extends Node
## Bestiário: tudo que a Cavaleira já viu, derrotou e comeu nesta caverna.
##
## Cada criatura tem três níveis de anotação:
##   1. VISTA     nome, tamanho, onde vive e a nota dela (o que achou do bicho)
##   2. DERROTADA golpes (com o dano), sentidos, PV e a dica de como lidar
##   3. COMIDA    o que comer a carne dá
## Os perigos que não se vence (a Mãe, o Colosso, a Cortina viva) anotam tudo ao serem vistos.
##
## Os números (PV, golpes, sentidos, comida) são copiados do próprio bicho na hora em que ela
## o vê: o bestiário mostra o que o jogo usa de verdade. Fica em GameState.knowledge
## ("bestiary"), então sobrevive à morte e vai no save (gravado na hora, sem esperar o casulo).

signal changed(id: String, tier: int)

const SEEN := 1
const DEFEATED := 2
const EATEN := 3
const SCAN_EVERY := 0.4
const PORTRAITS := "res://assets/ui/bestiario/%s.png"

const AREAS := [
	["bercario", "Berçário"],
	["galerias", "Galerias Úmidas"],
	["abismo", "Abismo"],
	["rio", "Rio de Brasa"],
	["cacada", "Galerias — a caçada"],
	["portao", "Portão da Superfície"],
]

