# DarkOneIntro — generated from js/rendering/dark_one_intro.js by tools/js2gd.js
extends Node

var _onComplete = null
var _canvas = null
var _ctx = null
var _raf = null
var _startTime = 0
var _done = false
var _particles = null
var T = null

func _boot():
	# ===== dark_one_intro.js =====
	# ~7 second cinematic intro before the Dark One fight.
	# Scene 1: Dark void with pulsing aura + title.
	# Scene 2: Dark One materializes on throne, tendrils spread.
	# Scene 3: Close-up of his glowing red eyes.
	# Click or any key to skip.
	_particles = []
	T = {"voidEnd": 2500, "riseEnd": 5500, "eyesEnd": 7000}

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

func spawnP(x = null, y = null, opts = null):
	_particles.append({
		"x": x,
		"y": y,
		"vx": JS.or_(opts.get("vx"), 0),
		"vy": JS.or_(opts.get("vy"), -1),
		"life": 1,
		"decay": JS.or_(opts.get("decay"), 0.018),
		"size": JS.or_(opts.get("size"), 2),
		"r": JS.or_(opts.get("r"), 200),
		"g": JS.or_(opts.get("g"), 0),
		"b": JS.or_(opts.get("b"), 0),
	})

func tickP():
	_particles = JS.arr(_particles).filter(func(p = null): return p.life > 0)
	for p in JS.iter(_particles):
		p.x += p.vx
		p.y += p.vy
		p.life -= p.decay
		_ctx.fillStyle = "rgba(" + JS.s(p.r) + "," + JS.s(p.g) + "," + JS.s(p.b) + "," + JS.s(max(0, p.life * 0.7)) + ")"
		_ctx.fillRect(p.x - (p.size / 2.0), p.y - (p.size / 2.0), p.size, p.size)

# t progress through this line's window; returns 0-1 alpha
func narAlpha(t = null, in0 = null, in1 = null, out0 = null, out1 = null):
	if (t < in0 or t > out1):
		return 0
	if t < in1:
		return (t - in0) / float(in1 - in0)
	if t > out0:
		return 1 - ((t - out0) / float(out1 - out0))
	return 1

func drawNarLine(text = null, alpha = null):
	if alpha <= 0:
		return
	var barH = H() * 0.12
	var bg = _ctx.createLinearGradient(0, H() - (barH * 1.6), 0, H())
	bg.addColorStop(0, "rgba(0,0,0,0)")
	bg.addColorStop(0.35, "rgba(0,0,0,0.72)")
	bg.addColorStop(1, "rgba(0,0,0,0.92)")
	_ctx.fillStyle = bg
	_ctx.fillRect(0, H() - (barH * 1.6), W(), barH * 1.6)
	_ctx.save()
	_ctx.globalAlpha = alpha
	_ctx.font = JS.s(clamp_(H() * 0.028, 11, 22)) + "px 'Cinzel',serif"
	_ctx.textAlign = "center"
	_ctx.fillStyle = "#c8a0ff"
	_ctx.shadowColor = "rgba(100,0,180,0.7)"
	_ctx.shadowBlur = 12
	_ctx.fillText(text, W() * 0.5, H() * 0.9)
	_ctx.restore()

# ── Drawing helpers (mirrors castle_cutscene.js) ───────────────────────────
func drawThrone(cx = null, cy = null, s = null):
	var ctx = _ctx
	ctx.fillStyle = "rgb(12,4,18)"
	ctx.fillRect(cx - (22 * s), cy - (72 * s), 44 * s, 72 * s)
	for ox in JS.iter([-16, -8, 0, 8, 16]):
		ctx.beginPath()
		ctx.moveTo(cx + ((ox - 6) * s), cy - (72 * s))
		ctx.lineTo(cx + (ox * s), cy - (92 * s))
		ctx.lineTo(cx + ((ox + 6) * s), cy - (72 * s))
		ctx.closePath()
		ctx.fill()
	ctx.fillRect(cx - (34 * s), cy - (28 * s), 14 * s, 28 * s)
	ctx.fillRect(cx + (20 * s), cy - (28 * s), 14 * s, 28 * s)
	ctx.fillRect(cx - (24 * s), cy - (10 * s), 48 * s, 10 * s)
	var tGrd = ctx.createRadialGradient(cx, cy - (50 * s), 0, cx, cy - (50 * s), 65 * s)
	tGrd.addColorStop(0, "rgba(55,0,0,0.28)")
	tGrd.addColorStop(1, "rgba(0,0,0,0)")
	ctx.fillStyle = tGrd
	ctx.fillRect(cx - (75 * s), cy - (115 * s), 150 * s, 130 * s)

