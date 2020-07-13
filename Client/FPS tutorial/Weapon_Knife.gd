extends Spatial

var ammo_in_weapon = 1
var spare_ammo = 1
const AMMO_IN_MAG = 1

const CAN_RELOAD = false
const CAN_REFILL = false

const RELOADING_ANIM_NAME = ""

const DAMAGE = 40

const IDLE_ANIM_NAME = "Knife_idle"
const FIRE_ANIM_NAME = "Knife_fire"

var is_weapon_enabled = false

var player_node = null

func _ready():
	pass

func fire_weapon():
	var area = $Area
	var bodies = area.get_overlapping_bodies()

	for body in bodies:
		if body == player_node:
			continue

		if body.has_method("bullet_hit"):
			body.bullet_hit(DAMAGE, area.global_transform)
			
	player_node.create_sound("Knife_Swing", self.global_transform.origin)

func equip_weapon():
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		is_weapon_enabled = true
		return true

	if player_node.animation_manager.current_state == "Idle_unarmed":
		player_node.animation_manager.set_animation("Knife_equip")
		rpc_id(1, "rpc_equip_knife", player_node)

	return false

func unequip_weapon():
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		player_node.animation_manager.set_animation("Knife_unequip")
		rpc_id(1,"rpc_unequip_knife", player_node)

	if player_node.animation_manager.current_state == "Idle_unarmed":
		is_weapon_enabled = false
		return true

	return false

func reload_weapon():
	return false

puppet func rpc_equip_knife(player_node):
	self.player_node.animation_manager.set_animation("Knife_equip") #self needed to refer to this player
	
puppet func rpc_unequip_knife(player_node):
	self.player_node.animation_manager.set_animation("Knife_unequip")

