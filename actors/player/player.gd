class_name Player
extends CharacterBody3D
## A Cavaleira de Seda (forma Filhote no protótipo).
## Movimento twin-stick, esquiva, combate, fio, Modo Tecelagem, casulo e os 4 recursos.
## Os recursos aparecem no corpo: placas = PV, runa = Energia, cachecol = Seda, abdômen = Saciedade.

# ---------------------------------------------------------------- balanceamento
const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const STRAND_SPEED_MULT := 1.5
const DODGE_SPEED := 13.0
const DODGE_TIME := 0.32
const DODGE_INVULN := 0.3
const DODGE_COST := 15.0
const BACKSTEP_SPEED := 10.0
const BACKSTEP_TIME := 0.16
const BACKSTEP_COST := 8.0
const GRAVITY := 22.0

const COMBO_DAMAGE := [8.0, 8.0, 14.0]   ## (Cavaleira) — a forma atual decide: veja FORMS
const ATTACK_TIME := 0.3
const ATTACK_RANGE := 1.7
const ATTACK_ARC := 100.0
const BITE_TIME := 0.45
const BITE_DAMAGE := 4.0
const BITE_RANGE := 1.4

const STRAND_RANGE := 12.0
const THROW_RANGE := 12.0
const TRAP_RANGE := 8.0
const SILK_STRAND := 5.0
const SILK_TRAP := 15.0
const SILK_COCOON := 30.0
const SILK_THROW := 5.0
const TRAP_LEVEL := 3

const WEAVE_TIME_SCALE := 0.25
const WEAVE_ENERGY_PER_SEC := 8.0
const ENERGY_REGEN := 10.0
const SATIETY_DECAY := 1.0 / 6.0   ## ~10 min de cheia a vazia
const STARVE_DPS := 1.0
const FALL_DAMAGE := 25.0

## Formas (evolução). A jogadora nasce Filhote: pequena, frágil, garras fracas — precisa de
## teia, veneno e armadilha para caçar qualquer coisa do tamanho de um sapo. No nível
## EVOLVE_LEVEL, descansar num casulo faz a muda: vira a Cavaleira de Seda (lâminas, placas,
## o dobro da vida), o nível volta a 1 e o crescimento por nível dobra.
## No nível BRANCH_LEVEL da Cavaleira, a jogadora escolhe no casulo um dos três ramos
## (Lâmina, Teia ou Runa) e a próxima muda faz a forma escolhida.
## No nível FINAL_LEVEL do ramo vem a última muda: cada ramo se divide em dois, e quem
## cumpriu os requisitos de uma forma rara (resistências e materiais) pode escolher ela no lugar.
enum Form { FILHOTE, CAVALEIRA, LAMINA, TEIA, RUNA,
	EXECUTORA, BASTIA, SENHORA, SALTADORA, VIDENTE, TEMPESTADE,
	ARDENTE, BREU, VIUVA, CORROSIVA, LUA }
const EVOLVE_LEVEL := 8
const BRANCH_LEVEL := 10
const FINAL_LEVEL := 10
## Equilíbrio (teste de 24/11: depois da muda tudo ficava fácil demais). Por estágio:
## 0 Filhote, 1 Cavaleira, 2 ramo, 3 forma final/rara. Vida e força crescem menos a cada muda.
const HP_MULT := [1.0, 0.85, 0.75, 0.7]
const POWER := [1.0, 0.8, 0.7, 0.62]
## Os testes de kit/evolução desligam o freio para medir as fichas cruas.
static var balanced := true
const BRANCHES := [Form.LAMINA, Form.TEIA, Form.RUNA]
const FINALS := {Form.LAMINA: [Form.EXECUTORA, Form.BASTIA], Form.TEIA: [Form.SENHORA, Form.SALTADORA], Form.RUNA: [Form.VIDENTE, Form.TEMPESTADE]}
const RARES := [Form.ARDENTE, Form.BREU, Form.VIUVA, Form.CORROSIVA, Form.LUA]
const MOONSTONES_NEEDED := 4
const FORMS := {
	Form.FILHOTE: {"name": "Filhote de Seda", "scale": 0.7, "size": 0, "hp": 40.0, "energy": 60.0, "silk": 40.0,
		"per_level": [4.0, 3.0, 2.0], "combo": [4.0, 4.0, 7.0], "bite": 3.0, "speed": 1.06, "hide": 0.8, "sight": 3.5},
	Form.CAVALEIRA: {"name": "Cavaleira de Seda", "scale": 1.0, "size": 1, "hp": 90.0, "energy": 90.0, "silk": 60.0,
		"per_level": [8.0, 4.0, 3.0], "combo": [8.0, 8.0, 14.0], "bite": 5.0, "speed": 1.0, "hide": 1.0, "sight": 5.5},
	# Ramo Lâmina: garras viram foices; mais vida, golpes pesados e couraça
	Form.LAMINA: {"name": "Ceifadora de Seda", "branch": "Lâmina", "scale": 1.15, "size": 1, "hp": 140.0, "energy": 100.0, "silk": 60.0,
		"per_level": [10.0, 5.0, 3.0], "combo": [14.0, 14.0, 26.0], "bite": 7.0, "speed": 1.05, "hide": 1.0, "sight": 6.0,
		"armor": 0.85, "tint": Color(1.0, 0.35, 0.3),
		"desc": ["Foices de cristal: combo 14 / 14 / 26 e mais alcance.", "Couraça: -15% de todo dano recebido.", "140 PV base, +10 por nível."]},
	# Ramo Teia: a tecelã — muita seda, fios baratos e longos, anda rápido nos fios
	Form.TEIA: {"name": "Tecelã do Abismo", "branch": "Teia", "scale": 1.05, "size": 1, "hp": 110.0, "energy": 100.0, "silk": 120.0,
		"per_level": [7.0, 4.0, 7.0], "combo": [9.0, 9.0, 16.0], "bite": 6.0, "speed": 1.0, "hide": 0.9, "sight": 6.0,
		"strand_bonus": 3.0, "strand_cost": 0.5, "trap_cost": 0.6, "strand_speed": 1.3, "tint": Color(0.92, 0.95, 1.0),
		"desc": ["120 de Seda base, +7 por nível.", "Fio-guia pela metade da seda e +3 m de alcance; teia de captura -40%.", "Anda 30% mais rápido nos fios."]},
	# Ramo Runa: a arauta — energia, visão e furtividade; o Pulso Espiral já vem com ela
	Form.RUNA: {"name": "Arauta da Runa", "branch": "Runa", "scale": 1.0, "size": 1, "hp": 100.0, "energy": 150.0, "silk": 80.0,
		"per_level": [7.0, 7.0, 4.0], "combo": [10.0, 10.0, 18.0], "bite": 6.0, "speed": 1.08, "hide": 0.6, "sight": 8.0,
		"pulse": true, "tint": Color(0.45, 0.85, 1.0),
		"desc": ["150 de Energia base e enxerga 8 m no escuro.", "Muito mais furtiva (os bichos te veem 40% mais perto).", "Pulso Espiral já vem: custa 10 e atordoa a 6,5 m."]},
	# ---- última muda: Lâmina
	Form.EXECUTORA: {"icon": "claw", "name": "Executora de Seda", "branch": "Lâmina", "parent": Form.LAMINA, "scale": 1.25, "size": 1, "hp": 210.0, "energy": 120.0, "silk": 70.0,
		"per_level": [12.0, 5.0, 3.0], "combo": [22.0, 22.0, 40.0], "bite": 9.0, "speed": 1.08, "hide": 1.0, "sight": 6.5,
		"armor": 0.85, "execute": 0.25, "kill_heal": 0.08, "tint": Color(1.0, 0.18, 0.22),
		"pitch": "Fúria: ataque total.",
		"desc": ["Foices longas: combo 22 / 22 / 40.", "Execução: golpe em bicho com menos de 25% da vida mata na hora (chefe: dano dobrado).", "Cada abate cura 8% da vida."]},
	Form.BASTIA: {"icon": "shield", "name": "Bastiã de Pedra", "branch": "Lâmina", "parent": Form.LAMINA, "scale": 1.3, "size": 1, "hp": 280.0, "energy": 110.0, "silk": 70.0,
		"per_level": [16.0, 4.0, 3.0], "combo": [18.0, 18.0, 30.0], "bite": 8.0, "speed": 0.95, "hide": 1.1, "sight": 6.0,
		"armor": 0.6, "thorns": 0.4, "no_knockback": true, "tint": Color(0.78, 0.72, 0.62),
		"pitch": "Couraça: aguentar tudo.",
		"desc": ["280 PV base, +16 por nível; couraça: -40% de todo dano.", "Espinhos: quem te acerta de perto leva 40% do dano de volta.", "Nada te empurra. Mais lenta e mais fácil de ver."]},
	# ---- última muda: Teia
	Form.SENHORA: {"icon": "web", "name": "Senhora das Teias", "branch": "Teia", "parent": Form.TEIA, "scale": 1.1, "size": 1, "hp": 170.0, "energy": 120.0, "silk": 180.0,
		"per_level": [9.0, 5.0, 9.0], "combo": [12.0, 12.0, 20.0], "bite": 7.0, "speed": 1.0, "hide": 0.9, "sight": 6.5,
		"strand_bonus": 3.0, "strand_cost": 0.4, "trap_cost": 0.4, "strand_speed": 1.3,
		"trap_capacity": 6, "trap_hold": 6.0, "trap_slow_big": 2.5, "tint": Color(0.88, 0.82, 1.0),
		"pitch": "Rede: armadilhas que seguram tudo.",
		"desc": ["180 de Seda base; fio e teia de captura por 40% da seda.", "Seda grossa: a teia segura 6 presas e bicho M fica preso 6 s.", "Bicho grande que arrebenta a teia perde o passo por 2,5 s."]},
	Form.SALTADORA: {"icon": "wind", "name": "Saltadora do Vento", "branch": "Teia", "parent": Form.TEIA, "scale": 1.05, "size": 1, "hp": 160.0, "energy": 140.0, "silk": 150.0,
		"per_level": [8.0, 6.0, 7.0], "combo": [12.0, 12.0, 22.0], "bite": 7.0, "speed": 1.12, "hide": 0.85, "sight": 6.5,
		"strand_bonus": 7.0, "strand_cost": 0.5, "trap_cost": 0.6, "strand_speed": 1.9, "dodge_cost": 0.5, "dive": 30.0,
		"tint": Color(0.6, 0.9, 1.0),
		"pitch": "Voo: fios longos e mergulho.",
		"desc": ["Fio-guia +7 m e quase o dobro da velocidade nos fios.", "Mergulho: chegar de um fio lançado (Q) acerta 30 e atordoa quem estiver perto.", "Esquiva pela metade da energia."]},
	# ---- última muda: Runa
	Form.VIDENTE: {"icon": "eye", "name": "Vidente da Runa", "branch": "Runa", "parent": Form.RUNA, "scale": 1.0, "size": 1, "hp": 150.0, "energy": 200.0, "silk": 100.0,
		"per_level": [8.0, 8.0, 5.0], "combo": [13.0, 13.0, 22.0], "bite": 7.0, "speed": 1.1, "hide": 0.5, "sight": 10.0,
		"pulse": true, "dark_regen": true, "reveal": 18.0, "dodge_bonus": 0.15, "tint": Color(1.0, 0.92, 0.55),
		"pitch": "Olho: ver tudo antes.",
		"desc": ["Enxerga 10 m no escuro e vê os bichos a 18 m através das paredes.", "Vê o golpe chegar: esquiva com mais tempo invulnerável.", "Pulso Espiral (10 de energia) e a furtividade da Arauta."]},
	Form.TEMPESTADE: {"icon": "pulse", "name": "Sacerdotisa da Tempestade", "branch": "Runa", "parent": Form.RUNA, "scale": 1.05, "size": 1, "hp": 150.0, "energy": 240.0, "silk": 100.0,
		"per_level": [8.0, 10.0, 5.0], "combo": [13.0, 13.0, 22.0], "bite": 7.0, "speed": 1.08, "hide": 0.65, "sight": 8.5,
		"pulse": true, "dark_regen": true, "pulse_r": 8.5, "pulse_dmg": 26.0, "energy_regen": 1.5, "tint": Color(0.45, 0.6, 1.0),
		"pitch": "Pulso: a runa vira arma.",
		"desc": ["240 de Energia base, +10 por nível; energia volta 50% mais rápido.", "Pulso Espiral a 8,5 m: atordoa e acerta 26.", "Um pulso a cada vez que acende a runa (10 de energia)."]},
	# ---- formas raras (qualquer ramo, com requisitos)
	Form.ARDENTE: {"icon": "star", "name": "Seda Ardente", "branch": "Rara", "rare": "Fogo", "scale": 1.15, "size": 1, "hp": 200.0, "energy": 140.0, "silk": 110.0,
		"per_level": [11.0, 6.0, 5.0], "combo": [16.0, 16.0, 28.0], "bite": 8.0, "speed": 1.06, "hide": 1.0, "sight": 7.0,
		"fireproof": true, "ignite": 3.0, "tint": Color(1.0, 0.5, 0.12),
		"pitch": "Rara de Fogo.",
		"desc": ["Imune a calor, brasa e queimadura; cair na lava não queima.", "Seus fios e teias não pegam fogo.", "Golpes e mordida incendeiam (5 PV/s por 3 s)."]},
	Form.BREU: {"icon": "steps", "name": "Sombra do Breu", "branch": "Rara", "rare": "Escuridão", "scale": 1.0, "size": 1, "hp": 160.0, "energy": 160.0, "silk": 110.0,
		"per_level": [8.0, 7.0, 5.0], "combo": [14.0, 14.0, 24.0], "bite": 8.0, "speed": 1.08, "hide": 0.35, "sight": 9.0,
		"dark_regen": true, "shadow": true, "ambush": 2.5, "tint": Color(0.35, 0.2, 0.55),
		"pitch": "Rara de Escuridão.",
		"desc": ["Parada e de runa apagada, ninguém te vê (só encostando ou ouvindo).", "Emboscada: golpe em quem não te notou dá 2,5x de dano.", "Enxerga 9 m no breu; energia volta com a runa apagada."]},
	Form.VIUVA: {"icon": "fang", "name": "Viúva de Seda", "branch": "Rara", "rare": "Veneno", "scale": 1.05, "size": 1, "hp": 170.0, "energy": 140.0, "silk": 120.0,
		"per_level": [9.0, 6.0, 6.0], "combo": [14.0, 14.0, 24.0], "bite": 12.0, "speed": 1.06, "hide": 0.8, "sight": 7.0,
		"venom": 2, "poison_immune": true, "trap_poison": true, "tint": Color(0.75, 0.1, 0.25),
		"pitch": "Rara de Veneno.",
		"desc": ["Golpes e mordida envenenam (2 doses por acerto).", "Imune a veneno.", "Teia de captura envenena quem prende."]},
	Form.CORROSIVA: {"icon": "drop", "name": "Corrosiva", "branch": "Rara", "rare": "Ácido", "scale": 1.1, "size": 1, "hp": 180.0, "energy": 130.0, "silk": 110.0,
		"per_level": [10.0, 6.0, 5.0], "combo": [15.0, 15.0, 26.0], "bite": 9.0, "speed": 1.04, "hide": 0.95, "sight": 7.0,
		"acid_immune": true, "corrode": 5.0, "trap_acid": 6.0, "tint": Color(0.55, 1.0, 0.2),
		"pitch": "Rara de Ácido.",
		"desc": ["Golpes corroem: o alvo leva +40% de dano por 5 s (até chefe de casca).", "Imune a ácido.", "Teia de captura derrete quem prende (6 PV/s)."]},
	Form.LUA: {"icon": "moon", "name": "Cavaleira de Pedra-da-lua", "branch": "Rara", "rare": "Pedra-da-lua", "scale": 1.2, "size": 1, "hp": 240.0, "energy": 140.0, "silk": 100.0,
		"per_level": [13.0, 6.0, 4.0], "combo": [17.0, 17.0, 30.0], "bite": 8.0, "speed": 1.0, "hide": 1.0, "sight": 8.0,
		"armor": 0.8, "shield": 50.0, "moonlight": true, "tint": Color(0.82, 0.9, 1.0),
		"pitch": "Rara de Pedra-da-lua.",
		"desc": ["Placas de pedra-da-lua: escudo de 50 que volta 6 s depois do último golpe.", "-20% de todo dano.", "A runa vira luar: ilumina 60% mais longe."]},
}

enum State { NORMAL, DODGE, BACKSTEP, ATTACK, BITE, ZIP, EAT, DEAD, SKILL }

# ---------------------------------------------------------------- recursos
var max_hp := 100.0
var hp := 100.0
var max_energy := 100.0
var energy := 100.0
var max_silk := 100.0
var silk := 100.0
var max_satiety := 100.0
var satiety := 100.0
var level := 1
var xp := 0
var form: Form = Form.FILHOTE
var pending_form := -1          ## ramo escolhido no casulo (faz a muda no próximo descanso)
var _mark: Node3D
var vis_scale := 1.0   ## tamanho do corpo na tela (a muda anima isso)
var bonus_hp := 0.0          ## vida, energia e seda ganhas com cristais e comida (sobrevivem à muda)
var bonus_energy := 0.0
var bonus_silk := 0.0
var resist_rot := 0
var resist_acid := 0            ## sobe comendo Sapo-de-rocha; 3 = atravessa as Poças ácidas
var resist_poison := 0          ## sobe comendo Escorpião-de-obsidiana; corta o veneno 25% por ponto
var poison_t := 0.0             ## envenenada: segundos de veneno ainda correndo
var dark_sight := 0.0           ## Resistência a Escuridão (Lago negro): + metros de visão no escuro
var resist_fire := 0            ## Resistência a Fogo: comer bichos de fogo (+1) e aguentar calor; 3 = anda na brasa
var heat_t := 0.0               ## > 0: está no calor agora (HUD mostra CALOR)
var heat_exposure := 0.0        ## segundos de calor aguentados (a cada 45 s: +1 de Resistência a Fogo, até 2)
var burn_t := 0.0               ## queimando (sopro de salamandra, mergulho do morcego de cinza)
var sight_penalty := 0.0        ## cinza no ar (Pântano de cinzas): metros a menos de visão
var daylight := 0.0             ## 0 a 1: luz do dia onde ela está (Portão): vê longe e é vista, com ou sem runa
var _day_check := 0.0
var weave_xp := 0               ## Tecelagem sobe tecendo fios: fios mais longos
const WEAVE_STEPS := [0, 8, 20, 36, 56]   ## fios tecidos para chegar em cada nível de Tecelagem (1 a 5)
var crystal_skin := false       ## Pele de Cristal (comer a Centopeia): -20% de dano
var kit: AttackKit = null      ## ataques próprios do ramo / forma final (troca golpe e mordida)
var attack_style := 0           ## formas finais: estilo A (0) ou B (1), escolhido no casulo
var veil_t := 0.0               ## escondida pela sombra (clone, nuvem de breu): ninguém vê
var leaping := false            ## no ar (bote aéreo): sem gravidade, passa por cima de buracos
var _kit_key := ""
var moonstones := 0             ## cristais de pedra-da-lua achados (forma rara Pedra-da-lua)
var shield := 0.0               ## escudo de pedra-da-lua (forma Lua): absorve dano e volta sozinho
var _shield_wait := 0.0
var _reveal_t := 0.0
var _reveal_marks: Array = []
var skills := {"fiandeira": true}   ## habilidades aprendidas no casulo (systems/skills.gd)
var skill_points := 0               ## 1 por nível; a muda não tira
var rune_shards := 0                ## fragmentos de runa achados; a cada RUNE_SHARDS_PER_POINT, +1 ponto
const RUNE_SHARDS_PER_POINT := 4
var bag: Array = []                 ## embrulhos na viagem [{"name", "sat", "silk"}] (a despensa fica na toca)
const BAG_MAX := 2
var dragged: Corpse = null          ## presa grande arrastada no fio até a toca
var eating_bag := false
var _drag_line: SilkLine
const DRAG_SPEED := 0.62            ## arrastando, anda a 62% (e faz mais barulho)
const SILK_WRAP := 10.0
const WRAP_RANGE := 8.0
var _dash_hit: Array = []
# golpes no estilo dos inimigos: marca no chão (cone/anel) que enche até o golpe
var _swing_marker: AttackMarker
var _swing: Attack = null
var _swing_t := -1.0
var _swing_hit := 0.1
var _swing_dir := Vector3.FORWARD
var _swing_cols := [Color(0.4, 0.85, 1.0, 0.12), Color(0.5, 0.9, 1.0, 0.4)]
const SWING_FADE := 0.18
const BITE_LUNGE_TIME := 0.16
const BITE_ASSIST := 2.6          ## a mordida avança até um bicho a esta distância (no cone da mira)
var _bite_dir := Vector3.FORWARD
var _bite_speed := 0.0
# fio do Q
var _silk: SilkLine = null
var _zip_wait := false
var _zip_dir := Vector3.FORWARD
var _zip_total := 1.0
var _spin := 0.0                    ## Corte em Espiral: o corpo dá uma volta inteira
const SPIN_TIME := 0.25
var rune_on := true
var dead := false
var in_territory := false
var on_strand := false

# ---------------------------------------------------------------- estado
var state: State = State.NORMAL
var state_time := 0.0
var combo_index := 0
var combo_queued := false
var hit_done := false
var invuln := 0.0
var energy_delay := 0.0
var external_velocity := Vector3.ZERO
var move_dir := Vector3.ZERO
var aim_dir := Vector3(0, 0, -1)
var aim_point := Vector3.ZERO
var action_dir := Vector3.ZERO
var zip_target := Vector3.ZERO
var eat_target: Corpse = null
var noise := 2.0
var last_safe_pos := Vector3.ZERO
var respawn_pos := Vector3.ZERO
## Já descansou num casulo desta camada: a morte volta para ele (os pontos de passagem
## das câmaras não mudam mais o lugar de voltar).
var rested_here := false
var using_stick_aim := false

var weaving := false
var weave_first: WebAnchor = null
var hovered_anchor: WebAnchor = null

var camera: Camera3D
## Cena: o jogo anda por você até auto_target (fuga do Berçário, chegada numa camada).
var autopilot := false
var auto_target := Vector3.ZERO
var auto_run := true
var cam_zoom := 0.0               ## > 0: tamanho de câmera forçado (cena)
var _shake := 0.0
var cam_focus := Vector3.ZERO      ## ponto que a câmera olha numa cena (aventureiros ao longe...)
var cam_focus_time := 0.0          ## segundos restantes olhando para cam_focus
var _preview: MeshInstance3D
var _preview_mat: StandardMaterial3D
var _last_real_us := 0
var _territory_timer := 0.0
var _safe_timer := 0.0
var _death_timer := 0.0
var _starve_msg_timer := 0.0
var _hurt_flash := 0.0
var _slow_mult := 1.0
var falling := false            ## caindo num abismo (a camada decide para onde)
var _sight_light: OmniLight3D   ## visão no escuro: não denuncia, só deixa ver em volta
var _slow_time := 0.0

# visual (formas cinza; troque por um modelo depois)
var _visual: Node3D
var _leg_rig: SpiderLegs
var _body_mat: StandardMaterial3D
var _rune_mat: StandardMaterial3D
var _rune_light: OmniLight3D
const RUNE_RANGE := 7.5   ## runa acesa ilumina longe (mas os bichos te veem); apagada, só a visão curta
var _scarf_tail: MeshInstance3D
var _abdomen: MeshInstance3D
var _plates: Array[MeshInstance3D] = []
var _hip_points: Array = []          ## encaixes das patas lidos do modelo do corpo
var _blades: Array[Node3D] = []      ## pivôs das 2 lâminas de cristal (só na forma Cavaleira)
var _blade_rest: Array[Vector3] = []
var _blade_tw: Array[Tween] = []
var _model_overlay: StandardMaterial3D


# ================================================================= setup

func _ready() -> void:
	var ear := AudioListener3D.new()   # os efeitos soam a partir dela, não da câmera lá em cima
	ear.name = "Ouvido"
	ear.position = Vector3(0, 1.0, 0)
	add_child(ear)
	ear.make_current.call_deferred()
	add_to_group("player")
	GameState.player = self
	collision_layer = 2
	collision_mask = 1 | 4 | 8
	floor_snap_length = 0.3
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.42
	cs.shape = shape
	cs.position.y = 0.42
	add_child(cs)
	_build_visual()
	_build_camera()
	_preview_mat = Fx.mat(Color(0.4, 1.0, 0.6), 2.0, true)
	_preview = Fx.box(Vector3(0.07, 0.07, 1.0), _preview_mat)
	_preview.top_level = true
	_preview.visible = false
	add_child(_preview)
	respawn_pos = global_position
	last_safe_pos = global_position
	aim_point = global_position + aim_dir * 3.0
	_last_real_us = Time.get_ticks_usec()
	recompute_stats(true)
	_apply_form_visual()


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_body_mat = Fx.mat(Color(0.16, 0.14, 0.38))
	var plate_mat := Fx.mat(Color(0.62, 0.66, 0.8), 0.15)

	var head := Fx.sphere(0.32, _body_mat)
	head.position = Vector3(0.0, 0.45, -0.18)
	_visual.add_child(head)
	_abdomen = Fx.sphere(0.42, _body_mat)
	_abdomen.position = Vector3(0.0, 0.55, 0.45)
	_visual.add_child(_abdomen)

	_rune_mat = Fx.mat(Color(0.3, 0.85, 1.0), 3.0, true)
	var rune := Fx.cylinder(0.2, 0.04, _rune_mat)
	rune.position = Vector3(0.0, 0.96, 0.48)
	_visual.add_child(rune)
	_rune_light = OmniLight3D.new()
	_rune_light.light_color = Color(0.4, 0.85, 1.0)
	_rune_light.omni_range = RUNE_RANGE
	_rune_light.light_energy = 1.4
	_rune_light.omni_attenuation = 0.6   # cai devagar: ilumina o salão em volta, não só o chão debaixo
	_rune_light.shadow_enabled = true
	_rune_light.position = Vector3(0.0, 1.6, 0.2)
	add_child(_rune_light)
	_sight_light = OmniLight3D.new()
	_sight_light.light_color = Color(0.62, 0.66, 0.85)
	_sight_light.light_energy = 0.9
	_sight_light.omni_range = 3.5
	_sight_light.omni_attenuation = 0.9
	_sight_light.shadow_enabled = false
	_sight_light.position = Vector3(0.0, 1.4, 0.0)
	add_child(_sight_light)

	var eye_mat := Fx.mat(Color(1.0, 0.65, 0.15), 1.5)
	for x in [-0.12, 0.12]:
		var eye := Fx.sphere(0.075, eye_mat)
		eye.position = Vector3(x, 0.52, -0.45)
		_visual.add_child(eye)
	var small_eye_mat := Fx.mat(Color(0.4, 0.9, 1.0), 2.0, true)
	for i in range(6):
		var e := Fx.sphere(0.03, small_eye_mat)
		e.position = Vector3(-0.1 + (i % 3) * 0.1, 0.66 + floorf(i / 3.0) * 0.05, -0.4)
		_visual.add_child(e)

	for p in [Vector3(-0.2, 0.72, -0.12), Vector3(0.2, 0.72, -0.12), Vector3(-0.22, 0.86, 0.42), Vector3(0.22, 0.86, 0.42)]:
		var plate := Fx.box(Vector3(0.2, 0.06, 0.26), plate_mat)
		plate.position = p
		plate.rotation.z = -0.5 * signf(p.x)
		_visual.add_child(plate)
		_plates.append(plate)

	_apply_model([head, _abdomen, rune])

	var scarf_mat := Fx.mat(Color(0.6, 0.72, 0.95), 0.3)
	var scarf := Fx.box(Vector3(0.52, 0.07, 0.14), scarf_mat)
	scarf.position = Vector3(0.0, 0.6, 0.02)
	_visual.add_child(scarf)
	_scarf_tail = Fx.box(Vector3(0.12, 0.04, 1.0), scarf_mat)
	_scarf_tail.position = Vector3(0.12, 0.66, 0.5)
	_visual.add_child(_scarf_tail)
	if Models.has("cavaleira_corpo"):
		scarf.visible = false   # o cachecol de caixas atravessava o modelo
		_scarf_tail.visible = false

	# 8 patas com IK procedural (systems/spider_legs.gd); refeitas na muda (tamanho novo)
	_build_legs(1.0)


func _build_legs(sz: float) -> void:
	if _leg_rig != null and is_instance_valid(_leg_rig):
		_leg_rig.queue_free()
	_leg_rig = SpiderLegs.new()
	_leg_rig.setup(_visual, sz, 1 | 8)
	_leg_rig.root = self
	_leg_rig.hip_points = _hip_points
	_leg_rig.segment_model = "cavaleira_pata"
	add_child(_leg_rig)


# ================================================================= forma e evolução

func form_data() -> Dictionary:
	return FORMS[form]


func form_name() -> String:
	return String(form_data()["name"])


func body_size() -> int:
	## 0 = P (Filhote), 1 = M (Cavaleira): predadores maiores que você te caçam.
	return int(form_data()["size"])


func can_evolve() -> bool:
	return (form == Form.FILHOTE and level >= EVOLVE_LEVEL) or ((can_choose_branch() or can_choose_final()) and pending_form >= 0)


func can_choose_branch() -> bool:
	return form == Form.CAVALEIRA and level >= BRANCH_LEVEL


func can_choose_final() -> bool:
	## A última muda: no nível FINAL_LEVEL de um ramo.
	return is_branch() and level >= FINAL_LEVEL


func choose_branch(f: int) -> bool:
	## Escolhe a próxima forma no casulo (o ramo, ou a forma final / rara).
	if can_choose_branch() and BRANCHES.has(f):
		pending_form = f
		return true
	if can_choose_final() and next_options().has(f) and rare_ready(f):
		pending_form = f
		return true
	return false


func next_options() -> Array:
	## As formas que a última muda pode dar a partir do ramo atual: as duas do ramo + as raras.
	if not is_branch():
		return []
	var out: Array = (FINALS[form] as Array).duplicate()
	out.append_array(RARES)
	return out


func rare_requirements(f: int) -> Array:
	## [[texto, cumprido], ...] de uma forma rara (as do ramo não têm requisito).
	match f:
		Form.ARDENTE:
			return [["Resistência a Fogo 5 (%d)" % resist_fire, resist_fire >= 5],
				["Cristal de fogo (Rio de Brasa)", bool(GameState.flags.get("material_cristal_fogo", false))]]
		Form.BREU:
			return [["Pérola negra do Lago negro (Abismo)", dark_sight >= 1.5],
				["Resistência à Podridão 3 (%d)" % resist_rot, resist_rot >= 3]]
		Form.VIUVA:
			return [["Resistência a Veneno 4 (%d)" % resist_poison, resist_poison >= 4]]
		Form.CORROSIVA:
			return [["Resistência a Ácido 5 (%d)" % resist_acid, resist_acid >= 5]]
		Form.LUA:
			return [["Pele de Cristal (comer a Centopeia)", crystal_skin],
				["Cristais de pedra-da-lua: %d / %d" % [mini(moonstones, MOONSTONES_NEEDED), MOONSTONES_NEEDED], moonstones >= MOONSTONES_NEEDED]]
	return []


func rare_ready(f: int) -> bool:
	for r in rare_requirements(f):
		if not bool(r[1]):
			return false
	return true


func is_branch() -> bool:
	return BRANCHES.has(form)


func is_final() -> bool:
	return int(form) >= int(Form.EXECUTORA)


func tier() -> int:
	## 0 Filhote, 1 Cavaleira, 2 ramo, 3 forma final ou rara.
	if form == Form.FILHOTE:
		return 0
	if form == Form.CAVALEIRA:
		return 1
	return 2 if is_branch() else 3


func branch_name() -> String:
	return String(form_data().get("branch", ""))


func fd(key: String, default: Variant = null) -> Variant:
	## Atalho para as marcas da forma atual (execute, thorns, fireproof...).
	return form_data().get(key, default)


func _levels_before() -> int:
	## Níveis já vividos nas formas anteriores (para devolver pontos de habilidade).
	match tier():
		0:
			return 0
		1:
			return EVOLVE_LEVEL - 1
		2:
			return (EVOLVE_LEVEL - 1) + (BRANCH_LEVEL - 1)
	return (EVOLVE_LEVEL - 1) + (BRANCH_LEVEL - 1) + (FINAL_LEVEL - 1)


func recompute_stats(refill: bool) -> void:
	var f := form_data()
	var per: Array = f["per_level"]
	max_hp = (float(f["hp"]) + float(per[0]) * (level - 1)) * (float(HP_MULT[clampi(tier(), 0, 3)]) if balanced else 1.0) + bonus_hp
	max_energy = float(f["energy"]) + float(per[1]) * (level - 1) + bonus_energy
	max_silk = float(f["silk"]) + float(per[2]) * (level - 1) + bonus_silk
	if refill:
		hp = max_hp
		energy = max_energy
		silk = max_silk
	else:
		hp = minf(hp, max_hp)
		energy = minf(energy, max_energy)
		silk = minf(silk, max_silk)
	refresh_kit()


func refresh_kit() -> void:
	## Troca o kit de ataques quando a forma (ou o estilo) muda.
	var key := "%d/%d" % [int(form), attack_style]
	if key == _kit_key and (kit != null or KitBook.styles(form) == 0):
		return
	_kit_key = key
	if kit != null:
		if state == State.SKILL:
			_start_state(State.NORMAL)
		kit.queue_free()
		kit = null
	kit = KitBook.make(int(form), attack_style)
	if kit != null:
		add_child(kit)
		kit.setup(self)


func set_attack_style(s: int) -> void:
	attack_style = clampi(s, 0, 1)
	refresh_kit()

func add_bonus(hp_: float, energy_: float, silk_: float = 0.0) -> void:
	bonus_hp += hp_
	bonus_energy += energy_
	bonus_silk += silk_
	max_hp += hp_
	max_energy += energy_
	max_silk += silk_
	hp = minf(max_hp, hp + hp_)
	energy = minf(max_energy, energy + energy_)
	silk = minf(max_silk, silk + silk_)


func _apply_form_visual() -> void:
	var k := float(form_data()["scale"])
	vis_scale = k
	_visual.scale = Vector3.ONE * k
	if _leg_rig == null or not is_equal_approx(_leg_rig.size, k):
		_build_legs(k)
	_rune_light.omni_range = rune_range()
	_sight_light.omni_range = sight_radius()
	_update_blades_visible()
	_build_mark()


func evolve() -> void:
	## A muda no casulo: Filhote -> Cavaleira de Seda; Cavaleira -> o ramo escolhido.
	if form != Form.FILHOTE:
		_evolve_branch()
		return
	form = Form.CAVALEIRA
	level = 1
	xp = 0
	recompute_stats(true)
	var tw := create_tween()
	tw.tween_property(self, "vis_scale", float(form_data()["scale"]), 1.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_build_legs(float(form_data()["scale"]))
	_update_blades_visible()
	_rune_light.omni_range = RUNE_RANGE
	_sight_light.omni_range = sight_radius()
	_build_mark()
	EventBus.big_message.emit("Evolução: Cavaleira de Seda!")
	_msg("A muda terminou. Lâminas de cristal, placas novas e muito mais vida. O nível voltou a 1.")
	GameState.say_once("evolucao_1", "Eu... cresci? Lâminas! Eu tenho LÂMINAS! Ok, caverna. Agora a conversa é outra.")


func _evolve_branch() -> void:
	if pending_form < 0:
		return
	form = pending_form as Form
	pending_form = -1
	level = 1
	xp = 0
	recompute_stats(true)
	var tw := create_tween()
	tw.tween_property(self, "vis_scale", float(form_data()["scale"]), 1.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_build_legs(float(form_data()["scale"]))
	_update_blades_visible()
	_rune_light.omni_range = rune_range()
	_sight_light.omni_range = sight_radius()
	_build_mark()
	shield = float(fd("shield", 0.0))
	EventBus.big_message.emit("Evolução: %s!" % form_name())
	Music.stinger("evolucao")
	Sfx.play("pc_muda_casca", global_position)
	_msg("A muda terminou: %s. O nível voltou a 1." % form_name() + (" Esta é a última muda." if is_final() else ""))
	match form:
		Form.LAMINA:
			GameState.say_once("evolucao_lamina", "Foices. Eu tenho FOICES. Tudo que me olhou torto, pode vir.")
		Form.TEIA:
			GameState.say_once("evolucao_teia", "Seda saindo de tudo quanto é lugar. O Abismo inteiro vai ser minha teia.")
		Form.RUNA:
			GameState.say_once("evolucao_runa", "A runa tá... cantando? Eu enxergo tudo. E ninguém me enxerga.")
		Form.EXECUTORA:
			GameState.say_once("evolucao_final", "Foices do tamanho de mim. Se correr, eu alcanço. Se ficar, eu corto.")
		Form.BASTIA:
			GameState.say_once("evolucao_final", "Pedra por fora, pedra por dentro. Pode bater. Vai doer em você.")
		Form.SENHORA:
			GameState.say_once("evolucao_final", "Cada fio é meu. Cada teia é uma porta trancada. Bem-vindos à minha casa.")
		Form.SALTADORA:
			GameState.say_once("evolucao_final", "Eu não ando mais. Eu VOO. De fio em fio, e caio em cima.")
		Form.VIDENTE:
			GameState.say_once("evolucao_final", "Estou vendo vocês. Atrás da pedra, no teto, no escuro. Todos.")
		Form.TEMPESTADE:
			GameState.say_once("evolucao_final", "A runa trovejou. Acho que agora ela é mais arma do que lanterna.")
		Form.ARDENTE:
			GameState.say_once("evolucao_final", "Eu sou a brasa agora. Tochas? Fofinho.")
		Form.BREU:
			GameState.say_once("evolucao_final", "Parada, eu sou o escuro. E o escuro morde.")
		Form.VIUVA:
			GameState.say_once("evolucao_final", "Uma mordida e acabou. Eles só não sabem ainda.")
		Form.CORROSIVA:
			GameState.say_once("evolucao_final", "Couraça, escudo, casca... tudo derrete igual.")
		Form.LUA:
			GameState.say_once("evolucao_final", "As placas do cristal. A silhueta da Fresta... era eu. Sempre fui eu.")


func rune_range() -> float:
	return RUNE_RANGE * maxf(float(form_data()["scale"]), 0.8) * (1.6 if fd("moonlight", false) else 1.0)


func _build_mark() -> void:
	## A marca da forma no corpo: crista vermelha (Lâmina), manto de seda (Teia), halo (Runa).
	## As formas finais mantêm a marca do ramo e ganham mais uma; as raras têm marca própria.
	if _mark != null:
		_mark.queue_free()
		_mark = null
	_rune_light.light_color = Color(0.4, 0.85, 1.0)
	if tier() < 2 or _visual == null:
		return
	_mark = Node3D.new()
	_visual.add_child(_mark)
	var tint: Color = form_data().get("tint", Color.WHITE)
	var base := int(fd("parent", form))
	var own := tint
	if base != int(form):
		tint = (FORMS[base]["tint"] as Color).lerp(own, 0.5)   # a marca do ramo, puxando para a cor nova
	match base:
		Form.LAMINA:
			for k in 5:
				var sp := Fx.cylinder(0.07, 0.55 - absf(k - 2) * 0.08, Fx.mat(tint, 2.2))
				(sp.mesh as CylinderMesh).top_radius = 0.005
				sp.position = Vector3(0, 0.95, -0.15 + k * 0.2)
				sp.rotation.x = 0.45
				_mark.add_child(sp)
		Form.TEIA:
			var cape := Fx.box(Vector3(0.85, 0.02, 1.0), Fx.mat(tint, 0.8, true, 0.6))
			cape.position = Vector3(0, 0.95, 0.45)
			cape.rotation.x = 0.3
			_mark.add_child(cape)
			for k in 5:
				var th := Fx.box(Vector3(0.015, 0.015, 1.05), Fx.mat(tint, 1.4, true))
				th.position = Vector3(-0.36 + k * 0.18, 0.97, 0.45)
				th.rotation.x = 0.3
				_mark.add_child(th)
		Form.RUNA:
			_mark.add_child(_halo(tint, 0.22, Vector3(0, 1.15, 0.1)))
			_rune_light.light_color = tint.lightened(0.1)
	tint = own
	match form:
		Form.EXECUTORA:
			for side in [-1.0, 1.0]:
				var hook := Fx.cylinder(0.05, 0.9, Fx.mat(tint, 2.6))
				(hook.mesh as CylinderMesh).top_radius = 0.004
				hook.position = Vector3(side * 0.42, 0.75, -0.55)
				hook.rotation = Vector3(-1.0, 0.0, side * 0.5)
				_mark.add_child(hook)
		Form.BASTIA:
			for k in 4:
				for side in [-1.0, 1.0]:
					var plate := Fx.box(Vector3(0.24, 0.06, 0.2), Fx.mat(tint.darkened(0.45), 0.0))
					plate.position = Vector3(side * 0.2, 0.9 + k * 0.02, 0.05 + k * 0.17)
					plate.rotation = Vector3(0.15, 0.0, side * 0.35)
					_mark.add_child(plate)
		Form.SENHORA:
			var crown := _halo(tint, 0.3, Vector3(0, 1.2, 0.35))
			crown.rotation.x = 1.2
			_mark.add_child(crown)
		Form.SALTADORA:
			for side in [-1.0, 1.0]:
				var wing := Fx.box(Vector3(0.9, 0.015, 0.45), Fx.mat(tint, 1.2, true, 0.45))
				wing.position = Vector3(side * 0.6, 0.98, 0.3)
				wing.rotation = Vector3(0.2, side * 0.35, side * 0.25)
				_mark.add_child(wing)
		Form.VIDENTE:
			for k in 3:
				var eye := Fx.sphere(0.06, Fx.mat(tint, 4.0, true))
				eye.position = Vector3(-0.14 + k * 0.14, 0.85, -0.52)
				_mark.add_child(eye)
		Form.TEMPESTADE:
			_mark.add_child(_halo(tint.lightened(0.3), 0.34, Vector3(0, 1.32, 0.1)))
		Form.ARDENTE:
			for k in 6:
				var fl := Fx.cylinder(0.08, 0.42 + fposmod(k * 0.37, 0.3), Fx.mat(tint, 3.2, true, 0.8))
				(fl.mesh as CylinderMesh).top_radius = 0.0
				fl.position = Vector3(-0.3 + (k % 3) * 0.3, 1.05, -0.1 + floori(k / 3.0) * 0.45)
				_mark.add_child(fl)
			_rune_light.light_color = Color(1.0, 0.55, 0.2)
		Form.BREU:
			var veil := Fx.box(Vector3(0.75, 0.02, 0.85), Fx.mat(tint, 0.3, true, 0.4))
			veil.position = Vector3(0, 0.99, 0.35)
			_mark.add_child(veil)
			_rune_light.light_color = Color(0.6, 0.45, 1.0)
		Form.VIUVA:
			var hg := Fx.box(Vector3(0.22, 0.03, 0.22), Fx.mat(tint, 3.0))
			hg.position = Vector3(0, 1.0, 0.45)
			hg.rotation.y = PI * 0.25
			_mark.add_child(hg)
			_rune_light.light_color = Color(1.0, 0.3, 0.4)
		Form.CORROSIVA:
			for k in 5:
				var drip := Fx.sphere(0.08, Fx.mat(tint, 2.4, true, 0.85))
				drip.position = Vector3(-0.3 + k * 0.15, 0.93, 0.1 + fposmod(k * 0.53, 0.5))
				_mark.add_child(drip)
			_rune_light.light_color = Color(0.6, 1.0, 0.3)
		Form.LUA:
			for k in 6:
				var pl := Fx.box(Vector3(0.2, 0.04, 0.16), Fx.mat(tint.darkened(0.2), 0.25))
				pl.position = Vector3(-0.22 + (k % 3) * 0.22, 0.97, 0.15 + floori(k / 3.0) * 0.3)
				pl.rotation.y = 0.785
				_mark.add_child(pl)
			_mark.add_child(_halo(tint, 0.2, Vector3(0, 1.2, 0.0)))
			_rune_light.light_color = Color(0.85, 0.92, 1.0)


func _halo(tint: Color, r: float, at: Vector3) -> MeshInstance3D:
	var halo := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r
	tm.outer_radius = r + 0.04
	halo.mesh = tm
	halo.material_override = Fx.mat(tint, 3.0, true)
	halo.position = at
	return halo


func _apply_model(base_parts: Array) -> void:
	## Com o modelo do corpo (assets/models/cavaleira_corpo), as formas cinza do corpo somem.
	## Patas e cachecol continuam por código. A luz da runa continua acendendo e apagando.
	var parts := base_parts.duplicate()
	for c in _visual.get_children():
		if c is MeshInstance3D and not parts.has(c):
			parts.append(c)
	var m := Models.swap(_visual, "cavaleira_corpo", 1.4, parts, "length")
	if m == null:
		return
	m.position.y = 0.15
	# encaixes das patas (leg_socket_L1..R4) vêm do modelo: as patas saem do lugar certo
	_hip_points.clear()
	for side in ["L", "R"]:
		for k in range(1, 5):
			var t = Models.node_xform(m, "leg_socket_%s%d" % [side, k])
			if t == null:
				_hip_points.clear()
				break
			_hip_points.append(m.transform * (t as Transform3D).origin)
		if _hip_points.is_empty():
			break
	if _hip_points.size() == 8:
		_hip_points = _hip_points.slice(0, 4) + _hip_points.slice(4, 8)
		# o rig conta "lado -1" primeiro: garante que os 4 primeiros são os de X negativo
		if (_hip_points[0] as Vector3).x > 0.0:
			_hip_points = _hip_points.slice(4, 8) + _hip_points.slice(0, 4)
	_build_blades()
	_plates.clear()
	_model_overlay = StandardMaterial3D.new()
	_model_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_model_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_model_overlay.albedo_color = Color(1.0, 0.2, 0.2, 0.0)
	Models.set_overlay(m, _model_overlay)


func _build_blades() -> void:
	## As duas lâminas de cristal (assets/models/cavaleira_lamina): presas na frente do
	## corpo, acima do primeiro par de patas, apontadas para a frente como foices.
	## Só aparecem na Cavaleira (o Filhote ainda não tem lâminas).
	for b in _blades:
		b.queue_free()
	_blades.clear()
	_blade_rest.clear()
	if not Models.has("cavaleira_lamina"):
		return
	for side in [-1.0, 1.0]:
		var m := Models.raw("cavaleira_lamina")
		var attach = Models.node_xform(m, "attach_point")
		var at := Vector3(0.0, 0.17, 0.0) if attach == null else (attach as Transform3D).origin
		var pivot := Node3D.new()
		pivot.name = "Lamina_" + ("E" if side < 0.0 else "D")
		var spin := Node3D.new()
		spin.rotation.y = PI * 0.5            # fio da lâmina na vertical (corta de lado)
		pivot.add_child(spin)
		var sc := 1.7
		m.scale = Vector3.ONE * sc
		m.position = -at * sc                 # o ponto de encaixe fica no pivô; a lâmina desce dele
		spin.add_child(m)
		var hip := Vector3(0.2 * side, 0.3, -0.5)
		if _hip_points.size() == 8:
			hip = _hip_points[0 if side < 0.0 else 4]
		pivot.position = Vector3(hip.x * 0.8, hip.y + 0.22, hip.z - 0.05)
		var rest := Vector3(deg_to_rad(62.0), -side * 0.32, side * 0.12)
		pivot.rotation = rest
		_visual.add_child(pivot)
		_blades.append(pivot)
		_blade_rest.append(rest)
	_update_blades_visible()


func _update_blades_visible() -> void:
	for b in _blades:
		b.visible = form != Form.FILHOTE


func _swing_blades(index: int) -> void:
	## Golpe do combo: 1º lâmina direita varre, 2º a esquerda, 3º as duas descem juntas.
	if _blades.size() < 2 or form == Form.FILHOTE:
		return
	for tw in _blade_tw:
		if tw.is_valid():
			tw.kill()
	_blade_tw.clear()
	for i in 2:
		_blades[i].rotation = _blade_rest[i]
	var who: Array = [1] if index == 0 else ([0] if index == 1 else [0, 1])
	for i in who:
		var side := -1.0 if i == 0 else 1.0
		var r: Vector3 = _blade_rest[i]
		var wind := r + Vector3(-0.5, -side * 0.5, 0.0)
		var cut := r + Vector3(0.35, side * 1.1, -side * 0.3)
		if index == 2:
			wind = r + Vector3(-0.9, -side * 0.15, 0.0)
			cut = r + Vector3(0.55, side * 0.25, 0.0)
		var tw := create_tween()
		tw.tween_property(_blades[i], "rotation", wind, 0.07)
		tw.tween_property(_blades[i], "rotation", cut, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_blades[i], "rotation", r, 0.22).set_delay(0.05)
		_blade_tw.append(tw)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 18.0
	camera.near = 0.1
	camera.far = 200.0
	camera.top_level = true
	camera.rotation_degrees = Vector3(-55.0, 0.0, 0.0)
	add_child(camera)
	camera.current = true
	snap_camera()


func snap_camera() -> void:
	_update_camera(1.0, true)


# ================================================================= loop

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		using_stick_aim = false


func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_dt := clampf((now - _last_real_us) / 1000000.0, 0.0, 0.1)
	_last_real_us = now
	_update_aim()
	_handle_weave(real_dt)
	_leg_rig.curled = dead
	_update_visual(delta)
	_update_camera(real_dt, false)
	if Input.is_action_just_pressed("debug_level") and not dead:
		gain_xp(xp_to_next() - xp)


func _physics_process(delta: float) -> void:
	_update_resources(delta)
	_day_check -= delta
	if _day_check <= 0.0:
		_day_check = 0.15
		var lyr = GameState.current_layer
		var want := float(lyr.daylight_at(global_position)) if lyr != null and lyr.has_method("daylight_at") else 0.0
		if absf(want - daylight) > 0.02:
			daylight = move_toward(daylight, want, 0.25)
			refresh_sight()
	_update_drag(delta)
	if dead:
		_death_timer -= delta
		if _death_timer <= 0.0:
			var layer = GameState.current_layer
			if GameState.permadeath and layer != null and layer.has_method("restart_act"):
				_death_timer = INF   # uma vez só
				layer.restart_act()
			elif layer != null and layer.has_method("respawn_player"):
				_death_timer = INF
				layer.respawn_player(self)   # escurece, acorda no casulo, clareia
			else:
				_respawn()
		return
	invuln = maxf(invuln - delta, 0.0)
	_slow_time = maxf(_slow_time - delta, 0.0)
	state_time += delta
	veil_t = maxf(veil_t - delta, 0.0)
	if kit != null:
		kit.tick(delta)

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if autopilot:
		var to := auto_target - global_position
		to.y = 0.0
		input = Vector2(to.x, to.z).normalized() if to.length() > 0.35 else Vector2.ZERO
	move_dir = Vector3(input.x, 0.0, input.y)
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()
	on_strand = WebNetwork.strand_near(global_position, 0.65) != null

	var horizontal := Vector3.ZERO
	match state:
		State.NORMAL:
			horizontal = _state_normal()
		State.DODGE:
			horizontal = _state_dodge()
		State.BACKSTEP:
			horizontal = _state_backstep()
		State.ATTACK:
			horizontal = _state_attack()
		State.BITE:
			horizontal = _state_bite()
		State.EAT:
			horizontal = _state_eat()
		State.SKILL:
			horizontal = kit.state_update(delta) if kit != null else Vector3.ZERO
			if kit == null:
				_start_state(State.NORMAL)
		State.ZIP:
			_state_zip()
			_check_fall_and_safe(delta)
			return

	velocity.x = horizontal.x + external_velocity.x
	velocity.z = horizontal.z + external_velocity.z
	if leaping:
		velocity.y = 0.0
	elif is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= GRAVITY * delta
	external_velocity = external_velocity.move_toward(Vector3.ZERO, 25.0 * delta)
	move_and_slide()
	_step_sounds(delta)
	_check_fall_and_safe(delta)


var _stride := 0.0


func _step_sounds(_delta: float) -> void:
	## Passinhos: um toque a cada passada (mais fracos com a runa apagada).
	if not is_on_floor() or leaping or on_strand or dead:
		return
	var v := Vector2(velocity.x, velocity.z).length()
	if v < 0.6:
		return
	_stride += v * get_physics_process_delta_time()
	var step := 0.55 * float(form_data()["scale"])
	if _stride >= step:
		_stride = 0.0
		Sfx.play("pc_passo", global_position, -2.0 if rune_on else -8.0, 0.12, 0.05)


func _start_state(s: State) -> void:
	# sair de um estado no meio (tomou dano, caiu, etc.) não pode deixar nada para trás
	if state == State.DODGE and s != State.DODGE:
		collision_mask = 1 | 4 | 8   # Investida: volta a colidir com os bichos
	if state == State.ZIP and s != State.ZIP:
		_visual.position.y = 0.0
		_zip_wait = false
		_release_silk_later(0.0)
	if state == State.SKILL and s != State.SKILL and kit != null and kit.busy():
		kit.cancel()
	if state == State.SKILL and s != State.SKILL:
		leaping = false
		if _visual != null:
			_visual.position.y = 0.0
	if state == State.EAT and s != State.EAT and eating_bag:
		eating_bag = false
		if state_time < 1.2:
			_msg("Interrompida: o embrulho ficou para depois.")
	state = s
	state_time = 0.0
	hit_done = false


# ================================================================= estados

func _state_normal() -> Vector3:
	var running := (auto_run if autopilot else Input.is_action_pressed("run")) and move_dir.length() > 0.1
	var spd := (RUN_SPEED if running else WALK_SPEED) * float(form_data()["speed"])
	if _slow_time > 0.0:
		spd *= _slow_mult
	if on_strand:
		spd *= (1.8 if has_skill("passos") else STRAND_SPEED_MULT) * float(form_data().get("strand_speed", 1.0))
	if satiety <= 0.0:
		spd *= 0.8
	if dragged != null:
		spd *= DRAG_SPEED
	if move_dir.length() > 0.1:
		if on_strand:
			noise = 0.0
		else:
			noise = 8.0 if running else 2.5
	else:
		noise = 0.5
	if dragged != null:
		noise += 3.0   # o corpo raspando no chão
	if autopilot:
		return move_dir * spd   # cena: sem golpes nem teclas

	if Input.is_action_just_pressed("dodge"):
		_try_dodge()
	elif Input.is_action_just_pressed("throw_silk"):
		_throw_silk()
	elif not weaving:
		if Input.is_action_just_pressed("attack"):
			if kit != null:
				kit.press(0)
			else:
				_start_attack(0)
		elif Input.is_action_just_pressed("bite"):
			if kit != null:
				kit.press(1)
			else:
				_start_bite()
		elif Input.is_action_just_pressed("interact"):
			_interact()
	if Input.is_action_just_pressed("rune"):
		_toggle_rune()
	if Input.is_action_just_pressed("cocoon"):
		_context_weave()
	if Input.is_action_just_pressed("eat"):
		eat_from_bag()
	return move_dir * spd


func _try_dodge() -> void:
	if move_dir.length() > 0.2:
		var cost := DODGE_COST * float(fd("dodge_cost", 1.0))
		if energy < cost:
			_msg("Sem energia para esquivar.")
			return
		energy -= cost
		energy_delay = 1.0
		Sfx.play("pc_esquiva", global_position)
		action_dir = move_dir.normalized()
		invuln = DODGE_INVULN + float(fd("dodge_bonus", 0.0))
		_dash_hit.clear()
		if has_skill("investida"):
			collision_mask = 1 | 8   # atravessa os bichos durante a esquiva
		_start_state(State.DODGE)
	else:
		if energy < BACKSTEP_COST:
			_msg("Sem energia para o backstep.")
			return
		energy -= BACKSTEP_COST
		energy_delay = 1.0
		action_dir = -aim_dir
		_start_state(State.BACKSTEP)


func _state_dodge() -> Vector3:
	noise = 3.0
	if has_skill("investida"):
		for n in get_tree().get_nodes_in_group("creature"):
			var c := n as Creature
			if c == null or c.dead or _dash_hit.has(c):
				continue
			if Fx.flat_dist(c.global_position, global_position) <= 1.0 + c.body_radius and absf(c.global_position.y - global_position.y) < 1.3:
				_dash_hit.append(c)
				c.take_damage(8.0, self)
	if state_time >= DODGE_TIME:
		collision_mask = 1 | 4 | 8
		_start_state(State.NORMAL)
	return action_dir * DODGE_SPEED


func _state_backstep() -> Vector3:
	noise = 2.0
	if state_time >= BACKSTEP_TIME:
		_start_state(State.NORMAL)
	return action_dir * BACKSTEP_SPEED


func _start_attack(index: int) -> void:
	combo_index = index
	combo_queued = false
	_start_state(State.ATTACK)
	_swing_blades(index)
	Sfx.play("pc_garra_pesada" if index == 2 else "pc_garra", global_position, 0.0, 0.1, 0.02)
	var reach := ATTACK_RANGE * float(form_data()["scale"]) + 0.3
	if index == 2 and _spiral_ready():
		_begin_swing(Attack.make("espiral", "", {"shape": Attack.Shape.RING, "reach": reach + 0.5}), 0.1, aim_dir, false)
	else:
		_begin_swing(Attack.make("golpe", "", {"shape": Attack.Shape.CONE, "reach": reach, "arc": ATTACK_ARC}), 0.1, aim_dir, false)


func _start_bite() -> void:
	## Mordida: micro-avanço. Se houver um bicho perto na mira, avança até encostar nele.
	_start_state(State.BITE)
	Sfx.play("pc_mordida", global_position)
	_bite_dir = aim_dir
	var dist := 0.6
	var best := BITE_ASSIST
	for n in get_tree().get_nodes_in_group("creature"):
		var c := n as Creature
		if c == null or c.dead or c.global_position.y - global_position.y > 1.3:
			continue
		var to := c.global_position - global_position
		to.y = 0.0
		var d := to.length() - c.body_radius
		if d > best or to.length() < 0.05:
			continue
		if rad_to_deg(aim_dir.angle_to(to.normalized())) > 40.0:
			continue
		best = d
		_bite_dir = to.normalized()
		dist = clampf(d - 0.35, 0.0, 1.6)
	_bite_speed = dist / BITE_LUNGE_TIME
	_begin_swing(Attack.make("mordida", "", {"shape": Attack.Shape.CONE, "reach": BITE_RANGE, "arc": 70.0}), 0.2, _bite_dir, true)


func _begin_swing(a: Attack, hit_time: float, dir: Vector3, poison: bool) -> void:
	if _swing_marker == null:
		_swing_marker = AttackMarker.new()
		add_child(_swing_marker)
	_swing = a
	_swing_t = 0.0
	_swing_hit = hit_time
	_swing_dir = dir
	_swing_cols = [Color(0.45, 1.0, 0.45, 0.12), Color(0.55, 1.0, 0.5, 0.42)] if poison else [Color(0.4, 0.85, 1.0, 0.12), Color(0.5, 0.9, 1.0, 0.4)]


func _update_swing(delta: float) -> void:
	if _swing_t < 0.0 or _swing_marker == null:
		return
	_swing_t += delta
	var fill := clampf(_swing_t / _swing_hit, 0.0, 1.0)
	var fade := 1.0 - clampf((_swing_t - _swing_hit) / SWING_FADE, 0.0, 1.0)
	if fade <= 0.0:
		_swing_t = -1.0
		_swing_marker.clear()
		return
	var b: Color = _swing_cols[0]
	var h: Color = _swing_cols[1]
	_swing_marker.draw_shape(_swing, global_position, _swing_dir, global_position, fill,
		Color(b.r, b.g, b.b, b.a * fade), Color(h.r, h.g, h.b, h.a * fade * (1.6 if _swing_t >= _swing_hit else 1.0)))


func _state_attack() -> Vector3:
	noise = 6.0
	if Input.is_action_just_pressed("attack") and not weaving:
		combo_queued = true
	if Input.is_action_just_pressed("dodge"):
		_try_dodge()
		return Vector3.ZERO
	if not hit_done and state_time >= 0.1:
		hit_done = true
		var dmg := float((form_data()["combo"] as Array)[combo_index]) * (1.25 if has_skill("afiadas") else 1.0)
		var reach := ATTACK_RANGE * float(form_data()["scale"]) + 0.3
		if combo_index == 2 and _spiral_ready():
			_spiral_fx(reach + 0.5)
			_melee(dmg, reach + 0.5, 360.0, false, _swing_dir)
		else:
			_melee(dmg, reach, ATTACK_ARC, false, _swing_dir)
	if state_time >= ATTACK_TIME:
		if combo_queued and combo_index < 2:
			_start_attack(combo_index + 1)
		else:
			_start_state(State.NORMAL)
	var lunge := 3.0 if state_time < 0.12 else 0.0
	return _swing_dir * lunge + move_dir * 1.5


func _zip_land() -> void:
	## Saltadora do Vento: chegar de um fio lançado é um mergulho (dano + atordoa em volta).
	var dmg := float(fd("dive", 0.0))
	if dmg <= 0.0 or _zip_total < 3.0:
		return
	var hit := 0
	for n in get_tree().get_nodes_in_group("creature"):
		var c := n as Creature
		if c == null or c.dead or absf(c.global_position.y - global_position.y) > 1.5:
			continue
		if Fx.flat_dist(c.global_position, global_position) <= 2.5 + c.body_radius:
			c.take_damage(dmg * power(), self)
			if not c.dead and not c.is_in_group("boss"):
				c.entangle_raw(1.2)
			hit += 1
	if hit > 0:
		_spiral_fx(2.5)
		shake(0.25)
		_msg("Mergulho! (%d)" % hit)


func _update_reveal(delta: float) -> void:
	## Vidente da Runa: marca os bichos por perto, mesmo atrás das paredes.
	var r := float(fd("reveal", 0.0))
	if r <= 0.0:
		if not _reveal_marks.is_empty():
			for m in _reveal_marks:
				if is_instance_valid(m):
					m.queue_free()
			_reveal_marks.clear()
		return
	_reveal_t -= delta
	if _reveal_t > 0.0:
		return
	_reveal_t = 0.2
	var seen: Array = []
	for n in get_tree().get_nodes_in_group("creature"):
		var c := n as Creature
		if c != null and not c.dead and Fx.flat_dist(c.global_position, global_position) <= r:
			seen.append(c)
	seen.sort_custom(func(a, b): return Fx.flat_dist(a.global_position, global_position) < Fx.flat_dist(b.global_position, global_position))
	seen = seen.slice(0, 16)
	while _reveal_marks.size() < seen.size():
		var m := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.45
		tm.outer_radius = 0.55
		m.mesh = tm
		var mat := Fx.mat(Color(1.0, 0.9, 0.5), 2.5, true, 0.7)
		mat.no_depth_test = true
		mat.render_priority = 10
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(m)
		_reveal_marks.append(m)
	for i in _reveal_marks.size():
		var m: MeshInstance3D = _reveal_marks[i]
		if not is_instance_valid(m):
			continue
		m.visible = i < seen.size()
		if m.visible:
			var c: Creature = seen[i]
			m.global_position = c.global_position + Vector3(0, 0.15, 0)
			m.scale = Vector3.ONE * clampf(c.body_radius * 1.6, 0.6, 3.0)
			var threat := c.is_in_group("boss") or c.noticed_player
			(m.material_override as StandardMaterial3D).albedo_color = Color(1.0, 0.35, 0.3, 0.8) if threat else Color(1.0, 0.9, 0.5, 0.6)


func _spiral_ready() -> bool:
	return has_skill("espiral") and form != Form.FILHOTE


func _spiral_fx(r: float) -> void:
	## Corte em Espiral: anel de luz em volta e as duas lâminas giram.
	var root := get_parent()
	var c := global_position + Vector3.UP * 0.45
	for k in 12:
		var a0 := k * TAU / 12.0
		var a1 := (k + 1) * TAU / 12.0
		Fx.beam(root, c + Vector3(cos(a0), 0, sin(a0)) * r, c + Vector3(cos(a1), 0, sin(a1)) * r, Color(0.7, 0.95, 1.0), 0.18, 0.06)
	_spin = SPIN_TIME


func _state_bite() -> Vector3:
	noise = 4.0
	if not hit_done and state_time >= 0.2:
		hit_done = true
		_melee(float(form_data()["bite"]), BITE_RANGE, 70.0, true, _bite_dir)
	if state_time >= BITE_TIME:
		_start_state(State.NORMAL)
	if state_time < BITE_LUNGE_TIME:
		return _bite_dir * _bite_speed   # o bote: avança e crava
	return move_dir * 1.0


func _state_eat() -> Vector3:
	noise = 1.0
	if eating_bag:
		if state_time >= 1.2:
			eating_bag = false
			if not bag.is_empty():
				var it: Dictionary = bag.pop_front()
				_eat_item(it)
				_msg("Comeu %s do embrulho: +%d saciedade, +%d seda." % [String(it.get("name", "presa")), int(it.get("sat", 0)), int(it.get("silk", 0))])
			_start_state(State.NORMAL)
		return Vector3.ZERO
	if eat_target == null or not is_instance_valid(eat_target):
		_start_state(State.NORMAL)
		return Vector3.ZERO
	if state_time >= 0.9:
		_eat(eat_target)
		eat_target = null
		_start_state(State.NORMAL)
	return Vector3.ZERO


func _state_zip() -> void:
	noise = 3.0
	if _zip_wait:
		# o fio ainda está voando até a parede
		velocity = Vector3.ZERO
		if state_time > 0.35 or _silk == null or not is_instance_valid(_silk):
			_zip_wait = false
		state_time = minf(state_time, 0.35)
		return
	var to := zip_target - global_position
	to.y = 0.0
	var left := to.length()
	var p := 1.0 - clampf(left / _zip_total, 0.0, 1.0)
	if left < 0.5 or state_time > 1.6:
		velocity = Vector3.ZERO
		_visual.position.y = 0.0
		_release_silk_later(0.0)
		_zip_land()
		_start_state(State.NORMAL)
		return
	# arranca rápido, voa e freia perto da parede; o corpo sobe num arco
	var spd := minf(20.0, 7.0 + 40.0 * state_time)
	spd = minf(spd, 4.0 + left * 9.0)
	velocity = to / left * spd
	velocity.y = 0.0
	_visual.position.y = sin(PI * p) * 0.35
	move_and_slide()
	if get_slide_collision_count() > 0 and velocity.length() < 1.0:
		_visual.position.y = 0.0
		_release_silk_later(0.0)
		_zip_land()
		_start_state(State.NORMAL)


# ================================================================= ações

func _melee(damage: float, reach: float, arc_deg: float, poison: bool, dir := Vector3.ZERO) -> void:
	if dir == Vector3.ZERO:
		dir = aim_dir
	for n in get_tree().get_nodes_in_group("creature"):
		var c := n as Creature
		if c == null or c.dead:
			continue
		var to := c.global_position - global_position
		to.y = 0.0
		if to.length() > reach + c.body_radius:
			continue
		if c.global_position.y - global_position.y > 1.3:
			continue   # voando alto demais (morcego): use fio (Q) ou espere o mergulho
		if to.length() > 0.3 and rad_to_deg(dir.angle_to(to.normalized())) > arc_deg * 0.5:
			continue
		hit_creature(c, damage, poison)


func _impact_fx(c: Creature, dmg: float, crit: bool) -> void:
	## Faíscas, número de dano e a pausa curtinha no impacto (Juice).
	if dmg < 0.5:
		return
	var col := Color(0.85, 0.95, 1.0)
	if fd("ignite", 0.0) > 0.0:
		col = Color(1.0, 0.55, 0.15)
	elif int(fd("venom", 0)) > 0:
		col = Color(0.7, 1.0, 0.3)
	elif fd("corrode", 0.0) > 0.0:
		col = Color(0.55, 1.0, 0.2)
	if crit:
		col = Color(1.0, 0.9, 0.35)
	var to := c.global_position - global_position
	to.y = 0.0
	var at := c.global_position - to.normalized() * minf(c.body_radius, to.length() * 0.5) + Vector3.UP * 0.5
	var heavy := dmg >= 30.0 or c.dead
	var strength := 1.0 + (0.7 if crit else 0.0) + (0.7 if heavy else 0.0)
	if dmg >= 6.0:
		Juice.impact(at, col, strength)
	Juice.number(c.global_position + Vector3.UP * c.body_radius, dmg, col if crit or dmg >= 30.0 else Color(1, 1, 1), crit or heavy)
	if dmg >= 4.0:
		Sfx.hit(c, crit, dmg)
	if dmg >= 8.0:
		Juice.hitstop(0.035 + (0.025 if crit else 0.0) + (0.03 if heavy else 0.0) + (0.04 if c.dead else 0.0))


func hit_creature(c: Creature, damage: float, poison := false) -> float:
	## Um acerto da jogadora num bicho, com tudo o que a forma soma (crítico no enredado,
	## emboscada, execução, corrosão, veneno, fogo, cura no abate). Devolve o dano.
	if c == null or c.dead:
		return 0.0
	var dmg := damage * power()
	var crit := c.is_entangled()
	if crit:
		dmg *= 2.0
		_msg("Crítico! %s está enredado." % c.display_name)
	var amb := float(fd("ambush", 1.0))
	if amb > 1.0 and not c.noticed_player and not crit:
		dmg *= amb
		_msg("Emboscada! %s nem te viu." % c.display_name)
	if kit != null:
		dmg = kit.modify_hit(c, dmg)
	var ex := float(fd("execute", 0.0))
	var boss := c.is_in_group("boss")
	if ex > 0.0 and c.hp > 0.0 and c.hp - dmg < c.max_hp * ex:
		if boss:
			dmg *= 2.0
		else:
			dmg = c.hp + 1.0
			_msg("Execução!")
	var cor := float(fd("corrode", 0.0))
	if cor > 0.0:
		c.corrode(cor)
	c.take_damage(dmg, self)
	_impact_fx(c, dmg, crit)
	if poison:
		c.add_poison()
	for k in int(fd("venom", 0)):
		c.add_poison()
	var ig := float(fd("ignite", 0.0))
	if ig > 0.0 and not c.dead:
		c.ignite(ig)
	if c.dead and float(fd("kill_heal", 0.0)) > 0.0:
		hp = minf(max_hp, hp + max_hp * float(fd("kill_heal", 0.0)))
	if kit != null:
		kit.on_hit(c, dmg)
	return dmg


func _throw_silk() -> void:
	if silk < SILK_THROW:
		_msg("Seda insuficiente para lançar fio.")
		return
	silk -= SILK_THROW
	Sfx.play("teia_lancar", global_position)
	if _silk != null and is_instance_valid(_silk):
		_silk.release()
	var dir := aim_dir
	var from := global_position + Vector3.UP * 0.5
	var to := from + dir * throw_range()
	var root := get_parent()
	var flyer := _flyer_in_aim()
	if flyer != null:
		var fl_ref: WeakRef = weakref(flyer)   # o bicho pode sumir com o fio no ar
		_silk = SilkLine.shoot(root, _mouth.bind(dir), func(): return _ref_pos(fl_ref, to, 0.0))
		_silk.arrived.connect(func():
			var fl := fl_ref.get_ref() as Creature
			if fl != null and not fl.dead:
				fl.entangle(4.0)
				_msg("Fio no ar! %s caiu enredado." % fl.display_name)
				GameState.say_once("derrubou_morcego", "Desce daí, rato de asa!")
			_release_silk_later(0.35))
		return
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 4)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		# errou: o fio vai até o fim do alcance e cai
		_silk = SilkLine.shoot(root, _mouth.bind(dir), func(): return to)
		_silk.arrived.connect(func(): _silk.release(true))
		return
	var hit_pos: Vector3 = hit["position"]
	var c := hit["collider"] as Creature
	if c != null:
		var c_ref: WeakRef = weakref(c)
		var cname := c.display_name
		_silk = SilkLine.shoot(root, _mouth.bind(dir), func(): return _ref_pos(c_ref, hit_pos, 0.3))
		if c.size == Creature.Size.P or (c.size == Creature.Size.M and has_skill("puxao")):
			_silk.arrived.connect(func(): _yank(c_ref.get_ref()))
			GameState.say_once("primeiro_puxao", "Vem cá, lanchinho!")
		else:
			_silk.arrived.connect(func():
				_msg("%s é grande demais para puxar." % cname)
				_release_silk_later(0.15))
		return
	# parede: o fio voa, prende, e ela se puxa até lá (o fio encurta junto)
	_zip_dir = dir
	zip_target = hit_pos - dir * 0.7
	zip_target.y = global_position.y
	_zip_total = maxf(0.5, Fx.flat_dist(zip_target, global_position))
	_zip_wait = true
	_silk = SilkLine.shoot(root, _mouth.bind(dir), func(): return hit_pos)
	_silk.arrived.connect(func(): _zip_wait = false)
	_start_state(State.ZIP)
	GameState.say_once("primeiro_zip", "Fio, parede, VOOOU!")


func _mouth(dir: Vector3) -> Vector3:
	## De onde sai o fio: na frente da aranha (ela segura o fio com as patas da frente).
	return global_position + dir * 0.45 * vis_scale + Vector3.UP * (0.35 + _visual.position.y) * vis_scale


func _ref_pos(r: WeakRef, fallback: Vector3, up: float) -> Vector3:
	var o = r.get_ref()
	return (o as Node3D).global_position + Vector3.UP * up if o != null else fallback


func _yank(obj) -> void:
	## Puxão: o bicho vem voando até a sua frente e fica tonto um instante.
	var c := obj as Creature
	if c == null or not is_instance_valid(c) or c.dead:
		_release_silk_later(0.0)
		return
	var to := c.global_position - global_position
	to.y = 0.0
	var stop := global_position + to.normalized() * (0.6 * vis_scale + c.body_radius + 0.35)
	c.yank_to(stop, 0.32)
	_release_silk_later(0.34)


func _release_silk_later(t: float) -> void:
	var s := _silk
	if s == null or not is_instance_valid(s):
		return
	if t <= 0.0:
		s.release()
		return
	get_tree().create_timer(t, false).timeout.connect(func():
		if is_instance_valid(s):
			s.release())


func _flyer_in_aim() -> Creature:
	## Criatura voando na direção da mira (fio lançado sobe até ela).
	var best: Creature = null
	var best_d := throw_range()
	for n in get_tree().get_nodes_in_group("flyer"):
		var c := n as Creature
		if c == null or c.dead or c.is_entangled():
			continue
		var to := c.global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d > best_d or d < 0.3:
			continue
		if rad_to_deg(aim_dir.angle_to(to.normalized())) > 14.0:
			continue
		best = c
		best_d = d
	return best


func _interact() -> void:
	var thing := _nearest_interactable(2.2)
	if thing != null:
		thing.call("interact", self)
		return
	var c := _nearest_cocoon(2.4)
	if c != null:
		var hud = GameState.current_layer.hud if GameState.current_layer != null else null
		if hud != null and hud.has_method("open_cocoon"):
			hud.open_cocoon(c)   # o menu do casulo: habilidades, evolução, despensa e descansar
		else:
			_rest(c)
		return
	var corpse := _nearest_corpse(1.9)
	if corpse != null:
		eat_target = corpse
		_start_state(State.EAT)
		return
	_msg("Nada para comer ou usar aqui.")


func _eat(c: Corpse) -> void:
	Sfx.play("pc_comer", global_position)
	Bestiary.eaten(c.display_name)
	var rotten := c.is_rotten()
	if c.has_meta("venom_heal"):
		hp = minf(max_hp, hp + max_hp * 0.2)
		_msg("A presa envenenada te curou.")
	satiety = minf(max_satiety, satiety + c.satiety * (0.6 if rotten else 1.0))
	silk = minf(max_silk, silk + c.silk)
	if rotten:
		var dmg := maxf(2.0, 12.0 - resist_rot * 2.0) * (0.5 if has_skill("estomago") else 1.0)
		resist_rot += 1
		_hurt(dmg)
		_msg("Carne podre! -%d PV · Resistência à Podridão %d" % [int(dmg), resist_rot])
		GameState.say_once("comeu_podre", "Eca. Eca, eca, eca. ...Mas acho que meu estômago ficou mais forte.")
	else:
		_msg("Comeu %s: +%d saciedade, +%d seda, +%d XP" % [c.display_name, int(c.satiety), int(c.silk), c.xp])
	GameState.say_once("primeira_refeicao", "Larva crua. Gosto de musgo molhado. Mas a fome venceu o nojo.")
	if c.acid_bonus > 0:
		resist_acid += c.acid_bonus
		_msg("Resistência a Ácido %d%s" % [resist_acid, " — as Poças ácidas não queimam mais!" if resist_acid == 3 else ""])
		GameState.say_once("acido_%d" % mini(resist_acid, 3), ["", "Gosto de pedra molhada... e de bateria.", "Minha boca formiga. Acho que estou me acostumando.", "Pronto. Ácido agora é só tempero."][mini(resist_acid, 3)])
	if c.fire_bonus > 0:
		resist_fire += c.fire_bonus
		_msg("Carne de fogo! Resistência a Fogo %d" % resist_fire)
		EventBus.big_message.emit("Resistência a Fogo %d" % resist_fire)
		GameState.say_once("fogo_%d" % mini(resist_fire, 3), ["", "Queimou a boca. E o estômago. E a alma.", "Já nem arde mais. Muito.", "Brasa? Pode vir. Eu ando em cima."][mini(resist_fire, 3)])
	if c.poison_bonus > 0:
		resist_poison += c.poison_bonus
		if resist_poison < 2:
			apply_poison(4.0)
		_msg("Carne venenosa! Resistência a Veneno %d" % resist_poison)
		GameState.say_once("veneno_%d" % mini(resist_poison, 3), ["", "Formiga na língua... e no estômago. Ugh.", "Já não arde tanto.", "Veneno? Tempero."][mini(resist_poison, 3)])
	if c.skin_bonus:
		crystal_skin = true
		add_bonus(20.0, 0.0)
		_msg("Pele de Cristal! +20 PV máximo e -20% de dano recebido.")
		GameState.say_once("pele_cristal", "Comi a armadura dela. Agora a armadura é minha.")
	if c.energy_bonus > 0.0:
		add_bonus(0.0, c.energy_bonus)
		_msg("A luz do lagarto agora é sua: +%d Energia máxima." % int(c.energy_bonus))
		GameState.say_once("comeu_lagarto", "Comi uma lanterna. Agora EU sou a lanterna.")
	gain_xp(int(round(c.xp * (1.25 if has_skill("paladar") else 1.0))))
	c.consume()


func rest_blocker() -> String:
	## Nome do bicho que está te caçando perto (aí não dá para dormir no casulo), ou "".
	for n in get_tree().get_nodes_in_group("creature"):
		var c := n as Creature
		if c == null or c.dead:
			continue
		if c.hunting_player() and Fx.flat_dist(c.global_position, global_position) < 14.0:
			return c.display_name
	return ""


func _rest(c: Cocoon) -> void:
	Sfx.play("pc_descanso")
	hp = max_hp
	energy = max_energy
	silk = max_silk
	satiety = maxf(0.0, satiety - 15.0)
	respawn_pos = c.global_position + Vector3(0.0, 0.1, 1.6)
	rested_here = true
	var den := current_den()
	if den != null:
		den.on_rest()
	EventBus.rested.emit(c)
	if can_evolve():
		evolve()
	GameState.save_now()
	_msg("Você descansou no casulo. Jogo salvo. O tempo passou (-15 saciedade).")
	GameState.say_once("primeiro_descanso", "Casulo quentinho... Isso aqui é meu agora. Meu território.")


# ================================================================= habilidades e despensa

func has_skill(id: String) -> bool:
	return skills.has(id)


func strand_cost() -> float:
	return (3.0 if has_skill("fio_leve") else SILK_STRAND) * float(form_data().get("strand_cost", 1.0))


func trap_cost() -> float:
	return SILK_TRAP * float(form_data().get("trap_cost", 1.0))


func throw_range() -> float:
	return THROW_RANGE * (1.5 if has_skill("puxao") else 1.0)


func skill_block(id: String) -> String:
	## "" = dá para aprender agora; senão o motivo.
	if has_skill(id):
		return "Aprendida"
	var s := Skills.info(id)
	if s.is_empty():
		return "?"
	if s.has("form") and int(form) < int(s["form"]):
		return "Precisa ser %s" % Skills.FORM_NAMES[int(s["form"])]
	var linked := false
	for n in Skills.neighbors(id):
		if has_skill(n):
			linked = true
	if not linked:
		return "Bloqueada"
	if skill_points < int(s["cost"]):
		return "Pontos insuficientes"
	return ""


func add_rune_shard() -> void:
	## Fragmento de runa: a cada 4, um ponto de habilidade para gastar no casulo.
	rune_shards += 1
	var have := rune_shards % RUNE_SHARDS_PER_POINT
	if have == 0:
		skill_points += 1
		EventBus.big_message.emit("Runa completa! +1 ponto de habilidade")
		_msg("Os %d fragmentos se juntam na sua runa. Gaste o ponto no casulo." % RUNE_SHARDS_PER_POINT)
		GameState.say_once("runa_completa", "A runa... ficou mais forte. Eu sinto. Hora de aprender algo novo.")
	else:
		_msg("Fragmento de runa (%d/%d para um ponto de habilidade)." % [have, RUNE_SHARDS_PER_POINT])
		GameState.say_once("primeiro_fragmento", "Um caco que brilha igual à minha runa. Deve ter mais por aí.")


func learn(id: String) -> bool:
	if skill_block(id) != "":
		return false
	skill_points -= int(Skills.info(id)["cost"])
	skills[id] = true
	match id:
		"carapaca":
			add_bonus(15.0, 0.0)
		"reserva":
			add_bonus(0.0, 0.0, 20.0)
		"olhos":
			_sight_light.omni_range = sight_radius()   # a luz da visão cresce na hora
	return true


func wrappable_corpses() -> Array:
	## Presas mortas por perto que dá para embrulhar (frescas e sem efeito especial).
	var out: Array = []
	for n in get_tree().get_nodes_in_group("corpse"):
		var c := n as Corpse
		if c == null or c.is_rotten() or c.reserved_by != null or c == dragged:
			continue
		if c.energy_bonus > 0.0 or c.acid_bonus > 0 or c.skin_bonus or c.poison_bonus > 0 or c.fire_bonus > 0:
			continue
		if Fx.flat_dist(c.global_position, global_position) <= WRAP_RANGE:
			out.append(c)
	return out


func current_den() -> Den:
	var l = GameState.current_layer
	return l.den if l != null else null


func in_den() -> bool:
	var d := current_den()
	return d != null and d.claimed and d.is_inside(global_position)


func wrap_nearby() -> int:
	## No menu da toca: embrulha as presas por perto direto na despensa (10 de Seda cada).
	var d := current_den()
	var n := 0
	for c in wrappable_corpses():
		if silk < SILK_WRAP:
			break
		var item := {"name": c.display_name, "sat": c.satiety, "silk": c.silk}
		if d != null and d.claimed and d.store(item):
			pass
		elif bag.size() < BAG_MAX:
			bag.append(item)
		else:
			break
		silk -= SILK_WRAP
		c.consume()
		n += 1
	return n


func wrap_into_bag(c: Corpse) -> bool:
	## Presa pequena: embrulha onde estiver e leva na bolsa (2 embrulhos).
	if bag.size() >= BAG_MAX:
		_msg("A bolsa está cheia (%d embrulhos). Coma (%s) ou guarde na toca." % [BAG_MAX, Settings.text("eat")])
		return false
	if c.is_rotten():
		_msg("Podre demais para embrulhar.")
		return false
	if silk < SILK_WRAP:
		_msg("Seda insuficiente para embrulhar (precisa de %d)." % int(SILK_WRAP))
		return false
	silk -= SILK_WRAP
	Sfx.play("teia_embrulhar", c.global_position)
	bag.append({"name": c.display_name, "sat": c.satiety, "silk": c.silk})
	c.consume()
	_msg("Embrulhou %s (%d/%d na bolsa). Coma com %s quando quiser." % [c.display_name, bag.size(), BAG_MAX, Settings.text("eat")])
	GameState.say_once("primeiro_embrulho", "Lanchinho pra viagem. Embrulhado, não estraga.")
	return true


func eat_from_bag() -> void:
	if bag.is_empty():
		_msg("Nenhum embrulho na bolsa.")
		return
	if state != State.NORMAL:
		return
	eating_bag = true
	_start_state(State.EAT)


func _eat_item(it: Dictionary) -> void:
	satiety = minf(max_satiety, satiety + float(it.get("sat", 0.0)))
	silk = minf(max_silk, silk + float(it.get("silk", 0.0)))


func eat_from_pantry(i: int) -> bool:
	## Comer da despensa da toca (pelo menu).
	var d := current_den()
	if d == null:
		return false
	var it := d.take(i)
	if it.is_empty():
		return false
	_eat_item(it)
	return true


func start_drag(c: Corpse) -> void:
	if dragged != null:
		stop_drag()
	if c.is_rotten():
		_msg("Podre demais para levar para a toca.")
		return
	dragged = c
	c.reserved_by = self
	_drag_line = SilkLine.shoot(get_parent(), _mouth_pos, func(): return dragged.global_position + Vector3(0, 0.3, 0) if is_instance_valid(dragged) else global_position)
	_msg("Arrastando %s no fio. Leve até a toca para guardar (%s solta)." % [c.display_name, Settings.text("cocoon")])
	GameState.say_once("primeiro_arrasto", "Pesadinho... mas é comida pra uma semana.")


func stop_drag() -> void:
	if is_instance_valid(dragged):
		dragged.reserved_by = null
	dragged = null
	if _drag_line != null and is_instance_valid(_drag_line):
		_drag_line.release()
	_drag_line = null


func _mouth_pos() -> Vector3:
	return global_position + Vector3(0, 0.35, 0)


func _update_drag(delta: float) -> void:
	if dragged == null:
		return
	if not is_instance_valid(dragged) or dead:
		stop_drag()
		return
	var back := dragged.global_position - global_position
	back.y = 0.0
	if back.length() > 1.6:
		var goal := global_position + back.normalized() * 1.6
		dragged.global_position = dragged.global_position.lerp(Vector3(goal.x, dragged.global_position.y, goal.z), minf(1.0, delta * 10.0))
	if back.length() > 6.0:
		stop_drag()   # ficou preso em algo (pulo, fio, abismo)
		_msg("O fio arrebentou: a presa ficou para trás.")
		return
	var d := current_den()
	if d != null and d.claimed and d.is_inside(dragged.global_position):
		var c := dragged
		var item := {"name": c.display_name, "sat": c.satiety, "silk": c.silk}
		if d.store(item):
			stop_drag()
			c.consume()
			_msg("%s guardado na despensa da toca (%d/%d)." % [c.display_name, d.pantry.size(), Den.PANTRY_MAX])
			GameState.say_once("primeira_despensa", "Despensa abastecida. Agora é só proteger as portas.")
		else:
			stop_drag()
			_msg("A despensa está cheia: a presa ficou no chão.")


func _context_weave() -> void:
	## C faz o que faz sentido aqui: soltar o que arrasta, tomar a toca, tecer/remendar uma
	## porta, embrulhar presa pequena, arrastar presa grande (ou casulo, no laboratório).
	if dragged != null:
		stop_drag()
		_msg("Soltou a presa.")
		return
	var d := current_den()
	if d != null and not d.claimed and Fx.flat_dist(global_position, d.center) <= 3.0:
		d.claim(self)
		return
	if d != null and d.claimed:
		var i := d.slot_near(global_position, 2.6)
		if i >= 0 and d.door_cost(i) > 0.0:
			d.weave_door(i, self)
			return
	var corpse := _nearest_corpse(1.9)
	if corpse != null and corpse.reserved_by == null:
		if corpse.big:
			start_drag(corpse)
		else:
			wrap_into_bag(corpse)
		return
	var l = GameState.current_layer
	if l != null and l.free_cocoons:
		_weave_cocoon()
	elif d != null and not d.claimed:
		_msg("Casulo só no ninho velho da toca (%s)." % d.title)
	else:
		_msg("Nada para tecer aqui. (Perto de uma presa: embrulha ou arrasta. Perto de uma entrada da toca: porta.)")


func _weave_cocoon() -> void:
	## Casulo livre (só no laboratório de testes; no jogo o casulo é o central da toca).
	if silk < SILK_COCOON:
		_msg("Seda insuficiente para o casulo (precisa de %d)." % int(SILK_COCOON))
		return
	var pos := global_position + aim_dir * 1.4
	pos.y = 0.0
	if not _has_floor(pos) or not is_on_floor():
		_msg("Teça o casulo em chão firme.")
		return
	if not WebNetwork.cocoons.is_empty() and not WebNetwork.is_in_territory(global_position):
		_msg("Novos casulos só dentro do território (perto de um casulo ou de fios ligados a ele).")
		return
	for existing in WebNetwork.cocoons:
		if is_instance_valid(existing) and Fx.flat_dist(existing.global_position, pos) < 4.0:
			_msg("Já existe um casulo aqui perto.")
			return
	silk -= SILK_COCOON
	WebNetwork.create_cocoon(pos)
	_msg("Casulo tecido! Descanse nele com E para salvar.")
	GameState.say_once("primeiro_casulo", "Um casulo! Agora tenho onde dormir sem virar janta.")


func _toggle_rune() -> void:
	rune_on = not rune_on
	Sfx.play("pc_runa_liga" if rune_on else "pc_runa_desliga", global_position)
	var pulse_cost := 10.0 if fd("pulse", false) else 20.0
	if rune_on and (has_skill("pulso") or fd("pulse", false)) and energy >= pulse_cost:
		energy -= pulse_cost
		_rune_pulse()
		_msg("Pulso Espiral!")
	elif rune_on:
		_msg("Runa acesa.")
	else:
		_msg("Runa apagada: furtiva, mas a energia não regenera.")
		GameState.say_once("runa_apagada", "Shhh... Apagada, sou só mais uma sombra na caverna.")


func pulse_radius() -> float:
	return float(fd("pulse_r", 6.5 if fd("pulse", false) else 4.5))


func _rune_pulse() -> void:
	Sfx.play("pc_pulso", global_position)
	## Onda de luz: atordoa os bichos perto (a Centopeia é grande demais para ligar).
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.0
	ring.mesh = tm
	ring.material_override = Fx.mat(Color(0.4, 0.9, 1.0), 3.0, true, 0.8)
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector3.UP * 0.3
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector3.ONE * pulse_radius(), 0.35)
	tw.tween_callback(ring.queue_free)
	EventBus.rune_pulsed.emit(global_position)
	for n in get_tree().get_nodes_in_group("creature"):
		var c := n as Creature
		if c == null or c.dead or c is Centipede:
			continue
		if Fx.flat_dist(c.global_position, global_position) <= pulse_radius():
			c.entangle_raw(1.5)
			var pd := float(fd("pulse_dmg", 0.0))
			if pd > 0.0:
				c.take_damage(pd * power(), self)


# ================================================================= Modo Tecelagem

func _handle_weave(real_dt: float) -> void:
	var want := Input.is_action_pressed("weave") and not dead
	if want and not weaving:
		if energy >= 5.0:
			_enter_weave()
		elif Input.is_action_just_pressed("weave"):
			_msg("Energia baixa demais para tecer.")
	elif weaving and (not want or energy <= 0.0):
		_exit_weave()
	if not weaving:
		return
	energy = maxf(0.0, energy - WEAVE_ENERGY_PER_SEC * (0.6 if has_skill("tecela") else 1.0) * real_dt)
	energy_delay = 1.0
	var new_hover := _anchor_near(aim_point, 2.5)
	if new_hover != hovered_anchor:
		hovered_anchor = new_hover
		_refresh_anchor_highlights()
	if Input.is_action_just_pressed("attack"):
		_weave_click()
	if Input.is_action_just_pressed("bite"):
		_place_trap()
	_update_preview()


func _enter_weave() -> void:
	weaving = true
	weave_first = null
	hovered_anchor = null
	Engine.time_scale = WEAVE_TIME_SCALE
	_refresh_anchor_highlights()
	GameState.say_once("primeira_tecelagem", "Tudo ficou lento... Consigo ver onde prender meus fios.")


func _exit_weave() -> void:
	weaving = false
	weave_first = null
	hovered_anchor = null
	Engine.time_scale = 1.0
	_preview.visible = false
	_refresh_anchor_highlights()


