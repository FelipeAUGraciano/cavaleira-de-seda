extends Node
## Menu do casulo: as 3 abas (Filhote e Cavaleira). Uma imagem por aba, 1600×900.
## Uso: godot --path . res://tests/screenshot_casulo.tscn -- <pasta>

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
	for c in World.creatures.duplicate():
		c.queue_free()
	var p: Player = GameState.player
	p.evolve()
	await _frames(120)
	p.level = 7
	p.xp = 140
	p.skill_points = 3
	for id in ["afiadas", "fio_leve", "runa_oculta", "carapaca", "puxao", "tecela"]:
		p.skills[id] = true
	p.hp = 84
	p.silk = 70
	p.pantry = [{"name": "Larva-de-musgo", "sat": 20, "silk": 10}, {"name": "Larva-de-musgo", "sat": 20, "silk": 10}, {"name": "Irmã-aranha", "sat": 30, "silk": 15}]
	var cocoon := WebNetwork.create_cocoon(p.global_position + Vector3(0, 0, -1.6))
	await _frames(5)
	layer.hud.open_cocoon(cocoon)
	var m: CocoonMenu = layer.hud.cocoon_menu
	m.selected = "espiral"
	await _frames(20)
	await _shot("casulo_habilidades")
	m._show_tab("evo")
	await _frames(5)
	await _shot("casulo_evolucao")
	m._show_tab("desp")
	await _frames(5)
	await _shot("casulo_despensa")
	print("captura: casulo")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame
