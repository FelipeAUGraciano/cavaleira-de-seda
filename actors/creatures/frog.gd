class_name Frog
extends Creature
## Sapo-de-rocha (M): predador de emboscada que caça na fase da Caça e dorme na poça no Brilho.
## Sentidos: visão em cone (10 m, 140°) e audição. Contra a jogadora: mordida e língua que puxa.
## Vida: come larvas e cadáveres, passeia entre câmaras, foge de bichos grandes e,
## ferido, volta para a poça para se curar. Comer o sapo dá Resistência a Ácido.

enum Mode { IDLE, CHASE, SEARCH, BITE, TONGUE }

const SIGHT := 10.0
const FOV := 140.0
const BITE_DAMAGE := 14.0
const TONGUE_DAMAGE := 8.0

var mode: Mode = Mode.IDLE
var mode_time := 0.0
var attack_done := false
var bite_cd := 0.0
var tongue_cd := 2.0


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
	food_acid = 1
	senses_text = "visão (10 m, cone de 140°) e audição"
	model_name = "sapo"
	model_size = 2.0
	model_fit = "length"
	rest_phase = CaveClock.Phase.BRILHO
	sight_range = SIGHT
	sight_fov = FOV
	attack_damage = BITE_DAMAGE
	attack_reach = 1.6
	hunger_threshold = 50.0
	retreat_frac = 0.3
	roam_speed = 0.5
	needs.hunger_rate = 0.5


func _ready() -> void:
	super._ready()
	add_to_group("predator")


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Caçando você")) \
		.add(Behaviors.Retreat.new()) \
		.add(Behaviors.Flee.new()) \
		.add(Behaviors.Fight.new()) \
		.add(Behaviors.Forage.new()) \
		.add(Behaviors.Sleep.new()) \
		.add(Behaviors.Roam.new()) \
		.add(Behaviors.Wander.new(5.0, 0.25))


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


# ---------------------------------------------------------------- vida

func is_prey(o: Creature) -> bool:
	return o is Larva or (o is Bat and o.global_position.y < 1.0)


func eats_carrion() -> bool:
	return true


func find_rival() -> Creature:
	## Revida quem o atacou (outro bicho, não a jogadora).
	var a: Creature = _last_attacker as Creature if is_instance_valid(_last_attacker) else null
	if a != null and is_instance_valid(a) and not a.dead and flat_dist_to(a) < 7.0 and not (a is Larva):
		return a
	return null


func _release_prey() -> void:
	## (compatibilidade) a comida agora é escolhida pelo cérebro (Behaviors.Forage)
	pass


# ---------------------------------------------------------------- combate com a jogadora

func combat_wants() -> bool:
	return player_memory > 0.0 or mode == Mode.BITE or mode == Mode.TONGUE


func combat_locked() -> bool:
	return mode == Mode.BITE or mode == Mode.TONGUE


func combat_start() -> void:
	if mode == Mode.IDLE:
		EventBus.message.emit("O %s te viu!" % display_name)
	mode = Mode.CHASE
	mode_time = 0.0


func combat_stop() -> void:
	mode = Mode.IDLE
	telegraph = false


func combat_tick(delta: float) -> Vector3:
	bite_cd -= delta
	tongue_cd -= delta
	mode_time += delta
	var p := GameState.player as Player
	if mode == Mode.BITE:
		return _do_bite(p)
	if mode == Mode.TONGUE:
		return _do_tongue(p)
	if p != null and not p.dead and noticed_player:
		mode = Mode.CHASE
		return _chase(p)
	mode = Mode.SEARCH
	return nav_to(last_player_pos, 0.7)


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
	return nav_to(p.global_position, 1.0)


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


func _on_hurt(source: Node3D) -> void:
	if source != null and source.is_in_group("player") and mode == Mode.IDLE:
		mode = Mode.CHASE
		mode_time = 0.0


func _animate(_delta: float, speed_now: float) -> void:
	var hop := absf(sin(_anim_t * 7.0)) * 0.25 * clampf(speed_now / speed, 0.0, 1.0)
	_visual.position.y = hop - (0.15 if asleep else 0.0)
