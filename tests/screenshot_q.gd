extends Node
## Golpes e fio da jogadora em sequência (câmera do jogo). Folha 3×2.
## Uso: godot --path . res://tests/screenshot_q.tscn -- <pasta>

var out := "user://shots"
var sheet := Image.create(1602, 900, false, Image.FORMAT_RGBA8)
var n := 0
var p: Player


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
	p = GameState.player
	p.evolve()
	await _frames(130)
	var base := Vector3(-14, 0.1, 8)
	p.global_position = base
	p.using_stick_aim = true
	p.aim_dir = Vector3(1, 0, 0)
	p.snap_camera()
	await _frames(10)
	# 1 combo (cone)
	Engine.time_scale = 0.12   # o renderizador de teste é lento: câmera lenta para pegar o meio dos golpes
	p._start_attack(0)
	await _frames(5)

	await _grab()
	await _frames(30)
	# 2 mordida (bote, cone verde)
	var l := Larva.new()
	l.position = base + Vector3(2.2, 0.2, 0.0)
	layer.ecosystem.add_child(l)
	await _frames(5)
	l.asleep = true
	p._start_bite()
	await _frames(7)
	await _grab()
	await _frames(40)
	# 3 puxão: fio voando até a larva
	if is_instance_valid(l):
		l.queue_free()
	var l2 := Larva.new()
	l2.position = p.global_position + Vector3(5.5, 0.2, 0.0)
	layer.ecosystem.add_child(l2)
	await _frames(5)
	p.silk = p.max_silk
	p._throw_silk()
	await _frames(4)
	await _grab()
	await _frames(14)
	await _grab()
	await _frames(40)
	# 5/6 voo até a parede: fio esticado e ela no ar
	p.global_position = base
	p.aim_dir = Vector3(0, 0, -1)
	await _frames(3)
	p._throw_silk()
	await _frames(12)
	await _grab()
	await _frames(6)
	await _grab()
	sheet.save_png("%s/golpes_q.png" % out)
	print("captura: golpes_q")
	get_tree().quit()


func _grab() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var c := p.camera.unproject_position(p.global_position)
	var r := Rect2i(int(clampf(c.x - 400, 0, img.get_width() - 800)), int(clampf(c.y - 340, 0, img.get_height() - 675)), 800, 675)
	img = img.get_region(r)
	img.resize(534, 450)
	sheet.blit_rect(img, Rect2i(0, 0, 534, 450), Vector2i((n % 3) * 534, (n / 3) * 450))
	n += 1


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame
