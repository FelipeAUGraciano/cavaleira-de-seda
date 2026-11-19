class_name AttackKit
extends Node
## Ataques próprios de um ramo ou forma final: trocam o golpe (botão de atacar) e a mordida.
##
## Cada kit diz o que cada botão faz (press), pode tomar conta do estado da jogadora com um
## "movimento" cronometrado (área marcada no chão, avanço, acertos em tempos certos) e pode
## reagir ao dano que ela leva (guarda, contra-ataque, reflexo) e aos acertos dela.
## As formas finais têm dois estilos (A e B), escolhidos no casulo.

const COL_BASE := Color(0.4, 0.85, 1.0, 0.12)
const COL_HOT := Color(0.5, 0.9, 1.0, 0.42)

var p: Player
var names: Array = ["Golpe", "Mordida"]
var descs: Array = ["", ""]
var cds: Array = [0.0, 0.0]
var marker: AttackMarker

var _m: Dictionary = {}          ## movimento atual (ver start_move)
var _mt := 0.0
var _fired: Array = []


func setup(pl: Player) -> void:
	p = pl
	marker = AttackMarker.new()
	add_child(marker)


# ------------------------------------------------------------ para os kits sobrescreverem

func press(_slot: int) -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func on_hurt(amount: float, _source: Node3D) -> float:
	## Antes do dano entrar. Devolver 0 (ou menos) anula o golpe.
	return amount


func modify_hit(_c: Creature, dmg: float) -> float:
	return dmg


func on_hit(_c: Creature, _dmg: float) -> void:
	pass


func status_text() -> String:
	## Texto curto para a linha de estado do HUD (calor, guarda, cargas).
	return ""


func cancel() -> void:
	## A jogadora saiu do movimento no meio (esquiva, dano forte, queda).
	_end_move(false)


# ------------------------------------------------------------ quadro

func tick(delta: float) -> void:
	for i in cds.size():
		cds[i] = maxf(0.0, float(cds[i]) - delta)
	_tick(delta)
	if _m.is_empty() and marker.visible and _mt < 0.0:
		marker.clear()


func busy() -> bool:
	return not _m.is_empty()


func ready_slot(slot: int, msg := "") -> bool:
	if float(cds[slot]) > 0.0:
		if msg != "":
			p._msg(msg)
		return false
	return true


# ------------------------------------------------------------ movimento cronometrado

func start_move(m: Dictionary) -> void:
	## m: dur, hits ([tempos]), attack (Attack: forma da área), dmg, dir, point, lunge (m/s),
	## lunge_until, move (multiplicador de andar), poison, on_hit (Callable(c)), on_fire
	## (Callable() no tempo do acerto), on_end (Callable()), hold ("attack"/"bite": o movimento
	## dura enquanto segurar, até dur), on_release (Callable(t)), update (Callable(t, dt) -> Vector3
	## de movimento extra), colors ([base, quente]), noise.
	_m = m
	_mt = 0.0
	_fired = []
	if not _m.has("dir"):
		_m["dir"] = p.aim_dir
	p._start_state(Player.State.SKILL)


func state_update(delta: float) -> Vector3:
	if _m.is_empty():
		p._start_state(Player.State.NORMAL)
		return Vector3.ZERO
	_mt += delta
	p.noise = float(_m.get("noise", 5.0))
	if Input.is_action_just_pressed("dodge") and bool(_m.get("dodge_cancel", true)):
		_end_move(false)
		p._start_state(Player.State.NORMAL)
		p._try_dodge()
		return Vector3.ZERO
	if bool(_m.get("queue", false)):
		if Input.is_action_just_pressed("attack"):
			_m["queued"] = 0
		elif Input.is_action_just_pressed("bite"):
			_m["queued"] = 1
	var dir: Vector3 = _m["dir"]
	var hold := String(_m.get("hold", ""))
	if hold != "" and not Input.is_action_pressed(hold) and not bool(_m.get("released", false)):
		_m["released"] = true
		if _m.has("on_release"):
			(_m["on_release"] as Callable).call(_mt)
			return Vector3.ZERO
	var a: Attack = _m.get("attack")
	var hits: Array = _m.get("hits", [])
	if a != null:
		var first: float = hits[0] if not hits.is_empty() else float(_m.get("dur", 0.3))
		var fill := clampf(_mt / maxf(first, 0.01), 0.0, 1.0)
		if hold != "" and not bool(_m.get("released", false)):
			fill = clampf(_mt / float(_m.get("dur", 1.0)), 0.0, 1.0)
		var cols: Array = _m.get("colors", [COL_BASE, COL_HOT])
		marker.draw_shape(a, origin_of(_m), dir, _m.get("point", p.global_position), fill, cols[0], cols[1])
	for i in hits.size():
		if not _fired.has(i) and _mt >= float(hits[i]):
			_fired.append(i)
			_fire()
			if _m.is_empty():
				return Vector3.ZERO
	var out := Vector3.ZERO
	if _m.has("update"):
		var mref := _m
		out = (_m["update"] as Callable).call(_mt, delta)
		if _m.is_empty() or _m != mref:
			return out
	if _mt < float(_m.get("lunge_until", 0.12)):
		out += dir * float(_m.get("lunge", 0.0))
	out += p.move_dir * float(_m.get("move", 1.0))
	var done := _mt >= float(_m.get("dur", 0.3))
	if hold != "" and not bool(_m.get("released", false)):
		done = false
		if _mt >= float(_m.get("dur", 1.0)) and _m.has("on_release"):
			_m["released"] = true
			(_m["on_release"] as Callable).call(_mt)
			return out
	if done:
		var q := int(_m.get("queued", -1))
		_end_move(true)
		p._start_state(Player.State.NORMAL)
		if q >= 0:
			press(q)
	return out


func origin_of(m: Dictionary) -> Vector3:
	return m.get("origin", p.global_position)


func _fire() -> void:
	var a: Attack = _m.get("attack")
	if a != null and float(_m.get("dmg", 0.0)) > 0.0:
		for c in targets(a, origin_of(_m), _m["dir"], _m.get("point", p.global_position)):
			var d := p.hit_creature(c, float(_m["dmg"]), bool(_m.get("poison", false)))
			if _m.has("on_hit"):
				(_m["on_hit"] as Callable).call(c, d)
	if _m.has("on_fire"):
		(_m["on_fire"] as Callable).call()


func _end_move(completed: bool) -> void:
	if _m.is_empty():
		return
	var m := _m
	_m = {}
	_mt = -1.0
	marker.clear()
	if m.has("on_end"):
		(m["on_end"] as Callable).call(completed)


func end_now() -> void:
	## Termina o movimento atual de dentro dele (pouso, explosão).
	_end_move(true)
	p._start_state(Player.State.NORMAL)


# ------------------------------------------------------------ ataques prontos

var _combo_i := 0
var _combo_t := 0.0


func combo_swing(dmgs: Array, hit_cb := Callable(), arc := Player.ATTACK_ARC) -> void:
	## O combo de garras de sempre (três golpes em cone), para os kits que só mudam a mordida
	## ou somam algo a cada acerto.
	if Time.get_ticks_msec() / 1000.0 - _combo_t > 0.45:
		_combo_i = 0
	var i := _combo_i
	_combo_i = (_combo_i + 1) % dmgs.size()
	var reach := Player.ATTACK_RANGE * float(p.form_data()["scale"]) + 0.3
	p._swing_blades(i)
	var m := {"dur": Player.ATTACK_TIME, "hits": [0.1], "attack": make(Attack.Shape.CONE, reach, {"arc": arc}),
		"dmg": float(dmgs[i]), "lunge": 3.0, "move": 1.5, "queue": true, "noise": 6.0,
		"on_end": func(_ok): _combo_t = Time.get_ticks_msec() / 1000.0}
	if hit_cb.is_valid():
		m["on_hit"] = hit_cb
	start_move(m)


func bite_move(assist: float, dmg: float, extra := {}) -> Creature:
	## Mordida com bote: avança até o bicho na mira (até "assist" m) e crava.
	var t := aim_target(assist, 80.0)
	var dir := p.aim_dir
	var dist := 0.6
	if t != null:
		var to := t.global_position - p.global_position
		to.y = 0.0
		if to.length() > 0.05:
			dir = to.normalized()
		dist = clampf(to.length() - t.body_radius - 0.35, 0.0, assist)
	var m := {"dur": Player.BITE_TIME, "hits": [0.2], "attack": make(Attack.Shape.CONE, Player.BITE_RANGE, {"arc": 70.0}),
		"dmg": dmg, "poison": true, "dir": dir, "lunge": dist / 0.16, "lunge_until": 0.16, "move": 0.5, "noise": 4.0,
		"colors": [Color(0.45, 1.0, 0.45, 0.12), Color(0.55, 1.0, 0.5, 0.42)]}
	m.merge(extra, true)
	start_move(m)
	return t


func bite_dmg() -> float:
	return float(p.form_data()["bite"])


func combo_dmg(i: int) -> float:
	return float((p.form_data()["combo"] as Array)[i])


# ------------------------------------------------------------ ajudantes

func make(shape: Attack.Shape, reach: float, extra := {}) -> Attack:
	var props := {"shape": shape, "reach": reach}
	props.merge(extra, true)
	return Attack.make("kit", "", props)


func targets(a: Attack, origin: Vector3, dir: Vector3, point: Vector3, tall := 1.3) -> Array:
	var out: Array = []
	for c in World.creatures:
		if not is_instance_valid(c) or c.dead:
			continue
		if c.global_position.y - p.global_position.y > tall:
			continue
		if a.hits(origin, dir, point, c.global_position, c.body_radius):
			out.append(c)
	return out


static func creatures_near(center: Vector3, r: float) -> Array:
	var out: Array = []
	for c in World.creatures:
		if is_instance_valid(c) and not c.dead and Fx.flat_dist(c.global_position, center) <= r + c.body_radius:
			out.append(c)
	return out


func aim_target(max_d: float, cone_deg: float, filter := Callable()) -> Creature:
	## O bicho mais perto na mira (cone), que passa no filtro.
	var best: Creature = null
	var bd := max_d
	for c in World.creatures:
		if not is_instance_valid(c) or c.dead or c.global_position.y - p.global_position.y > 1.3:
			continue
		var to: Vector3 = c.global_position - p.global_position
		to.y = 0.0
		var d := to.length() - c.body_radius
		if d > bd:
			continue
		if to.length() > 0.3 and rad_to_deg(p.aim_dir.angle_to(to.normalized())) > cone_deg * 0.5:
			continue
		if filter.is_valid() and not bool(filter.call(c)):
			continue
		best = c
		bd = d
	return best


func root() -> Node:
	return p.get_parent()


func floor_point(from: Vector3, to: Vector3) -> Vector3:
	## O ponto mais longe na linha que ainda tem chão e não passa de parede.
	var steps := maxi(2, int(from.distance_to(to) / 0.4))
	var space := p.get_world_3d().direct_space_state
	var last := from
	for i in range(1, steps + 1):
		var q := from.lerp(to, float(i) / steps)
		var wall := PhysicsRayQueryParameters3D.create(last + Vector3.UP * 0.5, q + Vector3.UP * 0.5, 1)
		if not space.intersect_ray(wall).is_empty():
			break
		var down := PhysicsRayQueryParameters3D.create(q + Vector3.UP * 1.0, q + Vector3.DOWN * 2.5, 1)
		if not space.intersect_ray(down).is_empty():
			last = q
	return Vector3(last.x, from.y, last.z)


func flash_ring(center: Vector3, r: float, col: Color, life := 0.25) -> void:
	var c := center + Vector3.UP * 0.35
	for k in 16:
		var a0 := k * TAU / 16.0
		var a1 := (k + 1) * TAU / 16.0
		Fx.beam(root(), c + Vector3(cos(a0), 0, sin(a0)) * r, c + Vector3(cos(a1), 0, sin(a1)) * r, col, life, 0.07)


func flash_line(a: Vector3, b: Vector3, col: Color, life := 0.2, w := 0.12) -> void:
	Fx.beam(root(), a + Vector3.UP * 0.4, b + Vector3.UP * 0.4, col, life, w)


func shoot(from: Vector3, to: Vector3, speed: float, radius: float, col: Color, hit_cb: Callable, pierce := false, end_cb := Callable(), lob := false) -> Shot:
	var s := Shot.new()
	s.from = from
	s.to = to
	s.speed = speed
	s.radius = radius
	s.col = col
	s.on_hit = hit_cb
	s.on_end = end_cb
	s.pierce = pierce
	s.lob = lob
	root().add_child(s)
	return s


func zone(center: Vector3, r: float, dur: float, every: float, col: Color, on_tick: Callable) -> Zone:
	var z := Zone.new()
	z.r = r
	z.dur = dur
	z.every = every
	z.col = col
	z.on_tick = on_tick
	root().add_child(z)
	z.global_position = Vector3(center.x, center.y + 0.06, center.z)
	return z


static func add_stack(c: Creature, n: int) -> int:
	## Contador no bicho (seda colada, marcas): devolve o novo total.
	var k := int(c.get_meta("seda", 0)) + n
	c.set_meta("seda", k)
	return k


static func boss(c: Creature) -> bool:
	return c.is_in_group("boss")


static func big(c: Creature) -> bool:
	return int(c.size) >= int(Creature.Size.G)


# ------------------------------------------------------------ projétil

class Shot extends Node3D:
	## Projétil da jogadora: vai reto (ou num arco, lob) até o ponto, acerta bichos no caminho.
	var from: Vector3
	var to: Vector3
	var speed := 14.0
	var radius := 0.5
	var col := Color.WHITE
	var on_hit: Callable
	var on_end: Callable
	var pierce := false
	var lob := false
	var _t := 0.0
	var _len := 1.0
	var _hit: Array = []
	var _ball: MeshInstance3D

	func _ready() -> void:
		_len = maxf(0.3, Fx.flat_dist(from, to))
		_ball = Fx.sphere(0.16 + radius * 0.2, Fx.mat(col, 3.0, true, 0.9))
		add_child(_ball)
		global_position = from

	func _physics_process(delta: float) -> void:
		_t += delta * speed / _len
		var k := minf(_t, 1.0)
		var pos := from.lerp(to, k)
		if lob:
			pos.y += sin(PI * k) * minf(2.5, _len * 0.35)
		var step_from := global_position
		global_position = pos
		if not lob:
			var q := PhysicsRayQueryParameters3D.create(step_from, pos, 1)
			if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
				_finish()
				return
			for c in AttackKit.creatures_near(pos, radius):
				if _hit.has(c):
					continue
				_hit.append(c)
				if on_hit.is_valid() and is_instance_valid(GameState.player):
					on_hit.call(c)
				if not pierce:
					_finish()
					return
		if k >= 1.0:
			_finish()

	func _finish() -> void:
		if on_end.is_valid() and is_instance_valid(GameState.player):
			on_end.call(Vector3(global_position.x, to.y, global_position.z))
		queue_free()


# ------------------------------------------------------------ área no chão

class Zone extends Node3D:
	## Poça ou campo no chão: a cada "every" segundos chama on_tick(c) para quem estiver dentro.
	var r := 1.5
	var dur := 5.0
	var every := 0.5
	var col := Color.WHITE
	var on_tick: Callable
	var _t := 0.0
	var _next := 0.0
	var _disc: MeshInstance3D
	var _mat: StandardMaterial3D

	func _ready() -> void:
		_mat = Fx.mat(col, 1.6, true, 0.35)
		_disc = Fx.cylinder(r, 0.03, _mat)
		add_child(_disc)

	func _physics_process(delta: float) -> void:
		_t += delta
		_next -= delta
		if _next <= 0.0:
			_next = every
			if not on_tick.is_valid():
				queue_free()
				return
			for c in AttackKit.creatures_near(global_position, r):
				on_tick.call(c)
		_mat.albedo_color.a = 0.35 * clampf((dur - _t) / 0.6, 0.0, 1.0)
		if _t >= dur:
			queue_free()
