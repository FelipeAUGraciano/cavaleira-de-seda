class_name CaptureWeb
extends Area3D
## Teia de captura: área de ~3x3 m que enreda criaturas P e M (e só desacelera as G).

const RADIUS := 1.6
const ENTANGLE_TIME := 4.0

var charges := 2
var _disc_mat: StandardMaterial3D


func _ready() -> void:
	add_to_group("trap")
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = 1.2
	cs.shape = shape
	cs.position.y = 0.6
	add_child(cs)
	_disc_mat = Fx.mat(Color(0.85, 0.9, 1.0), 0.4, true, 0.3)
	var disc := Fx.cylinder(RADIUS, 0.02, _disc_mat)
	disc.position.y = 0.03
	add_child(disc)
	var spoke_mat := Fx.mat(Color(0.9, 0.95, 1.0), 0.8, true)
	for i in range(4):
		var spoke := Fx.box(Vector3(RADIUS * 2.0, 0.02, 0.03), spoke_mat)
		spoke.position.y = 0.05
		spoke.rotation.y = i * PI / 4.0
		add_child(spoke)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if charges <= 0:
		return
	var c := body as Creature
	if c == null or c.dead:
		return
	if c.size <= Creature.Size.M:
		c.entangle(ENTANGLE_TIME)
	else:
		c.slow(0.5, ENTANGLE_TIME)
	charges -= 1
	_disc_mat.albedo_color.a = 0.12 if charges <= 0 else 0.22
	EventBus.web_touched.emit(global_position, c)
	if charges <= 0:
		await get_tree().create_timer(ENTANGLE_TIME).timeout
		WebNetwork.remove_trap(self)
		queue_free()
