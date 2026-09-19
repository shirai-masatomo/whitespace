shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_never;
void fragment() {
 float d = length(UV - vec2(0.5));
 float core = 1.0 - smoothstep(0.09, 0.11, d);
 float halo = pow(max(0.0,1.0-d*2.0),4.0);
 ALBEDO = mix(vec3(1.0,0.74,0.38), vec3(1.0,0.98,0.85), core);
 EMISSION = vec3(1.0,0.9,0.6) * core * 0.6;
 ALPHA = core + halo * 0.25;
}
