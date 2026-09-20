shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

void vertex() {
 vec3 center = MODEL_MATRIX[3].xyz;
 vec3 flow = normalize(MODEL_MATRIX[1].xyz);
 vec3 toward_camera = normalize(INV_VIEW_MATRIX[3].xyz - center);
 vec3 across = cross(flow, toward_camera);
 if (length(across) < 0.01) across = INV_VIEW_MATRIX[0].xyz;
 vec3 world = center + normalize(across) * VERTEX.x + flow * VERTEX.y;
 VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
}

void fragment() {
 float core = pow(max(0.0, 1.0 - abs(UV.x * 2.0 - 1.0)), 2.0);
 float tip = sin(UV.y * 3.14159265);
 ALBEDO = vec3(0.36, 0.57, 0.55);
 ALPHA = core * tip * 0.42;
}
