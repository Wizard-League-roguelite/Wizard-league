# CssValue — parsing of CSS values (lengths, colours, gradients, transforms, shadows).
class_name CssValue
extends RefCounted

const AUTO := -1e9          # sentinel for "auto" / unresolvable lengths

static var _len_cache: Dictionary = {}
static var _color_cache: Dictionary = {}

const NAMED := {
	"transparent": Color(0, 0, 0, 0), "black": Color(0, 0, 0), "white": Color(1, 1, 1), "red": Color(1, 0, 0),
	"green": Color(0, 0.5, 0), "blue": Color(0, 0, 1), "yellow": Color(1, 1, 0), "orange": Color(1, 0.647, 0),
	"purple": Color(0.5, 0, 0.5), "gray": Color(0.5, 0.5, 0.5), "grey": Color(0.5, 0.5, 0.5), "silver": Color(0.753, 0.753, 0.753),
	"gold": Color(1, 0.843, 0), "cyan": Color(0, 1, 1), "aqua": Color(0, 1, 1), "magenta": Color(1, 0, 1), "fuchsia": Color(1, 0, 1),
	"lime": Color(0, 1, 0), "navy": Color(0, 0, 0.5), "teal": Color(0, 0.5, 0.5), "maroon": Color(0.5, 0, 0), "olive": Color(0.5, 0.5, 0),
	"pink": Color(1, 0.753, 0.796), "brown": Color(0.647, 0.165, 0.165), "crimson": Color(0.863, 0.078, 0.235),
	"darkred": Color(0.545, 0, 0), "darkgreen": Color(0, 0.392, 0), "darkblue": Color(0, 0, 0.545), "lightgray": Color(0.827, 0.827, 0.827),
	"lightgrey": Color(0.827, 0.827, 0.827), "darkgray": Color(0.663, 0.663, 0.663), "darkgrey": Color(0.663, 0.663, 0.663),
	"dimgray": Color(0.412, 0.412, 0.412), "lightblue": Color(0.678, 0.847, 0.902), "skyblue": Color(0.529, 0.808, 0.922),
	"orangered": Color(1, 0.271, 0), "tomato": Color(1, 0.388, 0.278), "coral": Color(1, 0.498, 0.314), "salmon": Color(0.98, 0.502, 0.447),
	"khaki": Color(0.941, 0.902, 0.549), "violet": Color(0.933, 0.51, 0.933), "indigo": Color(0.294, 0, 0.51), "orchid": Color(0.855, 0.439, 0.839),
	"turquoise": Color(0.251, 0.878, 0.816), "tan": Color(0.824, 0.706, 0.549), "beige": Color(0.961, 0.961, 0.863), "ivory": Color(1, 1, 0.941),
	"lightyellow": Color(1, 1, 0.878), "lightgreen": Color(0.565, 0.933, 0.565), "limegreen": Color(0.196, 0.804, 0.196),
	"dodgerblue": Color(0.118, 0.565, 1), "royalblue": Color(0.255, 0.412, 0.882), "steelblue": Color(0.275, 0.51, 0.706),
	"firebrick": Color(0.698, 0.133, 0.133), "chocolate": Color(0.824, 0.412, 0.118), "sienna": Color(0.627, 0.322, 0.176),
	"peru": Color(0.804, 0.522, 0.247), "goldenrod": Color(0.855, 0.647, 0.125), "darkorange": Color(1, 0.549, 0),
	"hotpink": Color(1, 0.412, 0.706), "deeppink": Color(1, 0.078, 0.576), "plum": Color(0.867, 0.627, 0.867), "lavender": Color(0.902, 0.902, 0.98),
	"aquamarine": Color(0.498, 1, 0.831), "springgreen": Color(0, 1, 0.498), "seagreen": Color(0.18, 0.545, 0.341), "forestgreen": Color(0.133, 0.545, 0.133),
	"slategray": Color(0.439, 0.502, 0.565), "darkslategray": Color(0.184, 0.31, 0.31), "midnightblue": Color(0.098, 0.098, 0.439),
	"powderblue": Color(0.69, 0.878, 0.902), "wheat": Color(0.961, 0.871, 0.702), "snow": Color(1, 0.98, 0.98), "whitesmoke": Color(0.961, 0.961, 0.961),
	"gainsboro": Color(0.863, 0.863, 0.863), "darkviolet": Color(0.58, 0, 0.827), "mediumpurple": Color(0.576, 0.439, 0.859),
	"blueviolet": Color(0.541, 0.169, 0.886), "darkmagenta": Color(0.545, 0, 0.545), "darkcyan": Color(0, 0.545, 0.545),
	"lightcyan": Color(0.878, 1, 1), "lightpink": Color(1, 0.714, 0.757), "lightsalmon": Color(1, 0.627, 0.478), "lightcoral": Color(0.941, 0.502, 0.502),
	"indianred": Color(0.804, 0.361, 0.361), "darkgoldenrod": Color(0.722, 0.525, 0.043), "yellowgreen": Color(0.604, 0.804, 0.196),
	"greenyellow": Color(0.678, 1, 0.184), "chartreuse": Color(0.498, 1, 0), "lawngreen": Color(0.486, 0.988, 0), "darkolivegreen": Color(0.333, 0.42, 0.184),
	"olivedrab": Color(0.42, 0.557, 0.137), "cadetblue": Color(0.373, 0.62, 0.627), "cornflowerblue": Color(0.392, 0.584, 0.929),
	"deepskyblue": Color(0, 0.749, 1), "lightskyblue": Color(0.529, 0.808, 0.98), "mediumblue": Color(0, 0, 0.804), "slateblue": Color(0.416, 0.353, 0.804),
	"darkslateblue": Color(0.282, 0.239, 0.545), "mediumorchid": Color(0.729, 0.333, 0.827), "thistle": Color(0.847, 0.749, 0.847),
	"rosybrown": Color(0.737, 0.561, 0.561), "saddlebrown": Color(0.545, 0.271, 0.075), "sandybrown": Color(0.957, 0.643, 0.376),
	"burlywood": Color(0.871, 0.722, 0.529), "moccasin": Color(1, 0.894, 0.71), "navajowhite": Color(1, 0.871, 0.678), "peachpuff": Color(1, 0.855, 0.725),
	"mistyrose": Color(1, 0.894, 0.882), "linen": Color(0.98, 0.941, 0.902), "honeydew": Color(0.941, 1, 0.941), "azure": Color(0.941, 1, 1),
	"aliceblue": Color(0.941, 0.973, 1), "ghostwhite": Color(0.973, 0.973, 1), "lightslategray": Color(0.467, 0.533, 0.6), "lightsteelblue": Color(0.69, 0.769, 0.871),
	"paleturquoise": Color(0.686, 0.933, 0.933), "palegreen": Color(0.596, 0.984, 0.596), "palegoldenrod": Color(0.933, 0.91, 0.667),
	"mediumseagreen": Color(0.235, 0.702, 0.443), "mediumaquamarine": Color(0.4, 0.804, 0.667), "mediumturquoise": Color(0.282, 0.82, 0.8),
	"darkturquoise": Color(0, 0.808, 0.82), "lightseagreen": Color(0.125, 0.698, 0.667), "darkseagreen": Color(0.561, 0.737, 0.561),
	"mediumvioletred": Color(0.78, 0.082, 0.522), "palevioletred": Color(0.859, 0.439, 0.576), "darksalmon": Color(0.914, 0.588, 0.478),
	"darkkhaki": Color(0.741, 0.718, 0.42), "lemonchiffon": Color(1, 0.98, 0.804), "cornsilk": Color(1, 0.973, 0.863), "bisque": Color(1, 0.894, 0.769),
	"blanchedalmond": Color(1, 0.922, 0.804), "antiquewhite": Color(0.98, 0.922, 0.843), "papayawhip": Color(1, 0.937, 0.835), "oldlace": Color(0.992, 0.961, 0.902),
	"floralwhite": Color(1, 0.98, 0.941), "seashell": Color(1, 0.961, 0.933), "mintcream": Color(0.961, 1, 0.98), "lavenderblush": Color(1, 0.941, 0.961),
	"mediumslateblue": Color(0.482, 0.408, 0.933), "mediumspringgreen": Color(0, 0.98, 0.604), "rebeccapurple": Color(0.4, 0.2, 0.6),
	"buttonface": Color(0.94, 0.94, 0.94), "currentcolor": Color(1, 1, 1),
}

# Leading number of a CSS token ("12px" → 12, ".2em" → 0.2). CssValue.f(String) would
# treat the "e" of "em" as an exponent marker.
static func f(s: String) -> float:
	var n := s.length()
	var i := 0
	while i < n and (s[i] == " " or s[i] == "\t"): i += 1
	var start := i
	if i < n and (s[i] == "-" or s[i] == "+"): i += 1
	var seen_dot := false
	while i < n:
		var c := s.unicode_at(i)
		if c >= 48 and c <= 57: i += 1
		elif c == 46 and not seen_dot:
			seen_dot = true; i += 1
		else: break
	var t := s.substr(start, i - start)
	if t == "" or t == "-" or t == "+" or t == ".": return 0.0
	if t.begins_with("."): t = "0" + t
	elif t.begins_with("-."): t = "-0" + t.substr(1)
	elif t.begins_with("+."): t = "0" + t.substr(1)
	return t.to_float()

# ───────────────────────── colours ─────────────────────────
static func color(s, fallback: Color = Color(0, 0, 0, 0)) -> Color:
	if s == null: return fallback
	if s is Color: return s
	var key: String = s
	var hit = _color_cache.get(key)
	if hit != null: return hit
	var c = _parse_color(key.strip_edges().to_lower())
	if c == null: return fallback
	if _color_cache.size() > 6000: _color_cache.clear()
	_color_cache[key] = c
	return c

