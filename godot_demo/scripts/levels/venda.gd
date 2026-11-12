# Seu Bento's shop (interior.gd), and its radio (../docs/CONTEUDO_VILAREJO.md "A sintonia do rádio"): E at it and he turns
# the dial himself (Sintonia); the radio's own sound (interior.gd `radio`) goes quiet meanwhile.
extends "res://scripts/levels/interior.gd"

var dial: Interactable
var tuning: Sintonia


func _build() -> void:
	super()
	var m: Node3D = room.get_node("som_musica_venda")
	dial = Interactable.new(); add_child(dial); dial.position = Vector3(m.position.x + 0.6, 0.0, m.position.z)
	dial.radius = 1.3; dial.height = 2.2; dial.prompt = "E · mexer no rádio"
	dial.used.connect(func(_by): tune())


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
