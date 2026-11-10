# JSGradient — CanvasGradient (linear or radial) built with addColorStop().
class_name JSGradient
extends RefCounted

var radial := false
var p0 := Vector2.ZERO; var p1 := Vector2.ZERO
var r0 := 0.0; var r1 := 0.0
var _stops: Array = []      # [offset, Color]
var _tex: Texture2D = null
var _sorted := true

func addColorStop(offset, color) -> void:
	var o := clampf(float(offset), 0.0, 1.0)
	if _stops.size() > 0 and o < _stops[_stops.size() - 1][0]: _sorted = false
	_stops.append([o, CssValue.color(color, Color(0, 0, 0, 0))])
	_tex = null

func _ordered() -> Array:
	if not _sorted:
		# stable sort by offset
		var out := []
		for st in _stops:
			var i := out.size()
			while i > 0 and out[i - 1][0] > st[0]: i -= 1
			out.insert(i, st)
		_stops = out
		_sorted = true
	return _stops

func texture() -> Texture2D:
	if _tex != null: return _tex
	var stops := _ordered()
	if stops.is_empty(): stops = [[0.0, Color(0, 0, 0, 0)], [1.0, Color(0, 0, 0, 0)]]
	if radial:
		# remap so the texture spans centre → r1
		var k := r0 / r1 if r1 > 0.0 else 0.0
		var mapped := []
		if k > 0.0: mapped.append([0.0, stops[0][1]])
		for st in stops: mapped.append([k + st[0] * (1.0 - k), st[1]])
		_tex = DomPaint.radial_texture(mapped)
	else:
		_tex = CssValue.ramp_texture(stops)
	return _tex

# gradient parameter of a user-space point
func t_of(p: Vector2) -> float:
	if radial:
		var d := p.distance_to(p1)
		if r1 <= r0: return 1.0
		return clampf((d - r0) / (r1 - r0), 0.0, 1.0)
	var dir := p1 - p0
	var l2 := dir.length_squared()
	if l2 <= 0.0: return 0.0
	return clampf((p - p0).dot(dir) / l2, 0.0, 1.0)

func uv(p: Vector2) -> Vector2:
	if radial:
		var r := maxf(r1, 0.0001)
		return Vector2(clampf(0.5 + (p.x - p1.x) / (2.0 * r), 0.0, 1.0), clampf(0.5 + (p.y - p1.y) / (2.0 * r), 0.0, 1.0))
	var dir := p1 - p0
	var l2 := dir.length_squared()
	var t := 0.0 if l2 <= 0.0 else (p - p0).dot(dir) / l2
	return Vector2(clampf(t, 0.002, 0.998), 0.5)

func sample(t: float) -> Color:
	var stops := _ordered()
	if stops.is_empty(): return Color(0, 0, 0, 0)
	if t <= stops[0][0]: return stops[0][1]
	for i in range(1, stops.size()):
		if t <= stops[i][0]:
			var a: float = stops[i - 1][0]; var b: float = stops[i][0]
			var k := 0.0 if b <= a else (t - a) / (b - a)
			return (stops[i - 1][1] as Color).lerp(stops[i][1], k)
	return stops[stops.size() - 1][1]
