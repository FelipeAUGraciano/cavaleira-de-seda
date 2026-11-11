extends Node
## Rede de teias: guarda âncoras, fios, teias de captura e casulos,
## calcula o território e avisa quando algo toca um fio do território.

const COCOON_LINK_RANGE := 8.0   ## âncoras a até 8 m de um casulo entram no território
const TERRITORY_MARGIN := 3.0    ## distância de um fio que ainda conta como território
const TOUCH_DISTANCE := 0.9
const TOUCH_COOLDOWN_MS := 4000

var root: Node3D = null
var anchors: Dictionary = {}           ## nome -> WebAnchor
var strands: Array[WebStrand] = []
var traps: Array[CaptureWeb] = []
var cocoons: Array[Cocoon] = []

var _territory_strands: Array[WebStrand] = []
var _territory_anchors: Dictionary = {}
var _touch_timer := 0.0
var _touch_cooldown: Dictionary = {}


func setup(container: Node3D) -> void:
	root = container
	anchors.clear()
	strands.clear()
	traps.clear()
	cocoons.clear()
	_territory_strands.clear()
	_territory_anchors.clear()
	_touch_cooldown.clear()


func register_anchor(a: WebAnchor) -> void:
	anchors[String(a.name)] = a


# ---------------------------------------------------------------- criação

func create_strand(a: Node3D, b: Node3D) -> WebStrand:
	var s := WebStrand.new()
	s.setup(a, b)
	root.add_child(s)
	strands.append(s)
	recompute()
	return s


func create_trap(pos: Vector3) -> CaptureWeb:
	var t := CaptureWeb.new()
	t.position = pos
	root.add_child(t)
	traps.append(t)
	return t


func create_cocoon(pos: Vector3) -> Cocoon:
	var c := Cocoon.new()
	c.position = pos
	root.add_child(c)
	cocoons.append(c)
	recompute()
	return c


func remove_trap(t: CaptureWeb) -> void:
	traps.erase(t)


func has_strand(a_name: String, b_name: String) -> bool:
	for s in strands:
		if is_instance_valid(s) and s.connects(a_name, b_name):
			return true
	return false


# ---------------------------------------------------------------- consultas

func strand_near(pos: Vector3, radius: float) -> WebStrand:
	if absf(pos.y) > 1.2:
		return null
	for s in strands:
		if is_instance_valid(s) and s.distance_to(pos) <= radius:
			return s
	return null


func is_in_territory(pos: Vector3) -> bool:
	for c in cocoons:
		if is_instance_valid(c) and Fx.flat_dist(pos, c.global_position) <= COCOON_LINK_RANGE:
			return true
	for s in _territory_strands:
		if is_instance_valid(s) and s.distance_to(pos) <= TERRITORY_MARGIN:
			return true
	return false


func territory_anchor_count() -> int:
	return _territory_anchors.size()


func recompute() -> void:
	## Território = casulos + âncoras perto deles + tudo ligado a essas âncoras por fios.
	_territory_anchors.clear()
	_territory_strands.clear()
	var frontier: Array[String] = []
	for c in cocoons:
		if not is_instance_valid(c):
			continue
		for n in anchors:
			var a: WebAnchor = anchors[n]
			if not _territory_anchors.has(n) and Fx.flat_dist(a.global_position, c.global_position) <= COCOON_LINK_RANGE:
				_territory_anchors[n] = true
				frontier.append(n)
	while not frontier.is_empty():
		var cur: String = frontier.pop_back()
		for s in strands:
			if not is_instance_valid(s):
				continue
			var other := ""
			if s.anchor_a == cur:
				other = s.anchor_b
			elif s.anchor_b == cur:
				other = s.anchor_a
			else:
				continue
			if not _territory_strands.has(s):
				_territory_strands.append(s)
			if not _territory_anchors.has(other):
				_territory_anchors[other] = true
				frontier.append(other)
	for s in strands:
		if is_instance_valid(s):
			s.set_in_territory(_territory_strands.has(s))
	EventBus.territory_changed.emit()


# ---------------------------------------------------------------- vibração

func _physics_process(delta: float) -> void:
	_touch_timer -= delta
	if _touch_timer > 0.0 or _territory_strands.is_empty():
		return
	_touch_timer = 0.25
	var now := Time.get_ticks_msec()
	for n in get_tree().get_nodes_in_group("creature"):
		var c := n as Creature
		if c == null or c.dead:
			continue
		var id := c.get_instance_id()
		if _touch_cooldown.has(id) and now - int(_touch_cooldown[id]) < TOUCH_COOLDOWN_MS:
			continue
		for s in _territory_strands:
			if is_instance_valid(s) and s.distance_to(c.global_position) < TOUCH_DISTANCE:
				_touch_cooldown[id] = now
				EventBus.web_touched.emit(c.global_position, c)
				break


# ---------------------------------------------------------------- save

func to_dict() -> Dictionary:
	var s := []
	for st in strands:
		if is_instance_valid(st):
			s.append([st.anchor_a, st.anchor_b])
	var t := []
	for tr in traps:
		if is_instance_valid(tr) and tr.charges > 0:
			t.append([tr.position.x, tr.position.z, tr.charges])
	var c := []
	for co in cocoons:
		if is_instance_valid(co):
			c.append([co.position.x, co.position.z])
	return {"strands": s, "traps": t, "cocoons": c}


func load_from(d: Dictionary) -> void:
	for c in d.get("cocoons", []):
		create_cocoon(Vector3(float(c[0]), 0.0, float(c[1])))
	for s in d.get("strands", []):
		var a_name := String(s[0])
		var b_name := String(s[1])
		if anchors.has(a_name) and anchors.has(b_name) and not has_strand(a_name, b_name):
			create_strand(anchors[a_name], anchors[b_name])
	for t in d.get("traps", []):
		var trap := create_trap(Vector3(float(t[0]), 0.0, float(t[1])))
		trap.charges = int(t[2])
