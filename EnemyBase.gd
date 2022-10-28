extends Entity

class_name EnemyBase

onready var raycast          : RayCast2D      = $RayCast
onready var soft_collision   : SoftCollision  = $SoftCollision
onready var local_group_area : LocalGroupArea = $LocalGroupArea
onready var big_group_area   : LocalGroupArea = $ReinforcementsArea

onready var player = Global.get_player()

var damage = .185
var attack_distance = 29

var can_attack = true
var chasing = false

# TACTIC
enum Tactics { ATTACK, PREPARE, RUN }
var curr_tactic = Tactics.ATTACK


func before_process(delta):
	.before_process(delta)
	
	if not self.is_dead:
		if Global.pacifist_mode:
			return

		if sees_player():
			find_path(player.global_position)

		if can_move():
			move_towards_destination()
			
			if direction.length() > 0:
				direction = modify_direction(direction)

			var distance = global_position.distance_to(player.global_position)
			if distance <= attack_distance:
				direction = Vector2.ZERO
				
				if can_attack:
					attack(player)
					cancel_path()
		else:
			direction = Vector2.ZERO
	
	if debugging:
		update()


func should_find_path():
	return OS.get_system_time_msecs() - last_found_path_time > 350


func can_move():
	var cannot_move = self.is_dead or stunned
	return not cannot_move


func sees_player():
	return true


func attack(target: Node2D):
	pass


func modify_direction(direction: Vector2):
	return direction
	# Предотвращает столкновения между похожими сущностями
	# if soft_collision.is_colliding():
	# 	direction += soft_collision.get_push_vector() * .2
	# 	direction = direction.normalized()

	# return direction


func look_at_point(look_point: Vector2):
	facing_right = look_point.x >= global_position.x
	
	var vision = find_node("Vision")
	if vision:
		vision.look_at(look_point)
		vision.rotation_degrees += 180


func _on_health_changed(health: float):
	._on_health_changed(health)
	
	var health_bar = $HealthBar/ColorRect
	if health_bar:
		var color = Color.green
		if health < .66:
			color = Color.orange
		elif health < .33:
			color = Color.red
			
		health_bar.rect_scale.x = health
		health_bar.color = color


func _on_died():
	._on_died()
	if soft_collision:
		remove_child(soft_collision)


func take_damage(damage: float):
	.take_damage(damage)
	if self.health > 0:
		show_health_bar()


func show_health_bar():
	$HealthBar.visible = true
	yield(get_tree().create_timer(1.25), "timeout")
	$HealthBar.visible = false


func _on_lost_player(last_seen_position: Vector2):
	find_path(last_seen_position)


func _draw():
	if debugging and destination != null:
		draw_circle(destination - global_position, 2, Color.red)
