extends Node2D

onready var player_scene = preload("res://Player.tscn")

export (PackedScene) var scene: PackedScene

func _on_Area2D_body_entered(body: Node2D):
	var global_animation_player = Global.get_animation_player()
	global_animation_player.play("SCENE_TRANSITION_IN")
	yield(global_animation_player, "animation_finished")
	
	var player_clone = body.duplicate()
	player_clone.set_owner(null)
	
	var level = owner.find_node("Level") as Node2D
	level.queue_free()
	
	var current_scene = Global.get_scene()
	
	var next_scene = load(scene.resource_path).instance()
	current_scene.add_child(next_scene)
	
	var insert_node = next_scene.find_node("YSort");
	insert_node.add_child(player_clone)
	
	Global.player = player_clone
	Global.camera = player_clone.find_node("Camera2D")
	
	var respawn = next_scene.find_node("Respawn") as Position2D
	Global.player.global_position = respawn.global_position
	
	global_animation_player.play("SCENE_TRANSITION_OUT")
