shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_never;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
varying vec3 world_point;
float hash(vec2 p){
 uvec2 q=uvec2(ivec2(p));
 uint h=q.x*uint(374761393)+q.y*uint(668265263);
 h=(h^(h>>uint(13)))*uint(1274126177);
 return float(h^(h>>uint(16)))/4294967295.0;
}
float noise(vec2 p){
 vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float ripple(vec2 p){
 vec2 drift=vec2(TIME*0.20,-TIME*0.13);
 p+=vec2(noise(p*0.09+drift*0.1),noise(p*0.07+27.0-drift*0.2))*3.0;
 float broad=noise(p*0.19+drift*0.5);
 return broad*0.36+noise(p*0.72-drift)*0.13+noise(p*1.9+drift)*0.035;
}
void vertex(){
 world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.y+=sin(world_point.x*0.17+TIME*0.8)*0.10+sin(world_point.z*0.23-TIME*0.65)*0.08;
}
void fragment(){
 float underwater=1.0-smoothstep(-1.5,0.8,CAMERA_POSITION_WORLD.y);
 vec2 p=world_point.xz;
 vec2 slope=vec2(ripple(p+vec2(0.2,0))-ripple(p-vec2(0.2,0)),ripple(p+vec2(0,0.2))-ripple(p-vec2(0,0.2)))/0.4;
 vec3 n=normalize(vec3(-slope.x,1.0,-slope.y));
 vec3 v=normalize(CAMERA_POSITION_WORLD-world_point);
 float fresnel=pow(clamp(1.0-abs(dot(n,v)),0.0,1.0),4.0);
 // Renderer-specific NDC: Godot advanced_postprocessing documentation.
 float raw_depth=texture(depth_texture,SCREEN_UV).r;
 #if CURRENT_RENDERER == RENDERER_COMPATIBILITY
 vec3 ndc=vec3(SCREEN_UV,raw_depth)*2.0-1.0;
 #else
 vec3 ndc=vec3(SCREEN_UV*2.0-1.0,raw_depth);
 #endif
 vec4 scene_view=INV_PROJECTION_MATRIX*vec4(ndc,1.0);
 scene_view.xyz/=max(scene_view.w,0.00001);
 float thickness=clamp(length(scene_view.xyz-VERTEX),0.0,120.0);
 vec3 transmission=exp(-thickness*vec3(0.10,0.047,0.027));
 vec3 below=textureLod(screen_texture,SCREEN_UV,0.0).rgb;
 vec3 refracted=below*transmission+vec3(0.012,0.12,0.17)*(1.0-transmission);
 vec3 sky=mix(vec3(0.16,0.37,0.47),vec3(0.46,0.65,0.74),fresnel);
 vec3 base=mix(refracted,sky,0.045+fresnel*0.85);
 vec3 sun=normalize(vec3(0.246,0.309,-0.919));
 float glint=pow(max(0.0,dot(reflect(-v,n),sun)),180.0);
 base+=vec3(1.0,0.89,0.65)*glint*1.5;
 float shore=(1.0-smoothstep(0.2,1.8,thickness))*smoothstep(0.38,0.70,noise(p*2.1+TIME*0.2));
 base=mix(base,vec3(0.65,0.80,0.79),shore*0.7);
 vec3 underside=vec3(0.025,0.15,0.20)+ripple(p)*0.025;
 float window=smoothstep(0.42,0.86,-v.y);
 float sun_window=pow(max(0.0,dot(-v,normalize(vec3(0.18,0.70,-0.67)))),36.0);
 underside+=vec3(0.30,0.60,0.66)*window+vec3(1.0,0.93,0.72)*sun_window*1.6;
 ALBEDO=mix(base,underside,underwater);
 float distance_fade=1.0-smoothstep(500.0,1150.0,length(CAMERA_POSITION_WORLD.xz-p));
 float depth_fade=exp(-max(0.0,-CAMERA_POSITION_WORLD.y-20.0)/35.0);
 ALPHA=mix(0.99,depth_fade,underwater)*distance_fade;
}
