# The opening's first two acts (../docs/INTRODUCAO.md), a scene of its own between the menu's "Novo jogo" and the
# village. Three small sets built here, apart, and one camera (Cutscene) cutting between them:
#   1955, the parlatório (Parlatorio), in sepia: a boy and his mother either side of the wire, their hands on it; "Eu
#        vou te buscar"; the nurse's bell, and he is pulled away.
#   1974, São Paulo, a boarding-house room in the rain: home from his night shift with his lantern, a letter under the
#        door (NotesData carta_mae); the tin under the bed: the 1959 notice of her death (obito) and her photo, the same
#        hand on its back (foto); the cutting on the wall: the isolation ended by law in 1962 (recorte). He blows the
#        lamp out and goes.
#   The night bus up to the serra.
# Then the village plays the arrival (Intro). Skipping here skips that too.
class_name Abertura
extends Node3D

const PARLATORIO := Vector3.ZERO
const PENSAO := Vector3(40, 0, 0)
const ONIBUS := Vector3(80, 0, 0)
const PAGES := {"carta_mae": 10.0, "obito": 7.0, "recorte": 8.0}  # s each page stays up (E turns it sooner)

var cs: Cutscene
var notes: NotesReader
var sepia: Environment
var child: Node3D
var mother: Node3D
var him: Node3D
var his_hand: Node3D
var her_hand: Node3D
var door: Node3D
var envelope: Node3D
var lamp: OmniLight3D
var lid: Node3D
var photo: Node3D
var passing: OmniLight3D      # the road's lights, going past the bus window
var sounds: Array[AudioStreamPlayer] = []
var hall: AudioStreamPlayer   # the parlatório's room tone


func _ready() -> void:
	GameInput.setup()  # (E to skip, or to turn a page)
	var we := WorldEnvironment.new(); add_child(we); we.environment = _env(false)
	sepia = _env(true)
	_parlatorio()
	_pensao()
	_onibus()
	notes = NotesReader.new(); add_child(notes)
	cs = Cutscene.new(self); add_child(cs)
	if SceneRouter.testing():
		AutoTest.attach(self)
	await cs.play([_year, _screen, _hands, _bell, _city, _home, _letter, _tin, _photo, _cutting, _lamp_out, _bus])
	_end()


# --- act 1: the parlatório, 1955 ----------------------------------------------------------------------------------
func _year() -> void:  # 1
	cs.cam.environment = sepia
	Audio.music_play(self, "abertura", -10.0)  # (../docs/INTRODUCAO.md "Música"; on to the village, faded out by Intro)
	hall = Audio.play2d(self, "ambiente_hospital", -14.0, true)
	cs.say("Colônia Santa Clara, 1955")
	await cs.wait(3.0)
	cs.say("")


func _screen() -> void:  # 2. the boy on the visitors' side, her beyond the wire, the window behind her
	var p := PARLATORIO
	cs.look(p + Vector3(-0.6, 1.25, 2.2), p + Vector3(0.5, 1.15, -0.6))
	cs.cam_tw().tween_property(cs.cam, "global_position", p + Vector3(-0.55, 1.2, 1.5), 5.0).set_trans(Tween.TRANS_SINE)
	cs.fade(0.0, 1.5)
	await cs.wait(4.5)


func _hands() -> void:  # 3. their hands meet on the wire; what she says
	var p := PARLATORIO
	mother.visible = false; child.visible = false  # (just the hands: their bodies would hide them)
	his_hand.visible = true; her_hand.visible = true
	cs.look(p + Vector3(1.1, 1.3, 0.32), p + Vector3(0.55, 1.2, 0.0))
	var t := cs.tw().set_parallel().set_trans(Tween.TRANS_SINE)
	t.tween_property(his_hand, "position:z", 0.035, 1.6)
	t.tween_property(her_hand, "position:z", -0.035, 2.0)
	await cs.wait(1.6)
	Audio.play2d(self, "tela_arame", -8.0)  # the wire gives under their hands
	await cs.wait(0.6)
	cs.say("— Eu vou te buscar.")
	await cs.wait(3.0)
	cs.say("")


