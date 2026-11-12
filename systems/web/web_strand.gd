class_name WebStrand
extends StaticBody3D
## Fio-guia: ponte andável entre duas âncoras.
## Só a jogadora colide com ele (camada "fio"), então criaturas não atravessam abismos por fios.

const WIDTH := 1.1

var anchor_a := ""
var anchor_b := ""
var a_pos := Vector3.ZERO
var b_pos := Vector3.ZERO
var in_territory := false
var _mat: StandardMaterial3D
var _mem_mat: StandardMaterial3D
var _dew_mat: StandardMaterial3D
var _rng := RandomNumberGenerator.new()

const SILK := Color(0.85, 0.88, 0.95)
const SILK_TERRITORY := Color(0.55, 0.95, 1.0)
const CABLE_X := 0.4


func setup(a: Node3D, b: Node3D) -> void:
	anchor_a = String(a.name)
	anchor_b = String(b.name)
	a_pos = Vector3(a.global_position.x, 0.0, a.global_position.z)
	b_pos = Vector3(b.global_position.x, 0.0, b.global_position.z)


func _ready() -> void:
	add_to_group("strand")
	collision_layer = 8
	collision_mask = 0
	var dir := b_pos - a_pos
	var length := dir.length()
	position = (a_pos + b_pos) * 0.5
	rotation.y = atan2(dir.x, dir.z)

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(WIDTH, 0.1, length)
	cs.shape = shape
	cs.position.y = -0.03
	add_child(cs)

	_build_visual(length)
	set_in_territory(in_territory)


func set_in_territory(on: bool) -> void:
	in_territory = on
	if _mat == null:
		return
	var c := SILK_TERRITORY if on else SILK
	_mat.albedo_color = c
	_mat.emission = c
	_mat.emission_energy_multiplier = 1.4 if on else 0.6
	_mem_mat.albedo_color = Color(c.r, c.g, c.b, 0.07 if on else 0.045)
	_mem_mat.emission = c
	_dew_mat.emission_energy_multiplier = 2.6 if on else 1.6


func _exit_tree() -> void:
	for n in [anchor_a, anchor_b]:
		var an = WebNetwork.anchors.get(n)
		if an is WebAnchor and is_instance_valid(an):
			(an as WebAnchor).tie(false)


# ---------------------------------------------------------------- visual
## A ponte é tecida em código (não precisa de modelo: cada fio tem um comprimento):
## dois cabos torcidos nas bordas, um fio no meio, trama em zigue-zague entre eles,
## um véu de seda bem fino por baixo, gotas de orvalho e amarras subindo até o nó
## de cada pilar.

