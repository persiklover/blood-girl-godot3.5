extends CPUParticles2D

var player : Player
var stopped = false
var player_stands_on = false

var start_heal_time = 0
var heal_interval = 50
var heal_power = .005

var freshness = 1
var staling_speed_sec = 10

func _ready():
	player = Global.get_player()
	
	yield(get_tree().create_timer(staling_speed_sec), "timeout")
	freshness = .666
	color = color.darkened(.2)
	set_process_internal(true)
	
	yield(get_tree().create_timer(staling_speed_sec), "timeout")
	freshness = .333
	color = color.darkened(.35)
	set_process_internal(true)

func _on_Timer_timeout():
	stopped = true
	set_process_internal(false)

func _process(delta):
	if stopped:
		set_process_internal(false)
	
	var elapsed = OS.get_ticks_msec() - start_heal_time
	if player_stands_on and player.ejected_heart and elapsed > heal_interval:
		start_heal_time = OS.get_ticks_msec()
		player.health_manager.health += heal_power * freshness


# We assume that the only thing that can get in is player
func _on_Area2D_area_entered(area: Area2D):
	player_stands_on = true



func _on_Area2D_area_exited(area: Area2D):
	player_stands_on = false
