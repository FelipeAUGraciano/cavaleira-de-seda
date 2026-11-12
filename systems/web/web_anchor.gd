class_name WebAnchor
extends StaticBody3D
## Ponto onde fios podem ser presos.
##   kind "pilar"  : estalagmite no chão (forma, altura e inclinação variam pelo nome:
##                   o mesmo pilar sai sempre igual, mas nenhum é gêmeo do outro).
##   kind "gancho" : saliência de rocha na parede (só perto de abismos: poucos e marcados).
## Tudo é feito em código; se um modelo "estalagmite_a/b/c" existir, ele substitui a rocha.

var height := 4.0
var radius := 0.5
var color := Color(0.42, 0.42, 0.47)
var model_name := ""   ## "pilar_teia", "estalagmite_a"... (systems/models.gd)
var kind := "pilar"
var wall_normal := Vector3.ZERO   ## gancho: direção que sai da parede para o salão
var vary := true                  ## false = tamanho exato (salas de teste, puzzles medidos)
var tie_height := 0.9             ## altura onde os fios amarram no tronco
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _wrap: Node3D
var _ties := 0
var _trunk_r := 0.5   ## raio do tronco na altura do nó
var _trunk_off := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func _init(h: float = 4.0, r: float = 0.5, c: Color = Color(0.42, 0.42, 0.47)) -> void:
	height = h
	radius = r
	color = c


func _ready() -> void:
	add_to_group("anchor")
	collision_layer = 1
	collision_mask = 0
	_rng.seed = hash(String(name)) & 0x7fffffff
	var rock := Node3D.new()
	rock.name = "Rocha"
	add_child(rock)
	if kind == "gancho":
		_build_hook(rock)
	else:
		_build_stalagmite(rock)
	var shown := Models.swap(self, model_name, height, [rock], "height") if kind == "pilar" else null
	if shown != null:
		shown.rotation.y = _rng.randf() * TAU
		# o nó de seda abraça o modelo: raio pela largura dele perto da base
		var box := Models.bounds(shown, Transform3D.IDENTITY)
		_trunk_r = minf(box.size.x, box.size.z) * 0.22
		_trunk_off = Vector3(box.get_center().x, 0.0, box.get_center().z)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	cs.shape = shape
	cs.position.y = height * 0.5
	add_child(cs)
	_build_wrap()
	_ring_mat = Fx.mat(Color(0.4, 0.9, 1.0), 2.0, true, 0.85)
	_ring = Fx.cylinder(radius + 0.3, 0.05, _ring_mat)
	_ring.position.y = 0.06
	_ring.visible = false
	add_child(_ring)


func set_highlight(mode: int) -> void:
	## 0 = nada, 1 = disponível, 2 = selecionado (ponto A), 3 = sob o cursor
	_ring.visible = mode > 0
	var c := Color(0.4, 0.9, 1.0)
	if mode == 2:
		c = Color(1.0, 0.82, 0.3)
	elif mode == 3:
		c = Color(1.0, 1.0, 1.0)
	_ring_mat.albedo_color = Color(c.r, c.g, c.b, 0.85)
	_ring_mat.emission = c
	_ring.scale = Vector3.ONE * (1.35 if mode >= 2 else 1.0)


func tie_point() -> Vector3:
	## Onde os fios de amarra encostam no tronco (global).
	return global_position + _trunk_off + Vector3.UP * tie_height


func trunk_radius() -> float:
	return _trunk_r


func tie(on: bool) -> void:
	## Um fio amarrou (ou soltou) aqui: aparece o nó de seda enrolado no tronco.
	_ties = maxi(0, _ties + (1 if on else -1))
	if _wrap != null:
		_wrap.visible = _ties > 0


# ---------------------------------------------------------------- estalagmite

func _build_stalagmite(parent: Node3D) -> void:
	var h := height
	var r := radius
	if vary:
		h *= _rng.randf_range(0.6, 1.45)
		r *= _rng.randf_range(0.95, 1.35)   # só o visual: a colisão continua com o raio dado
	var style := _rng.randi() % 4 if vary else 0
	var lean := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).limit_length(1.0) * (0.12 if vary else 0.04)
	var mat := _rock_mat(color)
	match style:
		1:   # gêmeas fundidas
			_spire(parent, Vector3.ZERO, h, r, lean, 1.0, mat)
			var off := Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized() * r * 0.55
			_spire(parent, off, h * _rng.randf_range(0.5, 0.7), r * 0.75, -lean * 1.5, 1.0, mat)
		2:   # monte largo e baixo, com pontas
			h *= 0.62
			_spire(parent, Vector3.ZERO, h, r * 1.25, lean, 0.7, mat)
			for k in 3:
				var a := _rng.randf() * TAU
				_spire(parent, Vector3(cos(a), 0, sin(a)) * r * 0.5 + Vector3.UP * h * 0.45, h * 0.5, r * 0.35, lean * 2.0, 1.2, mat)
		3:   # agulha alta com anéis de pedra (camadas de calcário)
			h *= 1.2
			_spire(parent, Vector3.ZERO, h, r * 0.85, lean, 1.4, mat)
			for k in 2:
				var y := h * (0.3 + 0.25 * k)
				var ring := Fx.cylinder(r * (0.75 - 0.18 * k), 0.12, mat)
				ring.position = Vector3(lean.x * h * 0.3, y, lean.y * h * 0.3)
				ring.scale = Vector3(1.0, 1.0, _rng.randf_range(0.8, 1.15))
				parent.add_child(ring)
		_:
			_spire(parent, Vector3.ZERO, h, r, lean, 1.0, mat)
	height = h
	tie_height = clampf(h * 0.2, 0.45, 0.85)
	var main_r := r * (1.25 if style == 2 else (0.85 if style == 3 else 1.0))
	var tt := tie_height / h
	_trunk_r = main_r * lerpf(1.35, 0.1, pow(tt, 0.75)) * 0.88
	_trunk_off = Vector3(lean.x * h * tt * tt, 0.0, lean.y * h * tt * tt)
	# pontas pequenas em volta e cascalho: o pilar "nasce" do chão em vez de ser um poste
	var dark := _rock_mat(color.darkened(0.15))
	for k in _rng.randi_range(2, 4):
		var a := _rng.randf() * TAU
		var d := r + _rng.randf_range(0.1, 0.6)
		_spire(parent, Vector3(cos(a) * d, 0, sin(a) * d), _rng.randf_range(0.35, 1.0), r * _rng.randf_range(0.25, 0.42),
			Vector2(cos(a), sin(a)) * 0.25, 1.0, dark)
	for k in _rng.randi_range(2, 4):
		var a := _rng.randf() * TAU
		var d := r + _rng.randf_range(0.2, 0.9)
		var pebble := _blob_mesh(_rng.randf_range(0.1, 0.22), dark)
		pebble.position = Vector3(cos(a) * d, 0.04, sin(a) * d)
		parent.add_child(pebble)
	# poça de umidade na base (brilha de leve com a luz da visão)
	var wet := Fx.cylinder(r * 1.7, 0.01, Fx.mat(Color(0.12, 0.16, 0.17, 0.55), 0.0, false, 0.55))
	(wet.material_override as StandardMaterial3D).roughness = 0.15
	wet.position.y = 0.012
	wet.scale = Vector3(1.0, 1.0, _rng.randf_range(0.7, 1.0))
	parent.add_child(wet)
	# algumas têm veios de cristal (pontos frios que ajudam a achar o pilar no escuro)
	if vary and _rng.randf() < 0.35:
		var cm := Fx.mat(Color(0.45, 0.8, 0.85), 1.4)
		for k in _rng.randi_range(2, 4):
			var a := _rng.randf() * TAU
			var y := _rng.randf_range(0.3, h * 0.5)
			var t := y / h
			var rr := r * lerpf(1.2, 0.15, pow(t, 0.8))
			var cr := Fx.box(Vector3(0.06, 0.18, 0.06), cm)
			cr.position = Vector3(cos(a) * rr, y, sin(a) * rr)
			cr.rotation = Vector3(_rng.randf_range(-0.6, 0.6), a, _rng.randf_range(-0.6, 0.6))
			parent.add_child(cr)


func _spire(parent: Node3D, base: Vector3, h: float, r: float, lean: Vector2, sharp: float, mat: Material) -> void:
	## Cone torto e facetado: anéis com raio irregular, base alargada, ponta fina.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)   # facetas planas: cara de pedra lascada
	var sides := 9
	var levels := 7
	var rings: Array = []
	var phase := _rng.randf() * TAU
	for l in levels + 1:
		var t := float(l) / levels
		var ring: Array = []
		var rr := r * lerpf(1.35, 0.1, pow(t, 0.75 * sharp))
		var c := Vector3(lean.x * h * t * t, h * t, lean.y * h * t * t)
		for s in sides:
			var a := phase + TAU * s / sides + _rng.randf_range(-0.18, 0.18)
			var k := rr * _rng.randf_range(0.8, 1.18)
			ring.append(base + c + Vector3(cos(a) * k, _rng.randf_range(-0.04, 0.04) * h * (1.0 if l > 0 and l < levels else 0.0), sin(a) * k))
		rings.append(ring)
	var tip := base + Vector3(lean.x * h * 1.08, h * 1.04, lean.y * h * 1.08)
	for l in levels:
		var lo: Array = rings[l]
		var hi: Array = rings[l + 1]
		var shade := lerpf(0.75, 1.15, float(l) / levels)
		st.set_color(Color(shade, shade, shade))
		for s in sides:
			var s2 := (s + 1) % sides
			st.add_vertex(lo[s]); st.add_vertex(hi[s]); st.add_vertex(lo[s2])
			st.add_vertex(lo[s2]); st.add_vertex(hi[s]); st.add_vertex(hi[s2])
	st.set_color(Color(1.2, 1.2, 1.2))
	var top: Array = rings[levels]
	for s in sides:
		st.add_vertex(top[s]); st.add_vertex(tip); st.add_vertex(top[(s + 1) % sides])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	parent.add_child(mi)


