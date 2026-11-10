# InlineJS — evaluates the tiny JavaScript snippets found in inline event handlers,
# e.g.  onclick="event.stopPropagation();selectSaveSlot(2)"  or  onclick="if(event.target===this)closeModal()".
class_name InlineJS
extends RefCounted

static var _cache: Dictionary = {}
static var _globals: Dictionary = {}      # name -> [module, "f"/"v", gdName]
static var _tree: SceneTree = null

static func setup(globals: Dictionary) -> void:
	_globals = globals

static func run(code: String, this_node, event) -> void:
	var ast = _cache.get(code)
	if ast == null:
		var p := _Parser.new(code)
		ast = p.program()
		_cache[code] = ast
	var env := {"this": this_node, "event": event}
	for stmt in ast:
		var r = _eval(stmt, env)
		if env.has("__return"): break

# Resolve a global name: function → Callable, variable → value.
static func global(name_: String):
	var g = _globals.get(name_)
	if g == null:
		var w = window.get(name_)
		return w
	var mod := (Engine.get_main_loop() as SceneTree).root.get_node_or_null(g[0])
	if mod == null: return null
	if g[1] == "f": return Callable(mod, g[2])
	return mod.get(g[2])

static func _eval(n, env: Dictionary):
	match n[0]:
		"num", "str": return n[1]
		"lit": return n[1]
		"id":
			var name_: String = n[1]
			if env.has(name_): return env[name_]
			match name_:
				"document": return document
				"window": return window
				"localStorage": return localStorage
				"undefined": return null
			return global(name_)
		"if":
			if JS.t(_eval(n[1], env)): return _eval(n[2], env)
			elif n.size() > 3 and n[3] != null: return _eval(n[3], env)
			return null
		"ret":
			env["__return"] = true
			return _eval(n[1], env) if n[1] != null else null
		"un":
			var v = _eval(n[2], env)
			if n[1] == "!": return not JS.t(v)
			return -v
		"bin":
			var op: String = n[1]
			if op == "&&":
				var l = _eval(n[2], env)
				return _eval(n[3], env) if JS.t(l) else l
			if op == "||":
				var l2 = _eval(n[2], env)
				return l2 if JS.t(l2) else _eval(n[3], env)
			var a = _eval(n[2], env); var b = _eval(n[3], env)
			match op:
				"===", "==": return JS.eq(a, b)
				"!==", "!=": return not JS.eq(a, b)
				"+":
					if a is String or b is String: return JS.s(a) + JS.s(b)
					return a + b
				"-": return a - b
				"*": return a * b
				"/": return a / float(b)
				"<": return a < b
				">": return a > b
				"<=": return a <= b
				">=": return a >= b
			return null
		"tern": return _eval(n[2], env) if JS.t(_eval(n[1], env)) else _eval(n[3], env)
		"block":
			var last = null
			for st in n[1]:
				last = _eval(st, env)
				if env.has("__return"): break
			return last
		"obj":
			var d := {}
			for kv in n[1]: d[kv[0]] = _eval(kv[1], env)
			return d
		"arr":
			var out := []
			for e in n[1]: out.append(_eval(e, env))
			return out
		"mem":
			var o = _eval(n[1], env)
			var key = n[2] if n[2] is String else _eval(n[2], env)
			return _member(o, key)
		"call":
			var args := []
			for a2 in n[2]: args.append(_eval(a2, env))
			var callee = n[1]
			if callee[0] == "mem":
				var o2 = _eval(callee[1], env)
				var key2 = callee[2] if callee[2] is String else _eval(callee[2], env)
				if o2 == null: return null
				if o2 is Object and o2.has_method(key2): return o2.callv(key2, JS._fit(Callable(o2, key2), args))
				return JS.callm(o2, key2, args)
			var f = _eval(callee, env)
			if f is Callable: return JS.invoke(f, args)
			push_warning("InlineJS: '%s' is not callable" % str(callee))
			return null
		"asg":
			var val = _eval(n[2], env)
			var target = n[1]
			if target[0] == "mem":
				var o3 = _eval(target[1], env)
				var key3 = target[2] if target[2] is String else _eval(target[2], env)
				if o3 is Dictionary: o3[key3] = val
				elif o3 is Object: o3.set(key3, val)
			elif target[0] == "id":
				var g = _globals.get(target[1])
				if g != null:
					var mod := (Engine.get_main_loop() as SceneTree).root.get_node_or_null(g[0])
					if mod != null: mod.set(g[2], val)
				else: window.set(target[1], val)
			return val
	return null

static func _member(o, key):
	if o == null: return null
	if o is Dictionary or o is Array or o is String:
		if key is String and key == "length": return len(o)
		return JS.idx(o, key)
	if o is Object: return o.get(key)
	return null

