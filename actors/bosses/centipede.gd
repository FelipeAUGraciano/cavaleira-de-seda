class_name Centipede
extends Creature
## Centopeia-blindada (G, chefe das Galerias).
##
## Vida (como um monstro de Monster Hunter): patrulha as câmaras do leste (G8, G9, G11, G13,
## G14), caça sapos, lagartos e larvas, dorme no covil quando os fungos acendem, deixa rastro
## de arrasto e arrebenta os fios por onde passa. Ferida (35% do PV), foge mancando para o
## covil e dorme para se curar. Quando chega na câmara onde você está, o chão treme.
##
## Sente VIBRAÇÃO: percebe quem anda no chão (correr vibra mais). Quem está sobre um fio
## ou parada não vibra. Ataques: mordida de perto, investida em linha reta, CAVAR (some na
## terra, a rachadura segue a sua vibração e ela sai embaixo de você) e cuspe de ácido em leque
## (deixa poças). Furiosa: a investida quica nas paredes (até 2x) e ela te CERCA em anel.
## A carapaça segura 90% do dano e o veneno não entra. Ela só cede quando a Centopeia
## está ENREDADA, e isso só acontece quando ela investe ATRAVÉS de um fio esticado
## (o fio arrebenta). Na metade da vida ela se enfurece: investe mais rápido e com aviso menor.

enum Mode { IDLE, HUNT, WINDUP, CHARGE, RECOVER, BITE, BURROW, UNDER, EMERGE, SPIT, CIRCLE, SQUEEZE }

const SEGMENTS := 12
const SPACING := 1.05
const SENSE_RANGE := 18.0
const CHARGE_SPEED := 13.0
const CHARGE_TIME := 1.3
## marcas no chão (substituem o brilho amarelo): investida em linha e mordida em cone
var _tele_charge := Attack.make("investida", "", {"shape": Attack.Shape.LINE, "reach": 10.0, "width": 2.6})
var _tele_bite := Attack.make("mordida", "", {"shape": Attack.Shape.CONE, "reach": 3.0, "arc": 80.0})
const BITE_DAMAGE := 34.0
const CHARGE_DAMAGE := 40.0
const ARMOR := 0.1
const TANGLE_TIME := 4.5

var arena_center := Vector3.ZERO
var mode: Mode = Mode.IDLE
var mode_time := 0.0
var charge_dir := Vector3.FORWARD
var phase := 1
var attack_done := false
var announced := false          ## já avisou "Centopeia-blindada" na primeira luta
var _room := ""
var _arrive_cd := 0.0
var _track_from := Vector3.ZERO
var _trail: Array[Vector3] = []
var _segs: Array[Node3D] = []
var _seg_depth: Array[float] = []     ## comprimento (frente-trás) de cada placa
var _seg_pos: Array[Vector3] = []     ## onde cada placa está (a corrente puxa daqui)
var _joints: Array[MeshInstance3D] = []   ## "coluna" escura entre as placas: o corpo nunca parece solto
const HEAD_BACK := 1.45                ## da posição da cabeça até a nuca (a nuca fica a 70% disso: a borda de trás do casco)
const OVERLAP := 0.78                  ## placas se sobrepõem um pouco, como armadura
var _armor_msg_cd := 0.0

## Escavadora: some na terra e segue a vibração por baixo (rachadura), sai embaixo de você.
const BURROW_TIME := 0.7
const UNDER_MAX := 5.5
const UNDER_SPEED := 1.8        ## x speed (mais devagar que você correndo: dá para fugir)
const SINK_DEPTH := 2.6
const ERUPT_R := 2.4
const ERUPT_DAMAGE := 32.0
const SPIT_DAMAGE := 12.0
const SPIT_REACH := 6.5
const CIRCLE_R := 4.2
const CIRCLE_SPEED := 9.0
const SQUEEZE_DAMAGE := 36.0
const COIL_TOUCH := 12.0
var under := false
var _sink := 0.0
var _roll := 0.0
var _bounces := 0                ## furiosa: quica nas paredes e investe de novo (até 2x)
var _bounce_wait := false
var _cd_burrow := 4.0
var _cd_spit := 2.0
var _cd_circle := 2.0
var _crack_from := Vector3.ZERO
var _circle_c := Vector3.ZERO
var _circle_turn := 0.0
var _circle_dir := 1.0
var _touch_cd := 0.0
var _stuck_t := 0.0
var _tele_erupt := Attack.make("erupcao", "", {"shape": Attack.Shape.CIRCLE, "reach": ERUPT_R, "at_point": true})
var _tele_spit := Attack.make("cuspe", "", {"shape": Attack.Shape.CONE, "reach": SPIT_REACH, "arc": 55.0})
var _tele_squeeze := Attack.make("cerco", "", {"shape": Attack.Shape.CIRCLE, "reach": CIRCLE_R, "at_point": true})


func _init() -> void:
	uses_interest = false   # segue as próprias regras (chefe / território)
	display_name = "Centopeia-blindada"
	size = Size.G
	level = 12
	max_hp = 360.0
	speed = 3.4
	body_radius = 0.9
	body_color = Color(0.36, 0.4, 0.48)
	food_satiety = 100.0
	food_silk = 60.0
	food_xp = 220
	food_skin = true
	senses_text = "vibração (18 m): sente quem anda no chão; sobre um fio ou parada, você não vibra"
	model_name = "centopeia_cabeca"
	model_size = 2.2
	model_fit = "length"
	rest_phase = CaveClock.Phase.BRILHO
	nav_kind = NavGrid.Kind.LARGE
	roam_speed = 0.55
	hunt_burst = 1.6
	aggression = 1.0
	track_range = 24.0
	stalk_speed = 0.6
	retreat_frac = 0.35
	retreat_speed = 0.55
	retreat_cooldown = 120.0
	sleep_heal = 0.004
	den_radius = 3.0
	hunger_threshold = 45.0
	attack_damage = BITE_DAMAGE
	attack_reach = 1.8
	memory_time = 3.0
	needs.hunger_rate = 0.35


func _ready() -> void:
	super._ready()
	_safe_pos = global_position
	Sfx.loop_on(self, "centopeia_patas_loop", func(): return not dead and Vector2(velocity.x, velocity.z).length() > 1.5, 2.0)
	add_to_group("boss")
	boss_music = "centopeia"
	add_to_group("predator")
	collision_mask = 1   # atravessa a jogadora na investida (o dano é pelo contato)
	facing = Vector3(0, 0, -1)
	_build_segments()
	_reset_trail()
	_track_from = global_position


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Caçando você")) \
		.add(Behaviors.Retreat.new()) \
		.add(Behaviors.Stalk.new()) \
		.add(Behaviors.Forage.new()) \
		.add(Behaviors.Sleep.new()) \
		.add(Behaviors.Roam.new()) \
		.add(Behaviors.Wander.new(6.0, 0.3))


func _build_visual() -> void:
	var head := Fx.sphere(body_radius, _mat)
	head.scale = Vector3(1.1, 0.6, 1.2)
	head.position.y = body_radius * 0.6
	_visual.add_child(head)
	var jaw_mat := Fx.mat(Color(0.75, 0.6, 0.3), 0.3)
	for side in [-1.0, 1.0]:
		var jaw := Fx.box(Vector3(0.12, 0.12, 0.8), jaw_mat)
		jaw.position = Vector3(side * 0.45, body_radius * 0.5, -body_radius * 1.2)
		jaw.rotation.y = side * 0.35
		_visual.add_child(jaw)
	var eye_mat := Fx.mat(Color(0.6, 0.9, 1.0), 2.0, true)
	for side in [-1.0, 1.0]:
		var eye := Fx.sphere(0.12, eye_mat)
		eye.position = Vector3(side * 0.4, body_radius * 0.95, -body_radius * 0.8)
		_visual.add_child(eye)


func _build_segments() -> void:
	var leg_mat := Fx.mat(body_color.darkened(0.35))
	for i in SEGMENTS:
		var seg := Node3D.new()
		seg.top_level = true
		var k := 1.0 - float(i) / SEGMENTS * 0.45
		var model_name_seg := "centopeia_cauda" if i == SEGMENTS - 1 else "centopeia_segmento"
		var m := Models.instance(model_name_seg, (1.6 if i == SEGMENTS - 1 else 2.0) * k, "max")
		var depth := 0.9 * k
		if m != null:
			seg.add_child(m)
			var box := Models.bounds(m, Transform3D.IDENTITY)
			if box.size.z > 0.05:
				depth = box.size.z
		else:
			var shell := Fx.sphere(0.8 * k, _mat)
			shell.scale = Vector3(1.15, 0.55, 0.8)
			shell.position.y = 0.5 * k
			seg.add_child(shell)
			for side in [-1.0, 1.0]:
				var leg := Fx.box(Vector3(0.9 * k, 0.08, 0.1), leg_mat)
				leg.position = Vector3(side * 0.85 * k, 0.2, 0.0)
				leg.rotation.z = side * -0.4
				seg.add_child(leg)
		add_child(seg)
		_segs.append(seg)
		_seg_depth.append(depth)
		# junta: cilindro escuro ligando esta placa à anterior (ou à cabeça)
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.2 * k
		cyl.bottom_radius = 0.24 * k
		cyl.height = 1.0
		cyl.radial_segments = 10
		cyl.rings = 1
		var joint := MeshInstance3D.new()
		joint.mesh = cyl
		joint.material_override = leg_mat
		joint.top_level = true
		joint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(joint)
		_joints.append(joint)


func _reset_trail() -> void:
	_seg_pos.clear()   # a corrente volta reta atrás da cabeça
	_trail.clear()
	var back := -facing
	for i in int(SEGMENTS * SPACING / 0.15) + 10:
		_trail.append(global_position + back * (i * 0.15))
	_place_segments()


# ---------------------------------------------------------------- sentidos

func feels(p: Player) -> bool:
	if p == null or p.dead or p.on_strand:
		return false
	var spd := Vector2(p.velocity.x, p.velocity.z).length()
	var d := flat_dist_to(p)
	if spd < 0.8:
		return d < 2.0
	var r := SENSE_RANGE if spd > Player.WALK_SPEED + 0.5 else SENSE_RANGE * 0.75
	if asleep:
		r *= 0.3
	return d <= r


func notices_player(p: Player) -> bool:
	return feels(p)


func is_threat(_o: Creature) -> bool:
	return false


func is_prey(o: Creature) -> bool:
	if int(o.size) >= int(Size.G):
		return false
	return not (o is Bat and o.global_position.y > 1.0)


func eats_carrion() -> bool:
	return true


func engaged() -> bool:
	return brain != null and brain.is_doing("combat")


func on_retreat() -> void:
	if under:
		_set_under(false)
	hide_marker()
	mode = Mode.IDLE
	telegraph = false
	EventBus.big_message.emit("A Centopeia foge mancando para o covil!")
	GameState.say_once("centopeia_foge", "Ela tá fugindo! Ferida! ...Eu devia ir atrás? Eu devia ir atrás.")


func _sense() -> void:
	super._sense()
	_arrive_cd -= sense_interval()
	if World.nav == null:
		return
	var r := World.nav.room_at(global_position)
	if r != "" and r != _room:
		_room = r
		var layer = GameState.current_layer
		if _arrive_cd <= 0.0 and layer != null and layer.map_system != null and layer.map_system.current_room == r and not engaged():
			_arrive_cd = 30.0
			EventBus.message.emit("O chão treme: a Centopeia-blindada chegou aqui!")
			GameState.say_once("centopeia_chegou", "Esse tremor... ela está AQUI.")


func _tear_strands() -> void:
	## Passeando, ela arrebenta fios; lutando, só a investida conta (e aí ela se enrosca).
	if not engaged():
		super._tear_strands()


# ---------------------------------------------------------------- comportamento

const LOCKED := [Mode.WINDUP, Mode.CHARGE, Mode.BITE, Mode.BURROW, Mode.UNDER, Mode.EMERGE, Mode.SPIT, Mode.CIRCLE, Mode.SQUEEZE]


func combat_wants() -> bool:
	return player_memory > 0.0 or LOCKED.has(mode) or (mode == Mode.RECOVER and mode_time < 0.0)


func combat_locked() -> bool:
	return LOCKED.has(mode)


func combat_start() -> void:
	if mode == Mode.IDLE:
		_to_hunt()
	if not announced:
		announced = true
		EventBus.big_message.emit("Centopeia-blindada")
		EventBus.hint.emit("Ela sente o chão vibrar e CAVA atrás de você. Sobre um fio você não vibra. Faça ela investir (ou sair da terra) ATRAVÉS de um fio esticado: enroscada, a carapaça abre.")
		GameState.say_once("centopeia_inicio", "Uma centopeia. Blindada. Do tamanho de um corredor. Claro que é.")


func combat_stop() -> void:
	if under:
		_set_under(false)
	mode = Mode.IDLE
	telegraph = false
	hide_marker()


func _to_hunt() -> void:
	mode = Mode.HUNT
	mode_time = 0.0
	_roll = randf()


func combat_tick(delta: float) -> Vector3:
	mode_time += delta
	_cd_burrow -= delta
	_cd_spit -= delta
	_cd_circle -= delta
	var p := GameState.player as Player
	var windup := 0.8 if phase == 1 else 0.55
	var mult := 1.0 if phase == 1 else 1.25
	var last_heard := last_player_pos
	var alive := p != null and not p.dead
	match mode:
		Mode.IDLE, Mode.HUNT:
			if mode == Mode.IDLE:
				_to_hunt()
			face_toward(last_heard)
			var d := Fx.flat_dist(global_position, last_heard)
			if alive and flat_dist_to(p) < 2.6:
				_begin(Mode.BITE)
				face_toward(p.global_position)   # mira uma vez e trava
				return Vector3.ZERO
			if mode_time > 0.7 and alive:
				var dp := flat_dist_to(p)
				var sight := has_line_of_sight(p)
				# furiosa: corre em volta de você e fecha o anel
				if phase == 2 and _cd_circle <= 0.0 and dp > 2.5 and dp < 8.0 and feels(p):
					var ring = _ring_center(p.global_position)
					if ring != null:
						_start_circle(ring)
						return Vector3.ZERO
				# meia distância e te vendo: cuspe de ácido (às vezes)
				if sight and dp > 3.0 and dp < 9.0 and _cd_spit <= 0.0 and _roll < 0.5:
					_begin(Mode.SPIT)
					face_toward(p.global_position)
					_cd_spit = 7.0 if phase == 1 else 5.0
					return Vector3.ZERO
				# longe, sem linha reta, ou quando dá vontade: some na terra e vem por baixo
				if _cd_burrow <= 0.0 and player_memory > 0.0 and (d > 12.0 or not sight or (d > 6.0 and _roll > 0.7)):
					_begin(Mode.BURROW)
					_cd_burrow = 11.0 if phase == 1 else 7.5
					Sfx.play("centopeia_cava" if Sfx.has("centopeia_cava") else "pedra_cai", global_position, 2.0)
					return Vector3.ZERO
				if sight and d > 3.5 and d < 12.0:
					_bounces = 0
					_bounce_wait = false
					_begin(Mode.WINDUP)
					face_toward(p.global_position)   # a investida vai para onde você estava agora
					return Vector3.ZERO
			return nav_to(last_heard, 1.0 * mult)
		Mode.WINDUP:
			var w := 0.35 if _bounce_wait else windup
			show_marker(_tele_charge, global_position, mode_time / w)
			if mode_time >= w:
				hide_marker()
				telegraph = false
				charge_dir = facing
				mode = Mode.CHARGE
				mode_time = 0.0
				attack_done = false
				_bounce_wait = false
				Sfx.play("centopeia_golpe", global_position, 0.0, 0.1)
			return Vector3.ZERO
		Mode.CHARGE:
			if mode_time > CHARGE_TIME:
				_end_charge(0.6)
				return Vector3.ZERO
			if alive and not attack_done and flat_dist_to(p) < body_radius + 0.9:
				attack_done = true
				p.take_damage(CHARGE_DAMAGE, self)
			return charge_dir * CHARGE_SPEED * mult
		Mode.RECOVER:
			if mode_time < 0.0:
				return Vector3.ZERO
			_to_hunt()
			return Vector3.ZERO
		Mode.BITE:
			if not attack_done:
				show_marker(_tele_bite, global_position, mode_time / 0.5)
			if not attack_done and mode_time >= 0.5:
				attack_done = true
				hide_marker()
				telegraph = false
				if alive and flat_dist_to(p) <= 3.0 and _in_front(p.global_position, 50.0):
					p.take_damage(BITE_DAMAGE, self)
			if mode_time >= 0.9:
				_end_charge(0.5)   # respira depois da mordida: janela para você sair (ou bater)
			return Vector3.ZERO
		Mode.BURROW:
			activity = "Cavando"
			_sink = clampf(mode_time / BURROW_TIME, 0.0, 1.0)
			if int(mode_time * 10.0) != int((mode_time - delta) * 10.0):
				Juice.dust(get_parent(), global_position, 1.6)
			if mode_time >= BURROW_TIME:
				_set_under(true)
				mode = Mode.UNDER
				mode_time = 0.0
				telegraph = false
				if not GameState.said.has("centopeia_cavou"):
					EventBus.message.emit("Ela sumiu na terra! A rachadura segue a sua vibração: pare num fio e ela sai onde você estava.")
					GameState.say_once("centopeia_cavou", "Ela... entrou no CHÃO?! Isso é permitido?!")
			return Vector3.ZERO
		Mode.UNDER:
			activity = "Embaixo da terra"
			var goal := last_heard
			if (mode_time > 0.8 and Fx.flat_dist(global_position, goal) < 1.3) or mode_time > UNDER_MAX:
				_begin(Mode.EMERGE)
				return Vector3.ZERO
			_drop_crack()
			if alive and flat_dist_to(p) < 14.0 and int(mode_time * 3.0) != int((mode_time - delta) * 3.0):
				p.shake(0.12)
			return nav_to(goal, UNDER_SPEED * mult)
		Mode.EMERGE:
			activity = "Saindo da terra"
			var ew := 0.75 if phase == 1 else 0.55
			if not attack_done:
				show_marker(_tele_erupt, global_position, mode_time / ew)
				if mode_time >= ew:
					attack_done = true
					hide_marker()
					telegraph = false
					_erupt(p)
				return Vector3.ZERO
			if mode_time >= ew + 0.3:
				_end_charge(1.1)
			return Vector3.ZERO
		Mode.SPIT:
			activity = "Cuspe ácido"
			if not attack_done:
				show_marker(_tele_spit, global_position, mode_time / 0.6)
				if mode_time >= 0.6:
					attack_done = true
					hide_marker()
					telegraph = false
					_spit(p)
			if mode_time >= 1.2:
				_to_hunt()
			return Vector3.ZERO
		Mode.CIRCLE:
			activity = "Cercando"
			var rel := global_position - _circle_c
			rel.y = 0.0
			var r := rel.length()
			var radial := rel / r if r > 0.05 else -facing
			var tangent := Vector3(-radial.z, 0.0, radial.x) * _circle_dir
			var v := tangent * CIRCLE_SPEED + radial * clampf((CIRCLE_R - r) * 3.0, -CIRCLE_SPEED, CIRCLE_SPEED)
			if absf(r - CIRCLE_R) < 1.5:
				_circle_turn += CIRCLE_SPEED * delta / CIRCLE_R
			face_toward(global_position + v)
			_touch_body(p, delta)
			if _circle_turn >= TAU * 0.85 or mode_time > 5.0:
				_begin(Mode.SQUEEZE)
				EventBus.message.emit("O anel vai fechar!")
			return v.limit_length(CIRCLE_SPEED * 1.2)
		Mode.SQUEEZE:
			activity = "Apertando"
			var sw := 0.7
			_touch_body(p, delta)
			if not attack_done:
				show_marker(_tele_squeeze, _circle_c, mode_time / sw)
				if mode_time >= sw:
					attack_done = true
					hide_marker()
					telegraph = false
					Sfx.play("centopeia_golpe", global_position, 3.0)
					if alive and Fx.flat_dist(p.global_position, _circle_c) <= CIRCLE_R - 0.4:
						if p.take_damage(SQUEEZE_DAMAGE, self):
							EventBus.message.emit("Esmagada no anel!")
			if mode_time >= sw + 0.3:
				_end_charge(1.3)
			var rel2 := global_position - _circle_c
			rel2.y = 0.0
			return Vector3(-rel2.z, 0.0, rel2.x).normalized() * _circle_dir * 3.0 if rel2.length() > 0.1 else Vector3.ZERO
	return Vector3.ZERO


# ---------------------------------------------------------------- golpes novos

func _set_under(on: bool) -> void:
	under = on
	collision_layer = 0 if on else 4
	_sink = 1.0 if on else 0.0
	_crack_from = global_position
	if not on:
		_place_segments()


func _drop_crack() -> void:
	## Rachadura no chão por onde ela passa embaixo: dá para ver de onde ela vem.
	if Fx.flat_dist(global_position, _crack_from) < 0.8 or get_parent() == null:
		return
	var dir := global_position - _crack_from
	dir.y = 0.0
	var n := Node3D.new()
	n.name = "Rachadura"
	n.add_to_group("rachadura")
	get_parent().add_child(n)
	n.global_position = Vector3(global_position.x, 0.02, global_position.z)
	n.rotation.y = atan2(-dir.x, -dir.z) + randf_range(-0.3, 0.3)
	var crack := Fx.box(Vector3(0.35, 0.03, 1.1), _crack_mat())
	n.add_child(crack)
	for k in 2:
		var rock := Fx.box(Vector3(0.18, 0.12, 0.2), Fx.mat(Color(0.32, 0.29, 0.27)))
		rock.position = Vector3(randf_range(-0.5, 0.5), 0.06, randf_range(-0.4, 0.4))
		rock.rotation = Vector3(randf(), randf(), randf())
		n.add_child(rock)
	n.get_tree().create_timer(4.0, false).timeout.connect(n.queue_free)
	_crack_from = global_position
	Sfx.play("pedra_cai", global_position, -10.0, 0.2, 0.35)


var _crack_m: StandardMaterial3D


func _crack_mat() -> StandardMaterial3D:
	if _crack_m == null:
		_crack_m = Fx.mat(Color(0.07, 0.06, 0.05))
	return _crack_m


