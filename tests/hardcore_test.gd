extends Node
## v0.8 etapa 1: golpes estilo Monster Hunter, perseguição, teia por tamanho, fúria e
## morte permanente por ato.
## Rodar:  godot --headless --path . res://tests/hardcore_test.tscn

var layer
var player: Player
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	reparent(get_tree().root)          # sobrevive à troca de cena do fim (permadeath)
	get_tree().current_scene = null
	GameState.permadeath = false
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
	await _permadeath()
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
	var bite := frog.find_attack("bote")
	_check(bite.damage * 2.0 >= player.max_hp, "dois botes matam a Filhote (%.0f x2 vs %.0f PV)" % [bite.damage, player.max_hp])

	# O golpe não cancela quando você sai do alcance
	_teleport(Vector3(-2.0, 0.1, 30.0))
	frog.global_position = Vector3(-2.0, 0.0, 32.0)
	frog.facing = Vector3(0, 0, -1)
	frog.start_attack(bite, player)
	await _frames(6)
	_teleport(Vector3(-2.0, 0.1, 24.0))
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

	# Previsão: mira onde você vai estar
	player.velocity = Vector3(5.0, 0.0, 0.0)
	var pt := frog._predict(player, frog.find_attack("salto"))
	_check(pt.x > player.global_position.x + 1.0, "salto mira à frente de quem corre (%.1f m)" % (pt.x - player.global_position.x))
	player.velocity = Vector3.ZERO

	# Quem fica rodando do lado leva o giro
	frog.global_position = Vector3(-2.0, 0.0, 30.0)
	frog.facing = Vector3(0, 0, 1)
	_teleport(Vector3(0.2, 0.1, 30.0))   # do lado (90°), a 2,2 m
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
	frog.global_position = Vector3(-2.0, 0.0, 36.0)
	_teleport(Vector3(-2.0, 0.1, 30.0))
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
	frog.global_position = Vector3(-2.0, 0.0, 34.0)
	_teleport(Vector3(-2.0, 0.1, 30.0))
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
	_teleport(Vector3(71.0, -3.0, 38.0))   # 1ª fenda da Ponte quebrada
	player.last_safe_pos = Vector3(67.0, 0.0, 38.0)
	player.hp = player.max_hp
	await _frames(80)
	_check(not player.dead and layer.map_system.room_at(player.global_position).get("id", "") == "P1", "caiu na fenda da Ponte e acordou nas Profundezas (%s)" % layer.map_system.room_at(player.global_position).get("id", "?"))
	_check(absf(player.hp - player.max_hp * 0.65) < 1.5, "a queda tira 35%% da vida (%.0f/%.0f)" % [player.hp, player.max_hp])
	layer.hud.fade_alpha = 0.0
	# Sem fundo
	_teleport(Vector3(77.0, -3.0, 2.0))   # abismo longo da G16: sem fundo
	player.last_safe_pos = Vector3(70.0, 0.0, 10.0)
	await _frames(10)
	_check(player.dead, "abismo sem fundo mata")
	player._respawn()
	# Rampa leva de volta para cima
	_teleport(Vector3(22.0, 0.1, 214.0))
	await _frames(70)
	_check(layer.map_system.room_at(player.global_position).get("id", "") == "G2", "rampa das Profundezas leva à Poça rasa (%s)" % layer.map_system.room_at(player.global_position).get("id", "?"))
	layer.hud.fade_alpha = 0.0
	await _frames(60)
	_teleport(Vector3(-2.0, 0.1, 30.0))


func _permadeath() -> void:
	GameState.permadeath = true
	# o ato começou com a Filhote nível 1; ganhamos níveis, descobrimos o mapa e falamos
	var lvl0 := int((GameState.act.get("player", {}) as Dictionary).get("level", 1))
	player.gain_xp(500)
	_check(player.level > lvl0, "subiu de nível durante o ato (%d)" % player.level)
	layer.map_system.revealed["G7"] = true
	GameState.say_once("teste_fala", "...")
	player.hp = 1.0
	player.invuln = 0.0
	player.take_damage(10.0, null, false)
	_check(player.dead, "morreu")
	for i in 1200:
		await get_tree().process_frame
		if get_tree().current_scene != layer and get_tree().current_scene != null and GameState.player != null and GameState.player != player:
			break
	await _frames(20)
	var nl = get_tree().current_scene
	_check(nl != layer and nl != null and nl.scene_file_path.ends_with("galerias.tscn") and nl.restarting, "morte recomeça o ato (Galerias de novo)")
	var p2: Player = GameState.player
	_check(p2 != null and p2.level == lvl0 and not p2.dead, "nível volta ao do começo do ato (%d)" % (p2.level if p2 else -1))
	_check(nl.map_system.revealed.has("G7"), "o mapa descoberto continua")
	_check(GameState.said.has("teste_fala"), "falas já ditas não repetem")
	var data := GameState.load_game()
	_check(not data.is_empty() and not bool(data.get("checkpoint", true)), "save volta para o começo do ato (Continuar também)")
	GameState.permadeath = false


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
