class_name FireSalamander
extends Creature
## Salamandra-chama (M, em pares): lagarto de pele vermelha rachada, com brasas nas costas.
## Territorial: ataca quem chega perto do ninho. Sopro de fogo em linha (queima os fios no
## caminho e deixa você queimando), mordida e, furiosa, chicote de cauda.
## Comer a carne sobe a Resistência a Fogo.

const BITE := 16.0


func _init() -> void:
	display_name = "Salamandra-chama"
	size = Size.M
	level = 9
	max_hp = 75.0
	speed = 3.6
	body_radius = 0.5
	body_color = Color(0.55, 0.12, 0.06)
	food_satiety = 45.0
	food_silk = 26.0
	food_xp = 70
	food_fire = 1
	senses_text = "calor e visão (8 m); vê melhor quem está com a runa acesa"
	sight_range = 8.0
	sight_fov = 140.0
	aggression = 0.9
	track_range = 14.0
	memory_time = 5.0
	leash_range = 20.0
	attack_damage = BITE
	attack_reach = 1.4
	hunger_threshold = 40.0
	needs.hunger_rate = 0.8
	combat_label = "Defendendo o ninho"
	add_attack(Attack.make("mordida", "Mordida", {"max_range": 2.0, "windup": 0.4, "active": 0.16, "recover": 0.5,
		"cooldown": 1.4, "damage": BITE, "reach": 1.8, "arc": 90.0, "lunge": 3.0, "weight": 3.0}))
	add_attack(Attack.make("sopro", "Sopro de fogo", {"min_range": 2.0, "max_range": 6.5, "windup": 0.75, "active": 0.35,
		"recover": 0.8, "cooldown": 4.0, "damage": 14.0, "shape": Attack.Shape.LINE, "reach": 6.5, "width": 1.3,
		"knockback": false, "effect": "burn", "effect_power": 3.0, "weight": 2.5}))
	add_attack(Attack.make("cauda", "Chicote de cauda", {"max_range": 2.6, "windup": 0.45, "active": 0.2, "recover": 0.6,
		"cooldown": 4.5, "damage": 18.0, "shape": Attack.Shape.RING, "reach": 2.6, "only_enraged": true, "flank": true, "weight": 2.0}))


func _ready() -> void:
	super._ready()
	add_to_group("predator")


func notices_player(p: Player) -> bool:
	var d := flat_dist_to(p)
	if d < body_radius + 1.2 or d < p.noise_radius() * 0.8:
		return true
	return can_see(p, sight_range * (1.3 if p.rune_on else 1.0) * maxf(p.visibility_mult(), 0.5), sight_fov)


func is_prey(o: Creature) -> bool:
	return int(o.size) < int(Size.M) and not (o is Bat)


func on_attack_active(a: Attack) -> void:
	if a.id == "sopro":
		burn_strands(global_position, facing, a.reach, a.width * 0.5 + 0.3)


func burn_strands(from: Vector3, dir: Vector3, reach: float, half_w: float) -> void:
	## O fogo queima fios e teias no caminho.
	var to := from + dir * reach
	for s in WebNetwork.strands.duplicate():
		if is_instance_valid(s):
			for k in 6:
				var q: Vector3 = (s as WebStrand).a_pos.lerp((s as WebStrand).b_pos, k / 5.0)
				if Fx.seg_dist_flat(q, from, to) < half_w:
					WebNetwork.remove_strand(s)
					break
	for t in WebNetwork.traps.duplicate():
		if is_instance_valid(t) and Fx.seg_dist_flat(t.global_position, from, to) < half_w + 1.0:
			WebNetwork.remove_trap(t)
	_fire_fx(from, to)


func _fire_fx(from: Vector3, to: Vector3) -> void:
	if not near_player:
		return
	var m := Fx.mat(Color(1.0, 0.5, 0.1), 3.0, true, 0.7)
	for k in 6:
		var f := Fx.sphere(0.3 + k * 0.06, m)
		get_parent().add_child(f)
		f.global_position = from.lerp(to, k / 5.0) + Vector3(0, 0.5, 0)
		var tw := f.create_tween()
		tw.tween_property(f, "scale", Vector3.ONE * 1.8, 0.4)
		tw.tween_callback(f.queue_free)


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Defendendo o ninho")) \
		.add(Behaviors.Flee.new()) \
		.add(Behaviors.Stalk.new()) \
		.add(Behaviors.Forage.new()) \
		.add(Behaviors.Sleep.new()) \
		.add(Behaviors.Wander.new(5.0, 0.3))


func _build_visual() -> void:
	var skin := _mat
	var body := Fx.sphere(body_radius, skin)
	body.scale = Vector3(0.9, 0.5, 1.8)
	body.position.y = body_radius * 0.55
	_visual.add_child(body)
	var head := Fx.sphere(body_radius * 0.6, skin)
	head.scale = Vector3(1.0, 0.6, 1.4)
	head.position = Vector3(0, body_radius * 0.6, -body_radius * 1.6)
	_visual.add_child(head)
	var ember := Fx.mat(Color(1.0, 0.55, 0.1), 2.5, true)
	for k in 5:
		var e := Fx.sphere(0.08, ember)
		e.position = Vector3(sin(k * 1.7) * 0.12, body_radius * 0.85, -0.5 + k * 0.25)
		_visual.add_child(e)
	for sd: float in [-1.0, 1.0]:
		var eye := Fx.sphere(0.06, Fx.mat(Color(1.0, 0.9, 0.3), 2.0, true))
		eye.position = Vector3(sd * 0.18, body_radius * 0.8, -body_radius * 2.0)
		_visual.add_child(eye)
		for k in 2:
			var leg := Fx.box(Vector3(0.45, 0.08, 0.1), skin)
			leg.position = Vector3(sd * body_radius * 0.9, 0.12, -0.35 + k * 0.7)
			leg.set_meta("leg", k + (2 if sd > 0.0 else 0))
			_visual.add_child(leg)
	var prev := Vector3(0, body_radius * 0.5, body_radius * 1.7)
	for k in 5:
		var t := Fx.sphere(0.16 - k * 0.025, skin)
		t.position = prev + Vector3(0, -0.03, 0.28)
		prev = t.position
		t.set_meta("tail", k)
		_visual.add_child(t)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.15)
	l.omni_range = 3.5
	l.light_energy = 0.8
	l.position.y = 1.0
	_visual.add_child(l)


func _animate(_delta: float, speed_now: float) -> void:
	for n in _visual.get_children():
		if n.has_meta("leg"):
			n.rotation.y = sin(_anim_t * 10.0 + int(n.get_meta("leg")) * PI * 0.5) * 0.5 * clampf(speed_now, 0.0, 1.0)
		elif n.has_meta("tail"):
			n.position.x = sin(_anim_t * 3.0 - int(n.get_meta("tail")) * 0.6) * 0.08 * int(n.get_meta("tail"))
