extends Node
## Ataques próprios dos ramos e das formas finais (kits): cada golpe e mordida novos fazem
## o que dizem, e o estilo A/B troca no casulo e vai para o save.
## Rodar:  godot --headless --path . res://tests/kits_test.tscn

var player: Player
var layer
var failures := 0
var base := Vector3(-14, 0.1, 8)


func _ready() -> void:
	GameState.permadeath = false
	GameState.delete_save()
	layer = load("res://world/layers/test_chamber.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	await _clear()
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _become(f: int, style := 0) -> void:
	await _clear()
	_release_all()
	player.attack_style = style
	player.form = f as Player.Form
	player.level = 5
	player.recompute_stats(true)
	player._apply_form_visual()
	player.shield = float(player.fd("shield", 0.0))
	player.global_position = base
	player.velocity = Vector3.ZERO
	player.aim_dir = Vector3(1, 0, 0)
	player.using_stick_aim = true
	player.aim_point = base + Vector3(5, 0, 0)
	player.rune_on = true
	player.invuln = 0.0
	player._start_state(Player.State.NORMAL)
	await _frames(3)


func _dummy(off: Vector3, hp := 999.0, cls = Beetle) -> Creature:
	var c: Creature = cls.new()
	c.position = base + off + Vector3(0, 0.2, 0)
	layer.ecosystem.add_child(c)
	await _frames(3)
	c.max_hp = hp
	c.hp = hp
	c.asleep = true
	c._strike_cd = 99.0
	c.speed = 0.0   # boneco: não foge nem persegue
	return c


func _clear() -> void:
	for c in World.creatures.duplicate():
		if is_instance_valid(c):
			c.queue_free()
	for k in World.corpses.duplicate():
		if is_instance_valid(k):
			k.queue_free()
	await _frames(2)


func _release_all() -> void:
	Input.action_release("attack")
	Input.action_release("bite")


func _use(slot: int, hold := 0.0) -> void:
	## Aperta o botão (golpe 0, mordida 1), segura "hold" segundos e espera o movimento acabar.
	var act := "attack" if slot == 0 else "bite"
	player.aim_dir = player.aim_dir.normalized()
	if hold > 0.0:
		Input.action_press(act)
		await get_tree().physics_frame
	player.kit.press(slot)
	if hold > 0.0:
		await _seconds(hold)
		Input.action_release(act)
	for i in 120:
		if not player.kit.busy():
			break
		await get_tree().physics_frame
	await _frames(2)


func _run() -> void:
	# ---- ramos
	await _become(Player.Form.LAMINA)
	_check(player.kit != null and player.kit.names[0] == "Foice", "Ceifadora tem kit próprio (Foice)")
	var b := await _dummy(Vector3(3.4, 0, 0))
	await _use(0)
	await _use(0)
	var h0 := b.hp
	await _use(0)
	_check(b.hp < h0, "Ceifadora: o 3º corte em linha alcança 3,4 m")
	b = await _dummy(Vector3(0, 0, 3.0))
	player.aim_dir = Vector3(0, 0, 1)
	await _use(1)
	_check(b.hp < 999.0, "Ceifadora: bote longo alcança 3 m")

	await _become(Player.Form.TEIA)
	b = await _dummy(Vector3(2.6, 0, 0))
	for k in 3:
		await _use(0)
	_check(b.slow_time > 0.0, "Tecelã: 3 chicotadas deixam lento")
	b.slow_time = 0.0
	await _use(1)
	await _seconds(0.4)
	_check(b.slow_time > 0.0, "Tecelã: novelo gruda")

	await _become(Player.Form.RUNA)
	b = await _dummy(Vector3(5.0, 0, 0))
	var e0 := player.energy
	await _use(0)
	_check(b.hp < 999.0 and player.energy < e0, "Arauta: faísca a 5 m gasta energia")
	b.position = base + Vector3(2.5, 0.2, 0)
	await _frames(2)
	await _use(1)
	_check(b.is_entangled(), "Arauta: lampejo atordoa")

	# ---- Executora
	await _become(Player.Form.EXECUTORA, 0)
	b = await _dummy(Vector3(1.5, 0, 0))
	for k in 3:
		await _use(0)
	_check(player.kit.stack >= 2, "Frenesi: acertos seguidos acumulam (%d)" % player.kit.stack)
	b.hp = 999.0 * 0.3
	b.position = base + Vector3(4.2, 0.2, 0)
	await _frames(2)
	await _use(1)
	_check(not is_instance_valid(b) or b.dead, "Degola: bicho com 30% da vida a 4 m morre")

	await _become(Player.Form.EXECUTORA, 1)
	b = await _dummy(Vector3(5.4, 0, 0))
	await _use(0, 1.3)
	_check(999.0 - b.hp >= 50.0, "Foices gêmeas: corte carregado alcança 5,4 m (%.0f)" % (999.0 - b.hp))
	b.position = base + Vector3(2.5, 0.2, 0)
	b.hp = 999.0
	b.entangle_raw(1.0)
	await _frames(2)
	await _use(1, 1.2)
	_check(999.0 - b.hp >= 30.0, "Misericórdia: segura e golpeia o preso (%.0f)" % (999.0 - b.hp))

	# ---- Bastiã
	await _become(Player.Form.BASTIA, 0)
	b = await _dummy(Vector3(1.9, 0, 0))
	await _use(0)
	_check(999.0 - b.hp >= 40.0 and b.corrode_time > 0.0, "Martelo: pancada pesada e quebra a casca")
	b.position = base + Vector3(2.0, 0.2, 0)
	b.hp = 999.0
	await _frames(2)
	var x0 := b.global_position.x
	await _use(1)
	_check(b.hp < 999.0 and b.global_position.x > x0 + 1.0, "Investida de ombro: acerta e empurra")

	await _become(Player.Form.BASTIA, 1)
	b = await _dummy(Vector3(1.5, 0, 0))
	Input.action_press("attack")
	player.kit.press(0)
	await _seconds(0.4)
	var hp_p := player.hp
	var took := player.take_damage(20.0, b)
	_check(not took and is_equal_approx(player.hp, hp_p) and b.hp < 999.0, "Muralha: bloqueia de frente e devolve")
	Input.action_release("attack")
	await _seconds(0.2)
	b.position = base + Vector3(-3.3, 0.2, 0)
	b.hp = 999.0
	await _frames(2)
	await _use(1)
	_check(b.hp < 999.0 and b.is_entangled(), "Pisão: onda de 4 m em volta derruba")

	# ---- Senhora
	await _become(Player.Form.SENHORA, 0)
	b = await _dummy(Vector3(3.2, 0, 0))
	for k in 3:
		await _use(0)
	_check(b.is_entangled(), "Chicote de guerra: 3 acertos prendem")
	b.position = base + Vector3(1.4, 0.2, 0)
	await _frames(2)
	var bag0 := player.bag.size()
	await _use(1)
	await _frames(3)
	_check(player.bag.size() == bag0 + 1, "Casulo rápido: embrulha o preso direto na bolsa")

	await _become(Player.Form.SENHORA, 1)
	var traps0 := WebNetwork.traps.size()
	player.aim_point = base + Vector3(5, 0, 0)
	await _use(0)
	await _seconds(0.6)
	_check(WebNetwork.traps.size() == traps0 + 1, "Rede viva: o novelo vira teia de captura")
	b = await _dummy(Vector3(-8.0, 0, 0))
	b.entangle_raw(3.0)
	player.aim_dir = Vector3(1, 0, 0)
	await _use(1)
	await _seconds(0.4)
	_check(Fx.flat_dist(b.global_position, player.global_position) < 4.0, "Puxar a rede: traz o preso (%.1f m)" % Fx.flat_dist(b.global_position, player.global_position))
	for t in WebNetwork.traps.duplicate():
		if is_instance_valid(t) and t.has_meta("temp"):
			t._remove()

	# ---- Saltadora
	await _become(Player.Form.SALTADORA, 0)
	b = await _dummy(Vector3(2.2, 0, 2.2))
	var b2 := await _dummy(Vector3(2.2, 0, -2.2))
	await _use(0)
	_check(b.hp < 999.0 or b2.hp < 999.0, "Pêndulo: gira em volta do ponto e acerta no arco")
	await _become(Player.Form.SALTADORA, 0)
	b = await _dummy(Vector3(4.5, 0, 0))
	player.aim_point = base + Vector3(4.5, 0, 0)
	var px := player.global_position.x
	await _use(1)
	_check(player.global_position.x > px + 3.0 and b.hp < 999.0, "Bote aéreo: pula %.1f m e cai mordendo" % (player.global_position.x - px))
	_check(not player.leaping and player.collision_mask == (1 | 4 | 8), "Bote aéreo: volta ao chão normal")

	await _become(Player.Form.SALTADORA, 1)
	b = await _dummy(Vector3(6.0, 0, 0))
	await _use(0)
	await _seconds(0.4)
	_check(b.hp < 999.0 and b.slow_time > 0.0, "Ricochete: dardos a 6 m")
	b.position = base + Vector3(3.0, 0.2, 0)
	b.hp = 999.0
	await _frames(2)
	await _use(1)
	_check(b.hp < 999.0 and Fx.flat_dist(player.global_position, base) < 1.2, "Bate e volta: crava e volta (%.1f m)" % Fx.flat_dist(player.global_position, base))

	# ---- Vidente
	await _become(Player.Form.VIDENTE, 0)
	b = await _dummy(Vector3(2.0, 0, 0))
	b.facing = Vector3(-1, 0, 0)
	player.kit._rot = 99.0
	player.kit.weak[b] = 0.0   # o ponto fraco virado para ela
	await _use(0)
	_check(999.0 - b.hp >= 47.0 and b.is_entangled(), "Ponto fraco: 3x e atordoa (%.0f)" % (999.0 - b.hp))
	b.entangled_time = 0.0
	b.hp = 999.0
	player.energy = player.max_energy
	await _use(1)
	_check(player.kit.marked == b, "Leitura: marca o bicho")
	player.kit.weak[b] = PI
	await _use(0)
	_check(999.0 - b.hp >= 31.0, "Leitura: golpe no marcado é crítico (%.0f)" % (999.0 - b.hp))

	await _become(Player.Form.VIDENTE, 1)
	b = await _dummy(Vector3(1.4, 0, 0))
	player.kit.press(0)
	await _frames(3)
	var took2 := player.take_damage(25.0, b)
	_check(not took2 and 999.0 - b.hp >= 30.0, "Antecipação: desvia e devolve")
	await _seconds(0.6)
	b.position = base + Vector3(5.0, 0.2, 0)
	await _frames(2)
	player.energy = player.max_energy
	await _use(1)
	_check(b.fear_time > 0.0, "Olhar da runa: o bicho foge de medo")

	# ---- Tempestade
	await _become(Player.Form.TEMPESTADE, 0)
	b = await _dummy(Vector3(7.0, 0, 0))
	b2 = await _dummy(Vector3(7.0, 0, 3.0))
	await _use(0)
	_check(b.hp < 999.0 and b2.hp < 999.0, "Raio: 7 m e pula para o segundo")
	b.position = base + Vector3(1.5, 0.2, 0)
	b.hp = 999.0
	await _frames(2)
	player.energy = player.max_energy
	var en := player.energy
	await _use(1)
	_check(999.0 - b.hp >= 10.0 + en * 0.4 - 1.0 and player.energy < 5.0, "Descarga: solta toda a energia (%.0f)" % (999.0 - b.hp))

	await _become(Player.Form.TEMPESTADE, 1)
	b = await _dummy(Vector3(2.0, 0, 0))
	await _use(0)
	await _seconds(1.2)
	_check(player.kit.orb_on and b.hp < 999.0 and player.energy < player.max_energy, "Campo elétrico: o orbe dá choque e gasta energia")
	await _use(0)
	_check(not player.kit.orb_on, "Campo elétrico: desliga")
	var anchors := get_tree().get_nodes_in_group("anchor")
	if anchors.size() >= 2:
		var st := WebNetwork.create_strand(anchors[0], anchors[1])
		b.position = st.a_pos.lerp(st.b_pos, 0.5) + Vector3(0, 0.2, 0)
		b.hp = 999.0
		player.global_position = st.a_pos.lerp(st.b_pos, 0.5) + Vector3(2, 0.1, 0)
		await _frames(3)
		player.energy = player.max_energy
		await _use(1)
		_check(b.hp < 999.0 and b.is_entangled(), "Trovão nos fios: choque pelo fio")
		WebNetwork.remove_strand(st)

	# ---- Seda Ardente
	await _become(Player.Form.ARDENTE, 0)
	b = await _dummy(Vector3(3.0, 0, 0))
	await _use(0, 1.0)
	_check(b.hp < 990.0 and player.kit.heat > 10.0, "Lança-chamas: sopro queima e esquenta (%.0f%%)" % player.kit.heat)
	await _use(0, 4.5)
	_check(player.kit.overheat > 0.0, "Lança-chamas: superaquece")
	b.hp = 999.0
	b.burn_time = 0.0
	player.aim_point = b.global_position
	await _use(1)
	await _seconds(1.2)
	_check(b.hp < 999.0, "Brasa: fogo no chão")

	await _become(Player.Form.ARDENTE, 1)
	b = await _dummy(Vector3(1.5, 0, 0))
	for k in 5:
		await _use(0)
	_check(player.kit.heat >= 100.0, "Fornalha: garras enchem o calor")
	b.hp = 999.0
	b.position = base + Vector3(0, 0.2, -2.8)
	await _frames(2)
	await _use(1)
	_check(999.0 - b.hp >= 59.0 and player.kit.heat == 0.0, "Explosão: 60 em volta e zera o calor")

	# ---- Sombra do Breu
	await _become(Player.Form.BREU, 0)
	b = await _dummy(Vector3(1.5, 0, 0), 300.0)
	b.noticed_player = false
	await _use(0)
	_check(not is_instance_valid(b) or b.dead, "Golpe silencioso: quem não te viu morre")
	b = await _dummy(Vector3(4.0, 0, 0))
	player.rune_on = false
	await _use(1)
	_check(player.global_position.x > base.x + 4.0 and b.hp < 999.0, "Passo sombrio: aparece atrás e crava")

	await _become(Player.Form.BREU, 1)
	b = await _dummy(Vector3(5.0, 0, 0))
	b.noticed_player = true
	await _use(0)
	_check(b.distract_time > 0.0 and player.veil_t > 0.0, "Sombra viva: o bicho vai atrás do clone e ela some")
	var fire := Fire.new(0.5)
	layer.add_child(fire)
	fire.global_position = base + Vector3(2, 0, 0)
	await _frames(2)
	await _use(1)
	_check(fire.snuffed > 0.0 and player.veil_t > 0.0, "Breu: apaga o fogo e esconde")
	fire.queue_free()

	# ---- Viúva
	await _become(Player.Form.VIUVA, 0)
	b = await _dummy(Vector3(5.0, 0, 0))
	player.aim_point = b.global_position
	await _use(0)
	await _seconds(0.7)
	_check(b.poison_stacks >= 2, "Cuspe de veneno: envenena onde cai (%d)" % b.poison_stacks)
	b.poison_stacks = 0
	b.position = base + Vector3(1.6, 0.2, 0)
	await _frames(2)
	await _use(1)
	_check(b.poison_stacks >= 6, "Picada fatal: muitas doses (%d)" % b.poison_stacks)

	await _become(Player.Form.VIUVA, 1)
	b = await _dummy(Vector3(1.5, 0, 0))
	b.poison_stacks = 6
	player.hp = player.max_hp * 0.5
	var hp1 := player.hp
	await _use(1)
	_check(player.hp > hp1 and b.poison_stacks <= 3, "Dreno: cura com o veneno dos bichos (+%.0f)" % (player.hp - hp1))

	# ---- Corrosiva
	await _become(Player.Form.CORROSIVA, 0)
	b = await _dummy(Vector3(5.0, 0, 0))
	await _use(0)
	_check(b.hp < 999.0 and b.corrode_time > 0.0, "Cuspe ácido: 5 m em linha e corrói")
	b.position = base + Vector3(1.4, 0.2, 0)
	b.hp = 999.0
	await _frames(2)
	await _use(1, 1.2)
	_check(999.0 - b.hp >= 10.0 and b.corrode_time > 0.0, "Derreter: segurar derrete (%.0f)" % (999.0 - b.hp))

	await _become(Player.Form.CORROSIVA, 1)
	b = await _dummy(Vector3(-2.5, 0, 0))
	await _use(0)
	_check(b.hp < 999.0 and b.corrode_time > 0.0, "Banho ácido: respinga em volta")
	b.hp = 1.0
	b.take_damage(5.0, null)
	await _frames(3)
	player.satiety = 10.0
	player.global_position = base + Vector3(-1.6, 0, 0)
	await _frames(2)
	await _use(1)
	_check(player.satiety > 10.0, "Dissolver: come o cadáver de uma vez")

	# ---- Pedra-da-lua
	await _become(Player.Form.LUA, 0)
	b = await _dummy(Vector3(3.6, 0, 0))
	await _use(0)
	_check(999.0 - b.hp >= 25.0, "Lança de luar: 4 m em linha")
	b.hp = 999.0
	b.position = base + Vector3(0, 0.2, 2.8)
	await _frames(2)
	player.shield = 50.0
	await _use(1)
	_check(999.0 - b.hp >= 69.0 and player.shield == 0.0, "Estouro: gasta o escudo numa onda (%.0f)" % (999.0 - b.hp))

	await _become(Player.Form.LUA, 1)
	b = await _dummy(Vector3(1.5, 0, 0))
	player.shield = 10.0
	await _use(0)
	_check(player.shield >= 15.0, "Golpe espelhado: acerto recarrega o escudo")
	player.kit.press(1)
	await _frames(3)
	b.hp = 999.0
	var took3 := player.take_damage(20.0, b)
	_check(not took3 and 999.0 - b.hp >= 29.0, "Refletir: devolve o golpe")
	await _seconds(1.0)

	# ---- estilo e save
	await _become(Player.Form.CORROSIVA, 0)
	var k0 := player.kit
	player.set_attack_style(1)
	await _frames(2)
	_check(player.kit != k0 and player.kit.names[0] == "Banho ácido", "trocar o estilo troca o kit")
	_check(int(player.to_dict().get("attack_style", -1)) == 1, "o estilo vai para o save")
	await _become(Player.Form.CAVALEIRA)
	_check(player.kit == null, "Cavaleira volta aos ataques padrão")


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
