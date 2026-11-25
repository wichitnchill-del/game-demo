extends SceneTree
## Renders sample screenshots: godot -s res://tests/shot.gd  (needs a window)
const Story := preload("res://scripts/story.gd")
const Cutscene := preload("res://scripts/cutscene.gd")
var m

func snap(name: String, frames := 40) -> void:
	for i in frames: await process_frame
	root.get_texture().get_image().save_png("res://screenshots/%s.png" % name)
	print("saved ", name)

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	var game = root.get_node("Game")
	await snap("1_title")
	game.new_game()
	m.show_dialogue(Story.BEFORE_WAVE[0].slice(7), func(): pass)
	var cs = m.get_children().filter(func(c): return c is Cutscene)[-1]
	for k in 15: cs.next()
	await snap("2_cutscene")
	cs.skip_all()
	m.show_school(); m.hang_out("haru")
	await snap("3_school")
	m.autopilot = true
	m.start_battle()
	await snap("4_arena_wave1", 150)
	m.arena.queue_free(); m.arena = null
	game.wave = 2
	m.start_battle()
	await snap("5_arena_leon", 200)
	m.arena.switch_hero(1)
	m.arena.power()
	await snap("6_arena_power", 20)
	quit()
