extends Node
## Teste das Galerias (G1–G7): caminhos, morcegos, lagarto, lago, ponte, território e travas.
## Rodar:  godot --headless --path . res://tests/galerias_test.tscn

var layer
var player: Player
var failures := 0


func _ready() -> void:
	GameState.permadeath = false   # este teste morre de propósito e volta do casulo
	GameState.delete_save()
	GameState.said = {}
	GameState.flags = {}
	layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	# relógio parado na Caça: predadores acordados, ninguém vai dormir no meio do teste
	World.clock.paused = true
	World.clock.set_phase(CaveClock.Phase.CACA)
	for c in World.creatures:
		c.needs.fatigue = 0.0
		c.needs.restless = 0.0
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _run() -> void:
	# Estrutura
	_check(layer.rooms.size() == 31, "G1–G20 em cima + P1–P11 nas Profundezas (%d)" % layer.rooms.size())
	_check(layer.map_system.current_room == "G1", "começa na Entrada (G1)")
	var bats := _alive("bat")
	var g3 := bats.filter(func(b): return String(b.flock).begins_with("g3_"))
	_check(g3.size() == 5 and bats.size() == 12, "bando de 5 morcegos no túnel, 12 no mapa (%d/%d)" % [g3.size(), bats.size()])
	var lizards := get_tree().get_nodes_in_group("creature").filter(func(c): return c is Lizard and not c.has_meta("nest_id") and not c.has_meta("flag"))
	_check(lizards.size() == 1, "um Lagarto-lanterna no jardim")
	var frogs := get_tree().get_nodes_in_group("creature").filter(func(c): return c is Frog)
	_check(frogs.size() == 8, "oito Sapos-de-rocha nos dois andares (%d)" % frogs.size())
	_check(World.creatures.size() >= 50, "mapa cheio: %d criaturas" % World.creatures.size())

	# Caminhos: chão contínuo nas duas rotas até a Grande Gruta e dela para G5, G6 e G7
	var routes := {
		"G1→G2→G4": [Vector2(1, -17), Vector2(3, -14), Vector2(0, -7), Vector2(0, 0), Vector2(-4, 15), Vector2(-2, 34), Vector2(17, 39), Vector2(44, 36)],
		"G1→G3→G4": [Vector2(0, 0), Vector2(18, -8), Vector2(30, -6), Vector2(40, 0), Vector2(44, 10), Vector2(44, 36)],
		"G4→G5": [Vector2(44, 36), Vector2(47, 55), Vector2(44, 72)],
		"G4→G7": [Vector2(44, 36), Vector2(33, 44), Vector2(22, 54), Vector2(13, 67), Vector2(13, 72)],
		"G4→G6": [Vector2(44, 36), Vector2(59, 37), Vector2(66, 39)],
	}
	for r in routes:
		_check(_walkable(routes[r]), "caminho %s sem buracos" % r)
	_check(not layer.cave.is_floor(Vector2(70.5, 39.0)) and not layer.cave.is_floor(Vector2(85.5, 37.0)) and not layer.cave.is_floor(Vector2(99.5, 38.0)), "três fendas cortam a Ponte quebrada")
	var q := PhysicsRayQueryParameters3D.create(Vector3(58.5, 1.0, 25.0), Vector3(65.0, 1.0, 18.0), 1)
	_check(not layer.get_world_3d().direct_space_state.intersect_ray(q).is_empty(), "parede de cristal fecha a Subida antiga")

	# Morcegos: ouvem quem se mexe, não quem fica parada
	var bat: Bat = bats[0]
	_teleport(bat.global_position + Vector3(5.0, -bat.global_position.y + 0.1, 0.0))
	await _frames(2)
	player.velocity = Vector3.ZERO
	_check(not bat.hears(player), "parada a 5 m: o morcego não ouve")
	player.velocity = Vector3(4.0, 0.0, 0.0)
	_check(bat.hears(player), "andando a 5 m: o morcego ouve")

	# Mergulho machuca quem fica andando no túnel
	_teleport(Vector3(26.0, 0.1, -6.0))
	var hp0 := player.hp
	for i in 10:
		Input.action_press("move_right" if i % 2 == 0 else "move_left")
		await _seconds(0.5)
		Input.action_release("move_right" if i % 2 == 0 else "move_left")
	_check(player.hp < hp0, "morcegos mergulham e mordem (PV %d)" % int(player.hp))
	player.hp = player.max_hp

	# No alto, a mordida não alcança
	var high: Bat = null
	for b in _alive("bat"):
		if b.global_position.y > 1.8 and not b.is_entangled():
			high = b
			break
	if high != null:
		_teleport(Vector3(high.global_position.x - 1.0, 0.1, high.global_position.z))
		player.aim_dir = Vector3(1, 0, 0)
		var hb := high.hp
		player._melee(20.0, 1.7, 120.0, false)
		_check(high.hp == hb, "ataque não alcança morcego voando alto")
	else:
		_check(false, "achar um morcego voando alto")

	# Fio lançado (Q) derruba quem voa
	var target: Bat = null
	for b in _alive("bat"):
		if not b.is_entangled():
			target = b
			break
	_teleport(Vector3(target.global_position.x - 5.0, 0.1, target.global_position.z))
	player.aim_dir = Vector3(1, 0, 0)
	target.global_position.x = player.global_position.x + 5.0
	var aimed := player._flyer_in_aim()
	if aimed != null:
		target = aimed
	player._throw_silk()
	_check(target.is_entangled(), "Q prende o morcego no ar")
	await _seconds(1.0)
	_check(not is_instance_valid(target) or target.global_position.y < 0.8, "morcego enredado cai no chão")

	# Fio esticado no caminho do bando prende morcegos
	_teleport(Vector3(1.0, 0.1, -17.0))   # longe do bando (G1): eles voltam a passear
	player.rune_on = false
	for b in _alive("bat"):
		b.player_memory = 0.0
		b.search_left = 0.0
		b.needs.hunger = 0.0   # sem fome: não sai caçando a Filhote, só passeia com o bando
	WebNetwork.create_strand(WebNetwork.anchors["G3_a"], WebNetwork.anchors["G3_b"])
	var caught := false
	for i in 40:
		await _seconds(0.5)
		for b in _alive("bat"):
			if b.is_entangled() and b != target:
				caught = true

		if caught:
			break
	_check(caught, "morcego bate no fio esticado e cai")
	player.rune_on = true

	# Lagarto-lanterna: isca atrai larvas e ele as come
	var lz: Lizard = lizards[0]
	_teleport(Vector3(30.0, 0.1, 36.0))
	lz.hunger = 100.0
	var lv: Larva = layer.ecosystem.spawn_larva(lz.lure_position() + Vector3(5.0, 0.0, 0.0))
	var start_d := Fx.flat_dist(lv.global_position, lz.lure_position())
	var min_d := start_d
	var eaten := false
	for i in 24:
		if not is_instance_valid(lv) or lv.dead:
			eaten = true
			break
		min_d = minf(min_d, Fx.flat_dist(lv.global_position, lz.lure_position()))
		lz.hunger = 100.0   # outras larvas do jardim também vêm até a isca
		await _seconds(0.5)
	_check(eaten or min_d < start_d - 2.0, "larva vai até a isca (%.1f → %.1f m)" % [start_d, min_d])
	_check(eaten, "lagarto come a larva atraída")

	# Território: aviso, depois ataque; fora do território, ele volta
	player.rune_on = false
	player.hp = player.max_hp
	_teleport(lz.global_position + Vector3(0.0, 0.0, -3.5))
	player.global_position.y = 0.1
	hp0 = player.hp
	await _seconds(0.6)
	_check(lz.mode == Lizard.Mode.WARN or lz.mode == Lizard.Mode.CHASE, "isca revela a jogadora (runa apagada) e ele avisa")
	for i in 8:
		await _seconds(0.5)
	_check(player.hp < hp0, "lagarto ataca quem fica no território (PV %d)" % int(player.hp))
	player.rune_on = true
	player.hp = player.max_hp
	_teleport(Vector3(44.0, 0.1, 50.0))
	await _seconds(1.5)
	_check(lz.mode == Lizard.Mode.RETURN or lz.mode == Lizard.Mode.IDLE, "fora do território ele desiste e volta")

	# Comer o lagarto dá Energia máxima (uma vez só)
	var e0 := player.max_energy
	lz.take_damage(999.0, player)
	await _frames(3)
	var corpse: Corpse = null
	for c in get_tree().get_nodes_in_group("corpse"):
		if (c as Corpse).energy_bonus > 0.0:
			corpse = c
	_check(corpse != null, "lagarto deixa um corpo com bônus de energia")
	if corpse != null:
		player._eat(corpse)
	_check(player.max_energy >= e0 + 10.0, "comer o lagarto dá +10 Energia máx. (%d)" % int(player.max_energy))
	_check(GameState.flags.has("g5_lagarto"), "lagarto não volta depois de morto (flag salva)")

	# Lago: só a corrente de fios alcança a ilha
	var a7: WebAnchor = WebNetwork.anchors["G7_a"]
	var b7: WebAnchor = WebNetwork.anchors["G7_b"]
	var c7: WebAnchor = WebNetwork.anchors["G7_c"]
	player.silk = player.max_silk
	_check(player._strand_error(a7, c7) != "", "margem → ilha direto é longe demais")
	_check(player._strand_error(a7, b7) == "" and player._strand_error(b7, c7) == "", "margem → pedrinha → ilha funciona")
	_check(not layer.cave.is_floor(Vector2(3.0, 78.0)), "o lago não tem chão")
	e0 = player.max_energy
	_teleport(Vector3(-4.2, 0.1, 75.2))
	await _seconds(0.3)
	_check(player.max_energy >= e0 + 15.0, "cristal da ilha dá +15 Energia máx.")

	# Ponte quebrada: cada fenda tem pilares ao alcance dos dois lados
	for pair in [["G6_a", "G6_c"], ["G6_f", "G6_h"], ["G6_j", "G6_l"]]:
		_check(player._strand_error(WebNetwork.anchors[pair[0]], WebNetwork.anchors[pair[1]]) == "", "fenda %s ↔ %s alcançável" % pair)

	# Grande Gruta: casulo + 3 fios = território
	_teleport(Vector3(44.0, 0.1, 38.0))
	await _seconds(0.3)
	_check(layer.map_system.revealed.has("G4"), "entrar na gruta revela G4 no mapa")
	WebNetwork.create_cocoon(Vector3(44, 0, 36))
	for pair in [["G4_a", "G4_e"], ["G4_b", "G4_f"], ["G4_c", "G4_h"]]:
		WebNetwork.create_strand(WebNetwork.anchors[pair[0]], WebNetwork.anchors[pair[1]])
	await _frames(3)
	_check(GameState.flags.has("g4_territorio"), "três fios ligados ao casulo = território tecido")

	# Ácido machuca
	_teleport(Vector3(65.0, 0.1, 76.0))
	hp0 = player.hp
	await _seconds(1.0)
	_check(player.hp < hp0 - 10.0, "poça ácida machuca (PV %d)" % int(player.hp))
	player.hp = player.max_hp

	# A Ponte quebrada continua para a Galeria do eco
	_check(_walkable([Vector2(104, 37), Vector2(114, 36), Vector2(127, 38), Vector2(138, 40)]), "Ponte quebrada → Galeria do eco")


func _alive(group: String) -> Array:
	return get_tree().get_nodes_in_group(group).filter(func(c): return is_instance_valid(c) and not c.dead)


func _walkable(pts: Array) -> bool:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n := int(a.distance_to(b) / 0.5)
		for k in n + 1:
			var p := a.lerp(b, float(k) / maxf(n, 1))
			if not layer.cave.is_floor(p):
				print("    sem chão em ", p)
				return false
	return true


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _teleport(pos: Vector3) -> void:
	if player.dead:
		player._respawn()
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.external_velocity = Vector3.ZERO
	player.last_safe_pos = pos


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(int(s * 60.0))
