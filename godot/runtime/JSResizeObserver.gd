# JSResizeObserver — calls back when an observed element's box size changes.
class_name JSResizeObserver
extends RefCounted

var _fn
var _targets: Array = []      # [weakref, last size]
static var all: Array = []    # weakrefs to live observers

func _init(fn = null) -> void:
	_fn = fn
	all.append(weakref(self))

func observe(el) -> void:
	if el is DomNode: _targets.append([weakref(el), Vector2(-1, -1)])

func unobserve(_el = null) -> void:
	pass

func check() -> void:
	var changed := false
	for t in _targets:
		var n: DomNode = t[0].get_ref()
		if n == null or n.in_flow_display == "": continue
		var sz := Vector2(n.lw, n.lh)
		if sz != t[1]:
			if t[1].x >= 0.0: changed = true
			t[1] = sz
	if changed: JS.invoke(_fn, [[]])

static func check_all() -> void:
	var live := []
	for w in all:
		var o = w.get_ref()
		if o != null:
			live.append(w)
			o.check()
	all = live
