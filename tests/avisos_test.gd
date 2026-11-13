extends Node
## Carrega todos os scripts do jogo e falha se algum tiver aviso do GDScript.
## Rodar com os avisos virando erro:  godot --headless --path . res://tests/avisos_test.tscn
## (o override.cfg de checagem fica fora do git; veja tools/checar_avisos.sh)

func _ready() -> void:
	var files: Array[String] = []
	_collect("res://", files)
	for f in files:
		var s = load(f)
		if s == null:
			print("  FALHA ", f)
	print("\n==== checados %d scripts ====" % files.size())
	get_tree().quit()


func _collect(dir: String, out: Array[String]) -> void:
	for d in DirAccess.get_directories_at(dir):
		if d.begins_with(".") or d == "tests" or d == "addons":
			continue
		_collect(dir.path_join(d), out)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
