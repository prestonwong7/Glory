extends Control

# CLIENTS 

var start_menu
var my_info = {
	 name = "Johnson Magenta", 
	 favorite_color = Color8(255, 0, 255) 
}

onready var status_ok
onready var status_fail
onready var address
onready var testing_area = preload("res://FPS tutorial/Testing_Area.tscn")
onready var player_scene = preload("res://FPS tutorial/Player.tscn")

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
#
#	get_tree().connect("connected_to_server", self, "_connected_ok")
#	get_tree().connect("connection_failed", self, "_connected_fail")
#	get_tree().connect("server_disconnected", self, "_server_disconnected")

func start_menu_button_pressed(button_name):
	if button_name == "start":
		var host = NetworkedMultiplayerENet.new()
		
		# I'm not sure why this is needed to make it work below
		host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
		var err = host.create_server(65534, 1)
		get_tree().set_network_peer(host)
		
		# Solo play
		get_tree().change_scene_to(testing_area)
		var world = testing_area.instance()
		get_tree().get_root().add_child(world)
		get_tree().get_root().get_node("Main_Menu").hide()
		world.get_node("/root/Testing_Area/Players").add_child(player_scene.instance())
		
	elif button_name == "join":
		Network.join_server()
		_set_status("Connecting...", true)
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
		
