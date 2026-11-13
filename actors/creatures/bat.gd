class_name Bat
extends Creature
## Morcego-eco (P, bando): voa alto e caça pelo som.
## Ouve quem se MEXE (a runa apagada não ajuda; ficar parada, sim). Ataca em mergulhos,
## no máximo dois de cada vez. No alto, a mordida não alcança: só durante o mergulho.
## Fio esticado no caminho (ou fio lançado com Q) prende o morcego no ar e ele cai.
##
## Vida: dorme pendurado no poleiro quando os fungos estão acesos (Brilho). Na Caça, o bando
## sai junto para outras câmaras e mergulha nas larvas que encontra.

enum Mode { ROOST, ALERT, WINDUP, DIVE, CLIMB }

const HEAR_RANGE := 10.0
const STILL_RANGE := 1.8        ## parada, só é ouvida muito perto
const ROOST_Y := 2.6
const ALERT_Y := 2.3
const DIVE_Y := 0.45
const DIVE_SPEED := 9.5
const DIVE_HOMING := 3.5        ## m/s que o alvo do mergulho segue o alvo (esquiva ainda escapa)
const BITE_DAMAGE := 10.0        ## cinco mergulhos matam uma Filhote — e o bando mergulha junto
const PREY_DAMAGE := 9.0
const MAX_DIVERS := 3
const DIVE_LEAD := 0.35          ## mira onde você vai estar
const SCREECH_RANGE := 7.0

var _tele_dive := Attack.make("mergulho", "", {"shape": Attack.Shape.CIRCLE, "reach": 0.9, "at_point": true})   ## marca no chão do mergulho
var flock := "bando"            ## morcegos do mesmo bando passeiam juntos
var mode: Mode = Mode.ROOST
var mode_time := 0.0
var dive_cd := 0.0
var dive_target := Vector3.ZERO
var orbit_angle := 0.0
var bit := false
var catch_immunity := 0.0
var screech_cd := 4.0
var _wings: Array[Node3D] = []


func _init() -> void:
	display_name = "Morcego-eco"
	size = Size.P
	level = 2
	max_hp = 12.0
	speed = 5.5
	body_radius = 0.25
	body_color = Color(0.32, 0.27, 0.36)
	food_satiety = 12.0
	food_silk = 6.0
	food_xp = 20
	senses_text = "som (10 m): ouve quem se mexe; parada, só a 2 m"
	model_name = "morcego"
	model_size = 1.1
	hover_y = ROOST_Y
	rest_phase = CaveClock.Phase.BRILHO
	nav_kind = NavGrid.Kind.AIR
	roam_speed = 0.8
	hunger_threshold = 40.0
	memory_time = 6.0
	needs.hunger_rate = 0.7
	aggression = 0.7
	track_range = 18.0
	stalk_speed = 0.8


func _ready() -> void:
	super._ready()
	add_to_group("flyer")
	add_to_group("bat")
	collision_mask = 1 | 4
	orbit_angle = randf() * TAU
	dive_cd = randf_range(0.8, 3.0)
	position.y = ROOST_Y


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Mergulhando em você")) \
		.add(HuntLarva.new()) \
		.add(Behaviors.Stalk.new()) \
		.add(Behaviors.Sleep.new()) \
		.add(Behaviors.Roam.new()) \
		.add(Circle.new())


func _build_visual() -> void:
	var body := Fx.sphere(body_radius, _mat)
	body.scale = Vector3(0.8, 0.8, 1.2)
	body.position.y = body_radius
	_visual.add_child(body)
	var wing_mat := Fx.mat(body_color.darkened(0.25))
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * body_radius * 0.6, body_radius * 1.1, 0.0)
		var wing := Fx.box(Vector3(0.55, 0.03, 0.4), wing_mat)
		wing.position.x = side * 0.3
		pivot.add_child(wing)
		_visual.add_child(pivot)
		_wings.append(pivot)
	var eye_mat := Fx.mat(Color(1.0, 0.35, 0.3), 2.0, true)
	for x in [-0.07, 0.07]:
		var eye := Fx.sphere(0.04, eye_mat)
		eye.position = Vector3(x, body_radius * 1.2, -body_radius * 0.9)
		_visual.add_child(eye)


# ---------------------------------------------------------------- sentidos

func hears(p: Player) -> bool:
	var d := flat_dist_to(p)
	if asleep:
		return d <= 1.5
	var moving := Vector2(p.velocity.x, p.velocity.z).length() > 0.8
	if moving and d <= maxf(HEAR_RANGE, p.noise_radius() * 1.3):
		return true
	return d <= STILL_RANGE


func notices_player(p: Player) -> bool:
	return hears(p)


func keeps_tracking(p: Player) -> bool:
	## Caça pelo som: enquanto você se mexe, ele sabe onde você está. Parada, ele perde.
	if p == null or p.dead or flat_dist_to(p) > 24.0:
		return false
	return Vector2(p.velocity.x, p.velocity.z).length() > 0.8


func sees_player_as_prey(p: Player) -> bool:
	return p.body_size() == 0   # o bando ataca qualquer coisa pequena; a Cavaleira já é grande demais


func is_threat(_o: Creature) -> bool:
	return false   # voando, ninguém do chão alcança


func _physics_process(delta: float) -> void:
	catch_immunity -= delta
	if not dead and not is_entangled():
		_check_strands()
	if asleep:
		hover_y = ROOST_Y + 0.4
	elif mode == Mode.ROOST:
		hover_y = ROOST_Y
	super._physics_process(delta)


# ---------------------------------------------------------------- combate com a jogadora

func combat_wants() -> bool:
	return player_memory > 0.0 or mode == Mode.WINDUP or mode == Mode.DIVE or mode == Mode.CLIMB


func combat_locked() -> bool:
	return mode == Mode.WINDUP or mode == Mode.DIVE


func combat_start() -> void:
	if mode == Mode.ROOST:
		mode = Mode.ALERT
		mode_time = 0.0
	GameState.say_once("morcegos_ouviram", "Eles me ouviram. Se eu ficar parada... será que somem?")


func combat_stop() -> void:
	mode = Mode.ROOST
	telegraph = false


func combat_tick(delta: float) -> Vector3:
	var p := GameState.player as Player
	if p == null or p.dead:
		mode = Mode.ROOST
		return Vector3.ZERO
	return dive_cycle(p, noticed_player, delta)


func dive_cycle(target: Node3D, heard: bool, delta: float) -> Vector3:
	## Rodear o alvo no alto → aviso (brilho) → mergulho com mordida → subir.
	## Serve para a jogadora e para larvas.
	mode_time += delta
	dive_cd -= delta
	if mode == Mode.ROOST:
		mode = Mode.ALERT
		mode_time = 0.0
	match mode:
		Mode.ALERT:
			hover_y = ALERT_Y
			screech_cd -= delta
			var pl := target as Player
			if pl != null and heard and screech_cd <= 0.0 and flat_dist_to(pl) < SCREECH_RANGE and randf() < delta * 1.5:
				_screech(pl)
			if dive_cd <= 0.0 and heard and _divers() < MAX_DIVERS:
				mode = Mode.WINDUP
				mode_time = 0.0
				telegraph = true
				return Vector3.ZERO
			return _orbit(target.global_position if heard else last_player_pos, 3.2, 1.0, delta)
		Mode.WINDUP:
			hover_y = ALERT_Y + 0.3
			face_toward(target.global_position)
			show_marker(_tele_dive, target.global_position, mode_time / 0.45)
			if mode_time >= 0.45:
				hide_marker()
				telegraph = false
				var pv := Vector3.ZERO
				if target is CharacterBody3D:
					pv = (target as CharacterBody3D).velocity
					pv.y = 0.0
				dive_target = target.global_position + pv * DIVE_LEAD
				mode = Mode.DIVE
				mode_time = 0.0
				bit = false
			return Vector3.ZERO
		Mode.DIVE:
			hover_y = DIVE_Y
			var follow := target.global_position - dive_target
			follow.y = 0.0
			dive_target += follow.limit_length(DIVE_HOMING * delta)
			if not bit and Fx.flat_dist(global_position, target.global_position) < 1.0 and global_position.y < 1.4:
				var p := target as Player
				if p != null:
					if p.state != Player.State.DODGE:
						bit = true
						p.take_damage(BITE_DAMAGE, self, false)
				elif target.has_method("take_damage"):
					bit = true
					target.take_damage(PREY_DAMAGE, self)
			var to := dive_target - global_position
			to.y = 0.0
			if to.length() < 0.4 or mode_time > 1.3 or bit:
				mode = Mode.CLIMB
				mode_time = 0.0
				return safe_dir(-to) * speed
			# desce primeiro, acelera quando já está baixo
			var low := clampf((ALERT_Y + 0.3 - global_position.y) / (ALERT_Y + 0.3 - DIVE_Y), 0.35, 1.0)
			return safe_dir(to) * DIVE_SPEED * low
		Mode.CLIMB:
			hover_y = ALERT_Y
			if mode_time > 0.8:
				mode = Mode.ALERT
				dive_cd = randf_range(2.2, 4.0)
			return safe_dir(facing) * speed * 0.8
	return Vector3.ZERO


func _screech(p: Player) -> void:
	## Grito sônico: atordoa (anda devagar) e chama todo predador por perto até você.
	screech_cd = randf_range(7.0, 11.0)
	_flash = 0.25
	Fx.beam(get_parent(), global_position, p.global_position + Vector3.UP * 0.3, Color(0.75, 0.6, 1.0), 0.3, 0.05)
	p.apply_slow(0.55, 1.6)
	for c in World.near(p.global_position, 16.0):
		var cr := c as Creature
		if cr != null and cr != self and cr.aggression > 0.0 and not cr.dead:
			cr.last_player_pos = p.global_position
			cr.player_memory = maxf(cr.player_memory, cr.memory_time * 0.5)
			cr.asleep = false
			if cr.brain != null:
				cr.brain.wake_up()
	if near_player:
		EventBus.message.emit("Um Morcego-eco gritou: tudo por perto sabe onde você está!")
		GameState.say_once("morcego_grito", "AAH, meus ouvidos! ...E agora a caverna inteira sabe onde eu tô.")


func _orbit(center: Vector3, radius: float, mult: float, delta: float) -> Vector3:
	orbit_angle += delta * (1.6 if mult > 0.7 else 0.9)
	var target := center + Vector3(cos(orbit_angle) * radius, 0.0, sin(orbit_angle) * radius)
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.2:
		return Vector3.ZERO
	var d := safe_dir(to)
	if d == Vector3.ZERO:
		d = safe_dir(center - global_position)
	return d * speed * mult


func _divers() -> int:
	var n := 0
	for b in World.near(global_position, 16.0):
		var bat := b as Bat
		if bat != null and bat != self and (bat.mode == Mode.WINDUP or bat.mode == Mode.DIVE):
			n += 1
	return n


# ---------------------------------------------------------------- bando

func pick_roam_destination() -> Variant:
	## O primeiro do bando a ficar inquieto escolhe o destino; os outros vão junto.
	var now := Time.get_ticks_msec() / 1000.0
	var f: Dictionary = World.flocks.get(flock, {})
	# destino novo se não há um em andamento, ou se este morcego já chegou nele (viagem velha)
	if f.is_empty() or now > float(f["until"]) or Fx.flat_dist(f["dest"], anchor) < 4.0 or Fx.flat_dist(f["dest"], global_position) < 4.0:
		var dest = super.pick_roam_destination()
		if dest == null:
			return null
		f = {"dest": dest, "until": now + 20.0}
		World.flocks[flock] = f
		for b in World.creatures:
			var mate := b as Bat
			if mate != null and mate != self and mate.flock == flock:
				mate.needs.restless = 100.0
	var off := Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0))
	return (f["dest"] as Vector3) + off


# ---------------------------------------------------------------- fios

func _check_strands() -> void:
	if catch_immunity > 0.0:
		return
	for s in WebNetwork.strands:
		if is_instance_valid(s) and s.distance_to(global_position) < 0.45:
			entangle(5.0)
			catch_immunity = 7.0   # cobre o tempo enredado + 2 s depois de soltar
			mode = Mode.ALERT
			EventBus.web_touched.emit(global_position, self)
			EventBus.message.emit("Um Morcego-eco bateu no fio e caiu!")
			GameState.say_once("morcego_no_fio", "Fio esticado no caminho... e lá vem o jantar voando direto nele.")
			return


func _on_hurt(_source: Node3D) -> void:
	if mode == Mode.ROOST:
		mode = Mode.ALERT


func _animate(_delta: float, _speed_now: float) -> void:
	var flap := 0.0 if is_entangled() else sin(_anim_t * 22.0) * 0.7
	if asleep:
		flap = -1.2   # asas fechadas, pendurado
	for i in _wings.size():
		_wings[i].rotation.z = flap * (1.0 if i == 0 else -1.0)


class HuntLarva extends Behavior:
	## Na hora da caça, mergulha nas larvas que ouve lá embaixo.
	var prey: Larva = null

	func _init() -> void:
		id = "hunt"
		label = "Caçando larvas"

	func utility(c: Creature) -> float:
		if c.needs.hunger < c.hunger_threshold:
			return 0.0
		if prey == null or not is_instance_valid(prey) or prey.dead:
			prey = World.nearest(c.global_position, 12.0, func(o): return o is Larva) as Larva
		return 0.0 if prey == null else c.needs.hunger / 100.0 * 0.8

	func locked(c: Creature) -> bool:
		var b := c as Bat
		return b.mode == Bat.Mode.WINDUP or b.mode == Bat.Mode.DIVE

	func stop(c: Creature) -> void:
		(c as Bat).mode = Bat.Mode.ROOST
		c.telegraph = false

	func run(c: Creature, delta: float) -> Vector3:
		var b := c as Bat
		if prey == null or not is_instance_valid(prey) or prey.dead:
			if prey != null:
				b.needs.hunger = maxf(0.0, b.needs.hunger - 60.0)
			prey = null
			b.mode = Bat.Mode.ROOST
			return Vector3.ZERO
		return b.dive_cycle(prey, true, delta)


class Circle extends Behavior:
	## Voa em círculos sobre o ponto de referência (poleiro ou lugar onde o bando chegou).
	func _init() -> void:
		id = "circle"
		label = "Voando em círculos"

	func utility(_c: Creature) -> float:
		return 0.1

	func run(c: Creature, delta: float) -> Vector3:
		var b := c as Bat
		b.mode = Bat.Mode.ROOST
		return b._orbit(b.anchor, 3.0, 0.5, delta)
