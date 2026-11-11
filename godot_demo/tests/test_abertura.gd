# The opening's first acts (scenes/abertura.tscn, Abertura: ../docs/INTRODUCAO.md): played through to the village,
# a capture every 1.5 s (demo_abertura_<shot>_<n>); --only=skip: E held in the first act, straight to the village.
extends AutoTest


func run() -> void:
	var cs: Cutscene = L.cs
	var shots := {}; var last := 0; var frame := 0
	var t0 := Time.get_ticks_msec()
	while SceneRouter.requested != Paths.VILAREJO and Time.get_ticks_msec() - t0 < 180000:
		if cs.shot not in shots:
			shots[cs.shot] = true; frame = 0
		if Time.get_ticks_msec() - last >= 1500:
			last = Time.get_ticks_msec(); frame += 1
			await shot("abertura_%d_%d" % [cs.shot, frame])
		await get_tree().process_frame
	check(SceneRouter.requested == Paths.VILAREJO and shots.size() == 12 and not cs.skipped,
		"played through to the village (%d shots, %.0f s)" % [shots.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	check(Intro.NOTES.all(func(n): return n in NotesReader.read), "the letter, the notice, the photo, the cutting: in the notebook")
	check(Intro.pending and not Intro.skip_next, "the arrival waits in the village")
	check(not get_tree().paused, "nothing left paused")
	var want := ["ambiente_hospital", "tela_arame", "sineta", "chuva", "cidade_madrugada", "chave_fechadura", "porta",
		"passo_madeira", "papel_desdobrar", "lata_abrir", "coracao", "impacto_grave", "sopro", "onibus"]
	var missing := want.filter(func(n): return n not in Audio.heard)
	check(missing.is_empty(), "its sounds all play (missing: %s)" % [missing])


func skip_tests() -> void:
	var cs: Cutscene = L.cs
	await until(func(): return cs.shot == 3, 20.0)
	Input.action_press("interact"); await wait(1.3); Input.action_release("interact")
	await until(func(): return SceneRouter.requested == Paths.VILAREJO, 5.0)
	check(SceneRouter.requested == Paths.VILAREJO and cs.skipped and Intro.skip_next, "E held: on to the village, the arrival skipped too")
	check(Intro.NOTES.all(func(n): return n in NotesReader.read), "...the papers still in the notebook")


