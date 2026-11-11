# The bottom of the well (scenes/levels/poco.tscn): the rope he came down, E climbs back to the well's scene.
extends AutoTest


func run() -> void:
	await wait(0.6); await shot("poco")
	check(L.hud.prompt.text == "E · subir pela corda", "beside the rope: \"%s\"" % L.hud.prompt.text)
	Story.mark("poco:volta", [Paths.TREINO, "treino_poco"])
	await tap("interact"); await wait(0.2)
	check(SceneRouter.requested == Paths.TREINO and SceneRouter.arriving == "treino_poco", "E: back up to the well it hangs from")
