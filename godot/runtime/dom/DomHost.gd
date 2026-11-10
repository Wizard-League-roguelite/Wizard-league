# DomHost — full-window Control that receives input for the DOM and parents its canvas items.
class_name DomHost
extends Control

var doc
var _touch_scroll := {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	set_process_unhandled_key_input(true)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		doc.pointer_moved(e.position, e.button_mask)
	elif e is InputEventMouseButton:
		match e.button_index:
			MOUSE_BUTTON_LEFT:
				if e.pressed: doc.pointer_down(e.position, 0)
				else: doc.pointer_up(e.position, 0)
			MOUSE_BUTTON_RIGHT:
				if e.pressed: doc.pointer_down(e.position, 2)
				else: doc.pointer_up(e.position, 2)
			MOUSE_BUTTON_WHEEL_DOWN:
				if e.pressed: doc.wheel(e.position, 60.0 * maxf(1.0, e.factor))
			MOUSE_BUTTON_WHEEL_UP:
				if e.pressed: doc.wheel(e.position, -60.0 * maxf(1.0, e.factor))
	elif e is InputEventPanGesture:
		doc.wheel(e.position, e.delta.y * 30.0)

func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey:
		var key := OS.get_keycode_string(e.keycode)
		var ch := char(e.unicode) if e.unicode > 0 else ""
		var name_ := ch if ch != "" else key
		match e.keycode:
			KEY_ESCAPE: name_ = "Escape"
			KEY_ENTER, KEY_KP_ENTER: name_ = "Enter"
			KEY_SPACE: name_ = " "
			KEY_LEFT: name_ = "ArrowLeft"
			KEY_RIGHT: name_ = "ArrowRight"
			KEY_UP: name_ = "ArrowUp"
			KEY_DOWN: name_ = "ArrowDown"
			KEY_TAB: name_ = "Tab"
			KEY_BACKSPACE: name_ = "Backspace"
		doc.key_event("keydown" if e.pressed else "keyup", name_, key, e)

func _get_tooltip(at_position: Vector2) -> String:
	var n: DomNode = doc.element_at(at_position)
	while n != null:
		var t: String = n.attrs.get("title", "")
		if t != "": return t
		n = n.parentElement
	return ""
