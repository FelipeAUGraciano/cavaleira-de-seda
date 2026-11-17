extends Node
## Capturas do começo do Ato 2: a queda da Fenda, a tela de carregamento, a chegada no Abismo,
## o Ossário, o Colosso na trilha e a Fenda do refúgio.
## Uso: godot --path . res://tests/screenshot_abismo.tscn -- <pasta>

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
	GameState.flags["g14_centopeia"] = true
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://world/layers/galerias.tscn")
	await get_tree().create_timer(1.5).timeout
	var g = get_tree().current_scene
	var p: Player = GameState.player
	p.invuln = 999.0
	g.hud._area_time = 0.0
	p.global_position = Galerias.W(Vector3(169.0, 0.1, 110.0))
	p.snap_camera()
	await get_tree().create_timer(1.8).timeout
	await _shot("abismo_1_racha")
	while p.global_position.y > -4.0:
		await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	await _shot("abismo_2_queda")
	var ls: Node = null
	while ls == null:
		await get_tree().process_frame
		var f := get_tree().get_nodes_in_group("loading_screen")
		if not f.is_empty():
			ls = f[0]
	await get_tree().create_timer(1.6).timeout
	await _shot("abismo_3_carregando")
	while not String(get_tree().current_scene.scene_file_path if get_tree().current_scene else "").ends_with("abismo.tscn"):
		await get_tree().process_frame
	await get_tree().create_timer(3.2).timeout
	await _shot("abismo_4_chegada")
	var a = get_tree().current_scene
	p = GameState.player
	while p.autopilot:
		await get_tree().process_frame
	p.invuln = 999.0
	a.hud._area_time = 0.0
	p.global_position = Vector3(29.0, 0.1, 10.5)
	p.snap_camera()
	await get_tree().create_timer(1.2).timeout
	await _shot("abismo_5_ossario")
	var col: Colossus = a.colossus
	col.set_physics_process(false)
	col.s = 30.0
	col.dir = 1.0
	col._place(0.0)
	var ahead := col.point_at(41.0)
	var side := (col.point_at(41.5) - col.point_at(40.5)).normalized()
	p.rune_on = true
	p.global_position = ahead + Vector3(-side.z, 0.0, side.x) * 3.5 + Vector3(0, 0.1, 0)
	p.cam_zoom = 20.0
	p.snap_camera()
	await get_tree().create_timer(1.4).timeout
	await _shot("abismo_6_colosso")
	col._alert()
	col._animate(0.1)
	await get_tree().create_timer(0.6).timeout
	await _shot("abismo_7_alerta")
	col.set_physics_process(true)
	col._calm()
	var nk: Vector3 = a.niche_spots[2]
	p.global_position = nk + Vector3(0, 0.1, 0)
	await get_tree().create_timer(0.2).timeout
	p.cam_zoom = 0.0
	p.global_position = Vector3(84.0, 0.1, -4.0)
	p.snap_camera()
	await get_tree().create_timer(1.2).timeout
	await _shot("abismo_8_refugio")
	print("captura: abismo")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
