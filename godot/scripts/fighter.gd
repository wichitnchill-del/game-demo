class_name Fighter
extends CharacterBody3D
## One combatant in the 3D arena (hero or enemy). Movement + visuals only;
## combat rules live in arena.gd so balance is in one place.

const Sheets := preload("res://scripts/sheets.gd")
const GRAVITY := 22.0
const HEIGHT := 1.8

var data: Dictionary           # party member dict (Game.party) or enemy dict
var is_hero := false
var move_dir := Vector3.ZERO   # set by controller each frame (xz, length 0..1)
var speed := 6.0
var facing := Vector3(0, 0, 1)
var knock := Vector3.ZERO
var invuln := 0.0
var flash := 0.0
var lock := 0.0                # can't move (attacking / hit-stun)
var dash := 0.0
var dash_dir := Vector3.ZERO

## Movement kit per character — everyone moves differently.
##   jumps: total jumps before landing · jump: jump speed · climb: wall-climb speed
##   glide: hold jump while falling · fly: hold jump to rise (costs breath)
##   float: hold jump to drift down slowly · slam: hard landing hits nearby enemies
const MOBILITY := {
	"oli":    {"jumps": 2, "glide": 2.2, "climb": 3.0, "desc": "กระโดด 2 ชั้น + ร่อนลม (ค้าง Space กลางอากาศ) · ปีนได้"},
	"setsu":  {"jumps": 2, "glide": 1.4, "glide_speed": 1.6, "climb": 3.2, "desc": "กระโดด 2 ชั้น + ร่อนลมไกลและเร็ว · ปีนได้"},
	"leon":   {"fly": 7.0, "climb": 2.8, "desc": "บินด้วยไฟ (ค้าง Space · ใช้ลมหายใจ) · ปีนได้"},
	"null":   {"jumps": 2, "float": 0.9, "climb": 2.8, "desc": "ลอยตัวลงช้าๆ เหมือนวิญญาณ (ค้าง Space) · ปีนได้"},
	"mio":    {"jump": 13.5, "slam": true, "climb": 2.2, "desc": "กระโดดสูงมาก · ลงพื้นแรงกระแทกศัตรูรอบตัว · ปีนช้า"},
	"lumi":   {"jumps": 3, "climb": 3.0, "desc": "กระโดด 3 ชั้น · ปีนได้"},
	"ren":    {"climb": 5.0, "desc": "นักปีน: ปีนกำแพง/ตึกเร็ว (เดินชนกำแพง)"},
	"haru":   {"climb": 4.0, "jumps": 2, "desc": "ปีนเร็ว + กระโดด 2 ชั้น"},
	"fumi":   {"climb": 4.5, "desc": "นักปีน: ปีนกำแพง/ตึกเร็ว"},
	"kuroba": {"climb": 7.5, "desc": "นักปีน: ปีนเร็วที่สุด"},
}

var jump_held := false         # controller sets this each frame
var jumps_left := 1
var climbing := false
var was_climbing := false
var air_time := 0.0
var fall_speed := 0.0
var flying := false
var on_landing: Callable       # royale: (fighter, impact_speed) for Mio's slam

const HumanModel := preload("res://scripts/human_model.gd")
const Dust := preload("res://scripts/dust.gd")
var step_t := 0.0
var dying := false
var model3d: Node3D            # HumanModel when the character has a 3D look
var was_grounded := true
var land_t := 0.0
var sprite: Sprite3D
var body_mesh: MeshInstance3D
var tag: Label3D
var shadow: MeshInstance3D


func setup(d: Dictionary, hero: bool, font: Font) -> void:
	data = d
	is_hero = hero
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45 if not d.get("boss", false) else 0.6
	cap.height = HEIGHT
	col.shape = cap
	col.position.y = HEIGHT / 2
	add_child(col)

	var id: String = d.get("id", d.get("sprite", ""))
	if id != "" and HumanModel.has_look(id):
		# animated 3D character (Human Basic Motions + Spellcasting)
		model3d = HumanModel.make(id)
		add_child(model3d)
	elif id != "" and Sheets.has(id):
		sprite = Sprite3D.new()
		sprite.texture = Sheets.crop(id, "body")
		var region: Rect2 = Sheets.REGIONS[id]["body"]
		sprite.pixel_size = (HEIGHT + 0.25) / region.size.y
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.shaded = false
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
		sprite.position.y = (HEIGHT + 0.25) / 2
		add_child(sprite)
	else:
		# training dummy: capsule body + head, tinted by element
		body_mesh = MeshInstance3D.new()
		var m := CapsuleMesh.new()
		m.radius = 0.42; m.height = HEIGHT
		body_mesh.mesh = m
		body_mesh.position.y = HEIGHT / 2
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(d.get("color", "8a90b4"))
		body_mesh.material_override = mat
		add_child(body_mesh)
		var eye := MeshInstance3D.new()
		var em := BoxMesh.new(); em.size = Vector3(0.5, 0.08, 0.1)
		eye.mesh = em
		eye.position = Vector3(0, HEIGHT - 0.35, 0.4)
		var emat := StandardMaterial3D.new(); emat.albedo_color = Color.BLACK
		eye.material_override = emat
		body_mesh.add_child(eye)

	shadow = MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.55; sm.bottom_radius = 0.55; sm.height = 0.02
	shadow.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0, 0, 0, 0.35)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = smat
	shadow.position.y = 0.02
	add_child(shadow)

	tag = Label3D.new()
	tag.font = font
	tag.font_size = 40
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 10
	tag.position.y = HEIGHT + 0.55
	tag.text = d["name"]
	tag.modulate = Color("9fd8ff") if hero else Color("ffb0a0")
	add_child(tag)


