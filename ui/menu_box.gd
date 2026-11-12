class_name MenuBox
extends VBoxContainer
## Lista vertical de botões para os menus (tela inicial, pausa, confirmação).
## Funciona com mouse, teclado (setas + Enter) e controle (direcional + A).

const BTN_SIZE := Vector2(340, 52)


func _init() -> void:
	add_theme_constant_override("separation", 12)
	alignment = BoxContainer.ALIGNMENT_CENTER
	process_mode = Node.PROCESS_MODE_ALWAYS


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
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_stylebox_override("normal", _box(Color(0.1, 0.1, 0.2, 0.92), Color(0.35, 0.38, 0.6)))
	b.add_theme_stylebox_override("hover", _box(Color(0.18, 0.18, 0.34, 0.95), Color(0.7, 0.85, 1.0)))
	b.add_theme_stylebox_override("focus", _box(Color(0.18, 0.18, 0.34, 0.95), Color(0.7, 0.85, 1.0)))
	b.add_theme_stylebox_override("pressed", _box(Color(0.25, 0.25, 0.45, 0.95), Color(0.9, 0.95, 1.0)))
	if danger:
		b.add_theme_color_override("font_color", Color(1.0, 0.6, 0.55))
		b.add_theme_color_override("font_hover_color", Color(1.0, 0.75, 0.7))
		b.add_theme_color_override("font_focus_color", Color(1.0, 0.75, 0.7))
	b.pressed.connect(action)
	add_child(b)
	return b


func add_label(text: String, size := 18, color := Color(0.75, 0.78, 0.88)) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(520, 0)
	l.add_theme_font_size_override("font_size", size)
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


func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.content_margin_left = 16
	s.content_margin_right = 16
	return s
