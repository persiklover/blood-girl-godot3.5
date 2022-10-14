extends EnemyBase

tool

const deal_damage_distance = 36
const jump_speed = 205

var heart_scene = preload("res://Heart.tscn")
var blood_scene = preload("res://Blood.tscn")
var hit_blood_scene = preload("res://HitBlood.tscn")

onready var sprite : AnimatedSprite = $Graphics/AnimatedSprite
onready var animation_player = $AnimationPlayer

enum State { IDLE, RUN, ATTACK, DEAD }
var current_state = State.IDLE

var player_inside_visibility_area = false
var at_gunpoint = false
var saw_player_time = false

func _init():
	damage = .125
	movement_speed = 118
	attack_distance = 47 


func can_move():
	return not self.is_dead and self.can_change_state


func _process(delta):
	if Engine.editor_hint:
		$Graphics.scale.x = -1 if facing_right else 1
		return
	
	if not player:
		return
		
	._process(delta)
	
	before_process(delta)
	
	after_process(delta)
	
	$Graphics.scale.x = -1 if facing_right else 1
	
	if self.can_change_state:
		current_state = State.IDLE
		if velocity.length() != 0:
			current_state = State.RUN
	
	if not is_dead:
		sprite.play(State.keys()[current_state])


func sees_player():
	return true


func attack(target: Node2D):
	can_attack = false
	self.can_change_state = false
	current_state = State.ATTACK
	sprite.play(State.keys()[current_state])
	
	velocity = Vector2.ZERO
	yield(get_tree().create_timer(.35), "timeout")
	
	$Collider.disabled = true
	
	facing_right = target.global_position.x >= global_position.x
	var jump_direction = (target.global_position - global_position).normalized()
	velocity = jump_direction * jump_speed

func _on_AnimatedSprite_frame_changed():
	var frame = $Graphics/AnimatedSprite.frame
	match current_state:
		State.ATTACK:
			if frame == 12:
				var distance = global_position.distance_to(player.global_position)
				if distance <= deal_damage_distance:
					player.take_damage(damage, self)
				
				$Collider.disabled = false


func _on_AnimatedSprite_animation_finished():
	match current_state:
		State.ATTACK:
			self.can_change_state = true
			
			# Cooldown
			yield(get_tree().create_timer(.7), "timeout")
			can_attack = true



func _on_Hurtbox_area_entered(area: Area2D):
	var parent = area.get_parent()
	if parent.is_in_group("Bullet"):
		var bullet: Bullet = parent
		bullet.hit_number += 1
		queue_free()
