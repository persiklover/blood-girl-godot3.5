signal health_changed(health)
signal died()

var health = 1 setget _set_health

func _set_health(value):
	health = max(0, min(value, 1))
	emit_signal("health_changed", health)
	
	if health == 0:
		emit_signal("died")

