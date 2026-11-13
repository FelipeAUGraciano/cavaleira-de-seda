class_name CaveBuilder
extends RefCounted
## Gera cavernas orgânicas a partir de formas: bolhas, elipses e caminhos curvos.
##
## Como funciona:
##   1. Cada forma vira um "campo de distância" (positivo dentro, negativo fora) com ruído na borda.
##   2. A união das câmaras e túneis dá o espaço aberto; abismos tiram o chão; pontes devolvem.
##   3. Marching squares transforma os campos em malhas: chão de bordas suaves, paredes com
##      altura variável (altas ao norte, baixas ao sul para não tapar a câmera), penhascos nos
##      abismos e a massa de rocha em volta.
##   4. Uma grade de 1 m diz a que câmara cada ponto pertence (usada pelo mapa).

const STEP := 0.5
const WALL_TALL := 2.8
const WALL_LOW := 0.45
const CAP_H := 0.45
const PIT_Y := -9.0
const NO := -999.0

var rooms: Array = []      ## [{id, shapes: [shape...]}] — os dicionários de câmara da camada
var tunnels: Array = []    ## [shape]
var chasms: Array = []     ## [shape]
var bridges: Array = []    ## [shape] chão por cima de abismos
var floor_color := Color(0.3, 0.27, 0.33)
var rock_color := Color(0.2, 0.17, 0.24)
var noise := FastNoiseLite.new()
var detail := FastNoiseLite.new()

var _min := Vector2.ZERO
var _o_cache := PackedFloat32Array()   ## espaço aberto já calculado na grade de 0,5 m
var _f_cache := PackedFloat32Array()   ## chão firme já calculado na grade de 0,5 m
var _nx := 0
var _nz := 0


# ---------------------------------------------------------------- formas

static func blob(c: Vector2, r: float, rough: float = 1.2) -> Dictionary:
	return {"t": "blob", "c": c, "r": r, "n": rough, "box": Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0).grow(rough + 1.0)}


static func ellipse(c: Vector2, rx: float, rz: float, rot: float = 0.0, rough: float = 1.5) -> Dictionary:
	var m := maxf(rx, rz)
	return {"t": "ellipse", "c": c, "rx": rx, "rz": rz, "rot": rot, "n": rough, "box": Rect2(c - Vector2(m, m), Vector2(m, m) * 2.0).grow(rough + 1.0)}


static func path(pts: Array, w: float, rough: float = 0.6) -> Dictionary:
	var box := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		box = box.expand(p)
	return {"t": "path", "pts": pts, "w": w, "n": rough, "box": box.grow(w * 0.5 + rough + 1.0)}


static func field(data: PackedFloat32Array, w: int, h: int, origin: Vector2, rough: float = 0.0) -> Dictionary:
	## Campo de distância pronto (1 m por célula), vindo de uma caverna gerada (OrganicCave).
	return {"t": "field", "data": data, "w": w, "h": h, "o": origin, "n": rough,
		"box": Rect2(origin, Vector2(w - 1, h - 1)).grow(rough + 0.5)}


# ---------------------------------------------------------------- campos

func _init() -> void:
	noise.seed = 7
	noise.frequency = 0.09
	detail.seed = 21
	detail.frequency = 0.35


