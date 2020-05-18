extends Control

const DEFAULT_PORT = 31416
const MAX_PEERS = 10
var players = {}
var player_name
var start_menu
onready var status_ok
onready var status_fail
onready var address
# Called when the node enters the scene tree for the first time.
func _ready():
	start_menu = $Start_Menu
	$Start_Menu/Button_Start.connect("pressed", self, "start_menu_button_pressed", ["start"])
	$Start_Menu/Button_Join.connect("pressed", self, "start_menu_button_pressed", ["join"])
	$Start_Menu/Button_Open_Godot.connect("pressed", self, "start_menu_button_pressed", ["open_godot"])
	$Start_Menu/Button_Options.connect("pressed", self, "start_menu_button_pressed", ["options"])
	$Start_Menu/Button_Quit.connect("pressed", self, "start_menu_button_pressed", ["quit"])
	
	status_ok = $Start_Menu/StatusOk
	status_fail = $Start_Menu/StatusFail
	address = $Start_Menu/Address
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func start_menu_button_pressed(button_name):
	if button_name == "start":
		#set_mouse_and_joypad_sensitivity()
		start_server()
		#get_tree().change_scene("res://FPS tutorial/Testing_Area.tscn")
	elif button_name == "join":
		join_server()
		#get_tree().change_scene("res://FPS tutorial/Testing_Area.tscn")
	elif button_name == "quit":
		get_tree().quit()

func start_server():
	player_name = 'Server'
	var host = NetworkedMultiplayerENet.new()
	
	# I'm not sure why this is needed to make it work below
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	#
	
	var err = host.create_server(DEFAULT_PORT, MAX_PEERS)
	
	if (err != OK):
		_set_status("Cant host, address in use", false)
		join_server()
		return
	
	get_tree().set_network_peer(host)
	#spawn_player(1)
	_set_status("Waiting for player...", true)
	
func join_server():
	player_name = 'Client'
	var ip = address.get_text()
	print(ip)
	if not ip.is_valid_ip_address():
		_set_status("IP address is invalid", false)
		return
	
	#get_tree().set_network_master(ip)
	var host = NetworkedMultiplayerENet.new()
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)
	_set_status("Connecting...", true)
	
func _player_connected(id):
	get_tree().change_scene("res://FPS tutorial/Testing_Area.tscn")
	#spawn_player(1)
	# Someone connected, start the game!
	var fps = load("res://FPS tutorial/Testing_Area.tscn").instance()
	# Connect deferred so we can safely erase it from the callback.
	#fps.connect("game_finished", self, "_end_game", [], CONNECT_DEFERRED)

func _end_game(with_error = ""):
	if has_node("/root/Main_Menu"):
		# Erase immediately, otherwise network might show errors (this is why we connected deferred above).
		get_node("/root/Main_Menu").free()
		show()
	
	get_tree().set_network_peer(null) # Remove peer.
	
	_set_status(with_error, false)

func _player_disconnected(id):
	get_tree().change_scene("res://FPS tutorial/Main_Menu.tscn")
	unregister_player(id)
	rpc("unregister_player", id)

func _connected_ok():
	rpc_id(1, "user_ready", get_tree().get_network_unique_id(), player_name)
	print("connected ok")
	
# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	_set_status("Couldn't connect", false)
	
	get_tree().set_network_peer(null) # Remove peer.

remote func user_ready(id, player_name):
	if get_tree().is_network_server():
		rpc_id(id, "register_in_game")

remote func register_in_game():
	rpc("register_new_player", get_tree().get_network_unique_id(), player_name)
	register_new_player(get_tree().get_network_unique_id(), player_name)
	
func _server_disconnected():
	quit_game()
	
remote func register_new_player(id, name):
	if get_tree().is_network_server():
		rpc_id(id, "register_new_player", 1, player_name)
		
		for peer_id in players:
			rpc_id(id, "register_new_player", peer_id, players[peer_id])
			
	players[id] = name

remote func unregister_player(id):
	#get_node("/root/" + str(id)).queue_free()
	players.erase(id)
	
func quit_game():
	get_tree().set_network_peer(null)
	players.clear()

func spawn_player(id):
	print("spawn player")
	get_tree().change_scene("res://FPS tutorial/Testing_Area.tscn")
	var player_scene = load("res://FPS tutorial/Player.tscn")
	var player = player_scene.instance()
	
	player.global_transform.origin = Vector3(0, -50, 0)
	
	player.set_name(str(id))
	
	if id == get_tree().get_network_unique_id():
		player.set_network_master(id)
		player.player_id = id
		player.control = true
	
	get_parent().add_child(player)

func _set_status(text, isok):
	# Simple way to show status.
	if isok:
		status_ok.set_text(text)
		status_fail.set_text("")
	else:
		status_ok.set_text("")
		status_fail.set_text(text)
