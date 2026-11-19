class_name BestiaryView
extends Control
## Tela do Bestiário (B, ou pela pausa e pelo casulo). O jogo fica pausado.
##   esquerda: lista por área; quem ainda não foi visto aparece como sombra "???"
##   direita:  retrato, nota da Cavaleira, golpes, sentidos, dica e o que comer dá.
## Teclado: setas (↑↓ bicho, ←→ área), Esc/B fecha. Controle: direcional e B.
## Mouse: clique na lista, rodinha rola.

signal closed

const W := 1600.0
const H := 900.0
const LIST := Rect2(50, 130, 520, 720)
const CARD := Rect2(600, 130, 950, 720)
const CLOSE := Rect2(1400, 46, 150, 40)
const ROW_H := 44.0
const HEAD_H := 40.0
const PIPS := [["eye", "Vista"], ["claw", "Derrotada"], ["fang", "Comida"]]
const EFFECTS := {"pull": "puxa", "slow": "deixa lenta", "acid": "ácido", "web": "prende", "stun": "atordoa",
	"poison": "veneno", "fire": "fogo", "burn": "queima", "line": "em linha", "knock": "empurra"}

var selected := ""
var _rows: Array = []        ## [tipo ("area"/"bicho"), id, y]
var _scroll := 0.0
var _scroll_to := 0.0
var _t := 0.0
var _frame: Control
var _list: Control
var _threads: Array = []
var _hover_close := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for i in 40:
		var a := Vector2(rng.randf_range(-100, W + 100), rng.randf_range(-100, H + 100))
		var ang := rng.randf_range(0.0, PI)
		_threads.append([a - Vector2(cos(ang), sin(ang)) * 900.0, a + Vector2(cos(ang), sin(ang)) * 900.0, rng.randf_range(0.03, 0.08)])
	_frame = Control.new()
	_frame.size = Vector2(W, H)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.draw.connect(_draw_frame)
	add_child(_frame)
	_list = Control.new()
	_list.position = LIST.position + Vector2(10, 64)
	_list.size = LIST.size - Vector2(20, 80)
	_list.clip_contents = true
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.draw.connect(_draw_list)
	_frame.add_child(_list)
	_build_rows()


func open(focus_id := "") -> void:
	_build_rows()
	visible = true
	get_parent().move_child(self, -1)   # por cima do casulo e da pausa
	get_viewport().gui_release_focus()
	if focus_id != "" and Bestiary.entry(focus_id).size() > 0:
		selected = focus_id
	elif selected == "":
		selected = _first_known()
	_scroll_to = _target_scroll()
	_scroll = _scroll_to
	Sfx.play("ui_abrir")


func close() -> void:
	if not visible:
		return
	visible = false
	Settings.block_input(0.25)
	Sfx.play("ui_voltar")
	closed.emit()


func _first_known() -> String:
	for e in Bestiary.entries():
		if Bestiary.tier(e["id"]) > 0:
			return e["id"]
	return Bestiary.entries()[0]["id"]


func _build_rows() -> void:
	_rows.clear()
	var y := 0.0
	for a in Bestiary.AREAS:
		_rows.append(["area", a[0], y])
		y += HEAD_H
		for e in Bestiary.entries():
			if e["area"] == a[0]:
				_rows.append(["bicho", e["id"], y])
				y += ROW_H


func _ids() -> Array:
	return _rows.filter(func(r): return r[0] == "bicho").map(func(r): return r[1])


func _row_y(id: String) -> float:
	for r in _rows:
		if r[0] == "bicho" and r[1] == id:
			return r[2]
	return 0.0


func _target_scroll() -> float:
	## Mantém o selecionado à vista (com o título da área dele, se couber).
	var y := _row_y(selected)
	var view := _list.size.y
	var total: float = _rows[-1][2] + ROW_H
	var s := _scroll_to
	if y - HEAD_H < s:
		s = y - HEAD_H
	elif y + ROW_H > s + view:
		s = y + ROW_H - view
	return clampf(s, 0.0, maxf(0.0, total - view))


