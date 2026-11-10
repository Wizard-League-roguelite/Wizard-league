# HtmlParser — parses the HTML subset used by the game into DomNode trees.
class_name HtmlParser
extends RefCounted

const VOID := {"br": 1, "input": 1, "img": 1, "hr": 1, "meta": 1, "link": 1, "line": 1, "circle": 1, "path": 1, "rect": 1, "ellipse": 1, "polygon": 1, "polyline": 1, "stop": 1}
const RAW_TEXT := {"script": 1, "style": 1}
const ENTITIES := {"nbsp": " ", "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "middot": "·", "times": "×", "mdash": "—", "ndash": "–",
	"hellip": "…", "bull": "•", "larr": "←", "rarr": "→", "uarr": "↑", "darr": "↓", "copy": "©", "deg": "°", "laquo": "«", "raquo": "»", "starf": "★", "check": "✓", "hearts": "♥"}

static func decode(s: String) -> String:
	if not s.contains("&"): return s
	var out := ""
	var i := 0
	var n := s.length()
	while i < n:
		var c := s[i]
		if c == "&":
			var semi := s.find(";", i)
			if semi > 0 and semi - i <= 10:
				var ent := s.substr(i + 1, semi - i - 1)
				if ent.begins_with("#"):
					var code := ent.substr(2).hex_to_int() if ent.substr(1, 1).to_lower() == "x" else ent.substr(1).to_int()
					if code > 0:
						out += char(code); i = semi + 1
						continue
				elif ENTITIES.has(ent):
					out += ENTITIES[ent]; i = semi + 1
					continue
		out += c
		i += 1
	return out

# Returns the list of top-level nodes.
static func parse(html: String, doc) -> Array:
	var roots := []
	var stack: Array = []      # open elements
	var i := 0
	var n := html.length()
	while i < n:
		var lt := html.find("<", i)
		if lt < 0:
			_text(html.substr(i), stack, roots, doc)
			break
		if lt > i: _text(html.substr(i, lt - i), stack, roots, doc)
		if html.substr(lt, 4) == "<!--":
			var ce := html.find("-->", lt + 4)
			i = n if ce < 0 else ce + 3
			continue
		if lt + 1 < n and html[lt + 1] == "!":
			var de := html.find(">", lt)
			i = n if de < 0 else de + 1
			continue
		if lt + 1 < n and html[lt + 1] == "/":
			var ge := html.find(">", lt)
			if ge < 0: break
			var cname := html.substr(lt + 2, ge - lt - 2).strip_edges().to_lower()
			for k in range(stack.size() - 1, -1, -1):
				if stack[k].tag == cname:
					stack.resize(k)
					break
			i = ge + 1
			continue
		# not a tag start (e.g. "a < b")
		if lt + 1 >= n or not _is_name_start(html[lt + 1]):
			_text("<", stack, roots, doc)
			i = lt + 1
			continue
		# opening tag
		var j := lt + 1
		while j < n and not (html[j] == " " or html[j] == ">" or html[j] == "/" or html[j] == "\n" or html[j] == "\t" or html[j] == "\r"): j += 1
		var tname := html.substr(lt + 1, j - lt - 1).to_lower()
		var el := DomNode.new(tname, doc)
		var self_close := false
		# attributes
		while j < n:
			while j < n and (html[j] == " " or html[j] == "\n" or html[j] == "\t" or html[j] == "\r"): j += 1
			if j >= n: break
			if html[j] == ">":
				j += 1
				break
			if html[j] == "/":
				self_close = true
				j += 1
				continue
			var as_ := j
			while j < n and not (html[j] == "=" or html[j] == " " or html[j] == ">" or html[j] == "/" or html[j] == "\n" or html[j] == "\t"): j += 1
			var aname := html.substr(as_, j - as_)
			var aval := ""
			while j < n and (html[j] == " " or html[j] == "\n"): j += 1
			if j < n and html[j] == "=":
				j += 1
				while j < n and (html[j] == " " or html[j] == "\n"): j += 1
				if j < n and (html[j] == "\"" or html[j] == "'"):
					var q := html[j]
					var qe := html.find(q, j + 1)
					if qe < 0: qe = n
					aval = html.substr(j + 1, qe - j - 1)
					j = qe + 1
				else:
					var vs := j
					while j < n and not (html[j] == " " or html[j] == ">" or html[j] == "\n"): j += 1
					aval = html.substr(vs, j - vs)
			if aname != "": _attr(el, aname, decode(aval))
		_append(el, stack, roots)
		if RAW_TEXT.has(tname):
			var endtag := html.find("</" + tname, j)
			if endtag < 0: endtag = n
			var raw := html.substr(j, endtag - j)
			if raw != "":
				var tn := DomNode.new("#text", doc)
				tn.nodeType = DomNode.TEXT
				tn.data = raw
				tn._parent = weakref(el)
				el.childNodes.append(tn)
			var ge2 := html.find(">", endtag)
			i = n if ge2 < 0 else ge2 + 1
			continue
		if not self_close and not VOID.has(tname): stack.append(el)
		i = j
	return roots

