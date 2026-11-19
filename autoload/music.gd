extends Node
## Música do jogo. Os arquivos ficam em res://audio/music/ com os nomes da aba
## "Músicas (prompts)" do GDD; se um arquivo não existir, aquele trecho fica em silêncio.
##
## - area(nome): música do mapa (mus_<nome>.ogg) + camada de tensão (mus_<nome>_tensao.ogg)
##   tocando juntas; a tensão sobe quando um bicho está caçando a jogadora por perto.
## - Chefes: quando um bicho do grupo "boss" com boss_music entra em luta, troca para
##   mus_boss_<nome>.ogg (com _intro, se houver) e volta ao mapa quando ele morre.
## - Camadas por cima: Colosso perto (mus_colosso), alerta máximo da caçada (mus_cacada_alerta).
## - Curtas: stinger_<nome>.ogg (vitória, morte, evolução, segredo), abaixando a música.
## - Casulo: mus_casulo.ogg enquanto o menu do casulo estiver aberto.

const DIR := "res://audio/music/"
const BUS := "Música"
const FADE := 1.5
const SILENT := -60.0

var _a: AudioStreamPlayer          ## base atual
var _t: AudioStreamPlayer          ## camada de tensão (sincronizada com a base)
var _old: Array = []               ## players saindo (crossfade)
var _over: AudioStreamPlayer       ## camada por cima (Colosso, alerta)
var _sting: AudioStreamPlayer
var _cur := ""                     ## faixa base tocando ("" = silêncio)
var _area := ""
var _boss: Creature = null
var _boss_key := ""
var _over_key := ""
var _tension := 0.0
var _tension_target := 0.0
var _duck := 0.0
var _check := 0.0
var _boss_far := 0.0
var _in_cocoon := false
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = _player()
	_t = _player()
	_over = _player()
	_sting = _player()
	_sting.volume_db = 0.0


func _player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = BUS if AudioServer.get_bus_index(BUS) >= 0 else "Master"
	p.volume_db = SILENT
	add_child(p)
	return p


# ------------------------------------------------------------ API

func area(track: String) -> void:
	_area = track
	_boss = null
	_boss_key = ""
	_set_overlay("")
	if not _in_cocoon:
		_play_base("mus_" + track if track != "" else "")


func boss(key: String, who: Creature = null) -> void:
	if key == _boss_key and is_instance_valid(_boss):
		return
	_boss = who
	_boss_key = key
	_boss_far = 0.0
	var intro := _stream("mus_boss_%s_intro" % key, false)
	_play_base("mus_boss_" + key, intro)


func end_boss(victory := false) -> void:
	if _boss_key == "":
		return
	_boss = null
	_boss_key = ""
	if victory:
		stinger("vitoria")
	_play_base("mus_" + _area if _area != "" else "")


func stinger(track: String) -> void:
	var s := _stream(track if track.begins_with("mus_") else "stinger_" + track, false)
	if s == null:
		return
	_sting.stream = s
	_sting.volume_db = 0.0
	_sting.play()
	_duck = minf(8.0, s.get_length() if s.get_length() > 0.0 else 4.0)


func cocoon(open: bool) -> void:
	if open == _in_cocoon:
		return
	_in_cocoon = open
	if open:
		_play_base("mus_casulo")
	elif _boss_key != "":
		_play_base("mus_boss_" + _boss_key)
	else:
		_play_base("mus_" + _area if _area != "" else "")


func playing() -> String:
	return _cur


# ------------------------------------------------------------ quadro

func _process(delta: float) -> void:
	_check -= delta
	if _check <= 0.0:
		_check = 0.3
		_scan()
	_duck = maxf(0.0, _duck - delta)
	var duck_db := -8.0 if _duck > 0.0 else 0.0
	_tension = move_toward(_tension, _tension_target, delta / 2.0)
	if _a.playing:
		_a.volume_db = move_toward(_a.volume_db, duck_db, 60.0 * delta / FADE)
	if _t.stream != null and _t.playing:
		var want := linear_to_db(maxf(_tension, 0.001)) + duck_db
		_t.volume_db = move_toward(_t.volume_db, want, 60.0 * delta / FADE)
	for o in _old.duplicate():
		var p := o as AudioStreamPlayer
		p.volume_db -= 60.0 * delta / FADE
		if p.volume_db <= SILENT:
			p.stop()
			p.queue_free()
			_old.erase(p)
	if _over.stream != null:
		var target := duck_db if _over_key != "" else SILENT
		_over.volume_db = move_toward(_over.volume_db, target, 60.0 * delta / FADE)
		if _over_key == "" and _over.volume_db <= SILENT + 0.5:
			_over.stop()
			_over.stream = null


