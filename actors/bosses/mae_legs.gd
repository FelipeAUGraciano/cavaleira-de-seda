class_name MaeLegs
extends RefCounted
## As patas da Mãe (assets/models/mae_pata): uma pata reta no eixo X com juntas
## hip → joint_1 → joint_2 → joint_3 → tip, dobradas girando no eixo Z local de cada junta.

const REST := {"hip": 0.85, "j1": -1.85, "j2": -0.35, "j3": -0.15}


static func make(scale: float) -> Dictionary:
	## {root, hip, j1, j2, j3, tip} ou {} sem o modelo. A raiz fica com o quadril na origem.
	var m := Models.raw("mae_pata")
	if m == null:
		return {}
	var d := {"root": m, "hip": m.find_child("hip", true, false), "j1": m.find_child("joint_1", true, false),
		"j2": m.find_child("joint_2", true, false), "j3": m.find_child("joint_3", true, false), "tip": m.find_child("tip", true, false)}
	for k in ["hip", "j1", "j2", "j3", "tip"]:
		if d[k] == null:
			m.free()
			return {}
	m.scale = Vector3.ONE * scale
	var hip_x: float = (d["hip"] as Node3D).position.x
	m.position = Vector3(-hip_x * scale, 0.0, 0.0)
	return d


static func pose(d: Dictionary, hip: float, j1: float, j2: float, j3: float, yaw := 0.0) -> void:
	(d["hip"] as Node3D).rotation = Vector3(0.0, yaw, hip)
	(d["j1"] as Node3D).rotation.z = j1
	(d["j2"] as Node3D).rotation.z = j2
	(d["j3"] as Node3D).rotation.z = j3


static func tip_in(d: Dictionary, space: Node3D) -> Vector3:
	## Ponta da pata no espaço de outro nó (precisa estar na árvore).
	return space.global_transform.affine_inverse() * (d["tip"] as Node3D).global_position
