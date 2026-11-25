extends SceneTree
## Movement screenshots: godot -s res://tests/shot_move.gd (needs a window)
var m
func snap(name: String, frames := 1) -> void:
	for i in frames: await process_frame
	root.get_texture().get_image().save_png("res://screenshots/%s.png" % name)
	print("saved ", name)

func pose(id: String, shot: String, frames: int, hold: bool, dir: Vector3) -> void:
	m.start_royale(id)
	var r = m.royale
	r.autopilot = true
	r.think_t = 999.0
	var f = r.player
	for o in r.fighters:
		if o != f: o.process_mode = Node.PROCESS_MODE_DISABLED
	r._box(Vector3(8, 7, 2), Vector3(f.global_position.x, 3.5, f.global_position.z - 3), Color("c8b8a0"))
	for i in 100: await physics_frame
	for i in frames:
		f.move_dir = dir
		f.data["hold"] = 1.0 if hold else 0.0
		if i % 30 == 0 and hold: f.jump()
		await physics_frame
	await snap(shot)
	r._quit_match()
	await process_frame

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m.royale_seed = 7
	m.show_select()
	await snap("mv0_select", 30)
	await pose("ren", "mv1_ren_climb", 45, false, Vector3(0, 0, -1))
	await pose("leon", "mv2_leon_fly", 70, true, Vector3(0.3, 0, 0.3))
	await pose("oli", "mv3_oli_glide", 75, true, Vector3(1, 0, 0))
	quit()
