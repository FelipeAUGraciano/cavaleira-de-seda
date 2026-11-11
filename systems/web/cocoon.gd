class_name Cocoon
extends StaticBody3D
## Casulo: descanso, save, cura e coração do território.


func _ready() -> void:
	add_to_group("cocoon")
	collision_layer = 1
	collision_mask = 0
	var shell := Fx.sphere(0.7, Fx.mat(Color(0.88, 0.9, 0.96), 0.25))
	shell.scale = Vector3(1.0, 1.4, 1.0)
	shell.position.y = 0.95
	add_child(shell)
	var band := Fx.cylinder(0.72, 0.08, Fx.mat(Color(0.5, 0.9, 1.0), 1.5, true))
	band.position.y = 1.0
	add_child(band)
	Models.swap(self, "casulo", 1.8, [shell, band], "height")
	var light := OmniLight3D.new()
	light.light_color = Color(0.75, 0.9, 1.0)
	light.omni_range = 3.5
	light.light_energy = 0.6
	light.position.y = 1.6
	add_child(light)
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	cs.shape = shape
	cs.position.y = 0.8
	add_child(cs)
