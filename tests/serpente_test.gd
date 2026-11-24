extends Node
## Serpente-cega, a caçadora do silêncio: sibilo (eco + derruba do fio), constrição (aperte
## para soltar, escamas abrem), onda de tremor da cauda (fio salva), fase 3 de calor + vapor.
## Rodar:  godot --headless --path . res://tests/serpente_test.tscn

var layer
var player: Player
var sp: Serpent
var failures := 0


func _ready() -> void:
	GameState.permadeath = false
	GameState.delete_save()
	GameState.said = {}
	GameState.flags = {"g14_centopeia": true, "a1_queda": true}
	layer = load("res://world/layers/abismo.tscn").instantiate()
	add_child(layer)
	await _seconds(7.0)   # cena da queda
	player = GameState.player
	player.autopilot = false
	player.max_hp = 999.0
	sp = layer.serpent
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _reset(at: Vector3) -> void:
	sp.entangled_time = 0.0
	sp.open_time = 0.0
	sp.global_position = at
	sp.velocity = Vector3.ZERO
	sp.mode = Serpent.Mode.PROWL
	sp.mode_time = 0.0
	sp.vib_age = 99.0
	player.hp = player.max_hp
	player.invuln = 0.0


func _run() -> void:
	var c := Vector3(layer.ARENA.x, 0.0, layer.ARENA.y)
	_teleport(c + Vector3(0, 0.1, -7))
	await _seconds(0.5)
	sp.wake()
	_check(sp.awake, "a Serpente acorda")

	# 1) Sibilo: parada num fio, ela sibila, o eco te acha e o fio te derruba
	var s := WebNetwork.create_strand(WebNetwork.anchors["A12_0"], WebNetwork.anchors["A12_3"])
	var sm := (s.a_pos + s.b_pos) * 0.5
	_teleport(Vector3(sm.x, 0.1, sm.z))
	await _frames(3)
	_check(player.on_strand and not sp.feels(player), "parada num fio: ela não te sente")
	_reset(c + Vector3(-4.0, 0.3, 2.0))   # longe dos pilares e do fio
	sp._cd_hiss = 0.0
	var hissed := false
	for i in 120:
		await _frames(2)
		if sp.mode == Serpent.Mode.HISS and sp._hit:
			hissed = true
			break
	_check(hissed, "você sumiu: ela sibila")
	await _frames(2)
	_check(sp.vib_age < 1.0, "o eco te acha")
	_check(player.external_velocity.length() > 3.0 and player._slow_time > 0.0, "o sibilo sacode o fio e te joga no chão")
	if is_instance_valid(s):
		WebNetwork.remove_strand(s)

	# 2) Constrição: o bote te pega, ela te enrola; apertando, você solta e as escamas abrem
	await _seconds(1.0)
	_teleport(c + Vector3(-3.0, 0.1, 0.0))
	_reset(c + Vector3(3.0, 0.3, 0.0))
	sp.face_toward(player.global_position)
	sp._begin(Serpent.Mode.WINDUP)
	sp._lunge_len = 7.0
	sp.mode_time = 2.0
	var held := false
	for i in 60:
		await _frames(1)
		player.velocity = Vector3.ZERO
		if player.held_by == sp:
			held = true
			break
	_check(held and sp.mode == Serpent.Mode.COIL, "o bote te pega: enrolada")
	var p0 := player.global_position
	var hp0 := player.hp
	await _seconds(1.2)
	_check(player.hp < hp0 and Fx.flat_dist(player.global_position, p0) < 0.3, "enrolada você não sai do lugar e perde vida (%.0f PV, %.2f m)" % [hp0 - player.hp, Fx.flat_dist(player.global_position, p0)])
	for i in 7:
		player.struggle()
		await _frames(4)
	_check(player.held_by == null and sp.open_time > 0.0, "apertando, você se solta e ela fica tonta")
	var shp := sp.hp
	sp.take_damage(20.0, player)
	_check(absf((shp - sp.hp) - 20.0) < 0.5, "tonta, as escamas abertas: dano cheio")
	await _seconds(Serpent.OPEN_TIME + 0.2)
	shp = sp.hp
	sp.take_damage(20.0, player)
	_check(absf((shp - sp.hp) - 6.0) < 0.5, "depois fecham de novo (70%% seguram)")
	# sem apertar: ela solta sozinha depois de um tempo
	await _seconds(0.5)
	_teleport(c + Vector3(-3.0, 0.1, 0.0))
	_reset(c + Vector3(3.0, 0.3, 0.0))
	sp.face_toward(player.global_position)
	sp._begin(Serpent.Mode.WINDUP)
	sp._lunge_len = 7.0
	sp.mode_time = 2.0
	await _seconds(0.5)
	_check(player.held_by == sp, "enrolada de novo")
	await _seconds(Serpent.COIL_MAX + 0.3)
	_check(player.held_by == null and sp.open_time <= 0.0, "sem lutar ela solta sozinha, sem abrir as escamas")
	_teleport(c + Vector3(-3.0, 0.1, 0.0))
	_reset(c + Vector3(3.0, 0.3, 0.0))
	player.invuln = 999.0
	sp.face_toward(player.global_position)
	sp._begin(Serpent.Mode.WINDUP)
	sp._lunge_len = 7.0
	sp.mode_time = 2.0
	await _seconds(0.5)
	_check(player.held_by == null, "esquivando (invulnerável) o bote não te enrola")

	# 3) Fase 2: onda de tremor; num fio você passa por cima
	await _seconds(1.0)
	sp.phase = 2
	_teleport(c + Vector3(-6.0, 0.1, 0.0))
	_reset(c + Vector3(0.0, 0.3, 0.0))
	sp._cd_slam = 999.0
	sp.mode = Serpent.Mode.RECOVER
	sp.mode_time = -5.0
	sp._slam()
	var hp1 := player.hp
	await _seconds(1.5)
	_check(player.hp < hp1, "a onda de tremor te pega no chão (%.0f PV)" % (hp1 - player.hp))
	sp.global_position = c + Vector3(-4.0, 0.3, 2.0)   # longe da linha do fio
	await _frames(2)
	var s2 := WebNetwork.create_strand(WebNetwork.anchors["A12_0"], WebNetwork.anchors["A12_3"])
	var sm2 := (s2.a_pos + s2.b_pos) * 0.5
	_teleport(Vector3(sm2.x, 0.1, sm2.z))
	await _frames(3)
	player.hp = player.max_hp
	player.invuln = 0.0
	sp._slam()
	await _seconds(1.5)
	_check(player.hp >= player.max_hp - 0.5, "num fio, a onda passa por baixo")
	if is_instance_valid(s2):
		WebNetwork.remove_strand(s2)
	# a fase 2 usa a batida sozinha quando você está por perto
	_teleport(c + Vector3(-5.0, 0.1, 0.0))
	_reset(c + Vector3(1.0, 0.3, 0.0))
	sp._cd_slam = 0.0
	sp.mode_time = 1.0
	var slammed := false
	for i in 90:
		await _frames(2)
		player.velocity = Vector3.ZERO
		if sp.mode == Serpent.Mode.SLAM:
			slammed = true
			break
	_check(slammed, "furiosa, ela bate a cauda sozinha")

	# 4) Fase 3: calor. Parada não basta; o vapor esconde
	await _seconds(2.0)
	player.invuln = 999.0
	sp.mode = Serpent.Mode.RECOVER
	sp.mode_time = -10.0
	sp.global_position = c + Vector3(2.0, 0.3, 0.0)
	sp.hp = sp.max_hp * 0.36
	sp.open_time = 1.0
	sp.take_damage(20.0, player)
	_check(sp.phase == 3, "com um terço da vida: fase 3")
	_check(sp.vents.size() >= 3, "o chão racha e abre jatos de vapor (%d)" % sp.vents.size())
	_teleport(sp.global_position + Vector3(-6.0, 0.1, 0.0))
	await _frames(3)
	player.velocity = Vector3.ZERO
	_check(sp.feels(player), "parada a 6 m: ela sente o seu calor")
	var v: Node3D = sp.vents[0]
	for i in 60:
		if sp.vent_on(v):
			break
		await _frames(5)
	_teleport(v.global_position + Vector3(0.3, 0.1, 0.0))
	sp.global_position = v.global_position + Vector3(5.0, 0.3, 0.0)
	await _frames(2)
	_check(sp.vent_on(v) and not sp.feels(player), "dentro do jato de vapor ela não te sente")
	# luta "de verdade" em cada fase: corre um pouco, para um pouco
	for ph in [1, 2, 3]:
		sp.phase = ph
		_teleport(c + Vector3(-5.0, 0.1, 0.0))
		_reset(c + Vector3(4.0, 0.3, 0.0))
		sp._cd_hiss = 0.0
		sp._cd_slam = 0.0
		var seen := {}
		var t := 0.0
		player.autopilot = true
		player.auto_run = true
		while t < 36.0:
			var moving := int(t / 5.0) % 2 == 0
			var a := t * 0.5
			player.auto_target = c + Vector3(cos(a) * 6.0, 0.0, sin(a) * 4.0) if moving else player.global_position
			if player.held_by == sp and int(t * 10.0) % 3 == 0:
				player.struggle()
			player.hp = player.max_hp
			await _seconds(0.1)
			t += 0.1
			seen[Serpent.Mode.keys()[sp.mode]] = true
			if sp.is_entangled():
				sp.entangled_time = 0.0
		player.autopilot = false
		var want := [["LUNGE", "HISS"], ["LUNGE", "SLAM"], ["LUNGE", "SLAM"]][ph - 1] as Array
		var miss := want.filter(func(k): return not seen.has(k))
		_check(miss.is_empty() and sp.hp > 0.0, "fase %d: ela usa %s (faltou %s; viu %s)" % [ph, str(want), str(miss), str(seen.keys())])
	player.held_by = null
	var vs := sp.vents.duplicate()
	sp.take_damage(9999.0, player)
	await _seconds(0.5)
	_check(GameState.flags.has("a12_serpente") and vs.all(func(n): return not is_instance_valid(n)), "a Serpente cai e o vapor some com ela")


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _teleport(pos: Vector3) -> void:
	if player.dead:
		player._respawn()
	player.held_by = null
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.external_velocity = Vector3.ZERO
	player.last_safe_pos = pos


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(int(s * 60.0))
