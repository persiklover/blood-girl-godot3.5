extends Position2D

onready var text = $Text
onready var animation_player = $AnimationPlayer

var damage: float = 0

func _ready():
	text.content = str(damage)
	animation_player.play("DEFAULT")
	yield(animation_player, "animation_finished")
	queue_free()
