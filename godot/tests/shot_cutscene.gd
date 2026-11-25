extends SceneTree
## 3D story cutscene screenshots: godot -s res://tests/shot_cutscene.gd (needs a window)
const Story := preload("res://scripts/story.gd")
var m
func snap(name: String, frames := 30) -> void:
	for i in frames: await process_frame
	root.get_texture().get_image().save_png("res://screenshots/%s.png" % name)
	print("saved ", name)
func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	root.get_node("Game").new_game()
	var shots := 0
	m.show_dialogue(Story.PROLOGUE, func(): pass)
	var cs = m.get_children().filter(func(c): return c.has_method("advance"))[0]
	await snap("cs_%02d" % shots, 45)
	# step through the prologue, snapping every few lines
	for k in 40:
		if not is_instance_valid(cs) or cs.done: break
		cs.next(); cs.next()
		if k % 4 == 0:
			shots += 1
			await snap("cs_%02d" % shots, 40)
		else:
			await process_frame
	print("cutscene ok")
	quit()
