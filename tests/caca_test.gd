extends Node
## IA de caça: interesse que cai, desistir, trocar de presa, revidar e coleira de casa.
## Rodar:  godot --headless --path . res://tests/caca_test.tscn

var player: Player
var layer
var failures := 0


func _ready() -> void:
	GameState.permadeath = false
	GameState.delete_save()
	layer = load("res://world/layers/test_chamber.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	for c in World.creatures.duplicate():
		c.queue_free()
	await _frames(2)
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _frog(at: Vector3, hunger: float) -> Frog:
	var f := Frog.new()
	f.position = at
	layer.ecosystem.add_child(f)
	await _frames(3)
	f.home = at
	f.needs.hunger = hunger
	f.needs.fatigue = 0.0
	f.needs.restless = 0.0
	f.asleep = false
	return f


func _run() -> void:
	var base := Vector3(-14, 0.1, 8)
	player.global_position = base
	player.rune_on = true
	player.invuln = 999.0   # o teste é sobre a IA: a aranha não morre
	await _frames(5)

	# 1. Vê você: o interesse sobe e ele caça
	var f := await _frog(base + Vector3(4.0, 0.2, 0.0), 60.0)
	f.brain.wake_up()
	await _seconds(1.5)
	_check(f.interest > 20.0 and f.hunting_player(), "sapo te vê e caça (interesse %.0f)" % f.interest)

	# 2. Você vai para um fio sobre o abismo (ele não alcança): desiste em vez de esperar para sempre
	var st := WebNetwork.create_strand(WebNetwork.anchors["Pilar_09"], WebNetwork.anchors["Pilar_11"])
	var mid := (st.a_pos + st.b_pos) * 0.5
	player.global_position = Vector3(mid.x, 0.06, mid.z)
	f.global_position = Vector3(mid.x - 7.0, 0.3, mid.z)   # na beira oeste do abismo
	var gave_up := false
	for i in 40:
		await _seconds(0.5)
		player.global_position = Vector3(mid.x, 0.06, mid.z)
		player.velocity = Vector3(3, 0, 0)   # "fazendo barulho": antes isso prendia o sapo para sempre
		if not f.hunting_player() and f.player_memory <= 0.0:
			gave_up = true
			break
	_check(gave_up, "você no fio, fora do alcance: o sapo desiste da caçada")
	player.global_position = base
	_check(f.bored_of_player(), "e fica um tempo sem ligar para você")

	# 3. Desistiu: ver você de longe não reacende; encostar reacende
	f.global_position = base + Vector3(4.0, 0.2, 0.0)
	await _frames(2)
	player.global_position = f.global_position + Vector3(0, 0, 8.0)
	await _seconds(1.0)
	_check(not f.hunting_player(), "de longe (8 m) ele continua sem ligar")
	var back := false
	for i in 10:
		player.global_position = f.global_position + Vector3(0, 0, f.body_radius + 1.0)
		f.face_toward(player.global_position)   # na frente dele (de costas ele não vê)
		await _seconds(0.2)
		if f.hunting_player():
			back = true
			break
	_check(back, "encostou nele: ele volta a caçar")

	# 4. Presa fácil por perto com pouco interesse em você: troca de alvo
	f.interest = 15.0
	player.global_position = f.global_position + Vector3(0, 0, 9.0)
	var larva := Larva.new()
	larva.position = f.global_position + Vector3(2.5, 0.2, 0.0)
	layer.ecosystem.add_child(larva)
	await _frames(3)
	larva.asleep = true
	f.needs.hunger = 80.0
	var switched := false
	for i in 20:
		await _seconds(0.3)
		if f.brain.current != null and f.brain.current.id == "forage":
			switched = true
			break
	_check(switched, "com fome e pouco interesse, troca você pela larva ao lado (%s)" % (f.brain.current.id if f.brain.current else "-"))

	# 5. Bateu nele enquanto caçava outra coisa: ele revida
	if is_instance_valid(f) and not f.dead:
		f.take_damage(1.0, player)
		await _seconds(0.6)
		_check(f.brain.current != null and f.brain.current.id == "combat", "apanhou de você: larga a presa e revida")

	# 6. Coleira: já foi longe demais atrás de você, perde a vontade
	if is_instance_valid(f) and not f.dead:
		f._hunt_origin = f.global_position + Vector3(40.0, 0, 0)
		f._provoked_t = 0.0
		player.global_position = f.global_position + Vector3(0, 0, 4.0)
		var leashed := false
		for i in 30:
			await _seconds(0.5)
			if not f.hunting_player():
				leashed = true
				break
		_check(leashed, "longe demais de onde a caçada começou, ele desiste mesmo te vendo")


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
