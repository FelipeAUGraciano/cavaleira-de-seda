extends Node
## A toca (G22 Fosso escuro) tomada, com as 4 portas de teia, e o menu da toca na aba da
## despensa. Uso: godot --path . res://tests/screenshot_toca.tscn -- <pasta>

var out := "user://shots"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	GameState.permadeath = false
	GameState.delete_save()
	GameState.dens = {}
	var layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	layer.hud.visible = false
	var p: Player = GameState.player
	p.invuln = 999.0
	var den: Den = layer.den
	World.clock.paused = true
	World.clock.set_phase(CaveClock.Phase.BRILHO)
	p.global_position = den.center + Vector3(0.3, 0.1, 0.3)
	await _frames(3)
	p.silk = p.max_silk
	den.claim(p)
	for i in den.slots.size():
		p.silk = p.max_silk
		den.weave_door(i, p)
	(den.doors[2] as DenDoor).take_hit(60.0)   # uma rasgada, para ver a diferença
	den.pantry = [{"name": "Sapo-de-rocha", "sat": 45, "silk": 15}, {"name": "Larva-de-musgo", "sat": 20, "silk": 10},
		{"name": "Larva-de-musgo", "sat": 20, "silk": 10}, {"name": "Formiga-de-seda", "sat": 8, "silk": 12}, {"name": "Presa antiga", "sat": 30, "silk": 15}]
	den.log_lines = ["Sapo-de-rocha invadiu e comeu Larva-de-musgo.", "A porta sudeste foi rasgada."]
	p.bag = [{"name": "Larva-de-musgo", "sat": 20, "silk": 10}]
	p.global_position = den.center + Vector3(0.0, 0.1, 3.0)
	p.rune_on = true
	await _frames(60)
	p.snap_camera()
	await _frames(10)
	await _shot("toca_1_portas")
	layer.hud.visible = true
	layer.hud.open_cocoon(den.cocoon)
	var m: CocoonMenu = layer.hud.cocoon_menu
	m._show_tab("desp")
	await _frames(10)
	await _shot("toca_2_menu")
	print("captura: toca")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame
