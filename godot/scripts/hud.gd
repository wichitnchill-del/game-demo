extends CanvasLayer
## Battle Royale HUD — pastel anime style.
## Layout (1280x720): team list top-left · teams-left pill + area banner top ·
## round minimap top-right · pickup notices left · player card bottom-left ·
## 4 skill buttons bottom-centre · event cards, target, kills, fog timer right ·
## key chips along the bottom.

const NAVY := Color("2a2f6a")
const INK := Color("3a2f6a")
const LAV := Color("c8b0ff")
const PINK := Color("ff5fa8")
const HP_COL := Color("4fe08a")
const ST_COL := Color("5ab8ff")
const ULT_COL := Color("ffa23a")
## vector icon kind per character power (see icon.gd)
const POWER_ICON := {
	"oli": "clover", "haru": "drop", "ren": "bolt", "mio": "shield", "setsu": "wind",
	"leon": "flame", "lumi": "note", "null": "ghost", "kuroba": "radar", "fumi": "book",
}
const Icon := preload("res://scripts/icon.gd")

var royale
var font: Font
var bold: Font

var team_rows: Array = []      # [hp_bar, name_label, panel, face]
var pill: Label
var banner: Label
var banner_area := ""
var banner_t := 0.0
var area_check := 0.0
var notices_box: VBoxContainer
var notices: Array = []        # [text, icon, t]
var events_box: VBoxContainer
var events: Array = []         # [icon, text, color, t]
var events_dirty := true
var p_name: Label
var p_lv: Label
var p_hp: Array                # [bar, label]
var p_st: Array
var p_status: Label
var skills: Array = []         # dicts {panel, cover, cd_label, ...}
var kills_lbl: Label
var zone_lbl: Label
var target_panel: PanelContainer
var target_face: TextureRect
var target_name: Label
var target_hp: Array
var msg: Label
var msg_t := 0.0
var minimap_mask: Control
var p_card: Control
var p_face: Control
var kills_panel: Control
var zone_panel: Control
var touch: Node              # "Touch" autoload when on a touch screen, else null


func _init() -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Sukhumvit Set", "Thonburi", "Noto Sans Thai", "Leelawadee UI", "Tahoma"])
	f.font_weight = 500
	font = f
	var b := SystemFont.new()
	b.font_names = f.font_names
	b.font_weight = 800
	bold = b


