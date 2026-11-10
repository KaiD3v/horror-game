// The title menu's fog drifting over the painting (ui/menu.gd).
shader_type canvas_item;
uniform sampler2D noise : repeat_enable, filter_linear;
void fragment() {
	vec2 uv = UV * vec2(1.6, 1.0);
	float a = texture(noise, uv * 0.7 + vec2(TIME * 0.012, 0.0)).r;
	float b = texture(noise, uv * 1.3 - vec2(TIME * 0.02, TIME * 0.004)).r;
	float f = smoothstep(0.35, 0.85, a * 0.6 + b * 0.5) * smoothstep(0.15, 0.75, UV.y);  // thicker low down
	COLOR = vec4(0.62, 0.66, 0.68, f * 0.32);
}
