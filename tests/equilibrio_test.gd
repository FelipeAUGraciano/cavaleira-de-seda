extends Node
## Equilíbrio (24/11): teto de nível por andar, força e vida menores a cada muda,
## bichos mais duros e mais fortes nos andares fundos.
## Rodar:  godot --headless --path . res://tests/equilibrio_test.tscn

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	reparent(get_tree().root)
	get_tree().current_scene = null
	GameState.new_game()
	GameState.delete_save()
	await _frames(5)
	get_tree().change_scene_to_file("res://world/layers/galerias.tscn")
	await _seconds(2.5)
	var p: Player = GameState.player
	_check(p.level_cap() == 8, "Galerias: teto no nível 8")
	p.level = 7
	p.xp = 0
	p.gain_xp(p.xp_to_next())
	_check(p.level == 8 and p.at_level_cap() and p.xp == 0, "chegou no 8: teto do andar")
	p.gain_xp(500)
	_check(p.level == 8 and p.xp == 0, "no teto, a experiência não conta mais")
	_check(GameState.said.has("teto_8"), "ela avisa que o andar não ensina mais")
	_check(p.can_evolve(), "mas a muda para Cavaleira continua liberada")
	p.evolve()
	_check(p.form == Player.Form.CAVALEIRA and p.total_level() == 8 and p.at_level_cap(), "Cavaleira nível 1 = nível 8 da vida: ainda no teto")
	p.gain_xp(200)
	_check(p.level == 1, "Cavaleira não sobe mais nas Galerias")
	_check(is_equal_approx(p.max_hp, 90.0 * 0.85), "Cavaleira: vida x0,85 (%.1f)" % p.max_hp)
	_check(is_equal_approx(p.power(), 0.8), "Cavaleira: golpes x0,8")
	var c := Beetle.new()
	c.position = p.global_position + Vector3(30, 0.3, 0)
	get_tree().current_scene.ecosystem.add_child(c)
	await _frames(3)
	c.max_hp = 500.0
	c.hp = 500.0
	var dealt := p.hit_creature(c, 10.0)
	_check(is_equal_approx(dealt, 8.0), "golpe de 10 entra 8 (%.1f)" % dealt)
	var before := p.hp
	p.invuln = 0.0
	p.take_damage(10.0, c)
	_check(is_equal_approx(before - p.hp, 10.0), "Galerias: bicho bate normal")
	# Abismo: teto 17, bichos mais duros e mais fortes
	get_tree().change_scene_to_file("res://world/layers/abismo.tscn")
	await _seconds(3.0)
	p = GameState.player
	p.form = Player.Form.CAVALEIRA
	p.level = 1
	p.recompute_stats(true)
	_check(p.level_cap() == 17 and not p.at_level_cap(), "Abismo: teto 17, dá para crescer de novo")
	p.gain_xp(99999)
	_check(p.level == 10 and p.total_level() == 17 and p.at_level_cap(), "no Abismo a Cavaleira vai até o 10 (%d)" % p.level)
	var b := Beetle.new()
	b.position = p.global_position + Vector3(30, 0.3, 0)
	get_tree().current_scene.ecosystem.add_child(b)
	await _frames(3)
	var base_hp := Beetle.new()
	_check(is_equal_approx(b.max_hp, base_hp.max_hp * 1.25), "Abismo: bichos com 25%% mais vida (%.0f)" % b.max_hp)
	base_hp.free()
	before = p.hp
	p.invuln = 0.0
	p.take_damage(10.0, b)
	_check(is_equal_approx(before - p.hp, 13.5), "Abismo: bicho bate 35%% mais forte (%.1f)" % (before - p.hp))
	before = p.hp
	p.invuln = 0.0
	p.take_damage(10.0, null)
	_check(is_equal_approx(before - p.hp, 10.0), "queda, fogo e armadilha não mudam")
	# formas finais: menos vida e força
	p.form = Player.Form.EXECUTORA
	p.level = 1
	p.recompute_stats(true)
	_check(is_equal_approx(p.max_hp, 210.0 * 0.7) and is_equal_approx(p.power(), 0.62), "forma final: vida x0,7 e golpes x0,62")
	_end()


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
