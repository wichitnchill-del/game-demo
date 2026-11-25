extends SceneTree
## Render the same scenes and time frames:  godot -s res://tests/look_compare.gd -- <tag> [--plain-look]
## Saves screenshots/look_<tag>_<scene>.png and prints average ms per frame.
var m
func measure(name: String, tag: String) -> void:
	for i in 30: await process_frame          # settle
	var t0 := Time.get_ticks_usec()
	var n := 120
	for i in n: await process_frame
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / n
	root.get_texture().get_image().save_png("res://screenshots/look_%s_%s.png" % [tag, name])
	print("FRAME %s %s %.2f ms" % [tag, name, ms])

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.size = Vector2i(1280, 720)
	var tag: String = OS.get_cmdline_user_args()[0]
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	# 1) cutscene on the city street
	m.show_dialogue([["@bg", "city", ""], ["@cast", "oli", "haru"], ["", "..."]], func(): pass)
	await create_timer(1.0).timeout
	await measure("city", tag)
	var cs = m.get_children().filter(func(c): return c.has_method("advance"))[-1]
	cs.skip_all()
	await process_frame
	# 2) cutscene indoors (kitchen) with a close-up
	m.show_dialogue([["@bg", "kitchen", ""], ["@cast", "oli", "piang"], ["oli", "...", "sad"]], func(): pass)
	await create_timer(1.2).timeout
	await measure("kitchen", tag)
	cs = m.get_children().filter(func(c): return c.has_method("advance"))[-1]
	cs.skip_all()
	await process_frame
	# 3) story battle arena
	root.get_node("Game").new_game()
	m.autopilot = true
	m.start_battle()
	await create_timer(1.5).timeout
	await measure("arena", tag)
	# 4) battle royale
	m.royale_seed = 1003
	m.start_royale("mio")
	await create_timer(2.0).timeout
	await measure("royale", tag)
	quit()
