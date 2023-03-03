extends EnemyBase

onready var blood_vfx = preload("res://Blood.tscn")
onready var hitblood_vfx = preload("res://HitBlood.tscn")
onready var dead_body_scene = preload("res://GameObjects/Grabbable/Rat/Rat.tscn")

onready var blood_origin = $BloodOrigin
onready var animation_player = $AnimationPlayer

func _ready():
	._ready()

	health = 1
	movement_speed  = 50
	attack_distance = 20


func _process(delta):
	.before_process(delta)

	if direction.length() > 0:
		$AnimatedSprite.flip_h = true if direction.x >= 0 else false

	.after_process(delta)

	if health <= 0 and velocity == Vector2.ZERO:
		print("!!!")
		
		var dead_body = dead_body_scene.instance()
		dead_body.global_position = global_position
		get_parent().call_deferred("add_child", dead_body)

		queue_free()

# var time_offset = rand_range(0, 10) * 1000
# var interval = rand_range(1.15, 1.75)
# func modify_direction(direction: Vector2):
# 	# Gives 1 or -1 every <interval> seconds
# 	var t = sign( fposmod((time_offset + OS.get_ticks_msec()) / 1000.0, interval) - (interval / 2) )
# 	var side_vec = (global_position - player.global_position).normalized()
# 	side_vec = side_vec.rotated(deg2rad(135 * t))
# 	return (direction + side_vec).normalized()


func take_damage(damage: float, from: Node2D = null, type: String = "", knockback: Vector2 = Vector2.ZERO):
	.take_damage(damage)

	# Анимация получения урона
	animation_player.play("GOT_DAMAGE")

	match type:
		"bullet":
			var bullet = from

			var blood = blood_vfx.instance()
			blood.look_at(bullet.direction)
			blood.global_position = blood_origin.global_position
			blood.position += bullet.direction * 3
			blood.show_behind_parent = true
			get_parent().call_deferred("add_child", blood)
		_:
			var blood = hitblood_vfx.instance() as CPUParticles2D
			blood.look_at((from.global_position - global_position).normalized())
			blood.rotation_degrees += 180
			blood.global_position = blood_origin.global_position
			blood.emitting = true
			blood.show_behind_parent = true
			get_parent().call_deferred("add_child", blood)
	
	if knockback != Vector2.ZERO:
		can_change_state = false
		velocity = knockback
		yield(get_tree().create_timer(.125), "timeout")
		can_change_state = true



func attack(target: Node2D):
	if player.is_invincible():
		return
	
	if $AttackTimeout.time_left > 0:
		return
	
	$AttackSFX.play()
	target.take_damage(damage, self)
	$AttackTimeout.start()


func _on_died():
	._on_died()


func _on_Hitbox_got_damage(damage: float, from: Node2D, type: String):
	var knockback = Vector2.ZERO
	match type:
		"hand":
			type = "default"
			knockback = (global_position - player.global_position).normalized() * 120
		"bullet":
			knockback = from.direction.normalized() * 75
	take_damage(damage, from, type, knockback)
