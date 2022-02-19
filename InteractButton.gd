extends Node2D

func _process(delta):
	if Global.is_using_controller:
		$Controller.show()
		$Keyboard.hide()
	else:
		$Controller.hide()
		$Keyboard.show()
