extends Node3D
## Câmara de teste do protótipo cinza. Tudo é montado por código para iterar rápido.
##
## Layout (vista de cima, norte = topo da tela):
##   Oeste: início, larvas, poça com um Sapo-de-rocha.
##   Centro: abismo de 6 m de largura de norte a sul — só se cruza com fio-guia (ou lançando fio).
##   Leste: mais comida, outro sapo e a saída.

const HALF_X := 32.0
const HALF_Z := 20.0
const CHASM_HALF := 3.0
const WALL_H := 3.0
const FLOOR_COLOR := Color(0.3, 0.31, 0.34)
const WALL_COLOR := Color(0.22, 0.22, 0.25)
const ROCK_COLOR := Color(0.36, 0.35, 0.37)

const START := Vector3(-26.0, 0.1, 12.0)

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

var player: Player
var hud: Hud
var ecosystem: Ecosystem


func _ready() -> void:
	Engine.time_scale = 1.0
	_build_environment()
	_build_geometry()

	var webs := Node3D.new()
	webs.name = "Teias"
	add_child(webs)
	WebNetwork.setup(webs)
	_build_anchors()

	ecosystem = Ecosystem.new()
	ecosystem.name = "Criaturas"
	ecosystem.larva_spawns = [
		Vector3(-26, 0, -6), Vector3(-18, 0, 4), Vector3(-10, 0, -12), Vector3(-22, 0, 14), Vector3(-7, 0, 10),
		Vector3(12, 0, -6), Vector3(20, 0, 7), Vector3(26, 0, -10), Vector3(15, 0, 16),
	]
	ecosystem.frog_spawns = [Vector3(-12, 0, 11), Vector3(20, 0, -1)]
	add_child(ecosystem)

	player = Player.new()
	player.name = "Cavaleira"
	player.position = START
	add_child(player)

	hud = Hud.new()
	add_child(hud)
	hud.player = player

	ecosystem.spawn_initial()
	_build_exit()
	_load_save()

	EventBus.message.emit("Objetivo: sobreviva, aprenda a tecer e atravesse o abismo até a saída, a leste.")
	GameState.say_once("inicio", "...Ok. Eu sou uma aranha. Uma aranha MINÚSCULA. Numa caverna. Ótimo.")


func _load_save() -> void:
	var data := GameState.load_game()
	if data.is_empty():
		return
	var said = data.get("said", {})
	if said is Dictionary:
		GameState.said = said
	WebNetwork.load_from(data.get("web", {}))
	player.from_dict(data.get("player", {}))
	EventBus.message.emit("Save carregado do último casulo (F8 apaga e recomeça).")


# ---------------------------------------------------------------- ambiente

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.015, 0.025)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.5, 0.6)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.06, 0.08)
	env.fog_density = 0.006
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.25
	fill.light_color = Color(0.6, 0.65, 0.8)
	fill.rotation_degrees = Vector3(-65.0, 30.0, 0.0)
	fill.shadow_enabled = true
	add_child(fill)


func _build_geometry() -> void:
	var side_w := HALF_X - CHASM_HALF
	_static_box(Vector3(side_w, 1.0, HALF_Z * 2.0), Vector3(-(CHASM_HALF + side_w * 0.5), -0.5, 0.0), FLOOR_COLOR)
	_static_box(Vector3(side_w, 1.0, HALF_Z * 2.0), Vector3(CHASM_HALF + side_w * 0.5, -0.5, 0.0), FLOOR_COLOR)

	# Abismo: só visual (sem colisão). Quem cai volta ao último chão firme com dano.
	var pit := Fx.box(Vector3(CHASM_HALF * 2.0, 0.2, HALF_Z * 2.0), Fx.mat(Color(0.02, 0.02, 0.03)))
	pit.position = Vector3(0.0, -9.0, 0.0)
	add_child(pit)
	for sx in [-1.0, 1.0]:
		var cliff := Fx.box(Vector3(0.2, 9.0, HALF_Z * 2.0), Fx.mat(Color(0.16, 0.16, 0.18)))
		cliff.position = Vector3(sx * CHASM_HALF, -4.5, 0.0)
		add_child(cliff)

	# Paredes. A do sul é baixa para não tapar a câmera.
	_static_box(Vector3(HALF_X * 2.0 + 2.0, WALL_H, 1.0), Vector3(0.0, WALL_H * 0.5, -HALF_Z - 0.5), WALL_COLOR)
	_static_box(Vector3(HALF_X * 2.0 + 2.0, 0.6, 1.0), Vector3(0.0, 0.3, HALF_Z + 0.5), WALL_COLOR)
	_static_box(Vector3(1.0, WALL_H, HALF_Z * 2.0), Vector3(-HALF_X - 0.5, WALL_H * 0.5, 0.0), WALL_COLOR)
	_static_box(Vector3(1.0, WALL_H, HALF_Z * 2.0), Vector3(HALF_X + 0.5, WALL_H * 0.5, 0.0), WALL_COLOR)

	for r in ROCKS:
		_static_box(Vector3(r[2], 1.6, r[3]), Vector3(r[0], 0.8, r[1]), ROCK_COLOR)

	# Poça do sapo (só visual).
	var pond := Fx.cylinder(3.0, 0.02, Fx.mat(Color(0.1, 0.2, 0.3), 0.2, false, 0.8))
	pond.position = Vector3(-12.0, 0.02, 12.0)
	add_child(pond)

	for f in FUNGI:
		_fungus(f)


func _build_anchors() -> void:
	for i in ANCHORS.size():
		var d: Array = ANCHORS[i]
		var a := WebAnchor.new(float(d[2]), float(d[3]))
		a.name = "Pilar_%02d" % i
		a.position = Vector3(float(d[0]), 0.0, float(d[1]))
		add_child(a)
		WebNetwork.register_anchor(a)


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
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = exit_pos + Vector3(0.0, 1.0, 0.0)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.5, 2.0, 4.0)
	cs.shape = shape
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_exit_entered)


func _on_exit_entered(body: Node3D) -> void:
	if body is Player:
		EventBus.big_message.emit("Saída encontrada! Fim do protótipo cinza.")
		GameState.say_once("saida", "Ar fresco?! ...Não. Só mais caverna. Mas é um começo.")


# ---------------------------------------------------------------- utilidades

func _static_box(size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	body.add_child(Fx.box(size, Fx.mat(color)))
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	return body


func _fungus(pos: Vector3) -> void:
	var cap := Fx.sphere(0.25, Fx.mat(Color(0.45, 1.0, 0.6), 3.0, true))
	cap.position = pos + Vector3(0.0, 0.2, 0.0)
	add_child(cap)
	var light := OmniLight3D.new()
	light.light_color = Color(0.4, 1.0, 0.6)
	light.omni_range = 5.0
	light.light_energy = 1.2
	light.position = pos + Vector3(0.0, 1.0, 0.0)
	add_child(light)
