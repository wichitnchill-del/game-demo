extends Node3D
## Animated 3D character built from Kevin Iglesias' Human Basic Motions /
## Human Spellcasting Animations (male/female mannequin + shared rig).
## Each Core Blaker character gets its own outfit colours (palette recolour),
## hair, and small accessories (Oli's armband, Setsu's scarf, Fumi's book …).
##
## Use: var m = HumanModel.make("oli"); add_child(m); m.state = "run"; m.action("attack", 0.4)

const PALETTE := "res://assets/humans/HumanAnimations_ColorPalette.png"
const ANIM_DIR := "res://assets/humans/anims/"
## state -> file stem (without Human<G>@ prefix) ; loop?
const CLIPS := {
	"idle": ["Idle01", true], "run": ["Run01_Forward", true], "sprint": ["Sprint01_Forward", true],
	"walk": ["Walk01_Forward", true], "jump": ["Jump01 - Begin", false], "fall": ["Fall01", true],
	"land": ["Jump01 - Land", false], "talk": ["Talk01", true],
	"cast_idle": ["CastingIdle01", true], "hit": ["CastingDamage01", false],
	"attack": ["MagicAttackDirect1H01_R", false], "attack2": ["MagicAttackDirect2H01", false],
	"power": ["MagicAttackOmni01", false], "call": ["MagicAttackCall1H01_L", false],
}
const FEMALE := ["haru", "lumi", "fumi"]
const SKIN := Color("f6cdb0")   # warm peach (reads better under toon shading than the old pale beige)

## Outfit per character. Palette columns (from a debug render):
##  14 head · 13 chest+shoulders · 12 waist+forearms · 11 hips+hands
##  10 thighs · 9,8 shins · 7,6,5,4 shoes · 15 joints · 0..3 eyes/details
const LOOKS := {
	"oli":    {"top": "f4f4f4", "mid": "f4f4f4", "hips": "1f2a48", "legs": "1f2a48", "shins": "26304e", "shoes": "8a8a86", "hair": "8a2a1a", "scale": 1.0, "acc": ["armband"]},
	"haru":   {"top": "efe6d2", "mid": "efe6d2", "hips": "efe6d2", "legs": "8a8e98", "shins": "8a8e98", "shoes": "f8f8f8", "hair": "e07a9a", "scale": 0.96, "acc": ["long_hair", "clips"]},
	"ren":    {"top": "55565e", "mid": "55565e", "hips": "2a2a30", "legs": "2a2a30", "shins": "2a2a30", "shoes": "222226", "hair": "16161a", "scale": 1.0, "acc": []},
	"mio":    {"top": "2a2d3a", "mid": "2a2d3a", "hips": "16161a", "legs": "16161a", "shins": SKIN, "shoes": "2a2d3a", "hair": "", "scale": 1.12, "acc": []},
	"setsu":  {"top": "e8e4d8", "mid": "e8e4d8", "hips": "e8e4d8", "legs": "1e1e26", "shins": "1e1e26", "shoes": "3a3a3a", "hair": "4a7a5a", "scale": 0.98, "acc": ["scarf"]},
	"leon":   {"top": "16161a", "mid": "16161a", "hips": "f0f0f0", "legs": "f0f0f0", "shins": "f0f0f0", "shoes": "111114", "hair": "8a5a2a", "scale": 1.04, "acc": ["fire_tips"]},
	"lumi":   {"top": "fff4dc", "mid": "fff4dc", "hips": "1f2448", "legs": "1f2448", "shins": "1f2448", "shoes": "f4f4f8", "hair": "f2d24a", "scale": 0.95, "acc": ["horns"]},
	"null":   {"top": "f4f4f8", "mid": "f4f4f8", "hips": "f4f4f8", "legs": "f4f4f8", "shins": "f4f4f8", "shoes": "e8e8ee", "hair": "f0f0f6", "scale": 0.98, "acc": [], "ghost": true},
	"kuroba": {"top": "1e1e24", "mid": "1e1e24", "hips": "1e1e24", "legs": "1e1e24", "shins": "1e1e24", "shoes": "111114", "hair": "111114", "scale": 1.03, "acc": ["glasses"]},
	"fumi":   {"top": "7a5a5a", "mid": "7a5a5a", "hips": "7a5a5a", "legs": "7a5a5a", "shins": SKIN, "shoes": "6a5a4a", "hair": "1e1a16", "scale": 0.88, "acc": ["book", "braid"]},
}

