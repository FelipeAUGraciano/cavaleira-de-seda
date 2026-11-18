extends "res://world/layers/galerias.gd"
## Ato 4 — A caçada. As mesmas Galerias Úmidas do Ato 1 (mesmo mapa, a jogadora reconhece
## cada câmara), mas agora uma expedição humana caça a "aranha da runa".
##   - Chegada pela Chaminé do Rio de Brasa, no Ninho dos lagartos (G12): um Lagarto-lanterna
##     alfa defende o ninho.
##   - ALERTA DA CAÇADA (0 a 3): sobe quando um caçador te vê, acha uma teia sua ou perde um
##     companheiro; cai devagar quando você some. No 3, o esquadrão do acampamento sai atrás de você.
##   - G4 Grande Gruta virou o acampamento-base (tendas, fogueira, suprimentos, o esquadrão).
##   - G22 Fosso escuro: a sua toca antiga foi queimada. As teias do Ato 1 viraram carvão.
##   - G7 Lago escondido: a ilha só se alcança por fio — os caçadores não chegam. A única toca.
##   - G5 Jardim de musgo: armadilhas de fogo dos caçadores; quase sem larvas.
##   - G6, G8, G9: patrulhas com tochas; G9 ocupado e cheio de suprimentos.
##   - G16 Subida antiga: a Capitã da expedição guarda a corda que sobe para o Portão.
##   - Profundezas: os caçadores não descem. Rota de fuga, com bichos.
##   - Bichos: os caçadores limparam muita coisa; os que sobraram são alfas (mais fortes).

const OLD_GALERIAS := "res://world/layers/galerias.tscn"
var hunt: HuntDirector
var captain: Captain
var _rope_open := false
var _ending4 := false
var _traps: Array = []


func _configure() -> void:
	super._configure()
	layer_name = "Galerias Úmidas"
	layer_subtitle = "Ato 4 · A caçada"
	GameState.flags["g8_aventureiros"] = true   # o encontro de longe do Ato 1 não se repete
	var hints := {
		"G12": ["Você subiu pela Chaminé. O Lagarto-lanterna alfa defende o ninho: dá para contornar pelos fios.", "Eu conheço esse lugar. ...Mas tá diferente. Tem cheiro de fumaça."],
		"G4": ["O acampamento-base da expedição. Fogo queima fios. Furtividade (runa apagada) ou luta: e no alerta 3, o esquadrão sai daqui.", "Tendas. Fogueira. Na MINHA gruta."],
		"G5": ["Armadilhas de fogo no chão (placas de metal). Pise em fio por cima delas ou passe de longe.", "Cheiro de óleo queimado. Eles armaram alguma coisa aqui."],
		"G7": ["A ilha só se alcança por fio: os caçadores não chegam. Teça o casulo na ilha (C, 30 de Seda): é a única toca segura.", "A ilha. Eles não sabem tecer. Aqui eles não chegam."],
		"G22": ["A sua toca antiga foi queimada. Não dá mais para usar.", "Queimaram minha casa. QUEIMARAM MINHA CASA."],
		"G9": ["O acampamento agora está ocupado, e cheio de suprimentos. Roubar comida deles é um jeito de comer.", "Eles voltaram. E trouxeram comida. Muita comida."],
		"G16": ["A Capitã da expedição guarda a corda que sobe para o Portão da Superfície.", "Uma corda. Subindo. Lá em cima... luz de verdade."],
	}
	for r in rooms:
		if hints.has(r["id"]):
			r["hint"] = hints[r["id"]][0]
			r["line_id"] = "a4_%s" % String(r["id"]).to_lower()
			r["line"] = hints[r["id"]][1]
		if r["id"] == "G22":
			r.erase("checkpoint")


func _build_level() -> void:
	super._build_level()
	# a Chaminé do Rio de Brasa sai no canto sudoeste do Ninho dos lagartos
	spawn_point = _snap_floor(W3(38.0, 0.1, 108.0), 1.2) + Vector3(0, 0.1, 0)
	entries = {"rio": {"spawn": spawn_point, "from": _snap_floor(W3(35.0, 0.1, 113.0), 0.8) + Vector3(0, 0.1, 0)}}
	_build_base_camp()
	_build_burnt_den()
	_build_charred_webs()
	_build_fire_traps()
	# G9 ocupado: mais tendas e caixas de suprimentos
	for b in [W3(173, 0.45, 52), W3(191, 0.45, 44)]:
		add_static_box(Vector3(1.0, 0.9, 1.0), b, Color(0.42, 0.3, 0.2))


func _build_base_camp() -> void:
	## G4: o acampamento-base da expedição. Três tendas, fogueira, caixas e uma bandeira.
	var canvas := Color(0.58, 0.5, 0.38)
	for t in [[W3(36, 0.9, 30), 0.4], [W3(52, 0.9, 31), -0.3], [W3(36, 0.9, 43), 1.2]]:
		var tent := add_static_box(Vector3(3.0, 1.8, 2.4), _snap_floor(t[0], 1.6) + Vector3(0, 0.9, 0), canvas)
		tent.rotation.y = float(t[1])
	var fire := Fire.new(0.9)
	fire.position = _snap_floor(W3(44, 0, 36), 1.0)
	add_child(fire)
	for c in [W3(48, 0.45, 41), W3(49.2, 0.35, 42), W3(40, 0.45, 40)]:
		add_static_box(Vector3(0.9, 0.9, 0.9), _snap_floor(c, 0.8) + Vector3(0, 0.45, 0), Color(0.42, 0.3, 0.2))
	var pole := Fx.cylinder(0.06, 3.0, Fx.mat(Color(0.35, 0.25, 0.15)))
	var bp := _snap_floor(W3(55, 0, 36), 0.6)
	pole.position = bp + Vector3(0, 1.5, 0)
	add_child(pole)
	var flag := Fx.box(Vector3(0.05, 0.7, 1.0), Fx.mat(Color(0.6, 0.15, 0.12)))
	flag.position = bp + Vector3(0, 2.6, 0.5)
	add_child(flag)
	for t in [W3(38, 0, 33), W3(50, 0, 39)]:
		var torch := Fire.new(1.0)
		torch.position = _snap_floor(t, 0.8)
		add_child(torch)


func _build_burnt_den() -> void:
	## G22: o casulo da toca do Ato 1, queimado e preto.
	var ash := Fx.mat(Color(0.08, 0.07, 0.07))
	var shell := Fx.sphere(1.0, ash)
	shell.scale = Vector3(1.0, 0.6, 1.0)
	shell.position = Vector3(DEN_C.x, 0.4, DEN_C.y)
	add_child(shell)
	var ring := Fx.cylinder(3.0, 0.03, Fx.mat(Color(0.12, 0.1, 0.1)))
	ring.position = Vector3(DEN_C.x, 0.02, DEN_C.y)
	add_child(ring)


func _build_charred_webs() -> void:
	## As teias que você deixou no Ato 1 viraram carvão: fios pretos e quebrados.
	var all_webs: Dictionary = GameState.knowledge.get("webs", {})
	var old: Dictionary = all_webs.get(OLD_GALERIAS, {})
	var strands: Array = old.get("strands", [])
	if strands.is_empty():   # sem registro do Ato 1: alguns fios queimados no lugar da toca e da gruta
		strands = [["G4_a", "G4_b"], ["G4_b", "G4_c"], ["G4_c", "G4_a"], ["G5_a", "G5_b"], ["G1_a", "G1_b"]]
	var coal := Fx.mat(Color(0.06, 0.05, 0.05))
	for s in strands:
		var a: Node3D = WebNetwork.anchors.get(String(s[0]))
		var b: Node3D = WebNetwork.anchors.get(String(s[1]))
		if a == null or b == null:
			continue
		var pa := a.global_position + Vector3(0, 0.15, 0)
		var pb := b.global_position + Vector3(0, 0.15, 0)
		var mid := pa.lerp(pb, 0.45)
		for half in [[pa, mid.lerp(pa, 0.15)], [pb, mid.lerp(pb, -0.1)]]:
			var seg := Fx.box(Vector3(0.05, 0.05, (half[0] as Vector3).distance_to(half[1])), coal)
			add_child(seg)
			Fx.orient_between(seg, half[0], half[1])


