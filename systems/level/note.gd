class_name Note
extends StaticBody3D
## Coisa para ler ou examinar (E): anotações dos aventureiros, cristais estranhos...
## Cada E mostra a próxima página na caixa de dicas.

var pages: Array = []
var flag_id := ""
var look := "papel"     ## "papel" ou "cristal"
var _page := 0
var _glow: MeshInstance3D
var _t := 0.0


func _init(pages_: Array = [], flag: String = "", look_: String = "papel") -> void:
	pages = pages_
	flag_id = flag
	look = look_


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 0
	collision_mask = 0
	if look == "cristal":
		var mat := Fx.mat(Color(0.5, 0.85, 1.0), 2.5, false, 0.85)
		for i in 3:
			var shard := Fx.box(Vector3(0.25, 0.9 - i * 0.2, 0.25), mat)
			shard.position = Vector3(-0.25 + i * 0.25, 0.4, 0.05 * i)
			shard.rotation = Vector3(0.2 * (i - 1), i, 0.3 * (i - 1))
			add_child(shard)
		var light := OmniLight3D.new()
		light.light_color = Color(0.5, 0.85, 1.0)
		light.omni_range = 4.0
		light.light_energy = 1.2
		light.position.y = 1.0
		add_child(light)
	else:
		var paper := Fx.box(Vector3(0.45, 0.04, 0.32), Fx.mat(Color(0.85, 0.8, 0.65)))
		paper.position.y = 0.05
		paper.rotation.y = 0.4
		add_child(paper)
	_glow = Fx.sphere(0.07, Fx.mat(Color(1.0, 0.95, 0.6), 3.0, true))
	_glow.position.y = 1.2 if look == "cristal" else 0.6
	add_child(_glow)


func _process(delta: float) -> void:
	_t += delta
	_glow.position.y = (1.2 if look == "cristal" else 0.6) + sin(_t * 3.0) * 0.08
	_glow.visible = _page < pages.size()


func interact(_p: Node) -> void:
	if pages.is_empty():
		return
	var i := mini(_page, pages.size() - 1)
	var more := "  (E: continuar)" if i < pages.size() - 1 else ""
	EventBus.hint.emit(String(pages[i]) + more)
	_page = i + 1
	if _page >= pages.size() and flag_id != "":
		GameState.flags[flag_id] = true
