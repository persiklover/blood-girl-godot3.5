extends Control

var player : Player

func _ready():
	player = Global.get_player()
	player.connect("health_changed", self, "_on_health_changed")


func _on_health_changed(health: float):
	# Update health bar
	$HealthBar.rect_scale.x = (health / player.max_health)
