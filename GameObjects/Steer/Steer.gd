extends Area2D

onready var debugging = get_tree().debug_collisions_hint

onready var player = Global.get_player()
onready var circle = $CollisionShape2D
onready var visualizer = $Visualizer

var undesirable_directions = []

# Throttling
var cached_direction = Vector2.ZERO
var start_time = OS.get_ticks_msec()

var offset = .6

func _ready():
	if not debugging:
		visualizer.hide()


func _input(event):
	if Input.is_action_pressed("ui_page_down"):
		offset -= .05
		print(offset)
	if Input.is_action_pressed("ui_page_up"):
		offset += .05
		print(offset)

func modify_direction(direction: Vector2):
	if OS.get_ticks_msec() - start_time > 60:
		start_time = OS.get_ticks_msec()
	else:
		return cached_direction

	# var desirable_direction = (player.global_position - global_position).normalized()
	var desirable_direction = direction

	# Собираем нежеланные направления
	undesirable_directions = []
	var bodies = []
	for body in get_overlapping_bodies():
		# Don't target self
		if body == get_parent():
			continue
		
		var found = false
		var exception_groups = [
			"Player",
			"Bullet",
			"EnemyBullet",
			"Map"
		]
		for group in exception_groups:
			if body.is_in_group(group):
				found = true
				break
		if found:
			continue
		
		bodies.push_back(body)
		undesirable_directions.push_back((body.global_position - global_position).normalized())
	
	if debugging:
		update()

	if undesirable_directions.size() == 0:
		cached_direction = direction
		return direction

	var lines = visualizer.get_children()
	var directions = []
	var weights = []
	# Задаем длины линий
	for index in range(lines.size()):
		var line: ColorRect = lines[index]

		var dir = Vector2.RIGHT.rotated( deg2rad(line.rect_rotation) );
		directions.push_back(dir)

		var dot = dir.dot(desirable_direction)
		var weigth = dot
		for u_d in undesirable_directions:
			var body_index = bodies.find(u_d)
			var distance = global_position.distance_to( bodies[body_index].global_position )
			# > 0 - аккуратнее обходит
			# < 0 - идет как панк напролом
			# var factor = 1 - (distance / (circle.shape.radius - 15)) - offset
			var factor = offset
			# print(distance, " ", factor)
			weigth -= factor
			# pass
		
		weights.push_back(weigth)

		if debugging:
			# line.rect_scale.x = abs( max(0, weigth) )
			line.rect_scale.x = clamp(weigth, 0, 1)

			line.color = Color.white
			line.show_behind_parent = true
	

	# Находим самую длинную линию
	var max_weight_index = -1
	var max_weight = -INF
	for index in range(lines.size()):
		var weight = weights[index]
		if weight > max_weight:
			max_weight = weight
			max_weight_index = index

	if debugging:
		lines[max_weight_index].color = Color.green
		lines[max_weight_index].show_behind_parent = false
	else:
		visualizer.hide()
	
	direction = directions[max_weight_index].normalized()
	cached_direction = direction
	return direction


func _draw():
	if debugging:
		z_index = 88
		for dir in undesirable_directions:
			draw_circle(dir * 35, 5, Color.red)