static func is_color(s: String) -> bool:
	return _parse_color(s.strip_edges().to_lower()) != null

static func _parse_color(s: String):
	if s == "": return null
	if s[0] == "#":
		var h := s.substr(1)
		var n := h.length()
		if n == 3 or n == 4:
			var r := h.substr(0, 1).hex_to_int() * 17; var g := h.substr(1, 1).hex_to_int() * 17; var b := h.substr(2, 1).hex_to_int() * 17
			var a := 255 if n == 3 else h.substr(3, 1).hex_to_int() * 17
			return Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0)
		if n == 6 or n == 8:
			if not h.is_valid_hex_number(): return null
			var r2 := h.substr(0, 2).hex_to_int(); var g2 := h.substr(2, 2).hex_to_int(); var b2 := h.substr(4, 2).hex_to_int()
			var a2 := 255 if n == 6 else h.substr(6, 2).hex_to_int()
			return Color(r2 / 255.0, g2 / 255.0, b2 / 255.0, a2 / 255.0)
		return null
	if s.begins_with("rgb"):
		var open := s.find("(")
		var close := s.rfind(")")
		if open < 0: return null
		if close < 0: close = s.length()
		var inner := s.substr(open + 1, close - open - 1).replace("/", ",")
		var parts := inner.split(",") if inner.contains(",") else PackedStringArray(Array(inner.split(" ", false)))
		if parts.size() < 3: return null
		var comps := [0.0, 0.0, 0.0, 1.0]
		for i in range(mini(4, parts.size())):
			var p := parts[i].strip_edges()
			if p.ends_with("%"): comps[i] = CssValue.f(p) / 100.0 * (255.0 if i < 3 else 1.0)
			else: comps[i] = CssValue.f(p)
		return Color(clampf(comps[0] / 255.0, 0, 1), clampf(comps[1] / 255.0, 0, 1), clampf(comps[2] / 255.0, 0, 1), clampf(comps[3], 0, 1))
	if s.begins_with("hsl"):
		var open2 := s.find("(")
		var close2 := s.rfind(")")
		if close2 < 0: close2 = s.length()
		var inner2 := s.substr(open2 + 1, close2 - open2 - 1).replace("/", ",")
		var parts2 := inner2.split(",") if inner2.contains(",") else PackedStringArray(Array(inner2.split(" ", false)))
		if parts2.size() < 3: return null
		var hh := fposmod(CssValue.f(parts2[0]), 360.0) / 360.0
		var ss := clampf(CssValue.f(parts2[1]) / 100.0, 0, 1)
		var ll := clampf(CssValue.f(parts2[2]) / 100.0, 0, 1)
		var aa := 1.0
		if parts2.size() > 3:
			var ap := parts2[3].strip_edges()
			aa = CssValue.f(ap) / 100.0 if ap.ends_with("%") else CssValue.f(ap)
		return _hsl(hh, ss, ll, clampf(aa, 0, 1))
	if NAMED.has(s): return NAMED[s]
	return null

