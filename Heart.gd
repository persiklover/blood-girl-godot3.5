extends StaticBody2D

export(float) var health_gain = .2

onready var sprite = $AnimatedSprite

func _on_InteractiveArea_activated():
	var player : Player = Global.get_player()
	player.eat(self)
	yield(player, "finished_eating")
	player.health_manager.health += health_gain
	queue_free()
