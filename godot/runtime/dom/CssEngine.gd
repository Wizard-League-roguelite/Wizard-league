# CssEngine — parses style sheets and computes the cascaded style of DOM nodes.
# Supports the subset of CSS the game uses: class/id/tag selectors with descendant,
# child and adjacent combinators, :hover/:active/:disabled/:not()/:first-child/:last-child/:empty,
# ::before/::after, @media (min/max width/height), @keyframes, custom properties and calc().
class_name CssEngine
extends RefCounted

const INHERITED := {
	"color": true, "font-family": true, "font-size": true, "font-weight": true, "font-style": true,
	"letter-spacing": true, "line-height": true, "text-align": true, "text-transform": true,
	"white-space": true, "cursor": true, "visibility": true, "text-shadow": true, "word-break": true,
	"overflow-wrap": true, "pointer-events": true, "user-select": true, "list-style": true,
	"text-indent": true, "word-spacing": true, "image-rendering": true,
}

var rules: Array = []            # {sel: Array(compounds), spec: int, order: int, decls: Dictionary, imp: Dictionary, media: String, pseudo_el: String}
var keyframes: Dictionary = {}   # name -> Array of {t: float, decls: Dictionary}
var _index: Dictionary = {}      # key ("#id" / ".class" / "tag" / "*") -> Array of rules
var _order := 0
var hover_keys: Dictionary = {}  # keys of compounds that carry :hover / :active
var pe_keys: Dictionary = {}     # index keys that have ::before / ::after rules
var viewport := Vector2(1280, 720)
var generation := 0              # bumped whenever the rule set (or media state) changes
var _media_cache: Dictionary = {}

# ───────────────────────── parsing ─────────────────────────
func add_sheet(css: String) -> void:
	css = _strip_comments(css)
	_parse_block(css, "")
	generation += 1

func _strip_comments(css: String) -> String:
	var out := ""
	var i := 0
	while true:
		var a := css.find("/*", i)
		if a < 0:
			out += css.substr(i)
			break
		out += css.substr(i, a - i)
		var b := css.find("*/", a + 2)
		if b < 0: break
		i = b + 2
	return out

func _parse_block(css: String, media: String) -> void:
	var i := 0
	var n := css.length()
	while i < n:
		var brace := css.find("{", i)
		if brace < 0: break
		var prelude := css.substr(i, brace - i).strip_edges()
		var close := _match_brace(css, brace)
		var body := css.substr(brace + 1, close - brace - 1)
		i = close + 1
		if prelude.begins_with("@media"):
			var cond := prelude.substr(6).strip_edges()
			_parse_block(body, cond if media == "" else media + " and " + cond)
		elif prelude.begins_with("@keyframes") or prelude.begins_with("@-webkit-keyframes"):
			var kname := prelude.substr(prelude.find("keyframes") + 9).strip_edges()
			keyframes[kname] = _parse_keyframes(body)
		elif prelude.begins_with("@"):
			pass
		else:
			_add_rule(prelude, body, media)

func _match_brace(s: String, open: int) -> int:
	var depth := 0
	var i := open
	var n := s.length()
	while i < n:
		var c := s[i]
		if c == "{": depth += 1
		elif c == "}":
			depth -= 1
			if depth == 0: return i
		i += 1
	return n

func _parse_keyframes(body: String) -> Array:
	var frames := []
	var i := 0
	while true:
		var brace := body.find("{", i)
		if brace < 0: break
		var sel := body.substr(i, brace - i).strip_edges()
		var close := body.find("}", brace)
		if close < 0: close = body.length()
		var d := parse_declarations(body.substr(brace + 1, close - brace - 1))
		for part in sel.split(","):
			var p := part.strip_edges()
			var t := 0.0
			if p == "from": t = 0.0
			elif p == "to": t = 1.0
			else: t = CssValue.f(p) / 100.0
			frames.append({"t": t, "decls": d[0]})
		i = close + 1
	frames.sort_custom(func(a, b): return a.t < b.t)
	return frames

func _add_rule(prelude: String, body: String, media: String) -> void:
	var d := parse_declarations(body)
	if d[0].is_empty(): return
	for sel_text in _split_top(prelude, ","):
		var sel := _parse_selector(sel_text.strip_edges())
		if sel.is_empty(): continue
		_order += 1
		var rule := {"sel": sel.compounds, "spec": sel.spec, "order": _order, "decls": d[0], "imp": d[1], "media": media, "pseudo_el": sel.pseudo_el}
		rules.append(rule)
		var last: Dictionary = sel.compounds[sel.compounds.size() - 1]
		var key := "*"
		if last.id != "": key = "#" + last.id
		elif last.classes.size() > 0: key = "." + last.classes[0]
		elif last.tag != "": key = last.tag
		if not _index.has(key): _index[key] = []
		_index[key].append(rule)
		if sel.pseudo_el == "before" or sel.pseudo_el == "after": pe_keys[key] = true
		for c in sel.compounds:
			if c.hover:
				if c.id != "": hover_keys["#" + c.id] = true
				for cl in c.classes: hover_keys["." + cl] = true
				if c.tag != "": hover_keys[c.tag] = true
				if c.id == "" and c.classes.is_empty() and c.tag == "": hover_keys["*"] = true

# selector → {compounds: [{tag,id,classes,pseudos,comb,hover}], spec, pseudo_el}
func _parse_selector(text: String) -> Dictionary:
	var compounds := []
	var spec := 0
	var pseudo_el := ""
	var i := 0
	var n := text.length()
	var comb := ""
	var cur := _new_compound()
	var has_cur := false
	while i < n:
		var c := text[i]
		if c == " " or c == ">" or c == "+" or c == "~":
			var j := i
			var found := " "
			while j < n and (text[j] == " " or text[j] == ">" or text[j] == "+" or text[j] == "~"):
				if text[j] != " ": found = text[j]
				j += 1
			if has_cur:
				cur.comb = comb
				compounds.append(cur)
				cur = _new_compound()
				has_cur = false
			comb = found
			i = j
			continue
		has_cur = true
		if c == "#":
			var e := _ident_end(text, i + 1)
			cur.id = text.substr(i + 1, e - i - 1); spec += 10000; i = e
		elif c == ".":
			var e2 := _ident_end(text, i + 1)
			cur.classes.append(text.substr(i + 1, e2 - i - 1)); spec += 100; i = e2
		elif c == ":":
			var dbl := i + 1 < n and text[i + 1] == ":"
			var st := i + (2 if dbl else 1)
			var e3 := _ident_end(text, st)
			var pname := text.substr(st, e3 - st)
			var arg := ""
			if e3 < n and text[e3] == "(":
				var close := _match_paren(text, e3)
				arg = text.substr(e3 + 1, close - e3 - 1)
				e3 = close + 1
			if dbl or pname == "before" or pname == "after":
				if pname == "before" or pname == "after": pseudo_el = pname
				else: pseudo_el = "unsupported"
				spec += 1
			else:
				if pname == "not":
					cur.pseudos.append({"name": "not", "arg": _parse_selector(arg.strip_edges())})
				else:
					cur.pseudos.append({"name": pname, "arg": arg})
				if pname == "hover" or pname == "active" or pname == "focus": cur.hover = true
				spec += 100
			i = e3
		elif c == "*":
			i += 1
		elif c == "[":
			var cb := text.find("]", i)
			cur.pseudos.append({"name": "attr", "arg": text.substr(i + 1, cb - i - 1)})
			spec += 100
			i = cb + 1 if cb >= 0 else n
		else:
			var e4 := _ident_end(text, i)
			if e4 == i:
				i += 1
				continue
			cur.tag = text.substr(i, e4 - i).to_lower(); spec += 1; i = e4
	if has_cur:
		cur.comb = comb
		compounds.append(cur)
	if compounds.is_empty(): return {}
	return {"compounds": compounds, "spec": spec, "pseudo_el": pseudo_el}

func _new_compound() -> Dictionary:
	return {"tag": "", "id": "", "classes": [], "pseudos": [], "comb": "", "hover": false}

