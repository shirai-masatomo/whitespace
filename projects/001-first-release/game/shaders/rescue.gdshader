shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;
void fragment() {
	float rim = pow(1.0 - max(0.0, dot(NORMAL, VIEW)), 2.0);
	float bands = pow(0.5 + 0.5 * sin(UV.y * 28.0 - TIME * 8.0 + UV.x * 6.283), 8.0);
	ALBEDO = mix(vec3(0.12, 0.62, 0.72), vec3(0.7, 1.0, 1.0), rim);
	ALPHA = 0.12 + rim * 0.65 + bands * 0.06;
}
