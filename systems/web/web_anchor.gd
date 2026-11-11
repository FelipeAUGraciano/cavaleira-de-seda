class_name WebAnchor
extends StaticBody3D
## Pilar ou estalagmite onde fios podem ser presos.

var height := 4.0
var radius := 0.5
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D


func _init(h: float = 4.0, r: float = 0.5) -> void:
	height = h
	radius = r


func _ready() -> void:
	add_to_group("anchor")
	collision_layer = 1
	collision_mask = 0
	var mesh := Fx.cylinder(radius, height, Fx.mat(Color(0.42, 0.42, 0.47)))
	mesh.position.y = height * 0.5
	add_child(mesh)
	var cap := Fx.sphere(radius * 0.9, Fx.mat(Color(0.5, 0.5, 0.55)))
	cap.position.y = height
	add_child(cap)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	cs.shape = shape
	cs.position.y = height * 0.5
	add_child(cs)
	_ring_mat = Fx.mat(Color(0.4, 0.9, 1.0), 2.0, true, 0.85)
	_ring = Fx.cylinder(radius + 0.3, 0.05, _ring_mat)
	_ring.position.y = 0.06
	_ring.visible = false
	add_child(_ring)


func set_highlight(mode: int) -> void:
	## 0 = nada, 1 = disponível, 2 = selecionado (ponto A), 3 = sob o cursor
	_ring.visible = mode > 0
	var c := Color(0.4, 0.9, 1.0)
	if mode == 2:
		c = Color(1.0, 0.82, 0.3)
	elif mode == 3:
		c = Color(1.0, 1.0, 1.0)
	_ring_mat.albedo_color = Color(c.r, c.g, c.b, 0.85)
	_ring_mat.emission = c
	_ring.scale = Vector3.ONE * (1.35 if mode >= 2 else 1.0)
