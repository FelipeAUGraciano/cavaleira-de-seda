class_name NavGrid
extends RefCounted
## Navegação pela caverna em células de 1 m (AStarGrid2D, que roda em C++).
## Três grades, uma por "corpo":
##   SMALL  bichos pequenos e médios (precisa de ~0,35 m de folga até a borda)
##   LARGE  bichos grandes, como a Centopeia (~1,2 m de folga: não passa em frestas)
##   AIR    voadores: qualquer espaço aberto, inclusive por cima de abismos
## Também sabe a câmara de cada célula, para sortear destinos de passeio.

enum Kind { SMALL, LARGE, AIR }
const CLEARANCE := [0.35, 1.2, 0.6]
const OBSTACLE_PAD := [0.8, 1.4, 0.0]

var origin := Vector2.ZERO
var w := 0
var h := 0
var grids: Array[AStarGrid2D] = []
var room_ids: PackedStringArray = PackedStringArray()   ## índice da câmara -> id ("G4")
var room_cells := {}                                     ## id -> Array[Vector2i] andáveis (SMALL)
var _cell_room := PackedInt32Array()


func build(cave: CaveBuilder, map_grid: Dictionary, rooms: Array, obstacles: Array) -> void:
	origin = map_grid["origin"]
	w = int(map_grid["w"])
	h = int(map_grid["h"])
	_cell_room = map_grid["ids"]
	room_ids.clear()
	for r in rooms:
		room_ids.append(String(r["id"]))
		room_cells[String(r["id"])] = []
	grids.clear()
	for k in 3:
		var g := AStarGrid2D.new()
		g.region = Rect2i(0, 0, w, h)
		g.cell_size = Vector2(1, 1)
		g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		g.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		g.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		g.update()
		grids.append(g)
	for j in h:
		for i in w:
			var c := Vector2i(i, j)
			var p := origin + Vector2(i + 0.5, j + 0.5)
			var f := cave.floor_value(p)
			var o := cave.open_value(p)
			grids[Kind.SMALL].set_point_solid(c, f < CLEARANCE[Kind.SMALL])
			grids[Kind.LARGE].set_point_solid(c, f < CLEARANCE[Kind.LARGE])
			grids[Kind.AIR].set_point_solid(c, o < CLEARANCE[Kind.AIR])
			var rid := _cell_room[j * w + i]
			if rid >= 0 and rid < room_ids.size() and f >= CLEARANCE[Kind.SMALL]:
				(room_cells[room_ids[rid]] as Array).append(c)
	for o in obstacles:
		var pos: Vector3 = o
		for k in [Kind.SMALL, Kind.LARGE]:
			var pad: float = OBSTACLE_PAD[k]
			var c0 := cell_of(pos)
			var r := ceili(pad)
			for dj in range(-r, r + 1):
				for di in range(-r, r + 1):
					var c := c0 + Vector2i(di, dj)
					if _inside(c) and Vector2(di, dj).length() <= pad:
						grids[k].set_point_solid(c, true)


func cell_of(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x - origin.x), floori(pos.z - origin.y))


func center_of(c: Vector2i) -> Vector3:
	return Vector3(origin.x + c.x + 0.5, 0.0, origin.y + c.y + 0.5)


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h


func walkable(pos: Vector3, kind: int = Kind.SMALL) -> bool:
	var c := cell_of(pos)
	return _inside(c) and not grids[kind].is_point_solid(c)


func _snap(c: Vector2i, kind: int) -> Vector2i:
	## Célula andável mais próxima (até 4 m), para começar e terminar caminhos fora da grade.
	if _inside(c) and not grids[kind].is_point_solid(c):
		return c
	for r in range(1, 5):
		for dj in range(-r, r + 1):
			for di in range(-r, r + 1):
				if absi(di) != r and absi(dj) != r:
					continue
				var n := c + Vector2i(di, dj)
				if _inside(n) and not grids[kind].is_point_solid(n):
					return n
	return Vector2i(-1, -1)


func path(from: Vector3, to: Vector3, kind: int = Kind.SMALL) -> PackedVector3Array:
	var out := PackedVector3Array()
	var a := _snap(cell_of(from), kind)
	var b := _snap(cell_of(to), kind)
	if a.x < 0 or b.x < 0:
		return out
	var ids := grids[kind].get_id_path(a, b, true)
	# pula células em linha reta: só os cantos viram pontos do caminho
	var last_dir := Vector2i.ZERO
	for i in range(1, ids.size()):
		var d: Vector2i = ids[i] - ids[i - 1]
		if d != last_dir and i > 1:
			out.append(center_of(ids[i - 1]))
		last_dir = d
	if ids.size() > 1:
		out.append(center_of(ids[ids.size() - 1]))
	return out


func room_at(pos: Vector3) -> String:
	var c := cell_of(pos)
	if not _inside(c):
		return ""
	var rid := _cell_room[c.y * w + c.x]
	return room_ids[rid] if rid >= 0 and rid < room_ids.size() else ""


func random_point(room_id: String, kind: int = Kind.SMALL) -> Variant:
	## Ponto andável sorteado dentro da câmara (null se não houver).
	var cells: Array = room_cells.get(room_id, [])
	if cells.is_empty():
		return null
	for i in 24:
		var c: Vector2i = cells.pick_random()
		if not grids[kind].is_point_solid(c):
			return center_of(c)
	return null
