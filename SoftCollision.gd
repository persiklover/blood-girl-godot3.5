extends Area2D

class_name SoftCollision

func is_colliding() -> bool:
	var areas = get_overlapping_areas()
	return areas.size() > 0

func get_push_vector() -> Vector2:
	var areas = get_overlapping_areas()
	var push_vector = Vector2.ZERO
	if is_colliding():
		var area = areas[0] as Area2D
		push_vector = area.global_position.direction_to(global_position)
	
	return push_vector 
