extends Node

signal health_changed(health)
signal died()

onready var healthbar = $HealthBar/Progress

export (int) var max_health = 1
var health = 1 setget set_health

func set_health(value):
	health = max(0, value)
	emit_signal("health_changed", health)
	
	if health == 0:
		emit_signal("died")
	
	# Update healthbar
	var percent = health / max_health
	var color: Color
	if percent < .33:
		color = Color.red
	elif percent < .66:
		color = Color.orange
	else:
		color = Color.green
	healthbar.rect_scale.x = percent
	healthbar.color = color


var is_dead: bool setget ,get_is_dead

func get_is_dead():
	return self.health <= 0


func _ready():
	health = max_health
	connect("health_changed", self, "_on_health_changed")
	connect("died", self, "_on_died")


func take_damage(damage: float):
	self.health -= damage


func die():
	self.health = 0


func _on_health_changed(health: float):
	pass


func _on_died():
	pass
