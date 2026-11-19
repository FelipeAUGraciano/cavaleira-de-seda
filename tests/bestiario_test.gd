extends Node
## Bestiário: ver, derrotar e comer anotam; o save guarda; a tela abre, navega e fecha.
## Rodar:  godot --headless --path . res://tests/bestiario_test.tscn

var player: Player
var layer
var failures := 0


func _ready() -> void:
	GameState.permadeath = false
	GameState.delete_save()
	GameState.knowledge = {"maps": {}}
	layer = load("res://world/layers/test_chamber.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	player = GameState.player
	for c in World.creatures.duplicate():
		c.queue_free()
	await _frames(2)
	GameState.knowledge = {"maps": {}}
	await _run()
	print("\n==== %s (%d falha(s)) ====" % ["OK" if failures == 0 else "FALHOU", failures])
	GameState.delete_save()
	get_tree().quit(1 if failures > 0 else 0)


func _run() -> void:
	# toda criatura do jogo tem entrada (o nome que ela usa bate com o bestiário)
	var all := [Sister.new(false), Sister.new(true), Larva.new(), Frog.new(), Bat.new(), Lizard.new(), Ant.new(),
		Snake.new(), Centipede.new(), Beetle.new(), WolfSpider.new(), Mimic.new(), GiantBat.new(), Scorpion.new(),
		AcidSlug.new(), Serpent.new(), EmberBeetle.new(), AshBat.new(), AshSpider.new(), FireSalamander.new(),
		BasaltGolem.new(), MagmaFish.new(), LavaWorm.new(), QueenSalamander.new(), Hunter.new("espadachim"),
		Hunter.new("arqueira"), Hunter.new("batedor"), Captain.new(), Guardian.new()]
	var missing: Array = []
	for c in all:
		if Bestiary.id_for(c.display_name) == "":
			missing.append(c.display_name)
		c.free()
	_check(missing.is_empty(), "toda criatura tem entrada no bestiário %s" % [missing])
	_check(Bestiary.id_for("Irmã caçadora") == "irma_faminta", "a Irmã caçadora é a mesma entrada da faminta")
	var no_art: Array = []
	var ids := {}
	for e in Bestiary.entries():
		ids[e["id"]] = true
		if Bestiary.portrait(e["id"]) == null:
			no_art.append(e["id"])
	_check(ids.size() == Bestiary.entries().size(), "ids sem repetir")
	_check(no_art.is_empty(), "todo bicho tem retrato %s" % [no_art])

	# ver
	var base := player.global_position
	var b := Beetle.new()
	b.position = base + Vector3(2.0, 0.2, 0)
	layer.ecosystem.add_child(b)
	await _frames(3)
	b.speed = 0.0
	b.max_hp = 40.0
	b.hp = 40.0
	_check(Bestiary.tier("besouro") == 0, "antes de ver: desconhecido")
	await _seconds(0.6)
	_check(Bestiary.tier("besouro") == Bestiary.SEEN, "besouro perto: anotado como visto")
	_check(int(Bestiary.info("besouro").get("hp", 0)) == 40, "a ficha copia os números do bicho (PV)")
	var far := Beetle.new()
	far.display_name = "Larva-de-musgo"
	far.position = base + Vector3(40.0, 0.2, 0)
	layer.ecosystem.add_child(far)
	await _seconds(0.6)
	_check(Bestiary.tier("larva") == 0, "bicho longe, no escuro: não conta")
	far.queue_free()
	var m := Mimic.new()
	m.position = base + Vector3(-3.0, 0.0, 0.5)
	layer.ecosystem.add_child(m)
	await _seconds(0.6)
	_check(Bestiary.tier("mimico") == 0, "Mímico fingindo de pilar: não conta como visto")
	m.queue_free()

	# derrotar e comer
	player.hit_creature(b, 999.0)
	await _frames(3)
	_check(Bestiary.tier("besouro") == Bestiary.DEFEATED and int(Bestiary.record("besouro")["kills"]) == 1, "derrotou: golpes anotados (×1)")
	var corpse: Corpse = null
	for c in layer.find_children("*", "Corpse", true, false):
		corpse = c
	_check(corpse != null and corpse.display_name == "Besouro carniceiro", "o corpo leva o nome")
	if corpse != null:
		player._eat(corpse)
	_check(Bestiary.tier("besouro") == Bestiary.EATEN, "comeu: entrada completa")
	_check(Bestiary.count_seen() == 1, "1 anotada")

	# perigos: ver já ensina tudo
	Bestiary.see_id("colosso")
	_check(Bestiary.tier("colosso") == Bestiary.DEFEATED and Bestiary.info("colosso").has("attacks"), "Colosso visto: ficha completa (escrita à mão)")

	# save: grava na hora e sobrevive
	GameState.save_now()
	Bestiary.see_id("mae")
	var saved: Dictionary = GameState.load_game().get("knowledge", {}).get("bestiary", {})
	_check(saved.has("mae") and saved.has("besouro"), "o bestiário vai no save sem esperar o casulo")

	# tela
	var hud = layer.hud
	hud.open_bestiary("jogo", "besouro")
	await _frames(3)
	var v: BestiaryView = hud.bestiary
	_check(v.visible and get_tree().paused, "B abre o bestiário e pausa")
	_check(v.selected == "besouro", "abre no bicho pedido")
	v._move(1)
	_check(v.selected == "aranha_lobo", "↓ vai para o próximo da lista: %s" % v.selected)
	v._jump_area(1)
	_check(v.selected == "besouro_brasa", "→ pula para a próxima área: %s" % v.selected)
	for i in 40:
		v._move(1)
	_check(v.selected == Bestiary.entries()[-1]["id"] and v._scroll_to > 0.0, "a lista rola até o fim")
	await _frames(3)
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(4)
	_check(not v.visible and not get_tree().paused, "Esc fecha e o jogo volta")
	await _seconds(0.3)
	hud.open_pause()
	await _frames(2)
	var labels: Array = hud._pause_box.buttons().map(func(x): return x.text)
	_check(labels.has("Bestiário"), "a pausa tem Bestiário")
	hud.open_bestiary("pausa")
	await _frames(2)
	v.close()
	await _frames(3)
	_check(hud._pause_box.visible and get_tree().paused, "fechar volta para a pausa")
	hud.close_pause()


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
