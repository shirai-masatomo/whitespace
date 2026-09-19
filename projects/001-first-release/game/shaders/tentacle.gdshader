shader_type spatial;
render_mode cull_disabled;
void vertex() {
	VERTEX.x += sin(TIME * 1.1 + VERTEX.y * .8) * .05;
	VERTEX.z += sin(TIME * .8 + VERTEX.y * .7) * .04;
}
void fragment() {
	ALBEDO = vec3(.22, .45, .47);
	ROUGHNESS = .32;
	EMISSION = vec3(.015, .04, .045);
}
