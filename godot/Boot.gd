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
		var fit := func():
			win.content_scale_factor = maxf(android_scale(win.size) if OS.has_feature("android") else scale, 1.0)
			win.content_scale_size = win.size
		fit.call()
		win.size_changed.connect(fit)   # also fires when the phone rotates
	InlineJS.setup(GameModules.GLOBALS)
	document.load_page("res://web/index.html", ["res://web/styles.css"])
	for m in GameModules.ORDER:
		var mod := get_node_or_null("/root/" + m)
		if mod != null: mod._boot()
	_version_label()
	if OS.has_feature("android"):
		var up = load("res://android/Updater.gd").new()
		up.name = "Updater"
		add_child(up)
	for a in args:
		if a.begins_with("--driver="):
			var d = load("res://dev/Driver.gd").new()
			d.name = "Driver"
			d.script_path = a.substr(9)
			add_child(d)

# Phones report scale 1, so size the page from the screen density like a mobile browser (dpi/160),
# capped so the page keeps enough CSS pixels: about 400 across in portrait (a phone browser's
# width) and 480 tall in landscape, which the battle and menu screens need to fit.
static func android_scale(size: Vector2i) -> float:
	var css := 400.0 if size.y > size.x else 480.0
	return clampf(minf(DisplayServer.screen_get_dpi() / 160.0, mini(size.x, size.y) / css), 1.0, 4.0)

# small build stamp in the corner (index.html's inline script)
func _version_label() -> void:
	var v = Version.GAME_VERSION
	if not (v is Dictionary) or not JS.t(v.get("hash")) or v.get("hash") == "dev": return
	var el: DomNode = document.createElement("div")
	el.style.cssText = "position:fixed;bottom:6px;left:8px;font-size:.5rem;color:#3a3028;font-family:monospace;pointer-events:none;z-index:9999;letter-spacing:.04em;"
	el.textContent = ("v" + JS.s(v.version) + "  " if JS.t(v.get("version")) else "") + JS.s(v.hash) + ("  " + JS.s(v.date) if JS.t(v.get("date")) else "")
	document.body.appendChild(el)
