# DomNode — an element or text node of the in-game document tree.
# Mirrors the parts of the browser DOM API that the game code uses.
class_name DomNode
extends RefCounted

const ELEMENT := 1
const TEXT := 3

var nodeType: int = ELEMENT
var tag: String = "div"
var tagName: String:
	get: return tag.to_upper()
var nodeName: String:
	get: return tag.to_upper() if nodeType == ELEMENT else "#text"
var data: String = ""               # text nodes
var childNodes: Array = []          # Array[DomNode]
var _parent: WeakRef = null
var doc = null                      # owning document (Document.gd autoload)
var classes: Array = []             # class names
var attrs: Dictionary = {}
var dataset: Dictionary = {}
var style: DomStyle
var classList: DomClassList
var _id: String = ""
var _listeners: Dictionary = {}     # type -> Array of {fn, once}
var _on: Dictionary = {}            # "onclick" → Callable / handler source String
var _expando: Dictionary = {}
var pseudo: String = ""             # "before" / "after" for generated boxes
var _before: DomNode = null
var _after: DomNode = null

# interaction state
var _hover := false
var _active := false
var _focus := false
var _disabled := false
var _value: String = ""
var _checked := false
var control: Control = null         # native control for <input>

# style / layout / paint state (filled in by the engines)
var cs: Dictionary = {}             # computed style (strings)
var st: Dictionary = {}             # resolved, typed style values
var style_dirty := true
var paint_dirty := true
var lx := 0.0; var ly := 0.0; var lw := 0.0; var lh := 0.0      # border box, relative to parent's border box
var pad := [0.0, 0.0, 0.0, 0.0]     # top right bottom left
var bor := [0.0, 0.0, 0.0, 0.0]
var mar := [0.0, 0.0, 0.0, 0.0]
var content_w := 0.0; var content_h := 0.0
var _scroll_x := 0.0; var _scroll_y := 0.0
var frags: Array = []               # laid-out inline fragments (text runs, inline boxes)
var baseline := -1.0
var rid: RID
var in_flow_display := ""           # effective display used by layout ("" when not rendered)
var abs_cb: DomNode = null
var paint_seq := 0
var eff_z := 0
var _imin := -1.0; var _imax := -1.0; var _ipass := -1
var canvas_ctx = null               # Ctx2D for <canvas>
var _cw := 300; var _ch := 150      # canvas bitmap size
var svg_dirty := true

func _init(tag_: String = "div", doc_ = null) -> void:
	tag = tag_
	doc = doc_
	style = DomStyle.new(self)
	classList = DomClassList.new(self)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if rid.is_valid(): RenderingServer.free_rid(rid)
		if control != null and is_instance_valid(control): control.queue_free()
		if canvas_ctx != null: canvas_ctx.dispose()

# ───────────────────────── tree ─────────────────────────
var parentElement: DomNode:
	get: return _parent.get_ref() if _parent != null else null
var parentNode: DomNode:
	get: return _parent.get_ref() if _parent != null else null

var children: Array:
	get:
		var out := []
		for c in childNodes:
			if c.nodeType == ELEMENT: out.append(c)
		return out
var firstChild: DomNode:
	get: return childNodes[0] if childNodes.size() > 0 else null
var lastChild: DomNode:
	get: return childNodes[childNodes.size() - 1] if childNodes.size() > 0 else null
var firstElementChild: DomNode:
	get: return first_element_child()
var lastElementChild: DomNode:
	get: return last_element_child()
var nextElementSibling: DomNode:
	get: return next_element_sibling()
var previousElementSibling: DomNode:
	get: return previous_element_sibling()
var childElementCount: int:
	get: return children.size()
var isConnected: bool:
	get: return is_connected_to_doc()

func first_element_child() -> DomNode:
	for c in childNodes:
		if c.nodeType == ELEMENT: return c
	return null

func last_element_child() -> DomNode:
	for i in range(childNodes.size() - 1, -1, -1):
		if childNodes[i].nodeType == ELEMENT: return childNodes[i]
	return null

func previous_element_sibling() -> DomNode:
	var p := parentElement
	if p == null: return null
	var prev: DomNode = null
	for c in p.childNodes:
		if c == self: return prev
		if c.nodeType == ELEMENT: prev = c
	return null

func next_element_sibling() -> DomNode:
	var p := parentElement
	if p == null: return null
	var seen := false
	for c in p.childNodes:
		if seen and c.nodeType == ELEMENT: return c
		if c == self: seen = true
	return null

func is_connected_to_doc() -> bool:
	var n: DomNode = self
	while n != null:
		if doc != null and n == doc.root: return true
		n = n.parentElement
	return false

func _detach() -> void:
	var p := parentElement
	if p != null:
		p.childNodes.erase(self)
		p._tree_changed()
	_parent = null
	_release_render()

func _release_render() -> void:
	# free canvas items of a subtree that left the document (recreated on demand)
	if rid.is_valid():
		RenderingServer.free_rid(rid)
		rid = RID()
	if control != null and is_instance_valid(control): control.visible = false
	paint_dirty = true
	style_dirty = true
	if _before != null: _before._release_render()
	if _after != null: _after._release_render()
	for c in childNodes: c._release_render()

func _tree_changed() -> void:
	style_dirty = true
	if doc != null: doc.mark_style(self)

func appendChild(child: DomNode) -> DomNode:
	if child == null: return null
	child._detach()
	child._parent = weakref(self)
	child._adopt(doc)
	childNodes.append(child)
	_tree_changed()
	return child

func append(child) -> void:
	if child is DomNode: appendChild(child)
	else: appendChild(doc.createTextNode(JS.s(child)))

func prepend(child: DomNode) -> void:
	insertBefore(child, firstChild)

func insertBefore(child: DomNode, ref: DomNode = null) -> DomNode:
	if ref == null: return appendChild(child)
	child._detach()
	var i := childNodes.find(ref)
	if i < 0: return appendChild(child)
	child._parent = weakref(self)
	child._adopt(doc)
	childNodes.insert(i, child)
	_tree_changed()
	return child

func removeChild(child: DomNode) -> DomNode:
	if child != null and child.parentElement == self: child._detach()
	return child

func remove() -> void:
	_detach()

func replaceChildren() -> void:
	_clear_children()

func contains(other) -> bool:
	var n: DomNode = other
	while n != null:
		if n == self: return true
		n = n.parentElement
	return false

func closest(sel: String) -> DomNode:
	var n: DomNode = self
	while n != null:
		if n.nodeType == ELEMENT and doc.matches(n, sel): return n
		n = n.parentElement
	return null

func matches(sel: String) -> bool:
	return doc.matches(self, sel)

func cloneNode(deep = false) -> DomNode:
	var c := DomNode.new(tag, doc)
	c.nodeType = nodeType
	c.data = data
	c._id = _id
	c.classes = classes.duplicate()
	c.attrs = attrs.duplicate()
	c.dataset = dataset.duplicate()
	c.style._props = style._props.duplicate()
	c._on = _on.duplicate()
	if JS.t(deep):
		for ch in childNodes: c.appendChild(ch.cloneNode(true))
	return c

func _adopt(d) -> void:
	if doc == d: return
	doc = d
	for c in childNodes: c._adopt(d)

func _clear_children() -> void:
	if childNodes.is_empty(): return
	var old := childNodes
	childNodes = []
	for c in old:
		c._parent = null
		c._release_render()
	_tree_changed()

# ───────────────────────── attributes / properties ─────────────────────────
var id:
	get: return _id
	set(v):
		if doc != null: doc._unindex_id(self)
		_id = JS.s(v) if v != null else ""
		if doc != null: doc._index_id(self)
		_restyle()

var className:
	get: return " ".join(PackedStringArray(classes))
	set(v):
		classes = Array(JS.s(v).split(" ", false))
		_restyle()

var innerHTML:
	get: return HtmlParser.serialize_children(self)
	set(v):
		_clear_children()
		var html := JS.s(v) if v != null else ""
		if html != "":
			for n in HtmlParser.parse(html, doc):
				n._parent = weakref(self)
				childNodes.append(n)
			_tree_changed()
			if tag == "style" and doc != null: doc._style_element_changed(self)

var outerHTML: String:
	get: return HtmlParser.serialize(self)

var textContent:
	get:
		if nodeType == TEXT: return data
		var s := ""
		for c in childNodes: s += c.textContent
		return s
	set(v):
		var txt := JS.s(v) if v != null else ""
		if nodeType == TEXT:
			if data == txt: return
			data = txt
			var p := parentElement
			if p != null: p._layout_changed()
			return
		if childNodes.size() == 1 and childNodes[0].nodeType == TEXT:
			if childNodes[0].data == txt: return
			childNodes[0].data = txt
			_layout_changed()
			return
		_clear_children()
		if txt != "":
			var tn := DomNode.new("#text", doc)
			tn.nodeType = TEXT
			tn.data = txt
			tn._parent = weakref(self)
			childNodes.append(tn)
		_tree_changed()
		if tag == "style" and doc != null: doc._style_element_changed(self)

var innerText:
	get: return textContent
	set(v): textContent = v

var title:
	get: return attrs.get("title", "")
	set(v): attrs["title"] = JS.s(v)

var disabled:
	get: return _disabled
	set(v):
		var b := JS.t(v)
		if b == _disabled: return
		_disabled = b
		_restyle()

var hidden:
	get: return attrs.has("hidden")
	set(v):
		if JS.t(v): attrs["hidden"] = ""
		else: attrs.erase("hidden")
		_restyle()

var value:
	get:
		if control != null and is_instance_valid(control):
			if control is LineEdit: return control.text
			if control is HSlider: return JS.s(control.value)
		return _value
	set(v):
		_value = JS.s(v) if v != null else ""
		if control != null and is_instance_valid(control):
			if control is LineEdit: control.text = _value
			elif control is HSlider: control.set_value_no_signal(_value.to_float())

var checked:
	get: return _checked
	set(v): _checked = JS.t(v)

var draggable:
	get: return attrs.get("draggable", "") == "true"
	set(v): attrs["draggable"] = "true" if JS.t(v) else "false"

var type:
	get: return attrs.get("type", "")
	set(v): attrs["type"] = JS.s(v)

var placeholder:
	get: return attrs.get("placeholder", "")
	set(v): attrs["placeholder"] = JS.s(v)

# canvas bitmap size
var width:
	get: return _cw if tag == "canvas" else JS.num(attrs.get("width", "0"))
	set(v):
		if tag == "canvas":
			_cw = maxi(1, int(JS.num(v)))
			_canvas_resized()
		else: attrs["width"] = JS.s(v)
var height:
	get: return _ch if tag == "canvas" else JS.num(attrs.get("height", "0"))
	set(v):
		if tag == "canvas":
			_ch = maxi(1, int(JS.num(v)))
			_canvas_resized()
		else: attrs["height"] = JS.s(v)

func _canvas_resized() -> void:
	if canvas_ctx != null: canvas_ctx.resize(_cw, _ch)
	_layout_changed()

func getContext(_kind = "2d", _opts = null):
	if canvas_ctx == null:
		canvas_ctx = Ctx2D.new(self, _cw, _ch)
		paint_dirty = true
		if doc != null: doc.mark_paint(self)
	return canvas_ctx

func setAttribute(name_, v) -> void:
	var n := JS.s(name_)
	var val := JS.s(v) if v != null else ""
	match n:
		"id": id = val
		"class": className = val
		"style": style.cssText = val
		"width":
			if tag == "canvas": width = val.to_int()
			else: attrs[n] = val
		"height":
			if tag == "canvas": height = val.to_int()
			else: attrs[n] = val
		"disabled": disabled = true
		"value": value = val
		_:
			if n.begins_with("data-"): dataset[_camel(n.substr(5))] = val
			elif n.begins_with("on"): _on[n] = val
			else: attrs[n] = val
			if tag == "svg" or _in_svg(): _svg_changed()
			elif n != "title": _restyle()

func getAttribute(name_):
	var n := JS.s(name_)
	match n:
		"id": return _id
		"class": return className
		"style": return style.cssText
	if n.begins_with("data-"): return dataset.get(_camel(n.substr(5)))
	return attrs.get(n)

func hasAttribute(name_) -> bool:
	return getAttribute(name_) != null

func removeAttribute(name_) -> void:
	var n := JS.s(name_)
	if n == "disabled": disabled = false
	elif n == "style": style.cssText = ""
	elif n == "class": className = ""
	elif n.begins_with("data-"): dataset.erase(_camel(n.substr(5)))
	else: attrs.erase(n)
	_restyle()

static func _camel(s: String) -> String:
	var parts := s.split("-")
	var out := parts[0]
	for i in range(1, parts.size()): out += parts[i].capitalize()
	return out

func _in_svg() -> bool:
	var p := parentElement
	while p != null:
		if p.tag == "svg": return true
		p = p.parentElement
	return false

func _svg_changed() -> void:
	var p: DomNode = self
	while p != null and p.tag != "svg": p = p.parentElement
	if p != null:
		p.svg_dirty = true
		p.paint_dirty = true
		if doc != null: doc.mark_paint(p)

func _restyle() -> void:
	style_dirty = true
	if doc != null: doc.mark_style(self)

func _layout_changed() -> void:
	if doc != null: doc.mark_layout(self)

# dynamic properties: on<event> handlers and arbitrary expandos (el._foo = …)
func _get(prop: StringName):
	var p := String(prop)
	if p.begins_with("on") and _on.has(p): return _on[p]
	if _expando.has(p): return _expando[p]
	return null

func _set(prop: StringName, v) -> bool:
	var p := String(prop)
	if p.begins_with("on") and p == p.to_lower():
		if v == null: _on.erase(p)
		else: _on[p] = v
		return true
	_expando[p] = v
	return true

# ───────────────────────── events ─────────────────────────
func addEventListener(type_, fn, opts = null) -> void:
	if not (fn is Callable): return
	var t := JS.s(type_)
	if not _listeners.has(t): _listeners[t] = []
	for l in _listeners[t]:
		if l.fn == fn: return
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

func dispatchEvent(ev) -> bool:
	if doc != null: doc.dispatch(self, ev)
	return true

func click() -> void:
	if doc != null: doc.dispatch(self, DomEvent.new("click"))

func focus() -> void:
	if control != null and is_instance_valid(control): control.grab_focus()

func blur() -> void:
	if control != null and is_instance_valid(control): control.release_focus()

func setPointerCapture(_pid = null) -> void:
	if doc != null: doc.capture = self

func releasePointerCapture(_pid = null) -> void:
	if doc != null and doc.capture == self: doc.capture = null

func scrollIntoView(_opts = null) -> void:
	if doc != null: doc.scroll_into_view(self)

func scrollTo(a = null, b = null) -> void:
	if a is Dictionary: scrollTop = a.get("top", 0)
	elif b != null: scrollTop = b

# ───────────────────────── queries ─────────────────────────
func querySelector(sel):
	return doc.query(self, JS.s(sel), true)

func querySelectorAll(sel) -> Array:
	return doc.query(self, JS.s(sel), false)

func getElementsByClassName(cls) -> Array:
	return doc.query(self, "." + JS.s(cls), false)

func insertAdjacentHTML(where, html) -> void:
	var nodes := HtmlParser.parse(JS.s(html), doc)
	match JS.s(where):
		"beforeend":
			for n in nodes: appendChild(n)
		"afterbegin":
			var ref := firstChild
			for n in nodes: insertBefore(n, ref)
		"beforebegin":
			var p := parentElement
			if p != null:
				for n in nodes: p.insertBefore(n, self)
		"afterend":
			var p2 := parentElement
			if p2 != null:
				var ref2 := next_sibling()
				for n in nodes: p2.insertBefore(n, ref2)

func next_sibling() -> DomNode:
	var p := parentElement
	if p == null: return null
	var i := p.childNodes.find(self)
	return p.childNodes[i + 1] if i >= 0 and i + 1 < p.childNodes.size() else null

var nextSibling: DomNode:
	get: return next_sibling()

# ───────────────────────── geometry ─────────────────────────
# true when this element and all its ancestors are displayed
func _rendered() -> bool:
	if in_flow_display == "": return false
	var n: DomNode = self
	while n != null:
		if n.st.get("display", "none") == "none": return false
		n = n.parentElement
	return true

var offsetWidth: float:
	get:
		if doc != null: doc.ensure_layout()
		return roundf(lw) if _rendered() else 0.0
var offsetHeight: float:
	get:
		if doc != null: doc.ensure_layout()
		return roundf(lh) if _rendered() else 0.0
var clientWidth: float:
	get:
		if doc != null: doc.ensure_layout()
		return roundf(lw - bor[1] - bor[3]) if _rendered() else 0.0
var clientHeight: float:
	get:
		if doc != null: doc.ensure_layout()
		return roundf(lh - bor[0] - bor[2]) if _rendered() else 0.0
var scrollHeight: float:
	get:
		if doc != null: doc.ensure_layout()
		return maxf(content_h, lh - bor[0] - bor[2])
var scrollWidth: float:
	get:
		if doc != null: doc.ensure_layout()
		return maxf(content_w, lw - bor[1] - bor[3])
var offsetLeft: float:
	get:
		if doc != null: doc.ensure_layout()
		return lx
var offsetTop: float:
	get:
		if doc != null: doc.ensure_layout()
		return ly
var offsetParent: DomNode:
	get: return parentElement
var scrollTop:
	get: return _scroll_y
	set(v):
		if doc != null: doc.ensure_layout()
		var maxs := maxf(0.0, content_h - (lh - bor[0] - bor[2]))
		var nv := clampf(float(JS.num(v)), 0.0, maxs)
		if nv == _scroll_y: return
		_scroll_y = nv
		if doc != null: doc.mark_scroll(self)
var scrollLeft:
	get: return _scroll_x
	set(v):
		if doc != null: doc.ensure_layout()
		var maxs := maxf(0.0, content_w - (lw - bor[1] - bor[3]))
		_scroll_x = clampf(float(JS.num(v)), 0.0, maxs)
		if doc != null: doc.mark_scroll(self)

func getBoundingClientRect() -> Dictionary:
	if doc != null: doc.ensure_layout()
	var r: Rect2 = doc.client_rect(self) if doc != null else Rect2(lx, ly, lw, lh)
	return {"x": r.position.x, "y": r.position.y, "left": r.position.x, "top": r.position.y, "width": r.size.x, "height": r.size.y,
		"right": r.position.x + r.size.x, "bottom": r.position.y + r.size.y}

func _js_to_string() -> String:
	return "[object HTMLElement]"
