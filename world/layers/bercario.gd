extends LayerBase
## B — Berçário (Ato 1, tutorial). Seis câmaras em linha reta, com um desvio secreto.
## Coordenadas em metros: x cresce para leste, z para o sul. Ver a aba "Mapa da Fenda" do GDD.

const SILK_PILLAR := Color(0.78, 0.76, 0.84)
const NEXT_LAYER := "res://world/layers/test_chamber.tscn"

var chase: MotherChase
var mother_leg: MotherLeg
var _chase_started := false
var _leaving := false


func _configure() -> void:
	layer_id = "B"
	layer_name = "Berçário"
	spawn_point = Vector3(-56.0, 0.1, 0.0)
	ambient_color = Color(0.55, 0.48, 0.62)
	ambient_energy = 0.32
	fog_color = Color(0.07, 0.05, 0.09)
	rooms = [
		{"id": "B1", "name": "Câmara de eclosão", "rect": Rect2(-60, -8, 16, 16),
			"hint": "WASD anda · clique ataca · E come. Suas irmãs menores fogem... e você está com fome.",
			"line_id": "b1_fome", "line": "Minhas irmãs estão me olhando do mesmo jeito que eu olho pra elas."},
		{"id": "B2", "name": "Corredor das cascas", "rect": Rect2(-38, -4, 24, 8), "checkpoint": true,
			"hint": "Uma irmã faminta te caça! Shift corre · Espaço esquiva · clique ataca.",
			"line_id": "b2_irma", "line": "Ela é maior que eu. E mais rápida. E muito, MUITO mais faminta."},
		{"id": "B3", "name": "Salão das teias", "rect": Rect2(-8, -14, 30, 28), "checkpoint": true,
			"hint": "Um abismo. Segure R (Modo Tecelagem), clique num pilar de teia e depois num do outro lado.",
			"line_id": "b3_teias", "line": "As teias da Mãe são enormes. Dá pra prender um fio nelas..."},
		{"id": "B4", "name": "Fresta do ninho", "rect": Rect2(13, 22, 9, 6),
			"hint": "Uma fresta! Só alguém pequeno passa por aqui.",
			"line_id": "b4_fresta", "line": "Ser pequena tem suas vantagens."},
		{"id": "B5", "name": "Despensa da Mãe", "rect": Rect2(28, -12, 24, 24), "checkpoint": true,
			"hint": "Uma pata gigante procura comida. F apaga a runa: no escuro, ande devagar e pare quando ela chegar perto.",
			"line_id": "b5_pata", "line": "Aquilo é... a pata da Mãe. Não respira. Não brilha. Não existe."},
		{"id": "B6", "name": "Fuga", "rect": Rect2(58, -6, 42, 12), "checkpoint": true,
			"hint": "CORRA para o leste! No segundo abismo, teça um fio em câmera lenta (R).",
			"line_id": "b6_fuga", "line": "CORRE, CORRE, CORRE, CORRE!"},
	]
	tunnels = [Rect2(-44, -2, 6, 4), Rect2(-14, -2, 6, 4), Rect2(17, 14, 1, 8), Rect2(22, -2, 6, 4), Rect2(52, -2, 6, 4), Rect2(100, -1, 6, 2)]
	locks = [{"type": "fresta", "pos": Vector3(17.5, 0.0, 14.5)}]


