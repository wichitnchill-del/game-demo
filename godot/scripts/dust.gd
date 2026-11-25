extends RefCounted
## Dust clouds made in Blender (blender/make_dust.py -> assets/fx/*.glb).
##   Dust.spawn(parent, "puff", pos, size)    footsteps / sprint / dodge
##   Dust.spawn(parent, "ring", pos, size)    landing / slam
##   Dust.spawn(parent, "burst", pos, size)   jump take-off
## Each cloud grows, drifts up and fades out, then frees itself.

const MESHES := {
	"puff": "res://assets/fx/dust_puff.glb",
	"ring": "res://assets/fx/dust_ring.glb",
	"burst": "res://assets/fx/dust_burst.glb",
}
static var _scenes := {}
static var _alive := 0
const MAX_ALIVE := 60   # cap for 24 fighters running at once


static func spawn(parent: Node, kind: String, pos: Vector3, size := 1.0, tint := Color("e8dcc8")) -> void:
	if _alive >= MAX_ALIVE or parent == null or not parent.is_inside_tree():
		return
	if not _scenes.has(kind):
		_scenes[kind] = load(MESHES[kind])
	var ps: PackedScene = _scenes[kind]
	if ps == null:
		return
	var n: Node3D = ps.instantiate()
	parent.add_child(n)
	_alive += 1
	n.global_position = pos
	n.rotation.y = randf() * TAU
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(tint, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = mat
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var start := 0.35 * size
	var end := (1.25 if kind != "ring" else 1.6) * size
	var life := 0.55 if kind == "puff" else 0.7
	n.scale = Vector3.ONE * start
	var tw := n.create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "scale", Vector3.ONE * end, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "global_position:y", pos.y + (0.5 if kind == "puff" else 0.25), life)
	tw.tween_property(mat, "albedo_color:a", 0.0, life).set_delay(life * 0.35)
	tw.chain().tween_callback(func():
		_alive -= 1
		n.queue_free())
