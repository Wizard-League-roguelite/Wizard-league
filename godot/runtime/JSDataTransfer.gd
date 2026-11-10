# JSDataTransfer — payload carried by drag-and-drop events.
class_name JSDataTransfer
extends RefCounted

var _data: Dictionary = {}
var effectAllowed := "all"
var dropEffect := "move"

func setData(kind, value) -> void:
	_data[JS.s(kind)] = JS.s(value)

func getData(kind) -> String:
	return _data.get(JS.s(kind), "")

func setDragImage(_a = null, _b = null, _c = null) -> void:
	pass
