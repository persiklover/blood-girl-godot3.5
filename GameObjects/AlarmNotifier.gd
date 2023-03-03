extends Node2D

# Аларм захватил врага
func _on_ReactArea_body_entered(body: Node2D):
	if body == self or body == self.get_parent():
		return
	
	if body.is_in_group("Enemy"):
		return
		body.player_inside_visibility_area = true
