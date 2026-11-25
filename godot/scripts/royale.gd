extends Node3D
## Core Blaker: Battle Royale — 8 teams × 3 fighters on a 3D city map.
## Quirk-style powers instead of guns, seal cards to level skills, a shrinking
## "Forgetting Fog" zone, down-and-revive, last team standing wins.
##
## Controls: WASD move · Space jump · J/LMB attack · K/RMB power · I ultimate
##           L/Shift dodge · F (hold) revive teammate
signal finished(placement: int, stats: Dictionary)

const Sheets := preload("res://scripts/sheets.gd")
const Vfx := preload("res://scripts/vfx.gd")
const MAP_HALF := 90.0
const DAMAGE_SCALE := 0.42  # 24 fighters at once: keep time-to-kill readable
const HP_SCALE := 1.3
const TEAMS := 8
const TEAM_SIZE := 3
const TEAM_COLORS := ["5ab8ff", "ff6a6a", "ffd24a", "7dff9a", "d08aff", "ff9a3a", "4ae0d0", "ff8ad0"]
const TEAM_NAMES := ["ทีมเรา", "ทีมเพลิง", "ทีมสายฟ้า", "ทีมใบไม้", "ทีมม่วง", "ทีมส้ม", "ทีมคลื่น", "ทีมซากุระ"]

const ROSTER := ["oli", "haru", "ren", "mio", "setsu", "leon", "lumi", "null", "kuroba", "fumi"]
const STATS := {
	"oli":    {"name": "โอลี่",  "el": "ลม",  "hp": 150, "atk": 12, "speed": 6.6},
	"haru":   {"name": "ฮารุ",   "el": "น้ำ", "hp": 140, "atk": 13, "speed": 6.3},
	"ren":    {"name": "เรน",    "el": "",    "hp": 150, "atk": 11, "speed": 6.4},
	"mio":    {"name": "มิโอ",   "el": "ดิน", "hp": 210, "atk": 13, "speed": 5.8},
	"setsu":  {"name": "เซ็ตสึ", "el": "ลม",  "hp": 130, "atk": 13, "speed": 6.6},
	"leon":   {"name": "เลออน",  "el": "ไฟ",  "hp": 170, "atk": 15, "speed": 6.2},
	"lumi":   {"name": "ลูมิ",   "el": "",    "hp": 140, "atk": 11, "speed": 6.5},
	"null":   {"name": "น็อลล์", "el": "",    "hp": 150, "atk": 13, "speed": 6.4},
	"kuroba": {"name": "คุโรบะ", "el": "",    "hp": 150, "atk": 12, "speed": 6.2},
	"fumi":   {"name": "ฟุมิ",   "el": "",    "hp": 135, "atk": 10, "speed": 6.4},
}
## power: cost = breath, cd = seconds, range = how close bots must be to use it
const POWERS := {
	"oli":    {"name": "เอียงโชค",     "cost": 25, "cd": 11.0, "range": 4.0, "desc": "คริติคอลทุกครั้ง 5 วิ + หลบอัตโนมัติ"},
	"haru":   {"name": "น้ำสะท้อน",    "cost": 25, "cd": 7.0,  "range": 12.0, "desc": "คลื่นน้ำทะลุ · ศัตรูที่โดนถูกเผยบนแผนที่"},
	"ren":    {"name": "Support",      "cost": 35, "cd": 13.0, "range": 8.0, "desc": "เพื่อนรอบตัวดาเมจ x1.6 นาน 4 วิ"},
	"mio":    {"name": "กำแพงดิน",     "cost": 30, "cd": 9.0,  "range": 3.5, "desc": "กระแทกพื้นรอบตัว + เกราะ 3 วิ"},
	"setsu":  {"name": "ศรลม",         "cost": 25, "cd": 4.5,  "range": 16.0, "desc": "ยิงลมทะลุ ดาเมจสูง"},
	"leon":   {"name": "เพลิงสามสาย",  "cost": 30, "cd": 7.5,  "range": 12.0, "desc": "ลูกไฟกระจาย 3 ทาง"},
	"lumi":   {"name": "เพลงแสง",      "cost": 35, "cd": 14.0, "range": 8.0, "desc": "ฟื้น HP ทีมรอบตัว"},
	"null":   {"name": "ดูดเวท",       "cost": 30, "cd": 10.0, "range": 4.5, "desc": "ดูด HP ศัตรูรอบตัวมาเป็นของตัวเอง"},
	"kuroba": {"name": "สแกน K-7",     "cost": 25, "cd": 14.0, "range": 12.0, "desc": "เผยศัตรูทั้งหมดในระยะ 35 ม. + ทำให้ช้าลง"},
	"fumi":   {"name": "สมุดจดชื่อ",    "cost": 40, "cd": 16.0, "range": 7.0, "desc": "ชุบเพื่อนที่ล้มทันที หรือฟื้น HP มาก"},
}
const CARD_TYPES := {
	"power":  {"name": "การ์ดตรา: พลัง +1", "color": "f5c542", "weight": 5},
	"heal":   {"name": "การ์ดฟื้นฟู",       "color": "4cd28a", "weight": 3},
	"breath": {"name": "การ์ดลมหายใจ",      "color": "5ab8ef", "weight": 2},
	"armor":  {"name": "การ์ดเกราะ HP +20",  "color": "c8a0ff", "weight": 2},
}
## [wait seconds, shrink seconds, end radius, damage per second outside]
const ZONE_PHASES := [[40, 25, 62, 3], [30, 20, 40, 5], [25, 18, 24, 8], [20, 15, 11, 12], [15, 15, 0, 20]]

var font: Font
var fighters: Array = []       # all 24 Fighter nodes
var player: Fighter
var cam_target: Fighter
var cards: Array = []          # {node, type, pos}
var projectiles: Array = []
var cam: Camera3D
var hud: CanvasLayer
var minimap: Control
var time := 0.0
var ended := false
var autopilot := false         # tests: a bot drives the player too
var rng := RandomNumberGenerator.new()
var obstacles: Array = []      # Rect2 footprints of buildings, for spawning cards outside them

# zone
var zone_center := Vector2.ZERO
var zone_radius := 98.0
var zone_from_c := Vector2.ZERO
var zone_from_r := 98.0
var zone_to_c := Vector2.ZERO
var zone_to_r := 98.0
var zone_phase := -1
var zone_timer := 0.0
var zone_shrinking := false
var zone_dps := 2.0
var zone_mesh: MeshInstance3D

# HUD refs
var hud_team: VBoxContainer
var hud_hp: ProgressBar
var hud_br: ProgressBar
var hud_ult: ProgressBar
var hud_skill: Label
var hud_status: Label
var hud_msg: Label
var hud_feed: VBoxContainer
var hud_zone: Label
var msg_time := 0.0
var feed: Array = []
var team_out_order: Array = []  # teams in elimination order
var think_t := 0.0
var cam_yaw := 0.0
var cam_pitch := 0.62        # radians above horizontal
var cam_dist := 11.0         # metres (mouse wheel)
var regroup_t := 0.0         # T: teammates stick to the player
var map_open := false
var pause_layer: CanvasLayer


func _ready() -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Thonburi", "Sukhumvit Set", "Noto Sans Thai", "Leelawadee UI", "Tahoma"])
	font = f
	_setup_input()


func start(player_id: String, seed_value := -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	_build_world()
	_spawn_teams(player_id)
	_spawn_cards(140)
	_build_zone()
	_build_hud()
	cam_target = player
	_capture_mouse()
	_message("ม่านลืมกำลังจะเริ่มปิด — เก็บการ์ดตรา แล้วอยู่ให้รอดเป็นทีมสุดท้าย", 4.0)


# ================= world =================
func _setup_input() -> void:
	preload("res://scripts/controls.gd").apply("royale", self)


func _mat(c: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(size: Vector3, pos: Vector3, color: Color, solid := true) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color)
	mi.position = pos
	add_child(mi)
	if solid:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1 | 2
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new(); sh.size = size
		cs.shape = sh
		sb.add_child(cs)
		sb.position = pos
		add_child(sb)
		if pos.y > 0:
			obstacles.append(Rect2(pos.x - size.x / 2 - 1, pos.z - size.z / 2 - 1, size.x + 2, size.z + 2))


const CITY := "res://assets/city/"
const NATURE := "res://assets/nature/"
static var _aabb_cache := {}


func _tex_mat(path: String, uv_scale: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(path)
	m.uv1_scale = uv_scale
	m.roughness = 0.95
	return m


func _flat_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


func _model_aabb(path: String, node: Node3D) -> AABB:
	if _aabb_cache.has(path):
		return _aabb_cache[path]
	var acc := [null]
	_merge_aabb(node, Transform3D.IDENTITY, acc, true)
	var a: AABB = acc[0] if acc[0] != null else AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE)
	_aabb_cache[path] = a
	return a


func _merge_aabb(n: Node, xf: Transform3D, acc: Array, is_root: bool) -> void:
	var t := xf
	if n is Node3D and not is_root:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D:
		var a: AABB = t * (n as MeshInstance3D).get_aabb()
		acc[0] = a if acc[0] == null else acc[0].merge(a)
	for c in n.get_children():
		_merge_aabb(c, t, acc, false)


## Place a kit model. collide: "box" (full footprint, climbable), "trunk" (tree trunk), "none".
func _place(path: String, pos: Vector3, rot_y: float, scl: float, collide := "box") -> void:
	var ps = load(path)
	if ps == null:
		return
	var n: Node3D = ps.instantiate()
	add_child(n)
	var a := _model_aabb(path, n)
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * scl
	if collide == "none":
		return
	var sb := StaticBody3D.new()
	sb.collision_layer = 1 | 2
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	var basis := Basis(Vector3.UP, rot_y).scaled(Vector3.ONE * scl)
	var size: Vector3 = a.size * scl
	var centre: Vector3 = basis * a.get_center()
	if collide == "trunk":
		size = Vector3(0.6, a.size.y * scl * 0.6, 0.6)
		centre = Vector3(0, size.y / 2, 0)
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	sb.position = pos + centre
	sb.rotation.y = rot_y
	add_child(sb)
	if collide == "box":
		# footprint (axis-aligned bound of the rotated box) for minimap / spawning
		var half := Vector2(abs(cos(rot_y)) * size.x + abs(sin(rot_y)) * size.z, abs(sin(rot_y)) * size.x + abs(cos(rot_y)) * size.z) / 2.0
		var c2 := Vector2(sb.position.x, sb.position.z)
		obstacles.append(Rect2(c2 - half - Vector2.ONE, half * 2 + Vector2.ONE * 2))


# ---------- enterable buildings (modular kit pieces) ----------
## rooms: {rect: Rect2 (inner floor), door_out: Vector3, door_in: Vector3, upper: Array[Node3D], name}
var rooms: Array = []


func _piece(path: String, pos: Vector3, rot_y: float, parent: Node3D, scl := Vector3.ONE) -> Node3D:
	var ps = load(CITY + path)
	if ps == null:
		return null
	var n: Node3D = ps.instantiate()
	parent.add_child(n)
	n.position = pos
	n.rotation.y = rot_y
	n.scale = scl
	return n


func _wall_box(a: Vector3, b: Vector3, layer: int) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = layer
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = (b - a).abs()
	cs.shape = sh
	sb.add_child(cs)
	sb.position = (a + b) / 2.0
	add_child(sb)


## A walk-in building centred at `c`: w x d metres (multiples of 4), `floors` storeys,
## doorway in the middle of the +Z side. Only the ground floor is a room; upper
## storeys are facade (hidden while the camera target is inside so you can see in).
func _build_room(c: Vector3, w: int, d: int, floors: int, room_name: String, loot := 3) -> void:
	var root := Node3D.new()
	root.position = c
	add_child(root)
	var upper: Array = []
	var hw := w / 2.0
	var hd := d / 2.0
	var cells_w := w / 2
	var cells_d := d / 2
	var door_cell := cells_w / 2
	# outer walls: [side rotation, cell count, position of cell i]
	var sides := [
		[0.0, cells_w, func(i): return Vector3(-hw + 1 + i * 2, 0, hd)],          # front (+Z) with door
		[PI, cells_w, func(i): return Vector3(hw - 1 - i * 2, 0, -hd)],           # back
		[-PI / 2, cells_d, func(i): return Vector3(-hw, 0, -hd + 1 + i * 2)],     # left
		[PI / 2, cells_d, func(i): return Vector3(hw, 0, hd - 1 - i * 2)],        # right
	]
	for si in sides.size():
		var side: Array = sides[si]
		for f in floors:
			for i in side[1]:
				var pos: Vector3 = side[2].call(i) + Vector3(0, f * 3, 0)
				var piece := "Brick_Plain_3.gltf"
				if f == 0 and si == 0 and i == door_cell:
					piece = "DoorFrame_Wooden.gltf"
				elif f > 0 or i % 2 == 1:
					piece = "Brick_Window_Square_Single.gltf"
				var n := _piece(piece, pos, side[0], root)
				if f > 0 and n: upper.append(n)
				# plaster on the inside of the ground floor
				if f == 0 and not (si == 0 and i == door_cell):
					var inner := _piece("Brick_InteriorWall_4.gltf", pos + Vector3(0, 0, 0).rotated(Vector3.UP, side[0]) - (Vector3(0, 0, 0.22)).rotated(Vector3.UP, side[0]), side[0] + PI, root, Vector3(1, 0.75, 1))
		# corner columns
	for corner in [Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd), Vector3(-hw, 0, hd), Vector3(hw, 0, hd)]:
		for f in floors:
			var cn := _piece("Brick_CornerColumn_Center.gltf", corner + Vector3(0.4 * sign(corner.x), f * 3, 0.4 * sign(corner.z)), 0.0, root)
			if f > 0 and cn: upper.append(cn)
	# floor, ceiling, roof
	for x in range(0, w, 4):
		for z in range(0, d, 4):
			_piece("Floor_4x4.gltf", Vector3(-hw + 2 + x, 0.06, -hd + 2 + z), 0.0, root)
			var rf := _piece("Roof_4x4.gltf", Vector3(-hw + 2 + x, floors * 3 + 0.2, -hd + 2 + z), 0.0, root)
			if rf: upper.append(rf)
	var ceil := MeshInstance3D.new()
	var cm := BoxMesh.new(); cm.size = Vector3(w, 0.15, d)
	ceil.mesh = cm
	ceil.material_override = _mat(Color("efe6d8"))
	ceil.position = Vector3(0, 3.05, 0)
	root.add_child(ceil)
	upper.append(ceil)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color("ffe0b0"); lamp.light_energy = 1.6; lamp.omni_range = max(w, d)
	lamp.position = Vector3(0, 2.6, 0)
	root.add_child(lamp)
	# collision: ground-floor walls (layer 1|2, block movement + camera + sight),
	# upper storeys / roof (layer 1 only, so the camera can look in over them)
	var gx := c.x
	var gz := c.z
	var door_x := -hw + 1 + door_cell * 2
	var door_half := 0.8
	var t := 0.25
	_wall_box(Vector3(gx - hw, 0, gz + hd - t), Vector3(gx + door_x - door_half, 3, gz + hd), 1 | 2)
	_wall_box(Vector3(gx + door_x + door_half, 0, gz + hd - t), Vector3(gx + hw, 3, gz + hd), 1 | 2)
	_wall_box(Vector3(gx + door_x - door_half, 2.4, gz + hd - t), Vector3(gx + door_x + door_half, 3, gz + hd), 1 | 2)
	_wall_box(Vector3(gx - hw, 0, gz - hd), Vector3(gx + hw, 3, gz - hd + t), 1 | 2)
	_wall_box(Vector3(gx - hw, 0, gz - hd), Vector3(gx - hw + t, 3, gz + hd), 1 | 2)
	_wall_box(Vector3(gx + hw - t, 0, gz - hd), Vector3(gx + hw, 3, gz + hd), 1 | 2)
	_wall_box(Vector3(gx - hw, 3, gz - hd), Vector3(gx + hw, floors * 3 + 0.3, gz + hd), 1)   # upper block + roof
	rooms.append({
		"rect": Rect2(gx - hw + 0.6, gz - hd + 0.6, w - 1.2, d - 1.2),
		"outer": Rect2(gx - hw - 1, gz - hd - 1, w + 2, d + 2),
		"door_out": Vector3(gx + door_x, 0, gz + hd + 1.6),
		"door_in": Vector3(gx + door_x, 0, gz + hd - 1.4),
		"upper": upper, "name": room_name, "hidden": false,
	})
	# loot inside
	for k in loot:
		_drop_card("power" if k < 2 else ["heal", "armor", "breath"][rng.randi() % 3], Vector3(gx + rng.randf_range(-hw + 2, hw - 2), 0, gz + rng.randf_range(-hd + 2, hd - 2.5)))


func room_at(p: Vector3) -> int:
	for i in rooms.size():
		if (rooms[i]["rect"] as Rect2).grow(0.4).has_point(Vector2(p.x, p.z)):
			return i
	return -1


## Walk target that goes through doorways: outside -> door -> inside, inside -> door -> outside.
func _route(from: Vector3, to: Vector3) -> Vector3:
	var rf := room_at(from)
	var rt := room_at(to)
	if rf == rt:
		return to
	# standing in a doorway: keep going through it
	for i in rooms.size():
		var r: Dictionary = rooms[i]
		var din: Vector3 = r["door_in"]
		var dout: Vector3 = r["door_out"]
		if abs(from.x - din.x) < 1.3 and from.z > din.z - 0.3 and from.z < dout.z + 0.3:
			return din if rt == i else dout
	if rf >= 0:
		return rooms[rf]["door_in"]
	return rooms[rt]["door_out"]


## Hide the roof / upper storeys of the room the camera target stands in.
func _update_rooms() -> void:
	var inside := room_at(cam_target.global_position) if cam_target else -1
	for i in rooms.size():
		var hide := i == inside
		if rooms[i]["hidden"] != hide:
			rooms[i]["hidden"] = hide
			for n in rooms[i]["upper"]:
				(n as Node3D).visible = not hide


func _sign(text: String, pos: Vector3, col := Color("f5c542")) -> void:
	var l := Label3D.new()
	l.font = font
	l.text = text
	l.font_size = 120
	l.pixel_size = 0.011
	l.outline_size = 24
	l.modulate = col
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)
	l.position = pos


func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var skym := ProceduralSkyMaterial.new()
	skym.sky_top_color = Color("9fb8ff")
	skym.sky_horizon_color = Color("ffe0f4")
	skym.ground_horizon_color = Color("ffe0f4")
	skym.ground_bottom_color = Color("c8d8ff")
	sky.sky_material = skym
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.92, 0.88, 1.0)
	e.ambient_light_energy = 0.32
	e.fog_enabled = false
	e.fog_light_color = Color("b8c8e0")
	e.fog_density = 0.004
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60
	sun.light_energy = 0.75
	sun.light_color = Color("fff4fa")
	add_child(sun)
	# soft distance haze toward the pink horizon (the "curtain of forgetting" stays its own effect)
	preload("res://scripts/look.gd").apply(e, sun, self, Color("e6dcf2"), 0.0035)

	# ground + roads
	_box(Vector3(MAP_HALF * 2 + 20, 1, MAP_HALF * 2 + 20), Vector3(0, -0.5, 0), Color("8fd87a"))
	var asphalt := _tex_mat(CITY + "T_Concrete_Asphalt_BaseColor.png", Vector3(MAP_HALF / 3.0, 1, 1))
	var asphalt_v := _tex_mat(CITY + "T_Concrete_Asphalt_BaseColor.png", Vector3(1, MAP_HALF / 3.0, 1))
	var concrete := _tex_mat(CITY + "T_Concrete_BaseColor.png", Vector3(MAP_HALF / 2.0, 1, 1))
	var concrete_v := _tex_mat(CITY + "T_Concrete_BaseColor.png", Vector3(1, MAP_HALF / 2.0, 1))
	for i in range(-3, 4):
		_flat_box(Vector3(MAP_HALF * 2, 0.04, 6), Vector3(0, 0.03, i * 26), asphalt)
		_flat_box(Vector3(6, 0.05, MAP_HALF * 2), Vector3(i * 26, 0.035, 0), asphalt_v)
		for sd in [-4.0, 4.0]:   # sidewalks
			_flat_box(Vector3(MAP_HALF * 2, 0.12, 2), Vector3(0, 0.06, i * 26 + sd), concrete)
			_flat_box(Vector3(2, 0.13, MAP_HALF * 2), Vector3(i * 26 + sd, 0.065, 0), concrete_v)
	# outer wall
	var w := Color("b8a8e0")
	_box(Vector3(MAP_HALF * 2, 6, 1), Vector3(0, 3, -MAP_HALF), w)
	_box(Vector3(MAP_HALF * 2, 6, 1), Vector3(0, 3, MAP_HALF), w)
	_box(Vector3(1, 6, MAP_HALF * 2), Vector3(-MAP_HALF, 3, 0), w)
	_box(Vector3(1, 6, MAP_HALF * 2), Vector3(MAP_HALF, 3, 0), w)
	# invisible barrier above the wall (climbers / flyers stay in the map)
	for b in [[Vector3(MAP_HALF * 2, 60, 1), Vector3(0, 36, -MAP_HALF)], [Vector3(MAP_HALF * 2, 60, 1), Vector3(0, 36, MAP_HALF)],
			[Vector3(1, 60, MAP_HALF * 2), Vector3(-MAP_HALF, 36, 0)], [Vector3(1, 60, MAP_HALF * 2), Vector3(MAP_HALF, 36, 0)]]:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new(); sh.size = b[0]
		cs.shape = sh
		sb.add_child(cs)
		sb.position = b[1]
		add_child(sb)

	# landmarks from the story — built from Quaternius Downtown City MegaKit (CC0)
	# school (center-north): two large buildings + schoolyard
	_build_room(Vector3(0, 0, -36), 24, 12, 3, "โรงเรียน", 5)
	_box(Vector3(30, 0.06, 18), Vector3(0, 0.03, -18), Color("c8a878"), false)  # schoolyard
	_sign("โรงเรียน", Vector3(0, 27, -34))
	# old wooden building (P1 finale) keeps its own look
	_box(Vector3(14, 6, 10), Vector3(36, 3, 30), Color("6a4a2a"))
	_box(Vector3(15, 0.6, 11), Vector3(36, 6.3, 30), Color("4a3020"))
	_sign("อาคารเรียนไม้เก่า", Vector3(36, 10, 30), Color("ffb070"))
	# Kanel mansion (Oli's home) + clover garden
	_build_room(Vector3(-44, 0, 40), 16, 12, 2, "คฤหาสน์คาเนล", 4)
	for k in 10:
		_place(NATURE + "Clover_1.gltf", Vector3(-44 + rng.randf_range(-8, 8), 0, 50 + rng.randf_range(-2, 2)), rng.randf() * TAU, 1.0, "none")
	_sign("คฤหาสน์คาเนล", Vector3(-44, 26, 40))
	# concert stage (Lumi)
	_box(Vector3(14, 1.2, 8), Vector3(44, 0.6, -40), Color("c47aff"))
	_box(Vector3(14, 6, 0.5), Vector3(44, 3.6, -44), Color("f0a0e0"))
	_sign("เวทีคอนเสิร์ตลูมิ", Vector3(44, 9, -40), Color("e0a0ff"))
	# scan center (KANEL SCAN)
	_build_room(Vector3(-40, 0, -42), 12, 8, 2, "ศูนย์สแกนตรา", 3)
	_sign("ศูนย์สแกนตรา", Vector3(-40, 19, -40), Color("a0d8ff"))

	# city blocks: one kit building per block, nature filling the rest
	var buildings := ["Building_Small_1.gltf", "Building_Medium_2_001.gltf", "Building_Large_2.gltf"]
	var trees := ["CommonTree_1.gltf", "CommonTree_2.gltf", "CommonTree_3.gltf", "CommonTree_4.gltf", "CommonTree_5.gltf", "Pine_1.gltf", "Pine_2.gltf", "Pine_3.gltf"]
	var small := ["Bush_Common.gltf", "Bush_Common_Flowers.gltf", "Flower_3_Group.gltf", "Flower_4_Group.gltf", "Grass_Wispy_Tall.gltf", "Plant_1_Big.gltf", "Grass_Common_Short.gltf", "Mushroom_Common.gltf"]
	for gx in range(-3, 3):
		for gz in range(-3, 3):
			var cx := gx * 26 + 13.0
			var cz := gz * 26 + 13.0
			if _near_landmark(cx, cz):
				# small park around landmarks
				for k in 3:
					_place(NATURE + small[rng.randi() % small.size()], Vector3(cx + rng.randf_range(-9, 9), 0, cz + rng.randf_range(-9, 9)), rng.randf() * TAU, 1.0, "none")
				continue
			var park := rng.randf() < 0.22
			if park:
				# park block: trees, rocks, flowers
				for k in 5:
					_place(NATURE + trees[rng.randi() % trees.size()], Vector3(cx + rng.randf_range(-8, 8), 0, cz + rng.randf_range(-8, 8)), rng.randf() * TAU, rng.randf_range(0.9, 1.2), "trunk")
				for k in 2:
					_place(NATURE + "Rock_Medium_%d.gltf" % rng.randi_range(1, 3), Vector3(cx + rng.randf_range(-8, 8), 0, cz + rng.randf_range(-8, 8)), rng.randf() * TAU, 1.0, "box")
				for k in 6:
					_place(NATURE + small[rng.randi() % small.size()], Vector3(cx + rng.randf_range(-9, 9), 0, cz + rng.randf_range(-9, 9)), rng.randf() * TAU, 1.0, "none")
			elif rng.randf() < 0.3:
				_build_room(Vector3(cx, 0, cz), 12, 8, 2, "ร้านค้า", 2)
			else:
				var bname: String = buildings[rng.randi() % buildings.size()]
				var rot: float = [0.0, PI * 0.5, PI, PI * 1.5][rng.randi() % 4]
				_place(CITY + bname, Vector3(cx, 0, cz), rot, 0.78 if bname.begins_with("Building_Large") else 0.85)
				for k in 2:
					var side := Vector3(rng.randf_range(-10, 10), 0, [-10.5, 10.5][rng.randi() % 2])
					_place(NATURE + trees[rng.randi() % trees.size()], Vector3(cx, 0, cz) + side, rng.randf() * TAU, 0.8, "trunk")
			# street props on the block corner
			_place(CITY + "Prop_Bollard.gltf", Vector3(cx - 10.5, 0, cz - 10.5), 0.0, 1.2, "none")
			_place(CITY + "Prop_Planter_Single.gltf", Vector3(cx + 10.5, 0, cz - 10.5), 0.0, 1.0, "box")

	cam = Camera3D.new()
	cam.fov = 55
	cam.far = 300
	cam.current = true
	add_child(cam)


func _near_landmark(x: float, z: float) -> bool:
	for p in [Vector2(0, -30), Vector2(36, 30), Vector2(-44, 38), Vector2(44, -40), Vector2(-40, -40), Vector2(0, 0)]:
		if Vector2(x, z).distance_to(p) < 18:
			return true
	return false


func _free_spot(center: Vector2, spread: float) -> Vector3:
	for tries in 30:
		var p := center + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
		p = p.clamp(Vector2(-MAP_HALF + 3, -MAP_HALF + 3), Vector2(MAP_HALF - 3, MAP_HALF - 3))
		var blocked := false
		for r in obstacles:
			if r.has_point(p):
				blocked = true
				break
		if not blocked:
			return Vector3(p.x, 0, p.y)
	return Vector3(center.x, 0, center.y)


# ================= fighters =================
func _make_data(id: String, team: int, is_player: bool) -> Dictionary:
	var s: Dictionary = STATS[id]
	return {
		"id": id, "name": s["name"], "el": s["el"], "team": team, "is_player": is_player,
		"hp": s["hp"] * HP_SCALE, "maxhp": s["hp"] * HP_SCALE, "atk": s["atk"], "speed": s["speed"],
		"breath": 100.0, "seal": 0, "lv": 1, "cd": 0.0, "ult": 0.0, "atk_cd": 0.0, "combo": 0, "combo_t": 0.0,
		"downed": false, "bleed": 0.0, "revive": 0.0, "out": false,
		"buff": 0.0, "crit": 0.0, "armor": 0.0, "slow": 0.0, "revealed": 0.0,
		"kills": 0, "damage": 0, "windup": 0.0,
		# bot brain
		"goal": Vector3.ZERO, "target": null, "react": 0.0, "wander_t": 0.0,
	}


func _spawn_teams(player_id: String) -> void:
	for t in TEAMS:
		var ang := TAU * t / TEAMS + rng.randf_range(-0.1, 0.1)
		var base := Vector2(cos(ang), sin(ang)) * rng.randf_range(68, 78)
		var pool := ROSTER.duplicate()
		pool.shuffle()
		var ids: Array = []
		if t == 0:
			ids.append(player_id)
			pool.erase(player_id)
		while ids.size() < TEAM_SIZE:
			ids.append(pool.pop_back())
		for k in TEAM_SIZE:
			var d := _make_data(ids[k], t, t == 0 and k == 0)
			var f := Fighter.new()
			add_child(f)
			f.setup(d, t == 0, font)
			f.speed = d["speed"]
			f.tag.modulate = Color(TEAM_COLORS[t])
			f.on_landing = _on_landing
			var tm := TorusMesh.new()
			tm.inner_radius = 0.55; tm.outer_radius = 0.72
			f.shadow.mesh = tm
			var rm := StandardMaterial3D.new()
			rm.albedo_color = Color(Color(TEAM_COLORS[t]), 0.85)
			rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			f.shadow.material_override = rm
			f.shadow.position.y = 0.05
			if t == 0 and k == 0:
				f.tag.text = "▼ " + d["name"]
			f.global_position = _free_spot(base, 4) + Vector3(0, 22 + k * 2, 0)  # drop in from the sky
			fighters.append(f)
			if d["is_player"]:
				player = f


func team_color(t: int) -> Color:
	return Color(TEAM_COLORS[t])


func card_color(type: String) -> Color:
	return Color(CARD_TYPES[type]["color"])


func zone_has_next() -> bool:
	return zone_phase < ZONE_PHASES.size()


## Mio's ground slam: a hard landing knocks back and hurts nearby enemies.
func _on_landing(f: Fighter, impact: float) -> void:
	if not standing(f):
		return
	var r := 3.5
	if _visible_to_player(f):
		_ring(f.global_position, r, Color(0.8, 0.6, 0.3, 0.9))
		f.dust("ring", 2.2)
	for e in enemies_of(f):
		if _flat(e.global_position, f.global_position) < r and abs(e.global_position.y - f.global_position.y) < 2.5:
			hit(f, e, 1.2 + impact * 0.05, 12.0, f.global_position)


func members(team: int) -> Array:
	return fighters.filter(func(f): return f.data["team"] == team)


func standing(f: Fighter) -> bool:
	return not f.data["out"] and not f.data["downed"]


func teams_left() -> Array:
	var t := []
	for f in fighters:
		if not f.data["out"] and not t.has(f.data["team"]):
			t.append(f.data["team"])
	return t


# ================= cards =================
func _spawn_cards(n: int) -> void:
	var total := 0
	for k in CARD_TYPES:
		total += CARD_TYPES[k]["weight"]
	for i in n:
		var r := rng.randi_range(1, total)
		var type := "power"
		for k in CARD_TYPES:
			r -= CARD_TYPES[k]["weight"]
			if r <= 0:
				type = k
				break
		_drop_card(type, _free_spot(Vector2.ZERO, MAP_HALF - 6))


func _drop_card(type: String, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(0.55, 0.8, 0.06)
	mi.mesh = bm
	var c := Color(CARD_TYPES[type]["color"])
	var m := _mat(c, true)
	m.emission_enabled = true
	m.emission = c
	mi.material_override = m
	add_child(mi)
	mi.position = pos + Vector3(0, 0.9, 0)
	cards.append({"node": mi, "type": type, "pos": Vector3(pos.x, 0, pos.z)})


func _pickup_cards() -> void:
	for c in cards.duplicate():
		var node: MeshInstance3D = c["node"]
		node.rotation.y += 0.05
		for f in fighters:
			if standing(f) and _flat(f.global_position, c["pos"]) < 1.4:
				_apply_card(f, c["type"])
				node.queue_free()
				cards.erase(c)
				break


func _apply_card(f: Fighter, type: String) -> void:
	var d: Dictionary = f.data
	match type:
		"power":
			if d["lv"] < 5:
				d["lv"] += 1
			else:
				d["ult"] = min(100.0, d["ult"] + 35)
		"heal":
			d["hp"] = min(d["maxhp"], d["hp"] + 60)
		"breath":
			d["breath"] = 100.0
		"armor":
			d["maxhp"] += 20
			d["hp"] += 20
	if f == player and hud:
		hud.notice("เก็บ %s%s" % [CARD_TYPES[type]["name"], ("  → Lv.%d" % d["lv"]) if type == "power" else ""], "card")


# ================= zone (Forgetting Fog) =================
func _build_zone() -> void:
	zone_mesh = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0; cm.bottom_radius = 1.0; cm.height = 40
	cm.cap_top = false; cm.cap_bottom = false
	cm.radial_segments = 96
	zone_mesh.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.6, 0.3, 0.9, 0.28)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	zone_mesh.material_override = m
	zone_mesh.position.y = 20
	add_child(zone_mesh)
	zone_phase = -1
	_next_zone_phase()


