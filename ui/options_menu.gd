class_name OptionsMenu
extends PanelContainer
## Tela de Opções (menu inicial e pausa): Som, Tela e Controles.
## Mouse, teclado e controle. Esc volta (ou cancela a troca de tecla).

signal closed

const TEXT := SilkUI.TEXT
const QUIET := SilkUI.QUIET
const ACCENT := SilkUI.GOLD

var page := "som"
var _tabs: Dictionary = {}
var _body: VBoxContainer
var _status: Label
var _cap: Array = []              ## [ação, pad?, botão] enquanto espera a tecla nova
var _cap_from := 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(920, 640)
	theme = SilkUI.theme()
	var sb := SilkUI.box(Color(0.03, 0.035, 0.08, 0.96), Color(SilkUI.BORDER, 0.9), 1, 4, 30)
	sb.content_margin_top = 26
	sb.content_margin_bottom = 24
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 24
	add_theme_stylebox_override("panel", sb)
	draw.connect(func(): SilkUI.frame(self, Rect2(Vector2(6, 6), size - Vector2(12, 12)), Color(SilkUI.GOLD, 0.35)))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	var title := _label(SilkUI.spaced("OPÇÕES"), 30, TEXT)
	title.add_theme_font_override("font", SilkUI.font("title"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 12)
	root.add_child(tabs)
	for t in [["som", "Som"], ["tela", "Tela"], ["controles", "Controles"]]:
		var b := _button(t[1], func(): show_page(t[0]), Vector2(200, 46))
		tabs.add_child(b)
		_tabs[t[0]] = b
	_body = VBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 12)
	root.add_child(_body)
	_status = _label("", 16, ACCENT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_status)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(bottom)
	bottom.add_child(_button("Voltar", close, Vector2(260, 50)))


func open(start_page := "som") -> void:
	visible = true
	show_page(start_page)


func close() -> void:
	_cancel_capture()
	visible = false
	Settings.block_input(0.2)
	closed.emit()


func show_page(p: String) -> void:
	_cancel_capture()
	page = p
	_status.text = ""
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	for k in _tabs:
		var on: bool = k == p
		var tb := _tabs[k] as Button
		tb.add_theme_color_override("font_color", ACCENT if on else QUIET)
		tb.add_theme_stylebox_override("normal", SilkUI.box(Color(0.1, 0.09, 0.16, 0.9) if on else Color(0.05, 0.06, 0.13, 0.6), Color(SilkUI.GOLD, 0.7) if on else Color(SilkUI.BORDER, 0.5), 1, 4))
	match p:
		"som":
			_slider_row("Volume geral", "Master", 0.0, 1.0)
			_slider_row("Música", "Música", 0.0, 1.0)
			_slider_row("Efeitos", "Efeitos", 0.0, 1.0)
			_slider_row("Dublagem", "Voz", 0.0, 1.0)
			_body.add_child(_label("A dublagem ainda não existe; o volume dela já fica guardado para quando chegar.", 15, QUIET))
		"tela":
			_check_row("Tela cheia", "tela_cheia", Settings.fullscreen)
			_slider_row("Brilho", "brilho", 0.7, 1.6)
			_body.add_child(_label("A caverna é escura de propósito. Suba o brilho só se a tela for escura demais.", 15, QUIET))
			_check_row("Mostrar a lista de controles no jogo", "mostrar_controles", Settings.show_help)
			_check_row("Números de dano", "numeros_dano", Settings.damage_numbers)
			_check_row("Pausa curtinha no impacto dos golpes", "pausa_impacto", Settings.hit_stop)
			_check_row("Tremer a tela", "tremor", Settings.screen_shake)
			var r := HBoxContainer.new()
			r.alignment = BoxContainer.ALIGNMENT_CENTER
			r.add_child(_button("Restaurar tudo ao padrão", _reset_all, Vector2(340, 46)))
			_body.add_child(r)
		"controles":
			_controls_page()
	MenuBox.focus_later(_tabs[p])


# ---------------------------------------------------------------- linhas

