extends Node
## Captura do mundo vivo (HUD com a fase da caverna, Leitura com a atividade, bichos sentidos pela teia).
## Uso: godot --path . res://tests/screenshot_vida.tscn -- <pasta>

var out := "user://shots"


func _ready() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	GameState.delete_save()
	GameState.said = {}
	GameState.flags = {}
	var layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(30)
	var p: Player = GameState.player
	World.clock.paused = true
	World.clock.set_phase(CaveClock.Phase.CACA, 0.2)
	layer.hud._show_help = false
	# território na Grande Gruta com um sapo passando por ele
	WebNetwork.create_cocoon(Vector3(44, 0, 36))
	for pair in [["G4_a", "G4_e"], ["G4_b", "G4_f"], ["G4_c", "G4_h"], ["G4_a", "G4_d"], ["G4_b", "G4_g"]]:
		WebNetwork.create_strand(WebNetwork.anchors[pair[0]], WebNetwork.anchors[pair[1]])
	var frog: Frog = null
	for c in World.creatures:
		if c is Frog:
			frog = c
			break
	frog.global_position = Vector3(50.0, 0.3, 30.0)
	frog.needs.hunger = 90.0
	p.global_position = Vector3(44.0, 0.1, 38.0)
	p.last_safe_pos = p.global_position
	p.snap_camera()
	p.using_stick_aim = true
	await _frames(40)
	p.aim_point = frog.global_position
	p.aim_dir = (frog.global_position - p.global_position).normalized()
	Input.action_press("read")
	await _frames(6)
	await _shot("vida_leitura")
	Input.action_release("read")
	GameState.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("captura: ", name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
