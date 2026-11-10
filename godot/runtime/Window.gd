# window — autoload standing in for the browser `window` object.
extends Node

var devicePixelRatio := 1.0
var navigator := {"userAgent": "Godot", "maxTouchPoints": 0, "platform": "Godot"}
var location := {"hostname": "localhost", "href": "", "search": "", "hash": ""}
var scrollX := 0.0
var scrollY: float:
	get: return document.page_scroll
var _props: Dictionary = {}
var _listeners: Dictionary = {}

var innerWidth: float:
	get: return document.viewport_size.x
var innerHeight: float:
	get: return document.viewport_size.y

# arbitrary globals stored on window (window._foo = …)
func _get(prop: StringName):
	return _props.get(String(prop))

func _set(prop: StringName, v) -> bool:
	_props[String(prop)] = v
	return true

func addEventListener(type_, fn, opts = null) -> void:
	if not (fn is Callable): return
	var t := JS.s(type_)
	if not _listeners.has(t): _listeners[t] = []
	var once := false
	if opts is Dictionary: once = JS.t(opts.get("once"))
	_listeners[t].append({"fn": fn, "once": once})

func removeEventListener(type_, fn, _opts = null) -> void:
	var t := JS.s(type_)
	if not _listeners.has(t): return
	var list: Array = _listeners[t]
	for i in range(list.size()):
		if list[i].fn == fn:
			list.remove_at(i)
			return

func fire(ev: DomEvent) -> void:
	var list = _listeners.get(ev.type)
	if list == null: return
	ev.currentTarget = self
	for l in list.duplicate():
		if l.once: list.erase(l)
		JS.invoke(l.fn, [ev])

func dispatch_window_event(type_: String) -> void:
	fire(DomEvent.new(type_))

func getComputedStyle(el):
	document.ensure_layout()
	return JSComputedStyle.new(el)

func matchMedia(q) -> Dictionary:
	return {"matches": document.css.media_ok(JS.s(q))}

func scrollTo(_x = 0, y = 0) -> void:
	document.page_scroll = float(JS.num(y)) if not (_x is Dictionary) else float(_x.get("top", 0))
	document._paint_dirty = true

func open(_url = null, _t = null) -> void:
	if _url != null: OS.shell_open(JS.s(_url))
