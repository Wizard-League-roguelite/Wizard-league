# Cutscene — generated from js/rendering/cutscene.js by tools/js2gd.js
extends Node

var _onComplete = null
var _canvas = null
var _ctx = null
var _raf = null
var _startTime = 0
var _particles = null
var _done = false
var _shootingStars = null
var T = null
var NAR = null
var RUNES = null
var EL_COLORS = null

func _boot():
	# ===== cutscene.js =====
	# Opening cinematic — plays on first run only. Click or any key to skip.
	_particles = []
	_shootingStars = []
	# ── Timeline (ms) ────────────────────────────────────────────────────────────
	T = {
		"woodsEnd": 14000,
		"portalEnd": 26000,
		"reflectEnd": 31600,
		"fallEnd": 36000,
		"lobbyEnd": 49000,
		"staffEnd": 55600,
		"titleEnd": 63000,
		"panEnd": 71000,
	}
	# ── Narration script ─────────────────────────────────────────────────────────
	# Each entry: { t0, t1, text } — t0/t1 are fractions of the scene duration.
	NAR = {
		"woods": [
			{
				"t0": 0.05,
				"t1": 0.34,
				"text": "The Wizard League.  A cutthroat world where magic belongs to those who earn it.",
			},
			{
				"t0": 0.42,
				"t1": 0.68,
				"text": "A young wizard walked the Mirewood alone.  He had come for something ordinary.",
			},
			{"t0": 0.76, "t1": 0.96, "text": "A new staff.  That was all he wanted."},
		],
		"portal": [
			{"t0": 0.08, "t1": 0.44, "text": "But at the edge of the forest, half-buried in roots, he found a doorway."},
			{
				"t0": 0.54,
				"t1": 0.9,
				"text": "Stone.  Ancient.  Carved with runes that hummed in a language no living wizard knew.",
			},
		],
		"reflect": [
			{"t0": 0.1, "t1": 0.48, "text": "In the glow, he saw his own face."},
			{"t0": 0.56, "t1": 0.88, "text": "Something on the other side was already waiting for him."},
		],
		"fall": [{"t0": 0.22, "t1": 0.78, "text": "He stepped through."}],
		"lobby": [
			{"t0": 0.08, "t1": 0.42, "text": "He woke somewhere that should not exist."},
			{
				"t0": 0.52,
				"t1": 0.92,
				"text": "The Veil.  A world sealed in a loop.  A tournament with no end, run by someone who preferred it that way.",
			},
		],
		"staff": [
			{"t0": 0.1, "t1": 0.48, "text": "There was no door back.  No trace of how he had arrived."},
			{
				"t0": 0.58,
				"t1": 0.92,
				"text": "Only a staff on the ground.  And a game he had not chosen — but would not lose.",
			},
		],
		"title": [{"t0": 0.22, "t1": 0.78, "text": "This is where his story begins."}],
		"panDown": [
			{"t0": 0.12, "t1": 0.55, "text": "Welcome to The Veil."},
			{"t0": 0.62, "t1": 0.9, "text": "You are already inside."},
		],
	}
	# ── Stone-arch Veil portal (matches _drawBuildingVeil art style) ─────────────
	# cx/cy = centre base of arch. span = full width. height = full arch height.
	RUNES = ["ᚠ", "ᚢ", "ᚦ", "ᚨ", "ᚱ", "ᚲ", "ᚷ", "ᚹ", "ᚾ", "ᛁ", "ᛃ", "ᛇ", "ᛈ", "ᛉ", "ᛊ", "ᛏ"]
	# ── Shared lobby sky (reused in lobby + pan scenes) ──────────────────────────
	EL_COLORS = [
		[255, 55, 0],
		[0, 105, 255],
		[105, 205, 255],
		[115, 75, 28],
		[38, 175, 58],
		[255, 225, 0],
		[155, 55, 255],
		[175, 220, 255],
	]

func W():
	return _canvas.width

func H():
	return _canvas.height

func clamp_(v = null, a = null, b = null):
	return max(a, min(b, v))

func lerp_(a = null, b = null, t = null):
	return a + ((b - a) * clamp_(t, 0, 1))

func easeOut(t = null):
	t = clamp_(t, 0, 1)
	return 1 - ((1 - t) * (1 - t))

func easeInOut(t = null):
	t = clamp_(t, 0, 1)
	return ((2 * t) * t if t < 0.5 else (-1) + ((4 - (2 * t)) * t))

# fade: 0→1 over [0,inDur], hold 1, 1→0 over [outStart,1]
func fadeCurve(t = null, inDur = null, outStart = null):
	if t < inDur:
		return t / float(inDur)
	if t > outStart:
		return 1 - ((t - outStart) / float(1 - outStart))
	return 1

func drawNarration(lines = null, t = null):
	var text = ""
	for l in JS.iter(lines):
		if (t >= l.t0 and t <= l.t1):
			var mid = (l.t0 + l.t1) * 0.5
			var fade = (clamp_((t - l.t0) / 0.06, 0, 1) if t < mid else clamp_((l.t1 - t) / 0.06, 0, 1))
			text = l.text
			# bar
			var barH = H() * 0.115
			var barGrd = _ctx.createLinearGradient(0, H() - (barH * 1.6), 0, H())
			barGrd.addColorStop(0, "rgba(0,0,0,0)")
			barGrd.addColorStop(0.35, "rgba(0,0,0,0.72)")
			barGrd.addColorStop(1, "rgba(0,0,0,0.92)")
			_ctx.fillStyle = barGrd
			_ctx.fillRect(0, H() - (barH * 1.6), W(), barH * 1.6)
			_ctx.save()
			_ctx.globalAlpha = fade
			_ctx.font = "italic " + JS.s(clamp_(H() * 0.027, 11, 22)) + "px 'Cinzel',serif"
			_ctx.textAlign = "center"
			_ctx.textBaseline = "alphabetic"
			_ctx.shadowColor = "rgba(0,0,0,0.9)"
			_ctx.shadowBlur = 8
			_ctx.fillStyle = "#c8b890"
			_ctx.fillText(text, W() * 0.5, H() * 0.96)
			_ctx.restore()
			break

# Thin cinematic letterbox bars (top+bottom)
func drawBars(alpha = null):
	var bh = H() * 0.075
	_ctx.save()
	_ctx.globalAlpha = alpha
	_ctx.fillStyle = "#000"
	_ctx.fillRect(0, 0, W(), bh)
	_ctx.fillRect(0, H() - bh, W(), bh)
	_ctx.restore()

# ── Particles ────────────────────────────────────────────────────────────────
func spawnP(x = null, y = null, o = null):
	_particles.append({
		"x": x,
		"y": y,
		"vx": (o.vx if o.get("vx") != null else (randf() - 0.5) * 2),
		"vy": (o.vy if o.get("vy") != null else (-randf()) * 1.5),
		"life": 1,
		"decay": JS.or_(o.get("decay"), 0.011),
		"size": (o.get("size") if JS.t(o.get("size")) else (randf() * 2) + 1),
		"r": JS.or_(o.get("r"), 160),
		"g": JS.or_(o.get("g"), 80),
		"b": JS.or_(o.get("b"), 255),
	})

func tickP():
	_particles = JS.arr(_particles).filter(func(p = null): return p.life > 0)
	for p in JS.iter(_particles):
		p.x += p.vx
		p.y += p.vy
		p.life -= p.decay
		_ctx.save()
		_ctx.globalAlpha = p.life * 0.8
		_ctx.fillStyle = "rgb(" + JS.s(p.r) + "," + JS.s(p.g) + "," + JS.s(p.b) + ")"
		_ctx.beginPath()
		_ctx.arc(p.x, p.y, p.size, 0, PI * 2)
		_ctx.fill()
		_ctx.restore()

# ── Shooting stars ───────────────────────────────────────────────────────────
func maybeSpawnStar(sec = null):
	if (len(_shootingStars) < 3 and randf() < 0.004):
		_shootingStars.append({
			"x": randf() * W(),
			"y": (randf() * H()) * 0.35,
			"vx": lerp_(-6, -2, randf()),
			"vy": lerp_(1, 3, randf()),
			"life": 1,
			"len": lerp_(60, 140, randf()),
		})
	_shootingStars = JS.arr(_shootingStars).filter(func(s = null): return s.life > 0)
	for s in JS.iter(_shootingStars):
		s.x += s.vx
		s.y += s.vy
		s.life -= 0.016
		_ctx.save()
		_ctx.globalAlpha = s.life * 0.8
		var grd = _ctx.createLinearGradient(s.x, s.y, s.x - ((s.vx * s.len) / float(JS.hypot([s.vx, s.vy]))), s.y - ((s.vy * s.len) / float(JS.hypot([s.vx, s.vy]))))
		grd.addColorStop(0, "rgba(220,210,255,0.9)")
		grd.addColorStop(1, "rgba(200,180,255,0)")
		_ctx.strokeStyle = grd
		_ctx.lineWidth = 1.5
		_ctx.beginPath()
		_ctx.moveTo(s.x, s.y)
		_ctx.lineTo(s.x - (s.vx * 8), s.y - (s.vy * 8))
		_ctx.stroke()
		_ctx.restore()

# ── Stars background ─────────────────────────────────────────────────────────
func drawStars(sec = null, maxY = null, alpha = null):
	_ctx.save()
	_ctx.globalAlpha = alpha
	for i in range(60):
		var sx = JS.mod((i * 197.3) + 31, W())
		var sy = JS.mod((i * 113.9) + 17, (maxY if JS.t(maxY) else H() * 0.6))
		_ctx.globalAlpha = alpha * (0.28 + (0.24 * sin((sec * 0.88) + (i * 1.2))))
		_ctx.fillStyle = "rgb(205,190,225)"
		_ctx.fillRect(sx, sy, 1.5, 1.5)
	_ctx.restore()

# ── Wizard silhouette ────────────────────────────────────────────────────────
# Matches SPRITE_CHAR_MAGE: staff far-left full-height, tall pointed hat (≈50%
# of total height), beard, wide flowing robe, two separate boots.
func drawWizard(cx = null, cy = null, s = null, hasStaff = null, litLeft = null):
	var ctx = _ctx
	var d = (18 if JS.t(litLeft) else 4)
	ctx.fillStyle = "rgb(" + JS.s(d) + "," + JS.s(d - 1) + "," + JS.s(d + 4) + ")"
	var bx = cx + (2 * s)
	# body centre (offset right to leave room for staff)
	if JS.t(hasStaff):
		ctx.fillRect(cx - (22 * s), cy - (100 * s), 3 * s, 100 * s)
	# Hat (tip 100%, brim 52%)
	ctx.beginPath()
	ctx.moveTo(bx - (1 * s), cy - (100 * s))
	ctx.lineTo(bx - (14 * s), cy - (52 * s))
	ctx.lineTo(bx + (13 * s), cy - (52 * s))
	ctx.closePath()
	ctx.fill()
	ctx.fillRect(bx - (18 * s), cy - (54 * s), 33 * s, 4 * s)
	# brim ledge
	# Head
	ctx.beginPath()
	ctx.arc(bx, cy - (44 * s), 9 * s, 0, PI * 2)
	ctx.fill()
	# Beard
	ctx.beginPath()
	ctx.moveTo(bx - (8 * s), cy - (38 * s))
	ctx.lineTo(bx - (11 * s), cy - (30 * s))
	ctx.lineTo(bx + (11 * s), cy - (30 * s))
	ctx.lineTo(bx + (8 * s), cy - (38 * s))
	ctx.closePath()
	ctx.fill()
	# Robe
	ctx.beginPath()
	ctx.moveTo(bx - (8 * s), cy - (32 * s))
	ctx.lineTo(cx - (20 * s), cy - (14 * s))
	ctx.lineTo(cx - (15 * s), cy)
	ctx.lineTo(cx + (17 * s), cy)
	ctx.lineTo(bx + (22 * s), cy - (14 * s))
	ctx.lineTo(bx + (10 * s), cy - (32 * s))
	ctx.closePath()
	ctx.fill()
	# Boots
	ctx.fillRect(cx - (14 * s), cy - (3 * s), 11 * s, 4 * s)
	ctx.fillRect(cx + (5 * s), cy - (3 * s), 11 * s, 4 * s)
	# Staff tip glow
	if JS.t(hasStaff):
		var grd = ctx.createRadialGradient(cx - (21 * s), cy - (102 * s), 0, cx - (21 * s), cy - (102 * s), 11 * s)
		grd.addColorStop(0, "rgba(200,140,255,.9)")
		grd.addColorStop(1, "rgba(100,50,200,0)")
		ctx.fillStyle = grd
		ctx.fillRect(cx - (32 * s), cy - (113 * s), 22 * s, 22 * s)

# ── Pine tree ────────────────────────────────────────────────────────────────
func drawTree(cx = null, groundY = null, h = null, shade = null):
	var c = shade
	_ctx.fillStyle = "rgb(" + JS.s(c) + "," + JS.s(c) + "," + JS.s(min(255, c + 3)) + ")"
	_ctx.fillRect(cx - (h * 0.055), groundY - (h * 0.16), h * 0.11, h * 0.16)
	# trunk
	for _e1 in JS.iter([[0.46, 0.13, 0.38], [0.32, 0.36, 0.62], [0.17, 0.63, 1]]):
		var hw = JS.idx(_e1, 0)
		var bot = JS.idx(_e1, 1)
		var top = JS.idx(_e1, 2)
		_ctx.beginPath()
		_ctx.moveTo(cx, groundY - (h * top))
		_ctx.lineTo(cx - (h * hw), groundY - (h * bot))
		_ctx.lineTo(cx + (h * hw), groundY - (h * bot))
		_ctx.closePath()
		_ctx.fill()

func drawVeilPortal(cx = null, cy = null, span = null, height = null, sec = null, intensity = null):
	var ctx = _ctx
	var pilW = span * 0.18
	# pillar width
	var pilH = height * 0.78
	# pillar height
	var archR = (span - pilW) * 0.5
	# radius of the arch semicircle
	var archCY = cy - pilH
	# centre Y of the arch semicircle
	var lx = cx - (span * 0.5)
	# left pillar x
	var rx = (cx + (span * 0.5)) - pilW
	# right pillar x
	# ── Ambient halo ──
	var halo = ctx.createRadialGradient(cx, archCY, archR * 0.1, cx, archCY, span * 1.1)
	halo.addColorStop(0, "rgba(100,28,210," + JS.s(0.38 * intensity) + ")")
	halo.addColorStop(0.55, "rgba(55,10,140," + JS.s(0.16 * intensity) + ")")
	halo.addColorStop(1, "rgba(0,0,0,0)")
	ctx.fillStyle = halo
	ctx.fillRect(cx - (span * 1.1), archCY - (span * 1.1), span * 2.2, span * 2.2)
	# ── Portal interior (clipped to arch opening) ──
	ctx.save()
	ctx.beginPath()
	ctx.arc(cx, archCY, archR - (pilW * 0.45), PI, 0, false)
	ctx.lineTo((cx + archR) - (pilW * 0.45), cy)
	ctx.lineTo((cx - archR) + (pilW * 0.45), cy)
	ctx.closePath()
	ctx.clip()
	var interior = ctx.createRadialGradient(cx, archCY, 0, cx, archCY, archR)
	interior.addColorStop(0, "rgba(240,190,255," + JS.s(0.97 * intensity) + ")")
	interior.addColorStop(0.25, "rgba(165,62,255," + JS.s(0.9 * intensity) + ")")
	interior.addColorStop(0.68, "rgba(72,14,180," + JS.s(0.8 * intensity) + ")")
	interior.addColorStop(1, "rgba(18,0,55," + JS.s(0.35 * intensity) + ")")
	ctx.fillStyle = interior
	ctx.fillRect(cx - span, archCY - span, span * 2, span * 2)
	# Mist wisps inside
	for i in range(4):
		var wx = cx + ((sin((sec * 0.028) + (i * 2)) * archR) * 0.32)
		var wy = (((archCY * 0.2) + (cy * 0.8)) - ((i * pilH) * 0.16)) + ((cos((sec * 0.022) + i) * pilH) * 0.07)
		var wr = archR * (0.22 + (0.1 * sin((sec * 0.04) + i)))
		var mg = ctx.createRadialGradient(wx, wy, 0, wx, wy, wr)
		mg.addColorStop(0, "rgba(160,70,255," + JS.s((0.28 + (0.12 * sin((sec * 0.05) + i))) * intensity) + ")")
		mg.addColorStop(1, "rgba(0,0,0,0)")
		ctx.fillStyle = mg
		ctx.fillRect(wx - wr, wy - wr, wr * 2, wr * 2)
	ctx.restore()
	# ── Stone pillars ──
	var stoneD = 10
	var stoneL = 22
	ctx.fillStyle = "#1a1020"
	ctx.strokeStyle = "#2e1a42"
	ctx.lineWidth = 1
	# Left pillar
	ctx.fillRect(lx, cy - pilH, pilW, pilH)
	ctx.strokeRect(lx, cy - pilH, pilW, pilH)
	# Right pillar
	ctx.fillRect(rx, cy - pilH, pilW, pilH)
	ctx.strokeRect(rx, cy - pilH, pilW, pilH)
	# Mortar lines (simulate stone blocks)
	ctx.strokeStyle = "#251630"
	ctx.lineWidth = 0.8
	var y = cy - pilH
	while y < cy:
		ctx.beginPath()
		ctx.moveTo(lx, y)
		ctx.lineTo(lx + pilW, y)
		ctx.stroke()
		ctx.beginPath()
		ctx.moveTo(rx, y)
		ctx.lineTo(rx + pilW, y)
		ctx.stroke()
		y += stoneD
	# ── Stone arch ring ──
	ctx.strokeStyle = "#2e1a42"
	ctx.lineWidth = pilW
	ctx.fillStyle = "#1a1020"
	ctx.beginPath()
	ctx.arc(cx, archCY, archR, PI, 0)
	ctx.stroke()
	ctx.beginPath()
	ctx.arc(cx, archCY, archR, PI, 0)
	ctx.lineTo(cx + archR, cy - pilH)
	ctx.lineTo(cx - archR, cy - pilH)
	ctx.closePath()
	ctx.fill()
	# Arch outer ring highlight
	ctx.save()
	ctx.shadowColor = "#7030c0"
	ctx.shadowBlur = 12
	ctx.strokeStyle = "rgba(70,28,130," + JS.s(0.9 * intensity) + ")"
	ctx.lineWidth = 1.5
	ctx.beginPath()
	ctx.arc(cx, archCY, archR + (pilW * 0.44), PI, 0)
	ctx.stroke()
	ctx.beginPath()
	ctx.arc(cx, archCY, archR - (pilW * 0.44), PI, 0)
	ctx.stroke()
	ctx.restore()
	# ── Runes carved along the arch face ──
	var numR = 10
	ctx.font = JS.s(max(9, span * 0.068)) + "px serif"
	ctx.textAlign = "center"
	ctx.textBaseline = "middle"
	for i in range(ceili(numR)):
		var ang = PI * (i / float(numR - 1))
		# left(π) → top(π/2) → right(0)
		var runeR = archR
		# on the stone face
		var rx2 = cx - (cos(ang) * runeR)
		var ry2 = archCY - (sin(ang) * runeR)
		ctx.save()
		ctx.translate(rx2, ry2)
		ctx.rotate((-ang) + (PI * 0.5))
		ctx.globalAlpha = (0.55 + (sin((sec * 1.8) + i) * 0.18)) * intensity
		ctx.fillStyle = "#c8a0ee"
		ctx.fillText(JS.idx(RUNES, JS.mod(i, len(RUNES))), 0, 0)
		ctx.restore()
	# ── Keystone gem at arch top ──
	var gemR = span * 0.055
	ctx.beginPath()
	ctx.arc(cx, archCY - archR, gemR, 0, PI * 2)
	ctx.fillStyle = "rgba(185,85,255," + JS.s((0.7 + (0.25 * sin(sec * 2.5))) * intensity) + ")"
	ctx.fill()
	ctx.save()
	ctx.shadowColor = "#e0b0ff"
	ctx.shadowBlur = 18
	ctx.strokeStyle = "rgba(220,170,255," + JS.s(intensity) + ")"
	ctx.lineWidth = 1.5
	ctx.stroke()
	ctx.restore()

# ── Castle ───────────────────────────────────────────────────────────────────
func drawCastle(cx = null, cy = null, s = null):
	var ctx = _ctx
	ctx.fillStyle = "rgb(5,3,12)"
	ctx.fillRect(cx - (92 * s), cy - (62 * s), 184 * s, 62 * s)
	ctx.fillRect(cx - (122 * s), cy - (42 * s), 42 * s, 42 * s)
	ctx.fillRect(cx + (80 * s), cy - (42 * s), 42 * s, 42 * s)
	ctx.fillRect(cx - (104 * s), cy - (108 * s), 32 * s, 68 * s)
	ctx.fillRect(cx + (72 * s), cy - (108 * s), 32 * s, 68 * s)
	ctx.fillRect(cx - (24 * s), cy - (82 * s), 48 * s, 82 * s)
	ctx.beginPath()
	ctx.moveTo(cx - (22 * s), cy - (82 * s))
	ctx.lineTo(cx, cy - (158 * s))
	ctx.lineTo(cx + (22 * s), cy - (82 * s))
	ctx.fill()
	for _e2 in JS.iter([[cx - (88 * s), cy - (108 * s)], [cx + (88 * s), cy - (108 * s)]]):
		var tx = JS.idx(_e2, 0)
		var ty = JS.idx(_e2, 1)
		ctx.beginPath()
		ctx.moveTo(tx - (16 * s), ty)
		ctx.lineTo(tx, ty - (38 * s))
		ctx.lineTo(tx + (16 * s), ty)
		ctx.fill()
	for i in range(8):
		ctx.fillRect((cx - (88 * s)) + ((i * 24) * s), cy - (72 * s), 13 * s, 12 * s)

func drawLobbySky(sec = null, elAlpha = null, offsetY = null):
	offsetY = [offsetY]
	offsetY[0] = JS.or_(offsetY[0], 0)
	var ctx = _ctx
	var sky = ctx.createLinearGradient(0, offsetY[0], 0, H() + offsetY[0])
	sky.addColorStop(0, "#0e0420")
	sky.addColorStop(0.65, "#1a0735")
	sky.addColorStop(1, "#090320")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W(), H())
	drawStars(sec, H() * 0.58, 1)
	maybeSpawnStar(sec)
	var _arr4 = JS.iter(EL_COLORS)
	for i in range(len(_arr4)):
		var _e3 = _arr4[i]
		var r = JS.idx(_e3, 0)
		var g = JS.idx(_e3, 1)
		var b = JS.idx(_e3, 2)
		var ex = W() * ((i + 0.5) / 8.0)
		var ey = (H() * 0.63) + offsetY[0]
		var grd = ctx.createRadialGradient(ex, ey, 0, ex, ey, H() * 0.32)
		var a = (JS.or_(elAlpha, 1)) * (0.16 + (0.05 * sin((sec * 0.55) + i)))
		grd.addColorStop(0, "rgba(" + JS.s(r) + "," + JS.s(g) + "," + JS.s(b) + "," + JS.s(a) + ")")
		grd.addColorStop(1, "rgba(0,0,0,0)")
		ctx.fillStyle = grd
		ctx.fillRect(0, 0, W(), H())
	var ground = ctx.createLinearGradient(0, (H() * 0.62) + offsetY[0], 0, H() + offsetY[0])
	ground.addColorStop(0, "rgba(35,12,75,0)")
	ground.addColorStop(1, "rgba(22,6,52,.92)")
	ctx.fillStyle = ground
	ctx.fillRect(0, H() * 0.62, W(), H() * 0.38)

