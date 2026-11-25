extends CanvasLayer
## On-screen touch controls (autoload "Touch") for iPad / phones.
##
## Left side   : floating joystick (push to the edge = sprint in Battle Royale)
## Right side  : drag anywhere free = turn the camera (Battle Royale)
## Buttons     : attack · power · jump · dodge · ultimate / switch hero · pause · map · team · revive
##
## Buttons press the same InputMap actions the keyboard and gamepad use, so the
## game code does not need to know whether input came from a finger.
## Active automatically on touch screens; force it on desktop with `-- --touch`.

const ACCENT := Color("ffb0d8")
const NAVY := Color("1b1840")
const STICK_R := 92.0          # joystick travel radius
const SPRINT_AT := 0.92        # push this far to sprint
const CAM_SENS := Vector2(0.0065, 0.0045)

var enabled := false
var scheme := ""               # "royale" / "story" / "" (hidden)
var owner_ref: WeakRef
var cam_delta := Vector2.ZERO  # consumed by royale.gd each frame
var cooldowns := {}            # action -> [fraction 0..1 still cooling, text]; set by hud.gd

var _canvas: Control
var _buttons: Array = []       # {id, action, label, center, r, col, held, finger, hold}
var _stick_finger := -1
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _cam_finger := -1
var _cam_last := Vector2.ZERO
var _font: Font

# Thumb-first layout: joystick in the bottom-left corner, action buttons in an arc
# around the bottom-right corner (where the right thumb rests). Rarely used buttons
# (pause / map / team) sit at the top so they are not hit by accident.
const LAYOUTS := {
	"royale": [
		# id, action, label, center, radius, colour, hold?
		["attack", "attack", "ATK", Vector2(1188, 624), 72, Color("ff6a8a"), false],
		["jump", "jump", "JUMP", Vector2(1210, 474), 46, Color("8affc0"), true],
		["dodge", "dodge", "DASH", Vector2(1078, 520), 46, Color("ffd36a"), false],
		["power", "power", "SKILL", Vector2(1040, 650), 48, Color("6ab8ff"), false],
		["ultimate", "ultimate", "ULT", Vector2(1102, 402), 38, Color("ffb0ff"), false],
		["interact", "interact", "REVIVE", Vector2(920, 662), 36, Color("c8cce8"), true],
		["call_team", "call_team", "TEAM", Vector2(760, 33), 22, Color("c8cce8"), false],
		["map", "map", "MAP", Vector2(812, 33), 22, Color("c8cce8"), false],
		["pause", "pause", "II", Vector2(864, 33), 22, Color("c8cce8"), false],
	],
	"story": [
		["attack", "attack", "ATK", Vector2(1188, 624), 72, Color("ff6a8a"), false],
		["jump", "jump", "JUMP", Vector2(1210, 474), 46, Color("8affc0"), true],
		["dodge", "dodge", "DASH", Vector2(1078, 520), 46, Color("ffd36a"), false],
		["power", "power", "SKILL", Vector2(1040, 650), 48, Color("6ab8ff"), false],
		["switch_prev", "switch_prev", "◀", Vector2(1000, 410), 32, Color("c8cce8"), false],
		["switch_next", "switch_next", "▶", Vector2(1100, 400), 32, Color("c8cce8"), false],
	],
}


func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") \
		or "--touch" in OS.get_cmdline_user_args()
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Arial"])
	f.font_weight = 700
	_font = f
	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)
	visible = false


## Called by controls.gd when a mode sets up its key bindings.
func set_scheme(new_scheme: String, owner_node: Node) -> void:
	_release_all()
	cooldowns.clear()
	scheme = new_scheme if LAYOUTS.has(new_scheme) else ""
	owner_ref = weakref(owner_node) if owner_node else null
	_buttons.clear()
	for b in LAYOUTS.get(scheme, []):
		_buttons.append({"id": b[0], "action": b[1], "label": b[2], "center": b[3], "r": float(b[4]),
			"col": b[5], "hold": b[6], "finger": -1})


func active() -> bool:
	return enabled and scheme != "" and owner_ref != null and owner_ref.get_ref() != null \
		and not get_tree().paused


func take_cam_delta() -> Vector2:
	var d := cam_delta
	cam_delta = Vector2.ZERO
	return d


