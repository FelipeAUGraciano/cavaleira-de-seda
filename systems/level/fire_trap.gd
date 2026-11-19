class_name FireTrap
extends Node3D
## Placa de metal com óleo por baixo (G5). Pisou (no chão), estoura fogo: queima você, os fios
## por perto e faz barulho (sobe o alerta). Rearma em 8 s. Sobre um fio, não dispara.
var armed := true
var _t := 0.0
var _plate: MeshInstance3D
var _burst: MeshInstance3D

func _ready() -> void:
	add_to_group("fire_trap")
	var steel := Fx.mat(Color(0.35, 0.33, 0.3))
	steel.metallic = 0.8
	_plate = Fx.cylinder(0.55, 0.05, steel)
	_plate.position.y = 0.03
	add_child(_plate)
	_burst = Fx.cylinder(1.1, 2.2, Fx.mat(Color(1.0, 0.5, 0.12), 3.0, true, 0.7))
	_burst.position.y = 1.1
	_burst.visible = false
	add_child(_burst)

func _physics_process(delta: float) -> void:
	if not armed:
		_t += delta
		_burst.visible = _t < 0.8
		if _t > 8.0:
			armed = true
		return
	var p := GameState.player as Player
	if p == null or p.dead or p.on_strand:
		return
	if Fx.flat_dist(p.global_position, global_position) < 0.85:
		armed = false
		_t = 0.0
		Sfx.play("armadilha_estalo", global_position)
		Sfx.play("armadilha_fogo", global_position)
		if p.take_damage(16.0 * maxf(0.4, p.fire_mult()), null, false):
			p.apply_burn(3.0)
		for s in WebNetwork.strands.duplicate():
			if is_instance_valid(s) and (s as WebStrand).distance_to(global_position) < 2.5:
				WebNetwork.burn_strand(s)
		EventBus.message.emit("Armadilha de fogo!")
		GameState.say_once("a4_armadilha", "FOGO NO CHÃO! Eles armaram o CHÃO!")
		var l = GameState.current_layer
		if l != null and "hunt" in l and l.hunt != null:
			l.hunt.raise(0.5, global_position)
