shader_type spatial;
render_mode cull_disabled;
varying float edge;
varying float dorsal;
void vertex() {
 edge = abs(VERTEX.x);
 dorsal = smoothstep(-0.25,0.5,NORMAL.y);
 VERTEX.y += sin(TIME * 2.2 - edge * .65) * pow(edge / 3.6, 2.0) * .6;
}
void fragment() {
 ALBEDO = mix(vec3(.51,.63,.58),vec3(.11,.22,.25),dorsal);
 ROUGHNESS = .42;
}
