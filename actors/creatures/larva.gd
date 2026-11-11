class_name Larva
extends Creature
## Larva-de-musgo (P): presa fácil. Foge quando sente o cheiro da jogadora ou ouve barulho,
## e também foge de predadores próximos.


func _init() -> void:
	display_name = "Larva-de-musgo"
	size = Size.P
	level = 1
	max_hp = 18.0
	speed = 2.6
	body_radius = 0.3
	body_color = Color(0.55, 0.68, 0.38)
	food_satiety = 30.0
	food_silk = 20.0
	food_xp = 15
	senses_text = "cheiro (5 m) e audição"
	model_name = "larva"
	model_size = 0.75
	model_fit = "length"


func _build_visual() -> void:
	for i in range(3):
		var seg := Fx.sphere(body_radius * (1.0 - i * 0.15), _mat)
		seg.position = Vector3(0.0, body_radius * 0.9, i * body_radius * 1.3)
		_visual.add_child(seg)


func _think(delta: float) -> Vector3:
	var threat: Node3D = null
	var p := GameState.player as Player
	if p != null and not p.dead:
		var smell := maxf(5.0, p.noise_radius())
		if flat_dist_to(p) < smell:
			threat = p
	if threat == null:
		for n in get_tree().get_nodes_in_group("predator"):
			var c := n as Creature
			if c != null and not c.dead and not c.is_in_group("lure") and flat_dist_to(c) < 4.0:
				threat = c
				break
	if threat != null:
		var away := global_position - threat.global_position
		away.y = 0.0
		var dir := safe_dir(away)
		if dir == Vector3.ZERO:
			dir = safe_dir(away.rotated(Vector3.UP, PI * 0.5))
		return dir * speed * 1.3
	# A isca do Lagarto-lanterna hipnotiza: a larva vai até a luz (e vira janta).
	for n in get_tree().get_nodes_in_group("lure"):
		var lz := n as Lizard
		if lz != null and not lz.dead and Fx.flat_dist(lz.lure_position(), global_position) < Lizard.LURE_PULL:
			return move_to(lz.lure_position(), 0.45)
	return wander(delta, 6.0, 0.4)


func _animate(_delta: float, speed_now: float) -> void:
	_visual.scale.z = 1.0 + sin(_anim_t * 12.0) * 0.08 * clampf(speed_now, 0.0, 1.0)
