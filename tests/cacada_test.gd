extends Node
## Ato 4, a caçada: chegada pela Chaminé, expedição, alerta 0–3, esquadrão, batedor que queima
## fios, armadilhas de fogo, toca na ilha, toca antiga queimada, caçadores viram comida,
## a Capitã (trompa) e o fim do ato.
## Rodar:  godot --headless --path . res://tests/cacada_test.tscn

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	reparent(get_tree().root)
	get_tree().current_scene = null
	GameState.new_game()
	GameState.delete_save()
	for f in ["g14_centopeia", "a12_serpente", "r12_rainha", "ato2_fim", "a1_queda"]:
		GameState.flags[f] = true
	await _frames(5)
	get_tree().change_scene_to_file("res://world/layers/rio_brasa.tscn")
	await _seconds(3.0)
	var player: Player = GameState.player
	player.invuln = 999.0
	player.global_position = Vector3(188, 0.1, 74)
	var ls: Node = null
	for i in 60:
		await _seconds(0.1)
		var f := get_tree().get_nodes_in_group("loading_screen")
		if not f.is_empty():
			ls = f[0]
			break
	_check(ls != null and ls.header == "Fim do Ato 3", "Chaminé: tela 'Fim do Ato 3'")
	var arrived := await _wait_scene("galerias_cacada.tscn")
	_check(arrived, "chega nas Galerias do Ato 4")
	if not arrived:
		return _end()
	await _seconds(4.5)
	var g = get_tree().current_scene
	player = GameState.player
	_check(g.hud._area == "Galerias Úmidas" and g.layer_subtitle.begins_with("Ato 4"), "título 'Galerias Úmidas · Ato 4'")
	_check(World.nav.room_at(player.global_position) == "G12", "sai da Chaminé no Ninho dos lagartos (%s)" % World.nav.room_at(player.global_position))
	_check(GameState.hunt_alert == 0.0, "alerta da caçada começa em 0")
	for i in 40:
		if not player.autopilot:
			break
		await _seconds(0.1)
	player.invuln = 999.0

	# a expedição e os bichos
	var hunters: Array = get_tree().get_nodes_in_group("hunter")
	_check(hunters.size() >= 13, "a expedição: %d caçadores" % hunters.size())
	var roles := {}
	var deep := 0
	for h in hunters:
		roles[(h as Hunter).role] = true
		if (h as Node3D).global_position.z > Galerias.DEEP - 5.0:
			deep += 1
	_check(roles.has("espadachim") and roles.has("arqueira") and roles.has("batedor") and roles.has("capita"), "espadachins, arqueiras, batedores e a Capitã")
	_check(deep == 0, "nenhum caçador nas Profundezas (rota de fuga)")
	var alfa := 0
	for c in World.creatures:
		if c.display_name.ends_with(" alfa"):
			alfa += 1
	_check(alfa >= 4, "os bichos que sobraram são alfas (%d)" % alfa)
	_check(g.den != null and Fx.flat_dist(g.den.center, Galerias.WL3(-3, 0, 74)) < 1.0, "a única toca é a ilha do Lago escondido")
	_check(_reach(player.global_position, Galerias.W(Vector3(44, 0, 36))), "dá para andar até o acampamento (G4)")

	# alerta: ser vista sobe; no 3 o esquadrão sai
	var hd = g.hunt
	var sw: Hunter = null
	for h in hunters:
		if (h as Hunter).role == "espadachim" and not (h as Hunter).squad:
			sw = h
			break
	player.rune_on = true
	# um lugar a 3 m dele com linha de visão (o espadachim pode estar encostado numa parede)
	for k in 8:
		var off := Vector3(3.0, 0.1, 0).rotated(Vector3.UP, k * PI / 4.0)
		player.global_position = sw.global_position + off
		await get_tree().physics_frame
		if sw.has_line_of_sight(player) and _reach(player.global_position, sw.global_position):
			break
	player.velocity = Vector3.ZERO
	var seen := false
	for i in 30:
		var look: Vector3 = player.global_position - sw.global_position
		look.y = 0.0
		sw.facing = look.normalized()   # virado para ela (de costas ele não vê; é o que se testa aqui)
		await _seconds(0.1)
		if hd.alert >= 0.7:
			seen = true
			break
	_check(seen, "um caçador te vê: o alerta sobe (%.1f)" % hd.alert)
	hd.raise(3.0, player.global_position)
	await _frames(2)
	var squad_on := true
	for h in get_tree().get_nodes_in_group("hunter"):
		if (h as Hunter).squad and (h as Hunter).player_memory <= 0.0:
			squad_on = false
	_check(int(GameState.hunt_alert) == 3 and squad_on, "alerta 3: o esquadrão do acampamento sai atrás de você")
	player.rune_on = false
	player.global_position = Galerias.W(Vector3(0, 0.1, 0))
	await _seconds(0.3)
	hd.since_seen = 99.0
	hd.alert = 1.05
	await _seconds(1.5)
	_check(hd.alert < 1.0, "sumida, o alerta cai devagar")
	player.global_position = Galerias.W(Vector3(0, 0.1, 0))
	await _seconds(0.5)

	# batedor segue a seda e queima
	var bat_h: Hunter = null
	for h in get_tree().get_nodes_in_group("hunter"):
		if (h as Hunter).role == "batedor" and not (h as Hunter).squad and (h as Hunter).player_memory <= 0.0:
			bat_h = h
			break
	if bat_h != null:
		bat_h.global_position = Galerias.W(Vector3(44, 0.3, 72))
		for o in WebNetwork.strands.duplicate():
			WebNetwork.remove_strand(o)   # só este fio no mapa: o batedor não sai atrás de outro
		var st: WebStrand = WebNetwork.create_strand(WebNetwork.anchors["G5_a"], WebNetwork.anchors["G5_d"])
		print("    batedor em ", bat_h.global_position, " fio: ", st, " ", bat_h.range_rooms)
		var ref: WeakRef = weakref(st)
		var gone := false
		for i in 300:
			await _seconds(0.1)
			player.global_position = Galerias.W(Vector3(0, 0.1, 0))
			if st == null or ref.get_ref() == null or not WebNetwork.strands.has(st):
				gone = true
				break
		if not gone:
			print("    batedor parou em ", bat_h.global_position, " (fio a %.1f m)" % st.distance_to(bat_h.global_position) if is_instance_valid(st) else "")
		_check(gone, "o batedor segue o rastro de seda e queima o fio")

	# armadilha de fogo
	player.invuln = 0.0
	player.hp = player.max_hp
	player.resist_fire = 0
	var trap: Node3D = g._traps[0]
	player.global_position = trap.global_position + Vector3(0, 0.1, 0)
	await _seconds(0.3)
	_check(player.hp < player.max_hp and not trap.armed, "armadilha de fogo no Jardim estoura")
	player.invuln = 999.0

	# caçador vencido vira comida
	var victim: Hunter = null
	for h in get_tree().get_nodes_in_group("hunter"):
		if (h as Hunter).role == "arqueira" and not (h is Captain):
			victim = h
			break
	hd.alert = 1.0
	var a0: float = hd.alert
	victim.take_damage(9999.0, player)
	await _seconds(0.3)
	var corpse: Corpse = null
	for c in get_tree().get_nodes_in_group("corpse"):
		if (c as Corpse).display_name == "Caçadora arqueira":
			corpse = c
	_check(corpse != null, "caçador vencido vira comida")
	_check(hd.alert > a0, "perder um companheiro sobe o alerta")
	if corpse != null:
		player.satiety = 10.0
		player._eat(corpse)
		await _seconds(3.0)
		_check(player.satiety > 40.0, "dá para comer (saciedade %.0f)" % player.satiety)

	# a Capitã: trompa na metade; vencida, a corda abre
	var cap: Captain = g.captain
	var before := get_tree().get_nodes_in_group("hunter").size()
	cap.take_damage(cap.max_hp * 0.55, player)
	await _frames(3)
	_check(get_tree().get_nodes_in_group("hunter").size() == before + 2, "na metade da vida a Capitã sopra a trompa (+2 espadachins)")
	var rope: Vector3 = g.get_meta("rope")
	player.global_position = rope + Vector3(0, 0.1, 0.6)
	await _seconds(0.4)
	_check(not GameState.flags.has("ato4_fim"), "a corda fica fechada enquanto a Capitã guarda")
	player.global_position = Vector3(60.0, 0.1, 28.0)
	await _seconds(0.3)
	cap.take_damage(99999.0, player)
	await _seconds(0.5)
	_check(GameState.flags.has("g16_capita"), "a Capitã cai")
	player.global_position = rope + Vector3(0, 0.1, 0.6)
	await _seconds(0.6)
	print("    corda: ", g._rope_open, " ", rope, " ", player.global_position)
	_check(GameState.flags.has("ato4_fim") and g.hud.cinematic, "subir a corda: Fim do Ato 4")
	await _seconds(5.5)
	_check(player.global_position.z < Galerias.DEEP - 5.0 and not player.dead, "depois do título ela continua na Subida antiga")
	_end()


func _wait_scene(file: String) -> bool:
	for i in 200:
		await _seconds(0.1)
		var sc = get_tree().current_scene
		if sc != null and String(sc.scene_file_path).ends_with(file):
			return true
	return false


func _reach(from: Vector3, to: Vector3) -> bool:
	var p: PackedVector3Array = World.nav.path(from, to)
	return p.size() > 0 and Fx.flat_dist(p[p.size() - 1], to) < 3.0


func _end() -> void:
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
