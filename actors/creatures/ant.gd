class_name Ant
extends Creature
## Formiga-de-seda (P, em bando): sai do formigueiro em fila atrás de seda e de carniça.
## Rói os seus fios-guia (pela ponta do pilar) e come cadáveres. Uma que apanha ou que te
## sente chama as vizinhas: sozinha morre fácil, o bando cerca.
## Sentidos: cheiro (4,5 m) e vibração (o seu barulho). Não enxerga longe.

const ALARM_RADIUS := 9.0
const BITE_DAMAGE := 6.0
const SMELL := 4.5

var ahead: Ant = null          ## a formiga da frente na fila (null = puxa a fila)
var nest: Node3D = null        ## o formigueiro (volta para lá para dormir)


func _init() -> void:
	display_name = "Formiga-de-seda"
	size = Size.P
	level = 2
	max_hp = 14.0
	speed = 3.8
	body_radius = 0.2
	body_color = Color(0.42, 0.12, 0.08)
	food_satiety = 8.0
	food_silk = 12.0
	food_xp = 6
	senses_text = "cheiro (4,5 m) e vibração; o bando avisa as outras"
	rest_phase = CaveClock.Phase.BRILHO
	sleep_heal = 0.05
	hunger_threshold = 25.0
	aggression = 1.0
	track_range = 9.0
	memory_time = 5.0
	leash_range = 18.0
	roam_speed = 0.55
	attack_damage = 5.0          # contra larvas e carniça
	attack_reach = 0.6
	needs.hunger_rate = 0.8
	combat_label = "Atacando em bando"
	add_attack(Attack.make("mordida", "Mordida", {"max_range": 1.2, "windup": 0.4, "active": 0.12, "recover": 0.5,
		"cooldown": 1.2, "damage": BITE_DAMAGE, "reach": 1.0, "arc": 90.0, "lunge": 3.5, "weight": 3.0}))
	add_attack(Attack.make("acido", "Jato de ácido", {"min_range": 1.5, "max_range": 4.0, "windup": 0.6, "active": 0.15,
		"recover": 0.6, "cooldown": 5.0, "damage": 4.0, "shape": Attack.Shape.LINE, "reach": 4.0, "width": 0.6,
		"knockback": false, "effect": "acid", "weight": 1.0}))


func _ready() -> void:
	super._ready()
	add_to_group("ant")


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Atacando em bando")) \
		.add(ChewSilk.new()) \
		.add(Behaviors.Forage.new()) \
		.add(Behaviors.Sleep.new()) \
		.add(FollowLine.new()) \
		.add(Behaviors.Roam.new()) \
		.add(Behaviors.Wander.new(4.0, 0.4))


func _build_visual() -> void:
	var r := body_radius
	var dark := Fx.mat(body_color.darkened(0.3))
	for i in 3:
		var seg := Fx.sphere(r * [0.75, 0.6, 1.0][i], _mat if i != 1 else dark)
		seg.scale = Vector3(1.0, 0.8, 1.15)
		seg.position = Vector3(0.0, r * 0.9, [-r * 1.3, 0.0, r * 1.5][i])
		_visual.add_child(seg)
	var leg_mat := Fx.mat(body_color.darkened(0.5))
	for side in [-1.0, 1.0]:
		for k in 3:
			var leg := Fx.box(Vector3(r * 1.6, 0.03, 0.03), leg_mat)
			leg.position = Vector3(side * r * 0.9, r * 0.55, (k - 1) * r * 0.7)
			leg.rotation.y = side * (k - 1) * 0.35
			leg.set_meta("side", side)
			leg.set_meta("k", k)
			_visual.add_child(leg)
	var ant_mat := Fx.mat(body_color.darkened(0.4))
	for side in [-1.0, 1.0]:
		var antenna := Fx.box(Vector3(0.02, 0.02, r * 1.4), ant_mat)
		antenna.position = Vector3(side * r * 0.3, r * 1.3, -r * 2.2)
		antenna.rotation = Vector3(0.5, side * 0.35, 0.0)
		_visual.add_child(antenna)


func _animate(_delta: float, speed_now: float) -> void:
	for n in _visual.get_children():
		if n.has_meta("side"):
			var k: int = n.get_meta("k")
			n.rotation.x = sin(_anim_t * 22.0 + k * 2.1 + float(n.get_meta("side"))) * 0.5 * clampf(speed_now, 0.0, 1.0)


# ---------------------------------------------------------------- sentidos e bando

func notices_player(p: Player) -> bool:
	if asleep:
		return flat_dist_to(p) < 1.2
	var d := flat_dist_to(p)
	return d < SMELL * (1.3 if p.rune_on else 1.0) or d < p.noise_radius() * 0.8


