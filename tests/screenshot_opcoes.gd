extends Node
## Telas do menu: título, espaços de save e as 3 páginas de Opções. Folha 3×2.
## Uso: godot --path . res://tests/screenshot_opcoes.tscn -- <pasta>

var out := "user://shots"
var sheet := Image.create(1602, 600, false, Image.FORMAT_RGBA8)
var n := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	reparent(get_tree().root)
	get_tree().current_scene = null
	get_tree().change_scene_to_file(GameState.TITLE_SCENE)
	await _frames(10)
	var t = get_tree().current_scene
	await _grab()
	t.show_slots("new")
	await _frames(3)
	await _grab()
	t.show_options()
	await _frames(3)
	await _grab()
	t.options.show_page("tela")
	await _frames(3)
	await _grab()
	t.options.show_page("controles")
	await _frames(3)
	await _grab()
	var row := 5
	t.options._start_capture("attack", false, t.options._body.get_child(0).get_child(0).get_child(3 + row * 3 + 1))
	await _frames(3)
	await _grab()
	t.options._cancel_capture()
	sheet.save_png("%s/opcoes.png" % out)
	print("captura: opcoes")
	get_tree().quit()


func _grab() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(534, 300)
	sheet.blit_rect(img, Rect2i(0, 0, 534, 300), Vector2i((n % 3) * 534, (n / 3) * 300))
	n += 1


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame
