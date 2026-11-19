class_name QueenSalamander
extends FireSalamander
## Salamandra-rainha (G, chefe do Rio de Brasa, R12). A mãe de todas as salamandras-chama.
##   - Sopro de fogo em linha (queima fios e você), mordida, investida e chicote de cauda.
##   - ONDA DE FOGO: de tempos em tempos ela brilha inteira (aviso) e solta um anel de fogo que
##     cresce até a parede: queima TODAS as teias e fios da arena e quem estiver no chão no anel.
##     Esquive (Espaço) na hora em que o anel passa.
##   - Depois da onda ela fica um tempo apagada: a pele de brasa esfria e o golpe entra cheio.
##     Fora disso, a pele segura metade do dano.
##   - Furiosa (metade da vida): ondas mais seguidas e investidas.

const WAVE_EVERY := 9.0
const WAVE_EVERY_FURY := 6.5
const WAVE_WARN := 1.3
const WAVE_SPEED := 9.0
const WAVE_MAX := 16.0
const WAVE_DAMAGE := 24.0
const COOL_TIME := 3.5
const SKIN := 0.5

var arena_center := Vector3.ZERO
var awake := false
var _wave_t := 0.0
var _wave_r := -1.0                 ## raio do anel agora (< 0: sem onda)
var _warn := -1.0
var _cool := 0.0
var _hit_wave := false
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _skin_msg := 0.0


func _init() -> void:
	display_name = "Salamandra-rainha"
	size = Size.G
	level = 15
	max_hp = 420.0
	speed = 3.0
	body_radius = 1.1
	body_color = Color(0.6, 0.14, 0.05)
	food_satiety = 100.0
	food_silk = 70.0
	food_xp = 380
	food_fire = 2
	food_energy = 10.0
	senses_text = "calor e visão (12 m). Depois da onda de fogo a pele esfria: dano cheio"
	sight_range = 12.0
	aggression = 1.0
	leash_range = 40.0
	memory_time = 99.0
	nav_kind = NavGrid.Kind.LARGE
	model_size = 2.2
	add_attack(Attack.make("investida", "Investida", {"min_range": 3.0, "max_range": 9.0, "windup": 0.8, "active": 0.45,
		"recover": 0.9, "cooldown": 6.0, "damage": 28.0, "reach": 2.2, "arc": 90.0, "lunge": 14.0, "only_enraged": true, "weight": 2.0}))


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	boss_music = "rainha"
	_ring_mat = Fx.mat(Color(1.0, 0.45, 0.1), 3.0, true, 0.75)
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.92
	tm.outer_radius = 1.0
	_ring.mesh = tm
	_ring.material_override = _ring_mat
	_ring.top_level = true
	_ring.visible = false
	add_child(_ring)


func wake() -> void:
	if awake:
		return
	awake = true
	asleep = false
	_wave_t = 4.0
	var p := GameState.player as Player
	if p != null:
		player_memory = memory_time
		last_player_pos = p.global_position
	EventBus.big_message.emit("Salamandra-rainha")
	EventBus.hint.emit("Quando ela brilhar inteira, vem a ONDA DE FOGO: esquive (Espaço) quando o anel passar. A onda queima todas as teias. Depois dela, a pele esfria: bata com tudo.")
	GameState.say_once("rainha_inicio", "Ela é do tamanho de uma casa. Uma casa PEGANDO FOGO.")


func notices_player(p: Player) -> bool:
	return awake and not p.dead


func take_damage(amount: float, source: Node3D = null) -> void:
	if dead:
		return
	if not awake:
		wake()
	if _cool <= 0.0:
		amount *= SKIN
		_skin_msg -= 1.0
		if _skin_msg <= 0.0 and source != null and source.is_in_group("player"):
			_skin_msg = 6.0
			EventBus.message.emit("A pele de brasa segura o golpe. Espere a onda: depois dela, a pele esfria.")
	super.take_damage(amount, source)


func is_cooling() -> bool:
	return _cool > 0.0


func _think(delta: float) -> Vector3:
	if not awake:
		activity = "Dormindo na lava"
		return Vector3.ZERO
	_cool = maxf(0.0, _cool - delta)
	if _warn >= 0.0 or _wave_r >= 0.0:
		return Vector3.ZERO   # parada enquanto solta a onda
	_wave_t -= delta
	if _wave_t <= 0.0 and cur_attack == null:
		_warn = 0.0
		activity = "Brilhando inteira..."
		EventBus.message.emit("A rainha brilha inteira...")
		return Vector3.ZERO
	return super._think(delta)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if dead:
		_ring.visible = false
		return
	_mat.emission_enabled = true
	if _warn >= 0.0:
		_warn += delta
		_mat.emission = Color(1.0, 0.5, 0.1)
		_mat.emission_energy_multiplier = 0.5 + 3.0 * (_warn / WAVE_WARN)
		if _warn >= WAVE_WARN:
			_warn = -1.0
			_wave_r = 0.5
			_hit_wave = false
			_ring.visible = true
			var p := GameState.player as Player
			if p != null:
				p.shake(0.8)
	elif _wave_r >= 0.0:
		_wave_r += WAVE_SPEED * delta
		_ring.global_position = Vector3(global_position.x, 0.3, global_position.z)
		_ring.scale = Vector3(_wave_r, 1.0, _wave_r)
		_ring_mat.albedo_color.a = 0.75 * (1.0 - _wave_r / WAVE_MAX)
		_burn_ring(_wave_r)
		var p := GameState.player as Player
		if not _hit_wave and p != null and not p.dead:
			var d := flat_dist_to(p)
			if absf(d - _wave_r) < 0.9 and p.state != Player.State.DODGE:
				_hit_wave = true
				if p.take_damage(WAVE_DAMAGE * (1.15 if enraged else 1.0), self, false):
					p.apply_burn(3.0)
		if _wave_r >= WAVE_MAX:
			_wave_r = -1.0
			_ring.visible = false
			_cool = COOL_TIME
			_wave_t = WAVE_EVERY_FURY if enraged else WAVE_EVERY
			EventBus.message.emit("A pele dela esfriou! Agora!")
	else:
		var k := 0.25 if _cool > 0.0 else 1.0
		_mat.emission = Color(1.0, 0.35, 0.08) * k
		_mat.emission_energy_multiplier = 0.8


func _burn_ring(r: float) -> void:
	## A onda queima fios e teias por onde passa.
	var c := global_position
	for s in WebNetwork.strands.duplicate():
		if is_instance_valid(s):
			var ws := s as WebStrand
			var da := Fx.flat_dist(ws.a_pos, c)
			var db := Fx.flat_dist(ws.b_pos, c)
			if minf(da, db) <= r or ws.distance_to(c) <= r:
				WebNetwork.burn_strand(s)
	for t in WebNetwork.traps.duplicate():
		if is_instance_valid(t) and Fx.flat_dist(t.global_position, c) <= r:
			WebNetwork.burn_trap(t)


func on_enrage() -> void:
	EventBus.big_message.emit("A rainha se enfurece!")
	GameState.say_once("rainha_furia", "Ela tá MAIS quente agora? Isso nem devia ser possível.")


func entangle(_d: float) -> float:
	return 0.0


func can_raid() -> bool:
	return false
