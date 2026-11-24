class_name Serpent
extends Creature
## Serpente-cega (G, chefe do Abismo, A12) — a caçadora do silêncio. Não tem olhos.
##   Fase 1 (100–66%): caça pela VIBRAÇÃO (andando 9 m, correndo 16 m; parada ou num fio, não).
##     Sente fios que vibram e teia de captura NOVA (tecer faz tremer). Bote no ponto da
##     vibração; se o bote te pega, ela te ENROLA (constrição): aperte ATAQUE/ESQUIVA rápido
##     para soltar — escapar deixa as escamas abertas por um instante. Se você some (parada
##     ou num fio), ela SIBILA: o eco te acha até 10 m e o sibilo derruba quem está num fio.
##   Fase 2 (66–33%): batida de cauda — uma ONDA de tremor corre pelo chão; só quem está num
##     fio (ou esquivando) passa por cima. Sibilo e onda se alternam: fio te salva da onda,
##     mas o sibilo te derruba dele.
##   Fase 3 (<33%): as fossetas acendem: ela sente CALOR (9 m), ficar parada não basta.
##     O chão racha e sobe VAPOR: dentro do jato ligado ela não te sente.
##   Bote que termina numa teia de captura: morde a teia e fica ENREDADA (dano cheio).
##   Fora disso as escamas seguram 70% do dano.
## O corpo enrolado dela tapa o Poço de vapor (A13): só depois de vencê-la o caminho abre.

enum Mode { PROWL, TURN, WINDUP, LUNGE, RECOVER, BITE, TAIL, COIL, HISS, SLAM }

const SEGMENTS := 16
const SPACING := 0.95
const HEAR_WALK := 9.0
const HEAR_RUN := 16.0
const WEB_FEEL := 22.0
const LUNGE_MAX := 11.0
const LUNGE_SPEED := 15.0
const LUNGE_DAMAGE := 34.0
const BITE_DAMAGE := 26.0
const TAIL_DAMAGE := 22.0
const ARMOR := 0.3
const TANGLE_TIME := 5.5
const PHASE_AT := [1.0, 0.66, 0.33]
## constrição
const GRAB_DAMAGE := 14.0
const COIL_DAMAGE := 7.0
const COIL_TICK := 0.5
const COIL_MAX := 3.5
const OPEN_TIME := 2.2            ## escamas abertas depois que você escapa do aperto
## sibilo (eco)
const HISS_RANGE := 10.0
const HISS_SILENCE := 3.5         ## sem vibração por este tempo, ela sibila
## onda de tremor (fase 2+)
const WAVE_SPEED := 8.0
const WAVE_MAX := 13.0
const WAVE_DAMAGE := 20.0
## calor (fase 3)
const HEAT_RANGE := 9.0
const STEAM_R := 1.5

var arena_center := Vector3.ZERO
var arena_r := 9.0
var mode: Mode = Mode.PROWL
var mode_time := 0.0
var phase := 1
var vib_pos := Vector3.ZERO
var vib_age := 99.0
var vib_trap := false            ## a vibração veio de uma teia de captura
var _lunge_dir := Vector3.FORWARD
var _lunge_len := 0.0
var _lunge_from := Vector3.ZERO
var _hit := false
var _known_traps: Array = []
var _trail: Array[Vector3] = []
var _segs: Array[Node3D] = []
var _prowl_a := 0.0
var _armor_msg := 0.0
var awake := false               ## dorme enrolada até você entrar na arena
var open_time := 0.0             ## escamas abertas (escapou do aperto)
var _coil_tick := 0.0
var _cd_hiss := 4.0
var _cd_slam := 3.0
var _waves: Array = []           ## [{r, node, hit}] ondas de tremor correndo
var vents: Array[Node3D] = []    ## jatos de vapor que abrem na fase 3
var _pits_mat: StandardMaterial3D
var _glow: OmniLight3D
var _tele_lunge := Attack.make("bote", "", {"shape": Attack.Shape.LINE, "reach": LUNGE_MAX, "width": 1.8})
var _tele_bite := Attack.make("mordida", "", {"shape": Attack.Shape.CONE, "reach": 3.0, "arc": 90.0})
var _tele_tail := Attack.make("cauda", "", {"shape": Attack.Shape.RING, "reach": 4.2})
var _tele_hiss := Attack.make("sibilo", "", {"shape": Attack.Shape.RING, "reach": HISS_RANGE})
var _tele_slam := Attack.make("tremor", "", {"shape": Attack.Shape.RING, "reach": 3.0})


func _init() -> void:
	uses_interest = false
	display_name = "Serpente-cega"
	size = Size.G
	level = 13
	max_hp = 300.0
	speed = 3.2
	body_radius = 0.85
	body_color = Color(0.42, 0.4, 0.46)
	food_satiety = 100.0
	food_silk = 70.0
	food_xp = 300
	food_energy = 10.0
	senses_text = "cega: vibração (andando 9 m, correndo 16 m; fios e teias até 22 m) e eco do sibilo (10 m). Ferida, sente CALOR (9 m): só o vapor esconde"
	nav_kind = NavGrid.Kind.LARGE
	aggression = 1.0
	attack_damage = BITE_DAMAGE
	attack_reach = 2.0


func _ready() -> void:
	super._ready()
	_safe_pos = global_position
	add_to_group("boss")
	boss_music = "serpente"
	add_to_group("predator")
	collision_mask = 1
	_web_immune = 999.0
	EventBus.web_touched.connect(_on_web_touched)
	facing = Vector3(0, 0, -1)
	_build_segments()
	for i in int(SEGMENTS * SPACING / 0.15) + 10:
		_trail.append(global_position + Vector3(0, 0, i * 0.15))
	_place_segments()


func _make_brain() -> Brain:
	return null   # segue as próprias regras (_think)


# ---------------------------------------------------------------- sentidos

func feels(p: Player) -> bool:
	if p == null or p.dead:
		return false
	if in_steam(p.global_position):
		return false   # o jato de vapor mascara calor e tremor
	if phase >= 3 and flat_dist_to(p) <= HEAT_RANGE:
		return true    # fossetas: sente o seu calor, parada ou não
	if p.on_strand:
		return false
	var spd := Vector2(p.velocity.x, p.velocity.z).length()
	var d := flat_dist_to(p)
	if spd < 0.8:
		return d < 1.6
	return d <= (HEAR_RUN if spd > Player.WALK_SPEED + 0.5 else HEAR_WALK)


func notices_player(p: Player) -> bool:
	return feels(p)


func _on_web_touched(pos: Vector3, by: Node) -> void:
	if by == self or dead or not awake:
		return
	if Fx.flat_dist(pos, global_position) <= WEB_FEEL:
		_vibrate(pos, false)


func _vibrate(pos: Vector3, trap: bool) -> void:
	vib_pos = Vector3(pos.x, 0.0, pos.z)
	vib_age = 0.0
	vib_trap = trap


func _poll_traps() -> void:
	## Teia de captura nova perto: tecer faz a teia tremer, e ela vem.
	for t in WebNetwork.traps:
		if is_instance_valid(t) and not _known_traps.has(t):
			_known_traps.append(t)
			if Fx.flat_dist(t.global_position, global_position) <= WEB_FEEL:
				_vibrate(t.global_position, true)
				EventBus.message.emit("A teia nova vibra... a Serpente vira a cabeça para ela.")


func wake(_by: Node3D = null) -> void:
	if awake:
		return
	awake = true
	asleep = false
	for t in WebNetwork.traps:
		_known_traps.append(t)
	EventBus.big_message.emit("Serpente-cega")
	EventBus.hint.emit("Ela é cega: sente o chão e as teias. Parada ou num fio, você some — até ela SIBILAR (o eco te acha a 10 m). Arme uma teia de captura: tecer faz a teia vibrar, ela dá o bote nela e fica presa. Se o bote te pegar, aperte ATAQUE/ESQUIVA rápido.")
	GameState.say_once("serpente_inicio", "Sem olhos. Ela não tem OLHOS. Então... ela me ouve. Shhh.")


