// Blood over the protagonist (player/player_condition.gd), spreading with `wound`: 0 unhurt, +1/3 a hit, 1 dead. An overlay pass
// (next_pass) on his clothes and skin. CUSTOM0 carries each vertex's rest position, so the stains ride the skin
// through every clip. The cuts are segments in that rest pose (glTF: +x his left, +y up, +z his front).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, specular_disabled, diffuse_lambert;

uniform float wound = 0.0;
varying vec3 rest;

const int N = 8;
const vec3 A[N] = vec3[](
	vec3(0.58, 1.30, 0.01),    // the old wound under the bandage: it soaks through, then drenches the forearm
	vec3(0.12, 1.30, -0.14),   // 1st hit: a slash down the back, from the left shoulder blade
	vec3(0.60, 1.25, 0.0),     //          the left hand, pressed to it
	vec3(0.14, 1.08, 0.14),    // 2nd hit: the ribs, front left
	vec3(-0.20, 1.33, -0.06),  //          the right shoulder (the one the camera looks over)
	vec3(0.03, 1.63, 0.10),    //          a cut on the brow, running down the face
	vec3(0.10, 0.62, 0.10),    //          the left thigh
	vec3(-0.60, 1.25, 0.0));   //          the right hand
const vec3 B[N] = vec3[](
	vec3(0.66, 1.30, 0.01), vec3(-0.02, 1.08, -0.15), vec3(0.70, 1.25, 0.0), vec3(0.06, 0.98, 0.145),
	vec3(-0.08, 1.22, -0.13), vec3(0.07, 1.60, 0.105), vec3(0.08, 0.55, 0.10), vec3(-0.70, 1.25, 0.0));
// opens at (wound), spreads over (wound), radius (m), drip (how far it runs down; 0 on the arms, T-posed at rest)
const vec4 S[N] = vec4[](
	vec4(0.0, 0.67, 0.09, 0.0), vec4(0.03, 0.3, 0.045, 1.0), vec4(0.1, 0.25, 0.05, 0.0), vec4(0.37, 0.3, 0.07, 1.2),
	vec4(0.37, 0.3, 0.05, 0.8), vec4(0.37, 0.3, 0.03, 2.5), vec4(0.4, 0.3, 0.05, 0.8), vec4(0.45, 0.3, 0.04, 0.0));

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1) * 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	rest = CUSTOM0.xyz;
}

void fragment() {
	vec3 p = floor(rest * 90.0) / 90.0;  // ~1 cm texels, like the 32 px cloth textures
	float n = noise(p * 28.0) * 0.65 + noise(p * 70.0) * 0.35;
	float streak = noise(vec3(p.x * 55.0, 0.0, p.z * 55.0));  // some columns run further than others
	float best = -1.0;
	for (int i = 0; i < N; i++) {
		float r = S[i].z * clamp((wound - S[i].x) / S[i].y, 0.0, 1.0);
		if (r <= 0.0) {
			continue;
		}
		vec3 ab = B[i] - A[i];
		vec3 d = p - (A[i] + ab * clamp(dot(p - A[i], ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0));
		if (d.y < 0.0) {
			d.y /= 1.0 + S[i].w * (0.3 + 2.5 * streak * streak);
		}
		best = max(best, (r - length(d)) / r + (n - 0.5) * 1.1);
	}
	if (best < 0.0 && !(best > -0.7 && hash(p * 7.31) > 0.93)) {  // round the stain: flung specks
		discard;
	}
	ALBEDO = mix(vec3(0.24, 0.025, 0.02), vec3(0.07, 0.01, 0.008), smoothstep(0.0, 0.6, best));  // fresh rim, dried heart
	ALPHA = 0.92;
}
