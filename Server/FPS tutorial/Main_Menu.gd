extends Control

const DEFAULT_PORT = 31416
const MAX_PEERS = 2
var players = {}
var players_ready = []

var start_menu
var my_info = { name = "Johnson Magenta", favorite_color = Color8(255, 0, 255) }

onready var status_ok
onready var status_fail
onready var address
onready var testing_area = preload("res://FPS tutorial/Testing_Area.tscn")

var solo_play = false

# Called when the node enters the scene tree for the first time.
func _ready():
	start_menu = $Start_Menu
	$Start_Menu/Button_Start.connect("pressed", self, "start_menu_button_pressed", ["start"])
	$Start_Menu/Button_Host.connect("pressed", self, "start_menu_button_pressed", ["host"])
	$Start_Menu/Button_Quit.connect("pressed", self, "start_menu_button_pressed", ["quit"])
	
	status_ok = $Start_Menu/StatusOk
	status_fail = $Start_Menu/StatusFail
	address = $Start_Menu/Address
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")


func start_menu_button_pressed(button_name):
	if button_name == "start":
		solo_play = true
		start_server()
	elif button_name == "host":
		start_server()
	elif button_name == "quit":
		get_tree().quit()

func start_server():
	var host = NetworkedMultiplayerENet.new()
	
	# I'm not sure why this is needed to make it work below
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	
	var err = host.create_server(DEFAULT_PORT, MAX_PEERS)
	if (err != OK):
		_set_status("Cant host, address in use", false)
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
	
func _set_status(text, isok):
	# Simple way to show status.
	if isok:
		status_ok.set_text(text)
		status_fail.set_text("")
	else:
		status_ok.set_text("")
		status_fail.set_text(text)
		
func _player_connected(id):
	rpc_id(id, "register_player", my_info)
	print("player connected: ", id)

func _player_disconnected(id):
	unregister_player(id)
	rpc("unregister_player", id)

# Player management funcs
remote func register_player(info):
	var id = get_tree().get_rpc_sender_id()
	players[id] = info
	
	# send new player everyone else id (ON CLIENTS)
	for player_id in players:
		rpc_id(id, "register_player", player_id, players[player_id])
	
	# opposite - send everyone else the new player id (ON CLIENTS)
	rpc("register_player", id, players[id])
	
	print("Client registered: ", id)
	
remote func unregister_player(id):
	players.erase(id)
	print("Client ", id, " was unregistered")

remote func player_ready():
	var caller_id = get_tree().get_rpc_sender_id()
	
	# Add to array if ready
	players_ready.append(caller_id)

	if players_ready.size() == players.size():
		pre_configure_game() # call this method to start the game

func pre_configure_game():
	get_tree().get_root().get_node("Main_Menu").hide()
	
	var world = load("res://FPS tutorial/Testing_Area.tscn").instance()
	get_tree().get_root().add_child(world)
	
	# Load all players
	for p in players:
		var player_scene = preload("res://FPS tutorial/Player.tscn").instance()
#		player_scene.global_transform.origin = Vector3(p, 50, 0)
		player_scene.set_name(str(p))
		player_scene.set_network_master(p)
		world.get_node("/root/Testing_Area/Players").add_child(player_scene)

	# Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
	# Rpc = all peers
	rpc("pre_configure_game")

# Called by the client when pre_start_game	
remote func post_start_game():
	var caller_id = get_tree().get_rpc_sender_id()
	var world = get_node("/root/Testing_Area")
	
	for player in world.get_node("Players").get_children():
		world.rpc_id(caller_id, "spawn_player", player.position, player.get_network_master())

