# The weather, kept across scenes (statics) like the clock. At the start of each period it is planned from
# DayData.CHANCES: whether it rains some time in it (when, how long) and how foggy it gets (every morning: fog).
# What the world shows eases towards the plan, never snaps:
#   rain  0..1  sets in / stops over DayData.RAIN_EASE game minutes
#   fog   0..1  rolls in / lifts over DayData.FOG_EASE
#   wet   0..1  the ground: soaks while it rains, dries slowly after (the puddles)
class_name Weather

static var rain := 0.0
static var fog := 1.0
static var wet := 0.6             # it rained before you came
static var rain_from := -1.0      # the planned rain, on WorldTime's absolute clock
static var rain_until := -1.0
static var fog_goal := 1.0
static var forced := false        # a test (or a scripted moment) holds the weather where it set it
static var _planned := -1.0       # the period start the plan was made for


static func reset() -> void:
	rain = 0.0; fog = 1.0; wet = 0.6; rain_from = -1.0; rain_until = -1.0; fog_goal = 1.0
	forced = false; _planned = -1.0


## Hold the weather at these (tests, or a moment that needs it): no more planning until release().
static func force(rain_now: float, fog_now: float) -> void:
	forced = true; rain = rain_now; fog = fog_now; fog_goal = fog_now
	rain_from = WorldTime.minutes if rain_now > 0.0 else -1.0
	rain_until = WorldTime.minutes + (1e6 if rain_now > 0.0 else -1.0)


static func release() -> void:
	forced = false; _planned = -1.0


static func raining() -> bool:
	return WorldTime.minutes >= rain_from and WorldTime.minutes < rain_until


static func update(game_minutes: float) -> void:
	if not forced and WorldTime.period_start() != _planned:
		plan()
	var dm := game_minutes
	rain = move_toward(rain, 1.0 if raining() else 0.0, dm / DayData.RAIN_EASE)
	fog = move_toward(fog, fog_goal, dm / DayData.FOG_EASE)
	wet = move_toward(wet, 1.0 if rain > 0.3 else 0.0, dm / (20.0 if rain > 0.3 else DayData.DRY))


## Rolls the period that has just begun (a rain still falling from the last one runs its course).
static func plan() -> void:
	_planned = WorldTime.period_start()
	var p: Dictionary = WorldTime.period()
	var c: Dictionary = DayData.CHANCES[p.id]
	if not raining() and randf() < c.chuva:
		rain_from = _planned + randf_range(0.0, 300.0)
		rain_until = rain_from + randf_range(DayData.RAIN_SPELL.x, DayData.RAIN_SPELL.y)
	if p.id == "manha":
		fog_goal = 1.0
	else:
		fog_goal = randf_range(0.5, 1.0) if randf() < c.nevoa else randf_range(0.0, 0.15)
