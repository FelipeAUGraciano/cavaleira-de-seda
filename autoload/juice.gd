extends Node
## Sensação dos golpes: pausa curtinha no impacto, faíscas, poeira e números de dano.
## Tudo passa por aqui para respeitar as Opções (Settings.hit_stop, damage_numbers).

const STOP_SCALE := 0.06        ## velocidade do jogo durante a pausa no impacto

var _stop_until := 0
var _stopped := false
var _last_stop_frame := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if _stopped and Time.get_ticks_msec() >= _stop_until:
		_stopped = false
		Engine.time_scale = 1.0


func hitstop(sec: float) -> void:
	## Congela o jogo por uns centésimos (tempo real). Vários acertos no mesmo quadro contam uma vez.
	if not Settings.hit_stop or DisplayServer.get_name() == "headless" or get_tree().paused:
		return
	if Engine.get_process_frames() == _last_stop_frame or Time.get_ticks_msec() < _stop_until + 90:
		return   # um por quadro, e não emenda uma pausa na outra (golpes em área, fogo contínuo)
	_last_stop_frame = Engine.get_process_frames()
	_stop_until = maxi(_stop_until, Time.get_ticks_msec() + int(sec * 1000.0))
	_stopped = true
	Engine.time_scale = STOP_SCALE


func impact(at: Vector3, col: Color, strength := 1.0) -> void:
	## Faíscas no ponto do golpe; strength 1 = golpe comum, 2 = crítico ou pesado.
	var root := _root()
	if root == null:
		return
	sparks(root, at, col, int(6 + 6 * strength), 3.5 + 2.0 * strength)
	if strength >= 1.6:
		dust(root, at, 0.5 + 0.3 * strength)


func sparks(root: Node, at: Vector3, col: Color, n: int, speed: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = maxi(1, n)
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -12, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var m := BoxMesh.new()
	m.size = Vector3(0.05, 0.05, 0.16)
	m.material = Fx.mat(col, 4.0, true)
	p.mesh = m
	p.local_coords = false
	root.add_child(p)
	p.global_position = at
	p.emitting = true
	p.get_tree().create_timer(0.8, false, false, true).timeout.connect(p.queue_free)


func dust(root: Node, at: Vector3, r: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 10
	p.lifetime = 0.6
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 90.0
	p.flatness = 0.7
	p.initial_velocity_min = 1.0 * r
	p.initial_velocity_max = 2.5 * r
	p.gravity = Vector3(0, -1.0, 0)
	p.damping_min = 2.0
	p.damping_max = 3.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var m := SphereMesh.new()
	m.radius = 0.14 * r
	m.height = 0.2 * r
	m.material = Fx.mat(Color(0.55, 0.52, 0.5), 0.0, true, 0.45)
	p.mesh = m
	p.local_coords = false
	root.add_child(p)
	p.global_position = Vector3(at.x, at.y + 0.1, at.z)
	p.emitting = true
	p.get_tree().create_timer(1.2, false, false, true).timeout.connect(p.queue_free)


func number(at: Vector3, value: float, col: Color, big := false) -> void:
	## Número de dano que sobe e some (Opções → Números de dano).
	if not Settings.damage_numbers or value < 0.5:
		return
	var root := _root()
	if root == null:
		return
	var l := Label3D.new()
	l.text = str(roundi(value))
	l.font_size = 64 if big else 44
	l.outline_size = 12
	l.modulate = col
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 20
	l.pixel_size = 0.006
	root.add_child(l)
	var jitter := Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
	l.global_position = at + Vector3.UP * 1.2 + jitter
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position", l.global_position + Vector3.UP * 1.1, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


func _root() -> Node:
	var p = GameState.player
	if p != null and is_instance_valid(p) and p.get_parent() != null:
		return p.get_parent()
	return get_tree().current_scene
