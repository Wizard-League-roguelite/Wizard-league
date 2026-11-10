# DomFonts — font lookup (family / weight / style / letter-spacing) and cached text measurement.
class_name DomFonts
extends RefCounted

static var _faces: Dictionary = {}
static var _cache: Dictionary = {}
static var _measure: Dictionary = {}
static var _fallbacks: Array[Font] = []

static func _face(file: String) -> FontFile:
	if not _faces.has(file):
		var f = load("res://fonts/" + file)
		if f is FontFile and not file.contains("Emoji"):
			# unhinted, fractional advances: matches browser text metrics
			f.hinting = TextServer.HINTING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_ONE_QUARTER
		_faces[file] = f
	return _faces[file]

static func _init_fallbacks() -> void:
	if _fallbacks.size() > 0: return
	var sym := _face("DejaVuSans.ttf")
	var emoji := _face("NotoColorEmoji.ttf")
	if sym != null: _fallbacks.append(sym)
	if emoji != null: _fallbacks.append(emoji)

# family: CSS font-family list. Returns a Font with symbol + emoji fallbacks.
static func font(family: String, bold: bool, italic: bool, spacing: float) -> Font:
	var key := "%s|%s|%s" % [family, bold, italic]
	var hit = _cache.get(key)
	if hit != null: return hit
	_init_fallbacks()
	var fam := family.to_lower()
	var first := fam.split(",")[0].strip_edges().trim_prefix("'").trim_suffix("'").trim_prefix("\"").trim_suffix("\"")
	var base: Font = null
	var fake_italic := false
	var fake_bold := false
	match first:
		"cinzel":
			base = _face("Cinzel-Bold.woff2" if bold else "Cinzel-Regular.woff2")
			fake_italic = italic
		"monospace", "courier new", "courier", "consolas", "menlo":
			base = _face("DejaVuSansMono.ttf"); fake_bold = bold; fake_italic = italic
		"sans-serif", "arial", "helvetica", "system-ui", "segoe ui", "verdana", "tahoma", "inherit":
			base = _face("DejaVuSans.ttf"); fake_bold = bold; fake_italic = italic
		_:
			# Georgia / serif → Gelasio (metric-compatible with Georgia)
			var w := "700" if bold else "400"
			base = _face("Gelasio-%s-%s.woff2" % [w, "italic" if italic else "normal"])
	var fv := FontVariation.new()
	fv.base_font = base
	fv.fallbacks = _fallbacks
	if fake_bold: fv.variation_embolden = 0.6
	if fake_italic: fv.variation_transform = Transform2D(Vector2(1, 0), Vector2(-0.2, 1), Vector2.ZERO)
	_cache[key] = fv
	return fv

static var _shaped: Dictionary = {}

# Shaped glyphs of `text` at integer size (cached): [glyph dictionaries, total advance]
static func shaped(f: Font, text: String, isz: int) -> Array:
	var key := "%d|%d|%s" % [f.get_instance_id(), isz, text]
	var hit = _shaped.get(key)
	if hit != null: return hit
	var ts := TextServerManager.get_primary_interface()
	var st := ts.create_shaped_text()
	ts.shaped_text_add_string(st, text, f.get_rids(), isz, f.get_opentype_features())
	ts.shaped_text_shape(st)
	var glyphs := ts.shaped_text_get_glyphs(st)
	var adv := 0.0
	var count := 0
	for g in glyphs:
		adv += g.advance
		if g.advance > 0.0: count += 1
	ts.free_rid(st)
	var res := [glyphs, adv, count]
	if _shaped.size() > 20000: _shaped.clear()
	_shaped[key] = res
	return res

# Width of `text` at fractional pixel size `px` with CSS letter-spacing `ls` (px).
static func width(f: Font, text: String, px: float, ls: float = 0.0) -> float:
	if text == "": return 0.0
	var isz := maxi(1, int(round(px)))
	var sh := shaped(f, text, isz)
	return sh[1] * (px / float(isz)) + ls * sh[2]

# Draw text with its baseline origin at (0,0) of the current transform; `ls` in the same units.
static func draw(rid: RID, f: Font, at: Vector2, text: String, isz: int, col: Color, ls: float = 0.0) -> void:
	var ts := TextServerManager.get_primary_interface()
	var x := at.x
	for g in shaped(f, text, isz)[0]:
		if g.font_rid.is_valid():
			ts.font_draw_glyph(g.font_rid, rid, g.font_size, Vector2(x + g.offset.x, at.y + g.offset.y), g.index, col)
		x += g.advance
		if g.advance > 0.0: x += ls

static func ascent(f: Font, px: float) -> float:
	var isz := maxi(1, int(round(px)))
	return f.get_ascent(isz) * (px / float(isz))

static func descent(f: Font, px: float) -> float:
	var isz := maxi(1, int(round(px)))
	return f.get_descent(isz) * (px / float(isz))
