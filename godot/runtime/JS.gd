# JS — small helper library giving the converted game code JavaScript-like semantics
# (truthiness, loose property access, array/string helpers, timers).
extends Node

var _this = null           # receiver of the dictionary-held function currently being called
var console = self

# ───────────────────────── truthiness / coercion ─────────────────────────
func t(x) -> bool:
	match typeof(x):
		TYPE_NIL: return false
		TYPE_BOOL: return x
		TYPE_INT: return x != 0
		TYPE_FLOAT: return x != 0.0 and not is_nan(x)
		TYPE_STRING, TYPE_STRING_NAME: return x != ""
	return true

func or_(a, b):
	return a if t(a) else b

func orf(a, lazy_b: Callable):
	return a if t(a) else lazy_b.call()

func andf(a, lazy_b: Callable):
	return lazy_b.call() if t(a) else a

func nn(a, b):
	return b if a == null else a

func nnf(a, lazy_b: Callable):
	return lazy_b.call() if a == null else a

# Number → text the way JavaScript prints it
func s(x) -> String:
	match typeof(x):
		TYPE_NIL: return "undefined"
		TYPE_BOOL: return "true" if x else "false"
		TYPE_INT: return str(x)
		TYPE_FLOAT:
			if is_nan(x): return "NaN"
			if is_inf(x): return "Infinity" if x > 0 else "-Infinity"
			if x == floor(x) and absf(x) < 1e15: return str(int(x))
			var r = String.num(x, 15)
			return r
		TYPE_STRING: return x
		TYPE_STRING_NAME: return String(x)
		TYPE_ARRAY: return join(x, ",")
		TYPE_DICTIONARY: return "[object Object]"
		TYPE_OBJECT:
			if x != null and x.has_method("_js_to_string"): return x._js_to_string()
	return str(x)

# undefined → NaN, for operands of arithmetic / comparisons (JavaScript semantics)
func un(x):
	return NAN if x == null else x

# `a + b` when either side might be a string
func add(a, b):
	if a is String or b is String or a is StringName or b is StringName: return s(a) + s(b)
	if a == null or b == null: return NAN
	return a + b

func num(x):
	match typeof(x):
		TYPE_INT, TYPE_FLOAT: return x
		TYPE_BOOL: return 1 if x else 0
		TYPE_STRING, TYPE_STRING_NAME:
			var st = String(x).strip_edges()
			if st == "": return 0
			if st.is_valid_int(): return st.to_int()
			if st.is_valid_float(): return st.to_float()
			return NAN
	return NAN

func eq(a, b) -> bool:
	var ta = typeof(a); var tb = typeof(b)
	if ta == TYPE_NIL or tb == TYPE_NIL: return ta == tb
	var na = ta == TYPE_INT or ta == TYPE_FLOAT; var nb = tb == TYPE_INT or tb == TYPE_FLOAT
	if na or nb: return na and nb and a == b
	var sa = ta == TYPE_STRING or ta == TYPE_STRING_NAME; var sb = tb == TYPE_STRING or tb == TYPE_STRING_NAME
	if sa or sb: return sa and sb and a == b
	if ta != tb: return false
	if ta == TYPE_DICTIONARY or ta == TYPE_ARRAY or ta == TYPE_OBJECT: return is_same(a, b)
	return a == b

func typeof_(x) -> String:
	match typeof(x):
		TYPE_NIL: return "undefined"
		TYPE_BOOL: return "boolean"
		TYPE_INT, TYPE_FLOAT: return "number"
		TYPE_STRING, TYPE_STRING_NAME: return "string"
		TYPE_CALLABLE: return "function"
	return "object"

func instanceof_(_x, _cls) -> bool:
	return false

var _undef_seen = {}
func undef(name_):
	if not _undef_seen.has(name_):
		_undef_seen[name_] = true
		push_warning("JS: reference to undefined identifier '%s'" % name_)
	return null

func undef_call(name_, _args):
	undef(name_)
	return null

# ───────────────────────── property access ─────────────────────────
# obj[key] that yields null instead of an error when the key / index is absent
func idx(o, k):
	match typeof(o):
		TYPE_NIL: return null
		TYPE_ARRAY:
			var tk = typeof(k)
			if tk == TYPE_INT:
				return o[k] if k >= 0 and k < o.size() else null
			if tk == TYPE_FLOAT:
				var i = int(k)
				return o[i] if float(i) == k and i >= 0 and i < o.size() else null
			if tk == TYPE_STRING and k.is_valid_int():
				var j = k.to_int()
				return o[j] if j >= 0 and j < o.size() else null
			return null
		TYPE_DICTIONARY:
			if o.has(k): return o[k]
			var tk2 = typeof(k)
			if tk2 == TYPE_INT: return o.get(str(k))
			if tk2 == TYPE_FLOAT: return o.get(s(k))
			return null
		TYPE_STRING, TYPE_STRING_NAME:
			if (typeof(k) == TYPE_INT or typeof(k) == TYPE_FLOAT) and k >= 0 and k < o.length(): return o[int(k)]
			return null
		TYPE_OBJECT:
			if o.has_method("_js_index"): return o._js_index(k)
			return o.get(str(k))
		TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_BYTE_ARRAY:
			var n = int(k)
			return o[n] if n >= 0 and n < o.size() else null
	return null

# obj?.name
func g(o, name_):
	if o == null: return null
	if o is Dictionary: return o.get(name_)
	if o is Object: return o.get(name_)
	if name_ == "length": return len_(o)
	return null

func len_(x) -> int:
	if x == null: return 0
	if x is Object: return x.get("length") if x.get("length") != null else 0
	return len(x)

func has(o, k) -> bool:
	if o is Dictionary:
		return o.has(k) or (typeof(k) == TYPE_INT and o.has(str(k)))
	if o is Array: return (typeof(k) == TYPE_INT) and k >= 0 and k < o.size()
	if o is Object: return o.get(str(k)) != null
	return false

func del(o, k) -> bool:
	if o is Dictionary:
		o.erase(k)
	return true

# ───────────────────────── calling dictionary-held functions ─────────────────────────
func callm(o, name_, args: Array):
	if o == null:
		push_error("JS: cannot call '%s' on null" % str(name_))
		return null
	var f = null
	if o is Dictionary:
		f = o.get(name_)
		if f == null and typeof(name_) == TYPE_INT: f = o.get(str(name_))
	elif o is Object:
		if o.has_method(name_): return o.callv(name_, _fit(Callable(o, name_), args))
		f = o.get(name_)
	elif o is Array or o is String:
		push_error("JS: no method '%s' on %s" % [str(name_), type_string(typeof(o))])
		return null
	if not (f is Callable):
		push_error("JS: '%s' is not a function" % str(name_))
		return null
	var prev = _this
	_this = o
	var r = f.callv(_fit(f, args))
	_this = prev
	return r

func callm_opt(o, name_, args: Array):
	if o == null: return null
	if o is Dictionary and not (o.get(name_) is Callable): return null
	return callm(o, name_, args)

# call a callback with however many of `args` it accepts
func invoke(f, args: Array = []):
	if not (f is Callable) or not f.is_valid(): return null
	return f.callv(_fit(f, args))

func _fit(f: Callable, args: Array) -> Array:
	var n = f.get_argument_count()
	if args.size() > n: return args.slice(0, n)
	return args

# Temporary replacements for game functions (used by the library's spell-preview simulator).
var hooks: Dictionary = {}

func hook(name_, fn) -> void:
	if fn is Callable: hooks[s(name_)] = fn
	else: hooks.erase(s(name_))

func unhook(name_) -> void:
	hooks.erase(s(name_))

func run_hook(name_: String, args: Array):
	var f: Callable = hooks[name_]
	return f.callv(_fit(f, args))

# ───────────────────────── objects ─────────────────────────
func keys(o) -> Array:
	var out = []
	if o is Dictionary:
		for k in o.keys(): out.append(String(k) if k is StringName else (k if k is String else s(k)))
	elif o is Array:
		for i in range(o.size()): out.append(str(i))
	elif o is JSSet:
		return o.values()
	return out

func values(o) -> Array:
	if o is Dictionary: return o.values()
	if o is Array: return o.duplicate()
	if o is JSSet: return o.values()
	return []

func entries(o) -> Array:
	var out = []
	if o is Dictionary:
		for k in o.keys(): out.append([String(k) if k is StringName else k, o[k]])
	elif o is Array:
		for i in range(o.size()): out.append([i, o[i]])
	return out

func fromEntries(list) -> Dictionary:
	var d = {}
	for e in list: d[e[0]] = e[1]
	return d

func assign(target, sources: Array):
	for src in sources:
		if src is Dictionary:
			if target is Dictionary:
				for k in src.keys(): target[k] = src[k]
			elif target is Object:
				for k in src.keys(): target.set(k, src[k])
	return target

func merge(parts: Array) -> Dictionary:
	var d = {}
	for p in parts:
		if p is Dictionary:
			for k in p.keys(): d[k] = p[k]
		elif p is Array:
			for i in range(p.size()): d[str(i)] = p[i]
	return d

# ───────────────────────── arrays ─────────────────────────
# [...x] — always a fresh array
func arr(x) -> Array:
	if x is Array: return x.duplicate()
	if x == null: return []
	if x is JSSet: return x.values()
	if x is String:
		var out = []
		for ch in x: out.append(ch)
		return out
	if x is Dictionary: return x.values()
	if x is PackedStringArray or x is PackedInt32Array or x is PackedFloat32Array: return Array(x)
	if x is Object and x.has_method("_js_array"): return x._js_array()
	return []

# iteration source for `for … of` / forEach
func iter(x):
	if x is Array: return x
	if x == null: return []
	return arr(x)

func arrayFrom(x, fn = null) -> Array:
	var src
	if x is Dictionary and x.has("length"):
		src = []
		src.resize(int(x.length))
	else:
		src = arr(x)
	if fn == null: return src
	return map(src, fn)

func newArray(n = null, b = null) -> Array:
	var a = []
	if b != null: return [n, b]
	if n != null: a.resize(int(n))
	return a

func forEach(a, fn: Callable) -> void:
	var list = iter(a)
	var n = fn.get_argument_count()
	if n >= 3:
		for i in range(list.size()): fn.call(list[i], i, list)
	elif n == 2:
		for i in range(list.size()): fn.call(list[i], i)
	elif n == 1:
		for x in list: fn.call(x)
	else:
		for x in list: fn.call()

# call an array callback with (item[, index[, array]]) depending on what it accepts
func _cb(fn: Callable, n: int, list, i: int):
	if n >= 3: return fn.call(list[i], i, list)
	if n == 2: return fn.call(list[i], i)
	if n == 1: return fn.call(list[i])
	return fn.call()

func map(a, fn: Callable) -> Array:
	var list = iter(a); var out = []
	var n = fn.get_argument_count()
	for i in range(list.size()): out.append(_cb(fn, n, list, i))
	return out

func filter(a, fn: Callable) -> Array:
	var list = iter(a); var out = []
	var n = fn.get_argument_count()
	for i in range(list.size()):
		if t(_cb(fn, n, list, i)): out.append(list[i])
	return out

func find(a, fn: Callable):
	var list = iter(a)
	var n = fn.get_argument_count()
	for i in range(list.size()):
		if t(_cb(fn, n, list, i)): return list[i]
	return null

func findIndex(a, fn: Callable) -> int:
	var list = iter(a)
	var n = fn.get_argument_count()
	for i in range(list.size()):
		if t(_cb(fn, n, list, i)): return i
	return -1

func some(a, fn: Callable) -> bool:
	return findIndex(a, fn) >= 0

func every(a, fn: Callable) -> bool:
	var list = iter(a)
	var n = fn.get_argument_count()
	for i in range(list.size()):
		if not t(_cb(fn, n, list, i)): return false
	return true

