extends Control
## Menu inicial: Continuar (se houver save), Novo jogo e Carregar (3 espaços), Opções e Sair.
## Funciona com mouse, teclado (setas + Enter, Esc volta) e controle.

const VERSION := "protótipo v0.9"
const LAYER_NAMES := {
	"res://world/layers/bercario.tscn": "Berçário",
	"res://world/layers/galerias.tscn": "Galerias Úmidas",
	"res://world/layers/abismo.tscn": "Abismo",
	"res://world/layers/rio_brasa.tscn": "Rio de Brasa",
	"res://world/layers/galerias_cacada.tscn": "Galerias — a caçada",
	"res://world/layers/portao.tscn": "Portão da Superfície",
}
const MENU_POS := Vector2(118, 430)

var box: MenuBox
var options: OptionsMenu
var diorama: TitleDiorama
var _screen := "main"
var _t := 0.0
var _overlay: Control
var _menu_holder: Control
var hero: TextureRect   ## a Cavaleira em 2D (a mesma arte do casulo), por cima da caverna 3D

const HERO_ART := "res://assets/ui/retrato_cavaleira.png"
const RUNE_UV := Vector2(0.575, 0.386)   ## onde fica a espiral nas costas, na arte
## Borda suave em elipse (a arte se desfaz na caverna), a runa respirando em ciano
## e um brilho fino de "fio" passando de vez em quando.
const HERO_SHADER := """
shader_type canvas_item;
uniform float pulse = 0.5;
uniform vec2 rune_uv = vec2(0.575, 0.386);
uniform float sheen = -1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 d = (UV - vec2(0.5, 0.5)) / vec2(0.5, 0.5);
	float r = length(d * vec2(1.0, 1.05));
	float mask = 1.0 - smoothstep(0.52, 0.97, r);
	vec2 q = (UV - rune_uv) * vec2(1.07, 1.0);
	float g = exp(-dot(q, q) / 0.0032);
	c.rgb += vec3(0.25, 0.7, 1.0) * g * (0.15 + 0.45 * pulse);
	float lum = dot(c.rgb, vec3(0.3, 0.5, 0.2));
	float band = exp(-pow((UV.x + UV.y * 0.6 - sheen) / 0.05, 2.0));
	c.rgb += vec3(0.6, 0.75, 1.0) * band * smoothstep(0.25, 0.7, lum) * 0.35;
	COLOR = vec4(c.rgb, c.a * mask);
}
"""


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	Music.area("menu")
	Sfx.ambient("")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# fundo: a caverna viva, em 3D, num mundo só dela
	var svc := SubViewportContainer.new()
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.msaa_3d = Viewport.MSAA_4X
	sv.audio_listener_enable_3d = false
	sv.handle_input_locally = false
	svc.add_child(sv)
	diorama = TitleDiorama.new()
	sv.add_child(diorama)
	# a Cavaleira em 2D, no terço direito, respirando
	hero = TextureRect.new()
	hero.texture = load(HERO_ART)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = HERO_SHADER
	var hm := ShaderMaterial.new()
	hm.shader = sh
	hm.set_shader_parameter("rune_uv", RUNE_UV)
	hero.material = hm
	add_child(hero)
	# por cima: sombra à esquerda, logo e rodapé
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_menu_holder = Control.new()
	_menu_holder.position = MENU_POS
	_menu_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu_holder)
	box = MenuBox.new()
	box.left = true
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_menu_holder.add_child(box)
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
		var f := int(p["form"])
		var fname := String((Player.FORMS.get(f, Player.FORMS[Player.Form.FILHOTE]) as Dictionary)["name"])
		return "%s · %s, nível %d%s" % [where, fname, lvl, _done(data)]
	return "%s · nível %d%s" % [where, lvl, _done(data)]


func _done(data: Dictionary) -> String:
	## Quem já saiu da caverna (viu o final) ganha uma estrela no espaço.
	return "  ★ zerado" if (data.get("flags", {}) as Dictionary).has("fim_jogo") else ""


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

func _process(delta: float) -> void:
	_t += delta
	_place_hero()
	_overlay.queue_redraw()


