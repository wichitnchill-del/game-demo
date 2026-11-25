extends Control
## Round minimap, centred on the camera target, north up.
## Shows buildings, landmarks, the fog circle and next circle, cards,
## teammates, and enemies that are close or revealed.

const VIEW := 48.0            # metres from centre to edge
const MAP_HALF := 90.0
var royale
var full := false            # M: whole map, centred on the map instead of the player


func _to_map(p: Vector2, c: Vector2, r: float) -> Vector2:
	return Vector2(r, r) + (p - c) * (r / (VIEW if not full else MAP_HALF + 4.0))


func _in(m: Vector2, r: float, pad := 0.0) -> bool:
	return m.distance_to(Vector2(r, r)) <= r - pad


func _draw() -> void:
	if royale == null or royale.cam_target == null:
		return
	var r := size.x / 2.0
	var me = royale.cam_target
	var c := Vector2(me.global_position.x, me.global_position.z) if not full else Vector2.ZERO
	var view := VIEW if not full else MAP_HALF + 4.0
	var k := r / view
	# glow + background disc
	for i in 4:
		draw_circle(Vector2(r, r), r + 10 - i * 2, Color(0.75, 0.6, 1, 0.12))
	draw_circle(Vector2(r, r), r, Color("2a2f6a"))
	draw_circle(Vector2(r, r), r - 3, Color("3a3f82"))
	# buildings (only those fully inside the disc)
	for rect in royale.obstacles:
		var a: Vector2 = _to_map(rect.position, c, r)
		var b: Vector2 = _to_map(rect.end, c, r)
		if _in(a, r, 2) and _in(b, r, 2) and _in(Vector2(a.x, b.y), r, 2) and _in(Vector2(b.x, a.y), r, 2):
			draw_rect(Rect2(a, b - a), Color(0.62, 0.6, 0.85, 0.75))
	# walk-in buildings: light floor + door marker
	for rm in royale.rooms:
		var rr: Rect2 = rm["rect"]
		var a2: Vector2 = _to_map(rr.position, c, r)
		var b2: Vector2 = _to_map(rr.end, c, r)
		if _in(a2, r, 2) and _in(b2, r, 2) and _in(Vector2(a2.x, b2.y), r, 2) and _in(Vector2(b2.x, a2.y), r, 2):
			draw_rect(Rect2(a2, b2 - a2), Color(1, 0.85, 0.6, 0.45))
			draw_rect(Rect2(a2, b2 - a2), Color(1, 0.85, 0.6, 0.9), false, 1.5)
			var dm: Vector2 = _to_map(Vector2(rm["door_out"].x, rm["door_out"].z), c, r)
			draw_circle(dm, 2.5, Color(1, 0.95, 0.7))
	# fog circle: sample points, draw only inside the disc
	var steps := 96
	for pass_i in 2:
		var zc: Vector2 = royale.zone_center if pass_i == 0 else royale.zone_to_c
		var zr: float = royale.zone_radius if pass_i == 0 else royale.zone_to_r
		if pass_i == 1 and not royale.zone_has_next():
			continue
		var col := Color(1, 0.45, 0.85) if pass_i == 0 else Color(1, 1, 1, 0.7)
		var prev := Vector2.INF
		for i in steps + 1:
			var ang := TAU * i / steps
			var m := _to_map(zc + Vector2(cos(ang), sin(ang)) * zr, c, r)
			if _in(m, r, 3) and prev != Vector2.INF and _in(prev, r, 3):
				draw_line(prev, m, col, 2.5 if pass_i == 0 else 1.5, true)
			prev = m
	# cards
	for cd in royale.cards:
		var m := _to_map(Vector2(cd["pos"].x, cd["pos"].z), c, r)
		if _in(m, r, 4):
			draw_rect(Rect2(m - Vector2(2, 3), Vector2(4, 6)), royale.card_color(cd["type"]))
	# fighters
	for f in royale.fighters:
		var d: Dictionary = f.data
		if d["out"]:
			continue
		var p := Vector2(f.global_position.x, f.global_position.z)
		var mine: bool = d["team"] == 0
		var me_p := Vector2(me.global_position.x, me.global_position.z)
		if not mine and d["revealed"] <= 0 and p.distance_to(me_p) > 18:
			continue
		var m := _to_map(p, c, r)
		if not _in(m, r, 5):
			continue
		var col: Color = royale.team_color(d["team"])
		if d["downed"]:
			col = col.darkened(0.5)
		if f == royale.player:
			# arrow showing facing
			var fw := Vector2(f.facing.x, f.facing.z).normalized()
			var side := Vector2(-fw.y, fw.x)
			draw_colored_polygon(PackedVector2Array([m + fw * 9, m - fw * 5 + side * 6, m - fw * 2, m - fw * 5 - side * 6]), Color.WHITE)
		else:
			draw_circle(m, 4.5, Color.WHITE)
			draw_circle(m, 3.3, col)
	# frame ring + N marker + zoom chips
	draw_arc(Vector2(r, r), r - 1, 0, TAU, 96, Color("c8b0ff"), 4.0, true)
	draw_arc(Vector2(r, r), r - 6, 0, TAU, 96, Color(1, 1, 1, 0.35), 1.0, true)
	draw_circle(Vector2(r, 4), 11, Color("2a2f6a"))
	draw_arc(Vector2(r, 4), 11, 0, TAU, 24, Color("c8b0ff"), 2.0, true)
	var f: Font = royale.hud.bold if royale.hud else ThemeDB.fallback_font
	draw_string(f, Vector2(r - 6, 10), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
