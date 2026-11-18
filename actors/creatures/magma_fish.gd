class_name MagmaFish
extends LavaLurker
## Peixe-magma (P): mora na lava. Quando você chega na beirada, salta em arco, cai em cima
## de você (mordida que queima) e fica se debatendo no chão uns segundos: é a hora de pegar.
## Depois pula de volta. Comer sobe a Resistência a Fogo.

const BITE := 14.0
const FLOP_TIME := 3.5

var _from := Vector3.ZERO
var _to := Vector3.ZERO


func _init() -> void:
	display_name = "Peixe-magma"
	size = Size.P
	level = 5
	max_hp = 24.0
	speed = 2.0
	body_radius = 0.35
	body_color = Color(0.2, 0.08, 0.05)
	food_satiety = 30.0
	food_silk = 14.0
	food_xp = 28
	food_fire = 1
	senses_text = "calor (8 m da beirada); embaixo da lava não dá para acertar"
	detect_r = 7.5


func _think(delta: float) -> Vector3:
	super._think(delta)
	var p := GameState.player as Player
	match mode:
		Mode.HIDDEN:
			activity = "Embaixo da lava"
			if can_surface(p) and not p.on_strand:
				_from = global_position
				_to = Vector3(p.global_position.x, 0.0, p.global_position.z)
				_to += (Vector3(_from.x, 0, _from.z) - _to).normalized() * 0.6
				mode = Mode.OUT
				mode_t = 0.0
				surface_fx(_from)
				face_toward(_to)
		Mode.OUT:
			activity = "Saltando" if mode_t < 0.6 else "Se debatendo no chão"
			if mode_t < 0.6:
				var k := mode_t / 0.6
				global_position = _from.lerp(_to, k)
				_visual.position.y = sin(PI * k) * 2.2 - 0.2
			elif mode_t < 0.65:
				_visual.position.y = 0.0
				if p != null and not p.dead and Fx.flat_dist(p.global_position, global_position) < 1.3:
					if p.take_damage(BITE, self):
						p.apply_burn(2.0)
			else:
				_visual.position.y = absf(sin(mode_t * 9.0)) * 0.25
				if mode_t > 0.6 + FLOP_TIME:
					mode = Mode.BACK
					mode_t = 0.0
					_from = global_position
		Mode.BACK:
			activity = "Voltando para a lava"
			var k2 := minf(mode_t / 0.6, 1.0)
			global_position = _from.lerp(lava_home, k2)
			_visual.position.y = sin(PI * k2) * 1.8 - 1.6 * k2
			if k2 >= 1.0:
				mode = Mode.HIDDEN
				mode_t = 0.0
				cooldown = 4.0
				_visual.position.y = -1.6
				surface_fx(lava_home)
	return Vector3.ZERO


func _build_visual() -> void:
	var body := Fx.sphere(body_radius, _mat)
	body.scale = Vector3(0.7, 0.8, 1.6)
	body.position.y = body_radius * 0.8
	_visual.add_child(body)
	var glow := Fx.mat(Color(1.0, 0.5, 0.1), 2.5, true)
	for k in 4:
		var fin := Fx.box(Vector3(0.04, 0.2, 0.08), glow)
		fin.position = Vector3(0, body_radius * 1.2, -0.25 + k * 0.17)
		_visual.add_child(fin)
	var tail := Fx.box(Vector3(0.05, 0.4, 0.3), _mat)
	tail.position = Vector3(0, body_radius * 0.8, body_radius * 1.6)
	_visual.add_child(tail)
	for sd: float in [-1.0, 1.0]:
		var eye := Fx.sphere(0.05, Fx.mat(Color(1.0, 0.9, 0.4), 2.0, true))
		eye.position = Vector3(sd * 0.15, body_radius * 1.0, -body_radius * 1.2)
		_visual.add_child(eye)
