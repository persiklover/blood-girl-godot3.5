extends KinematicBody2D

onready var player = Global.get_player()

onready var grab_point = $GrabPoint

var carried = false
var active = false

var movement_speed: int
var direction: Vector2

func _init():
	stop_moving()


func _process(delta):
	if direction.length() != 0:
		move_and_collide(direction * movement_speed * delta)


func stop_moving():
	direction = Vector2.ZERO
	movement_speed = 0


func _on_Area2D_area_entered(area: Area2D):
	if area.is_in_group("PlayerHitbox"):
		yield(get_tree().create_timer(.07), "timeout")
		player.carry(self)
		stop_moving()
	
	if active:
		if area.is_in_group("EnemyHurtbox"):
			queue_free()
