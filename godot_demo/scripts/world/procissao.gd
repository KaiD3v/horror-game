# The procession (../docs/CONTEUDO_VILAREJO.md "A procissão"): the mourners, A Carpideira and four more like her, come
# down from the Colônia's gate one night with their candles, weeping, in a line, down the road, past the chapel, to the
# nameless grave: the boy Antero brought back from the river was one of theirs. Once O Porteiro is dead and Dona Firmina
# has told the grave's story (due()), from 21h; Firmina says so by day ("Hoje à noite elas descem").
#   Seen (each sees like A Carpideira, Carpideira.SEE: the lantern in hand far, standing in the dark near, crouched very
#   near; in front of her, a clear line) for NOTICE seconds: the leader screams (the night comes to it: vilarejo._alarm),
#   the candles go out, they are gone. They come again another night.
#   Unseen to the grave, with him near it (WITNESS): they kneel round it and mourn (MOURN s); the mother carves the
#   boy's name into the cross; they leave their candles burning on it and are gone (Story "procissao:vista").
#   They do not come after that. Not seen there, they mourn and go, and come again.
class_name Procissao
extends Node3D

signal ended(seen_through: bool)

const COUNT := 5
const GAP := 2.2              # m between them in the line
const SPEED := 0.8            # m/s, their slow walk (= Carpideira.speed)
const NOTICE := 1.2           # seconds of seeing him before the scream (= Carpideira.NOTICE)
const MOURN := 10.0
const WITNESS := 14.0         # how near the grave he must be when they kneel
const NAME := "BENEDITO\n1947 · 1958"

var level: Node3D
var player: Player
var path := PackedVector3Array()
var lengths: Array[float] = []    # distance along the path to each point
var total := 0.0
var lead := 0.0
var mourners: Array[Node3D] = []
var candles: Array[OmniLight3D] = []
var weeping: Array[AudioStreamPlayer3D] = []
var notice := 0.0
var phase := "walk"           # walk, mourn, gone
var mourn_t := 0.0
var grave := Vector3.ZERO


static func due() -> bool:
	return Story.has("morto:porteiro") and Story.has("tumulo:contou") and not Story.has("procissao:vista")


func _init(lv: Node3D, from: Vector3, to: Vector3) -> void:
	level = lv; player = lv.player; grave = to
	path = NavigationServer3D.map_get_path(lv.get_world_3d().navigation_map, from, to + Vector3(0, 0, 1.0), true)
	var s := 0.0
	for i in path.size():
		if i > 0:
			s += path[i].distance_to(path[i - 1])
		lengths.append(s)
	total = s


func _ready() -> void:
	for i in COUNT:
		var m := Node3D.new(); add_child(m)
		var model: Node3D = load(Paths.character("carpideira")).instantiate(); m.add_child(model); model.rotation.y = PI
		Looks.n64(model)
		var ap: AnimationPlayer = Nodes.find_first(model, "AnimationPlayer")
		ap.play("Walk", 0.2, SPEED / 0.78); ap.seek(randf() * 0.8, true)
		m.set_meta("ap", ap)
		var skel: Skeleton3D = Nodes.find_first(model, "Skeleton3D")
		var hand := BoneAttachment3D.new(); hand.bone_name = "hand.R"; skel.add_child(hand)
		var c := OmniLight3D.new(); hand.add_child(c)
		c.position = skel.get_bone_global_rest(skel.find_bone("hand.R")).affine_inverse() * Carpideira.FLAME
		c.light_color = Color(1.0, 0.7, 0.38); c.light_energy = 1.8; c.omni_range = 5.0
		candles.append(c)
		if i % 2 == 0:
			var w := Audio.play3d(m, "carpideira_choro", Vector3(0, 1.6, 0), -2.0, true, 5.0, 40.0); w.pitch_scale = 1.0 - 0.06 * i
			weeping.append(w)
		mourners.append(m)
	_place()


