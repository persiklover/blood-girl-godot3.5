extends Node2D

onready var animated_sprite = $AnimatedSprite
onready var hitbox = $Hitbox
onready var collision_shape = hitbox.find_node("CollisionShape2D")

export (int) var damage = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_Timer_timeout():
	animated_sprite.play()


func _on_animation_finished():
	animated_sprite.stop()
	animated_sprite.frame = 0

func _on_frame_changed():
	if animated_sprite.frame == 4:
		collision_shape.disabled = false
		yield(get_tree().create_timer(.1), "timeout")
		collision_shape.disabled = true


func _on_Hitbox_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(1, self, "default")
