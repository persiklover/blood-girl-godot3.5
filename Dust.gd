extends AnimatedSprite

func _ready():
	playing = true


func _on_Dust_animation_finished():
	queue_free()
