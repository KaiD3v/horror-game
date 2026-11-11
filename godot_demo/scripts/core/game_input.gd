# The game's input actions (keyboard and mouse), registered once.
class_name GameInput

const KEYS := {"forward": [KEY_W, KEY_UP], "back": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT],
	"right": [KEY_D, KEY_RIGHT], "sprint": [KEY_SHIFT], "walk": [KEY_CTRL], "draw": [KEY_1], "crossbow": [KEY_2], "lantern": [KEY_3],
	"dodge": [KEY_SPACE], "crouch": [KEY_C], "weapons": [KEY_Q], "interact": [KEY_E], "debug_hurt": [KEY_H],
	"reload": [KEY_R], "notes": [KEY_TAB], "debug_time": [KEY_T], "heal": [KEY_F]}
const BUTTONS := {"attack": MOUSE_BUTTON_LEFT, "block": MOUSE_BUTTON_RIGHT}


static func setup() -> void:
	for a in KEYS:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
			for k in KEYS[a]:
				var e := InputEventKey.new(); e.physical_keycode = k; InputMap.action_add_event(a, e)
	for a in BUTTONS:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
			var e := InputEventMouseButton.new(); e.button_index = BUTTONS[a]; InputMap.action_add_event(a, e)
