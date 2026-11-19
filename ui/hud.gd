class_name Hud
extends CanvasLayer
## HUD do protótipo, desenhado direto na tela (sem cenas de UI ainda).
## Barras, mensagens, monólogo, Leitura de criaturas, dicas do Modo Tecelagem, ajuda e pausa.

const MSG_TIME := 4.5
const MONO_TIME := 5.0
const TEXT := Color(0.92, 0.93, 0.97)
const QUIET := Color(0.7, 0.72, 0.8)
const THREAT_COLORS := [Color(0.45, 0.9, 0.45), Color(1.0, 0.85, 0.3), Color(1.0, 0.35, 0.3), Color(0.85, 0.4, 1.0)]
const THREAT_NAMES := ["Baixa", "Média", "Alta", "Mortal"]
static func help_lines() -> Array:
	## Lista de controles com as teclas atuais (o jogador pode trocar nas Opções).
	var k := func(a: String) -> String: return Settings.text(a)
	return [
		"CONTROLES (%s esconde)" % k.call("help"),
		"%s mover · Mouse mirar · %s correr" % [Settings.move_text(), k.call("run")],
		"%s golpe · %s mordida (no ramo e na forma final viram ataques próprios)" % [k.call("attack"), k.call("bite")],
		"%s esquiva (parada = backstep)" % k.call("dodge"),
		"%s lançar fio: puxa presa pequena ou te puxa até a parede" % k.call("throw_silk"),
		"Segurar %s: Modo Tecelagem (câmera lenta)" % k.call("weave"),
		"   %s em 2 pilares = fio-guia (%d seda)" % [k.call("attack"), int(GameState.player.strand_cost()) if GameState.player != null else 5],
		"   %s = teia de captura (15 seda, nível 3)" % k.call("bite"),
		"%s embrulhar, arrastar, porta, toca · %s comer embrulho · %s comer / descansar" % [k.call("cocoon"), k.call("eat"), k.call("interact")],
		"%s apagar/acender runa (furtividade)" % k.call("rune"),
		"Segurar %s: Leitura da criatura sob o cursor" % k.call("read"),
		"%s mapa · %s pausa / opções · F1 +1 nível (teste) · F8 novo jogo" % [k.call("map"), k.call("pause")],
	]
const LOCK_NAMES := {"fresta": "fresta", "cristal": "parede de cristal", "acido": "poça ácida", "abismo_longo": "abismo longo", "brasa": "brasa", "cortina": "cortina viva", "desabamento": "desabamento"}

var player: Player = null
var _root: Control
var _mini: Control
var _cv: Control            ## onde as funções de desenho pintam agora
var _font: Font
var _messages: Array = []        ## [texto, tempo restante]
var _mono_text := ""
var _mono_time := 0.0
var _big_text := ""
var _big_time := 0.0
var _show_help := true
var _show_map := false
var show_all_creatures := false
var fade_alpha := 0.0             ## tela preta das transições (0 = some)
## Nome de área à la Elden Ring (chegada numa camada): faixa escura, letras serifadas.
const AREA_SECS := 6.5
const AREA_GOLD := Color(0.93, 0.86, 0.68)
var _area := ""
var _area_sub := ""
var _area_time := 0.0
var _serif: Font = preload("res://ui/fonts/Cinzel-Medium.woff2")
## Cena (fuga, chegada): faixas pretas em cima e embaixo e a interface some.
var cinematic := false
var _cine := 0.0
var _title := ""
var _subtitle := ""
var _title_time := 0.0
const TITLE_SECS := 5.0   ## (capturas/depuração) mostra todas as criaturas no mapa, com legenda
var _pause_box: MenuBox
var _pause_holder: Control
var _portrait: Texture2D = load("res://assets/ui/retrato_cavaleira.png") if ResourceLoader.exists("res://assets/ui/retrato_cavaleira.png") else null
var _options: OptionsMenu
var cocoon_menu: CocoonMenu
var vibes: Array = []           ## setas de vibração: {pos, t, col, big, who}
const VIBE_TIME := 2.6
const VIBE_RING := 150.0         ## distância (px) da seta até a aranha
var _hint_text := ""
var _hint_time := 0.0
var _last_us := 0
# transformação mundo -> tela do mapa sendo desenhado
var _m_b := Rect2()
var _m_sc := 1.0
var _m_off := Vector2.ZERO


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.draw.connect(_on_draw)
	_mini = Control.new()
	_mini.clip_contents = true
	_mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_mini)
	_mini.draw.connect(_on_draw_mini)
	EventBus.stalked.connect(_on_stalked)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 40.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE   # não pode comer os cliques do jogo
	_root.add_child(center)
	_pause_holder = Control.new()
	_pause_holder.position = Vector2(118.0, 286.0)
	_pause_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_pause_holder)
	_pause_box = MenuBox.new()
	_pause_box.left = true
	_pause_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_pause_box.visible = false
	_pause_holder.add_child(_pause_box)
	_options = OptionsMenu.new()
	_options.visible = false
	_options.closed.connect(_on_options_closed)
	center.add_child(_options)
	_show_help = Settings.show_help
	Settings.changed.connect(func(): _show_help = Settings.show_help)
	_cv = _root
	_font = SilkUI.font("body_m")
	EventBus.message.connect(_on_message)
	EventBus.big_message.connect(_on_big_message)
	EventBus.monologue.connect(_on_monologue)
	EventBus.web_touched.connect(_on_web_touched)
	EventBus.hint.connect(_on_hint)
	_last_us = Time.get_ticks_usec()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var dt := clampf((now - _last_us) / 1000000.0, 0.0, 0.1)
	_last_us = now
	for m in _messages:
		m[1] -= dt
	_messages = _messages.filter(func(m): return m[1] > 0.0)
	_mono_time = maxf(0.0, _mono_time - dt)
	_big_time = maxf(0.0, _big_time - dt)
	_hint_time = maxf(0.0, _hint_time - dt)
	_title_time = maxf(0.0, _title_time - dt)
	_area_time = maxf(0.0, _area_time - dt)
	_cine = move_toward(_cine, 1.0 if cinematic else 0.0, dt * 1.6)
	for v in vibes:
		v["t"] -= dt
	vibes = vibes.filter(func(v): return v["t"] > 0.0)
	if Settings.input_blocked() or _options.visible or (cocoon_menu != null and cocoon_menu.visible):
		pass   # Opções abertas ou trocando tecla: as teclas do jogo esperam
	else:
		if Input.is_action_just_pressed("map"):
			_show_map = not _show_map
		if Input.is_action_just_pressed("help"):
			Settings.set_value("mostrar_controles", not _show_help)
		if Input.is_action_just_pressed("pause"):
			if get_tree().paused:
				close_pause()
			else:
				open_pause()
	if Input.is_action_just_pressed("debug_reset"):
		GameState.reset_run()
		return
	var vp := _root.get_viewport_rect().size
	_mini.position = Vector2(vp.x - 254.0, 20.0)
	_mini.size = Vector2(230.0, 160.0)
	_mini.visible = _map_system() != null and not _show_map and player != null and _cine < 0.3 and not _pause_menu_open()
	_root.queue_redraw()
	_mini.queue_redraw()


# ---------------------------------------------------------------- pausa

func open_pause() -> void:
	get_tree().paused = true
	_pause_box.clear()
	_pause_box.add_button("Voltar ao jogo", close_pause)
	_pause_box.add_button("Opções", open_options)
	_pause_box.add_button("Esconder controles" if _show_help else "Mostrar controles", _toggle_help_from_pause)
	_pause_box.add_button("Menu inicial", GameState.to_title)
	_pause_box.add_label("O jogo salva quando você descansa num casulo.\nO que fez depois disso se perde ao sair.", 15, QUIET)
	_pause_box.add_button("Sair do jogo", func(): get_tree().quit(), true)
	_pause_box.visible = true
	_pause_box.focus_first()


func close_pause() -> void:
	_pause_box.visible = false
	_options.visible = false
	get_tree().paused = false


func open_cocoon(c: Node3D) -> void:
	## Menu do casulo (E perto de um casulo): o jogo pausa enquanto ele está aberto.
	if player == null:
		return
	if cocoon_menu == null:
		cocoon_menu = CocoonMenu.new()
		cocoon_menu.closed.connect(func():
			Music.cocoon(false)
			Sfx.play("ui_voltar")
			if not _pause_box.visible and not _options.visible:
				get_tree().paused = false)
		add_child(cocoon_menu)
	get_tree().paused = true
	Music.cocoon(true)
	Sfx.play("ui_abrir")
	cocoon_menu.open(player, c)


func open_options() -> void:
	_pause_box.visible = false
	_options.open()


func _on_options_closed() -> void:
	open_pause()
	MenuBox.focus_later(_pause_box.buttons()[1])


func _toggle_help_from_pause() -> void:
	Settings.set_value("mostrar_controles", not _show_help)
	open_pause()
	MenuBox.focus_later(_pause_box.buttons()[2])


# ---------------------------------------------------------------- eventos

func _on_message(text: String) -> void:
	_messages.append([text, MSG_TIME])
	if _messages.size() > 6:
		_messages.pop_front()


func _on_big_message(text: String) -> void:
	_big_text = text
	_big_time = 4.0


func _on_hint(text: String) -> void:
	_hint_text = text
	_hint_time = 9.0


func _on_monologue(_id: String, text: String) -> void:
	_mono_text = text
	_mono_time = MONO_TIME


func _on_web_touched(pos: Vector3, by: Node) -> void:
	if player == null:
		return
	var who := "Algo"
	var c := by as Creature
	if c != null:
		who = c.display_name
	var d := pos - player.global_position
	_on_message("Vibração! %s tocou sua teia (%d m)." % [who, int(Vector2(d.x, d.z).length())])
	# seta como nos jogos de tiro: aponta de onde veio; cor pelo tamanho de quem tocou
	var col := Color(0.6, 0.95, 1.0)
	var big := 0
	if c != null:
		big = int(c.size)
		col = [Color(0.8, 0.95, 1.0), Color(1.0, 0.68, 0.25), Color(1.0, 0.3, 0.25)][clampi(big, 0, 2)]
	for v in vibes:   # o mesmo bicho de novo: renova a seta em vez de empilhar
		if v["who"] == by and by != null:
			v["pos"] = pos
			v["t"] = VIBE_TIME
			return
	vibes.append({"pos": pos, "t": VIBE_TIME, "col": col, "big": big, "who": by})
	if vibes.size() > 6:
		vibes.pop_front()


func _draw_vibes() -> void:
	## Setas em volta da aranha apontando para onde a teia vibrou (some em ~2,5 s).
	var cam := _root.get_viewport().get_camera_3d()
	if cam == null or vibes.is_empty():
		return
	var me := cam.unproject_position(player.global_position + Vector3(0, 0.4, 0))
	for v in vibes:
		var there := cam.unproject_position(v["pos"] as Vector3)
		var dir := there - me
		if dir.length() < 1.0:
			continue
		dir = dir.normalized()
		var a := clampf(float(v["t"]) / 0.6, 0.0, 1.0) * clampf((VIBE_TIME - float(v["t"])) / 0.12 + 0.3, 0.0, 1.0)
		var col: Color = v["col"]
		var pulse := 1.0 + 0.12 * sin(float(v["t"]) * 18.0)
		var size := (14.0 + 5.0 * int(v["big"])) * pulse
		var tip := me + dir * (VIBE_RING + size)
		var base := me + dir * VIBE_RING
		var side := Vector2(-dir.y, dir.x)
		# arco fino no anel (de onde veio) + a seta
		var ang := dir.angle()
		_cv.draw_arc(me, VIBE_RING - 6.0, ang - 0.32, ang + 0.32, 12, Color(col, 0.55 * a), 4.0, true)
		var tri := PackedVector2Array([tip, base + side * size * 0.75, base - side * size * 0.75])
		_cv.draw_colored_polygon(tri, Color(col, 0.9 * a))
		_cv.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color(0, 0, 0, 0.5 * a), 1.5, true)
		var dist := int(Vector2(v["pos"].x - player.global_position.x, v["pos"].z - player.global_position.z).length())
		var lab := "%d m" % dist
		var lp := tip + dir * 16.0 - Vector2(_font.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x * 0.5, -5.0)
		_cv.draw_string(_font, lp, lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(col, 0.85 * a))


func _direction_name(d: Vector3) -> String:
	## Norte = topo da tela (-Z).
	var ang := rad_to_deg(atan2(d.x, -d.z))
	var names := ["norte", "nordeste", "leste", "sudeste", "sul", "sudoeste", "oeste", "noroeste"]
	var idx := int(roundf(fposmod(ang, 360.0) / 45.0)) % 8
	return names[idx]


# ---------------------------------------------------------------- desenho

func _on_draw() -> void:
	_cv = _root
	var vp := _root.get_viewport_rect().size
	var menu_open := _pause_menu_open()
	if player != null and is_instance_valid(player) and _cine < 0.3 and not menu_open:   # em cena (ou na pausa), a interface some
		_draw_bars(vp)
		_draw_status(vp)
		_draw_boss(vp)
		_draw_danger(vp)
		_draw_vibes()
		if player.weaving:
			_draw_weave_hint(vp)
		var ms = _map_system()
		if ms != null and not _show_map:
			_draw_minimap(ms, vp)
		if Input.is_action_pressed("read"):
			_draw_reading(vp)
		elif _show_help:
			_draw_help(vp)
		if _show_map and ms != null:
			_draw_full_map(ms, vp)
	if _cine < 0.3:
		_draw_messages()
	if _hint_time > 0.0 and not _show_map and _cine < 0.3:
		var alpha_h := clampf(_hint_time, 0.0, 1.0)
		var tw := _font.get_string_size(_hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		_cv.draw_rect(Rect2(vp.x * 0.5 - tw * 0.5 - 18.0, 92.0, tw + 36.0, 38.0), Color(0.05, 0.12, 0.16, 0.8 * alpha_h))
		_text_center(vp.x, 117.0, _hint_text, 16, Color(0.75, 0.95, 1.0, alpha_h))
	if _mono_time > 0.0:
		var alpha := clampf(_mono_time, 0.0, 1.0)
		var mono_y := vp.y - 240.0 if (player != null and player.weaving) else vp.y - 200.0
		_text_center(vp.x, mono_y, "Cavaleira: \"%s\"" % _mono_text, 20, Color(0.75, 0.92, 1.0, alpha))
	if _big_time > 0.0 and _cine < 0.3:
		_text_center(vp.x, vp.y * 0.42, _big_text, 34, Color(1, 1, 1, clampf(_big_time, 0.0, 1.0)))
	if menu_open:
		_draw_pause(vp)
	_draw_transition(vp)   # por último: tela preta e título por cima de tudo

func _draw_bars(vp: Vector2) -> void:
	## Painel de vida embaixo à esquerda: nível e forma em cima, quatro barras com ícone.
	var r := Rect2(20.0, vp.y - 198.0, 396.0, 178.0)
	SilkUI.frame(_cv, r, Color(SilkUI.BORDER, 0.7), Color(0.02, 0.025, 0.06, 0.62))
	var x := r.position.x
	var y := r.position.y
	# medalhão do nível
	var badge := Vector2(x + 36.0, y + 36.0)
	_cv.draw_circle(badge, 23.0, Color(0.05, 0.06, 0.13, 0.95))
	_cv.draw_arc(badge, 23.0, 0.0, TAU, 40, SilkUI.GOLD, 1.6, true)
	var xp_k := clampf(float(player.xp) / maxf(1.0, float(player.xp_to_next())), 0.0, 1.0)
	_cv.draw_arc(badge, 27.0, -PI * 0.5, -PI * 0.5 + TAU * xp_k, 40, SilkUI.CYAN, 2.4, true)
	SilkUI.text(_cv, badge + Vector2(0, 8.0), str(player.level), "title", 22, SilkUI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	SilkUI.text(_cv, Vector2(x + 72.0, y + 30.0), player.form_name(), "title_s", 19, SilkUI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 3)
	SilkUI.text(_cv, Vector2(x + 72.0, y + 52.0), "XP %d / %d" % [player.xp, player.xp_to_next()], "body_m", 15, SilkUI.QUIET)
	SilkUI.text(_cv, Vector2(r.end.x - 14.0, y + 52.0), "Bolsa %d/%d  ·  Tecelagem %d" % [player.bag.size(), Player.BAG_MAX, player.weave_level()], "body_m", 15, SilkUI.QUIET, HORIZONTAL_ALIGNMENT_RIGHT)
	SilkUI.thread(_cv, Vector2(x + 14.0, y + 70.0), Vector2(r.end.x - 14.0, y + 70.0), Color(SilkUI.SILK, 0.18), 1.5, 1.0)
	_bar(x + 14.0, y + 84.0, "heart", player.hp, player.max_hp, Color(0.92, 0.32, 0.38))
	_bar(x + 14.0, y + 106.0, "bolt", player.energy, player.max_energy, Color(0.32, 0.82, 1.0))
	_bar(x + 14.0, y + 128.0, "spool", player.silk, player.max_silk, Color(0.86, 0.89, 0.98))
	_bar(x + 14.0, y + 150.0, "fang", player.satiety, player.max_satiety, Color(0.97, 0.72, 0.28))


func _status_pills() -> Array:
	## [texto, cor] de tudo que está valendo agora: condições, lugar, kit, caçada.
	var out: Array = []
	if player.poison_t > 0.0:
		out.append(["Envenenada", Color(0.6, 1.0, 0.4)])
	if player.heat_t > 0.0:
		out.append(["Calor", Color(1.0, 0.65, 0.3)])
	if player.burn_t > 0.0:
		out.append(["Queimando", Color(1.0, 0.45, 0.25)])
	if float(player.fd("shield", 0.0)) > 0.0:
		out.append(["Escudo %d" % int(player.shield), Color(0.75, 0.85, 1.0)])
	if player.satiety <= 0.0:
		out.append(["Faminta", Color(1.0, 0.45, 0.4)])
	if player.kit != null and player.kit.status_text() != "":
		out.append([player.kit.status_text(), SilkUI.GOLD])
	if GameState.hunt_alert >= 0.0:
		out.append(["Caçada " + "●".repeat(int(GameState.hunt_alert)) + "○".repeat(3 - int(GameState.hunt_alert)), Color(1.0, 0.5, 0.45)])
	if player.in_territory:
		out.append(["No território", SilkUI.CYAN])
	if player.on_strand:
		out.append(["Sobre fio · rápida e silenciosa", SilkUI.CYAN])
	if not player.rune_on:
		out.append(["Runa apagada · furtiva", Color(0.7, 0.72, 0.95)])
	if player.dragged != null:
		out.append(["Arrastando presa · lenta e barulhenta", Color(0.95, 0.8, 0.55)])
	if player.in_den():
		out.append(["Na toca", Color(0.65, 1.0, 0.75)])
	return out


func fade(to: float, secs: float) -> Signal:
	## Escurece (to = 1) ou clareia (to = 0) a tela. Devolve o sinal de fim para await.
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, "fade_alpha", to, secs)
	return tw.finished


func show_area_title(area: String, subtitle: String = "") -> void:
	_area = area
	_area_sub = subtitle
	_area_time = AREA_SECS


func _draw_area_title(vp: Vector2) -> void:
	## Faixa escura que some nas bordas, nome em letras serifadas espaçadas, um fio fino com
	## um losango no meio e o subtítulo pequeno embaixo. Entra devagar e sai devagar.
	var el := AREA_SECS - _area_time
	var a := clampf(el / 1.4, 0.0, 1.0) * clampf(_area_time / 1.8, 0.0, 1.0)
	a = a * a * (3.0 - 2.0 * a)
	var cy := vp.y * 0.36
	var band := 92.0
	var dark := Color(0, 0, 0, 0.62 * a)
	var clear := Color(0, 0, 0, 0.0)
	_cv.draw_polygon(PackedVector2Array([Vector2(0, cy - band), Vector2(vp.x, cy - band), Vector2(vp.x, cy), Vector2(0, cy)]),
		PackedColorArray([clear, clear, dark, dark]))
	_cv.draw_polygon(PackedVector2Array([Vector2(0, cy), Vector2(vp.x, cy), Vector2(vp.x, cy + band), Vector2(0, cy + band)]),
		PackedColorArray([dark, dark, clear, clear]))
	var size := 58
	var spacing := 6.0 + el * 0.5   # as letras se afastam devagar enquanto o nome está na tela
	var text := _area.to_upper()
	var w := 0.0
	for ch in text:
		w += _serif.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + spacing
	w -= spacing
	var x := vp.x * 0.5 - w * 0.5
	var base := cy + size * 0.32
	for ch in text:
		_cv.draw_string(_serif, Vector2(x + 2, base + 3), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.7 * a))
		_cv.draw_string(_serif, Vector2(x, base), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(AREA_GOLD, a))
		x += _serif.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + spacing
	# fio fino que some nas pontas, com um losango no meio
	var ly := cy + size * 0.62
	var half := maxf(w * 0.55, 260.0)
	var steps := 24
	for i in steps:
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		var fall := 1.0 - absf((t0 + t1) - 1.0)
		_cv.draw_line(Vector2(vp.x * 0.5 - half + t0 * half * 2.0, ly), Vector2(vp.x * 0.5 - half + t1 * half * 2.0, ly), Color(AREA_GOLD, 0.75 * a * fall), 1.4, true)
	var d := 5.0
	_cv.draw_colored_polygon(PackedVector2Array([Vector2(vp.x * 0.5, ly - d), Vector2(vp.x * 0.5 + d, ly), Vector2(vp.x * 0.5, ly + d), Vector2(vp.x * 0.5 - d, ly)]), Color(AREA_GOLD, 0.9 * a))
	if _area_sub != "":
		var sw := _serif.get_string_size(_area_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		_cv.draw_string(_serif, Vector2(vp.x * 0.5 - sw * 0.5, ly + 34), _area_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.85, 0.83, 0.78, 0.8 * a))


func _draw_cinematic(vp: Vector2) -> void:
	var h := vp.y * 0.11 * _cine
	_cv.draw_rect(Rect2(0, 0, vp.x, h), Color(0, 0, 0, 1))
	_cv.draw_rect(Rect2(0, vp.y - h, vp.x, h), Color(0, 0, 0, 1))


func show_title(title: String, subtitle: String) -> void:
	_title = title
	_subtitle = subtitle
	_title_time = TITLE_SECS


func _draw_transition(vp: Vector2) -> void:
	if _cine > 0.001:
		_draw_cinematic(vp)
	if fade_alpha > 0.001:
		_cv.draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, fade_alpha))
	if _area_time > 0.0:
		_draw_area_title(vp)
	if _title_time > 0.0:
		var a := clampf(minf(_title_time, TITLE_SECS - _title_time) / 0.8, 0.0, 1.0)
		_text_center(vp.x, vp.y * 0.42, _title, 46, Color(TEXT.r, TEXT.g, TEXT.b, a))
		_text_center(vp.x, vp.y * 0.42 + 46.0, _subtitle, 18, Color(QUIET.r, QUIET.g, QUIET.b, a))


func _on_stalked(_c: Node) -> void:
	if not GameState.said.has("cacada"):
		EventBus.message.emit("Você está sendo caçada! As setas vermelhas na borda da tela mostram de onde.")
	GameState.say_once("cacada", "Tem alguma coisa me seguindo. Eu... SINTO.")


func _draw_danger(vp: Vector2) -> void:
	## Setas vermelhas na borda da tela apontando para quem está te caçando e você não vê.
	if player == null or player.dead or player.camera == null or vp.x < 120.0 or vp.y < 120.0:
		return
	var cam := player.camera
	var center := vp * 0.5
	var inner := Rect2(Vector2.ZERO, vp).grow(-46.0)
	var t := Time.get_ticks_msec() / 1000.0
	for c in World.near(player.global_position, 28.0):
		if not c.hunting_player():
			continue
		var wp := c.global_position + Vector3.UP * 0.5
		var sp := cam.unproject_position(wp)
		if not cam.is_position_behind(wp) and inner.has_point(sp):
			continue   # está na tela: você já vê
		var dir := (sp - center)
		if cam.is_position_behind(wp):
			dir = -dir
		if dir.length() < 1.0:
			continue
		dir = dir.normalized()
		# ponto na borda do retângulo interno na direção do bicho
		var kx := (inner.size.x * 0.5) / maxf(absf(dir.x), 0.001)
		var ky := (inner.size.y * 0.5) / maxf(absf(dir.y), 0.001)
		var edge := center + dir * minf(kx, ky)
		var close := 1.0 - clampf(c.flat_dist_to(player) / 28.0, 0.0, 1.0)
		var a := 0.45 + 0.45 * close + 0.1 * sin(t * (6.0 + close * 10.0))
		var sz := 14.0 + 10.0 * close + 5.0 * int(c.size)
		var side := Vector2(-dir.y, dir.x)
		var pts := PackedVector2Array([edge + dir * sz, edge - dir * sz * 0.4 + side * sz * 0.8, edge - dir * sz * 0.4 - side * sz * 0.8])
		_cv.draw_colored_polygon(pts, Color(1.0, 0.22, 0.2, a))


