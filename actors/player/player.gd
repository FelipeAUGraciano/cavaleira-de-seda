class_name Player
extends CharacterBody3D
## A Cavaleira de Seda (forma Filhote no protótipo).
## Movimento twin-stick, esquiva, combate, fio, Modo Tecelagem, casulo e os 4 recursos.
## Os recursos aparecem no corpo: placas = PV, runa = Energia, cachecol = Seda, abdômen = Saciedade.

# ---------------------------------------------------------------- balanceamento
const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const STRAND_SPEED_MULT := 1.5
const DODGE_SPEED := 13.0
const DODGE_TIME := 0.32
const DODGE_INVULN := 0.3
const DODGE_COST := 15.0
const BACKSTEP_SPEED := 10.0
const BACKSTEP_TIME := 0.16
const BACKSTEP_COST := 8.0
const GRAVITY := 22.0

const COMBO_DAMAGE := [8.0, 8.0, 14.0]
const ATTACK_TIME := 0.3
const ATTACK_RANGE := 1.7
const ATTACK_ARC := 100.0
const BITE_TIME := 0.45
const BITE_DAMAGE := 4.0
const BITE_RANGE := 1.4

const STRAND_RANGE := 12.0
const THROW_RANGE := 12.0
const TRAP_RANGE := 8.0
const SILK_STRAND := 5.0
const SILK_TRAP := 15.0
const SILK_COCOON := 30.0
const SILK_THROW := 5.0
const TRAP_LEVEL := 3

const WEAVE_TIME_SCALE := 0.25
const WEAVE_ENERGY_PER_SEC := 8.0
const ENERGY_REGEN := 10.0
const SATIETY_DECAY := 1.0 / 6.0   ## ~10 min de cheia a vazia
const STARVE_DPS := 1.0
const FALL_DAMAGE := 25.0

enum State { NORMAL, DODGE, BACKSTEP, ATTACK, BITE, ZIP, EAT, DEAD }

# ---------------------------------------------------------------- recursos
var max_hp := 100.0
var hp := 100.0
var max_energy := 100.0
var energy := 100.0
var max_silk := 100.0
var silk := 100.0
var max_satiety := 100.0
var satiety := 100.0
var level := 1
var xp := 0
var resist_rot := 0
var rune_on := true
var dead := false
var in_territory := false
var on_strand := false

# ---------------------------------------------------------------- estado
var state: State = State.NORMAL
var state_time := 0.0
var combo_index := 0
var combo_queued := false
var hit_done := false
var invuln := 0.0
var energy_delay := 0.0
var external_velocity := Vector3.ZERO
var move_dir := Vector3.ZERO
var aim_dir := Vector3(0, 0, -1)
var aim_point := Vector3.ZERO
var action_dir := Vector3.ZERO
var zip_target := Vector3.ZERO
var eat_target: Corpse = null
var noise := 2.0
var last_safe_pos := Vector3.ZERO
var respawn_pos := Vector3.ZERO
var using_stick_aim := false

var weaving := false
var weave_first: WebAnchor = null
var hovered_anchor: WebAnchor = null

var camera: Camera3D
var _preview: MeshInstance3D
var _preview_mat: StandardMaterial3D
var _last_real_us := 0
var _territory_timer := 0.0
var _safe_timer := 0.0
var _death_timer := 0.0
var _starve_msg_timer := 0.0
var _hurt_flash := 0.0

# visual (formas cinza; troque por um modelo depois)
var _visual: Node3D
var _leg_rig: SpiderLegs
var _body_mat: StandardMaterial3D
var _rune_mat: StandardMaterial3D
var _rune_light: OmniLight3D
var _scarf_tail: MeshInstance3D
var _abdomen: MeshInstance3D
var _plates: Array[MeshInstance3D] = []
var _model_overlay: StandardMaterial3D


# ================================================================= setup

func _ready() -> void:
	add_to_group("player")
	GameState.player = self
	collision_layer = 2
	collision_mask = 1 | 4 | 8
	floor_snap_length = 0.3
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.42
	cs.shape = shape
	cs.position.y = 0.42
	add_child(cs)
	_build_visual()
	_build_camera()
	_preview_mat = Fx.mat(Color(0.4, 1.0, 0.6), 2.0, true)
	_preview = Fx.box(Vector3(0.07, 0.07, 1.0), _preview_mat)
	_preview.top_level = true
	_preview.visible = false
	add_child(_preview)
	respawn_pos = global_position
	last_safe_pos = global_position
	aim_point = global_position + aim_dir * 3.0
	_last_real_us = Time.get_ticks_usec()


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_body_mat = Fx.mat(Color(0.16, 0.14, 0.38))
	var plate_mat := Fx.mat(Color(0.62, 0.66, 0.8), 0.15)

	var head := Fx.sphere(0.32, _body_mat)
	head.position = Vector3(0.0, 0.45, -0.18)
	_visual.add_child(head)
	_abdomen = Fx.sphere(0.42, _body_mat)
	_abdomen.position = Vector3(0.0, 0.55, 0.45)
	_visual.add_child(_abdomen)

	_rune_mat = Fx.mat(Color(0.3, 0.85, 1.0), 3.0, true)
	var rune := Fx.cylinder(0.2, 0.04, _rune_mat)
	rune.position = Vector3(0.0, 0.96, 0.48)
	_visual.add_child(rune)
	_rune_light = OmniLight3D.new()
	_rune_light.light_color = Color(0.4, 0.85, 1.0)
	_rune_light.omni_range = 4.5
	_rune_light.light_energy = 1.4
	_rune_light.shadow_enabled = true
	_rune_light.position = Vector3(0.0, 1.3, 0.2)
	add_child(_rune_light)

	var eye_mat := Fx.mat(Color(1.0, 0.65, 0.15), 1.5)
	for x in [-0.12, 0.12]:
		var eye := Fx.sphere(0.075, eye_mat)
		eye.position = Vector3(x, 0.52, -0.45)
		_visual.add_child(eye)
	var small_eye_mat := Fx.mat(Color(0.4, 0.9, 1.0), 2.0, true)
	for i in range(6):
		var e := Fx.sphere(0.03, small_eye_mat)
		e.position = Vector3(-0.1 + (i % 3) * 0.1, 0.66 + floorf(i / 3.0) * 0.05, -0.4)
		_visual.add_child(e)

	for p in [Vector3(-0.2, 0.72, -0.12), Vector3(0.2, 0.72, -0.12), Vector3(-0.22, 0.86, 0.42), Vector3(0.22, 0.86, 0.42)]:
		var plate := Fx.box(Vector3(0.2, 0.06, 0.26), plate_mat)
		plate.position = p
		plate.rotation.z = -0.5 * signf(p.x)
		_visual.add_child(plate)
		_plates.append(plate)

	_apply_model([head, _abdomen, rune])

	var scarf_mat := Fx.mat(Color(0.6, 0.72, 0.95), 0.3)
	var scarf := Fx.box(Vector3(0.52, 0.07, 0.14), scarf_mat)
	scarf.position = Vector3(0.0, 0.6, 0.02)
	_visual.add_child(scarf)
	_scarf_tail = Fx.box(Vector3(0.12, 0.04, 1.0), scarf_mat)
	_scarf_tail.position = Vector3(0.12, 0.66, 0.5)
	_visual.add_child(_scarf_tail)

	# 8 patas com IK procedural (systems/spider_legs.gd)
	_leg_rig = SpiderLegs.new()
	_leg_rig.setup(_visual, 1.0, 1 | 8)
	add_child(_leg_rig)


func _apply_model(base_parts: Array) -> void:
	## Com o modelo do corpo (assets/models/cavaleira_corpo), as formas cinza do corpo somem.
	## Patas e cachecol continuam por código. A luz da runa continua acendendo e apagando.
	var parts := base_parts.duplicate()
	for c in _visual.get_children():
		if c is MeshInstance3D and not parts.has(c):
			parts.append(c)
	var m := Models.swap(_visual, "cavaleira_corpo", 1.4, parts, "length")
	if m == null:
		return
	m.position.y = 0.15
	_plates.clear()
	_model_overlay = StandardMaterial3D.new()
	_model_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_model_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_model_overlay.albedo_color = Color(1.0, 0.2, 0.2, 0.0)
	Models.set_overlay(m, _model_overlay)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 18.0
	camera.near = 0.1
	camera.far = 200.0
	camera.top_level = true
	camera.rotation_degrees = Vector3(-55.0, 0.0, 0.0)
	add_child(camera)
	camera.current = true
	snap_camera()


func snap_camera() -> void:
	_update_camera(1.0, true)


# ================================================================= loop

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		using_stick_aim = false


func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_dt := clampf((now - _last_real_us) / 1000000.0, 0.0, 0.1)
	_last_real_us = now
	_update_aim()
	_handle_weave(real_dt)
	_leg_rig.curled = dead
	_update_visual(delta)
	_update_camera(real_dt, false)
	if Input.is_action_just_pressed("debug_level") and not dead:
		gain_xp(xp_to_next() - xp)


