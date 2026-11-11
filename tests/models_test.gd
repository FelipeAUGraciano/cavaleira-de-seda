extends Node
## Teste da troca de modelos: usa caixas falsas em tests/fixtures/models (geradas por make_fixtures.gd).
## Rodar:  godot --headless --path . res://tests/models_test.tscn

var failures := 0


func _ready() -> void:
	Models.root = "res://tests/fixtures/models"
	Models.clear_cache()
	await get_tree().process_frame

	_check(Models.has("sapo"), "acha sapo_v01.glb")
	_check(not Models.has("larva"), "sem arquivo, sem modelo (larva continua cinza)")

	var m := Models.instance("sapo", 2.0, "length")
	add_child(m)
	var box := Models.bounds(m, Transform3D.IDENTITY)
	_check(absf(maxf(box.size.x, box.size.z) - 2.0) < 0.01, "escala pelo maior lado no chão (%.2f m)" % maxf(box.size.x, box.size.z))
	_check(absf(box.position.y) < 0.01, "base encostada no chão (y = %.2f)" % box.position.y)
	var c := box.get_center()
	_check(absf(c.x) < 0.01 and absf(c.z) < 0.01, "modelo centralizado (%.2f, %.2f)" % [c.x, c.z])

	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(20, 1, 20)
	cs.shape = shape
	cs.position.y = -0.5
	floor_body.add_child(cs)
	add_child(floor_body)

	var frog := Frog.new()
	frog.position = Vector3(0, 0.3, 0)
	add_child(frog)
	await get_tree().process_frame
	var fm := frog._visual.get_node_or_null("Modelo_sapo") as Node3D
	_check(fm != null, "sapo usa o modelo")
	var hidden := 0
	for n in frog._visual.get_children():
		if n != fm and not (n as Node3D).visible:
			hidden += 1
	_check(hidden == 3, "formas cinza do sapo escondidas (%d)" % hidden)
	frog.telegraph = true
	frog._anim_t = 0.05
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(frog._overlay != null and frog._overlay.albedo_color.a > 0.05, "aviso de ataque brilha por cima do modelo")

	var larva := Larva.new()
	larva.position = Vector3(4, 0.3, 0)
	add_child(larva)
	await get_tree().process_frame
	_check(larva._model == null and (larva._visual.get_child(0) as Node3D).visible, "larva sem modelo fica cinza")

	var a := WebAnchor.new(4.0, 0.5, Color.WHITE)
	a.model_name = "pilar_teia"
	a.position = Vector3(-4, 0, 0)
	add_child(a)
	var am := a.get_node_or_null("Modelo_pilar_teia") as Node3D
	_check(am != null and absf(Models.bounds(am, Transform3D.IDENTITY).size.y - 4.45) < 0.01, "pilar de teia na altura do pilar")

	var p := Player.new()
	p.position = Vector3(0, 0.3, 5)
	add_child(p)
	await get_tree().process_frame
	var pm := p._visual.get_node_or_null("Modelo_cavaleira_corpo") as Node3D
	_check(pm != null, "Cavaleira usa o modelo do corpo")
	_check(p._scarf_tail.visible, "cachecol continua por código")

	Models.root = Models.DEFAULT_ROOT
	Models.clear_cache()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	print(("  ok    " if cond else "  FALHA ") + label)
	if not cond:
		failures += 1
