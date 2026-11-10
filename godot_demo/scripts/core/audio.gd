# Sound helpers (../tools/sons -> res://sounds): one-shots and loops, 2D or placed in the world, and loops that fade.
class_name Audio


static func sfx(n: String, loop := false) -> AudioStreamWAV:
	var s: AudioStreamWAV = load(Paths.SOUND % n)
	if loop and s.loop_mode == AudioStreamWAV.LOOP_DISABLED:  # the loops are cut seamless by the sound tools
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD; s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
	return s


static func play2d(parent: Node, n: String, db := 0.0, loop := false) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new(); p.stream = sfx(n, loop); p.volume_db = db; parent.add_child(p); p.play()
	if not loop:
		p.finished.connect(p.queue_free)
	return p


static func play3d(parent: Node, n: String, at: Vector3, db := 0.0, loop := false, size := 3.0, far := 40.0) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new(); p.stream = sfx(n, loop); p.volume_db = db
	p.unit_size = size; p.max_distance = far; p.position = at; parent.add_child(p); p.play()
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
