extends Node

class_name Weapon

export var fire_rate = 2
export var clip_size = 5
export var reload_rate = 1

var current_ammo = 0
var can_fire = true
var reloading = false

onready var ammo_label = $"/root/World/UI/AmmoLabel"
onready var raycast = $"../Head/Camera/RayCast"

# Called when the node enters the scene tree for the first time.
func _ready():
	current_ammo = clip_size
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	ammo_label.set_text("%d / %d " % [current_ammo, clip_size])
	
	if Input.is_action_just_pressed("primary_fire") and can_fire == true:	
		if current_ammo > 0 and not reloading:
			fire()
		elif not reloading:
			reload()
			
	if Input.is_action_just_pressed("reload"):
		reload()
	pass
	
func check_collision():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.is_in_group("Enemy"):
			collider.queue_free() # delete
			print("Killed " + collider.name)
		
func reload():
	print("Reloading")
	reloading = true
	yield(get_tree().create_timer(reload_rate), "timeout") # waiting time for reload
	current_ammo = clip_size
	reloading = false
	print("Reload complete")
	
func fire():
	print("fire weapon")
	can_fire = false
	current_ammo -= 1
	check_collision()
	
	yield(get_tree().create_timer(fire_rate), "timeout") # waiting time for fire_Rate
	
	can_fire = true
			
		
		
		
		
