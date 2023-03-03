extends EnemyBase

class_name Hunter

onready var grid = Global.get_grid()
onready var bullet_origin = $Graphics/Rifle/BulletOrigin
onready var blood_origin = $BloodOrigin
onready var shoot_rayrect = $Graphics/Rifle/ShootRayRect
onready var gun = $Graphics/Rifle

var bullet_scene = preload("res://GameObjects/EnemyBullet.tscn")
var hitblood_vfx = preload("res://HitBlood.tscn")
var blood_vfx    = preload("res://Blood.tscn")

const ATTACK_DISTANCE = 155

var player_inside_visibility_area = false

var changing_position = false


func sees_player():
	return true
	return player_inside_visibility_area # and not raycast.is_colliding()


func _ready():
	._ready()

	damage = 0.35
	movement_speed = 50


func rotate_gun():
	gun.rotation = blood_origin.global_position.angle_to_point(player.blood_origin.global_position)
	if facing_right:
		gun.rotation_degrees = 180 - gun.rotation_degrees


func recoil():
	# Запускаем 3 пули
	for i in [-1, 0, 1]:
		# if i == -1 or i == 1:
		# 	continue
		
		var bullet = bullet_scene.instance()
		bullet.initiator = self
		bullet.lifespan = 7
		bullet.global_position = bullet_origin.global_position
		var direction = (player.blood_origin.global_position - bullet_origin.global_position)
		bullet.direction = direction.rotated(deg2rad(i * 15)).normalized()
		bullet.rotation = bullet.direction.angle()
		bullet.rotation_degrees += 180
		get_parent().call_deferred("add_child", bullet)
	
	$ShootSFX.play()
	gun.rotation_degrees += 30


func _process(delta):
	._process(delta)
	
	.before_process(delta)

	if not self.is_dead:
	
		if sees_player():
			look_at_point(player.global_position)
			
			# Поворачиваем gun в сторону игрока
			if $AnimationPlayer.current_animation != "SHOOT":
				rotate_gun()
			
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
		direction = Vector2.ZERO
		velocity  = Vector2.ZERO
	
	# Постепенно гасит скорость
	.after_process(delta)
	
	#$Vision.look_at(global_position - direction)
	$Graphics.scale.x = -1 if facing_right else 1


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
	# $HitSFX.play()
	.take_damage(damage)
	
	# Анимация получения урона
	# animation_player.play("GOT_DAMAGE")
	
	match type:
		# "headshot":
		# 	var bullet = from
		# 	bullet.hit_number += 1
			
		# 	if self.health > 0:
		# 		emit_default_blood(bullet.direction * -1)
		# 	else:
		# 		play_animation_once("DEAD_HEADSHOT")

		# 		var blood2 = preload("res://BloodFountain.tscn").instance()
		# 		blood2.global_position = head_blood_origin.global_position
		# 		blood2.show_behind_parent = true
		# 		get_parent().call_deferred("add_child", blood2)
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


func attack(_target: Node2D):
	if can_attack:
		# var line = $Graphics/Rifle/ColorRect
		# line.rect_size.x = bullet_origin.global_position.distance_to(player.blood_origin.global_position)

		facing_right = player.global_position.x >= global_position.x

		can_attack = false
		$AnimationPlayer.play("SHOOT")
		yield($AnimationPlayer, "animation_finished")

		$ReloadSFX.play()
		yield(get_tree().create_timer(1.5), "timeout")
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
	remove_child($Hitbox)
	remove_child($Collider)

# Saw player
func _on_Vision_area_entered(area: Area2D):
	if area.is_in_group("PlayerHitbox"):
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
	if area.is_in_group("PlayerHitbox"):
		if Global.pacifist_mode:
			return
		
		player_inside_visibility_area = false
		_on_lost_player(area.get_parent().global_position)


func _on_lost_player(last_seen_position: Vector2):
	player_inside_visibility_area = false
	changing_position = false
	can_attack = true
	._on_lost_player(last_seen_position)


func _on_Hitbox_got_damage(damage: float, from: Node2D, type: String):
	var knockback = Vector2.ZERO
	match type:
		"hand":
			type = "default"
			knockback = (global_position - player.global_position).normalized() * 120
		"bullet":
			knockback = from.direction.normalized() * 75
	take_damage(damage, from, type, knockback)
