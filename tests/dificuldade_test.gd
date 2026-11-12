extends Node
## Teste da v0.7: Filhote frágil, evolução no casulo, predadores que caçam a jogadora,
## transição entre camadas e patas que pisam no chão.
## Rodar:  godot --headless --path . res://tests/dificuldade_test.tscn

var layer
var player: Player
var failures := 0


func _ready() -> void:
	GameState.delete_save()
	GameState.said = {}
	GameState.flags = {}
	GameState.carry = {}
	layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	World.clock.paused = true
	World.clock.set_phase(CaveClock.Phase.CACA)
	for c in World.creatures:
		c.needs.fatigue = 0.0
		c.needs.restless = 0.0
		c.needs.hunger = 0.0
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _run() -> void:
	# Transição: a camada começa no escuro, clareia e mostra o nome
	_check(layer.hud._title == "Galerias Úmidas" and layer.hud._title_time > 0.0, "título da camada aparece ao chegar")
	await _seconds(2.0)
	_check(layer.hud.fade_alpha < 0.05, "a tela clareia depois da chegada")

	# Filhote: pequena e frágil
	_check(player.form == Player.Form.FILHOTE and player.form_name() == "Filhote de Seda", "jogo novo começa como Filhote de Seda")
	_check(is_equal_approx(player.max_hp, 50.0), "Filhote tem 50 PV (%.0f)" % player.max_hp)
	_check(absf(player._visual.scale.x - 0.7) < 0.01 and absf(player._leg_rig.size - 0.7) < 0.01, "Filhote é menor (corpo %.2f, patas %.2f)" % [player._visual.scale.x, player._leg_rig.size])
	var frog: Frog = null
	for c in World.creatures:
		if c is Frog:
			frog = c
			break
	_teleport(Vector3(-2.0, 0.1, 30.0))
	frog.global_position = Vector3(-2.0, 0.3, 31.6)
	frog.entangle(3.0)
	var hp0 := frog.hp
	player.aim_dir = Vector3(0, 0, 1)
	player._melee(float((player.form_data()["combo"] as Array)[0]), 2.0, 120.0, false)
	_check(hp0 - frog.hp <= 8.1, "garra da Filhote é fraca: um sapo aguenta muito (%.0f de dano)" % (hp0 - frog.hp))

	# Predador com fome caça a Filhote mesmo sem vê-la
	frog.entangled_time = 0.0
	frog.global_position = Vector3(-4.0, 0.3, 38.0)
	frog.player_memory = 0.0
	frog.needs.hunger = 90.0
	_teleport(Vector3(4.0, 0.1, 27.0))   # a ~13 m, atrás de pedra/fora do cone
	player.rune_on = false
	var d0 := frog.flat_dist_to(player)
	await _seconds(1.0)
	_check(frog.brain.is_doing("stalk") or frog.brain.is_doing("combat"), "sapo faminto vai atrás da Filhote pelo cheiro (%s)" % frog.activity)
	_check(frog.hunting_player(), "o HUD sabe que ele está te caçando (seta vermelha)")
	await _seconds(3.0)
	_check(frog.flat_dist_to(player) < d0 - 3.0, "ele chega mais perto (%.0f → %.0f m)" % [d0, frog.flat_dist_to(player)])
	player.rune_on = true

	# Irmã faminta também segue o cheiro (sem cérebro, lógica própria)
	var sis := Sister.new(true)
	sis.position = Vector3(8.0, 0.3, 30.0)
	layer.ecosystem.add_child(sis)
	_teleport(Vector3(0.0, 0.1, 36.0))
	await _seconds(1.0)
	_check(sis.hunting_player(), "irmã faminta segue o cheiro da Filhote")
	sis.queue_free()

	# Evolução: no nível 8, descansar no casulo faz a muda
	frog.needs.hunger = 0.0
	frog.player_memory = 0.0
	_teleport(Vector3(44.0, 0.1, 38.0))
	player.add_bonus(10.0, 15.0)   # um cristal de vida e um de energia, como no jogo
	player.level = Player.EVOLVE_LEVEL
	player.recompute_stats(true)
	var cocoon := WebNetwork.create_cocoon(Vector3(44, 0, 36))
	player._rest(cocoon)
	_check(player.form == Player.Form.CAVALEIRA and player.level == 1, "no nível %d o casulo faz a muda: Cavaleira de Seda, nível 1" % Player.EVOLVE_LEVEL)
	_check(is_equal_approx(player.max_hp, 120.0) and is_equal_approx(player.max_energy, 125.0), "Cavaleira: 110 PV de base + os bônus de cristal guardados (%.0f PV, %.0f energia)" % [player.max_hp, player.max_energy])
	await _seconds(1.8)
	_check(absf(player._visual.scale.x - 1.0) < 0.05 and absf(player._leg_rig.size - 1.0) < 0.01, "ela cresce (corpo e patas no tamanho cheio)")
	var data := player.to_dict()
	_check(int(data["form"]) == Player.Form.CAVALEIRA and (data["bonus"] as Array).size() == 3, "forma e bônus vão para o save")

	# Agora do mesmo tamanho do sapo: ele só caça se estiver faminto de verdade
	frog.needs.hunger = 60.0
	_check(not frog.sees_player_as_prey(player), "sapo com fome comum não vê a Cavaleira como comida")
	frog.needs.hunger = 90.0
	_check(frog.sees_player_as_prey(player), "mas faminto, arrisca")

	# Patas: pisando no chão, sem perna esticada para longe
	_teleport(Vector3(40.0, 0.1, 36.0))
	Input.action_press("move_right")
	var worst_y := 0.0
	var worst_reach := 0.0
	var legs := player._leg_rig
	var reach := legs._femur_len + legs._tibia_len
	for i in 60:
		await get_tree().physics_frame
		await get_tree().process_frame
		for k in 8:
			if not legs._swinging[k]:
				worst_y = maxf(worst_y, absf(legs._feet[k].y - player.global_position.y))
			worst_reach = maxf(worst_reach, (legs._feet[k] - legs.hip_world(k)).length() / reach)
	Input.action_release("move_right")
	_check(worst_y < 0.05, "patas apoiadas ficam no chão (desvio máx. %.2f m)" % worst_y)
	_check(worst_reach < 1.05, "nenhuma pata estica além do alcance (%.0f%%)" % (worst_reach * 100.0))


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
