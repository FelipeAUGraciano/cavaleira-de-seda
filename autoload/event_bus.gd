extends Node
## Sinais globais. Sistemas emitem e escutam aqui sem precisar se conhecer.

signal message(text: String)
signal big_message(text: String)
signal hint(text: String)
signal monologue(id: String, text: String)
signal creature_died(creature: Node)
signal web_touched(position: Vector3, by: Node)
signal territory_changed
signal player_leveled(level: int)
signal player_died
signal rested(cocoon: Node)
