class_name Anthill
extends Node3D
## Formigueiro: monte de terra que solta uma fila de Formigas-de-seda e repõe as mortas
## devagar (só quando você está longe, para não virar fábrica no meio da luta).
## As formigas passeiam pelas câmaras de `rooms`, dormem no monte no Brilho e roem fios-guia.

const RESPAWN := 70.0

var count := 7
var rooms: Array = []
var flag_id := ""                ## (reservado) formigueiro destruído no save
var _ants: Array = []
var _t := RESPAWN


func _init(count_: int = 7, rooms_: Array = []) -> void:
	count = count_
	rooms = rooms_


func _ready() -> void:
	add_to_group("nest")
	var dirt := Fx.mat(Color(0.3, 0.22, 0.16))
	var mound := Fx.cylinder(1.6, 0.9, dirt)
	(mound.mesh as CylinderMesh).top_radius = 0.35
	mound.position.y = 0.45
	add_child(mound)
	var hole_mat := Fx.mat(Color(0.03, 0.02, 0.02))
	for k in 3:
		var hole := Fx.sphere(0.18, hole_mat)
		var ang := k * TAU / 3.0 + 0.4
		hole.position = Vector3(cos(ang) * 0.75, 0.45, sin(ang) * 0.75)
		hole.scale = Vector3(1.0, 0.6, 1.0)
		add_child(hole)
	for k in 10:
		var grain := Fx.sphere(randf_range(0.06, 0.14), dirt)
		var ang := randf() * TAU
		var r := randf_range(1.5, 2.4)
		grain.position = Vector3(cos(ang) * r, 0.04, sin(ang) * r)
		add_child(grain)
	_spawn_all.call_deferred()


func _spawn_all() -> void:
	var prev: Ant = null
	for i in count:
		prev = _spawn(prev, i)


func _spawn(prev: Ant, i: int) -> Ant:
	var a := Ant.new()
	var ang := i * 0.9
	a.position = global_position + Vector3(cos(ang) * 1.9, 0.3, sin(ang) * 1.9)
	a.den = global_position + Vector3(cos(ang) * 1.9, 0.0, sin(ang) * 1.9)
	a.ahead = prev
	a.nest = self
	a.range_rooms = rooms
	get_parent().add_child(a)
	_ants.append(a)
	return a


func living() -> Array:
	return _ants.filter(func(a): return is_instance_valid(a) and not a.dead)


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = RESPAWN
	var alive := living()
	_ants = alive
	if alive.size() >= count:
		return
	var p := GameState.player as Player
	if p != null and Fx.flat_dist(p.global_position, global_position) < 22.0:
		return
	var last: Ant = alive.back() if not alive.is_empty() else null
	_spawn(last, alive.size())
