extends Control
## Menu inicial: Continuar (se houver save), Novo jogo e Carregar (3 espaços), Opções e Sair.
## Funciona com mouse, teclado (setas + Enter, Esc volta) e controle.

const VERSION := "protótipo v0.8"
const LAYER_NAMES := {
	"res://world/layers/bercario.tscn": "Berçário",
	"res://world/layers/galerias.tscn": "Galerias Úmidas",
	"res://world/layers/abismo.tscn": "Abismo",
}
const FORM_NAMES := ["Filhote de Seda", "Cavaleira de Seda"]

var box: MenuBox
var options: OptionsMenu
var _screen := "main"
var _t := 0.0
var _web: Array = []      ## fios da teia de fundo: [de, até]


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_make_web()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 150.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	box = MenuBox.new()
	center.add_child(box)
	var oc := CenterContainer.new()
	oc.set_anchors_preset(Control.PRESET_FULL_RECT)
	oc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(oc)
	options = OptionsMenu.new()
	options.visible = false
	options.closed.connect(func():
		show_main()
		for b in box.buttons():
			if b.text == "Opções":
				MenuBox.focus_later(b))
	oc.add_child(options)
	show_main()


func has_save() -> bool:
	return GameState.has_save()


func any_save() -> bool:
	for k in range(1, GameState.SLOTS + 1):
		if GameState.has_save(k):
			return true
	return false


func save_summary(slot: int = -1) -> String:
	## "Galerias Úmidas · Filhote de Seda, nível 3"
	var data := GameState.load_game(slot)
	if data.is_empty():
		return "vazio"
	var where := String(LAYER_NAMES.get(String(data.get("scene", "")), "?"))
	var p: Dictionary = data.get("player", {})
	if p.is_empty():
		p = (data.get("act", {}) as Dictionary).get("player", {})
	var lvl := int(p.get("level", 1))
	if p.has("form"):
		var f := clampi(int(p["form"]), 0, FORM_NAMES.size() - 1)
		return "%s · %s, nível %d" % [where, FORM_NAMES[f], lvl]
	return "%s · nível %d" % [where, lvl]


# ---------------------------------------------------------------- telas

func show_main() -> void:
	_screen = "main"
	options.visible = false
	box.visible = true
	box.clear()
	if has_save():
		box.add_button("Continuar", continue_game)
		box.add_label("Espaço %d · %s" % [GameState.slot, save_summary()], 16, Color(0.6, 0.66, 0.8))
	box.add_button("Novo jogo", show_slots.bind("new"))
	if any_save():
		box.add_button("Carregar", show_slots.bind("load"))
	box.add_button("Opções", show_options)
	box.add_button("Sair", func(): get_tree().quit())
	box.focus_first()


func show_slots(mode: String) -> void:
	## Os 3 espaços de save. "new": escolher onde começar; "load": escolher qual continuar.
	_screen = "slots_" + mode
	box.clear()
	box.add_label("Novo jogo: escolha um espaço" if mode == "new" else "Carregar", 26, Color(0.92, 0.93, 0.97))
	for k in range(1, GameState.SLOTS + 1):
		var full := GameState.has_save(k)
		var b := box.add_button("Espaço %d — %s" % [k, save_summary(k)], func(): _pick_slot(mode, k))
		b.custom_minimum_size = Vector2(620, 52)
		if mode == "load" and not full:
			b.disabled = true
	box.add_button("Voltar", show_main)
	box.focus_first()
	if mode == "load":
		for b in box.buttons():
			if not b.disabled:
				MenuBox.focus_later(b)
				break


func _pick_slot(mode: String, k: int) -> void:
	if mode == "load":
		_use_slot(k)
		continue_game()
	elif GameState.has_save(k):
		show_confirm_new(k)
	else:
		_use_slot(k)
		new_game()


func show_confirm_new(k: int = -1) -> void:
	if k < 1:
		k = GameState.slot
	_screen = "confirm"
	box.clear()
	box.add_label("Começar do zero no espaço %d apaga o save dele\n(%s)." % [k, save_summary(k)], 20, Color(0.92, 0.93, 0.97))
	box.add_button("Sim, começar do zero", func():
		_use_slot(k)
		new_game(), true)
	box.add_button("Voltar", show_slots.bind("new"))
	box.focus_first()
	# foco no "Voltar" para ninguém apagar o save sem querer
	var b := box.buttons()
	MenuBox.focus_later(b[b.size() - 1])


func show_options() -> void:
	_screen = "options"
	box.visible = false
	options.open()


func show_controls() -> void:
	show_options()
	options.show_page("controles")


func _use_slot(k: int) -> void:
	GameState.slot = k
	Settings.set_value("espaco", k)


func _unhandled_input(event: InputEvent) -> void:
	if _screen == "options":
		return   # as Opções cuidam do Esc
	if _screen != "main" and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		if _screen == "confirm":
			show_slots("new")
		else:
			show_main()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- ações

func new_game() -> void:
	GameState.new_game()


func continue_game() -> void:
	GameState.continue_game()


# ---------------------------------------------------------------- fundo

func _make_web() -> void:
	## Uma teia simples no canto: raios + espiral.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var c := Vector2(0.0, 0.0)
	var rays := 9
	var pts: Array = []
	for r in rays:
		var a := lerpf(0.05, PI * 0.5 - 0.05, float(r) / float(rays - 1)) + rng.randf_range(-0.04, 0.04)
		var ray: Array = []
		for k in range(1, 9):
			ray.append(c + Vector2(cos(a), sin(a)) * (70.0 * k + rng.randf_range(-8.0, 8.0)))
		pts.append(ray)
		_web.append([c, ray[ray.size() - 1]])
	for k in 8:
		for r in rays - 1:
			_web.append([pts[r][k], pts[r + 1][k]])


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect().size
	# fundo: caverna escura com um brilho de fungo pulsando no centro
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.03, 0.035, 0.07))
	var pulse := 0.5 + 0.5 * sin(_t * 0.8)
	for i in 6:
		var rad := 520.0 - i * 80.0
		draw_circle(vp * Vector2(0.5, 0.42), rad, Color(0.2, 0.35, 0.8, 0.025 + 0.012 * pulse))
	# teias nos dois cantos de cima
	var web_col := Color(0.75, 0.82, 1.0, 0.16 + 0.05 * pulse)
	for seg in _web:
		draw_line(seg[0], seg[1], web_col, 1.2, true)
		draw_line(Vector2(vp.x - seg[0].x, seg[0].y), Vector2(vp.x - seg[1].x, seg[1].y), web_col, 1.2, true)
	# fio descendo com a aranhinha balançando
	var sway := sin(_t * 1.3) * 18.0
	var spider := Vector2(vp.x * 0.5 + sway, 120.0 + 10.0 * sin(_t * 0.9))
	draw_line(Vector2(vp.x * 0.5, 0.0), spider, Color(0.85, 0.9, 1.0, 0.5), 1.5, true)
	draw_circle(spider, 9.0, Color(0.16, 0.14, 0.38))
	draw_circle(spider + Vector2(0, 12), 13.0, Color(0.16, 0.14, 0.38))
	draw_circle(spider + Vector2(0, 12), 3.0, Color(0.4, 0.9, 1.0, 0.6 + 0.4 * pulse))
	for s in [-1.0, 1.0]:
		for k in 4:
			var base := spider + Vector2(5.0 * s, 4.0 + k * 3.5)
			var knee := base + Vector2(14.0 * s, -8.0 + k * 4.0)
			var foot := knee + Vector2(6.0 * s, 12.0 + k * 2.0)
			draw_polyline(PackedVector2Array([base, knee, foot]), Color(0.12, 0.11, 0.26), 2.0, true)
	# título
	var font := ThemeDB.fallback_font
	_center_text(font, "CAVALEIRA DE SEDA", vp.y * 0.30, 64, Color(0.9, 0.93, 1.0))
	_center_text(font, "Uma aranha recém-nascida numa caverna onde tudo é maior que ela", vp.y * 0.30 + 44.0, 20, Color(0.6, 0.7, 0.9))
	draw_string(font, Vector2(20.0, vp.y - 20.0), VERSION, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.54, 0.66))
	var credit := "Fangame gratuito inspirado em Kumo desu ga, Nani ka?"
	var w := font.get_string_size(credit, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2(vp.x - w - 20.0, vp.y - 20.0), credit, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.54, 0.66))


func _center_text(font: Font, text: String, y: float, size: int, color: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2((get_viewport_rect().size.x - w) * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.6 * color.a))
	draw_string(font, Vector2((get_viewport_rect().size.x - w) * 0.5 - 2.0, y - 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
