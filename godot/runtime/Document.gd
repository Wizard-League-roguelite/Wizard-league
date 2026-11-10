# document — autoload standing in for the browser `document`.
# Owns the DOM tree, drives style → layout → paint each frame and routes input events.
extends Node

var root: DomNode                 # <body>
var body: DomNode:
	get: return root
var head: DomNode
var documentElement: DomNode:
	get: return root
var activeElement: DomNode = null
var hidden := false
var visibilityState := "visible"
var title := "Wizard's League"

var css := CssEngine.new()
var layout: DomLayout
var painter: DomPaint
var host: Control                 # input + canvas item parent
var host_rid: RID
var viewport_size := Vector2(1280, 720)
var premult_material: CanvasItemMaterial
var capture: DomNode = null       # pointer capture target

var _ids: Dictionary = {}
var _listeners: Dictionary = {}
var _style_dirty := true
var _layout_dirty := true
var _paint_dirty := true
var _scroll_dirty := false
var _sheets_seen: Dictionary = {}
var _hover_chain: Array = []
var _active_node: DomNode = null
var _down_target: DomNode = null
var _drag: Dictionary = {}
var _last_mouse := Vector2.ZERO
var _css_generation := -1
var page_scroll := 0.0
var anims: DomAnim
var ready_done := false

func _ready() -> void:
	process_priority = 100     # after JS timers / animation frames
	layout = DomLayout.new(self)
	painter = DomPaint.new(self)
	anims = DomAnim.new(self)
	premult_material = CanvasItemMaterial.new()
	premult_material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	head = DomNode.new("head", self)
	root = DomNode.new("body", self)
	host = DomHost.new()
	host.doc = self
	host.name = "DomHost"
	add_child(host)
	host_rid = host.get_canvas_item()
	_update_viewport()
	get_viewport().size_changed.connect(_on_resize)

func load_page(html_path: String, css_paths: Array) -> void:
	for p in css_paths:
		var f := FileAccess.open(p, FileAccess.READ)
		if f != null: css.add_sheet(f.get_as_text())
	var f2 := FileAccess.open(html_path, FileAccess.READ)
	var html := f2.get_as_text() if f2 != null else ""
	var a := html.find("<body")
	var b := html.rfind("</body>")
	if a >= 0:
		a = html.find(">", a) + 1
		html = html.substr(a, (b if b > a else html.length()) - a)
	for n in HtmlParser.parse(html, self):
		n._parent = weakref(root)
		root.childNodes.append(n)
	_reindex(root)
	mark_style(root)
	ready_done = true

func _reindex(n: DomNode) -> void:
	if n._id != "": _ids[n._id] = weakref(n)
	for c in n.childNodes:
		if c.nodeType == DomNode.ELEMENT: _reindex(c)

func _update_viewport() -> void:
	var vs := Vector2(get_viewport().get_visible_rect().size)
	viewport_size = vs
	host.position = Vector2.ZERO
	host.size = vs

func _on_resize() -> void:
	_update_viewport()
	css.set_viewport(viewport_size)
	mark_style(root)
	_layout_dirty = true
	window.dispatch_window_event("resize")

# ───────────────────────── DOM API ─────────────────────────
func getElementById(id_):
	if id_ == null: return null
	var key := JS.s(id_)
	var ref = _ids.get(key)
	if ref != null:
		var n: DomNode = ref.get_ref()
		if n != null and n._id == key and n.is_connected_to_doc(): return n
	# index miss: nodes created via innerHTML are indexed lazily
	var found := _find_id(root, key)
	if found != null: _ids[key] = weakref(found)
	else: _ids.erase(key)
	return found

func _find_id(n: DomNode, key: String) -> DomNode:
	if n._id == key: return n
	for c in n.childNodes:
		if c.nodeType == DomNode.ELEMENT:
			var r := _find_id(c, key)
			if r != null: return r
	return null

func _index_id(n: DomNode) -> void:
	if n._id != "": _ids[n._id] = weakref(n)

func _unindex_id(n: DomNode) -> void:
	if n._id != "" and _ids.has(n._id) and _ids[n._id].get_ref() == n: _ids.erase(n._id)

func createElement(tag_) -> DomNode:
	return DomNode.new(JS.s(tag_).to_lower(), self)

