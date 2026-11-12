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
const BAT_HOMES := [Vector3(28, 0, -6), Vector3(28, 0, -6), Vector3(28, 0, -6), Vector3(43, 0, 10), Vector3(43, 0, 10)]
const ACID_RECTS := [Rect2(60, 72, 12, 13), Rect2(110, 72, 11, 15)]
const ACID_SAFE := 3
const CRYSTAL_WALL := Vector3(61.6, 0.0, 21.8)
const ARENA := Vector3(135, 0, 112)
const DOOR_IN := Vector3(135.5, 0.0, 94.5)
const DOOR_OUT := Vector3(157.0, 0.0, 111.5)
const NEXT_LAYER := "res://world/layers/abismo.tscn"
const ARENA_2D := Vector2(135, 112)
const LEDGE_ROUTE := [Vector2(119, 21), Vector2(138, 20.5), Vector2(157, 21)]
const DEEP := 170.0            ## as Profundezas ficam DEEP metros ao sul (mesmo plano y = 0)
const FLOOR_NAMES := ["Andar de cima", "Profundezas"]

var cave: CaveBuilder
var centipede: Centipede
var _door_out: StaticBody3D
var _collapsing := false
var _territory_done := false
var _acid_timer := 0.0


func _configure() -> void:
	layer_id = "G"
	layer_name = "Galerias Úmidas"
	layer_subtitle = "Ato 1 · Você ainda é uma Filhote. Fuja do que é maior, cace o que é menor."
	spawn_point = Vector3(1.0, 0.1, -17.0)
	ambient_color = Color(0.42, 0.56, 0.58)
	ambient_energy = 0.34
	fog_color = Color(0.04, 0.07, 0.07)
	rooms = [
		{"id": "G1", "name": "Entrada", "checkpoint": true,
			"shapes": [CaveBuilder.blob(Vector2(0, 0), 9.0, 1.2)],
			"hint": "Fungos verdes marcam o caminho. Dois caminhos levam à Grande Gruta: a poça ao sul ou o túnel a leste.",
			"line_id": "galerias", "line": "Galerias úmidas... cheiro de musgo. E de comida."},
		{"id": "G2", "name": "Poça rasa",
			"shapes": [CaveBuilder.blob(Vector2(-2, 34), 10.0, 1.4)],
			"hint": "Algo grande espera perto da poça. Segure Alt (Leitura) para ver o que cada criatura sente e o quanto ela é perigosa.",
			"line_id": "g2_poca", "line": "Aquela pedra perto da água... piscou?"},
		{"id": "G3", "name": "Túnel dos morcegos",
			"shapes": [CaveBuilder.path([Vector2(8, -3), Vector2(18, -8), Vector2(30, -6), Vector2(40, 0), Vector2(44, 10), Vector2(44, 26)], 7.0, 0.8)],
			"hint": "Morcegos-eco ouvem quem se mexe: fique parada e eles perdem você. Fio esticado entre pilares derruba quem voa por ele, e Q lança fio para o alto.",
			"line_id": "g3_morcegos", "line": "Um túnel cheio de asas. Que maravilha."},
		{"id": "G4", "name": "Grande Gruta", "checkpoint": true,
			"shapes": [CaveBuilder.ellipse(Vector2(44, 36), 16.0, 12.0, 0.15, 1.5)],
			"hint": "Teça um casulo (C) para salvar. Depois ligue com fios (R) os pilares perto dele: tudo o que estiver ligado ao casulo vira seu território.",
			"line_id": "g4_gruta", "line": "Espaço, pilares, ninguém me caçando... por enquanto. Aqui vai ser minha casa."},
		{"id": "G5", "name": "Jardim de musgo",
			"shapes": [CaveBuilder.blob(Vector2(44, 72), 11.0, 1.6)],
			"hint": "O Lagarto-lanterna atrai larvas com a luz e defende o jardim. A isca revela você de perto, mesmo com a runa apagada.",
			"line_id": "g5_lagarto", "line": "Uma lanterna com dentes. Claro."},
		{"id": "G6", "name": "Ponte quebrada", "checkpoint": true,
			"shapes": [CaveBuilder.path([Vector2(59, 37), Vector2(72, 40), Vector2(86, 36), Vector2(100, 38), Vector2(114, 36)], 8.0, 0.8)],
			"hint": "Três fendas seguidas. Em cada uma, teça um fio entre os pilares (R) ou lance fio na parede do outro lado (Q).",
			"line_id": "g6_ponte", "line": "Quem quebrou essa ponte? ...Eu nem sei se isso era uma ponte."},
		{"id": "G7", "name": "Lago escondido",
			"shapes": [CaveBuilder.ellipse(Vector2(2, 74), 14.0, 11.0, 0.0, 1.0)],
			"hint": "Aranhas não nadam. Só uma corrente de fios leva até a ilha: primeiro a pedrinha no meio do caminho.",
			"line_id": "g7_lago", "line": "Tem algo brilhando na ilha. E eu odeio água."},
		{"id": "G8", "name": "Galeria do eco", "checkpoint": true,
			"shapes": [CaveBuilder.ellipse(Vector2(138, 39), 13.0, 10.0, 0.0, 1.0),
				CaveBuilder.path([Vector2(118, 26.5), Vector2(158, 26.5)], 9.0, 0.4),
				CaveBuilder.path([Vector2(118, 21), Vector2(158, 21)], 4.5, 0.4)],
			"hint": "Um abismo largo, e do outro lado uma borda de pedra. A galeria devolve qualquer som... fique atenta.",
			"line_id": "g8_eco", "line": "Eco... eco... Que lugar pra uma aranha com medo de barulho."},
		{"id": "G9", "name": "Acampamento",
			"shapes": [CaveBuilder.blob(Vector2(182, 44), 10.0, 1.2)],
			"hint": "Um acampamento abandonado. Fogo QUEIMA fios: não estique teia perto das tochas. Aperte E nas anotações para ler.",
			"line_id": "g9_acampamento", "line": "Gente esteve aqui. Gente com fogo. Por que tudo aqui tem que ter fogo?"},
		{"id": "G10", "name": "Fresta de cristal",
			"shapes": [CaveBuilder.blob(Vector2(168, 13), 3.6, 0.5)],
			"hint": "Cristais que brilham como a sua runa. Aperte E para examinar.",
			"line_id": "g10_fresta", "line": "Tá brilhando no mesmo ritmo que eu. Isso é bonito ou assustador?"},
		{"id": "G11", "name": "Poças ácidas",
			"shapes": [CaveBuilder.path([Vector2(54, 74), Vector2(64, 78), Vector2(80, 82), Vector2(96, 80), Vector2(112, 83), Vector2(133, 78)], 6.0, 0.8)],
			"hint": "Ácido no chão. Com Resistência a Ácido 3 dá para atravessar: dizem que quem come Sapo-de-rocha aguenta mais.",
			"line_id": "g11_pocas", "line": "Cheiro de ovo podre e metal. Meus pés já estão reclamando."},
		{"id": "G12", "name": "Ninho dos lagartos",
			"shapes": [CaveBuilder.blob(Vector2(43, 104), 11.0, 1.6)],
			"hint": "Três Lagartos-lanterna, cada um com o seu território. As iscas revelam você de perto. Escolha bem por onde passar.",
			"line_id": "g12_ninho", "line": "Uma, duas, três lanternas. E todas com fome."},
		{"id": "G13", "name": "Antecâmara", "checkpoint": true,
			"shapes": [CaveBuilder.blob(Vector2(135, 77), 8.0, 1.0)],
			"hint": "Último lugar seguro antes do covil. Teça um casulo (C) e descanse: depois daqui não tem volta fácil.",
			"line_id": "g13_antecamara", "line": "Dá pra sentir o chão tremendo daqui. Ela é GRANDE."},
		{"id": "G14", "name": "Covil da Centopeia",
			"shapes": [CaveBuilder.ellipse(ARENA_2D, 15.0, 12.0, 0.0, 1.2)]},
		{"id": "G15", "name": "Borda da Fenda",
			"shapes": [CaveBuilder.blob(Vector2(172, 110), 7.0, 1.0)]},
		{"id": "G16", "name": "Subida antiga",
			"shapes": [CaveBuilder.ellipse(Vector2(76, 4), 9.0, 8.0, 0.4, 1.0)]},
		# --- becos novos do andar de cima ---
		{"id": "G17", "name": "Beco dos ossos",
			"shapes": [CaveBuilder.blob(Vector2(-26, -6), 7.5, 1.2)],
			"line_id": "g17_ossos", "line": "Ossos. Muitos ossos. Alguém come aqui... e não limpa."},
		{"id": "G18", "name": "Galeria torta",
			"shapes": [CaveBuilder.path([Vector2(52, 66), Vector2(62, 60), Vector2(72, 57), Vector2(80, 49)], 5.0, 0.6)],
			"hint": "Um atalho para o meio da Ponte quebrada... com uma fenda no caminho. Cair aqui não é o fim: é pior. É lá embaixo.",
			"line_id": "g18_torta", "line": "Um atalho! Que tem um buraco. Óbvio."},
		{"id": "G19", "name": "Poço das raízes",
			"shapes": [CaveBuilder.blob(Vector2(43, 128), 7.0, 1.0)],
			"line_id": "g19_poco", "line": "Raízes descendo pro escuro. Bem fundo. Bem, bem fundo."},
		{"id": "G20", "name": "Mirante",
			"shapes": [CaveBuilder.blob(Vector2(194, 20), 6.5, 1.0)],
			"line_id": "g20_mirante", "line": "Daqui dá pra ver o nada. Muito nada."},
		# --- Profundezas (andar de baixo) ---
		{"id": "P1", "name": "Fundo da ponte", "floor": 1,
			"shapes": [CaveBuilder.ellipse(Vector2(86, 208), 23.0, 8.5, 0.0, 1.2)],
			"hint": "Você caiu nas Profundezas. Duas rampas levam de volta para cima: uma a oeste (Poça rasa), outra no fundo leste (Antecâmara).",
			"line_id": "p1_fundo", "line": "Ai... minhas pernas. Todas as oito. Onde eu tô?"},
		{"id": "P2", "name": "Leito seco", "floor": 1,
			"shapes": [CaveBuilder.path([Vector2(62, 212), Vector2(48, 220), Vector2(32, 216), Vector2(22, 214)], 6.0, 0.7)]},
		{"id": "P3", "name": "Ninho dos sapos", "floor": 1,
			"shapes": [CaveBuilder.blob(Vector2(16, 232), 10.0, 1.4)],
			"line_id": "p3_sapos", "line": "Um. Dois. Quatro. Ok, isso é um ninho. De SAPOS."},
		{"id": "P4", "name": "Galeria das raízes", "floor": 1,
			"shapes": [CaveBuilder.path([Vector2(22, 240), Vector2(34, 250), Vector2(42, 255)], 5.0, 0.7)]},
		{"id": "P5", "name": "Fundo do poço", "floor": 1,
			"shapes": [CaveBuilder.blob(Vector2(44, 262), 7.0, 1.0)]},
		{"id": "P6", "name": "Salão dos ecos baixos", "floor": 1,
			"shapes": [CaveBuilder.ellipse(Vector2(138, 196), 24.0, 8.5, 0.0, 1.2)]},
		{"id": "P7", "name": "Túnel úmido", "floor": 1,
			"shapes": [CaveBuilder.path([Vector2(106, 208), Vector2(117, 202)], 4.5, 0.5)]},
		{"id": "P8", "name": "Bifurcação", "floor": 1,
			"shapes": [CaveBuilder.blob(Vector2(150, 222), 7.0, 1.0)]},
		{"id": "P9", "name": "Beco do musgo negro", "floor": 1,
			"shapes": [CaveBuilder.blob(Vector2(176, 234), 6.5, 1.0)]},
		{"id": "P10", "name": "Fenda dupla", "floor": 1,
			"shapes": [CaveBuilder.path([Vector2(148, 229), Vector2(138, 246), Vector2(122, 258)], 7.0, 0.6)],
			"hint": "Duas fendas sem fundo cortam o caminho. Fio entre os pilares, ou volta.",
			"line_id": "p10_fendas", "line": "Essas não têm fundo. Eu sei. Eu SINTO."},
		{"id": "P11", "name": "Rampa velha", "floor": 1, "checkpoint": true,
			"shapes": [CaveBuilder.blob(Vector2(110, 265), 6.5, 1.0)]},
	]
	locks = [
		{"type": "cristal", "pos": CRYSTAL_WALL},
		{"type": "acido", "pos": Vector3(64, 0, 78)},
		{"type": "acido", "pos": Vector3(116, 0, 81)},
		{"type": "fresta", "pos": Vector3(164, 0, 32)},
	]


func _build_level() -> void:
	cave = CaveBuilder.new()
	cave.floor_color = Color(0.27, 0.32, 0.3)
	cave.rock_color = Color(0.17, 0.21, 0.21)
	cave.noise.seed = 31
	cave.rooms = rooms
	cave.tunnels = [
		CaveBuilder.path([Vector2(0, -24), Vector2(3, -14), Vector2(0, -7)], 3.6, 0.4),                 # chegada do Berçário
		CaveBuilder.path([Vector2(-2, 7), Vector2(-5, 17), Vector2(-3, 26)], 4.5, 0.5),                 # G1 → G2
		CaveBuilder.path([Vector2(6, 36), Vector2(17, 39), Vector2(31, 37)], 4.5, 0.5),                 # G2 → G4
		CaveBuilder.path([Vector2(55, 29), Vector2(63, 20), Vector2(71, 10)], 4.0, 0.3),                # G4 → G16 (parede de cristal)
		CaveBuilder.path([Vector2(33, 44), Vector2(22, 54), Vector2(13, 67)], 2.6, 0.3),                # G4 → G7, estreito e escuro
		CaveBuilder.path([Vector2(44, 46), Vector2(47, 55), Vector2(44, 63)], 5.0, 0.5),                # G4 → G5
		CaveBuilder.path([Vector2(44, 81), Vector2(43, 94)], 4.0, 0.3),                                 # G5 → G12
		CaveBuilder.path([Vector2(112, 36), Vector2(127, 38)], 3.6, 0.3),                               # G6 → G8
		CaveBuilder.path([Vector2(145, 42), Vector2(161, 47), Vector2(178, 44)], 5.6, 0.4),             # G8 → G9
		CaveBuilder.path([Vector2(150, 39), Vector2(160, 37), Vector2(165, 31), Vector2(167, 17)], 1.15, 0.0),  # fresta G8 → G10
		CaveBuilder.path([Vector2(180, 47), Vector2(176, 52), Vector2(160, 63), Vector2(137, 76)], 5.6, 0.4),             # G9 → G13 (a Centopeia passa)
		CaveBuilder.path([Vector2(135, 84), Vector2(136, 92), Vector2(135, 101)], 5.0, 0.3),            # G13 → G14
		CaveBuilder.path([Vector2(149, 112), Vector2(158, 111), Vector2(166, 110)], 4.0, 0.3),          # G14 → G15
		CaveBuilder.path([Vector2(-7, -1), Vector2(-14, -4), Vector2(-20, -5)], 3.4, 0.3),              # G1 → G17
		CaveBuilder.path([Vector2(43, 114), Vector2(43, 122)], 3.6, 0.3),                               # G12 → G19
		CaveBuilder.path([Vector2(186, 35), Vector2(191, 27)], 3.4, 0.3),                               # G9 → G20
		# Profundezas
		CaveBuilder.path([Vector2(22, 216), Vector2(18, 224)], 4.5, 0.4),                               # P2 → P3
		CaveBuilder.path([Vector2(18, 240), Vector2(24, 242)], 4.5, 0.4),                               # P3 → P4
		CaveBuilder.path([Vector2(42, 255), Vector2(44, 258)], 4.0, 0.3),                               # P4 → P5
		CaveBuilder.path([Vector2(146, 203), Vector2(150, 216)], 4.5, 0.4),                             # P6 → P8
		CaveBuilder.path([Vector2(156, 224), Vector2(170, 232)], 3.4, 0.3),                             # P8 → P9
		CaveBuilder.path([Vector2(122, 258), Vector2(114, 263)], 4.5, 0.3),                             # P10 → P11
	]
	cave.chasms = [
		CaveBuilder.path([Vector2(70, 29), Vector2(71, 49)], 4.5, 0.3),        # 1ª fenda da Ponte quebrada
		CaveBuilder.path([Vector2(85, 26), Vector2(86, 46)], 4.5, 0.3),        # 2ª
		CaveBuilder.path([Vector2(99, 28), Vector2(100, 48)], 5.0, 0.3),       # 3ª
		CaveBuilder.ellipse(Vector2(0, 74), 10.0, 7.5, 0.0, 0.4),              # lago
		CaveBuilder.ellipse(Vector2(77, 2), 6.0, 5.0, 0.4, 0.4),               # abismo longo da G16
		CaveBuilder.path([Vector2(116, 26.5), Vector2(160, 26)], 6.0, 0.4),    # abismo da Galeria do eco
		CaveBuilder.path([Vector2(178, 99), Vector2(181, 121)], 5.5, 0.6),     # a Fenda, na borda leste da G15
		CaveBuilder.blob(Vector2(-27, -6), 2.2, 0.3),                          # poço sem fundo do Beco dos ossos
		CaveBuilder.path([Vector2(66, 53.5), Vector2(68.5, 62.5)], 3.6, 0.2),  # fenda da Galeria torta
		CaveBuilder.ellipse(Vector2(43, 129), 3.5, 3.0, 0.0, 0.3),             # Poço das raízes
		CaveBuilder.blob(Vector2(200.5, 18), 2.6, 0.3),                        # beirada do Mirante
		CaveBuilder.path([Vector2(138.7, 235.5), Vector2(147.3, 240.5)], 3.5, 0.2),   # Fenda dupla, 1ª
		CaveBuilder.path([Vector2(127.6, 248.8), Vector2(132.4, 255.2)], 3.5, 0.2),   # Fenda dupla, 2ª
	]
	cave.bridges = [
		CaveBuilder.blob(Vector2(-3, 74), 2.6, 0.3),    # ilha do lago
		CaveBuilder.blob(Vector2(5, 70.5), 1.4, 0.15),  # pedrinha no meio do caminho
	]
	map_grid = cave.build(self)
	cave.scatter_decor(self, 23)
	# Quedas (v0.8): fendas com andar de baixo levam às Profundezas; o lago devolve à margem.
	# Sem "to" = sem fundo (G16, a Fenda da G15, o poço do Beco dos ossos, o Mirante, a Fenda dupla).
	var down := Vector3(0, 0, DEEP)
	chasms = [
		{"rect": Rect2(-10, 66.5, 20, 15), "mode": "volta", "name": "o lago"},
		{"rect": Rect2(67, 28, 7, 22), "drop": down, "to": Vector3(70, 0, 208), "name": "as Profundezas"},
		{"rect": Rect2(82, 25, 7, 22), "drop": down, "to": Vector3(85, 0, 208), "name": "as Profundezas"},
		{"rect": Rect2(96.5, 27, 7, 22), "drop": down, "to": Vector3(100, 0, 208), "name": "as Profundezas"},
		{"rect": Rect2(113, 22.5, 50, 8), "drop": down, "to": Vector3(138, 0, 196), "name": "as Profundezas"},
		{"rect": Rect2(63.5, 51, 7.5, 14), "to": Vector3(72, 0, 208), "name": "as Profundezas"},
		{"rect": Rect2(39, 125, 8, 8.5), "to": Vector3(44, 0, 262), "name": "o Fundo do poço"},
	]

	var pillars := {
		"G1_a": Vector3(-5, 0, -3), "G1_b": Vector3(5, 0, 3), "G1_c": Vector3(-3, 0, 5),
		"G2_a": Vector3(4, 0, 28), "G2_b": Vector3(-9, 0, 40), "G2_c": Vector3(5, 0, 40),
		"G3_a": Vector3(25, 0, -8.8), "G3_b": Vector3(31, 0, -3.4), "G3_c": Vector3(37, 0, 0.2),
		"G3_d": Vector3(41.5, 0, -1), "G3_e": Vector3(41.5, 0, 12), "G3_f": Vector3(46.5, 0, 14),
		"G4_a": Vector3(39, 0, 32), "G4_b": Vector3(50, 0, 34), "G4_c": Vector3(45, 0, 41),
		"G4_d": Vector3(32, 0, 36), "G4_e": Vector3(38, 0, 26.5), "G4_f": Vector3(51, 0, 27),
		"G4_g": Vector3(57, 0, 38), "G4_h": Vector3(50, 0, 45), "G4_i": Vector3(36, 0, 44),
		"G5_a": Vector3(37, 0, 67), "G5_b": Vector3(51, 0, 67), "G5_c": Vector3(50, 0, 79), "G5_d": Vector3(37, 0, 78),
		"G6_a": Vector3(66, 0, 36.5), "G6_b": Vector3(65.5, 0, 41), "G6_c": Vector3(75.5, 0, 37), "G6_d": Vector3(75.5, 0, 41.5),
		"G6_e": Vector3(81, 0, 35.5), "G6_f": Vector3(81, 0, 39.5), "G6_g": Vector3(90, 0, 34.8), "G6_h": Vector3(90, 0, 38.8),
		"G6_i": Vector3(95, 0, 35.5), "G6_j": Vector3(95, 0, 39.5), "G6_k": Vector3(104.5, 0, 35.5), "G6_l": Vector3(104.5, 0, 39.5),
		"G7_a": Vector3(13, 0, 72), "G7_b": Vector3(5, 0, 70.5), "G7_c": Vector3(-3, 0, 74),
		"G8_a": Vector3(129, 0, 36), "G8_b": Vector3(138, 0, 44), "G8_c": Vector3(146, 0, 35),
		"G9_a": Vector3(175, 0, 40), "G9_b": Vector3(189, 0, 40), "G9_c": Vector3(184, 0, 51), "G9_d": Vector3(178, 0, 48),
		"G11_a": Vector3(84, 0, 83.4), "G11_b": Vector3(100, 0, 78.2), "G11_c": Vector3(122, 0, 82.2),
		"G12_a": Vector3(36, 0, 98), "G12_b": Vector3(50, 0, 98), "G12_c": Vector3(36, 0, 110), "G12_d": Vector3(50, 0, 110),
		"G13_a": Vector3(130, 0, 73), "G13_b": Vector3(140, 0, 73), "G13_c": Vector3(129, 0, 80),
		"G15_a": Vector3(167, 0, 106), "G15_b": Vector3(168, 0, 114), "G15_c": Vector3(173, 0, 110),
		"G17_a": Vector3(-22, 0, -9), "G17_b": Vector3(-30, 0, -11), "G17_c": Vector3(-30.5, 0, -2.5),
		"G18_a": Vector3(63.5, 0, 59.2), "G18_b": Vector3(71, 0, 56.8),
		"G19_a": Vector3(38.5, 0, 127), "G19_b": Vector3(47.5, 0, 127), "G19_c": Vector3(43, 0, 123.2),
		"G20_a": Vector3(191, 0, 16), "G20_b": Vector3(196, 0, 25),
		"P1_a": Vector3(75, 0, 204), "P1_b": Vector3(75, 0, 212), "P1_c": Vector3(95, 0, 204), "P1_d": Vector3(95, 0, 212),
		"P3_a": Vector3(10, 0, 228), "P3_b": Vector3(22, 0, 236), "P3_c": Vector3(12, 0, 238),
		"P5_a": Vector3(40, 0, 258), "P5_b": Vector3(48, 0, 266),
		"P6_a": Vector3(126, 0, 193), "P6_b": Vector3(150, 0, 199), "P6_c": Vector3(138, 0, 201),
		"P8_a": Vector3(146, 0, 219), "P8_b": Vector3(154, 0, 226),
		"P9_a": Vector3(174, 0, 230), "P9_b": Vector3(179, 0, 238),
		"P10_a": Vector3(145, 0, 234.1), "P10_b": Vector3(140.8, 0, 241.2), "P10_c": Vector3(137.5, 0, 246.5),
		"P10_d": Vector3(134, 0, 249), "P10_e": Vector3(126, 0, 255),
		"P11_a": Vector3(106, 0, 262), "P11_b": Vector3(114, 0, 268),
	}
	for k in 8:
		var ang := k * TAU / 8.0 + PI / 8.0
		pillars["G14_%d" % k] = ARENA + Vector3(cos(ang) * 9.0, 0.0, sin(ang) * 7.0)
	var i := 0
	for n in pillars:
		var pos: Vector3 = pillars[n]
		var small := String(n) == "G7_b"
		add_anchor(n, pos, 2.5 if small else 3.5, 0.4 if small else 0.5, STONE, "estalagmite_" + "abc"[i % 3])
		i += 1
		if not cave.is_floor(Vector2(pos.x, pos.z), 0.45):
			push_warning("Pilar %s fora do chão firme em %s" % [n, pos])

	_build_pond(Vector3(-4, 0.03, 36), 3.4)
	_build_lake()
	_build_crystal_wall()
	_build_acid()
	_build_camp()
	_build_doors()

	for w in [Vector3(-6, 0, -5), Vector3(40, 0, 38), Vector3(48, 0, 31), Vector3(100, 0, 41), Vector3(28, 0, -3)]:
		add_web_decal(w, 2.2)

	# Fungos verdes marcam o caminho principal; o túnel do lago não tem nenhum
	for f in [Vector3(130, 0, 40), Vector3(146, 0, 42), Vector3(160, 0, 46), Vector3(150, 0, 58), Vector3(133, 0, 75),
			Vector3(137, 0, 88), Vector3(155, 0, 111), Vector3(52, 0, 76), Vector3(90, 0, 79), Vector3(44, 0, 90),
			Vector3(2, 0, -21), Vector3(-1, 0, -10), Vector3(6, 0, -6), Vector3(-6, 0, 6), Vector3(-5, 0, 16), Vector3(4, 0, 31),
			Vector3(14, 0, 38), Vector3(12, 0, -6), Vector3(22, 0, -10), Vector3(36, 0, -4), Vector3(46, 0, 18),
			Vector3(34, 0, 30), Vector3(55, 0, 33), Vector3(44, 0, 50), Vector3(62, 0, 39), Vector3(78, 0, 43),
			Vector3(92, 0, 41), Vector3(108, 0, 40), Vector3(118, 0, 36), Vector3(40, 0, 64), Vector3(50, 0, 76),
			Vector3(-8, 0, 30), Vector3(12, 0, 77)]:
		if cave.is_floor(Vector2(f.x, f.z), 0.2):
			add_fungus(f, GREEN)
	for f in [Vector3(38, 0, 72), Vector3(48, 0, 68), Vector3(44, 0, 77), Vector3(40, 0, 78)]:
		add_fungus(f, Color(0.75, 0.5, 1.0))
	# Profundezas: poucos fungos roxos (é mais escuro lá embaixo) e os becos novos de cima
	for f in [Vector3(80, 0, 206), Vector3(96, 0, 210), Vector3(30, 0, 216), Vector3(14, 0, 228), Vector3(36, 0, 252),
			Vector3(44, 0, 262), Vector3(130, 0, 194), Vector3(148, 0, 198), Vector3(150, 0, 222), Vector3(176, 0, 234),
			Vector3(110, 0, 265), Vector3(-24, 0, -4), Vector3(60, 0, 61), Vector3(43, 0, 122), Vector3(192, 0, 22)]:
		if cave.is_floor(Vector2(f.x, f.z), 0.2):
			add_fungus(f, Color(0.6, 0.45, 1.0))
	# Rampas entre os andares
	add_passage(Rect2(-9.2, 30.8, 2.4, 2.4), Vector3(27, 0, 215), "Você desceu a rampa para as Profundezas.", "Rampa para as Profundezas")
	add_passage(Rect2(20.8, 212.8, 2.4, 2.4), Vector3(-3, 0, 29), "Você subiu de volta para a Poça rasa.", "Rampa para cima")
	add_passage(Rect2(137.3, 79.3, 2.4, 2.4), Vector3(108, 0, 267), "Você desceu a rampa para as Profundezas.", "Rampa para as Profundezas")
	add_passage(Rect2(111.8, 261.8, 2.4, 2.4), Vector3(134, 0, 75.5), "Você subiu para a Antecâmara.", "Rampa para cima")
	# Luz fria vinda de baixo, na Borda da Fenda
	var deep := OmniLight3D.new()
	deep.light_color = Color(0.45, 0.55, 1.0)
	deep.omni_range = 10.0
	deep.light_energy = 1.0
	deep.position = Vector3(180, -2, 110)
	add_child(deep)
	# A luz fraca lá em cima, na Subida antiga
	var high := OmniLight3D.new()
	high.light_color = Color(1.0, 0.85, 0.6)
	high.omni_range = 14.0
	high.light_energy = 0.9
	high.position = Vector3(78, 9, 2)
	add_child(high)