func _build_fire_traps() -> void:
	## G5: placas de metal com óleo por baixo. Pisou, estoura fogo.
	for q in [W3(40, 0, 69), W3(47, 0, 70), W3(44, 0, 74), W3(39, 0, 76), W3(49, 0, 77)]:
		var t := FireTrap.new()
		t.position = _snap_floor(q, 0.6)
		add_child(t)
		_traps.append(t)


func _build_rope() -> void:
	## G16: a corda da expedição desce do alto pela beira do abismo da Subida antiga, na
	## borda sul (de onde se vê a luz lá em cima). Sobe para o Portão.
	var top := _snap_floor(Vector3(66.5, 0, 24.8), 0.7)
	var rope := Fx.cylinder(0.05, 6.0, Fx.mat(Color(0.6, 0.5, 0.3)))
	rope.position = top + Vector3(0, 3.0, 0)
	add_child(rope)
	for k in 6:
		var knot := Fx.sphere(0.09, Fx.mat(Color(0.5, 0.4, 0.25)))
		knot.position = top + Vector3(0, 0.5 + k, 0)
		add_child(knot)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.9, 0.7)
	l.omni_range = 6.0
	l.light_energy = 1.2
	l.position = top + Vector3(0, 4.0, 0)
	add_child(l)
	set_meta("rope", top)


# ---------------------------------------------------------------- bichos e caçadores

func _reachable(a: Vector3, b: Vector3) -> bool:
	var p: PackedVector3Array = World.nav.path(a, b)
	return p.size() > 0 and Fx.flat_dist(p[p.size() - 1], b) < 1.5


