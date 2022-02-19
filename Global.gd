extends Node2D

const WIDTH  = 256
const HEIGHT = WIDTH / 1.65

var is_movement_disabled = false
var is_using_controller  = false
var pacifist_mode = false
var current_interactive_area : Area2D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	var viewport : Viewport = get_viewport()
	viewport.size = Vector2(WIDTH, HEIGHT)

func _process(delta):
	var player = get_player()
	var camera = get_camera()
	camera.global_position = player.global_position
	
	get_scene().find_node("Crosshair").global_position = get_global_mouse_position()

func get_player():
	var player : Player = get_scene().find_node("Player")
	return player

func get_scene() -> Node:
	return get_tree().get_current_scene()

func get_camera() -> Camera2D:
	var camera = get_scene().find_node("Camera2D")
	return camera
	
func get_crosshair() -> Node2D:
	var crosshair = get_scene().find_node("Crosshair")
	return crosshair

func get_ysort() -> YSort:
	var node = get_scene().find_node("YSort")
	return node
