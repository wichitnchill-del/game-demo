extends SceneTree
## Each VFX next to a 1.8 m character, to calibrate scale: godot -s res://tests/shot_vfx.gd
const HM := preload("res://scripts/human_model.gd")
const Vfx := preload("res://scripts/vfx.gd")
func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var w := Node3D.new(); root.add_child(w)
	var cam := Camera3D.new(); w.add_child(cam); cam.position = Vector3(0, 3.0, 9.0); cam.current = true; cam.fov = 60
	cam.look_at(Vector3(0, 1, 0))
	var l := DirectionalLight3D.new(); w.add_child(l); l.rotation_degrees = Vector3(-35, 25, 0)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color("6a7090"); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color.WHITE; e.ambient_light_energy = 0.5; env.environment = e; w.add_child(env)
	await process_frame
	var kinds := ["swing", "slash", "claw", "charge", "shield", "dark_area", "dark_ball"]
	for i in kinds.size():
		var x := -6.0 + i * 2.0
		var m = HM.make("ren"); w.add_child(m); m.position = Vector3(x, 0, 0)
		var lab := Label3D.new(); lab.text = kinds[i]; lab.position = Vector3(x, -0.3, 0.5); lab.font_size = 48; w.add_child(lab)
		Vfx.spawn(w, kinds[i], Vector3(x, 1.0, 0.6), Vector3(0, 0, 1), Color("ff6a2a"), 5.0, 1.0)
	for k in int(OS.get_environment("FRAMES") if OS.get_environment("FRAMES") != "" else "12"): await process_frame
	root.get_texture().get_image().save_png("res://screenshots/vfx_scale.png")
	print("saved")
	quit()
