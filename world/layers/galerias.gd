class_name Galerias
extends LayerBase
## G — Galerias Úmidas (Ato 1): G1 a G15, mais a vista da G16 (abre no Ato 4).
## A Grande Gruta (G4) é o centro: dois caminhos levam até ela (a poça do sapo ou o túnel
## dos morcegos), o Jardim de musgo fica ao sul (e o Ninho dos lagartos depois dele),
## o Lago escondido a sudoeste e a Ponte quebrada a leste. Depois da ponte: Galeria do eco
## (aventureiros ao longe), Acampamento, Fresta de cristal, Antecâmara, o Covil da
## Centopeia-blindada e a Borda da Fenda, onde o chão cede e começa a queda para o Abismo.
## As Poças ácidas ligam o jardim à Antecâmara (precisa de Resistência a Ácido 3).
## v0.8: o mapa ganhou um andar de baixo, as Profundezas (P1–P11, 170 m ao sul no mesmo
## plano), e becos novos no andar de cima (G17–G20). Cair nas fendas da Ponte, no abismo do
## eco, na Galeria torta ou no Poço das raízes leva às Profundezas; as rampas da Poça rasa e
## da Antecâmara ligam os dois andares. O resto dos abismos é sem fundo.
## Coordenadas em metros: x para leste, z para o sul.
## Ver a aba "Mapa da Fenda" do GDD.

const STONE := Color(0.4, 0.43, 0.44)
const GREEN := Color(0.45, 1.0, 0.6)
var BAT_HOMES := [W3(28, 0, -6), W3(28, 0, -6), W3(28, 0, -6), W3(43, 0, 10), W3(43, 0, 10)]
var ACID_RECTS := [WR(60, 72, 12, 13), WR(110, 72, 11, 15)]
const ACID_SAFE := 3
var CRYSTAL_WALL := W3(61.6, 0.0, 21.8)
var ARENA := W3(135, 0, 112)
var DOOR_IN := W3(135.5, 0.0, 94.5)
var DOOR_OUT := W3(157.0, 0.0, 111.5)
const NEXT_LAYER := "res://world/layers/abismo.tscn"
var ARENA_2D := W2(135, 112)
var LEDGE_ROUTE := [W2(119, 21), W2(138, 20.5), W2(157, 21)]
var wall_hook_count := 0
const DEEP := 135.0            ## as Profundezas ficam DEEP metros ao sul (mesmo plano y = 0)
const FLOOR_NAMES := ["Andar de cima", "Profundezas"]
const K := 0.72                ## v0.8b: o mapa encolheu 1/3 (as câmaras feitas à mão foram escritas na escala antiga)
const KS := 0.8                ## tamanhos (raios, larguras) encolhem menos que as distâncias
const OLD_OFFSET := Vector2(15, 25)


static func W2(x: float, z: float) -> Vector2:
	## Coordenada da escala antiga → mapa novo.
	return Vector2((x + OLD_OFFSET.x) * K, (z + OLD_OFFSET.y) * K)


static func W3(x: float, y: float, z: float) -> Vector3:
	var q := W2(x, z)
	return Vector3(q.x, y, q.y)


static func WR(x: float, z: float, w: float, h: float) -> Rect2:
	return Rect2(W2(x, z), Vector2(w, h) * K)


static func W(v: Vector3) -> Vector3:
	## Para os testes: posição escrita na escala antiga → mapa novo.
	return W3(v.x, v.y, v.z)


static func WL(x: float, z: float) -> Vector2:
	## O Lago escondido não encolhe (a corrente de fios até a ilha depende das distâncias).
	return W2(0, 74) + Vector2(x, z - 74.0)


static func WL3(x: float, y: float, z: float) -> Vector3:
	var q := WL(x, z)
	return Vector3(q.x, y, q.y)


static func S(r: float) -> float:
	return r * KS

var cave: CaveBuilder
var upper: OrganicCave          ## caverna orgânica do andar de cima (autômato celular)
var lower: OrganicCave          ## e a das Profundezas
const UPPER_SEED := 11
const LOWER_SEED := 23
var centipede: Centipede
var _door_out: StaticBody3D
var _collapsing := false
var _territory_done := false
var _acid_timer := 0.0


