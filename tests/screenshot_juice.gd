extends Node
## Sensação dos golpes: faíscas, número de dano, recuo e a morte tombando.
## Uso: godot --path . res://tests/screenshot_juice.tscn -- <pasta>

var out := "user://shots"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	GameState.permadeath = false
	GameState.delete_save()
	var layer = load("res://world/layers/test_chamber.tscn").instantiate()
	add_child(layer)
	await _frames(20)
	for c in World.creatures.duplicate():
		c.queue_free()
	var p: Player = GameState.player
	p.form = Player.Form.EXECUTORA
	p.recompute_stats(true)
	p._apply_form_visual()
	p.aim_dir = Vector3(1, 0, 0)
	p.using_stick_aim = true
	var base := p.global_position
	var bugs: Array = []
	for k in 3:
		var b := Beetle.new()
		b.position = base + Vector3(1.6, 0.2, -1.0 + k)
		layer.ecosystem.add_child(b)
		bugs.append(b)
	await _frames(30)
	base = p.global_position
	for k in bugs.size():
		var b: Creature = bugs[k]
		b.speed = 0.0
		b.asleep = true
		b.max_hp = 80.0
		b.hp = 80.0
		b.global_position = base + Vector3(1.7, 0.1, -1.1 + k * 1.1)
	await _frames(5)
	p.hit_creature(bugs[0], 14.0)
	p.hit_creature(bugs[1], 42.0)
	bugs[2].entangle_raw(2.0)
	p.hit_creature(bugs[2], 20.0)
	await _frames(4)
	await _shot("juice_impacto")
	await _seconds(0.5)
	p.hit_creature(bugs[1], 99.0)
	await _seconds(0.12)
	await _shot("juice_morte")
	await _seconds(0.9)
	await _shot("juice_cadaver")
	print("captura: juice")
	get_tree().quit()


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, n])


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout
