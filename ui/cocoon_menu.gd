class_name CocoonMenu
extends Control
## Menu do casulo (design escolhido pelo criador, 12/11):
##   esquerda: retrato da aranha (a própria jogadora, renderizada ao vivo);
##   direita: abas Habilidades (teia de habilidades), Evolução e Despensa;
##   embaixo: PV, Energia, Seda, Saciedade, nível, XP, pontos e "Descansar (salvar)".
## Abre com E perto de um casulo (o jogo pausa). Esc / B sai sem descansar.
## Mouse, teclado (setas, Enter, 1-2-3 ou Tab troca a aba) e controle (LB/RB trocam a aba).

signal closed

const W := 1600.0
const H := 900.0
const BG := Color(0.035, 0.04, 0.085)
const PANEL := Color(0.05, 0.06, 0.13, 0.92)
const BORDER := Color(0.25, 0.35, 0.6, 0.55)
const CYAN := Color(0.45, 0.85, 1.0)
const GOLD := Color(0.95, 0.75, 0.4)
const TEXT := Color(0.9, 0.92, 0.98)
const QUIET := Color(0.58, 0.64, 0.8)
const DIM := Color(0.35, 0.4, 0.52)
const RIGHT := Rect2(800, 40, 750, 680)
const PORTRAIT := Rect2(30, 30, 770, 700)
const BOTTOM := Rect2(50, 745, 1500, 120)
const WEB_C := Vector2(1175, 420)
const WEB_STEP := 82.0
const TABS := [["hab", "Habilidades", "star"], ["evo", "Evolução", "crystal"], ["desp", "Toca e despensa", "cocoon"]]

var player: Player
var cocoon: Node3D
var tab := "hab"
var selected := "afiadas"
var message := ""
var _msg_t := 0.0
var _t := 0.0
var _frame: Control
var _f := {}
var _tab_btns := {}
var _node_btns := {}
var _page_btns: Array = []
var _rest_btn: Button
var _learn_btn: Button
var _leave_btn: Button
var _art: Texture2D
var _threads: Array = []
var _hunter := ""   ## bicho te caçando perto: descansar fica bloqueado


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_f = {
		"title": load("res://assets/fonts/cinzel-latin-700-normal.woff"),
		"title_s": load("res://assets/fonts/cinzel-latin-600-normal.woff"),
		"body": load("res://assets/fonts/alegreya-sans-latin-400-normal.woff"),
		"body_m": load("res://assets/fonts/alegreya-sans-latin-500-normal.woff"),
		"body_b": load("res://assets/fonts/alegreya-sans-latin-700-normal.woff"),
	}
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 60:   # fios do casulo no fundo
		var a := Vector2(rng.randf_range(-100, W + 100), rng.randf_range(-100, H + 100))
		var ang := rng.randf_range(0.0, PI)
		_threads.append([a - Vector2(cos(ang), sin(ang)) * 900.0, a + Vector2(cos(ang), sin(ang)) * 900.0, rng.randf_range(0.03, 0.1)])
	_frame = Control.new()
	_frame.size = Vector2(W, H)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_frame.draw.connect(_draw_frame)
	_art = load(PORTRAIT_ART) as Texture2D
	_build_static_buttons()


# ================================================================= abrir / fechar

func open(p: Player, c: Node3D) -> void:
	player = p
	cocoon = c
	visible = true
	message = ""
	tab = "evo" if player.can_evolve() or ((player.can_choose_branch() or player.can_choose_final()) and player.pending_form < 0) else "hab"
	selected = _first_learnable()
	_show_tab(tab)
	GameState.say_once("menu_casulo", "Meu cantinho. Aqui dá pra pensar com calma no que eu quero virar.")


func close() -> void:
	visible = false
	Settings.block_input(0.25)
	closed.emit()


func rest() -> void:
	## Descansar (salvar): cura, passa o tempo, faz a muda se der, grava e sai.
	if player == null:
		return
	var hunter := player.rest_blocker()
	if hunter != "":
		_say("Não dá para dormir: %s está te caçando aqui perto." % hunter)
		return
	var was := player.form
	var c := cocoon
	close()
	player._rest(c)
	if player.form != was:
		EventBus.message.emit("A muda terminou dentro do casulo.")


func _first_learnable() -> String:
	for id in Skills.ALL:
		if player.skill_block(id) == "":
			return id
	return "afiadas"


# ================================================================= retrato
## Arte 2D da protagonista (recorte do design do menu): assets/ui/retrato_cavaleira.png.
## O Filhote usa a mesma arte menor (ainda não tem uma própria).

const PORTRAIT_ART := "res://assets/ui/retrato_cavaleira.png"


# ================================================================= botões

func _build_static_buttons() -> void:
	var x := RIGHT.position.x + 17.0
	for i in TABS.size():
		var t: Array = TABS[i]
		var b := _flat_button(Rect2(x + i * 241.0, RIGHT.position.y + 17.0, 228.0, 50.0))
		b.pressed.connect(_show_tab.bind(t[0]))
		_tab_btns[t[0]] = b
	_rest_btn = _flat_button(Rect2(1300, 773, 232, 62))
	_rest_btn.pressed.connect(rest)
	_leave_btn = _flat_button(Rect2(44, 46, 150, 40))
	_leave_btn.pressed.connect(close)
	for id in Skills.ALL:
		var p := _node_pos(id)
		var r := _node_r(id) + 8.0
		var b := _flat_button(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0))
		b.focus_entered.connect(func(): _select(id))
		b.mouse_entered.connect(func(): b.grab_focus())
		b.pressed.connect(_press_node.bind(id))
		_node_btns[id] = b
	_learn_btn = _flat_button(Rect2(0, 0, 120, 30))
	_learn_btn.pressed.connect(func():
		var keep := selected
		_press_node(keep)
		MenuBox.focus_later(_node_btns[keep]))


func _flat_button(r: Rect2) -> Button:
	## Botão invisível por cima do desenho: o visual é pintado em _draw_frame.
	var b := Button.new()
	b.flat = true
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_ALL
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(st, empty)
	b.focus_entered.connect(_frame.queue_redraw)
	b.focus_exited.connect(_frame.queue_redraw)
	b.mouse_entered.connect(_frame.queue_redraw)
	b.mouse_exited.connect(_frame.queue_redraw)
	_frame.add_child(b)
	return b


func _show_tab(t: String) -> void:
	tab = t
	for id in _node_btns:
		_node_btns[id].visible = t == "hab"
	_learn_btn.visible = false
	for b in _page_btns:
		b.queue_free()
	_page_btns.clear()
	if t == "desp":
		_build_pantry_buttons()
	elif t == "evo":
		_build_branch_buttons()
	if t == "hab":
		MenuBox.focus_later(_node_btns[selected])
	else:
		MenuBox.focus_later(_tab_btns[t])
	_frame.queue_redraw()


const BRANCH_RECTS := [Rect2(1280, 175, 240, 56), Rect2(1280, 250, 240, 56), Rect2(1280, 325, 240, 56)]


## Última muda: as duas formas do ramo (coluna da esquerda) e as raras (coluna da direita).
const FINAL_RECTS := [Rect2(830, 222, 330, 60), Rect2(830, 292, 330, 60)]
const RARE_X := 1185.0
const RARE_Y := 214.0
const RARE_STEP := 38.0


func _rare_rect(i: int) -> Rect2:
	return Rect2(RARE_X, RARE_Y + i * RARE_STEP, 335, 33)


func _build_branch_buttons() -> void:
	## Os três ramos viram botões quando a Cavaleira chega no nível 10. No ramo, as formas da
	## última muda já aparecem (passar o mouse mostra o que fazem e o que pedem).
	if player.can_choose_branch():
		for b in 3:
			var f: int = Player.BRANCHES[b]
			var btn := _page_button(BRANCH_RECTS[b], "", true, _pick_branch.bind(f))
			btn.set_meta("branch", f)
	elif player.is_final():
		for st in 2:
			var b := _page_button(STYLE_RECTS[st], "", true, _pick_style.bind(st))
			b.set_meta("style", st)
	elif player.is_branch():
		var opts := player.next_options()
		for i in opts.size():
			var f2: int = opts[i]
			var r: Rect2 = FINAL_RECTS[i] if i < 2 else _rare_rect(i - 2)
			var btn2 := _page_button(r, "", true, _pick_branch.bind(f2))
			btn2.set_meta("branch", f2)


const STYLE_RECTS := [Rect2(850, 478, 324, 210), Rect2(1180, 478, 324, 210)]


func _pick_style(st: int) -> void:
	player.set_attack_style(st)
	var info := KitBook.info(int(player.form), st)
	_say("Estilo %s: %s e %s." % ["A" if st == 0 else "B", info["names"][0], info["names"][1]])
	_frame.queue_redraw()


func _pick_branch(f: int) -> void:
	if player.choose_branch(f):
		_say("Escolhido: %s. Descanse no casulo para fazer a muda." % String(Player.FORMS[f]["name"]))
	elif player.is_branch() and not player.can_choose_final():
		_say("A última muda abre no nível %d do ramo." % Player.FINAL_LEVEL)
	elif Player.RARES.has(f) and not player.rare_ready(f):
		_say("Ainda falta: %s." % ", ".join(player.rare_requirements(f).filter(func(r): return not r[1]).map(func(r): return String(r[0]))))
	_frame.queue_redraw()


func _den() -> Den:
	return player.current_den() if player != null else null


func _page_button(r: Rect2, label: String, enabled: bool, cb: Callable) -> Button:
	var b := _flat_button(r)
	b.set_meta("label", label)
	b.set_meta("on", enabled)
	b.pressed.connect(cb)
	_page_btns.append(b)
	return b


func _pantry_slot(i: int) -> Rect2:
	return Rect2(840 + (i % 5) * 138, 196 + floori(i / 5.0) * 150, 128, 140)


func _bag_slot(i: int) -> Rect2:
	return Rect2(840 + i * 258, 520, 250, 74)


func _build_pantry_buttons() -> void:
	var den := _den()
	if den != null and den.claimed:
		for i in den.pantry.size():
			var r := _pantry_slot(i)
			var full := player.bag.size() >= Player.BAG_MAX
			_page_button(Rect2(r.position + Vector2(6, r.size.y - 32), Vector2(56, 26)), "Comer", true, _eat.bind(i))
			_page_button(Rect2(r.position + Vector2(66, r.size.y - 32), Vector2(56, 26)), "Levar", not full, _take.bind(i))
	for i in player.bag.size():
		var r := _bag_slot(i)
		var can_store := den != null and den.claimed and den.pantry.size() < Den.PANTRY_MAX
		_page_button(Rect2(r.position + Vector2(162, 8), Vector2(80, 26)), "Guardar", can_store, _store.bind(i))
		_page_button(Rect2(r.position + Vector2(162, 40), Vector2(80, 26)), "Comer", true, _eat_bag.bind(i))
	var n := player.wrappable_corpses().size()
	var can_wrap := n > 0 and player.silk >= Player.SILK_WRAP
	_page_button(Rect2(840, 650, 420, 44), "Embrulhar presas por perto (%d) · 10 de Seda" % n, can_wrap, _wrap)
	if den != null and den.claimed:
		var lab := "Fios-alarme instalados" if den.alarm else "Fios-alarme · %d de Seda" % int(Den.ALARM_COST)
		_page_button(Rect2(1270, 650, 250, 44), lab, not den.alarm and player.silk >= Den.ALARM_COST, _buy_alarm)


func _select(id: String) -> void:
	selected = id
	_frame.queue_redraw()


func _press_node(id: String) -> void:
	if selected != id:
		_select(id)
		return
	var why := player.skill_block(id)
	if why == "":
		player.learn(id)
		_say("Aprendeu %s." % Skills.info(id)["name"])
		var lines := {"espiral": "Girar com as duas lâminas. Isso vai ser LINDO. E perigoso.",
			"pulso": "Minha runa agora brilha como um soco de luz.", "investida": "Atravesso tudo. Licença!"}
		if lines.has(id):
			GameState.say_once("hab_" + id, lines[id])
	elif why != "Aprendida":
		_say(why + ".")
	_frame.queue_redraw()


func _eat(i: int) -> void:
	var den := _den()
	var name_ := String(den.pantry[i].get("name", "presa")) if den != null and i < den.pantry.size() else ""
	if player.eat_from_pantry(i):
		_say("Comeu %s da despensa." % name_)
	_show_tab("desp")


func _take(i: int) -> void:
	var den := _den()
	if den == null or player.bag.size() >= Player.BAG_MAX:
		_say("A bolsa está cheia (%d embrulhos)." % Player.BAG_MAX)
		return
	var it := den.take(i)
	if not it.is_empty():
		player.bag.append(it)
		_say("%s foi para a bolsa." % String(it.get("name", "presa")))
	_show_tab("desp")


func _store(i: int) -> void:
	var den := _den()
	if den == null or i >= player.bag.size():
		return
	if den.store(player.bag[i]):
		_say("%s guardado na despensa." % String(player.bag[i].get("name", "presa")))
		player.bag.remove_at(i)
	else:
		_say("A despensa está cheia.")
	_show_tab("desp")


func _eat_bag(i: int) -> void:
	if i >= player.bag.size():
		return
	var it: Dictionary = player.bag[i]
	player.bag.remove_at(i)
	player._eat_item(it)
	_say("Comeu %s." % String(it.get("name", "presa")))
	_show_tab("desp")


func _buy_alarm() -> void:
	var den := _den()
	if den != null and den.buy_alarm(player):
		_say("Fios-alarme instalados: você vai sentir de longe quem mexer nas portas.")
	_show_tab("desp")


func _wrap() -> void:
	if player.wrappable_corpses().is_empty():
		_say("Nenhuma presa fresca por perto para embrulhar.")
		return
	if player.silk < Player.SILK_WRAP:
		_say("Seda insuficiente (10 por presa).")
		return
	var n := player.wrap_nearby()
	if n == 0:
		_say("Sem espaço: a despensa e a bolsa estão cheias.")
	else:
		_say("Embrulhou %d presa%s." % [n, "" if n == 1 else "s"])
	GameState.say_once("despensa", "Lanchinho embrulhado. Não apodrece mais.")
	_show_tab("desp")


