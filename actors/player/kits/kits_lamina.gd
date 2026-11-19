extends RefCounted
## Ataques do ramo Lâmina: Ceifadora (ramo), Executora (Frenesi / Foices gêmeas) e
## Bastiã (Martelo / Muralha).


class Ceifadora extends AttackKit:
	## Ramo: dois cortes largos e o terceiro em linha; mordida com bote longo.
	func _init() -> void:
		names = ["Foice", "Bote longo"]
		descs = ["Dois cortes largos (120°) e o terceiro em linha reta, de 4 m.", "Bote de até 3,5 m que crava 50% mais forte."]

	func press(slot: int) -> void:
		if slot == 1:
			bite_move(3.5, bite_dmg() * 1.5)
			return
		if Time.get_ticks_msec() / 1000.0 - _combo_t > 0.45:
			_combo_i = 0
		var i := _combo_i
		_combo_i = (_combo_i + 1) % 3
		p._swing_blades(i)
		var reach := Player.ATTACK_RANGE * float(p.form_data()["scale"]) + 0.3
		var a := make(Attack.Shape.CONE, reach, {"arc": 120.0}) if i < 2 else make(Attack.Shape.LINE, 4.0, {"width": 1.0})
		start_move({"dur": 0.3 if i < 2 else 0.42, "hits": [0.1 if i < 2 else 0.18], "attack": a, "dmg": combo_dmg(i),
			"lunge": 3.0, "move": 1.2, "queue": true, "noise": 6.0,
			"on_fire": func(): if i == 2: flash_line(p.global_position, p.global_position + p.aim_dir * 4.0, Color(1.0, 0.4, 0.4)),
			"on_end": func(_ok): _combo_t = Time.get_ticks_msec() / 1000.0})


class Frenesi extends AttackKit:
	## Executora A: combo sem fim que acelera a cada acerto seguido; Degola em quem está ferido.
	var stack := 0
	var _idle := 0.0
	var _hit_any := false

	func _init() -> void:
		names = ["Frenesi", "Degola"]
		descs = ["Combo sem fim: cada acerto seguido deixa o próximo mais rápido e mais forte (até 5). Errar ou parar zera.",
			"Bote de até 5 m em bicho ferido (menos de metade da vida) ou preso: abaixo de 35% da vida, mata na hora."]

	func _tick(delta: float) -> void:
		if not busy():
			_idle += delta
			if _idle > 0.6:
				stack = 0

	func status_text() -> String:
		return "FRENESI %d" % stack if stack > 0 else ""

	func press(slot: int) -> void:
		if slot == 1:
			_degola()
			return
		_idle = 0.0
		_hit_any = false
		var dur := maxf(0.13, 0.3 * pow(0.85, stack))
		var reach := Player.ATTACK_RANGE * float(p.form_data()["scale"]) + 0.3
		p._swing_blades(stack % 2)
		start_move({"dur": dur, "hits": [dur * 0.4], "attack": make(Attack.Shape.CONE, reach, {"arc": 100.0}),
			"dmg": 18.0 + 4.0 * stack, "lunge": 3.0, "move": 1.4, "queue": true, "noise": 6.0,
			"on_hit": func(_c, _d): _hit_any = true,
			"on_end": func(_ok):
				stack = mini(stack + 1, 5) if _hit_any else 0
				_idle = 0.0})

	func _degola() -> void:
		var t := aim_target(5.0, 50.0, func(c): return c.is_entangled() or c.hp < c.max_hp * 0.5)
		if t == null:
			bite_move(2.6, bite_dmg())
			return
		var to := t.global_position - p.global_position
		to.y = 0.0
		var dist := maxf(0.0, to.length() - t.body_radius - 0.4)
		start_move({"dur": 0.42, "hits": [0.22], "attack": make(Attack.Shape.CONE, 1.6, {"arc": 70.0}), "dmg": 0.0,
			"dir": to.normalized(), "lunge": dist / 0.2, "lunge_until": 0.2, "move": 0.3, "noise": 4.0,
			"colors": [Color(1.0, 0.3, 0.3, 0.14), Color(1.0, 0.3, 0.3, 0.45)],
			"on_fire": func():
				if not is_instance_valid(t) or t.dead:
					return
				if t.hp < t.max_hp * 0.35 and not boss(t):
					p.hit_creature(t, t.hp + 1.0)
					p._msg("Degola!")
					p.shake(0.2)
				else:
					p.hit_creature(t, 30.0, true)})


class Foices extends AttackKit:
	## Executora B: segurar carrega um corte em linha que atravessa todos; Misericórdia no preso.
	var charging := false

	func _sounds() -> void:
		Sfx.loop_on(p, "kit_carga_loop", func(): return charging and busy())
	func _init() -> void:
		names = ["Foices gêmeas", "Misericórdia"]
		descs = ["Toque: corte rápido. Segurar: carrega um corte em linha (3 a 6 m) que atravessa todos, de 25 a 60.",
			"Pula num bicho preso e o segura no chão enquanto você segura a mordida (até 3 s), golpeando."]

	func press(slot: int) -> void:
		if slot == 1:
			_misericordia()
			return
		var a := make(Attack.Shape.LINE, 3.0, {"width": 1.2})
		charging = true
		start_move({"dur": 1.2, "hold": "attack", "attack": a, "move": 0.35, "noise": 3.0, "hits": [],
			"update": func(t, _dt):
				a.reach = 3.0 + 3.0 * clampf((t - 0.2) / 1.0, 0.0, 1.0)
				return Vector3.ZERO,
			"on_release": func(t):
				charging = false
				if t < 0.2:
					var reach := Player.ATTACK_RANGE * float(p.form_data()["scale"]) + 0.3
					p._swing_blades(0)
					start_move({"dur": 0.28, "hits": [0.1], "attack": make(Attack.Shape.CONE, reach, {"arc": 100.0}), "dmg": 18.0, "lunge": 3.0, "move": 1.4})
					return
				var k := clampf((t - 0.2) / 1.0, 0.0, 1.0)
				var line := make(Attack.Shape.LINE, 3.0 + 3.0 * k, {"width": 1.2})
				p._swing_blades(2)
				Sfx.play("kit_corte", p.global_position)
				var dir := p.aim_dir
				start_move({"dur": 0.35, "hits": [0.06], "attack": line, "dmg": 25.0 + 35.0 * k, "dir": dir, "lunge": 8.0, "lunge_until": 0.1, "move": 0.0,
					"on_fire": func():
						flash_line(p.global_position, p.global_position + dir * line.reach, Color(1.0, 0.25, 0.3), 0.3, 0.2)
						p.shake(0.15 + 0.2 * k)})})

	func _misericordia() -> void:
		var t := aim_target(4.0, 70.0, func(c): return c.is_entangled())
		if t == null:
			bite_move(2.6, bite_dmg())
			return
		var to := t.global_position - p.global_position
		to.y = 0.0
		var dist := maxf(0.0, to.length() - t.body_radius - 0.3)
		var state := {"next": 0.25, "end": 3.25}
		start_move({"dur": 3.3, "hold": "bite", "hits": [], "dir": to.normalized(), "lunge": dist / 0.22, "lunge_until": 0.22, "move": 0.0, "noise": 6.0,
			"update": func(time, _dt):
				if time < 0.22:
					p._visual.position.y = sin(PI * time / 0.22) * 0.6
					return Vector3.ZERO
				p._visual.position.y = 0.0
				if not is_instance_valid(t) or t.dead:
					end_now()
					return Vector3.ZERO
				if not boss(t):
					t.entangle_raw(0.5)
				if time >= float(state["next"]):
					state["next"] = time + 0.3
					p._swing_blades(int(time * 10.0) % 2)
					p.hit_creature(t, 10.0)
				return Vector3.ZERO,
			"on_release": func(_t): end_now()})


class Martelo extends AttackKit:
	## Bastiã A: pancada lenta que derruba e quebra a casca; investida de ombro.
	func _init() -> void:
		names = ["Martelo", "Investida de ombro"]
		descs = ["Pancada lenta num círculo à frente: 45 de dano, derruba (1,5 s) e quebra a casca (+40% de dano por 4 s).",
			"Corre 6 m em linha empurrando tudo (20); quem bate na parede leva +25 e fica tonto. 15 de energia."]

	func press(slot: int) -> void:
		if slot == 1:
			_ombro()
			return
		var point := p.global_position + p.aim_dir * 1.9
		start_move({"sfx": "", "dur": 0.85, "hits": [0.55], "attack": make(Attack.Shape.CIRCLE, 1.7, {"at_point": true}), "point": point,
			"dmg": 45.0, "move": 0.2, "noise": 10.0, "dodge_cancel": true,
			"on_hit": func(c, _d):
				c.corrode(4.0)
				if not boss(c):
					c.entangle_raw(1.5),
			"on_fire": func():
				flash_ring(point, 1.7, Color(0.9, 0.85, 0.7))
				Sfx.play("kit_martelo", point)
				p.shake(0.35)})

	func _ombro() -> void:
		if not ready_slot(1, "A investida ainda não voltou."):
			return
		if p.energy < 15.0:
			p._msg("Sem energia para a investida.")
			return
		p.energy -= 15.0
		p.energy_delay = 1.0
		cds[1] = 2.5
		var dir := p.aim_dir
		var pushed: Array = []
		start_move({"dur": 0.6, "hits": [], "attack": make(Attack.Shape.LINE, 6.0, {"width": 1.4}), "dir": dir, "lunge": 15.0, "lunge_until": 0.4,
			"move": 0.0, "noise": 12.0,
			"update": func(time, _dt):
				if time < 0.4:
					for c in creatures_near(p.global_position + dir * 0.6, 1.2):
						if not pushed.has(c):
							pushed.append(c)
							p.hit_creature(c, 20.0)
					for c in pushed:
						if is_instance_valid(c) and not c.dead and not big(c):
							c.external_velocity = dir * 15.0
				return Vector3.ZERO,
			"on_end": func(_ok):
				var space := p.get_world_3d().direct_space_state
				for c in pushed:
					if not is_instance_valid(c) or c.dead:
						continue
					var from: Vector3 = c.global_position + Vector3.UP * 0.5
					var q := PhysicsRayQueryParameters3D.create(from, from + dir * (c.body_radius + 1.0), 1)
					if not space.intersect_ray(q).is_empty():
						p.hit_creature(c, 25.0)
						if not boss(c):
							c.entangle_raw(1.2)
						p._msg("Contra a parede!")
						p.shake(0.3)})


class Muralha extends AttackKit:
	## Bastiã B: guarda que bloqueia de frente e contra-ataca; pisão que derruba em volta.
	var guarding := false
	var _guard_dir := Vector3.FORWARD

	func _init() -> void:
		names = ["Muralha", "Pisão"]
		descs = ["Segurar: guarda que bloqueia tudo de frente (120°) e devolve 20 + atordoa quem bateu; gasta energia. Toque: empurrão de escudo.",
			"Bate as patas: onda de 4 m em volta, 18 de dano e derruba (1,2 s), até quem voa."]

	func status_text() -> String:
		return "GUARDA" if guarding else ""

	func press(slot: int) -> void:
		if slot == 1:
			_pisao()
			return
		guarding = true
		start_move({"dur": 30.0, "hold": "attack", "hits": [], "attack": make(Attack.Shape.CONE, 1.6, {"arc": 120.0}), "move": 0.3, "noise": 1.0,
			"colors": [Color(0.9, 0.85, 0.6, 0.18), Color(0.9, 0.85, 0.6, 0.3)],
			"update": func(time, dt):
				_m["dir"] = p.aim_dir
				_guard_dir = p.aim_dir
				if time > 0.2:
					p.energy = maxf(0.0, p.energy - 8.0 * dt)
					p.energy_delay = 0.8
					if p.energy <= 0.0:
						p._msg("Sem energia: a guarda caiu.")
						end_now()
				return Vector3.ZERO,
			"on_release": func(t):
				guarding = false
				if t < 0.2:
					var reach := 1.9
					start_move({"dur": 0.3, "hits": [0.1], "attack": make(Attack.Shape.CONE, reach, {"arc": 90.0}), "dmg": 16.0, "lunge": 4.0, "move": 0.8,
						"on_hit": func(c, _d): if not big(c): c.external_velocity = p.aim_dir * 9.0})
				else:
					end_now(),
			"on_end": func(_ok): guarding = false})

	func on_hurt(amount: float, source: Node3D) -> float:
		if not guarding or source == null or not is_instance_valid(source):
			return amount
		var to := source.global_position - p.global_position
		to.y = 0.0
		if to.length() > 0.2 and rad_to_deg(_guard_dir.angle_to(to.normalized())) > 60.0:
			return amount
		p.energy = maxf(0.0, p.energy - 5.0)
		flash_ring(p.global_position + _guard_dir * 0.8, 0.6, Color(1.0, 0.9, 0.6), 0.2)
		p._msg("Bloqueou!")
		if source is Creature and to.length() < 3.5 + (source as Creature).body_radius:
			var c := source as Creature
			p.hit_creature(c, 20.0)
			if not boss(c):
				c.entangle_raw(0.8)
		Sfx.play("kit_guarda", p.global_position)
		return 0.0

	func _pisao() -> void:
		if not ready_slot(1, "O pisão ainda não voltou."):
			return
		cds[1] = 3.0
		start_move({"sfx": "", "dur": 0.6, "hits": [0.35], "attack": make(Attack.Shape.RING, 4.0), "dmg": 0.0, "move": 0.0, "noise": 12.0,
			"on_fire": func():
				for c in targets(make(Attack.Shape.RING, 4.0), p.global_position, p.aim_dir, p.global_position, 4.0):
					p.hit_creature(c, 18.0)
					if not boss(c):
						c.entangle_raw(1.2)
				flash_ring(p.global_position, 4.0, Color(0.9, 0.8, 0.6), 0.3)
				Sfx.play("kit_onda", p.global_position)
				p.shake(0.4)})
