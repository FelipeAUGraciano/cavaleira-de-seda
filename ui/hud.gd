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
const HELP_LINES := [
	"CONTROLES (H esconde)",
	"WASD mover · Mouse mirar · Shift correr",
	"Botão esq. ataque (combo x3) · Botão dir. mordida (veneno)",
	"Espaço esquiva (parada = backstep)",
	"Q lançar fio: puxa presa pequena ou te puxa até a parede",
	"Segurar R: Modo Tecelagem (câmera lenta)",
	"   clique em 2 pilares = fio-guia (5 seda)",
	"   botão dir. = teia de captura (15 seda, nível 3)",
	"C tecer casulo (30 seda) · E comer / descansar",
	"F apagar/acender runa (furtividade)",
	"Segurar Alt ou Tab: Leitura da criatura sob o cursor",
	"M mapa · Esc pausa / menu · F1 +1 nível (teste) · F8 novo jogo",
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
var _title := ""
var _subtitle := ""
var _title_time := 0.0
const TITLE_SECS := 5.0   ## (capturas/depuração) mostra todas as criaturas no mapa, com legenda
var _pause_box: MenuBox
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
	_pause_box = MenuBox.new()
	_pause_box.visible = false
	center.add_child(_pause_box)
	_cv = _root
	_font = ThemeDB.fallback_font
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
	if Input.is_action_just_pressed("map"):
		_show_map = not _show_map

	if Input.is_action_just_pressed("help"):
		_show_help = not _show_help
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
	_mini.visible = _map_system() != null and not _show_map and player != null
	_root.queue_redraw()
	_mini.queue_redraw()


# ---------------------------------------------------------------- pausa

func open_pause() -> void:
	get_tree().paused = true
	_pause_box.clear()
	_pause_box.add_button("Voltar ao jogo", close_pause)
	_pause_box.add_button("Esconder controles" if _show_help else "Mostrar controles", _toggle_help_from_pause)
	_pause_box.add_button("Menu inicial", GameState.to_title)
	_pause_box.add_label("O jogo salva quando você descansa num casulo.\nO que fez depois disso se perde ao sair.", 15, QUIET)
	_pause_box.add_button("Sair do jogo", func(): get_tree().quit(), true)
	_pause_box.visible = true
	_pause_box.focus_first()


func close_pause() -> void:
	_pause_box.visible = false
	get_tree().paused = false


func _toggle_help_from_pause() -> void:
	_show_help = not _show_help
	open_pause()
	MenuBox.focus_later(_pause_box.buttons()[1])


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
	_on_message("Vibração! %s tocou sua teia (%s, %d m)." % [who, _direction_name(d), int(Vector2(d.x, d.z).length())])


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
	if player != null and is_instance_valid(player):
		_draw_bars(vp)
		_draw_status(vp)
		_draw_boss(vp)
		_draw_danger(vp)
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
	_draw_messages()
	if _hint_time > 0.0 and not _show_map:
		var alpha_h := clampf(_hint_time, 0.0, 1.0)
		var tw := _font.get_string_size(_hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		_cv.draw_rect(Rect2(vp.x * 0.5 - tw * 0.5 - 18.0, 92.0, tw + 36.0, 38.0), Color(0.05, 0.12, 0.16, 0.8 * alpha_h))
		_text_center(vp.x, 117.0, _hint_text, 16, Color(0.75, 0.95, 1.0, alpha_h))
	if _mono_time > 0.0:
		var alpha := clampf(_mono_time, 0.0, 1.0)
		var mono_y := vp.y - 240.0 if (player != null and player.weaving) else vp.y - 200.0
		_text_center(vp.x, mono_y, "Cavaleira: \"%s\"" % _mono_text, 20, Color(0.75, 0.92, 1.0, alpha))
	if _big_time > 0.0:
		_text_center(vp.x, vp.y * 0.42, _big_text, 34, Color(1, 1, 1, clampf(_big_time, 0.0, 1.0)))
	if get_tree().paused:
		_cv.draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.65))
		_text_center(vp.x, vp.y * 0.5 - 170.0, "PAUSA", 40, TEXT)
	_draw_transition(vp)   # por último: tela preta e título por cima de tudo

func _draw_bars(vp: Vector2) -> void:
	var x := 24.0
	var y := vp.y - 150.0
	_cv.draw_rect(Rect2(x - 12.0, y - 14.0, 390.0, 152.0), Color(0, 0, 0, 0.45))
	_bar(x, y, "PV", player.hp, player.max_hp, Color(0.85, 0.3, 0.35))
	_bar(x, y + 24.0, "Energia", player.energy, player.max_energy, Color(0.3, 0.8, 1.0))
	_bar(x, y + 48.0, "Seda", player.silk, player.max_silk, Color(0.85, 0.88, 0.95))
	_bar(x, y + 72.0, "Saciedade", player.satiety, player.max_satiety, Color(0.95, 0.7, 0.25))
	_text(x, y + 112.0, "Nível %d   XP %d / %d" % [player.level, player.xp, player.xp_to_next()], 15, TEXT)


func fade(to: float, secs: float) -> Signal:
	## Escurece (to = 1) ou clareia (to = 0) a tela. Devolve o sinal de fim para await.
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, "fade_alpha", to, secs)
	return tw.finished


func show_title(title: String, subtitle: String) -> void:
	_title = title
	_subtitle = subtitle
	_title_time = TITLE_SECS


func _draw_transition(vp: Vector2) -> void:
	if fade_alpha > 0.001:
		_cv.draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, fade_alpha))
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


