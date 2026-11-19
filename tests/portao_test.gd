extends Node
## Ato final, Portão da Superfície: câmaras, luz do dia, vento da ponte, o Guardião em 3 fases
## (pilar, teia de captura, escuro), o portão abrindo e o final.
## Rodar:  godot --headless --path . res://tests/portao_test.tscn

var failures := 0
var l
var p: Player


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	reparent(get_tree().root)
	get_tree().current_scene = null
	GameState.new_game()
	GameState.delete_save()
	await _frames(5)
	get_tree().change_scene_to_file("res://world/layers/portao.tscn")
	await _seconds(2.5)
	l = get_tree().current_scene
	p = GameState.player
	p.invuln = 9999.0
	_check(l.layer_name == "Portão da Superfície", "camada carregada")
	var ids: Array = l.rooms.map(func(r): return r["id"])
	_check(ids == ["P1", "P2", "P4", "P3", "P5", "P6", "P7", "P8"], "as 8 câmaras do mapa: %s" % [ids])
	_check(l.den != null and l.den.room_id == "P5", "a última toca é a Câmara do eco final")
	_check(get_tree().get_nodes_in_group("hunter").size() >= 8, "o acampamento grande tem caçadores")
	var g: Guardian = l.guardian
	_check(g != null and g.phase == 0, "o Guardião dorme na arena")
	_check(World.nav.walkable(g.global_position, NavGrid.Kind.LARGE), "o Guardião está em chão andável (grade dos grandes)")
	_check(Music.playing() == "mus_portao", "música do Portão: %s" % Music.playing())

	# luz do dia
	var beam := Vector3(28.5, 0.1, -14.5)
	var shade := Vector3(32.0, 0.1, -16.8)
	_check(l.daylight_at(beam) > 0.9 and l.daylight_at(shade) < 0.1, "fachos de luz e sombra entre eles (%.2f / %.2f)" % [l.daylight_at(beam), l.daylight_at(shade)])
	p.rune_on = false
	p.global_position = shade
	await _seconds(0.6)
	var vis_shade := p.visibility_mult()
	var sight_shade := p.sight_radius()
	p.global_position = beam
	await _seconds(0.9)
	_check(p.visibility_mult() > vis_shade * 2.5, "no facho, com a runa apagada, ela aparece de longe (%.2f > %.2f)" % [p.visibility_mult(), vis_shade])
	_check(p.sight_radius() > sight_shade + 5.0, "e enxerga longe")

	# vento da ponte
	p.global_position = Vector3(56, 0.1, -52.5)
	p.invuln = 0.0
	await _frames(3)
	l._wind_t = 5.85
	l._gust = 0.0
	var pushed := 0.0
	for i in 10:
		await get_tree().physics_frame
		pushed = maxf(pushed, p.external_velocity.x)
	p.invuln = 9999.0
	_check(l.is_gusting() and pushed > 2.0, "rajada na ponte empurra para o abismo (%.1f)" % pushed)

	# o Guardião acorda
	p.global_position = Vector3(56, 0.1, -82)
	await _seconds(0.6)
	_check(g.phase == 1, "entrar na arena acorda o Guardião")
	await _seconds(2.0)
	_check(Music.playing().begins_with("mus_boss_guardiao_1"), "música da fase 1: %s" % Music.playing())
	var hp0 := g.hp
	g.take_damage(100.0, p)
	_check(is_equal_approx(hp0 - g.hp, 25.0), "fase 1: as escamas seguram 75%% (%.0f)" % (hp0 - g.hp))
	# investida num pilar: atordoa
	var pillar: Vector3 = g.pillars[0]
	await _charge_at(g, pillar)
	_check(g.stun_t > 0.0, "investida no pilar: atordoado")
	hp0 = g.hp
	g.take_damage(100.0, p)
	_check(hp0 - g.hp > 120.0, "atordoado: golpe entra cheio (+25%)")
	g.stun_t = 0.0

	# fase 2
	g.take_damage(99999.0, p)
	_check(g.phase == 2 and absf(g.hp - g.max_hp * 0.66) < 1.0, "um golpe enorme não pula fase: para em 66% e muda (%.0f)" % g.hp)
	await _seconds(3.2)
	_check(Music.playing().begins_with("mus_boss_guardiao_2"), "música da fase 2: %s" % Music.playing())
	var rocks_seen := false
	for i in 30:
		await _frames(2)
		if not g._rocks.is_empty():
			rocks_seen = true
			break
	_check(rocks_seen, "pedras caindo com marca no chão")
	await _charge_at(g, pillar)
	_check(g.stun_t <= 0.0, "fase 2: ele freia antes do pilar (sem atordoar)")
	# teia de captura no caminho
	var mid := g.global_position.lerp(pillar, 0.5)
	mid.y = 0.0
	WebNetwork.create_trap(mid)
	await _charge_at(g, pillar)
	_check(g.stun_t > 0.0 and WebNetwork.traps.is_empty(), "fase 2: investida por cima da teia de captura → enroscado")
	g.stun_t = 0.0

	# fugiu da arena: ele volta para o portão e a vida volta ao começo da fase (a fase fica vencida)
	g.take_damage(60.0, p)
	var low := g.hp
	p.global_position = Vector3(56, 0.1, -40)
	await _seconds(6.0)
	_check(g.phase == 2 and g.hp > low and absf(g.hp - g.max_hp * 0.66) < 1.0, "fugiu: ele se recompõe até o começo da fase 2 (%.0f)" % g.hp)
	_check(g.cur_attack == null and not g.noticed_player, "e não sai caçando pela camada")
	p.global_position = Vector3(56, 0.1, -84)
	await _seconds(0.3)

	# fase 3
	g.take_damage(99999.0, p)
	_check(g.phase == 3, "fase 3")
	await _seconds(3.0)
	_check((l._arena_lights[0] as OmniLight3D).light_energy < 0.5, "a poeira apaga a arena")
	# some: longe, parada, runa apagada
	p.rune_on = false
	p.velocity = Vector3.ZERO
	p.global_position = g.global_position + Vector3(0, 0, 13.0)
	g.cancel_attack()
	g.player_memory = 0.0
	g.last_player_pos = g.global_position + Vector3(6, 0, 0)
	g.roar_t = 0.0
	g._found_t = -1.0
	await _seconds(0.5)
	_check(g.sniffing, "perdeu ela: fareja")
	g.face_toward(g.global_position + Vector3(10, 0, 0))
	var behind := g.global_position - g.facing * 4.0
	p.global_position = behind
	hp0 = g.hp
	var src := Node3D.new()
	add_child(src)
	src.global_position = behind
	src.add_to_group("player")
	g.take_damage(40.0, src)
	_check(is_equal_approx(hp0 - g.hp, 80.0), "farejando, golpe por trás entra dobrado (%.0f)" % (hp0 - g.hp))
	src.queue_free()

	# cai, o portão abre
	g.take_damage(99999.0, p)
	await _seconds(0.5)
	_check(GameState.flags.has("p7_guardiao"), "o Guardião cai")
	await _seconds(3.5)
	_check(l._gate_body == null, "o portão abre")
	_check(l.daylight_at(Vector3(56, 0, -118)) > 0.5, "luz do dia de verdade na saída")
	_check(Bestiary.tier("guardiao") >= Bestiary.DEFEATED, "Guardião no bestiário")

	# o final
	p.global_position = Vector3(56, 0.1, -124)
	var e: Node = null
	for i in 80:
		await _seconds(0.1)
		var f := get_tree().root.get_children().filter(func(n): return n is Ending)
		if not f.is_empty():
			e = f[0]
			break
	_check(e != null and GameState.flags.has("fim_jogo"), "sair pela boca da caverna: o final")
	if e != null:
		_check(e.data["form"] == p.form_name(), "o final conhece a forma dela")
		e._t = 20.0
		for i in 9:
			e.advance()
		_check(await _wait_scene("title.tscn"), "depois dos créditos, volta ao menu")
	_end()


func _charge_at(g: Guardian, target: Vector3) -> void:
	## Coloca o Guardião a ~9 m do alvo, de frente, e força a investida.
	var away := (g.global_position - target)
	away.y = 0.0
	away = away.normalized() if away.length() > 0.1 else Vector3(0, 0, 1)
	g.cancel_attack()
	g.global_position = target + away * 9.5
	g.velocity = Vector3.ZERO
	g.roar_t = 0.0
	g.stun_t = 0.0
	p.global_position = target - away * 2.5
	await _frames(2)
	g.face_toward(target)
	g.start_attack(g.find_attack("investida"), p)
	for i in 80:
		await _seconds(0.05)
		if g.stun_t > 0.0 or g.cur_attack == null:
			break


func _wait_scene(file: String) -> bool:
	for i in 200:
		await _seconds(0.1)
		var sc = get_tree().current_scene
		if sc != null and String(sc.scene_file_path).ends_with(file):
			return true
	return false


func _end() -> void:
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout
