extends Sprite

onready var player = Global.get_player()

const MAX_DISTANCE = 32

func _physics_process(_delta):
	global_position = get_global_mouse_position()


func play(anim: String):
	$AnimationPlayer.play(anim)
