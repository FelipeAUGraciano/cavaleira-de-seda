extends LayerBase
## R — Rio de Brasa (Ato 3). Caverna orgânica de um andar (como as Galerias e o Abismo) cortada
## por um rio de lava de norte a sul. Câmaras de trava e de chefe feitas à mão.
##
##   Oeste (gerado):  R1 Margem fria (chegada; a descida a oeste volta para o Abismo), R15 Galeria
##                    de basalto, R16 Beco quente
##   R2 Mirante do rio: a vista do rio e a escolha entre as duas rotas
##   R3 Ilhas de basalto: pilares sobre a lava (fios queimam em 8 s); a brasa das ilhas pede
##                        Resistência a Fogo 3 (rota rápida)
##   R8 Rota de pedra:    caminho longo pelo sul, sem lava, com golems dormindo (rota segura)
##   Leste (gerado):  R6 Ninho das salamandras, R4 Forja dos golems, R17 Grota dos peixes,
##                    R19 Corredor das brasas, R20 Fosso morno,
##                    R7 Câmara fria (a toca: obsidiana resfriada, 4 frestas)
##   R5 Gêiseres:     corredor de gêiseres que arremessam → Nordeste
##   Nordeste (gerado): R9 Pântano de cinzas (a cinza encurta a visão), R18 Cinzeiro,
##                    R10 Cristais de fogo (segredo atrás de uma fresta)
##   R11 Antecâmara da rainha → R12 Arena da Salamandra-rainha (chefe) → R13 Fluxo resfriado
##   (a lava esfria quando ela cai) → R14 Chaminé (fim do Ato 3)
## Calor: perto da lava perde vida aos poucos (Resistência a Fogo corta 25% por ponto).
## Coordenadas em metros: x leste, z sul.

var cave: CaveBuilder
var org: OrganicCave
var queen: QueenSalamander
const SEED := 83
const RIVER := [Vector2(48, -66), Vector2(46, -24), Vector2(52, 4), Vector2(50, 30), Vector2(47, 42)]
const RIVER_W := 22.0
const ISLANDS := [Vector2(45.5, 4.0), Vector2(52.0, 8.5), Vector2(58.5, 4.5)]
const ISLAND_R := 2.3
const R1_C := Vector2(2, 18)
const R1_POOL := Vector2(6, 22.5)
const DOWN := Vector2(-18, 14)         ## descida para o Abismo (Rampa quente)
const ABISMO := "res://world/layers/abismo.tscn"
const R2_C := Vector2(33, 4)
const DEN_C := Vector2(80, 10)
const DEN_R := 4.5
const R4_C := Vector2(92, 40)
const R6_C := Vector2(78, -34)
const ROTA := [Vector2(14, 46), Vector2(26, 58), Vector2(48, 64), Vector2(70, 58), Vector2(86, 48)]
const GEYSER_PATH := [Vector2(118, 6), Vector2(130, -2), Vector2(144, -8)]
const R9_C := Vector2(166, -30)
const R10_C := Vector2(188, -56)
const R11_C := Vector2(166, 10)
const ARENA := Vector2(166, 34)
const MOAT := Vector3(166, 0, 49.5)
const R13_C := Vector2(166, 60)
const CHIMNEY_END := Vector2(188, 74)
const ZONES := [Rect2(-22, -44, 58, 96), Rect2(64, -64, 56, 124), Rect2(142, -64, 52, 70)]
const DEN_BLOCK := Rect2(72, 2, 16, 16)
var _heat_check := 0.0
var _near_lava := false
var _burn_check := 0.0
var _burning := {}                ## fio → segundos sobre a lava
var _geysers: Array = []
var _geyser_t := 0.0
var _moat_body: StaticBody3D
var _moat_mat: StandardMaterial3D
var _moat_light: OmniLight3D
var _ending := false


# ---------------------------------------------------------------- câmaras

func _configure() -> void:
	layer_id = "R"
	layer_name = "Rio de Brasa"
	layer_subtitle = "Ato 3 · Onde a pedra derrete"
	spawn_point = Vector3(R1_C.x, 0.1, R1_C.y)
	# vindo do Abismo: sobe pela descida da Margem fria (e por ela dá para voltar)
	entries = {"abismo": {"spawn": Vector3(R1_C.x - 4.0, 0.1, R1_C.y - 1.0), "from": Vector3(DOWN.x + 4.0, 0.1, DOWN.y + 0.3)}}
	ambient_color = Color(0.45, 0.22, 0.14)
	ambient_energy = 0.22
	fog_color = Color(0.05, 0.015, 0.005)
	rooms = [
		{"id": "R1", "name": "Margem fria", "checkpoint": true, "label_only": true, "open_r": 9.0,
			"shapes": [CaveBuilder.blob(R1_C, 6.0, 0.0)],
			"hint": "O ar esquenta perto da lava: ficar na beirada tira vida aos poucos. Comer bichos de fogo sobe a Resistência a Fogo.",
			"line_id": "r1_margem", "line": "Quente. Quente QUENTE. E aquilo ali... é um peixe? NADANDO NA LAVA?"},
		{"id": "R2", "name": "Mirante do rio", "checkpoint": true, "shapes": [CaveBuilder.blob(R2_C, 8.0, 1.0)],
			"hint": "Duas rotas: pelas Ilhas de basalto (rápido, mas a brasa das ilhas pede Resistência a Fogo 3 e os fios queimam em 8 s) ou pela Rota de pedra ao sul (longa, com golems dormindo).",
			"line_id": "r2_mirante", "line": "Um RIO. De lava. E do outro lado... tem caminho. Ou eu pulo de ilha em ilha, ou dou a volta."},
		{"id": "R3", "name": "Ilhas de basalto", "shapes": [CaveBuilder.path([Vector2(37, 6), Vector2(67, 8)], 10.0, 0.6)],
			"line_id": "r3_ilhas", "line": "As pedras tão em brasa. Isso vai doer se eu ficar parada."},
		{"id": "R4", "name": "Forja dos golems", "label_only": true, "open_r": 10.0, "shapes": [CaveBuilder.blob(R4_C, 6.0, 0.0)],
			"hint": "Golems de basalto dormem parados como pedra. Correr perto acorda; ande devagar ou passe pelos fios.",
			"line_id": "r4_forja", "line": "Alguém forjou essas coisas. Alguém GRANDE."},
		{"id": "R5", "name": "Gêiseres", "shapes": [CaveBuilder.path(GEYSER_PATH, 8.0, 0.5)],
			"hint": "Os gêiseres borbulham antes de estourar. Passe no intervalo.",
			"line_id": "r5_geiser", "line": "O chão tá... respirando vapor. Em intervalos. Dá pra contar."},
		{"id": "R6", "name": "Ninho das salamandras", "label_only": true, "open_r": 8.5, "shapes": [CaveBuilder.blob(R6_C, 6.0, 0.0)],
			"hint": "Salamandras-chama em pares. O sopro queima seus fios. A carne sobe a Resistência a Fogo.",
			"line_id": "r6_ninho", "line": "Ovos. Ovos QUENTES. E as mães tão olhando pra mim."},
		{"id": "R7", "name": "Câmara fria", "shapes": [CaveBuilder.blob(DEN_C, DEN_R, 0.4)],
			"hint": "Obsidiana resfriada: o único lugar fresco do rio. Teça o casulo central (C) para fazer dela sua toca.",
			"line_id": "r7_fria", "line": "Frio! FRIO! Que delícia. Daqui eu não saio nunca mais."},
		{"id": "R8", "name": "Rota de pedra", "shapes": [CaveBuilder.path(ROTA, 5.0, 0.5)],
			"hint": "Caminho longo, sem lava. Os golems no caminho dormem: ande devagar.",
			"line_id": "r8_rota", "line": "Longe pra caramba. Mas pelo menos o chão não tá derretendo."},
		{"id": "R9", "name": "Pântano de cinzas", "label_only": true, "open_r": 11.0, "shapes": [CaveBuilder.blob(R9_C, 6.0, 0.0)],
			"hint": "A cinza no ar encurta a visão. Peixes-magma nas poças.",
			"line_id": "r9_cinzas", "line": "Não enxergo nada. É tudo cinza. Até eu tô cinza."},
		{"id": "R10", "name": "Cristais de fogo", "shapes": [CaveBuilder.blob(R10_C, 4.5, 0.6)],
			"line_id": "r10_cristais", "line": "Cristais vermelhos. Pulsando. Igual à minha runa, só que... com raiva."},
		{"id": "R11", "name": "Antecâmara da rainha", "checkpoint": true, "shapes": [CaveBuilder.blob(R11_C, 5.5, 0.6)],
			"hint": "Daqui para a frente, a Salamandra-rainha. Prepare a seda e a vida.",
			"line_id": "r11_ante", "line": "Tá muito quente lá dentro. E tem alguma coisa respirando."},
		{"id": "R12", "name": "Arena da Salamandra-rainha", "shapes": [CaveBuilder.ellipse(ARENA, 14.0, 11.0, 0.0, 0.8)],
			"line_id": "r12_arena", "line": "É ela. A mãe de todas."},
		{"id": "R13", "name": "Fluxo resfriado", "checkpoint": true, "shapes": [CaveBuilder.blob(R13_C, 6.0, 0.8)],
			"line_id": "r13_fluxo", "line": "A lava virou pedra. Ainda tá morna. Dá pra andar!"},
		{"id": "R14", "name": "Chaminé", "shapes": [CaveBuilder.path([Vector2(170, 64), Vector2(180, 68), CHIMNEY_END], 4.4, 0.4)],
			"line_id": "r14_chamine", "line": "Um poço subindo. Bem alto. Lá em cima... ar das Galerias?"},
		{"id": "R15", "name": "Galeria de basalto", "label_only": true, "open_r": 7.0, "shapes": [CaveBuilder.blob(Vector2(-8, -26), 5.0, 0.0)]},
		{"id": "R16", "name": "Beco quente", "label_only": true, "open_r": 5.5, "shapes": [CaveBuilder.blob(Vector2(-10, 40), 5.0, 0.0)]},
		{"id": "R17", "name": "Grota dos peixes", "label_only": true, "open_r": 7.0, "shapes": [CaveBuilder.blob(Vector2(104, -48), 5.0, 0.0)]},
		{"id": "R18", "name": "Cinzeiro", "label_only": true, "open_r": 6.5, "shapes": [CaveBuilder.blob(Vector2(184, -12), 5.0, 0.0)]},
		{"id": "R19", "name": "Corredor das brasas", "label_only": true, "open_r": 5.0, "shapes": [CaveBuilder.blob(Vector2(97, 2), 5.0, 0.0)]},
		{"id": "R20", "name": "Fosso morno", "label_only": true, "open_r": 5.0, "shapes": [CaveBuilder.blob(Vector2(72, 27), 5.0, 0.0)]},
	]
	locks = [{"type": "brasa", "pos": Vector3(52, 0, 6)}]


func _room(id: String) -> Array:
	for r in rooms:
		if r["id"] == id:
			return r["shapes"]
	return []


# ---------------------------------------------------------------- geometria

func _build_level() -> void:
	cave = CaveBuilder.new()
	cave.floor_color = Color(0.2, 0.15, 0.14)
	cave.rock_color = Color(0.1, 0.07, 0.07)
	cave.pit_y = -0.6
	cave.pit_color = Color(1.0, 0.32, 0.05)
	cave.pit_glow = 2.4
	cave.noise.seed = 83
	cave.rooms = rooms
	cave.tunnels = [
		CaveBuilder.path([R1_C, Vector2(-8, 16), DOWN + Vector2(-1.5, 0)], 4.0, 0.3),  # Margem fria → descida para o Abismo
		CaveBuilder.path([Vector2(75.6, 10), Vector2(66, 9)], 2.6, 0.2),            # toca → oeste (ilhas)
		CaveBuilder.path([Vector2(80, 5.6), Vector2(80, -3), Vector2(79, -12), Vector2(78, -26)], 2.6, 0.2),   # toca → norte (salamandras)
		CaveBuilder.path([Vector2(80, 14.4), Vector2(80, 21), Vector2(85, 30), Vector2(90, 37)], 2.6, 0.2),   # toca → sul (forja)
		CaveBuilder.path([Vector2(80, 21), Vector2(75, 27)], 2.4, 0.2),                                         # → Fosso morno
		CaveBuilder.path([Vector2(84.4, 10), Vector2(92, 10), Vector2(96, 4)], 2.6, 0.2),     # toca → leste (gêiseres)
		CaveBuilder.path([Vector2(178, -46), Vector2(182, -50), Vector2(185, -53)], 1.4, 0.1),   # fresta → Cristais de fogo
		CaveBuilder.path([Vector2(166, 15), Vector2(166, 24)], 4.0, 0.3),           # antecâmara → arena
		CaveBuilder.path([Vector2(166, 44), Vector2(166, 55)], 5.0, 0.3),           # arena → fluxo (lava até ela cair)
	]
	cave.chasms = [
		CaveBuilder.path(RIVER, RIVER_W, 0.8),                    # o rio de lava
		CaveBuilder.ellipse(R1_POOL, 3.2, 2.2, 0.3, 0.3),         # poça da Margem fria (peixes)
		CaveBuilder.ellipse(R4_C + Vector2(4, 4), 2.6, 1.8, 0.0, 0.2),   # bacia da forja
	]
	var isl: Array = []
	for q: Vector2 in ISLANDS:
		isl.append(CaveBuilder.blob(q, ISLAND_R, 0.3))
	cave.bridges = isl
	_generate_organic()
	map_grid = cave.build(self)
	cave.scatter_decor(self, 11)
	_build_anchors()
	_build_lights()
	_build_den_room()
	_build_forge()
	_build_geysers()
	_build_moat()
	_build_crystals()
	_build_descent()


func _build_descent() -> void:
	## A boca da Rampa quente: degraus descendo para o escuro, com a luz fria do Abismo.
	var rock := Fx.mat(Color(0.14, 0.12, 0.13))
	for k in 5:
		var st := Fx.box(Vector3(0.6, 0.1, 3.4), rock)
		st.position = Vector3(DOWN.x - 0.8 - k * 0.6, -0.08 - k * 0.14, DOWN.y)
		add_child(st)
	var hole := Fx.box(Vector3(2.4, 0.04, 3.6), Fx.mat(Color(0.0, 0.0, 0.02)))
	hole.position = Vector3(DOWN.x - 3.6, -0.7, DOWN.y)
	add_child(hole)
	var l := OmniLight3D.new()
	l.light_color = Color(0.45, 0.55, 1.0)
	l.omni_range = 5.0
	l.light_energy = 0.9
	l.position = Vector3(DOWN.x - 2.5, 0.6, DOWN.y)
	add_child(l)


func _in_zone(p: Vector2) -> bool:
	if DEN_BLOCK.has_point(p):
		return false
	for z: Rect2 in ZONES:
		if z.has_point(p):
			return true
	return false


func _generate_organic() -> void:
	org = OrganicCave.new(Rect2(-24, -68, 222, 152), SEED)
	org.lock_rock(func(p): return not _in_zone(p))
	org.fix_open(func(p): return cave.open_at(p))
	for id in ["R10", "R12", "R13", "R14", "R7"]:
		for sh in _room(id):
			org.protect_band(func(p): return cave._sdf(sh, p, 0.0), 3.0)
	org.scatter(0.5)
	org.smooth(6)
	for r in rooms:
		if r.get("label_only", false):
			org.open_blob((r["shapes"][0] as Dictionary)["c"], float(r.get("open_r", 5.0)))
	org.connect_all(60)
	org.chasm_pockets(0.45, 3.4, 0.06)
	for keep: Vector2 in [R1_C, R4_C, R6_C, R9_C, Vector2(-8, -26)]:
		_no_pits(keep, 8.0)
	cave.tunnels.append(org.open_shape(0.5))
	cave.chasms.append(org.chasm_shape(0.25))


func _no_pits(c: Vector2, r: float) -> void:
	var cc := org.cell_of(c)
	var ri := int(ceil(r))
	for j in range(cc.y - ri, cc.y + ri + 1):
		for i in range(cc.x - ri, cc.x + ri + 1):
			if org.inside(i, j) and org.grid[org.idx(i, j)] == 2 and org.center_of(i, j).distance_to(c) <= r:
				org.grid[org.idx(i, j)] = 1


func _snap(p: Vector2, margin: float = 0.6) -> Vector3:
	if cave.is_floor(p, margin):
		return Vector3(p.x, 0, p.y)
	for r in range(1, 14):
		for k in 16:
			var q := p + Vector2(cos(k * TAU / 16.0), sin(k * TAU / 16.0)) * float(r) * 0.6
			if cave.is_floor(q, margin):
				return Vector3(q.x, 0, q.y)
	var f := org.nearest_floor(p)
	return Vector3(f.x, 0, f.y)


func _lava_spot(c: Vector2, r: float) -> Variant:
	## Ponto de lava perto da beirada (até 2,5 m de chão), o mais perto de c.
	var best: Variant = null
	var best_d := INF
	for j in range(-int(r), int(r) + 1):
		for i in range(-int(r), int(r) + 1):
			var q := c + Vector2(i, j)
			if q.distance_to(c) > r or not cave.is_pit(q):
				continue
			var shore := false
			for k in 8:
				if cave.is_floor(q + Vector2(cos(k * TAU / 8.0), sin(k * TAU / 8.0)) * 2.2, 0.3):
					shore = true
					break
			if shore and q.distance_to(c) < best_d:
				best_d = q.distance_to(c)
				best = Vector3(q.x, 0, q.y)
	return best


func _build_anchors() -> void:
	var basalt := Color(0.16, 0.13, 0.13)
	var named := {"R1": [R1_C + Vector2(-4, -3), R1_C + Vector2(4, -4), R1_C + Vector2(-3, 5)],
		"R2": [R2_C + Vector2(-4, -4), R2_C + Vector2(-3, 5)],
		"R4": [R4_C + Vector2(-6, -4), R4_C + Vector2(6, -6), R4_C + Vector2(-5, 6), R4_C + Vector2(0, -8)],
		"R6": [R6_C + Vector2(-5, -2), R6_C + Vector2(5, 2), R6_C + Vector2(0, 6)],
		"R9": [R9_C + Vector2(-7, -4), R9_C + Vector2(6, -6), R9_C + Vector2(-4, 7), R9_C + Vector2(7, 5)],
		"R11": [R11_C + Vector2(-3, -2), R11_C + Vector2(3, -2)],
		"R13": [R13_C + Vector2(-3, 2), R13_C + Vector2(3, 2)],
		"R15": [Vector2(-12, -26), Vector2(-4, -29)], "R17": [Vector2(100, -46), Vector2(108, -50)],
		"R18": [Vector2(181, -12), Vector2(187, -9)],
		"R8": [Vector2(26, 56), Vector2(48, 62), Vector2(70, 56)]}
	for id in named:
		var k := 0
		for q: Vector2 in named[id]:
			if cave.is_floor(q, 0.7):
				add_anchor("%s_%d" % [id, k], Vector3(q.x, 0, q.y), 3.0, 0.42, basalt)
				k += 1
	# Ilhas de basalto: margem, as três ilhas e a outra margem (até 7,9 m de fio)
	add_anchor("R3_oeste", _snap(Vector2(39.5, 5.5), 0.4), 3.2, 0.45, basalt)
	for i in ISLANDS.size():
		add_anchor("R3_ilha%d" % i, Vector3(ISLANDS[i].x, 0, ISLANDS[i].y), 3.0, 0.45, basalt)
	add_anchor("R3_leste", _snap(Vector2(64.5, 7.0), 0.4), 3.2, 0.45, basalt)
	# toca: quatro pilares de obsidiana
	for i in 4:
		var a := i * TAU / 4.0 + PI * 0.25
		add_anchor("Toca_%d" % i, Vector3(DEN_C.x + cos(a) * (DEN_R - 1.4), 0, DEN_C.y + sin(a) * (DEN_R - 1.4)), 3.0, 0.4, Color(0.08, 0.08, 0.14))
	# arena da rainha: oito pilares em volta
	for i in 8:
		var a := i * TAU / 8.0 + 0.2
		add_anchor("R12_%d" % i, Vector3(ARENA.x + cos(a) * 9.5, 0, ARENA.y + sin(a) * 7.2), 3.6, 0.5, basalt)


func _build_lights() -> void:
	## O rio brilha: luzes laranja ao longo da lava e nas poças.
	for i in range(1, RIVER.size()):
		var a: Vector2 = RIVER[i - 1]
		var b: Vector2 = RIVER[i]
		var n := int(a.distance_to(b) / 14.0) + 1
		for k in n:
			var q := a.lerp(b, (k + 0.5) / n)
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.42, 0.12)
			l.omni_range = 16.0
			l.light_energy = 1.2
			l.position = Vector3(q.x, 1.5, q.y)
			add_child(l)
	for q: Vector2 in [R1_POOL, R4_C + Vector2(4, 4)]:
		var l2 := OmniLight3D.new()
		l2.light_color = Color(1.0, 0.42, 0.12)
		l2.omni_range = 7.0
		l2.light_energy = 1.0
		l2.position = Vector3(q.x, 1.2, q.y)
		add_child(l2)


func _build_den_room() -> void:
	## R7: obsidiana resfriada, preta e lisa, com luz fria.
	var obs := Fx.mat(Color(0.05, 0.05, 0.09))
	obs.metallic = 0.6
	obs.roughness = 0.1
	for k in 10:
		var a := k * TAU / 10.0 + 0.3
		if absf(wrapf(a, -PI, PI)) < 0.45 or absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.45 or absf(wrapf(a + PI * 0.5, -PI, PI)) < 0.45 or absf(wrapf(a - PI, -PI, PI)) < 0.45:
			continue
		var sh := Fx.box(Vector3(0.4, 1.2 + 0.5 * sin(k * 2.3), 0.9), obs)
		sh.position = Vector3(DEN_C.x + cos(a) * (DEN_R - 0.3), 0.6, DEN_C.y + sin(a) * (DEN_R - 0.3))
		sh.rotation.y = -a
		add_child(sh)
	var l := OmniLight3D.new()
	l.light_color = Color(0.5, 0.7, 1.0)
	l.omni_range = 6.0
	l.light_energy = 0.9
	l.position = Vector3(DEN_C.x, 2.2, DEN_C.y)
	add_child(l)


func _build_forge() -> void:
	## R4: bigornas de basalto, correntes e moldes de golem pela metade.
	var rock := Fx.mat(Color(0.18, 0.16, 0.16))
	for q: Vector2 in [R4_C + Vector2(-2, -3), R4_C + Vector2(-5, 3)]:
		if not cave.is_floor(q, 0.8):
			continue
		var anvil := Fx.box(Vector3(1.6, 0.9, 0.9), rock)
		anvil.position = Vector3(q.x, 0.45, q.y)
		add_child(anvil)
		var top := Fx.box(Vector3(2.0, 0.25, 1.0), rock)
		top.position = Vector3(q.x, 1.0, q.y)
		add_child(top)
	var half := R4_C + Vector2(-7, -1)
	if cave.is_floor(half, 1.0):
		var mold := Fx.box(Vector3(1.4, 0.8, 1.0), Fx.mat(Color(0.14, 0.12, 0.12)))
		mold.position = Vector3(half.x, 0.4, half.y)
		mold.rotation.z = 0.4
		add_child(mold)


func _build_geysers() -> void:
	for k in 5:
		var t := (k + 0.6) / 5.6
		var q := _path_point(GEYSER_PATH, t)
		q += Vector2(sin(k * 2.1), cos(k * 1.7)) * 1.6
		var g := Node3D.new()
		g.position = Vector3(q.x, 0, q.y)
		add_child(g)
		var mouth := Fx.cylinder(0.75, 0.06, Fx.mat(Color(0.35, 0.12, 0.05), 0.8))
		mouth.position.y = 0.03
		g.add_child(mouth)
		var bubble := Fx.cylinder(0.8, 0.1, Fx.mat(Color(1.0, 0.5, 0.15), 2.0, true, 0.7))
		bubble.position.y = 0.08
		bubble.visible = false
		g.add_child(bubble)
		var jet := Fx.cylinder(0.85, 5.0, Fx.mat(Color(1.0, 0.9, 0.8), 0.8, true, 0.45))
		jet.position.y = 2.5
		jet.visible = false
		g.add_child(jet)
		g.set_meta("bubble", bubble)
		g.set_meta("jet", jet)
		g.set_meta("hit", false)
		_geysers.append(g)


func _path_point(pts: Array, t: float) -> Vector2:
	var total := 0.0
	for i in range(1, pts.size()):
		total += (pts[i] as Vector2).distance_to(pts[i - 1])
	var d := t * total
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		var l := a.distance_to(b)
		if d <= l:
			return a.lerp(b, d / l)
		d -= l
	return pts[pts.size() - 1]


func _build_moat() -> void:
	## R12→R13: um fosso de lava fecha a saída da arena até a rainha cair.
	_moat_mat = Fx.mat(Color(1.0, 0.35, 0.06), 2.6)
	var pool := Fx.box(Vector3(5.6, 0.05, 4.4), _moat_mat)
	pool.position = MOAT + Vector3(0, 0.03, 0)
	add_child(pool)
	_moat_light = OmniLight3D.new()
	_moat_light.light_color = Color(1.0, 0.42, 0.12)
	_moat_light.omni_range = 7.0
	_moat_light.light_energy = 1.4
	_moat_light.position = MOAT + Vector3(0, 1.2, 0)
	add_child(_moat_light)
	if GameState.flags.has("r12_rainha"):
		cool_moat(false)
		return
	_moat_body = add_static_box(Vector3(5.6, 2.4, 4.4), MOAT + Vector3(0, 1.2, 0), Color.BLACK)
	for c in _moat_body.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visible = false


func cool_moat(animated: bool) -> void:
	if _moat_body != null and is_instance_valid(_moat_body):
		_moat_body.queue_free()
		_moat_body = null
	if animated:
		var tw := create_tween()
		tw.tween_property(_moat_mat, "albedo_color", Color(0.12, 0.1, 0.1), 2.5)
		tw.parallel().tween_property(_moat_mat, "emission_energy_multiplier", 0.15, 2.5)
		tw.parallel().tween_property(_moat_light, "light_energy", 0.0, 2.5)
	else:
		_moat_mat.albedo_color = Color(0.12, 0.1, 0.1)
		_moat_mat.emission_energy_multiplier = 0.15
		_moat_light.light_energy = 0.0


func _build_crystals() -> void:
	## R10: parede de cristais vermelhos pulsando.
	var m := Fx.mat(Color(1.0, 0.3, 0.1), 2.8, false, 0.9)
	for k in 9:
		var a := k * TAU / 9.0
		var q := R10_C + Vector2(cos(a), sin(a)) * 3.4
		if not cave.is_floor(q, 0.2):
			continue
		var c := Fx.cylinder(0.2, 1.2 + 0.5 * sin(k * 1.9), m)
		(c.mesh as CylinderMesh).top_radius = 0.02
		c.position = Vector3(q.x, 0.6, q.y)
		c.rotation.z = 0.3 * sin(k)
		add_child(c)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.35, 0.12)
	l.omni_range = 6.0
	l.light_energy = 1.3
	l.position = Vector3(R10_C.x, 1.5, R10_C.y)
	add_child(l)


# ---------------------------------------------------------------- bichos e coisas

func _populate() -> void:
	ecosystem.larva_target = 0
	ecosystem.frog_target = 0
	EventBus.rested.connect(_on_rested)
	EventBus.creature_died.connect(_on_creature_died)
	den = Den.new().setup("R7", Vector3(DEN_C.x, 0.0, DEN_C.y), [
		{"pos": Vector3(DEN_C.x - DEN_R + 0.2, 0, DEN_C.y), "out": Vector3(-1, 0, 0), "width": 2.6, "to": "R3"},
		{"pos": Vector3(DEN_C.x, 0, DEN_C.y - DEN_R + 0.2), "out": Vector3(0, 0, -1), "width": 2.6, "to": "R6"},
		{"pos": Vector3(DEN_C.x, 0, DEN_C.y + DEN_R - 0.2), "out": Vector3(0, 0, 1), "width": 2.6, "to": "R4"},
		{"pos": Vector3(DEN_C.x + DEN_R - 0.2, 0, DEN_C.y), "out": Vector3(1, 0, 0), "width": 2.6, "to": "R5"},
	], "Câmara fria")
	den.inner_r = DEN_R - 0.5
	add_child(den)
	_spawn_food()
	# peixes-magma e vermes de lava (moram na lava, perto da beirada)
	for f in [[R1_POOL, 3.0], [R1_POOL + Vector2(1.5, 0.5), 3.0], [Vector2(42, -2), 6.0], [Vector2(57, 15), 6.0], [Vector2(61, -8), 6.0],
			[Vector2(104, -48), 9.0], [Vector2(98, -52), 9.0], [R9_C + Vector2(4, 6), 12.0]]:
		_spawn_lurker(MagmaFish.new(), f[0], float(f[1]))
	for w in [[Vector2(46, 16), 6.0], [Vector2(56, -6), 6.0], [R4_C + Vector2(4, 4), 3.0], [R9_C + Vector2(-6, -4), 12.0]]:
		_spawn_lurker(LavaWorm.new(), w[0], float(w[1]))
	# salamandras-chama: dois pares no ninho e um no pântano
	for s in [["R6", 701, ["R6"]], ["R6", 702, ["R6"]], ["R6", 703, ["R6", "R17"]], ["R6", 704, ["R6"]], ["R9", 705, ["R9"]], ["R9", 706, ["R9", "R18"]],
			["R20", 707, ["R20", "R4"]]]:
		var q = _spot(s[0], int(s[1]), 1.2)
		if q != null:
			var sal := FireSalamander.new()
			sal.position = (q as Vector3) + Vector3(0, 0.3, 0)
			sal.den = q
			sal.range_rooms = s[2]
			ecosystem.add_child(sal)
	_build_nest()
	# golems: três na forja, dois dormindo na Rota de pedra
	var golem_spots: Array = []
	for k in 3:
		var q2 = _spot("R4", 720 + k, 1.6)
		if q2 != null:
			golem_spots.append(q2)
	golem_spots.append(Vector3(36, 0, 61))
	golem_spots.append(Vector3(61, 0, 61))
	for q3: Vector3 in golem_spots:
		var g := BasaltGolem.new()
		g.position = _snap(Vector2(q3.x, q3.z), 1.2) + Vector3(0, 0.3, 0)
		g.range_rooms = ["R4", "R8"]
		ecosystem.add_child(g)
	# aranhas de cinza: três matilhas
	for pk in [["R15", 3, 801], ["R17", 3, 802], ["R18", 3, 803]]:
		var c = _spot(pk[0], int(pk[2]), 1.2)
		if c == null:
			continue
		for k in int(pk[1]):
			var w2 := AshSpider.new()
			var a := k * TAU / float(pk[1])
			w2.position = (c as Vector3) + Vector3(cos(a) * 1.5, 0.3, sin(a) * 1.5)
			w2.pack = "cinza_%s" % pk[0]
			w2.den = c
			w2.range_rooms = [pk[0]]
			ecosystem.add_child(w2)
	# morcegos de cinza: na fumaça do pântano e do cinzeiro
	for fl in [["R9", 3, 811], ["R9", 3, 812], ["R18", 3, 813]]:
		var home_ = _spot(fl[0], int(fl[2]), 1.0)
		if home_ == null:
			continue
		for k in int(fl[1]):
			var b := AshBat.new()
			b.position = (home_ as Vector3) + Vector3(randf_range(-2, 2), Bat.ROOST_Y, randf_range(-1.5, 1.5))
			b.den = home_
			b.flock = "cinza_%d" % int(fl[2])
			b.range_rooms = [fl[0], "R18" if fl[0] == "R9" else "R9"]
			ecosystem.add_child(b)
			b.home = home_
	# a rainha
	if not GameState.flags.has("r12_rainha"):
		queen = QueenSalamander.new()
		queen.position = Vector3(ARENA.x, 0.3, ARENA.y + 3.0)
		queen.arena_center = Vector3(ARENA.x, 0, ARENA.y)
		queen.range_rooms = ["R12"]
		queen.den = Vector3(ARENA.x, 0, ARENA.y)
		ecosystem.add_child(queen)
		add_trigger(Rect2(ARENA - Vector2(11, 8), Vector2(22, 16)), _on_arena)
	add_trigger(Rect2(CHIMNEY_END - Vector2(3, 3), Vector2(6, 6)), _on_chimney)
	add_trigger(Rect2(DOWN - Vector2(2.5, 2.2), Vector2(2.5, 4.4)), _on_descent)
	# fungos de cinza (pouca luz fora do rio)
	for fz: Vector2 in [R1_C + Vector2(-5, 2), Vector2(-8, -26), Vector2(-10, 40), R6_C + Vector2(4, -4), Vector2(104, -48),
			R9_C + Vector2(2, -5), Vector2(184, -12), R11_C + Vector2(2, 2), Vector2(30, 58), R4_C + Vector2(-6, 0), Vector2(97, 2), Vector2(72, 27)]:
		if cave.is_floor(fz, 0.4):
			add_fungus(Vector3(fz.x, 0, fz.y), Color(1.0, 0.6, 0.25))
	# coletáveis
	var items := [["cristal_fogo", "cristal_fogo_r10", Vector3(R10_C.x, 0, R10_C.y)],
		["fragmento", "fragmento_r3", Vector3(ISLANDS[1].x + 0.8, 0, ISLANDS[1].y)]]
	for it in [["fragmento", "R15", 41], ["fragmento", "R16", 42], ["fragmento", "R17", 43], ["fragmento", "R6", 44],
			["fragmento", "R18", 45], ["fragmento", "R4", 46], ["cristal_pv", "R16", 47], ["cristal_en", "R17", 48],
			["cristal_seda", "R15", 49], ["presa", "R1", 50], ["presa", "R9", 51], ["presa", "R8", 52]]:
		var p = _spot(it[1], int(it[2]), 1.0)
		if p != null:
			items.append([it[0], "%s_%s" % [it[0], String(it[1]).to_lower()], p])
	for it in items:
		if GameState.flags.has(it[1]):
			continue
		var pk2 := Pickup.new(it[0], it[1])
		pk2.position = it[2]
		add_child(pk2)
	var note := Note.new([
		"Marcas de martelo na bigorna. Martelo grande, do tamanho de uma aranha inteira.",
		"Nos moldes, a mesma espiral da sua runa, só que gravada em brasa.",
		"Quem fazia golems aqui também conhecia a espiral."], "r4_bigorna", "papel")
	note.position = _snap(R4_C + Vector2(-2, -5), 0.6)
	add_child(note)


func _spawn_lurker(c: Creature, near: Vector2, r: float) -> void:
	var q = _lava_spot(near, r)
	if q == null:
		c.free()
		return
	c.position = q
	ecosystem.add_child(c)


func _build_nest() -> void:
	var egg := Fx.mat(Color(1.0, 0.45, 0.15), 1.6)
	var p = _spot("R6", 790, 1.4)
	if p == null:
		return
	for k in 7:
		var e := Fx.sphere(0.22, egg)
		e.scale = Vector3(1.0, 1.25, 1.0)
		e.position = (p as Vector3) + Vector3(cos(k * 0.9) * 0.7, 0.25, sin(k * 0.9) * 0.7)
		add_child(e)


func _on_rested(_c: Node) -> void:
	_spawn_food()


func _spawn_food() -> void:
	## Besouros-brasa: a comida fácil do rio. Descansar repõe os bandos.
	var alive := {}
	for c in World.creatures:
		if is_instance_valid(c) and c is EmberBeetle and not (c as Creature).dead:
			var g := String(c.get_meta("grupo", ""))
			alive[g] = int(alive.get(g, 0)) + 1
	for g in [["R1", 5, ["R1", "R16"], 601], ["R8", 3, ["R8"], 602], ["R17", 4, ["R17", "R6"], 603], ["R9", 4, ["R9", "R18"], 604],
			["R19", 3, ["R19", "R20"], 605], ["R2", 2, ["R2", "R1"], 606]]:
		var at = _spot(g[0], int(g[3]), 1.2)
		if at == null:
			continue
		var n := int(g[1]) - int(alive.get(g[0], 0))
		for k in n:
			var b := EmberBeetle.new()
			var a := k * TAU / float(g[1])
			b.position = (at as Vector3) + Vector3(cos(a) * 1.3, 0.3, sin(a) * 1.3)
			b.range_rooms = g[2]
			b.set_meta("grupo", g[0])
			ecosystem.add_child(b)


func _spot(room_id: String, seed_: int, min_clear: float = 1.0) -> Variant:
	if World.nav == null:
		return null
	var cells: Array = World.nav.room_cells.get(room_id, [])
	var ok: Array = []
	for c in cells:
		var cp := World.nav.center_of(c)
		if cave.floor_value(Vector2(cp.x, cp.z)) >= min_clear:
			ok.append(cp)
	if ok.is_empty():
		ok = cells.map(func(c): return World.nav.center_of(c))
	if ok.is_empty():
		return null
	var r := RandomNumberGenerator.new()
	r.seed = seed_
	var p: Vector3 = ok[r.randi() % ok.size()]
	return Vector3(p.x, 0.0, p.z)


# ---------------------------------------------------------------- calor, fios queimando, gêiseres

func on_player_fell(p: Player) -> void:
	## Aqui todo buraco é lava: sai pela beirada, queimada.
	p.lava_fall()


func is_lava(q: Vector2) -> bool:
	return cave.is_pit(q)


func on_island(p: Vector3) -> bool:
	for q: Vector2 in ISLANDS:
		if Vector2(p.x, p.z).distance_to(q) < ISLAND_R + 0.2:
			return true
	return false


