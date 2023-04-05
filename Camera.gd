extends Camera2D

class_name MainCamera

var player: Player
onready var timer = $ShakeTimer

export var amplitude = 3.0

var is_shaking: bool = false setget set_shake
func set_shake(value: bool):
	is_shaking = value
	if is_shaking:
		timer.start()


func _ready():
	print("init camera")
	player = get_parent()
	randomize()


func _process(_delta):
	var threshold = 50
	var cursor_position = player.global_position + get_local_mouse_position() - offset
	var target = cursor_position - player.global_position
	target /= 2.25
	var weight = 1
	# var weight = 1 - (target.length() / threshold)
	# weight = clamp(weight, .075, .25)

	if is_shaking:
		var damping = ease(timer.time_left / timer.wait_time, 1.0)
		target += Vector2(
			rand_range(amplitude, -amplitude) * damping,
			rand_range(amplitude, -amplitude) * damping
		)
		weight = 1
	
	offset = lerp(offset, target, weight)


func shake(t = 0.225, ampl = 0.85):
	timer.wait_time = t
	amplitude = ampl
	set_shake(true)


func _on_ShakeTimer_timeout():
	set_shake(false)