func _say(t: String) -> void:
	message = t
	_msg_t = 3.0


# ================================================================= entrada e tempo

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_msg_t = maxf(0.0, _msg_t - delta)
	var vp := get_viewport_rect().size
	var k := minf(vp.x / W, vp.y / H)
	_frame.scale = Vector2(k, k)
	_frame.position = (vp - Vector2(W, H) * k) * 0.5
	_hunter = player.rest_blocker()
	if tab == "hab":
		var why := player.skill_block(selected)
		var br := _badge_rect(why)
		_learn_btn.position = br.position
		_learn_btn.size = br.size
		_learn_btn.visible = why == ""
	_frame.queue_redraw()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
		return
	var next := 0
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			next = 1
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			next = -1
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).physical_keycode:
			KEY_1:
				_show_tab("hab")
			KEY_2:
				_show_tab("evo")
			KEY_3:
				_show_tab("desp")
			KEY_TAB:
				next = -1 if event.shift_pressed else 1
	if next != 0:
		var ids := TABS.map(func(x): return x[0])
		_show_tab(ids[(ids.find(tab) + next + ids.size()) % ids.size()])
		get_viewport().set_input_as_handled()


# ================================================================= desenho

func _draw() -> void:
	## Fundo: o lado de dentro do casulo (fios de seda e brilho frio).
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), BG)
	var k := minf(vp.x / W, vp.y / H)
	var off := (vp - Vector2(W, H) * k) * 0.5
	for i in 8:
		draw_circle(off + Vector2(420, 430) * k, (620.0 - i * 70.0) * k, Color(0.15, 0.25, 0.6, 0.03))
	for th in _threads:
		draw_line(off + (th[0] as Vector2) * k, off + (th[1] as Vector2) * k, Color(0.7, 0.8, 1.0, th[2]), 1.0, true)


func _draw_frame() -> void:
	var ci := _frame
	# retrato (a arte já traz a plataforma de luz)
	if _art != null:
		var k := 1.0 if player.form != Player.Form.FILHOTE else 0.78
		var anchor := Vector2(392, 659)   # centro da plataforma, em pixels da arte
		ci.draw_texture_rect(_art, Rect2(Vector2(400, 668) - anchor * k, _art.get_size() * k), false)
	_draw_leave(ci)
	# painel da direita
	_panel(ci, RIGHT, PANEL, BORDER, 14.0)
	_draw_tabs(ci)
	var sep_y := RIGHT.position.y + 82.0
	ci.draw_line(Vector2(RIGHT.position.x + 20, sep_y), Vector2(RIGHT.end.x - 20, sep_y), Color(BORDER.r, BORDER.g, BORDER.b, 0.6), 1.0)
	_diamond(ci, Vector2(RIGHT.get_center().x, sep_y), 5.0, GOLD)
	match tab:
		"hab":
			_draw_web(ci)
		"evo":
			_draw_evolution(ci)
		"desp":
			_draw_pantry(ci)
	_draw_bottom(ci)
	if _msg_t > 0.0 and message != "":
		var a := clampf(_msg_t, 0.0, 1.0)
		_text(ci, Vector2(RIGHT.get_center().x, RIGHT.end.y - 16), message, "body_m", 18, Color(GOLD.r, GOLD.g, GOLD.b, a), HORIZONTAL_ALIGNMENT_CENTER)


func _draw_leave(ci: Control) -> void:
	var r := Rect2(44, 46, 150, 40)
	var hot := _leave_btn.has_focus() or _leave_btn.is_hovered()
	_panel(ci, r, Color(0.05, 0.06, 0.13, 0.7), CYAN if hot else BORDER, 8.0)
	_text(ci, r.get_center() + Vector2(0, 6), "Sair  (Esc)", "body_m", 17, TEXT if hot else QUIET, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_tabs(ci: Control) -> void:
	for i in TABS.size():
		var t: Array = TABS[i]
		var b: Button = _tab_btns[t[0]]
		var r := Rect2(b.position, b.size)
		var on: bool = tab == t[0]
		var hot := b.has_focus() or b.is_hovered()
		var fill := Color(0.1, 0.2, 0.35, 0.85) if on else Color(0.06, 0.07, 0.15, 0.8)
		_panel(ci, r, fill, CYAN if on or hot else Color(BORDER.r, BORDER.g, BORDER.b, 0.35), 8.0, on)
		var col := TEXT if on else (TEXT if hot else QUIET)
		var label := String(t[1]).to_upper()
		var tw := _fnt("title").get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		var x0 := r.get_center().x - (tw + 30.0) * 0.5
		SkillIcons.draw(ci, t[2], Vector2(x0 + 9, r.get_center().y), 9.0, CYAN if on else col)
		_text(ci, Vector2(x0 + 30, r.get_center().y + 7), label, "title", 19, col)


# ---------------------------------------------------------------- aba Habilidades

func _node_pos(id: String) -> Vector2:
	return WEB_C + (Skills.info(id)["pos"] as Vector2) * WEB_STEP


func _node_r(id: String) -> float:
	return 36.0 if id == "fiandeira" else 26.0


func _draw_web(ci: Control) -> void:
	# a teia de fundo: anéis e raios
	for ring in [1.0, 2.0, 3.0, 3.6]:
		var pts := PackedVector2Array()
		for k in 17:
			var a := k * TAU / 16.0
			var wob := 1.0 + 0.04 * sin(a * 3.0 + ring)
			pts.append(WEB_C + Vector2(cos(a), sin(a)) * ring * WEB_STEP * wob)
		ci.draw_polyline(pts, Color(0.55, 0.65, 0.9, 0.09), 1.0, true)
	for k in 16:
		var a := k * TAU / 16.0
		ci.draw_line(WEB_C, WEB_C + Vector2(cos(a), sin(a)) * 3.6 * WEB_STEP, Color(0.55, 0.65, 0.9, 0.07), 1.0, true)
	# ligações
	for e in Skills.edges():
		var a: String = e[0]
		var b: String = e[1]
		var pa := _node_pos(a)
		var pb := _node_pos(b)
		var dir := (pb - pa).normalized()
		pa += dir * _node_r(a)
		pb -= dir * _node_r(b)
		var both := player.has_skill(a) and player.has_skill(b)
		var one := player.has_skill(a) or player.has_skill(b)
		if e[2]:
			_dashed(ci, pa, pb, Color(CYAN.r, CYAN.g, CYAN.b, 0.7 if both else (0.35 if one else 0.15)), 2.0 if both else 1.4)
		elif both:
			ci.draw_line(pa, pb, Color(CYAN.r, CYAN.g, CYAN.b, 0.25), 7.0, true)
			ci.draw_line(pa, pb, CYAN, 2.5, true)
		else:
			ci.draw_line(pa, pb, Color(CYAN.r, CYAN.g, CYAN.b, 0.35 if one else 0.12), 1.6, true)
	# nós
	for id in Skills.ALL:
		_draw_node(ci, id)
	_draw_tooltip(ci)


func _draw_node(ci: Control, id: String) -> void:
	var p := _node_pos(id)
	var r := _node_r(id)
	var owned := player.has_skill(id)
	var why := player.skill_block(id)
	var open_ := why == "" or why == "Pontos insuficientes"
	var sel := id == selected
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	if owned:
		for g in 4:
			ci.draw_circle(p, r + 10.0 - g * 2.5, Color(0.3, 0.7, 1.0, 0.06))
		ci.draw_circle(p, r, Color(0.08, 0.25, 0.5))
		ci.draw_circle(p, r * 0.8, Color(0.1, 0.35, 0.65))
		_ring(ci, p, r, CYAN, 2.5)
	elif open_:
		ci.draw_circle(p, r, Color(0.07, 0.1, 0.2))
		_ring(ci, p, r, Color(CYAN.r, CYAN.g, CYAN.b, 0.45 + 0.4 * pulse * (1.0 if why == "" else 0.3)), 1.8)
	else:
		ci.draw_circle(p, r, Color(0.08, 0.09, 0.14))
		_ring(ci, p, r, Color(0.4, 0.43, 0.5, 0.6), 1.5)
	if sel:
		_ring(ci, p, r + 7.0, GOLD, 2.0)
		_dotted_ring(ci, p, r + 12.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.7))
	var icol := Color(0.85, 0.95, 1.0) if owned else (Color(0.6, 0.85, 1.0) if open_ else Color(0.45, 0.48, 0.55))
	SkillIcons.draw(ci, String(Skills.info(id)["icon"]), p, r * 0.55, icol)


