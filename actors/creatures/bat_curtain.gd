class_name BatCurtain
extends Node3D
## Cortina viva (A8): centenas de morcegos gigantes pendurados no teto do túnel, tão juntos
## que viram uma cortina de asas. Dormem enquanto nada brilha nem faz barulho.
##   - Runa acesa ou correndo por baixo: acordam, a cortina se fecha em volta de você
##     (empurra para trás e machuca) até você sair; depois voltam a dormir.
##   - Runa apagada e andando devagar: passa por baixo sem acordar ninguém.
##   - Pulso Espiral perto: caem atordoados por alguns segundos e o túnel abre de vez.

enum Mode { SLEEP, AWAKE, STUNNED }

const ZONE_HALF := 3.2       ## metros para cada lado do meio da cortina (ao longo do túnel)
const ZONE_WIDTH := 3.0      ## meia largura
const PUSH := 9.0
const DAMAGE := 7.0
const STUN_TIME := 9.0
const WAKE_NOISE := 6.0

var a := Vector3.ZERO        ## o túnel passa de a para b (a cortina fica no meio)
var b := Vector3.ZERO
var mode := Mode.SLEEP
var _t := 0.0
var _hit_t := 0.0
var _entry_side := 0.0
var _bats: Array = []


func setup(a_: Vector3, b_: Vector3) -> BatCurtain:
	a = a_
	b = b_
	return self


func _ready() -> void:
	add_to_group("bat_curtain")
	global_position = (a + b) * 0.5
	EventBus.rune_pulsed.connect(_on_pulse)
	var axis := (b - a).normalized()
	var side := Vector3(-axis.z, 0.0, axis.x)
	var wing := Fx.mat(Color(0.12, 0.08, 0.12))
	var eye := Fx.mat(Color(1.0, 0.35, 0.25), 2.5, true)
	var r := RandomNumberGenerator.new()
	r.seed = 88
	for k in 22:
		var bat := Node3D.new()
		var along := r.randf_range(-ZONE_HALF, ZONE_HALF) * 0.8
		var across := r.randf_range(-ZONE_WIDTH, ZONE_WIDTH) * 0.9
		bat.position = axis * along + side * across + Vector3(0, r.randf_range(2.1, 2.9), 0)
		bat.set_meta("home", bat.position)
		bat.set_meta("ph", r.randf() * TAU)
		add_child(bat)
		var body := Fx.sphere(0.3, wing)
		body.scale = Vector3(0.8, 1.4, 0.8)
		bat.add_child(body)
		for sd: float in [-1.0, 1.0]:
			var w := Fx.box(Vector3(0.75, 0.9, 0.04), wing)
			w.position = Vector3(sd * 0.35, -0.1, 0)
			w.rotation.z = sd * 0.25
			w.set_meta("wing", sd)
			bat.add_child(w)
		var e := Fx.sphere(0.05, eye)
		e.position = Vector3(0, -0.25, -0.25)
		e.visible = false
		e.set_meta("eye", true)
		bat.add_child(e)
		_bats.append(bat)


func in_zone(p: Vector3) -> bool:
	var q := p - global_position
	q.y = 0.0
	var axis := (b - a).normalized()
	var along := q.dot(axis)
	var across := (q - axis * along).length()
	return absf(along) <= ZONE_HALF and across <= ZONE_WIDTH + 0.5


func _side_of(p: Vector3) -> float:
	return signf((p - global_position).dot((b - a).normalized()))


func _physics_process(delta: float) -> void:
	_t += delta
	var p := GameState.player as Player
	var inside := p != null and not p.dead and in_zone(p.global_position)
	if p != null and not inside and Fx.flat_dist(p.global_position, global_position) < ZONE_HALF + 4.0:
		_entry_side = _side_of(p.global_position)   # de que lado ela vem
	match mode:
		Mode.SLEEP:
			if inside and (p.rune_on or p.noise_radius() >= WAKE_NOISE):
				_wake()
		Mode.AWAKE:
			if inside:
				_hit_t -= delta
				var back := (b - a).normalized() * (_entry_side if _entry_side != 0.0 else -1.0)
				p.external_velocity = back * PUSH
				if _hit_t <= 0.0:
					_hit_t = 0.8
					p.take_damage(DAMAGE, null, false)
				_t = 0.0
			elif _t > 3.0:
				mode = Mode.SLEEP
				EventBus.message.emit("A Cortina viva se acalma e volta a dormir.")
		Mode.STUNNED:
			if _t > STUN_TIME:
				mode = Mode.SLEEP
				_t = 0.0
				EventBus.message.emit("Os morcegos voltam para o teto.")
	_animate(delta)


func _wake() -> void:
	mode = Mode.AWAKE
	_t = 0.0
	_hit_t = 0.0
	EventBus.big_message.emit("A Cortina viva se fecha!")
	EventBus.hint.emit("Luz e barulho acordam a Cortina viva. Apague a runa (F) e passe devagar, ou use o Pulso Espiral.")
	GameState.say_once("a8_cortina", "SÃO MORCEGOS. É TUDO MORCEGO. Volta, volta, VOLTA!")
	var p := GameState.player as Player
	if p != null:
		p.shake(0.6)


func _on_pulse(pos: Vector3) -> void:
	if Fx.flat_dist(pos, global_position) > ZONE_HALF + 6.0:
		return
	mode = Mode.STUNNED
	_t = 0.0
	EventBus.big_message.emit("A Cortina viva caiu atordoada!")
	GameState.say_once("a8_pulso", "Ha! Luz demais pra vocês? Agora é minha vez de passar.")


func _animate(_delta: float) -> void:
	for bat: Node3D in _bats:
		var home: Vector3 = bat.get_meta("home")
		var ph: float = bat.get_meta("ph")
		var target := home
		match mode:
			Mode.AWAKE:
				target = home + Vector3(sin(_t * 3.0 + ph) * 1.6, -1.4 + sin(_t * 5.0 + ph) * 0.6, cos(_t * 2.6 + ph) * 1.6)
			Mode.STUNNED:
				target = Vector3(home.x, 0.25, home.z)
		bat.position = bat.position.lerp(target, 0.12)
		for c in bat.get_children():
			if c.has_meta("wing"):
				var flap := sin(_t * 18.0 + ph) * 0.9 if mode == Mode.AWAKE else (0.05 * sin(_t + ph) if mode == Mode.SLEEP else 0.6)
				(c as Node3D).rotation.z = float(c.get_meta("wing")) * (0.25 + flap)
			elif c.has_meta("eye"):
				(c as Node3D).visible = mode == Mode.AWAKE
