# DomLayout — box layout for the DOM tree: block flow, inline text, flexbox, simple grids
# and absolute / fixed positioning.  Results are stored on each DomNode
# (lx, ly, lw, lh = border box relative to the parent's border box).
class_name DomLayout
extends RefCounted

const AUTO := CssValue.AUTO
const FILL := 0
const FIT := 1

var doc
var vp := Vector2(1280, 720)
var pass_id := 0
var fixed_nodes: Array = []

func _init(doc_) -> void:
	doc = doc_

# ───────────────────────── helpers ─────────────────────────
static func is_auto(v: float) -> bool:
	return v <= AUTO + 1.0

func L(n: DomNode, prop: String, base: float) -> float:
	return CssValue.length(n.cs.get(prop), base, n.st.fs, vp)

func display_of(n: DomNode) -> String:
	if n.nodeType == DomNode.TEXT: return "inline"
	return n.st.get("display", "none")

func is_out_of_flow(n: DomNode) -> bool:
	if n.nodeType == DomNode.TEXT: return false
	var p: String = n.st.position
	return p == "absolute" or p == "fixed"

func is_inline_level(n: DomNode) -> bool:
	if n.nodeType == DomNode.TEXT: return true
	var d: String = n.st.display
	return d == "inline" or d == "inline-block" or d == "inline-flex" or d == "inline-grid"

func is_atomic(n: DomNode) -> bool:
	if n.nodeType == DomNode.TEXT: return false
	var d: String = n.st.display
	if d == "inline-block" or d == "inline-flex" or d == "inline-grid": return true
	return d == "inline" and (n.tag == "canvas" or n.tag == "svg" or n.tag == "img" or n.tag == "input")

func metrics(n: DomNode, cb_w: float) -> void:
	var base := 0.0 if is_auto(cb_w) else cb_w
	var cs := n.cs
	var fs: float = n.st.fs
	n.pad[0] = maxf(0.0, _len0(cs.get("padding-top"), base, fs)); n.pad[1] = maxf(0.0, _len0(cs.get("padding-right"), base, fs))
	n.pad[2] = maxf(0.0, _len0(cs.get("padding-bottom"), base, fs)); n.pad[3] = maxf(0.0, _len0(cs.get("padding-left"), base, fs))
	n.bor[0] = _border(cs, "top", fs); n.bor[1] = _border(cs, "right", fs); n.bor[2] = _border(cs, "bottom", fs); n.bor[3] = _border(cs, "left", fs)
	n.mar[0] = _len0(cs.get("margin-top"), base, fs); n.mar[1] = _len0(cs.get("margin-right"), base, fs)
	n.mar[2] = _len0(cs.get("margin-bottom"), base, fs); n.mar[3] = _len0(cs.get("margin-left"), base, fs)

func _len0(v, base: float, fs: float) -> float:
	if v == null: return 0.0
	var r := CssValue.length(v, base, fs, vp)
	return 0.0 if is_auto(r) else r

func _border(cs: Dictionary, side: String, fs: float) -> float:
	var style = cs.get("border-" + side + "-style")
	if style == null or style == "none" or style == "hidden": return 0.0
	var w = cs.get("border-" + side + "-width")
	if w == null: return 3.0
	return maxf(0.0, _len0(w, 0.0, fs))

func margin_auto(n: DomNode, side: String) -> bool:
	return n.cs.get("margin-" + side) == "auto"

func hpad(n: DomNode) -> float:
	return n.pad[1] + n.pad[3] + n.bor[1] + n.bor[3]

func vpad(n: DomNode) -> float:
	return n.pad[0] + n.pad[2] + n.bor[0] + n.bor[2]

func border_box(n: DomNode) -> bool:
	return n.cs.get("box-sizing", "content-box") == "border-box"

# specified width as a border-box size, or AUTO
func spec_w(n: DomNode, cb_w: float, prop: String = "width") -> float:
	var v := L(n, prop, cb_w)
	if is_auto(v): return AUTO
	return v if border_box(n) else v + hpad(n)

func spec_h(n: DomNode, cb_h: float, prop: String = "height") -> float:
	var v := L(n, prop, cb_h)
	if is_auto(v): return AUTO
	return v if border_box(n) else v + vpad(n)

func clamp_w(n: DomNode, w: float, cb_w: float) -> float:
	var mx := spec_w(n, cb_w, "max-width")
	if not is_auto(mx): w = minf(w, mx)
	var mn := spec_w(n, cb_w, "min-width")
	if not is_auto(mn): w = maxf(w, mn)
	return maxf(w, 0.0)

func clamp_h(n: DomNode, h: float, cb_h: float) -> float:
	var mx := spec_h(n, cb_h, "max-height")
	if not is_auto(mx): h = minf(h, mx)
	var mn := spec_h(n, cb_h, "min-height")
	if not is_auto(mn): h = maxf(h, mn)
	return maxf(h, 0.0)

func flow_children(n: DomNode) -> Array:
	var out := []
	if n._before != null and display_of(n._before) != "none": out.append(n._before)
	for c in n.childNodes:
		if c.nodeType == DomNode.TEXT: out.append(c)
		elif c.st.display != "none": out.append(c)
	if n._after != null and display_of(n._after) != "none": out.append(n._after)
	return out

# ───────────────────────── entry point ─────────────────────────
func run(root: DomNode, viewport: Vector2) -> void:
	vp = viewport
	pass_id += 1
	fixed_nodes.clear()
	metrics(root, vp.x)
	layout_box(root, vp.x, vp.y, FILL, -1.0, -1.0)
	root.lx = root.mar[3]
	root.ly = root.mar[0]
	# fixed-position boxes use the viewport as their containing block
	var i := 0
	while i < fixed_nodes.size():
		place_abs(fixed_nodes[i], null, vp.x, vp.y)
		i += 1

# ───────────────────────── intrinsic sizes ─────────────────────────
# min-content / max-content border-box widths
func intrinsic(n: DomNode) -> Vector2:
	if n._ipass == pass_id: return Vector2(n._imin, n._imax)
	metrics(n, AUTO)
	var extra := hpad(n)
	var res := Vector2.ZERO
	var sw := AUTO
	var wv = n.cs.get("width")
	if wv != null and not CssValue.is_percent(wv): sw = spec_w(n, AUTO)
	if not is_auto(sw):
		res = Vector2(sw, sw)
	elif n.tag == "canvas":
		var cw := float(n._cw)
		var hv := L(n, "height", AUTO)
		if not is_auto(hv) and n._ch > 0: cw = hv * float(n._cw) / float(n._ch)
		res = Vector2(cw + extra, cw + extra)
	elif n.tag == "input":
		var iw := 129.0 if n.attrs.get("type", "text") == "range" else 150.0
		res = Vector2(iw + extra, iw + extra)
	elif n.tag == "svg":
		var sv := float(str(n.attrs.get("width", "300")).to_float())
		res = Vector2(sv + extra, sv + extra)
	else:
		var d: String = n.st.display
		var kids := flow_children(n)
		var inner := Vector2.ZERO
		if d == "flex" or d == "inline-flex":
			var row: bool = not n.cs.get("flex-direction", "row").begins_with("column")
			var gap := _len0(n.cs.get("column-gap"), 0.0, n.st.fs) if row else 0.0
			var count := 0
			var wrap: bool = n.cs.get("flex-wrap", "nowrap") != "nowrap"
			for c in _flex_items(n, kids):
				var ci := _intrinsic_outer(c)
				if row:
					inner.y += ci.y
					if wrap: inner.x = maxf(inner.x, ci.x)
					else: inner.x += ci.x
					count += 1
				else:
					inner.x = maxf(inner.x, ci.x); inner.y = maxf(inner.y, ci.y)
			if row and count > 1:
				inner.y += gap * (count - 1)
				if not wrap: inner.x += gap * (count - 1)
		elif d == "grid" or d == "inline-grid":
			var tracks := _grid_tracks(n, AUTO)
			var gap2 := _len0(n.cs.get("column-gap"), 0.0, n.st.fs)
			var total := gap2 * maxf(0.0, tracks.size() - 1)
			var fr_max := 0.0
			var items := _flex_items(n, kids)
			for t in tracks:
				if t[0] == "px": total += t[1]
			var has_fr := false
			for t in tracks:
				if t[0] != "px": has_fr = true
			if has_fr:
				for c in items: fr_max = maxf(fr_max, _intrinsic_outer(c).y)
				for t in tracks:
					if t[0] != "px": total += fr_max
			inner = Vector2(total, total)
		else:
			inner = _intrinsic_flow(n, kids)
		res = inner + Vector2(extra, extra)
	# min/max-width constraints that are not percentages
	var mxv = n.cs.get("max-width")
	if mxv != null and not CssValue.is_percent(mxv):
		var mx := spec_w(n, AUTO, "max-width")
		if not is_auto(mx): res = Vector2(minf(res.x, mx), minf(res.y, mx))
	var mnv = n.cs.get("min-width")
	if mnv != null and not CssValue.is_percent(mnv):
		var mn := spec_w(n, AUTO, "min-width")
		if not is_auto(mn): res = Vector2(maxf(res.x, mn), maxf(res.y, mn))
	if n.cs.get("overflow-x", "visible") != "visible" and is_auto(sw): res.x = minf(res.x, extra)
	n._imin = res.x; n._imax = res.y; n._ipass = pass_id
	return res

func _intrinsic_outer(c) -> Vector2:
	if c is Array:   # anonymous inline run
		return _measure_inline(c[0], c[1])
	var i := intrinsic(c)
	var m: float = c.mar[1] + c.mar[3]
	return Vector2(i.x + m, i.y + m)

func _intrinsic_flow(n: DomNode, kids: Array) -> Vector2:
	var res := Vector2.ZERO
	var run := []
	for c in kids:
		if is_out_of_flow(c): continue
		if is_inline_level(c): run.append(c)
		else:
			if run.size() > 0:
				var r := _measure_inline(n, run)
				res.x = maxf(res.x, r.x); res.y = maxf(res.y, r.y)
				run = []
			var ci := _intrinsic_outer(c)
			res.x = maxf(res.x, ci.x); res.y = maxf(res.y, ci.y)
	if run.size() > 0:
		var r2 := _measure_inline(n, run)
		res.x = maxf(res.x, r2.x); res.y = maxf(res.y, r2.y)
	return res

# ───────────────────────── inline content ─────────────────────────
# Flatten inline-level nodes into items:
#  ["w", text, node, width]  word      ["s", " ", node, width]  collapsible space
#  ["br"]                    forced break
#  ["a", node, width, height] atomic box
#  ["o", node, advance] / ["c", node, advance]   inline element open / close
func _inline_items(container: DomNode, nodes: Array, out: Array, style_node: DomNode) -> void:
	for c in nodes:
		if c.nodeType == DomNode.TEXT:
			_text_items(c.data, style_node, out)
			continue
		if c.st.display == "none": continue
		if is_out_of_flow(c):
			out.append(["abs", c])
			continue
		if c.tag == "br":
			out.append(["br"])
			continue
		if is_atomic(c):
			out.append(["a", c, 0.0, 0.0])
			continue
		metrics(c, AUTO)
		out.append(["o", c, c.mar[3] + c.bor[3] + c.pad[3]])
		_inline_items(container, flow_children(c), out, c)
		out.append(["c", c, c.mar[1] + c.bor[1] + c.pad[1]])

func _text_items(text: String, sn: DomNode, out: Array) -> void:
	var ws: String = sn.st.ws
	var tt: String = sn.st.tt
	if tt == "uppercase": text = text.to_upper()
	elif tt == "lowercase": text = text.to_lower()
	elif tt == "capitalize": text = text.capitalize()
	var font: Font = sn.st.font
	var fs: float = sn.st.fs
	var preserve := ws == "pre" or ws == "pre-wrap"
	var keep_nl := preserve or ws == "pre-line"
	var word := ""
	var n := text.length()
	var i := 0
	while i < n:
		var ch := text[i]
		var is_space := ch == " " or ch == "\t" or ch == "\n" or ch == "\r"
		if not is_space:
			word += ch
			i += 1
			continue
		if word != "":
			out.append(["w", word, sn, DomFonts.width(font, word, fs, sn.st.ls)])
			word = ""
		if ch == "\n" and keep_nl:
			out.append(["br"])
		elif preserve:
			out.append(["s", " ", sn, DomFonts.width(font, " ", fs, sn.st.ls), true])
		else:
			# collapse runs of white space
			if out.is_empty() or out[out.size() - 1][0] != "s":
				out.append(["s", " ", sn, DomFonts.width(font, " ", fs, sn.st.ls), false])
		i += 1
	if word != "": out.append(["w", word, sn, DomFonts.width(font, word, fs, sn.st.ls)])

