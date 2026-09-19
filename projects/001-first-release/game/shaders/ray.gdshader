shader_type spatial;
render_mode cull_disabled;
varying float edge;
void vertex() {
 edge = abs(VERTEX.x);
 VERTEX.y += sin(TIME * 2.2 - edge * .65) * pow(edge / 3.6, 2.0) * .6;
}
void fragment() {
 ALBEDO = FRONT_FACING ? vec3(.16,.30,.32) : vec3(.51,.63,.58);
 ROUGHNESS = .42;
}
