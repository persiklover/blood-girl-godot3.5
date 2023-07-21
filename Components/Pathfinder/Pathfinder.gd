extends Node2D

onready var astar = Global.get_astar()
onready var rayrect = $RayRect
onready var line = $Line2D

var destination = null

const SPEED = 25
var direction = Vector2.ZERO

var start_time = OS.get_ticks_msec()
var path = []

func find_path(position: Vector2):
	var direction = Vector2.ZERO

	var start_position = global_position
	var end_position = position
	if abs(start_position.length() - end_position.length()) < 1:
		return null
	
	var angle_to_target = rayrect.global_position.angle_to_point(end_position)
	var distance_to_target = rayrect.global_position.distance_to(end_position)
	rayrect.rotation = angle_to_target

	var collision_shape = rayrect.find_node("CollisionShape2D")
	var collision_width = (distance_to_target / 2)
	collision_shape.shape.extents.x =  collision_width
	collision_shape.position.x      = -collision_width
	
	# Бежим напрямую, если это возможно
	if rayrect.get_overlapping_bodies().size() == 0:
		direction = (end_position - start_position).normalized()
		path = []
	else:
		if OS.get_ticks_msec() - start_time > 500:
			start_time = OS.get_ticks_msec()
			path = astar.FindPath(owner.global_position, end_position)
			if not path:
				path = []
			path.remove(0)

		if path.size() > 0:
			var goal = path[0]
			direction = owner.global_position.direction_to( goal )
		else:
			direction = (end_position - start_position).normalized()
	
	line.clear_points()
	if path.size() > 0:
		line.global_position = Vector2.ZERO
		for pos in path:
			line.add_point(pos)
	
	return direction

func _process(delta):
	if destination != null:
		direction = find_path(destination)
		if direction == null:
			return
		var velocity = direction * SPEED
		# Постепенно гасит скорость
		velocity = velocity.move_toward(Vector2.ZERO, delta * 160)
		velocity = owner.move_and_slide(velocity)
