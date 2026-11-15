class_name SilkMesh
extends RefCounted
## Peças de seda feitas em malha (mesmo visual das pontes de teia): tubos finos, fios que
## cedem, contas de orvalho e materiais. Usado pelas portas e pela decoração da toca.
## Cada "camada" acumula triângulos num SurfaceTool e vira um MeshInstance3D no fim.

const SILK := Color(0.85, 0.88, 0.95)
const GLOW := Color(0.55, 0.95, 1.0)
const OLD := Color(0.5, 0.5, 0.52)

var silk := SurfaceTool.new()     ## fios brancos
var glow := SurfaceTool.new()     ## fios ciano (território)
var veil := SurfaceTool.new()     ## véu transparente
var dew := SurfaceTool.new()      ## orvalho
var rng := RandomNumberGenerator.new()
var old := false                  ## teia abandonada: cinza, sem brilho
var _used := {}


func _init(seed_: int = 1, old_: bool = false) -> void:
	rng.seed = seed_
	old = old_
	for st in [silk, glow, veil, dew]:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)


func thread(pts: Array, r: float = 0.012, glowing: bool = false) -> void:
	var st := glow if glowing and not old else silk
	_used[st] = true
	tube(st, pts, r)


func sag(a: Vector3, b: Vector3, droop: float, n: int = 8) -> Array:
	## Fio esticado de a até b, cedendo no meio (droop em metros, para baixo).
	var pts: Array = []
	for i in n + 1:
		var t := float(i) / n
		pts.append(a.lerp(b, t) + Vector3.DOWN * droop * sin(PI * t))
	return pts


func veil_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	## a-b embaixo, d-c em cima (sentido não importa: o véu não tem frente).
	_used[veil] = true
	veil.add_vertex(a); veil.add_vertex(b); veil.add_vertex(c)
	veil.add_vertex(a); veil.add_vertex(c); veil.add_vertex(d)


func bead(c: Vector3, r: float = 0.03) -> void:
	if old:
		return
	_used[dew] = true
	var v := [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	var faces := [[0, 2, 4], [0, 4, 3], [0, 3, 5], [0, 5, 2], [1, 4, 2], [1, 3, 4], [1, 5, 3], [1, 2, 5]]
	for f in faces:
		for i in f:
			dew.add_vertex(c + (v[i] as Vector3) * r)


func commit(parent: Node3D, veil_alpha: float = 0.06) -> void:
	var col := OLD if old else SILK
	var mats := [
		[silk, Fx.mat(col, 0.15 if old else 0.6, true, 0.75 if old else 1.0), "Fios"],
		[glow, Fx.mat(GLOW, 1.4, true), "FiosCiano"],
		[veil, _veil_mat(col, veil_alpha * (0.6 if old else 1.0)), "Veu"],
		[dew, Fx.mat(Color(0.8, 0.95, 1.0), 1.6, true), "Orvalho"],
	]
	for m in mats:
		var st: SurfaceTool = m[0]
		if not _used.has(st):
			continue
		var mi := MeshInstance3D.new()
		mi.name = m[2]
		mi.mesh = st.commit()
		mi.material_override = m[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)


static func _veil_mat(col: Color, alpha: float) -> StandardMaterial3D:
	var m := Fx.mat(col, 0.4, true, alpha)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func tube(st: SurfaceTool, pts: Array, r: float) -> void:
	## Tubo de 4 lados ao longo dos pontos (fio fino que aparece de qualquer ângulo).
	var rings: Array = []
	for i in pts.size():
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var b: Vector3 = pts[mini(i + 1, pts.size() - 1)]
		var t := (b - a).normalized()
		var side := t.cross(Vector3.UP)
		if side.length() < 0.01:
			side = Vector3.RIGHT
		side = side.normalized()
		var up := side.cross(t).normalized()
		var ring: Array[Vector3] = []
		for s in 4:
			var ang := PI * 0.25 + s * PI * 0.5
			ring.append((pts[i] as Vector3) + (side * cos(ang) + up * sin(ang)) * r)
		rings.append(ring)
	for i in pts.size() - 1:
		var lo: Array = rings[i]
		var hi: Array = rings[i + 1]
		for s in 4:
			var s2 := (s + 1) % 4
			st.add_vertex(lo[s]); st.add_vertex(hi[s]); st.add_vertex(lo[s2])
			st.add_vertex(lo[s2]); st.add_vertex(hi[s]); st.add_vertex(hi[s2])
