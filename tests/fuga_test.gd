extends Node
## Fim do prólogo: a fuga pelo túnel (cena), a tela de carregamento e a chegada nas Galerias
## com o nome da área. Rodar:  godot --headless --path . res://tests/fuga_test.tscn

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	reparent(get_tree().root)          # sobrevive às trocas de cena
	get_tree().current_scene = null
	GameState.new_game()
	GameState.delete_save()
	await _frames(5)
	get_tree().change_scene_to_file("res://world/layers/bercario.tscn")
	await _seconds(1.0)
	var layer = get_tree().current_scene
	var player: Player = GameState.player
	player.invuln = 999.0
	layer._chase_started = true
	layer.chase.begin()
	player.global_position = Vector3(114.0, 0.1, 1.0)
	player.velocity = Vector3.ZERO
	var started := false
	for i in 120:
		player.global_position.x = minf(player.global_position.x + 0.05, 117.0)
		await get_tree().physics_frame
		if player.autopilot:
			started = true
			break
	_check(started and layer.hud.cinematic, "chegou na saída: a cena começa (faixas pretas, ela corre sozinha)")
	_check(layer.chase.visible and layer.chase.finished, "a Mãe bate na boca do túnel")
	var x0 := player.global_position.x
	await _seconds(1.2)
	_check(player.global_position.x > x0 + 3.0, "ela dispara túnel adentro (%.1f m)" % (player.global_position.x - x0))
	var ls: Node = null
	for i in 100:
		await _seconds(0.1)
		var found := get_tree().get_nodes_in_group("loading_screen")
		if not found.is_empty():
			ls = found[0]
			break
	_check(ls != null, "a tela escurece e vem a tela de carregamento")
	if ls != null:
		_check(ls.header == "Fim do prólogo", "com o 'Fim do prólogo' em cima")
		var p0: float = ls.progress()
		await _seconds(1.0)
		_check(is_instance_valid(ls) and ls.progress() > p0, "a teia do carregamento vai sendo tecida (%.0f%%)" % (ls.progress() * 100.0))
	var arrived := false
	for i in 150:
		await _seconds(0.1)
		var sc = get_tree().current_scene
		if sc != null and String(sc.scene_file_path).ends_with("galerias.tscn"):
			arrived = true
			break
	_check(arrived, "chega nas Galerias")
	if not arrived:
		return _end()
	await _frames(5)
	var g = get_tree().current_scene
	player = GameState.player
	_check(player.autopilot and g.hud.cinematic, "entra correndo, ainda em cena")
	await _seconds(1.5)
	_check(g.hud._area == "Galerias Úmidas" and g.hud._area_time > 0.0, "o nome da área aparece em cima, à la Elden Ring")
	var free := false
	for i in 80:
		await _seconds(0.1)
		if not player.autopilot:
			free = true
			break
	_check(free and not g.hud.cinematic, "depois o controle volta")
	_check(Fx.flat_dist(player.global_position, g.spawn_point) < 1.5, "ela para no começo da camada")
	await _seconds(1.5)
	_check(get_tree().get_nodes_in_group("loading_screen").is_empty(), "a tela de carregamento some")
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
	await get_tree().create_timer(s).timeout
