class_name Adventurer
extends Node3D
## Aventureiro humano visto de longe (Ato 1): anda por um caminho com tocha e some no fim.
## Ainda não luta: na v0.5 é só o primeiro encontro, à distância.

var route: PackedVector2Array = PackedVector2Array()
var speed := 2.2
var delay := 0.0
var color := Color(0.55, 0.4, 0.3)
var torch := false
var _s := 0.0
var _length := 0.0
var _t := 0.0
var _light: OmniLight3D


func _ready() -> void:
	add_to_group("adventurer")
	for i in route.size() - 1:
		_length += route[i].distance_to(route[i + 1])
	var mat := Fx.mat(color)
	var body := Fx.cylinder(0.32, 1.3, mat)
	body.position.y = 0.95
	add_child(body)
	var head := Fx.sphere(0.24, Fx.mat(Color(0.85, 0.7, 0.58)))
	head.position.y = 1.85
	add_child(head)
	var pack := Fx.box(Vector3(0.45, 0.6, 0.3), Fx.mat(color.darkened(0.4)))
	pack.position = Vector3(0.0, 1.15, 0.3)
	add_child(pack)
	if torch:
		var flame := Fx.sphere(0.13, Fx.mat(Color(1.0, 0.6, 0.2), 4.0, true))
		flame.position = Vector3(0.45, 2.1, -0.1)
		add_child(flame)
		_light = OmniLight3D.new()
		_light.light_color = Color(1.0, 0.6, 0.25)
		_light.omni_range = 9.0
		_light.light_energy = 2.0
		_light.position = Vector3(0.45, 2.3, -0.1)
		add_child(_light)
	visible = false
	_place(0.0)


func _process(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
		return
	visible = true
	_t += delta
	_s += speed * delta
	if _s >= _length:
		queue_free()
		return
	_place(_s)
	position.y = absf(sin(_t * 8.0)) * 0.06
	if _light != null:
		_light.light_energy = 2.0 + 0.3 * sin(_t * 15.0)


func _place(s: float) -> void:
	var acc := 0.0
	for i in route.size() - 1:
		var seg := route[i].distance_to(route[i + 1])
		if acc + seg >= s or i == route.size() - 2:
			var p := route[i].lerp(route[i + 1], clampf((s - acc) / maxf(seg, 0.001), 0.0, 1.0))
			position.x = p.x
			position.z = p.y
			var d := route[i + 1] - route[i]
			rotation.y = atan2(-d.x, -d.y)
			return
		acc += seg
