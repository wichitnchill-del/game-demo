extends SceneTree
## Battle Royale screenshots: godot -s res://tests/shot_royale.gd (needs a window)
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
	await snap("br1_title")
	m.show_select()
	await snap("br2_select")
	m.autopilot = true
	m.royale_seed = 1003
	m.start_royale("mio")
	await snap("br3_drop", 20)
	Engine.time_scale = 3.0
	# wait until our team is in a fight
	var r = m.royale
	for i in 4000:
		await process_frame
		if m.royale == null: break
		var near = r._nearest_enemy(r.player, 6.0, true)
		if near and r.time > 30: break
	Engine.time_scale = 1.0
	await snap("br4_fight", 25)
	r.player.data["ult"] = 100.0
	r.do_ultimate(r.player)
	await snap("br5_ultimate", 8)
	Engine.time_scale = 4.0
	while m.royale != null: await process_frame
	Engine.time_scale = 1.0
	await snap("br6_result")
	quit()
