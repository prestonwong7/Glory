extends Control

# SERVER

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
onready var player_scene = preload("res://FPS tutorial/Player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	start_menu = $Start_Menu
	$Start_Menu/Button_Start.connect("pressed", self, "start_menu_button_pressed", ["start"])
	$Start_Menu/Button_Host.connect("pressed", self, "start_menu_button_pressed", ["host"])
	$Start_Menu/Button_Quit.connect("pressed", self, "start_menu_button_pressed", ["quit"])
	
	status_ok = $Start_Menu/StatusOk
	status_fail = $Start_Menu/StatusFail
	address = $Start_Menu/Address
	
#	get_tree().connect("network_peer_connected", self, "_player_connected")
#	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

func start_menu_button_pressed(button_name):
	if button_name == "start":
		# Solo play
		var host = NetworkedMultiplayerENet.new()
		
		# I'm not sure why this is needed to make it work below
		host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
		var err = host.create_server(65534, MAX_PEERS)
		get_tree().set_network_peer(host)
		
		var world = testing_area.instance()
		get_tree().get_root().add_child(world)
		get_tree().get_root().get_node("Main_Menu").hide()
		world.get_node("/root/Testing_Area/Players").add_child(player_scene.instance())
		
	elif button_name == "host":
		Network.start_server()
		_set_status("Waiting for player...", true)
		
	elif button_name == "quit":
		get_tree().quit()

func _set_status(text, isok):
	# Simple way to show status.
	if isok:
		status_ok.set_text(text)
		status_fail.set_text("")
	else:
		status_ok.set_text("")
		status_fail.set_text(text)

