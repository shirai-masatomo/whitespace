shader_type spatial;
render_mode cull_disabled;
varying float belly;
void vertex(){
 belly=VERTEX.y;
 float phase=TIME*0.32+INSTANCE_CUSTOM.x*0.24;
 VERTEX.x+=sin(TIME*9.0+INSTANCE_CUSTOM.x*25.0)*smoothstep(0.1,0.75,-VERTEX.z)*0.16;
 vec2 heading=normalize(vec2(cos(phase)*6.0,-sin(phase)*4.0));
 mat3 turn=mat3(vec3(heading.y,0.0,-heading.x),vec3(0.0,1.0,0.0),vec3(heading.x,0.0,heading.y));
 VERTEX=turn*VERTEX+vec3(sin(phase)*6.0,sin(phase*1.7)*0.6,cos(phase)*4.0);
 NORMAL=turn*NORMAL;
}
void fragment(){
 ALBEDO=mix(vec3(0.06,0.24,0.28),vec3(0.68,0.76,0.55),(1.0-smoothstep(-0.12,0.16,belly)));
 ROUGHNESS=0.32;
 METALLIC=0.45;
}
