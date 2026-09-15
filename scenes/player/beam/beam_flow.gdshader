shader_type canvas_item;
render_mode unshaded;

uniform float frame_index = 0.0;
uniform float team_row = 0.0;
uniform bool overdrive = false;
uniform float flow_length = 8.0;

void fragment() {
	float tier = overdrive ? 4.0 : 2.0;
	float tile_width = overdrive ? 16.0 : 8.0;
	float tile_x = (16.0 - tile_width) * 0.5;
	// Line2D runs U along the beam; the authored tiles run vertically.
	vec2 pixel = vec2(
		(tier * 4.0 + frame_index) * 16.0 + tile_x + clamp(UV.y, 0.0, 0.9999) * tile_width,
		team_row * 8.0 + mod(UV.x * flow_length, 8.0)
	);
	COLOR = texture(TEXTURE, (floor(pixel) + vec2(0.5)) / vec2(320.0, 16.0));
}