static var _libs := {}        # gender -> AnimationLibrary
static var BONES := {}        # bone names present in the model skeleton
static var SKEL_PATH := "Skeleton3D"
static var _palettes := {}    # id -> ImageTexture

var id := ""
var gender := "M"
var model: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer
var state := "idle":
	set(v):
		if v != state:
			state = v
			_apply()
var action_name := ""
var action_t := 0.0
var tint := Color.WHITE


static func make(char_id: String) -> Node3D:
	var n := Node3D.new()
	n.set_script(load("res://scripts/human_model.gd"))
	n.build(char_id)
	return n


static func has_look(char_id: String) -> bool:
	return LOOKS.has(char_id)


func build(char_id: String) -> void:
	id = char_id
	gender = "F" if FEMALE.has(id) else "M"
	var look: Dictionary = LOOKS.get(id, LOOKS["ren"])
	model = load("res://assets/humans/Human%s_Model.fbx" % gender).instantiate()
	add_child(model)
	model.scale = Vector3.ONE * look.get("scale", 1.0)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	SKEL_PATH = str(model.get_path_to(skeleton))
	if BONES.is_empty():
		for i in skeleton.get_bone_count():
			BONES[skeleton.get_bone_name(i)] = true
	# outfit
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _palette_for(id)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.85
	if look.get("ghost", false):
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1, 1, 1, 0.62)
		mat.emission_enabled = true
		mat.emission = Color(0.6, 0.65, 0.9)
		mat.emission_energy_multiplier = 0.35
	preload("res://scripts/look.gd").toon(mat, not look.get("ghost", false), 0.011)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = mat
	_build_accessories(look)
	# animations
	anim = AnimationPlayer.new()
	model.add_child(anim)
	anim.root_node = NodePath("..")
	anim.add_animation_library("", _library(gender))
	_apply()


func _library(g: String) -> AnimationLibrary:
	if _libs.has(g):
		return _libs[g]
	var lib := AnimationLibrary.new()
	for st in CLIPS:
		var path := ANIM_DIR + "Human%s@%s.fbx" % [g, CLIPS[st][0]]
		if not ResourceLoader.exists(path):
			continue
		var scn: Node = load(path).instantiate()
		var ap: AnimationPlayer = scn.find_children("*", "AnimationPlayer", true, false)[0]
		var a: Animation = ap.get_animation(ap.get_animation_list()[0]).duplicate(true)
		a.loop_mode = Animation.LOOP_LINEAR if CLIPS[st][1] else Animation.LOOP_NONE
		# The two packs put the skeleton at different paths ("Skeleton3D" vs "Rig/Skeleton3D");
		# point every track at our model's skeleton and drop bones it doesn't have.
		for t in range(a.get_track_count() - 1, -1, -1):
			var tpath := str(a.track_get_path(t))
			var colon := tpath.find(":")
			if colon < 0:
				continue
			var bone := tpath.substr(colon + 1)
			if not BONES.has(bone):
				a.remove_track(t)
				continue
			a.track_set_path(t, NodePath(SKEL_PATH + ":" + bone))
			# keep the character in place: no root-bone translation
			if bone == "B-root" and a.track_get_type(t) == Animation.TYPE_POSITION_3D:
				a.track_set_enabled(t, false)
		lib.add_animation(st, a)
		scn.free()
	lib.add_animation("climb", _make_climb())
	_libs[g] = lib
	return lib


