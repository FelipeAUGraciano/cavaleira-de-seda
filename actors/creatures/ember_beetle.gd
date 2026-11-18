class_name EmberBeetle
extends Beetle
## Besouro-brasa (P, bandos): casco que brilha como carvão aceso. Pasta o musgo-de-cinza
## perto dos fungos e foge de você. A comida fácil do Rio de Brasa.


func _init() -> void:
	display_name = "Besouro-brasa"
	level = 4
	max_hp = 16.0
	speed = 3.3
	body_color = Color(0.25, 0.08, 0.04)
	food_satiety = 26.0
	food_silk = 16.0
	food_xp = 16
	fire_immune = true
	senses_text = "calor e vibração (5 m)"


func find_food() -> Variant:
	var best: Variant = null
	var best_d := 16.0
	for q: Vector3 in World.graze_spots:
		var d := Fx.flat_dist(global_position, q)
		if d < best_d:
			best_d = d
			best = q
	return best


func _build_visual() -> void:
	super._build_visual()
	var glow := Fx.mat(Color(1.0, 0.4, 0.1), 2.2, true)
	for k in 3:
		var crack := Fx.box(Vector3(0.03, 0.02, 0.32), glow)
		crack.position = Vector3(-0.08 + k * 0.08, body_radius * 1.05, 0.0)
		_visual.add_child(crack)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.15)
	l.omni_range = 1.8
	l.light_energy = 0.5
	l.position.y = 0.5
	_visual.add_child(l)
