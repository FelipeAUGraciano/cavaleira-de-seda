extends Node
## Captura dos pilares, ganchos de parede e da ponte de fio.
## Uso: godot --path . res://tests/screenshot_teia.tscn -- <pasta>

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
	layer.hud.visible = false
	var p: Player = GameState.player
	for c in World.creatures.duplicate():
		c.queue_free()
	var A: Dictionary = WebNetwork.anchors
	var hook := layer.add_wall_anchor("Gancho_teste", Vector3(-1.5, 0, 10.5), Vector3(0, 0, -1)) as WebAnchor
	layer.add_static_box(Vector3(8.0, 2.8, 1.2), Vector3(-1.5, 1.4, 11.9), Color(0.17, 0.21, 0.21))
	await _frames(2)
	for pair in [["Pilar_09", "Pilar_11"], ["Pilar_06", "Pilar_12"], ["Pilar_05", "Pilar_09"], ["Pilar_06", "Gancho_teste"], ["Pilar_12", "Pilar_13"]]:
		WebNetwork.create_strand(A[pair[0]], A[pair[1]])
	WebNetwork.create_cocoon(Vector3(-6.5, 0, 3.0))
	await _frames(10)
	p.set_physics_process(false)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 40.0
	layer.dark_vision = false
	var sheet := Image.create(1600, 900, false, Image.FORMAT_RGBA8)
	var a6: Vector3 = A["Pilar_06"].global_position
	var a12: Vector3 = A["Pilar_12"].global_position
	var mid := (a6 + a12) * 0.5
	var shots := [
		["game", Vector3(0, 0, -4)],
		["persp", [mid + Vector3(-1.5, 2.2, -4.0), mid]],
		["persp", [a6 + Vector3(1.8, 1.6, -1.8), a6 + Vector3(0, 0.7, 0)]],
		["persp", [hook.global_position + Vector3(1.6, 1.8, -2.6), hook.global_position + Vector3(0, 0.6, 0)]],
	]
	for i in shots.size():
		var s: Array = shots[i]
		if s[0] == "game":
			p.global_position = s[1]
			p.snap_camera()
			p.camera.make_current()
		else:
			cam.make_current()
			cam.global_position = s[1][0]
			cam.look_at(s[1][1], Vector3.UP)
		await _frames(4)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(800, 450)
		sheet.blit_rect(img, Rect2i(0, 0, 800, 450), Vector2i((i % 2) * 800, (i / 2) * 450))
	sheet.save_png("%s/teia.png" % out)
	print("captura: teia")
	# Galerias de verdade (escuro, visão curta): ganchos e pilares
	layer.queue_free()
	await _frames(3)
	var gal = load("res://world/layers/galerias.tscn").instantiate()
	add_child(gal)
	await _frames(30)
	gal.hud.visible = false
	p = GameState.player
	for c in World.creatures.duplicate():
		c.queue_free()
	p.set_physics_process(false)
	print("ganchos: ", gal.wall_hook_count)
	var A2: Dictionary = WebNetwork.anchors
	var targets: Array = []
	if A2.has("Gancho_00"):
		WebNetwork.create_strand(A2["Gancho_00"], A2["Gancho_01"])
		targets.append((A2["Gancho_00"].global_position + A2["Gancho_01"].global_position) * 0.5)
	if A2.has("Gancho_02"):
		WebNetwork.create_strand(A2["Gancho_02"], A2["Gancho_03"])
		targets.append((A2["Gancho_02"].global_position + A2["Gancho_03"].global_position) * 0.5)
	for pair in [["G4_a", "G4_e"], ["G4_b", "G4_f"], ["G4_a", "G4_d"]]:
		if A2.has(pair[0]) and A2.has(pair[1]):
			WebNetwork.create_strand(A2[pair[0]], A2[pair[1]])
	targets.append(A2["G4_a"].global_position)
	targets.append(A2["G6_c"].global_position)
	var sheet2 := Image.create(1600, 900, false, Image.FORMAT_RGBA8)
	for i in mini(targets.size(), 4):
		p.global_position = targets[i] + Vector3(0, 0.1, 0)
		p.snap_camera()
		p.camera.make_current()
		await _frames(6)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(800, 450)
		sheet2.blit_rect(img, Rect2i(0, 0, 800, 450), Vector2i((i % 2) * 800, (i / 2) * 450))
	sheet2.save_png("%s/teia_galerias.png" % out)
	print("captura: teia_galerias")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
