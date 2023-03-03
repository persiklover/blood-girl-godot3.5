extends Particles2D


# Called when the node enters the scene tree for the first time.
func _ready():
	yield(get_tree().create_timer(lifetime), "timeout")
	queue_free()
