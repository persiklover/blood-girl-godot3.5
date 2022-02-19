extends Sprite

func _ready():
	$AnimationPlayer.play("IDLE")

func play(anim: String):
	$AnimationPlayer.play(anim)
