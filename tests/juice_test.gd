extends Node
## Sensação dos golpes (Juice) e o tocador de música (Music), sem arquivos de música.
## Rodar:  godot --headless --path . res://tests/juice_test.tscn

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


func _labels() -> int:
	var n := 0
	for k in layer.find_children("*", "Label3D", true, false):
		if is_instance_valid(k):
			n += 1
	return n


func _run() -> void:
	var base := player.global_position
	var b := Beetle.new()
	b.position = base + Vector3(1.5, 0.2, 0)
	layer.ecosystem.add_child(b)
	await _frames(3)
	b.max_hp = 200.0
	b.hp = 200.0
	b.speed = 0.0
	# números de dano e faíscas
	Settings.damage_numbers = true
	var l0 := _labels()
	player.hit_creature(b, 12.0)
	await _frames(2)
	_check(_labels() > l0, "golpe mostra número de dano")
	_check(layer.find_children("*", "CPUParticles3D", true, false).size() > 0, "golpe solta faíscas")
	_check(b._flinch > 0.0, "o bicho recua ao levar o golpe")
	Settings.damage_numbers = false
	await _seconds(1.0)
	var l1 := _labels()
	player.hit_creature(b, 12.0)
	await _frames(2)
	_check(_labels() == l1, "Opções: números de dano desligados")
	Settings.damage_numbers = true
	await _seconds(0.4)
	var vis := b._visual
	_check(is_equal_approx(vis.scale.y, b._vis_base.y), "o recuo volta ao tamanho normal")
	# morte: o corpo tomba e some, o cadáver assenta
	b.take_damage(999.0, player)
	await _frames(2)
	_check(is_instance_valid(vis) and vis.get_parent() == layer.ecosystem.get_parent() or (is_instance_valid(vis) and vis.get_parent() != null), "na morte, o modelo fica tombando no chão")
	await _seconds(0.9)
	_check(not is_instance_valid(vis), "o modelo da morte some")
	_check(World.corpses.size() > 0, "o cadáver fica no lugar")
	# pausa no impacto (desligada no modo sem tela)
	Juice.hitstop(0.1)
	_check(Engine.time_scale == 1.0, "sem tela, a pausa no impacto não trava os testes")
	# tremor
	Settings.screen_shake = false
	player._shake = 0.0
	player.shake(0.5)
	_check(player._shake == 0.0, "Opções: tremor desligado")
	Settings.screen_shake = true
	# música (sem arquivos: segue em silêncio, sem erro)
	Music.area("galerias")
	_check(Music.playing() == "mus_galerias", "música do mapa escolhida")
	await _frames(2)
	_check(Music._a.stream != null and Music._t.stream != null, "achou mus_galerias.ogg e a camada de tensão")
	if Music._a.stream != null and Music._t.stream != null:
		_check(absf(Music._a.stream.get_length() - Music._t.stream.get_length()) < 0.01 and Music._a.stream.loop, "base e tensão do mesmo tamanho, em loop")
	var boss := Beetle.new()
	boss.position = base + Vector3(6, 0.2, 0)
	boss.boss_music = "teste"
	layer.ecosystem.add_child(boss)
	await _frames(3)
	boss.speed = 0.0
	boss.max_hp = 500.0
	boss.hp = 499.0   # já apanhou: a luta começou (noticed_player pode mudar com a IA do bicho)
	await _seconds(0.5)
	_check(Music.playing() == "mus_boss_teste", "chefe em luta troca a música")
	boss.take_damage(9999.0, player)
	await _seconds(0.6)
	_check(Music.playing() == "mus_galerias", "chefe morto: volta à música do mapa")
	Music.boss("centopeia")
	_check(Music._a.stream != null and Music._a.stream.get_length() < 10.0 and not Music._a.stream.loop, "chefe com intro: toca a intro antes do loop")
	Music.end_boss(true)
	await _frames(2)
	_check(Music._sting.stream != null and Music._sting.playing, "chefe vencido: toca a vitória")
	Music.area("nao_existe")
	await _frames(2)
	_check(Music._a.stream == null, "faixa que não existe: silêncio, sem erro")
	Music.area("galerias")
	Music.cocoon(true)
	_check(Music.playing() == "mus_casulo", "casulo aberto: música do casulo")
	Music.cocoon(false)
	_check(Music.playing() == "mus_galerias", "casulo fechado: volta ao mapa")
	Music.area("")


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
