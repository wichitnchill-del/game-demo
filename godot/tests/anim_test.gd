extends SceneTree
## Every animation state must resolve all its tracks on the model (no missing paths).
const HM := preload("res://scripts/human_model.gd")
func _initialize() -> void:
	var fails := 0
	for id in ["oli", "haru"]:
		var m = HM.make(id)
		root.add_child(m)
		await process_frame
		for st in HM.CLIPS:
			if not m.anim.has_animation(st):
				print("MISSING clip ", id, " ", st); fails += 1; continue
			var a: Animation = m.anim.get_animation(st)
			var bad := 0
			for t in a.get_track_count():
				var np := a.track_get_path(t)
				var node = m.model.get_node_or_null(NodePath(str(np).split(":")[0]))
				if node == null: bad += 1
			if bad > 0 or a.get_track_count() == 0:
				print("BAD ", id, " ", st, " tracks ", a.get_track_count(), " unresolved ", bad); fails += 1
		print(id, " clips ok: ", m.anim.get_animation_list().size())
	for p in ["res://assets/BinbunVFX_Vol2/BattleFX/effects/shield/vfx_blank_shield_01.tscn", "res://assets/BinbunVFX_Vol2/DarkMagicFX/effects/area/vfx_evil_area_01.tscn", "res://assets/BinbunVFX_Vol2/BattleFX/effects/slash/vfx_blank_slash.tscn"]:
		var n = load(p).instantiate()
		var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
		print(p.get_file(), " anims ", ap.get_animation_list())
		if ap.get_animation_list().size() < 2: fails += 1
		n.free()
	print("ANIM FAILURES: ", fails)
	quit()
