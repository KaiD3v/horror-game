// Mist banks (world/clima.gd): big soft cards standing on the ground, turned to the camera, drifting downhill;
// they fade where they cut into the ground and as you walk through them.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled;
uniform sampler2D noise : repeat_enable, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec4 tint : source_color;
uniform float density = 0.5;
uniform float seed = 0.0;
void fragment() {
	float n = texture(noise, UV * vec2(0.7, 0.4) + vec2(TIME * 0.012 + seed, seed * 0.37)).r;
	n *= texture(noise, UV * vec2(1.6, 0.9) - vec2(TIME * 0.02, seed)).r * 1.8;
	float shape = smoothstep(0.0, 0.3, UV.x) * smoothstep(1.0, 0.7, UV.x) * smoothstep(0.0, 0.45, UV.y) * smoothstep(1.0, 0.85, UV.y);
	shape *= mix(0.45, 1.0, UV.y);  // thicker low down
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	float soft = clamp((-v.z / v.w + VERTEX.z) / 2.0, 0.0, 1.0);   // fades where it cuts into the ground
	float near = smoothstep(1.5, 6.0, -VERTEX.z);                  // and as you walk through it
	ALBEDO = tint.rgb;
	ALPHA = clamp(n * shape * density * soft * near, 0.0, 0.85);
}
