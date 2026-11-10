# Sprites — generated from js/rendering/sprites.js by tools/js2gd.js
extends Node

# ═══ POSITIONS ════════════════════════════════════════════════════════════════
var P_SCALE = 4
var E_SCALE = 3
var S_SCALE = 3
# ═══ MAIN RENDER ══════════════════════════════════════════════════════════════
var _battleFrame = 0
# ═══ LOOP ══════════════════════════════════════════════════════════════════════
var _battleRAF = null

func _boot():
	pass

# ===== sprites.js =====
# ─── SPRITES.JS — Pixel art battlefield canvas ────────────────────────────────
# Pokemon-style battlefield: player back-left, enemies front-right.
# Canvas renders continuously via rAF loop.
# Static sprite data lives in js/data/sprite_data.js (loaded first).
# ═══ PALETTE LOOKUPS ══════════════════════════════════════════════════════════
func getElemPal(element = null):
	var el = (JS.idx(JS.split(element, JS.re("[\\/\\s]", "")), 0) if JS.t(element) else "Neutral")
	return JS.or_(JS.idx(SpriteData.EL_PAL, el), SpriteData.EL_PAL.get("Neutral"))

func getBGTone(element = null):
	var el = (JS.idx(JS.split(element, JS.re("[\\/\\s]", "")), 0) if JS.t(element) else "Neutral")
	return JS.or_(JS.idx(SpriteData.BG_TONES, el), SpriteData.BG_TONES.get("Neutral"))

func getElemHatSprite(element = null):
	return JS.or_(JS.idx(SpriteData.ELEM_HAT_SPRITES, element), SpriteData.ELEM_HAT_SPRITES.get("Fire"))

# ═══ DRAWING ══════════════════════════════════════════════════════════════════
func charToColor(c = null, pal = null):
	match c:
		"1":
			return JS.idx(pal, 0)
		"2":
			return JS.idx(pal, 1)
		"3":
			return JS.idx(pal, 2)
		"4":
			return JS.idx(pal, 3)
		"h":
			return JS.idx(pal, 1)
		"s":
			return SpriteData.SKIN_C
		"e":
			return SpriteData.EYE_C
		"b":
			return SpriteData.BOOT_C
		"w":
			return SpriteData.BEARD_C
		"f":
			# white beard
			return SpriteData.STAFF_C
		"g":
			# wooden staff
			return JS.idx(pal, 3)
		_:
			# staff glow — matches element highlight
			return null

# Hand-optimised: sprites are cached as textures instead of being drawn pixel by pixel each frame.
func drawSprite(ctx = null, rows = null, x = null, y = null, scale_ = null, pal = null, cols = null, flipH = null):
	cols = JS.or_(cols, 12)
	var key = hash(pal)
	var colors = _sprite_pal_cache.get(key)
	if colors == null:
		colors = {}
		for ch in ["1", "2", "3", "4", "h", "s", "e", "b", "w", "f", "g"]:
			var c = charToColor(ch, pal)
			if JS.t(c): colors[ch] = c
		if _sprite_pal_cache.size() > 200: _sprite_pal_cache.clear()
		_sprite_pal_cache[key] = colors
	ctx.drawPixelRows(rows, x, y, scale_, colors, cols, JS.t(flipH))

# ═══ BACKGROUND ══════════════════════════════════════════════════════════════
# ═══ ZONE BATTLE BACKGROUNDS ═════════════════════════════════════════════════
# Each element gets a unique daytime arena scene.
# Ground line sits at GROUND_Y = H * 0.62. Both fighters stand on it.
func _bBGtick():
	return JS.dateNow()

func _horizonFrac():
	return 0.25

func _bSkyGrad(ctx = null, W = null, H = null, c0 = null, c1 = null, horizFrac = null):
	var g = ctx.createLinearGradient(0, 0, 0, H * horizFrac)
	g.addColorStop(0, c0)
	g.addColorStop(1, c1)
	ctx.fillStyle = g
	ctx.fillRect(0, 0, W, ceili(H * horizFrac))

func _bGroundGrad(ctx = null, W = null, H = null, c0 = null, c1 = null, horizFrac = null):
	var g = ctx.createLinearGradient(0, H * horizFrac, 0, H)
	g.addColorStop(0, c0)
	g.addColorStop(1, c1)
	ctx.fillStyle = g
	ctx.fillRect(0, floori(H * horizFrac), W, H)

func _bHillSil(ctx = null, W = null, H = null, horizFrac = null, col = null, phase = null):
	var hy = H * horizFrac
	ctx.fillStyle = col
	ctx.beginPath()
	for x in range(0, floori(W) + 1):
		var y = (hy + ((sin((x * 0.025) + (JS.or_(phase, 0))) * H) * 0.04)) + ((sin((x * 0.011) + ((JS.or_(phase, 0)) * 0.7)) * H) * 0.025)
		if x == 0:
			ctx.moveTo(0, JS.round(y))
		else:
			ctx.lineTo(x, JS.round(y))
	ctx.lineTo(W, H)
	ctx.lineTo(0, H)
	ctx.closePath()
	ctx.fill()

func _bStars(ctx = null, W = null, H = null, horizFrac = null, n = null):
	for i in range(ceili(n)):
		var sx = JS.mod((i * 173) + 37, W)
		var sy = JS.mod((i * 97) + 19, JS.round((H * horizFrac) * 0.9))
		var bright = 0.3 + (0.4 * sin((_bBGtick() * 0.004) + (i * 0.9)))
		ctx.fillStyle = "rgba(255,255,255," + JS.toFixed(bright, 2) + ")"
		ctx.fillRect(sx, sy, (2 if (JS.mod(i, 7)) == 0 else 1), (2 if (JS.mod(i, 7)) == 0 else 1))

# ─── FIRE battle arena ───────────────────────────────────────────────────────
func _bbFire(ctx = null, W = null, H = null):
	var t = _bBGtick()
	var hf = _horizonFrac()
	_bSkyGrad(ctx, W, H, "#1a0500", "#3d0800", hf)
	# Volcano silhouette with crater glow (matches lobby panel)
	ctx.fillStyle = "#0a0100"
	ctx.beginPath()
	ctx.moveTo(0, JS.round(H * hf))
	ctx.lineTo(JS.round(W * 0.18), JS.round(H * (hf - 0.24)))
	ctx.lineTo(JS.round(W * 0.3), JS.round(H * (hf - 0.38)))
	ctx.lineTo(JS.round(W * 0.42), JS.round(H * (hf - 0.22)))
	ctx.lineTo(JS.round(W * 0.6), JS.round(H * (hf - 0.3)))
	ctx.lineTo(JS.round(W * 0.72), JS.round(H * (hf - 0.18)))
	ctx.lineTo(W, JS.round(H * hf))
	ctx.closePath()
	ctx.fill()
	var vcx = JS.round(W * 0.3)
	var vcy = JS.round(H * (hf - 0.38))
	var vcg = ctx.createRadialGradient(vcx, vcy, 0, vcx, vcy, JS.round(W * 0.18))
	vcg.addColorStop(0, "rgba(255,80,0,0.45)")
	vcg.addColorStop(0.4, "rgba(180,30,0,0.18)")
	vcg.addColorStop(1, "transparent")
	ctx.fillStyle = vcg
	ctx.fillRect(0, 0, W, JS.round(H * hf))
	_bHillSil(ctx, W, H, hf - 0.08, "#110200", 0.3)
	# Lava glow on horizon
	var hg = ctx.createLinearGradient(0, (H * hf) - 12, 0, (H * hf) + 8)
	hg.addColorStop(0, "rgba(255,80,0,0.35)")
	hg.addColorStop(1, "rgba(255,80,0,0)")
	ctx.fillStyle = hg
	ctx.fillRect(0, (H * hf) - 12, W, 20)
	# Ground — black volcanic rock
	_bGroundGrad(ctx, W, H, "#220800", "#0e0400", hf)
	# Lava crack seams
	for i in range(6):
		var cx2 = JS.mod((i * 211) + 37, W)
		var cy2 = JS.round(H * ((hf + 0.08) + ((JS.mod(i, 3)) * 0.06)))
		var glow = 0.4 + (0.4 * sin((t * 0.008) + i))
		ctx.fillStyle = "rgba(255," + JS.s(JS.round(60 + (40 * glow))) + ",0," + JS.toFixed(0.5 + (0.3 * glow), 2) + ")"
		ctx.fillRect(cx2, cy2, 20 + ((JS.mod(i, 4)) * 8), 2)
	# Charred tree silhouette (far back)
	ctx.fillStyle = "#100502"
	for _e1 in JS.iter([[W * 0.12, H * 0.52, 18], [W * 0.82, H * 0.5, 14], [W * 0.6, H * 0.54, 10]]):
		var tx = JS.idx(_e1, 0)
		var ty = JS.idx(_e1, 1)
		var th = JS.idx(_e1, 2)
		ctx.fillRect(tx - 2, ty - th, 4, th)
		ctx.fillRect(tx + 2, (ty - th) + 4, 8, 2)
		ctx.fillRect(tx - 10, (ty - th) + 8, 8, 2)
	# Embers floating up
	for i in range(8):
		var ex = JS.mod((i * 173) + 31, W)
		var phase = JS.mod((t * 0.001) + (i * 0.7), 1)
		var ey = JS.round(H * (0.9 - (phase * 0.5)))
		ctx.fillStyle = "rgba(255," + JS.s(JS.round(100 + (100 * phase))) + ",0," + JS.toFixed(1 - phase, 2) + ")"
		ctx.fillRect(ex, ey, 2, 2)
	# Ground line
	ctx.fillStyle = "#cc3300"
	ctx.fillRect(0, JS.round(H * hf), W, 1)

