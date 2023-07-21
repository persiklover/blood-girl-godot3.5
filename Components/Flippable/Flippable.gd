extends Node2D

tool

export (bool) var v_flip = false
export (Vector2) var origin = Vector2.ZERO

func _process(delta):
	if v_flip:
		position.x = origin.x * 2
		scale.x = -1
	else:
		position.x = 0
		scale.x = 1
	pass
