extends RefCounted
## Ataques das formas raras: Seda Ardente, Sombra do Breu, Viúva de Seda, Corrosiva e
## Cavaleira de Pedra-da-lua (dois estilos cada).

const FIRE_COL := Color(1.0, 0.5, 0.15)
const SHADOW_COL := Color(0.45, 0.3, 0.75)
const VENOM_COL := Color(0.75, 1.0, 0.3)
const ACID_COL := Color(0.55, 1.0, 0.2)
const MOON_COL := Color(0.85, 0.92, 1.0)


class LancaChamas extends AttackKit:
	## Ardente A: sopro de fogo contínuo que esquenta você; bola de brasa que deixa fogo no chão.
	var heat := 0.0
	var overheat := 0.0
	var flaming := false

	func _init() -> void:
		names = ["Lança-chamas", "Brasa"]
		descs = ["Segurar: sopro de fogo em cone (5 m), 30 por segundo e incendeia. Esquenta você: em 100% de calor, ela trava por 2,5 s.",
			"Cospe uma bola de brasa (7 m) que deixa fogo no chão por 5 s (10 por segundo e incendeia)."]

	func status_text() -> String:
		if overheat > 0.0:
			return "SUPERAQUECIDA"
		return "CALOR %d%%" % int(heat) if heat > 1.0 else ""

	func _tick(delta: float) -> void:
		overheat = maxf(0.0, overheat - delta)
		if not flaming:
			heat = maxf(0.0, heat - 20.0 * delta)

	func press(slot: int) -> void:
		if slot == 1:
			if not ready_slot(1):
				return
			cds[1] = 2.0
			var to := floor_point(p.global_position, p.global_position + p.aim_dir * clampf(Fx.flat_dist(p.aim_point, p.global_position), 2.0, 7.0))
			shoot(p.global_position + Vector3.UP * 0.6, to, 13.0, 0.4, FIRE_COL, Callable(), false, func(pos):
				zone(pos, 1.8, 5.0, 0.5, FIRE_COL, func(c): p.hit_creature(c, 5.0)), true)
			start_move({"dur": 0.3, "hits": [], "move": 0.8, "noise": 4.0})
			return
		if overheat > 0.0:
			p._msg("Superaquecida! Espere esfriar.")
			return
		var a := make(Attack.Shape.CONE, 5.0, {"arc": 70.0})
		var st := {"next": 0.0}
		flaming = true
		start_move({"dur": 30.0, "hold": "attack", "hits": [], "attack": a, "move": 0.45, "noise": 7.0,
			"colors": [Color(1.0, 0.5, 0.15, 0.12), Color(1.0, 0.5, 0.15, 0.3)],
			"update": func(time, dt):
				_m["dir"] = p.aim_dir
				heat += 25.0 * dt
				if heat >= 100.0:
					heat = 100.0
					overheat = 2.5
					p._msg("Superaqueceu!")
					end_now()
					return Vector3.ZERO
				if time >= float(st["next"]):
					st["next"] = time + 0.15
					for c in targets(a, p.global_position, p.aim_dir, p.global_position):
						p.hit_creature(c, 4.5)
					for k in 3:
						var d := p.aim_dir.rotated(Vector3.UP, randf_range(-0.55, 0.55))
						flash_line(p.global_position + p.aim_dir * 0.6, p.global_position + d * randf_range(2.5, 5.0), FIRE_COL, 0.12, 0.12)
				return Vector3.ZERO,
			"on_release": func(_t): end_now(),
			"on_end": func(_ok): flaming = false})


class Fornalha extends AttackKit:
	## Ardente B: garras de fogo enchem o calor; com calor cheio, a mordida explode.
	var heat := 0.0

	func _init() -> void:
		names = ["Garras de fogo", "Explosão"]
		descs = ["Combo de garras que incendeiam; cada acerto enche 20% de calor.",
			"Com o calor cheio: explode em volta (3,5 m, 60 de dano) e zera o calor. Sem calor cheio, é uma mordida comum."]

	func status_text() -> String:
		return "FORNALHA %d%%" % int(heat) if heat > 0.0 else ""

	func press(slot: int) -> void:
		if slot == 0:
			combo_swing(p.form_data()["combo"], func(_c, _d): heat = minf(100.0, heat + 20.0))
			return
		if heat < 100.0:
			bite_move(2.6, bite_dmg())
			return
		heat = 0.0
		start_move({"dur": 0.55, "hits": [0.25], "attack": make(Attack.Shape.RING, 3.5), "dmg": 60.0, "move": 0.0, "noise": 14.0,
			"colors": [Color(1.0, 0.5, 0.15, 0.15), Color(1.0, 0.4, 0.1, 0.5)],
			"on_fire": func():
				flash_ring(p.global_position, 3.5, FIRE_COL, 0.35)
				flash_ring(p.global_position, 2.2, Color(1.0, 0.8, 0.3), 0.3)
				p.shake(0.45)
				p._msg("Explosão!")})


