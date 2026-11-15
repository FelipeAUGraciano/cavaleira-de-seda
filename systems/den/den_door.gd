class_name DenDoor
extends StaticBody3D
## Porta de teia numa entrada da toca. A jogadora atravessa; os bichos não (camada 5).
## Tem vida: bicho com fome que sente a comida guardada rasga a porta para entrar.
## Rasgada, deixa passar até ser tecida de novo (C perto dela).

signal torn(door: DenDoor)
signal hit(door: DenDoor, by: Node3D)

const LAYER := 16
const MAX_HP := 60.0

var hp := MAX_HP
var width := 3.2
var across := Vector3(1, 0, 0)     ## direção da largura (de um lado ao outro da entrada)
var _vis: Node3D
var _mat: StandardMaterial3D
var _cs: CollisionShape3D
var _flash := 0.0
var _blocked: Array = []           ## células da navegação travadas por esta porta


func _ready() -> void:
	add_to_group("den_door")
	collision_layer = LAYER
	collision_mask = 0
	var ax := across.normalized()
	look_at_from_position(global_position, global_position + ax.cross(Vector3.UP), Vector3.UP)
	_cs = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 2.4, 0.5)
	_cs.shape = box
	_cs.position.y = 1.2
	add_child(_cs)
	_vis = Node3D.new()
	add_child(_vis)
	_mat = Fx.mat(Color(0.9, 0.93, 1.0), 0.35, true, 0.55)
	_build_web()
	_set_intact(hp > 0.0)


func _build_web() -> void:
	for c in _vis.get_children():
		c.queue_free()
	var thin := 0.03
	for k in 5:   # fios verticais
		var x := -width * 0.5 + width * (k + 0.5) / 5.0
		var v := Fx.box(Vector3(thin, 2.2, thin), _mat)
		v.position = Vector3(x, 1.1, 0.0)
		_vis.add_child(v)
	for k in 6:   # fios horizontais, meio tortos
		var h := Fx.box(Vector3(width, thin, thin), _mat)
		h.position = Vector3(0.0, 0.25 + k * 0.38, 0.0)
		h.rotation.z = sin(k * 1.7) * 0.06
		_vis.add_child(h)
	for s in [-1.0, 1.0]:   # diagonais
		var d := Fx.box(Vector3(width * 1.15, thin, thin), _mat)
		d.position = Vector3(0.0, 1.1, 0.0)
		d.rotation.z = s * 0.62
		_vis.add_child(d)


func intact() -> bool:
	return hp > 0.0


func take_hit(dmg: float, by: Node3D = null) -> void:
	if hp <= 0.0:
		return
	hp = maxf(0.0, hp - dmg)
	_flash = 0.25
	hit.emit(self, by)
	if hp <= 0.0:
		_set_intact(false)
		torn.emit(self)


func weave() -> void:
	hp = MAX_HP
	_set_intact(true)


func _set_intact(on: bool) -> void:
	_cs.disabled = not on
	_vis.scale = Vector3.ONE if on else Vector3(1.0, 0.25, 1.0)   # rasgada: só os fiapos de baixo
	_mat.albedo_color.a = 0.55 if on else 0.3
	_block_nav(on)


func _block_nav(on: bool) -> void:
	## Porta inteira: a navegação dos bichos não passa por aqui (dão a volta ou param na porta).
	if World.nav == null:
		return
	for c in _blocked:
		for g in World.nav.grids:
			g.set_point_solid(c, false)
	_blocked.clear()
	if not on:
		return
	var ax := across.normalized()
	var fw := ax.cross(Vector3.UP)
	var seen := {}
	for k in 17:
		for f: float in [-0.4, 0.0, 0.4]:
			var p := global_position + ax * lerpf(-width * 0.5 - 0.4, width * 0.5 + 0.4, k / 16.0) + fw * f
			var c := World.nav.cell_of(p)
			if seen.has(c) or not World.nav.has_cell(c):
				continue
			seen[c] = true
			if not World.nav.grids[0].is_point_solid(c):
				_blocked.append(c)
	for c in _blocked:
		for g in World.nav.grids:
			g.set_point_solid(c, true)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		_mat.emission_energy_multiplier = 0.35 + _flash * 6.0
		_vis.position.x = sin(_flash * 80.0) * 0.06
	elif _vis.position.x != 0.0:
		_vis.position.x = 0.0
		_mat.emission_energy_multiplier = 0.35
