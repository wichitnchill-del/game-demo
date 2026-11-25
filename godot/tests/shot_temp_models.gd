extends SceneTree
## Temporary (Blender) character models in the cutscene stage:
## godot -s res://tests/shot_temp_models.gd -- piang clover   (needs a window)
var m
func snap(name: String, frames := 40) -> void:
	for i in frames: await process_frame
	root.get_texture().get_image().save_png("res://screenshots/%s.png" % name)
	print("saved ", name)
func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var ids: Array = OS.get_cmdline_user_args()
	if ids.is_empty(): ids = ["piang"]
	for id in ids:
		var lines := [["@bg", "kitchen", "ทดสอบโมเดล: " + id], ["@cast", "oli", id], ["", "ช็อตกว้าง"], [id, "ช็อตคนพูด"]]
		m.show_dialogue(lines, func(): pass)
		var cs = m.get_children().filter(func(c): return c.has_method("advance"))[-1]
		await snap("tm_%s_wide" % id, 50)
		cs.next(); cs.next()
		await snap("tm_%s_talk" % id, 60)
		cs.skip_all()
		await process_frame
	quit()