func _measure_inline(container: DomNode, nodes: Array) -> Vector2:
	var items := []
	_inline_items(container, nodes, items, container)
	var minw := 0.0; var maxw := 0.0; var line := 0.0
	var nowrap_run := 0.0
	var pending_space := 0.0
	for it in items:
		match it[0]:
			"w":
				var nw: bool = it[2].st.ws == "nowrap" or it[2].st.ws == "pre"
				line += pending_space + it[3]
				if nw: nowrap_run += pending_space + it[3]
				else:
					nowrap_run = it[3]
				minw = maxf(minw, nowrap_run)
				pending_space = 0.0
			"s":
				if line > 0.0: pending_space = it[3]
				if not (it[2].st.ws == "nowrap" or it[2].st.ws == "pre"): nowrap_run = 0.0
			"br":
				maxw = maxf(maxw, line); line = 0.0; pending_space = 0.0; nowrap_run = 0.0
			"a":
				var ci := _intrinsic_outer(it[1])
				line += pending_space + ci.y
				minw = maxf(minw, ci.x)
				pending_space = 0.0
				nowrap_run = 0.0
			"o", "c":
				line += it[2]
	maxw = maxf(maxw, line)
	return Vector2(minw, maxw)

# Lay out an inline formatting context. Appends fragments to container.frags.
# Returns Vector2(max line width, total height).
func layout_inline(container: DomNode, nodes: Array, x0: float, y0: float, avail: float, cb_h: float) -> Vector2:
	var items := []
	_inline_items(container, nodes, items, container)
	var cst := container.st
	var strut_a: float = cst.asc + (cst.lh - (cst.asc + cst.desc)) * 0.5
	var strut_d: float = cst.lh - strut_a
	var align: String = cst.ta
	var lines := []          # each: {items:[...], w, asc, desc}
	var cur := []
	var cur_w := 0.0
	var pending = null       # pending space item
	var unbounded := is_auto(avail)
	var i := 0
	var open_stack := []     # inline elements currently open
	while i < items.size():
		var it = items[i]
		var kind: String = it[0]
		if kind == "abs":
			# static position: start of the current line
			cur.append(it)
		elif kind == "br":
			lines.append([cur, cur_w, true]); cur = []; cur_w = 0.0; pending = null
			for o in open_stack: cur.append(["o", o, 0.0])
		elif kind == "s":
			if it.size() > 4 and it[4]:
				cur.append(it); cur_w += it[3]
			elif cur_w > 0.0 or _has_content(cur): pending = it
		elif kind == "w" or kind == "a":
			var w: float
			if kind == "a":
				var box: DomNode = it[1]
				metrics(box, avail)
				layout_box(box, avail, cb_h, FIT, -1.0, -1.0)
				w = box.lw + box.mar[1] + box.mar[3]
				it[2] = w; it[3] = box.lh + box.mar[0] + box.mar[2]
			else:
				w = it[3]
			var nowrap: bool = (it[2].st.ws if kind == "w" else container.st.ws) in ["nowrap", "pre"]
			var sp: float = pending[3] if pending != null else 0.0
			if not unbounded and not nowrap and _has_content(cur) and cur_w + sp + w > avail + 0.01:
				lines.append([cur, cur_w, false]); cur = []; cur_w = 0.0; pending = null; sp = 0.0
				for o in open_stack: cur.append(["o", o, 0.0])
			if pending != null:
				cur.append(pending); cur_w += sp; pending = null
			# break very long words when allowed
			if kind == "w" and not unbounded and not nowrap and w > avail + 0.5 and it[2].st.get("break_word", false) and avail > 8.0:
				var parts := _break_word(it, avail - cur_w, avail)
				for pi in range(parts.size()):
					if pi > 0:
						lines.append([cur, cur_w, false]); cur = []; cur_w = 0.0
					cur.append(parts[pi]); cur_w += parts[pi][3]
			else:
				cur.append(it); cur_w += w
		elif kind == "o":
			open_stack.append(it[1])
			cur.append(it); cur_w += it[2]
		elif kind == "c":
			open_stack.pop_back()
			cur.append(it); cur_w += it[2]
		i += 1
	if cur.size() > 0: lines.append([cur, cur_w, true])
	# position the lines
	var y := y0
	var max_w := 0.0
	var ellipsis: bool = container.cs.get("text-overflow") == "ellipsis" and container.cs.get("overflow-x", "visible") != "visible"
	for ln in lines:
		var litems: Array = ln[0]
		var lw: float = ln[1]
		if not _has_content(litems) and not _has_break_only(ln):
			# only open/close markers: no line box, but keep abs children anchored
			for it in litems:
				if it[0] == "abs": _static_pos(it[1], x0, y)
			continue
		var asc := 0.0; var desc := 0.0
		var any_text := false
		for it in litems:
			if it[0] == "w" or it[0] == "s":
				var s: Dictionary = it[2].st
				var a: float = s.asc + (s.lh - (s.asc + s.desc)) * 0.5
				asc = maxf(asc, a); desc = maxf(desc, s.lh - a)
				any_text = true
			elif it[0] == "a":
				var box: DomNode = it[1]
				var h: float = it[3]
				var va: String = box.cs.get("vertical-align", "baseline")
				var a2: float
				if va == "middle": a2 = h * 0.5 + cst.fs * 0.25
				elif va == "top" or va == "text-top": a2 = strut_a
				elif va == "bottom" or va == "text-bottom": a2 = h - strut_d
				elif box.baseline >= 0.0 and box.cs.get("overflow-y", "visible") == "visible": a2 = box.mar[0] + box.baseline
				else: a2 = h
				it.append(a2)
				asc = maxf(asc, a2); desc = maxf(desc, h - a2)
		if any_text or true:
			asc = maxf(asc, strut_a); desc = maxf(desc, strut_d)
		var line_h := asc + desc
		var off := 0.0
		if not unbounded:
			if align == "center": off = (avail - lw) * 0.5
			elif align == "right" or align == "end": off = avail - lw
			if off < 0.0 and align == "center": off = off   # centred overflow, like browsers
			elif off < 0.0: off = 0.0
		var x := x0 + off
		var base_y := y + asc
		if container.baseline < 0.0: container.baseline = base_y
		# emit fragments (merge adjacent words of the same style)
		var run_text := ""; var run_x := x; var run_w := 0.0; var run_node: DomNode = null
		var boxes := []    # open inline boxes: [node, start_x]
		for it in litems:
			var k: String = it[0]
			if k == "w" or k == "s":
				if run_node != it[2]:
					if run_text != "": container.frags.append({"t": "text", "x": run_x, "y": base_y, "w": run_w, "text": run_text, "n": run_node})
					run_text = ""; run_x = x; run_w = 0.0; run_node = it[2]
				run_text += it[1]; run_w += it[3]
				x += it[3]
			else:
				if run_text != "":
					container.frags.append({"t": "text", "x": run_x, "y": base_y, "w": run_w, "text": run_text, "n": run_node})
					run_text = ""; run_node = null
				if k == "a":
					var box: DomNode = it[1]
					box.lx = x + box.mar[3]
					box.ly = base_y - it[4] + box.mar[0]
					x += it[2]
				elif k == "o":
					boxes.append([it[1], x])
					x += it[2]
				elif k == "c":
					x += it[2]
					for bi in range(boxes.size() - 1, -1, -1):
						if boxes[bi][0] == it[1]:
							_inline_box_frag(container, it[1], boxes[bi][1], x, base_y)
							boxes.remove_at(bi)
							break
				elif k == "abs":
					_static_pos(it[1], x, y)
		if run_text != "": container.frags.append({"t": "text", "x": run_x, "y": base_y, "w": run_w, "text": run_text, "n": run_node})
		for b in boxes: _inline_box_frag(container, b[0], b[1], x, base_y)
		if ellipsis and lw > avail + 0.5: container.frags.append({"t": "clip", "x": x0, "w": avail, "y": base_y})
		max_w = maxf(max_w, lw)
		y += line_h
	return Vector2(max_w, y - y0)

func _has_content(items: Array) -> bool:
	for it in items:
		if it[0] == "w" or it[0] == "a" or (it[0] == "s" and it.size() > 4 and it[4]): return true
	return false

func _has_break_only(ln: Array) -> bool:
	return ln[2] and ln[0].is_empty()

func _static_pos(n: DomNode, x: float, y: float) -> void:
	n.st["static_x"] = x
	n.st["static_y"] = y

func _inline_box_frag(container: DomNode, el: DomNode, x1: float, x2: float, base_y: float) -> void:
	var s := el.st
	if not s.get("has_bg", false) and el.bor[0] + el.bor[1] + el.bor[2] + el.bor[3] == 0.0: return
	var top: float = base_y - s.asc - el.pad[0] - el.bor[0]
	var h: float = s.asc + s.desc + el.pad[0] + el.pad[2] + el.bor[0] + el.bor[2]
	# insert before the text of this line so the background sits underneath
	container.frags.push_front({"t": "ibox", "x": x1 + el.mar[3], "y": top, "w": x2 - x1 - el.mar[3] - el.mar[1], "h": h, "n": el})

func _break_word(it: Array, first_avail: float, avail: float) -> Array:
	var text: String = it[1]
	var sn: DomNode = it[2]
	var font: Font = sn.st.font
	var fs: float = sn.st.fs
	var parts := []
	var cur := ""
	var limit := maxf(first_avail, 8.0)
	for ch in text:
		if cur != "" and DomFonts.width(font, cur + ch, fs, sn.st.ls) > limit:
			parts.append(["w", cur, sn, DomFonts.width(font, cur, fs, sn.st.ls)])
			cur = ""
			limit = avail
		cur += ch
	if cur != "": parts.append(["w", cur, sn, DomFonts.width(font, cur, fs, sn.st.ls)])
	return parts

# ───────────────────────── box layout ─────────────────────────
func layout_box(n: DomNode, cb_w: float, cb_h: float, mode: int, forced_w: float, forced_h: float) -> void:
	n.frags = []
	n.baseline = -1.0
	n.in_flow_display = n.st.display
	var d: String = n.st.display
	var extra_w := hpad(n)
	var extra_h := vpad(n)
	# ── width ──
	var w := forced_w
	var sw := spec_w(n, cb_w)
	if w < 0.0:
		if not is_auto(sw): w = sw
		elif n.tag == "canvas" or n.tag == "input" or n.tag == "svg" or n.tag == "img":
			w = _replaced_w(n, cb_h) + extra_w
		elif mode == FILL and not is_auto(cb_w):
			w = cb_w - n.mar[1] - n.mar[3]
		else:
			var i := intrinsic(n)
			if is_auto(cb_w): w = i.y
			else: w = minf(i.y, maxf(i.x, cb_w - n.mar[1] - n.mar[3]))
		w = clamp_w(n, w, cb_w)
	var inner_w := maxf(0.0, w - extra_w)
	# ── definite height (if known before laying out children) ──
	var def_h := forced_h
	if def_h < 0.0:
		var sh := spec_h(n, cb_h)
		if not is_auto(sh): def_h = clamp_h(n, sh, cb_h)
	var inner_h := AUTO if def_h < 0.0 else maxf(0.0, def_h - extra_h)
	# ── children ──
	var content := Vector2.ZERO      # content size (w, h) inside the padding box
	if n.tag == "canvas" or n.tag == "input" or n.tag == "svg" or n.tag == "img":
		content = Vector2(inner_w, _replaced_h(n, inner_w, cb_h))
	elif d == "flex" or d == "inline-flex":
		content = layout_flex(n, inner_w, inner_h, cb_h, def_h < 0.0)
	elif d == "grid" or d == "inline-grid":
		content = layout_grid(n, inner_w, inner_h)
	else:
		content = layout_flow(n, inner_w, inner_h)
	# ── height ──
	var h := def_h
	if h < 0.0: h = clamp_h(n, content.y + extra_h, cb_h)
	n.lw = w
	n.lh = h
	n.content_w = content.x
	n.content_h = content.y
	# buttons centre their content vertically
	if n.tag == "button" and d != "flex" and d != "inline-flex":
		var free := (h - extra_h) - content.y
		if free > 0.5: _shift_children(n, 0.0, free * 0.5)
	if n._scroll_y > 0.0: n._scroll_y = clampf(n._scroll_y, 0.0, maxf(0.0, n.content_h - (h - n.bor[0] - n.bor[2])))
	# ── absolutely positioned descendants whose containing block is this box ──
	if n.st.position != "static" or n == doc.root:
		var pending: Array = n.st.get("abs_children", [])
		if pending.size() > 0:
			n.st["abs_children"] = []
			for a in pending: place_abs(a, n, w - n.bor[1] - n.bor[3], h - n.bor[0] - n.bor[2])

func _replaced_w(n: DomNode, cb_h: float) -> float:
	if n.tag == "canvas":
		var hv := L(n, "height", cb_h)
		if not is_auto(hv) and n._ch > 0: return hv * float(n._cw) / float(n._ch)
		return float(n._cw)
	if n.tag == "input": return 129.0 if n.attrs.get("type", "text") == "range" else 150.0
	return str(n.attrs.get("width", "300")).to_float()

func _replaced_h(n: DomNode, inner_w: float, cb_h: float) -> float:
	if n.tag == "canvas":
		return inner_w * float(n._ch) / float(maxi(1, n._cw))
	if n.tag == "input":
		return 16.0 if n.attrs.get("type", "text") == "range" else n.st.lh
	return str(n.attrs.get("height", "150")).to_float()

func _shift_children(n: DomNode, dx: float, dy: float) -> void:
	for c in flow_children(n):
		if c.nodeType == DomNode.ELEMENT and not is_out_of_flow(c):
			c.lx += dx; c.ly += dy
	for f in n.frags:
		f.x += dx; f.y += dy
	if n.baseline >= 0.0: n.baseline += dy

