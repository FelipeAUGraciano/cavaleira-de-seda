class_name AcidSlug
extends Creature
## Lesma de ácido (M): lenta, mole e muito resistente. Pasta o musgo perto dos fungos e
## deixa um rastro de ácido brilhando no chão (queima quem pisa; sobre um fio, não).
## Não caça, mas se defende: cospe ácido longe e esmaga de perto.
## Comer dá Resistência a Ácido.

const TRAIL_STEP := 1.4
const TRAIL_LIFE := 14.0

var _last_drop := Vector3.ZERO


func _init() -> void:
	display_name = "Lesma de ácido"
	size = Size.M
	level = 6
	max_hp = 130.0
	speed = 1.3
	body_radius = 0.6
	body_color = Color(0.32, 0.45, 0.2)
	food_satiety = 60.0
	food_silk = 20.0
	food_xp = 50
	food_acid = 1
	senses_text = "tato e cheiro (3 m); deixa rastro de ácido"
	aggression = 0.35
	memory_time = 3.0
	sight_range = 3.0
	hunger_threshold = 30.0
	needs.hunger_rate = 0.5
	attack_damage = 16.0
	attack_reach = 1.3
	combat_label = "Se defendendo"
	add_attack(Attack.make("esmagar", "Esmagar", {"max_range": 1.9, "windup": 0.7, "active": 0.2, "recover": 0.8,
		"cooldown": 1.8, "damage": 16.0, "reach": 1.8, "arc": 120.0, "weight": 2.0}))
	add_attack(Attack.make("cuspe", "Cuspe de ácido", {"min_range": 2.0, "max_range": 7.0, "windup": 0.8, "active": 0.15,
		"recover": 0.7, "cooldown": 3.5, "damage": 8.0, "shape": Attack.Shape.CIRCLE, "reach": 1.3, "at_point": true,
		"knockback": false, "effect": "acid", "effect_power": 8.0, "weight": 2.0}))


func _ready() -> void:
	super._ready()
	_last_drop = global_position


func notices_player(p: Player) -> bool:
	return flat_dist_to(p) < 3.0 or (flat_dist_to(p) < 6.0 and player_memory > 0.0)


func find_food() -> Variant:
	## Pasta o musgo dos fungos.
	var best: Variant = null
	var best_d := 16.0
	for q: Vector3 in World.graze_spots:
		var d := Fx.flat_dist(global_position, q)
		if d < best_d:
			best_d = d
			best = q
	return best


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Se defendendo")) \
		.add(Behaviors.Forage.new()) \
		.add(Behaviors.Sleep.new()) \
		.add(Behaviors.Wander.new(4.0, 0.5))


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if dead:
		return
	if Fx.flat_dist(global_position, _last_drop) > TRAIL_STEP:
		_last_drop = global_position
		var puddle := SlugTrail.new()
		puddle.life = TRAIL_LIFE
		get_parent().add_child(puddle)
		puddle.global_position = Vector3(global_position.x, 0.02, global_position.z)


func _build_visual() -> void:
	var body := Fx.sphere(body_radius, _mat)
	body.scale = Vector3(0.9, 0.55, 2.0)
	body.position.y = body_radius * 0.5
	_visual.add_child(body)
	var glow := Fx.mat(Color(0.6, 1.0, 0.2), 1.8, true, 0.8)
	for k in 5:
		var spot := Fx.sphere(0.12, glow)
		spot.position = Vector3(sin(k * 2.3) * 0.25, body_radius * 0.85, -0.6 + k * 0.3)
		_visual.add_child(spot)
	for sd: float in [-1.0, 1.0]:
		var stalk := Fx.cylinder(0.04, 0.5, _mat)
		stalk.position = Vector3(sd * 0.18, body_radius * 0.9, -body_radius * 1.6)
		stalk.rotation.x = -0.5
		_visual.add_child(stalk)
		var eye := Fx.sphere(0.07, glow)
		eye.position = stalk.position + Vector3(0, 0.22, -0.12)
		_visual.add_child(eye)
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 1.0, 0.2)
	l.omni_range = 3.0
	l.light_energy = 0.5
	l.position.y = 1.0
	_visual.add_child(l)


func _animate(_delta: float, speed_now: float) -> void:
	_visual.scale = Vector3(1.0, 1.0 + sin(_anim_t * 4.0) * 0.06 * clampf(speed_now, 0.0, 1.0), 1.0 - sin(_anim_t * 4.0) * 0.06 * clampf(speed_now, 0.0, 1.0))


class SlugTrail extends Node3D:
	## Rastro de ácido: brilha verde, queima quem pisa (Resistência a Ácido corta), some sozinho.
	var life := 14.0
	var _age := 0.0
	var _cd := 0.0
	var _m: StandardMaterial3D

	func _ready() -> void:
		add_to_group("acid_puddle")
		_m = Fx.mat(Color(0.55, 1.0, 0.15), 1.4, true, 0.55)
		var d := Fx.cylinder(0.55, 0.02, _m)
		add_child(d)

	func _physics_process(delta: float) -> void:
		_age += delta
		_cd -= delta
		_m.albedo_color.a = 0.55 * clampf(1.0 - _age / life, 0.0, 1.0)
		if _age >= life:
			queue_free()
			return
		var p := GameState.player as Player
		if _cd <= 0.0 and p != null and not p.dead and not p.on_strand and Fx.flat_dist(p.global_position, global_position) < 0.6:
			_cd = 0.5
			p.apply_acid(4.0)
