extends KinematicBody2D

onready var destroy_vfx = preload("res://GameObjects/Grabbable/Branch/BranchDestroyVFX.tscn")
onready var player = Global.get_player()
onready var grab_point = $GrabPoint

var carried = false
var active = false

var damage = 1
var movement_speed = 380
var direction: Vector2

func _process(delta):
	if direction.length() != 0:
		move_and_collide(direction * movement_speed * delta)


func _on_Area2D_area_entered(area: Area2D):
	if area.is_in_group("PlayerHand"):
		yield(get_tree().create_timer(.07), "timeout")
		player.carry(self)


func destroy():
	active = false

	var vfx = destroy_vfx.instance()
	vfx.global_position = global_position
	vfx.rotation = direction.angle()
	vfx.emitting = true
	vfx.show_on_top = true
	get_parent().call_deferred("add_child", vfx)

	hide()
	$SFX.play()
	yield($SFX, "finished")
	queue_free()
