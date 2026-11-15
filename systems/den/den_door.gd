class_name DenDoor
extends StaticBody3D
## Porta de teia numa entrada da toca. A jogadora atravessa; os bichos não (camada 5).
## Tem vida: bicho com fome que sente a comida guardada rasga a porta para entrar.
## Rasgada, deixa passar até ser tecida de novo (C perto dela).

signal torn(door: DenDoor)
signal hit(door: DenDoor, by: Node3D)

const LAYER := 16
const MAX_HP := 60.0

var hp := MAX_HP
var width := 3.2
var across := Vector3(1, 0, 0)     ## direção da largura (de um lado ao outro da entrada)
var _vis: Node3D
var _cs: CollisionShape3D
var _flash := 0.0
var _blocked: Array = []           ## células da navegação travadas por esta porta


func _ready() -> void:
	add_to_group("den_door")
	collision_layer = LAYER
	collision_mask = 0
	var ax := across.normalized()
	look_at_from_position(global_position, global_position + ax.cross(Vector3.UP), Vector3.UP)
	_cs = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 2.4, 0.5)
	_cs.shape = box
	_cs.position.y = 1.2
	add_child(_cs)
	_vis = Node3D.new()
	add_child(_vis)
	_set_intact(hp > 0.0)


const H := 2.5


func _edge(side: float, t: float, fiber: int) -> Vector3:
	## Cabo da borda (side -1/1) na altura t (0..1): sobe da pedra, cede um pouco para dentro
	## no meio (como os cabos da ponte) e duas fibras torcem uma na outra.
	var x := side * width * 0.5 * (1.0 - 0.07 * sin(PI * t))
	var p := Vector3(x, 0.05 + t * (H - 0.05), 0.0)
	if fiber >= 0:
		var ph := p.y / 0.45 * TAU + fiber * PI
		p += Vector3(cos(ph) * 0.022, 0.0, sin(ph) * 0.022)
	return p


func _top(t: float) -> Vector3:
	return Vector3(lerpf(-width * 0.5, width * 0.5, t), H - 0.12 * sin(PI * t), 0.0)


