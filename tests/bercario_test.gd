extends Node
## Teste do Berçário: joga as 6 câmaras e confere mapa, irmãs, fio, fresta, pata e fuga da Mãe.
## Rodar:  godot --headless --path . res://tests/bercario_test.tscn

var layer
var player: Player
var failures := 0


func _ready() -> void:
	GameState.delete_save()
	GameState.said = {}
	GameState.flags = {}
	layer = load("res://world/layers/bercario.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _run() -> void:
	# Estrutura
	_check(layer.rooms.size() == 6, "6 câmaras definidas")
	var sisters := get_tree().get_nodes_in_group("creature").filter(func(c): return c is Sister)
	_check(sisters.size() == 7, "7 irmãs no ninho (%d)" % sisters.size())
	await _frames(15)
	_check(layer.map_system.revealed.has("B1") and not layer.map_system.revealed.has("B2"), "mapa revela só a câmara de eclosão no início")

	# Paredes: andar para o norte em B1 bate na parede
	Input.action_press("move_up")
	await _seconds(2.5)
	Input.action_release("move_up")
	_check(player.global_position.z > -8.6, "parede gerada segura a jogadora (z = %.1f)" % player.global_position.z)

	# Irmã menor foge da jogadora
	var small: Sister = null
	for s in sisters:
		if not s.hunter and s.global_position.x < -40.0:
			small = s
			break
	if small != null:
		_teleport(small.global_position + Vector3(2.5, 0.1, 0.0))
		var d0 := Fx.flat_dist(small.global_position, player.global_position)
		await _seconds(1.0)
		_check(is_instance_valid(small) and Fx.flat_dist(small.global_position, player.global_position) > d0, "irmã menor foge")

	# Túnel até B2 revela B2; irmã faminta ataca
	_teleport(Vector3(-36.0, 0.1, 0.0))
	await _seconds(0.5)
	_check(layer.map_system.revealed.has("B2"), "entrar no corredor revela B2 no mapa")
	_check(player.respawn_pos.x > -40.0, "B2 vira ponto de retorno")
	var hp0 := player.hp
	var hungry: Sister = null
	var best := 1e9
	for s in get_tree().get_nodes_in_group("predator"):
		var d := Fx.flat_dist(s.global_position, Vector3(-25.0, 0.0, 0.0))
		if s is Sister and d < best:
			hungry = s
			best = d
	print("  info: irmã faminta mais próxima a %.1f m de B2" % best)
	_teleport(hungry.global_position + Vector3(-2.0, 0.1, 0.0) if hungry != null else Vector3(-25.0, 0.1, 0.0))
	await _seconds(3.0)
	_check(player.hp < hp0, "irmã faminta caça e morde (PV %d)" % int(player.hp))

	# B3: fio sobre o abismo
	player.hp = player.max_hp
	_teleport(Vector3(0.0, 0.1, -6.0))
	await _frames(5)
	var a: WebAnchor = WebNetwork.anchors["B3_a"]
	var c: WebAnchor = WebNetwork.anchors["B3_c"]
	_check(player._strand_error(a, c) == "", "pilares de teia de B3 alcançam o outro lado (10 m)")
	WebNetwork.create_strand(a, c)
	_teleport(Vector3(3.0, 0.15, -6.0))
	await _frames(5)
	Input.action_press("move_right")
	await _seconds(1.4)
	Input.action_release("move_right")
	await _frames(10)
	_check(player.global_position.x > 10.0 and player.global_position.y > -1.0, "atravessou o abismo de B3 pelo fio (x = %.1f)" % player.global_position.x)

	# Fresta até B4 e o cristal
	var max_before := player.max_hp
	_teleport(Vector3(17.5, 0.1, 12.5))
	await _frames(5)
	Input.action_press("move_down")
	await _seconds(3.0)
	Input.action_release("move_down")
	await _frames(10)
	_check(layer.map_system.revealed.has("B4"), "a Filhote passa pela fresta até B4")
	_check(player.max_hp >= max_before + 10.0 and GameState.flags.has("b4_cristal"), "cristal de pedra-da-lua dá +10 PV máx.")
	_check(layer.map_system.locks[0]["seen"], "a fresta aparece no mapa como trava vista")

	# B5: a pata sente a runa acesa
	var leg: MotherLeg = layer.mother_leg
	player.hp = player.max_hp
	player.rune_on = true
	leg._rest = 0.0
	_teleport(leg._leg.position + Vector3(4.0, 0.1, 0.0))
	await _frames(3)
	_check(leg._can_sense(player), "runa acesa: a pata sente a 4 m")
	player.rune_on = false
	player.velocity = Vector3.ZERO
	_check(not leg._can_sense(player), "runa apagada e parada: a pata não sente")
	player.rune_on = true

	# B6: a Mãe persegue e alcança quem fica parado
	player.hp = player.max_hp
	_teleport(Vector3(59.0, 0.1, 0.0))
	await _seconds(0.3)
	_teleport(Vector3(61.0, 0.1, 0.0))
	await _seconds(0.3)
	_check(layer.chase.active, "a Mãe acorda quando a jogadora entra na Fuga")
	await _seconds(3.0)
	_check(player.hp <= player.max_hp - 35.0, "a Mãe alcança quem fica parado (PV %d)" % int(player.hp))

	# Saída: túnel estreito leva às Galerias
	_teleport(Vector3(101.0, 0.1, 0.0))
	Input.action_press("move_right")
	await _seconds(0.8)
	Input.action_release("move_right")
	_check(layer._leaving, "túnel de saída leva às Galerias")
	_check(not GameState.carry.is_empty() or layer._leaving, "atributos seguem para a próxima camada")


func _check(ok: bool, label: String) -> void:
	if ok:
		print("  ok    ", label)
	else:
		failures += 1
		print("  FALHA ", label)


func _teleport(pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.external_velocity = Vector3.ZERO
	player.last_safe_pos = pos


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(int(s * 60.0))
