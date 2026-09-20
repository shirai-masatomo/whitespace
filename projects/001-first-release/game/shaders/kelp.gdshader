shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
void vertex(){
 wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.x+=sin(TIME*0.9+wp.z*0.4+UV.y*3.0)*UV.y*UV.y*0.55;
 VERTEX.z+=cos(TIME*0.7+wp.x*0.3)*UV.y*0.2;
}
void fragment(){
 // Nearby scenery must not cover the third-person camera while turning.
 float visibility = smoothstep(1.2, 3.4, length(VERTEX));
 float dither = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
 if (dither > visibility) discard;
 float vein=pow(abs(sin(UV.x*3.14159)),8.0);
 ALBEDO=mix(vec3(0.05,0.16,0.08),vec3(0.28,0.39,0.09),UV.y)*(.7+vein*.3);
 ROUGHNESS=0.5;
 BACKLIGHT=vec3(0.15,0.3,0.07)*0.3;
}
