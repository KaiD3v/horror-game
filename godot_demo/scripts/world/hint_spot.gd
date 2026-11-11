# A place that asks for a move (Hints, ../docs/TUTORIAL_VILAREJO.md): near it, while `needed` says he is not doing it
# yet (standing, for "agachar"), the line for that move. Gone once he has learned it.
class_name HintSpot
extends Node3D

var action := ""
var radius := 1.3
var needed: Callable          # (player) -> bool


static func make(parent: Node, at: Vector3, what: String, r: float, when: Callable) -> HintSpot:
	var h := HintSpot.new(); h.action = what; h.radius = r; h.needed = when; h.position = at
	parent.add_child(h)
	return h


func _process(_delta: float) -> void:
	if Hints.learned(action):
		queue_free()
		return
	var p := get_tree().get_first_node_in_group("player")
	if p and p.global_position.distance_to(global_position) < radius and needed.call(p):
		Hints.want(self, action)
