extends SceneTree
## Checks each character's movement kit in the royale map:
## climbers get onto a roof, flyers/jumpers gain height, Mio's slam fires.
func _initialize() -> void:
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m.royale_seed = 7
	var fails := 0
	for id in m.Royale.ROSTER:
		m.start_royale(id)
		var r = m.royale
		r.autopilot = true
		var f = r.player
		# freeze everyone else so nothing interferes
		for o in r.fighters:
			if o != f: o.process_mode = Node.PROCESS_MODE_DISABLED
		r.think_t = 999.0
		# a test wall right next to the player
		var base: Vector3 = Vector3(f.global_position.x, 0, f.global_position.z)
		r._box(Vector3(6, 6, 1), base + Vector3(0, 3, -3), Color.RED)
		f.global_position = base + Vector3(0, 0.5, 0)
		for i in 90: await physics_frame   # land
		var start_y: float = f.global_position.y
		var max_y := start_y
		var landed_slam := [false]
		var orig: Callable = f.on_landing
		f.on_landing = func(ff, imp): landed_slam[0] = true
		# 1) walk into the wall while holding jump, pressing jump repeatedly
		for i in 240:
			f.move_dir = Vector3(0, 0, -1)
			f.jump_held = true
			f.data["hold"] = 1.0
			if i % 25 == 0: f.jump()
			await physics_frame
			max_y = max(max_y, f.global_position.y)
		var mobv: Dictionary = f.mob()
		var gained: float = max_y - start_y
		var ok := true
		var expect := ""
		if mobv.has("climb"):
			expect = "climbs onto 6m wall"; ok = f.global_position.y > 5.5 or max_y > 5.5
		elif mobv.has("fly"):
			expect = "flies above 6m"; ok = max_y > 6.0
		elif mobv.get("slam", false):
			expect = "high jump + slam"; ok = gained > 3.5 and landed_slam[0]
		else:
			expect = "%d jumps" % mobv.get("jumps", 1); ok = gained > 1.5
		print("%-8s %-22s max height %.1f  %s" % [id, expect, gained, "OK" if ok else "FAIL"])
		if not ok: fails += 1
		r._quit_match()
		await process_frame
		await process_frame
	print("MOBILITY FAILURES: ", fails)
	quit()
