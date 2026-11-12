class_name Skills
extends RefCounted
## Teia de habilidades do menu do casulo.
##
## O centro (Fiandeira) já vem aprendido. Cada braço é um ramo; os nós de fora (diagonais)
## ligam dois braços. Só dá para aprender um nó ligado a outro que você já tem.
## 1 Ponto de Habilidade por nível (a muda não tira os pontos).
## pos: posição na teia (1 = um anel). icon: desenho em ui/skill_icons.gd.

const ALL := {
	"fiandeira": {"name": "Fiandeira", "branch": "Comum", "cost": 0, "pos": Vector2(0, 0), "icon": "web",
		"desc": "Você nasceu tecendo. Fio-guia, casulo e lançar fio.", "links": ["afiadas", "fio_leve", "runa_oculta", "carapaca"]},

	# Lâmina (para cima)
	"afiadas": {"name": "Garras Afiadas", "branch": "Lâmina", "cost": 1, "pos": Vector2(0, -1), "icon": "claw",
		"desc": "Golpes do combo causam +25% de dano.", "links": ["espiral"]},
	"espiral": {"name": "Corte em Espiral", "branch": "Lâmina", "cost": 2, "pos": Vector2(0, -2), "icon": "spiral", "form": 1,
		"desc": "O 3º golpe do combo vira um giro com as duas lâminas, atingindo todos ao redor.", "links": ["investida"]},
	"investida": {"name": "Investida", "branch": "Lâmina", "cost": 3, "pos": Vector2(0, -3), "icon": "dash",
		"desc": "A esquiva atravessa bichos pequenos e corta quem estiver no caminho (8 de dano).", "links": []},

	# Teia (para a direita)
	"fio_leve": {"name": "Fio Leve", "branch": "Teia", "cost": 1, "pos": Vector2(1, 0), "icon": "thread",
		"desc": "Fio-guia custa 3 de Seda em vez de 5.", "links": ["puxao"]},
	"puxao": {"name": "Puxão", "branch": "Teia", "cost": 2, "pos": Vector2(2, 0), "icon": "hook",
		"desc": "Lançar fio alcança 50% mais longe e também puxa bichos médios.", "links": ["teia_veneno"]},
	"teia_veneno": {"name": "Teia Venenosa", "branch": "Teia", "cost": 3, "pos": Vector2(3, 0), "icon": "web_drop",
		"desc": "A teia de captura envenena quem ficar preso nela.", "links": []},

	# Runa (para a esquerda)
	"runa_oculta": {"name": "Runa Oculta", "branch": "Runa", "cost": 1, "pos": Vector2(-1, 0), "icon": "rune",
		"desc": "Com a runa apagada, a Energia continua voltando (pela metade).", "links": ["pulso"]},
	"pulso": {"name": "Pulso Espiral", "branch": "Runa", "cost": 2, "pos": Vector2(-2, 0), "icon": "pulse",
		"desc": "Ao reacender a runa, solta uma onda de luz que atordoa os bichos perto (20 de Energia).", "links": ["olhos"]},
	"olhos": {"name": "Olhos de Cristal", "branch": "Runa", "cost": 3, "pos": Vector2(-3, 0), "icon": "eye",
		"desc": "Enxerga 1,5 m mais longe no escuro.", "links": []},

	# Corpo (para baixo)
	"carapaca": {"name": "Carapaça", "branch": "Corpo", "cost": 1, "pos": Vector2(0, 1), "icon": "shield",
		"desc": "+15 PV máximos.", "links": ["reserva"]},
	"reserva": {"name": "Glândula Cheia", "branch": "Corpo", "cost": 2, "pos": Vector2(0, 2), "icon": "spool",
		"desc": "+20 de Seda máxima.", "links": ["estomago"]},
	"estomago": {"name": "Estômago de Ferro", "branch": "Corpo", "cost": 3, "pos": Vector2(0, 3), "icon": "moon",
		"desc": "Carne podre machuca pela metade e a fome demora 25% mais.", "links": []},

	# Diagonais: ligam dois braços
	"sangue_frio": {"name": "Sangue Frio", "branch": "Lâmina · Runa", "cost": 2, "pos": Vector2(-1.55, -1.55), "icon": "drop",
		"desc": "Regenera PV duas vezes mais rápido quando está bem alimentada.", "links": ["afiadas", "runa_oculta"]},
	"tecela": {"name": "Tecelã Veloz", "branch": "Lâmina · Teia", "cost": 2, "pos": Vector2(1.55, -1.55), "icon": "wind",
		"desc": "O Modo Tecelagem gasta 40% menos Energia.", "links": ["afiadas", "fio_leve"]},
	"paladar": {"name": "Paladar Caçador", "branch": "Runa · Corpo", "cost": 2, "pos": Vector2(-1.55, 1.55), "icon": "fang",
		"desc": "Comer dá 25% mais XP.", "links": ["runa_oculta", "carapaca"]},
	"passos": {"name": "Passos de Seda", "branch": "Teia · Corpo", "cost": 2, "pos": Vector2(1.55, 1.55), "icon": "steps",
		"desc": "Sobre os fios você corre ainda mais rápido (×1,8 em vez de ×1,5).", "links": ["fio_leve", "carapaca"]},
}

const FORM_NAMES := ["Filhote de Seda", "Cavaleira de Seda"]


static func info(id: String) -> Dictionary:
	return ALL.get(id, {})


static func neighbors(id: String) -> Array:
	## Ligações nos dois sentidos.
	var out: Array = (ALL[id]["links"] as Array).duplicate()
	for other in ALL:
		if other != id and (ALL[other]["links"] as Array).has(id) and not out.has(other):
			out.append(other)
	return out


static func edges() -> Array:
	## [a, b, diagonal?] uma vez cada.
	var out: Array = []
	for a in ALL:
		for b in ALL[a]["links"]:
			out.append([a, b, String(a) in ["sangue_frio", "tecela", "paladar", "passos"]])
	return out
