# DomEvent — event object handed to listeners.
class_name DomEvent
extends RefCounted

var type: String = ""
var target: DomNode = null
var currentTarget = null
var clientX := 0.0; var clientY := 0.0
var pageX := 0.0; var pageY := 0.0
var offsetX := 0.0; var offsetY := 0.0
var screenX := 0.0; var screenY := 0.0
var movementX := 0.0; var movementY := 0.0
var button := 0
var buttons := 0
var key: String = ""
var code: String = ""
var ctrlKey := false; var shiftKey := false; var altKey := false; var metaKey := false
var deltaY := 0.0; var deltaX := 0.0
var touches: Array = []
var changedTouches: Array = []
var targetTouches: Array = []
var pointerId := 1
var pointerType: String = "mouse"
var isPrimary := true
var detail = 0
var dataTransfer = null
var defaultPrevented := false
var cancelable := true
var bubbles := true
var _stopped := false
var _stopped_now := false
var timeStamp := 0.0
var repeat := false
var which := 0
var keyCode := 0

func _init(type_: String = "", init = null) -> void:
	type = type_
	timeStamp = JS.now()
	if init is Dictionary:
		for k in init.keys(): set(k, init[k])

func preventDefault() -> void:
	defaultPrevented = true

func stopPropagation() -> void:
	_stopped = true

func stopImmediatePropagation() -> void:
	_stopped = true
	_stopped_now = true
