extends Spatial

var ammo_in_weapon = 30
var spare_ammo = 90
const AMMO_IN_MAG = 30

const CAN_RELOAD = true
const CAN_REFILL = true

const RELOADING_ANIM_NAME = "Rifle_reload"

const DAMAGE = 4

const IDLE_ANIM_NAME = "Rifle_idle"
const FIRE_ANIM_NAME = "Rifle_fire"

var is_weapon_enabled = false

var player_node = null

func _ready():
	pass

func fire_weapon():
	var ray = $Ray_Cast
	ray.force_raycast_update()

	if ray.is_colliding():
		var body = ray.get_collider()

		if body == player_node:
			pass
		elif body.has_method("bullet_hit"):
			body.bullet_hit(DAMAGE, ray.global_transform)
			
	ammo_in_weapon -= 1
	player_node.create_sound("Rifle_Shot", ray.global_transform.origin)

func equip_weapon():
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		is_weapon_enabled = true
		return true

	if player_node.animation_manager.current_state == "Idle_unarmed":
		player_node.animation_manager.set_animation("Rifle_equip")
		rpc_id(1, "rpc_equip_rifle", player_node)
		player_node.create_sound("Gun_Cock", player_node.global_transform.origin)

	return false

func unequip_weapon():
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		if player_node.animation_manager.current_state != "Rifle_unequip":
			player_node.animation_manager.set_animation("Rifle_unequip")
			rpc_id(1, "rpc_unequip_rifle", player_node)

	if player_node.animation_manager.current_state == "Idle_unarmed":
		is_weapon_enabled = false
		return true

	return false
	
func reload_weapon():
	var can_reload = false
	
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		can_reload = true
	
	# If no ammo or ammo is full
	if spare_ammo <= 0 or ammo_in_weapon == AMMO_IN_MAG:
		can_reload = false
	
	if can_reload == true:
		var ammo_needed = AMMO_IN_MAG - ammo_in_weapon
		
		if spare_ammo >= ammo_needed:
			spare_ammo -= ammo_needed
			ammo_in_weapon = AMMO_IN_MAG
		else:
			ammo_in_weapon += spare_ammo
			spare_ammo = 0
		
		player_node.animation_manager.set_animation(RELOADING_ANIM_NAME)
		player_node.create_sound("Gun_Cock", player_node.camera.global_transform.origin)
		
		return true
	
	return false
	

puppet func rpc_equip_rifle(player_node):
	self.player_node.animation_manager.set_animation("Rifle_equip") #self needed to refer to this player
	
puppet func rpc_unequip_rifle(player_node):
	self.player_node.animation_manager.set_animation("Rifle_unequip")
