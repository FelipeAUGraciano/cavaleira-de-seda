class_name MotherChase
extends Node3D
## A Mãe acordada perseguindo a Cavaleira pela Fuga (B6).
## Anda para leste em linha reta, passa por cima dos abismos e para no túnel, onde não cabe.
## Se alcança a jogadora: 35 de dano e um empurrão para a frente.

const CATCH_DAMAGE := 35.0

var start_x := 46.0
var stop_x := 95.0
var speed := 6.5
var active := false
var finished := false
var _hit_cd := 0.0
var _roar := 0.0   ## pausa depois de um golpe: chance de fugir
var _t := 0.0
var _legs: Array[Node3D] = []


func _ready() -> void:
	visible = false
	var dark := Fx.mat(Color(0.09, 0.07, 0.14))
	var head := Fx.sphere(2.6, dark)
	head.scale = Vector3(1.1, 0.8, 1.0)
	head.position = Vector3(0.0, 3.0, 0.0)
	add_child(head)
	var abdomen := Fx.sphere(3.6, dark)
	abdomen.position = Vector3(-5.0, 4.0, 0.0)
	add_child(abdomen)
	var rune := Fx.cylinder(1.4, 0.1, Fx.mat(Color(0.9, 0.25, 0.3), 2.5, true))
	rune.position = Vector3(-5.0, 7.6, 0.0)
	add_child(rune)
	var eye_mat := Fx.mat(Color(1.0, 0.3, 0.2), 3.0, true)
	for i in 8:
		var eye := Fx.sphere(0.32 if i < 2 else 0.18, eye_mat)
		eye.position = Vector3(2.5, 3.6 + (i % 3) * 0.35, -1.0 + (i % 4) * 0.66)
		add_child(eye)
	var leg_mat := Fx.mat(Color(0.12, 0.1, 0.18))
	for i in 8:
		var side := -1.0 if i < 4 else 1.0
		var pivot := Node3D.new()
		pivot.position = Vector3(1.0 - (i % 4) * 1.4, 3.0, side * 1.6)
		var leg := Fx.box(Vector3(0.45, 0.45, 7.0), leg_mat)
		leg.position = Vector3(0.0, -1.4, side * 3.4)
		leg.rotation.x = side * 0.45
		pivot.add_child(leg)
		add_child(pivot)
		_legs.append(pivot)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.3, 0.25)
	light.omni_range = 9.0
	light.light_energy = 1.5
	light.position = Vector3(3.0, 4.0, 0.0)
	add_child(light)


func begin() -> void:
	active = true
	finished = false
	visible = true
	position = Vector3(start_x, 0.0, 0.0)
	EventBus.big_message.emit("A MÃE ACORDOU!")


func reset() -> void:
	active = false
	finished = false
	visible = false
	position = Vector3(start_x, 0.0, 0.0)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_t += delta
	_hit_cd -= delta
	_roar -= delta
	if _roar <= 0.0:
		position.x = minf(position.x + speed * delta, stop_x)
	for i in _legs.size():
		_legs[i].rotation.y = sin(_t * 9.0 + (i % 2) * PI) * 0.35
	var p := GameState.player as Player
	if p != null and not p.dead and _hit_cd <= 0.0:
		var gap := p.global_position.x - (position.x + 2.8)
		if gap < 1.2 and absf(p.global_position.z - position.z) < 6.0:
			p.invuln = 0.0
			p.take_damage(CATCH_DAMAGE, self, false)
			p.external_velocity = Vector3(14.0, 0.0, 0.0)
			_hit_cd = 1.2
			_roar = 0.8
			GameState.say_once("b6_pega", "AAAH! Ela é ENORME!")
	if position.x >= stop_x and not finished:
		finished = true
		EventBus.message.emit("A Mãe não cabe no túnel!")
