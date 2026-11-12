class_name Lizard
extends Creature
## Lagarto-lanterna (M): territorial. Uma isca de luz na cabeça atrai larvas, que ele come.
## A luz também revela quem chega perto (runa apagada não esconde a 5 m da isca).
## Quem entra no território leva um aviso (isca pisca vermelho); quem fica, é atacado:
## mordida de perto e investida de longe. Não persegue para fora do território.
## Comer o lagarto dá Energia máxima.

enum Mode { IDLE, WARN, CHASE, RETURN, EAT }

const SIGHT := 9.0
const FOV := 130.0
const LURE_REVEAL := 5.0
const LURE_PULL := 9.0
const BITE_DAMAGE := 26.0
const CHARGE_DAMAGE := 32.0
const CHARGE_SPEED := 12.0

var territory_radius := 9.0
var mode: Mode = Mode.IDLE
var mode_time := 0.0
var attack_done := false
var bite_cd := 0.0
var charge_cd := 2.0
var charge_dir := Vector3.ZERO
var lure: OmniLight3D
var _lure_mat: StandardMaterial3D
var _warned := false


func _init() -> void:
	display_name = "Lagarto-lanterna"
	size = Size.M
	level = 5
	max_hp = 70.0
	speed = 3.4
	body_radius = 0.6
	body_color = Color(0.36, 0.42, 0.3)
	food_satiety = 45.0
	food_silk = 25.0
	food_xp = 45
	food_energy = 10.0
	senses_text = "visão (9 m, cone de 130°); a isca revela tudo a 5 m"
	model_name = "lagarto"
	rest_phase = CaveClock.Phase.BRILHO
	sight_range = SIGHT
	sight_fov = FOV
	attack_damage = BITE_DAMAGE
	attack_reach = 1.5
	needs.hunger_rate = 2.0
	model_size = 2.4
	model_fit = "length"
	aggression = 0.6
	combat_label = "Defendendo o território"
	add_attack(Attack.make("mordida", "Mordida", {"max_range": 2.3, "windup": 0.45, "active": 0.18, "recover": 0.6,
		"cooldown": 1.4, "damage": BITE_DAMAGE, "reach": 2.1, "arc": 75.0, "lunge": 4.0, "track": 6.0, "lead": 0.15, "weight": 3.0}))
	add_attack(Attack.make("investida", "Investida", {"min_range": 3.0, "max_range": 8.0, "windup": 0.6, "active": 0.5,
		"recover": 0.9, "cooldown": 3.5, "damage": CHARGE_DAMAGE, "shape": Attack.Shape.LINE, "reach": 6.5, "width": 1.4,
		"lunge": CHARGE_SPEED, "track": 3.0, "lead": 0.35, "needs_sight": true, "weight": 2.0}))
	add_attack(Attack.make("cauda", "Chicote de cauda", {"max_range": 2.8, "windup": 0.4, "active": 0.22, "recover": 0.5,
		"cooldown": 3.0, "damage": 20.0, "shape": Attack.Shape.RING, "reach": 2.7, "track": 0.0, "flank": true, "weight": 2.0}))
	add_attack(Attack.make("clarao", "Clarão da isca", {"max_range": 6.0, "windup": 0.8, "active": 0.15, "recover": 0.7,
		"cooldown": 8.0, "damage": 0.0, "shape": Attack.Shape.RING, "reach": 6.0, "track": 0.0, "knockback": false,
		"only_enraged": true, "effect": "slow", "effect_power": 2.5, "weight": 1.5}))


func _ready() -> void:
	super._ready()
	add_to_group("predator")
	add_to_group("lure")
	collision_mask = 1 | 2   # larvas hipnotizadas em volta da isca não o prendem


func _build_visual() -> void:
	var body := Fx.sphere(body_radius, _mat)
	body.scale = Vector3(0.9, 0.5, 1.8)
	body.position.y = body_radius * 0.5
	_visual.add_child(body)
	var head := Fx.sphere(body_radius * 0.6, _mat)
	head.scale = Vector3(1.0, 0.7, 1.2)
	head.position = Vector3(0.0, body_radius * 0.6, -body_radius * 1.6)
	_visual.add_child(head)
	var tail := Fx.box(Vector3(0.18, 0.12, 1.2), _mat)
	tail.position = Vector3(0.0, body_radius * 0.35, body_radius * 1.9)
	_visual.add_child(tail)
	var stalk := Fx.box(Vector3(0.04, 0.5, 0.04), Fx.mat(body_color.darkened(0.3)))
	stalk.position = Vector3(0.0, body_radius * 1.1, -body_radius * 1.8)
	stalk.rotation.x = -0.4
	_visual.add_child(stalk)
	_lure_mat = Fx.mat(Color(0.75, 1.0, 0.45), 3.0, true)
	var bulb := Fx.sphere(0.12, _lure_mat)
	bulb.position = Vector3(0.0, body_radius * 1.4, -body_radius * 2.1)
	_visual.add_child(bulb)
	lure = OmniLight3D.new()
	lure.light_color = Color(0.75, 1.0, 0.45)
	lure.omni_range = 6.0
	lure.light_energy = 1.6
	lure.position = bulb.position + Vector3(0.0, 0.3, 0.0)
	_visual.add_child(lure)
	_body_parts = [body, head, tail, stalk, bulb]   # o modelo já tem a isca; a luz continua por código


func lure_position() -> Vector3:
	return lure.global_position if lure != null else global_position


func sees(p: Player) -> bool:
	if p == null or p.dead:
		return false
	if asleep:
		return flat_dist_to(p) < 2.0 or flat_dist_to(p) < p.noise_radius() * 0.3
	if Fx.flat_dist(lure_position(), p.global_position) <= LURE_REVEAL and has_line_of_sight(p):
		return true
	return can_see(p, SIGHT * p.visibility_mult(), FOV)


func in_territory(pos: Vector3) -> bool:
	return Fx.flat_dist(pos, home) <= territory_radius


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Defendendo o território")) \
		.add(Behaviors.Flee.new()) \
		.add(Behaviors.Fight.new()) \
		.add(Behaviors.Sleep.new()) \
		.add(LureFeed.new())


# ---------------------------------------------------------------- vida

func lure_active() -> bool:
	return not dead and not asleep


func notices_player(p: Player) -> bool:
	return sees(p)


func find_rival() -> Creature:
	## Expulsa sapos do território (outros lagartos do ninho são tolerados).
	var a: Creature = _last_attacker as Creature if is_instance_valid(_last_attacker) else null
	if a != null and is_instance_valid(a) and not a.dead and flat_dist_to(a) < 8.0:
		return a
	return World.nearest(home, territory_radius, func(o): return o is Frog)


# ---------------------------------------------------------------- combate (defesa do território)

func combat_wants() -> bool:
	var p := GameState.player as Player
	var intruder := p != null and not p.dead and in_territory(p.global_position) and noticed_player
	return intruder or cur_attack != null or mode == Mode.WARN or mode == Mode.CHASE or mode == Mode.RETURN


func combat_locked() -> bool:
	return cur_attack != null


func combat_start() -> void:
	if mode == Mode.IDLE:
		mode = Mode.WARN
		mode_time = 0.0
		if not _warned:
			_warned = true
			EventBus.message.emit("O Lagarto-lanterna pisca a isca: você está no território dele!")
			GameState.say_once("lagarto_aviso", "Ok, ok, entendi o recado luminoso. ...Ou não entendi?")


func combat_stop() -> void:
	if mode != Mode.RETURN:
		mode = Mode.IDLE
	cancel_attack()


func combat_tick(delta: float) -> Vector3:
	mode_time += delta
	var p := GameState.player as Player
	if cur_attack != null:
		return attack_tick(delta, p)
	var intruder := p != null and not p.dead and in_territory(p.global_position) and noticed_player
	match mode:
		Mode.RETURN:
			if flat_dist_to_home() < 1.0:
				mode = Mode.IDLE
				return Vector3.ZERO
			if intruder:
				mode = Mode.CHASE
			return nav_to(home, 0.8)
		Mode.WARN:
			face_toward(p.global_position if p != null else home)
			if not intruder and mode_time > 0.4:
				mode = Mode.IDLE
				return Vector3.ZERO
			if mode_time >= (0.8 if enraged else 1.4):
				mode = Mode.CHASE
				mode_time = 0.0
			return Vector3.ZERO
		Mode.CHASE:
			if p == null or p.dead or Fx.flat_dist(p.global_position, home) > territory_radius + 4.0:
				mode = Mode.RETURN
				EventBus.message.emit("O Lagarto-lanterna volta para o território.")
				return Vector3.ZERO
			return fight_player(delta, p)
	if intruder:
		combat_start()
	return Vector3.ZERO


func on_attack_active(a: Attack) -> void:
	if a.id == "clarao" and lure != null:
		lure.light_energy = 9.0
		EventBus.message.emit("O clarão da isca te ofuscou!")


func flat_dist_to_home() -> float:
	return Fx.flat_dist(global_position, home)


func _larva_in_reach() -> Larva:
	return World.nearest(global_position, 3.5, func(o): return o is Larva and (Fx.flat_dist(o.global_position, lure_position()) < 1.4 or flat_dist_to(o) < body_radius + 1.0)) as Larva


func _on_hurt(source: Node3D) -> void:
	if source != null and source.is_in_group("player"):
		mode = Mode.CHASE
		mode_time = 0.0


func _update_glow(delta: float) -> void:
	super._update_glow(delta)
	if _lure_mat == null:
		return
	var warn := mode == Mode.WARN or (cur_attack != null and atk_phase == 0)
	var c := Color(1.0, 0.25, 0.2) if warn else Color(0.75, 1.0, 0.45)
	var pulse := 1.0 + 0.5 * sin(_anim_t * (14.0 if warn else 2.5))
	if asleep:
		pulse = 0.12   # dormindo, a isca quase apaga: a melhor hora para passar
	_lure_mat.albedo_color = c
	_lure_mat.emission = c
	_lure_mat.emission_energy_multiplier = 3.0 * pulse
	lure.light_color = c
	lure.light_energy = 1.6 * pulse


func _animate(_delta: float, speed_now: float) -> void:
	_visual.rotation.z = sin(_anim_t * 9.0) * 0.08 * clampf(speed_now / speed, 0.0, 1.5)


class LureFeed extends Behavior:
	## Fica perto de casa com a isca acesa; quando está com fome, come as larvas que chegam.
	func _init() -> void:
		id = "lure"
		label = "Pescando com a isca"

	func utility(_c: Creature) -> float:
		return 0.3

	func run(c: Creature, delta: float) -> Vector3:
		var lz := c as Lizard
		if lz.flat_dist_to_home() > 2.5:
			return lz.nav_to(lz.home, 0.6)
		if lz.needs.hunger > 20.0:
			var snack := lz._larva_in_reach()
			if snack != null:
				lz.face_toward(snack.global_position)
				snack.take_damage(999.0, lz)
				lz.needs.hunger = 0.0
				lz.activity = "Comendo uma larva"
				return Vector3.ZERO
		lz.activity = label
		return lz.wander(delta, 2.5, 0.15)
