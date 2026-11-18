extends Node
## Última muda: o menu do casulo no ramo (antes e na hora de escolher, com uma rara em foco),
## a forma final e as 11 formas novas lado a lado.
## Uso: godot --path . res://tests/screenshot_evolucao.tscn -- <pasta>

var out := "user://shots"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	GameState.permadeath = false
	GameState.delete_save()
	var layer = load("res://world/layers/test_chamber.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	for c in World.creatures.duplicate():
		c.queue_free()
	var p: Player = GameState.player
	p.form = Player.Form.LAMINA
	p.level = 6
	p.recompute_stats(true)
	p._apply_form_visual()
	await _frames(30)
	var cocoon := WebNetwork.create_cocoon(p.global_position + Vector3(0, 0, -1.6))
	await _frames(5)
	layer.hud.open_cocoon(cocoon)
	var m: CocoonMenu = layer.hud.cocoon_menu
	m._show_tab("evo")
	await _frames(10)
	await _shot("evo_ramo_nivel6")
	# nível 10, com requisitos de algumas raras cumpridos; foco numa rara
	m.close()
	await _frames(5)
	p.level = Player.FINAL_LEVEL
	p.resist_fire = 5
	GameState.flags["material_cristal_fogo"] = true
	p.resist_poison = 2
	p.resist_acid = 5
	p.crystal_skin = true
	p.moonstones = 2
	layer.hud.open_cocoon(cocoon)
	m._show_tab("evo")
	await _frames(5)
	for b in m._page_btns:
		if int(b.get_meta("branch", -1)) == Player.Form.LUA:
			b.grab_focus()
	await _frames(5)
	await _shot("evo_escolha_rara")
	for b in m._page_btns:
		if int(b.get_meta("branch", -1)) == Player.Form.EXECUTORA:
			b.grab_focus()
	await _frames(5)
	await _shot("evo_escolha_ramo")
	m.close()
	await _frames(5)
	p.choose_branch(Player.Form.ARDENTE)
	p.evolve()
	await _frames(60)
	layer.hud.open_cocoon(cocoon)
	m._show_tab("evo")
	await _frames(10)
	await _shot("evo_final")
	m.close()
	await _frames(5)
	# galeria das formas: um boneco de cada, em fila
	var forms := [Player.Form.EXECUTORA, Player.Form.BASTIA, Player.Form.SENHORA, Player.Form.SALTADORA, Player.Form.VIDENTE, Player.Form.TEMPESTADE,
		Player.Form.ARDENTE, Player.Form.BREU, Player.Form.VIUVA, Player.Form.CORROSIVA, Player.Form.LUA]
	for f in forms:
		p.form = f
		p.recompute_stats(true)
		p._apply_form_visual()
		p.rune_on = true
		p.aim_dir = Vector3(0, 0, 1)
		p.cam_zoom = 5.0
		await _frames(40)
		await _shot("forma_%02d" % int(f))
	print("captura: evolucao")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame
