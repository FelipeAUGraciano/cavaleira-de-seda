class_name Pickup
extends Area3D
## Item coletável único (ex.: cristal de pedra-da-lua). Some para sempre depois de pego (fica salvo).

var kind := "cristal_pv"
var flag_id := ""
var _crystal: Node3D


func _init(kind_: String = "cristal_pv", flag: String = "") -> void:
	kind = kind_
	flag_id = flag


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.9
	cs.shape = shape
	cs.position.y = 0.6
	add_child(cs)
	var col := Color(0.4, 1.0, 0.85) if kind == "cristal_en" else Color(0.7, 0.75, 1.0)
	_crystal = Fx.box(Vector3(0.35, 0.6, 0.35), Fx.mat(col, 2.0))
	_crystal.position.y = 0.7
	_crystal.rotation = Vector3(0.6, 0.0, 0.6)
	add_child(_crystal)
	var m := Models.swap(self, "cristal", 0.8, [_crystal], "height")
	if m != null:
		m.position.y = 0.3
		_crystal = m
	var light := OmniLight3D.new()
	light.light_color = col
	light.omni_range = 3.0
	light.light_energy = 1.0
	light.position.y = 1.0
	add_child(light)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_crystal.rotate_y(delta * 1.5)


func _on_body_entered(body: Node3D) -> void:
	var p := body as Player
	if p == null:
		return
	if kind == "cristal_pv":
		p.add_bonus(10.0, 0.0)
		EventBus.message.emit("Cristal de pedra-da-lua! +10 PV máximo.")
	elif kind == "cristal_en":
		p.add_bonus(0.0, 15.0)
		EventBus.message.emit("Cristal de energia! +15 Energia máxima.")
		GameState.say_once("cristal_lago", "Valeu cada fio. E eu nem molhei as patas.")
	if flag_id != "":
		GameState.flags[flag_id] = true
	queue_free()