func _bell() -> void:  # 4. the nurse's bell: visiting time is over, he is pulled away
	var p := PARLATORIO
	mother.visible = true; child.visible = true; his_hand.visible = false; her_hand.visible = false  # (the close-up's)
	cs.look(p + Vector3(-0.5, 1.3, 1.9), p + Vector3(0.5, 1.15, -0.4))  # back to the room: the two of them
	Audio.play2d(self, "sineta", -2.0)
	await cs.wait(0.9)
	cs.tw().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(child, "position:z", child.position.z + 1.6, 0.6)
	await cs.wait(2.2)
	cs.black.color.a = 1.0
	hall.stop()
	await cs.wait(1.2)


# --- act 2: São Paulo, 1974 ---------------------------------------------------------------------------------------
func _city() -> void:  # 5
	cs.cam.environment = null
	sounds.append(Audio.play2d(self, "chuva", -13.0, true))
	sounds.append(Audio.play2d(self, "cidade_madrugada", -12.0, true))
	sounds.append(Audio.play2d(self, "relogio", -16.0, true))
	cs.say("São Paulo, março de 1974")
	await cs.wait(3.0)
	cs.say("")


func _home() -> void:  # 6. back from the night shift, lantern in hand; the envelope under the door
	var p := PENSAO
	cs.look(p + Vector3(-1.6, 1.7, -2.0), p + Vector3(1.4, 0.9, 1.4))
	Audio.play2d(self, "chave_fechadura", -6.0)  # his key in the lock, then the door
	await cs.wait(1.4)
	Audio.play2d(self, "porta", -6.0)
	cs.tw().set_trans(Tween.TRANS_SINE).tween_property(door, "rotation:y", -1.6, 0.9)
	cs.fade(0.0, 1.0)
	await cs.wait(0.6)
	await _walk(p + Vector3(1.0, 0, 1.55), "Walk_Lantern")
	_clip("Crouch_Down_Free")
	await cs.wait(0.7)
	envelope.visible = false  # picked up
	await cs.wait(0.8)
	_clip("Idle_Lantern")
	await cs.wait(0.6)


func _letter() -> void:  # 7. her letter
	await _page("carta_mae")


func _tin() -> void:  # 8. the tin under the bed: the notice of her death, kept since 1959
	var p := PENSAO
	await _walk(p + Vector3(-0.75, 0, -0.75), "Walk_Lantern")
	_face(Vector3(-1, 0, 0))
	cs.look(p + Vector3(-0.4, 1.4, 0.6), p + Vector3(-1.3, 0.5, -0.75))
	_clip("Open_Chest")
	await cs.wait(0.9)
	Audio.play2d(self, "lata_abrir", -4.0)
	cs.tw().tween_property(lid, "rotation:z", -1.9, 0.5)
	await cs.wait(1.2)
	await _page("obito")


func _photo() -> void:  # 9. her photo; turned over, the same hand as the letter's
	var at := photo.global_position
	photo.visible = true
	cs.look(at + Vector3(0.0, 0.05, 0.32), at)
	var heart := Audio.play2d(self, "coracao", -10.0, true)
	await cs.wait(2.6)
	cs.tw().set_trans(Tween.TRANS_SINE).tween_property(photo, "rotation:y", photo.rotation.y + PI, 0.8)
	await cs.wait(0.6)
	Audio.play2d(self, "impacto_grave", -8.0)  # the same hand
	await cs.wait(3.2)
	heart.stop()


func _cutting() -> void:  # 10. the cutting pinned over the table, years old: the law ended it in 1962
	var p := PENSAO
	cs.look(p + Vector3(0.1, 1.5, -1.3), p + Vector3(0.6, 1.55, -2.5))
	await cs.wait(1.6)
	await _page("recorte")


func _lamp_out() -> void:  # 11. he blows the lamp out, and goes
	var p := PENSAO
	cs.look(p + Vector3(-1.5, 1.5, 1.8), p + Vector3(0.6, 0.9, -2.0))
	_put(p + Vector3(0.6, 0, -1.4), Vector3(0, 0, -1))
	_clip("Idle_Lantern")
	await cs.wait(1.2)
	Audio.play2d(self, "sopro", -6.0)
	cs.tw().tween_property(lamp, "light_energy", 0.0, 0.3)
	await cs.wait(0.8)
	await _walk(p + Vector3(1.6, 0, 1.6), "Walk_Lantern")
	Audio.play2d(self, "porta", -6.0)
	cs.fade(1.0, 0.6)
	await cs.wait(1.0)
	for s in sounds:
		s.stop()