func _physics_process(delta: float) -> void:
	if player == null or player.dead:
		return
	# calor: perto da lava (até 3 m) e brasa nas ilhas
	_heat_check -= delta
	if _heat_check <= 0.0:
		_heat_check = 0.15
		_near_lava = false
		var pp := Vector2(player.global_position.x, player.global_position.z)
		for rr: float in [1.6, 3.0]:
			for k in 8:
				if is_lava(pp + Vector2(cos(k * TAU / 8.0), sin(k * TAU / 8.0)) * rr):
					_near_lava = true
					break
			if _near_lava:
				break
		var room := World.nav.room_at(player.global_position) if World.nav != null else ""
		var ash := 2.0 if room == "R9" or room == "R18" else 0.0
		if ash != player.sight_penalty:
			player.sight_penalty = ash
			player.refresh_sight()
			if ash > 0.0:
				GameState.say_once("r9_cinza", "Cinza no olho. Cinza na boca. Cinza em TUDO.")
	if not player.on_strand and on_island(player.global_position):
		player.apply_heat(14.0, delta, true)
		if player.resist_fire < 3:
			GameState.say_once("r3_brasa", "AI! A pedra tá em brasa! Preciso de mais Resistência a Fogo pra ficar aqui!")
	elif _near_lava:
		player.apply_heat(2.5, delta)
	_tick_strands(delta)
	_tick_geysers(delta)


func _tick_strands(delta: float) -> void:
	## Fio sobre a lava aguenta 8 s; depois queima.
	_burn_check -= delta
	if _burn_check > 0.0:
		return
	_burn_check = 0.25
	for s in _burning.keys():
		if not is_instance_valid(s):
			_burning.erase(s)
	for s in WebNetwork.strands.duplicate():
		if not is_instance_valid(s):
			continue
		var ws := s as WebStrand
		var over := false
		for k in range(1, 6):
			var q := ws.a_pos.lerp(ws.b_pos, k / 6.0)
			if is_lava(Vector2(q.x, q.z)):
				over = true
				break
		if not over:
			continue
		var t := float(_burning.get(s, 0.0)) + 0.25
		_burning[s] = t
		if t >= 8.0:
			_burning.erase(s)
			var mid := (ws.a_pos + ws.b_pos) * 0.5
			WebNetwork.remove_strand(s)
			EventBus.message.emit("O fio sobre a lava queimou!")
			_flame(mid)
		elif t >= 5.5 and fmod(t, 1.0) < 0.26:
			_flame((ws.a_pos + ws.b_pos) * 0.5 + Vector3(0, 0.2, 0), 0.25)


func _flame(at: Vector3, size_k: float = 0.5) -> void:
	var m := Fx.mat(Color(1.0, 0.55, 0.15), 3.0, true, 0.8)
	var f := Fx.sphere(size_k, m)
	add_child(f)
	f.global_position = at + Vector3(0, 0.4, 0)
	var tw := f.create_tween()
	tw.tween_property(f, "scale", Vector3.ONE * 2.2, 0.45)
	tw.tween_callback(f.queue_free)


func strand_burn_time(s: Node) -> float:
	return float(_burning.get(s, 0.0))


func _tick_geysers(delta: float) -> void:
	## Cada gêiser: 4,5 s de ciclo; borbulha 1 s, estoura 0,8 s (arremessa e queima).
	_geyser_t += delta
	for k in _geysers.size():
		var g: Node3D = _geysers[k]
		var ph := fmod(_geyser_t + k * 0.9, 4.5)
		var bubbling := ph >= 2.7 and ph < 3.7
		var erupting := ph >= 3.7
		(g.get_meta("bubble") as Node3D).visible = bubbling
		(g.get_meta("jet") as Node3D).visible = erupting
		if not erupting:
			g.set_meta("hit", false)
			continue
		if bool(g.get_meta("hit")) or player.on_strand or player.invuln > 0.0:
			continue
		var d := Fx.flat_dist(player.global_position, g.global_position)
		if d < 1.5:
			g.set_meta("hit", true)
			var away := (player.global_position - g.global_position)
			away.y = 0.0
			away = away.normalized() if away.length() > 0.05 else Vector3(1, 0, 0)
			if player.take_damage(12.0 * maxf(0.4, player.fire_mult()), null, false):
				player.external_velocity = away * 13.0
				player.shake(0.8)
				EventBus.message.emit("O gêiser te arremessou!")


# ---------------------------------------------------------------- chefe e fim do ato

func _on_arena(body: Node3D) -> void:
	if body is Player and queen != null and is_instance_valid(queen) and not queen.awake:
		queen.wake()


func _on_creature_died(c: Node) -> void:
	if c is QueenSalamander:
		GameState.flags["r12_rainha"] = true
		EventBus.big_message.emit("A Salamandra-rainha caiu")
		GameState.say_once("rainha_morta", "Caiu. E a lava... tá apagando. Sem ela, o rio esfria.")
		cool_moat(true)


func _on_descent(body: Node3D) -> void:
	## Descer de volta para o Abismo (os dois andares são abertos).
	if _ending or not (body is Player) or player.autopilot:
		return
	_ending = true
	player.autopilot = true
	player.auto_target = Vector3(DOWN.x - 3.5, 0.1, DOWN.y)
	hud.cinematic = true
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	go_to_layer(ABISMO, "Abismo", "Descendo a Rampa quente.", "rio")


const GALERIAS_CACADA := "res://world/layers/galerias_cacada.tscn"


func _on_chimney(body: Node3D) -> void:
	## Fim do Ato 3: ela sobe a Chaminé e sai nas Galerias (Ato 4: a caçada). Não tem volta.
	if _ending or not (body is Player):
		return
	_ending = true
	GameState.flags["ato3_fim"] = true
	player.autopilot = true
	player.auto_target = Vector3(CHIMNEY_END.x + 1.0, 0.1, CHIMNEY_END.y + 1.0)
	player.auto_run = true
	hud.cinematic = true
	GameState.say_once("r14_topo", "Ar fresco. Cheiro de musgo. São as Galerias. Eu voltei.")
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	go_to_layer(GALERIAS_CACADA, "Fim do Ato 3", "De volta às Galerias. Mas agora alguém está caçando você.", "rio")
