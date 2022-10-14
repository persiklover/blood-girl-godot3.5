extends Node2D

func _on_Area2D_body_entered(body: Node2D):
	if body.is_in_group("Bullet"):
		return

	if body.is_in_group("Player") and body.dashing:
		return
	
	body.global_position = global_position + Vector2.UP
	if body.has_method("stun"):
		body.stun(1.5)
	
	$AnimationPlayer.play("ACTIVATE")
	yield($AnimationPlayer, "animation_finished")
	
	if body.is_in_group("Player") and Global.invincible:
		return
	
	if body.has_method("take_damage"):
		body.take_damage(.4, self, 0)