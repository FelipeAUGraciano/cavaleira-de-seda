extends Node
## Setas de vibração em volta da aranha. Uso: godot --path . res://tests/screenshot_vibracao.tscn -- <pasta>

var out := "user://shots"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	GameState.delete_save()
	var layer = load("res://world/layers/test_chamber.tscn").instantiate()
	add_child(layer)
	await get_tree().create_timer(1.0).timeout
	var p: Player = GameState.player
	var l := Larva.new()
	l.position = p.global_position + Vector3(-7, 0.3, -5)
	layer.ecosystem.add_child(l)
	var f := Frog.new()
	f.position = p.global_position + Vector3(9, 0.3, 3)
	layer.ecosystem.add_child(f)
	await get_tree().create_timer(0.3).timeout
	EventBus.web_touched.emit(p.global_position + Vector3(-7, 0, -5), l)
	EventBus.web_touched.emit(p.global_position + Vector3(9, 0, 3), f)
	EventBus.web_touched.emit(p.global_position + Vector3(0, 0, 14), null)
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/vibracao.png" % out)
	print("captura: vibracao")
	get_tree().quit()
