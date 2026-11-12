class_name Sister
extends Creature
## Irmãs-aranha do Berçário. Usam as mesmas patas com IK da Cavaleira.
##   Irmã menor (P): foge pela vibração e vira comida.
##   Irmã faminta (P, maior): caça a jogadora pela visão e devora as irmãs menores.

const TRACK_RANGE := 16.0         ## faminta sente o cheiro da filhote a esta distância
const BITE_DAMAGE := 18.0         ## três mordidas matam uma Filhote
const SIGHT := 9.0
const FOV := 160.0

var hunter := false
var legs: SpiderLegs
var stalking: bool:               ## (compatibilidade) seguindo o cheiro da jogadora
	get:
		return brain != null and brain.is_doing("stalk")


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
		sight_range = SIGHT
		sight_fov = FOV
		aggression = 1.0
		track_range = TRACK_RANGE
		stalk_speed = 0.9
		memory_time = 6.0
		attack_damage = 30.0       # contra irmãs menores (presa)
		attack_reach = 0.9
		hunger_threshold = 30.0
		needs.hunger_rate = 1.0
		combat_label = "Caçando você"
		add_attack(Attack.make("mordida", "Mordida", {"max_range": 1.7, "windup": 0.35, "active": 0.15, "recover": 0.45,
			"cooldown": 0.9, "damage": BITE_DAMAGE, "reach": 1.4, "arc": 80.0, "lunge": 4.5, "track": 8.0, "lead": 0.12, "weight": 3.0}))
		add_attack(Attack.make("pulo", "Pulo", {"min_range": 2.5, "max_range": 6.0, "windup": 0.55, "active": 0.4,
			"recover": 0.7, "cooldown": 4.0, "damage": 22.0, "shape": Attack.Shape.CIRCLE, "reach": 1.0, "leap": true,
			"track": 4.0, "lead": 0.4, "weight": 1.5}))
		add_attack(Attack.make("teia", "Teia cuspida", {"min_range": 3.0, "max_range": 8.0, "windup": 0.5, "active": 0.15,
			"recover": 0.5, "cooldown": 5.0, "damage": 4.0, "shape": Attack.Shape.CIRCLE, "reach": 1.2, "at_point": true,
			"track": 5.0, "lead": 0.45, "needs_sight": true, "knockback": false, "effect": "slow", "effect_power": 2.5, "weight": 1.5}))
		add_attack(Attack.make("frenesi", "Frenesi", {"max_range": 1.8, "windup": 0.22, "active": 0.12, "recover": 0.3,
			"cooldown": 4.0, "damage": 10.0, "reach": 1.5, "arc": 100.0, "lunge": 3.0, "track": 10.0,
			"only_enraged": true, "combo_next": "frenesi", "weight": 2.5}))
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


func _make_brain() -> Brain:
	if not hunter:
		return null   # a irmã menor só foge (lógica simples em _think)
	return Brain.new() \
		.add(Behaviors.Combat.new("Caçando você")) \
		.add(Behaviors.Stalk.new()) \
		.add(Behaviors.Forage.new()) \
		.add(Behaviors.Wander.new(6.0, 0.35))


func _think(delta: float) -> Vector3:
	if hunter:
		return super._think(delta)
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


func is_prey(o: Creature) -> bool:
	return hunter and o is Sister and not (o as Sister).hunter


func sees_player_as_prey(p: Player) -> bool:
	## Canibal: a Filhote é do tamanho dela, e ela está sempre com fome.
	return p.body_size() == 0 or needs.hunger > 75.0


func is_resting_phase() -> bool:
	return false   # no Berçário ninguém dorme


func combat_start() -> void:
	if noticed_player:
		EventBus.stalked.emit(self)


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
