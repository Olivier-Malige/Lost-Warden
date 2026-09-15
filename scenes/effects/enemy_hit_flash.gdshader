shader_type canvas_item;

instance uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float flash_strength : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), hit_flash * flash_strength);
}
