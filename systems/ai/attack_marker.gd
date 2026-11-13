class_name AttackMarker
extends MeshInstance3D
## Marca no chão mostrando a área de um golpe durante o aviso. A parte escura é a área
## inteira; a clara cresce até cobrir tudo no instante do golpe.

const Y := 0.07
const SEGMENTS := 20

var _im := ImmediateMesh.new()
var _mat: StandardMaterial3D


func _ready() -> void:
	top_level = true
	mesh = _im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.no_depth_test = false
	material_override = _mat
	visible = false


func clear() -> void:
	_im.clear_surfaces()
	visible = false


func draw_attack(a: Attack, origin: Vector3, facing: Vector3, point: Vector3, fill: float, enraged: bool) -> void:
	var base := Color(1.0, 0.25, 0.1, 0.16) if enraged else Color(1.0, 0.55, 0.1, 0.14)
	var hot := Color(1.0, 0.2, 0.1, 0.4) if enraged else Color(1.0, 0.6, 0.15, 0.36)
	draw_shape(a, origin, facing, point, fill, base, hot)


func draw_shape(a: Attack, origin: Vector3, facing: Vector3, point: Vector3, fill: float, base: Color, hot: Color) -> void:
	## Mesma marca com cores próprias (a jogadora usa azul; a mordida, verde de veneno).
	_im.clear_surfaces()
	visible = true
	global_transform = Transform3D.IDENTITY
	fill = clampf(fill, 0.0, 1.0)
	var o := Vector3(origin.x, Y, origin.z)
	var f := Vector3(facing.x, 0.0, facing.z)
	f = f.normalized() if f.length() > 0.01 else Vector3(0, 0, -1)
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	match a.shape:
		Attack.Shape.CIRCLE:
			var c := Vector3(point.x, Y, point.z) if (a.leap or a.at_point) else o
			_sector(c, f, a.reach, 360.0, base)
			_sector(c, f, a.reach * fill, 360.0, hot)
		Attack.Shape.RING:
			_sector(o, f, a.reach, 360.0, base)
			_sector(o, f, a.reach * fill, 360.0, hot)
		Attack.Shape.LINE:
			_rect(o, f, a.reach, a.width, base)
			_rect(o, f, a.reach * fill, a.width, hot)
		_:
			_sector(o, f, a.reach, a.arc, base)
			_sector(o, f, a.reach * fill, a.arc, hot)
	_im.surface_end()


func _sector(c: Vector3, f: Vector3, r: float, arc_deg: float, col: Color) -> void:
	if r <= 0.01:
		return
	var half := deg_to_rad(arc_deg) * 0.5
	var n := maxi(4, int(SEGMENTS * arc_deg / 180.0))
	for i in n:
		var a0 := -half + (2.0 * half) * float(i) / n
		var a1 := -half + (2.0 * half) * float(i + 1) / n
		_tri(c, c + f.rotated(Vector3.UP, a0) * r, c + f.rotated(Vector3.UP, a1) * r, col)


func _rect(o: Vector3, f: Vector3, length: float, w: float, col: Color) -> void:
	if length <= 0.01:
		return
	var side := Vector3(-f.z, 0.0, f.x) * w * 0.5
	var a := o + side
	var b := o - side
	var c := o - side + f * length
	var d := o + side + f * length
	_tri(a, b, c, col)
	_tri(a, c, d, col)


func _tri(a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	for v in [a, b, c]:
		_im.surface_set_color(col)
		_im.surface_add_vertex(v)