# ─── WATER battle arena ──────────────────────────────────────────────────────
func _bbWater(ctx = null, W = null, H = null):
	var t = _bBGtick()
	var hf = _horizonFrac()
	_bSkyGrad(ctx, W, H, "#040d1a", "#0a2035", hf)
	_bStars(ctx, W, H, hf, 40)
	# Moon reflection
	var mx = JS.round(W * 0.72)
	var mReflY = JS.round((H * hf) * 0.25)
	ctx.fillStyle = "rgba(220,230,255,0.9)"
	ctx.fillRect(mx - 4, mReflY, 8, 8)
	ctx.fillStyle = "rgba(220,230,255,0.5)"
	ctx.fillRect(mx - 6, mReflY + 2, 4, 4)
	ctx.fillRect(mx + 4, mReflY + 2, 4, 4)
	# Distant rocky island silhouette (matches lobby panel)
	ctx.fillStyle = "#020e1c"
	ctx.beginPath()
	ctx.moveTo(JS.round(W * 0.12), JS.round(H * hf))
	ctx.lineTo(JS.round(W * 0.2), JS.round(H * (hf - 0.12)))
	ctx.lineTo(JS.round(W * 0.32), JS.round(H * (hf - 0.2)))
	ctx.lineTo(JS.round(W * 0.44), JS.round(H * (hf - 0.13)))
	ctx.lineTo(JS.round(W * 0.55), JS.round(H * hf))
	ctx.closePath()
	ctx.fill()
	_bHillSil(ctx, W, H, hf - 0.1, "#080d18", 0.5)
	_bHillSil(ctx, W, H, hf - 0.04, "#0a1220", 0.8)
	# Ocean ground
	var og = ctx.createLinearGradient(0, H * hf, 0, H)
	og.addColorStop(0, "#0a3050")
	og.addColorStop(0.5, "#082540")
	og.addColorStop(1, "#051830")
	ctx.fillStyle = og
	ctx.fillRect(0, floori(H * hf), W, H)
	# Wave lines
	for wi in range(4):
		var wy = JS.round(H * ((hf + 0.05) + (wi * 0.07)))
		var phase = (t * 0.002) + (wi * 1.1)
		ctx.fillStyle = "rgba(100,180,220," + JS.s(0.15 - (wi * 0.02)) + ")"
		for x in range(ceili(W)):
			var w2 = sin((x * 0.04) + phase) * 3
			if abs(w2) > 1.5:
				ctx.fillRect(x, wy + JS.round(w2), 1, 2)
	# Moon shimmer on water
	for i in range(5):
		var sx = (mx - 6) + (i * 3)
		var sy = JS.round(((H * hf) + 4) + (i * 8))
		var alpha = 0.25 - (i * 0.04)
		ctx.fillStyle = "rgba(200,220,255," + JS.s(alpha) + ")"
		ctx.fillRect(sx, sy, 3, 2)
	# Bioluminescent sparkle dots near waterline (matches lobby panel)
	for i in range(8):
		var bx = JS.round(JS.mod((i * 173) + 31, W))
		var by = JS.round(H * ((hf + 0.06) + (JS.mod(i * 0.09, 0.14))))
		var ba = 0.3 + (0.5 * sin((t * 0.04) + (i * 2.1)))
		if ba < 0.1:
			continue
		ctx.fillStyle = "rgba(68,255,204," + JS.toFixed(ba, 2) + ")"
		ctx.fillRect(bx, by, 1, 1)
	# Sandy shore
	ctx.fillStyle = "#7a6838"
	ctx.fillRect(0, JS.round(H * hf) - 2, W, 3)
	# Ground line
	ctx.fillStyle = "#1a8aaa"
	ctx.fillRect(0, JS.round(H * hf), W, 1)

# ─── ICE battle arena ────────────────────────────────────────────────────────
func _bbIce(ctx = null, W = null, H = null):
	var t = _bBGtick()
	var hf = _horizonFrac()
	_bSkyGrad(ctx, W, H, "#060c18", "#0a1628", hf)
	_bStars(ctx, W, H, hf, 50)
	# Aurora (sweeping color ribbons — matches lobby panel green/blue/violet)
	var auroraC = ["rgba(0,255,160,", "rgba(0,180,255,", "rgba(100,80,255,"]
	for ai in range(3):
		var aPhase = (t * 0.0012) + (ai * 1.4)
		var ay = JS.round((H * (0.07 + (ai * 0.11))) + ((sin(aPhase) * H) * 0.018))
		var ah = JS.round(H * (0.06 + (0.03 * sin(aPhase * 0.7))))
		var ag = ctx.createLinearGradient(0, ay, 0, ay + ah)
		ag.addColorStop(0, "transparent")
		ag.addColorStop(0.5, JS.s(JS.add(auroraC[ai], 0.18 + (0.1 * sin(aPhase * 1.3)))) + ")")
		ag.addColorStop(1, "transparent")
		ctx.fillStyle = ag
		ctx.fillRect(0, ay, W, ah)
	_bHillSil(ctx, W, H, hf - 0.1, "#8ab0d0", 0.4)
	_bHillSil(ctx, W, H, hf - 0.04, "#a0c8e8", 0.7)
	# Snowy ground
	var ig = ctx.createLinearGradient(0, H * hf, 0, H)
	ig.addColorStop(0, "#c8dff0")
	ig.addColorStop(1, "#b0cce0")
	ctx.fillStyle = ig
	ctx.fillRect(0, floori(H * hf), W, H)
	# Snow sparkles
	for i in range(20):
		var sx = JS.mod((i * 173) + 31, W)
		var sy = JS.round(H * ((hf + 0.05) + ((JS.mod((i * 97) + 13, JS.round(H * 0.38))) / float(H))))
		var bright = 0.4 + (0.5 * sin((t * 0.005) + (i * 1.1)))
		ctx.fillStyle = "rgba(255,255,255," + JS.toFixed(bright, 2) + ")"
		ctx.fillRect(sx, sy, 2, 2)
	# Icicles from top of ground line
	for i in range(12):
		var ix = JS.mod((i * 97) + 41, W)
		var ih = 4 + ((JS.mod(i, 5)) * 3)
		ctx.fillStyle = "#90c0e0"
		ctx.fillRect(ix - 1, JS.round(H * hf), 2, ih)
		ctx.fillStyle = "#c0e0f8"
		ctx.fillRect(ix, JS.round(H * hf), 1, ih - 2)
	# Ground line
	ctx.fillStyle = "#80b8d8"
	ctx.fillRect(0, JS.round(H * hf), W, 1)

# ─── LIGHTNING battle arena ──────────────────────────────────────────────────
func _bbLightning(ctx = null, W = null, H = null):
	var t = _bBGtick()
	var hf = _horizonFrac()
	_bSkyGrad(ctx, W, H, "#06040e", "#100830", hf)
	_bStars(ctx, W, H, hf, 35)
	# Storm clouds (dark rolling masses)
	for ci in range(4):
		var cx2 = (JS.mod((ci * 211) + 37, W)) * 1.0
		var cy2 = JS.round(H * (0.08 + (ci * 0.07)))
		var cw = 60 + ((JS.mod(ci, 3)) * 30)
		var ch = 14 + ((JS.mod(ci, 2)) * 8)
		ctx.fillStyle = "rgba(20,12,40,0.85)"
		ctx.fillRect(JS.round(cx2 - (cw / 2.0)), cy2, cw, ch)
		ctx.fillStyle = "rgba(40,25,70,0.5)"
		ctx.fillRect(JS.round(cx2 - (cw / 2.0)), cy2, cw, 4)
	# Ambient purple glow pulse in upper sky (matches lobby panel)
	ctx.globalAlpha = 0.06 + (0.04 * sin(t * 0.025))
	ctx.fillStyle = "#7744ff"
	ctx.fillRect(0, 0, W, JS.round((H * hf) * 0.5))
	ctx.globalAlpha = 1
	_bHillSil(ctx, W, H, hf - 0.08, "#0c0a1c", 0.3)
	_bGroundGrad(ctx, W, H, "#14102a", "#08060e", hf)
	# Cracked earth
	for i in range(10):
		var cx2 = JS.mod((i * 173) + 31, W)
		var cy2 = JS.round(H * ((hf + 0.04) + (((JS.mod((i * 97) + 13, JS.round(H * 0.3))) / float(H)) * H)))
		ctx.strokeStyle = "#1e1838"
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.moveTo(cx2, cy2)
		ctx.lineTo(cx2 + (12 if JS.t(JS.mod(i, 2)) else -12), cy2 + ((JS.mod(i, 3)) * 4))
		ctx.stroke()
	# Lightning arcs in sky
	if (JS.mod(t, 2200)) < 180:
		var ax = JS.round(W * (0.3 + ((JS.mod(int(t / 2200.0), 3)) * 0.2)))
		ctx.strokeStyle = "#ffffaa"
		ctx.lineWidth = 2
		ctx.beginPath()
		ctx.moveTo(ax, 0)
		for seg in range(5):
			ctx.lineTo(ax + (sin(t + (seg * 7)) * 14), ((seg * H) * hf) / 5.0)
		ctx.stroke()
		ctx.strokeStyle = "rgba(200,180,255,0.3)"
		ctx.lineWidth = 8
		ctx.stroke()
		# Ground impact glow
		ctx.fillStyle = "rgba(220,200,80,0.3)"
		ctx.beginPath()
		ctx.ellipse(ax, JS.round(H * hf), 20, 6, 0, 0, PI * 2)
		ctx.fill()
	# Ground line
	ctx.fillStyle = "#6040cc"
	ctx.fillRect(0, JS.round(H * hf), W, 1)

# ─── EARTH battle arena ──────────────────────────────────────────────────────
func _bbEarth(ctx = null, W = null, H = null):
	var t = _bBGtick()
	var hf = _horizonFrac()
	_bSkyGrad(ctx, W, H, "#08040a", "#1a0e04", hf)
	_bStars(ctx, W, H, hf, 30)
	# Flat-top mesa plateau silhouettes (Earth's signature look — matches lobby panel)
	ctx.fillStyle = "#150a02"
	ctx.beginPath()
	ctx.moveTo(0, JS.round(H * hf))
	ctx.lineTo(0, JS.round(H * (hf - 0.22)))
	ctx.lineTo(JS.round(W * 0.14), JS.round(H * (hf - 0.22)))
	ctx.lineTo(JS.round(W * 0.14), JS.round(H * (hf - 0.32)))
	ctx.lineTo(JS.round(W * 0.38), JS.round(H * (hf - 0.32)))
	ctx.lineTo(JS.round(W * 0.38), JS.round(H * (hf - 0.2)))
	ctx.lineTo(JS.round(W * 0.55), JS.round(H * (hf - 0.2)))
	ctx.lineTo(JS.round(W * 0.55), JS.round(H * (hf - 0.28)))
	ctx.lineTo(JS.round(W * 0.8), JS.round(H * (hf - 0.28)))
	ctx.lineTo(JS.round(W * 0.8), JS.round(H * (hf - 0.16)))
	ctx.lineTo(W, JS.round(H * (hf - 0.16)))
	ctx.lineTo(W, JS.round(H * hf))
	ctx.closePath()
	ctx.fill()
	# Mesa top highlight (warm rim light)
	ctx.fillStyle = "#2a1008"
	for _e2 in JS.iter([[0, 0.22, 0.14], [0.14, 0.32, 0.38], [0.38, 0.2, 0.55], [0.55, 0.28, 0.8], [0.8, 0.16, 1.0]]):
		var x1 = JS.idx(_e2, 0)
		var y1 = JS.idx(_e2, 1)
		var x2 = JS.idx(_e2, 2)
		ctx.fillRect(JS.round(W * x1), JS.round(H * (hf - y1)), JS.round(W * (x2 - x1)), 2)
	# Rocky ground
	_bGroundGrad(ctx, W, H, "#4a2c10", "#2a1808", hf)
	# Rock pebbles
	for i in range(14):
		var rx = JS.mod((i * 173) + 31, W)
		var ry = JS.round(H * ((hf + 0.05) + (((JS.mod((i * 97) + 13, JS.round(H * 0.35))) / float(H)) * H)))
		var rw = 4 + ((JS.mod(i, 5)) * 2)
		var rh = 3 + (JS.mod(i, 3))
		ctx.fillStyle = ("#6a4020" if (JS.mod(i, 3)) == 0 else ("#5a3218" if (JS.mod(i, 3)) == 1 else "#7a5030"))
		ctx.fillRect(rx, ry, rw, rh)
		ctx.fillStyle = "#8a6040"
		ctx.fillRect(rx, ry, rw, 1)
	# Stone formations in background
	var stX = JS.round(W * 0.15)
	var stY = JS.round(H * (hf - 0.12))
	for _e3 in JS.iter([[0, 0, 14, 20], [14, 6, 10, 14], [24, 3, 8, 17]]):
		var dx = JS.idx(_e3, 0)
		var dy = JS.idx(_e3, 1)
		var sw = JS.idx(_e3, 2)
		var sh = JS.idx(_e3, 3)
		ctx.fillStyle = "#4a2e10"
		ctx.fillRect(stX + dx, stY + dy, sw, sh)
		ctx.fillStyle = "#6a4828"
		ctx.fillRect(stX + dx, stY + dy, sw, 2)
	# Ground line
	ctx.fillStyle = "#8a5a20"
	ctx.fillRect(0, JS.round(H * hf), W, 1)

# ─── NATURE battle arena ─────────────────────────────────────────────────────
func _bbNature(ctx = null, W = null, H = null):
	var t = _bBGtick()
	var hf = _horizonFrac()
	_bSkyGrad(ctx, W, H, "#030c06", "#062010", hf)
	_bStars(ctx, W, H, hf, 30)
	_bHillSil(ctx, W, H, hf - 0.12, "#041008", 0.4)
	_bHillSil(ctx, W, H, hf - 0.05, "#072014", 0.7)
	# Pine tree silhouettes along hill line (matches lobby panel layered treeline)
	ctx.fillStyle = "#041005"
	for i in range(10):
		var tx = JS.round(((JS.mod((i * 197) + 41, 997)) / 997.0) * W)
		var ty = JS.round(H * (hf - 0.05))
		var tw = JS.round(W * 0.055)
		var th = JS.round(H * 0.18)
		# Trunk
		ctx.fillRect(tx + JS.round(tw * 0.44), ty - JS.round(th * 0.5), JS.round(tw * 0.12), JS.round(th * 0.5))
		# Lower canopy
		ctx.beginPath()
		ctx.moveTo(tx + JS.round(tw * 0.5), ty - th)
		ctx.lineTo(tx, ty - JS.round(th * 0.4))
		ctx.lineTo(tx + tw, ty - JS.round(th * 0.4))
		ctx.closePath()
		ctx.fill()
		# Upper canopy
		ctx.beginPath()
		ctx.moveTo(tx + JS.round(tw * 0.5), ty - JS.round(th * 0.75))
		ctx.lineTo(tx + JS.round(tw * 0.08), ty - JS.round(th * 0.18))
		ctx.lineTo(tx + JS.round(tw * 0.92), ty - JS.round(th * 0.18))
		ctx.closePath()
		ctx.fill()
	# Rich green ground
	_bGroundGrad(ctx, W, H, "#1c4a10", "#0e2a08", hf)
	# Grass tufts
	for i in range(16):
		var gx = JS.mod((i * 173) + 31, W)
		var gy = JS.round(H * ((hf + 0.03) + (((JS.mod((i * 97) + 13, JS.round(H * 0.2))) / float(H)) * H)))
		ctx.fillStyle = ("#2a5a14" if (JS.mod(i, 3)) == 0 else ("#224a10" if (JS.mod(i, 3)) == 1 else "#1e4010"))
		ctx.fillRect(gx, gy, 3 + (JS.mod(i, 3)), 2)
		ctx.fillRect(gx + 1, (gy - 1) + (JS.mod(i, 2)), 1, 2)
	# Waterfall mist (left edge)
	var wy = JS.round(H * 0.3)
	while wy < JS.round(H * hf):
		var alpha = 0.08 + (0.06 * sin((t * 0.01) + (wy * 0.1)))
		ctx.fillStyle = "rgba(140,200,240," + JS.toFixed(alpha, 2) + ")"
		ctx.fillRect(0 + JS.round(sin((wy * 0.3) + (t * 0.006)) * 3), wy, 5, 3)
		wy += 3
	# Fireflies
	for i in range(6):
		var fx = JS.mod((i * 211) + 53, W)
		var phase = JS.mod((t * 0.0008) + (i * 0.55), 1)
		var fy = JS.round(H * (0.4 + (sin((t * 0.001) + i) * 0.08)))
		var glow = sin((t * 0.006) + (i * 1.3))
		if glow > 0.2:
			ctx.fillStyle = "rgba(180,240,100," + JS.toFixed(glow * 0.6, 2) + ")"
			ctx.fillRect(fx, fy, 2, 2)
	# Ground line
	ctx.fillStyle = "#4a8a20"
	ctx.fillRect(0, JS.round(H * hf), W, 1)

# ─── PLASMA battle arena ─────────────────────────────────────────────────────
func _bbPlasma(ctx = null, W = null, H = null):
	var t = _bBGtick()
	var hf = _horizonFrac()
	_bSkyGrad(ctx, W, H, "#08020e", "#180330", hf)
	_bStars(ctx, W, H, hf, 45)
	# Void planet/orb in sky (matches lobby panel)
	var orbX = JS.round(W * 0.65)
	var orbY = JS.round(H * 0.2)
	var orbR = max(6, JS.round(W * 0.055))
	var orbG = ctx.createRadialGradient(orbX - JS.round(orbR * 0.3), orbY - JS.round(orbR * 0.3), 0, orbX, orbY, orbR)
	orbG.addColorStop(0, "#9933cc")
	orbG.addColorStop(0.6, "#550088")
	orbG.addColorStop(1, "#220044")
	ctx.fillStyle = orbG
	ctx.beginPath()
	ctx.arc(orbX, orbY, orbR, 0, PI * 2)
	ctx.fill()
	ctx.strokeStyle = "rgba(200,80,255,0.35)"
	ctx.lineWidth = 1
	ctx.beginPath()
	ctx.ellipse(orbX, orbY, JS.round(orbR * 1.5), JS.round(orbR * 0.35), -0.3, 0, PI * 2)
	ctx.stroke()
	# Phase shimmer on horizon
	var phg = ctx.createLinearGradient(0, (H * hf) - 14, 0, (H * hf) + 6)
	phg.addColorStop(0, "rgba(180,20,220,0.3)")
	phg.addColorStop(1, "rgba(180,20,220,0)")
	ctx.fillStyle = phg
	ctx.fillRect(0, (H * hf) - 14, W, 20)
	_bHillSil(ctx, W, H, hf - 0.1, "#100220", 0.4)
	_bGroundGrad(ctx, W, H, "#1e0430", "#0e0218", hf)
	# Crystal veins
	for i in range(10):
		var vx = JS.mod((i * 173) + 31, W)
		var vy = JS.round(H * ((hf + 0.04) + (((JS.mod((i * 97) + 13, JS.round(H * 0.35))) / float(H)) * H)))
		var glow = 0.3 + (0.4 * sin((t * 0.006) + (i * 1.1)))
		ctx.fillStyle = "rgba(" + JS.s((180 if JS.t(JS.mod(i, 2)) else 120)) + ",30," + JS.s((255 if JS.t(JS.mod(i, 2)) else 180)) + "," + JS.toFixed(glow, 2) + ")"
		ctx.fillRect(vx, vy, 3 + (JS.mod(i, 3)), 2)
	# Floating orbs
	for i in range(4):
		var ox = JS.round(W * (0.15 + (i * 0.22)))
		var oy = JS.round(H * (0.25 + (sin((t * 0.001) + (i * 1.4)) * 0.06)))
		var glow = 0.5 + (0.4 * sin((t * 0.005) + i))
		ctx.fillStyle = "rgba(180,60,255," + JS.toFixed(glow * 0.4, 2) + ")"
		ctx.beginPath()
		ctx.arc(ox, oy, 5 + ((JS.mod(i, 2)) * 2), 0, PI * 2)
		ctx.fill()
		ctx.fillStyle = "rgba(220,120,255,0.6)"
		ctx.fillRect(ox - 1, oy - 1, 2, 2)
	# Ground line
	ctx.fillStyle = "#aa30ee"
	ctx.fillRect(0, JS.round(H * hf), W, 1)

# ─── AIR battle arena ────────────────────────────────────────────────────────
func _bbAir(ctx = null, W = null, H = null):
	var t = _bBGtick()
	var hf = _horizonFrac()
	# Night sky — full canvas
	var sky = ctx.createLinearGradient(0, 0, 0, H)
	sky.addColorStop(0, "#03050d")
	sky.addColorStop(0.55, "#07101e")
	sky.addColorStop(1, "#0d1a2e")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, H)
	# Stars (deterministic)
	var ss = [17, 31, 53, 79, 101, 127, 149, 163, 193, 211, 233, 251, 269, 281, 307, 331]
	var _arr4 = JS.iter(ss)
	for i in range(len(_arr4)):
		var s = _arr4[i]
		var sx = JS.mod((s * 37) + (i * 83), W)
		var sy = JS.mod((s * 53) + (i * 61), H * 0.9)
		ctx.fillStyle = "rgba(215,228,255," + JS.toFixed(0.3 + ((JS.mod(i, 5)) * 0.13), 2) + ")"
		ctx.fillRect(sx, sy, (2 if (JS.mod(i, 7)) == 0 else 1), (2 if (JS.mod(i, 7)) == 0 else 1))
	# Moon
	var mx = JS.round(W * 0.86)
	var my = JS.round(H * 0.09)
	ctx.fillStyle = "#ddeeff"
	ctx.fillRect(mx - 6, my - 6, 12, 12)
	ctx.fillStyle = "#060e1c"
	ctx.fillRect(mx + 2, my - 5, 5, 10)
	# Distant mountain range visible through sky (matches lobby panel)
	ctx.fillStyle = "#0c1420"
	ctx.beginPath()
	ctx.moveTo(0, JS.round(H * 0.68))
	ctx.lineTo(JS.round(W * 0.08), JS.round(H * 0.38))
	ctx.lineTo(JS.round(W * 0.2), JS.round(H * 0.5))
	ctx.lineTo(JS.round(W * 0.34), JS.round(H * 0.22))
	ctx.lineTo(JS.round(W * 0.46), JS.round(H * 0.36))
	ctx.lineTo(JS.round(W * 0.6), JS.round(H * 0.28))
	ctx.lineTo(JS.round(W * 0.72), JS.round(H * 0.44))
	ctx.lineTo(JS.round(W * 0.86), JS.round(H * 0.32))
	ctx.lineTo(W, JS.round(H * 0.48))
	ctx.lineTo(W, JS.round(H * 0.68))
	ctx.closePath()
	ctx.fill()
	# Snow highlights on peaks (matches lobby panel)
	ctx.fillStyle = "#1e2e40"
	ctx.globalAlpha = 0.5
	for _e5 in JS.iter([[0.34, 0.22, 0.44, 0.34], [0.6, 0.28, 0.7, 0.38], [0.08, 0.38, 0.14, 0.48]]):
		var x1 = JS.idx(_e5, 0)
		var y1 = JS.idx(_e5, 1)
		var x2 = JS.idx(_e5, 2)
		var y2 = JS.idx(_e5, 3)
		ctx.beginPath()
		ctx.moveTo(JS.round(W * x1), JS.round(H * y1))
		ctx.lineTo(JS.round(W * (((x1 + x2) / 2.0) - 0.04)), JS.round(H * (y1 * 0.82)))
		ctx.lineTo(JS.round(W * x2), JS.round(H * y2))
		ctx.closePath()
		ctx.fill()
	ctx.globalAlpha = 1
	# Wind particle streaks (matches lobby panel)
	for i in range(5):
		var wp = JS.mod((t * 0.00014) + (i * 0.22), 1)
		var wy2 = JS.round(H * (0.5 + (JS.mod(i * 0.07, 0.18))))
		var wx2 = JS.round(((wp * W) * 1.3) - (W * 0.15))
		ctx.globalAlpha = (1 - wp) * 0.1
		ctx.fillStyle = "#aaccee"
		ctx.fillRect(wx2, wy2, JS.round(W * 0.12), 1)
	ctx.globalAlpha = 1
	# Player cloud platform (left — pushed to edge)
	var pcy = JS.round(H * 0.68)
	_bbCloudPad(ctx, JS.round(W * 0.17), pcy, 110, 28, true)
	# Enemy cloud platform (right — pushed to other edge, clear sky gap between)
	var ecy = JS.round(H * 0.64)
	_bbCloudPad(ctx, JS.round(W * 0.8), ecy, 95, 24, false)

func _bbCloudPad(ctx = null, cx = null, cy = null, w = null, h = null, bright = null):
	var base = ("#c0d8f4" if JS.t(bright) else "#5a7898")
	var mid = ("#a8c8e8" if JS.t(bright) else "#4a6880")
	var top = ("#e8f4ff" if JS.t(bright) else "#80a8c8")
	var shad = ("rgba(80,120,180,0.18)" if JS.t(bright) else "rgba(10,25,55,0.40)")
	var l = cx - JS.round(w / 2.0)
	var bodyTop = cy + JS.round(h * 0.45)
	var bodyH = JS.round(h * 0.55)
	ctx.fillStyle = shad
	ctx.fillRect(l + 4, (cy + h) + 3, w - 4, 4)
	ctx.fillStyle = mid
	ctx.fillRect(l, bodyTop, w, bodyH)
	var bumpDefs = ([
		{"ox": 0.08, "bw": 0.28, "bh": 0.72},
		{"ox": 0.3, "bw": 0.24, "bh": 0.55},
		{"ox": 0.5, "bw": 0.3, "bh": 0.82},
		{"ox": 0.72, "bw": 0.22, "bh": 0.58},
	] if w > 70 else [
		{"ox": 0.1, "bw": 0.38, "bh": 0.72},
		{"ox": 0.42, "bw": 0.3, "bh": 0.58},
		{"ox": 0.66, "bw": 0.28, "bh": 0.68},
	])
	for _e6 in JS.iter(bumpDefs):
		var ox = JS.idx(_e6, "ox")
		var bw = JS.idx(_e6, "bw")
		var bh = JS.idx(_e6, "bh")
		var bx = l + JS.round(ox * w)
		var bwPx = JS.round(bw * w)
		var bhPx = JS.round((bh * h) * 0.6)
		var bTop = bodyTop - bhPx
		ctx.fillStyle = base
		ctx.fillRect(bx, bTop + 2, bwPx, (bhPx + bodyH) - 2)
		ctx.fillStyle = top
		ctx.fillRect(bx + 1, bTop, bwPx - 2, 2)
		ctx.fillStyle = base
		ctx.fillRect(bx - 1, bTop + 2, 1, bhPx - 2)
		ctx.fillRect(bx + bwPx, bTop + 2, 1, bhPx - 2)
	ctx.fillStyle = top
	ctx.fillRect(l + 1, bodyTop, w - 2, 1)

func drawBattleBG(ctx = null, W = null, H = null):
	var el = (State.currentZoneElement if (true and JS.t(State.currentZoneElement)) else State.playerElement)
	match el:
		"Fire":
			_bbFire(ctx, W, H)
		"Water":
			_bbWater(ctx, W, H)
		"Ice":
			_bbIce(ctx, W, H)
		"Lightning":
			_bbLightning(ctx, W, H)
		"Earth":
			_bbEarth(ctx, W, H)
		"Nature":
			_bbNature(ctx, W, H)
		"Plasma":
			_bbPlasma(ctx, W, H)
		"Air":
			_bbAir(ctx, W, H)
		_:
			_bbEarth(ctx, W, H)

# ═══ CHARACTER SPRITE SELECTOR ════════════════════════════════════════════════
func getPlayerCharSprite(charId = null):
	var id = (charId if charId != null else Characters.playerCharId)
	if (JS.eq(id, "battlemage") or JS.eq(id, "warrior")):
		return SpriteData.SPRITE_CHAR_WARRIOR
	if (JS.eq(id, "hexblade") or JS.eq(id, "rogue")):
		return SpriteData.SPRITE_CHAR_ROGUE
	return SpriteData.SPRITE_CHAR_MAGE

# Ground line is at H * 0.55 (hf in BG functions).
# Player stands close-left: bottom at H * 0.90 (deep foreground).
# Enemy stands mid-right: bottom at H * 0.72 (mid-ground — slightly behind, still clearly on earth).
# Multiple enemies fan out along the mid-ground line with slight Y stagger for depth.
func playerSpritePos(W = null, H = null):
	var rows = getPlayerCharSprite()
	var sw = 24 * P_SCALE
	var sh = len(rows) * P_SCALE
	var groundBottom = JS.round(H * 0.9)
	return {"x": JS.round(W * 0.14), "y": groundBottom - sh, "w": sw, "h": sh}

func getEnemySprite(e = null):
	var el = JS.or_((e.get("element") if JS.t(e) else e), "")
	if (el == "Fire" or el == "Lightning"):
		return SpriteData.SPRITE_WIZ_A
	if (el == "Water" or el == "Ice"):
		return SpriteData.SPRITE_WIZ_B
	if (el == "Earth" or el == "Nature"):
		return SpriteData.SPRITE_WIZ_C
	if (el == "Plasma" or el == "Air"):
		return SpriteData.SPRITE_WIZ_D
	return SpriteData.SPRITE_WIZ_A

func enemySpritePos(idx = null, allEnemies = null, W = null, H = null):
	var n = len(allEnemies)
	var e = JS.idx(allEnemies, idx)
	var rows = getEnemySprite(e)
	var sw = 24 * E_SCALE
	var sh = len(rows) * E_SCALE
	var areaX = W * (0.42 if n <= 1 else max(0.04, 0.42 - ((n - 1) * 0.14)))
	var areaW = W * (0.36 if n <= 1 else min(0.92, 0.36 + ((n - 1) * 0.22)))
	var xFrac = (0.5 if n <= 1 else idx / float(max(n - 1, 1)))
	# Alternate depth: even-idx slightly further back (higher Y), odd slightly closer
	var depthOffset = ((0 if (JS.mod(idx, 2)) == 0 else JS.round(H * 0.06)) if n > 1 else 0)
	var groundBottom = JS.round(H * (_horizonFrac() + 0.1)) + depthOffset
	return {"x": JS.round(areaX + (xFrac * (areaW - sw))), "y": groundBottom - sh, "w": sw, "h": sh, "rows": rows}

func summonSpritePos(idx = null, W = null, H = null):
	var sw = 12 * S_SCALE
	var sh = len(SpriteData.SPRITE_TREANT) * S_SCALE
	# Summons stand just to the right of player, on same foreground plane
	var groundBottom = JS.round(H * 0.9)
	return {"x": JS.round((W * 0.26) + (idx * (sw + 6))), "y": groundBottom - sh, "w": sw, "h": sh}

# ═══ HIT FLASH ════════════════════════════════════════════════════════════════
func triggerHitFlash(defenderSide = null, enemyIdx = null):
	if not JS.t(State.combat.get("hitFlashes")):
		State.combat.hitFlashes = []
	State.combat.get("hitFlashes").append({
		"side": defenderSide,
		"idx": (enemyIdx if enemyIdx != null else State.combat.get("activeEnemyIdx")),
		"frames": 10,
		"color": ("#FF3322" if JS.eq(defenderSide, "player") else "#FFAA33"),
	})