func _physics_process(delta: float) -> void:
	_update_resources(delta)
	if dead:
		_death_timer -= delta
		if _death_timer <= 0.0:
			_respawn()
		return
	invuln = maxf(invuln - delta, 0.0)
	state_time += delta

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move_dir = Vector3(input.x, 0.0, input.y)
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()
	on_strand = WebNetwork.strand_near(global_position, 0.65) != null

	var horizontal := Vector3.ZERO
	match state:
		State.NORMAL:
			horizontal = _state_normal()
		State.DODGE:
			horizontal = _state_dodge()
		State.BACKSTEP:
			horizontal = _state_backstep()
		State.ATTACK:
			horizontal = _state_attack()
		State.BITE:
			horizontal = _state_bite()
		State.EAT:
			horizontal = _state_eat()
		State.ZIP:
			_state_zip()
			_check_fall_and_safe(delta)
			return

	velocity.x = horizontal.x + external_velocity.x
	velocity.z = horizontal.z + external_velocity.z
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= GRAVITY * delta
	external_velocity = external_velocity.move_toward(Vector3.ZERO, 25.0 * delta)
	move_and_slide()
	_check_fall_and_safe(delta)


func _start_state(s: State) -> void:
	state = s
	state_time = 0.0
	hit_done = false


# ================================================================= estados

func _state_normal() -> Vector3:
	var running := Input.is_action_pressed("run") and move_dir.length() > 0.1
	var spd := RUN_SPEED if running else WALK_SPEED
	if on_strand:
		spd *= STRAND_SPEED_MULT
	if satiety <= 0.0:
		spd *= 0.8
	if move_dir.length() > 0.1:
		if on_strand:
			noise = 0.0
		else:
			noise = 8.0 if running else 2.5
	else:
		noise = 0.5

	if Input.is_action_just_pressed("dodge"):
		_try_dodge()
	elif Input.is_action_just_pressed("throw_silk"):
		_throw_silk()
	elif not weaving:
		if Input.is_action_just_pressed("attack"):
			_start_attack(0)
		elif Input.is_action_just_pressed("bite"):
			_start_state(State.BITE)
		elif Input.is_action_just_pressed("interact"):
			_interact()
	if Input.is_action_just_pressed("rune"):
		_toggle_rune()
	if Input.is_action_just_pressed("cocoon"):
		_weave_cocoon()
	return move_dir * spd


func _try_dodge() -> void:
	if move_dir.length() > 0.2:
		if energy < DODGE_COST:
			_msg("Sem energia para esquivar.")
			return
		energy -= DODGE_COST
		energy_delay = 1.0
		action_dir = move_dir.normalized()
		invuln = DODGE_INVULN
		_start_state(State.DODGE)
	else:
		if energy < BACKSTEP_COST:
			_msg("Sem energia para o backstep.")
			return
		energy -= BACKSTEP_COST
		energy_delay = 1.0
		action_dir = -aim_dir
		_start_state(State.BACKSTEP)


func _state_dodge() -> Vector3:
	noise = 3.0
	if state_time >= DODGE_TIME:
		_start_state(State.NORMAL)
	return action_dir * DODGE_SPEED


func _state_backstep() -> Vector3:
	noise = 2.0
	if state_time >= BACKSTEP_TIME:
		_start_state(State.NORMAL)
	return action_dir * BACKSTEP_SPEED


func _start_attack(index: int) -> void:
	combo_index = index
	combo_queued = false
	_start_state(State.ATTACK)


func _state_attack() -> Vector3:
	noise = 6.0
	if Input.is_action_just_pressed("attack") and not weaving:
		combo_queued = true
	if Input.is_action_just_pressed("dodge"):
		_try_dodge()
		return Vector3.ZERO
	if not hit_done and state_time >= 0.1:
		hit_done = true
		_melee(float(COMBO_DAMAGE[combo_index]), ATTACK_RANGE, ATTACK_ARC, false)
	if state_time >= ATTACK_TIME:
		if combo_queued and combo_index < 2:
			_start_attack(combo_index + 1)
		else:
			_start_state(State.NORMAL)
	var lunge := 3.0 if state_time < 0.12 else 0.0
	return aim_dir * lunge + move_dir * 1.5


func _state_bite() -> Vector3:
	noise = 4.0
	if not hit_done and state_time >= 0.2:
		hit_done = true
		_melee(BITE_DAMAGE, BITE_RANGE, 70.0, true)
	if state_time >= BITE_TIME:
		_start_state(State.NORMAL)
	return move_dir * 1.0


func _state_eat() -> Vector3:
	noise = 1.0
	if eat_target == null or not is_instance_valid(eat_target):
		_start_state(State.NORMAL)
		return Vector3.ZERO
	if state_time >= 0.9:
		_eat(eat_target)
		eat_target = null
		_start_state(State.NORMAL)
	return Vector3.ZERO


func _state_zip() -> void:
	noise = 3.0
	var to := zip_target - global_position
	to.y = 0.0
	if to.length() < 0.7 or state_time > 1.2:
		velocity = Vector3.ZERO
		_start_state(State.NORMAL)
		return
	velocity = to.normalized() * 16.0
	velocity.y = 0.0
	move_and_slide()


# ================================================================= ações

func _melee(damage: float, reach: float, arc_deg: float, poison: bool) -> void:
	var root := get_parent()
	var side := aim_dir.cross(Vector3.UP) * 0.6
	var center := global_position + Vector3.UP * 0.5
	Fx.beam(root, center + side + aim_dir * 0.3, center - side + aim_dir * reach, Color(0.7, 0.95, 1.0), 0.1, 0.05)
	for n in get_tree().get_nodes_in_group("creature"):
		var c := n as Creature
		if c == null or c.dead:
			continue
		var to := c.global_position - global_position
		to.y = 0.0
		if to.length() > reach + c.body_radius:
			continue
		if c.global_position.y - global_position.y > 1.3:
			continue   # voando alto demais (morcego): use fio (Q) ou espere o mergulho
		if to.length() > 0.3 and rad_to_deg(aim_dir.angle_to(to.normalized())) > arc_deg * 0.5:
			continue
		var dmg := damage
		var crit := c.is_entangled()
		if crit:
			dmg *= 2.0
			_msg("Crítico! %s está enredado." % c.display_name)
		c.take_damage(dmg, self)
		if poison:
			c.add_poison()


func _throw_silk() -> void:
	if silk < SILK_THROW:
		_msg("Seda insuficiente para lançar fio.")
		return
	silk -= SILK_THROW
	var from := global_position + Vector3.UP * 0.5
	var to := from + aim_dir * THROW_RANGE
	var flyer := _flyer_in_aim()
	if flyer != null:
		Fx.beam(get_parent(), from, flyer.global_position, Color(0.9, 0.95, 1.0), 0.3, 0.05)
		flyer.entangle(4.0)
		_msg("Fio no ar! %s caiu enredado." % flyer.display_name)
		GameState.say_once("derrubou_morcego", "Desce daí, rato de asa!")
		return
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 4)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		Fx.beam(get_parent(), from, to, Color(0.9, 0.95, 1.0), 0.15, 0.04)
		return
	var hit_pos: Vector3 = hit["position"]
	Fx.beam(get_parent(), from, hit_pos, Color(0.9, 0.95, 1.0), 0.3, 0.05)
	var c := hit["collider"] as Creature
	if c != null:
		if c.size == Creature.Size.P:
			c.pull_toward(global_position, 10.0)
			GameState.say_once("primeiro_puxao", "Vem cá, lanchinho!")
		else:
			_msg("%s é grande demais para puxar." % c.display_name)
		return
	zip_target = hit_pos - aim_dir * 0.7
	zip_target.y = global_position.y
	_start_state(State.ZIP)
	GameState.say_once("primeiro_zip", "Fio, parede, VOOOU!")


func _flyer_in_aim() -> Creature:
	## Criatura voando na direção da mira (fio lançado sobe até ela).
	var best: Creature = null
	var best_d := THROW_RANGE
	for n in get_tree().get_nodes_in_group("flyer"):
		var c := n as Creature
		if c == null or c.dead or c.is_entangled():
			continue
		var to := c.global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d > best_d or d < 0.3:
			continue
		if rad_to_deg(aim_dir.angle_to(to.normalized())) > 14.0:
			continue
		best = c
		best_d = d
	return best


func _interact() -> void:
	var c := _nearest_cocoon(2.4)
	if c != null:
		_rest(c)
		return
	var corpse := _nearest_corpse(1.9)
	if corpse != null:
		eat_target = corpse
		_start_state(State.EAT)
		return
	_msg("Nada para comer ou usar aqui.")


func _eat(c: Corpse) -> void:
	var rotten := c.is_rotten()
	satiety = minf(max_satiety, satiety + c.satiety * (0.6 if rotten else 1.0))
	silk = minf(max_silk, silk + c.silk)
	if rotten:
		var dmg := maxf(2.0, 12.0 - resist_rot * 2.0)
		resist_rot += 1
		_hurt(dmg)
		_msg("Carne podre! -%d PV · Resistência à Podridão %d" % [int(dmg), resist_rot])
		GameState.say_once("comeu_podre", "Eca. Eca, eca, eca. ...Mas acho que meu estômago ficou mais forte.")
	else:
		_msg("Comeu %s: +%d saciedade, +%d seda, +%d XP" % [c.display_name, int(c.satiety), int(c.silk), c.xp])
	GameState.say_once("primeira_refeicao", "Larva crua. Gosto de musgo molhado. Mas a fome venceu o nojo.")
	if c.energy_bonus > 0.0:
		max_energy += c.energy_bonus
		energy = minf(max_energy, energy + c.energy_bonus)
		_msg("A luz do lagarto agora é sua: +%d Energia máxima." % int(c.energy_bonus))
		GameState.say_once("comeu_lagarto", "Comi uma lanterna. Agora EU sou a lanterna.")
	gain_xp(c.xp)
	c.consume()


func _rest(c: Cocoon) -> void:
	hp = max_hp
	energy = max_energy
	silk = max_silk
	satiety = maxf(0.0, satiety - 15.0)
	respawn_pos = c.global_position + Vector3(0.0, 0.1, 1.6)
	EventBus.rested.emit(c)
	GameState.save_now()
	_msg("Você descansou no casulo. Jogo salvo. O tempo passou (-15 saciedade).")
	GameState.say_once("primeiro_descanso", "Casulo quentinho... Isso aqui é meu agora. Meu território.")


func _weave_cocoon() -> void:
	if silk < SILK_COCOON:
		_msg("Seda insuficiente para o casulo (precisa de %d)." % int(SILK_COCOON))
		return
	var pos := global_position + aim_dir * 1.4
	pos.y = 0.0
	if not _has_floor(pos) or not is_on_floor():
		_msg("Teça o casulo em chão firme.")
		return
	if not WebNetwork.cocoons.is_empty() and not WebNetwork.is_in_territory(global_position):
		_msg("Novos casulos só dentro do território (perto de um casulo ou de fios ligados a ele).")
		return
	for existing in WebNetwork.cocoons:
		if is_instance_valid(existing) and Fx.flat_dist(existing.global_position, pos) < 4.0:
			_msg("Já existe um casulo aqui perto.")
			return
	silk -= SILK_COCOON
	WebNetwork.create_cocoon(pos)
	_msg("Casulo tecido! Descanse nele com E para salvar.")
	GameState.say_once("primeiro_casulo", "Um casulo! Agora tenho onde dormir sem virar janta.")


func _toggle_rune() -> void:
	rune_on = not rune_on
	if rune_on:
		_msg("Runa acesa.")
	else:
		_msg("Runa apagada: furtiva, mas a energia não regenera.")
		GameState.say_once("runa_apagada", "Shhh... Apagada, sou só mais uma sombra na caverna.")


# ================================================================= Modo Tecelagem

func _handle_weave(real_dt: float) -> void:
	var want := Input.is_action_pressed("weave") and not dead
	if want and not weaving:
		if energy >= 5.0:
			_enter_weave()
		elif Input.is_action_just_pressed("weave"):
			_msg("Energia baixa demais para tecer.")
	elif weaving and (not want or energy <= 0.0):
		_exit_weave()
	if not weaving:
		return
	energy = maxf(0.0, energy - WEAVE_ENERGY_PER_SEC * real_dt)
	energy_delay = 1.0
	var new_hover := _anchor_near(aim_point, 2.5)
	if new_hover != hovered_anchor:
		hovered_anchor = new_hover
		_refresh_anchor_highlights()
	if Input.is_action_just_pressed("attack"):
		_weave_click()
	if Input.is_action_just_pressed("bite"):
		_place_trap()
	_update_preview()


func _enter_weave() -> void:
	weaving = true
	weave_first = null
	hovered_anchor = null
	Engine.time_scale = WEAVE_TIME_SCALE
	_refresh_anchor_highlights()
	GameState.say_once("primeira_tecelagem", "Tudo ficou lento... Consigo ver onde prender meus fios.")


func _exit_weave() -> void:
	weaving = false
	weave_first = null
	hovered_anchor = null
	Engine.time_scale = 1.0
	_preview.visible = false
	_refresh_anchor_highlights()


func _refresh_anchor_highlights() -> void:
	for n in get_tree().get_nodes_in_group("anchor"):
		var a := n as WebAnchor
		if a == null:
			continue
		var mode := 0
		if weaving:
			mode = 1 if Fx.flat_dist(a.global_position, global_position) <= 24.0 else 0
			if a == hovered_anchor:
				mode = 3
			if a == weave_first:
				mode = 2
		a.set_highlight(mode)


func _weave_click() -> void:
	if hovered_anchor == null:
		_msg("Mire num pilar (âncora) para prender o fio.")
		return
	if weave_first == null:
		weave_first = hovered_anchor
		_refresh_anchor_highlights()
		return
	if hovered_anchor == weave_first:
		weave_first = null
		_refresh_anchor_highlights()
		return
	var err := _strand_error(weave_first, hovered_anchor)
	if err != "":
		_msg(err)
		return
	silk -= SILK_STRAND
	WebNetwork.create_strand(weave_first, hovered_anchor)
	_msg("Fio-guia tecido (-%d seda)." % int(SILK_STRAND))
	GameState.say_once("primeiro_fio", "Um fio! Andar nele é rápido e silencioso. Isso muda tudo.")
	weave_first = hovered_anchor
	_refresh_anchor_highlights()


func _strand_error(a: WebAnchor, b: WebAnchor) -> String:
	var d := Fx.flat_dist(a.global_position, b.global_position)
	if d > STRAND_RANGE:
		return "Longe demais: %.1f m (máximo %d m)." % [d, int(STRAND_RANGE)]
	if WebNetwork.has_strand(String(a.name), String(b.name)):
		return "Esses pilares já estão ligados."
	if silk < SILK_STRAND:
		return "Seda insuficiente (precisa de %d)." % int(SILK_STRAND)
	var q := PhysicsRayQueryParameters3D.create(a.global_position + Vector3.UP * 0.5, b.global_position + Vector3.UP * 0.5, 1)
	q.exclude = [a.get_rid(), b.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		return "Algo bloqueia o caminho entre os pilares."
	return ""


func _place_trap() -> void:
	if level < TRAP_LEVEL:
		_msg("Teia de captura libera no nível %d (F1 sobe de nível para testar)." % TRAP_LEVEL)
		return
	if silk < SILK_TRAP:
		_msg("Seda insuficiente para a teia de captura (precisa de %d)." % int(SILK_TRAP))
		return
	if Fx.flat_dist(aim_point, global_position) > TRAP_RANGE:
		_msg("Longe demais para lançar a teia (máximo %d m)." % int(TRAP_RANGE))
		return
	if not _has_floor(aim_point):
		_msg("A teia de captura precisa de chão firme.")
		return
	silk -= SILK_TRAP
	WebNetwork.create_trap(Vector3(aim_point.x, 0.0, aim_point.z))
	_msg("Teia de captura armada (-%d seda)." % int(SILK_TRAP))
	GameState.say_once("primeira_armadilha", "Pronto. Agora é só esperar alguém pisar... Paciência de aranha.")


func _update_preview() -> void:
	if weave_first == null:
		_preview.visible = false
		return
	var a := Vector3(weave_first.global_position.x, 0.1, weave_first.global_position.z)
	var target := aim_point
	var ok := true
	if hovered_anchor != null and hovered_anchor != weave_first:
		target = hovered_anchor.global_position
		ok = _strand_error(weave_first, hovered_anchor) == ""
	var b := Vector3(target.x, 0.1, target.z)
	if Fx.flat_dist(a, b) > STRAND_RANGE:
		ok = false
	var length := a.distance_to(b)
	_preview.visible = length > 0.1
	(_preview.mesh as BoxMesh).size = Vector3(0.07, 0.07, maxf(length, 0.01))
	Fx.orient_between(_preview, a, b)
	var col := Color(0.4, 1.0, 0.6) if ok else Color(1.0, 0.35, 0.3)
	_preview_mat.albedo_color = col
	_preview_mat.emission = col


# ================================================================= recursos, dano e morte

func _update_resources(delta: float) -> void:
	if dead:
		return
	_territory_timer -= delta
	if _territory_timer <= 0.0:
		_territory_timer = 0.4
		var was := in_territory
		in_territory = WebNetwork.is_in_territory(global_position)
		if in_territory and not was:
			GameState.say_once("territorio", "Sinto cada fio vibrando. Aqui é seguro... mais ou menos.")
	satiety = maxf(0.0, satiety - SATIETY_DECAY * delta)
	if satiety <= 0.0:
		_starve_msg_timer -= delta
		if _starve_msg_timer <= 0.0:
			_starve_msg_timer = 10.0
			_msg("Você está morrendo de fome! Coma algo.")
			GameState.say_once("fome", "Minha barriga está roncando tão alto que vai me denunciar.")
		_hurt(STARVE_DPS * delta)
	energy_delay = maxf(0.0, energy_delay - delta)
	if energy_delay <= 0.0 and rune_on and not weaving:
		energy = minf(max_energy, energy + ENERGY_REGEN * delta * (1.5 if in_territory else 1.0))
	if satiety > 30.0:
		silk = minf(max_silk, silk + delta)
	if satiety > 60.0:
		hp = minf(max_hp, hp + 0.5 * delta)


func take_damage(amount: float, source: Node3D = null, knockback: bool = true) -> void:
	if dead or invuln > 0.0:
		return
	invuln = 0.35
	_hurt_flash = 0.25
	if knockback and source != null:
		var push := global_position - source.global_position
		push.y = 0.0
		if push.length() > 0.01:
			external_velocity = push.normalized() * 6.0
	if state == State.EAT:
		_start_state(State.NORMAL)
	_hurt(amount)
	if not dead:
		GameState.say_once("primeiro_dano", "AI! Ok, ok, tudo aqui é maior que eu. Anotado.")


func pull_toward(point: Vector3, strength: float) -> bool:
	## Usado pela língua do sapo. Retorna false se a jogadora esquivou.
	if dead or invuln > 0.0 or state == State.DODGE:
		return false
	var d := point - global_position
	d.y = 0.0
	if d.length() > 0.1:
		external_velocity = d.normalized() * strength
	return true


func _hurt(amount: float) -> void:
	hp -= amount
	if hp <= 0.0 and not dead:
		_die()


func _die() -> void:
	dead = true
	hp = 0.0
	state = State.DEAD
	_death_timer = 2.5
	velocity = Vector3.ZERO
	if weaving:
		_exit_weave()
	_visual.rotation.z = PI
	_visual.position.y = 0.9
	EventBus.player_died.emit()
	EventBus.big_message.emit("Você morreu...")
	GameState.say_once("primeira_morte_pre", "Ah, não... tudo ficou escuro...")


func _respawn() -> void:
	dead = false
	state = State.NORMAL
	hp = max_hp
	energy = max_energy
	silk *= 0.5
	satiety = maxf(satiety, 40.0)
	global_position = respawn_pos
	last_safe_pos = respawn_pos
	velocity = Vector3.ZERO
	external_velocity = Vector3.ZERO
	_visual.rotation.z = 0.0
	_visual.position.y = 0.0
	snap_camera()
	_msg("Você acordou no último casulo. Perdeu metade da seda.")
	GameState.say_once("primeira_morte", "...Tá. Aranha teimosa não desiste.")


func _check_fall_and_safe(delta: float) -> void:
	if global_position.y < -4.0:
		global_position = last_safe_pos + Vector3.UP * 0.3
		velocity = Vector3.ZERO
		external_velocity = Vector3.ZERO
		_start_state(State.NORMAL)
		_hurt_flash = 0.25
		_msg("Você caiu no abismo! -%d PV" % int(FALL_DAMAGE))
		GameState.say_once("primeira_queda", "Não olha pra baixo. Não olha pra baixo. ...Olhei.")
		_hurt(FALL_DAMAGE)
		snap_camera()
		return
	_safe_timer -= delta
	if _safe_timer <= 0.0 and is_on_floor():
		_safe_timer = 0.25
		var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.3, global_position + Vector3.DOWN * 0.6, 1)
		if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			last_safe_pos = global_position


func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		max_hp += 10.0
		max_energy += 5.0
		max_silk += 5.0
		hp = minf(max_hp, hp + 30.0)
		EventBus.player_leveled.emit(level)
		_msg("Nível %d! PV, Energia e Seda máximos aumentaram." % level)
		if level == TRAP_LEVEL:
			GameState.say_once("nivel_3", "Nível 3! Sinto que consigo tecer uma teia de captura. Modo Tecelagem e botão direito.")


func xp_to_next() -> int:
	return 30 * level


# ================================================================= percepção (usada pelas criaturas)

func noise_radius() -> float:
	return noise


func visibility_mult() -> float:
	return 1.0 if rune_on else 0.45


# ================================================================= mira, câmera, visual

func _update_aim() -> void:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick.length() > 0.3:
		using_stick_aim = true
		aim_dir = Vector3(stick.x, 0.0, stick.y).normalized()
		aim_point = global_position + aim_dir * (2.0 + 10.0 * stick.length())
		return
	if using_stick_aim:
		if move_dir.length() > 0.2:
			aim_dir = move_dir.normalized()
		aim_point = global_position + aim_dir * 3.0
		return
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var normal := camera.project_ray_normal(mouse)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(origin, normal)
	if hit != null:
		aim_point = hit
		var d: Vector3 = aim_point - global_position
		d.y = 0.0
		if d.length() > 0.2:
			aim_dir = d.normalized()


func _update_camera(real_dt: float, snap: bool) -> void:
	var look := global_position
	if not using_stick_aim and not weaving and not dead:
		look += aim_dir * clampf(Fx.flat_dist(aim_point, global_position) * 0.2, 0.0, 2.5)
	var forward := -camera.global_transform.basis.z
	var target := look - forward * 40.0
	if snap:
		camera.global_position = target
	else:
		camera.global_position = camera.global_position.lerp(target, clampf(real_dt * 6.0, 0.0, 1.0))
	var want_size := 28.0 if weaving else 18.0
	camera.size = lerpf(camera.size, want_size, clampf(real_dt * 4.0, 0.0, 1.0))


func _update_visual(delta: float) -> void:
	if dead:
		return
	_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-aim_dir.x, -aim_dir.z), clampf(delta * 14.0, 0.0, 1.0))
	_leg_rig.velocity_hint = Vector3(velocity.x, 0.0, velocity.z)

	# Runa = Energia (e luz). Apagada = furtiva.
	var e := energy / max_energy
	var flicker := 1.0
	if e < 0.25:
		flicker = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.02)
	_rune_mat.emission_energy_multiplier = (0.4 + 3.0 * e) * flicker if rune_on else 0.1
	_rune_light.visible = rune_on
	_rune_light.light_energy = (0.5 + 1.2 * e) * flicker

	# Cachecol = Seda
	var s := 0.15 + 0.75 * silk / max_silk
	_scarf_tail.scale.z = s
	_scarf_tail.position.z = 0.1 + s * 0.5

	# Abdômen = Saciedade
	var a := 0.82 + 0.3 * satiety / max_satiety
	_abdomen.scale = Vector3(a, a, a)

	# Placas = PV
	var plates_left := ceili(4.0 * hp / max_hp)
	for i in _plates.size():
		_plates[i].visible = i < plates_left

	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	_body_mat.emission_enabled = _hurt_flash > 0.0
	_body_mat.emission = Color(1.0, 0.2, 0.2)
	if _model_overlay != null:
		_model_overlay.albedo_color.a = 0.5 if _hurt_flash > 0.0 else 0.0
	if state == State.DODGE:
		_visual.scale = Vector3(1.15, 0.7, 1.15)
	elif state == State.EAT:
		_visual.scale = Vector3(1.0, 0.85 + 0.1 * sin(state_time * 25.0), 1.0)
	else:
		_visual.scale = Vector3.ONE


# ================================================================= utilidades

func _msg(text: String) -> void:
	EventBus.message.emit(text)


func _has_floor(pos: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 1.0, pos + Vector3.DOWN * 1.0, 1)
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _anchor_near(point: Vector3, radius: float) -> WebAnchor:
	var best: WebAnchor = null
	var best_d := radius
	for n in get_tree().get_nodes_in_group("anchor"):
		var a := n as WebAnchor
		if a == null:
			continue
		var d := Fx.flat_dist(a.global_position, point)
		if d < best_d:
			best = a
			best_d = d
	return best


func _nearest_cocoon(radius: float) -> Cocoon:
	for c in WebNetwork.cocoons:
		if is_instance_valid(c) and Fx.flat_dist(c.global_position, global_position) <= radius:
			return c
	return null


func _nearest_corpse(radius: float) -> Corpse:
	var best: Corpse = null
	var best_d := radius
	for n in get_tree().get_nodes_in_group("corpse"):
		var c := n as Corpse
		if c == null:
			continue
		var d := Fx.flat_dist(c.global_position, global_position)
		if d < best_d:
			best = c
			best_d = d
	return best


# ================================================================= save

func to_dict() -> Dictionary:
	return {
		"hp": hp, "max_hp": max_hp,
		"energy": energy, "max_energy": max_energy,
		"silk": silk, "max_silk": max_silk,
		"satiety": satiety,
		"level": level, "xp": xp, "resist_rot": resist_rot,
		"respawn": [respawn_pos.x, respawn_pos.y, respawn_pos.z],
	}


func apply_carry(d: Dictionary) -> void:
	## Atributos vindos da camada anterior (sem posição: a jogadora entra pela entrada da camada).
	var keep := respawn_pos
	from_dict(d)
	respawn_pos = keep
	global_position = keep
	last_safe_pos = keep
	snap_camera()


func from_dict(d: Dictionary) -> void:
	max_hp = float(d.get("max_hp", max_hp))
	hp = float(d.get("hp", hp))
	max_energy = float(d.get("max_energy", max_energy))
	energy = float(d.get("energy", energy))
	max_silk = float(d.get("max_silk", max_silk))
	silk = float(d.get("silk", silk))
	satiety = float(d.get("satiety", satiety))
	level = int(d.get("level", level))
	xp = int(d.get("xp", xp))
	resist_rot = int(d.get("resist_rot", resist_rot))
	var r: Array = d.get("respawn", [])
	if r.size() == 3:
		respawn_pos = Vector3(float(r[0]), float(r[1]), float(r[2]))
		global_position = respawn_pos
		last_safe_pos = respawn_pos
	snap_camera()
