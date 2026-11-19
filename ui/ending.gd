class_name Ending
extends CanvasLayer
## O final: ela sai da caverna. A cena (pintada aqui, em 2D) muda conforme o ramo da forma
## dela, e o epílogo tem um parágrafo próprio de cada forma. No fim, uma pista da história
## de antes da caverna, os números da jornada e os créditos.
## Enter / clique / A: adianta. No último "Fim", volta ao menu inicial.

const ART := "res://assets/ui/cavaleira_recorte.png"   ## a arte dela recortada (sem o fundo)
const W := 1600.0
const H := 900.0

## Cena por ramo: céu (cima, horizonte), sol/lua, cor das montanhas, título.
const SCENES := {
	"Lâmina": {"sky": [Color(0.32, 0.12, 0.2), Color(1.0, 0.55, 0.3)], "sun": Color(1.0, 0.75, 0.45), "sun_y": 0.36,
		"hills": Color(0.2, 0.08, 0.12), "title": "Final da Lâmina", "sub": "O vale ao amanhecer"},
	"Teia": {"sky": [Color(0.42, 0.55, 0.62), Color(0.9, 0.92, 0.85)], "sun": Color(1.0, 0.97, 0.85), "sun_y": 0.4,
		"hills": Color(0.16, 0.28, 0.24), "title": "Final da Teia", "sub": "A floresta de manhã"},
	"Runa": {"sky": [Color(0.02, 0.03, 0.1), Color(0.12, 0.2, 0.38)], "sun": Color(0.85, 0.92, 1.0), "sun_y": 0.25,
		"hills": Color(0.03, 0.04, 0.09), "title": "Final da Runa", "sub": "A noite de cima"},
	"Rara": {"sky": [Color(0.05, 0.03, 0.12), Color(0.3, 0.22, 0.42)], "sun": Color(0.95, 0.95, 1.0), "sun_y": 0.3,
		"hills": Color(0.05, 0.04, 0.1), "title": "Final raro", "sub": "A lua sobre a boca da caverna"},
	"": {"sky": [Color(0.3, 0.38, 0.6), Color(1.0, 0.82, 0.55)], "sun": Color(1.0, 0.9, 0.6), "sun_y": 0.58,
		"hills": Color(0.15, 0.14, 0.22), "title": "Final", "sub": "O primeiro sol"},
}
const RARE_TINT := {"Fogo": Color(1.0, 0.55, 0.3), "Escuridão": Color(0.6, 0.45, 0.95), "Veneno": Color(0.55, 1.0, 0.5),
	"Ácido": Color(0.85, 1.0, 0.4), "Pedra-da-lua": Color(0.75, 0.88, 1.0)}

