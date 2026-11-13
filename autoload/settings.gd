extends Node
## Opções do jogador (som, tela, controles) e o último espaço de save usado.
## Ficam em user://opcoes.cfg, separadas do save: valem para todos os espaços.

signal changed

const PATH := "user://opcoes.cfg"
const BUSES := ["Música", "Efeitos", "Voz"]

## Ações que dá para trocar: [ação, nome, teclado/mouse?, controle?]
const REMAP := [
	["move_up", "Andar para cima", true, false],
	["move_down", "Andar para baixo", true, false],
	["move_left", "Andar para a esquerda", true, false],
	["move_right", "Andar para a direita", true, false],
	["run", "Correr", true, true],
	["attack", "Ataque (combo)", true, true],
	["bite", "Mordida / teia de captura", true, true],
	["dodge", "Esquiva", true, true],
	["throw_silk", "Lançar fio", true, true],
	["weave", "Modo Tecelagem (segurar)", true, true],
	["read", "Leitura da criatura (segurar)", true, true],
	["interact", "Comer / descansar / ler", true, true],
	["rune", "Apagar / acender runa", true, true],
	["cocoon", "Tecer casulo", true, true],
	["map", "Mapa", true, true],
	["help", "Mostrar controles", true, true],
	["pause", "Pausa", true, true],
]

var volume := {"Master": 0.8, "Música": 0.7, "Efeitos": 0.8, "Voz": 1.0}
var fullscreen := false
var brightness := 1.0           ## 0.7 a 1.6 (o jogo é escuro de propósito; isso ajuda telas escuras)
var show_help := true           ## lista de controles no canto da tela
var slot := 1                   ## último espaço de save usado
var capturing := false          ## esperando o jogador apertar a tecla nova (o HUD ignora a entrada)
var _block_until := 0
var _defaults := {}             ## ação -> eventos originais
var _binds := {}                ## ação -> {"kb": [dict], "pad": [dict]} trocados pelo jogador


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in BUSES:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	for r in REMAP:
		_defaults[r[0]] = InputMap.action_get_events(r[0]).duplicate()
	load_cfg()
	apply()


func block_input(sec: float) -> void:
	## Depois de fechar as Opções ou trocar uma tecla, o HUD ignora a entrada um instante
	## (senão o mesmo Esc que fechou a tela também despausava o jogo).
	_block_until = Time.get_ticks_msec() + int(sec * 1000.0)


func input_blocked() -> bool:
	return capturing or Time.get_ticks_msec() < _block_until


# ---------------------------------------------------------------- aplicar e guardar

func apply() -> void:
	for b in volume:
		var i := AudioServer.get_bus_index(b)
		if i >= 0:
			var v := float(volume[b])
			AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
			AudioServer.set_bus_mute(i, v <= 0.001)
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	GameState.slot = slot
	changed.emit()


func load_cfg() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	for b in volume.keys():
		volume[b] = clampf(float(cf.get_value("som", b, volume[b])), 0.0, 1.0)
	fullscreen = bool(cf.get_value("tela", "tela_cheia", fullscreen))
	brightness = clampf(float(cf.get_value("tela", "brilho", brightness)), 0.7, 1.6)
	show_help = bool(cf.get_value("tela", "mostrar_controles", show_help))
	slot = clampi(int(cf.get_value("save", "espaco", slot)), 1, GameState.SLOTS)
	var binds = cf.get_value("controles", "trocas", {})
	if binds is Dictionary:
		_binds = binds
	_apply_binds()


func save_cfg() -> void:
	var cf := ConfigFile.new()
	for b in volume:
		cf.set_value("som", b, volume[b])
	cf.set_value("tela", "tela_cheia", fullscreen)
	cf.set_value("tela", "brilho", brightness)
	cf.set_value("tela", "mostrar_controles", show_help)
	cf.set_value("save", "espaco", slot)
	cf.set_value("controles", "trocas", _binds)
	cf.save(PATH)


func set_value(key: String, value) -> void:
	## Atalho para o menu: muda, aplica e grava.
	if volume.has(key):
		volume[key] = clampf(float(value), 0.0, 1.0)
	elif key == "tela_cheia":
		fullscreen = bool(value)
	elif key == "brilho":
		brightness = clampf(float(value), 0.7, 1.6)
	elif key == "mostrar_controles":
		show_help = bool(value)
	elif key == "espaco":
		slot = clampi(int(value), 1, GameState.SLOTS)
	apply()
	save_cfg()


