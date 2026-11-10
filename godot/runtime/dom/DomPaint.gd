# DomPaint — draws laid-out DOM boxes through RenderingServer canvas items
# (one canvas item per element; text, backgrounds, borders, gradients, canvases).
class_name DomPaint
extends RefCounted

var doc
var seq := 0
static var _radial_cache: Dictionary = {}

func _init(doc_) -> void:
	doc = doc_

static func zmap(z: int) -> int:
	var a := absi(z)
	var m := a
	if a > 1000: m = 190 + int((a - 1000) / 100.0)
	elif a > 100: m = 100 + int((a - 100) / 10.0)
	m = mini(m, 400)
	return m if z >= 0 else -m

# Paint `n` and its subtree. `force` repaints even when nothing is flagged.
func paint_tree(n: DomNode, parent_rid: RID, order: int, force: bool, parent_z: int) -> void:
	if n.nodeType != DomNode.ELEMENT: return
	var s := n.st
	if s.get("display", "none") == "none":
		if n.rid.is_valid() and n.st.get("_shown", true):
			RenderingServer.canvas_item_set_visible(n.rid, false)
			n.st["_shown"] = false
		if not n.st.get("_hid", false):
			n.st["_hid"] = true
			_hide_control(n)
		return
	n.st["_hid"] = false
	var fixed: bool = s.position == "fixed"
	var actual_parent = doc.host_rid if fixed else parent_rid
	if not n.rid.is_valid():
		n.rid = RenderingServer.canvas_item_create()
		n.st["_parent_rid"] = RID()
		force = true
	if n.st.get("_parent_rid") != actual_parent:
		RenderingServer.canvas_item_set_parent(n.rid, actual_parent)
		n.st["_parent_rid"] = actual_parent
	if not n.st.get("_shown", false):
		RenderingServer.canvas_item_set_visible(n.rid, true)
		n.st["_shown"] = true
	var positioned: bool = s.position != "static"
	RenderingServer.canvas_item_set_draw_index(n.rid, order + (1000 if positioned else 0))
	var z := 0
	if s.z != null and (positioned or s.get("flex_item", false)): z = zmap(s.z)
	if fixed:
		RenderingServer.canvas_item_set_z_as_relative_to_parent(n.rid, false)
		RenderingServer.canvas_item_set_z_index(n.rid, clampi(parent_z + z, -4000, 4000))
	else:
		RenderingServer.canvas_item_set_z_index(n.rid, z)
	n.eff_z = parent_z + z
	seq += 1
	n.paint_seq = seq
	# transform
	var p := n.parentElement
	var pos := Vector2(n.lx, n.ly)
	if not fixed and p != null and n.pseudo == "": pos -= Vector2(p._scroll_x, p._scroll_y)
	elif not fixed and p != null: pos -= Vector2(p._scroll_x, p._scroll_y)
	var xf := Transform2D(0, pos)
	var tf = s.get("transform")
	if tf != null and tf != "none":
		var m := CssValue.transform(tf, Vector2(n.lw, n.lh), s.fs, doc.viewport_size)
		var origin := Vector2(n.lw, n.lh) * 0.5
		var to = n.cs.get("transform-origin")
		if to != null:
			var parts := CssEngine.split_ws(to)
			origin.x = _origin_part(parts[0], n.lw, s.fs)
			origin.y = _origin_part(parts[1], n.lh, s.fs) if parts.size() > 1 else n.lh * 0.5
		xf = xf * Transform2D(0, origin) * m * Transform2D(0, -origin)
	n.st["_xf"] = xf
	RenderingServer.canvas_item_set_transform(n.rid, xf)
	# opacity / filters
	var mod := Color(1, 1, 1, s.opacity)
	var flt = s.get("filter")
	if flt != null and flt != "none": mod = _filter_mod(flt, mod)
	if not s.visible: mod.a = 0.0
	RenderingServer.canvas_item_set_modulate(n.rid, mod)
	var clip: bool = s.clip
	RenderingServer.canvas_item_set_clip(n.rid, clip)
	if clip: RenderingServer.canvas_item_set_custom_rect(n.rid, true, Rect2(0, 0, n.lw, n.lh))
	else: RenderingServer.canvas_item_set_custom_rect(n.rid, false)
	if force or n.paint_dirty:
		n.paint_dirty = false
		RenderingServer.canvas_item_clear(n.rid)
		_draw_box(n)
	_place_control(n)
	# children
	var i := 0
	if n._before != null:
		paint_tree(n._before, n.rid, i, force, n.eff_z)
		i += 1
	for c in n.childNodes:
		if c.nodeType == DomNode.ELEMENT:
			paint_tree(c, n.rid, i, force, n.eff_z)
			i += 1
	if n._after != null: paint_tree(n._after, n.rid, i, force, n.eff_z)
	if s.get("scrollable", false): _draw_scrollbar(n, i + 2000)
	elif n.st.has("_sb_rid"):
		RenderingServer.canvas_item_clear(n.st["_sb_rid"])

func _origin_part(tok: String, size: float, fs: float) -> float:
	match tok:
		"left", "top": return 0.0
		"center": return size * 0.5
		"right", "bottom": return size
	return CssValue.length(tok, size, fs, doc.viewport_size)

func _filter_mod(flt: String, mod: Color) -> Color:
	for part in CssEngine.split_ws(flt):
		var open := part.find("(")
		if open < 0: continue
		var fname := part.substr(0, open)
		var arg := part.substr(open + 1, part.length() - open - 2)
		var v := CssValue.f(arg)
		if arg.ends_with("%"): v /= 100.0
		match fname:
			"opacity": mod.a *= v
			"brightness":
				mod.r *= v; mod.g *= v; mod.b *= v
			"grayscale":
				var k := 1.0 - 0.35 * v
				mod.r *= k; mod.g *= k; mod.b *= k
			"saturate":
				if v < 1.0:
					var k2 := 0.6 + 0.4 * v
					mod.r *= k2; mod.g *= k2; mod.b *= k2
	return mod

# a hidden subtree: native controls and fixed-position boxes (parented to the viewport) must go too
func _hide_control(n: DomNode) -> void:
	if n.control != null and is_instance_valid(n.control): n.control.visible = false
	for c in n.childNodes:
		if c.nodeType != DomNode.ELEMENT: continue
		if c.rid.is_valid() and c.st.get("_parent_rid") == doc.host_rid and c.st.get("_shown", false):
			RenderingServer.canvas_item_set_visible(c.rid, false)
			c.st["_shown"] = false
		if c.control != null or c.childNodes.size() > 0: _hide_control(c)

func _place_control(n: DomNode) -> void:
	if n.tag != "input": return
	doc.ensure_control(n)
	if n.control == null: return
	var r: Rect2 = doc.client_rect(n)
	n.control.visible = true
	n.control.position = r.position
	n.control.size = r.size

# rounded-rectangle outline (clockwise)
static func rounded_points(x: float, y: float, w: float, h: float, r: Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var maxr := minf(w, h) * 0.5
	var tl := minf(r[0], maxr); var tr := minf(r[1], maxr); var br := minf(r[2], maxr); var bl := minf(r[3], maxr)
	_corner(pts, x + tl, y + tl, tl, PI, 1.5 * PI)
	_corner(pts, x + w - tr, y + tr, tr, 1.5 * PI, TAU)
	_corner(pts, x + w - br, y + h - br, br, 0.0, 0.5 * PI)
	_corner(pts, x + bl, y + h - bl, bl, 0.5 * PI, PI)
	return pts

static func _corner(pts: PackedVector2Array, cx: float, cy: float, r: float, a0: float, a1: float) -> void:
	if r < 0.5:
		pts.append(Vector2(cx, cy))
		return
	var steps := clampi(int(r * 0.6) + 2, 3, 10)
	for i in range(steps + 1):
		var a := a0 + (a1 - a0) * float(i) / float(steps)
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))

