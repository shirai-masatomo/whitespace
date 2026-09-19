shader_type spatial;
render_mode cull_disabled;
varying vec3 world_point;
void vertex(){
 world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float bend=UV.y*UV.y;
 VERTEX.x+=sin(TIME*0.75+world_point.z*0.65+UV.y*2.8)*bend*0.40;
 VERTEX.z+=cos(TIME*0.63+world_point.x*0.7)*bend*0.24;
}
void fragment(){
 float rib=exp(-abs(UV.x-0.5)*22.0);
 float veins=pow(0.5+0.5*sin(UV.y*55.0+abs(UV.x-0.5)*15.0),8.0);
 float pulse=0.88+0.12*sin(TIME*1.4+world_point.x*0.4);
 ALBEDO=mix(vec3(0.025,0.19,0.08),vec3(0.20,0.67,0.28),UV.y)*(0.8+veins*0.2);
 EMISSION=vec3(0.10,0.85,0.36)*(rib*0.7+smoothstep(0.4,1.0,UV.y)*0.45)*pulse;
 ROUGHNESS=0.48;
 BACKLIGHT=vec3(0.09,0.42,0.12)*0.6;
}