# Draws a perspective ground band from horizon line to player ground line (H*0.90)
# Zone-tinted so it blends with the background scene
func _drawBattleForeground(ctx = null, W = null, H = null):
	var el = (State.currentZoneElement if (true and JS.t(State.currentZoneElement)) else State.playerElement)
	var eY = JS.round(H * _horizonFrac())
	var pY = JS.round(H * 0.9)
	var fh = pY - eY
	var tk = JS.dateNow()
	# ── Ground gradient ──────────────────────────────────────────────────────────
	var grads = {
		"Fire": ["#180602", "#200a04", "#180402"],
		"Water": ["#1a3858", "#0e2640", "#0a1e30"],
		"Ice": ["#b8d4ec", "#cce0f4", "#a8c8e0"],
		"Lightning": ["#100e24", "#18162e", "#0c0a1a"],
		"Earth": ["#3d2208", "#522e10", "#3a2008"],
		"Nature": ["#0e2808", "#1a3e0c", "#122e06"],
		"Plasma": ["#180330", "#200438", "#100224"],
		"Air": ["#8898b4", "#9aaac4", "#7888a4"],
	}
	var gc = JS.or_(JS.idx(grads, el), grads.get("Earth"))
	var gg = ctx.createLinearGradient(0, eY, 0, pY)
	gg.addColorStop(0, JS.idx(gc, 0))
	gg.addColorStop(0.5, JS.idx(gc, 1))
	gg.addColorStop(1, JS.idx(gc, 2))
	ctx.fillStyle = gg
	ctx.fillRect(0, eY, W, fh)
	ctx.fillStyle = "rgba(255,255,255,0.06)"
	ctx.fillRect(0, eY, W, 1)
	# ── Zone-specific foreground ─────────────────────────────────────────────────
	match el:
		"Fire":
			# Surface volcanic rock chunks
			for i in range(28):
				var rx = JS.mod((i * 173) + 31, W)
				var ry = eY + JS.round((((JS.mod((i * 97) + 13, 90)) / 90.0) * fh) * 0.85)
				var rw = 4 + ((JS.mod(i, 5)) * 2)
				ctx.fillStyle = ("#2a0e04" if (JS.mod(i, 3)) == 0 else ("#1e0a02" if (JS.mod(i, 3)) == 1 else "#300e04"))
				ctx.fillRect(rx, ry, rw, 2 + (JS.mod(i, 3)))
				ctx.fillStyle = "#3a1006"
				ctx.fillRect(rx, ry, rw, 1)
			# Lava crack fissures
			for i in range(7):
				var cx = JS.mod((i * 211) + 53, W)
				var cy = eY + JS.round((0.12 + (i * 0.1)) * fh)
				var len_ = 20 + ((JS.mod(i, 4)) * 12)
				var glow = 0.4 + (0.4 * sin((tk * 0.008) + i))
				ctx.strokeStyle = "rgba(255," + JS.s(JS.round(50 + (40 * glow))) + ",0," + JS.toFixed(glow, 2) + ")"
				ctx.lineWidth = 2
				ctx.beginPath()
				ctx.moveTo(cx, cy)
				ctx.lineTo(cx + ((len_ if JS.t(JS.mod(i, 2)) else -len_) * 0.7), (cy + 3) + (JS.mod(i, 3)))
				ctx.stroke()
				ctx.strokeStyle = "rgba(255," + JS.s(JS.round(20 + (30 * glow))) + ",0," + JS.toFixed(glow * 0.45, 2) + ")"
				ctx.lineWidth = 1
				ctx.beginPath()
				ctx.moveTo(cx + (4 if JS.t(JS.mod(i, 2)) else -4), cy + 2)
				ctx.lineTo(cx + (len_ * 0.4 if JS.t(JS.mod(i, 2)) else (-len_) * 0.4), cy + 6)
				ctx.stroke()
				ctx.fillStyle = "rgba(255," + JS.s(JS.round(80 + (60 * glow))) + ",0," + JS.toFixed(glow * 0.6, 2) + ")"
				ctx.fillRect(cx - 1, cy - 1, 3, 3)
			# Foreground volcanic rocks
			for _e7 in JS.iter([[W * 0.22, pY - 6], [W * 0.5, pY - 8], [W * 0.75, pY - 5], [W * 0.88, pY - 7]]):
				var rx = JS.idx(_e7, 0)
				var ry = JS.idx(_e7, 1)
				ctx.fillStyle = "#1c0806"
				ctx.fillRect(JS.round(rx) - 7, JS.round(ry) - 4, 14, 7)
				ctx.fillStyle = "#280e08"
				ctx.fillRect(JS.round(rx) - 7, JS.round(ry) - 4, 14, 2)
				ctx.fillStyle = "rgba(255,60,0," + JS.toFixed(0.3 + (0.2 * sin((tk * 0.007) + rx)), 2) + ")"
				ctx.fillRect(JS.round(rx) - 2, JS.round(ry), 5, 1)
			# Ash drift
			for i in range(8):
				var ap = JS.mod((tk * 0.0003) + (i * 0.17), 1)
				var ax = (JS.mod((i * 197) + 23, W)) + JS.round(sin((tk * 0.001) + i) * 5)
				var ay = eY + JS.round((ap * fh) * 0.9)
				var aa = sin(ap * PI) * 0.3
				if aa < 0.04:
					continue
				ctx.fillStyle = "rgba(70,35,15," + JS.toFixed(aa, 2) + ")"
				ctx.fillRect(ax, ay, 2, 1)
		"Water":
			# Sandy beach — gradient from wet (top) to dry sand (bottom)
			var sandG = ctx.createLinearGradient(0, eY, 0, pY)
			sandG.addColorStop(0, "#1a3050")
			sandG.addColorStop(0.4, "#7a6a38")
			sandG.addColorStop(1, "#c0a850")
			ctx.fillStyle = sandG
			ctx.fillRect(0, eY, W, fh)
			# Sand grain texture
			for i in range(35):
				var sx = JS.mod((i * 173) + 41, W)
				var sy = eY + JS.round(((JS.mod((i * 97) + 7, 90)) / 90.0) * fh)
				ctx.fillStyle = ("rgba(180,160,80,0.3)" if (JS.mod(i, 4)) == 0 else "rgba(100,80,30,0.2)")
				ctx.fillRect(sx, sy, 2 + (JS.mod(i, 3)), 1)
			# Wet sand shimmer band
			var wetY = eY + JS.round(fh * 0.35)
			var wetG = ctx.createLinearGradient(0, wetY, 0, wetY + JS.round(fh * 0.18))
			wetG.addColorStop(0, "rgba(60,120,180,0.25)")
			wetG.addColorStop(1, "rgba(60,120,180,0)")
			ctx.fillStyle = wetG
			ctx.fillRect(0, wetY, W, JS.round(fh * 0.18))
			# Tide wave lines
			for i in range(4):
				var wy = wetY + (i * JS.round(fh * 0.04))
				var phase = (tk * 0.002) + (i * 0.9)
				ctx.fillStyle = "rgba(100,180,220," + JS.toFixed(0.14 - (i * 0.03), 2) + ")"
				for x in range(ceili(W)):
					if sin((x * 0.05) + phase) > 0.75:
						ctx.fillRect(x, wy, 1, 2)
			# Shells and pebbles
			var _arr9 = JS.iter([[W * 0.15, pY - 5], [W * 0.38, pY - 4], [W * 0.55, pY - 6], [W * 0.7, pY - 4], [W * 0.85, pY - 5]])
			for i in range(len(_arr9)):
				var _e8 = _arr9[i]
				var rx = JS.idx(_e8, 0)
				var ry = JS.idx(_e8, 1)
				ctx.fillStyle = ("#c8b060" if (JS.mod(i, 2)) == 0 else "#e0c880")
				ctx.beginPath()
				ctx.ellipse(JS.round(rx), JS.round(ry), 4 + (JS.mod(i, 3)), 2, 0, 0, PI * 2)
				ctx.fill()
		"Ice":
			# Snow surface
			var snowG = ctx.createLinearGradient(0, eY, 0, pY)
			snowG.addColorStop(0, "#a8c4dc")
			snowG.addColorStop(0.5, "#c0d8f0")
			snowG.addColorStop(1, "#d8ecff")
			ctx.fillStyle = snowG
			ctx.fillRect(0, eY, W, fh)
			# Snow sparkle
			for i in range(40):
				var sx = JS.mod((i * 173) + 31, W)
				var sy = eY + JS.round(((JS.mod((i * 97) + 13, 90)) / 90.0) * fh)
				var bright = 0.3 + (0.5 * sin((tk * 0.005) + (i * 0.9)))
				ctx.fillStyle = "rgba(255,255,255," + JS.toFixed(bright, 2) + ")"
				ctx.fillRect(sx, sy, (3 if (JS.mod(i, 9)) == 0 else 2), (3 if (JS.mod(i, 9)) == 0 else 2))
			# Horizon icicles
			for i in range(18):
				var ix = JS.mod((i * 97) + 41, W)
				var ih = 5 + ((JS.mod(i, 6)) * 3)
				ctx.fillStyle = "rgba(140,200,230,0.75)"
				ctx.fillRect(ix - 1, eY, 2, ih)
				ctx.fillStyle = "rgba(200,235,255,0.55)"
				ctx.fillRect(ix, eY, 1, ih - 2)
			# Ice crack patterns on surface
			for i in range(10):
				var icx = JS.mod((i * 211) + 41, W)
				var icy = eY + JS.round((((JS.mod((i * 89) + 17, 85)) / 85.0) * fh) * 0.7)
				ctx.strokeStyle = "rgba(160,210,240,0.35)"
				ctx.lineWidth = 1
				ctx.beginPath()
				ctx.moveTo(icx, icy)
				ctx.lineTo(icx + (14 if JS.t(JS.mod(i, 2)) else -12), (icy + 5) + (JS.mod(i, 4)))
				ctx.stroke()
			# Foreground snow drifts
			for _e10 in JS.iter([[W * 0.1, pY], [W * 0.4, pY], [W * 0.65, pY], [W * 0.9, pY]]):
				var dx = JS.idx(_e10, 0)
				var dy = JS.idx(_e10, 1)
				var dg = ctx.createRadialGradient(JS.round(dx), JS.round(dy), 2, JS.round(dx), JS.round(dy), JS.round(W * 0.09))
				dg.addColorStop(0, "rgba(240,250,255,0.5)")
				dg.addColorStop(1, "transparent")
				ctx.fillStyle = dg
				ctx.fillRect(JS.round(dx) - JS.round(W * 0.09), JS.round(dy) - 10, JS.round(W * 0.18), 18)
		"Lightning":
			# Scorched cracked earth
			for i in range(22):
				var rx = JS.mod((i * 173) + 31, W)
				var ry = eY + JS.round((((JS.mod((i * 97) + 13, 90)) / 90.0) * fh) * 0.85)
				ctx.strokeStyle = "#1e1838"
				ctx.lineWidth = 1
				ctx.beginPath()
				ctx.moveTo(rx, ry)
				ctx.lineTo(rx + (((5 + (JS.mod(i, 5))) * 3 if JS.t(JS.mod(i, 2)) else (-(5 + (JS.mod(i, 5)))) * 3) * 0.6), (ry + 2) + (JS.mod(i, 3)))
				ctx.stroke()
			# Electric ground veins
			for i in range(5):
				var vx = JS.mod((i * 211) + 53, W)
				var vy = eY + JS.round((0.12 + (i * 0.14)) * fh)
				var glow = 0.35 + (0.4 * sin((tk * 0.009) + (i * 1.3)))
				ctx.strokeStyle = "rgba(200,180,255," + JS.toFixed(glow, 2) + ")"
				ctx.lineWidth = 1
				ctx.beginPath()
				ctx.moveTo(vx, vy)
				for s in range(5):
					ctx.lineTo(vx + (((1 if JS.t(JS.mod(i, 2)) else -1) * s) * 8), (vy + (s * 2)) + (JS.mod((s * 7) + i, 3)))
				ctx.stroke()
				if (JS.mod(tk, 900)) < 140:
					ctx.fillStyle = "rgba(220,200,60," + JS.toFixed(glow * 0.7, 2) + ")"
					ctx.fillRect(vx - 1, vy - 1, 3, 3)
			# Broken rubble
			for _e11 in JS.iter([[W * 0.18, pY - 6], [W * 0.45, pY - 9], [W * 0.68, pY - 6], [W * 0.84, pY - 7]]):
				var rx = JS.idx(_e11, 0)
				var ry = JS.idx(_e11, 1)
				ctx.fillStyle = "#1a1630"
				ctx.fillRect(JS.round(rx) - 6, JS.round(ry) - 3, 12, 6)
				ctx.fillStyle = "#24203c"
				ctx.fillRect(JS.round(rx) - 6, JS.round(ry) - 3, 12, 2)
			# Rain streaks
			for i in range(14):
				var rp = JS.mod((tk * 0.0013) + (i * 0.14), 1)
				var rx2 = JS.mod((i * 211) + 57, W)
				var ry2 = eY + JS.round((rp * fh) * 1.1)
				var ra = sin(rp * PI) * 0.18
				if (ra < 0.02 or ry2 > pY):
					continue
				ctx.fillStyle = "rgba(140,160,220," + JS.toFixed(ra, 2) + ")"
				ctx.fillRect(rx2, ry2, 1, 5)
		"Earth":
			# Rocky soil
			for i in range(30):
				var rx = JS.mod((i * 173) + 31, W)
				var ry = eY + JS.round((((JS.mod((i * 97) + 13, 90)) / 90.0) * fh) * 0.85)
				var rw = 5 + ((JS.mod(i, 6)) * 3)
				var rh = 3 + (JS.mod(i, 3))
				ctx.fillStyle = ("#6a4020" if (JS.mod(i, 3)) == 0 else ("#5a3218" if (JS.mod(i, 3)) == 1 else "#7a5030"))
				ctx.fillRect(rx, ry, rw, rh)
				ctx.fillStyle = "#8a6040"
				ctx.fillRect(rx, ry, rw, 1)
				ctx.fillStyle = "#2a1008"
				ctx.fillRect(rx + rw, ry, 2, rh)
			# Rock strata lines
			for i in range(3):
				var sy = eY + JS.round(fh * (0.22 + (i * 0.2)))
				ctx.strokeStyle = "rgba(40,20,8,0.30)"
				ctx.lineWidth = 1
				ctx.beginPath()
				ctx.moveTo(0, sy)
				ctx.lineTo(W * (0.7 + (0.2 * sin(i * 1.9))), sy)
				ctx.stroke()
			# Foreground rocks
			var _arr13 = JS.iter([[W * 0.12, pY - 7], [W * 0.35, pY - 10], [W * 0.6, pY - 7], [W * 0.8, pY - 9], [W * 0.92, pY - 6]])
			for i in range(len(_arr13)):
				var _e12 = _arr13[i]
				var rx = JS.idx(_e12, 0)
				var ry = JS.idx(_e12, 1)
				var rw2 = 10 + (i * 3)
				var rh2 = 5 + (i * 2)
				ctx.fillStyle = ("#5a3818" if (JS.mod(i, 2)) == 0 else "#4a2c10")
				ctx.fillRect(JS.round(rx) - JS.round(rw2 / 2.0), JS.round(ry) - rh2, rw2, rh2)
				ctx.fillStyle = "#7a5030"
				ctx.fillRect(JS.round(rx) - JS.round(rw2 / 2.0), JS.round(ry) - rh2, rw2, 2)
				ctx.fillStyle = "#2a1808"
				ctx.fillRect((JS.round(rx) + JS.round(rw2 / 2.0)) - 2, JS.round(ry) - rh2, 2, rh2)
			# Dust drift
			for i in range(5):
				var dp = JS.mod((tk * 0.0005) + (i * 0.22), 1)
				var dx2 = JS.round((dp * (W + 40)) - 20)
				var dy2 = eY + JS.round(fh * (0.55 + (JS.mod(i * 0.08, 0.3))))
				ctx.fillStyle = "rgba(140,90,40," + JS.toFixed(sin(dp * PI) * 0.18, 2) + ")"
				ctx.fillRect(dx2, dy2, 6 + (i * 2), 1)
		"Nature":
			# Layered forest floor
			var ngG = ctx.createLinearGradient(0, eY, 0, pY)
			ngG.addColorStop(0, "#0e2808")
			ngG.addColorStop(0.35, "#1a3e0c")
			ngG.addColorStop(0.7, "#1e4a10")
			ngG.addColorStop(1, "#162e08")
			ctx.fillStyle = ngG
			ctx.fillRect(0, eY, W, fh)
			# Ground mist at horizon
			var mistG = ctx.createLinearGradient(0, eY, 0, eY + JS.round(fh * 0.22))
			mistG.addColorStop(0, "rgba(140,200,160,0.20)")
			mistG.addColorStop(1, "rgba(100,180,130,0)")
			ctx.fillStyle = mistG
			ctx.fillRect(0, eY, W, JS.round(fh * 0.22))
			# Moss / ground cover
			for i in range(30):
				var mx = JS.mod((i * 173) + 31, W)
				var my = eY + JS.round((((JS.mod((i * 97) + 13, 90)) / 90.0) * fh) * 0.8)
				ctx.fillStyle = ("#264a14" if (JS.mod(i, 3)) == 0 else ("#1e3e10" if (JS.mod(i, 3)) == 1 else "#2e5618"))
				ctx.fillRect(mx, my, 3 + (JS.mod(i, 4)), 2)
			# Scattered grass blades at multiple depths
			for i in range(36):
				var gx = JS.round(((JS.mod((i * 263) + 17, 997)) / 997.0) * W)
				var gy = eY + JS.round((((JS.mod((i * 89) + 11, 88)) / 88.0) * fh) * 0.78)
				var gh = 4 + ((JS.mod(i, 5)) * 2)
				ctx.fillStyle = ("#3a6a1a" if (JS.mod(i, 4)) == 0 else ("#2e5a14" if (JS.mod(i, 4)) == 1 else ("#264e10" if (JS.mod(i, 4)) == 2 else "#1e4010")))
				ctx.fillRect(gx, gy - gh, 1, gh)
				ctx.fillRect(gx + 2, gy - JS.round(gh * 0.8), 1, JS.round(gh * 0.8))
				ctx.fillRect(gx + 4, gy - JS.round(gh * 1.1), 1, JS.round(gh * 1.1))
			# Mossy stones
			for _e14 in JS.iter([[W * 0.08, pY - 5], [W * 0.3, pY - 6], [W * 0.52, pY - 5], [W * 0.72, pY - 7], [W * 0.9, pY - 5]]):
				var sx = JS.idx(_e14, 0)
				var sy = JS.idx(_e14, 1)
				ctx.fillStyle = "#2a3e18"
				ctx.fillRect(JS.round(sx) - 5, JS.round(sy) - 3, 10, 6)
				ctx.fillStyle = "#3a5824"
				ctx.fillRect(JS.round(sx) - 5, JS.round(sy) - 3, 10, 2)
			# Foreground tall grass tufts
			for i in range(18):
				var gx2 = JS.round(((JS.mod((i * 211) + 37, 997)) / 997.0) * W)
				var gy2 = pY - 2
				var gh2 = 8 + ((JS.mod(i, 6)) * 3)
				ctx.fillStyle = ("#3a6a1a" if (JS.mod(i, 3)) == 0 else "#2e5618")
				ctx.fillRect(gx2, gy2 - gh2, 1, gh2)
				ctx.fillRect(gx2 + 2, gy2 - JS.round(gh2 * 1.2), 1, JS.round(gh2 * 1.2))
			# Fireflies
			for i in range(6):
				var fx = JS.mod((i * 211) + 37, W)
				var fy = (eY + JS.round(fh * 0.25)) + JS.round(sin((tk * 0.002) + (i * 1.4)) * JS.round(fh * 0.12))
				var glow = 0.4 + (0.55 * sin((tk * 0.007) + (i * 1.3)))
				if glow > 0.5:
					ctx.fillStyle = "rgba(180,255,80," + JS.toFixed(glow * 0.75, 2) + ")"
					ctx.fillRect(fx, fy, 2, 2)
		"Plasma":
			# Crystal floor veins
			for i in range(18):
				var vx = JS.mod((i * 173) + 31, W)
				var vy = eY + JS.round((((JS.mod((i * 97) + 13, 90)) / 90.0) * fh) * 0.8)
				var glow = 0.35 + (0.4 * sin((tk * 0.006) + (i * 1.2)))
				ctx.fillStyle = "rgba(" + JS.s((190 if JS.t(JS.mod(i, 2)) else 130)) + ",40,255," + JS.toFixed(glow, 2) + ")"
				ctx.fillRect(vx, vy, 10 + ((JS.mod(i, 5)) * 4), 2)
			# Void ground rifts
			for i in range(6):
				var rfx = JS.mod((i * 197) + 53, W)
				var rfy = eY + JS.round((0.1 + (i * 0.12)) * fh)
				var rfg = 0.4 + (0.4 * sin((tk * 0.006) + (i * 1.4)))
				ctx.strokeStyle = "rgba(200,60,255," + JS.toFixed(rfg, 2) + ")"
				ctx.lineWidth = 1
				ctx.beginPath()
				ctx.moveTo(rfx, rfy)
				ctx.lineTo((rfx + 16) + (i * 4), rfy + 3)
				ctx.stroke()
				ctx.fillStyle = "rgba(220,80,255," + JS.toFixed(rfg * 0.4, 2) + ")"
				ctx.fillRect(rfx, rfy, 18 + (i * 4), 2)
			# Orbiting motes low on ground
			for i in range(5):
				var angle = ((tk * 0.001) * (1 + (i * 0.15))) + (i * 1.26)
				var ox = JS.round((W * 0.5) + ((cos(angle) * W) * 0.38))
				var oy = eY + JS.round(fh * (0.4 + (sin(angle * 0.5) * 0.15)))
				var oa = 0.4 + (0.4 * sin((tk * 0.007) + i))
				if (((ox < 0 or ox > W) or oy < eY) or oy > pY):
					continue
				ctx.fillStyle = "rgba(" + JS.s((200 if JS.t(JS.mod(i, 2)) else 140)) + ",40,255," + JS.toFixed(oa, 2) + ")"
				ctx.fillRect(ox, oy, 3, 3)
			# Foreground crystal spires
			var _arr16 = JS.iter([[W * 0.1, pY - 4], [W * 0.38, pY - 6], [W * 0.62, pY - 5], [W * 0.88, pY - 4]])
			for ci in range(len(_arr16)):
				var _e15 = _arr16[ci]
				var cx = JS.idx(_e15, 0)
				var cy = JS.idx(_e15, 1)
				var cg = 0.5 + (0.4 * sin((tk * 0.005) + ci))
				ctx.fillStyle = "rgba(" + JS.s((180 if JS.t(JS.mod(ci, 2)) else 140)) + ",60,255," + JS.toFixed(cg, 2) + ")"
				for row in range(8):
					var cw = max(1, 3 - JS.round(row / 3.0))
					ctx.fillRect(JS.round(cx) - cw, JS.round(cy) - row, cw * 2, 1)
		"Air":
			# Wispy cloud wisps across the battlefield floor
			for i in range(5):
				var cp = JS.mod((tk * 0.00025) + (i * 0.22), 1)
				var cx2 = JS.round((cp * (W + 100)) - 50)
				var cy2 = eY + JS.round(fh * (0.08 + (JS.mod(i * 0.16, 0.5))))
				var cw2 = 50 + (i * 18)
				var clg = ctx.createLinearGradient(cx2, cy2, cx2, cy2 + 14)
				clg.addColorStop(0, "rgba(180,200,230," + JS.toFixed(0.14 - (i * 0.02), 2) + ")")
				clg.addColorStop(1, "transparent")
				ctx.fillStyle = clg
				ctx.fillRect(JS.round(cx2), cy2, cw2, 14)
				ctx.fillRect(JS.round(cx2) + 6, cy2 - 5, cw2 - 12, 8)
			# Stars visible through cloud gaps
			for i in range(10):
				var sx2 = JS.mod((i * 173) + 51, W)
				var sy2 = eY + JS.round((((JS.mod((i * 97) + 11, 80)) / 80.0) * fh) * 0.55)
				var bright = 0.15 + (0.2 * sin((tk * 0.004) + (i * 0.8)))
				ctx.fillStyle = "rgba(220,230,255," + JS.toFixed(bright, 2) + ")"
				ctx.fillRect(sx2, sy2, 1, 1)
			# Wind streaks
			for i in range(5):
				var wp = JS.mod((tk * 0.00014) + (i * 0.22), 1)
				var wy2 = eY + JS.round(fh * (0.55 + (JS.mod(i * 0.09, 0.32))))
				var wx2 = JS.round(((wp * W) * 1.3) - (W * 0.15))
				ctx.globalAlpha = (1 - wp) * 0.1
				ctx.fillStyle = "#c0d4f0"
				ctx.fillRect(wx2, wy2, JS.round(W * 0.12), 1)
			ctx.globalAlpha = 1
	ctx.fillStyle = "rgba(255,255,255,0.04)"
	ctx.fillRect(0, pY - 1, W, 1)

