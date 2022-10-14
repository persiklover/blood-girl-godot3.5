extends Node2D

export (String, MULTILINE) var description


# Игрок вошел в зону покупки
func _on_Area2D_body_entered(body):
	$Text.content = description + "\n(Grab)"


func _on_Area2D_body_exited(body):
	$Text.content = ""
