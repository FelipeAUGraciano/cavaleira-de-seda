class_name Brain
extends RefCounted
## Escolhe a atividade da criatura pela maior nota (utility AI), com um pouco de "teimosia"
## (a atividade atual ganha +0,1) para não ficar trocando toda hora.
## Decide 4× por segundo perto da jogadora e 1× por segundo longe (LOD).

const STICKY := 0.1

var behaviors: Array[Behavior] = []
var current: Behavior = null
var _timer := 0.0


func add(b: Behavior) -> Brain:
	behaviors.append(b)
	return self


func wake_up() -> void:
	## Algo importante aconteceu (viu a jogadora, levou dano): decide já no próximo quadro.
	_timer = 0.0


func find(id: String) -> Behavior:
	for b in behaviors:
		if b.id == id:
			return b
	return null


func is_doing(id: String) -> bool:
	return current != null and current.id == id


func tick(c: Creature, delta: float) -> Vector3:
	_timer -= delta
	if _timer <= 0.0 or current == null:
		_timer = c.decide_interval()
		decide(c)
	return current.run(c, delta) if current != null else Vector3.ZERO


func decide(c: Creature) -> void:
	if current != null and current.locked(c):
		return
	var best: Behavior = null
	var best_u := -1.0
	for b in behaviors:
		var u := b.utility(c)
		if b == current and u > 0.0:
			u += STICKY   # teimosia só vale para quem ainda quer continuar
		if u > best_u:
			best = b
			best_u = u
	if best != current:
		switch_to(c, best)


func switch_to(c: Creature, b: Behavior) -> void:
	if current != null:
		current.stop(c)
	current = b
	if current != null:
		current.start(c)
		c.activity = current.label
