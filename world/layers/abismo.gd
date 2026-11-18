extends LayerBase
## A — Abismo (Ato 2). Caverna orgânica de um andar (autômato celular, como as Galerias) com
## as câmaras de trava e de chefe feitas à mão. Quase breu: só a runa, poucos fungos e cristais.
##
##   Oeste (gerado): A1 Fundo da queda, A2 Ossário, A15 Galeria dos ecos mortos
##   Meio (à mão):   A3 Trilha do Colosso (o dragão faz a ronda), rachaduras-esconderijo,
##                   A4 Fenda do refúgio (a toca: 4 frestas), A10 Câmara de cristal (segredo)
##   Sul (gerado):   A18 Fosso dos besouros, A19 Beco sem volta (só por uma rachadura da trilha)
##   Norte (gerado): A5 Lago negro (a pérola da ilha: Resistência a Escuridão), A6 Floresta de
##                   estalagmites (dezenas de pilares: sobe a Tecelagem), A7 Ninho dos
##                   escorpiões, A16 Fosso das raízes
##   A8 Cortina viva (túnel de morcegos gigantes: runa apagada ou Pulso Espiral) liga a ponta
##   leste da Trilha à Câmara de cristal.
##   A9 Abismo duplo: fenda de 16 m, pilares a 17,6 m (Tecelagem 5), entre o norte e o nordeste.
##   Nordeste (gerado): A11 Santuário afundado (feito à mão: ruínas com a espiral da runa),
##                   A17 Raízes negras
##   Leste (à mão):  A12 Toca da Serpente-cega (chefe) → A13 Poço de vapor → A14 Rampa quente
## Coordenadas em metros: x leste, z sul.

var cave: CaveBuilder
var org: OrganicCave
var colossus: Colossus
var serpent: Serpent
var curtain: BatCurtain
const SEED := 57
const STONE := Color(0.18, 0.18, 0.24)
const ROUTE := [Vector2(46, 13), Vector2(62, 8), Vector2(80, 14), Vector2(98, 8), Vector2(116, 12), Vector2(124, 12)]
const TRAIL_W := 11.0
## Rachaduras da Trilha: (metros ao longo da rota, lado: -1 norte / +1 sul)
const NICHES := [[11.0, -1.0], [27.0, 1.0], [47.0, 1.0], [62.0, -1.0], [74.0, 1.0]]
const DEN_C := Vector2(84, -6)
const DEN_R := 4.3
const A2_C := Vector2(30, 8)
const CARCASSES := [Vector2(26, 4), Vector2(33, 11.5), Vector2(27, 12), Vector2(34, 4)]
const LAKE_C := Vector2(58, -33)
const ISLAND := Vector2(60.5, -33)
const STEP_ROCK := Vector2(53.0, -34.0)
const A6_C := Vector2(87, -40)
const A7_C := Vector2(62, -55)
const GORGE_Z := -38.0
const GORGE_X := 118.0
const GORGE_W := 16.0           ## 16 m de buraco: âncoras a 17,6 m (Tecelagem 5)
const A10_C := Vector2(106, -7)
const A11_C := Vector2(152, -40)
const ARENA := Vector2(156, 0)
const A13_C := Vector2(160, 26)
const PLUG := Vector3(158.6, 0, 13.0)   ## a cauda enrolada da Serpente tapa o poço
const RAMP_END := Vector2(162, 56)
const CURTAIN_A := Vector3(131, 0, 1)
const CURTAIN_B := Vector3(127, 0, -6)
## Zonas geradas: o resto é rocha (nenhum atalho pula a Trilha, a Cortina ou o Abismo duplo).
const ZONES := [Rect2(-16, -26, 60, 66), Rect2(44, -64, 64, 50), Rect2(128, -64, 52, 48), Rect2(50, 27, 72, 36)]
var niche_spots: Array = []              ## centro de cada rachadura (Vector3)
var niche_shapes: Array = []
var _plug: StaticBody3D
var _plug_vis: Node3D
var _vents: Array = []
var _vent_t := 0.0
var _ending := false


# ---------------------------------------------------------------- câmaras

func _configure() -> void:
	layer_id = "A"
	layer_name = "Abismo"
	layer_subtitle = "Ato 2 · O fundo da Fenda"
	spawn_point = Vector3(0.0, 0.1, 0.0)
	# voltando do Rio de Brasa: desce a Rampa quente
	entries = {"rio": {"spawn": Vector3(161.5, 0.1, 46.0), "from": Vector3(162.0, 0.1, 52.5)}}
	ambient_color = Color(0.16, 0.18, 0.3)
	ambient_energy = 0.08
	fog_color = Color(0.0, 0.0, 0.015)
	niche_spots.clear()
	for n in NICHES:
		var c := _niche_center(float(n[0]), float(n[1]))
		niche_spots.append(Vector3(c.x, 0.0, c.y))
	rooms = [
		{"id": "A1", "name": "Fundo da queda", "checkpoint": true, "label_only": true, "open_r": 7.5,
			"shapes": [CaveBuilder.blob(Vector2(0, 0), 6.0, 0.0)],
			"line_id": "a1_fundo", "line": "...Tô viva. Acho. Tá TUDO escuro aqui embaixo."},
		{"id": "A2", "name": "Ossário", "checkpoint": true, "label_only": true, "open_r": 9.5,
			"shapes": [CaveBuilder.blob(A2_C, 6.0, 0.0)],
			"line_id": "a2_ossos", "line": "Ossos. Muitos ossos. E... alguma coisa roendo eles."},
		{"id": "A3", "name": "Trilha do Colosso", "shapes": [CaveBuilder.path(ROUTE, TRAIL_W, 0.8)],
			"hint": "Algo enorme anda por este corredor. Ele sente o chão: correr ou andar num fio perto dele chama atenção. Parada, de lado e com a runa apagada (F), ele passa. As rachaduras nas paredes são esconderijo.",
			"line_id": "a3_trilha", "line": "Esse corredor é largo demais. Quem precisa de um corredor desse tamanho?"},
		{"id": "A4", "name": "Fenda do refúgio", "shapes": [CaveBuilder.blob(DEN_C, DEN_R, 0.5)],
			"hint": "Uma câmara pequena, quatro frestas. Teça o casulo central (C, 30 de Seda) para fazer dela sua toca no Abismo.",
			"line_id": "a4_refugio", "line": "Uma frestinha onde nada grande cabe. Isso. ISSO. Aqui é meu."},
		{"id": "A5", "name": "Lago negro", "shapes": [CaveBuilder.ellipse(LAKE_C, 13.0, 9.5, 0.0, 1.0)],
			"hint": "Água preta e parada. Algo enorme se move embaixo. Alguma coisa brilha na ilha: uma corrente de fios até lá, pela pedrinha.",
			"line_id": "a5_lago", "line": "Essa água... mexeu. A água MEXEU."},
		{"id": "A6", "name": "Floresta de estalagmites", "label_only": true, "open_r": 11.0,
			"shapes": [CaveBuilder.blob(A6_C, 6.0, 0.0)],
			"hint": "Pilares para todo lado. Tecer muitos fios sobe a Tecelagem: fios mais longos (Tecelagem 5 = 18 m).",
			"line_id": "a6_floresta", "line": "Uma floresta de pedra. Dá pra tecer uma cidade inteira aqui."},
		{"id": "A7", "name": "Ninho dos escorpiões", "label_only": true, "open_r": 7.5,
			"shapes": [CaveBuilder.blob(A7_C, 6.0, 0.0)],
			"hint": "Escorpiões-de-obsidiana sentem o chão. O ferrão envenena; a carne também, mas quem come aguenta mais veneno.",
			"line_id": "a7_ninho", "line": "Estalos. Pinças. Ferrões. Eu odeio esse lugar com todas as minhas oito pernas."},
		{"id": "A8", "name": "Cortina viva",
			"shapes": [CaveBuilder.path([Vector2(125, 9), Vector2(131, 2), Vector2(127, -6), Vector2(118, -7.5), Vector2(110, -7)], 3.4, 0.3)],
			"line_id": "a8_tunel", "line": "O teto tá... respirando?"},
		{"id": "A9", "name": "Abismo duplo",
			"shapes": [CaveBuilder.path([Vector2(102, GORGE_Z), Vector2(134, GORGE_Z)], 11.0, 0.5)],
			"hint": "Uma fenda larga demais. Do outro lado, pilares a quase 18 m: só com Tecelagem 5.",
			"line_id": "a9_fenda", "line": "Dezoito metros de nada. Meus fios não chegam. Ainda."},
		{"id": "A10", "name": "Câmara de cristal", "shapes": [CaveBuilder.blob(A10_C, 5.5, 0.6)],
			"hint": "Paredes de cristal afiado: encostar corta. A fresta a oeste volta para a toca.",
			"line_id": "a10_cristal", "line": "Tudo brilhando... e tudo cortando. Lindo e mortal. Típico."},
		{"id": "A11", "name": "Santuário afundado", "checkpoint": true, "shapes": [CaveBuilder.blob(A11_C, 8.0, 1.0)],
			"hint": "Ruínas afundadas. A espiral gravada no chão é igual à da sua runa. Aperte E nas pedras escritas.",
			"line_id": "a11_santuario", "line": "Essa espiral... é a MINHA espiral. Quem fez isso?"},
		{"id": "A12", "name": "Toca da Serpente-cega", "shapes": [CaveBuilder.ellipse(ARENA, 13.0, 10.0, 0.0, 0.8)],
			"line_id": "a12_toca", "line": "Não respira. Não pisa forte. Não pensa alto."},
		{"id": "A13", "name": "Poço de vapor", "shapes": [CaveBuilder.blob(A13_C, 6.0, 0.8)],
			"hint": "O vapor sobe em jatos: espere o jato acabar e passe.",
			"line_id": "a13_poco", "line": "O ar tá quente. Quente de verdade. Tem alguma coisa queimando lá em cima."},
		{"id": "A14", "name": "Rampa quente",
			"shapes": [CaveBuilder.path([Vector2(160, 30), Vector2(166, 42), Vector2(162, 56)], 4.4, 0.4)],
			"line_id": "a14_rampa", "line": "Subindo. Finalmente, subindo."},
		# nomes das partes geradas
		{"id": "A15", "name": "Galeria dos ecos mortos", "label_only": true, "open_r": 5.5, "shapes": [CaveBuilder.blob(Vector2(10, 28), 5.0, 0.0)],
			"line_id": "a15_ecos", "line": "Nenhum som volta daqui. Nem o meu."},
		{"id": "A16", "name": "Fosso das raízes", "label_only": true, "open_r": 5.5, "shapes": [CaveBuilder.blob(Vector2(100, -56), 5.0, 0.0)]},
		{"id": "A17", "name": "Raízes negras", "label_only": true, "open_r": 6.0, "shapes": [CaveBuilder.blob(Vector2(168, -54), 5.0, 0.0)]},
		{"id": "A18", "name": "Fosso dos besouros", "label_only": true, "open_r": 7.5, "shapes": [CaveBuilder.blob(Vector2(90, 45), 5.0, 0.0)],
			"line_id": "a18_fosso", "line": "Um buraco escondido atrás da rachadura. E tem comida andando!"},
		{"id": "A19", "name": "Beco sem volta", "label_only": true, "open_r": 5.0, "shapes": [CaveBuilder.blob(Vector2(62, 52), 5.0, 0.0)]},
	]
	locks = [
		{"type": "cortina", "pos": Vector3(129, 0, -2.5)},
		{"type": "abismo_longo", "pos": Vector3(GORGE_X, 0, GORGE_Z)},
	]


func _room(id: String) -> Array:
	for r in rooms:
		if r["id"] == id:
			return r["shapes"]
	return []


func _niche_center(at: float, side: float) -> Vector2:
	var p := _route_point(at)
	var n := _route_normal(at)
	return p + n * side * (TRAIL_W * 0.5 + 2.6)


func _route_point(d: float) -> Vector2:
	for i in range(1, ROUTE.size()):
		var a: Vector2 = ROUTE[i - 1]
		var b: Vector2 = ROUTE[i]
		var l := a.distance_to(b)
		if d <= l:
			return a.lerp(b, d / l)
		d -= l
	return ROUTE[ROUTE.size() - 1]


func _route_normal(d: float) -> Vector2:
	## Normal "para o sul" (z+) do trecho da rota em d.
	var a := _route_point(maxf(0.0, d - 0.5))
	var b := _route_point(d + 0.5)
	var t := (b - a).normalized()
	var n := Vector2(-t.y, t.x)
	return n if n.y >= 0.0 else -n


# ---------------------------------------------------------------- geometria

func _build_level() -> void:
	cave = CaveBuilder.new()
	cave.floor_color = Color(0.14, 0.14, 0.19)
	cave.rock_color = Color(0.07, 0.07, 0.1)
	cave.noise.seed = 47
	cave.rooms = rooms
	cave.tunnels = [
		CaveBuilder.path([Vector2(84, 8.5), Vector2(83.4, 3.5), Vector2(84, -3.0)], 1.8, 0.15),         # rachadura Trilha → A4
		CaveBuilder.path([Vector2(84, -9.0), Vector2(85, -16), Vector2(86, -22)], 2.4, 0.3),             # A4 → norte (A6)
		CaveBuilder.path([Vector2(80.5, -6.5), Vector2(70, -10), Vector2(64, -17), Vector2(62, -24)], 2.4, 0.3),  # A4 → Lago negro
		CaveBuilder.path([Vector2(87.5, -6.0), Vector2(94, -5.5), Vector2(101, -6.5)], 1.5, 0.1),        # fresta secreta A4 → A10
		CaveBuilder.path([Vector2(154, -26), Vector2(155, -16), Vector2(156, -9)], 3.6, 0.4),            # nordeste → arena
		CaveBuilder.path([Vector2(158, 8), Vector2(159, 15), Vector2(160, 21)], 3.2, 0.3),               # arena → poço (tapado)
		CaveBuilder.path([Vector2(160, 30), Vector2(160, 24)], 4.0, 0.3),
	]
	niche_shapes.clear()
	for n in NICHES:   # rachaduras: gargalo estreito e um buraquinho no fim
		var at := float(n[0])
		var side := float(n[1])
		var p := _route_point(at)
		var nn := _route_normal(at) * side
		var neck := CaveBuilder.path([p + nn * (TRAIL_W * 0.5 - 1.0), p + nn * (TRAIL_W * 0.5 + 2.0)], 1.5, 0.1)
		var hole := CaveBuilder.blob(p + nn * (TRAIL_W * 0.5 + 2.6), 1.6, 0.25)
		cave.tunnels.append(neck)
		cave.tunnels.append(hole)
		niche_shapes.append(neck)
		niche_shapes.append(hole)
	# a 3ª rachadura (sul) continua: uma fresta comprida até o Fosso dos besouros
	var c3 := _niche_center(47.0, 1.0)
	cave.tunnels.append(CaveBuilder.path([c3, c3 + Vector2(1.5, 7.0), Vector2(c3.x + 1.0, 33.0)], 1.5, 0.15))
	cave.chasms = [
		CaveBuilder.ellipse(LAKE_C, 8.5, 6.0, 0.0, 0.4),                                            # Lago negro
		CaveBuilder.path([Vector2(GORGE_X, -60), Vector2(GORGE_X, -16)], GORGE_W, 0.0),             # Abismo duplo
	]
	cave.bridges = [CaveBuilder.blob(ISLAND, 2.3, 0.3), CaveBuilder.blob(STEP_ROCK, 1.3, 0.15)]
	_generate_organic()
	map_grid = cave.build(self)
	cave.scatter_decor(self, 9)
	chasms = [{"rect": Rect2(LAKE_C - Vector2(9.5, 7.0), Vector2(19.0, 14.0)), "mode": "volta", "name": "o lago negro"}]
	_build_anchors()
	_build_bones()
	_build_lake()
	_build_crystal_room()
	_build_sanctuary()
	_build_arena()
	_build_well()
	var far := OmniLight3D.new()   # lá em cima, muito longe: o buraco por onde ela caiu
	far.light_color = Color(0.45, 0.55, 1.0)
	far.omni_range = 10.0
	far.light_energy = 0.35
	far.position = Vector3(0, 14, -2)
	add_child(far)


func _in_zone(p: Vector2) -> bool:
	for z: Rect2 in ZONES:
		if z.has_point(p):
			return true
	return false


func _generate_organic() -> void:
	## Como nas Galerias: autômato celular só dentro das zonas; câmaras feitas à mão entram
	## fixas; faixas de rocha em volta da Trilha (fora do oeste), das rachaduras e das câmaras
	## de trava/chefe para nenhum salão gerado virar atalho.
	org = OrganicCave.new(Rect2(-18, -66, 200, 132), SEED)
	org.lock_rock(func(p): return not _in_zone(p))
	org.fix_open(func(p): return cave.open_at(p))
	var trail: Dictionary = _room("A3")[0]
	org.protect_band(func(p): return cave._sdf(trail, p, 0.0) if p.x > 46.0 else CaveBuilder.NO, 4.0)
	for sh in niche_shapes:
		org.protect_band(func(p): return cave._sdf(sh, p, 0.0), 3.0)
	for id in ["A8", "A10", "A12", "A13", "A14"]:
		for sh in _room(id):
			org.protect_band(func(p): return cave._sdf(sh, p, 0.0), 3.0)
	org.scatter(0.5)
	org.smooth(6)
	for r in rooms:
		if r.get("label_only", false):
			org.open_blob((r["shapes"][0] as Dictionary)["c"], float(r.get("open_r", 5.0)))
	org.connect_all(60)
	org.chasm_pockets(0.42, 3.4, 0.07)
	for keep: Vector2 in [Vector2(0, 0), A2_C, A6_C, A7_C, Vector2(90, 45)]:
		_no_pits(keep, 8.0)
	cave.tunnels.append(org.open_shape(0.5))
	cave.chasms.append(org.chasm_shape(0.25))


func _no_pits(c: Vector2, r: float) -> void:
	## Nada de buraco onde ela pousa e nos salões principais.
	var cc := org.cell_of(c)
	var ri := int(ceil(r))
	for j in range(cc.y - ri, cc.y + ri + 1):
		for i in range(cc.x - ri, cc.x + ri + 1):
			if org.inside(i, j) and org.grid[org.idx(i, j)] == 2 and org.center_of(i, j).distance_to(c) <= r:
				org.grid[org.idx(i, j)] = 1


func _snap(p: Vector2, margin: float = 0.6) -> Vector3:
	## Chão firme mais perto de p.
	if cave.is_floor(p, margin):
		return Vector3(p.x, 0, p.y)
	for r in range(1, 14):
		for k in 16:
			var q := p + Vector2(cos(k * TAU / 16.0), sin(k * TAU / 16.0)) * float(r) * 0.6
			if cave.is_floor(q, margin):
				return Vector3(q.x, 0, q.y)
	var f := org.nearest_floor(p)
	return Vector3(f.x, 0, f.y)


func _build_anchors() -> void:
	# A1: pilares para os primeiros fios
	for i in 4:
		var ang := i * TAU / 4.0 + 0.4
		add_anchor("A1_%d" % i, _snap(Vector2(cos(ang) * 4.5, sin(ang) * 4.5), 0.8), 3.0, 0.45, STONE)
	# A2: colunas de osso também seguram fio
	for q: Vector2 in [Vector2(24, 9), Vector2(32, 2.5), Vector2(36, 10), Vector2(28, 14.5)]:
		add_anchor("A2_%d_%d" % [int(q.x), int(q.y)], _snap(q, 0.7), 3.2, 0.4, Color(0.62, 0.6, 0.55))
	# A4: quatro pilares na toca
	for i in 4:
		var ang := i * TAU / 4.0 + PI * 0.25
		add_anchor("Toca_%d" % i, Vector3(DEN_C.x + cos(ang) * (DEN_R - 1.3), 0, DEN_C.y + sin(ang) * (DEN_R - 1.3)), 3.0, 0.4, STONE)
	# A6: a floresta (pilares a cada ~4,6 m: tecer dezenas de fios aqui sobe a Tecelagem)
	var r := RandomNumberGenerator.new()
	r.seed = 606
	var k := 0
	for j in range(-4, 5):
		for i in range(-4, 5):
			var q := A6_C + Vector2(i * 4.6 + r.randf_range(-1.2, 1.2), j * 4.6 + r.randf_range(-1.2, 1.2))
			if q.distance_to(A6_C) > 15.0 or not cave.is_floor(q, 1.0):
				continue
			add_anchor("A6_%02d" % k, Vector3(q.x, 0, q.y), r.randf_range(2.6, 4.2), r.randf_range(0.3, 0.5), Color(0.24, 0.23, 0.3))
			k += 1
	# A7: a ronda dos escorpiões
	for q: Vector2 in [A7_C + Vector2(-4, -2), A7_C + Vector2(4, 1), A7_C + Vector2(0, 5)]:
		if cave.is_floor(q, 0.8):
			add_anchor("A7_%d_%d" % [int(q.x), int(q.y)], Vector3(q.x, 0, q.y), 2.8, 0.4, STONE)
	# A9: as bordas do Abismo duplo (17,6 m de uma à outra)
	for z: float in [GORGE_Z - 3.0, GORGE_Z + 3.0]:
		add_anchor("A9_o_%d" % int(z), Vector3(GORGE_X - GORGE_W * 0.5 - 0.8, 0, z), 3.4, 0.45, STONE)
		add_anchor("A9_l_%d" % int(z), Vector3(GORGE_X + GORGE_W * 0.5 + 0.8, 0, z), 3.4, 0.45, STONE)
	# A12: pilares da arena (fios para ficar quieta em cima)
	for i in 6:
		var ang := i * TAU / 6.0 + 0.3
		add_anchor("A12_%d" % i, Vector3(ARENA.x + cos(ang) * 8.2, 0, ARENA.y + sin(ang) * 6.0), 3.6, 0.5, STONE)
	# A11, A15, A18: alguns pilares
	for q: Vector2 in [A11_C + Vector2(-5, -3), A11_C + Vector2(5, -3), A11_C + Vector2(0, 5),
			Vector2(7, 28), Vector2(13, 30), Vector2(86, 43), Vector2(94, 47)]:
		if cave.is_floor(q, 0.8):
			add_anchor("P_%d_%d" % [int(q.x), int(q.y)], Vector3(q.x, 0, q.y), 3.0, 0.4, STONE)


func _build_bones() -> void:
	## Ossário: carcaças velhas (os besouros roem) e uma costela gigante de algo do tamanho do Colosso.
	var bone := Fx.mat(Color(0.7, 0.67, 0.6), 0.05)
	var old := Fx.mat(Color(0.32, 0.3, 0.24))
	for c: Vector2 in CARCASSES:
		var m := Node3D.new()
		m.position = _snap(c, 0.4)
		m.add_to_group("carcass")
		add_child(m)
		var hide_ := Fx.sphere(0.9, old)
		hide_.scale = Vector3(1.4, 0.4, 1.0)
		hide_.position.y = 0.2
		m.add_child(hide_)
		for k in 4:
			var rib := Fx.cylinder(0.06, 1.3, bone)
			rib.position = Vector3(-0.6 + k * 0.4, 0.45, 0.0)
			rib.rotation = Vector3(0.0, 0.0, 0.9 if k % 2 == 0 else -0.9)
			m.add_child(rib)
	var spine_y := 3.3
	for k in 5:
		var x := 27.5 + k * 1.5
		for sd: float in [-1.0, 1.0]:
			var prev := Vector3(x, 0.0, A2_C.y + sd * 3.1)
			for j in range(1, 7):
				var th := j * PI * 0.5 / 6.0
				var pt := Vector3(x + sin(th) * 0.3, spine_y * sin(th), A2_C.y + sd * 3.1 * cos(th))
				var w := 0.26 - j * 0.02
				var seg := Fx.box(Vector3(w, w, prev.distance_to(pt) + 0.08), bone)
				add_child(seg)
				Fx.orient_between(seg, prev, pt)
				prev = pt
	var sp0 := Vector3(26.5, spine_y, A2_C.y)
	for k in 6:
		var sp1 := Vector3(27.5 + k * 1.5, spine_y + 0.05 * sin(k * 1.3), A2_C.y)
		var vert := Fx.box(Vector3(0.34, 0.34, sp0.distance_to(sp1) + 0.1), bone)
		add_child(vert)
		Fx.orient_between(vert, sp0, sp1)
		sp0 = sp1
	var skull := Fx.sphere(1.2, bone)
	skull.scale = Vector3(1.0, 0.7, 1.6)
	skull.position = Vector3(25.0, 0.6, A2_C.y)
	add_child(skull)
	for sd: float in [-1.0, 1.0]:
		var socket := Fx.sphere(0.32, Fx.mat(Color(0.02, 0.02, 0.03)))
		socket.position = skull.position + Vector3(sd * 0.55, 0.35, -1.2)
		add_child(socket)


func _build_lake() -> void:
	## Lago negro: água preta, uma ilha com a pérola e algo enorme passando embaixo.
	var water := Fx.cylinder(1.0, 0.04, Fx.mat(Color(0.02, 0.03, 0.06), 0.15, false, 0.88))
	water.position = Vector3(LAKE_C.x, -0.8, LAKE_C.y)
	water.scale = Vector3(9.5, 1.0, 6.8)
	add_child(water)
	var shadow := LakeShadow.new()
	shadow.center = Vector3(LAKE_C.x, -0.9, LAKE_C.y)
	add_child(shadow)
	# corrente de fios: margem oeste → pedrinha → ilha
	add_anchor("A5_margem", _snap(Vector2(LAKE_C.x - 10.5, STEP_ROCK.y), 0.5), 3.0, 0.4, STONE)
	add_anchor("A5_pedra", Vector3(STEP_ROCK.x, 0, STEP_ROCK.y), 2.4, 0.35, STONE)
	add_anchor("A5_ilha", Vector3(ISLAND.x - 0.6, 0, ISLAND.y + 0.8), 3.0, 0.4, STONE)
	add_anchor("A5_leste", _snap(Vector2(LAKE_C.x + 10.5, LAKE_C.y + 1.0), 0.5), 3.0, 0.4, STONE)


func _build_crystal_room() -> void:
	## A10: paredes de cristal afiado (encostar corta) e muita luz fria.
	var m := Fx.mat(Color(0.5, 0.85, 1.0), 2.4, false, 0.9)
	for k in 14:
		var a := k * TAU / 14.0
		var q := A10_C + Vector2(cos(a), sin(a)) * 4.6
		if absf(wrapf(a - PI, -PI, PI)) < 0.6 or absf(wrapf(a, -PI, PI)) < 0.6:
			continue   # as duas passagens (fresta da toca a oeste, Cortina viva a leste) ficam livres
		if cave.is_floor(q, 0.2) and not cave.is_floor(A10_C + Vector2(cos(a), sin(a)) * 6.2, 0.2):
			var blade := Fx.box(Vector3(0.18, 1.6 + 0.4 * sin(k * 2.1), 0.7), m)
			blade.position = Vector3(q.x, 0.8, q.y)
			blade.rotation = Vector3(0.25 * sin(k), -a, 0.2)
			blade.add_to_group("crystal_blade")
			add_child(blade)
	var l := OmniLight3D.new()
	l.light_color = Color(0.5, 0.85, 1.0)
	l.omni_range = 8.0
	l.light_energy = 1.2
	l.position = Vector3(A10_C.x, 2.2, A10_C.y)
	add_child(l)


func _build_sanctuary() -> void:
	## A11: ruínas afundadas, colunas quebradas e a espiral da runa gravada no chão.
	var stone := Fx.mat(Color(0.32, 0.31, 0.36))
	var glow := Fx.mat(Color(0.45, 0.8, 1.0), 2.0, true)
	for k in 7:
		var a := k * TAU / 7.0
		var q := A11_C + Vector2(cos(a), sin(a)) * 6.2
		if not cave.is_floor(q, 0.5):
			continue
		var h := 1.2 + 1.4 * absf(sin(k * 1.7))
		var col := Fx.cylinder(0.45, h, stone)
		col.position = Vector3(q.x, h * 0.5 - 0.3, q.y)
		col.rotation.z = 0.12 * sin(k * 3.1)
		add_child(col)
	var prev := Vector3(A11_C.x, 0.04, A11_C.y)
	for k in 60:   # espiral de Arquimedes no chão, brilhando como a runa
		var a := k * 0.32
		var pt := Vector3(A11_C.x + cos(a) * a * 0.22, 0.04, A11_C.y + sin(a) * a * 0.22)
		var seg := Fx.box(Vector3(0.09, 0.02, prev.distance_to(pt) + 0.02), glow)
		add_child(seg)
		Fx.orient_between(seg, prev, pt)
		prev = pt
	var l := OmniLight3D.new()
	l.light_color = Color(0.45, 0.8, 1.0)
	l.omni_range = 7.0
	l.light_energy = 0.9
	l.position = Vector3(A11_C.x, 1.5, A11_C.y)
	add_child(l)


func _build_arena() -> void:
	## A12: chão liso e frio, ossos espalhados e a cauda dela enfiada no poço ao sul.
	var bone := Fx.mat(Color(0.6, 0.58, 0.52))
	var r := RandomNumberGenerator.new()
	r.seed = 1212
	for k in 10:
		var q := ARENA + Vector2(r.randf_range(-10, 10), r.randf_range(-7, 7))
		if cave.is_floor(q, 0.6):
			var b := Fx.cylinder(0.07, r.randf_range(0.6, 1.4), bone)
			b.position = Vector3(q.x, 0.08, q.y)
			b.rotation = Vector3(PI * 0.5, r.randf() * TAU, 0)
			add_child(b)
	if GameState.flags.has("a12_serpente"):
		return
	_plug = add_static_box(Vector3(4.4, 2.2, 2.4), PLUG + Vector3(0, 1.1, 0), Color(0.3, 0.29, 0.34))
	for c in _plug.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visible = false
	_plug_vis = Node3D.new()
	_plug_vis.position = PLUG
	add_child(_plug_vis)
	var skin := Fx.mat(Color(0.42, 0.4, 0.46))
	for k in 3:
		var tor := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.9 - k * 0.15
		tm.outer_radius = 2.1 - k * 0.3
		tor.mesh = tm
		tor.material_override = skin
		tor.position = Vector3(0, 0.45 + k * 0.6, 0)
		_plug_vis.add_child(tor)


func _build_well() -> void:
	## A13: jatos de vapor (machucam) e brilho vermelho vindo de cima (o Rio de Brasa).
	for q: Vector2 in [A13_C + Vector2(-2.5, -1.5), A13_C + Vector2(2.5, 0.5), A13_C + Vector2(-0.5, 3.0)]:
		var v := Node3D.new()
		v.position = Vector3(q.x, 0, q.y)
		add_child(v)
		var hole := Fx.cylinder(0.6, 0.05, Fx.mat(Color(0.25, 0.08, 0.04), 1.5))
		hole.position.y = 0.03
		v.add_child(hole)
		var steam := Fx.cylinder(0.7, 3.0, Fx.mat(Color(0.95, 0.92, 0.9), 0.6, true, 0.35))
		steam.position.y = 1.5
		steam.visible = false
		v.add_child(steam)
		v.set_meta("steam", steam)
		_vents.append(v)
	for q: Vector2 in [A13_C, Vector2(163, 42), RAMP_END]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.4, 0.15)
		l.omni_range = 9.0
		l.light_energy = 0.9 if q != RAMP_END else 2.0
		l.position = Vector3(q.x, 2.0, q.y)
		add_child(l)


# ---------------------------------------------------------------- bichos e coisas

