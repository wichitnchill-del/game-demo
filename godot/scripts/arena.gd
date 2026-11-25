extends Node3D
## Real-time 3D action battle. One hero on the field at a time, tag-switch
## between the five (Q / E). Combat rules from game-design.md, made real-time:
## element advantage, magic breath, seal cracks, each power's price.
##
## Controls: WASD move · Space jump · J attack (3-hit combo) · K power
##           L dodge (i-frames) · Q / E switch hero
signal finished(won: bool)

const Sheets := preload("res://scripts/sheets.gd")
const Vfx := preload("res://scripts/vfx.gd")
const ARENA_HALF := 16.0

## Each power: cost (breath), cooldown, description shown in HUD.
const POWERS := {
	"ren":   {"name": "Support สามวินาที", "cost": 40, "cd": 9.0, "desc": "ทุกคนดาเมจ x2 นาน 3 วิ"},
	"mio":   {"name": "กำแพงดิน", "cost": 30, "cd": 7.0, "desc": "กระแทกพื้นรอบตัว + เกราะ 3 วิ"},
	"oli":   {"name": "เอียงโชค", "cost": 0, "cd": 10.0, "desc": "คริติคอลทุกครั้ง 5 วิ · ใบโคลเวอร์ร้าว"},
	"haru":  {"name": "น้ำสะท้อน", "cost": 25, "cd": 6.0, "desc": "คลื่นน้ำ + เผยจุดอ่อน · ป้องกันลด"},
	"setsu": {"name": "ศรลม", "cost": 30, "cd": 3.5, "desc": "ยิงลมทะลุ ดาเมจสูง"},
}

var font: Font
var heroes: Array = []        # fighter nodes, one per Game.party member (index-aligned)
var active := 0
var enemies: Array = []
var projectiles: Array = []   # dicts {node, vel, dmg, el, team, life, pierce, hit}
var cam: Camera3D
var hud: CanvasLayer
var hud_party: HBoxContainer
var hud_power: Label
var hud_boss: ProgressBar
var hud_boss_name: Label
var hud_msg: Label
var msg_time := 0.0

var combo := 0
var combo_timer := 0.0
var attack_cd := 0.0
var dodge_cd := 0.0
var switch_cd := 0.0
var power_cd := {}
var team_buff := 0.0          # Ren: damage x2
var oli_luck := 0.0           # Oli: always crit
var mio_armor := 0.0          # Mio: damage taken x0.3, no knockback
var haru_exposed := 0.0       # Haru: takes x1.4
var weak_revealed := false
var ended := false
var time := 0.0
var autopilot := false        # tests / demo: AI drives the hero


func _ready() -> void:
	_setup_input()
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Thonburi", "Sukhumvit Set", "Noto Sans Thai", "Leelawadee UI", "Tahoma"])
	font = f
	_build_world()


## wave: Array of enemy dicts from Game.WAVES (already scaled by the caller).
func start(wave: Array) -> void:
	for i in Game.party.size():
		var p: Dictionary = Game.party[i]
		p["buff"] = 0
		var h := _spawn_fighter(p, true, Vector3(-3 + i * 0.1, 0.5, 6))
		h.visible = false
		h.process_mode = Node.PROCESS_MODE_DISABLED
		heroes.append(h)
	for p in POWERS:
		power_cd[p] = 0.0
	active = -1
	_switch_to(_next_alive(0, 1))
	for i in wave.size():
		var e: Dictionary = wave[i]
		var x := 0.0
		if wave.size() > 1:
			x = -4.0 + i * 8.0 / (wave.size() - 1)
		var pos := Vector3(x, 0.5, -6)
		var f := _spawn_fighter(e, false, pos)
		e["atk_cd"] = randf_range(1.0, 2.0)
		e["windup"] = 0.0
		e["shot_cd"] = 2.5
		enemies.append(f)
	_build_hud()
	weak_revealed = not wave.any(func(e): return e.get("hidden", false))
	_message("ด่าน %d — สู้!" % (Game.wave + 1))


# ---------------- world ----------------
func _setup_input() -> void:
	preload("res://scripts/controls.gd").apply("story", self)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m


