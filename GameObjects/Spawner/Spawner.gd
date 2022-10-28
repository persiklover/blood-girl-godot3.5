extends Node

export(NodePath) var source
onready var enemy: EnemyBase = get_node(source)

func _ready():
	enemy.connect("died", self, "_on_died")


func _on_died():
	yield(get_tree().create_timer(1), "timeout")
	var duplicate: EnemyBase = enemy.duplicate()
	var MIN = -10
	var MAX =  10
	duplicate.global_position += Vector2(rand_range(MIN, MAX), rand_range(MIN, MAX))
	Global.get_ysort().add_child(duplicate)

