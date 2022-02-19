extends KinematicBody2D

export(float) var damage = .125
export(int) var speed = 57.5

var heart_scene = preload("res://Heart.tscn")
var blood_scene = preload("res://Blood.tscn")

var player : Player

onready var sprite = $AnimatedSprite
var facingRight = false
var canAttack = true
var can_change_state = true

var health_manager = preload("res://Health.gd").new()
var is_dead = false

enum State { IDLE, RUN, HIT, DEAD }
var current_state = State.IDLE
var velocity = Vector2.ZERO

func _ready():
	player = Global.get_player()
	
	health_manager.connect("died", self, "_on_died")
	
func _process(delta):
	is_dead = health_manager.health <= 0
	
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	if not is_dead and not Global.pacifist_mode and distance <= 95:
		if distance <= 25:
			if canAttack:
				current_state = State.HIT
				canAttack = false
				can_change_state = false
				sprite.play(State.keys()[current_state])
				yield(sprite, "animation_finished")
				can_change_state = true
				player.take_damage(damage)
				# Cooldown
				yield(get_tree().create_timer(.65), "timeout")
				canAttack = true
		else:
			var dir = (player.position - self.position).normalized()
			facingRight = dir.x >= 0
			velocity = dir * speed
			current_state = State.RUN
	
	sprite.flip_h = facingRight
	
	velocity = velocity.move_toward(Vector2.ZERO, delta * 130)
	velocity = move_and_slide(velocity)
	
	if can_change_state:
		current_state = State.IDLE
		if velocity.length() != 0:
			current_state = State.RUN
	
	if not is_dead:
		sprite.play(State.keys()[current_state])

func _on_Hurtbox_area_entered(area: Area2D):
	velocity = (global_position - area.global_position).normalized() * 75
	if area.get_parent().is_in_group("Bullet"):
		var bullet = area.get_parent()
		velocity = bullet.direction.normalized() * 85
		
		var blood = blood_scene.instance()
		blood.look_at(bullet.direction.normalized())
		blood.global_position = $BloodOrigin.global_position
		blood.position += bullet.direction.normalized() * 10
		blood.show_behind_parent = true
		get_parent().call_deferred("add_child", blood)
	
	# Can't die twice
	if is_dead:
		return
	
	health_manager.health = 0
	sprite.play(State.keys()[State.DEAD])
	# remove_child($Collider)

func _on_died():	
	return
	yield(get_tree().create_timer(.5), "timeout")
	var heart = heart_scene.instance()
	heart.global_position = global_position + Vector2(1, 1)
	Global.get_ysort().add_child(heart)
