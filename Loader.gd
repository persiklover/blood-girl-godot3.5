extends Node2D

onready var animation_player = $AnimationPlayer

signal loaded()

func start(time):
  animation_player.playback_speed = 1 / time
  animation_player.play("LOAD")
  yield(animation_player, "animation_finished")
  # Time to play sound
  yield(get_tree().create_timer(.1), "timeout")
  emit_signal("loaded")


func is_playing():
  return animation_player.is_playing()