class _Parser:
	var toks: Array = []
	var i := 0

	func _init(src: String) -> void:
		_lex(src)

	func _lex(s: String) -> void:
		var n := s.length()
		var p := 0
		while p < n:
			var c := s[p]
			if c == " " or c == "\n" or c == "\t" or c == "\r":
				p += 1
			elif c == "'" or c == "\"" or c == "`":
				var e := p + 1
				var out := ""
				while e < n and s[e] != c:
					if s[e] == "\\" and e + 1 < n:
						e += 1
						match s[e]:
							"n": out += "\n"
							"t": out += "\t"
							_: out += s[e]
					else: out += s[e]
					e += 1
				toks.append(["str", out])
				p = e + 1
			elif (c >= "0" and c <= "9") or (c == "." and p + 1 < n and s[p + 1] >= "0" and s[p + 1] <= "9"):
				var e2 := p
				while e2 < n and ((s[e2] >= "0" and s[e2] <= "9") or s[e2] == "."): e2 += 1
				var t := s.substr(p, e2 - p)
				toks.append(["num", t.to_float() if t.contains(".") else t.to_int()])
				p = e2
			elif (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_" or c == "$":
				var e3 := p
				while e3 < n and ((s[e3] >= "a" and s[e3] <= "z") or (s[e3] >= "A" and s[e3] <= "Z") or (s[e3] >= "0" and s[e3] <= "9") or s[e3] == "_" or s[e3] == "$"): e3 += 1
				toks.append(["id", s.substr(p, e3 - p)])
				p = e3
			else:
				var three := s.substr(p, 3)
				var two := s.substr(p, 2)
				if three == "===" or three == "!==":
					toks.append(["op", three]); p += 3
				elif two == "==" or two == "!=" or two == "&&" or two == "||" or two == "<=" or two == ">=":
					toks.append(["op", two]); p += 2
				else:
					toks.append(["op", c]); p += 1
		toks.append(["eof", ""])

	func peek_op(v: String) -> bool:
		return toks[i][0] == "op" and toks[i][1] == v

	func eat_op(v: String) -> bool:
		if peek_op(v):
			i += 1
			return true
		return false

	func program() -> Array:
		var out := []
		while toks[i][0] != "eof":
			if eat_op(";"): continue
			out.append(statement())
		return out

	func statement():
		if toks[i][0] == "id" and toks[i][1] == "if":
			i += 1
			eat_op("(")
			var c = expr()
			eat_op(")")
			var body = statement()
			eat_op(";")
			var alt = null
			if toks[i][0] == "id" and toks[i][1] == "else":
				i += 1
				alt = statement()
			return ["if", c, body, alt]
		if toks[i][0] == "id" and toks[i][1] == "return":
			i += 1
			if toks[i][0] == "eof" or peek_op(";"): return ["ret", null]
			return ["ret", expr()]
		if eat_op("{"):
			var stmts := []
			while not peek_op("}") and toks[i][0] != "eof":
				if eat_op(";"): continue
				stmts.append(statement())
			eat_op("}")
			return ["block", stmts]
		return expr()

	func expr():
		var l = ternary()
		if peek_op("=") :
			i += 1
			return ["asg", l, expr()]
		return l

	func ternary():
		var c = binary(0)
		if eat_op("?"):
			var a = expr()
			eat_op(":")
			var b = expr()
			return ["tern", c, a, b]
		return c

	const LEVELS := [["||"], ["&&"], ["===", "!==", "==", "!="], ["<", ">", "<=", ">="], ["+", "-"], ["*", "/"]]

	func binary(level: int):
		if level >= LEVELS.size(): return unary()
		var l = binary(level + 1)
		while toks[i][0] == "op" and LEVELS[level].has(toks[i][1]):
			var op: String = toks[i][1]
			i += 1
			l = ["bin", op, l, binary(level + 1)]
		return l

	func unary():
		if peek_op("!") or peek_op("-"):
			var op: String = toks[i][1]
			i += 1
			return ["un", op, unary()]
		return postfix()

	func postfix():
		var e = primary()
		while true:
			if eat_op("."):
				e = ["mem", e, toks[i][1]]
				i += 1
			elif eat_op("["):
				var k = expr()
				eat_op("]")
				e = ["mem", e, k]
			elif eat_op("("):
				var args := []
				while not peek_op(")") and toks[i][0] != "eof":
					args.append(expr())
					eat_op(",")
				eat_op(")")
				e = ["call", e, args]
			else: break
		return e

	func primary():
		var t = toks[i]
		i += 1
		match t[0]:
			"num": return ["num", t[1]]
			"str": return ["str", t[1]]
			"id":
				match t[1]:
					"true": return ["lit", true]
					"false": return ["lit", false]
					"null", "undefined": return ["lit", null]
				return ["id", t[1]]
			"op":
				if t[1] == "(":
					var e = expr()
					eat_op(")")
					return e
				if t[1] == "{":
					var pairs := []
					while not peek_op("}") and toks[i][0] != "eof":
						var key = toks[i][1]
						i += 1
						eat_op(":")
						pairs.append([str(key), expr()])
						eat_op(",")
					eat_op("}")
					return ["obj", pairs]
				if t[1] == "[":
					var items := []
					while not peek_op("]") and toks[i][0] != "eof":
						items.append(expr())
						eat_op(",")
					eat_op("]")
					return ["arr", items]
		return ["lit", null]
