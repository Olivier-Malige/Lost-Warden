shader_type canvas_item;

instance uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
instance uniform float port_hit_flash : hint_range(0.0, 1.0) = 0.0;
instance uniform float starboard_hit_flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 pixel = mod(UV / TEXTURE_PIXEL_SIZE, vec2(128.0, 96.0));
	float gun_y = step(54.0, pixel.y) * (1.0 - step(84.0, pixel.y));
	float port = step(14.0, pixel.x) * (1.0 - step(34.0, pixel.x)) * gun_y;
	float starboard = step(94.0, pixel.x) * (1.0 - step(114.0, pixel.x)) * gun_y;
	float core = step(52.0, pixel.x) * (1.0 - step(76.0, pixel.x))
		* step(16.0, pixel.y) * (1.0 - step(92.0, pixel.y));
	float flash = max(core * hit_flash, max(port * port_hit_flash, starboard * starboard_hit_flash));
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.94, 0.84), flash * 0.9);
}
