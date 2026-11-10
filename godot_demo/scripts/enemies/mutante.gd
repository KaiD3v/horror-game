# O Interno, the mutant (models/characters/monster.glb): idles until it sees the player, screams, lurches after them
# along the navmesh and swings its bone blade. Grunts while it roams, heavy bare feet.
class_name Mutante
extends Enemy

const SIGHT := 8.0  # metres; needs a clear line of sight too


func _init() -> void:
	model_name = "monster"; max_health = 6  # machete: slash 1, overhead 2; bolt 3
	speed = 1.45; stride = 1.28              # the player escapes only by sprinting (2.6)
	voice = {"idle": "mutante_grunhido", "alert": "mutante_grito", "attack": "mutante_ataque", "hurt": "mutante_dor",
		"death": "mutante_morte", "step": "mutante_passo"}


func _decide(to: Vector3, dist: float, delta: float) -> void:
	match state:
		State.IDLE:
			if dist < SIGHT and _clear_line(global_position + Vector3(0, 1.9, 0)):
				go(State.ALERT, "Alert")
		State.ALERT:
			_face(to, delta)
			if t >= ap.get_animation("Alert").length:
				go(State.CHASE, "Walk", 0.3)
		State.CHASE:
			_face(to if dist < 2.0 else _route(target.global_position, to), delta)
			if dist <= attack_range and cooldown == 0.0:
				go(State.ATTACK, "Attack", 0.15)
			elif dist > attack_range:
				walk_forward()
