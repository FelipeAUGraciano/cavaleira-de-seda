class_name Creature
extends CharacterBody3D
## Base das criaturas da caverna.
##
## Corpo: vida, status (veneno, enredado, lento), morte e cadáver, modelo 3D, voo.
## Vida (mundo vivo, systems/ai): necessidades (Needs), sentidos e um cérebro (Brain) que
## escolhe a atividade — dormir na toca, comer, fugir, passear entre câmaras, lutar.
## Cada espécie monta o seu cérebro em _make_brain() e define os ataques em combat_tick().
## Criaturas sem cérebro (as irmãs do Berçário) continuam usando _think() direto.

enum Size { P, M, G, COLOSSAL }
const SIZE_NAMES := ["P", "M", "G", "Colossal"]
const GRAVITY := 20.0
const POISON_DPS_PER_STACK := 2.0
const POISON_DURATION := 5.0
const MAX_POISON := 5
const LOD_DISTANCE := 40.0           ## além disso, pensa e sente menos vezes por segundo

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
var food_acid := 0           ## + Resistência a Ácido ao comer (Sapo-de-rocha)
var food_skin := false       ## Pele de Cristal ao comer (Centopeia-blindada)

# Modelo 3D (systems/models.gd): troca as formas cinza quando o .glb existir
var model_name := ""
var model_size := 0.0        ## 0 = body_radius * 2.5
var model_fit := "max"
var model_lift := 0.0        ## sobe o modelo (corpos sem patas ficam acima do chão)
var model_tint := Color(1, 1, 1)  ## multiplica as cores do modelo (ex.: irmã faminta mais vermelha)
var hover_y := -1.0         ## >= 0: voa nessa altura (morcegos). Enredado, cai.

# Vida: ficha de comportamento (cada espécie ajusta no _init)
var rest_phase: CaveClock.Phase = CaveClock.Phase.CACA   ## fase do ciclo em que tem sono
var den := Vector3.ZERO      ## toca: onde dorme e se cura (padrão: onde nasceu)
var den_radius := 1.5
var range_rooms: Array = []  ## câmaras por onde passeia (vazio = fica perto da toca)
var roam_speed := 0.6
var hunger_threshold := 40.0
var sleep_heal := 0.01       ## fração do PV por segundo, dormindo
var retreat_frac := 0.0      ## abaixo desta fração do PV, foge para a toca (0 = nunca)
var retreat_speed := 0.7
var retreat_cooldown := 90.0
var fears_player := false
var fear_radius := 7.0
var sight_range := 8.0
var sight_fov := 140.0
var memory_time := 4.0
var attack_damage := 8.0
var attack_reach := 1.3
var nav_kind: int = NavGrid.Kind.SMALL
var hunt_burst := 1.0        ## arrancada ao perseguir uma presa (×velocidade)
var aggression := 0.0        ## vontade de caçar a jogadora (0 = nunca; 1 = predador de verdade)
var track_range := 18.0      ## de quão longe sente o cheiro/barulho dela para ir atrás
var stalk_speed := 0.75

# Estado do corpo
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

# Estado da vida
var needs := Needs.new()
var brain: Brain = null
var anchor := Vector3.ZERO   ## ponto de referência atual (toca ou destino de passeio)
var asleep := false
var activity := "Parada"     ## mostrado na Leitura
var noticed_player := false
var player_memory := 0.0
var last_player_pos := Vector3.ZERO
var fear_source := Vector3.ZERO
var threat: Creature = null
var retreat_cd := 0.0
var near_player := true
var hunger: float:
	get:
		return needs.hunger
	set(v):
		needs.hunger = v

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
var _sense_t := 0.0
var _path := PackedVector3Array()
var _path_i := 0
var _path_goal := Vector3.ZERO
var _path_age := 0.0
var _strike_t := -1.0
var _strike_cd := 0.0
var _strike_target: Node3D = null
var _grid_move := false      ## anda presa à grade de navegação (sem colidir com a malha da caverna)


func _ready() -> void:
	add_to_group("creature")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	hp = max_hp
	home = global_position
	if den == Vector3.ZERO:
		den = Vector3(global_position.x, 0.0, global_position.z)
	anchor = den
	needs.randomize_start()
	_sense_t = randf() * 0.2
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
	brain = _make_brain()
	World.register(self)
	call_deferred("_setup_grid_move")


