shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void vertex() {
	mat4 facing = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	facing[0].xyz *= length(MODEL_MATRIX[0].xyz);
	facing[1].xyz *= length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * facing;
}
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	ALBEDO = vec3(0.62, 0.85, 0.85);
	ALPHA = (1.0 - smoothstep(0.1, 0.9, r)) * 0.4;
}
