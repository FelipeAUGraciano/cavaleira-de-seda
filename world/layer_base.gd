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
var layer_subtitle := ""       ## frase embaixo do título quando a camada começa
var spawn_point := Vector3.ZERO
var rooms: Array = []        ## [{id, name, rect: Rect2, checkpoint, hint, line_id, line}]
var tunnels: Array = []      ## [Rect2]
var locks: Array = []        ## [{type, pos: Vector3}]
var map_grid: Dictionary = {}  ## preenchido por camadas orgânicas (CaveBuilder.build)
var nav_blockers: Array = []   ## [Vector3 centro, Vector3 tamanho] de caixas sólidas (porta, tenda...)

## Quedas: cada abismo diz para onde você cai. {"rect": Rect2 (x, z), "to": Vector3 = pouso no
## andar de baixo, ou ausente = sem fundo (morte)}. Fora de qualquer rect vale fall_default.
var chasms: Array = []
var fall_default := "fundo"
var passages: Array = []        ## [{rect, to, label}] rampas entre andares (add_passage)     ## "fundo" = sem fundo (morre); "volta" = antigo (volta pra beirada, -25 PV)
const FALL_DAMAGE_FRAC := 0.35  ## cair para o andar de baixo tira 35% da vida máxima
## Visão curta: o ambiente fica quase preto; só o que tem luz aparece (fungos, isca, fogo, runa).
var dark_vision := true
var ambient_color := Color(0.45, 0.5, 0.6)
var ambient_energy := 0.35
var fog_color := Color(0.05, 0.06, 0.08)

var player: Player
var hud: Hud
var ecosystem: Ecosystem
var map_system: MapSystem
var webs: Node3D
var clock: CaveClock
var resumed := false
var restarting := false        ## morreu: o ato recomeçou do início (permadeath)


func _ready() -> void:
	Engine.time_scale = 1.0
	GameState.current_layer = self
	World.reset()
	_configure()

	var data := GameState.load_game()
	var here := not data.is_empty() and String(data.get("scene", "")) == scene_file_path
	resumed = here and bool(data.get("checkpoint", true))
	restarting = here and not resumed
	var k = data.get("knowledge", {})
	if k is Dictionary and not k.is_empty():
		GameState.knowledge = k
	if here:
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
	_build_nav()
	clock = CaveClock.new()
	clock.name = "Relogio"
	if resumed:
		clock.t = float(data.get("clock", clock.t))
	add_child(clock)
	World.clock = clock

	ecosystem = Ecosystem.new()
	ecosystem.name = "Criaturas"
	add_child(ecosystem)

	map_system = MapSystem.new()
	map_system.name = "Mapa"
	map_system.setup(layer_name, rooms, tunnels, locks)
	if not map_grid.is_empty():
		map_system.set_grid(map_grid)
	add_child(map_system)
	map_system.room_entered.connect(_on_room_entered)

	player = Player.new()
	player.name = "Cavaleira"
	player.position = spawn_point
	add_child(player)

	hud = Hud.new()
	add_child(hud)
	if dark_vision:
		var vo := VisionOverlay.new()
		vo.player = player
		add_child(vo)
	hud.player = player

	_populate()

	map_system.from_dict((GameState.knowledge.get("maps", {}) as Dictionary).get(scene_file_path, {}))
	if resumed:
		WebNetwork.load_from(data.get("web", {}))
		map_system.from_dict(data.get("map", {}))
		player.from_dict(data.get("player", {}))
		GameState.act = data.get("act", {})
		EventBus.message.emit("Save carregado do último casulo.")
	elif restarting:
		GameState.act = data.get("act", {})
		player.apply_carry(GameState.act.get("player", {}))
		EventBus.message.emit("O ato recomeçou. Você lembra do caminho... e de quem te matou.")
	elif not GameState.carry.is_empty():
		player.apply_carry(GameState.carry)
		GameState.carry = {}
	if GameState.act.is_empty() or String(GameState.act.get("scene", "")) != scene_file_path:
		GameState.act = {"scene": scene_file_path, "player": player.to_dict(), "flags": GameState.flags.duplicate(true)}
		GameState.save_act_start()

	EventBus.player_died.connect(_on_player_died)
	_start()
	_arrival()


func _build_nav() -> void:
	## Grade de navegação das criaturas (só em camadas de caverna orgânica).
	var cave_builder = get("cave") if "cave" in self else null
	if cave_builder == null or map_grid.is_empty():
		return
	var obstacles: Array = []
	for a in WebNetwork.anchors.values():
		obstacles.append((a as Node3D).global_position)
	for b in nav_blockers:
		var c: Vector3 = b[0]
		var sz: Vector3 = b[1]
		var r := maxf(sz.x, sz.z) * 0.5
		var x := -r
		while x <= r:
			var z := -r
			while z <= r:
				obstacles.append(c + Vector3(x, 0.0, z))
				z += 1.0
			x += 1.0
	var nav := NavGrid.new()
	nav.build(cave_builder, map_grid, rooms, obstacles)
	World.nav = nav


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


func on_player_fell(p: Player) -> void:
	## A jogadora caiu num abismo. Com andar de baixo: dano grande e ela acorda lá embaixo.
	## Sem fundo: morte (e o ato recomeça).
	var c := chasm_at(p.last_safe_pos, p.global_position)
	var to = c.get("to", null) if not c.is_empty() else null
	if (c.is_empty() and fall_default == "volta") or String(c.get("mode", "")) == "volta":
		p.legacy_fall()
		return
	if to == null:
		EventBus.big_message.emit("Abismo sem fundo...")
		p.fall_to_death()
		return
	if c.has("drop"):
		# cai bem embaixo de onde estava, se lá embaixo tiver chão
		var below: Vector3 = Vector3(p.global_position.x, 0.0, p.global_position.z) + (c["drop"] as Vector3)
		if World.nav != null and World.nav.walkable(below, NavGrid.Kind.SMALL):
			to = below
		else:
			to = landing_near(below)
	p.falling = true
	if hud != null:
		await hud.fade(1.0, 0.35)
	p.land_after_fall(to, p.max_hp * FALL_DAMAGE_FRAC, String(c.get("name", "o andar de baixo")))
	if hud != null:
		hud.fade(0.0, 0.7)


var _passing := false


func landing_near(p: Vector3) -> Vector3:
	## Chão mais perto de p no andar de baixo (a camada com caverna gerada responde melhor).
	return p


func add_passage(rect: Rect2, to: Vector3, msg: String, label: String = "Rampa") -> void:
	## Rampa entre andares: pisou, a tela escurece e você aparece no outro andar.
	var c := rect.get_center()
	var mark := Fx.cylinder(1.4, 0.05, Fx.mat(Color(0.55, 0.6, 0.7), 0.4))
	mark.position = Vector3(c.x, 0.04, c.y)
	add_child(mark)
	for k in 3:
		var step := Fx.box(Vector3(1.6 - k * 0.4, 0.12, 0.5), Fx.mat(Color(0.45, 0.48, 0.55)))
		step.position = Vector3(c.x, 0.08 + k * 0.1, c.y - 0.5 + k * 0.5)
		add_child(step)
	var l := OmniLight3D.new()
	l.light_color = Color(0.75, 0.8, 1.0)
	l.omni_range = 4.5
	l.light_energy = 0.9
	l.position = Vector3(c.x, 1.6, c.y)
	add_child(l)
	var a := add_trigger(rect, func(body): _use_passage(body, to, msg))
	a.set_meta("label", label)
	passages.append({"rect": rect, "to": to, "label": label})


func _use_passage(body: Node3D, to: Vector3, msg: String) -> void:
	var p := body as Player
	if p == null or _passing or p.dead:
		return
	_passing = true
	p.set_physics_process(false)
	p.velocity = Vector3.ZERO
	if hud != null:
		await hud.fade(1.0, 0.4)
	p.global_position = to + Vector3.UP * 0.1
	p.last_safe_pos = to
	p.external_velocity = Vector3.ZERO
	p.snap_camera()
	p.set_physics_process(true)
	EventBus.message.emit(msg)
	if hud != null:
		hud.fade(0.0, 0.6)
	await get_tree().create_timer(0.8).timeout
	_passing = false


func chasm_at(safe: Vector3, now: Vector3) -> Dictionary:
	## Qual abismo: o que contém o ponto de queda (ou o mais perto da última beirada).
	var q := Vector2(now.x, now.z)
	for c in chasms:
		if (c["rect"] as Rect2).grow(0.8).has_point(q):
			return c
	var best := {}
	var best_d := 6.0
	var s2 := Vector2(safe.x, safe.z)
	for c in chasms:
		var r: Rect2 = c["rect"]
		var cl := Vector2(clampf(s2.x, r.position.x, r.end.x), clampf(s2.y, r.position.y, r.end.y))
		var d := cl.distance_to(s2)
		if d < best_d:
			best_d = d
			best = c
	return best


func restart_act() -> void:
	## Chamado pela jogadora morta (permadeath): escurece e recomeça o ato.
	if hud != null:
		hud.show_title("Você morreu", "O ato recomeça do início. Só o que você aprendeu fica.")
		await hud.fade(1.0, 1.4)
		await get_tree().create_timer(1.2).timeout
	GameState.restart_act()


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
	if player != null:
		player.velocity = Vector3.ZERO
		player.set_physics_process(false)
	if hud != null:
		await hud.fade(1.0, 1.0)
	get_tree().change_scene_to_file.call_deferred(path)