## kind: bicho, chefe, perigo (não dá para vencer), humano.
## manual: ficha escrita à mão para quem não é Creature (não tem PV nem golpes no código).
const ENTRIES := [
	{"id": "irma_menor", "name": "Irmã menor", "area": "bercario", "kind": "bicho",
		"note": "Minhas irmãs. Saímos do mesmo saco de ovos, e mesmo assim elas olham pra mim como se eu fosse almoço. Ou sou eu que olho assim pra elas? ...Melhor não pensar nisso.",
		"tip": "Foge pela vibração do chão. Chegue andando devagar ou por cima de um fio."},
	{"id": "irma_faminta", "name": "Irmã faminta", "aliases": ["Irmã caçadora"], "area": "bercario", "kind": "bicho",
		"note": "Maior, mais rápida e com fome de mim. Família é complicado.",
		"tip": "Três mordidas matam uma Filhote. Use a teia de captura e fuja pelos fios; se ela pular, esquive para o lado e morda na volta."},
	{"id": "mae", "name": "A Mãe", "area": "bercario", "kind": "perigo",
		"note": "Eu vi só as patas. Foi o bastante pra eu nunca mais querer ver o resto.",
		"tip": "Não dá para lutar. Corra pelo túnel sem parar nos abismos: a saída é estreita demais para ela.",
		"manual": {"size": "Colossal", "hp": "—", "senses": "vibração e o cheiro dos filhotes",
			"attacks": [["Pisada", "35 de dano e um empurrão; depois ela ruge por quase um segundo (a chance de fugir)"]]}},

	{"id": "larva", "name": "Larva-de-musgo", "area": "galerias", "kind": "bicho",
		"note": "Gosto de musgo molhado. A primeira coisa que eu comi na vida, e provavelmente a única coisa nesta caverna mais fraca que eu.",
		"tip": "Foge do seu cheiro. Prenda com um fio, ou espere ela ir atrás da isca de um Lagarto-lanterna."},
	{"id": "sapo", "name": "Sapo-de-rocha", "area": "galerias", "kind": "bicho",
		"note": "Uma pedra com boca. A língua puxa a gente direto pra ela, que é a pior direção possível.",
		"tip": "Fique fora do cone da língua (a marca no chão) e ataque pelos lados. Dorme na poça quando os fungos acendem."},
	{"id": "morcego", "name": "Morcego-eco", "area": "galerias", "kind": "bicho",
		"note": "Me acham pelo barulho dos passos. Ficar parada funciona, por mais que cada pelo do meu corpo grite CORRE.",
		"tip": "Pare quando o bando passar. Um fio esticado no caminho do mergulho derruba o morcego."},
	{"id": "lagarto", "name": "Lagarto-lanterna", "area": "galerias", "kind": "bicho",
		"note": "Tem uma lanterna na testa e usa pra hipnotizar larvas. Genial. Eu queria uma.",
		"tip": "Território marcado: a isca pisca vermelho como aviso. Saia ou lute; ele não persegue para fora."},
	{"id": "formiga", "name": "Formiga-de-seda", "area": "galerias", "kind": "bicho",
		"note": "Comem os meus fios. OS MEUS FIOS. Sozinha não é nada; o problema é que ela nunca está sozinha.",
		"tip": "Mate a primeira antes que ela chame as vizinhas. Fios perto do formigueiro duram pouco."},
	{"id": "cobra", "name": "Cobra-das-frestas", "area": "galerias", "kind": "bicho",
		"note": "Dois olhinhos brilhando numa fresta da parede. Se eu passar correndo, viro um risco no chão.",
		"tip": "Ela sente quem anda. Passe parada ou bem devagar; depois do bote ela fica exposta uns segundos: é a hora de bater."},
	{"id": "centopeia", "name": "Centopeia-blindada", "area": "galerias", "kind": "chefe",
		"note": "Oito metros de armadura e fome. O chão treme antes de ela chegar. E às vezes ela chega POR BAIXO.",
		"tip": "A carapaça segura quase tudo. Estique um fio no caminho da investida: ela arrebenta o fio, fica enredada, e aí os golpes entram. Quando ela cava, a rachadura segue sua vibração: pare num fio e ela sai onde você estava (se sair dentro do fio, enrosca). Furiosa, ela quica nas paredes e te cerca: saia do anel antes de fechar."},

	{"id": "besouro", "name": "Besouro carniceiro", "area": "abismo", "kind": "bicho",
		"note": "Rói ossos velhos no escuro e foge de mim. Finalmente alguém que me respeita.",
		"tip": "Comida fácil. Anda em bandos de 3 a 5."},
	{"id": "aranha_lobo", "name": "Aranha-lobo do breu", "area": "abismo", "kind": "bicho",
		"note": "Aranhas que não tecem. Só correm, uivam pelas patas e caçam em matilha. Rivais. Feias, também.",
		"tip": "Apague a runa: elas enxergam melhor quem brilha. Lute de costas para a parede; quando sobra uma ferida, ela foge."},
	{"id": "mimico", "name": "Mímico de estalagmite", "area": "abismo", "kind": "bicho",
		"note": "Um pilar que morde. Desde então eu olho torto para TODOS os pilares.",
		"tip": "No Modo Tecelagem ele não acende como os pilares de verdade, e a Leitura (Alt) entrega que é bicho."},
	{"id": "morcego_gigante", "name": "Morcego gigante", "area": "abismo", "kind": "bicho",
		"note": "O primo grande do Morcego-eco. Mesma regra, mergulho bem mais pesado.",
		"tip": "Parada, ele só te ouve bem perto. Fio esticado derruba igual."},
	{"id": "escorpiao", "name": "Escorpião-de-obsidiana", "area": "abismo", "kind": "bicho",
		"note": "Feito de vidro preto e maldade. O ferrão brilha vermelho, o que pelo menos é educado.",
		"tip": "Sente o chão: ande devagar perto do ninho. Saia da linha do ferrão; o giro de cauda vem quando ele fica furioso."},
	{"id": "lesma", "name": "Lesma de ácido", "area": "abismo", "kind": "bicho",
		"note": "Lenta, mole e quase impossível de matar. Deixa um rastro que derrete o chão. Encantadora.",
		"tip": "Não pise no rastro brilhante (por cima de um fio pode). Ela só se defende: dá para passar longe."},
	{"id": "colosso", "name": "Colosso da Fenda", "area": "abismo", "kind": "perigo",
		"note": "Um dragão do tamanho do corredor. Eu não vou lutar com isso. Eu vou me esconder numa rachadura e repensar as minhas escolhas.",
		"tip": "Não dá para vencer. Fique parada no escuro e use as rachaduras das paredes: ele não entra nelas.",
		"manual": {"size": "Colossal", "hp": "—", "senses": "vibração do chão (correr e andar em fios chamam); enxerga só de perto",
			"attacks": [["Pisada", "se ele te alcança, acabou"], ["Rugido", "olhos vermelhos: ele avança pela trilha até onde você está"]]}},
	{"id": "cortina", "name": "Cortina viva", "area": "abismo", "kind": "perigo",
		"note": "Centenas de morcegos gigantes pendurados juntinhos. Eu passo por baixo na ponta das patas, sem respirar.",
		"tip": "Runa apagada e andando devagar, ninguém acorda. Um Pulso Espiral perto derruba todos e abre o túnel.",
		"manual": {"size": "Colossal", "hp": "—", "senses": "luz e barulho",
			"attacks": [["Cortina fechando", "empurra para trás e machuca enquanto você estiver dentro"]]}},
	{"id": "serpente", "name": "Serpente-cega", "area": "abismo", "kind": "chefe",
		"note": "Não tem olhos e me acha mesmo assim. Sibila e escuta o eco. Depois sente até o meu calor.",
		"tip": "Ela vai sempre na vibração mais nova: teça uma teia de captura e espere o bote. Se ela te enrolar, aperte ATAQUE/ESQUIVA rápido; escapar abre as escamas. Num fio a onda da cauda passa por baixo, mas o sibilo te derruba. No fim, esconda-se nos jatos de vapor."},

	{"id": "besouro_brasa", "name": "Besouro-brasa", "area": "rio", "kind": "bicho",
		"note": "Um carvão com perninhas. Crocante por fora, crocante por dentro.",
		"tip": "A comida fácil do Rio de Brasa. Foge de você."},
	{"id": "morcego_cinza", "name": "Morcego de cinza", "area": "rio", "kind": "bicho",
		"note": "Mora na fumaça e mergulha pegando fogo. Quem é que inventa essas coisas?",
		"tip": "O mergulho queima. Mesma regra dos outros morcegos: parada, você some."},
	{"id": "aranha_cinza", "name": "Aranha de cinza", "area": "rio", "kind": "bicho",
		"note": "Rivais que tecem fio de cinza. Que NÃO queima. Estou com inveja e não tenho vergonha de admitir.",
		"tip": "Prendem de longe com fio grudento: quebre a linha de visão antes do cuspe."},
	{"id": "salamandra", "name": "Salamandra-chama", "area": "rio", "kind": "bicho",
		"note": "Um lagarto em brasa que cospe fogo e guarda o ninho. Perto dela, os meus fios viram fumaça.",
		"tip": "Saia da linha do sopro (a marca no chão). Fios perto dela queimam: lute no chão."},
	{"id": "golem", "name": "Golem de basalto", "area": "rio", "kind": "bicho",
		"note": "Uma pilha de pedra que dorme. Por favor, continue dormindo.",
		"tip": "Acorda com barulho: ande devagar ou vá pelos fios. Se perder você, volta a dormir."},
	{"id": "peixe_magma", "name": "Peixe-magma", "area": "rio", "kind": "bicho",
		"note": "Um peixe. De lava. Que pula em você. E depois fica se debatendo no chão como se a vítima fosse ele.",
		"tip": "Quando ele cair se debatendo, pegue. Longe da beirada, ele não alcança."},
	{"id": "verme_lava", "name": "Verme de lava", "area": "rio", "kind": "bicho",
		"note": "Sai da lava, cospe bola de fogo e afunda. Tímido, mas mal-educado.",
		"tip": "Saia das marcas no chão. Só dá para acertar enquanto ele está fora da lava."},
	{"id": "rainha", "name": "Salamandra-rainha", "area": "rio", "kind": "chefe",
		"note": "A mãe de todas as salamandras. Quando ela brilha inteira, a arena vira forno.",
		"tip": "Esquive (Espaço) na hora em que o anel de fogo passa. Depois da onda a pele esfria: bata com tudo."},

	{"id": "espadachim", "name": "Caçador espadachim", "area": "cacada", "kind": "humano",
		"note": "Humanos. Grandes, barulhentos e com fogo. Me chamam de \"aranha da runa\". Gostei do nome, odiei o resto.",
		"tip": "Corte que emenda e empurrão de escudo: não fique na frente dele. Vencido, vira comida como qualquer bicho."},
	{"id": "arqueira", "name": "Caçadora arqueira", "area": "cacada", "kind": "humano",
		"note": "Flechas de fogo de longe. Queimam os meus fios no caminho, e depois eu.",
		"tip": "Quebre a linha de visão e chegue por trás. De perto ela é frágil."},
	{"id": "batedor", "name": "Caçador batedor", "area": "cacada", "kind": "humano",
		"note": "Segue os meus fios com uma tocha e queima tudo. Basicamente um crítico de arte.",
		"tip": "Ele avisa o grupo quando acha seda. Pegue-o primeiro, longe dos outros."},
	{"id": "capita", "name": "Capitã da expedição", "area": "cacada", "kind": "chefe",
		"note": "A chefe deles. Armadura, espada pesada e uma trompa que chama reforço. Ela não está de brincadeira.",
		"tip": "A teia segura metade do tempo nela. Na metade da vida ela chama dois espadachins: guarde fios para eles."},

	{"id": "guardiao", "name": "Guardião do Portão", "area": "portao", "kind": "chefe",
		"note": "É o Colosso. O MESMO dragão da Fenda. Ele não estava passando pelo Abismo: ele mora aqui, na frente da saída. Lá embaixo eu me escondia numa rachadura. Aqui em cima eu sou do tamanho certo para responder.",
		"tip": "Fase 1: esquive da investida para ele bater num pilar. Fase 2: ele freia antes dos pilares; teia de captura no caminho da investida. Fase 3: cego, caça pela vibração; suma no escuro e bata por trás enquanto ele fareja."},
]

var _by_id := {}
var _by_name := {}
var _scan_t := 0.0
var _portraits := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for e in ENTRIES:
		_by_id[e["id"]] = e
		_by_name[e["name"]] = e["id"]
		for a in e.get("aliases", []):
			_by_name[a] = e["id"]


# ---------------------------------------------------------------- consulta

func entries() -> Array:
	return ENTRIES


func entry(id: String) -> Dictionary:
	return _by_id.get(id, {})


func id_for(creature_name: String) -> String:
	return String(_by_name.get(creature_name, ""))


func record(id: String) -> Dictionary:
	## O que já foi anotado: {"seen": bool, "kills": int, "eaten": int, "info": {...}}.
	return (_book().get(id, {}) as Dictionary)


func tier(id: String) -> int:
	var r := record(id)
	if r.is_empty() or not bool(r.get("seen", false)):
		return 0
	if entry(id).has("manual"):
		return DEFEATED   # perigos: ver já ensina tudo (e não dá para comer)
	if int(r.get("eaten", 0)) > 0:
		return EATEN
	if int(r.get("kills", 0)) > 0:
		return DEFEATED
	return SEEN


func count_seen() -> int:
	var n := 0
	for e in ENTRIES:
		if tier(e["id"]) > 0:
			n += 1
	return n


func portrait(id: String) -> Texture2D:
	if not _portraits.has(id):
		var p := PORTRAITS % id
		_portraits[id] = load(p) if ResourceLoader.exists(p) else null
	return _portraits[id]


func info(id: String) -> Dictionary:
	## Ficha do bicho: a manual (perigos) ou a copiada dele na hora em que foi visto.
	var e := entry(id)
	if e.has("manual"):
		return e["manual"]
	return (record(id).get("info", {}) as Dictionary)


# ---------------------------------------------------------------- anotar

func see(c: Node) -> void:
	var id := _id_of(c)
	if id == "":
		return
	var r := _rec(id)
	if c is Creature:
		r["info"] = snapshot(c as Creature)
	if bool(r.get("seen", false)):
		return
	r["seen"] = true
	_announce(id, SEEN)


func see_id(id: String) -> void:
	if not _by_id.has(id):
		return
	var r := _rec(id)
	if bool(r.get("seen", false)):
		return
	r["seen"] = true
	_announce(id, SEEN)


func defeated(c: Creature) -> void:
	var id := _id_of(c)
	if id == "":
		return
	var before := tier(id)
	var r := _rec(id)
	r["seen"] = true
	r["info"] = snapshot(c)
	r["kills"] = int(r.get("kills", 0)) + 1
	if tier(id) > before:
		_announce(id, tier(id))