func _populate() -> void:
	_build_rope()
	hunt = HuntDirector.new()
	add_child(hunt)
	hunt.squad_out.connect(func(): EventBus.big_message.emit("ALERTA 3: o esquadrão saiu do acampamento!"))
	# comida escassa: poucas larvas lá em cima, um pouco mais nas Profundezas
	ecosystem.larva_spawns.clear()
	for sp in [W3(10, 0, 74), W3(20, 0, 14), W3(-12, 0, 18), W3(160, 0, 70), W3(18, 0, 100)]:
		ecosystem.larva_spawns.append(_snap_floor(sp))
	ecosystem.larva_spawns.append_array(_deep_spots(5, 201))
	ecosystem.frog_spawns.clear()
	ecosystem.frog_spawns.append_array(_deep_spots(3, 202))
	ecosystem.larva_target = 7
	ecosystem.frog_target = 3
	ecosystem.on_spawn = _setup_creature
	ecosystem.spawn_initial()
	for k in 3:
		_spawn_bat(_snap_floor(W3(28, 0, -6)))
	var deep_flock: Vector3 = _deep_spots(1, 203)[0]
	for k in 4:
		_spawn_bat(deep_flock, ["P2", "P1", "P3", "P5"], "p2")
	# os que sobraram são alfas
	var alpha := Lizard.new()
	alpha.position = _snap_floor(W3(47, 0.3, 100), 1.0) + Vector3(0, 0.3, 0)
	alpha.territory_radius = 7.0
	_alpha(alpha, 2.5)
	ecosystem.add_child(alpha)
	for sp in _deep_spots(2, 204):
		var dlz := Lizard.new()
		dlz.position = sp + Vector3(0, 0.3, 0)
		dlz.territory_radius = 6.5
		_alpha(dlz, 1.8)
		ecosystem.add_child(dlz)
	var sis_spots: Array = [_snap_floor(W3(-12, 0, 18))]
	sis_spots.append_array(_deep_spots(2, 205))
	for sp in sis_spots:
		var sis := Sister.new(true)
		sis.position = sp + Vector3(0, 0.3, 0)
		sis.display_name = "Irmã caçadora"
		_alpha(sis, 1.8)
		ecosystem.add_child(sis)
	# a expedição
	var camp := _snap_floor(W3(44, 0, 36), 1.2)
	var roles := ["espadachim", "espadachim", "arqueira", "batedor"]
	for k in roles.size():
		var a := k * TAU / roles.size() + 0.4
		_hunter(roles[k], camp + Vector3(cos(a) * 3.0, 0, sin(a) * 3.0), ["G4"], true)
	_hunter("espadachim", W3(64, 0, 38), ["G6", "G4"])
	_hunter("batedor", W3(60, 0, 40), ["G6", "G4", "G18"])
	_hunter("arqueira", W3(133, 0, 40), ["G8", "G21"])
	_hunter("espadachim", W3(140, 0, 44), ["G8", "G21", "G13"])
	_hunter("espadachim", W3(180, 0, 44), ["G9", "G20"])
	_hunter("arqueira", W3(186, 0, 46), ["G9"])
	_hunter("batedor", W3(178, 0, 48), ["G9", "G21", "G13"])
	_hunter("batedor", W3(42, 0, 66), ["G5", "G18", "G4"])
	_hunter("arqueira", Vector3(70.0, 0, 24.0), ["G16"])
	if not GameState.flags.has("g16_capita"):
		captain = Captain.new()
		captain.position = _snap_floor(Vector3(62.0, 0, 25.5), 1.0) + Vector3(0, 0.3, 0)
		captain.range_rooms = ["G16"]
		captain.den = captain.position
		captain.director = hunt
		captain.horn.connect(_on_horn)
		ecosystem.add_child(captain)
	else:
		_rope_open = true
	# a única toca: a ilha do Lago escondido
	var island := WL3(-3, 0, 74)
	den = Den.new().setup("G7ilha", island, [], "Ilha do lago")
	den.inner_r = 2.2
	add_child(den)
	# suprimentos para roubar (G4 e G9)
	for it in [["racao", "a4_racao_g4a", W3(48.5, 0, 43)], ["racao", "a4_racao_g4b", W3(39, 0, 41)], ["racao", "a4_racao_g9a", W3(174, 0, 50)],
			["racao", "a4_racao_g9b", W3(190, 0, 46)], ["racao", "a4_racao_g9c", W3(185, 0, 52)], ["fragmento", "a4_fragmento_g16", W3(82, 0, 6)]]:
		if GameState.flags.has(it[1]):
			continue
		var pk := Pickup.new(it[0], it[1])
		pk.position = _snap_floor(it[2], 0.5)
		add_child(pk)
	add_child(_note(_snap_floor(W3(46, 0, 33), 0.6), "a4_ordens", [
		"Ordens da Capitã: a aranha da runa matou a centopeia. Está grande agora. Ninguém sai sozinho.",
		"Batedores: sigam a seda. Toda teia que acharem, queimem. Arqueiras: flechas de fogo, sempre.",
		"Se a virem, toquem o sino. Se o sino tocar três vezes, todo mundo sai do acampamento."], "papel"))
	_open_door_out()
	add_trigger(Rect2(Vector2(get_meta("rope").x, get_meta("rope").z) - Vector2(1.6, 1.6), Vector2(3.2, 3.2)), _on_rope)
	EventBus.rested.connect(_on_rested)
	EventBus.creature_died.connect(_on_creature_died)


func _hunter(role: String, at: Vector3, rooms_: Array, squad := false) -> Hunter:
	var h := Hunter.new(role)
	h.position = _snap_floor(at, 1.0) + Vector3(0, 0.3, 0)
	h.range_rooms = rooms_
	h.squad = squad
	h.den = h.position
	h.director = hunt
	ecosystem.add_child(h)
	return h


func _alpha(c: Creature, k: float) -> void:
	## Sobrevivente da limpeza dos caçadores: mais forte e mais esperto.
	c.level += 5
	c.max_hp *= k
	c.food_xp = int(c.food_xp * 2.0)
	for a in c.attacks:
		(a as Attack).damage *= 1.5
	if not c.display_name.ends_with(" alfa"):
		c.display_name += " alfa"


func _on_horn() -> void:
	for k in 2:
		var h := _hunter("espadachim", W3(62, 0, 18) + Vector3(k * 1.5, 0, 0), ["G16", "G4"])
		h.player_memory = h.memory_time
		if player != null:
			h.last_player_pos = player.global_position


func _start() -> void:
	GameState.hunt_alert = 0.0
	if not resumed:
		EventBus.message.emit("Objetivo: atravesse as Galerias até a Subida antiga (noroeste). A expedição está caçando você.")
	GameState.say_once("a4_chegada", "As Galerias. Voltei. ...Por que tudo tem cheiro de fumaça?")
	# a primeira vez: o mapa do Ato 1 ainda está na cabeça dela
	var maps: Dictionary = GameState.knowledge.get("maps", {})
	if not maps.has(scene_file_path) and maps.has(OLD_GALERIAS):
		map_system.from_dict(maps[OLD_GALERIAS])


func _on_rested(_c: Node) -> void:
	pass   # aqui nada repõe sozinho: comida escassa


func _on_territory_changed() -> void:
	pass


func _on_creature_died(c: Node) -> void:
	if c is Captain:
		GameState.flags["g16_capita"] = true
		_rope_open = true
		EventBus.big_message.emit("A Capitã caiu")
		GameState.say_once("capita_morta", "A Capitã caiu. A corda tá livre. Lá em cima... a superfície.")
	elif c is Hunter:
		pass


func _on_rope(body: Node3D) -> void:
	## Fim do Ato 4 (o Portão da Superfície vem na próxima versão).
	if not (body is Player) or _ending4:
		return
	if not _rope_open:
		EventBus.message.emit("A Capitã guarda a corda. Primeiro ela.")
		return
	_ending4 = true
	GameState.flags["ato4_fim"] = true
	player.autopilot = true
	player.auto_target = get_meta("rope") + Vector3(0, 0.1, 0)
	hud.cinematic = true
	GameState.say_once("a4_corda", "Subindo. Pela corda deles. Que ironia deliciosa.")
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	await hud.fade(1.0, 1.2)
	hud.show_title("Fim do Ato 4", "O Portão da Superfície chega na próxima versão.")
	autosave()
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return
	player.global_position = _snap_floor(Vector3(60.0, 0, 28.0), 0.8) + Vector3(0, 0.1, 0)
	player.snap_camera()
	player.autopilot = false
	hud.cinematic = false
	await hud.fade(0.0, 1.0)
	_ending4 = false


func _physics_process(delta: float) -> void:
	super._physics_process(delta)


# ---------------------------------------------------------------- alerta da caçada

class HuntDirector extends Node:
	## Alerta da caçada, de 0 a 3. Sobe quando um caçador te vê (+0,8), acha teia (+0,4) ou perde
	## um companheiro (+0,6). Depois de 20 s sem te ver, cai 1 nível a cada 25 s.
	## No 3, o esquadrão do acampamento sai atrás do último lugar onde te viram.
	signal level_changed(level: int)
	signal squad_out

	var alert := 0.0
	var last_pos := Vector3.ZERO
	var since_seen := 99.0
	var squad_sent := false

	func raise(amount: float, pos: Vector3, _by: Node = null) -> void:
		var before := int(alert)
		alert = minf(3.0, alert + amount)
		last_pos = pos
		since_seen = 0.0
		var now := int(alert)
		if now > before:
			level_changed.emit(now)
			if now < 3:
				EventBus.message.emit("Alerta da caçada %d: %s" % [now, ["", "eles sabem que você está por perto.", "os caçadores estão procurando você."][now]])
		if now >= 3 and not squad_sent:
			_send_squad()
		elif squad_sent:
			_point_squad()
		GameState.hunt_alert = alert

	func comrade_down(h: Node) -> void:
		var alive := 0
		for o in get_tree().get_nodes_in_group("hunter"):
			if o != h and not (o as Creature).dead:
				alive += 1
		if alive > 0:
			raise(0.6, (h as Node3D).global_position, h)

	func _send_squad() -> void:
		squad_sent = true
		squad_out.emit()
		GameState.say_once("a4_esquadrao", "Sinos. Três vezes. Eles tão vindo TODOS.")
		_point_squad()

	func _point_squad() -> void:
		for o in get_tree().get_nodes_in_group("hunter"):
			var h := o as Hunter
			if h == null or h.dead or not h.squad:
				continue
			h.range_rooms = []
			h.track_range = 200.0
			h.leash_range = 200.0
			h.player_memory = h.memory_time
			h.last_player_pos = last_pos

	func _process(delta: float) -> void:
		since_seen += delta
		if since_seen > 20.0 and alert > 0.0:
			var before := int(alert)
			alert = maxf(0.0, alert - delta / 25.0)
			if int(alert) < before:
				level_changed.emit(int(alert))
				EventBus.message.emit("O alerta da caçada baixou para %d." % int(alert))
			if alert < 2.0 and squad_sent:
				squad_sent = false
				for o in get_tree().get_nodes_in_group("hunter"):
					var h := o as Hunter
					if h != null and not h.dead and h.squad:
						h.range_rooms = ["G4"]
						h.track_range = 24.0
						h.leash_range = 45.0
		GameState.hunt_alert = alert


# ---------------------------------------------------------------- armadilha de fogo

class FireTrap extends Node3D:
	## Placa de metal com óleo por baixo (G5). Pisou (no chão), estoura fogo: queima você, os fios
	## por perto e faz barulho (sobe o alerta). Rearma em 8 s. Sobre um fio, não dispara.
	var armed := true
	var _t := 0.0
	var _plate: MeshInstance3D
	var _burst: MeshInstance3D

	func _ready() -> void:
		add_to_group("fire_trap")
		var steel := Fx.mat(Color(0.35, 0.33, 0.3))
		steel.metallic = 0.8
		_plate = Fx.cylinder(0.55, 0.05, steel)
		_plate.position.y = 0.03
		add_child(_plate)
		_burst = Fx.cylinder(1.1, 2.2, Fx.mat(Color(1.0, 0.5, 0.12), 3.0, true, 0.7))
		_burst.position.y = 1.1
		_burst.visible = false
		add_child(_burst)

	func _physics_process(delta: float) -> void:
		if not armed:
			_t += delta
			_burst.visible = _t < 0.8
			if _t > 8.0:
				armed = true
			return
		var p := GameState.player as Player
		if p == null or p.dead or p.on_strand:
			return
		if Fx.flat_dist(p.global_position, global_position) < 0.85:
			armed = false
			_t = 0.0
			if p.take_damage(16.0 * maxf(0.4, p.fire_mult()), null, false):
				p.apply_burn(3.0)
			for s in WebNetwork.strands.duplicate():
				if is_instance_valid(s) and (s as WebStrand).distance_to(global_position) < 2.5:
					WebNetwork.remove_strand(s)
			EventBus.message.emit("Armadilha de fogo!")
			GameState.say_once("a4_armadilha", "FOGO NO CHÃO! Eles armaram o CHÃO!")
			var l = GameState.current_layer
			if l != null and "hunt" in l and l.hunt != null:
				l.hunt.raise(0.5, global_position)
