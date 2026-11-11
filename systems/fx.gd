class_name Fx
extends RefCounted
## Utilidades para montar a geometria cinza do protótipo por código.
## Quando os modelos 3D chegarem, só os métodos _build_visual() de cada ator mudam.


static func mat(color: Color, emission: float = 0.0, unshaded: bool = false, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.roughness = 0.85
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


static func box(size: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = material
	return mi


static func sphere(radius: float, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = material
	return mi


static func cylinder(radius: float, height: float, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 16
	mi.mesh = cm
	mi.material_override = material
	return mi


static func orient_between(node: Node3D, a: Vector3, b: Vector3) -> void:
	## Coloca o nó no meio de a-b com o eixo Z local apontando de a para b.
	## Usa coordenadas locais: o pai precisa estar na origem (ou o nó ser top_level).
	var d := b - a
	node.position = (a + b) * 0.5
	if d.length() > 0.001:
		var up := Vector3.UP
		if absf(d.normalized().dot(up)) > 0.99:
			up = Vector3.RIGHT
		node.basis = Basis.looking_at(d, up)


static func beam(parent: Node, a: Vector3, b: Vector3, color: Color, life: float = 0.25, width: float = 0.06) -> MeshInstance3D:
	## Linha temporária (fio lançado, língua do sapo, golpe).
	var mi := box(Vector3(width, width, maxf(a.distance_to(b), 0.01)), mat(color, 2.0, true))
	parent.add_child(mi)
	orient_between(mi, a, b)
	if life > 0.0:
		parent.get_tree().create_timer(life, true, false, true).timeout.connect(mi.queue_free)
	return mi


static func flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