func at_distance(s: float) -> Vector3:
	s = clampf(s, 0.0, total)
	for i in range(1, path.size()):
		if lengths[i] >= s:
			var k := (s - lengths[i - 1]) / maxf(lengths[i] - lengths[i - 1], 0.001)
			return path[i - 1].lerp(path[i], k)
	return path[path.size() - 1] if path.size() > 0 else Vector3.ZERO


func _place() -> void:
	for i in mourners.size():
		var s := lead - GAP * i
		var p := at_distance(s); var ahead := at_distance(s + 0.6) - p; ahead.y = 0
		mourners[i].global_position = p
		mourners[i].visible = s > -0.5  # (still behind the gate: not out yet)
		if ahead.length() > 0.05:
			mourners[i].rotation.y = atan2(-ahead.x, -ahead.z)


func _physics_process(delta: float) -> void:
	for c in candles:
		c.light_energy = 1.8 + 0.25 * sin(Time.get_ticks_msec() * 0.013 + c.get_instance_id())
	match phase:
		"walk":
			lead += SPEED * delta
			_place()
			if _seen(delta):
				_scream(); return
			if lead - GAP * (COUNT - 1) >= total:
				_kneel()
		"mourn":
			mourn_t += delta
			if _seen(delta):
				_scream(); return
			if mourn_t >= MOURN:
				_finish()


## Any of them, seeing him like A Carpideira does, long enough.
func _seen(delta: float) -> bool:
	var sees := false
	for m in mourners:
		if m.visible and _sees(m):
			sees = true; break
	notice = notice + delta if sees else maxf(0.0, notice - 0.6 * delta)
	return notice >= NOTICE


func _sees(m: Node3D) -> bool:
	if player.mode == Player.Mode.DEAD:
		return false
	var to := player.global_position - m.global_position; var dist := to.length()
	var reach: float = Carpideira.SEE.lantern if player.holds_lantern() else (Carpideira.SEE.crouch if player.crouched else Carpideira.SEE.dark)
	if dist > reach or (-m.global_basis.z).dot(to.normalized()) < Carpideira.CONE:
		return false
	var q := PhysicsRayQueryParameters3D.create(m.global_position + Vector3(0, 1.6, 0), player.global_position + Vector3(0, 1.3, 0), 1, [player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _kneel() -> void:
	phase = "mourn"
	for i in mourners.size():
		var a := PI * (0.15 + 0.7 * float(i) / (COUNT - 1))  # a half ring round the grave's foot
		var p: Vector3 = level.ground(grave.x + cos(a) * 1.4, grave.z + sin(a) * 1.4 + 0.2)
		mourners[i].global_position = p
		var to := grave - p; mourners[i].rotation.y = atan2(-to.x, -to.z)
		(mourners[i].get_meta("ap") as AnimationPlayer).play("Idle", 0.5)
	Audio.play3d(self, "carpideira_crianca", grave + Vector3(0, 1.2, 0), 0.0, false, 6.0, 50.0)


func _scream() -> void:
	phase = "gone"
	Audio.play3d(self, "carpideira_grito", mourners[0].global_position + Vector3(0, 1.7, 0), 8.0, false, 12.0, 120.0)
	if level.has_method("_alarm"):
		level._alarm(player.global_position)
	Story.bump("procissao:vista_de_longe")
	player.notice.emit("Ela viu você. As velas se apagam todas de uma vez.")
	_leave(false)


func _finish() -> void:
	phase = "gone"
	var near := Vector2(player.global_position.x - grave.x, player.global_position.z - grave.z).length() < WITNESS
	if near:
		Story.mark("procissao:vista")
		player.notice.emit("Uma delas risca alguma coisa na cruz com a unha. Depois deixam as velas acesas e vão embora.")
	_leave(near)


func _leave(seen_through: bool) -> void:
	for w in weeping:
		w.stop()
	var tw := create_tween().set_parallel()
	for c in candles:
		tw.tween_property(c, "light_energy", 0.0, 0.6 if not seen_through else 3.0)
	tw.chain().tween_callback(func():
		ended.emit(seen_through)
		queue_free())
