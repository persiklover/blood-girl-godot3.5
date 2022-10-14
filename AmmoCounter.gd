extends Node2D

onready var texture = $Bullet
var gap = 2

var ammo = 5

func update_graphics():
	var i = -1
	for child in get_children():
		i += 1
		child.modulate = Color.white
		if i >= ammo:
			child.modulate = Color(.5, .5, .5)
	pass


func _ready():
	var width =  texture.texture.get_size().x
	for i in ammo - 1:
		var t = texture.duplicate()
		t.position.x = (width + gap) + (width * i) + (gap * i)
		add_child(t)
	
	update_graphics()


func _on_Player_shoot(_ammo):
	ammo = _ammo
	update_graphics()