func drawDarkOne(cx = null, cy = null, s = null, sec = null):
	var ctx = _ctx
	var aura = ctx.createRadialGradient(cx, cy - (40 * s), 0, cx, cy - (40 * s), 90 * s)
	aura.addColorStop(0, "rgba(50,0,0,0.45)")
	aura.addColorStop(0.55, "rgba(18,0,0,0.18)")
	aura.addColorStop(1, "rgba(0,0,0,0)")
	ctx.fillStyle = aura
	ctx.fillRect(cx - (100 * s), cy - (120 * s), 200 * s, 160 * s)
	ctx.fillStyle = "rgb(6,3,10)"
	var crownBase = cy - (60 * s)
	ctx.fillRect(cx - (16 * s), crownBase, 32 * s, 7 * s)
	for _e1 in JS.iter([[-11, -20], [0, -26], [11, -20]]):
		var ox = JS.idx(_e1, 0)
		var oy = JS.idx(_e1, 1)
		ctx.beginPath()
		ctx.moveTo(cx + ((ox - 5) * s), crownBase)
		ctx.lineTo(cx + (ox * s), crownBase + (oy * s))
		ctx.lineTo(cx + ((ox + 5) * s), crownBase)
		ctx.closePath()
		ctx.fill()
	ctx.beginPath()
	ctx.arc(cx, cy - (50 * s), 11 * s, 0, PI * 2)
	ctx.fill()
	for _e2 in JS.iter([[-4.5, -52], [4.5, -52]]):
		var ox = JS.idx(_e2, 0)
		var oy = JS.idx(_e2, 1)
		var ex = cx + (ox * s)
		var ey = cy + (oy * s)
		var eg = ctx.createRadialGradient(ex, ey, 0, ex, ey, 6 * s)
		var flicker = 0.85 + (0.15 * sin((sec * 6.2) + (1 if ox > 0 else 2)))
		eg.addColorStop(0, "rgba(255,40,0," + JS.s(flicker) + ")")
		eg.addColorStop(1, "rgba(140,0,0,0)")
		ctx.fillStyle = eg
		ctx.fillRect(ex - (7 * s), ey - (7 * s), 14 * s, 14 * s)
	ctx.fillStyle = "rgb(6,3,10)"
	ctx.beginPath()
	ctx.moveTo(cx - (9 * s), cy - (38 * s))
	ctx.lineTo(cx - (22 * s), cy - (12 * s))
	ctx.lineTo(cx + (22 * s), cy - (12 * s))
	ctx.lineTo(cx + (9 * s), cy - (38 * s))
	ctx.closePath()
	ctx.fill()
	ctx.beginPath()
	ctx.moveTo(cx - (22 * s), cy - (12 * s))
	ctx.lineTo(cx - (38 * s), cy + (4 * s))
	ctx.lineTo(cx + (38 * s), cy + (4 * s))
	ctx.lineTo(cx + (22 * s), cy - (12 * s))
	ctx.closePath()
	ctx.fill()
	ctx.fillRect(cx - (36 * s), cy - (20 * s), 18 * s, 7 * s)
	ctx.fillRect(cx + (18 * s), cy - (20 * s), 18 * s, 7 * s)
	ctx.fillRect(cx - (32 * s), cy + (2 * s), 64 * s, 14 * s)

