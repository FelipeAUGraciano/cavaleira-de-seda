extends Node
## Captura dos modelos novos (lagarto, morcego, Centopeia) numa sala clara.
## Uso: godot --path . res://tests/screenshot_novos.tscn -- <pasta>

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
	await _frames(2)
	var base := p.global_position
	var lz := Lizard.new()
	lz.position = base + Vector3(-3.0, 0.3, 1.0)
	layer.ecosystem.add_child(lz)
	var bat := Bat.new()
	bat.position = base + Vector3(1.5, 2.2, -1.0)
	bat.den = base
	layer.ecosystem.add_child(bat)
	var cen := Centipede.new()
	cen.position = base + Vector3(4.0, 0.3, 3.0)
	layer.ecosystem.add_child(cen)
	await _frames(10)
	for c in [lz, bat, cen]:
		c.set_physics_process(false)
	lz.facing = Vector3(1, 0, 0)
	lz.look_at(lz.global_position + Vector3(1, 0, 0.3), Vector3.UP)
	cen.facing = Vector3(-1, 0, -0.2).normalized()
	cen.look_at(cen.global_position + cen.facing, Vector3.UP)
	cen._reset_trail()
	await _frames(5)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 40.0
	cam.make_current()
	layer.dark_vision = false
	var shots := [[base + Vector3(0, 9, 9), base + Vector3(0.5, 0, 1)], [lz.global_position + Vector3(2.0, 1.6, 2.6), lz.global_position],
		[bat.global_position + Vector3(0.6, 1.4, 1.2), bat.global_position], [cen.global_position + Vector3(4, 3.5, 5), cen.global_position + Vector3(-2, 0, -1)]]
	var sheet := Image.create(1600, 900, false, Image.FORMAT_RGBA8)
	for i in shots.size():
		cam.global_position = shots[i][0]
		cam.look_at(shots[i][1], Vector3.UP)
		await _frames(3)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(800, 450)
		sheet.blit_rect(img, Rect2i(0, 0, 800, 450), Vector2i((i % 2) * 800, (i / 2) * 450))
	sheet.save_png("%s/novos.png" % out)
	print("captura: novos")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
