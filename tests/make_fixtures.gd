extends SceneTree
## Gera modelos .glb falsos (caixas) para testar a troca de modelos sem depender da IA.
## Rodar uma vez:  godot --headless --path . -s res://tests/make_fixtures.gd  e depois --import

func _init() -> void:
	_make("sapo", Vector3(3.0, 1.5, 4.0))
	_make("cavaleira_corpo", Vector3(1.0, 0.8, 2.0))
	_make("pilar_teia", Vector3(1.0, 10.0, 1.0))
	quit()


func _make(model_name: String, size: Vector3) -> void:
	var root := Node3D.new()
	root.name = model_name
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = Vector3(5.0, 2.0, -1.0)   # fora do centro, para testar o recentrar
	root.add_child(mi)
	var dir := "res://tests/fixtures/models/%s" % model_name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	doc.append_from_scene(root, state)
	var err := doc.write_to_filesystem(state, "%s/%s_v01.glb" % [dir, model_name])
	print("%s: %s" % [model_name, error_string(err)])
	root.free()
