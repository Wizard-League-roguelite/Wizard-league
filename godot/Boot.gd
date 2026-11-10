# Boot — main scene script: loads the page, starts every game module in order.
extends Node

func _ready() -> void:
	randomize()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--driver="): localStorage.memory_only = true   # scripted runs never touch real saves
		if a.begins_with("--seed="): seed(a.substr(7).to_int())
	# high-DPI displays: scale the whole UI like a browser does (CSS pixels)
	var scale := DisplayServer.screen_get_scale()
	if scale <= 1.0 and OS.get_name() == "Windows": scale = clampf(roundf(DisplayServer.screen_get_dpi() / 96.0 * 4.0) / 4.0, 1.0, 3.0)
	if DisplayServer.get_name() != "headless":
		# a bigger window shows more of the page (as in a browser) instead of zooming it
		var win := get_window()
		win.content_scale_factor = maxf(scale, 1.0)
		win.content_scale_size = win.size
		win.size_changed.connect(func(): win.content_scale_size = win.size)
	InlineJS.setup(GameModules.GLOBALS)
	document.load_page("res://web/index.html", ["res://web/styles.css"])
	for m in GameModules.ORDER:
		var mod := get_node_or_null("/root/" + m)
		if mod != null: mod._boot()
	_version_label()
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
