tool

extends Node2D

class_name Grid

const ROWS = 75
const COLS = 60
const SIZE = 12
var adjacement_vector = Vector2(SIZE / 2, SIZE / 2)

export (bool) var show_grid = false

var grid = create_grid()

onready var player = Global.get_player()

class GridNode:
	var walkable = true
	var content = null
	var x = null
	var y = null
	var global_position = Vector2.ZERO
	var parent: GridNode
	
	var g_cost = 0
	var h_cost = 0
	var f_cost = 0 setget ,get_f_cost
	
	func _init(_x: int, _y: int):
		x = _x
		y = _y
		
		return self
	
	func reset():
		walkable = true
		
		clear()
		
		return self
	
	func clear():
		content  = null
		parent   = null
		
		g_cost = 0
		h_cost = 0
		f_cost = 0
		
		return self
	
	func get_f_cost():
		return g_cost + h_cost
	
	func distance_to(node: GridNode) -> int:
		var diagonal_distance = Vector2(0, 0).distance_to(Vector2(SIZE, SIZE))
		var dist_x = abs( x - node.x )
		var dist_y = abs( y - node.y )
		if dist_x > dist_y:
			return diagonal_distance * dist_y + SIZE * (dist_x - dist_y)
		return diagonal_distance * dist_x + SIZE * (dist_y - dist_x)


func create_grid() -> Array:
	var grid = []
	for x in range(ROWS):
		var col = []
		col.resize(COLS)
		grid.append(col)
	return grid


# Очищает 2-мерный массив
func clear_grid():
	for x in range(ROWS):
		for y in range(COLS):
			var node = get_node_at(x, y)
			node.clear()


func reset_grid():
	for x in range(ROWS):
		for y in range(COLS):
			var node = get_node_at(x, y)
			if node == null:
				node = GridNode.new(x, y)
				grid[x][y] = node
			node.reset()


func _ready():
	reset_grid()
	
	for x in range(ROWS):
		for y in range(COLS):
			var area = Area2D.new() as Area2D
			area.position = Vector2(x * SIZE, y * SIZE) + adjacement_vector
			area.collision_layer = pow(2, 1-1) + pow(2, 10-1)
			area.collision_mask  = pow(2, 1-1) + pow(2, 10-1)
			
			var rectangle_shape = RectangleShape2D.new()
			rectangle_shape.extents.x = SIZE / 2;
			rectangle_shape.extents.y = SIZE / 2;
			
			var collision_shape = CollisionShape2D.new()
			collision_shape.shape = rectangle_shape
			
			area.add_child(collision_shape)
			
			add_child(area)
			
			grid[x][y].global_position = area.global_position


var start_time = OS.get_system_time_msecs()

func _physics_process(_delta):
	# Показывает стены при запуске
	if show_grid:
		update()
		return
	
	if OS.get_system_time_msecs() - start_time > 600:
		start_time = OS.get_system_time_msecs()
		reset_grid()
		
		for area in get_children():
			var overlapping_bodies = area.get_overlapping_bodies()
			for body in overlapping_bodies:
				var exception_groups = [
					"Enemy",
					"Player",
					"Bullet",
					"EnemyBullet"
				]
				var found = false
				for group in exception_groups:
					if body.is_in_group(group):
						found = true
						break
				
				if found:
					continue
				
				var x = ((area.position - adjacement_vector) / SIZE).x
				var y = ((area.position - adjacement_vector) / SIZE).y
				grid[x][y].walkable = false
				break


func get_node_at(x, y) -> GridNode:
	if x >= ROWS or y >= COLS:
		return null
	return grid[x][y]


func get_node_from_position(pos_x, pos_y):
	for x in range(ROWS):
		for y in range(COLS):
			var node = get_node_at(x, y)
			if node != null and (
				pos_x >= node.global_position.x - SIZE / 2 and
				pos_x <= node.global_position.x + SIZE / 2 and
				pos_y >= node.global_position.y - SIZE / 2 and
				pos_y <= node.global_position.y + SIZE / 2
			):
				return node


func set_cell(x, y, value):
	grid[x][y].content = value


func get_cell_position(vector: Vector2) -> Vector2:
	return grid[vector.x][vector.y].coords


func _draw():
	if not show_grid:
		return
	
	for x in range(ROWS):
		for y in range(COLS):
			var color = Color.gray
			var filled = false
			
			var node = get_node_at(x, y)
			if node == null:
				if show_grid:
					draw_rect(Rect2(x * SIZE, y * SIZE, SIZE, SIZE), color, filled)
				continue

			if not node.walkable:
				color = Color.rebeccapurple
				filled = true
			else:
				match node.content:
					"S":
						color = Color.deepskyblue
					"E":
						color = Color.palevioletred
					"O":
						color = Color.darkorange
					"C":
						color = Color.red
				filled = true
			
			draw_rect(Rect2(x * SIZE, y * SIZE, SIZE, SIZE), color, filled)
