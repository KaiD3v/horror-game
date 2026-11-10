# The game's clock: 1 real second = 1 game minute (a day lasts 24 real minutes). It keeps running across scenes (a
# static), only while a level with a DayCycle is playing (a pause, the notes, stop it). A new game starts it again.
class_name WorldTime

const SPEED := 1.0           # game minutes per real second
const START := 6 * 60 + 30   # a new game: 06:30, the morning fog

static var minutes := float(START)   # game minutes since midnight of the first day


static func reset(at := START) -> void:
	minutes = at


static func advance(game_minutes: float) -> void:
	minutes += game_minutes


static func minute_of_day() -> float:
	return fposmod(minutes, 1440.0)


static func hour() -> float:
	return minute_of_day() / 60.0


## Which part of the day it is (DayData.PERIODS): madrugada 00:00-05:59, manhã 06:00-11:59, tarde 12:00-17:59, noite 18:00-23:59.
static func period() -> Dictionary:
	return DayData.PERIODS[int(minute_of_day() / 360.0)]


## The game minute the current period began at (on the absolute clock).
static func period_start() -> float:
	return floorf(minutes / 360.0) * 360.0


static func clock() -> String:
	var m := int(minute_of_day())
	return "%02d:%02d" % [m / 60, m % 60]
