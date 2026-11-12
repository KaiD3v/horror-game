# Palitinho with Tenório on his porch (../docs/CONTEUDO_VILAREJO.md "Os jogos"): the bar game. Each hides 0 to 3 sticks in
# a fist; each in turn says what the two fists make together (not the number the other said); the fists open, and who
# said the total takes the round. First to two takes the match: Cr$ 5 either way. Tenório plays with Cr$ 30 a day, no
# more. His habit: when he is behind he squeezes his fist shut hard, and it always holds all three. Each match won, he
# tells something he has never told (MEMORIES; the fourth answers why he climbs to the gate at dawn).
# Keys: W/S or A/D or the mouse wheel change the number, E / Enter / click say it, Esc leaves. Pauses the game.
class_name Palitinho
extends CanvasLayer

signal closed

const STAKE := 5
const PURSE := 30            # what he plays with a day
const MEMORIES := [
	"Eu caçava pra Colônia. Paca, tatu, veado. Os doutores pagavam bem e não perguntavam de onde.",
	"Depois pediram cartucho. Caixa e caixa de cartucho. Pra que hospital quer cartucho? Eu não perguntei.",
	"Na noite da sirene eu vi daqui, desta varanda: as lamparinas subindo a estrada. Gente da vila, cantando. Eu fiquei.",
	"Todo dia de manhã eu subo até o portão pra ver se tenho coragem de bater. Ainda não tive. Pronto. Agora você sabe.",
]
static var lost_day := -1    # the game day his purse is counted for
static var lost := 0         # ...what he has lost on it

var player: Player
var panel: PanelContainer
var title: Label
var score: Label
var line: Label
var choice: Label
var hint: Label
var phase := ""              # "hand", "guess", "shown", "end"
var mine := 0                # my sticks
var his := 0
var his_guess := -1
var my_guess := -1
var pick := 0
var wins := Vector2i.ZERO    # me, him
var round_n := 0


static func day() -> int:
	return int(WorldTime.minutes / 1440.0)


## Whether he will play now (money on both sides).
static func can_play() -> String:
	if lost_day == day() and lost >= PURSE:
		return "Por hoje chega. Você me limpou."
	if Inventory.money < STAKE:
		return "Sem dinheiro na mesa não tem jogo, rapaz."
	return ""


func _init(p: Player) -> void:
	player = p; layer = 60; process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	if lost_day != day():
		lost_day = day(); lost = 0
	panel = PanelContainer.new(); add_child(panel)
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -300; panel.offset_right = 300; panel.offset_top = -150; panel.offset_bottom = 150
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.07, 0.05, 0.04, 0.94); sb.border_color = Color(0.55, 0.42, 0.22)
	sb.set_border_width_all(2); sb.set_content_margin_all(18); panel.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 12); panel.add_child(box)
	title = _label(box, "Palitinho com o Tenório  ·  Cr$ %d a partida" % STAKE, Color(0.86, 0.72, 0.42))
	score = _label(box, "", Color(0.8, 0.78, 0.72))
	line = _label(box, "", Color(0.92, 0.9, 0.84)); line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice = _label(box, "", Color(1, 0.86, 0.5)); choice.add_theme_font_size_override("font_size", 28)
	choice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint = _label(box, "W/S · escolher    E · dizer    Esc · sair", Color(0.55, 0.52, 0.48))
	get_tree().paused = true
	_round()


func _label(parent: Node, t: String, c: Color) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_color_override("font_color", c); parent.add_child(l)
	return l


func _round() -> void:
	round_n += 1
	his = 3 if wins.y < wins.x else randi_range(0, 3)  # (behind: the full fist, every time)
	his_guess = -1; my_guess = -1
	phase = "hand"; pick = mine
	var squeeze := "  Ele aperta o punho fechado com força." if wins.y < wins.x else "  Ele esconde a mão nas costas, sem pressa."
	line.text = "Rodada %d.%s\nQuantos palitos você esconde na mão?" % [round_n, squeeze]
	_show()


func _show() -> void:
	score.text = "Você %d  x  %d Tenório    ·    seu dinheiro: %s" % [wins.x, wins.y, ItemCatalog.price(Inventory.money)]
	choice.text = "" if phase in ["shown", "end"] else ("<   %d   >" % pick)


func _his_turn_first() -> bool:
	return round_n % 2 == 0


func _confirm() -> void:
	match phase:
		"hand":
			mine = pick; phase = "guess"; pick = mine
			if _his_turn_first():
				his_guess = _guess_for_him(-1)
				line.text = "Tenório: — Dá %d.\nE você, diz quanto dá?" % his_guess
			else:
				line.text = "Você fala primeiro. Quanto dá, as duas mãos juntas?"
		"guess":
			if pick == his_guess:
				line.text = "Esse ele já disse. Fala outro."; return
			my_guess = pick
			if his_guess < 0:
				his_guess = _guess_for_him(my_guess)
			Audio.play2d(self, "palitos", -4.0)
			var total := mine + his
			var who := "Ninguém acertou." if total != my_guess and total != his_guess else ("Você acertou!" if total == my_guess else "O Tenório acertou.")
			if total == my_guess: wins.x += 1
			elif total == his_guess: wins.y += 1
			line.text = "Você disse %d, ele disse %d.\nAs mãos abrem: você %d, ele %d. Dá %d. %s" % [my_guess, his_guess, mine, his, total, who]
			phase = "shown"
		"shown":
			if wins.x >= 2 or wins.y >= 2:
				_end()
			else:
				_round()
		"end":
			_close()
	_show()


## His word: his own sticks plus what he expects of yours, never the one you said.
func _guess_for_him(said: int) -> int:
	var g := clampi(his + randi_range(0, 3), 0, 6)
	if g == said:
		g = clampi(g + (1 if g < 6 else -1), 0, 6)
	return g


func _end() -> void:
	phase = "end"
	if wins.x >= 2:
		Inventory.money += STAKE; lost += STAKE
		var k := Story.count("palitinho:vitorias"); Story.bump("palitinho:vitorias")
		line.text = "Você ganhou: Cr$ %d. O Tenório junta os palitos devagar.\nTenório: — %s" % [STAKE,
			MEMORIES[k] if k < MEMORIES.size() else "Sorte de principiante. Amanhã eu desforro."]
	else:
		Inventory.spend(STAKE)
		line.text = "O Tenório ganhou: Cr$ %d. \"Prestar atenção custa mais barato, rapaz.\"" % STAKE
	hint.text = "E · fechar"


func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_pressed() or e.is_echo():
		return
	var top := 3 if phase == "hand" else 6
	if e.is_action("forward") or e.is_action("left") or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_WHEEL_UP):
		pick = wrapi(pick + 1, 0, top + 1)
	elif e.is_action("back") or e.is_action("right") or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		pick = wrapi(pick - 1, 0, top + 1)
	elif e.is_action("interact") or (e is InputEventKey and e.keycode == KEY_ENTER) or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT):
		_confirm()
	elif e is InputEventKey and e.keycode == KEY_ESCAPE:
		_close()
	else:
		return
	_show()
	get_viewport().set_input_as_handled()