func _tooltip_rect() -> Rect2:
	var p := _node_pos(selected)
	var sz := Vector2(320, 168)
	var pos := p + Vector2(_node_r(selected) + 26.0, -sz.y * 0.5)
	if pos.x + sz.x > RIGHT.end.x - 12.0:
		pos.x = p.x - _node_r(selected) - 26.0 - sz.x
	pos.y = clampf(pos.y, RIGHT.position.y + 96.0, RIGHT.end.y - sz.y - 40.0)
	return Rect2(pos, sz)


func _badge_text(why: String) -> String:
	return "Aprender" if why == "" else why


func _badge_rect(why: String) -> Rect2:
	var r := _tooltip_rect()
	var bw := _fnt("body_b").get_string_size(_badge_text(why), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 22.0
	return Rect2(r.position + Vector2(r.size.x - 20 - bw, r.size.y - 34), Vector2(bw, 26))


func _draw_tooltip(ci: Control) -> void:
	var s := Skills.info(selected)
	if s.is_empty():
		return
	var r := _tooltip_rect()
	var pos := r.position
	var sz := r.size
	_panel(ci, r, Color(0.03, 0.035, 0.08, 0.97), Color(GOLD.r, GOLD.g, GOLD.b, 0.75), 10.0)
	_text(ci, pos + Vector2(20, 34), String(s["name"]), "title", 19, GOLD)
	_text(ci, pos + Vector2(20, 54), String(s["branch"]).to_upper(), "body_b", 12, QUIET)
	_wrap_text(ci, pos + Vector2(20, 78), sz.x - 40.0, String(s["desc"]), "body", 16, TEXT)
	ci.draw_line(pos + Vector2(20, sz.y - 44), pos + Vector2(sz.x - 20, sz.y - 44), Color(GOLD.r, GOLD.g, GOLD.b, 0.3), 1.0)
	var why := player.skill_block(selected)
	var cost := int(s["cost"])
	if cost > 0:
		SkillIcons.draw(ci, "crystal", pos + Vector2(28, sz.y - 22), 8.0, CYAN)
		_text(ci, pos + Vector2(42, sz.y - 15), "%d ponto%s" % [cost, "" if cost == 1 else "s"], "body_b", 16, TEXT)
	var badge := _badge_text(why)
	var bcol := QUIET
	if why == "":
		bcol = CYAN
	elif why == "Aprendida":
		bcol = Color(0.55, 0.9, 0.7)
	var br := _badge_rect(why)
	var hot := why == "" and (_learn_btn.has_focus() or _learn_btn.is_hovered())
	_panel(ci, br, Color(0.1, 0.2, 0.35, 0.9) if why == "" else Color(0.1, 0.11, 0.18, 0.9), bcol if (why == "" or hot) else Color(0.3, 0.32, 0.4), 6.0)
	_text(ci, br.get_center() + Vector2(0, 5), badge, "body_b", 14, bcol, HORIZONTAL_ALIGNMENT_CENTER)
	if why == "":
		_text(ci, Vector2(RIGHT.position.x + 24, RIGHT.end.y - 16), "Enter / A de novo no nó também aprende", "body", 14, DIM)


# ---------------------------------------------------------------- aba Evolução

func _draw_evolution(ci: Control) -> void:
	if player.tier() >= 2:
		_draw_final_tree(ci)
		return
	var y0 := RIGHT.position.y + 110.0
	_text(ci, Vector2(RIGHT.position.x + 36, y0 + 10), "A muda acontece dentro do casulo.", "body_m", 18, QUIET)
	var f := int(player.form)
	var stage := 0 if f == Player.Form.FILHOTE else (1 if f == Player.Form.CAVALEIRA else 2)
	var cards := [
		["Filhote de Seda", "spider", Rect2(830, 200, 180, 150), 0],
		["Cavaleira de Seda", "blade", Rect2(1050, 200, 180, 150), 1],
	]
	var icons := ["blade", "web", "rune"]
	ci.draw_line(Vector2(1010, 275), Vector2(1050, 275), Color(CYAN.r, CYAN.g, CYAN.b, 0.7 if stage >= 1 else 0.3), 2.0, true)
	for b in 3:
		var by := 175.0 + b * 75.0
		var lit: bool = stage == 2 and int(Player.BRANCHES[b]) == f
		_dashed(ci, Vector2(1230, 275), Vector2(1280, by + 25.0), Color(CYAN.r, CYAN.g, CYAN.b, 0.8) if lit else Color(0.5, 0.55, 0.7, 0.4), 1.4)
	for c in cards:
		var r: Rect2 = c[2]
		var st := int(c[3])
		var cur := st == stage
		var done := st < stage
		var col := GOLD if cur else (CYAN if done else QUIET)
		_panel(ci, r, Color(0.07, 0.1, 0.2, 0.9) if cur else Color(0.05, 0.06, 0.12, 0.85), col, 10.0, cur)
		SkillIcons.draw(ci, c[1], r.position + Vector2(r.size.x * 0.5, 52), 26.0, col)
		_text(ci, r.position + Vector2(r.size.x * 0.5, 106), String(c[0]).to_upper(), "title_s", 13, TEXT if cur or done else QUIET, HORIZONTAL_ALIGNMENT_CENTER)
		var tag := "Forma atual" if cur else ("Concluída" if done else "Nível %d" % Player.EVOLVE_LEVEL)
		_text(ci, r.position + Vector2(r.size.x * 0.5, 132), tag, "body_b", 15, col, HORIZONTAL_ALIGNMENT_CENTER)
	var can_pick := player.can_choose_branch()
	for b in 3:
		var bf: int = Player.BRANCHES[b]
		var data: Dictionary = Player.FORMS[bf]
		var r: Rect2 = BRANCH_RECTS[b]
		var cur := f == bf
		var picked := player.pending_form == bf
		var hot := false
		for btn in _page_btns:
			if int(btn.get_meta("branch", -1)) == bf and (btn.has_focus() or btn.is_hovered()):
				hot = true
		var col := GOLD if (cur or picked) else (CYAN if (can_pick and hot) else (TEXT if can_pick else DIM))
		_panel(ci, r, Color(0.08, 0.1, 0.2, 0.9) if (cur or picked or hot) else Color(0.05, 0.06, 0.11, 0.8), col if (cur or picked or hot) else Color(0.3, 0.33, 0.42, 0.7), 8.0, cur or picked)
		SkillIcons.draw(ci, icons[b], r.position + Vector2(28, 28), 12.0, col)
		_text(ci, r.position + Vector2(52, 25), String(data["name"]), "title_s", 14, col)
		var sub := "Forma atual" if cur else ("Escolhida: descanse para mudar" if picked else ("Clique para escolher" if can_pick else "Ramo %s · Cavaleira nível %d" % [data["branch"], Player.BRANCH_LEVEL]))
		_text(ci, r.position + Vector2(52, 45), sub, "body", 14, col if (cur or picked) else DIM)
		if not can_pick and not cur:
			SkillIcons.draw(ci, "lock", r.position + Vector2(r.size.x - 22, 28), 8.0, DIM)
	# quadro da próxima muda
	var box := Rect2(830, 410, 690, 240)
	_panel(ci, box, Color(0.04, 0.05, 0.1, 0.9), BORDER, 10.0)
	var bx := box.position + Vector2(24, 0)
	if player.form == Player.Form.FILHOTE:
		var lv := player.level
		var need := Player.EVOLVE_LEVEL
		_text(ci, bx + Vector2(0, 40), "Próxima forma: Cavaleira de Seda", "title", 20, GOLD if player.can_evolve() else TEXT)
		_bar(ci, Rect2(bx + Vector2(0, 62), Vector2(420, 10)), clampf(float(lv) / need, 0.0, 1.0), CYAN)
		_text(ci, bx + Vector2(436, 72), "Nível %d / %d" % [lv, need], "body_b", 16, TEXT)
		var lines := [
			"Ganha as duas lâminas de cristal, placas novas e muito mais vida.",
			"O nível volta a 1; PV, Energia e Seda base sobem. Habilidades e pontos ficam.",
			"Cresce para tamanho M: predadores médios param de te tratar como lanche.",
		]
		for i in lines.size():
			_text(ci, bx + Vector2(0, 106 + i * 26), "·  " + lines[i], "body", 17, QUIET)
		if player.can_evolve():
			var pulse := 0.6 + 0.4 * sin(_t * 3.0)
			_text(ci, bx + Vector2(0, 212), "Pronta para a muda! Descanse no casulo para mudar.", "body_b", 18, Color(GOLD.r, GOLD.g, GOLD.b, pulse))
	elif player.form == Player.Form.CAVALEIRA:
		var shown := player.pending_form
		if shown < 0:
			for btn in _page_btns:
				if btn.has_focus() or btn.is_hovered():
					shown = int(btn.get_meta("branch", -1))
		if shown >= 0:
			var d: Dictionary = Player.FORMS[shown]
			_text(ci, bx + Vector2(0, 40), "%s  ·  Ramo %s" % [d["name"], d["branch"]], "title", 20, GOLD)
			var desc: Array = d["desc"]
			for i in desc.size():
				_text(ci, bx + Vector2(0, 80 + i * 28), "·  " + String(desc[i]), "body", 17, TEXT)
			if player.pending_form >= 0:
				var pulse2 := 0.6 + 0.4 * sin(_t * 3.0)
				_text(ci, bx + Vector2(0, 212), "Pronta para a muda! Descanse no casulo para mudar.", "body_b", 18, Color(GOLD.r, GOLD.g, GOLD.b, pulse2))
		else:
			var lv2 := player.level
			_text(ci, bx + Vector2(0, 40), "Próxima muda: escolha um ramo", "title", 20, GOLD if can_pick else TEXT)
			_bar(ci, Rect2(bx + Vector2(0, 62), Vector2(420, 10)), clampf(float(lv2) / Player.BRANCH_LEVEL, 0.0, 1.0), CYAN)
			_text(ci, bx + Vector2(436, 72), "Nível %d / %d" % [lv2, Player.BRANCH_LEVEL], "body_b", 16, TEXT)
			_text(ci, bx + Vector2(0, 106), "·  Lâmina: foices, couraça e golpes pesados.", "body", 17, QUIET)
			_text(ci, bx + Vector2(0, 132), "·  Teia: muita seda, fios baratos e longos.", "body", 17, QUIET)
			_text(ci, bx + Vector2(0, 158), "·  Runa: energia, visão no escuro e furtividade.", "body", 17, QUIET)
			if can_pick:
				_text(ci, bx + Vector2(0, 204), "Passe o mouse num ramo para ver; clique para escolher.", "body_b", 17, CYAN)


func _hot_form() -> int:
	for btn in _page_btns:
		if btn.has_focus() or btn.is_hovered():
			return int(btn.get_meta("branch", -1))
	return -1


func _draw_final_tree(ci: Control) -> void:
	## Ramo e última muda: a trilha das formas no alto, as opções no meio e o quadro embaixo.
	var f := int(player.form)
	var final := player.is_final()
	var branch_form: int = int(player.fd("parent", f)) if final and player.fd("parent") != null else f
	# trilha: Filhote → Cavaleira → ramo → última muda
	var steps := [["Filhote", "spider"], ["Cavaleira", "blade"]]
	if Player.BRANCHES.has(branch_form):
		steps.append([String(Player.FORMS[branch_form]["name"]).split(" ")[0], ["blade", "web", "rune"][Player.BRANCHES.find(branch_form)]])
	else:
		steps.append(["Ramo", "star"])
	steps.append([String(player.form_data()["name"]).split(" ")[0] if final else "Última muda", String(player.fd("icon", "star")) if final else "lock"])
	for i in steps.size():
		var r := Rect2(830 + i * 175, 140, 160, 44)
		var cur := (i == 2 and not final) or (i == 3 and final)
		var done := i < (3 if final else 2)
		var col := GOLD if cur else (CYAN if done else QUIET)
		_panel(ci, r, Color(0.07, 0.1, 0.2, 0.9) if cur else Color(0.05, 0.06, 0.12, 0.85), col, 8.0, cur)
		SkillIcons.draw(ci, steps[i][1], r.position + Vector2(24, 22), 10.0, col)
		_text(ci, r.position + Vector2(44, 28), steps[i][0], "body_b", 15, TEXT if cur or done else QUIET)
		if i > 0:
			ci.draw_line(Vector2(r.position.x - 15, 162), Vector2(r.position.x, 162), Color(CYAN.r, CYAN.g, CYAN.b, 0.6 if done or cur else 0.25), 2.0, true)
	var box := Rect2(830, 410, 690, 290)
	_panel(ci, box, Color(0.04, 0.05, 0.1, 0.9), BORDER, 10.0)
	var bx := box.position + Vector2(24, 0)
	if final:
		var d: Dictionary = player.form_data()
		var big := Rect2(830, 200, 690, 96)
		var tint: Color = d.get("tint", GOLD)
		_panel(ci, big, Color(0.07, 0.1, 0.2, 0.9), GOLD, 12.0, true)
		SkillIcons.draw(ci, String(d.get("icon", "star")), big.position + Vector2(52, 48), 26.0, tint)
		_text(ci, big.position + Vector2(104, 42), String(d["name"]).to_upper(), "title", 22, TEXT)
		_text(ci, big.position + Vector2(104, 74), ("Forma rara · " + String(d["rare"])) if d.has("rare") else ("Ramo " + String(d["branch"]) + " · " + String(d.get("pitch", ""))), "body_b", 16, GOLD)
		_text(ci, big.position + Vector2(big.size.x - 20, 74), "a última muda", "body", 14, QUIET, HORIZONTAL_ALIGNMENT_RIGHT)
		var box2 := Rect2(830, 306, 690, 394)
		_panel(ci, box2, Color(0.04, 0.05, 0.1, 0.9), BORDER, 10.0)
		var desc: Array = d["desc"]
		for i in desc.size():
			_text(ci, box2.position + Vector2(24, 34 + i * 26), "·  " + String(desc[i]), "body", 16, TEXT)
		_text(ci, box2.position + Vector2(24, 140), "ESTILO DE ATAQUE  ·  troque quando quiser aqui no casulo", "body_b", 13, QUIET)
		var hot_st := -1
		for btn in _page_btns:
			if btn.has_meta("style") and (btn.has_focus() or btn.is_hovered()):
				hot_st = int(btn.get_meta("style"))
		for st in 2:
			var r: Rect2 = STYLE_RECTS[st]
			var on := player.attack_style == st
			var col := GOLD if on else (CYAN if hot_st == st else Color(0.3, 0.33, 0.42, 0.8))
			_panel(ci, r, Color(0.08, 0.1, 0.2, 0.92) if on or hot_st == st else Color(0.05, 0.06, 0.11, 0.85), col, 8.0, on)
			var info := KitBook.info(f, st)
			if info.is_empty():
				continue
			_text(ci, r.position + Vector2(16, 26), ("ESTILO " + ("A" if st == 0 else "B")) + ("  ·  em uso" if on else ""), "body_b", 13, GOLD if on else QUIET)
			var yy := r.position.y + 50.0
			for k in 2:
				_text(ci, Vector2(r.position.x + 16, yy), ("Golpe: " if k == 0 else "Mordida: ") + String(info["names"][k]), "title_s", 15, TEXT if on or hot_st == st else Color(0.75, 0.78, 0.85))
				yy = _wrap_text_h(ci, Vector2(r.position.x + 16, yy + 20), r.size.x - 30, String(info["descs"][k]), "body", 13, QUIET) + 6.0
		return
	var can_pick := player.can_choose_final()
	_text(ci, Vector2(830, 207), "RAMO " + String(player.form_data()["branch"]).to_upper(), "body_b", 13, QUIET)
	_text(ci, Vector2(RARE_X, 207), "FORMAS RARAS (QUALQUER RAMO)", "body_b", 13, QUIET)
	var opts := player.next_options()
	var hot := _hot_form()
	for i in opts.size():
		var of: int = opts[i]
		var d2: Dictionary = Player.FORMS[of]
		var rare := i >= 2
		var r: Rect2 = FINAL_RECTS[i] if not rare else _rare_rect(i - 2)
		var is_ready := not rare or player.rare_ready(of)
		var picked := player.pending_form == of
		var is_hot := hot == of
		var col := GOLD if picked else (CYAN if is_hot else (TEXT if (can_pick and is_ready) else DIM))
		_panel(ci, r, Color(0.08, 0.1, 0.2, 0.9) if (picked or is_hot) else Color(0.05, 0.06, 0.11, 0.8), col if (picked or is_hot) else Color(0.3, 0.33, 0.42, 0.7), 8.0, picked)
		var tint: Color = d2.get("tint", TEXT)
		if not rare:
			SkillIcons.draw(ci, String(d2.get("icon", "star")), r.position + Vector2(30, 30), 13.0, tint if is_ready else DIM)
			_text(ci, r.position + Vector2(58, 26), String(d2["name"]), "title_s", 15, col)
			var sub := "Escolhida: descanse para mudar" if picked else (String(d2.get("pitch", "")) if can_pick else "%s · ramo nível %d" % [d2.get("pitch", ""), Player.FINAL_LEVEL])
			_text(ci, r.position + Vector2(58, 47), sub, "body", 14, col if picked else QUIET)
		else:
			SkillIcons.draw(ci, String(d2.get("icon", "star")), r.position + Vector2(18, 16), 8.0, tint if is_ready else DIM)
			_text(ci, r.position + Vector2(36, 22), String(d2["name"]), "body_b", 15, col)
			var tag := "escolhida" if picked else ("pronta" if is_ready else String(d2["rare"]))
			_text(ci, r.position + Vector2(r.size.x - 12, 22), tag, "body", 13, GOLD if (picked or is_ready) else DIM, HORIZONTAL_ALIGNMENT_RIGHT)
			if not is_ready:
				SkillIcons.draw(ci, "lock", r.position + Vector2(r.size.x - 22 - 9.0 * tag.length(), 16), 6.0, DIM)
	var shown := player.pending_form if player.pending_form >= 0 else hot
	if shown < 0 or not opts.has(shown):
		var lv := player.level
		_text(ci, bx + Vector2(0, 40), "Última muda", "title", 20, GOLD if can_pick else TEXT)
		_bar(ci, Rect2(bx + Vector2(0, 62), Vector2(420, 10)), clampf(float(lv) / Player.FINAL_LEVEL, 0.0, 1.0), CYAN)
		_text(ci, bx + Vector2(436, 72), "Nível %d / %d" % [lv, Player.FINAL_LEVEL], "body_b", 16, TEXT)
		var lines := [
			"No nível %d do ramo, o ramo se divide em dois: escolha um." % Player.FINAL_LEVEL,
			"As formas raras servem para qualquer ramo, mas pedem resistências e materiais.",
			"É a última muda: o nível volta a 1 e a forma fica para sempre.",
		]
		for i in lines.size():
			_text(ci, bx + Vector2(0, 106 + i * 26), "·  " + lines[i], "body", 17, QUIET)
		var bk := KitBook.info(f, 0)
		if not bk.is_empty():
			_text(ci, bx + Vector2(0, 200), "Seus ataques agora: %s (golpe) e %s (mordida)." % [bk["names"][0], bk["names"][1]], "body", 15, TEXT)
		_text(ci, bx + Vector2(0, 236), "Passe o mouse numa forma para ver o que ela faz e o que pede.", "body_b", 16, CYAN)
		return
	var d3: Dictionary = Player.FORMS[shown]
	var head := "%s  ·  %s" % [d3["name"], ("Rara de " + String(d3["rare"])) if d3.has("rare") else ("Ramo " + String(d3["branch"]))]
	_text(ci, bx + Vector2(0, 40), head, "title", 20, GOLD)
	var desc3: Array = d3["desc"]
	for i in desc3.size():
		_text(ci, bx + Vector2(0, 78 + i * 28), "·  " + String(desc3[i]), "body", 16, TEXT)
	var y := 78.0 + desc3.size() * 28.0 + 10.0
	var ia := KitBook.info(shown, 0)
	var ib := KitBook.info(shown, 1)
	if not ia.is_empty() and not ib.is_empty():
		_text(ci, bx + Vector2(0, y), "Ataques: A) %s + %s   ·   B) %s + %s" % [ia["names"][0], ia["names"][1], ib["names"][0], ib["names"][1]], "body_b", 14, CYAN)
		y += 30.0
	var reqs := player.rare_requirements(shown)
	if not reqs.is_empty():
		_text(ci, bx + Vector2(0, y), "Pede:", "body_b", 16, QUIET)
		for i in reqs.size():
			var ok: bool = reqs[i][1]
			var rc := Color(0.5, 0.95, 0.6) if ok else Color(1.0, 0.55, 0.5)
			ci.draw_circle(bx + Vector2(64, y + i * 24 - 5), 5.0, rc if ok else Color(rc.r, rc.g, rc.b, 0.25))
			_ring(ci, bx + Vector2(64, y + i * 24 - 5), 5.0, rc, 1.2)
			_text(ci, bx + Vector2(78, y + i * 24), String(reqs[i][0]) + ("" if ok else "  (falta)"), "body_b" if ok else "body", 16, rc)
	if player.pending_form == shown:
		var pulse := 0.6 + 0.4 * sin(_t * 3.0)
		_text(ci, bx + Vector2(0, 272), "Pronta para a muda! Descanse no casulo para mudar.", "body_b", 18, Color(GOLD.r, GOLD.g, GOLD.b, pulse))
	elif not can_pick:
		_text(ci, bx + Vector2(0, 272), "Abre no nível %d do ramo (agora %d)." % [Player.FINAL_LEVEL, player.level], "body", 16, QUIET)


# ---------------------------------------------------------------- aba Despensa

func _draw_pantry(ci: Control) -> void:
	var den := _den()
	var y0 := RIGHT.position.y + 110.0
	if den == null or not den.claimed:
		_text(ci, Vector2(840, y0 + 10), "Sem toca nesta camada", "title", 20, TEXT)
		_wrap_text(ci, Vector2(840, y0 + 40), 680, "A despensa fica na toca. Aqui você só tem a bolsa (2 embrulhos para a viagem).", "body", 17, QUIET)
	else:
		_text(ci, Vector2(840, y0 + 10), "Despensa da toca  %d / %d" % [den.pantry.size(), Den.PANTRY_MAX], "title", 20, TEXT)
		_text(ci, Vector2(1180, y0 + 10), "Embrulhado não estraga.", "body", 16, QUIET)
		for i in Den.PANTRY_MAX:
			var r := _pantry_slot(i)
			if i < den.pantry.size():
				var it: Dictionary = den.pantry[i]
				_panel(ci, r, Color(0.06, 0.08, 0.16, 0.9), BORDER, 10.0)
				_cocoon_icon(ci, r.position + Vector2(r.size.x * 0.5, 36), 20.0)
				_text(ci, r.position + Vector2(r.size.x * 0.5, 76), _short(String(it.get("name", "presa"))), "body_b", 14, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
				_text(ci, r.position + Vector2(r.size.x * 0.5, 94), "+%d sac · +%d seda" % [int(it.get("sat", 0)), int(it.get("silk", 0))], "body", 12, QUIET, HORIZONTAL_ALIGNMENT_CENTER)
			else:
				_dashed_rect(ci, r, Color(0.4, 0.45, 0.6, 0.25))
	_text(ci, Vector2(840, 508), "Bolsa (viagem)  %d / %d  ·  %s come em qualquer lugar" % [player.bag.size(), Player.BAG_MAX, Settings.text("eat")], "body_b", 17, TEXT)
	for i in Player.BAG_MAX:
		var r := _bag_slot(i)
		if i < player.bag.size():
			var it: Dictionary = player.bag[i]
			_panel(ci, r, Color(0.06, 0.08, 0.16, 0.9), BORDER, 10.0)
			_cocoon_icon(ci, r.position + Vector2(30, 37), 18.0)
			_text(ci, r.position + Vector2(54, 32), _short(String(it.get("name", "presa"))), "body_b", 13, TEXT)
			_text(ci, r.position + Vector2(56, 52), "+%d sac · +%d seda" % [int(it.get("sat", 0)), int(it.get("silk", 0))], "body", 12, QUIET)
		else:
			_dashed_rect(ci, r, Color(0.4, 0.45, 0.6, 0.25))
	if den != null and den.claimed:
		_text(ci, Vector2(1360, 532), "Portas", "body_b", 16, TEXT)
		_text(ci, Vector2(1360, 554), den.doors_summary(), "body", 14, QUIET)
		var y := 576.0
		for line in den.log_lines.slice(0, 2):
			_wrap_text(ci, Vector2(1360, y), 170, String(line), "body", 12, Color(1.0, 0.7, 0.55))
			y += 30.0
	for b in _page_btns:
		var on: bool = b.get_meta("on", true)
		var hot: bool = b.has_focus() or b.is_hovered()
		var br := Rect2(b.position, b.size)
		_panel(ci, br, (Color(0.1, 0.2, 0.35, 0.9) if hot else Color(0.08, 0.1, 0.2, 0.9)) if on else Color(0.05, 0.06, 0.1, 0.85), (CYAN if hot else BORDER) if on else Color(0.22, 0.24, 0.32), 6.0)
		var fs := 15 if b.size.y < 40 else 17
		_text(ci, br.get_center() + Vector2(0, 6), String(b.get_meta("label", "")), "body_b", fs, TEXT if on else DIM, HORIZONTAL_ALIGNMENT_CENTER)


func _short(s: String) -> String:
	return s if s.length() <= 16 else s.substr(0, 15) + "…"


func _cocoon_icon(ci: Control, c: Vector2, r: float) -> void:
	ci.draw_set_transform(c, 0.0, Vector2(0.72, 1.0))
	ci.draw_circle(Vector2.ZERO, r, Color(0.82, 0.86, 0.95, 0.9))
	ci.draw_circle(Vector2.ZERO, r * 0.8, Color(0.9, 0.93, 1.0, 0.95))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for k in 6:
		var y := -r * 0.75 + k * r * 0.3
		var w := sqrt(maxf(0.0, 1.0 - pow(y / r, 2))) * r * 0.72
		ci.draw_line(c + Vector2(-w, y - 3), c + Vector2(w, y + 3), Color(0.55, 0.62, 0.8, 0.7), 1.2, true)


# ---------------------------------------------------------------- barra de baixo

func _draw_bottom(ci: Control) -> void:
	_panel(ci, BOTTOM, PANEL, BORDER, 14.0)
	var res := [
		["heart", "PV", player.hp, player.max_hp, Color(0.92, 0.3, 0.38)],
		["bolt", "Energia", player.energy, player.max_energy, Color(0.95, 0.72, 0.25)],
		["spool", "Seda", player.silk, player.max_silk, Color(0.62, 0.66, 0.98)],
		["leaf", "Saciedade", player.satiety, player.max_satiety, Color(0.45, 0.85, 0.5)],
	]
	for i in res.size():
		var r: Array = res[i]
		var x := 72.0 + i * 228.0
		var c := Vector2(x + 22, 805)
		ci.draw_circle(c, 21.0, Color(0.07, 0.08, 0.16))
		_ring(ci, c, 21.0, Color(BORDER.r, BORDER.g, BORDER.b, 0.8), 1.2)
		SkillIcons.draw(ci, r[0], c, 10.0, r[4])
		_text(ci, Vector2(x + 54, 795), r[1], "body_b", 17, TEXT)
		_text(ci, Vector2(x + 212, 795), "%d / %d" % [int(r[2]), int(r[3])], "body_b", 16, TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		_bar(ci, Rect2(x + 54, 806, 158, 8), clampf(float(r[2]) / maxf(float(r[3]), 1.0), 0.0, 1.0), r[4])
	ci.draw_line(Vector2(992, 768), Vector2(992, 842), Color(BORDER.r, BORDER.g, BORDER.b, 0.6), 1.0)
	# nível
	var lc := Vector2(1040, 805)
	ci.draw_circle(lc, 30.0, Color(0.06, 0.08, 0.2))
	_ring(ci, lc, 30.0, GOLD, 2.0)
	_text(ci, lc + Vector2(0, -9), "NÍVEL", "body_b", 10, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_text(ci, lc + Vector2(0, 16), str(player.level), "title", 24, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_text(ci, Vector2(1084, 797), "XP", "body_b", 17, TEXT)
	_text(ci, Vector2(1214, 797), "%d / %d" % [player.xp, player.xp_to_next()], "body_b", 15, TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_bar(ci, Rect2(1084, 808, 130, 8), clampf(float(player.xp) / maxf(player.xp_to_next(), 1), 0.0, 1.0), CYAN)
	# pontos de habilidade
	var pr := Rect2(1228, 784, 58, 42)
	_panel(ci, pr, Color(0.06, 0.08, 0.16), Color(BORDER.r, BORDER.g, BORDER.b, 0.8), 8.0)
	SkillIcons.draw(ci, "crystal", pr.position + Vector2(18, 21), 9.0, CYAN)
	_text(ci, pr.position + Vector2(42, 28), str(player.skill_points), "body_b", 18, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	# descansar
	var rb := Rect2(_rest_btn.position, _rest_btn.size)
	var hot := _rest_btn.has_focus() or _rest_btn.is_hovered()
	_panel(ci, rb, Color(0.2, 0.15, 0.08, 0.95) if hot else Color(0.12, 0.1, 0.08, 0.95), GOLD, 8.0, hot)
	SkillIcons.draw(ci, "cocoon", rb.position + Vector2(26, 31), 11.0, GOLD)
	var label := "MUDA E DESCANSO" if player.can_evolve() else "DESCANSAR (SALVAR)"
	if _hunter != "":
		label = "PERIGO POR PERTO"
	_text(ci, rb.position + Vector2(44, 38), label, "title", 15, Color(1.0, 0.9, 0.7) if _hunter == "" else Color(1.0, 0.5, 0.4))


# ================================================================= peças de desenho

func _fnt(k: String) -> Font:
	var f = _f.get(k)
	return f if f is Font else ThemeDB.fallback_font


func _text(ci: Control, p: Vector2, s: String, font: String, fsize: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var f := _fnt(font)
	var x := p.x
	if align != HORIZONTAL_ALIGNMENT_LEFT:
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		x -= w * (0.5 if align == HORIZONTAL_ALIGNMENT_CENTER else 1.0)
	ci.draw_string(f, Vector2(x, p.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)


func _wrap_text(ci: Control, p: Vector2, width: float, s: String, font: String, fsize: int, col: Color) -> void:
	var f := _fnt(font)
	var line := ""
	var y := p.y
	for word in s.split(" "):
		var t := word if line == "" else line + " " + word
		if f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > width and line != "":
			ci.draw_string(f, Vector2(p.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
			y += fsize * 1.3
			line = word
		else:
			line = t
	if line != "":
		ci.draw_string(f, Vector2(p.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)


func _wrap_text_h(ci: Control, p: Vector2, width: float, s: String, font: String, fsize: int, col: Color) -> float:
	## Como _wrap_text, mas devolve o y da próxima linha.
	var f := _fnt(font)
	var line := ""
	var y := p.y
	for word in s.split(" "):
		var t := word if line == "" else line + " " + word
		if f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > width and line != "":
			ci.draw_string(f, Vector2(p.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
			y += fsize * 1.3
			line = word
		else:
			line = t
	if line != "":
		ci.draw_string(f, Vector2(p.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
		y += fsize * 1.3
	return y


func _panel(ci: Control, r: Rect2, fill: Color, border: Color, radius: float, glow := false) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2 if glow else 1)
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	if glow:
		sb.shadow_color = Color(border.r, border.g, border.b, 0.35)
		sb.shadow_size = 10
	ci.draw_style_box(sb, r)


func _bar(ci: Control, r: Rect2, t: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.025, 0.05)
	sb.set_corner_radius_all(int(r.size.y * 0.5))
	ci.draw_style_box(sb, r)
	if t > 0.0:
		var fr := Rect2(r.position, Vector2(maxf(r.size.y, r.size.x * t), r.size.y))
		var fb := StyleBoxFlat.new()
		fb.bg_color = col
		fb.set_corner_radius_all(int(r.size.y * 0.5))
		ci.draw_style_box(fb, fr)


func _ring(ci: Control, c: Vector2, r: float, col: Color, w: float) -> void:
	ci.draw_arc(c, r, 0.0, TAU, 48, col, w, true)


func _dotted_ring(ci: Control, c: Vector2, r: float, col: Color) -> void:
	for k in 28:
		var a := k * TAU / 28.0 + _t * 0.4
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * r, 1.3, col)


func _ellipse(ci: Control, c: Vector2, r: Vector2, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for k in 65:
		var a := k * TAU / 64.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	ci.draw_polyline(pts, col, w, true)


func _dashed(ci: Control, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var L := a.distance_to(b)
	var d := (b - a) / maxf(L, 0.001)
	var s := 0.0
	while s < L:
		ci.draw_line(a + d * s, a + d * minf(s + 5.0, L), col, w, true)
		s += 10.0


func _dashed_rect(ci: Control, r: Rect2, col: Color) -> void:
	_dashed(ci, r.position, Vector2(r.end.x, r.position.y), col, 1.2)
	_dashed(ci, Vector2(r.end.x, r.position.y), r.end, col, 1.2)
	_dashed(ci, r.end, Vector2(r.position.x, r.end.y), col, 1.2)
	_dashed(ci, Vector2(r.position.x, r.end.y), r.position, col, 1.2)


func _diamond(ci: Control, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)
