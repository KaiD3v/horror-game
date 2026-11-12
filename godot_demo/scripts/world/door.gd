# A door between scenes, Zelda style: E takes you to `scene`; `arrive` names the door you come out of there (the
# village puts you back at its porta_<arrive> marker).
# Shut by the hour (`shut`: from, to, wrapping midnight; the routines, ../docs/CONTEUDO_VILAREJO.md): E knocks
# instead, and `answer` comes back through the boards; with `lets_in` they open after it.
class_name Door
extends Interactable

const KNOCK := "E · bater na porta"

var scene := ""
var arrive := ""
var shut := Vector2(-1, -1)
var answer := ""
var lets_in := false
var open_prompt := ""
var knocking := false


static func make(at: Node3D, text: String, to_scene: String, arrive_at := "", r := 1.8) -> Door:
	var d := Door.new(); d.prompt = text; d.open_prompt = text; d.scene = to_scene; d.arrive = arrive_at; d.radius = r
	at.add_child(d)  # on the marker: it stands where the marker does
	return d


## Shut between these hours: knock, hear `said`; `let_in`: then in.
func hours(from: float, to: float, said: String, let_in := false) -> Door:
	shut = Vector2(from, to); answer = said; lets_in = let_in
	return self


func is_shut() -> bool:
	if shut.x < 0:
		return false
	var h := WorldTime.hour()
	return (h >= shut.x or h < shut.y) if shut.x > shut.y else (h >= shut.x and h < shut.y)


func _process(_d: float) -> void:
	if shut.x >= 0:
		prompt = KNOCK if is_shut() else open_prompt


func _use(by: Node3D) -> void:
	if not is_shut():
		SceneRouter.go_to(self, scene, arrive)
		return
	if knocking:
		return
	knocking = true
	Audio.play3d(self, "bater_porta", Vector3(0, 1.4, 0), 0.0, false, 3.0, 25.0)
	await get_tree().create_timer(1.0).timeout
	if by is Player:
		by.notice.emit(answer)
	if lets_in:
		await get_tree().create_timer(1.2).timeout
		SceneRouter.go_to(self, scene, arrive)
	knocking = false
