shader_type canvas_item;

uniform vec4 base_color : hint_color = vec4(1.0, 1.0, 1.0, 1.0);

float random( float seed ) {
	return fract( 543.2543 * sin( dot( vec2( seed, seed ), vec2( 3525.46, -54.3415 ) ) ) );
}

void fragment() {
	
	vec2 fixed_uv = UV;
	//fixed_uv.x += random(TIME) * .05;
	//fixed_uv.y += sin(TIME);
	
	vec4 original_color = texture(TEXTURE, fixed_uv);
	vec4 color = original_color;
	vec4 d4 = abs(color - base_color);
    float d = max(max(d4.r, d4.g), d4.b);
    if(d < 0.05) {
		//color = vec4(random(fixed_uv.x), random(fixed_uv.x), random(fixed_uv.y), 1);
		color = vec4(
			random(sin(SCREEN_UV.x) * TIME * 9.0),
			random(cos(SCREEN_UV.y) * TIME * 99.0),
			random(cos(SCREEN_UV.y)),
			1
		);
	}
	
	COLOR = vec4(color.rgb, original_color.a);
}