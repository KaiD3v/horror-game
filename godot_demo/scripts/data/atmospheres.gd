# World environments (Looks.environment): background, ambient light, fog. One preset per kind of place.
class_name Atmospheres

const VILLAGE_FOG := Color(0.25, 0.27, 0.29)

const NIGHT := {  # the training room
	"bg": Color(0.01, 0.012, 0.02), "ambient": Color(0.35, 0.4, 0.55), "ambient_energy": 0.3,
	"fog": Color(0.02, 0.025, 0.035), "fog_density": 0.04}
const COLONIA := {  # night in the Colônia's yard
	"bg": Color(0.01, 0.012, 0.02), "ambient": Color(0.35, 0.4, 0.55), "ambient_energy": 0.3,
	"fog": Color(0.03, 0.035, 0.045), "fog_density": 0.06}
const VILLAGE := {  # late afternoon in the fog: the sky is the fog, mist lying in the bottom of the valley
	"bg": VILLAGE_FOG, "ambient": Color(0.6, 0.65, 0.72), "ambient_energy": 0.55,
	"fog": VILLAGE_FOG, "fog_density": 0.06, "fog_height": 1.5, "fog_height_density": 0.12}
const INTERIOR := {  # dust and smoke in a closed room (ambient_energy set per room)
	"bg": Color.BLACK, "ambient": Color(0.55, 0.48, 0.42), "ambient_energy": 0.28,
	"fog": Color(0.05, 0.04, 0.035), "fog_density": 0.03}

const MOON := [Vector3(-55, 160, 0), Color(0.5, 0.6, 0.9), 0.35]
const OVERCAST_SUN := [Vector3(-28, -150, 0), Color(0.8, 0.82, 0.9), 0.45]  # low, cold, behind the clouds
