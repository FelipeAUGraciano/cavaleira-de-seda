class_name MotherChase
extends Node3D
## A Mãe acordada perseguindo a Cavaleira pela Fuga (B6).
## Segue o túnel curvo (uma linha de pontos), passa por cima dos abismos e para antes do túnel
## de saída, onde não cabe. Se alcança a jogadora: 35 de dano, um empurrão para a frente e uma
## pausa de 0,8 s rugindo (chance de fugir).

const CATCH_DAMAGE := 35.0
const FRONT := 3.0          ## distância do centro até a "boca"

var route := PackedVector2Array()   ## caminho no plano XZ (x, z)
var speed := 6.5
var active := false
var finished := false
var progress := 0.0                 ## metros percorridos no caminho
var _length := 0.0
var _hit_cd := 0.0
var _roar := 0.0
var _t := 0.0
var _legs: Array[Node3D] = []


func _ready() -> void:
	visible = false
	for i in route.size() - 1:
		_length += route[i].distance_to(route[i + 1])
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
	var parts: Array = [head, abdomen, rune]
	for i in 8:
		var eye := Fx.sphere(0.32 if i < 2 else 0.18, eye_mat)
		eye.position = Vector3(2.5, 3.6 + (i % 3) * 0.35, -1.0 + (i % 4) * 0.66)
		add_child(eye)
		parts.append(eye)
	var body_model := Models.swap(self, "mae_corpo", 12.0, parts, "length")
	if body_model != null:
		body_model.position = Vector3(-3.0, 1.2, 0.0)
		body_model.rotation_degrees.y = -90.0   # o modelo olha para -Z; a Mãe corre para +X
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
		var leg_model := Models.instance("mae_pata", 7.5, "max")
		if leg_model != null:
			var wrap := Node3D.new()
			wrap.transform = leg.transform
			pivot.add_child(wrap)
			leg_model.rotation.x = PI * 0.5   # comprimento do modelo (Y) ao longo da pata (Z)
			leg_model.position.z = -3.6
			wrap.add_child(leg_model)
			leg.visible = false
		_legs.append(pivot)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.3, 0.25)
	light.omni_range = 9.0
	light.light_energy = 1.5
	light.position = Vector3(3.0, 4.0, 0.0)
	add_child(light)
	_place(0.0)


func begin() -> void:
	active = true
	finished = false
	visible = true
	progress = 0.0
	_place(progress)
	EventBus.big_message.emit("A MÃE ACORDOU!")


func reset() -> void:
	active = false
	finished = false
	visible = false
	progress = 0.0
	_place(progress)


func point_at(s: float) -> Array:
	## [posição, direção] no caminho, a s metros do início.
	var left := clampf(s, 0.0, _length)
	for i in route.size() - 1:
		var seg := route[i].distance_to(route[i + 1])
		if left <= seg or i == route.size() - 2:
			var dir := (route[i + 1] - route[i]).normalized()
			return [route[i] + dir * minf(left, seg), dir]
		left -= seg
	return [route[0], Vector2.RIGHT]


func progress_of(p: Vector2) -> Array:
	## [metros no caminho do ponto mais próximo, distância até o caminho]
	var best_d := 1e9
	var best_s := 0.0
	var acc := 0.0
	for i in route.size() - 1:
		var a := route[i]
		var b := route[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best_d:
			best_d = d
			best_s = acc + ab.length() * t
		acc += ab.length()
	return [best_s, best_d]


func _place(s: float) -> void:
	var pd := point_at(s)
	var pos: Vector2 = pd[0]
	var dir: Vector2 = pd[1]
	position = Vector3(pos.x, 0.0, pos.y)
	rotation.y = atan2(-dir.y, dir.x)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_t += delta
	_hit_cd -= delta
	_roar -= delta
	if _roar <= 0.0:
		progress = minf(progress + speed * delta, _length)
		_place(progress)
	for i in _legs.size():
		_legs[i].rotation.y = sin(_t * 9.0 + (i % 2) * PI) * 0.35
	var p := GameState.player as Player
	if p != null and not p.dead and _hit_cd <= 0.0:
		var pr := progress_of(Vector2(p.global_position.x, p.global_position.z))
		var gap: float = pr[0] - (progress + FRONT)
		if gap < 1.2 and gap > -8.0 and pr[1] < 6.5:
			p.invuln = 0.0
			p.take_damage(CATCH_DAMAGE, self, false)
			var fwd: Vector2 = point_at(progress)[1]
			p.external_velocity = Vector3(fwd.x, 0.0, fwd.y) * 14.0
			_hit_cd = 1.2
			_roar = 0.8
			GameState.say_once("b6_pega", "AAAH! Ela é ENORME!")
	if progress >= _length and not finished:
		finished = true
		EventBus.message.emit("A Mãe não cabe no túnel!")
