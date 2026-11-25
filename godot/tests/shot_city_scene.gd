extends SceneTree
## City street cutscene location: godot -s res://tests/shot_city_scene.gd (needs a window)
var m
var fails := 0
func check(c: bool, msg: String) -> void:
	print(("ok   " if c else "FAIL ") + msg)
	if not c: fails += 1
func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var lines := [["@bg", "city", "ทางไปโรงเรียน"], ["@cast", "oli", "haru"], ["", "ช็อตกว้างบนทางเท้า"],
		["haru", "สาย"], ["oli", "ได้ๆ!"]]
	m.show_dialogue(lines, func(): pass)
	var cs = m.get_children().filter(func(c): return c.has_method("advance"))[-1]
	await create_timer(1.2).timeout
	check(cs.stage.set_root.get_node_or_null("city") != null, "city block loaded as the set")
	root.get_texture().get_image().save_png("res://screenshots/city_scene_wide.png")
	for k in 2:
		cs.next(); cs.next()
		await create_timer(1.2).timeout
		root.get_texture().get_image().save_png("res://screenshots/city_scene_%d.png" % k)
	print("city fails: ", fails)
	quit(1 if fails else 0)