func _configure() -> void:
	layer_id = "G"
	layer_name = "Galerias Úmidas"
	layer_subtitle = "Ato 1 · Você ainda é uma Filhote. Fuja do que é maior, cace o que é menor."
	spawn_point = W3(1.0, 0.1, -17.0)
	ambient_color = Color(0.42, 0.56, 0.58)
	ambient_energy = 0.34
	fog_color = Color(0.04, 0.07, 0.07)
	rooms = [
		{"id": "G1", "name": "Entrada", "checkpoint": true, "label_only": true, "open_r": 7.0,
			"shapes": [CaveBuilder.blob(W2(0, 0), 7.0, 0.0)],
			"hint": "Fungos verdes marcam o caminho. Dois caminhos levam à Grande Gruta: a poça ao sul ou o túnel a leste.",
			"line_id": "galerias", "line": "Galerias úmidas... cheiro de musgo. E de comida."},
		{"id": "G2", "name": "Poça rasa", "label_only": true, "open_r": 6.5,
			"shapes": [CaveBuilder.blob(W2(-2, 34), 7.0, 0.0)],
			"hint": "Algo grande espera perto da poça. Segure Alt (Leitura) para ver o que cada criatura sente e o quanto ela é perigosa.",
			"line_id": "g2_poca", "line": "Aquela pedra perto da água... piscou?"},
		{"id": "G3", "name": "Túnel dos morcegos", "label_only": true, "open_r": 4.5,
			"shapes": [CaveBuilder.blob(W2(28, -6), 7.0, 0.0)],
			"hint": "Morcegos-eco ouvem quem se mexe: fique parada e eles perdem você. Fio esticado entre pilares derruba quem voa por ele, e Q lança fio para o alto.",
			"line_id": "g3_morcegos", "line": "Um túnel cheio de asas. Que maravilha."},
		{"id": "G4", "name": "Grande Gruta", "checkpoint": true, "label_only": true, "open_r": 9.5,
			"shapes": [CaveBuilder.blob(W2(44, 36), 7.0, 0.0)],
			"hint": "Teça um casulo (C) para salvar. Depois ligue com fios (R) os pilares perto dele: tudo o que estiver ligado ao casulo vira seu território.",
			"line_id": "g4_gruta", "line": "Espaço, pilares, ninguém me caçando... por enquanto. Aqui vai ser minha casa."},
		{"id": "G5", "name": "Jardim de musgo", "label_only": true, "open_r": 7.5,
			"shapes": [CaveBuilder.blob(W2(44, 72), 7.0, 0.0)],
			"hint": "O Lagarto-lanterna atrai larvas com a luz e defende o jardim. A isca revela você de perto, mesmo com a runa apagada.",
			"line_id": "g5_lagarto", "line": "Uma lanterna com dentes. Claro."},
		{"id": "G6", "name": "Ponte quebrada", "checkpoint": true,
			"shapes": [CaveBuilder.path([W2(59, 37), W2(72, 40), W2(86, 36), W2(100, 38), W2(114, 36)], S(8.0), 0.8)],
			"hint": "Três fendas seguidas. Em cada uma, teça um fio entre os pilares (R) ou lance fio na parede do outro lado (Q).",
			"line_id": "g6_ponte", "line": "Quem quebrou essa ponte? ...Eu nem sei se isso era uma ponte."},
		{"id": "G7", "name": "Lago escondido",
			"shapes": [CaveBuilder.ellipse(WL(2, 74), 14.0, 11.0, 0.0, 1.0)],
			"hint": "Aranhas não nadam. Só uma corrente de fios leva até a ilha: primeiro a pedrinha no meio do caminho.",
			"line_id": "g7_lago", "line": "Tem algo brilhando na ilha. E eu odeio água."},
		{"id": "G8", "name": "Galeria do eco", "checkpoint": true,
			"shapes": [CaveBuilder.ellipse(W2(138, 39), S(13.0), S(10.0), 0.0, 1.0),
				CaveBuilder.path([W2(118, 26.5), W2(158, 26.5)], S(9.0), 0.4),
				CaveBuilder.path([W2(118, 21), W2(158, 21)], S(4.5), 0.4)],
			"hint": "Um abismo largo, e do outro lado uma borda de pedra. A galeria devolve qualquer som... fique atenta.",
			"line_id": "g8_eco", "line": "Eco... eco... Que lugar pra uma aranha com medo de barulho."},
		{"id": "G9", "name": "Acampamento", "label_only": true, "open_r": 7.5,
			"shapes": [CaveBuilder.blob(W2(182, 44), 7.0, 0.0)],
			"hint": "Um acampamento abandonado. Fogo QUEIMA fios: não estique teia perto das tochas. Aperte E nas anotações para ler.",
			"line_id": "g9_acampamento", "line": "Gente esteve aqui. Gente com fogo. Por que tudo aqui tem que ter fogo?"},
		{"id": "G10", "name": "Fresta de cristal",
			"shapes": [CaveBuilder.blob(W2(168, 13), S(3.6), 0.5)],
			"hint": "Cristais que brilham como a sua runa. Aperte E para examinar.",
			"line_id": "g10_fresta", "line": "Tá brilhando no mesmo ritmo que eu. Isso é bonito ou assustador?"},
		{"id": "G11", "name": "Poças ácidas",
			"shapes": [CaveBuilder.path([W2(54, 74), W2(64, 78), W2(80, 82), W2(96, 80), W2(112, 83), W2(133, 78)], S(6.0), 0.8)],
			"hint": "Ácido no chão. Com Resistência a Ácido 3 dá para atravessar: dizem que quem come Sapo-de-rocha aguenta mais.",
			"line_id": "g11_pocas", "line": "Cheiro de ovo podre e metal. Meus pés já estão reclamando."},
		{"id": "G12", "name": "Ninho dos lagartos", "label_only": true, "open_r": 8.5,
			"shapes": [CaveBuilder.blob(W2(43, 104), 7.0, 0.0)],
			"hint": "Três Lagartos-lanterna, cada um com o seu território. As iscas revelam você de perto. Escolha bem por onde passar.",
			"line_id": "g12_ninho", "line": "Uma, duas, três lanternas. E todas com fome."},
		{"id": "G13", "name": "Antecâmara", "checkpoint": true, "label_only": true, "open_r": 6.5,
			"shapes": [CaveBuilder.blob(W2(135, 77), 7.0, 0.0)],
			"hint": "Último lugar seguro antes do covil. Teça um casulo (C) e descanse: depois daqui não tem volta fácil.",
			"line_id": "g13_antecamara", "line": "Dá pra sentir o chão tremendo daqui. Ela é GRANDE."},
		{"id": "G14", "name": "Covil da Centopeia",
			"shapes": [CaveBuilder.ellipse(ARENA_2D, S(15.0), S(12.0), 0.0, 1.2)]},
		{"id": "G15", "name": "Borda da Fenda",
			"shapes": [CaveBuilder.blob(W2(172, 110), S(7.0), 1.0)]},
		{"id": "G16", "name": "Subida antiga",
			"shapes": [CaveBuilder.ellipse(W2(76, 4), S(9.0), S(8.0), 0.4, 1.0)]},
		# --- v0.8b: nomes das partes geradas (só nome; o chão vem da caverna orgânica) ---
		{"id": "G17", "name": "Beco dos ossos", "label_only": true, "shapes": [CaveBuilder.blob(W2(-12, 18), 5.0, 0.0)],
			"line_id": "g17_ossos", "line": "Ossos. Muitos ossos. Alguém come aqui... e não limpa."},
		{"id": "G18", "name": "Galerias tortas", "label_only": true, "shapes": [CaveBuilder.blob(W2(20, 14), 5.0, 0.0)],
			"line_id": "g18_torta", "line": "Pra que lado eu vim mesmo? ...Todos os lados parecem iguais."},
		{"id": "G19", "name": "Poço das raízes", "label_only": true, "shapes": [CaveBuilder.blob(W2(18, 112), 5.0, 0.0)],
			"line_id": "g19_poco", "line": "Raízes descendo pro escuro. Bem fundo. Bem, bem fundo."},
		{"id": "G20", "name": "Mirante", "label_only": true, "shapes": [CaveBuilder.blob(W2(186, 12), 5.0, 0.0)],
			"line_id": "g20_mirante", "line": "Daqui dá pra ver o nada. Muito nada."},
		{"id": "G21", "name": "Corredores do leste", "label_only": true, "shapes": [CaveBuilder.blob(W2(160, 70), 5.0, 0.0)]},
		{"id": "G22", "name": "Fosso escuro", "label_only": true, "shapes": [CaveBuilder.blob(W2(20, 88), 5.0, 0.0)]},
	]
	locks = [
		{"type": "cristal", "pos": CRYSTAL_WALL},
		{"type": "acido", "pos": W3(64, 0, 78)},
		{"type": "acido", "pos": W3(116, 0, 81)},
		{"type": "fresta", "pos": W3(164, 0, 32)},
	]


func _room_shapes(id: String) -> Array:
	for r in rooms:
		if r["id"] == id:
			return r["shapes"]
	return []


func _generate_organic() -> void:
	## Andar de cima: a caverna orgânica preenche o oeste (G1–G5, lago, ninho) e o leste
	## (Galeria do eco, acampamento, Antecâmara). O meio (Ponte quebrada, Poças ácidas,
	## Subida antiga) e o sul do covil ficam só com as câmaras feitas à mão: assim nenhum
	## atalho gerado pula a Ponte, o ácido, a fresta, a parede de cristal ou a porta do covil.
	upper = OrganicCave.new(Rect2(-2, -2, 156, 114), UPPER_SEED)
	var west_max := W2(58, 0).x
	var east_min := W2(118, 0).x
	var south := W2(0, 95).y
	upper.lock_rock(func(p): return (p.x > west_max and p.x < east_min) or (p.y > south and p.x > west_max))
	upper.fix_open(func(p): return cave.open_at(p))
	var shut: Array = []
	shut.append_array(_room_shapes("G10"))
	shut.append(cave.tunnels[5])                     # a fresta
	shut.append((_room_shapes("G8") as Array)[2])    # a borda de pedra da Galeria do eco
	for sh in shut:
		upper.protect_band(func(p): return cave._sdf(sh, p, 0.0), 2.5)
	upper.scatter(0.5)
	upper.smooth(6)
	for r in rooms:
		if r.get("label_only", false) and int(r.get("floor", 0)) == 0:
			upper.open_blob((r["shapes"][0] as Dictionary)["c"], float(r.get("open_r", 4.0)))
	upper.connect_all(80, [W2(168, 13), W2(76, 4), W2(138, 21)])
	upper.chasm_pockets(0.36, 3.2, 0.07)
	cave.tunnels.append(upper.open_shape(0.5))
	cave.chasms.append(upper.chasm_shape(0.25))

	# Profundezas: inteiras orgânicas, embaixo do andar de cima; poços lá embaixo não têm fundo
	lower = OrganicCave.new(Rect2(6, DEEP + 4, 142, 100), LOWER_SEED)
	var labels := [["P1", "Fundo das fendas", Vector2(30, 25)], ["P2", "Salão dos ecos baixos", Vector2(75, 22)],
		["P3", "Ninho dos sapos", Vector2(122, 26)], ["P4", "Galeria das raízes", Vector2(28, 78)],
		["P5", "Fundo do poço", Vector2(75, 80)], ["P6", "Beco do musgo negro", Vector2(122, 78)]]
	lower.scatter(0.5)
	lower.smooth(6)
	for l in labels:
		var c: Vector2 = lower.origin + l[2]
		lower.open_blob(c, 5.0)
		rooms.append({"id": l[0], "name": l[1], "floor": 1, "label_only": true, "shapes": [CaveBuilder.blob(c, 5.0, 0.0)]})
	rooms[rooms.size() - 6]["hint"] = "Você caiu nas Profundezas. Duas rampas levam de volta para cima: procure as luzes frias."
	rooms[rooms.size() - 6]["line_id"] = "p1_fundo"
	rooms[rooms.size() - 6]["line"] = "Ai... minhas pernas. Todas as oito. Onde eu tô?"
	lower.connect_all(80)
	lower.chasm_pockets(0.4, 3.0, 0.07)
	cave.tunnels.append(lower.open_shape(0.5))
	cave.chasms.append(lower.chasm_shape(0.25))


func _add_wall_hooks() -> void:
	## Ganchos de rocha nas paredes, só em pares atravessando os bolsões de abismo
	## (uma rota de fuga por cima do buraco). Poucos de propósito: a rede de fios
	## continua sendo de pilares; o gancho é um atalho que se descobre.
	var hooks: Array = upper.wall_hooks(6, 11.0)
	hooks.append_array(lower.wall_hooks(4, 11.0))
	var k := 0
	for i in range(0, hooks.size() - 1, 2):
		var pair: Array = []
		for hk in [hooks[i], hooks[i + 1]]:
			var p: Vector2 = hk["p"]
			var nrm: Vector2 = hk["n"]
			var q := p
			for step in 5:
				if cave.is_floor(q, 0.4):
					break
				q += nrm * 0.35
			if not cave.is_floor(q, 0.4):
				break
			pair.append([q, nrm])
		if pair.size() < 2 or (pair[0][0] as Vector2).distance_to(pair[1][0]) > 11.6:
			continue
		for e in pair:
			var q: Vector2 = e[0]
			var nrm: Vector2 = e[1]
			add_wall_anchor("Gancho_%02d" % k, Vector3(q.x, 0.0, q.y), Vector3(nrm.x, 0.0, nrm.y), STONE.lightened(0.04))
			k += 1
	wall_hook_count = k


func _snap_floor(p: Vector3, margin: float = 0.5) -> Vector3:
	## Chão firme mais perto (para posições escritas antes da caverna gerada).
	var q := Vector2(p.x, p.z)
	if cave.is_floor(q, margin):
		return p
	var oc := lower if p.z > DEEP - 5.0 else upper
	for r in range(1, 30):
		for k in 16:
			var c := q + Vector2(cos(k * TAU / 16.0), sin(k * TAU / 16.0)) * float(r)
			if cave.is_floor(c, margin):
				return Vector3(c.x, p.y, c.y)
	var f := oc.nearest_floor(q)
	return Vector3(f.x, p.y, f.y)


func _deep_floor(p: Vector3) -> Vector3:
	return _snap_floor(Vector3(p.x, 0.0, p.z), 0.8)


func landing_near(p: Vector3) -> Vector3:
	return _deep_floor(p)


func _build_level() -> void:
	cave = CaveBuilder.new()
	cave.floor_color = Color(0.27, 0.32, 0.3)
	cave.rock_color = Color(0.17, 0.21, 0.21)
	cave.noise.seed = 31
	cave.rooms = rooms
	cave.tunnels = [
		CaveBuilder.path([W2(0, -24), W2(3, -14), W2(0, -7)], S(3.6), 0.4),                     # chegada do Berçário
		CaveBuilder.path([W2(55, 29), W2(63, 20), W2(71, 10)], S(4.0), 0.3),                    # → G16 (parede de cristal)
		CaveBuilder.path([W2(50, 37), W2(59, 37)], S(6.0), 0.4),                                # boca oeste da Ponte
		CaveBuilder.path([W2(112, 36), W2(127, 38)], S(3.6), 0.3),                              # G6 → G8
		CaveBuilder.path([W2(145, 42), W2(161, 47), W2(178, 44)], S(5.6), 0.4),                 # G8 → G9
		CaveBuilder.path([W2(150, 39), W2(160, 37), W2(165, 31), W2(167, 17)], 1.15, 0.0),      # fresta G8 → G10
		CaveBuilder.path([W2(180, 47), W2(176, 52), W2(160, 63), W2(137, 76)], S(5.6), 0.4),    # G9 → G13 (a Centopeia passa)
		CaveBuilder.path([W2(135, 84), W2(136, 92), W2(135, 101)], S(5.0), 0.3),                # G13 → G14
		CaveBuilder.path([W2(149, 112), W2(158, 111), W2(166, 110)], S(4.0), 0.3),              # G14 → G15
		CaveBuilder.path([W2(44, 81), W2(43, 94)], S(4.0), 0.3),                                # G5 → G12
	]
	cave.chasms = [
		CaveBuilder.path([W2(70, 29), W2(71, 49)], S(4.5), 0.3),        # 1ª fenda da Ponte quebrada
		CaveBuilder.path([W2(85, 26), W2(86, 46)], S(4.5), 0.3),        # 2ª
		CaveBuilder.path([W2(99, 28), W2(100, 48)], S(5.0), 0.3),       # 3ª
		CaveBuilder.ellipse(WL(0, 74), 10.0, 7.5, 0.0, 0.4),           # lago (sem encolher)
		CaveBuilder.ellipse(W2(77, 2), S(6.0), S(5.0), 0.4, 0.4),       # abismo longo da G16
		CaveBuilder.path([W2(116, 26.5), W2(160, 26)], S(6.0), 0.4),    # abismo da Galeria do eco
		CaveBuilder.path([W2(178, 99), W2(181, 121)], S(5.5), 0.6),     # a Fenda, na borda leste da G15
	]
	cave.bridges = [
		CaveBuilder.blob(WL(-3, 74), 2.6, 0.3),      # ilha do lago
		CaveBuilder.blob(WL(5, 70.5), 1.4, 0.15),    # pedrinha no meio do caminho
	]
	_generate_organic()
	map_grid = cave.build(self)
	cave.scatter_decor(self, 23)
	# Quedas: os abismos do andar de cima levam às Profundezas (bem embaixo de onde você caiu);
	# o lago devolve à margem; G16, a Fenda da G15 e os poços das Profundezas não têm fundo.
	var down := Vector3(0, 0, DEEP)
	var deep_mid := _deep_floor(Vector3(75, 0, DEEP + 55))
	chasms = [
		{"rect": Rect2(WL(-10, 66.5), Vector2(20, 15)), "mode": "volta", "name": "o lago"},
		{"rect": WR(70, -5, 14, 14), "name": "o abismo"},                    # G16: sem fundo
		{"rect": WR(174, 95, 12, 30), "name": "a Fenda"},                    # G15: sem fundo
		{"rect": Rect2(-10, DEEP - 10, 180, 140), "name": "o fundo"},        # Profundezas: sem fundo
		{"rect": Rect2(-10, -10, 180, 130), "drop": down, "to": deep_mid, "name": "as Profundezas"},
	]

	var pillars := {
		"G1_a": W3(-5, 0, -3), "G1_b": W3(5, 0, 3), "G1_c": W3(-3, 0, 5),
		"G2_a": W3(4, 0, 28), "G2_b": W3(-9, 0, 40), "G2_c": W3(5, 0, 40),
		"G3_a": W3(25, 0, -8.8), "G3_b": W3(31, 0, -3.4), "G3_c": W3(37, 0, 0.2),
		"G3_d": W3(41.5, 0, -1), "G3_e": W3(41.5, 0, 12), "G3_f": W3(46.5, 0, 14),
		"G4_a": W3(39, 0, 32), "G4_b": W3(50, 0, 34), "G4_c": W3(45, 0, 41),
		"G4_d": W3(32, 0, 36), "G4_e": W3(38, 0, 26.5), "G4_f": W3(51, 0, 27),
		"G4_g": W3(57, 0, 38), "G4_h": W3(50, 0, 45), "G4_i": W3(36, 0, 44),
		"G5_a": W3(37, 0, 67), "G5_b": W3(51, 0, 67), "G5_c": W3(50, 0, 79), "G5_d": W3(37, 0, 78),
		"G6_a": W3(66, 0, 36.5), "G6_b": W3(65.5, 0, 41), "G6_c": W3(75.5, 0, 37), "G6_d": W3(75.5, 0, 41.5),
		"G6_e": W3(81, 0, 35.5), "G6_f": W3(81, 0, 39.5), "G6_g": W3(90, 0, 34.8), "G6_h": W3(90, 0, 38.8),
		"G6_i": W3(95, 0, 35.5), "G6_j": W3(95, 0, 39.5), "G6_k": W3(104.5, 0, 35.5), "G6_l": W3(104.5, 0, 39.5),
		"G7_a": WL3(13, 0, 72), "G7_b": WL3(5, 0, 70.5), "G7_c": WL3(-3, 0, 74),
		"G8_a": W3(129, 0, 36), "G8_b": W3(138, 0, 44), "G8_c": W3(146, 0, 35),
		"G9_a": W3(175, 0, 40), "G9_b": W3(189, 0, 40), "G9_c": W3(184, 0, 51), "G9_d": W3(178, 0, 48),
		"G11_a": W3(84, 0, 83.4), "G11_b": W3(100, 0, 78.2), "G11_c": W3(122, 0, 82.2),
		"G12_a": W3(36, 0, 98), "G12_b": W3(50, 0, 98), "G12_c": W3(36, 0, 110), "G12_d": W3(50, 0, 110),
		"G13_a": W3(130, 0, 73), "G13_b": W3(140, 0, 73), "G13_c": W3(129, 0, 80),
		"G15_a": W3(167, 0, 106), "G15_b": W3(168, 0, 114), "G15_c": W3(173, 0, 110),
	}
	for k in 8:
		var ang := k * TAU / 8.0 + PI / 8.0
		pillars["G14_%d" % k] = ARENA + Vector3(cos(ang) * 7.2, 0.0, sin(ang) * 5.6)
	var i := 0
	for n in pillars:
		var pos: Vector3 = pillars[n]
		if not cave.is_floor(Vector2(pos.x, pos.z), 0.45):
			pos = _snap_floor(pos, 0.6)   # pilar que caiu na rocha da caverna gerada: chão mais perto
			pillars[n] = pos
		var small := String(n) == "G7_b"
		add_anchor(n, pos, 2.5 if small else 3.5, 0.4 if small else 0.5, STONE, "estalagmite_" + "abc"[i % 3])
		i += 1
		if not cave.is_floor(Vector2(pos.x, pos.z), 0.45):
			push_warning("Pilar %s fora do chão firme em %s" % [n, pos])
	_add_wall_hooks()

	_build_pond(W3(-4, 0.03, 36), 3.4)
	_build_lake()
	_build_crystal_wall()
	_build_acid()
	_build_camp()
	_build_doors()

	for w in [W3(-6, 0, -5), W3(40, 0, 38), W3(48, 0, 31), W3(100, 0, 41), W3(28, 0, -3)]:
		add_web_decal(w, 2.2)

	# Fungos verdes marcam o caminho principal; o túnel do lago não tem nenhum
	for f in [W3(130, 0, 40), W3(146, 0, 42), W3(160, 0, 46), W3(150, 0, 58), W3(133, 0, 75),
			W3(137, 0, 88), W3(155, 0, 111), W3(52, 0, 76), W3(90, 0, 79), W3(44, 0, 90),
			W3(2, 0, -21), W3(-1, 0, -10), W3(6, 0, -6), W3(-6, 0, 6), W3(-5, 0, 16), W3(4, 0, 31),
			W3(14, 0, 38), W3(12, 0, -6), W3(22, 0, -10), W3(36, 0, -4), W3(46, 0, 18),
			W3(34, 0, 30), W3(55, 0, 33), W3(44, 0, 50), W3(62, 0, 39), W3(78, 0, 43),
			W3(92, 0, 41), W3(108, 0, 40), W3(118, 0, 36), W3(40, 0, 64), W3(50, 0, 76),
			W3(-8, 0, 30), W3(12, 0, 77)]:
		if cave.is_floor(Vector2(f.x, f.z), 0.2):
			add_fungus(f, GREEN)
	for f in [W3(38, 0, 72), W3(48, 0, 68), W3(44, 0, 77), W3(40, 0, 78)]:
		add_fungus(f, Color(0.75, 0.5, 1.0))
	# Profundezas: poucos fungos roxos (é mais escuro lá embaixo)
	var frng := RandomNumberGenerator.new()
	frng.seed = 5
	for k in 14:
		var fp := lower.nearest_floor(Vector2(frng.randf_range(lower.origin.x + 8, lower.origin.x + lower.w - 8),
			frng.randf_range(lower.origin.y + 8, lower.origin.y + lower.h - 8)))
		if cave.is_floor(fp, 0.4):
			add_fungus(Vector3(fp.x, 0, fp.y), Color(0.6, 0.45, 1.0))
	# Rampas entre os andares: na Poça rasa e na Antecâmara, cada uma com o par lá embaixo
	for pair in [[W3(-6, 0, 30), "a Poça rasa"], [W3(140, 0, 80), "a Antecâmara"]]:
		var up_pos: Vector3 = _snap_floor(pair[0], 1.2)
		var dn_pos := _deep_floor(up_pos + Vector3(0, 0, DEEP))
		var up_rect := Rect2(Vector2(up_pos.x, up_pos.z) - Vector2(1.2, 1.2), Vector2(2.4, 2.4))
		var dn_rect := Rect2(Vector2(dn_pos.x, dn_pos.z) - Vector2(1.2, 1.2), Vector2(2.4, 2.4))
		add_passage(up_rect, _deep_floor(dn_pos + Vector3(2.8, 0, 0)), "Você desceu a rampa para as Profundezas.", "Rampa para as Profundezas")
		add_passage(dn_rect, _snap_floor(up_pos + Vector3(2.8, 0, 0), 0.8), "Você subiu de volta para %s." % pair[1], "Rampa para cima")
	# Luz fria vinda de baixo, na Borda da Fenda
	var deep := OmniLight3D.new()
	deep.light_color = Color(0.45, 0.55, 1.0)
	deep.omni_range = 10.0
	deep.light_energy = 1.0
	deep.position = W3(180, -2, 110)
	add_child(deep)
	# A luz fraca lá em cima, na Subida antiga
	var high := OmniLight3D.new()
	high.light_color = Color(1.0, 0.85, 0.6)
	high.omni_range = 14.0
	high.light_energy = 0.9
	high.position = W3(78, 9, 2)
	add_child(high)


func _build_pond(pos: Vector3, radius: float) -> void:
	var water := Fx.cylinder(radius, 0.02, Fx.mat(Color(0.12, 0.25, 0.32), 0.25, false, 0.75))
	water.position = pos
	water.scale = Vector3(1.0, 1.0, 0.75)
	add_child(water)


func _build_lake() -> void:
	var water := Fx.cylinder(1.0, 0.04, Fx.mat(Color(0.08, 0.2, 0.3), 0.35, false, 0.82))
	water.position = WL3(0, -0.8, 74)
	water.scale = Vector3(11.0, 1.0, 8.5)
	add_child(water)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.3, 0.6, 0.9)
	glow.omni_range = 10.0
	glow.light_energy = 0.5
	glow.position = WL3(0, 0.5, 74)
	add_child(glow)


func _build_crystal_wall() -> void:
	# Parede de cristal na passagem para a Subida antiga (abre no Ato 4).
	var body := add_static_box(Vector3(4.2, 3.0, 0.8), CRYSTAL_WALL + Vector3(0, 1.6, 0), Color(0.55, 0.75, 1.0))
	body.rotation.y = -0.72
	var mi := body.get_child(0) as MeshInstance3D
	mi.material_override = Fx.mat(Color(0.55, 0.75, 1.0), 1.2, false, 0.55)
	var light := OmniLight3D.new()
	light.light_color = Color(0.55, 0.75, 1.0)
	light.omni_range = 5.0
	light.light_energy = 0.8
	light.position = CRYSTAL_WALL + Vector3(-1.0, 2.0, 1.0)
	add_child(light)


func _build_acid() -> void:
	# Poças ácidas cobrem o corredor da G11 nas duas pontas.
	var mat := Fx.mat(Color(0.55, 1.0, 0.25), 1.6, false, 0.7)
	for r in ACID_RECTS:
		var rect: Rect2 = r
		var x := rect.position.x + 1.5
		while x < rect.end.x:
			var z := rect.position.y + 1.5
			while z < rect.end.y:
				if cave.is_floor(Vector2(x, z), 0.3):
					var pool := Fx.cylinder(1.7, 0.03, mat)
					pool.position = Vector3(x + fposmod(z * 1.7, 0.8), 0.03, z)
					add_child(pool)
				z += 2.6
			x += 2.6
		var light := OmniLight3D.new()
		light.light_color = Color(0.55, 1.0, 0.25)
		light.omni_range = 8.0
		light.light_energy = 1.0
		light.position = Vector3(rect.get_center().x, 1.2, rect.get_center().y)
		add_child(light)


func _build_camp() -> void:
	# G9: acampamento abandonado dos aventureiros. Tochas queimam fios.
	var canvas := Color(0.55, 0.47, 0.35)
	var tent := add_static_box(Vector3(3.2, 1.8, 2.6), W3(176.5, 0.9, 47.5), canvas)
	tent.rotation.y = 0.3
	add_static_box(Vector3(1.0, 0.9, 1.0), W3(188.5, 0.45, 48.0), Color(0.42, 0.3, 0.2))
	add_static_box(Vector3(0.8, 0.7, 0.8), W3(189.3, 0.35, 46.9), Color(0.42, 0.3, 0.2))
	for b in [W3(181, 0.03, 40.5), W3(185, 0.03, 42), W3(179, 0.03, 43)]:
		var roll := Fx.box(Vector3(0.9, 0.06, 2.0), Fx.mat(Color(0.35, 0.3, 0.42)))
		roll.position = b
		roll.rotation.y = b.x * 0.4
		add_child(roll)
	for t in [W3(177, 0, 41), W3(187, 0, 41), W3(182, 0, 51)]:
		var torch := Fire.new(1.0)
		torch.position = t
		add_child(torch)
	var campfire := Fire.new(0.7)
	campfire.position = W3(182, 0, 45)
	add_child(campfire)
	add_child(_note(W3(183.5, 0, 46.5), "g9_diario", [
		"Diário de expedição, dia 3. A guilda paga bem por seda de aranha-da-runa. Ninguém sabe se elas ainda existem.",
		"Dia 5. Achamos a pele de uma centopeia gigante mais ao sul. Do tamanho de uma carroça. O Tobias quer voltar.",
		"Dia 6. Alguma coisa toca as nossas cordas à noite. Mantenham as tochas acesas: fogo queima teia.",
	], "papel"))
	add_child(_note(W3(168, 0, 12), "g10_visao", [
		"Os cristais pulsam no mesmo ritmo da sua runa.",
		"Dentro de um deles, uma silhueta: uma aranha com placas de pedra-da-lua... maior. Muito maior.",
		"(Pista de uma forma rara. Lembre deste lugar.)",
	], "cristal"))


func _note(pos: Vector3, flag: String, pages: Array, look: String) -> Note:
	var n := Note.new(pages, flag, look)
	n.position = pos
	return n


func _build_doors() -> void:
	# Portas de pedra do covil: a de saída fica fechada até a Centopeia cair;
	# a de entrada só fecha durante a luta.
	_door_out = _rock_door(DOOR_OUT, 0.0)


func _rock_door(pos: Vector3, rot: float) -> StaticBody3D:
	var body := add_static_box(Vector3(4.6, 3.0, 1.4), pos + Vector3(0, 1.5, 0), Color(0.3, 0.32, 0.33))
	body.rotation.y = rot
	if pos == DOOR_OUT:
		body.rotation.y = PI * 0.5
	return body


func _populate() -> void:
	var up_spawns := [
		W3(-4, 0, 2), W3(4, 0, -3), W3(-2, 0, 30), W3(3, 0, 38),
		W3(40, 0, 70), W3(48, 0, 74), W3(41, 0, 77), W3(47, 0, 66), W3(38, 0, 73),
		W3(50, 0, 40), W3(10, 0, 74), W3(40, 0, 102), W3(46, 0, 106), W3(133, 0, 40), W3(180, 0, 56),
		W3(20, 0, 14), W3(-12, 0, 18), W3(18, 0, 100), W3(160, 0, 70),
	]
	ecosystem.larva_spawns = []
	for sp in up_spawns:
		ecosystem.larva_spawns.append(_snap_floor(sp))
	ecosystem.larva_spawns.append_array(_deep_spots(9, 101))
	ecosystem.frog_spawns = []
	for sp in [W3(-5, 0, 38), W3(188, 0, 50), W3(20, 0, 14), W3(18, 0, 100)]:
		ecosystem.frog_spawns.append(_snap_floor(sp))
	ecosystem.frog_spawns.append_array(_deep_spots(4, 102))
	ecosystem.larva_target = 22
	ecosystem.frog_target = 8
	ecosystem.on_spawn = _setup_creature
	ecosystem.spawn_initial()
	for home in BAT_HOMES:
		_spawn_bat(_snap_floor(home))
	var east_flock := _snap_floor(W3(160, 0, 70))
	for k in 3:
		_spawn_bat(east_flock, ["G21", "G9", "G13"], "g21")
	var deep_flock: Vector3 = _deep_spots(1, 103)[0]
	for k in 4:
		_spawn_bat(deep_flock, ["P2", "P1", "P3", "P5"], "p2")
	# Profundezas: lagartos e irmãs famintas que fugiram do ninho e viraram caçadoras
	var lz_spots := _deep_spots(2, 104)
	for li in 2:
		var flag := "p_lagarto_%d" % li
		if not GameState.flags.has(flag):
			var dlz := Lizard.new()
			dlz.position = lz_spots[li] + Vector3(0, 0.3, 0)
			dlz.territory_radius = 6.5
			dlz.set_meta("flag", flag)
			ecosystem.add_child(dlz)
	var sis_spots: Array = [_snap_floor(W3(-12, 0, 18)), _snap_floor(W3(186, 0, 12))]
	sis_spots.append_array(_deep_spots(3, 105))
	for sp in sis_spots:
		var sis := Sister.new(true)
		sis.position = sp + Vector3(0, 0.3, 0)
		sis.display_name = "Irmã caçadora"
		ecosystem.add_child(sis)
	if not GameState.flags.has("g5_lagarto"):
		var lz := Lizard.new()
		lz.position = _snap_floor(W3(44, 0.3, 73), 1.0)
		ecosystem.add_child(lz)
	for i in 3:
		if GameState.flags.has("g12_lagarto_%d" % i):
			continue
		var nest := Lizard.new()
		nest.position = _snap_floor([W3(37, 0.3, 101), W3(49, 0.3, 101), W3(43, 0.3, 109)][i] as Vector3, 0.8)
		nest.territory_radius = 6.0
		nest.food_energy = 5.0
		nest.set_meta("nest_id", i)
		ecosystem.add_child(nest)
	var deep_cr := _deep_spots(2, 106)
	for pk in [["cristal_en", "g7_cristal", WL3(-4.2, 0, 75.2)], ["cristal_en", "g12_cristal", W3(43, 0, 104)], ["cristal_pv", "g10_cristal", W3(169.5, 0, 14.5)],
			["cristal_pv", "g17_cristal", _snap_floor(W3(-12, 0, 18))], ["cristal_pv", "p6_cristal", deep_cr[0]], ["cristal_en", "p5_cristal", deep_cr[1]]]:
		if not GameState.flags.has(pk[1]):
			var crystal := Pickup.new(pk[0], pk[1])
			crystal.position = pk[2]
			add_child(crystal)
	if not GameState.flags.has("g14_centopeia"):
		centipede = Centipede.new()
		centipede.position = ARENA + Vector3(0, 0.3, 3)
		centipede.arena_center = ARENA
		centipede.den = ARENA
		centipede.range_rooms = ["G8", "G9", "G11", "G13", "G14"]
		ecosystem.add_child(centipede)
	else:
		_open_door_out()
	add_trigger(WR(165, 104, 10, 12), _on_edge)
	EventBus.rested.connect(_on_rested)
	EventBus.territory_changed.connect(_on_territory_changed)
	EventBus.creature_died.connect(_on_creature_died)


func _deep_spots(n: int, seed_: int) -> Array:
	## Pontos de chão nas Profundezas (sempre os mesmos para a mesma semente).
	var r := RandomNumberGenerator.new()
	r.seed = seed_
	var out: Array = []
	for k in n:
		var q := lower.nearest_floor(Vector2(r.randf_range(lower.origin.x + 10, lower.origin.x + lower.w - 10),
			r.randf_range(lower.origin.y + 10, lower.origin.y + lower.h - 10)))
		out.append(_snap_floor(Vector3(q.x, 0, q.y), 0.6))
	return out


func _spawn_bat(home: Vector3, rooms_: Array = ["G3", "G1", "G4", "G2"], flock_: String = "") -> Bat:
	var b := Bat.new()
	b.position = home + Vector3(randf_range(-2.0, 2.0), Bat.ROOST_Y, randf_range(-1.5, 1.5))
	b.den = home
	b.flock = flock_ if flock_ != "" else "g3_%d" % int(home.x)
	b.range_rooms = rooms_
	ecosystem.add_child(b)
	b.home = home
	return b


func _setup_creature(c: Creature) -> void:
	## Câmaras por onde cada criatura nova passeia.
	if c is Frog:
		var q := c.global_position
		if q.z > DEEP - 5.0:
			c.range_rooms = ["P1", "P2", "P4", "P5"] if q.x < 75.0 else ["P2", "P3", "P5", "P6"]
		elif q.x < W2(58, 0).x and q.z > W2(0, 80).y:
			c.range_rooms = ["G19", "G22", "G12"]
		elif q.x < W2(58, 0).x and q.z < W2(0, 20).y:
			c.range_rooms = ["G18", "G17", "G1", "G3"]
		else:
			c.range_rooms = ["G9", "G8", "G13"] if q.x > W2(100, 0).x else ["G2", "G1", "G4", "G5"]


