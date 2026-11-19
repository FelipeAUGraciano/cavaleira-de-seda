extends Node
## Efeitos sonoros. Os arquivos ficam em res://audio/sfx/ com os nomes da aba
## "Efeitos sonoros (prompts)" do GDD; variações têm sufixo _1, _2... e o jogo sorteia.
## O que faltar fica em silêncio.
##
## - play(nome, posição): toca no espaço 3D (ou sem posição: interface, 2D).
## - creature(bicho, "alerta" | "ataque" | "dor"): som da família do bicho (ou do chefe).
## - loop_on(nó, nome, condição): loop preso a um nó (fogueira, orbe, sopro de fogo...).
## - ambient(nome): fundo contínuo do mapa (amb_<nome>.ogg), por baixo da música.

const DIR := "res://audio/sfx/"
var dir := DIR                    ## os testes apontam para tests/fixtures/sfx/
const BUS := "Efeitos"
const MAX_VARIANTS := 8
const POOL := 24

## Família de som de cada tipo de bicho (pelo class_name).
const FAMILY := {
	"Larva": "inseto", "Beetle": "inseto", "EmberBeetle": "inseto", "Ant": "inseto", "Centipede": "inseto",
	"Sister": "aracnideo", "WolfSpider": "aracnideo", "AshSpider": "aracnideo", "Scorpion": "aracnideo",
	"Lizard": "reptil", "FireSalamander": "reptil", "Snake": "reptil", "Serpent": "reptil", "QueenSalamander": "reptil",
	"Frog": "anfibio",
	"Bat": "voador", "GiantBat": "voador", "AshBat": "voador", "BatCurtain": "voador",
	"Mimic": "pedra", "BasaltGolem": "pedra",
	"LavaLurker": "lava", "MagmaFish": "lava", "LavaWorm": "lava",
	"AcidSlug": "gosma",
	"Hunter": "humano", "Captain": "humano", "Adventurer": "humano",
}
## Chefes com sons próprios (no lugar do da família).
const BOSS := {
	"Serpent": {"alerta": "serpente_sibilo", "ataque": "serpente_bote"},
	"Centipede": {"ataque": "centopeia_golpe"},
	"QueenSalamander": {"alerta": "rainha_rugido"},
	"Captain": {"alerta": "capita_comando"},
}
## Casca dura: o golpe soa como em carapaça/pedra.
const HARD := ["Beetle", "EmberBeetle", "Centipede", "Scorpion", "Mimic", "BasaltGolem", "Captain"]

var _pool: Array = []
var _next := 0
var _ui: AudioStreamPlayer
var _amb: AudioStreamPlayer
var _amb_old: AudioStreamPlayer
var _amb_name := ""
var _cache := {}                  ## nome -> Array de streams (variações)
var _last := {}                   ## nome -> tempo do último toque (ms)
var _cd := {}                     ## bicho -> {tipo: ms}
var _loops: Array = []            ## [{node, player, cond}]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bus := BUS if AudioServer.get_bus_index(BUS) >= 0 else "Master"
	for i in POOL:
		var p := AudioStreamPlayer3D.new()
		p.bus = bus
		p.unit_size = 6.0
		p.max_distance = 34.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.panning_strength = 0.6
		add_child(p)
		_pool.append(p)
	_ui = AudioStreamPlayer.new()
	_ui.bus = bus
	_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui)
	_amb = AudioStreamPlayer.new()
	_amb.bus = bus
	add_child(_amb)
	_amb_old = AudioStreamPlayer.new()
	_amb_old.bus = bus
	add_child(_amb_old)
	# interface: qualquer botão do jogo faz "clique" ao ganhar foco e ao ser apertado
	get_tree().node_added.connect(_on_node_added)
	get_viewport().gui_focus_changed.connect(func(c: Control):
		if c is BaseButton:
			play("ui_mover", Vector3.INF, 0.0, 0.03, 0.05))


func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		(n as BaseButton).pressed.connect(func(): play("ui_confirmar", Vector3.INF, 0.0, 0.02, 0.05))


func _exit_tree() -> void:
	for c in get_children():
		if c is AudioStreamPlayer or c is AudioStreamPlayer3D:
			c.stop()
			c.stream = null
	_cache.clear()


# ------------------------------------------------------------ tocar

func use_dir(d: String) -> void:
	## Troca a pasta dos sons (testes) e esquece o que já tinha carregado.
	dir = d
	_cache.clear()
	_last.clear()
	_cd.clear()


func has(sound: String) -> bool:
	return not _variants(sound).is_empty()


func play(sound: String, at: Vector3 = Vector3.INF, vol_db := 0.0, pitch_var := 0.08, min_gap := 0.04) -> void:
	var vs := _variants(sound)
	if vs.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(sound, -100000)) < int(min_gap * 1000.0):
		return
	_last[sound] = now
	var s: AudioStream = vs[randi() % vs.size()]
	var pitch := 1.0 + randf_range(-pitch_var, pitch_var)
	if at == Vector3.INF:
		_ui.stream = s
		_ui.volume_db = vol_db
		_ui.pitch_scale = pitch
		_ui.play()
		return
	var p: AudioStreamPlayer3D = _pool[_next]
	_next = (_next + 1) % _pool.size()
	if not p.is_inside_tree():
		return
	p.stream = s
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.global_position = at
	p.play()