# ---------- style helpers ----------
func sb(bg: Color, border := Color(0, 0, 0, 0), radius := 18, bw := 0, shadow := Color(0, 0, 0, 0), ss := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.shadow_color = shadow
	s.shadow_size = ss
	s.anti_aliasing = true
	return s


func lbl(t: String, size := 16, col := INK, f: Font = null, outline := Color.WHITE, ow := 6) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f if f else font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", outline)
	l.add_theme_constant_override("outline_size", ow)
	return l


func panel(style: StyleBoxFlat, pos: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style)
	p.position = pos
	p.size = size
	p.custom_minimum_size = size
	add_child(p)
	return p


## Rounded bar with "cur/max" text on it.
func bar(col: Color, w: float, h: float, with_text := true) -> Array:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(w, h)
	var b := ProgressBar.new()
	b.show_percentage = false
	b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_theme_stylebox_override("background", sb(Color(0.16, 0.15, 0.35, 0.55), Color(1, 1, 1, 0.9), int(h / 2), 2))
	b.add_theme_stylebox_override("fill", sb(col, Color(0, 0, 0, 0), int(h / 2), 0, col.lightened(0.3), 3))
	holder.add_child(b)
	var t: Label = null
	if with_text:
		t = lbl("", int(h * 0.72), Color.WHITE, bold, NAVY, 5)
		t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		t.offset_right = -10
		holder.add_child(t)
	return [b, t, holder]


func set_bar(arr: Array, v: float, mx: float) -> void:
	var b: ProgressBar = arr[0]
	b.max_value = max(1.0, mx)
	b.value = clamp(v, 0.0, mx)
	if arr[1]:
		(arr[1] as Label).text = "%d/%d" % [int(v), int(mx)]


func face_tex(id: String) -> Texture2D:
	var p := "res://assets/faces/%s.png" % id
	return load(p) if ResourceLoader.exists(p) else null


func face(id: String, d: float, ring: Color, ring_w := 4) -> Control:
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(d, d)
	holder.add_theme_stylebox_override("panel", sb(Color.WHITE, ring, int(d / 2), ring_w, Color(LAV, 0.8), 6))
	var t := TextureRect.new()
	t.texture = face_tex(id)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(d - ring_w * 2, d - ring_w * 2)
	holder.add_child(t)
	return holder


# ---------- build ----------
func build() -> void:
	layer = 5
	_build_team()
	_build_top()
	_build_minimap()
	_build_player()
	_build_skills()
	_build_right()
	_build_keys()
	notices_box = VBoxContainer.new()
	notices_box.position = Vector2(14, 268)
	notices_box.add_theme_constant_override("separation", 6)
	add_child(notices_box)
	msg = lbl("", 26, PINK, bold, Color.WHITE, 10)
	msg.position = Vector2(0, 196)
	msg.size = Vector2(1280, 40)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(msg)
	var t := get_node_or_null("/root/Touch")
	if t and t.enabled:
		touch = t
		_touch_layout()


## Touch screens: keep both bottom corners free for the thumbs.
## Joystick lives bottom-left, action buttons bottom-right, so the player card and
## team list go top-left, kills/zone go under the minimap, and the skill cards are
## hidden (their cooldowns are drawn on the touch buttons instead).
func _touch_layout() -> void:
	p_face.scale = Vector2(0.72, 0.72)
	p_face.position = Vector2(8, 8)
	p_card.scale = Vector2(0.85, 0.85)
	p_card.position = Vector2(70, 22)
	for row in team_rows:
		(row[2] as Control).position.y += 130
		(row[3] as Control).position.y += 130
	notices_box.position = Vector2(14, 372)
	kills_panel.position = Vector2(1016, 212)
	zone_panel.position = Vector2(1162, 212)
	events_box.position = Vector2(1016, 316)
	target_panel.position = Vector2(515, 636)
	for s in skills:
		for key in ["panel", "cover", "cd"]:
			(s[key] as Control).visible = false


func _build_team() -> void:
	var ms: Array = royale.members(0)
	for i in ms.size():
		var f = ms[i]
		var y := 12 + i * 70
		var p := panel(sb(Color(1, 1, 1, 0.88), LAV, 28, 3, Color(0.6, 0.45, 1, 0.45), 8), Vector2(44, y + 8), Vector2(230, 52))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 30)
		m.add_theme_constant_override("margin_right", 12)
		m.add_child(v)
		p.add_child(m)
		var n := lbl("%s Lv.%d" % [f.data["name"], f.data["lv"]], 16, NAVY, bold)
		v.add_child(n)
		var hb := bar(HP_COL, 180, 13, false)
		v.add_child(hb[2])
		var fc := face(f.data["id"], 64, LAV)
		fc.position = Vector2(10, y)
		add_child(fc)
		team_rows.append([hb, n, p, fc])


func _build_top() -> void:
	var p := panel(sb(Color(NAVY, 0.92), Color(1, 1, 1, 0.9), 22, 3, Color(0.4, 0.3, 0.9, 0.5), 6), Vector2(465, 12), Vector2(250, 42))
	var ph := HBoxContainer.new()
	ph.alignment = BoxContainer.ALIGNMENT_CENTER
	ph.add_theme_constant_override("separation", 8)
	ph.add_child(Icon.make("people", 24, Color("c8b0ff")))
	pill = lbl("", 17, Color.WHITE, bold, NAVY, 4)
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ph.add_child(pill)
	p.add_child(ph)
	banner = lbl("", 46, PINK, bold, Color.WHITE, 16)
	banner.add_theme_color_override("font_shadow_color", Color(0.45, 0.25, 0.9, 0.85))
	banner.add_theme_constant_override("shadow_offset_x", 0)
	banner.add_theme_constant_override("shadow_offset_y", 5)
	banner.add_theme_constant_override("shadow_outline_size", 20)
	banner.position = Vector2(240, 56)
	banner.size = Vector2(700, 70)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(banner)


