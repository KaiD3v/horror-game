# Sound helpers (../tools/sons -> res://sounds): one-shots and loops, 2D or placed in the world, and loops that fade.
class_name Audio

static var heard: Array[String] = []   # what has played (autotest): the names as asked for
static var _takes := {}                # name -> how many takes <name>_1.._N there are (0: just <name>.wav)


## The file for a sound name: <name>.wav, or one of its takes <name>_1, _2... at random (so a blow never sounds
## twice the same).
static func pick(n: String) -> String:
	if not _takes.has(n):
		var k := 0
		while ResourceLoader.exists(Paths.SOUND % ("%s_%d" % [n, k + 1])):
			k += 1
		_takes[n] = k
	return n if _takes[n] == 0 else "%s_%d" % [n, randi_range(1, _takes[n])]


static func sfx(n: String, loop := false) -> AudioStreamWAV:
	if SceneRouter.testing():
		heard.append(n)
	var s: AudioStreamWAV = load(Paths.SOUND % pick(n))
	if loop and s.loop_mode == AudioStreamWAV.LOOP_DISABLED:  # the loops are cut seamless by the sound tools
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD; s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
	return s


static func play2d(parent: Node, n: String, db := 0.0, loop := false) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new(); p.stream = sfx(n, loop); p.volume_db = db; _keep(p, loop); parent.add_child(p); p.play()
	if not loop:
		p.finished.connect(p.queue_free)
	return p


static func play3d(parent: Node, n: String, at: Vector3, db := 0.0, loop := false, size := 3.0, far := 40.0) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new(); p.stream = sfx(n, loop); p.volume_db = db
	p.unit_size = size; p.max_distance = far; p.position = at; _keep(p, loop); parent.add_child(p); p.play()
	if not loop:
		p.finished.connect(p.queue_free)
	return p


## A looping 2D player, stopped: drive it with fade().
static func loop_player(parent: Node, n: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new(); p.stream = sfx(n, true); parent.add_child(p)
	return p


## amp 0..1 over a base volume: plays (from a random point) while amp > 0, stops at 0.
static func fade(p: AudioStreamPlayer, amp: float, db: float) -> void:
	if amp > 0.0 and not p.playing:
		p.play(randf() * p.stream.get_length())
	elif amp == 0.0 and p.playing:
		p.stop()
	p.volume_db = linear_to_db(amp) + db


## Ambient loops (wind, rain, room tone, fire, a prayer, the radio) go on while the game is paused for a menu
## (shop, notes); one-shots and the body's own loops pause with it.
static func _keep(p: Node, loop: bool) -> void:
	if loop:
		p.process_mode = Node.PROCESS_MODE_ALWAYS
