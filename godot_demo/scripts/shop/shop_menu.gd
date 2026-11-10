# A shop's screen, for any seller (Shop has the rules, ShopCatalog the goods): the game pauses on a price list written
# on aged paper, the seller's line at the top, your money at the bottom. W/S (or the arrows, or the mouse) choose,
# E / Enter / click buys, Esc / Tab leaves.
class_name ShopMenu
extends CanvasLayer

signal closed

const PAGE := Vector2(420, 540)    # the paper at 2x, like the notes
const INK := Color(0.12, 0.1, 0.1)
const PICKED := Color(0.55, 0.14, 0.08)
const GONE := Color(0.42, 0.4, 0.37)

var shop_id := ""
var seller := ""
var page: TextureRect
var title: Label
var line: Label        # what the seller says (and how a purchase went)
var list: VBoxContainer
var desc: Label
var purse: Label
var rows: Array[Button] = []
var prices: Array[Label] = []


func _ready() -> void:
	add_to_group("shop_menu")
	layer = 6; process_mode = Node.PROCESS_MODE_ALWAYS  # buying pauses the game, not the shop
	var screen := get_viewport().get_visible_rect().size
	var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.72); dim.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(dim)
	page = TextureRect.new(); add_child(page); page.position = Vector2((screen.x - PAGE.x) / 2, 30); page.size = PAGE
	page.texture = load(Paths.TEXTURE % "nota_oficio"); page.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title = _label(Vector2(44, 40), 24, INK)
	line = _label(Vector2(44, 96), 24, Color(0.3, 0.25, 0.22)); line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list = VBoxContainer.new(); page.add_child(list); list.position = Vector2(36, 190); list.size = Vector2(PAGE.x - 72, 180)
	list.add_theme_constant_override("separation", 2)
	desc = _label(Vector2(44, 380), 24, Color(0.25, 0.22, 0.2)); desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	purse = _label(Vector2(44, 488), 24, INK)
	var foot := Label.new(); add_child(foot); foot.position = Vector2(0, screen.y - 26); foot.size = Vector2(screen.x, 24)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; foot.add_theme_font_size_override("font_size", 12)
	foot.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	foot.text = "W/S escolher   ·   E comprar   ·   Esc sair"
	visible = false


func _label(at: Vector2, size: int, col: Color) -> Label:
	var l := Label.new(); page.add_child(l); l.position = at; l.size = Vector2(PAGE.x - 88, 24)
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	return l


func open(id: String, who: String) -> void:
	shop_id = id; seller = who
	var s := ShopCatalog.shop(id)
	title.text = "%s · %s" % [s.titulo, who]
	line.text = "\"%s\"" % s.fala
	for c in list.get_children():
		c.queue_free()
	rows.clear(); prices.clear()
	for i in Shop.offers(id).size():
		var row := HBoxContainer.new(); list.add_child(row)
		var b := Button.new(); row.add_child(b); b.flat = true; b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var p := Label.new(); row.add_child(p)
		b.pressed.connect(buy.bind(i)); b.focus_entered.connect(_show.bind(i)); b.mouse_entered.connect(b.grab_focus)
		rows.append(b); prices.append(p)
	_refresh()
	visible = true
	get_tree().paused = true
	rows[0].grab_focus()
	_show(0)


func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func buy(i: int) -> void:
	var o: Dictionary = Shop.offers(shop_id)[i]
	match Shop.buy(shop_id, i):
		Shop.Result.OK:
			line.text = "\"Tá na mão.\""
			Audio.play2d(self, "compra", -4.0)
		Shop.Result.NO_MONEY:
			line.text = "\"Isso é %s. Volta quando tiver.\"" % ItemCatalog.price(o.preco)
		Shop.Result.SOLD_OUT:
			line.text = "\"Acabou. Não vem mais nada lá de baixo.\""
	_refresh()
	_show(i)


func _refresh() -> void:
	for i in rows.size():
		var o: Dictionary = Shop.offers(shop_id)[i]
		var it := ItemCatalog.item(o.item)
		var left := Shop.left(shop_id, i)
		rows[i].text = it.nome + (" (%d)" % o.qtd if o.qtd > 1 else "") + ("  · esgotado" if left == 0 else "")
		prices[i].text = ItemCatalog.price(o.preco)
		var col := GONE if left == 0 or Inventory.money < o.preco else INK
		for s in ["font_color", "font_pressed_color", "font_hover_pressed_color"]:
			rows[i].add_theme_color_override(s, col)
		for s in ["font_hover_color", "font_focus_color"]:
			rows[i].add_theme_color_override(s, PICKED)
		prices[i].add_theme_color_override("font_color", col)
	purse.text = "Dinheiro: %s" % ItemCatalog.price(Inventory.money)


func _show(i: int) -> void:  # the chosen item: what it is, how many you have
	var o: Dictionary = Shop.offers(shop_id)[i]
	var it := ItemCatalog.item(o.item)
	var left := Shop.left(shop_id, i)
	desc.text = "%s\nVocê tem: %d%s" % [it.descricao, Inventory.count(o.item), "" if left < 0 else "   ·   restam %d" % left]


func focused() -> int:
	return rows.find(get_viewport().gui_get_focus_owner())


func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		return
	if e.is_action_pressed("ui_cancel") or e.is_action_pressed("notes"):
		close()
	elif e.is_action_pressed("interact") and focused() >= 0:
		buy(focused())
	elif e.is_action_pressed("forward") or e.is_action_pressed("back"):
		rows[wrapi(focused() + (1 if e.is_action_pressed("back") else -1), 0, rows.size())].grab_focus()
	else:
		return
	get_viewport().set_input_as_handled()