func _box(size: Vector3, pos: Vector3, color: Color, solid := true) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color)
	mi.position = pos
	if solid:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1 | 2
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new(); sh.size = size
		cs.shape = sh
		sb.add_child(cs)
		sb.position = pos
		add_child(sb)
	add_child(mi)


func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("2a3050") if Game.wave < 2 else Color("120c1e")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.85)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	add_child(sun)
	preload("res://scripts/look.gd").apply(e, sun, self)   # no fog: small dark arena

	# old wooden school building floor (P1-finale location)
	var floor_col: Color = [Color("7a5a3a"), Color("5a4a3a"), Color("3a2a2a")][clamp(Game.wave, 0, 2)]
	_box(Vector3(ARENA_HALF * 2, 1, ARENA_HALF * 2), Vector3(0, -0.5, 0), floor_col)
	for i in range(-7, 8):  # floor planks
		_box(Vector3(0.05, 0.02, ARENA_HALF * 2), Vector3(i * 2.2, 0.01, 0), floor_col.darkened(0.25), false)
	# walls
	var wall := Color("4a3a2e")
	_box(Vector3(ARENA_HALF * 2, 3, 0.6), Vector3(0, 1.5, -ARENA_HALF), wall)
	_box(Vector3(ARENA_HALF * 2, 3, 0.6), Vector3(0, 1.5, ARENA_HALF), wall)
	_box(Vector3(0.6, 3, ARENA_HALF * 2), Vector3(-ARENA_HALF, 1.5, 0), wall)
	_box(Vector3(0.6, 3, ARENA_HALF * 2), Vector3(ARENA_HALF, 1.5, 0), wall)
	# cover: desks / fallen beams
	for p in [Vector3(-7, 0.5, -2), Vector3(7, 0.5, 2), Vector3(0, 0.5, 9), Vector3(-9, 0.5, 8), Vector3(9, 0.5, -9)]:
		_box(Vector3(2.2, 1.0, 1.0), p, Color("6a4a2a"))
	_box(Vector3(6, 0.5, 0.5), Vector3(3, 0.25, -10), Color("3a2a1a"))
	if Game.wave == 1:  # fire scene: glowing embers
		var l := OmniLight3D.new()
		l.light_color = Color("ff7a2a"); l.light_energy = 3.0; l.omni_range = 14
		l.position = Vector3(0, 3, -8)
		add_child(l)

	cam = Camera3D.new()
	cam.fov = 55
	cam.current = true
	add_child(cam)


func _spawn_fighter(d: Dictionary, hero: bool, pos: Vector3) -> Fighter:
	var f := Fighter.new()
	add_child(f)
	f.setup(d, hero, font)
	f.global_position = pos
	if not hero:
		f.speed = d.get("speed", 4.2)
	return f


# ---------------- HUD ----------------
func _label(t: String, size := 16, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 5)
	return l


func _bar(col: Color, w := 120.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(w, 9)
	var fill := StyleBoxFlat.new(); fill.bg_color = col
	var bg := StyleBoxFlat.new(); bg.bg_color = Color(0, 0, 0, 0.6)
	b.add_theme_stylebox_override("fill", fill)
	b.add_theme_stylebox_override("background", bg)
	return b


func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	hud_party = HBoxContainer.new()
	hud_party.position = Vector2(16, 560)
	hud_party.add_theme_constant_override("separation", 10)
	hud.add_child(hud_party)
	for i in heroes.size():
		var p: Dictionary = Game.party[i]
		var box := VBoxContainer.new()
		box.name = "h%d" % i
		var face := TextureRect.new()
		face.texture = Sheets.crop(p["id"], "face")
		face.custom_minimum_size = Vector2(64, 64)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		face.name = "face"
		box.add_child(face)
		var n := _label("%d %s" % [i + 1, p["name"]], 14); n.name = "name"
		box.add_child(n)
		var hp := _bar(Color("4cd28a")); hp.name = "hp"; box.add_child(hp)
		var br := _bar(Color("5ab8ef")); br.name = "br"; box.add_child(br)
		var st := _label("", 12); st.name = "st"; box.add_child(st)
		hud_party.add_child(box)
	hud_power = _label("", 16, Color("f5c542"))
	hud_power.position = Vector2(700, 600)
	hud.add_child(hud_power)
	var keys := _label("WASD เดิน · Space กระโดด · คลิกซ้าย โจมตี · คลิกขวา พลัง · C/Ctrl หลบ · Q/E สลับตัว", 13, Color("c8cce8"))
	keys.position = Vector2(16, 12)
	var touch := get_node_or_null("/root/Touch")
	keys.visible = not (touch and touch.enabled)
	hud.add_child(keys)
	if touch and touch.enabled:
		# thumbs own the bottom corners: party goes top-left (smaller), info shifts right
		hud_party.position = Vector2(12, 10)
		hud_party.scale = Vector2(0.75, 0.75)
		hud_power.position = Vector2(520, 100)
	hud_boss_name = _label("", 18, Color("ffb0a0"))
	hud_boss_name.position = Vector2(390, 36)
	hud.add_child(hud_boss_name)
	hud_boss = _bar(Color("ef5a5a"), 500)
	hud_boss.position = Vector2(390, 64)
	hud.add_child(hud_boss)
	if touch and touch.enabled:
		hud_boss_name.position.x = 520
		hud_boss.position.x = 520
	hud_msg = _label("", 30, Color("f5c542"))
	hud_msg.position = Vector2(0, 250)
	hud_msg.size = Vector2(1280, 60)
	hud_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(hud_msg)


func _update_hud(delta: float) -> void:
	for i in heroes.size():
		var p: Dictionary = Game.party[i]
		var box := hud_party.get_node("h%d" % i)
		(box.get_node("hp") as ProgressBar).max_value = p["maxhp"]
		(box.get_node("hp") as ProgressBar).value = p["hp"]
		(box.get_node("br") as ProgressBar).value = p["breath"]
		var st: String = ["ตราปกติ", "ตราร้าว", "ตราแตก"][p["seal"]]
		if p["id"] == "oli":
			st += " ใบโคลเวอร์ %d/3" % Game.clover
		var l: Label = box.get_node("st")
		l.text = st
		l.add_theme_color_override("font_color", [Color("4cd28a"), Color("f5c542"), Color("ef5a5a")][p["seal"]])
		box.modulate = Color(1, 1, 1) if i == active else (Color(0.45, 0.45, 0.5) if not heroes[i].alive() else Color(0.75, 0.75, 0.8))
		(box.get_node("name") as Label).text = ("▶ " if i == active else "") + "%d %s" % [i + 1, p["name"]]
	var id: String = Game.party[active]["id"]
	var pw: Dictionary = POWERS[id]
	var cd: float = power_cd[id]
	var state := "พร้อม" if cd <= 0 else "%.1f วิ" % cd
	if id == "oli" and Game.clover >= 3:
		state = "ใบโคลเวอร์ร่วงแล้ว"
	var fx := []
	if team_buff > 0: fx.append("ดาเมจx2 %.0f" % team_buff)
	if oli_luck > 0: fx.append("คริ %.0f" % oli_luck)
	if mio_armor > 0: fx.append("เกราะ %.0f" % mio_armor)
	if haru_exposed > 0: fx.append("ป้องกันลด")
	hud_power.text = "[K] %s — %s (%s)\n%s\n%s" % [pw["name"], pw["desc"], state,
		"ลมหายใจ %d · ใช้ %d" % [Game.party[active]["breath"], pw["cost"]], "  ".join(fx)]
	var boss = null
	for e in enemies:
		if e.data.get("boss", false) or enemies.size() == 1:
			boss = e
	if boss:
		hud_boss_name.text = boss.data["name"] + ("  · จุดอ่อน: เผยแล้ว x1.6" if weak_revealed and boss.data.get("hidden", false) else ("  · จุดอ่อน: ??? (ใช้น้ำสะท้อนของฮารุ)" if boss.data.get("hidden", false) else ""))
		hud_boss.max_value = boss.data["maxhp"]
		hud_boss.value = boss.data["hp"]
	else:
		var left := enemies.filter(func(e): return e.alive()).size()
		hud_boss_name.text = "ศัตรูเหลือ %d" % left
		hud_boss.visible = false
	msg_time -= delta
	hud_msg.visible = msg_time > 0


func _message(t: String, dur := 1.8) -> void:
	if hud_msg:
		hud_msg.text = t
	msg_time = dur


func _popup(pos: Vector3, t: String, col: Color, size := 56) -> void:
	var l := Label3D.new()
	l.font = font
	l.text = t
	l.font_size = size
	l.pixel_size = 0.006
	l.modulate = col
	l.outline_size = 12
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.3, 0.3), 2.2, 0)
	var tw := create_tween()
	tw.tween_property(l, "global_position:y", l.global_position.y + 1.2, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.tween_callback(l.queue_free)


func _ring(pos: Vector3, radius: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius * 0.85; tm.outer_radius = radius
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	add_child(mi)
	mi.global_position = pos + Vector3(0, 0.1, 0)
	mi.scale = Vector3(0.3, 1, 0.3)
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.25)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.4)
	tw.tween_callback(mi.queue_free)


# ---------------- main loop ----------------
func hero() -> Fighter:
	return heroes[active]


func _physics_process(delta: float) -> void:
	if ended or heroes.is_empty():
		return
	time += delta
	for k in power_cd:
		power_cd[k] = max(0.0, power_cd[k] - delta)
	attack_cd = max(0.0, attack_cd - delta)
	dodge_cd = max(0.0, dodge_cd - delta)
	switch_cd = max(0.0, switch_cd - delta)
	combo_timer -= delta
	if combo_timer <= 0:
		combo = 0
	team_buff = max(0.0, team_buff - delta)
	oli_luck = max(0.0, oli_luck - delta)
	mio_armor = max(0.0, mio_armor - delta)
	haru_exposed = max(0.0, haru_exposed - delta)
	# breath regenerates for everyone (benched heroes faster)
	for i in Game.party.size():
		var p: Dictionary = Game.party[i]
		if p["seal"] < 2:
			p["breath"] = min(100.0, p["breath"] + delta * (5.0 if i == active else 9.0))

	if autopilot:
		_autopilot()
	else:
		_player_input()
	_enemy_ai(delta)
	_projectiles(delta)
	_camera(delta)
	_update_hud(delta)
	_check_end()


func _player_input() -> void:
	var h := hero()
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	h.move_dir = Vector3(v.x, 0, v.y)
	if Input.is_action_just_pressed("jump"): h.jump()
	if Input.is_action_just_pressed("attack"): attack()
	if Input.is_action_just_pressed("power"): power()
	if Input.is_action_just_pressed("dodge"): dodge()
	if Input.is_action_just_pressed("switch_next"): switch_hero(1)
	if Input.is_action_just_pressed("switch_prev"): switch_hero(-1)
	for i in 5:
		if Input.is_physical_key_pressed(KEY_1 + i) and i != active and heroes[i].alive() and switch_cd <= 0:
			_switch_to(i)


func _camera(delta: float) -> void:
	var target := hero().global_position
	var want := target + Vector3(0, 4.6, 7.2)
	cam.global_position = cam.global_position.lerp(want, min(1.0, delta * 6.0)) if time > 0.1 else want
	cam.look_at(target + Vector3(0, 1.3, -1.5))


# ---------------- hero actions ----------------
func _elem_mult(a: String, d: String) -> float:
	return Game.mult(a, d)


func _hero_damage(base_mult: float, target: Dictionary) -> Array:
	var p: Dictionary = Game.party[active]
	var crit := oli_luck > 0 or randf() < 0.08
	var d: float = p["atk"] * base_mult * _elem_mult(p["el"], target["el"])
	d *= Game.bond_atk_mult(p["id"])
	if team_buff > 0: d *= 2.0
	if crit: d *= 2.5 if oli_luck > 0 else 1.8
	if target.get("hidden", false) and weak_revealed: d *= 1.6
	return [int(round(d * randf_range(0.9, 1.1))), crit]


func _hit_enemy(e: Fighter, base_mult: float, kb: float, src: Vector3) -> void:
	if not e.alive():
		return
	var r := _hero_damage(base_mult, e.data)
	var dmg: int = r[0]
	e.data["hp"] = max(0, e.data["hp"] - dmg)
	e.flash = 0.15
	var away: Vector3 = e.global_position - src
	away.y = 0
	if e.data.get("boss", false):
		kb *= 0.35
	else:
		e.data["windup"] = 0.0   # hit interrupts the enemy's attack
		e.lock = 0.25
	e.knock = away.normalized() * kb
	var m := _elem_mult(Game.party[active]["el"], e.data["el"])
	_popup(e.global_position, ("%d!" if r[1] else "%d") % dmg, Color("ffe14a") if r[1] else (Color("7dffa0") if m > 1 else Color.WHITE), 70 if r[1] else 52)
	if e.data["hp"] <= 0:
		_popup(e.global_position, "ล้ม!", Color("ffb0a0"))
		e.collision_layer = 0


func attack() -> void:
	var h := hero()
	if attack_cd > 0 or not h.alive() or h.dash > 0:
		return
	combo = combo % 3 + 1
	combo_timer = 0.7
	attack_cd = 0.32 if combo < 3 else 0.55
	h.lock = 0.15
	var reach := 2.3
	# auto-face the nearest enemy in reach (arena-fighter style soft lock-on)
	var near = _nearest_enemy(h.global_position, 4.0)
	if near:
		var to: Vector3 = near.global_position - h.global_position
		to.y = 0
		if to.length() > 0.1:
			h.facing = to.normalized()
	h.knock = h.facing * 3.0   # lunge
	var hits := 0
	for e in enemies:
		if not e.alive():
			continue
		var to2: Vector3 = e.global_position - h.global_position
		to2.y = 0
		if to2.length() <= reach and h.facing.dot(to2.normalized()) > 0.2 and _clear_line(h.global_position, e.global_position):
			_hit_enemy(e, 1.0 if combo < 3 else 1.6, 4.0 if combo < 3 else 11.0, h.global_position)
			hits += 1
	_ring(h.global_position + h.facing * 1.2, 0.9 if combo < 3 else 1.4, Color(1, 1, 1, 0.8))
	h.act("attack" if combo < 3 else "attack2", 0.42 if combo < 3 else 0.6, 1.8)
	Vfx.spawn(self, "swing" if combo < 3 else "slash", h.global_position + Vector3(0, 1.1, 0) + h.facing * 0.6, h.facing, Vfx.element_color(Game.party[active]["el"]), 0.35, 0.8)


func dodge() -> void:
	var h := hero()
	if dodge_cd > 0 or not h.alive():
		return
	dodge_cd = 0.7
	h.start_dash(h.move_dir)


## Using a power with too little breath still works — but the seal cracks
## (game-design.md: "ใช้เกินตัวแล้วร้าว").
func _pay(p: Dictionary, cost: float) -> void:
	p["breath"] -= cost * p.get("drain", 1.0)
	if p["breath"] < 0:
		p["breath"] = 0.0
		_crack(active, "ฝืนใช้เวทตอนลมหายใจหมด")
	elif p.get("crack_easy", false) and p["breath"] < 35 and p["seal"] == 0 and randf() < 0.5:
		_crack(active, "เสริมเกินตัว")


func _crack(i: int, why: String) -> void:
	var p: Dictionary = Game.party[i]
	if p["seal"] >= 2:
		return
	p["seal"] += 1
	if p["seal"] == 1:
		_message("ตราของ%sร้าว — %s" % [p["name"], why], 2.2)
	else:
		_message("ตราของ%sแตก! ออกจากการต่อสู้" % p["name"], 2.5)
		_on_hero_down(i)


