extends SceneTree
## Touch overlay screenshots: godot -s res://tests/shot_touch.gd -- --touch (needs a window)
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
	m.royale_seed = 1003
	m.start_royale("mio")
	await snap("touch_royale", 90)
	m.royale._quit_match()
	for i in 10: await process_frame
	root.get_node("Game").new_game()
	m.start_battle()
	await snap("touch_story", 60)
	quit()
