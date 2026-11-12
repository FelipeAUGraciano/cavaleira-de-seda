extends Node
## Teste do mundo vivo: relógio da caverna, sono, pasto, bando, medo, brigas e desempenho.
## Rodar:  godot --headless --path . res://tests/vida_test.tscn

var layer
var player: Player
var failures := 0


func _ready() -> void:
	GameState.permadeath = false   # este teste morre de propósito e volta do casulo
	GameState.delete_save()
	GameState.said = {}
	GameState.flags = {}
	layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	World.clock.paused = true
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _run() -> void:
	# Base
	_check(World.nav != null and World.nav.room_cells.size() == layer.rooms.size(), "grade de navegação montada para todas as câmaras")
	_check(World.graze_spots.size() > 10, "pastos de musgo perto dos fungos (%d)" % World.graze_spots.size())
	_check(World.creatures.size() >= 20, "criaturas registradas no mundo (%d)" % World.creatures.size())
	var near := World.near(Galerias.W(Vector3(28, 0, -6)), 8.0)
	_check(near.any(func(c): return c is Bat), "busca espacial acha o bando de morcegos")

	# Relógio: fungos acendem e apagam
	World.clock.set_phase(CaveClock.Phase.BRILHO, 0.5)
	var bright := World.clock.glow()
	World.clock.set_phase(CaveClock.Phase.CACA, 0.5)
	var dark := World.clock.glow()
	_check(bright > 0.9 and dark < 0.4, "fungos acesos no Brilho (%.2f) e apagados na Caça (%.2f)" % [bright, dark])

	# Longe da jogadora, as criaturas pensam menos vezes (LOD)
	_teleport(Galerias.W(Vector3(0.0, 0.1, -17.0)))
	await _seconds(1.0)
	var boss: Centipede = layer.centipede
	_check(not boss.near_player and boss.decide_interval() >= 1.0, "longe da jogadora, a Centopeia decide 1x por segundo")

	# Na Caça, larvas com sono vão dormir na toca
	World.clock.set_phase(CaveClock.Phase.CACA)
	var larva: Larva = null
	for c in World.creatures:
		if c is Larva and Fx.flat_dist(c.global_position, Galerias.W(Vector3(44, 0, 72))) > 14.0:
			larva = c
			break
	larva.needs.fatigue = 90.0
	larva.needs.hunger = 0.0
	larva.needs.fear = 0.0
	await _seconds(8.0)
	_check(larva.asleep and Fx.flat_dist(larva.global_position, larva.den) < 2.5, "na Caça, a larva com sono dorme na toca")

	# No Brilho, larvas com fome vão pastar perto dos fungos
	World.clock.set_phase(CaveClock.Phase.BRILHO)
	larva.needs.fatigue = 0.0
	larva.needs.hunger = 90.0
	await _seconds(1.0)
	_check(larva.brain.is_doing("forage"), "no Brilho, a larva com fome vai pastar (%s)" % larva.activity)

	# No Brilho, morcegos com sono penduram no poleiro
	var bats: Array = World.creatures.filter(func(c): return c is Bat)
	for b in bats:
		b.needs.fatigue = 90.0
		b.needs.hunger = 0.0
	await _seconds(6.0)
	bats = bats.filter(func(b): return is_instance_valid(b) and not b.dead)   # algum pode ter sido comido
	var sleeping := bats.filter(func(b): return b.asleep).size()
	_check(sleeping >= 3, "no Brilho, os morcegos dormem no poleiro (%d de %d)" % [sleeping, bats.size()])

	# Na Caça, o bando sai junto para outra câmara
	World.clock.set_phase(CaveClock.Phase.CACA)
	for b in bats:
		b.needs.fatigue = 0.0
		b.asleep = false
	var leader: Bat = bats[0]
	leader.needs.restless = 100.0
	await _seconds(1.0)
	var mates := bats.filter(func(b): return b.flock == leader.flock and b != leader)
	_check(mates.all(func(b): return b.needs.restless > 50.0 or b.brain.is_doing("roam")), "um morcego inquieto leva o bando junto")
	var start := leader.global_position
	await _seconds(10.0)
	_check(Fx.flat_dist(leader.global_position, start) > 8.0, "o bando voa para outra câmara (%.0f m)" % Fx.flat_dist(leader.global_position, start))

	# Medo: sapo foge da Centopeia acordada
	var frog: Frog = null
	for c in World.creatures:
		if c is Frog:
			frog = c
			break
	boss.needs.restless = 0.0
	boss.needs.hunger = 0.0
	boss.global_position = Galerias.W(Vector3(135.0, 0.05, 77.0))
	boss._reset_trail()
	frog.global_position = Galerias.W(Vector3(139.0, 0.3, 77.0))
	frog.needs.fear = 0.0
	frog.player_memory = 0.0
	_teleport(Galerias.W(Vector3(132.0, 0.1, 60.0)))
	await _seconds(1.0)
	_check(frog.needs.fear > 25.0 and frog.brain.is_doing("flee"), "sapo foge da Centopeia (%s)" % frog.activity)

	# Território: lagarto expulsa um sapo do jardim
	var lz: Lizard = null
	for c in World.creatures:
		if c is Lizard and not c.has_meta("nest_id"):
			lz = c
	var intruder := Frog.new()
	intruder.position = lz.home + Vector3(3.0, 0.3, 0.0)
	layer.ecosystem.add_child(intruder)
	_teleport(Galerias.W(Vector3(44.0, 0.1, 50.0)))
	await _seconds(1.5)
	_check(lz.brain.is_doing("fight"), "lagarto briga com o sapo que invadiu o jardim (%s)" % lz.activity)
	await _seconds(6.0)
	_check(intruder.hp < intruder.max_hp, "e machuca o invasor")

	# Desempenho: o mundo inteiro vivo por 5 s
	World.clock.paused = false
	var frames := 0
	var t0 := Time.get_ticks_usec()
	var t_phys := 0.0
	while frames < 300:
		await get_tree().physics_frame
		t_phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		frames += 1
	var ms := t_phys / frames * 1000.0
	print("  info: %d criaturas, física+IA média %.2f ms por quadro" % [World.creatures.size(), ms])
	_check(ms < 8.0, "mundo inteiro vivo cabe no orçamento (%.2f ms < 8 ms)" % ms)


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
