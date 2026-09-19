shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float rings=sin(wp.x*36.0+sin(wp.z*0.6)*0.4+sin(wp.y*2.0));
 ALBEDO=mix(vec3(0.21,0.15,0.09),vec3(0.28,0.22,0.14),rings*0.5+0.5);
 ROUGHNESS=0.78;
}
