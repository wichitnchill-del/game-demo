extends SceneTree
## Climb / dust / death screenshots: godot -s res://tests/shot_anims.gd (needs a window)
var m
func snap(name: String, frames := 1) -> void:
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
	m.start_royale("mio")
	var r = m.royale
	r.think_t = 999.0
	var f = r.player
	for o in r.fighters:
		if o != f: o.process_mode = Node.PROCESS_MODE_DISABLED
	var room: Dictionary = r.rooms[0]
	var base: Vector3 = room["door_out"] + Vector3(6, 0.5, 4)
	# 1) sprint dust
	f.global_position = base
	for k in 40: await physics_frame
	r.cam_yaw = PI * 0.5
	for k in 50:
		f.move_dir = Vector3(-1, 0, 0)
		f.data["sprint"] = true
		await physics_frame
	await snap("anim1_sprint_dust")
	# 2) climb the building wall (walk into +Z face from outside, i.e. move -Z)
	f.data["sprint"] = false
	f.global_position = room["door_out"] + Vector3(-6, 0.5, 1.5)
	r.cam_yaw = 0.0
	for k in 20: await physics_frame
	for k in 70:
		f.move_dir = Vector3(0, 0, -1)
		await physics_frame
	await snap("anim2_climb")
	# 3) jump + land dust
	f.move_dir = Vector3.ZERO
	f.global_position = base
	for k in 60: await physics_frame
	f.jump()
	for k in 75: await physics_frame
	await snap("anim3_land_dust")
	# 4) death of an enemy right in front of us
	var e = r.fighters[5]
	e.process_mode = Node.PROCESS_MODE_INHERIT
	e.global_position = f.global_position + Vector3(0, 0.5, -2.5)
	for k in 30: await physics_frame
	e.data["hp"] = 0.0
	r._down(e, f)
	for k in 8: await physics_frame
	await snap("anim4_hit")
	for k in 4: r.do_attack(f); await physics_frame
	e.data["bleed"] = 0.0
	r._eliminate(e)
	for k in 22: await physics_frame
	await snap("anim5_death")
	quit()