func _build_level() -> void:
	var grid := CaveGrid.new(Rect2i(-62, -16, 172, 46))
	for r in rooms:
		grid.paint(r["rect"], CaveGrid.FLOOR)
	for t in tunnels:
		grid.paint(t, CaveGrid.FLOOR)
	grid.paint(Rect2(4, -14, 6, 28), CaveGrid.CHASM)      # abismo do Salão das teias (B3)
	grid.paint(Rect2(66, -6, 6, 12), CaveGrid.CHASM)      # 1º abismo da Fuga (tem ponte de teia da Mãe)
	grid.paint(Rect2(66, -1.5, 6, 3), CaveGrid.FLOOR)     # ponte de teia
	grid.paint(Rect2(82, -6, 6, 12), CaveGrid.CHASM)      # 2º abismo da Fuga (precisa de fio)
	grid.build(self, Color(0.3, 0.27, 0.33), Color(0.2, 0.17, 0.24))

	# Ponte de teia da Mãe (visual por cima do chão)
	add_web_bridge(Rect2(66, -2, 6, 4))

	# Pilares de teia (âncoras)
	add_anchor("B2_a", Vector3(-30, 0, -3), 3.0, 0.45, SILK_PILLAR)
	add_anchor("B2_b", Vector3(-22, 0, 3), 3.0, 0.45, SILK_PILLAR)
	add_anchor("B3_a", Vector3(2, 0, -6), 5.0, 0.6, SILK_PILLAR)
	add_anchor("B3_b", Vector3(2, 0, 6), 5.0, 0.6, SILK_PILLAR)
	add_anchor("B3_c", Vector3(12, 0, -6), 5.0, 0.6, SILK_PILLAR)
	add_anchor("B3_d", Vector3(12, 0, 6), 5.0, 0.6, SILK_PILLAR)
	add_anchor("B3_e", Vector3(-4, 0, -10), 4.0, 0.5, SILK_PILLAR)
	add_anchor("B3_f", Vector3(-4, 0, 10), 4.0, 0.5, SILK_PILLAR)
	add_anchor("B3_g", Vector3(18, 0, -10), 4.0, 0.5, SILK_PILLAR)
	add_anchor("B3_h", Vector3(18, 0, 10), 4.0, 0.5, SILK_PILLAR)
	add_anchor("B5_a", Vector3(34, 0, -6), 4.0, 0.55, SILK_PILLAR)
	add_anchor("B5_b", Vector3(34, 0, 6), 4.0, 0.55, SILK_PILLAR)
	add_anchor("B5_c", Vector3(40, 0, 0), 4.0, 0.55, SILK_PILLAR)
	add_anchor("B5_d", Vector3(46, 0, -6), 4.0, 0.55, SILK_PILLAR)
	add_anchor("B5_e", Vector3(46, 0, 6), 4.0, 0.55, SILK_PILLAR)
	add_anchor("B6_a", Vector3(80, 0, -3.5), 4.0, 0.5, SILK_PILLAR)
	add_anchor("B6_b", Vector3(90, 0, -3.5), 4.0, 0.5, SILK_PILLAR)
	add_anchor("B6_c", Vector3(80, 0, 3.5), 4.0, 0.5, SILK_PILLAR)
	add_anchor("B6_d", Vector3(90, 0, 3.5), 4.0, 0.5, SILK_PILLAR)

	# Ovos na Câmara de eclosão
	var egg_mat := Fx.mat(Color(0.85, 0.82, 0.78), 0.15)
	for e in [Vector3(-57, 0, -5), Vector3(-55, 0, -6), Vector3(-53, 0, -5), Vector3(-58, 0, 5), Vector3(-50, 0, 6), Vector3(-47, 0, -4)]:
		var egg := Fx.sphere(0.45, egg_mat)
		egg.scale = Vector3(1.0, 0.8, 1.0)
		egg.position = e + Vector3(0.0, 0.3, 0.0)
		add_child(egg)

	# Teias decorativas no chão
	for w in [Vector3(-52, 0, 0), Vector3(-26, 0, 0), Vector3(-2, 0, 0), Vector3(17, 0, 0), Vector3(40, 0, -9), Vector3(40, 0, 9), Vector3(62, 0, 0), Vector3(95, 0, 0)]:
		add_web_decal(w, 2.5)

	# Luzes: fungos roxos marcam o caminho principal
	var violet := Color(0.75, 0.5, 1.0)
	for f in [Vector3(-59, 0, 7), Vector3(-45, 0, -1.5), Vector3(-15, 0, 3.5), Vector3(-7, 0, -13), Vector3(21, 0, 13), Vector3(17, 0, 27), Vector3(27, 0, -1.5), Vector3(51, 0, 11), Vector3(59, 0, -5), Vector3(99, 0, 5)]:
		add_fungus(f, violet)
	var exit_light := OmniLight3D.new()
	exit_light.light_color = Color(0.5, 1.0, 0.7)
	exit_light.omni_range = 7.0
	exit_light.light_energy = 1.5
	exit_light.position = Vector3(104, 2, 0)
	add_child(exit_light)


func _populate() -> void:
	# B1: irmãs menores (comida do tutorial)
	for p in [Vector3(-50, 0, -3), Vector3(-48, 0, 4), Vector3(-52, 0, 5)]:
		_spawn_sister(p, false)
	# B2: irmã faminta
	_spawn_sister(Vector3(-22, 0, 0), true)
	# B3: uma faminta deste lado, duas menores do outro
	_spawn_sister(Vector3(-2, 0, 8), true)
	_spawn_sister(Vector3(16, 0, -8), false)
	_spawn_sister(Vector3(18, 0, 6), false)
	# B4: cristal secreto
	if not GameState.flags.has("b4_cristal"):
		var crystal := Pickup.new("cristal_pv", "b4_cristal")
		crystal.position = Vector3(17.5, 0, 25)
		add_child(crystal)
	# B5: presas embrulhadas e a pata da Mãe
	for c in [Vector3(31, 0, -9), Vector3(31, 0, 9), Vector3(49, 0, -9), Vector3(49, 0, 9), Vector3(40, 0, -10)]:
		var food := Corpse.new()
		food.preserved = true
		food.setup("Presa embrulhada", 40.0, 25.0, 10, Color(0.85, 0.85, 0.9), 0.5)
		food.position = c
		ecosystem.add_child(food)
	mother_leg = MotherLeg.new()
	mother_leg.points = [Vector3(40, 0, 0), Vector3(36, 0, -4), Vector3(44, 0, 4), Vector3(40, 0, 8), Vector3(36, 0, 6), Vector3(44, 0, -6), Vector3(40, 0, -8)]
	add_child(mother_leg)
	# B6: a Mãe e a saída
	chase = MotherChase.new()
	add_child(chase)
	add_trigger(Rect2(103, -1, 2, 2), _on_exit)


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
	if not _chase_started and player.global_position.x >= 60.0:
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
	GameState.say_once("b_saida", "Ela não cabe no túnel... Consegui. Acho.")
	EventBus.big_message.emit("Fim do Berçário")
	await get_tree().create_timer(2.0).timeout
	go_to_layer(NEXT_LAYER)
