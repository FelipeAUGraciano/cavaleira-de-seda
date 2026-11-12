extends Node
## Capturas da visão curta: Brilho e Caça, runa acesa e apagada. Uso: godot --path . res://tests/screenshot_visao.tscn -- <pasta>

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
	layer.hud.fade_alpha = 0.0
	layer.hud._title_time = 0.0
	layer.hud._show_help = false
	var p: Player = GameState.player
	var sheet := Image.create(1600, 900, false, Image.FORMAT_RGBA8)
	var cases := [[CaveClock.Phase.BRILHO, true], [CaveClock.Phase.BRILHO, true], [CaveClock.Phase.CACA, true], [CaveClock.Phase.CACA, false]]
	for i in cases.size():
		World.clock.paused = true
		World.clock.set_phase(cases[i][0])
		p.global_position = layer._snap_floor(Galerias.W(Vector3(40.0, 0.1, 36.0)), 1.5)
		p.invuln = 99.0
		p.rune_on = cases[i][1]
		p.snap_camera()
		await _frames(20)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(800, 450)
		sheet.blit_rect(img, Rect2i(0, 0, 800, 450), Vector2i((i % 2) * 800, (i / 2) * 450))
	sheet.save_png("%s/visao.png" % out)
	print("captura: visao")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
