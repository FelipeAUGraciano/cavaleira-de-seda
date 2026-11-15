extends Node
## Bichos e coletáveis novos (15/11): Formiga-de-seda, Cobra-das-frestas, fragmentos de runa,
## cristal de seda e presas esquecidas. Rodar:  godot --headless --path . res://tests/novos_test.tscn

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
	player.invuln = 999.0
	await _pickups()
	await _ants()
	await _snake()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _pickups() -> void:
	var sp0 := player.skill_points
	for k in 4:
		var f := Pickup.new("fragmento", "t_frag_%d" % k)
		f.position = player.global_position + Vector3(8.0 + k * 2.0, 0, 0)
		layer.add_child(f)
	await _frames(3)
	for k in 4:
		player.global_position += Vector3(2.0 if k > 0 else 8.0, 0, 0)
		await _physics(10)
		if k == 2:
			_check(player.rune_shards == 3 and player.skill_points == sp0, "3 fragmentos ainda não dão ponto (%d)" % player.rune_shards)
	_check(player.rune_shards == 4 and player.skill_points == sp0 + 1, "4 fragmentos de runa = +1 ponto de habilidade")
	_check(GameState.flags.has("t_frag_0"), "fragmento pego fica salvo")
	var silk0 := player.max_silk
	var cs := Pickup.new("cristal_seda", "t_seda")
	cs.position = player.global_position + Vector3(3, 0, 0)
	layer.add_child(cs)
	await _frames(3)
	player.global_position += Vector3(3, 0, 0)
	await _physics(10)
	_check(is_equal_approx(player.max_silk, silk0 + 10.0), "cristal de seda: +10 Seda máxima")
	var n0 := player.pantry.size()
	var pr := Pickup.new("presa", "t_presa")
	pr.position = player.global_position + Vector3(0, 0, 3)
	layer.add_child(pr)
	await _frames(3)
	player.global_position += Vector3(0, 0, 3)
	await _physics(10)
	_check(player.pantry.size() == n0 + 1, "presa esquecida vai para a despensa")
	var d := player.to_dict()
	_check(int(d.get("shards", -1)) == 4, "fragmentos vão para o save")


func _ants() -> void:
	player.global_position = Vector3(20, 0.1, 10)   # longe
	var st := WebNetwork.create_strand(WebNetwork.anchors["Pilar_07"], WebNetwork.anchors["Pilar_08"])
	var hill := Anthill.new(6, [])
	hill.position = Vector3(-13, 0, 9)
	layer.ecosystem.add_child(hill)
	await _frames(5)
	var ants := hill.living()
	_check(ants.size() == 6, "formigueiro solta 6 formigas (%d)" % ants.size())
	var linked: int = ants.filter(func(a): return a.ahead != null).size()
	_check(linked == 5, "andam em fila: cada uma segue a da frente (%d)" % linked)
	for a in ants:
		a.needs.hunger = 60.0
		a.needs.fatigue = 0.0
		a.asleep = false
		a.brain.wake_up()
	var chewed := false
	for i in 60:
		await _seconds(0.5)
		if not is_instance_valid(st) or not WebNetwork.strands.has(st):
			chewed = true
			break
	_check(chewed, "formigas roem o fio-guia")
	# Alarme: bater numa chama as outras
	ants = hill.living()
	player.global_position = ants[0].global_position + Vector3(0, 0.1, 1.5)
	await _frames(2)
	ants[0].take_damage(1.0, player)
	await _frames(2)
	var called: int = ants.filter(func(a): return a.player_memory > 0.0).size()
	_check(called >= 4, "uma apanha, o bando vem (%d de %d)" % [called, ants.size()])
	await _seconds(1.5)
	var fighting: int = ants.filter(func(a): return is_instance_valid(a) and a.brain.is_doing("combat")).size()
	_check(fighting >= 3, "o bando ataca junto (%d)" % fighting)
	var a0: Ant = ants[0]
	var bite: Attack = a0.find_attack("mordida")
	var bite_ok: bool = bite != null and bite.damage <= 8.0
	_check(bite_ok and a0.max_hp <= 15.0, "sozinha é fraca (14 PV, mordida de 6)")
	for a in hill.living():
		a.queue_free()
	hill.queue_free()
	await _frames(3)


func _snake() -> void:
	var hole := Vector3(26, 0, 6)
	var sn := Snake.new()
	sn.position = hole + Vector3(0, 0.3, 0)
	sn.den = hole
	sn.out_dir = Vector3(-1, 0, 0)
	layer.ecosystem.add_child(sn)
	await _frames(5)
	sn.asleep = false
	sn.needs.fatigue = 0.0
	# parada na frente dela, a 4 m: não sente
	player.global_position = hole + Vector3(-4.0, 0.1, 0.0)
	player.velocity = Vector3.ZERO
	player.rune_on = false
	await _seconds(1.5)
	_check(sn.cur_attack == null and not sn.noticed_player, "parada, a cobra não te sente")
	# andando perto: bote
	var struck := false
	var face0 := Vector3.ZERO
	var marker_seen := false
	for i in 40:
		player.velocity = Vector3(0, 0, 3.0)
		player.rune_on = true
		await get_tree().physics_frame
		if sn.cur_attack != null:
			if not struck:
				face0 = sn.facing
			struck = true
			if sn._marker != null and sn._marker.visible:
				marker_seen = true
			if sn.atk_phase >= 1:
				break
	player.velocity = Vector3.ZERO
	_check(struck, "andando perto, ela dá o bote")
	_check(marker_seen, "o bote tem marca no chão")
	_check(face0.dot((player.global_position - hole).normalized() * Vector3(1, 0, 1)) > 0.8, "mira em você")
	_check(Fx.flat_dist(sn.global_position, hole) < 0.8, "não sai do buraco")
	await _seconds(0.4)
	_check(sn.cur_attack != null and sn.atk_phase == 2, "depois do bote fica exposta (recuperação)")
	# bote atravessando um fio: arrebenta
	var a: Attack = sn.find_attack("bote")
	sn.cur_attack = null
	sn.atk_gap = 0.0
	sn.facing = Vector3(-1, 0, 0)
	var s2 := WebNetwork.create_strand(WebNetwork.anchors["Pilar_15"], WebNetwork.anchors["Pilar_18"])
	var cross := false
	for k in 13:
		if s2.distance_to(hole + Vector3(-1, 0, 0) * (6.0 * k / 12.0)) < 0.6:
			cross = true
	sn.on_attack_active(a)
	_check(cross and not WebNetwork.strands.has(s2), "o bote arrebenta o fio no caminho (cruzava: %s)" % cross)


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _physics(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
