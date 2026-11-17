class_name Den
extends Node3D
## Toca: uma câmara marcada da camada (nas Galerias, a G22 Fosso escuro). Vira sua quando
## você tece o casulo central no lugar marcado. A partir daí ela é o único lugar que salva e
## cura, guarda a despensa (10 embrulhos) e é o coração do território.
## Cada entrada recebe uma porta de teia (C perto dela, 15 de Seda). Bicho com fome sente o
## cheiro da comida guardada, rasga a porta, entra, come um embrulho e vai embora.
## Fios-alarme (melhoria, 30 de Seda) avisam onde você estiver.

signal changed

const PANTRY_MAX := 10
const CLAIM_COST := 30.0
const DOOR_COST := 15.0
const REPAIR_COST := 6.0
const ALARM_COST := 30.0
const SAFE_R := 14.0              ## você por perto: ninguém tenta saquear

var room_id := ""
var title := "Toca"
var center := Vector3.ZERO
var inner_r := 5.5
var slots: Array = []             ## [{pos: Vector3, out: Vector3 (aponta para fora), width}]
var claimed := false
var pantry: Array = []            ## [{name, sat, silk}]
var alarm := false
var log_lines: Array = []         ## últimos acontecimentos (aparecem no menu da toca)
var doors: Array = []             ## DenDoor ou null, um por entrada
var cocoon: Cocoon
var raider: Creature = null
var growth := 0.0                 ## quanto a teia da toca já cresceu (1 a 5); só visual
var decor: DenDecor
var _raid_t := 40.0
var _alarm_t := 0.0
var _marker: Node3D


func setup(room_id_: String, center_: Vector3, slots_: Array, title_: String = "Toca") -> Den:
	room_id = room_id_
	center = center_
	slots = slots_
	title = title_
	return self


func _ready() -> void:
	add_to_group("den")
	global_position = Vector3(center.x, 0.0, center.z)
	doors.resize(slots.size())
	_build_marker()
	decor = DenDecor.new().setup(self)
	add_child(decor)
	changed.connect(func(): decor.refresh_pantry())
	from_dict(GameState.dens.get(_key(), {}))


func _key() -> String:
	var l = GameState.current_layer
	return (l.scene_file_path if l != null else "") + "#" + room_id


# ---------------------------------------------------------------- posse e casulo

func _build_marker() -> void:
	## Lugar marcado: um ninho velho de seda e pedrinhas (some quando você toma a toca).
	_marker = Node3D.new()
	add_child(_marker)
	var silk := Fx.mat(Color(0.8, 0.82, 0.9), 0.2, false, 0.7)
	for k in 9:
		var a := k * TAU / 9.0
		var st := Fx.sphere(0.16, Fx.mat(Color(0.45, 0.43, 0.5)))
		st.position = Vector3(cos(a) * 1.3, 0.08, sin(a) * 1.3)
		_marker.add_child(st)
	var ring := Fx.cylinder(1.2, 0.04, silk)
	ring.position.y = 0.03
	_marker.add_child(ring)
	var light := OmniLight3D.new()
	light.light_color = Color(0.7, 0.85, 1.0)
	light.omni_range = 3.0
	light.light_energy = 0.5
	light.position.y = 1.0
	_marker.add_child(light)


func can_claim(p: Player) -> String:
	## "" = dá para tomar a toca agora; senão o motivo.
	if claimed:
		return "Esta toca já é sua."
	if Fx.flat_dist(p.global_position, center) > 3.0:
		return "Vá até o ninho velho no meio da câmara."
	if p.silk < CLAIM_COST:
		return "Seda insuficiente para o casulo central (precisa de %d)." % int(CLAIM_COST)
	return ""


func claim(p: Player) -> bool:
	var why := can_claim(p)
	if why != "":
		EventBus.message.emit(why)
		return false
	p.silk -= CLAIM_COST
	claimed = true
	growth = 1.0
	_ensure_cocoon()
	p.respawn_pos = center + Vector3(0.0, 0.1, 1.6)
	p.rested_here = true
	_note("Você tomou a câmara como toca.")
	EventBus.big_message.emit("%s: agora é sua toca" % title)
	EventBus.message.emit("Casulo central tecido. Descanse nele (E) para salvar e curar. Feche as %d entradas com portas de teia (C perto de cada uma, %d de Seda)." % [slots.size(), int(DOOR_COST)])
	GameState.say_once("toca_tomada", "Minha toca. Meu cheiro, meus fios, minha comida. Agora é fechar as portas.")
	changed.emit()
	GameState.save_now()
	return true


func grow(amount: float) -> void:
	## A teia da toca cresce (tomar posse, portas, descansos, comida guardada).
	growth = clampf(growth + amount, 1.0, 5.0)
	_refresh_decor()


func _refresh_decor() -> void:
	if decor != null and decor.is_inside_tree():
		decor.set_stage(clampi(int(growth), 1, 5) if claimed else 0)


