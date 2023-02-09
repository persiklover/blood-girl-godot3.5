extends EnemyBase

tool

var heart_scene  = preload("res://Heart.tscn")
var blood_vfx    = preload("res://Blood.tscn")
var hitblood_vfx = preload("res://HitBlood.tscn")

onready var sprite : AnimatedSprite = $Graphics/AnimatedSprite
onready var animation_player = $AnimationPlayer
onready var react_area = $ReactArea/CollisionShape2D
onready var blood_origin = $BloodOrigin
onready var head_blood_origin = $HeadBloodOrigin

var carried = false

var invincible = false

enum State { IDLE, RUN, HIT, DEAD }

var player_inside_visibility_area = false
var player_last_seen_position = null
var _at_gunpoint = false
var at_gunpoint  = false

const SPEED = 67.5 # 82

func _ready():
	._ready()

	attack_distance = 38
	movement_speed  = SPEED

	max_health = 4
	health = max_health


func sees_player():
	return true
	return player_inside_visibility_area # and not see_player_raycast.is_colliding()


func should_find_path():
	return (
		(OS.get_system_time_msecs() - last_found_path_time > 300)
		and not should_zigzag()
	)


func can_move():
	return .can_move() and curr_state != State.HIT


func should_zigzag():
	# Maximum confidence when player is realoading
	if player.is_reloading():
		return false
	
	return at_gunpoint and sees_player() and not (
		Global.pacifist_mode or
		curr_state == State.HIT or
		stunned
	)


func _process(delta):
	._process(delta)
	
	if Engine.editor_hint:
		$Graphics.scale.x = -1 if facing_right else 1
		
		var look_point = global_position + (Vector2.LEFT if facing_right else Vector2.RIGHT)
		$Vision.look_at(look_point)
		
		$Direction.look_at(look_point)
		
		return
	
	$Vision.look_at(global_position - direction)

	.before_process(delta)
	
	# Can't move if carried
	if not self.is_dead:
		if carried:
			direction = Vector2.ZERO
			$Collider.disabled = true
			$Hurtbox.monitoring = false
			$HeadHurtbox.monitoring = false
		else:
			$Hurtbox.monitoring = true
			$HeadHurtbox.monitoring = true
	
	# Двигает юнит и гасит скорость
	.after_process(delta)
	
	$Graphics.scale.x = -1 if facing_right else 1
	
	if curr_state == State.DEAD:
		can_change_state = false
	
	if can_change_state:
		if velocity.length() == 0:
			curr_state = State.IDLE
		else:
			curr_state = State.RUN
			movement_speed = SPEED
	
		sprite.play(State.keys()[curr_state])


func emit_default_blood(shoot_direction: Vector2):
	var blood = hitblood_vfx.instance() as CPUParticles2D
	blood.look_at(shoot_direction)
	blood.rotation_degrees += 180
	blood.global_position = blood_origin.global_position
	blood.emitting = true
	blood.show_behind_parent = true
	get_parent().call_deferred("add_child", blood)


func take_damage(damage: float, from: Node2D = null, type: String = "", knockback: Vector2 = Vector2.ZERO):
	if Global.invincible_enemies:
		damage = 0
	
	# TODO: questionable
	$HitSFX.play()
	.take_damage(damage)
	
	# Анимация получения урона
	animation_player.play("GOT_DAMAGE")
	
	match type:
		"headshot":
			var bullet = from
			bullet.hit_number += 1
			
			if self.health > 0:
				emit_default_blood(bullet.direction * -1)
			else:
				play_animation_once("DEAD_HEADSHOT")

				var blood2 = preload("res://BloodFountain.tscn").instance()
				blood2.global_position = head_blood_origin.global_position
				blood2.show_behind_parent = true
				get_parent().call_deferred("add_child", blood2)
		"bullet":
			var bullet = from
			bullet.hit_number += 1
			
			var blood = blood_vfx.instance()
			blood.look_at(bullet.direction.normalized())
			blood.global_position = blood_origin.global_position
			blood.position += bullet.direction.normalized() * 16
			blood.show_behind_parent = true
			get_parent().call_deferred("add_child", blood)
		_:
			emit_default_blood((from.global_position - global_position).normalized())
	
	if knockback != Vector2.ZERO:
		can_change_state = false
		velocity = knockback
		yield(get_tree().create_timer(.125), "timeout")
		can_change_state = true


