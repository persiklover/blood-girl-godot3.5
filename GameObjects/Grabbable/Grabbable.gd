extends KinematicBody2D

onready var player: Player = Global.get_player()

onready var grab_point = $GrabPoint

var carried = false
var active = false

var direction = Vector2.ZERO
var movement_speed = 0

func _ready():
	get_node("Area2D").connect("area_entered", self, "_on_Area2D_area_entered")


func _process(delta):
	if direction.length() != 0:
		move_and_collide(direction * movement_speed * delta)


func _on_Area2D_area_entered(area: Area2D):
	print("!!! ", area)
	if area.is_in_group("PlayerHitbox"):
		yield(get_tree().create_timer(.07), "timeout")
		player.carry(self)
	
	if active:
		if area.is_in_group("EnemyHurtbox"):
			queue_free()
