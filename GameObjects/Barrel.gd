extends Entity

func _process(delta):
	._process(delta)
	
	.before_process(delta)
	.after_process(delta)

func explode():
	var explosion = preload("res://Explosion.tscn").instance()
	explosion.global_position = global_position
	Global.get_scene().add_child(explosion)

	$ExplosionArea.monitoring = true
	yield(get_tree().create_timer(.15), "timeout")
	queue_free()

func _on_Area2D_area_entered(area: Area2D):
	var body = area.get_parent() as Node2D
	if body.is_in_group("Bullet") or body.is_in_group("EnemyBullet"):
		body.queue_free()
		explode()


func _on_ExplosionArea_body_entered(body: Node2D):
	if body == self:
		return
	
	if body.is_in_group("Barrel"):
		body.explode()
	elif body.has_method("take_damage"):
		body.take_damage(1.375, self, 5, false)
