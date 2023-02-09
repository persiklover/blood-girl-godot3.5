shader_type canvas_item;

uniform float opacity = 1.0;

void fragment() {
//	COLOR.a = opacity;
	vec4 color = texture(TEXTURE, UV);
	if (color.a != 0.0) {
//		color = vec4(1, 1, 1, 1);
	}
	COLOR = color;
}