extends Spatial

onready var Player = load("res://FPS tutorial/Player.tscn")

func spawn_player(spawn_pos, id):
	var player = Player.instance()
	
	player.position = spawn_pos
	player.name = String(id) # Important
	player.set_network_master(id) # Important
	
	$Players.add_child(player)
	get_node("/root/Testing_Area/Players").add_child(player)
