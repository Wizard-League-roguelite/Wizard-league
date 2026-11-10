# DomAnim — CSS animations (@keyframes) and transitions.
# Values are interpolated numerically token by token ("translateY(-4px) scale(1.03)",
# "0 0 12px rgba(255,200,0,.5)", "0.4", …) and written back into the node's computed style.
class_name DomAnim
extends RefCounted

var doc
var _anims: Dictionary = {}     # node instance id -> {ref, list: [{name, dur, delay, iters, alt, ease, start, fill}], key}
var _trans: Dictionary = {}     # node instance id -> {ref, props: {prop: {from, to, start, dur, delay, ease}}}
static var _tok_cache: Dictionary = {}

func _init(doc_) -> void:
	doc = doc_

static func _time(s: String) -> float:
	s = s.strip_edges()
	if s.ends_with("ms"): return CssValue.f(s)
	if s.ends_with("s"): return CssValue.f(s) * 1000.0
	return 0.0

static func _is_time(s: String) -> bool:
	return s.length() > 1 and (s[0].is_valid_int() or s[0] == ".") and s.ends_with("s")

static func ease_fn(kind: String, t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	match kind:
		"linear": return t
		"ease-in": return _bezier(0.42, 0.0, 1.0, 1.0, t)
		"ease-out": return _bezier(0.0, 0.0, 0.58, 1.0, t)
		"ease-in-out": return _bezier(0.42, 0.0, 0.58, 1.0, t)
	if kind.begins_with("cubic-bezier("):
		var a := kind.substr(13, kind.length() - 14).split(",")
		if a.size() == 4: return _bezier(CssValue.f(a[0]), CssValue.f(a[1]), CssValue.f(a[2]), CssValue.f(a[3]), t)
	return _bezier(0.25, 0.1, 0.25, 1.0, t)

static func _bezier(x1: float, y1: float, x2: float, y2: float, x: float) -> float:
	var lo := 0.0; var hi := 1.0; var u := x
	for i in range(14):
		var bx := 3.0 * (1 - u) * (1 - u) * u * x1 + 3.0 * (1 - u) * u * u * x2 + u * u * u
		if bx < x: lo = u
		else: hi = u
		u = (lo + hi) * 0.5
	return 3.0 * (1 - u) * (1 - u) * u * y1 + 3.0 * (1 - u) * u * u * y2 + u * u * u

# split a value into [text skeleton parts, numbers]; colours are normalised to rgba()
static func _tokens(v: String) -> Array:
	var hit = _tok_cache.get(v)
	if hit != null: return hit
	var s := v
	# normalise colour tokens
	var parts := CssEngine.split_ws(s)
	var changed := false
	for i in range(parts.size()):
		var p := parts[i].trim_suffix(",")
		if p.begins_with("#") or CssValue.NAMED.has(p.to_lower()):
			var c := CssValue.color(p, Color(0, 0, 0, 0))
			parts[i] = "rgba(%d,%d,%d,%.3f)%s" % [int(round(c.r * 255)), int(round(c.g * 255)), int(round(c.b * 255)), c.a, "," if parts[i].ends_with(",") else ""]
			changed = true
		elif p.begins_with("rgb(") :
			parts[i] = parts[i].replace("rgb(", "rgba(").replace(")", ",1)")
			changed = true
	if changed: s = " ".join(parts)
	var skel := PackedStringArray()
	var nums := PackedFloat64Array()
	var cur := ""
	var i2 := 0
	var n := s.length()
	while i2 < n:
		var ch := s[i2]
		var is_num_start := (ch >= "0" and ch <= "9") or ((ch == "." or ch == "-") and i2 + 1 < n and ((s[i2 + 1] >= "0" and s[i2 + 1] <= "9") or s[i2 + 1] == "."))
		if is_num_start and (cur == "" or not ((cur[cur.length() - 1] >= "a" and cur[cur.length() - 1] <= "z") or (cur[cur.length() - 1] >= "A" and cur[cur.length() - 1] <= "Z") or cur[cur.length() - 1] == "#" or cur[cur.length() - 1] == "_")):
			var j := i2 + 1
			while j < n and ((s[j] >= "0" and s[j] <= "9") or s[j] == "."): j += 1
			skel.append(cur)
			cur = ""
			nums.append(CssValue.f(s.substr(i2, j - i2)))
			i2 = j
		else:
			cur += ch
			i2 += 1
	skel.append(cur)
	var res := [skel, nums]
	if _tok_cache.size() > 4000: _tok_cache.clear()
	_tok_cache[v] = res
	return res

# interpolate two CSS values; falls back to a step when they are not compatible
static func lerp_value(a: String, b: String, t: float) -> String:
	if a == b: return b
	if a == "none" and b != "none": a = _identity_like(b)
	elif b == "none" and a != "none": b = _identity_like(a)
	var ta := _tokens(a); var tb := _tokens(b)
	var sa: PackedStringArray = ta[0]; var sb: PackedStringArray = tb[0]
	if sa.size() != sb.size(): return b if t >= 0.5 else a
	for i in range(sa.size()):
		if sa[i] != sb[i]:
			# allow unit-less zero against a unit ("0" vs "4px")
			if not (sa[i].strip_edges() == "" or sb[i].strip_edges() == "" or sa[i].replace("px", "") == sb[i].replace("px", "")): return b if t >= 0.5 else a
	var na: PackedFloat64Array = ta[1]; var nb: PackedFloat64Array = tb[1]
	var out := ""
	for i in range(na.size()):
		var sk := sb[i] if sb[i].length() >= sa[i].length() else sa[i]
		var val := na[i] + (nb[i] - na[i]) * t
		out += sk + ("%d" % int(round(val)) if sk.ends_with("rgba(") or (i > 0 and _in_rgb(sb, i)) else ("%.4f" % val))
	out += sb[sb.size() - 1] if sb[sb.size() - 1].length() >= sa[sa.size() - 1].length() else sa[sa.size() - 1]
	return out

# "none" expressed in the shape of another value (zero offsets, unit scale, transparent shadows)
static func _identity_like(v: String) -> String:
	var out := ""
	var i := 0
	var n := v.length()
	var in_scale := false
	var fname := ""
	while i < n:
		var ch := v[i]
		if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z"):
			fname += ch; out += ch; i += 1
			continue
		if ch == "(":
			in_scale = fname.to_lower().begins_with("scale") or fname == "brightness" or fname == "saturate"
			fname = ""
		elif ch == ")": in_scale = false
		elif ch != "-" and ch != "." and not (ch >= "0" and ch <= "9"): fname = ""
		if (ch >= "0" and ch <= "9") or ((ch == "." or ch == "-") and i + 1 < n and ((v[i + 1] >= "0" and v[i + 1] <= "9") or v[i + 1] == ".")):
			var j := i + 1
			while j < n and ((v[j] >= "0" and v[j] <= "9") or v[j] == "."): j += 1
			out += "1" if in_scale else "0"
			i = j
			continue
		out += ch
		i += 1
	return out

# true when number i is the 2nd or 3rd channel of an rgba( … ) group
static func _in_rgb(skel: PackedStringArray, i: int) -> bool:
	if skel[i].strip_edges() != ",": return false
	if i >= 1 and skel[i - 1].ends_with("rgba("): return true
	if i >= 2 and skel[i - 1].strip_edges() == "," and skel[i - 2].ends_with("rgba("): return true
	return false

# ───────────────────────── registration ─────────────────────────
func style_changed(n: DomNode, old: Dictionary) -> void:
	var id := n.get_instance_id()
	var an: String = n.cs.get("animation", "none")
	var disp: String = n.cs.get("display", "inline")
	# animations
	if an != "none" and an != "" and disp != "none":
		var cur = _anims.get(id)
		if cur == null or cur.key != an:
			var list := []
			for layer in CssEngine._split_top(an, ","):
				var a := {"name": "", "dur": 0.0, "delay": 0.0, "iters": 1.0, "alt": false, "ease": "ease", "fill": false, "start": JS.now()}
				var seen_time := false
				for tok in CssEngine.split_ws(layer.strip_edges()):
					if _is_time(tok):
						if not seen_time:
							a.dur = _time(tok); seen_time = true
						else: a.delay = _time(tok)
					elif tok == "infinite": a.iters = INF
					elif tok == "alternate": a.alt = true
					elif tok == "forwards" or tok == "both": a.fill = true
					elif tok in ["linear", "ease", "ease-in", "ease-out", "ease-in-out"] or tok.begins_with("cubic-bezier"): a.ease = tok
					elif tok.is_valid_float(): a.iters = tok.to_float()
					elif tok in ["normal", "none", "backwards", "running", "paused", "reverse"]: pass
					else: a.name = tok
				if a.name != "" and a.dur > 0.0: list.append(a)
			if list.size() > 0: _anims[id] = {"ref": weakref(n), "list": list, "key": an, "applied": {}}
			else: _anims.erase(id)
		else:
			# restyle while animating: re-apply the current animated values
			for p in cur.applied.keys(): n.cs[p] = cur.applied[p]
			if cur.applied.size() > 0: doc._resolve(n)
	elif _anims.has(id):
		_anims.erase(id)
	# transitions
	var tr: String = n.cs.get("transition", "none")
	var active = _trans.get(id)
	if tr == "none" or tr == "" or old.is_empty() or old.get("display", "inline") == "none" or disp == "none":
		if active != null: _trans.erase(id)
		return
	var specs := _transition_specs(tr)
	var touched := false
	for prop in n.cs.keys():
		if DomStyle.PAINT_ONLY.has(prop) and not (prop in ["color", "background-color", "opacity", "transform", "box-shadow", "border-top-color", "border-right-color", "border-bottom-color", "border-left-color", "filter"]): continue
		if prop == "transition" or prop == "animation" or prop == "display" or prop.begins_with("--"): continue
		var spec = specs.get(prop, specs.get("all"))
		if spec == null and prop.begins_with("border-") and prop.ends_with("-color"): spec = specs.get("border-color")
		if spec == null and prop == "background-color": spec = specs.get("background")
		if spec == null or spec.dur <= 0.0: continue
		var nv: String = n.cs[prop]
		var ov = old.get(prop)
		if active != null and active.props.has(prop):
			var t = active.props[prop]
			if t.to == nv:
				n.cs[prop] = t.cur   # same target: keep animating
				touched = true
				continue
			ov = t.cur
		if ov == null or ov == nv: continue
		if lerp_value(ov, nv, 0.25) == ov: continue   # not interpolable
		if active == null:
			active = {"ref": weakref(n), "props": {}}
			_trans[id] = active
		active.props[prop] = {"from": ov, "to": nv, "cur": ov, "start": JS.now() + spec.delay, "dur": spec.dur, "ease": spec.ease}
		n.cs[prop] = ov
		touched = true
	if touched: doc._resolve(n)

var _spec_cache: Dictionary = {}
func _transition_specs(tr: String) -> Dictionary:
	if _spec_cache.has(tr): return _spec_cache[tr]
	var specs := {}
	for layer in CssEngine._split_top(tr, ","):
		var sp := {"dur": 0.0, "delay": 0.0, "ease": "ease"}
		var prop := "all"
		var seen := false
		for tok in CssEngine.split_ws(layer.strip_edges()):
			if _is_time(tok):
				if not seen:
					sp.dur = _time(tok); seen = true
				else: sp.delay = _time(tok)
			elif tok in ["linear", "ease", "ease-in", "ease-out", "ease-in-out"] or tok.begins_with("cubic-bezier"): sp.ease = tok
			else: prop = tok
		specs[prop] = sp
	_spec_cache[tr] = specs
	return specs

# ───────────────────────── per-frame update ─────────────────────────
# Returns true while anything is animating (the document then repaints).
func tick() -> bool:
	if _anims.is_empty() and _trans.is_empty(): return false
	var now := JS.now()
	var busy := false
	for id in _anims.keys():
		var rec = _anims[id]
		var n: DomNode = rec.ref.get_ref()
		if n == null or not n.is_connected_to_doc():
			_anims.erase(id)
			continue
		if not n.rid.is_valid() or not n.st.get("_shown", false): continue
		var applied := {}
		var alive := false
		for a in rec.list:
			var frames = doc.css.keyframes.get(a.name)
			if frames == null or frames.is_empty(): continue
			var el: float = now - a.start - a.delay
			if el < 0.0:
				alive = true
				continue
			var cycles: float = el / a.dur
			var t: float
			if cycles >= a.iters:
				if not a.fill: continue
				t = 1.0 if (not a.alt or int(a.iters) % 2 == 1) else 0.0
			else:
				alive = true
				var whole := int(floor(cycles))
				t = cycles - whole
				if a.alt and whole % 2 == 1: t = 1.0 - t
			_sample(n, frames, t, a.ease, applied)
		if not alive and applied.is_empty():
			_anims.erase(id)
			doc.mark_style(n)
			continue
		var layout := false
		for p in applied.keys():
			if n.cs.get(p) != applied[p]:
				n.cs[p] = applied[p]
				if not DomStyle.PAINT_ONLY.has(p): layout = true
		rec.applied = applied
		doc._resolve(n)
		n.paint_dirty = true
		if layout: doc._layout_dirty = true
		if alive: busy = true
	for id in _trans.keys():
		var rec2 = _trans[id]
		var n2: DomNode = rec2.ref.get_ref()
		if n2 == null or not n2.is_connected_to_doc():
			_trans.erase(id)
			continue
		var layout2 := false
		for prop in rec2.props.keys():
			var t2 = rec2.props[prop]
			var k: float = (now - t2.start) / t2.dur
			if k >= 1.0:
				n2.cs[prop] = t2.to
				rec2.props.erase(prop)
			else:
				t2.cur = lerp_value(t2.from, t2.to, ease_fn(t2.ease, maxf(k, 0.0)))
				n2.cs[prop] = t2.cur
			if not DomStyle.PAINT_ONLY.has(prop): layout2 = true
		doc._resolve(n2)
		n2.paint_dirty = true
		if layout2: doc._layout_dirty = true
		if rec2.props.is_empty(): _trans.erase(id)
		busy = true
	return busy

func _sample(n: DomNode, frames: Array, t: float, easing: String, out: Dictionary) -> void:
	# properties animated by this keyframe set
	var props := {}
	for f in frames:
		for p in f.decls.keys(): props[p] = true
	for p in props.keys():
		var prev = null; var next = null
		for f in frames:
			if not f.decls.has(p): continue
			if f.t <= t: prev = f
			elif next == null: next = f
		var base = n.style._props.get(p)
		var from_v: String; var to_v: String; var t0 := 0.0; var t1 := 1.0
		if prev != null:
			from_v = prev.decls[p]; t0 = prev.t
		else: from_v = base if base != null else _neutral(p)
		if next != null:
			to_v = next.decls[p]; t1 = next.t
		else:
			to_v = from_v if prev != null and prev.t >= 1.0 else (base if base != null else (from_v if prev != null and t >= prev.t and next == null and prev.t == 1.0 else _neutral(p)))
			if prev != null and next == null: to_v = prev.decls[p] if prev.t >= 1.0 else to_v
		var local := 0.0 if t1 <= t0 else (t - t0) / (t1 - t0)
		var v := lerp_value(from_v, to_v, ease_fn(easing, local))
		if v.contains("var("): v = doc.css._subst_vars(v, n.cs)
		out[p] = v

static func _neutral(p: String) -> String:
	match p:
		"opacity": return "1"
		"transform": return "none"
		"box-shadow", "filter", "text-shadow": return "none"
	return "0"
