# The player's side of Interactable: each frame finds the nearest one in reach, shows its prompt on the HUD, and on
# E uses it, unless E went to locking on an enemy (Player.toggle_lock, weapon out). One per level (Level adds it).
class_name Interactor
extends Node

var player: Node3D
var hud: Hud
var current: Interactable


func _init(p: Node3D, h: Hud) -> void:
	player = p; hud = h


func _process(_delta: float) -> void:
	current = nearest()
	hud.set_prompt(current.prompt if current else "")


func nearest() -> Interactable:
	var best: Interactable = null; var best_d := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		var d: float = n.reach(player.global_position)
		if d < best_d:
			best = n; best_d = d
	return best


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") and player.get("mode") != Player.Mode.DEAD:
		if player is Player and player.toggle_lock():  # armed, E locks on an enemy first
			get_viewport().set_input_as_handled()
			return
		var it := nearest()
		if it:
			it.use(player)
			get_viewport().set_input_as_handled()
