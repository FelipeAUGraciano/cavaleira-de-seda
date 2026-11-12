extends Node
## Estado global: mapa de controles, falas já ditas e save/load.

const SAVE_PATH := "user://save.json"

## Referência para a jogadora ativa (definida pela própria jogadora no _ready).
var player = null
## Falas do monólogo que já tocaram (cada uma toca uma vez só).
var said: Dictionary = {}
## Camada atual (LayerBase) e itens/eventos únicos já resolvidos.
var current_layer = null
var flags: Dictionary = {}
## Atributos levados de uma camada para a próxima.
var carry: Dictionary = {}


func _ready() -> void:
	_setup_input()


# ---------------------------------------------------------------- falas

func say_once(id: String, text: String) -> void:
	if said.has(id):
		return
	said[id] = true
	EventBus.monologue.emit(id, text)


# ---------------------------------------------------------------- save

func save_now() -> void:
	if player == null:
		return
	var data := {
		"version": 2,
		"scene": current_layer.scene_file_path if current_layer != null else "",
		"player": player.to_dict(),
		"web": WebNetwork.to_dict(),
		"map": current_layer.map_system.to_dict() if current_layer != null else {},
		"said": said,
		"flags": flags,
		"clock": World.clock.t if World.clock != null else 0.0,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		return parsed
	return {}


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


const TITLE_SCENE := "res://world/title.tscn"
const FIRST_LAYER := "res://world/layers/bercario.tscn"


func new_game() -> void:
	## Apaga o save e começa do Berçário (menu inicial ou F8).
	_clear_run()
	delete_save()
	get_tree().change_scene_to_file.call_deferred(FIRST_LAYER)


func continue_game() -> void:
	## Abre a camada do último casulo (o boot lê o save).
	_clear_run()
	get_tree().change_scene_to_file.call_deferred("res://world/main.tscn")


func to_title() -> void:
	## Volta ao menu inicial. O que não foi salvo num casulo se perde.
	_clear_run()
	get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)


func reset_run() -> void:
	new_game()


func _clear_run() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	said = {}
	flags = {}
	carry = {}
	player = null
	current_layer = null


# ---------------------------------------------------------------- controles

func _setup_input() -> void:
	_add("move_left", [_k(KEY_A), _k(KEY_LEFT), _ja(JOY_AXIS_LEFT_X, -1.0)])
	_add("move_right", [_k(KEY_D), _k(KEY_RIGHT), _ja(JOY_AXIS_LEFT_X, 1.0)])
	_add("move_up", [_k(KEY_W), _k(KEY_UP), _ja(JOY_AXIS_LEFT_Y, -1.0)])
	_add("move_down", [_k(KEY_S), _k(KEY_DOWN), _ja(JOY_AXIS_LEFT_Y, 1.0)])
	_add("aim_left", [_ja(JOY_AXIS_RIGHT_X, -1.0)])
	_add("aim_right", [_ja(JOY_AXIS_RIGHT_X, 1.0)])
	_add("aim_up", [_ja(JOY_AXIS_RIGHT_Y, -1.0)])
	_add("aim_down", [_ja(JOY_AXIS_RIGHT_Y, 1.0)])
	_add("attack", [_m(MOUSE_BUTTON_LEFT), _jb(JOY_BUTTON_X)])
	_add("bite", [_m(MOUSE_BUTTON_RIGHT), _jb(JOY_BUTTON_Y)])
	_add("dodge", [_k(KEY_SPACE), _jb(JOY_BUTTON_A)])
	_add("run", [_k(KEY_SHIFT), _jb(JOY_BUTTON_LEFT_SHOULDER)])
	_add("throw_silk", [_k(KEY_Q), _jb(JOY_BUTTON_RIGHT_SHOULDER)])
	_add("weave", [_k(KEY_R), _ja(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_add("read", [_k(KEY_ALT), _k(KEY_TAB), _ja(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_add("interact", [_k(KEY_E), _jb(JOY_BUTTON_B)])
	_add("rune", [_k(KEY_F), _jb(JOY_BUTTON_RIGHT_STICK)])
	_add("cocoon", [_k(KEY_C), _jb(JOY_BUTTON_DPAD_DOWN)])
	_add("help", [_k(KEY_H), _jb(JOY_BUTTON_BACK)])
	_add("map", [_k(KEY_M), _jb(JOY_BUTTON_DPAD_UP)])
	_add("pause", [_k(KEY_ESCAPE), _jb(JOY_BUTTON_START)])
	_add("debug_level", [_k(KEY_F1)])
	_add("debug_reset", [_k(KEY_F8)])


func _add(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)
	for e in events:
		InputMap.action_add_event(action, e)


func _k(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


func _m(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	return e


func _jb(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


func _ja(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e
