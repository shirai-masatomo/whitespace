shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
void vertex(){VERTEX.xz*=1.0+sin(TIME*2.0+VERTEX.y*0.5)*0.045;}
void fragment(){
 float rim=pow(1.0-max(dot(NORMAL,VIEW),0.0),3.0);
 float veins=pow(abs(sin(UV.x*50.265)),14.0);
 ALBEDO=mix(vec3(0.14,0.3,0.36),vec3(0.5,0.8,0.78),rim);
 EMISSION=vec3(0.04,0.45,0.48)*(rim*.55+veins*.16);
 ROUGHNESS=.22;
 ALPHA=.50+rim*.42;
}