const SCENE_TEXT := {
	"Lâmina": "Lá fora, o sol nasce vermelho sobre um vale enorme. As lâminas de cristal dela brilham como duas brasas. Ao longe, fumaça de chaminés: a vila de onde a expedição veio. Ela não tem pressa. Agora quem caça é ela.",
	"Teia": "A manhã sai cinza e molhada. Entre duas árvores (ÁRVORES!) ela estica o primeiro fio do mundo de cima, e o sol acende cada gota de orvalho como uma conta de vidro. A floresta inteira é um salão esperando para ser tecido.",
	"Runa": "Ela sai à noite. O céu é tão grande que dá vertigem, e no meio das estrelas tem uma espiral: a mesma da runa nas costas dela. Ela não sabe por quê. Mas a espiral parece saber dela.",
	"Rara": "A lua está enorme sobre a boca da caverna, e a luz dela pega a cor do que ela virou lá embaixo. Nenhuma aranha da caverna saiu assim antes. Talvez nenhuma aranha do mundo.",
	"": "O sol nasce. Ela ainda é pequena, mas é a primeira coisa da caverna a ver isso. E o mundo de cima é ainda maior do que o de baixo.",
}
const FORM_TEXT := {
	"Filhote de Seda": "Saiu do jeito que nasceu: pequena, rápida e sem pedir licença. Ninguém vai acreditar que uma filhote atravessou a Fenda inteira. Ela mesma não acredita.",
	"Cavaleira de Seda": "A Cavaleira de Seda sai sem ter escolhido um caminho só. Ainda dá tempo de escolher: lá fora, tudo é novo.",
	"Ceifadora de Seda": "A Ceifadora corta o primeiro capim que vê, só para saber como é. É macio. Ela ri, se é que aranhas riem.",
	"Tecelã do Abismo": "A Tecelã olha para o espaço entre as coisas e já vê os fios que vão estar ali. Lá fora tem espaço demais. Que bom.",
	"Arauta da Runa": "A Arauta sente a runa esquentar sob o céu aberto, como se finalmente estivesse no lugar dela.",
	"Executora de Seda": "A Executora não volta para a caverna. Nas vilas, contam de uma sombra que derruba lobos com um golpe só e nunca encosta numa criança.",
	"Bastiã de Pedra": "A Bastiã de Pedra fica. Faz do Portão a casa dela, no lugar do dragão: quem sai, passa. Quem entra para caçar, não.",
	"Senhora das Teias": "A Senhora das Teias tece uma rede do tamanho da floresta. Em um ano, os pássaros aprendem a desviar. Em dois, ela aprende o nome deles.",
	"Saltadora do Vento": "A Saltadora do Vento descobre que o vento lá fora não tem parede. Ela solta um fio e voa. Ninguém da caverna jamais voou.",
	"Vidente da Runa": "A Vidente olha para o céu e vê caminhos. Um deles leva de volta para antes da caverna. Ela ainda não está pronta para segui-lo.",
	"Sacerdotisa da Tempestade": "Na primeira chuva, a Sacerdotisa sobe na pedra mais alta e chama o raio. O raio vem. A vila lá embaixo acha que viu um deus. Ela acha graça.",
	"Seda Ardente": "A Seda Ardente deixa um rastro de brasa no orvalho. Por onde ela passa, nasce capim novo na primavera seguinte.",
	"Sombra do Breu": "A Sombra do Breu não gosta do sol. Ela espera a noite, e a noite a recebe como se ela sempre tivesse sido de lá.",
	"Viúva de Seda": "A Viúva de Seda descobre que, lá fora, veneno também é remédio. As curandeiras da vila começam a deixar oferendas na boca da caverna.",
	"Corrosiva": "A Corrosiva derrete a corrente do portão ao passar, para ninguém nunca mais fechá-lo.",
	"Cavaleira de Pedra-da-lua": "A Cavaleira de Pedra-da-lua brilha mais forte quando a lua sobe. As quatro pedras nas costas dela desenham uma constelação que ninguém tinha batizado.",
}
const MEMORY := "E, por um segundo, com o vento de fora no rosto, ela lembra de uma janela, do barulho da chuva num telhado e de um nome que não é o dela. Depois o vento leva embora."
const QUESTION := "Quem eu era, antes da caverna?"
const CREDITS := [
	["title", "CAVALEIRA DE SEDA"],
	["small", "Um fangame gratuito inspirado em Kumo desu ga, Nani ka? (Okina Baba)"],
	["gap", ""],
	["head", "Criação, direção e arte"], ["name", "Felipe AG"],
	["head", "Programação"], ["name", "Claude (Anthropic)"],
	["head", "Música e efeitos sonoros"], ["name", "Gerados em Python a partir dos prompts do GDD"],
	["head", "Modelos 3D"], ["name", "Hunyuan 3D, com as patas e o resto feitos no Godot"],
	["head", "Fontes"], ["name", "Cinzel e Alegreya Sans (SIL Open Font License)"],
	["head", "Motor"], ["name", "Godot Engine 4.7"],
	["gap", ""],
	["small", "Obrigado por jogar."],
]

var data := {}
var _canvas: Control
var _hero: TextureRect
var _t := 0.0
var _stage := 0          ## 0 cena e textos, 1 créditos, 2 fim
var _shown := 0          ## quantos blocos de texto já apareceram
var _shown_t := 0.0
var _blocks: Array = []  ## [texto, estilo]
var _credit_y := 0.0
var _stars: Array = []
var _rng := RandomNumberGenerator.new()


func setup(p: Player) -> Ending:
	var fd: Dictionary = p.form_data()
	var branch := String(fd.get("branch", ""))
	data = {
		"form": String(fd.get("name", "Cavaleira de Seda")),
		"branch": branch if SCENES.has(branch) else "",
		"rare": String(fd.get("rare", "")),
		"level": p.level,
		"seen": Bestiary.count_seen(),
		"total": Bestiary.entries().size(),
		"moon": p.moonstones,
	}
	return self


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Music.area("menu")
	_rng.seed = 7
	for i in 140:
		_stars.append([Vector2(_rng.randf() * W, _rng.randf() * H * 0.6), _rng.randf_range(0.6, 2.0), _rng.randf() * TAU])
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_paint)
	_canvas.gui_input.connect(_on_click)
	add_child(_canvas)
	_hero = TextureRect.new()
	_hero.texture = load(ART)
	_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero.stretch_mode = TextureRect.STRETCH_SCALE
	_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_hero)
	var sc: Dictionary = SCENES[data.get("branch", "")]
	_blocks = [
		[String(sc["title"]).to_upper() + "  ·  " + String(sc["sub"]), "head"],
		[SCENE_TEXT[data.get("branch", "")], "body"],
		[FORM_TEXT.get(data.get("form", ""), FORM_TEXT["Cavaleira de Seda"]), "body"],
		[MEMORY, "memory"],
		[QUESTION, "question"],
		["%s  ·  nível %d  ·  Bestiário %d de %d%s" % [data["form"], data["level"], data["seen"], data["total"],
			("  ·  Pedras-da-lua %d" % data["moon"]) if int(data["moon"]) > 0 else ""], "stats"],
	]
	_shown_t = 2.5


func _process(delta: float) -> void:
	_t += delta
	if _stage == 0:
		_shown_t -= delta
		if _shown_t <= 0.0 and _shown < _blocks.size():
			_shown += 1
			_shown_t = 4.5 if _shown < 4 else 3.0
	elif _stage == 1:
		_credit_y += delta * 55.0
		if _credit_y > _credits_height() + H * 0.7:
			_stage = 2
	_canvas.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("attack") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		advance()


func _on_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()


func advance() -> void:
	## Adianta: mostra o próximo texto; depois créditos; depois o fim volta ao menu.
	if _t < 1.0:
		return
	match _stage:
		0:
			if _shown < _blocks.size():
				_shown += 1
				_shown_t = 4.5
			else:
				_stage = 1
				_credit_y = 0.0
		1:
			_stage = 2
		2:
			get_tree().paused = false
			queue_free()
			GameState.to_title()


func _credits_height() -> float:
	return CREDITS.size() * 46.0 + 200.0


# ---------------------------------------------------------------- desenho

