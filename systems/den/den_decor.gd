class_name DenDecor
extends Node3D
## A cara da toca, no estilo da casa da Kumoko no labirinto: chão forrado de seda trançada,
## paredes cobertas de teia, fios em leque do chão até a pedra, teias redondas, o casulo
## numa rede no meio e a despensa pendurada nas paredes. Só visual.
##   stage 0: ninho abandonado (teia velha, cinza e rasgada)
##   stage 1..5: a teia cresce (tomar a toca, portas, descansos e comida guardada)

const N_ANG := 96
const WALL_H := 2.7

var den: Den
var stage := -1
var _wall_r: PackedFloat32Array = PackedFloat32Array()
var _gap: Array[bool] = []
var _body: Node3D
var _pantry: Node3D
var _hammock: Node3D


func setup(den_: Den) -> DenDecor:
	den = den_
	return self


func _ready() -> void:
	_scan_walls()
	_pantry = Node3D.new()
	add_child(_pantry)


func _scan_walls() -> void:
	## Raio até a parede em cada direção (onde a rocha começa) e quais direções são entradas.
	_wall_r.resize(N_ANG)
	_gap.resize(N_ANG)
	var cave = GameState.current_layer.get("cave") if GameState.current_layer != null else null
	var c := Vector2(den.center.x, den.center.z)
	for k in N_ANG:
		var a := k * TAU / N_ANG
		var dir := Vector2(cos(a), sin(a))
		var r := den.inner_r
		if cave != null:
			r = 9.0
			var d := 1.5
			while d < 9.0:
				if cave.open_value(c + dir * d) < 0.05 or cave.floor_value(c + dir * d) < 0.0:
					r = d
					break
				d += 0.15
		_wall_r[k] = r
		_gap[k] = r > 6.2   # passou da rocha da toca: é uma das entradas
	# um respiro nas pontas de cada entrada (a teia de parede não invade o vão da porta)
	var g := _gap.duplicate()
	for k in N_ANG:
		if g[(k + 1) % N_ANG] or g[(k - 1 + N_ANG) % N_ANG]:
			_gap[k] = true


func _wr(k: int) -> float:
	return _wall_r[posmod(k, N_ANG)]


func _dir(k: int) -> Vector3:
	var a := k * TAU / N_ANG
	return Vector3(cos(a), 0.0, sin(a))


func _wall_pt(k: int, y: float, inset: float = 0.12) -> Vector3:
	## Ponto colado na parede na direção k, na altura y (a parede inclina um pouco para fora).
	return _dir(k) * (minf(_wr(k), 6.1) - inset + y * 0.06) + Vector3.UP * y   # nunca atravessa uma entrada


func set_stage(s: int) -> void:
	if s == stage:
		return
	stage = s
	if _body != null:
		_body.queue_free()
	_body = Node3D.new()
	add_child(_body)
	var m := SilkMesh.new(7 + s * 13, s == 0)      # chão, leques e fios do alto (véu bem leve)
	var w := SilkMesh.new(11 + s * 17, s == 0)     # paredes (véu mais denso: parecem lençóis de seda)
	if s == 0:
		_walls(w, 0.55, 3, true)
		_orbs(w, 3, true)
		_loose_floor(m, 12)
	else:
		_carpet(m, s)
		if s >= 2:
			_walls(w, [0.0, 0.0, 0.45, 0.8, 1.0, 1.0][s], [0, 0, 3, 5, 6, 8][s], false)
		if s >= 3:
			_orbs(w, [0, 0, 0, 2, 4, 6][s], false)
			_fans(m, [0, 0, 0, 4, 7, 10][s])
		if s >= 4:
			_overhead(m, 6 if s == 4 else 10)
	m.commit(_body, 0.035)
	w.commit(_body, 0.06 if s == 0 else 0.17)
	_build_hammock()
	refresh_pantry()


# ---------------------------------------------------------------- chão

func _carpet(m: SilkMesh, s: int) -> void:
	## Tapete de seda: raios do centro até a borda e anéis trançados entre eles.
	var spokes := 28
	var reach: float = [0.0, 0.45, 0.75, 1.0, 1.0, 1.0][s]
	var r_of := func(i: int) -> float:
		var k := int(float(i) / spokes * N_ANG)
		return minf(_wr(k), den.inner_r + 0.6) * reach - 0.25
	for i in spokes:
		var d := _dir(int(float(i) / spokes * N_ANG))
		var r: float = r_of.call(i)
		var pts: Array = []
		for t in 7:
			var q := d * lerpf(0.55, r, t / 6.0)
			pts.append(q + Vector3(0, 0.03 + 0.01 * sin(t * 1.7 + i), 0))
		m.thread(pts, 0.011)
		if s >= 2 and m.rng.randf() < 0.35:
			m.bead(d * r * m.rng.randf_range(0.4, 0.95) + Vector3(0, 0.05, 0), 0.025)
	var ring := 0.9
	var ri := 0
	while true:
		var any := false
		for i in spokes:
			var j := (i + 1) % spokes
			var ra: float = r_of.call(i)
			var rb: float = r_of.call(j)
			if ring > minf(ra, rb):
				continue
			any = true
			var a := _dir(int(float(i) / spokes * N_ANG)) * (ring + m.rng.randf_range(-0.06, 0.06)) + Vector3(0, 0.035, 0)
			var b := _dir(int(float(j) / spokes * N_ANG)) * (ring + m.rng.randf_range(-0.06, 0.06)) + Vector3(0, 0.035, 0)
			m.thread(m.sag(a, b, -0.004, 3), 0.008, s >= 3 and (ri + i) % 9 == 0)
			if true:
				var a0 := _dir(int(float(i) / spokes * N_ANG)) * maxf(0.55, ring - 0.42) + Vector3(0, 0.025, 0)
				var b0 := _dir(int(float(j) / spokes * N_ANG)) * maxf(0.55, ring - 0.42) + Vector3(0, 0.025, 0)
				m.veil_quad(a0, b0, b, a)
		if not any:
			break
		ring += 0.42
		ri += 1


func _loose_floor(m: SilkMesh, n: int) -> void:
	for k in n:
		var a := _dir(m.rng.randi() % N_ANG) * m.rng.randf_range(0.8, den.inner_r - 0.5) + Vector3(0, 0.03, 0)
		var b := a + Vector3(m.rng.randf_range(-1.2, 1.2), 0.0, m.rng.randf_range(-1.2, 1.2))
		m.thread(m.sag(a, b, -0.01, 4), 0.008)


# ---------------------------------------------------------------- paredes

