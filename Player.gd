extends KinematicBody2D

class_name Player

onready var sprite : AnimatedSprite = $AnimatedSprite
onready var spriteOffset = sprite.offset
onready var animation_player = $AnimationPlayer
onready var graphics = $Graphics
onready var torso_pivot = $Graphics/TorsoPivot
onready var torso = $Graphics/TorsoPivot/Torso
onready var gun = $Graphics/TorsoPivot/Revolver
onready var gun_initial_offset = gun.position
onready var bullet_origin = $Graphics/TorsoPivot/Revolver/BulletOrigin
onready var left_arm = $Graphics/TorsoPivot/LeftArm

onready var legs = $Graphics/Legs

export(float) var movementSpeed = 1.4
export(float) var health_drop = 0.0015

enum State { IDLE, RUN, EAT, PUNCH }
var currentState = State.IDLE
var prevState = currentState

var ejected_heart = false
var facingRight = false
var canChangeCurrentState = true
var canSpawnDust = true

var velocity : Vector2

var health_manager = preload("res://Health.gd").new()

var dustScene = preload("res://Dust.tscn")

var bullet_scene = preload("res://Bullet.tscn")
var gun_smoke_scene = preload("res://GunSmoke.tscn")
var hit_blood_scene = preload("res://HitBlood.tscn")
var breadcrumb_scene = preload("res://Breadcrumb.tscn")

func _ready():
	health_manager.health = 1

func _handle_input():
	velocity = Vector2.ZERO
	
	if Global.is_movement_disabled:
		return
	
	# Controller
	var dir = Vector2.ZERO
	dir.x = Input.get_action_strength("controller_right") - Input.get_action_strength("controller_left")
	dir.y = Input.get_action_strength("controller_down")  - Input.get_action_strength("controller_up")
	if dir.length() != 0:
		Global.is_using_controller = true
		velocity = dir
		if dir.x != 0:
			facingRight = dir.x >= 0
	# Keyboard
	else:
		if Input.is_action_pressed("ui_right"):
			Global.is_using_controller = false
			velocity.x += 1
		if Input.is_action_pressed("ui_left"):
			Global.is_using_controller = false
			velocity.x -= 1
		if Input.is_action_pressed("ui_up"):
			Global.is_using_controller = false
			velocity.y -= 1
		if Input.is_action_pressed("ui_down"):
			Global.is_using_controller = false
			velocity.y += 1
	
	if Input.is_action_just_pressed("melee_attack"):
		$AnimatedSprite.visible = true
		play_animation_once(State.keys()[State.PUNCH])
		$Graphics.visible = false
	
	if Input.is_action_just_pressed("shoot"):
		if not animation_player.is_playing():
			var bullet = bullet_scene.instance()
			bullet.global_position = bullet_origin.global_position
			bullet.direction = (get_global_mouse_position() - bullet_origin.global_position).normalized()
			bullet.rotation = bullet.direction.angle()
			bullet.rotation_degrees += 180
			get_parent().call_deferred("add_child", bullet)
			
			# Adding gun smoke
			var gun_smoke = gun_smoke_scene.instance()
			gun_smoke.emitting = true
			#gun_smoke.global_position = bullet_origin.global_position
			gun_smoke.rotation = bullet.direction.angle()
			gun_smoke.rotation_degrees += 180
			bullet_origin.call_deferred("add_child", gun_smoke)
			
			# "Animating" gun
			gun.rotation_degrees += 30
		
		Global.get_camera().shake()
		Global.get_crosshair().play("SHOOT")
		animation_player.play("SHOOT")
		yield(animation_player, "animation_finished")
		_rotate_gun()
		Global.get_crosshair().play("IDLE")
	
	if Input.is_action_just_pressed("check_health"):
		ejected_heart = !ejected_heart
		if ejected_heart:
			animation_player.play("CHECK_HEALTH")
		else:
			animation_player.play_backwards("CHECK_HEALTH")