func _bus() -> void:  # 12. the night bus up to the serra: his face at the window, the road's lights going by
	var p := ONIBUS
	_put(p + Vector3(-0.6, 0.22, 0.4), Vector3(-0.45, 0, -1))
	_clip("Crouch_Idle_Free")
	cs.look(p + Vector3(-2.1, 1.35, 0.9), p + Vector3(-0.6, 1.2, 0.35))
	sounds.append(Audio.play2d(self, "onibus", -6.0, true))
	var t := cs.tw().set_loops(6)
	t.tween_property(passing, "position:z", 6.0, 1.3).from(-6.0)
	t.tween_interval(0.4)
	cs.fade(0.0, 1.2)
	await cs.wait(6.0)
	cs.fade(1.0, 1.5)
	await cs.wait(1.6)


# --- the end, played or skipped: on to the village, where the arrival plays (or is skipped too) --------------------
func _end() -> void:
	for s in sounds:
		if is_instance_valid(s):
			s.stop()
	if notes.showing >= 0:
		notes.close()
	for id in Intro.NOTES:
		if id not in NotesReader.read:
			NotesReader.read.append(id)
	Intro.pending = true; Intro.skip_next = cs.skipped
	SceneRouter.go_to(self, Paths.VILAREJO, "", 1.0, "")


# --- the sets -----------------------------------------------------------------------------------------------------
func _parlatorio() -> void:  # 7 x 7 m, the screen across the middle; her side lit from a high window behind her
	var p := PARLATORIO
	_room(p, Vector3(7, 3, 7), Looks.triplanar("tiles"), Looks.triplanar("paint_green", 0.5), Looks.triplanar("plaster", 0.5))
	Parlatorio.build(self, p, 0.0, 6.8)
	var glow := StandardMaterial3D.new(); glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; glow.albedo_color = Color(1, 0.97, 0.88)
	_mesh(p + Vector3(0.3, 2.1, -3.44), Vector3(1.4, 1.0, 0.02), glow)  # the window
	var sun := SpotLight3D.new(); add_child(sun); sun.position = p + Vector3(0.3, 2.3, -3.2)
	sun.look_at_from_position(sun.position, p + Vector3(0.2, 0.6, 0.8)); sun.light_energy = 6.0; sun.spot_range = 9.0; sun.spot_angle = 35.0
	var room := OmniLight3D.new(); add_child(room); room.position = p + Vector3(-1.5, 2.4, 1.5); room.light_energy = 0.5; room.omni_range = 6.0
	mother = _puppet(Paths.character("npc_mae"), p + Vector3(0.5, 0, -0.75), Vector3(0, 0, 1), "Idle")  # (npcs/mae.py)
	child = _puppet(Paths.character("protagonista"), p + Vector3(0.45, 0, 0.62), Vector3(0, 0, -1), "Idle_Free", 0.62)
	his_hand = _hand(p + Vector3(0.55, 1.18, 0.32), 0.75, PI, _skin(child, "skin_hand"))  # (to the wire in _hands)
	her_hand = _hand(p + Vector3(0.56, 1.21, -0.3), 1.0, 0.0, _skin(mother, "mae_skin"))
	his_hand.visible = false; her_hand.visible = false  # only in the close-up (_hands): beside the bodies they float


