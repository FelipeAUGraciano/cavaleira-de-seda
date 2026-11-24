extends Node
## Ato 2, primeiro trecho: a queda da Fenda (cena), a chegada no Abismo ferida e sem seda,
## o Ossário (besouros), a Trilha do Colosso (ronda, vibração, rachaduras) e a toca A4.
## Rodar:  godot --headless --path . res://tests/abismo_test.tscn

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	reparent(get_tree().root)
	get_tree().current_scene = null
	GameState.new_game()
	GameState.delete_save()
	GameState.flags["g14_centopeia"] = true
	await _frames(5)
	get_tree().change_scene_to_file("res://world/layers/galerias.tscn")
	await _seconds(1.5)
	var g = get_tree().current_scene
	var player: Player = GameState.player
	player.invuln = 999.0
	player.global_position = Galerias.W(Vector3(169.0, 0.1, 110.0))
	player.velocity = Vector3.ZERO
	await _seconds(0.5)
	_check(g.hud.cinematic and player.autopilot, "na Borda da Fenda a cena começa (faixas pretas)")
	var low := 0.0
	var ls: Node = null
	for i in 120:
		await _seconds(0.1)
		if is_instance_valid(player):
			low = minf(low, player.global_position.y)
		var found := get_tree().get_nodes_in_group("loading_screen")
		if not found.is_empty():
			ls = found[0]
			break
	_check(low < -15.0, "ela despenca Fenda abaixo, a câmera junto (%.0f m)" % low)
	_check(ls != null and ls.header == "Fim do Ato 1", "tela de carregamento com 'Fim do Ato 1'")
	var arrived := false
	for i in 150:
		await _seconds(0.1)
		var sc = get_tree().current_scene
		if sc != null and String(sc.scene_file_path).ends_with("abismo.tscn"):
			arrived = true
			break
	_check(arrived, "chega no Abismo")
	if not arrived:
		return _end()
	await _frames(3)
	var a = get_tree().current_scene
	player = GameState.player
	_check(player.global_position.y > 3.0 and a.hud.cinematic, "chega caindo do alto, em cena")
	var landed := false
	for i in 40:
		await _seconds(0.1)
		if player.global_position.y < 0.5:
			landed = true
			break
	_check(landed, "bate no chão do Fundo da queda")
	await _frames(3)
	_check(absf(player.hp - player.max_hp * 0.3) < 1.0, "ferida: 30%% da vida (%.0f/%.0f)" % [player.hp, player.max_hp])
	_check(player.silk < 0.5, "sem seda (%.1f)" % player.silk)
	await _seconds(1.8)
	_check(a.hud._area == "Abismo", "o nome 'Abismo' aparece em cima")
	var free := false
	for i in 60:
		await _seconds(0.1)
		if not player.autopilot:
			free = true
			break
	_check(free and not a.hud.cinematic, "depois o controle volta")
	player.invuln = 999.0

	# câmaras e caminhos
	for id in ["A1", "A2", "A3", "A4"]:
		_check(World.nav.room_cells.has(id) and not (World.nav.room_cells[id] as Array).is_empty(), "câmara %s existe" % id)
	var path: PackedVector3Array = World.nav.path(a.spawn_point, Vector3(84, 0, -6))
	print("    caminho: ", path.size(), " fim ", path[path.size() - 1] if path.size() > 0 else Vector3.ZERO)
	_check(path.size() > 2 and Fx.flat_dist(path[path.size() - 1], Vector3(84, 0, -6)) < 2.0, "dá para andar do Fundo da queda até a toca A4")
	for n in a.niche_spots:
		var pr: Vector2 = a.colossus.project(n)
		_check(a.cave.is_floor(Vector2(n.x, n.z)) and pr.y > Colossus.REACH + 0.5, "rachadura a %.1f m do meio da trilha (fora do alcance)" % pr.y)
	for pair in [[a.spawn_point, Vector3(87, 0, -40), "A1 → Floresta (pela toca)"], [Vector3(87, 0, -40), Vector3(62, 0, -55), "Floresta → Ninho"],
			[a.spawn_point, Vector3(106, 0, -7), "A1 → Câmara de cristal"], [a.spawn_point, Vector3(90, 0, 45), "A1 → Fosso dos besouros (rachadura)"],
			[Vector3(152, 0, -40), Vector3(156, 0, 0), "Santuário → arena"], [Vector3(112, 0, -7), Vector3(126, 0, 8), "Cortina viva liga a Trilha"]]:
		_check(_reach(pair[0], pair[1]), "dá para andar: %s" % pair[2])
	_check(not _reach(Vector3(106, 0, -38), Vector3(130, 0, -38)), "o Abismo duplo não se atravessa a pé")
	_check(not _reach(Vector3(87, 0, -40), Vector3(152, 0, -40)), "sem atalho do norte para o Santuário")
	_check(not _reach(Vector3(156, 0, 0), Vector3(160, 0, 26)), "o corpo da Serpente tapa o Poço de vapor")
	_check(not _reach(Vector3(126, 0, 8), Vector3(156, 0, 0)), "sem atalho da Trilha para a arena")
	var big := 0
	for id in ["A1", "A2", "A5", "A6", "A11", "A12", "A15", "A18"]:
		big += (World.nav.room_cells.get(id, []) as Array).size()
	_check(big > 3500, "caverna gerada grande como as Galerias (%d m² nessas câmaras)" % big)

	# Tecelagem: o Abismo duplo pede 17,6 m de fio
	var wa: WebAnchor = WebNetwork.anchors["A9_o_-41"]
	var wb: WebAnchor = WebNetwork.anchors["A9_l_-41"]
	player.silk = player.max_silk
	_check(player._strand_error(wa, wb).begins_with("Longe demais"), "Tecelagem 1: o fio não alcança o outro lado (%.1f m)" % Fx.flat_dist(wa.global_position, wb.global_position))
	player.weave_xp = 55
	player._gain_weave()
	_check(player.weave_level() == 5 and is_equal_approx(player.strand_range(), 18.0), "56 fios tecidos: Tecelagem 5, fio de 18 m")
	_check(player._strand_error(wa, wb) == "", "com Tecelagem 5 o fio atravessa o Abismo duplo")
	var anchors_a6 := 0
	for n in WebNetwork.anchors:
		if String(n).begins_with("A6_"):
			anchors_a6 += 1
	_check(anchors_a6 >= 20, "Floresta de estalagmites com dezenas de pilares (%d)" % anchors_a6)

	# Ossário: besouros
	var beetles: Array = []
	for c in World.creatures:
		if c is Beetle and String(c.get_meta("grupo", "")).begins_with("A2"):
			beetles.append(c)
	_check(beetles.size() == 7, "7 besouros carniceiros no Ossário (%d)" % beetles.size())
	var b: Beetle = beetles[0]
	player.global_position = b.global_position + Vector3(2.0, 0, 0)
	player.velocity = Vector3.ZERO
	var d0 := Fx.flat_dist(b.global_position, player.global_position)
	await _seconds(1.2)
	_check(is_instance_valid(b) and Fx.flat_dist(b.global_position, player.global_position) > d0 + 1.0, "besouro foge de você")
	var food: Variant = beetles[3].find_food()
	_check(food is Vector3, "besouro acha carcaça velha para roer")
	b.take_damage(999.0, player)
	await _seconds(0.3)
	var corpse: Corpse = null
	for c in get_tree().get_nodes_in_group("corpse"):
		if c is Corpse and (c as Corpse).display_name == "Besouro carniceiro":
			corpse = c
	_check(corpse != null, "besouro morto vira comida")
	if corpse != null:
		player.silk = 0.0
		var s0 := player.silk
		player._eat(corpse)
		await _seconds(3.0)
		_check(player.silk > s0 + 5.0, "comer besouro devolve seda (%.0f → %.0f)" % [s0, player.silk])

	# Trilha do Colosso
	var col: Colossus = a.colossus
	player.global_position = Vector3(31, 0.1, 8)
	var s_a := col.s
	await _seconds(1.0)
	_check(absf(col.s - s_a) > 1.5 and col.mode == Colossus.Mode.PATROL, "o Colosso faz a ronda pela trilha")
	# parada, de lado, no escuro: ele passa
	col.s = 30.0
	col.dir = 1.0
	col.mode = Colossus.Mode.PATROL
	var side := col.point_at(42.0) + Vector3(0, 0.1, 0) + _side_off(col, 42.0, 3.8)
	player.global_position = side
	player.velocity = Vector3.ZERO
	player.invuln = 0.0
	player.rune_on = false
	var passed := false
	for i in 80:
		await _seconds(0.1)
		player.global_position = side
		player.velocity = Vector3.ZERO
		if col.s > 50.0:
			passed = true
			break
	_check(passed and not player.dead and col.mode == Colossus.Mode.PATROL, "parada de lado no escuro, ele passa sem notar")
	# fio perto dele: a vibração chega
	col.s = 60.0
	col.mode = Colossus.Mode.PATROL
	col._place(0.0)
	player.invuln = 999.0
	player.global_position = col.point_at(70.0) + _side_off(col, 70.0, 4.5)
	player.on_strand = true
	col._sense(player)
	_check(col.mode == Colossus.Mode.CHARGE, "andar num fio perto dele: ele sente e avança")
	player.on_strand = false
	# correndo no meio da trilha: ele avança e mata na hora
	col._calm()
	col.s = 20.0
	col.dir = 1.0
	col._place(0.0)
	player.invuln = 0.0
	player.hp = player.max_hp
	player.global_position = col.point_at(32.0) + Vector3(0, 0.1, 0)
	player.noise = 8.0
	col._sense(player)
	_check(col.mode == Colossus.Mode.CHARGE, "correndo perto, ele te sente pelo chão")
	for i in 60:
		await get_tree().physics_frame
		player.global_position = col.point_at(32.0) + Vector3(0, 0.1, 0)
		if player.dead:
			break
	_check(player.dead, "ele te alcança: uma pisada e acabou")
	await _seconds(4.0)
	if player.dead:
		player._respawn()
	# rachadura: ele não alcança
	player.invuln = 999.0
	col._calm()
	var nk: Vector3 = a.niche_spots[2]
	var pr2: Vector2 = col.project(nk)
	col.s = pr2.x - 14.0
	col.dir = 1.0
	player.global_position = nk + Vector3(0, 0.1, 0)
	player.velocity = Vector3.ZERO
	await _frames(2)
	player.invuln = 0.0
	col._alert()
	var sniffed := false
	for i in 240:
		await get_tree().physics_frame
		player.global_position = nk + Vector3(0, 0.1, 0)
		if col.mode == Colossus.Mode.SNIFF:
			sniffed = true
	_check(sniffed and not player.dead, "escondida na rachadura: ele fareja e não alcança")
	await _seconds(4.0)
	_check(col.mode == Colossus.Mode.PATROL, "desiste e volta para a ronda")
	# pisa e arrebenta os fios
	player.invuln = 999.0
	var p1: Vector3 = col.point_at(col.s + col.dir * 8.0) + _side_off(col, col.s + col.dir * 8.0, 3.0)
	var p2: Vector3 = col.point_at(col.s + col.dir * 8.0) - _side_off(col, col.s + col.dir * 8.0, 3.0)
	var an1: WebAnchor = a.add_anchor("T_1", p1, 2.0)
	var an2: WebAnchor = a.add_anchor("T_2", p2, 2.0)
	var st := WebNetwork.create_strand(an1, an2)
	var ref: WeakRef = weakref(st)
	player.global_position = Vector3(31, 0.1, 8)
	var torn := false
	for i in 80:
		await _seconds(0.1)
		if ref.get_ref() == null or not WebNetwork.strands.has(st):
			torn = true
			break
	_check(torn, "fio atravessando a trilha: ele pisa e arrebenta")

	# A4: a toca do Abismo
	_check(a.den != null and a.den.is_inside(Vector3(84, 0, -6)), "a Fenda do refúgio é uma toca")
	_check(a.den.slots.size() == 4, "quatro frestas (Trilha, Floresta, Lago, Cristal)")
	var far: float = col.project(Vector3(84, 0, -6)).y
	_check(far > 12.0, "a toca fica longe do caminho do Colosso (%.0f m)" % far)

	# Bichos: o Abismo cheio como as Galerias (os predadores comem alguns besouros no caminho)
	var kinds := {}
	var total := 0
	for c in World.creatures:
		if is_instance_valid(c) and not c.dead:
			total += 1
			kinds[c.display_name] = int(kinds.get(c.display_name, 0)) + 1
	_check(total >= 42, "Abismo cheio: %d bichos (%s)" % [total, str(kinds)])
	for nm in ["Aranha-lobo do breu", "Mímico de estalagmite", "Lesma de ácido", "Morcego gigante", "Escorpião-de-obsidiana"]:
		_check(kinds.has(nm), "tem %s" % nm)
	# matilha: uma te sente, todas vêm
	var wolves: Array = []
	for c in World.creatures:
		if c is WolfSpider and (c as WolfSpider).pack == "A17":
			wolves.append(c)
	if wolves.size() >= 2:
		player.invuln = 999.0
		player.global_position = (wolves[0] as Node3D).global_position + Vector3(3, 0.1, 0)
		(wolves[0] as WolfSpider).howl()
		var all_in := true
		for w in wolves:
			if (w as Creature).player_memory <= 0.0 and w != wolves[0]:
				all_in = false
		_check(all_in, "aranha-lobo bate as patas: a matilha toda vem (%d)" % wolves.size())
	# mímico: parece pilar até você passar perto
	var mm: Mimic = null
	for c in World.creatures:
		if c is Mimic:
			mm = c
			break
	if mm != null:
		_check(mm.mode == Mimic.Mode.HIDDEN, "o mímico fica parado, parecendo pilar")
		player.invuln = 0.0
		player.hp = player.max_hp
		player.global_position = mm.global_position + Vector3(1.6, 0.1, 0)
		await _seconds(0.9)
		_check(mm.mode != Mimic.Mode.HIDDEN and player.hp < player.max_hp, "passou perto: o pilar morde")
		player.invuln = 999.0
		player.global_position = Vector3(31, 0.1, 8)
	# lesma: rastro de ácido
	var sl: AcidSlug = null
	for c in World.creatures:
		if c is AcidSlug:
			sl = c
			break
	if sl != null:
		sl.global_position += Vector3(2.0, 0, 0)
		await _seconds(0.3)
		_check(not get_tree().get_nodes_in_group("acid_puddle").is_empty(), "a lesma deixa rastro de ácido")
		var pd: Node3D = get_tree().get_nodes_in_group("acid_puddle")[0]
		sl.global_position += Vector3(0, 0, 4.0)   # a lesma sai de cima do rastro
		sl.set_physics_process(false)
		player.invuln = 0.0
		player.resist_acid = 0
		player.hp = player.max_hp
		player.global_position = pd.global_position + Vector3(0, 0.1, 0)
		await _seconds(0.3)
		_check(player.hp < player.max_hp, "pisar no rastro queima")
		sl.set_physics_process(true)
		player.invuln = 999.0
		player.global_position = Vector3(31, 0.1, 8)
	# A5: a pérola do Lago negro
	var pearl: Pickup = null
	for n in get_tree().get_nodes_in_group("pickup"):
		if (n as Pickup).kind == "olho_escuro":
			pearl = n
	_check(pearl != null and a.cave.is_floor(Vector2(pearl.global_position.x, pearl.global_position.z)), "a pérola está na ilha do Lago negro")
	var sight0 := player.sight_radius()
	if pearl != null:
		player.invuln = 999.0
		player.global_position = pearl.global_position + Vector3(0, 0.1, 0)
		await _seconds(0.4)
	_check(player.sight_radius() > sight0 + 1.4, "Resistência a Escuridão: +1,5 m de visão (%.1f → %.1f)" % [sight0, player.sight_radius()])

	# A7: escorpiões
	var sc: Scorpion = null
	for c in World.creatures:
		if c is Scorpion:
			sc = c
	_check(sc != null, "escorpiões no Ninho")
	if sc != null:
		player.invuln = 0.0
		player.hp = player.max_hp
		player.global_position = sc.global_position + Vector3(2.5, 0.1, 0)
		sc.on_attack_hit(sc.find_attack("ferrao"), player)
		_check(player.poison_t > 0.0, "o ferrão envenena")
		var hp0 := player.hp
		await _seconds(1.0)
		_check(player.hp < hp0 - 1.5, "veneno tira vida aos poucos (%.1f)" % (hp0 - player.hp))
		player.poison_t = 0.0
		player.invuln = 999.0
		sc.take_damage(999.0, player)
		await _seconds(0.3)
		var sk: Corpse = null
		for c in get_tree().get_nodes_in_group("corpse"):
			if (c as Corpse).display_name == "Escorpião-de-obsidiana":
				sk = c
		if sk != null:
			player._eat(sk)
		_check(player.resist_poison == 1, "comer escorpião: Resistência a Veneno 1")

	# A8: a Cortina viva
	var cur: BatCurtain = a.curtain
	cur.mode = BatCurtain.Mode.SLEEP
	player.invuln = 999.0
	player.rune_on = false
	player.global_position = cur.global_position + Vector3(0, 0.1, 0)
	player.velocity = Vector3.ZERO
	await _seconds(0.4)
	_check(cur.mode == BatCurtain.Mode.SLEEP, "runa apagada e devagar: a Cortina viva não acorda")
	player.rune_on = true
	await _seconds(0.3)
	_check(cur.mode == BatCurtain.Mode.AWAKE, "runa acesa embaixo dela: a cortina se fecha")
	_check(player.external_velocity.length() > 3.0, "e empurra você para fora")
	EventBus.rune_pulsed.emit(player.global_position)
	await _frames(2)
	_check(cur.mode == BatCurtain.Mode.STUNNED, "Pulso Espiral: os morcegos caem atordoados")
	player.rune_on = false

	# A12: a Serpente-cega
	var sp: Serpent = a.serpent
	player.invuln = 999.0
	player.global_position = Vector3(156, 0.1, -7)
	await _seconds(0.5)
	_check(sp.awake, "entrar na arena acorda a Serpente-cega")
	player.global_position = Vector3(147, 0.1, -3)
	player.velocity = Vector3.ZERO
	await _frames(3)
	_check(not sp.feels(player), "parada, ela não te sente")
	var hp_s := sp.hp
	sp.take_damage(20.0, player)
	_check(absf((hp_s - sp.hp) - 6.0) < 0.5, "escamas seguram 70%% do dano (%.1f)" % (hp_s - sp.hp))
	sp.global_position = Vector3(156, 0.3, 0)
	sp.mode = Serpent.Mode.PROWL
	var trap_pos := Vector3(156, 0, -6)
	var trap := WebNetwork.create_trap(trap_pos)
	var caught := false
	for i in 300:
		await get_tree().physics_frame
		player.global_position = Vector3(147, 0.1, -3)
		player.velocity = Vector3.ZERO
		if sp.is_entangled():
			caught = true
			break
	_check(caught, "teia nova vibra, ela dá o bote nela e fica enredada")
	_check(not is_instance_valid(trap) or not WebNetwork.traps.has(trap), "a teia é mordida e some")
	if caught:
		hp_s = sp.hp
		sp.take_damage(20.0, player)
		_check(absf((hp_s - sp.hp) - 20.0) < 0.5, "enredada, as escamas abrem: dano cheio")
	sp.take_damage(9999.0, player)
	await _seconds(0.5)
	_check(GameState.flags.has("a12_serpente"), "a Serpente-cega cai")
	_check(a._plug == null, "o corpo dela sai do poço")
	player.global_position = Vector3(159, 0.1, 18)
	await _seconds(0.3)
	_check(Fx.flat_dist(player.global_position, Vector3(159, 0, 18)) < 1.0, "dá para passar para o Poço de vapor")

	# A13 e A14
	player.invuln = 0.0
	player.hp = player.max_hp
	var vent: Node3D = a._vents[0]
	var burnt := false
	for i in 50:
		player.global_position = vent.global_position + Vector3(0, 0.1, 0)
		await _seconds(0.1)
		if player.hp < player.max_hp:
			burnt = true
			break
	_check(burnt, "jato de vapor queima")
	player.invuln = 999.0
	player.global_position = Vector3(162, 0.1, 55)
	await _seconds(0.5)
	_check(GameState.flags.has("ato2_fim") and a.hud.cinematic, "topo da Rampa quente: Fim do Ato 2")

	# Evoluções: no nível 10 da Cavaleira, escolhe um dos três ramos no casulo
	player.form = Player.Form.CAVALEIRA
	player.level = 9
	player.recompute_stats(true)
	_check(not player.choose_branch(Player.Form.TEIA), "antes do nível 10 não dá para escolher ramo")
	player.level = Player.BRANCH_LEVEL
	_check(player.can_choose_branch() and not player.can_evolve(), "nível 10: o casulo oferece os três ramos")
	_check(player.choose_branch(Player.Form.TEIA) and player.can_evolve(), "escolheu o ramo Teia")
	var coc := WebNetwork.create_cocoon(Vector3(0, 0, 2))
	var cost0 := player.strand_cost()
	var range0 := player.strand_range()
	player._rest(coc)
	_check(player.form == Player.Form.TEIA and player.level == 1, "a muda: Tecelã do Abismo, nível 1")
	_check(player.strand_cost() < cost0 and player.strand_range() > range0 + 2.9, "Tecelã: fio pela metade e +3 m (%.1f m)" % player.strand_range())
	_check(player.max_silk >= 120.0, "Tecelã: 120 de Seda base")
	var d := player.to_dict()
	_check(int(d["form"]) == Player.Form.TEIA, "a forma nova vai para o save")
	for f: int in [Player.Form.LAMINA, Player.Form.RUNA]:
		player.form = Player.Form.CAVALEIRA
		player.level = Player.BRANCH_LEVEL
		player.choose_branch(f)
		player.evolve()
		_check(player.form == f, "ramo %s funciona" % player.form_name())
	_check(player.visibility_mult() < 0.4 and player.sight_radius() >= 8.0, "Arauta da Runa: furtiva e enxerga longe")

	_end()


func _reach(from: Vector3, to: Vector3) -> bool:
	var p: PackedVector3Array = World.nav.path(from, to)
	return p.size() > 0 and Fx.flat_dist(p[p.size() - 1], to) < 2.5


func _side_off(col: Colossus, at: float, dist: float) -> Vector3:
	var a := col.point_at(at - 0.5)
	var b := col.point_at(at + 0.5)
	var t := (b - a).normalized()
	return Vector3(-t.z, 0.0, t.x) * dist


func _end() -> void:
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
