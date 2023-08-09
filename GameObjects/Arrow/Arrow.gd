extends KinematicBody2D

export (Vector2) var direction

const SPEED = 90

func _process(delta):
	var collision = move_and_collide(direction * SPEED * delta)
	if collision != null:
		queue_free()


func _on_Timer_timeout():
	queue_free()


func _on_DamageBox_triggered():
	queue_free()
