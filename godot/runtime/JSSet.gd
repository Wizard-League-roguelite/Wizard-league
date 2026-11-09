# JSSet — insertion-ordered set with JavaScript `Set` semantics (objects compared by identity).
class_name JSSet
extends RefCounted

var _prim := {}      # primitive values
var _objs := []      # dictionaries / arrays / objects (identity)
var size: int:
	get: return _prim.size() + _objs.size()

func _init(src = null) -> void:
	if src == null: return
	for x in JS.iter(src): add(x)

func _is_obj(x) -> bool:
	var ty = typeof(x)
	return ty == TYPE_DICTIONARY or ty == TYPE_ARRAY or ty == TYPE_OBJECT

func _key(x):
	if typeof(x) == TYPE_FLOAT and x == floor(x): return int(x)
	if typeof(x) == TYPE_STRING_NAME: return String(x)
	return x

func has(x) -> bool:
	if _is_obj(x):
		for o in _objs:
			if is_same(o, x): return true
		return false
	return _prim.has(_key(x))

func add(x) -> JSSet:
	if _is_obj(x):
		if not has(x): _objs.append(x)
	else:
		_prim[_key(x)] = true
	return self

func delete(x) -> bool:
	if _is_obj(x):
		for i in range(_objs.size()):
			if is_same(_objs[i], x):
				_objs.remove_at(i)
				return true
		return false
	return _prim.erase(_key(x))

func clear() -> void:
	_prim.clear(); _objs.clear()

func values() -> Array:
	return _prim.keys() + _objs

func forEach(fn: Callable) -> void:
	for x in values(): JS.invoke(fn, [x])

func _js_array() -> Array:
	return values()
