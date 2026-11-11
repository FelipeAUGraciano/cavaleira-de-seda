class_name Fire
extends Node3D
## Tocha ou fogueira: ilumina e QUEIMA fios e teias de captura por perto.

const BURN_RADIUS := 2.2

var size := 1.0
var _flame: MeshInstance3D
var _light: OmniLight3D
var _t := 0.0
var _check := 0.0


func _init(size_: float = 1.0) -> void:
	size = size_


func _ready() -> void:
	add_to_group("fire")
	var pole := Fx.cylinder(0.05 * size, 1.1 * size, Fx.mat(Color(0.3, 0.2, 0.12)))
	pole.position.y = 0.55 * size
	add_child(pole)
	_flame = Fx.sphere(0.16 * size, Fx.mat(Color(1.0, 0.55, 0.15), 4.0, true))
	_flame.scale = Vector3(1.0, 1.6, 1.0)
	_flame.position.y = 1.25 * size
	add_child(_flame)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.6, 0.25)
	_light.omni_range = 7.0 * size
	_light.light_energy = 1.6
	_light.shadow_enabled = true
	_light.position.y = 1.5 * size
	add_child(_light)


func _process(delta: float) -> void:
	_t += delta
	var f := 1.0 + 0.15 * sin(_t * 17.0) + 0.1 * sin(_t * 7.3)
	_light.light_energy = 1.6 * f
	_flame.scale = Vector3(1.0, 1.6 * f, 1.0)


func _physics_process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = 0.3
	for s in WebNetwork.strands.duplicate():
		if is_instance_valid(s) and s.distance_to(global_position) < BURN_RADIUS:
			Fx.beam(get_parent(), global_position + Vector3.UP, s.global_position + Vector3.UP * 0.1, Color(1.0, 0.5, 0.15), 0.4, 0.12)
			WebNetwork.remove_strand(s)
			EventBus.message.emit("O fogo queimou o seu fio!")
			GameState.say_once("fogo_fio", "Fogo e seda não combinam. Anotado. Doloridamente anotado.")
	for t in WebNetwork.traps.duplicate():
		if is_instance_valid(t) and Fx.flat_dist(t.global_position, global_position) < BURN_RADIUS:
			WebNetwork.remove_trap(t)
			t.queue_free()
			EventBus.message.emit("O fogo queimou a sua teia de captura!")
