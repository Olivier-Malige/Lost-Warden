shader_type canvas_item;
render_mode blend_add;

varying vec4 particle_color;

void vertex() {
	particle_color = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	// Replace the legacy violet accent with the blue ship's hull highlight.
	if (distance(texel.rgb, vec3(185.0, 121.0, 200.0) / 255.0) < 0.01) {
		texel.rgb = vec3(120.0, 183.0, 207.0) / 255.0;
	}
	COLOR = texel * particle_color;
}
