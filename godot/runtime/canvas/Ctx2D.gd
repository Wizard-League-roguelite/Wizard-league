# Ctx2D — CanvasRenderingContext2D look-alike.
# Each <canvas> owns a SubViewport that is never cleared automatically, so drawing
# accumulates exactly like a browser canvas bitmap.  Draw calls are forwarded to
# RenderingServer canvas items; once a frame has been rendered they are discarded.
class_name Ctx2D
extends RefCounted

static var frame_id := 0        # advanced once per process frame by Boot

var _owner: WeakRef
var canvas: DomNode:
	get: return _owner.get_ref()
var vp: SubViewport
var _root: RID                  # canvas item attached to the viewport canvas
var _ci: RID                    # current target item (root or a clip layer)
var _layers: Array = []         # extra items created for clipping
var _frame := -1
var _w := 300; var _h := 150

# drawing state
var _xf := Transform2D.IDENTITY
var _xf_sent := false
var _sent_xf := Transform2D.IDENTITY
var _stack: Array = []
var _fill = Color(0, 0, 0, 1)   # Color or JSGradient
var _stroke = Color(0, 0, 0, 1)
var _fill_src = "#000"
var _stroke_src = "#000"
var _alpha := 1.0
var lineWidth = 1.0
var lineCap := "butt"
var lineJoin := "miter"
var miterLimit = 10.0
var lineDashOffset = 0.0
var textAlign := "start"
var textBaseline := "alphabetic"
var shadowColor = "rgba(0,0,0,0)"
var shadowBlur = 0.0
var shadowOffsetX = 0.0
var shadowOffsetY = 0.0
var imageSmoothingEnabled = true
var globalCompositeOperation := "source-over"
var filter := "none"
var _font_src := "10px sans-serif"
var _font: Font
var _font_px := 10.0
var _clip_active := false

# current path (device space)
var _subs: Array = []           # Array[PackedVector2Array]
var _closed: Array = []
var _cur := PackedVector2Array()
var _cur_closed := false
var _pen := Vector2.ZERO        # last point (user space)

static var _font_cache: Dictionary = {}

func _init(owner_: DomNode, w: int, h: int) -> void:
	_owner = weakref(owner_)
	_w = w; _h = h
	vp = SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.msaa_2d = Viewport.MSAA_4X
	vp.gui_disable_input = true
	document.add_child(vp)
	_root = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(_root, vp.find_world_2d().canvas)
	_ci = _root
	_font = DomFonts.font("sans-serif", false, false, 0.0)

func dispose() -> void:
	for l in _layers: RenderingServer.free_rid(l)
	_layers.clear()
	if _root.is_valid(): RenderingServer.free_rid(_root)
	_root = RID()
	if vp != null and is_instance_valid(vp): vp.queue_free()
	vp = null

func texture_rid() -> RID:
	return vp.get_texture().get_rid()

func resize(w: int, h: int) -> void:
	_w = w; _h = h
	if vp == null: return
	if vp.size != Vector2i(w, h): vp.size = Vector2i(w, h)
	_reset_commands()
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	# resizing a canvas resets its state
	_xf = Transform2D.IDENTITY
	_stack.clear()
	_alpha = 1.0
	_frame = frame_id

func _reset_commands() -> void:
	for l in _layers: RenderingServer.free_rid(l)
	_layers.clear()
	RenderingServer.canvas_item_clear(_root)
	_ci = _root
	_xf_sent = false
	_clip_active = false

# called before every draw: discards commands that were already rendered
func _begin() -> void:
	if _frame != frame_id:
		_frame = frame_id
		_reset_commands()
		if vp != null: vp.render_target_update_mode = SubViewport.UPDATE_ONCE

func _use_xf(t: Transform2D) -> void:
	if not _xf_sent or _sent_xf != t:
		RenderingServer.canvas_item_add_set_transform(_ci, t)
		_sent_xf = t
		_xf_sent = true

# ───────────────────────── state ─────────────────────────
var fillStyle:
	get: return _fill_src
	set(v):
		_fill_src = v
		if v is JSGradient: _fill = v
		elif v is String: _fill = CssValue.color(v, Color(0, 0, 0, 1))
var strokeStyle:
	get: return _stroke_src
	set(v):
		_stroke_src = v
		if v is JSGradient: _stroke = v
		elif v is String: _stroke = CssValue.color(v, Color(0, 0, 0, 1))
var globalAlpha:
	get: return _alpha
	set(v):
		if v == null: return
		var f := float(v)
		if is_nan(f): return
		_alpha = clampf(f, 0.0, 1.0)
var font:
	get: return _font_src
	set(v):
		_font_src = JS.s(v)
		var hit = _font_cache.get(_font_src)
		if hit == null:
			hit = _parse_font(_font_src)
			_font_cache[_font_src] = hit
		_font = hit[0]; _font_px = hit[1]

static func _parse_font(s: String) -> Array:
	var bold := false; var italic := false
	var px := 10.0
	var family := "sans-serif"
	var toks := CssEngine.split_ws(s)
	var i := 0
	while i < toks.size():
		var t := toks[i]
		var tl := t.to_lower()
		if tl == "bold" or tl == "bolder" or (tl.is_valid_int() and tl.to_int() >= 600): bold = true
		elif tl == "italic" or tl == "oblique": italic = true
		elif tl == "normal" or tl.is_valid_int(): pass
		elif tl.contains("px") or tl.ends_with("em") or tl.ends_with("pt"):
			var sz := tl.split("/")[0]
			if sz.ends_with("px"): px = CssValue.f(sz)
			elif sz.ends_with("rem"): px = CssValue.f(sz) * 16.0
			elif sz.ends_with("em"): px = CssValue.f(sz) * 16.0
			elif sz.ends_with("pt"): px = CssValue.f(sz) * 4.0 / 3.0
			family = " ".join(toks.slice(i + 1))
			break
		i += 1
	return [DomFonts.font(family, bold, italic, 0.0), maxf(1.0, px)]

func save() -> void:
	_stack.append([_xf, _fill, _fill_src, _stroke, _stroke_src, _alpha, lineWidth, lineCap, lineJoin, textAlign, textBaseline,
		shadowColor, shadowBlur, _font_src, _font, _font_px, _clip_active, shadowOffsetX, shadowOffsetY])

func restore() -> void:
	if _stack.is_empty(): return
	var s: Array = _stack.pop_back()
	_xf = s[0]; _fill = s[1]; _fill_src = s[2]; _stroke = s[3]; _stroke_src = s[4]; _alpha = s[5]
	lineWidth = s[6]; lineCap = s[7]; lineJoin = s[8]; textAlign = s[9]; textBaseline = s[10]
	shadowColor = s[11]; shadowBlur = s[12]; _font_src = s[13]; _font = s[14]; _font_px = s[15]
	shadowOffsetX = s[17]; shadowOffsetY = s[18]
	if _clip_active and not s[16]:
		# leave the clip layer: later drawing goes to a fresh unclipped layer
		_clip_active = false
		if _frame == frame_id: _new_layer(false, Rect2())

func _new_layer(clip: bool, rect: Rect2) -> void:
	var l := RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(l, _root)
	RenderingServer.canvas_item_set_draw_index(l, _layers.size() + 1)
	if clip:
		RenderingServer.canvas_item_set_custom_rect(l, true, rect)
		RenderingServer.canvas_item_set_clip(l, true)
	_layers.append(l)
	_ci = l
	_xf_sent = false

func translate(x = 0, y = 0) -> void:
	_xf = _xf * Transform2D(0, Vector2(x, y))

func scale(x = 1, y = null) -> void:
	if y == null: y = x
	_xf = _xf * Transform2D(Vector2(x, 0), Vector2(0, y), Vector2.ZERO)

func rotate(a = 0) -> void:
	_xf = _xf * Transform2D(float(a), Vector2.ZERO)

func transform(a, b, c, d, e, f) -> void:
	_xf = _xf * Transform2D(Vector2(a, b), Vector2(c, d), Vector2(e, f))

func setTransform(a = 1, b = 0, c = 0, d = 1, e = 0, f = 0) -> void:
	_xf = Transform2D(Vector2(a, b), Vector2(c, d), Vector2(e, f))

func resetTransform() -> void:
	_xf = Transform2D.IDENTITY

func setLineDash(_a = null) -> void:
	pass

# ───────────────────────── gradients ─────────────────────────
func createLinearGradient(x0, y0, x1, y1) -> JSGradient:
	var g := JSGradient.new()
	g.p0 = Vector2(x0, y0); g.p1 = Vector2(x1, y1)
	return g

func createRadialGradient(x0, y0, r0, x1, y1, r1) -> JSGradient:
	var g := JSGradient.new()
	g.radial = true
	g.p0 = Vector2(x0, y0); g.r0 = float(r0); g.p1 = Vector2(x1, y1); g.r1 = float(r1)
	return g

func _col(c: Color) -> Color:
	return c if _alpha >= 1.0 else Color(c.r, c.g, c.b, c.a * _alpha)

# Fill a polygon given in the coordinate space of transform `t` with a paint.
func _fill_poly(pts: PackedVector2Array, paint, t: Transform2D, user_from_pts: Transform2D) -> void:
	if pts.size() < 3: return
	_use_xf(t)
	if paint is Color:
		var c := _col(paint)
		if c.a <= 0.0: return
		_poly(pts, PackedColorArray([c]), PackedVector2Array(), RID())
	elif paint is JSGradient:
		var g: JSGradient = paint
		var uvs := PackedVector2Array()
		for p in pts: uvs.append(g.uv(user_from_pts * p))
		_poly(pts, PackedColorArray([Color(1, 1, 1, _alpha)]), uvs, g.texture().get_rid())

func _poly(pts: PackedVector2Array, cols: PackedColorArray, uvs: PackedVector2Array, tex: RID) -> void:
	var n := pts.size()
	var idx: PackedInt32Array
	if n == 3: idx = PackedInt32Array([0, 1, 2])
	elif n == 4 and uvs.is_empty() and false: idx = PackedInt32Array([0, 1, 2, 0, 2, 3])
	else:
		idx = Geometry2D.triangulate_polygon(pts)
		if idx.is_empty():
			# degenerate / self-intersecting outline: fall back to its convex hull
			var hull := Geometry2D.convex_hull(pts)
			if hull.size() < 4: return
			hull.resize(hull.size() - 1)
			if not uvs.is_empty(): return
			pts = hull
			idx = Geometry2D.triangulate_polygon(pts)
			if idx.is_empty(): return
	var colors := cols
	if cols.size() == 1 and pts.size() > 1:
		colors = PackedColorArray()
		colors.resize(pts.size())
		colors.fill(cols[0])
	if tex.is_valid(): RenderingServer.canvas_item_add_triangle_array(_ci, idx, pts, colors, uvs, PackedInt32Array(), PackedFloat32Array(), tex)
	else: RenderingServer.canvas_item_add_triangle_array(_ci, idx, pts, colors)

# ───────────────────────── rectangles ─────────────────────────
func fillRect(x, y, w, h) -> void:
	_begin()
	if w == null or h == null: return
	var r := Rect2(x, y, w, h).abs()
	if _fill is Color:
		var c: Color = _fill
		if _alpha < 1.0: c = Color(c.r, c.g, c.b, c.a * _alpha)
		if c.a <= 0.0: return
		if float(shadowBlur) > 0.0: _shadow_rect(r)
		_use_xf(_xf)
		RenderingServer.canvas_item_add_rect(_ci, r, c)
	else:
		var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		_fill_poly(pts, _fill, _xf, Transform2D.IDENTITY)

func _shadow_rect(r: Rect2) -> void:
	var sc := CssValue.color(shadowColor, Color(0, 0, 0, 0))
	if sc.a <= 0.0: return
	var blur := float(shadowBlur)
	_use_xf(_xf)
	var steps := 3
	for i in range(steps, 0, -1):
		var g := blur * 0.5 * float(i) / float(steps)
		RenderingServer.canvas_item_add_rect(_ci, r.grow(g), Color(sc.r, sc.g, sc.b, sc.a * _alpha * 0.16))

func strokeRect(x, y, w, h) -> void:
	_begin()
	var r := Rect2(x, y, w, h).abs()
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position])
	_stroke_line(pts, _xf, Transform2D.IDENTITY, true)

func clearRect(x, y, w, h) -> void:
	var r := Rect2(x, y, w, h).abs()
	var dev := _xf * r
	if dev.position.x <= 0.5 and dev.position.y <= 0.5 and dev.end.x >= _w - 0.5 and dev.end.y >= _h - 0.5:
		# whole bitmap: drop everything drawn so far and clear the target
		_frame = frame_id
		_reset_commands()
		if vp != null:
			vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	# partial clear: punch a transparent hole using a non-blending layer
	_begin()
	var l := RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(l, _root)
	RenderingServer.canvas_item_set_draw_index(l, _layers.size() + 1)
	RenderingServer.canvas_item_set_material(l, _erase_material().get_rid())
	RenderingServer.canvas_item_add_set_transform(l, _xf)
	RenderingServer.canvas_item_add_rect(l, r, Color(0, 0, 0, 0))
	_layers.append(l)
	_new_layer(false, Rect2())

static var _erase_mat: ShaderMaterial = null
static func _erase_material() -> ShaderMaterial:
	if _erase_mat == null:
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;\nrender_mode blend_disabled;\nvoid fragment() { COLOR = vec4(0.0); }\n"
		_erase_mat = ShaderMaterial.new()
		_erase_mat.shader = sh
	return _erase_mat

# ───────────────────────── paths ─────────────────────────
func beginPath() -> void:
	_subs = []
	_closed = []
	_cur = PackedVector2Array()
	_cur_closed = false

func _flush_sub() -> void:
	if _cur.size() > 0:
		_subs.append(_cur)
		_closed.append(_cur_closed)
	_cur = PackedVector2Array()
	_cur_closed = false

func moveTo(x, y) -> void:
	_flush_sub()
	_pen = Vector2(x, y)
	_cur.append(_xf * _pen)

func lineTo(x, y) -> void:
	_pen = Vector2(x, y)
	if _cur.is_empty(): _cur.append(_xf * _pen)
	else: _cur.append(_xf * _pen)

func closePath() -> void:
	if _cur.size() > 1:
		_cur_closed = true
		var first := _cur[0]
		_flush_sub()
		# a new sub-path starts at the closed path's first point
		_cur.append(first)
		_pen = _xf.affine_inverse() * first

func rect(x, y, w, h) -> void:
	_flush_sub()
	_cur.append(_xf * Vector2(x, y)); _cur.append(_xf * Vector2(x + w, y)); _cur.append(_xf * Vector2(x + w, y + h)); _cur.append(_xf * Vector2(x, y + h))
	_cur_closed = true
	_flush_sub()
	_pen = Vector2(x, y)

func roundRect(x, y, w, h, r = 0) -> void:
	_flush_sub()
	var rad := 0.0
	if r is Array: rad = float(r[0]) if r.size() > 0 else 0.0
	else: rad = float(r)
	for p in DomPaint.rounded_points(x, y, w, h, [rad, rad, rad, rad]): _cur.append(_xf * p)
	_cur_closed = true
	_flush_sub()

func _scale_hint() -> float:
	return maxf(0.01, (_xf.x.length() + _xf.y.length()) * 0.5)

func arc(x, y, r, a0, a1, ccw = false) -> void:
	ellipse(x, y, r, r, 0.0, a0, a1, ccw)

func ellipse(x, y, rx, ry, rot, a0, a1, ccw = false) -> void:
	if rx == null or ry == null: return
	rx = absf(float(rx)); ry = absf(float(ry))
	var start := float(a0); var end := float(a1)
	var sweep := end - start
	if not JS.t(ccw):
		if sweep < 0.0: sweep = fposmod(sweep, TAU)
		if sweep > TAU: sweep = TAU
	else:
		if sweep > 0.0: sweep = fposmod(sweep, TAU) - TAU
		if sweep < -TAU: sweep = -TAU
	var dev_r := maxf(rx, ry) * _scale_hint()
	var steps := clampi(int(ceil(absf(sweep) * dev_r / 2.5)), 6, 96)
	if absf(sweep) < 0.0001: steps = 1
	var cr := cos(float(rot)); var sr := sin(float(rot))
	for i in range(steps + 1):
		var a := start + sweep * float(i) / float(steps)
		var px: float = cos(a) * rx; var py: float = sin(a) * ry
		var p := Vector2(x + px * cr - py * sr, y + px * sr + py * cr)
		_cur.append(_xf * p)
		_pen = p

func arcTo(x1, y1, x2, y2, r) -> void:
	var p0 := _pen
	var p1 := Vector2(x1, y1); var p2 := Vector2(x2, y2)
	var rad := float(r)
	var d0 := (p0 - p1); var d2 := (p2 - p1)
	if rad <= 0.0 or d0.length() < 0.0001 or d2.length() < 0.0001:
		lineTo(x1, y1)
		return
	d0 = d0.normalized(); d2 = d2.normalized()
	var cosang := clampf(d0.dot(d2), -1.0, 1.0)
	var ang := acos(cosang)
	if ang < 0.0001 or absf(ang - PI) < 0.0001:
		lineTo(x1, y1)
		return
	var dist := rad / tan(ang * 0.5)
	var t0 := p1 + d0 * dist; var t2 := p1 + d2 * dist
	var bis := (d0 + d2).normalized()
	var center := p1 + bis * (rad / sin(ang * 0.5))
	var a_start := (t0 - center).angle(); var a_end := (t2 - center).angle()
	var cross := d0.cross(d2)
	lineTo(t0.x, t0.y)
	var sweep := a_end - a_start
	if cross > 0.0:   # turn counter-clockwise in canvas coords
		if sweep > 0.0: sweep -= TAU
	else:
		if sweep < 0.0: sweep += TAU
	var steps := clampi(int(ceil(absf(sweep) * rad * _scale_hint() / 2.5)), 3, 32)
	for i in range(1, steps + 1):
		var a := a_start + sweep * float(i) / float(steps)
		var p := center + Vector2(cos(a), sin(a)) * rad
		_cur.append(_xf * p)
		_pen = p

func quadraticCurveTo(cx, cy, x, y) -> void:
	var p0 := _pen; var c := Vector2(cx, cy); var p1 := Vector2(x, y)
	if _cur.is_empty(): _cur.append(_xf * p0)
	var steps := clampi(int(((c - p0).length() + (p1 - c).length()) * _scale_hint() / 4.0), 4, 40)
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var p := p0.lerp(c, t).lerp(c.lerp(p1, t), t)
		_cur.append(_xf * p)
	_pen = p1

func bezierCurveTo(c1x, c1y, c2x, c2y, x, y) -> void:
	var p0 := _pen; var c1 := Vector2(c1x, c1y); var c2 := Vector2(c2x, c2y); var p1 := Vector2(x, y)
	if _cur.is_empty(): _cur.append(_xf * p0)
	var steps := clampi(int(((c1 - p0).length() + (c2 - c1).length() + (p1 - c2).length()) * _scale_hint() / 4.0), 6, 48)
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		_cur.append(_xf * p0.bezier_interpolate(c1, c2, p1, t))
	_pen = p1

func _all_subs() -> Array:
	var subs := _subs.duplicate()
	var closed := _closed.duplicate()
	if _cur.size() > 0:
		subs.append(_cur)
		closed.append(_cur_closed)
	return [subs, closed]

func fill(_rule = null) -> void:
	_begin()
	var a := _all_subs()
	var inv := _xf.affine_inverse()
	for sp in a[0]:
		var pts: PackedVector2Array = sp
		if pts.size() < 3: continue
		if float(shadowBlur) > 0.0: _shadow_poly(pts)
		_fill_poly(_dedupe(pts), _fill, Transform2D.IDENTITY, inv)