func alive() -> bool:
	return data["hp"] > 0 and data.get("seal", 0) < 2


func _physics_process(delta: float) -> void:
	invuln = max(0.0, invuln - delta)
	lock = max(0.0, lock - delta)
	flash = max(0.0, flash - delta)
	var v := Vector3.ZERO
	if dash > 0:
		dash -= delta
		v = dash_dir * 15.0
	elif lock <= 0 and (alive() or data.get("downed", false)):
		v = move_dir * speed
		if move_dir.length() > 0.1:
			facing = move_dir.normalized()
	var m := mob()
	var grounded := is_on_floor()
	flying = false
	# wall climb: walk into a wall to climb it
	was_climbing = climbing
	climbing = false
	if m.has("climb") and alive() and is_on_wall() and move_dir.length() > 0.3 and dash <= 0:
		var n := get_wall_normal()
		if move_dir.normalized().dot(-Vector3(n.x, 0, n.z).normalized()) > 0.35:
			climbing = true
	# glide: faster air movement
	var gliding: bool = m.has("glide") and jump_held and not grounded and velocity.y < 0 and alive()
	if gliding:
		v *= m.get("glide_speed", 1.3)
	v += knock
	knock = knock.move_toward(Vector3.ZERO, 30 * delta)
	velocity.x = v.x
	velocity.z = v.z
	if climbing:
		velocity.y = m["climb"]
	elif was_climbing and not grounded:
		# reached the top: hop up and over the edge
		velocity.y = max(velocity.y, 5.0)
		knock += facing * 4.0
	elif not grounded:
		velocity.y -= GRAVITY * delta
		if m.has("fly") and jump_held and alive() and data.get("breath", 0.0) > 1.0:
			flying = true
			velocity.y = min(velocity.y + 40.0 * delta, m["fly"])
			data["breath"] = max(0.0, data["breath"] - 14.0 * delta)
		elif gliding:
			velocity.y = max(velocity.y, -m["glide"])
		elif m.has("float") and jump_held and velocity.y < 0 and alive():
			velocity.y = max(velocity.y, -m["float"])
	elif m.has("fly") and jump_held and alive() and data.get("breath", 0.0) > 1.0:
		flying = true
		velocity.y = m["fly"] * 0.6   # take off
	if not grounded:
		air_time += delta
		fall_speed = min(fall_speed, velocity.y)
	move_and_slide()
	if is_on_floor() and not grounded:
		jumps_left = m.get("jumps", 1) - 1
		if m.get("slam", false) and fall_speed < -11.0 and on_landing.is_valid():
			on_landing.call(self, -fall_speed)
		fall_speed = 0.0
		air_time = 0.0
	if is_on_floor():
		fall_speed = 0.0
	if global_position.y < -10:   # fell out of the arena
		global_position = Vector3(0, 1, 0)
	_update_visual()


func mob() -> Dictionary:
	return MOBILITY.get(data.get("id", ""), {})


func jump() -> void:
	if not alive() or lock > 0.3:
		return
	var m := mob()
	if is_on_floor() or climbing:
		jumps_left = m.get("jumps", 1) - 1
		velocity.y = m.get("jump", 8.5)
		if climbing:   # wall-jump: kick off the wall
			knock = get_wall_normal() * 6.0 if is_on_wall() else -facing * 6.0
			climbing = false
	elif jumps_left > 0:
		jumps_left -= 1
		velocity.y = m.get("jump", 8.5) * 0.9


func start_dash(dir: Vector3) -> void:
	dust("puff", 1.1)
	dash_dir = (dir if dir.length() > 0.1 else facing).normalized()
	dash = 0.2
	invuln = 0.35


## One-shot animation (attack, power, hit …) on the 3D model.
func act(name: String, dur := 0.45, speed := 1.4) -> void:
	if model3d:
		model3d.action(name, dur, speed)
		if name == "hit":
			model3d.flash_hit()


func _near_camera() -> bool:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	return cam != null and cam.global_position.distance_to(global_position) < 32.0


func dust(kind: String, size := 1.0) -> void:
	if _near_camera():
		Dust.spawn(get_parent(), kind, global_position + Vector3(0, 0.05, 0), size)


## Death: fall backwards, sink and fade, then `done` is called (e.g. hide / free).
func die(done := Callable()) -> void:
	if dying:
		return
	dying = true
	collision_layer = 0
	if model3d:
		model3d.action("hit", 0.4, 1.0)
		model3d.flash_hit()
	dust("ring", 0.9)
	var tw := create_tween()
	if model3d:
		tw.tween_property(model3d, "rotation:x", -1.5, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_interval(0.5)
		tw.tween_property(model3d, "position:y", -1.2, 0.7)
	elif sprite:
		tw.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func():
		if done.is_valid(): done.call())


func _update_model(delta: float) -> void:
	var downed: bool = data.get("downed", false) or not alive()
	if facing.length() > 0.1:
		var want := atan2(facing.x, facing.z)
		model3d.rotation.y = lerp_angle(model3d.rotation.y, want, min(1.0, delta * 14.0))
	# lying on the ground when downed / knocked out
	model3d.rotation.x = lerp(model3d.rotation.x, -1.45 if downed else 0.0, min(1.0, delta * 8.0))
	model3d.position.y = lerp(model3d.position.y, 0.25 if downed else 0.0, min(1.0, delta * 8.0))
	var grounded := is_on_floor()
	if grounded and not was_grounded and air_time_prev > 0.35:
		land_t = 0.25
		dust("ring", clamp(air_time_prev, 0.6, 1.6))
	if not grounded and was_grounded and velocity.y > 3.0:
		dust("burst", 0.8)
	# footstep dust while running / sprinting / dodging
	var hv0 := Vector2(velocity.x, velocity.z).length()
	step_t -= delta
	if grounded and hv0 > 4.0 and step_t <= 0 and not downed:
		step_t = 0.32 if hv0 < speed * 1.15 else 0.18
		dust("puff", 0.7 if hv0 < speed * 1.15 else 1.0)
	was_grounded = grounded
	land_t = max(0.0, land_t - delta)
	var hv := Vector2(velocity.x, velocity.z).length()
	var st := "idle"
	if downed:
		st = "hit"
	elif dash > 0:
		st = "sprint"
	elif climbing:
		st = "climb"
	elif flying:
		st = "cast_idle"
	elif not grounded:
		st = "jump" if velocity.y > 1.0 else "fall"
	elif land_t > 0:
		st = "land"
	elif hv > speed * 1.15:
		st = "sprint"
	elif hv > 0.6:
		st = "run"
	model3d.state = st
	var anim_speed := 1.0
	if st == "run":
		anim_speed = clamp(hv / 5.0, 0.7, 1.6)
	if model3d.action_t <= 0 and model3d.anim:
		model3d.anim.speed_scale = anim_speed
	elif model3d.anim:
		model3d.anim.speed_scale = 1.0


var air_time_prev := 0.0


func _update_visual() -> void:
	if model3d:
		_update_model(get_physics_process_delta_time())
		if not is_on_floor():
			air_time_prev = air_time
		elif air_time > 0:
			air_time_prev = air_time
	var c := Color(1, 1, 1)
	if flash > 0:
		c = Color(1, 0.45, 0.45)
	elif data.get("windup", 0.0) > 0:
		c = Color(1, 0.75, 0.3)          # enemy telegraph
	elif invuln > 0 and is_hero:
		c = Color(1, 1, 1, 0.55)
	if not alive():
		c = Color(0.4, 0.4, 0.45, 0.5)
	if sprite:
		sprite.modulate = c
		# face left/right by flipping the paper cutout
		var cam := get_viewport().get_camera_3d()
		if cam:
			var right := cam.global_transform.basis.x
			if abs(facing.dot(right)) > 0.2:
				sprite.flip_h = facing.dot(right) < 0
	if body_mesh:
		(body_mesh.material_override as StandardMaterial3D).albedo_color = Color(data.get("color", "8a90b4")) * c
		if facing.length() > 0.1:
			body_mesh.rotation.y = atan2(facing.x, facing.z)
	if not alive():
		rotation.z = lerp(rotation.z, 1.4, 0.1) if body_mesh else rotation.z