func power() -> void:
	var h := hero()
	var p: Dictionary = Game.party[active]
	var id: String = p["id"]
	if power_cd[id] > 0 or not h.alive():
		return
	if id == "oli" and Game.clover >= 3:
		_message("ใบโคลเวอร์ร่วงไปแล้ว…")
		return
	power_cd[id] = POWERS[id]["cd"]
	h.act("attack2" if ["haru", "setsu"].has(id) else ("call" if id == "ren" else "power"), 0.7, 1.5)
	Vfx.spawn(self, "charge", h.global_position, Vector3.ZERO, Vfx.element_color(p["el"]), 0.6, 0.8)
	_pay(p, POWERS[id]["cost"])
	if not h.alive():
		return
	match id:
		"ren":
			team_buff = 3.0
			_message("“เสริม… สามวินาที”")
			_ring(h.global_position, 4.0, Color(0.6, 0.8, 1, 0.9))
		"mio":
			mio_armor = 3.0
			_ring(h.global_position, 3.5, Color(0.8, 0.6, 0.3, 0.9))
			for e in enemies:
				if e.alive() and e.global_position.distance_to(h.global_position) < 3.5:
					_hit_enemy(e, 1.8, 12.0, h.global_position)
		"oli":
			Game.clover += 1
			oli_luck = 5.0
			_message("ใบโคลเวอร์ร้าว %d/3" % Game.clover)
			if Game.clover >= 3:
				_message("ใบโคลเวอร์ร่วง… ที่บ้าน ป้าเพียงอ่อนแรงลง", 3.0)
			h.invuln = 1.0
			_ring(h.global_position, 2.5, Color(0.5, 1, 0.6, 0.9))
		"haru":
			haru_exposed = 4.0
			weak_revealed = true
			_shoot(h, Color(0.4, 0.7, 1), 1.4, 11.0, true, 1.2)
			_message("น้ำสะท้อน… เห็นจุดอ่อน")
		"setsu":
			_shoot(h, Color(0.7, 1, 0.8), 2.6, 26.0, true, 0.5)


func _shoot(h: Fighter, col: Color, mult: float, spd: float, pierce: bool, size: float) -> void:
	var near = _nearest_enemy(h.global_position, 30.0)
	var dir: Vector3 = h.facing
	if near:
		dir = near.global_position - h.global_position
		dir.y = 0
		dir = dir.normalized()
		h.facing = dir
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = size * 0.5; sm.height = size
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true; m.emission = col
	mi.material_override = m
	add_child(mi)
	mi.global_position = h.global_position + Vector3(0, 1.1, 0) + dir * 0.8
	projectiles.append({"node": mi, "vel": dir * spd, "mult": mult, "team": "hero", "life": 1.6, "pierce": pierce, "hit": [], "r": size * 0.6 + 0.4})


func switch_hero(step: int) -> void:
	if switch_cd > 0:
		return
	var n := _next_alive(active + step, step)
	if n != -1 and n != active:
		_switch_to(n)


func _next_alive(from: int, step: int) -> int:
	var n := heroes.size()
	for k in n:
		var i := posmod(from + k * step, n)
		if heroes[i].alive():
			return i
	return -1


func _switch_to(i: int) -> void:
	if i < 0:
		return
	var pos := Vector3(0, 0.5, 6)
	var face := Vector3(0, 0, -1)
	if active >= 0:
		var old: Fighter = heroes[active]
		pos = old.global_position
		face = old.facing
		old.visible = false
		old.process_mode = Node.PROCESS_MODE_DISABLED
		old.move_dir = Vector3.ZERO
	active = i
	var h: Fighter = heroes[i]
	h.process_mode = Node.PROCESS_MODE_INHERIT
	h.visible = true
	h.global_position = pos + Vector3(0, 0.2, 0)
	h.facing = face
	h.invuln = 0.6
	switch_cd = 0.8
	combo = 0
	if hud:
		_ring(pos, 1.5, Color(1, 1, 1, 0.8))
		_message("สลับเป็น %s" % Game.party[i]["name"], 0.8)


func _on_hero_down(i: int) -> void:
	if i == active:
		var n := _next_alive(i + 1, 1)
		if n != -1:
			_switch_to(n)


func _nearest_enemy(pos: Vector3, max_d: float):
	var best = null
	var bd := max_d
	for e in enemies:
		if e.alive():
			var d: float = e.global_position.distance_to(pos)
			if d < bd:
				bd = d; best = e
	return best