# ═══ FLOATING AURA (deck mode) ════════════════════════════════════════════════
# Drawn beneath the enemy sprite when they're levitating above the horizon.
func _drawFloatAura(ctx = null, cx = null, cy = null, r = null, element = null, t = null):
	var el = JS.idx(JS.split(JS.or_(element, ""), "/"), 0)
	ctx.save()
	match el:
		"Fire":
			# Pulsing ember ring
			var pulse = 0.55 + (0.3 * sin(t * 0.11))
			var g = ctx.createRadialGradient(cx, cy, r * 0.1, cx, cy, r)
			g.addColorStop(0, "rgba(255,120,0," + JS.s(pulse) + ")")
			g.addColorStop(0.55, "rgba(220,50,0," + JS.s(pulse * 0.6) + ")")
			g.addColorStop(1, "rgba(180,20,0,0)")
			ctx.fillStyle = g
			ctx.beginPath()
			ctx.ellipse(cx, cy, r, r * 0.28, 0, 0, PI * 2)
			ctx.fill()
			# Ember sparks orbiting
			for i in range(5):
				var a = JS.mod((t * 0.04) + (i * 1.26), PI * 2)
				var sx = cx + ((cos(a) * r) * 0.8)
				var sy = cy + ((sin(a) * r) * 0.22)
				var bright = 0.5 + (0.5 * sin((t * 0.09) + (i * 1.7)))
				ctx.fillStyle = "rgba(255," + JS.s(JS.round(80 + (80 * bright))) + ",0," + JS.toFixed(bright, 2) + ")"
				ctx.fillRect(JS.round(sx), JS.round(sy), 2, 2)
		"Water":
			# Rippling water rings
			for ring in range(3):
				var phase = JS.mod((t * 0.05) + (ring * 0.7), 1)
				var rr = r * (0.4 + (phase * 0.6))
				var alpha = (1 - phase) * 0.55
				ctx.strokeStyle = "rgba(80,180,220," + JS.toFixed(alpha, 2) + ")"
				ctx.lineWidth = 1.5
				ctx.beginPath()
				ctx.ellipse(cx, cy, rr, rr * 0.25, 0, 0, PI * 2)
				ctx.stroke()
		"Ice":
			# Snowflake arms radiating out
			var numArms = 6
			ctx.strokeStyle = "rgba(180,230,255,0.7)"
			ctx.lineWidth = 1
			for i in range(ceili(numArms)):
				var a = (((i / float(numArms)) * PI) * 2) + (t * 0.012)
				var x1 = cx + ((cos(a) * r) * 0.15)
				var y1 = cy + ((sin(a) * r) * 0.04)
				var x2 = cx + ((cos(a) * r) * 0.9)
				var y2 = cy + ((sin(a) * r) * 0.24)
				ctx.beginPath()
				ctx.moveTo(x1, y1)
				ctx.lineTo(x2, y2)
				ctx.stroke()
				# crossbars
				var mx = cx + ((cos(a) * r) * 0.55)
				var my = cy + ((sin(a) * r) * 0.15)
				var pa = a + (PI * 0.5)
				ctx.beginPath()
				ctx.moveTo(mx + ((cos(pa) * r) * 0.12), my + ((sin(pa) * r) * 0.03))
				ctx.lineTo(mx - ((cos(pa) * r) * 0.12), my - ((sin(pa) * r) * 0.03))
				ctx.stroke()
			# Glow disk
			var ig = ctx.createRadialGradient(cx, cy, 0, cx, cy, r * 0.5)
			ig.addColorStop(0, "rgba(200,240,255,0.35)")
			ig.addColorStop(1, "rgba(160,210,255,0)")
			ctx.fillStyle = ig
			ctx.beginPath()
			ctx.ellipse(cx, cy, r * 0.5, r * 0.13, 0, 0, PI * 2)
			ctx.fill()
		"Lightning":
			# Electric arc ring with crackling spokes
			var arcAlpha = 0.5 + (0.4 * sin(t * 0.18))
			ctx.strokeStyle = "rgba(180,160,255," + JS.toFixed(arcAlpha, 2) + ")"
			ctx.lineWidth = 1.5
			ctx.beginPath()
			ctx.ellipse(cx, cy, r, r * 0.26, 0, 0, PI * 2)
			ctx.stroke()
			# Lightning spokes
			for i in range(6):
				if (JS.mod(t + (i * 7), 12)) > 4:
					continue
				var a = (((i / 6.0) * PI) * 2) + (t * 0.03)
				ctx.strokeStyle = "rgba(220,210,255,0.85)"
				ctx.lineWidth = 1
				ctx.beginPath()
				ctx.moveTo(cx + ((cos(a) * r) * 0.2), cy + ((sin(a) * r) * 0.05))
				ctx.lineTo(cx + ((cos(a + 0.15) * r) * 0.7), cy + ((sin(a + 0.15) * r) * 0.18))
				ctx.lineTo(cx + ((cos(a) * r) * 0.95), cy + ((sin(a) * r) * 0.25))
				ctx.stroke()
		"Earth":
			# Floating stone disk
			var eg = ctx.createRadialGradient(cx, cy, r * 0.1, cx, cy, r)
			eg.addColorStop(0, "rgba(110,70,30,0.75)")
			eg.addColorStop(0.6, "rgba(80,50,20,0.5)")
			eg.addColorStop(1, "rgba(60,35,10,0)")
			ctx.fillStyle = eg
			ctx.beginPath()
			ctx.ellipse(cx, cy, r, r * 0.27, 0, 0, PI * 2)
			ctx.fill()
			# Rock cracks
			ctx.strokeStyle = "rgba(50,30,8,0.6)"
			ctx.lineWidth = 1
			for i in range(4):
				var a = (((i / 4.0) * PI) * 2) + 0.4
				ctx.beginPath()
				ctx.moveTo(cx + ((cos(a) * r) * 0.15), cy + ((sin(a) * r) * 0.04))
				ctx.lineTo(cx + ((cos(a + 0.3) * r) * 0.7), cy + ((sin(a + 0.3) * r) * 0.19))
				ctx.stroke()
		"Nature":
			# Vine/leaf circle
			var ng = ctx.createRadialGradient(cx, cy, 0, cx, cy, r)
			ng.addColorStop(0, "rgba(60,160,40,0.4)")
			ng.addColorStop(1, "rgba(30,100,15,0)")
			ctx.fillStyle = ng
			ctx.beginPath()
			ctx.ellipse(cx, cy, r, r * 0.26, 0, 0, PI * 2)
			ctx.fill()
			# Leaf pips orbiting
			for i in range(6):
				var a = JS.mod((t * 0.025) + (i * 1.047), PI * 2)
				var lx = cx + ((cos(a) * r) * 0.78)
				var ly = cy + ((sin(a) * r) * 0.21)
				ctx.fillStyle = ("rgba(80,180,40,0.75)" if (JS.mod(i, 2)) == 0 else "rgba(50,140,25,0.6)")
				ctx.fillRect(JS.round(lx) - 1, JS.round(ly) - 1, 3, 3)
		"Plasma":
			# Rotating dual-ring
			for ring in range(2):
				var spin = t * (0.05 if ring == 0 else -0.03)
				var rr = r * (1.0 if ring == 0 else 0.55)
				var alpha = 0.5 + (0.3 * sin((t * 0.1) + ring))
				ctx.strokeStyle = ("rgba(180,60,255," + JS.toFixed(alpha, 2) + ")" if ring == 0 else "rgba(120,220,255," + JS.toFixed(alpha, 2) + ")")
				ctx.lineWidth = (2 if ring == 0 else 1)
				ctx.beginPath()
				ctx.ellipse(cx + (cos(spin) * 2), cy + ((sin(spin) * r) * 0.04), rr, rr * 0.25, spin * 0.1, 0, PI * 2)
				ctx.stroke()
		"Air":
			# Swirling wind spiral
			for i in range(4):
				var a = JS.mod((t * 0.06) + (i * 1.57), PI * 2)
				var rr = r * (0.3 + (i * 0.18))
				var alpha = 0.2 + (0.15 * sin((t * 0.08) + i))
				ctx.strokeStyle = "rgba(200,220,240," + JS.toFixed(alpha, 2) + ")"
				ctx.lineWidth = 1
				ctx.beginPath()
				ctx.ellipse(cx, cy, rr, rr * 0.25, a, 0, PI * 1.4)
				ctx.stroke()
		_:
			# Neutral: simple soft glow
			var dg = ctx.createRadialGradient(cx, cy, 0, cx, cy, r)
			dg.addColorStop(0, "rgba(200,180,120,0.45)")
			dg.addColorStop(1, "rgba(160,130,80,0)")
			ctx.fillStyle = dg
			ctx.beginPath()
			ctx.ellipse(cx, cy, r, r * 0.26, 0, 0, PI * 2)
			ctx.fill()
	ctx.restore()

