extends KinematicBody

export var speed = 300
export var sprint_speed = 500
export var max_speed = 300
export var crouch_speed = 50
export var fallspeed = -5
export var acceleration = 100	

export var gravity = -100
export var jump_power = 8000
export var dash_distance = 2000
export var dash_cooldown = 0.2

export var mouse_sensitivity = 0.3

onready var rotation_helper = $Rotation_Helper
onready var camera = $Rotation_Helper/Model/Camera 
onready var crouchtween = get_node("CrouchTween")
onready var raycollision = get_node("RayCollision")

var direction = Vector3()
var rotation_helper_basis

var velocity = Vector3()
var camera_x_rotation = 0
var timer = 0
var timer_prevent_dash = 0

var check_double_tap = false

# To make weapon shoot
var animation_manager

var current_weapon_name = "UNARMED"
var weapons = {"UNARMED":null, "KNIFE":null, "PISTOL":null, "RIFLE":null}
const WEAPON_NUMBER_TO_NAME = {0:"UNARMED", 1:"KNIFE", 2:"PISTOL", 3:"RIFLE"}
const WEAPON_NAME_TO_NUMBER = {"UNARMED":0, "KNIFE":1, "PISTOL":2, "RIFLE":3}
var changing_weapon = false
var changing_weapon_name = "UNARMED"

var health = 100
var UI_status_label

# Dash Variables
var double_tap_forward = false
var double_tap_left = false
var double_tap_right = false
var double_tap_backward = false

var check_timer_dash = false
var prevent_dash = false

var check_forward_dash = false
var check_backward_dash = false
var check_left_dash = false
var check_right_dash = false

var dash_forward = false
var dash_left = false
var dash_right = false
var dash_backward = false

# Double Jump Variables
var first_jump_used = false
var double_jump_used = false
var check_double_jump = false
var enable_double_jump = true

var crouching = false

# To slide down slopes
var has_contact = false
const MAX_SLOPE_ANGLE = 35

# Called when the node enters the scene tree for the first time.
func _ready():
	# Player weapon stuff below
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	camera = $Rotation_Helper/Model/Camera
	rotation_helper = $Rotation_Helper	
	
	animation_manager = $Rotation_Helper/Model/Animation_Player
	animation_manager.callback_function = funcref(self, "fire_bullet")
	
	weapons["KNIFE"] = $Rotation_Helper/Gun_Fire_Points/Knife_Point
	weapons["PISTOL"] = $Rotation_Helper/Gun_Fire_Points/Pistol_Point
	weapons["RIFLE"] = $Rotation_Helper/Gun_Fire_Points/Rifle_Point
	
	var gun_aim_point_pos = $Rotation_Helper/Gun_Aim_Point.global_transform.origin
	
	for weapon in weapons:
		var weapon_node = weapons[weapon]
		if weapon_node != null:
			print("hello")
			weapon_node.player_node = self
			weapon_node.look_at(gun_aim_point_pos, Vector3(0, 1, 0))
			weapon_node.rotate_object_local(Vector3(0, 1, 0), deg2rad((180)))
#		print(weapon_node.player_node)
	
	current_weapon_name = "UNARMED"
	changing_weapon_name = "UNARMED"
	
	UI_status_label = $HUD/Panel/Gun_label
	#flashlight = $Rotation_Helper/Flashlight

	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if check_double_tap == true:
		timer += delta
		if timer < 0.1:
			if check_forward_dash == true:
				if Input.is_action_pressed("move_forward"):
					double_tap_forward = true
					check_double_tap = false
					timer = 0
			elif check_backward_dash == true:
				if Input.is_action_pressed("move_backward"):
					double_tap_backward = true
					check_double_tap = false
					timer = 0
			elif check_left_dash == true:
				if Input.is_action_pressed("move_left"):
					double_tap_left = true
					check_double_tap = false
					timer = 0
			elif check_right_dash == true:
				if Input.is_action_pressed("move_right"):
					double_tap_right = true
					check_double_tap = false
					timer = 0
		else:
			double_tap_forward = false
			double_tap_backward = false
			double_tap_left = false
			double_tap_right = false
			check_double_tap = false
			timer = 0
			
	if check_double_jump == true:
		if Input.is_action_pressed("jump"):
			enable_double_jump = true
			
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func _input(event):
	if event is InputEventMouseMotion:
		rotation_helper.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity)) # rotates on x axis
		
		var x_delta = event.relative.y * mouse_sensitivity
		if x_delta + camera_x_rotation > - 90 and x_delta + camera_x_rotation < 90:
			camera.rotate_x(deg2rad(x_delta)) # rotates on y axis
			camera_x_rotation += x_delta

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
	process_changing_weapons(delta)

