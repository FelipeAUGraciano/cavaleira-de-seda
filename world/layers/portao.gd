extends LayerBase
## P — Portão da Superfície (o ato final). Curta e intensa: a luz do dia anula a vantagem do
## escuro, a expedição tem o acampamento grande aqui e, no fim, o Guardião.
##
##   P1 Escadaria antiga     chegada pela corda da Capitã; degraus esculpidos (alguém viveu aqui)
##   P2 Acampamento grande   de onde a expedição veio: tendas, fogueiras, armadilhas, caçadores
##   P4 Ninho alto           segredo do outro lado de um abismo (fio de pilar a pilar)
##   P3 Galeria iluminada    LUZ DO DIA em fachos: a runa não ajuda, só as sombras escondem
##   P5 Câmara do eco final  o último casulo do jogo (a toca), onde a caverna inteira ecoa
##   P6 Ponte do Guardião    abismo longo com a ponte de pedra quebrada e rajadas de vento
##   P7 Arena do Guardião    o Colosso da Fenda no ninho dele (chefe final, 3 fases)
##   P8 Saída                a superfície: o final muda conforme a forma dela
## Coordenadas em metros: x leste, z sul (subir é ir para o norte, z negativo).

const P1_PATH := [Vector2(0, 48), Vector2(0, 38), Vector2(1, 29)]
const P2_C := Vector2(0, 8)
const P4_C := Vector2(-35, -3)
const P3_PATH := [Vector2(17, -4), Vector2(27, -13), Vector2(38, -21), Vector2(47, -30)]
const P5_C := Vector2(56, -40)
const P5_R := 6.0
const P6_S := Vector2(56, -52)        ## beira sul do abismo
const P6_N := Vector2(56, -72)        ## beira norte
const ISLES := [Vector2(56, -58.5), Vector2(57.5, -65.0)]
const ARENA := Vector2(56, -92)
const ARENA_RX := 17.0
const ARENA_RZ := 14.5
const GATE := Vector2(56, -107.5)
const EXIT_END := Vector2(56, -125)
const WIND_ZONE := Rect2(46, -73, 20, 22)

var cave: CaveBuilder
var hunt: HuntDirector
var guardian: Guardian
var _sun: Array = []                  ## [centro, raio, força] dos fachos de luz do dia
var _arena_sun := -1
var _arena_lights: Array = []
var _gate_body: StaticBody3D
var _gate_parts: Array = []
var _wind_t := 0.0
var _wind_warned := false
var _gust := 0.0
var _wind_fx: CPUParticles3D
var _ending := false
var _echoed := false
var _zoomed := false


# ---------------------------------------------------------------- câmaras

