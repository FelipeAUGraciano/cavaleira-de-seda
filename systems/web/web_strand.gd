class_name WebStrand
extends StaticBody3D
## Fio-guia: ponte andável entre duas âncoras.
## Só a jogadora colide com ele (camada "fio"), então criaturas não atravessam abismos por fios.

const WIDTH := 1.1

var anchor_a := ""
var anchor_b := ""
var a_pos := Vector3.ZERO
var b_pos := Vector3.ZERO
var in_territory := false
var _mat: StandardMaterial3D


func setup(a: Node3D, b: Node3D) -> void:
	anchor_a = String(a.name)
	anchor_b = String(b.name)
	a_pos = Vector3(a.global_position.x, 0.0, a.global_position.z)
	b_pos = Vector3(b.global_position.x, 0.0, b.global_position.z)


func _ready() -> void:
	add_to_group("strand")
	collision_layer = 8
	collision_mask = 0
	var dir := b_pos - a_pos
	var length := dir.length()
	position = (a_pos + b_pos) * 0.5
	rotation.y = atan2(dir.x, dir.z)

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(WIDTH, 0.1, length)
	cs.shape = shape
	cs.position.y = -0.03
	add_child(cs)

	_mat = Fx.mat(Color(0.85, 0.88, 0.95), 0.6, true)
	for x in [-0.3, 0.0, 0.3]:
		var w := 0.05 if x == 0.0 else 0.03
		var line := Fx.box(Vector3(w, 0.03, length), _mat)
		line.position = Vector3(x, 0.05, 0.0)
		add_child(line)
	var n := int(length / 0.8)
	for i in range(n):
		var cross := Fx.box(Vector3(0.62, 0.02, 0.02), _mat)
		cross.position = Vector3(0.0, 0.05, -length * 0.5 + (i + 0.5) * length / n)
		add_child(cross)
	set_in_territory(in_territory)


func set_in_territory(on: bool) -> void:
	in_territory = on
	if _mat == null:
		return
	var c := Color(0.55, 0.95, 1.0) if on else Color(0.85, 0.88, 0.95)
	_mat.albedo_color = c
	_mat.emission = c
	_mat.emission_energy_multiplier = 1.4 if on else 0.6


func connects(a_name: String, b_name: String) -> bool:
	return (anchor_a == a_name and anchor_b == b_name) or (anchor_a == b_name and anchor_b == a_name)


func distance_to(p: Vector3) -> float:
	## Distância no plano XZ entre um ponto e o segmento do fio.
	var a := Vector2(a_pos.x, a_pos.z)
	var b := Vector2(b_pos.x, b_pos.z)
	var q := Vector2(p.x, p.z)
	var ab := b - a
	var t := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return q.distance_to(a + ab * t)
