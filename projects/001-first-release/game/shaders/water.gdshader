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
 ALBEDO = mix(base, vec3(0.025,0.15,0.20) + (a+b)*0.008, underwater);
 float window = smoothstep(0.42,0.86,-v.y);
 float sun_window = pow(max(0.0, dot(-v,normalize(vec3(0.14,0.7,-0.5)))),36.0);
 // In unshaded water the transmitted sky belongs in albedo, not only emission.
 ALBEDO += underwater * (vec3(0.30,0.60,0.66)*window + vec3(1.0,0.93,0.72)*sun_window*2.0);
 float distance_fade = 1.0 - smoothstep(500.0,1150.0,length(CAMERA_POSITION_WORLD.xz-p));
 float depth_fade = exp(-max(0.0,-CAMERA_POSITION_WORLD.y-20.0)/35.0);
 ALPHA = mix(0.97,depth_fade,underwater)*distance_fade;
}