func _sdf(s: Dictionary, p: Vector2, nv: float) -> float:
	var box: Rect2 = s["box"]
	if not box.has_point(p):
		return NO
	var n: float = s["n"] * nv
	match s["t"]:
		"blob":
			return float(s["r"]) - p.distance_to(s["c"]) + n
		"ellipse":
			var q: Vector2 = (p - s["c"]).rotated(-float(s["rot"]))
			var rx: float = s["rx"]
			var rz: float = s["rz"]
			var k := sqrt((q.x / rx) * (q.x / rx) + (q.y / rz) * (q.y / rz))
			return (1.0 - k) * minf(rx, rz) + n
		"field":
			var d: PackedFloat32Array = s["data"]
			var fw: int = s["w"]
			var fh: int = s["h"]
			var q: Vector2 = p - s["o"]
			var i := int(floor(q.x))
			var j := int(floor(q.y))
			if i < 0 or j < 0 or i >= fw - 1 or j >= fh - 1:
				return NO
			var tx := q.x - i
			var tz := q.y - j
			var a := lerpf(d[j * fw + i], d[j * fw + i + 1], tx)
			var b := lerpf(d[(j + 1) * fw + i], d[(j + 1) * fw + i + 1], tx)
			return lerpf(a, b, tz) + n
		_:
			var pts: Array = s["pts"]
			var best := 1e9
			for i in pts.size() - 1:
				best = minf(best, _seg_dist(p, pts[i], pts[i + 1]))
			return float(s["w"]) * 0.5 - best + n


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _max_of(shapes: Array, p: Vector2, nv: float) -> float:
	var v := NO
	for s in shapes:
		v = maxf(v, _sdf(s, p, nv))
	return v


func open_at(p: Vector2) -> float:
	var nv := noise.get_noise_2d(p.x, p.y)
	var v := _max_of(tunnels, p, nv)
	for r in rooms:
		if not r.get("label_only", false):
			v = maxf(v, _max_of(r["shapes"], p, nv))
	return v


func floor_at(p: Vector2) -> float:
	var nv := noise.get_noise_2d(p.x, p.y)
	var o := _max_of(tunnels, p, nv)
	for r in rooms:
		if not r.get("label_only", false):
			o = maxf(o, _max_of(r["shapes"], p, nv))
	return _floor_from(o, _max_of(chasms, p, nv), _max_of(bridges, p, nv))


func _stamp(sh: Dictionary, arr: PackedFloat32Array, nv_vals: PackedFloat32Array) -> PackedFloat32Array:
	var box: Rect2 = sh["box"]
	var i0 := maxi(0, int(floor((box.position.x - _min.x) / STEP)))
	var i1 := mini(_nx - 1, int(ceil((box.end.x - _min.x) / STEP)))
	var j0 := maxi(0, int(floor((box.position.y - _min.y) / STEP)))
	var j1 := mini(_nz - 1, int(ceil((box.end.y - _min.y) / STEP)))
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var k := j * _nx + i
			var v := _sdf(sh, _min + Vector2(i, j) * STEP, nv_vals[k])
			if v > arr[k]:
				arr[k] = v
	return arr


func _floor_from(o: float, c: float, b: float) -> float:
	var f := minf(o, -c)
	if b > 0.0:
		f = maxf(f, minf(o, b))
	return f


func floor_value(p: Vector2) -> float:
	## Quanto de chão firme há em p (> 0 = chão; maior = mais longe da borda). Rápido depois de build().
	return _floor_cached(p)


func open_value(p: Vector2) -> float:
	## Quanto de espaço aberto há em p (inclui abismos). Rápido depois de build().
	return _open_cached(p)


func _open_cached(p: Vector2) -> float:
	## Espaço aberto lido da grade de build() (interpolado); fora dela, cálculo direto.
	var v := _sample(_o_cache, p)
	return open_at(p) if is_nan(v) else v


func _floor_cached(p: Vector2) -> float:
	var v := _sample(_f_cache, p)
	return floor_at(p) if is_nan(v) else v


func _sample(arr: PackedFloat32Array, p: Vector2) -> float:
	if arr.is_empty():
		return NAN
	var fx := (p.x - _min.x) / STEP
	var fz := (p.y - _min.y) / STEP
	var i := int(floor(fx))
	var j := int(floor(fz))
	if i < 0 or j < 0 or i >= _nx - 1 or j >= _nz - 1:
		return NAN
	var tx := fx - i
	var tz := fz - j
	var a := lerpf(arr[j * _nx + i], arr[j * _nx + i + 1], tx)
	var b := lerpf(arr[(j + 1) * _nx + i], arr[(j + 1) * _nx + i + 1], tx)
	return lerpf(a, b, tz)


func is_floor(p: Vector2, margin: float = 0.0) -> bool:
	return _floor_cached(p) > margin   # depois do build() lê a grade pronta (bem mais rápido)


func room_index_at(p: Vector2) -> int:
	var nv := noise.get_noise_2d(p.x, p.y)
	var best := NO
	var idx := -1
	for i in rooms.size():
		var v := _max_of(rooms[i]["shapes"], p, nv)
		if v > best:
			best = v
			idx = i
	if idx == -1:
		# longe de todas as câmaras (meio de um túnel): fica com a câmara de centro mais próximo
		var best_d := 1e9
		for i in rooms.size():
			for sh in rooms[i]["shapes"]:
				var box: Rect2 = sh["box"]
				var d := p.distance_to(box.get_center())
				if d < best_d:
					best_d = d
					idx = i
	return idx


# ---------------------------------------------------------------- construção

func build(parent: Node3D) -> Dictionary:
	var bounds := Rect2()
	var first := true
	var all_shapes: Array = tunnels.duplicate()
	for r in rooms:
		if not r.get("label_only", false):   # câmaras só de nome não abrem espaço
			all_shapes.append_array(r["shapes"])
	for s in all_shapes:
		if first:
			bounds = s["box"]
			first = false
		else:
			bounds = bounds.merge(s["box"])
	bounds = bounds.grow(2.0)
	_min = bounds.position
	_nx = int(ceil(bounds.size.x / STEP)) + 1
	_nz = int(ceil(bounds.size.y / STEP)) + 1

	var n := _nx * _nz
	var o_vals := PackedFloat32Array()
	var f_vals := PackedFloat32Array()
	var pit_vals := PackedFloat32Array()
	var rock_vals := PackedFloat32Array()
	var c_vals := PackedFloat32Array()
	var b_vals := PackedFloat32Array()
	o_vals.resize(n)   # (arrays "Packed" são copiados por valor: um resize por vez)
	f_vals.resize(n)
	pit_vals.resize(n)
	rock_vals.resize(n)
	c_vals.resize(n)
	b_vals.resize(n)
	o_vals.fill(NO)
	c_vals.fill(NO)
	b_vals.fill(NO)
	# Ruído uma vez por ponto; cada forma só visita os pontos da sua caixa (bem mais rápido
	# que testar todas as formas em todos os pontos).
	var nv_vals := PackedFloat32Array()
	nv_vals.resize(n)
	for j in _nz:
		for i in _nx:
			var p := _min + Vector2(i, j) * STEP
			nv_vals[j * _nx + i] = noise.get_noise_2d(p.x, p.y)
	for sh in all_shapes:
		o_vals = _stamp(sh, o_vals, nv_vals)
	for sh in chasms:
		c_vals = _stamp(sh, c_vals, nv_vals)
	for sh in bridges:
		b_vals = _stamp(sh, b_vals, nv_vals)
	for k in n:
		var o := o_vals[k]
		var f := _floor_from(o, c_vals[k], b_vals[k])
		rock_vals[k] = -o
		f_vals[k] = f
		pit_vals[k] = minf(o, -f)
	_o_cache = o_vals
	_f_cache = f_vals

	var floor_m := _march(f_vals, true, true)
	var wall_m := _march(o_vals, false, true)
	var rock_m := _march(rock_vals, true, false)
	var pit_m := _march(pit_vals, true, false)

	_add_floor(parent, floor_m[0])
	_add_walls(parent, wall_m[1])
	_add_flat(parent, rock_m[0], CAP_H, rock_color.darkened(0.35), 0.25)
	_add_flat(parent, pit_m[0], PIT_Y, Color(0.02, 0.02, 0.03), 0.0)
	_add_cliffs(parent, floor_m[1])
	return _room_grid()


# ---------------------------------------------------------------- marching squares

func _march(vals: PackedFloat32Array, want_fill: bool, want_lines: bool) -> Array:
	var tris := PackedVector2Array()
	var segs := PackedVector2Array()
	for j in _nz - 1:
		for i in _nx - 1:
			var k0 := j * _nx + i
			var v0 := vals[k0]
			var v1 := vals[k0 + 1]
			var v2 := vals[k0 + 1 + _nx]
			var v3 := vals[k0 + _nx]
			var code := (1 if v0 > 0.0 else 0) | (2 if v1 > 0.0 else 0) | (4 if v2 > 0.0 else 0) | (8 if v3 > 0.0 else 0)
			if code == 0:
				continue
			var c0 := _min + Vector2(i, j) * STEP
			var c1 := c0 + Vector2(STEP, 0.0)
			var c2 := c0 + Vector2(STEP, STEP)
			var c3 := c0 + Vector2(0.0, STEP)
			if code == 15:
				if want_fill:
					tris.append_array(PackedVector2Array([c0, c1, c2, c0, c2, c3]))
				continue
			var e0 := c0.lerp(c1, v0 / (v0 - v1)) if (v0 > 0.0) != (v1 > 0.0) else c0
			var e1 := c1.lerp(c2, v1 / (v1 - v2)) if (v1 > 0.0) != (v2 > 0.0) else c1
			var e2 := c3.lerp(c2, v3 / (v3 - v2)) if (v3 > 0.0) != (v2 > 0.0) else c3
			var e3 := c0.lerp(c3, v0 / (v0 - v3)) if (v0 > 0.0) != (v3 > 0.0) else c0
			var center_in := (v0 + v1 + v2 + v3) > 0.0
			var polys: Array = []
			var lines: Array = []
			match code:
				1:
					polys = [[c0, e0, e3]]
					lines = [e0, e3]
				2:
					polys = [[e0, c1, e1]]
					lines = [e0, e1]
				4:
					polys = [[e1, c2, e2]]
					lines = [e1, e2]
				8:
					polys = [[e3, e2, c3]]
					lines = [e2, e3]
				3:
					polys = [[c0, c1, e1, e3]]
					lines = [e1, e3]
				6:
					polys = [[e0, c1, c2, e2]]
					lines = [e0, e2]
				12:
					polys = [[e3, e1, c2, c3]]
					lines = [e1, e3]
				9:
					polys = [[c0, e0, e2, c3]]
					lines = [e0, e2]
				7:
					polys = [[c0, c1, c2, e2, e3]]
					lines = [e2, e3]
				11:
					polys = [[c0, c1, e1, e2, c3]]
					lines = [e1, e2]
				13:
					polys = [[c0, e0, e1, c2, c3]]
					lines = [e0, e1]
				14:
					polys = [[e0, c1, c2, c3, e3]]
					lines = [e0, e3]
				5:
					if center_in:
						polys = [[c0, e0, e1, c2, e2, e3]]
						lines = [e0, e1, e2, e3]
					else:
						polys = [[c0, e0, e3], [e1, c2, e2]]
						lines = [e0, e3, e1, e2]
				10:
					if center_in:
						polys = [[e0, c1, e1, e2, c3, e3]]
						lines = [e0, e3, e1, e2]
					else:
						polys = [[e0, c1, e1], [e3, e2, c3]]
						lines = [e0, e1, e2, e3]
			if want_fill:
				for poly in polys:
					for t in range(1, poly.size() - 1):
						tris.append_array(PackedVector2Array([poly[0], poly[t], poly[t + 1]]))
			if want_lines:
				for l in lines:
					segs.append(l)
	return [tris, segs]


# ---------------------------------------------------------------- malhas