# ---------------------------------------------------------------- comportamento

func _think(delta: float) -> Vector3:
	mode_time += delta
	vib_age += delta
	open_time = maxf(0.0, open_time - delta)
	_cd_hiss -= delta
	_cd_slam -= delta
	var p := GameState.player as Player
	if not awake:
		return Vector3.ZERO
	_poll_traps()
	var alive := p != null and not p.dead
	if alive and feels(p) and mode != Mode.LUNGE and mode != Mode.WINDUP:
		_vibrate(p.global_position, false)
	var windup := [0.9, 0.7, 0.6][phase - 1] as float
	var spd_mult := [1.0, 1.15, 1.25][phase - 1] as float
	match mode:
		Mode.PROWL, Mode.TURN:
			var dp := flat_dist_to(p) if alive else 99.0
			# fase 2+: batida de cauda quando você está por perto (mesmo quieta: ela chuta)
			if phase >= 2 and _cd_slam <= 0.0 and alive and dp < WAVE_MAX - 1.0 and mode_time > 0.3:
				_begin(Mode.SLAM)
				_cd_slam = 9.0 if phase == 2 else 7.0
				return Vector3.ZERO
			if vib_age < 2.5:
				var d := Fx.flat_dist(global_position, vib_pos)
				face_toward(vib_pos)
				if alive and dp < 3.0 and feels(p):
					if phase >= 2 and _behind(p.global_position):
						_begin(Mode.TAIL)
					else:
						_begin(Mode.BITE)
						face_toward(p.global_position)
					return Vector3.ZERO
				if d <= LUNGE_MAX and d > 2.0 and mode_time > 0.4:
					_begin(Mode.WINDUP)
					face_toward(vib_pos)
					_lunge_len = minf(d + 1.2, LUNGE_MAX)
					_tele_lunge.reach = _lunge_len
					return Vector3.ZERO
				return nav_to(vib_pos, 1.1 * spd_mult)
			# você sumiu (parada, num fio): ela sibila e escuta o eco
			if alive and vib_age > HISS_SILENCE and _cd_hiss <= 0.0 and dp < HISS_RANGE + 3.0:
				_begin(Mode.HISS)
				_cd_hiss = 8.0 if phase == 1 else 6.0
				return Vector3.ZERO
			# nada vibrando: ronda devagar em volta do meio da arena
			activity = "Escutando o chão"
			_prowl_a += delta * 0.25
			var goal := arena_center + Vector3(cos(_prowl_a), 0, sin(_prowl_a)) * arena_r * 0.6
			return nav_to(goal, 0.45)
		Mode.WINDUP:
			activity = "Bote"
			show_marker(_tele_lunge, global_position, mode_time / windup)
			if mode_time >= windup:
				hide_marker()
				telegraph = false
				mode = Mode.LUNGE
				mode_time = 0.0
				_lunge_dir = facing
				_lunge_from = global_position
				_hit = false
				Sfx.play("serpente_bote", global_position)
			return Vector3.ZERO
		Mode.LUNGE:
			var gone := Fx.flat_dist(global_position, _lunge_from)
			if not _hit and alive and flat_dist_to(p) < body_radius + 0.9:
				_hit = true
				if p.grab(self, COIL_MAX):
					_start_coil(p)
					return Vector3.ZERO
				p.take_damage(LUNGE_DAMAGE * spd_mult, self)
			if _bite_trap():
				return Vector3.ZERO
			if gone >= _lunge_len or mode_time > 1.2:
				_end(0.9)
				return Vector3.ZERO
			if mode_time > 0.25 and Vector2(get_real_velocity().x, get_real_velocity().z).length() < 2.0:
				_end(1.3)   # bateu na pedra
				EventBus.message.emit("A Serpente bateu de cabeça na rocha!")
				return Vector3.ZERO
			return _lunge_dir * LUNGE_SPEED * spd_mult
		Mode.RECOVER:
			activity = "Tonta" if open_time > 0.0 else "Recuperando"
			if mode_time >= 0.0:
				mode = Mode.PROWL
				mode_time = 0.0
				vib_age = 99.0
			return Vector3.ZERO
		Mode.BITE:
			activity = "Mordida"
			if not _hit:
				show_marker(_tele_bite, global_position, mode_time / 0.5)
			if not _hit and mode_time >= 0.5:
				_hit = true
				hide_marker()
				telegraph = false
				if alive and flat_dist_to(p) <= 3.2 and _in_front(p.global_position):
					p.take_damage(BITE_DAMAGE, self)
			if mode_time >= 1.0:
				_end(0.3)
			return Vector3.ZERO
		Mode.TAIL:
			activity = "Chicote de cauda"
			if not _hit:
				show_marker(_tele_tail, global_position, mode_time / 0.55)
			if not _hit and mode_time >= 0.55:
				_hit = true
				hide_marker()
				telegraph = false
				if alive and flat_dist_to(p) <= 4.4:
					p.take_damage(TAIL_DAMAGE, self)
			if mode_time >= 1.0:
				_end(0.4)
			return Vector3.ZERO
		Mode.COIL:
			activity = "Enrolando"
			if not alive or p.held_by != self:
				if mode == Mode.COIL:
					_end(0.6)
				return Vector3.ZERO
			global_position = global_position.move_toward(Vector3(p.global_position.x, global_position.y, p.global_position.z) - facing * 0.9, delta * 4.0)
			_coil_tick -= delta
			if _coil_tick <= 0.0:
				_coil_tick = COIL_TICK
				p.invuln = 0.0
				p.take_damage(COIL_DAMAGE, self, false)
				Sfx.play("serpente_aperta" if Sfx.has("serpente_aperta") else "serpente_sibilo", global_position, -6.0, 0.15, 0.3)
			return Vector3.ZERO
		Mode.HISS:
			activity = "Sibilando"
			var hw := 0.9 if phase == 1 else 0.7
			if not _hit:
				show_marker(_tele_hiss, global_position, mode_time / hw)
				if mode_time >= hw:
					_hit = true
					hide_marker()
					telegraph = false
					_hiss(p)
			if mode_time >= hw + 0.3:
				_end(0.2)
				if vib_age < 0.5:
					mode = Mode.PROWL   # achou: já vai pro bote
					mode_time = 0.5
			return Vector3.ZERO
		Mode.SLAM:
			activity = "Batida de cauda"
			var sw := 1.1 if phase == 2 else 0.85
			if not _hit:
				show_marker(_tele_slam, global_position, mode_time / sw)
				if mode_time >= sw:
					_hit = true
					hide_marker()
					telegraph = false
					_slam()
			if mode_time >= sw + 0.5:
				_end(0.5)
			return Vector3.ZERO
	return Vector3.ZERO


# ---------------------------------------------------------------- golpes

func _start_coil(p: Player) -> void:
	mode = Mode.COIL
	mode_time = 0.0
	telegraph = false
	hide_marker()
	_coil_tick = 0.15
	p.invuln = 0.0
	p.take_damage(GRAB_DAMAGE, self, false)
	if GameState.said.has("serpente_enrola"):
		EventBus.message.emit("Enrolada! ATAQUE/ESQUIVA rápido!")
	else:
		EventBus.big_message.emit("Enrolada! Aperte ATAQUE ou ESQUIVA rápido!")
		GameState.say_once("serpente_enrola", "Ela me ENROLOU! Solta, solta, SOLTA!")


func on_hold_released(escaped: bool) -> void:
	## A jogadora saiu do aperto. Escapou na força: a Serpente fica tonta, escamas abertas.
	if dead:
		return
	if escaped:
		open_time = OPEN_TIME
		_end(OPEN_TIME)
		EventBus.big_message.emit("Ela afrouxou! As escamas abriram!")
		GameState.say_once("serpente_solta", "Me soltei! E ela ficou aberta! BATE!")
	else:
		_end(0.6)


func _hiss(p: Player) -> void:
	## Sibilo: o eco acha quem está perto (parada ou não) e o tremor derruba quem está num fio.
	Sfx.play("serpente_sibilo", global_position, 4.0)
	if p == null or p.dead or flat_dist_to(p) > HISS_RANGE or in_steam(p.global_position):
		return
	_vibrate(p.global_position, false)
	if p.on_strand:
		var s := WebNetwork.strand_near(p.global_position, 0.8)
		var off := Vector3.ZERO
		if s != null:
			var along: Vector3 = (s.b_pos - s.a_pos)
			along.y = 0.0
			off = Vector3(-along.z, 0.0, along.x).normalized()
			if off.dot(p.global_position - global_position) < 0.0:
				off = -off
		else:
			off = (p.global_position - global_position).normalized()
		p.external_velocity = off * 7.0
		p.apply_slow(0.6, 1.5)
		p.shake(0.15)
		if GameState.said.has("serpente_sibilo_fio"):
			EventBus.message.emit("O sibilo sacudiu o fio e te jogou no chão!")
		else:
			EventBus.big_message.emit("O sibilo sacode os fios!")
			GameState.say_once("serpente_sibilo_fio", "O fio TREMEU! Ela me achou pelo eco!")
	elif not GameState.said.has("serpente_eco"):
		GameState.say_once("serpente_eco", "Ela sibilou e... virou direto pra mim. Eco. Ela enxerga com ECO.")


func _slam() -> void:
	## Batida de cauda: a onda corre pelo chão. Num fio (ou esquivando) você passa por cima.
	Sfx.play("serpente_cauda" if Sfx.has("serpente_cauda") else "pedra_cai", global_position, 5.0)
	Juice.dust(get_parent(), global_position, 2.0)
	var ring := MeshInstance3D.new()
	ring.mesh = ImmediateMesh.new()
	ring.material_override = _wave_mat()
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(ring)
	ring.global_position = Vector3(global_position.x, 0.06, global_position.z)
	_waves.append({"c": Vector3(global_position.x, 0.0, global_position.z), "r": 0.5, "node": ring, "hit": false})
	if not GameState.said.has("serpente_onda"):
		EventBus.message.emit("Uma onda de tremor corre pelo chão: suba num fio ou esquive por cima!")
		GameState.say_once("serpente_onda", "O chão tá ONDULANDO. Fio. Preciso de um fio. AGORA.")


func _tick_waves(delta: float) -> void:
	var p := GameState.player as Player
	for w in _waves.duplicate():
		w["r"] = float(w["r"]) + WAVE_SPEED * delta
		var r := float(w["r"])
		var node := w["node"] as MeshInstance3D
		if is_instance_valid(node):
			_draw_wave(node.mesh as ImmediateMesh, r, 1.0 - r / WAVE_MAX)
		if not bool(w["hit"]) and p != null and not p.dead:
			var d := Fx.flat_dist(p.global_position, w["c"])
			if absf(d - r) < 0.7 and p.global_position.y < 0.6:
				w["hit"] = true   # a onda passa uma vez só por você
				if p.on_strand:
					EventBus.message.emit("O fio te segurou acima da onda!")
				elif p.take_damage(WAVE_DAMAGE, self, false):
					p.apply_slow(0.5, 1.2)
					p.shake(0.3)
		if r >= WAVE_MAX:
			if is_instance_valid(node):
				node.queue_free()
			_waves.erase(w)


var _wave_m: StandardMaterial3D


func _wave_mat() -> StandardMaterial3D:
	if _wave_m == null:
		_wave_m = StandardMaterial3D.new()
		_wave_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_wave_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_wave_m.vertex_color_use_as_albedo = true
		_wave_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _wave_m


func _draw_wave(im: ImmediateMesh, r: float, life: float) -> void:
	## Anel de poeira no chão: a frente da onda (onde ela machuca) bem marcada.
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var r0 := maxf(0.0, r - 0.45)
	var r1 := r + 0.3
	var col := Color(0.95, 0.75, 0.5, 0.75 * clampf(life + 0.2, 0.0, 1.0))
	var n := 64
	for i in n:
		var a0 := i * TAU / n
		var a1 := (i + 1) * TAU / n
		var p00 := Vector3(cos(a0) * r0, 0.0, sin(a0) * r0)
		var p01 := Vector3(cos(a0) * r1, 0.0, sin(a0) * r1)
		var p10 := Vector3(cos(a1) * r0, 0.0, sin(a1) * r0)
		var p11 := Vector3(cos(a1) * r1, 0.0, sin(a1) * r1)
		for v in [p00, p01, p11, p00, p11, p10]:
			im.surface_set_color(col)
			im.surface_add_vertex(v)
	im.surface_end()


func _open_vents() -> void:
	## Fase 3: o chão da toca racha e sobe vapor do Poço. Dentro do jato ligado ela não te sente.
	if not vents.is_empty() or get_parent() == null:
		return
	var offs := [Vector3(-4.5, 0, 2.5), Vector3(4.5, 0, -1.5), Vector3(0.5, 0, -4.5), Vector3(-1.0, 0, 4.8)]
	for i in offs.size():
		var at: Vector3 = arena_center + offs[i]
		if World.nav != null and not World.nav.walkable(at):
			continue
		var v := Node3D.new()
		v.name = "VaporSerpente%d" % i
		get_parent().add_child(v)
		v.global_position = Vector3(at.x, 0.0, at.z)
		var rim := Fx.cylinder(STEAM_R * 0.6, 0.06, Fx.mat(Color(0.12, 0.08, 0.07)))
		rim.position.y = 0.03
		v.add_child(rim)
		var glow := Fx.cylinder(STEAM_R * 0.35, 0.07, Fx.mat(Color(1.0, 0.45, 0.2), 2.0, true))
		glow.position.y = 0.04
		v.add_child(glow)
		var steam := Fx.cylinder(STEAM_R, 3.2, Fx.mat(Color(0.95, 0.93, 0.92), 0.5, true, 0.3))
		steam.position.y = 1.6
		v.add_child(steam)
		v.set_meta("steam", steam)
		v.set_meta("t", float(i) * 1.3)
		vents.append(v)


func vent_on(v: Node3D) -> bool:
	## 3 s ligado, 2 s desligado; cada jato num tempo.
	return fmod(float(v.get_meta("t", 0.0)), 5.0) < 3.0


func in_steam(pos: Vector3) -> bool:
	for v in vents:
		if is_instance_valid(v) and vent_on(v) and Fx.flat_dist(v.global_position, pos) <= STEAM_R:
			return true
	return false


func _tick_vents(delta: float) -> void:
	for v in vents:
		if is_instance_valid(v):
			v.set_meta("t", float(v.get_meta("t", 0.0)) + delta)
			var st := v.get_meta("steam") as Node3D
			if st != null:
				st.visible = vent_on(v)


func _bite_trap() -> bool:
	## O bote terminou numa teia de captura: morde a teia e se enrosca.
	var head := global_position + facing * (body_radius + 0.4)
	for t in WebNetwork.traps.duplicate():
		if is_instance_valid(t) and Fx.flat_dist(t.global_position, head) < CaptureWeb.RADIUS + 0.5:
			WebNetwork.remove_trap(t)
			_end(0.0)
			entangle_raw(TANGLE_TIME)
			_web_immune = 999.0
			EventBus.big_message.emit("Enredada! As escamas abriram!")
			GameState.say_once("serpente_presa", "Mordeu a isca! AGORA, AGORA, AGORA!")
			return true
	return false


func _behind(pos: Vector3) -> bool:
	var to := pos - global_position
	to.y = 0.0
	return to.length() > 0.1 and facing.angle_to(to.normalized()) > deg_to_rad(100.0)


func _in_front(pos: Vector3) -> bool:
	var to := pos - global_position
	to.y = 0.0
	return to.length() < body_radius or facing.angle_to(to.normalized()) <= deg_to_rad(50.0)


func _begin(m: Mode) -> void:
	mode = m
	mode_time = 0.0
	_hit = false
	telegraph = true


func _end(pause: float) -> void:
	hide_marker()
	telegraph = false
	mode = Mode.RECOVER
	mode_time = -pause


# ---------------------------------------------------------------- dano

func take_damage(amount: float, source: Node3D = null) -> void:
	if dead:
		return
	if not awake:
		wake(source)
	if not is_entangled() and open_time <= 0.0:
		amount *= ARMOR
		_armor_msg -= 1.0
		if _armor_msg <= 0.0 and source != null and source.is_in_group("player"):
			_armor_msg = 6.0
			EventBus.message.emit("As escamas seguram o golpe. Faça ela morder uma teia de captura (ou escape do aperto)!")
	super.take_damage(amount, source)
	if dead:
		return
	if phase == 1 and hp <= max_hp * float(PHASE_AT[1]):
		phase = 2
		_cd_slam = 1.5
		EventBus.big_message.emit("A Serpente se enfurece!")
		GameState.say_once("serpente_furia", "Ela tá batendo a cauda no chão. O chão inteiro ONDULA. Ótimo. ÓTIMO.")
	if phase == 2 and hp <= max_hp * float(PHASE_AT[2]):
		phase = 3
		_open_vents()
		if _pits_mat != null:
			_pits_mat.emission_energy_multiplier = 5.0
		if _glow != null:
			_glow.light_color = Color(1.0, 0.45, 0.3)
		EventBus.big_message.emit("As fossetas acendem: ela sente CALOR!")
		EventBus.hint.emit("Agora ficar parada não basta: ela sente o seu calor a 9 m. Esconda-se nos jatos de VAPOR que abriram no chão.")
		GameState.say_once("serpente_calor", "As manchas da cara dela tão BRILHANDO. Ela sente meu calor?! O vapor... o vapor esconde!")


func add_poison(n := 1, cap := MAX_POISON) -> void:
	if is_entangled():
		super.add_poison(n, cap)


func entangle(_duration: float) -> float:
	return 0.0   # teia comum ela arrebenta; só o bote numa teia de captura prende


var _safe_pos := Vector3.ZERO


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if absf(global_position.y) < 0.3 and World.nav != null and World.nav.walkable(global_position, NavGrid.Kind.LARGE):
		_safe_pos = Vector3(global_position.x, 0.05, global_position.z)
	_tick_waves(delta)
	if dead:
		return
	_tick_vents(delta)
	if not is_entangled():
		_web_immune = 999.0
		for s in WebNetwork.strands.duplicate():
			if is_instance_valid(s) and s.distance_to(global_position) < body_radius + 0.3:
				WebNetwork.remove_strand(s)
	_update_trail()


func die(fell: bool = false) -> void:
	if fell and not dead and hp > 0.0:
		# chefe não morre de queda (espremida num pilar, empurrada para fora da grade):
		# volta para o último chão bom e segue a luta
		global_position = _safe_pos
		velocity = Vector3.ZERO
		external_velocity = Vector3.ZERO
		return
	var p := GameState.player as Player
	if p != null and p.held_by == self:
		p.release_hold(false)
	for w in _waves:
		if is_instance_valid(w["node"]):
			(w["node"] as Node).queue_free()
	_waves.clear()
	for v in vents:
		if is_instance_valid(v):
			v.queue_free()
	vents.clear()
	for s in _segs:
		if is_instance_valid(s):
			s.queue_free()
	super.die(fell)


# ---------------------------------------------------------------- corpo

