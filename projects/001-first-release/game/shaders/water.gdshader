shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
varying vec3 world_point;
void vertex() {
 world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 VERTEX.y += sin(world_point.x * 0.17 + TIME * 0.8) * 0.10;
 VERTEX.y += sin(world_point.z * 0.23 - TIME * 0.65) * 0.08;
}
void fragment() {
 float underwater = 1.0 - smoothstep(-1.5,0.8,CAMERA_POSITION_WORLD.y);
 vec2 p = world_point.xz;
 float a = sin(dot(p, vec2(0.18,0.11)) + TIME * 0.8);
 float b = sin(dot(p, vec2(-0.09,0.23)) - TIME * 0.65);
 float c = sin(dot(p, vec2(0.46,-0.37)) + TIME * 1.4);
 vec3 n = normalize(vec3(a * 0.055 + c * 0.02, 1.0, b * 0.055));
 vec3 v = normalize(CAMERA_POSITION_WORLD - world_point);
 float fresnel = pow(1.0 - abs(dot(n,v)), 4.0);
 vec3 base = mix(vec3(0.02,0.16,0.23), vec3(0.38,0.65,0.74), fresnel);
 float glint = pow(max(0.0,dot(reflect(-v,n),normalize(vec3(0.11,0.17,-1.0)))), 180.0);
 base += vec3(1.0,0.89,0.65) * glint * 1.8;
 ALBEDO = mix(base, vec3(0.32,0.67,0.72) + (a+b)*0.014, underwater);
 float window = exp(-dot(p-vec2(15.0,-45.0),p-vec2(15.0,-45.0))/260.0);
 EMISSION = vec3(0.70,0.93,1.0) * window * underwater * 5.0;
 float distance_fade = 1.0 - smoothstep(500.0,1150.0,length(CAMERA_POSITION_WORLD.xz-p));
 float depth_fade = exp(-max(0.0,-CAMERA_POSITION_WORLD.y-20.0)/35.0);
 ALPHA = mix(0.97,(0.35 + window * 0.65)*depth_fade,underwater)*distance_fade;
}