func _register_abs(c: DomNode, parent: DomNode) -> void:
	if c.st.position == "fixed":
		fixed_nodes.append(c)
		return
	var cb: DomNode = parent
	while cb != null and cb.st.position == "static" and cb != doc.root: cb = cb.parentElement
	if cb == null: cb = doc.root
	if not cb.st.has("abs_children"): cb.st["abs_children"] = []
	cb.st["abs_children"].append(c)
	c.abs_cb = cb

# Block / inline flow. Returns content size.
func layout_flow(n: DomNode, inner_w: float, inner_h: float) -> Vector2:
	var x0: float = n.bor[3] + n.pad[3]
	var y: float = n.bor[0] + n.pad[0]
	var y_start := y
	var max_w := 0.0
	var run := []
	var prev_mb := 0.0
	var first := true
	var kids := flow_children(n)
	var has_block := false
	for c in kids:
		if not is_out_of_flow(c) and not is_inline_level(c): has_block = true
	for c in kids:
		if is_out_of_flow(c):
			if has_block and run.is_empty():
				_static_pos(c, x0, y)
				_register_abs(c, n)
			else:
				run.append(c)
				_register_abs(c, n)
			continue
		if is_inline_level(c):
			run.append(c)
			continue
		if run.size() > 0:
			if _run_has_content(run):
				y += prev_mb; prev_mb = 0.0
				var r := layout_inline(n, run, x0, y, inner_w, inner_h)
				y += r.y; max_w = maxf(max_w, r.x)
				first = false
			run = []
		metrics(c, inner_w)
		layout_box(c, inner_w, inner_h, FILL, -1.0, -1.0)
		var mt: float = c.mar[0]
		var gap := maxf(prev_mb, mt) if not first else mt
		if prev_mb < 0.0 or mt < 0.0: gap = prev_mb + mt
		y += gap
		var cx: float = x0 + c.mar[3]
		var free = inner_w - c.lw - c.mar[1] - c.mar[3]
		if free > 0.0:
			var la := margin_auto(c, "left"); var ra := margin_auto(c, "right")
			if la and ra: cx = x0 + (inner_w - c.lw) * 0.5
			elif la: cx = x0 + inner_w - c.lw - c.mar[1]
		c.lx = cx
		c.ly = y
		_apply_relative(c, inner_w, inner_h)
		if n.baseline < 0.0 and c.baseline >= 0.0: n.baseline = y + c.baseline
		y += c.lh
		prev_mb = c.mar[2]
		max_w = maxf(max_w, c.lw + c.mar[1] + c.mar[3])
		first = false
	if run.size() > 0 and _run_has_content(run):
		y += prev_mb; prev_mb = 0.0
		var r2 := layout_inline(n, run, x0, y, inner_w, inner_h)
		y += r2.y; max_w = maxf(max_w, r2.x)
	y += prev_mb
	return Vector2(max_w, y - y_start)

func _run_has_content(run: Array) -> bool:
	for c in run:
		if c.nodeType == DomNode.TEXT:
			if c.data.strip_edges() != "": return true
		elif not is_out_of_flow(c): return true
	return false

func _apply_relative(c: DomNode, cb_w: float, cb_h: float) -> void:
	if c.nodeType != DomNode.ELEMENT or c.st.position != "relative": return
	var l := L(c, "left", cb_w); var t := L(c, "top", cb_h)
	if not is_auto(l): c.lx += l
	else:
		var r := L(c, "right", cb_w)
		if not is_auto(r): c.lx -= r
	if not is_auto(t): c.ly += t
	else:
		var b := L(c, "bottom", cb_h)
		if not is_auto(b): c.ly -= b

# ───────────────────────── flexbox ─────────────────────────
# Children of a flex/grid container: elements, plus anonymous runs for bare text.
func _flex_items(n: DomNode, kids: Array) -> Array:
	var items := []
	for c in kids:
		if c.nodeType == DomNode.TEXT:
			if c.data.strip_edges() != "": items.append([n, [c]])
		elif is_out_of_flow(c): continue
		else: items.append(c)
	return items

