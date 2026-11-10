# DomSvg — draws inline <svg> elements (rect, circle, ellipse, line, polygon, polyline, path, text, g).
class_name DomSvg
extends RefCounted

static func _num(n: DomNode, key: String, def: float = 0.0) -> float:
	var v = n.attrs.get(key)
	if v == null: return def
	return str(v).to_float()

static func draw(rid: RID, svg: DomNode, doc) -> void:
	var box := Rect2(svg.bor[3] + svg.pad[3], svg.bor[0] + svg.pad[0], svg.lw - svg.bor[1] - svg.bor[3] - svg.pad[1] - svg.pad[3], svg.lh - svg.bor[0] - svg.bor[2] - svg.pad[0] - svg.pad[2])
	var xf := Transform2D(0, box.position)
	var vb = svg.attrs.get("viewBox", svg.attrs.get("viewbox"))
	if vb != null:
		var p := str(vb).replace(",", " ").split(" ", false)
		if p.size() == 4 and p[2].to_float() > 0.0 and p[3].to_float() > 0.0:
			var sx := box.size.x / p[2].to_float(); var sy := box.size.y / p[3].to_float()
			var k := minf(sx, sy)
			var off := Vector2((box.size.x - p[2].to_float() * k) * 0.5, (box.size.y - p[3].to_float() * k) * 0.5)
			xf = Transform2D(Vector2(k, 0), Vector2(0, k), box.position + off - Vector2(p[0].to_float(), p[1].to_float()) * k)
	var inherit := {"fill": "#000", "stroke": "none", "stroke-width": "1", "opacity": 1.0, "color": svg.st.color}
	_children(rid, svg, xf, inherit, doc)
	RenderingServer.canvas_item_add_set_transform(rid, Transform2D.IDENTITY)

static func _children(rid: RID, parent: DomNode, xf: Transform2D, inh: Dictionary, doc) -> void:
	for c in parent.childNodes:
		if c.nodeType == DomNode.ELEMENT: _shape(rid, c, xf, inh, doc)

static func _attr(n: DomNode, key: String, inh: Dictionary):
	var v = n.attrs.get(key)
	if v == null: v = n.style._props.get(key)
	if v == null: return inh.get(key)
	return v

static func _paint(v, opacity: float, cur: Color):
	if v == null or v == "none" or v == "transparent": return null
	if v == "currentColor" or v == "currentcolor": return Color(cur.r, cur.g, cur.b, cur.a * opacity)
	var c := CssValue.color(v, Color(0, 0, 0, 1))
	return Color(c.r, c.g, c.b, c.a * opacity)

static func _shape(rid: RID, n: DomNode, xf: Transform2D, inh: Dictionary, doc) -> void:
	var tag := n.tag.to_lower()
	var t := xf
	var tfv = n.attrs.get("transform")
	if tfv != null: t = xf * _transform(str(tfv))
	var op: float = inh.opacity * _num(n, "opacity", 1.0)
	if tag == "g" or tag == "svg" or tag == "a":
		var sub := inh.duplicate()
		for k in ["fill", "stroke", "stroke-width", "stroke-linecap", "stroke-linejoin"]:
			var v = n.attrs.get(k)
			if v != null: sub[k] = v
		sub.opacity = op
		_children(rid, n, t, sub, doc)
		return
	if tag == "defs" or tag == "title" or tag == "style": return
	var fill = _paint(_attr(n, "fill", inh), op * _num(n, "fill-opacity", 1.0), inh.color)
	var stroke = _paint(_attr(n, "stroke", inh), op * _num(n, "stroke-opacity", 1.0), inh.color)
	var sw := str(_attr(n, "stroke-width", inh)).to_float()
	var scale := (t.x.length() + t.y.length()) * 0.5
	var subs := []     # [PackedVector2Array, closed]
	match tag:
		"rect":
			var x := _num(n, "x"); var y := _num(n, "y"); var w := _num(n, "width"); var h := _num(n, "height")
			var rx := _num(n, "rx", _num(n, "ry"))
			if w <= 0.0 or h <= 0.0: return
			if rx <= 0.0 and fill != null and stroke == null and t.x.y == 0.0 and t.y.x == 0.0:
				RenderingServer.canvas_item_add_set_transform(rid, t)
				RenderingServer.canvas_item_add_rect(rid, Rect2(x, y, w, h), fill)
				return
			var pts := DomPaint.rounded_points(x, y, w, h, [rx, rx, rx, rx]) if rx > 0.0 else PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])
			subs.append([pts, true])
		"circle", "ellipse":
			var cx := _num(n, "cx"); var cy := _num(n, "cy")
			var rx2 := _num(n, "r") if tag == "circle" else _num(n, "rx")
			var ry2 := _num(n, "r") if tag == "circle" else _num(n, "ry")
			if rx2 <= 0.0 or ry2 <= 0.0: return
			var steps := clampi(int(maxf(rx2, ry2) * scale * 1.2) + 8, 10, 64)
			var pts2 := PackedVector2Array()
			for i in range(steps): pts2.append(Vector2(cx + cos(TAU * i / steps) * rx2, cy + sin(TAU * i / steps) * ry2))
			subs.append([pts2, true])
		"line":
			subs.append([PackedVector2Array([Vector2(_num(n, "x1"), _num(n, "y1")), Vector2(_num(n, "x2"), _num(n, "y2"))]), false])
			fill = null
		"polygon", "polyline":
			var nums := _numbers(str(n.attrs.get("points", "")))
			var pts3 := PackedVector2Array()
			for i in range(0, nums.size() - 1, 2): pts3.append(Vector2(nums[i], nums[i + 1]))
			subs.append([pts3, tag == "polygon"])
		"path":
			subs = path(str(n.attrs.get("d", "")), scale)
		"text":
			var txt := n.textContent
			if txt == "": return
			var px := _num(n, "font-size", 16.0)
			var font: Font = doc.root.st.font
			var w2 := DomFonts.width(font, txt, px)
			var ox := _num(n, "x")
			var anchor = n.attrs.get("text-anchor", "start")
			if anchor == "middle": ox -= w2 * 0.5
			elif anchor == "end": ox -= w2
			var isz := maxi(1, int(round(px * scale)))
			var k := px / float(isz)
			RenderingServer.canvas_item_add_set_transform(rid, t * Transform2D(Vector2(k, 0), Vector2(0, k), Vector2(ox, _num(n, "y"))))
			font.draw_string(rid, Vector2.ZERO, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, isz, fill if fill != null else Color.WHITE)
			return
		_: return
	RenderingServer.canvas_item_add_set_transform(rid, t)
	for sp in subs:
		var pts4: PackedVector2Array = sp[0]
		if fill != null and pts4.size() >= 3:
			var idx := Geometry2D.triangulate_polygon(pts4)
			if not idx.is_empty():
				var cols := PackedColorArray()
				cols.resize(pts4.size())
				cols.fill(fill)
				RenderingServer.canvas_item_add_triangle_array(rid, idx, pts4, cols)
		if stroke != null and sw > 0.0 and pts4.size() >= 2:
			var line := pts4
			if sp[1]:
				line = pts4.duplicate()
				line.append(pts4[0])
			RenderingServer.canvas_item_add_polyline(rid, line, PackedColorArray([stroke]), sw, sw * scale > 1.5)
			if _attr(n, "stroke-linecap", inh) == "round" and sw * scale >= 2.0 and not sp[1]:
				RenderingServer.canvas_item_add_circle(rid, line[0], sw * 0.5, stroke)
				RenderingServer.canvas_item_add_circle(rid, line[line.size() - 1], sw * 0.5, stroke)

