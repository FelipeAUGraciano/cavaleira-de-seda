extends RefCounted
## Ataques do ramo Runa: Arauta (ramo), Vidente (Ponto fraco / Antecipação) e
## Sacerdotisa da Tempestade (Raio / Campo elétrico).

const RUNE_COL := Color(0.55, 0.9, 1.0)
const BOLT_COL := Color(0.6, 0.75, 1.0)


class Arauta extends AttackKit:
	## Ramo: faísca da runa à distância; lampejo que atordoa em cone.
	func _init() -> void:
		names = ["Faísca", "Lampejo"]
		descs = ["Faísca da runa em linha (6 m) no primeiro bicho; 5 de energia. Sem energia, vira uma garrada comum.",
			"Clarão em cone (4 m) que atordoa por 1 s. 10 de energia."]

	func press(slot: int) -> void:
		if slot == 0:
			if p.energy < 5.0:
				combo_swing(p.form_data()["combo"])
				return
			p.energy -= 5.0
			p.energy_delay = 0.8
			var to := _first_on_line(6.0)
			var end: Vector3 = to.global_position if to != null else p.global_position + p.aim_dir * 6.0
			flash_line(p.global_position, end, RUNE_COL, 0.15, 0.06)
			if to != null:
				p.hit_creature(to, combo_dmg(0) + 4.0)
			start_move({"dur": 0.25, "hits": [], "move": 1.0, "queue": true, "noise": 2.0})
			return
		if not ready_slot(1):
			return
		if p.energy < 10.0:
			p._msg("Sem energia para o lampejo.")
			return
		p.energy -= 10.0
		p.energy_delay = 1.0
		cds[1] = 3.0
		start_move({"dur": 0.4, "hits": [0.15], "attack": make(Attack.Shape.CONE, 4.0, {"arc": 70.0}), "dmg": 0.0, "move": 0.5, "noise": 3.0,
			"on_fire": func():
				for c in targets(make(Attack.Shape.CONE, 4.0, {"arc": 70.0}), p.global_position, p.aim_dir, p.global_position):
					if not boss(c):
						c.entangle_raw(1.0)
				flash_ring(p.global_position + p.aim_dir * 2.0, 1.2, RUNE_COL, 0.2)})

	func _first_on_line(length: float) -> Creature:
		var best: Creature = null
		var bd := length
		for c in targets(make(Attack.Shape.LINE, length, {"width": 0.8}), p.global_position, p.aim_dir, p.global_position):
			var d := Fx.flat_dist(c.global_position, p.global_position)
			if d < bd:
				bd = d
				best = c
		return best


