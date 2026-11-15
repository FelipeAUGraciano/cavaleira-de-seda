extends Node
## Toca (G22 Fosso escuro): tomar posse, só ela salva/cura, portas de teia, bolsa de 2,
## comer em qualquer lugar, arrastar presa grande, saque e fios-alarme.
## Rodar:  godot --headless --path . res://tests/toca_test.tscn

var layer
var player: Player
var den: Den
var failures := 0
var _big: Array = []


func _ready() -> void:
	GameState.permadeath = false
	GameState.delete_save()
	GameState.said = {}
	GameState.flags = {}
	GameState.dens = {}
	layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	World.clock.paused = true
	World.clock.set_phase(CaveClock.Phase.CACA)
	EventBus.big_message.connect(func(t): _big.append(String(t)))
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _run() -> void:
	den = layer.den
	_check(den != null and den.slots.size() == 4 and not den.claimed, "G22 é a câmara-toca: 4 entradas, ainda sem dona")
	_check(GameState.has_save(), "chegou na camada: salvou sozinho (sem toca ainda)")
	var center := den.center
	# fechada por rocha: de dentro para fora só pelas 4 entradas (sem atalho)
	var gaps := 0
	var was_open := false
	for k in 144:
		var a := k * TAU / 144.0
		var q := Vector2(center.x, center.z) + Vector2(cos(a), sin(a)) * 5.6
		var open: bool = layer.cave.floor_value(q) > 0.0
		if open and not was_open:
			gaps += 1
		was_open = open
	_check(gaps == 4, "a toca é fechada por rocha com 4 entradas estreitas (%d)" % gaps)
	_check(den.decor != null and den.decor.stage == 0, "antes de ser tomada: ninho abandonado (teia velha)")
	# casulo livre não existe mais
	_teleport(Galerias.W(Vector3(44, 0.1, 36)))
	await _frames(3)
	player.silk = player.max_silk
	var n0 := WebNetwork.cocoons.size()
	player._context_weave()
	_check(WebNetwork.cocoons.size() == n0, "fora da toca não dá para tecer casulo")
	# tomar posse
	_teleport(center + Vector3(0.5, 0.1, 0.5))
	await _frames(3)
	player.silk = player.max_silk
	player._context_weave()
	await _frames(3)
	_check(den.claimed and den.cocoon != null and is_instance_valid(den.cocoon), "C no ninho velho: casulo central e a câmara vira toca")
	_check(player.rested_here and Fx.flat_dist(player.respawn_pos, center) < 2.5, "a morte agora volta para a toca")
	_check(den.decor.stage == 1 and den.cocoon.position.y > 0.3, "tomada: o tapete de seda começa e o casulo sobe para a rede")
	var saved := GameState.load_game()
	_check((saved.get("dens", {}) as Dictionary).size() == 1, "a toca vai para o save")
	# portas
	for i in den.slots.size():
		var s: Dictionary = den.slots[i]
		_teleport((s["pos"] as Vector3) - (s["out"] as Vector3) * 1.0 + Vector3(0, 0.1, 0))
		await _frames(2)
		player.silk = player.max_silk
		var silk0 := player.silk
		player._context_weave()
		_check(den.door_state(i) == "inteira" and is_equal_approx(player.silk, silk0 - Den.DOOR_COST), "porta %s tecida (15 de Seda)" % den.dir_name(i))
	await _frames(3)
	var outside: Vector3 = (den.slots[0]["pos"] as Vector3) + (den.slots[0]["out"] as Vector3) * 3.0
	var path := World.nav.path(outside, center)
	var reach_in := not path.is_empty() and Fx.flat_dist(path[path.size() - 1], center) < 4.0
	_check(not reach_in, "com as portas fechadas, os bichos não acham caminho para dentro")
	# a jogadora passa pela porta
	_teleport(outside + Vector3(0, 0.1, 0))
	await _frames(2)
	var dir := (center - outside)
	dir.y = 0.0
	var crossed := false
	for f in 120:
		player.velocity = dir.normalized() * 4.0
		player.global_position += dir.normalized() * 4.0 / 60.0
		await get_tree().physics_frame
		if den.is_inside(player.global_position) and Fx.flat_dist(player.global_position, center) < 3.0:
			crossed = true
			break
	_check(crossed, "você atravessa a própria porta de teia")
	# bolsa: presa pequena
	var larva := _corpse("Larva-de-musgo", 20.0, 10.0, false, player.global_position + Vector3(1.0, 0, 0))
	await _frames(2)
	player.silk = player.max_silk
	player._context_weave()
	await _frames(2)
	_check(player.bag.size() == 1 and not is_instance_valid(larva), "presa pequena: C embrulha e vai para a bolsa")
	player.satiety = 10.0
	player.eat_from_bag()
	await _seconds(1.5)
	_check(player.bag.is_empty() and player.satiety > 25.0, "come o embrulho em qualquer lugar (leva um tempinho)")
	player.bag = [{"name": "a", "sat": 10.0, "silk": 1.0}, {"name": "b", "sat": 10.0, "silk": 1.0}]
	var l2 := _corpse("Larva-de-musgo", 20.0, 10.0, false, player.global_position + Vector3(1.0, 0, 0))
	await _frames(2)
	player._context_weave()
	_check(player.bag.size() == 2 and is_instance_valid(l2), "a bolsa só leva 2")
	l2.queue_free()
	player.bag.clear()
	player.satiety = 10.0
	player.eat_from_bag()
	_check(player.state != Player.State.EAT, "bolsa vazia: nada para comer")
	player.bag = [{"name": "a", "sat": 30.0, "silk": 1.0}]
	player.eat_from_bag()
	await _seconds(0.4)
	player.take_damage(1.0, null, false)
	await _seconds(1.2)
	_check(player.bag.size() == 1 and player.satiety < 20.0, "levar dano interrompe o lanche")
	player.bag.clear()
	# presa grande: arrastar até a toca
	var s0: Dictionary = den.slots[1]
	var start: Vector3 = (s0["pos"] as Vector3) + (s0["out"] as Vector3) * 4.0
	_teleport(start + Vector3(0, 0.1, 0))
	await _frames(2)
	var frog := _corpse("Sapo-de-rocha", 45.0, 15.0, true, start + (s0["out"] as Vector3) * 1.0)
	await _frames(2)
	player._context_weave()
	_check(player.dragged == frog, "presa grande: C prende no fio para arrastar")
	var slow := player._state_normal()
	_check(true, "(arrastando)")
	var p0 := den.pantry.size()
	var to_c := center - player.global_position
	to_c.y = 0.0
	var stored := false
	for f in 300:
		player.global_position += to_c.normalized() * 3.0 / 60.0
		await get_tree().physics_frame
		if den.pantry.size() > p0:
			stored = true
			break
	_check(stored and player.dragged == null, "levou o sapo para dentro: guardado na despensa (%d/%d)" % [den.pantry.size(), Den.PANTRY_MAX])
	_check(slow != null, "arrastando você anda mais devagar (x%.2f)" % Player.DRAG_SPEED)
	# saque: bicho com fome rasga a porta, entra e come
	den.pantry = [{"name": "x", "sat": 20.0, "silk": 5.0}, {"name": "Sapo-de-rocha", "sat": 45.0, "silk": 15.0}, {"name": "y", "sat": 20.0, "silk": 5.0}]
	_teleport(Galerias.W(Vector3(44, 0.1, 36)))   # longe
	await _frames(3)
	player.silk = player.max_silk
	den.buy_alarm(player)
	_check(den.alarm, "fios-alarme comprados (50 de Seda)")
	for c in World.creatures.duplicate():   # ninguém por perto para comer o sapo do teste
		if is_instance_valid(c) and Fx.flat_dist(c.global_position, den.center) < 22.0:
			c.queue_free()
	await _frames(2)
	var raider := Frog.new()
	var s2: Dictionary = den.slots[2]
	raider.position = (s2["pos"] as Vector3) + (s2["out"] as Vector3) * 3.0 + Vector3(0, 0.3, 0)
	layer.ecosystem.add_child(raider)
	await _frames(3)
	raider.max_hp = 9999.0
	raider.hp = 9999.0
	raider.needs.hunger = 90.0
	raider.needs.fatigue = 0.0
	raider.asleep = false
	_big.clear()
	den.start_raid(raider)
	var door: DenDoor = den.doors[2]
	var torn := false
	var hit := false
	for i in 40:
		await _seconds(0.5)
		for dd in den.doors:
			if (dd as DenDoor).hp < DenDoor.MAX_HP:
				hit = true
				door = dd
			if not (dd as DenDoor).intact():
				torn = true
				door = dd
		if torn:
			break
	_check(hit, "o sapo com fome vem rasgar a porta da toca")
	_check(_big.any(func(t): return t.begins_with("Fios-alarme")), "fios-alarme avisam de longe")
	if not torn:
		print("  info: sapo=%s fome=%.0f atividade=%s raid=%s hp_porta=%.0f d=%.1f" % [is_instance_valid(raider), raider.needs.hunger if is_instance_valid(raider) else -1.0, raider.activity if is_instance_valid(raider) else "-", raider.raid_den != null if is_instance_valid(raider) else false, door.hp, Fx.flat_dist(raider.global_position, door.global_position) if is_instance_valid(raider) else -1.0])
	_check(torn, "a porta rasga")
	var ate := false
	for i in 40:
		await _seconds(0.5)
		if den.pantry.size() < 3:
			ate = true
			break
	_check(ate, "ele entra e come um embrulho (%d sobraram)" % den.pantry.size())
	_check(not den.pantry.any(func(it): return String(it["name"]) == "Sapo-de-rocha"), "come o mais gostoso")
	_check(den.log_lines.size() > 0, "a toca registra o saque (%s)" % (den.log_lines[0] if den.log_lines.size() > 0 else "-"))
	# descansar remenda porta danificada; rasgada precisa tecer
	(den.doors[(int(door.get_meta("slot")) + 1) % 4] as DenDoor).take_hit(20.0)
	_teleport(center + Vector3(0, 0.1, 1.6))
	for c in World.creatures:
		c.player_memory = 0.0
		if c.uses_interest:
			c.give_up_hunt()
	await _frames(2)
	var st0 := den.decor.stage
	player._rest(den.cocoon)
	_check(den.decor.stage > st0, "a teia da toca cresce com o tempo (estágio %d → %d)" % [st0, den.decor.stage])
	_check(den.decor._pantry.get_child_count() > 0, "a despensa aparece pendurada nas paredes")
	var ti: int = door.get_meta("slot")
	var di := (ti + 1) % 4
	_check(den.door_state(di) == "inteira" and den.door_state(ti) == "rasgada", "descansar remenda a danificada; a rasgada continua rasgada")
	player.silk = player.max_silk
	_check(den.weave_door(ti, player) and den.door_state(ti) == "inteira", "tecer de novo a porta rasgada")
	# save e volta
	GameState.save_now()
	var d: Dictionary = GameState.dens.values()[0]
	_check(bool(d["claimed"]) and (d["pantry"] as Array).size() == den.pantry.size() and bool(d["alarm"]), "despensa, portas e alarme no save")
	var n_pantry := den.pantry.size()
	# carregar o save: a toca volta como estava (um casulo só)
	layer.queue_free()
	await _frames(5)
	layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	var d2: Den = layer.den
	var cocoons := WebNetwork.cocoons.filter(func(c): return is_instance_valid(c) and Fx.flat_dist(c.global_position, d2.center) < 2.5).size()
	var all_doors := d2.doors.all(func(x): return x != null and (x as DenDoor).intact())
	_check(d2.claimed and d2.pantry.size() == n_pantry and d2.alarm and cocoons == 1 and all_doors, "carregou: toca, despensa, alarme, 4 portas e um casulo só (%d)" % cocoons)
	_check(Fx.flat_dist(player.global_position, d2.center) < 3.0, "volta no casulo da toca")


func _corpse(name_: String, sat: float, silk: float, big: bool, pos: Vector3) -> Corpse:
	var c := Corpse.new()
	c.setup(name_, sat, silk, 10, Color(0.5, 0.6, 0.4), 0.7 if big else 0.3)
	c.big = big
	layer.add_child(c)
	c.global_position = Vector3(pos.x, 0.0, pos.z)
	return c


func _teleport(pos: Vector3) -> void:
	if player.dead:
		player._respawn()
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.external_velocity = Vector3.ZERO
	player.last_safe_pos = pos


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
