class_name SpiderLegs
extends Node3D
## Oito patas procedurais com IK de dois segmentos (fêmur + tíbia).
##
## Andar de aranha de verdade: dois grupos alternados de quatro patas (tetrápode alternado).
## Um relógio de passada avança com a distância andada; metade do ciclo um grupo está no ar,
## na outra metade, o outro. A pata no ar mira onde o corpo VAI estar quando ela pousar
## (passo previsto), então nunca fica esticada para trás. Parada, as patas se ajeitam de
## volta à pose de descanso. O pé pisa na altura do corpo (chão ou fio): sem raio de física,
## então nenhuma pata "acha" o chão em cima de uma parede.
## Os joelhos dobram para cima e para fora, como nas aranhas.

const SPREAD := [0.85, 0.32, -0.2, -0.7]   ## abertura de cada par, da frente para trás (rad)
const REST_RADIUS := 0.78                   ## distância do pé ao quadril, parada (× size)
const STRIDE := 0.9                         ## comprimento de um ciclo de passada (× size)
const LIFT := 0.22                          ## altura do pé no ar (× size)
const MIN_SWING := 0.05                     ## segundos: a pata nunca se mexe mais rápido que isso

var body: Node3D = null          ## nó que dá posição e rotação do corpo (o visual da criatura)
var root: Node3D = null          ## o corpo físico (a altura dele é a altura do chão)
var size := 1.0                  ## escala geral (1.0 = Cavaleira)
var ground_mask := 1             ## (mantido por compatibilidade; os pés não usam mais raio)
var leg_color := Color(0.12, 0.11, 0.26)
var joint_color := Color(0.78, 0.6, 0.25)
var curled := false              ## morte: patas encolhidas para cima
var velocity_hint := Vector3.ZERO
var phase := 0.0                 ## relógio da passada (0..1); dá para o corpo balançar junto

var _hips: Array[Vector3] = []
var _rests: Array[Vector3] = []
var _feet: Array[Vector3] = []
var _from: Array[Vector3] = []
var _swinging: Array[bool] = []
var _femurs: Array[MeshInstance3D] = []
var _tibias: Array[MeshInstance3D] = []
var _knees: Array[MeshInstance3D] = []
var _tips: Array[MeshInstance3D] = []
var _femur_len := 0.5
var _tibia_len := 0.72
var _ready_feet := false
var _settle_t := 0.0


func setup(body_node: Node3D, scale_: float, mask: int) -> void:
	body = body_node
	size = scale_
	ground_mask = mask


func _ready() -> void:
	top_level = true
	transform = Transform3D.IDENTITY
	if root == null and body != null:
		root = body.get_parent() as Node3D
	_femur_len = 0.5 * size
	_tibia_len = 0.72 * size
	var leg_mat := Fx.mat(leg_color)
	var joint_mat := Fx.mat(joint_color, 0.3)
	for i in 8:
		var side := -1.0 if i < 4 else 1.0
		var idx := i % 4
		var hip := Vector3(0.18 * side, 0.42, -0.26 + idx * 0.15) * size
		var dir := Vector3(side, 0.0, 0.0).rotated(Vector3.UP, side * float(SPREAD[idx]))
		var rest := Vector3(hip.x, 0.0, hip.z) + dir * REST_RADIUS * size
		_hips.append(hip)
		_rests.append(rest)
		_feet.append(Vector3.ZERO)
		_from.append(Vector3.ZERO)
		_swinging.append(false)
		var femur := Fx.box(Vector3(0.075 * size, 0.075 * size, _femur_len), leg_mat)
		var tibia := Fx.box(Vector3(0.05 * size, 0.05 * size, _tibia_len), leg_mat)
		var knee := Fx.sphere(0.055 * size, joint_mat)
		var tip := Fx.sphere(0.035 * size, joint_mat)
		add_child(femur)
		add_child(tibia)
		add_child(knee)
		add_child(tip)
		_femurs.append(femur)
		_tibias.append(tibia)
		_knees.append(knee)
		_tips.append(tip)


func _ground_y() -> float:
	return root.global_position.y if root != null and is_instance_valid(root) else body.global_position.y


func _rest_world(t: Transform3D, i: int) -> Vector3:
	var p := t * _rests[i]
	p.y = _ground_y()
	return p