class Assassina extends AttackKit:
	## Breu A: golpe silencioso que mata quem não te viu; passo sombrio para trás do alvo.
	func _init() -> void:
		names = ["Golpe silencioso", "Passo sombrio"]
		descs = ["Garrada sem barulho. Em quem não te notou: bicho pequeno ou médio morre na hora (grande leva 2,5x).",
			"De runa apagada: some e reaparece atrás do bicho na mira (até 6 m) e crava. Recarrega em 4 s."]

	func press(slot: int) -> void:
		if slot == 0:
			var a := make(Attack.Shape.CONE, 2.0, {"arc": 80.0})
			start_move({"dur": 0.32, "hits": [0.12], "attack": a, "dmg": 0.0, "move": 1.0, "queue": true, "noise": 0.0,
				"colors": [Color(0.5, 0.35, 0.8, 0.12), Color(0.6, 0.4, 0.9, 0.35)],
				"on_fire": func():
					for c in targets(a, p.global_position, p.aim_dir, p.global_position):
						if not c.noticed_player and int(c.size) <= int(Creature.Size.M) and not boss(c):
							p.hit_creature(c, c.hp + 1.0)
							p._msg("Silêncio.")
						else:
							p.hit_creature(c, 14.0)})
			return
		if p.rune_on:
			p._msg("O passo sombrio só funciona no escuro (runa apagada).")
			bite_move(2.6, bite_dmg())
			return
		if not ready_slot(1, "O passo sombrio ainda não voltou."):
			return
		var t := aim_target(6.0, 60.0)
		if t == null:
			bite_move(2.6, bite_dmg())
			return
		var away := t.global_position - p.global_position
		away.y = 0.0
		var behind := t.global_position + away.normalized() * (t.body_radius + 0.8)
		var spot := floor_point(t.global_position, Vector3(behind.x, t.global_position.y, behind.z))
		if Fx.flat_dist(spot, t.global_position) < t.body_radius + 0.3:
			spot = p.global_position   # sem lugar atrás: morde daqui mesmo
		cds[1] = 4.0
		flash_ring(p.global_position, 0.6, SHADOW_COL, 0.3)
		p.global_position = Vector3(spot.x, p.global_position.y, spot.z)
		flash_ring(p.global_position, 0.6, SHADOW_COL, 0.3)
		p.aim_dir = (t.global_position - p.global_position).normalized()
		p.aim_dir.y = 0.0
		bite_move(1.0, bite_dmg() + 6.0, {"noise": 0.0})


class SombraViva extends AttackKit:
	## Breu B: clone de sombra que atrai os bichos; nuvem de breu que apaga as luzes.
	var cloud_t := 0.0
	var cloud_c := Vector3.ZERO

	func _tick(delta: float) -> void:
		if cloud_t > 0.0:
			cloud_t -= delta
			if Fx.flat_dist(p.global_position, cloud_c) < 5.0:
				p.veil_t = maxf(p.veil_t, 0.3)

	func _init() -> void:
		names = ["Sombra viva", "Breu"]
		descs = ["Deixa um clone de sombra: quem te caçava vai atrás dele (5 s) e você some por 2,5 s. Recarrega em 10 s.",
			"Nuvem de breu (5 m, 6 s): apaga tochas e fogueiras, e dentro dela ninguém te vê. Recarrega em 12 s."]

	func press(slot: int) -> void:
		if slot == 0:
			if not ready_slot(0, "A sombra ainda não voltou."):
				return
			cds[0] = 10.0
			var at := p.global_position
			var clone := Fx.sphere(0.55 * float(p.form_data()["scale"]), Fx.mat(SHADOW_COL, 1.5, true, 0.6))
			root().add_child(clone)
			clone.global_position = at + Vector3.UP * 0.5
			get_tree().create_timer(6.0).timeout.connect(clone.queue_free)
			var n := 0
			for c in creatures_near(at, 15.0):
				if c.noticed_player or c.hunting_player() or Fx.flat_dist(c.global_position, at) < 6.0:
					c.distract(at, 5.0)
					n += 1
			p.veil_t = 2.5
			p._msg("Sombra viva (%d foram atrás dela)." % n)
			start_move({"dur": 0.2, "hits": [], "move": 1.2, "noise": 0.0})
			return
		if not ready_slot(1, "O breu ainda não voltou."):
			return
		cds[1] = 12.0
		var center := p.global_position
		zone(center, 5.0, 6.0, 0.25, Color(0.08, 0.05, 0.14), func(c): c.noticed_player = false)
		for n in root().find_children("*", "Node3D", true, false):
			if n is Fire and Fx.flat_dist((n as Fire).global_position, center) < 5.5:
				(n as Fire).snuff(6.0)
		cloud_t = 6.0
		cloud_c = center
		p._msg("Breu.")
		start_move({"dur": 0.3, "hits": [], "move": 0.5, "noise": 0.0})


