# The day and its weather, as data (WorldTime, Weather, DayCycle use it):
#   PERIODS   the four parts of the day, six hours each
#   CHANCES   per period: the chance it rains (some time in it) and the chance of fog; every morning is foggy
#   LIGHT     the light at the hours of the day, eased between: the sky/fog colour, the ambient, the sun and the moon
# Changing how the day looks or how often it rains = changing these numbers.
class_name DayData

const PERIODS := [  # by the hour they start at: 0, 6, 12, 18
	{"id": "madrugada", "nome": "Madrugada"}, {"id": "manha", "nome": "Manhã"},
	{"id": "tarde", "nome": "Tarde"}, {"id": "noite", "nome": "Noite"}]
const CHANCES := {
	"madrugada": {"chuva": 0.25, "nevoa": 0.6},
	"manha": {"chuva": 0.25, "nevoa": 1.0},    # every morning: fog
	"tarde": {"chuva": 0.35, "nevoa": 0.3},
	"noite": {"chuva": 0.3, "nevoa": 0.45}}
const RAIN_SPELL := Vector2(40, 180)   # game minutes a rain lasts
const RAIN_EASE := 12.0                # game minutes for a rain to set in or stop
const FOG_EASE := 45.0                 # ...and for the fog to roll in or lift
const VOZ_DO_BRASIL := Vector2(19, 20)  # the hour every radio had to carry the government's programme: Bento's too
const DRY := 240.0                     # game minutes for the puddles to dry after the rain (they soak in 20)

# hour: fog/sky colour, ambient colour and energy, sun colour and energy, moon energy (the moon is cold and dim)
const LIGHT := [
	[0.0, {"fog": Color(0.035, 0.04, 0.055), "amb": Color(0.25, 0.3, 0.45), "amb_e": 0.14, "sun": Color(1, 0.6, 0.45), "sun_e": 0.0, "moon_e": 0.15}],
	[4.5, {"fog": Color(0.035, 0.04, 0.055), "amb": Color(0.25, 0.3, 0.45), "amb_e": 0.14, "sun": Color(1, 0.6, 0.45), "sun_e": 0.0, "moon_e": 0.14}],
	[5.5, {"fog": Color(0.12, 0.12, 0.16), "amb": Color(0.4, 0.4, 0.55), "amb_e": 0.3, "sun": Color(1, 0.6, 0.45), "sun_e": 0.05, "moon_e": 0.1}],
	[6.5, {"fog": Color(0.42, 0.38, 0.38), "amb": Color(0.75, 0.68, 0.65), "amb_e": 0.5, "sun": Color(1, 0.75, 0.6), "sun_e": 0.35, "moon_e": 0.0}],   # dawn
	[9.0, {"fog": Color(0.4, 0.42, 0.43), "amb": Color(0.68, 0.7, 0.75), "amb_e": 0.6, "sun": Color(0.95, 0.92, 0.88), "sun_e": 0.5, "moon_e": 0.0}],
	[13.0, {"fog": Color(0.36, 0.38, 0.4), "amb": Color(0.65, 0.68, 0.72), "amb_e": 0.65, "sun": Color(0.9, 0.9, 0.92), "sun_e": 0.55, "moon_e": 0.0}],
	[16.5, {"fog": Color(0.25, 0.27, 0.29), "amb": Color(0.6, 0.65, 0.72), "amb_e": 0.55, "sun": Color(0.8, 0.82, 0.9), "sun_e": 0.45, "moon_e": 0.0}],  # late afternoon
	[18.0, {"fog": Color(0.22, 0.17, 0.16), "amb": Color(0.55, 0.45, 0.45), "amb_e": 0.4, "sun": Color(1, 0.55, 0.35), "sun_e": 0.25, "moon_e": 0.0}],   # dusk
	[19.5, {"fog": Color(0.06, 0.065, 0.085), "amb": Color(0.3, 0.33, 0.48), "amb_e": 0.22, "sun": Color(1, 0.55, 0.35), "sun_e": 0.0, "moon_e": 0.15}],
	[23.0, {"fog": Color(0.035, 0.04, 0.055), "amb": Color(0.25, 0.3, 0.45), "amb_e": 0.14, "sun": Color(1, 0.6, 0.45), "sun_e": 0.0, "moon_e": 0.15}]]
const MOON_COLOR := Color(0.5, 0.6, 0.9)
const MOON_ROT := Vector3(-55, 160, 0)
const FULL_SUN := 0.55                 # sun_e at noon: daylight = sun_e / FULL_SUN


## The light at `hour` (0..24), eased between the two LIGHT rows round it; `day` = how much daylight (0 night .. 1).
static func sample(hour: float) -> Dictionary:
	var i := 0
	while i + 1 < LIGHT.size() and LIGHT[i + 1][0] <= hour:
		i += 1
	var a: Array = LIGHT[i]; var b: Array = LIGHT[(i + 1) % LIGHT.size()]
	var span: float = fposmod(b[0] - a[0], 24.0)
	var t := smoothstep(0.0, 1.0, fposmod(hour - a[0], 24.0) / span) if span > 0.0 else 0.0
	var out := {}
	for k in a[1]:
		out[k] = lerp(a[1][k], b[1][k], t)
	out["day"] = clampf(out.sun_e / FULL_SUN, 0.0, 1.0)
	return out


## What Bento's radio plays at `hour`: the Voz do Brasil in its hour, music otherwise.
static func radio(hour: float) -> String:
	return "voz_do_brasil" if hour >= VOZ_DO_BRASIL.x and hour < VOZ_DO_BRASIL.y else "musica_venda"