# ---------------- enemies ----------------
func _damage_hero(dmg_base: float, el: String, src: Vector3, kb: float) -> void:
	var h := hero()
	if not h.alive() or h.invuln > 0:
		return
	var p: Dictionary = Game.party[active]
	var d := dmg_base * _elem_mult(el, p["el"])
	if mio_armor > 0 and p["id"] == "mio": d *= 0.3
	if haru_exposed > 0 and p["id"] == "haru": d *= 1.4
	var dmg := int(round(d * randf_range(0.9, 1.1)))
	p["hp"] = max(0, p["hp"] - dmg)
	h.flash = 0.2
	h.invuln = 0.4
	if not (mio_armor > 0 and p["id"] == "mio"):
		var away: Vector3 = h.global_position - src
		away.y = 0
		h.knock = away.normalized() * kb
		h.lock = 0.2
	_popup(h.global_position, "-%d" % dmg, Color("ff6a6a"))
	if p["hp"] <= 0:
		_message("%sหมดสติ!" % p["name"])
		_on_hero_down(active)


func _enemy_ai(delta: float) -> void:
	var h := hero()
	for e in enemies:
		var d: Dictionary = e.data
		if not e.alive():
			e.move_dir = Vector3.ZERO
			continue
		var to: Vector3 = h.global_position - e.global_position
		to.y = 0
		var dist := to.length()
		d["atk_cd"] -= delta
		if d["windup"] > 0:
			d["windup"] -= delta
			e.move_dir = Vector3.ZERO
			if d["windup"] <= 0:
				# strike lands only if the hero is still in front and close
				_ring(e.global_position + e.facing * 1.1, 1.3, Color(1, 0.4, 0.3, 0.9))
				if dist < 2.4 and e.facing.dot(to.normalized()) > 0.3 and _clear_line(e.global_position, h.global_position):
					_damage_hero(d["atk"] * 1.3, d["el"], e.global_position, 9.0)
				d["atk_cd"] = randf_range(0.7, 1.3) if not d.get("boss", false) else 0.6
			continue
		# boss: fireballs at range
		if d.get("boss", false):
			d["shot_cd"] -= delta
			var enraged: bool = d["hp"] < d["maxhp"] * 0.5
			if d["shot_cd"] <= 0 and dist > 3.5 and _clear_line(e.global_position, h.global_position):
				d["shot_cd"] = 1.4 if enraged else 2.4
				var dir := to.normalized()
				_enemy_fireball(e, dir, d)
				if enraged and d.get("leon", false):
					_enemy_fireball(e, dir.rotated(Vector3.UP, 0.35), d)
					_enemy_fireball(e, dir.rotated(Vector3.UP, -0.35), d)
			d["dash_cd"] = d.get("dash_cd", 4.0) - delta
			if d["dash_cd"] <= 0 and dist > 5.0 and dist < 12.0:
				d["dash_cd"] = 3.0 if enraged else 5.0
				e.start_dash(to.normalized())
				if not d.get("enraged_said", false) and enraged:
					d["enraged_said"] = true
					_message("%s: “แค่นี้เองเหรอ ลูกคนกลาง”" % d["name"], 2.0)
		var can_hit := dist <= 1.9 and _clear_line(e.global_position, h.global_position)
		if not can_hit:
			e.move_dir = _steer(e.global_position, h.global_position) * (0.55 if d.get("boss", false) and dist > 6 else 1.0)
		else:
			e.move_dir = Vector3.ZERO
			e.facing = to.normalized()
			if d["atk_cd"] <= 0 and h.alive():
				d["windup"] = 0.45 if not d.get("boss", false) else 0.35   # telegraph: dodge now!
	# enemies don't stack on top of each other
	for a in enemies:
		for b in enemies:
			if a != b and a.alive() and b.alive():
				var sep: Vector3 = a.global_position - b.global_position
				sep.y = 0
				if sep.length() < 1.2 and sep.length() > 0.01:
					a.knock += sep.normalized() * 0.4