func _dedupe(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		if out.is_empty() or out[out.size() - 1].distance_squared_to(p) > 0.0004: out.append(p)
	if out.size() > 1 and out[0].distance_squared_to(out[out.size() - 1]) <= 0.0004: out.resize(out.size() - 1)
	return out

func _shadow_poly(pts: PackedVector2Array) -> void:
	var sc := CssValue.color(shadowColor, Color(0, 0, 0, 0))
	if sc.a <= 0.0: return
	var blur := minf(float(shadowBlur), 40.0) * _scale_hint()
	var c := Vector2.ZERO
	for p in pts: c += p
	c /= float(pts.size())
	_use_xf(Transform2D.IDENTITY)
	for i in range(3, 0, -1):
		var g := blur * 0.5 * float(i) / 3.0
		var grown := PackedVector2Array()
		for p in pts:
			var d := p - c
			var l := d.length()
			grown.append(p + (d / l * g if l > 0.001 else Vector2.ZERO))
		_poly(_dedupe(grown), PackedColorArray([Color(sc.r, sc.g, sc.b, sc.a * _alpha * 0.16)]), PackedVector2Array(), RID())

func stroke() -> void:
	_begin()
	var a := _all_subs()
	var inv := _xf.affine_inverse()
	for i in range(a[0].size()):
		var pts: PackedVector2Array = a[0][i]
		if pts.size() < 2: continue
		if a[1][i]:
			pts = pts.duplicate()
			pts.append(pts[0])
		_stroke_line(pts, Transform2D.IDENTITY, inv, false)

# pts are in the space of transform `t`; `user_from_pts` maps them to user space (for gradients)
func _stroke_line(pts: PackedVector2Array, t: Transform2D, user_from_pts: Transform2D, user_space: bool) -> void:
	var width := float(lineWidth) * (1.0 if user_space else _scale_hint())
	if width <= 0.0: return
	var col: Color
	if _stroke is Color: col = _col(_stroke)
	else:
		var g: JSGradient = _stroke
		col = _col(g.sample(g.t_of(user_from_pts * pts[pts.size() / 2])))
	if col.a <= 0.0: return
	if float(shadowBlur) > 0.0:
		var sc := CssValue.color(shadowColor, Color(0, 0, 0, 0))
		if sc.a > 0.0:
			_use_xf(t)
			var gw := minf(float(shadowBlur), 30.0) * (1.0 if user_space else _scale_hint())
			RenderingServer.canvas_item_add_polyline(_ci, pts, PackedColorArray([Color(sc.r, sc.g, sc.b, sc.a * _alpha * 0.25)]), width + gw, false)
	_use_xf(t)
	var clean := PackedVector2Array()
	for p in pts:
		if clean.is_empty() or clean[clean.size() - 1].distance_squared_to(p) > 0.000001: clean.append(p)
	if clean.size() < 2:
		if lineCap == "round" or lineCap == "square": RenderingServer.canvas_item_add_circle(_ci, pts[0], width * 0.5, col)
		return
	RenderingServer.canvas_item_add_polyline(_ci, clean, PackedColorArray([col]), width, width > 1.5)
	if lineCap == "round" and width >= 2.5:
		RenderingServer.canvas_item_add_circle(_ci, clean[0], width * 0.5, col)
		RenderingServer.canvas_item_add_circle(_ci, clean[clean.size() - 1], width * 0.5, col)
	if lineJoin == "round" and width >= 3.5:
		for i in range(1, clean.size() - 1): RenderingServer.canvas_item_add_circle(_ci, clean[i], width * 0.5, col)

func clip(_rule = null) -> void:
	_begin()
	var a := _all_subs()
	var r := Rect2()
	var first := true
	for sp in a[0]:
		for p in sp:
			if first:
				r = Rect2(p, Vector2.ZERO); first = false
			else: r = r.expand(p)
	if first: return
	_clip_active = true
	_new_layer(true, r)

# ───────────────────────── text ─────────────────────────
func measureText(text) -> Dictionary:
	var w := DomFonts.width(_font, JS.s(text), _font_px)
	return {"width": w, "actualBoundingBoxAscent": DomFonts.ascent(_font, _font_px) * 0.75, "actualBoundingBoxDescent": DomFonts.descent(_font, _font_px) * 0.5,
		"fontBoundingBoxAscent": DomFonts.ascent(_font, _font_px), "fontBoundingBoxDescent": DomFonts.descent(_font, _font_px)}

func _text_origin(text: String, x: float, y: float) -> Vector2:
	var w := DomFonts.width(_font, text, _font_px)
	var ox := x
	if textAlign == "center": ox = x - w * 0.5
	elif textAlign == "right" or textAlign == "end": ox = x - w
	var asc := DomFonts.ascent(_font, _font_px); var desc := DomFonts.descent(_font, _font_px)
	var oy := y
	match textBaseline:
		"top", "hanging": oy = y + asc * 0.82
		"middle": oy = y + (asc - desc) * 0.5 * 0.72
		"bottom", "ideographic": oy = y - desc
	return Vector2(ox, oy)

func fillText(text, x, y, max_w = null) -> void:
	_begin()
	var t := JS.s(text)
	if t == "": return
	var col: Color
	if _fill is Color: col = _col(_fill)
	else: col = _col((_fill as JSGradient).sample(0.5))
	if col.a <= 0.0: return
	var o := _text_origin(t, x, y)
	var isz := maxi(1, int(round(_font_px)))
	var k := _font_px / float(isz)
	var sx := k
	if max_w != null:
		var w := DomFonts.width(_font, t, _font_px)
		if w > float(max_w) and w > 0.0:
			sx = k * float(max_w) / w
			if textAlign == "center": o.x = x - float(max_w) * 0.5
			elif textAlign == "right" or textAlign == "end": o.x = x - float(max_w)
	_use_xf(_xf * Transform2D(Vector2(sx, 0), Vector2(0, k), o))
	if float(shadowBlur) > 0.0:
		var sc := CssValue.color(shadowColor, Color(0, 0, 0, 0))
		if sc.a > 0.0:
			var rad := minf(float(shadowBlur) * 0.3, 8.0) / k
			var c2 := Color(sc.r, sc.g, sc.b, sc.a * _alpha * 0.2)
			for a in range(8):
				_font.draw_string(_ci, Vector2(cos(a * TAU / 8.0), sin(a * TAU / 8.0)) * rad, t, HORIZONTAL_ALIGNMENT_LEFT, -1, isz, c2)
	_font.draw_string(_ci, Vector2.ZERO, t, HORIZONTAL_ALIGNMENT_LEFT, -1, isz, col)

func strokeText(text, x, y, _max_w = null) -> void:
	_begin()
	var t := JS.s(text)
	if t == "": return
	var col: Color
	if _stroke is Color: col = _col(_stroke)
	else: col = _col((_stroke as JSGradient).sample(0.5))
	var o := _text_origin(t, x, y)
	var isz := maxi(1, int(round(_font_px)))
	var k := _font_px / float(isz)
	_use_xf(_xf * Transform2D(Vector2(k, 0), Vector2(0, k), o))
	_font.draw_string_outline(_ci, Vector2.ZERO, t, HORIZONTAL_ALIGNMENT_LEFT, -1, isz, maxi(1, int(round(float(lineWidth) / k))), col)

# ───────────────────────── images ─────────────────────────
func drawImage(src, a = 0, b = 0, c = null, d = null, e = null, f = null, g = null, h = null) -> void:
	_begin()
	var ctx = null
	if src is DomNode: ctx = src.canvas_ctx
	elif src is Ctx2D: ctx = src
	if ctx == null or ctx.vp == null: return
	var sw := float(ctx._w); var sh := float(ctx._h)
	var src_rect := Rect2(0, 0, sw, sh)
	var dst: Rect2
	if e != null:
		src_rect = Rect2(a, b, c, d)
		dst = Rect2(e, f, g, h)
	elif c != null: dst = Rect2(a, b, c, d)
	else: dst = Rect2(a, b, sw, sh)
	_use_xf(_xf)
	RenderingServer.canvas_item_add_texture_rect_region(_ci, dst, ctx.texture_rid(), src_rect, Color(1, 1, 1, _alpha))
