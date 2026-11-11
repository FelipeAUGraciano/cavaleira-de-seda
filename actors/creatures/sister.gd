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
var hunger := 60.0


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
	super._ready()
	if hunter:
		add_to_group("predator")


func _build_visual() -> void:
	var k := body_radius / 0.42
	var head := Fx.sphere(0.32 * k, _mat)
	head.position = Vector3(0.0, 0.45 * k, -0.18 * k)
	_visual.add_child(head)
	var abdomen := Fx.sphere(0.42 * k, _mat)
	abdomen.position = Vector3(0.0, 0.55 * k, 0.45 * k)
	_visual.add_child(abdomen)
	var eye_mat := Fx.mat(Color(1.0, 0.25, 0.2) if hunter else Color(1.0, 0.65, 0.15), 1.5)
	for x in [-0.12, 0.12]:
		var eye := Fx.sphere(0.075 * k, eye_mat)
		eye.position = Vector3(x * k, 0.52 * k, -0.45 * k)
		_visual.add_child(eye)
	legs = SpiderLegs.new()
	legs.leg_color = body_color.darkened(0.3)
	legs.setup(_visual, k, 1)
	add_child(legs)


func _think(delta: float) -> Vector3:
	if hunter:
		return _think_hunter(delta)
	return _think_small(delta)


func _think_small(delta: float) -> Vector3:
	var threat: Node3D = null
	var p := GameState.player as Player
	if p != null and not p.dead and flat_dist_to(p) < maxf(4.0, p.noise_radius()):
		threat = p
	if threat == null:
		for n in get_tree().get_nodes_in_group("predator"):
			var c := n as Creature
			if c != null and not c.dead and flat_dist_to(c) < 5.0:
				threat = c
				break
	if threat != null:
		var away := global_position - threat.global_position
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
		for n in get_tree().get_nodes_in_group("creature"):
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


func _animate(_delta: float, _speed_now: float) -> void:
	legs.velocity_hint = Vector3(velocity.x, 0.0, velocity.z)
