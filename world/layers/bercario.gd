extends LayerBase
## B — Berçário (Ato 1, tutorial). Seis câmaras orgânicas ligadas por túneis curvos,
## uma trilha baixa alternativa entre B1 e B3 (área "Bt") e um nicho no corredor.
## Coordenadas em metros: x cresce para leste, z para o sul. Ver a aba "Mapa da Fenda" do GDD.

const SILK_PILLAR := Color(0.78, 0.76, 0.84)
const NEXT_LAYER := "res://world/layers/galerias.tscn"

const CHASE_ROUTE := [Vector2(46, -3), Vector2(55, -2), Vector2(61, 2), Vector2(70, 7), Vector2(82, 6), Vector2(92, -1), Vector2(104, -2), Vector2(109, 0)]

var chase: MotherChase
var mother_leg: MotherLeg
var cave: CaveBuilder
var _chase_started := false
var _leaving := false


func _configure() -> void:
	layer_id = "B"
	layer_name = "Berçário"
	layer_subtitle = "Prólogo · O ninho da Mãe"
	spawn_point = Vector3(-60.0, 0.1, 6.0)
	ambient_color = Color(0.55, 0.48, 0.62)
	ambient_energy = 0.32
	fog_color = Color(0.07, 0.05, 0.09)
	rooms = [
		{"id": "B1", "name": "Câmara de eclosão",
			"shapes": [CaveBuilder.blob(Vector2(-58, 4), 9.0, 1.4)],
			"hint": "WASD anda · clique ataca · E come. Suas irmãs menores fogem... e você está com fome.",
			"line_id": "b1_fome", "line": "Minhas irmãs estão me olhando do mesmo jeito que eu olho pra elas."},
		{"id": "B2", "name": "Corredor das cascas", "checkpoint": true,
			"shapes": [CaveBuilder.path([Vector2(-40, -6), Vector2(-31, -10), Vector2(-22, -9), Vector2(-14, -4)], 7.0, 0.8),
				CaveBuilder.blob(Vector2(-27, -16), 3.5, 0.6)],
			"hint": "Uma irmã faminta te caça! Shift corre · Espaço esquiva · clique ataca.",
			"line_id": "b2_irma", "line": "Ela é maior que eu. E mais rápida. E muito, MUITO mais faminta."},
		{"id": "Bt", "name": "Trilha baixa",
			"shapes": [CaveBuilder.path([Vector2(-50, 10), Vector2(-36, 15), Vector2(-20, 13), Vector2(-8, 8)], 3.2, 0.5)],
			"hint": "Uma trilha escura e estreita: caminho alternativo até o Salão das teias.",
			"line_id": "bt_trilha", "line": "Um atalho escuro... ninguém vai me ver aqui. Espero."},
		{"id": "B3", "name": "Salão das teias", "checkpoint": true,
			"shapes": [CaveBuilder.ellipse(Vector2(6, 2), 17.0, 13.0, 0.2, 2.0)],
			"hint": "Uma fenda corta o salão. Segure R (Modo Tecelagem), clique num pilar de teia e depois num do outro lado.",
			"line_id": "b3_teias", "line": "As teias da Mãe são enormes. Dá pra prender um fio nelas..."},
		{"id": "B4", "name": "Fresta do ninho",
			"shapes": [CaveBuilder.blob(Vector2(18, 27), 3.8, 0.5)],
			"hint": "Uma fresta! Só alguém pequeno passa por aqui.",
			"line_id": "b4_fresta", "line": "Ser pequena tem suas vantagens."},
		{"id": "B5", "name": "Despensa da Mãe", "checkpoint": true,
			"shapes": [CaveBuilder.blob(Vector2(44, -4), 12.0, 1.2)],
			"hint": "Uma pata gigante procura comida. F apaga a runa: no escuro, ande devagar e pare quando ela chegar perto.",
			"line_id": "b5_pata", "line": "Aquilo é... a pata da Mãe. Não respira. Não brilha. Não existe."},
		{"id": "B6", "name": "Fuga", "checkpoint": true,
			"shapes": [CaveBuilder.path([Vector2(60, 2), Vector2(70, 7), Vector2(82, 6), Vector2(92, -1), Vector2(104, -2), Vector2(111, 1)], 9.0, 1.0)],
			"hint": "CORRA pelo túnel! No segundo abismo, teça um fio em câmera lenta (R).",
			"line_id": "b6_fuga", "line": "CORRE, CORRE, CORRE, CORRE!"},
	]
	locks = [{"type": "fresta", "pos": Vector3(15.5, 0.0, 13.0)}]


func _build_level() -> void:
	cave = CaveBuilder.new()
	cave.floor_color = Color(0.31, 0.27, 0.34)
	cave.rock_color = Color(0.22, 0.18, 0.27)
	cave.rooms = rooms
	cave.tunnels = [
		CaveBuilder.path([Vector2(-51, 0), Vector2(-45, -4), Vector2(-39, -6)], 4.0, 0.4),            # B1 → B2
		CaveBuilder.path([Vector2(-15, -4), Vector2(-9, -1)], 4.5, 0.4),                               # B2 → B3
		CaveBuilder.path([Vector2(15, 12), Vector2(19, 18), Vector2(18, 24)], 1.15, 0.0),              # fresta B3 → B4
		CaveBuilder.path([Vector2(20, -3), Vector2(28, -7), Vector2(33, -6)], 4.5, 0.4),               # B3 → B5
		CaveBuilder.path([Vector2(55, -2), Vector2(61, 2)], 4.5, 0.4),                                 # B5 → B6
		CaveBuilder.path([Vector2(110, 1), Vector2(119, 1)], 2.2, 0.0),                                # saída
	]
	cave.chasms = [
		CaveBuilder.path([Vector2(1, -16), Vector2(4, -2), Vector2(8, 9), Vector2(7, 20)], 6.0, 0.5),  # fenda do Salão
		CaveBuilder.path([Vector2(67, -4), Vector2(73, 18)], 5.0, 0.3),                                # 1º abismo da Fuga
		CaveBuilder.path([Vector2(95, -12), Vector2(91, 9)], 5.0, 0.3),                                # 2º abismo da Fuga
	]
	cave.bridges = [CaveBuilder.path([Vector2(64, 5), Vector2(76, 6.8)], 3.6, 0.0)]
	map_grid = cave.build(self)
	cave.scatter_decor(self, 11)
	add_web_bridge_path(Vector2(64, 5), Vector2(76, 6.8), 3.6)

	# Pilares de teia (âncoras)
	var pillars := {
		"B2_a": Vector3(-30, 0, -12.5), "B2_b": Vector3(-24, 0, -6.5),
		"B3_a": Vector3(-2, 0, -6), "B3_b": Vector3(2, 0, 8), "B3_c": Vector3(9, 0, -6), "B3_d": Vector3(13, 0, 8),
		"B3_e": Vector3(-7, 0, -4), "B3_f": Vector3(-4, 0, 7.5), "B3_g": Vector3(16, 0, -5), "B3_h": Vector3(18, 0, 7),
		"B5_a": Vector3(38, 0, -9), "B5_b": Vector3(38, 0, 2), "B5_c": Vector3(44, 0, -4), "B5_d": Vector3(50, 0, -9), "B5_e": Vector3(50, 0, 2),
		"B6_a": Vector3(88, 0, -1), "B6_b": Vector3(98, 0, -4.3), "B6_c": Vector3(87.5, 0, 5), "B6_d": Vector3(98, 0, 1.3),
	}
	for n in pillars:
		var pos: Vector3 = pillars[n]
		var tall := 5.0 if String(n).begins_with("B3") else 4.0
		add_anchor(n, pos, tall, 0.55, SILK_PILLAR, "pilar_teia")
		if not cave.is_floor(Vector2(pos.x, pos.z), 0.6):
			push_warning("Pilar %s fora do chão firme em %s" % [n, pos])

	# Ovos na Câmara de eclosão
	var egg_mat := Fx.mat(Color(0.85, 0.82, 0.78), 0.15)
	for e in [Vector3(-62, 0, -1), Vector3(-60, 0, -3), Vector3(-57, 0, -2), Vector3(-63, 0, 8), Vector3(-55, 0, 10), Vector3(-52, 0, 3)]:
		var egg := Fx.sphere(0.45, egg_mat)
		egg.scale = Vector3(1.0, 0.8, 1.0)
		egg.position = e + Vector3(0.0, 0.3, 0.0)
		add_child(egg)
		var m := Models.swap(self, "ovo", 0.9, [egg], "height")
		if m != null:
			m.position = e
			m.rotation.y = e.x
			Models.tint(m, Color(1, 1, 1), 0.35)   # ovos claros se destacam no ninho escuro

	# Teias decorativas no chão
	for w in [Vector3(-58, 0, 4), Vector3(-28, 0, -10), Vector3(-5, 0, 1), Vector3(15, 0, 3), Vector3(44, 0, -4), Vector3(84, 0, 4), Vector3(102, 0, -1), Vector3(-36, 0, 15)]:
		add_web_decal(w, 2.6)

	# Fungos roxos marcam o caminho; a trilha baixa tem só dois, é mais escura
	var violet := Color(0.75, 0.5, 1.0)
	for f in [Vector3(-63, 0, 0), Vector3(-50, 0, -2), Vector3(-38, 0, -9), Vector3(-17, 0, -6), Vector3(-10, 0, -3), Vector3(-7, 0, 12),
			Vector3(20, 0, -1), Vector3(22, 0, 12), Vector3(18, 0, 29), Vector3(31, 0, -6), Vector3(54, 0, 4), Vector3(62, 0, 0),
			Vector3(80, 0, 9), Vector3(100, 0, -5), Vector3(113, 0, 2), Vector3(-44, 0, 13), Vector3(-28, 0, 15)]:
		if cave.is_floor(Vector2(f.x, f.z), 0.2):
			add_fungus(f, violet)
	var exit_light := OmniLight3D.new()
	exit_light.light_color = Color(0.5, 1.0, 0.7)
	exit_light.omni_range = 7.0
	exit_light.light_energy = 1.5
	exit_light.position = Vector3(117, 2, 1)
	add_child(exit_light)


func _populate() -> void:
	# B1: irmãs menores (comida do tutorial)
	for p in [Vector3(-56, 0, 1), Vector3(-54, 0, 8), Vector3(-61, 0, 2)]:
		_spawn_sister(p, false)
	# B2: irmã faminta e uma menor escondida no nicho
	_spawn_sister(Vector3(-25, 0, -9), true)
	_spawn_sister(Vector3(-27, 0, -16), false)
	# trilha baixa: uma menor
	_spawn_sister(Vector3(-36, 0, 14), false)
	# B3: uma faminta deste lado da fenda, duas menores do outro
	_spawn_sister(Vector3(-5, 0, 5), true)
	_spawn_sister(Vector3(14, 0, -4), false)
	_spawn_sister(Vector3(16, 0, 10), false)
	# B4: cristal secreto
	if not GameState.flags.has("b4_cristal"):
		var crystal := Pickup.new("cristal_pv", "b4_cristal")
		crystal.position = Vector3(18, 0, 27)
		add_child(crystal)
	# B5: presas embrulhadas e a pata da Mãe
	for c in [Vector3(36, 0, -10), Vector3(36, 0, 3), Vector3(52, 0, -10), Vector3(52, 0, 2), Vector3(44, 0, -14)]:
		var food := Corpse.new()
		food.preserved = true
		food.setup("Presa embrulhada", 40.0, 25.0, 10, Color(0.85, 0.85, 0.9), 0.5)
		food.position = c
		ecosystem.add_child(food)
	mother_leg = MotherLeg.new()
	mother_leg.points = [Vector3(44, 0, -4), Vector3(40, 0, -8), Vector3(48, 0, 0), Vector3(44, 0, 4), Vector3(39, 0, 0), Vector3(48, 0, -9), Vector3(44, 0, -12)]
	add_child(mother_leg)
	# B6: a Mãe e a saída
	chase = MotherChase.new()
	chase.route = PackedVector2Array(CHASE_ROUTE)
	add_child(chase)
	add_trigger(Rect2(116, -0.5, 2, 3), _on_exit)


func _spawn_sister(pos: Vector3, hunter: bool) -> Sister:
	var s := Sister.new(hunter)
	s.position = pos + Vector3(0.0, 0.3, 0.0)
	ecosystem.add_child(s)
	return s


func _start() -> void:
	if not resumed:
		EventBus.message.emit("Objetivo: fuja do ninho da Mãe pelo túnel a leste.")
	GameState.say_once("inicio", "...Ok. Eu sou uma aranha. Uma aranha MINÚSCULA. Num ninho. Ótimo.")


func _physics_process(_delta: float) -> void:
	if player == null or player.dead:
		return
	if not _chase_started and map_system.current_room == "B6" and player.global_position.x >= 63.0:
		_chase_started = true
		chase.begin()
		mother_leg.active = false
		mother_leg.visible = false


func _on_player_died() -> void:
	# A fuga recomeça do início da câmara B6.
	if _chase_started:
		_chase_started = false
		chase.reset()
		mother_leg.active = true
		mother_leg.visible = true


func _on_exit(body: Node3D) -> void:
	if _leaving or not (body is Player):
		return
	_leaving = true
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	GameState.say_once("b_saida", "Ela não cabe no túnel... Consegui. Acho.")
	EventBus.big_message.emit("Você escapou do ninho!")
	await get_tree().create_timer(2.6).timeout
	await hud.fade(0.85, 1.0)
	hud.show_title("Fim do prólogo", "Lá fora tudo é maior que você. Coma, cresça, teça um território... e evolua.")
	GameState.say_once("b_epilogo", "Irmãs, Mãe, ninho... tudo pra trás. Agora é só eu. E eu tô com FOME.")
	await get_tree().create_timer(4.5).timeout
	go_to_layer(NEXT_LAYER)
