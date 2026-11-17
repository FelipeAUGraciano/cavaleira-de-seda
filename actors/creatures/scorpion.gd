class_name Scorpion
extends Creature
## Escorpião-de-obsidiana (M, Ninho dos escorpiões no Abismo). Carapaça preta e vítrea,
## ferrão com brilho vermelho. Caçador de emboscada: fica parado no ninho e sente o chão.
## Sentidos: vibração (quem anda perto, 7 m; correndo, 11 m) e visão curta (5 m).
## Golpes: pinças (cone, emendam), ferrão em linha (veneno) e, furioso, giro de cauda.
## Comer a carne envenena um pouco e sobe a Resistência a Veneno.

const BITE := 16.0
const STING := 22.0


func _init() -> void:
	display_name = "Escorpião-de-obsidiana"
	size = Size.M
	level = 7
	max_hp = 80.0
	speed = 3.7
	body_radius = 0.55
	body_color = Color(0.08, 0.07, 0.1)
	food_satiety = 50.0
	food_silk = 28.0
	food_xp = 60
	food_poison = 1
	senses_text = "vibração do chão (7 m; correndo, 11 m) e visão curta (5 m)"
	rest_phase = CaveClock.Phase.BRILHO
	sight_range = 5.0
	sight_fov = 150.0
	aggression = 0.85
	track_range = 14.0
	stalk_speed = 0.8
	memory_time = 4.0
	attack_damage = BITE
	attack_reach = 1.4
	hunger_threshold = 40.0
	needs.hunger_rate = 1.0
	combat_label = "Caçando você"
	add_attack(Attack.make("pincas", "Pinças", {"max_range": 2.2, "windup": 0.4, "active": 0.16, "recover": 0.45,
		"cooldown": 1.2, "damage": BITE, "reach": 1.9, "arc": 90.0, "lunge": 3.5, "combo_next": "pincas2", "weight": 3.0}))
	add_attack(Attack.make("pincas2", "Pinça cruzada", {"max_range": 2.4, "windup": 0.25, "active": 0.14, "recover": 0.55,
		"cooldown": 3.0, "damage": BITE * 0.8, "reach": 2.0, "arc": 110.0, "lunge": 2.0, "weight": 0.0}))
	add_attack(Attack.make("ferrao", "Ferrão", {"min_range": 1.5, "max_range": 4.2, "windup": 0.6, "active": 0.2,
		"recover": 0.8, "cooldown": 3.2, "damage": STING, "shape": Attack.Shape.LINE, "reach": 3.8, "width": 0.9,
		"lunge": 2.5, "effect": "poison", "effect_power": 6.0, "weight": 2.0}))
	add_attack(Attack.make("giro", "Giro de cauda", {"max_range": 2.6, "windup": 0.45, "active": 0.25, "recover": 0.6,
		"cooldown": 5.0, "damage": 18.0, "shape": Attack.Shape.RING, "reach": 2.6, "only_enraged": true, "flank": true,
		"effect": "poison", "effect_power": 3.0, "weight": 2.0}))


func _ready() -> void:
	super._ready()
	add_to_group("predator")


func notices_player(p: Player) -> bool:
	## Sente o chão: andando perto, correndo de mais longe. Sobre um fio ou parada, não.
	var d := flat_dist_to(p)
	var k := 0.35 if asleep else 1.0
	if d < body_radius + 1.0:
		return true
	if not p.on_strand:
		var spd := Vector2(p.velocity.x, p.velocity.z).length()
		if spd > 0.8 and d < (11.0 if spd > Player.WALK_SPEED + 0.5 else 7.0) * k:
			return true
	return can_see(p, sight_range * p.visibility_mult() * k, sight_fov)


func is_prey(o: Creature) -> bool:
	return int(o.size) < int(Size.M) and not (o is Bat)


func eats_carrion() -> bool:
	return true


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Caçando você")) \
		.add(Behaviors.Flee.new()) \
		.add(Behaviors.Stalk.new()) \
		.add(Behaviors.Forage.new()) \
		.add(Behaviors.Sleep.new()) \
		.add(Behaviors.Wander.new(4.0, 0.3))


func _build_visual() -> void:
	var shell := Fx.mat(body_color)
	shell.metallic = 0.7
	shell.roughness = 0.15
	var edge := Fx.mat(Color(0.35, 0.18, 0.5), 0.6)
	var body := Fx.sphere(body_radius, shell)
	body.scale = Vector3(1.0, 0.45, 1.5)
	body.position.y = body_radius * 0.5
	_visual.add_child(body)
	var head := Fx.sphere(body_radius * 0.55, shell)
	head.scale = Vector3(1.2, 0.55, 0.8)
	head.position = Vector3(0, body_radius * 0.5, -body_radius * 1.35)
	_visual.add_child(head)
	for sd: float in [-1.0, 1.0]:
		var arm := Fx.box(Vector3(0.1, 0.1, 0.7), shell)
		arm.position = Vector3(sd * 0.45, body_radius * 0.5, -body_radius * 1.6)
		arm.rotation.y = sd * 0.5
		_visual.add_child(arm)
		var claw := Fx.sphere(0.2, shell)
		claw.scale = Vector3(0.8, 0.6, 1.4)
		claw.position = Vector3(sd * 0.7, body_radius * 0.5, -body_radius * 2.3)
		claw.set_meta("claw", sd)
		_visual.add_child(claw)
		var rim := Fx.box(Vector3(0.03, 0.03, 0.4), edge)
		rim.position = claw.position + Vector3(0, 0.1, 0)
		_visual.add_child(rim)
		for k in 4:
			var leg := Fx.box(Vector3(0.7, 0.05, 0.05), shell)
			leg.position = Vector3(sd * body_radius * 1.05, body_radius * 0.25, -0.3 + k * 0.28)
			leg.rotation.z = sd * -0.35
			leg.set_meta("k", k + (4 if sd > 0.0 else 0))
			_visual.add_child(leg)
	# cauda: segmentos subindo em arco por cima das costas, com o ferrão no fim
	var prev := Vector3(0, body_radius * 0.6, body_radius * 1.3)
	for k in 5:
		var a := 0.5 + k * 0.42
		var pt := prev + Vector3(0, sin(a) * 0.32, cos(a) * 0.32)
		var seg := Fx.sphere(0.15 - k * 0.012, shell)
		seg.position = pt
		_visual.add_child(seg)
		prev = pt
	var sting_mat := Fx.mat(Color(1.0, 0.15, 0.1), 2.5)
	var sting := Fx.cylinder(0.07, 0.35, sting_mat)
	(sting.mesh as CylinderMesh).top_radius = 0.005
	sting.position = prev + Vector3(0, -0.05, -0.18)
	sting.rotation.x = -2.2
	sting.set_meta("sting", true)
	_visual.add_child(sting)
	var glow := OmniLight3D.new()   # o ferrão brilha: dá para ver o escorpião no escuro (de perto)
	glow.light_color = Color(1.0, 0.25, 0.15)
	glow.omni_range = 2.2
	glow.light_energy = 0.6
	glow.position = sting.position
	_visual.add_child(glow)


func _animate(_delta: float, speed_now: float) -> void:
	for n in _visual.get_children():
		if n.has_meta("k"):
			n.rotation.x = sin(_anim_t * 16.0 + int(n.get_meta("k")) * 1.3) * 0.4 * clampf(speed_now, 0.0, 1.0)
		elif n.has_meta("claw"):
			n.rotation.y = sin(_anim_t * 3.0) * 0.15 + (0.4 * float(n.get_meta("claw")) if telegraph else 0.0)
