extends SceneTree
## Audit every story cutscene: one thumbnail per dialogue line, saved as
## screenshots/audit/<SCRIPT>_<nn>.png (godot -s res://tests/shot_all_cutscenes.gd, needs a window).
## Also prints lines where the camera shows nobody (speaker not on stage).
const Story := preload("res://scripts/story.gd")
var m

func all_scripts() -> Dictionary:
	var d := {"PROLOGUE": Story.PROLOGUE, "AFTER_FIRE": Story.AFTER_FIRE, "CLOVER_WARNING": Story.CLOVER_WARNING,
		"LEON_ASIDE": Story.LEON_ASIDE, "LEON_DEFEATED": Story.LEON_DEFEATED, "AFTER_WIN": Story.AFTER_WIN, "POST_CREDIT": Story.POST_CREDIT}
	for i in Story.BEFORE_WAVE.size():
		d["BEFORE_WAVE_%d" % i] = Story.BEFORE_WAVE[i]
	return d

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var scripts := all_scripts()
	var empty := 0
	for name in scripts:
		m.show_dialogue(scripts[name], func(): pass)
		var cs = m.get_children().filter(func(c): return c.has_method("advance"))[-1]
		var n := 0
		while is_instance_valid(cs) and not cs.done:
			await create_timer(0.75).timeout
			if not is_instance_valid(cs) or cs.done: break
			var who: String = str(cs.steps[cs.i][0]).trim_suffix("*")
			if cs.stage.actors.is_empty():
				empty += 1
				print("EMPTY %s_%02d  %s: %s" % [name, n, who, cs.steps[cs.i][1]])
			var img := root.get_texture().get_image()
			img.resize(320, 180)
			img.save_png("res://screenshots/audit/%s_%02d.png" % [name, n])
			n += 1
			cs.next(); cs.next()
		print("%s: %d lines" % [name, n])
	print("empty-stage lines: ", empty)
	quit()
