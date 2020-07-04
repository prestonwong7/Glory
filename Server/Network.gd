extends Node

# SERVER NETWORKING
const DEFAULT_PORT = 31416
const MAX_PEERS = 2
var players = {}
var players_ready = []

var start_menu
var my_info = { name = "Johnson Magenta", favorite_color = Color8(255, 0, 255) }

onready var testing_area = preload("res://FPS tutorial/Testing_Area.tscn")

var solo_play = false

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

func start_server():
	var host = NetworkedMultiplayerENet.new()
	print("hello")
	# I'm not sure why this is needed to make it work below
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	
	var err = host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)
	
func _player_connected(id):
	print("player connected: ", id)

func _player_disconnected(id):
	players.erase(id)
	rpc("unregister_player", id)

# Client calls funcs, server uses remote funcs
remote func register_player(name):
	var id = get_tree().get_rpc_sender_id()
	players[id] = name
	
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
	
	# if all players are ready, let's start!
	if players_ready.size() == players.size():
		pre_configure_game() # call this method to start the game
		
func pre_configure_game():
	get_tree().get_root().get_node("Main_Menu").hide()
	
	var world = load("res://FPS tutorial/Testing_Area.tscn").instance()
	get_tree().get_root().add_child(world)
	
	# Load all players
#	for p in players:
#		var player_scene = load("res://FPS tutorial/Player.tscn").instance()
#		player_scene.global_transform.origin = Vector3(p, 200, 0)
#		player_scene.set_name(str(p))
#		player_scene.set_network_master(p)
#		world.get_node("/root/Testing_Area/Players").add_child(player_scene)
	# Spawn all the people
	for id in players:
		get_node("/root/Testing_Area").spawn_player(Vector3(0,52,0), id)
		
	# Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
	# Rpc = all peers
	rpc("pre_configure_game") # will call post start game here by the clients

# Called by the clients when pre_start_game	
remote func post_start_game():
	var caller_id = get_tree().get_rpc_sender_id()
	var world = get_node("/root/Testing_Area")
	
	for player in world.get_node("Players").get_children():
		world.rpc_id(caller_id, "spawn_player", player.global_transform.origin, player.get_network_master())