func _build_visual() -> void:
	var head := Fx.sphere(body_radius, _mat)
	head.scale = Vector3(1.0, 0.55, 1.5)
	head.position.y = body_radius * 0.55
	_visual.add_child(head)
	var scar := Fx.mat(Color(0.75, 0.72, 0.7))
	for sd: float in [-1.0, 1.0]:   # onde seriam os olhos: só pele lisa e clara
		var s := Fx.sphere(0.16, scar)
		s.scale = Vector3(1.0, 0.4, 1.3)
		s.position = Vector3(sd * 0.45, body_radius * 0.8, -body_radius * 0.6)
		_visual.add_child(s)
	var fang := Fx.mat(Color(0.95, 0.93, 0.85), 0.3)
	for sd: float in [-1.0, 1.0]:
		var f := Fx.cylinder(0.06, 0.45, fang)
		(f.mesh as CylinderMesh).top_radius = 0.005
		f.position = Vector3(sd * 0.3, body_radius * 0.3, -body_radius * 1.35)
		f.rotation.x = PI
		_visual.add_child(f)
	var pits := Fx.mat(Color(0.9, 0.5, 0.4), 1.5, true)   # fossetas que sentem o tremor (brilham fraco)
	_pits_mat = pits
	for sd: float in [-1.0, 1.0]:
		var pt := Fx.sphere(0.07, pits)
		pt.position = Vector3(sd * 0.55, body_radius * 0.55, -body_radius * 1.1)
		_visual.add_child(pt)
	var glow := OmniLight3D.new()   # escamas claras refletem a pouca luz: dá para ver a cabeça chegando
	glow.light_color = Color(0.85, 0.8, 0.95)
	glow.omni_range = 4.5
	glow.light_energy = 0.7
	glow.position = Vector3(0, 1.6, 0)
	_visual.add_child(glow)
	_glow = glow


func _build_segments() -> void:
	var belly := Fx.mat(body_color.lightened(0.25))
	for i in SEGMENTS:
		var k := 1.0 - float(i) / SEGMENTS * 0.7
		var seg := Node3D.new()
		seg.top_level = true
		var s := Fx.sphere(body_radius * 0.95 * k, _mat)
		s.scale = Vector3(1.0, 0.6, 1.25)
		s.position.y = body_radius * 0.5 * k
		seg.add_child(s)
		var b := Fx.box(Vector3(body_radius * 1.1 * k, 0.05, body_radius * 0.9 * k), belly)
		b.position.y = 0.06
		seg.add_child(b)
		add_child(seg)
		_segs.append(seg)


func _update_trail() -> void:
	var head := global_position
	if _trail.is_empty() or head.distance_to(_trail[0]) > 0.15:
		_trail.insert(0, head)
		var cap := int(SEGMENTS * SPACING / 0.15) + 12
		while _trail.size() > cap:
			_trail.pop_back()
	_place_segments()


func _place_segments() -> void:
	var step := int(SPACING / 0.15)
	var p := GameState.player as Player
	var coiling := mode == Mode.COIL and p != null and p.held_by == self
	for i in _segs.size():
		if coiling and i < 9:
			# os primeiros anéis dão voltas em você, subindo
			var ang := float(i) * TAU / 6.0 + _anim_t * 1.5
			var c := Vector3(p.global_position.x, 0.0, p.global_position.z)
			_segs[i].global_position = c + Vector3(cos(ang), 0.0, sin(ang)) * 1.05 + Vector3.UP * float(i) * 0.14
			_segs[i].rotation.y = -ang
			continue
		var ti := mini((i + 1) * step, _trail.size() - 1)
		var pos: Vector3 = _trail[ti]
		var ahead: Vector3 = _trail[maxi(ti - step, 0)]
		var wave := sin(_anim_t * 4.0 - i * 0.7) * 0.18 * (0.0 if is_entangled() else 1.0)
		var dir := ahead - pos
		dir.y = 0.0
		var side := Vector3(-dir.z, 0, dir.x).normalized() if dir.length() > 0.01 else Vector3.RIGHT
		_segs[i].global_position = Vector3(pos.x, 0.0, pos.z) + side * wave
		if dir.length() > 0.01:
			_segs[i].rotation.y = atan2(-dir.x, -dir.z)


func can_raid() -> bool:
	return false