func _arrival() -> void:
	## Ao chegar numa camada nova: a tela clareia e aparece o nome dela.
	if hud == null:
		return
	hud.fade_alpha = 1.0
	if resumed:
		hud.fade(0.0, 0.6)
		return
	hud.fade(0.0, 1.6)
	hud.show_title(layer_name, layer_subtitle)


# ---------------------------------------------------------------- construção

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.015, 0.025)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = ambient_energy * (0.12 if dark_vision else 1.0)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = true
	env.fog_light_color = fog_color
	env.fog_density = 0.006
	env.adjustment_enabled = true
	env.adjustment_brightness = Settings.brightness
	Settings.changed.connect(func(): env.adjustment_brightness = Settings.brightness)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.03 if dark_vision else 0.25
	fill.light_color = Color(0.6, 0.65, 0.8)
	fill.rotation_degrees = Vector3(-65.0, 30.0, 0.0)
	fill.shadow_enabled = true
	add_child(fill)


func add_anchor(anchor_name: String, pos: Vector3, height: float = 4.0, radius: float = 0.5, color: Color = Color(0.42, 0.42, 0.47), model: String = "") -> WebAnchor:
	var a := WebAnchor.new(height, radius, color)
	a.name = anchor_name
	a.model_name = model
	a.position = pos
	add_child(a)
	WebNetwork.register_anchor(a)
	return a


func add_wall_anchor(anchor_name: String, pos: Vector3, normal: Vector3, color: Color = Color(0.36, 0.38, 0.4)) -> WebAnchor:
	## Gancho de rocha na parede: âncora como um pilar, mas encostada na parede.
	## Só deve aparecer onde vale a pena (beira de abismo): poucos e fáceis de ler.
	var a := WebAnchor.new(1.3, 0.35, color)
	a.name = anchor_name
	a.kind = "gancho"
	a.wall_normal = normal
	a.position = pos
	add_child(a)
	WebNetwork.register_anchor(a)
	return a


func add_static_box(size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	nav_blockers.append([pos, size])
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
	var m := Models.swap(self, "fungo_roxo" if color.b > color.g else "fungo_verde", 0.55, [cap], "max")
	if m != null:
		m.position = pos
		m.rotation.y = fposmod(pos.x * 1.7 + pos.z * 2.3, TAU)
	var light := OmniLight3D.new()
	light.light_color = color
	light.omni_range = 7.0 if dark_vision else 5.0
	light.light_energy = 1.6 if dark_vision else 1.2
	light.position = pos + Vector3(0.0, 1.0, 0.0)
	light.set_meta("base", light.light_energy)
	light.add_to_group("fungus_light")   # o relógio da caverna acende e apaga
	add_child(light)
	World.graze_spots.append(pos)          # larvas pastam o musgo perto dos fungos


func add_web_decal(pos: Vector3, radius: float = 2.5) -> void:
	## Teia decorativa no chão: raios e anéis finos e translúcidos.
	var mat := Fx.mat(Color(0.86, 0.86, 0.96), 0.5, true, 0.35)
	var root := Node3D.new()
	root.position = pos + Vector3(0.0, 0.03, 0.0)
	add_child(root)
	var m := Models.instance("teia_canto", radius * 2.0, "length")
	if m != null:
		root.add_child(m)
		m.rotation.y = fposmod(pos.x + pos.z, TAU)
		return
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


func add_web_bridge_path(a: Vector2, b: Vector2, width: float) -> void:
	## Ponte de teia antiga em qualquer direção (o chão vem da forma "bridges" da caverna).
	var mat := Fx.mat(Color(0.86, 0.86, 0.96), 0.6, true, 0.6)
	var root := Node3D.new()
	add_child(root)
	var dir := (b - a).normalized()
	var side := Vector2(-dir.y, dir.x)
	var length := a.distance_to(b)
	var off := -width * 0.5 + 0.2
	while off < width * 0.5:
		var p0 := a + side * off
		var p1 := b + side * off
		var line := Fx.box(Vector3(0.04, 0.02, length), mat)
		root.add_child(line)
		Fx.orient_between(line, Vector3(p0.x, 0.04, p0.y), Vector3(p1.x, 0.04, p1.y))
		off += 0.45
	var t := 0.3
	while t < length:
		var c0 := a + dir * t - side * width * 0.5
		var c1 := a + dir * t + side * width * 0.5
		var cross := Fx.box(Vector3(0.03, 0.02, width), mat)
		root.add_child(cross)
		Fx.orient_between(cross, Vector3(c0.x, 0.05, c0.y), Vector3(c1.x, 0.05, c1.y))
		t += 0.7


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