func _pensao() -> void:  # 4 x 5 m, the door east, the bed west, the table and the window north
	var p := PENSAO
	var plaster := Looks.triplanar("plaster", 0.5, Color(0.78, 0.72, 0.62))
	_room(p, Vector3(4, 2.7, 5), Looks.triplanar("planks"), plaster, plaster, Vector2(1.6, 0.9))  # (the east wall: a door at z = 1.6, 0.9 wide)
	var wood := Looks.triplanar("planks", 1.5, Color(0.6, 0.45, 0.32))
	door = Node3D.new(); add_child(door); door.position = p + Vector3(1.95, 0, 1.15)  # hinged at its north edge
	Looks.box(door, Vector3(0, 1.0, 0.45), Vector3(0.05, 2.0, 0.88), wood)
	envelope = _mesh(p + Vector3(1.45, 0.01, 1.6), Vector3(0.22, 0.006, 0.12), Color(0.86, 0.82, 0.7))
	Looks.box(self, p + Vector3(-1.5, 0.22, 0.6), Vector3(0.9, 0.44, 1.9), wood)            # the bed
	_mesh(p + Vector3(-1.5, 0.5, 0.6), Vector3(0.84, 0.14, 1.84), Looks.triplanar("linen"))
	Looks.box(self, p + Vector3(-1.45, 0.25, -0.75), Vector3(0.45, 0.5, 0.45), wood)        # a crate by it
	var tin := StandardMaterial3D.new(); tin.albedo_color = Color(0.5, 0.16, 0.1); tin.metallic = 0.6; tin.roughness = 0.5
	_mesh(p + Vector3(-1.45, 0.54, -0.75), Vector3(0.28, 0.08, 0.2), tin)
	lid = Node3D.new(); add_child(lid); lid.position = p + Vector3(-1.31, 0.585, -0.75)  # hinged on its far edge
	_mesh(Vector3(-0.14, 0.006, 0), Vector3(0.29, 0.012, 0.21), tin, lid)
	Looks.box(self, p + Vector3(0.6, 0.38, -2.15), Vector3(0.9, 0.76, 0.6), wood)           # the table
	_mesh(p + Vector3(0.6, 0.86, -2.2), Vector3(0.1, 0.2, 0.1), Color(0.75, 0.6, 0.3))    # the lamp on it
	lamp = OmniLight3D.new(); add_child(lamp); lamp.position = p + Vector3(0.6, 1.05, -2.1)
	lamp.light_color = Color(1.0, 0.72, 0.42); lamp.light_energy = 1.6; lamp.omni_range = 6.0
	_mesh(p + Vector3(0.6, 1.55, -2.44), Vector3(0.26, 0.34, 0.01), Color(0.92, 0.9, 0.82))  # the cutting: newsprint,
	_mesh(p + Vector3(0.6, 1.67, -2.434), Vector3(0.2, 0.035, 0.002), Color(0.1, 0.1, 0.1))  # its headline, its columns
	for i in 6:
		for c in [-0.06, 0.06]:
			_mesh(p + Vector3(0.6 + c, 1.6 - i * 0.035, -2.434), Vector3(0.1, 0.012, 0.002), Color(0.35, 0.35, 0.35))
	var night := StandardMaterial3D.new(); night.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; night.albedo_color = Color(0.08, 0.1, 0.16)
	_mesh(p + Vector3(-1.0, 1.6, -2.44), Vector3(0.8, 0.9, 0.02), night)                       # the window, the rainy night
	var out := OmniLight3D.new(); add_child(out); out.position = p + Vector3(-1.0, 1.6, -2.2)
	out.light_color = Color(0.5, 0.6, 0.9); out.light_energy = 0.4; out.omni_range = 3.0
	him = _puppet(Paths.character("protagonista"), p + Vector3(2.6, 0, 1.55), Vector3(-1, 0, 0), "Walk_Lantern")
	photo = _photo_card(p + Vector3(-1.38, 0.78, -0.62)); photo.visible = false  # (out of the tin in _photo)


func _onibus() -> void:  # inside a bus at night: seats, his window open to the camera, the road's lights passing
	var p := ONIBUS
	var dark := Looks.triplanar("painted_wood", 1.5, Color(0.35, 0.33, 0.32))
	Looks.box(self, p + Vector3(0, -0.05, 0), Vector3(2.4, 0.1, 9), dark)
	Looks.box(self, p + Vector3(0, 2.25, 0), Vector3(2.4, 0.1, 9), dark)
	Looks.box(self, p + Vector3(1.2, 1.1, 0), Vector3(0.08, 2.2, 9), dark)
	Looks.box(self, p + Vector3(-1.2, 0.5, 0), Vector3(0.08, 1.0, 9), dark)                 # below the windows
	Looks.box(self, p + Vector3(-1.2, 2.05, 0), Vector3(0.08, 0.3, 9), dark)                # above them
	for z in [-3.6, -2.0, 1.4, 3.0]:                                                          # pillars between them
		Looks.box(self, p + Vector3(-1.2, 1.4, z), Vector3(0.08, 0.9, 0.12), dark)
	var seat := Looks.triplanar("linen", 1.0, Color(0.35, 0.3, 0.45))
	for z in [-3.2, -2.3, -1.4, -0.5, 0.4, 1.3, 2.2, 3.1]:
		for x in [-0.6, 0.6]:
			Looks.box(self, p + Vector3(x, 0.4, z), Vector3(0.85, 0.12, 0.5), seat)
			Looks.box(self, p + Vector3(x, 0.75, z + 0.27), Vector3(0.85, 0.75, 0.1), seat)
	var inside := OmniLight3D.new(); add_child(inside); inside.position = p + Vector3(0, 2.0, 0)
	inside.light_color = Color(0.45, 0.55, 0.85); inside.light_energy = 0.35; inside.omni_range = 6.0
	passing = OmniLight3D.new(); add_child(passing); passing.position = p + Vector3(-2.6, 1.7, -6.0)
	passing.light_color = Color(1.0, 0.8, 0.5); passing.light_energy = 3.0; passing.omni_range = 4.5