func _process(_delta: float) -> void:
	var on := active()
	if visible != on:
		visible = on
		if not on:
			_release_all()
	if on:
		_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not active():
		return
	if event is InputEventScreenTouch:
		var pos := _to_canvas(event.position)
		if event.pressed:
			_touch_down(event.index, pos)
		else:
			_touch_up(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_touch_move(event.index, _to_canvas(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouse and enabled and not event is InputEventMouseMotion:
		# fingers also arrive as emulated mouse clicks; keep them out of the game
		get_viewport().set_input_as_handled()


func _to_canvas(p: Vector2) -> Vector2:
	return _canvas.get_global_transform_with_canvas().affine_inverse() * p


func _touch_down(finger: int, pos: Vector2) -> void:
	for b in _buttons:
		if b["finger"] == -1 and pos.distance_to(b["center"]) <= b["r"] * 1.15:
			b["finger"] = finger
			_send(b["action"], true)
			if not b["hold"]:
				# tap buttons fire once; keep it down for 2 physics ticks so
				# is_action_just_pressed in _physics_process always sees it (also on 120 Hz screens)
				_release_later(b)
			return
	if pos.x < 560 and _stick_finger == -1:
		_stick_finger = finger
		_stick_origin = pos
		_stick_pos = pos
		return
	if scheme == "royale" and _cam_finger == -1:
		_cam_finger = finger
		_cam_last = pos


func _release_later(b: Dictionary) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if Input.is_action_pressed(b["action"]):
		_send(b["action"], false)


## Real action event: updates Input state AND reaches _unhandled_input handlers
## (pause / map / team only listen for events, not for held state).
func _send(action: String, down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)


func _touch_move(finger: int, pos: Vector2) -> void:
	if finger == _stick_finger:
		var off := pos - _stick_origin
		if off.length() > STICK_R:
			# drag the base along so the stick never feels stuck
			_stick_origin = pos - off.normalized() * STICK_R
			off = pos - _stick_origin
		_stick_pos = pos
		_apply_stick(off / STICK_R)
	elif finger == _cam_finger:
		var d := pos - _cam_last
		_cam_last = pos
		cam_delta += Vector2(d.x * CAM_SENS.x, d.y * CAM_SENS.y)


func _touch_up(finger: int) -> void:
	if finger == _stick_finger:
		_stick_finger = -1
		_apply_stick(Vector2.ZERO)
	if finger == _cam_finger:
		_cam_finger = -1
	for b in _buttons:
		if b["finger"] == finger:
			b["finger"] = -1
			if b["hold"]:
				_send(b["action"], false)


func _apply_stick(v: Vector2) -> void:
	var pairs := [["move_left", -v.x], ["move_right", v.x], ["move_up", -v.y], ["move_down", v.y]]
	for p in pairs:
		if p[1] > 0.05:
			Input.action_press(p[0], clampf(p[1], 0.0, 1.0))
		else:
			Input.action_release(p[0])
	if InputMap.has_action("sprint"):
		if v.length() >= SPRINT_AT:
			Input.action_press("sprint")
		else:
			Input.action_release("sprint")


func _release_all() -> void:
	_stick_finger = -1
	_cam_finger = -1
	cam_delta = Vector2.ZERO
	for a in ["move_left", "move_right", "move_up", "move_down", "sprint"]:
		if InputMap.has_action(a):
			Input.action_release(a)
	for b in _buttons:
		b["finger"] = -1
		if InputMap.has_action(b["action"]):
			Input.action_release(b["action"])


# ---------------- drawing ----------------
func _draw_controls() -> void:
	# joystick
	if _stick_finger != -1:
		_canvas.draw_circle(_stick_origin, STICK_R, Color(NAVY, 0.35))
		_canvas.draw_arc(_stick_origin, STICK_R, 0, TAU, 48, Color(ACCENT, 0.6), 3.0, true)
		var knob := _stick_origin + (_stick_pos - _stick_origin).limit_length(STICK_R)
		var sprint := (_stick_pos - _stick_origin).length() >= STICK_R * SPRINT_AT and scheme == "royale"
		_canvas.draw_circle(knob, 40, Color(ACCENT if not sprint else Color("ffd36a"), 0.85))
	else:
		# hint where the stick lives
		var home := Vector2(170, 580)
		_canvas.draw_arc(home, STICK_R, 0, TAU, 48, Color(1, 1, 1, 0.22), 3.0, true)
		_canvas.draw_circle(home, 34, Color(1, 1, 1, 0.16))
	# buttons
	for b in _buttons:
		var held: bool = b["finger"] != -1
		var c: Color = b["col"]
		_canvas.draw_circle(b["center"], b["r"], Color(NAVY, 0.72 if held else 0.5))
		_canvas.draw_arc(b["center"], b["r"], 0, TAU, 48, Color(c, 1.0 if held else 0.8), 4.0 if held else 3.0, true)
		if held:
			_canvas.draw_circle(b["center"], b["r"] - 6, Color(c, 0.35))
		var cd: Array = cooldowns.get(b["action"], [0.0, ""])
		if cd[0] > 0.0:
			# dark pie sweeping clockwise as the move recharges
			var pts := PackedVector2Array([b["center"]])
			var steps := 32
			for k in steps + 1:
				var ang: float = -PI / 2 + TAU * float(cd[0]) * k / steps
				pts.append(b["center"] + Vector2(cos(ang), sin(ang)) * (b["r"] - 3))
			_canvas.draw_colored_polygon(pts, Color(0.03, 0.02, 0.1, 0.6))
		var fs := int(clampf(b["r"] * 0.42, 13, 26))
		var lift := 0.0
		if cd[1] != "":
			# cooldown / charge text under the label (e.g. "ULT" + "40%", "SKILL" + "3")
			var fs2 := int(fs * 0.8)
			var w2 := _font.get_string_size(cd[1], HORIZONTAL_ALIGNMENT_CENTER, -1, fs2).x
			_canvas.draw_string(_font, b["center"] + Vector2(-w2 / 2.0, fs * 0.36 + fs * 0.62), cd[1],
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color("ffe14a"))
			lift = fs * 0.5
		var text: String = b["label"]
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		_canvas.draw_string(_font, b["center"] + Vector2(-w / 2.0, fs * 0.36 - lift), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
