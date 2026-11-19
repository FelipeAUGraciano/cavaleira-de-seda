extends Node
## Capturas do Portão da Superfície, do Guardião e dos finais.
## Uso: godot --path . res://tests/screenshot_portao.tscn -- <pasta> [so_finais]

var out := "user://shots"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	reparent(get_tree().root)
	get_tree().current_scene = null
	GameState.new_game()
	GameState.delete_save()
	await _frames(5)
	get_tree().change_scene_to_file("res://world/layers/portao.tscn")
	await _seconds(3.5)
	var l = get_tree().current_scene
	var p: Player = GameState.player
	p.invuln = 9999.0
	p.level = 10
	Settings.set_value("mostrar_controles", false)
	if not args.has("so_finais"):
		for spot in [["p1", Vector3(0, 0.1, 40)], ["p2", Vector3(-2, 0.1, 16)], ["p3", Vector3(28.5, 0.1, -14.5)], ["p3_sombra", Vector3(32, 0.1, -16)],
				["p5", Vector3(56, 0.1, -38)], ["p6", Vector3(56, 0.1, -53)], ["p7", Vector3(56, 0.1, -80)]]:
			p.global_position = spot[1]
			p.snap_camera()
			await _seconds(1.2)
			await _shot(spot[0])
		l.hud._show_map = true
		await _frames(4)
		await _shot("mapa")
		l.hud._show_map = false
		# a luta
		p.global_position = Vector3(56, 0.1, -82)
		p.snap_camera()
		l.guardian.wake()
		await _seconds(3.0)
		await _shot("guardiao_1")
		l.guardian.take_damage(l.guardian.max_hp * 0.4, p)
		await _seconds(4.5)
		await _shot("guardiao_2")
		l.guardian.take_damage(l.guardian.max_hp * 0.4, p)
		await _seconds(4.0)
		await _shot("guardiao_3")
	# finais
	for f in [Player.Form.EXECUTORA, Player.Form.SENHORA, Player.Form.TEMPESTADE, Player.Form.LUA]:
		p.form = f
		var e := Ending.new().setup(p)
		get_tree().root.add_child(e)
		await _seconds(1.0)
		e._t = 12.0
		for i in 6:
			e.advance()
		await _seconds(1.6)
		await _shot("final_%s" % String(Player.Form.keys()[f]).to_lower())
		e.queue_free()
		get_tree().paused = false
		await _frames(3)
	GameState.delete_save()
	get_tree().quit()


func _shot(tag: String) -> void:
	var sc = get_tree().current_scene
	if sc != null and "hud" in sc and sc.hud != null:
		sc.hud._area_time = 0.0   # (com a tela lenta da captura, o título da área fica na tela mais tempo)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, tag])
	print("captura: ", tag)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout
