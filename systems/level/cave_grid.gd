class_name CaveGrid
extends RefCounted
## Monta o chão e as paredes de uma camada a partir de retângulos (câmaras e túneis) numa grade de 1 m.
## As paredes nascem sozinhas em volta de qualquer chão; abismos são buracos sem parede.
## As paredes logo ao sul de um chão são baixas, para não esconder a jogadora da câmera.

const EMPTY := 0
const FLOOR := 1
const CHASM := 2

const WALL_H := 3.0
const LOW_WALL_H := 0.7

enum Cell { NONE, FLOOR, CHASM, WALL, LOW_WALL }

var min_x := 0
var min_z := 0
var w := 0
var h := 0
var cells := PackedByteArray()


func _init(bounds: Rect2i) -> void:
	min_x = bounds.position.x - 2
	min_z = bounds.position.y - 2
	w = bounds.size.x + 4
	h = bounds.size.y + 4
	cells.resize(w * h)
	cells.fill(EMPTY)


func paint(rect: Rect2, value: int) -> void:
	## rect em metros no plano XZ: position = (x, z), size = (largura, profundidade).
	var x0 := int(floor(rect.position.x))
	var z0 := int(floor(rect.position.y))
	var x1 := int(ceil(rect.position.x + rect.size.x))
	var z1 := int(ceil(rect.position.y + rect.size.y))
	for z in range(z0, z1):
		for x in range(x0, x1):
			var i := _index(x, z)
			if i >= 0:
				cells[i] = value


func get_cell(x: int, z: int) -> int:
	var i := _index(x, z)
	if i < 0:
		return EMPTY
	return cells[i]


func is_open(x: int, z: int) -> bool:
	var c := get_cell(x, z)
	return c == FLOOR or c == CHASM


func _index(x: int, z: int) -> int:
	var lx := x - min_x
	var lz := z - min_z
	if lx < 0 or lz < 0 or lx >= w or lz >= h:
		return -1
	return lz * w + lx


func _classify(x: int, z: int) -> Cell:
	var c := get_cell(x, z)
	if c == FLOOR:
		return Cell.FLOOR
	if c == CHASM:
		return Cell.CHASM
	var near := false
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if (dx != 0 or dz != 0) and is_open(x + dx, z + dz):
				near = true
	if not near:
		return Cell.NONE
	if is_open(x, z - 1) or is_open(x - 1, z - 1) or is_open(x + 1, z - 1):
		return Cell.LOW_WALL
	return Cell.WALL


func build(parent: Node3D, floor_color: Color, wall_color: Color) -> void:
	var floor_mat := Fx.mat(floor_color)
	var wall_mat := Fx.mat(wall_color)
	var low_mat := Fx.mat(wall_color.lightened(0.08))
	var pit_mat := Fx.mat(Color(0.02, 0.02, 0.03))
	for row in h:
		var z := min_z + row
		var x := min_x
		while x < min_x + w:
			var kind := _classify(x, z)
			if kind == Cell.NONE:
				x += 1
				continue
			var start := x
			while x < min_x + w and _classify(x, z) == kind:
				x += 1
			var length := float(x - start)
			var cx := start + length * 0.5
			var cz := z + 0.5
			match kind:
				Cell.FLOOR:
					_solid(parent, Vector3(length, 1.0, 1.0), Vector3(cx, -0.5, cz), floor_mat)
				Cell.CHASM:
					var pit := Fx.box(Vector3(length, 0.2, 1.0), pit_mat)
					pit.position = Vector3(cx, -9.0, cz)
					parent.add_child(pit)
				Cell.WALL:
					_solid(parent, Vector3(length, WALL_H, 1.0), Vector3(cx, WALL_H * 0.5, cz), wall_mat)
				Cell.LOW_WALL:
					_solid(parent, Vector3(length, LOW_WALL_H, 1.0), Vector3(cx, LOW_WALL_H * 0.5, cz), low_mat)


func _solid(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	body.add_child(Fx.box(size, material))
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)
