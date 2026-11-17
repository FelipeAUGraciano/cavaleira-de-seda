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
	for seal in [a.SEAL_EAST, a.SEAL_SOUTH]:
		var q: PackedVector3Array = World.nav.path(a.spawn_point, Vector3(seal.x, 0, seal.y) + Vector3(2.5, 0, 0) if seal == a.SEAL_EAST else Vector3(seal.x, 0, seal.y + 2.5))
		_check(q.is_empty() or Fx.flat_dist(q[q.size() - 1], Vector3(seal.x, 0, seal.y)) > 1.2, "desabamento tapa a passagem (%s)" % str(seal))

	# Ossário: besouros
	var beetles: Array = []
	for c in World.creatures:
		if c is Beetle:
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
	_check(a.den.slots.size() == 1, "uma entrada só (a rachadura)")
	var far: float = col.project(Vector3(84, 0, -6)).y
	_check(far > 12.0, "a toca fica longe do caminho do Colosso (%.0f m)" % far)
	_end()


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
