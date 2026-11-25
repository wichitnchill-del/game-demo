extends SceneTree
## Headless Battle Royale test: godot --headless -s res://tests/royale_test.gd
## Runs N full 24-fighter matches with the player on autopilot and checks
## invariants; reports placement, match length and how matches end.

var m
var errors := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		errors += 1
		if errors < 30: print("FAIL: ", msg)

func _initialize() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m.autopilot = true
	Engine.time_scale = 4.0
	var n := int(OS.get_environment("MATCHES")) if OS.get_environment("MATCHES") != "" else 3
	var roster: Array = m.Royale.ROSTER
	for i in n:
		m.royale_seed = 1000 + i
		var pick: String = roster[i % roster.size()]
		m.start_royale(pick)
		var r = m.royale
		var frames := 0
		var max_frames := 60 * 60 * 8   # 8 game-minutes at time_scale 4 = 2 real minutes
		while m.royale != null and frames < max_frames:
			await physics_frame
			frames += 1
			if frames % 30 == 0 and m.royale:
				var standing := 0
				for f in r.fighters:
					var d: Dictionary = f.data
					check(d["hp"] >= 0 and d["hp"] <= d["maxhp"] + 0.01, "hp range %s %s" % [d["name"], d["hp"]])
					check(d["lv"] >= 1 and d["lv"] <= 5, "lv")
					check(d["breath"] >= 0 and d["breath"] <= 100, "breath")
					check(not (d["out"] and d["downed"]), "out and downed")
					if not d["out"]:
						check(abs(f.global_position.x) < 92 and abs(f.global_position.z) < 92, "left map %s %s" % [d["name"], f.global_position])
						check(f.global_position.y > -2, "fell %s %s" % [d["name"], f.global_position])
					if not d["out"] and not d["downed"]: standing += 1
				for t in r.teams_left():
					check(r.members(t).any(func(f): return not f.data["out"]), "team listed but empty")
				check(r.zone_radius >= 0, "zone radius")
		if m.royale != null:
			print("TIMEOUT match %d: teams left %s, zone phase %d r %.1f, time %.0f" % [i, m.royale.teams_left(), m.royale.zone_phase, m.royale.zone_radius, m.royale.time])
			for f in m.royale.fighters:
				if not f.data["out"]:
					print("   ", f.data["name"], " team ", f.data["team"], " hp ", int(f.data["hp"]), " downed ", f.data["downed"], " pos ", f.global_position.round())
			m.royale._end()
			while m.royale != null: await process_frame
		var res: Array = m.last_result
		print("match %d as %s: place %d/8, team kills %d, damage %d, time %ds" % [i, pick, res[0], res[1]["kills"], res[1]["damage"], int(res[1]["time"])])
		await process_frame
	print("FAILURES: ", errors)
	print("ROYALE DONE")
	quit()
