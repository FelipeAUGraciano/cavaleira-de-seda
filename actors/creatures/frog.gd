class_name Frog
extends Creature
## Sapo-de-rocha (M): predador de emboscada que caça na fase da Caça e dorme na poça no Brilho.
## Sentidos: visão em cone (10 m, 140°) e audição. Contra a jogadora: mordida e língua que puxa.
## Vida: come larvas e cadáveres, passeia entre câmaras, foge de bichos grandes e,
## ferido, volta para a poça para se curar. Comer o sapo dá Resistência a Ácido.

const SIGHT := 10.0
const FOV := 140.0
const BITE_DAMAGE := 26.0      ## dois botes matam uma Filhote

var mode_time := 0.0          ## (compatibilidade com testes antigos)
enum Mode { IDLE, CHASE }
var mode: Mode = Mode.IDLE


func _init() -> void:
	display_name = "Sapo-de-rocha"
	size = Size.M
	level = 4
	max_hp = 80.0
	speed = 4.2
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
	aggression = 0.9
	track_range = 16.0
	memory_time = 7.0
	needs.hunger_rate = 0.5
	combat_label = "Caçando você"
	# Golpes (aviso no chão → golpe que vai até o fim → recuperação)
	add_attack(Attack.make("bote", "Bote", {"max_range": 2.4, "windup": 0.45, "active": 0.18, "recover": 0.55,
		"cooldown": 1.3, "damage": BITE_DAMAGE, "reach": 2.0, "arc": 80.0, "lunge": 5.5, "track": 7.0, "lead": 0.15, "weight": 3.0}))
	add_attack(Attack.make("lingua", "Língua", {"min_range": 2.5, "max_range": 7.0, "windup": 0.6, "active": 0.2,
		"recover": 0.7, "cooldown": 4.0, "damage": 8.0, "shape": Attack.Shape.LINE, "reach": 7.5, "width": 0.9,
		"track": 4.0, "lead": 0.3, "needs_sight": true, "knockback": false, "effect": "pull", "effect_power": 14.0,
		"combo_next": "bote", "weight": 2.0}))
	add_attack(Attack.make("salto", "Salto esmagador", {"min_range": 3.5, "max_range": 8.0, "windup": 0.7, "active": 0.45,
		"recover": 0.9, "cooldown": 6.0, "damage": 30.0, "shape": Attack.Shape.CIRCLE, "reach": 1.6, "leap": true,
		"track": 3.0, "lead": 0.45, "weight": 1.5}))
	add_attack(Attack.make("giro", "Giro de língua", {"max_range": 3.0, "windup": 0.5, "active": 0.25, "recover": 0.6,
		"cooldown": 3.5, "damage": 18.0, "shape": Attack.Shape.RING, "reach": 3.0, "track": 0.0, "flank": true, "weight": 2.0}))
	add_attack(Attack.make("cuspe", "Cuspe ácido", {"min_range": 3.0, "max_range": 9.0, "windup": 0.7, "active": 0.2,
		"recover": 0.5, "cooldown": 5.0, "damage": 12.0, "shape": Attack.Shape.CIRCLE, "reach": 1.4, "at_point": true,
		"track": 5.0, "lead": 0.5, "needs_sight": true, "only_enraged": true, "effect": "acid", "weight": 2.0}))


func _ready() -> void:
	super._ready()
	add_to_group("predator")


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Caçando você")) \
		.add(Behaviors.Retreat.new()) \
		.add(Behaviors.Flee.new()) \
		.add(Behaviors.Fight.new()) \
		.add(Behaviors.Stalk.new()) \
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

func combat_start() -> void:
	if mode == Mode.IDLE and noticed_player:
		EventBus.message.emit("O %s te viu!" % display_name)
	mode = Mode.CHASE


func combat_stop() -> void:
	mode = Mode.IDLE
	cancel_attack()


func on_attack_active(a: Attack) -> void:
	var mouth := global_position + Vector3.UP * 0.6
	match a.id:
		"lingua":
			Fx.beam(get_parent(), mouth, mouth + facing * a.reach, Color(0.95, 0.45, 0.55), 0.22, 0.12)
		"giro":
			for i in 8:
				var d := facing.rotated(Vector3.UP, i * TAU / 8.0)
				Fx.beam(get_parent(), mouth, mouth + d * a.reach, Color(0.95, 0.45, 0.55), 0.18, 0.08)
		"cuspe":
			Fx.beam(get_parent(), mouth, atk_point + Vector3.UP * 0.1, Color(0.6, 0.95, 0.3), 0.2, 0.1)
			AcidPuddle.spawn(get_parent(), atk_point, 1.4, 5.0)


func _on_hurt(source: Node3D) -> void:
	if source != null and source.is_in_group("player"):
		mode = Mode.CHASE


func _animate(_delta: float, speed_now: float) -> void:
	var hop := absf(sin(_anim_t * 7.0)) * 0.25 * clampf(speed_now / speed, 0.0, 1.0)
	if cur_attack != null and cur_attack.leap and atk_phase == 1:
		hop = sin(clampf(atk_t / cur_attack.active, 0.0, 1.0) * PI) * 1.6   # no ar
	elif cur_attack != null and atk_phase == 0:
		hop = -0.08 * clampf(atk_t / cur_attack.windup, 0.0, 1.0)          # se agacha antes
	_visual.position.y = hop - (0.15 if asleep else 0.0)
