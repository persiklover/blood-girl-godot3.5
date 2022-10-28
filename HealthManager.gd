signal health_changed(health)
signal died()

var health = 1 setget _set_health

func _set_health(value):
	health = clamp(value, 0, 1)
	emit_signal("health_changed", health)
	
	if health <= 0:
		emit_signal("died")