func process_input(delta):
	# Get direction player is facing
	direction = Vector3() # needed so the player moves one direction after pressing one button once
	rotation_helper_basis = rotation_helper.get_global_transform().basis # get local transform and rotation axis 

	# Move forward or backward, not both
	if Input.is_action_pressed("move_forward"):
		direction += rotation_helper_basis.z # forward is negative on godot
		# To not accidentally dash back and forth (mashing keys)
		check_backward_dash = false
		check_left_dash = false
		check_right_dash = false
		if double_tap_forward == true:
			check_timer_dash = true
			prevent_dash = true
			dash_forward = true
			double_tap_forward = false
	elif Input.is_action_pressed("move_backward"):
		direction -= rotation_helper_basis.z
		check_forward_dash = false
		check_left_dash = false
		check_right_dash = false
		if double_tap_backward == true:
			check_timer_dash = true
			prevent_dash = true
			dash_backward = true
			double_tap_backward = false
		
	# Move left or right, not both
	if Input.is_action_pressed("move_left"):
		direction += rotation_helper_basis.x
		check_forward_dash = false
		check_backward_dash = false
		check_right_dash = false
		if double_tap_left == true:
			check_timer_dash = true
			prevent_dash = true
			dash_left = true
			double_tap_left = false
	elif Input.is_action_pressed("move_right"):
		direction -= rotation_helper_basis.x
		check_forward_dash = false
		check_backward_dash = false
		check_left_dash = false
		if double_tap_right == true:
			check_timer_dash = true
			prevent_dash = true
			dash_right = true
			double_tap_right = false
			
	dash(delta)
	jump_and_double_jump() # jump & double jump mechanics inside
	sprint()
	crouch()
	
	#Changing Weapons
	var weapon_change_number = WEAPON_NAME_TO_NUMBER[current_weapon_name]
	
	if Input.is_key_pressed(KEY_1):
		weapon_change_number = 0
	if Input.is_key_pressed(KEY_2):
		weapon_change_number = 1
	if Input.is_key_pressed(KEY_3):
		weapon_change_number = 2
	if Input.is_key_pressed(KEY_4):
		weapon_change_number = 3
		
	if Input.is_action_just_pressed("shift_weapon_positive"):
		weapon_change_number += 1
	if Input.is_action_just_pressed("shift_weapon_negative"):
		weapon_change_number -= 1
		
	weapon_change_number = clamp(weapon_change_number, 0, WEAPON_NUMBER_TO_NAME.size() - 1)
	
	if changing_weapon == false:
		if WEAPON_NUMBER_TO_NAME[weapon_change_number] != current_weapon_name:
			changing_weapon_name = WEAPON_NUMBER_TO_NAME[weapon_change_number]
			changing_weapon = true
	
	# Firing weapon here		
	if Input.is_action_pressed("primary_fire"):
		print(changing_weapon)
		if changing_weapon == false:
			var current_weapon = weapons[current_weapon_name]
			if current_weapon != null:
				if animation_manager.current_state == current_weapon.IDLE_ANIM_NAME:
					animation_manager.set_animation(current_weapon.FIRE_ANIM_NAME)

func process_movement(delta):
	direction = direction.normalized() # so moving diagonally doesn't increase speed
	
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta) 
	
	# Slope logic to slide down at a certain angle
	if is_on_floor():
		has_contact = true
		var n = $LegRaycast.get_collision_normal()
		var floor_angle = rad2deg(acos(n.dot(Vector3(0,1,0))))
		if floor_angle > MAX_SLOPE_ANGLE:
			velocity.y += gravity
			pass
	else:
		if !$LegRaycast.is_colliding():
			has_contact = false
			velocity.y += gravity # Gravity mechanics
			
	if (has_contact and !(is_on_floor())):
		move_and_collide(Vector3(0,-1,0))
	
	# End slope logic
	
	velocity = move_and_slide(velocity, Vector3.UP)

func process_changing_weapons(delta):
	
	if changing_weapon == true:
		
		var weapon_unequipped = false
		var current_weapon = weapons[current_weapon_name]
		
		if current_weapon == null:
			weapon_unequipped = true
		else:
			if current_weapon.is_weapon_enabled == true:
				weapon_unequipped = current_weapon.unequip_weapon()
			else:
				weapon_unequipped = true
		
		# Weapon_unequipped is s
		if weapon_unequipped == true:
			
			var weapon_equipped = false
			var weapon_to_equip = weapons[changing_weapon_name]
			
			if weapon_to_equip == null:
				weapon_equipped = true
			else:
				if weapon_to_equip.is_weapon_enabled == false:
					weapon_equipped = weapon_to_equip.equip_weapon()
				else:
					weapon_equipped = true
			
			if weapon_equipped == true:
				changing_weapon = false
				current_weapon_name = changing_weapon_name
				changing_weapon_name = ""

func jump_and_double_jump():
	if is_on_floor():
		first_jump_used = false
		check_double_jump = false
		enable_double_jump = false
		double_jump_used = false
	elif (not(is_on_floor()) and double_jump_used == false 
		and enable_double_jump == false and first_jump_used == false):
			check_double_jump = true # used in _process(delta)

	if (Input.is_action_just_pressed("jump") and has_contact):
		velocity.y -= jump_power
		first_jump_used = true
		has_contact = false
		print("jump")
		
	if first_jump_used == true:
		if Input.is_action_just_released("jump"):
			check_double_jump = true
			first_jump_used = false
		
	if enable_double_jump == true: # enable double jump set in _process(delta)
		velocity.y -= jump_power
		enable_double_jump = false # disable so that you cant do it again
		check_double_jump = false # used in _process(delta)
		double_jump_used = true
		print("double jumped")
	
	pass

func sprint():
	if Input.is_action_pressed("sprint"):
		speed = sprint_speed
	else:
		speed = max_speed
	pass

func dash(delta): # Dash player in a direction
	if dash_forward == true:
		print ("dashed forward")
		velocity -= rotation_helper_basis.z * dash_distance
		dash_forward = false
	elif dash_backward == true:
		velocity += rotation_helper_basis.z * dash_distance
		dash_backward = false
	elif dash_left == true:
		velocity -= rotation_helper_basis.x * dash_distance
		dash_left = false
	elif dash_right == true:
		velocity += rotation_helper_basis.x * dash_distance
		dash_right = false

	if prevent_dash == false: # Prevent_dash = cooldown checker
		if (Input.is_action_just_released("move_forward") and has_contact):
			check_double_tap = true
			check_forward_dash = true
			check_left_dash = false
			check_right_dash = false
			check_backward_dash = false
		elif (Input.is_action_just_released("move_backward") and is_on_floor()):
			check_double_tap = true
			check_backward_dash = true
			check_forward_dash = false
			check_left_dash = false
			check_right_dash = false
		elif (Input.is_action_just_released("move_left") and is_on_floor()):
			check_double_tap = true
			check_left_dash = true
			check_forward_dash = false
			check_right_dash = false
			check_backward_dash = false
		elif (Input.is_action_just_released("move_right") and is_on_floor()):
			check_double_tap = true
			check_right_dash = true
			check_forward_dash = false
			check_left_dash = false
			check_backward_dash = false
			
	# Dash cooldown			
	if check_timer_dash == true:
		timer_prevent_dash += delta
		if timer_prevent_dash > dash_cooldown:
			prevent_dash = false
			timer_prevent_dash = 0
			check_timer_dash = false
			
func crouch():
	if Input.is_action_pressed("crouch"):
		crouching = true
		crouchtween.interpolate_property(raycollision.shape, "length", 
			raycollision.shape.length, 0, 0.08, Tween.TRANS_LINEAR,
			Tween.EASE_IN_OUT)
		crouchtween.start()
		speed = crouch_speed
	
	# Fast-fall
	if Input.is_action_pressed("crouch") and not(has_contact) and crouching == true:
		velocity.y += gravity * fallspeed
		speed = crouch_speed
	
	if Input.is_action_just_released("crouch"):
		crouching = false
		crouchtween.interpolate_property(raycollision.shape, "length", 
			raycollision.shape.length, 2.5, 0.08, Tween.TRANS_LINEAR,
			Tween.EASE_IN_OUT)
			
	if crouching == true:
		rotation_helper_basis.y -= Vector3(0,5,0)
		
func fire_bullet():
	if changing_weapon == true:
		return
		
	weapons[current_weapon_name].fire_weapon()
	