func layout_flex(n: DomNode, inner_w: float, inner_h: float, cb_h: float, auto_h: bool) -> Vector2:
	var cs := n.cs
	var dir: String = cs.get("flex-direction", "row")
	var row := not dir.begins_with("column")
	var reverse := dir.ends_with("reverse")
	var wrap: bool = cs.get("flex-wrap", "nowrap") != "nowrap"
	var jc: String = cs.get("justify-content", "flex-start")
	var ai: String = cs.get("align-items", "stretch")
	var fs: float = n.st.fs
	var gap_main := _len0(cs.get("column-gap" if row else "row-gap"), inner_w, fs)
	var gap_cross := _len0(cs.get("row-gap" if row else "column-gap"), inner_w, fs)
	var x0: float = n.bor[3] + n.pad[3]
	var y0: float = n.bor[0] + n.pad[0]
	var kids := flow_children(n)
	for c in kids:
		if c.nodeType == DomNode.ELEMENT and is_out_of_flow(c):
			_static_pos(c, x0, y0)
			c.st["static_flex"] = [jc, ai, row]
			_register_abs(c, n)
	var raw := _flex_items(n, kids)
	if reverse: raw.reverse()
	# container main size
	var main_avail := inner_w if row else inner_h
	var min_main := 0.0; var max_main := INF
	if not row and auto_h:
		var mnh := spec_h(n, cb_h, "min-height")
		if not is_auto(mnh): min_main = maxf(0.0, mnh - vpad(n))
		var mxh := spec_h(n, cb_h, "max-height")
		if not is_auto(mxh): max_main = maxf(0.0, mxh - vpad(n))
	# ── gather items ──
	var items := []   # dictionaries
	for c in raw:
		var it := {"n": c, "anon": c is Array, "grow": 0.0, "shrink": 1.0, "base": 0.0, "min": 0.0, "max": INF, "main": 0.0, "cross": 0.0, "m1": 0.0, "m2": 0.0, "c1": 0.0, "c2": 0.0, "frozen": false}
		if it.anon:
			var mi := _measure_inline(n, c[1])
			if row:
				it.base = mi.y; it.min = mi.x
			else:
				it.base = _anon_height(n, c[1], inner_w); it.min = it.base
			items.append(it)
			continue
		var el: DomNode = c
		metrics(el, inner_w)
		it.grow = CssValue.f(el.cs.get("flex-grow", "0"))
		it.shrink = CssValue.f(el.cs.get("flex-shrink", "1"))
		if row:
			it.m1 = el.mar[3]; it.m2 = el.mar[1]; it.c1 = el.mar[0]; it.c2 = el.mar[2]
		else:
			it.m1 = el.mar[0]; it.m2 = el.mar[2]; it.c1 = el.mar[3]; it.c2 = el.mar[1]
		var basis = el.cs.get("flex-basis", "auto")
		var b := AUTO
		if basis != "auto" and basis != "content":
			b = CssValue.length(basis, main_avail, el.st.fs, vp)
			# a percentage basis against an indefinite container size behaves like `content`
			if CssValue.is_percent(basis) and is_auto(main_avail): b = AUTO
			if not is_auto(b) and not border_box(el): b += hpad(el) if row else vpad(el)
			if not is_auto(b): b = maxf(b, hpad(el) if row else vpad(el))
		if row:
			var sw := spec_w(el, inner_w)
			var intr := Vector2(-1, -1)
			if is_auto(b):
				if not is_auto(sw): b = sw
				elif el.tag == "canvas" or el.tag == "input" or el.tag == "svg": b = _replaced_w(el, inner_h) + hpad(el)
				else:
					intr = intrinsic(el)
					b = intr.y
			# automatic minimum size
			var mn := spec_w(el, inner_w, "min-width")
			if is_auto(mn):
				if el.cs.get("overflow-x", "visible") != "visible": mn = 0.0
				elif el.tag == "canvas" or el.tag == "input": mn = 0.0 if is_auto(sw) else sw
				else:
					if intr.x < 0: intr = intrinsic(el)
					mn = intr.x
					if not is_auto(sw): mn = minf(mn, sw)
			it.min = mn
			var mx := spec_w(el, inner_w, "max-width")
			if not is_auto(mx): it.max = mx
			it.base = b
		else:
			# column: main size is height → need a layout at the item's cross size
			var sh := spec_h(el, inner_h)
			var cw := _column_item_width(el, inner_w, ai)
			if is_auto(b):
				if not is_auto(sh): b = sh
				else:
					layout_box(el, inner_w, AUTO, FILL, cw, -1.0)
					b = el.lh
					it["laid_h"] = el.lh
					it["laid"] = true
			var mnh2 := spec_h(el, inner_h, "min-height")
			if is_auto(mnh2):
				if el.cs.get("overflow-y", "visible") != "visible": mnh2 = 0.0
				else:
					if not it.has("laid_h"):
						if is_auto(sh):
							layout_box(el, inner_w, AUTO, FILL, cw, -1.0)
							it["laid_h"] = el.lh
							it["laid"] = true
						else: it["laid_h"] = sh
					mnh2 = it.laid_h
					if not is_auto(sh): mnh2 = minf(mnh2, sh)
			it.min = mnh2
			var mxh2 := spec_h(el, inner_h, "max-height")
			if not is_auto(mxh2): it.max = mxh2
			it.base = b
			it["cw"] = cw
		it.base = clampf(it.base, minf(it.min, it.max), it.max) if it.max >= it.min else it.max
		items.append(it)
	# ── break into lines ──
	var lines := []
	var cur := []
	var cur_main := 0.0
	var limit := main_avail
	if is_auto(limit): limit = INF
	for it in items:
		var outer: float = it.base + it.m1 + it.m2
		if wrap and cur.size() > 0 and cur_main + gap_main + outer > limit + 0.01:
			lines.append(cur); cur = []; cur_main = 0.0
		cur_main += outer + (gap_main if cur.size() > 0 else 0.0)
		cur.append(it)
	if cur.size() > 0 or lines.is_empty(): lines.append(cur)
	# ── resolve main sizes per line ──
	var content_main := 0.0
	var line_infos := []
	for line in lines:
		var total := gap_main * maxf(0.0, line.size() - 1)
		for it in line: total += it.base + it.m1 + it.m2
		var container_main := main_avail
		if is_auto(container_main): container_main = clampf(total, min_main, max_main)
		var free := container_main - total
		for it in line:
			it.main = it.base
			it.frozen = false
		if absf(free) > 0.01:
			var guard := 0
			while guard < 8:
				guard += 1
				var weight := 0.0
				var used := gap_main * maxf(0.0, line.size() - 1)
				for it in line:
					used += (it.main if it.frozen else it.base) + it.m1 + it.m2
					if not it.frozen: weight += it.grow if free > 0.0 else it.shrink * it.base
				var rem := container_main - used
				if weight <= 0.0: break
				var violated := false
				for it in line:
					if it.frozen: continue
					var share: float = (it.grow if free > 0.0 else it.shrink * it.base) / weight
					var target: float = it.base + rem * share
					var clamped := clampf(target, minf(it.min, it.max), it.max)
					if absf(clamped - target) > 0.01:
						it.main = clamped; it.frozen = true; violated = true
					else: it.main = target
				if not violated: break
		var used_main := gap_main * maxf(0.0, line.size() - 1)
		for it in line: used_main += it.main + it.m1 + it.m2
		content_main = maxf(content_main, used_main)
		line_infos.append({"items": line, "used": used_main, "container": container_main, "cross": 0.0})
	# ── cross sizes ──
	var cross_avail := inner_h if row else inner_w
	var single := lines.size() == 1
	for li in line_infos:
		var line_cross := 0.0
		for it in li.items:
			if it.anon:
				if row:
					it.cross = _anon_height(n, it.n[1], it.main)
				else:
					it.cross = minf(_measure_inline(n, it.n[1]).y, inner_w)
				line_cross = maxf(line_cross, it.cross)
				continue
			var el: DomNode = it.n
			if row:
				layout_box(el, inner_w, cross_avail, FIT, it.main, -1.0)
				it.cross = el.lh
			else:
				if not it.get("laid", false) or absf(it.main - el.lh) > 0.01 or el.lw != it.cw:
					var fh: float = it.main
					# keep auto height when the item was neither grown nor shrunk
					if is_auto(spec_h(el, inner_h)) and absf(it.main - it.base) < 0.01 and it.has("laid_h"): fh = -1.0
					layout_box(el, inner_w, AUTO if is_auto(inner_h) else inner_h, FILL, it.cw, fh)
				it.cross = el.lw
			line_cross = maxf(line_cross, it.cross + it.c1 + it.c2)
		if single and not is_auto(cross_avail): line_cross = cross_avail
		li.cross = line_cross
	# column containers: cross size (width) is always the inner width
	if not row:
		for li in line_infos:
			if single: li.cross = inner_w
	# ── stretch + position ──
	var total_cross := gap_cross * maxf(0.0, line_infos.size() - 1)
	for li in line_infos: total_cross += li.cross
	var cross_pos := 0.0
	if not is_auto(cross_avail) and not single:
		# align-content: default stretch/flex-start → start
		pass
	var max_main_used := 0.0
	for li in line_infos:
		var line: Array = li.items
		var free: float = li.container - li.used
		var autos := 0
		for it in line:
			if it.anon: continue
			var el: DomNode = it.n
			if margin_auto(el, "left" if row else "top"): autos += 1
			if margin_auto(el, "right" if row else "bottom"): autos += 1
		var pos := 0.0
		var between := 0.0
		if free > 0.0 and autos > 0:
			pass
		elif free != 0.0:
			match jc:
				"center": pos = free * 0.5
				"flex-end", "end", "right": pos = free
				"space-between":
					if line.size() > 1 and free > 0.0: between = free / (line.size() - 1)
				"space-around":
					if line.size() > 0 and free > 0.0:
						between = free / line.size(); pos = between * 0.5
				"space-evenly":
					if line.size() > 0 and free > 0.0:
						between = free / (line.size() + 1); pos = between
			if free < 0.0 and (jc == "space-between" or jc == "space-around" or jc == "space-evenly"): pos = 0.0
		for it in line:
			var el2 = it.n
			var am1 := 0.0; var am2 := 0.0
			if not it.anon and free > 0.0 and autos > 0:
				if margin_auto(el2, "left" if row else "top"): am1 = free / autos
				if margin_auto(el2, "right" if row else "bottom"): am2 = free / autos
			pos += it.m1 + am1
			# cross-axis alignment
			var align := ai
			if not it.anon:
				var self_a: String = el2.cs.get("align-self", "auto")
				if self_a != "auto": align = self_a
			var cross_size: float = it.cross
			var cpos: float = it.c1
			var line_cross: float = li.cross
			var can_stretch: bool = not it.anon and is_auto(spec_h(el2, cross_avail) if row else spec_w(el2, inner_w)) and not (el2.tag == "canvas" and not row and false)
			if not it.anon and (margin_auto(el2, "top" if row else "left") or margin_auto(el2, "bottom" if row else "right")):
				var cfree: float = line_cross - cross_size - it.c1 - it.c2
				var ta := margin_auto(el2, "top" if row else "left"); var ba := margin_auto(el2, "bottom" if row else "right")
				if ta and ba: cpos = it.c1 + cfree * 0.5
				elif ta: cpos = it.c1 + cfree
			elif (align == "stretch" or align == "normal") and can_stretch:
				var target: float = maxf(0.0, line_cross - it.c1 - it.c2)
				if row:
					target = clamp_h(el2, target, cross_avail)
					if absf(target - el2.lh) > 0.01:
						layout_box(el2, inner_w, cross_avail, FIT, it.main, target)
				cross_size = target
			elif align == "center": cpos = it.c1 + (line_cross - cross_size - it.c1 - it.c2) * 0.5
			elif align == "flex-end" or align == "end": cpos = line_cross - cross_size - it.c2
			elif align == "baseline" and row and not it.anon and el2.baseline >= 0.0:
				cpos = it.c1   # approximated as flex-start
			if it.anon:
				var ax := x0 + (pos if row else cross_pos + cpos)
				var ay := y0 + (cross_pos + cpos if row else pos)
				var aw: float = it.main if row else minf(inner_w, maxf(it.cross, 0.0))
				if not row and (align == "stretch" or align == "normal"): aw = inner_w; ax = x0 + cross_pos
				layout_inline(n, it.n[1], ax, ay, aw, AUTO)
			else:
				if row:
					el2.lx = x0 + pos; el2.ly = y0 + cross_pos + cpos
				else:
					el2.lx = x0 + cross_pos + cpos; el2.ly = y0 + pos
				_apply_relative(el2, inner_w, inner_h)
				if n.baseline < 0.0 and el2.baseline >= 0.0: n.baseline = el2.ly + el2.baseline
			pos += it.main + it.m2 + am2 + gap_main + between
		max_main_used = maxf(max_main_used, li.container if not is_auto(main_avail) else li.used)
		cross_pos += li.cross + gap_cross
	if row: return Vector2(content_main, total_cross)
	var main_size := content_main
	if is_auto(main_avail): main_size = clampf(content_main, min_main, INF)
	return Vector2(total_cross, main_size)

func _column_item_width(el: DomNode, inner_w: float, ai: String) -> float:
	var sw := spec_w(el, inner_w)
	if not is_auto(sw): return clamp_w(el, sw, inner_w)
	var align: String = el.cs.get("align-self", "auto")
	if align == "auto": align = ai
	if el.tag == "canvas" or el.tag == "input" or el.tag == "svg":
		return clamp_w(el, _replaced_w(el, AUTO) + hpad(el), inner_w)
	if (align == "stretch" or align == "normal") and not margin_auto(el, "left") and not margin_auto(el, "right"):
		return clamp_w(el, inner_w - el.mar[1] - el.mar[3], inner_w)
	var i := intrinsic(el)
	return clamp_w(el, minf(i.y, maxf(i.x, inner_w - el.mar[1] - el.mar[3])), inner_w)

func _anon_height(n: DomNode, nodes: Array, width: float) -> float:
	var saved := n.frags
	var saved_base := n.baseline
	n.frags = []
	var r := layout_inline(n, nodes, 0.0, 0.0, width, AUTO)
	n.frags = saved
	n.baseline = saved_base
	return r.y

# ───────────────────────── grid ─────────────────────────
# Column tracks: [["px", size] | ["fr", n] | ["auto", 0]]
func _grid_tracks(n: DomNode, inner_w: float) -> Array:
	var tpl: String = n.cs.get("grid-template-columns", "none")
	var tracks := []
	if tpl == "none" or tpl == "": return [["fr", 1.0]]
	var gap := _len0(n.cs.get("column-gap"), 0.0, n.st.fs)
	for tok in CssEngine.split_ws(tpl):
		if tok.begins_with("repeat("):
			var inner := tok.substr(7, tok.length() - 8)
			var comma := inner.find(",")
			var count_s := inner.substr(0, comma).strip_edges()
			var sub := CssEngine.split_ws(inner.substr(comma + 1).strip_edges())
			var count := count_s.to_int()
			if count_s == "auto-fill" or count_s == "auto-fit":
				var minw := 100.0
				if sub.size() > 0 and sub[0].begins_with("minmax("):
					minw = CssValue.length(sub[0].substr(7).split(",")[0], inner_w, n.st.fs, vp)
				elif sub.size() > 0: minw = CssValue.length(sub[0], inner_w, n.st.fs, vp)
				count = 1 if is_auto(inner_w) else maxi(1, int(floor((inner_w + gap) / (minw + gap))))
			for i in range(count):
				for s in sub: tracks.append(_track(n, s, inner_w))
		else:
			tracks.append(_track(n, tok, inner_w))
	return tracks

func _track(n: DomNode, tok: String, inner_w: float) -> Array:
	if tok.ends_with("fr"): return ["fr", CssValue.f(tok)]
	if tok.begins_with("minmax("): return ["fr", 1.0]
	if tok == "auto" or tok == "max-content" or tok == "min-content": return ["auto", 0.0]
	var v := CssValue.length(tok, inner_w, n.st.fs, vp)
	if is_auto(v): return ["auto", 0.0]
	return ["px", v]

func layout_grid(n: DomNode, inner_w: float, inner_h: float) -> Vector2:
	var fs: float = n.st.fs
	var cgap := _len0(n.cs.get("column-gap"), inner_w, fs)
	var rgap := _len0(n.cs.get("row-gap"), inner_w, fs)
	var x0: float = n.bor[3] + n.pad[3]
	var y0: float = n.bor[0] + n.pad[0]
	var kids := flow_children(n)
	for c in kids:
		if c.nodeType == DomNode.ELEMENT and is_out_of_flow(c):
			_static_pos(c, x0, y0)
			_register_abs(c, n)
	var items := _flex_items(n, kids)
	var tracks := _grid_tracks(n, inner_w)
	var ncol := tracks.size()
	var widths := []
	var fixed := cgap * maxf(0.0, ncol - 1)
	var fr_total := 0.0
	for ti in range(ncol):
		var t = tracks[ti]
		if t[0] == "px":
			widths.append(t[1]); fixed += t[1]
		elif t[0] == "auto":
			var mw := 0.0
			for ii in range(ti, items.size(), ncol):
				if not (items[ii] is Array): mw = maxf(mw, _intrinsic_outer(items[ii]).y)
			widths.append(mw); fixed += mw
		else:
			widths.append(-t[1]); fr_total += t[1]
	if fr_total > 0.0:
		var rem := maxf(0.0, inner_w - fixed)
		for ti in range(ncol):
			if widths[ti] < 0.0: widths[ti] = rem * (-widths[ti]) / fr_total
	var y := y0
	var total_w := cgap * maxf(0.0, ncol - 1)
	for wv in widths: total_w += wv
	var ji: String = n.cs.get("justify-items", "stretch")
	var ai: String = n.cs.get("align-items", "stretch")
	var idx := 0
	while idx < items.size():
		var row_h := 0.0
		var x := x0
		var row_items := []
		for ci in range(ncol):
			if idx >= items.size(): break
			var it = items[idx]
			idx += 1
			var cw: float = widths[ci]
			if it is Array:
				var r := layout_inline(n, it[1], x, y, cw, AUTO)
				row_h = maxf(row_h, r.y)
			else:
				var el: DomNode = it
				metrics(el, cw)
				var sw := spec_w(el, cw)
				var fw := -1.0
				if is_auto(sw) and ji == "stretch" and not (el.tag == "canvas"): fw = maxf(0.0, cw - el.mar[1] - el.mar[3])
				layout_box(el, cw, AUTO, FIT, fw, -1.0)
				el.lx = x + el.mar[3]
				if ji == "center": el.lx = x + (cw - el.lw) * 0.5
				el.ly = y + el.mar[0]
				row_h = maxf(row_h, el.lh + el.mar[0] + el.mar[2])
				row_items.append([el, cw, x])
			x += cw + cgap
		for ri in row_items:
			var el2: DomNode = ri[0]
			if ai == "stretch" and is_auto(spec_h(el2, AUTO)):
				var target = row_h - el2.mar[0] - el2.mar[2]
				if absf(target - el2.lh) > 0.01: layout_box(el2, ri[1], AUTO, FIT, el2.lw, target)
			elif ai == "center": el2.ly = y + (row_h - el2.lh) * 0.5
			_apply_relative(el2, ri[1], AUTO)
		y += row_h + (rgap if idx < items.size() else 0.0)
	return Vector2(total_w, y - y0)

# ───────────────────────── absolute / fixed ─────────────────────────
# cb == null → viewport (fixed). cbw/cbh = padding-box size of the containing block.
func place_abs(n: DomNode, cb: DomNode, cbw: float, cbh: float) -> void:
	metrics(n, cbw)
	var l := L(n, "left", cbw); var r := L(n, "right", cbw)
	var t := L(n, "top", cbh); var b := L(n, "bottom", cbh)
	var sw := spec_w(n, cbw)
	var fw := -1.0
	var avail_w := cbw
	if is_auto(sw):
		if not is_auto(l) and not is_auto(r):
			fw = clamp_w(n, maxf(0.0, cbw - l - r - n.mar[1] - n.mar[3]), cbw)
		else:
			avail_w = cbw - (0.0 if is_auto(l) else l) - (0.0 if is_auto(r) else r)
	var sh := spec_h(n, cbh)
	var fh := -1.0
	if is_auto(sh) and not is_auto(t) and not is_auto(b):
		fh = clamp_h(n, maxf(0.0, cbh - t - b - n.mar[0] - n.mar[2]), cbh)
	layout_box(n, avail_w, cbh, FIT, fw, fh)
	var ox := 0.0; var oy := 0.0     # padding-box origin within the containing block's border box
	if cb != null:
		ox = cb.bor[3]; oy = cb.bor[0]
	var x: float
	if not is_auto(l):
		x = ox + l + n.mar[3]
		if margin_auto(n, "left") and margin_auto(n, "right") and not is_auto(r): x = ox + l + (cbw - l - r - n.lw) * 0.5
	elif not is_auto(r): x = ox + cbw - r - n.lw - n.mar[1]
	else: x = _static_abs(n, cb, true, cbw, cbh)
	var y: float
	if not is_auto(t):
		y = oy + t + n.mar[0]
		if margin_auto(n, "top") and margin_auto(n, "bottom") and not is_auto(b): y = oy + t + (cbh - t - b - n.lh) * 0.5
	elif not is_auto(b): y = oy + cbh - b - n.lh - n.mar[2]
	else: y = _static_abs(n, cb, false, cbw, cbh)
	n.lx = x
	n.ly = y

# static position of an abs box, expressed relative to its containing block
func _static_abs(n: DomNode, cb: DomNode, horiz: bool, cbw: float, cbh: float) -> float:
	var v: float = n.st.get("static_x" if horiz else "static_y", 0.0)
	var p := n.parentElement
	var sf = n.st.get("static_flex")
	if sf != null and p != null:
		# abs child of a flex container: honours the container's alignment
		var pw: float = p.lw - hpad(p); var ph: float = p.lh - vpad(p)
		var row: bool = sf[2]
		var main_a: String = sf[0]; var cross_a: String = sf[1]
		var a: String = (main_a if row else cross_a) if horiz else (cross_a if row else main_a)
		var free: float = (pw - n.lw) if horiz else (ph - n.lh)
		if a == "center": v += free * 0.5
		elif a == "flex-end" or a == "end": v += free
	v += n.mar[3] if horiz else n.mar[0]
	# convert from parent coordinates to the containing block's
	while p != null and p != cb:
		v += p.lx if horiz else p.ly
		p = p.parentElement
	if cb == null:
		pass
	return v
