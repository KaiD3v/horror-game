# Time and weather made visible in a level: each frame it runs the clock (WorldTime) and the weather (Weather), then
# lights the level by the hour (DayData.LIGHT, eased) with the weather on top. Outdoors it drives the environment
# (sky = fog colour, ambient, fog density), the sun / moon, the far shapes' haze and Clima (rain, mist banks,
# puddles). Indoors it drives the windows (their light and their panes) and the rain heard through the roof.
# Add one with DayCycle.outdoors() / DayCycle.indoors(); it says the period on the HUD when one begins.
class_name DayCycle
extends Node

signal period_changed(period: Dictionary)

var level: Level
var env: Environment
var sun: DirectionalLight3D
var haze: Array[ShaderMaterial] = []      # silhouettes: their "fog" (and "dark") follow the sky
var haze_dark: Array[Color] = []
var clima: Clima
var windows: Array[OmniLight3D] = []      # indoors: the daylight through the windows...
var window_energy: Array[float] = []
var panes: Array[BaseMaterial3D] = []     # ...and the panes themselves
var roof_rain: AudioStreamPlayer          # the rain on the roof, muffled
var now := {}                             # what was applied last (DayData.sample + fog colour): read by tests
var clear := 0.0                          # 0..1: how far the fog thins (up in the belfry, the fog lies below)


static func outdoors(lvl: Level, e: Environment, s: DirectionalLight3D, haze_mats: Array[ShaderMaterial], c: Clima) -> DayCycle:
	var d := DayCycle.new(); d.level = lvl; d.env = e; d.sun = s; d.clima = c
	for m in haze_mats:
		d.haze.append(m); d.haze_dark.append(m.get_shader_parameter("dark"))
	lvl.add_child(d)
	return d


static func indoors(lvl: Level, lights: Array[OmniLight3D], pane_mats: Array[BaseMaterial3D]) -> DayCycle:
	var d := DayCycle.new(); d.level = lvl
	for l in lights:
		d.windows.append(l); d.window_energy.append(l.light_energy)
	d.panes = pane_mats
	d.roof_rain = Audio.loop_player(d, "chuva")  # before it enters the tree: _ready lights the room at once
	lvl.add_child(d)
	return d


func _ready() -> void:
	period_changed.connect(func(p): level.hud.say("%s · %s" % [p.nome, WorldTime.clock()], 3.0))
	_step(0.0)
	(func(): level.hud.say("%s · %s" % [WorldTime.period().nome, WorldTime.clock()], 3.0)).call_deferred()


func _process(delta: float) -> void:
	_step(delta * WorldTime.SPEED)


## Moves time on by `game_minutes` (0: just light it as it is now).
func _step(game_minutes: float) -> void:
	var before: Dictionary = WorldTime.period()
	WorldTime.advance(game_minutes)
	Weather.update(game_minutes)
	if WorldTime.period().id != before.id:
		period_changed.emit(WorldTime.period())
	now = DayData.sample(WorldTime.hour())
	if env:
		_outdoors()
	else:
		_indoors()


func _outdoors() -> void:
	var k := now; var rain := Weather.rain; var fog := Weather.fog
	var sky: Color = k.fog
	sky = sky.lerp(sky.lightened(0.12), fog * k.day)  # fog by day: brighter, milkier
	sky = sky.darkened(0.18 * rain)                     # rain: a heavier, darker sky
	k["sky"] = sky
	env.background_color = sky; env.fog_light_color = sky
	env.fog_density = (0.028 + 0.047 * fog + 0.012 * rain) * (1.0 - 0.72 * clear)
	env.fog_height_density = (0.04 + 0.12 * fog) * (1.0 - 0.5 * clear)
	env.ambient_light_color = k.amb; env.ambient_light_energy = k.amb_e * (1.0 - 0.25 * rain)
	# one light for the sun and the moon: the sun's while it is up, the moon's at night
	var w: float = k.sun_e / maxf(k.sun_e + k.moon_e, 0.001)
	var h := WorldTime.hour()
	var sun_rot := Vector3(-maxf(8.0, 55.0 * sin(PI * clampf((h - 6.0) / 12.0, 0.0, 1.0))), -150.0 + (h - 12.0) * 12.0, 0.0)
	sun.rotation_degrees = DayData.MOON_ROT.lerp(sun_rot, w)
	sun.light_color = DayData.MOON_COLOR.lerp(k.sun, w)
	sun.light_energy = k.sun_e * (1.0 - 0.5 * fog) * (1.0 - 0.4 * rain) + k.moon_e * (1.0 - 0.5 * rain)
	for i in haze.size():
		haze[i].set_shader_parameter("fog", sky)
		haze[i].set_shader_parameter("dark", Color(minf(haze_dark[i].r, sky.r * 0.45), minf(haze_dark[i].g, sky.g * 0.45), minf(haze_dark[i].b, sky.b * 0.45)))
	if clima:
		clima.weather(rain, fog, Weather.wet, sky)


func _indoors() -> void:
	var d: float = now.day * (1.0 - 0.4 * Weather.rain)  # a grey, rainy day lets less in
	var light := Color(0.25, 0.3, 0.5).lerp(Color(0.62, 0.68, 0.78), now.day)   # night: a cold blue, day: grey
	for i in windows.size():
		windows[i].light_energy = window_energy[i] * (0.08 + 0.92 * d)
		windows[i].light_color = light
	for m in panes:
		m.albedo_color = Color(0.1, 0.12, 0.2).lerp(Color.WHITE, d)
	Audio.fade(roof_rain, Weather.rain, -22.0)
