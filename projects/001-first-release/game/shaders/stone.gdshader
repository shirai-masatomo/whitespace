shader_type spatial;
varying vec3 world_point;
void vertex() { world_point = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float grain = sin(world_point.x * 2.4) * sin(world_point.z * 2.0) * 0.05;
	float lines = pow(abs(sin(world_point.x * 0.7 + world_point.z * 0.35 + TIME * 0.4)), 18.0);
	float other = pow(abs(sin(world_point.z * 0.8 - world_point.x * 0.2 - TIME * 0.3)), 18.0);
	float caustic = max(lines, other) * exp(min(world_point.y, 0.0) / 75.0);
	ALBEDO = vec3(0.21,0.32,0.32) + grain;
	EMISSION = vec3(0.16,0.46,0.40) * caustic * 0.5;
	ROUGHNESS = 0.8;
}
