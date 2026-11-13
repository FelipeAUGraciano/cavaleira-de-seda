class_name Track
extends Node3D
## Rastro no chão (marcas de arrasto da Centopeia). Some devagar em 2 minutos.
## No máximo MAX rastros no mundo: os mais velhos somem primeiro.

const LIFE := 120.0
const MAX := 90
static var _all: Array = []   ## sem tipo: guarda rastros que podem já ter sido apagados (troca de camada)

var _age := 0.0
var _mat: StandardMaterial3D


static func drop(parent: Node, pos: Vector3, dir: Vector3, width: float) -> void:
	var t := Track.new()
	parent.add_child(t)
	t.global_position = Vector3(pos.x, 0.025, pos.z)
	t.rotation.y = atan2(dir.x, dir.z)
	t._build(width)
	_all.append(t)
	while _all.size() > MAX:
		var old = _all.pop_front()
		if is_instance_valid(old):
			(old as Node).queue_free()


func _build(width: float) -> void:
	_mat = Fx.mat(Color(0.08, 0.07, 0.06), 0.0, false, 0.55)
	for side in [-1.0, 1.0]:
		var mark := Fx.box(Vector3(0.12, 0.01, 1.1), _mat)
		mark.position.x = side * width * 0.5
		add_child(mark)


func _exit_tree() -> void:
	_all.erase(self)   # camada trocada ou rastro apagado: sai da lista


func _process(delta: float) -> void:
	_age += delta
	_mat.albedo_color.a = 0.55 * (1.0 - _age / LIFE)
	if _age >= LIFE:
		queue_free()
