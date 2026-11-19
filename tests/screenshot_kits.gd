extends Node
## Ataques das formas: o casulo com os estilos A/B e algumas áreas de ataque no chão.
## Uso: godot --path . res://tests/screenshot_kits.tscn -- <pasta>

var out := "user://shots"
var layer
var p: Player


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	GameState.permadeath = false
	GameState.delete_save()
	layer = load("res://world/layers/test_chamber.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	for c in World.creatures.duplicate():
		c.queue_free()
	p = GameState.player
	# casulo: forma final com os dois estilos
	await _form(Player.Form.EXECUTORA, 0)
	var cocoon := WebNetwork.create_cocoon(p.global_position + Vector3(0, 0, -1.6))
	await _frames(5)
	layer.hud.open_cocoon(cocoon)
	var m: CocoonMenu = layer.hud.cocoon_menu
	m._show_tab("evo")
	await _frames(10)
	for b in m._page_btns:
		if int(b.get_meta("style", -1)) == 1:
			b.grab_focus()
	await _frames(5)
	await _shot("casulo_estilos")
	m.close()
	cocoon.queue_free()
	await _frames(5)
	# áreas de ataque (fotos no meio do movimento)
	var base := p.global_position
	var shots := [
		[Player.Form.EXECUTORA, 1, 0, 0.9, "foices_carregando"],
		[Player.Form.BASTIA, 0, 0, 0.35, "martelo"],
		[Player.Form.BASTIA, 1, 1, 0.25, "pisao"],
		[Player.Form.SALTADORA, 0, 0, 0.2, "pendulo"],
		[Player.Form.ARDENTE, 0, 0, 0.6, "lanca_chamas"],
		[Player.Form.VIDENTE, 0, 0, 0.25, "ponto_fraco"],
		[Player.Form.TEMPESTADE, 1, 0, 1.0, "campo_eletrico"],
		[Player.Form.LUA, 0, 0, 0.12, "lanca_de_luar"],
	]
	for s in shots:
		await _form(s[0], s[1])
		p.global_position = base
		p.aim_dir = Vector3(1, 0, 0).rotated(Vector3.UP, -0.4)
		p.using_stick_aim = true
		p.cam_zoom = 9.0
		for k in 3:
			var c := Beetle.new()
			c.position = base + Vector3(2.0 + k * 1.2, 0.2, -1.0 + k * 0.9)
			layer.ecosystem.add_child(c)
		await _frames(30)
		for c in World.creatures:
			c.speed = 0.0
			c.max_hp = 999.0
			c.hp = 999.0
		var act := "attack" if s[2] == 0 else "bite"
		Input.action_press(act)
		p.kit.press(s[2])
		await _seconds(s[3])
		await _shot("kit_" + s[4])
		Input.action_release(act)
		await _seconds(0.8)
		if p.kit is AttackKit and p.kit.has_method("status_text") and s[4] == "campo_eletrico":
			p.kit.press(0)
		for c in World.creatures.duplicate():
			c.queue_free()
		await _frames(3)
	print("captura: kits")
	get_tree().quit()


func _form(f: int, style: int) -> void:
	p.attack_style = style
	p.form = f as Player.Form
	p.recompute_stats(true)
	p._apply_form_visual()
	p.shield = float(p.fd("shield", 0.0))
	p.rune_on = true
	await _frames(10)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