func _radii(n: DomNode) -> Array:
	var cs := n.cs
	var fs: float = n.st.fs
	var base := minf(n.lw, n.lh)
	return [
		maxf(0.0, _len(cs.get("border-top-left-radius"), base, fs)), maxf(0.0, _len(cs.get("border-top-right-radius"), base, fs)),
		maxf(0.0, _len(cs.get("border-bottom-right-radius"), base, fs)), maxf(0.0, _len(cs.get("border-bottom-left-radius"), base, fs))]

func _len(v, base: float, fs: float) -> float:
	if v == null: return 0.0
	var r := CssValue.length(v, base, fs, doc.viewport_size)
	return 0.0 if r <= CssValue.AUTO + 1.0 else r

func _draw_box(n: DomNode) -> void:
	var rid := n.rid
	var s := n.st
	var w := n.lw; var h := n.lh
	if s.get("has_box", false) and w > 0.0 and h > 0.0:
		_draw_decor(rid, n, Rect2(0, 0, w, h))
	if n.tag == "canvas":
		if n.canvas_ctx != null:
			var cr := Rect2(n.bor[3] + n.pad[3], n.bor[0] + n.pad[0], w - n.bor[1] - n.bor[3] - n.pad[1] - n.pad[3], h - n.bor[0] - n.bor[2] - n.pad[0] - n.pad[2])
			var pix: bool = n.cs.get("image-rendering", "auto") != "auto"
			RenderingServer.canvas_item_set_default_texture_filter(rid, RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST if pix else RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_LINEAR)
			RenderingServer.canvas_item_set_material(rid, doc.premult_material.get_rid())
			RenderingServer.canvas_item_add_texture_rect(rid, cr, n.canvas_ctx.texture_rid())
	elif n.tag == "svg":
		DomSvg.draw(rid, n, doc)
	for f in n.frags:
		if f.t == "ibox":
			_draw_decor(rid, f.n, Rect2(f.x, f.y, f.w, f.h))
	var clip_x := INF
	for f in n.frags:
		if f.t == "clip": clip_x = f.x + f.w
	for f in n.frags:
		if f.t != "text": continue
		var sn: DomNode = f.n
		var fs_: Dictionary = sn.st
		if not fs_.get("visible", true): continue
		var text: String = f.text
		var font: Font = fs_.font
		var px: float = fs_.fs
		if clip_x < INF and f.x + f.w > clip_x:
			text = _ellipsize(font, text, px, clip_x - f.x, fs_.ls)
			if text == "": continue
		draw_text(rid, font, Vector2(f.x, f.y), text, px, fs_.color, fs_.get("shadows"), fs_.ls)
		var deco = sn.cs.get("text-decoration")
		if deco != null and deco.contains("underline"):
			RenderingServer.canvas_item_add_line(rid, Vector2(f.x, f.y + 2), Vector2(f.x + f.w, f.y + 2), fs_.color, maxf(1.0, px / 14.0))
		elif deco != null and deco.contains("line-through"):
			RenderingServer.canvas_item_add_line(rid, Vector2(f.x, f.y - px * 0.3), Vector2(f.x + f.w, f.y - px * 0.3), fs_.color, maxf(1.0, px / 14.0))

func _ellipsize(font: Font, text: String, px: float, avail: float, ls: float = 0.0) -> String:
	var ell := "…"
	var ew := DomFonts.width(font, ell, px)
	if avail <= ew: return ""
	var out := text
	while out.length() > 0 and DomFonts.width(font, out, px, ls) + ew > avail: out = out.substr(0, out.length() - 1)
	return out.strip_edges(false, true) + ell

# Text at fractional pixel sizes: draw at the nearest integer size and scale.
func draw_text(rid: RID, font: Font, pos: Vector2, text: String, px: float, col: Color, shadows = null, ls: float = 0.0) -> void:
	var isz := maxi(1, int(round(px)))
	var k := px / float(isz)
	var scaled := absf(k - 1.0) > 0.004
	if scaled: RenderingServer.canvas_item_add_set_transform(rid, Transform2D(Vector2(k, 0), Vector2(0, k), pos))
	var at := Vector2.ZERO if scaled else pos
	var sp := ls / k
	if shadows != null:
		for sh in shadows:
			var off := Vector2(sh.x, sh.y) / (k if scaled else 1.0)
			var sc: Color = sh.color
			if sh.blur > 0.5:
				# soft glow: a few offset copies at reduced alpha
				var rad: float = minf(sh.blur * 0.35, 6.0) / (k if scaled else 1.0)
				var c2 := Color(sc.r, sc.g, sc.b, sc.a * 0.22)
				for a in range(8):
					var d := Vector2(cos(a * TAU / 8.0), sin(a * TAU / 8.0)) * rad
					DomFonts.draw(rid, font, at + off + d, text, isz, c2, sp)
				DomFonts.draw(rid, font, at + off, text, isz, Color(sc.r, sc.g, sc.b, sc.a * 0.35), sp)
			else:
				DomFonts.draw(rid, font, at + off, text, isz, sc, sp)
	DomFonts.draw(rid, font, at, text, isz, col, sp)
	if scaled: RenderingServer.canvas_item_add_set_transform(rid, Transform2D.IDENTITY)

# background, border, box-shadow of a box occupying `rect`
func _draw_decor(rid: RID, n: DomNode, rect: Rect2) -> void:
	var cs := n.cs
	var s := n.st
	var radii := _radii(n)
	var bg: Color = s.get("bg", Color(0, 0, 0, 0))
	var bw: Array = n.bor
	var bcols := [CssValue.color(cs.get("border-top-color", "currentcolor"), s.color), CssValue.color(cs.get("border-right-color", "currentcolor"), s.color),
		CssValue.color(cs.get("border-bottom-color", "currentcolor"), s.color), CssValue.color(cs.get("border-left-color", "currentcolor"), s.color)]
	for i in range(4):
		if cs.get("border-" + ["top", "right", "bottom", "left"][i] + "-color", "currentcolor") == "currentcolor": bcols[i] = s.color
	var has_border: bool = bw[0] + bw[1] + bw[2] + bw[3] > 0.0
	var uniform := true
	var first_col = null
	for i in range(4):
		if bw[i] > 0.0:
			if first_col == null: first_col = bcols[i]
			elif first_col != bcols[i]: uniform = false
	var clip_path = cs.get("clip-path")
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = int(round(radii[0])); sb.corner_radius_top_right = int(round(radii[1]))
	sb.corner_radius_bottom_right = int(round(radii[2])); sb.corner_radius_bottom_left = int(round(radii[3]))
	sb.corner_detail = 8
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 0.6
	var sh_list = s.get("box_shadows")
	if sh_list != null:
		for sh in sh_list:
			if sh.inset: continue
			var ssb := StyleBoxFlat.new()
			ssb.bg_color = Color(0, 0, 0, 0)
			ssb.draw_center = false
			ssb.corner_radius_top_left = sb.corner_radius_top_left; ssb.corner_radius_top_right = sb.corner_radius_top_right
			ssb.corner_radius_bottom_right = sb.corner_radius_bottom_right; ssb.corner_radius_bottom_left = sb.corner_radius_bottom_left
			var c: Color = sh.color
			var size: float = sh.blur * 0.75 + sh.spread
			ssb.shadow_color = Color(c.r, c.g, c.b, c.a * (0.55 if sh.blur > 0.0 else 1.0))
			ssb.shadow_size = int(ceil(maxf(size, 1.0)))
			ssb.shadow_offset = Vector2(sh.x, sh.y)
			ssb.draw(rid, rect)
	if clip_path != null and clip_path.begins_with("polygon("):
		var pts := _clip_polygon(clip_path, rect, n)
		if pts.size() >= 3:
			if bg.a > 0.0: RenderingServer.canvas_item_add_polygon(rid, pts, PackedColorArray([bg]))
			var img = cs.get("background-image")
			if img != null and img != "none": _draw_gradients(rid, n, img, rect, pts)
			return
	if has_border and uniform:
		sb.border_color = first_col
		sb.border_width_top = int(round(bw[0])) if bw[0] >= 0.5 else (1 if bw[0] > 0.0 else 0)
		sb.border_width_right = int(round(bw[1])) if bw[1] >= 0.5 else (1 if bw[1] > 0.0 else 0)
		sb.border_width_bottom = int(round(bw[2])) if bw[2] >= 0.5 else (1 if bw[2] > 0.0 else 0)
		sb.border_width_left = int(round(bw[3])) if bw[3] >= 0.5 else (1 if bw[3] > 0.0 else 0)
		var style: String = cs.get("border-top-style", "solid")
		if style == "dashed" or style == "dotted": sb.border_color = Color(first_col.r, first_col.g, first_col.b, first_col.a * 0.75)
	if bg.a > 0.0 or (has_border and uniform):
		sb.draw(rid, rect)
	var img2 = cs.get("background-image")
	if img2 != null and img2 != "none":
		var inner := Rect2(rect.position + Vector2(bw[3], bw[0]), rect.size - Vector2(bw[1] + bw[3], bw[0] + bw[2]))
		var ir := [maxf(0.0, radii[0] - bw[0]), maxf(0.0, radii[1] - bw[0]), maxf(0.0, radii[2] - bw[2]), maxf(0.0, radii[3] - bw[2])]
		_draw_gradients(rid, n, img2, inner, rounded_points(inner.position.x, inner.position.y, inner.size.x, inner.size.y, ir))
	if has_border and not uniform:
		var x := rect.position.x; var y := rect.position.y; var w := rect.size.x; var h := rect.size.y
		if bw[0] > 0.0: RenderingServer.canvas_item_add_rect(rid, Rect2(x, y, w, bw[0]), bcols[0])
		if bw[2] > 0.0: RenderingServer.canvas_item_add_rect(rid, Rect2(x, y + h - bw[2], w, bw[2]), bcols[2])
		if bw[3] > 0.0: RenderingServer.canvas_item_add_rect(rid, Rect2(x, y, bw[3], h), bcols[3])
		if bw[1] > 0.0: RenderingServer.canvas_item_add_rect(rid, Rect2(x + w - bw[1], y, bw[1], h), bcols[1])
	# inset shadows: approximated by a soft inner frame
	if sh_list != null:
		for sh in sh_list:
			if not sh.inset: continue
			var c2: Color = sh.color
			var t: float = clampf(sh.blur * 0.5 + sh.spread, 1.0, 14.0)
			var isb := StyleBoxFlat.new()
			isb.draw_center = false
			isb.bg_color = Color(0, 0, 0, 0)
			isb.border_color = Color(c2.r, c2.g, c2.b, c2.a * 0.45)
			isb.set_border_width_all(int(ceil(t)))
			isb.border_blend = true
			isb.corner_radius_top_left = sb.corner_radius_top_left; isb.corner_radius_top_right = sb.corner_radius_top_right
			isb.corner_radius_bottom_right = sb.corner_radius_bottom_right; isb.corner_radius_bottom_left = sb.corner_radius_bottom_left
			isb.draw(rid, rect)

func _clip_polygon(clip_path: String, rect: Rect2, n: DomNode) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var inner := clip_path.substr(8, clip_path.rfind(")") - 8)
	for pair in CssEngine._split_top(inner, ","):
		var xy := CssEngine.split_ws(pair.strip_edges())
		if xy.size() < 2: continue
		var px := CssValue.length(xy[0], rect.size.x, n.st.fs, doc.viewport_size)
		var py := CssValue.length(xy[1], rect.size.y, n.st.fs, doc.viewport_size)
		pts.append(rect.position + Vector2(px, py))
	return pts

func _draw_gradients(rid: RID, n: DomNode, img: String, rect: Rect2, pts: PackedVector2Array) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0 or pts.size() < 3: return
	var layers := CssEngine._split_top(img, ",")
	for li in range(layers.size() - 1, -1, -1):
		var g = CssValue.gradient(layers[li])
		if g == null: continue
		draw_gradient(rid, g, rect, pts)