func _erupt(p: Player) -> void:
	## Sai da terra de uma vez: quem está em cima voa; se sair dentro de um fio, se enrosca.
	_set_under(false)
	Sfx.play("centopeia_emerge" if Sfx.has("centopeia_emerge") else "pedra_cai", global_position, 4.0)
	Juice.dust(get_parent(), global_position, 2.4)
	Juice.sparks(get_parent(), global_position + Vector3.UP * 0.3, Color(0.5, 0.42, 0.32), 18, 7.0)
	for s in WebNetwork.strands.duplicate():
		if is_instance_valid(s) and s.distance_to(global_position) < ERUPT_R * 0.8:
			WebNetwork.remove_strand(s)
			entangle_raw(TANGLE_TIME)
			EventBus.web_touched.emit(global_position, self)
			EventBus.big_message.emit("Saiu dentro da teia! A carapaça abriu!")
			GameState.say_once("centopeia_emerge_fio", "Ela saiu bem no meu fio! Enroscou! VAI!")
			return
	if p != null and not p.dead:
		var d := flat_dist_to(p)
		if d < 12.0:
			p.shake(0.35)
		if d <= ERUPT_R + 0.3 and p.take_damage(ERUPT_DAMAGE, self):
			var out := p.global_position - global_position
			out.y = 0.0
			p.external_velocity = (out.normalized() if out.length() > 0.05 else -facing) * 9.0


func _spit(p: Player) -> void:
	## Cuspe de ácido em leque: machuca quem está no cone e deixa poças por alguns segundos.
	Sfx.play("centopeia_cuspe" if Sfx.has("centopeia_cuspe") else "kit_cuspe", global_position, 2.0)
	var spots: Array[Vector3] = []
	for dist: float in [2.2, 4.0, 5.8]:
		spots.append(global_position + facing * dist)
	if phase == 2:
		for side: float in [-1.0, 1.0]:
			spots.append(global_position + facing.rotated(Vector3.UP, side * 0.45) * 4.6)
	for at in spots:
		if World.nav == null or World.nav.walkable(at):
			AcidPuddle.spawn(get_parent(), at, 1.2, 6.0)
			Juice.sparks(get_parent(), Vector3(at.x, 0.3, at.z), Color(0.55, 0.95, 0.25), 6, 3.0)
	if p != null and not p.dead and _tele_spit.hits(global_position, facing, global_position, p.global_position, 0.3):
		if p.take_damage(SPIT_DAMAGE, self, false):
			p.apply_acid(6.0)


func _ring_clear(c: Vector3) -> bool:
	## Só cerca onde dá para correr em volta (sem parede no caminho do anel).
	## Um ou dois pontos apertados (perto de um pilar) tudo bem: ela se espreme e passa.
	if World.nav == null:
		return false
	var tight := 0
	for i in 12:
		var q := c + Vector3(cos(i * TAU / 12.0), 0.0, sin(i * TAU / 12.0)) * CIRCLE_R
		if not World.nav.walkable(q, NavGrid.Kind.SMALL):
			return false
		if not World.nav.walkable(q, NavGrid.Kind.LARGE):
			tight += 1
	return tight <= 2


func _ring_center(at: Vector3) -> Variant:
	## Centro do anel: onde você está, ou um pouco para o lado aberto (você fica dentro).
	if _ring_clear(at):
		return at
	for k in 8:
		var q := at + Vector3(cos(k * TAU / 8.0), 0.0, sin(k * TAU / 8.0)) * 1.8
		if _ring_clear(q):
			return q
	return null


func _start_circle(c: Vector3) -> void:
	_circle_c = Vector3(c.x, 0.0, c.z)
	_circle_turn = 0.0
	_cd_circle = 13.0
	var rel := global_position - _circle_c
	rel.y = 0.0
	var tangent := Vector3(-rel.z, 0.0, rel.x)
	_circle_dir = 1.0 if tangent.dot(facing) >= 0.0 else -1.0
	_begin(Mode.CIRCLE)
	telegraph = true
	EventBus.message.emit("Ela está te cercando! Saia do anel (ou esquive ATRAVÉS do corpo) antes que feche!")
	GameState.say_once("centopeia_cerco", "Ela tá dando VOLTA em mim. Isso não é bom. Isso não é nada bom.")


func _touch_body(p: Player, delta: float) -> void:
	## Durante o cerco o corpo é uma cerca: encostar machuca e joga você de volta para dentro.
	_touch_cd -= delta
	if p == null or p.dead or p.invuln > 0.0 or _touch_cd > 0.0:
		return
	for sp in _seg_pos:
		if Fx.flat_dist(sp, p.global_position) < 1.0:
			_touch_cd = 0.6
			if p.take_damage(COIL_TOUCH, self, false):
				var inward := _circle_c - p.global_position
				inward.y = 0.0
				if inward.length() > 0.05:
					p.external_velocity = inward.normalized() * 7.0
			return


func _in_front(pos: Vector3, half_angle_deg: float) -> bool:
	## A mordida acerta só quem está na frente da cabeça (a mira travou no começo).
	var to := pos - global_position
	to.y = 0.0
	if to.length() < body_radius * 0.6:
		return true
	return facing.angle_to(to.normalized()) <= deg_to_rad(half_angle_deg)


func _begin(m: Mode) -> void:
	mode = m
	mode_time = 0.0
	attack_done = false
	telegraph = true


func _end_charge(pause: float) -> void:
	hide_marker()
	telegraph = false
	mode = Mode.RECOVER
	mode_time = -pause   # RECOVER termina quando mode_time passa de 0


var _safe_pos := Vector3.ZERO


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if absf(global_position.y) < 0.3 and World.nav != null and World.nav.walkable(global_position, NavGrid.Kind.LARGE):
		_safe_pos = Vector3(global_position.x, 0.05, global_position.z)
	if dead:
		return
	if under:
		_track_from = global_position
	elif Fx.flat_dist(global_position, _track_from) > 1.6 and not is_entangled():
		var dir := global_position - _track_from
		Track.drop(get_parent(), _track_from, dir, 1.3)
		_track_from = global_position
	if mode == Mode.CHARGE and not is_entangled():
		_check_strands()
		var real := get_real_velocity()
		if mode_time > 0.25 and Vector2(real.x, real.z).length() < 3.0:
			_wall_hit()
	elif (mode == Mode.CIRCLE or mode == Mode.SQUEEZE) and not is_entangled():
		_check_strands()
		var rv := get_real_velocity()
		_stuck_t = _stuck_t + delta if Vector2(rv.x, rv.z).length() < 2.0 else 0.0
		if _stuck_t > 0.4 and mode == Mode.CIRCLE:
			_stuck_t = 0.0
			_end_charge(1.0)
	if mode == Mode.BURROW or under or _sink > 0.0:
		if not under and mode != Mode.BURROW:
			_sink = maxf(0.0, _sink - delta * 5.0)
	_update_trail()


func _wall_hit() -> void:
	## Furiosa, ela quica na parede e mira de novo em você (até 2x); senão fica tonta.
	var p := GameState.player as Player
	Juice.dust(get_parent(), global_position + facing * 1.2, 1.5)
	if p != null and not p.dead and flat_dist_to(p) < 14.0:
		p.shake(0.25)
	if phase == 2 and _bounces < 2 and p != null and not p.dead:
		_bounces += 1
		_bounce_wait = true
		_begin(Mode.WINDUP)
		face_toward(p.global_position)
		if not GameState.said.has("centopeia_quica"):
			EventBus.message.emit("Ela quicou na parede e vem de novo!")
			GameState.say_once("centopeia_quica", "Ela nem PAROU! Bateu e voltou!")
		return
	_end_charge(1.2 if _bounces == 0 else 1.8)
	EventBus.message.emit("A Centopeia bateu de cabeça na parede!")


func _check_strands() -> void:
	for s in WebNetwork.strands.duplicate():
		if is_instance_valid(s) and s.distance_to(global_position) < 1.1:
			WebNetwork.remove_strand(s)
			entangle_raw(TANGLE_TIME)
			_end_charge(0.4)   # enredada ela já fica parada; o _think nem roda até soltar
			EventBus.web_touched.emit(global_position, self)
			EventBus.big_message.emit("Enredada! A carapaça abriu!")
			GameState.say_once("centopeia_enredada", "Isso! Ela se enroscou! AGORA!")
			return


# ---------------------------------------------------------------- dano

func take_damage(amount: float, source: Node3D = null) -> void:
	if dead or under:
		return   # embaixo da terra nada acerta
	if not is_entangled():
		amount *= ARMOR
		if _armor_msg_cd <= 0.0 and source != null and source.is_in_group("player"):
			_armor_msg_cd = 6.0
			EventBus.message.emit("A carapaça segura o golpe. Faça a Centopeia investir através de um fio esticado!")
	super.take_damage(amount, source)
	if not dead and phase == 1 and hp <= max_hp * 0.5:
		phase = 2
		EventBus.big_message.emit("A Centopeia se enfurece!")
		GameState.say_once("centopeia_furia", "Ah, ótimo. Agora ela está BRAVA.")


func add_poison(n := 1, cap := MAX_POISON) -> void:
	if is_entangled():
		super.add_poison(n, cap)


func _on_hurt(source: Node3D) -> void:
	if source != null and source.is_in_group("player") and mode == Mode.IDLE:
		_to_hunt()


