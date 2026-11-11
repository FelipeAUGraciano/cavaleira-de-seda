class_name Lizard
extends Creature
## Lagarto-lanterna (M): territorial. Uma isca de luz na cabeça atrai larvas, que ele come.
## A luz também revela quem chega perto (runa apagada não esconde a 5 m da isca).
## Quem entra no território leva um aviso (isca pisca vermelho); quem fica, é atacado:
## mordida de perto e investida de longe. Não persegue para fora do território.
## Comer o lagarto dá Energia máxima.

enum Mode { IDLE, WARN, CHASE, BITE, CHARGE, RETURN, EAT }

const SIGHT := 9.0
const FOV := 130.0
const LURE_REVEAL := 5.0
const LURE_PULL := 9.0
const BITE_DAMAGE := 12.0
const CHARGE_DAMAGE := 18.0
const CHARGE_SPEED := 11.0

var territory_radius := 9.0
var mode: Mode = Mode.IDLE
var mode_time := 0.0
var attack_done := false
var bite_cd := 0.0
var charge_cd := 2.0
var hunger := 30.0
var charge_dir := Vector3.ZERO
var lure: OmniLight3D
var _lure_mat: StandardMaterial3D
var _warned := false


func _init() -> void:
	display_name = "Lagarto-lanterna"
	size = Size.M
	level = 5
	max_hp = 70.0
	speed = 3.4
	body_radius = 0.6
	body_color = Color(0.36, 0.42, 0.3)
	food_satiety = 45.0
	food_silk = 25.0
	food_xp = 45
	food_energy = 10.0
	senses_text = "visão (9 m, cone de 130°); a isca revela tudo a 5 m"
	model_name = "lagarto"
	model_size = 2.4
	model_fit = "length"


func _ready() -> void:
	super._ready()
	add_to_group("predator")
	add_to_group("lure")
	collision_mask = 1 | 2   # larvas hipnotizadas em volta da isca não o prendem


func _build_visual() -> void:
	var body := Fx.sphere(body_radius, _mat)
	body.scale = Vector3(0.9, 0.5, 1.8)
	body.position.y = body_radius * 0.5
	_visual.add_child(body)
	var head := Fx.sphere(body_radius * 0.6, _mat)
	head.scale = Vector3(1.0, 0.7, 1.2)
	head.position = Vector3(0.0, body_radius * 0.6, -body_radius * 1.6)
	_visual.add_child(head)
	var tail := Fx.box(Vector3(0.18, 0.12, 1.2), _mat)
	tail.position = Vector3(0.0, body_radius * 0.35, body_radius * 1.9)
	_visual.add_child(tail)
	var stalk := Fx.box(Vector3(0.04, 0.5, 0.04), Fx.mat(body_color.darkened(0.3)))
	stalk.position = Vector3(0.0, body_radius * 1.1, -body_radius * 1.8)
	stalk.rotation.x = -0.4
	_visual.add_child(stalk)
	_lure_mat = Fx.mat(Color(0.75, 1.0, 0.45), 3.0, true)
	var bulb := Fx.sphere(0.12, _lure_mat)
	bulb.position = Vector3(0.0, body_radius * 1.4, -body_radius * 2.1)
	_visual.add_child(bulb)
	lure = OmniLight3D.new()
	lure.light_color = Color(0.75, 1.0, 0.45)
	lure.omni_range = 6.0
	lure.light_energy = 1.6
	lure.position = bulb.position + Vector3(0.0, 0.3, 0.0)
	_visual.add_child(lure)
	_body_parts = [body, head, tail]   # a isca continua por código (é a luz que importa)


func lure_position() -> Vector3:
	return lure.global_position if lure != null else global_position


func sees(p: Player) -> bool:
	if p == null or p.dead:
		return false
	if Fx.flat_dist(lure_position(), p.global_position) <= LURE_REVEAL and has_line_of_sight(p):
		return true
	return can_see(p, SIGHT * p.visibility_mult(), FOV)


func in_territory(pos: Vector3) -> bool:
	return Fx.flat_dist(pos, home) <= territory_radius


func _think(delta: float) -> Vector3:
	mode_time += delta
	bite_cd -= delta
	charge_cd -= delta
	hunger = minf(100.0, hunger + delta * 2.0)
	var p := GameState.player as Player
	var intruder := p != null and not p.dead and in_territory(p.global_position) and sees(p)

	match mode:
		Mode.BITE:
			return _do_bite(p)
		Mode.CHARGE:
			return _do_charge(p)
		Mode.EAT:
			if mode_time > 2.0 or intruder:
				mode = Mode.IDLE
			if not intruder:
				return Vector3.ZERO
		Mode.RETURN:
			if flat_dist_to_home() < 1.0:
				mode = Mode.IDLE
				return Vector3.ZERO
			if intruder:
				mode = Mode.CHASE
			return move_to(home, 0.8)
		Mode.WARN:
			face_toward(p.global_position if p != null else home)
			if not intruder and mode_time > 0.4:
				mode = Mode.IDLE
				return Vector3.ZERO
			if mode_time >= 1.4:
				mode = Mode.CHASE
				mode_time = 0.0
			return Vector3.ZERO
		Mode.CHASE:
			if p == null or p.dead or Fx.flat_dist(p.global_position, home) > territory_radius + 3.0:
				mode = Mode.RETURN
				EventBus.message.emit("O Lagarto-lanterna volta para o território.")
				return Vector3.ZERO
			return _chase(p)

	# IDLE: avisa intrusos, come larvas atraídas pela isca, fica perto de casa
	if intruder:
		mode = Mode.WARN
		mode_time = 0.0
		if not _warned:
			_warned = true
			EventBus.message.emit("O Lagarto-lanterna pisca a isca: você está no território dele!")
			GameState.say_once("lagarto_aviso", "Ok, ok, entendi o recado luminoso. ...Ou não entendi?")
		return Vector3.ZERO
	var snack := _larva_in_reach()
	if snack != null and hunger > 20.0:
		face_toward(snack.global_position)
		snack.take_damage(999.0, self)
		hunger = 0.0
		mode = Mode.EAT
		mode_time = 0.0
		return Vector3.ZERO
	return wander(delta, 3.0, 0.2)


func flat_dist_to_home() -> float:
	return Fx.flat_dist(global_position, home)


func _chase(p: Player) -> Vector3:
	var d := flat_dist_to(p)
	face_toward(p.global_position)
	if d <= 1.9 and bite_cd <= 0.0:
		_begin(Mode.BITE)
		return Vector3.ZERO
	if d >= 3.0 and d <= 7.0 and charge_cd <= 0.0 and has_line_of_sight(p):
		_begin(Mode.CHARGE)
		return Vector3.ZERO
	if d <= 1.5:
		return Vector3.ZERO
	return move_to(p.global_position, 1.0)


func _begin(m: Mode) -> void:
	mode = m
	mode_time = 0.0
	attack_done = false
	telegraph = true


func _do_bite(p: Player) -> Vector3:
	if p != null:
		face_toward(p.global_position)
	if not attack_done and mode_time >= 0.45:
		attack_done = true
		telegraph = false
		if p != null and not p.dead and flat_dist_to(p) <= 2.3:
			p.take_damage(BITE_DAMAGE, self)
	if mode_time >= 0.8:
		bite_cd = 1.4
		mode = Mode.CHASE
	return Vector3.ZERO


func _do_charge(p: Player) -> Vector3:
	if mode_time < 0.6:
		if p != null:
			face_toward(p.global_position)
			charge_dir = facing
		return Vector3.ZERO
	telegraph = false
	if mode_time >= 1.05:
		charge_cd = 3.5
		mode = Mode.CHASE
		return Vector3.ZERO
	if not attack_done and p != null and not p.dead and flat_dist_to(p) <= body_radius + 0.8:
		attack_done = true
		p.take_damage(CHARGE_DAMAGE, self)
	return safe_dir(charge_dir) * CHARGE_SPEED


func _larva_in_reach() -> Larva:
	for n in get_tree().get_nodes_in_group("creature"):
		var l := n as Larva
		if l != null and not l.dead and (Fx.flat_dist(l.global_position, lure_position()) < 1.4 or flat_dist_to(l) < body_radius + 1.0):
			return l
	return null


func _on_hurt(source: Node3D) -> void:
	if source != null and source.is_in_group("player") and mode != Mode.BITE and mode != Mode.CHARGE:
		mode = Mode.CHASE
		mode_time = 0.0


func _update_glow(delta: float) -> void:
	super._update_glow(delta)
	if _lure_mat == null:
		return
	var warn := mode == Mode.WARN or mode == Mode.CHARGE and mode_time < 0.6
	var c := Color(1.0, 0.25, 0.2) if warn else Color(0.75, 1.0, 0.45)
	var pulse := 1.0 + 0.5 * sin(_anim_t * (14.0 if warn else 2.5))
	_lure_mat.albedo_color = c
	_lure_mat.emission = c
	_lure_mat.emission_energy_multiplier = 3.0 * pulse
	lure.light_color = c
	lure.light_energy = 1.6 * pulse


func _animate(_delta: float, speed_now: float) -> void:
	_visual.rotation.z = sin(_anim_t * 9.0) * 0.08 * clampf(speed_now / speed, 0.0, 1.5)
