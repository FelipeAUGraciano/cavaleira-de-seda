class_name Larva
extends Creature
## Larva-de-musgo (P): a presa de quase todo mundo.
## Pasta musgo perto dos fungos quando eles estão acesos (Brilho) e se esconde na toca na Caça.
## Foge do cheiro da jogadora e de predadores maiores acordados.
## A isca do Lagarto-lanterna a hipnotiza: ela vai até a luz (e vira janta).


func _init() -> void:
	display_name = "Larva-de-musgo"
	size = Size.P
	level = 1
	max_hp = 18.0
	speed = 2.6
	body_radius = 0.3
	body_color = Color(0.55, 0.68, 0.38)
	food_satiety = 30.0
	food_silk = 20.0
	food_xp = 15
	senses_text = "cheiro (5 m) e audição"
	model_name = "larva"
	model_size = 0.9
	model_fit = "length"
	fears_player = true
	fear_radius = 4.5
	rest_phase = CaveClock.Phase.CACA
	hunger_threshold = 35.0
	sleep_heal = 0.02
	needs.hunger_rate = 0.5


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Lured.new()) \
		.add(Behaviors.Flee.new()) \
		.add(Behaviors.Forage.new()) \
		.add(Behaviors.Sleep.new()) \
		.add(Behaviors.Wander.new(5.0, 0.3))


func _build_visual() -> void:
	for i in range(3):
		var seg := Fx.sphere(body_radius * (1.0 - i * 0.15), _mat)
		seg.position = Vector3(0.0, body_radius * 0.9, i * body_radius * 1.3)
		_visual.add_child(seg)


func find_food() -> Variant:
	return World.nearest_graze(global_position, 16.0)


func is_threat(o: Creature) -> bool:
	return super.is_threat(o) and not o.is_in_group("lure")


func lure_near() -> Lizard:
	return World.nearest(global_position, Lizard.LURE_PULL + 1.5, func(o): return o is Lizard and o.lure_active()) as Lizard


func _animate(_delta: float, speed_now: float) -> void:
	_visual.scale.z = 1.0 + sin(_anim_t * 12.0) * 0.08 * clampf(speed_now, 0.0, 1.0)


class Lured extends Behavior:
	## A luz da isca é mais forte que o sono e que a fome (mas não que o pavor).
	var lizard: Lizard = null

	func _init() -> void:
		id = "lured"
		label = "Hipnotizada pela luz"

	func utility(c: Creature) -> float:
		if c.needs.fear > 60.0:
			return 0.0
		lizard = (c as Larva).lure_near()
		return 1.1 if lizard != null else 0.0

	func run(c: Creature, _delta: float) -> Vector3:
		if lizard == null or not is_instance_valid(lizard) or lizard.dead:
			return Vector3.ZERO
		return c.move_to(lizard.lure_position(), 0.45)
