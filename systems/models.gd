class_name Models
extends RefCounted
## Troca as formas cinza pelos modelos 3D assim que eles chegam.
##
## Como usar: coloque o arquivo em  assets/models/<nome>/<nome>_vNN.glb
## (ex.: assets/models/sapo/sapo_v01.glb). O jogo pega sempre a versão mais alta,
## ajusta o tamanho, encosta a base no chão e centraliza. Se não houver arquivo, nada muda.
## A lista de nomes está na aba "Modelos 3D" do GDD.

const DEFAULT_ROOT := "res://assets/models"
const MAX_VERSION := 30
## glTF olha para +Z; as criaturas do jogo olham para -Z.
const DEFAULT_ROT_Y := 180.0

## Ajustes finos por modelo, preenchidos depois de ver cada um no jogo:
##   rot_y (graus), y (metros, sobe ou desce), scale (multiplica o tamanho)
##   legs: true = o modelo já veio com patas (as patas por código ficam escondidas)
const TUNING := {
	"irma_corpo": {"legs": true},
}

static var root := DEFAULT_ROOT
static var _paths := {}


static func clear_cache() -> void:
	_paths.clear()


static func path_for(model_name: String) -> String:
	if _paths.has(model_name):
		return _paths[model_name]
	var found := ""
	for v in range(MAX_VERSION, 0, -1):
		var p := "%s/%s/%s_v%02d.glb" % [root, model_name, model_name, v]
		if ResourceLoader.exists(p):
			found = p
			break
	_paths[model_name] = found
	return found


static func tuning(model_name: String) -> Dictionary:
	return TUNING.get(model_name, {})


static func has(model_name: String) -> bool:
	return model_name != "" and path_for(model_name) != ""


static func instance(model_name: String, size: float, fit: String = "max") -> Node3D:
	## Devolve o modelo pronto para pendurar no lugar da forma cinza, ou null.
	## fit: "max" (maior lado), "height" (altura) ou "length" (maior lado no chão).
	if not has(model_name):
		return null
	var scene := load(path_for(model_name)) as PackedScene
	if scene == null:
		push_warning("Modelo %s não abriu." % model_name)
		return null
	var model := scene.instantiate() as Node3D
	if model == null:
		return null
	var box := bounds(model, Transform3D.IDENTITY)
	if box.size == Vector3.ZERO:
		model.free()
		return null
	var dim := maxf(box.size.x, maxf(box.size.y, box.size.z))
	if fit == "height":
		dim = box.size.y
	elif fit == "length":
		dim = maxf(box.size.x, box.size.z)
	var tune: Dictionary = TUNING.get(model_name, {})
	var s := size / maxf(dim, 0.001) * float(tune.get("scale", 1.0))
	var center := box.get_center()

	var holder := Node3D.new()
	holder.name = "Modelo_" + model_name
	var pivot := Node3D.new()
	pivot.rotation_degrees.y = float(tune.get("rot_y", DEFAULT_ROT_Y))
	holder.add_child(pivot)
	model.scale = Vector3.ONE * s
	model.position = Vector3(-center.x * s, -box.position.y * s + float(tune.get("y", 0.0)), -center.z * s)
	pivot.add_child(model)
	return holder


static func swap(parent: Node3D, model_name: String, size: float, placeholders: Array, fit: String = "max") -> Node3D:
	## Se o modelo existir: esconde as formas cinza, pendura o modelo em parent e o devolve.
	var m := instance(model_name, size, fit)
	if m == null:
		return null
	for p in placeholders:
		if p is Node3D and is_instance_valid(p):
			(p as Node3D).visible = false
	parent.add_child(m)
	return m


static func set_overlay(node: Node, mat: Material) -> void:
	## Camada de brilho por cima do modelo (piscar ao levar dano, aviso de ataque, tinta).
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).material_overlay = mat
	for c in node.get_children():
		set_overlay(c, mat)


static func tint(node: Node, color: Color) -> void:
	## Recolore o modelo multiplicando a cor de cada material (cópia só deste modelo).
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i) as BaseMaterial3D
			if m == null:
				continue
			var copy := m.duplicate() as BaseMaterial3D
			copy.albedo_color = copy.albedo_color * color
			mi.set_surface_override_material(i, copy)
	for c in node.get_children():
		tint(c, color)


static func bounds(node: Node, xform: Transform3D) -> AABB:
	## Caixa que envolve todas as malhas, no espaço de quem chamou.
	var t := xform
	if node is Node3D:
		t = xform * (node as Node3D).transform
	var box := AABB()
	var started := false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		box = t * (node as MeshInstance3D).mesh.get_aabb()
		started = true
	for c in node.get_children():
		var cb := bounds(c, t)
		if cb.size == Vector3.ZERO:
			continue
		box = cb if not started else box.merge(cb)
		started = true
	return box
