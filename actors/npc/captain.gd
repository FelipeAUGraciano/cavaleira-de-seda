class_name Captain
extends Hunter
## A Capitã da expedição (minichefe do Ato 4, guarda a Subida antiga para o Portão).
## Armadura, espada pesada e uma tocha. Corte pesado, investida com escudo e frasco de fogo
## (área no chão que queima e acaba com as teias por perto). Furiosa: giro da espada.
## Na metade da vida, sopra a trompa: dois espadachins chegam correndo (uma vez).

signal horn

var _horned := false


func _init(_r: String = "capita") -> void:
	super._init("capita")
	display_name = "Capitã da expedição"
	level = 16
	max_hp = 480.0
	speed = 3.3
	body_radius = 0.5
	model_size = 2.05
	model_tint = Color(1.0, 0.7, 0.65)
	sight_range = 12.0
	memory_time = 99.0
	leash_range = 30.0
	food_satiety = 100.0
	food_silk = 60.0
	food_xp = 400
	food_energy = 10.0
	senses_text = "visão (12 m) e barulho; guarda a Subida antiga"
	add_attack(Attack.make("corte_pesado", "Corte pesado", {"max_range": 2.8, "windup": 0.7, "active": 0.2, "recover": 0.7,
		"cooldown": 1.8, "damage": 32.0, "reach": 2.8, "arc": 110.0, "lunge": 3.0, "weight": 3.0}))
	add_attack(Attack.make("investida", "Investida com escudo", {"min_range": 3.0, "max_range": 9.0, "windup": 0.8, "active": 0.4,
		"recover": 0.9, "cooldown": 5.0, "damage": 24.0, "reach": 1.8, "arc": 90.0, "lunge": 12.0, "weight": 2.0}))
	add_attack(Attack.make("frasco", "Frasco de fogo", {"min_range": 3.5, "max_range": 10.0, "windup": 1.0, "active": 0.2,
		"recover": 0.8, "cooldown": 6.0, "damage": 20.0, "shape": Attack.Shape.CIRCLE, "reach": 2.2, "at_point": true,
		"knockback": false, "effect": "burn", "effect_power": 4.0, "weight": 2.0}))
	add_attack(Attack.make("giro", "Giro da espada", {"max_range": 3.0, "windup": 0.6, "active": 0.3, "recover": 0.8,
		"cooldown": 5.0, "damage": 26.0, "shape": Attack.Shape.RING, "reach": 3.2, "only_enraged": true, "weight": 2.5}))


func _ready() -> void:
	super._ready()
	add_to_group("boss")


func on_attack_active(a: Attack) -> void:
	super.on_attack_active(a)
	if a.id == "frasco":
		var at: Vector3 = atk_point
		for s in WebNetwork.strands.duplicate():
			if is_instance_valid(s) and (s as WebStrand).distance_to(at) < 3.0:
				WebNetwork.burn_strand(s)
		for t in WebNetwork.traps.duplicate():
			if is_instance_valid(t) and Fx.flat_dist(t.global_position, at) < 3.0:
				WebNetwork.burn_trap(t)


func take_damage(amount: float, source: Node3D = null) -> void:
	super.take_damage(amount, source)
	if not dead and not _horned and hp <= max_hp * 0.5:
		_horned = true
		EventBus.big_message.emit("A Capitã sopra a trompa!")
		GameState.say_once("capita_trompa", "Trompa. Isso é uma TROMPA. Ela chamou reforço!")
		horn.emit()


func entangle(duration: float) -> float:
	return super.entangle(duration * 0.5)   # armadura: a teia segura menos
