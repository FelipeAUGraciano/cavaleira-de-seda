extends Node
## Menu do casulo: habilidades (regras e efeitos), despensa, save e o próprio menu.
## Rodar:  godot --headless --path . res://tests/casulo_test.tscn

var player: Player
var layer
var failures := 0


func _ready() -> void:
	GameState.permadeath = false
	GameState.delete_save()
	layer = load("res://world/layers/test_chamber.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	for c in World.creatures.duplicate():
		c.queue_free()
	await _frames(2)
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _run() -> void:
	# pontos por nível
	_check(player.skill_points == 0 and player.has_skill("fiandeira"), "começa com 0 pontos e a Fiandeira")
	player.gain_xp(player.xp_to_next())
	_check(player.skill_points == 1, "subir de nível dá 1 ponto")

	# regras da teia
	_check(player.skill_block("investida") == "Bloqueada", "nó sem ligação aprendida fica bloqueado")
	_check(player.skill_block("afiadas") == "", "nó ligado ao centro dá para aprender")
	player.skill_points = 0
	_check(player.skill_block("afiadas") == "Pontos insuficientes", "sem pontos não aprende")
	player.skill_points = 20
	_check(player.learn("afiadas") and player.skill_points == 19, "aprender gasta o custo")
	_check(player.skill_block("espiral").begins_with("Precisa ser"), "Corte em Espiral pede a Cavaleira")
	_check(player.skill_block("tecela") == "", "diagonal abre com um dos dois braços")

	# efeitos
	_check(is_equal_approx(player.strand_cost(), 5.0), "fio-guia custa 5")
	player.learn("fio_leve")
	_check(is_equal_approx(player.strand_cost(), 3.0), "Fio Leve: fio-guia custa 3")
	player.learn("puxao")
	_check(is_equal_approx(player.throw_range(), Player.THROW_RANGE * 1.5), "Puxão: lançar fio vai 50% mais longe")
	var hp0 := player.max_hp
	player.learn("carapaca")
	_check(is_equal_approx(player.max_hp, hp0 + 15.0), "Carapaça: +15 PV máx")
	var s0 := player.sight_radius()
	player.learn("runa_oculta")
	player.learn("pulso")
	player.learn("olhos")
	_check(is_equal_approx(player.sight_radius(), s0 + 1.5), "Olhos de Cristal: +1,5 m de visão")
	# Runa Oculta: energia volta com a runa apagada
	player.rune_on = false
	player.energy = 10.0
	player.energy_delay = 0.0
	await _seconds(0.5)
	_check(player.energy > 10.5, "Runa Oculta: energia volta com a runa apagada (%.1f)" % player.energy)
	# Pulso Espiral: reacender a runa atordoa um bicho perto
	var larva := Larva.new()
	larva.position = player.global_position + Vector3(2.0, 0.3, 0.0)
	layer.ecosystem.add_child(larva)
	await _frames(3)
	player.energy = 50.0
	player._toggle_rune()
	_check(player.rune_on and larva.is_entangled() and player.energy < 31.0, "Pulso Espiral: atordoa a larva perto e gasta 20 de Energia")

	# despensa
	larva.die()
	await _frames(3)
	player.silk = 50.0
	var n := player.wrap_nearby()
	_check(n == 1 and player.pantry.size() == 1 and is_equal_approx(player.silk, 40.0), "embrulhar a presa: vai para a despensa e custa 10 de Seda")
	player.satiety = 10.0
	_check(player.eat_from_pantry(0) and player.satiety > 10.0 and player.pantry.is_empty(), "comer da despensa")

	# save
	player.pantry = [{"name": "Larva-de-musgo", "sat": 20.0, "silk": 10.0}]
	var d := player.to_dict()
	var fresh := {"level": 5, "form": 0}
	var q := Player.new()
	add_child(q)
	await _frames(1)
	GameState.player = player   # o Player novo se registrou como a jogadora; devolve
	q.from_dict(d)
	_check(q.has_skill("olhos") and q.skill_points == player.skill_points and q.pantry.size() == 1, "habilidades, pontos e despensa vão para o save")
	q.skill_points = 0
	q.skills = {"fiandeira": true}
	q.from_dict(fresh)
	_check(q.skill_points == 4, "save antigo ganha os pontos dos níveis que já tinha (%d)" % q.skill_points)
	q.queue_free()

	# o menu
	var cocoon := WebNetwork.create_cocoon(player.global_position + Vector3(0, 0, -1.6))
	await _frames(3)
	player.global_position = cocoon.global_position + Vector3(0, 0.1, 1.4)
	player.hp = 20.0
	player._interact()
	await _frames(3)
	var m: CocoonMenu = layer.hud.cocoon_menu
	_check(m != null and m.visible and get_tree().paused, "E no casulo abre o menu e pausa")
	player.skill_points = 2
	var pts := player.skill_points
	m._select("sangue_frio")
	m._press_node("sangue_frio")
	_check(player.has_skill("sangue_frio") and player.skill_points == pts - 2, "selecionar e apertar de novo aprende")
	m._show_tab("evo")
	m._show_tab("desp")
	_check(m._page_btns.size() == 2, "despensa: botão Comer + Embrulhar")
	m.close()
	await _frames(2)
	_check(not m.visible and not get_tree().paused and player.hp < 21.0, "Sair (Esc) fecha sem descansar")
	player._interact()
	await _frames(2)
	m.rest()
	await _frames(2)
	_check(is_equal_approx(player.hp, player.max_hp) and GameState.has_save(), "Descansar cura e salva")


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
