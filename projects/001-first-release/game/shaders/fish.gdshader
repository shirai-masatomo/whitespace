shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
varying float belly;
varying vec3 body_position;
uniform bool guided_motion = false;
void vertex(){
 belly=VERTEX.y;
 body_position=VERTEX;
 float phase=TIME*0.32+INSTANCE_CUSTOM.x*0.24;
 VERTEX.x+=sin(TIME*9.0+INSTANCE_CUSTOM.x*25.0)*smoothstep(0.1,0.75,-VERTEX.z)*0.16;
 if(guided_motion){
  VERTEX+=vec3(sin(TIME*0.7+INSTANCE_CUSTOM.x*6.0)*0.4,sin(TIME*0.6+INSTANCE_CUSTOM.x*9.0)*0.3,0.0);
 }else{
  vec2 heading=normalize(vec2(cos(phase)*6.0,-sin(phase)*4.0));
  mat3 turn=mat3(vec3(heading.y,0.0,-heading.x),vec3(0.0,1.0,0.0),vec3(heading.x,0.0,heading.y));
  VERTEX=turn*VERTEX+vec3(sin(phase)*6.0,sin(phase*1.7)*0.6,cos(phase)*4.0);
  NORMAL=turn*NORMAL;
 }
}
void fragment(){
 // Nearby scenery must not cover the third-person camera while turning.
 float visibility = smoothstep(1.2, 3.4, length(VERTEX));
 ALPHA = visibility;
 vec3 silver=mix(vec3(0.05,0.16,0.19),vec3(0.62,0.73,0.72),1.0-smoothstep(-0.05,0.12,belly));
 float stripe=1.0-smoothstep(0.008,0.026,abs(belly-0.025));
 silver=mix(silver,vec3(0.23,0.44,0.51),stripe*0.45);
 // Both flanks have an eye; no per-animal nodes or texture dependencies.
 float eye=1.0-smoothstep(0.016,0.023,length(body_position.yz-vec2(0.026,0.43)));
 silver=mix(silver,vec3(0.012,0.027,0.03),eye);
 ALBEDO=mix(silver,vec3(0.15,0.32,0.35),COLOR.r*0.7);
 ROUGHNESS=0.42;
 METALLIC=0.25;
}
