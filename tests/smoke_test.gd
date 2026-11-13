extends Node
## Teste de fumaça: joga a câmara sozinho e confere os sistemas principais.
## Rodar:  godot --headless --path . res://tests/smoke_test.tscn
## Sai com código 0 se tudo passou, 1 se algo falhou.

var main
var player: Player
var failures := 0


func _ready() -> void:
	GameState.permadeath = false   # este teste morre de propósito e volta do casulo
	GameState.delete_save()
	GameState.said = {}
	main = load("res://world/layers/test_chamber.tscn").instantiate()
	add_child(main)
	await _frames(20)
	player = GameState.player
	World.clock.paused = true
	World.clock.set_phase(CaveClock.Phase.CACA)   # predadores acordados durante o teste
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _run() -> void:
	# 1. População inicial
	var larvae := get_tree().get_nodes_in_group("creature").filter(func(c): return c is Larva).size()
	var frogs := get_tree().get_nodes_in_group("predator").size()
	_check(larvae == 9 and frogs == 2, "população inicial: %d larvas, %d sapos" % [larvae, frogs])
	_check(WebNetwork.anchors.size() == 20, "20 âncoras registradas")

	# 2. Abismo sem fio: cai e volta com dano
	_teleport(Vector3(-6.0, 0.1, -3.0))
	await _frames(10)
	var hp_before := player.hp
	Input.action_press("move_right")
	for i in 240:
		await _frames(1)
		if player.hp < hp_before - 1.0:
			break
	Input.action_release("move_right")
	await _frames(5)
	_check(player.hp <= hp_before - 24.0 and player.global_position.x < -2.5, "cair no abismo tira 25 PV e devolve ao chão firme (PV %d -> %d)" % [int(hp_before), int(player.hp)])

	# 3. Fio-guia sobre o abismo pelo Modo Tecelagem
	_teleport(Vector3(-7.0, 0.1, 6.0))
	await _frames(10)
	Input.action_press("weave")
	await _frames(3)
	_check(player.weaving and is_equal_approx(Engine.time_scale, 0.25), "Modo Tecelagem deixa o tempo a 25%")
	player.hovered_anchor = WebNetwork.anchors["Pilar_06"]
	player._weave_click()
	player.hovered_anchor = WebNetwork.anchors["Pilar_12"]
	var silk_before := player.silk
	player._weave_click()
	_check(WebNetwork.strands.size() == 1 and player.silk <= silk_before - 5.0, "fio-guia tecido entre Pilar_06 e Pilar_12")
	Input.action_release("weave")
	await _frames(3)
	_check(not player.weaving and is_equal_approx(Engine.time_scale, 1.0), "soltar R volta o tempo ao normal")
	_teleport(Vector3(-4.1, 0.15, 6.0))
	await _frames(5)
	await _hold("move_right", 1.4)
	_check(player.global_position.x > 3.2 and player.global_position.y > -1.0, "atravessou o abismo andando no fio (x = %.1f)" % player.global_position.x)

	# 4. Fio longo demais é recusado
	var err := player._strand_error(WebNetwork.anchors["Pilar_00"], WebNetwork.anchors["Pilar_05"])
	_check(err.begins_with("Longe demais"), "fio acima de 12 m é recusado")

	# 5. Combate: matar uma larva e comer
	_teleport(Vector3(-20.0, 0.1, -16.0))
	await _frames(5)
	var prey: Larva = main.ecosystem.spawn_larva(Vector3(-20.0, 0.0, -17.2))
	await _frames(5)
	prey.entangle(10.0)
	prey.global_position = Vector3(-20.0, 0.1, -17.3)
	Input.action_press("aim_up", 1.0)
	await _frames(3)
	var xp_before := player.xp + player.level * 1000
	for i in 4:
		player._start_attack(0)
		await _frames(25)
	Input.action_release("aim_up")
	_check(not is_instance_valid(prey) or prey.dead, "larva enredada morre no combo (crítico x2)")
	await _frames(5)
	player.satiety = 40.0
	var corpse := player._nearest_corpse(3.0)
	_check(corpse != null, "larva deixou cadáver")
	if corpse != null:
		_teleport(corpse.global_position + Vector3(0.0, 0.1, 0.8))
		await _frames(3)
		player._interact()
		await _frames(70)
		_check(player.satiety > 60.0 and player.xp + player.level * 1000 > xp_before, "comer dá saciedade e XP (saciedade %d)" % int(player.satiety))

	# 6. Casulo, território, descanso e save
	_teleport(Vector3(-22.0, 0.1, -8.0))
	await _frames(10)
	player.silk = player.max_silk
	player.aim_dir = Vector3(0, 0, 1)
	player._weave_cocoon()
	_check(WebNetwork.cocoons.size() == 1, "casulo tecido")
	await _frames(30)
	_check(player.in_territory, "perto do casulo = no território")
	var cocoon := WebNetwork.cocoons[0]
	_teleport(cocoon.global_position + Vector3(0.0, 0.1, 1.5))
	await _frames(3)
	player.hp = 30.0
	# ninguém te caçando agora (com predador por perto o casulo não deixa dormir)
	for c in World.creatures:
		if is_instance_valid(c) and c.brain != null:
			c.player_memory = 0.0
			if c.uses_interest:
				c.give_up_hunt()
			c.brain.decide(c)
	# um sapo passeando pode ter arrebentado o fio-guia (é do jogo): tece de novo
	if WebNetwork.strands.is_empty():
		WebNetwork.create_strand(WebNetwork.anchors["Pilar_06"], WebNetwork.anchors["Pilar_12"])
	_check(player.rest_blocker() == "", "ninguém caçando perto do casulo (%s)" % player.rest_blocker())
	player._interact()
	await _frames(3)
	var menu: CocoonMenu = GameState.current_layer.hud.cocoon_menu
	_check(menu != null and menu.visible and get_tree().paused, "E no casulo abre o menu do casulo e pausa")
	_check(player.hp < 31.0, "só abrir o menu não cura")
	menu.rest()
	await _frames(3)
	_check(not menu.visible and not get_tree().paused, "Descansar fecha o menu e despausa")
	_check(is_equal_approx(player.hp, player.max_hp), "descansar cura tudo")
	var data := GameState.load_game()
	_check(not data.is_empty() and data["web"]["cocoons"].size() == 1 and data["web"]["strands"].size() == 1, "save gravado com casulo e fio")

	# 7. Sapo vê, persegue e ataca
	var frog: Frog = null
	for f in get_tree().get_nodes_in_group("predator"):
		var fr := f as Frog
		if fr != null and (frog == null or fr.global_position.x < 0.0):
			frog = fr   # o do oeste, se ainda estiver lá (pode ter passeado)
	_check(frog != null, "sapo do oeste existe")
	if frog != null:
		player.hp = player.max_hp
		player.rune_on = true
		frog._release_prey()
		frog.mode = Frog.Mode.IDLE
		frog.hunger = 0.0
		frog.needs.hunger = 0.0
		frog.needs.fatigue = 0.0
		frog.needs.fear = 0.0
		frog.needs.restless = 0.0
		frog.facing = Vector3(0, 0, -1)
		frog.global_position = Vector3(-12.0, 0.3, 11.0)   # lugar aberto, sem pedra no caminho
		frog.velocity = Vector3.ZERO
		_teleport(Vector3(-12.0, 0.1, 7.0))
		frog.brain.wake_up()
		var waited := 0.0
		while waited < 8.0 and player.hp >= player.max_hp:
			await _seconds(0.5)
			waited += 0.5
		_check(player.hp < player.max_hp, "sapo atacou (PV %d)" % int(player.hp))
		# 8. Teia de captura prende o sapo
		player.level = 3
		player.silk = player.max_silk
		_teleport(frog.global_position + Vector3(0.0, 0.1, -4.5))
		await _frames(2)
		WebNetwork.create_trap(Vector3(frog.global_position.x, 0.0, frog.global_position.z))
		await _frames(10)
		_check(frog.is_entangled(), "teia de captura enreda o sapo (tamanho M)")
		var hp_frog := frog.hp
		frog.take_damage(10.0, player)
		_check(frog.hp <= hp_frog - 10.0, "sapo enredado recebe dano")

	# 9. Fome mata devagar
	player.satiety = 0.0
	var hp_starve := player.hp
	await _seconds(1.0)
	_check(player.hp < hp_starve, "fome zerada drena PV")

	# 10. Tick de física em câmera lenta (informativo)
	Engine.time_scale = 0.25
	var f0 := Engine.get_physics_frames()
	var t0 := Time.get_ticks_msec()
	await _seconds_real(0.5)
	print("  info: física em câmera lenta = %.0f ticks/s reais" % ((Engine.get_physics_frames() - f0) * 1000.0 / maxf(1.0, Time.get_ticks_msec() - t0)))
	Engine.time_scale = 1.0


# ---------------------------------------------------------------- utilidades

func _check(ok: bool, label: String) -> void:
	if ok:
		print("  ok    ", label)
	else:
		failures += 1
		print("  FALHA ", label)


func _teleport(pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.external_velocity = Vector3.ZERO
	player.last_safe_pos = pos


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(int(s * 60.0))


func _seconds_real(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _hold(action: String, s: float) -> void:
	Input.action_press(action)
	await _seconds(s)
	Input.action_release(action)
	await _frames(5)
