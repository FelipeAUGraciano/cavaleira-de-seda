extends RefCounted
## Ataques do ramo Teia: Tecelã (ramo), Senhora das Teias (Tecelã de guerra / Rede viva) e
## Saltadora do Vento (Pêndulo / Ricochete).

const SILK_COL := Color(0.92, 0.95, 1.0)


class Tecela extends AttackKit:
	## Ramo: chicote de seda de 4 m (o 3º acerto no mesmo bicho deixa lento); novelo grudento.
	func _init() -> void:
		names = ["Chicote de seda", "Novelo"]
		descs = ["Chicote em linha de 4 m; a cada 3 acertos no mesmo bicho, ele fica lento por 2 s.", "Atira um novelo (7 m) que gruda: o bicho fica lento por 2,5 s. 5 de seda."]

	func press(slot: int) -> void:
		if slot == 0:
			start_move({"dur": 0.32, "hits": [0.12], "attack": make(Attack.Shape.LINE, 4.0, {"width": 0.7}), "dmg": combo_dmg(0) + 2.0,
				"move": 1.0, "queue": true, "noise": 4.0,
				"on_hit": func(c, _d):
					if add_stack(c, 1) % 3 == 0:
						c.slow(0.5, 2.0),
				"on_fire": func(): flash_line(p.global_position, p.global_position + p.aim_dir * 4.0, SILK_COL, 0.15, 0.05)})
			return
		if p.silk < 5.0:
			p._msg("Seda insuficiente para o novelo.")
			return
		if not ready_slot(1):
			return
		cds[1] = 0.8
		p.silk -= 5.0
		var to := p.global_position + p.aim_dir * 7.0
		shoot(p.global_position + Vector3.UP * 0.5, to + Vector3.UP * 0.5, 18.0, 0.5, SILK_COL, func(c):
			p.hit_creature(c, 3.0)
			c.slow(0.4, 2.5))
		start_move({"dur": 0.25, "hits": [], "move": 1.0})


class Guerra extends AttackKit:
	## Senhora A: chicote de 5 m que cola (3 acertos = preso); casulo rápido no preso.
	func _init() -> void:
		names = ["Chicote de guerra", "Casulo rápido"]
		descs = ["Chicote em linha de 5 m: cada acerto cola seda; 3 no mesmo bicho e ele fica preso (grandes só ficam lentos).",
			"Morde um bicho preso (pequeno ou médio) e embrulha na hora: o pequeno vai para a bolsa, o médio fica embrulhado no chão."]

	func press(slot: int) -> void:
		if slot == 0:
			start_move({"dur": 0.3, "hits": [0.11], "attack": make(Attack.Shape.LINE, 5.0, {"width": 0.8}), "dmg": 10.0, "move": 1.0, "queue": true, "noise": 4.0,
				"on_hit": func(c, _d):
					if c.dead:
						return
					if add_stack(c, 1) >= 3:
						c.set_meta("seda", 0)
						if c.entangle(2.5) <= 0.0:
							c.slow(0.4, 2.0)
						p._msg("Colou! %s está preso." % c.display_name),
				"on_fire": func(): flash_line(p.global_position, p.global_position + p.aim_dir * 5.0, SILK_COL, 0.15, 0.06)})
			return
		var t := aim_target(2.6, 80.0, func(c): return c.is_entangled() and int(c.size) <= int(Creature.Size.M) and not boss(c))
		if t == null:
			bite_move(2.6, bite_dmg())
			return
		var at := t.global_position
		bite_move(2.6, 0.0, {"on_fire": func():
			if not is_instance_valid(t) or t.dead:
				return
			t.take_damage(t.hp + 1.0, p)
			_wrap_corpse_near.call_deferred(at)})

	func _wrap_corpse_near(at: Vector3) -> void:
		var best: Corpse = null
		var bd := 2.5
		for k in World.corpses:
			if is_instance_valid(k) and Fx.flat_dist(k.global_position, at) < bd:
				best = k
				bd = Fx.flat_dist(k.global_position, at)
		if best == null:
			return
		if not best.big and p.bag.size() < Player.BAG_MAX and not best.is_rotten():
			p.silk += Player.SILK_WRAP   # o casulo rápido não gasta seda
			p.wrap_into_bag(best)
		else:
			best.preserved = true
			p._msg("Embrulhou %s no chão (não estraga)." % best.display_name)


class Rede extends AttackKit:
	## Senhora B: atira novelos que viram teias de captura onde caem; puxa todos os presos.
	const MAX_NETS := 3
	var nets: Array = []

	func _init() -> void:
		names = ["Rede viva", "Puxar a rede"]
		descs = ["Atira um novelo (até 7 m) que vira uma teia de captura pequena onde cair, sem pilar (dura 20 s, até 3). 12 de seda.",
			"Puxa até você todos os bichos presos por perto (12 m); grandes só perdem o passo. 8 de seda."]

	func press(slot: int) -> void:
		if slot == 0:
			if p.silk < 12.0:
				p._msg("Seda insuficiente para a rede.")
				return
			if not ready_slot(0):
				return
			cds[0] = 0.6
			p.silk -= 12.0
			var to := floor_point(p.global_position, p.global_position + p.aim_dir * minf(7.0, maxf(2.0, Fx.flat_dist(p.aim_point, p.global_position))))
			shoot(p.global_position + Vector3.UP * 0.5, to, 14.0, 0.3, SILK_COL, Callable(), false, func(pos): _net_at(pos), true)
			start_move({"dur": 0.3, "hits": [], "move": 0.8, "noise": 2.0})
			return
		if p.silk < 8.0:
			p._msg("Seda insuficiente.")
			return
		if not ready_slot(1, "Ainda recolhendo a seda."):
			return
		var caught: Array = []
		for c in creatures_near(p.global_position, 12.0):
			if c.is_entangled() and not boss(c):
				caught.append(c)
		if caught.is_empty():
			p._msg("Ninguém preso para puxar.")
			return
		cds[1] = 4.0
		p.silk -= 8.0
		var dest := p.global_position + p.aim_dir * 1.6
		for c in caught:
			flash_line(p.global_position, c.global_position, SILK_COL, 0.35, 0.05)
			if big(c):
				c.slow(0.3, 2.5)
			else:
				c.yank_to(dest + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6)), 0.35)
		start_move({"dur": 0.4, "hits": [], "move": 0.0, "noise": 3.0})

	func _net_at(pos: Vector3) -> void:
		var t := WebNetwork.create_trap(Vector3(pos.x, p.global_position.y, pos.z))
		if t == null:
			return
		t.set_meta("temp", true)
		t.capacity = 1
		nets.append(t)
		while nets.size() > MAX_NETS:
			var old = nets.pop_front()
			if is_instance_valid(old):
				old._remove()
		get_tree().create_timer(20.0).timeout.connect(t._remove)


class Pendulo extends AttackKit:
	## Saltadora A: gira presa a um fio em volta de um ponto, acertando o arco; bote aéreo.
	func _init() -> void:
		names = ["Pêndulo", "Bote aéreo"]
		descs = ["Prende um fio 2,2 m à frente e gira meia volta em torno dele, acertando tudo no caminho (20).",
			"Pulo de até 5 m (passa por cima de bichos e de buracos curtos) que cai mordendo em volta (22). 10 de energia."]

	func press(slot: int) -> void:
		if slot == 0:
			_pendulo()
		else:
			_bote()

	func _pendulo() -> void:
		var pivot := p.global_position + p.aim_dir * 2.2
		var r := 2.2
		var a0 := atan2(p.global_position.z - pivot.z, p.global_position.x - pivot.x)
		var side := 1.0 if randf() < 0.5 else -1.0
		var hit: Array = []
		start_move({"dur": 0.5, "hits": [], "attack": make(Attack.Shape.RING, r + 0.8), "origin": pivot, "move": 0.0, "noise": 3.0,
			"update": func(time, dt):
				var k := clampf(time / 0.45, 0.0, 1.0)
				var ang := a0 + side * PI * 1.1 * k
				var want := pivot + Vector3(cos(ang), 0.0, sin(ang)) * r
				want.y = p.global_position.y
				flash_line(pivot, p.global_position, SILK_COL, 0.05, 0.03)
				for c in creatures_near(p.global_position, 1.4):
					if not hit.has(c):
						hit.append(c)
						p.hit_creature(c, 20.0)
				var v := (want - p.global_position) / maxf(dt, 0.001)
				v.y = 0.0
				return v.limit_length(30.0)})

	func _bote() -> void:
		if not ready_slot(1):
			return
		if p.energy < 10.0:
			p._msg("Sem energia para o bote.")
			return
		p.energy -= 10.0
		p.energy_delay = 1.0
		cds[1] = 1.5
		var want := p.global_position + p.aim_dir * clampf(Fx.flat_dist(p.aim_point, p.global_position), 2.0, 5.0)
		var land := floor_point(p.global_position, want)
		var dist := Fx.flat_dist(land, p.global_position)
		var dir := p.aim_dir
		p.leaping = true
		p.collision_mask = 1
		start_move({"dur": 0.55, "hits": [0.4], "attack": make(Attack.Shape.CIRCLE, 1.6, {"at_point": true}), "point": land, "dmg": 22.0, "poison": true,
			"dir": dir, "lunge": dist / 0.4, "lunge_until": 0.4, "move": 0.0, "noise": 2.0,
			"colors": [Color(0.45, 1.0, 0.45, 0.12), Color(0.55, 1.0, 0.5, 0.42)],
			"update": func(time, _dt):
				p._visual.position.y = sin(PI * clampf(time / 0.4, 0.0, 1.0)) * 1.4
				if time >= 0.4 and p.leaping:
					p.leaping = false
					p.collision_mask = 1 | 4 | 8
				return Vector3.ZERO,
			"on_end": func(_ok):
				p.leaping = false
				p.collision_mask = 1 | 4 | 8
				p._visual.position.y = 0.0})


class Ricochete extends AttackKit:
	## Saltadora B: dardos de seda à distância; bate e volta.
	func _init() -> void:
		names = ["Ricochete", "Bate e volta"]
		descs = ["Três dardos de seda em leque (9 m): 6 de dano cada e deixam lento. 3 de seda.",
			"Avança até o bicho (4 m), crava (18) e quica de volta para onde estava."]

	func press(slot: int) -> void:
		if slot == 0:
			if p.silk < 3.0:
				p._msg("Seda insuficiente para os dardos.")
				return
			p.silk -= 3.0
			for k in [-1, 0, 1]:
				var d := p.aim_dir.rotated(Vector3.UP, deg_to_rad(12.0 * k))
				shoot(p.global_position + Vector3.UP * 0.5, p.global_position + Vector3.UP * 0.5 + d * 9.0, 24.0, 0.4, SILK_COL, func(c):
					p.hit_creature(c, 6.0)
					c.slow(0.6, 2.0))
			start_move({"dur": 0.28, "hits": [], "move": 0.8, "queue": true, "noise": 2.0})
			return
		var t := aim_target(4.0, 60.0)
		if t == null:
			bite_move(2.6, bite_dmg())
			return
		var home := p.global_position
		var to := t.global_position - p.global_position
		to.y = 0.0
		var dist := maxf(0.0, to.length() - t.body_radius - 0.35)
		start_move({"dur": 0.45, "hits": [0.17], "attack": make(Attack.Shape.CONE, Player.BITE_RANGE, {"arc": 70.0}), "dmg": 18.0, "poison": true,
			"dir": to.normalized(), "lunge": dist / 0.15, "lunge_until": 0.15, "move": 0.0, "noise": 3.0,
			"colors": [Color(0.45, 1.0, 0.45, 0.12), Color(0.55, 1.0, 0.5, 0.42)],
			"update": func(time, _dt):
				if time > 0.2:
					var back := home - p.global_position
					back.y = 0.0
					if back.length() > 0.2:
						return back.normalized() * minf(back.length() / 0.05, 18.0)
				return Vector3.ZERO})
