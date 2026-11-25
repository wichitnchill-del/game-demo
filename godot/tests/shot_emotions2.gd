extends SceneTree
## Haru + Leon emotion faces: godot -s res://tests/shot_emotions2.gd (needs a window)
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
	var lines := [["@bg", "rooftop", "ทดสอบสีหน้า"], ["@cast", "leon", "haru"],
		["leon", "ยิ้มมุมปาก", "smirk"], ["leon", "ตกใจ", "surprised"], ["haru", "น้ำตาไหล", "sad"], ["haru", "ร้องไห้", "cry"]]
	m.show_dialogue(lines, func(): pass)
	var cs = m.get_children().filter(func(c): return c.has_method("advance"))[-1]
	var want := [["left", "smirk"], ["left", "surprised"], ["right", "sad"], ["right", "cry"]]
	for k in want.size():
		await create_timer(1.0).timeout
		var a = cs.stage.actors[want[k][0]]["node"]
		check(a.emotion_now == want[k][1], "%s face = %s (got '%s')" % [a.id, want[k][1], a.emotion_now])
		check(cs.stage.close_up == (want[k][1] in ["surprised", "sad", "cry"]), "close-up only on strong emotions (%s)" % want[k][1])
		root.get_texture().get_image().save_png("res://screenshots/emo2_%d.png" % k)
		cs.next(); cs.next()
	print("emotion2 fails: ", fails)
	quit(1 if fails else 0)
