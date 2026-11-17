class_name Colossus
extends Node3D
## Colosso da Fenda (A3, Trilha do Colosso): um dragão da terra do tamanho do corredor.
## Não dá para vencer, só evitar. Vai e volta numa rota fixa pelo meio da trilha.
## Sente o chão: correr perto dele, ou andar num fio por perto, chama atenção; enxerga só
## de perto (e só com a runa acesa ajuda). Parada no escuro, ele passa.
## Alerta: ruge, os olhos ficam vermelhos e ele avança pela trilha até onde você está.
## Se te alcança, uma pisada e acabou. Nas rachaduras das paredes ele não entra: fareja,
## desiste e volta para a ronda. Pisa e arrebenta qualquer fio no caminho.

signal alerted
signal killed_player

enum Mode { PATROL, TURN, CHARGE, SNIFF }

const WALK := 3.0
const RUN := 6.8
const HEAR := 1.7            ## multiplica o raio de barulho da jogadora
const STRAND_FEEL := 13.0    ## fio por perto: a vibração chega nele
const SEE := 6.0
const KILL_R := 3.4          ## alcance da pisada/mordida (da cabeça)
const REACH := 5.0           ## até quanto fora do meio da trilha ele alcança

var route: PackedVector2Array = PackedVector2Array()   ## meio da trilha (x, z)
var mode := Mode.PATROL
var s := 0.0                 ## posição ao longo da rota (metros)
var dir := 1.0
var _len := 0.0
var _seg: PackedFloat32Array = PackedFloat32Array()
var _t := 0.0
var _sense_t := 0.0
var _step_t := 0.0
var _goal_s := 0.0
var _visual: Node3D
var _legs: Array = []
var _neck: Array = []
var _tail: Array = []
var _head: Node3D
var _eyes: Array = []
var _eye_mat: StandardMaterial3D


func setup(route_: PackedVector2Array) -> Colossus:
	route = route_
	return self


func _ready() -> void:
	add_to_group("colossus")
	_seg.resize(route.size())
	_len = 0.0
	for i in route.size():
		if i > 0:
			_len += route[i].distance_to(route[i - 1])
		_seg[i] = _len
	s = _len * 0.5
	_build_visual()
	_place(0.0)


# ---------------------------------------------------------------- rota

func point_at(d: float) -> Vector3:
	d = clampf(d, 0.0, _len)
	for i in range(1, route.size()):
		if d <= _seg[i]:
			var t := (d - _seg[i - 1]) / maxf(0.001, _seg[i] - _seg[i - 1])
			var q := route[i - 1].lerp(route[i], t)
			return Vector3(q.x, 0.0, q.y)
	return Vector3(route[route.size() - 1].x, 0.0, route[route.size() - 1].y)


func project(p: Vector3) -> Vector2:
	## (posição na rota, distância até o meio da trilha) do ponto p.
	var q := Vector2(p.x, p.z)
	var best_s := 0.0
	var best_d := INF
	for i in range(1, route.size()):
		var a := route[i - 1]
		var b := route[i]
		var ab := b - a
		var t := clampf((q - a).dot(ab) / maxf(0.0001, ab.length_squared()), 0.0, 1.0)
		var d := q.distance_to(a + ab * t)
		if d < best_d:
			best_d = d
			best_s = _seg[i - 1] + ab.length() * t
	return Vector2(best_s, best_d)


func head_pos() -> Vector3:
	return global_position + _forward() * 5.0


func _forward() -> Vector3:
	return Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))


func _place(delta: float) -> void:
	var p := point_at(s)
	var ahead := point_at(s + dir * 1.5)
	global_position = p
	var f := ahead - p
	if f.length() > 0.01:
		var want := atan2(-f.x, -f.z)
		rotation.y = lerp_angle(rotation.y, want, clampf(delta * 3.0, 0.0, 1.0) if delta > 0.0 else 1.0)


# ---------------------------------------------------------------- cérebro

func _physics_process(delta: float) -> void:
	_t += delta
	var p := GameState.player as Player
	match mode:
		Mode.PATROL:
			s += dir * WALK * delta
			if s >= _len - 1.0 or s <= 1.0:
				mode = Mode.TURN
				_t = 0.0
		Mode.TURN:
			if _t > 2.2:   # para na ponta, cheira o ar e dá meia-volta
				dir = -dir
				mode = Mode.PATROL
		Mode.CHARGE:
			if p == null or p.dead:
				_calm()
			else:
				var pr := project(p.global_position)
				_goal_s = pr.x
				dir = signf(_goal_s - s) if absf(_goal_s - s) > 0.5 else dir
				s = move_toward(s, _goal_s, RUN * delta)
				if pr.y > REACH + 0.5 and absf(_goal_s - s) < 3.0:
					mode = Mode.SNIFF   # ela está numa rachadura: ele não entra
					_t = 0.0
					EventBus.message.emit("O Colosso fareja a rachadura... e não cabe.")
				elif _t > 9.0:
					_calm()
		Mode.SNIFF:
			if p != null and not p.dead and project(p.global_position).y <= REACH and _t > 0.6:
				mode = Mode.CHARGE   # saiu da rachadura cedo demais
				_t = 0.0
			elif _t > 3.5:
				_calm()
	_place(delta)
	_sense_t -= delta
	if _sense_t <= 0.0:
		_sense_t = 0.2
		_sense(p)
	_footsteps(delta, p)
	_crush_strands()
	if p != null and not p.dead and p.invuln <= 0.0 and _catches(p):
		_kill(p)
	_animate(delta)


func _catches(p: Player) -> bool:
	## Avançando: pega tudo no corredor na frente dele. De ronda: só se ela estiver bem no
	## caminho das patas (de lado, parada no escuro, ele passa).
	var pr := project(p.global_position)
	var along := (pr.x - s) * dir     # + na frente, - atrás
	if mode == Mode.CHARGE:
		return pr.y <= REACH and along > -4.5 and along < KILL_R + 4.0
	if mode == Mode.SNIFF:
		return false
	return pr.y < 2.3 and along > -4.5 and along < 5.5


func _sense(p: Player) -> void:
	if p == null or p.dead or mode == Mode.CHARGE:
		return
	var d := Fx.flat_dist(p.global_position, head_pos())
	var heard := d < p.noise_radius() * HEAR
	var on_web := p.on_strand and d < STRAND_FEEL
	var seen := false
	if d < SEE * p.visibility_mult():
		var to := (p.global_position - global_position).normalized()
		seen = _forward().dot(to) > 0.2
	if heard or on_web or seen:
		_alert()


func _alert() -> void:
	if mode == Mode.CHARGE:
		return
	mode = Mode.CHARGE
	_t = 0.0
	_eye_mat.albedo_color = Color(1.0, 0.25, 0.15)
	_eye_mat.emission = Color(1.0, 0.25, 0.15)
	alerted.emit()
	EventBus.big_message.emit("O Colosso te sentiu!")
	var pl := GameState.player as Player
	if pl != null:
		pl.shake(1.0)
	GameState.say_once("colosso_alerta", "ELE ME SENTIU. Rachadura, rachadura, RACHADURA!")


func _calm() -> void:
	mode = Mode.PATROL
	_t = 0.0
	_eye_mat.albedo_color = Color(1.0, 0.75, 0.3)
	_eye_mat.emission = Color(1.0, 0.75, 0.3)


func _kill(p: Player) -> void:
	killed_player.emit()
	EventBus.big_message.emit("O Colosso te esmagou.")
	p.shake(2.0)
	p.take_damage(99999.0, null, false)
	_calm()


func _footsteps(delta: float, p: Player) -> void:
	## Cada passo treme o chão: quanto mais perto, mais a câmera chacoalha.
	var pace := 0.5 if mode == Mode.CHARGE else 0.85
	_step_t -= delta
	if _step_t > 0.0 or mode == Mode.TURN or mode == Mode.SNIFF:
		return
	_step_t = pace
	if p != null:
		var d := Fx.flat_dist(p.global_position, global_position)
		var k := clampf(1.0 - d / 32.0, 0.0, 1.0)
		if k > 0.0:
			p.shake(0.12 + 0.5 * k * k)


func _crush_strands() -> void:
	for st in WebNetwork.strands.duplicate():
		if is_instance_valid(st) and (st.distance_to(global_position) < 3.0 or st.distance_to(head_pos()) < 2.0):
			WebNetwork.remove_strand(st)
			EventBus.web_touched.emit(global_position, null)


# ---------------------------------------------------------------- corpo (provisório: dragão da terra)

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var skin := Fx.mat(Color(0.3, 0.28, 0.33))
	var belly := Fx.mat(Color(0.3, 0.27, 0.25))
	var vein := Fx.mat(Color(0.45, 0.85, 1.0), 3.0, true)
	var horn := Fx.mat(Color(0.75, 0.7, 0.6))
	var body := Fx.sphere(1.0, skin)
	body.scale = Vector3(2.0, 1.55, 4.2)
	body.position = Vector3(0, 2.6, 0.4)
	_visual.add_child(body)
	var under := Fx.sphere(1.0, belly)
	under.scale = Vector3(1.7, 1.0, 3.6)
	under.position = Vector3(0, 2.0, 0.4)
	_visual.add_child(under)
	for k in 7:   # espinhos nas costas, com veios de cristal
		var z := -2.4 + k * 0.95
		var sp := Fx.cylinder(0.32 - k * 0.02, 1.1 - absf(k - 3) * 0.12, skin)
		(sp.mesh as CylinderMesh).top_radius = 0.02
		sp.position = Vector3(0, 4.2 - absf(k - 3) * 0.15, z)
		sp.rotation.x = -0.35
		_visual.add_child(sp)
		var v := Fx.box(Vector3(0.08, 0.7, 0.08), vein)
		v.position = sp.position + Vector3(0, -0.2, 0.05)
		v.rotation.x = -0.35
		_visual.add_child(v)
	for side: float in [-1.0, 1.0]:   # veio comprido no flanco
		var fl := Fx.box(Vector3(0.06, 0.06, 5.5), vein)
		fl.position = Vector3(side * 1.9, 2.9, 0.3)
		_visual.add_child(fl)
	for i in 4:   # patas grossas
		var lside := -1.0 if i % 2 == 0 else 1.0
		var front := i < 2
		var leg := Node3D.new()
		leg.position = Vector3(lside * 1.75, 2.2, -2.2 if front else 2.6)
		_visual.add_child(leg)
		var up := Fx.cylinder(0.55, 1.6, skin)
		up.position.y = -0.6
		leg.add_child(up)
		var low := Fx.cylinder(0.42, 1.4, skin)
		low.position.y = -1.6
		leg.add_child(low)
		for c in 3:
			var claw := Fx.cylinder(0.09, 0.45, horn)
			(claw.mesh as CylinderMesh).top_radius = 0.01
			claw.position = Vector3((c - 1) * 0.28, -2.2, -0.35)
			claw.rotation.x = -1.2
			leg.add_child(claw)
		leg.set_meta("phase", [0.0, PI, PI, 0.0][i])
		_legs.append(leg)
	var prev := Vector3(0, 3.2, -3.6)
	for k in 5:   # pescoço
		var seg := Fx.sphere(0.9 - k * 0.08, skin)
		seg.position = prev + Vector3(0, 0.25, -0.75)
		prev = seg.position
		_visual.add_child(seg)
		_neck.append(seg)
	_head = Node3D.new()
	_head.position = prev + Vector3(0, 0.1, -1.1)
	_visual.add_child(_head)
	var skull := Fx.sphere(0.85, skin)
	skull.scale = Vector3(1.0, 0.8, 1.6)
	_head.add_child(skull)
	var jaw := Fx.sphere(0.65, belly)
	jaw.scale = Vector3(0.9, 0.45, 1.5)
	jaw.position = Vector3(0, -0.45, -0.25)
	_head.add_child(jaw)
	for side: float in [-1.0, 1.0]:
		var hn := Fx.cylinder(0.16, 1.4, horn)
		(hn.mesh as CylinderMesh).top_radius = 0.02
		hn.position = Vector3(side * 0.45, 0.6, 0.6)
		hn.rotation = Vector3(1.0, 0.0, side * 0.35)
		_head.add_child(hn)
	_eye_mat = Fx.mat(Color(1.0, 0.75, 0.3), 3.0)
	for side: float in [-1.0, 1.0]:
		var eye := Fx.sphere(0.13, _eye_mat)
		eye.position = Vector3(side * 0.5, 0.2, -0.85)
		_head.add_child(eye)
		_eyes.append(eye)
	var glow := OmniLight3D.new()   # os olhos: a única coisa que se vê de longe no escuro
	glow.light_color = Color(1.0, 0.6, 0.3)
	glow.omni_range = 5.0
	glow.light_energy = 0.8
	glow.position = Vector3(0, 0.3, -1.4)
	_head.add_child(glow)
	# luz fria dos veios de cristal: no breu, ele é uma silhueta enorme com brilho nas costas
	var back := OmniLight3D.new()
	back.light_color = Color(0.45, 0.8, 1.0)
	back.omni_range = 9.0
	back.light_energy = 1.1
	back.position = Vector3(0, 6.0, 0.5)
	_visual.add_child(back)
	var tp := Vector3(0, 2.6, 4.4)
	for k in 9:   # cauda
		var seg := Fx.sphere(0.8 - k * 0.075, skin)
		seg.position = tp + Vector3(0, -0.12, 0.85)
		tp = seg.position
		_visual.add_child(seg)
		_tail.append(seg)


func _animate(_delta: float) -> void:
	var moving := mode == Mode.PATROL or mode == Mode.CHARGE
	var spd := (RUN if mode == Mode.CHARGE else WALK) if moving else 0.0
	var ph := _t * spd * 1.1
	for leg: Node3D in _legs:
		var a: float = ph + float(leg.get_meta("phase"))
		leg.rotation.x = sin(a) * 0.35 * (1.0 if moving else 0.0)
	for k in _tail.size():
		var seg: Node3D = _tail[k]
		seg.position.x = sin(_t * 1.6 - k * 0.5) * 0.12 * k
	var sniff := mode == Mode.SNIFF or mode == Mode.TURN
	_head.position.y = 5.0 + (sin(_t * 7.0) * 0.15 - 0.9 if sniff else sin(_t * 1.3) * 0.12)
	_visual.position.y = absf(sin(ph)) * 0.12 if moving else 0.0
