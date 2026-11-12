extends Node
## Menu inicial e menu de pausa.
## Rodar:  godot --headless --path . res://tests/menu_test.tscn

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# o teste sobrevive às trocas de cena: sai da cena atual e fica pendurado na raiz
	reparent(get_tree().root)
	get_tree().current_scene = null
	GameState.delete_save()

	# sem save: Novo jogo, Controles, Sair
	var title = await _open_title()
	_check(_texts(title) == ["Novo jogo", "Controles", "Sair"], "sem save: %s" % [_texts(title)])
	title.show_controls()
	_check(_texts(title) == ["Voltar"] and title.box.get_child_count() >= 4, "tela de controles com a lista e Voltar")
	title.show_main()

	# Novo jogo -> Berçário
	title.new_game()
	await _frames(30)
	var scene := get_tree().current_scene
	_check(scene != null and scene.scene_file_path.ends_with("bercario.tscn"), "Novo jogo abre o Berçário")
	GameState.player.level = 3
	GameState.save_now()

	# Esc no jogo abre a pausa com o menu
	var hud: Hud = scene.hud
	hud.open_pause()
	_check(get_tree().paused and hud._pause_box.visible, "Esc pausa e mostra o menu")
	var pt := []
	for b in hud._pause_box.buttons():
		pt.append(b.text)
	_check(pt.has("Voltar ao jogo") and pt.has("Menu inicial") and pt.has("Sair do jogo"), "menu de pausa: %s" % [pt])
	hud.close_pause()
	_check(not get_tree().paused and not hud._pause_box.visible, "Voltar ao jogo despausa")

	# Menu inicial pela pausa
	hud.open_pause()
	GameState.to_title()
	await _frames(10)
	title = get_tree().current_scene
	_check(title != null and title.scene_file_path.ends_with("title.tscn") and not get_tree().paused, "Menu inicial pela pausa volta para a tela de título")
	_check(_texts(title) == ["Continuar", "Novo jogo", "Controles", "Sair"], "com save: %s" % [_texts(title)])
	_check(title.save_summary() == "Berçário · Filhote de Seda, nível 3", "resumo do save: %s" % title.save_summary())

	# Novo jogo com save pede confirmação; Voltar não apaga nada
	title.show_confirm_new()
	_check(_texts(title) == ["Sim, começar do zero", "Voltar"], "pede confirmação antes de apagar")
	title.show_main()
	_check(title.has_save(), "Voltar não apaga o save")

	# Continuar abre a camada do save
	title.continue_game()
	await _frames(40)
	scene = get_tree().current_scene
	_check(scene != null and scene.scene_file_path.ends_with("bercario.tscn") and scene.resumed and GameState.player.level == 3, "Continuar carrega o save (nível 3)")

	# Novo jogo de verdade apaga
	GameState.to_title()
	await _frames(10)
	get_tree().current_scene.new_game()
	await _frames(30)
	_check(GameState.player != null and GameState.player.level == 1 and GameState.player.form == Player.Form.FILHOTE, "Sim, começar do zero: nível 1, Filhote")
	_check(not get_tree().current_scene.resumed, "e não carrega o save antigo")

	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _open_title():
	get_tree().change_scene_to_file(GameState.TITLE_SCENE)
	await _frames(5)
	return get_tree().current_scene


func _texts(title) -> Array:
	var out := []
	for b in title.box.buttons():
		out.append(b.text)
	return out


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
