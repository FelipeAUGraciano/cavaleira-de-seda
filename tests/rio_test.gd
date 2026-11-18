extends Node
## Ato 3, Rio de Brasa: chegada (vinda da Rampa quente), caminhos e travas, calor, fios
## queimando sobre a lava, gêiseres, bichos de fogo, Resistência a Fogo e a Salamandra-rainha.
## Rodar:  godot --headless --path . res://tests/rio_test.tscn

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	reparent(get_tree().root)
	get_tree().current_scene = null
	GameState.new_game()
	GameState.delete_save()
	GameState.flags["a12_serpente"] = true
	await _frames(5)
	# da Rampa quente do Abismo até o rio
	get_tree().change_scene_to_file("res://world/layers/abismo.tscn")
	await _seconds(2.0)
	var player: Player = GameState.player
	player.invuln = 999.0
	player.global_position = Vector3(162, 0.1, 55)
	var ls: Node = null
	for i in 60:
		await _seconds(0.1)
		var f := get_tree().get_nodes_in_group("loading_screen")
		if not f.is_empty():
			ls = f[0]
			break
	_check(ls != null and ls.header == "Fim do Ato 2", "topo da Rampa quente: tela 'Fim do Ato 2'")
	var arrived := false
	for i in 150:
		await _seconds(0.1)
		var sc = get_tree().current_scene
		if sc != null and String(sc.scene_file_path).ends_with("rio_brasa.tscn"):
			arrived = true
			break
	_check(arrived, "chega no Rio de Brasa")
	if not arrived:
		return _end()
	var r = get_tree().current_scene
	await _seconds(4.0)
	player = GameState.player
	_check(r.hud._area == "Rio de Brasa", "título 'Rio de Brasa' em cima")
	for i in 60:
		if not player.autopilot:
			break
		await _seconds(0.1)
	player.invuln = 999.0

	# câmaras e caminhos
	for id in ["R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9", "R10", "R11", "R12", "R13", "R14"]:
		_check(World.nav.room_cells.has(id) and not (World.nav.room_cells[id] as Array).is_empty(), "câmara %s existe" % id)
	var R1 := Vector3(2, 0, 18)
	for pair in [[R1, Vector3(33, 0, 4), "Margem → Mirante"], [R1, Vector3(92, 0, 40), "Margem → Forja pela Rota de pedra"],
			[Vector3(92, 0, 40), Vector3(80, 0, 10), "Forja → Câmara fria"], [Vector3(80, 0, 10), Vector3(78, 0, -34), "Câmara fria → Ninho"],
			[Vector3(80, 0, 10), Vector3(166, 0, -30), "Câmara fria → Pântano (gêiseres)"], [Vector3(166, 0, -30), Vector3(188, 0, -56), "Pântano → Cristais de fogo (fresta)"],
			[Vector3(166, 0, -30), Vector3(166, 0, 10), "Pântano → Antecâmara"], [Vector3(166, 0, 10), Vector3(166, 0, 34), "Antecâmara → arena"]]:
		_check(_reach(pair[0], pair[1]), "dá para andar: %s" % pair[2])
	_check(not _reach(Vector3(33, 0, 4), Vector3(66, 0, 8)) or _path_len(Vector3(33, 0, 4), Vector3(66, 0, 8)) > 120.0, "o rio de lava não se atravessa a pé (só pelas ilhas ou pela volta longa)")
	_check(not _reach(Vector3(166, 0, 34), Vector3(166, 0, 60)), "o fosso de lava fecha a saída da arena")

	# bichos
	var kinds := {}
	var total := 0
	for c in World.creatures:
		if is_instance_valid(c) and not c.dead:
			total += 1
			kinds[c.display_name] = int(kinds.get(c.display_name, 0)) + 1
	_check(total >= 50, "rio cheio: %d bichos (%s)" % [total, str(kinds)])
	for nm in ["Peixe-magma", "Verme de lava", "Salamandra-chama", "Golem de basalto", "Besouro-brasa", "Morcego de cinza", "Aranha de cinza", "Salamandra-rainha"]:
		_check(kinds.has(nm), "tem %s" % nm)

	# calor (invulnerável a golpes: só o calor conta)
	player.invuln = 999.0
	player.resist_fire = 0
	player.hp = player.max_hp
	var shore := _shore_point(r)
	player.global_position = shore + Vector3(0, 0.1, 0)
	await _seconds(1.5)
	_check(player.hp < player.max_hp - 1.5 and player.heat_t > 0.0, "perto da lava: calor tira vida (%.1f)" % (player.max_hp - player.hp))
	player.hp = player.max_hp
	player.resist_fire = 4
	await _seconds(1.0)
	_check(player.hp >= player.max_hp - 0.01, "Resistência a Fogo 4: imune ao calor")
	player.resist_fire = 0
	# brasa das ilhas
	player.global_position = Vector3(r.ISLANDS[1].x, 0.1, r.ISLANDS[1].y)
	player.hp = player.max_hp
	await _seconds(1.0)
	_check(player.hp < player.max_hp - 8.0, "brasa das ilhas queima rápido sem Resistência 3")
	player.resist_fire = 3
	player.hp = player.max_hp
	await _seconds(1.0)
	_check(player.hp >= player.max_hp - 0.01, "com Resistência a Fogo 3 anda na brasa")
	player.global_position = Vector3(33, 0.1, 4)
	player.invuln = 999.0

	# fio sobre a lava queima em 8 s
	var wa: WebAnchor = WebNetwork.anchors["R3_ilha0"]
	var wb: WebAnchor = WebNetwork.anchors["R3_ilha1"]
	var st := WebNetwork.create_strand(wa, wb)
	await _seconds(6.0)
	_check(is_instance_valid(st) and WebNetwork.strands.has(st), "o fio sobre a lava aguenta alguns segundos")
	await _seconds(2.6)
	_check(not is_instance_valid(st) or not WebNetwork.strands.has(st), "e queima em 8 s")

	# comer bicho de fogo sobe a Resistência a Fogo
	player.resist_fire = 0
	var sal: FireSalamander = null
	for c in World.creatures:
		if c is FireSalamander and not (c is QueenSalamander):
			sal = c
			break
	if sal != null:
		sal.take_damage(9999.0, player)
		await _seconds(0.3)
		var corpse: Corpse = null
		for c in get_tree().get_nodes_in_group("corpse"):
			if (c as Corpse).display_name == "Salamandra-chama":
				corpse = c
		if corpse != null:
			player._eat(corpse)
		_check(player.resist_fire == 1, "comer salamandra: Resistência a Fogo 1")

	# peixe-magma salta da lava
	var fish: MagmaFish = null
	for c in World.creatures:
		if c is MagmaFish:
			fish = c
			break
	if fish != null:
		_check(fish.mode == LavaLurker.Mode.HIDDEN, "o peixe-magma fica escondido na lava")
		var hp_f := fish.hp
		fish.take_damage(50.0, player)
		_check(fish.hp == hp_f, "embaixo da lava não dá para acertar")
		var land := _floor_near(r, fish.global_position)
		player.global_position = land + Vector3(0, 0.1, 0)
		player.velocity = Vector3.ZERO
		var out := false
		for i in 40:
			await _seconds(0.1)
			if fish.mode != LavaLurker.Mode.HIDDEN:
				out = true
				break
		_check(out, "chegou na beirada: o peixe salta")

	# gêiser arremessa
	player.invuln = 0.0
	player.hp = player.max_hp
	player.resist_fire = 0
	var g: Node3D = r._geysers[0]
	var thrown := false
	for i in 60:
		player.global_position = g.global_position + Vector3(0.4, 0.1, 0)
		await _seconds(0.1)
		if player.hp < player.max_hp:
			thrown = true
			break
	_check(thrown, "o gêiser estoura e arremessa")
	player.invuln = 999.0

	# golem dorme até alguém correr perto
	var golem: BasaltGolem = null
	for c in World.creatures:
		if c is BasaltGolem:
			golem = c
			break
	if golem != null:
		_check(golem.mode == BasaltGolem.Mode.DORMANT, "golem dorme parado")
		player.global_position = golem.global_position + Vector3(5.0, 0.1, 0)
		player.velocity = Vector3.ZERO
		await _seconds(0.5)
		_check(golem.mode == BasaltGolem.Mode.DORMANT, "parada a 5 m, ele não acorda")
		golem.take_damage(5.0, player)
		_check(golem.mode == BasaltGolem.Mode.AWAKE, "apanhou: acorda")

	# a rainha: onda de fogo queima as teias; depois esfria
	var q: QueenSalamander = r.queen
	player.global_position = Vector3(166, 0.1, 26)
	await _seconds(0.5)
	_check(q.awake, "entrar na arena acorda a Salamandra-rainha")
	var a12: WebAnchor = WebNetwork.anchors["R12_0"]
	var b12: WebAnchor = WebNetwork.anchors["R12_1"]
	var s12 := WebNetwork.create_strand(a12, b12)
	var t12 := WebNetwork.create_trap(Vector3(160, 0, 36))
	var hp_q := q.hp
	q.take_damage(20.0, player)
	_check(absf((hp_q - q.hp) - 10.0) < 0.5, "pele de brasa: metade do dano")
	q._wave_t = 0.0
	var cooled := false
	for i in 120:
		await _seconds(0.05)
		player.global_position = Vector3(166, 0.1, 26)
		if q.is_cooling():
			cooled = true
			break
	_check((not is_instance_valid(s12) or not WebNetwork.strands.has(s12)) and (not is_instance_valid(t12) or not WebNetwork.traps.has(t12)), "a onda de fogo queima fios e teias da arena")
	_check(cooled, "depois da onda a pele esfria")
	hp_q = q.hp
	q.take_damage(20.0, player)
	_check(absf((hp_q - q.hp) - 20.0) < 0.5, "esfriada: dano cheio")
	q.take_damage(99999.0, player)
	await _seconds(0.5)
	_check(GameState.flags.has("r12_rainha"), "a rainha cai")
	await _seconds(3.0)
	player.global_position = Vector3(166, 0.1, 49.5)
	await _seconds(0.4)
	_check(Fx.flat_dist(player.global_position, Vector3(166, 0, 49.5)) < 1.2, "sem ela a lava esfria e o caminho abre")

	# fim do ato
	player.global_position = Vector3(188, 0.1, 74)
	await _seconds(0.5)
	_check(GameState.flags.has("ato3_fim") and r.hud.cinematic, "Chaminé: Fim do Ato 3")
	_end()


func _shore_point(r) -> Vector3:
	for x in range(30, 45):
		var q := Vector2(x, 4)
		if r.cave.is_floor(q, 0.3) and r.is_lava(q + Vector2(2.0, 0)):
			return Vector3(q.x, 0, q.y)
	return Vector3(39, 0, 5)


func _floor_near(r, p: Vector3) -> Vector3:
	for rr in range(1, 8):
		for k in 16:
			var q := Vector2(p.x, p.z) + Vector2(cos(k * TAU / 16.0), sin(k * TAU / 16.0)) * rr
			if r.cave.is_floor(q, 0.4):
				return Vector3(q.x, 0, q.y)
	return p


func _reach(from: Vector3, to: Vector3) -> bool:
	var p: PackedVector3Array = World.nav.path(from, to)
	return p.size() > 0 and Fx.flat_dist(p[p.size() - 1], to) < 2.5


func _path_len(from: Vector3, to: Vector3) -> float:
	var p: PackedVector3Array = World.nav.path(from, to)
	var l := 0.0
	for i in range(1, p.size()):
		l += p[i].distance_to(p[i - 1])
	return l


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
