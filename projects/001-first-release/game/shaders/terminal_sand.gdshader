shader_type spatial;
render_mode cull_disabled;
#include "res://game/shaders/natural_noise.gdshaderinc"
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float n=natural_noise(wp*.11);
 float ripple=sin(wp.x*2.4+sin(wp.z*.18)*2.0)*.018;
 ALBEDO=mix(vec3(.29,.25,.16),vec3(.64,.57,.38),n)+ripple;
 ROUGHNESS=.97;
}