func createElementNS(_ns, tag_) -> DomNode:
	return DomNode.new(JS.s(tag_), self)

func createTextNode(text) -> DomNode:
	var n := DomNode.new("#text", self)
	n.nodeType = DomNode.TEXT
	n.data = JS.s(text)
	return n

func createDocumentFragment() -> DomNode:
	return DomNode.new("fragment", self)

func querySelector(sel):
	return query(root, JS.s(sel), true)

func querySelectorAll(sel) -> Array:
	return query(root, JS.s(sel), false)

func getElementsByClassName(cls) -> Array:
	return query(root, "." + JS.s(cls), false)

var _sel_cache: Dictionary = {}
func _selectors(sel: String) -> Array:
	if _sel_cache.has(sel): return _sel_cache[sel]
	var out := []
	for part in CssEngine._split_top(sel, ","):
		var parsed := css._parse_selector(part.strip_edges())
		if not parsed.is_empty(): out.append(parsed.compounds)
	_sel_cache[sel] = out
	return out

func matches(n: DomNode, sel: String) -> bool:
	for s in _selectors(sel):
		if css._match_rule(n, s): return true
	return false

func query(scope: DomNode, sel: String, first: bool):
	var sels := _selectors(sel)
	var out := []
	_query(scope, sels, first, out)
	if first: return out[0] if out.size() > 0 else null
	return out

func _query(n: DomNode, sels: Array, first: bool, out: Array) -> void:
	for c in n.childNodes:
		if c.nodeType != DomNode.ELEMENT: continue
		for s in sels:
			if css._match_rule(c, s):
				out.append(c)
				break
		if first and out.size() > 0: return
		_query(c, sels, first, out)
		if first and out.size() > 0: return

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

# ───────────────────────── invalidation ─────────────────────────
func mark_style(n: DomNode) -> void:
	n.style_dirty = true
	_style_dirty = true
	if n == head: _scan_styles(head)

func mark_layout(_n: DomNode) -> void:
	_layout_dirty = true

func mark_paint(n: DomNode) -> void:
	n.paint_dirty = true
	_paint_dirty = true

func mark_scroll(n: DomNode) -> void:
	_paint_dirty = true
	_scroll_dirty = true

func _style_element_changed(el: DomNode) -> void:
	_sheets_seen.erase(el.get_instance_id())
	if el.is_connected_to_doc() or el.parentElement == head: _register_sheet(el)

func _scan_styles(n: DomNode) -> void:
	for c in n.childNodes:
		if c.nodeType == DomNode.ELEMENT and c.tag == "style": _register_sheet(c)

func _register_sheet(el: DomNode) -> void:
	var text = el.textContent
	if _sheets_seen.get(el.get_instance_id(), "") == text: return
	_sheets_seen[el.get_instance_id()] = text
	css.add_sheet(text)
	mark_style(root)

# ───────────────────────── frame ─────────────────────────
var perf_flush_usec := 0

func _process(_dt: float) -> void:
	if not ready_done: return
	var t0 := Time.get_ticks_usec()
	flush()
	perf_flush_usec = Time.get_ticks_usec() - t0

func ensure_layout() -> void:
	if _style_dirty or css.generation != _css_generation: _restyle_pass()
	if _layout_dirty: _layout_pass()

func flush() -> void:
	var animating := anims.tick()
	ensure_layout()
	if _paint_dirty or animating:
		_paint_dirty = false
		_scroll_dirty = false
		painter.seq = 0
		_apply_page_scroll()
		painter.paint_tree(root, host_rid, 0, false, 0)

func _apply_page_scroll() -> void:
	var maxs := maxf(0.0, root.lh + root.mar[0] + root.mar[2] - viewport_size.y)
	page_scroll = clampf(page_scroll, 0.0, maxs)
	root.ly = root.mar[0] - page_scroll

func _restyle_pass() -> void:
	var force := css.generation != _css_generation
	_css_generation = css.generation
	_style_dirty = false
	_restyle(root, {}, force)

func _layout_pass() -> void:
	_layout_dirty = false
	layout.run(root, viewport_size)
	JSResizeObserver.check_all.call_deferred()
	_repaint_all(root)
	_paint_dirty = true

func _repaint_all(n: DomNode) -> void:
	n.paint_dirty = true
	if n._before != null: n._before.paint_dirty = true
	if n._after != null: n._after.paint_dirty = true
	for c in n.childNodes:
		if c.nodeType == DomNode.ELEMENT and c.st.get("display", "none") != "none": _repaint_all(c)

# Recompute styles. `force` → whole subtree, otherwise only flagged nodes and their subtrees.
func _restyle(n: DomNode, parent_cs: Dictionary, force: bool) -> void:
	if n.tag == "style":
		if not _sheets_seen.has(n.get_instance_id()): _register_sheet(n)
	var do_it := force or n.style_dirty or n.cs.is_empty()
	if do_it:
		n.style_dirty = false
		var old := n.cs
		var old_display = n.st.get("display", "none")
		n.cs = css.compute(n, parent_cs)
		_resolve(n)
		var changed := false
		var layout_change := false
		if old.size() != n.cs.size():
			changed = true; layout_change = true
		else:
			for k in n.cs.keys():
				if old.get(k) != n.cs[k]:
					changed = true
					if not DomStyle.PAINT_ONLY.has(k): layout_change = true
		if layout_change or old_display != n.st.display: _layout_dirty = true
		if changed:
			n.paint_dirty = true
			_paint_dirty = true
		anims.style_changed(n, old)
		force = true
		_pseudo(n)
	if n.st.get("display", "none") == "none":
		# hidden subtree: defer styling until it is shown
		if do_it: _defer(n)
		return
	for c in n.childNodes:
		if c.nodeType == DomNode.ELEMENT:
			if force or c.style_dirty or c.cs.is_empty() or c.st.get("_sub", false) or true:
				_restyle(c, n.cs, force)

func _defer(n: DomNode) -> void:
	for c in n.childNodes:
		if c.nodeType == DomNode.ELEMENT and not c.style_dirty:
			c.style_dirty = true

func _pseudo(n: DomNode) -> void:
	for which in ["before", "after"]:
		var rules := css.matching_rules(n, which) if css.has_pseudo(n) else []
		var cur: DomNode = n._before if which == "before" else n._after
		if rules.is_empty():
			if cur != null:
				cur._release_render()
				if which == "before": n._before = null
				else: n._after = null
				_layout_dirty = true
			continue
		if cur == null:
			cur = DomNode.new("::" + which, self)
			cur.pseudo = which
			cur._parent = weakref(n)
			if which == "before": n._before = cur
			else: n._after = cur
			_layout_dirty = true
		cur.cs = css.compute(cur, n.cs, which)
		if not cur.cs.has("display"): cur.cs["display"] = "inline"
		var content: String = cur.cs.get("content", "none")
		var text := ""
		if content == "none" or content == "normal": cur.cs["display"] = "none"
		elif content.begins_with("attr("):
			var an := content.substr(5, content.length() - 6).strip_edges()
			var av = n.getAttribute(an)
			text = "" if av == null else str(av)
		else: text = content.trim_prefix("'").trim_suffix("'").trim_prefix("\"").trim_suffix("\"")
		if cur.childNodes.size() == 0 or cur.childNodes[0].data != text:
			cur.childNodes.clear()
			if text != "":
				var tn := createTextNode(text)
				tn._parent = weakref(cur)
				cur.childNodes.append(tn)
			_layout_dirty = true
		_resolve(cur)
		cur.paint_dirty = true

# typed style values used by layout and painting
func _resolve(n: DomNode) -> void:
	var cs := n.cs
	var keep := {}
	for k in ["_shown", "_parent_rid", "_sb_rid", "_xf"]:
		if n.st.has(k): keep[k] = n.st[k]
	var st := keep
	var disp: String = cs.get("display", "inline")
	if n.attrs.has("hidden") and not n.style._props.has("display"): disp = "none"
	st["position"] = cs.get("position", "static")
	if st.position == "sticky": st.position = "relative"
	# flex/grid items are blockified
	var p := n.parentElement
	if p != null and p.st.has("display"):
		var pd: String = p.st.display
		if pd == "flex" or pd == "inline-flex" or pd == "grid" or pd == "inline-grid":
			st["flex_item"] = true
			if disp == "inline" or disp == "inline-block": disp = "block"
			elif disp == "inline-flex": disp = "flex"
	if st.position == "absolute" or st.position == "fixed":
		if disp == "inline" or disp == "inline-block": disp = "block"
		elif disp == "inline-flex": disp = "flex"
	st["display"] = disp
	var fs: float = CssValue.f(cs.get("font-size", "16px"))
	st["fs"] = fs
	var weight: String = cs.get("font-weight", "normal")
	var bold := weight == "bold" or weight == "bolder" or (weight.is_valid_int() and weight.to_int() >= 600)
	var italic: bool = cs.get("font-style", "normal") == "italic"
	var ls := 0.0
	var lsv: String = cs.get("letter-spacing", "normal")
	if lsv != "normal": ls = maxf(-4.0, CssValue.length(lsv, 0.0, fs, viewport_size))
	if ls <= CssValue.AUTO + 1.0: ls = 0.0
	st["ls"] = ls
	var font := DomFonts.font(cs.get("font-family", "serif"), bold, italic, ls)
	st["font"] = font
	st["asc"] = DomFonts.ascent(font, fs)
	st["desc"] = DomFonts.descent(font, fs)
	var lhv: String = cs.get("line-height", "normal")
	var lh: float
	if lhv == "normal": lh = (st.asc + st.desc)
	elif lhv.is_valid_float(): lh = CssValue.f(lhv) * fs
	else:
		lh = CssValue.length(lhv, fs, fs, viewport_size)
		if lh <= CssValue.AUTO + 1.0: lh = st.asc + st.desc
	st["lh"] = lh
	st["color"] = CssValue.color(cs.get("color", "#000"), Color(0, 0, 0, 1))
	st["ws"] = cs.get("white-space", "normal")
	st["ta"] = cs.get("text-align", "left")
	if st.ta == "start": st.ta = "left"
	st["tt"] = cs.get("text-transform", "none")
	st["break_word"] = cs.get("word-break", "normal") != "normal" or cs.get("overflow-wrap", "normal") != "normal" or cs.get("word-wrap", "normal") != "normal"
	st["visible"] = cs.get("visibility", "visible") == "visible"
	st["opacity"] = clampf(CssValue.f(cs.get("opacity", "1")), 0.0, 1.0)
	var zv: String = cs.get("z-index", "auto")
	st["z"] = zv.to_int() if zv != "auto" else null
	st["pe"] = cs.get("pointer-events", "auto") != "none"
	var bgc: String = cs.get("background-color", "transparent")
	var bg := CssValue.color(bgc, Color(0, 0, 0, 0))
	if not CssValue.is_color(bgc):
		# "background: <color> <other tokens>" — pick the first colour-looking token
		for tok in CssEngine.split_ws(bgc):
			if CssValue.is_color(tok):
				bg = CssValue.color(tok)
				break
	st["bg"] = bg
	var bgi: String = cs.get("background-image", "none")
	st["has_bg"] = bg.a > 0.0 or bgi != "none"
	var has_border := false
	for side in ["top", "right", "bottom", "left"]:
		var bs = cs.get("border-" + side + "-style")
		if bs != null and bs != "none" and bs != "hidden": has_border = true
	var bsh: String = cs.get("box-shadow", "none")
	st["box_shadows"] = CssValue.shadows(bsh, fs, viewport_size) if bsh != "none" else null
	st["has_box"] = st.has_bg or has_border or bsh != "none"
	var tsh: String = cs.get("text-shadow", "none")
	st["shadows"] = CssValue.shadows(tsh, fs, viewport_size) if tsh != "none" else null
	var ox: String = cs.get("overflow-x", "visible"); var oy: String = cs.get("overflow-y", "visible")
	st["clip"] = ox != "visible" or oy != "visible"
	st["scrollable"] = oy == "auto" or oy == "scroll"
	var tf: String = cs.get("transform", "none")
	st["transform"] = tf if tf != "none" else null
	var fl: String = cs.get("filter", "none")
	st["filter"] = fl if fl != "none" else null
	st["cursor"] = cs.get("cursor", "auto")
	n.st = st

