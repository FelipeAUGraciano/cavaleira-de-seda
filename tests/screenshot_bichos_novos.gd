extends Node
## Captura da Formiga-de-seda (formigueiro e fila), da Cobra-das-frestas (escondida e no bote)
## e dos coletáveis novos. Uso: godot --path . res://tests/screenshot_bichos_novos.tscn -- <pasta>

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
	p.invuln = 999.0
	for c in World.creatures.duplicate():
		c.queue_free()
	await _frames(2)
	var base := p.global_position
	var hill := Anthill.new(7, [])
	hill.position = base + Vector3(-3.5, 0, -1.5)
	layer.ecosystem.add_child(hill)
	var k := 0
	for kind in ["fragmento", "cristal_seda", "presa"]:
		var pk := Pickup.new(kind, "")
		pk.position = base + Vector3(2.0 + k * 1.3, 0, 2.2)
		pk.collision_mask = 0
		layer.add_child(pk)
		k += 1
	var sn := Snake.new()
	sn.position = base + Vector3(3.5, 0.3, -2.5)
	sn.den = base + Vector3(3.5, 0, -2.5)
	sn.out_dir = Vector3(-0.6, 0, 0.8).normalized()
	layer.ecosystem.add_child(sn)
	await _frames(30)
	# formigas saindo em fila
	for a in hill.living():
		a.asleep = false
		a.needs.fatigue = 0.0
	p.rune_on = true
	await _seconds(1.0)
	await _shot("bichos_novos_1")
	# a cobra dá o bote
	p.global_position = sn.global_position + sn.out_dir * 4.0
	p.velocity = Vector3(2.5, 0, 0)
	for i in 120:
		await get_tree().physics_frame
		p.velocity = Vector3(2.5, 0, 0)
		if sn.cur_attack != null and sn.atk_phase == 0 and sn.atk_t > 0.25:
			break
	await _shot("bichos_novos_2_aviso")
	for i in 60:
		await get_tree().physics_frame
		if sn.cur_attack != null and sn.atk_phase >= 1:
			break
	await _frames(2)
	await _shot("bichos_novos_3_bote")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("captura: ", name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