func _process(delta: float) -> void:
	if body == null or not is_instance_valid(body):
		return
	var t := _body_xform()
	if not _ready_feet:
		for i in 8:
			_feet[i] = _rest_world(t, i)
		_ready_feet = true

	var vel := Vector3(velocity_hint.x, 0.0, velocity_hint.z)
	var speed := vel.length()
	# correndo, a passada alonga (até 40%), como aranha de verdade
	var stride := STRIDE * size * clampf(1.0 + (speed / maxf(size, 0.1) - 3.0) / 6.0, 1.0, 1.4)
	# ciclo: cada grupo fica metade no ar; a pata no ar nunca leva menos de MIN_SWING
	var cycle_rate := minf(speed / stride, 0.5 / MIN_SWING)
	var moving := speed > 0.3
	var old_phase := phase
	if moving:
		phase = fmod(phase + cycle_rate * delta, 1.0)
	var swing_time := 0.5 / maxf(cycle_rate, 0.001)

	for i in 8:
		var hip := t * _hips[i]
		if curled:
			var out := t.basis * Vector3(_rests[i].x - _hips[i].x, 0.0, _rests[i].z - _hips[i].z)
			var target := hip + out * 0.35 + Vector3.UP * 0.55 * size
			_feet[i] = _feet[i].lerp(target, clampf(delta * 10.0, 0.0, 1.0))
			_swinging[i] = false
			_solve(i, hip, _feet[i], t)
			continue
		var rest := _rest_world(t, i)
		# teleporte (respawn, puxão de fio, esquiva longa): pés vão direto
		if _feet[i].distance_to(rest) > 2.6 * size:
			_feet[i] = rest
			_swinging[i] = false
		if moving:
			var g_start := 0.0 if _group(i) == 0 else 0.5
			var local := fposmod(phase - g_start, 1.0)        # 0..0.5 = no ar; 0.5..1 = apoiada
			var was_local := fposmod(old_phase - g_start, 1.0)
			if local < 0.5:
				if not _swinging[i] or was_local > local:
					_swinging[i] = true
					_from[i] = _feet[i]
				var s := local / 0.5
				# mira onde o corpo vai estar quando a pata pousar + meio apoio à frente
				var ahead := vel * (swing_time * (1.0 - s) + swing_time * 0.5)
				var target := rest + ahead
				var e := s * s * (3.0 - 2.0 * s)
				_feet[i] = _from[i].lerp(target, e) + Vector3.UP * sin(s * PI) * LIFT * size
			else:
				_swinging[i] = false
				_feet[i].y = rest.y   # apoiada: acompanha o chão (degrau, queda curta)
				# rápido demais para a passada (fio, empurrão): a pata escorrega junto
				var reach := (_femur_len + _tibia_len) * 0.97
				if _feet[i].distance_to(hip) > reach:
					_feet[i] = _feet[i].lerp(rest, clampf(delta * 20.0, 0.0, 1.0))
		else:
			_feet[i].y = lerpf(_feet[i].y, rest.y, clampf(delta * 12.0, 0.0, 1.0))
			_swinging[i] = false
		_solve(i, hip, _feet[i], t)

	# parada: patas fora do lugar voltam para a pose de descanso, um grupo de cada vez
	if not moving:
		_settle_t -= delta
		if _settle_t <= 0.0:
			_settle_t = 0.12
			_settle(t)


func _body_xform() -> Transform3D:
	## Posição e giro do corpo, sem a escala do visual (o tamanho já vem de `size`).
	var t := body.global_transform
	t.basis = t.basis.orthonormalized()
	return t


func hip_world(i: int) -> Vector3:
	return _body_xform() * _hips[i]


func _settle(t: Transform3D) -> void:
	for g in 2:
		var any := false
		for i in 8:
			if _group(i) != g:
				continue
			var rest := _rest_world(t, i)
			if _feet[i].distance_to(rest) > 0.12 * size:
				_feet[i] = _feet[i].lerp(rest, 0.65)
				any = true
		if any:
			return


func _group(i: int) -> int:
	## Grupos alternados: frente-esq., 2ª-dir., 3ª-esq., trás-dir. contra o resto.
	var side := 0 if i < 4 else 1
	return (i % 4 + side) % 2


func _solve(i: int, hip: Vector3, foot: Vector3, t: Transform3D) -> void:
	var to_foot := foot - hip
	var reach := _femur_len + _tibia_len
	var d := clampf(to_foot.length(), absf(_femur_len - _tibia_len) + 0.01, reach - 0.001)
	var dir := Vector3.DOWN
	if to_foot.length() > 0.001:
		dir = to_foot.normalized()
	var along := (_femur_len * _femur_len - _tibia_len * _tibia_len + d * d) / (2.0 * d)
	var h := sqrt(maxf(_femur_len * _femur_len - along * along, 0.0))
	# o joelho dobra para cima e um pouco para fora do corpo
	var outward := (t.basis * Vector3(_hips[i].x, 0.0, _hips[i].z)).normalized()
	var pole := t.basis.y.normalized() + outward * 0.35
	var n := pole - dir * pole.dot(dir)
	if n.length() < 0.001:
		n = t.basis.y
	n = n.normalized()
	var knee := hip + dir * along + n * h
	var foot_eff := hip + dir * d
	Fx.orient_between(_femurs[i], hip, knee)
	Fx.orient_between(_tibias[i], knee, foot_eff)
	_knees[i].position = knee
	_tips[i].position = foot_eff
