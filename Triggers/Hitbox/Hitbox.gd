extends Area2D

export(float) var multiplier = 1.0

signal got_damage(damage, from, type)

func handle_damage(damage: float):
	return round(damage * multiplier)

func _on_area_entered(area: Area2D):
	var object: Node2D = area.get_parent()

	if area.is_in_group("PlayerHand"):
		var player = Global.get_player()
		emit_signal("got_damage", handle_damage(1), player, "hand")

	elif object.is_in_group("Grabbable"):
		var grabbable = object
		if grabbable.active:
			grabbable.destroy()
			emit_signal("got_damage", handle_damage(grabbable.damage), grabbable, "default")

	elif object.is_in_group("PlayerBullet"):
		var bullet = object
		emit_signal("got_damage", handle_damage(bullet.damage), bullet, "bullet")

	# Legacy
	elif object.is_in_group("Bonfire"):
		emit_signal("got_damage", Global.your_mom)