func _refresh_anchor_highlights() -> void:
	for n in get_tree().get_nodes_in_group("anchor"):
		var a := n as WebAnchor
		if a == null:
			continue
		var mode := 0
		if weaving:
			mode = 1 if Fx.flat_dist(a.global_position, global_position) <= 24.0 else 0
			if a == hovered_anchor:
				mode = 3
			if a == weave_first:
				mode = 2
		a.set_highlight(mode)


func _weave_click() -> void:
	if hovered_anchor == null:
		_msg("Mire num pilar (âncora) para prender o fio.")
		return
	if weave_first == null:
		weave_first = hovered_anchor
		_refresh_anchor_highlights()
		return
	if hovered_anchor == weave_first:
		weave_first = null
		_refresh_anchor_highlights()
		return
	var err := _strand_error(weave_first, hovered_anchor)
	if err != "":
		_msg(err)
		return
	silk -= strand_cost()
	WebNetwork.create_strand(weave_first, hovered_anchor)
	_msg("Fio-guia tecido (-%d seda)." % int(strand_cost()))
	_gain_weave()
	GameState.say_once("primeiro_fio", "Um fio! Andar nele é rápido e silencioso. Isso muda tudo.")
	weave_first = hovered_anchor
	_refresh_anchor_highlights()


func weave_level() -> int:
	var lv := 1
	for i in WEAVE_STEPS.size():
		if weave_xp >= int(WEAVE_STEPS[i]):
			lv = i + 1
	return lv


func strand_range() -> float:
	## Tecelagem 1: 12 m; cada nível +1,5 m (Tecelagem 5: 18 m, o Abismo duplo).
	return STRAND_RANGE + (weave_level() - 1) * 1.5 + float(form_data().get("strand_bonus", 0.0))


func _gain_weave() -> void:
	var before := weave_level()
	weave_xp += 1
	if weave_level() > before:
		EventBus.big_message.emit("Tecelagem %d" % weave_level())
		_msg("Tecelagem %d: fio-guia até %.1f m." % [weave_level(), strand_range()])
		GameState.say_once("tecelagem_%d" % weave_level(), ["", "", "Meus fios estão saindo mais firmes.", "Mais longe... e mais longe.", "Dá pra sentir a seda esticando sem arrebentar.", "Dezoito metros. Agora nenhum buraco me segura."][weave_level()])


func fire_mult() -> float:
	if fd("fireproof", false):
		return 0.0
	## Quanto do fogo ainda passa: cada ponto de Resistência a Fogo corta 25% (4 = imune).
	return maxf(0.0, 1.0 - 0.25 * resist_fire)


func apply_heat(dps: float, delta: float, ember: bool = false) -> void:
	## Calor perto da lava (ou brasa nas ilhas): perde vida aos poucos. Brasa pede Resistência 3.
	if dead:
		return
	var k := 0.0 if fd("fireproof", false) else (maxf(0.0, 1.0 - resist_fire / 3.0) if ember else fire_mult())
	heat_t = 0.3
	if k <= 0.0:
		return
	_hurt(dps * k * delta)
	heat_exposure += delta
	if heat_exposure >= 45.0 and resist_fire < 2:
		heat_exposure = 0.0
		resist_fire += 1
		EventBus.big_message.emit("Resistência a Fogo %d" % resist_fire)
		_msg("Aguentou o calor: Resistência a Fogo %d." % resist_fire)


func apply_burn(secs: float) -> void:
	if dead or fire_mult() <= 0.0:
		return
	burn_t = maxf(burn_t, secs * fire_mult())
	_msg("Queimando!")


func lava_fall() -> void:
	## Caiu na lava: sai pela beirada, mas queima feio.
	falling = false
	global_position = last_safe_pos + Vector3.UP * 0.3
	velocity = Vector3.ZERO
	external_velocity = Vector3.ZERO
	_start_state(State.NORMAL)
	_hurt_flash = 0.25
	var dmg := 0.0 if fd("fireproof", false) else max_hp * 0.4 * maxf(0.25, fire_mult())
	_msg("Lava! -%d PV" % int(dmg))
	GameState.say_once("primeira_lava", "AI AI AI AI QUENTE QUENTE QUENTE!")
	_hurt(dmg)
	snap_camera()


func apply_acid(amount: float) -> void:
	## Ácido (cuspe e rastro da lesma): Resistência a Ácido 3 anula.
	if dead or fd("acid_immune", false):
		return
	var k := maxf(0.0, 1.0 - resist_acid / 3.0)
	if k <= 0.0:
		return
	_hurt(amount * k)
	_msg("Ácido! -%d PV" % int(ceil(amount * k)))


func apply_poison(secs: float) -> void:
	## Ferrão de escorpião, carne venenosa: perde vida aos poucos (Resistência a Veneno corta).
	if dead or fd("poison_immune", false):
		return
	var k := maxf(0.0, 1.0 - 0.25 * resist_poison)
	if k <= 0.0:
		return
	poison_t = maxf(poison_t, secs * k)
	_msg("Envenenada!")


func _strand_error(a: WebAnchor, b: WebAnchor) -> String:
	var d := Fx.flat_dist(a.global_position, b.global_position)
	if d > strand_range():
		return "Longe demais: %.1f m (máximo %.1f m, Tecelagem %d)." % [d, strand_range(), weave_level()]
	if WebNetwork.has_strand(String(a.name), String(b.name)):
		return "Esses pilares já estão ligados."
	if silk < strand_cost():
		return "Seda insuficiente (precisa de %d)." % int(strand_cost())
	var q := PhysicsRayQueryParameters3D.create(a.global_position + Vector3.UP * 0.5, b.global_position + Vector3.UP * 0.5, 1)
	q.exclude = [a.get_rid(), b.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		return "Algo bloqueia o caminho entre os pilares."
	return ""


func _place_trap() -> void:
	if level < TRAP_LEVEL:
		_msg("Teia de captura libera no nível %d (F1 sobe de nível para testar)." % TRAP_LEVEL)
		return
	if silk < trap_cost():
		_msg("Seda insuficiente para a teia de captura (precisa de %d)." % int(trap_cost()))
		return
	if Fx.flat_dist(aim_point, global_position) > TRAP_RANGE:
		_msg("Longe demais para lançar a teia (máximo %d m)." % int(TRAP_RANGE))
		return
	if not _has_floor(aim_point):
		_msg("A teia de captura precisa de chão firme.")
		return
	silk -= trap_cost()
	WebNetwork.create_trap(Vector3(aim_point.x, 0.0, aim_point.z))
	_msg("Teia de captura armada (-%d seda)." % int(trap_cost()))
	GameState.say_once("primeira_armadilha", "Pronto. Agora é só esperar alguém pisar... Paciência de aranha.")


func _update_preview() -> void:
	if weave_first == null:
		_preview.visible = false
		return
	var a := Vector3(weave_first.global_position.x, 0.1, weave_first.global_position.z)
	var target := aim_point
	var ok := true
	if hovered_anchor != null and hovered_anchor != weave_first:
		target = hovered_anchor.global_position
		ok = _strand_error(weave_first, hovered_anchor) == ""
	var b := Vector3(target.x, 0.1, target.z)
	if Fx.flat_dist(a, b) > strand_range():
		ok = false
	var length := a.distance_to(b)
	_preview.visible = length > 0.1
	(_preview.mesh as BoxMesh).size = Vector3(0.07, 0.07, maxf(length, 0.01))
	Fx.orient_between(_preview, a, b)
	var col := Color(0.4, 1.0, 0.6) if ok else Color(1.0, 0.35, 0.3)
	_preview_mat.albedo_color = col
	_preview_mat.emission = col


# ================================================================= recursos, dano e morte

func _update_resources(delta: float) -> void:
	if dead:
		return
	_territory_timer -= delta
	if _territory_timer <= 0.0:
		_territory_timer = 0.4
		var was := in_territory
		in_territory = WebNetwork.is_in_territory(global_position)
		if in_territory and not was:
			GameState.say_once("territorio", "Sinto cada fio vibrando. Aqui é seguro... mais ou menos.")
	if poison_t > 0.0:
		poison_t -= delta
		_hurt(3.0 * delta)
	if burn_t > 0.0:
		burn_t -= delta
		_hurt(4.0 * delta)
	heat_t = maxf(0.0, heat_t - delta)
	satiety = maxf(0.0, satiety - SATIETY_DECAY * (0.75 if has_skill("estomago") else 1.0) * delta)
	if satiety <= 0.0:
		_starve_msg_timer -= delta
		if _starve_msg_timer <= 0.0:
			_starve_msg_timer = 10.0
			_msg("Você está morrendo de fome! Coma algo.")
			GameState.say_once("fome", "Minha barriga está roncando tão alto que vai me denunciar.")
		_hurt(STARVE_DPS * delta)
	energy_delay = maxf(0.0, energy_delay - delta)
	if energy_delay <= 0.0 and (rune_on or has_skill("runa_oculta") or fd("dark_regen", false)) and not weaving:
		energy = minf(max_energy, energy + ENERGY_REGEN * delta * (1.5 if in_territory else 1.0) * (1.0 if rune_on else 0.5) * float(fd("energy_regen", 1.0)))
	var sh_max := float(fd("shield", 0.0))
	if sh_max > 0.0 and shield < sh_max:
		_shield_wait -= delta
		if _shield_wait <= 0.0:
			var was_down := shield <= 0.0
			shield = minf(sh_max, shield + sh_max * 0.5 * delta)
			if was_down and shield > 0.0:
				_msg("O escudo de pedra-da-lua voltou.")
	elif sh_max <= 0.0:
		shield = 0.0
	_update_reveal(delta)
	# seda não volta sozinha: só comendo (presa, embrulho) ou descansando na toca
	if satiety > 60.0:
		hp = minf(max_hp, hp + (0.15 if form == Form.FILHOTE else 0.4) * (2.0 if has_skill("sangue_frio") else 1.0) * delta)


func take_damage(amount: float, source: Node3D = null, knockback: bool = true) -> bool:
	## Devolve false se não pegou (esquiva com invulnerabilidade, já morta).
	if dead or invuln > 0.0:
		return false
	if source is Creature:   # andares mais fundos: os bichos batem mais forte
		var lyr = GameState.current_layer
		if lyr != null and is_instance_valid(lyr) and "threat" in lyr:
			amount *= float(lyr.threat)
	if kit != null:
		amount = kit.on_hurt(amount, source)
		if amount <= 0.0:
			invuln = maxf(invuln, 0.2)
			return false
	invuln = 0.35
	_hurt_flash = 0.25
	Sfx.play("pc_dano", global_position, 0.0, 0.08, 0.15)
	if amount >= 4.0:
		Juice.hitstop(0.05 if amount < 20.0 else 0.09)
		if get_parent() != null:
			Juice.sparks(get_parent(), global_position + Vector3.UP * 0.6, Color(1.0, 0.25, 0.2), 8, 4.0)
	if crystal_skin:
		amount *= 0.8
	amount *= float(form_data().get("armor", 1.0))
	var thorns := float(fd("thorns", 0.0))
	if thorns > 0.0 and source is Creature and not (source as Creature).dead and Fx.flat_dist(source.global_position, global_position) < 3.5 + (source as Creature).body_radius:
		(source as Creature).take_damage(amount * thorns / maxf(0.1, float(fd("armor", 1.0))), self)
	if float(fd("shield", 0.0)) > 0.0:
		_shield_wait = 6.0
		if shield > 0.0:
			var soak := minf(shield, amount)
			shield -= soak
			amount -= soak
			if shield <= 0.0:
				_msg("O escudo de pedra-da-lua quebrou!")
	if fd("no_knockback", false):
		knockback = false
	if knockback and source != null:
		var push := global_position - source.global_position
		push.y = 0.0
		if push.length() > 0.01:
			external_velocity = push.normalized() * 6.0
	if state == State.EAT:
		_start_state(State.NORMAL)
	_hurt(amount)
	if not dead:
		GameState.say_once("primeiro_dano", "AI! Ok, ok, tudo aqui é maior que eu. Anotado.")
	return true


func apply_slow(mult: float, secs: float) -> void:
	## Teia cuspida, grito de morcego, clarão do lagarto: anda mais devagar por um tempo.
	if dead:
		return
	_slow_mult = minf(_slow_mult, mult) if _slow_time > 0.0 else mult
	_slow_time = maxf(_slow_time, secs)


func is_quiet() -> bool:
	## Quieta = parada (ou quase), runa apagada e sem atacar. Só assim um caçador perde o rastro.
	return not rune_on and Vector2(velocity.x, velocity.z).length() < 0.8 and (state == State.NORMAL or state == State.EAT)


func pull_toward(point: Vector3, strength: float) -> bool:
	## Usado pela língua do sapo. Retorna false se a jogadora esquivou.
	if dead or invuln > 0.0 or state == State.DODGE:
		return false
	var d := point - global_position
	d.y = 0.0
	if d.length() > 0.1:
		external_velocity = d.normalized() * strength
	return true


func _hurt(amount: float) -> void:
	hp -= amount
	if hp <= 0.0 and not dead:
		_die()


func _die() -> void:
	stop_drag()
	Music.stinger("morte")
	Sfx.play("pc_morte", global_position)
	dead = true
	hp = 0.0
	state = State.DEAD
	_death_timer = 2.5
	velocity = Vector3.ZERO
	if weaving:
		_exit_weave()
	_visual.rotation.z = PI
	_visual.position.y = 0.9
	EventBus.player_died.emit()
	EventBus.big_message.emit("Você morreu...")
	GameState.say_once("primeira_morte_pre", "Ah, não... tudo ficou escuro...")


func _respawn() -> void:
	dead = false
	falling = false
	poison_t = 0.0
	burn_t = 0.0
	state = State.NORMAL
	hp = max_hp
	energy = max_energy
	silk *= 0.5
	satiety = maxf(satiety, 40.0)
	global_position = respawn_pos
	last_safe_pos = respawn_pos
	velocity = Vector3.ZERO
	external_velocity = Vector3.ZERO
	_visual.rotation.z = 0.0
	_visual.position.y = 0.0
	_death_timer = 0.0
	snap_camera()
	_msg("Você acordou no último casulo. Perdeu metade da seda." if rested_here else "Você acordou no último ponto seguro. Perdeu metade da seda.")
	GameState.say_once("primeira_morte", "...Tá. Aranha teimosa não desiste.")


func _check_fall_and_safe(delta: float) -> void:
	if global_position.y < -2.5 and not falling:
		Sfx.play("pc_queda", global_position)
		var layer = GameState.current_layer
		if layer != null and layer.has_method("on_player_fell"):
			falling = true
			velocity = Vector3.ZERO
			layer.on_player_fell(self)
			return
	if falling:
		return
	if global_position.y < -4.0:
		global_position = last_safe_pos + Vector3.UP * 0.3
		velocity = Vector3.ZERO
		external_velocity = Vector3.ZERO
		_start_state(State.NORMAL)
		_hurt_flash = 0.25
		_msg("Você caiu no abismo! -%d PV" % int(FALL_DAMAGE))
		GameState.say_once("primeira_queda", "Não olha pra baixo. Não olha pra baixo. ...Olhei.")
		_hurt(FALL_DAMAGE)
		snap_camera()
		return
	_safe_timer -= delta
	if _safe_timer <= 0.0 and is_on_floor():
		_safe_timer = 0.25
		var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.3, global_position + Vector3.DOWN * 0.6, 1)
		if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			last_safe_pos = global_position


func legacy_fall() -> void:
	## Queda antiga (câmara de teste): volta para a beirada com dano fixo.
	falling = false
	global_position = last_safe_pos + Vector3.UP * 0.3
	velocity = Vector3.ZERO
	external_velocity = Vector3.ZERO
	_start_state(State.NORMAL)
	_hurt_flash = 0.25
	_msg("Você caiu no abismo! -%d PV" % int(FALL_DAMAGE))
	GameState.say_once("primeira_queda", "Não olha pra baixo. Não olha pra baixo. ...Olhei.")
	_hurt(FALL_DAMAGE)
	snap_camera()


func fall_to_death() -> void:
	velocity = Vector3.ZERO
	GameState.say_once("queda_fatal", "Não tem chão... não tem chão...!")
	_hurt(hp + 1.0)
	falling = false


func land_after_fall(pos: Vector3, damage: float, where: String) -> void:
	## Caiu para o andar de baixo: acorda lá, machucada. O caminho de volta é por sua conta.
	falling = false
	global_position = pos + Vector3.UP * 0.2
	last_safe_pos = pos
	velocity = Vector3.ZERO
	external_velocity = Vector3.ZERO
	if weaving:
		_exit_weave()
	_start_state(State.NORMAL)
	_hurt_flash = 0.4
	snap_camera()
	_msg("Você caiu em %s! -%d PV" % [where, int(damage)])
	EventBus.big_message.emit("Queda!")
	GameState.say_once("primeira_queda", "Não olha pra baixo. Não olha pra baixo. ...Olhei. E CAÍ.")
	_hurt(damage)


func power() -> float:
	## Quanto dos golpes entra de verdade neste estágio (as formas novas batem mais forte na
	## ficha, mas o jogo segura um pouco para os bichos continuarem perigosos).
	if not balanced:
		return 1.0
	return float(POWER[clampi(tier(), 0, 3)])


func total_level() -> int:
	## Nível somando todas as formas (a Cavaleira nível 1 é o 8º nível da vida dela).
	return _levels_before() + level


func level_cap() -> int:
	## Teto de nível da camada atual (0 = sem teto). Cada andar só ensina até certo ponto:
	## para crescer mais, é preciso seguir em frente.
	var l = GameState.current_layer
	if l == null or not is_instance_valid(l) or not ("level_cap" in l):
		return 0
	return int(l.level_cap)


func at_level_cap() -> bool:
	var c := level_cap()
	return c > 0 and total_level() >= c


func _cap_reached() -> void:
	xp = 0
	var lid := "teto_%d" % level_cap()
	if not GameState.said.has(lid):
		GameState.say_once(lid, "Aqui eu não cresço mais. Esse andar já me ensinou tudo o que tinha... o resto está mais adiante.")
		EventBus.big_message.emit("Teto do andar")
		_msg("Nível máximo deste andar. A experiência daqui não conta mais: siga para o próximo.")


func gain_xp(amount: int) -> void:
	if at_level_cap():
		_cap_reached()
		return
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		Sfx.play("pc_nivel")
		skill_points += 1
		var old_hp := hp
		recompute_stats(false)
		hp = minf(max_hp, old_hp + max_hp * 0.3)
		EventBus.player_leveled.emit(level)
		_msg("Nível %d! PV, Energia e Seda máximos aumentaram. +1 Ponto de Habilidade (gaste no casulo)." % level)
		if can_evolve():
			EventBus.big_message.emit("Pronta para evoluir!")
			_msg("Descanse num casulo (E) para fazer a muda e virar a Cavaleira de Seda.")
			GameState.say_once("pronta_evoluir", "Tá coçando tudo... minha casca tá apertada. Preciso de um casulo. AGORA.")
		if level == TRAP_LEVEL:
			GameState.say_once("nivel_3", "Nível 3! Sinto que consigo tecer uma teia de captura. Modo Tecelagem e botão direito.")
		if at_level_cap():
			_cap_reached()
			break


func xp_to_next() -> int:
	return 30 * level


# ================================================================= percepção (usada pelas criaturas)

func noise_radius() -> float:
	return noise


func refresh_sight() -> void:
	if _sight_light != null:
		_sight_light.omni_range = sight_radius()


func sight_radius() -> float:
	## Até onde ela enxerga no escuro (cresce com a evolução; runa acesa ajuda).
	return float(form_data().get("sight", 4.0)) + (1.5 if has_skill("olhos") else 0.0) + dark_sight - sight_penalty + daylight * 9.0


func visibility_mult() -> float:
	if veil_t > 0.0:
		return 0.0
	if fd("shadow", false) and not rune_on and daylight < 0.3 and Vector2(velocity.x, velocity.z).length() < 0.8:
		return 0.0   # Sombra do Breu: parada no escuro, ninguém vê (só encostando ou ouvindo)
	var v := (1.0 if rune_on else 0.45) * float(form_data()["hide"])
	if daylight > 0.0:   # na luz do dia a runa não importa: ela aparece de longe
		v = maxf(v, lerpf(v, 1.6, daylight) * float(form_data()["hide"]))
	return v


# ================================================================= mira, câmera, visual

func shake(amount: float) -> void:
	## Tremor de câmera (a Mãe batendo no túnel, desabamento).
	if not Settings.screen_shake:
		return
	_shake = maxf(_shake, amount)


func _update_aim() -> void:
	if autopilot:
		if move_dir.length() > 0.1:
			aim_dir = move_dir.normalized()
		aim_point = global_position + aim_dir * 3.0
		return
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick.length() > 0.3:
		using_stick_aim = true
		aim_dir = Vector3(stick.x, 0.0, stick.y).normalized()
		aim_point = global_position + aim_dir * (2.0 + 10.0 * stick.length())
		return
	if using_stick_aim:
		if move_dir.length() > 0.2:
			aim_dir = move_dir.normalized()
		aim_point = global_position + aim_dir * 3.0
		return
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var normal := camera.project_ray_normal(mouse)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(origin, normal)
	if hit != null:
		aim_point = hit
		var d: Vector3 = aim_point - global_position
		d.y = 0.0
		if d.length() > 0.2:
			aim_dir = d.normalized()


func _update_camera(real_dt: float, snap: bool) -> void:
	var look := global_position
	if not using_stick_aim and not weaving and not dead:
		look += aim_dir * clampf(Fx.flat_dist(aim_point, global_position) * 0.2, 0.0, 2.5)
	if cam_focus_time > 0.0:
		cam_focus_time -= real_dt
		look = look.lerp(cam_focus, 0.7)
		real_dt *= 0.35   # pan mais lento, de cinema
	var forward := -camera.global_transform.basis.z
	var target := look - forward * 40.0
	if snap:
		camera.global_position = target
	else:
		camera.global_position = camera.global_position.lerp(target, clampf(real_dt * 6.0, 0.0, 1.0))
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - real_dt * 1.8)
		camera.global_position += Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)) * _shake * 0.6
	var want_size := cam_zoom if cam_zoom > 0.0 else (28.0 if weaving else 18.0)
	camera.size = lerpf(camera.size, want_size, clampf(real_dt * (1.5 if cam_zoom > 0.0 else 4.0), 0.0, 1.0))


func _update_visual(delta: float) -> void:
	if dead:
		return
	var face := _zip_dir if state == State.ZIP else aim_dir
	_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-face.x, -face.z), clampf(delta * 14.0, 0.0, 1.0))
	if _spin > 0.0:
		_spin = maxf(0.0, _spin - delta)
		_visual.rotation.y = atan2(-aim_dir.x, -aim_dir.z) + TAU * (1.0 - _spin / SPIN_TIME)
	_leg_rig.velocity_hint = Vector3(velocity.x, 0.0, velocity.z)
	# o corpo sobe um pouquinho a cada grupo de patas que pousa
	var spd := Vector2(velocity.x, velocity.z).length()
	if state != State.ZIP:
		_visual.position.y = absf(sin(_leg_rig.phase * TAU)) * 0.03 * clampf(spd / 4.0, 0.0, 1.0)

	# Runa = Energia (e luz). Apagada = furtiva.
	var e := energy / max_energy
	var flicker := 1.0
	if e < 0.25:
		flicker = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.02)
	_rune_mat.emission_energy_multiplier = (0.4 + 3.0 * e) * flicker if rune_on else 0.1
	_rune_light.visible = rune_on
	_rune_light.light_energy = (1.0 + 1.8 * e) * flicker

	# Cachecol = Seda
	var s := 0.15 + 0.75 * silk / max_silk
	_scarf_tail.scale.z = s
	_scarf_tail.position.z = 0.1 + s * 0.5

	# Abdômen = Saciedade
	var a := 0.82 + 0.3 * satiety / max_satiety
	_abdomen.scale = Vector3(a, a, a)

	# Placas = PV
	var plates_left := ceili(4.0 * hp / max_hp)
	for i in _plates.size():
		_plates[i].visible = i < plates_left

	_update_swing(delta)
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	_body_mat.emission_enabled = _hurt_flash > 0.0
	_body_mat.emission = Color(1.0, 0.2, 0.2)
	if _model_overlay != null:
		_model_overlay.albedo_color.a = 0.5 if _hurt_flash > 0.0 else 0.0
	if state == State.DODGE:
		_visual.scale = Vector3(1.15, 0.7, 1.15) * vis_scale
	elif state == State.EAT:
		_visual.scale = Vector3(1.0, 0.85 + 0.1 * sin(state_time * 25.0), 1.0) * vis_scale
	else:
		_visual.scale = Vector3.ONE * vis_scale


# ================================================================= utilidades

func _msg(text: String) -> void:
	if text.begins_with("Sem ") or text.contains("insuficiente"):
		Sfx.play("ui_erro", Vector3.INF, 0.0, 0.0, 0.3)   # sem seda, sem energia...
	EventBus.message.emit(text)


func _has_floor(pos: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 1.0, pos + Vector3.DOWN * 1.0, 1)
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _anchor_near(point: Vector3, radius: float) -> WebAnchor:
	var best: WebAnchor = null
	var best_d := radius
	for n in get_tree().get_nodes_in_group("anchor"):
		var a := n as WebAnchor
		if a == null:
			continue
		var d := Fx.flat_dist(a.global_position, point)
		if d < best_d:
			best = a
			best_d = d
	return best


func _nearest_interactable(radius: float) -> Node3D:
	## Objetos com interact(player): anotações, cristais de lore...
	var best: Node3D = null
	var best_d := radius
	for n in get_tree().get_nodes_in_group("interactable"):
		var o := n as Node3D
		if o == null or not o.has_method("interact"):
			continue
		var d := Fx.flat_dist(o.global_position, global_position)
		if d <= best_d:
			best = o
			best_d = d
	return best


func _nearest_cocoon(radius: float) -> Cocoon:
	for c in WebNetwork.cocoons:
		if is_instance_valid(c) and Fx.flat_dist(c.global_position, global_position) <= radius:
			return c
	return null


func _nearest_corpse(radius: float) -> Corpse:
	var best: Corpse = null
	var best_d := radius
	for n in get_tree().get_nodes_in_group("corpse"):
		var c := n as Corpse
		if c == null:
			continue
		var d := Fx.flat_dist(c.global_position, global_position)
		if d < best_d:
			best = c
			best_d = d
	return best


# ================================================================= save

func to_dict() -> Dictionary:
	return {
		"hp": hp, "max_hp": max_hp,
		"energy": energy, "max_energy": max_energy,
		"silk": silk, "max_silk": max_silk,
		"satiety": satiety,
		"level": level, "xp": xp, "resist_rot": resist_rot,
		"resist_acid": resist_acid, "crystal_skin": crystal_skin, "moonstones": moonstones, "attack_style": attack_style,
		"resist_poison": resist_poison, "dark_sight": dark_sight, "weave_xp": weave_xp,
		"resist_fire": resist_fire, "heat_exposure": heat_exposure,
		"form": int(form), "pending": pending_form, "bonus": [bonus_hp, bonus_energy, bonus_silk],
		"respawn": [respawn_pos.x, respawn_pos.y, respawn_pos.z], "rested": rested_here,
		"skills": skills.keys(), "sp": skill_points, "bag": bag, "shards": rune_shards,
	}


func apply_carry(d: Dictionary) -> void:
	## Atributos vindos da camada anterior (sem posição: a jogadora entra pela entrada da camada).
	var keep := respawn_pos
	from_dict(d)
	respawn_pos = keep
	rested_here = false   # camada nova: ainda sem casulo aqui
	global_position = keep
	last_safe_pos = keep
	snap_camera()


func from_dict(d: Dictionary) -> void:
	max_hp = float(d.get("max_hp", max_hp))
	hp = float(d.get("hp", hp))
	max_energy = float(d.get("max_energy", max_energy))
	energy = float(d.get("energy", energy))
	max_silk = float(d.get("max_silk", max_silk))
	silk = float(d.get("silk", silk))
	satiety = float(d.get("satiety", satiety))
	level = int(d.get("level", level))
	xp = int(d.get("xp", xp))
	resist_rot = int(d.get("resist_rot", resist_rot))
	resist_acid = int(d.get("resist_acid", resist_acid))
	resist_poison = int(d.get("resist_poison", resist_poison))
	dark_sight = float(d.get("dark_sight", dark_sight))
	weave_xp = int(d.get("weave_xp", weave_xp))
	resist_fire = int(d.get("resist_fire", resist_fire))
	heat_exposure = float(d.get("heat_exposure", heat_exposure))
	crystal_skin = bool(d.get("crystal_skin", crystal_skin))
	moonstones = int(d.get("moonstones", moonstones))
	attack_style = int(d.get("attack_style", attack_style))
	form = int(d.get("form", form)) as Form
	pending_form = int(d.get("pending", pending_form))
	if d.has("skills"):
		skills = {}
		for k in d["skills"]:
			if Skills.ALL.has(String(k)):
				skills[String(k)] = true
		skills["fiandeira"] = true
	if d.has("sp"):
		skill_points = int(d["sp"])
	elif d.has("level"):
		# save de antes das habilidades: devolve os pontos dos níveis já ganhos
		skill_points = (level - 1) + _levels_before()
	rune_shards = int(d.get("shards", 0))
	var ba = d.get("bag", d.get("pantry", []))   # save antigo: a despensa vira a bolsa (só cabem 2)
	if ba is Array:
		bag = (ba as Array).slice(0, BAG_MAX).duplicate(true)
	var b: Array = d.get("bonus", [])
	if b.size() == 3:
		bonus_hp = float(b[0])
		bonus_energy = float(b[1])
		bonus_silk = float(b[2])
	if not d.has("form"):
		# save de antes das formas (v0.6 ou anterior): recalcula pela forma de Filhote
		recompute_stats(false)
	_apply_form_visual()
	rested_here = bool(d.get("rested", false))
	var r: Array = d.get("respawn", [])
	if r.size() == 3:
		respawn_pos = Vector3(float(r[0]), float(r[1]), float(r[2]))
		global_position = respawn_pos
		last_safe_pos = respawn_pos
	snap_camera()
