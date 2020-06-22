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

# Called when the node enters the scene tree for the first time.
func _ready():
	start_menu = $Start_Menu
#	$Start_Menu/Button_Start.connect("pressed", self, "start_menu_button_pressed", ["start"])
	$Start_Menu/Button_Host.connect("pressed", self, "start_menu_button_pressed", ["host"])
	$Start_Menu/Button_Options.connect("pressed", self, "start_menu_button_pressed", ["options"])
	$Start_Menu/Button_Quit.connect("pressed", self, "start_menu_button_pressed", ["quit"])
	
	status_ok = $Start_Menu/StatusOk
	status_fail = $Start_Menu/StatusFail
	address = $Start_Menu/Address
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")


func start_menu_button_pressed(button_name):
	if button_name == "start":
		# Load my player
		#get_tree().change_scene_to(testing_area)
		solo_play = true
		start_server()
	elif button_name == "host":
		start_server()
		#get_tree().change_scene("res://FPS tutorial/Testing_Area.tscn")
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
	
func _player_connected(id):
	rpc_id(id, "register_player", my_info)

func _player_disconnected(id):
	unregister_player(id)
	rpc("unregister_player", id)

# Player management funcs
remote func register_player(info):
#	if get_tree().is_network_server():
#		rpc_id(id, "register_new_player", 1, player_name)
#
#		for peer_id in players:
#			rpc_id(id, "register_new_player", peer_id, players[peer_id])
	var id = get_tree().get_rpc_sender_id()
	players[id] = info
	rpc("pre_configure_game")

remote func unregister_player(id):
	#get_node("/root/" + str(id)).queue_free()
	players.erase(id)
	
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
		

remote func pre_configure_game():
	get_tree().set_pause(true) # Pre-pause
	
	var world = load("res://FPS tutorial/Testing_Area.tscn").instance()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Main_Menu").hide()
	
	var selfPeerID = get_tree().get_network_unique_id()
	var my_player = load("res://FPS tutorial/Player.tscn").instance()
#	my_player.global_transform.origin = Vector3(2, 50, 0)
	my_player.set_name(str(selfPeerID))
	my_player.set_network_master(selfPeerID)
	world.get_node("/root/Testing_Area/Players").add_child(my_player)
	
	# Load all players
	for p in players:
		var player_scene = preload("res://FPS tutorial/Player.tscn").instance()
#		player_scene.global_transform.origin = Vector3(p, 50, 0)
		player_scene.set_name(str(p))
		player_scene.set_network_master(p)
		world.get_node("/root/Testing_Area/Players").add_child(player_scene)

	# Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
	rpc_id(1, "done_preconfiguring", selfPeerID)

remote func done_preconfiguring(who):
	# Here are some checks you can do, for example
	assert(get_tree().is_network_server())
	assert(who in players) # Exists
	assert(not who in players_done) # Was not added yet

	players_done.append(who)

	if players_done.size() == players.size():
		rpc("post_configure_game")

remote func post_configure_game():
	get_tree().set_pause(false)
	# Game starts now!
