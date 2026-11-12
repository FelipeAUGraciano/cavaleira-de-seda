extends Node
## Close das patas andando (folha de 8 quadros: em cima de lado, embaixo de cima).
## Uso: godot --path . res://tests/screenshot_patas.tscn -- <pasta> [nome] [filhote|cavaleira]

var out := "user://shots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var tag := args[1] if args.size() > 1 else "patas"
	DirAccess.make_dir_recursive_absolute(out)
	GameState.delete_save()
	GameState.said = {}
	GameState.flags = {}
	var layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	layer.hud.visible = false
	for c in World.creatures.duplicate():
		c.queue_free()
	var p: Player = GameState.player
	if args.size() > 2 and args[2] == "cavaleira":
		p.evolve()
		await _frames(120)
	p.global_position = Vector3(36, 0.1, 37)
	p.using_stick_aim = true
	p.aim_dir = Vector3(1, 0, 0)
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.fov = 35.0
	var light := OmniLight3D.new()
	light.omni_range = 8.0
	light.light_energy = 2.0
	add_child(light)
	await _frames(10)
	var sheet := Image.create(1600, 900, false, Image.FORMAT_RGBA8)
	Input.action_press("move_right")
	await _frames(20)
	for i in 8:
		if i < 4:
			cam.global_position = p.global_position + Vector3(0.0, 0.9, 3.4)
		else:
			cam.global_position = p.global_position + Vector3(0.0, 4.2, 1.6)
		cam.look_at(p.global_position + Vector3(0.0, 0.3, 0.0))
		light.global_position = p.global_position + Vector3(1.0, 3.0, 2.0)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img = img.get_region(Rect2i(img.get_width() / 2 - 400, 0, 800, 900))
		img.resize(400, 450)
		sheet.blit_rect(img, Rect2i(0, 0, 400, 450), Vector2i((i % 4) * 400, (i / 4) * 450))
		await _frames(5)
	Input.action_release("move_right")
	sheet.save_png("%s/%s.png" % [out, tag])
	print("captura: ", tag)
	GameState.delete_save()
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
