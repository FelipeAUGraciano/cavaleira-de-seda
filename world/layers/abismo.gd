extends LayerBase
## A — Abismo (provisório). Só o lugar onde a Cavaleira cai no fim do Ato 1, para o save
## e a continuação funcionarem. A camada de verdade (escuridão total, Serpente-cega) vem depois.

var cave: CaveBuilder


func _configure() -> void:
	layer_id = "A"
	layer_name = "Abismo"
	layer_subtitle = "Ato 2 · Em breve"
	spawn_point = Vector3(0.0, 0.1, 0.0)
	ambient_color = Color(0.2, 0.22, 0.35)
	ambient_energy = 0.18
	fog_color = Color(0.01, 0.01, 0.03)
	rooms = [
		{"id": "A1", "name": "Fundo da Fenda", "checkpoint": true,
			"shapes": [CaveBuilder.blob(Vector2(0, 0), 8.0, 1.4)],
			"line_id": "a1_fundo", "line": "...Tô viva. Acho. Tá TUDO escuro aqui embaixo."},
	]


func _build_level() -> void:
	cave = CaveBuilder.new()
	cave.floor_color = Color(0.16, 0.16, 0.22)
	cave.rock_color = Color(0.08, 0.08, 0.12)
	cave.rooms = rooms
	map_grid = cave.build(self)
	cave.scatter_decor(self, 5)
	for i in 4:
		var ang := i * TAU / 4.0 + 0.4
		add_anchor("A1_%d" % i, Vector3(cos(ang) * 5.0, 0, sin(ang) * 5.0), 3.0, 0.45, Color(0.25, 0.25, 0.32))
	var far := OmniLight3D.new()
	far.light_color = Color(0.45, 0.55, 1.0)
	far.omni_range = 9.0
	far.light_energy = 0.4
	far.position = Vector3(0, 12, -4)
	add_child(far)


func _start() -> void:
	if GameState.flags.has("ato1_fim") and not GameState.flags.has("ato1_tela"):
		GameState.flags["ato1_tela"] = true
		EventBus.big_message.emit("Fim do Ato 1")
		EventBus.message.emit("O Abismo chega na próxima versão. Teça um casulo (C) e descanse para salvar aqui.")
