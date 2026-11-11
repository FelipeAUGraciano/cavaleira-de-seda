class_name Frog
extends Creature
## Sapo-de-rocha (M): predador de emboscada. Caça por visão (cone) e audição.
## Ataques: mordida corpo a corpo e língua que puxa (dá para esquivar).
## Quando está com fome, caça larvas e come os cadáveres — ecossistema básico.

enum Mode { IDLE, CHASE, SEARCH, HUNT, EAT, BITE, TONGUE }

const SIGHT := 10.0
const FOV := 140.0
const BITE_DAMAGE := 14.0
const TONGUE_DAMAGE := 8.0

var mode: Mode = Mode.IDLE
var mode_time := 0.0
var attack_done := false
var last_seen := Vector3.ZERO
var memory := 0.0
var bite_cd := 0.0
var tongue_cd := 2.0
var hunger := 40.0
var prey: Node3D = null


func _init() -> void:
	display_name = "Sapo-de-rocha"
	size = Size.M
	level = 4
	max_hp = 80.0
	speed = 3.6
	body_radius = 0.75
	body_color = Color(0.45, 0.42, 0.36)
	food_satiety = 60.0
	food_silk = 30.0
	food_xp = 50
	senses_text = "visão (10 m, cone de 140°) e audição"
	model_name = "sapo"
	model_size = 2.0
	model_fit = "length"


func _ready() -> void:
	super._ready()
	add_to_group("predator")


func _build_visual() -> void:
	var body := Fx.sphere(body_radius, _mat)
	body.scale = Vector3(1.15, 0.7, 1.2)
	body.position.y = body_radius * 0.75
	_visual.add_child(body)
	var eye_mat := Fx.mat(Color(1.0, 0.8, 0.2), 1.2)
	for x in [-0.3, 0.3]:
		var eye := Fx.sphere(0.14, eye_mat)
		eye.position = Vector3(x, body_radius * 1.2, -body_radius * 0.55)
		_visual.add_child(eye)


func _think(delta: float) -> Vector3:
	bite_cd -= delta
	tongue_cd -= delta
	mode_time += delta
	hunger = minf(100.0, hunger + delta)

	var p := GameState.player as Player
	var sees := false
	if p != null and not p.dead:
		if can_see(p, SIGHT * p.visibility_mult(), FOV) or flat_dist_to(p) < p.noise_radius():
			sees = true
			last_seen = p.global_position
			memory = 4.0

	if mode == Mode.BITE:
		return _do_bite(p)
	if mode == Mode.TONGUE:
		return _do_tongue(p)

	if sees and mode != Mode.CHASE:
		if mode != Mode.SEARCH:
			EventBus.message.emit("O %s te viu!" % display_name)
		_release_prey()
		mode = Mode.CHASE
		mode_time = 0.0

	match mode:
		Mode.CHASE:
			if not sees:
				mode = Mode.SEARCH
				return Vector3.ZERO
			return _chase(p)
		Mode.SEARCH:
			memory -= delta
			if memory <= 0.0:
				mode = Mode.IDLE
			return move_to(last_seen, 0.7)
		Mode.EAT:
			return _do_eat()
		Mode.HUNT:
			return _do_hunt()

	if hunger > 50.0 and _find_prey():
		mode = Mode.HUNT
		return Vector3.ZERO
	return wander(delta, 5.0, 0.25)


func _begin(m: Mode) -> void:
	mode = m
	mode_time = 0.0
	attack_done = false
	telegraph = true


func _chase(p: Player) -> Vector3:
	var d := flat_dist_to(p)
	face_toward(p.global_position)
	if d <= 1.9 and bite_cd <= 0.0:
		_begin(Mode.BITE)
		return Vector3.ZERO
	if d >= 3.0 and d <= 6.5 and tongue_cd <= 0.0 and has_line_of_sight(p):
		_begin(Mode.TONGUE)
		return Vector3.ZERO
	if d <= 1.6:
		return Vector3.ZERO
	return move_to(p.global_position, 1.0)


func _do_bite(p: Player) -> Vector3:
	if p != null:
		face_toward(p.global_position)
	if not attack_done and mode_time >= 0.5:
		attack_done = true
		telegraph = false
		if p != null and not p.dead and flat_dist_to(p) <= 2.4:
			p.take_damage(BITE_DAMAGE, self)
	if mode_time >= 0.85:
		bite_cd = 1.3
		mode = Mode.CHASE
	return Vector3.ZERO


func _do_tongue(p: Player) -> Vector3:
	if p != null:
		face_toward(p.global_position)
	if not attack_done and mode_time >= 0.7:
		attack_done = true
		telegraph = false
		var mouth := global_position + Vector3.UP * 0.6
		if p != null and not p.dead and flat_dist_to(p) <= 7.5 and has_line_of_sight(p):
			Fx.beam(get_parent(), mouth, p.global_position + Vector3.UP * 0.4, Color(0.95, 0.45, 0.55), 0.2, 0.12)
			if p.pull_toward(global_position, 12.0):
				p.take_damage(TONGUE_DAMAGE, self, false)
		else:
			Fx.beam(get_parent(), mouth, mouth + facing * 6.0, Color(0.95, 0.45, 0.55), 0.2, 0.12)
	if mode_time >= 1.1:
		tongue_cd = 4.0
		mode = Mode.CHASE
	return Vector3.ZERO


func _find_prey() -> bool:
	var best: Node3D = null
	var best_d := 9.0
	for n in get_tree().get_nodes_in_group("corpse"):
		var c := n as Corpse
		if c == null or c.is_rotten():
			continue
		if c.reserved_by != null and is_instance_valid(c.reserved_by) and c.reserved_by != self:
			continue
		var d := flat_dist_to(c)
		if d < best_d:
			best = c
			best_d = d
	if best == null:
		for n in get_tree().get_nodes_in_group("creature"):
			var l := n as Larva
			if l == null or l.dead:
				continue
			var d := flat_dist_to(l)
			if d < best_d and can_see(l, 9.0, 200.0):
				best = l
				best_d = d
	prey = best
	if prey is Corpse:
		(prey as Corpse).reserved_by = self
	return prey != null


func _do_hunt() -> Vector3:
	if prey == null or not is_instance_valid(prey):
		prey = null
		mode = Mode.IDLE
		return Vector3.ZERO
	var d := flat_dist_to(prey)
	if prey is Corpse:
		if d <= 1.4:
			mode = Mode.EAT
			mode_time = 0.0
			return Vector3.ZERO
		return move_to(prey.global_position, 0.8)
	var l := prey as Larva
	if l == null or l.dead:
		prey = null
		mode = Mode.IDLE
		return Vector3.ZERO
	if d <= 1.5:
		l.take_damage(999.0, self)
		prey = null
		mode = Mode.IDLE
		return Vector3.ZERO
	return move_to(l.global_position, 1.1)


func _do_eat() -> Vector3:
	if prey == null or not is_instance_valid(prey):
		prey = null
		mode = Mode.IDLE
		return Vector3.ZERO
	if mode_time >= 3.0:
		(prey as Corpse).consume()
		prey = null
		hunger = 0.0
		mode = Mode.IDLE
	return Vector3.ZERO


func _release_prey() -> void:
	if prey != null and is_instance_valid(prey) and prey is Corpse:
		(prey as Corpse).reserved_by = null
	prey = null


func _on_hurt(source: Node3D) -> void:
	if source != null and source.is_in_group("player"):
		last_seen = source.global_position
		memory = 5.0
		if mode != Mode.BITE and mode != Mode.TONGUE and mode != Mode.CHASE:
			_release_prey()
			mode = Mode.CHASE
			mode_time = 0.0


func _animate(_delta: float, speed_now: float) -> void:
	var hop := absf(sin(_anim_t * 7.0)) * 0.25 * clampf(speed_now / speed, 0.0, 1.0)
	_visual.position.y = hop
