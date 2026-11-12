class_name AcidPuddle
extends Node3D
## Poça de ácido deixada pelo cuspe do sapo furioso: queima quem pisa por alguns segundos.
## Resistência a Ácido 3 ignora.

const DPS := 6.0

var radius := 1.4
var life := 5.0
var _mat: StandardMaterial3D


static func spawn(parent: Node, pos: Vector3, r: float, secs: float) -> AcidPuddle:
	var a := AcidPuddle.new()
	a.radius = r
	a.life = secs
	parent.add_child(a)
	a.global_position = Vector3(pos.x, 0.0, pos.z)
	return a


func _ready() -> void:
	add_to_group("hazard")
	_mat = Fx.mat(Color(0.55, 0.95, 0.25), 1.2, true, 0.45)
	var disc := Fx.cylinder(radius, 0.02, _mat)
	disc.position.y = 0.05
	add_child(disc)


func _physics_process(delta: float) -> void:
	life -= delta
	_mat.albedo_color.a = 0.45 * clampf(life, 0.0, 1.0)
	if life <= 0.0:
		queue_free()
		return
	var p := GameState.player as Player
	if p == null or p.dead or p.resist_acid >= 3 or p.on_strand:
		return
	if Fx.flat_dist(p.global_position, global_position) <= radius and p.global_position.y < 0.6:
		p._hurt(DPS * delta * (0.5 if p.resist_acid > 0 else 1.0))
		p._hurt_flash = 0.1
