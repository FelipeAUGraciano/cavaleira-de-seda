class_name Snake
extends Creature
## Cobra-das-frestas (M, vibração): mora num buraco na parede e não sai dele.
## Escondida, só os dois olhos brilham. Sente pelo chão quem ANDA perto (parada, ou andando
## devagar no escuro, você passa); aí dá um bote longo e rápido em linha — a marca no chão
## avisa — e fica exposta uns segundos antes de voltar para o buraco. É a hora de bater.
## O bote arrebenta qualquer fio-guia por onde passa.

const FEEL := 6.0              ## sente quem anda a esta distância
const STRIKE_REACH := 6.0

var out_dir := Vector3(0, 0, 1)    ## para onde a boca do buraco olha
var _extend := 0.0                 ## 0 escondida, 1 esticada no bote
var _neck: Array = []
var _eyes: Node3D
var _head: Node3D


func _init() -> void:
	display_name = "Cobra-das-frestas"
	size = Size.M
	level = 6
	max_hp = 70.0
	speed = 2.0
	body_radius = 0.45
	body_color = Color(0.3, 0.36, 0.22)
	food_satiety = 55.0
	food_silk = 25.0
	food_xp = 70
	senses_text = "vibração no chão (6 m): parada ou devagar no escuro, você passa"
	rest_phase = CaveClock.Phase.BRILHO
	aggression = 1.0
	uses_interest = false       # emboscada: não persegue, só dá o bote
	memory_time = 2.5
	search_time = 0.0
	sleep_heal = 0.03
	combat_label = "Dando o bote"
	add_attack(Attack.make("bote", "Bote da fresta", {"max_range": STRIKE_REACH, "min_range": 1.6, "windup": 0.4,
		"active": 0.15, "recover": 1.6, "cooldown": 2.6, "damage": 28.0, "shape": Attack.Shape.LINE,
		"reach": STRIKE_REACH, "width": 1.0, "weight": 3.0}))
	add_attack(Attack.make("mordida", "Mordida", {"max_range": 1.9, "windup": 0.35, "active": 0.15, "recover": 0.8,
		"cooldown": 1.4, "damage": 18.0, "reach": 1.9, "arc": 110.0, "weight": 3.0}))


func _ready() -> void:
	super._ready()
	add_to_group("predator")
	facing = out_dir


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Dando o bote")) \
		.add(Lurk.new())


func _build_visual() -> void:
	var dark := Fx.mat(body_color.darkened(0.35))
	for i in 7:
		var seg := Fx.sphere(body_radius * (0.75 - i * 0.04), _mat if i % 2 == 0 else dark)
		seg.position = Vector3(0.0, body_radius * 0.7, 0.0)
		_visual.add_child(seg)
		_neck.append(seg)
	_head = Fx.sphere(body_radius * 0.8, _mat)
	_head.scale = Vector3(1.0, 0.7, 1.4)
	_visual.add_child(_head)
	_eyes = Node3D.new()
	_visual.add_child(_eyes)
	var eye_mat := Fx.mat(Color(1.0, 0.85, 0.2), 2.5)
	for x in [-0.16, 0.16]:
		var eye := Fx.sphere(0.07, eye_mat)
		eye.position = Vector3(x, 0.0, -0.25)
		_eyes.add_child(eye)


func _animate(delta: float, _speed_now: float) -> void:
	var want := 0.15
	if cur_attack != null:
		want = 0.45 if atk_phase == 0 else (1.0 if cur_attack.id == "bote" else 0.6)
		if atk_phase == 2:
			want = lerpf(1.0 if cur_attack.id == "bote" else 0.6, 0.45, clampf(atk_t / 0.4, 0.0, 1.0))
	elif player_memory > 0.0:
		want = 0.35
	_extend = move_toward(_extend, want, delta * (14.0 if want > _extend else 2.5))
	var reach := lerpf(0.3, STRIKE_REACH - 0.4, _extend)
	var rise := lerpf(-0.55, 0.15, minf(_extend * 3.0, 1.0))   # escondida: quase toda no chão
	for i in _neck.size():
		var t := float(i + 1) / float(_neck.size() + 1)
		var wave := sin(_anim_t * 6.0 + i) * 0.12 * (1.0 - _extend)
		(_neck[i] as Node3D).position = Vector3(wave, body_radius * 0.6 + rise, -reach * t)
	_head.position = Vector3(0.0, body_radius * 0.7 + rise, -reach)
	_eyes.position = _head.position + Vector3(0.0, 0.18 - minf(rise, 0.0) * 0.9, 0.0)


# ---------------------------------------------------------------- sentidos e bote

func notices_player(p: Player) -> bool:
	var d := flat_dist_to(p)
	if d < body_radius + 1.2:
		return true
	if asleep:
		return false
	if p.on_strand:
		return d < FEEL + 1.5          # fio esticado vibra muito
	if p.is_quiet():
		return false
	var feel := FEEL if (p.rune_on or Vector2(p.velocity.x, p.velocity.z).length() > 2.5) else FEEL * 0.55
	return d < feel


func combat_wants() -> bool:
	return cur_attack != null or player_memory > 0.0


func combat_tick(delta: float) -> Vector3:
	var p := GameState.player as Player
	if cur_attack != null:
		return attack_tick(delta, p)
	if Fx.flat_dist(global_position, den) > 0.6:
		return nav_to(den, 0.8)       # foi empurrada: volta para o buraco
	if p == null or p.dead or not noticed_player:
		return Vector3.ZERO
	if atk_gap <= 0.0:
		var a := pick_attack(p)
		if a != null:
			start_attack(a, p)
	return Vector3.ZERO


func on_attack_active(a: Attack) -> void:
	if a.id != "bote":
		return
	# o bote passa rasgando: fio-guia no caminho arrebenta
	for s in WebNetwork.strands.duplicate():
		if not is_instance_valid(s):
			continue
		for k in 13:
			var pt := global_position + facing * (STRIKE_REACH * k / 12.0)
			if s.distance_to(pt) < 0.6:
				WebNetwork.remove_strand(s)
				EventBus.web_touched.emit(pt, self)
				break


func is_threat(_o: Creature) -> bool:
	return false   # dentro do buraco ela não tem medo de nada


func sees_player_as_prey(_p: Player) -> bool:
	return false


class Lurk extends Behavior:
	## Fica no buraco, de olho na boca da fresta.
	func _init() -> void:
		id = "lurk"
		label = "Escondida na fresta"

	func utility(_c: Creature) -> float:
		return 0.2

	func run(c: Creature, _delta: float) -> Vector3:
		var s := c as Snake
		if Fx.flat_dist(c.global_position, c.den) > 0.4:
			return c.nav_to(c.den, 0.6)
		s.facing = s.facing.lerp(s.out_dir, 0.1).normalized()
		return Vector3.ZERO


func can_raid() -> bool:
	return false