func _process(delta):
	_handle_input()
	move_and_slide(velocity.normalized() * movementSpeed * 50)
	
	# Чем меньше HP, тем бледнее сердце
	$Graphics/TorsoPivot/Heart.modulate = Color(
		min(health_manager.health + 0.3, 1),
		health_manager.health,
		min(health_manager.health + 0.4, 1)
	)
	$Graphics/TorsoPivot/Heart.speed_scale = 1 / (health_manager.health + 0.3)
	
	if health_manager.health <= 0:
		respawn()
	
	# State manager
	prevState = currentState
	
	if canChangeCurrentState:
		currentState = State.IDLE
		if (velocity.length() != 0):
			currentState = State.RUN
	
	# Switch
	match currentState:
		State.IDLE:
			pass
		State.RUN:
			if canSpawnDust:
				spawn_dust()
				canSpawnDust = false
				yield(get_tree().create_timer(.35), "timeout")
				canSpawnDust = true
	
	# Applying changes to sprite
	sprite.animation = State.keys()[currentState]
	
	legs.animation = State.keys()[currentState]
	
	var mouse_position = get_global_mouse_position()
	var facing_right = mouse_position.x >= global_position.x
	graphics.scale.x = -1 if facing_right else 1
	
	if not animation_player.is_playing():
		_rotate_gun()
		
		var cursor_angle = -1 * (-90 + int(gun.rotation_degrees) % 360)
		
		var gun_offsets = [
			Vector2(-4, gun_initial_offset.y),
			Vector2(-1, gun_initial_offset.y),
			Vector2(-1, gun_initial_offset.y + 1),
			Vector2(-6, gun_initial_offset.y + 1)
		]
		
		if cursor_angle > 0:
			if cursor_angle < 35:
				torso.play("UP")
				gun.position = gun_offsets[2]
			elif cursor_angle < 65:
				torso.play("MIDDLE-UP")
				gun.position = gun_offsets[1]
			else:
				torso.play("MIDDLE")
				gun.position = gun_offsets[0]
		else:
			if cursor_angle > -270 + 35:
				torso.play("MIDDLE-DOWN")
				gun.position = gun_offsets[3]
			else:
				torso.play("MIDDLE")
				gun.position = gun_offsets[0]

func _rotate_gun():
	var mouse_position = get_global_mouse_position()
	gun.look_at(mouse_position)
	gun.rotation_degrees += 180

func spawn_dust():
	var dust = dustScene.instance()
	dust.global_position = self.global_position
	dust.show_behind_parent = true
	get_parent().call_deferred("add_child", dust)

func play_animation_once(anim: String):
	currentState = State[anim]
	canChangeCurrentState = false
	sprite.play(anim)
	yield(sprite, "animation_finished")
	canChangeCurrentState = true

func take_damage(damage: float, initiator: Node2D):
	health_manager.health -= damage
	
	var blood = hit_blood_scene.instance() as CPUParticles2D
	blood.look_at((initiator.global_position - global_position).normalized())
	blood.rotation_degrees += 180
	blood.global_position = $BloodOrigin.global_position
	blood.emitting = true
	blood.show_behind_parent = true
	get_parent().call_deferred("add_child", blood)

func respawn():
	var respawn : Position2D = owner.find_node("Respawn")
	if respawn:
		global_position = respawn.global_position
		health_manager.health = 1

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
	facingRight = object.global_position.x > global_position.x;

	object.global_position = Vector2(global_position.x, global_position.y + 1)
	
	play_animation_once("EAT")

func _on_HSlider_value_changed(value):
	movementSpeed = value

func _on_AnimatedSprite_frame_changed():
	var frame = sprite.frame
	match currentState:
		State.IDLE:
			torso_pivot.position = Vector2.ZERO
		State.RUN:
			if frame == 0:
				torso_pivot.position = Vector2(0, 1)
			elif frame == 1:
				torso_pivot.position = Vector2(0, 1)
			elif frame == 2:
				torso_pivot.position = Vector2(0, 3)
			elif frame == 3:
				torso_pivot.position = Vector2(-1, 0)
			elif frame == 4:
				torso_pivot.position = Vector2(-1, 0)
			elif frame == 5:
				torso_pivot.position = Vector2(1, 2)
		State.PUNCH:
			# Импакт от удара
			if frame == 4:
				$Hitbox/CollisionShape2D.disabled = false
				yield(get_tree().create_timer(.1), "timeout")
				$Hitbox/CollisionShape2D.disabled = true
		State.EAT:
			if frame < len(eating_offsets):
				object_to_interact.sprite.offset.x = eating_offsets[frame].x * (1 if facingRight else -1)
				object_to_interact.sprite.offset.y = eating_offsets[frame].y;

func _on_AnimatedSprite_animation_finished():
	match currentState:
		State.EAT:
			eating = false
			Global.is_movement_disabled = false
			emit_signal("finished_eating")
		State.PUNCH:
			$AnimatedSprite.visible = false
			$Graphics.visible = true

func _on_Timer_timeout():
	health_manager.health -= health_drop
	
	var mouse_position = get_global_mouse_position() / 4;
	#print(global_position, " ", mouse_position)


func _on_BreadcrumbTimer_timeout():
	var breadcrumb = breadcrumb_scene.instance()
	breadcrumb.global_position = global_position
	breadcrumb.show_behind_parent = true
	get_parent().call_deferred("add_child", breadcrumb)
