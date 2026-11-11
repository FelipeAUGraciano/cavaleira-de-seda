class_name Sister
extends Creature
## Irmãs-aranha do Berçário. Usam as mesmas patas com IK da Cavaleira.
##   Irmã menor (P): foge pela vibração e vira comida.
##   Irmã faminta (P, maior): caça a jogadora pela visão e devora as irmãs menores.

const BITE_DAMAGE := 8.0
const SIGHT := 9.0
const FOV := 160.0

var hunter := false
var legs: SpiderLegs
var mode_time := 0.0
var bite_cd := 0.0
var biting := false
var bite_done := false
var target: Node3D = null


func _init(is_hunter: bool = false) -> void:
	hunter = is_hunter
	size = Size.P
	if hunter:
		display_name = "Irmã faminta"
		level = 3
		max_hp = 32.0
		speed = 5.6
		body_radius = 0.32
		body_color = Color(0.32, 0.12, 0.3)
		food_satiety = 35.0
		food_silk = 20.0
		food_xp = 25
		senses_text = "visão (9 m, cone de 160°) e vibração"
	else:
		display_name = "Irmã menor"
		level = 1
		max_hp = 10.0
		speed = 3.0
		body_radius = 0.22
		body_color = Color(0.22, 0.2, 0.38)
		food_satiety = 25.0
		food_silk = 15.0
		food_xp = 12
		senses_text = "vibração (4 m)"


func _ready() -> void:
	needs.hunger = 60.0
	super._ready()
	needs.hunger = 60.0
	if hunter:
		add_to_group("predator")
	if _model != null and Models.tuning(model_name).get("legs", false):
		legs.visible = false
		legs.process_mode = Node.PROCESS_MODE_DISABLED


func _build_visual() -> void:
	var k := body_radius / 0.42
	var head := Fx.sphere(0.32 * k, _mat)
	head.position = Vector3(0.0, 0.45 * k, -0.18 * k)
	_visual.add_child(head)
	var abdomen := Fx.sphere(0.42 * k, _mat)
	abdomen.position = Vector3(0.0, 0.55 * k, 0.45 * k)
	_visual.add_child(abdomen)
	var eye_mat := Fx.mat(Color(1.0, 0.25, 0.2) if hunter else Color(1.0, 0.65, 0.15), 1.5)
	_body_parts = [head, abdomen]
	for x in [-0.12, 0.12]:
		var eye := Fx.sphere(0.075 * k, eye_mat)
		eye.position = Vector3(x * k, 0.52 * k, -0.45 * k)
		_visual.add_child(eye)
		_body_parts.append(eye)
	model_name = "irma_corpo"
	model_size = 1.35 * k
	model_fit = "length"
	model_lift = 0.15 * k
	if Models.tuning(model_name).get("legs", false):
		# modelo com patas: mede pela envergadura e pisa no chão
		model_size = 1.9 * k
		model_fit = "max"
		model_lift = 0.0
	if hunter:
		model_tint = Color(1.6, 0.55, 0.6)
	legs = SpiderLegs.new()
	legs.leg_color = body_color.darkened(0.3)
	legs.setup(_visual, k, 1)
	add_child(legs)


func _think(delta: float) -> Vector3:
	if hunter:
		return _think_hunter(delta)
	return _think_small(delta)


func _think_small(delta: float) -> Vector3:
	var danger: Node3D = null
	var p := GameState.player as Player
	if p != null and not p.dead and flat_dist_to(p) < maxf(4.0, p.noise_radius()):
		danger = p
	if danger == null:
		danger = World.nearest(global_position, 5.0, func(c): return c.is_in_group("predator"))
	if danger != null:
		var away := global_position - danger.global_position
		var dir := safe_dir(away)
		if dir == Vector3.ZERO:
			dir = safe_dir(away.rotated(Vector3.UP, PI * 0.5))
		return dir * speed * 1.3
	return wander(delta, 4.0, 0.4)


func _think_hunter(delta: float) -> Vector3:
	bite_cd -= delta
	mode_time += delta
	if biting:
		if target != null and is_instance_valid(target):
			face_toward(target.global_position)
		if not bite_done and mode_time >= 0.35:
			bite_done = true
			telegraph = false
			if target != null and is_instance_valid(target) and flat_dist_to(target) <= 1.6:
				var p := target as Player
				if p != null:
					p.take_damage(BITE_DAMAGE, self)
				else:
					var prey := target as Creature
					if prey != null and not prey.dead:
						prey.take_damage(999.0, self)
						hunger = 0.0
		if mode_time >= 0.6:
			biting = false
			bite_cd = 1.1
		return Vector3.ZERO

	target = null
	var pl := GameState.player as Player
	if pl != null and not pl.dead:
		if can_see(pl, SIGHT * pl.visibility_mult(), FOV) or flat_dist_to(pl) < maxf(3.0, pl.noise_radius()):
			target = pl
	if target == null and hunger > 30.0:
		var best_d := 8.0
		for n in World.near(global_position, 8.0):
			var s := n as Sister
			if s != null and s != self and not s.hunter and not s.dead:
				var d := flat_dist_to(s)
				if d < best_d and has_line_of_sight(s):
					target = s
					best_d = d
	if target != null:
		var dist := flat_dist_to(target)
		face_toward(target.global_position)
		if dist <= 1.3 and bite_cd <= 0.0:
			biting = true
			bite_done = false
			mode_time = 0.0
			telegraph = true
			return Vector3.ZERO
		return move_to(target.global_position, 1.0)
	hunger += delta
	return wander(delta, 6.0, 0.35)


func _lod_changed(near: bool) -> void:
	# longe da câmera, as patas com IK (raios de física por pata) param de calcular
	legs.process_mode = Node.PROCESS_MODE_INHERIT if near and (_model == null or not Models.tuning(model_name).get("legs", false)) else Node.PROCESS_MODE_DISABLED
	legs.visible = near and legs.process_mode != Node.PROCESS_MODE_DISABLED


func _animate(_delta: float, speed_now: float) -> void:
	legs.velocity_hint = Vector3(velocity.x, 0.0, velocity.z)
	if _model != null and not legs.visible:
		# patas do modelo não andam: um balanço rápido dá a impressão de passos
		var moving := clampf(speed_now / maxf(speed, 0.1), 0.0, 1.0)
		_model.position.y = absf(sin(_anim_t * 18.0)) * 0.04 * moving
		_model.rotation.z = sin(_anim_t * 18.0) * 0.06 * moving
