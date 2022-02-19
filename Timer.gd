extends Node2D

signal timeout

var startTime = 0

export(int) var TIME_PERIOD = 0.5 # 500ms

func _process(delta):
	startTime += delta
	if startTime > TIME_PERIOD:
		emit_signal("timeout")
		startTime = 0