func _paint() -> void:
	var vp := _canvas.get_viewport_rect().size
	var k := minf(vp.x / W, vp.y / H)
	var off := (vp - Vector2(W, H) * k) * 0.5
	_canvas.draw_rect(Rect2(Vector2.ZERO, vp), Color.BLACK)
	_canvas.draw_set_transform(off, 0.0, Vector2(k, k))
	_paint_scene()
	if _stage == 0:
		_draw_texts()
	else:
		_canvas.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.72))
		_draw_credits()
	# entra saindo do branco (a luz lá de fora)
	var white := clampf(1.0 - _t / 2.2, 0.0, 1.0)
	if white > 0.0:
		_canvas.draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, white))
	_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _paint_scene() -> void:
	var branch: String = data.get("branch", "")
	var sc: Dictionary = SCENES[branch]
	var top: Color = sc["sky"][0]
	var hor: Color = sc["sky"][1]
	var tint: Color = RARE_TINT.get(data.get("rare", ""), Color.WHITE)
	if branch == "Rara":
		hor = hor.lerp(tint, 0.35)
	# céu em faixas
	for i in 40:
		var y := i * H * 0.7 / 40.0
		_canvas.draw_rect(Rect2(0, y, W, H * 0.7 / 40.0 + 1.0), top.lerp(hor, pow(float(i) / 39.0, 1.4)))
	_canvas.draw_rect(Rect2(0, H * 0.7, W, H * 0.3), hor.darkened(0.2))
	# estrelas (noite e lua)
	if branch == "Runa" or branch == "Rara":
		for s in _stars:
			var tw := 0.5 + 0.5 * sin(_t * 1.5 + float(s[2]))
			_canvas.draw_circle(s[0], float(s[1]), Color(1, 1, 1, 0.35 + 0.5 * tw))
	if branch == "Runa":
		_rune_constellation(Vector2(1060, 230), 120.0)
	# sol ou lua
	var sun_c := Vector2(W * 0.68, H * float(sc["sun_y"]))
	var sun_col: Color = sc["sun"]
	if branch == "Rara":
		sun_col = sun_col.lerp(tint, 0.5)
	var rise := clampf(_t / 8.0, 0.0, 1.0)
	sun_c.y += (1.0 - rise) * 40.0
	var r := 70.0 if branch in ["Rara", "Runa"] else 58.0
	if branch != "Runa":
		for i in 6:
			_canvas.draw_circle(sun_c, r + i * 26.0, Color(sun_col, 0.07))
		_canvas.draw_circle(sun_c, r, sun_col)
	# montanhas: duas camadas
	var hills: Color = sc["hills"]
	_hills(H * 0.62, 70.0, 0.004, hills.lerp(hor, 0.45), 1.3)
	_hills(H * 0.72, 90.0, 0.006, hills, 3.7)
	if branch == "Lâmina":
		for i in 9:   # luzes da vila ao longe
			var x := 1180.0 + i * 16.0 + sin(i * 2.1) * 6.0
			_canvas.draw_circle(Vector2(x, H * 0.705 + sin(i) * 4.0), 2.2, Color(1.0, 0.8, 0.45, 0.8))
		_canvas.draw_line(Vector2(1230, H * 0.69), Vector2(1250, H * 0.55), Color(0.5, 0.45, 0.5, 0.3), 6.0)
	if branch == "Teia":
		_trees_and_web()
	# pássaros (a lembrança do ninho)
	if branch != "Runa":
		for i in 5:
			var bx := fposmod(300.0 + i * 140.0 + _t * (22.0 + i * 3.0), W + 200.0) - 100.0
			var by := 180.0 + i * 26.0 + sin(_t * 2.0 + i) * 8.0
			var flap := sin(_t * 9.0 + i) * 5.0
			var bc := Color(0.1, 0.08, 0.12, 0.8)
			_canvas.draw_line(Vector2(bx - 10, by - flap), Vector2(bx, by), bc, 2.0, true)
			_canvas.draw_line(Vector2(bx, by), Vector2(bx + 10, by - flap), bc, 2.0, true)
	# a boca da caverna (moldura escura) e o rochedo onde ela está
	var rock := hills.darkened(0.55)
	var cliff := PackedVector2Array([Vector2(0, H), Vector2(0, H * 0.74), Vector2(260, H * 0.76), Vector2(520, H * 0.8),
		Vector2(700, H * 0.86), Vector2(760, H)])
	_canvas.draw_colored_polygon(cliff, rock)
	var arch := PackedVector2Array([Vector2(0, 0), Vector2(220, 0), Vector2(150, 120), Vector2(90, 330), Vector2(70, H * 0.74), Vector2(0, H * 0.74)])
	_canvas.draw_colored_polygon(arch, rock.darkened(0.3))
	var arch2 := PackedVector2Array([Vector2(W, 0), Vector2(W - 180, 0), Vector2(W - 110, 90), Vector2(W - 60, 260), Vector2(W, 300)])
	_canvas.draw_colored_polygon(arch2, rock.darkened(0.3))
	# ela, no rochedo, olhando o mundo
	var art: Texture2D = load(ART) as Texture2D
	if art != null:
		var hgt := 230.0
		var wdt := hgt * art.get_size().x / art.get_size().y
		var feet := Vector2(400, H * 0.785)
		var shadow := PackedVector2Array()
		for i in 24:
			var ang := i * TAU / 24.0
			shadow.append(feet + Vector2(cos(ang) * wdt * 0.42, 4.0 + sin(ang) * wdt * 0.08))
		_canvas.draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
		var pos := Vector2(feet.x - wdt * 0.5, feet.y - hgt + sin(_t * 1.2) * 2.0)
		var lit := Color(1, 1, 1).lerp(sun_col, 0.25)
		if branch == "Runa":
			lit = Color(0.75, 0.85, 1.0)
		# (a arte vai num TextureRect: desenhada direto aqui ela saía branca em alguns drivers)
		var vp := _canvas.get_viewport_rect().size
		var k := minf(vp.x / W, vp.y / H)
		var off := (vp - Vector2(W, H) * k) * 0.5
		_hero.position = off + pos * k
		_hero.size = Vector2(wdt, hgt) * k
		_hero.modulate = lit


func _hills(base: float, amp: float, freq: float, col: Color, seed_: float) -> void:
	var pts := PackedVector2Array([Vector2(0, H)])
	var x := 0.0
	while x <= W + 20.0:
		var y := base - amp * (0.5 + 0.3 * sin(x * freq + seed_) + 0.2 * sin(x * freq * 2.7 + seed_ * 1.7) + 0.1 * sin(x * freq * 6.1 + seed_ * 3.1))
		pts.append(Vector2(x, y))
		x += 20.0
	pts.append(Vector2(W, H))
	_canvas.draw_colored_polygon(pts, col)


func _trees_and_web() -> void:
	## Teia: duas árvores à direita e o primeiro fio do mundo de cima, com orvalho.
	var trunk := Color(0.1, 0.12, 0.1)
	for tx in [760.0, 1020.0]:
		_canvas.draw_rect(Rect2(tx - 14, H * 0.38, 28, H * 0.62), trunk)
		for i in 5:
			_canvas.draw_circle(Vector2(tx + sin(i * 2.0) * 40.0, H * 0.36 - i * 34.0), 70.0 - i * 6.0, Color(0.12, 0.2, 0.15))
	var c := Vector2(890, H * 0.4)
	var silk := Color(1, 1, 1, 0.55)
	var spokes := 10
	for i in spokes:
		var a := i * TAU / spokes
		_canvas.draw_line(c, c + Vector2(cos(a) * 120.0, sin(a) * 95.0), silk, 1.2, true)
	for ring in 6:
		var rr := 18.0 + ring * 18.0
		var pts := PackedVector2Array()
		for i in spokes + 1:
			var a := i * TAU / spokes
			pts.append(c + Vector2(cos(a) * rr, sin(a) * rr * 0.8))
		_canvas.draw_polyline(pts, silk, 1.0, true)
	for i in 14:
		var a := i * 1.7
		var rr2 := 20.0 + fposmod(i * 37.0, 100.0)
		var p := c + Vector2(cos(a) * rr2, sin(a) * rr2 * 0.8)
		var tw := 0.5 + 0.5 * sin(_t * 3.0 + i)
		_canvas.draw_circle(p, 2.5, Color(1.0, 1.0, 0.9, 0.5 + 0.5 * tw))


func _rune_constellation(c: Vector2, r: float) -> void:
	## Runa: a espiral nas estrelas, acendendo devagar.
	var n := 14
	var lit := clampf((_t - 3.0) / 6.0, 0.0, 1.0)
	var prev := Vector2.ZERO
	for i in n:
		var k := float(i) / float(n - 1)
		var a := k * TAU * 2.2
		var p := c + Vector2(cos(a), sin(a)) * r * (0.12 + 0.88 * k)
		if i > 0 and k <= lit:
			_canvas.draw_line(prev, p, Color(0.5, 0.85, 1.0, 0.5), 1.4, true)
		_canvas.draw_circle(p, 3.0 if k <= lit else 1.6, Color(0.7, 0.92, 1.0, 0.9 if k <= lit else 0.4))
		prev = p


