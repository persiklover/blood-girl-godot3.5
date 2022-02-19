extends Position2D

export(NodePath) var destination

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_Area2D_area_entered(area):
	var destinationNode = get_node(destination)
	
	var player = area.get_parent()
	player.global_position = destinationNode.global_position
	
	var camera = player.get_node("Camera2D")
	if not camera:
		camera = owner.find_node("Camera2D")
	camera.global_position = player.global_position
