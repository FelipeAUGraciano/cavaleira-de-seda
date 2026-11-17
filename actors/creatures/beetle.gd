class_name Beetle
extends Creature
## Besouro carniceiro (P, bandos de 3 a 5): vive no Ossário do Abismo roendo carcaças velhas.
## Foge de você e de qualquer coisa maior; é a primeira comida fácil lá embaixo.
## Sentidos: cheiro (5 m) e vibração. Carapaça escura com um brilho de óleo.


func _init() -> void:
	display_name = "Besouro carniceiro"
	size = Size.P
	level = 2
	max_hp = 12.0
	speed = 3.1
	body_radius = 0.26
	body_color = Color(0.16, 0.13, 0.2)
	food_satiety = 22.0
	food_silk = 14.0
	food_xp = 10
	senses_text = "cheiro (5 m) e vibração"
	fears_player = true
	fear_radius = 5.0
	rest_phase = CaveClock.Phase.BRILHO
	hunger_threshold = 30.0
	sleep_heal = 0.03
	needs.hunger_rate = 0.6


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Flee.new()) \
		.add(Behaviors.Forage.new()) \
		.add(Behaviors.Sleep.new()) \
		.add(Behaviors.Wander.new(5.0, 0.35))


func _build_visual() -> void:
	var shell := Fx.mat(body_color, 0.0)
	shell.metallic = 0.6
	shell.roughness = 0.25
	var body := Fx.sphere(body_radius, shell)
	body.scale = Vector3(1.0, 0.6, 1.35)
	body.position.y = body_radius * 0.6
	_visual.add_child(body)
	var head := Fx.sphere(body_radius * 0.45, Fx.mat(body_color.darkened(0.3)))
	head.position = Vector3(0.0, body_radius * 0.55, -body_radius * 1.25)
	_visual.add_child(head)
	var seam := Fx.box(Vector3(0.015, 0.02, body_radius * 2.4), Fx.mat(Color(0.5, 0.75, 0.6), 0.6))
	seam.position = Vector3(0.0, body_radius * 1.15, 0.05)
	_visual.add_child(seam)
	var leg_mat := Fx.mat(body_color.darkened(0.5))
	for side: float in [-1.0, 1.0]:
		for k in 3:
			var leg := Fx.box(Vector3(body_radius * 1.3, 0.025, 0.025), leg_mat)
			leg.position = Vector3(side * body_radius * 0.95, body_radius * 0.3, (k - 1) * body_radius * 0.7)
			leg.set_meta("k", k)
			_visual.add_child(leg)


func _animate(_delta: float, speed_now: float) -> void:
	for n in _visual.get_children():
		if n.has_meta("k"):
			n.rotation.x = sin(_anim_t * 24.0 + int(n.get_meta("k")) * 2.0) * 0.45 * clampf(speed_now, 0.0, 1.0)


func find_food() -> Variant:
	## Rói as carcaças velhas do Ossário (sem acabar com elas).
	var best: Node3D = null
	var best_d := 18.0
	for n in get_tree().get_nodes_in_group("carcass"):
		var d := Fx.flat_dist(global_position, (n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n
	if best == null:
		return null
	return best.global_position
