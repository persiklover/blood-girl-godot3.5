extends Area2D

export (int) var difficulty = 1
export (int) var waves = 3

onready var collision_shape = $CollisionShape

onready var y_sort: YSort = Global.get_ysort()
onready var _rat    = preload("res://GameObjects/Enemies/Rat/Rat.tscn")
onready var _hunter = preload("res://GameObjects/Hunter.tscn")

var total = 0
var dead  = 0
var wave  = 1

func _ready():
	spawn()
	pass


func spawn():
	var center = collision_shape.global_position
	var w = collision_shape.shape.extents.x
	var h = collision_shape.shape.extents.y

	total = 0
	dead  = 0

	var difficulty_points = difficulty * 8
	while difficulty_points > 0:
		if difficulty_points >= 3 and randf() > (1 - 1 / difficulty) + .25:
			difficulty_points -= 3
			total += 1
			print("h")

			var hunter = _hunter.instance()
			hunter.global_position.x = rand_range(center.x - w, center.x + w)
			hunter.global_position.y = rand_range(center.y - h, center.y + h)
			y_sort.call_deferred("add_child", hunter)
			hunter.connect("died", self, "_on_died")
		elif difficulty_points >= 1:
			difficulty_points -= 1
			total += 1
			print("r")

			var rat = _rat.instance()
			rat.global_position.x = rand_range(center.x - w, center.x + w)
			rat.global_position.y = rand_range(center.y - h, center.y + h)
			y_sort.call_deferred("add_child", rat)
			rat.connect("died", self, "_on_died")


func _on_died():
	dead += 1
	print("Enemy died. Total enemies died: ", dead)
	if dead >= total:
		print("Killed everyone!")
		if wave < waves:
			wave += 1
			spawn()
		else:
			print('Congratulations!')
