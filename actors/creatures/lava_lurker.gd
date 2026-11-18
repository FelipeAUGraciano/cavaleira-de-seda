class_name LavaLurker
extends Creature
## Base dos bichos que moram dentro da lava (Peixe-magma, Verme de lava). Ficam escondidos
## embaixo da superfície (não dá para acertar), saem quando você chega perto da beirada,
## atacam e voltam. Fora da lava ficam vulneráveis.

enum Mode { HIDDEN, OUT, BACK }

var lava_home := Vector3.ZERO      ## ponto dentro da lava onde ele mora
var detect_r := 8.0
var mode: Mode = Mode.HIDDEN
var mode_t := 0.0
var cooldown := 0.0


func _ready() -> void:
	super._ready()
	uses_interest = false
	hover_y = 0.0
	_web_immune = 999.0
	lava_home = Vector3(global_position.x, 0.0, global_position.z)
	add_to_group("predator")
	add_to_group("lava_lurker")
	_visual.position.y = -1.6


func _make_brain() -> Brain:
	return null


func notices_player(p: Player) -> bool:
	return mode != Mode.HIDDEN and flat_dist_to(p) < detect_r


func entangle(_d: float) -> float:
	return 0.0


func take_damage(amount: float, source: Node3D = null) -> void:
	if mode == Mode.HIDDEN:
		return   # embaixo da lava ninguém alcança
	super.take_damage(amount, source)


func can_surface(p: Player) -> bool:
	return p != null and not p.dead and cooldown <= 0.0 and flat_dist_to(p) < detect_r


func _think(delta: float) -> Vector3:
	mode_t += delta
	cooldown -= delta
	_web_immune = 999.0
	return Vector3.ZERO


func surface_fx(at: Vector3) -> void:
	if not near_player:
		return
	var m := Fx.mat(Color(1.0, 0.55, 0.1), 2.5, true, 0.8)
	for k in 5:
		var d := Fx.sphere(0.18, m)
		get_parent().add_child(d)
		d.global_position = at + Vector3(randf_range(-0.6, 0.6), 0.1, randf_range(-0.6, 0.6))
		var tw := d.create_tween()
		tw.tween_property(d, "position", d.position + Vector3(0, randf_range(0.8, 1.6), 0), 0.4)
		tw.tween_property(d, "position", d.position + Vector3(0, -0.5, 0), 0.4)
		tw.tween_callback(d.queue_free)
