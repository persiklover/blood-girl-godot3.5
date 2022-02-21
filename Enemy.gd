extends KinematicBody2D

export(float) var damage = .125
export(int) var speed = 73.5 # 57.5

const attack_distance = 26

var heart_scene = preload("res://Heart.tscn")
var blood_scene = preload("res://Blood.tscn")

var player : Player

onready var sprite : AnimatedSprite = $Graphics/AnimatedSprite
var facingRight = false
var canAttack = true
var can_change_state = true

var health_manager = preload("res://Health.gd").new()
var is_dead = false

enum State { IDLE, RUN, HIT, DEAD }
var current_state = State.IDLE
var prev_state = current_state
var velocity = Vector2.ZERO

var player_inside_visibility_area = false
var at_gunpoint = false
var saw_player_time = false

var breadcrumbs = []
var breadcrumbs_copy = []

var destination = null

var zigzag_time = 1.5
var rand_start_zigzag_time : int

func _ready():
	randomize()
	rand_start_zigzag_time = rand_range(0, 5)
	
	player = Global.get_player()
	
	health_manager.connect("died", self, "_on_died")

func sees_player():
	return player_inside_visibility_area and not $SeePlayerRayCast.is_colliding()

func _process(delta):
	is_dead = health_manager.health <= 0
	
	if not player:
		return
	
	var raycast = $SeePlayerRayCast
	raycast.cast_to = player.global_position - global_position
	$Text.text = str(sees_player())
	
	prev_state = current_state
	
	var dir = Vector2.ZERO
	if not is_dead and can_change_state:
		if sees_player() and not Global.pacifist_mode:
			var distance = global_position.distance_to(player.global_position)
			if distance <= attack_distance:
				if canAttack:
					current_state = State.HIT
					canAttack = false
					can_change_state = false
					sprite.play(State.keys()[current_state])
			else:
				dir = (player.global_position - global_position).normalized()
				facingRight = dir.x >= 0
				current_state = State.RUN
		
		if destination != null:
			dir = (destination - global_position).normalized()
			facingRight = dir.x >= 0
			if global_position.distance_to(destination) <= 1:
				destination = null
				if len(breadcrumbs) != 0:
					destination = breadcrumbs.pop_back()
				else:
					breadcrumbs_copy = []
		
		if at_gunpoint and sees_player():
			# Gives -1 or 1 after 1.5s
			var t = sign( fposmod(rand_start_zigzag_time + OS.get_ticks_msec() / (1000 * zigzag_time), 2) -1)
			var side_vec = (global_position - player.global_position).normalized()
			side_vec = side_vec.rotated(deg2rad(90 * t))
			dir = (dir + side_vec).normalized()
		
		velocity = dir * speed
	
	# Debug moving direction
	$RayCast2D.cast_to = dir * 7
	
	# Постепенно гасит скорость
	velocity = velocity.move_toward(Vector2.ZERO, delta * 130)
	velocity = move_and_slide(velocity)
	
	$Line2D.global_position = Vector2.ZERO
	$Line2D.points = breadcrumbs_copy
	
	$Graphics.scale.x = -1 if facingRight else 1
	
	if can_change_state:
		current_state = State.IDLE
		if velocity.length() != 0:
			current_state = State.RUN
	
	if current_state != prev_state:
		if prev_state == State.HIT:
			canAttack = true
	
	if not is_dead:
		sprite.play(State.keys()[current_state])

func _on_Hurtbox_area_entered(area: Area2D):
	if area.is_in_group("GunRaycast"):
		at_gunpoint = true
		return
	
	velocity = (global_position - area.global_position).normalized() * 75
	if area.get_parent().is_in_group("Bullet"):
		var bullet = area.get_parent()
		velocity = bullet.direction.normalized() * 85
		
		var blood = blood_scene.instance()
		blood.look_at(bullet.direction.normalized())
		blood.global_position = $BloodOrigin.global_position
		#blood.position += bullet.direction.normalized() * 20
		blood.show_behind_parent = true
		get_parent().call_deferred("add_child", blood)
	
	# Can't die twice
	if is_dead:
		return
	
	health_manager.health = 0
	sprite.play(State.keys()[State.DEAD])
	remove_child($Hurtbox)


func _on_Hurtbox_area_exited(area):
	if area.is_in_group("GunRaycast"):
		at_gunpoint = false


func _on_died():	
	return
	yield(get_tree().create_timer(.5), "timeout")
	var heart = heart_scene.instance()
	heart.global_position = global_position + Vector2(1, 1)
	Global.get_ysort().add_child(heart)

func _on_lost_player():
	player_inside_visibility_area = false
	
	# find closes breadcrumb & remove everything behind
	var closest_position = null
	var smallest_distance = INF
	var _i = -1
	
	for i in range(breadcrumbs.size() - 1, 0, -1):
		var pos = breadcrumbs[i]
		var distance = global_position.distance_to(pos)
		if distance < smallest_distance:
			smallest_distance = distance
			closest_position = pos
			_i = i

	breadcrumbs = breadcrumbs.slice(0, _i)
	breadcrumbs_copy = breadcrumbs.duplicate(true)
	
	destination = breadcrumbs.pop_back()


# Can see player
func _on_Vision_area_entered(area: Area2D):
	if area.is_in_group("Breadcrumb"):
		var breadcrumb = area
		if player_inside_visibility_area and breadcrumb.birth_time > saw_player_time:
			breadcrumbs.push_front(breadcrumb.position)
			breadcrumbs_copy = breadcrumbs.duplicate(true)
	else:
		var target = area.get_parent()
		if target.is_in_group("Player"):
			saw_player_time = OS.get_ticks_msec()
			player_inside_visibility_area = true
			breadcrumbs = []
			breadcrumbs_copy = []


# Lost player
func _on_Vision_area_exited(area: Area2D):
	if area.is_in_group("Breadcrumb"):
		pass
	else:
		var target = area.get_parent()
		if target.is_in_group("Player"):
			_on_lost_player()


func _on_AnimatedSprite_animation_finished():
	match current_state:
		State.HIT:
			var distance = global_position.distance_to(player.global_position)
			if distance <= attack_distance + 15:
				player.take_damage(damage, self)
			
			can_change_state = true
			
			# Cooldown
			yield(get_tree().create_timer(.65), "timeout")
			canAttack = true

