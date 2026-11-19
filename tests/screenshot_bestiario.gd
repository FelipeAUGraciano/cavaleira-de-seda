extends Node
## Capturas do Bestiário (ficha completa, só vista, desconhecida, perigo) e do botão no casulo.
## Uso: godot --path . res://tests/screenshot_bestiario.tscn -- <pasta>

var out := "user://shots"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	reparent(get_tree().root)
	get_tree().current_scene = null
	GameState.delete_save()
	GameState.new_game()
	await _frames(40)
	var layer = get_tree().current_scene
	# anota alguns bichos em níveis diferentes, com a ficha copiada de bichos de verdade
	var far: Vector3 = GameState.player.global_position + Vector3(0, -50, 0)
	for spec in [[Scorpion.new(), 3], [Sister.new(true), 3], [Frog.new(), 2], [Larva.new(), 3], [Sister.new(false), 1],
			[Bat.new(), 2], [Centipede.new(), 1], [Lizard.new(), 1]]:
		var c: Creature = spec[0]
		c.set_meta("vitrine", true)
		layer.add_child(c)
		c.global_position = far
		c.process_mode = Node.PROCESS_MODE_DISABLED
		Bestiary.see(c)
		if spec[1] >= 2:
			Bestiary.defeated(c)
		if spec[1] >= 3:
			Bestiary.eaten(c.display_name)
		c.queue_free()
	Bestiary.see_id("mae")
	Bestiary.see_id("colosso")
	await _frames(10)
	var hud = layer.hud
	hud.open_bestiary("jogo", "escorpiao")
	await _frames(20)
	await _shot("bestiario_completo")
	hud.bestiary.select("sapo")
	await _frames(10)
	await _shot("bestiario_derrotado")
	hud.bestiary.select("lagarto")
	await _frames(10)
	await _shot("bestiario_visto")
	hud.bestiary.select("colosso")
	await _frames(20)
	await _shot("bestiario_perigo")
	hud.bestiary.select("rainha")
	await _frames(20)
	await _shot("bestiario_desconhecido")
	hud.bestiary.close()
	await _frames(10)
	GameState.delete_save()
	get_tree().quit()


func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, tag])
	print("captura: ", tag)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
