# CastleCutscene — generated from js/rendering/castle_cutscene.js by tools/js2gd.js
extends Node

var _onComplete = null
var _canvas = null
var _ctx = null
var _raf = null
var _startTime = 0
var _particles = null
var _done = false
var T = null
var NAR = null
var EL = null

func _boot():
	# ===== castle_cutscene.js =====
	# Throne room intro — plays on first run, chained after the opening cutscene.
	# Scenes: castle exterior → great hall → Dark One on throne →
	# pan across 8 elemental wizards → dispatch → our wizard ejected.
	# Click or any key to skip.
	_particles = []
	# ── Timeline (ms) ─────────────────────────────────────────────────────────
	T = {
		"exteriorEnd": 11000,
		"hallEnd": 22000,
		"throneEnd": 36000,
		"panEnd": 50000,
		"dispatchEnd": 59000,
		"ejectEnd": 70000,
		"totalEnd": 72500,
	}
	# ── Narration ──────────────────────────────────────────────────────────────
	NAR = {
		"exterior": [
			{
				"t0": 0.1,
				"t1": 0.46,
				"text": "He followed the crowd through the gates of the great castle at the heart of The Veil.",
			},
			{
				"t0": 0.56,
				"t1": 0.92,
				"text": "Everyone here was a competitor.  Not one of them remembered choosing to arrive.",
			},
		],
		"hall": [
			{
				"t0": 0.1,
				"t1": 0.44,
				"text": "Inside, the hall stretched into darkness.  Stone walls.  Cold torchlight.  Silence.",
			},
			{
				"t0": 0.54,
				"t1": 0.9,
				"text": "Row upon row of wizards, every element represented.  All of them waiting for the same thing.",
			},
		],
		"throne": [
			{
				"t0": 0.08,
				"t1": 0.36,
				"text": "At the far end, on a throne carved from shadow, sat the one who owned this world.",
			},
			{"t0": 0.44, "t1": 0.68, "text": "He had the look of a man who had never lost.  That was not luck."},
			{"t0": 0.76, "t1": 0.95, "text": "He built the loop.  He ran the tournament.  He kept both going by design."},
		],
		"pan": [
			{
				"t0": 0.08,
				"t1": 0.44,
				"text": "Eight elements.  Eight gatekeepers.  Eight chances to prove you belonged here.",
			},
			{"t0": 0.55, "t1": 0.9, "text": "They were not obstacles.  They were the whole point."},
		],
		"dispatch": [
			{"t0": 0.08, "t1": 0.44, "text": "The rules were announced once, without ceremony, without mercy."},
			{"t0": 0.54, "t1": 0.9, "text": "Return with three badges.  Only then may you stand before the throne."},
		],
		"eject": [
			{"t0": 0.08, "t1": 0.44, "text": "Our wizard had barely gotten a look at the place before he was removed."},
			{"t0": 0.54, "t1": 0.88, "text": "He had not yet earned his right to enter.  That was about to change."},
		],
	}
	# ── Element colors for wizard pan ─────────────────────────────────────────
	EL = [
		{"name": "Fire", "r": 255, "g": 55, "b": 0},
		{"name": "Ice", "r": 105, "g": 205, "b": 255},
		{"name": "Lightning", "r": 255, "g": 220, "b": 0},
		{"name": "Earth", "r": 115, "g": 75, "b": 28},
		{"name": "Water", "r": 0, "g": 105, "b": 255},
		{"name": "Nature", "r": 38, "g": 175, "b": 58},
		{"name": "Plasma", "r": 155, "g": 55, "b": 255},
		{"name": "Air", "r": 175, "g": 220, "b": 255},
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

func fadeCurve(t = null, inD = null, outS = null):
	if t < inD:
		return t / float(inD)
	if t > outS:
		return 1 - ((t - outS) / float((1 - outS)))
	return 1

func drawNarration(lines = null, t = null):
	for l in JS.iter(lines):
		if (t >= l.get("t0") and t <= l.get("t1")):
			var mid = (l.get("t0") + l.get("t1")) * 0.5
			var fade = (clamp_((t - l.get("t0")) / 0.06, 0, 1) if t < mid else clamp_((l.get("t1") - t) / 0.06, 0, 1))
			var barH = H() * 0.115
			var bg = _ctx.createLinearGradient(0, H() - (barH * 1.6), 0, H())
			bg.addColorStop(0, "rgba(0,0,0,0)")
			bg.addColorStop(0.35, "rgba(0,0,0,0.72)")
			bg.addColorStop(1, "rgba(0,0,0,0.92)")
			_ctx.fillStyle = bg
			_ctx.fillRect(0, H() - (barH * 1.6), W(), barH * 1.6)
			_ctx.save()
			_ctx.globalAlpha = fade
			_ctx.font = "italic " + JS.s(clamp_(H() * 0.027, 11, 22)) + "px 'Cinzel',serif"
			_ctx.textAlign = "center"
			_ctx.textBaseline = "alphabetic"
			_ctx.shadowColor = "rgba(0,0,0,0.9)"
			_ctx.shadowBlur = 8
			_ctx.fillStyle = "#c8b890"
			_ctx.fillText(l.get("text"), W() * 0.5, H() * 0.96)
			_ctx.restore()
			break

func drawBars(alpha = null):
	var bh = H() * 0.075
	_ctx.save()
	_ctx.globalAlpha = alpha
	_ctx.fillStyle = "#000"
	_ctx.fillRect(0, 0, W(), bh)
	_ctx.fillRect(0, H() - bh, W(), bh)
	_ctx.restore()

# ── Particles ─────────────────────────────────────────────────────────────
func spawnP(x = null, y = null, o = null):
	_particles.append({
		"x": x,
		"y": y,
		"vx": (o.get("vx") if o.get("vx") != null else (JS.vrandom() - 0.5) * 2),
		"vy": (o.get("vy") if o.get("vy") != null else (-JS.vrandom()) * 1.4),
		"life": 1,
		"decay": JS.or_(o.get("decay"), 0.013),
		"size": (o.get("size") if JS.t(o.get("size")) else (JS.vrandom() * 2) + 1),
		"r": JS.or_(o.get("r"), 220),
		"g": JS.or_(o.get("g"), 90),
		"b": JS.or_(o.get("b"), 20),
	})

func tickP():
	_particles = JS.arr(_particles).filter(func(p = null): return p.get("life") > 0)
	for p in JS.iter(_particles):
		p.x += p.get("vx")
		p.y += p.get("vy")
		p.life -= p.get("decay")
		_ctx.save()
		_ctx.globalAlpha = p.get("life") * 0.75
		_ctx.fillStyle = "rgb(" + JS.s(p.get("r")) + "," + JS.s(p.get("g")) + "," + JS.s(p.get("b")) + ")"
		_ctx.beginPath()
		_ctx.arc(p.get("x"), p.get("y"), p.size, 0, PI * 2)
		_ctx.fill()
		_ctx.restore()

# ── Night sky (for exterior) ───────────────────────────────────────────────
func drawNightSky():
	var sky = _ctx.createLinearGradient(0, 0, 0, H())
	sky.addColorStop(0, "#030208")
	sky.addColorStop(0.65, "#060412")
	sky.addColorStop(1, "#0a0618")
	_ctx.fillStyle = sky
	_ctx.fillRect(0, 0, W(), H())
	for i in range(55):
		var sx = JS.mod((i * 211.3) + 41, W())
		var sy = JS.mod((i * 127.1) + 19, H() * 0.55)
		_ctx.fillStyle = "rgba(200,185,220," + JS.s(0.25 + (0.2 * sin(i * 1.4))) + ")"
		_ctx.fillRect(sx, sy, 1.5, 1.5)

# ── Castle exterior (matching opening cutscene style) ─────────────────────
func drawCastle(cx = null, cy = null, s = null, alpha = null):
	_ctx.save()
	_ctx.globalAlpha = alpha
	_ctx.fillStyle = "rgb(4,2,10)"
	_ctx.fillRect(cx - (92 * s), cy - (62 * s), 184 * s, 62 * s)
	_ctx.fillRect(cx - (122 * s), cy - (42 * s), 42 * s, 42 * s)
	_ctx.fillRect(cx + (80 * s), cy - (42 * s), 42 * s, 42 * s)
	_ctx.fillRect(cx - (104 * s), cy - (108 * s), 32 * s, 68 * s)
	_ctx.fillRect(cx + (72 * s), cy - (108 * s), 32 * s, 68 * s)
	_ctx.fillRect(cx - (24 * s), cy - (82 * s), 48 * s, 82 * s)
	_ctx.beginPath()
	_ctx.moveTo(cx - (22 * s), cy - (82 * s))
	_ctx.lineTo(cx, cy - (158 * s))
	_ctx.lineTo(cx + (22 * s), cy - (82 * s))
	_ctx.fill()
	for _e1 in JS.iter([[cx - (88 * s), cy - (108 * s)], [cx + (88 * s), cy - (108 * s)]]):
		var tx = JS.idx(_e1, 0)
		var ty = JS.idx(_e1, 1)
		_ctx.beginPath()
		_ctx.moveTo(tx - (16 * s), ty)
		_ctx.lineTo(tx, ty - (38 * s))
		_ctx.lineTo(tx + (16 * s), ty)
		_ctx.fill()
	for i in range(8):
		_ctx.fillRect((cx - (88 * s)) + ((i * 24) * s), cy - (72 * s), 13 * s, 12 * s)
	_ctx.restore()

# ── Torch sconce ─────────────────────────────────────────────────────────
func drawTorch(x = null, y = null, sec = null, idx = null):
	var f = 0.72 + (0.28 * sin((sec * 7.1) + (idx * 2.3)))
	# Sconce bracket
	_ctx.fillStyle = "#1c0e06"
	_ctx.fillRect(x - 3, y, 6, 14)
	_ctx.fillRect(x - 6, y + 12, 12, 4)
	# Glow
	var grd = _ctx.createRadialGradient(x, y, 0, x, y, 32 * f)
	grd.addColorStop(0, "rgba(255,145,20," + JS.s(0.55 * f) + ")")
	grd.addColorStop(0.45, "rgba(200,65,8," + JS.s(0.22 * f) + ")")
	grd.addColorStop(1, "rgba(160,30,0,0)")
	_ctx.fillStyle = grd
	_ctx.fillRect(x - 34, y - 34, 68, 68)
	# Flame
	_ctx.fillStyle = "rgba(255,190,60," + JS.s(f * 0.9) + ")"
	_ctx.beginPath()
	_ctx.ellipse(x, y - 7, 4, 9 * f, 0, 0, PI * 2)
	_ctx.fill()

# ── Throne room background ─────────────────────────────────────────────────
# One-point perspective hall. vp = vanishing point.
func drawHall(sec = null):
	var ctx = _ctx
	var vpX = W() * 0.5
	var vpY = H() * 0.22
	# Stone background
	var bg = ctx.createLinearGradient(0, 0, 0, H())
	bg.addColorStop(0, "#08051a")
	bg.addColorStop(0.5, "#0d0924")
	bg.addColorStop(1, "#060412")
	ctx.fillStyle = bg
	ctx.fillRect(0, 0, W(), H())
	# Ceiling vaulting lines
	ctx.strokeStyle = "rgba(28,18,50,0.55)"
	ctx.lineWidth = 1
	for i in range(10):
		var fx = W() * (i / 9.0)
		ctx.beginPath()
		ctx.moveTo(lerp_(vpX, fx, 0.04), lerp_(vpY, H() * 0.04, 0.04))
		ctx.lineTo(fx, 0)
		ctx.stroke()
	# Floor perspective tiles
	ctx.strokeStyle = "rgba(30,20,55,0.5)"
	ctx.lineWidth = 0.8
	# Longitudinal lines
	for i in range(14):
		var fx = W() * (i / 13.0)
		ctx.beginPath()
		ctx.moveTo(lerp_(vpX, fx, 0.06), lerp_(vpY, H(), 0.06))
		ctx.lineTo(fx, H())
		ctx.stroke()
	# Lateral lines
	for i in range(1, 10):
		var fy = lerp_(vpY, H(), i / 10.0)
		var spread = lerp_(0.03, 0.5, i / 10.0)
		ctx.beginPath()
		ctx.moveTo(vpX - (W() * spread), fy)
		ctx.lineTo(vpX + (W() * spread), fy)
		ctx.stroke()
	# Dark side walls
	ctx.fillStyle = "#06040f"
	ctx.beginPath()
	ctx.moveTo(0, 0)
	ctx.lineTo(W() * 0.18, vpY)
	ctx.lineTo(W() * 0.18, H())
	ctx.lineTo(0, H())
	ctx.closePath()
	ctx.fill()
	ctx.beginPath()
	ctx.moveTo(W(), 0)
	ctx.lineTo(W() * 0.82, vpY)
	ctx.lineTo(W() * 0.82, H())
	ctx.lineTo(W(), H())
	ctx.closePath()
	ctx.fill()
	# Wall stone lines (left)
	ctx.strokeStyle = "rgba(18,12,32,0.7)"
	ctx.lineWidth = 0.7
	for r in range(10):
		var ry = H() * (r / 10.0)
		ctx.beginPath()
		ctx.moveTo(0, ry)
		ctx.lineTo(W() * 0.18, ry)
		ctx.stroke()
	# Wall stone lines (right)
	for r in range(10):
		var ry = H() * (r / 10.0)
		ctx.beginPath()
		ctx.moveTo(W() * 0.82, ry)
		ctx.lineTo(W(), ry)
		ctx.stroke()
	# Pillars (left side, 3 pairs shrinking to vanishing point)
	var pillarPositions = [[0.18, 0.9], [0.22, 0.65], [0.26, 0.45]]
	var _arr3 = JS.iter(pillarPositions)
	for i in range(len(_arr3)):
		var _e2 = _arr3[i]
		var px = JS.idx(_e2, 0)
		var py = JS.idx(_e2, 1)
		var pw = lerp_(32, 10, i / 2.0)
		var ph = H() * (py - (vpY / float(H())))
		ctx.fillStyle = "#0a0818"
		ctx.fillRect((W() * px) - (pw / 2.0), ((H() * vpY) / float(H())) + ((H() - ((H() * vpY) / float(H()))) * (1 - (py / 1.0))), pw, H() * py)
		# highlight edge
		ctx.fillStyle = "rgba(35,22,60,0.25)"
		ctx.fillRect((W() * px) - (pw / 2.0), ((H() * vpY) / float(H())) + ((H() - ((H() * vpY) / float(H()))) * (1 - (py / 1.0))), pw * 0.18, H() * py)
	# Mirror on right
	var _arr5 = JS.iter(pillarPositions)
	for i in range(len(_arr5)):
		var _e4 = _arr5[i]
		var px = JS.idx(_e4, 0)
		var py = JS.idx(_e4, 1)
		var pw = lerp_(32, 10, i / 2.0)
		ctx.fillStyle = "#0a0818"
		ctx.fillRect((W() * (1 - px)) - (pw / 2.0), ((H() * vpY) / float(H())) + ((H() - ((H() * vpY) / float(H()))) * (1 - (py / 1.0))), pw, H() * py)
	# Torches along walls
	var torchPairs = [
		[W() * 0.1, H() * 0.38],
		[W() * 0.14, H() * 0.52],
		[W() * 0.9, H() * 0.38],
		[W() * 0.86, H() * 0.52],
	]
	var _arr7 = JS.iter(torchPairs)
	for i in range(len(_arr7)):
		var _e6 = _arr7[i]
		var tx = JS.idx(_e6, 0)
		var ty = JS.idx(_e6, 1)
		drawTorch(tx, ty, sec, i)
		if JS.vrandom() < 0.04:
			spawnP(tx, ty - 8, {
				"vx": (JS.vrandom() - 0.5) * 0.6,
				"vy": (-JS.vrandom()) * 0.8,
				"decay": 0.03,
				"size": 1.2,
				"r": 240,
				"g": 140,
				"b": 30,
			})
	# Raised dais at back
	var daisW = W() * 0.24
	var daisH = H() * 0.055
	var daisX = (W() * 0.5) - (daisW * 0.5)
	var daisY = H() * 0.29
	ctx.fillStyle = "#0c0920"
	ctx.fillRect(daisX, daisY, daisW, daisH)
	ctx.fillStyle = "#100e28"
	ctx.fillRect(daisX - (W() * 0.03), daisY + daisH, daisW + (W() * 0.06), H() * 0.022)
	ctx.fillStyle = "#0f0c25"
	ctx.fillRect(daisX - (W() * 0.055), (daisY + daisH) + (H() * 0.022), daisW + (W() * 0.11), H() * 0.022)
	# Ambient dark vignette
	var vig = ctx.createRadialGradient(W() * 0.5, H() * 0.5, H() * 0.2, W() * 0.5, H() * 0.5, H())
	vig.addColorStop(0, "rgba(0,0,0,0)")
	vig.addColorStop(1, "rgba(0,0,0,0.55)")
	ctx.fillStyle = vig
	ctx.fillRect(0, 0, W(), H())

# ── Dark One throne ────────────────────────────────────────────────────────
func drawThrone(cx = null, cy = null, s = null):
	var ctx = _ctx
	ctx.fillStyle = "#08050f"
	# High throne back
	ctx.fillRect(cx - (22 * s), cy - (72 * s), 44 * s, 72 * s)
	# Throne crown spikes (5 pointed tips along the top)
	for ox in JS.iter([-16, -8, 0, 8, 16]):
		ctx.beginPath()
		ctx.moveTo(cx + ((ox - 6) * s), cy - (72 * s))
		ctx.lineTo(cx + (ox * s), cy - (92 * s))
		ctx.lineTo(cx + ((ox + 6) * s), cy - (72 * s))
		ctx.closePath()
		ctx.fill()
	# Armrests
	ctx.fillRect(cx - (34 * s), cy - (28 * s), 14 * s, 28 * s)
	ctx.fillRect(cx + (20 * s), cy - (28 * s), 14 * s, 28 * s)
	# Seat platform
	ctx.fillRect(cx - (24 * s), cy - (10 * s), 48 * s, 10 * s)
	# Throne glow (dark red)
	var tGrd = ctx.createRadialGradient(cx, cy - (50 * s), 0, cx, cy - (50 * s), 65 * s)
	tGrd.addColorStop(0, "rgba(55,0,0,0.28)")
	tGrd.addColorStop(1, "rgba(0,0,0,0)")
	ctx.fillStyle = tGrd
	ctx.fillRect(cx - (75 * s), cy - (115 * s), 150 * s, 130 * s)

# ── Dark One silhouette (seated on throne) ─────────────────────────────────
func drawDarkOne(cx = null, cy = null, s = null, sec = null):
	var ctx = _ctx
	# Shadow aura
	var aura = ctx.createRadialGradient(cx, cy - (40 * s), 0, cx, cy - (40 * s), 90 * s)
	aura.addColorStop(0, "rgba(50,0,0,0.45)")
	aura.addColorStop(0.55, "rgba(18,0,0,0.18)")
	aura.addColorStop(1, "rgba(0,0,0,0)")
	ctx.fillStyle = aura
	ctx.fillRect(cx - (100 * s), cy - (120 * s), 200 * s, 160 * s)
	ctx.fillStyle = "rgb(6,3,10)"
	# Crown (3 pointed prongs + band)
	var crownBase = cy - (60 * s)
	ctx.fillRect(cx - (16 * s), crownBase, 32 * s, 7 * s)
	# band
	for _e8 in JS.iter([[-11, -20], [0, -26], [11, -20]]):
		var ox = JS.idx(_e8, 0)
		var oy = JS.idx(_e8, 1)
		ctx.beginPath()
		ctx.moveTo(cx + ((ox - 5) * s), crownBase)
		ctx.lineTo(cx + (ox * s), crownBase + (oy * s))
		ctx.lineTo(cx + ((ox + 5) * s), crownBase)
		ctx.closePath()
		ctx.fill()
	# Head
	ctx.beginPath()
	ctx.arc(cx, cy - (50 * s), 11 * s, 0, PI * 2)
	ctx.fill()
	# Red eyes (glowing)
	for _e9 in JS.iter([[-4.5, -52], [4.5, -52]]):
		var ox = JS.idx(_e9, 0)
		var oy = JS.idx(_e9, 1)
		var ex = cx + (ox * s)
		var ey = cy + (oy * s)
		var eg = ctx.createRadialGradient(ex, ey, 0, ex, ey, 6 * s)
		var flicker = 0.85 + (0.15 * sin((sec * 6.2) + (1 if ox > 0 else 2)))
		eg.addColorStop(0, "rgba(255,40,0," + JS.s(flicker) + ")")
		eg.addColorStop(1, "rgba(140,0,0,0)")
		ctx.fillStyle = eg
		ctx.fillRect(ex - (7 * s), ey - (7 * s), 14 * s, 14 * s)
	ctx.fillStyle = "rgb(6,3,10)"
	# Torso (seated, compact)
	ctx.beginPath()
	ctx.moveTo(cx - (9 * s), cy - (38 * s))
	ctx.lineTo(cx - (22 * s), cy - (12 * s))
	ctx.lineTo(cx + (22 * s), cy - (12 * s))
	ctx.lineTo(cx + (9 * s), cy - (38 * s))
	ctx.closePath()
	ctx.fill()
	# Wide robes fanning out on seat
	ctx.beginPath()
	ctx.moveTo(cx - (22 * s), cy - (12 * s))
	ctx.lineTo(cx - (38 * s), cy + (4 * s))
	ctx.lineTo(cx + (38 * s), cy + (4 * s))
	ctx.lineTo(cx + (22 * s), cy - (12 * s))
	ctx.closePath()
	ctx.fill()
	# Arms resting on throne armrests
	ctx.fillRect(cx - (36 * s), cy - (20 * s), 18 * s, 7 * s)
	ctx.fillRect(cx + (18 * s), cy - (20 * s), 18 * s, 7 * s)
	# Lower robe drape
	ctx.fillRect(cx - (32 * s), cy + (2 * s), 64 * s, 14 * s)

# ── Wizard silhouette (generic, for crowd) ─────────────────────────────────
func drawWizard(cx = null, cy = null, s = null):
	var ctx = _ctx
	ctx.fillStyle = "rgb(7,4,12)"
	# Hat
	ctx.beginPath()
	ctx.moveTo(cx, cy - (82 * s))
	ctx.lineTo(cx - (13 * s), cy - (45 * s))
	ctx.lineTo(cx + (13 * s), cy - (45 * s))
	ctx.closePath()
	ctx.fill()
	ctx.fillRect(cx - (16 * s), cy - (47 * s), 32 * s, 4 * s)
	# Head
	ctx.beginPath()
	ctx.arc(cx, cy - (38 * s), 9 * s, 0, PI * 2)
	ctx.fill()
	# Body
	ctx.beginPath()
	ctx.moveTo(cx - (8 * s), cy - (30 * s))
	ctx.lineTo(cx - (18 * s), cy - (2 * s))
	ctx.lineTo(cx + (18 * s), cy - (2 * s))
	ctx.lineTo(cx + (8 * s), cy - (30 * s))
	ctx.closePath()
	ctx.fill()
	# Boots
	ctx.fillRect(cx - (13 * s), cy - (4 * s), 10 * s, 5 * s)
	ctx.fillRect(cx + (3 * s), cy - (4 * s), 10 * s, 5 * s)

# ── Our wizard silhouette (with staff) ────────────────────────────────────
func drawOurWizard(cx = null, cy = null, s = null):
	var ctx = _ctx
	ctx.fillStyle = "rgb(7,4,12)"
	# Staff
	ctx.fillRect(cx - (20 * s), cy - (95 * s), 3 * s, 95 * s)
	# Hat
	ctx.beginPath()
	ctx.moveTo(cx + (2 * s), cy - (95 * s))
	ctx.lineTo(cx - (12 * s), cy - (50 * s))
	ctx.lineTo(cx + (15 * s), cy - (50 * s))
	ctx.closePath()
	ctx.fill()
	ctx.fillRect(cx - (16 * s), cy - (52 * s), 30 * s, 4 * s)
	# Head
	ctx.beginPath()
	ctx.arc(cx + (2 * s), cy - (42 * s), 9 * s, 0, PI * 2)
	ctx.fill()
	# Body
	ctx.beginPath()
	ctx.moveTo(cx - (6 * s), cy - (34 * s))
	ctx.lineTo(cx - (16 * s), cy - (5 * s))
	ctx.lineTo(cx + (18 * s), cy - (5 * s))
	ctx.lineTo(cx + (10 * s), cy - (34 * s))
	ctx.closePath()
	ctx.fill()
	# Boots
	ctx.fillRect(cx - (12 * s), cy - (6 * s), 10 * s, 5 * s)
	ctx.fillRect(cx + (4 * s), cy - (6 * s), 10 * s, 5 * s)
	# Staff tip glow
	var sg = ctx.createRadialGradient(cx - (19 * s), cy - (97 * s), 0, cx - (19 * s), cy - (97 * s), 9 * s)
	sg.addColorStop(0, "rgba(185,110,255,.85)")
	sg.addColorStop(1, "rgba(90,40,190,0)")
	ctx.fillStyle = sg
	ctx.fillRect(cx - (28 * s), cy - (106 * s), 18 * s, 18 * s)

func drawElementWizard(cx = null, cy = null, s = null, el = null, sec = null, idx = null):
	var ctx = _ctx
	var pulse = 0.14 + (0.05 * sin((sec * 1.4) + (idx * 0.9)))
	# Elemental aura
	var aura = ctx.createRadialGradient(cx, cy - (40 * s), 0, cx, cy - (40 * s), 55 * s)
	aura.addColorStop(0, "rgba(" + JS.s(el.get("r")) + "," + JS.s(el.get("g")) + "," + JS.s(el.get("b")) + "," + JS.s(pulse) + ")")
	aura.addColorStop(1, "rgba(0,0,0,0)")
	ctx.fillStyle = aura
	ctx.fillRect(cx - (65 * s), cy - (90 * s), 130 * s, 110 * s)
	# Wizard body
	drawWizard(cx, cy, s)
	# Small colored dot above hat (element indicator)
	ctx.fillStyle = "rgba(" + JS.s(el.get("r")) + "," + JS.s(el.get("g")) + "," + JS.s(el.get("b")) + ",0.65)"
	ctx.beginPath()
	ctx.arc(cx, cy - (90 * s), 4 * s, 0, PI * 2)
	ctx.fill()

# ═══════════════════════════════════════════════════════════════════════════
# SCENES
# ═══════════════════════════════════════════════════════════════════════════
# ── Scene 1: Castle Exterior ───────────────────────────────────────────────
func sceneExterior(t = null, sec = null):
	drawNightSky()
	# Moon
	var mx = W() * 0.72
	var my = H() * 0.15
	var mr = H() * 0.048
	var mg = _ctx.createRadialGradient(mx, my, 0, mx, my, mr * 4)
	mg.addColorStop(0, "rgba(165,155,205,.18)")
	mg.addColorStop(1, "rgba(0,0,0,0)")
	_ctx.fillStyle = mg
	_ctx.fillRect(mx - (mr * 4), my - (mr * 4), mr * 8, mr * 8)
	_ctx.fillStyle = "rgb(178,170,205)"
	_ctx.beginPath()
	_ctx.arc(mx, my, mr, 0, PI * 2)
	_ctx.fill()
	var gY = H() * 0.72
	_ctx.fillStyle = "rgb(4,3,9)"
	_ctx.fillRect(0, gY, W(), H() - gY)
	# Ground mist
	var mist = _ctx.createLinearGradient(0, gY - (H() * 0.06), 0, gY + (H() * 0.08))
	mist.addColorStop(0, "rgba(12,6,28,0)")
	mist.addColorStop(1, "rgba(12,6,28,.78)")
	_ctx.fillStyle = mist
	_ctx.fillRect(0, gY - (H() * 0.06), W(), H() * 0.14)
	# Castle — zooms in slightly as we approach
	var zoom = lerp_(0.55, 0.75, easeOut(t))
	drawCastle(W() * 0.5, gY, zoom, min(1, t * 2))
	# Castle window lights
	_ctx.save()
	_ctx.globalAlpha = min(1, t * 2) * (0.55 + (0.18 * sin(sec * 3.2)))
	_ctx.fillStyle = "rgba(255,165,40,0.35)"
	for ox in JS.iter([-28, 0, 28]):
		_ctx.beginPath()
		_ctx.arc((W() * 0.5) + (ox * zoom), gY - (55 * zoom), 5 * zoom, 0, PI * 2)
		_ctx.fill()
	_ctx.restore()
	# Our wizard walking toward castle
	var walkX = lerp_(-40, W() * 0.38, easeInOut(clamp_(t / 0.85, 0, 1)))
	var bob = sin(sec * 3.6) * 2.5
	drawOurWizard(walkX, (gY + (H() * 0.06)) + bob, H() / 640.0)
	drawBars(1)
	drawNarration(NAR.get("exterior"), t)
	var ov = 1 - fadeCurve(t, 0.1, 0.88)
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 2: Great Hall Interior ───────────────────────────────────────────
func sceneHall(t = null, sec = null):
	drawHall(sec)
	# Crowd of wizards in two rows on either side, fading in
	var crowdAlpha = min(1, t * 1.8)
	var ws = H() / 720.0
	var floorY = H() * 0.82
	_ctx.save()
	_ctx.globalAlpha = crowdAlpha
	# Left row (4 wizards)
	var _arr10 = JS.iter([0.16, 0.22, 0.28, 0.34])
	for i in range(len(_arr10)):
		var fx = _arr10[i]
		drawWizard(W() * fx, floorY, ws * lerp_(0.65, 0.8, i / 3.0))
	# Right row (4 wizards)
	var _arr11 = JS.iter([0.84, 0.78, 0.72, 0.66])
	for i in range(len(_arr11)):
		var fx = _arr11[i]
		drawWizard(W() * fx, floorY, ws * lerp_(0.65, 0.8, i / 3.0))
	_ctx.restore()
	# Camera slow drift forward (subtle zoom)
	var zoom = 1 + (easeInOut(t) * 0.06)
	_ctx.save()
	_ctx.translate((W() * 0.5) * (1 - zoom), (H() * 0.5) * (1 - zoom))
	_ctx.scale(zoom, zoom)
	# Our wizard in the entrance (back of frame → moves forward)
	var enterT = easeOut(clamp_(t * 1.4, 0, 1))
	var charX = lerp_(W() * 0.5, W() * 0.5, enterT)
	# centred
	var charY = lerp_(H() * 0.5, H() * 0.78, enterT)
	_ctx.save()
	_ctx.globalAlpha = min(1, t * 2.2)
	drawOurWizard(charX, charY, ws * lerp_(0.6, 0.85, enterT))
	_ctx.restore()
	_ctx.restore()
	# un-zoom
	tickP()
	drawBars(1)
	drawNarration(NAR.get("hall"), t)
	var ov = 1 - fadeCurve(t, 0.08, 0.9)
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 3: The Throne — Dark One speaks ──────────────────────────────────
func sceneThrone(t = null, sec = null):
	drawHall(sec)
	var ws = H() / 720.0
	var cx = W() * 0.5
	var daisY = H() * 0.36
	# Throne
	drawThrone(cx, daisY, ws * 1.6)
	# Dark One (fades in slowly)
	_ctx.save()
	_ctx.globalAlpha = min(1, t * 1.4)
	drawDarkOne(cx, daisY, ws * 1.6, sec)
	_ctx.restore()
	# Dark energy tendrils / aura pulses
	if t > 0.15:
		var pulseA = (0.2 + (0.12 * sin(sec * 2.8))) * min(1, (t - 0.15) / 0.25)
		var tGrd = _ctx.createRadialGradient(cx, daisY - (50 * ws), 0, cx, daisY - (50 * ws), H() * 0.38)
		tGrd.addColorStop(0, "rgba(80,0,0," + JS.s(pulseA) + ")")
		tGrd.addColorStop(0.5, "rgba(25,0,0," + JS.s(pulseA * 0.4) + ")")
		tGrd.addColorStop(1, "rgba(0,0,0,0)")
		_ctx.fillStyle = tGrd
		_ctx.fillRect(0, 0, W(), H())
	# Crowd silhouettes in the foreground (bottom)
	_ctx.save()
	_ctx.globalAlpha = 0.55
	var fgS = ws * 0.9
	for i in JS.iter([-3, -2, -1, 0, 1, 2, 3]):
		drawWizard((W() * 0.5) + ((i * W()) * 0.11), H() * 0.96, fgS)
	_ctx.restore()
	tickP()
	drawBars(1)
	drawNarration(NAR.get("throne"), t)
	var ov = 1 - fadeCurve(t, 0.06, 0.9)
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 4: Pan Across Elemental Wizards ─────────────────────────────────
func scenePan(t = null, sec = null):
	# World is 3x screen wide; camera pans left→right
	var worldW = W() * 3.0
	var panX = easeInOut(t) * (worldW - W())
	var floorY = H() * 0.8
	var ws = H() / 680.0
	var spacing = worldW / float((len(EL) + 1))
	_ctx.save()
	_ctx.translate(-panX, 0)
	# Sky/background (wider)
	var bg = _ctx.createLinearGradient(0, 0, 0, H())
	bg.addColorStop(0, "#08051a")
	bg.addColorStop(0.5, "#0d0924")
	bg.addColorStop(1, "#060412")
	_ctx.fillStyle = bg
	_ctx.fillRect(0, 0, worldW, H())
	# Floor
	_ctx.fillStyle = "#060412"
	_ctx.fillRect(0, floorY, worldW, H() - floorY)
	_ctx.strokeStyle = "rgba(28,18,50,0.4)"
	_ctx.lineWidth = 0.7
	for i in range(20):
		_ctx.beginPath()
		_ctx.moveTo(worldW * (i / 19.0), floorY)
		_ctx.lineTo(worldW * (i / 19.0), H())
		_ctx.stroke()
	for r in range(1, 5):
		_ctx.beginPath()
		_ctx.moveTo(0, lerp_(floorY, H(), r / 5.0))
		_ctx.lineTo(worldW, lerp_(floorY, H(), r / 5.0))
		_ctx.stroke()
	# 8 elemental wizards
	var _arr12 = JS.iter(EL)
	for i in range(len(_arr12)):
		var el = _arr12[i]
		var ex = spacing * (i + 1)
		drawElementWizard(ex, floorY, ws, el, sec, i)
		# Name label below
		_ctx.save()
		_ctx.font = JS.s(clamp_(H() * 0.022, 9, 16)) + "px 'Cinzel',serif"
		_ctx.textAlign = "center"
		_ctx.fillStyle = "rgba(" + JS.s(el.get("r")) + "," + JS.s(el.get("g")) + "," + JS.s(el.get("b")) + ",0.45)"
		_ctx.fillText(el.get("name"), ex, floorY + (18 * ws))
		_ctx.restore()
	_ctx.restore()
	# Vignette edges
	var vigL = _ctx.createLinearGradient(0, 0, W() * 0.18, 0)
	vigL.addColorStop(0, "rgba(0,0,0,0.75)")
	vigL.addColorStop(1, "rgba(0,0,0,0)")
	_ctx.fillStyle = vigL
	_ctx.fillRect(0, 0, W() * 0.18, H())
	var vigR = _ctx.createLinearGradient(W() * 0.82, 0, W(), 0)
	vigR.addColorStop(0, "rgba(0,0,0,0)")
	vigR.addColorStop(1, "rgba(0,0,0,0.75)")
	_ctx.fillStyle = vigR
	_ctx.fillRect(W() * 0.82, 0, W() * 0.18, H())
	drawBars(1)
	drawNarration(NAR.get("pan"), t)
	var ov = 1 - fadeCurve(t, 0.06, 0.9)
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 5: Dark One Dispatches ──────────────────────────────────────────
func sceneDispatch(t = null, sec = null):
	drawHall(sec)
	var ws = H() / 720.0
	var cx = W() * 0.5
	var daisY = H() * 0.36
	drawThrone(cx, daisY, ws * 1.6)
	drawDarkOne(cx, daisY, ws * 1.6, sec)
	# Crowd of wizards starting to move/disperse
	var moveT = easeInOut(clamp_((t - 0.35) / 0.55, 0, 1))
	_ctx.save()
	_ctx.globalAlpha = max(0, 1 - (moveT * 0.8))
	var floorY = H() * 0.82
	var _arr13 = JS.iter([-3, -2, -1, 1, 2, 3])
	for idx in range(len(_arr13)):
		var i = _arr13[idx]
		var drift = ((moveT * W()) * (-0.22 if i < 0 else 0.22)) * (0.6 + (idx * 0.08))
		drawWizard(((W() * 0.5) + ((i * W()) * 0.1)) + drift, floorY, ws * 0.82)
	_ctx.restore()
	# Dark One's hand gesture — arm extending outward (t > .3)
	if t > 0.25:
		var gestA = min(1, (t - 0.25) / 0.2)
		_ctx.save()
		_ctx.globalAlpha = gestA
		_ctx.strokeStyle = "rgba(120,20,20,0.55)"
		_ctx.lineWidth = 3 * ws
		_ctx.beginPath()
		_ctx.moveTo(cx + ((22 * ws) * 1.6), daisY - ((18 * ws) * 1.6))
		_ctx.lineTo((cx + ((22 * ws) * 1.6)) + ((35 * ws) * gestA), daisY - ((16 * ws) * 1.6))
		_ctx.stroke()
		_ctx.restore()
	# Dark energy pulse when dispatching
	if t > 0.28:
		var pa = (0.15 + (0.1 * sin(sec * 4.5))) * min(1, (t - 0.28) / 0.18)
		var pg = _ctx.createRadialGradient(cx, daisY - (40 * ws), 0, cx, daisY - (40 * ws), H() * 0.3)
		pg.addColorStop(0, "rgba(60,0,0," + JS.s(pa) + ")")
		pg.addColorStop(1, "rgba(0,0,0,0)")
		_ctx.fillStyle = pg
		_ctx.fillRect(0, 0, W(), H())
	tickP()
	drawBars(1)
	drawNarration(NAR.get("dispatch"), t)
	var ov = 1 - fadeCurve(t, 0.06, 0.88)
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 6: Our Wizard Ejected ───────────────────────────────────────────
func sceneEject(t = null, sec = null):
	drawNightSky()
	var gY = H() * 0.72
	_ctx.fillStyle = "rgb(4,3,9)"
	_ctx.fillRect(0, gY, W(), H() - gY)
	var mist = _ctx.createLinearGradient(0, gY - (H() * 0.05), 0, gY + (H() * 0.08))
	mist.addColorStop(0, "rgba(12,6,28,0)")
	mist.addColorStop(1, "rgba(12,6,28,.75)")
	_ctx.fillStyle = mist
	_ctx.fillRect(0, gY - (H() * 0.05), W(), H() * 0.13)
	# Castle
	drawCastle(W() * 0.5, gY, 0.72, 1)
	# Castle gate/door opening then closing
	var doorOpen = clamp_(t / 0.18, 0, 1)
	var doorClose = easeInOut(clamp_((t - 0.38) / 0.35, 0, 1))
	var doorW = W() * 0.055
	var doorH = H() * 0.072
	var doorX = (W() * 0.5) - (doorW * 0.5)
	var doorY = gY - doorH
	# Door gap (light spills out when open)
	if doorOpen > 0:
		var openW = (doorW * doorOpen) * max(0, 1 - (doorClose * 0.95))
		var hallLight = _ctx.createRadialGradient(W() * 0.5, gY, 0, W() * 0.5, gY, H() * 0.12)
		hallLight.addColorStop(0, "rgba(90,50,20," + JS.s((0.35 * doorOpen) * (1 - (doorClose * 0.9))) + ")")
		hallLight.addColorStop(1, "rgba(0,0,0,0)")
		_ctx.fillStyle = hallLight
		_ctx.fillRect(0, 0, W(), H())
		_ctx.fillStyle = "rgba(80,42,8," + JS.s((0.55 * doorOpen) * (1 - (doorClose * 0.95))) + ")"
		_ctx.fillRect((W() * 0.5) - (openW * 0.5), doorY, openW, doorH)
	# Our wizard being ejected — tumbles out
	var throwT = easeOut(clamp_((t - 0.05) / 0.4, 0, 1))
	var landT = easeInOut(clamp_((t - 0.45) / 0.3, 0, 1))
	var wS = H() / 640.0
	var charX = null
	var charY = null
	var rot = 0
	if t < 0.45:
		charX = lerp_(W() * 0.5, W() * 0.28, throwT)
		charY = lerp_(gY, gY + (H() * 0.04), throwT)
		rot = lerp_(0, -0.22, throwT)
	else:
		# Landed, straightens up
		charX = W() * 0.28
		charY = gY + (H() * 0.04)
		rot = lerp_(-0.22, 0, landT)
	_ctx.save()
	_ctx.translate(charX, charY)
	_ctx.rotate(rot)
	_ctx.translate(-charX, -charY)
	drawOurWizard(charX, charY, wS)
	_ctx.restore()
	# Dust puff on landing
	if ((t > 0.44 and t < 0.52) and JS.vrandom() < 0.35):
		spawnP(charX, charY, {
			"vx": (JS.vrandom() - 0.5) * 3.5,
			"vy": (-JS.vrandom()) * 1.8,
			"decay": 0.025,
			"size": 2.2,
			"r": 60,
			"g": 45,
			"b": 80,
		})
	# Wizard looks back at castle (t > .55) — we add a small head-turn glow
	if t > 0.58:
		var lookA = min(1, (t - 0.58) / 0.15) * 0.35
		var lookG = _ctx.createRadialGradient(charX + (12 * wS), charY - (42 * wS), 0, charX + (12 * wS), charY - (42 * wS), 18 * wS)
		lookG.addColorStop(0, "rgba(180,100,255," + JS.s(lookA) + ")")
		lookG.addColorStop(1, "rgba(0,0,0,0)")
		_ctx.fillStyle = lookG
		_ctx.fillRect(charX - (8 * wS), charY - (60 * wS), 36 * wS, 36 * wS)
	tickP()
	drawBars(1)
	drawNarration(NAR.get("eject"), t)
	# Fade out at end
	if t > 0.8:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s((t - 0.8) / 0.2) + ")"
		_ctx.fillRect(0, 0, W(), H())
	var ov = 1 - fadeCurve(t, 0.08, 0.88)
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Main loop ─────────────────────────────────────────────────────────────
func tick(ts = null):
	if JS.t(_done):
		return
	var el = ts - _startTime
	var sec = el / 1000.0
	_ctx.clearRect(0, 0, W(), H())
	if el < T.get("exteriorEnd"):
		sceneExterior(el / float(T.get("exteriorEnd")), sec)
	elif el < T.get("hallEnd"):
		sceneHall((el - T.get("exteriorEnd")) / float((T.get("hallEnd") - T.get("exteriorEnd"))), sec)
	elif el < T.get("throneEnd"):
		sceneThrone((el - T.get("hallEnd")) / float((T.get("throneEnd") - T.get("hallEnd"))), sec)
	elif el < T.get("panEnd"):
		scenePan((el - T.get("throneEnd")) / float((T.get("panEnd") - T.get("throneEnd"))), sec)
	elif el < T.get("dispatchEnd"):
		sceneDispatch((el - T.get("panEnd")) / float((T.get("dispatchEnd") - T.get("panEnd"))), sec)
	elif el < T.get("ejectEnd"):
		sceneEject((el - T.get("dispatchEnd")) / float((T.get("ejectEnd") - T.get("dispatchEnd"))), sec)
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
	var screen = document.getElementById("cutscene-screen")
	if JS.t(screen):
		screen.style.transition = "opacity 1s"
		screen.style.opacity = "0"
		var _fn14 = func():
			screen.style.display = "none"
			screen.style.opacity = "1"
			screen.style.transition = ""
			if JS.t(_onComplete):
				_onComplete.call()
		JS.setTimeout(_fn14, 1000)
	else:
		if JS.t(_onComplete):
			_onComplete.call()

func playThroneRoomCutscene(onComplete = null):
	_onComplete = onComplete
	_done = false
	_particles = []
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
