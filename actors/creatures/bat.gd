class_name Bat
extends Creature
## Morcego-eco (P, bando): voa alto e caça pelo som.
## Ouve quem se MEXE (a runa apagada não ajuda; ficar parada, sim). Ataca em mergulhos,
## no máximo dois de cada vez. No alto, a mordida não alcança: só durante o mergulho.
## Fio esticado no caminho (ou fio lançado com Q) prende o morcego no ar e ele cai.

enum Mode { ROOST, ALERT, WINDUP, DIVE, CLIMB }

const HEAR_RANGE := 10.0
const STILL_RANGE := 1.8        ## parada, só é ouvida muito perto
const ROOST_Y := 2.6
const ALERT_Y := 2.3
const DIVE_Y := 0.45
const DIVE_SPEED := 9.5
const DIVE_HOMING := 3.5        ## m/s que o alvo do mergulho segue a jogadora (esquiva ainda escapa)
const BITE_DAMAGE := 5.0
const MAX_DIVERS := 2

var mode: Mode = Mode.ROOST
var mode_time := 0.0
var dive_cd := 0.0
var memory := 0.0
var dive_target := Vector3.ZERO
var orbit_angle := 0.0
var bit := false
var catch_immunity := 0.0
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


func _ready() -> void:
	super._ready()
	add_to_group("flyer")
	add_to_group("bat")
	collision_mask = 1 | 4
	orbit_angle = randf() * TAU
	dive_cd = randf_range(0.8, 3.0)
	position.y = ROOST_Y


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


func hears(p: Player) -> bool:
	var d := flat_dist_to(p)
	var moving := Vector2(p.velocity.x, p.velocity.z).length() > 0.8
	if moving and d <= maxf(HEAR_RANGE, p.noise_radius() * 1.3):
		return true
	return d <= STILL_RANGE


func _think(delta: float) -> Vector3:
	mode_time += delta
	dive_cd -= delta
	catch_immunity -= delta
	_check_strands()
	if is_entangled():
		return Vector3.ZERO

	var p := GameState.player as Player
	var heard := p != null and not p.dead and hears(p)
	if heard:
		memory = 4.0
	else:
		memory -= delta

	match mode:
		Mode.ROOST:
			hover_y = ROOST_Y
			if heard:
				mode = Mode.ALERT
				mode_time = 0.0
				GameState.say_once("morcegos_ouviram", "Eles me ouviram. Se eu ficar parada... será que somem?")
			return _orbit(home, 3.0, 0.5, delta)
		Mode.ALERT:
			hover_y = ALERT_Y
			if memory <= 0.0 or p == null or p.dead:
				mode = Mode.ROOST
				return Vector3.ZERO
			if dive_cd <= 0.0 and heard and _divers() < MAX_DIVERS:
				mode = Mode.WINDUP
				mode_time = 0.0
				telegraph = true
				return Vector3.ZERO
			var center := p.global_position if heard else home
			return _orbit(center, 3.2, 1.0, delta)
		Mode.WINDUP:
			hover_y = ALERT_Y + 0.3
			if p != null:
				face_toward(p.global_position)
			if mode_time >= 0.45:
				telegraph = false
				if p == null or p.dead:
					mode = Mode.ALERT
					return Vector3.ZERO
				dive_target = p.global_position
				mode = Mode.DIVE
				mode_time = 0.0
				bit = false
			return Vector3.ZERO
		Mode.DIVE:
			hover_y = DIVE_Y
			if p != null and not p.dead:
				var follow := p.global_position - dive_target
				follow.y = 0.0
				dive_target += follow.limit_length(DIVE_HOMING * delta)
				if not bit and Fx.flat_dist(global_position, p.global_position) < 1.0 and global_position.y < 1.4 and p.state != Player.State.DODGE:
					bit = true
					p.take_damage(BITE_DAMAGE, self, false)
			var to := dive_target - global_position
			to.y = 0.0
			if to.length() < 0.4 or mode_time > 1.3 or bit:
				mode = Mode.CLIMB
				mode_time = 0.0
				return _fly_dir(-to) * speed
			# desce primeiro, acelera quando já está baixo
			var low := clampf((ALERT_Y + 0.3 - global_position.y) / (ALERT_Y + 0.3 - DIVE_Y), 0.35, 1.0)
			return _fly_dir(to) * DIVE_SPEED * low
		Mode.CLIMB:
			hover_y = ALERT_Y
			if mode_time > 0.8:
				mode = Mode.ALERT
				dive_cd = randf_range(2.2, 4.0)
			return _fly_dir(facing) * speed * 0.8
	return Vector3.ZERO


func _orbit(center: Vector3, radius: float, mult: float, delta: float) -> Vector3:
	orbit_angle += delta * (1.6 if mult > 0.7 else 0.9)
	var target := center + Vector3(cos(orbit_angle) * radius, 0.0, sin(orbit_angle) * radius)
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.2:
		return Vector3.ZERO
	return _fly_dir(to) * speed * mult


func _fly_dir(dir: Vector3) -> Vector3:
	## Voa por cima de chão e abismos, mas não sai da caverna por cima das paredes baixas.
	dir.y = 0.0
	if dir.length() < 0.01:
		return Vector3.ZERO
	dir = dir.normalized()
	var ahead := global_position + dir * 0.9
	var layer = GameState.current_layer
	if layer != null and "cave" in layer and layer.get("cave") != null:
		if (layer.get("cave") as CaveBuilder).open_at(Vector2(ahead.x, ahead.z)) < 0.8:
			return Vector3.ZERO
		return dir
	var q := PhysicsRayQueryParameters3D.create(Vector3(ahead.x, 4.0, ahead.z), Vector3(ahead.x, -1.0, ahead.z), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or float(hit["position"].y) > 0.25:
		return Vector3.ZERO
	return dir


func _divers() -> int:
	var n := 0
	for b in get_tree().get_nodes_in_group("bat"):
		var bat := b as Bat
		if bat != null and bat != self and not bat.dead and (bat.mode == Mode.WINDUP or bat.mode == Mode.DIVE):
			n += 1
	return n


func _check_strands() -> void:
	if is_entangled() or catch_immunity > 0.0:
		return
	for s in WebNetwork.strands:
		if is_instance_valid(s) and s.distance_to(global_position) < 0.45:
			entangle(5.0)
			catch_immunity = 2.0   # só conta depois de soltar
			mode = Mode.ALERT
			EventBus.web_touched.emit(global_position, self)
			EventBus.message.emit("Um Morcego-eco bateu no fio e caiu!")
			GameState.say_once("morcego_no_fio", "Fio esticado no caminho... e lá vem o jantar voando direto nele.")
			return


func _on_hurt(_source: Node3D) -> void:
	memory = 5.0
	if mode == Mode.ROOST:
		mode = Mode.ALERT


func _animate(_delta: float, _speed_now: float) -> void:
	var flap := 0.0 if is_entangled() else sin(_anim_t * 22.0) * 0.7
	for i in _wings.size():
		_wings[i].rotation.z = flap * (1.0 if i == 0 else -1.0)
