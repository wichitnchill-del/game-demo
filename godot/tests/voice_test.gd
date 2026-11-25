extends SceneTree
## Every spoken cutscene line has a voice file that loads as audio.
const Story := preload("res://scripts/story.gd")
const Cutscene := preload("res://scripts/cutscene.gd")
func _initialize() -> void:
	var all := [Story.PROLOGUE, Story.AFTER_FIRE, Story.CLOVER_WARNING, Story.LEON_ASIDE, Story.LEON_DEFEATED, Story.AFTER_WIN, Story.POST_CREDIT] + Story.BEFORE_WAVE
	var total := 0
	var missing := []
	for script in all:
		for st in script:
			var who: String = st[0]
			if who.begins_with("@"): continue
			var text: String = st[1]
			if text.begins_with("(") and text.ends_with(")"): continue   # stage direction, not voiced
			total += 1
			var p := Cutscene.voice_path(who, text)
			if not ResourceLoader.exists(p) or not (load(p) is AudioStream):
				missing.append("%s: %s" % [who, text.left(30)])
	print("voiced lines: %d/%d" % [total - missing.size(), total])
	for m in missing: print("  MISSING ", m)
	print("VOICE FAILURES: ", missing.size())
	quit()
