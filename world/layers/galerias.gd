extends LayerBase
## G — Galerias Úmidas, primeira parte (Ato 1): G1 a G7, mais a vista da G16.
## A Grande Gruta (G4) é o centro: dois caminhos levam até ela (a poça do sapo ou o túnel
## dos morcegos), o Jardim de musgo fica ao sul, o Lago escondido a sudoeste e a
## Ponte quebrada a leste. Coordenadas em metros: x para leste, z para o sul.
## Ver a aba "Mapa da Fenda" do GDD.

const STONE := Color(0.4, 0.43, 0.44)
const GREEN := Color(0.45, 1.0, 0.6)
const BAT_HOMES := [Vector3(28, 0, -6), Vector3(28, 0, -6), Vector3(28, 0, -6), Vector3(43, 0, 10), Vector3(43, 0, 10)]
const ACID_RECT := Rect2(61, 72, 9, 8)
const CRYSTAL_WALL := Vector3(61.6, 0.0, 21.8)

var cave: CaveBuilder
var _leaving := false
var _territory_done := false
var _acid_timer := 0.0


func _configure() -> void:
	layer_id = "G"
	layer_name = "Galerias Úmidas"
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
		{"id": "G16", "name": "Subida antiga",
			"shapes": [CaveBuilder.ellipse(Vector2(76, 4), 9.0, 8.0, 0.4, 1.0)]},
	]
	locks = [
		{"type": "cristal", "pos": CRYSTAL_WALL},
		{"type": "acido", "pos": Vector3(64, 0, 76)},
		{"type": "desabamento", "pos": Vector3(43.5, 0, 88)},
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
		CaveBuilder.path([Vector2(53, 74), Vector2(62, 77), Vector2(69, 76)], 4.0, 0.3),                # G5 → G11 (ácido)
		CaveBuilder.path([Vector2(44, 81), Vector2(43, 90)], 4.0, 0.3),                                 # G5 → G12 (desabamento)
		CaveBuilder.path([Vector2(112, 36), Vector2(123, 37)], 3.0, 0.2),                               # G6 → G8
	]
	cave.chasms = [
		CaveBuilder.path([Vector2(70, 29), Vector2(71, 49)], 4.5, 0.3),        # 1ª fenda da Ponte quebrada
		CaveBuilder.path([Vector2(85, 26), Vector2(86, 46)], 4.5, 0.3),        # 2ª
		CaveBuilder.path([Vector2(99, 28), Vector2(100, 48)], 5.0, 0.3),       # 3ª
		CaveBuilder.ellipse(Vector2(0, 74), 10.0, 7.5, 0.0, 0.4),              # lago
		CaveBuilder.ellipse(Vector2(77, 2), 6.0, 5.0, 0.4, 0.4),               # abismo longo da G16
	]
	cave.bridges = [
		CaveBuilder.blob(Vector2(-3, 74), 2.6, 0.3),    # ilha do lago
		CaveBuilder.blob(Vector2(5, 70.5), 1.4, 0.15),  # pedrinha no meio do caminho
	]
	map_grid = cave.build(self)
	cave.scatter_decor(self, 23)

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
	}
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
	_build_rockfall()

	for w in [Vector3(-6, 0, -5), Vector3(40, 0, 38), Vector3(48, 0, 31), Vector3(100, 0, 41), Vector3(28, 0, -3)]:
		add_web_decal(w, 2.2)

	# Fungos verdes marcam o caminho principal; o túnel do lago não tem nenhum
	for f in [Vector3(2, 0, -21), Vector3(-1, 0, -10), Vector3(6, 0, -6), Vector3(-6, 0, 6), Vector3(-5, 0, 16), Vector3(4, 0, 31),
			Vector3(14, 0, 38), Vector3(12, 0, -6), Vector3(22, 0, -10), Vector3(36, 0, -4), Vector3(46, 0, 18),
			Vector3(34, 0, 30), Vector3(55, 0, 33), Vector3(44, 0, 50), Vector3(62, 0, 39), Vector3(78, 0, 43),
			Vector3(92, 0, 41), Vector3(108, 0, 40), Vector3(118, 0, 36), Vector3(40, 0, 64), Vector3(50, 0, 76),
			Vector3(-8, 0, 30), Vector3(12, 0, 77)]:
		if cave.is_floor(Vector2(f.x, f.z), 0.2):
			add_fungus(f, GREEN)
	for f in [Vector3(38, 0, 72), Vector3(48, 0, 68), Vector3(44, 0, 77), Vector3(40, 0, 78)]:
		add_fungus(f, Color(0.75, 0.5, 1.0))
	var exit_light := OmniLight3D.new()
	exit_light.light_color = Color(0.6, 0.9, 1.0)
	exit_light.omni_range = 7.0
	exit_light.light_energy = 1.4
	exit_light.position = Vector3(121, 2, 37)
	add_child(exit_light)
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
	var mat := Fx.mat(Color(0.55, 1.0, 0.25), 1.6, false, 0.7)
	for c in [Vector2(63, 76.5), Vector2(66, 75.5), Vector2(68.5, 76.5)]:
		var pool := Fx.cylinder(1.9, 0.03, mat)
		pool.position = Vector3(c.x, 0.03, c.y)
		add_child(pool)
	var light := OmniLight3D.new()
	light.light_color = Color(0.55, 1.0, 0.25)
	light.omni_range = 6.0
	light.light_energy = 1.0
	light.position = Vector3(66, 1.2, 76)
	add_child(light)


