extends Spatial

onready var Player = preload("res://FPS tutorial/Player.tscn")

# Called by the server during post_start_game
puppet func spawn_player(spawn_pos, id):
	var player = Player.instance()
	
	player.name = String(id) # Important
	player.set_network_master(id) # Important
	
	print("Spawn Player")
	var player_node = get_tree().get_root().get_node("Testing_Area/Players")
	player_node.add_child(player)
	player.global_transform.origin = spawn_pos
