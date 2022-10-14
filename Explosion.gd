extends Node2D

func _ready():
	$Particles2D.one_shot = true
	$Particles2D.emitting = true
	yield(get_tree().create_timer(1), "timeout")
	queue_free()