# ---------------------------------------------------------------- corpo

func _update_trail() -> void:
	var head := global_position
	if _trail.is_empty() or head.distance_to(_trail[0]) > 0.15:
		_trail.insert(0, head)
		var cap := int(SEGMENTS * SPACING / 0.15) + 12
		while _trail.size() > cap:
			_trail.pop_back()
	_place_segments()


func _place_segments() -> void:
	## Corrente "segue o líder": a nuca é presa à cabeça; cada placa fica à distância certa
	## da placa da frente, puxada na direção de onde ela estava. Nada solta, nada atravessa,
	## e nas curvas o corpo corta a curva de leve, como uma centopeia de verdade.
	var wave := 0.0 if is_entangled() else _anim_t * 6.0
	var sink := _sink * SINK_DEPTH
	_visual.position.y = -sink
	_visual.visible = _sink < 0.97
	if _seg_pos.size() != _segs.size():
		_seg_pos.clear()
		for i in _segs.size():
			_seg_pos.append(global_position - facing * (HEAD_BACK + 0.8 * (i + 1)))
	# a cabeça olha para onde vai, mas no máximo ~20° fora da linha do corpo (gira pela nuca)
	var body_dir := global_position - _seg_pos[0]
	body_dir.y = 0.0
	body_dir = body_dir.normalized() if body_dir.length() > 0.05 else facing
	var yaw_body := atan2(-body_dir.x, -body_dir.z)
	var yaw_face := atan2(-facing.x, -facing.z)
	var yaw := yaw_body + clampf(wrapf(yaw_face - yaw_body, -PI, PI), -0.35, 0.35)
	_visual.rotation.y = yaw
	var fwd := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var prev := global_position - fwd * HEAD_BACK * 0.7   # a nuca
	prev.y = maxf(global_position.y, 0.0)
	var prev_half := 0.0
	for i in _segs.size():
		var half := _seg_depth[i] * 0.5 if i < _seg_depth.size() else 0.45
		var gap := (prev_half + half) * OVERLAP
		var d := _seg_pos[i] - prev
		d.y = 0.0
		if d.length() < 0.01:
			d = -fwd
		var pos := prev + d.normalized() * gap
		pos.y = 0.0
		_seg_pos[i] = pos
		var seg := _segs[i]
		seg.global_position = pos + Vector3.UP * (sin(wave - i * 0.8) * 0.05 - sink * clampf(1.0 - float(i) * 0.04, 0.5, 1.0))
		seg.visible = _sink < 0.97
		var dir := prev - pos
		dir.y = 0.0
		if dir.length() > 0.01:
			seg.rotation = Vector3(0.0, atan2(-dir.x, -dir.z), 0.0)
		if i < _joints.size():
			_place_joint(_joints[i], prev, pos, 0.28 * (1.0 - float(i) / SEGMENTS * 0.45) - sink)
			_joints[i].visible = _joints[i].visible and _sink < 0.97
		prev = pos
		prev_half = half


func _trail_dir_near_head(dist: float) -> Vector3:
	## Direção do corpo logo atrás da cabeça (do ponto do rastro a `dist` m até a cabeça).
	var acc := 0.0
	for j in _trail.size() - 1:
		acc += _trail[j].distance_to(_trail[j + 1])
		if acc >= dist:
			var d := global_position - _trail[j + 1]
			d.y = 0.0
			if d.length() > 0.05:
				return d.normalized()
			break
	return facing


func _place_joint(joint: MeshInstance3D, a: Vector3, b: Vector3, h: float) -> void:
	var d := a - b
	var ln := d.length()
	if ln < 0.01:
		joint.visible = false
		return
	joint.visible = true
	var y := d / ln
	var x := y.cross(Vector3.UP)
	if x.length() < 0.01:
		x = Vector3.RIGHT
	x = x.normalized()
	var z := x.cross(y).normalized()
	joint.global_transform = Transform3D(Basis(x, y * ln, z), (a + b) * 0.5 + Vector3.UP * h)


func die(fell: bool = false) -> void:
	if fell and not dead and hp > 0.0:
		# chefe não morre de queda (espremida num pilar, empurrada para fora da grade):
		# volta para o último chão bom e segue a luta
		global_position = _safe_pos
		velocity = Vector3.ZERO
		external_velocity = Vector3.ZERO
		return
	for s in _segs:
		if is_instance_valid(s):
			s.queue_free()
	for jn in _joints:
		if is_instance_valid(jn):
			jn.queue_free()
	super.die(fell)


func _animate(_delta: float, _speed_now: float) -> void:
	pass


func can_raid() -> bool:
	return false