## Hand-over-hand climbing cycle built from the rig's rest pose
## (neither pack ships a climb clip). Arms reach up alternately, legs push.
func _make_climb() -> Animation:
	var a := Animation.new()
	a.length = 0.8
	a.loop_mode = Animation.LOOP_LINEAR
	# bone: [axis in bone space, angle at t=0, angle at t=0.4]
	var poses := {
		"B-upperArm.L": [Vector3.RIGHT, -2.6, -1.4], "B-upperArm.R": [Vector3.RIGHT, -1.4, -2.6],
		"B-forearm.L": [Vector3.RIGHT, -0.3, -1.2], "B-forearm.R": [Vector3.RIGHT, -1.2, -0.3],
		"B-thigh.L": [Vector3.RIGHT, -1.1, -0.2], "B-thigh.R": [Vector3.RIGHT, -0.2, -1.1],
		"B-shin.L": [Vector3.RIGHT, 1.3, 0.3], "B-shin.R": [Vector3.RIGHT, 0.3, 1.3],
	}
	for bone in poses:
		var idx := skeleton.find_bone(bone)
		if idx < 0:
			continue
		var rest: Quaternion = skeleton.get_bone_rest(idx).basis.get_rotation_quaternion()
		var t := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(t, NodePath(SKEL_PATH + ":" + bone))
		var p: Array = poses[bone]
		var q0 := rest * Quaternion(p[0], p[1])
		var q1 := rest * Quaternion(p[0], p[2])
		a.rotation_track_insert_key(t, 0.0, q0)
		a.rotation_track_insert_key(t, 0.4, q1)
		a.rotation_track_insert_key(t, 0.8, q0)
	return a


var _flash_mat: StandardMaterial3D
var _flash_tw: Tween


## Red flash when hit.
func flash_hit() -> void:
	if _flash_mat == null:
		_flash_mat = StandardMaterial3D.new()
		_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash_mat.albedo_color = Color(1, 0.25, 0.2, 0.0)
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = _flash_mat
	if _flash_tw:
		_flash_tw.kill()
	_flash_mat.albedo_color.a = 0.65
	_flash_tw = create_tween()
	_flash_tw.tween_property(_flash_mat, "albedo_color:a", 0.0, 0.22)


func _palette_for(char_id: String) -> Texture2D:
	if _palettes.has(char_id):
		return _palettes[char_id]
	var img: Image = (load(PALETTE) as Texture2D).get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var look: Dictionary = LOOKS.get(char_id, LOOKS["ren"])
	var col := func(k: String, fallback: Color) -> Color:
		var v = look.get(k, "")
		if v is Color: return v
		return Color(v) if v != "" else fallback
	var skin: Color = SKIN
	var head_col: Color = skin
	var cols := {
		14: head_col, 13: col.call("top", skin), 12: col.call("mid", skin), 11: col.call("hips", skin),
		10: col.call("legs", skin), 9: col.call("shins", skin), 8: col.call("shins", skin),
		7: col.call("shoes", Color.GRAY), 6: col.call("shoes", Color.GRAY).darkened(0.3),
		5: col.call("shoes", Color.GRAY).darkened(0.4), 4: col.call("shoes", Color.GRAY).darkened(0.4),
		15: col.call("top", skin).darkened(0.35),
		0: Color("2a1a14"), 1: Color("2a1a14"), 2: Color("2a1a14"), 3: Color("f8f8f8"),
	}
	# the model samples the top row of 8x8 cells; recolour the whole column to be safe
	for c in cols:
		var cc: Color = cols[c]
		for x in range(c * 8, c * 8 + 8):
			for y in range(0, 8):
				img.set_pixel(x, y, cc)
	var tex := ImageTexture.create_from_image(img)
	_palettes[char_id] = tex
	return tex


