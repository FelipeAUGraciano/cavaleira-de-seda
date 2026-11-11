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
	"Esc pausa · F1 +1 nível (teste) · F8 apagar save",
]

var player: Player = null
var _root: Control
var _font: Font
var _messages: Array = []        ## [texto, tempo restante]
var _mono_text := ""
var _mono_time := 0.0
var _big_text := ""
var _big_time := 0.0
var _show_help := true
var _last_us := 0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.draw.connect(_on_draw)
	_font = ThemeDB.fallback_font
	EventBus.message.connect(_on_message)
	EventBus.big_message.connect(_on_big_message)
	EventBus.monologue.connect(_on_monologue)
	EventBus.web_touched.connect(_on_web_touched)
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

	if Input.is_action_just_pressed("help"):
		_show_help = not _show_help
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
	if Input.is_action_just_pressed("debug_reset"):
		GameState.reset_run()
		return
	_root.queue_redraw()


# ---------------------------------------------------------------- eventos

func _on_message(text: String) -> void:
	_messages.append([text, MSG_TIME])
	if _messages.size() > 6:
		_messages.pop_front()


func _on_big_message(text: String) -> void:
	_big_text = text
	_big_time = 4.0


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
	var vp := _root.get_viewport_rect().size
	if player != null and is_instance_valid(player):
		_draw_bars(vp)
		_draw_status(vp)
		if player.weaving:
			_draw_weave_hint(vp)
		if Input.is_action_pressed("read"):
			_draw_reading(vp)
		elif _show_help:
			_draw_help(vp)
	_draw_messages()
	if _mono_time > 0.0:
		var alpha := clampf(_mono_time, 0.0, 1.0)
		var mono_y := vp.y - 240.0 if (player != null and player.weaving) else vp.y - 200.0
		_text_center(vp.x, mono_y, "Cavaleira: \"%s\"" % _mono_text, 20, Color(0.75, 0.92, 1.0, alpha))
	if _big_time > 0.0:
		_text_center(vp.x, vp.y * 0.42, _big_text, 34, Color(1, 1, 1, clampf(_big_time, 0.0, 1.0)))
	if get_tree().paused:
		_root.draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.5))
		_text_center(vp.x, vp.y * 0.45, "PAUSA — Esc para voltar", 32, TEXT)


func _draw_bars(vp: Vector2) -> void:
	var x := 24.0
	var y := vp.y - 150.0
	_root.draw_rect(Rect2(x - 12.0, y - 14.0, 390.0, 152.0), Color(0, 0, 0, 0.45))
	_bar(x, y, "PV", player.hp, player.max_hp, Color(0.85, 0.3, 0.35))
	_bar(x, y + 24.0, "Energia", player.energy, player.max_energy, Color(0.3, 0.8, 1.0))
	_bar(x, y + 48.0, "Seda", player.silk, player.max_silk, Color(0.85, 0.88, 0.95))
	_bar(x, y + 72.0, "Saciedade", player.satiety, player.max_satiety, Color(0.95, 0.7, 0.25))
	_text(x, y + 112.0, "Nível %d   XP %d / %d" % [player.level, player.xp, player.xp_to_next()], 15, TEXT)


func _bar(x: float, y: float, label: String, value: float, max_value: float, color: Color) -> void:
	_text(x, y + 13.0, label, 14, QUIET)
	var bx := x + 90.0
	_root.draw_rect(Rect2(bx, y + 2.0, 220.0, 12.0), Color(0, 0, 0, 0.6))
	_root.draw_rect(Rect2(bx, y + 2.0, 220.0 * clampf(value / max_value, 0.0, 1.0), 12.0), color)
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
	_root.draw_rect(Rect2(vp.x * 0.5 - 380.0, y - 26.0, 760.0, 84.0), Color(0, 0, 0, 0.5))
	for i in lines.size():
		_text_center(vp.x, y + i * 22.0, lines[i], 16 if i == 0 else 14, TEXT if i == 0 else QUIET)


func _draw_help(vp: Vector2) -> void:
	var x := vp.x - 440.0
	var y := 24.0
	_root.draw_rect(Rect2(x - 12.0, y - 6.0, 436.0, HELP_LINES.size() * 20.0 + 16.0), Color(0, 0, 0, 0.45))
	for i in HELP_LINES.size():
		_text(x, y + 14.0 + i * 20.0, HELP_LINES[i], 14 if i == 0 else 13, TEXT if i == 0 else QUIET)


func _draw_reading(vp: Vector2) -> void:
	var x := vp.x - 380.0
	var y := 24.0
	_root.draw_rect(Rect2(x - 12.0, y - 6.0, 376.0, 150.0), Color(0, 0, 0, 0.55))
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


func _draw_messages() -> void:
	var y := 30.0
	for m in _messages:
		var alpha := clampf(float(m[1]), 0.0, 1.0)
		_text(24.0, y, String(m[0]), 15, Color(TEXT.r, TEXT.g, TEXT.b, alpha))
		y += 22.0


func _creature_near(point: Vector3, radius: float) -> Creature:
	var best: Creature = null
	var best_d := radius
	for n in get_tree().get_nodes_in_group("creature"):
		var c := n as Creature
		if c == null or c.dead:
			continue
		var d := Fx.flat_dist(c.global_position, point)
		if d < best_d:
			best = c
			best_d = d
	return best


func _text(x: float, y: float, s: String, size: int, color: Color) -> void:
	_root.draw_string_outline(_font, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0, color.a * 0.8))
	_root.draw_string(_font, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _text_center(width: float, y: float, s: String, size: int, color: Color) -> void:
	_root.draw_string_outline(_font, Vector2(0.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, width, size, 4, Color(0, 0, 0, color.a * 0.8))
	_root.draw_string(_font, Vector2(0.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)
