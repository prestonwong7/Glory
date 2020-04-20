extends RigidBody

const BASE_BULLET_BOOST = 9;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func bullet_hit(damage, bullet_global_trans):
		var direction_vect = bullet_global_trans.basis.z.normalized() * BASE_BULLET_BOOST
		
		apply_impulse((bullet_global_trans.origin - global_transform.origin).normalized(), direction_vect * damage)
