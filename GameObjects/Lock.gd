extends Area2D

onready var text = $Text

signal unlocked()

func _ready():
	text.hide()


func _on_body_entered(body: Node):
	if body.is_in_group("Player"):
		if body.has_key:
			emit_signal("unlocked")
			hide()
			$SFX.play()
			yield($SFX, "finished")
			queue_free()
		else:
			text.show()


func _on_body_exited(body: Node):
	if body.is_in_group("Player"):
		text.hide()
