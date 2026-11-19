class_name Pickup
extends Area3D
## Item coletável único. Some para sempre depois de pego (fica salvo pelo flag_id).
##   cristal_pv   cristal de pedra-da-lua: +10 PV máximo
##   cristal_en   cristal de energia: +15 Energia máxima
##   cristal_seda cristal de seda: +10 Seda máxima
##   fragmento    fragmento de runa: a cada 4, um ponto de habilidade
##   presa        presa embrulhada antiga: vai para a bolsa (ou é comida na hora)
##   racao        suprimentos roubados dos caçadores (Ato 4): vão para a bolsa como uma presa
##   cristal_fogo Cristais de fogo (R10): Resistência a Fogo +1 e material de evolução rara
##   olho_escuro  pérola do Lago negro: Resistência a Escuridão (+1,5 m de visão no escuro)

var kind := "cristal_pv"
var flag_id := ""
var _crystal: Node3D


func _init(kind_: String = "cristal_pv", flag: String = "") -> void:
	kind = kind_
	flag_id = flag


func _ready() -> void:
	add_to_group("pickup")
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.9
	cs.shape = shape
	cs.position.y = 0.6
	add_child(cs)
	var col := Color(0.7, 0.75, 1.0)
	match kind:
		"cristal_en":
			col = Color(0.4, 1.0, 0.85)
		"cristal_seda":
			col = Color(0.95, 0.95, 1.0)
		"fragmento":
			col = Color(0.75, 0.45, 1.0)
		"presa":
			col = Color(0.85, 0.82, 0.7)
		"olho_escuro":
			col = Color(0.55, 0.45, 1.0)
		"cristal_fogo":
			col = Color(1.0, 0.45, 0.15)
		"racao":
			col = Color(0.75, 0.6, 0.4)
	if kind == "racao":
		_crystal = Fx.box(Vector3(0.5, 0.3, 0.35), Fx.mat(Color(0.5, 0.38, 0.24)))
		_crystal.position.y = 0.15
		add_child(_crystal)
		var strap := Fx.box(Vector3(0.52, 0.04, 0.08), Fx.mat(Color(0.25, 0.18, 0.1)))
		strap.position.y = 0.31
		add_child(strap)
	elif kind == "presa":
		_crystal = Fx.sphere(0.35, Fx.mat(col, 0.15))
		_crystal.scale = Vector3(0.8, 0.7, 1.3)
		_crystal.position.y = 0.3
		add_child(_crystal)
		var pm := Models.swap(self, "presa", 0.8, [_crystal], "max")
		if pm != null:
			_crystal = pm
	elif kind == "fragmento":
		_crystal = Fx.box(Vector3(0.14, 0.32, 0.08), Fx.mat(col, 2.5))
		_crystal.position.y = 0.45
		_crystal.rotation = Vector3(0.3, 0.0, 0.4)
		add_child(_crystal)
	else:
		_crystal = Fx.box(Vector3(0.35, 0.6, 0.35), Fx.mat(col, 2.0))
		_crystal.position.y = 0.7
		_crystal.rotation = Vector3(0.6, 0.0, 0.6)
		add_child(_crystal)
		var m := Models.swap(self, "cristal", 0.8, [_crystal], "height")
		if m != null:
			m.position.y = 0.3
			_crystal = m
			if kind != "cristal_pv":
				Models.tint(m, col)
	var light := OmniLight3D.new()
	light.light_color = col
	light.omni_range = 3.0 if kind != "presa" and kind != "racao" else 1.5
	light.light_energy = 1.0 if kind != "presa" and kind != "racao" else 0.3
	light.position.y = 1.0
	add_child(light)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if kind != "presa" and kind != "racao":
		_crystal.rotate_y(delta * 1.5)


func _on_body_entered(body: Node3D) -> void:
	var p := body as Player
	if p == null:
		return
	Sfx.play("ui_item", global_position)
	if kind in ["cristal_pv", "cristal_en", "cristal_seda", "cristal_fogo", "olho_escuro"]:
		Music.stinger("segredo")
	if kind == "cristal_pv":
		p.add_bonus(10.0, 0.0)
		p.moonstones += 1
		EventBus.message.emit("Cristal de pedra-da-lua! +10 PV máximo (%d achados)." % p.moonstones)
	elif kind == "cristal_en":
		p.add_bonus(0.0, 15.0)
		EventBus.message.emit("Cristal de energia! +15 Energia máxima.")
		GameState.say_once("cristal_lago", "Valeu cada fio. E eu nem molhei as patas.")
	elif kind == "cristal_seda":
		p.add_bonus(0.0, 0.0, 10.0)
		EventBus.message.emit("Cristal de seda! +10 Seda máxima.")
	elif kind == "fragmento":
		p.add_rune_shard()
	elif kind == "cristal_fogo":
		p.resist_fire += 1
		GameState.flags["material_cristal_fogo"] = true
		EventBus.big_message.emit("Cristal de fogo")
		EventBus.message.emit("Um cristal que queima por dentro: Resistência a Fogo +1. Material da forma rara Seda Ardente.")
		GameState.say_once("cristal_fogo", "Ele pulsa igual à runa... só que em vermelho. Guarda isso. GUARDA ISSO.")
	elif kind == "olho_escuro":
		p.dark_sight += 1.5
		p.refresh_sight()
		EventBus.big_message.emit("Resistência a Escuridão")
		EventBus.message.emit("Pérola negra do lago: +1,5 m de visão no escuro.")
		GameState.say_once("perola_negra", "O escuro ficou... menos escuro. Ou eu fiquei mais escura.")
	elif kind == "presa" or kind == "racao":
		var item := {"name": "Presa antiga", "sat": 30.0, "silk": 15.0} if kind == "presa" else {"name": "Ração dos caçadores", "sat": 35.0, "silk": 8.0}
		var den := p.current_den()
		if p.bag.size() < Player.BAG_MAX:
			p.bag.append(item)
			EventBus.message.emit("Uma presa embrulhada esquecida! Foi para a bolsa (%d/%d)." % [p.bag.size(), Player.BAG_MAX])
		elif den != null and p.in_den() and den.store(item):
			EventBus.message.emit("Uma presa embrulhada esquecida! Foi para a despensa da toca.")
		else:
			p.satiety = minf(p.max_satiety, p.satiety + 30.0)
			p.silk = minf(p.max_silk, p.silk + 15.0)
			EventBus.message.emit("Despensa cheia: você comeu a presa antiga na hora.")
	if flag_id != "":
		GameState.flags[flag_id] = true
	queue_free()
