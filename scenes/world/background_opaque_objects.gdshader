shader_type canvas_item;

uniform int draw_mode = 0;
uniform float horizontal_blend_width = 0.0;
const float NEBULA_OPACITY = 0.68;
const float DEBRIS_OPACITY = 0.78;

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

bool is_planet(vec4 source) {
	return source.a > 0.35 && max(source.r, max(source.g, source.b)) < 0.34;
}

bool is_star(vec4 source) {
	bool pale = source.r > 0.55 && source.g > 0.55 && source.b > 0.55;
	bool amber = source.r > 0.55 && source.g > 0.3 && source.b < 0.35 && source.r > source.g * 1.25;
	return source.a > 0.5 && (pale || amber);
}

// Premultiplied color prevents dark halos when blending faint cloud edges.
vec4 nebula_color(vec4 source) {
	if (is_planet(source) || is_star(source)) {
		return vec4(0.0);
	}
	return vec4(source.rgb * source.a, source.a);
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	bool planet = is_planet(source);
	bool star = is_star(source);
	if ((draw_mode == 1 || draw_mode == 5) && !star && horizontal_blend_width > 0.0) {
		float u = fract(UV.x);
		float edge_distance = min(u, 1.0 - u) / TEXTURE_PIXEL_SIZE.x;
		float blend = 0.5 * (1.0 - smoothstep(0.0, horizontal_blend_width, edge_distance));
		// Texel centers keep the opposite-edge sample stable across repeated regions.
		float opposite_u = 1.0 - (floor(u / TEXTURE_PIXEL_SIZE.x + 0.001) + 0.5) * TEXTURE_PIXEL_SIZE.x;
		vec4 opposite = texture(TEXTURE, vec2(opposite_u, UV.y));
		vec4 cloud = mix(nebula_color(source), nebula_color(opposite), blend);
		COLOR.rgb = cloud.rgb / max(cloud.a, 0.00001) * vertex_color.rgb;
		COLOR.a = cloud.a * NEBULA_OPACITY * vertex_color.a;
	} else {
		if (source.a <= 0.0 || (draw_mode == 1 && planet) || (draw_mode == 2 && !planet)
			|| (draw_mode == 3 && !star) || (draw_mode == 4 && star)) {
			discard;
		}
		if (draw_mode == 2) {
			COLOR.rgb = max(source.rgb * 1.2, vec3(0.07, 0.08, 0.11)) * vertex_color.rgb;
			COLOR.a = vertex_color.a;
		} else if (draw_mode == 1 || draw_mode == 5) {
			COLOR.a = vertex_color.a * (star ? 1.0 : source.a * NEBULA_OPACITY);
		} else if (draw_mode == 4) {
			COLOR.a = vertex_color.a * source.a * DEBRIS_OPACITY;
		} else {
			COLOR.a = vertex_color.a;
		}
	}
}
