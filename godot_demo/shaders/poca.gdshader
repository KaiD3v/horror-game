// A puddle on the road (world/clima.gd): dark, glossy, the overcast sky in it at a low angle, rings from the drizzle.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
uniform sampler2D noise : repeat_enable, filter_linear;
uniform float seed = 0.0;
uniform vec3 sky : source_color;
void fragment() {
	vec2 c = UV - 0.5;
	float n = texture(noise, UV * 0.6 + seed).r;
	float a = 1.0 - smoothstep(0.32, 0.46, length(c) + (n - 0.5) * 0.25);
	vec2 g = UV * 5.0 + seed * 7.0;  // a drop lands in each cell, its ring spreads and fades
	vec2 cell = floor(g); vec2 f = fract(g) - 0.5;
	float h = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	float ph = fract(TIME * 0.8 + h);
	float r = length(f); float d = r - ph * 0.45;
	float wave = exp(-d * d * 500.0) * (1.0 - ph);
	vec2 slope = r > 0.001 ? f / r * wave : vec2(0.0);
	NORMAL_MAP = vec3(slope * 0.5 + 0.5, 1.0);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = vec3(0.03, 0.035, 0.04);
	EMISSION = sky * fres * 0.7;  // the overcast sky in it at a low angle
	ROUGHNESS = 0.05; METALLIC = 0.0; SPECULAR = 1.0;
	ALPHA = a * 0.94;
}
