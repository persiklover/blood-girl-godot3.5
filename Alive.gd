extends Stateful

class_name Alive

signal health_changed(health)
signal died()

var health_manager = preload("res://HealthManager.gd").new()

var health: float = health_manager.health setget set_health,get_health

func set_health(value: float):
	health_manager.health = value
	
func get_health():
	return health_manager.health


var is_dead: bool setget ,get_is_dead

func get_is_dead():
	return self.health <= 0


func _ready():
	health_manager.connect("health_changed", self, "_on_health_changed")
	health_manager.connect("died", self, "_on_died")


func _process(delta):
	._process(delta)


func take_damage(damage: float):
	self.health -= damage


func _on_health_changed(health: float):
	emit_signal("health_changed", health)


func _on_died():
	emit_signal("died")