func _ident_end(s: String, i: int) -> int:
	var n := s.length()
	while i < n:
		var c := s.unicode_at(i)
		if (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 45 or c == 95 or c > 127: i += 1
		else: break
	return i

func _match_paren(s: String, open: int) -> int:
	var depth := 0
	var i := open
	while i < s.length():
		if s[i] == "(": depth += 1
		elif s[i] == ")":
			depth -= 1
			if depth == 0: return i
		i += 1
	return s.length() - 1

static func _split_top(s: String, sep: String) -> PackedStringArray:
	var out := PackedStringArray()
	var depth := 0
	var start := 0
	var quote := ""
	for i in range(s.length()):
		var c := s[i]
		if quote != "":
			if c == quote: quote = ""
			continue
		if c == "'" or c == "\"": quote = c
		elif c == "(": depth += 1
		elif c == ")": depth -= 1
		elif c == sep and depth == 0:
			out.append(s.substr(start, i - start))
			start = i + 1
	out.append(s.substr(start))
	return out

static func split_ws(s: String) -> PackedStringArray:
	var out := PackedStringArray()
	var depth := 0
	var cur := ""
	var quote := ""
	for i in range(s.length()):
		var c := s[i]
		if quote != "":
			cur += c
			if c == quote: quote = ""
			continue
		if c == "'" or c == "\"":
			quote = c; cur += c
		elif c == "(":
			depth += 1; cur += c
		elif c == ")":
			depth -= 1; cur += c
		elif (c == " " or c == "\n" or c == "\t") and depth == 0:
			if cur != "": out.append(cur)
			cur = ""
		else: cur += c
	if cur != "": out.append(cur)
	return out

var _decl_cache: Dictionary = {}
# "a:b; c:d !important" → [decls, important]  (shorthands expanded)
func parse_declarations(body: String) -> Array:
	if _decl_cache.has(body): return _decl_cache[body]
	var decls := {}
	var imp := {}
	for part in _split_top(body, ";"):
		var colon := part.find(":")
		if colon < 0: continue
		var prop := part.substr(0, colon).strip_edges()
		var val := part.substr(colon + 1).strip_edges()
		if prop == "" or val == "": continue
		if not prop.begins_with("--"): prop = prop.to_lower()
		var important := false
		if val.ends_with("!important"):
			important = true
			val = val.substr(0, val.length() - 10).strip_edges()
		var tmp := {}
		expand(prop, val, tmp)
		for k in tmp.keys():
			decls[k] = tmp[k]
			if important: imp[k] = true
			else: imp.erase(k)
	var res := [decls, imp]
	if _decl_cache.size() > 4000: _decl_cache.clear()
	_decl_cache[body] = res
	return res

const _SIDES := ["top", "right", "bottom", "left"]
const _BORDER_STYLES := {"none": 1, "solid": 1, "dashed": 1, "dotted": 1, "double": 1, "hidden": 1, "groove": 1, "ridge": 1, "inset": 1, "outset": 1}

static func expand(prop: String, val: String, out: Dictionary) -> void:
	match prop:
		"margin", "padding":
			var p := split_ws(val)
			var v := _four(p)
			for i in range(4): out[prop + "-" + _SIDES[i]] = v[i]
		"inset":
			var p2 := split_ws(val)
			var v2 := _four(p2)
			for i in range(4): out[_SIDES[i]] = v2[i]
		"border", "border-top", "border-right", "border-bottom", "border-left", "outline":
			if prop == "outline": return
			var w := "medium"; var st := "none"; var col := "currentcolor"
			for tok in split_ws(val):
				var tl := tok.to_lower()
				if _BORDER_STYLES.has(tl): st = tl
				elif tl[0].is_valid_int() or tl[0] == "." or tl == "thin" or tl == "medium" or tl == "thick" or tl.begins_with("calc"): w = tok
				else: col = tok
			if w == "medium": w = "3px"
			elif w == "thin": w = "1px"
			elif w == "thick": w = "5px"
			var sides: Array = _SIDES if prop == "border" else [prop.substr(7)]
			for s in sides:
				out["border-" + s + "-width"] = w
				out["border-" + s + "-style"] = st
				out["border-" + s + "-color"] = col
		"border-width", "border-style", "border-color":
			var kind := prop.substr(7)
			var v3 := _four(split_ws(val))
			for i in range(4): out["border-" + _SIDES[i] + "-" + kind] = v3[i]
		"border-radius":
			var main := val.split("/")[0]
			var p4 := split_ws(main)
			var r := [p4[0], p4[0], p4[0], p4[0]]
			if p4.size() == 2: r = [p4[0], p4[1], p4[0], p4[1]]
			elif p4.size() == 3: r = [p4[0], p4[1], p4[2], p4[1]]
			elif p4.size() >= 4: r = [p4[0], p4[1], p4[2], p4[3]]
			out["border-top-left-radius"] = r[0]; out["border-top-right-radius"] = r[1]
			out["border-bottom-right-radius"] = r[2]; out["border-bottom-left-radius"] = r[3]
		"background":
			# colour and/or image layers
			var layers := _split_top(val, ",")
			var images := PackedStringArray()
			var color := ""
			for layer in layers:
				var l := layer.strip_edges()
				if l.contains("gradient(") or l.begins_with("url("): images.append(l)
				elif l == "none" or l == "transparent":
					if color == "": color = "transparent"
				else:
					# may be "color extra-tokens"; keep the first token that parses as a colour
					color = l
			out["background-color"] = color if color != "" else "transparent"
			out["background-image"] = ", ".join(images) if images.size() > 0 else "none"
		"flex":
			var p5 := split_ws(val)
			if val == "none":
				out["flex-grow"] = "0"; out["flex-shrink"] = "0"; out["flex-basis"] = "auto"
			elif val == "auto":
				out["flex-grow"] = "1"; out["flex-shrink"] = "1"; out["flex-basis"] = "auto"
			elif p5.size() == 1:
				if p5[0].is_valid_float():
					out["flex-grow"] = p5[0]; out["flex-shrink"] = "1"; out["flex-basis"] = "0%"
				else:
					out["flex-grow"] = "1"; out["flex-shrink"] = "1"; out["flex-basis"] = p5[0]
			elif p5.size() == 2:
				out["flex-grow"] = p5[0]
				if p5[1].is_valid_float():
					out["flex-shrink"] = p5[1]; out["flex-basis"] = "0%"
				else:
					out["flex-shrink"] = "1"; out["flex-basis"] = p5[1]
			else:
				out["flex-grow"] = p5[0]; out["flex-shrink"] = p5[1]; out["flex-basis"] = p5[2]
		"flex-flow":
			for tok in split_ws(val):
				if tok == "wrap" or tok == "nowrap" or tok == "wrap-reverse": out["flex-wrap"] = tok
				else: out["flex-direction"] = tok
		"gap":
			var p6 := split_ws(val)
			out["row-gap"] = p6[0]
			out["column-gap"] = p6[1] if p6.size() > 1 else p6[0]
		"overflow":
			var p7 := split_ws(val)
			out["overflow-x"] = p7[0]
			out["overflow-y"] = p7[1] if p7.size() > 1 else p7[0]
		"font":
			# [style] [weight] size[/line-height] family
			var toks := split_ws(val)
			var idx := 0
			while idx < toks.size():
				var tk := toks[idx]
				if tk == "italic": out["font-style"] = "italic"
				elif tk == "bold" or tk == "bolder" or tk.is_valid_int(): out["font-weight"] = tk
				elif tk == "normal": pass
				else: break
				idx += 1
			if idx < toks.size():
				var sz := toks[idx].split("/")
				out["font-size"] = sz[0]
				if sz.size() > 1: out["line-height"] = sz[1]
				idx += 1
			if idx < toks.size(): out["font-family"] = " ".join(toks.slice(idx))
		"-webkit-backdrop-filter", "-webkit-appearance", "-webkit-overflow-scrolling", "-webkit-line-clamp", "-webkit-box-orient":
			pass
		_:
			out[prop] = val

static func _four(p: PackedStringArray) -> Array:
	if p.size() == 0: return ["0", "0", "0", "0"]
	if p.size() == 1: return [p[0], p[0], p[0], p[0]]
	if p.size() == 2: return [p[0], p[1], p[0], p[1]]
	if p.size() == 3: return [p[0], p[1], p[2], p[1]]
	return [p[0], p[1], p[2], p[3]]

# ───────────────────────── matching ─────────────────────────
func media_ok(media: String) -> bool:
	if media == "": return true
	if _media_cache.has(media): return _media_cache[media]
	var ok := true
	for part in media.split(" and "):
		var p := part.strip_edges().trim_prefix("(").trim_suffix(")")
		if p == "screen" or p == "all" or p == "": continue
		var kv := p.split(":")
		if kv.size() < 2: continue
		var k := kv[0].strip_edges()
		var v := CssValue.f(kv[1].strip_edges())
		match k:
			"max-width": ok = ok and viewport.x <= v
			"min-width": ok = ok and viewport.x >= v
			"max-height": ok = ok and viewport.y <= v
			"min-height": ok = ok and viewport.y >= v
			"hover": ok = ok
			"orientation": ok = ok and ((kv[1].strip_edges() == "landscape") == (viewport.x >= viewport.y))
			_: ok = false
	_media_cache[media] = ok
	return ok

func set_viewport(v: Vector2) -> bool:
	if v == viewport: return false
	var before := {}
	for m in _media_cache.keys(): before[m] = _media_cache[m]
	viewport = v
	_media_cache.clear()
	var changed := false
	for m in before.keys():
		if media_ok(m) != before[m]: changed = true
	if changed: generation += 1
	return changed

func _match_compound(node: DomNode, c: Dictionary) -> bool:
	if c.tag != "" and c.tag != node.tag: return false
	if c.id != "" and c.id != node.id: return false
	for cl in c.classes:
		if not node.classes.has(cl): return false
	for p in c.pseudos:
		match p.name:
			"hover":
				if not node._hover: return false
			"active":
				if not node._active: return false
			"focus":
				if not node._focus: return false
			"disabled":
				if not node.disabled: return false
			"not":
				var inner: Dictionary = p.arg
				if not inner.is_empty() and _match_compound(node, inner.compounds[0]): return false
			"first-child":
				var par := node.parentElement
				if par == null or par.first_element_child() != node: return false
			"last-child":
				var par2 := node.parentElement
				if par2 == null or par2.last_element_child() != node: return false
			"empty":
				if node.childNodes.size() > 0: return false
			_:
				return false
	return true

func _match_rule(node: DomNode, sel: Array) -> bool:
	var i := sel.size() - 1
	if not _match_compound(node, sel[i]): return false
	return _match_rest(node, sel, i)

func _match_rest(node: DomNode, sel: Array, i: int) -> bool:
	if i == 0: return true
	var comb: String = sel[i].comb
	var prev: Dictionary = sel[i - 1]
	if comb == ">":
		var p := node.parentElement
		return p != null and _match_compound(p, prev) and _match_rest(p, sel, i - 1)
	if comb == "+":
		var s := node.previous_element_sibling()
		return s != null and _match_compound(s, prev) and _match_rest(s, sel, i - 1)
	if comb == "~":
		var s2 := node.previous_element_sibling()
		while s2 != null:
			if _match_compound(s2, prev) and _match_rest(s2, sel, i - 1): return true
			s2 = s2.previous_element_sibling()
		return false
	var a := node.parentElement
	while a != null:
		if _match_compound(a, prev) and _match_rest(a, sel, i - 1): return true
		a = a.parentElement
	return false

func has_pseudo(node: DomNode) -> bool:
	if pe_keys.is_empty(): return false
	if pe_keys.has("*") or pe_keys.has(node.tag): return true
	if node._id != "" and pe_keys.has("#" + node._id): return true
	for cl in node.classes:
		if pe_keys.has("." + cl): return true
	return false

# Rules that apply to `node` (pseudo_el "" / "before" / "after"), cascade-sorted.
func matching_rules(node: DomNode, pseudo_el: String) -> Array:
	var cands := []
	if node.id != "" and _index.has("#" + node.id): cands.append_array(_index["#" + node.id])
	for cl in node.classes:
		if _index.has("." + cl): cands.append_array(_index["." + cl])
	if _index.has(node.tag): cands.append_array(_index[node.tag])
	if _index.has("*"): cands.append_array(_index["*"])
	var out := []
	var seen := {}
	for r in cands:
		if r.pseudo_el != pseudo_el: continue
		if seen.has(r.order): continue
		if not media_ok(r.media): continue
		if _match_rule(node, r.sel):
			seen[r.order] = true
			out.append(r)
	out.sort_custom(func(a, b): return a.spec < b.spec or (a.spec == b.spec and a.order < b.order))
	return out

# user-agent defaults
const UA := {
	"div": {"display": "block"}, "p": {"display": "block"}, "body": {"display": "block"}, "html": {"display": "block"},
	"h1": {"display": "block", "font-size": "2em", "font-weight": "bold"},
	"h2": {"display": "block", "font-size": "1.5em", "font-weight": "bold"},
	"h3": {"display": "block", "font-size": "1.17em", "font-weight": "bold"},
	"h4": {"display": "block", "font-weight": "bold"},
	"b": {"font-weight": "bold"}, "strong": {"font-weight": "bold"},
	"i": {"font-style": "italic"}, "em": {"font-style": "italic"},
	"button": {"display": "inline-block", "text-align": "center", "padding-top": "1px", "padding-bottom": "1px", "padding-left": "6px", "padding-right": "6px",
		"border-top-width": "2px", "border-right-width": "2px", "border-bottom-width": "2px", "border-left-width": "2px",
		"border-top-style": "solid", "border-right-style": "solid", "border-bottom-style": "solid", "border-left-style": "solid",
		"border-top-color": "#767676", "border-right-color": "#767676", "border-bottom-color": "#767676", "border-left-color": "#767676",
		"background-color": "#efefef", "color": "#000", "font-size": "13.333px", "font-family": "sans-serif", "cursor": "default",
		"letter-spacing": "normal", "text-transform": "none", "line-height": "normal", "font-weight": "normal", "font-style": "normal", "white-space": "normal", "text-shadow": "none"},
	"input": {"display": "inline-block", "font-size": "13.333px", "font-family": "sans-serif", "color": "#000", "background-color": "#fff", "cursor": "text",
		"letter-spacing": "normal", "text-transform": "none", "line-height": "normal"},
	"canvas": {"display": "inline"}, "svg": {"display": "inline"}, "img": {"display": "inline"},
	"style": {"display": "none"}, "script": {"display": "none"}, "head": {"display": "none"}, "title": {"display": "none"}, "meta": {"display": "none"}, "link": {"display": "none"},
	"br": {"display": "inline"}, "ul": {"display": "block"}, "li": {"display": "block"}, "label": {"display": "inline"},
	"table": {"display": "block"}, "hr": {"display": "block"}, "section": {"display": "block"}, "header": {"display": "block"}, "footer": {"display": "block"},
}

# Computes node.cs (the cascaded + inherited declarations as strings).
func compute(node: DomNode, parent_cs: Dictionary, pseudo_el: String = "") -> Dictionary:
	var cs := {}
	for k in parent_cs.keys():
		if INHERITED.has(k) or k.begins_with("--"): cs[k] = parent_cs[k]
	var own := {}
	if pseudo_el == "":
		var ua = UA.get(node.tag)
		if ua != null:
			for k in ua.keys(): own[k] = ua[k]
	var imp := {}
	var owner := node if pseudo_el == "" else node.parentElement
	for r in matching_rules(owner, pseudo_el):
		for k in r.decls.keys():
			if imp.has(k) and not r.imp.has(k): continue
			own[k] = r.decls[k]
			if r.imp.has(k): imp[k] = true
	if pseudo_el == "":
		var inline_decls: Dictionary = node.style._props
		for k in inline_decls.keys():
			if imp.has(k) and not node.style._imp.has(k): continue
			own[k] = inline_decls[k]
	# custom properties first so var() can see them
	for k in own.keys():
		if k.begins_with("--"): cs[k] = own[k]
	for k in own.keys():
		if k.begins_with("--"): continue
		var v: String = own[k]
		if v.contains("var("): v = _subst_vars(v, cs)
		if v == "inherit":
			if parent_cs.has(k): cs[k] = parent_cs[k]
			continue
		if v == "initial" or v == "unset":
			if not INHERITED.has(k) or v == "initial": cs.erase(k)
			continue
		if k == "font-size":
			# resolve relative sizes now, against the parent's size
			cs[k] = "%spx" % str(font_size_px(v, parent_cs))
		elif k == "line-height" and v.ends_with("em") and not v.ends_with("rem"):
			cs[k] = v  # resolved against own font-size later
		else:
			cs[k] = v
	return cs

func _subst_vars(v: String, cs: Dictionary) -> String:
	var guard := 0
	while guard < 8:
		guard += 1
		var a := v.find("var(")
		if a < 0: break
		var close := _match_paren(v, a + 3)
		var inner := v.substr(a + 4, close - a - 4)
		var comma := inner.find(",")
		var name_ := (inner if comma < 0 else inner.substr(0, comma)).strip_edges()
		var fallback := "" if comma < 0 else inner.substr(comma + 1).strip_edges()
		var rep: String = cs.get(name_, fallback)
		v = v.substr(0, a) + rep + v.substr(close + 1)
	return v

func font_size_px(v: String, parent_cs: Dictionary) -> float:
	var parent_px := 16.0
	if parent_cs.has("font-size"): parent_px = CssValue.f(parent_cs["font-size"])
	v = v.strip_edges()
	if v.ends_with("rem"): return CssValue.f(v) * 16.0
	if v.ends_with("em"): return CssValue.f(v) * parent_px
	if v.ends_with("%"): return CssValue.f(v) / 100.0 * parent_px
	if v.ends_with("px"): return CssValue.f(v)
	if v.begins_with("calc("):
		return CssValue.length(v, parent_px, parent_px, viewport)
	match v:
		"small": return 13.0
		"smaller": return parent_px * 0.83
		"large": return 18.0
		"larger": return parent_px * 1.2
		"medium": return 16.0
		"x-small": return 10.0
		"x-large": return 24.0
	if v.is_valid_float(): return CssValue.f(v)
	return parent_px
