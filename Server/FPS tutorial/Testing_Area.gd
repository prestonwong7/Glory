extends Spatial

onready var Player = load("res://FPS tutorial/Player.tscn")

func spawn_player(spawn_pos, id):
	var player = Player.instance()
	
	player.global_transform.origin = spawn_pos
	player.name = String(id) # Important
	player.set_network_master(id) # Important
	
	var player_node = get_tree().get_root().get_node("Testing_Area/Players")
	player_node.add_child(player)
