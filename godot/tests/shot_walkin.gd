extends SceneTree
## Walk-in test: godot -s res://tests/shot_walkin.gd (needs a window)
## Piang (temp model) and Haru (HumanModel) arrive mid-scene and must end up in place.
var m
var fails := 0
func snap(name: String, frames := 1) -> void:
	for i in frames: await process_frame
	root.get_texture().get_image().save_png("res://screenshots/%s.png" % name)
func check(c: bool, msg: String) -> void:
	print(("ok   " if c else "FAIL ") + msg)
	if not c: fails += 1
func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var lines := [["@bg", "kitchen", "ทดสอบเดินเข้าฉาก"], ["@cast", "oli", ""], ["", "โอลี่อยู่คนเดียว"],
		["piang", "ป้ามาแล้ว"], ["@cast", "oli", "haru"], ["haru", "ฉันก็มา"]]
	m.show_dialogue(lines, func(): pass)
	var cs = m.get_children().filter(func(c): return c.has_method("advance"))[-1]
	var st = cs.stage
	await snap("walk_0", 30)
	check(st.has_actor("oli") and not st.is_busy(), "oli placed instantly at scene start")
	cs.next(); cs.next()          # piang speaks -> walks in
	await snap("walk_1_mid", 20)
	check(st.has_actor("piang") and st.is_busy(), "piang walking in")
	for i in 50:   # up to 5 real seconds
		await create_timer(0.1).timeout
		if not st.is_busy(): break
	await snap("walk_2_arrived", 5)
	check(not st.is_busy(), "piang arrived")
	check(st.steps_played >= 3, "footsteps played while walking (%d)" % st.steps_played)
	cs.next(); cs.next()          # haru replaces piang on the right, walks in
	await snap("walk_3_haru_mid", 25)
	check(st.has_actor("haru") and st.is_busy(), "haru walking in (HumanModel walk anim)")
	check(st.leaving.size() == 1, "piang walks out instead of vanishing")
	for i in 50:   # up to 5 real seconds
		await create_timer(0.1).timeout
		if not st.is_busy(): break
	check(not st.is_busy(), "haru arrived")
	for i in 30:
		if st.leaving.is_empty(): break
		await create_timer(0.1).timeout
	check(st.leaving.is_empty(), "piang gone after leaving")
	await snap("walk_4_haru_talk", 20)
	print("walkin fails: ", fails)
	quit(1 if fails else 0)