func attack(target: Node2D):
	if carried:
		return
	
	.attack(target)

	can_attack = false
	can_change_state = false
	curr_state = State.HIT
	sprite.play(State.keys()[curr_state])

	movement_speed = 45


func play_animation_once(anim: String):
	can_change_state = false
	sprite.play(anim)
	yield(sprite, "animation_finished")
	if sprite.frame == 0:
		sprite.frame = sprite.frames.get_frame_count(anim)
	sprite.stop()
	can_change_state = true


func _on_Hurtbox_got_damage(damage: float, from: Node2D, type: String):
	var knockback = Vector2.ZERO
	match type:
		"hand":
			type = "default"
			knockback = (global_position - player.global_position).normalized() * 120
		"bullet":
			knockback = from.direction.normalized() * 75
	take_damage(damage, from, type, knockback)


func _on_HeadHurtbox_got_damage(damage: float, from: Node2D, type: String):
	var knockback = Vector2.ZERO
	match type:
		"hand":
			return # Do nothing, will be handled by body
		"bullet":
			type = "headshot"
			knockback = from.direction.normalized() * 75
	take_damage(damage, from, type, knockback)


func _on_Hurtbox_area_entered(area: Area2D):
	if area.is_in_group("GunRaycast"):
		# Can see the gun only if didn't see it before
		if not _at_gunpoint:
			yield(get_tree().create_timer(rand_range(.125, 1.75)), "timeout")
			if randf() > .5:
				print("yes")
				_at_gunpoint = true
				at_gunpoint  = true
			else:
				print("noe")


func _on_Hurtbox_area_exited(area):
	if area.is_in_group("GunRaycast"):
		_at_gunpoint = false
		yield(get_tree().create_timer(1), "timeout")
		if not _at_gunpoint:
			at_gunpoint = false
			cooldown_zigzag()


func _on_died():
	._on_died()

	can_change_state = false
	curr_state = State.DEAD
	play_animation_once("DEAD_BODYSHOT")

	$Vision.monitoring = false
	remove_child($Hurtbox)
	remove_child($HeadHurtbox)
	remove_child(local_group_area)
	remove_child(big_group_area)
	remove_child($Collider)


func get_meeting_point(bodies: Array) -> Vector2:
	var position = Vector2.ZERO
	var count = 0
	for body in bodies:
		position += body.global_position
		count += 1
	return position / count

# Saw player
func _on_Vision_area_entered(area: Area2D):
	if area.get_parent().is_in_group("Bullet"):
		var avoided = randf() < 0 # .4
		if avoided:
			invincible = true
			play_animation_once("AVOID")
			yield(get_tree().create_timer(.5), "timeout")
			invincible = false
			return

	if area.is_in_group("PlayerHitbox"):
		if Global.pacifist_mode:
			return
		
		player_inside_visibility_area = true
		
		if chasing:
			return
		chasing = true
		
		animation_player.play("SPRED_ALARM_AREA")
		
		var local_group = local_group_area.get_bodies()
		var reinforcements = big_group_area.get_bodies()
		
		return
		
		# никого нет рядом, но есть любое подкрепление
		if local_group.size() == 1 and reinforcements.size() > 1:
		
			# Если хотя бы один из подмоги файтится, то
			# тоже начинаем файтиться
			for body in reinforcements:
				if body == self:
					continue
				if body.chasing:
					print(body, " файтится, надо и мне")
					return
			
			curr_tactic = Tactics.RUN
			
			# Находим точку встречи
			var meet_point = get_meeting_point(reinforcements)
			
			# Бежим к ней
			#find_path(meet_point, 40)
			print(self, " Бегу к подмоге! ", meet_point)
			
			# Заставляем всю подмогу бежать к ней
			for enemy in reinforcements:
				enemy.find_path(meet_point, 40)
		
		elif local_group.size() > 1:
			# В поддержке есть стрелок, но его нет в локальной группе
			if not local_group_area.has("Hunter") and big_group_area.has("Hunter"):
				print("Бегу к стрелку!")
				# Находим точку встречи
				var frienly_unit = big_group_area.get_group_member("Hunter")
				var meet_point = frienly_unit.global_position
				# Заставляем всю локальную группу бежать к стрелку
				for enemy in local_group:
					enemy.curr_tactic = Tactics.RUN
					find_path(meet_point, 55)
			else:
				print("Ебашим вместе!")
				# Заставляем всю локальную группу атаковать гг
				for enemy in local_group:
					enemy.curr_tactic = Tactics.ATTACK
					enemy.find_path(player.global_position)


# Lost player
func _on_Vision_area_exited(area: Area2D):
	if area.is_in_group("PlayerHitbox"):
		if Global.pacifist_mode:
			return
		
		_on_lost_player(area.get_parent().global_position)


func _on_lost_player(last_seen_position: Vector2):
	player_inside_visibility_area = false
	player_last_seen_position = last_seen_position
	look_at_point(player_last_seen_position)
	._on_lost_player(last_seen_position)


func _on_reached_destination():
	._on_reached_destination()
	# print("reached dest")
	if not player_inside_visibility_area:
		chasing = false
		print("Not chasing!")


func _on_AnimatedSprite_frame_changed():
	if sprite == null:
		return
	
	var frame = sprite.frame
	match curr_state:
		State.HIT:
			match frame:
				9:
					var distance = global_position.distance_to(player.global_position)
					# small dash towards the player
					global_position += (
						(player.global_position - global_position).normalized() *
						min(14, distance - 12)
					)

				10:
					var distance = global_position.distance_to(player.global_position)
					if distance <= 35:
						var knockback = (player.blood_origin.global_position - blood_origin.global_position).normalized() * 180
						player.take_damage(damage, self, "", knockback)


func _on_AnimatedSprite_animation_finished():
	match curr_state:
		State.HIT:
			can_change_state = true
			if player_last_seen_position:
				look_at_point(player_last_seen_position)
			
			# Cooldown
			yield(get_tree().create_timer(.65), "timeout")
			can_attack = true


# Аларм захватил врага
func _on_ReactArea_body_entered(body: Node2D):
	if body == self:
		return
	
#	if body.is_in_group("Enemy"):
#		body.player_inside_visibility_area = true
#		pass


func cooldown_zigzag():
	if $ZigzagTimoutTimer.is_stopped():
		$ZigzagTimoutTimer.start(rand_range(3, 5))
		zigzag_allowed = false


func _on_ZigzagAllowedTimer_timeout():
	cooldown_zigzag()


func _on_ZigzagTimoutTimer_timeout():
	zigzag_allowed = true


func look_at_point(look_point: Vector2):
	facing_right = look_point.x >= global_position.x
	# $Graphics.scale.x = -1 if facing_right else 1
		
	$Vision.look_at(look_point)
	$Vision.rotation_degrees += 180
	#$Direction.look_at(look_point)
	#$Direction.rotation_degrees += 180


var zigzag_interval = 1.15
var zigzag_offset = rand_range(0, 7)
var zigzag_allowed = true

func modify_direction(direction: Vector2):
	# return .modify_direction(direction)

	# Nothing in the way to player and can zigzag
	if not raycast.is_colliding() and should_zigzag():
		var t = sign( fposmod(zigzag_offset + OS.get_ticks_msec() / (1000 * zigzag_interval), 2) - 1)
		var side_vec = (global_position - player.global_position).normalized()
		side_vec = side_vec.rotated(deg2rad(115 * t))
		direction = (direction + side_vec).normalized()
		
		# TODO: what?
		last_found_path_time = OS.get_system_time_msecs()

		return direction

	return direction
	# return $Steer.modify_direction(direction)


# Услышал шаги игрока
func _on_HearArea_area_entered(area: Area2D):
	if (
		not Global.pacifist_mode 
		and not self.is_dead 
		and not chasing
		and not player_inside_visibility_area
	):
		var look_point = area.get_parent().global_position
		$BgAnimationPlayer.play("QUESTION")
		yield(get_tree().create_timer(.6), "timeout")
		look_at_point(look_point)