func _build_pond(pos: Vector3, radius: float) -> void:
	var water := Fx.cylinder(radius, 0.02, Fx.mat(Color(0.12, 0.25, 0.32), 0.25, false, 0.75))
	water.position = pos
	water.scale = Vector3(1.0, 1.0, 0.75)
	add_child(water)


func _build_lake() -> void:
	var water := Fx.cylinder(1.0, 0.04, Fx.mat(Color(0.08, 0.2, 0.3), 0.35, false, 0.82))
	water.position = Vector3(0, -0.8, 74)
	water.scale = Vector3(11.0, 1.0, 8.5)
	add_child(water)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.3, 0.6, 0.9)
	glow.omni_range = 10.0
	glow.light_energy = 0.5
	glow.position = Vector3(0, 0.5, 74)
	add_child(glow)


func _build_crystal_wall() -> void:
	# Parede de cristal na passagem para a Subida antiga (abre no Ato 4).
	var body := add_static_box(Vector3(5.0, 3.0, 0.8), CRYSTAL_WALL + Vector3(0, 1.6, 0), Color(0.55, 0.75, 1.0))
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
	var tent := add_static_box(Vector3(3.2, 1.8, 2.6), Vector3(176.5, 0.9, 47.5), canvas)
	tent.rotation.y = 0.3
	add_static_box(Vector3(1.0, 0.9, 1.0), Vector3(188.5, 0.45, 48.0), Color(0.42, 0.3, 0.2))
	add_static_box(Vector3(0.8, 0.7, 0.8), Vector3(189.3, 0.35, 46.9), Color(0.42, 0.3, 0.2))
	for b in [Vector3(181, 0.03, 40.5), Vector3(185, 0.03, 42), Vector3(179, 0.03, 43)]:
		var roll := Fx.box(Vector3(0.9, 0.06, 2.0), Fx.mat(Color(0.35, 0.3, 0.42)))
		roll.position = b
		roll.rotation.y = b.x * 0.4
		add_child(roll)
	for t in [Vector3(177, 0, 41), Vector3(187, 0, 41), Vector3(182, 0, 51)]:
		var torch := Fire.new(1.0)
		torch.position = t
		add_child(torch)
	var campfire := Fire.new(0.7)
	campfire.position = Vector3(182, 0, 45)
	add_child(campfire)
	add_child(_note(Vector3(183.5, 0, 46.5), "g9_diario", [
		"Diário de expedição, dia 3. A guilda paga bem por seda de aranha-da-runa. Ninguém sabe se elas ainda existem.",
		"Dia 5. Achamos a pele de uma centopeia gigante mais ao sul. Do tamanho de uma carroça. O Tobias quer voltar.",
		"Dia 6. Alguma coisa toca as nossas cordas à noite. Mantenham as tochas acesas: fogo queima teia.",
	], "papel"))
	add_child(_note(Vector3(168, 0, 12), "g10_visao", [
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
	var body := add_static_box(Vector3(5.5, 3.0, 1.4), pos + Vector3(0, 1.5, 0), Color(0.3, 0.32, 0.33))
	body.rotation.y = rot
	if pos == DOOR_OUT:
		body.rotation.y = PI * 0.5
	return body


func _populate() -> void:
	ecosystem.larva_spawns = [
		Vector3(-4, 0, 2), Vector3(4, 0, -3), Vector3(-2, 0, 30), Vector3(3, 0, 38),
		Vector3(40, 0, 70), Vector3(48, 0, 74), Vector3(41, 0, 77), Vector3(47, 0, 66), Vector3(38, 0, 73),
		Vector3(50, 0, 40), Vector3(10, 0, 74),
	]
	ecosystem.larva_spawns.append_array([Vector3(40, 0, 102), Vector3(46, 0, 106), Vector3(133, 0, 40), Vector3(180, 0, 56)])
	ecosystem.larva_spawns.append_array([Vector3(80, 0, 210), Vector3(92, 0, 206), Vector3(40, 0, 218), Vector3(16, 0, 226),
		Vector3(36, 0, 250), Vector3(46, 0, 262), Vector3(132, 0, 196), Vector3(176, 0, 234), Vector3(60, 0, 61)])
	ecosystem.frog_spawns = [Vector3(-5, 0, 38), Vector3(188, 0, 50), Vector3(66, 0, 58), Vector3(43, 0, 126),
		Vector3(14, 0, 230), Vector3(20, 0, 234), Vector3(140, 0, 198), Vector3(150, 0, 222)]
	ecosystem.larva_target = 20
	ecosystem.frog_target = 8
	ecosystem.on_spawn = _setup_creature
	ecosystem.spawn_initial()
	for home in BAT_HOMES:
		_spawn_bat(home)
	for k in 3:
		_spawn_bat(Vector3(66, 0, 58), ["G18", "G5", "G6"], "g18")
	for k in 4:
		_spawn_bat(Vector3(138, 0, 196), ["P6", "P7", "P8", "P1"], "p6")
	# Profundezas: lagartos e irmãs famintas que fugiram do ninho e viraram caçadoras
	for lz_def in [["p1_lagarto", Vector3(86, 0.3, 209), 7.0], ["p9_lagarto", Vector3(177, 0.3, 235), 6.0]]:
		if not GameState.flags.has(lz_def[0]):
			var dlz := Lizard.new()
			dlz.position = lz_def[1]
			dlz.territory_radius = lz_def[2]
			dlz.set_meta("flag", lz_def[0])
			ecosystem.add_child(dlz)
	for sp in [Vector3(-27, 0.3, -1), Vector3(194, 0.3, 21), Vector3(34, 0.3, 250), Vector3(112, 0.3, 205), Vector3(135, 0.3, 248)]:
		var sis := Sister.new(true)
		sis.position = sp
		sis.display_name = "Irmã caçadora"
		ecosystem.add_child(sis)
	if not GameState.flags.has("g5_lagarto"):
		var lz := Lizard.new()
		lz.position = Vector3(44, 0.3, 73)
		ecosystem.add_child(lz)
	for i in 3:
		if GameState.flags.has("g12_lagarto_%d" % i):
			continue
		var nest := Lizard.new()
		nest.position = [Vector3(37, 0.3, 101), Vector3(49, 0.3, 101), Vector3(43, 0.3, 109)][i] as Vector3
		nest.territory_radius = 6.0
		nest.food_energy = 5.0
		nest.set_meta("nest_id", i)
		ecosystem.add_child(nest)
	for pk in [["cristal_en", "g7_cristal", Vector3(-4.2, 0, 75.2)], ["cristal_en", "g12_cristal", Vector3(43, 0, 104)], ["cristal_pv", "g10_cristal", Vector3(169.5, 0, 14.5)],
			["cristal_pv", "g17_cristal", Vector3(-31.5, 0, -6)], ["cristal_pv", "p9_cristal", Vector3(179, 0, 234)], ["cristal_en", "p5_cristal", Vector3(47, 0, 263)]]:
		if not GameState.flags.has(pk[1]):
			var crystal := Pickup.new(pk[0], pk[1])
			crystal.position = pk[2]
			add_child(crystal)
	if not GameState.flags.has("g14_centopeia"):
		centipede = Centipede.new()
		centipede.position = ARENA + Vector3(0, 0.3, 4)
		centipede.arena_center = ARENA
		centipede.den = ARENA
		centipede.range_rooms = ["G8", "G9", "G11", "G13", "G14"]
		ecosystem.add_child(centipede)
	else:
		_open_door_out()
	add_trigger(Rect2(165, 104, 10, 12), _on_edge)
	EventBus.rested.connect(_on_rested)
	EventBus.territory_changed.connect(_on_territory_changed)
	EventBus.creature_died.connect(_on_creature_died)


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
		if q.z > 150.0:
			c.range_rooms = ["P3", "P2", "P4", "P1"] if q.x < 70.0 else ["P6", "P8", "P7", "P1"]
		elif q.z > 115.0:
			c.range_rooms = ["G19", "G12"]
		elif q.x > 58.0 and q.x < 82.0 and q.z > 48.0:
			c.range_rooms = ["G18", "G5", "G6"]
		else:
			c.range_rooms = ["G9", "G8", "G13"] if q.x > 100.0 else ["G2", "G1", "G4", "G5"]


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
	player.cam_focus = Vector3(138.0, 0.0, 22.0)
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
