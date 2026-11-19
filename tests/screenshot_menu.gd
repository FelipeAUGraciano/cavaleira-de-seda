extends Node
## Capturas do menu inicial (com save) e da pausa. Uso: godot --path . res://tests/screenshot_menu.tscn -- <pasta>

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
	GameState.delete_save()
	GameState.new_game()
	await _frames(40)
	GameState.player.level = 4
	GameState.save_now()
	await _frames(200)
	var hud = get_tree().current_scene.hud
	GameState.player.poison_t = 6.0
	GameState.player.hp = GameState.player.max_hp * 0.62
	GameState.player.silk = GameState.player.max_silk * 0.4
	GameState.player.rune_on = false
	await _frames(3)
	await _shot("hud")
	hud.open_pause()
	await _frames(5)
	await _shot("pausa")
	hud.open_options()
	await _frames(5)
	await _shot("opcoes")
	hud._options.close()
	await _frames(3)
	GameState.to_title()
	await _frames(60)
	await _shot("menu")
	GameState.delete_save()
	get_tree().quit()


func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, tag])
	print("captura: ", tag)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
