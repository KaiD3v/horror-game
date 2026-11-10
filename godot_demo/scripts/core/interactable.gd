# Something the player uses with E: a door, a paper to read, a bolt. Stand within `radius` (flat) and `height`
# (up/down) of it and the HUD shows its prompt; E calls use(). The level's Interactor picks the nearest one.
# Subclass and override _use(), or connect to `used`.
class_name Interactable
extends Node3D

signal used(by: Node3D)

@export var prompt := "E · usar"
@export var radius := 1.5
@export var height := 1.6
var enabled := true


func _ready() -> void:
	add_to_group("interactable")


## How far `p` stands from it, flat; INF when out of reach (or disabled).
func reach(p: Vector3) -> float:
	var d := global_position - p
	var flat := Vector2(d.x, d.z).length()
	return flat if enabled and flat < radius and absf(d.y) < height else INF


func use(by: Node3D) -> void:
	_use(by)
	used.emit(by)


func _use(_by: Node3D) -> void:
	pass
