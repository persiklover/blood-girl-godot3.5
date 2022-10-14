shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (color.a != 0.0) {
		color = vec4(1, 1, 1, 1);
	}
	COLOR = color;
}