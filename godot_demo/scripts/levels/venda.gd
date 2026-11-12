# Seu Bento's shop (interior.gd), its radio and its cellar (../docs/CONTEUDO_VILAREJO.md):
#   the radio: E and he turns the dial himself (Sintonia); the radio's own sound (interior.gd `radio`) goes quiet meanwhile;
#   the counter's left end: scratched into the wood with a knife point, a heart, an O. and a number (Label3D): 0612,
#   Odete's number at the Colônia (the radio reads it too);
#   the iron trapdoor in the floor, a combination padlock on it (Segredo, 0612): open, down to the cellar (porao).
extends "res://scripts/levels/interior.gd"

const CODE := "0612"
const TRAPDOOR := Vector3(1.0, 0.0, 1.3)
const SCRATCH := Vector3(-2.9, 1.015, -0.78)

var dial: Interactable
var tuning: Sintonia
var lock: Interactable
var down: Door
var cracking: Segredo


func _build() -> void:
	super()
	var m: Node3D = room.get_node("som_musica_venda")
	dial = Interactable.new(); add_child(dial); dial.position = Vector3(m.position.x + 0.6, 0.0, m.position.z)
	dial.radius = 1.3; dial.height = 2.2; dial.prompt = "E · mexer no rádio"
	dial.used.connect(func(_by): tune())
	_scratch()
	_trapdoor()


func _player_start() -> Transform3D:  # up the ladder from the cellar: by the trapdoor
	if SceneRouter.arriving == "porao":
		return Transform3D(Basis(Vector3.UP, 0.0), TRAPDOOR + Vector3(0, 0.05, 0.9))
	return super()


func tune() -> Sintonia:
	if is_instance_valid(tuning):
		return tuning
	tuning = Sintonia.new(player); add_child(tuning)
	if radio:
		radio.stream_paused = true
	tuning.closed.connect(func():
		if radio:
			radio.stream_paused = false)
	return tuning


func _scratch() -> void:
	var l := Label3D.new(); add_child(l); l.position = SCRATCH; l.rotation.x = -PI / 2
	l.text = "♥ O.\n0612"; l.font_size = 22; l.pixel_size = 0.0025; l.modulate = Color(0.28, 0.2, 0.13, 0.85)
	l.outline_size = 0
	var look := Interactable.new(); add_child(look); look.position = Vector3(SCRATCH.x, 0.0, SCRATCH.z + 0.6)
	look.radius = 0.9; look.height = 2.0; look.prompt = "E · olhar o balcão"
	look.used.connect(func(_by):
		Story.mark("porao:numero")
		player.notice.emit("Riscado na madeira com a ponta de uma faca: um coração, um O. e um número. 0612."))


func _trapdoor() -> void:
	var iron := StandardMaterial3D.new(); iron.albedo_color = Color(0.22, 0.2, 0.18); iron.metallic = 0.6; iron.roughness = 0.6
	var plate := MeshInstance3D.new(); add_child(plate); var pm := BoxMesh.new(); pm.size = Vector3(0.9, 0.02, 0.7)
	pm.material = iron; plate.mesh = pm; plate.position = TRAPDOOR + Vector3(0, 0.01, 0)
	var brass := StandardMaterial3D.new(); brass.albedo_color = Color(0.7, 0.55, 0.25); brass.metallic = 0.8
	var pad := MeshInstance3D.new(); add_child(pad); var bm := BoxMesh.new(); bm.size = Vector3(0.12, 0.05, 0.08)
	bm.material = brass; pad.mesh = bm; pad.position = TRAPDOOR + Vector3(0, 0.035, 0.3)
	var spot := Node3D.new(); add_child(spot); spot.position = TRAPDOOR
	down = Door.make(spot, "E · descer ao porão", Paths.interior("porao"), "porao", 1.0)
	down.enabled = Story.has("aberta:porao")
	pad.visible = not down.enabled
	lock = Interactable.new(); add_child(lock); lock.position = TRAPDOOR; lock.radius = 1.0
	lock.prompt = "E · abrir o cadeado de segredo"; lock.enabled = not down.enabled
	lock.used.connect(func(_by): crack())
	lock.set_meta("pad", pad)


func crack() -> Segredo:
	if is_instance_valid(cracking):
		return cracking
	cracking = Segredo.new(player, CODE); add_child(cracking)
	cracking.opened.connect(func():
		Story.mark("aberta:porao"); down.enabled = true; lock.enabled = false
		(lock.get_meta("pad") as Node3D).visible = false
		player.notice.emit("O cadeado abre. Embaixo da tampa, uma escada de mão no escuro."))
	return cracking
