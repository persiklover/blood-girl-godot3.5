extends Area2D


export var lifespan = 1
var birth_time : int

func _ready():
	birth_time = OS.get_ticks_msec()
	yield(get_tree().create_timer(lifespan), "timeout")
	queue_free()
