extends SceneTree
## Lineup of all character models: godot -s res://tests/shot_models.gd (needs a window)
const HM := preload("res://scripts/human_model.gd")
func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var w := Node3D.new(); root.add_child(w)
	var cam := Camera3D.new(); w.add_child(cam); cam.position = Vector3(0, 1.3, 7.2); cam.current = true; cam.fov = 50
	var l := DirectionalLight3D.new(); w.add_child(l); l.rotation_degrees = Vector3(-35, 25, 0)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color("c8d0ff"); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color.WHITE; e.ambient_light_energy = 0.55; env.environment = e; w.add_child(env)
	await process_frame
	var ids := ["oli", "haru", "ren", "mio", "setsu", "leon", "lumi", "null", "kuroba", "fumi"]
	var mode := OS.get_environment("POSE") if OS.get_environment("POSE") != "" else "idle"
	if OS.get_environment("CLOSE") != "":
		cam.position = Vector3(-2.0, 1.55, 2.2); cam.fov = 40
	for i in ids.size():
		var m = HM.make(ids[i])
		w.add_child(m)
		m.position = Vector3(-4.5 + i * 1.0, 0, 0)
		m.state = mode
		if OS.get_environment("FLIP") != "": m.rotation.y = PI
	for k in 50: await process_frame
	root.get_texture().get_image().save_png("res://screenshots/models_%s.png" % mode)
	print("saved ", mode)
	quit()
