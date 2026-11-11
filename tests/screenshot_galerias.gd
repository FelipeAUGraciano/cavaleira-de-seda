extends Node
## Capturas das Galerias para revisão visual. Uso: godot --path . res://tests/screenshot_galerias.tscn -- <pasta>

var out := "user://shots"
var layer
var p: Player


func _ready() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	GameState.delete_save()
	GameState.said = {}
	GameState.flags = {}
	layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(30)
	p = GameState.player
	p.using_stick_aim = true
	p.aim_dir = Vector3(0, 0, 1)
	await _frames(60)
	await _shot("g1_entrada")

	_go(Vector3(2.0, 0.1, 30.0))
	await _frames(60)
	await _shot("g2_poca")

	_go(Vector3(22.0, 0.1, -7.0))
	p.aim_dir = Vector3(1, 0, 0)
	await _frames(90)
	await _shot("g3_morcegos")

	_go(Vector3(42.0, 0.1, 37.0))
	await _frames(20)
	WebNetwork.create_cocoon(Vector3(44, 0, 36))
	for pair in [["G4_a", "G4_e"], ["G4_b", "G4_f"], ["G4_c", "G4_h"], ["G4_a", "G4_d"]]:
		WebNetwork.create_strand(WebNetwork.anchors[pair[0]], WebNetwork.anchors[pair[1]])
	await _frames(40)
	await _shot("g4_gruta")

	_go(Vector3(44.0, 0.1, 64.0))
	await _frames(60)
	await _shot("g5_jardim")

	_go(Vector3(77.0, 0.1, 39.0))
	p.aim_dir = Vector3(1, 0, 0)
	await _frames(40)
	await _shot("g6_ponte")

	_go(Vector3(12.0, 0.1, 74.0))
	p.aim_dir = Vector3(-1, 0, 0)
	await _frames(40)
	await _shot("g7_lago")

	_go(Vector3(58.0, 0.1, 26.0))
	await _frames(30)
	await _shot("g16_cristal")

	for r in layer.rooms:
		layer.map_system.revealed[r["id"]] = true
	for l in layer.map_system.locks:
		l["seen"] = true
	layer.hud._show_map = true
	await _frames(10)
	await _shot("mapa")
	GameState.delete_save()
	get_tree().quit()


func _go(pos: Vector3) -> void:
	if p.dead:
		p._respawn()
	p.hp = p.max_hp
	p.global_position = pos
	p.last_safe_pos = pos
	p.velocity = Vector3.ZERO
	p.snap_camera()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("captura: ", name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
