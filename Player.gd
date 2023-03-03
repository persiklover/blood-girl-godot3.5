extends Alive

class_name Player

onready var sprite : AnimatedSprite = $AnimatedSprite
onready var spriteOffset = sprite.offset
onready var animation_player = $AnimationPlayer
onready var secondary_animation_player = $SecondaryAnimationPlayer
onready var graphics = $Graphics
onready var torso_pivot = $Graphics/TorsoPivot
onready var torso = $Graphics/TorsoPivot/Torso
onready var legs = $Graphics/Legs
onready var blood_origin = $BloodOrigin
onready var carry_point = $Graphics/TorsoPivot/LeftArm/CarryPivot

onready var gun = $Graphics/TorsoPivot/RotAxis
onready var gun_initial_offset = gun.position
onready var gun_animation_player = $Graphics/TorsoPivot/RotAxis/AnimationPlayer
onready var bullet_origin = $Graphics/TorsoPivot/RotAxis/Gun/BulletOrigin
onready var left_arm = $Graphics/TorsoPivot/LeftArm
onready var left_arm_initial_position = left_arm.position

var min_speed = 65 # 94
var max_speed = 85
var speed = 0

export(float) var health_drop = 0.0022

enum State { IDLE, RUN, EAT, PUNCH, KICK, DASH }
var currentState = State.IDLE
var prevState = currentState

var ejected_heart = false
var facing_right = false
var canSpawnDust = true

var dashing = false
var invincible = false

var stunned = false

var grabbed_body = null

var max_ammo = 7
var ammo = max_ammo
signal shoot()

var dir      : Vector2
var velocity : Vector2

var dustScene        = preload("res://Dust.tscn")
var bullet_scene     = preload("res://Bullet.tscn")
var gun_smoke_scene  = preload("res://GunSmoke.tscn")
var hit_blood_scene  = preload("res://HitBlood.tscn")

var has_key = false

func _ready():
	._ready()


func _handle_input():
	# if Input.is_action_just_released("ui_left"):
	# 	get_viewport().size.x -= 1
	# 	print(get_viewport().size.x)
	# elif Input.is_action_just_released("ui_right"):
	# 	get_viewport().size.x += 1
	# 	print(get_viewport().size.x)
	# if Input.is_action_just_released("ui_down"):
	# 	get_viewport().size.y -= 1
	# 	print(get_viewport().size.y)
	# elif Input.is_action_just_released("ui_up"):
	# 	get_viewport().size.y += 1
	# 	print(get_viewport().size.y)
	
	# return

	if Global.is_movement_disabled:
		dir = Vector2.ZERO
		velocity = Vector2.ZERO
		return

	# Block inputs if dashing or stunned
	# TODO: doesn't look good
	if dashing or stunned or not can_change_state:
		return
	
	# Controller
	dir = Vector2.ZERO
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	dir = dir.normalized()
	if dir.length() != 0:
		Global.is_using_controller = true
		velocity = dir
		if dir.x != 0:
			facing_right = dir.x >= 0
	# Keyboard
	else:
		if Input.is_action_pressed("ui_right"):
			Global.is_using_controller = false
			dir.x += 1
		if Input.is_action_pressed("ui_left"):
			Global.is_using_controller = false
			dir.x -= 1
		if Input.is_action_pressed("ui_up"):
			Global.is_using_controller = false
			dir.y -= 1
		if Input.is_action_pressed("ui_down"):
			Global.is_using_controller = false
			dir.y += 1
	
	dir = dir.normalized()
	
	# Melee attack
	if Input.is_action_just_pressed("melee_attack"):
		# Throw object if it's in the hand
		if grabbed_body:
			grabbed_body.active = true
			grabbed_body.direction = (get_cursor_position() - grabbed_body.global_position).normalized()
			grabbed_body = null

			# TODO: Add throw animation
			secondary_animation_player.play("RESET")

		# Can't hit if already holding the heart
		elif not ejected_heart:
			secondary_animation_player.play("PUNCH")
	
	# Shooting
	if Input.is_action_pressed("shoot"):
		if ammo == 0 and not is_reloading():
			$OutOfAmmoSFX.play()

		# Do nothing if can't shoot
		if not can_shoot():
			return

		# Do not reduce ammo if "invfinite_ammo" mode is on
		if not Global.invfinite_ammo:
			ammo -= 1
		
		if ammo < 0:
			ammo = 0
		
		emit_signal("shoot", ammo)

		# Reset gun rotation
		update_gun_rotation()

		# Creating bullet
		var bullet = bullet_scene.instance()
		bullet.global_position = bullet_origin.global_position
		bullet.direction = (get_cursor_position() - bullet_origin.global_position).normalized()
		bullet.rotation = bullet.direction.angle()
		bullet.rotation_degrees += 180
		get_parent().call_deferred("add_child", bullet)
		
		# Adding gun smoke
		var gun_smoke = gun_smoke_scene.instance()
		gun_smoke.emitting = true
		gun_smoke.rotation = bullet.direction.angle()
		gun_smoke.rotation_degrees += 180
		bullet_origin.call_deferred("add_child", gun_smoke)

		# "Animating" gun
		gun.rotation_degrees += 30
		gun_animation_player.play("SHOOT")
	
		# Global.get_camera().shake(.225, 1.75)
		Global.get_crosshair().play("SHOOT")
	
	# Checking health
	if Input.is_action_just_pressed("check_health"):
		# Can't eject heart when carrying smth
		if not secondary_animation_player.current_animation == "CARRY":
			if not ejected_heart:
				secondary_animation_player.play("CHECK_HEALTH")
			else:
				secondary_animation_player.play_backwards("CHECK_HEALTH")

	# Dash
	if Input.is_action_just_pressed("dash"):
		# Не дэшимся, если стоим на месте
		if dir.length() != 0 and $DashInterval.is_stopped():
			dash(dir)

	# Reloading
	if Input.is_action_just_pressed("reload"):
		# Не можем перезаряжаться, если уже перезаряжаемся или полный магазин
		if $Loader.is_playing() or ammo == max_ammo:
			return
		
		gun_animation_player.play("RELOAD")
		$Loader.start(gun_animation_player.get_animation("RELOAD").length)
		$Loader.visible = true
		yield($Loader, "loaded")
		$Loader.visible = false

		ammo = max_ammo
		emit_signal("shoot", ammo)


func _process(delta):
	._process(delta)
	_handle_input()

	# TODO: delete
	$Health.content = str(self.health)

	# Нельзя поворачиваться, если заблокировано движение
	if not Global.is_movement_disabled and not dashing:
		var mouse_position = get_global_mouse_position()
		facing_right = mouse_position.x >= global_position.x
		look_in_facing_direction(facing_right)
	
	if not dashing and dir.length() > 0:
		speed += 2
		if speed > max_speed:
			speed = max_speed
		
		velocity = dir * speed
	else:
		speed -= 4
		if speed < min_speed:
			speed = min_speed
	
	if stunned:
		dir = Vector2.ZERO
		velocity = Vector2.ZERO
	
	velocity = move_and_slide(velocity)
	# Постепенно гасит скорость
	if not dashing:
		velocity = velocity.move_toward(Vector2.ZERO, delta * 410)
	
	if grabbed_body:
		var body = grabbed_body as Node2D
		var offset = body.grab_point.position
		offset.x *= -1 if facing_right else 1
		
		body.global_position = carry_point.global_position - offset
		body.scale.x = -1 if facing_right else 1
		# body.z_index = 1
		# body.show_behind_parent = true
		show_on_top = true

		# Graphics
		left_arm.rotation_degrees = 0
		# left_arm.z_index = 2
		show_on_top = true
	
	# Чем меньше HP, тем бледнее сердце
	var heart = $Graphics/TorsoPivot/Heart
	var health_percent = self.health / max_health
	if heart:
		heart.modulate = Color(
			min(health_percent + 0.3, 1),
			health_percent,
			min(health_percent + 0.4, 1)
		)
		heart.speed_scale = 1 / (health_percent + 0.3)
	
	# -------------
	# State manager
	# -------------
	prevState = currentState
	if can_change_state:
		if dashing:
			currentState = State.DASH
		elif velocity.length() > 0 && not stunned:
			currentState = State.RUN
		else:
			currentState = State.IDLE
	
	#print(State.keys()[prevState], " ", State.keys()[currentState])
	
	match currentState:
		State.IDLE:
			pass
		State.RUN:
			if canSpawnDust:
				spawn_dust()
				canSpawnDust = false
				yield(get_tree().create_timer(.35), "timeout")
				canSpawnDust = true
	
	# print(State.keys()[prevState], " ", State.keys()[currentState])
	
	var preffered_animation = State.keys()[currentState]
	match preffered_animation:
		"IDLE":
			preffered_animation = "RESET"
		"RUN":
			preffered_animation = "RUN"
	
	if preffered_animation != animation_player.current_animation:
		animation_player.play(preffered_animation)
	
	# Tilting body when running

	# if velocity.x != 0:
	# 	var angle = 10
	# 	if not facing_right:
	# 		angle *= -1
	# 	# torso_pivot.rotation_degrees = -angle if velocity.x > 0 else angle
	# 	torso_pivot.rotation_degrees = lerp(
	# 		torso_pivot.rotation_degrees,
	# 		-angle if velocity.x > 0 else angle,
	# 		.2
	# 	)
	# else:
	# 	torso_pivot.rotation_degrees = 0


	# Нельзя поворачиваться, если заблокировано движение
	if not Global.is_movement_disabled and not dashing:
		var mouse_position = get_global_mouse_position()
		facing_right = mouse_position.x >= global_position.x
		look_in_facing_direction(facing_right)
	
	
	# Нельзя поворачиваться, если заблокировано движение
	if not Global.is_movement_disabled and not dashing:
		var mouse_position = get_global_mouse_position()
		facing_right = mouse_position.x >= global_position.x
		look_in_facing_direction(facing_right)
	
	# Left arm rotation when punching
	if secondary_animation_player.current_animation == "PUNCH" and left_arm.frame == 5:
		left_arm.look_at(get_cursor_position())
		left_arm.rotation_degrees += 180
	
	# Can't aim when recoil
	if not gun_animation_player.current_animation == "SHOOT":
		update_gun_rotation()
		
		var angle = -1 * rad2deg( blood_origin.get_angle_to(get_cursor_position()) )
		if abs(angle) > 90:
			angle = sign(angle) * (90 - (abs(angle) - 90))
		
		var gun_offsets = [
			Vector2(-4, gun_initial_offset.y), # MIDDLE
			Vector2(-2, gun_initial_offset.y), # MIDDLE-UP
			Vector2( 0, gun_initial_offset.y), # UP
			Vector2(-5, gun_initial_offset.y)  # MIDDLE-DOWN
		]

		if not secondary_animation_player.is_playing() or secondary_animation_player.current_animation == "CARRY":
			if angle > 0:
				if angle >= 60:
					torso.play("UP")
					gun.position = gun_offsets[2]
					left_arm.position = left_arm_initial_position + Vector2(1, 2)
				elif angle >= 25:
					torso.play("MIDDLE-UP")
					gun.position = gun_offsets[1]
					left_arm.position = left_arm_initial_position + Vector2.RIGHT
				else:
					torso.play("MIDDLE")
					gun.position = gun_offsets[0]
					left_arm.position = left_arm_initial_position
			else:
				if angle <= -25:
					torso.play("MIDDLE-DOWN")
					gun.position = gun_offsets[3]
					left_arm.position = left_arm_initial_position
				else:
					torso.play("MIDDLE")
					gun.position = gun_offsets[0]
					left_arm.position = left_arm_initial_position


func look_in_facing_direction(facing_right: bool):
	# Поворот кусковой части графики
	graphics.scale.x = -1 if facing_right else 1
	
	# Поворот цельной графики (AnimatedSprite)
	$AnimatedSprite.flip_h = facing_right

# Makes gun look at a cursor position
func update_gun_rotation():
	if Global.is_movement_disabled:
		return
	
	gun.look_at(get_cursor_position())
	gun.rotation_degrees += 180


func spawn_dust():
	var dust = dustScene.instance()
	dust.global_position = self.global_position
	dust.show_behind_parent = true
	dust.scale.x = 1 if dir.x < 0 else -1
	get_parent().call_deferred("add_child", dust)

func play_animation_once(anim: String):
	currentState = State[anim]
	can_change_state = false
	sprite.play(anim)
	yield(sprite, "animation_finished")
	can_change_state = true

func take_damage(damage: float, from: Node2D = null, _type: String = "", knockback: Vector2 = Vector2.ZERO):
	# Получаем в 3 раза больше урона, если достали сердце
	if ejected_heart:
		damage *= 3
	
	print(Global.invincible)
	if Global.invincible or invincible:
		return
	
	.take_damage(damage)
	
	# TODO: should come from damage dealer
	$HitSFX.play()
	
	Global.get_camera().shake(0.1, 0.75)
	
	# Cancels all active actions
	secondary_animation_player.play("RESET")
	# Flashing to indicate getting damage
	$BGAnimationPlayer.play("GOT_DAMAGE")
	
	var blood = hit_blood_scene.instance()
	blood.look_at((from.global_position - global_position).normalized())
	blood.rotation_degrees += 180
	blood.global_position = blood_origin.global_position
	blood.emitting = true
	blood.show_behind_parent = true
	get_parent().call_deferred("add_child", blood)
	
	# Experimental
	knockback = (global_position - from.global_position).normalized() * 125

	# Knockback
	if knockback != Vector2.ZERO:
		can_change_state = false
		dir = Vector2.ZERO
		velocity = knockback
		yield(get_tree().create_timer(.175), "timeout")
		can_change_state = true


func stun(time: float = 1):
	stunned = true
	yield(get_tree().create_timer(time), "timeout")
	stunned = false


func is_reloading():
	return $Loader.is_playing()


func can_shoot():
	# Can't shoot if there's no ammo
	if not Global.invfinite_ammo and ammo == 0:
		return false
	
	# Can't shoot while reloading or during shooting cooldown
	if (is_reloading() or gun_animation_player.is_playing()):
		return false

	return true