func _bar(x: float, y: float, label: String, value: float, max_value: float, color: Color) -> void:
	_text(x, y + 13.0, label, 14, QUIET)
	var bx := x + 90.0
	_cv.draw_rect(Rect2(bx, y + 2.0, 220.0, 12.0), Color(0, 0, 0, 0.6))
	_cv.draw_rect(Rect2(bx, y + 2.0, 220.0 * clampf(value / max_value, 0.0, 1.0), 12.0), color)
	_text(bx + 228.0, y + 13.0, "%d/%d" % [int(value), int(max_value)], 13, QUIET)


func _draw_status(vp: Vector2) -> void:
	var tags: Array[String] = []
	if player.in_territory:
		tags.append("No território")
	if player.on_strand:
		tags.append("Sobre fio (rápida e silenciosa)")
	if not player.rune_on:
		tags.append("Runa apagada (furtiva)")
	if player.satiety <= 0.0:
		tags.append("FAMINTA")
	if not tags.is_empty():
		_text(24.0, vp.y - 172.0, " · ".join(tags), 15, Color(0.6, 0.95, 1.0))


func _draw_weave_hint(vp: Vector2) -> void:
	var lines := [
		"MODO TECELAGEM — tempo a 25%, gasta Energia",
		"Clique em 2 pilares para esticar um fio-guia (5 seda, até 12 m)",
		"Botão direito: teia de captura no cursor (15 seda, nível 3) · C: casulo (30 seda)",
	]
	var y := vp.y - 110.0
	_cv.draw_rect(Rect2(vp.x * 0.5 - 380.0, y - 26.0, 760.0, 84.0), Color(0, 0, 0, 0.5))
	for i in lines.size():
		_text_center(vp.x, y + i * 22.0, lines[i], 16 if i == 0 else 14, TEXT if i == 0 else QUIET)


func _draw_help(vp: Vector2) -> void:
	var x := vp.x - 440.0
	var y := 240.0
	_cv.draw_rect(Rect2(x - 12.0, y - 6.0, 436.0, HELP_LINES.size() * 20.0 + 16.0), Color(0, 0, 0, 0.45))
	for i in HELP_LINES.size():
		_text(x, y + 14.0 + i * 20.0, HELP_LINES[i], 14 if i == 0 else 13, TEXT if i == 0 else QUIET)


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


# ---------------------------------------------------------------- mapa

func _map_system():
	var layer = GameState.current_layer
	if layer == null or not is_instance_valid(layer):
		return null
	return layer.map_system


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
	_cv.draw_rect(area, Color(0.6, 0.65, 0.78, 0.6), false, 1.0)
	_cv = _root


func _draw_minimap(ms, vp: Vector2) -> void:
	var area := Rect2(vp.x - 254.0, 20.0, 230.0, 160.0)
	var room_name := ""
	var here: Dictionary = ms.room_at(player.global_position)
	if not here.is_empty():
		room_name = "%s · %s" % [here["id"], here["name"]]
	_text(area.position.x + 8.0, area.position.y + area.size.y + 16.0, room_name, 13, QUIET)
	if World.clock != null:
		var left := int(World.clock.seconds_to_change())
		var col := Color(0.65, 1.0, 0.75) if World.clock.phase == CaveClock.Phase.BRILHO else Color(0.75, 0.65, 1.0)
		_text(area.position.x + 8.0, area.position.y + area.size.y + 34.0, "%s (%d:%02d)" % [CaveClock.NAMES[World.clock.phase], left / 60, left % 60], 12, col)


func _draw_full_map(ms, vp: Vector2) -> void:
	_cv.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.01, 0.01, 0.02, 0.88))
	_text(60.0, 50.0, "MAPA — %s" % ms.layer_name, 22, TEXT)
	_text(60.0, 74.0, "M fecha · câmaras aparecem quando você entra nelas · losangos = travas já vistas", 14, QUIET)
	_draw_map(ms, Rect2(60.0, 96.0, vp.x - 120.0, vp.y - 170.0), true)


func _ms(x: float, z: float) -> Vector2:
	return _m_off + (Vector2(x, z) - _m_b.position) * _m_sc


func _draw_map(ms, area: Rect2, full: bool, view: Rect2 = Rect2()) -> void:
	_m_b = view if view.size != Vector2.ZERO else ms.bounds().grow(2.0)
	_m_sc = minf(area.size.x / _m_b.size.x, area.size.y / _m_b.size.y)
	_m_off = area.position + (area.size - _m_b.size * _m_sc) * 0.5
	for t in ms.tunnels:
		if ms.is_tunnel_revealed(t):
			_cv.draw_rect(Rect2(_ms(t.position.x, t.position.y), t.size * _m_sc), Color(0.3, 0.32, 0.4, 0.9))
	var labels: Array = []   ## nomes das câmaras: desenhados por último, por cima de abismos e fios
	for r in ms.rooms:
		if not ms.revealed.has(r["id"]):
			continue
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
		if is_instance_valid(s):
			var col := Color(0.55, 0.95, 1.0) if s.in_territory else Color(0.9, 0.92, 1.0)
			_cv.draw_line(_ms(s.a_pos.x, s.a_pos.z), _ms(s.b_pos.x, s.b_pos.z), col, 2.0)
	for c in WebNetwork.cocoons:
		if is_instance_valid(c):
			_cv.draw_circle(_ms(c.global_position.x, c.global_position.z), 4.0 if not full else 6.0, Color(0.6, 1.0, 0.7))
	for l in ms.locks:
		if l["seen"]:
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
