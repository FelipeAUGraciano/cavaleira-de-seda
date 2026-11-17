class_name WolfSpider
extends Creature
## Aranha-lobo do breu (P, matilha de 3 a 4). Rival da protagonista: aranha que não tece,
## só corre e caça. Olhos grandes refletem a luz (dois pontinhos verdes no escuro).
## Sentidos: visão no escuro (8 m, enxerga melhor quem está com a runa acesa) e vibração.
## Uma que te sente uiva pelas patas e a matilha toda vem; elas cercam e mordem em sequência.
## Pulam em você de longe. Fogem quando sobra uma só e ela está ferida.

const PACK_RADIUS := 14.0
const BITE := 11.0

var pack := "matilha"
var legs: SpiderLegs


func _init() -> void:
	display_name = "Aranha-lobo do breu"
	size = Size.P
	level = 6
	max_hp = 34.0
	speed = 5.4
	body_radius = 0.36
	body_color = Color(0.2, 0.17, 0.14)
	food_satiety = 30.0
	food_silk = 22.0
	food_xp = 32
	senses_text = "visão no escuro (8 m; a runa acesa te entrega de 12 m) e vibração; a matilha avisa as outras"
	sight_range = 8.0
	sight_fov = 170.0
	aggression = 1.0
	track_range = 18.0
	stalk_speed = 0.9
	memory_time = 6.0
	leash_range = 30.0
	hunger_threshold = 35.0
	retreat_frac = 0.25
	attack_damage = BITE
	attack_reach = 1.0
	needs.hunger_rate = 1.0
	combat_label = "Caçando em matilha"
	add_attack(Attack.make("mordida", "Mordida", {"max_range": 1.7, "windup": 0.35, "active": 0.14, "recover": 0.5,
		"cooldown": 1.1, "damage": BITE, "reach": 1.4, "arc": 80.0, "lunge": 4.5, "weight": 3.0}))
	add_attack(Attack.make("bote", "Bote", {"min_range": 2.5, "max_range": 6.5, "windup": 0.55, "active": 0.4,
		"recover": 0.8, "cooldown": 4.0, "damage": 15.0, "shape": Attack.Shape.CIRCLE, "reach": 1.1, "leap": true, "weight": 2.0}))
	add_attack(Attack.make("flanco", "Mordida no flanco", {"max_range": 1.8, "windup": 0.25, "active": 0.12, "recover": 0.4,
		"cooldown": 3.0, "damage": BITE * 1.3, "reach": 1.5, "arc": 100.0, "lunge": 3.0, "flank": true, "weight": 2.0}))


func _ready() -> void:
	super._ready()
	add_to_group("predator")
	add_to_group("wolf_spider")


func notices_player(p: Player) -> bool:
	var d := flat_dist_to(p)
	var k := 0.35 if asleep else 1.0
	if d < body_radius + 1.0:
		return true
	if d < p.noise_radius() * k:
		return true
	var sight := (12.0 if p.rune_on else sight_range) * k
	return can_see(p, sight * maxf(p.visibility_mult(), 0.6), sight_fov)


func sees_player_as_prey(_p: Player) -> bool:
	return true   # em matilha, qualquer aranha sozinha é comida


func is_prey(o: Creature) -> bool:
	return int(o.size) == int(Size.P) and not (o is WolfSpider) and not (o is Bat)


func eats_carrion() -> bool:
	return true


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Caçando em matilha")) \
		.add(Behaviors.Retreat.new()) \
		.add(Behaviors.Stalk.new()) \
		.add(Behaviors.Forage.new()) \
		.add(Behaviors.Sleep.new()) \
		.add(Behaviors.Roam.new()) \
		.add(Behaviors.Wander.new(5.0, 0.4))


func combat_start() -> void:
	howl()


func _on_hurt(source: Node3D) -> void:
	if source != null and source.is_in_group("player"):
		howl()


func howl() -> void:
	## Bate as patas no chão: a matilha inteira larga o que está fazendo e vem.
	var p := GameState.player as Player
	if p == null or p.dead:
		return
	var called := 0
	for o in get_tree().get_nodes_in_group("wolf_spider"):
		var w := o as WolfSpider
		if w == null or w == self or w.dead or w.pack != pack or w.flat_dist_to(self) > PACK_RADIUS:
			continue
		if w.player_memory <= 0.0:
			w.player_memory = w.memory_time
			w.last_player_pos = p.global_position
			w.interest = maxf(w.interest, 70.0)
			w._bored_t = 0.0
			w.asleep = false
			if w.brain != null:
				w.brain.wake_up()
			called += 1
	if called > 0 and near_player:
		EventBus.message.emit("Patas batendo no chão em volta... a matilha veio.")
		GameState.say_once("matilha", "Uma, duas, três... são VÁRIAS. E são aranhas. Aranhas que não tecem. Aranhas que CORREM.")


func _build_visual() -> void:
	var k := body_radius / 0.42
	var head := Fx.sphere(0.34 * k, _mat)
	head.position = Vector3(0.0, 0.42 * k, -0.2 * k)
	_visual.add_child(head)
	var abdomen := Fx.sphere(0.44 * k, _mat)
	abdomen.scale = Vector3(0.9, 0.8, 1.15)
	abdomen.position = Vector3(0.0, 0.5 * k, 0.48 * k)
	_visual.add_child(abdomen)
	var stripe := Fx.box(Vector3(0.08 * k, 0.03, 0.7 * k), Fx.mat(Color(0.55, 0.48, 0.38)))
	stripe.position = Vector3(0, 0.88 * k, 0.4 * k)
	_visual.add_child(stripe)
	var eye_mat := Fx.mat(Color(0.55, 1.0, 0.55), 3.0, true)
	for x: float in [-0.13, 0.13]:   # os olhos grandes refletem: dois pontos verdes no escuro
		var eye := Fx.sphere(0.08 * k, eye_mat)
		eye.position = Vector3(x * k, 0.55 * k, -0.48 * k)
		_visual.add_child(eye)
	_body_parts = [head, abdomen, stripe]
	legs = SpiderLegs.new()
	legs.leg_color = body_color.darkened(0.25)
	legs.setup(_visual, k * 1.15, 1)
	add_child(legs)


func _lod_changed(near: bool) -> void:
	legs.process_mode = Node.PROCESS_MODE_INHERIT if near else Node.PROCESS_MODE_DISABLED
	legs.visible = near


func _animate(_delta: float, _speed_now: float) -> void:
	legs.velocity_hint = Vector3(velocity.x, 0.0, velocity.z)
