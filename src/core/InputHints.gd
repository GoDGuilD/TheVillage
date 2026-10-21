# File: InputHints.gd
# Description: Watches which kind of device the player last used (keyboard or gamepad, and which gamepad family) so on-screen hints name the right keys or buttons; a node that keeps listening while the game is paused, with the answers kept static.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
class_name InputHints
extends Node
## The Juice autoload adds one instance. Hints are English text; PixelText translates them ("PRESS %s" ->
## "PULSA %s"), and the button names are the same in every language except "CIRCLE".
## The SNES layout puts confirm (SNES A) on the right face button: Xbox B, Nintendo A, PlayStation circle.

signal device_changed(device: String)

const KEYBOARD := "keyboard"
const GAMEPAD := "gamepad"
const STICK_THRESHOLD := 0.5             # a stick must move this far to count as "using the gamepad"
const STICK_AXES := [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]   # not the triggers:
		# some pads report a resting trigger at full deflection, which would claim "gamepad" all the time
const CONFIRM_KEY := "ENTER"
const CONFIRM_BUTTONS := {"playstation": "CIRCLE", "nintendo": "A", "xbox": "B"}
const PAD_FAMILIES := {"playstation": ["ps3", "ps4", "ps5", "dualshock", "dualsense", "playstation", "sony"],
		"nintendo": ["nintendo", "switch", "joy-con", "pro controller"]}

static var device := KEYBOARD
static var family := "xbox"              # the last gamepad's family (names its buttons)
static var changes := 0                  # device switches seen (tests)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	var motion := event as InputEventJoypadMotion
	if event is InputEventJoypadButton or (motion != null and motion.axis in STICK_AXES
			and absf(motion.axis_value) >= STICK_THRESHOLD):
		note(GAMEPAD, Input.get_joy_name(event.device))
	elif event is InputEventKey or event is InputEventMouseButton:
		note(KEYBOARD, "")


# Record a device switch (also how tests fake a gamepad: note(GAMEPAD, "Xbox Controller")).
func note(new_device: String, pad_name: String) -> void:
	if new_device == GAMEPAD:
		family = family_of(pad_name)
	if new_device == device:
		return
	device = new_device
	changes += 1
	device_changed.emit(device)


static func family_of(pad_name: String) -> String:
	var n := pad_name.to_lower()
	for fam in PAD_FAMILIES:
		for word in PAD_FAMILIES[fam]:
			if n.contains(word):
				return fam
	return "xbox"


# The confirm key or button for the current device ("ENTER", "B", "A" or "CIRCLE").
static func confirm_label() -> String:
	return CONFIRM_KEY if device == KEYBOARD else String(CONFIRM_BUTTONS[family])


# "PRESS ENTER" / "PRESS B" ... (English; PixelText translates it).
static func press_hint() -> String:
	return "PRESS %s" % confirm_label()


# The title screen's hint: how to move the cursor and pick.
static func menu_hint() -> String:
	return "ARROWS + ENTER" if device == KEYBOARD else "D-PAD + %s" % confirm_label()
