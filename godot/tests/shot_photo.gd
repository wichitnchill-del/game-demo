extends SceneTree
## Family photo scene: godot -s res://tests/shot_photo.gd (needs a window)
## After the flash Oli walks in and watches the family, who stay in the background.
const Story := preload("res://scripts/story.gd")
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
	m.show_dialogue(Story.PROLOGUE, func(): pass)
	var cs = m.get_children().filter(func(c): return c.has_method("advance"))[-1]
	var st = cs.stage
	await create_timer(0.8).timeout
	await snap("photo_1_family")
	var gap0: float = absf(st.actors["g0"]["node"].position.x)
	# advance to Oli's thought after the flash
	for k in 8:
		if cs.steps[cs.i][0] == "oli*": break
		cs.next(); cs.next()
		await create_timer(0.15).timeout
	check(cs.steps[cs.i][0] == "oli*", "reached Oli's thought")
	check(st.shutter_played == 1, "shutter clicked once at the photo flash")
	check(st.has_actor("victor") and st.has_actor("lily"), "family still in the shot")
	check(absf(st.actors["g0"]["node"].position.x) < gap0 - 0.2, "family squeezed together for the photo")
	check(st.has_actor("oli"), "Oli on stage")
	for i in 40:
		if not st.is_busy(): break
		await create_timer(0.1).timeout
	await create_timer(1.0).timeout
	await snap("photo_2_oli_watches")
	# next location clears the family
	for k in 4:
		cs.next(); cs.next()
		await create_timer(0.1).timeout
	check(not st.has_actor("victor"), "family cleared at the kitchen scene")
	print("photo fails: ", fails)
	quit(1 if fails else 0)
