class_name Corpse
extends Node3D
## Cadáver comestível. Apodrece depois de 3 minutos (ainda dá para comer, mas machuca).

const ROT_TIME := 180.0
const DESPAWN_TIME := 360.0

var display_name := ""
var satiety := 20.0
var silk := 10.0
var xp := 10
var age := 0.0
var reserved_by: Node = null   ## predador que está indo comer
var preserved := false         ## embrulhada em seda: não apodrece
var _color := Color.GRAY
var _radius := 0.4
var _mat: StandardMaterial3D
var _was_rotten := false


func setup(name_: String, satiety_: float, silk_: float, xp_: int, color: Color, radius: float) -> void:
	display_name = name_
	satiety = satiety_
	silk = silk_
	xp = xp_
	_color = color
	_radius = radius


func _ready() -> void:
	add_to_group("corpse")
	_mat = Fx.mat(Color(0.86, 0.86, 0.92) if preserved else _color.darkened(0.25))
	var body := Fx.sphere(_radius, _mat)
	body.scale = Vector3(1.0, 0.7, 1.4) if preserved else Vector3(1.2, 0.45, 1.2)
	body.position.y = _radius * 0.4
	add_child(body)


func _process(delta: float) -> void:
	if preserved:
		return
	age += delta
	if not _was_rotten and is_rotten():
		_was_rotten = true
		_mat.albedo_color = Color(0.3, 0.33, 0.18)
	if age >= DESPAWN_TIME:
		queue_free()


func is_rotten() -> bool:
	return age >= ROT_TIME


func consume() -> void:
	queue_free()
