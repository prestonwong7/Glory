extends KinematicBody

export var speed = 100
export var acceleration = 100
export var gravity = 50
export var jump_power = 15
export var mouse_sensitivity = 0.3
export var sprint_speed = 200
export var max_speed = 100
export var dash_distance = 700
export var dash_cooldown = 0.5

onready var head = $Head
onready var camera = $Head/Camera 

var velocity = Vector3()
var camera_x_rotation = 0
var timer = 0
var timer_prevent_dash = 0

var check_double_tap = false

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

func _input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity)) # rotates on x axis
		
		var x_delta = event.relative.y * mouse_sensitivity
		if x_delta + camera_x_rotation > - 90 and x_delta + camera_x_rotation < 90:
			camera.rotate_x(deg2rad(-x_delta)) # rotates on y axis
			camera_x_rotation += x_delta

func _physics_process(delta):
	
	# Get direction player is facing
	var head_basis = head.get_global_transform().basis # get local transform and rotation axis 
	
	var direction = Vector3()
	# Move forward or backward, not both
	if Input.is_action_pressed("move_forward"):
		direction -= head_basis.z # forward is negative on godot
		if double_tap_forward == true:
			check_timer_dash = true
			prevent_dash = true
			dash_forward = true
			double_tap_forward = false
	elif Input.is_action_pressed("move_backward"):
		direction += head_basis.z
		if double_tap_backward == true:
			check_timer_dash = true
			prevent_dash = true
			dash_backward = true
			double_tap_backward = false
		
	# Move left or right, not both
	if Input.is_action_pressed("move_left"):
		direction -= head_basis.x
		if double_tap_left == true:
			check_timer_dash = true
			prevent_dash = true
			dash_left = true
			double_tap_left = false
	elif Input.is_action_pressed("move_right"):
		direction += head_basis.x
		if double_tap_right == true:
			check_timer_dash = true
			prevent_dash = true
			dash_right = true
			double_tap_right = false
		
	direction = direction.normalized() # so moving diagonally doesn't increase speed
	
	if Input.is_action_pressed("sprint"):
		speed = sprint_speed
	else:
		speed = max_speed
	
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta) 
	
	velocity.y -= gravity
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y -= jump_power
	
	# Dash player in a direction
	if dash_forward == true:
		velocity += head_basis.z * dash_distance
		dash_forward = false
	elif dash_backward == true:
		velocity -= head_basis.z * dash_distance
		dash_backward = false
	elif dash_left == true:
		velocity += head_basis.x * dash_distance
		dash_left = false
	elif dash_right == true:
		velocity -= head_basis.x * dash_distance
		dash_right = false
	
	# Dashing forward mechanics
	if prevent_dash == false:
		if (Input.is_action_just_released("move_forward") and is_on_floor()):
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
		

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if check_double_tap == true:
		timer += delta
		if timer < 0.2:
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
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	pass
