class_name Ecosystem
extends Node3D
## Mantém a população da câmara: repõe larvas com o tempo e repõe tudo quando a jogadora descansa.

const LARVA_RESPAWN_INTERVAL := 40.0
const LARVA_TARGET := 8
const FROG_TARGET := 2
const MIN_SPAWN_DISTANCE := 14.0

var larva_spawns: Array[Vector3] = []
var frog_spawns: Array[Vector3] = []
var _timer := LARVA_RESPAWN_INTERVAL


func _ready() -> void:
	EventBus.rested.connect(_on_rested)


func spawn_initial() -> void:
	for p in larva_spawns:
		spawn_larva(p)
	for p in frog_spawns:
		spawn_frog(p)


func spawn_larva(pos: Vector3) -> Larva:
	var l := Larva.new()
	l.position = pos + Vector3(randf_range(-1.0, 1.0), 0.3, randf_range(-1.0, 1.0))
	add_child(l)
	return l


func spawn_frog(pos: Vector3) -> Frog:
	var f := Frog.new()
	f.position = pos + Vector3(0.0, 0.3, 0.0)
	add_child(f)
	return f


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = LARVA_RESPAWN_INTERVAL
		_top_up(LARVA_TARGET, 0, 1)


func _on_rested(_c: Node) -> void:
	# O tempo passou: a caverna se repovoa.
	_top_up(LARVA_TARGET, FROG_TARGET, 99)


func _top_up(larva_target: int, frog_target: int, max_spawns: int) -> void:
	var larvae := 0
	var frogs := 0
	for n in get_children():
		if n is Larva and not (n as Larva).dead:
			larvae += 1
		elif n is Frog and not (n as Frog).dead:
			frogs += 1
	var spawned := 0
	while larvae < larva_target and spawned < max_spawns:
		var p = _far_point(larva_spawns)
		if p == null:
			break
		spawn_larva(p)
		larvae += 1
		spawned += 1
	while frogs < frog_target:
		var p = _far_point(frog_spawns)
		if p == null:
			break
		spawn_frog(p)
		frogs += 1


func _far_point(points: Array[Vector3]) -> Variant:
	var player = GameState.player
	var options: Array[Vector3] = []
	for p in points:
		if player == null or Fx.flat_dist(p, player.global_position) >= MIN_SPAWN_DISTANCE:
			options.append(p)
	if options.is_empty():
		return null
	return options.pick_random()