func _draw_boss(vp: Vector2) -> void:
	## Barra de vida do chefe acordado (topo da tela).
	for n in get_tree().get_nodes_in_group("boss"):
		var b := n as Centipede
		if b == null or b.dead or not (b.engaged() or (b.hp < b.max_hp and b.near_player and b.flat_dist_to(player) < 30.0)):
			continue
		var w := 520.0
		var x := vp.x * 0.5 - w * 0.5
		var y := 52.0
		_cv.draw_rect(Rect2(x - 10.0, y - 30.0, w + 20.0, 52.0), Color(0, 0, 0, 0.5))
		var label: String = b.display_name + ("  ·  ENREDADA: a carapaça abriu!" if b.is_entangled() else ("  ·  furiosa" if b.phase == 2 else ""))
		_text_center(vp.x, y - 10.0, label, 16, Color(1.0, 0.85, 0.5) if b.is_entangled() else TEXT)
		_cv.draw_rect(Rect2(x, y, w, 12.0), Color(0, 0, 0, 0.7))
		_cv.draw_rect(Rect2(x, y, w * clampf(b.hp / b.max_hp, 0.0, 1.0), 12.0), Color(0.9, 0.55, 0.2) if b.is_entangled() else Color(0.75, 0.25, 0.3))
		return


func _bar(x: float, y: float, icon: String, value: float, max_value: float, color: Color) -> void:
	## Barra em cápsula com o ícone na frente e o número no fim.
	SkillIcons.draw(_cv, icon, Vector2(x + 9.0, y + 1.0), 8.0, color)
	var bx := x + 28.0
	var w := 262.0
	var h := 10.0
	_capsule(Rect2(bx, y - 4.0, w, h), Color(0.0, 0.0, 0.0, 0.55))
	var k := clampf(value / maxf(max_value, 0.001), 0.0, 1.0)
	if k > 0.0:
		_capsule(Rect2(bx, y - 4.0, maxf(h, w * k), h), color.darkened(0.15))
		_cv.draw_line(Vector2(bx + h * 0.5, y - 2.0), Vector2(bx + maxf(h, w * k) - h * 0.5, y - 2.0), Color(1, 1, 1, 0.28), 1.5)
	_cv.draw_rect(Rect2(bx + h * 0.5, y - 4.0, w - h, h), Color(SilkUI.BORDER, 0.35), false, 1.0)
	SilkUI.text(_cv, Vector2(bx + w + 10.0, y + 5.0), "%d/%d" % [int(value), int(max_value)], "body_m", 15, SilkUI.QUIET)


func _capsule(r: Rect2, col: Color) -> void:
	var rad := r.size.y * 0.5
	_cv.draw_circle(r.position + Vector2(rad, rad), rad, col)
	_cv.draw_circle(Vector2(r.end.x - rad, r.position.y + rad), rad, col)
	_cv.draw_rect(Rect2(r.position.x + rad, r.position.y, maxf(0.0, r.size.x - rad * 2.0), r.size.y), col)


func _draw_status(vp: Vector2) -> void:
	## Pílulas em cima do painel de vida (quebram linha se não couberem).
	var x := 20.0
	var y := vp.y - 226.0
	for p in _status_pills():
		var t := String(p[0])
		var col: Color = p[1]
		var w := SilkUI.text_width(t, "body_b", 15) + 26.0
		if x + w > vp.x * 0.55:
			x = 20.0
			y -= 30.0
		var r := Rect2(x, y, w, 24.0)
		_capsule(r, Color(0.02, 0.03, 0.07, 0.72))
		_cv.draw_circle(Vector2(x + 11.0, y + 12.0), 3.0, col)
		SilkUI.text(_cv, Vector2(x + 19.0, y + 17.5), t, "body_b", 15, col)
		x += w + 8.0


func _draw_weave_hint(vp: Vector2) -> void:
	var lines := [
		"MODO TECELAGEM — tempo a 25%, gasta Energia",
		"%s em 2 pilares para esticar um fio-guia (%d seda, até 12 m)" % [Settings.text("attack"), int(player.strand_cost()) if player != null else 5],
		"%s: teia de captura no cursor (15 seda, nível 3) · %s: embrulhar / arrastar presa, portas e casulo da toca" % [Settings.text("bite"), Settings.text("cocoon")],
	]
	var y := vp.y - 110.0
	_cv.draw_rect(Rect2(vp.x * 0.5 - 380.0, y - 26.0, 760.0, 84.0), Color(0, 0, 0, 0.5))
	for i in lines.size():
		_text_center(vp.x, y + i * 22.0, lines[i], 16 if i == 0 else 14, TEXT if i == 0 else QUIET)


func _draw_help(vp: Vector2) -> void:
	## Lista de controles num painel de largura fixa; linha comprida quebra em vez de sair da tela.
	const W := 380.0
	var x := vp.x - W - 20.0
	var y := 236.0
	var rows: Array = []
	var lines := help_lines()
	for i in lines.size():
		if i == 0:
			continue
		var indent := String(lines[i]).begins_with("   ")
		for part in _wrap(String(lines[i]).strip_edges(), W - 32.0 - (14.0 if indent else 0.0), 14):
			rows.append([part, indent])
	var r := Rect2(x, y, W, rows.size() * 19.0 + 48.0)
	SilkUI.frame(_cv, r, Color(SilkUI.BORDER, 0.55), Color(0.02, 0.025, 0.06, 0.55))
	SilkUI.text(_cv, Vector2(x + 16.0, y + 25.0), String(lines[0]).to_upper(), "title_s", 13, SilkUI.GOLD)
	for i in rows.size():
		var ind := 14.0 if rows[i][1] else 0.0
		SilkUI.text(_cv, Vector2(x + 16.0 + ind, y + 48.0 + i * 19.0), rows[i][0], "body_m", 14, SilkUI.QUIET if ind > 0.0 else SilkUI.TEXT.darkened(0.08))


