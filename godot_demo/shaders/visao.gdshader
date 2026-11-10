// What the player's body does to his sight (ui/hud.gd, in place of bars), over the whole screen:
//   hurt  (PlayerCondition.wound: 1/3 a hit): the colour drains and a dark red closes in from the edges; at the last hit
//         it throbs, like blood in the temples
//   tired (PlayerCondition.tired: stamina below 60 %, 1 winded): the edges darken and open again with each pant
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float hurt = 0.0;
uniform float tired = 0.0;

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	float r = length((SCREEN_UV - 0.5) * vec2(1.6, 1.0));  // 0 centre, ~0.94 the corners
	float beat = smoothstep(0.55, 0.7, hurt) * pow(0.5 + 0.5 * sin(TIME * 7.0), 8.0);
	float pant = 0.5 + 0.5 * sin(TIME * 13.0);
	float grey = dot(c, vec3(0.3, 0.59, 0.11));
	c = mix(c, vec3(grey) * vec3(1.0, 0.94, 0.92), clamp(hurt * (0.3 + 0.6 * r), 0.0, 0.85));
	float red = smoothstep(0.85 - 0.5 * hurt - 0.12 * beat, 1.1, r) * min(1.0, hurt * 1.6);
	c = mix(c, vec3(0.10, 0.0, 0.0), red * 0.9);
	c *= 1.0 - smoothstep(0.95 - 0.4 * tired * (0.75 + 0.25 * pant), 1.2, r) * tired * 0.85;
	COLOR = vec4(c, 1.0);
}
