extends KinematicBody2D

class_name Bullet

export (int) var damage = 1
export (int) var speed = 520
export (int) var max_hits = 1

var initiator: Node2D
var direction = Vector2.ZERO

var hit_number = 0 setget set_hit_number
func set_hit_number(value: int):
	hit_number = value
	if hit_number >= max_hits:
		queue_free()


func _ready():
	$AnimationPlayer.play("DEFAULT")


func _process(delta):
	var collision = move_and_collide(direction * speed * delta)
	if collision != null:
		# amongus
		queue_free()


func _on_Lifespan_timeout():
	# Убиваем пулю, если кончился срок ее жизни
	queue_free()
