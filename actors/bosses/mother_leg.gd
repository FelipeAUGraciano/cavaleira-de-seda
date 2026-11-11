class_name MotherLeg
extends Node3D
## A pata da Mãe vasculhando a despensa (B5). Sente movimento e luz:
##   runa acesa = percebe a 7 m; runa apagada e andando = 2,5 m; parada no escuro = invisível.
##   Correr (barulho) = percebe a 9 m.
## Quando percebe, marca o chão em vermelho e golpeia depois de 0,9 s (dá para esquivar).

const STRIKE_DAMAGE := 30.0
const WINDUP := 0.9
const MOVE_TIME := 2.2

var points: Array[Vector3] = []
var active := true
var _idx := 0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0
var _rest := 0.0
var _striking := false
var _strike_t := 0.0
var _strike_pos := Vector3.ZERO
var _leg: Node3D
var _marker: MeshInstance3D


func _ready() -> void:
	_leg = Node3D.new()
	add_child(_leg)
	var mat := Fx.mat(Color(0.1, 0.08, 0.16))
	var tip := Fx.cylinder(0.12, 1.2, mat)
	tip.position.y = 0.6
	_leg.add_child(tip)
	var lower := Fx.cylinder(0.32, 6.0, mat)
	lower.position.y = 4.2
	_leg.add_child(lower)
	var joint := Fx.sphere(0.5, Fx.mat(Color(0.78, 0.6, 0.25), 0.3))
	joint.position.y = 7.2
	_leg.add_child(joint)
	var upper := Fx.cylinder(0.3, 8.0, mat)
	upper.position = Vector3(0.0, 10.0, -2.6)
	upper.rotation.x = 0.6
	_leg.add_child(upper)
	Models.swap(_leg, "mae_pata", 11.0, [tip, lower, joint, upper], "height")
	_marker = Fx.cylinder(1.6, 0.03, Fx.mat(Color(1.0, 0.2, 0.2), 1.5, true, 0.5))
	_marker.visible = false
	add_child(_marker)
	if points.is_empty():
		points.append(Vector3.ZERO)
	_from = points[0]
	_to = points[0]
	_leg.position = _from
	_t = 1.0


func _process(delta: float) -> void:
	if not active:
		return
	var p := GameState.player as Player
	if _striking:
		_strike_t += delta
		_leg.position = _leg.position.lerp(_strike_pos + Vector3.UP * 2.5, clampf(delta * 6.0, 0.0, 1.0))
		if _strike_t >= WINDUP:
			_leg.position = _strike_pos
			_marker.visible = false
			_striking = false
			_rest = 1.4
			_from = _strike_pos
			_t = 1.0
			if p != null and not p.dead and Fx.flat_dist(p.global_position, _strike_pos) <= 1.7:
				p.take_damage(STRIKE_DAMAGE, _leg)
		return
	if p != null and not p.dead and _rest <= 0.6 and _can_sense(p):
		_start_strike(p.global_position)
		return
	if _rest > 0.0:
		_rest -= delta
		return
	if _t >= 1.0:
		_idx = (_idx + 1) % points.size()
		_from = _leg.position
		_from.y = 0.0
		_to = points[_idx]
		_t = 0.0
	_t = minf(_t + delta / MOVE_TIME, 1.0)
	_leg.position = _from.lerp(_to, smoothstep(0.0, 1.0, _t)) + Vector3.UP * sin(_t * PI) * 1.5
	if _t >= 1.0:
		_rest = 1.0


func _can_sense(p: Player) -> bool:
	var d := Fx.flat_dist(p.global_position, _leg.position)
	var moving := Vector2(p.velocity.x, p.velocity.z).length() > 0.5
	var r := 7.0 if p.rune_on else 2.5
	if p.noise_radius() >= 6.0:
		r = maxf(r, 9.0)
	return d < r and (moving or p.rune_on)


func _start_strike(pos: Vector3) -> void:
	_striking = true
	_strike_t = 0.0
	_strike_pos = Vector3(pos.x, 0.0, pos.z)
	_marker.position = _strike_pos + Vector3.UP * 0.05
	_marker.visible = true
	GameState.say_once("b5_visto", "Ela me sentiu!")