func _blob_mesh(r: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 1.3
	sm.radial_segments = 7
	sm.rings = 4
	var arr := sm.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ids: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var jitter := {}
	for v in verts:
		var key := Vector3i((v * 1000.0).round())
		if not jitter.has(key):
			jitter[key] = v * _rng.randf_range(0.8, 1.2)
	st.set_color(Color(0.9, 0.9, 0.9))
	for i in ids:
		st.add_vertex(jitter[Vector3i((verts[i] * 1000.0).round())])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


# ---------------------------------------------------------------- gancho de parede

func _build_hook(parent: Node3D) -> void:
	## Chifre de rocha saindo da parede e curvando para cima (onde o fio prende).
	var n := wall_normal
	n.y = 0.0
	if n.length() < 0.1:
		n = Vector3.FORWARD
	n = n.normalized()
	height = 1.3
	radius = 0.35
	tie_height = 0.9
	_trunk_r = 0.15
	_trunk_off = -n * 0.1
	var mat := _rock_mat(color.lightened(0.08))
	# base: placa de rocha grudada na parede
	var body := _blob_mesh(0.6, mat)
	body.position = -n * 0.75 + Vector3.UP * 0.5
	body.scale = Vector3(1.3, 1.4, 1.3)
	parent.add_child(body)
	# chifre: sai da parede para o salão e sobe
	var horn: Array[Vector3] = []
	for i in 7:
		var t := i / 6.0
		horn.append(-n * 0.7 * (1.0 - t) + n * 0.15 * t + Vector3.UP * (0.25 + 1.0 * t * t + 0.25 * t))
	_horn(parent, horn, 0.3, mat)
	# lasca de cristal na ponta: o gancho se acha no escuro (e se lê como "dá para prender")
	var cm := Fx.mat(Color(0.5, 0.85, 0.9), 1.6)
	var cr := Fx.box(Vector3(0.07, 0.22, 0.07), cm)
	cr.position = horn[6] + Vector3.UP * 0.12
	cr.rotation = Vector3(0.3, _rng.randf() * TAU, 0.2)
	parent.add_child(cr)


func _horn(parent: Node3D, pts: Array[Vector3], r0: float, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var sides := 7
	var rings: Array = []
	for i in pts.size():
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, pts.size() - 1)]
		var t := (b - a).normalized()
		var side := t.cross(Vector3.UP)
		if side.length() < 0.05:
			side = Vector3.RIGHT
		side = side.normalized()
		var up := side.cross(t).normalized()
		var rr := r0 * lerpf(1.0, 0.12, float(i) / (pts.size() - 1))
		var ring: Array[Vector3] = []
		for s in sides:
			var ang := TAU * s / sides
			ring.append(pts[i] + (side * cos(ang) + up * sin(ang)) * rr * _rng.randf_range(0.85, 1.15))
		rings.append(ring)
	for i in pts.size() - 1:
		st.set_color(Color.WHITE * lerpf(0.8, 1.15, float(i) / pts.size()))
		var lo: Array = rings[i]
		var hi: Array = rings[i + 1]
		for s in sides:
			var s2 := (s + 1) % sides
			st.add_vertex(lo[s]); st.add_vertex(hi[s]); st.add_vertex(lo[s2])
			st.add_vertex(lo[s2]); st.add_vertex(hi[s]); st.add_vertex(hi[s2])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	parent.add_child(mi)


# ---------------------------------------------------------------- nó de seda

func _build_wrap() -> void:
	## Voltas de seda em volta do tronco, na altura do nó. Escondido até um fio amarrar aqui.
	_wrap = Node3D.new()
	_wrap.name = "NoDeSeda"
	_wrap.visible = false
	add_child(_wrap)
	var m := Fx.mat(Color(0.88, 0.9, 0.96, 0.85), 0.5, true, 0.85)
	var rr := _trunk_r
	for k in 3:
		var t := TorusMesh.new()
		var ry := rr * (1.0 - 0.06 * k)
		t.inner_radius = ry
		t.outer_radius = ry + 0.022
		t.rings = 16
		t.ring_segments = 4
		var mi := MeshInstance3D.new()
		mi.mesh = t
		mi.material_override = m
		mi.position = _trunk_off + Vector3.UP * (tie_height - 0.12 + 0.08 * k)
		mi.rotation = Vector3(_rng.randf_range(-0.1, 0.1), 0, _rng.randf_range(-0.1, 0.1))
		_wrap.add_child(mi)


func _rock_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	return m
