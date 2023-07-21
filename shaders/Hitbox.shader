shader_type canvas_item;

void fragment() {
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	if (length(abs(vec4(1, 1, 1, 1) -  COLOR)) < 1.0) {
		COLOR += vec4(.2, .5, .8, 0.2);
	}
	else discard;
}