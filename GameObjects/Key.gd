extends Area2D

func _on_body_entered(body: Node):
	if body.is_in_group("Player"):
		body.has_key = true
		queue_free()
