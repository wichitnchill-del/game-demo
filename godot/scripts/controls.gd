extends RefCounted
## Key bindings (standard PC action-game layout, adapted to Core Blaker).
##
## Battle Royale:
##   Mouse move = camera · LMB = attack · RMB / Q = power · Wheel = zoom
##   WASD = move · Shift (hold) = sprint · Ctrl / C = dodge-slide · Space = jump / fly / glide
##   R = ultimate · E (hold) = revive · Tab (hold) = status · M = map · T / Enter = call team · Esc = pause
## Story mode: same, plus Q / E or 1-5 switch hero (no power on Q there).
## Gamepad: L-stick move · R-stick camera · A jump · X attack · Y power · B dodge
##          RB ultimate · LB revive · L3 sprint · Back map · Start pause

const ROYALE := {
	"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE], "sprint": [KEY_SHIFT], "dodge": [KEY_C, KEY_CTRL],
	"attack": [KEY_J, "LMB"], "power": [KEY_Q, KEY_K, "RMB"], "ultimate": [KEY_R],
	"interact": [KEY_E, KEY_F], "status": [KEY_TAB], "map": [KEY_M],
	"call_team": [KEY_T, KEY_ENTER], "pause": [KEY_ESCAPE, KEY_P],
	"zoom_in": ["WHEEL_UP"], "zoom_out": ["WHEEL_DOWN"],
	"cam_left": [], "cam_right": [],
}
const STORY := {
	"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE], "attack": [KEY_J, "LMB"], "power": [KEY_K, "RMB"],
	"dodge": [KEY_C, KEY_CTRL, KEY_SHIFT, KEY_L], "switch_next": [KEY_E], "switch_prev": [KEY_Q],
}
const PAD := {
	"jump": JOY_BUTTON_A, "attack": JOY_BUTTON_X, "power": JOY_BUTTON_Y, "dodge": JOY_BUTTON_B,
	"ultimate": JOY_BUTTON_RIGHT_SHOULDER, "interact": JOY_BUTTON_LEFT_SHOULDER,
	"pause": JOY_BUTTON_START, "map": JOY_BUTTON_BACK, "sprint": JOY_BUTTON_LEFT_STICK,
	"switch_next": JOY_BUTTON_RIGHT_SHOULDER, "switch_prev": JOY_BUTTON_LEFT_SHOULDER,
}
const PAD_AXES := [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0],
	["move_up", JOY_AXIS_LEFT_Y, -1.0], ["move_down", JOY_AXIS_LEFT_Y, 1.0],
	["cam_left", JOY_AXIS_RIGHT_X, -1.0], ["cam_right", JOY_AXIS_RIGHT_X, 1.0]]


## Replace all bindings with the given scheme ("royale" or "story").
static func apply(scheme: String, owner: Node = null) -> void:
	var table: Dictionary = ROYALE if scheme == "royale" else STORY
	var touch: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Touch")
	var on_touch: bool = touch != null and touch.enabled
	for action in table:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action)
		for k in table[action]:
			var ev: InputEvent
			if k is String and on_touch:
				continue  # fingers arrive as fake mouse clicks; touch buttons replace mouse bindings
			if k is String:
				var mb := InputEventMouseButton.new()
				mb.button_index = {"LMB": MOUSE_BUTTON_LEFT, "RMB": MOUSE_BUTTON_RIGHT,
					"WHEEL_UP": MOUSE_BUTTON_WHEEL_UP, "WHEEL_DOWN": MOUSE_BUTTON_WHEEL_DOWN}[k]
				ev = mb
			else:
				var ke := InputEventKey.new()
				ke.physical_keycode = k
				ev = ke
			InputMap.action_add_event(action, ev)
		if PAD.has(action) and not (scheme == "royale" and action.begins_with("switch")):
			var jb := InputEventJoypadButton.new()
			jb.button_index = PAD[action]
			InputMap.action_add_event(action, jb)
	for ax in PAD_AXES:
		if not table.has(ax[0]):
			continue
		var jm := InputEventJoypadMotion.new()
		jm.axis = ax[1]
		jm.axis_value = ax[2]
		InputMap.action_add_event(ax[0], jm)
	if touch:
		touch.set_scheme(scheme, owner)
