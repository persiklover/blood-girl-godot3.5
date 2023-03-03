extends Area2D

export (bool) var disabled = false
export (int)  var difficulty = 1
export (int)  var waves = 3

onready var collision_shape = $CollisionShape

onready var _rat    = preload("res://GameObjects/Enemies/Rat/Rat.tscn")
onready var _hunter = preload("res://GameObjects/Hunter.tscn")
onready var _melee  = preload("res://Enemy.tscn")

var y_sort: YSort

var total = 0
var dead  = 0
var wave  = 1

func _ready():
	# y_sort = Global.get_ysort()
	y_sort = get_parent()
	spawn()


func spawn():
	if disabled:
		return
	
	var center = collision_shape.global_position
	var w = collision_shape.shape.extents.x
	var h = collision_shape.shape.extents.y

	total = 0
	dead  = 0

	var difficulty_points = difficulty * 14
	while difficulty_points > 0:
		if difficulty_points >= 5 and randf() > (1 - 1 / difficulty) + .25:
			continue
			difficulty_points -= 5
			total += 1
			print("h")

			var hunter = _hunter.instance()
			hunter.global_position.x = rand_range(center.x - w, center.x + w)
			hunter.global_position.y = rand_range(center.y - h, center.y + h)
			y_sort.call_deferred("add_child", hunter)
			hunter.connect("died", self, "_on_died")
		elif difficulty_points >= 3:
			# continue
			difficulty_points -= 3
			total += 1
			print("m")

			var melee = _melee.instance()
			melee.global_position.x = rand_range(center.x - w, center.x + w)
			melee.global_position.y = rand_range(center.y - h, center.y + h)
			y_sort.call_deferred("add_child", melee)
			melee.connect("died", self, "_on_died")
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
