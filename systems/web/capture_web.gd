class_name CaptureWeb
extends Area3D
## Teia de captura: área de ~3x3 m. Aguenta 3 de peso no total (3 presas pequenas; M pesa 2):
## quem passar do limite arrebenta a teia e solta quem estava preso. G arrebenta na hora.

const RADIUS := 1.6
const ENTANGLE_TIME := 4.0

const CAPACITY := 3
var capacity := CAPACITY      ## Senhora das Teias: 6
var acid_dps := 0.0           ## Corrosiva: derrete quem fica preso
var used := 0                 ## peso que ela já segurou (gasta: 3 presas pequenas e acabou)
var held: Array = []
var _torn := false
var _disc_mat: StandardMaterial3D


func _ready() -> void:
	add_to_group("trap")
	var pl = GameState.player
	if pl != null and is_instance_valid(pl):
		capacity = int(pl.fd("trap_capacity", CAPACITY))
		acid_dps = float(pl.fd("trap_acid", 0.0))
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
	if _torn:
		return
	var c := body as Creature
	if c == null or c.dead or c._web_immune > 0.0:
		return
	var w := c.web_weight()
	if used + w > capacity:
		_rip(c)
		return
	var t := c.entangle(ENTANGLE_TIME)
	if t <= 0.0:
		return
	var pl = GameState.player
	if pl != null and is_instance_valid(pl):
		var hold := float(pl.fd("trap_hold", 0.0))
		if hold > t and c.size == Creature.Size.M:
			c.entangle_raw(hold)   # Senhora das Teias: seda grossa segura o bicho médio
		if pl.has_skill("teia_veneno") or pl.fd("trap_poison", false):
			c.add_poison()   # Teia Venenosa / Viúva de Seda
			if pl.fd("trap_poison", false):
				c.add_poison()
	used += w
	held.append(c)
	_disc_mat.albedo_color.a = lerpf(0.3, 0.1, float(used) / capacity)
	EventBus.web_touched.emit(global_position, c)
	if used >= capacity:
		EventBus.message.emit("A teia de captura está no limite (%d/%d)." % [used, capacity])
		await get_tree().create_timer(ENTANGLE_TIME).timeout
		if is_instance_valid(self) and not _torn:
			_remove()


func _rip(by: Creature) -> void:
	## Peso demais (ou bicho grande): a teia arrebenta e solta todo mundo.
	_torn = true
	for h in held:
		if is_instance_valid(h):
			(h as Creature).release_web()
	held.clear()
	var pl = GameState.player
	var big := 1.0
	if pl != null and is_instance_valid(pl):
		big = float(pl.fd("trap_slow_big", 1.0))
	by.slow(0.55 if big <= 1.0 else 0.35, big)
	EventBus.web_touched.emit(global_position, by)
	EventBus.message.emit("O %s arrebentou a teia de captura! (aguenta %d presas pequenas)" % [by.display_name, capacity])
	_remove()


func _remove() -> void:
	WebNetwork.remove_trap(self)
	queue_free()


func _physics_process(delta: float) -> void:
	if acid_dps <= 0.0 or held.is_empty():
		return
	for h in held:
		if is_instance_valid(h) and not (h as Creature).dead and (h as Creature).is_entangled():
			(h as Creature).take_damage(acid_dps * delta, null)