func _walls(m: SilkMesh, cover: float, rows: int, torn: bool) -> void:
	## Teia cobrindo a parede: postes do chão até em cima, fios atravessados que cedem,
	## zigue-zague e véu. Em pedaços contínuos entre as entradas.
	var step := 3   # um poste a cada 3 direções (~1 m)
	var on := false
	var k := 0
	while k < N_ANG:
		if k % 12 == 0:
			on = m.rng.randf() < cover
		if _gap[k] or _gap[posmod(k + step, N_ANG)] or not on:
			k += step
			continue
		var k2 := k + step
		var hi := WALL_H * m.rng.randf_range(0.8, 1.0)
		if not (torn and m.rng.randf() < 0.3):
			m.thread([_wall_pt(k, 0.0), _wall_pt(k, hi * 0.5, 0.18), _wall_pt(k, hi)], 0.012)
		for r in rows:
			if torn and m.rng.randf() < 0.4:
				continue
			var y := (r + 0.6) / (rows + 0.4) * hi
			var y2 := y + m.rng.randf_range(-0.12, 0.12)
			m.thread(m.sag(_wall_pt(k, y), _wall_pt(k2, y2), 0.07, 4), 0.009, not torn and (k + r) % 11 == 0)
			if r % 2 == 0 and r + 1 < rows:
				var y3 := (r + 1.6) / (rows + 0.4) * hi
				m.thread([_wall_pt(k, y), (_wall_pt(k, y) + _wall_pt(k2, y3)) * 0.5 + _dir(k) * -0.06, _wall_pt(k2, y3)], 0.007)
			if not torn and r + 1 < rows:
				var yn := (r + 1.6) / (rows + 0.4) * hi
				m.veil_quad(_wall_pt(k, y, 0.14), _wall_pt(k2, y2, 0.14), _wall_pt(k2, yn, 0.14), _wall_pt(k, yn, 0.14))
			if not torn and m.rng.randf() < 0.15:
				m.bead(_wall_pt(k + 1, y + 0.02, 0.2), 0.026)
		if not torn:   # fios soltos em diagonal: tecido à mão, não cerca
			for x in 2:
				var ya := m.rng.randf_range(0.1, hi)
				var yb := clampf(ya + m.rng.randf_range(-1.0, 1.0), 0.05, hi)
				m.thread(m.sag(_wall_pt(k + m.rng.randi_range(-1, 1), ya, 0.16), _wall_pt(k2 + m.rng.randi_range(0, 2), yb, 0.16), 0.05, 4), 0.006)
		if torn and m.rng.randf() < 0.5:   # pedaço solto pendurado
			var a := _wall_pt(k + 1, hi * 0.8, 0.2)
			m.thread([a, a + Vector3(0.1, -0.7, 0.05) + _dir(k) * -0.2], 0.007)
		k += step


func _orbs(m: SilkMesh, n: int, torn: bool) -> void:
	## Teias redondas de aranha (raios e espiral) encostadas na parede.
	var free: Array = []
	for k in N_ANG:
		if not _gap[k] and not _gap[posmod(k - 4, N_ANG)] and not _gap[posmod(k + 4, N_ANG)]:
			free.append(k)
	if free.is_empty():
		return
	for i in n:
		var k: int = free[(i * 37 + 11) % free.size()]
		var r := m.rng.randf_range(0.6, 0.95)
		var c := _wall_pt(k, m.rng.randf_range(1.2, 1.7), 0.25)
		var inward := -_dir(k)
		var side := inward.cross(Vector3.UP).normalized()
		var spokes := 10
		var keep := 0.55 if torn else 1.0
		for s in spokes:
			if torn and m.rng.randf() < 0.3:
				continue
			var a := s * TAU / spokes
			m.thread([c, c + (side * cos(a) + Vector3.UP * sin(a)) * r], 0.009)
		var turns := 5
		var pts: Array = []
		var total := int(turns * spokes * keep)
		for t in total + 1:
			var a := float(t) / spokes * TAU
			var rr := r * (0.2 + 0.78 * float(t) / (turns * spokes))
			pts.append(c + (side * cos(a) + Vector3.UP * sin(a)) * rr + inward * 0.01)
		m.thread(pts, 0.006, not torn and i % 2 == 0)
		if not torn:
			m.bead(c + Vector3.UP * r * 0.5, 0.03)


func _fans(m: SilkMesh, n: int) -> void:
	## Fios em leque: do chão forrado sobem até o alto da parede.
	for i in n:
		var k := int(float(i) / n * N_ANG + 5)
		if _gap[posmod(k, N_ANG)]:
			continue
		var base := _dir(k) * (_wr(k) * 0.55) + Vector3(0, 0.04, 0)
		for f in 4:
			var kk := k + (f - 1.5) * 2.0
			if _gap[posmod(int(kk), N_ANG)]:
				continue
			var top := _wall_pt(int(kk), WALL_H * m.rng.randf_range(0.75, 0.95), 0.15)
			m.thread(m.sag(base, top, 0.05, 6), 0.009, f == 1 and i % 3 == 0)


func _overhead(m: SilkMesh, n: int) -> void:
	## Fios atravessando por cima (de parede a parede, bem acima da cabeça).
	var free: Array = []
	for k in N_ANG:
		if not _gap[k]:
			free.append(k)
	for i in n:
		var a: int = free[(i * 29 + 3) % free.size()]
		var b: int = free[(i * 29 + 3 + free.size() / 2 + (i % 5) * 3) % free.size()]
		m.thread(m.sag(_wall_pt(a, WALL_H * 0.95, 0.2), _wall_pt(b, WALL_H * 0.92, 0.2), 0.35, 10), 0.008, i % 4 == 0)


# ---------------------------------------------------------------- rede do casulo e despensa

func _build_hammock() -> void:
	if _hammock != null:
		_hammock.queue_free()
		_hammock = null
	if stage < 1 or den.cocoon == null or not is_instance_valid(den.cocoon):
		return
	_hammock = Node3D.new()
	add_child(_hammock)
	var m := SilkMesh.new(99)
	var lift := 0.45
	den.cocoon.position.y = lift   # o casulo fica suspenso na rede
	var hub := Vector3(0, lift + 0.15, 0)
	# rede embaixo: raios e anéis curtinhos
	for s in 10:
		var d := _dir(int(s * N_ANG / 10.0))
		m.thread(m.sag(hub + d * 0.15, d * 1.05 + Vector3(0, lift * 0.5, 0), 0.08, 4), 0.01)
	for ring in [0.5, 0.8]:
		var pts: Array = []
		for s in 21:
			var d := _dir(int(s * N_ANG / 20.0))
			pts.append(d * ring + Vector3(0, lift + 0.12 - ring * 0.25, 0))
		m.thread(pts, 0.008, ring > 0.6)
	# amarras até as paredes (entre as entradas), altas o bastante para passar por baixo
	var picks := 0
	var k := 6
	while k < N_ANG and picks < 6:
		if not _gap[k]:
			var top := _wall_pt(k, 2.0 + 0.3 * (picks % 2), 0.2)
			m.thread(m.sag(_dir(k) * 0.9 + Vector3(0, lift + 0.2, 0), top, 0.25, 8), 0.012)
			picks += 1
			k += 15
		else:
			k += 1
	m.commit(_hammock, 0.08)


func refresh_pantry() -> void:
	## Cada embrulho da despensa aparece pendurado na parede de teia.
	if _pantry == null:
		return
	for c in _pantry.get_children():
		c.queue_free()
	if stage < 1:
		return
	var free: Array = []
	for k in N_ANG:
		if not _gap[k] and not _gap[posmod(k - 3, N_ANG)] and not _gap[posmod(k + 3, N_ANG)]:
			free.append(k)
	if free.is_empty():
		return
	var mat := Fx.mat(Color(0.9, 0.92, 0.98), 0.5)   # claro: aparece no escuro da parede
	var m := SilkMesh.new(5)
	for i in den.pantry.size():
		var k: int = free[(i * 13 + 2) % free.size()]
		var y := 1.25 + 0.35 * (i % 3)
		var p := _wall_pt(k, y, 0.45)
		var b := Fx.sphere(0.24, mat)
		b.scale = Vector3(0.85, 1.4, 0.85)
		b.position = p
		_pantry.add_child(b)
		m.thread([p + Vector3.UP * 0.28, _wall_pt(k, WALL_H * 0.92, 0.2)], 0.008)
		for w in 3:   # voltas de seda no embrulho
			var yy := p.y - 0.12 + w * 0.12
			var pts: Array = []
			for s in 9:
				var a := s * TAU / 8.0
				pts.append(Vector3(p.x + cos(a) * 0.19, yy + sin(a * 2.0) * 0.02, p.z + sin(a) * 0.19))
			m.thread(pts, 0.006)
	m.commit(_pantry)
