# Driver — development helper: plays a scripted sequence of UI actions and screenshots.
# Usage: godot --path godot -- --driver=/path/to/steps.json
# Steps: {"wait": frames} {"click": "#css-selector"} {"shot": "/path.png"} {"call": "fnName", "args": []}
#        {"text": "#selector", "value": "abc"} {"dump": "#selector"} {"quit": true} {"clickxy": [x, y]}
extends Node

var script_path := ""
var steps: Array = []
var idx := 0
var wait := 0
var until_ms := 0.0
var perf_left := 0
var perf_acc := [0, 0, 0]
var _t_last := 0
var monkey_until := 0.0
var monkey_next := 0.0
var monkey_gap := 250.0
var monkey_clicks := 0
var _last_screen := ""
var _screens := {}
var shot_dir := ""
var _shot_at := 0.0
var _shot_name := ""
var _bot_out := ""

func _ready() -> void:
	var f := FileAccess.open(script_path, FileAccess.READ)
	if f == null:
		push_error("Driver: cannot open " + script_path)
		get_tree().quit(1)
		return
	steps = JSON.parse_string(f.get_as_text())

func _process(_dt: float) -> void:
	if perf_left > 0:
		var nowu := Time.get_ticks_usec()
		perf_acc[0] += nowu - _t_last
		perf_acc[1] += JS.perf_pump_usec
		perf_acc[2] += document.perf_flush_usec
		_t_last = nowu
		perf_left -= 1
		if perf_left == 0:
			var n: float = perf_acc[3]
			print("PERF frame=%.1fms (%.1f fps)  game=%.1fms  dom=%.1fms" % [perf_acc[0] / n / 1000.0, 1e6 * n / perf_acc[0], perf_acc[1] / n / 1000.0, perf_acc[2] / n / 1000.0])
		return
	if _bot_out != "":
		var bot := get_node("/root/Bot")
		if not bot._botDone and Engine.get_process_frames() % 120 != 0: return
		var f := FileAccess.open(_bot_out, FileAccess.WRITE)
		f.store_string("\n".join(PackedStringArray(bot._botLog)) + "\n")
		f.close()
		if not bot._botDone: return
		print("DRIVER: bot finished, ", bot._botLog.size(), " lines -> ", _bot_out)
		_bot_out = ""
	if monkey_until > 0.0:
		if JS.now() >= monkey_until:
			monkey_until = 0.0
			print("DRIVER: monkey made ", monkey_clicks, " clicks; screens visited: ", _screens)
		elif _shot_at > 0.0:
			if JS.now() >= _shot_at:
				_shot_at = 0.0
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(_shot_name)
			return
		elif JS.now() >= monkey_next:
			monkey_next = JS.now() + monkey_gap
			_monkey()
			return
		else: return
	if wait > 0:
		wait -= 1
		return
	if until_ms > 0.0:
		if JS.now() < until_ms: return
		until_ms = 0.0
	while idx < steps.size():
		var s: Dictionary = steps[idx]
		idx += 1
		if s.has("wait"):
			wait = int(s.wait)
			return
		if s.has("perf"):
			perf_left = int(s.perf)
			perf_acc = [0, 0, 0, float(s.perf)]
			_t_last = Time.get_ticks_usec()
			return
		if s.has("monkey"):
			monkey_until = JS.now() + float(s.monkey) * 1000.0
			monkey_gap = float(s.get("gap", 250))
			shot_dir = s.get("shots", "")
			return
		if s.has("bot"):
			get_node("/root/Bot").botStart(int(s.bot), int(s.get("battles", 3)))
			_bot_out = s.get("out", "")
			return
		if s.has("speed"):
			JS.sim_speed = int(s.speed)
			continue
		if s.has("ms"):
			until_ms = JS.now() + float(s.ms)
			return
		if s.has("click"):
			var el = document.querySelector(s.click)
			if el == null: print("DRIVER: no element for ", s.click)
			else:
				var r: Rect2 = document.client_rect(el)
				var p := r.position + r.size * 0.5
				document.pointer_moved(p, 0)
				document.pointer_down(p, 0)
				document.pointer_up(p, 0)
		elif s.has("clickxy"):
			var p2 := Vector2(s.clickxy[0], s.clickxy[1])
			document.pointer_moved(p2, 0)
			document.pointer_down(p2, 0)
			document.pointer_up(p2, 0)
		elif s.has("hover"):
			var el2 = document.querySelector(s.hover)
			if el2 != null:
				var r2: Rect2 = document.client_rect(el2)
				document.pointer_moved(r2.position + r2.size * 0.5, 0)
		elif s.has("text"):
			var el3 = document.querySelector(s.text)
			if el3 != null: el3.value = s.value
		elif s.has("call"):
			var f = InlineJS.global(s.call)
			if f is Callable: f.callv(s.get("args", []))
			else: print("DRIVER: no function ", s.call)
		elif s.has("print"):
			print("PRINT ", s.print, " => ", JSON.stringify(JS._plain(InlineJS.eval_expr(s.print))))
		elif s.has("js"):
			InlineJS.run(s.js, null, null)
		elif s.has("dump"):
			var el4 = document.querySelector(s.dump)
			print("DUMP ", s.dump, ": ", _dump(el4, 0, int(s.get("depth", 3))) if el4 != null else "null")
		elif s.has("font"):
			var el5 = document.querySelector(s.font)
			var f: Font = el5.st.font
			print("FONT ", s.font, " ls=", el5.st.ls, " fs=", el5.st.fs, " spacing=", f.spacing_glyph, " cs.ls=", el5.cs.get("letter-spacing"), " w=", f.get_string_size("ABCDE", HORIZONTAL_ALIGNMENT_LEFT, -1, 72).x, " frags=", el5.frags)
		elif s.has("shot"):
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.save_png(s.shot)
			print("DRIVER: saved ", s.shot)
		elif s.has("quit"):
			get_tree().quit()
			return
	get_tree().quit()

