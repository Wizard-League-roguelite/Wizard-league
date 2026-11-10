# DomClassList — `el.classList`
class_name DomClassList
extends RefCounted

var _owner: WeakRef

func _init(owner_: DomNode) -> void:
	_owner = weakref(owner_)

func add(a = null, b = null, c = null) -> void:
	var o: DomNode = _owner.get_ref()
	var changed := false
	for x in [a, b, c]:
		if x != null and not o.classes.has(x):
			o.classes.append(JS.s(x)); changed = true
	if changed: o._restyle()

func remove(a = null, b = null, c = null) -> void:
	var o: DomNode = _owner.get_ref()
	var changed := false
	for x in [a, b, c]:
		if x != null and o.classes.has(x):
			o.classes.erase(x); changed = true
	if changed: o._restyle()

func toggle(cls, force = null) -> bool:
	var o: DomNode = _owner.get_ref()
	var want: bool = (not o.classes.has(cls)) if force == null else JS.t(force)
	if want: add(cls)
	else: remove(cls)
	return want

func contains(cls) -> bool:
	var o: DomNode = _owner.get_ref()
	return o.classes.has(cls)

func has(cls) -> bool:
	return contains(cls)
