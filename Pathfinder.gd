extends Node2D

class_name Pathfinder

onready var grid = $Grid
onready var player = Global.get_player() as Player

var START = Vector2(1, 1)
var END   = Vector2(3, 1)

func find_path(from_position: Vector2, to_position: Vector2):
	var start_time = OS.get_ticks_msec()
	grid.clear_grid()
	
	var start_node = grid.get_node_from_position(from_position.x, from_position.y)
	if start_node == null or not grid.get_node_at(start_node.x, start_node.y).walkable:
		print('starting point is not walkable!')
		return
		pass
	var end_node = grid.get_node_from_position(to_position.x, to_position.y)
	if end_node == null or not grid.get_node_at(end_node.x, end_node.y).walkable:
		print('destination point is not walkable!')
		return
		pass
	
	var open_list   = []
	var closed_list = []
	
	open_list.push_back(start_node)
	
	var MAX_ITERATIONS = 1_000
	var step = 0
	while open_list.size() > 0:
		step += 1
		if step > MAX_ITERATIONS:
			return
		
		var current_node = open_list[0]
		for open_node in open_list:
			if (
				 open_node.f_cost < current_node.f_cost or 
				(open_node.f_cost == current_node.f_cost and open_node.h_cost < current_node.h_cost)
			):
				current_node = open_node
		
		open_list.erase(current_node)
		closed_list.push_back(current_node)
		
		if current_node == end_node:
			var path = []
			var parent = current_node.parent
			while parent != null:
				path.push_front(Vector2(parent.global_position.x, parent.global_position.y))
				parent = parent.parent
			
			#path.push_back(to_position)
			return path
		
		# Проходимся по всем соседним клеткам
		var adjacent_nodes = []
		for i in [-1, 0, 1]:
			for j in [-1, 0, 1]:
				# Не проверяем текущую клетку
				if i == 0 and j == 0:
					continue
				
				var x = current_node.x + i
				var y = current_node.y + j
				var neighbour = grid.get_node_at(x, y)
				if neighbour == null:
					continue
				
				if not neighbour.walkable or closed_list.has(neighbour):
					continue
				
				var movement_cost_to_neighbour = current_node.g_cost + current_node.distance_to(neighbour)
				if movement_cost_to_neighbour < neighbour.g_cost or not open_list.has(neighbour):
					neighbour.g_cost = movement_cost_to_neighbour
					neighbour.h_cost = neighbour.distance_to(end_node)
					neighbour.parent = current_node
					
					if not open_list.has(neighbour):
						open_list.push_back(neighbour)


func _on_Grid_after_process():
	return
	