class Presas extends AttackKit:
	## Viúva A: cuspe de veneno que deixa poça; picada fatal (só veneno, muito).
	var victims: Array = []

	func _init() -> void:
		names = ["Cuspe de veneno", "Picada fatal"]
		descs = ["Cospe veneno em arco (até 7 m): 2 doses em quem estiver lá e uma poça que envenena por 6 s.",
			"Bote que quase não machuca na hora mas injeta 6 doses de veneno (passa do limite normal de 5). Quem morrer envenenado vira comida que cura 20% da vida."]

	func press(slot: int) -> void:
		if slot == 0:
			if not ready_slot(0):
				return
			cds[0] = 0.7
			var to := floor_point(p.global_position, p.global_position + p.aim_dir * clampf(Fx.flat_dist(p.aim_point, p.global_position), 2.0, 7.0))
			shoot(p.global_position + Vector3.UP * 0.6, to, 14.0, 0.3, VENOM_COL, Callable(), false, func(pos):
				for c in creatures_near(pos, 1.5):
					c.add_poison()
					c.add_poison()
				zone(pos, 1.5, 6.0, 1.0, VENOM_COL, func(c): c.add_poison()), true)
			start_move({"dur": 0.3, "hits": [], "move": 0.8, "noise": 3.0})
			return
		var t := bite_move(2.8, 1.0, {"on_hit": func(c, _d):
			c.add_poison(6, 10)
			if not victims.has(c):
				victims.append(c)})
		if t == null:
			return

	func _tick(_delta: float) -> void:
		for c in victims.duplicate():
			if not is_instance_valid(c):
				victims.erase(c)
				continue
			if c.dead:
				var at: Vector3 = c.global_position
				victims.erase(c)
				_mark_corpse.call_deferred(at)

	func _mark_corpse(at: Vector3) -> void:
		for k in World.corpses:
			if is_instance_valid(k) and Fx.flat_dist(k.global_position, at) < 2.0:
				k.set_meta("venom_heal", true)
				return


class FiosVenenosos extends AttackKit:
	## Viúva B: garras que envenenam os fios por perto; dreno que cura com o veneno dos bichos.
	var poisoned := {}       ## fio -> segundos que faltam
	var _t := 0.0

	func _init() -> void:
		names = ["Fios venenosos", "Dreno"]
		descs = ["Combo de garras; cada golpe envenena seus fios a até 4 m por 20 s (quem encostar neles toma veneno).",
			"Suga o veneno: cura 4 PV por dose de todos os bichos envenenados a até 8 m (até 40% da vida) e tira metade das doses deles."]

	func press(slot: int) -> void:
		if slot == 0:
			combo_swing(p.form_data()["combo"])
			for s in WebNetwork.strands:
				if is_instance_valid(s) and (s as WebStrand).distance_to(p.global_position) < 4.0:
					poisoned[s] = 20.0
			return
		if not ready_slot(1, "O dreno ainda não voltou."):
			return
		var total := 0.0
		for c in creatures_near(p.global_position, 8.0):
			if c.poison_stacks > 0:
				total += 4.0 * c.poison_stacks
				flash_line(c.global_position, p.global_position, VENOM_COL, 0.35, 0.05)
				c.poison_stacks = int(c.poison_stacks / 2.0)
		if total <= 0.0:
			p._msg("Ninguém envenenado por perto.")
			return
		cds[1] = 6.0
		var gain := minf(total, p.max_hp * 0.4)
		p.hp = minf(p.max_hp, p.hp + gain)
		p._msg("Dreno: +%d PV." % int(gain))
		start_move({"dur": 0.4, "hits": [], "move": 0.3, "noise": 1.0})

	func _tick(delta: float) -> void:
		_t -= delta
		if _t > 0.0:
			return
		_t = 1.0
		for s in poisoned.keys():
			if not is_instance_valid(s):
				poisoned.erase(s)
				continue
			poisoned[s] = float(poisoned[s]) - 1.0
			if float(poisoned[s]) <= 0.0:
				poisoned.erase(s)
				continue
			var ws := s as WebStrand
			flash_line(ws.a_pos, ws.b_pos, VENOM_COL, 0.9, 0.04)
			for c in World.creatures:
				if is_instance_valid(c) and not c.dead and Fx.seg_dist_flat(c.global_position, ws.a_pos, ws.b_pos) < 1.0 + c.body_radius:
					c.add_poison()


class Cuspe extends AttackKit:
	## Corrosiva A: jato de ácido que deixa rastro; derreter (segurar a mordida).
	func _init() -> void:
		names = ["Cuspe ácido", "Derreter"]
		descs = ["Jato de ácido em linha (6 m): 12 e corrói, e deixa um rastro que corrói quem passar (5 s).",
			"Segurar a mordida num bicho colado: o ácido derrete cada vez mais rápido (até 2,5 s) e deixa ele lento."]

	func press(slot: int) -> void:
		if slot == 0:
			if not ready_slot(0):
				return
			cds[0] = 0.5
			var a := make(Attack.Shape.LINE, 6.0, {"width": 1.0})
			var dir := p.aim_dir
			start_move({"dur": 0.35, "hits": [0.15], "attack": a, "dmg": 12.0, "move": 0.6, "noise": 4.0,
				"colors": [Color(0.55, 1.0, 0.2, 0.12), Color(0.55, 1.0, 0.2, 0.4)],
				"on_fire": func():
					flash_line(p.global_position, p.global_position + dir * 6.0, ACID_COL, 0.25, 0.14)
					for k in 3:
						zone(p.global_position + dir * (1.5 + k * 1.8), 0.8, 5.0, 0.5, ACID_COL, func(c):
							c.corrode(2.0)
							c.take_damage(2.0, p))})
			return
		var t := aim_target(2.2, 80.0)
		if t == null:
			bite_move(2.6, bite_dmg())
			return
		var st := {"next": 0.0}
		start_move({"dur": 2.5, "hold": "bite", "hits": [], "move": 0.0, "noise": 3.0,
			"update": func(time, _dt):
				if not is_instance_valid(t) or t.dead or Fx.flat_dist(t.global_position, p.global_position) > 2.6 + t.body_radius:
					end_now()
					return Vector3.ZERO
				_m["dir"] = (t.global_position - p.global_position).normalized()
				if time >= float(st["next"]):
					st["next"] = time + 0.25
					t.corrode(1.0)
					t.slow(0.4, 0.5)
					p.hit_creature(t, 2.0 + 4.0 * time)
					flash_line(p.global_position, t.global_position, ACID_COL, 0.2, 0.06)
				return Vector3.ZERO,
			"on_release": func(_t): end_now()})


class Banho extends AttackKit:
	## Corrosiva B: respingo em volta que corrói todos; dissolver cadáver (come de uma vez).
	func _init() -> void:
		names = ["Banho ácido", "Dissolver"]
		descs = ["Sacode o corpo: respingo de ácido em volta (3 m), 10 e corrói todos.",
			"Num cadáver: derrete e come de uma vez (+15% de vida). Num bicho corroído: mordida 2,5x."]

	func press(slot: int) -> void:
		if slot == 0:
			if not ready_slot(0):
				return
			cds[0] = 0.6
			start_move({"dur": 0.45, "hits": [0.2], "attack": make(Attack.Shape.RING, 3.0), "dmg": 10.0, "move": 0.3, "noise": 5.0,
				"colors": [Color(0.55, 1.0, 0.2, 0.12), Color(0.55, 1.0, 0.2, 0.4)],
				"on_fire": func(): flash_ring(p.global_position, 3.0, ACID_COL, 0.25)})
			return
		var corpse := p._nearest_corpse(2.2)
		if corpse != null:
			var at := corpse.global_position
			p._eat(corpse)
			p.hp = minf(p.max_hp, p.hp + p.max_hp * 0.15)
			flash_ring(at, 0.8, ACID_COL, 0.4)
			p._msg("Dissolveu!")
			start_move({"dur": 0.4, "hits": [], "move": 0.0, "noise": 2.0})
			return
		var t := aim_target(2.6, 80.0)
		var mult := 2.5 if t != null and t.corrode_time > 0.0 else 1.0
		bite_move(2.6, bite_dmg() * mult)


class Lanca extends AttackKit:
	## Pedra-da-lua A: estocada longa de cristal; estouro do escudo.
	func _init() -> void:
		names = ["Lança de luar", "Estouro"]
		descs = ["Estocada de cristal em linha (4 m), atravessa todos: 26.",
			"Gasta o escudo inteiro numa onda (3,5 m): dano = escudo x 1,2 + 10, empurra e atordoa."]

	func press(slot: int) -> void:
		if slot == 0:
			var dir := p.aim_dir
			start_move({"dur": 0.45, "hits": [0.18], "attack": make(Attack.Shape.LINE, 4.0, {"width": 0.9}), "dmg": 26.0, "lunge": 6.0, "lunge_until": 0.15,
				"move": 0.6, "queue": true, "noise": 6.0,
				"colors": [Color(0.85, 0.92, 1.0, 0.12), Color(0.85, 0.92, 1.0, 0.4)],
				"on_fire": func(): flash_line(p.global_position, p.global_position + dir * 4.0, MOON_COL, 0.2, 0.1)})
			return
		if p.shield < 10.0:
			p._msg("Escudo fraco demais para o estouro.")
			return
		var power := p.shield * 1.2 + 10.0
		p.shield = 0.0
		p._shield_wait = 6.0
		start_move({"dur": 0.5, "hits": [0.2], "attack": make(Attack.Shape.RING, 3.5), "dmg": power, "move": 0.0, "noise": 10.0,
			"colors": [Color(0.85, 0.92, 1.0, 0.14), Color(0.85, 0.92, 1.0, 0.5)],
			"on_hit": func(c, _d):
				if c.dead:
					return
				if not boss(c):
					c.entangle_raw(1.0)
				if not big(c):
					var away: Vector3 = c.global_position - p.global_position
					away.y = 0.0
					c.external_velocity = away.normalized() * 10.0,
			"on_fire": func():
				flash_ring(p.global_position, 3.5, MOON_COL, 0.35)
				p.shake(0.3)})


class Espelho extends AttackKit:
	## Pedra-da-lua B: golpes que recarregam o escudo; refletir.
	var reflecting := false

	func _init() -> void:
		names = ["Golpe espelhado", "Refletir"]
		descs = ["Combo de garras; cada acerto recarrega 5 de escudo.",
			"Por 0,8 s, o escudo vira espelho: flechas, cuspes e golpes voltam para quem atacou (1,5x). Recarrega em 4 s."]

	func status_text() -> String:
		return "ESPELHO" if reflecting else ""

	func press(slot: int) -> void:
		if slot == 0:
			combo_swing(p.form_data()["combo"], func(_c, _d): p.shield = minf(float(p.fd("shield", 0.0)), p.shield + 5.0))
			return
		if not ready_slot(1, "O espelho ainda não voltou."):
			return
		cds[1] = 4.0
		reflecting = true
		flash_ring(p.global_position, 1.0, MOON_COL, 0.8)
		start_move({"dur": 0.8, "hits": [], "attack": make(Attack.Shape.RING, 1.2), "move": 0.3, "noise": 2.0,
			"colors": [Color(0.85, 0.92, 1.0, 0.2), Color(0.85, 0.92, 1.0, 0.3)],
			"on_end": func(_ok): reflecting = false})

	func on_hurt(amount: float, source: Node3D) -> float:
		if not reflecting:
			return amount
		if source is Creature and not (source as Creature).dead:
			(source as Creature).take_damage(amount * 1.5, p)
			flash_line(p.global_position, source.global_position, MOON_COL, 0.25, 0.08)
		p._msg("Refletiu!")
		return 0.0