static func _is_name_start(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")

static func _attr(el: DomNode, aname: String, aval: String) -> void:
	var lname := aname.to_lower()
	match lname:
		"id": el._id = aval
		"class": el.classes = Array(aval.split(" ", false))
		"style":
			var d := DomStyle._parse(aval)
			el.style._props = d[0].duplicate()
			el.style._imp = d[1].duplicate()
		"disabled": el._disabled = true
		"value": el._value = aval
		"checked": el._checked = true
		"width":
			if el.tag == "canvas": el._cw = maxi(1, aval.to_int())
			else: el.attrs[lname] = aval
		"height":
			if el.tag == "canvas": el._ch = maxi(1, aval.to_int())
			else: el.attrs[lname] = aval
		_:
			if lname.begins_with("data-"): el.dataset[DomNode._camel(lname.substr(5))] = aval
			elif lname.begins_with("on"): el._on[lname] = aval
			elif el.tag == "svg" or lname == "viewbox" or aname != lname: el.attrs[aname] = aval
			else: el.attrs[lname] = aval

static func _append(node: DomNode, stack: Array, roots: Array) -> void:
	if stack.is_empty(): roots.append(node)
	else:
		var p: DomNode = stack[stack.size() - 1]
		node._parent = weakref(p)
		p.childNodes.append(node)

static func _text(raw: String, stack: Array, roots: Array, doc) -> void:
	if raw == "": return
	var tn := DomNode.new("#text", doc)
	tn.nodeType = DomNode.TEXT
	tn.data = decode(raw)
	_append(tn, stack, roots)

static func _esc(s: String) -> String:
	return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

static func serialize_children(node: DomNode) -> String:
	var s := ""
	for c in node.childNodes: s += serialize(c)
	return s

static func serialize(node: DomNode) -> String:
	if node.nodeType == DomNode.TEXT: return _esc(node.data)
	var s := "<" + node.tag
	if node._id != "": s += " id=\"%s\"" % node._id
	if node.classes.size() > 0: s += " class=\"%s\"" % node.className
	var css := node.style.cssText
	if css != "": s += " style=\"%s\"" % css.replace("\"", "&quot;")
	for k in node.attrs.keys(): s += " %s=\"%s\"" % [k, str(node.attrs[k]).replace("\"", "&quot;")]
	for k in node.dataset.keys(): s += " data-%s=\"%s\"" % [k, str(node.dataset[k]).replace("\"", "&quot;")]
	for k in node._on.keys():
		if node._on[k] is String: s += " %s=\"%s\"" % [k, node._on[k].replace("\"", "&quot;")]
	if node._disabled: s += " disabled"
	s += ">"
	if VOID.has(node.tag): return s
	return s + serialize_children(node) + "</" + node.tag + ">"
