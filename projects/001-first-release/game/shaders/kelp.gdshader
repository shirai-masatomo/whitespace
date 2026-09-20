shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
varying vec3 wp;
uniform float stipe_height = 0.0;
uniform float phase_offset = 0.0;
void vertex(){
 wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float bend = stipe_height > 0.0 ? pow(clamp(VERTEX.y / stipe_height, 0.0, 1.0), 2.0) : UV.y * UV.y;
 VERTEX.x+=sin(TIME*0.7+wp.z*0.15+phase_offset)*bend*0.7;
 VERTEX.z+=cos(TIME*0.5+wp.x*0.12+phase_offset)*bend*0.35;
 VERTEX.x+=sin(TIME*1.3+UV.y*6.0+phase_offset)*UV.y*UV.y*0.08;
}
void fragment(){
 // Nearby scenery must not cover the third-person camera while turning.
 float visibility = smoothstep(1.2, 3.4, length(VERTEX));
 ALPHA = visibility;
 float vein=pow(abs(sin(UV.x*3.14159)),8.0);
 ALBEDO=mix(vec3(0.05,0.16,0.08),vec3(0.28,0.39,0.09),UV.y)*(.7+vein*.3);
 ROUGHNESS=0.5;
 BACKLIGHT=vec3(0.15,0.3,0.07)*0.3;
}
