class_name Centipede
extends Creature
## Centopeia-blindada (G, chefe das Galerias).
##
## Sente VIBRAÇÃO: percebe quem anda no chão (correr vibra mais). Quem está sobre um fio
## ou parada não vibra. Ataques: mordida de perto e investida em linha reta.
## A carapaça segura 90% do dano e o veneno não entra. Ela só cede quando a Centopeia
## está ENREDADA, e isso só acontece quando ela investe ATRAVÉS de um fio esticado
## (o fio arrebenta). Na metade da vida ela se enfurece: investe mais rápido e com aviso menor.

enum Mode { SLEEP, PATROL, HUNT, WINDUP, CHARGE, RECOVER, BITE }

const SEGMENTS := 12
const SPACING := 1.05
const SENSE_RANGE := 18.0
const CHARGE_SPEED := 13.0
const CHARGE_TIME := 1.3
const BITE_DAMAGE := 20.0
const CHARGE_DAMAGE := 22.0
const ARMOR := 0.1
const TANGLE_TIME := 4.5

var arena_center := Vector3.ZERO
var arena_radius := 9.0
var mode: Mode = Mode.SLEEP
var mode_time := 0.0
var last_heard := Vector3.ZERO
var memory := 0.0
var charge_dir := Vector3.FORWARD
var phase := 1
var attack_done := false
var _patrol_angle := 0.0
var _trail: Array[Vector3] = []
var _segs: Array[Node3D] = []
var _armor_msg_cd := 0.0


func _init() -> void:
	display_name = "Centopeia-blindada"
	size = Size.G
	level = 12
	max_hp = 360.0
	speed = 3.4
	body_radius = 0.9
	body_color = Color(0.36, 0.4, 0.48)
	food_satiety = 100.0
	food_silk = 60.0
	food_xp = 220
	food_skin = true
	senses_text = "vibração (18 m): sente quem anda no chão; sobre um fio ou parada, você não vibra"
	model_name = "centopeia_cabeca"
	model_size = 2.2
	model_fit = "length"


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	add_to_group("predator")
	collision_mask = 1   # atravessa a jogadora na investida (o dano é pelo contato)
	facing = Vector3(0, 0, -1)
	_build_segments()
	_reset_trail()


func _build_visual() -> void:
	var head := Fx.sphere(body_radius, _mat)
	head.scale = Vector3(1.1, 0.6, 1.2)
	head.position.y = body_radius * 0.6
	_visual.add_child(head)
	var jaw_mat := Fx.mat(Color(0.75, 0.6, 0.3), 0.3)
	for side in [-1.0, 1.0]:
		var jaw := Fx.box(Vector3(0.12, 0.12, 0.8), jaw_mat)
		jaw.position = Vector3(side * 0.45, body_radius * 0.5, -body_radius * 1.2)
		jaw.rotation.y = side * 0.35
		_visual.add_child(jaw)
	var eye_mat := Fx.mat(Color(0.6, 0.9, 1.0), 2.0, true)
	for side in [-1.0, 1.0]:
		var eye := Fx.sphere(0.12, eye_mat)
		eye.position = Vector3(side * 0.4, body_radius * 0.95, -body_radius * 0.8)
		_visual.add_child(eye)


func _build_segments() -> void:
	var leg_mat := Fx.mat(body_color.darkened(0.35))
	for i in SEGMENTS:
		var seg := Node3D.new()
		seg.top_level = true
		var k := 1.0 - float(i) / SEGMENTS * 0.45
		var model_name_seg := "centopeia_cauda" if i == SEGMENTS - 1 else "centopeia_segmento"
		var m := Models.instance(model_name_seg, 1.6 * k, "max")
		if m != null:
			seg.add_child(m)
		else:
			var shell := Fx.sphere(0.8 * k, _mat)
			shell.scale = Vector3(1.15, 0.55, 0.8)
			shell.position.y = 0.5 * k
			seg.add_child(shell)
			for side in [-1.0, 1.0]:
				var leg := Fx.box(Vector3(0.9 * k, 0.08, 0.1), leg_mat)
				leg.position = Vector3(side * 0.85 * k, 0.2, 0.0)
				leg.rotation.z = side * -0.4
				seg.add_child(leg)
		add_child(seg)
		_segs.append(seg)


