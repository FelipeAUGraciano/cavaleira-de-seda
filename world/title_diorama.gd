class_name TitleDiorama
extends Node3D
## O fundo do menu inicial: um salão da caverna de verdade, em 3D.
## A Cavaleira parada na frente de uma teia grande esticada entre dois pilares,
## fungos acesos em volta, ovos e um casulo pendurado; a runa das costas pulsa
## e a câmera dá a volta devagar, baixinha, como quem chega de mansinho.

const SILK_COL := Color(0.72, 0.8, 1.0)
const RUNE_COL := Color(0.4, 0.85, 1.0)
const WEB_C := Vector3(0.0, 3.3, 4.6)       ## centro da teia grande
const LOOK := Vector3(0.0, 1.0, 0.9)       ## para onde a câmera olha

var camera: Camera3D
var cavaleira: Node3D
var _body: Node3D
var _rune_light: OmniLight3D
var _glows: Array = []      ## [luz, energia base, fase]: fungos e cristais respirando
var _blades: Array = []     ## [pivô, rotação de descanso]
var _cocoon: Node3D
var _dew: Array = []        ## gotas de orvalho na teia (piscam)
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 2611
	_environment()
	_ground()
	_pillars_and_web()
	_cavaleira()
	_props()
	_dust()
	camera = Camera3D.new()
	camera.fov = 46.0
	camera.h_offset = -1.15   # a Cavaleira fica no terço direito; o menu ocupa a esquerda
	camera.near = 0.05
	add_child(camera)
	camera.current = true
	_place_camera()


func _process(delta: float) -> void:
	_t += delta
	_place_camera()
	# a runa das costas acende e apaga devagar (respiração)
	var p := 0.5 + 0.5 * sin(_t * 1.25)
	if _rune_light:
		_rune_light.light_energy = 1.1 + 1.5 * p
	# corpo: sobe e desce com a respiração e olha em volta de vez em quando
	if _body:
		_body.position.y = 0.04 * sin(_t * 1.25)
		_body.rotation.x = 0.03 * sin(_t * 1.25 + 0.6)
	if cavaleira:
		var look := sin(_t * 0.23) * 0.22 + sin(_t * 0.61) * 0.06
		cavaleira.rotation.y = 0.2 + look
	for i in _blades.size():
		var pv: Node3D = _blades[i][0]
		var rest: Vector3 = _blades[i][1]
		pv.rotation = rest + Vector3(0.06 * sin(_t * 1.25 + i * 1.7), 0.0, 0.03 * sin(_t * 0.8 + i))
	for g in _glows:
		var l: OmniLight3D = g[0]
		l.light_energy = float(g[1]) * (0.75 + 0.25 * sin(_t * 0.9 + float(g[2])))
	if _cocoon:
		_cocoon.rotation.z = 0.06 * sin(_t * 0.7)
		_cocoon.rotation.y += delta * 0.15
	for k in _dew.size():
		var d: MeshInstance3D = _dew[k]
		d.scale = Vector3.ONE * (0.6 + 0.6 * maxf(0.0, sin(_t * 1.7 + k * 2.3)))


func _place_camera() -> void:
	## Arco lento na frente da Cavaleira, baixo, olhando um pouco para cima.
	var a := -0.35 + 0.38 * sin(_t * 0.07)
	var dist := 6.2 + 0.25 * sin(_t * 0.11)
	var pos := LOOK + Vector3(sin(a) * dist, 0.55 + 0.12 * sin(_t * 0.13), -cos(a) * dist)
	camera.position = pos
	camera.look_at(LOOK + Vector3(0, 0.55, 0), Vector3.UP)


# ------------------------------------------------------------ montagem

func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.014, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.26, 0.45)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.07, 0.14)
	env.fog_density = 0.045
	env.adjustment_enabled = true
	env.adjustment_brightness = Settings.brightness
	env.adjustment_saturation = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()   # luz fria de cima: recorta as costas e a teia
	moon.light_color = Color(0.55, 0.62, 0.9)
	moon.light_energy = 0.35
	moon.rotation_degrees = Vector3(-55.0, 160.0, 0.0)
	moon.shadow_enabled = true
	add_child(moon)
	var key := SpotLight3D.new()           # luz quente vinda da frente-esquerda (da tocha do menu)
	key.light_color = Color(1.0, 0.78, 0.5)
	key.light_energy = 2.2
	key.spot_range = 12.0
	key.spot_angle = 34.0
	key.position = Vector3(-3.2, 4.0, -3.8)
	add_child(key)
	key.look_at_from_position(key.position, Vector3(0.0, 0.5, 0.6))
	key.shadow_enabled = true


