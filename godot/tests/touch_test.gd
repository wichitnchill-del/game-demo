extends SceneTree
## Touch controls test: godot --headless -s res://tests/touch_test.gd -- --touch
## Sends fake finger events and checks the game reacts.
var m
var errors := 0
var touch

func check(cond: bool, msg: String) -> void:
	print(("ok   " if cond else "FAIL ") + msg)
	if not cond: errors += 1

func finger(i: int, pos: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = i; e.position = root.get_final_transform() * pos; e.pressed = down
	Input.parse_input_event(e)

func drag(i: int, pos: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = i; e.position = root.get_final_transform() * pos; e.relative = rel
	Input.parse_input_event(e)

func frames(n := 3) -> void:
	for k in n:
		await process_frame
		await physics_frame

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	touch = root.get_node("Touch")
	await process_frame
	check(touch.enabled, "touch mode is on (--touch)")
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await frames()
	check(not touch.visible, "overlay hidden on title screen")

	# ---- battle royale ----
	m.royale_seed = 1003
	m.start_royale("mio")
	await frames(5)
	var r = m.royale
	check(touch.visible, "overlay shown in battle royale")
	check(Input.mouse_mode != Input.MOUSE_MODE_CAPTURED, "mouse not captured on touch")
	# joystick: press left side, drag right to the edge
	finger(0, Vector2(200, 560), true); await frames()
	drag(0, Vector2(300, 560), Vector2(100, 0)); await frames()
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	check(v.x > 0.9, "joystick right -> move_right (%.2f)" % v.x)
	check(Input.is_action_pressed("sprint"), "stick at edge -> sprint")
	# camera drag on the right while still holding the stick (multi-touch)
	var yaw0: float = r.cam_yaw
	finger(1, Vector2(800, 300), true); await frames()
	drag(1, Vector2(900, 300), Vector2(100, 0)); await frames(2)
	check(absf(r.cam_yaw - yaw0) > 0.3, "right-side drag turns camera (%.2f)" % (r.cam_yaw - yaw0))
	finger(1, Vector2(900, 300), false)
	# attack button tap
	var atk_seen := false
	finger(2, Vector2(1188, 624), true)
	for k in 3:
		await physics_frame
		if Input.is_action_pressed("attack"): atk_seen = true
	finger(2, Vector2(1188, 624), false)
	check(atk_seen, "ATK button presses attack")
	await frames(3)
	check(not Input.is_action_pressed("attack"), "attack released after tap")
	# jump is a hold button
	finger(3, Vector2(1210, 474), true); await frames()
	check(Input.is_action_pressed("jump"), "JUMP held while finger down")
	finger(3, Vector2(1210, 474), false); await frames()
	check(not Input.is_action_pressed("jump"), "JUMP released on lift")
	finger(0, Vector2(300, 560), false); await frames()
	v = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	check(v.length() < 0.01, "stick released -> stop")
	# pause button pauses and overlay hides; menus still clickable
	finger(4, Vector2(864, 33), true); await frames(); finger(4, Vector2(864, 33), false)
	await frames(3)
	check(r.pause_layer != null, "II button pauses")
	check(not touch.visible, "overlay hidden while paused")
	r.toggle_pause(); await frames()
	r._quit_match()
	await frames(10)
	check(m.royale == null, "left royale")
	check(not touch.visible, "overlay hidden after match")

	# ---- story arena ----
	m.autopilot = false
	root.get_node("Game").new_game()
	m.start_battle()
	await frames(5)
	if m.arena:
		check(touch.visible, "overlay shown in story arena")
		var a = m.arena
		await frames(70)  # hero-switch cooldown after the battle starts
		var act0: int = a.active
		finger(0, Vector2(1100, 400), true); await frames(); finger(0, Vector2(1100, 400), false)
		await frames(40)
		check(a.active != act0, "▶ button switches hero (%d -> %d)" % [act0, a.active])
	else:
		print("skip story arena (no start_battle)")
	print("touch_test errors: ", errors)
	quit(1 if errors > 0 else 0)
