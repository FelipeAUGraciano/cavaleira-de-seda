extends Node
## Capturas da segunda metade das Galerias e da Centopeia. Uso: godot --path . res://tests/screenshot_covil.tscn -- <pasta>

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
	p.aim_dir = Vector3(0, 0, -1)
	layer.hud._show_help = false

	_go(Vector3(138.0, 0.1, 36.0))
	await _frames(70)
	await _shot("g8_aventureiros")

	_go(Vector3(182.0, 0.1, 47.0))
	await _frames(40)
	await _shot("g9_acampamento")

	_go(Vector3(43.0, 0.1, 96.0))
	p.aim_dir = Vector3(0, 0, 1)
	await _frames(60)
	await _shot("g12_ninho")

	_go(Vector3(167.5, 0.1, 15.5))
	await _frames(40)
	await _shot("g10_fresta")

	_go(Vector3(135.0, 0.1, 103.0))
	await _frames(20)
	WebNetwork.create_strand(WebNetwork.anchors["G14_0"], WebNetwork.anchors["G14_7"])
	WebNetwork.create_strand(WebNetwork.anchors["G14_1"], WebNetwork.anchors["G14_2"])
	var boss: Centipede = layer.centipede
	boss.global_position = layer.ARENA + Vector3(-3, 0.05, 0)
	boss.facing = Vector3(1, 0, 0)
	boss._reset_trail()
	_go(Vector3(141.0, 0.1, 114.0))
	boss.memory = 2.0
	boss.last_heard = p.global_position
	boss.mode = Centipede.Mode.WINDUP
	boss.mode_time = 0.2
	boss.telegraph = true
	await _frames(18)
	await _shot("g14_centopeia_aviso")
	await _frames(10)
	boss.global_position = layer.ARENA + Vector3(8.2, 0.05, 0)
	boss._update_trail()
	boss.entangle(4.5)
	boss.mode = Centipede.Mode.RECOVER
	_go(Vector3(146.0, 0.1, 109.0))
	p.aim_dir = Vector3(-1, 0, 0)
	await _frames(12)
	await _shot("g14_centopeia_enredada")

	boss.take_damage(9999.0, p)
	await _frames(10)
	layer._collapsing = true   # só a foto: sem trocar de cena
	_go(Vector3(168.0, 0.1, 110.0))
	p.aim_dir = Vector3(1, 0, 0)
	await _frames(70)
	await _shot("g15_borda")

	for r in layer.rooms:
		layer.map_system.revealed[r["id"]] = true
	for l in layer.map_system.locks:
		l["seen"] = true
	layer.hud._show_map = true
	await _frames(10)
	await _shot("mapa_galerias")
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
