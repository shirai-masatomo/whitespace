shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.65,0.9,1.0,0.06);
void fragment() {
	float stripe = pow(max(sin(UV.x * 3.14159),0.0), 3.0);
	float end_fade = sin(UV.y * 3.14159);
	ALBEDO = tint.rgb;
	EMISSION = tint.rgb * 1.0;
	ALPHA = stripe * end_fade * tint.a;
}
