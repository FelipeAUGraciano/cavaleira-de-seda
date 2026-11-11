extends Node
## Close dos modelos já recebidos, na câmera do jogo. Uso: godot --path . res://tests/screenshot_modelos.tscn -- <pasta>

var out := "user://shots"


func _ready() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	GameState.delete_save()
	GameState.said = {"inicio": true, "b1_fome": true, "hint_B1": true}
	GameState.flags = {}
	var layer = load("res://world/layers/bercario.tscn").instantiate()
	add_child(layer)
	await _frames(30)
	var p: Player = GameState.player
	p.using_stick_aim = true
	p.aim_dir = Vector3(1, 0, 0)
	layer.hud.visible = false
	# irmãs em volta da Cavaleira: duas menores e uma faminta
	var spots := [Vector3(-57.5, 0.3, 5.0), Vector3(-61.5, 0.3, 3.0), Vector3(-58.5, 0.3, 8.0)]
	var i := 0
	for s in get_tree().get_nodes_in_group("creature"):
		if s is Sister and i < spots.size():
			s.global_position = spots[i]
			s.set_physics_process(i == 0)
			i += 1
	var hunter := Sister.new(true)
	hunter.position = Vector3(-62.0, 0.3, 7.0)
	layer.ecosystem.add_child(hunter)
	hunter.set_physics_process(false)
	p.global_position = Vector3(-60.0, 0.1, 5.5)
	p.snap_camera()
	p.camera.size = 9.0
	await _frames(40)
	await _shot("modelo_irmas")
	get_tree().paused = false
	layer.queue_free()
	await _frames(5)

	var gal = load("res://world/layers/galerias.tscn").instantiate()
	add_child(gal)
	await _frames(30)
	p = GameState.player
	gal.hud.visible = false
	var frog: Frog = null
	for c in get_tree().get_nodes_in_group("creature"):
		if c is Frog:
			frog = c
	frog.set_physics_process(false)
	frog.global_position = Vector3(-3.0, 0.0, 33.0)
	frog._visual.rotation.y = 0.8
	p.global_position = Vector3(0.5, 0.1, 35.0)
	p.aim_dir = Vector3(-1, 0, 0)
	p.snap_camera()
	p.camera.size = 9.0
	await _frames(40)
	await _shot("modelo_sapo")
	GameState.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("captura: ", name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
