extends SceneTree
## Headless tests: godot --headless -s res://tests/autoplay.gd
## 1) validates & plays every cutscene  2) plays N full games where the
## arena autopilot fights in real time, checking invariants every frame.

const Story := preload("res://scripts/story.gd")
const Cutscene := preload("res://scripts/cutscene.gd")
var m
var game
var errors := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		errors += 1
		if errors < 30: print("FAIL: ", msg)

func invariants(ctx: String) -> void:
	for p in game.party:
		check(p["hp"] >= 0 and p["hp"] <= p["maxhp"], "%s hp %s %d/%d" % [ctx, p["name"], p["hp"], p["maxhp"]])
		check(p["breath"] >= 0 and p["breath"] <= 100, "%s breath %s %s" % [ctx, p["name"], p["breath"]])
		check(p["seal"] >= 0 and p["seal"] <= 2, ctx + " seal")
	check(game.clover >= 0 and game.clover <= 3, "%s clover %d" % [ctx, game.clover])
	for k in game.bonds:
		check(game.bonds[k] >= 0 and game.bonds[k] <= game.BOND_MAX, ctx + " bond " + k)
	if m.arena:
		for e in m.arena.enemies:
			check(e.data["hp"] >= 0 and e.data["hp"] <= e.data["maxhp"], ctx + " enemy hp")
			check(abs(e.global_position.x) < 17 and abs(e.global_position.z) < 17, ctx + " enemy left arena")
		var h = m.arena.hero()
		check(abs(h.global_position.x) < 17 and abs(h.global_position.z) < 17, ctx + " hero left arena")
		check(h.visible, ctx + " active hero hidden")

func all_scripts() -> Dictionary:
	var d := {"PROLOGUE": Story.PROLOGUE, "AFTER_FIRE": Story.AFTER_FIRE, "CLOVER_WARNING": Story.CLOVER_WARNING,
		"LEON_ASIDE": Story.LEON_ASIDE, "LEON_DEFEATED": Story.LEON_DEFEATED, "AFTER_WIN": Story.AFTER_WIN, "POST_CREDIT": Story.POST_CREDIT}
	for i in Story.BEFORE_WAVE.size():
		d["BEFORE_WAVE_%d" % i] = Story.BEFORE_WAVE[i]
	return d

func _initialize() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	game = root.get_node("Game")

	var scripts := all_scripts()
	check(Story.BEFORE_WAVE.size() == game.WAVES.size(), "BEFORE_WAVE count")
	for name in scripts:
		for s in scripts[name]:
			var k: String = s[0]
			if k == "@bg": check(Cutscene.BG.has(s[1]), "%s bg %s" % [name, s[1]])
			elif k == "@cast":
				for id in s.slice(1): check(id == "" or m.Sheets.has(id), "%s sheet %s" % [name, id])
			elif k == "@group":
				# group shots use the 3D stage: every member needs a 3D look or a temp model
				for id in s.slice(1): check(Cutscene.NAMES.has(id) and (preload("res://scripts/human_model.gd").has_look(id) or ResourceLoader.exists("res://assets/models/%s.glb" % id)), "%s group %s" % [name, id])
			elif k != "@flash": check(Cutscene.NAMES.has(k.trim_suffix("*")) or k == "", "%s speaker %s" % [name, k])
		var ended := [false]
		m.show_dialogue(scripts[name], func(): ended[0] = true)
		var cs = m.get_children().filter(func(c): return c is Cutscene)[-1]
		var n := 0
		while not ended[0] and n < 400:
			cs.next(); cs.next(); n += 1
			await process_frame
		check(ended[0], "cutscene %s did not finish" % name)
	print("cutscenes ok: ", scripts.size())

	Engine.time_scale = 4.0
	m.autopilot = true
	var results := {"win": 0, "aside": 0, "lose": 0, "timeout": 0}
	var ids := ["ren", "mio", "haru", "setsu", "leon"]
	var games := int(OS.get_environment("GAMES")) if OS.get_environment("GAMES") != "" else 6
	var battle_times := []
	for g in games:
		game.new_game()
		m.clover_warned = false
		var outcome := ""
		while outcome == "":
			m.show_school()
			for k in 3:
				m.hang_out(ids.pick_random()) if randf() < 0.85 else m.rest_room()
			var w: int = game.wave
			if w == 2 and game.bonds["leon"] >= game.LEON_BOND_NEEDED:
				m.start_battle(); outcome = "aside"; break
			m.start_battle()
			var t0 := Time.get_ticks_msec()
			var frames := 0
			while m.arena != null and frames < 6000:
				await physics_frame
				frames += 1
				if frames % 10 == 0: invariants("w%d" % w)
			battle_times.append(frames / 60.0 * Engine.time_scale)
			if frames >= 6000:
				var a = m.arena
				print("TIMEOUT wave ", w, " hero ", a.hero().data["name"], " pos ", a.hero().global_position, " alive ", a.hero().alive())
				for e in a.enemies:
					print("   enemy ", e.data["name"], " hp ", e.data["hp"], " pos ", e.global_position, " floor ", e.is_on_floor(), " windup ", e.data["windup"])
				outcome = "timeout"; m.arena.queue_free(); m.arena = null
			elif game.wave >= game.WAVES.size(): outcome = "win"
			elif game.wave == w: outcome = "lose"
			await process_frame
		results[outcome] += 1
		print("game ", g, ": ", outcome, " lv ", game.lv, " clover ", game.clover)
	print("RESULTS ", results, "  avg battle (game-seconds): ", snapped(battle_times.reduce(func(a, b): return a + b, 0.0) / max(1, battle_times.size()), 0.1))
	print("BATTLES [wave, game-seconds, won, team hp%]: ", m.battle_log)
	print("FAILURES: ", errors)
	print("AUTOPLAY DONE")
	quit()
