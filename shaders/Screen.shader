shader_type canvas_item;

uniform int pixel_size = 4;

void fragment() {
    COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
    COLOR.r += .2;
}