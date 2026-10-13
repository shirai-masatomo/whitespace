shader_type canvas_item;
render_mode unshaded;
uniform sampler2D gravel : filter_nearest, repeat_enable;
uniform sampler2D bedrock : filter_nearest, repeat_enable;
varying vec2 ground_pixel;
float hash2(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float patch_noise(vec2 p) {
 vec2 cell=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash2(cell),hash2(cell+vec2(1.0,0.0)),f.x),mix(hash2(cell+vec2(0.0,1.0)),hash2(cell+vec2(1.0)),f.x),f.y);
}
void vertex() { ground_pixel=VERTEX; }
void fragment() {
 // World-fixed two-pixel grains; no TIME, screen coordinates or blurred border.
 vec2 p=floor(ground_pixel/2.0);
 vec4 weights=COLOR;
 float grain=hash2(p);
 float patch=patch_noise(p/10.0);
 float clod=hash2(floor(p/2.0));
 vec3 earth=vec3(0.525,0.475,0.380);
 vec3 grass=vec3(0.447,0.490,0.329);
 vec3 sand=vec3(0.610,0.529,0.404);
 vec3 clay=vec3(0.435,0.440,0.445);
 float vegetation=step(patch*0.90+clod*0.10,weights.r);
 vec3 result=mix(earth,grass,vegetation*0.68);
 float mineral_pick=patch*0.80+clod*0.20;
 result=mix(result,sand,step(mineral_pick,weights.g*0.92));
 result=mix(result,clay,step(mineral_pick,weights.b*0.65));
 result += (floor(grain*5.0)/4.0-0.5)*0.024;
 // Fine short blades and soil clods, not a continuous green fill.
 if(vegetation>0.5 && hash2(floor(p/vec2(4.0,3.0)))>0.78 && mod(p.x,4.0)<1.0) result+=vec3(0.065,0.069,0.025);
 if(grain<0.05) result-=vec3(0.040,0.032,0.026);
 float debris=smoothstep(0.23,0.59,weights.a);
 float rock=smoothstep(0.50,0.82,weights.a);
 // Preserve delivered stone patterns but break the edge into discrete grains.
 vec2 stone_uv=ground_pixel/vec2(48.0,42.0);
 vec4 grit=texture(gravel,stone_uv);
 vec4 stone=texture(bedrock,stone_uv);
 result=mix(result,grit.rgb*0.88,step(mineral_pick,debris)*grit.a*0.72);
 result=mix(result,stone.rgb*0.87,step(mineral_pick,rock)*stone.a);
 COLOR=vec4(result,1.0);
}
