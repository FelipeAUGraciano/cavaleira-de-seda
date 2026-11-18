extends Node
## Capturas do Rio de Brasa (Ato 3). Uso: godot --path . res://tests/screenshot_rio.tscn -- <pasta>

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
	get_tree().change_scene_to_file("res://world/layers/rio_brasa.tscn")
	await get_tree().create_timer(3.5).timeout
	var r = get_tree().current_scene
	var p: Player = GameState.player
	p.invuln = 999.0
	p.resist_fire = 4
	p.rune_on = true
	var first := {}
	for c in World.creatures:
		if not first.has(c.display_name):
			first[c.display_name] = c
	var shots := [["rio_1_margem", Vector3(2, 0.1, 18), 0.0], ["rio_2_mirante", Vector3(36, 0.1, 5), 20.0],
		["rio_3_ilhas", Vector3(52, 0.1, 8.5), 14.0], ["rio_4_camara_fria", Vector3(80, 0.1, 10), 0.0],
		["rio_5_forja", Vector3(90, 0.1, 38), 14.0], ["rio_6_geiseres", Vector3(128, 0.1, -1), 12.0],
		["rio_7_pantano", Vector3(166, 0.1, -30), 0.0], ["rio_8_cristais", Vector3(187, 0.1, -55), 0.0]]
	for sh in shots:
		r.hud._area_time = 0.0
		p.global_position = sh[1]
		p.cam_zoom = float(sh[2])
		p.snap_camera()
		if sh[0] == "rio_3_ilhas":
			WebNetwork.create_strand(WebNetwork.anchors["R3_oeste"], WebNetwork.anchors["R3_ilha0"])
			WebNetwork.create_strand(WebNetwork.anchors["R3_ilha0"], WebNetwork.anchors["R3_ilha1"])
		if sh[0] == "rio_6_geiseres":
			r._geyser_t = 3.75
		await get_tree().create_timer(1.3).timeout
		await _shot(sh[0])
	for nm in ["Salamandra-chama", "Golem de basalto", "Peixe-magma", "Aranha de cinza"]:
		var c: Creature = first.get(nm)
		if c == null:
			continue
		p.cam_zoom = 10.0
		p.global_position = c.global_position + Vector3(3.0, 0.1, 1.5)
		if c is LavaLurker:
			(c as LavaLurker)._visual.position.y = 0.0
		p.snap_camera()
		await get_tree().create_timer(1.0).timeout
		await _shot("rio_bicho_%s" % nm.split(" ")[0].to_lower().replace("ã", "a"))
	# a rainha soltando a onda
	var q: QueenSalamander = r.queen
	p.cam_zoom = 22.0
	p.global_position = Vector3(166, 0.1, 26)
	p.snap_camera()
	await get_tree().create_timer(1.0).timeout
	q._wave_t = 0.0
	await get_tree().create_timer(1.9).timeout
	await _shot("rio_9_rainha_onda")
	print("captura: rio")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
