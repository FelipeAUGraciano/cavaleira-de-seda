extends Node
## Runa acesa x apagada nas Galerias, e o fio lançado numa parede de baixo (sul).
## Uso: godot --path . res://tests/screenshot_runa.tscn -- <pasta>

var out := "user://shots"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	GameState.permadeath = false
	GameState.delete_save()
	var gal = load("res://world/layers/galerias.tscn").instantiate()
	add_child(gal)
	await _frames(30)
	gal.hud.visible = false
	for c in World.creatures.duplicate():
		c.queue_free()
	var p: Player = GameState.player
	p.global_position = Galerias.W(Vector3(-6, 0.1, 24))
	p.snap_camera()
	p.energy = p.max_energy
	var sheet := Image.create(1600, 450, false, Image.FORMAT_RGBA8)
	p.rune_on = false
	await _frames(40)
	await _grab(sheet, 0)
	p.rune_on = true
	await _frames(40)
	await _grab(sheet, 1)
	sheet.save_png("%s/runa.png" % out)
	# parede de baixo: lança o fio para +Z e vê se prende
	var from := p.global_position + Vector3.UP * 0.5
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, 0, 14), 1)
	q.exclude = [p.get_rid()]
	var hit := p.get_world_3d().direct_space_state.intersect_ray(q)
	print("parede sul: ", "acertou a %.1f m" % from.distance_to(hit["position"]) if not hit.is_empty() else "NADA")
	print("captura: runa")
	get_tree().quit()


func _grab(sheet: Image, i: int) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(800, 450)
	sheet.blit_rect(img, Rect2i(0, 0, 800, 450), Vector2i(i * 800, 0))


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame
