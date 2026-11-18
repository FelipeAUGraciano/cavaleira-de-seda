extends Node
## Quanto tem em cada câmara (bichos, pilares, luz, itens) por área de chão.
## Uso: godot --headless --path . res://tests/analise_mapa.tscn

const GROUPS := ["anchor", "fungus_light", "interactable", "lure", "hazard", "fire", "cocoon", "adventurer", "pickup", "nest"]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.permadeath = false
	for path in ["res://world/layers/bercario.tscn", "res://world/layers/galerias.tscn", "res://world/layers/abismo.tscn", "res://world/layers/rio_brasa.tscn"]:
		GameState.delete_save()
		GameState.said = {}
		GameState.flags = {}
		var layer = load(path).instantiate()
		add_child(layer)
		await _frames(30)
		var nav: NavGrid = World.nav
		var stats := {}
		var dump := {"w": nav.w, "h": nav.h, "origin": [nav.origin.x, nav.origin.y], "rooms": {}, "walk": [], "pts": []}
		for j in nav.h:
			var row := ""
			for i in nav.w:
				row += "0" if nav.grids[NavGrid.Kind.SMALL].is_point_solid(Vector2i(i, j)) else "1"
			dump["walk"].append(row)
		for id in nav.room_cells:
			var cells := []
			for c in nav.room_cells[id]:
				cells.append([c.x, c.y])
			dump["rooms"][id] = cells
		for c in World.creatures:
			if is_instance_valid(c):
				dump["pts"].append(["bicho", c.display_name, c.global_position.x, c.global_position.z])
		for g in GROUPS:
			for n in get_tree().get_nodes_in_group(g):
				dump["pts"].append([g, "", (n as Node3D).global_position.x, (n as Node3D).global_position.z])
		var names := {}
		for r in layer.rooms:
			names[String(r["id"])] = String(r.get("name", ""))
		dump["names"] = names
		var fo := FileAccess.open("/tmp/mapa_%s.json" % layer.layer_id, FileAccess.WRITE)
		fo.store_string(JSON.stringify(dump))
		fo.close()
		for r in layer.rooms:
			var id := String(r["id"])
			stats[id] = {"name": String(r.get("name", "")), "area": (nav.room_cells.get(id, []) as Array).size(), "bichos": {}, "coisas": {}}
		for c in World.creatures:
			if not is_instance_valid(c):
				continue
			var id := nav.room_at(c.global_position)
			if stats.has(id):
				var b: Dictionary = stats[id]["bichos"]
				b[c.display_name] = int(b.get(c.display_name, 0)) + 1
		for g in GROUPS:
			for n in get_tree().get_nodes_in_group(g):
				var id := nav.room_at((n as Node3D).global_position)
				if stats.has(id):
					var k: Dictionary = stats[id]["coisas"]
					k[g] = int(k.get(g, 0)) + 1
		for id in stats:
			var s: Dictionary = stats[id]
			var nb := 0
			for v in (s["bichos"] as Dictionary).values():
				nb += int(v)
			var nc := 0
			for v in (s["coisas"] as Dictionary).values():
				nc += int(v)
			var dens := float(nb + nc) / maxf(1.0, float(s["area"])) * 100.0
			print("ROOM\t%s\t%s\t%s\t%d\t%d\t%d\t%.2f\t%s\t%s" % [layer.layer_id, id, s["name"], s["area"], nb, nc, dens, JSON.stringify(s["bichos"]), JSON.stringify(s["coisas"])])
		layer.queue_free()
		await _frames(5)
	GameState.delete_save()
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
