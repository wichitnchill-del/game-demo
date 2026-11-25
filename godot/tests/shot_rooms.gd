extends SceneTree
## Walk-in building screenshots: godot -s res://tests/shot_rooms.gd (needs a window)
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
	m.royale_seed = 5
	m.autopilot = true
	m.start_royale("oli")
	var r = m.royale
	r.think_t = 999.0
	var f = r.player
	for o in r.fighters:
		if o != f: o.process_mode = Node.PROCESS_MODE_DISABLED
	var room: Dictionary = r.rooms[0]
	f.global_position = room["door_out"] + Vector3(0, 0.5, 5)
	f.facing = Vector3(0, 0, -1)
	r.cam_yaw = 0.0
	for k in 60: await physics_frame
	await snap("room1_outside")
	f.global_position = Vector3(room["rect"].get_center().x - 3, 0.5, room["rect"].get_center().y + 1)
	for k in 60: await physics_frame
	await snap("room2_inside")
	quit()
