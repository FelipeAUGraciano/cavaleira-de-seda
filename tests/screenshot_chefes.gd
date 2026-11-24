extends Node
## Capturas dos golpes novos da Centopeia (escavadora) e da Serpente (caçadora do silêncio).
## Uso: godot --path . res://tests/screenshot_chefes.tscn -- <pasta> [serpente]

var out := "user://shots"
var layer
var p: Player


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	GameState.delete_save()
	GameState.said = {}
	if args.size() > 1 and args[1] == "serpente":
		await _serpente()
	else:
		await _centopeia()
	GameState.delete_save()
	get_tree().quit()


func _centopeia() -> void:
	GameState.flags = {}
	layer = load("res://world/layers/galerias.tscn").instantiate()
	add_child(layer)
	await _frames(30)
	_setup()
	World.clock.paused = true
	p.max_hp = 999.0
	var boss: Centipede = layer.centipede
	var c: Vector3 = layer.ARENA
	_go(c + Vector3(-2.0, 0.1, 2.0))
	boss.global_position = c + Vector3(6.0, 0.05, -2.0)
	boss._reset_trail()
	boss.player_memory = 10.0
	boss.last_player_pos = p.global_position
	boss._begin(Centipede.Mode.BURROW)
	boss.brain.decide(boss)
	await _wait_mode(boss, Centipede.Mode.EMERGE, 300)
	await _frames(8)
	await _shot("centopeia_1_erupcao")
	await _wait_mode(boss, Centipede.Mode.RECOVER, 200)
	boss.phase = 2
	boss.global_position = c + Vector3(4.2, 0.05, 0.0)
	boss._reset_trail()
	_go(c)
	boss._start_circle(p.global_position)
	boss.brain.decide(boss)
	await _frames(70)
	_go(c)
	await _shot("centopeia_2_cerco")
	await _wait_mode(boss, Centipede.Mode.SQUEEZE, 200)
	await _frames(6)
	await _shot("centopeia_3_aperto")
	await _wait_mode(boss, Centipede.Mode.RECOVER, 200)
	boss.global_position = c + Vector3(3.0, 0.05, 0.0)
	boss._reset_trail()
	_go(c + Vector3(-3.0, 0.1, 0.0))
	boss._begin(Centipede.Mode.SPIT)
	boss.face_toward(p.global_position)
	boss.brain.decide(boss)
	await _frames(45)
	_go(c + Vector3(-6.0, 0.1, 3.0))
	await _frames(4)
	await _shot("centopeia_4_acido")


func _serpente() -> void:
	GameState.flags = {"g14_centopeia": true, "a1_queda": true}
	layer = load("res://world/layers/abismo.tscn").instantiate()
	add_child(layer)
	await _frames(400)
	_setup()
	p.autopilot = false
	p.invuln = 0.0
	p.max_hp = 999.0
	var sp: Serpent = layer.serpent
	var c := Vector3(layer.ARENA.x, 0.0, layer.ARENA.y)
	sp.wake()
	_go(c + Vector3(-2.5, 0.1, 0.0))
	sp.global_position = c + Vector3(3.0, 0.3, 0.0)
	sp.face_toward(p.global_position)
	sp._begin(Serpent.Mode.WINDUP)
	sp._lunge_len = 7.0
	sp.mode_time = 2.0
	for i in 200:
		await _frames(1)
		if p.held_by == sp:
			break
	await _frames(30)
	await _shot("serpente_1_enrolada")
	p.release_hold(true)
	await _frames(20)
	sp.phase = 2
	_go(c + Vector3(-7.0, 0.1, 1.0))
	sp.global_position = c + Vector3(1.0, 0.3, 0.0)
	sp.mode = Serpent.Mode.RECOVER
	sp.mode_time = -99.0
	sp.hide_marker()
	sp._slam()
	await _frames(4)
	await _shot("serpente_2_onda")
	sp.hp = sp.max_hp * 0.36
	sp.open_time = 1.0
	sp.take_damage(20.0, p)
	sp.mode = Serpent.Mode.RECOVER
	sp.mode_time = -99.0
	sp.hide_marker()
	await _frames(40)
	_go(c + Vector3(-1.0, 0.1, 6.0))
	await _frames(8)
	await _shot("serpente_3_vapor")


func _setup() -> void:
	p = GameState.player
	p.using_stick_aim = true
	p.aim_dir = Vector3(0, 0, -1)
	layer.hud._show_help = false
	layer.hud._area_time = 0.0


func _wait_mode(b, m, n: int) -> void:
	for i in n:
		await _frames(1)
		if b.mode == m:
			return


func _go(pos: Vector3) -> void:
	if p.dead:
		p._respawn()
	p.hp = p.max_hp
	p.global_position = pos
	p.last_safe_pos = pos
	p.velocity = Vector3.ZERO
	p.snap_camera()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("captura: ", name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
