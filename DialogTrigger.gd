extends Area2D

export (String, FILE, "*.json") var dialogFile : String

var interactButtonScene = preload("res://InteractButton.tscn")

var button
var is_active : bool
var json

func _ready():
	var file = File.new()
	assert(file.file_exists(dialogFile), dialogFile + " does not exist")

	file.open(dialogFile, file.READ)
	json = parse_json(file.get_as_text())
	assert(json.size() > 0)

func _process(delta):
	if Input.is_action_just_released("interact") and is_active and not Global.is_movement_disabled:
		button.hide()
		
		var dialog = owner.find_node("Dialog")
		dialog.start(json)

func _on_DialogTrigger_area_entered(area):
	is_active = true
	button = interactButtonScene.instance()
	button.global_position = self.global_position
	# button.show_behind_parent = true
	self.owner.call_deferred("add_child", button)

func _on_DialogTrigger_area_exited(area):
	is_active = false
	button.queue_free()
