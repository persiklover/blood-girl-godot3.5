extends Control

var player : Player

func _ready():
	player = Global.get_player()
	player.health_manager.connect("health_changed", self, "_on_health_changed")

func _on_health_changed(health: float):
	# Update health bar
	$HealthBar.rect_scale.x = health
