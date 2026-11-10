# Boot — main scene script: loads the page, starts every game module in order.
extends Node

func _ready() -> void:
	randomize()
	InlineJS.setup(GameModules.GLOBALS)
	document.load_page("res://web/index.html", ["res://web/styles.css"])
	for m in GameModules.ORDER:
		var mod := get_node_or_null("/root/" + m)
		if mod != null: mod._boot()
	_version_label()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--driver="):
			var d = load("res://dev/Driver.gd").new()
			d.name = "Driver"
			d.script_path = a.substr(9)
			add_child(d)

# small build stamp in the corner (index.html's inline script)
func _version_label() -> void:
	var v = Version.GAME_VERSION
	if not (v is Dictionary) or not JS.t(v.get("hash")) or v.get("hash") == "dev": return
	var el: DomNode = document.createElement("div")
	el.style.cssText = "position:fixed;bottom:6px;left:8px;font-size:.5rem;color:#3a3028;font-family:monospace;pointer-events:none;z-index:9999;letter-spacing:.04em;"
	el.textContent = ("v" + JS.s(v.version) + "  " if JS.t(v.get("version")) else "") + JS.s(v.hash) + ("  " + JS.s(v.date) if JS.t(v.get("date")) else "")
	document.body.appendChild(el)
