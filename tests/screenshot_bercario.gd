extends Node
## Capturas do Berçário para revisão visual. Uso: godot --path . res://tests/screenshot_bercario.tscn -- <pasta>

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
	layer = load("res://world/layers/bercario.tscn").instantiate()
	add_child(layer)
	await _frames(30)
	p = GameState.player
	p.using_stick_aim = true
	p.aim_dir = Vector3(1, 0, 0)
	await _frames(60)
	await _shot("b1_eclosao")

	_go(Vector3(0.0, 0.1, -3.0))
	await _frames(40)
	Input.action_press("weave")
	await _frames(10)
	p.weave_first = WebNetwork.anchors["B3_a"]
	p.aim_dir = Vector3(1, 0, -0.2).normalized()
	p._refresh_anchor_highlights()
	await _frames(25)
	await _shot("b3_tecelagem")
	Input.action_release("weave")
	await _frames(10)

	var leg: MotherLeg = layer.mother_leg
	_go(Vector3(37.0, 0.1, 2.0))
	await _frames(20)
	leg._start_strike(p.global_position)
	await _frames(20)
	await _shot("b5_pata")
	leg.active = false

	p.hp = p.max_hp
	_go(Vector3(70.0, 0.1, 0.0))
	await _frames(5)
	layer._chase_started = true
	layer.chase.begin()
	layer.chase.position.x = 60.0
	await _frames(4)
	await _shot("b6_fuga")

	for id in ["B1", "B2", "B3", "B4", "B5", "B6"]:
		layer.map_system.revealed[id] = true
	layer.map_system.locks[0]["seen"] = true
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