func _configure() -> void:
	music_area = "portao"
	level_cap = 31   ## teto de nível do andar (somando as formas): ver Player.level_cap
	threat = 2.0      ## bichos batem 100% mais forte
	toughness = 1.7   ## e têm 70% mais vida (chefes não)
	ambience = "portao" if Sfx.has("amb_portao") else "cacada"   # (amb_portao: prompt no GDD)
	layer_id = "P"
	layer_name = "Portão da Superfície"
	layer_subtitle = "Ato final · A luz lá em cima"
	spawn_point = Vector3(0, 0.1, 46)
	entries = {"cacada": {"spawn": Vector3(0, 0.1, 44), "from": Vector3(0, 0.1, 49)}}
	ambient_color = Color(0.6, 0.58, 0.5)
	ambient_energy = 0.3
	fog_color = Color(0.09, 0.08, 0.07)
	rooms = [
		{"id": "P1", "name": "Escadaria antiga", "checkpoint": true, "shapes": [CaveBuilder.path(P1_PATH, 6.5, 0.5)],
			"hint": "Degraus esculpidos subindo. Lá em cima, o acampamento grande da expedição: furtividade ou luta.",
			"line_id": "p1_escada", "line": "Degraus. DEGRAUS. Alguém fez isso. Pra patas pequenas... e pra patas enormes."},
		{"id": "P2", "name": "Acampamento grande", "checkpoint": true, "shapes": [CaveBuilder.ellipse(P2_C, 19.0, 14.0, 0.0, 1.2)],
			"hint": "O acampamento de onde a expedição veio. Fogo queima fios; no alerta 3, o esquadrão sai atrás de você. A saída é a galeria a nordeste.",
			"line_id": "p2_acampamento", "line": "É aqui que eles moram. Um monte deles. E um monte de comida."},
		{"id": "P4", "name": "Ninho alto", "shapes": [CaveBuilder.blob(P4_C, 5.0, 0.6)],
			"line_id": "p4_ninho", "line": "Um ninho. Bem alto. Ninguém chega aqui... a não ser por um fio."},
		{"id": "P3", "name": "Galeria iluminada", "checkpoint": true, "shapes": [CaveBuilder.path(P3_PATH, 9.0, 0.8)],
			"hint": "LUZ DO DIA nos fachos: lá dentro todo mundo te vê, com ou sem runa. Passe pelas sombras entre eles.",
			"line_id": "p3_luz", "line": "Isso é... luz? Luz de verdade, que não vem de fungo nem de mim? Dói nos olhos. É lindo."},
		{"id": "P5", "name": "Câmara do eco final", "checkpoint": true, "shapes": [CaveBuilder.blob(P5_C, P5_R, 0.4)],
			"hint": "O último casulo. Teça o casulo central (C, 30 de Seda) para fazer daqui a sua toca: depois dela, só o Guardião.",
			"line_id": "p5_eco", "line": "Escuta... a caverna inteira ecoa aqui."},
		{"id": "P6", "name": "Ponte do Guardião", "shapes": [CaveBuilder.path([P6_S + Vector2(0, 4), P6_N + Vector2(0, -3)], 12.0, 0.5)],
			"hint": "A ponte de pedra caiu. Fios de pilar em pilar pelas ilhas. RAJADAS de vento: no chão empurram para o abismo; no fio, ela se agarra e para.",
			"line_id": "p6_ponte", "line": "Vento. Vento DE VERDADE. Vem de cima... de fora."},
		{"id": "P7", "name": "Arena do Guardião", "shapes": [CaveBuilder.ellipse(ARENA, ARENA_RX, ARENA_RZ, 0.0, 0.8)],
			"line_id": "p7_arena", "line": "Tem alguma coisa enorme dormindo na frente do portão."},
		{"id": "P8", "name": "Saída", "shapes": [CaveBuilder.path([GATE, EXIT_END], 7.0, 0.4)],
			"line_id": "p8_saida", "line": "Luz. Muita luz. É o fim da caverna."},
	]
	locks = [{"type": "abismo_longo", "pos": Vector3(-25, 0, -3)}]
	chasms = [
		{"rect": Rect2(-29, -9, 7, 12), "name": "o abismo do ninho"},
		{"rect": Rect2(44, -71, 24, 17), "name": "o abismo da ponte"},
	]


func _build_level() -> void:
	cave = CaveBuilder.new()
	cave.floor_color = Color(0.36, 0.33, 0.3)
	cave.rock_color = Color(0.24, 0.22, 0.21)
	cave.noise.seed = 97
	cave.rooms = rooms
	cave.tunnels = [
		CaveBuilder.path([Vector2(1, 30), Vector2(0, 21)], 5.0, 0.3),                         # P1 → P2
		CaveBuilder.path([Vector2(13, 0), Vector2(18, -5)], 6.0, 0.3),                        # P2 → P3
		CaveBuilder.path([Vector2(-18, -3), Vector2(-31, -3)], 4.5, 0.2),                     # P2 → (abismo) → P4
		CaveBuilder.path([Vector2(46, -29), Vector2(51, -35)], 4.5, 0.3),                     # P3 → P5
		CaveBuilder.path([P5_C + Vector2(0, -P5_R + 0.5), P6_S + Vector2(0, 3)], 4.5, 0.2),   # P5 → P6
		CaveBuilder.path([P6_N + Vector2(0, -2), Vector2(56, -78.5)], 6.0, 0.2),              # P6 → P7
	]
	cave.chasms = [
		CaveBuilder.path([Vector2(-25, -10), Vector2(-25.5, 4)], 6.0, 0.3),                    # abismo do ninho
		CaveBuilder.ellipse(Vector2(56, -62), 11.0, 7.2, 0.0, 0.3),                           # abismo da ponte
	]
	var isl: Array = []
	for q: Vector2 in ISLES:
		isl.append(CaveBuilder.blob(q, 2.0, 0.2))
	cave.bridges = isl
	map_grid = cave.build(self)
	cave.scatter_decor(self, 5)
	_build_stairs()
	_build_anchors()
	_build_camp()
	_build_sunbeams()
	_build_bridge_ruins()
	_build_arena()
	_build_exit_light()
	_build_wind_fx()


func _snap(p: Vector2, margin := 0.6) -> Vector3:
	if cave.is_floor(p, margin):
		return Vector3(p.x, 0, p.y)
	for r in range(1, 16):
		for k in 16:
			var q := p + Vector2(cos(k * TAU / 16.0), sin(k * TAU / 16.0)) * float(r) * 0.5
			if cave.is_floor(q, margin):
				return Vector3(q.x, 0, q.y)
	return Vector3(p.x, 0, p.y)


func _build_stairs() -> void:
	## P1: degraus largos e baixos esculpidos na pedra, e colunas quebradas.
	var stone := Fx.mat(Color(0.42, 0.39, 0.36))
	for k in 9:
		var z := 46.0 - k * 1.8
		var w := 5.0 - absf(k - 4) * 0.12
		var st := Fx.box(Vector3(w, 0.06, 0.5), stone)
		st.position = Vector3(0.1 * sin(k), 0.03, z)
		add_child(st)
	for q in [Vector2(-3.6, 42), Vector2(3.6, 39), Vector2(-3.4, 34), Vector2(3.8, 31)]:
		if not cave.is_floor(q, 0.3):
			continue
		var h := 1.2 + fposmod(q.y * 0.37, 1.4)
		var col := Fx.cylinder(0.42, h, stone)
		col.position = Vector3(q.x, h * 0.5, q.y)
		add_child(col)
	var mural := Note.new([
		"Na parede, a espiral da runa. A mesma das minhas costas.",
		"Embaixo dela, gravados na pedra: uma aranha pequena e um dragão enorme, lado a lado, na frente de um portão.",
		"O dragão está deitado. A aranha está de frente para ele. Não dá para saber se é uma luta... ou uma conversa."], "p1_mural", "cristal")
	mural.position = _snap(Vector2(-2.6, 36), 0.4)
	add_child(mural)


func _build_anchors() -> void:
	var stone := Color(0.4, 0.37, 0.34)
	var named := {
		"P1": [Vector2(-2.5, 44), Vector2(2.5, 33)],
		"P2": [P2_C + Vector2(-12, -6), P2_C + Vector2(-8, 7), P2_C + Vector2(10, 8), P2_C + Vector2(12, -6), P2_C + Vector2(0, -10), P2_C + Vector2(-4, 0)],
		"P3": [Vector2(22, -11), Vector2(30, -12), Vector2(34, -23), Vector2(42, -22)],
		"P5": [P5_C + Vector2(-3.4, 2.2), P5_C + Vector2(3.4, 2.2)],
	}
	for id in named:
		var k := 0
		for q: Vector2 in named[id]:
			if cave.is_floor(q, 0.7):
				add_anchor("%s_%d" % [id, k], Vector3(q.x, 0, q.y), 3.6, 0.45, stone)
				k += 1
	# o abismo do ninho: um pilar de cada lado (10 m de fio)
	add_anchor("P2_beira", _snap(Vector2(-20.5, -3), 0.4), 3.8, 0.45, stone)
	add_anchor("P4_beira", _snap(Vector2(-30.5, -3), 0.4), 3.8, 0.45, stone)
	# a ponte: beira sul, as duas ilhas e a beira norte (até ~7 m de fio)
	add_anchor("P6_sul", _snap(P6_S, 0.4), 4.0, 0.5, stone)
	for i in ISLES.size():
		add_anchor("P6_ilha%d" % i, Vector3(ISLES[i].x, 0, ISLES[i].y), 3.8, 0.5, stone)
	add_anchor("P6_norte", _snap(P6_N, 0.4), 4.0, 0.5, stone)
	# arena: seis pilares grossos (a investida se arrebenta neles)
	for i in 6:
		var a := i * TAU / 6.0 + PI / 6.0
		var q := ARENA + Vector2(cos(a) * 9.5, sin(a) * 8.0)
		add_anchor("P7_%d" % i, Vector3(q.x, 0, q.y), 5.0, 0.8, stone)


func arena_pillars() -> Array:
	var out: Array = []
	for i in 6:
		var a: Node3D = WebNetwork.anchors.get("P7_%d" % i)
		if a != null:
			out.append(a.global_position)
	return out


func _build_camp() -> void:
	## P2: o acampamento grande. Tendas, duas fogueiras, caixas, bandeiras e uma paliçada.
	var canvas := Color(0.6, 0.52, 0.4)
	for t in [[Vector2(-10, 0), 0.3], [Vector2(-6, 14), -0.4], [Vector2(8, 15), 0.9], [Vector2(11, 2), -0.2], [Vector2(-13, 9), 1.4]]:
		var tent := add_static_box(Vector3(3.2, 1.9, 2.5), _snap(t[0], 1.8) + Vector3(0, 0.95, 0), canvas)
		tent.rotation.y = float(t[1])
		nav_blockers.append([tent.position, Vector3(3.2, 1.9, 2.5)])
	for f in [Vector2(-1, 6), Vector2(6, -4)]:
		var fire := Fire.new(1.0)
		fire.position = _snap(f, 1.0)
		add_child(fire)
	for c in [Vector2(3, 12), Vector2(4.2, 12.6), Vector2(-15, 3), Vector2(14, 9)]:
		var box := add_static_box(Vector3(0.9, 0.9, 0.9), _snap(c, 0.8) + Vector3(0, 0.45, 0), Color(0.42, 0.3, 0.2))
		nav_blockers.append([box.position, Vector3(0.9, 0.9, 0.9)])
	for b in [Vector2(-3, -8), Vector2(9, -9)]:
		var bp := _snap(b, 0.6)
		var pole := Fx.cylinder(0.06, 3.4, Fx.mat(Color(0.35, 0.25, 0.15)))
		pole.position = bp + Vector3(0, 1.7, 0)
		add_child(pole)
		var flag := Fx.box(Vector3(0.05, 0.8, 1.2), Fx.mat(Color(0.6, 0.15, 0.12)))
		flag.position = bp + Vector3(0, 3.0, 0.6)
		add_child(flag)
	var stake := Fx.mat(Color(0.33, 0.24, 0.16))
	for k in 12:   # paliçada pela borda sul (de onde ela chega)
		var x := -9.0 + k * 1.6
		if absf(x - 0.5) < 3.0:
			continue   # a entrada da escadaria fica aberta
		var q := Vector2(x, 20.5)
		if not cave.is_floor(q, 0.2):
			continue
		var s := Fx.cylinder(0.12, 1.6, stake)
		s.position = Vector3(q.x, 0.8, q.y)
		s.rotation.z = 0.08 * sin(k * 1.7)
		add_child(s)


func _build_sunbeams() -> void:
	## P3 (e um facho no meio da arena): fendas no teto deixam entrar a luz do dia em fachos.
	## Dentro do facho todo mundo te vê; entre eles, sombra.
	var beams := [[Vector2(21, -8), 2.8], [Vector2(28.5, -14.5), 3.2], [Vector2(35, -18.5), 2.6], [Vector2(40.5, -24), 3.0], [Vector2(45.5, -28.5), 2.4]]
	for b in beams:
		_add_beam(b[0], float(b[1]), 1.0)
	_arena_sun = _sun.size()
	_add_beam(ARENA + Vector2(0, 2), 4.2, 0.7)


func _add_beam(c: Vector2, r: float, strength: float) -> void:
	_sun.append([c, r, strength])
	var sl := SpotLight3D.new()
	sl.light_color = Color(1.0, 0.94, 0.8)
	sl.light_energy = 6.0 * strength
	sl.spot_range = 16.0
	sl.spot_angle = rad_to_deg(atan(r / 12.0)) + 3.0
	sl.spot_attenuation = 0.4
	sl.shadow_enabled = true
	sl.position = Vector3(c.x, 12.0, c.y)
	sl.rotation_degrees = Vector3(-90, 0, 0)
	add_child(sl)
	var shaft := Fx.cylinder(r * 0.85, 12.0, Fx.mat(Color(1.0, 0.95, 0.8), 0.15, true, 0.025))
	(shaft.mesh as CylinderMesh).top_radius = r * 0.55
	shaft.position = Vector3(c.x, 6.0, c.y)
	add_child(shaft)
	var pool := Fx.cylinder(r, 0.02, Fx.mat(Color(1.0, 0.92, 0.7), 0.3, true, 0.08))
	pool.position = Vector3(c.x, 0.02, c.y)
	add_child(pool)
	sl.set_meta("parts", [shaft, pool])
	_sun[_sun.size() - 1].append(sl)


func daylight_at(pos: Vector3) -> float:
	## 0 a 1: quanto de luz do dia bate aqui (fachos e a saída).
	var q := Vector2(pos.x, pos.z)
	var best := 0.0
	for s in _sun:
		var r: float = s[1]
		if float(s[2]) <= 0.0:
			continue
		var d := q.distance_to(s[0])
		if d < r:
			best = maxf(best, float(s[2]) * clampf((r - d) / (r * 0.4), 0.0, 1.0))
	if q.y < GATE.y + 2.0 and (_gate_body == null or not is_instance_valid(_gate_body)):
		best = maxf(best, clampf((GATE.y + 2.0 - q.y) / 12.0, 0.0, 1.0))
	return best


func _build_bridge_ruins() -> void:
	## P6: pedaços da ponte de pedra caída nas ilhas e nas beiradas.
	var stone := Fx.mat(Color(0.38, 0.35, 0.33))
	for q in [P6_S + Vector2(-2.2, -0.6), P6_S + Vector2(2.4, -0.4), P6_N + Vector2(-2.0, 0.6), P6_N + Vector2(2.2, 0.4)]:
		var b := Fx.box(Vector3(1.0, 0.7, 1.4), stone)
		b.position = Vector3(q.x, 0.35, q.y)
		b.rotation.y = q.x * 0.3
		add_child(b)
	for q: Vector2 in ISLES:
		var slab := Fx.box(Vector3(2.2, 0.25, 1.6), stone)
		slab.position = Vector3(q.x + 0.6, 0.12, q.y + 0.5)
		slab.rotation.y = 0.4
		add_child(slab)


func _build_arena() -> void:
	## P7: ninho do Colosso. Ossos grandes pelo chão, luz fria dos cristais nas paredes
	## e o portão de pedra ao norte (fechado até ele cair).
	var bone := Fx.mat(Color(0.82, 0.78, 0.68))
	for k in 7:
		var a := k * 0.9 + 0.3
		var q := ARENA + Vector2(cos(a) * 12.5, sin(a) * 10.5)
		if not cave.is_floor(q, 0.5):
			continue
		var b := Fx.cylinder(0.18, 1.8, bone)
		b.position = Vector3(q.x, 0.2, q.y)
		b.rotation = Vector3(PI * 0.5, a, 0.3)
		add_child(b)
	for k in 8:
		var a := k * TAU / 8.0 + 0.2
		var l := OmniLight3D.new()
		l.light_color = Color(0.45, 0.8, 1.0)
		l.omni_range = 9.0
		l.light_energy = 1.3
		l.position = Vector3(ARENA.x + cos(a) * (ARENA_RX - 2.0), 2.5, ARENA.y + sin(a) * (ARENA_RZ - 2.0))
		add_child(l)
		_arena_lights.append(l)
		var cr := Fx.cylinder(0.25, 1.4, Fx.mat(Color(0.45, 0.85, 1.0), 2.5, false, 0.9))
		(cr.mesh as CylinderMesh).top_radius = 0.02
		cr.position = l.position + Vector3(0, -1.6, 0)
		add_child(cr)
	# o portão: duas folhas de pedra com a espiral gravada
	var stone := Color(0.3, 0.28, 0.27)
	for side in [-1.0, 1.0]:
		var leaf := add_static_box(Vector3(3.6, 6.0, 0.8), Vector3(GATE.x + side * 1.8, 3.0, GATE.y), stone)
		_gate_parts.append(leaf)
	_gate_body = add_static_box(Vector3(7.4, 6.0, 1.0), Vector3(GATE.x, 3.0, GATE.y), stone)
	for c in _gate_body.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visible = false
	var spiral := Fx.cylinder(1.1, 0.06, Fx.mat(Color(0.45, 0.85, 1.0), 2.0, true))
	spiral.position = Vector3(GATE.x, 3.4, GATE.y + 0.45)
	spiral.rotation.x = PI * 0.5
	add_child(spiral)
	_gate_parts.append(spiral)
	var leak := OmniLight3D.new()   # a luz do dia vazando pelas frestas do portão
	leak.light_color = Color(1.0, 0.92, 0.75)
	leak.omni_range = 7.0
	leak.light_energy = 1.4
	leak.position = Vector3(GATE.x, 1.5, GATE.y + 1.2)
	add_child(leak)


func open_gate(animated: bool) -> void:
	if animated and Sfx.has("portao_abre"):
		Sfx.play("portao_abre", Vector3(GATE.x, 1.0, GATE.y), 4.0, 0.0)
	if _gate_body != null and is_instance_valid(_gate_body):
		_gate_body.queue_free()
		_gate_body = null
	for p in _gate_parts:
		if not is_instance_valid(p):
			continue
		var n := p as Node3D
		if animated:
			var tw := n.create_tween()
			tw.tween_property(n, "position:y", n.position.y + 6.5, 3.0).set_trans(Tween.TRANS_SINE)
		else:
			n.position.y += 6.5


func _build_exit_light() -> void:
	## P8: a luz do dia de verdade, cada vez mais forte até a boca da caverna.
	for k in 4:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.95, 0.85)
		l.omni_range = 9.0
		l.light_energy = 0.8 + k * 0.7
		l.position = Vector3(EXIT_END.x, 3.0, GATE.y - 3.0 - k * 4.5)
		add_child(l)


func _build_wind_fx() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_wind_fx = CPUParticles3D.new()
	_wind_fx.emitting = false
	_wind_fx.amount = 90
	_wind_fx.lifetime = 1.2
	_wind_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_wind_fx.emission_box_extents = Vector3(1.0, 1.5, 9.0)
	_wind_fx.position = Vector3(WIND_ZONE.position.x, 1.2, WIND_ZONE.get_center().y)
	_wind_fx.direction = Vector3(1, 0, 0)
	_wind_fx.spread = 6.0
	_wind_fx.gravity = Vector3.ZERO
	_wind_fx.initial_velocity_min = 14.0
	_wind_fx.initial_velocity_max = 20.0
	var q := BoxMesh.new()
	q.size = Vector3(0.6, 0.02, 0.02)
	q.material = Fx.mat(Color(0.9, 0.9, 0.85), 0.8, true, 0.5)
	_wind_fx.mesh = q
	add_child(_wind_fx)


# ---------------------------------------------------------------- gente e coisas

func _populate() -> void:
	ecosystem.larva_target = 0
	ecosystem.frog_target = 0
	EventBus.creature_died.connect(_on_creature_died)
	hunt = HuntDirector.new()
	hunt.camp_rooms = ["P2"]
	add_child(hunt)
	hunt.squad_out.connect(func(): EventBus.big_message.emit("ALERTA 3: o acampamento inteiro saiu atrás de você!"))
	var camp := _snap(P2_C + Vector2(0, 2), 1.2)
	var roles := ["espadachim", "espadachim", "arqueira", "batedor"]
	for k in roles.size():
		var a := k * TAU / roles.size() + 0.4
		_hunter(roles[k], camp + Vector3(cos(a) * 3.2, 0, sin(a) * 3.2), ["P2"], true)
	_hunter("espadachim", _snap(P2_C + Vector2(-12, 4)), ["P2", "P1"])
	_hunter("arqueira", _snap(P2_C + Vector2(13, -5)), ["P2"])
	_hunter("batedor", _snap(P2_C + Vector2(8, -10)), ["P2", "P3"])
	_hunter("espadachim", _snap(Vector2(30, -14)), ["P3"])
	_hunter("arqueira", _snap(Vector2(41, -25)), ["P3"])
	# armadilhas de fogo nos caminhos do acampamento
	for q in [Vector2(0.5, 19), Vector2(-2, 17.5), Vector2(14, -1), Vector2(-17, -2.5)]:
		var t := FireTrap.new()
		t.position = _snap(q, 0.5)
		add_child(t)
	# a última toca
	den = Den.new().setup("P5", Vector3(P5_C.x, 0.0, P5_C.y), [
		{"pos": Vector3(P5_C.x - 3.6, 0, P5_C.y + P5_R - 1.2), "out": Vector3(-0.6, 0, 0.8), "width": 2.8, "to": "P3"},
		{"pos": Vector3(P5_C.x, 0, P5_C.y - P5_R + 0.2), "out": Vector3(0, 0, -1), "width": 2.8, "to": "P6"},
	], "Câmara do eco final")
	den.inner_r = P5_R - 0.6
	add_child(den)
	# o Guardião
	if not GameState.flags.has("p7_guardiao"):
		guardian = Guardian.new()
		guardian.position = Vector3(ARENA.x, 0.0, ARENA.y - 3.5)
		guardian.arena_center = Vector3(ARENA.x, 0, ARENA.y)
		guardian.arena_radius = minf(ARENA_RX, ARENA_RZ)
		guardian.den = guardian.position
		guardian.range_rooms = ["P7"]
		guardian.facing = Vector3(0, 0, 1)
		ecosystem.add_child(guardian)
		guardian.pillars = arena_pillars()
		guardian.phase_changed.connect(_on_guardian_phase)
		add_trigger(Rect2(ARENA - Vector2(ARENA_RX - 3.0, ARENA_RZ - 6.0), Vector2((ARENA_RX - 3.0) * 2.0, ARENA_RZ * 2.0 - 8.0)), _on_arena)
	else:
		open_gate(false)
	add_trigger(Rect2(EXIT_END - Vector2(3.5, 2.0), Vector2(7, 5)), _on_exit)
	add_trigger(Rect2(P5_C - Vector2(P5_R, P5_R), Vector2(P5_R * 2.0, P5_R * 2.0)), _on_echo_room)
	# comida: suprimentos da expedição e presas esquecidas
	var items := [["racao", "p2_racao_a", P2_C + Vector2(3.6, 11)], ["racao", "p2_racao_b", P2_C + Vector2(-14, 2)],
		["racao", "p2_racao_c", P2_C + Vector2(12, 6)], ["presa", "p3_presa", Vector2(33, -16)], ["presa", "p5_presa", P5_C + Vector2(2, -2)],
		["cristal_pv", "p4_cristal", P4_C + Vector2(1.5, -1)], ["presa", "p4_presa", P4_C + Vector2(-2, 1)]]
	for it in items:
		if GameState.flags.has(it[1]):
			continue
		var pk := Pickup.new(it[0], it[1])
		pk.position = _snap(it[2], 0.5)
		add_child(pk)
	var diary := Note.new([
		"Diário do acampamento: a Capitã desceu atrás da aranha da runa. Se não voltar até a lua cheia, recuamos para a superfície.",
		"Ninguém atravessa a ponte. O dragão do Portão acorda com qualquer vibração, e a ponte de pedra já caiu uma vez.",
		"Os velhos da vila dizem que o dragão não guarda o portão contra quem sai. Guarda contra quem entra."], "p2_diario", "papel")
	diary.position = _snap(P2_C + Vector2(-1, 9), 0.6)
	add_child(diary)
	var nest := Note.new([
		"Um ninho de gravetos, bem trançado. De PÁSSARO.",
		"...Pássaro. Como eu sei o que é um pássaro? Eu nunca vi um pássaro. Eu nunca vi o céu.",
		"Mas eu sei. Asas, penas, canto de manhã cedo. Eu sei do jeito que a gente sabe uma coisa de antes."], "p4_ninho_lembranca", "cristal")
	nest.position = _snap(P4_C + Vector2(-0.5, -1.5), 0.5)
	add_child(nest)
	for fz: Vector2 in [Vector2(-2, 40), Vector2(2, 31), P5_C + Vector2(-4, -1), P5_C + Vector2(4, -2), P4_C + Vector2(2, 2)]:
		if cave.is_floor(fz, 0.4):
			add_fungus(Vector3(fz.x, 0, fz.y), Color(0.85, 0.75, 1.0))


func _hunter(role: String, at: Vector3, rooms_: Array, squad := false) -> Hunter:
	var h := Hunter.new(role)
	h.position = at + Vector3(0, 0.3, 0)
	h.range_rooms = rooms_
	h.squad = squad
	h.den = at
	h.director = hunt
	ecosystem.add_child(h)
	return h


func _start() -> void:
	GameState.hunt_alert = 0.0
	if not resumed:
		EventBus.message.emit("Objetivo: atravesse o acampamento e a galeria iluminada até a Ponte do Guardião (norte).")
	GameState.say_once("p_chegada", "Ar fresco. De verdade. Lá em cima tem um mundo inteiro... e um acampamento inteiro no caminho.")


# ---------------------------------------------------------------- vento, eco, guardião, saída

func _physics_process(delta: float) -> void:
	if player == null or player.dead:
		return
	_tick_wind(delta)
	# luta com o Guardião: a câmera abre para caber o dragão inteiro
	var fight := guardian != null and is_instance_valid(guardian) and guardian.phase in [1, 2, 3] \
		and Fx.flat_dist(player.global_position, Vector3(ARENA.x, 0, ARENA.y)) < ARENA_RX + 4.0
	if fight and not hud.cinematic:
		player.cam_zoom = 30.0
		_zoomed = true
	elif _zoomed:
		player.cam_zoom = 0.0
		_zoomed = false