func _ground() -> void:
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	floor_mi.mesh = pm
	var fm := Fx.mat(Color(0.09, 0.09, 0.13))
	fm.roughness = 1.0
	floor_mi.material_override = fm
	add_child(floor_mi)
	# pedras espalhadas: esferas achatadas, mais densas longe do centro
	var rock := Fx.mat(Color(0.12, 0.12, 0.17))
	for i in 46:
		var ang := _rng.randf() * TAU
		var r := _rng.randf_range(3.2, 14.0)
		var p := Vector3(cos(ang) * r, 0.0, sin(ang) * r + 2.0)
		if p.z < -2.0 and absf(p.x) < 4.0:
			continue   # deixa a frente da câmera livre
		var s := _rng.randf_range(0.25, 1.1) * (1.0 + r * 0.06)
		var b := Fx.sphere(s, rock)
		b.position = p + Vector3(0, s * 0.2, 0)
		b.scale = Vector3(_rng.randf_range(0.9, 1.6), _rng.randf_range(0.45, 0.8), _rng.randf_range(0.9, 1.5))
		b.rotation.y = _rng.randf() * TAU
		add_child(b)
	# estalactites no teto
	for i in 22:
		var c := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var h := _rng.randf_range(1.2, 3.4)
		cm.top_radius = _rng.randf_range(0.25, 0.6)
		cm.bottom_radius = 0.02
		cm.height = h
		cm.radial_segments = 8
		c.mesh = cm
		c.material_override = rock
		c.position = Vector3(_rng.randf_range(-9, 9), 8.2 - h * 0.5, _rng.randf_range(1.0, 10.0))
		add_child(c)


func _strand(a: Vector3, b: Vector3, mat: Material, w := 0.013) -> MeshInstance3D:
	var mi := Fx.box(Vector3(w, w, maxf(a.distance_to(b), 0.01)), mat)
	add_child(mi)
	Fx.orient_between(mi, a, b)
	return mi


func _pillars_and_web() -> void:
	var anchors := [Vector3(-3.9, 0.0, 5.0), Vector3(3.7, 0.0, 5.3), Vector3(-6.6, 0.0, 9.5), Vector3(6.4, 0.0, 9.0)]
	for i in anchors.size():
		var p: Vector3 = anchors[i]
		var h := 7.5 if i < 2 else 6.0
		var m := Models.instance("pilar_teia", h, "height")
		if m == null:
			m = Fx.cylinder(0.5, h, Fx.mat(Color(0.3, 0.3, 0.36)))
			m.position.y = h * 0.5
		m.position += p
		m.rotation.y = _rng.randf() * TAU
		add_child(m)
	var silk := Fx.mat(SILK_COL, 0.45, true, 0.5)
	var silk_soft := Fx.mat(SILK_COL, 0.3, true, 0.22)
	# raios da teia grande: do centro até os pilares, o chão e o teto
	var ends := [
		Vector3(-3.6, 5.9, 4.95), Vector3(-3.6, 3.6, 4.95), Vector3(-3.6, 1.2, 4.95),
		Vector3(-1.8, 0.0, 4.75), Vector3(1.4, 0.0, 4.8),
		Vector3(3.4, 1.0, 5.2), Vector3(3.4, 3.4, 5.2), Vector3(3.4, 6.0, 5.2),
		Vector3(1.2, 8.0, 4.7), Vector3(-1.3, 8.0, 4.6),
	]
	var rays: Array = []
	for e in ends:
		_strand(WEB_C, e, silk)
		rays.append(e)
	# espiral: anéis ligando os raios, mais densos no meio
	for ring in 9:
		var k := 0.12 + ring * 0.095
		for i in rays.size():
			var a: Vector3 = WEB_C.lerp(rays[i], k + 0.012 * i)
			var b: Vector3 = WEB_C.lerp(rays[(i + 1) % rays.size()], k + 0.012 * (i + 1))
			_strand(a, b, silk if ring % 2 == 0 else silk_soft, 0.009)
	# gotas de orvalho
	var dew_mat := Fx.mat(RUNE_COL, 4.0, true)
	for i in 14:
		var r: Vector3 = rays[_rng.randi() % rays.size()]
		var d := Fx.sphere(0.035, dew_mat)
		d.position = WEB_C.lerp(r, _rng.randf_range(0.2, 0.9))
		add_child(d)
		_dew.append(d)
	# fios soltos entre os pilares do fundo e caindo do teto
	_strand(Vector3(-3.6, 6.6, 5.0), Vector3(-6.3, 5.0, 9.4), silk_soft)
	_strand(Vector3(3.4, 6.4, 5.3), Vector3(6.1, 4.6, 9.0), silk_soft)
	_strand(Vector3(-6.3, 3.0, 9.4), Vector3(6.1, 3.6, 9.0), silk_soft, 0.012)
	for x in [-2.6, 2.2, 4.8]:
		_strand(Vector3(x, 8.2, 3.0 + absf(x)), Vector3(x + 0.1, 3.0 + absf(x) * 0.3, 3.0 + absf(x)), silk_soft, 0.01)
	# fio da Cavaleira: das costas até a teia (ela acabou de descer dali)
	_strand(Vector3(0.0, 1.1, 0.9), WEB_C + Vector3(0.0, -0.4, 0.0), silk, 0.014)


func _cavaleira() -> void:
	cavaleira = Node3D.new()
	cavaleira.name = "Cavaleira"
	cavaleira.position = Vector3(0.0, 0.0, 0.4)
	add_child(cavaleira)
	_body = Node3D.new()
	cavaleira.add_child(_body)
	var hips: Array = []
	var m := Models.swap(_body, "cavaleira_corpo", 1.4, [], "length")
	if m != null:
		m.position.y = 0.15
		for side in ["L", "R"]:
			for k in range(1, 5):
				var t = Models.node_xform(m, "leg_socket_%s%d" % [side, k])
				if t != null:
					hips.append(m.transform * (t as Transform3D).origin)
		if hips.size() != 8:
			hips.clear()
		elif (hips[0] as Vector3).x > 0.0:
			hips = hips.slice(4, 8) + hips.slice(0, 4)
	else:
		var mat := Fx.mat(Color(0.16, 0.14, 0.38))
		var head := Fx.sphere(0.32, mat)
		head.position = Vector3(0.0, 0.45, -0.18)
		_body.add_child(head)
		var abd := Fx.sphere(0.42, mat)
		abd.position = Vector3(0.0, 0.55, 0.45)
		_body.add_child(abd)
	# a runa: disco aceso nas costas e a luz dela
	_rune_light = OmniLight3D.new()
	_rune_light.light_color = RUNE_COL
	_rune_light.omni_range = 5.5
	_rune_light.omni_attenuation = 0.8
	_rune_light.position = Vector3(0.0, 1.5, 0.3)
	_rune_light.shadow_enabled = true
	_body.add_child(_rune_light)
	_build_blades(hips)
	var legs := SpiderLegs.new()
	legs.setup(_body, 1.0, 1)
	legs.root = cavaleira
	legs.hip_points = hips
	legs.segment_model = "cavaleira_pata"
	cavaleira.add_child(legs)


func _build_blades(hips: Array) -> void:
	## As duas lâminas de cristal levantadas, prontas (como no jogo, um pouco mais altas).
	if not Models.has("cavaleira_lamina"):
		return
	for side in [-1.0, 1.0]:
		var m := Models.raw("cavaleira_lamina")
		var attach = Models.node_xform(m, "attach_point")
		var at := Vector3(0.0, 0.17, 0.0) if attach == null else (attach as Transform3D).origin
		var pivot := Node3D.new()
		var spin := Node3D.new()
		spin.rotation.y = PI * 0.5
		pivot.add_child(spin)
		m.scale = Vector3.ONE * 1.7
		m.position = -at * 1.7
		spin.add_child(m)
		var hip := Vector3(0.2 * side, 0.3, -0.5)
		if hips.size() == 8:
			hip = hips[0 if side < 0.0 else 4]
		pivot.position = Vector3(hip.x * 0.8, hip.y + 0.22, hip.z - 0.05)
		var rest := Vector3(deg_to_rad(48.0), -side * 0.38, side * 0.16)
		pivot.rotation = rest
		_body.add_child(pivot)
		_blades.append([pivot, rest])


func _glow_light(at: Vector3, col: Color, energy: float, rng_: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_
	l.omni_attenuation = 1.2
	l.position = at
	add_child(l)
	_glows.append([l, energy, _rng.randf() * TAU])


func _put(model: String, size: float, at: Vector3, fit := "height", fallback_col := Color.GRAY) -> Node3D:
	var m := Models.instance(model, size, fit)
	if m == null:
		m = Fx.sphere(size * 0.5, Fx.mat(fallback_col, 1.0))
		m.position.y = size * 0.5
	m.position += at
	m.rotation.y = _rng.randf() * TAU
	add_child(m)
	return m


func _props() -> void:
	var purple := Color(0.75, 0.4, 1.0)
	var green := Color(0.45, 1.0, 0.55)
	# fungos: um tufo roxo à esquerda, um verde à direita, outros pequenos no fundo
	for f in [
		["fungo_roxo", 1.1, Vector3(-2.3, 0, 1.6)], ["fungo_roxo", 0.6, Vector3(-1.75, 0, 1.15)],
		["fungo_roxo", 0.45, Vector3(-2.75, 0, 1.1)], ["fungo_verde", 0.9, Vector3(2.35, 0, 1.9)],
		["fungo_verde", 0.5, Vector3(1.9, 0, 1.3)], ["fungo_verde", 0.7, Vector3(-4.6, 0, 6.6)],
		["fungo_roxo", 0.8, Vector3(4.8, 0, 7.0)], ["fungo_verde", 0.4, Vector3(-0.9, 0, 3.6)],
		["fungo_roxo", 0.55, Vector3(1.1, 0, 4.0)],
	]:
		_put(f[0], f[1], f[2], "height", purple)
	_glow_light(Vector3(-2.2, 0.9, 1.5), purple, 1.6, 4.0)
	_glow_light(Vector3(2.3, 0.8, 1.8), green, 1.3, 3.6)
	_glow_light(Vector3(-4.6, 0.8, 6.5), green, 1.0, 3.5)
	_glow_light(Vector3(4.8, 0.9, 6.9), purple, 1.0, 3.5)
	# cristais azuis ao pé do pilar direito
	var cyan := Color(0.4, 0.8, 1.0)
	_put("cristal", 1.5, Vector3(3.1, 0, 4.4), "height", cyan)
	_put("cristal", 0.8, Vector3(2.6, 0, 4.0), "height", cyan)
	_glow_light(Vector3(3.0, 1.0, 4.1), cyan, 1.4, 4.0)
	# ninho de ovos ao pé do pilar esquerdo
	for e in [Vector3(-3.2, 0, 4.1), Vector3(-2.75, 0, 4.4), Vector3(-3.05, 0, 3.6), Vector3(-2.55, 0, 3.85), Vector3(-2.9, 0.3, 3.95)]:
		_put("ovo", 0.5, e, "height", Color(0.9, 0.9, 0.8))
	_glow_light(Vector3(-2.9, 0.6, 3.9), Color(0.95, 0.85, 0.6), 0.6, 2.5)
	# casulo pendurado num fio da teia
	var top := Vector3(1.9, 6.0, 4.8)
	_strand(top, top + Vector3(0, -1.9, 0), Fx.mat(SILK_COL, 0.8, true, 0.6), 0.012)
	_cocoon = Node3D.new()
	_cocoon.position = top + Vector3(0, -1.9, 0)
	add_child(_cocoon)
	var c := Models.instance("casulo", 1.0, "height")
	if c == null:
		c = Fx.sphere(0.35, Fx.mat(Color(0.85, 0.85, 0.9)))
	c.position.y = -1.0 if c.name.begins_with("Modelo_") else -0.4
	_cocoon.add_child(c)


func _dust() -> void:
	## Pó e esporos boiando na luz (sem tela, como nos testes, não há o que desenhar).
	if DisplayServer.get_name() == "headless":
		return
	var p := CPUParticles3D.new()
	p.amount = 120
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(7.0, 3.0, 5.0)
	p.position = Vector3(0, 2.6, 2.4)
	p.direction = Vector3(0.2, 1, 0)
	p.spread = 60.0
	p.gravity = Vector3(0, 0.03, 0)
	p.initial_velocity_min = 0.03
	p.initial_velocity_max = 0.12
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.2
	var q := SphereMesh.new()
	q.radius = 0.012
	q.height = 0.024
	q.radial_segments = 6
	q.rings = 3
	q.material = Fx.mat(Color(0.75, 0.88, 1.0), 3.0, true)
	p.mesh = q
	var fade := Curve.new()   # nasce e some devagar (cresce e encolhe)
	fade.add_point(Vector2(0.0, 0.0))
	fade.add_point(Vector2(0.3, 1.0))
	fade.add_point(Vector2(0.7, 1.0))
	fade.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = fade
	add_child(p)
