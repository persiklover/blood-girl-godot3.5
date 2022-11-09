extends EnemyBase

onready var blood_vfx = preload("res://BloodVFX2.tscn")
#onready var player = Global.get_player()#

onready var collider = $Collider
onready var hitbox = $Hitbox

func _process(delta):
	.before_process(delta)

	if direction.length() > 0:
		$AnimatedSprite.flip_h = true if direction.x > 0 else false

	.after_process(delta)


func _on_Hitbox_area_entered(area: Area2D):
	var parent = area.get_parent()
	if parent.is_in_group("PlayerBullet"):
		# queue_free()
		take_damage(1)
	
	elif parent.is_in_group("Grabbable"):
		if parent.active:
			# queue_free()
			take_damage(1)


func _on_died():
	._on_died()

	remove_child(collider)
	remove_child(hitbox)

	var blood = blood_vfx.instance()
	blood.global_position = global_position
	blood.emitting = true
	blood.show_behind_parent = true
	get_parent().call_deferred("add_child", blood)\
	