func _build_web() -> void:
	## Cortina trançada: uma ponte de teia em pé, com o mesmo trançado, véu e orvalho.
	for c in _vis.get_children():
		c.queue_free()
	var whole := hp > 0.0
	var m := SilkMesh.new(hash(str(global_position.round())) & 0x7fffffff)
	var rng := m.rng
	var top_t := 1.0 if whole else 0.32   # rasgada: só sobra o pé da cortina
	# cabos das bordas (duas fibras torcidas cada) e o de cima
	for side in [-1.0, 1.0]:
		for fiber in 2:
			var pts: Array = []
			var n := 26
			for k in n + 1:
				pts.append(_edge(side, float(k) / n * (1.0 if whole or side < 0.0 else 0.75), fiber))
			m.thread(pts, 0.018)
		var y := rng.randf_range(0.25, 0.6)
		while y < H * (1.0 if whole else 0.7):
			m.bead(_edge(side, y / H, -1) + Vector3(0, 0, 0.03), rng.randf_range(0.022, 0.04))
			y += rng.randf_range(0.5, 1.1)
	if whole:
		for fiber in 2:
			var pts: Array = []
			for k in 17:
				var t := k / 16.0
				var ph := t * width / 0.45 * TAU + fiber * PI
				pts.append(_top(t) + Vector3(0, sin(ph) * 0.022, cos(ph) * 0.022))
			m.thread(pts, 0.018)
		# fio do meio
		m.thread(m.sag(Vector3(0, 0.05, 0), _top(0.5), 0.0, 8).map(func(q): return q + Vector3(0, 0, -0.02 * sin(q.y))), 0.02)
	# trama em zigue-zague, meio torta, de baixo até onde sobrou
	var rows := 9
	var hs: Array[float] = [0.0]
	for k in range(1, rows):
		hs.append(float(k) / rows + rng.randf_range(-0.3, 0.3) / rows)
	hs.append(1.0)
	for k in rows:
		if hs[k + 1] > top_t:
			break
		var sd := -1.0 if k % 2 == 0 else 1.0
		var p0 := _edge(sd, hs[k], -1)
		var p2 := _edge(-sd, hs[k + 1], -1)
		var p1 := (p0 + p2) * 0.5 + Vector3(rng.randf_range(-0.06, 0.06), -rng.randf_range(0.03, 0.08), rng.randf_range(-0.07, 0.07))
		m.thread([p0, p1, p2], 0.01, k % 3 == 1)
		if rng.randf() < 0.45:   # fio cruzado de volta
			m.thread([_edge(sd, hs[k + 1], -1), (p0 + p2) * 0.5 + Vector3.DOWN * 0.05, _edge(-sd, hs[k], -1)], 0.008)
		if whole:
			m.veil_quad(_edge(-1.0, hs[k], -1), _edge(1.0, hs[k], -1), _edge(1.0, hs[k + 1], -1), _edge(-1.0, hs[k + 1], -1))
	if whole:
		# amarras: do alto dos cabos em leque até a rocha dos dois lados
		for side in [-1.0, 1.0]:
			for t in [0.55, 0.8, 1.0]:
				var a := _edge(side, t, -1)
				var b := a + Vector3(side * rng.randf_range(0.5, 0.9), rng.randf_range(0.2, 0.6), rng.randf_range(-0.25, 0.25))
				m.thread(m.sag(a, b, 0.04, 4), 0.011)
			m.thread([_edge(side, 0.0, -1), _edge(side, 0.0, -1) + Vector3(side * 0.45, 0.0, 0.1)], 0.014)
	else:
		# fiapos: pedaços pendurados do que sobrou e restos caídos no chão
		for k in 6:
			var x := rng.randf_range(-width * 0.45, width * 0.45)
			var y0 := rng.randf_range(H * 0.75, H * 0.95)
			var y1 := y0 - rng.randf_range(0.4, 1.3)
			var a := Vector3(x, y0, 0.0)
			var b := Vector3(x + rng.randf_range(-0.3, 0.3), y1, rng.randf_range(-0.15, 0.15))
			m.thread([a, a.lerp(b, 0.5) + Vector3(0.05, 0, 0.05), b], 0.008)
		for k in 4:
			var a := Vector3(rng.randf_range(-width * 0.5, width * 0.5), 0.03, rng.randf_range(-0.6, 0.6))
			m.thread(m.sag(a, a + Vector3(rng.randf_range(-0.8, 0.8), 0.0, rng.randf_range(-0.8, 0.8)), -0.02, 4), 0.008)
	m.commit(_vis, 0.07)


func intact() -> bool:
	return hp > 0.0


func take_hit(dmg: float, by: Node3D = null) -> void:
	if hp <= 0.0:
		return
	hp = maxf(0.0, hp - dmg)
	_flash = 0.25
	hit.emit(self, by)
	if hp <= 0.0:
		_set_intact(false)
		torn.emit(self)


func weave() -> void:
	hp = MAX_HP
	_set_intact(true)


func _set_intact(on: bool) -> void:
	_cs.disabled = not on
	_build_web()
	_block_nav(on)


func _block_nav(on: bool) -> void:
	## Porta inteira: a navegação dos bichos não passa por aqui (dão a volta ou param na porta).
	if World.nav == null:
		return
	for c in _blocked:
		for g in World.nav.grids:
			g.set_point_solid(c, false)
	_blocked.clear()
	if not on:
		return
	var ax := across.normalized()
	var fw := ax.cross(Vector3.UP)
	var seen := {}
	for k in 17:
		for f: float in [-0.4, 0.0, 0.4]:
			var p := global_position + ax * lerpf(-width * 0.5 - 0.4, width * 0.5 + 0.4, k / 16.0) + fw * f
			var c := World.nav.cell_of(p)
			if seen.has(c) or not World.nav.has_cell(c):
				continue
			seen[c] = true
			if not World.nav.grids[0].is_point_solid(c):
				_blocked.append(c)
	for c in _blocked:
		for g in World.nav.grids:
			g.set_point_solid(c, true)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		_vis.position.z = sin(_flash * 80.0) * 0.08   # a cortina balança quando apanha
	elif _vis.position.z != 0.0:
		_vis.position.z = 0.0
