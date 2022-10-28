extends Node2D

onready var FPS = $ForegroundLayer/CanvasLayer/FPS

const WIDTH  = 1280 # 426  # 459
const HEIGHT = 720  # 428  # 266 # 228

onready var player : Player
onready var camera : Camera2D

onready var viewport : Viewport = get_viewport()

var is_movement_disabled = false
var is_using_controller  = false
var pacifist_mode        = false
var invincible           = false
var invfinite_ammo       = false
var invincible_enemies   = false
var current_interactive_area : Area2D

var your_mom = INF

func get_animation_player() -> AnimationPlayer:
	return get_scene().find_node("GlobalAnimationPlayer") as AnimationPlayer


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	player = get_player()
	camera = get_camera()
	
	viewport.size = Vector2(WIDTH, HEIGHT)
	
	VisualServer.set_default_clear_color(Color("#222034"))
	
	camera.set_physics_process_internal(false)
	yield(get_tree().create_timer(0.001), "timeout")
	camera.set_physics_process_internal(true)

func _process(_delta):
	if is_instance_valid(camera) and is_instance_valid(player):
		camera.global_position = player.global_position
	
	if FPS:
		FPS.content = str( Performance.get_monitor(Performance.TIME_FPS) )

func get_player() -> Player:
	if player:
		return player
		
	return get_scene().find_node("Player") as Player

func get_scene() -> Node:
	return get_tree().current_scene

func get_camera() -> Camera2D:
	if camera:
		return camera
	
	return get_scene().find_node("Camera2D") as Camera2D
	
func get_crosshair() -> Node2D:
	var crosshair = get_scene().find_node("Crosshair")
	return crosshair

func get_cutscene() -> AnimationPlayer:
	var anim_player = get_scene().find_node("Cutscenes")
	return anim_player

func get_ysort() -> YSort:
	var node = get_scene().find_node("YSort")
	return node

func get_pathfinder() -> Pathfinder:
	var pathfinder = get_scene().find_node("Pathfinder")
	return pathfinder

func get_grid() -> Grid:
	var grid = get_scene().find_node("Grid")
	return grid