const _NOINIT = "\u0001__noinit__"
func reduce(a, fn: Callable, init = _NOINIT):
	var list = iter(a)
	var i = 0
	var acc = init
	if typeof(init) == TYPE_STRING and init == _NOINIT:
		if list.is_empty(): return null
		acc = list[0]; i = 1
	var three = fn.get_argument_count() >= 3
	while i < list.size():
		acc = fn.call(acc, list[i], i) if three else fn.call(acc, list[i])
		i += 1
	return acc

# stable in-place sort (JavaScript's sort is stable)
func sort(a: Array, fn = null) -> Array:
	var n = a.size()
	if n < 2: return a
	var cmp: Callable
	if fn == null:
		cmp = func(x, y): return -1 if s(x) < s(y) else (1 if s(x) > s(y) else 0)
	else:
		cmp = fn
	var argc = cmp.get_argument_count()
	var src = a.duplicate()
	var buf = a.duplicate()
	var width = 1
	while width < n:
		var lo = 0
		while lo < n:
			var mid = mini(lo + width, n); var hi = mini(lo + 2 * width, n)
			var i = lo; var j = mid; var k = lo
			while i < mid and j < hi:
				var c = cmp.call(src[i], src[j]) if argc >= 2 else (cmp.call(src[i]) if argc == 1 else cmp.call())
				if typeof(c) == TYPE_BOOL: c = 1 if c else -1
				if c == null or (typeof(c) == TYPE_FLOAT and is_nan(c)): c = 0
				if c <= 0:
					buf[k] = src[i]; i += 1
				else:
					buf[k] = src[j]; j += 1
				k += 1
			while i < mid:
				buf[k] = src[i]; i += 1; k += 1
			while j < hi:
				buf[k] = src[j]; j += 1; k += 1
			lo += 2 * width
		var tmp = src; src = buf; buf = tmp
		width *= 2
	for i in range(n): a[i] = src[i]
	return a

func reverse(a: Array) -> Array:
	a.reverse()
	return a

func _is_container(x) -> bool:
	var ty = typeof(x)
	return ty == TYPE_DICTIONARY or ty == TYPE_ARRAY or ty == TYPE_OBJECT

func indexOf(o, x, from = 0) -> int:
	if o is String: return o.find(s(x), int(from))
	if o == null: return -1
	if o is Array:
		for i in range(int(from), o.size()):
			if eq(o[i], x): return i
	return -1

func includes(o, x) -> bool:
	if o is String: return o.contains(s(x))
	if o is JSSet: return o.has(x)
	return indexOf(o, x) >= 0

func join(a, sep = ",") -> String:
	var parts = PackedStringArray()
	for x in iter(a): parts.append("" if x == null else s(x))
	return sep.join(parts)

func slice(o, a = 0, b = null):
	if o is String:
		var n = o.length()
		var st = int(a); var en = n if b == null else int(b)
		if st < 0: st = maxi(0, n + st)
		if en < 0: en = maxi(0, n + en)
		st = mini(st, n); en = mini(en, n)
		return o.substr(st, maxi(0, en - st))
	var list = iter(o)
	if b == null: return list.slice(int(a))
	return list.slice(int(a), int(b))

func splice(a: Array, start, count = null, items: Array = []) -> Array:
	var n = a.size()
	var st = int(start)
	if st < 0: st = maxi(0, n + st)
	st = mini(st, n)
	var c = n - st if count == null else clampi(int(count), 0, n - st)
	var removed = a.slice(st, st + c)
	for i in range(c): a.remove_at(st)
	for i in range(items.size()): a.insert(st + i, items[i])
	return removed

func concat(a, others: Array) -> Array:
	var out = arr(a)
	for o in others:
		if o is Array: out.append_array(o)
		else: out.append(o)
	return out

func flat(a) -> Array:
	var out = []
	for x in iter(a):
		if x is Array: out.append_array(x)
		else: out.append(x)
	return out