func creature(c: Creature, kind: String) -> void:
	## Som de um bicho: alerta (te notou), ataque (começo do golpe), dor (apanhou).
	if c == null or not is_instance_valid(c) or not c.is_inside_tree():
		return
	var cls := _cls(c)
	var cds: Dictionary = _cd.get(c, {})
	var now := Time.get_ticks_msec()
	var gap: int = {"alerta": 4000, "ataque": 300, "dor": 350}.get(kind, 300)
	if now - int(cds.get(kind, -100000)) < gap:
		return
	cds[kind] = now
	_cd[c] = cds
	var at := c.global_position + Vector3.UP * 0.5
	var big := int(c.size) >= int(Creature.Size.G)
	var vol := 3.0 if big else 0.0
	var pitch := 0.12
	if kind == "ataque" and c.cur_attack != null:
		var label := String(c.cur_attack.label).to_lower()
		for k in [["flecha", "flecha_disparo"], ["tocha", "tocha_whoosh"], ["frasco", "capita_frasco"], ["giro", "capita_giro"], ["escudo", "espada_escudo"], ["onda", "rainha_onda"]]:
			if label.contains(k[0]) and has(k[1]):
				play(k[1], at, vol)
				return
		if FAMILY.get(cls, "") == "humano" and has("espada_golpe"):
			play("espada_golpe", at, vol)
	var special: String = (BOSS.get(cls, {}) as Dictionary).get(kind, "")
	if special != "" and has(special):
		play(special, at, vol + 2.0, 0.04)
		return
	var fam: String = FAMILY.get(cls, "inseto")
	play("%s_%s" % [fam, kind], at, vol, pitch, 0.02)


func hit(c: Creature, crit: bool, dmg: float) -> void:
	if c == null or not is_instance_valid(c):
		return
	var at := c.global_position + Vector3.UP * 0.5
	if crit and has("hit_critico"):
		play("hit_critico", at)
	elif c.is_in_group("boss") and dmg < 8.0 and has("hit_bloqueado"):
		play("hit_bloqueado", at)
	elif HARD.has(_cls(c)):
		play("hit_casca", at, 0.0, 0.1, 0.03)
	else:
		play("hit_carne", at, 0.0, 0.1, 0.03)


func death(c: Creature) -> void:
	var at := c.global_position + Vector3.UP * 0.4
	if int(c.size) >= int(Creature.Size.M) or c.is_in_group("boss"):
		play("morte_grande", at, 2.0 if c.is_in_group("boss") else 0.0)
	else:
		play("morte_pequena", at)
	play("corpo_cai", at, -3.0, 0.1, 0.0)


func _cls(c: Object) -> String:
	var s: Script = c.get_script()
	while s != null:
		var n := String(s.get_global_name())
		if FAMILY.has(n):
			return n
		s = s.get_base_script()
	return ""


# ------------------------------------------------------------ loops presos a nós

func loop_on(node: Node3D, sound: String, cond := Callable(), vol_db := 0.0) -> void:
	## Loop que segue o nó; com cond, só toca enquanto cond.call() for true.
	var vs := _variants(sound)
	if vs.is_empty() or node == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.bus = BUS if AudioServer.get_bus_index(BUS) >= 0 else "Master"
	p.unit_size = 5.0
	p.max_distance = 26.0
	p.stream = vs[0]
	p.volume_db = vol_db
	node.add_child(p)
	_loops.append({"node": node, "player": p, "cond": cond, "has_cond": cond.is_valid()})


func _process(_delta: float) -> void:
	for l in _loops.duplicate():
		var p = l["player"]
		if not is_instance_valid(l["node"]) or not is_instance_valid(p):
			_loops.erase(l)
			continue
		var on := true
		var cond: Callable = l["cond"]
		if bool(l["has_cond"]):
			if not cond.is_valid():   # quem pediu o loop sumiu (forma trocada): para e solta
				(p as Node).queue_free()
				_loops.erase(l)
				continue
			on = bool(cond.call())
		var ap := p as AudioStreamPlayer3D
		if on and not ap.playing and ap.is_inside_tree():
			ap.play(randf() * maxf(0.0, ap.stream.get_length() - 0.1))
		elif not on and ap.playing:
			ap.stop()


# ------------------------------------------------------------ ambiente

func ambient(area: String) -> void:
	var sound := "amb_" + area if area != "" else ""
	if sound == _amb_name:
		return
	_amb_name = sound
	if _amb.playing:
		_amb_old.stream = _amb.stream
		_amb_old.volume_db = _amb.volume_db
		_amb_old.play(_amb.get_playback_position())
		var tw := create_tween()
		tw.tween_property(_amb_old, "volume_db", -60.0, 2.0)
		tw.tween_callback(_amb_old.stop)
	_amb.stop()
	var vs := _variants(sound) if sound != "" else []
	if vs.is_empty():
		_amb.stream = null
		return
	_amb.stream = vs[0]
	_amb.volume_db = -60.0
	_amb.play()
	create_tween().tween_property(_amb, "volume_db", -4.0, 2.0)


func ambient_now() -> String:
	return _amb_name if _amb.stream != null else ""


# ------------------------------------------------------------ arquivos

func _variants(sound: String) -> Array:
	if _cache.has(sound):
		return _cache[sound]
	var out: Array = []
	var s := _load(sound)
	if s != null:
		out.append(s)
	for i in range(1, MAX_VARIANTS + 1):
		var v := _load("%s_%d" % [sound, i])
		if v == null:
			break
		out.append(v)
	var loop := sound.begins_with("amb_") or sound.begins_with("loop_") or sound.ends_with("_loop")
	for k in out.size():
		if out[k] is AudioStreamOggVorbis:
			out[k] = out[k].duplicate()
			(out[k] as AudioStreamOggVorbis).loop = loop
	_cache[sound] = out
	return out


func _load(file: String) -> AudioStream:
	var path := dir + file + ".ogg"
	if ResourceLoader.exists(path):
		return load(path)
	if FileAccess.file_exists(path):
		return AudioStreamOggVorbis.load_from_file(path)
	return null
