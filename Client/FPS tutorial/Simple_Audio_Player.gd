extends Spatial

var audio_pistol_shot = preload("res://Audio/Pistol_Shot.wav")
var audio_gun_cock = preload("res://Audio/Gun_Cock.wav")
var audio_rifle_shot = preload("res://Audio/Rifle_Shot.wav")
var audio_knife_swing = preload("res://Audio/Knife_Swing.wav")

var audio_node = null

# Called when the node enters the scene tree for the first time.
func _ready():
	audio_node = $Audio_Stream_Player
	audio_node.connect("finished", self, "destroy_self")
	audio_node.stop()

# position null is to make it optional to be in it = smart
func play_sound(sound_name, position = null):
	if audio_pistol_shot == null or audio_rifle_shot == null or audio_gun_cock == null:
		print("Audio not set")
		queue_free()
		return
	
	if sound_name == "Pistol_Shot":
		audio_node.stream = audio_pistol_shot
	elif sound_name == "Gun_Cock":
		audio_node.stream = audio_gun_cock
	elif sound_name == "Rifle_Shot":
		audio_node.stream = audio_rifle_shot
	elif sound_name == "Knife_Swing":
		audio_node.stream = audio_knife_swing
	else:
		print("Unknown stream!")
		queue_free()
		return
		
	if audio_node is AudioStreamPlayer3D:
		if position != null:
			audio_node.global_transform.origin = position
			
	audio_node.play()

func destroy_self():
	audio_node.stop()
	queue_free()
