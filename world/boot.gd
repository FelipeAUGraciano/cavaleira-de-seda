extends Node
## Cena inicial: abre a camada do último save ou começa pelo Berçário.

const FIRST_LAYER := "res://world/layers/bercario.tscn"


func _ready() -> void:
	var data := GameState.load_game()
	var scene := FIRST_LAYER
	var saved := String(data.get("scene", ""))
	if saved != "" and ResourceLoader.exists(saved):
		scene = saved
	get_tree().change_scene_to_file.call_deferred(scene)
