extends KinematicBody2D

export (int) var damage = 1
export (int) var movement_speed = 375

onready var player: Player = Global.get_player()

onready var area = $Area2D
onready var grab_point = $GrabPoint

var carried = false
var active = false

var direction = Vector2.ZERO

func _ready():
	area.connect("area_entered", self, "_on_Area2D_area_entered")


func _process(delta):
	if direction.length() != 0:
		move_and_collide(direction * movement_speed * delta)


func destroy():
	queue_free()


func _on_Area2D_area_entered(area: Area2D):
	if area.is_in_group("PlayerHand"):
		yield(get_tree().create_timer(.07), "timeout")
		player.carry(self)
		$Shadow.hide()
	
	if active:
		if area.is_in_group("EnemyHitbox"):
			queue_free()
