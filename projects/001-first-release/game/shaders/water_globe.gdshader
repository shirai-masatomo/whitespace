shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform vec3 tint = vec3(.10,.65,.82);
void fragment(){
 float wave=sin(UV.x*35.0+sin(UV.y*23.0+TIME)*3.0-TIME)*.5+.5;
 float rim=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),2.0);
 ALBEDO=tint*.28;
 EMISSION=tint*(.45+rim*2.3+wave*.25);
 ROUGHNESS=.12;
 ALPHA=.52+rim*.35;
}
