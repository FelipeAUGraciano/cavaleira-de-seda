class_name SkillIcons
extends RefCounted
## Ícones desenhados em código (linhas finas, estilo do menu do casulo).
## draw(ci, id, centro, raio, cor): cada ícone cabe num círculo de raio r.


static func draw(ci: CanvasItem, id: String, c: Vector2, r: float, col: Color) -> void:
	var w := maxf(1.5, r * 0.13)
	match id:
		"web":
			for k in 6:
				var a := k * TAU / 6.0
				ci.draw_line(c, c + Vector2(cos(a), sin(a)) * r, col, w * 0.7, true)
			for ring in [0.4, 0.75]:
				var pts := PackedVector2Array()
				for k in 7:
					var a := k * TAU / 6.0
					pts.append(c + Vector2(cos(a), sin(a)) * r * ring)
				ci.draw_polyline(pts, col, w * 0.7, true)
		"claw":
			for k in 3:
				var x := (k - 1) * r * 0.42
				_arc(ci, c + Vector2(x - r * 0.35, r * 0.1), r * 0.62, -1.1, 0.1, col, w)
		"spiral":
			var pts := PackedVector2Array()
			for i in 40:
				var t := i / 39.0
				var a := t * TAU * 1.6 - PI * 0.5
				pts.append(c + Vector2(cos(a), sin(a)) * r * (0.12 + 0.82 * t))
			ci.draw_polyline(pts, col, w, true)
		"dash":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.9, 0), c + Vector2(-r * 0.1, -r * 0.55), c + Vector2(0.1 * r, 0), c + Vector2(-r * 0.1, r * 0.55)]), col)
			for k in 3:
				var y := (k - 1) * r * 0.32
				ci.draw_line(c + Vector2(-r * 0.95, y), c + Vector2(-r * 0.35, y), col, w * 0.8, true)
		"thread":
			ci.draw_line(c + Vector2(-r * 0.8, r * 0.6), c + Vector2(r * 0.8, -r * 0.6), col, w, true)
			ci.draw_circle(c + Vector2(-r * 0.8, r * 0.6), r * 0.16, col)
			ci.draw_circle(c + Vector2(r * 0.8, -r * 0.6), r * 0.16, col)
			_arc(ci, c, r * 0.35, 0.0, TAU, col, w * 0.7)
		"hook":
			ci.draw_line(c + Vector2(0, -r * 0.9), c + Vector2(0, r * 0.2), col, w, true)
			_arc(ci, c + Vector2(-r * 0.35, r * 0.2), r * 0.35, 0.0, PI, col, w)
			ci.draw_line(c + Vector2(-r * 0.7, r * 0.2), c + Vector2(-r * 0.7, -r * 0.05), col, w, true)
		"web_drop":
			draw(ci, "web", c + Vector2(-r * 0.2, -r * 0.15), r * 0.7, col)
			_drop(ci, c + Vector2(r * 0.5, r * 0.45), r * 0.38, col)
		"rune":
			_arc(ci, c, r * 0.85, 0.0, TAU, col, w * 0.8)
			var pts := PackedVector2Array()
			for i in 30:
				var t := i / 29.0
				var a := t * TAU * 1.2
				pts.append(c + Vector2(cos(a), sin(a)) * r * (0.08 + 0.55 * t))
			ci.draw_polyline(pts, col, w, true)
		"pulse":
			ci.draw_circle(c, r * 0.18, col)
			for k in 3:
				_arc(ci, c, r * (0.38 + 0.25 * k), -0.6, 0.6, col, w * 0.8)
				_arc(ci, c, r * (0.38 + 0.25 * k), PI - 0.6, PI + 0.6, col, w * 0.8)
		"eye":
			var up := PackedVector2Array()
			var dn := PackedVector2Array()
			for i in 17:
				var x := lerpf(-1.0, 1.0, i / 16.0)
				up.append(c + Vector2(x * r * 0.9, -(1.0 - x * x) * r * 0.5))
				dn.append(c + Vector2(x * r * 0.9, (1.0 - x * x) * r * 0.5))
			ci.draw_polyline(up, col, w, true)
			ci.draw_polyline(dn, col, w, true)
			_arc(ci, c, r * 0.28, 0.0, TAU, col, w)
		"shield":
			var pts := PackedVector2Array([c + Vector2(0, -r * 0.85), c + Vector2(r * 0.75, -r * 0.5), c + Vector2(r * 0.6, r * 0.35),
				c + Vector2(0, r * 0.9), c + Vector2(-r * 0.6, r * 0.35), c + Vector2(-r * 0.75, -r * 0.5), c + Vector2(0, -r * 0.85)])
			ci.draw_polyline(pts, col, w, true)
			ci.draw_line(c + Vector2(0, -r * 0.5), c + Vector2(0, r * 0.55), col, w * 0.7, true)
			ci.draw_line(c + Vector2(-r * 0.45, -r * 0.1), c + Vector2(r * 0.45, -r * 0.1), col, w * 0.7, true)
		"spool":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.45, -r * 0.8), Vector2(r * 0.9, r * 0.16)), col)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.45, r * 0.64), Vector2(r * 0.9, r * 0.16)), col)
			for k in 5:
				var y := lerpf(-r * 0.5, r * 0.5, k / 4.0)
				ci.draw_line(c + Vector2(-r * 0.3, y), c + Vector2(r * 0.3, y + r * 0.08), col, w * 0.7, true)
		"moon":
			_arc(ci, c, r * 0.75, PI * 0.35, PI * 1.65, col, w * 1.1)
			_arc(ci, c + Vector2(r * 0.32, -r * 0.05), r * 0.55, PI * 0.55, PI * 1.45, col, w * 0.9)
		"drop":
			_drop(ci, c, r * 0.8, col, false, w)
		"wind":
			for k in 3:
				var y := (k - 1) * r * 0.42
				var len := r * (1.3 if k == 1 else 1.0)
				ci.draw_line(c + Vector2(-r * 0.8, y), c + Vector2(-r * 0.8 + len, y), col, w, true)
				_arc(ci, c + Vector2(-r * 0.8 + len, y - r * 0.14), r * 0.14, -PI * 0.5, PI * 0.5, col, w)
		"fang":
			_arc(ci, c + Vector2(0, -r * 0.25), r * 0.75, PI * 0.15, PI * 0.85, col, w)
			for s in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * r * 0.45, r * 0.05), c + Vector2(s * r * 0.15, r * 0.1), c + Vector2(s * r * 0.3, r * 0.75)]), col)
		"steps":
			for k in 3:
				var p := c + Vector2(-r * 0.6 + k * r * 0.6, r * 0.4 - k * r * 0.4)
				ci.draw_circle(p, r * 0.16, col)
				ci.draw_line(p, p + Vector2(r * 0.2, -r * 0.3), col, w * 0.7, true)
		"heart":
			var pts := PackedVector2Array()
			for i in 40:
				var t := i / 39.0 * TAU
				var x := 16.0 * pow(sin(t), 3)
				var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
				pts.append(c + Vector2(x, y) * r / 18.0)
			ci.draw_polyline(pts, col, w, true)
		"bolt":
			_drop(ci, c, r * 0.8, col, false, w)
			ci.draw_polyline(PackedVector2Array([c + Vector2(r * 0.1, -r * 0.3), c + Vector2(-r * 0.15, r * 0.1), c + Vector2(r * 0.12, r * 0.05), c + Vector2(-r * 0.08, r * 0.45)]), col, w * 0.8, true)
		"leaf":
			_arc(ci, c + Vector2(-r * 0.3, 0), r * 0.75, -0.9, 0.9, col, w)
			_arc(ci, c + Vector2(r * 0.3, 0), r * 0.75, PI - 0.9, PI + 0.9, col, w)
			ci.draw_line(c + Vector2(0, -r * 0.6), c + Vector2(0, r * 0.75), col, w * 0.7, true)
		"crystal":
			var pts := PackedVector2Array([c + Vector2(0, -r * 0.9), c + Vector2(r * 0.45, -r * 0.25), c + Vector2(0, r * 0.9), c + Vector2(-r * 0.45, -r * 0.25), c + Vector2(0, -r * 0.9)])
			ci.draw_polyline(pts, col, w, true)
			ci.draw_line(c + Vector2(-r * 0.45, -r * 0.25), c + Vector2(r * 0.45, -r * 0.25), col, w * 0.7, true)
			ci.draw_line(c + Vector2(0, -r * 0.9), c + Vector2(0, r * 0.9), col, w * 0.5, true)
		"star":
			for k in 4:
				var a := k * PI * 0.25
				ci.draw_line(c - Vector2(cos(a), sin(a)) * r * (0.9 if k % 2 == 0 else 0.55), c + Vector2(cos(a), sin(a)) * r * (0.9 if k % 2 == 0 else 0.55), col, w, true)
			ci.draw_circle(c, r * 0.22, col)
		"cocoon":
			_arc(ci, c, r * 0.6, 0.0, TAU, col, w, Vector2(0.75, 1.15))
			for k in 3:
				var y := (k - 1) * r * 0.35
				ci.draw_line(c + Vector2(-r * 0.42, y - r * 0.1), c + Vector2(r * 0.42, y + r * 0.1), col, w * 0.6, true)
		"lock":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.5, -r * 0.05), Vector2(r, r * 0.8)), col, false, w)
			_arc(ci, c + Vector2(0, -r * 0.05), r * 0.33, PI, TAU, col, w)
		"blade":
			ci.draw_polyline(PackedVector2Array([c + Vector2(0, -r * 0.95), c + Vector2(r * 0.3, -r * 0.1), c + Vector2(0, r * 0.95), c + Vector2(-r * 0.3, -r * 0.1), c + Vector2(0, -r * 0.95)]), col, w, true)
		"spider":
			ci.draw_circle(c + Vector2(0, -r * 0.25), r * 0.28, col)
			ci.draw_circle(c + Vector2(0, r * 0.3), r * 0.4, col)
			for s in [-1.0, 1.0]:
				for k in 4:
					var b := c + Vector2(s * r * 0.2, -r * 0.35 + k * r * 0.18)
					var kn := b + Vector2(s * r * 0.4, -r * 0.25 + k * r * 0.12)
					ci.draw_polyline(PackedVector2Array([b, kn, kn + Vector2(s * r * 0.22, r * 0.35)]), col, w * 0.6, true)
		_:
			ci.draw_circle(c, r * 0.3, col)


static func _arc(ci: CanvasItem, c: Vector2, r: float, a0: float, a1: float, col: Color, w: float, squash := Vector2.ONE) -> void:
	var pts := PackedVector2Array()
	var n := maxi(8, int(absf(a1 - a0) * 8.0))
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a) * squash.x, sin(a) * squash.y) * r)
	ci.draw_polyline(pts, col, w, true)


static func _drop(ci: CanvasItem, c: Vector2, r: float, col: Color, fill := true, w := 2.0) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var t := i / 24.0 * TAU
		var x := sin(t) * (1.0 - cos(t)) * 0.5
		var y := -cos(t)
		pts.append(c + Vector2(x * r * 0.9, y * r))
	if fill:
		ci.draw_colored_polygon(pts, col)
	else:
		ci.draw_polyline(pts, col, w, true)