# ───────────────────────── geometry ─────────────────────────
# border box in viewport coordinates
func client_rect(n: DomNode) -> Rect2:
	var pos := Vector2.ZERO
	var size := Vector2(n.lw, n.lh)
	var cur: DomNode = n
	while cur != null:
		pos += Vector2(cur.lx, cur.ly)
		var tf = cur.st.get("transform")
		if tf != null:
			var m := CssValue.transform(tf, Vector2(cur.lw, cur.lh), cur.st.fs, viewport_size)
			pos += m.origin
		if cur.st.get("position") == "fixed": break
		var p := cur.parentElement
		if p != null: pos -= Vector2(p._scroll_x, p._scroll_y)
		elif cur == root: pos.y -= page_scroll
		cur = p
	return Rect2(pos, size)

func scroll_into_view(n: DomNode) -> void:
	ensure_layout()
	var p := n.parentElement
	while p != null:
		if p.st.get("scrollable", false) and p.content_h > p.lh:
			var y := 0.0
			var c: DomNode = n
			while c != null and c != p:
				y += c.ly
				c = c.parentElement
			if y < p._scroll_y: p.scrollTop = y
			elif y + n.lh > p._scroll_y + p.lh: p.scrollTop = y + n.lh - p.lh
			return
		p = p.parentElement

# ───────────────────────── hit testing ─────────────────────────
func hit_test(pt: Vector2) -> DomNode:
	ensure_layout()
	var best := [null, -99999, -1]
	_hit(root, pt + Vector2(0, 0), best, true, 0)
	return best[0]

func _hit(n: DomNode, pt: Vector2, best: Array, events: bool, depth: int) -> void:
	var s := n.st
	if s.get("display", "none") == "none" or not s.get("visible", true): return
	var xf = s.get("_xf")
	if xf == null: return
	var local: Vector2 = (xf as Transform2D).affine_inverse() * pt
	if s.position == "fixed" and depth > 0:
		# fixed boxes live in viewport space
		local = (xf as Transform2D).affine_inverse() * _last_hit_viewport
	var inside := local.x >= 0.0 and local.y >= 0.0 and local.x < n.lw and local.y < n.lh
	if s.clip and not inside: return
	var ev: bool = s.pe
	if ev and inside and (n.eff_z > best[1] or (n.eff_z == best[1] and n.paint_seq > best[2])):
		best[0] = n; best[1] = n.eff_z; best[2] = n.paint_seq
	if n._before != null: _hit(n._before, local, best, ev, depth + 1)
	for c in n.childNodes:
		if c.nodeType == DomNode.ELEMENT: _hit(c, local, best, ev, depth + 1)
	if n._after != null: _hit(n._after, local, best, ev, depth + 1)

var _last_hit_viewport := Vector2.ZERO

func element_at(pt: Vector2) -> DomNode:
	_last_hit_viewport = pt
	var n := hit_test(pt)
	# pseudo-elements resolve to their owner
	while n != null and n.pseudo != "": n = n.parentElement
	return n

func elementFromPoint(x, y) -> DomNode:
	return element_at(Vector2(x, y))

# ───────────────────────── events ─────────────────────────
func dispatch(target: DomNode, ev: DomEvent) -> void:
	if ev.target == null: ev.target = target
	var path := []
	var n: DomNode = target
	while n != null:
		path.append(n)
		n = n.parentElement
	for node in path:
		ev.currentTarget = node
		_fire(node, ev)
		if ev._stopped or not ev.bubbles: break
	if not ev._stopped and ev.bubbles:
		ev.currentTarget = self
		_fire_list(_listeners.get(ev.type), ev, self)
		if not ev._stopped: window.fire(ev)

func _fire(node: DomNode, ev: DomEvent) -> void:
	var h = node._on.get("on" + ev.type)
	if h != null and not (node._disabled and ev.type == "click"):
		if h is Callable: JS.invoke(h, [ev])
		elif h is String: InlineJS.run(h, node, ev)
		if ev._stopped_now: return
	var list = node._listeners.get(ev.type)
	if list != null: _fire_list(list, ev, node)

func _fire_list(list, ev: DomEvent, _owner) -> void:
	if list == null: return
	for l in list.duplicate():
		if l.once: list.erase(l)
		JS.invoke(l.fn, [ev])
		if ev._stopped_now: return

func dispatch_document_event(ev: DomEvent) -> void:
	ev.currentTarget = self
	_fire_list(_listeners.get(ev.type), ev, self)
	if not ev._stopped: window.fire(ev)

func _mouse_event(type_: String, target: DomNode, pos: Vector2, button := 0, buttons := 0) -> DomEvent:
	var ev := DomEvent.new(type_)
	ev.target = target
	ev.clientX = pos.x; ev.clientY = pos.y
	ev.pageX = pos.x; ev.pageY = pos.y + page_scroll
	ev.screenX = pos.x; ev.screenY = pos.y
	ev.button = button; ev.buttons = buttons
	if target != null:
		var r := client_rect(target)
		ev.offsetX = pos.x - r.position.x; ev.offsetY = pos.y - r.position.y
	return ev

func _set_hover(target: DomNode, pos: Vector2) -> void:
	var chain := []
	var n: DomNode = target
	while n != null:
		chain.append(n)
		n = n.parentElement
	if chain.size() == _hover_chain.size() and (chain.is_empty() or chain[0] == _hover_chain[0]): return
	var old := _hover_chain
	_hover_chain = chain
	for o in old:
		if not chain.has(o):
			o._hover = false
			if _hover_sensitive(o): mark_style(o)
			var e := _mouse_event("mouseleave", o, pos)
			e.bubbles = false
			e.currentTarget = o
			_fire(o, e)
			var e2 := _mouse_event("pointerleave", o, pos)
			e2.bubbles = false
			_fire(o, e2)
	if old.size() > 0 and (chain.is_empty() or old[0] != chain[0]):
		dispatch(old[0], _mouse_event("mouseout", old[0], pos))
	for i in range(chain.size() - 1, -1, -1):
		var c: DomNode = chain[i]
		if not old.has(c):
			c._hover = true
			if _hover_sensitive(c): mark_style(c)
			var e3 := _mouse_event("mouseenter", c, pos)
			e3.bubbles = false
			e3.currentTarget = c
			_fire(c, e3)
			var e4 := _mouse_event("pointerenter", c, pos)
			e4.bubbles = false
			_fire(c, e4)
	if chain.size() > 0: dispatch(chain[0], _mouse_event("mouseover", chain[0], pos))
	# cursor
	var cur := "auto"
	if target != null: cur = target.st.get("cursor", "auto")
	host.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if cur == "pointer" else (Control.CURSOR_MOVE if cur == "grab" or cur == "grabbing" or cur == "move" else Control.CURSOR_ARROW)

func _hover_sensitive(n: DomNode) -> bool:
	if css.hover_keys.has("*") or css.hover_keys.has(n.tag): return true
	if n._id != "" and css.hover_keys.has("#" + n._id): return true
	for cl in n.classes:
		if css.hover_keys.has("." + cl): return true
	return false

func pointer_moved(pos: Vector2, buttons: int, touch := false) -> void:
	_last_mouse = pos
	var target := capture if capture != null else element_at(pos)
	if capture == null: _set_hover(target, pos)
	if target == null: target = root
	var pe := _mouse_event("pointermove", target, pos, 0, buttons)
	pe.pointerType = "touch" if touch else "mouse"
	dispatch(target, pe)
	dispatch(target, _mouse_event("mousemove", target, pos, 0, buttons))
	if not _drag.is_empty(): _drag_move(pos)
	elif _down_target != null and buttons != 0 and _drag_candidate != null and pos.distance_to(_down_pos) > 5.0:
		_drag_start(_drag_candidate, pos)

var _down_pos := Vector2.ZERO
var _drag_candidate: DomNode = null

func pointer_down(pos: Vector2, button: int, touch := false) -> void:
	_last_mouse = pos
	var target := element_at(pos)
	_set_hover(target, pos)
	if target == null: target = root
	_down_target = target
	_down_pos = pos
	if button == 0:
		if _active_node != null:
			_active_node._active = false
			mark_style(_active_node)
		_active_node = target
		var a: DomNode = target
		while a != null:
			a._active = true
			a = a.parentElement
		if _hover_sensitive(target): mark_style(target)
		# HTML5 drag & drop candidate
		_drag_candidate = null
		var d: DomNode = target
		while d != null:
			if d.attrs.get("draggable", "") == "true":
				_drag_candidate = d
				break
			d = d.parentElement
	var pe := _mouse_event("pointerdown", target, pos, button, 1)
	pe.pointerType = "touch" if touch else "mouse"
	dispatch(target, pe)
	dispatch(target, _mouse_event("mousedown", target, pos, button, 1))
	if touch: _touch_event("touchstart", target, pos)

func pointer_up(pos: Vector2, button: int, touch := false) -> void:
	_last_mouse = pos
	var target := capture if capture != null else element_at(pos)
	if target == null: target = root
	if not _drag.is_empty():
		_drag_end(pos)
		_down_target = null
		_clear_active()
		return
	var pe := _mouse_event("pointerup", target, pos, button, 0)
	pe.pointerType = "touch" if touch else "mouse"
	dispatch(target, pe)
	dispatch(target, _mouse_event("mouseup", target, pos, button, 0))
	if touch: _touch_event("touchend", target, pos)
	capture = null
	var down := _down_target
	_down_target = null
	_drag_candidate = null
	_clear_active()
	if button == 0 and down != null:
		# click goes to the common ancestor of press and release
		var click_target: DomNode = null
		var n: DomNode = down
		while n != null:
			if n == target or n.contains(target):
				click_target = n
				break
			n = n.parentElement
		if click_target != null and pos.distance_to(_down_pos) < 12.0 or (click_target != null and click_target == target):
			var d: DomNode = click_target
			var blocked := false
			while d != null:
				if d._disabled: blocked = true
				d = d.parentElement
			if not blocked: dispatch(click_target, _mouse_event("click", click_target, pos, 0, 0))
	elif button == 2 and down != null:
		dispatch(target, _mouse_event("contextmenu", target, pos, 2, 0))

func _clear_active() -> void:
	if _active_node != null:
		var a: DomNode = _active_node
		while a != null:
			a._active = false
			a = a.parentElement
		if _hover_sensitive(_active_node): mark_style(_active_node)
		_active_node = null

func _touch_event(type_: String, target: DomNode, pos: Vector2) -> void:
	var ev := _mouse_event(type_, target, pos)
	var t := {"clientX": pos.x, "clientY": pos.y, "pageX": pos.x, "pageY": pos.y, "identifier": 0, "target": target}
	ev.changedTouches = [t]
	ev.touches = [] if type_ == "touchend" else [t]
	ev.targetTouches = ev.touches
	dispatch(target, ev)

func wheel(pos: Vector2, dy: float) -> void:
	var target := element_at(pos)
	var ev := _mouse_event("wheel", target if target != null else root, pos)
	ev.deltaY = dy
	dispatch(ev.target, ev)
	if ev.defaultPrevented: return
	scroll_by(target, dy)

func scroll_by(target: DomNode, dy: float) -> void:
	var n: DomNode = target
	while n != null:
		if n.st.get("scrollable", false):
			var view: float = n.lh - n.bor[0] - n.bor[2]
			var maxs: float = n.content_h - view
			if maxs > 1.0 and ((dy > 0 and n._scroll_y < maxs - 0.5) or (dy < 0 and n._scroll_y > 0.5)):
				n.scrollTop = n._scroll_y + dy
				var se := DomEvent.new("scroll")
				se.bubbles = false
				se.target = n; se.currentTarget = n
				_fire(n, se)
				return
		n = n.parentElement
	var before := page_scroll
	page_scroll = clampf(page_scroll + dy, 0.0, maxf(0.0, root.lh + root.mar[0] + root.mar[2] - viewport_size.y))
	if page_scroll != before: _paint_dirty = true

func key_event(type_: String, key: String, code: String, e: InputEventKey) -> void:
	var ev := DomEvent.new(type_)
	ev.key = key; ev.code = code
	ev.ctrlKey = e.ctrl_pressed; ev.shiftKey = e.shift_pressed; ev.altKey = e.alt_pressed; ev.metaKey = e.meta_pressed
	ev.repeat = e.echo
	ev.keyCode = e.keycode; ev.which = e.keycode
	ev.target = root
	dispatch_document_event(ev)

# ── HTML5 drag and drop (used for re-ordering queued actions) ──
func _drag_start(n: DomNode, pos: Vector2) -> void:
	var dt := JSDataTransfer.new()
	var ev := _mouse_event("dragstart", n, pos)
	ev.dataTransfer = dt
	dispatch(n, ev)
	if ev.defaultPrevented:
		_drag_candidate = null
		return
	_drag = {"node": n, "dt": dt, "over": null}
	_drag_candidate = null

