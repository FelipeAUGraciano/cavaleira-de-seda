extends Node
## Última muda: cada ramo se divide em dois (nível 10 do ramo) e as formas raras pedem
## resistências e materiais. Testa a escolha, a muda, o save e a marca de cada forma.
## Rodar:  godot --headless --path . res://tests/evolucao_test.tscn

var player: Player
var layer
var failures := 0


func _ready() -> void:
	GameState.permadeath = false
	GameState.delete_save()
	layer = load("res://world/layers/test_chamber.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	for c in World.creatures.duplicate():
		c.queue_free()
	await _frames(2)
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _spawn(cls, at: Vector3) -> Creature:
	var c: Creature = cls.new()
	c.position = at
	layer.ecosystem.add_child(c)
	return c


func _become(f: int) -> void:
	player.form = f as Player.Form
	player.pending_form = -1
	player.level = 1
	player.recompute_stats(true)
	player._apply_form_visual()
	player.shield = float(player.fd("shield", 0.0))
	player.invuln = 0.0


func _clear() -> void:
	for c in World.creatures.duplicate():
		if is_instance_valid(c):
			c.queue_free()
	await _frames(2)


func _run() -> void:
	var base := Vector3(-14, 0.1, 8)
	player.global_position = base
	player.using_stick_aim = true
	player.aim_dir = Vector3(1, 0, 0)
	await _frames(5)

	# ---- escolha da última muda
	_become(Player.Form.LAMINA)
	player.level = 9
	_check(not player.can_choose_final() and not player.choose_branch(Player.Form.EXECUTORA), "antes do nível 10 do ramo não tem última muda")
	player.level = Player.FINAL_LEVEL
	var opts := player.next_options()
	_check(opts.size() == 7 and opts[0] == Player.Form.EXECUTORA and opts[1] == Player.Form.BASTIA, "Ceifadora: Executora ou Bastiã + 5 raras")
	_check(not player.choose_branch(Player.Form.SENHORA), "não dá para pegar a forma de outro ramo")
	_check(not player.choose_branch(Player.Form.ARDENTE), "rara sem requisito não dá")
	_check(player.choose_branch(Player.Form.BASTIA) and player.can_evolve(), "escolheu a Bastiã de Pedra")
	var coc := WebNetwork.create_cocoon(base + Vector3(0, 0, 3))
	var sp0 := player.skill_points
	player._rest(coc)
	_check(player.form == Player.Form.BASTIA and player.level == 1 and player.is_final(), "a muda: Bastiã de Pedra, nível 1")
	_check(player.max_hp >= 280.0 and player.skill_points == sp0, "Bastiã: 280 PV base, pontos ficam")
	_check(not player.can_choose_final() and player.next_options().is_empty(), "depois da última muda não há outra")
	var d := player.to_dict()
	_check(int(d["form"]) == Player.Form.BASTIA, "a forma final vai para o save")
	for pair in [[Player.Form.TEIA, Player.Form.SALTADORA], [Player.Form.RUNA, Player.Form.TEMPESTADE], [Player.Form.TEIA, Player.Form.SENHORA], [Player.Form.RUNA, Player.Form.VIDENTE], [Player.Form.LAMINA, Player.Form.EXECUTORA]]:
		_become(pair[0])
		player.level = Player.FINAL_LEVEL
		_check(player.choose_branch(pair[1]), "%s -> %s" % [Player.FORMS[pair[0]]["name"], Player.FORMS[pair[1]]["name"]])
		player.evolve()
		_check(player.form == pair[1] and player._mark != null, "%s tem marca no corpo" % player.form_name())

	# ---- requisitos das raras
	_become(Player.Form.RUNA)
	player.level = Player.FINAL_LEVEL
	player.resist_fire = 5
	_check(not player.rare_ready(Player.Form.ARDENTE), "Ardente: Fogo 5 sem o Cristal de fogo não basta")
	GameState.flags["material_cristal_fogo"] = true
	_check(player.rare_ready(Player.Form.ARDENTE), "Ardente: Fogo 5 + Cristal de fogo")
	player.dark_sight = 1.5
	player.resist_rot = 3
	_check(player.rare_ready(Player.Form.BREU), "Breu: pérola negra + Podridão 3")
	player.resist_poison = 4
	_check(player.rare_ready(Player.Form.VIUVA), "Viúva: Veneno 4")
	player.resist_acid = 4
	_check(not player.rare_ready(Player.Form.CORROSIVA), "Corrosiva: Ácido 4 ainda não")
	player.resist_acid = 5
	_check(player.rare_ready(Player.Form.CORROSIVA), "Corrosiva: Ácido 5")
	player.crystal_skin = true
	var pk := Pickup.new("cristal_pv", "")
	layer.add_child(pk)
	pk.global_position = player.global_position + Vector3(0, 0, 9)
	await _frames(2)
	pk._on_body_entered(player)
	_check(player.moonstones == 1, "pegar pedra-da-lua conta (%d)" % player.moonstones)
	player.moonstones = Player.MOONSTONES_NEEDED - 1
	_check(not player.rare_ready(Player.Form.LUA), "Pedra-da-lua: faltando cristal")
	player.moonstones = Player.MOONSTONES_NEEDED
	_check(player.rare_ready(Player.Form.LUA) and player.choose_branch(Player.Form.LUA), "Pedra-da-lua: Pele de Cristal + 4 cristais; escolheu")
	player.evolve()
	_check(player.form == Player.Form.LUA and player.shield >= 50.0, "Cavaleira de Pedra-da-lua com escudo de 50")
	var d2 := player.to_dict()
	_check(int(d2.get("moonstones", -1)) == Player.MOONSTONES_NEEDED, "cristais de pedra-da-lua vão para o save")

	# ---- mecânicas
	var beetle: Creature
	# Pedra-da-lua: o escudo absorve e volta
	var hp0 := player.hp
	player.take_damage(30.0, null)
	_check(is_equal_approx(player.hp, hp0) and player.shield < 50.0, "escudo absorve o golpe (escudo %d)" % int(player.shield))
	player.invuln = 0.0
	player.take_damage(60.0, null)
	_check(player.shield <= 0.0 and player.hp < hp0, "escudo quebra e o resto passa")
	await _seconds(7.5)
	_check(player.shield > 20.0, "escudo volta depois de 6 s (%d)" % int(player.shield))

	# Executora: execução e cura no abate
	_become(Player.Form.EXECUTORA)
	beetle = _spawn(Beetle, base + Vector3(1.6, 0.2, 0))
	await _frames(5)
	beetle.asleep = true
	beetle.hp = beetle.max_hp * 0.3
	player.hp = player.max_hp * 0.5
	var hpe := player.hp
	player._melee(1.0, 3.0, 360.0, false, Vector3(1, 0, 0))
	await _frames(2)
	_check(not is_instance_valid(beetle) or beetle.dead, "Executora: golpe fraco em bicho com pouca vida executa")
	_check(player.hp > hpe, "Executora: abate cura")
	await _clear()

	# Bastiã: espinhos e nada empurra
	_become(Player.Form.BASTIA)
	beetle = _spawn(Beetle, base + Vector3(1.6, 0.2, 0))
	await _frames(5)
	var bh := beetle.hp
	player.external_velocity = Vector3.ZERO
	player.take_damage(10.0, beetle)
	_check(beetle.hp < bh, "Bastiã: espinhos devolvem dano (%.1f)" % (bh - beetle.hp))
	_check(player.external_velocity.length() < 0.1, "Bastiã: golpe não empurra")
	await _clear()

	# Senhora: teia segura bicho M o tempo todo e cabe mais
	_become(Player.Form.SENHORA)
	var trap := WebNetwork.create_trap(base + Vector3(4, 0, 0))
	await _frames(3)
	_check(trap.capacity == 6, "Senhora: teia de captura aguenta 6")
	var sc := _spawn(Scorpion, base + Vector3(4, 0.2, 0))
	await _frames(3)
	trap._on_body_entered(sc)
	_check(sc.entangled_time >= 5.5, "Senhora: escorpião (M) preso por %.1f s" % sc.entangled_time)
	await _clear()
	if is_instance_valid(trap):
		trap._remove()

	# Saltadora: mergulho no fim do fio lançado
	_become(Player.Form.SALTADORA)
	beetle = _spawn(Beetle, base + Vector3(0.8, 0.2, 0.5))
	await _frames(5)
	var bh2 := beetle.hp
	player._zip_total = 6.0
	player._zip_land()
	_check(beetle.hp < bh2 or beetle.dead, "Saltadora: mergulho acerta quem está perto")
	_check(player.fd("dodge_cost", 1.0) == 0.5 and player.strand_range() >= Player.STRAND_RANGE + 7.0, "Saltadora: esquiva barata e fio +7 m")
	await _clear()

	# Vidente: marca bichos atrás das paredes
	_become(Player.Form.VIDENTE)
	beetle = _spawn(Beetle, base + Vector3(10, 0.2, 0))
	await _seconds(0.5)
	var shown := 0
	for m in player._reveal_marks:
		if is_instance_valid(m) and m.visible:
			shown += 1
	_check(shown >= 1, "Vidente: bicho a 10 m marcado (%d)" % shown)
	await _clear()

	# Tempestade: pulso machuca e alcança longe
	_become(Player.Form.TEMPESTADE)
	beetle = _spawn(Beetle, base + Vector3(7.5, 0.2, 0))
	await _frames(5)
	beetle.max_hp = 999.0
	beetle.hp = 999.0
	var bh3 := beetle.hp
	player.rune_on = false
	player.energy = player.max_energy
	player._toggle_rune()
	await _frames(2)
	_check(beetle.hp < bh3 and beetle.is_entangled(), "Tempestade: pulso a 7,5 m acerta e atordoa")
	await _clear()

	# Ardente: imune a fogo, fios não queimam, golpe incendeia
	_become(Player.Form.ARDENTE)
	player.apply_burn(3.0)
	player.apply_heat(10.0, 1.0, true)
	_check(player.burn_t <= 0.0 and is_equal_approx(player.hp, player.max_hp), "Ardente: não queima nem sente calor")
	var anchors := get_tree().get_nodes_in_group("anchor")
	var st: WebStrand = null
	if anchors.size() >= 2:
		st = WebNetwork.create_strand(anchors[0], anchors[1])
	_check(st != null and not WebNetwork.burn_strand(st) and is_instance_valid(st), "Ardente: fio não pega fogo")
	beetle = _spawn(Beetle, base + Vector3(1.6, 0.2, 0))
	await _frames(5)
	beetle.max_hp = 999.0
	beetle.hp = 999.0
	player._melee(1.0, 3.0, 360.0, false, Vector3(1, 0, 0))
	_check(beetle.burn_time > 2.0, "Ardente: golpe incendeia")
	var fb := _spawn(EmberBeetle, base + Vector3(1.6, 0.2, 1.0))
	await _frames(3)
	fb.ignite(3.0)
	_check(fb.burn_time <= 0.0, "bicho de fogo não pega fogo")
	await _clear()
	_become(Player.Form.TEIA)
	_check(st != null and WebNetwork.burn_strand(st), "outras formas: o fio queima")

	# Breu: parada no escuro some; emboscada
	_become(Player.Form.BREU)
	player.rune_on = false
	player.velocity = Vector3.ZERO
	_check(player.visibility_mult() == 0.0, "Breu: parada de runa apagada, invisível")
	beetle = _spawn(Beetle, base + Vector3(1.6, 0.2, 0))
	await _frames(5)
	beetle.max_hp = 999.0
	beetle.hp = 999.0
	beetle.noticed_player = false
	player._melee(10.0, 3.0, 360.0, false, Vector3(1, 0, 0))
	_check(beetle.hp <= 999.0 - 24.0, "Breu: emboscada dá 2,5x (%.0f)" % (999.0 - beetle.hp))
	await _clear()

	# Viúva: veneno por golpe, imune
	_become(Player.Form.VIUVA)
	player.apply_poison(5.0)
	_check(player.poison_t <= 0.0, "Viúva: imune a veneno")
	beetle = _spawn(Beetle, base + Vector3(1.6, 0.2, 0))
	await _frames(5)
	beetle.max_hp = 999.0
	beetle.hp = 999.0
	player._melee(1.0, 3.0, 360.0, false, Vector3(1, 0, 0))
	_check(beetle.poison_stacks >= 2, "Viúva: golpe envenena (%d doses)" % beetle.poison_stacks)
	await _clear()

	# Corrosiva: corrói (+40%), imune a ácido
	_become(Player.Form.CORROSIVA)
	var hpc := player.hp
	player.apply_acid(20.0)
	_check(is_equal_approx(player.hp, hpc), "Corrosiva: imune a ácido")
	beetle = _spawn(Beetle, base + Vector3(1.6, 0.2, 0))
	await _frames(5)
	beetle.max_hp = 999.0
	beetle.hp = 999.0
	player._melee(10.0, 3.0, 360.0, false, Vector3(1, 0, 0))
	var h1 := 999.0 - beetle.hp
	_check(beetle.corrode_time > 4.0 and h1 >= 13.9, "Corrosiva: o primeiro golpe já corrói (%.1f)" % h1)
	await _clear()

	# o menu do casulo abre na aba Evolução quando a última muda está pronta
	_become(Player.Form.LAMINA)
	player.level = Player.FINAL_LEVEL
	_check(player.can_choose_final() and player.pending_form < 0, "pronta para escolher a última muda")
	_check(player.branch_name() == "Lâmina", "nome do ramo para os finais")


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
