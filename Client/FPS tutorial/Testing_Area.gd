extends Spatial

signal game_finished()


func _ready():
	var my_player = preload("res://FPS tutorial/Player.tscn").instance()
	
	my_player.global_transform.origin = Vector3(0, 50, 0)
	get_node("/root/Testing_Area/Players").add_child(my_player)
	if get_tree().is_network_server():
		# For the server, give control of player 2 to the other peer. 
		my_player.set_network_master(get_tree().get_network_connected_peers()[0])
	else:
		# For the client, give control of player 2 to itself.
		my_player.set_network_master(get_tree().get_network_unique_id())
	print("unique id: ", get_tree().get_network_unique_id())
		
func _on_exit_game_pressed():
	emit_signal("game_finished")
