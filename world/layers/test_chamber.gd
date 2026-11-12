extends LayerBase
## Câmara de teste do protótipo (faz o papel das Galerias até elas serem construídas).
##
## Layout (vista de cima, norte = topo da tela):
##   Oeste: larvas e uma poça com um Sapo-de-rocha.
##   Centro: abismo de 6 m de norte a sul — só se cruza com fio-guia (ou lançando fio).
##   Leste: mais comida, outro sapo e a saída.

const HALF_X := 32.0
const HALF_Z := 20.0
const CHASM_HALF := 3.0
const WALL_H := 3.0
const FLOOR_COLOR := Color(0.3, 0.31, 0.34)
const WALL_COLOR := Color(0.22, 0.22, 0.25)
const ROCK_COLOR := Color(0.36, 0.35, 0.37)

## [x, z, altura, raio] — nomes estáveis (Pilar_00...) para o save funcionar.
const ANCHORS := [
	[-28.0, -15.0, 4.0, 0.5], [-20.0, -11.0, 4.0, 0.5], [-12.0, -16.0, 3.0, 0.45],
	[-24.0, -2.0, 4.0, 0.55], [-14.0, 1.0, 2.5, 0.4], [-6.0, -8.0, 4.0, 0.5],
	[-5.2, 6.0, 4.0, 0.5], [-18.0, 15.0, 3.0, 0.45], [-8.0, 15.5, 4.0, 0.5],
	[-4.6, -14.0, 4.0, 0.5], [-29.0, 6.0, 3.0, 0.45],
	[4.6, -14.0, 4.0, 0.5], [4.6, 6.0, 4.0, 0.5], [8.0, -3.0, 3.0, 0.45],
	[12.0, -14.0, 4.0, 0.5], [20.0, -6.0, 4.0, 0.55], [26.0, -16.0, 3.0, 0.45],
	[13.0, 9.0, 4.0, 0.5], [24.0, 12.0, 4.0, 0.5], [28.0, 1.0, 2.5, 0.4],
]

## [x, z, largura, profundidade] — rochas baixas que bloqueiam visão (cobertura).
const ROCKS := [
	[-16.0, -5.0, 3.0, 2.0], [-9.0, 3.0, 2.0, 3.0], [-23.0, 8.0, 2.5, 1.5],
	[11.0, 3.0, 3.0, 2.0], [22.0, -11.0, 2.0, 3.0], [18.0, 15.0, 3.0, 1.5],
]

const FUNGI := [
	Vector3(-28.0, 0.0, -17.0), Vector3(-16.0, 0.0, 8.0), Vector3(-4.5, 0.0, -18.0),
	Vector3(8.0, 0.0, -17.0), Vector3(18.0, 0.0, 12.0), Vector3(29.0, 0.0, -7.0),
	Vector3(-30.0, 0.0, 2.0), Vector3(-11.0, 0.0, 13.0),
]


func _configure() -> void:
	layer_id = "T"
	fall_default = "volta"
	dark_vision = false
	layer_name = "Galerias (câmara de teste)"
	spawn_point = Vector3(-26.0, 0.1, 12.0)
	rooms = [
		{"id": "T1", "name": "Margem oeste", "rect": Rect2(-32, -20, 29, 40),
			"line_id": "galerias", "line": "Galerias úmidas... cheiro de musgo. E de comida."},
		{"id": "T2", "name": "Abismo", "rect": Rect2(-3, -20, 6, 40)},
		{"id": "T3", "name": "Margem leste", "rect": Rect2(3, -20, 29, 40)},
	]
	tunnels = []
	locks = []


