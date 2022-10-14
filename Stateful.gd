extends KinematicBody2D

class_name Stateful

var curr_state = 0
var prev_state = curr_state

var can_change_state = true

func _process(_delta):
	prev_state = curr_state
