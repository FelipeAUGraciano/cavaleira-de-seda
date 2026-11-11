extends Node
## Gera capturas de tela de situações do protótipo (para revisão visual).
## Rodar com tela: godot --path . res://tests/screenshot.tscn -- <pasta de saída>

var main
var out_dir := "user://shots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameState.delete_save()
	GameState.said = {}
	main = load("res://world/main.tscn").instantiate()
	add_child(main)
	var p: Player = null
	await _frames(30)
	p = GameState.player
	p.using_stick_aim = true
	p.aim_dir = Vector3(1, 0, -0.4).normalized()
	await _frames(5)
	await _shot("01_inicio")

	# Perto do abismo, com fio e casulo
	WebNetwork.create_cocoon(Vector3(-9.0, 0.0, 4.0))
	WebNetwork.create_strand(WebNetwork.anchors["Pilar_06"], WebNetwork.anchors["Pilar_12"])
	WebNetwork.create_strand(WebNetwork.anchors["Pilar_06"], WebNetwork.anchors["Pilar_04"])
	p.global_position = Vector3(-1.0, 0.15, 6.0)
	p.snap_camera()
	await _frames(40)
	await _shot("02_fio_sobre_abismo")

	# Modo Tecelagem com um ponto A escolhido
	Input.action_press("weave")
	await _frames(10)
	p.weave_first = WebNetwork.anchors["Pilar_05"]
	p._refresh_anchor_highlights()
	await _frames(20)
	await _shot("03_modo_tecelagem")
	Input.action_release("weave")
	await _frames(10)

	# Perto do sapo, runa apagada, lendo a criatura
	var frog: Frog = null
	for f in get_tree().get_nodes_in_group("predator"):
		var fr := f as Frog
		if fr != null and fr.global_position.x < 0.0:
			frog = fr
	if frog != null:
		p.global_position = frog.global_position + Vector3(2.5, 0.15, -3.0)
		p.snap_camera()
		Input.action_press("read")
		var to := frog.global_position - p.global_position
		to.y = 0.0
		p.aim_dir = to.normalized()
		await _frames(30)
		await _shot("04_sapo_leitura")
		Input.action_release("read")
	GameState.delete_save()
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("captura: ", name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
