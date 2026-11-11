class_name CaveClock
extends Node
## O "dia" da caverna: os fungos acendem e apagam num ciclo de 5 minutos.
##   BRILHO  fungos acesos: larvas saem para pastar; caçadores (sapo, lagarto, morcegos,
##           Centopeia) ficam com sono e voltam às tocas.
##   CAÇA    fungos apagados: os caçadores acordam, os morcegos saem em bando, as larvas se escondem.
## Cada criatura diz em qual fase descansa (Creature.rest_phase).

enum Phase { BRILHO, CACA }
const PERIOD := 300.0
const NAMES := ["Fungos acesos — hora das larvas", "Fungos apagados — hora da caça"]

signal phase_changed(phase: int)

var t := PERIOD * 0.05
var paused := false
var phase: Phase = Phase.BRILHO
var _light_timer := 0.0


func _ready() -> void:
	phase = _phase_at(t)
	_apply_lights()


func _process(delta: float) -> void:
	if not paused:
		t = fmod(t + delta, PERIOD)
		var p := _phase_at(t)
		if p != phase:
			phase = p
			phase_changed.emit(phase)
			EventBus.message.emit(NAMES[phase] + ".")
			if phase == Phase.CACA:
				GameState.say_once("primeira_caca", "Os fungos estão apagando... e a caverna inteira acordou.")
			else:
				GameState.say_once("primeiro_brilho", "Luz de novo. Quem caça de noite foi dormir. Hora de eu caçar.")
	_light_timer -= delta
	if _light_timer <= 0.0:
		_light_timer = 0.3
		_apply_lights()


func _phase_at(x: float) -> Phase:
	return Phase.BRILHO if x < PERIOD * 0.5 else Phase.CACA


func set_phase(p: Phase, frac: float = 0.3) -> void:
	t = (0.0 if p == Phase.BRILHO else PERIOD * 0.5) + PERIOD * 0.5 * frac
	phase = p
	_apply_lights()


func glow() -> float:
	## 1,0 no meio do Brilho; 0,3 no meio da Caça. Muda devagar nas viradas.
	return 0.65 + 0.35 * cos((t / PERIOD) * TAU - PI * 0.5)


func seconds_to_change() -> float:
	return PERIOD * 0.5 - fmod(t, PERIOD * 0.5)


func _apply_lights() -> void:
	var g := glow()
	for n in get_tree().get_nodes_in_group("fungus_light"):
		var l := n as OmniLight3D
		if l != null:
			l.light_energy = float(l.get_meta("base", 1.2)) * g
