extends Node
## Props 3D do Berçário e a Mãe, num palco claro. Folha 3×2.
## Uso: godot --path . res://tests/screenshot_props.tscn -- <pasta>

var out := "user://shots"
var sheet := Image.create(1602, 900, false, Image.FORMAT_RGBA8)
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
	p.global_position = Vector3(-24, 0.1, 10)
	var o := Vector3(14, 0, 8)
	# fileira de props
	WebNetwork.create_cocoon(o + Vector3(-3, 0, 0))
	var corpse := Corpse.new()
	corpse.setup("Larva-de-musgo", 20, 10, 10, Color(0.4, 0.6, 0.3), 0.4)
	corpse.preserved = true
	layer.add_child(corpse)
	corpse.global_position = o + Vector3(-1.4, 0, 0.4)
	var pk := Pickup.new("cristal_pv")
	layer.add_child(pk)
	pk.global_position = o + Vector3(0.0, 0, 0.6)
	layer.add_fungus(o + Vector3(1.4, 0, 0.8), Color(0.75, 0.5, 1.0))
	layer.add_fungus(o + Vector3(2.1, 0, 0.4))
	for k in 3:
		var r := Models.instance("rocha_" + "abc"[k], 1.2, "max")
		layer.add_child(r)
		r.global_position = o + Vector3(-3.0 + k * 2.0, 0, 3.2)
	layer.add_web_decal(o + Vector3(3.6, 0, 2.6), 1.3)
	layer.add_anchor("Pteia", o + Vector3(-4.5, 0, -3.5), 4.0, 0.55, Color(0.8, 0.8, 0.9), "pilar_teia")
	for k in 3:
		layer.add_anchor("Est%d" % k, o + Vector3(-1.5 + k * 2.4, 0, -3.5), 3.5, 0.5, Color(0.3, 0.33, 0.34), "estalagmite_" + "abc"[k])
	await _frames(3)
	WebNetwork.create_strand(WebNetwork.anchors["Est0"], WebNetwork.anchors["Est1"])
	var egg := Models.instance("ovo", 0.9, "height")
	layer.add_child(egg)
	egg.global_position = o + Vector3(3.6, 0, -0.6)
	# a pata da Mãe
	var leg := MotherLeg.new()
	leg.points = [Vector3(-14, 0, -8)]
	leg.active = false
	layer.add_child(leg)
	# a Mãe inteira
	var mom := MotherChase.new()
	mom.route = PackedVector2Array([Vector2(-6, 14), Vector2(10, 14)])
	layer.add_child(mom)
	mom.begin()
	mom.active = false
	await _frames(10)
	mom._animate_legs(0.3, true)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 40.0
	cam.make_current()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	light.light_energy = 1.2
	add_child(light)
	await _shot(cam, o + Vector3(1.0, 4.5, 8.5), o + Vector3(0, 0.5, 0.5))
	await _shot(cam, o + Vector3(-1, 5.0, 3.0), o + Vector3(-1, 1.2, -3.5))
	await _shot(cam, o + Vector3(-3.0, 1.6, 2.5), o + Vector3(-1.8, 0.4, 0.2))
	await _shot(cam, Vector3(-14, 6, 8), Vector3(-14, 4, -9))
	var mp := mom.global_position
	await _shot(cam, mp + Vector3(2, 9, 20), mp + Vector3(-2, 3, 0))
	await _shot(cam, mp + Vector3(16, 6, 6), mp + Vector3(-2, 3, 0))
	sheet.save_png("%s/props.png" % out)
	print("captura: props")
	get_tree().quit()


func _shot(cam: Camera3D, from: Vector3, at: Vector3) -> void:
	cam.global_position = from
	cam.look_at(at, Vector3.UP)
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(534, 450)
	sheet.blit_rect(img, Rect2i(0, 0, 534, 450), Vector2i((n % 3) * 534, (n / 3) * 450))
	n += 1


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame
