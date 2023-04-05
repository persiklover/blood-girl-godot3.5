shader_type canvas_item;

uniform sampler2D dither_texture;
uniform float scale: hint_range(0.1, 10) = 4.0;

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	if (color.a != 0.0) {
		color.r += 0.2;
	}
	COLOR = color;
//	if (color.a != 0.0) {
//		color = texture(dither_texture, (UV / TEXTURE_PIXEL_SIZE) / scale);
//		COLOR = color;
//	}
//	else discard;
}