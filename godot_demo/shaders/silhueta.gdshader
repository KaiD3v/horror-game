// The far shapes beyond the fog (levels/vilarejo.gd: silhueta_* materials): ridges, araucarias, the Colônia over its
// wall. Fog-free: a haze of their own, so they read through the fog as layers; a lit window glows, flickering.
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, shadows_disabled;
uniform vec3 dark : source_color;
uniform vec3 fog : source_color;
uniform float least = 0.6;      // the haze it never gets clearer than
uniform float density = 0.0;    // how fast distance adds to it
uniform float light = 0.0;      // 1 = a lit window: it glows, flickering, and the haze only dims it
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float h = 1.0 - exp(-length(wpos - CAMERA_POSITION_WORLD) * density);
	float low = smoothstep(14.0, -2.0, wpos.y) * 0.45;  // mist lying along their feet
	float k = clamp(max(h, least) + low, 0.0, 0.93);
	vec3 c = mix(dark, fog, k);
	if (light > 0.5) {
		float f = 0.85 + 0.1 * sin(TIME * 7.0) + 0.05 * sin(TIME * 23.0);
		c = mix(dark * f, fog, k * 0.55);
	}
	ALBEDO = c;
}
