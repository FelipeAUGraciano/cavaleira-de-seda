extends Node
## Capturas do fim do prólogo: a fuga pelo túnel, a tela de carregamento e a chegada com o
## nome da área. Uso: godot --path . res://tests/screenshot_fuga.tscn -- <pasta>

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
	get_tree().change_scene_to_file("res://world/layers/bercario.tscn")
	await get_tree().create_timer(1.5).timeout
	var layer = get_tree().current_scene
	var p: Player = GameState.player
	p.invuln = 999.0
	layer._chase_started = true
	layer.chase.begin()
	layer.chase.progress = 40.0
	layer.hud._area_time = 0.0   # (captura) o nome do Berçário já teria sumido há tempo
	p.global_position = Vector3(114.5, 0.1, 1.0)
	p.snap_camera()
	await get_tree().create_timer(0.5).timeout
	p.global_position = Vector3(116.6, 0.1, 1.0)
	await get_tree().create_timer(0.9).timeout
	await _shot("fuga_1_desabamento")
	await get_tree().create_timer(0.9).timeout
	await _shot("fuga_2_tunel")
	var ls: Node = null
	while ls == null:
		await get_tree().process_frame
		var f := get_tree().get_nodes_in_group("loading_screen")
		if not f.is_empty():
			ls = f[0]
	await get_tree().create_timer(1.6).timeout
	await _shot("fuga_3_carregando")
	while not String(get_tree().current_scene.scene_file_path if get_tree().current_scene else "").ends_with("galerias.tscn"):
		await get_tree().process_frame
	await get_tree().create_timer(2.6).timeout
	await _shot("fuga_4_chegada")
	print("captura: fuga")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
