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
## ou parada não vibra. Ataques: mordida de perto e investida em linha reta.
## A carapaça segura 90% do dano e o veneno não entra. Ela só cede quando a Centopeia
## está ENREDADA, e isso só acontece quando ela investe ATRAVÉS de um fio esticado
## (o fio arrebenta). Na metade da vida ela se enfurece: investe mais rápido e com aviso menor.

enum Mode { IDLE, HUNT, WINDUP, CHARGE, RECOVER, BITE }

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
	add_to_group("boss")
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

func combat_wants() -> bool:
	return player_memory > 0.0 or mode == Mode.WINDUP or mode == Mode.CHARGE or mode == Mode.BITE or (mode == Mode.RECOVER and mode_time < 0.0)


func combat_locked() -> bool:
	return mode == Mode.WINDUP or mode == Mode.CHARGE or mode == Mode.BITE


func combat_start() -> void:
	if mode == Mode.IDLE:
		mode = Mode.HUNT
		mode_time = 0.0
	if not announced:
		announced = true
		EventBus.big_message.emit("Centopeia-blindada")
		EventBus.hint.emit("Ela sente o chão vibrar. Sobre um fio você não vibra. Faça ela investir ATRAVÉS de um fio esticado: enroscada, a carapaça abre.")
		GameState.say_once("centopeia_inicio", "Uma centopeia. Blindada. Do tamanho de um corredor. Claro que é.")


func combat_stop() -> void:
	mode = Mode.IDLE
	telegraph = false


func combat_tick(delta: float) -> Vector3:
	mode_time += delta
	var p := GameState.player as Player
	var windup := 0.8 if phase == 1 else 0.55
	var mult := 1.0 if phase == 1 else 1.25
	var last_heard := last_player_pos
	match mode:
		Mode.IDLE, Mode.HUNT:
			mode = Mode.HUNT
			face_toward(last_heard)
			var d := Fx.flat_dist(global_position, last_heard)
			if p != null and not p.dead and flat_dist_to(p) < 2.6:
				_begin(Mode.BITE)
				return Vector3.ZERO
			if d > 3.5 and d < 12.0 and mode_time > 0.7 and p != null and has_line_of_sight(p):
				_begin(Mode.WINDUP)
				return Vector3.ZERO
			return nav_to(last_heard, 1.0 * mult)
		Mode.WINDUP:
			if player_memory > 0.0:
				face_toward(last_heard)
			show_marker(_tele_charge, global_position, mode_time / windup)
			if mode_time >= windup:
				hide_marker()
				telegraph = false
				charge_dir = facing
				mode = Mode.CHARGE
				mode_time = 0.0
				attack_done = false
			return Vector3.ZERO
		Mode.CHARGE:
			if mode_time > CHARGE_TIME:
				_end_charge(0.6)
				return Vector3.ZERO
			if p != null and not p.dead and not attack_done and flat_dist_to(p) < body_radius + 0.9:
				attack_done = true
				p.take_damage(CHARGE_DAMAGE, self)
			return charge_dir * CHARGE_SPEED * mult
		Mode.RECOVER:
			if mode_time < 0.0:
				return Vector3.ZERO
			mode = Mode.HUNT
			mode_time = 0.0
			return Vector3.ZERO
		Mode.BITE:
			if p != null:
				face_toward(p.global_position)
			if not attack_done:
				show_marker(_tele_bite, global_position, mode_time / 0.5)
			if not attack_done and mode_time >= 0.5:
				attack_done = true
				hide_marker()
				telegraph = false
				if p != null and not p.dead and flat_dist_to(p) <= 3.0:
					p.take_damage(BITE_DAMAGE, self)
			if mode_time >= 0.9:
				mode = Mode.HUNT
				mode_time = 0.0
			return Vector3.ZERO
	return Vector3.ZERO


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


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if dead:
		return
	if Fx.flat_dist(global_position, _track_from) > 1.6 and not is_entangled():
		var dir := global_position - _track_from
		Track.drop(get_parent(), _track_from, dir, 1.3)
		_track_from = global_position
	if mode == Mode.CHARGE and not is_entangled():
		_check_strands()
		var real := get_real_velocity()
		if mode_time > 0.25 and Vector2(real.x, real.z).length() < 3.0:
			_end_charge(1.2)
			EventBus.message.emit("A Centopeia bateu de cabeça na parede!")
	_update_trail()


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
	if dead:
		return
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


func add_poison() -> void:
	if is_entangled():
		super.add_poison()


func _on_hurt(source: Node3D) -> void:
	if source != null and source.is_in_group("player") and mode == Mode.IDLE:
		mode = Mode.HUNT
		mode_time = 0.0


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
		seg.global_position = pos + Vector3.UP * sin(wave - i * 0.8) * 0.05
		var dir := prev - pos
		dir.y = 0.0
		if dir.length() > 0.01:
			seg.rotation = Vector3(0.0, atan2(-dir.x, -dir.z), 0.0)
		if i < _joints.size():
			_place_joint(_joints[i], prev, pos, 0.28 * (1.0 - float(i) / SEGMENTS * 0.45))
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
	for s in _segs:
		if is_instance_valid(s):
			s.queue_free()
	for jn in _joints:
		if is_instance_valid(jn):
			jn.queue_free()
	super.die(fell)


func _animate(_delta: float, _speed_now: float) -> void:
	pass