func _wrap(t: String, width: float, size: int) -> Array:
	var out: Array = []
	var cur := ""
	for word in t.split(" "):
		var test := word if cur == "" else cur + " " + word
		if cur != "" and SilkUI.text_width(test, "body_m", size) > width:
			out.append(cur)
			cur = word
		else:
			cur = test
	if cur != "":
		out.append(cur)
	return out


func _draw_reading(vp: Vector2) -> void:
	var x := vp.x - 380.0
	var y := 240.0
	_cv.draw_rect(Rect2(x - 12.0, y - 6.0, 376.0, 196.0), Color(0, 0, 0, 0.55))
	var c := _creature_near(player.aim_point, 3.5)
	if c == null:
		_text(x, y + 16.0, "LEITURA", 15, TEXT)
		_text(x, y + 40.0, "Mire numa criatura.", 14, QUIET)
		return
	var threat := c.threat_level(player.level)
	_text(x, y + 16.0, "LEITURA · %s" % c.display_name, 15, TEXT)
	_text(x, y + 40.0, "Tamanho %s · Nível %d" % [Creature.SIZE_NAMES[c.size], c.level], 14, QUIET)
	_text(x, y + 62.0, "Ameaça: %s" % THREAT_NAMES[threat], 14, THREAT_COLORS[threat])
	_text(x, y + 84.0, "PV %d / %d" % [int(c.hp), int(c.max_hp)], 14, QUIET)
	_text(x, y + 106.0, "Sentidos: %s" % c.senses_text, 13, QUIET)
	var st: Array[String] = []
	if c.is_entangled():
		st.append("Enredado")
	if c.poison_stacks > 0:
		st.append("Veneno x%d" % c.poison_stacks)
	if not st.is_empty():
		_text(x, y + 128.0, ", ".join(st), 13, Color(0.6, 0.95, 1.0))
	if c.brain != null:
		_text(x, y + 152.0, "Fazendo: %s" % c.activity, 14, TEXT)
		var feel: Array[String] = []
		if c.needs.hunger > 60.0:
			feel.append("com fome")
		if c.needs.fatigue > 60.0:
			feel.append("com sono")
		if c.needs.fear > 30.0:
			feel.append("com medo")
		if c.hp < c.max_hp * 0.4:
			feel.append("muito ferida")
		_text(x, y + 174.0, ("Parece " + ", ".join(feel)) if not feel.is_empty() else "Parece tranquila", 13, QUIET)


func _draw_messages() -> void:
	var y := 30.0
	for m in _messages:
		var alpha := clampf(float(m[1]), 0.0, 1.0)
		_text(24.0, y, String(m[0]), 15, Color(TEXT.r, TEXT.g, TEXT.b, alpha))
		y += 22.0


func _creature_near(point: Vector3, radius: float) -> Creature:
	return World.nearest(point, radius, func(_c): return true)