func _populate() -> void:
	ecosystem.larva_target = 8
	ecosystem.frog_target = 0
	ecosystem.larva_spawns = []
	for id in ["A6", "A16", "A15", "A17", "A5", "A18"]:
		var p = _spot(id, 300 + String(id).hash() % 97, 1.0)
		if p != null:
			ecosystem.larva_spawns.append(p)
	_spawn_beetles()
	EventBus.rested.connect(_on_rested)
	EventBus.creature_died.connect(_on_creature_died)
	var route := PackedVector2Array()
	for q: Vector2 in ROUTE:
		route.append(q)
	colossus = Colossus.new().setup(route)
	add_child(colossus)
	colossus.alerted.connect(_on_colossus_alert)
	# A4: a toca do Abismo, quatro frestas
	den = Den.new().setup("A4", Vector3(DEN_C.x, 0.0, DEN_C.y), [
		{"pos": Vector3(84.0, 0.0, -1.4), "out": Vector3(0, 0, 1), "width": 2.2, "to": "A3"},
		{"pos": Vector3(84.2, 0.0, -10.6), "out": Vector3(0, 0, -1), "width": 2.6, "to": "A6"},
		{"pos": Vector3(79.6, 0.0, -6.9), "out": Vector3(-0.95, 0, -0.3).normalized(), "width": 2.6, "to": "A5"},
		{"pos": Vector3(88.6, 0.0, -6.0), "out": Vector3(1, 0, 0), "width": 1.8, "to": "A10"},
	], "Fenda do refúgio")
	den.inner_r = DEN_R - 0.4
	add_child(den)
	# A7: escorpiões
	for k in 3:
		var p = _spot("A7", 700 + k, 1.2)
		if p != null and not GameState.flags.has("escorpiao_%d" % k):
			var s := Scorpion.new()
			s.position = (p as Vector3) + Vector3(0, 0.3, 0)
			s.den = Vector3(A7_C.x, 0, A7_C.y)
			s.range_rooms = ["A7", "A6", "A16"] if k == 0 else ["A7"]
			s.set_meta("flag", "escorpiao_%d" % k)
			ecosystem.add_child(s)
	_build_nest()
	_populate_monsters()
	# A8: a Cortina viva
	curtain = BatCurtain.new().setup(CURTAIN_A, CURTAIN_B)
	add_child(curtain)
	# A12: a Serpente-cega
	if not GameState.flags.has("a12_serpente"):
		serpent = Serpent.new()
		serpent.position = Vector3(ARENA.x - 2.0, 0.3, ARENA.y + 4.0)
		serpent.arena_center = Vector3(ARENA.x, 0, ARENA.y)
		serpent.arena_r = 9.0
		ecosystem.add_child(serpent)
		add_trigger(Rect2(ARENA - Vector2(11, 8), Vector2(22, 16)), _on_arena)
	add_trigger(Rect2(RAMP_END - Vector2(3, 2), Vector2(6, 4)), _on_ramp_top)
	# pouca luz: fungos aqui e ali
	for fz in [[Vector2(-4.5, 3.5), 0], [Vector2(25.0, 3.0), 1], [Vector2(37.0, 13.5), 0], [DEN_C + Vector2(2.0, -1.5), 1],
			[LAKE_C + Vector2(-11.5, 4.0), 1], [A6_C + Vector2(-3, 9), 0], [A6_C + Vector2(8, -6), 1], [A7_C + Vector2(3, -3), 0],
			[Vector2(10, 28), 1], [Vector2(90, 45), 0], [Vector2(168, -54), 1], [Vector2(100, -56), 0]]:
		var q: Vector2 = fz[0]
		if cave.is_floor(q, 0.4):
			add_fungus(Vector3(q.x, 0, q.y), Color(0.45, 1.0, 0.6) if int(fz[1]) == 0 else Color(0.75, 0.5, 1.0))
	for k in niche_spots.size():   # cada rachadura tem um brilho fraco: dá para achá-las no escuro
		if k % 2 == 0:
			_add_crystal(niche_spots[k])
	_add_crystal(Vector3(70.0, 0, 6.0))
	_add_crystal(Vector3(106.0, 0, 15.0))
	_add_crystal(Vector3(GORGE_X - GORGE_W * 0.5 - 2.0, 0, GORGE_Z + 4.0))
	# coletáveis
	var items := [["fragmento", "fragmento_a2", Vector3(37.5, 0, 6.5)], ["fragmento", "fragmento_a3", niche_spots[3]],
		["cristal_seda", "cristal_seda_a3", niche_spots[1]], ["presa", "presa_a1", _snap(Vector2(-4.5, -3.0), 0.5)],
		["olho_escuro", "olho_escuro_a5", Vector3(ISLAND.x + 0.6, 0, ISLAND.y - 0.4)],
		["cristal_pv", "cristal_pv_a10", Vector3(A10_C.x, 0, A10_C.y)]]
	for it in [["fragmento", "A6", 41], ["fragmento", "A7", 42], ["fragmento", "A15", 43], ["fragmento", "A18", 44],
			["fragmento", "A17", 45], ["fragmento", "A16", 46], ["cristal_seda", "A16", 47], ["cristal_pv", "A18", 48],
			["presa", "A15", 49], ["presa", "A17", 50], ["presa", "A19", 51], ["cristal_en", "A19", 52]]:
		var p = _spot(it[1], int(it[2]), 1.0)
		if p != null:
			items.append([it[0], "%s_%s" % [it[0], String(it[1]).to_lower()], p])
	for it in items:
		if GameState.flags.has(it[1]):
			continue
		var pk := Pickup.new(it[0], it[1])
		pk.position = it[2]
		add_child(pk)
	# A11: as pedras escritas
	add_child(_note(Vector3(A11_C.x - 2.5, 0, A11_C.y - 4.5), "a11_pedra1", [
		"Uma pedra lisa, com marcas de garras finas. No meio, a mesma espiral da sua runa.",
		"Embaixo, riscos em fileira, como fios tecidos na pedra: alguém contava alguma coisa. Dias? Mudas?",
		"Na última fileira, uma espiral cortada ao meio. Como se a história tivesse parado aí."], "papel"))
	add_child(_note(Vector3(A11_C.x + 3.0, 0, A11_C.y + 3.5), "a11_pedra2", [
		"Um cristal pulsando devagar. Quando você chega perto, ele pulsa no mesmo ritmo da sua runa.",
		"Por um instante você vê fios: milhares, ligando o teto ao chão, e uma aranha enorme no meio.",
		"A visão some. O cristal volta a pulsar sozinho."], "cristal"))