# --- pieces -------------------------------------------------------------------------------------------------------
## A box room centred on p (size x, height, z): floor, ceiling, four walls (the lower 1.2 m in `low`); `gap` = a door
## (z, width) in its east wall.
func _room(p: Vector3, s: Vector3, floor: Material, low: Material, up: Material, gap := Vector2.ZERO) -> void:
	Looks.box(self, p + Vector3(0, -0.05, 0), Vector3(s.x, 0.1, s.z), floor)
	Looks.box(self, p + Vector3(0, s.y + 0.05, 0), Vector3(s.x, 0.1, s.z), up)
	for side in [[Vector3(0, 0, -s.z / 2), Vector3(s.x, 0, 0.1)], [Vector3(0, 0, s.z / 2), Vector3(s.x, 0, 0.1)],
			[Vector3(-s.x / 2, 0, 0), Vector3(0.1, 0, s.z)]]:
		_wall(p + side[0], side[1], s.y, low, up)
	if gap == Vector2.ZERO:
		_wall(p + Vector3(s.x / 2, 0, 0), Vector3(0.1, 0, s.z), s.y, low, up)
	else:  # either side of the doorway, and over it
		var a := -s.z / 2; var b := gap.x - gap.y / 2; var c := gap.x + gap.y / 2; var d := s.z / 2
		_wall(p + Vector3(s.x / 2, 0, (a + b) / 2), Vector3(0.1, 0, b - a), s.y, low, up)
		_wall(p + Vector3(s.x / 2, 0, (c + d) / 2), Vector3(0.1, 0, d - c), s.y, low, up)
		Looks.box(self, p + Vector3(s.x / 2, (2.0 + s.y) / 2, gap.x), Vector3(0.1, s.y - 2.0, gap.y), up)


func _wall(at: Vector3, size: Vector3, h: float, low: Material, up: Material) -> void:
	Looks.box(self, at + Vector3(0, 0.6, 0), Vector3(size.x, 1.2, size.z), low)
	Looks.box(self, at + Vector3(0, (1.2 + h) / 2, 0), Vector3(size.x, h - 1.2, size.z), up)


func _mesh(at: Vector3, size: Vector3, look: Variant, parent: Node = self) -> MeshInstance3D:  # no collision
	var mi := MeshInstance3D.new(); parent.add_child(mi); mi.position = at
	var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	if look is Material:
		bm.material = look
	else:
		var m := StandardMaterial3D.new(); m.albedo_color = look; bm.material = m
	return mi


## A person from the game's models, facing `dir`, playing `clip` (scaled: the boy is the man at 0.62).
func _puppet(file: String, at: Vector3, dir: Vector3, clip: String, s := 1.0) -> Node3D:
	var root := Node3D.new(); add_child(root); root.position = at; root.scale = Vector3.ONE * s
	var m: Node3D = load(file).instantiate(); root.add_child(m); m.rotation.y = PI  # glTF faces +Z; this, -Z
	root.rotation.y = atan2(-dir.x, -dir.z)
	(Nodes.find_first(root, "AnimationPlayer") as AnimationPlayer).play(clip)
	return root


## A hand for the close-up on the wire, blocky like everything else (palm, four fingers, a thumb), in its owner's
## skin (the model's own material); its palm facing -z, turned by yaw.
func _hand(at: Vector3, s: float, yaw: float, mat: Material) -> Node3D:
	var h := Node3D.new(); add_child(h); h.position = at; h.rotation.y = yaw; h.scale = Vector3.ONE * s
	var skin: Variant = mat if mat else Color(0.72, 0.55, 0.43)
	_mesh(Vector3.ZERO, Vector3(0.085, 0.09, 0.03), skin, h)
	for i in 4:
		_mesh(Vector3(-0.03 + 0.02 * i, 0.075 - 0.004 * absf(i - 1.5), 0), Vector3(0.017, 0.07 - 0.008 * absf(i - 1.5), 0.022), skin, h)
	_mesh(Vector3(0.055, 0.0, 0.006), Vector3(0.02, 0.05, 0.02), skin, h).rotation.z = -0.6
	return h


