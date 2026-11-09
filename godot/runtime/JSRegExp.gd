# JSRegExp — compiled regular expression with JavaScript-style flags.
class_name JSRegExp
extends RefCounted

var regex := RegEx.new()
var global := false
var source := ""

func _init(pattern: String, flags: String = "") -> void:
	source = pattern
	global = flags.contains("g")
	var prefix = ""
	if flags.contains("i"): prefix += "(?i)"
	if flags.contains("s"): prefix += "(?s)"
	if flags.contains("m"): prefix += "(?m)"
	if regex.compile(prefix + pattern) != OK:
		push_error("JSRegExp: cannot compile /%s/%s" % [pattern, flags])

func test(text) -> bool:
	return regex.search(JS.s(text)) != null