func _populate_monsters() -> void:
	## O Abismo cheio (~60 bichos, como as Galerias): matilhas, mímicos, lesmas e morcegos gigantes.
	# Aranhas-lobo do breu: três matilhas nas partes geradas
	for pk in [["A15", 3, 901], ["A17", 4, 902], ["A16", 3, 903]]:
		var c = _spot(pk[0], int(pk[2]), 1.2)
		if c == null:
			continue
		for k in int(pk[1]):
			var w := WolfSpider.new()
			var a := k * TAU / float(pk[1])
			w.position = (c as Vector3) + Vector3(cos(a) * 1.5, 0.3, sin(a) * 1.5)
			w.pack = String(pk[0])
			w.den = c
			w.range_rooms = [pk[0]] if pk[0] != "A16" else ["A16", "A6", "A7"]
			ecosystem.add_child(w)
	# Mímicos: no meio dos pilares da Floresta, numa coluna do Santuário e no Beco sem volta
	var mim: Array = []
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for k in 30:
		if mim.size() >= 3:
			break
		var q := A6_C + Vector2(r.randf_range(-12, 12), r.randf_range(-12, 12))
		if not cave.is_floor(q, 1.2):
			continue
		var clear := true
		for an in WebNetwork.anchors.values():
			if Fx.flat_dist((an as Node3D).global_position, Vector3(q.x, 0, q.y)) < 1.6:
				clear = false
				break
		if clear:
			mim.append(Vector3(q.x, 0, q.y))
	for id in ["A11", "A19"]:
		var q2 = _spot(id, 950 + id.length(), 1.4)
		if q2 != null:
			mim.append(q2)
	for q3: Vector3 in mim:
		var m := Mimic.new()
		m.position = q3 + Vector3(0, 0.05, 0)
		ecosystem.add_child(m)
	# Lesmas de ácido: na margem do Lago negro, no Fosso das raízes e no Fosso dos besouros
	for sl in [["A5", 961], ["A5", 962], ["A16", 963], ["A18", 964]]:
		var q4 = _spot(sl[0], int(sl[1]), 1.4)
		if q4 != null:
			var s := AcidSlug.new()
			s.position = (q4 as Vector3) + Vector3(0, 0.3, 0)
			s.range_rooms = [sl[0]]
			ecosystem.add_child(s)
	# Morcegos gigantes: bandos caçando nos salões grandes (e por cima do Abismo duplo)
	for fl in [["A18", 3, ["A18", "A19"], 971], ["A9", 2, ["A9", "A6", "A16"], 972], ["A11", 3, ["A11", "A17"], 973]]:
		var home = _spot(fl[0], int(fl[3]), 1.0)
		if fl[0] == "A9":
			home = Vector3(GORGE_X - GORGE_W * 0.5 - 3.0, 0, GORGE_Z)
		if home == null:
			continue
		for k in int(fl[1]):
			var b := GiantBat.new()
			b.position = (home as Vector3) + Vector3(r.randf_range(-2.0, 2.0), Bat.ROOST_Y, r.randf_range(-1.5, 1.5))
			b.den = home
			b.flock = "gigante_%s" % fl[0]
			b.range_rooms = fl[2]
			ecosystem.add_child(b)
			b.home = home
	# um escorpião a mais, rondando o Beco sem volta
	var q5 = _spot("A19", 981, 1.2)
	if q5 != null and not GameState.flags.has("escorpiao_3"):
		var sc := Scorpion.new()
		sc.position = (q5 as Vector3) + Vector3(0, 0.3, 0)
		sc.range_rooms = ["A19", "A18"]
		sc.set_meta("flag", "escorpiao_3")
		ecosystem.add_child(sc)
	# mais dois escorpiões (Ossário e Raízes negras): veneno suficiente para a Viúva de Seda
	for e in [["A2", 982, "escorpiao_4", ["A2", "A1"]], ["A17", 983, "escorpiao_5", ["A17", "A11"]]]:
		var qe = _spot(e[0], e[1], 1.2)
		if qe != null and not GameState.flags.has(e[2]):
			var se := Scorpion.new()
			se.position = (qe as Vector3) + Vector3(0, 0.3, 0)
			se.range_rooms = e[3]
			se.set_meta("flag", e[2])
			ecosystem.add_child(se)


func _on_colossus_alert() -> void:
	GameState.flags["a3_colosso_visto"] = true


func _note(pos: Vector3, flag: String, pages: Array, look: String) -> Note:
	var n := Note.new(pages, flag, look)
	n.position = pos
	return n


func _build_nest() -> void:
	## Ninho dos escorpiões: monte de cascas e ovos escuros.
	var shell := Fx.mat(Color(0.12, 0.1, 0.14))
	var egg := Fx.mat(Color(0.3, 0.12, 0.35), 0.8)
	var nest := Node3D.new()
	nest.position = Vector3(A7_C.x, 0, A7_C.y)
	nest.add_to_group("nest")
	add_child(nest)
	for k in 9:
		var a := k * TAU / 9.0
		var s := Fx.sphere(0.35, shell)
		s.scale = Vector3(1.4, 0.4, 0.9)
		s.position = Vector3(cos(a) * 1.4, 0.1, sin(a) * 1.4)
		s.rotation.y = a
		nest.add_child(s)
	for k in 5:
		var e := Fx.sphere(0.18, egg)
		e.position = Vector3(cos(k * 1.3) * 0.5, 0.18, sin(k * 1.3) * 0.5)
		nest.add_child(e)


func _spot(room_id: String, seed_: int, min_clear: float = 1.0) -> Variant:
	## Ponto de chão dentro da câmara, longe das bordas (sempre o mesmo para a mesma semente).
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


func _add_crystal(at: Vector3) -> void:
	var m := Fx.mat(Color(0.45, 0.7, 1.0), 2.2)
	for k in 3:
		var c := Fx.cylinder(0.12, 0.6 + k * 0.25, m)
		(c.mesh as CylinderMesh).top_radius = 0.01
		c.position = at + Vector3((k - 1) * 0.22, 0.3 + k * 0.1, 0.0)
		c.rotation.z = (k - 1) * 0.35
		add_child(c)
	var l := OmniLight3D.new()
	l.light_color = Color(0.45, 0.7, 1.0)
	l.omni_range = 4.5
	l.light_energy = 0.7
	l.position = at + Vector3(0, 1.0, 0)
	add_child(l)


func _on_rested(_c: Node) -> void:
	_spawn_beetles()


func _spawn_beetles() -> void:
	## Bandos: Ossário (4 e 3), Fosso dos besouros (5), Raízes negras (3). Descansar repõe.
	var alive := {}
	for c in World.creatures:
		if is_instance_valid(c) and c is Beetle and not (c as Beetle).dead:
			var g := String(c.get_meta("grupo", ""))
			alive[g] = int(alive.get(g, 0)) + 1
	var groups := [["A2a", Vector3(CARCASSES[0].x, 0, CARCASSES[0].y), 4, ["A2"]],
		["A2b", Vector3(CARCASSES[2].x, 0, CARCASSES[2].y), 3, ["A2"]],
		["A18", _spot("A18", 81, 1.2), 5, ["A18", "A19"]], ["A17", _spot("A17", 82, 1.2), 3, ["A17", "A11"]],
		["A11", _spot("A11", 83, 1.2), 2, ["A11"]], ["A1", _spot("A1", 84, 1.2), 2, ["A1", "A15"]]]
	for g in groups:
		if g[1] == null:
			continue
		var at: Vector3 = g[1]
		var n := int(g[2]) - int(alive.get(g[0], 0))
		for k in n:
			var b := Beetle.new()
			var a := k * TAU / maxf(1.0, float(g[2]))
			b.position = at + Vector3(cos(a) * 1.4, 0.3, sin(a) * 1.4)
			b.range_rooms = g[3]
			b.set_meta("grupo", g[0])
			ecosystem.add_child(b)


# ---------------------------------------------------------------- eventos

func _on_arena(body: Node3D) -> void:
	if body is Player and serpent != null and is_instance_valid(serpent) and not serpent.awake:
		serpent.wake(body)


func _on_creature_died(c: Node) -> void:
	if c is Scorpion and c.has_meta("flag"):
		GameState.flags[String(c.get_meta("flag"))] = true
	if c is Serpent:
		GameState.flags["a12_serpente"] = true
		EventBus.big_message.emit("A Serpente-cega caiu")
		GameState.say_once("serpente_morta", "Ela caiu. A cauda dela... estava tapando um buraco. E de lá vem ar QUENTE.")
		open_well(true)