class PontoFraco extends AttackKit:
	## Vidente A: golpe preciso no ponto fraco (3x e atordoa); Leitura marca um bicho.
	var weak := {}          ## bicho -> ângulo do ponto fraco (em relação ao rosto dele)
	var _rot := 0.0
	var marked: Creature = null
	var marked_t := 0.0
	var _dots: Array = []
	var _mark_ring: MeshInstance3D

	func _init() -> void:
		names = ["Ponto fraco", "Leitura"]
		descs = ["Um golpe só, lento e preciso (cone estreito). Pelo lado do ponto fraco marcado no bicho (muda a cada 3 s): 3x e atordoa.",
			"Marca um bicho na mira (10 m) por 10 s: todo golpe seu nele é crítico e os dele em você doem a metade. 15 de energia."]

	func _tick(delta: float) -> void:
		_rot -= delta
		if _rot <= 0.0:
			_rot = 3.0
			for c in creatures_near(p.global_position, 8.0):
				weak[c] = [0.0, PI * 0.5, PI, PI * 1.5][randi() % 4]
		if marked != null and (not is_instance_valid(marked) or marked.dead):
			marked = null
		marked_t -= delta
		if marked_t <= 0.0:
			marked = null
		_draw_dots()

	func _weak_dir(c: Creature) -> Vector3:
		return c.facing.rotated(Vector3.UP, float(weak.get(c, PI)))

	func _draw_dots() -> void:
		var near := creatures_near(p.global_position, 6.0)
		while _dots.size() < 6:
			var d := Fx.sphere(0.13, Fx.mat(Color(1.0, 0.85, 0.3), 4.0, true))
			d.top_level = true
			add_child(d)
			_dots.append(d)
		for i in _dots.size():
			var dot: MeshInstance3D = _dots[i]
			dot.visible = i < near.size() and weak.has(near[i])
			if dot.visible:
				var c: Creature = near[i]
				dot.global_position = c.global_position + _weak_dir(c) * (c.body_radius + 0.15) + Vector3.UP * 0.6
		if _mark_ring == null:
			_mark_ring = MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.5
			tm.outer_radius = 0.6
			_mark_ring.mesh = tm
			var mat := Fx.mat(Color(1.0, 0.85, 0.3), 3.0, true, 0.8)
			mat.no_depth_test = true
			_mark_ring.material_override = mat
			_mark_ring.top_level = true
			add_child(_mark_ring)
		_mark_ring.visible = marked != null
		if marked != null:
			_mark_ring.global_position = marked.global_position + Vector3.UP * (1.2 + marked.body_radius)

	func press(slot: int) -> void:
		if slot == 0:
			var a := make(Attack.Shape.CONE, 2.4, {"arc": 40.0})
			start_move({"dur": 0.55, "hits": [0.35], "attack": a, "dmg": 0.0, "move": 0.4, "noise": 3.0,
				"on_fire": func():
					for c in targets(a, p.global_position, p.aim_dir, p.global_position):
						var from_c: Vector3 = p.global_position - c.global_position
						from_c.y = 0.0
						var hit_weak: bool = weak.has(c) and from_c.length() > 0.1 and _weak_dir(c).angle_to(from_c.normalized()) < deg_to_rad(55.0)
						p.hit_creature(c, 16.0 * (3.0 if hit_weak else 1.0))
						if hit_weak and not c.dead:
							if not boss(c):
								c.entangle_raw(1.2)
							p._msg("Ponto fraco!")
							weak[c] = fposmod(float(weak[c]) + PI, TAU)})
			return
		if not ready_slot(1, "A Leitura ainda não voltou."):
			return
		if p.energy < 15.0:
			p._msg("Sem energia para a Leitura.")
			return
		var t := aim_target(10.0, 40.0)
		if t == null:
			p._msg("Nenhum bicho na mira.")
			return
		p.energy -= 15.0
		p.energy_delay = 1.0
		cds[1] = 12.0
		marked = t
		marked_t = 10.0
		p._msg("Leitura: %s." % t.display_name)
		flash_line(p.global_position, t.global_position, Color(1.0, 0.85, 0.3), 0.3, 0.05)

	func modify_hit(c: Creature, dmg: float) -> float:
		if c == marked and not c.is_entangled():
			return dmg * 2.0
		return dmg

	func on_hurt(amount: float, source: Node3D) -> float:
		if marked != null and source == marked:
			return amount * 0.5
		return amount


class Antecipacao extends AttackKit:
	## Vidente B: aparar logo antes do golpe e devolver forte; Olhar da runa assusta.
	var window := false

	func _init() -> void:
		names = ["Antecipação", "Olhar da runa"]
		descs = ["Abre uma janela curta (0,3 s): se um bicho te acertar nela, você desvia e devolve 30 e atordoa. Se ninguém vier, vira uma garrada fraca.",
			"Encara (cone de 8 m): os bichos fogem de medo por 4 s; chefes só hesitam. 20 de energia."]

	func press(slot: int) -> void:
		if slot == 0:
			window = true
			start_move({"dur": 0.5, "hits": [0.35], "attack": make(Attack.Shape.CONE, 1.8, {"arc": 80.0}), "dmg": 10.0, "move": 0.3, "noise": 2.0,
				"colors": [Color(1.0, 0.9, 0.5, 0.14), Color(1.0, 0.9, 0.5, 0.4)],
				"update": func(time, _dt):
					window = time < 0.3
					return Vector3.ZERO,
				"on_end": func(_ok): window = false})
			return
		if not ready_slot(1, "O Olhar ainda não voltou."):
			return
		if p.energy < 20.0:
			p._msg("Sem energia para o Olhar.")
			return
		p.energy -= 20.0
		p.energy_delay = 1.0
		cds[1] = 10.0
		var a := make(Attack.Shape.CONE, 8.0, {"arc": 60.0})
		var n := 0
		for c in targets(a, p.global_position, p.aim_dir, p.global_position, 3.0):
			if boss(c):
				c.entangle_raw(0.5)
			else:
				c.scare(4.0, p.global_position)
			n += 1
		marker.draw_shape(a, p.global_position, p.aim_dir, p.global_position, 1.0, Color(1.0, 0.9, 0.5, 0.1), Color(1.0, 0.9, 0.5, 0.25))
		_mt = -1.0
		get_tree().create_timer(0.3).timeout.connect(marker.clear)
		p._msg("Olhar da runa: %d com medo." % n if n > 0 else "Ninguém na mira do Olhar.")

	func on_hurt(amount: float, source: Node3D) -> float:
		if not window or not (source is Creature):
			return amount
		var c := source as Creature
		window = false
		p.invuln = 0.4
		p.hit_creature(c, 30.0)
		c.entangle_raw(1.5 if not boss(c) else 0.5)
		flash_ring(p.global_position, 1.0, Color(1.0, 0.9, 0.5), 0.2)
		p._msg("Antecipou!")
		p.shake(0.2)
		end_now()
		return 0.0


class Raio extends AttackKit:
	## Tempestade A: raio que pula para um segundo bicho; descarga com toda a energia.
	func _init() -> void:
		names = ["Raio", "Descarga"]
		descs = ["Raio em linha (8 m): 18 no primeiro bicho e pula para outro perto (10). 8 de energia.",
			"Crava e solta toda a energia de uma vez: 10 + 40% da energia gasta, e atordoa 2 s."]

	func press(slot: int) -> void:
		if slot == 0:
			if p.energy < 8.0:
				combo_swing([8.0, 8.0, 12.0])
				return
			p.energy -= 8.0
			p.energy_delay = 0.8
			var first: Creature = null
			var bd := 8.0
			for c in targets(make(Attack.Shape.LINE, 8.0, {"width": 0.9}), p.global_position, p.aim_dir, p.global_position):
				var d := Fx.flat_dist(c.global_position, p.global_position)
				if d < bd:
					bd = d
					first = c
			var end: Vector3 = first.global_position if first != null else p.global_position + p.aim_dir * 8.0
			_zig(p.global_position, end)
			if first != null:
				p.hit_creature(first, 18.0)
				first.entangle_raw(0.3)
				var second: Creature = null
				var sd := 5.0
				for c in creatures_near(first.global_position, 5.0):
					if c != first and Fx.flat_dist(c.global_position, first.global_position) < sd:
						sd = Fx.flat_dist(c.global_position, first.global_position)
						second = c
				if second != null:
					_zig(first.global_position, second.global_position)
					p.hit_creature(second, 10.0)
			start_move({"dur": 0.3, "hits": [], "move": 0.8, "queue": true, "noise": 6.0})
			return
		if p.energy < 10.0:
			bite_move(2.6, bite_dmg())
			return
		bite_move(2.6, 0.0, {"on_fire": func():
			var t := aim_target(2.2, 100.0)
			if t == null:
				return
			var spent := p.energy
			p.energy = 0.0
			p.energy_delay = 1.5
			p.hit_creature(t, 10.0 + spent * 0.4)
			if not t.dead and not boss(t):
				t.entangle_raw(2.0)
			_zig(p.global_position, t.global_position)
			p._msg("Descarga! (%d de energia)" % int(spent))})

	func _zig(a: Vector3, b: Vector3) -> void:
		var pts := [a]
		for k in range(1, 4):
			var q := a.lerp(b, k / 4.0)
			pts.append(q + Vector3(randf_range(-0.35, 0.35), 0, randf_range(-0.35, 0.35)))
		pts.append(b)
		for i in pts.size() - 1:
			flash_line(pts[i], pts[i + 1], BOLT_COL, 0.15, 0.07)


class Campo extends AttackKit:
	## Tempestade B: orbe que gira em volta e dá choque; trovão que corre pelos seus fios.
	var orb_on := false
	var _orb: MeshInstance3D
	var _zap := 0.0
	var _ang := 0.0

	func _init() -> void:
		names = ["Campo elétrico", "Trovão nos fios"]
		descs = ["Liga/desliga um orbe que gira em volta de você e dá choque (8, atordoa um instante) em quem chegar a 2,4 m. Gasta 6 de energia por segundo.",
			"Um choque corre por todos os seus fios (15 m): quem estiver neles ou perto leva 20 e fica tonto 1,5 s. 25 de energia."]

	func status_text() -> String:
		return "CAMPO" if orb_on else ""

	func press(slot: int) -> void:
		if slot == 0:
			orb_on = not orb_on and p.energy > 5.0
			p._msg("Campo elétrico ligado." if orb_on else "Campo elétrico desligado.")
			start_move({"dur": 0.2, "hits": [], "move": 1.0})
			return
		if not ready_slot(1, "O trovão ainda não voltou."):
			return
		if p.energy < 25.0:
			p._msg("Sem energia para o trovão.")
			return
		var lines: Array = []
		for s in WebNetwork.strands:
			if is_instance_valid(s) and (s as WebStrand).distance_to(p.global_position) < 15.0:
				lines.append(s)
		if lines.is_empty():
			p._msg("Nenhum fio seu por perto.")
			return
		p.energy -= 25.0
		p.energy_delay = 1.0
		cds[1] = 6.0
		var n := 0
		for s in lines:
			var ws := s as WebStrand
			flash_line(ws.a_pos, ws.b_pos, BOLT_COL, 0.3, 0.09)
			for c in World.creatures:
				if is_instance_valid(c) and not c.dead and Fx.seg_dist_flat(c.global_position, ws.a_pos, ws.b_pos) < 1.3 + c.body_radius and c.get_meta("_trovao", -1) != Engine.get_physics_frames():
					c.set_meta("_trovao", Engine.get_physics_frames())
					p.hit_creature(c, 20.0)
					if not boss(c):
						c.entangle_raw(1.5)
					n += 1
		p._msg("Trovão nos fios! (%d)" % n)
		start_move({"dur": 0.35, "hits": [], "move": 0.3})

	func _tick(delta: float) -> void:
		if _orb == null:
			_orb = Fx.sphere(0.2, Fx.mat(BOLT_COL, 5.0, true))
			_orb.top_level = true
			add_child(_orb)
		_orb.visible = orb_on
		if not orb_on:
			return
		_ang += delta * 6.0
		_orb.global_position = p.global_position + Vector3(cos(_ang), 0.8, sin(_ang)) * Vector3(1.8, 1.0, 1.8)
		p.energy = maxf(0.0, p.energy - 6.0 * delta)
		p.energy_delay = 0.5
		if p.energy <= 0.0:
			orb_on = false
			p._msg("Sem energia: o campo apagou.")
			return
		_zap -= delta
		if _zap <= 0.0:
			_zap = 0.5
			for c in creatures_near(p.global_position, 2.4):
				flash_line(_orb.global_position - Vector3.UP * 0.4, c.global_position, BOLT_COL, 0.1, 0.04)
				p.hit_creature(c, 8.0)
				if not boss(c) and not c.dead:
					c.entangle_raw(0.3)