func _text(x: float, y: float, s: String, size: int, color: Color) -> void:
	_cv.draw_string_outline(_font, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0, color.a * 0.8))
	_cv.draw_string(_font, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _text_center(width: float, y: float, s: String, size: int, color: Color) -> void:
	_cv.draw_string_outline(_font, Vector2(0.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, width, size, 4, Color(0, 0, 0, color.a * 0.8))
	_cv.draw_string(_font, Vector2(0.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)


# ---------------------------------------------------------------- tela de pausa

func _pause_menu_open() -> bool:
	return _pause_box.visible or _options.visible


func _draw_pause(vp: Vector2) -> void:
	## Pausa: a caverna escurece, o lugar onde você está à esquerda e um cartão com a Cavaleira.
	_cv.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.01, 0.012, 0.03, 0.55))
	for i in 20:
		var k := float(i) / 20.0
		_cv.draw_rect(Rect2(k * vp.x * 0.55, 0, vp.x * 0.55 / 20.0 + 1.0, vp.y), Color(0.01, 0.012, 0.03, 0.6 * pow(1.0 - k, 1.5)))
	if not _pause_box.visible:
		return   # Opções abertas: só o escuro atrás
	var x := 118.0
	SilkUI.text(_cv, Vector2(x, 122.0), SilkUI.spaced("PAUSA"), "title_s", 20, SilkUI.GOLD)
	var lyr = GameState.current_layer
	var where := String(lyr.layer_name) if lyr != null and is_instance_valid(lyr) else "Caverna"
	SilkUI.text(_cv, Vector2(x, 180.0), where, "title", 48, SilkUI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 4)
	var sub := ""
	var ms = _map_system()
	if ms != null and player != null and is_instance_valid(player):
		var here: Dictionary = ms.room_at(player.global_position)
		if not here.is_empty():
			sub = "%s · %s" % [here["id"], here["name"]]
	if World.clock != null:
		sub += ("   ·   " if sub != "" else "") + CaveClock.NAMES[World.clock.phase]
	SilkUI.text(_cv, Vector2(x, 214.0), sub, "body_m", 19, SilkUI.QUIET, HORIZONTAL_ALIGNMENT_LEFT, 3)
	var tw := maxf(340.0, SilkUI.text_width(where, "title", 48))
	SilkUI.thread(_cv, Vector2(x, 238.0), Vector2(x + tw, 238.0), Color(SilkUI.SILK, 0.4), 3.0)
	SilkUI.knot(_cv, Vector2(x, 238.0), SilkUI.GOLD)
	SilkUI.knot(_cv, Vector2(x + tw, 238.0), SilkUI.GOLD)
	if player != null and is_instance_valid(player):
		_draw_pause_card(vp)


func _draw_pause_card(vp: Vector2) -> void:
	var r := Rect2(vp.x - 560.0, 150.0, 460.0, 470.0)
	SilkUI.frame(_cv, r, Color(SilkUI.BORDER, 0.8), Color(0.03, 0.035, 0.08, 0.86))
	var x := r.position.x + 28.0
	var y := r.position.y
	if _portrait != null:
		var ph := 210.0
		var pw := ph * float(_portrait.get_width()) / float(_portrait.get_height())
		var pr := Rect2(r.position.x + (r.size.x - pw) * 0.5, y + 18.0, pw, ph)
		var halo := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 800.0)
		for k in 4:
			_cv.draw_circle(pr.get_center(), 48.0 + k * 16.0, Color(SilkUI.CYAN, 0.025 + 0.012 * halo))
		_cv.draw_texture_rect(_portrait, pr, false)
		y += 236.0
	else:
		y += 30.0
	SilkUI.text(_cv, Vector2(r.get_center().x, y + 8.0), SilkUI.spaced("A CAVALEIRA"), "title_s", 13, SilkUI.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	SilkUI.text(_cv, Vector2(r.get_center().x, y + 42.0), player.form_name(), "title", 28, SilkUI.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 3)
	var info := "Nível %d   ·   XP %d / %d" % [player.level, player.xp, player.xp_to_next()]
	SilkUI.text(_cv, Vector2(r.get_center().x, y + 68.0), info, "body_m", 17, SilkUI.QUIET, HORIZONTAL_ALIGNMENT_CENTER)
	y += 92.0
	_bar(x, y, "heart", player.hp, player.max_hp, Color(0.92, 0.32, 0.38))
	_bar(x, y + 24.0, "bolt", player.energy, player.max_energy, Color(0.32, 0.82, 1.0))
	_bar(x, y + 48.0, "spool", player.silk, player.max_silk, Color(0.86, 0.89, 0.98))
	_bar(x, y + 72.0, "fang", player.satiety, player.max_satiety, Color(0.97, 0.72, 0.28))
	var extra := "Bolsa %d/%d   ·   Tecelagem %d" % [player.bag.size(), Player.BAG_MAX, player.weave_level()]
	if player.moonstones > 0:
		extra += "   ·   Pedra-da-lua %d/%d" % [mini(player.moonstones, Player.MOONSTONES_NEEDED), Player.MOONSTONES_NEEDED]
	SilkUI.text(_cv, Vector2(r.get_center().x, y + 108.0), extra, "body_m", 15, SilkUI.DIM.lightened(0.25), HORIZONTAL_ALIGNMENT_CENTER)


# ---------------------------------------------------------------- mapa

func _map_system():
	var lyr = GameState.current_layer
	if lyr == null or not is_instance_valid(lyr):
		return null
	return lyr.map_system


func _on_draw_mini() -> void:
	var ms = _map_system()
	if ms == null or player == null:
		return
	_cv = _mini
	var area := Rect2(Vector2.ZERO, _mini.size)
	_cv.draw_rect(area, Color(0, 0, 0, 0.6))
	const SCALE := 3.0   # pixels por metro
	var view := area.size / SCALE
	var center := Vector2(player.global_position.x, player.global_position.z)
	_draw_map(ms, area, false, Rect2(center - view * 0.5, view))
	_cv = _root


func _draw_minimap(ms, vp: Vector2) -> void:
	var area := Rect2(vp.x - 254.0, 20.0, 230.0, 160.0)
	SilkUI.frame(_cv, area.grow(2.0), Color(SilkUI.BORDER, 0.85))
	var room_name := ""
	var here: Dictionary = ms.room_at(player.global_position)
	if not here.is_empty():
		room_name = "%s · %s" % [here["id"], here["name"]]
	_text(area.position.x + 8.0, area.position.y + area.size.y + 16.0, room_name, 13, QUIET)
	if World.clock != null:
		var left := int(World.clock.seconds_to_change())
		var col := Color(0.65, 1.0, 0.75) if World.clock.phase == CaveClock.Phase.BRILHO else Color(0.75, 0.65, 1.0)
		_text(area.position.x + 8.0, area.position.y + area.size.y + 34.0, "%s (%d:%02d)" % [CaveClock.NAMES[World.clock.phase], int(left / 60.0), left % 60], 12, col)


func _draw_full_map(ms, vp: Vector2) -> void:
	_cv.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.01, 0.01, 0.02, 0.88))
	var fl: int = ms.current_floor()
	var names = GameState.current_layer.get("FLOOR_NAMES") if GameState.current_layer != null else null
	var fname := ""
	if names is Array and fl < (names as Array).size():
		fname = " · " + String(names[fl])
	_text(60.0, 50.0, "MAPA — %s%s" % [ms.layer_name, fname], 22, TEXT)
	_text(60.0, 74.0, "M fecha · câmaras aparecem quando você entra nelas · losangos = travas já vistas", 14, QUIET)
	_draw_map(ms, Rect2(60.0, 96.0, vp.x - 120.0, vp.y - 170.0), true)


func _ms(x: float, z: float) -> Vector2:
	return _m_off + (Vector2(x, z) - _m_b.position) * _m_sc