func select(id: String) -> void:
	if id == selected:
		return
	selected = id
	_scroll_to = _target_scroll()
	Sfx.play("ui_mover", Vector3.INF, -6.0, 0.08, 0.05)


func _move(step: int) -> void:
	var ids := _ids()
	var i := ids.find(selected)
	select(ids[clampi(i + step, 0, ids.size() - 1)])


func _jump_area(step: int) -> void:
	var cur := String(Bestiary.entry(selected)["area"])
	var keys: Array = Bestiary.AREAS.map(func(a): return a[0])
	var k := clampi(keys.find(cur) + step, 0, keys.size() - 1)
	for e in Bestiary.entries():
		if e["area"] == keys[k]:
			select(e["id"])
			return


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("bestiary"):
		get_viewport().set_input_as_handled()
		close()
		return
	var step := 0
	if event.is_action_pressed("ui_down", true) or event.is_action_pressed("move_down", true):
		step = 1
	elif event.is_action_pressed("ui_up", true) or event.is_action_pressed("move_up", true):
		step = -1
	if step != 0:
		_move(step)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_jump_area(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_jump_area(-1)
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	var p := _to_canvas(get_local_mouse_position())
	if event is InputEventMouseMotion:
		_hover_close = CLOSE.has_point(p)
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			var total: float = _rows[-1][2] + ROW_H
			var d := 60.0 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -60.0
			_scroll_to = clampf(_scroll_to + d, 0.0, maxf(0.0, total - _list.size.y))
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if CLOSE.has_point(p):
				close()
			else:
				var lp := p - _list.position
				if Rect2(Vector2.ZERO, _list.size).has_point(lp):
					for r in _rows:
						if r[0] == "bicho" and lp.y + _scroll >= r[2] and lp.y + _scroll < r[2] + ROW_H:
							select(r[1])
			accept_event()


func _to_canvas(p: Vector2) -> Vector2:
	return (p - _frame.position) / maxf(_frame.scale.x, 0.001)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_scroll = lerpf(_scroll, _scroll_to, minf(1.0, delta * 14.0))
	var vp := get_viewport_rect().size
	var k := minf(vp.x / W, vp.y / H)
	_frame.scale = Vector2(k, k)
	_frame.position = (vp - Vector2(W, H) * k) * 0.5
	queue_redraw()
	_frame.queue_redraw()
	_list.queue_redraw()


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), SilkUI.BG)
	var k := minf(vp.x / W, vp.y / H)
	var off := (vp - Vector2(W, H) * k) * 0.5
	for i in 7:
		draw_circle(off + Vector2(820, 340) * k, (560.0 - i * 70.0) * k, Color(0.15, 0.25, 0.6, 0.025))
	for th in _threads:
		draw_line(off + (th[0] as Vector2) * k, off + (th[1] as Vector2) * k, Color(0.7, 0.8, 1.0, th[2]), 1.0, true)


