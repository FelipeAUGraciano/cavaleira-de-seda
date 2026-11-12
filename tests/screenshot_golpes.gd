extends Node
## Capturas dos avisos de golpe no chão (sapo e lagarto). Uso: godot --path . res://tests/screenshot_golpes.tscn -- <pasta>

var out := "user://shots"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	GameState.permadeath = false
	GameState.delete_save()
	var layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(30)
	World.clock.paused = true
	World.clock.set_phase(CaveClock.Phase.CACA)
	layer.hud.fade_alpha = 0.0
	layer.hud._title_time = 0.0
	var p: Player = GameState.player
	var frog: Frog = null
	for c in World.creatures:
		if c is Frog:
			frog = c
			break
	var sheet := Image.create(1600, 900, false, Image.FORMAT_RGBA8)
	var ids := ["bote", "lingua", "salto", "giro"]
	for i in ids.size():
		p.global_position = Vector3(-2.0, 0.1, 30.0)
		p.velocity = Vector3.ZERO
		p.invuln = 99.0
		frog.global_position = Vector3(-2.0 + (2.2 if ids[i] == "giro" else 0.0), 0.0, 30.0 + (0.0 if ids[i] == "giro" else (2.0 if ids[i] == "bote" else 6.0)))
		frog.facing = Vector3(0, 0, -1)
		frog.cancel_attack()
		p.snap_camera()
		await _frames(2)
		frog.player_memory = 5.0
		frog.last_player_pos = p.global_position
		frog.brain.switch_to(frog, frog.brain.find("combat"))
		frog.start_attack(frog.find_attack(ids[i]), p)
		await _frames(int(frog.cur_attack.windup * 60.0 * 0.7))
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img = img.get_region(Rect2i(400, 100, 800, 700))
		img.resize(800, 450)
		sheet.blit_rect(img, Rect2i(0, 0, 800, 450), Vector2i((i % 2) * 800, (i / 2) * 450))
	sheet.save_png("%s/golpes.png" % out)
	print("captura: golpes")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