# ── Scene 1: Dark void with pulsing aura ──────────────────────────────────
func sceneVoid(t = null, sec = null):
	_ctx.fillStyle = "#000"
	_ctx.fillRect(0, 0, W(), H())
	var pulse = 0.15 + (0.12 * sin(sec * 2.1))
	var fade = easeOut(t)
	var aura = _ctx.createRadialGradient(W() * 0.5, H() * 0.45, 0, W() * 0.5, H() * 0.45, H() * 0.45)
	aura.addColorStop(0, "rgba(80,0,0," + JS.s((pulse + 0.1) * fade) + ")")
	aura.addColorStop(0.4, "rgba(35,0,0," + JS.s(pulse * fade) + ")")
	aura.addColorStop(1, "rgba(0,0,0,0)")
	_ctx.fillStyle = aura
	_ctx.fillRect(0, 0, W(), H())
	if randf() < 0.25:
		var px = (W() * 0.5) + (((randf() - 0.5) * W()) * 0.4)
		spawnP(px, H() * 0.65, {
			"vx": (randf() - 0.5) * 1.2,
			"vy": ((-randf()) * 1.5) - 0.5,
			"decay": 0.012,
			"size": 1.5,
			"r": 200,
			"g": 30,
			"b": 0,
		})
	tickP()
	# Title
	if t > 0.3:
		var a = clamp_((t - 0.3) / 0.22, 0, 1)
		_ctx.save()
		_ctx.globalAlpha = a
		_ctx.font = "bold " + JS.s(clamp_(H() * 0.06, 18, 46)) + "px 'Cinzel',serif"
		_ctx.textAlign = "center"
		_ctx.fillStyle = "#8b0000"
		_ctx.shadowColor = "rgba(200,0,0,0.9)"
		_ctx.shadowBlur = 28
		_ctx.fillText("THE DARK ONE", W() * 0.5, H() * 0.44)
		_ctx.restore()
	drawNarLine("The architect of the time loop.", narAlpha(t, 0.55, 0.7, 0.82, 0.96))
	# Fade in from black
	var ov = 1 - easeOut(clamp_(t / 0.12, 0, 1))
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 2: Dark One materializes on throne ──────────────────────────────
func sceneRise(t = null, sec = null):
	var bg = _ctx.createLinearGradient(0, 0, 0, H())
	bg.addColorStop(0, "#060008")
	bg.addColorStop(0.5, "#0a000f")
	bg.addColorStop(1, "#040006")
	_ctx.fillStyle = bg
	_ctx.fillRect(0, 0, W(), H())
	var cx = W() * 0.5
	var cy = H() * 0.54
	var ws = H() / 720.0
	var appearA = easeOut(clamp_(t * 1.6, 0, 1))
	# Expanding aura behind the figure
	var auraR = lerp_(H() * 0.18, H() * 0.55, easeInOut(t))
	var pulseA = (0.28 + (0.12 * sin(sec * 2.8))) * appearA
	var bigAura = _ctx.createRadialGradient(cx, cy - (50 * ws), 0, cx, cy - (50 * ws), auraR)
	bigAura.addColorStop(0, "rgba(100,0,0," + JS.s(pulseA) + ")")
	bigAura.addColorStop(0.5, "rgba(40,0,0," + JS.s(pulseA * 0.5) + ")")
	bigAura.addColorStop(1, "rgba(0,0,0,0)")
	_ctx.fillStyle = bigAura
	_ctx.fillRect(0, 0, W(), H())
	# Throne then figure fade in
	_ctx.save()
	_ctx.globalAlpha = clamp_(t * 2.2, 0, 1)
	drawThrone(cx, cy, ws * 1.6)
	_ctx.restore()
	_ctx.save()
	_ctx.globalAlpha = appearA
	drawDarkOne(cx, cy, ws * 1.6, sec)
	_ctx.restore()
	# Dark tendrils radiating outward
	if t > 0.18:
		var tendA = clamp_((t - 0.18) / 0.3, 0, 1) * (0.12 + (0.06 * sin(sec * 3.2)))
		_ctx.strokeStyle = "rgba(130,0,0," + JS.s(tendA) + ")"
		_ctx.lineWidth = 1.5
		for i in range(8):
			var angle = (((i / 8.0) * PI) * 2) + (sec * 0.18)
			var len_ = H() * lerp_(0.1, 0.36, easeInOut(t))
			_ctx.beginPath()
			_ctx.moveTo(cx + ((cos(angle) * H()) * 0.04), (cy - (50 * ws)) + ((sin(angle) * H()) * 0.04))
			_ctx.lineTo(cx + (cos(angle) * len_), (cy - (50 * ws)) + (sin(angle) * len_))
			_ctx.stroke()
	if randf() < 0.3:
		spawnP(cx + (((randf() - 0.5) * W()) * 0.5), H() * 0.75, {
			"vx": (randf() - 0.5) * 1.5,
			"vy": ((-randf()) * 2) - 0.5,
			"decay": 0.014,
			"size": 1.8,
			"r": 200,
			"g": 40,
			"b": 0,
		})
	tickP()
	drawNarLine("The source of all suffering.", narAlpha(t, 0.52, 0.68, 0.84, 0.97))
	var ov = 1 - easeOut(clamp_(t / 0.1, 0, 1))
	if ov > 0:
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(ov) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Scene 3: Close-up glowing red eyes ────────────────────────────────────
func sceneEyes(t = null, sec = null):
	_ctx.fillStyle = "#000"
	_ctx.fillRect(0, 0, W(), H())
	var appear = easeOut(clamp_(t / 0.25, 0, 1))
	var eyeSep = W() * 0.1
	var eyeY = H() * 0.44
	var eyeSize = (H() * 0.075) * (1 + (0.05 * sin(sec * 4.1)))
	var flicker = 0.88 + (0.12 * sin(sec * 5.5))
	for side in JS.iter([-1, 1]):
		var ex = (W() * 0.5) + (side * eyeSep)
		var eg = _ctx.createRadialGradient(ex, eyeY, 0, ex, eyeY, eyeSize * 2.6)
		eg.addColorStop(0, "rgba(255,60,0," + JS.s(flicker * appear) + ")")
		eg.addColorStop(0.3, "rgba(200,10,0," + JS.s((0.7 * flicker) * appear) + ")")
		eg.addColorStop(1, "rgba(0,0,0,0)")
		_ctx.fillStyle = eg
		_ctx.fillRect(ex - (eyeSize * 3), eyeY - (eyeSize * 3), eyeSize * 6, eyeSize * 6)
	# Ambient glow between the eyes
	var midAura = _ctx.createRadialGradient(W() * 0.5, eyeY, 0, W() * 0.5, eyeY, H() * 0.28)
	midAura.addColorStop(0, "rgba(55,0,0," + JS.s(0.3 * appear) + ")")
	midAura.addColorStop(1, "rgba(0,0,0,0)")
	_ctx.fillStyle = midAura
	_ctx.fillRect(0, 0, W(), H())
	if randf() < 0.22:
		spawnP((W() * 0.5) + (((randf() - 0.5) * W()) * 0.55), H() * 0.82, {"vx": (randf() - 0.5) * 1, "vy": (-randf()) * 1.8, "decay": 0.016, "size": 1.4, "r": 220, "g": 20, "b": 0})
	tickP()
	drawNarLine("He has been waiting.", narAlpha(t, 0.1, 0.28, 0.62, 0.82))
	# Fade out to black at end
	if t > 0.8:
		var fadeOut = (t - 0.8) / 0.2
		_ctx.fillStyle = "rgba(0,0,0," + JS.s(fadeOut) + ")"
		_ctx.fillRect(0, 0, W(), H())

# ── Main loop ─────────────────────────────────────────────────────────────
func tick(ts = null):
	if JS.t(_done):
		return
	var el = ts - _startTime
	var sec = el / 1000.0
	_ctx.clearRect(0, 0, W(), H())
	if el < T.voidEnd:
		sceneVoid(el / float(T.voidEnd), sec)
	elif el < T.riseEnd:
		sceneRise((el - T.voidEnd) / float(T.riseEnd - T.voidEnd), sec)
	elif el < T.eyesEnd:
		sceneEyes((el - T.riseEnd) / float(T.eyesEnd - T.riseEnd), sec)
	else:
		endIntro()
		return
	_raf = JS.requestAnimationFrame(tick)

func endIntro():
	if JS.t(_done):
		return
	_done = true
	JS.cancelAnimationFrame(_raf)
	_particles = []
	var screen = document.getElementById("cutscene-screen")
	if JS.t(screen):
		screen.style.transition = "opacity 0.5s"
		screen.style.opacity = "0"
		var _fn3 = func():
			screen.style.display = "none"
			screen.style.opacity = "1"
			screen.style.transition = ""
			if JS.t(_onComplete):
				_onComplete.call()
		JS.setTimeout(_fn3, 500)
	else:
		if JS.t(_onComplete):
			_onComplete.call()

func playDarkOneIntro(onComplete = null):
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
	screen.addEventListener("click", func(): return endIntro(), {"once": true})
	document.addEventListener("keydown", func(): return endIntro(), {"once": true})
	_startTime = JS.now()
	_raf = JS.requestAnimationFrame(tick)
