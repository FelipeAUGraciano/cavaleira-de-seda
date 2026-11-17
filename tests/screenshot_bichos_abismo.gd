extends Node
## Bichos novos do Abismo e os três ramos de evolução (forma no corpo e menu do casulo).
## Uso: godot --path . res://tests/screenshot_bichos_abismo.tscn -- <pasta>

var out := "user://shots"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	reparent(get_tree().root)
	get_tree().current_scene = null
	GameState.new_game()
	GameState.delete_save()
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://world/layers/abismo.tscn")
	await get_tree().create_timer(2.5).timeout
	var a = get_tree().current_scene
	var p: Player = GameState.player
	p.invuln = 999.0
	p.rune_on = true
	p.cam_zoom = 12.0
	var first := {}
	for c in World.creatures:
		if not first.has(c.display_name):
			first[c.display_name] = c
	for sh in [["bicho_aranha_lobo", "Aranha-lobo do breu"], ["bicho_mimico", "Mímico de estalagmite"],
			["bicho_lesma", "Lesma de ácido"], ["bicho_morcego_gigante", "Morcego gigante"], ["bicho_escorpiao", "Escorpião-de-obsidiana"]]:
		var c: Creature = first.get(sh[1])
		if c == null:
			continue
		a.hud._area_time = 0.0
		p.global_position = c.global_position + Vector3(2.6, 0.1, 1.2)
		p.snap_camera()
		if c is Mimic:
			p.global_position = c.global_position + Vector3(1.8, 0.1, 0.4)
		await get_tree().create_timer(1.2).timeout
		await _shot(sh[0])
	# as três formas
	p.global_position = Vector3(0, 0.1, 0)
	p.cam_zoom = 6.0
	for f: int in [Player.Form.LAMINA, Player.Form.TEIA, Player.Form.RUNA]:
		p.form = Player.Form.CAVALEIRA
		p.level = Player.BRANCH_LEVEL
		p.choose_branch(f)
		p.evolve()
		p.snap_camera()
		await get_tree().create_timer(2.0).timeout
		await _shot("forma_%d" % f)
	# menu do casulo com os ramos abertos
	p.form = Player.Form.CAVALEIRA
	p._apply_form_visual()
	p.level = Player.BRANCH_LEVEL
	p.pending_form = Player.Form.TEIA
	var cocoon := WebNetwork.create_cocoon(p.global_position + Vector3(0, 0, -1.6))
	await get_tree().create_timer(0.2).timeout
	a.hud.open_cocoon(cocoon)
	var m: CocoonMenu = a.hud.cocoon_menu
	m._show_tab("evo")
	await get_tree().create_timer(0.4).timeout
	await _shot("casulo_ramos")
	print("captura: bichos do abismo")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