# ═══════════════════════════════════════════════════════════════════════════
# SCENES
# ═══════════════════════════════════════════════════════════════════════════
# ── Scene 1: Dark Woods ──────────────────────────────────────────────────────
func sceneWoods(t = null, sec = null):
	# Sky
	var sky = _ctx.createLinearGradient(0, 0, 0, H())
	sky.addColorStop(0, "#030208")
	sky.addColorStop(0.6, "#060412")
	sky.addColorStop(1, "#0a0618")
	_ctx.fillStyle = sky
	_ctx.fillRect(0, 0, W(), H())
	# Moon
	var mx = W() * 0.78
	var my = H() * 0.16
	var mr = H() * 0.052
	var mGlow = _ctx.createRadialGradient(mx, my, 0, mx, my, mr * 4.5)
	mGlow.addColorStop(0, "rgba(175,165,215,.20)")
	mGlow.addColorStop(1, "rgba(0,0,0,0)")
	_ctx.fillStyle = mGlow
	_ctx.fillRect(mx - (mr * 4.5), my - (mr * 4.5), mr * 9, mr * 9)
	_ctx.fillStyle = "rgb(182,175,208)"
	_ctx.beginPath()
	_ctx.arc(mx, my, mr, 0, PI * 2)
	_ctx.fill()
	drawStars(sec, H() * 0.6, 1)
	var gY = H() * 0.78
	# Tree layers (far→near)
	for i in range(11):
		drawTree(W() * (i / 10.0), gY - (H() * 0.04), H() * 0.21, 12)
	for i in range(9):
		drawTree(W() * ((i / 8.0) - 0.03), gY, H() * 0.3, 8)
	for fx in JS.iter([0, 0.14, 0.42, 0.62, 0.8, 0.96]):
		drawTree(W() * fx, gY + (H() * 0.04), H() * 0.42, 5)
	for fx in JS.iter([0, 0.12, 0.78, 0.92, 1.04]):
		drawTree(W() * fx, H(), H() * 0.6, 3)
	# Ground + path
	_ctx.fillStyle = "rgb(5,4,9)"
	_ctx.fillRect(0, gY + (H() * 0.04), W(), H())
	var path = _ctx.createLinearGradient(W() * 0.28, 0, W() * 0.58, 0)
	path.addColorStop(0, "rgba(0,0,0,0)")
	path.addColorStop(0.2, "rgba(22,16,10,.65)")
	path.addColorStop(0.8, "rgba(22,16,10,.65)")
	path.addColorStop(1, "rgba(0,0,0,0)")
	_ctx.fillStyle = path
	_ctx.fillRect(0, gY + (H() * 0.04), W(), H())
	var mist = _ctx.createLinearGradient(0, gY - (H() * 0.06), 0, gY + (H() * 0.12))
	mist.addColorStop(0, "rgba(20,10,40,0)")
	mist.addColorStop(1, "rgba(20,10,40,.75)")
	_ctx.fillStyle = mist
	_ctx.fillRect(0, gY - (H() * 0.06), W(), H() * 0.18)
	# Moonray
	var ray = _ctx.createLinearGradient(mx, my + mr, mx * 0.65, gY)
	ray.addColorStop(0, "rgba(178,165,228,.05)")
	ray.addColorStop(1, "rgba(178,165,228,0)")
	_ctx.fillStyle = ray
	_ctx.beginPath()
	_ctx.moveTo(mx - (mr * 0.4), my + mr)
	_ctx.lineTo(mx * 0.28, gY)
	_ctx.lineTo(mx * 0.92, gY)
	_ctx.lineTo(mx + (mr * 0.4), my + mr)
	_ctx.closePath()
	_ctx.fill()
	# Wizard walks in, bobs
	var walkT = easeInOut(clamp_(t / 0.82, 0, 1))
	var charX = lerp_(-30, W() * 0.44, walkT)
	var bob = (sin(sec * 3.8) * 3) * max(0, 1 - (t * 2))
	drawWizard(charX, (gY + (H() * 0.055)) + bob, H() / 640.0, false, false)
	# Dust motes
	if randf() < 0.22:
		spawnP(randf() * W(), gY - ((randf() * H()) * 0.25), {"vx": (randf() - 0.5) * 0.4, "vy": -0.2, "decay": 0.004, "size": 1.4, "r": 130, "g": 90, "b": 200})
	tickP()
	drawBars(1)
	drawNarration(NAR.woods, t)
	var ov = 1 - fadeCurve(t, 0.1, 0.88)
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 2: Portal (Stone Arch Veil) ───────────────────────────────────────
func scenePortal(t = null, sec = null):
	var sky = _ctx.createLinearGradient(0, 0, 0, H())
	sky.addColorStop(0, "#030108")
	sky.addColorStop(1, "#070514")
	_ctx.fillStyle = sky
	_ctx.fillRect(0, 0, W(), H())
	drawStars(sec, H() * 0.55, 0.7)
	var gY = H() * 0.8
	for i in range(9):
		drawTree(W() * (i / 8.0), gY, H() * 0.28, 8)
	for fx in JS.iter([0, 0.1, 0.8, 0.92, 1.04]):
		drawTree(W() * fx, H(), H() * 0.6, 3)
	_ctx.fillStyle = "rgb(4,3,8)"
	_ctx.fillRect(0, gY, W(), H() - gY)
	var mist = _ctx.createLinearGradient(0, gY - (H() * 0.05), 0, gY + (H() * 0.1))
	mist.addColorStop(0, "rgba(20,8,45,0)")
	mist.addColorStop(1, "rgba(20,8,45,.80)")
	_ctx.fillStyle = mist
	_ctx.fillRect(0, gY - (H() * 0.05), W(), H() * 0.15)
	# Portal grows in
	var zoom = lerp_(0.55, 1.0, easeOut(t))
	var pulse = 1 + (sin(sec * 2.4) * 0.03)
	var span = ((H() * 0.55) * zoom) * pulse
	var pH = ((H() * 0.62) * zoom) * pulse
	drawVeilPortal(W() * 0.56, gY, span, pH, sec, min(1, t * 2.2))
	# Wizard watches
	_ctx.save()
	_ctx.globalAlpha = min(1, t * 3)
	drawWizard(W() * 0.2, gY + (H() * 0.055), H() / 640.0, false, true)
	_ctx.restore()
	tickP()
	drawBars(1)
	drawNarration(NAR.portal, t)
	var ov = 1 - fadeCurve(t, 0.08, 0.88)
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 3: Face Reflection ─────────────────────────────────────────────────
func sceneReflect(t = null, sec = null):
	_ctx.fillStyle = "rgb(3,2,7)"
	_ctx.fillRect(0, 0, W(), H())
	var cx = W() * 0.5
	var cy = H() * 0.52
	var s = H() / 200.0
	_ctx.fillStyle = "rgb(5,4,11)"
	_ctx.beginPath()
	_ctx.moveTo(cx, cy - (140 * s))
	_ctx.lineTo(cx - (60 * s), cy - (60 * s))
	_ctx.lineTo(cx + (58 * s), cy - (60 * s))
	_ctx.closePath()
	_ctx.fill()
	_ctx.fillRect(cx - (70 * s), cy - (64 * s), 132 * s, 7 * s)
	_ctx.beginPath()
	_ctx.arc(cx + (3 * s), cy - (50 * s), 36 * s, 0, PI * 2)
	_ctx.fill()
	_ctx.fillRect(cx - (40 * s), cy - (24 * s), 84 * s, 40 * s)
	_ctx.fillRect(cx - (130 * s), cy + (12 * s), 280 * s, 80 * s)
	var fl = (0.72 + (sin(sec * 4.8) * 0.09)) + (sin(sec * 7.1) * 0.04)
	var faceL = _ctx.createRadialGradient(cx + 85, cy - 40, 0, cx + 85, cy - 40, 230)
	faceL.addColorStop(0, "rgba(140,62,255," + JS.s(0.58 * fl) + ")")
	faceL.addColorStop(1, "rgba(0,0,0,0)")
	_ctx.fillStyle = faceL
	_ctx.fillRect(0, 0, W(), H())
	if t > 0.35:
		var ra = clamp_((t - 0.35) / 0.22, 0, 1)
		_ctx.save()
		_ctx.globalAlpha = ra * 0.7
		_ctx.font = JS.s(H() * 0.072) + "px serif"
		_ctx.fillStyle = "#cc99ff"
		_ctx.textAlign = "center"
		_ctx.textBaseline = "middle"
		var _arr5 = JS.iter(JS.slice(RUNES, 0, 6))
		for i in range(len(_arr5)):
			var r = _arr5[i]
			var a = (sec * 0.54) + (i * (PI / 3.0))
			_ctx.fillText(r, cx + ((cos(a) * H()) * 0.26), cy + ((sin(a) * H()) * 0.2))
		_ctx.restore()
	drawBars(1)
	drawNarration(NAR.reflect, t)
	var ov = 1 - fadeCurve(t, 0.18, 0.78)
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 4: The Fall ────────────────────────────────────────────────────────
func sceneFall(t = null, sec = null):
	var fA = (1 if t < 0.15 else max(0, 1 - ((t - 0.15) / 0.28)))
	_ctx.fillStyle = "rgba(165,85,255," + JS.s(fA) + ")"
	_ctx.fillRect(0, 0, W(), H())
	if (t > 0.1 and t < 0.88):
		_ctx.save()
		_ctx.globalAlpha = (clamp_((t - 0.1) / 0.14, 0, 1) * clamp_((0.88 - t) / 0.1, 0, 1)) * 0.65
		_ctx.font = JS.s(H() * 0.062) + "px serif"
		_ctx.fillStyle = "#eeddff"
		_ctx.textAlign = "center"
		_ctx.textBaseline = "middle"
		for i in range(12):
			var ang = (((i / 12.0) * PI) * 2) + (sec * 2.5)
			var d = lerp_(H() * 0.04, H() * 0.56, clamp_(t * 1.1, 0, 1))
			_ctx.fillText(JS.idx(RUNES, JS.mod(i + 4, len(RUNES))), (W() * 0.5) + (cos(ang) * d), (H() * 0.5) + ((sin(ang) * d) * 0.52))
		_ctx.restore()
	if (t > 0.12 and t < 0.82):
		var ft = (t - 0.12) / 0.7
		_ctx.save()
		_ctx.translate(W() * 0.5, H() * 0.5)
		_ctx.rotate(ft * 0.55)
		_ctx.globalAlpha = 1 - (ft * 0.85)
		drawWizard(0, 0, lerp_(H() / 640.0, H() / 1200.0, ft), false, false)
		_ctx.restore()
	if (t < 0.45 and randf() < 0.55):
		var a = (randf() * PI) * 2
		var sp = 3 + (randf() * 5)
		spawnP(W() * 0.5, H() * 0.5, {"vx": cos(a) * sp, "vy": sin(a) * sp, "decay": 0.022, "size": 2.8, "r": 215, "g": 145, "b": 255})
	tickP()
	drawBars(1)
	drawNarration(NAR.fall, t)
	if t > 0.72:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s((t - 0.72) / 0.28) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 5: Lobby Reveal ────────────────────────────────────────────────────
func sceneLobby(t = null, sec = null):
	drawLobbySky(sec, min(1, t * 1.6), 0)
	_ctx.save()
	_ctx.globalAlpha = min(1, t * 1.3)
	drawCastle(W() * 0.5, H() * 0.65, 0.6)
	_ctx.restore()
	var landT = easeOut(clamp_(t * 1.55, 0, 1))
	var wS = H() / 640.0
	var charY = lerp_((-wS) * 110, (H() * 0.715) + (wS * 55), landT)
	_ctx.save()
	if landT < 1:
		_ctx.translate(W() * 0.5, charY)
		_ctx.rotate((1 - landT) * 0.4)
		_ctx.translate((-W()) * 0.5, -charY)
	drawWizard(W() * 0.5, charY, wS, false, false)
	_ctx.restore()
	if (t > 0.6 and t < 0.76):
		for i in range(2):
			spawnP((W() * 0.5) + ((randf() - 0.5) * 28), charY, {
				"vx": (randf() - 0.5) * 3.8,
				"vy": (-randf()) * 2.8,
				"decay": 0.025,
				"size": 2.8,
				"r": 130,
				"g": 75,
				"b": 195,
			})
	tickP()
	drawBars(1)
	drawNarration(NAR.lobby, t)
	var ov = 1 - fadeCurve(t, 0.07, 0.9)
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 6: Stand + Staff ───────────────────────────────────────────────────
func sceneStaff(t = null, sec = null):
	drawLobbySky(sec, 1, 0)
	_ctx.save()
	_ctx.globalAlpha = 0.88
	drawCastle(W() * 0.5, H() * 0.65, 0.6)
	_ctx.restore()
	var riseT = easeInOut(clamp_(t * 1.7, 0, 1))
	var wS = H() / 640.0
	var charY = lerp_((H() * 0.74) + (wS * 55), (H() * 0.715) + (wS * 55), riseT)
	var staffOn = t > 0.42
	drawWizard(W() * 0.5, charY, wS, staffOn, false)
	if (staffOn and randf() < 0.32):
		spawnP((W() * 0.5) - (22 * wS), charY - (102 * wS), {
			"vx": (randf() - 0.5) * 1.8,
			"vy": (-randf()) * 2.4,
			"decay": 0.022,
			"size": 2.1,
			"r": 205,
			"g": 140,
			"b": 255,
		})
	tickP()
	drawBars(1)
	drawNarration(NAR.staff, t)
	var ov = 1 - fadeCurve(t, 0.12, 0.8)
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 7: Title Card ───────────────────────────────────────────────────────
func sceneTitleCard(t = null):
	_ctx.fillStyle = "rgb(0,0,0)"
	_ctx.fillRect(0, 0, W(), H())
	var alpha = fadeCurve(t, 0.18, 0.72)
	_ctx.save()
	_ctx.globalAlpha = alpha
	var grd = _ctx.createRadialGradient(W() * 0.5, H() * 0.45, 0, W() * 0.5, H() * 0.45, W() * 0.42)
	grd.addColorStop(0, "rgba(80,28,150,.45)")
	grd.addColorStop(1, "rgba(0,0,0,0)")
	_ctx.fillStyle = grd
	_ctx.fillRect(0, 0, W(), H())
	_ctx.textAlign = "center"
	_ctx.textBaseline = "middle"
	var fs = clamp_(H() * 0.115, 28, 92)
	_ctx.font = "bold " + JS.s(fs) + "px 'Cinzel',serif"
	_ctx.shadowColor = "#c8a050"
	_ctx.shadowBlur = 42
	_ctx.fillStyle = "#e8c870"
	_ctx.fillText("WIZARD'S LEAGUE", W() * 0.5, H() * 0.43)
	_ctx.shadowBlur = 0
	_ctx.strokeStyle = "rgba(150,110,210,.40)"
	_ctx.lineWidth = 1
	_ctx.beginPath()
	_ctx.moveTo(W() * 0.33, H() * 0.535)
	_ctx.lineTo(W() * 0.67, H() * 0.535)
	_ctx.stroke()
	_ctx.font = JS.s(clamp_(H() * 0.038, 12, 30)) + "px 'Cinzel',serif"
	_ctx.fillStyle = "#6a5a90"
	_ctx.fillText("T H E   V E I L", W() * 0.5, H() * 0.595)
	_ctx.restore()
	drawBars(1)
	drawNarration(NAR.title, t)

