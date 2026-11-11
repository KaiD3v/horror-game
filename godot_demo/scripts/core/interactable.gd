# Something the player uses with E: a door, a paper to read, a bolt. Stand within `radius` (flat) and `height`
# (up/down) of it and the HUD shows its prompt; E calls use(). The level's Interactor picks the nearest one.
# Subclass and override _use(), or connect to `used`. `requires` (an ItemCatalog id) locks it: without that item E
# only says `refusal` (a door that needs a key, a well that needs a rope). A key (tipo "chave") is spent on its lock
# the first time, which then stays open (Story "destrancado:<key>", saved with the game); a tool is only shown.
class_name Interactable
extends Node3D

signal used(by: Node3D)

@export var prompt := "E · usar"
@export var radius := 1.5
@export var height := 1.6
@export var requires := ""
@export var refusal := ""   # "" = "Precisa de: <item>."
@export var key := "interact"   # the action that uses it (Jumpable: "dodge", Space)
var enabled := true


func _ready() -> void:
	add_to_group("interactable")


## How far `p` stands from it, flat; INF when out of reach (or disabled).
func reach(p: Vector3) -> float:
	var d := global_position - p
	var flat := Vector2(d.x, d.z).length()
	return flat if enabled and flat < radius and absf(d.y) < height else INF


## Whether nothing stops it: no lock, the item it needs on him, or (a key's lock) opened before.
func unlocked() -> bool:
	return Inventory.has(requires) or Story.has("destrancado:" + requires)


func use(by: Node3D) -> void:
	if not unlocked():
		if by is Player:
			by.notice.emit(refusal if refusal != "" else "Precisa de: %s." % ItemCatalog.item(requires).nome)
		return
	if ItemCatalog.key(requires) and not Story.has("destrancado:" + requires):  # the key stays in the lock
		Inventory.take(requires); Story.mark("destrancado:" + requires)
		if by is Player:
			by.notice.emit("Usou: %s." % ItemCatalog.item(requires).nome)
	_use(by)
	used.emit(by)


func _use(_by: Node3D) -> void:
	pass
