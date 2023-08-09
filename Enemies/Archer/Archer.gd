extends KinematicBody2D

onready var arrow_scene = preload("res://GameObjects/Arrow/Arrow.tscn")

onready var health = $Health
onready var graphics = $Flippable
onready var bullet_origin = $Flippable/BulletOrigin
onready var pathfinder = $Pathfinder
onready var heart_spawner = $HeartSpawner

onready var player = Global.get_player()

export (int) var attack_distance = 165

func _process(_delta: float):
	if Global.pacifist_mode:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > attack_distance:
		var destination = player.global_position + (global_position - player.global_position).normalized() * attack_distance
		pathfinder.destination = destination

	if pathfinder.direction:
		graphics.v_flip = pathfinder.direction.x >= 0


func attack():
	if randf() < .3:
		for t in [-1, 0, 1]:
			var arrow = arrow_scene.instance()
			var origin = bullet_origin.global_position
			arrow.global_position = origin
			arrow.direction = (player.blood_origin.global_position - origin).normalized()
			arrow.direction = arrow.direction.rotated(deg2rad(t * 15))
			arrow.rotation = arrow.direction.angle()
			arrow.rotation_degrees += 180
			get_parent().call_deferred("add_child", arrow)
	else:
		var shots = 1
		var error_deg = 13
		if randf() < .25:
			shots = 4
			error_deg = 6
		
		for _i in range(shots):
			var arrow = arrow_scene.instance()
			var origin = bullet_origin.global_position
			arrow.global_position = origin
			arrow.direction = (player.blood_origin.global_position - origin).normalized()
			var t = (-1 if randf() > .5 else 1)
			var accuracy = randf()
			arrow.direction = arrow.direction.rotated(deg2rad(t * error_deg * accuracy))
			arrow.rotation = arrow.direction.angle()
			arrow.rotation_degrees += 180
			get_parent().call_deferred("add_child", arrow)
			yield(get_tree().create_timer(.3), "timeout")


func _on_got_damage(damage, _from, type):
	health.take_damage(damage)
	if type == "bullet":
		$HitSFX.play()


func _on_died():
	heart_spawner.spawn()
	queue_free()


func _on_AttackTimer_timeout():
	if Global.pacifist_mode:
		return
	
	attack()
