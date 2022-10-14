extends CPUParticles2D

var player : Player
var stopped = false
var player_stands_on = false

var start_heal_time = 0
var heal_interval = 500
var heal_power = .0275

var freshness = 1
var staling_speed_sec = 15

var heal_particle_scene = preload("res://HealParticle.tscn")

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
	scale.x += .15
	scale.y += .15
	set_process_internal(false)

func _process(delta):
	if stopped:
		set_process_internal(false)
	
	var elapsed = OS.get_ticks_msec() - start_heal_time
	if player_stands_on and player.ejected_heart and elapsed > heal_interval:
		start_heal_time = OS.get_ticks_msec()
		player.health_manager.health += heal_power * freshness
		
		var heal_particle = heal_particle_scene.instance()
		heal_particle.global_position = player.global_position
		heal_particle.emitting = true
		# heal_particle.show_behind_parent = true
		get_parent().call_deferred("add_child", heal_particle)


# We assume that the only thing that can get in is player
func _on_Area2D_area_entered(area: Area2D):
	player_stands_on = true



func _on_Area2D_area_exited(area: Area2D):
	player_stands_on = false
