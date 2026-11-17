class_name Serpent
extends Creature
## Serpente-cega (G, chefe do Abismo, A12). Não tem olhos: caça só pela VIBRAÇÃO.
##   - Sente quem anda no chão (andando 9 m, correndo 16 m). Parada ou sobre um fio, não.
##   - Sente qualquer fio ou teia que vibra perto (um bicho preso, um fio arrebentado) e
##     uma teia de captura NOVA: tecer a teia faz ela tremer. Vai sempre na vibração mais nova.
##   - Bote: mira o ponto da vibração, avisa (linha no chão) e dispara. Se o bote acaba numa
##     teia de captura, ela morde a teia e fica ENREDADA (as escamas abrem: dano cheio).
##     Fora disso as escamas seguram 70% do dano.
##   - De perto: mordida em cone; furiosa (metade da vida), chicote de cauda em volta.
## O corpo enrolado dela tapa o Poço de vapor (A13): só depois de vencê-la o caminho abre.

enum Mode { PROWL, TURN, WINDUP, LUNGE, RECOVER, BITE, TAIL }

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
var _tele_lunge := Attack.make("bote", "", {"shape": Attack.Shape.LINE, "reach": LUNGE_MAX, "width": 1.8})
var _tele_bite := Attack.make("mordida", "", {"shape": Attack.Shape.CONE, "reach": 3.0, "arc": 90.0})
var _tele_tail := Attack.make("cauda", "", {"shape": Attack.Shape.RING, "reach": 4.2})


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
	senses_text = "cega: só vibração (andando 9 m, correndo 16 m; fios e teias até 22 m). Parada ou num fio, ela não te sente"
	nav_kind = NavGrid.Kind.LARGE
	aggression = 1.0
	attack_damage = BITE_DAMAGE
	attack_reach = 2.0


func _ready() -> void:
	super._ready()
	add_to_group("boss")
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
	if p == null or p.dead or p.on_strand:
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
	EventBus.hint.emit("Ela é cega: sente o chão e as teias. Parada ou num fio, você some. Arme uma teia de captura: tecer faz a teia vibrar, ela dá o bote nela e fica presa. Enredada, as escamas abrem.")
	GameState.say_once("serpente_inicio", "Sem olhos. Ela não tem OLHOS. Então... ela me ouve. Shhh.")


# ---------------------------------------------------------------- comportamento

func _think(delta: float) -> Vector3:
	mode_time += delta
	vib_age += delta
	var p := GameState.player as Player
	if not awake:
		return Vector3.ZERO
	_poll_traps()
	if p != null and feels(p) and mode != Mode.LUNGE and mode != Mode.WINDUP:
		_vibrate(p.global_position, false)
	var windup := 0.9 if phase == 1 else 0.65
	var spd_mult := 1.0 if phase == 1 else 1.2
	match mode:
		Mode.PROWL, Mode.TURN:
			if vib_age < 2.5:
				var d := Fx.flat_dist(global_position, vib_pos)
				face_toward(vib_pos)
				if p != null and not p.dead and flat_dist_to(p) < 3.0 and feels(p):
					if phase == 2 and _behind(p.global_position):
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
			return Vector3.ZERO
		Mode.LUNGE:
			var gone := Fx.flat_dist(global_position, _lunge_from)
			if not _hit and p != null and not p.dead and flat_dist_to(p) < body_radius + 0.9:
				_hit = true
				p.take_damage(LUNGE_DAMAGE * (1.15 if phase == 2 else 1.0), self)
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
			activity = "Recuperando"
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
				if p != null and not p.dead and flat_dist_to(p) <= 3.2 and _in_front(p.global_position):
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
				if p != null and not p.dead and flat_dist_to(p) <= 4.4:
					p.take_damage(TAIL_DAMAGE, self)
			if mode_time >= 1.0:
				_end(0.4)
			return Vector3.ZERO
	return Vector3.ZERO


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
	if not is_entangled():
		amount *= ARMOR
		_armor_msg -= 1.0
		if _armor_msg <= 0.0 and source != null and source.is_in_group("player"):
			_armor_msg = 6.0
			EventBus.message.emit("As escamas seguram o golpe. Faça ela morder uma teia de captura!")
	super.take_damage(amount, source)
	if not dead and phase == 1 and hp <= max_hp * 0.5:
		phase = 2
		EventBus.big_message.emit("A Serpente se enfurece!")
		GameState.say_once("serpente_furia", "Ela tá tremendo o chão inteiro agora. Ótimo. ÓTIMO.")


func add_poison() -> void:
	if is_entangled():
		super.add_poison()


func entangle(_duration: float) -> float:
	return 0.0   # teia comum ela arrebenta; só o bote numa teia de captura prende


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if dead:
		return
	if not is_entangled():
		_web_immune = 999.0
		for s in WebNetwork.strands.duplicate():
			if is_instance_valid(s) and s.distance_to(global_position) < body_radius + 0.3:
				WebNetwork.remove_strand(s)
	_update_trail()


func die(fell: bool = false) -> void:
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
	for i in _segs.size():
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
