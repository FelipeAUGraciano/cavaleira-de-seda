extends Node
## Capturas do Ato 4 (a caçada). Uso: godot --path . res://tests/screenshot_cacada.tscn -- <pasta>

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
	for f in ["g14_centopeia"]:
		GameState.flags[f] = true
	for i in 5:
		await get_tree().process_frame
	get_tree().change_scene_to_file("res://world/layers/galerias_cacada.tscn")
	await get_tree().create_timer(7.0).timeout
	var g = get_tree().current_scene
	var p: Player = GameState.player
	p.invuln = 999.0
	p.rune_on = true
	for sh in [["cacada_1_chegada", Vector3(0, 0, 0), 0.0, ""], ["cacada_2_acampamento", Galerias.W(Vector3(44, 0.1, 44)), 16.0, ""],
			["cacada_3_toca_queimada", Vector3(28.5, 0.1, 86.5), 0.0, ""], ["cacada_4_ilha", Galerias.WL3(-3, 0.1, 75.5), 12.0, ""],
			["cacada_5_jardim", Galerias.W(Vector3(44, 0.1, 72)), 12.0, ""], ["cacada_6_g9", Galerias.W(Vector3(182, 0.1, 47)), 14.0, ""],
			["cacada_7_capita", Vector3(60.5, 0.1, 28.5), 14.0, ""]]:
		g.hud._area_time = 0.0
		if sh[0] != "cacada_1_chegada":
			p.global_position = sh[1]
		p.cam_zoom = float(sh[2])
		p.snap_camera()
		if sh[0] == "cacada_7_capita":
			g.hunt.raise(2.2, p.global_position)
		await get_tree().create_timer(1.3).timeout
		await _shot(sh[0])
	print("captura: cacada")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
