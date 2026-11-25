extends SceneTree
## Emotion faces: godot -s res://tests/shot_emotions.gd (needs a window)
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
	var lines := [["@bg", "kitchen", "ทดสอบสีหน้า"], ["@cast", "oli", "piang"],
		["oli", "ยิ้ม"], ["oli", "เฉยๆ", "neutral"], ["oli", "เศร้า", "sad"], ["oli", "โกรธ", "angry"], ["oli", "ไม่มีหน้านี้", "confused"]]
	m.show_dialogue(lines, func(): pass)
	var cs = m.get_children().filter(func(c): return c.has_method("advance"))[-1]
	var oli = cs.stage.actors["left"]["node"]
	var want := ["", "neutral", "sad", "angry", ""]
	for k in want.size():
		await create_timer(1.0).timeout
		check(oli.emotion_now == want[k], "line %d face = '%s' (got '%s')" % [k, want[k], oli.emotion_now])
		root.get_texture().get_image().save_png("res://screenshots/emo_%d.png" % k)
		cs.next(); cs.next()
	print("emotion fails: ", fails)
	quit(1 if fails else 0)