# Fill polygon `pts` with a CSS gradient defined over `rect`.
static func draw_gradient(rid: RID, g: Dictionary, rect: Rect2, pts: PackedVector2Array) -> void:
	var uvs := PackedVector2Array()
	var white := PackedColorArray([Color(1, 1, 1, 1)])
	if g.kind == "linear":
		var ang := deg_to_rad(g.angle)
		var dir := Vector2(sin(ang), -cos(ang))
		var length := absf(rect.size.x * sin(ang)) + absf(rect.size.y * cos(ang))
		var center := rect.position + rect.size * 0.5
		var stops := CssValue.resolve_stops(g.stops, length)
		var tex := CssValue.ramp_texture(stops)
		for p in pts:
			var t := (p - center).dot(dir) / maxf(length, 0.001) + 0.5
			uvs.append(Vector2(clampf(t, 0.002, 0.998), 0.5))
		RenderingServer.canvas_item_add_polygon(rid, pts, white, uvs, tex.get_rid())
	else:
		var c := rect.position + Vector2(rect.size.x * g.cx, rect.size.y * g.cy)
		var dx := maxf(c.x - rect.position.x, rect.end.x - c.x)
		var dy := maxf(c.y - rect.position.y, rect.end.y - c.y)
		var rx: float; var ry: float
		if g.shape == "circle":
			rx = sqrt(dx * dx + dy * dy); ry = rx
		else:
			rx = dx * 1.41421; ry = dy * 1.41421
		var stops2 := CssValue.resolve_stops(g.stops, rx)
		var tex2 := radial_texture(stops2)
		for p in pts:
			var u := 0.5 + (p.x - c.x) / (2.0 * maxf(rx, 0.001))
			var v := 0.5 + (p.y - c.y) / (2.0 * maxf(ry, 0.001))
			uvs.append(Vector2(clampf(u, 0.0, 1.0), clampf(v, 0.0, 1.0)))
		RenderingServer.canvas_item_add_polygon(rid, pts, white, uvs, tex2.get_rid())

# square texture with a radial ramp (centre → edge)
static func radial_texture(stops: Array) -> Texture2D:
	var key := ""
	for st in stops: key += "%.4f:%s;" % [st[0], (st[1] as Color).to_html(true)]
	var hit = _radial_cache.get(key)
	if hit != null: return hit
	var grad := Gradient.new()
	var offs := PackedFloat32Array(); var cols := PackedColorArray()
	for st in stops:
		offs.append(clampf(st[0], 0.0, 1.0)); cols.append(st[1])
	grad.offsets = offs; grad.colors = cols
	grad.interpolation_color_space = Gradient.GRADIENT_COLOR_SPACE_SRGB
	var tex := GradientTexture2D.new()
	tex.width = 128; tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.gradient = grad
	if _radial_cache.size() > 400: _radial_cache.clear()
	_radial_cache[key] = tex
	return tex

func _draw_scrollbar(n: DomNode, order: int) -> void:
	var view_h = n.lh - n.bor[0] - n.bor[2]
	if not n.st.has("_sb_rid"):
		var r := RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(r, n.rid)
		n.st["_sb_rid"] = r
	var sb: RID = n.st["_sb_rid"]
	RenderingServer.canvas_item_clear(sb)
	RenderingServer.canvas_item_set_draw_index(sb, order)
	if n.content_h <= view_h + 1.0 or n.cs.get("overflow-y", "visible") == "hidden": return
	var track_h = view_h - 4.0
	var thumb_h := maxf(18.0, track_h * view_h / n.content_h)
	var maxs = n.content_h - view_h
	var ty = 2.0 + (track_h - thumb_h) * (n._scroll_y / maxs if maxs > 0.0 else 0.0)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.22)
	box.set_corner_radius_all(3)
	box.draw(sb, Rect2(n.lw - n.bor[1] - 6.0, n.bor[0] + ty, 4.0, thumb_h))