func _build_minimap() -> void:
	var c := Vector2(1168, 112)
	var r := 92.0
	minimap_mask = Control.new()
	minimap_mask.set_script(preload("res://scripts/minimap.gd"))
	minimap_mask.royale = royale
	minimap_mask.position = c - Vector2(r, r)
	minimap_mask.size = Vector2(r * 2, r * 2)
	add_child(minimap_mask)


func _build_player() -> void:
	var f = royale.player
	var card := panel(sb(Color(NAVY, 0.86), LAV, 26, 3, Color(0.6, 0.45, 1, 0.55), 10), Vector2(118, 566), Vector2(352, 118))
	p_card = card
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 46)
	m.add_theme_constant_override("margin_top", 6)
	m.add_theme_constant_override("margin_right", 14)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	m.add_child(v)
	var top := HBoxContainer.new()
	p_name = lbl(f.data["name"], 28, Color.WHITE, bold, Color(PINK, 0.9), 8)
	top.add_child(p_name)
	p_lv = lbl("", 18, Color("ffe14a"), bold, NAVY, 5)
	p_lv.size_flags_vertical = Control.SIZE_SHRINK_END
	top.add_child(p_lv)
	v.add_child(top)
	for row in [["HP", HP_COL], ["Stamina", ST_COL]]:
		var h := HBoxContainer.new()
		var l := lbl(row[0], 14, Color.WHITE, bold, NAVY, 4)
		l.custom_minimum_size = Vector2(70, 0)
		h.add_child(l)
		var b := bar(row[1], 214, 18)
		h.add_child(b[2])
		v.add_child(h)
		if row[0] == "HP": p_hp = b
		else: p_st = b
	p_status = lbl("", 12, Color("e8e0ff"), font, NAVY, 3)
	v.add_child(p_status)
	var fc := face(f.data["id"], 150, Color("ffd0ec"), 6)
	fc.position = Vector2(10, 540)
	add_child(fc)
	p_face = fc


func _build_skills() -> void:
	var id: String = royale.player.data["id"]
	var pw: Dictionary = royale.POWERS[id]
	var defs := [
		{"icon": "sword", "name": "โจมตี", "key": "คลิกซ้าย", "col": Color("6ab8ff"), "kind": "attack"},
		{"icon": "dash", "name": "หลบ", "key": "C / Ctrl", "col": Color("b88aff"), "kind": "dodge"},
		{"icon": POWER_ICON.get(id, "burst"), "name": pw["name"], "key": "คลิกขวา / Q", "col": Color("5ee0c0"), "kind": "power"},
		{"icon": "burst", "name": "ท่าไม้ตาย", "key": "R", "col": Color("ffa23a"), "kind": "ult"},
	]
	for i in defs.size():
		var d: Dictionary = defs[i]
		var x := 492 + i * 122
		var bgc := Color(NAVY, 0.9)
		var p := panel(sb(bgc, d["col"], 18, 3, Color(d["col"], 0.7), 10), Vector2(x, 572), Vector2(112, 124))
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 0)
		p.add_child(v)
		var ic := Icon.make(d["icon"], 48, (d["col"] as Color).lightened(0.35))
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var nm := lbl(d["name"], 15 if d["name"].length() < 9 else 12, Color.WHITE, bold, NAVY, 4)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		v.add_child(nm)
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", sb(Color(1, 1, 1, 0.92), Color(0, 0, 0, 0), 9))
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var kl := lbl(d["key"], 11, NAVY, bold, Color.WHITE, 0)
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(kl)
		v.add_child(chip)
		# cooldown cover (darkens from the top, shrinks as it recharges)
		var cover := ColorRect.new()
		cover.color = Color(0.05, 0.04, 0.15, 0.62)
		cover.position = Vector2(x + 4, 576)
		cover.size = Vector2(104, 0)
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cover)
		var cl := lbl("", 30, Color.WHITE, bold, NAVY, 6)
		cl.position = Vector2(x, 600)
		cl.size = Vector2(112, 40)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(cl)
		skills.append({"kind": d["kind"], "panel": p, "cover": cover, "cd": cl, "col": d["col"]})