func _draw_frame() -> void:
	var ci := _frame
	# cabeçalho
	SilkUI.rune(ci, Vector2(76, 78), 16.0, Color(SilkUI.CYAN, 0.85), _t * 0.4)
	SilkUI.text(ci, Vector2(108, 94), "BESTIÁRIO", "title", 42, SilkUI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 3)
	var n := Bestiary.count_seen()
	var tot := Bestiary.entries().size()
	SilkUI.text(ci, Vector2(400, 92), "%d de %d anotadas" % [n, tot], "body_m", 20, SilkUI.QUIET)
	_bar(ci, Rect2(560, 82, 300, 6), float(n) / float(tot))
	SilkUI.frame(ci, CLOSE, SilkUI.GOLD if _hover_close else Color(SilkUI.BORDER, 0.8), Color(0.05, 0.06, 0.13, 0.75))
	SilkUI.text(ci, CLOSE.get_center() + Vector2(0, 6), "Voltar  (Esc)", "body_m", 17, SilkUI.TEXT if _hover_close else SilkUI.QUIET, HORIZONTAL_ALIGNMENT_CENTER)
	# lista
	SilkUI.frame(ci, LIST, Color(SilkUI.BORDER, 0.7), Color(0.04, 0.05, 0.11, 0.85))
	SilkUI.text(ci, LIST.position + Vector2(22, 38), SilkUI.spaced("CRIATURAS"), "title_s", 15, SilkUI.GOLD)
	SilkUI.text(ci, LIST.position + Vector2(LIST.size.x - 20, 38), "↑↓ bicho · ←→ área", "body_m", 14, SilkUI.DIM.lightened(0.2), HORIZONTAL_ALIGNMENT_RIGHT)
	ci.draw_line(LIST.position + Vector2(18, 54), LIST.position + Vector2(LIST.size.x - 18, 54), Color(SilkUI.BORDER, 0.5), 1.0)
	# barra de rolagem
	var total: float = _rows[-1][2] + ROW_H
	if total > _list.size.y:
		var track := Rect2(LIST.end.x - 8, _list.position.y, 3, _list.size.y)
		ci.draw_rect(track, Color(SilkUI.BORDER, 0.3))
		var hgt := track.size.y * _list.size.y / total
		ci.draw_rect(Rect2(track.position.x, track.position.y + (track.size.y - hgt) * _scroll / (total - _list.size.y), 3, hgt), Color(SilkUI.GOLD, 0.6))
	# ficha
	SilkUI.frame(ci, CARD, Color(SilkUI.BORDER, 0.8), Color(0.03, 0.035, 0.08, 0.9))
	_draw_card(ci)


func _bar(ci: CanvasItem, r: Rect2, k: float) -> void:
	ci.draw_rect(r, Color(0, 0, 0, 0.5))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(k, 0.0, 1.0), r.size.y)), SilkUI.CYAN.darkened(0.15))
	ci.draw_rect(r, Color(SilkUI.BORDER, 0.6), false, 1.0)


func _draw_list() -> void:
	var ci := _list
	var w := _list.size.x - 14.0
	for r in _rows:
		var y: float = float(r[2]) - _scroll
		if y < -ROW_H or y > _list.size.y:
			continue
		if r[0] == "area":
			var nm := ""
			for a in Bestiary.AREAS:
				if a[0] == r[1]:
					nm = a[1]
			SilkUI.text(ci, Vector2(6, y + 27), nm.to_upper(), "title_s", 15, Color(SilkUI.GOLD, 0.85))
			var tw := SilkUI.text_width(nm.to_upper(), "title_s", 15)
			SilkUI.thread(ci, Vector2(16 + tw, y + 22), Vector2(w, y + 22), Color(SilkUI.SILK, 0.18), 1.5, 1.0)
			continue
		var id: String = r[1]
		var tier_ := Bestiary.tier(id)
		var on := id == selected
		var row := Rect2(2, y + 3, w, ROW_H - 6)
		if on:
			ci.draw_rect(row, Color(0.12, 0.12, 0.24, 0.9))
			ci.draw_rect(row, Color(SilkUI.GOLD, 0.8), false, 1.2)
			SilkUI.knot(ci, Vector2(row.position.x, row.get_center().y), SilkUI.GOLD, 4.0)
		var tex := Bestiary.portrait(id)
		var th := Rect2(14, y + 5, 34, 34)
		if tex != null:
			ci.draw_texture_rect(tex, th, false, Color(1, 1, 1) if tier_ > 0 else Color(0.06, 0.08, 0.16, 0.95))
		var e := Bestiary.entry(id)
		var nm2 := String(e["name"]) if tier_ > 0 else "???"
		var col := (SilkUI.GOLD if on else SilkUI.TEXT) if tier_ > 0 else SilkUI.DIM
		SilkUI.text(ci, Vector2(60, y + 28), nm2, "body_b", 19, col)
		if tier_ > 0 and e["kind"] != "bicho":
			var tag := {"chefe": "CHEFE", "perigo": "PERIGO", "humano": "HUMANO"}[e["kind"]] as String
			SilkUI.text(ci, Vector2(66 + SilkUI.text_width(nm2, "body_b", 19), y + 27), tag, "title_s", 11, _kind_col(e["kind"]))
		for i in 3:
			var lit := tier_ >= i + 1 and not (i == 2 and e.has("manual"))
			if i == 2 and e.has("manual"):
				continue
			SkillIcons.draw(ci, PIPS[i][0], Vector2(w - 70 + i * 24, y + ROW_H * 0.5), 7.5, SilkUI.CYAN if lit else Color(SilkUI.DIM, 0.45))