func _draw_map(ms, area: Rect2, full: bool, view: Rect2 = Rect2()) -> void:
	var floor_now: int = ms.current_floor()
	_m_b = view if view.size != Vector2.ZERO else ms.floor_bounds(floor_now).grow(4.0)
	_m_sc = minf(area.size.x / _m_b.size.x, area.size.y / _m_b.size.y)
	_m_off = area.position + (area.size - _m_b.size * _m_sc) * 0.5
	for t in ms.tunnels:
		if ms.is_tunnel_revealed(t):
			_cv.draw_rect(Rect2(_ms(t.position.x, t.position.y), t.size * _m_sc), Color(0.3, 0.32, 0.4, 0.9))
	var labels: Array = []   ## nomes das câmaras: desenhados por último, por cima de abismos e fios
	for r in ms.rooms:
		if not ms.revealed.has(r["id"]):
			continue
		if full and ms.floor_of_room(r) != floor_now:
			continue   # o mapa cheio mostra só o andar onde você está
		var current: bool = String(r["id"]) == ms.current_room
		var fill := Color(0.42, 0.58, 0.72, 0.95) if current else Color(0.3, 0.33, 0.42, 0.95)
		if not ms.grid.is_empty():
			var runs: Array = ms.grid["runs"][r["id"]]
			var lo := Vector2(1e9, 1e9)
			var hi := Vector2(-1e9, -1e9)
			for run in runs:
				var rr: Rect2 = run
				_cv.draw_rect(Rect2(_ms(rr.position.x, rr.position.y), rr.size * _m_sc + Vector2(0.6, 0.6)), fill)
				lo = Vector2(minf(lo.x, rr.position.x), minf(lo.y, rr.position.y))
				hi = Vector2(maxf(hi.x, rr.end.x), maxf(hi.y, rr.end.y))
			if full and not runs.is_empty():
				labels.append([_ms((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5), String(r["id"]), String(r["name"])])
			continue
		var rect: Rect2 = r["rect"]
		var srect := Rect2(_ms(rect.position.x, rect.position.y), rect.size * _m_sc)
		_cv.draw_rect(srect, fill)
		_cv.draw_rect(srect, Color(0.6, 0.65, 0.78, 0.9), false, 1.0)
		if full:
			_text(srect.position.x + 6.0, srect.position.y + 18.0, String(r["id"]), 14, TEXT)
			if srect.size.x > 90.0:
				_text(srect.position.x + 6.0, srect.position.y + 34.0, String(r["name"]), 12, QUIET)
	if not ms.grid.is_empty():
		for pit in ms.grid["pits"]:
			var pr: Rect2 = pit
			var here: Dictionary = ms.room_at(Vector3(pr.position.x + 0.5, 0.0, pr.position.y + 0.5))
			if not here.is_empty() and ms.revealed.has(here["id"]):
				_cv.draw_rect(Rect2(_ms(pr.position.x, pr.position.y), pr.size * _m_sc + Vector2(0.6, 0.6)), Color(0.05, 0.05, 0.08, 0.95))
	for s in WebNetwork.strands:
		if is_instance_valid(s) and _m_b.grow(2.0).has_point(Vector2(s.a_pos.x, s.a_pos.z)):
			var col := Color(0.55, 0.95, 1.0) if s.in_territory else Color(0.9, 0.92, 1.0)
			_cv.draw_line(_ms(s.a_pos.x, s.a_pos.z), _ms(s.b_pos.x, s.b_pos.z), col, 2.0)
	for c in WebNetwork.cocoons:
		if is_instance_valid(c) and _m_b.has_point(Vector2(c.global_position.x, c.global_position.z)):
			_cv.draw_circle(_ms(c.global_position.x, c.global_position.z), 4.0 if not full else 6.0, Color(0.6, 1.0, 0.7))
	var lay = GameState.current_layer
	if lay != null and lay.get("passages") != null:
		for pa in lay.passages:
			var c2: Vector2 = (pa["rect"] as Rect2).get_center()
			var room: Dictionary = ms.room_at(Vector3(c2.x, 0.0, c2.y))
			if room.is_empty() or not ms.revealed.has(room["id"]) or not _m_b.has_point(c2):
				continue
			var pp2 := _ms(c2.x, c2.y)
			var up: bool = (pa["to"] as Vector3).z < c2.y
			var k3 := 5.0 if not full else 8.0
			var tip := Vector2(0, -k3) if up else Vector2(0, k3)
			_cv.draw_colored_polygon(PackedVector2Array([pp2 + tip, pp2 - tip * 0.6 + Vector2(k3, 0), pp2 - tip * 0.6 - Vector2(k3, 0)]), Color(0.8, 0.85, 1.0))
			if full:
				_text(pp2.x + 10.0, pp2.y + 5.0, String(pa["label"]), 12, Color(0.8, 0.85, 1.0))
	for l in ms.locks:
		if l["seen"] and _m_b.has_point(Vector2(l["pos"].x, l["pos"].z)):
			var lp := _ms(l["pos"].x, l["pos"].z)
			var k := 5.0 if not full else 7.0
			_cv.draw_colored_polygon(PackedVector2Array([lp + Vector2(0, -k), lp + Vector2(k, 0), lp + Vector2(0, k), lp + Vector2(-k, 0)]), Color(1.0, 0.7, 0.3))
			if full:
				_text(lp.x + 10.0, lp.y + 5.0, String(LOCK_NAMES.get(l["type"], l["type"])), 12, Color(1.0, 0.8, 0.5))
	# Bichos que você sente pela teia (dentro do território) e a Centopeia quando luta com você
	for c in World.creatures:
		if not is_instance_valid(c) or c.dead:
			continue
		var boss := c as Centipede
		if not _m_b.has_point(Vector2(c.global_position.x, c.global_position.z)):
			continue
		if WebNetwork.is_in_territory(c.global_position) or (boss != null and boss.engaged()):
			var col: Color = [Color(0.6, 1.0, 0.6), Color(1.0, 0.85, 0.35), Color(1.0, 0.35, 0.3), Color(0.85, 0.4, 1.0)][int(c.size)]
			var cp := _ms(c.global_position.x, c.global_position.z)
			_cv.draw_circle(cp, (2.5 + int(c.size) * 1.5) * (1.4 if full else 1.0), col)
	if full and show_all_creatures:
		_draw_all_creatures()
	for lb in labels:
		_text_at_center(lb[0], lb[1], lb[2])
	var pp := _ms(player.global_position.x, player.global_position.z)
	var f := Vector2(player.aim_dir.x, player.aim_dir.z).normalized()
	if f.length() < 0.1:
		f = Vector2(0, -1)
	var side := Vector2(-f.y, f.x)
	var k2 := 6.0 if not full else 9.0
	_cv.draw_colored_polygon(PackedVector2Array([pp + f * k2, pp - f * k2 * 0.6 + side * k2 * 0.6, pp - f * k2 * 0.6 - side * k2 * 0.6]), Color(0.4, 0.9, 1.0))


const SPECIES_COLORS := {
	"Irmã-aranha": Color(0.7, 0.55, 1.0), "Larva-de-musgo": Color(0.55, 0.95, 0.45),
	"Sapo-de-rocha": Color(0.95, 0.8, 0.4), "Morcego-eco": Color(0.95, 0.5, 0.85),
	"Lagarto-lanterna": Color(0.4, 0.95, 0.9), "Centopeia-blindada": Color(1.0, 0.35, 0.3),
}


func _draw_all_creatures() -> void:
	var seen := {}
	for c in World.creatures:
		if not is_instance_valid(c) or c.dead:
			continue
		var key: String = c.display_name
		if c is Sister:
			key = "Irmã-aranha"
		var col: Color = SPECIES_COLORS.get(key, Color.WHITE)
		_cv.draw_circle(_ms(c.global_position.x, c.global_position.z), 3.0 + int(c.size) * 2.0, col)
		seen[key] = col
	var y := 110.0
	for k in seen:
		_cv.draw_circle(Vector2(70.0, y - 5.0), 6.0, seen[k])
		_text(84.0, y, k, 14, TEXT)
		y += 22.0


func _text_at_center(c: Vector2, id: String, name_: String) -> void:
	var w1 := _font.get_string_size(id, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var w2 := _font.get_string_size(name_, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	_text(c.x - w1 * 0.5, c.y - 2.0, id, 15, TEXT)
	_text(c.x - w2 * 0.5, c.y + 14.0, name_, 12, QUIET)