func _scan() -> void:
	var p = GameState.player
	if p == null or not is_instance_valid(p) or p.dead:
		_tension_target = 0.0
		return
	# tensão: um bicho caçando por perto
	var hunted := false
	var colossus_near := false
	for c in World.creatures:
		if not is_instance_valid(c) or c.dead:
			continue
		var d := Fx.flat_dist(c.global_position, p.global_position)
		if d < 18.0 and c.hunting_player():
			hunted = true
		# chefe entrando em luta
		var key := c.boss_music
		if key != "" and _boss_key == "" and d < 30.0 and (c.noticed_player or c.hp < c.max_hp):
			boss(key, c)
			if c.has_signal("horn") and not c.is_connected("horn", _on_horn):
				c.connect("horn", _on_horn)
	for col in get_tree().get_nodes_in_group("colossus"):
		if Fx.flat_dist((col as Node3D).global_position, p.global_position) < 22.0:
			colossus_near = true
	_tension_target = 1.0 if hunted else 0.0
	# chefe: venceu, sumiu ou ela fugiu para longe
	if _boss_key != "" and _boss_key != "fuga_mae":
		if not is_instance_valid(_boss) or _boss.dead:
			end_boss(true)
		elif Fx.flat_dist(_boss.global_position, p.global_position) > 40.0:
			_boss_far += 0.3
			if _boss_far > 8.0:
				end_boss()
		else:
			_boss_far = 0.0
			# a fúria (segunda metade da vida) sobe a camada de tensão do chefe
			if _t.stream != null and _boss.hp < _boss.max_hp * 0.5:
				_tension_target = 1.0
	# camadas por cima
	if colossus_near:
		_set_overlay("mus_colosso")
	elif GameState.hunt_alert >= 3.0:
		_set_overlay("mus_cacada_alerta")
	else:
		_set_overlay("")


func _on_horn() -> void:
	stinger("mus_boss_capita_trompa")


# ------------------------------------------------------------ tocar

func _play_base(track: String, intro: AudioStream = null) -> void:
	if track == _cur:
		return
	_cur = track
	for p in [_a, _t]:
		if p.playing:
			var o := AudioStreamPlayer.new()
			o.bus = p.bus
			o.stream = p.stream
			o.volume_db = p.volume_db
			add_child(o)
			o.play(p.get_playback_position())
			_old.append(o)
		p.stop()
		p.stream = null
	var s := _stream(track, true)
	if s == null:
		return
	var tens := _stream(track + "_tensao", true)
	if intro != null:
		_a.stream = intro
		_a.volume_db = 0.0
		_a.play()
		_a.finished.connect(func():
			if _cur == track:
				_start_loop(s, tens), CONNECT_ONE_SHOT)
		return
	_start_loop(s, tens)


func _start_loop(s: AudioStream, tens: AudioStream) -> void:
	_a.stream = s
	_a.volume_db = SILENT + 20.0
	_a.play()
	if tens != null:
		_t.stream = tens
		_t.volume_db = SILENT
		_t.play()


func _set_overlay(track: String) -> void:
	if track == _over_key:
		return
	_over_key = track
	if track == "":
		return
	var s := _stream(track, true)
	if s == null:
		_over_key = ""
		return
	_over.stream = s
	_over.volume_db = SILENT
	_over.play(_a.get_playback_position() if _a.playing else 0.0)


func _stream(track: String, loop: bool) -> AudioStream:
	if track == "":
		return null
	var key := "%s|%s" % [track, loop]
	if _cache.has(key):
		return _cache[key]
	var path := DIR + track + ".ogg"
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	elif FileAccess.file_exists(path):
		s = AudioStreamOggVorbis.load_from_file(path)
	if s is AudioStreamOggVorbis:
		s = s.duplicate()
		(s as AudioStreamOggVorbis).loop = loop
	_cache[key] = s
	return s
