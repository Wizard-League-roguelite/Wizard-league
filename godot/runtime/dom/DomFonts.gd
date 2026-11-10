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
	var key := "%s|%s|%s|%.2f" % [family, bold, italic, spacing]
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
	if spacing != 0.0: fv.spacing_glyph = int(round(spacing))
	_cache[key] = fv
	return fv

# Width of `text` at fractional pixel size `px` (letter-spacing `ls` in px).
static func width(f: Font, text: String, px: float, ls: float = 0.0) -> float:
	if text == "": return 0.0
	var isz := maxi(1, int(round(px)))
	var key := "%d|%d|%s" % [f.get_instance_id(), isz, text]
	var w = _measure.get(key)
	if w == null:
		w = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, isz).x
		if _measure.size() > 20000: _measure.clear()
		_measure[key] = w
	return w * (px / float(isz))

static func ascent(f: Font, px: float) -> float:
	var isz := maxi(1, int(round(px)))
	return f.get_ascent(isz) * (px / float(isz))

static func descent(f: Font, px: float) -> float:
	var isz := maxi(1, int(round(px)))
	return f.get_descent(isz) * (px / float(isz))
