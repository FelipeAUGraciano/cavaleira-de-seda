class_name SilkUI
extends RefCounted
## A cara do jogo nos menus e na HUD: as cores e fontes do casulo (azul-noite, dourado da
## seda, ciano da runa), botões com fio de seda e moldura com nós nos cantos.

const BG := Color(0.035, 0.04, 0.085)
const PANEL := Color(0.05, 0.06, 0.13, 0.9)
const PANEL_SOFT := Color(0.04, 0.05, 0.1, 0.72)
const BORDER := Color(0.32, 0.42, 0.66, 0.6)
const CYAN := Color(0.45, 0.85, 1.0)
const GOLD := Color(0.95, 0.75, 0.4)
const SILK := Color(0.88, 0.9, 1.0)
const TEXT := Color(0.9, 0.92, 0.98)
const QUIET := Color(0.6, 0.66, 0.8)
const DIM := Color(0.36, 0.41, 0.54)
const DANGER := Color(1.0, 0.55, 0.5)

const FONTS := {
	"title": "res://assets/fonts/cinzel-latin-700-normal.woff",
	"title_s": "res://assets/fonts/cinzel-latin-600-normal.woff",
	"body": "res://assets/fonts/alegreya-sans-latin-400-normal.woff",
	"body_m": "res://assets/fonts/alegreya-sans-latin-500-normal.woff",
	"body_b": "res://assets/fonts/alegreya-sans-latin-700-normal.woff",
}

static var _fonts := {}
static var _theme: Theme = null


static func font(k: String) -> Font:
	if not _fonts.has(k):
		var f = load(FONTS.get(k, FONTS["body"])) if ResourceLoader.exists(FONTS.get(k, "")) else null
		_fonts[k] = f if f is Font else ThemeDB.fallback_font
	return _fonts[k]


static func box(bg: Color, border: Color, width := 1, radius := 6, margin := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	s.anti_aliasing = true
	return s


static func theme() -> Theme:
	## Tema para os Controls dos menus (Opções, listas): fontes do jogo e caixas de seda.
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font("body_m")
	t.default_font_size = 19
	t.set_color("font_color", "Label", TEXT)
	for cls in ["Button", "CheckButton"]:
		t.set_font("font", cls, font("body_b"))
		t.set_color("font_color", cls, TEXT)
		t.set_color("font_hover_color", cls, GOLD)
		t.set_color("font_focus_color", cls, GOLD)
		t.set_color("font_pressed_color", cls, SILK)
		t.set_color("font_disabled_color", cls, DIM)
	t.set_stylebox("normal", "Button", box(Color(0.06, 0.07, 0.15, 0.85), BORDER))
	t.set_stylebox("hover", "Button", box(Color(0.09, 0.1, 0.2, 0.92), GOLD.darkened(0.15)))
	t.set_stylebox("focus", "Button", box(Color(0.09, 0.1, 0.2, 0.92), GOLD, 2))
	t.set_stylebox("pressed", "Button", box(Color(0.13, 0.13, 0.26, 0.95), SILK))
	t.set_stylebox("disabled", "Button", box(Color(0.04, 0.045, 0.09, 0.7), Color(0.18, 0.2, 0.3, 0.6)))
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(st, "CheckButton", empty)
	t.set_stylebox("focus", "CheckButton", box(Color(0, 0, 0, 0), GOLD, 1, 6, 6))
	var track := box(Color(0.1, 0.12, 0.22), BORDER, 1, 4, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	var fill := box(CYAN.darkened(0.3), CYAN.darkened(0.3), 1, 4, 0)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_stylebox("panel", "PanelContainer", box(PANEL, BORDER, 1, 10, 26))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	_theme = t
	return t


# ------------------------------------------------------------ desenho

static func knot(ci: CanvasItem, p: Vector2, col: Color, r := 3.5) -> void:
	## Nó de seda: um losango pequeno com um ponto de luz.
	var pts := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)])
	ci.draw_colored_polygon(pts, col)
	ci.draw_circle(p, r * 0.35, Color(1, 1, 1, col.a * 0.8))


static func frame(ci: CanvasItem, r: Rect2, col: Color, fill := Color(0, 0, 0, 0), width := 1.2) -> void:
	## Moldura de seda: retângulo fino com fios que passam dos cantos e nós nas pontas.
	if fill.a > 0.0:
		ci.draw_rect(r, fill)
	ci.draw_rect(r, col, false, width, true)
	var e := 10.0
	var c := Color(col.r, col.g, col.b, col.a * 0.55)
	for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var sx := -1.0 if corner.x <= r.position.x + 0.1 else 1.0
		var sy := -1.0 if corner.y <= r.position.y + 0.1 else 1.0
		ci.draw_line(corner, corner + Vector2(sx * e, 0), c, width, true)
		ci.draw_line(corner, corner + Vector2(0, sy * e), c, width, true)
		knot(ci, corner, col, 3.0)


static func thread(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, sag := 6.0, width := 1.2) -> void:
	## Fio de seda levemente caído entre dois pontos.
	var pts := PackedVector2Array()
	for i in 17:
		var k := i / 16.0
		pts.append(a.lerp(b, k) + Vector2(0, sin(k * PI) * sag))
	ci.draw_polyline(pts, col, width, true)


static func rune(ci: CanvasItem, c: Vector2, r: float, col: Color, t := 0.0) -> void:
	## A espiral da runa (a mesma das costas da Cavaleira e do Santuário).
	var pts := PackedVector2Array()
	var turns := 2.6
	for i in 64:
		var k := i / 63.0
		var a := k * TAU * turns + t
		pts.append(c + Vector2(cos(a), sin(a)) * r * (0.12 + 0.88 * k))
	ci.draw_polyline(pts, col, maxf(1.2, r * 0.09), true)
	ci.draw_arc(c, r * 1.12, 0.0, TAU, 48, Color(col.r, col.g, col.b, col.a * 0.35), maxf(1.0, r * 0.05), true)
	ci.draw_circle(c, r * 0.12, Color(1, 1, 1, col.a))


static func text(ci: CanvasItem, p: Vector2, s: String, f: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, outline := 0) -> void:
	var fo := font(f)
	var x := p.x
	if align != HORIZONTAL_ALIGNMENT_LEFT:
		var w := fo.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		x -= w * (0.5 if align == HORIZONTAL_ALIGNMENT_CENTER else 1.0)
	if outline > 0:
		ci.draw_string_outline(fo, Vector2(x, p.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0, 0, 0, col.a * 0.75))
	ci.draw_string(fo, Vector2(x, p.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func text_width(s: String, f: String, size: int) -> float:
	return font(f).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func spaced(s: String) -> String:
	## Letras espaçadas para os títulos pequenos ("P A U S A").
	return " ".join(s.split(""))