func fill(a: Array, v) -> Array:
	a.fill(v)
	return a

func arrMax(a):
	var m = -INF
	for x in iter(a):
		if x == null: return NAN
		if x > m: m = x
	return m

func arrMin(a):
	var m = INF
	for x in iter(a):
		if x == null: return NAN
		if x < m: m = x
	return m

# ───────────────────────── strings ─────────────────────────
var _re_cache = {}
func re(pattern: String, flags: String = "") -> JSRegExp:
	var key = pattern + "/" + flags
	if not _re_cache.has(key): _re_cache[key] = JSRegExp.new(pattern, flags)
	return _re_cache[key]

func split(st, sep = null, limit = -1) -> Array:
	st = s(st)
	var out = []
	if sep == null: return [st]
	if sep is JSRegExp:
		var last = 0
		for m in sep.regex.search_all(st):
			out.append(st.substr(last, m.get_start() - last))
			last = m.get_end()
		out.append(st.substr(last))
	elif sep == "":
		for ch in st: out.append(ch)
	else:
		out = Array(st.split(sep))
	if limit >= 0 and out.size() > limit: out.resize(limit)
	return out

func replace(st, pat, rep) -> String:
	st = s(st)
	if pat is JSRegExp:
		if rep is Callable:
			var res = ""; var last = 0
			var ms = pat.regex.search_all(st) if pat.global else ([pat.regex.search(st)] if pat.regex.search(st) != null else [])
			for m in ms:
				res += st.substr(last, m.get_start() - last)
				var args = [m.get_string()]
				for gi in range(1, m.get_group_count() + 1): args.append(m.get_string(gi))
				res += s(invoke(rep, args))
				last = m.get_end()
			return res + st.substr(last)
		return pat.regex.sub(st, s(rep), pat.global)
	var p = s(pat)
	var i = st.find(p)
	if i < 0: return st
	var r = s(invoke(rep, [p])) if rep is Callable else s(rep)
	return st.substr(0, i) + r + st.substr(i + p.length())

func replaceAll(st, pat, rep) -> String:
	if pat is JSRegExp: return replace(st, pat, rep)
	return s(st).replace(s(pat), s(rep))

func match_(st, pat):
	if not (pat is JSRegExp): pat = JSRegExp.new(s(pat), "")
	st = s(st)
	if pat.global:
		var out = []
		for m in pat.regex.search_all(st): out.append(m.get_string())
		return out if out.size() > 0 else null
	var m = pat.regex.search(st)
	if m == null: return null
	var res = []
	for gi in range(m.get_group_count() + 1):
		res.append(m.get_string(gi) if m.get_start(gi) >= 0 else null)
	return res

func test(pat, st) -> bool:
	if not (pat is JSRegExp): return false
	return pat.regex.search(s(st)) != null

func charAt(st, i) -> String:
	st = s(st); i = int(i)
	return st[i] if i >= 0 and i < st.length() else ""

func substring(st, a, b = null) -> String:
	st = s(st)
	var n = st.length()
	var x = clampi(int(a), 0, n); var y = n if b == null else clampi(int(b), 0, n)
	if x > y:
		var tmp = x; x = y; y = tmp
	return st.substr(x, y - x)

func substr(st, a, l = null) -> String:
	st = s(st)
	var n = st.length(); var x = int(a)
	if x < 0: x = maxi(0, n + x)
	return st.substr(x, -1 if l == null else int(l))

func padStart(st, n, ch = " ") -> String:
	st = s(st)
	while st.length() < int(n): st = s(ch) + st
	return st

func padEnd(st, n, ch = " ") -> String:
	st = s(st)
	while st.length() < int(n): st = st + s(ch)
	return st

func toFixed(x, digits = 0) -> String:
	if x == null: return "NaN"
	x = num(x)
	if typeof(x) == TYPE_FLOAT and is_nan(x): return "NaN"
	var d = int(digits)
	var r = ("%." + str(d) + "f") % float(x)
	if r.begins_with("-") and float(r) == 0.0: r = r.substr(1)
	return r

func toLocaleString(x) -> String:
	if typeof(x) == TYPE_INT or typeof(x) == TYPE_FLOAT:
		var neg = x < 0
		var whole = str(int(abs(x)))
		var out = ""
		while whole.length() > 3:
			out = "," + whole.substr(whole.length() - 3) + out
			whole = whole.substr(0, whole.length() - 3)
		out = whole + out
		if typeof(x) == TYPE_FLOAT and x != floor(x):
			var frac = ("%.3f" % (abs(x) - floor(abs(x)))).substr(1).rstrip("0")
			if frac != ".": out += frac
		return ("-" if neg else "") + out
	return s(x)

func toLocaleDateString(x) -> String:
	return s(x)

func localeCompare(a, b) -> int:
	a = s(a); b = s(b)
	return -1 if a < b else (1 if a > b else 0)

func parseInt(x, radix = 10):
	if typeof(x) == TYPE_INT: return x
	if typeof(x) == TYPE_FLOAT: return NAN if is_nan(x) else int(x)
	var st = s(x).strip_edges()
	var m = re("^[-+]?[0-9]+").regex.search(st) if int(radix) == 10 else null
	if int(radix) == 16:
		var h = re("^[-+]?(0[xX])?[0-9a-fA-F]+").regex.search(st)
		return NAN if h == null else h.get_string().replace("0x", "").replace("0X", "").hex_to_int()
	if m == null: return NAN
	return m.get_string().to_int()

func parseFloat(x):
	if typeof(x) == TYPE_INT or typeof(x) == TYPE_FLOAT: return x
	var m = re("^[-+]?([0-9]+\\.?[0-9]*|\\.[0-9]+)([eE][-+]?[0-9]+)?").regex.search(s(x).strip_edges())
	if m == null: return NAN
	var f = m.get_string().to_float()
	return int(f) if f == floor(f) and absf(f) < 1e15 else f

func isNaN(x) -> bool:
	var v = num(x)
	return typeof(v) == TYPE_FLOAT and is_nan(v)

func isFinite(x) -> bool:
	var v = num(x)
	return not (typeof(v) == TYPE_FLOAT and (is_nan(v) or is_inf(v)))

func isInteger(x) -> bool:
	return typeof(x) == TYPE_INT or (typeof(x) == TYPE_FLOAT and x == floor(x) and not is_inf(x))

# ───────────────────────── maths ─────────────────────────
func mod(a, b):
	if typeof(a) == TYPE_INT and typeof(b) == TYPE_INT:
		return NAN if b == 0 else a % b
	return fmod(a, b)

func round(x):
	if typeof(x) == TYPE_INT: return x
	return floori(x + 0.5)

func hypot(a: Array) -> float:
	var sum = 0.0
	for v in a: sum += float(v) * float(v)
	return sqrt(sum)

func imul(a, b) -> int:
	var r = (int(a) * int(b)) & 0xFFFFFFFF
	return r - 0x100000000 if r >= 0x80000000 else r

func ushr(a, b) -> int:
	return (int(a) & 0xFFFFFFFF) >> (int(b) & 31)

# Math.random(). Normally Godot's generator; tests can seed two deterministic streams
# (game logic, and visuals drawn from animation-frame callbacks) to compare against the browser.
var _rng_seeded := false
var _rng_logic := 0
var _rng_visual := 0
var _in_raf := false

func seedRandom(seed_) -> void:
	_rng_seeded = true
	_rng_logic = int(seed_) & 0xFFFFFFFF
	_rng_visual = (int(seed_) ^ 0x9E3779B9) & 0xFFFFFFFF

func _mul32(a: int, b: int) -> int:
	return (((a & 0xFFFF) * b) + ((((a >> 16) & 0xFFFF) * b) << 16)) & 0xFFFFFFFF

func random() -> float:
	if not _rng_seeded: return randf()
	var st := _rng_visual if _in_raf else _rng_logic
	st = (st + 0x6D2B79F5) & 0xFFFFFFFF
	if _in_raf: _rng_visual = st
	else: _rng_logic = st
	var t := _mul32(st ^ (st >> 15), 1 | st)
	t = ((t + _mul32(t ^ (t >> 7), 61 | t)) & 0xFFFFFFFF) ^ t
	return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0

# ───────────────────────── JSON ─────────────────────────
func jsonParse(text):
	if text == null: return null
	var j = JSON.new()
	if j.parse(s(text)) != OK: return null
	return _ints(j.data)

func _ints(v):
	match typeof(v):
		TYPE_FLOAT:
			return int(v) if v == floor(v) and absf(v) < 9.0e15 else v
		TYPE_ARRAY:
			for i in range(v.size()): v[i] = _ints(v[i])
		TYPE_DICTIONARY:
			for k in v.keys(): v[k] = _ints(v[k])
	return v

func jsonStringify(v, _replacer = null, indent = null) -> String:
	return JSON.stringify(_plain(v), "" if indent == null else "  ", false)

func _plain(v):
	match typeof(v):
		TYPE_FLOAT:
			if is_nan(v) or is_inf(v): return null
			return int(v) if v == floor(v) and absf(v) < 9.0e15 else v
		TYPE_STRING_NAME: return String(v)
		TYPE_ARRAY:
			var a = []
			for x in v: a.append(null if x is Callable else _plain(x))
			return a
		TYPE_DICTIONARY:
			var d = {}
			for k in v.keys():
				var val = v[k]
				if val is Callable: continue
				d[String(k) if not (k is String) else k] = _plain(val)
			return d
		TYPE_OBJECT:
			if v is JSSet: return {}
			return null
		TYPE_CALLABLE: return null
	return v

# ───────────────────────── time / scheduling ─────────────────────────
func now() -> float:
	if virtual_time >= 0.0: return virtual_time
	return Time.get_ticks_usec() / 1000.0

func dateNow() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)

func newDate(_a = null):
	return Time.get_date_string_from_system()

var _timer_id = 0
var _timers = {}       # id -> {due, fn, every}
var _rafs = {}         # id -> fn
var virtual_time = -1.0   # >= 0: tests drive the clock manually (ms)

func _clock() -> float:
	return now()

func setTimeout(fn, ms = 0) -> int:
	_timer_id += 1
	_timers[_timer_id] = {"due": _clock() + float(ms if ms != null else 0), "fn": fn, "every": -1.0}
	return _timer_id

func setInterval(fn, ms = 0) -> int:
	_timer_id += 1
	_timers[_timer_id] = {"due": _clock() + float(ms), "fn": fn, "every": maxf(1.0, float(ms))}
	return _timer_id

func clearTimeout(id = null) -> void:
	if id != null: _timers.erase(id)

func clearInterval(id = null) -> void:
	clearTimeout(id)

func requestAnimationFrame(fn) -> int:
	_timer_id += 1
	_rafs[_timer_id] = fn
	return _timer_id

func cancelAnimationFrame(id = null) -> void:
	if id != null: _rafs.erase(id)

var sim_speed := 0          # > 0: tests fast-forward this many 60 Hz ticks per rendered frame
var perf_pump_usec := 0    # time spent in game callbacks last frame

func _process(_dt: float) -> void:
	Ctx2D.frame_id += 1
	if not hooks.is_empty(): hooks.clear()   # hooks never outlive the call that installed them
	var t0 := Time.get_ticks_usec()
	if sim_speed > 0:
		if virtual_time < 0.0: virtual_time = now()
		for i in range(sim_speed):
			virtual_time += 1000.0 / 60.0
			pump()
	elif virtual_time < 0.0: pump()
	perf_pump_usec = Time.get_ticks_usec() - t0

# Runs due animation-frame callbacks and timers once.
func pump() -> void:
	var ts = _clock()
	if not _rafs.is_empty():
		var batch = _rafs
		_rafs = {}
		_in_raf = true
		for id in batch.keys():
			invoke(batch[id], [ts])
		_in_raf = false
	if not _timers.is_empty():
		var due = []
		for id in _timers.keys():
			if _timers[id].due <= ts: due.append(id)
		due.sort_custom(func(a, b): return _timers[a].due < _timers[b].due or (_timers[a].due == _timers[b].due and a < b))
		for id in due:
			if not _timers.has(id): continue
			var tm = _timers[id]
			if tm.every > 0: tm.due = ts + tm.every
			else: _timers.erase(id)
			invoke(tm.fn, [])

func pending_timers() -> int:
	return _timers.size()

func next_timer_due() -> float:
	var m = INF
	for id in _timers.keys(): m = minf(m, _timers[id].due)
	return m

# ───────────────────────── misc browser bits ─────────────────────────
func confirm(_msg = null) -> bool:
	return true

# Yes/No dialog built from DOM elements; calls `on_yes` when confirmed.
func confirmDialog(msg, on_yes) -> void:
	var overlay: DomNode = document.createElement("div")
	overlay.style.cssText = "position:fixed;inset:0;background:rgba(0,0,0,.72);z-index:9500;display:flex;align-items:center;justify-content:center;"
	var box: DomNode = document.createElement("div")
	box.style.cssText = "background:#0d0b09;border:1px solid #3a2a10;border-radius:8px;padding:1.2rem 1.4rem;max-width:340px;text-align:center;box-shadow:0 8px 40px rgba(0,0,0,.8);"
	var text: DomNode = document.createElement("div")
	text.style.cssText = "font-family:'Cinzel',serif;font-size:.8rem;color:#c8a060;margin-bottom:1rem;line-height:1.5;"
	text.textContent = s(msg)
	var row: DomNode = document.createElement("div")
	row.style.cssText = "display:flex;gap:.6rem;justify-content:center;"
	var yes: DomNode = document.createElement("button")
	yes.style.cssText = "background:#1a0a08;border:1px solid #6a2a1a;color:#e06a4a;font-family:'Cinzel',serif;font-size:.7rem;padding:.4rem 1rem;border-radius:4px;cursor:pointer;"
	yes.textContent = "Yes"
	var no: DomNode = document.createElement("button")
	no.style.cssText = "background:#0f0d0b;border:1px solid #3a3020;color:#8a6a30;font-family:'Cinzel',serif;font-size:.7rem;padding:.4rem 1rem;border-radius:4px;cursor:pointer;"
	no.textContent = "Cancel"
	yes.onclick = func():
		overlay.remove()
		invoke(on_yes, [])
	no.onclick = func(): overlay.remove()
	row.appendChild(yes); row.appendChild(no)
	box.appendChild(text); box.appendChild(row)
	overlay.appendChild(box)
	document.body.appendChild(overlay)

func alert(msg = null) -> void:
	print("[alert] ", s(msg))

func console_log(args: Array) -> void:
	print(" ".join(PackedStringArray(args.map(func(a): return s(a)))))

func console_warn(args: Array) -> void:
	push_warning(" ".join(PackedStringArray(args.map(func(a): return s(a)))))

func console_error(args: Array) -> void:
	push_error(" ".join(PackedStringArray(args.map(func(a): return s(a)))))

func gtag(_args: Array) -> void:
	pass

# True for editor / debug runs, so development play never reports analytics.
func isLocalBuild() -> bool:
	return OS.is_debug_build() or DisplayServer.get_name() == "headless"

func fetch(url, opts = null):
	var req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_r, _c, _h, _b): req.queue_free())
	var headers = PackedStringArray()
	var method = HTTPClient.METHOD_GET
	var body = ""
	if opts is Dictionary:
		for k in opts.get("headers", {}).keys(): headers.append("%s: %s" % [k, opts.headers[k]])
		if opts.get("method", "GET") == "POST": method = HTTPClient.METHOD_POST
		body = s(opts.get("body", ""))
	req.request(s(url), headers, method, body)
	return null