func _draw_texts() -> void:
	## Os textos sobem do lado direito, numa faixa escura.
	if _shown <= 0:
		return
	## Faixa embaixo à direita, crescendo para cima conforme os textos aparecem (o céu fica livre).
	var x := 660.0
	var wdt := 860.0
	var panel_h := 0.0
	for i in mini(_shown, _blocks.size()):
		panel_h += _block_h(_blocks[i], wdt) + 18.0
	var y := H - 60.0 - panel_h + 26.0
	_canvas.draw_rect(Rect2(x - 36, y - 46, wdt + 72, panel_h + 60), Color(0.0, 0.0, 0.03, 0.6))
	SilkUI.frame(_canvas, Rect2(x - 36, y - 46, wdt + 72, panel_h + 60), Color(SilkUI.GOLD, 0.35))
	for i in mini(_shown, _blocks.size()):
		var b: Array = _blocks[i]
		var a := 1.0 if i < _shown - 1 else clampf((4.5 - _shown_t) / 1.2, 0.0, 1.0)
		y = _block(b, Vector2(x, y), wdt, a) + 18.0
	if _shown >= _blocks.size():
		SilkUI.text(_canvas, Vector2(W - 60, H - 16), "Enter: créditos", "body_m", 16, Color(1, 1, 1, 0.5 + 0.3 * sin(_t * 3.0)), HORIZONTAL_ALIGNMENT_RIGHT)


func _style(st: String) -> Array:
	## [fonte, tamanho, cor, altura da linha]
	match st:
		"head":
			return ["title_s", 22, SilkUI.GOLD, 30.0]
		"memory":
			return ["body", 21, Color(0.85, 0.88, 1.0), 29.0]
		"question":
			return ["title", 28, SilkUI.CYAN, 36.0]
		"stats":
			return ["body_m", 17, Color(1, 1, 1, 0.6), 24.0]
	return ["body_m", 23, Color(0.96, 0.95, 0.92), 32.0]


func _block_h(b: Array, wdt: float) -> float:
	var st := _style(b[1])
	return _wrap(String(b[0]), st[0], int(st[1]), wdt).size() * float(st[3])


func _block(b: Array, p: Vector2, wdt: float, alpha: float) -> float:
	var st := _style(b[1])
	var col: Color = st[2]
	col.a *= alpha
	var y := p.y
	for line in _wrap(String(b[0]), st[0], int(st[1]), wdt):
		SilkUI.text(_canvas, Vector2(p.x, y), line, st[0], int(st[1]), col, HORIZONTAL_ALIGNMENT_LEFT, 3)
		y += float(st[3])
	return y


func _wrap(t: String, f: String, size_: int, wdt: float) -> Array:
	var out: Array = []
	var cur := ""
	for word in t.split(" "):
		var test := word if cur == "" else cur + " " + word
		if cur != "" and SilkUI.text_width(test, f, size_) > wdt:
			out.append(cur)
			cur = word
		else:
			cur = test
	if cur != "":
		out.append(cur)
	return out


func _draw_credits() -> void:
	if _stage == 2:
		SilkUI.text(_canvas, Vector2(W * 0.5, H * 0.48), "FIM", "title", 72, Color(1, 1, 1, 0.92), HORIZONTAL_ALIGNMENT_CENTER, 4)
		SilkUI.rune(_canvas, Vector2(W * 0.5, H * 0.58), 18.0, Color(SilkUI.CYAN, 0.8), _t * 0.5)
		SilkUI.text(_canvas, Vector2(W * 0.5, H - 60), "Enter: voltar ao menu", "body_m", 18, Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_CENTER)
		return
	var y := H + 40.0 - _credit_y
	for c in CREDITS:
		match c[0]:
			"title":
				SilkUI.text(_canvas, Vector2(W * 0.5, y), c[1], "title", 54, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER, 4)
				y += 70.0
			"small":
				SilkUI.text(_canvas, Vector2(W * 0.5, y), c[1], "body_m", 20, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER, 3)
				y += 40.0
			"head":
				SilkUI.text(_canvas, Vector2(W * 0.5, y), c[1].to_upper(), "title_s", 16, SilkUI.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 3)
				y += 26.0
			"name":
				SilkUI.text(_canvas, Vector2(W * 0.5, y), c[1], "body_m", 24, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER, 3)
				y += 46.0
			_:
				y += 40.0
