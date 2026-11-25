extends SceneTree
## Clover's first appearance: godot -s res://tests/shot_clover.gd (needs a window)
var m
var fails := 0
func snap(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png("res://screenshots/%s.png" % name)
func check(c: bool, msg: String) -> void:
	print(("ok   " if c else "FAIL ") + msg)
	if not c: fails += 1
func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var lines := [["@bg", "kitchen", "ครัว · ค่ำ"], ["@cast", "oli", ""], ["oli", "ของป้าเหรอครับ"],
		["@flash", "7dffa0"], ["clover", "…ในที่สุดก็มีคนเลือกนาย"], ["oli", "เข็มกลัด… พูดได้?!"]]
	m.show_dialogue(lines, func(): pass)
	var cs = m.get_children().filter(func(c): return c.has_method("advance"))[-1]
	var st = cs.stage
	await create_timer(0.8).timeout
	cs.next(); cs.next()
	await create_timer(0.25).timeout
	await snap("clover_1_burst")
	check(st.has_actor("clover"), "clover on stage")
	var node = null
	for k in st.actors: if st.actors[k]["id"] == "clover": node = st.actors[k]["node"]
	check(node != null and not node.has_meta("walk_to"), "clover does not walk in")
	await create_timer(1.4).timeout
	await snap("clover_2_settled")
	check(node.scale.is_equal_approx(Vector3.ONE * 0.5), "clover grown to shoulder size (0.5)")
	check(absf(node.position.x - (-0.65)) < 0.01 and node.position.y > 0.5, "clover hovers by Oli's shoulder (%s)" % node.position)
	cs.next(); cs.next()
	await create_timer(1.2).timeout
	await snap("clover_3_oli")
	print("clover fails: ", fails)
	quit(1 if fails else 0)
