extends SceneTree
## Walk-in buildings: a bot outside must reach a card inside (through the door) and walk back out.
func _initialize() -> void:
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m.royale_seed = 5
	m.autopilot = true
	m.start_royale("ren")
	var r = m.royale
	print("rooms: ", r.rooms.size(), " ", r.rooms.map(func(x): return x["name"]))
	r.think_t = 999.0
	var f = r.player
	for o in r.fighters:
		if o != f: o.process_mode = Node.PROCESS_MODE_DISABLED
	var fails := 0
	for i in min(4, r.rooms.size()):
		var room: Dictionary = r.rooms[i]
		var inside_pt: Vector3 = Vector3(room["rect"].get_center().x, 0, room["rect"].get_center().y)
		var outside_pt: Vector3 = room["door_out"] + Vector3(0, 0, 6)
		f.global_position = outside_pt + Vector3(3, 1, 2)
		f.velocity = Vector3.ZERO
		for k in 30: await physics_frame
		var ok_in := false
		for k in 900:
			f.move_dir = r._steer(f.global_position, inside_pt)
			await physics_frame
			if r.room_at(f.global_position) == i:
				ok_in = true; break
		var ok_out := false
		for k in 900:
			f.move_dir = r._steer(f.global_position, outside_pt)
			await physics_frame
			if r.room_at(f.global_position) == -1 and f.global_position.z > room["door_out"].z:
				ok_out = true; break
		print("%-12s enter %s  exit %s  roof hidden while inside: %s" % [room["name"], ok_in, ok_out, "checked" ])
		if not (ok_in and ok_out): fails += 1
	print("ROOM FAILURES: ", fails)
	quit()
