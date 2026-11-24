class_name Guardian
extends Creature
## O Guardião do Portão (P7, chefe final): o Colosso da Fenda, no ninho dele. O mesmo dragão
## da terra que no Abismo não dava para vencer, só evitar. Agora ela cresceu.
## Luta em 3 fases, cada uma testando uma coisa que ela aprendeu na caverna:
##   1. ESQUIVA (100%–66%): escamas de pedra seguram 75%. A INVESTIDA em linha é a chance:
##      esquive para o lado e ele se arrebenta num pilar (ou na parede) e fica atordoado,
##      com as escamas abertas.
##   2. TEIA (66%–33%): ele aprendeu a frear antes dos pilares. O teto racha (pedras caindo,
##      marca no chão) e ele cospe estilhaços de cristal. A chance agora é a TEIA DE CAPTURA:
##      se a investida passar por cima de uma, ele se enrosca e as escamas abrem.
##   3. ESCURO (33%–0): a poeira apaga a arena e ele fica cego. Caça pela vibração, como no
##      Abismo (correr, fio vibrando, encostar). Ela some (runa apagada, devagar) → ele fareja,
##      de costas e sem defesa: golpe por trás entra dobrado. Achou você, ruge e volta a caçar.
## Cada troca de fase: rugido (sem dano por 2,5 s), música nova e uma dica.

signal phase_changed(phase: int)

const SCALE := 0.8
const PHASE_AT := [1.0, 0.66, 0.33]
const ARMOR := [0.75, 0.6, 0.5]       ## fração do golpe que as escamas seguram, por fase
const STUN_TIME := 4.0
const ROAR_TIME := 2.5
const CHARGE_REACH := 17.0
const ROCK_EVERY := 2.4
const ROCK_WARN := 1.4
const ROCK_R := 1.7
const ROCK_DAMAGE := 22.0
const SNIFF_BONUS := 2.0
const HEAR := 1.6
const STRAND_FEEL := 12.0

var phase := 0                         ## 0 dormindo; 1, 2, 3; 4 caído
var arena_center := Vector3.ZERO
var arena_radius := 16.0
var pillars: Array = []                ## Vector3 dos pilares da arena (a investida bate neles na fase 1)
var stun_t := 0.0
var roar_t := 0.0
var sniffing := false
var _parts := {}
var _legs: Array = []
var _tail: Array = []
var _neck: Array = []
var _head: Node3D
var _eye_mat: StandardMaterial3D
var _vein_mat: StandardMaterial3D
var _armor_msg := 0.0
var _trap_msg := 0.0
var _rock_t := 0.0
var _rocks: Array = []                 ## [marca, ponto, tempo]
var _sense_tick := 0.0
var _found_t := -1.0                   ## fase 3: apanhou farejando → em instantes vira e ruge
var _away_t := 0.0


func _init() -> void:
	display_name = "Guardião do Portão"
	size = Size.COLOSSAL
	level = 30
	max_hp = 1100.0
	speed = 3.2
	body_radius = 2.3
	body_color = Color(0.3, 0.28, 0.33)
	food_satiety = 200.0
	food_silk = 120.0
	food_xp = 900
	food_energy = 25.0
	food_skin = true
	senses_text = "vibração do chão e visão de perto. Na fase 3, cego: só a vibração"
	sight_range = 14.0
	aggression = 1.0
	leash_range = 80.0
	memory_time = 99.0
	uses_interest = false
	nav_kind = NavGrid.Kind.LARGE
	combat_label = "Guardando o Portão"
	add_attack(Attack.make("pisada", "Pisada", {"max_range": 5.5, "windup": 0.95, "active": 0.2, "recover": 0.8,
		"cooldown": 2.0, "damage": 32.0, "reach": 5.2, "arc": 110.0, "weight": 3.0}))
	add_attack(Attack.make("cauda", "Rabo de pedra", {"max_range": 6.8, "windup": 1.0, "active": 0.25, "recover": 0.9,
		"cooldown": 4.0, "damage": 26.0, "shape": Attack.Shape.RING, "reach": 6.6, "flank": true, "weight": 2.0}))
	add_attack(Attack.make("investida", "Investida", {"min_range": 6.0, "max_range": 18.0, "windup": 1.2, "active": 1.05,
		"recover": 1.1, "cooldown": 4.5, "damage": 40.0, "shape": Attack.Shape.LINE, "reach": CHARGE_REACH, "width": 4.2,
		"lunge": 16.0, "weight": 3.0}))
	add_attack(Attack.make("estilhacos", "Estilhaços de cristal", {"min_range": 4.0, "max_range": 14.0, "windup": 0.9,
		"active": 0.2, "recover": 0.8, "cooldown": 3.5, "damage": 24.0, "shape": Attack.Shape.LINE, "reach": 14.0,
		"width": 1.6, "knockback": false, "weight": 2.0}))
	add_attack(Attack.make("tremor", "Tremor", {"max_range": 9.0, "windup": 1.3, "active": 0.25, "recover": 1.0,
		"cooldown": 6.0, "damage": 26.0, "shape": Attack.Shape.RING, "reach": 8.5, "weight": 1.5}))


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	boss_music = "guardiao_1"
	_web_immune = 999.0          # a teia de captura não segura: só a investida em cima dela (fase 2)
	_set_phase_attacks()


func _build_visual() -> void:
	_parts = Colossus.build_body(_visual)
	var v: Node3D = _parts["visual"]
	v.scale = Vector3.ONE * SCALE
	_legs = _parts["legs"]
	_tail = _parts["tail"]
	_neck = _parts["neck"]
	_head = _parts["head"]
	_eye_mat = _parts["eye_mat"]
	_vein_mat = _parts["vein_mat"]


func bestiary_visible() -> bool:
	return true


func notices_player(p: Player) -> bool:
	return phase > 0 and not p.dead


func entangle(_d: float) -> float:
	return 0.0


func can_raid() -> bool:
	return false


func web_weight() -> int:
	return 99


# ---------------------------------------------------------------- fases

func wake() -> void:
	if phase != 0:
		return
	_to_phase(1)


func _to_phase(n: int) -> void:
	phase = n
	cancel_attack()
	roar_t = ROAR_TIME if n > 1 else 1.6
	stun_t = 0.0
	sniffing = false
	asleep = false
	noticed_player = true
	var p := GameState.player as Player
	if p != null:
		player_memory = 5.0
		last_player_pos = p.global_position
		p.shake(1.4)
	Sfx.creature(self, "alerta")
	_set_phase_attacks()
	match n:
		1:
			EventBus.big_message.emit("O Guardião do Portão")
			EventBus.hint.emit("As escamas seguram quase tudo. Quando ele avisar a INVESTIDA (a linha no chão), esquive para o lado: se ele bater num pilar ou na parede, fica atordoado e as escamas abrem.")
			GameState.say_once("guardiao_1", "É ELE. O Colosso. Ele não estava só passando pela Fenda... ele mora aqui. E agora eu caibo no mundo dele.")
		2:
			boss_music = "guardiao_2"
			Music.boss("guardiao_2", self)
			EventBus.big_message.emit("O teto está rachando!")
			EventBus.hint.emit("Ele aprendeu a frear antes dos pilares. Pedras caem do teto (fuja das marcas). Teça TEIAS DE CAPTURA no caminho da investida: se ele passar por cima, se enrosca e as escamas abrem.")
			GameState.say_once("guardiao_2", "Ele APRENDEU. Tudo bem. Eu também aprendi umas coisas.")
		3:
			boss_music = "guardiao_3"
			Music.boss("guardiao_3", self)
			EventBus.big_message.emit("A poeira apagou a arena")
			EventBus.hint.emit("Ele está cego: caça pela vibração (correr, fio vibrando, chegar perto). Apague a runa e ande devagar até ele perder você. Farejando, ele fica de costas e sem defesa: golpe por trás entra dobrado.")
			GameState.say_once("guardiao_3", "Não enxergo nada. ...Nem ele. No escuro, quem manda sou EU.")
	phase_changed.emit(n)


func _set_phase_attacks() -> void:
	## Estilhaços e tremor só a partir da fase 2 (recarga "infinita" até lá).
	for a in attacks:
		var on := true
		match a.id:
			"estilhacos", "tremor":
				on = phase >= 2
		if not on:
			a.cd_left = 9999.0
		elif a.cd_left > 999.0:
			a.cd_left = 1.5


func take_damage(amount: float, source: Node3D = null) -> void:
	if dead or phase >= 4:
		return
	if phase == 0:
		wake()
	if roar_t > 0.0 and phase > 1:
		return   # rugindo: nada entra
	var from_player := source != null and source.is_in_group("player")
	if stun_t > 0.0:
		amount *= 1.25
	elif phase == 3 and sniffing:
		var behind := _behind(source.global_position) if source != null else false
		amount *= SNIFF_BONUS if behind else 1.0
		if from_player:
			_found_t = 0.45   # achou você: vira e ruge
			if behind:
				EventBus.message.emit("Golpe por trás, farejando: dano dobrado!")
	else:
		amount *= 1.0 - ARMOR[clampi(phase - 1, 0, 2)]
		_armor_msg -= 1.0
		if _armor_msg <= 0.0 and from_player:
			_armor_msg = 7.0
			EventBus.message.emit(["As escamas de pedra seguram o golpe. Faça ele se arrebentar num pilar.",
				"As escamas seguram. Teia de captura no caminho da investida!",
				"As escamas seguram. Suma no escuro e ataque quando ele estiver farejando."][clampi(phase - 1, 0, 2)])
	# não pula fase de uma vez: segura no limite e muda
	if phase < 3:
		var floor_hp: float = max_hp * float(PHASE_AT[phase])
		if hp - amount <= floor_hp:
			amount = maxf(0.0, hp - floor_hp)
			super.take_damage(amount, source)
			if not dead:
				_to_phase(phase + 1)
			return
	super.take_damage(amount, source)


func _behind(pos: Vector3) -> bool:
	var to := pos - global_position
	to.y = 0.0
	return to.length() > 0.1 and facing.angle_to(to.normalized()) > deg_to_rad(95.0)


func die(fell: bool = false) -> void:
	phase = 4
	for r in _rocks:
		if is_instance_valid(r[0]):
			(r[0] as Node).queue_free()
	_rocks.clear()
	super.die(fell)


# ---------------------------------------------------------------- cérebro

func _think(delta: float) -> Vector3:
	var p := GameState.player as Player
	if phase == 0:
		activity = "Dormindo no ninho"
		return Vector3.ZERO
	if roar_t > 0.0:
		roar_t -= delta
		activity = "Rugindo"
		if p != null:
			face_toward(p.global_position)
		return Vector3.ZERO
	if stun_t > 0.0:
		stun_t -= delta
		activity = "Atordoado (escamas abertas)"
		if stun_t <= 0.0:
			EventBus.message.emit("O Guardião se levantou.")
		return Vector3.ZERO
	if p == null or p.dead or not _in_arena(p):
		return _guard_gate(delta)
	_away_t = 0.0
	if phase == 2:
		_tick_rocks(delta)
	if phase == 3:
		_sense_blind(delta, p)
		if _found_t >= 0.0:
			_found_t -= delta
			if _found_t < 0.0:
				_found_you(p)
			return Vector3.ZERO
		if player_memory <= 0.0 and cur_attack == null:
			if not sniffing:
				sniffing = true
				EventBus.message.emit("Ele perdeu você. Está farejando... de costas.")
			activity = "Farejando"
			noticed_player = false
			if Fx.flat_dist(global_position, last_player_pos) < 2.5:
				return wander(delta, 5.0, 0.3)
			return nav_to(last_player_pos, 0.35)
		sniffing = false
		noticed_player = player_memory > 0.0
	else:
		noticed_player = p != null and not p.dead
		if noticed_player:
			player_memory = 5.0
			last_player_pos = p.global_position
	return fight_player(delta, p)


func _in_arena(p: Player) -> bool:
	return Fx.flat_dist(p.global_position, arena_center) < arena_radius + 4.0


func _guard_gate(delta: float) -> Vector3:
	## Ela saiu da arena (fugiu ou morreu): ele volta para a frente do portão e se recompõe.
	## A fase que ela já venceu fica vencida; a vida volta ao começo da fase atual.
	cancel_attack()
	noticed_player = false
	sniffing = false
	_away_t += delta
	if _away_t > 5.0:
		hp = maxf(hp, max_hp * float(PHASE_AT[clampi(phase - 1, 0, 2)]))
	activity = "Guardando o Portão"
	if Fx.flat_dist(global_position, den) > 1.5:
		return nav_to(den, 0.5)
	face_toward(arena_center)
	return Vector3.ZERO


func _sense_blind(delta: float, p: Player) -> void:
	## Fase 3: cego. Sente o chão: correr, andar perto, fio vibrando, encostar.
	player_memory -= delta
	_sense_tick -= delta
	if _sense_tick > 0.0 or p == null or p.dead:
		return
	_sense_tick = 0.2
	var d := flat_dist_to(p)
	var heard := d < p.noise_radius() * HEAR
	var on_web := p.on_strand and d < STRAND_FEEL
	var touch := d < body_radius + 2.2
	if heard or on_web or touch:
		if sniffing and player_memory <= 0.0:
			_found_t = 0.35
		player_memory = 3.0
		last_player_pos = p.global_position


func _found_you(p: Player) -> void:
	sniffing = false
	player_memory = 3.0
	if p != null:
		last_player_pos = p.global_position
		face_toward(p.global_position)
	roar_t = 0.9
	Sfx.creature(self, "alerta")
	EventBus.message.emit("Ele te sentiu!")
	if p != null:
		p.shake(0.6)


# ---------------------------------------------------------------- investida: pilar e teia

func on_attack_start(a: Attack) -> void:
	if a.id == "investida":
		a.shape = Attack.Shape.LINE
		a.reach = CHARGE_REACH   # o aviso mostra o caminho inteiro


func on_attack_active(a: Attack) -> void:
	if a.id == "investida":
		a.reach = 3.2            # correndo: pega o que estiver na frente da cabeça
		a.shape = Attack.Shape.CONE
		a.arc = 120.0
	elif a.id == "tremor":
		var p := GameState.player as Player
		if p != null:
			p.shake(1.0)
	elif a.id == "estilhacos":
		var to := atk_point - global_position
		to.y = 0.0
		if Sfx.has("guardiao_cristal"):
			Sfx.play("guardiao_cristal", global_position, 2.0)
		if to.length() > 0.1:
			Fx.beam(get_parent(), global_position + Vector3(0, 2.2, 0), global_position + to.normalized() * 14.0 + Vector3(0, 0.6, 0), Color(0.5, 0.9, 1.0), 0.5, 0.18)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if dead or phase == 0:
		return
	_trap_msg -= delta
	var charging := cur_attack != null and cur_attack.id == "investida" and atk_phase == 1
	if charging:
		var ahead := global_position + facing * (body_radius + 1.2)
		if phase == 2 and _hit_trap(ahead):
			return
		if _crashes(ahead):
			if phase == 1:
				_stun("Ele se arrebentou no pilar! Atordoado: as escamas abriram!")
			else:
				cancel_attack()   # aprendeu: freia antes de bater
				if phase == 2 and _trap_msg <= 0.0:
					_trap_msg = 8.0
					EventBus.message.emit("Ele freou antes do pilar. Teia de captura no caminho!")
	else:
		# andando por cima de uma teia de captura, ele arrebenta
		for t in WebNetwork.traps.duplicate():
			if is_instance_valid(t) and Fx.flat_dist(t.global_position, global_position) < body_radius + 0.4:
				WebNetwork.remove_trap(t)
				if _trap_msg <= 0.0:
					_trap_msg = 5.0
					EventBus.message.emit("Ele pisou na teia e arrebentou. Só a INVESTIDA se enrosca!")
	_tear_strands_big()


func _crashes(ahead: Vector3) -> bool:
	for q in pillars:
		if Fx.flat_dist(q, ahead) < 1.9:
			return true
	return World.nav != null and not World.nav.walkable(ahead, NavGrid.Kind.SMALL)


func _hit_trap(ahead: Vector3) -> bool:
	for t in WebNetwork.traps.duplicate():
		if is_instance_valid(t) and (Fx.flat_dist(t.global_position, ahead) < CaptureWeb.RADIUS + 1.2 or Fx.flat_dist(t.global_position, global_position) < body_radius + 0.6):
			WebNetwork.remove_trap(t)
			_stun("Enroscou na teia de captura! As escamas abriram!")
			GameState.say_once("guardiao_teia", "Pegou! A teia segurou um DRAGÃO! Bate, bate, BATE!")
			return true
	return false


func _stun(msg: String) -> void:
	cancel_attack()
	stun_t = STUN_TIME
	external_velocity = -facing * 3.0
	Sfx.play("pedra_cai", global_position, 6.0, 0.05)
	EventBus.big_message.emit(msg)
	var p := GameState.player as Player
	if p != null:
		p.shake(1.2)


func _tear_strands_big() -> void:
	## Fios no caminho do corpo e da cabeça arrebentam.
	var head := global_position + facing * 4.0
	for st in WebNetwork.strands.duplicate():
		if is_instance_valid(st) and (st.distance_to(global_position) < body_radius + 0.3 or st.distance_to(head) < 1.5):
			WebNetwork.remove_strand(st)
			EventBus.web_touched.emit(global_position, self)


# ---------------------------------------------------------------- fase 2: o teto cai

func _tick_rocks(delta: float) -> void:
	_rock_t -= delta
	var p := GameState.player as Player
	if _rock_t <= 0.0 and p != null and not p.dead:
		_rock_t = ROCK_EVERY
		for k in 3:
			var ang := randf() * TAU
			var off := Vector3(cos(ang), 0, sin(ang)) * (0.0 if k == 0 else randf_range(2.5, 5.0))
			var at := p.global_position + off
			at.y = 0.0
			if Fx.flat_dist(at, arena_center) > arena_radius - 1.0:
				continue
			_rocks.append([_rock_mark(at), at, 0.0])
	for r in _rocks.duplicate():
		r[2] = float(r[2]) + delta
		var mark: MeshInstance3D = r[0]
		var k := clampf(float(r[2]) / ROCK_WARN, 0.0, 1.0)
		if is_instance_valid(mark):
			mark.scale = Vector3(k, 1.0, k)
		if float(r[2]) >= ROCK_WARN:
			_rocks.erase(r)
			if is_instance_valid(mark):
				mark.queue_free()
			_rock_land(r[1])


func _rock_mark(at: Vector3) -> MeshInstance3D:
	var m := Fx.cylinder(ROCK_R, 0.03, Fx.mat(Color(1.0, 0.35, 0.25), 1.5, true, 0.45))
	get_parent().add_child(m)
	m.global_position = at + Vector3(0, 0.05, 0)
	m.scale = Vector3(0.05, 1.0, 0.05)
	return m


func _rock_land(at: Vector3) -> void:
	var rock := Fx.sphere(0.7, Fx.mat(Color(0.32, 0.3, 0.3)))
	get_parent().add_child(rock)
	rock.global_position = at + Vector3(0, 0.5, 0)
	var tw := rock.create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(rock, "scale", Vector3.ONE * 0.05, 0.5)
	tw.tween_callback(rock.queue_free)
	Juice.dust(get_parent(), at, 1.6)
	Sfx.play("teto_desaba" if Sfx.has("teto_desaba") else "pedra_cai", at, 2.0, 0.12, 0.05)
	var p := GameState.player as Player
	if p != null and not p.dead and Fx.flat_dist(p.global_position, at) < ROCK_R + 0.3 and p.state != Player.State.DODGE:
		p.take_damage(ROCK_DAMAGE, null, true)


# ---------------------------------------------------------------- corpo

func _animate(_delta: float, speed_now: float) -> void:
	var moving := speed_now > 0.3
	var ph := _anim_t * maxf(speed_now, 1.0) * 1.1
	for leg: Node3D in _legs:
		var a: float = ph + float(leg.get_meta("phase"))
		leg.rotation.x = sin(a) * 0.35 * (1.0 if moving else 0.0)
	for k in _tail.size():
		var seg: Node3D = _tail[k]
		seg.position.x = sin(_anim_t * (2.6 if cur_attack != null else 1.6) - k * 0.5) * 0.12 * k
	var low := sniffing or stun_t > 0.0
	_head.position.y = 5.0 + (sin(_anim_t * 7.0) * 0.15 - 1.2 if low else sin(_anim_t * 1.3) * 0.12)
	if roar_t > 0.0:
		_head.position.y = 5.6 + sin(_anim_t * 30.0) * 0.08
	# olhos: âmbar dormindo, vermelhos caçando, apagados atordoado; na fase 3, cegos (brancos)
	var eye := Color(1.0, 0.75, 0.3)
	if stun_t > 0.0:
		eye = Color(0.3, 0.25, 0.2)
	elif phase == 3:
		eye = Color(0.85, 0.9, 1.0) if not sniffing else Color(0.5, 0.55, 0.6)
	elif phase > 0:
		eye = Color(1.0, 0.25, 0.15)
	_eye_mat.albedo_color = eye
	_eye_mat.emission = eye
	# veios de cristal: pulsam; atordoado, piscam (ponto fraco aberto)
	var pulse := 0.5 + 0.5 * sin(_anim_t * (8.0 if stun_t > 0.0 else 2.0))
	_vein_mat.emission_energy_multiplier = 1.5 + 3.0 * pulse * (1.6 if stun_t > 0.0 else 1.0)
	(_parts["visual"] as Node3D).position.y = absf(sin(ph)) * 0.1 if moving else 0.0
