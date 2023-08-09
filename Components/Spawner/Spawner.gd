extends Node2D

export(PackedScene) var scene

func spawn():
	var heart = scene.instance()
	heart.global_position = get_parent().global_position
	var ysort = Global.get_ysort()
	if ysort:
		ysort.call_deferred("add_child", heart)
