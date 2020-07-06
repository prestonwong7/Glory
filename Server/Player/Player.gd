extends KinematicBody

# Looking around
onready var rotation_helper = $Rotation_Helper
onready var camera = $Rotation_Helper/Model/Camera 
onready var crouchtween = get_node("CrouchTween")
onready var raycollision = get_node("RayCollision")

puppet var puppet_direction = Vector3()
puppet var puppet_velocity = Vector3()
puppet var puppet_rotation_helper_basis

var direction = Vector3()
var velocity = Vector3()

var animation_manager

# To make weapon shoot
const WEAPON_NUMBER_TO_NAME = {0:"UNARMED", 1:"KNIFE", 2:"PISTOL", 3:"RIFLE"}
const WEAPON_NAME_TO_NUMBER = {"UNARMED":0, "KNIFE":1, "PISTOL":2, "RIFLE":3}

# Puppets for clients
puppet var weapons = {"UNARMED":null, "KNIFE":null, "PISTOL":null, "RIFLE":null}
puppet var current_weapon_name = "UNARMED"
puppet var changing_weapon_name = "UNARMED"
puppet var changing_weapon = false

puppet var reloading_weapon = false

# UI
var health = 100
const MAX_HEALTH = 150
var UI_status_label

# Audio
var simple_audio_player = preload("res://FPS tutorial/Simple_Audio_Player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# Player weapon stuff below
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if is_network_master():
		rotation_helper = $Rotation_Helper
		camera = $Rotation_Helper/Model/Camera
	
	animation_manager = $Rotation_Helper/Model/Animation_Player
	animation_manager.callback_function = funcref(self, "fire_bullet")
	
	weapons["KNIFE"] = $Rotation_Helper/Gun_Fire_Points/Knife_Point
	weapons["PISTOL"] = $Rotation_Helper/Gun_Fire_Points/Pistol_Point
	weapons["RIFLE"] = $Rotation_Helper/Gun_Fire_Points/Rifle_Point
	
	var gun_aim_point_pos = $Rotation_Helper/Gun_Aim_Point.global_transform.origin
	
	for weapon in weapons:
		var weapon_node = weapons[weapon]
		if weapon_node != null:
			weapon_node.player_node = self
			weapon_node.look_at(gun_aim_point_pos, Vector3(0, 1, 0))
			weapon_node.rotate_object_local(Vector3(0, 1, 0), deg2rad((180)))
	
	current_weapon_name = "UNARMED"
	changing_weapon_name = "UNARMED"
	
	UI_status_label = $HUD/Panel/Gun_label
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Sync to last known position and velocity
#	position = puppet_pos
	velocity = puppet_velocity
	
#	position += velocity * delta
	
	# It may happen that many frames pass before the controlling player sends
	# their position again. If we don't update puppet_pos to position after moving,
	# we will keep jumping back until controlling player sends next position update.
	# Therefore, we update puppet_pos to minimize jitter problems
#	puppet_pos = position
	move_and_slide(velocity, Vector3.UP)
	
func fire_bullet():
	if changing_weapon == true:
		return
		
	weapons[current_weapon_name].fire_weapon()
	
func process_reloading():
	if reloading_weapon == true:
		var current_weapon = weapons[current_weapon_name]
		# just so that the player isn't unarmed
		if current_weapon != null:
			current_weapon.reload_weapon()
		reloading_weapon = false
	
func process_UI():
	if current_weapon_name == "UNARMED" or current_weapon_name == "KNIFE":
		UI_status_label.text = "HEALTH: " + str(health)
	else:
		var current_weapon = weapons[current_weapon_name]
		UI_status_label.text = "HEALTH: " + str(health) + \
			"\nAMMO: " + str(current_weapon.ammo_in_weapon) + "/" + str(current_weapon.spare_ammo)
			
func create_sound(sound_name, position=null):
	var audio_clone = simple_audio_player.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(audio_clone)
	audio_clone.play_sound(sound_name, position)
	
func add_health(additional_health):
	health += additional_health
	health = clamp(health, 0, MAX_HEALTH)

remote func rpc_move_character(velocity):
	move_and_slide(velocity, Vector3.UP)
	
remote func bullet_hit(damage, bullet_global_trans):
	health -= damage

remote func rpc_rotate_character_y(rotate_y):
	self.rotate_y(deg2rad(rotate_y))
	
remote func rpc_rotate_character_x(rotate_x):
	rotation_helper.rotate_x(deg2rad(rotate_x))

remote func rpc_fire_weapon(current_weapon_name):
	self.weapons[current_weapon_name].fire_weapon()

remote func rpc_fire_weapon_animation(fire_animation_name):
	self.animation_manager.set_animation(fire_animation_name)
	
remote func rpc_reload_weapon(current_weapon_name):
	self.weapons[current_weapon_name].reload_weapon()
	