func renderBattlefield():
	if JS.hooks.has("renderBattlefield"):
		return JS.run_hook("renderBattlefield", [])
	var canvas = document.getElementById("battle-canvas")
	if (not JS.t(canvas) or not JS.t(canvas.get("width"))):
		return
	var ctx = canvas.getContext("2d")
	var W = canvas.width
	var H = canvas.height
	_battleFrame += 1
	var t = _battleFrame
	ctx.clearRect(0, 0, W, H)
	drawBattleBG(ctx, W, H)
	# ── Foreground ground band (between enemy ground line and player ground line) ──
	# Gives both fighters visible terrain to stand on
	_drawBattleForeground(ctx, W, H)
	var allE = JS.or_(State.combat.get("enemies"), [])
	# ── Player idle animation ──
	# Gentle bob + very subtle lean (breathe cycle ~2s at 60fps)
	var playerBob = JS.round(sin(t * 0.055) * 2)
	# ±2px vertical
	var playerLean = JS.round(sin(t * 0.028) * 1)
	# ±1px horizontal drift
	var pp = playerSpritePos(W, H)
	var px = pp.get("x") + playerLean
	var py = pp.get("y") + playerBob
	ctx.save()
	ctx.globalAlpha = 0.28 - (abs(playerBob) * 0.02)
	ctx.fillStyle = "#000"
	ctx.beginPath()
	ctx.ellipse(px + (pp.get("w") / 2.0), (pp.get("y") + pp.get("h")) + 3, pp.get("w") * 0.38, 5, 0, 0, PI * 2)
	ctx.fill()
	ctx.restore()
	var rows = getPlayerCharSprite()
	var colorMap = Characters.getWizColorMap()
	JS.drawPixelRows(ctx, rows, px, py, P_SCALE, colorMap, 24)
	# ── Enemies ──
	var _arr17 = JS.iter(allE)
	for i in range(len(_arr17)):
		var e = _arr17[i]
		var ep = enemySpritePos(i, allE, W, H)
		var ePal = getElemPal(JS.or_(e.get("element"), "Neutral"))
		# Enemy sway — out of phase with player, slightly faster, each enemy offset
		var phaseOff = i * 1.3
		var enemyBob = (JS.round(sin((t * 0.07) + phaseOff) * 2) if JS.t(e.get("alive")) else 0)
		var enemySway = (JS.round(sin((t * 0.04) + phaseOff) * 1) if JS.t(e.get("alive")) else 0)
		var ex = ep.get("x") + enemySway
		var ey = ep.get("y") + enemyBob
		if JS.t(e.get("alive")):
			ctx.save()
			ctx.globalAlpha = 0.22
			ctx.fillStyle = "#000"
			ctx.beginPath()
			ctx.ellipse(ep.get("x") + (ep.get("w") / 2.0), (ep.get("y") + ep.get("h")) + 3, ep.get("w") * 0.36, 4, 0, 0, PI * 2)
			ctx.fill()
			ctx.restore()
		ctx.save()
		if not JS.t(e.get("alive")):
			ctx.globalAlpha = 0.15
		drawSprite(ctx, getEnemySprite(e), ex, ey, E_SCALE, ePal, 24)
		ctx.restore()
		if JS.t(e.get("alive")):
			# Target arrow
			if JS.eq(i, State.combat.get("targetIdx")):
				ctx.save()
				ctx.fillStyle = "#C8A060"
				ctx.font = "bold 10px monospace"
				ctx.textAlign = "center"
				ctx.fillText("▼", ep.get("x") + (ep.get("w") / 2.0), ep.get("y") - 5)
				ctx.restore()
	# ── Summons ──
	var _arr18 = JS.iter(JS.arr(JS.or_(State.combat.get("summons"), [])).filter(func(s = null): return s.get("hp") > 0))
	for i in range(len(_arr18)):
		var sp = summonSpritePos(i, W, H)
		ctx.save()
		ctx.globalAlpha = 0.22
		ctx.fillStyle = "#000"
		ctx.beginPath()
		ctx.ellipse(sp.get("x") + (sp.get("w") / 2.0), (sp.get("y") + sp.get("h")) + 3, sp.get("w") * 0.32, 4, 0, 0, PI * 2)
		ctx.fill()
		ctx.restore()
		drawSprite(ctx, SpriteData.SPRITE_TREANT, sp.get("x"), sp.get("y"), S_SCALE, getElemPal("Nature"))
	# ── Hit flashes ──
	if (JS.t(State.combat.get("hitFlashes")) and JS.t(len(State.combat.get("hitFlashes")))):
		for flash in JS.iter(State.combat.get("hitFlashes")):
			if flash.get("frames") <= 0:
				continue
			var rect = (playerSpritePos(W, H) if JS.eq(flash.get("side"), "player") else enemySpritePos(flash.get("idx"), allE, W, H))
			ctx.save()
			ctx.globalAlpha = (flash.get("frames") / 10.0) * 0.6
			ctx.fillStyle = flash.get("color")
			ctx.fillRect(rect.get("x"), rect.get("y"), rect.get("w"), rect.get("h"))
			ctx.restore()
			flash.frames -= 1
		State.combat.hitFlashes = JS.arr(State.combat.get("hitFlashes")).filter(func(f = null): return f.get("frames") > 0)
	# ── Spell / effect animations ──
	Animations.tickAnims(ctx, W, H)

func startBattleLoop():
	if JS.t(_battleRAF):
		JS.cancelAnimationFrame(_battleRAF)
	var loop = [null]
	var _fn19 = func():
		renderBattlefield()
		_battleRAF = JS.requestAnimationFrame(loop[0])
	loop[0] = _fn19
	loop[0].call()

func stopBattleLoop():
	if JS.t(_battleRAF):
		JS.cancelAnimationFrame(_battleRAF)
		_battleRAF = null

func initBattleCanvas():
	var canvas = document.getElementById("battle-canvas")
	if not JS.t(canvas):
		return
	var arena = canvas.parentElement
	var w = JS.or_((arena.offsetWidth if JS.t(arena) else 0), 480)
	var h = JS.orf((arena.offsetHeight if JS.t(arena) else 0), func(): return JS.round(w * 0.38))
	canvas.width = w
	canvas.height = max(160, h)
	# Stretch canvas CSS to fill the arena
	canvas.style.width = "100%"
	canvas.style.height = "100%"
	# Re-size on container resize (mobile orientation change, browser bar show/hide)
	if (JS.t(arena) and not JS.t(arena.get("_battleResizeObserver"))):
		var _fn20 = func():
			var nw = JS.or_(arena.get("offsetWidth"), 480)
			var nh = max(160, (arena.get("offsetHeight") if JS.t(arena.get("offsetHeight")) else JS.round(nw * 0.38)))
			if (nw != canvas.width or nh != canvas.height):
				canvas.width = nw
				canvas.height = nh
				UI.renderEnemyCards()
		arena._battleResizeObserver = JSResizeObserver.new(_fn20)
		arena.get("_battleResizeObserver").observe(arena)

var _sprite_pal_cache := {}
