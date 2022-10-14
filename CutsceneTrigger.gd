extends Area2D

var cutscene_player : AnimationPlayer

func _ready():
	cutscene_player = Global.get_cutscene()

func _on_CutsceneTrigger_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		Global.is_movement_disabled = true
		cutscene_player.play("Cutscene1")
		yield(cutscene_player, "animation_finished")
		Global.is_movement_disabled = false
		cutscene_player.play("RESET")
		queue_free()
