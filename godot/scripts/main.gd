extends Control
## Whole game flow: title → prologue → (school → story → battle) × 3 → ending.
## UI is built in code so the project has no fragile scene files.

const Story := preload("res://scripts/story.gd")
const Sheets := preload("res://scripts/sheets.gd")

const MUSIC := {
	"title": "res://assets/music/lumi-sleeve.wav",
	"school": "res://assets/music/lumi-sunny.wav",
	"battle": "res://assets/music/lumi-light.wav",
}

var root: VBoxContainer
var log_box: RichTextLabel
var music: AudioStreamPlayer
var music_key := ""
var tex_cache := {}
var bg: ColorRect
var school_actions := 0



func _ready() -> void:
	var th := Theme.new()
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Thonburi", "Sukhumvit Set", "Noto Sans Thai", "Leelawadee UI", "Tahoma"])
	th.default_font = f
	theme = th

	bg = ColorRect.new()
	bg.color = Color("0f1220")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	music = AudioStreamPlayer.new()
	music.volume_db = -8
	music.finished.connect(func(): music.play())
	add_child(music)
	show_title()


# ---------- helpers ----------
func play_music(key: String) -> void:
	if key == music_key:
		return
	music_key = key
	var s = load(MUSIC[key])
	if s:
		music.stream = s
		music.play()


func crop(id: String, part: String) -> Texture2D:
	return Sheets.crop(id, part)


## Character image on a light card (sheets have white backgrounds).
func portrait(id: String, size: float, part := "face") -> Control:
	var t := crop(id, part)
	var holder := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f2f0ea")
	sb.set_corner_radius_all(8)
	holder.add_theme_stylebox_override("panel", sb)
	var h := size * (2.6 if part == "body" else 1.0)
	holder.custom_minimum_size = Vector2(size, h)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if t:
		var r := TextureRect.new()
		r.texture = t
		r.custom_minimum_size = Vector2(size, h)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		holder.add_child(r)
	return holder


func clear() -> void:
	for c in root.get_children():
		root.remove_child(c)
		c.queue_free()
	log_box = null


func label(text: String, size := 16, color := Color("e8eaf6")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func head_label(text: String, size := 14) -> Label:
	var l := label(text, size)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func button(text: String, cb: Callable, disabled := false) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	b.custom_minimum_size = Vector2(150, 54)
	b.pressed.connect(cb)
	return b


func panel(children: Array, highlight := Color(0, 0, 0, 0)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1a1f35")
	sb.border_color = highlight if highlight.a > 0 else Color("2c3354")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	p.add_child(v)
	for c in children:
		v.add_child(c)
	return p


func bar(value: float, maxv: float, color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = maxv
	b.value = max(0, value)
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	b.add_theme_stylebox_override("fill", fill)
	return b


func add_log(t: String, color := "e8eaf6") -> void:
	if log_box:
		log_box.append_text("[color=#%s]%s[/color]\n" % [color, t])


# ---------- cutscenes ----------
const Cutscene := preload("res://scripts/cutscene.gd")
var clover_warned := false


## Plays a cutscene over the whole screen, then calls done.
func show_dialogue(lines: Array, done: Callable) -> void:
	clear()
	var cs := Cutscene.new()
	add_child(cs)
	cs.finished.connect(done, CONNECT_DEFERRED)
	cs.play(lines)


# ---------- title / ending ----------
func show_title() -> void:
	play_music("title")
	clear()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for id in ["ren", "mio", "oli", "haru", "setsu"]:
		row.add_child(portrait(id, 150, "body"))
	root.add_child(label("Core Blaker", 44))
	root.add_child(label("เฟส 1 — ห้าคน", 20, Color("8a90b4")))
	root.add_child(row)
	root.add_child(label("เล่นเป็นโอลี่ ใช้เวลาหลังเลิกเรียนกับเพื่อนให้สนิทขึ้น ความสนิทเพิ่มพลังในการต่อสู้ · ถ้าสนิทกับเลออนพอ เขาอาจหลบทางให้", 16, Color("8a90b4")))
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 12)
	var br := button("BATTLE ROYALE\nทีมละ 3 คน · 8 ทีม · เหลือรอดทีมสุดท้าย", show_select)
	br.custom_minimum_size = Vector2(620, 80)
	br.add_theme_font_size_override("font_size", 20)
	modes.add_child(br)
	var story := button("โหมดเรื่องราว\nเฟส 1 — ห้าคน", func():
		Game.new_game()
		clover_warned = false
		show_dialogue(Story.PROLOGUE, show_school))
	story.custom_minimum_size = Vector2(600, 80)
	modes.add_child(story)
	root.add_child(modes)


func finish_game(won_by_bond: bool) -> void:
	var lines: Array = []
	lines += Story.LEON_ASIDE if won_by_bond else Story.LEON_DEFEATED
	lines += Story.AFTER_WIN
	if Game.bonds["haru"] >= Game.BOND_MAX:
		lines += Story.POST_CREDIT
	play_music("title")
	show_dialogue(lines, func(): show_end("จบเฟส 1", "เลออนหลบทางให้ ไม่ต้องสู้" if won_by_bond else "ชนะเลออน!"))


func show_end(title: String, body: String) -> void:
	play_music("title")
	clear()
	root.add_child(label(title, 34))
	root.add_child(label(body, 18))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for k in Game.bonds:
		var v := VBoxContainer.new()
		v.add_child(portrait(k, 110))
		v.add_child(label("%s  ความสนิท %d/%d" % [Game.HANGOUTS[k]["name"], Game.bonds[k], Game.BOND_MAX], 13))
		row.add_child(v)
	root.add_child(row)
	root.add_child(label("Lv %d · ใบโคลเวอร์ร้าว %d/3" % [Game.lv, Game.clover], 14, Color("8a90b4")))
	root.add_child(button("เล่นอีกครั้ง", show_title))


# ---------- battle royale ----------
const Royale := preload("res://scripts/royale.gd")
var royale: Node3D
var royale_seed := -1   # tests: fixed map


func show_select() -> void:
	play_music("title")
	clear()
	root.add_child(label("เลือกตัวละคร", 30))
	root.add_child(label("เพื่อนร่วมทีมอีก 2 คนจะสุ่มจากตัวละครที่เหลือ (AI ช่วยสู้และชุบให้)", 15, Color("8a90b4")))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)
	for id in Royale.ROSTER:
		var st: Dictionary = Royale.STATS[id]
		var pw: Dictionary = Royale.POWERS[id]
		var mv: String = Fighter.MOBILITY.get(id, {}).get("desc", "")
		var b := button("%s  %s\nพลัง: %s — %s\nเคลื่อนที่: %s" % [st["name"], ("ธาตุ" + st["el"]) if st["el"] != "" else "", pw["name"], pw["desc"], mv], func(): start_royale(id))
		b.icon = crop(id, "face")
		b.expand_icon = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(240, 130)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 12)
		grid.add_child(b)
	root.add_child(button("◀ กลับ", show_title))


func start_royale(id: String) -> void:
	play_music("battle")
	clear()
	bg.visible = false
	royale = Royale.new()
	royale.autopilot = autopilot
	add_child(royale)
	royale.start(id, royale_seed)
	royale.finished.connect(_on_royale_finished, CONNECT_DEFERRED)


var last_result: Array = []   # tests


func _on_royale_finished(placement: int, stats: Dictionary) -> void:
	last_result = [placement, stats]
	if royale:
		royale.queue_free()
		royale = null
	bg.visible = true
	if placement < 0:   # quit from the pause menu
		show_title()
		return
	play_music("title")
	clear()
	root.add_child(label("ชนะ! ทีมสุดท้ายที่เหลือรอด" if placement == 1 else "อันดับ %d / 8" % placement, 36, Color("f5c542") if placement == 1 else Color("e8eaf6")))
	root.add_child(label("เวลา %d:%02d · ฆ่ารวมทั้งทีม %d · ดาเมจรวม %d" % [int(stats["time"]) / 60, int(stats["time"]) % 60, stats["kills"], stats["damage"]], 18, Color("8a90b4")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	for m in stats["team"]:
		var v := VBoxContainer.new()
		v.add_child(portrait(m[0], 130, "body"))
		v.add_child(label("%s\nฆ่า %d · ดาเมจ %d · พลัง Lv%d" % [m[1], m[2], m[3], m[4]], 14))
		row.add_child(v)
	root.add_child(row)
	var again := HBoxContainer.new()
	again.add_child(button("เล่นอีกครั้ง", show_select))
	again.add_child(button("หน้าแรก", show_title))
	root.add_child(again)


# ---------- school ----------
func show_school() -> void:
	school_actions = 2
	render_school("")


func render_school(event_text: String, speaker := "") -> void:
	play_music("school")
	clear()
	root.add_child(label("หลังเลิกเรียน — ก่อนด่าน %d / %d" % [Game.wave + 1, Game.WAVES.size()], 26))
	root.add_child(label("เหลือเวลาอีก %d ช่วง · Lv %d · EXP %d" % [school_actions, Game.lv, Game.exp], 15, Color("8a90b4")))
	if event_text != "":
		var row := HBoxContainer.new()
		if speaker != "":
			row.add_child(portrait(speaker, 90))
		var p := panel([label(event_text, 18, Color("f5c542"))])
		row.add_child(p)
		root.add_child(row)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)
	for id in Game.HANGOUTS:
		var h: Dictionary = Game.HANGOUTS[id]
		var b: int = Game.bonds[id]
		var hearts := "ความสนิท %d/%d" % [b, Game.BOND_MAX]
		var note := ""
		if id == "leon":
			note = "สนิทถึง %d = เลออนหลบทาง" % Game.LEON_BOND_NEEDED
		elif id == "haru":
			note = "พลังโจมตี +%d%% · เต็ม = ฉากพิเศษ" % (b * 4)
		else:
			note = "พลังโจมตี +%d%%" % (b * 4)
		var btn := button("%s @ %s\n%s\n%s" % [h["name"], h["place"], hearts, note],
			func(): hang_out(id), school_actions <= 0 or b >= Game.BOND_MAX)
		btn.icon = crop(id, "face")
		btn.expand_icon = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(380, 100)
		grid.add_child(btn)
	var rest := button("พักที่ห้อง\nทุกคนลมหายใจ +30 · HP +20%", func(): rest_room(), school_actions <= 0)
	rest.custom_minimum_size = Vector2(380, 100)
	grid.add_child(rest)
	var go_text := "ไปต่อ ▶"
	root.add_child(button(go_text, func(): show_dialogue(Story.BEFORE_WAVE[Game.wave], start_battle)))


func hang_out(id: String) -> void:
	if school_actions <= 0 or Game.bonds[id] >= Game.BOND_MAX:
		return
	var h: Dictionary = Game.HANGOUTS[id]
	var lines: Array = h["lines"]
	var text: String = lines[Game.bonds[id]]
	Game.bonds[id] += 1
	school_actions -= 1
	render_school("%s\n— ความสนิทกับ%s +1" % [text, h["name"]], id)


func rest_room() -> void:
	if school_actions <= 0:
		return
	Game.rest_party(30)
	for p in Game.party:
		if p["seal"] < 2:
			p["hp"] = min(p["maxhp"], p["hp"] + int(p["maxhp"] * 0.2))
	school_actions -= 1
	render_school("โอลี่นอนกลางวัน… ทุกคนได้พัก", "oli")


# ---------- battle (3D action arena) ----------
const Arena := preload("res://scripts/arena.gd")
var arena: Node3D
var autopilot := false   # tests: let the AI fight


func start_battle() -> void:
	var wave_def: Array = Game.WAVES[Game.wave]
	if wave_def[0].get("leon", false) and Game.bonds["leon"] >= Game.LEON_BOND_NEEDED:
		finish_game(true)
		return
	play_music("battle")
	clear()
	bg.visible = false
	var wave: Array = []
	for e in wave_def:
		var d: Dictionary = e.duplicate()
		# action pacing: enemies take many more hits for real-time action combat
		d["maxhp"] = int(d["hp"] * 2.6) + Game.lv * 20
		d["hp"] = d["maxhp"]
		wave.append(d)
	for p in Game.party:
		p["breath"] = float(p["breath"])
	arena = Arena.new()
	arena.autopilot = autopilot
	add_child(arena)
	arena.start(wave)
	arena.finished.connect(_on_arena_finished, CONNECT_DEFERRED)


var battle_log: Array = []   # [wave, seconds, won, team hp %] — used by tests


func _on_arena_finished(won: bool) -> void:
	if arena:
		var hp := 0.0
		var mx := 0.0
		for p in Game.party:
			hp += p["hp"]; mx += p["maxhp"]
		battle_log.append([Game.wave, snapped(arena.time, 0.1), won, int(100 * hp / mx)])
		arena.queue_free()
		arena = null
	bg.visible = true
	if won:
		win_wave()
	else:
		lose()


func alive_party() -> Array:
	return Game.party.filter(func(p): return p["hp"] > 0 and p["seal"] < 2)


func lose() -> void:
	show_end("พ่ายแพ้", "ทีมหมดแรง ลองใช้ธาตุให้ได้เปรียบ อย่าฝืนลมหายใจ และไปสนิทกับเพื่อนให้มากขึ้น")


func win_wave() -> void:
	var cracked := alive_party().filter(func(p): return p["seal"] == 1).size()
	var g := 40 + Game.wave * 30
	if cracked > 0:
		g *= 2
	var msgs := Game.add_exp(g)
	Game.wave += 1
	if Game.wave >= Game.WAVES.size():
		finish_game(false)
		return
	# knocked-out members get back up for the next day; broken seals stay broken
	for p in Game.party:
		if p["hp"] <= 0 and p["seal"] < 2:
			p["hp"] = 1
	Game.rest_party(40)
	school_actions = 2
	var t := "ผ่านด่าน! EXP +%d%s" % [g, " (x2 เจ็บแล้วรอด)" if cracked > 0 else ""]
	if not msgs.is_empty():
		t += "\n" + "\n".join(msgs)
	var story: Array = []
	if Game.wave == 2:
		story += Story.AFTER_FIRE
	if Game.clover >= 2 and not clover_warned:
		clover_warned = true
		story += Story.CLOVER_WARNING
	if story.is_empty():
		render_school(t)
	else:
		show_dialogue(story, func(): render_school(t))
