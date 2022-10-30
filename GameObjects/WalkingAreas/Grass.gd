extends Area2D

func _on_GrassArea_area_entered(area: Area2D): 
	print(area.get_parent().is_in_group('grass_toucher'));
	$SFX.play();
