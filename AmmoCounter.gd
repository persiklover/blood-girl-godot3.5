extends Node2D

tool

export(int) var ammo = 5

onready var bullet = $Bullet

var gap = 2

func update_graphics():
	var i = -1
	for child in get_children():
		i += 1
		child.modulate = Color.white
		if i >= ammo:
			child.modulate = Color(.5, .5, .5)
	pass


func _ready():
	var width = bullet.rect_size.x
	for i in ammo - 1:
		var t = bullet.duplicate()
		t.rect_position.x = width + gap + (width * i) + (gap * i)
		add_child(t)
	
	update_graphics()


func _process(delta):
	update_graphics()


func _on_Player_shoot(_ammo):
	ammo = _ammo
	update_graphics()