func _next_zone_phase() -> void:
	zone_phase += 1
	if zone_phase >= ZONE_PHASES.size():
		return
	var ph: Array = ZONE_PHASES[zone_phase]
	zone_timer = ph[0]
	zone_shrinking = false
	zone_from_c = zone_center
	zone_from_r = zone_radius
	zone_to_r = ph[2]
	var slack := maxf(0.0, zone_radius - zone_to_r)
	var off := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).limit_length(1.0) * slack * 0.7
	zone_to_c = (zone_center + off).clamp(Vector2(-60, -60), Vector2(60, 60))


func _update_zone(delta: float) -> void:
	if zone_phase < ZONE_PHASES.size():
		var ph: Array = ZONE_PHASES[zone_phase]
		zone_timer -= delta
		if not zone_shrinking and zone_timer <= 0:
			zone_shrinking = true
			zone_timer = ph[1]
			zone_dps = ph[3]
			if player and not player.data["out"]:
				_message("ม่านลืมกำลังปิดเข้ามา!", 2.5)
		elif zone_shrinking:
			var t: float = 1.0 - clamp(zone_timer / ph[1], 0.0, 1.0)
			zone_center = zone_from_c.lerp(zone_to_c, t)
			zone_radius = lerp(zone_from_r, zone_to_r, t)
			if zone_timer <= 0:
				_next_zone_phase()
	zone_mesh.position.x = zone_center.x
	zone_mesh.position.z = zone_center.y
	var r: float = max(zone_radius, 0.3)
	zone_mesh.scale = Vector3(r, 1, r)
	# damage outside
	for f in fighters:
		if f.data["out"] or f.data["downed"]:
			continue
		if Vector2(f.global_position.x, f.global_position.z).distance_to(zone_center) > zone_radius:
			_raw_damage(f, zone_dps * delta, null)


func in_zone(p: Vector3, margin := 0.0) -> bool:
	return Vector2(p.x, p.z).distance_to(zone_center) < zone_radius - margin


# ================= combat =================
func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _clear_line(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a + Vector3(0, 0.9, 0), b + Vector3(0, 0.9, 0), 2)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _steer(from: Vector3, to: Vector3) -> Vector3:
	if not rooms.is_empty():
		to = _route(from, to)
	var d := to - from
	d.y = 0
	if d.length() < 0.01:
		return Vector3.ZERO
	d = d.normalized()
	if _clear_line(from, from + d * 2.0):
		return d
	for ang in [0.7, -0.7, 1.4, -1.4, 2.2, -2.2]:
		var alt := d.rotated(Vector3.UP, ang)
		if _clear_line(from, from + alt * 2.0):
			return alt
	return d


func lv_mult(d: Dictionary) -> float:
	return 1.0 + 0.2 * (d["lv"] - 1)


func enemies_of(f: Fighter) -> Array:
	return fighters.filter(func(o): return o.data["team"] != f.data["team"] and not o.data["out"])


func allies_of(f: Fighter) -> Array:
	return fighters.filter(func(o): return o.data["team"] == f.data["team"] and not o.data["out"] and o != f)


## Generic hit from attacker a to target t (base = multiplier of a's attack).
func hit(a: Fighter, t: Fighter, base: float, kb: float, src: Vector3) -> void:
	if t.data["out"] or t.data["team"] == a.data["team"]:
		return
	if t.invuln > 0 and not t.data["downed"]:
		return
	var ad: Dictionary = a.data
	var crit: bool = ad["crit"] > 0 or rng.randf() < 0.08
	var dmg: float = ad["atk"] * base * Game.mult(ad["el"], t.data["el"])
	if ad["buff"] > 0: dmg *= 1.6
	if crit: dmg *= 2.0
	if t.data["armor"] > 0: dmg *= 0.35
	dmg *= rng.randf_range(0.9, 1.1) * DAMAGE_SCALE
	if t.data["downed"]:
		t.data["bleed"] -= 4.0   # finishing a downed enemy
		t.flash = 0.15
		return
	var away := t.global_position - src
	away.y = 0
	if t.data["armor"] <= 0:
		t.knock = away.normalized() * kb
		t.lock = 0.18
		t.act("hit", 0.3, 1.6)
		if crit and _visible_to_player(t):
			Vfx.spawn(self, "claw", t.global_position + Vector3(0, 1.1, 0), -away, Vfx.element_color(ad["el"]), 0.3, 0.7)
	t.flash = 0.15
	ad["damage"] += int(dmg)
	ad["ult"] = min(100.0, ad["ult"] + dmg * 0.45)
	if a == player or t == player or t == cam_target:
		_popup(t.global_position, ("%d!" if crit else "%d") % int(dmg), Color("ffe14a") if crit else (Color("ff6a6a") if t.data["team"] == 0 else Color.WHITE), 64 if crit else 48)
	_raw_damage(t, dmg, a)


func _raw_damage(t: Fighter, dmg: float, by) -> void:
	var d: Dictionary = t.data
	if d["out"] or d["downed"]:
		return
	d["hp"] = max(0.0, d["hp"] - dmg)
	if d["hp"] <= 0:
		_down(t, by)


func _down(t: Fighter, by) -> void:
	var d: Dictionary = t.data
	d["downed"] = true
	d["bleed"] = 25.0
	d["revive"] = 0.0
	d["windup"] = 0.0
	t.move_dir = Vector3.ZERO
	var who: String = by.data["name"] if by else "ม่านลืม"
	_feed("%s ล้ม %s" % [who, d["name"]], by.data["team"] if by else -1)
	if by:
		by.data["kills"] += 1
	_check_team(d["team"])


func _eliminate(t: Fighter) -> void:
	var d: Dictionary = t.data
	if d["out"]:
		return
	d["out"] = true
	d["downed"] = false
	t.collision_layer = 0
	t.collision_mask = 0
	t.move_dir = Vector3.ZERO
	t.tag.visible = false
	t.shadow.visible = false
	t.die(func():
		t.visible = false
		t.process_mode = Node.PROCESS_MODE_DISABLED)
	# drop loot: their power level becomes cards
	for k in clamp(d["lv"] - 1, 0, 3):
		_drop_card("power", t.global_position + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5)))
	_drop_card("heal", t.global_position)


func _check_team(team: int) -> void:
	var ms := members(team)
	if ms.any(func(f): return standing(f)):
		return
	# whole team down -> out
	for f in ms:
		_eliminate(f)
	if not team_out_order.has(team):
		team_out_order.append(team)
		_feed("%s ตกรอบ (เหลือ %d ทีม)" % [TEAM_NAMES[team], teams_left().size()], team)


func _revive(t: Fighter) -> void:
	var d: Dictionary = t.data
	d["downed"] = false
	d["hp"] = d["maxhp"] * 0.35
	d["bleed"] = 0.0
	d["revive"] = 0.0
	t.invuln = 1.5
	if d["team"] == 0:
		_message("%s ลุกขึ้นแล้ว!" % d["name"], 1.5)


# ---- actions (shared by player and bots) ----
func do_attack(f: Fighter) -> void:
	var d: Dictionary = f.data
	if d["atk_cd"] > 0 or not standing(f) or f.dash > 0:
		return
	d["combo"] = d["combo"] % 3 + 1
	d["combo_t"] = 0.7
	d["atk_cd"] = 0.32 if d["combo"] < 3 else 0.55
	f.lock = 0.14
	var near = _nearest_enemy(f, 4.0, true)
	if near:
		var to: Vector3 = near.global_position - f.global_position
		to.y = 0
		if to.length() > 0.1:
			f.facing = to.normalized()
	f.knock = f.facing * 3.0
	for e in enemies_of(f):
		var to2: Vector3 = e.global_position - f.global_position
		to2.y = 0
		if to2.length() <= 2.3 and f.facing.dot(to2.normalized()) > 0.2 and abs(e.global_position.y - f.global_position.y) < 2.2 and _clear_line(f.global_position, e.global_position):
			hit(f, e, 1.0 if d["combo"] < 3 else 1.6, 4.0 if d["combo"] < 3 else 11.0, f.global_position)
	f.act("attack" if d["combo"] < 3 else "attack2", 0.42 if d["combo"] < 3 else 0.6, 1.8)
	if _visible_to_player(f):
		var ec := Vfx.element_color(d["el"])
		Vfx.spawn(self, "swing" if d["combo"] < 3 else "slash", f.global_position + Vector3(0, 1.1, 0) + f.facing * 0.6, f.facing, ec, 0.35, 0.8 if d["combo"] < 3 else 1.0)


func do_dodge(f: Fighter) -> void:
	if f.data.get("dodge_cd", 0.0) > 0 or not standing(f):
		return
	f.data["dodge_cd"] = 0.8
	f.start_dash(f.move_dir)


func do_power(f: Fighter) -> void:
	var d: Dictionary = f.data
	var id: String = d["id"]
	if d["cd"] > 0 or not standing(f):
		return
	var pw: Dictionary = POWERS[id]
	d["cd"] = pw["cd"] * (1.0 - 0.08 * (d["lv"] - 1))
	# the price of power: overusing breath cracks the seal (game-design.md)
	d["breath"] -= pw["cost"]
	if d["breath"] < 0:
		d["breath"] = 0.0
		d["seal"] = min(1, d["seal"] + 1)
		d["hp"] = max(1.0, d["hp"] - d["maxhp"] * 0.15)
		if f == player:
			_message("ตราร้าว — ฝืนใช้เวทตอนลมหายใจหมด (HP -15%)", 2.0)
	var L := lv_mult(d)
	var vis := _visible_to_player(f)
	f.act("attack2" if ["haru", "setsu", "leon"].has(id) else ("call" if ["ren", "lumi", "fumi", "kuroba"].has(id) else "power"), 0.7, 1.5)
	if vis:
		Vfx.spawn(self, "charge", f.global_position + Vector3(0, 0.1, 0), Vector3.ZERO, Vfx.element_color(d["el"]), 0.6, 0.8)
	match id:
		"oli":
			d["crit"] = 5.0
			f.invuln = 0.8
			if vis: _ring(f.global_position, 2.5, Color(0.5, 1, 0.6, 0.9))
		"haru":
			_shoot(f, Color(0.4, 0.7, 1), 1.6 * L, 13.0, true, 1.2, "reveal")
		"ren":
			for a in [f] + allies_of(f):
				if _flat(a.global_position, f.global_position) < 8:
					a.data["buff"] = 4.0 + d["lv"] * 0.5
			if vis: _ring(f.global_position, 8.0, Color(0.6, 0.8, 1, 0.8))
		"mio":
			d["armor"] = 3.0
			var sh := Vfx.spawn(f, "shield", f.global_position + Vector3(0, 1.0, 0), Vector3.ZERO, Color("d0a060"), 3.0, 1.1)
			if vis: _ring(f.global_position, 3.5, Color(0.8, 0.6, 0.3, 0.9))
			for e in enemies_of(f):
				if _flat(e.global_position, f.global_position) < 3.5:
					hit(f, e, 1.8 * L, 12.0, f.global_position)
		"setsu":
			_shoot(f, Color(0.7, 1, 0.8), 2.6 * L, 28.0, true, 0.5, "")
		"leon":
			for ang in [-0.3, 0.0, 0.3]:
				_shoot(f, Color("ff7a2a"), 1.5 * L, 15.0, false, 0.7, "", ang)
		"lumi":
			for a in [f] + allies_of(f):
				if _flat(a.global_position, f.global_position) < 8 and not a.data["downed"]:
					a.data["hp"] = min(a.data["maxhp"], a.data["hp"] + 35 + 10 * d["lv"])
			if vis: _ring(f.global_position, 8.0, Color(1, 0.9, 0.4, 0.9))
		"null":
			var gained := 0.0
			for e in enemies_of(f):
				if _flat(e.global_position, f.global_position) < 4.5 and not e.data["downed"]:
					var before: float = e.data["hp"]
					hit(f, e, 1.3 * L, 3.0, f.global_position)
					gained += max(0.0, before - e.data["hp"])
			d["hp"] = min(d["maxhp"], d["hp"] + gained * 0.7)
			if vis: Vfx.spawn(self, "dark_area", f.global_position, Vector3.ZERO, Color(-1, 0, 0), 1.2, 1.2)
			if vis: _ring(f.global_position, 4.5, Color(0.9, 0.9, 1, 0.9))
		"kuroba":
			for e in enemies_of(f):
				if _flat(e.global_position, f.global_position) < 35:
					e.data["revealed"] = 8.0
					if _flat(e.global_position, f.global_position) < 8:
						e.data["slow"] = 3.0
			if vis: Vfx.spawn(self, "dark_ball", f.global_position + Vector3(0, 2.2, 0), Vector3.ZERO, Color("8a8aff"), 1.0, 0.8)
			if vis: _ring(f.global_position, 8.0, Color(0.6, 0.6, 1, 0.8))
		"fumi":
			var done := false
			for a in allies_of(f):
				if a.data["downed"] and _flat(a.global_position, f.global_position) < 7:
					_revive(a)
					done = true
					break
			if not done:
				for a in [f] + allies_of(f):
					if _flat(a.global_position, f.global_position) < 7 and not a.data["downed"]:
						a.data["hp"] = min(a.data["maxhp"], a.data["hp"] + 50 + 10 * d["lv"])
			if vis: _ring(f.global_position, 7.0, Color(1, 1, 1, 0.9))
	if f == player:
		_message(pw["name"], 0.9)


func do_ultimate(f: Fighter) -> void:
	var d: Dictionary = f.data
	if d["ult"] < 100 or not standing(f):
		return
	d["ult"] = 0.0
	f.invuln = 1.0
	f.act("power", 1.0, 1.2)
	Vfx.spawn(self, "charge", f.global_position, Vector3.ZERO, Vfx.element_color(d["el"]), 1.0, 1.6)
	var col: Color = {"ไฟ": Color("ff6a2a"), "น้ำ": Color("4aa0ff"), "ลม": Color("8affc0"), "ดิน": Color("c09050")}.get(d["el"], Color("f5c542"))
	_ring(f.global_position, 7.0, col)
	_ring(f.global_position, 4.0, Color(1, 1, 1, 0.9))
	for e in enemies_of(f):
		if _flat(e.global_position, f.global_position) < 7.0:
			hit(f, e, 4.0 * lv_mult(d), 16.0, f.global_position)
	if _visible_to_player(f):
		_message("ท่าไม้ตาย — %s!" % d["name"], 1.5)


func _shoot(f: Fighter, col: Color, mult: float, spd: float, pierce: bool, size: float, effect: String, ang := 0.0) -> void:
	var near = _nearest_enemy(f, 25.0, true)
	var dir: Vector3 = f.facing
	if near:
		dir = near.global_position - f.global_position
		dir.y = 0
		dir = dir.normalized()
		f.facing = dir
	dir = dir.rotated(Vector3.UP, ang)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = size * 0.5; sm.height = size
	mi.mesh = sm
	var m := _mat(col, true)
	mi.material_override = m
	add_child(mi)
	mi.global_position = f.global_position + Vector3(0, 1.1, 0) + dir * 0.8
	projectiles.append({"node": mi, "vel": dir * spd, "mult": mult, "owner": f, "life": 1.4, "pierce": pierce, "hit": [], "r": size * 0.6 + 0.45, "effect": effect})


func _projectiles(delta: float) -> void:
	for pr in projectiles.duplicate():
		var n: MeshInstance3D = pr["node"]
		var step: Vector3 = pr["vel"] * delta
		var gone: bool = pr["life"] <= 0 or not _clear_line(n.global_position - Vector3(0, 0.9, 0), n.global_position - Vector3(0, 0.9, 0) + step)
		n.global_position += step
		pr["life"] -= delta
		var shooter: Fighter = pr["owner"]
		for e in enemies_of(shooter):
			if not pr["hit"].has(e) and _flat(e.global_position, n.global_position) < pr["r"] and abs(e.global_position.y + 1 - n.global_position.y) < 2:
				pr["hit"].append(e)
				hit(shooter, e, pr["mult"], 7.0, n.global_position - pr["vel"].normalized())
				if pr["effect"] == "reveal":
					e.data["revealed"] = 6.0
				if not pr["pierce"]:
					gone = true
					break
		if gone:
			n.queue_free()
			projectiles.erase(pr)


func _nearest_enemy(f: Fighter, max_d: float, prefer_standing: bool):
	var best = null
	var bd := max_d
	for e in enemies_of(f):
		var dd := _flat(e.global_position, f.global_position)
		if prefer_standing and e.data["downed"]:
			dd += 6.0
		if dd < bd:
			bd = dd
			best = e
	return best


# ================= main loop =================
func _physics_process(delta: float) -> void:
	if ended or fighters.is_empty():
		return
	time += delta
	regroup_t = max(0.0, regroup_t - delta)
	think_t -= delta
	var think := think_t <= 0
	if think:
		think_t = 0.2
	for f in fighters:
		var d: Dictionary = f.data
		if d["out"]:
			continue
		for k in ["cd", "atk_cd", "buff", "crit", "armor", "slow", "revealed", "combo_t", "dodge_cd"]:
			d[k] = max(0.0, d.get(k, 0.0) - delta)
		if d["combo_t"] <= 0:
			d["combo"] = 0
		d["breath"] = min(100.0, d["breath"] + delta * 7.0)
		f.speed = d["speed"] * (0.5 if d["slow"] > 0 else 1.0) * (0.3 if d["downed"] else 1.0) * (1.45 if d.get("sprint", false) else 1.0)
		if d.get("sprint", false):
			d["breath"] = max(0.0, d["breath"] - delta * 19.0)
		if d["downed"]:
			d["bleed"] -= delta
			if d["bleed"] <= 0:
				_eliminate(f)
				_check_team(d["team"])
				continue
			_revive_progress(f, delta)
		if f == player and not autopilot:
			_player_input(f)
		else:
			d["hold"] = max(0.0, d.get("hold", 0.0) - delta)
			f.jump_held = d["hold"] > 0
			if think or d["downed"]:
				_bot_think(f)
				_bot_unstick(f)
	for f in fighters:
		if not f.data["out"]:
			if f.global_position.y > 28.0 and f.velocity.y > 0:
				f.velocity.y = 0.0
			if f.global_position.y < -5.0:
				f.global_position = Vector3(f.global_position.x, 2.0, f.global_position.z)
	_update_rooms()
	_projectiles(delta)
	_update_zone(delta)
	if int(time * 10) % 2 == 0:
		_pickup_cards()
	_camera(delta)
	_update_hud(delta)
	_check_end()


func _revive_progress(t: Fighter, delta: float) -> void:
	var helper = null
	for a in allies_of(t):
		if standing(a) and _flat(a.global_position, t.global_position) < 2.4:
			if a == player and not autopilot:
				if Input.is_action_pressed("interact"):
					helper = a
			else:
				helper = a
	if helper:
		helper.move_dir = Vector3.ZERO
		t.data["revive"] += delta
		if t.data["revive"] >= 3.0:
			_revive(t)
	else:
		t.data["revive"] = max(0.0, t.data["revive"] - delta)


func _player_input(f: Fighter) -> void:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	f.move_dir = Vector3(v.x, 0, v.y).rotated(Vector3.UP, cam_yaw)
	f.jump_held = Input.is_action_pressed("jump")
	if f.data["downed"]:
		return
	if Input.is_action_just_pressed("jump"): f.jump()
	if Input.is_action_just_pressed("attack"): do_attack(f)
	if Input.is_action_just_pressed("power"): do_power(f)
	if Input.is_action_just_pressed("ultimate"): do_ultimate(f)
	if Input.is_action_just_pressed("dodge"): do_dodge(f)
	# sprint: faster, drains stamina
	var sprinting: bool = Input.is_action_pressed("sprint") and f.move_dir.length() > 0.3 and f.data["breath"] > 2.0 and f.is_on_floor()
	f.data["sprint"] = sprinting


# ================= bot AI =================
## Bots use their movement kit when blocked: climbers climb automatically
## (walking into the wall), others jump / fly / glide over.
func _bot_unstick(f: Fighter) -> void:
	var d: Dictionary = f.data
	if d["downed"] or f.move_dir.length() < 0.5 or f.climbing:
		d["stuck"] = 0.0
		return
	var moved: float = Vector2(f.velocity.x, f.velocity.z).length()
	d["stuck"] = d.get("stuck", 0.0) + 0.2 if moved < 1.0 else 0.0
	if d["stuck"] >= 0.4 and not f.mob().has("climb"):
		f.jump()
		d["hold"] = 1.0
		d["stuck"] = 0.0



func _bot_think(f: Fighter) -> void:
	var d: Dictionary = f.data
	var pos := f.global_position
	# downed: crawl toward the nearest standing teammate
	if d["downed"]:
		var mate = null
		var md := 999.0
		for a in allies_of(f):
			if standing(a) and _flat(a.global_position, pos) < md:
				md = _flat(a.global_position, pos); mate = a
		f.move_dir = _steer(pos, mate.global_position) if mate and md > 1.5 else Vector3.ZERO
		return
	var hp_frac: float = d["hp"] / d["maxhp"]
	var leader = null
	if d["team"] == 0 and player and standing(player) and f != player:
		leader = player

	# 1) target: nearest visible enemy
	var target = null
	# early game: loot first, only fight what is right in front of you
	var td := (15.0 if leader == null else 12.0) if time > 40.0 else 8.0
	for e in enemies_of(f):
		var dd := _flat(e.global_position, pos)
		if e.data["downed"]:
			dd += 5.0
		if dd < td and _clear_line(pos, e.global_position):
			td = dd; target = e

	# 2) downed teammate nearby: go revive if it's safe
	var downed_mate = null
	for a in allies_of(f):
		if a.data["downed"] and _flat(a.global_position, pos) < 30:
			downed_mate = a
	if downed_mate and (target == null or td > 7):
		if d["id"] == "fumi" and d["cd"] <= 0 and _flat(downed_mate.global_position, pos) < 7:
			do_power(f)
		f.move_dir = _steer(pos, downed_mate.global_position) if _flat(downed_mate.global_position, pos) > 1.8 else Vector3.ZERO
		return

	# support powers
	var pw: Dictionary = POWERS[d["id"]]
	if d["cd"] <= 0 and d["breath"] >= pw["cost"]:
		match d["id"]:
			"lumi", "fumi":
				if hp_frac < 0.6 or allies_of(f).any(func(a): return not a.data["downed"] and a.data["hp"] < a.data["maxhp"] * 0.55 and _flat(a.global_position, pos) < 7):
					do_power(f)
			"kuroba":
				if target == null and rng.randf() < 0.1:
					do_power(f)

	if target:
		var to: Vector3 = target.global_position - pos
		to.y = 0
		var dist := to.length()
		# low HP: back off toward teammates / zone centre
		if hp_frac < 0.25 and not target.data["downed"] and rng.randf() < 0.7:
			var away: Vector3 = (pos - target.global_position).normalized()
			f.move_dir = _steer(pos, pos + away * 6.0)
			if rng.randf() < 0.15: do_dodge(f)
			return
		if d["cd"] <= 0 and d["breath"] >= pw["cost"] and dist <= pw["range"] and not ["lumi", "fumi", "kuroba"].has(d["id"]):
			do_power(f)
		if d["ult"] >= 100 and dist < 5:
			do_ultimate(f)
		d["sprint"] = dist > 8.0 and d["breath"] > 45.0
		if dist > 1.8:
			f.move_dir = _steer(pos, target.global_position)
		else:
			f.move_dir = Vector3.ZERO
			f.facing = to.normalized()
			if rng.randf() < 0.75:
				do_attack(f)
			if rng.randf() < 0.05:
				do_dodge(f)
		return

	# 3) stay inside the fog
	var zc := Vector3(zone_center.x, 0, zone_center.y)
	if not in_zone(pos, 6.0):
		f.move_dir = _steer(pos, zc)
		return
	# 4) follow the player (our team)
	if leader and regroup_t > 0 and _flat(leader.global_position, pos) > 3:
		f.move_dir = _steer(pos, leader.global_position)
		d["sprint"] = _flat(leader.global_position, pos) > 8 and d["breath"] > 30
		return
	d["sprint"] = false
	if leader and _flat(leader.global_position, pos) > 6:
		f.move_dir = _steer(pos, leader.global_position)
		return
	# 5) loot: nearest card
	var best = null
	var bd := 22.0
	for c in cards:
		var cd2 := _flat(c["pos"], pos)
		if cd2 < bd and in_zone(c["pos"], 3.0):
			bd = cd2; best = c
	if best:
		f.move_dir = _steer(pos, best["pos"])
		return
	# 6) wander toward the zone centre with some spread
	d["wander_t"] -= 0.2
	if d["wander_t"] <= 0 or _flat(d["goal"], pos) < 2:
		d["wander_t"] = rng.randf_range(3, 7)
		var r: float = max(4.0, zone_radius * 0.6)
		d["goal"] = zc + Vector3(rng.randf_range(-r, r), 0, rng.randf_range(-r, r))
	f.move_dir = _steer(pos, d["goal"]) * (0.0 if leader and _flat(leader.global_position, pos) < 4 else 1.0)


# ================= camera / visuals =================
func _camera(delta: float) -> void:
	if cam_target == null or cam_target.data["out"]:
		# spectate a living teammate, else anyone
		var alive_mates := members(0).filter(func(f): return not f.data["out"])
		var pool := alive_mates if not alive_mates.is_empty() else fighters.filter(func(f): return not f.data["out"])
		if pool.is_empty():
			return
		cam_target = pool[0]
	cam_yaw += (Input.get_action_strength("cam_left") - Input.get_action_strength("cam_right")) * delta * 2.2
	var touch := get_node_or_null("/root/Touch")
	if touch and touch.enabled:
		var td: Vector2 = touch.take_cam_delta()
		cam_yaw -= td.x
		cam_pitch = clamp(cam_pitch + td.y, 0.12, 1.25)
	var t := cam_target.global_position
	var want := t + Vector3(0, sin(cam_pitch) * cam_dist, cos(cam_pitch) * cam_dist).rotated(Vector3.UP, cam_yaw)
	# camera collision: don't end up inside buildings
	var from := t + Vector3(0, 1.6, 0)
	var q := PhysicsRayQueryParameters3D.create(from, want, 2)
	var hitr := get_world_3d().direct_space_state.intersect_ray(q)
	if not hitr.is_empty():
		want = hitr["position"] + (from - want).normalized() * 0.6
		cam.global_position = cam.global_position.lerp(want, min(1.0, delta * 20.0))
	cam.global_position = cam.global_position.lerp(want, min(1.0, delta * 5.0)) if time > 0.2 else want
	cam.look_at(t + Vector3(0, 1.4, -1.5).rotated(Vector3.UP, cam_yaw))


func _visible_to_player(f: Fighter) -> bool:
	return cam_target != null and _flat(f.global_position, cam_target.global_position) < 30


func _popup(pos: Vector3, t: String, col: Color, size := 52) -> void:
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
	l.global_position = pos + Vector3(rng.randf_range(-0.3, 0.3), 2.2, 0)
	var tw := create_tween()
	tw.tween_property(l, "global_position:y", l.global_position.y + 1.2, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.tween_callback(l.queue_free)


func _ring(pos: Vector3, radius: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius * 0.85; tm.outer_radius = radius
	mi.mesh = tm
	var m := _mat(col, true)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	add_child(mi)
	mi.global_position = pos + Vector3(0, 0.1, 0)
	mi.scale = Vector3(0.3, 1, 0.3)
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.25)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.45)
	tw.tween_callback(mi.queue_free)


# ================= HUD (see hud.gd) =================
const LANDMARKS := [[Vector2(0, -30), "โรงเรียน"], [Vector2(36, 30), "อาคารเรียนไม้เก่า"], [Vector2(-44, 38), "คฤหาสน์คาเนล"],
	[Vector2(44, -40), "เวทีคอนเสิร์ตลูมิ"], [Vector2(-40, -40), "ศูนย์สแกนตรา"]]


func area_name(p: Vector3) -> String:
	for lm in LANDMARKS:
		if Vector2(p.x, p.z).distance_to(lm[0]) < 22:
			return lm[1]
	return "ย่านเมืองคาเนล"


func _label(t: String, size := 16, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	return l


func _build_hud() -> void:
	hud = preload("res://scripts/hud.gd").new()
	hud.royale = self
	add_child(hud)
	hud.build()


func _message(t: String, dur := 1.8) -> void:
	if hud:
		hud.message(t, dur)


## team: team that made the play (-1 = the fog). Only shows what matters to us.
func _feed(t: String, team: int) -> void:
	if hud == null:
		return
	var icon := "sword" if team == 0 else ("cross" if t.contains("ตกรอบ") else ("cloud" if team < 0 else "hit"))
	hud.event(icon, t, team_color(team) if team >= 0 else Color("e0a0ff"))


func _update_hud(delta: float) -> void:
	if hud:
		hud.refresh(delta)


# ================= end =================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not ended:
		toggle_pause()
		return
	if pause_layer or ended:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_yaw -= event.relative.x * 0.0045
		cam_pitch = clamp(cam_pitch + event.relative.y * 0.003, 0.12, 1.25)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not autopilot:
		_capture_mouse()
	if event.is_action_pressed("zoom_in"):
		cam_dist = clamp(cam_dist - 1.0, 5.0, 16.0)
	elif event.is_action_pressed("zoom_out"):
		cam_dist = clamp(cam_dist + 1.0, 5.0, 16.0)
	elif event.is_action_pressed("map"):
		map_open = not map_open
		if hud: hud.set_big_map(map_open)
	elif event.is_action_pressed("call_team") and player and standing(player):
		regroup_t = 8.0
		_message("เรียกเพื่อน: รวมตัวที่ฉัน!", 1.5)
		if hud: hud.event("people", "%s: รวมตัว!" % player.data["name"], Color("5ab8ff"))
	elif event.is_action_pressed("status") and hud:
		hud.set_status(true)
	elif event.is_action_released("status") and hud:
		hud.set_status(false)


## Mouse look on desktop; on touch screens the right-side drag turns the camera instead.
func _capture_mouse() -> void:
	var touch := get_node_or_null("/root/Touch")
	if autopilot or (touch and touch.enabled):
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func toggle_pause() -> void:
	var tree := get_tree()
	if pause_layer:
		pause_layer.queue_free()
		pause_layer = null
		tree.paused = false
		_capture_mouse()
		return
	tree.paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 10
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(dim)
	var box := VBoxContainer.new()
	box.position = Vector2(440, 200)
	box.add_theme_constant_override("separation", 12)
	pause_layer.add_child(box)
	box.add_child(_label("พักเกม", 34))
	box.add_child(_label("ตัวละคร: %s — %s\nพลัง: %s\nเคลื่อนที่: %s" % [player.data["name"], POWERS[player.data["id"]]["name"], POWERS[player.data["id"]]["desc"], player.mob().get("desc", "")], 16, Color("c8cce8")))
	for item in [["เล่นต่อ", toggle_pause], ["ออกจากแมตช์", _quit_match]]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(400, 56)
		b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(item[1])
		box.add_child(b)


func _quit_match() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ended = true
	finished.emit(-1, {})


func _check_end() -> void:
	var left := teams_left()
	var mine_out: bool = team_out_order.has(0)
	if left.size() <= 1 or mine_out:
		_end()


func _end() -> void:
	if ended:
		return
	ended = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var placement: int = 1
	if team_out_order.has(0):
		placement = TEAMS - team_out_order.find(0)
	var stats := {"kills": 0, "damage": 0, "team": []}
	for f in members(0):
		stats["kills"] += f.data["kills"]
		stats["damage"] += f.data["damage"]
		stats["team"].append([f.data["id"], f.data["name"], f.data["kills"], f.data["damage"], f.data["lv"]])
	stats["time"] = time
	stats["player_kills"] = player.data["kills"]
	_message("ทีมเราชนะ! เหลือรอดเป็นทีมสุดท้าย" if placement == 1 else "ทีมเราตกรอบ — อันดับ %d/%d" % [placement, TEAMS], 4.0)
	await get_tree().create_timer(2.5 if not autopilot else 0.05).timeout
	finished.emit(placement, stats)
