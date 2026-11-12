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
	for k in range(1, GameState.SLOTS + 1):
		GameState.delete_save(k)
	GameState.slot = 1

	# sem save: Novo jogo, Opções, Sair
	var title = await _open_title()
	_check(_texts(title) == ["Novo jogo", "Opções", "Sair"], "sem save: %s" % [_texts(title)])
	title.show_slots("new")
	_check(_texts(title).size() == 4 and String(_texts(title)[0]).contains("vazio"), "Novo jogo mostra os 3 espaços: %s" % [_texts(title)])
	title.show_main()

	# Novo jogo -> Berçário (espaço 1)
	title._pick_slot("new", 1)
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
	_check(pt.has("Voltar ao jogo") and pt.has("Opções") and pt.has("Menu inicial") and pt.has("Sair do jogo"), "menu de pausa: %s" % [pt])
	hud.open_options()
	_check(hud._options.visible and not hud._pause_box.visible and get_tree().paused, "Opções na pausa")
	hud._options.close()
	_check(hud._pause_box.visible and get_tree().paused, "fechar Opções volta para a pausa")
	hud.close_pause()
	_check(not get_tree().paused and not hud._pause_box.visible, "Voltar ao jogo despausa")

	# Menu inicial pela pausa
	hud.open_pause()
	GameState.to_title()
	await _frames(10)
	title = get_tree().current_scene
	_check(title != null and title.scene_file_path.ends_with("title.tscn") and not get_tree().paused, "Menu inicial pela pausa volta para a tela de título")
	_check(_texts(title) == ["Continuar", "Novo jogo", "Carregar", "Opções", "Sair"], "com save: %s" % [_texts(title)])
	_check(title.save_summary() == "Berçário · Filhote de Seda, nível 3", "resumo do save: %s" % title.save_summary())
	title.show_slots("load")
	var lt := _texts(title)
	_check(String(lt[0]).contains("nível 3") and title.box.buttons()[1].disabled and title.box.buttons()[2].disabled, "Carregar: só o espaço 1 tem save: %s" % [lt])
	title.show_main()

	# Novo jogo com save pede confirmação; Voltar não apaga nada
	title._pick_slot("new", 1)
	_check(_texts(title) == ["Sim, começar do zero", "Voltar"], "pede confirmação antes de apagar")
	title.show_main()
	_check(title.has_save(), "Voltar não apaga o save")

	# Opções: abre, troca uma tecla (com troca de lugar), muda volume, fecha
	title.show_options()
	_check(title.options.visible and not title.box.visible, "Opções abre por cima do menu")
	var old_dodge := Settings.text("dodge")
	var q := InputEventKey.new()
	q.physical_keycode = KEY_Q
	var swapped := Settings.bind("dodge", false, q)
	_check(Settings.text("dodge") == "Q" and Settings.text("throw_silk") == old_dodge and swapped != "", "trocar esquiva para Q devolve %s ao lançar fio" % old_dodge)
	_check(Hud.help_lines()[3].begins_with("Q esquiva"), "lista de controles usa a tecla nova: %s" % Hud.help_lines()[3])
	Settings.set_value("Master", 0.5)
	_check(absf(AudioServer.get_bus_volume_db(0) - linear_to_db(0.5)) < 0.01, "volume geral vai para o bus Master")
	_check(AudioServer.get_bus_index("Voz") >= 0 and Voice._player.bus == &"Voz", "dublagem toca no bus Voz")
	Settings.load_cfg()
	_check(Settings.text("dodge") == "Q", "a troca de tecla fica guardada")
	title.options.show_page("controles")
	# troca pela tela: clica em "Mapa" (teclado) e aperte N
	var row := -1
	for i in Settings.REMAP.size():
		if Settings.REMAP[i][0] == "map":
			row = i
	var grid = title.options._body.get_child(0).get_child(0)
	var mb: Button = grid.get_child(3 + row * 3 + 1)
	mb.pressed.emit()
	_check(Settings.capturing and mb.text.begins_with("Aperte"), "botão de tecla espera a tecla nova")
	await get_tree().create_timer(0.25).timeout
	var nk := InputEventKey.new()
	nk.physical_keycode = KEY_N
	nk.pressed = true
	title.options._input(nk)
	_check(not Settings.capturing and Settings.text("map") == "N", "apertar N troca o Mapa para N")
	title.options._start_capture("map", false, title.options._body.get_child(0).get_child(0).get_child(3 + row * 3 + 1))
	await get_tree().create_timer(0.25).timeout
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	title.options._input(esc)
	_check(not Settings.capturing and Settings.text("map") == "N", "Esc cancela a troca")
	title.options.show_page("tela")
	title.options.show_page("som")
	title.options.close()
	_check(not title.options.visible and title.box.visible, "Voltar das Opções volta ao menu")
	Settings.reset_controls()
	Settings.set_value("Master", 0.8)
	_check(Settings.text("dodge") == "Espaço", "restaurar controles padrão")

	# Continuar abre a camada do save
	title.continue_game()
	await _frames(40)
	scene = get_tree().current_scene
	_check(scene != null and scene.scene_file_path.ends_with("bercario.tscn") and scene.resumed and GameState.player.level == 3, "Continuar carrega o save (nível 3)")

	# Novo jogo no espaço 2 não mexe no espaço 1
	GameState.to_title()
	await _frames(10)
	get_tree().current_scene._pick_slot("new", 2)
	await _frames(30)
	GameState.save_now()
	_check(GameState.slot == 2 and GameState.has_save(1) and GameState.has_save(2), "espaço 2 novo, espaço 1 continua lá")
	GameState.delete_save(2)
	GameState.slot = 1

	# Novo jogo de verdade apaga
	GameState.to_title()
	await _frames(10)
	get_tree().current_scene.new_game()
	await _frames(30)
	_check(GameState.player != null and GameState.player.level == 1 and GameState.player.form == Player.Form.FILHOTE, "Sim, começar do zero: nível 1, Filhote")
	_check(not get_tree().current_scene.resumed, "e não carrega o save antigo")

	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	Settings.set_value("espaco", 1)
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