func _place_hero() -> void:
	## Ocupa ~80% da altura, encostada embaixo à direita; sobe e desce bem pouco
	## (respiração no mesmo ritmo da luz da runa na caverna).
	if hero == null or hero.texture == null:
		return
	var vp := get_viewport_rect().size
	var h := vp.y * 0.8
	var w := h * float(hero.texture.get_width()) / float(hero.texture.get_height())
	var breath := sin(_t * 1.25)
	hero.size = Vector2(w, h * (1.0 + 0.006 * breath))
	hero.position = Vector2(vp.x * 0.69 - w * 0.5, vp.y - h - 36.0 + 5.0 * sin(_t * 0.6) - h * 0.006 * breath)
	var hm := hero.material as ShaderMaterial
	hm.set_shader_parameter("pulse", 0.5 + 0.5 * breath)
	# um brilho atravessa a arte a cada ~7 s
	hm.set_shader_parameter("sheen", fposmod(_t, 7.0) / 7.0 * 4.0 - 1.0)


func _draw_overlay() -> void:
	var ci := _overlay
	var vp := get_viewport_rect().size
	# sombra que vem da esquerda (onde fica o menu) e escurece em cima e embaixo
	var steps := 24
	for i in steps:
		var k := float(i) / float(steps)
		var w := vp.x * 0.62 / float(steps)
		ci.draw_rect(Rect2(k * vp.x * 0.62, 0, w + 1.0, vp.y), Color(0.01, 0.012, 0.03, 0.88 * pow(1.0 - k, 1.6)))
	for i in 12:
		var k := float(i) / 12.0
		var a := 0.5 * pow(1.0 - k, 2.0)
		ci.draw_rect(Rect2(0, k * 90.0, vp.x, 8.0), Color(0, 0, 0, a))
		ci.draw_rect(Rect2(0, vp.y - k * 110.0 - 9.0, vp.x, 9.0), Color(0, 0, 0, a))
	_draw_logo(ci, Vector2(MENU_POS.x, 132.0))
	# rodapé
	SilkUI.text(ci, Vector2(28.0, vp.y - 24.0), VERSION, "body_m", 15, Color(SilkUI.DIM, 0.9))
	SilkUI.text(ci, Vector2(vp.x - 28.0, vp.y - 24.0), "Fangame gratuito inspirado em Kumo desu ga, Nani ka?", "body_m", 15, Color(SilkUI.DIM, 0.9), HORIZONTAL_ALIGNMENT_RIGHT)
	if _screen == "main":
		SilkUI.text(ci, Vector2(vp.x * 0.5, vp.y - 24.0), "↑ ↓  escolher    Enter  confirmar", "body_m", 15, Color(SilkUI.QUIET, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	# entra devagar, saindo do escuro
	var fade := clampf(1.0 - _t / 1.6, 0.0, 1.0)
	if fade > 0.0:
		ci.draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, fade))


func _draw_logo(ci: Control, at: Vector2) -> void:
	## "CAVALEIRA / DE SEDA": letras de Cinzel, um fio de seda com nós e a espiral da runa.
	var pulse := 0.5 + 0.5 * sin(_t * 1.25)
	var glow := Color(SilkUI.CYAN, 0.12 + 0.1 * pulse)
	for k in 3:
		SilkUI.text(ci, at + Vector2(0, 84) + Vector2(k - 1, 0) * 2.0, "CAVALEIRA", "title", 84, glow)
	SilkUI.text(ci, at + Vector2(3, 88), "CAVALEIRA", "title", 84, Color(0, 0, 0, 0.55))
	SilkUI.text(ci, at + Vector2(0, 84), "CAVALEIRA", "title", 84, SilkUI.TEXT)
	var w := SilkUI.text_width("CAVALEIRA", "title", 84)
	# fio com a runa no meio e "DE SEDA" dourado
	var y := at.y + 112.0
	var rune_c := Vector2(at.x + w * 0.5, y)
	SilkUI.thread(ci, Vector2(at.x, y), rune_c - Vector2(20, 0), Color(SilkUI.SILK, 0.55), 2.5, 1.2)
	SilkUI.thread(ci, rune_c + Vector2(20, 0), Vector2(at.x + w, y), Color(SilkUI.SILK, 0.55), 2.5, 1.2)
	SilkUI.knot(ci, Vector2(at.x, y), SilkUI.GOLD, 4.0)
	SilkUI.knot(ci, Vector2(at.x + w, y), SilkUI.GOLD, 4.0)
	SilkUI.rune(ci, rune_c, 13.0, Color(SilkUI.CYAN, 0.75 + 0.25 * pulse), _t * 0.5)
	var sub := SilkUI.spaced("DE SEDA")
	SilkUI.text(ci, Vector2(at.x + w * 0.5, y + 52.0), sub, "title_s", 34, SilkUI.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 4)
	SilkUI.text(ci, Vector2(at.x, y + 98.0), "Uma aranha recém-nascida numa caverna onde tudo é maior que ela.", "body_m", 20, SilkUI.QUIET, HORIZONTAL_ALIGNMENT_LEFT, 3)
