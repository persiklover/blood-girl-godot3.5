extends Alive

class_name Entity

onready var debugging = get_tree().debug_collisions_hint
onready var rayrect: Area2D = $RayRect
onready var pathfinder : Pathfinder = Global.get_pathfinder()
onready var dust_scene = preload("res://Dust.tscn")

var movement_speed = 65
export(bool) var facing_right = false

var direction: Vector2
var velocity : Vector2 = Vector2.ZERO

var can_spawn_dust = true

# PATHFINDING
var destination
var destination_safe_distance
var breadcrumbs = []
var last_found_path_time = OS.get_system_time_msecs()

# EXPERIMENTAL
var stunned = false


func move_towards_destination():
	if destination != null:
		direction = (destination - global_position).normalized()
		facing_right = direction.x >= 0
		
		var safe_distance = 4
		if destination_safe_distance != null:
			safe_distance = destination_safe_distance
		
		if global_position.distance_to(destination) <= safe_distance:
			direction = Vector2.ZERO
			# Ищем ближайшую точку назначения
			if breadcrumbs.size() > 0:
				destination = breadcrumbs.pop_front()
			else:
				destination = null
				destination_safe_distance = null
				_on_reached_destination()
		
		# Ensures we check for path even when moving in straight line
		if destination != null and breadcrumbs.size() == 0 and should_find_path():
			find_path(destination, destination_safe_distance)


func should_find_path():
	return OS.get_system_time_msecs() - last_found_path_time > 350


func find_path(end_position: Vector2, safe_distance = 4):
	var start_position = global_position
	
	var angle_to_target = rayrect.global_position.angle_to_point(end_position)
	var distance_to_target = rayrect.global_position.distance_to(end_position)
	rayrect.rotation = angle_to_target

	var collision_shape = rayrect.find_node("CollisionShape2D")
	var collision_width = (distance_to_target / 2)
	collision_shape.shape.extents.x =  collision_width
	collision_shape.position.x      = -collision_width
	
	# Если можно бежать напрямую - бежим напрямую
	if rayrect.get_overlapping_bodies().size() == 0:
		direction = (end_position - start_position).normalized()
		cancel_path()
		destination = end_position
		destination_safe_distance = safe_distance
	# Прокладываем путь
	elif should_find_path():
		destination_safe_distance = null
		last_found_path_time = OS.get_system_time_msecs()
		
		var path = pathfinder.find_path(start_position, end_position)
		if path != null and path.size() > 0:
			breadcrumbs = path
			breadcrumbs.pop_front()
			destination = breadcrumbs.pop_front()


func go_to(dest: Vector2):
	find_path(dest)


func cancel_path():
	breadcrumbs = []
	destination = null


func before_process(_delta):
	direction = Vector2.ZERO


func after_process(delta):
	if get_tree().debug_collisions_hint:
		debug()
	
	if direction.length() > 0:
		facing_right = direction.x >= 0
		velocity = direction * movement_speed
		
		rayrect.visible = true

		if can_spawn_dust:
			spawn_dust()
			can_spawn_dust = false
			yield(get_tree().create_timer(.35), "timeout")
			can_spawn_dust = true
	else:
		rayrect.visible = false
	
	# Постепенно гасит скорость
	velocity = velocity.move_toward(Vector2.ZERO, delta * 160)
	velocity = move_and_slide(velocity)


func spawn_dust():
	var dust = dust_scene.instance()
	dust.global_position = self.global_position
	dust.show_behind_parent = true
	get_parent().call_deferred("add_child", dust)


func stun(time: float = 1):
	stunned = true
	direction = Vector2.ZERO
	velocity  = Vector2.ZERO
	yield(get_tree().create_timer(time), "timeout")
	stunned = false


func _on_reached_destination():
	pass


func debug():
	# Визуализация пути
	var path_visualizer = find_node("PathLine")
	if path_visualizer:
		var path = breadcrumbs + []
		if breadcrumbs.size() == 0 and destination != null:
			path = [destination]
		path.push_front(global_position)
		path_visualizer.points = path
		for i in range(path_visualizer.points.size()):
			path_visualizer.points[i] -= global_position
		
		if self.is_dead:
			path_visualizer.points = []
	
	# Debug moving direction
	var direction_node = find_node("Direction")
	if direction_node:
		direction_node.cast_to = direction * 7