func _slider_row(text: String, key: String, lo: float, hi: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := _label(text, 20, TEXT)
	l.custom_minimum_size = Vector2(240, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = float(Settings.volume[key]) if Settings.volume.has(key) else Settings.brightness
	s.custom_minimum_size = Vector2(440, 32)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_ALL
	s.process_mode = Node.PROCESS_MODE_ALWAYS
	var v := _label("", 20, ACCENT)
	v.custom_minimum_size = Vector2(80, 0)
	var show_val := func(x: float): v.text = "%d%%" % roundi(x * 100.0)
	show_val.call(s.value)
	s.value_changed.connect(func(x: float):
		show_val.call(x)
		Settings.set_value(key, x))
	row.add_child(s)
	row.add_child(v)
	_body.add_child(row)


func _check_row(text: String, key: String, on: bool) -> void:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = on
	c.focus_mode = Control.FOCUS_ALL
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	c.add_theme_font_size_override("font_size", 20)
	c.toggled.connect(func(x: bool): Settings.set_value(key, x))
	_body.add_child(c)


func _controls_page() -> void:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(840, 380)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	_body.add_child(sc)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 6)
	sc.add_child(g)
	for h in ["Ação", "Teclado / mouse", "Controle"]:
		g.add_child(_label(h, 16, QUIET))
	for r in Settings.REMAP:
		var action: String = r[0]
		var l := _label(String(r[1]), 18, TEXT)
		l.custom_minimum_size = Vector2(330, 0)
		g.add_child(l)
		for pad in [false, true]:
			var allowed: bool = r[3] if pad else r[2]
			var txt := Settings.text(action, pad) if allowed else ("Analógico esq." if pad else "—")
			var b := _button(txt, func(): pass, Vector2(230, 38), 17)
			b.disabled = not allowed
			if allowed:
				b.pressed.connect(_start_capture.bind(action, pad, b))
			g.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(_button("Restaurar controles padrão", _reset_controls, Vector2(340, 44)))
	_body.add_child(row)
	_body.add_child(_label("Clique numa tecla e aperte a nova. Esc cancela. Se a tecla já era de outra ação, as duas trocam.", 15, QUIET))


# ---------------------------------------------------------------- trocar tecla

func _start_capture(action: String, pad: bool, b: Button) -> void:
	_cancel_capture()
	_cap = [action, pad, b]
	_cap_from = Time.get_ticks_msec()
	Settings.capturing = true
	b.text = "Aperte um botão do controle…" if pad else "Aperte uma tecla…"
	_status.text = ""


func _cancel_capture() -> void:
	if _cap.is_empty():
		return
	var b: Button = _cap[2]
	if is_instance_valid(b):
		b.text = Settings.text(_cap[0], _cap[1])
	_cap = []
	Settings.capturing = false
	Settings.block_input(0.2)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _cap.is_empty():
		return
	get_viewport().set_input_as_handled()
	if Time.get_ticks_msec() - _cap_from < 180:
		return   # o próprio clique/aperto que abriu a troca
	if event is InputEventKey and event.pressed and ((event as InputEventKey).physical_keycode == KEY_ESCAPE or (event as InputEventKey).keycode == KEY_ESCAPE):
		_cancel_capture()
		return
	var ev := Settings.capture_ok(event, _cap[1])
	if ev == null:
		return
	var action: String = _cap[0]
	var pad: bool = _cap[1]
	_cap = []
	var swapped := Settings.bind(action, pad, ev)
	Settings.capturing = false
	Settings.block_input(0.25)
	_rebuild_controls_keep_focus(action, pad)
	_status.text = ("Trocou de lugar com \"%s\"." % swapped) if swapped != "" else "Pronto: %s." % Settings.event_text(ev)


func _rebuild_controls_keep_focus(action: String, pad: bool) -> void:
	var st := _status.text
	show_page("controles")
	_status.text = st
	# devolve o foco para o mesmo botão
	var sc := _body.get_child(0) as ScrollContainer
	var g := sc.get_child(0) as GridContainer
	var idx := -1
	for i in Settings.REMAP.size():
		if Settings.REMAP[i][0] == action:
			idx = i
	if idx >= 0:
		MenuBox.focus_later(g.get_child(3 + idx * 3 + (2 if pad else 1)) as Control)


func _unhandled_input(event: InputEvent) -> void:
	if visible and _cap.is_empty() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _reset_controls() -> void:
	Settings.reset_controls()
	show_page("controles")
	_status.text = "Controles de volta ao padrão."


func _reset_all() -> void:
	Settings.reset_all()
	Settings.apply()
	Settings.save_cfg()
	show_page("tela")
	_status.text = "Tudo de volta ao padrão."


# ---------------------------------------------------------------- peças

func _label(text: String, fsize: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, action: Callable, min_size: Vector2, font := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.add_theme_font_size_override("font_size", font)
	b.add_theme_font_override("font", SilkUI.font("title_s" if min_size.x >= 200.0 else "body_b"))
	b.pressed.connect(action)
	return b