func _start() -> void:
	if not resumed:
		EventBus.message.emit("Objetivo: chegue à Grande Gruta e faça dela o seu território.")
	GameState.say_once("g_chegada", "Saí do ninho. Agora é só eu, a caverna... e tudo que mora nela.")


func _on_rested(_c: Node) -> void:
	# O tempo passou: o bando de morcegos volta a ter cinco.
	var alive := get_tree().get_nodes_in_group("bat").filter(func(b): return not b.dead).size()
	for i in range(alive, BAT_HOMES.size()):
		_spawn_bat(BAT_HOMES[i])


func _on_territory_changed() -> void:
	if _territory_done or WebNetwork.cocoons.is_empty():
		return
	if WebNetwork.territory_anchor_count() >= 4 and WebNetwork._territory_strands.size() >= 3:
		_territory_done = true
		GameState.flags["g4_territorio"] = true
		EventBus.big_message.emit("Território tecido!")
		EventBus.message.emit("Dentro do território você sente o que toca nos fios e a Energia volta mais rápido. Objetivo: siga para o leste pela Ponte quebrada.")
		GameState.say_once("g4_territorio", "Meu cantinho. Meus fios. Quem tocar, eu sinto. Isso é poder.")


func _on_creature_died(c: Node) -> void:
	if c is Centipede:
		GameState.flags["g14_centopeia"] = true
		_open_door_out()
		EventBus.big_message.emit("Centopeia-blindada derrotada!")
		EventBus.message.emit("Coma a carapaça (E) para ganhar a Pele de Cristal. A passagem a leste se abriu.")
		GameState.say_once("centopeia_vitoria", "Eu. Venci. AQUILO. ...Alguém viu? Ninguém viu. Típico.")
	elif c is Lizard:
		if c.has_meta("flag"):
			GameState.flags[String(c.get_meta("flag"))] = true
		elif c.has_meta("nest_id"):
			GameState.flags["g12_lagarto_%d" % int(c.get_meta("nest_id"))] = true
		else:
			GameState.flags["g5_lagarto"] = true


func _on_room_entered(room: Dictionary) -> void:
	super._on_room_entered(room)
	var id := String(room.get("id", ""))
	if id == "G8" and not GameState.flags.has("g8_aventureiros"):
		GameState.flags["g8_aventureiros"] = true
		_adventurers_pass()



func _adventurers_pass() -> void:
	# Primeiro encontro: três humanos passam pela borda do outro lado do abismo e somem.
	for i in 3:
		var a := Adventurer.new()
		a.route = PackedVector2Array(LEDGE_ROUTE)
		a.delay = 1.5 + i * 1.3
		a.torch = i != 1
		a.color = [Color(0.55, 0.4, 0.3), Color(0.35, 0.4, 0.55), Color(0.5, 0.5, 0.45)][i]
		a.model_name = "aventureiro_" + "abc"[i]
		add_child(a)
	EventBus.hint.emit("Do outro lado do abismo... luzes. Fique parada e observe.")
	player.cam_focus = W3(138.0, 0.0, 22.0)
	player.cam_focus_time = 14.0
	get_tree().create_timer(3.0).timeout.connect(func(): GameState.say_once("g8_humanos", "Humanos?! ...Com tochas. E espadas. Melhor ficar bem quietinha."))


func _open_door_out() -> void:
	if _door_out != null and is_instance_valid(_door_out):
		_door_out.queue_free()
	_door_out = null


func _physics_process(delta: float) -> void:
	if player == null or player.dead:
		return
	var p2 := Vector2(player.global_position.x, player.global_position.z)
	if in_acid(p2) and not player.on_strand and player.resist_acid < ACID_SAFE:
		_acid_timer -= delta
		if _acid_timer <= 0.0:
			_acid_timer = 0.4
			player.take_damage(7.0 * float(ACID_SAFE - player.resist_acid) / ACID_SAFE, null, false)
		if not GameState.said.has("g11_acido"):
			EventBus.hint.emit("Ácido! Com Resistência a Ácido %d (agora: %d) dá para atravessar. Comer Sapo-de-rocha ajuda." % [ACID_SAFE, player.resist_acid])
		GameState.say_once("g11_acido", "AI, AI, queima! Volta, volta!")
	if not GameState.said.has("g16_cristal") and Fx.flat_dist(player.global_position, CRYSTAL_WALL) < 4.0:
		EventBus.hint.emit("Uma parede de cristal, e uma luz fraca lá em cima. Ainda não dá para passar.")
		GameState.say_once("g16_cristal", "Luz... lá em cima. Um dia eu volto aqui.")


func in_acid(p: Vector2) -> bool:
	for r in ACID_RECTS:
		if (r as Rect2).has_point(p):
			return true
	return false


func _on_edge(body: Node3D) -> void:
	# G15: depois da luta, o chão da borda cede e a Cavaleira cai para o Abismo.
	if _collapsing or not (body is Player) or not GameState.flags.has("g14_centopeia"):
		return
	_collapsing = true
	EventBus.message.emit("O chão está rachando...")
	GameState.say_once("g15_racha", "Ok. Isso aí não é um barulho bom.")
	var t := 0.0
	while t < 2.2:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		t += dt
		if player != null and player.camera != null:
			player.camera.h_offset = randf_range(-0.25, 0.25) * t
			player.camera.v_offset = randf_range(-0.2, 0.2) * t
	EventBus.big_message.emit("O chão cede!")
	GameState.say_once("g15_queda", "NÃO NÃO NÃO NÃO NÃÃÃÃÃO...")
	GameState.flags["ato1_fim"] = true
	await get_tree().create_timer(1.6).timeout
	go_to_layer(NEXT_LAYER)
