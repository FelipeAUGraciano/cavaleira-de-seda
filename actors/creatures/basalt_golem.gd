class_name BasaltGolem
extends Creature
## Golem de basalto (G): pilha de rocha vulcânica com brasa no peito. Dorme parado como uma
## pedra; acorda com barulho perto (correr a 8 m, lutar) ou se apanhar. Lento e enorme:
## soco em cone, pisão em volta e, de longe, arremessa pedra. Arrebenta fios.
## Passar sem acordá-los: andar devagar ou ir pelos fios. Se perder você, volta a dormir.

enum Mode { DORMANT, AWAKE }

var mode: Mode = Mode.DORMANT
var rest_spot := Vector3.ZERO
var _calm_t := 0.0
var _core: StandardMaterial3D


func _init() -> void:
	display_name = "Golem de basalto"
	size = Size.G
	level = 12
	max_hp = 240.0
	speed = 1.7
	body_radius = 0.95
	body_color = Color(0.17, 0.16, 0.17)
	food_satiety = 60.0
	food_silk = 20.0
	food_xp = 180
	fire_immune = true
	food_energy = 6.0
	senses_text = "vibração forte (correr a 8 m acorda); dormindo, parece pedra"
	nav_kind = NavGrid.Kind.LARGE
	aggression = 1.0
	memory_time = 6.0
	track_range = 16.0
	attack_damage = 30.0
	attack_reach = 2.4
	combat_label = "Esmagando"
	add_attack(Attack.make("soco", "Soco de basalto", {"max_range": 3.0, "windup": 0.9, "active": 0.2, "recover": 0.9,
		"cooldown": 2.0, "damage": 30.0, "reach": 3.0, "arc": 80.0, "lunge": 1.5, "weight": 3.0}))
	add_attack(Attack.make("pisao", "Pisão", {"max_range": 3.6, "windup": 1.1, "active": 0.25, "recover": 1.0,
		"cooldown": 4.5, "damage": 26.0, "shape": Attack.Shape.RING, "reach": 4.0, "weight": 2.0, "flank": true}))
	add_attack(Attack.make("pedra", "Arremesso de pedra", {"min_range": 4.0, "max_range": 11.0, "windup": 1.2, "active": 0.2,
		"recover": 1.0, "cooldown": 5.0, "damage": 22.0, "shape": Attack.Shape.CIRCLE, "reach": 1.6, "at_point": true, "weight": 2.0}))


func _ready() -> void:
	super._ready()
	rest_spot = global_position
	add_to_group("predator")
	add_to_group("golem")


func notices_player(p: Player) -> bool:
	var d := flat_dist_to(p)
	if mode == Mode.DORMANT:
		return d < body_radius + 0.8 or (not p.on_strand and d < p.noise_radius() * 1.0 and p.noise_radius() >= 6.0)
	return d < p.noise_radius() * 1.5 or can_see(p, 7.0, 160.0)


func sees_player_as_prey(_p: Player) -> bool:
	return mode == Mode.AWAKE


func take_damage(amount: float, source: Node3D = null) -> void:
	if mode == Mode.DORMANT and not dead:
		_wake()
	super.take_damage(amount, source)


func _wake() -> void:
	if mode == Mode.AWAKE:
		return
	mode = Mode.AWAKE
	_calm_t = 0.0
	if _core != null:
		_core.emission_energy_multiplier = 3.5
	if near_player:
		EventBus.big_message.emit("O golem acordou!")
		GameState.say_once("golem_acorda", "A pedra... levantou. A PEDRA LEVANTOU.")
		var p := GameState.player as Player
		if p != null:
			p.shake(0.6)


func _think(delta: float) -> Vector3:
	var p := GameState.player as Player
	if mode == Mode.DORMANT:
		activity = "Dormindo (parece pedra)"
		if p != null and not p.dead and notices_player(p):
			_wake()
			player_memory = memory_time
			last_player_pos = p.global_position
		return Vector3.ZERO
	if player_memory <= 0.0:
		_calm_t += delta
		if _calm_t > 6.0 and Fx.flat_dist(global_position, rest_spot) < 1.5:
			mode = Mode.DORMANT
			if _core != null:
				_core.emission_energy_multiplier = 1.0
			return Vector3.ZERO
		if _calm_t > 2.0:
			activity = "Voltando para o lugar"
			return nav_to(rest_spot, 0.6)
	else:
		_calm_t = 0.0
	return super._think(delta)


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Esmagando")) \
		.add(Behaviors.Wander.new(0.5, 0.0))


func _build_visual() -> void:
	var rock := _mat
	var torso := Fx.box(Vector3(1.6, 1.5, 1.1), rock)
	torso.position.y = 1.7
	torso.rotation.y = 0.1
	_visual.add_child(torso)
	var head := Fx.box(Vector3(0.7, 0.55, 0.6), rock)
	head.position = Vector3(0, 2.75, -0.15)
	_visual.add_child(head)
	_core = Fx.mat(Color(1.0, 0.4, 0.1), 1.0, true)
	var core := Fx.sphere(0.25, _core)
	core.position = Vector3(0, 1.8, -0.56)
	_visual.add_child(core)
	for sd: float in [-1.0, 1.0]:
		var arm := Fx.box(Vector3(0.55, 1.5, 0.55), rock)
		arm.position = Vector3(sd * 1.15, 1.4, 0)
		arm.set_meta("arm", sd)
		_visual.add_child(arm)
		var fist := Fx.box(Vector3(0.7, 0.6, 0.7), rock)
		fist.position = Vector3(sd * 1.2, 0.45, -0.1)
		fist.set_meta("arm", sd)
		_visual.add_child(fist)
		var leg := Fx.box(Vector3(0.6, 1.0, 0.6), rock)
		leg.position = Vector3(sd * 0.45, 0.5, 0)
		leg.set_meta("leg", sd)
		_visual.add_child(leg)
		var eye := Fx.box(Vector3(0.12, 0.06, 0.05), _core)
		eye.position = Vector3(sd * 0.17, 2.8, -0.46)
		_visual.add_child(eye)
	_body_parts = [torso, head]


func _animate(_delta: float, speed_now: float) -> void:
	var moving := clampf(speed_now, 0.0, 1.0)
	for n in _visual.get_children():
		if n.has_meta("leg"):
			n.rotation.x = sin(_anim_t * 4.0 + float(n.get_meta("leg")) * 1.5) * 0.35 * moving
		elif n.has_meta("arm"):
			n.rotation.x = sin(_anim_t * 4.0 - float(n.get_meta("arm")) * 1.5) * 0.25 * moving - (0.8 if telegraph else 0.0)
