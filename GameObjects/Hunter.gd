extends EnemyBase

class_name Hunter

onready var grid = Global.get_grid()
onready var bullet_origin = $Graphics/Rifle/BulletOrigin
onready var blood_origin = $BloodOrigin
onready var shoot_rayrect = $Graphics/Rifle/ShootRayRect
onready var gun = $Graphics/Rifle

var bullet_scene = preload("res://GameObjects/EnemyBullet.tscn")
var blood_scene  = preload("res://HitBlood.tscn")

const ATTACK_DISTANCE = 210

var player_inside_visibility_area = false

var changing_position = false


func sees_player():
	return player_inside_visibility_area and not raycast.is_colliding()


func _init():
	self.health = 2
	damage = 0.35
	movement_speed = 50


func _ready():
	._ready()
	randomize()


func _rotate_gun():
	gun.rotation = blood_origin.global_position.angle_to_point(player.blood_origin.global_position)
	if facing_right:
		gun.rotation_degrees = 180 - gun.rotation_degrees


func recoil():
	# Запускаем 3 пули
	for i in [-1, 0, 1]:
		if i == -1 or i == 1:
			continue
		
		var bullet = bullet_scene.instance()
		bullet.initiator = self
		bullet.speed = 145
		bullet.global_position = bullet_origin.global_position
		bullet.direction = (player.blood_origin.global_position - bullet_origin.global_position).normalized()
		bullet.direction = bullet.direction.rotated(deg2rad(i * 15))
		bullet.rotation = bullet.direction.angle()
		bullet.rotation_degrees += 180
		get_parent().call_deferred("add_child", bullet)
	
	gun.rotation_degrees += 30


func _process(delta):
	._process(delta)
	
	.before_process(delta)

	if not self.is_dead:
	
		if player_inside_visibility_area:
			look_at_point(player.global_position)
			
			# Поворачиваем gun в сторону игрока
			if $AnimationPlayer.current_animation != "SHOOT":
				_rotate_gun()
			
			var angle_to_player = shoot_rayrect.global_position.angle_to_point(player.blood_origin.global_position)
			var distance_to_player = shoot_rayrect.global_position.distance_to(player.blood_origin.global_position)
		
			shoot_rayrect.rotation = angle_to_player - $Graphics/Rifle.rotation
		
			var collision_shape = shoot_rayrect.find_node("CollisionShape2D")
			var collision_width = (distance_to_player / 2) - 7
			collision_shape.shape.extents.x =  collision_width
			collision_shape.position.x      = -collision_width
			
			if facing_right:
				shoot_rayrect.rotation_degrees -= 180
				shoot_rayrect.rotation += $Graphics/Rifle.rotation * 2
			
			if distance_to_player <= ATTACK_DISTANCE:
				# Стреляем только если на пути к игроку нет преград
				if shoot_rayrect.get_overlapping_bodies().size() == 0:
					direction = Vector2.ZERO
					velocity  = Vector2.ZERO

					attack(player)
	
	# Не можем двигаться во время выстрела
	if $AnimationPlayer.is_playing():
		pass
		# direction = Vector2.ZERO
		# velocity  = Vector2.ZERO
	
	# Постепенно гасит скорость
	.after_process(delta)
	
	#$Vision.look_at(global_position - direction)
	$Graphics.scale.x = -1 if facing_right else 1


func take_damage(damage: float, initiator = null, knockback = 110, emit_blood = true):
	if initiator == null:
		initiator = self

	if Global.invincible_enemies:
		damage = 0
	
	.take_damage(damage)
	
	# Анимация получения урона
	#animation_player.play("GOT_DAMAGE")
	
	if emit_blood and initiator:
		var blood = blood_scene.instance() as CPUParticles2D
		blood.look_at((initiator.global_position - global_position).normalized())
		blood.rotation_degrees += 180
		blood.global_position = blood_origin.global_position
		blood.emitting = true
		blood.show_behind_parent = true
		get_parent().call_deferred("add_child", blood)
	
	#self.can_change_state = false
	# Отбрасываем врага
	var direction = (global_position - initiator.global_position).normalized()
	velocity = direction * knockback
	#yield(get_tree().create_timer(.5), "timeout")
	#self.can_change_state = true


func attack(_target: Node2D):
	if can_attack:
		# cancel_path()
		# direction = Vector2.ZERO
		# velocity  = Vector2.ZERO
		facing_right = player.global_position.x >= global_position.x

		can_attack = false
		$AnimationPlayer.play("SHOOT")
		yield($AnimationPlayer, "animation_finished")

		can_attack = true
		return

		changing_position = true

		var attempts = 0
		while true:
			attempts += 1
			if attempts > 25:
				# destination = null
				_on_reached_destination()
				break
			
			# Choosing random destination
			var direction = Vector2.RIGHT.rotated(deg2rad(rand_range(0, 360)))
			# var direction = Vector2.RIGHT
			var distance = rand_range(55, 95)
			var target_position = global_position + (direction * distance)

			var distance_to_player = target_position.distance_to(player.global_position)

			var node = grid.get_node_from_position(target_position.x, target_position.y)
			if (node and node.walkable) and (distance_to_player > 70):
				destination = target_position
				break


func _on_reached_destination():
	._on_reached_destination()
	if changing_position:
		changing_position = false
		can_attack = true
	pass


func modify_direction(direction: Vector2):
	return .modify_direction(direction)

	# var distance_to_player = global_position.distance_to(player.global_position)
	# if distance_to_player <= ATTACK_DISTANCE:
	# 	direction = direction.rotated(deg2rad(60))

	# return $Steer.modify_direction(direction)


func _on_died():
	._on_died()
	
	$AnimationPlayer.play("DIE")
	
	yield(get_tree().create_timer(.75), "timeout")
	remove_child($Hurtbox)
	remove_child($Collider)


func _on_Hurtbox_area_entered(area: Area2D):
	if area.is_in_group("GunRaycast"):
		#at_gunpoint = true
		return
	
	var body = area.get_parent()
	if body.is_in_group("PlayerBullet"):
		take_damage(.5, player)
		
		var bullet = body
		bullet.hit_number += 1
		
		var blood = blood_scene.instance()
		blood.look_at(bullet.direction.normalized())
		blood.global_position = $BloodOrigin.global_position
		blood.position += bullet.direction.normalized() * 16
		blood.show_behind_parent = true
		get_parent().call_deferred("add_child", blood)


func _on_Hurtbox_body_entered(body: Node2D):
	#print(body)
	pass


# Saw player
func _on_Vision_area_entered(area: Area2D):
	if area.is_in_group("PlayerHurtbox"):
		if Global.pacifist_mode:
			return
		
		player_inside_visibility_area = true
		
		return
		var local_group = local_group_area.get_bodies()
		var reinforcements = big_group_area.get_bodies()
		
		if local_group.size() > 1:
			print("Ебашим вместе со стрелком!")
			# Заставляем всю локальную группу атаковать гг
			for enemy in local_group:
				enemy.curr_tactic = Tactics.ATTACK
				enemy.find_path(player.global_position)


# Lost player
func _on_Vision_area_exited(area: Area2D):
	if area.is_in_group("PlayerHurtbox"):
		if Global.pacifist_mode:
			return
		
		player_inside_visibility_area = false
		_on_lost_player(area.get_parent().global_position)


func _on_lost_player(last_seen_position: Vector2):
	player_inside_visibility_area = false
	changing_position = false
	can_attack = true
	._on_lost_player(last_seen_position)
