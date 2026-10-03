shader_type canvas_item;
// Rendering-only key for the unmodified user-provided white-background atlas.
void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	ivec2 size = textureSize(TEXTURE, 0);
	if (size.x == 2508 && size.y == 627) {
		float white = min(sample_color.r, min(sample_color.g,sample_color.b));
		COLOR.a *= 1.0 - smoothstep(0.94,0.98,white);
	}
}
