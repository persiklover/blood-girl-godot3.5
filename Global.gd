extends Node2D

onready var fps = get_scene().find_node("FPS")

const WIDTH  = 396 # 421 # 459
const HEIGHT = 228 # 219 # 228

onready var player : Player
onready var camera : Camera2D

onready var viewport : Viewport = get_viewport()

var is_movement_disabled = false
var is_using_controller  = false
var pacifist_mode        = false
var invincible           = true
var invfinite_ammo       = false
var invincible_enemies   = false
var current_interactive_area : Area2D

var your_mom = INF

func get_animation_player() -> AnimationPlayer:
	return get_scene().find_node("GlobalAnimationPlayer") as AnimationPlayer


func _ready():
	randomize()
	
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
	
	if fps:
		fps.content = str( Performance.get_monitor(Performance.TIME_FPS) )

func _input(event):
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
		viewport.size = Vector2(WIDTH, HEIGHT)

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
	return get_scene().find_node("Cutscenes") as AnimationPlayer

func get_ysort() -> YSort:
	return get_scene().find_node("YSort") as YSort

func get_pathfinder() -> Pathfinder:
	var pathfinder = get_scene().find_node("Pathfinder", true, false)
	return pathfinder

func get_grid() -> Grid:
	var grid = get_scene().find_node("Grid")
	return grid

func load_scene(scene: PackedScene):
	var world = Global.get_scene()
	var level = world.find_node("Level") as Node2D
	level.name = 'your_mom'
	level.find_node("YSort").remove_child(player)
	level.queue_free()
	
	var next_scene = scene.instance()
	next_scene.name = "Level"
	var y_sort = next_scene.find_node("YSort")
	y_sort.add_child(player)
	var respawn = next_scene.find_node("Respawn") as Position2D
	player.global_position = respawn.global_position
	world.add_child(next_scene, true)
	next_scene.owner = world


func transition_to_scene(scene: PackedScene):
	is_movement_disabled = true
	pacifist_mode = true
	invincible = true

	var animation_player = Global.get_animation_player()
	animation_player.play("SCENE_TRANSITION_IN")
	yield(animation_player, "animation_finished")
	
	Global.load_scene(scene)
	
	is_movement_disabled = false
	invincible = false

	animation_player.play("SCENE_TRANSITION_OUT")
	yield(animation_player, "animation_finished")

	pacifist_mode = false

