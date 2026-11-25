extends Control
## Visual-novel style cutscene player.
## Script = Array of steps:
##   ["@bg", key, caption?]   change location (fade) + optional place/time caption
##   ["@cast", left?, right?] full-body sprites on stage ("" = empty slot)
##   ["@group", id, id, ...] several characters lined up facing the camera (3D stage)
##   ["@flash", color_hex]    screen flash (fire, magic)
##   [who, text, emotion?]    line; who "" = narration; "oli*" = inner thought;
##                            emotion picks a face (smile/neutral/sad/angry) on the 3D stage
## Click / Space / Enter = next (or finish typing). Esc / "ข้าม" = skip all.

signal finished

const NAMES := {
	"oli": "โอลี่", "haru": "ฮารุ", "ren": "เรน", "mio": "มิโอ", "setsu": "เซ็ตสึ",
	"leon": "เลออน", "fumi": "ฟุมิ", "lumi": "ลูมิ", "null": "น็อลล์", "kuroba": "คุโรบะ",
	"clover": "ใบสี่", "enji": "เอ็นจิ", "piang": "ป้าเพียง", "teacher": "ครู",
	"kai": "คาอิ", "thug": "ลูกน้อง", "staff": "เจ้าหน้าที่", "mom": "แม่", "grandma": "ยายชิโอะ",
	"victor": "พ่อ", "lily": "ลิลี่",
}
const BG := {
	"mansion": ["f3d9a8", "8a6a45"], "kitchen": ["e8b878", "5a3a22"], "school": ["a8d4f0", "4a6f9a"],
	"hallway": ["d6e4f0", "6a7f99"], "scanroom": ["cfe8ff", "2d4a75"], "rooftop": ["ffb27a", "5a3f7a"],
	"oldbuilding": ["5a5a66", "1e1e26"], "fire": ["ff8a3a", "3a0a0a"], "night": ["2a3060", "05060f"],
	"concert": ["c06aff", "1a0a3a"], "rain": ["7a8aa0", "2a3040"], "white": ["ffffff", "d0d0d0"],
	"city": ["8ac4f8", "b8b4aa"],
}
const Sheets := preload("res://scripts/sheets.gd")
const Stage := preload("res://scripts/cutscene_stage.gd")

var steps: Array = []
var i := -1
var bg_rect: TextureRect
var stage: SubViewportContainer   # 3D set + animated actors behind the dialogue
var caption: Label
var left_spr: TextureRect
var right_spr: TextureRect
var name_lbl: Label
var text_lbl: Label
var box: PanelContainer
var fade: ColorRect
var typing: Tween
var cast := {"left": "", "right": ""}
var voice: AudioStreamPlayer
var music_player: AudioStreamPlayer   # parent's music, ducked while someone speaks
var music_db := 0.0


func play(script: Array) -> void:
	steps = script
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	i = -1
	advance()


## Voice file for a line: assets/voice/<md5(who|text)[:12]>.mp3 (tools/voice/generate.mjs).
static func voice_path(who: String, text: String) -> String:
	return "res://assets/voice/%s.mp3" % ("%s|%s" % [who, text]).md5_text().substr(0, 12)


func _play_voice(who: String, text: String) -> void:
	voice.stop()
	var p := voice_path(who, text)
	if ResourceLoader.exists(p):
		voice.stream = load(p)
		voice.play()
		if music_player:
			music_player.volume_db = music_db - 12.0
	elif music_player:
		music_player.volume_db = music_db


func _build() -> void:
	voice = AudioStreamPlayer.new()
	voice.volume_db = 2.0
	add_child(voice)
	voice.finished.connect(func():
		if music_player: music_player.volume_db = music_db)
	var host = get_parent()
	if host and "music" in host and host.music is AudioStreamPlayer:
		music_player = host.music
		music_db = music_player.volume_db
	bg_rect = TextureRect.new()
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg_rect)
	stage = Stage.new()
	add_child(stage)
	_add_vignette()
	_set_bg("night")

	# 2D sprites stay as a fallback but the 3D stage shows the cast now
	left_spr = _sprite_slot(0.04)
	right_spr = _sprite_slot(0.62)
	left_spr.visible = false
	right_spr.visible = false

	caption = Label.new()
	caption.position = Vector2(30, 24)
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	caption.add_theme_constant_override("outline_size", 6)
	add_child(caption)

	box = PanelContainer.new()
	box.anchor_left = 0.03; box.anchor_right = 0.97
	box.anchor_top = 0.70; box.anchor_bottom = 0.96
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.13, 0.9)
	sb.border_color = Color("9b7bff")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(18)
	box.add_theme_stylebox_override("panel", sb)
	add_child(box)
	var v := VBoxContainer.new()
	box.add_child(v)
	name_lbl = Label.new()
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color("f5c542"))
	v.add_child(name_lbl)
	text_lbl = Label.new()
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.add_theme_font_size_override("font_size", 24)
	text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(text_lbl)

	var skip := Button.new()
	skip.text = "ข้าม ▶▶"
	skip.anchor_left = 1; skip.anchor_right = 1
	skip.offset_left = -120; skip.offset_right = -20; skip.offset_top = 20; skip.offset_bottom = 60
	skip.pressed.connect(skip_all)
	add_child(skip)

	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)


func _sprite_slot(x: float) -> TextureRect:
	var t := TextureRect.new()
	t.anchor_left = x; t.anchor_right = x + 0.34
	t.anchor_top = 0.04; t.anchor_bottom = 1.25
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t


func _set_bg(key: String) -> void:
	var cols: Array = BG.get(key, BG["night"])
	var g := Gradient.new()
	g.set_color(0, Color(cols[0]))
	g.set_color(1, Color(cols[1]))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0)
	gt.fill_to = Vector2(0.5, 1)
	bg_rect.texture = gt
	if stage:
		stage.set_location(key)


func _apply_cast() -> void:
	for slot in [["left", left_spr], ["right", right_spr]]:
		var id: String = cast[slot[0]]
		var spr: TextureRect = slot[1]
		spr.texture = Sheets.crop(id, "body") if id != "" else null
	if stage:
		stage.set_cast(cast["left"], cast["right"])


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		next()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_accept"):
		next()
	elif event.is_action_pressed("ui_cancel"):
		skip_all()


func next() -> void:
	if typing and typing.is_running():
		typing.kill()
		text_lbl.visible_ratio = 1.0
		return
	advance()


func skip_all() -> void:
	i = steps.size()
	advance()


var done := false


func advance() -> void:
	if done:
		return
	i += 1
	while i < steps.size() and str(steps[i][0]).begins_with("@"):
		_command(steps[i])
		i += 1
	if i >= steps.size():
		done = true
		if voice: voice.stop()
		if music_player: music_player.volume_db = music_db
		finished.emit()
		queue_free()
		return
	_line(steps[i])


func _command(s: Array) -> void:
	match s[0]:
		"@bg":
			_set_bg(s[1])
			caption.text = s[2] if s.size() > 2 else ""
			fade.color.a = 1.0
			create_tween().tween_property(fade, "color:a", 0.0, 0.5)
		"@cast":
			cast["left"] = s[1] if s.size() > 1 else ""
			cast["right"] = s[2] if s.size() > 2 else ""
			_apply_cast()
		"@group":
			cast["left"] = ""
			cast["right"] = ""
			if stage:
				stage.set_group(s.slice(1))
		"@flash":
			if stage:
				stage.photo_flash()
			fade.color = Color(s[1])
			fade.color.a = 0.85
			var tw := create_tween()
			tw.tween_property(fade, "color:a", 0.0, 0.6)
			tw.tween_callback(func(): fade.color = Color(0, 0, 0, 0))


func _line(s: Array) -> void:
	_play_voice(s[0], s[1])
	var who: String = s[0]
	var thought := who.ends_with("*")
	who = who.trim_suffix("*")
	name_lbl.text = NAMES.get(who, who) + ("  (ในใจ)" if thought else "")
	name_lbl.visible = who != ""
	text_lbl.text = s[1]
	if who == "":
		text_lbl.add_theme_color_override("font_color", Color("b8bce0"))
	elif thought:
		text_lbl.add_theme_color_override("font_color", Color("9fd8ff"))
	else:
		text_lbl.add_theme_color_override("font_color", Color("ffffff"))
	# a speaker who isn't on stage yet walks on (fills an empty slot, else the right one)
	if stage and who != "" and who != cast["left"] and who != cast["right"] and not stage.has_actor(who):
		var slot := "right" if cast["right"] == "" or cast["left"] != "" else "left"
		cast[slot] = who
		stage.set_cast(cast["left"], cast["right"])
	# camera cuts to the speaker (inner thoughts: close-up but no lip movement)
	if stage:
		stage.focus(who, not thought, str(s[2]) if s.size() > 2 else "")
	# the speaker stays bright, the other sprite dims
	left_spr.modulate = Color(1, 1, 1) if who == cast["left"] or who == "" else Color(0.5, 0.5, 0.6)
	right_spr.modulate = Color(1, 1, 1) if who == cast["right"] or who == "" else Color(0.5, 0.5, 0.6)
	text_lbl.visible_ratio = 0.0
	typing = create_tween()
	typing.tween_property(text_lbl, "visible_ratio", 1.0, max(0.3, s[1].length() * 0.03))


## Soft dark edges over the 3D stage (cinematic, and almost free: one textured quad).
func _add_vignette() -> void:
	if preload("res://scripts/look.gd").quality() == "off":
		return
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.55))
	g.set_offset(0, 0.55)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 0.5)
	gt.width = 256
	gt.height = 256
	var v := TextureRect.new()
	v.name = "vignette"
	v.texture = gt
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	v.stretch_mode = TextureRect.STRETCH_SCALE
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
