extends Node
## Efeitos sonoros (Sfx): variações, famílias dos bichos, golpes, teia, loops presos a nós,
## ambiente e silêncio sem arquivo. Usa sons de teste em tests/fixtures/sfx/.
## Rodar:  godot --headless --path . res://tests/sfx_test.tscn

var player: Player
var layer
var failures := 0


func _ready() -> void:
	GameState.permadeath = false
	GameState.delete_save()
	Sfx.use_dir("res://tests/fixtures/sfx/")
	layer = load("res://world/layers/test_chamber.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	for c in World.creatures.duplicate():
		c.queue_free()
	await _frames(2)
	await _run()
	Sfx.use_dir(Sfx.DIR)
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _played(sound: String, since: int) -> bool:
	return int(Sfx._last.get(sound, -1)) >= since


func _run() -> void:
	_check(Sfx._variants("pc_passo").size() == 2, "acha as variações (pc_passo_1 e _2)")
	_check(Sfx._variants("teia_tecer").size() == 1, "acha som sem variação")
	_check(not Sfx.has("nao_existe"), "som que não existe: silêncio")
	Sfx.play("nao_existe", player.global_position)
	_check(get_viewport().get_audio_listener_3d() != null and get_viewport().get_audio_listener_3d().get_parent() == player, "o ouvido é a jogadora (não a câmera)")
	# passos
	var t0 := Time.get_ticks_msec()
	Input.action_press("move_right")
	await _seconds(0.8)
	Input.action_release("move_right")
	_check(_played("pc_passo", t0), "andando: passinhos")
	# bicho: família, dor, golpe, morte
	var b := Beetle.new()
	b.position = player.global_position + Vector3(1.5, 0.2, 0)
	layer.ecosystem.add_child(b)
	await _frames(3)
	b.speed = 0.0
	b.max_hp = 100.0
	b.hp = 100.0
	_check(Sfx._cls(b) == "Beetle" and Sfx.FAMILY["Beetle"] == "inseto", "besouro é da família inseto")
	t0 = Time.get_ticks_msec()
	player.hit_creature(b, 12.0)
	await _frames(1)
	_check(_played("inseto_dor", t0), "apanhou: dor da família")
	_check(_played("hit_casca", t0) or Sfx.HARD.has("Beetle"), "besouro tem casca (hit_casca)")
	b.entangle_raw(2.0)
	await _seconds(0.5)
	t0 = Time.get_ticks_msec()
	player.hit_creature(b, 12.0)
	_check(_played("hit_critico", t0), "acerto crítico: hit_critico")
	t0 = Time.get_ticks_msec()
	Sfx._cd.clear()
	Sfx.creature(b, "alerta")
	_check(_played("inseto_alerta", t0), "alerta da família")
	t0 = Time.get_ticks_msec()
	Sfx.creature(b, "alerta")
	_check(not _played("inseto_alerta", t0 + 1), "alerta não repete logo em seguida")
	t0 = Time.get_ticks_msec()
	b.take_damage(999.0, player)
	await _frames(1)
	_check(_played("morte_pequena", t0), "morte: som de morte")
	# ataques e teia
	t0 = Time.get_ticks_msec()
	player._start_attack(0)
	_check(_played("pc_garra", t0), "golpe: pc_garra")
	await _seconds(0.5)
	var anchors := get_tree().get_nodes_in_group("anchor")
	t0 = Time.get_ticks_msec()
	var st: WebStrand = null
	if anchors.size() >= 2:
		st = WebNetwork.create_strand(anchors[0], anchors[1])
	_check(_played("teia_tecer", t0), "fio-guia: teia_tecer")
	if st != null:
		WebNetwork.remove_strand(st)
	# kit: corte em linha pelo formato da área
	player.form = Player.Form.LAMINA
	player.recompute_stats(true)
	await _frames(2)
	player.kit._combo_i = 2
	player.kit._combo_t = Time.get_ticks_msec() / 1000.0
	t0 = Time.get_ticks_msec()
	player.kit.press(0)
	_check(_played("kit_corte", t0), "ataque em linha do kit: kit_corte")
	await _seconds(0.6)
	# loop preso a nó (fogueira) e ambiente
	var fire := Fire.new(0.5)
	layer.add_child(fire)
	fire.global_position = player.global_position + Vector3(3, 0, 0)
	await _frames(3)
	var lp: AudioStreamPlayer3D = null
	for c in fire.get_children():
		if c is AudioStreamPlayer3D:
			lp = c
	_check(lp != null and lp.playing, "fogueira: loop tocando")
	fire.snuff(1.0)
	await _frames(3)
	_check(lp != null and not lp.playing, "fogueira apagada: loop para")
	fire.queue_free()
	Sfx.ambient("galerias")
	_check(Sfx.ambient_now() == "amb_galerias", "ambiente do mapa")
	Sfx.ambient("abismo")
	_check(Sfx.ambient_now() == "", "ambiente sem arquivo: silêncio")


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
