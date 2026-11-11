extends Node
## Mundo vivo da camada atual.
##   - Registro espacial: criaturas e cadáveres numa grade de 8 m, refeita 10× por segundo.
##     As buscas ("quem está perto?") olham só as células vizinhas, em vez de varrer a cena.
##   - Navegação (NavGrid) e relógio da caverna (CaveClock) da camada.
##   - Pontos de pasto (perto dos fungos) para as larvas.
## A camada chama reset() ao nascer; criaturas e cadáveres se registram sozinhos.

const CELL := 8.0

var nav: NavGrid = null
var clock: CaveClock = null
var creatures: Array[Creature] = []
var corpses: Array[Corpse] = []
var graze_spots: Array[Vector3] = []
var flocks := {}                       ## id do bando -> {dest: Vector3, until: float}
var _grid := {}                        ## Vector2i -> Array[Creature]
var _rebuild := 0.0


func reset() -> void:
	nav = null
	clock = null
	creatures.clear()
	corpses.clear()
	graze_spots.clear()
	flocks.clear()
	_grid.clear()


func register(c: Creature) -> void:
	if not creatures.has(c):
		creatures.append(c)
	_put(c)


func unregister(c: Creature) -> void:
	creatures.erase(c)


func register_corpse(c: Corpse) -> void:
	if not corpses.has(c):
		corpses.append(c)


func unregister_corpse(c: Corpse) -> void:
	corpses.erase(c)


func _physics_process(delta: float) -> void:
	_rebuild -= delta
	if _rebuild > 0.0:
		return
	_rebuild = 0.1
	_grid.clear()
	for c in creatures:
		if is_instance_valid(c) and not c.dead:
			_put(c)


func _put(c: Creature) -> void:
	var key := Vector2i(floori(c.global_position.x / CELL), floori(c.global_position.z / CELL))
	(_grid.get_or_add(key, []) as Array).append(c)


# ---------------------------------------------------------------- buscas

func near(pos: Vector3, radius: float) -> Array[Creature]:
	var out: Array[Creature] = []
	var r := ceili(radius / CELL)
	var cx := floori(pos.x / CELL)
	var cz := floori(pos.z / CELL)
	var r2 := radius * radius
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var bucket = _grid.get(Vector2i(cx + dx, cz + dz))
			if bucket == null:
				continue
			for c in bucket:
				if is_instance_valid(c) and not c.dead:
					var d := Vector2(c.global_position.x - pos.x, c.global_position.z - pos.z)
					if d.length_squared() <= r2:
						out.append(c)
	return out


func nearest(pos: Vector3, radius: float, filter: Callable) -> Creature:
	var best: Creature = null
	var best_d := radius
	for c in near(pos, radius):
		var d := Fx.flat_dist(c.global_position, pos)
		if d < best_d and filter.call(c):
			best = c
			best_d = d
	return best


func nearest_corpse(pos: Vector3, radius: float, filter: Callable = Callable()) -> Corpse:
	var best: Corpse = null
	var best_d := radius
	for c in corpses:
		if not is_instance_valid(c):
			continue
		var d := Fx.flat_dist(c.global_position, pos)
		if d < best_d and (not filter.is_valid() or filter.call(c)):
			best = c
			best_d = d
	return best


func nearest_graze(pos: Vector3, radius: float) -> Variant:
	var best: Variant = null
	var best_d := radius
	for g in graze_spots:
		var d := Fx.flat_dist(g, pos)
		if d < best_d:
			best = g
			best_d = d
	return best


func count(kind: Script) -> int:
	var n := 0
	for c in creatures:
		if is_instance_valid(c) and not c.dead and c.get_script() == kind:
			n += 1
	return n