func _dump(n: DomNode, depth: int, maxd: int) -> String:
	var ind := "  ".repeat(depth)
	if n.nodeType == DomNode.TEXT: return ""
	var out := "\n%s<%s#%s.%s> %s [%d,%d %dx%d] %s" % [ind, n.tag, n._id, ".".join(PackedStringArray(n.classes)), n.st.get("display", "?"), n.lx, n.ly, n.lw, n.lh, n.textContent.substr(0, 40).replace("\n", " ") if depth >= maxd else ""]
	if depth < maxd:
		for c in n.childNodes: out += _dump(c, depth + 1, maxd)
	return out

# Random play: clicks a random visible, enabled, clickable element (avoiding quit / back buttons).
const AVOID := ["Quit", "Abandon", "Files", "Back", "Delete", "Sandbox", "Skip", "Rarity", "Library", "Log", "Stats", "Decks", "Reroll"]
func _monkey() -> void:
	document.ensure_layout()
	var cands := []
	_collect(document.root, cands)
	if cands.is_empty(): return
	# favour "end turn" occasionally so battles progress
	var pick: DomNode = cands[randi() % cands.size()]
	var r: Rect2 = document.client_rect(pick)
	var p := r.position + r.size * 0.5
	if pick.tag == "canvas": p = r.position + Vector2(randf() * r.size.x, randf() * r.size.y)
	monkey_clicks += 1
	var hub = document.getElementById("hub-name-input")
	if hub != null and hub.value == "": hub.value = "Monkey"
	var scr = document.querySelector(".screen.active")
	var sid: String = scr._id if scr != null else "?"
	if sid != _last_screen:
		_last_screen = sid
		_screens[sid] = _screens.get(sid, 0) + 1
		if shot_dir != "" and _screens[sid] <= 2: _shot_at = JS.now() + 700.0; _shot_name = "%s/m_%s_%d.png" % [shot_dir, sid, _screens[sid]]
		if _screens[sid] <= 3: print("DRIVER: screen -> ", sid, "  battle=", InlineJS.global("battleNumber"))
	document.pointer_moved(p, 0)
	document.pointer_down(p, 0)
	document.pointer_up(p, 0)

func _collect(n: DomNode, out: Array) -> void:
	if n.nodeType != DomNode.ELEMENT or n.st.get("display", "none") == "none": return
	if (n._on.has("onclick") or n._listeners.has("click") or n._listeners.has("pointerdown") or n._listeners.has("pointerup")) and not n._disabled and n.lw > 2 and n.lh > 2:
		var txt: String = n.textContent
		if txt.length() > 40: txt = ""
		var bad: bool = n.classes.has("save-slot-delete")
		for a in AVOID:
			if txt.contains(a): bad = true
		if not bad and n.tag != "body" and not n.classes.has("screen"):
			var r: Rect2 = document.client_rect(n)
			var c := r.position + r.size * 0.5
			if c.x >= 0 and c.y >= 0 and c.x < document.viewport_size.x and c.y < document.viewport_size.y:
				var hit: DomNode = document.element_at(c)
				if hit != null and (hit == n or n.contains(hit)): out.append(n)
	for ch in n.childNodes: _collect(ch, out)
