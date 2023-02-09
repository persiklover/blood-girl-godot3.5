extends RichTextLabel

tool

export(String, MULTILINE) var content = "Buongiorno"
export(Color) var color = Color.black
export(bool) var centered = true


func _process(_delta):
	var text = "[color=#" + color.to_html() + "]" + str(content) + "[/color]"
	if centered:
		text = "[center]" + text + "[/center]"
	bbcode_text = text
