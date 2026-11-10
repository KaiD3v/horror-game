# Things that happen now and then (a crow, the dog far off, the bell): each one fires after a random wait, then
# again and again after other random waits. fire() makes one happen now (autotest).
class_name RandomEvents
extends Node

var _events := {}  # name -> {"every": Vector2 (seconds, min/max), "fn": Callable, "left": float}


func add(event: String, first: Vector2, every: Vector2, fn: Callable) -> void:
	_events[event] = {"every": every, "fn": fn, "left": randf_range(first.x, first.y)}


func fire(event: String) -> Variant:
	return _events[event].fn.call()


func _process(delta: float) -> void:
	for k in _events:
		var e: Dictionary = _events[k]
		e.left -= delta
		if e.left <= 0.0:
			e.fn.call()
			e.left = randf_range(e.every.x, e.every.y)