func reset_all() -> void:
	volume = {"Master": 0.8, "Música": 0.7, "Efeitos": 0.8, "Voz": 1.0}
	fullscreen = false
	brightness = 1.0
	show_help = true
	reset_controls()


# ---------------------------------------------------------------- controles

func is_kb(e: InputEvent) -> bool:
	return e is InputEventKey or e is InputEventMouseButton


func is_pad(e: InputEvent) -> bool:
	return e is InputEventJoypadButton or e is InputEventJoypadMotion


func binding(action: String, pad: bool) -> InputEvent:
	## A tecla principal da ação (a primeira do tipo pedido).
	if not InputMap.has_action(action):
		return null
	for e in InputMap.action_get_events(action):
		if (pad and is_pad(e)) or (not pad and is_kb(e)):
			return e
	return null


func bind(action: String, pad: bool, ev: InputEvent) -> String:
	## Troca a tecla da ação. Se outra ação usava essa tecla, as duas trocam de lugar.
	## Devolve o nome da ação que trocou (ou "").
	var kind := "pad" if pad else "kb"
	var old := binding(action, pad)
	var swapped := ""
	for r in REMAP:
		var other: String = r[0]
		if other == action:
			continue
		for e in InputMap.action_get_events(other):
			if _same(e, ev):
				_set_kind(other, kind, [old] if old != null else [])
				swapped = String(r[1])
				break
	_set_kind(action, kind, [ev])
	save_cfg()
	changed.emit()
	return swapped


func reset_controls() -> void:
	_binds = {}
	for a in _defaults:
		InputMap.action_erase_events(a)
		for e in _defaults[a]:
			InputMap.action_add_event(a, e)
	save_cfg()
	changed.emit()


func _set_kind(action: String, kind: String, events: Array) -> void:
	for e in InputMap.action_get_events(action):
		if (kind == "pad" and is_pad(e)) or (kind == "kb" and is_kb(e)):
			InputMap.action_erase_event(action, e)
	var stored: Array = []
	for e in events:
		InputMap.action_add_event(action, e)
		stored.append(_to_dict(e))
	var d: Dictionary = _binds.get(action, {})
	d[kind] = stored
	_binds[action] = d


func _apply_binds() -> void:
	for a in _binds:
		if not InputMap.has_action(a):
			continue
		var d: Dictionary = _binds[a]
		for kind in d:
			var evs: Array = []
			for ed in d[kind]:
				var e := _from_dict(ed)
				if e != null:
					evs.append(e)
			for e in InputMap.action_get_events(a):
				if (kind == "pad" and is_pad(e)) or (kind == "kb" and is_kb(e)):
					InputMap.action_erase_event(a, e)
			for e in evs:
				InputMap.action_add_event(a, e)


func _same(a: InputEvent, b: InputEvent) -> bool:
	return _to_dict(a) == _to_dict(b)


func _to_dict(e: InputEvent) -> Dictionary:
	if e is InputEventKey:
		var k := e as InputEventKey
		return {"t": "key", "c": int(k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode)}
	if e is InputEventMouseButton:
		return {"t": "mouse", "b": int((e as InputEventMouseButton).button_index)}
	if e is InputEventJoypadButton:
		return {"t": "jb", "b": int((e as InputEventJoypadButton).button_index)}
	if e is InputEventJoypadMotion:
		var m := e as InputEventJoypadMotion
		return {"t": "ja", "a": int(m.axis), "v": 1.0 if m.axis_value > 0.0 else -1.0}
	return {}


func _from_dict(d) -> InputEvent:
	if not (d is Dictionary):
		return null
	match String(d.get("t", "")):
		"key":
			var k := InputEventKey.new()
			k.physical_keycode = int(d["c"])
			return k
		"mouse":
			var m := InputEventMouseButton.new()
			m.button_index = int(d["b"])
			return m
		"jb":
			var j := InputEventJoypadButton.new()
			j.button_index = int(d["b"])
			return j
		"ja":
			var a := InputEventJoypadMotion.new()
			a.axis = int(d["a"])
			a.axis_value = float(d["v"])
			return a
	return null


func capture_ok(e: InputEvent, pad: bool) -> InputEvent:
	## Evento que serve como tecla nova (ou null). Para eixos, só um empurrão forte.
	if pad:
		if e is InputEventJoypadButton and e.pressed:
			var j := InputEventJoypadButton.new()
			j.button_index = (e as InputEventJoypadButton).button_index
			return j
		if e is InputEventJoypadMotion and absf((e as InputEventJoypadMotion).axis_value) > 0.7:
			var m := e as InputEventJoypadMotion
			if m.axis == JOY_AXIS_LEFT_X or m.axis == JOY_AXIS_LEFT_Y:
				return null   # o analógico esquerdo é do movimento
			var a := InputEventJoypadMotion.new()
			a.axis = m.axis
			a.axis_value = 1.0 if m.axis_value > 0.0 else -1.0
			return a
		return null
	if e is InputEventKey and e.pressed and not e.echo:
		var k := InputEventKey.new()
		var src := e as InputEventKey
		k.physical_keycode = src.physical_keycode if src.physical_keycode != KEY_NONE else src.keycode
		return k
	if e is InputEventMouseButton and e.pressed:
		var b := (e as InputEventMouseButton).button_index
		if b == MOUSE_BUTTON_WHEEL_UP or b == MOUSE_BUTTON_WHEEL_DOWN:
			return null
		var mb := InputEventMouseButton.new()
		mb.button_index = b
		return mb
	return null


# ---------------------------------------------------------------- nomes das teclas

func text(action: String, pad := false) -> String:
	var e := binding(action, pad)
	return event_text(e) if e != null else "—"


func move_text() -> String:
	var s := ""
	for a in ["move_up", "move_left", "move_down", "move_right"]:
		s += text(a)
	return s if s.length() == 4 else "%s/%s/%s/%s" % [text("move_up"), text("move_left"), text("move_down"), text("move_right")]


func event_text(e: InputEvent) -> String:
	if e is InputEventKey:
		var k := e as InputEventKey
		var code := k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
		var names := {KEY_SPACE: "Espaço", KEY_ESCAPE: "Esc", KEY_SHIFT: "Shift", KEY_CTRL: "Ctrl", KEY_ALT: "Alt",
			KEY_TAB: "Tab", KEY_ENTER: "Enter", KEY_BACKSPACE: "Backspace", KEY_UP: "↑", KEY_DOWN: "↓",
			KEY_LEFT: "←", KEY_RIGHT: "→", KEY_CAPSLOCK: "Caps Lock"}
		if names.has(code):
			return names[code]
		return OS.get_keycode_string(code)
	if e is InputEventMouseButton:
		var mb := {MOUSE_BUTTON_LEFT: "Botão esq.", MOUSE_BUTTON_RIGHT: "Botão dir.", MOUSE_BUTTON_MIDDLE: "Botão do meio",
			MOUSE_BUTTON_XBUTTON1: "Botão lateral 1", MOUSE_BUTTON_XBUTTON2: "Botão lateral 2"}
		return mb.get((e as InputEventMouseButton).button_index, "Mouse %d" % (e as InputEventMouseButton).button_index)
	if e is InputEventJoypadButton:
		var jb := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
			JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_BACK: "Select",
			JOY_BUTTON_START: "Start", JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
			JOY_BUTTON_DPAD_UP: "Direcional ↑", JOY_BUTTON_DPAD_DOWN: "Direcional ↓",
			JOY_BUTTON_DPAD_LEFT: "Direcional ←", JOY_BUTTON_DPAD_RIGHT: "Direcional →", JOY_BUTTON_GUIDE: "Guia"}
		return jb.get((e as InputEventJoypadButton).button_index, "Botão %d" % (e as InputEventJoypadButton).button_index)
	if e is InputEventJoypadMotion:
		var m := e as InputEventJoypadMotion
		match m.axis:
			JOY_AXIS_TRIGGER_LEFT:
				return "LT"
			JOY_AXIS_TRIGGER_RIGHT:
				return "RT"
			JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y:
				return "Analógico esq."
			JOY_AXIS_RIGHT_X:
				return "Analógico dir. " + ("→" if m.axis_value > 0.0 else "←")
			JOY_AXIS_RIGHT_Y:
				return "Analógico dir. " + ("↓" if m.axis_value > 0.0 else "↑")
	return "?"
