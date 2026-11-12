class_name MapSystem
extends Node
## Mapa automático da camada: revela cada câmara quando a jogadora entra nela,
## lembra as travas que ela já viu e avisa quando ela muda de câmara.

signal room_entered(room: Dictionary)

const LOCK_SIGHT := 10.0

var layer_name := ""
var rooms: Array = []        ## [{id, name, rect: Rect2, ...}]
var tunnels: Array = []      ## [Rect2]
var locks: Array = []        ## [{type, pos: Vector3, seen: bool}]
var grid: Dictionary = {}   ## modo orgânico: {origin, w, h, ids, runs, bounds}; vazio = modo retângulos
var revealed: Dictionary = {}
var current_room := ""
var _timer := 0.0


func setup(name_: String, rooms_: Array, tunnels_: Array, locks_: Array) -> void:
	layer_name = name_
	rooms = rooms_
	tunnels = tunnels_
	locks = []
	for l in locks_:
		locks.append({"type": l["type"], "pos": l["pos"], "seen": false})


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.2
	var p = GameState.player
	if p == null or not is_instance_valid(p):
		return
	var pos: Vector3 = p.global_position
	var here := room_at(pos)
	if not here.is_empty() and String(here["id"]) != current_room:
		current_room = String(here["id"])
		revealed[current_room] = true
		room_entered.emit(here)
	for l in locks:
		if not l["seen"] and Fx.flat_dist(l["pos"], pos) <= LOCK_SIGHT:
			l["seen"] = true


func set_grid(g: Dictionary) -> void:
	grid = g


func room_at(pos: Vector3) -> Dictionary:
	if not grid.is_empty():
		var o: Vector2 = grid["origin"]
		var i := int(floor(pos.x - o.x))
		var j := int(floor(pos.z - o.y))
		if i < 0 or j < 0 or i >= int(grid["w"]) or j >= int(grid["h"]):
			return {}
		var idx: int = grid["ids"][j * int(grid["w"]) + i]
		return rooms[idx] if idx >= 0 else {}
	for r in rooms:
		var rect: Rect2 = r["rect"]
		if rect.has_point(Vector2(pos.x, pos.z)):
			return r
	return {}


func is_tunnel_revealed(t: Rect2) -> bool:
	var grown := t.grow(1.5)
	for r in rooms:
		if revealed.has(r["id"]) and grown.intersects(r["rect"]):
			return true
	return false


func floor_of_room(r: Dictionary) -> int:
	return int(r.get("floor", 0))


func current_floor() -> int:
	for r in rooms:
		if String(r["id"]) == current_room:
			return floor_of_room(r)
	return 0


func floor_bounds(f: int) -> Rect2:
	## Retângulo das câmaras de um andar (o mapa cheio mostra um andar por vez).
	var b := Rect2()
	var first := true
	for r in rooms:
		if floor_of_room(r) != f:
			continue
		var rects: Array = grid["runs"].get(r["id"], []) if not grid.is_empty() else [r["rect"]]
		for rr in rects:
			if first:
				b = rr
				first = false
			else:
				b = b.merge(rr)
	return b if not first else bounds()


func bounds() -> Rect2:
	if not grid.is_empty():
		return grid["bounds"]
	var b := Rect2()
	var first := true
	for r in rooms:
		if first:
			b = r["rect"]
			first = false
		else:
			b = b.merge(r["rect"])
	for t in tunnels:
		b = b.merge(t)
	return b


func to_dict() -> Dictionary:
	var seen := []
	for i in locks.size():
		if locks[i]["seen"]:
			seen.append(i)
	return {"revealed": revealed.keys(), "locks_seen": seen}


func from_dict(d: Dictionary) -> void:
	for id in d.get("revealed", []):
		revealed[String(id)] = true
	for i in d.get("locks_seen", []):
		var idx := int(i)
		if idx >= 0 and idx < locks.size():
			locks[idx]["seen"] = true