## node.position / rotation are given in the character's own frame (Y up, +Z forward,
## metres at scale 1) relative to the bone origin; convert them into bone space.
func _attach(bone: String, node: Node3D) -> void:
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skeleton.add_child(ba)
	var idx := skeleton.find_bone(bone)
	var sk_in_model: Transform3D = _relative(skeleton, model)
	var bone_basis: Basis = sk_in_model.basis * skeleton.get_bone_global_rest(idx).basis
	var inv := bone_basis.inverse()
	var desired := Basis.from_euler(node.rotation).scaled(node.scale)
	node.transform = Transform3D(inv * desired, inv * node.position)
	ba.add_child(node)


func _relative(n: Node3D, ancestor: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != ancestor:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t


func _mesh(mesh: Mesh, col: Color, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE, emissive := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.8
	if emissive:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 0.8
	preload("res://scripts/look.gd").toon(m, false)
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	return mi


const HEAD_Y := 0.1    # head centre above the B-head bone origin
const FACE_Z := 0.128  # front of the face


func _build_accessories(look: Dictionary) -> void:
	# eyes
	var eye := BoxMesh.new(); eye.size = Vector3(0.03, 0.046, 0.02)
	for sx in [-0.038, 0.038]:
		_attach("B-head", _mesh(eye, Color("201820"), Vector3(sx, HEAD_Y, FACE_Z)))
	var hair: String = look.get("hair", "")
	if hair != "":
		var hc := Color(hair)
		var cap := SphereMesh.new()
		cap.radius = 0.13; cap.height = 0.26
		# head bone origin is at the neck; hair wraps the top/back of the skull
		_attach("B-head", _mesh(cap, hc, Vector3(0, HEAD_Y + 0.03, -0.02), Vector3.ZERO, Vector3(1.12, 0.95, 1.12)))
		var fringe := BoxMesh.new(); fringe.size = Vector3(0.22, 0.06, 0.05)
		_attach("B-head", _mesh(fringe, hc, Vector3(0, HEAD_Y + 0.08, 0.095), Vector3(-0.35, 0, 0)))
	for a in look.get("acc", []):
		match a:
			"armband":
				var t := TorusMesh.new(); t.inner_radius = 0.045; t.outer_radius = 0.065
				_attach("B-upperArm.L", _mesh(t, Color("c8201a"), Vector3(0, 0.12, 0)))
			"long_hair":
				var c := CapsuleMesh.new(); c.radius = 0.11; c.height = 0.62
				_attach("B-head", _mesh(c, Color(hair), Vector3(0, -0.08, -0.09), Vector3(0.15, 0, 0)))
			"clips":
				var b := BoxMesh.new(); b.size = Vector3(0.05, 0.015, 0.015)
				_attach("B-head", _mesh(b, Color.WHITE, Vector3(0.08, HEAD_Y + 0.12, 0.07), Vector3(0, 0, 0.4)))
			"scarf":
				var t2 := TorusMesh.new(); t2.inner_radius = 0.06; t2.outer_radius = 0.11
				_attach("B-neck", _mesh(t2, Color("4a7a5a"), Vector3(0, 0.03, 0)))
				var mask := BoxMesh.new(); mask.size = Vector3(0.15, 0.08, 0.04)
				_attach("B-head", _mesh(mask, Color("2a2a2e"), Vector3(0, HEAD_Y - 0.06, FACE_Z - 0.01)))
			"fire_tips":
				var f := SphereMesh.new(); f.radius = 0.06; f.height = 0.1
				_attach("B-head", _mesh(f, Color("ff6a2a"), Vector3(0.09, HEAD_Y + 0.06, -0.05), Vector3.ZERO, Vector3.ONE, true))
				_attach("B-head", _mesh(f, Color("ff6a2a"), Vector3(-0.09, HEAD_Y + 0.06, -0.05), Vector3.ZERO, Vector3.ONE, true))
			"horns":
				var cn := CylinderMesh.new(); cn.top_radius = 0.0; cn.bottom_radius = 0.035; cn.height = 0.1
				_attach("B-head", _mesh(cn, Color("c8a040"), Vector3(0.08, HEAD_Y + 0.16, 0), Vector3(0, 0, -0.5)))
				_attach("B-head", _mesh(cn, Color("c8a040"), Vector3(-0.08, HEAD_Y + 0.16, 0), Vector3(0, 0, 0.5)))
			"glasses":
				var g := BoxMesh.new(); g.size = Vector3(0.16, 0.035, 0.01)
				_attach("B-head", _mesh(g, Color("b8c8d8"), Vector3(0, HEAD_Y, FACE_Z + 0.012)))
			"braid":
				var br := CapsuleMesh.new(); br.radius = 0.04; br.height = 0.4
				_attach("B-head", _mesh(br, Color(hair), Vector3(0, -0.05, -0.1), Vector3(0.2, 0, 0)))
			"book":
				var bk := BoxMesh.new(); bk.size = Vector3(0.16, 0.22, 0.04)
				_attach("B-handProp.L", _mesh(bk, Color("7a4a2a"), Vector3(0, 0.05, 0)))


## One-shot action that overrides the locomotion state for `dur` seconds.
func action(name: String, dur := 0.5, speed := 1.4) -> void:
	if not anim.has_animation(name):
		return
	action_name = name
	action_t = dur
	anim.play(name, 0.08, speed)


func _apply() -> void:
	if anim == null or action_t > 0:
		return
	if anim.has_animation(state):
		anim.play(state, 0.15)


func _process(delta: float) -> void:
	if _face:
		_place_face()
	if action_t > 0:
		action_t -= delta
		if action_t <= 0:
			action_name = ""
			if anim.has_animation(state):
				anim.play(state, 0.15)


## Cutscene close-ups: the character-sheet portrait as a cel "paper face"
## (assets/faces/decal_<id>.png, made by tools/make_face_decals.py).
## It always turns to the camera and floats just in front of the head centre, so
## it covers the mannequin head from any angle. Only the top of the portrait
## (head + hair) is used; the collar is cropped off.
var _face: MeshInstance3D
var _face_anchor: Node3D


func use_portrait_face() -> void:
	var p := "res://assets/faces/decal_%s.png" % id
	if not ResourceLoader.exists(p) or skeleton == null:
		return
	const KEEP := 0.80
	const W := 0.40
	var q := QuadMesh.new()
	q.size = Vector2(W, W * KEEP)
	_face = MeshInstance3D.new()
	_face.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(p)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.uv1_scale = Vector3(1, KEEP, 1)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_face.material_override = m
	_face.name = "portrait_face"
	_face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_face.top_level = true
	add_child(_face)
	_face_anchor = Node3D.new()
	_face_anchor.position = Vector3(0, HEAD_Y + 0.02, 0)
	_attach("B-head", _face_anchor)


## Swap the cutscene face to decal_<id>_<emotion>.png ("" = the default face).
## Unknown emotions fall back to the default, so story lines can tag freely.
func set_emotion(emotion: String) -> void:
	if _face == null:
		return
	var p := "res://assets/faces/decal_%s_%s.png" % [id, emotion]
	if emotion == "" or not ResourceLoader.exists(p):
		p = "res://assets/faces/decal_%s.png" % id
	var m := _face.material_override as StandardMaterial3D
	if m.albedo_texture == null or m.albedo_texture.resource_path != p:
		m.albedo_texture = load(p)
	emotion_now = emotion if p.ends_with("_%s.png" % emotion) else ""


var emotion_now := ""


func _place_face() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or not _face_anchor.is_inside_tree():
		return
	var c := _face_anchor.global_position
	var to_cam := (cam.global_position - c).normalized()
	# seen from behind: no face (the hair cap shows instead)
	var fwd := global_transform.basis.z.normalized()
	_face.visible = fwd.dot(to_cam) > -0.15
	_face.global_position = c + to_cam * 0.17
	_face.scale = Vector3.ONE * global_transform.basis.get_scale().x
