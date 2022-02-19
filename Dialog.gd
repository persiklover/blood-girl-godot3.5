extends Node2D

export (int) var speed = 50
onready var text = $Control/Text

var obj : Array

var is_active = false
var start_time = 0
var current_line = -1

func start(json):
	obj = json
	is_active = true
	start_time = OS.get_ticks_msec()
	
	show()
	$Control.grab_focus()
	Global.is_movement_disabled = true
	
	text.visible_characters = 0
	current_line = -1
	_next_line()
	
func _next_line():
	if current_line + 1 < len(obj):
		current_line += 1
		$Control/Text.bbcode_text = obj[current_line]
		text.visible_characters = 0
	else:
		hide()
		Global.is_movement_disabled = false

func _process(delta):
	var current_time = OS.get_ticks_msec()
	var elapsed = current_time - start_time
	if is_active and elapsed > speed and text.visible_characters < text.text.length():
		start_time = OS.get_ticks_msec()
		text.visible_characters += 1
	
	# Skipping
	if is_active and (Input.is_action_just_released("ui_accept") or Input.is_action_just_released("ui_cancel")):
		if text.visible_characters < text.text.length():
			text.visible_characters = text.text.length()
		else:
			_next_line()
