class_name MenuBox
extends VBoxContainer
## Lista vertical de botões para os menus (tela inicial, pausa, confirmação).
## Funciona com mouse, teclado (setas + Enter) e controle (direcional + A).
## Estilo de seda: o botão em foco ganha um fio dourado e a espiral da runa ao lado.

const BTN_SIZE := Vector2(340, 50)

var left := false   ## alinhar texto à esquerda (menu inicial) em vez de centralizar
var _t := 0.0


func _init() -> void:
	add_theme_constant_override("separation", 8)
	alignment = BoxContainer.ALIGNMENT_CENTER
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_t += delta
	for b in buttons():
		if b.has_focus() or b.is_hovered():
			b.queue_redraw()


func clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()


func add_button(text: String, action: Callable, danger := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = BTN_SIZE
	b.focus_mode = Control.FOCUS_ALL
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_font_override("font", SilkUI.font("title_s"))
	b.add_theme_font_size_override("font_size", 22)
	var pad := 46 if left else 20
	b.add_theme_stylebox_override("normal", _box(Color(0.05, 0.06, 0.13, 0.55), Color(0.3, 0.38, 0.6, 0.35), pad))
	b.add_theme_stylebox_override("hover", _box(Color(0.08, 0.09, 0.19, 0.82), Color(0.95, 0.75, 0.4, 0.45), pad))
	b.add_theme_stylebox_override("focus", _box(Color(0.08, 0.09, 0.19, 0.82), Color(0.95, 0.75, 0.4, 0.8), pad))
	b.add_theme_stylebox_override("pressed", _box(Color(0.12, 0.12, 0.25, 0.9), SilkUI.SILK, pad))
	b.add_theme_stylebox_override("disabled", _box(Color(0.04, 0.045, 0.09, 0.4), Color(0.2, 0.22, 0.32, 0.3), pad))
	var base := SilkUI.DANGER if danger else SilkUI.TEXT
	b.add_theme_color_override("font_color", base)
	b.add_theme_color_override("font_hover_color", SilkUI.DANGER.lightened(0.2) if danger else SilkUI.GOLD)
	b.add_theme_color_override("font_focus_color", SilkUI.DANGER.lightened(0.2) if danger else SilkUI.GOLD)
	b.add_theme_color_override("font_pressed_color", SilkUI.SILK)
	b.add_theme_color_override("font_disabled_color", SilkUI.DIM)
	b.draw.connect(_draw_button.bind(b, danger))
	b.pressed.connect(action)
	add_child(b)
	return b


func add_label(text: String, fsize := 18, color := SilkUI.QUIET) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(460.0 if left else 520.0, 0)
	l.add_theme_font_override("font", SilkUI.font("title_s" if fsize >= 24 else "body_m"))
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	return l


func focus_first() -> void:
	for c in get_children():
		if c is Button:
			focus_later(c)
			return


static func focus_later(b: Control) -> void:
	## Foco no próximo quadro, se o botão ainda existir (a cena pode ter trocado).
	var f := func():
		if is_instance_valid(b) and b.is_inside_tree() and b.is_visible_in_tree():
			b.grab_focus()
	f.call_deferred()


func buttons() -> Array:
	return get_children().filter(func(c): return c is Button)


func _draw_button(b: Button, danger: bool) -> void:
	var on := b.has_focus() or b.is_hovered()
	var sz := b.size
	if b.disabled:
		return
	var col := (SilkUI.DANGER if danger else SilkUI.GOLD) if on else Color(0.55, 0.65, 0.9, 0.45)
	if left:
		# espiral da runa à esquerda: gira devagar quando o botão está em foco
		var c := Vector2(23, sz.y * 0.5)
		if on:
			SilkUI.rune(b, c, 9.0, col, _t * 1.6)
		else:
			SilkUI.knot(b, c, col, 3.5)
	elif on:
		SilkUI.knot(b, Vector2(10, sz.y * 0.5), col, 4.0)
		SilkUI.knot(b, Vector2(sz.x - 10, sz.y * 0.5), col, 4.0)
	if on:
		# fio dourado embaixo, com um brilho que corre por ele
		var y := sz.y - 3.0
		b.draw_line(Vector2(12, y), Vector2(sz.x - 12, y), Color(col.r, col.g, col.b, 0.5), 1.0, true)
		var k := fposmod(_t * 0.6, 1.0)
		var x := lerpf(12.0, sz.x - 12.0, k)
		b.draw_line(Vector2(maxf(12.0, x - 40.0), y), Vector2(x, y), Color(1, 0.95, 0.8, 0.85), 1.6, true)


func _box(bg: Color, border: Color, pad := 20) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.border_width_left = 2 if left else 1
	s.set_corner_radius_all(4)
	s.content_margin_left = pad
	s.content_margin_right = 20
	s.anti_aliasing = true
	return s
