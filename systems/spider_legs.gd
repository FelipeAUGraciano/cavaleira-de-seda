class_name SpiderLegs
extends Node3D
## Oito patas procedurais com IK de dois segmentos (fêmur + tíbia).
## Os pés ficam presos no chão (ou no fio) e dão passos quando o corpo se afasta deles,
## em dois grupos alternados, como uma aranha de verdade: sempre há 4 patas apoiadas.
## Serve para a Cavaleira, para as irmãs e, depois, para o modelo 3D (é só trocar os segmentos).

const SPREAD := [0.75, 0.28, -0.22, -0.65]   ## abertura de cada par, da frente para trás (rad)

var body: Node3D = null          ## nó que dá posição e rotação do corpo
var size := 1.0                  ## escala geral (1.0 = Cavaleira Filhote)
var ground_mask := 1             ## camadas onde os pés pisam
var leg_color := Color(0.12, 0.11, 0.26)
var joint_color := Color(0.78, 0.6, 0.25)
var curled := false              ## morte: patas encolhidas para cima
var velocity_hint := Vector3.ZERO

var _hips: Array[Vector3] = []
var _rests: Array[Vector3] = []
var _feet: Array[Vector3] = []
var _from: Array[Vector3] = []
var _to: Array[Vector3] = []
var _step_t: Array[float] = []   ## < 0 = pé apoiado
var _femurs: Array[MeshInstance3D] = []
var _tibias: Array[MeshInstance3D] = []
var _knees: Array[MeshInstance3D] = []
var _femur_len := 0.42
var _tibia_len := 0.6
var _ready_feet := false


func setup(body_node: Node3D, scale_: float, mask: int) -> void:
	body = body_node
	size = scale_
	ground_mask = mask


func _ready() -> void:
	top_level = true
	transform = Transform3D.IDENTITY
	_femur_len = 0.42 * size
	_tibia_len = 0.6 * size
	var leg_mat := Fx.mat(leg_color)
	var joint_mat := Fx.mat(joint_color, 0.3)
	for i in 8:
		var side := -1.0 if i < 4 else 1.0
		var idx := i % 4
		var hip := Vector3(0.2 * side, 0.45, -0.3 + idx * 0.16) * size
		var dir := Vector3(side, 0.0, 0.0).rotated(Vector3.UP, side * float(SPREAD[idx]))
		var rest := Vector3(hip.x, 0.0, hip.z) + dir * 0.78 * size
		_hips.append(hip)
		_rests.append(rest)
		_feet.append(Vector3.ZERO)
		_from.append(Vector3.ZERO)
		_to.append(Vector3.ZERO)
		_step_t.append(-1.0)
		var femur := Fx.box(Vector3(0.06, 0.06, _femur_len) * Vector3(size, size, 1.0), leg_mat)
		var tibia := Fx.box(Vector3(0.05, 0.05, _tibia_len) * Vector3(size, size, 1.0), leg_mat)
		var knee := Fx.sphere(0.045 * size, joint_mat)
		add_child(femur)
		add_child(tibia)
		add_child(knee)
		_femurs.append(femur)
		_tibias.append(tibia)
		_knees.append(knee)


func _process(delta: float) -> void:
	if body == null or not is_instance_valid(body):
		return
	var t := body.global_transform
	if not _ready_feet:
		for i in 8:
			_feet[i] = _ground(t * _rests[i])
		_ready_feet = true

	var speed := Vector2(velocity_hint.x, velocity_hint.z).length()
	var step_time := clampf(0.14 - speed * 0.006, 0.06, 0.14)
	var busy := [false, false]
	for i in 8:
		if _step_t[i] >= 0.0:
			busy[_group(i)] = true

	for i in 8:
		var hip := t * _hips[i]
		if curled:
			var out := t.basis * Vector3(_rests[i].x - _hips[i].x, 0.0, _rests[i].z - _hips[i].z)
			var target := hip + out * 0.35 + Vector3.UP * 0.55 * size
			_feet[i] = _feet[i].lerp(target, clampf(delta * 10.0, 0.0, 1.0))
			_step_t[i] = -1.0
		elif _step_t[i] >= 0.0:
			_step_t[i] += delta / step_time
			if _step_t[i] >= 1.0:
				_feet[i] = _to[i]
				_step_t[i] = -1.0
			else:
				var k := _step_t[i]
				_feet[i] = _from[i].lerp(_to[i], k) + Vector3.UP * sin(k * PI) * 0.16 * size
		else:
			var desired := _ground(t * _rests[i] + velocity_hint * 0.08)
			var dist := _feet[i].distance_to(desired)
			if dist > 2.5 * size:
				_feet[i] = desired   # teleporte (respawn, puxão de fio)
			elif dist > 0.42 * size and not busy[1 - _group(i)]:
				_from[i] = _feet[i]
				_to[i] = desired
				_step_t[i] = 0.0
				busy[_group(i)] = true
		_solve(i, hip, _feet[i], t)


func _group(i: int) -> int:
	## Grupos alternados: frente-esq., 2ª-dir., 3ª-esq., trás-dir. contra o resto.
	var side := 0 if i < 4 else 1
	return (i % 4 + side) % 2


func _ground(p: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.2 * size, p + Vector3.DOWN * 1.5 * size, ground_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return p
	return hit["position"]


func _solve(i: int, hip: Vector3, foot: Vector3, t: Transform3D) -> void:
	var to_foot := foot - hip
	var reach := _femur_len + _tibia_len
	var d := clampf(to_foot.length(), absf(_femur_len - _tibia_len) + 0.01, reach - 0.001)
	var dir := Vector3.DOWN
	if to_foot.length() > 0.001:
		dir = to_foot.normalized()
	var along := (_femur_len * _femur_len - _tibia_len * _tibia_len + d * d) / (2.0 * d)
	var h := sqrt(maxf(_femur_len * _femur_len - along * along, 0.0))
	# o joelho dobra para fora e para cima do corpo
	var outward := t.basis * Vector3(_hips[i].x, 0.0, _hips[i].z)
	var pole := outward.normalized() * 0.4 + t.basis.y.normalized()
	var n := pole - dir * pole.dot(dir)
	if n.length() < 0.001:
		n = t.basis.y
	n = n.normalized()
	var knee := hip + dir * along + n * h
	var foot_eff := hip + dir * d
	Fx.orient_between(_femurs[i], hip, knee)
	Fx.orient_between(_tibias[i], knee, foot_eff)
	_knees[i].position = knee