# ── Scene 8: Pan Down into lobby ─────────────────────────────────────────────
# Camera slowly descends, revealing the ground / lobby world, then fades out.
func scenePanDown(t = null, sec = null):
	# Pan: shift all content upward so we "move down" into the world
	var panFrac = easeInOut(clamp_(t * 1.15, 0, 1))
	var panY = (panFrac * H()) * 0.42
	# how far down we've scrolled
	_ctx.save()
	_ctx.translate(0, -panY)
	# Extend the sky/ground downward so it fills the scrolled view
	drawLobbySky(sec, 1, panY)
	# Castle — remains at its world position
	drawCastle(W() * 0.5, H() * 0.65, 0.6)
	# Wizard standing with staff at world position
	var wS = H() / 640.0
	drawWizard(W() * 0.5, (H() * 0.715) + (wS * 55), wS, true, false)
	if randf() < 0.18:
		spawnP((W() * 0.5) - (22 * wS), ((H() * 0.715) + (wS * 55)) - (102 * wS), {"vx": (randf() - 0.5) * 1.5, "vy": (-randf()) * 2, "decay": 0.02, "size": 2, "r": 200, "g": 135, "b": 255})
	tickP()
	_ctx.restore()
	# un-translate so bars/fade are screen-aligned
	drawBars(1)
	drawNarration(NAR.panDown, t)
	# Fade out at the very end
	if t > 0.78:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s((t - 0.78) / 0.22) + ")"
		_ctx.fillRect(0, 0, W(), H())
	# Fade in from title
	if t < 0.12:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(1 - (t / 0.12)) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Main loop ────────────────────────────────────────────────────────────────
func tick(ts = null):
	if JS.t(_done):
		return
	var el = ts - _startTime
	var sec = el / 1000.0
	_ctx.clearRect(0, 0, W(), H())
	if el < T.woodsEnd:
		sceneWoods(el / float(T.woodsEnd), sec)
	elif el < T.portalEnd:
		scenePortal((el - T.woodsEnd) / float(T.portalEnd - T.woodsEnd), sec)
	elif el < T.reflectEnd:
		sceneReflect((el - T.portalEnd) / float(T.reflectEnd - T.portalEnd), sec)
	elif el < T.fallEnd:
		sceneFall((el - T.reflectEnd) / float(T.fallEnd - T.reflectEnd), sec)
	elif el < T.lobbyEnd:
		sceneLobby((el - T.fallEnd) / float(T.lobbyEnd - T.fallEnd), sec)
	elif el < T.staffEnd:
		sceneStaff((el - T.lobbyEnd) / float(T.staffEnd - T.lobbyEnd), sec)
	elif el < T.titleEnd:
		sceneTitleCard((el - T.staffEnd) / float(T.titleEnd - T.staffEnd))
	elif el < T.panEnd:
		scenePanDown((el - T.titleEnd) / float(T.panEnd - T.titleEnd), sec)
	else:
		endCutscene()
		return
	_raf = JS.requestAnimationFrame(tick)

func endCutscene():
	if JS.t(_done):
		return
	_done = true
	JS.cancelAnimationFrame(_raf)
	_particles = []
	_shootingStars = []
	var screen = document.getElementById("cutscene-screen")
	if JS.t(screen):
		screen.style.transition = "opacity 1s"
		screen.style.opacity = "0"
		var _fn6 = func():
			screen.style.display = "none"
			screen.style.opacity = "1"
			screen.style.transition = ""
			if JS.t(_onComplete):
				_onComplete.call()
		JS.setTimeout(_fn6, 1000)
	else:
		if JS.t(_onComplete):
			_onComplete.call()

func playCutscene(onComplete = null):
	_onComplete = onComplete
	_done = false
	_particles = []
	_shootingStars = []
	var screen = document.getElementById("cutscene-screen")
	if not JS.t(screen):
		if JS.t(onComplete):
			onComplete.call()
		return
	screen.style.display = "flex"
	screen.style.opacity = "1"
	screen.style.transition = ""
	_canvas = document.getElementById("cutscene-canvas")
	_canvas.width = window.innerWidth
	_canvas.height = window.innerHeight
	_ctx = _canvas.getContext("2d")
	screen.addEventListener("click", func(): return endCutscene(), {"once": true})
	document.addEventListener("keydown", func(): return endCutscene(), {"once": true})
	_startTime = JS.now()
	_raf = JS.requestAnimationFrame(tick)
