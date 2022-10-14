extends Camera2D

class_name MainCamera

onready var timer = $ShakeTimer
onready var player = Global.get_player()

export var amplitude = 3.0

var default_offset = offset

var shake = false setget set_shake

func set_shake(value: bool):
	shake = value
	offset = default_offset
	if shake:
		timer.start()


func _ready():
	randomize()


func _process(delta):
	offset = default_offset

	# var threshhold = 70
	# var cursor_position = player.global_position + get_local_mouse_position() - offset
	# var diff = cursor_position - player.global_position
	# diff /= 4
	# diff.x = clamp(diff.x, -threshhold, threshhold)
	# diff.y = clamp(diff.y, -threshhold, threshhold)
	# offset = diff

	if not shake:
		return
	
	var damping = ease(timer.time_left / timer.wait_time, 1.0)
	offset += Vector2(
		rand_range(amplitude, -amplitude) * damping,
		rand_range(amplitude, -amplitude) * damping
	)
	# offset += default_offset


func shake(_time = 0.225, _amplitude = 0.85):
	amplitude  = _amplitude
	timer.wait_time = _time
	set_shake(true)


func _on_ShakeTimer_timeout():
	set_shake(false)
