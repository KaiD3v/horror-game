# Going from one scene to another (Zelda-style doors, the menu's "Novo jogo"): fades to black, remembers which door
# you came out of (the next level puts you there) and what the next scene plays as it opens from black.
# Under --autotest nothing changes scene: the request is only recorded, for the test to check.
class_name SceneRouter

static var arriving := ""         # set on the way out of an interior: the village puts you at its porta_<arriving>
static var fade_in := false       # the next scene opens from black
static var fade_sound := "porta"  # ...and plays this (a door shutting behind you); "" = silence
static var requested := ""        # the last scene asked for (autotest)


static func testing() -> bool:
	return "--autotest" in OS.get_cmdline_user_args()


static func go_to(from: Node, scene: String, arrive := "", fade := 0.3, sound := "porta") -> void:
	arriving = arrive; requested = scene
	if testing():
		return
	var layer := CanvasLayer.new(); layer.layer = 100; from.add_child(layer)
	var black := ColorRect.new(); black.color = Color(0, 0, 0, 0); black.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(black)
	var tw := from.create_tween(); tw.tween_property(black, "color:a", 1.0, fade)
	await tw.finished
	fade_in = true; fade_sound = sound
	from.get_tree().change_scene_to_file(scene)


## Called by the scene that opens: whether to fade in from black, and with what sound (then back to the default).
static func take_arrival() -> Array:
	var r := [fade_in, fade_sound]
	fade_in = false; fade_sound = "porta"
	return r
