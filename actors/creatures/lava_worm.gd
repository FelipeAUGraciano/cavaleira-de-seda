class_name LavaWorm
extends LavaLurker
## Verme de lava (M): sai da lava de repente perto da beirada, cospe duas bolas de fogo
## (marca no chão onde vai cair) e afunda de novo. Fora da lava dá para acertar.
## Comer sobe a Resistência a Fogo.

const SPIT := 14.0
const WINDUP := 0.9

var _shots := 0
var _target := Vector3.ZERO
var _tele := Attack.make("cuspe", "", {"shape": Attack.Shape.CIRCLE, "reach": 1.4, "at_point": true})


func _init() -> void:
	display_name = "Verme de lava"
	size = Size.M
	level = 7
	max_hp = 50.0
	speed = 1.0
	body_radius = 0.5
	body_color = Color(0.3, 0.1, 0.06)
	food_satiety = 40.0
	food_silk = 18.0
	food_xp = 45
	food_fire = 1
	senses_text = "calor (10 m da beirada); só dá para acertar quando ele sai da lava"
	detect_r = 10.0


func _think(delta: float) -> Vector3:
	super._think(delta)
	var p := GameState.player as Player
	match mode:
		Mode.HIDDEN:
			activity = "Embaixo da lava"
			_visual.position.y = move_toward(_visual.position.y, -1.6, delta * 4.0)
			if can_surface(p):
				mode = Mode.OUT
				mode_t = 0.0
				_shots = 0
				surface_fx(global_position)
		Mode.OUT:
			activity = "Cuspindo fogo"
			_visual.position.y = move_toward(_visual.position.y, 0.0, delta * 4.0)
			if mode_t < 0.5:
				return Vector3.ZERO
			var t := mode_t - 0.5
			if _target == Vector3.ZERO and p != null:
				_target = Vector3(p.global_position.x, 0.0, p.global_position.z)   # mira uma vez
				face_toward(_target)
			show_marker(_tele, _target, clampf(t / WINDUP, 0.0, 1.0))
			if t >= WINDUP:
				hide_marker()
				_fireball(_target)
				_target = Vector3.ZERO
				_shots += 1
				mode_t = 0.5 - 0.3
				if _shots >= 2:
					mode = Mode.BACK
					mode_t = 0.0
		Mode.BACK:
			activity = "Afundando"
			_visual.position.y = move_toward(_visual.position.y, -1.6, delta * 3.0)
			if mode_t > 1.2:
				mode = Mode.HIDDEN
				mode_t = 0.0
				cooldown = 4.5
	return Vector3.ZERO


func _fireball(at: Vector3) -> void:
	var p := GameState.player as Player
	if p != null and not p.dead and Fx.flat_dist(p.global_position, at) < 1.5:
		if p.take_damage(SPIT, self, false):
			p.apply_burn(3.0)
	if near_player:
		var m := Fx.mat(Color(1.0, 0.5, 0.1), 3.0, true, 0.8)
		var f := Fx.sphere(0.6, m)
		get_parent().add_child(f)
		f.global_position = at + Vector3(0, 0.3, 0)
		var tw := f.create_tween()
		tw.tween_property(f, "scale", Vector3.ONE * 2.6, 0.35)
		tw.tween_callback(f.queue_free)


func _build_visual() -> void:
	for k in 6:
		var seg := Fx.sphere(body_radius * (1.0 - k * 0.08), _mat)
		seg.position = Vector3(0, 0.4 + k * 0.42, 0.12 * k)
		_visual.add_child(seg)
	var mouth := Fx.sphere(0.25, Fx.mat(Color(1.0, 0.6, 0.15), 3.0, true))
	mouth.position = Vector3(0, 2.7, -0.2)
	_visual.add_child(mouth)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.15)
	l.omni_range = 4.0
	l.light_energy = 0.9
	l.position.y = 2.5
	_visual.add_child(l)
