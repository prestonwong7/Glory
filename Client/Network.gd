extends Node

# CLIENT NETWORKING

const DEFAULT_PORT = 31416
const MAX_PEERS = 2
var players = {}
var players_done = []
var player_name

onready var address

var my_name = "Client"

# Signals for GUI
signal connection_failed()
signal connection_succeeded()
signal server_disconnected()
signal players_updated()

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func join_server():
	var ip = get_tree().get_root().get_node("Main_Menu/Main/Address").get_text()
	var host = NetworkedMultiplayerENet.new()
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)

# Clients functions	
func _connected_ok():
	# my_name gets overwritten in the main class
	rpc_id(1, "register_player", my_name)
	print("connected ok")
	emit_signal("connection_succeeded")

# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	print("Couldn't connect")
	get_tree().set_network_peer(null) # Remove peer.

func _server_disconnected():
	quit_game()
	
func quit_game():
	get_tree().set_network_peer(null)
	players.clear()

func get_player_list():
	return players.values()

# All functions called by server are puppets, not remote
# Puppet - Only if you are not master of the node, called by the server
puppet func register_player(id, name):
	players[id] = name
	emit_signal("players_updated")

puppet func unregister_player(id):
	players.erase(id)
	emit_signal("players_updated")
	
puppet func pre_configure_game():
	#get_tree().set_pause(true) # Pre-pause
	get_tree().get_root().get_node("Main_Menu").hide()
	
	var world = load("res://FPS tutorial/Testing_Area.tscn").instance()
	get_tree().get_root().add_child(world)
	
	# Tell server to start game, all clients will tell server
	rpc_id(1, "post_start_game")
