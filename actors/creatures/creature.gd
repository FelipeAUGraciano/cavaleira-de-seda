class_name Creature
extends CharacterBody3D
## Base das criaturas da caverna: vida, status (veneno, enredado), sentidos, morte e cadáver.
## Cada espécie sobrescreve _think() (decisão) e _build_visual() (aparência).

enum Size { P, M, G, COLOSSAL }
const SIZE_NAMES := ["P", "M", "G", "Colossal"]
const GRAVITY := 20.0
const POISON_DPS_PER_STACK := 2.0
const POISON_DURATION := 5.0
const MAX_POISON := 5

# Ficha da espécie (definida no _init de cada subclasse)
var display_name := "Criatura"
var size: Size = Size.P
var level := 1
var max_hp := 20.0
var speed := 3.0
var body_radius := 0.4
var body_color := Color(0.5, 0.5, 0.5)
var food_satiety := 20.0
var food_silk := 10.0
var food_xp := 10
var senses_text := "?"
var food_energy := 0.0       ## bônus permanente de Energia máx. ao comer (Lagarto-lanterna)

# Modelo 3D (systems/models.gd): troca as formas cinza quando o .glb existir
var model_name := ""
var model_size := 0.0        ## 0 = body_radius * 2.5
var model_fit := "max"
var model_lift := 0.0        ## sobe o modelo (corpos sem patas ficam acima do chão)
var model_tint := Color(1, 1, 1)  ## multiplica as cores do modelo (ex.: irmã faminta mais vermelha)
var hover_y := -1.0         ## >= 0: voa nessa altura (morcegos). Enredado, cai.

# Estado
var hp := 0.0
var dead := false
var poison_stacks := 0
var poison_time := 0.0
var entangled_time := 0.0
var slow_mult := 1.0
var slow_time := 0.0
var telegraph := false   ## brilho amarelo = vai atacar
var external_velocity := Vector3.ZERO
var home := Vector3.ZERO
var facing := Vector3(0, 0, -1)

var _wander_target := Vector3.ZERO
var _wander_timer := 0.0
var _visual: Node3D
var _mat: StandardMaterial3D
var _web_overlay: MeshInstance3D
var _flash := 0.0
var _anim_t := 0.0
var _last_attacker: Node = null
var _model: Node3D
var _body_parts: Array = []  ## formas cinza que o modelo substitui (vazio = todas do _visual)
var _overlay: StandardMaterial3D


func _ready() -> void:
	add_to_group("creature")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	hp = max_hp
	home = global_position
	var ang := randf() * TAU
	facing = Vector3(cos(ang), 0.0, sin(ang))
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = body_radius
	cs.shape = shape
	cs.position.y = body_radius
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	_mat = Fx.mat(body_color)
	_build_visual()
	_apply_model()
	_web_overlay = Fx.sphere(body_radius * 1.3, Fx.mat(Color(0.9, 0.95, 1.0), 0.6, true, 0.45))
	_web_overlay.position.y = body_radius
	_web_overlay.visible = false
	add_child(_web_overlay)
	_pick_wander_target()


func _build_visual() -> void:
	var body := Fx.sphere(body_radius, _mat)
	body.position.y = body_radius
	_visual.add_child(body)


func _apply_model() -> void:
	var parts: Array = _body_parts if not _body_parts.is_empty() else _visual.get_children()
	var sz := model_size if model_size > 0.0 else body_radius * 2.5
	_model = Models.swap(_visual, model_name, sz, parts, model_fit)
	if _model == null:
		return
	_model.position.y = model_lift
	_overlay = StandardMaterial3D.new()
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.albedo_color = Color(0, 0, 0, 0)
	Models.set_overlay(_model, _overlay)
	if model_tint != Color(1, 1, 1):
		Models.tint(_model, model_tint)


func _think(_delta: float) -> Vector3:
	## Devolve a velocidade horizontal desejada. Subclasses decidem o comportamento.
	return Vector3.ZERO


func _on_hurt(_source: Node3D) -> void:
	pass


func _animate(_delta: float, _speed_now: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if dead:
		return
	_tick_status(delta)
	if dead:
		return
	var desired := Vector3.ZERO
	if entangled_time <= 0.0:
		desired = _think(delta) * slow_mult
	else:
		telegraph = false
	velocity.x = desired.x + external_velocity.x
	velocity.z = desired.z + external_velocity.z
	if hover_y >= 0.0 and entangled_time <= 0.0:
		velocity.y = clampf((hover_y - global_position.y) * 6.0, -9.0, 7.0)
	elif is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= GRAVITY * delta
	external_velocity = external_velocity.move_toward(Vector3.ZERO, 18.0 * delta)
	move_and_slide()

	var flat := Vector3(desired.x, 0.0, desired.z)
	if flat.length() > 0.1:
		facing = flat.normalized()
	_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-facing.x, -facing.z), clampf(10.0 * delta, 0.0, 1.0))
	_anim_t += delta
	_animate(delta, flat.length())
	_update_glow(delta)
	if global_position.y < -5.0:
		die(true)


func _update_glow(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	if _overlay != null:
		if _flash > 0.0:
			_overlay.albedo_color = Color(1, 1, 1, 0.6)
		elif telegraph:
			_overlay.albedo_color = Color(1.0, 0.8, 0.1, 0.35 + 0.25 * sin(_anim_t * 30.0))
		else:
			_overlay.albedo_color = Color(0, 0, 0, 0)
	if _flash > 0.0:
		_mat.emission_enabled = true
		_mat.emission = Color(1, 1, 1)
		_mat.emission_energy_multiplier = 1.5
	elif telegraph:
		_mat.emission_enabled = true
		_mat.emission = Color(1.0, 0.8, 0.1)
		_mat.emission_energy_multiplier = 0.8 + 0.6 * sin(_anim_t * 30.0)
	else:
		_mat.emission_enabled = false


# ---------------------------------------------------------------- status

func _tick_status(delta: float) -> void:
	if poison_stacks > 0:
		poison_time -= delta
		_apply_damage(poison_stacks * POISON_DPS_PER_STACK * delta)
		if poison_time <= 0.0:
			poison_stacks = 0
	if entangled_time > 0.0:
		entangled_time -= delta
		if entangled_time <= 0.0:
			_web_overlay.visible = false
	if slow_time > 0.0:
		slow_time -= delta
		if slow_time <= 0.0:
			slow_mult = 1.0


func take_damage(amount: float, source: Node3D = null) -> void:
	if dead:
		return
	_last_attacker = source
	_flash = 0.12
	if source != null and entangled_time <= 0.0:
		var push := global_position - source.global_position
		push.y = 0.0
		if push.length() > 0.01:
			external_velocity += push.normalized() * (4.0 if size == Size.P else 1.5)
	_on_hurt(source)
	_apply_damage(amount)


func _apply_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0 and not dead:
		die(false)


func add_poison() -> void:
	poison_stacks = mini(poison_stacks + 1, MAX_POISON)
	poison_time = POISON_DURATION


func entangle(duration: float) -> void:
	entangled_time = maxf(entangled_time, duration)
	external_velocity = Vector3.ZERO
	telegraph = false
	_web_overlay.visible = true


func is_entangled() -> bool:
	return entangled_time > 0.0


func slow(mult: float, duration: float) -> void:
	slow_mult = mult
	slow_time = duration


func pull_toward(point: Vector3, strength: float) -> void:
	var d := point - global_position
	d.y = 0.0
	if d.length() > 0.1:
		external_velocity = d.normalized() * strength


func die(fell: bool = false) -> void:
	if dead:
		return
	dead = true
	if not fell:
		var corpse := Corpse.new()
		corpse.setup(display_name, food_satiety, food_silk, food_xp, body_color, body_radius)
		corpse.energy_bonus = food_energy
		get_parent().add_child(corpse)
		corpse.global_position = Vector3(global_position.x, maxf(global_position.y, 0.0), global_position.z)
		var killer: Player = null
		if is_instance_valid(_last_attacker):
			killer = _last_attacker as Player
		if killer != null:
			killer.gain_xp(int(food_xp / 2.0))
			EventBus.message.emit("Você derrotou: %s. Coma o corpo (E)." % display_name)
	EventBus.creature_died.emit(self)
	queue_free()


# ---------------------------------------------------------------- sentidos e movimento

func flat_dist_to(n: Node3D) -> float:
	return Fx.flat_dist(n.global_position, global_position)


func can_see(target: Node3D, range_: float, fov_deg: float) -> bool:
	var to := target.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > range_:
		return false
	if dist > 1.5 and rad_to_deg(facing.angle_to(to.normalized())) > fov_deg * 0.5:
		return false
	return has_line_of_sight(target)


func has_line_of_sight(target: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.6, target.global_position + Vector3.UP * 0.4, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func safe_dir(dir: Vector3) -> Vector3:
	## Evita andar para dentro de abismos: só segue se houver chão logo à frente.
	dir.y = 0.0
	if dir.length() < 0.01:
		return Vector3.ZERO
	var ahead := global_position + dir.normalized() * (body_radius + 0.7)
	var q := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 0.5, ahead + Vector3.DOWN * 1.5, 1)
	if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		return Vector3.ZERO
	return dir.normalized()


func move_to(pos: Vector3, mult: float) -> Vector3:
	var d := pos - global_position
	d.y = 0.0
	if d.length() < 0.8:
		return Vector3.ZERO
	return safe_dir(d) * speed * mult


func face_toward(pos: Vector3) -> void:
	var d := pos - global_position
	d.y = 0.0
	if d.length() > 0.05:
		facing = d.normalized()


func wander(delta: float, radius: float = 6.0, mult: float = 0.45) -> Vector3:
	_wander_timer -= delta
	var to := _wander_target - global_position
	to.y = 0.0
	if _wander_timer <= 0.0 or to.length() < 0.5:
		_pick_wander_target(radius)
		return Vector3.ZERO
	var dir := safe_dir(to)
	if dir == Vector3.ZERO:
		_pick_wander_target(radius)
	return dir * speed * mult


func _pick_wander_target(radius: float = 6.0) -> void:
	var ang := randf() * TAU
	var r := randf_range(1.0, radius)
	_wander_target = home + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
	_wander_timer = randf_range(2.5, 5.0)


# ---------------------------------------------------------------- Leitura

func threat_level(player_level: int) -> int:
	## 0 verde, 1 amarelo, 2 vermelho, 3 caveira
	if size >= Size.COLOSSAL:
		return 3
	var diff := level + int(size) * 4 - player_level
	if diff <= 0:
		return 0
	if diff <= 3:
		return 1
	if diff <= 7:
		return 2
	return 3
