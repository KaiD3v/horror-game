# The trunks to find (Chest, models/props/bau.glb) and what each holds. id: one of a kind in the whole game (an opened
# trunk stays open); scene: the scene file's name; at: x and z (it is dropped onto whatever is below `from` m,
# default 30: indoors, start below the ceiling); yaw: degrees, 0 = its front to +z; item / qtd: what is inside
# (ItemCatalog); requires: an item that opens it (a key), optional, with `refusal` for when you do not have it.
# A new trunk = a new entry here. No code.
class_name ChestData

const CHESTS := [
	{"id": "facao_ruina", "scene": "vilarejo", "at": Vector2(-6.6, 37.6), "yaw": 90.0, "item": "facao"},  # at the ruin by the way in
	{"id": "garrafada_altar", "scene": "capela", "from": 2.2, "at": Vector2(2.6, -5.2), "yaw": -90.0, "item": "garrafada"},
]


static func in_scene(scene: String) -> Array:
	return CHESTS.filter(func(c): return c.scene == scene)
