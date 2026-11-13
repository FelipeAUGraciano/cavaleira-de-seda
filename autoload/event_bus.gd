extends Node
## Sinais globais. Sistemas emitem e escutam aqui sem precisar se conhecer.

@warning_ignore("unused_signal")
signal message(text: String)
@warning_ignore("unused_signal")
signal big_message(text: String)
@warning_ignore("unused_signal")
signal hint(text: String)
@warning_ignore("unused_signal")
signal monologue(id: String, text: String)
@warning_ignore("unused_signal")
signal creature_died(creature: Node)
@warning_ignore("unused_signal")
signal web_touched(position: Vector3, by: Node)
@warning_ignore("unused_signal")
signal territory_changed
@warning_ignore("unused_signal")
signal player_leveled(level: int)
@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal stalked(creature: Node)          ## um predador começou a seguir a jogadora
@warning_ignore("unused_signal")
signal rested(cocoon: Node)
