# DomStyle — an element's inline style (`el.style.x = …`, `el.style.cssText = …`).
class_name DomStyle
extends RefCounted

var _owner: WeakRef
var _props: Dictionary = {}     # kebab-case property → value (shorthands expanded)
var _imp: Dictionary = {}
static var _kebab_cache: Dictionary = {}

# properties that never affect layout — changing them only needs a repaint
const PAINT_ONLY := {
	"color": 1, "background-color": 1, "background-image": 1, "opacity": 1, "transform": 1, "box-shadow": 1, "filter": 1,
	"border-top-color": 1, "border-right-color": 1, "border-bottom-color": 1, "border-left-color": 1, "visibility": 1,
	"cursor": 1, "pointer-events": 1, "text-shadow": 1, "transition": 1, "z-index": 1, "transform-origin": 1, "outline": 1,
	"animation": 1, "image-rendering": 1, "user-select": 1, "backdrop-filter": 1, "will-change": 1, "touch-action": 1,
}

func _init(owner_: DomNode) -> void:
	_owner = weakref(owner_)

static func kebab(p: String) -> String:
	var hit = _kebab_cache.get(p)
	if hit != null: return hit
	var out := ""
	if p.begins_with("--"): out = p
	else:
		for ch in p:
			if ch >= "A" and ch <= "Z": out += "-" + ch.to_lower()
			else: out += ch
		if out.begins_with("webkit-"): out = "-" + out
		if out == "css-float": out = "float"
	_kebab_cache[p] = out
	return out

var cssText: String:
	get:
		var s := ""
		for k in _props.keys(): s += "%s:%s;" % [k, _props[k]]
		return s
	set(v):
		var d: Array = _parse(JS.s(v) if v != null else "")
		_props = d[0].duplicate()
		_imp = d[1].duplicate()
		_changed("")

static var _engine: CssEngine = null
static func _parse(text: String) -> Array:
	if _engine == null: _engine = CssEngine.new()
	return _engine.parse_declarations(text)

func _get(prop: StringName):
	var k := kebab(String(prop))
	if _props.has(k): return _props[k]
	# shorthand reads
	match k:
		"border-color": return _props.get("border-top-color", "")
		"border-width": return _props.get("border-top-width", "")
		"background": return _props.get("background-color", "")
		"padding": return _props.get("padding-top", "")
		"margin": return _props.get("margin-top", "")
		"overflow": return _props.get("overflow-y", "")
		"gap": return _props.get("row-gap", "")
		"border-radius": return _props.get("border-top-left-radius", "")
	return ""

func _set(prop: StringName, v) -> bool:
	setProperty(kebab(String(prop)), v)
	return true

func setProperty(name_, v, _prio = null) -> void:
	var k := kebab(JS.s(name_))
	var val := "" if v == null else JS.s(v).strip_edges()
	var tmp := {}
	if val == "":
		CssEngine.expand(k, "0", tmp)
		var removed := false
		for kk in tmp.keys():
			if _props.erase(kk): removed = true
		if removed: _changed(k)
		return
	var important := false
	if val.ends_with("!important"):
		important = true
		val = val.substr(0, val.length() - 10).strip_edges()
	CssEngine.expand(k, val, tmp)
	var changed := false
	for kk in tmp.keys():
		if _props.get(kk) != tmp[kk]:
			_props[kk] = tmp[kk]
			changed = true
		if important: _imp[kk] = true
	if changed: _changed(k)

func getPropertyValue(name_) -> String:
	return _props.get(kebab(JS.s(name_)), "")

func removeProperty(name_) -> void:
	setProperty(name_, "")

func _changed(_k: String) -> void:
	var o: DomNode = _owner.get_ref()
	if o != null: o._restyle()