func _ensure_cocoon() -> void:
	_marker.visible = not claimed
	if not claimed:
		_refresh_decor()
		return
	for c in WebNetwork.cocoons:
		if is_instance_valid(c) and Fx.flat_dist(c.global_position, center) < 2.0:
			cocoon = c
			_refresh_decor()
			return
	cocoon = WebNetwork.create_cocoon(Vector3(center.x, 0.0, center.z))
	_refresh_decor()


func is_inside(pos: Vector3) -> bool:
	if World.nav != null and room_id != "" and World.nav.room_at(pos) == room_id:
		return Fx.flat_dist(pos, center) < inner_r + 3.5
	return Fx.flat_dist(pos, center) < inner_r


# ---------------------------------------------------------------- portas

func slot_near(pos: Vector3, r: float = 2.4) -> int:
	var best := -1
	var best_d := r
	for i in slots.size():
		var d := Fx.flat_dist(pos, slots[i]["pos"])
		if d < best_d:
			best_d = d
			best = i
	return best


func door_state(i: int) -> String:
	var d = doors[i]
	if d == null:
		return "sem porta"
	if not (d as DenDoor).intact():
		return "rasgada"
	if (d as DenDoor).hp < DenDoor.MAX_HP:
		return "danificada"
	return "inteira"


func door_cost(i: int) -> float:
	var st := door_state(i)
	if st == "danificada":
		return REPAIR_COST
	if st == "inteira":
		return 0.0
	return DOOR_COST


func weave_door(i: int, p: Player) -> bool:
	if not claimed:
		EventBus.message.emit("Primeiro tome a câmara: teça o casulo central no ninho velho (C).")
		return false
	var cost := door_cost(i)
	if cost <= 0.0:
		EventBus.message.emit("A porta %s está inteira." % dir_name(i))
		return false
	if p.silk < cost:
		EventBus.message.emit("Seda insuficiente (precisa de %d)." % int(cost))
		return false
	p.silk -= cost
	if cost >= DOOR_COST:
		grow(0.5)
	_make_door(i, DenDoor.MAX_HP)
	EventBus.message.emit("Porta %s tecida. Você passa por ela; os bichos não." % dir_name(i))
	GameState.say_once("primeira_porta", "Fechadinho. Quem quiser entrar vai ter que rasgar. E eu vou sentir.")
	changed.emit()
	return true


func _make_door(i: int, hp: float) -> void:
	var d = doors[i]
	if d == null:
		var nd := DenDoor.new()
		var s: Dictionary = slots[i]
		var out: Vector3 = s["out"]
		nd.across = Vector3(-out.z, 0.0, out.x)
		nd.width = float(s.get("width", 3.2))
		nd.hp = hp
		nd.position = Vector3((s["pos"] as Vector3).x, 0.0, (s["pos"] as Vector3).z)
		nd.set_meta("slot", i)
		get_parent().add_child(nd)
		nd.hit.connect(_on_door_hit)
		nd.torn.connect(_on_door_torn)
		doors[i] = nd
	elif hp > 0.0:
		(d as DenDoor).weave()
		(d as DenDoor).hp = hp


func dir_name(i: int) -> String:
	var out: Vector3 = slots[i]["out"]
	var ang := rad_to_deg(atan2(out.x, -out.z))   # 0 = norte (z negativo), 90 = leste
	var names := ["norte", "nordeste", "leste", "sudeste", "sul", "sudoeste", "oeste", "noroeste"]
	return names[int(round(fposmod(ang, 360.0) / 45.0)) % 8]


func doors_summary() -> String:
	var ok := 0
	for i in slots.size():
		if door_state(i) == "inteira" or door_state(i) == "danificada":
			ok += 1
	return "%d de %d entradas fechadas" % [ok, slots.size()]


func _on_door_hit(door: DenDoor, by: Node3D) -> void:
	var i: int = door.get_meta("slot")
	var who := (by as Creature).display_name if by is Creature else "Algo"
	_warn("%s está rasgando a porta %s da toca!" % [who, dir_name(i)], door.global_position)


func _on_door_torn(door: DenDoor) -> void:
	var i: int = door.get_meta("slot")
	_note("A porta %s foi rasgada." % dir_name(i))
	_warn("A porta %s da toca foi rasgada!" % dir_name(i), door.global_position, true)
	changed.emit()


func _warn(text: String, at: Vector3, force: bool = false) -> void:
	## Com fios-alarme você sabe na hora, onde estiver; sem eles, só se estiver perto.
	var p := GameState.player as Player
	var near := p != null and Fx.flat_dist(p.global_position, center) < 30.0
	if not alarm and not near:
		return
	if _alarm_t > 0.0 and not force:
		return
	_alarm_t = 8.0
	if alarm:
		EventBus.big_message.emit("Fios-alarme: " + text)
	else:
		EventBus.message.emit(text)
	EventBus.web_touched.emit(at, null)