func _reset_trail() -> void:
	_trail.clear()
	var back := -facing
	for i in int(SEGMENTS * SPACING / 0.15) + 10:
		_trail.append(global_position + back * (i * 0.15))
	_place_segments()


# ---------------------------------------------------------------- sentidos

func feels(p: Player) -> bool:
	if p == null or p.dead or p.on_strand:
		return false
	var spd := Vector2(p.velocity.x, p.velocity.z).length()
	var d := flat_dist_to(p)
	if spd < 0.8:
		return d < 2.0
	var r := SENSE_RANGE if spd > Player.WALK_SPEED + 0.5 else SENSE_RANGE * 0.75
	return d <= r


# ---------------------------------------------------------------- comportamento

func wake() -> void:
	if mode == Mode.SLEEP:
		mode = Mode.PATROL
		mode_time = 0.0


func reset() -> void:
	hp = max_hp
	phase = 1
	poison_stacks = 0
	entangled_time = 0.0
	_web_overlay.visible = false
	telegraph = false
	mode = Mode.SLEEP
	global_position = home
	velocity = Vector3.ZERO
	external_velocity = Vector3.ZERO
	facing = Vector3(0, 0, -1)
	_reset_trail()


func _think(delta: float) -> Vector3:
	mode_time += delta
	_armor_msg_cd -= delta
	if mode == Mode.SLEEP:
		return Vector3.ZERO
	var p := GameState.player as Player
	if feels(p):
		last_heard = p.global_position
		memory = 3.0
	else:
		memory -= delta
	var windup := 0.8 if phase == 1 else 0.55
	var mult := 1.0 if phase == 1 else 1.25

	match mode:
		Mode.PATROL:
			if memory > 0.0:
				mode = Mode.HUNT
				mode_time = 0.0
				return Vector3.ZERO
			_patrol_angle += delta * 0.35
			var target := arena_center + Vector3(cos(_patrol_angle), 0.0, sin(_patrol_angle)) * arena_radius * 0.6
			return move_to(target, 0.6)
		Mode.HUNT:
			if memory <= 0.0:
				mode = Mode.PATROL
				return Vector3.ZERO
			face_toward(last_heard)
			var d := Fx.flat_dist(global_position, last_heard)
			if p != null and not p.dead and flat_dist_to(p) < 2.6:
				_begin(Mode.BITE)
				return Vector3.ZERO
			if d > 3.5 and d < 12.0 and mode_time > 0.7 and has_line_of_sight(p):
				_begin(Mode.WINDUP)
				return Vector3.ZERO
			return move_to(last_heard, 1.0 * mult)
		Mode.WINDUP:
			if memory > 0.0:
				face_toward(last_heard)
			if mode_time >= windup:
				telegraph = false
				charge_dir = facing
				mode = Mode.CHARGE
				mode_time = 0.0
				attack_done = false
			return Vector3.ZERO
		Mode.CHARGE:
			if mode_time > CHARGE_TIME:
				_end_charge(0.6)
				return Vector3.ZERO
			if p != null and not p.dead and not attack_done and flat_dist_to(p) < body_radius + 0.9:
				attack_done = true
				p.take_damage(CHARGE_DAMAGE, self)
			return charge_dir * CHARGE_SPEED * mult
		Mode.RECOVER:
			if mode_time < 0.0:
				return Vector3.ZERO
			mode = Mode.HUNT if memory > 0.0 else Mode.PATROL
			mode_time = 0.0
			return Vector3.ZERO
		Mode.BITE:
			if p != null:
				face_toward(p.global_position)
			if not attack_done and mode_time >= 0.5:
				attack_done = true
				telegraph = false
				if p != null and not p.dead and flat_dist_to(p) <= 3.0:
					p.take_damage(BITE_DAMAGE, self)
			if mode_time >= 0.9:
				mode = Mode.HUNT
				mode_time = 0.0
			return Vector3.ZERO
	return Vector3.ZERO


func _begin(m: Mode) -> void:
	mode = m
	mode_time = 0.0
	attack_done = false
	telegraph = true


func _end_charge(pause: float) -> void:
	telegraph = false
	mode = Mode.RECOVER
	mode_time = -pause   # RECOVER termina quando mode_time passa de 0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if dead:
		return
	if mode == Mode.CHARGE and not is_entangled():
		_check_strands()
		var real := get_real_velocity()
		if mode_time > 0.25 and Vector2(real.x, real.z).length() < 3.0:
			_end_charge(1.2)
			EventBus.message.emit("A Centopeia bateu de cabeça na parede!")
	_update_trail()


func _check_strands() -> void:
	for s in WebNetwork.strands.duplicate():
		if is_instance_valid(s) and s.distance_to(global_position) < 1.1:
			WebNetwork.remove_strand(s)
			entangle(TANGLE_TIME)
			_end_charge(0.4)   # enredada ela já fica parada; o _think nem roda até soltar
			EventBus.web_touched.emit(global_position, self)
			EventBus.big_message.emit("Enredada! A carapaça abriu!")
			GameState.say_once("centopeia_enredada", "Isso! Ela se enroscou! AGORA!")
			return


# ---------------------------------------------------------------- dano

func take_damage(amount: float, source: Node3D = null) -> void:
	if dead:
		return
	if not is_entangled():
		amount *= ARMOR
		if _armor_msg_cd <= 0.0 and source != null and source.is_in_group("player"):
			_armor_msg_cd = 6.0
			EventBus.message.emit("A carapaça segura o golpe. Faça a Centopeia investir através de um fio esticado!")
	super.take_damage(amount, source)
	if not dead and phase == 1 and hp <= max_hp * 0.5:
		phase = 2
		EventBus.big_message.emit("A Centopeia se enfurece!")
		GameState.say_once("centopeia_furia", "Ah, ótimo. Agora ela está BRAVA.")


func add_poison() -> void:
	if is_entangled():
		super.add_poison()


func _on_hurt(source: Node3D) -> void:
	if source != null and source.is_in_group("player"):
		last_heard = source.global_position
		memory = 3.0
		if mode == Mode.PATROL or mode == Mode.SLEEP:
			mode = Mode.HUNT
			mode_time = 0.0


# ---------------------------------------------------------------- corpo

func _update_trail() -> void:
	var head := global_position
	if _trail.is_empty() or head.distance_to(_trail[0]) > 0.15:
		_trail.insert(0, head)
		var cap := int(SEGMENTS * SPACING / 0.15) + 12
		while _trail.size() > cap:
			_trail.pop_back()
	_place_segments()


func _place_segments() -> void:
	if _trail.size() < 2:
		return
	var wiggle := 0.0 if is_entangled() else _anim_t * 10.0
	for i in _segs.size():
		var want := (i + 1) * SPACING
		var acc := 0.0
		var pos := _trail[_trail.size() - 1]
		var dir := Vector3.FORWARD
		for j in _trail.size() - 1:
			var a := _trail[j]
			var b := _trail[j + 1]
			var seg_len := a.distance_to(b)
			if acc + seg_len >= want:
				pos = a.lerp(b, (want - acc) / maxf(seg_len, 0.001))
				dir = a - b
				break
			acc += seg_len
		var seg := _segs[i]
		seg.global_position = Vector3(pos.x, maxf(pos.y, 0.0), pos.z)
		if Vector2(dir.x, dir.z).length() > 0.01:
			seg.rotation = Vector3(0.0, atan2(-dir.x, -dir.z), sin(wiggle - i * 0.7) * 0.12)


func die(fell: bool = false) -> void:
	for s in _segs:
		if is_instance_valid(s):
			s.queue_free()
	super.die(fell)


func _animate(_delta: float, _speed_now: float) -> void:
	pass
