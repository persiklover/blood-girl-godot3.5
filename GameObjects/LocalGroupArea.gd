extends Area2D

class_name LocalGroupArea

func number_of(group: String) -> int:
	var num: int = 0
	for body in get_bodies():
		if body.is_in_group(group):
			num += 1
	return num


func has(group: String) -> bool:
	return number_of(group) > 0


func get_group_member(group: String):
	for body in get_bodies():
		if body.is_in_group(group):
			return body
	return null


func size() -> int:
	return get_bodies().size()


func get_bodies() -> Array:
	return get_overlapping_bodies()
