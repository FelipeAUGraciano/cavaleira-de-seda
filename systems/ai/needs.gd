class_name Needs
extends RefCounted
## O que uma criatura sente por dentro, de 0 a 100. O cérebro (Brain) usa isso para decidir.
##   hunger    fome: sobe com o tempo, cai ao comer
##   fatigue   sono: sobe rápido na fase de descanso da espécie, devagar na outra; cai dormindo
##   fear      medo: vem de ameaças por perto e some sozinho
##   restless  vontade de passear: leva a criatura para outras câmaras

var hunger := 30.0
var fatigue := 20.0
var fear := 0.0
var restless := 0.0

var hunger_rate := 0.6      ## por segundo
var fatigue_rest := 0.35    ## por segundo, na fase de descanso
var fatigue_active := 0.03  ## por segundo, na fase ativa
var sleep_recovery := 3.0   ## por segundo, dormindo
var restless_rate := 0.35   ## por segundo, na fase ativa (um terço na de descanso)
var fear_decay := 18.0      ## por segundo


func randomize_start() -> void:
	hunger = randf_range(15.0, 55.0)
	fatigue = randf_range(0.0, 35.0)
	restless = randf_range(0.0, 40.0)


func tick(delta: float, resting_phase: bool, asleep: bool) -> void:
	hunger = minf(100.0, hunger + hunger_rate * delta)
	if asleep:
		fatigue = maxf(0.0, fatigue - sleep_recovery * delta)
	else:
		fatigue = minf(100.0, fatigue + (fatigue_rest if resting_phase else fatigue_active) * delta)
	restless = minf(100.0, restless + restless_rate * delta * (0.3 if resting_phase else 1.0))
	fear = maxf(0.0, fear - fear_decay * delta)


func feel_fear(amount: float) -> void:
	fear = clampf(maxf(fear, amount), 0.0, 100.0)
