extends LayerBase
## A — Abismo (Ato 2), primeiro trecho: A1 a A4.
##   A1 Fundo da queda      onde ela cai da Fenda, ferida e sem seda
##   A2 Ossário             ossos velhos e carcaças; besouros carniceiros (a primeira comida)
##   A3 Trilha do Colosso   corredor largo e comprido; um dragão da terra faz a ronda.
##                          Rachaduras nas paredes servem de esconderijo
##   A4 Fenda do refúgio    rachadura estreita que dá numa câmara pequena: a toca do Abismo
## O resto do Abismo (Lago negro, Cortina viva, Serpente-cega...) está atrás de desabamentos.
## Quase breu: só a runa, poucos fungos e cristais. Coordenadas: x leste, z sul (metros).

var cave: CaveBuilder
var colossus: Colossus
const STONE := Color(0.18, 0.18, 0.24)
const ROUTE := [Vector2(46, 13), Vector2(62, 8), Vector2(80, 14), Vector2(98, 8), Vector2(116, 12), Vector2(124, 12)]
const TRAIL_W := 11.0
## Rachaduras da Trilha: (metros ao longo da rota, lado: -1 norte / +1 sul)
const NICHES := [[11.0, -1.0], [27.0, 1.0], [47.0, 1.0], [62.0, -1.0], [74.0, 1.0]]
const DEN_C := Vector2(84, -6)
const DEN_R := 4.3
const CARCASSES := [Vector2(27, 5), Vector2(34, 11), Vector2(29, 13), Vector2(36, 4)]
const SEAL_EAST := Vector2(125.5, 12)    ## → A8 Cortina viva (próxima parte)
const SEAL_SOUTH := Vector2(31, 21.5)    ## → A5 Lago negro (próxima parte)
var niche_spots: Array = []              ## centro de cada rachadura (Vector3)


func _configure() -> void:
	layer_id = "A"
	layer_name = "Abismo"
	layer_subtitle = "Ato 2 · O fundo da Fenda"
	spawn_point = Vector3(0.0, 0.1, 0.0)
	ambient_color = Color(0.16, 0.18, 0.3)
	ambient_energy = 0.08
	fog_color = Color(0.0, 0.0, 0.015)
	var trail_shapes := [CaveBuilder.path(ROUTE, TRAIL_W, 0.8)]
	niche_spots.clear()
	for n in NICHES:
		var c := _niche_center(float(n[0]), float(n[1]))
		niche_spots.append(Vector3(c.x, 0.0, c.y))
	rooms = [
		{"id": "A1", "name": "Fundo da queda", "checkpoint": true,
			"shapes": [CaveBuilder.blob(Vector2(0, 0), 8.5, 1.4)],
			"line_id": "a1_fundo", "line": "...Tô viva. Acho. Tá TUDO escuro aqui embaixo."},
		{"id": "A2", "name": "Ossário", "checkpoint": true,
			"shapes": [CaveBuilder.blob(Vector2(31, 8), 9.0, 1.6)],
			"line_id": "a2_ossos", "line": "Ossos. Muitos ossos. E... alguma coisa roendo eles."},
		{"id": "A3", "name": "Trilha do Colosso", "shapes": trail_shapes,
			"line_id": "a3_trilha", "line": "Esse corredor é largo demais. Quem precisa de um corredor desse tamanho?"},
		{"id": "A4", "name": "Fenda do refúgio",
			"shapes": [CaveBuilder.blob(DEN_C, DEN_R, 0.5)],
			"line_id": "a4_refugio", "line": "Uma frestinha onde nada grande cabe. Isso. ISSO. Aqui é meu."},
	]


func _niche_center(at: float, side: float) -> Vector2:
	var p := _route_point(at)
	var n := _route_normal(at)
	return p + n * side * (TRAIL_W * 0.5 + 2.6)


func _route_point(d: float) -> Vector2:
	for i in range(1, ROUTE.size()):
		var a: Vector2 = ROUTE[i - 1]
		var b: Vector2 = ROUTE[i]
		var l := a.distance_to(b)
		if d <= l:
			return a.lerp(b, d / l)
		d -= l
	return ROUTE[ROUTE.size() - 1]


func _route_normal(d: float) -> Vector2:
	## Normal "para o sul" (z+) do trecho da rota em d.
	var a := _route_point(maxf(0.0, d - 0.5))
	var b := _route_point(d + 0.5)
	var t := (b - a).normalized()
	var n := Vector2(-t.y, t.x)
	return n if n.y >= 0.0 else -n


func _build_level() -> void:
	cave = CaveBuilder.new()
	cave.floor_color = Color(0.14, 0.14, 0.19)
	cave.rock_color = Color(0.07, 0.07, 0.1)
	cave.noise.seed = 47
	cave.rooms = rooms
	cave.tunnels = [
		CaveBuilder.path([Vector2(6, 3), Vector2(15, 6), Vector2(23, 7)], 3.0, 0.4),       # A1 → A2
		CaveBuilder.path([Vector2(39, 10), Vector2(44, 12), Vector2(49, 13)], 3.2, 0.4),   # A2 → A3
		CaveBuilder.path([Vector2(84, 8.5), Vector2(83.4, 3.5), Vector2(84, -3.0)], 1.8, 0.15),  # rachadura → A4
		CaveBuilder.path([Vector2(31, 16), Vector2(31, 22)], 2.6, 0.3),                   # A2 → (Lago negro) desabado
	]
	for n in NICHES:   # rachaduras: gargalo estreito e um buraquinho no fim
		var at := float(n[0])
		var side := float(n[1])
		var p := _route_point(at)
		var nn := _route_normal(at) * side
		cave.tunnels.append(CaveBuilder.path([p + nn * (TRAIL_W * 0.5 - 1.0), p + nn * (TRAIL_W * 0.5 + 2.0)], 1.5, 0.1))
		cave.tunnels.append(CaveBuilder.blob(p + nn * (TRAIL_W * 0.5 + 2.6), 1.6, 0.25))
	map_grid = cave.build(self)
	cave.scatter_decor(self, 9)
	# A1: pilares para os primeiros fios
	for i in 4:
		var ang := i * TAU / 4.0 + 0.4
		add_anchor("A1_%d" % i, Vector3(cos(ang) * 5.0, 0, sin(ang) * 5.0), 3.0, 0.45, STONE)
	# A2: colunas de osso também seguram fio
	for q: Vector2 in [Vector2(25, 9), Vector2(33, 2.5), Vector2(37, 12), Vector2(28, 15)]:
		add_anchor("A2_%d_%d" % [int(q.x), int(q.y)], Vector3(q.x, 0, q.y), 3.2, 0.4, Color(0.62, 0.6, 0.55))
	# A4: quatro pilares na toca
	for i in 4:
		var ang := i * TAU / 4.0 + PI * 0.25
		add_anchor("Toca_%d" % i, Vector3(DEN_C.x + cos(ang) * (DEN_R - 1.3), 0, DEN_C.y + sin(ang) * (DEN_R - 1.3)), 3.0, 0.4, STONE)
	# A3: nenhuma âncora no meio da trilha (fio ali é sentido e pisado)
	_build_bones()
	_build_seal(SEAL_EAST, 0.0, "Cortina viva")
	_build_seal(SEAL_SOUTH, PI * 0.5, "Lago negro")
	var far := OmniLight3D.new()   # lá em cima, muito longe: o buraco por onde ela caiu
	far.light_color = Color(0.45, 0.55, 1.0)
	far.omni_range = 10.0
	far.light_energy = 0.35
	far.position = Vector3(0, 14, -2)
	add_child(far)


func _build_bones() -> void:
	## Ossário: carcaças velhas (os besouros roem) e uma costela gigante de algo do tamanho do Colosso.
	var bone := Fx.mat(Color(0.7, 0.67, 0.6), 0.05)
	var old := Fx.mat(Color(0.32, 0.3, 0.24))
	for c: Vector2 in CARCASSES:
		var m := Node3D.new()
		m.position = Vector3(c.x, 0, c.y)
		m.add_to_group("carcass")
		add_child(m)
		var hide_ := Fx.sphere(0.9, old)
		hide_.scale = Vector3(1.4, 0.4, 1.0)
		hide_.position.y = 0.2
		m.add_child(hide_)
		for k in 4:
			var rib := Fx.cylinder(0.06, 1.3, bone)
			rib.position = Vector3(-0.6 + k * 0.4, 0.45, 0.0)
			rib.rotation = Vector3(0.0, 0.0, 0.9 if k % 2 == 0 else -0.9)
			m.add_child(rib)
	# a costela gigante: arcos de osso saindo do chão e se juntando na espinha, no meio do Ossário
	var spine_y := 3.3
	for k in 6:
		var x := 29.5 + k * 1.5
		for sd: float in [-1.0, 1.0]:
			var prev := Vector3(x, 0.0, 8.0 + sd * 3.1)
			for j in range(1, 7):
				var th := j * PI * 0.5 / 6.0
				var pt := Vector3(x + sin(th) * 0.3, spine_y * sin(th), 8.0 + sd * 3.1 * cos(th))
				var w := 0.26 - j * 0.02
				var seg := Fx.box(Vector3(w, w, prev.distance_to(pt) + 0.08), bone)
				add_child(seg)
				Fx.orient_between(seg, prev, pt)
				prev = pt
	var sp0 := Vector3(28.5, spine_y, 8.0)
	for k in 7:
		var sp1 := Vector3(29.5 + k * 1.5, spine_y + 0.05 * sin(k * 1.3), 8.0)
		var vert := Fx.box(Vector3(0.34, 0.34, sp0.distance_to(sp1) + 0.1), bone)
		add_child(vert)
		Fx.orient_between(vert, sp0, sp1)
		sp0 = sp1
	var skull := Fx.sphere(1.2, bone)
	skull.scale = Vector3(1.0, 0.7, 1.6)
	skull.position = Vector3(26.5, 0.6, 8.2)
	add_child(skull)
	for sd: float in [-1.0, 1.0]:
		var socket := Fx.sphere(0.32, Fx.mat(Color(0.02, 0.02, 0.03)))
		socket.position = skull.position + Vector3(sd * 0.55, 0.35, -1.2)
		add_child(socket)
		var hn := Fx.cylinder(0.18, 1.6, bone)
		(hn.mesh as CylinderMesh).top_radius = 0.02
		hn.position = skull.position + Vector3(sd * 0.6, 0.9, 0.6)
		hn.rotation = Vector3(1.0, 0.0, sd * 0.4)
		add_child(hn)


func _build_seal(at: Vector2, rot: float, beyond: String) -> void:
	## Desabamento: pedra solta tapando a passagem (o Abismo continua na próxima parte).
	var body := add_static_box(Vector3(4.0, 2.6, 1.6), Vector3(at.x, 1.3, at.y), Color(0.1, 0.1, 0.13))
	body.rotation.y = rot
	nav_blockers.append([Vector3(at.x, 0, at.y), Vector3(4.0, 2.6, 4.0)])
	var rock := Fx.mat(Color(0.2, 0.2, 0.25))
	var r := RandomNumberGenerator.new()
	r.seed = int(at.x * 7 + at.y * 13)
	for k in 9:
		var s := Fx.sphere(r.randf_range(0.4, 0.9), rock)
		s.scale = Vector3(1.0, r.randf_range(0.6, 0.9), r.randf_range(0.8, 1.2))
		var off := Vector3(r.randf_range(-1.8, 1.8), r.randf_range(0.2, 2.2), r.randf_range(-0.7, 0.7)).rotated(Vector3.UP, rot)
		s.position = Vector3(at.x, 0, at.y) + off
		add_child(s)
	var probe := Area3D.new()
	probe.collision_layer = 0
	probe.collision_mask = 2
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 3.6
	cs.shape = sh
	probe.add_child(cs)
	probe.position = Vector3(at.x, 0.5, at.y)
	add_child(probe)
	probe.body_entered.connect(func(b: Node3D):
		if b is Player:
			EventBus.hint.emit("Desabamento. Do outro lado: %s (chega na próxima parte do Ato 2)." % beyond))


func _populate() -> void:
	ecosystem.larva_target = 0
	ecosystem.frog_target = 0
	_spawn_beetles()
	EventBus.rested.connect(_on_rested)
	# Trilha do Colosso
	var route := PackedVector2Array()
	for q: Vector2 in ROUTE:
		route.append(q)
	colossus = Colossus.new().setup(route)
	add_child(colossus)
	colossus.alerted.connect(func(): GameState.flags["a3_colosso_visto"] = true)
	# A4: a toca do Abismo
	den = Den.new().setup("A4", Vector3(DEN_C.x, 0.0, DEN_C.y),
		[{"pos": Vector3(84.0, 0.0, -1.4), "out": Vector3(0, 0, 1), "width": 2.2}], "Fenda do refúgio")
	den.inner_r = DEN_R - 0.4
	add_child(den)
	# pouca luz: um fungo aqui e ali, cristais frios na Trilha
	add_fungus(Vector3(-4.5, 0, 3.5), Color(0.45, 1.0, 0.6))
	add_fungus(Vector3(25.0, 0, 3.0), Color(0.75, 0.5, 1.0))
	add_fungus(Vector3(37.0, 0, 13.5), Color(0.45, 1.0, 0.6))
	add_fungus(Vector3(DEN_C.x + 2.0, 0, DEN_C.y - 1.5), Color(0.75, 0.5, 1.0))
	for k in niche_spots.size():   # cada rachadura tem um brilho fraco: dá para achá-las no escuro
		if k % 2 == 0:
			_add_crystal(niche_spots[k])
	_add_crystal(Vector3(70.0, 0, 6.0))
	_add_crystal(Vector3(106.0, 0, 15.0))
	# coletáveis
	for it in [["fragmento", "fragmento_a2", Vector3(37.5, 0, 6.5)], ["fragmento", "fragmento_a3", niche_spots[3]],
			["cristal_seda", "cristal_seda_a3", niche_spots[1]], ["presa", "presa_a1", Vector3(-5.0, 0, -3.0)]]:
		if GameState.flags.has(it[1]):
			continue
		var pk := Pickup.new(it[0], it[1])
		pk.position = it[2]
		add_child(pk)


func _add_crystal(at: Vector3) -> void:
	var m := Fx.mat(Color(0.45, 0.7, 1.0), 2.2)
	for k in 3:
		var c := Fx.cylinder(0.12, 0.6 + k * 0.25, m)
		(c.mesh as CylinderMesh).top_radius = 0.01
		c.position = at + Vector3((k - 1) * 0.22, 0.3 + k * 0.1, 0.0)
		c.rotation.z = (k - 1) * 0.35
		add_child(c)
	var l := OmniLight3D.new()
	l.light_color = Color(0.45, 0.7, 1.0)
	l.omni_range = 4.5
	l.light_energy = 0.7
	l.position = at + Vector3(0, 1.0, 0)
	add_child(l)


func _on_rested(_c: Node) -> void:
	_spawn_beetles()


func _spawn_beetles() -> void:
	## Dois bandos no Ossário (4 e 3). Descansar repõe quem foi comido.
	var alive := 0
	for c in World.creatures:
		if is_instance_valid(c) and c is Beetle and not (c as Beetle).dead:
			alive += 1
	var want := [[CARCASSES[0], 4], [CARCASSES[2], 3]]
	var need := 7 - alive
	for g in want:
		var at: Vector2 = g[0]
		for k in int(g[1]):
			if need <= 0:
				return
			var b := Beetle.new()
			var a := k * TAU / float(g[1])
			b.position = Vector3(at.x + cos(a) * 1.4, 0.3, at.y + sin(a) * 1.4)
			b.range_rooms = ["A2"]
			ecosystem.add_child(b)
			need -= 1


func _start() -> void:
	GameState.flags.erase("ato1_tela")


func _walk_in_scene() -> void:
	## Chegada do Ato 2: ela despenca do alto da Fenda, bate no chão e fica um tempo caída.
	## Primeira vez: chega ferida (30% da vida) e sem nada de seda.
	var land := spawn_point
	player.set_physics_process(false)
	player.global_position = land + Vector3(0.6, 16.0, -0.8)
	player.cam_zoom = 10.0
	player.snap_camera()
	player.invuln = 999.0
	hud.cinematic = true
	hud.fade(0.0, 0.5)
	var tw := create_tween()
	tw.tween_property(player, "global_position", land, 0.95).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	if not is_inside_tree():
		return
	player.shake(2.0)
	_impact_dust(land)
	if not GameState.flags.has("a1_queda"):
		GameState.flags["a1_queda"] = true
		player.hp = maxf(1.0, player.max_hp * 0.3)
		player.silk = 0.0
		EventBus.big_message.emit("Ferida e sem seda")
	player.set_physics_process(true)
	player.autopilot = true
	player.auto_target = land
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	GameState.say_once("a1_acorda", "Ai... ai ai ai. Nada quebrado. Eu acho. A seda acabou toda nos fios.")
	hud.show_area_title(layer_name, layer_subtitle)
	await get_tree().create_timer(2.4).timeout
	if not is_inside_tree():
		return
	player.autopilot = false
	player.cam_zoom = 0.0
	player.invuln = 0.0
	hud.cinematic = false
	EventBus.hint.emit("Sem seda, sem fios. Coma alguma coisa para tecer de novo. E ande devagar: aqui o chão conta onde você está.")


func _impact_dust(at: Vector3) -> void:
	var dust := Fx.mat(Color(0.5, 0.5, 0.58), 0.2, true, 0.45)
	for k in 8:
		var d := Fx.sphere(randf_range(0.35, 0.7), dust)
		var a := k * TAU / 8.0
		d.position = at + Vector3(cos(a) * 0.5, 0.2, sin(a) * 0.5)
		add_child(d)
		var t := d.create_tween()
		t.tween_property(d, "position", d.position + Vector3(cos(a) * 2.2, 0.6, sin(a) * 2.2), 1.1).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(d, "scale", Vector3.ONE * 2.2, 1.1)
		t.tween_callback(d.queue_free)
