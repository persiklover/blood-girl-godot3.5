extends EnemyBase

func _ready():
	print("I'm a rat!")


func _process(delta):
	.before_process(delta)

	if direction.length() > 0:
		$AnimatedSprite.flip_h = true if direction.x > 0 else false

	.after_process(delta)


func _on_Hitbox_area_entered(area: Area2D):
	var parent = area.get_parent()
	if parent.is_in_group("PlayerBullet"):
		queue_free()
