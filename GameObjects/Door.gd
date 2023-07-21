extends Node2D

export (bool) var disabled = false
export(String, FILE, "*.tscn") var path_to_scene

onready var area = $Area2D

func _on_Area2D_body_entered(_body: Node2D):
	if disabled:
		return
	disabled = true
	
	var scene = ResourceLoader.load(path_to_scene)
	Global.transition_to_scene(scene)
	# Prevent triggering twice
	area.queue_free()


func _on_Lock_unlocked():
	disabled = false
