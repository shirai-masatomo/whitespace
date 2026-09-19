shader_type spatial;
render_mode cull_disabled;
#include "res://game/shaders/natural_noise.gdshaderinc"
uniform bool trunk = false;
varying vec3 local_point;
varying vec3 local_normal;
float noise(vec2 p){return natural_noise(vec3(p,3.0));}
void vertex(){local_point=VERTEX;local_normal=NORMAL;}
void fragment(){
 vec2 p=trunk ? vec2(atan(local_point.z,local_point.x)*2.0,local_point.y) : local_point.xz;
 float stain=noise(p*vec2(1.7,0.24));
 float phase=p.x*31.0+noise(p*vec2(2.0,0.35))*8.0;
 float visible=1.0-smoothstep(1.0,3.0,fwidth(phase));
 float grain=0.5+0.5*sin(phase)*visible;
 float split=smoothstep(0.86,0.98,grain)*noise(p*vec2(4.0,0.9));
 vec3 dark=trunk ? vec3(0.075,0.038,0.018) : vec3(0.19,0.14,0.09);
 vec3 light=trunk ? vec3(0.27,0.18,0.085) : vec3(0.36,0.29,0.21);
 ALBEDO=mix(dark,light,0.3+stain*0.55+grain*0.08)*(1.0-split*0.5);
 if(trunk && abs(local_normal.y)>0.75){
  float rings=0.5+0.5*sin(length(local_point.xz)*26.0+noise(local_point.xz*3.0));
  ALBEDO=mix(vec3(0.22,0.14,0.065),vec3(0.36,0.25,0.12),rings*0.28+0.35);
 }
 ROUGHNESS=0.78+stain*0.2;
}
