shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void vertex(){
 vec3 scale=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*scale.x,INV_VIEW_MATRIX[1]*scale.y,INV_VIEW_MATRIX[2]*scale.z,MODEL_MATRIX[3]);
}
void fragment(){
 vec2 p=UV*2.0-1.0;
 float r=length(p);
 float ring=exp(-pow((r-.76)*17.0,2.0));
 float shine=exp(-dot(p-vec2(-.28,-.37),p-vec2(-.28,-.37))*55.0);
 ALBEDO=vec3(.6,.86,.92)+shine*.5;
 ALPHA=(ring*.42+shine*.8)*(1.0-smoothstep(.85,1.0,r));
}
