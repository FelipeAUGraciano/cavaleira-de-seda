extends Node
## Mapa completo de cada camada, com tudo revelado. Uso: godot --path . res://tests/screenshot_mapas.tscn -- <pasta>

var out := "user://shots"


func _ready() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	for path in ["res://world/layers/bercario.tscn", "res://world/layers/galerias.tscn"]:
		GameState.delete_save()
		GameState.said = {}
		GameState.flags = {}
		var layer = load(path).instantiate()
		add_child(layer)
		await _frames(20)
		for r in layer.rooms:
			layer.map_system.revealed[r["id"]] = true
		for l in layer.map_system.locks:
			l["seen"] = true
		layer.hud._show_help = false
		layer.hud._show_map = true
		layer.hud.show_all_creatures = true
		GameState.player.camera.cull_mask = 0   # só o mapa, sem o 3D por trás
		layer.hud._hint_time = 0.0
		layer.hud._mono_time = 0.0
		layer.hud._messages.clear()
		await _frames(10)
		await _shot("mapa_" + layer.layer_id)
		layer.queue_free()
		await _frames(5)
	GameState.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("captura: ", name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
