class_name Behaviors
extends RefCounted
## Comportamentos genéricos usados pelas espécies (cada uma monta o seu Brain com eles).
## Os específicos de uma espécie (a isca do lagarto, o bote do morcego) ficam no arquivo dela.
##
##   Wander   vagar perto do ponto de referência (toca ou lugar onde chegou passeando)
##   Sleep    ir até a toca e dormir; cura devagar; acorda com barulho, ameaça ou ataque
##   Forage   comer: pastar perto dos fungos, comer cadáver ou caçar uma presa menor
##   Flee     fugir de ameaça (bicho maior ou a jogadora, para quem tem medo dela)
##   Roam     passear até outra câmara do seu território (como os monstros de Monster Hunter)
##   Combat   lutar com a jogadora (cada espécie tem seus ataques em combat_tick)
##   Retreat  ferida, volta mancando para a toca para dormir e se curar
##   Fight    brigar com um rival que invadiu o território
##   Stalk    caçar a jogadora: com fome, segue o cheiro e o barulho dela até achar


class Wander extends Behavior:
	var radius := 5.0
	var mult := 0.35

	func _init(radius_: float = 5.0, mult_: float = 0.35) -> void:
		id = "wander"
		label = "Vagando"
		radius = radius_
		mult = mult_

	func utility(_c: Creature) -> float:
		return 0.1

	func run(c: Creature, delta: float) -> Vector3:
		return c.wander(delta, radius, mult)


class Sleep extends Behavior:
	func _init() -> void:
		id = "sleep"
		label = "Dormindo"

	func utility(c: Creature) -> float:
		if c.noticed_player or c.needs.fear > 25.0:
			return 0.0
		var f := c.needs.fatigue
		if c.asleep:
			return 0.0 if f < 8.0 else 0.25 + f / 100.0 * 0.8
		if f < 55.0:
			return 0.0
		return f / 100.0 * (1.0 if c.is_resting_phase() else 0.5)

	func start(c: Creature) -> void:
		c.anchor = c.den

	func run(c: Creature, delta: float) -> Vector3:
		if Fx.flat_dist(c.global_position, c.den) > c.den_radius:
			c.asleep = false
			c.activity = "Indo para a toca"
			return c.nav_to(c.den, 0.6)
		c.asleep = true
		c.activity = label
		c.heal(c.max_hp * c.sleep_heal * delta)
		return Vector3.ZERO

	func stop(c: Creature) -> void:
		c.asleep = false


class Forage extends Behavior:
	var target: Variant = null
	var eat_t := 0.0

	func _init() -> void:
		id = "forage"
		label = "Procurando comida"

	func utility(c: Creature) -> float:
		if c.needs.hunger < c.hunger_threshold:
			return 0.0
		if not _valid(target):
			target = c.find_food()
		if target == null:
			return 0.0
		return c.needs.hunger / 100.0 * 0.9

	func start(_c: Creature) -> void:
		eat_t = 0.0

	func stop(c: Creature) -> void:
		if target is Corpse and is_instance_valid(target) and (target as Corpse).reserved_by == c:
			(target as Corpse).reserved_by = null
		target = null

	func locked(c: Creature) -> bool:
		return c.is_striking()

	func _valid(t: Variant) -> bool:
		if t == null:
			return false
		if t is Vector3:
			return true
		return is_instance_valid(t) and not (t is Creature and (t as Creature).dead)

	func run(c: Creature, delta: float) -> Vector3:
		if not _valid(target):
			target = c.find_food()
			if target == null:
				return Vector3.ZERO
		if target is Vector3:
			var spot: Vector3 = target
			if Fx.flat_dist(c.global_position, spot) > 1.0:
				c.activity = "Indo pastar"
				return c.nav_to(spot, 0.5)
			c.activity = "Pastando"
			eat_t += delta
			if eat_t >= 4.0:
				c.needs.hunger = maxf(0.0, c.needs.hunger - 60.0)
				target = null
				eat_t = 0.0
			return c.wander(delta, 1.5, 0.15)
		if target is Corpse:
			var corpse := target as Corpse
			if corpse.reserved_by != null and is_instance_valid(corpse.reserved_by) and corpse.reserved_by != c:
				target = null
				return Vector3.ZERO
			corpse.reserved_by = c
			if Fx.flat_dist(c.global_position, corpse.global_position) > c.body_radius + 1.0:
				c.activity = "Indo comer"
				return c.nav_to(corpse.global_position, 0.8)
			c.activity = "Comendo"
			c.face_toward(corpse.global_position)
			eat_t += delta
			if eat_t >= 2.5:
				corpse.consume()
				c.needs.hunger = maxf(0.0, c.needs.hunger - 70.0)
				c.heal(c.max_hp * 0.15)
				target = null
				eat_t = 0.0
			return Vector3.ZERO
		var prey := target as Creature
		c.activity = "Caçando"
		var v := c.fight(prey, delta)
		if prey.dead:
			target = World.nearest_corpse(prey.global_position, 3.0)
			eat_t = 0.0
		return v


class Flee extends Behavior:
	func _init() -> void:
		id = "flee"
		label = "Fugindo"

	func utility(c: Creature) -> float:
		return 0.0 if c.needs.fear < 25.0 else c.needs.fear / 100.0 * 1.2

	func run(c: Creature, _delta: float) -> Vector3:
		return c.flee_from(c.fear_source)


class Roam extends Behavior:
	var dest: Variant = null
	var _t := 0.0
	var _check_t := 0.0
	var _check_pos := Vector3.ZERO

	func _init() -> void:
		id = "roam"
		label = "Passeando"

	func utility(c: Creature) -> float:
		if c.range_rooms.is_empty() or World.nav == null or c.needs.restless < 50.0:
			return 0.0
		return c.needs.restless / 100.0 * 0.55 * c.activity_level()

	func start(c: Creature) -> void:
		dest = c.pick_roam_destination()
		_t = 0.0
		_check_t = 0.0
		_check_pos = c.global_position

	func run(c: Creature, delta: float) -> Vector3:
		if dest == null:
			c.needs.restless = 0.0
			return Vector3.ZERO
		_t += delta
		_check_t += delta
		if _check_t >= 4.0:
			# sem sair do lugar (destino inalcançável): desiste e fica por aqui
			var stuck := Fx.flat_dist(c.global_position, _check_pos) < 0.6
			_check_t = 0.0
			_check_pos = c.global_position
			if stuck or _t > 45.0:
				dest = c.global_position
		var d: Vector3 = dest
		if Fx.flat_dist(c.global_position, d) < 1.6:
			c.anchor = d
			c.needs.restless = 0.0
			dest = null
			return Vector3.ZERO
		return c.nav_to(d, c.roam_speed)


class Combat extends Behavior:
	func _init(label_: String = "Em combate") -> void:
		id = "combat"
		label = label_

	func utility(c: Creature) -> float:
		return 1.0 if c.combat_wants() else 0.0

	func start(c: Creature) -> void:
		c.asleep = false
		c.combat_start()

	func run(c: Creature, delta: float) -> Vector3:
		return c.combat_tick(delta)

	func stop(c: Creature) -> void:
		c.combat_stop()

	func locked(c: Creature) -> bool:
		return c.combat_locked()


class Retreat extends Behavior:
	func _init() -> void:
		id = "retreat"
		label = "Fugindo ferida para a toca"

	func utility(c: Creature) -> float:
		if c.retreat_frac <= 0.0 or c.retreat_cd > 0.0:
			return 0.0
		return 1.3 if c.hp < c.max_hp * c.retreat_frac else 0.0

	func start(c: Creature) -> void:
		c.on_retreat()

	func run(c: Creature, _delta: float) -> Vector3:
		if Fx.flat_dist(c.global_position, c.den) > c.den_radius:
			return c.nav_to(c.den, c.retreat_speed)
		# chegou: vai dormir para se curar (o Sleep assume na próxima decisão)
		c.needs.fatigue = 100.0
		c.retreat_cd = c.retreat_cooldown
		return Vector3.ZERO


class Fight extends Behavior:
	var rival: Creature = null

	func _init() -> void:
		id = "fight"
		label = "Brigando por território"

	func utility(c: Creature) -> float:
		rival = c.find_rival()
		return 0.85 if rival != null else 0.0

	func locked(c: Creature) -> bool:
		return c.is_striking()

	func run(c: Creature, delta: float) -> Vector3:
		if rival == null or not is_instance_valid(rival) or rival.dead:
			return Vector3.ZERO
		return c.fight(rival, delta)


class Stalk extends Behavior:
	## Predador com fome trata a jogadora como presa: vai atrás do cheiro e do barulho dela
	## (uma estimativa que melhora quanto mais perto) até vê-la — aí o Combate assume.
	## Só caça quem é maior que você (ou do mesmo tamanho, faminto). Depois da muda, menos
	## bichos te veem como comida.
	var guess := Vector3.ZERO
	var _refresh := 0.0

	func _init() -> void:
		id = "stalk"
		label = "Te caçando"

	func utility(c: Creature) -> float:
		if c.aggression <= 0.0 or c.needs.hunger < 35.0 or c.combat_wants():
			return 0.0   # já sabe onde você está: quem manda é o Combate
		var p := GameState.player as Player
		if p == null or p.dead or not c.sees_player_as_prey(p):
			return 0.0
		var d := c.flat_dist_to(p)
		var r := c.track_range * c.activity_level()
		if d > r:
			return 0.0
		# a Filhote cheira a presa fácil: quanto mais perto, mais ela vale que outra comida
		var near := 1.0 - d / maxf(r, 0.1)
		return (0.5 + c.needs.hunger / 100.0 * 0.45 + 0.2 * near) * c.aggression

	func start(c: Creature) -> void:
		_refresh = 0.0
		c.on_stalk_start()

	func run(c: Creature, delta: float) -> Vector3:
		var p := GameState.player as Player
		if p == null or p.dead:
			return Vector3.ZERO
		_refresh -= delta
		if _refresh <= 0.0:
			_refresh = 1.5
			var d := c.flat_dist_to(p)
			var err := d * 0.18
			guess = p.global_position + Vector3(randf_range(-err, err), 0.0, randf_range(-err, err))
		if Fx.flat_dist(c.global_position, guess) < 1.2:
			return c.wander(delta, 3.0, 0.4)   # farejando em volta
		return c.nav_to(guess, c.stalk_speed)