func _kind_col(kind: String) -> Color:
	match kind:
		"chefe":
			return Color(1.0, 0.55, 0.45)
		"perigo":
			return Color(0.95, 0.4, 0.6)
		"humano":
			return Color(1.0, 0.75, 0.4)
	return SilkUI.QUIET


func _draw_card(ci: CanvasItem) -> void:
	var id := selected
	var e := Bestiary.entry(id)
	if e.is_empty():
		return
	var tier_ := Bestiary.tier(id)
	var rec := Bestiary.record(id)
	var inf := Bestiary.info(id)
	var area_name := ""
	for a in Bestiary.AREAS:
		if a[0] == e["area"]:
			area_name = a[1]
	# retrato com halo
	var pr := Rect2(CARD.position + Vector2(24, 24), Vector2(380, 380))
	var c := pr.get_center()
	for k in 5:
		ci.draw_circle(c, 180.0 - k * 30.0, Color(SilkUI.CYAN if tier_ > 0 else SilkUI.DIM, 0.03 + 0.008 * sin(_t * 1.3)))
	ci.draw_arc(c, 176.0, 0.0, TAU, 72, Color(SilkUI.BORDER, 0.5), 1.0, true)
	var tex := Bestiary.portrait(id)
	if tex != null:
		var bob := Vector2(0, 3.0 * sin(_t * 1.1))
		ci.draw_texture_rect(tex, Rect2(pr.position + bob, pr.size), false, Color(1, 1, 1) if tier_ > 0 else Color(0.05, 0.07, 0.14, 0.97))
	if tier_ == 0:
		SilkUI.text(ci, c + Vector2(0, 22), "?", "title", 90, Color(SilkUI.DIM, 0.6), HORIZONTAL_ALIGNMENT_CENTER)
	# nome, tipo e progresso
	var x := CARD.position.x + 430.0
	var y := CARD.position.y + 64.0
	var tw := CARD.end.x - x - 30.0
	SilkUI.text(ci, Vector2(x, y), String(e["name"]) if tier_ > 0 else "???", "title", 34, SilkUI.TEXT if tier_ > 0 else SilkUI.DIM, HORIZONTAL_ALIGNMENT_LEFT, 3)
	y += 34.0
	var line := area_name
	if tier_ > 0:
		line += "   ·   Tamanho %s" % String(inf.get("size", "?"))
		if tier_ >= Bestiary.DEFEATED and not (inf.get("hp", 0) is String):
			line += "   ·   %d PV" % int(inf.get("hp", 0))
	SilkUI.text(ci, Vector2(x, y), line, "body_m", 19, SilkUI.QUIET)
	if tier_ > 0 and e["kind"] != "bicho":
		var tag := {"chefe": "Chefe", "perigo": "Perigo · não dá para vencer", "humano": "Humano · a expedição"}[e["kind"]] as String
		y += 28.0
		SilkUI.text(ci, Vector2(x, y), tag, "body_b", 17, _kind_col(e["kind"]))
	y += 34.0
	var px := x
	for i in 3:
		if i == 2 and e.has("manual"):
			continue
		var lit := tier_ >= i + 1
		var label := String(PIPS[i][1])
		if i == 1 and int(rec.get("kills", 0)) > 0:
			label += " ×%d" % int(rec.get("kills", 0))
		if i == 2 and int(rec.get("eaten", 0)) > 0:
			label += " ×%d" % int(rec.get("eaten", 0))
		if e.has("manual") and i == 1:
			label = "Sobrevivi"
		var colp := SilkUI.CYAN if lit else Color(SilkUI.DIM, 0.6)
		SkillIcons.draw(ci, PIPS[i][0], Vector2(px + 9, y - 6), 8.0, colp)
		SilkUI.text(ci, Vector2(px + 24, y), label, "body_m", 16, SilkUI.TEXT if lit else SilkUI.DIM)
		px += 36.0 + SilkUI.text_width(label, "body_m", 16) + 18.0
	y += 26.0
	SilkUI.thread(ci, Vector2(x, y), Vector2(CARD.end.x - 30, y), Color(SilkUI.SILK, 0.22), 2.0)
	y += 34.0
	# nota da Cavaleira
	if tier_ > 0:
		y = _para(ci, Vector2(x, y), tw, "“%s”" % e["note"], "body_m", 20, SilkUI.TEXT.darkened(0.04), 27.0)
	else:
		var prep := "nas" if area_name.begins_with("Galerias") else "no"
		y = _para(ci, Vector2(x, y), tw, "Ainda não vi este bicho. Algo vive %s %s..." % [prep, area_name], "body_m", 20, SilkUI.DIM, 27.0)
	# parte de baixo: golpes | sentidos, dica e comida
	var by := CARD.position.y + 430.0
	var lx := CARD.position.x + 30.0
	var rx := CARD.position.x + 500.0
	var col_w := 420.0
	_section(ci, Vector2(lx, by), "GOLPES")
	if tier_ >= Bestiary.DEFEATED:
		var yy := by + 34.0
		var atk: Array = inf.get("attacks", [])
		if atk.is_empty():
			yy = _para(ci, Vector2(lx, yy), col_w, "Não ataca: foge ou se defende.", "body_m", 18, SilkUI.QUIET, 24.0)
		for a in atk:
			if yy > CARD.end.y - 30.0:
				break
			yy = _attack_row(ci, Vector2(lx, yy), col_w, a)
	else:
		_locked(ci, Vector2(lx, by + 34.0), "Derrote para anotar os golpes." if tier_ > 0 else "—")
	_section(ci, Vector2(rx, by), "SENTIDOS")
	var ry := by + 34.0
	if tier_ >= Bestiary.DEFEATED:
		ry = _para(ci, Vector2(rx, ry), col_w, _cap(String(inf.get("senses", "?"))), "body_m", 18, SilkUI.TEXT.darkened(0.08), 24.0)
	else:
		_locked(ci, Vector2(rx, ry), "Derrote para anotar." if tier_ > 0 else "—")
		ry += 26.0
	ry += 16.0
	_section(ci, Vector2(rx, ry), "COMO LIDAR")
	ry += 34.0
	if tier_ >= Bestiary.DEFEATED:
		ry = _para(ci, Vector2(rx, ry), col_w, String(e["tip"]), "body_m", 18, SilkUI.TEXT.darkened(0.08), 24.0)
	else:
		_locked(ci, Vector2(rx, ry), "Derrote para anotar." if tier_ > 0 else "—")
		ry += 26.0
	if e.has("manual"):
		return
	ry += 16.0
	_section(ci, Vector2(rx, ry), "AO COMER")
	ry += 34.0
	if tier_ >= Bestiary.EATEN:
		_para(ci, Vector2(rx, ry), col_w, _food_text(inf.get("food", {})), "body_m", 18, Color(0.97, 0.8, 0.5), 24.0)
	else:
		_locked(ci, Vector2(rx, ry), "Coma para descobrir." if tier_ > 0 else "—")