func _enemy_fireball(e: Fighter, dir: Vector3, d: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.35; sm.height = 0.7
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("ff7a2a"); m.emission_enabled = true; m.emission = Color("ff5a1a")
	mi.material_override = m
	add_child(mi)
	mi.global_position = e.global_position + Vector3(0, 1.2, 0) + dir * 0.8
	projectiles.append({"node": mi, "vel": dir * 9.0, "dmg": d["atk"] * 0.8, "el": d["el"], "team": "enemy", "life": 2.5, "pierce": false, "hit": [], "r": 0.7})


func _projectiles(delta: float) -> void:
	for pr in projectiles.duplicate():
		var n: MeshInstance3D = pr["node"]
		n.global_position += pr["vel"] * delta
		pr["life"] -= delta
		var gone: bool = pr["life"] <= 0 or abs(n.global_position.x) > ARENA_HALF or abs(n.global_position.z) > ARENA_HALF \
			or not _clear_line(n.global_position - Vector3(0, 0.9, 0), n.global_position - Vector3(0, 0.9, 0) + pr["vel"] * delta)
		if pr["team"] == "hero":
			for e in enemies:
				if e.alive() and not pr["hit"].has(e) and _flat_dist(e.global_position, n.global_position) < pr["r"]:
					pr["hit"].append(e)
					_hit_enemy(e, pr["mult"], 7.0, n.global_position - pr["vel"].normalized())
					if not pr["pierce"]:
						gone = true
		else:
			var h := hero()
			if h.alive() and _flat_dist(h.global_position, n.global_position) < pr["r"]:
				_damage_hero(pr["dmg"], pr["el"], n.global_position - pr["vel"].normalized(), 7.0)
				gone = true
		if gone:
			n.queue_free()
			projectiles.erase(pr)


## True when no wall/crate is between a and b (checked at chest height).
func _clear_line(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a + Vector3(0, 0.9, 0), b + Vector3(0, 0.9, 0), 2)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## Direction to walk toward `to`, sidestepping around scenery that blocks the straight line.
func _steer(from: Vector3, to: Vector3) -> Vector3:
	var d := to - from
	d.y = 0
	if d.length() < 0.01:
		return Vector3.ZERO
	d = d.normalized()
	if _clear_line(from, from + d * 1.6):
		return d
	for ang in [0.8, -0.8, 1.5, -1.5]:
		var alt := d.rotated(Vector3.UP, ang)
		if _clear_line(from, from + alt * 1.6):
			return alt
	return d


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# ---------------- end ----------------
func _check_end() -> void:
	if enemies.all(func(e): return not e.alive()):
		_end(true)
	elif heroes.all(func(h): return not h.alive()):
		_end(false)


func _end(won: bool) -> void:
	if ended:
		return
	ended = true
	hero().move_dir = Vector3.ZERO
	_message("ชนะ!" if won else "ทีมหมดแรง…", 3.0)
	_update_hud(0)
	await get_tree().create_timer(1.6 if not autopilot else 0.05).timeout
	finished.emit(won)


# ---------------- autopilot (tests / attract mode) ----------------
func _autopilot() -> void:
	var h := hero()
	var target = _nearest_enemy(h.global_position, 99.0)
	if target == null:
		h.move_dir = Vector3.ZERO
		return
	var to: Vector3 = target.global_position - h.global_position
	to.y = 0
	# dodge telegraphed strikes and incoming fireballs
	for e in enemies:
		if e.alive() and e.data["windup"] > 0 and e.data["windup"] < 0.25 and e.global_position.distance_to(h.global_position) < 2.6:
			h.move_dir = -to.normalized()
			dodge()
	var id: String = Game.party[active]["id"]
	if power_cd[id] <= 0 and Game.party[active]["breath"] >= POWERS[id]["cost"] and randf() < 0.02:
		if not (id == "oli" and Game.clover >= 2):
			power()
	if to.length() > 1.8 or not _clear_line(h.global_position, target.global_position):
		h.move_dir = _steer(h.global_position, target.global_position)
	else:
		h.move_dir = Vector3.ZERO
		attack()
	var p: Dictionary = Game.party[active]
	if p["hp"] < p["maxhp"] * 0.3 and randf() < 0.05:
		switch_hero(1)
