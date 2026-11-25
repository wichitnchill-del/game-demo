extends RefCounted
## Spawns BinbunVFX effects (Battle FX + Dark Magic FX, CC0) tinted per element.
##   Vfx.spawn(parent, "swing", pos, dir, color)
## kinds: swing slash claw charge shield dark_area dark_ball

const SCENES := {
	"swing": "res://assets/BinbunVFX_Vol2/BattleFX/effects/swing/vfx_blank_swing.tscn",
	"slash": "res://assets/BinbunVFX_Vol2/BattleFX/effects/slash/vfx_blank_slash.tscn",
	"claw": "res://assets/BinbunVFX_Vol2/BattleFX/effects/claw/vfx_blank_claw.tscn",
	"charge": "res://assets/BinbunVFX_Vol2/BattleFX/effects/charge/vfx_blank_charge.tscn",
	"shield": "res://assets/BinbunVFX_Vol2/BattleFX/effects/shield/vfx_blank_shield_01.tscn",
	"dark_area": "res://assets/BinbunVFX_Vol2/DarkMagicFX/effects/area/vfx_evil_area_01.tscn",
	"dark_ball": "res://assets/BinbunVFX_Vol2/DarkMagicFX/effects/ball/vfx_ball_evil_01.tscn",
}
## base size so a 1.0 call fits a 1.8 m character (measured with tests/shot_vfx.gd)
const BASE_SCALE := {"swing": 1.0, "slash": 0.7, "claw": 0.9, "charge": 0.9, "shield": 0.27, "dark_area": 0.55, "dark_ball": 0.8}
const ELEMENT_COLOR := {"ไฟ": Color("ff6a2a"), "น้ำ": Color("4aa8ff"), "ลม": Color("7dffb0"), "ดิน": Color("d0a060"), "": Color("c8a8ff")}

static var _cache := {}


static func element_color(el: String) -> Color:
	return ELEMENT_COLOR.get(el, ELEMENT_COLOR[""])


## Returns the node; it frees itself after `dur` (+ fade time).
static func spawn(parent: Node, kind: String, pos: Vector3, dir := Vector3.FORWARD, col := Color(-1, 0, 0), dur := 1.0, scale := 1.0) -> Node3D:
	if not SCENES.has(kind):
		return null
	if not _cache.has(kind):
		_cache[kind] = load(SCENES[kind])
	var ps: PackedScene = _cache[kind]
	if ps == null:
		return null
	var n: Node3D = ps.instantiate()
	parent.add_child(n)
	n.global_position = pos
	n.scale = Vector3.ONE * scale * BASE_SCALE.get(kind, 1.0)
	if dir.length() > 0.01:
		var flat := Vector3(dir.x, 0, dir.z)
		if flat.length() > 0.01:
			n.look_at(pos + flat.normalized(), Vector3.UP)
	if col.r >= 0:
		for prop in ["primary_color", "secondary_color", "light_color"]:
			if prop in n:
				var c := col if prop != "secondary_color" else col.lightened(0.45)
				n.set(prop, c)
	if n.has_method("play"):
		n.play()
	elif "emitting" in n:
		n.emitting = true
	var tree := parent.get_tree()
	if tree:
		tree.create_timer(dur).timeout.connect(func():
			if is_instance_valid(n):
				if "emitting" in n and not n.has_method("play"):
					n.emitting = false
				tree.create_timer(1.2).timeout.connect(func():
					if is_instance_valid(n): n.queue_free()))
	return n
