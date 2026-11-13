class_name SilkLine
extends MeshInstance3D
## O fio do Q, desenhado a cada quadro entre a boca da aranha e o alvo.
##   1. voa: a ponta sai da aranha e corre até o alvo, ondulando;
##   2. preso: estica (a onda morre) e acompanha a aranha / o bicho puxado;
##   3. solto: recolhe para o lado do alvo e some.
## As pontas vêm de funções (from_fn / to_fn), então o fio nunca fica parado no ar
## enquanto a aranha passa por ele.

signal arrived

const SPEED := 55.0
const WIDTH := 0.035
const SEG := 18

var from_fn: Callable
var to_fn: Callable
var color := Color(0.92, 0.95, 1.0)
var _im := ImmediateMesh.new()
var _mat: StandardMaterial3D
var _shot := 0.0
var _hit := false
var _t := 0.0
var _hold_t := 0.0
var _fade := -1.0
var _droop := false   ## errou o alvo: o fio cai ao recolher


static func shoot(parent: Node, from: Callable, to: Callable) -> SilkLine:
	var s := SilkLine.new()
	s.from_fn = from
	s.to_fn = to
	parent.add_child(s)
	return s


func _ready() -> void:
	top_level = true
	mesh = _im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.vertex_color_use_as_albedo = true
	material_override = _mat
	global_transform = Transform3D.IDENTITY


func attached() -> bool:
	return _hit


func release(droop := false) -> void:
	if _fade < 0.0:
		_fade = 0.0
		_droop = droop


func _process(delta: float) -> void:
	_t += delta
	if not from_fn.is_valid() or not to_fn.is_valid():
		release()
	var a: Vector3 = from_fn.call() if from_fn.is_valid() else global_position
	var b: Vector3 = to_fn.call() if to_fn.is_valid() else a
	var L := a.distance_to(b)
	var tip := b
	var amp := 0.0
	if not _hit:
		_shot += SPEED * delta
		var k := clampf(_shot / maxf(L, 0.01), 0.0, 1.0)
		tip = a.lerp(b, k)
		amp = 0.12 * (1.0 - k)
		if k >= 1.0:
			_hit = true
			arrived.emit()
	else:
		_hold_t += delta
		amp = 0.1 * exp(-_hold_t * 9.0)   # o tranco do fio esticando
	var alpha := 1.0
	var start := a
	if _fade >= 0.0:
		_fade += delta
		var f := clampf(_fade / 0.28, 0.0, 1.0)
		alpha = 1.0 - f
		start = a.lerp(tip, f)          # recolhe para o lado do alvo
		if _droop:
			start += Vector3.DOWN * f * 0.6
			tip += Vector3.DOWN * f * 0.6
		if f >= 1.0:
			queue_free()
			return
	_draw(start, tip, amp, alpha)


func _draw(a: Vector3, b: Vector3, amp: float, alpha: float) -> void:
	_im.clear_surfaces()
	var d := b - a
	var L := d.length()
	if L < 0.05:
		return
	var f := d / L
	var side := f.cross(Vector3.UP)
	if side.length() < 0.01:
		side = Vector3.RIGHT
	side = side.normalized()
	var up := side.cross(f).normalized()
	var sag := minf(0.12, L * 0.012) * (1.0 if _hit else 0.4)
	var pts: Array[Vector3] = []
	for i in SEG + 1:
		var u := float(i) / SEG
		var env := sin(PI * u)
		var w := sin(u * PI * 3.0 - _t * 34.0) * amp * env
		pts.append(a + d * u + side * w + up * w * 0.5 + Vector3.DOWN * sag * env)
	var col := Color(color.r, color.g, color.b, 0.95 * alpha)
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# duas fitas cruzadas: aparece de cima (câmera do jogo) e de lado
	for axis in [side, up]:
		var o: Vector3 = axis * WIDTH * 0.5
		for i in SEG:
			var p0 := pts[i]
			var p1 := pts[i + 1]
			for v in [p0 - o, p0 + o, p1 + o, p0 - o, p1 + o, p1 - o]:
				_im.surface_set_color(col)
				_im.surface_add_vertex(v)
	_im.surface_end()