func _build_right() -> void:
	events_box = VBoxContainer.new()
	events_box.position = Vector2(1016, 236)
	events_box.add_theme_constant_override("separation", 6)
	add_child(events_box)
	# target card
	target_panel = panel(sb(Color(NAVY, 0.88), Color("ffb0d8"), 22, 3, Color(1, 0.5, 0.8, 0.5), 8), Vector2(1016, 500), Vector2(250, 70))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	target_panel.add_child(h)
	target_face = TextureRect.new()
	target_face.custom_minimum_size = Vector2(56, 56)
	target_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	target_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(target_face)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	target_name = lbl("", 15, Color.WHITE, bold, NAVY, 4)
	v.add_child(target_name)
	target_hp = bar(Color("ff6a8a"), 160, 14)
	v.add_child(target_hp[2])
	h.add_child(v)
	# kills + fog
	var k := panel(sb(Color(NAVY, 0.9), LAV, 20, 3, Color(0.6, 0.45, 1, 0.5), 8), Vector2(1016, 584), Vector2(136, 96))
	kills_panel = k
	var kv := VBoxContainer.new()
	kv.alignment = BoxContainer.ALIGNMENT_CENTER
	k.add_child(kv)
	var kt := lbl("ผลงาน (ฆ่า)", 14, Color.WHITE, bold, NAVY, 3)
	kt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kv.add_child(kt)
	kills_lbl = lbl("0", 42, Color("ffe14a"), bold, NAVY, 6)
	kills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kv.add_child(kills_lbl)
	var z := panel(sb(Color("ffe8f6"), PINK, 20, 3, Color(1, 0.5, 0.8, 0.5), 8), Vector2(1162, 584), Vector2(104, 96))
	zone_panel = z
	zone_lbl = lbl("", 16, Color("8a2a6a"), bold, Color.WHITE, 4)
	zone_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	z.add_child(zone_lbl)


func _build_keys() -> void:
	var touch := get_node_or_null("/root/Touch")
	if touch and touch.enabled:
		return  # keyboard hints are meaningless on a touch screen
	var h := HBoxContainer.new()
	h.position = Vector2(14, 694)
	h.add_theme_constant_override("separation", 6)
	add_child(h)
	for t in ["เมาส์ หมุนกล้อง", "WASD เดิน", "Shift วิ่งเร็ว", "Space กระโดด/บิน/ร่อน", "ชนกำแพง ปีน", "E ชุบเพื่อน", "Tab สถานะ", "M แผนที่", "T เรียกเพื่อน", "Esc พัก"]:
		var c := PanelContainer.new()
		c.add_theme_stylebox_override("panel", sb(Color(NAVY, 0.85), Color(1, 1, 1, 0.7), 10, 1))
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 8)
		m.add_theme_constant_override("margin_right", 8)
		m.add_child(lbl(t, 11, Color.WHITE, bold, NAVY, 0))
		c.add_child(m)
		h.add_child(c)


# ---------- Tab status / M big map ----------
var status_panel: PanelContainer
var map_small_pos := Vector2.ZERO
var map_small_size := Vector2.ZERO


func set_big_map(on: bool) -> void:
	if map_small_size == Vector2.ZERO:
		map_small_pos = minimap_mask.position
		map_small_size = minimap_mask.size
	minimap_mask.full = on
	if on:
		minimap_mask.size = Vector2(560, 560)
		minimap_mask.position = Vector2(640 - 280, 360 - 290)
	else:
		minimap_mask.size = map_small_size
		minimap_mask.position = map_small_pos


