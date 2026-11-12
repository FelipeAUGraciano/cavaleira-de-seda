extends Node
## Gera os PNGs das cavernas orgânicas das Galerias. Uso: godot --headless --path . res://tests/preview_organic.tscn -- <pasta>


func _ready() -> void:
	var out := "/tmp"
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	GameState.delete_save()
	var t0 := Time.get_ticks_msec()
	var layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	print("construída em %d ms" % (Time.get_ticks_msec() - t0))
	await get_tree().process_frame
	layer.upper.preview(out + "/org_cima.png")
	layer.lower.preview(out + "/org_baixo.png")
	print("criaturas: %d" % World.creatures.size())
	get_tree().quit()
