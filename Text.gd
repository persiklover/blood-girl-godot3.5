extends RichTextLabel

tool

export(String, MULTILINE) var content = "Buongiorno"
export(Color) var color = Color.black


func _process(_delta):
	bbcode_text = "[center]" + "[color=#" + color.to_html(false) + "]" + content + "[/color][/center]"
