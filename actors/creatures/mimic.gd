class_name Mimic
extends Creature
## Mímico de estalagmite (M). Fica parado no meio dos pilares fingindo ser um: mesma pedra,
## mesma altura. Quem passa perto (2,4 m) leva o bote: agarra, puxa e morde.
## Pistas: no Modo Tecelagem ele não acende como os pilares de verdade, e a Leitura (Alt)
## mostra que é bicho. Depois do bote, luta devagar; se você se afastar, volta a se fingir de pedra.
## Comer dá Energia máxima (a pedra-viva guarda energia).

enum Mode { HIDDEN, STRIKE, AWAKE }

const GRAB_R := 2.4
const GRAB_DAMAGE := 22.0

var mode: Mode = Mode.HIDDEN
var _t := 0.0
var _rock: Node3D
var _maw: Node3D


func _init() -> void:
	uses_interest = false
	display_name = "Mímico de estalagmite"
	size = Size.M
	level = 8
	max_hp = 95.0
	speed = 1.6
	body_radius = 0.5
	body_color = Color(0.24, 0.23, 0.3)
	food_satiety = 55.0
	food_silk = 25.0
	food_xp = 70
	food_energy = 8.0
	senses_text = "vibração bem de perto (2,4 m); parece um pilar"
	aggression = 0.6
	memory_time = 3.0
	attack_damage = 18.0
	attack_reach = 1.6
	combat_label = "Mordendo"
	add_attack(Attack.make("mordida", "Mordida de pedra", {"max_range": 2.4, "windup": 0.5, "active": 0.18, "recover": 0.7,
		"cooldown": 1.6, "damage": 18.0, "reach": 2.2, "arc": 110.0, "lunge": 2.0, "weight": 3.0}))
	add_attack(Attack.make("lingua", "Língua de pedra", {"min_range": 2.0, "max_range": 5.0, "windup": 0.6, "active": 0.2,
		"recover": 0.8, "cooldown": 4.5, "damage": 8.0, "shape": Attack.Shape.LINE, "reach": 5.0, "width": 0.7,
		"knockback": false, "effect": "pull", "effect_power": 10.0, "weight": 2.0}))


func _ready() -> void:
	super._ready()
	add_to_group("predator")
	add_to_group("mimic")


func notices_player(p: Player) -> bool:
	if mode == Mode.HIDDEN:
		return false
	return flat_dist_to(p) < 7.0


func sees_player_as_prey(_p: Player) -> bool:
	return mode != Mode.HIDDEN


func _make_brain() -> Brain:
	return Brain.new() \
		.add(Behaviors.Combat.new("Mordendo")) \
		.add(Behaviors.Wander.new(0.5, 0.0))


func _think(delta: float) -> Vector3:
	_t += delta
	var p := GameState.player as Player
	match mode:
		Mode.HIDDEN:
			activity = "Parado (parece pedra)"
			if p != null and not p.dead and not p.on_strand and flat_dist_to(p) < GRAB_R:
				mode = Mode.STRIKE
				_t = 0.0
				face_toward(p.global_position)
				EventBus.big_message.emit("O pilar MORDEU!")
				GameState.say_once("mimico", "ESSE PILAR TEM DENTE! Esse pilar tem DENTE!")
			return Vector3.ZERO
		Mode.STRIKE:
			if _t > 0.35:
				if p != null and not p.dead and flat_dist_to(p) < GRAB_R + 0.8:
					if p.take_damage(GRAB_DAMAGE, self, false):
						p.pull_toward(global_position, 8.0)
						p.apply_slow(0.5, 1.5)
				mode = Mode.AWAKE
				_t = 0.0
				player_memory = memory_time
				if p != null:
					last_player_pos = p.global_position
			return Vector3.ZERO
		Mode.AWAKE:
			if p == null or p.dead or flat_dist_to(p) > 9.0:
				if _t > 4.0:
					mode = Mode.HIDDEN   # perdeu você: volta a se fingir de pedra
					player_memory = 0.0
					return Vector3.ZERO
			else:
				_t = 0.0
			return super._think(delta)
	return Vector3.ZERO


func _build_visual() -> void:
	## Por fora, um pilar como os outros; por dentro, uma boca de pedra que abre no bote.
	_rock = Node3D.new()
	_visual.add_child(_rock)
	var stone := _mat
	var h := 3.2
	var col := Fx.cylinder(0.42, h, stone)
	(col.mesh as CylinderMesh).top_radius = 0.12
	col.position.y = h * 0.5
	_rock.add_child(col)
	var base := Fx.sphere(0.6, stone)
	base.scale = Vector3(1.0, 0.45, 1.0)
	base.position.y = 0.15
	_rock.add_child(base)
	_maw = Node3D.new()
	_maw.position = Vector3(0, 0.9, -0.3)
	_maw.visible = false
	_visual.add_child(_maw)
	var tooth := Fx.mat(Color(0.85, 0.82, 0.75))
	for k in 6:
		var t := Fx.cylinder(0.05, 0.3, tooth)
		(t.mesh as CylinderMesh).top_radius = 0.005
		var a := (k - 2.5) * 0.35
		t.position = Vector3(sin(a) * 0.35, 0.15 if k % 2 == 0 else -0.15, -cos(a) * 0.2)
		t.rotation.x = PI if k % 2 == 0 else 0.0
		_maw.add_child(t)
	var inside := Fx.sphere(0.25, Fx.mat(Color(0.5, 0.1, 0.15), 0.8))
	inside.scale = Vector3(1.4, 0.8, 0.6)
	_maw.add_child(inside)
	_body_parts = [col, base]


func _animate(_delta: float, _speed_now: float) -> void:
	_maw.visible = mode != Mode.HIDDEN
	var open := 0.0 if mode == Mode.HIDDEN else (1.0 if mode == Mode.STRIKE or telegraph else 0.5)
	_maw.scale = Vector3.ONE * lerpf(0.6, 1.2, open)
	_rock.rotation.z = sin(_anim_t * 20.0) * 0.06 if mode == Mode.STRIKE else 0.0
