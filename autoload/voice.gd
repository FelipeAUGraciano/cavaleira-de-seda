extends Node
## Toca a dublagem de cada fala do monólogo, se o arquivo existir.
## Coloque o áudio em res://audio/voice/<id>.ogg (ou .wav / .mp3).
## Os ids das falas estão listados em docs/falas.md.

const EXTENSIONS := ["ogg", "wav", "mp3"]

var _player := AudioStreamPlayer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)
	EventBus.monologue.connect(_on_monologue)


func _on_monologue(id: String, _text: String) -> void:
	for ext in EXTENSIONS:
		var path := "res://audio/voice/%s.%s" % [id, ext]
		if ResourceLoader.exists(path):
			_player.stream = load(path)
			_player.play()
			return