static func _hsl(h: float, s: float, l: float, a: float) -> Color:
	if s == 0.0: return Color(l, l, l, a)
	var q := l * (1 + s) if l < 0.5 else l + s - l * s
	var p := 2 * l - q
	return Color(_hue(p, q, h + 1.0 / 3.0), _hue(p, q, h), _hue(p, q, h - 1.0 / 3.0), a)

static func _hue(p: float, q: float, t: float) -> float:
	if t < 0: t += 1
	if t > 1: t -= 1
	if t < 1.0 / 6.0: return p + (q - p) * 6 * t
	if t < 0.5: return q
	if t < 2.0 / 3.0: return p + (q - p) * (2.0 / 3.0 - t) * 6
	return p

# ───────────────────────── lengths ─────────────────────────
# Parsed length: [px, pct, em, rem, vw, vh] coefficients, or null for auto/none
static func _parse_len(s: String):
	s = s.strip_edges().to_lower()
	if s == "" or s == "auto" or s == "none" or s == "normal": return null
	if s.begins_with("calc("):
		return _calc(s.substr(5, s.length() - 6))
	if s.begins_with("env("):
		var comma := s.find(",")
		if comma >= 0: return _parse_len(s.substr(comma + 1, s.length() - comma - 2))
		return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var num := CssValue.f(s)
	if s.ends_with("px"): return [num, 0.0, 0.0, 0.0, 0.0, 0.0]
	if s.ends_with("%"): return [0.0, num / 100.0, 0.0, 0.0, 0.0, 0.0]
	if s.ends_with("rem"): return [0.0, 0.0, 0.0, num, 0.0, 0.0]
	if s.ends_with("em"): return [0.0, 0.0, num, 0.0, 0.0, 0.0]
	if s.ends_with("vw"): return [0.0, 0.0, 0.0, 0.0, num / 100.0, 0.0]
	if s.ends_with("vh"): return [0.0, 0.0, 0.0, 0.0, 0.0, num / 100.0]   # also dvh / svh / lvh
	if s.ends_with("ch"): return [0.0, 0.0, num * 0.5, 0.0, 0.0, 0.0]
	if s.ends_with("pt"): return [num * 4.0 / 3.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	if s.ends_with("fr"): return null
	if s.is_valid_float(): return [num, 0.0, 0.0, 0.0, 0.0, 0.0]
	return null

# very small calc(): sums / differences of terms, each optionally multiplied or divided by a number
static func _calc(expr: String):
	var total := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var toks := CssEngine.split_ws(expr)
	var sign := 1.0
	var i := 0
	var have := false
	while i < toks.size():
		var t := toks[i]
		if t == "+": sign = 1.0
		elif t == "-": sign = -1.0
		elif t == "*" or t == "/":
			i += 1
			if i < toks.size():
				var f := CssValue.f(toks[i])
				if t == "/" and f != 0.0: f = 1.0 / f
				# multiply only the most recent term: approximate by scaling the last addend
				if _last_term != null:
					for k in range(6): total[k] += _last_term[k] * (f - 1.0) * _last_sign
					for k in range(6): _last_term[k] *= f
		else:
			var term = _parse_len(t)
			if term == null:
				if t.is_valid_float(): term = [CssValue.f(t), 0.0, 0.0, 0.0, 0.0, 0.0]
				else: return null
			for k in range(6): total[k] += term[k] * sign
			_last_term = term.duplicate(); _last_sign = sign
			have = true
		i += 1
	_last_term = null
	return total if have else null

static var _last_term = null
static var _last_sign := 1.0

# Resolve to pixels. `base` is what percentages refer to (AUTO if indefinite → returns AUTO).
static func length(s, base: float, font_px: float, viewport: Vector2) -> float:
	if s == null: return AUTO
	var key: String = s
	var p = _len_cache.get(key, 0)
	if typeof(p) == TYPE_INT:
		p = _parse_len(key)
		if _len_cache.size() > 8000: _len_cache.clear()
		_len_cache[key] = p
	if p == null: return AUTO
	var v: float = p[0] + p[2] * font_px + p[3] * 16.0 + p[4] * viewport.x + p[5] * viewport.y
	if p[1] != 0.0:
		if base <= AUTO + 1.0: return AUTO
		v += p[1] * base
	return v

static func is_percent(s) -> bool:
	if s == null: return false
	return (s as String).contains("%")

# ───────────────────────── gradients ─────────────────────────
static var _grad_cache: Dictionary = {}
static var _grad_order: Array = []

# CSS gradient string → {kind:"linear"/"radial", angle, stops:[[offset,Color]], ...} or null
static func gradient(s: String):
	s = s.strip_edges()
	var open := s.find("(")
	if open < 0: return null
	var fname := s.substr(0, open).to_lower()
	var inner := s.substr(open + 1, s.rfind(")") - open - 1)
	var parts := CssEngine._split_top(inner, ",")
	var g := {"kind": "linear", "angle": 180.0, "stops": [], "cx": 0.5, "cy": 0.5, "shape": "ellipse", "repeating": fname.begins_with("repeating")}
	var start := 0
	var first := parts[0].strip_edges().to_lower()
	if fname.contains("linear"):
		if first.ends_with("deg"):
			g.angle = CssValue.f(first); start = 1
		elif first.ends_with("turn"):
			g.angle = CssValue.f(first) * 360.0; start = 1
		elif first.begins_with("to "):
			var dir := first.substr(3)
			var ang := {"top": 0.0, "right": 90.0, "bottom": 180.0, "left": 270.0, "top right": 45.0, "right top": 45.0, "bottom right": 135.0, "right bottom": 135.0, "bottom left": 225.0, "left bottom": 225.0, "top left": 315.0, "left top": 315.0}
			g.angle = ang.get(dir, 180.0); start = 1
	elif fname.contains("radial"):
		g.kind = "radial"
		if not is_color(CssEngine.split_ws(first)[0]) :
			start = 1
			if first.contains("circle"): g.shape = "circle"
			var at := first.find("at ")
			if at >= 0:
				var pos := CssEngine.split_ws(first.substr(at + 3))
				g.cx = _pos_frac(pos[0], true)
				g.cy = _pos_frac(pos[1], false) if pos.size() > 1 else 0.5
	else:
		return null
	var raw := []
	for i in range(start, parts.size()):
		var toks := CssEngine.split_ws(parts[i].strip_edges())
		if toks.size() == 0: continue
		var col := color(toks[0], Color(0, 0, 0, 0))
		var off := -1.0
		if toks.size() > 1:
			off = CssValue.f(toks[1]) / 100.0 if toks[1].ends_with("%") else -2.0 - CssValue.f(toks[1])
		raw.append([off, col])
		if toks.size() > 2:
			raw.append([CssValue.f(toks[2]) / 100.0 if toks[2].ends_with("%") else -2.0 - CssValue.f(toks[2]), col])
	if raw.size() == 0: return null
	# px offsets are encoded as (-2 - px); resolved by the painter against the gradient length
	g.stops = raw
	return g

static func _pos_frac(t: String, horiz: bool) -> float:
	match t:
		"left", "top": return 0.0
		"center": return 0.5
		"right", "bottom": return 1.0
	if t.ends_with("%"): return CssValue.f(t) / 100.0
	return 0.5

# fill in missing offsets; px offsets resolved against `length_px`
static func resolve_stops(raw: Array, length_px: float) -> Array:
	var n := raw.size()
	var offs := []
	for st in raw:
		var o: float = st[0]
		if o <= -2.0: o = (-2.0 - o) / maxf(1.0, length_px)
		offs.append(o)
	if offs[0] < 0.0 and offs[0] > -1.5: offs[0] = 0.0
	if offs[n - 1] < 0.0 and offs[n - 1] > -1.5: offs[n - 1] = 1.0
	var i := 0
	while i < n:
		if offs[i] < 0.0:
			var j := i
			while j < n and offs[j] < 0.0: j += 1
			var a: float = offs[i - 1]
			var b: float = offs[j]
			for k in range(i, j): offs[k] = a + (b - a) * float(k - i + 1) / float(j - i + 1)
			i = j
		else: i += 1
	var out := []
	var last := 0.0
	for k in range(n):
		last = maxf(last, offs[k])
		out.append([last, raw[k][1]])
	return out

# 1-D ramp texture for a list of [offset, Color] stops (cached)
static func ramp_texture(stops: Array) -> Texture2D:
	var key := ""
	for st in stops: key += "%.4f:%s;" % [st[0], (st[1] as Color).to_html(true)]
	var hit = _grad_cache.get(key)
	if hit != null: return hit
	var grad := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for st in stops:
		offs.append(clampf(st[0], 0.0, 1.0)); cols.append(st[1])
	grad.offsets = offs
	grad.colors = cols
	grad.interpolation_color_space = Gradient.GRADIENT_COLOR_SPACE_SRGB
	var tex := GradientTexture1D.new()
	tex.width = 256
	tex.gradient = grad
	_grad_cache[key] = tex
	_grad_order.append(key)
	if _grad_order.size() > 700:
		for i in range(200): _grad_cache.erase(_grad_order[i])
		_grad_order = _grad_order.slice(200)
	return tex

# ───────────────────────── transforms ─────────────────────────
# Returns Transform2D for a CSS transform list; percentages refer to `size`.
static func transform(s: String, size: Vector2, font_px: float, viewport: Vector2) -> Transform2D:
	var t := Transform2D.IDENTITY
	if s == "" or s == "none": return t
	var i := 0
	var n := s.length()
	while i < n:
		var open := s.find("(", i)
		if open < 0: break
		var fname := s.substr(i, open - i).strip_edges().to_lower()
		var close := s.find(")", open)
		if close < 0: break
		var args := s.substr(open + 1, close - open - 1).split(",")
		i = close + 1
		var m := Transform2D.IDENTITY
		match fname:
			"translate":
				var tx := length(args[0], size.x, font_px, viewport)
				var ty := length(args[1], size.y, font_px, viewport) if args.size() > 1 else 0.0
				m = Transform2D(0, Vector2(tx, ty))
			"translatex": m = Transform2D(0, Vector2(length(args[0], size.x, font_px, viewport), 0))
			"translatey": m = Transform2D(0, Vector2(0, length(args[0], size.y, font_px, viewport)))
			"scale":
				var sx := CssValue.f(args[0])
				var sy := CssValue.f(args[1]) if args.size() > 1 else sx
				m = Transform2D(Vector2(sx, 0), Vector2(0, sy), Vector2.ZERO)
			"scalex": m = Transform2D(Vector2(CssValue.f(args[0]), 0), Vector2(0, 1), Vector2.ZERO)
			"scaley": m = Transform2D(Vector2(1, 0), Vector2(0, CssValue.f(args[0])), Vector2.ZERO)
			"rotate":
				var a := args[0].strip_edges()
				var rad := deg_to_rad(CssValue.f(a))
				if a.ends_with("rad"): rad = CssValue.f(a)
				elif a.ends_with("turn"): rad = CssValue.f(a) * TAU
				m = Transform2D(rad, Vector2.ZERO)
			_: pass
		t = t * m
	return t

# "0 2px 12px rgba(..)" list → [{x, y, blur, spread, color, inset}]
static func shadows(s: String, font_px: float, viewport: Vector2) -> Array:
	var out := []
	if s == "" or s == "none": return out
	for layer in CssEngine._split_top(s, ","):
		var d := {"x": 0.0, "y": 0.0, "blur": 0.0, "spread": 0.0, "color": Color(0, 0, 0, 1), "inset": false}
		var nums := []
		for tok in CssEngine.split_ws(layer.strip_edges()):
			if tok == "inset": d.inset = true
			elif tok[0].is_valid_int() or tok[0] == "-" or tok[0] == ".": nums.append(length(tok, 0.0, font_px, viewport))
			else: d.color = color(tok, Color(0, 0, 0, 1))
		if nums.size() > 0: d.x = nums[0]
		if nums.size() > 1: d.y = nums[1]
		if nums.size() > 2: d.blur = nums[2]
		if nums.size() > 3: d.spread = nums[3]
		out.append(d)
	return out
