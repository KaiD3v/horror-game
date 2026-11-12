# The crypt under the Moura mausoleum (../docs/CHAVE_DO_PORTAO.md; ../tools/cenarios/jazigo_build.py): the arena of the
# village's last fight. An interior (interior.gd) with O Porteiro (Porteiro) waiting by the coffin:
#   down the stair and onto the floor he wakes: a fall of stone shuts the stair behind you, his name and his health at
#   the top of the screen (bar), the fight's music if there is one (music/chefe.mp3);
#   phase 2 (up on the altar): a second box of bolts by the stair, if the first was taken;
#   phase 3: the candles go out one by one, the room nearly black: only your lantern;
#   his death: the stair opens, the candles come back, his ring of keys on the floor with the gate's key in it, and in the
#   doctor's coffin the ex-voto heart (the upgrade, FoundBanner). Story "morto:porteiro": after, the crypt stays quiet.
extends "res://scripts/levels/interior.gd"

const MUSIC := "chefe"        # music/chefe.mp3 ("Crypt Procession", cut to 1:55 so it loops without the tail of silence)
const MUSIC_DB := -14.0        # (a loud track: under it the keys must still be heard, they warn of the smash)

var candles: Array[OmniLight3D] = []
var boss: Porteiro
var shut: StaticBody3D          # the fallen stone across the stair's foot
var bar: Control
var bar_fill: ColorRect


func _build() -> void:
	super()
	for l in lights:
		candles.append(l)
	_bolts("jazigo_virotes")
	if Story.has("morto:porteiro"):
		_spoils()
		return
	var m: Node3D = room.get_node("porteiro")
	boss = Porteiro.new(); add_enemy(boss, m.position, m.rotation.y)
	var a: Node3D = room.get_node("altar")
	boss.altar = a.position; boss.below = a.position - Vector3(0, a.position.y, 0) + Vector3(0, 0, 2.4)
	boss.phase_changed.connect(_phase)
	boss.died.connect(_won)


func _bolts(id: String) -> void:  # a box of 6 bolts by the stair's foot
	var box: Node3D = room.get_node("virotes")
	var bolts := Pickup.make(self, box.position + Vector3(0.6 if id.ends_with("2") else 0.0, 0, 0), "virote", 6, id)
	if is_instance_valid(bolts) and not bolts.is_queued_for_deletion():
		Looks.box(bolts, Vector3(0, 0.15, 0), Vector3(0.5, 0.3, 0.35), Color(0.4, 0.3, 0.2))


func _physics_process(delta: float) -> void:
	super(delta)
	if boss and boss.phase == 0 and player and player.global_position.y < 0.5 and player.global_position.z < room.get_node("escada").position.z - 1.5:
		boss.wake()
	if bar and is_instance_valid(boss):
		bar_fill.size.x = 400.0 * float(boss.health) / Porteiro.HEALTH


func _phase(n: int) -> void:
	match n:
		1:
			_shut_stair(true)
			_bar()
			Audio.music_play(self, MUSIC, MUSIC_DB, 1.0, true)
		2:
			if Story.has("pego:jazigo_virotes"):
				_bolts("jazigo_virotes_2")
		3:
			for i in candles.size():  # out, one by one, round the room
				var c := candles[i]
				var tw := create_tween(); tw.tween_interval(0.25 * i); tw.tween_property(c, "light_energy", 0.0, 0.3)
			create_tween().tween_property(env, "ambient_light_energy", 0.02, 2.0)


func _shut_stair(on: bool) -> void:
	if on and shut == null:
		var foot: Node3D = room.get_node("escada")
		shut = Looks.box(self, foot.position + Vector3(0, 1.6, 0.4), Vector3(2.6, 3.2, 0.8), Looks.triplanar("stone", 1.0, Color(0.45, 0.43, 0.4)))
		Audio.play3d(self, "entulho_desabar", foot.position, 4.0, false, 6.0, 40.0)
	elif not on and shut:
		Audio.play3d(self, "entulho_desabar", shut.position, 2.0, false, 6.0, 40.0)
		shut.queue_free(); shut = null


func _bar() -> void:  # his name and his health, at the top
	var layer := CanvasLayer.new(); add_child(layer)
	bar = Control.new(); bar.anchor_left = 0.5; bar.anchor_right = 0.5  # (anchors before entering the tree)
	bar.offset_left = -200; bar.offset_right = 200; bar.offset_top = 24; bar.offset_bottom = 60; layer.add_child(bar)
	var name_l := Label.new(); bar.add_child(name_l); name_l.text = "O PORTEIRO"; name_l.position = Vector2(0, -4)
	name_l.add_theme_color_override("font_color", Color(0.86, 0.84, 0.78))
	var back := ColorRect.new(); bar.add_child(back); back.color = Color(0, 0, 0, 0.6); back.position = Vector2(0, 22); back.size = Vector2(400, 8)
	bar_fill = ColorRect.new(); bar.add_child(bar_fill); bar_fill.color = Color(0.62, 0.1, 0.06); bar_fill.position = Vector2(0, 22); bar_fill.size = Vector2(400, 8)


func _won() -> void:
	Story.mark("morto:porteiro")
	Audio.music_stop(4.0)
	if bar:
		var tw := create_tween(); tw.tween_interval(2.0); tw.tween_property(bar, "modulate:a", 0.0, 1.5)
	for c in candles:
		create_tween().tween_property(c, "light_energy", 0.9 * dim, 2.0)
	create_tween().tween_property(env, "ambient_light_energy", ambient, 2.0)
	await get_tree().create_timer(2.0).timeout
	_shut_stair(false)
	_spoils(boss.global_position)


## What he leaves: the ring of keys with the gate's key (the task done), the ex-voto heart in the coffin.
func _spoils(at := Vector3.INF) -> void:
	var where := at if at != Vector3.INF else (room.get_node("caixao") as Node3D).position + Vector3(0, 0, 2.4)
	var key := Pickup.make(self, Vector3(where.x, 0.02, where.z), "chave_portao", 1, "jazigo_chave")
	if is_instance_valid(key) and not key.is_queued_for_deletion():
		key.prompt = "E · pegar o molho de chaves"
		_shape(key, "chave")
		key.used.connect(func(_by):
			if Story.task("chave") == "ativa":
				Story.set_task("chave", "feita"); player.notice.emit("Tarefa cumprida: %s" % QuestData.title("chave")))
	var heart := Pickup.make(self, (room.get_node("caixao") as Node3D).position + Vector3(0, 0.16, 0), "coracao_exvoto", 1, "jazigo_coracao")
	if is_instance_valid(heart) and not heart.is_queued_for_deletion():
		heart.prompt = "E · pegar o que brilha no caixão"
		var glow := OmniLight3D.new(); heart.add_child(glow); glow.position.y = 0.3
		glow.light_color = Color(1.0, 0.8, 0.5); glow.light_energy = 0.8; glow.omni_range = 2.0
		_tin_heart(heart)
		heart.used.connect(func(_by): FoundBanner.open(self, "coracao_exvoto"))


func _tin_heart(p: Pickup) -> void:  # a beaten-tin ex-voto heart, standing on its point: a square on edge and two lobes
	var tin := StandardMaterial3D.new(); tin.albedo_color = Color(0.85, 0.72, 0.42); tin.metallic = 0.7; tin.roughness = 0.35
	var n := Node3D.new(); p.add_child(n); n.position.y = 0.2
	var sq := MeshInstance3D.new(); n.add_child(sq); var bm := BoxMesh.new(); bm.size = Vector3(0.16, 0.16, 0.03); bm.material = tin
	sq.mesh = bm; sq.rotation.z = PI / 4
	for sx in [-1.0, 1.0]:
		var lobe := MeshInstance3D.new(); n.add_child(lobe); var c := CylinderMesh.new()
		c.top_radius = 0.06; c.bottom_radius = 0.06; c.height = 0.03; c.material = tin; lobe.mesh = c
		lobe.rotation.x = PI / 2; lobe.position = Vector3(sx * 0.057, 0.057, 0)
	var spin := n.create_tween().set_loops(); spin.tween_property(n, "rotation:y", TAU, 4.0).from(0.0)


func _shape(p: Pickup, id: String) -> void:
	var all: Node = load(Paths.PROP % "itens").instantiate()
	var s: Node3D = all.find_child(id, false)
	if s == null:
		s = all.find_child("embrulho", false)
	all.remove_child(s); s.owner = null; all.free(); p.add_child(s)
