extends Control
## Vector icons drawn in code (no emoji / no image files).
## kind: sword dash burst clover drop bolt shield wind flame note ghost radar
##       book people card cross cloud hit
## Drawn in a 100x100 design space, scaled to the control's size.

var kind := "burst"
var color := Color.WHITE
var line_w := 7.0


static func make(k: String, sz: float, col := Color.WHITE) -> Control:
	var c := Control.new()
	c.set_script(load("res://scripts/icon.gd"))
	c.kind = k
	c.color = col
	c.custom_minimum_size = Vector2(sz, sz)
	c.size = Vector2(sz, sz)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func P(x: float, y: float) -> Vector2:
	var s: float = min(size.x, size.y) / 100.0
	var off := (size - Vector2(100, 100) * s) / 2.0
	return off + Vector2(x, y) * s


func S(v: float) -> float:
	return v * min(size.x, size.y) / 100.0


func poly(pts: Array, col := color) -> void:
	var arr := PackedVector2Array()
	for p in pts:
		arr.append(P(p[0], p[1]))
	draw_colored_polygon(arr, col)


func line(a: Array, b: Array, w := line_w, col := color) -> void:
	draw_line(P(a[0], a[1]), P(b[0], b[1]), col, S(w), true)


func circle(c: Array, r: float, col := color) -> void:
	draw_circle(P(c[0], c[1]), S(r), col)


func arc(c: Array, r: float, a0: float, a1: float, w := line_w, col := color) -> void:
	draw_arc(P(c[0], c[1]), S(r), a0, a1, 32, col, S(w), true)


func star(cx: float, cy: float, r_out: float, r_in: float, n: int, col := color) -> void:
	var pts := []
	for i in n * 2:
		var a := PI * i / n - PI / 2
		var r := r_out if i % 2 == 0 else r_in
		pts.append([cx + cos(a) * r, cy + sin(a) * r])
	poly(pts, col)


func _draw() -> void:
	var shade := color.darkened(0.35)
	match kind:
		"sword":
			poly([[78, 10], [90, 22], [42, 70], [30, 58]])
			poly([[78, 10], [90, 22], [86, 26], [74, 14]], color.lightened(0.4))
			line([22, 50], [50, 78], 9, shade)
			line([30, 70], [14, 86], 10)
			circle([12, 88], 6)
		"dash":
			poly([[46, 22], [82, 50], [46, 78], [56, 50]])
			line([10, 34], [40, 34], 7)
			line([4, 50], [44, 50], 7)
			line([10, 66], [40, 66], 7)
		"burst":
			star(50, 50, 46, 20, 8)
			star(50, 50, 24, 11, 8, Color(1, 1, 0.85))
		"clover":
			for c in [[36, 34], [64, 34], [36, 62], [64, 62]]:
				circle(c, 17)
			line([50, 50], [66, 92], 6, shade)
		"drop":
			poly([[50, 8], [76, 52], [24, 52]])
			circle([50, 62], 27)
			circle([40, 58], 7, Color(1, 1, 1, 0.6))
		"bolt":
			poly([[58, 4], [22, 56], [46, 56], [38, 96], [80, 40], [54, 40], [66, 4]])
		"shield":
			poly([[50, 6], [88, 20], [84, 58], [50, 94], [16, 58], [12, 20]])
			poly([[50, 18], [76, 28], [73, 56], [50, 82]], color.lightened(0.35))
		"wind":
			arc([46, 40], 26, -PI * 0.9, PI * 0.5, 8)
			line([46, 66], [8, 66], 8)
			arc([62, 62], 16, -PI * 0.8, PI * 0.6, 7)
			line([8, 40], [20, 40], 8)
		"flame":
			poly([[50, 4], [80, 46], [84, 70], [70, 92], [30, 92], [16, 70], [22, 46], [36, 58]])
			poly([[52, 40], [68, 66], [62, 88], [38, 88], [34, 70], [44, 62]], Color(1, 0.95, 0.6))
		"note":
			circle([32, 76], 15)
			circle([72, 66], 15)
			line([45, 76], [45, 16], 7)
			line([85, 66], [85, 8], 7)
			poly([[42, 14], [88, 4], [88, 22], [42, 32]])
		"ghost":
			poly([[18, 50], [18, 90], [30, 80], [42, 92], [58, 80], [70, 92], [82, 80], [82, 50]])
			circle([50, 46], 32)
			circle([39, 44], 7, Color("2a2f6a"))
			circle([61, 44], 7, Color("2a2f6a"))
		"radar":
			arc([50, 60], 40, -PI * 0.85, -PI * 0.15, 7)
			arc([50, 60], 26, -PI * 0.8, -PI * 0.2, 7)
			circle([50, 60], 9)
			line([50, 60], [50, 92], 7)
		"book":
			poly([[10, 18], [48, 26], [48, 90], [10, 82]])
			poly([[90, 18], [52, 26], [52, 90], [90, 82]], color.lightened(0.25))
			line([18, 40], [40, 44], 4, shade)
			line([18, 54], [40, 58], 4, shade)
		"people":
			circle([34, 30], 15)
			poly([[12, 84], [16, 54], [52, 54], [56, 84]])
			circle([68, 34], 13, color.darkened(0.15))
			poly([[52, 54], [86, 56], [90, 84], [60, 84]], color.darkened(0.15))
		"card":
			draw_rect(Rect2(P(24, 8), Vector2(S(52), S(84))), color, true)
			draw_rect(Rect2(P(30, 14), Vector2(S(40), S(72))), shade, false, S(3))
			star(50, 50, 18, 8, 4, shade)
		"cross":
			line([20, 20], [80, 80], 14)
			line([80, 20], [20, 80], 14)
		"cloud":
			circle([34, 58], 20)
			circle([56, 46], 26)
			circle([74, 62], 18)
			draw_rect(Rect2(P(30, 60), Vector2(S(46), S(20))), color)
		"hit":
			star(50, 50, 44, 22, 6)
		_:
			circle([50, 50], 30)