func _drag_move(pos: Vector2) -> void:
	var over := element_at(pos)
	if over == null: return
	if _drag.over != over:
		if _drag.over != null:
			var le := _mouse_event("dragleave", _drag.over, pos)
			le.dataTransfer = _drag.dt
			dispatch(_drag.over, le)
		_drag.over = over
		var ee := _mouse_event("dragenter", over, pos)
		ee.dataTransfer = _drag.dt
		dispatch(over, ee)
	var ev := _mouse_event("dragover", over, pos)
	ev.dataTransfer = _drag.dt
	dispatch(over, ev)
	_drag["allowed"] = ev.defaultPrevented

func _drag_end(pos: Vector2) -> void:
	var over := element_at(pos)
	var d := _drag
	_drag = {}
	if over != null:
		var ov := _mouse_event("dragover", over, pos)
		ov.dataTransfer = d.dt
		dispatch(over, ov)
		if ov.defaultPrevented:
			var ev := _mouse_event("drop", over, pos)
			ev.dataTransfer = d.dt
			dispatch(over, ev)
	var ee := _mouse_event("dragend", d.node, pos)
	ee.dataTransfer = d.dt
	dispatch(d.node, ee)

# ───────────────────────── native controls for <input> ─────────────────────────
func ensure_control(n: DomNode) -> void:
	if n.control != null and is_instance_valid(n.control): return
	var kind: String = n.attrs.get("type", "text")
	if kind == "range":
		var sl := HSlider.new()
		sl.min_value = float(n.attrs.get("min", "0"))
		sl.max_value = float(n.attrs.get("max", "100"))
		sl.step = float(n.attrs.get("step", "1"))
		sl.value = CssValue.f(n._value)
		sl.focus_mode = Control.FOCUS_NONE
		sl.value_changed.connect(func(_v):
			var ev := DomEvent.new("input")
			dispatch(n, ev)
			dispatch(n, DomEvent.new("change")))
		var accent := CssValue.color(n.cs.get("accent-color", "#c8a060"), Color("#c8a060"))
		var line := StyleBoxFlat.new()
		line.bg_color = Color(accent.r, accent.g, accent.b, 0.35)
		line.content_margin_top = 1; line.content_margin_bottom = 1
		var fill := StyleBoxFlat.new()
		fill.bg_color = accent
		fill.content_margin_top = 1; fill.content_margin_bottom = 1
		sl.add_theme_stylebox_override("slider", line)
		sl.add_theme_stylebox_override("grabber_area", fill)
		sl.add_theme_stylebox_override("grabber_area_highlight", fill)
		var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		for y in range(8):
			for x in range(8):
				var d := Vector2(x - 3.5, y - 3.5).length()
				img.set_pixel(x, y, Color(accent.r, accent.g, accent.b, clampf(4.2 - d, 0.0, 1.0)))
		var tex := ImageTexture.create_from_image(img)
		sl.add_theme_icon_override("grabber", tex)
		sl.add_theme_icon_override("grabber_highlight", tex)
		n.control = sl
	else:
		var le := LineEdit.new()
		le.text = n._value
		le.placeholder_text = n.attrs.get("placeholder", "")
		if n.attrs.has("maxlength"): le.max_length = int(n.attrs["maxlength"])
		var sb := StyleBoxEmpty.new()
		sb.content_margin_left = n.pad[3] + n.bor[3]; sb.content_margin_right = n.pad[1] + n.bor[1]
		le.add_theme_stylebox_override("normal", sb)
		le.add_theme_stylebox_override("focus", sb)
		le.add_theme_font_override("font", n.st.font)
		le.add_theme_font_size_override("font_size", int(round(n.st.fs)))
		le.add_theme_color_override("font_color", n.st.color)
		le.add_theme_color_override("font_placeholder_color", Color(n.st.color.r, n.st.color.g, n.st.color.b, 0.45))
		le.add_theme_color_override("caret_color", n.st.color)
		le.text_changed.connect(func(_t): dispatch(n, DomEvent.new("input")))
		le.text_submitted.connect(func(_t):
			var ev := DomEvent.new("keydown")
			ev.key = "Enter"
			dispatch(n, ev))
		le.focus_entered.connect(func():
			n._focus = true
			activeElement = n
			mark_style(n))
		le.focus_exited.connect(func():
			n._focus = false
			mark_style(n))
		n.control = le
	host.add_child(n.control)
