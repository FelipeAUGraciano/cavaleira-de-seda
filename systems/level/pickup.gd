class_name Pickup
extends Area3D
## Item coletável único (ex.: cristal de pedra-da-lua). Some para sempre depois de pego (fica salvo).

var kind := "cristal_pv"
var flag_id := ""
var _crystal: MeshInstance3D


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
	_crystal = Fx.box(Vector3(0.35, 0.6, 0.35), Fx.mat(Color(0.7, 0.75, 1.0), 2.0))
	_crystal.position.y = 0.7
	_crystal.rotation = Vector3(0.6, 0.0, 0.6)
	add_child(_crystal)
	var light := OmniLight3D.new()
	light.light_color = Color(0.7, 0.75, 1.0)
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
		p.max_hp += 10.0
		p.hp = minf(p.max_hp, p.hp + 10.0)
		EventBus.message.emit("Cristal de pedra-da-lua! +10 PV máximo.")
	if flag_id != "":
		GameState.flags[flag_id] = true
	queue_free()
