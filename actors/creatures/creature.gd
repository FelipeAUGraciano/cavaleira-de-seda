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
var telegraph := false   ## vai atacar (o aviso é a marca no chão; o corpo não pisca mais)
var external_velocity := Vector3.ZERO
var _yank_t := -1.0             ## puxada pelo fio (Q): voa até um ponto e fica tonta
var _yank_dur := 0.3
var _yank_from := Vector3.ZERO
var _yank_to := Vector3.ZERO
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

# Golpes contra a jogadora (systems/ai/attack.gd), estilo Monster Hunter
var attacks: Array[Attack] = []
var cur_attack: Attack = null
var atk_t := 0.0
var atk_phase := 0             ## 0 aviso, 1 golpe, 2 recuperação
var atk_point := Vector3.ZERO  ## para onde o golpe mira (previsão de onde você vai estar)
var atk_hit := false
var atk_gap := 0.0             ## respiro entre um golpe e outro
var enraged := false           ## fúria: abaixo de enrage_frac da vida, avisa menos e bate mais
var enrage_frac := 0.5
var chase_speed := 1.0
var combat_label := "Caçando você"
var search_time := 8.0         ## depois de perder você de vista, vasculha a área por esse tempo
# Interesse na caçada (0-100): sobe vendo/apanhando, cai com o tempo, mais rápido se você
# some de vista, fica longe, inalcançável (fio, outro andar) ou leva o bicho longe de casa.
# Zerou = desiste e fica um tempo sem ligar para você (só volta se você encostar ou bater).
var uses_interest := true      ## chefes e bichos de território seguem as próprias regras
var interest := 0.0
var leash_range := 26.0        ## arrastado assim longe de onde a caçada começou, perde a vontade
var _hunt_origin := Vector3.ZERO
var _bored_t := 0.0            ## desistiu há pouco: ignora você por esse tempo
var _stall_t := 0.0            ## tempo correndo atrás sem chegar mais perto
var _best_d := INF
var _provoked_t := 0.0         ## acabou de apanhar de você: revida antes de qualquer outra coisa
const INTEREST_SEE := 45.0     ## por segundo, vendo você
const INTEREST_HIT := 40.0     ## levou um golpe seu
const BORED_TIME := 14.0
const BORED_IGNORE := 5.0
var search_left := 0.0
var _search_pt := Vector3.ZERO
var _search_t := 0.0
var _forced_next := ""
var _combo_count := 0
var _strafe := 1.0
var _marker: AttackMarker
var _web_immune := 0.0


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
	var d := flat_dist_to(p)
	if not asleep and d < body_radius + 1.2:
		return true   # encostou: sente mesmo de costas e no escuro
	if d < p.noise_radius() * k:
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
	return not attacks.is_empty() and hunt_wants()


func combat_tick(delta: float) -> Vector3:
	return hunt_combat(delta)


func combat_locked() -> bool:
	return cur_attack != null


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
	if _yank_t >= 0.0:
		_tick_yank(delta)
		return
	_strike_cd -= delta
	_tick_attacks(delta)
	var desired := Vector3.ZERO
	if entangled_time <= 0.0:
		desired = _think(delta) * slow_mult
	else:
		telegraph = false
		_strike_t = -1.0
		cancel_attack()
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
	var was_near := near_player
	near_player = p == null or Fx.flat_dist(p.global_position, global_position) < LOD_DISTANCE
	if was_near != near_player:
		_lod_changed(near_player)
	var was_noticed := noticed_player
	noticed_player = p != null and not p.dead and near_player and notices_player(p)
	if uses_interest and aggression > 0.0 and p != null:
		_update_interest(sense_interval(), p)
		if noticed_player and _bored_t > 0.0:
			if flat_dist_to(p) > BORED_IGNORE:
				noticed_player = false   # desistiu há pouco: só volta se você chegar bem perto
			else:
				_bored_t = 0.0           # encostou: a caçada recomeça
				_update_interest(sense_interval(), p)
	if noticed_player and not was_noticed and brain != null:
		brain.wake_up()
	if noticed_player:
		player_memory = memory_time
		last_player_pos = p.global_position
	elif player_memory > 0.0:
		if keeps_tracking(p) and (not uses_interest or interest > 0.0):
			# caçando: segue o barulho e o cheiro. Só despista quem some de vista E fica quieta.
			player_memory = memory_time
			last_player_pos = p.global_position
		else:
			player_memory = maxf(0.0, player_memory - sense_interval())
			if player_memory <= 0.0 and aggression > 0.0:
				search_left = search_time
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
	elif hover_y < 0.0 and entangled_time <= 0.0:
		_walk_into_strands()


func _update_interest(dt: float, p: Player) -> void:
	_bored_t = maxf(0.0, _bored_t - dt)
	_provoked_t = maxf(0.0, _provoked_t - dt)
	if p.dead:
		interest = 0.0
		return
	var d := flat_dist_to(p)
	var reachable := World.nav == null or World.nav.walkable(p.global_position, nav_kind)
	var stalking := brain != null and brain.is_doing("stalk")
	if player_memory <= 0.0 and search_left <= 0.0 and not stalking:
		_hunt_origin = global_position   # a caçada (se começar) conta a partir daqui
	var leashed := hunt_leashed()
	if leashed and stalking and player_memory <= 0.0:
		give_up_hunt()   # seguiu o cheiro longe demais sem te achar: volta para casa
		return
	if noticed_player and _bored_t <= 0.0 and reachable and not leashed:
		# ver você só alimenta a caçada se der para te pegar (e sem estar longe demais de casa)
		interest += INTEREST_SEE * dt * (1.6 if d < 4.0 else 1.0) * (0.4 if _stall_t > 5.0 else 1.0)
	var decay := 4.0
	if not noticed_player:
		decay += 8.0                      # sumiu de vista
	if d > track_range:
		decay += 12.0                     # longe demais
	if not reachable:
		decay += 18.0                     # inalcançável: no fio, do outro lado do abismo, outro andar
	if leashed:
		decay += 25.0                     # longe de casa: a coragem acaba
	if _stall_t > 5.0:
		decay += 14.0                     # corre, corre e não chega
	decay *= lerpf(1.7, 0.55, clampf(needs.hunger / 100.0, 0.0, 1.0))   # faminto insiste, cheio desiste
	interest = clampf(interest - decay * dt, 0.0, 100.0)
	if interest <= 0.0 and (player_memory > 0.0 or search_left > 0.0) and cur_attack == null:
		give_up_hunt()


func give_up_hunt() -> void:
	## Desiste da caçada: esquece você, não vasculha, e fica um tempo sem ligar.
	player_memory = 0.0
	search_left = 0.0
	interest = 0.0
	_bored_t = BORED_TIME
	_stall_t = 0.0
	_best_d = INF
	if brain != null:
		brain.wake_up()


func combat_utility() -> float:
	## Quanto a luta contra você vale frente a outras vontades (comer outra presa, fugir...).
	## Com pouco interesse, uma presa fácil por perto ganha.
	if not uses_interest or cur_attack != null:
		return 1.0
	if player_memory <= 0.0:
		return 0.45 if search_left > 0.0 else 0.0
	return 0.5 + 0.45 * interest / 100.0 + (0.35 if _provoked_t > 0.0 else 0.0)


func hunt_leashed() -> bool:
	## Já foi longe demais atrás de você desde que a caçada começou.
	return Fx.flat_dist(global_position, _hunt_origin) > leash_range


func mark_hunt_start() -> void:
	if player_memory <= 0.0:
		_hunt_origin = global_position


func bored_of_player() -> bool:
	return uses_interest and _bored_t > 0.0


func keeps_tracking(p: Player) -> bool:
	## Predador que já está atrás de você não perde o rastro enquanto você faz barulho
	## (anda, corre, luta, runa acesa) ou está à vista. Longe demais, perde.
	if aggression <= 0.0 or p == null or p.dead:
		return false
	if flat_dist_to(p) > maxf(track_range * 1.6, 24.0):
		return false
	return not p.is_quiet() or has_line_of_sight(p)


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


func _walk_into_strands() -> void:
	## Andando, P fica presa no fio (e o fio aguenta); M fica presa um instante e arrebenta.
	if _web_immune > 0.0 or WebNetwork.strands.is_empty():
		return
	for s in WebNetwork.strands:
		if is_instance_valid(s) and s.crossing_distance(global_position, body_radius * 2.0 + 0.2) < body_radius + 0.15:
			var held := entangle(3.0 if size == Size.P else 1.2)
			if held <= 0.0:
				return
			EventBus.web_touched.emit(global_position, self)
			if size == Size.M:
				var mine: bool = s.in_territory
				WebNetwork.remove_strand(s)
				if mine:
					EventBus.message.emit("O %s se enroscou num fio e arrebentou!" % display_name)
			return


func _update_glow(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	if not telegraph and cur_attack == null and _marker != null and _marker.visible:
		_marker.clear()   # golpe cancelado (enredada, atordoada, morta): a marca some junto
	if _overlay != null:
		if _flash > 0.0:
			_overlay.albedo_color = Color(1, 1, 1, 0.6)
		else:
			_overlay.albedo_color = Color(0, 0, 0, 0)
	if _flash > 0.0:
		_mat.emission_enabled = true
		_mat.emission = Color(1, 1, 1)
		_mat.emission_energy_multiplier = 1.5
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
	_web_immune -= delta
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
		interest = minf(100.0, interest + INTEREST_HIT)   # apanhou: agora é pessoal
		_bored_t = 0.0
		_provoked_t = 4.0
	if brain != null:
		brain.wake_up()
	if source != null and entangled_time <= 0.0:
		var push := global_position - source.global_position
		push.y = 0.0
		if push.length() > 0.01:
			external_velocity += push.normalized() * (4.0 if size == Size.P else 1.5)
	_on_hurt(source)
	_apply_damage(amount)
	if not dead and not enraged and not attacks.is_empty() and hp < max_hp * enrage_frac:
		enrage()


func _apply_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0 and not dead:
		die(false)


func add_poison() -> void:
	poison_stacks = mini(poison_stacks + 1, MAX_POISON)
	poison_time = POISON_DURATION


func entangle(duration: float) -> float:
	## Teia por tamanho: P fica presa o tempo todo; M fica presa mas rasga e se solta em
	## poucos segundos; G arrebenta na hora e só perde o passo. Devolve o tempo preso.
	if _web_immune > 0.0:
		return 0.0
	match size:
		Size.P:
			pass
		Size.M:
			duration = minf(duration, 2.2)
		_:
			slow(0.55, 1.0)
			return 0.0
	entangle_raw(duration)
	return duration


func entangle_raw(duration: float) -> void:
	## Prende sem a regra de tamanho (mecânicas de chefe, como a investida da Centopeia no fio).
	entangled_time = maxf(entangled_time, duration)
	external_velocity = Vector3.ZERO
	telegraph = false
	cancel_attack()
	_web_overlay.visible = true
	_web_immune = duration + 1.5


func is_entangled() -> bool:
	return entangled_time > 0.0


func slow(mult: float, duration: float) -> void:
	slow_mult = mult
	slow_time = duration


func yank_to(point: Vector3, dur: float = 0.3) -> void:
	## Puxão do fio: sai voando (num arquinho) até o ponto, larga o que fazia e fica tonta.
	_yank_from = global_position
	_yank_to = Vector3(point.x, global_position.y, point.z)
	_yank_dur = maxf(dur, 0.05)
	_yank_t = 0.0
	cancel_attack()
	telegraph = false
	_strike_t = -1.0
	external_velocity = Vector3.ZERO
	asleep = false


func _tick_yank(delta: float) -> void:
	_yank_t += delta
	var k := clampf(_yank_t / _yank_dur, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	var target := _yank_from.lerp(_yank_to, e)
	var step := target - global_position
	step.y = 0.0
	velocity = step / maxf(delta, 0.001)
	velocity.y = 0.0
	move_and_slide()
	if _visual != null:
		_visual.position.y = sin(PI * k) * 0.45   # sai do chão no puxão
	if k >= 1.0:
		_yank_t = -1.0
		if _visual != null:
			_visual.position.y = 0.0
		velocity = Vector3.ZERO
		entangle_raw(0.7)   # tonta: um instante para morder ou bater (crítico)


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


# ---------------------------------------------------------------- golpes contra a jogadora

func add_attack(a: Attack) -> Attack:
	attacks.append(a)
	return a


func find_attack(id: String) -> Attack:
	for a in attacks:
		if a.id == id:
			return a
	return null


func _tick_attacks(delta: float) -> void:
	atk_gap -= delta
	for a in attacks:
		a.cd_left -= delta


func cancel_attack() -> void:
	if cur_attack == null:
		return
	cur_attack.cd_left = cur_attack.cooldown * 0.5
	cur_attack = null
	telegraph = false
	_forced_next = ""
	if _marker != null:
		_marker.clear()


func show_marker(a: Attack, point: Vector3, fill: float) -> void:
	## Marca no chão para golpes fora do sistema de ataques (Centopeia, Morcego).
	if _marker == null:
		_marker = AttackMarker.new()
		add_child(_marker)
	_marker.draw_attack(a, global_position, facing, point, fill, enraged)


func hide_marker() -> void:
	if _marker != null:
		_marker.clear()


func enrage() -> void:
	enraged = true
	_flash = 0.3
	if near_player:
		EventBus.message.emit("O %s ficou FURIOSO!" % display_name)
	on_enrage()


func on_enrage() -> void:
	pass


func on_attack_start(_a: Attack) -> void:
	pass


func on_attack_active(_a: Attack) -> void:
	pass


func on_attack_hit(a: Attack, p: Player) -> void:
	## Efeitos genéricos; a espécie pode completar.
	match a.effect:
		"pull":
			p.pull_toward(global_position, a.effect_power if a.effect_power > 0.0 else 12.0)
		"slow":
			p.apply_slow(0.5, a.effect_power if a.effect_power > 0.0 else 2.0)


func _wind_mult() -> float:
	return 0.75 if enraged else 1.0


func _predict(p: Player, a: Attack) -> Vector3:
	var v := Vector3(p.velocity.x, 0.0, p.velocity.z)
	var goal := p.global_position + v * a.lead
	goal.y = 0.0
	if a.leap or a.at_point:
		var to := goal - global_position
		to.y = 0.0
		goal = global_position + to.limit_length(a.max_range + 1.0)
		goal.y = 0.0
		if a.leap and World.nav != null and not World.nav.walkable(goal, nav_kind):
			goal = _last_walkable_on_line(goal)
	return goal


func _last_walkable_on_line(goal: Vector3) -> Vector3:
	## Não pula num abismo: para no último ponto andável na direção do salto.
	var best := global_position
	var n := int(Fx.flat_dist(global_position, goal) / 0.5) + 1

	for i in range(1, n + 1):
		var q := global_position.lerp(goal, float(i) / n)
		if not World.nav.walkable(q, nav_kind):
			break
		best = q
	best.y = 0.0
	return best


func _turn_toward(pos: Vector3, max_rad: float) -> void:
	var to := pos - global_position
	to.y = 0.0
	if to.length() < 0.05:
		return
	var want := to.normalized()
	var ang := facing.signed_angle_to(want, Vector3.UP)
	facing = facing.rotated(Vector3.UP, clampf(ang, -max_rad, max_rad)).normalized()


func player_flank_angle(p: Player) -> float:
	## Ângulo (graus) entre a frente do bicho e a jogadora: >70 = do lado ou atrás.
	var to := p.global_position - global_position
	to.y = 0.0
	if to.length() < 0.05:
		return 0.0
	return rad_to_deg(facing.angle_to(to.normalized()))


func pick_attack(p: Player) -> Attack:
	var d := flat_dist_to(p)
	if _forced_next != "":
		var nxt := find_attack(_forced_next)
		_forced_next = ""
		if nxt != null and d <= nxt.max_range + 1.5:
			return nxt
	_combo_count = 0
	var flanked := player_flank_angle(p) > 70.0
	var opts: Array = []
	var total := 0.0
	for a in attacks:
		if a.cd_left > 0.0 or not a.in_range(d):
			continue
		if a.only_enraged and not enraged:
			continue
		if a.needs_sight and not has_line_of_sight(p):
			continue
		if a.leap and World.nav != null and not _clear_line(p.global_position):
			continue   # tem pedra ou buraco no meio: não pula
		var w := a.weight
		if a.flank:
			w *= 5.0 if flanked else 0.1
		opts.append([a, w])
		total += w
	if opts.is_empty():
		return null
	var r := randf() * total
	for o in opts:
		r -= float(o[1])
		if r <= 0.0:
			return o[0]
	return opts[opts.size() - 1][0]


func start_attack(a: Attack, p: Player) -> void:
	cur_attack = a
	atk_t = 0.0
	atk_phase = 0
	atk_hit = false
	atk_point = _predict(p, a)
	telegraph = true
	activity = a.label
	if _marker == null:
		_marker = AttackMarker.new()
		add_child(_marker)
	on_attack_start(a)


func attack_tick(delta: float, p: Player) -> Vector3:
	var a := cur_attack
	atk_t += delta
	var alive := p != null and not p.dead
	if atk_phase == 0:
		var wu := a.windup * _wind_mult()
		if alive and not (a.leap and atk_t > wu * 0.8):
			atk_point = _predict(p, a)
		_turn_toward(atk_point, a.track * delta * (1.3 if enraged else 1.0))
		if near_player:
			_marker.draw_attack(a, global_position, facing, atk_point, atk_t / wu, enraged)
		if atk_t >= wu:
			atk_phase = 1
			atk_t = 0.0
			telegraph = false
			on_attack_active(a)
		return Vector3.ZERO
	if atk_phase == 1:
		var v := Vector3.ZERO
		if a.leap:
			var to := atk_point - global_position
			to.y = 0.0
			var left := maxf(a.active - atk_t, 0.05)
			if to.length() > 0.15:
				v = to.normalized() * minf(to.length() / left, 20.0)

		elif a.lunge > 0.0:
			v = facing * a.lunge
		var landing := not a.leap or atk_t >= a.active * 0.65
		if not atk_hit and alive and landing:
			if a.hits(global_position, facing, atk_point, p.global_position, 0.3 * p.vis_scale):
				var dmg := a.damage * (1.2 if enraged else 1.0)
				if dmg <= 0.0 or p.take_damage(dmg, self, a.knockback):
					atk_hit = true
					on_attack_hit(a, p)
		if near_player:
			_marker.draw_attack(a, global_position, facing, atk_point, 1.0, enraged)
		if atk_t >= a.active:
			atk_phase = 2
			atk_t = 0.0
			_marker.clear()
			if atk_hit and a.combo_next != "" and _combo_count < 3:
				_forced_next = a.combo_next
				_combo_count += 1
		return v
	var rec := a.recover * (0.7 if enraged else 1.0)
	if _forced_next != "":
		rec = minf(rec, 0.12)
	if atk_t >= rec:
		a.cd_left = a.cooldown * (0.7 if enraged else 1.0)
		cur_attack = null
		atk_gap = 0.0 if _forced_next != "" else randf_range(0.2, 0.6) * (0.6 if enraged else 1.0)
	return Vector3.ZERO


func preferred_distance() -> float:
	## Distância que o bicho tenta manter quando nenhum golpe está pronto.
	var best := 1.5
	for a in attacks:
		if a.cd_left <= 0.0 and not a.only_enraged:
			best = maxf(best, a.max_range * 0.8)
	return best if best < 3.0 else attack_reach + 0.5


func fight_player(delta: float, p: Player) -> Vector3:
	## Luta contra a jogadora: golpe em andamento → termina; senão escolhe um golpe; senão
	## chega perto e, sem golpe pronto, rodeia (como os monstros de Monster Hunter).
	if cur_attack != null:
		return attack_tick(delta, p)
	if p == null or p.dead:
		return Vector3.ZERO
	var d := flat_dist_to(p)
	var see := noticed_player or d < 2.5
	if see:
		face_toward(p.global_position)
	if atk_gap <= 0.0 and see:
		var a := pick_attack(p)
		if a != null:
			start_attack(a, p)
			_stall_t = 0.0   # atacou: a caçada está rendendo
			_best_d = d
			return Vector3.ZERO
	activity = combat_label
	if d < _best_d - 0.75:
		_best_d = d
		_stall_t = 0.0
	else:
		_stall_t += delta
	var goal := p.global_position if see else last_player_pos
	if d > preferred_distance() or not see:
		return nav_to(goal, chase_speed * (1.15 if enraged else 1.0))
	var to := p.global_position - global_position
	to.y = 0.0
	if randf() < delta * 0.5:
		_strafe = -_strafe
	var side := Vector3(-to.z, 0.0, to.x).normalized() * _strafe
	return safe_dir(side) * speed * 0.5


func hunt_combat(delta: float) -> Vector3:
	## Combate completo: luta enquanto sabe onde você está; perdeu, vasculha a área.
	var p := GameState.player as Player
	if cur_attack != null or player_memory > 0.0:
		search_left = search_time if aggression > 0.0 else 0.0
		return fight_player(delta, p)
	search_left -= delta
	activity = "Procurando você"
	_search_t -= delta
	if _search_t <= 0.0 or Fx.flat_dist(global_position, _search_pt) < 0.8:
		_search_t = 2.0
		var ang := randf() * TAU
		_search_pt = last_player_pos + Vector3(cos(ang), 0.0, sin(ang)) * randf_range(1.0, 5.0)
		if World.nav != null and not World.nav.walkable(_search_pt, nav_kind):
			_search_pt = last_player_pos
	return nav_to(_search_pt, 0.6)


func hunt_wants() -> bool:
	return player_memory > 0.0 or search_left > 0.0 or cur_attack != null


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