func set_status(on: bool) -> void:
	if not on:
		if status_panel:
			status_panel.queue_free()
			status_panel = null
		return
	if status_panel:
		return
	status_panel = panel(sb(Color(NAVY, 0.92), LAV, 24, 3, Color(0.6, 0.45, 1, 0.6), 12), Vector2(330, 140), Vector2(620, 0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 16)
	m.add_child(v)
	status_panel.add_child(m)
	v.add_child(lbl("สถานะทีม", 26, Color.WHITE, bold, Color(PINK, 0.9), 8))
	for f in royale.members(0):
		var d: Dictionary = f.data
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		h.add_child(face(d["id"], 54, LAV, 3))
		var st := "ตกรอบ" if d["out"] else ("ล้มอยู่" if d["downed"] else "HP %d/%d" % [d["hp"], d["maxhp"]])
		h.add_child(lbl("%s  · พลัง Lv.%d · ฆ่า %d · ดาเมจ %d · %s\nพลัง: %s  |  เคลื่อนที่: %s" % [d["name"], d["lv"], d["kills"], d["damage"], st,
			royale.POWERS[d["id"]]["name"], f.mob().get("desc", "")], 15, Color.WHITE, font, NAVY, 3))
		v.add_child(h)
	v.add_child(lbl("ทีมที่เหลือ %d · เวลา %d:%02d" % [royale.teams_left().size(), int(royale.time) / 60, int(royale.time) % 60], 15, Color("e0d0ff"), bold, NAVY, 3))


# ---------- events from royale ----------
func message(t: String, dur := 1.8) -> void:
	msg.text = t
	msg_t = dur


func notice(t: String, icon := "card") -> void:
	notices.push_front([t, icon, 3.0])
	if notices.size() > 4:
		notices.pop_back()
	_rebuild_notices()


func event(icon: String, t: String, col: Color) -> void:
	events.push_front([icon, t, col, 6.0])
	if events.size() > 5:
		events.pop_back()
	events_dirty = true


func _chip_row(icon: String, t: String, bg: Color, border: Color, w: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(w, 36)
	p.add_theme_stylebox_override("panel", sb(bg, border, 18, 2, Color(border, 0.4), 4))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_child(h)
	p.add_child(m)
	h.add_child(Icon.make(icon, 22, border.lightened(0.2)))
	var l := lbl(t, 13, Color.WHITE, bold, NAVY, 3)
	l.clip_text = true
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return p


func _rebuild_notices() -> void:
	for c in notices_box.get_children():
		notices_box.remove_child(c)
		c.queue_free()
	for n in notices:
		notices_box.add_child(_chip_row(n[1], n[0], Color(NAVY, 0.82), Color("ffd24a"), 300))


func _rebuild_events() -> void:
	for c in events_box.get_children():
		events_box.remove_child(c)
		c.queue_free()
	for e in events:
		events_box.add_child(_chip_row(e[0], e[1], Color(NAVY, 0.82), e[2], 250))
	events_dirty = false


# ---------- per-frame ----------
func refresh(delta: float) -> void:
	var r = royale
	# team
	var ms: Array = r.members(0)
	for i in ms.size():
		var f = ms[i]
		var d: Dictionary = f.data
		var row: Array = team_rows[i]
		set_bar(row[0], d["hp"], d["maxhp"])
		var st := ""
		if d["out"]: st = " · ตกรอบ"
		elif d["downed"]: st = " · ล้ม %d" % int(d["bleed"])
		(row[1] as Label).text = "%s Lv.%d%s" % [d["name"], d["lv"], st]
		var mod := Color(0.55, 0.55, 0.6) if d["out"] else (Color(1, 0.7, 0.75) if d["downed"] else Color.WHITE)
		(row[2] as Control).modulate = mod
		(row[3] as Control).modulate = mod
	# top
	var people: int = r.fighters.filter(func(f): return not f.data["out"]).size()
	pill.text = "เหลือ %d ทีม · %d คน" % [r.teams_left().size(), people]
	area_check -= delta
	if area_check <= 0 and r.cam_target:
		area_check = 0.5
		var a: String = r.area_name(r.cam_target.global_position)
		if a != banner_area:
			banner_area = a
			banner.text = "✦ %s ✦" % a
			banner_t = 3.5
	banner_t -= delta
	banner.modulate.a = clamp(banner_t, 0.0, 1.0)
	# player
	var p: Dictionary = r.player.data
	p_lv.text = "  พลัง Lv.%d" % p["lv"]
	set_bar(p_hp, p["hp"], p["maxhp"])
	set_bar(p_st, p["breath"], 100.0)
	var fx := []
	if p["seal"] > 0: fx.append("ตราร้าว")
	if p["buff"] > 0: fx.append("ดาเมจ x1.6")
	if p["crit"] > 0: fx.append("คริติคอล")
	if p["armor"] > 0: fx.append("เกราะ")
	if p["slow"] > 0: fx.append("ช้าลง")
	if r.player.climbing: fx.append("กำลังปีน")
	if r.player.flying: fx.append("กำลังบิน")
	if p["downed"]: fx.append("ล้มอยู่! รอเพื่อนชุบ %d วิ" % int(p["bleed"]))
	if p["out"]: fx.append("ตกรอบ — ดูเพื่อนร่วมทีม")
	if not r.in_zone(r.player.global_position) and not p["out"]: fx.append("อยู่นอกม่านลืม!")
	p_status.text = "  ".join(fx) if not fx.is_empty() else r.player.mob().get("desc", "")
	# skills
	for s in skills:
		var frac := 0.0
		var txt := ""
		match s["kind"]:
			"attack":
				frac = clamp(p["atk_cd"] / 0.55, 0.0, 1.0)
			"dodge":
				frac = clamp(p.get("dodge_cd", 0.0) / 0.8, 0.0, 1.0)
			"power":
				var full: float = r.POWERS[p["id"]]["cd"] * (1.0 - 0.08 * (p["lv"] - 1))
				frac = clamp(p["cd"] / full, 0.0, 1.0)
				if p["cd"] > 0.05: txt = "%d" % ceil(p["cd"])
			"ult":
				frac = 1.0 - clamp(p["ult"] / 100.0, 0.0, 1.0)
				txt = "%d%%" % int(p["ult"]) if p["ult"] < 100 else ""
		if touch:
			touch.cooldowns[{"attack": "attack", "dodge": "dodge", "power": "power", "ult": "ultimate"}[s["kind"]]] = [frac, txt]
		(s["cover"] as ColorRect).size.y = 116.0 * frac
		(s["cd"] as Label).text = txt
		var ready: bool = frac <= 0.0
		(s["panel"] as Control).modulate = Color(1.15, 1.15, 1.15) if ready and s["kind"] == "ult" and fmod(r.time, 0.8) < 0.4 else Color.WHITE
	# right side
	kills_lbl.text = str(p["kills"])
	if r.zone_has_next():
		zone_lbl.text = ("ม่านลืม\nปิดใน\n%d วิ" if not r.zone_shrinking else "ม่านลืม\nกำลังปิด\n%d วิ") % int(max(0.0, r.zone_timer))
	else:
		zone_lbl.text = "ม่านลืม\nปิดสุดแล้ว"
	var tgt = r._nearest_enemy(r.cam_target, 16.0, true) if r.cam_target else null
	target_panel.visible = tgt != null
	if tgt:
		target_face.texture = face_tex(tgt.data["id"])
		target_name.text = "%s  Lv.%d%s" % [tgt.data["name"], tgt.data["lv"], " (ล้ม)" if tgt.data["downed"] else ""]
		set_bar(target_hp, tgt.data["hp"], tgt.data["maxhp"])
	# timers
	var changed := false
	for e in events:
		e[3] -= delta
		if e[3] <= 0: changed = true
	if changed:
		events = events.filter(func(e): return e[3] > 0)
		events_dirty = true
	if events_dirty:
		_rebuild_events()
	var nchanged := false
	for n in notices:
		n[2] -= delta
		if n[2] <= 0: nchanged = true
	if nchanged:
		notices = notices.filter(func(n): return n[2] > 0)
		_rebuild_notices()
	msg_t -= delta
	msg.visible = msg_t > 0
	minimap_mask.queue_redraw()