func open_well(animated: bool) -> void:
	## A cauda enrolada solta o poço: o caminho para o Poço de vapor abre.
	if _plug != null and is_instance_valid(_plug):
		_plug.queue_free()
		_plug = null
	if _plug_vis != null:
		if animated:
			var tw := _plug_vis.create_tween()
			tw.tween_property(_plug_vis, "position:y", -3.0, 2.5)
			tw.tween_callback(_plug_vis.queue_free)
		else:
			_plug_vis.queue_free()
		_plug_vis = null
	if animated:
		EventBus.message.emit("O corpo dela tapava o poço. O ar esquenta...")


const NEXT_LAYER := "res://world/layers/rio_brasa.tscn"


func _on_ramp_top(body: Node3D) -> void:
	## Fim do Ato 2: ela sobe a Rampa quente e chega no Rio de Brasa (Ato 3).
	if _ending or not (body is Player):
		return
	_ending = true
	var first := not GameState.flags.has("ato2_fim")
	GameState.flags["ato2_fim"] = true
	player.autopilot = true
	player.auto_target = Vector3(RAMP_END.x, 0.1, RAMP_END.y + 1.5)
	player.auto_run = true
	hud.cinematic = true
	GameState.say_once("a14_topo", "Lá em cima tem fogo. Um RIO de fogo. ...Claro que tem.")
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree():
		return
	if first:
		go_to_layer(NEXT_LAYER, "Fim do Ato 2", "Do fundo escuro para o rio que queima.", "abismo")
	else:
		go_to_layer(NEXT_LAYER, "Rio de Brasa", "Subindo a Rampa quente.", "abismo")


func _physics_process(delta: float) -> void:
	if player == null:
		return
	# jatos de vapor: 1,2 s ligados a cada 3,5 s, cada um num tempo
	_vent_t += delta
	for k in _vents.size():
		var v: Node3D = _vents[k]
		var on := fmod(_vent_t + k * 1.2, 3.5) < 1.2
		(v.get_meta("steam") as Node3D).visible = on
		if on and not player.dead and player.invuln <= 0.0 and Fx.flat_dist(player.global_position, v.global_position) < 1.1:
			player.take_damage(10.0, null, false)
			EventBus.message.emit("Vapor! Espere o jato acabar.")
	# lâminas de cristal (A10): encostar corta
	if not player.dead and player.invuln <= 0.0 and Fx.flat_dist(player.global_position, Vector3(A10_C.x, 0, A10_C.y)) < 7.0:
		for bl in get_tree().get_nodes_in_group("crystal_blade"):
			if Fx.flat_dist(player.global_position, (bl as Node3D).global_position) < 0.75:
				player.take_damage(8.0, bl as Node3D, true)
				GameState.say_once("a10_corte", "AI! Cristal corta. Anotado. De novo.")
				break


# ---------------------------------------------------------------- chegada (queda)

func _start() -> void:
	GameState.flags.erase("ato1_tela")


func _walk_in_scene() -> void:
	## Chegada do Ato 2: ela despenca do alto da Fenda, bate no chão e fica um tempo caída.
	## Primeira vez: chega ferida (30% da vida) e sem nada de seda.
	## Voltando do Rio de Brasa: desce a Rampa quente andando.
	if arrived_from == "rio":
		await super._walk_in_scene()
		return
	var land := spawn_point
	player.set_physics_process(false)
	player.global_position = land + Vector3(0.6, 16.0, -0.8)
	player.cam_zoom = 10.0
	player.snap_camera()
	player.invuln = 999.0
	hud.cinematic = true
	hud.fade(0.0, 0.5)
	var tw := create_tween()
	tw.tween_property(player, "global_position", land, 0.95).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	if not is_inside_tree():
		return
	player.shake(2.0)
	_impact_dust(land)
	if not GameState.flags.has("a1_queda"):
		GameState.flags["a1_queda"] = true
		player.hp = maxf(1.0, player.max_hp * 0.3)
		player.silk = 0.0
		EventBus.big_message.emit("Ferida e sem seda")
	player.set_physics_process(true)
	player.autopilot = true
	player.auto_target = land
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	GameState.say_once("a1_acorda", "Ai... ai ai ai. Nada quebrado. Eu acho. A seda acabou toda nos fios.")
	hud.show_area_title(layer_name, layer_subtitle)
	await get_tree().create_timer(2.4).timeout
	if not is_inside_tree():
		return
	player.autopilot = false
	player.cam_zoom = 0.0
	player.invuln = 0.0
	hud.cinematic = false
	EventBus.hint.emit("Sem seda, sem fios. Coma alguma coisa para tecer de novo. E ande devagar: aqui o chão conta onde você está.")


func _impact_dust(at: Vector3) -> void:
	var dust := Fx.mat(Color(0.5, 0.5, 0.58), 0.2, true, 0.45)
	for k in 8:
		var d := Fx.sphere(randf_range(0.35, 0.7), dust)
		var a := k * TAU / 8.0
		d.position = at + Vector3(cos(a) * 0.5, 0.2, sin(a) * 0.5)
		add_child(d)
		var t := d.create_tween()
		t.tween_property(d, "position", d.position + Vector3(cos(a) * 2.2, 0.6, sin(a) * 2.2), 1.1).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(d, "scale", Vector3.ONE * 2.2, 1.1)
		t.tween_callback(d.queue_free)


# ---------------------------------------------------------------- sombra no lago

class LakeShadow extends Node3D:
	## Algo enorme passando embaixo da água preta (a Serpente): uma sombra comprida e anéis.
	var center := Vector3.ZERO
	var _t := 0.0
	var _body: Array = []
	var _ring_t := 0.0

	func _ready() -> void:
		var m := Fx.mat(Color(0.0, 0.0, 0.0), 0.0, true, 0.6)
		for k in 9:
			var s := Fx.sphere(0.7 - k * 0.05, m)
			s.scale = Vector3(1.0, 0.2, 1.4)
			add_child(s)
			_body.append(s)

	func _process(delta: float) -> void:
		_t += delta * 0.35
		for k in _body.size():
			var a := _t - k * 0.13
			(_body[k] as Node3D).global_position = center + Vector3(cos(a) * 6.0, 0.0, sin(a * 1.3) * 3.6)
		_ring_t -= delta
		if _ring_t <= 0.0:
			_ring_t = randf_range(2.5, 5.0)
			var ring := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.45
			tm.outer_radius = 0.5
			ring.mesh = tm
			ring.material_override = Fx.mat(Color(0.5, 0.55, 0.7), 0.6, true, 0.5)
			get_parent().add_child(ring)
			ring.global_position = (_body[0] as Node3D).global_position + Vector3(0, 0.15, 0)
			var tw := ring.create_tween()
			tw.tween_property(ring, "scale", Vector3.ONE * 4.0, 1.8)
			tw.tween_callback(ring.queue_free)
