class_name HuntDirector
extends Node
## Alerta da caçada, de 0 a 3. Sobe quando um caçador te vê (+0,8), acha teia (+0,4) ou perde
## um companheiro (+0,6). Depois de 20 s sem te ver, cai 1 nível a cada 25 s.
## No 3, o esquadrão do acampamento sai atrás do último lugar onde te viram.
signal level_changed(level: int)
signal squad_out

var alert := 0.0
var last_pos := Vector3.ZERO
var since_seen := 99.0
var squad_sent := false
var camp_rooms: Array = ["G4"]   ## para onde o esquadrão volta quando o alerta baixa

func raise(amount: float, pos: Vector3, _by: Node = null) -> void:
	var before := int(alert)
	alert = minf(3.0, alert + amount)
	last_pos = pos
	since_seen = 0.0
	var now := int(alert)
	if now > before:
		level_changed.emit(now)
		if now < 3:
			EventBus.message.emit("Alerta da caçada %d: %s" % [now, ["", "eles sabem que você está por perto.", "os caçadores estão procurando você."][now]])
	if now >= 3 and not squad_sent:
		_send_squad()
	elif squad_sent:
		_point_squad()
	GameState.hunt_alert = alert

func comrade_down(h: Node) -> void:
	var alive := 0
	for o in get_tree().get_nodes_in_group("hunter"):
		if o != h and not (o as Creature).dead:
			alive += 1
	if alive > 0:
		raise(0.6, (h as Node3D).global_position, h)

func _send_squad() -> void:
	squad_sent = true
	squad_out.emit()
	GameState.say_once("a4_esquadrao", "Sinos. Três vezes. Eles tão vindo TODOS.")
	_point_squad()

func _point_squad() -> void:
	for o in get_tree().get_nodes_in_group("hunter"):
		var h := o as Hunter
		if h == null or h.dead or not h.squad:
			continue
		h.range_rooms = []
		h.track_range = 200.0
		h.leash_range = 200.0
		h.player_memory = h.memory_time
		h.last_player_pos = last_pos

func _process(delta: float) -> void:
	since_seen += delta
	if since_seen > 20.0 and alert > 0.0:
		var before := int(alert)
		alert = maxf(0.0, alert - delta / 25.0)
		if int(alert) < before:
			level_changed.emit(int(alert))
			EventBus.message.emit("O alerta da caçada baixou para %d." % int(alert))
		if alert < 2.0 and squad_sent:
			squad_sent = false
			for o in get_tree().get_nodes_in_group("hunter"):
				var h := o as Hunter
				if h != null and not h.dead and h.squad:
					h.range_rooms = camp_rooms.duplicate()
					h.track_range = 24.0
					h.leash_range = 45.0
	GameState.hunt_alert = alert
