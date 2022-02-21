extends Node

signal health_changed(health)
signal died()

var health = .5 setget set_health

func _ready():
	set_health(health)

func set_health(value):
	health = value
	if health > 1:
		health = 1
	emit_signal("health_changed", health)
	if health <= 0:
		health = 0
		emit_signal("died")
