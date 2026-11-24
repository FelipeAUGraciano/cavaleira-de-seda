extends Node
## Centopeia-blindada, a escavadora: cavar + rachadura + erupção, sair dentro de um fio,
## cuspe de ácido com poças, investida que quica (furiosa) e o cerco em anel.
## Rodar:  godot --headless --path . res://tests/centopeia_test.tscn

var layer
var player: Player
var boss: Centipede
var failures := 0


func _ready() -> void:
	GameState.permadeath = false
	GameState.delete_save()
	GameState.said = {}
	GameState.flags = {}
	layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	World.clock.paused = true
	World.clock.set_phase(CaveClock.Phase.CACA)
	for c in World.creatures:
		c.needs.fatigue = 0.0
		c.needs.restless = 0.0
	# só a Centopeia e a jogadora no covil (sapos e larvas atrapalhariam a conta)
	for c in World.creatures.duplicate():
		if is_instance_valid(c) and not (c is Centipede) and Fx.flat_dist(c.global_position, layer.ARENA) < 25.0:
			c.queue_free()
	boss = layer.centipede
	player.max_hp = 999.0
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _fight(at: Vector3) -> void:
	boss.entangled_time = 0.0
	boss.global_position = at
	boss.velocity = Vector3.ZERO
	boss._reset_trail()
	boss.player_memory = 10.0
	boss.last_player_pos = player.global_position
	player.hp = player.max_hp
	player.invuln = 0.0


func _run() -> void:
	var c := layer.ARENA as Vector3
	# 1) Cavar: some na terra, nada acerta, a rachadura segue você e ela sai embaixo
	_teleport(c + Vector3(-5.0, 0.1, 0.0))
	_fight(c + Vector3(5.0, 0.05, 0.0))
	boss._begin(Centipede.Mode.BURROW)
	boss.brain.decide(boss)
	await _seconds(1.0)
	_check(boss.under and boss.mode == Centipede.Mode.UNDER, "ela cava e some na terra")
	var hp0 := boss.hp
	boss.take_damage(100.0, player)
	_check(is_equal_approx(boss.hp, hp0), "embaixo da terra nada acerta")
	var cracks := 0
	var hit := false
	for i in 80:
		await _seconds(0.1)
		player.velocity = Vector3.ZERO
		boss.last_player_pos = player.global_position
		if player.hp < player.max_hp:
			hit = true
			break
	cracks = get_tree().get_nodes_in_group("rachadura").size()
	_check(cracks >= 2, "deixa rachadura no chão por onde passa (%d)" % cracks)
	_check(hit and not boss.under, "sai da terra embaixo de você (erupção, %.0f PV)" % (player.max_hp - player.hp))

	# 2) Sair dentro de um fio: se enrosca e a carapaça abre
	await _seconds(1.5)
	var s := WebNetwork.create_strand(WebNetwork.anchors["G14_0"], WebNetwork.anchors["G14_4"])
	var sm := (s.a_pos + s.b_pos) * 0.5
	_teleport(c + Vector3(0.0, 0.1, 9.0))
	_fight(Vector3(sm.x + 0.6, 0.05, sm.z))
	boss._set_under(true)
	boss._begin(Centipede.Mode.UNDER)
	boss.mode_time = 1.0
	boss.last_player_pos = Vector3(sm.x, 0.0, sm.z)
	boss.player_memory = 0.0
	boss.brain.decide(boss)
	var tangled := false
	for i in 60:
		await _frames(3)
		boss.last_player_pos = Vector3(sm.x, 0.0, sm.z)
		if boss.is_entangled():
			tangled = true
			break
	_check(tangled, "saiu da terra em cima de um fio: enredada")
	_check(not is_instance_valid(s) or not WebNetwork.strands.has(s), "o fio arrebenta")
	boss.entangled_time = 0.0

	# 3) Cuspe de ácido: dano no cone e poças no chão
	await _seconds(1.0)
	_teleport(c + Vector3(-5.0, 0.1, 0.0))
	_fight(c + Vector3(0.5, 0.05, 0.0))
	var pools0 := _pools()
	boss._begin(Centipede.Mode.SPIT)
	boss.face_toward(player.global_position)
	boss.brain.decide(boss)
	await _seconds(0.9)
	_check(_pools() >= pools0 + 2, "cuspe de ácido deixa poças (%d)" % (_pools() - pools0))
	_check(player.hp < player.max_hp, "e machuca quem está no leque")

	# 4) Furiosa: a investida quica na parede (2x) e só depois ela fica tonta
	await _seconds(1.3)
	boss.phase = 2
	_fight(c)
	boss._bounces = 0
	boss.mode = Centipede.Mode.CHARGE
	boss.mode_time = 0.5
	boss._wall_hit()
	_check(boss.mode == Centipede.Mode.WINDUP and boss._bounces == 1, "furiosa: bateu na parede e já mira de novo")
	boss.mode = Centipede.Mode.CHARGE
	boss._wall_hit()
	boss.mode = Centipede.Mode.CHARGE
	boss._wall_hit()
	_check(boss.mode == Centipede.Mode.RECOVER and boss.mode_time < -1.0, "na terceira batida ela fica tonta")
	boss.phase = 1
	boss._wall_hit()
	_check(boss.mode == Centipede.Mode.RECOVER, "calma (fase 1) ela não quica")

	# 5) Cerco: corre em volta e fecha o anel
	await _seconds(2.0)
	boss.phase = 2
	_teleport(c + Vector3(0.0, 0.1, 0.0))
	var bad := []
	for i in 12:
		var a := i * TAU / 12.0
		var q := player.global_position + Vector3(cos(a), 0.0, sin(a)) * Centipede.CIRCLE_R
		if not World.nav.walkable(q, NavGrid.Kind.LARGE):
			bad.append("%d:%s/%s" % [i, World.nav.walkable(q, NavGrid.Kind.SMALL), layer.map_system.room_at(q).get("id", "?")])
	_check(boss._ring_clear(player.global_position), "o meio do covil tem espaço para o anel %s" % str(bad))
	_fight(c + Vector3(4.2, 0.05, 0.0))
	boss._start_circle(player.global_position)
	boss.brain.decide(boss)
	var squeezed := false
	var hp_ring := player.hp
	for i in 70:
		await _seconds(0.1)
		player.global_position = Vector3(c.x, player.global_position.y, c.z)
		player.velocity = Vector3.ZERO
		if boss.mode == Centipede.Mode.RECOVER:
			squeezed = true
			break
	_check(squeezed, "dá a volta e aperta o anel")
	_check(player.hp <= hp_ring - Centipede.SQUEEZE_DAMAGE + 0.5, "quem ficou dentro é esmagada (%.0f PV)" % (hp_ring - player.hp))
	await _seconds(1.5)
	_fight(c + Vector3(4.2, 0.05, 0.0))
	_teleport(c)
	boss._start_circle(player.global_position)
	boss.brain.decide(boss)
	await _seconds(0.3)
	_teleport(c + Vector3(0.0, 0.1, -9.0))   # saiu do anel a tempo
	player.hp = player.max_hp
	for i in 70:
		await _seconds(0.1)
		player.velocity = Vector3.ZERO
		if boss.mode == Centipede.Mode.RECOVER:
			break
	_check(player.hp >= player.max_hp - 0.5, "quem saiu do anel a tempo não leva o aperto")

	# 6) Luta "de verdade": você corre pelo covil e ela mistura os golpes
	for ph in [1, 2]:
		boss.phase = ph
		boss._cd_burrow = 0.0
		boss._cd_spit = 0.0
		boss._cd_circle = 0.0
		_fight(c + Vector3(6.0, 0.05, 0.0))
		boss._to_hunt()
		player.invuln = 999.0
		player.autopilot = true
		player.auto_run = true
		var seen := {}
		var t := 0.0
		while t < 60.0:
			var a := t * 0.45
			var big := int(t / 10.0) % 2 == 0
			player.auto_target = c + Vector3(cos(a) * (9.0 if big else 5.0), 0.0, sin(a) * (6.0 if big else 3.5))
			await _seconds(0.1)
			t += 0.1
			seen[Centipede.Mode.keys()[boss.mode]] = true
			if boss.is_entangled():
				boss.entangled_time = 0.0
		var want := ["BURROW", "SPIT", "CHARGE"] + (["CIRCLE"] if ph == 2 else [])
		var miss := want.filter(func(k): return not seen.has(k))
		_check(miss.is_empty(), "fase %d: ela usa %s (faltou %s; viu %s)" % [ph, str(want), str(miss), str(seen.keys())])
	player.autopilot = false


func _pools() -> int:
	var n := 0
	for h in get_tree().get_nodes_in_group("hazard"):
		if h is AcidPuddle:
			n += 1
	return n


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