func buy_alarm(p: Player) -> bool:
	if alarm:
		return false
	if p.silk < ALARM_COST:
		EventBus.message.emit("Seda insuficiente para os fios-alarme (precisa de %d)." % int(ALARM_COST))
		return false
	p.silk -= ALARM_COST
	alarm = true
	_note("Fios-alarme instalados nas portas.")
	changed.emit()
	return true


func on_rest() -> void:
	## Dormir na toca remenda as portas danificadas (as rasgadas precisam ser tecidas de novo).
	for i in doors.size():
		if doors[i] != null and (doors[i] as DenDoor).intact():
			(doors[i] as DenDoor).hp = DenDoor.MAX_HP
	grow(1.0)


# ---------------------------------------------------------------- despensa

func store(item: Dictionary) -> bool:
	if pantry.size() >= PANTRY_MAX:
		return false
	pantry.append(item)
	growth = minf(5.0, growth + 0.25)
	changed.emit()
	_refresh_decor()
	return true


func take(i: int) -> Dictionary:
	if i < 0 or i >= pantry.size():
		return {}
	var it: Dictionary = pantry[i]
	pantry.remove_at(i)
	changed.emit()
	return it


func steal(c: Creature) -> void:
	## O bicho que entrou come o que tem de mais gostoso.
	if pantry.is_empty():
		return
	var best := 0
	for i in pantry.size():
		if float(pantry[i].get("sat", 0.0)) > float(pantry[best].get("sat", 0.0)):
			best = i
	var it: Dictionary = take(best)
	c.needs.hunger = maxf(0.0, c.needs.hunger - float(it.get("sat", 20.0)) * 2.0)
	_note("%s invadiu e comeu %s." % [c.display_name, String(it.get("name", "uma presa"))])
	_warn("%s invadiu a toca e comeu %s!" % [c.display_name, String(it.get("name", "uma presa"))], c.global_position, true)


func _note(t: String) -> void:
	log_lines.push_front(t)
	if log_lines.size() > 4:
		log_lines.resize(4)


# ---------------------------------------------------------------- saque

func entry_for(c: Creature) -> Dictionary:
	## Por onde o bicho tenta entrar: a entrada mais perto dele (porta inteira = rasgar).
	var best := -1
	var best_d := INF
	for i in slots.size():
		var d := Fx.flat_dist(c.global_position, slots[i]["pos"])
		if d < best_d:
			best_d = d
			best = i
	if best < 0:
		return {}
	var s: Dictionary = slots[best]
	return {"slot": best, "door": doors[best], "outside": (s["pos"] as Vector3) + (s["out"] as Vector3) * 1.3}


func _process(delta: float) -> void:
	_alarm_t = maxf(0.0, _alarm_t - delta)
	if not claimed:
		return
	if raider != null and (not is_instance_valid(raider) or raider.dead or raider.raid_den != self):
		raider = null
	_raid_t -= delta
	if _raid_t > 0.0:
		return
	_raid_t = randf_range(25.0, 45.0)
	if raider != null or pantry.is_empty():
		return
	var p := GameState.player as Player
	if p != null and Fx.flat_dist(p.global_position, center) < SAFE_R:
		return
	if randf() > 0.35 + 0.05 * pantry.size():
		return
	var best: Creature = null
	var best_d := 45.0
	for c in World.creatures:
		if not is_instance_valid(c) or c.dead or c.asleep or not c.can_raid():
			continue
		if c.hunting_player() or c.cur_attack != null:
			continue
		if not (c is Ant) and c.needs.hunger < 45.0:
			continue
		var d := Fx.flat_dist(c.global_position, center)
		if d < best_d:
			best_d = d
			best = c
	if best != null:
		start_raid(best)


func start_raid(c: Creature) -> void:
	raider = c
	c.raid_den = self
	c.raid_t = 70.0
	if c.brain != null:
		c.brain.wake_up()


# ---------------------------------------------------------------- save

func to_dict() -> Dictionary:
	var dh: Array = []
	for d in doors:
		dh.append(-1.0 if d == null else (d as DenDoor).hp)
	return {"claimed": claimed, "pantry": pantry.duplicate(true), "alarm": alarm, "doors": dh, "log": log_lines.duplicate(), "growth": growth}


func from_dict(d: Dictionary) -> void:
	claimed = bool(d.get("claimed", false))
	growth = float(d.get("growth", 1.0 if claimed else 0.0))
	var pa = d.get("pantry", [])
	pantry = (pa as Array).duplicate(true) if pa is Array else []
	alarm = bool(d.get("alarm", false))
	var lg = d.get("log", [])
	log_lines = (lg as Array).duplicate() if lg is Array else []
	var dh = d.get("doors", [])
	if dh is Array:
		for i in mini((dh as Array).size(), slots.size()):
			var hp := float(dh[i])
			if hp >= 0.0:
				_make_door.call_deferred(i, hp)   # hp 0 = porta rasgada (só os fiapos)
	_ensure_cocoon.call_deferred()


func remember() -> void:
	## Guarda o estado no GameState (vai para o save e sobrevive à troca de camada).
	GameState.dens[_key()] = to_dict()
