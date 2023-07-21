extends Area2D

signal triggered()

export (int) var damage = 1

func _on_body_entered(body: Node2D):
	pass

func _on_area_entered(area: Area2D):
	var object = area.get_parent()
	if object.is_in_group("Player"):
		var player = object as Player
		if not player.invincible:
			object.take_damage(damage, self)
			emit_signal("triggered")
