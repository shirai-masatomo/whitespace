shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment() {
 float edge = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.0);
 float ripple = .5 + .5 * sin(UV.y * 42.0 + sin(UV.x * 30.0 + TIME) * 1.5 - TIME);
 ALBEDO = mix(vec3(.14,.48,.58),vec3(.76,.98,.87),edge);
 EMISSION = vec3(.1,.35,.3) * edge;
 ALPHA = .015 + edge * (.27 + ripple * .13);
}
