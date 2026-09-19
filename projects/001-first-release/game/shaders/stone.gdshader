shader_type spatial;
render_mode cull_disabled;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 p){vec3 i=floor(p);vec3 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
varying vec3 wp;
varying float tint_variation;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;tint_variation=hash(MODEL_MATRIX[3].xyz*0.31);}
void fragment(){
 float footprint=max(length(dFdx(wp)),length(dFdy(wp)));
 float detail=1.0-smoothstep(0.05,0.55,footprint);
 float n=noise(wp*0.5)*0.5+mix(0.5,noise(wp*2.7)*0.6+noise(wp*5.0)*0.4,detail)*0.5;
 float strata=sin(wp.y*1.4+n*6.0)*0.5+0.5;
 vec3 stone=mix(vec3(0.10,0.15,0.15),vec3(0.42,0.43,0.34),n);
 stone*=0.7+strata*0.3;
 stone=mix(stone*vec3(0.85,1.02,1.05),stone*vec3(1.15,1.02,0.86),tint_variation);
 float moss=smoothstep(0.55,0.8,noise(wp*0.35+7.0));
 ALBEDO=mix(stone,vec3(0.12,0.22,0.12),moss*0.6);
 ROUGHNESS=0.8;
 float caustic=pow(1.0-abs(sin(wp.x*0.65+sin(wp.z*0.5+TIME*0.5))+sin(wp.z*0.63-TIME*0.3))*0.5,12.0);
 EMISSION=vec3(0.04,0.10,0.08)*caustic*exp(min(0.0,wp.y)/65.0);
}