func _build_visual(length: float) -> void:
	_rng.seed = hash(anchor_a + "|" + anchor_b) & 0x7fffffff
	_mat = Fx.mat(SILK, 0.6, true)
	_mem_mat = Fx.mat(SILK, 0.4, true, 0.045)
	_mem_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_dew_mat = Fx.mat(Color(0.8, 0.95, 1.0), 1.6, true)
	var aa = WebNetwork.anchors.get(anchor_a)
	var bb = WebNetwork.anchors.get(anchor_b)
	var ra := _end_r(aa)
	var rb := _end_r(bb)
	var z0 := -length * 0.5 + ra
	var z1 := length * 0.5 - rb
	if z1 - z0 < 0.6:
		z0 = -length * 0.5
		z1 = length * 0.5
	var span := z1 - z0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dew: Array[Vector3] = []
	# cabos das bordas: duas fibras torcidas cada
	for side in [-1.0, 1.0]:
		for fiber in 2:
			var pts: Array[Vector3] = []
			var n := maxi(10, int(span / 0.12))
			for i in n + 1:
				var t := float(i) / n
				pts.append(_cable(side, t, z0, span, fiber))
			_tube(st, pts, 0.017)
		var z := z0 + _rng.randf_range(0.3, 1.2)
		while z < z1 - 0.3:
			dew.append(_cable(side, (z - z0) / span, z0, span, -1) + Vector3.UP * 0.03)
			z += _rng.randf_range(0.7, 1.9)
	# fio do meio
	var mid: Array[Vector3] = []
	for i in 9:
		var t := i / 8.0
		mid.append(Vector3(0.0, 0.035 - 0.02 * sin(PI * t), lerpf(z0, z1, t)))
	_tube(st, mid, 0.02)
	# trama em zigue-zague, meio torta (tecida à mão, não treliça de metal)
	var k := maxi(2, int(span / 0.55))
	var jit: Array[float] = [0.0]
	for i in range(1, k):
		jit.append(_rng.randf_range(-0.35, 0.35) / k)
	jit.append(0.0)
	for i in k:
		var ta := float(i) / k + jit[i]
		var tb := float(i + 1) / k + jit[i + 1]
		var s := -1.0 if i % 2 == 0 else 1.0
		var p0 := _cable(s, ta, z0, span, -1)
		var p2 := _cable(-s, tb, z0, span, -1)
		var p1 := (p0 + p2) * 0.5 + Vector3(_rng.randf_range(-0.06, 0.06), -_rng.randf_range(0.02, 0.05), _rng.randf_range(-0.08, 0.08))
		_tube(st, [p0, p1, p2], 0.009)
		if _rng.randf() < 0.3:   # alguns fios cruzados de volta
			_tube(st, [_cable(s, tb, z0, span, -1), (p0 + p2) * 0.5 + Vector3.DOWN * 0.03, _cable(-s, ta, z0, span, -1)], 0.007)
	# amarras: saem da ponte um pouco antes do fim e sobem em leque até o nó do pilar
	for e in [[aa, 1.0], [bb, -1.0]]:
		var an = e[0]
		if not (an is WebAnchor) or not is_instance_valid(an):
			continue
		var w := an as WebAnchor
		var dirz := float(e[1])
		var tp := to_local(w.tie_point())
		var tr := w.trunk_radius()
		var out := clampf(span * 0.18, 0.5, 1.4) / span
		var t_out := out if dirz > 0.0 else 1.0 - out
		var t_end := 0.0 if dirz > 0.0 else 1.0
		for side in [-1.0, 0.0, 1.0]:
			var start := _cable(side, t_out, z0, span, -1) if side != 0.0 else Vector3(0, 0.03, lerpf(z0, z1, t_out))
			var to := tp + Vector3(side * tr * 0.85, _rng.randf_range(-0.05, 0.05), dirz * tr * (0.5 if side == 0.0 else 0.2))
			_tube(st, [start, start.lerp(to, 0.5) + Vector3.DOWN * 0.04, to], 0.011)
		# e as pontas dos cabos encostam no tronco, rente ao chão
		for side in [-1.0, 1.0]:
			var a0 := _cable(side, t_end, z0, span, -1)
			_tube(st, [a0, Vector3(side * tr * 0.6, 0.12, tp.z + dirz * tr * 0.4)], 0.014)
		w.tie(true)
	var mi := MeshInstance3D.new()
	mi.name = "Fios"
	mi.mesh = st.commit()
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	# véu de seda entre os cabos (bem transparente: dá corpo à ponte sem esconder o abismo)
	var sm := SurfaceTool.new()
	sm.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := maxi(4, int(span / 0.4))
	for i in steps:
		var ta := float(i) / steps
		var tb := float(i + 1) / steps
		var l0 := _cable(-1.0, ta, z0, span, -1) + Vector3.DOWN * 0.03
		var r0 := _cable(1.0, ta, z0, span, -1) + Vector3.DOWN * 0.03
		var l1 := _cable(-1.0, tb, z0, span, -1) + Vector3.DOWN * 0.03
		var r1 := _cable(1.0, tb, z0, span, -1) + Vector3.DOWN * 0.03
		sm.add_vertex(l0); sm.add_vertex(r0); sm.add_vertex(l1)
		sm.add_vertex(l1); sm.add_vertex(r0); sm.add_vertex(r1)
	var mem := MeshInstance3D.new()
	mem.name = "Veu"
	mem.mesh = sm.commit()
	mem.material_override = _mem_mat
	mem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mem)
	# orvalho
	if not dew.is_empty():
		var sd := SurfaceTool.new()
		sd.begin(Mesh.PRIMITIVE_TRIANGLES)
		for p in dew:
			_bead(sd, p, _rng.randf_range(0.022, 0.04))
		var dm := MeshInstance3D.new()
		dm.name = "Orvalho"
		dm.mesh = sd.commit()
		dm.material_override = _dew_mat
		dm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(dm)


func _end_r(an) -> float:
	if an is WebAnchor and is_instance_valid(an):
		return (an as WebAnchor).trunk_radius() * 0.8
	return 0.3


func _cable(side: float, t: float, z0: float, span: float, fiber: int) -> Vector3:
	## Ponto do cabo da borda (side -1/1) em t (0..1). fiber -1 = centro do cabo.
	## Nas pontas os cabos se juntam um pouco (afunila até o pilar) e no meio cedem de leve.
	var z := z0 + span * t
	var e := clampf(minf(t * span, (1.0 - t) * span) / 1.4, 0.0, 1.0)
	var w := lerpf(0.45, 1.0, e * e * (3.0 - 2.0 * e))
	var y := 0.08 - 0.035 * sin(PI * t)
	var p := Vector3(side * CABLE_X * w, y, z)
	if fiber >= 0:
		var ph := z / 0.5 * TAU + fiber * PI
		p += Vector3(cos(ph) * 0.02, sin(ph) * 0.02, 0.0)
	return p


func _tube(st: SurfaceTool, pts: Array, r: float) -> void:
	## Tubo de 4 lados ao longo dos pontos (fio fino que aparece de qualquer ângulo).
	var rings: Array = []
	for i in pts.size():
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var b: Vector3 = pts[mini(i + 1, pts.size() - 1)]
		var t := (b - a).normalized()
		var side := t.cross(Vector3.UP)
		if side.length() < 0.01:
			side = Vector3.RIGHT
		side = side.normalized()
		var up := side.cross(t).normalized()
		var ring: Array[Vector3] = []
		for s in 4:
			var ang := PI * 0.25 + s * PI * 0.5
			ring.append(pts[i] + (side * cos(ang) + up * sin(ang)) * r)
		rings.append(ring)
	for i in pts.size() - 1:
		var lo: Array = rings[i]
		var hi: Array = rings[i + 1]
		for s in 4:
			var s2 := (s + 1) % 4
			st.add_vertex(lo[s]); st.add_vertex(hi[s]); st.add_vertex(lo[s2])
			st.add_vertex(lo[s2]); st.add_vertex(hi[s]); st.add_vertex(hi[s2])


func _bead(st: SurfaceTool, c: Vector3, r: float) -> void:
	var v := [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	var faces := [[0, 2, 4], [0, 4, 3], [0, 3, 5], [0, 5, 2], [1, 4, 2], [1, 3, 4], [1, 5, 3], [1, 2, 5]]
	for f in faces:
		for i in f:
			st.add_vertex(c + (v[i] as Vector3) * r)


func connects(a_name: String, b_name: String) -> bool:
	return (anchor_a == a_name and anchor_b == b_name) or (anchor_a == b_name and anchor_b == a_name)


func crossing_distance(p: Vector3, height: float, end_margin: float = 1.0) -> float:
	## Para bichos andando: distância até o trecho do meio do fio (perto das âncoras não conta:
	## andar rente ao pilar não enrosca) e só se o fio estiver baixo o bastante para bater no corpo.
	var a := Vector2(a_pos.x, a_pos.z)
	var b := Vector2(b_pos.x, b_pos.z)
	var q := Vector2(p.x, p.z)
	var ab := b - a
	var L := ab.length()
	if L < end_margin * 2.0 + 0.2:
		return INF
	var t := (q - a).dot(ab) / (L * L)
	var m := end_margin / L
	if t < m or t > 1.0 - m:
		return INF
	var y := lerpf(a_pos.y, b_pos.y, t)
	if y > p.y + height or y < p.y - 0.3:
		return INF
	return q.distance_to(a + ab * t)


func distance_to(p: Vector3) -> float:
	## Distância no plano XZ entre um ponto e o segmento do fio.
	var a := Vector2(a_pos.x, a_pos.z)
	var b := Vector2(b_pos.x, b_pos.z)
	var q := Vector2(p.x, p.z)
	var ab := b - a
	var t := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return q.distance_to(a + ab * t)