func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s.length() > 0 else s


func _section(ci: CanvasItem, p: Vector2, title: String) -> void:
	SilkUI.knot(ci, p + Vector2(4, -6), SilkUI.GOLD, 3.5)
	SilkUI.text(ci, p + Vector2(16, 0), title, "title_s", 15, SilkUI.GOLD)


func _locked(ci: CanvasItem, p: Vector2, s: String) -> void:
	SkillIcons.draw(ci, "lock", p + Vector2(8, -6), 7.0, SilkUI.DIM)
	SilkUI.text(ci, p + Vector2(24, 0), s, "body_m", 17, SilkUI.DIM.lightened(0.15))


func _attack_row(ci: CanvasItem, p: Vector2, width: float, a) -> float:
	var nm := String(a[0])
	var dmg := String(a[1]) if a[1] is String else "%d" % int(a[1])
	var fx := String(a[2]) if a.size() > 2 else ""
	var furious: bool = a.size() > 3 and bool(a[3])
	SilkUI.text(ci, p, "•  " + nm, "body_b", 18, SilkUI.TEXT)
	var x := p.x + SilkUI.text_width("•  " + nm, "body_b", 18) + 12.0
	if a[1] is String:
		# golpe escrito à mão (perigos): a descrição vem na linha de baixo
		return _para(ci, Vector2(p.x + 20, p.y + 24), width - 20.0, String(a[1]), "body_m", 16, SilkUI.QUIET, 22.0) + 4.0
	if int(a[1]) > 0:
		SilkUI.text(ci, Vector2(x, p.y), "%s de dano" % dmg, "body_m", 17, Color(1.0, 0.6, 0.55))
		x += SilkUI.text_width("%s de dano" % dmg, "body_m", 17) + 12.0
	var tags: Array = []
	if EFFECTS.has(fx):
		tags.append(EFFECTS[fx])
	if furious:
		tags.append("só furiosa")
	for t in tags:
		var tw2 := SilkUI.text_width(t, "body_b", 13) + 16.0
		if x + tw2 > p.x + width:
			break
		var r := Rect2(x, p.y - 15, tw2, 20)
		ci.draw_rect(r, Color(0.1, 0.12, 0.22, 0.9))
		ci.draw_rect(r, Color(SilkUI.BORDER, 0.7), false, 1.0)
		SilkUI.text(ci, Vector2(x + 8, p.y), t, "body_b", 13, SilkUI.QUIET)
		x += tw2 + 6.0
	return p.y + 28.0


