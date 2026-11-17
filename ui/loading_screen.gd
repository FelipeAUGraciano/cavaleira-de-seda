class_name LoadingScreen
extends CanvasLayer
## Tela de carregamento entre camadas: fundo preto, uma teia sendo tecida no meio (ela é a
## barra de progresso), um título pequeno em cima ("Fim do prólogo") e dicas embaixo.
## Carrega a cena em segundo plano, troca e some devagar enquanto a camada nova clareia.

const MIN_TIME := 3.2             ## fica pelo menos isso na tela (dá tempo de ler)
const GOLD := Color(0.93, 0.86, 0.68)
const TIPS := [
	"Seda não volta sozinha: coma ou descanse na toca.",
	"Andar no fio é rápido e silencioso. E é o único jeito de cruzar o abismo.",
	"Runa apagada: você some no escuro, mas a Energia para de voltar.",
	"Bicho grande arrebenta fio. Bicho médio fica preso só um instante.",
	"Um fio aguenta três presas pequenas. A quarta arrebenta tudo.",
	"Presa pequena se embrulha onde estiver. Presa grande vai arrastada até a toca.",
	"A seta em volta da aranha aponta de onde a sua teia vibrou.",
	"Parada no escuro, quase ninguém te encontra. Quase.",
	"Com fome, os bichos insistem. De barriga cheia, desistem rápido.",
	"Uma toca com as portas fechadas é o lugar mais seguro da Fenda.",
]

var path := ""
var header := ""
var sub := ""
var _t := 0.0
var _shown := 0.0
var _swapped := false
var _out := -1.0
var _tip := 0
var _tip_t := 0.0
var _cv: Control
var _font: Font
var _serif: Font = preload("res://ui/fonts/Cinzel-Medium.woff2")


func setup(path_: String, header_: String = "", sub_: String = "") -> LoadingScreen:
	path = path_
	header = header_
	sub = sub_
	return self


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("loading_screen")
	_font = ThemeDB.fallback_font
	_cv = Control.new()
	_cv.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cv.mouse_filter = Control.MOUSE_FILTER_STOP
	_cv.draw.connect(_draw)
	add_child(_cv)
	_tip = randi() % TIPS.size()
	if ResourceLoader.load_threaded_request(path) != OK:
		push_warning("carregamento em segundo plano falhou: " + path)


func progress() -> float:
	return _shown


func _process(delta: float) -> void:
	delta = minf(delta, 0.1)
	_t += delta
	_tip_t += delta
	if _tip_t > 5.0:
		_tip_t = 0.0
		_tip = (_tip + 1) % TIPS.size()
	if _out >= 0.0:
		_out += delta
		_cv.modulate.a = clampf(1.0 - (_out - 0.25) / 0.9, 0.0, 1.0)
		_cv.queue_redraw()
		if _out > 1.2:
			queue_free()
		return
	var prog: Array = []
	var st := ResourceLoader.load_threaded_get_status(path, prog)
	var real: float = prog[0] if not prog.is_empty() else 0.0
	if st == ResourceLoader.THREAD_LOAD_LOADED:
		real = 1.0
	elif st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		real = 1.0
	# a teia nunca corre na frente do carregamento nem acaba antes do tempo mínimo
	_shown = move_toward(_shown, minf(real, _t / MIN_TIME), delta * 0.9)
	if not _swapped and _shown >= 0.999 and st != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_swapped = true
		var res = ResourceLoader.load_threaded_get(path) if st == ResourceLoader.THREAD_LOAD_LOADED else null
		if res is PackedScene:
			get_tree().change_scene_to_packed(res)
		else:
			get_tree().change_scene_to_file(path)
		_out = 0.0
	_cv.queue_redraw()


func _draw() -> void:
	var vp := _cv.get_viewport_rect().size
	_cv.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.0, 0.0, 0.0))
	var c := Vector2(vp.x * 0.5, vp.y * 0.52)
	var r := minf(vp.y * 0.13, 110.0)
	var silk := Color(0.85, 0.9, 1.0)
	# raios aparecem primeiro, depois a espiral vai sendo tecida conforme carrega
	var spokes := 12
	var spoke_p := clampf(_shown * 3.0, 0.0, 1.0)
	for i in spokes:
		var a := i * TAU / spokes + 0.13
		var reach := r * clampf(spoke_p * spokes - i, 0.0, 1.0)
		if reach > 0.0:
			_cv.draw_line(c, c + Vector2(cos(a), sin(a)) * reach, Color(silk, 0.35), 1.0, true)
	var turns := 6.0
	var total := int(turns * spokes)
	var upto := int(clampf((_shown - 0.15) / 0.85, 0.0, 1.0) * total)
	var pts := PackedVector2Array()
	for k in upto + 1:
		var a := k * TAU / spokes + 0.13
		var rr := r * (0.12 + 0.86 * float(k) / total)
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	if pts.size() >= 2:
		_cv.draw_polyline(pts, Color(silk, 0.75), 1.4, true)
	# a aranhinha na ponta do fio
	var tip := pts[pts.size() - 1] if pts.size() > 0 else c
	var bob := sin(_t * 9.0) * 1.5
	_cv.draw_circle(tip + Vector2(0, bob), 5.0, Color(0.15, 0.2, 0.35))
	_cv.draw_circle(tip + Vector2(0, bob), 2.4, Color(0.4, 0.95, 1.0, 0.8 + 0.2 * sin(_t * 4.0)))
	for s in [-1.0, 1.0]:
		for k in 4:
			var la: float = (0.5 + k * 0.35) * s
			_cv.draw_line(tip + Vector2(0, bob), tip + Vector2(cos(la) * 9.0 * s, sin(la) * 5.0 + bob), Color(0.15, 0.2, 0.35), 1.2, true)
	if header != "":
		var hw := _serif.get_string_size(header.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		_cv.draw_string(_serif, Vector2(vp.x * 0.5 - hw * 0.5, vp.y * 0.2), header.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(GOLD, 0.95))
		var lw := maxf(hw * 0.7, 160.0)
		_cv.draw_line(Vector2(vp.x * 0.5 - lw * 0.5, vp.y * 0.2 + 14), Vector2(vp.x * 0.5 + lw * 0.5, vp.y * 0.2 + 14), Color(GOLD, 0.4), 1.0, true)
	if sub != "":
		var sw := _font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		_cv.draw_string(_font, Vector2(vp.x * 0.5 - sw * 0.5, vp.y * 0.2 + 44), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.8, 0.8, 0.85, 0.85))
	var pct := "%d%%" % int(round(_shown * 100.0))
	var pw := _serif.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_cv.draw_string(_serif, Vector2(vp.x * 0.5 - pw * 0.5, c.y + r + 34), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(GOLD, 0.7))
	var tip_text: String = TIPS[_tip]
	var ta := clampf(minf(_tip_t, 5.0 - _tip_t) / 0.5, 0.0, 1.0)
	var tw := _font.get_string_size(tip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	_cv.draw_string(_font, Vector2(vp.x * 0.5 - tw * 0.5, vp.y - 70), tip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.75, 0.78, 0.85, 0.9 * ta))
