class_name OrganicCave
extends RefCounted
## Caverna orgânica gerada por autômato celular (o formato "A" escolhido para as Galerias).
##
## Grade de 1 m: 0 = rocha, 1 = chão, 2 = abismo. Sempre a mesma caverna para a mesma
## semente (os testes e o save dependem disso).
##   1. Enche a grade de rocha/chão ao acaso (fill) e alisa N vezes: célula com 5+ vizinhos
##      de chão vira chão, com 3 ou menos vira rocha. Sai uma caverna de salões que se fundem.
##   2. Áreas "fixas" (as câmaras feitas à mão: covil, ponte, acampamento...) entram como
##      estão; áreas "protegidas" ficam rocha (nada de atalho em volta de uma trava).
##   3. Pedaços soltos são ligados ao maior por túneis tortos; pedaços pequenos somem.
##   4. Bolsões de abismo só no meio de salões largos (sempre sobra uma beirada para passar).
##   5. Vira campo de distância suave (CaveBuilder.field) para as malhas.

var w := 0
var h := 0
var origin := Vector2.ZERO
var grid := PackedByteArray()
var locked := PackedByteArray()      ## 1 = não mexer (fixo ou protegido)
var rng := RandomNumberGenerator.new()


func _init(rect: Rect2, seed_: int) -> void:
	origin = rect.position.floor()
	w = int(ceil(rect.size.x)) + 1
	h = int(ceil(rect.size.y)) + 1
	grid.resize(w * h)
	locked.resize(w * h)
	rng.seed = seed_


func idx(i: int, j: int) -> int:
	return j * w + i


func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x - origin.x)), int(floor(p.y - origin.y)))


func center_of(i: int, j: int) -> Vector2:
	return origin + Vector2(i + 0.5, j + 0.5)


func inside(i: int, j: int) -> bool:
	return i >= 0 and j >= 0 and i < w and j < h


# ---------------------------------------------------------------- etapas

func scatter(fill: float, margin: int = 3) -> void:
	for j in h:
		for i in w:
			var k := idx(i, j)
			if locked[k]:
				continue
			var edge := i < margin or j < margin or i >= w - margin or j >= h - margin
			grid[k] = 0 if edge else (1 if rng.randf() < fill else 0)


func smooth(iterations: int) -> void:
	for it in iterations:
		var nxt := grid.duplicate()
		for j in range(1, h - 1):
			for i in range(1, w - 1):
				var k := idx(i, j)
				if locked[k]:
					continue
				var n := 0
				for dj in [-1, 0, 1]:
					for di in [-1, 0, 1]:
						if (di != 0 or dj != 0) and grid[idx(i + di, j + dj)] > 0:
							n += 1
				if n >= 5:
					nxt[k] = 1
				elif n <= 3:
					nxt[k] = 0
		grid = nxt


func fix_open(open_fn: Callable, chasm_fn: Callable = Callable()) -> void:
	## Câmaras feitas à mão: o que open_fn(p) > 0 vira chão fixo (ou abismo, se chasm_fn > 0).
	for j in h:
		for i in w:
			var p := center_of(i, j)
			if float(open_fn.call(p)) > 0.0:
				var k := idx(i, j)
				grid[k] = 2 if (chasm_fn.is_valid() and float(chasm_fn.call(p)) > 0.0) else 1
				locked[k] = 1


func lock_rock(fn: Callable) -> void:
	## Rocha fixa onde fn(p) for verdadeiro (zonas que só têm as câmaras feitas à mão).
	for j in h:
		for i in w:
			var k := idx(i, j)
			if not locked[k] and fn.call(center_of(i, j)):
				grid[k] = 0
				locked[k] = 1


func protect(p: Vector2, r: float) -> void:
	## Força rocha num raio (em volta de travas e câmaras fechadas), sem tocar no que já é fixo.
	var c := cell_of(p)
	var ri := int(ceil(r))
	for j in range(c.y - ri, c.y + ri + 1):
		for i in range(c.x - ri, c.x + ri + 1):
			if inside(i, j) and not locked[idx(i, j)] and center_of(i, j).distance_to(p) <= r:
				grid[idx(i, j)] = 0
				locked[idx(i, j)] = 1


func protect_band(open_fn: Callable, band: float) -> void:
	## Rocha numa faixa de `band` m em volta do que open_fn marca como aberto.
	var b := int(ceil(band))
	var hits: Array = []
	for j in h:
		for i in w:
			if float(open_fn.call(center_of(i, j))) > 0.0:
				hits.append(Vector2i(i, j))
	for c in hits:
		for dj in range(-b, b + 1):
			for di in range(-b, b + 1):
				var i: int = c.x + di
				var j: int = c.y + dj
				if inside(i, j) and not locked[idx(i, j)] and Vector2(di, dj).length() <= band:
					grid[idx(i, j)] = 0
					locked[idx(i, j)] = 1


func open_blob(p: Vector2, r: float) -> void:
	## Garante chão num raio (onde uma câmara com nome precisa existir).
	var c := cell_of(p)
	var ri := int(ceil(r))
	for j in range(c.y - ri, c.y + ri + 1):
		for i in range(c.x - ri, c.x + ri + 1):
			if inside(i, j) and i > 1 and j > 1 and i < w - 2 and j < h - 2 and not locked[idx(i, j)]:
				var q := center_of(i, j)
				var rr := r * (1.0 + 0.25 * sin(atan2(q.y - p.y, q.x - p.x) * 3.0 + r))
				if q.distance_to(p) <= rr:
					grid[idx(i, j)] = 1


func carve_to(a: Vector2, b: Vector2, width: float = 1.5, wobble: float = 0.55) -> void:
	## Túnel torto de a até b (não fura o que está protegido).
	var x := a.x
	var y := a.y
	var ang := atan2(b.y - y, b.x - x)
	for step in 2000:
		var want := atan2(b.y - y, b.x - x)
		ang += 0.2 * sin(want - ang) + rng.randfn(0.0, wobble)
		x += cos(ang)
		y += sin(ang)
		_disk(Vector2(x, y), width + 0.4 * rng.randf())
		if Vector2(x, y).distance_to(b) < 1.5:
			break


func _disk(p: Vector2, r: float) -> void:
	var c := cell_of(p)
	var ri := int(ceil(r))
	for j in range(c.y - ri, c.y + ri + 1):
		for i in range(c.x - ri, c.x + ri + 1):
			if inside(i, j) and i > 1 and j > 1 and i < w - 2 and j < h - 2 and not locked[idx(i, j)]:
				if center_of(i, j).distance_to(p) <= r:
					grid[idx(i, j)] = 1


func components() -> Array:
	## Pedaços de chão ligados (4 vizinhos). Devolve [[células...], ...] do maior para o menor.
	var lab := PackedInt32Array()
	lab.resize(w * h)
	lab.fill(-1)
	var comps: Array = []
	for j in h:
		for i in w:
			var k := idx(i, j)
			if grid[k] == 0 or lab[k] >= 0:
				continue
			var cells: Array = []
			var stack: Array = [Vector2i(i, j)]
			lab[k] = comps.size()
			while not stack.is_empty():
				var c: Vector2i = stack.pop_back()
				cells.append(c)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = c + d
					if inside(q.x, q.y):
						var kq := idx(q.x, q.y)
						if grid[kq] > 0 and lab[kq] < 0:
							lab[kq] = comps.size()
							stack.append(q)
			comps.append(cells)
	comps.sort_custom(func(a, b): return a.size() > b.size())
	return comps


func connect_all(min_size: int = 40, skip: Array = []) -> void:
	## Liga cada pedaço grande ao principal pelo ponto mais próximo; pedaços pequenos viram rocha.
	## `skip`: pontos cujos pedaços ficam de fora (câmaras que só se alcançam por uma trava).
	for pass_i in 6:
		var comps := components()
		if comps.size() <= 1:
			return
		var main: Array = comps[0]
		var changed := false
		for ci in range(1, comps.size()):
			var cells: Array = comps[ci]
			if _has_any(cells, skip):
				continue
			if cells.size() < min_size and not _any_locked(cells):
				for c in cells:
					grid[idx(c.x, c.y)] = 0
				continue
			var best := INF
			var pa := Vector2.ZERO
			var pb := Vector2.ZERO
			var stride := maxi(1, main.size() / 400)
			for c in cells:
				for mi in range(0, main.size(), stride):
					var m: Vector2i = main[mi]
					var d := Vector2(c - m).length_squared()
					if d < best:
						best = d
						pa = center_of(c.x, c.y)
						pb = center_of(m.x, m.y)
			carve_to(pa, pb)
			changed = true
		if not changed:
			return


func _has_any(cells: Array, pts: Array) -> bool:
	for p in pts:
		var c := cell_of(p)
		if cells.has(c):
			return true
	return false


func _any_locked(cells: Array) -> bool:
	for c in cells:
		if locked[idx(c.x, c.y)]:
			return true
	return false


func wall_distance() -> PackedFloat32Array:
	## Distância (aprox.) de cada célula de chão até a rocha mais próxima.
	var d := PackedFloat32Array()
	d.resize(w * h)
	for k in w * h:
		d[k] = 0.0 if grid[k] == 0 else 1e6
	for j in h:
		for i in w:
			var k := idx(i, j)
			if d[k] == 0.0:
				continue
			if i > 0:
				d[k] = minf(d[k], d[k - 1] + 1.0)
			if j > 0:
				d[k] = minf(d[k], d[k - w] + 1.0)
			if i > 0 and j > 0:
				d[k] = minf(d[k], d[k - w - 1] + 1.414)
			if i < w - 1 and j > 0:
				d[k] = minf(d[k], d[k - w + 1] + 1.414)
	for j in range(h - 1, -1, -1):
		for i in range(w - 1, -1, -1):
			var k := idx(i, j)
			if i < w - 1:
				d[k] = minf(d[k], d[k + 1] + 1.0)
			if j < h - 1:
				d[k] = minf(d[k], d[k + w] + 1.0)
			if i < w - 1 and j < h - 1:
				d[k] = minf(d[k], d[k + w + 1] + 1.414)
			if i > 0 and j < h - 1:
				d[k] = minf(d[k], d[k + w - 1] + 1.414)
	return d


func chasm_pockets(threshold: float, min_wall: float, freq: float = 0.06) -> void:
	## Bolsões de abismo no meio dos salões largos (ruído acima de `threshold` e pelo menos
	## `min_wall` m longe da parede: sempre sobra beirada para contornar).
	var nz := FastNoiseLite.new()
	nz.seed = rng.randi()
	nz.frequency = freq
	var dist := wall_distance()
	for j in h:
		for i in w:
			var k := idx(i, j)
			if grid[k] != 1 or locked[k]:
				continue
			var p := center_of(i, j)
			if dist[k] >= min_wall and nz.get_noise_2d(p.x, p.y) > threshold:
				grid[k] = 2


func nearest_floor(p: Vector2, max_r: int = 30) -> Vector2:
	var c := cell_of(p)
	for r in max_r:
		for j in range(c.y - r, c.y + r + 1):
			for i in range(c.x - r, c.x + r + 1):
				if inside(i, j) and grid[idx(i, j)] == 1 and maxi(absi(i - c.x), absi(j - c.y)) == r:
					return center_of(i, j)
	return p


func is_floor(p: Vector2) -> bool:
	var c := cell_of(p)
	return inside(c.x, c.y) and grid[idx(c.x, c.y)] == 1


# ---------------------------------------------------------------- campos para o CaveBuilder

func _sdf_of(mask_fn: Callable) -> PackedFloat32Array:
	## Distância com sinal (+ dentro, - fora), suavizada, a partir de uma máscara.
	var inside_d := _dist_to(func(k): return not mask_fn.call(k))
	var outside_d := _dist_to(func(k): return mask_fn.call(k))
	var out := PackedFloat32Array()
	out.resize(w * h)
	for k in w * h:
		out[k] = (inside_d[k] - 0.5) if mask_fn.call(k) else (0.5 - outside_d[k])
	return out


func _dist_to(target: Callable) -> PackedFloat32Array:
	var d := PackedFloat32Array()
	d.resize(w * h)
	for k in w * h:
		d[k] = 0.0 if target.call(k) else 1e6
	for j in h:
		for i in w:
			var k := idx(i, j)
			if i > 0:
				d[k] = minf(d[k], d[k - 1] + 1.0)
			if j > 0:
				d[k] = minf(d[k], d[k - w] + 1.0)
			if i > 0 and j > 0:
				d[k] = minf(d[k], d[k - w - 1] + 1.414)
			if i < w - 1 and j > 0:
				d[k] = minf(d[k], d[k - w + 1] + 1.414)
	for j in range(h - 1, -1, -1):
		for i in range(w - 1, -1, -1):
			var k := idx(i, j)
			if i < w - 1:
				d[k] = minf(d[k], d[k + 1] + 1.0)
			if j < h - 1:
				d[k] = minf(d[k], d[k + w] + 1.0)
			if i < w - 1 and j < h - 1:
				d[k] = minf(d[k], d[k + w + 1] + 1.414)
			if i > 0 and j < h - 1:
				d[k] = minf(d[k], d[k + w - 1] + 1.414)
	return d


func open_shape(rough: float = 0.5) -> Dictionary:
	var g := grid
	return CaveBuilder.field(_sdf_of(func(k): return g[k] > 0), w, h, origin + Vector2(0.5, 0.5), rough)


func chasm_shape(rough: float = 0.3) -> Dictionary:
	var g := grid
	return CaveBuilder.field(_sdf_of(func(k): return g[k] == 2), w, h, origin + Vector2(0.5, 0.5), rough)


func preview(path: String) -> void:
	## PNG para conferir a caverna (cinza = chão, azul = abismo).
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for j in h:
		for i in w:
			var v := grid[idx(i, j)]
			var c := Color(0.03, 0.03, 0.05)
			if v == 1:
				c = Color(0.29, 0.32, 0.39) if not locked[idx(i, j)] else Color(0.4, 0.42, 0.5)
			elif v == 2:
				c = Color(0.09, 0.12, 0.26)
			img.set_pixel(i, j, c)
	img.resize(w * 4, h * 4, Image.INTERPOLATE_NEAREST)
	img.save_png(path)
