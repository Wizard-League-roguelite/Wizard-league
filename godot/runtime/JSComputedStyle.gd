# JSComputedStyle — result of window.getComputedStyle(el)
class_name JSComputedStyle
extends RefCounted

var _n: DomNode

func _init(n: DomNode) -> void:
	_n = n

func _get(prop: StringName):
	var k := DomStyle.kebab(String(prop))
	match k:
		"width": return "%spx" % JS.s(_n.lw)
		"height": return "%spx" % JS.s(_n.lh)
	return _n.cs.get(k, "")

func getPropertyValue(name_) -> String:
	return _n.cs.get(DomStyle.kebab(JS.s(name_)), "")
