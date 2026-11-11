# The title menu (scenes/menu.tscn): the art, the three options, the keyboard, Controles, Novo jogo.
extends AutoTest


func run() -> void:
	await wait(0.6)
	check(L.bg.texture != null and L.bg.texture.get_width() == 1024, "background art loaded")
	var first := 1 if SaveGame.exists() else 0  # a saved game: Continuar on top
	check(L.buttons.size() == 3 + first and get_viewport().gui_get_focus_owner() == L.buttons[0], "%d options, the first focused" % L.buttons.size())
	check(L.buttons[0].text.begins_with("•"), "focused option is marked")
	await shot("menu")
	for i in first + 1:
		await tap("ui_down")
	check(get_viewport().gui_get_focus_owner() == L.buttons[first + 1], "down arrow moves to Controles")
	await tap("ui_accept")
	check(L.controls.visible, "Controles opens")
	await wait(0.2)
	await shot("menu_controles")
	await tap("ui_cancel")
	check(not L.controls.visible and get_viewport().gui_get_focus_owner() == L.buttons[first + 1], "Esc closes Controles")
	await tap("ui_up")
	await tap("ui_accept")
	check(SceneRouter.requested == Paths.VILAREJO, "Novo jogo goes to the village")
	check(ResourceLoader.exists(SceneRouter.requested), "village scene exists")
