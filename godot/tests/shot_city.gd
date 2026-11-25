extends SceneTree
## City block model in Godot: godot -s res://tests/shot_city.gd (needs a window)
func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	var w := Node3D.new()
	root.add_child(w)
	var city: Node3D = (load("res://assets/models/city_block.glb") as PackedScene).instantiate()
	w.add_child(city)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("6aa8ec")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c8d8f0")
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new(); we.environment = env; w.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0); sun.shadow_enabled = true; sun.light_energy = 1.3
	w.add_child(sun)
	var cam := Camera3D.new(); cam.fov = 60; w.add_child(cam)
	# Blender (x, y, z) -> Godot (x, z, -y)
	for shot in [["city_godot_street", Vector3(11.6, 1.7, 59.5), Vector3(3, 9, -30)],
			["city_godot_train", Vector3(16, 15, 38), Vector3(-2.1, 13, 8)]]:
		cam.look_at_from_position(shot[1], shot[2])
		for i in 20: await process_frame
		root.get_texture().get_image().save_png("res://screenshots/%s.png" % shot[0])
		print("saved ", shot[0])
	var meshes := city.find_children("*", "MeshInstance3D", true, false).size()
	print("city meshes: ", meshes)
	quit()
