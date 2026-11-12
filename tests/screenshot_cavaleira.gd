extends Node
## Protagonista com os modelos (corpo, patas, lâminas). Folha 3×2.
## Uso: godot --path . res://tests/screenshot_cavaleira.tscn -- <pasta>

var out := "user://shots"
var sheet := Image.create(1620, 900, false, Image.FORMAT_RGBA8)
var n := 0


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
	layer.dark_vision = false
	for c in World.creatures.duplicate():
		c.queue_free()
	var p: Player = GameState.player
	p.global_position = Vector3(-14, 0.1, 8)
	p.using_stick_aim = true
	p.aim_dir = Vector3(0, 0, -1)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 35.0
	var light := OmniLight3D.new()
	light.omni_range = 9.0
	light.light_energy = 2.2
	add_child(light)
	await _frames(20)
	# 1: Filhote parado (sem lâminas)
	await _shot(cam, light, p, Vector3(2.2, 1.4, -2.6))
	p.evolve()
	await _frames(130)
	var base := p.global_position
	# 2: Cavaleira de frente/3/4
	await _shot(cam, light, p, Vector3(2.0, 1.3, -2.8))
	# 3: de lado
	await _shot(cam, light, p, Vector3(3.4, 0.9, 0.0))
	# 4: andando (de cima e de lado)
	Input.action_press("move_left")
	await _frames(25)
	await _shot(cam, light, p, Vector3(0.3, 2.6, 2.6))
	Input.action_release("move_left")
	await _frames(30)
	# 5: golpe 1 no meio da varrida
	p.aim_dir = Vector3(0, 0, -1)
	p._start_attack(0)
	await _frames(6)
	await _shot(cam, light, p, Vector3(1.6, 1.6, -2.6), false)
	await _frames(30)
	# 6: câmera do jogo
	p._start_state(Player.State.NORMAL)
	p.snap_camera()
	p.camera.make_current()
	await _frames(4)
	await _grab()
	sheet.save_png("%s/cavaleira.png" % out)
	print("captura: cavaleira")
	get_tree().quit()


func _shot(cam: Camera3D, light: OmniLight3D, p: Node3D, off: Vector3, wait: bool = true) -> void:
	cam.make_current()
	cam.global_position = p.global_position + off
	cam.look_at(p.global_position + Vector3(0, 0.4, 0))
	light.global_position = p.global_position + Vector3(1.0, 3.0, -1.0)
	if wait:
		await _frames(3)
	await _grab()


func _grab() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img = img.get_region(Rect2i(img.get_width() / 2 - 480, 0, 960, 800))
	img.resize(540, 450)
	sheet.blit_rect(img, Rect2i(0, 0, 540, 450), Vector2i((n % 3) * 540, (n / 3) * 450))
	n += 1


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame
