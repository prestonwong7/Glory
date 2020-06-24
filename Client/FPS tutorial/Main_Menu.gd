extends Control

const DEFAULT_PORT = 31416
const MAX_PEERS = 2
var players = {}
var players_done = []
var player_name
var start_menu
var my_info = { name = "Johnson Magenta", favorite_color = Color8(255, 0, 255) }
onready var status_ok
onready var status_fail
onready var address
onready var testing_area = preload("res://FPS tutorial/Testing_Area.tscn")

var solo_play = false
var my_name = "Client"

# Signals for GUI
signal connection_failed()
signal connection_succeeded()
signal server_disconnected()
signal players_updated()

# Called when the node enters the scene tree for the first time.
func _ready():
	start_menu = $Start_Menu
	$Start_Menu/Button_Start.connect("pressed", self, "start_menu_button_pressed", ["start"])
	$Start_Menu/Button_Join.connect("pressed", self, "start_menu_button_pressed", ["join"])
	$Start_Menu/Button_Options.connect("pressed", self, "start_menu_button_pressed", ["options"])
	$Start_Menu/Button_Quit.connect("pressed", self, "start_menu_button_pressed", ["quit"])
	
	status_ok = $Start_Menu/StatusOk
	status_fail = $Start_Menu/StatusFail
	address = $Start_Menu/Address
	
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func start_menu_button_pressed(button_name):
	if button_name == "start":
		solo_play = true
		start_server()
	elif button_name == "join":
		join_server()
	elif button_name == "quit":
		get_tree().quit()

func start_server():
	player_name = 'Server'
	var host = NetworkedMultiplayerENet.new()
	
	# I'm not sure why this is needed to make it work below
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	
	var err = host.create_server(DEFAULT_PORT, MAX_PEERS)
	if (err != OK):
		_set_status("Cant host, address in use", false)
		join_server()
		return
	
	get_tree().set_network_peer(host)
	_set_status("Waiting for player...", true)
	
	if solo_play == true:
		get_tree().change_scene_to(testing_area)
		var player_scene = load("res://FPS tutorial/Player.tscn").instance()
		var world = load("res://FPS tutorial/Testing_Area.tscn").instance()
		get_tree().get_root().add_child(world)
		get_tree().get_root().get_node("Main_Menu").hide()
		world.get_node("/root/Testing_Area/Players").add_child(player_scene)
	
func join_server():
	var ip = address.get_text()
	if not ip.is_valid_ip_address():
		_set_status("IP address is invalid", false)
		return
	
	var host = NetworkedMultiplayerENet.new()
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)
	_set_status("Connecting...", true)

# Clients functions	
func _connected_ok():
	rpc_id(1, "register_player", my_name)
	print("connected ok")
	emit_signal("connection_succeeded")

# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	_set_status("Couldn't connect", false)
	get_tree().set_network_peer(null) # Remove peer.

func _server_disconnected():
	quit_game()
	
# Puppet - Only if you are not master of the node
puppet func register_player(id, name):
	players[id] = name
	emit_signal("players_updated")

puppet func unregister_player(id):
	players.erase(id)
	emit_signal("players_updated")
	
func quit_game():
	get_tree().set_network_peer(null)
	players.clear()

func _set_status(text, isok):
	# Simple way to show status.
	if isok:
		status_ok.set_text(text)
		status_fail.set_text("")
	else:
		status_ok.set_text("")
		status_fail.set_text(text)
		

puppet func pre_configure_game():
	#get_tree().set_pause(true) # Pre-pause
	get_tree().get_root().get_node("Main_Menu").hide()
	
	var world = load("res://FPS tutorial/Testing_Area.tscn").instance()
	get_tree().get_root().add_child(world)
	
	# Start game
	rpc_id(1, "post_start_game")