func _build_level() -> void:
	var side_w := HALF_X - CHASM_HALF
	add_static_box(Vector3(side_w, 1.0, HALF_Z * 2.0), Vector3(-(CHASM_HALF + side_w * 0.5), -0.5, 0.0), FLOOR_COLOR)
	add_static_box(Vector3(side_w, 1.0, HALF_Z * 2.0), Vector3(CHASM_HALF + side_w * 0.5, -0.5, 0.0), FLOOR_COLOR)

	# Abismo: só visual (sem colisão). Quem cai volta ao último chão firme com dano.
	var pit := Fx.box(Vector3(CHASM_HALF * 2.0, 0.2, HALF_Z * 2.0), Fx.mat(Color(0.02, 0.02, 0.03)))
	pit.position = Vector3(0.0, -9.0, 0.0)
	add_child(pit)
	for sx in [-1.0, 1.0]:
		var cliff := Fx.box(Vector3(0.2, 9.0, HALF_Z * 2.0), Fx.mat(Color(0.16, 0.16, 0.18)))
		cliff.position = Vector3(sx * CHASM_HALF, -4.5, 0.0)
		add_child(cliff)

	# Paredes. A do sul é baixa para não tapar a câmera.
	add_static_box(Vector3(HALF_X * 2.0 + 2.0, WALL_H, 1.0), Vector3(0.0, WALL_H * 0.5, -HALF_Z - 0.5), WALL_COLOR)
	add_static_box(Vector3(HALF_X * 2.0 + 2.0, 0.6, 1.0), Vector3(0.0, 0.3, HALF_Z + 0.5), WALL_COLOR)
	add_static_box(Vector3(1.0, WALL_H, HALF_Z * 2.0), Vector3(-HALF_X - 0.5, WALL_H * 0.5, 0.0), WALL_COLOR)
	add_static_box(Vector3(1.0, WALL_H, HALF_Z * 2.0), Vector3(HALF_X + 0.5, WALL_H * 0.5, 0.0), WALL_COLOR)

	for r in ROCKS:
		add_static_box(Vector3(r[2], 1.6, r[3]), Vector3(r[0], 0.8, r[1]), ROCK_COLOR)

	var pond := Fx.cylinder(3.0, 0.02, Fx.mat(Color(0.1, 0.2, 0.3), 0.2, false, 0.8))
	pond.position = Vector3(-12.0, 0.02, 12.0)
	add_child(pond)

	for f in FUNGI:
		add_fungus(f)

	for i in ANCHORS.size():
		var d: Array = ANCHORS[i]
		add_anchor("Pilar_%02d" % i, Vector3(float(d[0]), 0.0, float(d[1])), float(d[2]), float(d[3]))


func _populate() -> void:
	ecosystem.larva_spawns = [
		Vector3(-26, 0, -6), Vector3(-18, 0, 4), Vector3(-10, 0, -12), Vector3(-22, 0, 14), Vector3(-7, 0, 10),
		Vector3(12, 0, -6), Vector3(20, 0, 7), Vector3(26, 0, -10), Vector3(15, 0, 16),
	]
	ecosystem.frog_spawns = [Vector3(-12, 0, 11), Vector3(20, 0, -1)]
	ecosystem.spawn_initial()
	_build_exit()


func _start() -> void:
	EventBus.message.emit("Objetivo: sobreviva, aprenda a tecer e atravesse o abismo até a saída, a leste.")
	GameState.say_once("inicio_teste", "...Ok. Eu sou uma aranha. Uma aranha MINÚSCULA. Numa caverna. Ótimo.")


func _build_exit() -> void:
	var exit_pos := Vector3(30.5, 0.0, 0.0)
	var glow := Fx.box(Vector3(0.3, 3.0, 4.0), Fx.mat(Color(0.9, 0.95, 1.0), 2.5, true, 0.7))
	glow.position = exit_pos + Vector3(1.2, 1.5, 0.0)
	add_child(glow)
	var light := OmniLight3D.new()
	light.light_color = Color(0.9, 0.95, 1.0)
	light.omni_range = 8.0
	light.light_energy = 2.0
	light.position = exit_pos + Vector3(0.0, 2.0, 0.0)
	add_child(light)
	add_trigger(Rect2(exit_pos.x - 1.25, -2.0, 2.5, 4.0), _on_exit_entered)


func _on_exit_entered(body: Node3D) -> void:
	if body is Player:
		EventBus.big_message.emit("Saída encontrada! Fim do protótipo cinza.")
		GameState.say_once("saida", "Ar fresco?! ...Não. Só mais caverna. Mas é um começo.")
