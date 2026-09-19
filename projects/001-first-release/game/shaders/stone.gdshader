shader_type spatial;
render_mode cull_disabled;
#include "res://game/shaders/natural_noise.gdshaderinc"
varying vec3 wp;
varying float tint_variation;
uniform float caustic_strength = 1.0;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;tint_variation=natural_hash(floor(MODEL_MATRIX[3].xyz*0.31));}
void fragment(){
 vec3 dx=dFdx(wp),dy=dFdy(wp);
 float footprint=max(length(dx),length(dy));
 float detail=1.0-smoothstep(0.02,0.10,footprint);
 float broad=natural_noise(wp*0.12);
 float weather=natural_noise(wp*0.7+vec3(broad*1.5));
 float grain=mix(0.5,natural_noise(wp*3.0),detail);
 // Broken mineral seams and weathering, without repeating horizontal strata.
 float seam=1.0-smoothstep(0.015,0.07,abs(weather-0.47));
 vec3 stone=mix(vec3(0.13,0.18,0.18),vec3(0.39,0.37,0.29),broad*0.7+weather*0.3);
 stone*=0.83+grain*0.30;
 stone=mix(stone,vec3(0.46,0.45,0.37),seam*0.16);
 stone*=mix(vec3(0.86,1.02,1.04),vec3(1.12,1.01,0.88),tint_variation);
 vec3 world_normal=normalize((INV_VIEW_MATRIX*vec4(NORMAL,0.0)).xyz);
 float moss=smoothstep(0.58,0.83,weather)*smoothstep(-0.1,0.75,world_normal.y);
 ALBEDO=mix(stone,vec3(0.105,0.20,0.11),moss*0.4);
 ROUGHNESS=0.76+weather*0.18;
 // Surface-gradient bump in world space; no UV seams or displaced landing geometry.
 float micro=1.0-smoothstep(0.008,0.035,footprint);
 float height=weather*0.025+grain*0.004*micro;
 vec3 r1=cross(dy,world_normal),r2=cross(world_normal,dx);
 float determinant=dot(dx,r1);
 if(abs(determinant)>0.000001){
  vec3 gradient=sign(determinant)*(dFdx(height)*r1+dFdy(height)*r2);
  vec3 perturbed=normalize(abs(determinant)*world_normal-gradient);
  NORMAL=normalize((VIEW_MATRIX*vec4(perturbed,0.0)).xyz);
 }
 float caustic=pow(1.0-abs(sin(wp.x*0.65+sin(wp.z*0.5+TIME*0.5))+sin(wp.z*0.63-TIME*0.3))*0.5,12.0);
 EMISSION=vec3(0.04,0.10,0.08)*caustic*exp(min(0.0,wp.y)/65.0)*caustic_strength;
}
