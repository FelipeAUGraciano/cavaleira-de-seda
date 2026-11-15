extends Node
## v0.8 etapa 1: golpes estilo Monster Hunter, perseguição, teia por tamanho, fúria e
## morte (volta para o último casulo, o andar continua).
## Rodar:  godot --headless --path . res://tests/hardcore_test.tscn

var layer
var player: Player
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	reparent(get_tree().root)          # sobrevive à troca de cena do fim (permadeath)
	get_tree().current_scene = null
	GameState.new_game()
	await _frames(5)
	get_tree().change_scene_to_file("res://world/layers/galerias.tscn")
	await _frames(30)
	layer = get_tree().current_scene
	player = GameState.player
	World.clock.paused = true
	World.clock.set_phase(CaveClock.Phase.CACA)
	for c in World.creatures:
		c.needs.hunger = 0.0
		c.needs.fatigue = 0.0
		c.needs.restless = 0.0
	await _combat()
	await _pursuit()
	await _webs()
	await _falls()
	await _death_to_cocoon()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _frog() -> Frog:
	for c in World.creatures:
		if c is Frog and not c.dead:
			return c
	return null


func _combat() -> void:
	var frog := _frog()
	_check(frog.attacks.size() >= 4, "sapo tem %d golpes" % frog.attacks.size())
	frog.uses_interest = false   # aqui o teste força os golpes na mão (sem o medidor de interesse)
	var bite := frog.find_attack("bote")
	_check(bite.damage * 2.0 >= player.max_hp, "dois botes matam a Filhote (%.0f x2 vs %.0f PV)" % [bite.damage, player.max_hp])

	# O golpe não cancela quando você sai do alcance
	_teleport(Galerias.W(Vector3(-2.0, 0.1, 30.0)))
	frog.global_position = Galerias.W(Vector3(-2.0, 0.0, 32.0))
	frog.facing = Vector3(0, 0, -1)
	frog.start_attack(bite, player)
	await _frames(6)
	_teleport(Galerias.W(Vector3(-2.0, 0.1, 24.0)))
	var phases := {}
	for i in 90:
		await get_tree().physics_frame
		if frog.cur_attack == bite:
			phases[frog.atk_phase] = true
	_check(phases.has(1) and phases.has(2), "bote vai até o fim mesmo com você longe (fases %s)" % [phases.keys()])

	# Marca no chão durante o aviso
	frog.cur_attack = null
	frog.atk_gap = 0.0
	frog.start_attack(bite, player)
	await _frames(3)
	_check(frog._marker != null and frog._marker.visible, "aviso aparece no chão")
	frog.cancel_attack()

	# Mira travada: o golpe mira uma vez onde você está e não te acompanha no aviso
	var tongue := frog.find_attack("lingua") if frog.find_attack("lingua") != null else bite
	frog.global_position = player.global_position + Vector3(0, 0, 3.0)
	frog.facing = Vector3(1, 0, 0)
	frog.cur_attack = null
	frog.start_attack(tongue, player)
	var aim0 := frog.atk_point
	var face0 := frog.facing
	_check(face0.dot((player.global_position - frog.global_position).normalized() * Vector3(1, 0, 1)) > 0.95, "vira para você na hora em que começa o golpe")
	_teleport(player.global_position + Vector3(3.0, 0.0, 0.0))   # sai de lado durante o aviso
	await _frames(8)
	_check(frog.atk_point.is_equal_approx(aim0) and frog.facing.dot(face0) > 0.999, "durante o aviso a mira não acompanha (%.3f)" % frog.facing.dot(face0))
	frog.cancel_attack()
	player.velocity = Vector3.ZERO
	var still := frog._predict(player, frog.find_attack("salto"))
	player.velocity = Vector3(5.0, 0.0, 0.0)
	var pt := frog._predict(player, frog.find_attack("salto"))
	_check(Fx.flat_dist(pt, still) < 0.05, "salto mira onde você está, sem prever a corrida (%.1f m)" % Fx.flat_dist(pt, still))
	player.velocity = Vector3.ZERO

	# Quem fica rodando do lado leva o giro
	frog.global_position = Galerias.W(Vector3(-2.0, 0.0, 30.0))
	frog.facing = Vector3(0, 0, 1)
	_teleport(Galerias.W(Vector3(0.2, 0.1, 30.0)))   # do lado (90°), a 2,2 m
	for a in frog.attacks:
		a.cd_left = 0.0
	var spins := 0
	for i in 40:
		var a := frog.pick_attack(player)
		if a != null and a.id == "giro":
			spins += 1
	_check(spins >= 25, "do lado dele, o sapo prefere o giro (%d de 40)" % spins)

	# Fúria na metade da vida
	frog.hp = frog.max_hp
	frog.take_damage(frog.max_hp * 0.55, player)
	_check(frog.enraged, "abaixo da metade da vida o sapo fica furioso")
	frog.global_position = Galerias.W(Vector3(-2.0, 0.0, 36.0))
	_teleport(Galerias.W(Vector3(-2.0, 0.1, 30.0)))
	for a in frog.attacks:
		a.cd_left = 99.0
	frog.find_attack("cuspe").cd_left = 0.0
	frog.facing = Vector3(0, 0, -1)
	_check(frog.pick_attack(player) == frog.find_attack("cuspe"), "furioso, ele ganha o cuspe ácido")
	for a in frog.attacks:
		a.cd_left = 0.0

	# Dois golpes matam
	player.hp = player.max_hp
	player.take_damage(bite.damage, frog)
	player.invuln = 0.0
	player.take_damage(bite.damage, frog)
	_check(player.dead, "Filhote morre com dois botes")
	player._respawn()


func _pursuit() -> void:
	var frog := _frog()
	frog.hp = frog.max_hp
	frog.enraged = false
	frog.uses_interest = true
	frog.global_position = Galerias.W(Vector3(-2.0, 0.0, 34.0))
	_teleport(Galerias.W(Vector3(-2.0, 0.1, 30.0)))
	player.rune_on = true
	frog.player_memory = frog.memory_time
	frog.last_player_pos = player.global_position
	frog.set_physics_process(false)   # parado enquanto procuramos o esconderijo
	# Achar um lugar perto do sapo sem linha de visão
	# Atrás de um pilar, do outro lado do sapo
	var pil: Vector3 = WebNetwork.anchors["G2_b"].global_position
	frog.global_position = Vector3(pil.x, 0.0, pil.z - 6.0)
	var hide := Vector3(pil.x, 0.1, pil.z + 1.2)
	_teleport(hide)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if frog.has_line_of_sight(player):
		hide = Vector3.INF
	_check(hide != Vector3.INF, "achou um esconderijo atrás de pedra")
	if hide == Vector3.INF:
		return
	player.velocity = Vector3(3.0, 0.0, 0.0)   # andando: faz barulho
	_check(frog.keeps_tracking(player), "fora de vista mas andando: ele segue o rastro")
	player.velocity = Vector3.ZERO
	player.rune_on = false
	_check(not frog.keeps_tracking(player), "fora de vista, parada e com a runa apagada: perde o rastro")
	frog.player_memory = 0.0
	frog.search_left = frog.search_time
	_check(frog.combat_wants(), "perdeu você: vasculha a área antes de desistir")
	player.rune_on = true
	frog.set_physics_process(true)


func _webs() -> void:
	var larva: Larva = null
	for c in World.creatures:
		if c is Larva and not c.dead:
			larva = c
			break
	_check(larva.entangle(4.0) >= 4.0, "larva (P) fica presa o tempo todo")
	var frog := _frog()
	frog.entangled_time = 0.0
	frog._web_immune = 0.0
	var held := frog.entangle(4.0)
	_check(held > 0.0 and held <= 2.3, "sapo (M) fica preso só %.1f s e rasga" % held)
	var boss: Creature = null
	for c in World.creatures:
		if c.size >= Creature.Size.G:
			boss = c
			break
	if boss != null:
		_check(boss.entangle(4.0) == 0.0 and boss.slow_time > 0.0, "Centopeia (G) arrebenta na hora e só perde o passo")
	# Sapo andando num fio arrebenta o fio
	frog.entangled_time = 0.0
	frog._web_immune = 0.0
	var a: WebAnchor = null
	var b: WebAnchor = null
	for id in WebNetwork.anchors:
		var an: WebAnchor = WebNetwork.anchors[id]
		if a == null:
			a = an
		elif b == null and an.global_position.distance_to(a.global_position) > 3.0 and an.global_position.distance_to(a.global_position) < 10.0:
			b = an
	var s := WebNetwork.create_strand(a, b)
	var mid := (a.global_position + b.global_position) * 0.5
	frog.global_position = Vector3(mid.x, mid.y - frog.body_radius, mid.z)
	frog._walk_into_strands()
	_check(frog.is_entangled() and not WebNetwork.strands.has(s), "sapo enrosca no fio e arrebenta")


func _falls() -> void:
	# Visão curta
	_check(layer.dark_vision and player.sight_radius() < 4.0, "visão curta: a Filhote enxerga %.1f m no escuro" % player.sight_radius())
	# Queda com andar de baixo
	_teleport(Galerias.W(Vector3(71.0, -3.0, 38.0)))   # 1ª fenda da Ponte quebrada
	player.last_safe_pos = Galerias.W(Vector3(67.0, 0.0, 38.0))
	player.hp = player.max_hp
	await _frames(80)
	_check(not player.dead and int(layer.map_system.room_at(player.global_position).get("floor", 0)) == 1, "caiu na fenda da Ponte e acordou nas Profundezas (%s)" % layer.map_system.room_at(player.global_position).get("id", "?"))
	_check(absf(player.hp - player.max_hp * 0.65) < 1.5, "a queda tira 35%% da vida (%.0f/%.0f)" % [player.hp, player.max_hp])
	layer.hud.fade_alpha = 0.0
	# Sem fundo
	_teleport(Galerias.W(Vector3(77.0, -3.0, 2.0)))   # abismo longo da G16: sem fundo
	player.last_safe_pos = Galerias.W(Vector3(70.0, 0.0, 10.0))
	await _frames(10)
	_check(player.dead, "abismo sem fundo mata")
	player._respawn()
	# Rampa leva de volta para cima
	var ramp: Rect2 = layer.passages[1]["rect"]   # a rampa de baixo que sobe para a Poça rasa
	_teleport(Vector3(ramp.get_center().x, 0.1, ramp.get_center().y))
	await _frames(70)
	_check(layer.map_system.room_at(player.global_position).get("id", "") == "G2", "rampa das Profundezas leva à Poça rasa (%s)" % layer.map_system.room_at(player.global_position).get("id", "?"))
	layer.hud.fade_alpha = 0.0
	await _frames(60)
	_teleport(Galerias.W(Vector3(-2.0, 0.1, 30.0)))


func _death_to_cocoon() -> void:
	## Morte: volta para o último casulo, o andar NÃO recomeça.
	player.hp = player.max_hp
	_teleport(Galerias.W(Vector3(-2.0, 0.1, 30.0)))
	await _frames(5)
	var cocoon := WebNetwork.create_cocoon(player.global_position + Vector3(0, 0, 2.0))
	player._rest(cocoon)
	var home := player.respawn_pos
	_check(player.rested_here, "descansar marca o casulo como volta")
	var lvl := player.level
	player.gain_xp(500)
	var lvl_up := player.level
	_check(lvl_up > lvl, "subiu de nível depois do casulo (%d)" % lvl_up)
	var victim := _frog()
	victim.hp = 1.0
	victim.take_damage(50.0, player)
	var victim_ref: WeakRef = weakref(victim)
	await _frames(3)
	_check(victim_ref.get_ref() == null or (victim_ref.get_ref() as Creature).dead, "matou um sapo")
	var strands0 := WebNetwork.strands.size()
	var cocoons0 := WebNetwork.cocoons.size()
	# passa por uma câmara de passagem: não muda o lugar de voltar
	_teleport(Galerias.W(Vector3(44.0, 0.1, 36.0)))
	await _frames(10)
	_check(player.respawn_pos.is_equal_approx(home), "câmara de passagem não troca o casulo de volta")
	player.hp = 1.0
	player.invuln = 0.0
	player.take_damage(10.0, null, false)
	_check(player.dead, "morreu")
	var back := false
	for i in 80:
		await _seconds(0.1)
		if not player.dead:
			back = true
			break
	await _seconds(2.0)
	_check(back and is_instance_valid(layer) and GameState.current_layer == layer and GameState.player == player, "acorda na mesma camada (o andar não recomeça)")
	_check(Fx.flat_dist(player.global_position, home) < 1.5, "acorda no casulo (%.1f m)" % Fx.flat_dist(player.global_position, home))
	_check(player.level == lvl_up, "nível ganho fica (%d)" % player.level)
	_check(victim_ref.get_ref() == null or (victim_ref.get_ref() as Creature).dead, "o sapo morto continua morto")
	_check(WebNetwork.strands.size() == strands0 and WebNetwork.cocoons.size() == cocoons0, "fios e casulos ficam")
	_check(layer.hud.fade_alpha < 0.05, "a tela clareia de novo")
	var hunting := 0
	for c in World.creatures:
		if is_instance_valid(c) and not c.dead and c.hunting_player() and Fx.flat_dist(c.global_position, player.global_position) < 10.0:
			hunting += 1
	_check(hunting == 0, "ninguém de plantão no casulo (%d)" % hunting)


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
	await get_tree().create_timer(s).timeout
