extends Node
## Teste da segunda metade das Galerias (G8–G15) e da Centopeia-blindada.
## Rodar:  godot --headless --path . res://tests/covil_test.tscn

var layer
var player: Player
var failures := 0


func _ready() -> void:
	GameState.delete_save()
	GameState.said = {}
	GameState.flags = {}
	layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _run() -> void:
	# Caminhos novos
	var routes := {
		"G8→G9→G13": [Vector2(138, 40), Vector2(150, 44), Vector2(161, 47), Vector2(173, 44), Vector2(182, 44), Vector2(176, 52), Vector2(160, 63), Vector2(141, 72), Vector2(135, 77)],
		"G13→G14→G15": [Vector2(135, 77), Vector2(136, 92), Vector2(135, 112), Vector2(158, 111), Vector2(170, 110)],
		"G5→G11→G13": [Vector2(44, 72), Vector2(54, 74), Vector2(64, 78), Vector2(80, 82), Vector2(96, 80), Vector2(112, 83), Vector2(128, 78), Vector2(135, 77)],
		"G5→G12": [Vector2(44, 72), Vector2(44, 81), Vector2(43, 94), Vector2(43, 104)],
		"fresta G8→G10": [Vector2(150, 39), Vector2(160, 37), Vector2(165, 31), Vector2(167, 17), Vector2(168, 13)],
	}
	for r in routes:
		_check(_walkable(routes[r]), "caminho %s" % r)
	_check(not layer.cave.is_floor(Vector2(138, 26.5)), "abismo separa a Galeria do eco da borda dos aventureiros")
	var nest := get_tree().get_nodes_in_group("creature").filter(func(c): return c is Lizard and c.has_meta("nest_id"))
	_check(nest.size() == 3, "três lagartos no Ninho (G12)")

	# G8: aventureiros passam do outro lado do abismo e somem
	_teleport(Vector3(136.0, 0.1, 42.0))
	await _seconds(3.0)
	_check(get_tree().get_nodes_in_group("adventurer").size() == 3, "três aventureiros aparecem na Galeria do eco")
	var far := true
	for a in get_tree().get_nodes_in_group("adventurer"):
		if (a as Node3D).global_position.z > 24.0:
			far = false
	_check(far, "eles andam pela borda do outro lado do abismo")
	await _seconds(24.0)
	_check(get_tree().get_nodes_in_group("adventurer").is_empty(), "e vão embora")

	# G9: fogo queima fio; anotações
	_teleport(Vector3(182.0, 0.1, 42.0))
	var n0: int = WebNetwork.strands.size()
	WebNetwork.create_strand(WebNetwork.anchors["G9_a"], WebNetwork.anchors["G9_b"])
	await _seconds(1.0)
	_check(WebNetwork.strands.size() == n0, "tocha queima o fio esticado perto dela")
	_teleport(Vector3(183.5, 0.1, 45.6))
	await _frames(3)
	for i in 3:
		player._interact()
		await _frames(2)
	_check(GameState.flags.has("g9_diario"), "ler as 3 páginas do diário (E)")

	# Ácido: resistência por comer sapo
	player.resist_acid = 0
	player.hp = player.max_hp
	_teleport(Vector3(115.0, 0.1, 80.0))
	await _seconds(1.0)
	_check(player.hp < player.max_hp, "sem resistência, o ácido queima")
	var frog := Frog.new()
	frog.position = Vector3(100.0, 0.3, 80.0)
	layer.ecosystem.add_child(frog)
	await _frames(3)
	frog.take_damage(999.0, player)
	await _frames(3)
	var fc: Corpse = null
	for c in get_tree().get_nodes_in_group("corpse"):
		if (c as Corpse).acid_bonus > 0:
			fc = c
	if fc != null:
		player._eat(fc)
	_check(player.resist_acid == 1, "comer Sapo-de-rocha dá Resistência a Ácido 1")
	player.resist_acid = 3
	player.hp = player.max_hp
	await _seconds(1.0)
	_check(is_equal_approx(player.hp, player.max_hp), "com Resistência a Ácido 3 dá para atravessar")

	# G14: a luta
	var boss: Centipede = layer.centipede
	_check(boss != null and boss.mode == Centipede.Mode.SLEEP, "Centopeia dormindo antes da luta")
	_check(layer._door_out != null, "saída para a Borda da Fenda fechada")
	_teleport(Vector3(135.0, 0.1, 103.0))
	await _seconds(0.5)
	_check(layer.fight and layer._door_in != null and boss.mode != Centipede.Mode.SLEEP, "entrar no covil acorda a Centopeia e fecha a porta")

	# Vibração
	_teleport(Vector3(boss.global_position.x - 8.0, 0.1, boss.global_position.z))
	player.on_strand = false
	player.velocity = Vector3(5.0, 0, 0)
	_check(boss.feels(player), "andando no chão a 8 m: ela sente")
	player.velocity = Vector3.ZERO
	_check(not boss.feels(player), "parada: ela não sente")
	player.velocity = Vector3(5.0, 0, 0)
	player.on_strand = true
	_check(not boss.feels(player), "sobre um fio: ela não sente")
	player.on_strand = false
	player.velocity = Vector3.ZERO

	# Carapaça
	var hp0 := boss.hp
	boss.take_damage(100.0, player)
	_check(absf((hp0 - boss.hp) - 10.0) < 0.1, "carapaça segura 90%% do dano (%.0f)" % (hp0 - boss.hp))
	boss.add_poison()
	_check(boss.poison_stacks == 0, "veneno não atravessa a carapaça")

	# Morrer na luta reinicia a Centopeia e reabre a porta
	player.hp = 1.0
	player.take_damage(50.0, null, false)
	await _seconds(0.3)
	_check(not layer.fight and layer._door_in == null, "morrer reabre a porta do covil")
	_check(boss.mode == Centipede.Mode.SLEEP and is_equal_approx(boss.hp, boss.max_hp), "e a Centopeia volta a dormir com a vida cheia")
	await _seconds(3.5)

	# Investida através de um fio = enredada
	_teleport(Vector3(135.0, 0.1, 103.0))
	await _seconds(0.3)
	_teleport(Vector3(122.0, 0.1, 118.0))   # longe e parada: ela não sente
	player.velocity = Vector3.ZERO
	boss.global_position = Vector3(layer.ARENA.x - 6.0, 0.05, layer.ARENA.z)
	boss.velocity = Vector3.ZERO
	boss.facing = Vector3(1, 0, 0)
	boss._reset_trail()
	var s := WebNetwork.create_strand(WebNetwork.anchors["G14_0"], WebNetwork.anchors["G14_7"])
	boss.memory = 0.0
	boss.mode = Centipede.Mode.WINDUP
	boss.mode_time = 0.79
	var tangled := false
	for i in 30:
		await _frames(5)
		if boss.is_entangled():
			tangled = true
			break
	_check(tangled, "investida através do fio: Centopeia enredada")
	_check(not is_instance_valid(s) or not WebNetwork.strands.has(s), "o fio arrebenta")
	hp0 = boss.hp
	boss.take_damage(50.0, player)
	_check(absf((hp0 - boss.hp) - 50.0) < 0.1, "enredada, a carapaça cede (dano cheio)")
	boss.take_damage(150.0, player)
	_check(boss.phase == 2, "na metade da vida ela se enfurece")

	# Vitória
	boss.take_damage(9999.0, player)
	await _frames(5)
	_check(GameState.flags.has("g14_centopeia") and layer._door_out == null and layer._door_in == null, "vitória abre o caminho para a Borda da Fenda")
	var skin: Corpse = null
	for c in get_tree().get_nodes_in_group("corpse"):
		if (c as Corpse).skin_bonus:
			skin = c
	_check(skin != null, "a carapaça fica para comer")
	if skin != null:
		player._eat(skin)
	_check(player.crystal_skin, "comer a carapaça dá Pele de Cristal")
	player.hp = player.max_hp
	player.take_damage(10.0, null, false)
	_check(absf(player.hp - (player.max_hp - 8.0)) < 0.1, "Pele de Cristal reduz o dano em 20%")

	# G15: o chão cede (o teste para antes de trocar de cena)
	_teleport(Vector3(169.0, 0.1, 110.0))
	await _seconds(3.0)
	_check(GameState.flags.has("ato1_fim"), "na Borda da Fenda o chão cede: fim do Ato 1")


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
