shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;
varying vec3 point;
void vertex(){point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float wave=sin(point.x*1.8+TIME*0.8)*cos(point.z*2.2-TIME*0.6);
 ALBEDO=vec3(0.035,0.13,0.15)+wave*0.009;
 ROUGHNESS=0.19;
 METALLIC=0.3;
 ALPHA=0.72;
}