func eaten(creature_name: String) -> void:
	var id := id_for(creature_name)
	if id == "":
		return
	var before := tier(id)
	var r := _rec(id)
	r["seen"] = true
	r["eaten"] = int(r.get("eaten", 0)) + 1
	if tier(id) > before:
		_announce(id, tier(id))


static func snapshot(c: Creature) -> Dictionary:
	var atk: Array = []
	for a in c.attacks:
		if a.label == "":
			continue
		var fx := a.effect
		if a.shape == Attack.Shape.LINE and fx == "":
			fx = "line"
		atk.append([a.label, roundi(a.damage), fx, a.only_enraged])
	return {
		"hp": roundi(c.max_hp),
		"size": Creature.SIZE_NAMES[clampi(int(c.size), 0, Creature.SIZE_NAMES.size() - 1)],
		"level": c.level,
		"senses": c.senses_text,
		"attacks": atk,
		"fire_immune": c.fire_immune,
		"food": {"satiety": roundi(c.food_satiety), "silk": roundi(c.food_silk), "xp": c.food_xp,
			"energy": c.food_energy, "acid": c.food_acid, "fire": c.food_fire,
			"poison": c.food_poison, "skin": c.food_skin},
	}


func _id_of(c: Node) -> String:
	if c is Creature:
		return id_for((c as Creature).display_name)
	if c.is_in_group("colossus"):
		return "colosso"
	if c.is_in_group("bat_curtain"):
		return "cortina"
	return ""


func _book() -> Dictionary:
	if not GameState.knowledge.has("bestiary") or not (GameState.knowledge["bestiary"] is Dictionary):
		GameState.knowledge["bestiary"] = {}
	return GameState.knowledge["bestiary"]


func _rec(id: String) -> Dictionary:
	var b := _book()
	if not b.has(id) or not (b[id] is Dictionary):
		b[id] = {"seen": false, "kills": 0, "eaten": 0}
	return b[id]


func _announce(id: String, t: int) -> void:
	var nm := String(entry(id)["name"])
	match t:
		SEEN:
			EventBus.message.emit("Bestiário: %s anotada." % nm if nm.begins_with("A ") else "Bestiário: nova entrada — %s." % nm)
		DEFEATED:
			EventBus.message.emit("Bestiário: golpes de %s anotados." % nm)
		EATEN:
			EventBus.message.emit("Bestiário: %s completo." % nm)
	Sfx.play("ui_item", Vector3.INF, -8.0)
	changed.emit(id, t)
	GameState.save_knowledge()


# ---------------------------------------------------------------- de olho

func _process(delta: float) -> void:
	_scan_t -= delta
	if _scan_t > 0.0:
		return
	_scan_t = SCAN_EVERY
	var p = GameState.player
	if p == null or not is_instance_valid(p) or not p.is_inside_tree():
		return
	var at: Vector3 = p.global_position
	var r: float = maxf(5.0, p.sight_radius() + 2.0)
	for c in get_tree().get_nodes_in_group("creature"):
		var cr := c as Creature
		if cr == null or cr.dead or cr.has_meta("vitrine"):
			continue
		var id := id_for(cr.display_name)
		if id == "" or (bool(record(id).get("seen", false)) and record(id).has("info")):
			continue
		if not cr.bestiary_visible():
			continue
		var d := at.distance_to(cr.global_position) - cr.body_radius
		if d <= r or (cr.noticed_player and d <= 14.0):
			see(cr)
	for c in get_tree().get_nodes_in_group("colossus"):
		if at.distance_to((c as Node3D).global_position) < 22.0:
			see(c)
	for c in get_tree().get_nodes_in_group("bat_curtain"):
		if at.distance_to((c as Node3D).global_position) < 9.0:
			see(c)