static func _tri(verts: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray,
		a: Vector3, b: Vector3, c: Vector3, n: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	## Godot usa sentido horário para a face da frente: garante que a frente aponte para n.
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
		var tc := cb
		cb = cc
		cc = tc
	verts.append_array(PackedVector3Array([a, b, c]))
	normals.append_array(PackedVector3Array([n, n, n]))
	colors.append_array(PackedColorArray([ca, cb, cc]))


func _mesh_node(parent: Node3D, verts: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, collide: bool, emission: float = 0.0) -> void:
	if verts.is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = Color(0.05, 0.04, 0.07)
		mat.emission_energy_multiplier = emission
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if collide:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.add_child(mi)
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(verts)
		var cs := CollisionShape3D.new()
		cs.shape = shape
		body.add_child(cs)
		parent.add_child(body)
	else:
		parent.add_child(mi)


func _collision_node(parent: Node3D, faces: PackedVector3Array) -> void:
	## Só colisão (sem malha). As paredes do lado da câmera são baixas para ver a aranha,
	## mas a colisão delas tem a altura toda: fio lançado, linha de visão e fios-guia
	## param nelas como nas paredes altas.
	if faces.is_empty():
		return
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)


func _shade_floor(p: Vector2) -> Color:
	var o := _open_cached(p)
	var ao := clampf(0.55 + o * 0.22, 0.55, 1.0)
	var var_n := 0.88 + 0.12 * noise.get_noise_2d(p.x * 3.1, p.y * 3.1) + 0.06 * detail.get_noise_2d(p.x, p.y)
	return Color(floor_color.r * ao * var_n, floor_color.g * ao * var_n, floor_color.b * ao * var_n)


func _add_floor(parent: Node3D, tris: PackedVector2Array) -> void:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var cache := {}
	for t in range(0, tris.size(), 3):
		var a := tris[t]
		var b := tris[t + 1]
		var c := tris[t + 2]
		for p in [a, b, c]:
			if not cache.has(p):
				cache[p] = _shade_floor(p)
		_tri(verts, normals, colors, Vector3(a.x, 0.0, a.y), Vector3(b.x, 0.0, b.y), Vector3(c.x, 0.0, c.y), Vector3.UP, cache[a], cache[b], cache[c])
	_mesh_node(parent, verts, normals, colors, true)


func _add_flat(parent: Node3D, tris: PackedVector2Array, y: float, color: Color, var_amount: float) -> void:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for t in range(0, tris.size(), 3):
		var pts := [tris[t], tris[t + 1], tris[t + 2]]
		var cols := []
		for p in pts:
			var k := 1.0 + var_amount * noise.get_noise_2d(p.x * 2.0, p.y * 2.0)
			cols.append(Color(color.r * k, color.g * k, color.b * k))
		_tri(verts, normals, colors, Vector3(pts[0].x, y, pts[0].y), Vector3(pts[1].x, y, pts[1].y), Vector3(pts[2].x, y, pts[2].y), Vector3.UP, cols[0], cols[1], cols[2])
	_mesh_node(parent, verts, normals, colors, false)


func _rock_normal(p: Vector2) -> Vector2:
	## Direção do aberto para a rocha (contra o gradiente do campo aberto).
	var e := 0.25
	var g := Vector2(_open_cached(p + Vector2(e, 0)) - _open_cached(p - Vector2(e, 0)), _open_cached(p + Vector2(0, e)) - _open_cached(p - Vector2(0, e)))
	if g.length() < 0.0001:
		return Vector2(0, -1)
	return -g.normalized()


func _wall_height(p: Vector2, n: Vector2) -> float:
	## n aponta para a rocha. Rocha ao norte (n.y < 0) = parede alta, vista de frente pela câmera.
	var t := clampf((-n.y + 0.25) / 1.25, 0.0, 1.0)
	return lerpf(WALL_LOW, WALL_TALL, t) + 0.45 * t * (0.5 + 0.5 * detail.get_noise_2d(p.x, p.y))


func _add_walls(parent: Node3D, segs: PackedVector2Array) -> void:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var top_v := PackedVector3Array()
	var top_n := PackedVector3Array()
	var top_c := PackedColorArray()
	var col_v := PackedVector3Array()   # colisão sempre alta: a parede baixa (perto da câmera) é só visual
	var info := {}
	for p in segs:
		if not info.has(p):
			var n := _rock_normal(p)
			info[p] = [n, _wall_height(p, n)]
	var base := rock_color
	for s in range(0, segs.size(), 2):
		var a := segs[s]
		var b := segs[s + 1]
		var na: Vector2 = info[a][0]
		var nb: Vector2 = info[b][0]
		var ha: float = info[a][1]
		var hb: float = info[b][1]
		var face_n := Vector3(-(na.x + nb.x), 0.0, -(na.y + nb.y)).normalized()
		var lit := 0.8 + 0.2 * detail.get_noise_2d(a.x * 2.0, a.y * 2.0)
		var cb := Color(base.r * 0.55, base.g * 0.55, base.b * 0.6)
		var ct := Color(base.r * lit * 1.25, base.g * lit * 1.25, base.b * lit * 1.3)
		var a0 := Vector3(a.x, -0.05, a.y)
		var b0 := Vector3(b.x, -0.05, b.y)
		var a1 := Vector3(a.x, ha, a.y)
		var b1 := Vector3(b.x, hb, b.y)
		_tri(verts, normals, colors, a0, b0, b1, face_n, cb, cb, ct)
		_tri(verts, normals, colors, a0, b1, a1, face_n, cb, ct, ct)
		var ac := Vector3(a.x, maxf(ha, WALL_TALL), a.y)
		var bc := Vector3(b.x, maxf(hb, WALL_TALL), b.y)
		col_v.append_array(PackedVector3Array([a0, b0, bc, a0, bc, ac]))
		var a2 := a1 + Vector3(na.x, 0.0, na.y) * 0.9
		var b2 := b1 + Vector3(nb.x, 0.0, nb.y) * 0.9
		var cap := Color(base.r * 0.8, base.g * 0.8, base.b * 0.85)
		_tri(top_v, top_n, top_c, a1, b1, b2, Vector3.UP, ct, ct, cap)
		_tri(top_v, top_n, top_c, a1, b2, a2, Vector3.UP, ct, cap, cap)
	_mesh_node(parent, verts, normals, colors, false)
	_mesh_node(parent, top_v, top_n, top_c, false)
	_collision_node(parent, col_v)


func _add_cliffs(parent: Node3D, segs: PackedVector2Array) -> void:
	## Penhascos: bordas do chão que dão para um abismo (e não para a rocha).
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var top := Color(rock_color.r * 0.9, rock_color.g * 0.9, rock_color.b)
	var bottom := Color(0.01, 0.01, 0.02)
	for s in range(0, segs.size(), 2):
		var a := segs[s]
		var b := segs[s + 1]
		var mid := (a + b) * 0.5
		if _open_cached(mid) < 0.15:
			continue
		var e := 0.25
		var g := Vector2(_floor_cached(mid + Vector2(e, 0)) - _floor_cached(mid - Vector2(e, 0)), _floor_cached(mid + Vector2(0, e)) - _floor_cached(mid - Vector2(0, e)))
		var n := Vector3(-g.x, 0.0, -g.y).normalized()
		var a0 := Vector3(a.x, 0.0, a.y)
		var b0 := Vector3(b.x, 0.0, b.y)
		var a1 := Vector3(a.x, PIT_Y, a.y)
		var b1 := Vector3(b.x, PIT_Y, b.y)
		_tri(verts, normals, colors, a0, b0, b1, n, top, top, bottom)
		_tri(verts, normals, colors, a0, b1, a1, n, top, bottom, bottom)
	_mesh_node(parent, verts, normals, colors, false)


# ---------------------------------------------------------------- mapa e decoração