## Her photo (a 3x4, face up on the opened tin, its back up after _photo turns it): the front shows her, from the
## parlatório set through a little camera of its own; the back, in her hand, what she wrote.
func _photo_card(at: Vector3) -> Node3D:
	var card := Node3D.new(); add_child(card); card.position = at
	var sv := SubViewport.new(); add_child(sv); sv.size = Vector2i(72, 96)
	var pc := Camera3D.new(); sv.add_child(pc); pc.environment = sepia; pc.fov = 30.0
	pc.fov = 24.0; pc.position = PARLATORIO + Vector3(0.5, 1.4, -0.05); pc.look_at(PARLATORIO + Vector3(0.5, 1.42, -0.75))
	var front := MeshInstance3D.new(); card.add_child(front); var q := QuadMesh.new(); q.size = Vector2(0.075, 0.1)
	var fm := StandardMaterial3D.new(); fm.albedo_texture = sv.get_texture(); fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q.material = fm; front.mesh = q
	var paper := StandardMaterial3D.new(); paper.albedo_color = Color(0.86, 0.82, 0.7); paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh(Vector3(0, 0, -0.002), Vector3(0.08, 0.105, 0.002), paper, card)  # the paper, its back
	var words := Label3D.new(); card.add_child(words); words.text = "Pro meu menino.\nTua mãe, 1955."
	words.position.z = -0.0035; words.rotation.y = PI; words.pixel_size = 0.00022; words.font_size = 48
	words.modulate = Color(0.13, 0.12, 0.2); words.outline_size = 0
	return card


func _skin(who: Node3D, mat: String) -> Material:  # a surface material of a puppet, by name (its skin)
	for mi: MeshInstance3D in who.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i)
			if m and m.resource_name == mat:
				return m
	return null


func _put(at: Vector3, dir: Vector3) -> void:
	him.position = at; _face(dir)


func _face(dir: Vector3) -> void:
	him.rotation.y = atan2(-dir.x, -dir.z)


func _clip(n: String) -> void:
	(Nodes.find_first(him, "AnimationPlayer") as AnimationPlayer).play(n)


## Walk him to `to` (on the floor) at walk pace, playing `clip`; back when there (or skipped).
func _walk(to: Vector3, clip: String) -> void:
	var d := to - him.position; d.y = 0
	if d.length() < 0.05:
		return
	_face(d); _clip(clip)
	var s := d.length() / Player.WALK_SPEED
	var t := cs.tw(); t.tween_property(him, "position", Vector3(to.x, him.position.y, to.z), s)
	var steps := cs.tw().set_loops(maxi(1, int(s / 0.55)))  # his steps on the boards
	steps.tween_callback(func(): Audio.play2d(self, "passo_madeira", -14.0)); steps.tween_interval(0.55)
	await cs.wait(s)
	steps.kill()
	_clip("Idle_Lantern")


## A page up (NotesReader, paused under it), for its PAGES seconds or until E turns it.
func _page(id: String) -> void:
	Audio.play2d(self, "papel_desdobrar", -4.0)
	notes.take(id)
	var t0 := Time.get_ticks_msec()
	while notes.showing >= 0 and Time.get_ticks_msec() - t0 < PAGES[id] * 1000.0 and not cs.skipped:
		await get_tree().process_frame
	if notes.showing >= 0:
		notes.close()


static func _env(old: bool) -> Environment:  # the present: dim, cold; the past (old): sepia, a little bright
	var e := Environment.new(); e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.045, 0.04) if old else Color(0.02, 0.025, 0.035)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.5, 0.45) if old else Color(0.3, 0.33, 0.42)
	e.ambient_light_energy = 0.7 if old else 0.35
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if old:
		e.adjustment_enabled = true; e.adjustment_saturation = 0.0; e.adjustment_contrast = 1.1
		var g := Gradient.new(); g.set_color(0, Color(0.06, 0.04, 0.02)); g.set_color(1, Color(1.0, 0.93, 0.78))
		g.add_point(0.5, Color(0.56, 0.43, 0.29))
		var gt := GradientTexture1D.new(); gt.gradient = g; e.adjustment_color_correction = gt
	return e
