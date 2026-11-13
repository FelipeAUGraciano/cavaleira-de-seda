extends Node
## Golpes e fio (Q) da jogadora: marca no chão, bote da mordida, puxão e voo até a parede.
## Rodar:  godot --headless --path . res://tests/golpes_test.tscn

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


func _larva(at: Vector3) -> Creature:
	var l := Larva.new()
	l.position = at
	layer.ecosystem.add_child(l)
	return l


func _run() -> void:
	var base := Vector3(-14, 0.1, 8)
	player.global_position = base
	player.using_stick_aim = true
	player.aim_dir = Vector3(1, 0, 0)
	await _frames(5)

	# combo: marca em cone no chão, some depois do golpe
	player._start_attack(0)
	await _frames(2)
	_check(player._swing_marker != null and player._swing_marker.visible, "golpe mostra o cone no chão")
	await _seconds(0.5)
	_check(not player._swing_marker.visible, "a marca some depois do golpe")
	player._start_state(Player.State.NORMAL)

	# mordida: avança até a larva e crava
	var l := _larva(base + Vector3(2.0, 0.2, 0.3))
	await _frames(5)
	l.asleep = true
	var x0 := player.global_position.x
	var hp0 := l.hp
	player._start_bite()
	await _seconds(0.35)
	_check(player.global_position.x - x0 > 0.7, "mordida dá um bote para a frente (%.2f m)" % (player.global_position.x - x0))
	_check(not is_instance_valid(l) or l.dead or l.hp < hp0, "e acerta a larva que estava fora do alcance parada")
	if is_instance_valid(l) and not l.dead:
		l.queue_free()
	await _seconds(0.4)

	# puxão: o fio voa, a larva vem até a frente e fica tonta
	player.global_position = base
	player.velocity = Vector3.ZERO
	var l2 := _larva(base + Vector3(5.0, 0.2, 0.0))
	await _frames(5)
	player.silk = player.max_silk
	player.aim_dir = Vector3(1, 0, 0)
	player._throw_silk()
	await _frames(2)
	_check(player._silk != null and is_instance_valid(player._silk), "o fio do Q é desenhado (voando)")
	await _seconds(0.6)
	var d := Fx.flat_dist(l2.global_position, player.global_position)
	_check(d < 1.8, "puxão: a larva veio até a frente (%.1f m)" % d)
	_check(l2.is_entangled(), "e ficou tonta")
	l2.queue_free()
	await _seconds(0.5)

	# voo até a parede: acha uma parede a 4-10 m e se puxa até ela
	player.global_position = base
	var dir := Vector3.ZERO
	var wall := Vector3.ZERO
	for k in 16:
		var a := k * TAU / 16.0
		var v := Vector3(cos(a), 0, sin(a))
		var from := base + Vector3.UP * 0.5
		var q := PhysicsRayQueryParameters3D.create(from, from + v * 11.0, 1)
		q.exclude = [player.get_rid()]
		var hit := player.get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and from.distance_to(hit["position"]) > 4.0 and not (hit["collider"] is Creature):
			dir = v
			wall = hit["position"]
			break
	_check(dir != Vector3.ZERO, "achou uma parede para o teste")
	if dir != Vector3.ZERO:
		player.aim_dir = dir
		player._throw_silk()
		await _frames(2)
		_check(player.state == Player.State.ZIP and player._zip_wait, "o fio voa primeiro; ela espera ele prender")
		await _seconds(1.4)
		_check(Fx.flat_dist(player.global_position, wall) < 1.5, "e depois se puxa até a parede (%.1f m)" % Fx.flat_dist(player.global_position, wall))
		_check(player.state != Player.State.ZIP and is_equal_approx(player._visual.position.y, 0.0) or player._visual.position.y < 0.05, "pousa no fim")
		await _seconds(0.5)
		_check(player._silk == null or not is_instance_valid(player._silk), "o fio recolhe e some")

	# inimigos: o aviso é a marca no chão, o corpo não pisca amarelo
	var l3 := _larva(base + Vector3(-3, 0.2, 0))
	await _frames(3)
	l3.telegraph = true
	await _frames(3)
	var oc: Color = l3._overlay.albedo_color if l3._overlay != null else Color(0, 0, 0, 0)
	_check(oc.a < 0.05, "aviso de ataque não pisca o corpo de amarelo")


func _check(ok: bool, label: String) -> void:
	print(("  ok    " if ok else "  FALHA ") + label)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