func _food_text(f: Dictionary) -> String:
	if f.is_empty():
		return "?"
	var parts: Array = ["+%d saciedade, +%d seda, +%d XP" % [int(f.get("satiety", 0)), int(f.get("silk", 0)), int(f.get("xp", 0))]]
	if float(f.get("energy", 0.0)) > 0.0:
		parts.append("Energia máxima +%d" % int(f["energy"]))
	if int(f.get("acid", 0)) > 0:
		parts.append("Resistência a Ácido +%d" % int(f["acid"]))
	if int(f.get("fire", 0)) > 0:
		parts.append("Resistência a Fogo +%d" % int(f["fire"]))
	if int(f.get("poison", 0)) > 0:
		parts.append("Resistência a Veneno +%d (envenena um pouco)" % int(f["poison"]))
	if bool(f.get("skin", false)):
		parts.append("Pele de Cristal")
	return ". ".join(parts) + "."


func _para(ci: CanvasItem, p: Vector2, width: float, s: String, f: String, fsize: int, col: Color, line_h: float) -> float:
	## Texto com quebra de linha; devolve o y da próxima linha.
	var y := p.y
	var cur := ""
	for word in s.split(" "):
		var test := word if cur == "" else cur + " " + word
		if cur != "" and SilkUI.text_width(test, f, fsize) > width:
			SilkUI.text(ci, Vector2(p.x, y), cur, f, fsize, col)
			y += line_h
			cur = word
		else:
			cur = test
	if cur != "":
		SilkUI.text(ci, Vector2(p.x, y), cur, f, fsize, col)
		y += line_h
	return y