func combat_start() -> void:
	alarm()


func _on_hurt(source: Node3D) -> void:
	if source != null and source.is_in_group("player"):
		alarm()


func alarm() -> void:
	## Feromônio de alarme: as vizinhas largam o que estão fazendo e vêm.
	var p := GameState.player as Player
	if p == null or p.dead:
		return
	for o in get_tree().get_nodes_in_group("ant"):
		var a := o as Ant
		if a == null or a == self or a.dead or a.flat_dist_to(self) > ALARM_RADIUS:
			continue
		if a.player_memory <= 0.0:
			a.player_memory = a.memory_time
			a.last_player_pos = p.global_position
			a.interest = maxf(a.interest, 60.0)
			a._bored_t = 0.0
			a.asleep = false
			if a.brain != null:
				a.brain.wake_up()


func is_prey(o: Creature) -> bool:
	return o is Larva


func eats_carrion() -> bool:
	return true


func is_threat(_o: Creature) -> bool:
	return false   # o bando não foge de ninguém


func sees_player_as_prey(_p: Player) -> bool:
	return false   # não sai seguindo seu cheiro de longe: só ataca quem chega perto


func fix_line() -> void:
	## A da frente morreu: segue a que vinha antes dela.
	var guard := 0
	while ahead != null and guard < 12:
		if not is_instance_valid(ahead):
			ahead = null
			return
		if not ahead.dead:
			return
		ahead = ahead.ahead
		guard += 1


func strand_target() -> WebStrand:
	## Fio-guia que dá para roer: a ponta (pilar) mais perto, alcançável a pé.
	var best: WebStrand = null
	var best_d := 11.0
	for s in WebNetwork.strands:
		if not is_instance_valid(s):
			continue
		for end in [s.a_pos, s.b_pos]:
			var d := Fx.flat_dist(global_position, end)
			if d < best_d:
				best_d = d
				best = s
	return best


func strand_end(s: WebStrand) -> Vector3:
	var e: Vector3 = s.a_pos if Fx.flat_dist(global_position, s.a_pos) < Fx.flat_dist(global_position, s.b_pos) else s.b_pos
	return Vector3(e.x, 0.0, e.z)


class ChewSilk extends Behavior:
	## Seda é comida: vai até a ponta do fio e rói até arrebentar.
	var strand: WebStrand = null
	var chew := 0.0

	func _init() -> void:
		id = "chew"
		label = "Roendo seda"

	func utility(c: Creature) -> float:
		if c.asleep or c.needs.hunger < 15.0:
			return 0.0
		var a := c as Ant
		if strand == null or not is_instance_valid(strand):
			strand = a.strand_target()
		return 0.55 if strand != null else 0.0

	func start(_c: Creature) -> void:
		chew = 0.0

	func run(c: Creature, delta: float) -> Vector3:
		var a := c as Ant
		if strand == null or not is_instance_valid(strand):
			return Vector3.ZERO
		var end := a.strand_end(strand)
		if Fx.flat_dist(c.global_position, end) > 1.4:
			c.activity = "Indo roer seda"
			return c.nav_to(end, 0.8)
		c.activity = "Roendo seda"
		c.face_toward(end)
		chew += delta
		if chew >= 4.0:
			var mine: bool = strand.in_territory
			WebNetwork.remove_strand(strand)
			EventBus.web_touched.emit(c.global_position, c)
			if mine or (GameState.player != null and c.flat_dist_to(GameState.player) < 25.0):
				EventBus.message.emit("Formigas roeram um fio de seda!")
			c.needs.hunger = maxf(0.0, c.needs.hunger - 40.0)
			strand = null
			chew = 0.0
		return Vector3.ZERO


class FollowLine extends Behavior:
	## Anda em fila atrás da formiga da frente (a primeira escolhe o caminho).
	func _init() -> void:
		id = "line"
		label = "Andando em fila"

	func utility(c: Creature) -> float:
		var a := c as Ant
		a.fix_line()
		if a.ahead == null or a.ahead.asleep:
			return 0.0
		if a.flat_dist_to(a.ahead) > 16.0:
			return 0.0
		return 0.4

	func run(c: Creature, _delta: float) -> Vector3:
		var a := c as Ant
		a.fix_line()
		if a.ahead == null:
			return Vector3.ZERO   # a da frente morreu entre a escolha e o passo
		var spot := a.ahead.global_position - a.ahead.facing * 0.75
		spot.y = 0.0
		if Fx.flat_dist(c.global_position, spot) < 0.35:
			return Vector3.ZERO
		return c.nav_to(spot, 0.9 if Fx.flat_dist(c.global_position, spot) > 1.5 else 0.55)