func _build_rockfall() -> void:
	# Desabamento a caminho do Ninho dos lagartos (G12): abre numa próxima versão.
	for r in [[42.0, 87.5, 2.4, 1.8, 2.0], [44.6, 88.3, 2.0, 1.4, 1.6], [43.2, 89.6, 3.0, 2.2, 1.8]]:
		var body := add_static_box(Vector3(r[2], r[4], r[3]), Vector3(r[0], r[4] * 0.5, r[1]), Color(0.3, 0.32, 0.33))
		body.rotation.y = r[0] * 0.3


func _populate() -> void:
	ecosystem.larva_spawns = [
		Vector3(-4, 0, 2), Vector3(4, 0, -3), Vector3(-2, 0, 30), Vector3(3, 0, 38),
		Vector3(40, 0, 70), Vector3(48, 0, 74), Vector3(41, 0, 77), Vector3(47, 0, 66), Vector3(38, 0, 73),
		Vector3(50, 0, 40), Vector3(10, 0, 74),
	]
	ecosystem.frog_spawns = [Vector3(-5, 0, 38)]
	ecosystem.larva_target = 9
	ecosystem.frog_target = 1
	ecosystem.spawn_initial()
	for home in BAT_HOMES:
		_spawn_bat(home)
	if not GameState.flags.has("g5_lagarto"):
		var lz := Lizard.new()
		lz.position = Vector3(44, 0.3, 73)
		ecosystem.add_child(lz)
	if not GameState.flags.has("g7_cristal"):
		var crystal := Pickup.new("cristal_en", "g7_cristal")
		crystal.position = Vector3(-4.2, 0, 75.2)
		add_child(crystal)
	add_trigger(Rect2(119, 35, 2, 4), _on_exit)
	EventBus.rested.connect(_on_rested)
	EventBus.territory_changed.connect(_on_territory_changed)
	EventBus.creature_died.connect(_on_creature_died)


func _spawn_bat(home: Vector3) -> Bat:
	var b := Bat.new()
	b.position = home + Vector3(randf_range(-2.0, 2.0), Bat.ROOST_Y, randf_range(-1.5, 1.5))
	ecosystem.add_child(b)
	b.home = home
	return b


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
	if c is Lizard:
		GameState.flags["g5_lagarto"] = true


func _physics_process(delta: float) -> void:
	if player == null or player.dead:
		return
	var p2 := Vector2(player.global_position.x, player.global_position.z)
	if ACID_RECT.has_point(p2):
		_acid_timer -= delta
		if _acid_timer <= 0.0:
			_acid_timer = 0.4
			player.take_damage(7.0, null, false)
		if not GameState.said.has("g11_acido"):
			EventBus.hint.emit("Ácido! Sem Resistência a Ácido 3 não dá para atravessar as Poças ácidas.")
		GameState.say_once("g11_acido", "AI, AI, queima! Volta, volta!")
	if not GameState.said.has("g12_desabamento") and Fx.flat_dist(player.global_position, Vector3(43.5, 0, 86)) < 3.0:
		EventBus.hint.emit("(Protótipo) O caminho para o Ninho dos lagartos abre numa próxima versão.")
		GameState.say_once("g12_desabamento", "Pedra. Muita pedra. Nem minhas patinhas passam.")
	if not GameState.said.has("g16_cristal") and Fx.flat_dist(player.global_position, CRYSTAL_WALL) < 4.0:
		EventBus.hint.emit("Uma parede de cristal, e uma luz fraca lá em cima. Ainda não dá para passar.")
		GameState.say_once("g16_cristal", "Luz... lá em cima. Um dia eu volto aqui.")


func _on_exit(body: Node3D) -> void:
	if _leaving or not (body is Player):
		return
	_leaving = true
	GameState.say_once("g_fim_trecho", "Mais túneis, mais escuro... e vozes? Vozes de gente?")
	EventBus.big_message.emit("Fim do trecho jogável (v0.4)")
	EventBus.message.emit("A Galeria do eco e o resto das Galerias chegam na próxima versão.")
