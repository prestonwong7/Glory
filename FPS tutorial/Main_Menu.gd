extends Control

var start_menu
var level_select_menu
var options_menu

export (String, FILE) var testing_area_scene
export (String, FILE) var space_level_scene
export (String, FILE) var ruins_level_scene

# Called when the node enters the scene tree for the first time.
func _ready():
	start_menu = $Start_Menu
	$Start_Menu/Button_Start.connect("pressed", self, "start_menu_button_pressed", ["start"])
	$Start_Menu/Button_Open_Godot.connect("pressed", self, "start_menu_button_pressed", ["open_godot"])
	$Start_Menu/Button_Options.connect("pressed", self, "start_menu_button_pressed", ["options"])
	$Start_Menu/Button_Quit.connect("pressed", self, "start_menu_button_pressed", ["quit"])

func start_menu_button_pressed(button_name):
	if button_name == "start":
		#set_mouse_and_joypad_sensitivity()
		Network.start_server()
		get_tree().change_scene("res://FPS tutorial/Testing_Area.tscn")
		
	elif button_name == "open_godot":
		OS.shell_open("https://godotengine.org/")
	elif button_name == "options":
		options_menu.visible = true
		start_menu.visible = false
	elif button_name == "quit":
		get_tree().quit()