func _room_grid() -> Dictionary:
	var origin := Vector2(floor(_min.x), floor(_min.y))
	var w := int(ceil((_nx - 1) * STEP)) + 1
	var h := int(ceil((_nz - 1) * STEP)) + 1
	var ids := PackedInt32Array()
	ids.resize(w * h)
	ids.fill(-1)
	var runs := {}
	var pits: Array = []
	for r in rooms:
		runs[r["id"]] = []
	for j in h:
		var pit_start := -1
		for i in w + 1:
			var is_pit := false
			if i < w:
				var q := origin + Vector2(i + 0.5, j + 0.5)
				is_pit = _open_cached(q) > 0.0 and _floor_cached(q) <= 0.0
			if is_pit and pit_start < 0:
				pit_start = i
			elif not is_pit and pit_start >= 0:
				pits.append(Rect2(origin + Vector2(pit_start, j), Vector2(i - pit_start, 1)))
				pit_start = -1
		var run_start := -1
		var run_id := -1
		for i in w + 1:
			var id := -1
			if i < w:
				var p := origin + Vector2(i + 0.5, j + 0.5)
				if _open_cached(p) > 0.0:
					id = room_index_at(p)
				ids[j * w + i] = id
			if id != run_id:
				if run_id >= 0:
					runs[rooms[run_id]["id"]].append(Rect2(origin + Vector2(run_start, j), Vector2(i - run_start, 1)))
				run_id = id
				run_start = i
	return {"origin": origin, "w": w, "h": h, "ids": ids, "runs": runs, "pits": pits, "bounds": Rect2(origin, Vector2(w, h))}


func scatter_decor(parent: Node3D, seed_: int = 3) -> void:
	## Estalagmites encostadas nas paredes e pedrinhas soltas no chão.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var stone := Fx.mat(rock_color.lightened(0.12))
	var pebble := Fx.mat(floor_color.darkened(0.2))
	var x := _min.x
	while x < _min.x + _nx * STEP:
		var z := _min.y
		while z < _min.y + _nz * STEP:
			var p := Vector2(x + rng.randf_range(-0.6, 0.6), z + rng.randf_range(-0.6, 0.6))
			var f := _floor_cached(p)
			var o := _open_cached(p)
			if f > 0.25 and o < 1.1 and detail.get_noise_2d(p.x * 0.7, p.y * 0.7) > 0.15:
				var hgt := rng.randf_range(0.8, 2.2)
				var cone := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.02
				cm.bottom_radius = rng.randf_range(0.22, 0.45)
				cm.height = hgt
				cm.radial_segments = 6
				cone.mesh = cm
				cone.material_override = stone
				cone.position = Vector3(p.x, hgt * 0.5, p.y)
				cone.rotation = Vector3(rng.randf_range(-0.12, 0.12), rng.randf(), rng.randf_range(-0.12, 0.12))
				parent.add_child(cone)
				var sm := Models.swap(parent, "estalagmite_" + "abc"[rng.randi() % 3], hgt, [cone], "height")
				if sm != null:
					sm.position = Vector3(p.x, 0.0, p.y)
					sm.rotation.y = rng.randf() * TAU
			elif f > 1.5 and rng.randf() < 0.05:
				var rock := Fx.sphere(rng.randf_range(0.12, 0.3), pebble)
				rock.scale = Vector3(1.0, rng.randf_range(0.4, 0.8), rng.randf_range(0.8, 1.3))
				rock.position = Vector3(p.x, 0.05, p.y)
				rock.rotation.y = rng.randf() * TAU
				parent.add_child(rock)
			elif f > 1.2 and o < 2.2 and rng.randf() < 0.012:
				# rochas maiores perto das paredes: só aparecem quando os modelos existem
				var big := Models.instance("rocha_" + "abc"[rng.randi() % 3], rng.randf_range(0.9, 1.6), "max")
				if big != null:
					big.position = Vector3(p.x, -0.1, p.y)
					big.rotation.y = rng.randf() * TAU
					parent.add_child(big)
			z += 1.5
		x += 1.5
