shader_type spatial;
#include "res://game/shaders/natural_noise.gdshaderinc"
varying vec3 point;
float noise(vec2 p){return natural_noise(vec3(p,9.0));}
void vertex(){
 vec2 p=VERTEX.xz;
 float dune=sin(p.x*0.035)*3.5+cos(p.y*0.028)*5.0+sin((p.x+p.y)*0.012)*8.0;
 float dx=cos(p.x*0.035)*0.1225+cos((p.x+p.y)*0.012)*0.096;
 float dz=-sin(p.y*0.028)*0.14+cos((p.x+p.y)*0.012)*0.096;
 VERTEX.y+=dune;
 NORMAL=normalize(vec3(-dx,1.0,-dz));
 point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment(){
 float field=noise(point.xz*0.035);
 float footprint=max(length(dFdx(point)),length(dFdy(point)));
 float detail=1.0-smoothstep(0.1,0.8,footprint);
 float ripple=sin(point.x*4.0+noise(point.xz*0.5)*4.0)*detail*0.025;
 ALBEDO=mix(vec3(0.23,0.26,0.21),vec3(0.38,0.36,0.26),field)+ripple;
 ROUGHNESS=0.96;
}