func _tick_wind(delta: float) -> void:
	## P6: a cada 7 s, uma rajada de 1,2 s soprando para leste (aviso 1,2 s antes).
	_wind_t += delta
	var ph := fmod(_wind_t, 7.0)
	var inside := WIND_ZONE.has_point(Vector2(player.global_position.x, player.global_position.z))
	if ph >= 4.6 and ph < 5.8 and not _wind_warned:
		_wind_warned = true
		if inside:
			EventBus.message.emit("O vento está vindo...")
			GameState.say_once("p6_vento", "Lá vem o vento. Segura firme. SEGURA FIRME.")
	if ph >= 5.8:
		if _gust <= 0.0:
			_gust = 1.2
			if _wind_fx != null:
				_wind_fx.emitting = true
			Sfx.play("vento_rajada" if Sfx.has("vento_rajada") else "pc_queda", player.global_position, -6.0, 0.15, 0.5)
	else:
		_wind_warned = ph >= 4.6
	if _gust > 0.0:
		_gust -= delta
		if _gust <= 0.0 and _wind_fx != null:
			_wind_fx.emitting = false
		if inside and player.invuln <= 0.0:
			if player.on_strand:
				player.apply_slow(0.1, 0.25)   # agarrada no fio: para até a rajada passar
			else:
				player.external_velocity.x = maxf(player.external_velocity.x, 6.5)


func is_gusting() -> bool:
	return _gust > 0.0


func _on_echo_room(body: Node3D) -> void:
	## P5: a caverna inteira ecoa aqui (falas de antes, de longe).
	if not (body is Player) or _echoed or GameState.said.has("p5_eco_fim"):
		return
	_echoed = true
	var lines := [
		["p5_eco_1", "(eco) ...CORRE, CORRE, CORRE, CORRE..."],
		["p5_eco_2", "(eco) ...Larva crua. Gosto de musgo molhado..."],
		["p5_eco_3", "(eco) ...ELE ME SENTIU. Rachadura, rachadura..."],
		["p5_eco_4", "(eco) ...Queimaram minha casa..."],
		["p5_eco_fim", "Tudo o que eu passei tá ecoando aqui. E do outro lado da ponte... tem luz."],
	]
	for l in lines:
		await get_tree().create_timer(2.6).timeout
		if not is_inside_tree():
			return
		GameState.say_once(l[0], l[1])


func _on_arena(body: Node3D) -> void:
	if body is Player and guardian != null and is_instance_valid(guardian) and guardian.phase == 0:
		guardian.wake()


func _on_guardian_phase(n: int) -> void:
	match n:
		3:
			# a poeira apaga a arena: o facho do meio some e os cristais quase apagam
			if _arena_sun >= 0 and _arena_sun < _sun.size():
				_sun[_arena_sun][2] = 0.0
				var sl: SpotLight3D = _sun[_arena_sun][3]
				sl.visible = false
				for part in sl.get_meta("parts"):
					(part as Node3D).visible = false
			for l in _arena_lights:
				var tw := (l as OmniLight3D).create_tween()
				tw.tween_property(l, "light_energy", 0.15, 2.0)
			if player != null:
				player.shake(1.5)
		4:
			pass


func _on_creature_died(c: Node) -> void:
	if c is Guardian and (c as Guardian).phase >= 3:
		GameState.flags["p7_guardiao"] = true
		EventBus.big_message.emit("O Guardião caiu")
		GameState.say_once("guardiao_morto", "Caiu. O dragão que eu não podia nem olhar... caiu. E o portão... tá abrindo.")
		for l in _arena_lights:
			var tw := (l as OmniLight3D).create_tween()
			tw.tween_property(l, "light_energy", 1.3, 2.0)
		open_gate(true)
		autosave()


func _on_exit(body: Node3D) -> void:
	## O fim do jogo: ela sai da caverna. A cena muda conforme a forma dela (Ending).
	if _ending or not (body is Player) or not GameState.flags.has("p7_guardiao"):
		return
	_ending = true
	GameState.flags["fim_jogo"] = true
	player.autopilot = true
	player.auto_target = Vector3(EXIT_END.x, 0.1, EXIT_END.y - 4.0)
	hud.cinematic = true
	GameState.say_once("p8_fim", "O céu. Isso é... o céu.")
	GameState.save_now()
	await get_tree().create_timer(1.8).timeout
	if not is_inside_tree():
		return
	await hud.fade(1.0, 1.6, Color(1, 1, 1))
	var e := Ending.new().setup(player)
	get_tree().root.add_child(e)
