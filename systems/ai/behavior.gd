class_name Behavior
extends RefCounted
## Uma atividade que uma criatura pode fazer (dormir, comer, fugir...).
## O Brain pergunta a nota de cada uma (utility) e roda a melhor.
##   utility(c)  0 = não quer; ~1 = quer muito. Combate vale 1,0; passear, uns 0,3.
##   start/stop  ao começar e ao trocar por outra
##   run(c, dt)  devolve a velocidade desejada (como o _think das criaturas)
##   locked(c)   true = não pode ser interrompida agora (no meio de um bote)

var id := "?"
var label := "?"     ## texto mostrado na Leitura ("Dormindo", "Caçando"...)


func utility(_c: Creature) -> float:
	return 0.0


func start(_c: Creature) -> void:
	pass


func run(_c: Creature, _delta: float) -> Vector3:
	return Vector3.ZERO


func stop(_c: Creature) -> void:
	pass


func locked(_c: Creature) -> bool:
	return false