func recoil():
	gun.rotation_degrees += 30
	gun_animation_player.play("SHOOT")


func respawn():
	Global.transition_to_scene(load("res://Levels/Hub/Hub.tscn"))
	self.health = max_health


func _on_died():
	._on_died()
	print("DED!")
	respawn()

func get_cursor_position() -> Vector2:
	return Global.get_crosshair().global_position


signal finished_eating()
var eating = false
var eating_offsets = [
	Vector2(4, -4),
	Vector2(4, -19)
]

var object_to_interact : Node2D = null

func eat(object : Node2D):
	if eating:
		return
	
	object_to_interact = object
	
	eating = true
	Global.is_movement_disabled = true
	facing_right = object.global_position.x > global_position.x;

	object.global_position = Vector2(global_position.x, global_position.y + 1)
	
	play_animation_once("EAT")


func dash(direction: Vector2):
	$DashInterval.start(.75)
	
	dashing = true
	
	if direction.x != 0:
		var facing_right = direction.x >= 0
		look_in_facing_direction(facing_right)
	
	velocity = direction * max_speed * 1.5
	animation_player.play("DASH")
	if grabbed_body:
		grabbed_body.visible = false
	yield(animation_player, "animation_finished")
	dashing = false


func stop_dashing():
	velocity = velocity.normalized() * max_speed
	if grabbed_body:
		grabbed_body.visible = true


# Invincibility
func is_invincible():
	return Global.invincible or invincible

func turn_invincibility_on():
	invincible = true


func turn_invincibility_off():
	if Global.invincible:
		return
	
	invincible = false


func _on_AnimatedSprite_frame_changed():
	var frame = sprite.frame
	match currentState:
		State.PUNCH:
			# Импакт от удара
			if frame == 5:
				var direction = (get_global_mouse_position() - global_position).normalized()
				global_position += direction * 16.5
		State.EAT:
			if frame < len(eating_offsets):
				object_to_interact.sprite.offset.x = eating_offsets[frame].x * (1 if facing_right else -1)
				object_to_interact.sprite.offset.y = eating_offsets[frame].y;

func _on_AnimatedSprite_animation_finished():
	match currentState:
		State.EAT:
			eating = false
			Global.is_movement_disabled = false
			emit_signal("finished_eating")
		State.PUNCH:
			Global.is_movement_disabled = false
			$AnimatedSprite.visible = false
			$Graphics.visible = true

func on_punch():
	var direction = (get_global_mouse_position() - global_position).normalized()
	global_position += direction * 2.5
	
	var hitbox = $Graphics/TorsoPivot/RotAxis/Hitbox/CollisionShape2D
	hitbox.disabled = false
	yield(get_tree().create_timer(.1), "timeout")
	hitbox.disabled = true


func _on_AnimationPlayer_animation_finished(anim_name: String):
	pass


func _on_SecondaryAnimationPlayer_animation_finished(anim_name: String):
	match anim_name:
		"CHECK_HEALTH":
			ejected_heart = !ejected_heart
		"PUNCH":
			secondary_animation_player.play("RESET")
			pass


func _on_Timer_timeout():
	if Global.invincible:
		return
	
	# health -= health_drop


# Кто-то пiпався в хитбокс левой руки
# func _on_Hitbox_body_entered(body):
# 	print("body: ", body)
# 	if body == self:
# 		return

# 	var push_force = 120
# 	if body.is_in_group("Enemy"):
# 		# carry(body)
# 		body.take_damage(.4, self, push_force)
# 		$HitSFX.play()
# 		if body.health > 0:
# 			yield(get_tree().create_timer(.4), "timeout")
# 			if body.has_method("stun"):
# 				body.stun(1.15)
			
# 	elif body.is_in_group("Barrel"):
# 		body.velocity = (body.global_position - global_position).normalized() * push_force


func carry(body: Node2D):
	$GrabSFX.play()
	secondary_animation_player.play("CARRY")
	grabbed_body = body

	body.carried = true


func _on_Hurtbox_body_entered(body: Node2D):
	if Global.invincible or invincible:
		return
	
	if body.is_in_group("EnemyBullet"):
		var bullet = body
		var initiator = bullet.initiator
		if "damage" in initiator:
			take_damage(bullet.damage, initiator)
		bullet.queue_free()

# Sounds logic
onready var default_step_sound = $StepSFX.stream;
func _on_Trigger_area_entered(area: Area2D):
	if area.is_in_group("Surface"):
		$StepSFX.stream = area.find_node("SFX").stream

func _on_Trigger_area_exited(area: Area2D):
	if area.is_in_group("Surface"):
		for area in $Trigger.get_overlapping_areas():
			if area.is_in_group("Surface"):
				return
		
		$StepSFX.stream = default_step_sound