func _setup_grid_move() -> void:
	## Com grade de navegação, a criatura não testa colisão contra a caverna (a parte mais cara
	## da física): a grade já diz onde dá para pisar. Ela continua batendo na jogadora e nos bichos.
	if World.nav != null:
		_grid_move = true
		collision_mask &= ~1


func _exit_tree() -> void:
	World.unregister(self)


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


# ---------------------------------------------------------------- ganchos das espécies

func _make_brain() -> Brain:
	## Cada espécie devolve o seu cérebro; null = usa _think() direto.
	return null


func _think(delta: float) -> Vector3:
	## Devolve a velocidade horizontal desejada.
	return brain.tick(self, delta) if brain != null else Vector3.ZERO


func notices_player(p: Player) -> bool:
	## Sentidos da espécie. Padrão: visão em cone e ouvir barulho. Dormindo, quase nada.
	var k := 0.3 if asleep else 1.0
	if flat_dist_to(p) < p.noise_radius() * k:
		return true
	return can_see(p, sight_range * p.visibility_mult() * k, sight_fov)


func is_threat(o: Creature) -> bool:
	## Quem esta espécie teme: predadores maiores acordados.
	return o != self and int(o.size) > int(size) and o.is_in_group("predator") and not o.asleep


func is_prey(_o: Creature) -> bool:
	return false


func eats_carrion() -> bool:
	return false


func find_food() -> Variant:
	## Comida que a criatura enxerga agora: Corpse, Creature (presa) ou Vector3 (pasto). null = nada.
	var best: Variant = null
	if eats_carrion():
		best = World.nearest_corpse(global_position, 12.0, func(c): return not c.is_rotten() and (c.reserved_by == null or not is_instance_valid(c.reserved_by) or c.reserved_by == self))
	if best == null:
		best = World.nearest(global_position, 10.0, func(o): return is_prey(o) and not o.dead)
	return best


func find_rival() -> Creature:
	return null


func combat_wants() -> bool:
	return false


func combat_tick(_delta: float) -> Vector3:
	return Vector3.ZERO


func combat_locked() -> bool:
	return false


func combat_start() -> void:
	pass


func combat_stop() -> void:
	pass


func on_retreat() -> void:
	pass


func sees_player_as_prey(p: Player) -> bool:
	## Maior que ela, sempre; do mesmo tamanho, só se estiver faminto.
	var mine := int(size)
	var hers := p.body_size()
	return mine > hers or (mine == hers and needs.hunger > 75.0)


func on_stalk_start() -> void:
	if near_player:
		EventBus.stalked.emit(self)


func hunting_player() -> bool:
	## Para o HUD: este bicho está atrás de você agora?
	return brain != null and (brain.is_doing("stalk") or brain.is_doing("combat"))


func _on_hurt(_source: Node3D) -> void:
	pass


func _lod_changed(_near: bool) -> void:
	## Criaturas sem cérebro: chamada quando ficam perto/longe da jogadora.
	pass


func _animate(_delta: float, _speed_now: float) -> void:
	pass


# ---------------------------------------------------------------- laço

func _physics_process(delta: float) -> void:
	if dead:
		return
	_tick_status(delta)
	if dead:
		return
	if brain == null:
		_sense_t -= delta
		if _sense_t <= 0.0:
			_sense_t = 0.5
			var p := GameState.player as Player
			var near := p == null or Fx.flat_dist(p.global_position, global_position) < LOD_DISTANCE
			if near != near_player:
				near_player = near
				_lod_changed(near)
	if brain != null:
		needs.tick(delta, is_resting_phase(), asleep)
		retreat_cd -= delta
		_path_age += delta
		_sense_t -= delta
		if _sense_t <= 0.0:
			_sense_t = sense_interval()
			_sense()
	_strike_cd -= delta
	var desired := Vector3.ZERO
	if entangled_time <= 0.0:
		desired = _think(delta) * slow_mult
	else:
		telegraph = false
		_strike_t = -1.0
	velocity.x = desired.x + external_velocity.x
	velocity.z = desired.z + external_velocity.z
	if _grid_move:
		_grid_constrain(delta)
		if hover_y >= 0.0 and entangled_time <= 0.0:
			velocity.y = clampf((hover_y - global_position.y) * 6.0, -9.0, 7.0)
		elif global_position.y > 0.02 or not World.nav.walkable(global_position, NavGrid.Kind.SMALL):
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = 0.0
			global_position.y = 0.0
	elif hover_y >= 0.0 and entangled_time <= 0.0:
		velocity.y = clampf((hover_y - global_position.y) * 6.0, -9.0, 7.0)
	elif is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= GRAVITY * delta
	external_velocity = external_velocity.move_toward(Vector3.ZERO, 18.0 * delta)
	move_and_slide()
	if _grid_move and global_position.y < 0.0 and global_position.y > -0.6 and World.nav.walkable(global_position, NavGrid.Kind.SMALL):
		global_position.y = 0.0   # pousou no chão
		velocity.y = 0.0

	var flat := Vector3(desired.x, 0.0, desired.z)
	if flat.length() > 0.1:
		facing = flat.normalized()
	_anim_t += delta
	if near_player:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-facing.x, -facing.z), clampf(10.0 * delta, 0.0, 1.0))
		_animate(delta, flat.length())
		_update_glow(delta)
	if global_position.y < -5.0:
		die(true)


func _grid_constrain(delta: float) -> void:
	## Zera o movimento que levaria para fora das células andáveis (paredes, abismos, pilares).
	var nav := World.nav
	var kind := nav_kind
	var here := global_position
	if not nav.walkable(here, kind):
		return   # já está fora (empurrada): deixa sair
	var step := Vector3(velocity.x, 0.0, velocity.z) * delta
	if step.length_squared() < 0.000001:
		return
	var look := step.normalized() * 0.3
	if nav.walkable(here + step + look, kind):
		return
	if absf(step.x) > 0.0001 and nav.walkable(here + Vector3(step.x + signf(step.x) * 0.3, 0.0, 0.0), kind):
		velocity.z = 0.0
		return
	if absf(step.z) > 0.0001 and nav.walkable(here + Vector3(0.0, 0.0, step.z + signf(step.z) * 0.3), kind):
		velocity.x = 0.0
		return
	velocity.x = 0.0
	velocity.z = 0.0


func decide_interval() -> float:
	return 0.25 if near_player else 1.0


func sense_interval() -> float:
	return 0.2 if near_player else 0.6


func _sense() -> void:
	var p := GameState.player as Player
	near_player = p == null or Fx.flat_dist(p.global_position, global_position) < LOD_DISTANCE
	var was_noticed := noticed_player
	noticed_player = p != null and not p.dead and near_player and notices_player(p)
	if noticed_player and not was_noticed and brain != null:
		brain.wake_up()
	if noticed_player:
		player_memory = memory_time
		last_player_pos = p.global_position
	else:
		player_memory = maxf(0.0, player_memory - sense_interval())
	threat = World.nearest(global_position, fear_radius, is_threat)
	if threat != null:
		needs.feel_fear(100.0 * (1.0 - flat_dist_to(threat) / fear_radius) + 30.0)
		fear_source = threat.global_position
	if fears_player and p != null and not p.dead:
		var smell := maxf(4.0, p.noise_radius())
		var d := flat_dist_to(p)
		if d < smell:
			needs.feel_fear(100.0 * (1.0 - d / smell) + 30.0)
			fear_source = p.global_position
	if size >= Size.G:
		_tear_strands()


func is_resting_phase() -> bool:
	return World.clock != null and World.clock.phase == rest_phase


func activity_level() -> float:
	return 0.35 if is_resting_phase() else 1.0


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


func pick_roam_destination() -> Variant:
	if World.nav == null or range_rooms.is_empty():
		return null
	var here := World.nav.room_at(global_position)
	var options := range_rooms.filter(func(r): return r != here)
	if options.is_empty():
		options = range_rooms
	return World.nav.random_point(String(options.pick_random()), nav_kind)


func _tear_strands() -> void:
	## Bichos grandes arrebentam os fios por onde passam.
	for s in WebNetwork.strands.duplicate():
		if is_instance_valid(s) and s.distance_to(global_position) < body_radius + 0.3:
			var mine: bool = s.in_territory
			WebNetwork.remove_strand(s)
			EventBus.web_touched.emit(global_position, self)
			if mine:
				EventBus.message.emit("Algo grande arrebentou um fio do seu território!")


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
	asleep = false
	if source != null and source.is_in_group("player"):
		player_memory = memory_time + 2.0
		last_player_pos = source.global_position
	if brain != null:
		brain.wake_up()
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
	World.unregister(self)
	if not fell:
		var corpse := Corpse.new()
		corpse.setup(display_name, food_satiety, food_silk, food_xp, body_color, body_radius)
		corpse.energy_bonus = food_energy
		corpse.acid_bonus = food_acid
		corpse.skin_bonus = food_skin
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


# ---------------------------------------------------------------- movimento

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
	## Só segue se houver chão logo à frente (não cai em abismo). Usa a grade de navegação
	## quando existe (sem raio de física); senão, um raio para baixo.
	dir.y = 0.0
	if dir.length() < 0.01:
		return Vector3.ZERO
	dir = dir.normalized()
	var ahead := global_position + dir * (body_radius + 0.7)
	if World.nav != null:
		return dir if World.nav.walkable(ahead, nav_kind) else Vector3.ZERO
	var q := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 0.5, ahead + Vector3.DOWN * 1.5, 1)
	if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		return Vector3.ZERO
	return dir


func move_to(pos: Vector3, mult: float) -> Vector3:
	var d := pos - global_position
	d.y = 0.0
	if d.length() < 0.8:
		return Vector3.ZERO
	return safe_dir(d) * speed * mult


func nav_to(goal: Vector3, mult: float) -> Vector3:
	## Anda até goal pelo caminho da grade de navegação (contorna paredes, pilares e abismos).
	var to := goal - global_position
	to.y = 0.0
	if to.length() < 0.6:
		return Vector3.ZERO
	var nav := World.nav
	if nav == null or (to.length() < 4.0 and _clear_line(goal)):
		return move_to(goal, mult)
	if _path.is_empty() or _path_goal.distance_to(goal) > 2.0 or _path_age > 4.0:
		_path = nav.path(global_position, goal, nav_kind)
		_path_i = 0
		_path_goal = goal
		_path_age = 0.0
	while _path_i < _path.size() and Fx.flat_dist(global_position, _path[_path_i]) < 0.9:
		_path_i += 1
	if _path_i >= _path.size():
		return move_to(goal, mult)
	var d := _path[_path_i] - global_position
	d.y = 0.0
	return d.normalized() * speed * mult


func _clear_line(goal: Vector3) -> bool:
	var nav := World.nav
	var n := int(Fx.flat_dist(global_position, goal))
	for i in range(1, n + 1):
		if not nav.walkable(global_position.lerp(goal, float(i) / (n + 1)), nav_kind):
			return false
	return true


func flee_from(src: Vector3) -> Vector3:
	var away := global_position - src
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3(randf() - 0.5, 0.0, randf() - 0.5)
	for ang in [0.0, 0.6, -0.6, 1.2, -1.2, 1.8, -1.8, 2.5, -2.5]:
		var d := safe_dir(away.rotated(Vector3.UP, ang))
		if d != Vector3.ZERO:
			return d * speed * 1.25
	return Vector3.ZERO


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
	var center := anchor if anchor != Vector3.ZERO else home
	var ang := randf() * TAU
	var r := randf_range(1.0, radius)
	_wander_target = center + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
	_wander_timer = randf_range(2.5, 5.0)


# ---------------------------------------------------------------- briga entre criaturas

func fight(target: Node3D, delta: float) -> Vector3:
	## Aproxima e dá um bote (0,4 s de aviso). Serve para caçar presas e brigar com rivais.
	if target == null or not is_instance_valid(target):
		_strike_t = -1.0
		return Vector3.ZERO
	if _strike_t >= 0.0:
		_strike_t += delta
		face_toward(target.global_position)
		if _strike_t >= 0.4:
			_strike_t = -1.0
			telegraph = false
			_strike_cd = 1.1
			var reach: float = attack_reach + _radius_of(target) + 0.5
			if flat_dist_to(target) <= reach and target.has_method("take_damage"):
				target.take_damage(attack_damage, self)
		return Vector3.ZERO
	var r: float = attack_reach + _radius_of(target)
	if flat_dist_to(target) <= r:
		face_toward(target.global_position)
		if _strike_cd <= 0.0:
			_strike_t = 0.0
			_strike_target = target
			telegraph = true
		return Vector3.ZERO
	return nav_to(target.global_position, hunt_burst)


func _radius_of(n: Node3D) -> float:
	var c := n as Creature
	return c.body_radius if c != null else 0.4


func is_striking() -> bool:
	return _strike_t >= 0.0


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
