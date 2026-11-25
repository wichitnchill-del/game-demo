extends SubViewportContainer
## 3D stage behind the story cutscene dialogue (used by cutscene.gd).
##
## set_location(key)       builds a small set for the place (floor, walls, props, light)
## set_cast(left, right)   puts two actors on stage, facing each other
## set_group(ids)          lines several actors up facing the camera (group photo)
## focus(who)              speaker plays "talk", camera cuts to them; "" = wide shot
##
## Actors: HumanModel (3D animated) when the character has a look; otherwise a
## temporary model from assets/models/<id>.glb (made in Blender), otherwise a
## placeholder capsule with the name above it.

const HumanModel := preload("res://scripts/human_model.gd")
const Look := preload("res://scripts/look.gd")

## location -> [floor, wall, light colour, light energy, ambient, props]
const SETS := {
	"mansion":    ["8a6a45", "f3d9a8", "ffe2b0", 1.2, "6a5a4a", ["pillars", "rug"]],
	"kitchen":    ["9a7a5a", "e8b878", "ffd9a0", 1.1, "5a4a3a", ["counter", "table"]],
	"school":     ["b0b6c0", "a8d4f0", "ffffff", 1.2, "6a7a8a", ["desks", "board"]],
	"hallway":    ["c8ccd4", "d6e4f0", "ffffff", 1.1, "6a7080", ["lockers"]],
	"scanroom":   ["2d4a75", "cfe8ff", "bfe0ff", 1.3, "3a5a8a", ["scanner"]],
	"rooftop":    ["7a7a80", "ffb27a", "ffb27a", 1.3, "5a3f7a", ["railing"]],
	"oldbuilding":["3a3a44", "5a5a66", "c0c0d0", 0.7, "1e1e26", ["crates"]],
	"fire":       ["3a1a12", "ff8a3a", "ff7a30", 1.6, "3a0a0a", ["crates", "flames"]],
	"night":      ["1e2238", "2a3060", "8aa0ff", 0.7, "10142a", ["lamp"]],
	"concert":    ["1a0a3a", "c06aff", "e0a0ff", 1.4, "2a1050", ["stage_lights"]],
	"rain":       ["3a4050", "7a8aa0", "a0b0c8", 0.8, "2a3040", ["lamp"]],
	"white":      ["e8e8ee", "ffffff", "ffffff", 1.0, "c8c8d0", []],
	# full 3D street from blender/make_city.py (actors stand on the sidewalk)
	"city":       ["b8b4aa", "6aa8ec", "fff2dc", 1.6, "c8d8f0", ["city_block"]],
}
const SLOT_X := {"left": -1.15, "right": 1.15}

var viewport: SubViewport
var world: Node3D
var set_root: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var actors := {}          # slot -> {id, node, x, front}
var _cam_from := Transform3D()
var _cam_to := Transform3D()
var _cam_t := 1.0
var _flicker: Array = []  # lights that flicker (fire)
var _time := 0.0
var _loc_time := -1.0      # when the current location was set (same frame = place actors instantly)
const WALK_SPEED := 1.7
const STEP_EVERY := 0.36    # seconds between footsteps while walking
const STEPS := ["res://assets/sfx/step_1.wav", "res://assets/sfx/step_2.wav", "res://assets/sfx/step_3.wav", "res://assets/sfx/step_4.wav"]
var steps_played := 0      # counted for tests
## Spirits don't walk in — they materialise in a burst of their colour.
const SPIRITS := {"clover": Color("6aff9a")}


func _ready() -> void:
	stretch = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.shadow_enabled = true
	world.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 34
	world.add_child(cam)
	_wide(true)


func set_location(key: String) -> void:
	_loc_time = _time
	_clear_group()
	for n in leaving:
		n.queue_free()
	leaving.clear()
	var s: Array = SETS.get(key, SETS["night"])
	if set_root:
		set_root.queue_free()
	_flicker.clear()
	set_root = Node3D.new()
	world.add_child(set_root)
	# muted set colours so the characters read clearly against them
	var wall := Color(s[1]).lerp(Color("7a7c88"), 0.45)
	env.background_color = wall.darkened(0.35)
	env.ambient_light_color = Color(s[4]).lerp(Color.WHITE, 0.25)
	# less flat ambient + stronger key light = shapes get a light and a shadow side
	env.ambient_light_energy = 0.6
	sun.light_color = Color(s[2]).lerp(Color.WHITE, 0.4)
	sun.light_energy = s[3] * 0.95
	# indoor sets are small: a little fog softens the walls toward the background
	Look.apply(env, sun, world, env.background_color, 0.012)
	if "city_block" in s[5]:
		_city_block()
		Look.apply(env, sun, world, Color("a8c8ee"), 0.0025)
		_wide(true)
		return
	_box(Vector3(0, -0.05, -1.0), Vector3(12, 0.1, 9), Color(s[0]))           # floor
	_box(Vector3(0, 2.0, -4.2), Vector3(12, 4.2, 0.2), wall)                 # back wall
	_box(Vector3(-5.6, 2.0, -1.5), Vector3(0.2, 4.2, 6), wall.darkened(0.15))
	_box(Vector3(5.6, 2.0, -1.5), Vector3(0.2, 4.2, 6), wall.darkened(0.15))
	for p in s[5]:
		_prop(p)
	_wide(true)


func _box(pos: Vector3, size: Vector3, col: Color, parent: Node3D = null) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.85
	m.material_override = mat
	m.position = pos
	(parent if parent else set_root).add_child(m)
	return m


func _light(pos: Vector3, col: Color, energy: float, rng := 6.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	set_root.add_child(l)
	return l


func _prop(kind: String) -> void:
	match kind:
		"pillars":
			for x in [-3.6, 3.6]:
				_box(Vector3(x, 2.0, -3.6), Vector3(0.5, 4.0, 0.5), Color("e8d4b0"))
		"rug":
			_box(Vector3(0, 0.01, -0.6), Vector3(4.5, 0.02, 2.6), Color("8a2a3a"))
		"counter":
			_box(Vector3(-3.2, 0.45, -3.4), Vector3(4.0, 0.9, 0.9), Color("c8a07a"))
			_box(Vector3(-3.2, 0.93, -3.4), Vector3(4.1, 0.06, 1.0), Color("eeeae0"))
		"table":
			_box(Vector3(3.0, 0.38, -2.4), Vector3(1.6, 0.06, 1.0), Color("a07a4a"))
			for dx in [-0.7, 0.7]:
				_box(Vector3(3.0 + dx, 0.18, -2.4), Vector3(0.08, 0.36, 0.8), Color("7a5a3a"))
		"desks":
			for x in [-3.8, -2.4, 2.4, 3.8]:
				_box(Vector3(x, 0.37, -2.6), Vector3(1.0, 0.06, 0.6), Color("c8a878"))
				_box(Vector3(x, 0.18, -2.6), Vector3(0.9, 0.36, 0.08), Color("6a6a72"))
		"board":
			_box(Vector3(0, 2.0, -4.05), Vector3(4.6, 1.5, 0.06), Color("2a4a3a"))
		"lockers":
			for i in 8:
				_box(Vector3(-4.2 + i * 1.2, 1.0, -3.9), Vector3(1.1, 2.0, 0.5), Color("6a8ab0").darkened(0.05 * (i % 2)))
		"scanner":
			var arch := _box(Vector3(0, 1.3, -3.2), Vector3(2.6, 2.6, 0.3), Color("dfefff"))
			_box(Vector3(0, 1.2, -3.05), Vector3(1.8, 2.2, 0.05), Color("2d4a75"), arch.get_parent())
			_light(Vector3(0, 2.4, -2.6), Color("7ac8ff"), 2.0)
		"railing":
			_box(Vector3(0, 0.9, -3.9), Vector3(11, 0.06, 0.06), Color("d0d0d8"))
			for i in 12:
				_box(Vector3(-5.5 + i, 0.45, -3.9), Vector3(0.05, 0.9, 0.05), Color("d0d0d8"))
		"crates":
			for c in [Vector3(-3.6, 0.4, -2.8), Vector3(-2.9, 0.4, -3.2), Vector3(3.4, 0.4, -3.0), Vector3(-3.3, 1.2, -3.0)]:
				_box(c, Vector3(0.8, 0.8, 0.8), Color("7a5a3a"))
		"flames":
			for x in [-3.0, 3.2]:
				_flicker.append(_light(Vector3(x, 0.8, -2.6), Color("ff7a20"), 3.0, 5.0))
		"lamp":
			_box(Vector3(3.4, 1.6, -3.0), Vector3(0.1, 3.2, 0.1), Color("3a3a44"))
			_light(Vector3(3.4, 3.1, -2.8), Color("ffe0a0"), 2.2, 7.0)
		"stage_lights":
			for x in [-3.0, 0.0, 3.0]:
				_flicker.append(_light(Vector3(x, 3.6, -1.5), Color("e0a0ff") if x != 0.0 else Color("ffe08a"), 2.0, 8.0))


func has_actor(id: String) -> bool:
	for slot in actors:
		if actors[slot]["id"] == id:
			return true
	return false


func _clear_group() -> void:
	for slot in actors.keys():
		if str(slot).begins_with("g"):
			actors[slot]["node"].queue_free()
			actors.erase(slot)


## Line actors up side by side facing the camera; tallest in the middle-back feel
## comes from the models themselves. Camera goes to a centred wide shot.
func set_group(ids: Array) -> void:
	for slot in actors.keys():
		actors[slot]["node"].queue_free()
	actors.clear()
	var n := ids.size()
	var gap := 0.85
	for k in n:
		var id: String = ids[k]
		var x := (k - (n - 1) / 2.0) * gap
		var node := _make_actor(id)
		node.position = Vector3(x, 0, -0.6 - absf(x) * 0.12)
		node.rotation.y = -x * 0.08
		world.add_child(node)
		actors["g%d" % k] = {"id": id, "node": node, "x": x, "front": true}
	_wide(false)


func set_cast(left: String, right: String) -> void:
	# a group that is already posing stays, pushed back into the background,
	# so a character can watch it (Oli outside the family photo)
	var group_bg := false
	for slot in actors:
		if str(slot).begins_with("g"):
			group_bg = true
			if not actors[slot].get("bg", false):
				actors[slot]["bg"] = true
				actors[slot]["node"].position.z -= 1.9
	for slot in ["left", "right"]:
		var want: String = left if slot == "left" else right
		var cur: Dictionary = actors.get(slot, {})
		if cur.get("id", "") == want:
			continue
		if cur.has("node"):
			_exit(cur, slot)
		actors.erase(slot)
		if want == "":
			continue
		var n := _make_actor(want)
		var home := Vector3(SLOT_X[slot], 0, -0.6)
		if group_bg:
			# watcher stands off to the side, outside the group
			home = Vector3(signf(SLOT_X[slot]) * 1.6, 0, 0.8)
		# face the other actor, slightly toward camera
		var face := deg_to_rad(65 if slot == "left" else -65)
		world.add_child(n)
		if _time - _loc_time < 0.001:
			# scene just opened: already in place
			n.position = home
			n.rotation.y = face
		elif SPIRITS.has(want):
			n.position = home
			n.rotation.y = face * 0.5
			_materialise(n, SPIRITS[want])
		else:
			# arriving mid-scene: walk in from that side of the set (in front of a background group)
			# start just inside the wide shot's edge so the entrance is quick (~1.3 s)
			n.position = Vector3(signf(home.x) * 3.3, 0, 0.0)
			n.set_meta("walk_to", home)
			n.set_meta("face", face)
			if n.has_method("build"):
				n.state = "walk"
		actors[slot] = {"id": want, "node": n, "x": home.x, "front": false}
		if group_bg:
			# watcher faces the group instead of an empty partner slot
			var f := atan2(-home.x * 0.8, -3.3)
			n.set_meta("face", f)
			if not n.has_meta("walk_to"):
				n.rotation.y = f
	_attach_spirits()


## A thumb-sized spirit doesn't stand in its own slot: it hovers by the shoulder
## of the person on the other side (ใบสี่ next to Oli), at half size.
func _attach_spirits() -> void:
	for slot in actors:
		var a: Dictionary = actors[slot]
		if not SPIRITS.has(a["id"]):
			continue
		var other: String = "right" if slot == "left" else "left"
		if not actors.has(other) or SPIRITS.has(actors[other]["id"]):
			continue
		var host: Node3D = actors[other]["node"]
		var hx: float = SLOT_X[other]
		var spot := Vector3(hx - signf(hx) * 0.5, 0.75, -0.45)
		var n: Node3D = a["node"]
		n.remove_meta("walk_to")
		n.position = spot
		n.rotation.y = deg_to_rad(-20.0 * signf(hx))
		n.set_meta("size", 0.5)
		if not n.has_meta("grow"):
			n.scale = Vector3.ONE * 0.5
		a["x"] = spot.x
		a["host"] = host


func _make_actor(id: String) -> Node3D:
	if HumanModel.has_look(id):
		var h := HumanModel.make(id)
		h.state = "idle"
		h.use_portrait_face()
		return h
	var glb := "res://assets/models/%s.glb" % id
	if ResourceLoader.exists(glb):
		# static Blender model: _process gives it breathing / nodding / hovering
		var holder := Node3D.new()
		var body := (load(glb) as PackedScene).instantiate()
		body.name = "body"
		holder.add_child(body)
		Look.toon_model(body, 0.014)
		holder.set_meta("static", true)
		holder.set_meta("float", id == "clover")
		_add_temp_face(holder, id)
		return holder
	# placeholder until a model exists
	var holder := Node3D.new()
	var m := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = 0.28
	c.height = 1.6
	m.mesh = c
	m.position.y = 0.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.from_hsv(float(hash(id) % 360) / 360.0, 0.35, 0.85)
	m.material_override = mat
	holder.add_child(m)
	var lbl := Label3D.new()
	lbl.text = id
	lbl.position.y = 1.85
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 48
	holder.add_child(lbl)
	return holder


## Speaker talks, everyone else idles; camera cuts to the speaker.
var leaving: Array = []     # actors walking (or fading) off stage, freed when out of view
var _pending_focus := []   # [who, speaking] — re-applied when a walking actor arrives


func focus(who: String, speaking := true, emotion := "") -> void:
	_pending_focus = [who, speaking, emotion]
	for slot in actors:
		var an: Node3D = actors[slot]["node"]
		if actors[slot]["id"] == who and an.has_method("set_emotion"):
			an.set_emotion(emotion)
	var target_slot := ""
	for slot in actors:
		var a: Dictionary = actors[slot]
		var talking: bool = a["id"] == who
		if talking:
			target_slot = slot
		a["node"].set_meta("talking", talking and speaking)
		if a["node"].has_method("build") and not a["node"].has_meta("walk_to"):   # HumanModel
			a["node"].state = "talk" if talking and speaking else "idle"
	if target_slot == "" or actors[target_slot]["node"].has_meta("walk_to"):
		# narration, or the speaker is still walking in: hold the wide shot
		_wide(false)
		return
	var x: float = actors[target_slot]["x"]
	if actors[target_slot]["front"]:
		# group shot: straight-on close-up of whoever speaks
		var feye := Vector3(x * 0.85, 1.55, 2.4)
		_move_cam(Transform3D.IDENTITY.looking_at(Vector3(x, 1.2, -0.6) - feye, Vector3.UP).translated(feye), false)
		return
	if actors[target_slot].has("host"):
		# spirit on a shoulder: two-shot of host + spirit, framed at shoulder height
		var seye := Vector3(x * 0.6, 1.55, 2.3)
		_move_cam(Transform3D.IDENTITY.looking_at(Vector3(x, 1.3, -0.5) - seye, Vector3.UP).translated(seye), false)
		return
	if _group_behind():
		# watching the group: over the speaker's shoulder, toward the group
		# camera above and behind the watcher: his head/shoulder low in the corner, group in full view
		var beye := Vector3(x + signf(x) * 0.4, 2.15, 2.9)
		_move_cam(Transform3D.IDENTITY.looking_at(Vector3(-x * 0.12, 1.05, -2.5) - beye, Vector3.UP).translated(beye), false)
		return
	var other := -x
	# medium close-up from the other actor's side; the head sits in the upper
	# third so the dialogue box (bottom 30%) never covers the face
	var eye := Vector3(other * 0.5, 1.6, 2.6)
	var look := Vector3(x, 1.22, -0.6)
	if emotion in CLOSE_EMOTIONS:
		# strong feeling: tight close-up on the face (head + shoulders), face kept
		# in the upper half so the dialogue box doesn't cover it
		var hy := _head_y(actors[target_slot]["node"])
		eye = Vector3(x + (other - x) * 0.22, hy + 0.02, 0.85)
		look = Vector3(x, hy - 0.14, -0.6)
	close_up = emotion in CLOSE_EMOTIONS
	_move_cam(Transform3D.IDENTITY.looking_at(look - eye, Vector3.UP).translated(eye), false)


## Lines tagged with these emotions get a tight close-up instead of the medium shot.
const CLOSE_EMOTIONS := ["sad", "cry", "angry", "surprised"]
var close_up := false      # last speaker shot was a close-up (tests)


func _head_y(n: Node3D) -> float:
	if n.has_meta("face_y"):
		return float(n.get_meta("face_y"))
	return 1.62 * n.scale.y


func _wide(instant: bool) -> void:
	var eye := Vector3(0, 1.8, 6.4)
	_move_cam(Transform3D.IDENTITY.looking_at(Vector3(0, 0.95, -0.8) - eye, Vector3.UP).translated(eye), instant)


func _move_cam(to: Transform3D, instant: bool) -> void:
	_cam_from = cam.global_transform if not instant else to
	_cam_to = to
	_cam_t = 0.0 if not instant else 1.0
	if instant:
		cam.global_transform = to


func _process(delta: float) -> void:
	_time += delta
	if _cam_t < 1.0:
		_cam_t = min(1.0, _cam_t + delta * 1.6)
		var e := 1.0 - pow(1.0 - _cam_t, 3.0)
		cam.global_transform = _cam_from.interpolate_with(_cam_to, e)
	else:
		# slow push-in keeps shots alive
		cam.position += -cam.global_transform.basis.z * delta * 0.04
	_walk(delta)
	_leave(delta)
	_footsteps(delta)
	_grow(delta)
	_animate_static()
	_place_temp_faces()
	for l in _flicker:
		l.light_energy = 2.4 + sin(_time * 13.0 + l.position.x) * 0.5 + sin(_time * 7.3) * 0.3


## Blender temp models have no skeleton: breathe, nod while talking, hover (spirits).
func _animate_static() -> void:
	for slot in actors:
		var n: Node3D = actors[slot]["node"]
		if not n.has_meta("static"):
			continue
		var body := n.get_node_or_null("body") as Node3D
		if body == null:
			continue
		var ph := _time * 1.7 + (0.0 if slot == "left" else 1.3)
		if n.get_meta("float", false):
			body.position.y = sin(ph * 1.4) * 0.06
			body.rotation.y = sin(ph * 0.8) * 0.25
		else:
			body.scale = Vector3(1.0, 1.0 + sin(ph) * 0.008, 1.0)
		if n.get_meta("talking", false):
			body.rotation.x = sin(_time * 7.0) * 0.025
			body.rotation.z = sin(_time * 3.1) * 0.02
		else:
			body.rotation.x = lerpf(body.rotation.x, 0.0, 0.1)
			body.rotation.z = lerpf(body.rotation.z, 0.0, 0.1)


## Actors with a "walk_to" target walk there, then turn to face their partner.
func _walk(delta: float) -> void:
	for slot in actors:
		var n: Node3D = actors[slot]["node"]
		if not n.has_meta("walk_to"):
			continue
		var to: Vector3 = n.get_meta("walk_to")
		var d := to - n.position
		d.y = 0
		if d.length() < 0.05:
			n.position = to
			n.rotation.y = n.get_meta("face")
			n.remove_meta("walk_to")
			if not _pending_focus.is_empty():
				focus(_pending_focus[0], _pending_focus[1], _pending_focus[2])
			if n.has_method("build"):
				n.state = "talk" if n.get_meta("talking", false) else "idle"
			continue
		n.position += d.normalized() * min(d.length(), WALK_SPEED * delta)
		n.rotation.y = lerp_angle(n.rotation.y, atan2(d.x, d.z), min(1.0, delta * 10.0))
		if not n.has_method("build"):
			# static model: little hop so it doesn't glide
			var body := n.get_node_or_null("body") as Node3D
			if body:
				body.position.y = absf(sin(_time * 9.0)) * 0.04


func is_busy() -> bool:
	for slot in actors:
		if actors[slot]["node"].has_meta("walk_to"):
			return true
	return false


## Spirit entrance: tiny -> full size with a light flare and a ring of sparks.
func _materialise(n: Node3D, col: Color) -> void:
	n.scale = Vector3.ONE * 0.02
	n.set_meta("grow", 0.0)
	var flare := OmniLight3D.new()
	flare.name = "flare"
	flare.light_color = col
	flare.light_energy = 6.0
	flare.omni_range = 4.0
	flare.position.y = 1.35
	n.add_child(flare)
	var p := CPUParticles3D.new()
	p.name = "sparks"
	p.position.y = 1.35
	p.amount = 60
	p.one_shot = true
	p.explosiveness = 0.85
	p.lifetime = 1.2
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 2.0
	p.gravity = Vector3(0, -0.6, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var m := SphereMesh.new()
	m.radius = 0.025
	m.height = 0.05
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col.lightened(0.3)
	m.material = mat
	p.mesh = m
	n.add_child(p)
	p.emitting = true


func _grow(delta: float) -> void:
	for slot in actors:
		var n: Node3D = actors[slot]["node"]
		if not n.has_meta("grow"):
			continue
		var t: float = min(1.0, n.get_meta("grow") + delta / 0.9)
		n.set_meta("grow", t)
		# overshoot a little, then settle (elastic pop)
		var e := 1.0 + 0.25 * sin(t * PI) * (1.0 - t) * 3.0 if t > 0.5 else t * 2.0 * 0.9 + 0.02
		var size: float = n.get_meta("size", 1.0)
		n.scale = Vector3.ONE * clampf(e, 0.02, 1.3) * size
		var flare := n.get_node_or_null("flare") as OmniLight3D
		if flare:
			flare.light_energy = lerpf(6.0, 0.8, t)
		if t >= 1.0:
			n.scale = Vector3.ONE * size
			n.remove_meta("grow")


## Replaced actor leaves: people walk out on their own side, spirits shrink away.
## At a scene change (same frame as set_location) they just vanish.
func _exit(a: Dictionary, slot: String) -> void:
	var n: Node3D = a["node"]
	if _time - _loc_time < 0.001:
		n.queue_free()
		return
	n.remove_meta("walk_to")
	if SPIRITS.has(a["id"]):
		n.set_meta("shrink", 1.0)
	else:
		var side := signf(float(a.get("x", SLOT_X.get(slot, 1.0))))
		n.set_meta("leave_to", Vector3(side * 4.2, 0, 0.3))
		if n.has_method("build"):
			n.state = "walk"
	leaving.append(n)


func _leave(delta: float) -> void:
	for n in leaving.duplicate():
		if not is_instance_valid(n):
			leaving.erase(n)
			continue
		var done := false
		if n.has_meta("shrink"):
			var t: float = n.get_meta("shrink") - delta / 0.5
			n.set_meta("shrink", t)
			n.scale = Vector3.ONE * maxf(t, 0.01) * float(n.get_meta("size", 1.0))
			done = t <= 0.0
		else:
			var to: Vector3 = n.get_meta("leave_to")
			var d: Vector3 = to - n.position
			d.y = 0
			n.position += d.normalized() * min(d.length(), WALK_SPEED * delta)
			n.rotation.y = lerp_angle(n.rotation.y, atan2(d.x, d.z), min(1.0, delta * 10.0))
			if not n.has_method("build"):
				var body := n.get_node_or_null("body") as Node3D
				if body:
					body.position.y = absf(sin(_time * 9.0)) * 0.04
			done = d.length() < 0.05
		if done:
			leaving.erase(n)
			n.queue_free()


func _group_behind() -> bool:
	for slot in actors:
		if str(slot).begins_with("g") and actors[slot].get("bg", false):
			return true
	return false


## Footsteps for anyone walking in or out (positional, so they pan with the character).
func _footsteps(delta: float) -> void:
	var walkers: Array = []
	for slot in actors:
		if actors[slot]["node"].has_meta("walk_to"):
			walkers.append(actors[slot]["node"])
	for n in leaving:
		if is_instance_valid(n) and n.has_meta("leave_to"):
			walkers.append(n)
	for n in walkers:
		var t: float = n.get_meta("step_t", 0.0) - delta
		if t <= 0.0:
			t += STEP_EVERY
			_step_sound(n)
		n.set_meta("step_t", t)


func _step_sound(n: Node3D) -> void:
	var p := n.get_node_or_null("steps") as AudioStreamPlayer3D
	if p == null:
		p = AudioStreamPlayer3D.new()
		p.name = "steps"
		p.unit_size = 4.0
		p.volume_db = -4.0
		n.add_child(p)
	p.stream = load(STEPS[randi() % STEPS.size()])
	p.pitch_scale = randf_range(0.9, 1.1)
	p.play()
	steps_played += 1


var shutter_played := 0   # counted for tests


## A flash while a group is posing = someone takes the photo: everyone squeezes
## together first, then the shutter clicks.
func photo_flash() -> bool:
	var members: Array = []
	for slot in actors:
		if str(slot).begins_with("g") and not actors[slot].get("bg", false):
			members.append(actors[slot])
	if members.is_empty():
		return false
	var tw := create_tween().set_parallel(true)
	for a in members:
		var nx: float = a["x"] * 0.72
		a["x"] = nx
		tw.tween_property(a["node"], "position:x", nx, 0.25).set_trans(Tween.TRANS_SINE)
	var p := AudioStreamPlayer.new()
	p.stream = load("res://assets/sfx/shutter.wav")
	p.volume_db = -2.0
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	shutter_played += 1
	return true


## Head-centre height of each Blender temp model (1.66 m × height/1.75, matching
## blender/make_temp_models.py) — where its cartoon face goes.
const TEMP_HEAD_Y := {"piang": 1.423, "mom": 1.575, "victor": 1.745, "lily": 1.29,
	"teacher": 1.632, "enji": 1.707, "kai": 1.764, "thug": 1.67}


## Cartoon face (assets/faces/decal_<id>.png from tools/make_temp_faces.py) on a
## temp model: turns to the camera, hidden when the model faces away.
func _add_temp_face(holder: Node3D, id: String) -> void:
	var p := "res://assets/faces/decal_%s.png" % id
	if not TEMP_HEAD_Y.has(id) or not ResourceLoader.exists(p):
		return
	var hy: float = TEMP_HEAD_Y[id]
	var q := QuadMesh.new()
	var w := 0.34 * hy / 1.66
	q.size = Vector2(w, w)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(p)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.name = "face"
	mi.top_level = true
	holder.add_child(mi)
	holder.set_meta("face_y", hy)


func _place_temp_faces() -> void:
	var all: Array = []
	for slot in actors:
		all.append(actors[slot]["node"])
	all.append_array(leaving)
	for n in all:
		if not is_instance_valid(n) or not n.has_meta("face_y"):
			continue
		var f := n.get_node_or_null("face") as MeshInstance3D
		var body := n.get_node_or_null("body") as Node3D
		if f == null or body == null:
			continue
		var c: Vector3 = body.global_transform * Vector3(0, n.get_meta("face_y"), 0)
		var to_cam := (cam.global_position - c).normalized()
		f.global_position = c + to_cam * 0.13
		f.scale = n.scale
		f.visible = n.global_transform.basis.z.normalized().dot(to_cam) > -0.15


## Outdoor street: the Blender city block (godot/assets/models/city_block.glb).
## Blender's street runs along its Y axis = Godot -Z, so the default camera looks
## straight down the avenue. The block is shifted so the stage origin sits on the
## right-hand sidewalk with the row of street trees just left of the actors
## (frame-left), and the road, hedge median and skytrain viaduct beyond them.
## Trees repeat every 9 m; the z shift keeps them out of the camera's path.
const CITY_OFFSET := Vector3(-11.8, -0.16, -3.0)


func _city_block() -> void:
	var p := "res://assets/models/city_block.glb"
	if not ResourceLoader.exists(p):
		return
	var city: Node3D = (load(p) as PackedScene).instantiate()
	city.name = "city"
	city.position = CITY_OFFSET
	set_root.add_child(city)
	env.background_color = Color("6aa8ec")
	env.ambient_light_color = Color("c8d8f0")
	env.ambient_light_energy = 0.4
	sun.light_color = Color("fff2dc")
	sun.light_energy = 1.1
