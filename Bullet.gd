extends KinematicBody2D

class_name Bullet

var direction = Vector2.ZERO
var speed = 0.735 # 1.025

func _ready():
	$AnimationPlayer.play("START")

func _process(delta):
	var collision = move_and_collide(direction.normalized() * speed)
	if collision != null:
		queue_free()