static func _numbers(s: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var cur := ""
	for ch in s:
		if (ch >= "0" and ch <= "9") or ch == "." or ch == "e" or ch == "E":
			if ch == "." and cur.contains(".") and not cur.contains("e"):
				out.append(cur.to_float()); cur = ""
			cur += ch
		elif ch == "-" or ch == "+":
			if cur != "" and not (cur.ends_with("e") or cur.ends_with("E")):
				out.append(cur.to_float()); cur = ""
			cur += ch
		else:
			if cur != "":
				out.append(cur.to_float()); cur = ""
	if cur != "": out.append(cur.to_float())
	return out

static func _transform(s: String) -> Transform2D:
	var t := Transform2D.IDENTITY
	var i := 0
	while true:
		var open := s.find("(", i)
		if open < 0: break
		var fname := s.substr(i, open - i).strip_edges().trim_prefix(",").strip_edges()
		var close := s.find(")", open)
		var a := _numbers(s.substr(open + 1, close - open - 1))
		i = close + 1
		match fname:
			"translate": t = t * Transform2D(0, Vector2(a[0], a[1] if a.size() > 1 else 0.0))
			"scale": t = t * Transform2D(Vector2(a[0], 0), Vector2(0, a[1] if a.size() > 1 else a[0]), Vector2.ZERO)
			"rotate":
				var r := Transform2D(deg_to_rad(a[0]), Vector2.ZERO)
				if a.size() >= 3: r = Transform2D(0, Vector2(a[1], a[2])) * r * Transform2D(0, -Vector2(a[1], a[2]))
				t = t * r
			"matrix":
				if a.size() >= 6: t = t * Transform2D(Vector2(a[0], a[1]), Vector2(a[2], a[3]), Vector2(a[4], a[5]))
	return t

static var _path_cache: Dictionary = {}

# SVG path data → list of [points, closed]
static func path(d: String, scale: float) -> Array:
	var key := "%s|%d" % [d, int(scale * 4.0)]
	if _path_cache.has(key): return _path_cache[key]
	var subs := []
	var cur := PackedVector2Array()
	var pen := Vector2.ZERO; var start := Vector2.ZERO
	var last_c := Vector2.ZERO; var last_cmd := ""
	var toks := []
	var num := ""
	for ch in d:
		if (ch >= "A" and ch <= "Z" and ch != "E") or (ch >= "a" and ch <= "z" and ch != "e"):
			if num != "":
				toks.append(num.to_float()); num = ""
			toks.append(ch)
		elif (ch >= "0" and ch <= "9") or ch == "." or ch == "e" or ch == "E":
			if ch == "." and num.contains(".") and not num.to_lower().contains("e"):
				toks.append(num.to_float()); num = ""
			num += ch
		elif ch == "-" or ch == "+":
			if num != "" and not num.to_lower().ends_with("e"):
				toks.append(num.to_float()); num = ""
			num += ch
		else:
			if num != "":
				toks.append(num.to_float()); num = ""
	if num != "": toks.append(num.to_float())
	var i := 0
	var cmd := ""
	while i < toks.size():
		if toks[i] is String:
			cmd = toks[i]; i += 1
		var rel := cmd == cmd.to_lower()
		var base := pen if rel else Vector2.ZERO
		match cmd.to_upper():
			"M":
				if cur.size() > 0: subs.append([cur, false])
				cur = PackedVector2Array()
				pen = base + Vector2(toks[i], toks[i + 1]); i += 2
				start = pen
				cur.append(pen)
				cmd = "l" if rel else "L"
			"L":
				pen = base + Vector2(toks[i], toks[i + 1]); i += 2
				cur.append(pen)
			"H":
				pen = Vector2((pen.x if rel else 0.0) + toks[i], pen.y); i += 1
				cur.append(pen)
			"V":
				pen = Vector2(pen.x, (pen.y if rel else 0.0) + toks[i]); i += 1
				cur.append(pen)
			"C":
				var c1 := base + Vector2(toks[i], toks[i + 1]); var c2 := base + Vector2(toks[i + 2], toks[i + 3]); var p1 := base + Vector2(toks[i + 4], toks[i + 5]); i += 6
				_cubic(cur, pen, c1, c2, p1, scale)
				last_c = c2; pen = p1
			"S":
				var c1b := pen * 2.0 - last_c if last_cmd in ["C", "S"] else pen
				var c2b := base + Vector2(toks[i], toks[i + 1]); var p1b := base + Vector2(toks[i + 2], toks[i + 3]); i += 4
				_cubic(cur, pen, c1b, c2b, p1b, scale)
				last_c = c2b; pen = p1b
			"Q":
				var qc := base + Vector2(toks[i], toks[i + 1]); var qp := base + Vector2(toks[i + 2], toks[i + 3]); i += 4
				_cubic(cur, pen, pen + (qc - pen) * 2.0 / 3.0, qp + (qc - qp) * 2.0 / 3.0, qp, scale)
				last_c = qc; pen = qp
			"T":
				var qc2 := pen * 2.0 - last_c if last_cmd in ["Q", "T"] else pen
				var qp2 := base + Vector2(toks[i], toks[i + 1]); i += 2
				_cubic(cur, pen, pen + (qc2 - pen) * 2.0 / 3.0, qp2 + (qc2 - qp2) * 2.0 / 3.0, qp2, scale)
				last_c = qc2; pen = qp2
			"A":
				var rx: float = toks[i]; var ry: float = toks[i + 1]; var rot: float = toks[i + 2]
				var large: bool = toks[i + 3] != 0.0; var sweep: bool = toks[i + 4] != 0.0
				var p2 := base + Vector2(toks[i + 5], toks[i + 6]); i += 7
				_arc(cur, pen, p2, rx, ry, deg_to_rad(rot), large, sweep, scale)
				pen = p2
			"Z":
				if cur.size() > 0: subs.append([cur, true])
				cur = PackedVector2Array()
				pen = start
				cur.append(pen)
			_:
				i += 1
		last_cmd = cmd.to_upper()
	if cur.size() > 1: subs.append([cur, false])
	if _path_cache.size() > 3000: _path_cache.clear()
	_path_cache[key] = subs
	return subs

static func _cubic(out: PackedVector2Array, p0: Vector2, c1: Vector2, c2: Vector2, p1: Vector2, scale: float) -> void:
	var steps := clampi(int(((c1 - p0).length() + (c2 - c1).length() + (p1 - c2).length()) * scale / 3.0), 4, 32)
	for k in range(1, steps + 1): out.append(p0.bezier_interpolate(c1, c2, p1, float(k) / steps))

static func _arc(out: PackedVector2Array, p0: Vector2, p1: Vector2, rx: float, ry: float, phi: float, large: bool, sweep: bool, scale: float) -> void:
	if rx == 0.0 or ry == 0.0:
		out.append(p1)
		return
	rx = absf(rx); ry = absf(ry)
	var cp := cos(phi); var sp := sin(phi)
	var dx := (p0.x - p1.x) * 0.5; var dy := (p0.y - p1.y) * 0.5
	var x1 := cp * dx + sp * dy; var y1 := -sp * dx + cp * dy
	var lam := (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
	if lam > 1.0:
		rx *= sqrt(lam); ry *= sqrt(lam)
	var num := rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
	var den := rx * rx * y1 * y1 + ry * ry * x1 * x1
	var co := 0.0 if den == 0.0 else sqrt(maxf(0.0, num / den))
	if large == sweep: co = -co
	var cxp := co * rx * y1 / ry; var cyp := -co * ry * x1 / rx
	var cx := cp * cxp - sp * cyp + (p0.x + p1.x) * 0.5
	var cy := sp * cxp + cp * cyp + (p0.y + p1.y) * 0.5
	var a0 := atan2((y1 - cyp) / ry, (x1 - cxp) / rx)
	var a1 := atan2((-y1 - cyp) / ry, (-x1 - cxp) / rx)
	var da := a1 - a0
	if sweep and da < 0.0: da += TAU
	elif not sweep and da > 0.0: da -= TAU
	var steps := clampi(int(absf(da) * maxf(rx, ry) * scale / 2.5), 4, 48)
	for k in range(1, steps + 1):
		var a := a0 + da * float(k) / steps
		var ex := cos(a) * rx; var ey := sin(a) * ry
		out.append(Vector2(cx + cp * ex - sp * ey, cy + sp * ex + cp * ey))
