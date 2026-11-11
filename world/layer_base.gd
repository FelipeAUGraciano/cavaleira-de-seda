class_name LayerBase
extends Node3D
## Base de toda camada da Fenda: ambiente, rede de teias, jogadora, HUD, mapa, ecossistema,
## save e transição entre camadas. Cada camada sobrescreve:
##   _configure()   ids, câmaras, túneis, travas e ponto de entrada
##   _build_level() geometria, âncoras e decoração
##   _populate()    criaturas, itens e gatilhos
##   _start()       mensagens iniciais e lógica própria

var layer_id := "?"
var layer_name := "Camada"
var spawn_point := Vector3.ZERO
var rooms: Array = []        ## [{id, name, rect: Rect2, checkpoint, hint, line_id, line}]
var tunnels: Array = []      ## [Rect2]
var locks: Array = []        ## [{type, pos: Vector3}]

var ambient_color := Color(0.45, 0.5, 0.6)
var ambient_energy := 0.35
var fog_color := Color(0.05, 0.06, 0.08)

var player: Player
var hud: Hud
var ecosystem: Ecosystem
var map_system: MapSystem
var webs: Node3D
var resumed := false


func _ready() -> void:
	Engine.time_scale = 1.0
	GameState.current_layer = self
	_configure()

	var data := GameState.load_game()
	resumed = not data.is_empty() and String(data.get("scene", "")) == scene_file_path
	if resumed:
		var said = data.get("said", {})
		if said is Dictionary:
			GameState.said = said
		var flags = data.get("flags", {})
		if flags is Dictionary:
			GameState.flags = flags

	_build_environment()
	webs = Node3D.new()
	webs.name = "Teias"
	add_child(webs)
	WebNetwork.setup(webs)
	_build_level()

	ecosystem = Ecosystem.new()
	ecosystem.name = "Criaturas"
	add_child(ecosystem)

	map_system = MapSystem.new()
	map_system.name = "Mapa"
	map_system.setup(layer_name, rooms, tunnels, locks)
	add_child(map_system)
	map_system.room_entered.connect(_on_room_entered)

	player = Player.new()
	player.name = "Cavaleira"
	player.position = spawn_point
	add_child(player)

	hud = Hud.new()
	add_child(hud)
	hud.player = player

	_populate()

	if resumed:
		WebNetwork.load_from(data.get("web", {}))
		map_system.from_dict(data.get("map", {}))
		player.from_dict(data.get("player", {}))
		EventBus.message.emit("Save carregado do último casulo (F8 apaga e recomeça).")
	elif not GameState.carry.is_empty():
		player.apply_carry(GameState.carry)
		GameState.carry = {}

	EventBus.player_died.connect(_on_player_died)
	_start()


# ---------------------------------------------------------------- para sobrescrever

func _configure() -> void:
	pass


func _build_level() -> void:
	pass


func _populate() -> void:
	pass


func _start() -> void:
	pass


func _on_player_died() -> void:
	pass


# ---------------------------------------------------------------- câmaras

func _on_room_entered(room: Dictionary) -> void:
	if room.get("checkpoint", false) and player != null and not player.dead:
		player.respawn_pos = player.global_position
	var hint := String(room.get("hint", ""))
	if hint != "" and not GameState.said.has("hint_" + String(room["id"])):
		GameState.said["hint_" + String(room["id"])] = true
		EventBus.hint.emit(hint)
	var line := String(room.get("line", ""))
	if line != "":
		GameState.say_once(String(room.get("line_id", "")), line)


func go_to_layer(path: String) -> void:
	GameState.carry = player.to_dict()
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file.call_deferred(path)


# ---------------------------------------------------------------- construção

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.015, 0.025)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = true
	env.fog_light_color = fog_color
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


func add_anchor(anchor_name: String, pos: Vector3, height: float = 4.0, radius: float = 0.5, color: Color = Color(0.42, 0.42, 0.47)) -> WebAnchor:
	var a := WebAnchor.new(height, radius, color)
	a.name = anchor_name
	a.position = pos
	add_child(a)
	WebNetwork.register_anchor(a)
	return a


func add_static_box(size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
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


func add_fungus(pos: Vector3, color: Color = Color(0.45, 1.0, 0.6)) -> void:
	var cap := Fx.sphere(0.25, Fx.mat(color, 3.0, true))
	cap.position = pos + Vector3(0.0, 0.2, 0.0)
	add_child(cap)
	var light := OmniLight3D.new()
	light.light_color = color
	light.omni_range = 5.0
	light.light_energy = 1.2
	light.position = pos + Vector3(0.0, 1.0, 0.0)
	add_child(light)


func add_web_decal(pos: Vector3, radius: float = 2.5) -> void:
	## Teia decorativa no chão: raios e anéis finos e translúcidos.
	var mat := Fx.mat(Color(0.86, 0.86, 0.96), 0.5, true, 0.35)
	var root := Node3D.new()
	root.position = pos + Vector3(0.0, 0.03, 0.0)
	add_child(root)
	for i in 6:
		var spoke := Fx.box(Vector3(radius * 2.0, 0.01, 0.03), mat)
		spoke.rotation.y = i * PI / 6.0
		root.add_child(spoke)
	for ring in [0.35, 0.65, 0.95]:
		var r: float = radius * ring
		for i in 12:
			var a0 := i * TAU / 12.0
			var a1 := (i + 1) * TAU / 12.0
			var seg := Fx.box(Vector3(0.025, 0.01, 1.0), mat)
			root.add_child(seg)
			Fx.orient_between(seg, Vector3(cos(a0) * r, 0.0, sin(a0) * r), Vector3(cos(a1) * r, 0.0, sin(a1) * r))
			seg.scale.z = Vector3(cos(a0) * r, 0.0, sin(a0) * r).distance_to(Vector3(cos(a1) * r, 0.0, sin(a1) * r))


func add_web_bridge(rect: Rect2) -> void:
	## Ponte de teia antiga sobre um abismo (o chão já foi pintado na grade): só o visual.
	var mat := Fx.mat(Color(0.86, 0.86, 0.96), 0.6, true, 0.6)
	var z := rect.position.y + 0.2
	while z < rect.position.y + rect.size.y:
		var line := Fx.box(Vector3(rect.size.x, 0.02, 0.04), mat)
		line.position = Vector3(rect.position.x + rect.size.x * 0.5, 0.04, z)
		add_child(line)
		z += 0.45
	var x := rect.position.x + 0.3
	while x < rect.position.x + rect.size.x:
		var cross := Fx.box(Vector3(0.03, 0.02, rect.size.y), mat)
		cross.position = Vector3(x, 0.05, rect.position.y + rect.size.y * 0.5)
		add_child(cross)
		x += 0.7


func add_trigger(rect: Rect2, callback: Callable) -> Area3D:
	## Área no chão (rect em XZ) que chama callback(body) quando a jogadora entra.
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = Vector3(rect.position.x + rect.size.x * 0.5, 1.0, rect.position.y + rect.size.y * 0.5)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(rect.size.x, 2.0, rect.size.y)
	cs.shape = shape
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(callback)
	return area
