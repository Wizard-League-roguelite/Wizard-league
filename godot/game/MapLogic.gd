# MapLogic — generated from js/logic/map.js by tools/js2gd.js
extends Node

# ── Run Victory Screen ────────────────────────────────────────────────────────
var _victoryFreeplay = false
# ── COMBAT TABS ───────────────────────────────────────────────────────────────
var _activeCombatTab = "actions"
var _logHasNew = false
var canvas = null
var W = 240
var H = 135
var ctx = null
var frame = 0
var FAR_STARS = null
var NEAR_STARS = null
var shoots = null
var ZONE = null

func _boot():
	# ── Global Background Canvas ─────────────────────────────────────────────────
	canvas = document.getElementById("bg-canvas")
	if not JS.t(canvas):
		return
	canvas.width = W
	canvas.height = H
	ctx = canvas.getContext("2d")
	FAR_STARS = mkStars(60, 5, 25, 0.0003, 0.0008, 0.25, 0.55)
	NEAR_STARS = mkStars(30, 8, 40, 0.0005, 0.0012, 0.55, 1.0)
	shoots = []
	# ── Zone configs ──
	ZONE = {
		"Fire": {
			"sky": ["#120300", "#2a0600", "#1a0400"],
			"nebulae": [
				{"x": 60, "y": 22, "rx": 50, "ry": 20, "r": "rgba(200,40,0,", "base": 0.06},
				{"x": 170, "y": 30, "rx": 40, "ry": 16, "r": "rgba(160,20,0,", "base": 0.04},
				{"x": 110, "y": 10, "rx": 30, "ry": 10, "r": "rgba(220,80,0,", "base": 0.05},
			],
			"starCol": "#ff9966",
			"hillCol": "#1a0500",
			"hgCol": "rgba(220,60,0,0.2)",
			"gndCol": "#0e0300",
			"extra": ZONE__Fire__extra,
		},
		"Water": {
			"sky": ["#020c18", "#051828", "#082035"],
			"nebulae": [
				{"x": 50, "y": 18, "rx": 50, "ry": 20, "r": "rgba(20,60,140,", "base": 0.06},
				{"x": 175, "y": 28, "rx": 38, "ry": 15, "r": "rgba(10,80,120,", "base": 0.05},
				{"x": 115, "y": 8, "rx": 28, "ry": 10, "r": "rgba(40,60,160,", "base": 0.04},
			],
			"starCol": "#a0d0ff",
			"hillCol": "#040d1c",
			"hgCol": "rgba(20,100,160,0.18)",
			"gndCol": "#020810",
			"extra": ZONE__Water__extra,
		},
		"Ice": {
			"sky": ["#04081a", "#081228", "#0c1830"],
			"nebulae": [
				{"x": 55, "y": 20, "rx": 50, "ry": 18, "r": "rgba(40,160,200,", "base": 0.05},
				{"x": 175, "y": 30, "rx": 38, "ry": 14, "r": "rgba(60,120,200,", "base": 0.04},
				{"x": 110, "y": 10, "rx": 30, "ry": 10, "r": "rgba(80,200,220,", "base": 0.06},
			],
			"starCol": "#c0e8ff",
			"hillCol": "#8ab8d8",
			"hgCol": "rgba(140,200,255,0.25)",
			"gndCol": "#b0cce0",
			"extra": ZONE__Ice__extra,
		},
		"Lightning": {
			"sky": ["#040210", "#080520", "#0c0828"],
			"nebulae": [
				{"x": 60, "y": 20, "rx": 50, "ry": 18, "r": "rgba(100,60,200,", "base": 0.06},
				{"x": 170, "y": 30, "rx": 40, "ry": 15, "r": "rgba(180,140,20,", "base": 0.04},
				{"x": 112, "y": 10, "rx": 28, "ry": 10, "r": "rgba(60,20,180,", "base": 0.05},
			],
			"starCol": "#e8e0a0",
			"hillCol": "#0a0818",
			"hgCol": "rgba(160,120,20,0.2)",
			"gndCol": "#060410",
			"extra": ZONE__Lightning__extra,
		},
		"Earth": {
			"sky": ["#060302", "#100806", "#18100a"],
			"nebulae": [
				{"x": 60, "y": 22, "rx": 48, "ry": 18, "r": "rgba(100,60,20,", "base": 0.05},
				{"x": 170, "y": 32, "rx": 36, "ry": 14, "r": "rgba(80,40,10,", "base": 0.04},
				{"x": 112, "y": 10, "rx": 28, "ry": 10, "r": "rgba(120,80,20,", "base": 0.04},
			],
			"starCol": "#e0c898",
			"hillCol": "#1a0c04",
			"hgCol": "rgba(140,80,20,0.2)",
			"gndCol": "#0c0602",
			"extra": ZONE__Earth__extra,
		},
		"Nature": {
			"sky": ["#020a04", "#041408", "#061a0a"],
			"nebulae": [
				{"x": 60, "y": 22, "rx": 50, "ry": 18, "r": "rgba(20,100,30,", "base": 0.06},
				{"x": 170, "y": 30, "rx": 38, "ry": 14, "r": "rgba(10,80,40,", "base": 0.05},
				{"x": 110, "y": 10, "rx": 30, "ry": 10, "r": "rgba(40,120,20,", "base": 0.04},
			],
			"starCol": "#a0e0a0",
			"hillCol": "#030e05",
			"hgCol": "rgba(20,100,10,0.2)",
			"gndCol": "#020804",
			"extra": ZONE__Nature__extra,
		},
		"Plasma": {
			"sky": ["#060010", "#0e0020", "#180030"],
			"nebulae": [
				{"x": 60, "y": 20, "rx": 52, "ry": 20, "r": "rgba(160,0,220,", "base": 0.07},
				{"x": 170, "y": 28, "rx": 40, "ry": 15, "r": "rgba(100,0,200,", "base": 0.06},
				{"x": 112, "y": 10, "rx": 30, "ry": 10, "r": "rgba(200,40,220,", "base": 0.05},
			],
			"starCol": "#dd88ff",
			"hillCol": "#0e0020",
			"hgCol": "rgba(180,20,220,0.25)",
			"gndCol": "#0a0018",
			"extra": ZONE__Plasma__extra,
		},
		"Air": {
			"sky": ["#060c18", "#0c1828", "#101e30"],
			"nebulae": [
				{"x": 60, "y": 22, "rx": 50, "ry": 18, "r": "rgba(120,160,220,", "base": 0.05},
				{"x": 175, "y": 30, "rx": 38, "ry": 14, "r": "rgba(80,120,200,", "base": 0.04},
				{"x": 110, "y": 10, "rx": 30, "ry": 10, "r": "rgba(160,190,230,", "base": 0.04},
			],
			"starCol": "#b8d0f0",
			"hillCol": "#6878a0",
			"hgCol": "rgba(160,200,240,0.18)",
			"gndCol": "#8898b0",
			"extra": ZONE__Air__extra,
		},
		"Neutral": {
			"sky": ["#020210", "#070520", "#110e2a"],
			"nebulae": [
				{"x": 60, "y": 22, "rx": 45, "ry": 18, "r": "rgba(80,40,120,", "base": 0.04},
				{"x": 170, "y": 35, "rx": 35, "ry": 14, "r": "rgba(30,60,120,", "base": 0.05},
				{"x": 110, "y": 12, "rx": 30, "ry": 10, "r": "rgba(100,30,80,", "base": 0.03},
			],
			"starCol": "#c8c0f0",
			"hillCol": "#0a0818",
			"hgCol": "rgba(60,40,120,0.12)",
			"gndCol": "#060412",
			"extra": ZONE__Neutral__extra,
		},
	}
	drawScene()

# ===============================
func showGameOver():
	var frame = [null]
	var stopped = [null]
	var drawScene = [null]
	BetweenRuns._lastRunPhos = Artifacts.saveRunStats()
	Analytics.sendRunAnalytics("loss")
	BetweenRuns.showBetweenRuns()
	# routes to between-runs-screen
	# Canvas pixel art scene
	var canvas = document.getElementById("gameover-canvas")
	if not JS.t(canvas):
		return
	var W = 160
	var H = 90
	canvas.width = W
	canvas.height = H
	canvas.style.width = "100%"
	canvas.style.maxWidth = "480px"
	var ctx = canvas.getContext("2d")
	frame[0] = 0
	stopped[0] = false
	var _fn1 = func():
		stopped[0] = true
	canvas._goStop = _fn1
	var _fn7 = func():
		if stopped[0]:
			return
		ctx.fillStyle = "#06060e"
		ctx.fillRect(0, 0, W, H)
		# Stars
		var starPositions = [
			[12, 8],
			[35, 5],
			[58, 12],
			[80, 4],
			[105, 9],
			[128, 6],
			[150, 11],
			[20, 20],
			[70, 18],
			[140, 22],
			[45, 30],
			[95, 25],
			[160, 15],
			[8, 35],
			[130, 30],
		]
		var _arr3 = JS.iter(starPositions)
		for i in range(len(_arr3)):
			var _e2 = _arr3[i]
			var sx = JS.idx(_e2, 0)
			var sy = JS.idx(_e2, 1)
			var twinkle = sin((frame[0] * 0.05) + (i * 1.3))
			ctx.globalAlpha = 0.4 + (twinkle * 0.3)
			ctx.fillStyle = "#ffffff"
			ctx.fillRect(sx, sy, 1, 1)
		ctx.globalAlpha = 1
		# Ground
		ctx.fillStyle = "#1a1018"
		ctx.fillRect(0, H - 18, W, 18)
		ctx.fillStyle = "#0e0a14"
		ctx.fillRect(0, H - 20, W, 2)
		# Cracked ground lines
		ctx.fillStyle = "#120a1a"
		for _e4 in JS.iter([[15, H - 16, 30, 1], [60, H - 14, 20, 1], [100, H - 17, 35, 1], [8, H - 12, 10, 1]]):
			var x = JS.idx(_e4, 0)
			var y = JS.idx(_e4, 1)
			var w = JS.idx(_e4, 2)
			var h = JS.idx(_e4, 3)
			ctx.fillRect(x, y, w, h)
		# Fallen player sprite — lying on side
		var px = 68
		var py = H - 26
		var charRows = (Sprites.getPlayerCharSprite() if JS.t(Sprites.getPlayerCharSprite) else SpriteData.SPRITE_CHAR_MAGE)
		# Draw character sprite rotated 90° via pixel-by-pixel
		var scale_ = 2
		var spriteW = len(JS.idx(charRows, 0))
		var spriteH = len(charRows)
		# Lay sprite on its side — rotate 90deg CW
		for row in range(ceili(spriteH)):
			for col in range(ceili(spriteW)):
				var c = charRows[row][col]
				if not JS.t(c):
					continue
				# Rotated: new col = (spriteH-1-row), new row = col
				var nx = px + (((spriteH - 1) - row) * scale_)
				var ny = py + (col * scale_)
				ctx.fillStyle = c
				ctx.fillRect(nx, ny, scale_, scale_)
		# Grim skull floating
		var skullY = 28 + (sin(frame[0] * 0.04) * 3)
		var skull = [
			[0, 0, 1, 1, 1, 0, 0],
			[0, 1, 1, 1, 1, 1, 0],
			[1, 1, 1, 1, 1, 1, 1],
			[1, 1, 1, 1, 1, 1, 1],
			[1, 1, 1, 1, 1, 1, 1],
			[0, 1, 0, 1, 0, 1, 0],
			[0, 1, 1, 1, 1, 1, 0],
		]
		var sw = 2
		var _arr5 = JS.iter(skull)
		for ry in range(len(_arr5)):
			var row = _arr5[ry]
			var _arr6 = JS.iter(row)
			for cx in range(len(_arr6)):
				var px2 = _arr6[cx]
				if not JS.t(px2):
					continue
				var darkness = sin(frame[0] * 0.06) * 0.15
				ctx.fillStyle = "rgba(200,180,220," + JS.s(0.75 + darkness) + ")"
				ctx.fillRect(40 + (cx * sw), skullY + (ry * sw), sw, sw)
		# Floating ghost wisps
		var wisps = [
			{"ox": 20, "phase": 0.0, "col": "rgba(140,100,200,0.4)"},
			{"ox": 110, "phase": 1.5, "col": "rgba(100,80,180,0.3)"},
			{"ox": 145, "phase": 0.8, "col": "rgba(160,120,220,0.35)"},
		]
		for w in JS.iter(wisps):
			var wy = 40 + (sin((frame[0] * 0.035) + w.phase) * 8)
			ctx.fillStyle = w.col
			ctx.fillRect(w.ox, wy, 4, 6)
			ctx.fillRect(w.ox - 1, wy + 2, 6, 3)
			ctx.fillRect(w.ox + 1, wy + 5, 2, 3)
		# "GAME OVER" text in big pixel-ish font
		var alpha = min(1, frame[0] / 40.0)
		ctx.globalAlpha = alpha
		ctx.fillStyle = "#cc3333"
		ctx.font = "bold 13px \"Cinzel\", serif"
		ctx.textAlign = "center"
		ctx.fillText("GAME  OVER", W / 2.0, 22)
		ctx.globalAlpha = 1
		# Vignette
		var vign = ctx.createRadialGradient(W / 2.0, H / 2.0, H * 0.2, W / 2.0, H / 2.0, H * 0.75)
		vign.addColorStop(0, "rgba(0,0,0,0)")
		vign.addColorStop(1, "rgba(0,0,0,0.6)")
		ctx.fillStyle = vign
		ctx.fillRect(0, 0, W, H)
		frame[0] += 1
		JS.requestAnimationFrame(drawScene[0])
	drawScene[0] = _fn7
	drawScene[0].call()

func showRunVictory():
	_victoryFreeplay = false
	BetweenRuns._lastRunPhos = Artifacts.saveRunStats()
	Analytics.sendRunAnalytics("win")
	# Unlock the Veil on non-sandbox wins (Dark One defeated)
	if not JS.t(Constants.sandboxMode):
		var _vm = Artifacts.getMeta()
		if not JS.t(_vm.get("darkOneDefeated")):
			_vm.darkOneDefeated = true
			Artifacts.saveMeta()
			window._pendingVeilUnlock = true
	# Populate stats panel
	var statsEl = document.getElementById("victory-stats")
	if JS.t(statsEl):
		var phos = JS.or_(BetweenRuns._lastRunPhos, 0)
		statsEl.innerHTML = "<div style=\"color:#aaffaa;font-size:.9rem;text-align:center;margin-bottom:.6rem;letter-spacing:.06em;\">✦ RUN COMPLETE ✦</div>" + "<div style=\"display:grid;grid-template-columns:1fr 1fr;gap:.15rem .8rem;\">" + ("<span style=\"color:#559955;\">Element</span><span style=\"color:#ccffcc;\">" + (JS.or_(State.playerEmoji, "")) + " " + (JS.or_(State.playerElement, "?")) + "</span>") + ("<span style=\"color:#559955;\">Battles</span><span style=\"color:#ccffcc;\">" + JS.s(State.battleNumber) + "</span>") + ("<span style=\"color:#559955;\">Damage Dealt</span><span style=\"color:#ccffcc;\">" + JS.toLocaleString(JS.or_(State._runDmgDealt, 0)) + "</span>") + ("<span style=\"color:#559955;\">Damage Taken</span><span style=\"color:#ccffcc;\">" + JS.toLocaleString(JS.or_(State._runDmgTaken, 0)) + "</span>") + ("<span style=\"color:#559955;\">Gold Earned</span><span style=\"color:#ccffcc;\">" + JS.s(State.player.gold) + "</span>") + ("<span style=\"color:#559955;\">Spells</span><span style=\"color:#ccffcc;\">" + JS.s(len(State.player.spellbook)) + "</span>") + ("<span style=\"color:#559955;\">Phos Earned</span><span style=\"color:#ffdd88;\">✦ " + JS.s(phos) + "</span>") + "</div>"
	UI.showScreen("run-victory-screen")
	_startVictoryCanvas()

func _startVictoryCanvas():
	var frame = [null]
	var stopped = [null]
	var drawScene = [null]
	var canvas = document.getElementById("victory-canvas")
	if not JS.t(canvas):
		return
	var W = 160
	var H = 90
	canvas.width = W
	canvas.height = H
	canvas.style.width = "100%"
	canvas.style.maxWidth = "480px"
	var ctx = canvas.getContext("2d")
	frame[0] = 0
	stopped[0] = false
	var _fn8 = func():
		stopped[0] = true
	canvas._vcStop = _fn8
	# Star positions
	var stars = [
		[12, 8],
		[35, 5],
		[58, 12],
		[80, 4],
		[105, 9],
		[128, 6],
		[150, 11],
		[20, 20],
		[70, 18],
		[140, 22],
		[45, 30],
		[95, 25],
		[160, 15],
		[8, 35],
		[130, 30],
		[50, 42],
		[115, 38],
		[75, 50],
	]
	# Confetti particles
	var _fn9 = func(_u = null, i = null):
		return {
			"x": JS.mod(i * 7.5, 160),
			"y": randf() * 90,
			"vy": 0.4 + (randf() * 0.5),
			"col": JS.idx(["#ffdd44", "#44ffaa", "#ff88cc", "#88ccff", "#ffaa44"], JS.mod(i, 5)),
			"phase": (randf() * PI) * 2,
		}
	var confetti = JS.arrayFrom({"length": 22}, _fn9)
	var _fn14 = func():
		if stopped[0]:
			return
		# Sky
		ctx.fillStyle = "#06180a"
		ctx.fillRect(0, 0, W, H)
		# Stars
		var _arr11 = JS.iter(stars)
		for i in range(len(_arr11)):
			var _e10 = _arr11[i]
			var sx = JS.idx(_e10, 0)
			var sy = JS.idx(_e10, 1)
			var twinkle = sin((frame[0] * 0.05) + (i * 1.3))
			ctx.globalAlpha = 0.4 + (twinkle * 0.3)
			ctx.fillStyle = "#ffffff"
			ctx.fillRect(sx, sy, 1, 1)
		ctx.globalAlpha = 1
		# Ground
		ctx.fillStyle = "#0a2010"
		ctx.fillRect(0, H - 18, W, 18)
		ctx.fillStyle = "#072a10"
		ctx.fillRect(0, H - 20, W, 2)
		# Player sprite — standing upright, slight bob
		var bob = JS.round(sin(frame[0] * 0.07) * 1)
		var charRows = Sprites.getPlayerCharSprite()
		var colorMap = Characters.getWizColorMap()
		var scale_ = 2
		var sprW = 24
		var sprH = len(charRows)
		var sx = floori((W - (sprW * scale_)) / 2.0)
		var sy = ((H - 18) - (sprH * scale_)) + bob
		for r in range(ceili(sprH)):
			for c in range(ceili(sprW)):
				var ch = JS.or_(JS.idx(JS.or_(JS.idx(charRows, r), ""), c), ".")
				var color = null
				if JS.t(colorMap):
					color = JS.idx(colorMap, ch)
				else:
					color = ("#c8a060" if ch != "." else null)
				if not JS.t(color):
					continue
				ctx.fillStyle = color
				ctx.fillRect(sx + (c * scale_), sy + (r * scale_), scale_, scale_)
		# Trophy pixel art (simple crown shape)
		var trophyX = 110
		var trophyY = H - 34
		var glow = 0.7 + (sin(frame[0] * 0.06) * 0.2)
		ctx.globalAlpha = glow
		ctx.fillStyle = "#ffdd44"
		# Cup
		var _arr12 = JS.iter([[1, 0, 1], [1, 1, 1], [0, 1, 0], [0, 1, 0], [1, 1, 1]])
		for ry in range(len(_arr12)):
			var row = _arr12[ry]
			var _arr13 = JS.iter(row)
			for cx in range(len(_arr13)):
				var on = _arr13[cx]
				if JS.t(on):
					ctx.fillRect(trophyX + (cx * 3), trophyY + (ry * 3), 3, 3)
		ctx.globalAlpha = 1
		# Confetti
		for p in JS.iter(confetti):
			p.y += p.vy
			if p.y > H:
				p.y = -4
			var wx = p.x + (sin((frame[0] * 0.04) + p.phase) * 3)
			ctx.fillStyle = p.col
			ctx.globalAlpha = 0.75
			ctx.fillRect(JS.round(wx), JS.round(p.y), 2, 2)
		ctx.globalAlpha = 1
		# "VICTORY" text
		var alpha = min(1, frame[0] / 35.0)
		ctx.globalAlpha = alpha
		ctx.fillStyle = "#66ff88"
		ctx.font = "bold 13px \"Cinzel\", serif"
		ctx.textAlign = "center"
		ctx.fillText("VICTORY", W / 2.0, 20)
		ctx.globalAlpha = 1
		# Vignette
		var vign = ctx.createRadialGradient(W / 2.0, H / 2.0, H * 0.2, W / 2.0, H / 2.0, H * 0.75)
		vign.addColorStop(0, "rgba(0,0,0,0)")
		vign.addColorStop(1, "rgba(0,0,0,0.5)")
		ctx.fillStyle = vign
		ctx.fillRect(0, 0, W, H)
		frame[0] += 1
		JS.requestAnimationFrame(drawScene[0])
	drawScene[0] = _fn14
	drawScene[0].call()

func victoryBackToLobby():
	var vc = document.getElementById("victory-canvas")
	if (JS.t(vc) and JS.t(vc.get("_vcStop"))):
		JS.callm(vc, "_vcStop", [])
	BetweenRuns.showBetweenRuns()

func victoryFreeplay():
	_victoryFreeplay = true
	var vc = document.getElementById("victory-canvas")
	if (JS.t(vc) and JS.t(vc.get("_vcStop"))):
		JS.callm(vc, "_vcStop", [])
	MapCanvas.showMap()

# ── Shop Canvas Animation ─────────────────────────────────────────────────────
func startShopCanvas():
	var frame = [null]
	var stopped = [null]
	var drawScene = [null]
	var canvas = document.getElementById("shop-canvas")
	if not JS.t(canvas):
		return
	if JS.t(canvas.get("_stop")):
		JS.callm(canvas, "_stop", [])
	# stop previous loop
	var W = 160
	var H = 100
	canvas.width = W
	canvas.height = H
	canvas.style.width = "100%"
	var ctx = canvas.getContext("2d")
	frame[0] = 0
	stopped[0] = false
	var _fn15 = func():
		stopped[0] = true
	canvas._stop = _fn15
	# Fixed stars with slow swirl orbit
	var _fn16 = func(_u = null, i = null):
		return {
			"angle": ((i / 28.0) * PI) * 2,
			"r": (18 + ((JS.mod(i, 5)) * 14)) + (randf() * 10),
			"cx": W * 0.52,
			"cy": H * 0.38,
			"size": (2 if (JS.mod(i, 3)) == 0 else 1),
			"speed": 0.0008 + ((JS.mod(i, 4)) * 0.0003),
			"brightness": 0.5 + (randf() * 0.5),
			"phase": (randf() * PI) * 2,
		}
	var STARS = JS.arrayFrom({"length": 28}, _fn16)
	# Shopkeeper sprite (pixel art, ~7×11)
	var KEEPER = [
		[0, 0, "#c8a060", 0, 0],
		[0, "#4a3010", "#c8a060", "#4a3010", 0],
		[0, "#e8c090", "#e8c090", "#e8c090", 0],
		[0, "#e8c090", "#333", "#e8c090", 0],
		[0, "#e8c090", "#c87040", "#e8c090", 0],
		["#2a1a50", "#2a1a50", "#2a1a50", "#2a1a50", "#2a1a50"],
		["#2a1a50", "#c8a030", "#2a1a50", "#c8a030", "#2a1a50"],
		["#2a1a50", "#2a1a50", "#2a1a50", "#2a1a50", "#2a1a50"],
		["#1a1030", "#1a1030", "#1a1030", "#1a1030", "#1a1030"],
		[0, "#c89040", 0, "#c89040", 0],
		[0, "#1a1030", 0, "#1a1030", 0],
	]
	# hat top
	# hat brim
	# face
	# eyes
	# nose/mouth
	# robe top
	# robe trim
	# robe body
	# robe bottom
	# hands
	# feet
	# Lantern flicker particles
	var LANTERN_X = 118
	var LANTERN_Y = 60
	var particles = JS.arrayFrom({"length": 8}, func(_u = null, i = null): return {"x": LANTERN_X, "y": LANTERN_Y, "life": randf(), "speed": 0.3 + (randf() * 0.4), "vx": (randf() - 0.5) * 0.4})
	var _fn22 = func():
		if stopped[0]:
			return
		# Night sky gradient
		var sky = ctx.createLinearGradient(0, 0, 0, H * 0.7)
		sky.addColorStop(0, "#03031a")
		sky.addColorStop(1, "#0c0820")
		ctx.fillStyle = sky
		ctx.fillRect(0, 0, W, H)
		# Swirling stars
		for s in JS.iter(STARS):
			s.angle += s.speed
			var sx = s.cx + (cos(s.angle) * s.r)
			var sy = s.cy + ((sin(s.angle) * s.r) * 0.45)
			# elliptical orbit
			var twinkle = 0.4 + (sin((frame[0] * 0.07) + s.phase) * 0.3)
			ctx.globalAlpha = twinkle * s.brightness
			ctx.fillStyle = "#e8e0ff"
			ctx.fillRect(JS.round(sx), JS.round(sy), s.size, s.size)
		# A few brighter fixed stars
		var _arr18 = JS.iter([[10, 8], [150, 12], [75, 6], [130, 25], [20, 30]])
		for i in range(len(_arr18)):
			var _e17 = _arr18[i]
			var sx = JS.idx(_e17, 0)
			var sy = JS.idx(_e17, 1)
			ctx.globalAlpha = 0.6 + (sin((frame[0] * 0.05) + i) * 0.3)
			ctx.fillStyle = "#ffffff"
			ctx.fillRect(sx, sy, 1, 1)
		ctx.globalAlpha = 1
		# Ground
		ctx.fillStyle = "#120e1c"
		ctx.fillRect(0, H - 20, W, 20)
		ctx.fillStyle = "#0d0a18"
		ctx.fillRect(0, H - 22, W, 2)
		# Ground texture
		ctx.fillStyle = "#1a1428"
		for _e19 in JS.iter([[5, H - 16, 18, 1], [40, H - 14, 12, 1], [80, H - 17, 22, 1], [120, H - 15, 15, 1]]):
			var x = JS.idx(_e19, 0)
			var y = JS.idx(_e19, 1)
			var w = JS.idx(_e19, 2)
			var h = JS.idx(_e19, 3)
			ctx.fillRect(x, y, w, h)
		# ── Tent ──
		# Triangle body
		ctx.fillStyle = "#3a2810"
		ctx.beginPath()
		ctx.moveTo(50, H - 20)
		# left base
		ctx.lineTo(110, H - 20)
		# right base
		ctx.lineTo(80, H - 58)
		# peak
		ctx.closePath()
		ctx.fill()
		# Tent stripes
		ctx.fillStyle = "#2a1c08"
		ctx.beginPath()
		ctx.moveTo(80, H - 58)
		ctx.lineTo(65, H - 20)
		ctx.lineTo(68, H - 20)
		ctx.lineTo(80, H - 54)
		ctx.closePath()
		ctx.fill()
		ctx.beginPath()
		ctx.moveTo(80, H - 58)
		ctx.lineTo(95, H - 20)
		ctx.lineTo(92, H - 20)
		ctx.lineTo(80, H - 54)
		ctx.closePath()
		ctx.fill()
		# Tent outline
		ctx.strokeStyle = "#6a4818"
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.moveTo(50, H - 20)
		ctx.lineTo(80, H - 58)
		ctx.lineTo(110, H - 20)
		ctx.stroke()
		# Tent door (arch)
		ctx.fillStyle = "#0a0618"
		ctx.fillRect(71, H - 34, 18, 14)
		ctx.fillStyle = "#14102a"
		ctx.fillRect(72, H - 35, 16, 2)
		# Tent flag at peak
		var flagY = (H - 60) + (sin(frame[0] * 0.06) * 1)
		ctx.fillStyle = "#c8a030"
		ctx.fillRect(79, flagY - 6, 1, 6)
		ctx.fillStyle = "#e8c050"
		ctx.fillRect(80, flagY - 6, 5, 4)
		# Rope lines from tent peak to ground stakes
		ctx.strokeStyle = "#3a2808"
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.moveTo(80, H - 58)
		ctx.lineTo(40, H - 20)
		ctx.stroke()
		ctx.beginPath()
		ctx.moveTo(80, H - 58)
		ctx.lineTo(120, H - 20)
		ctx.stroke()
		# Stakes
		ctx.fillStyle = "#5a3810"
		ctx.fillRect(38, H - 20, 3, 4)
		ctx.fillRect(118, H - 20, 3, 4)
		# ── Shopkeeper ──
		var kx = 28
		var ky = H - 46
		var bobY = sin(frame[0] * 0.04) * 1
		var S = 3
		var _arr20 = JS.iter(KEEPER)
		for ry in range(len(_arr20)):
			var row = _arr20[ry]
			var _arr21 = JS.iter(row)
			for cx in range(len(_arr21)):
				var col = _arr21[cx]
				if not JS.t(col):
					continue
				ctx.fillStyle = col
				ctx.fillRect(kx + (cx * S), (ky + JS.round(bobY)) + (ry * S), S, S)
		# ── Lantern (hung from tent) ──
		var lx = LANTERN_X
		var ly = LANTERN_Y
		# String
		ctx.strokeStyle = "#4a3010"
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.moveTo(80, H - 58)
		ctx.lineTo(lx, ly - 8)
		ctx.stroke()
		# Lantern body glow
		var flicker = (0.7 + (sin((frame[0] * 0.13) + 1) * 0.2)) + (sin(frame[0] * 0.31) * 0.1)
		var glow = ctx.createRadialGradient(lx, ly, 1, lx, ly, 18)
		glow.addColorStop(0, "rgba(255,200,80," + JS.s(0.35 * flicker) + ")")
		glow.addColorStop(1, "rgba(255,160,20,0)")
		ctx.fillStyle = glow
		ctx.fillRect(lx - 18, ly - 18, 36, 36)
		# Lantern box
		ctx.fillStyle = "rgba(255,180,40," + JS.s(0.9 * flicker) + ")"
		ctx.fillRect(lx - 3, ly - 5, 6, 8)
		ctx.fillStyle = "#5a3800"
		ctx.fillRect(lx - 4, ly - 6, 8, 2)
		ctx.fillRect(lx - 4, ly + 3, 8, 2)
		# Fire particles from lantern
		for p in JS.iter(particles):
			p.life += p.speed * 0.04
			if p.life >= 1:
				p.life = 0
				p.x = lx + ((randf() - 0.5) * 3)
				p.y = ly
				p.vx = (randf() - 0.5) * 0.4
			p.x += p.vx
			p.y = ly - (p.life * 9)
			var a = (1 - p.life) * 0.8
			ctx.globalAlpha = a
			ctx.fillStyle = ("#ffdd60" if p.life < 0.4 else "#ff8020")
			ctx.fillRect(JS.round(p.x), JS.round(p.y), 1, 2)
		ctx.globalAlpha = 1
		# Foreground vignette
		var vign = ctx.createRadialGradient(W / 2.0, H * 0.6, H * 0.1, W / 2.0, H * 0.5, H * 0.9)
		vign.addColorStop(0, "rgba(0,0,0,0)")
		vign.addColorStop(1, "rgba(0,0,0,0.5)")
		ctx.fillStyle = vign
		ctx.fillRect(0, 0, W, H)
		# Title text
		ctx.globalAlpha = min(1, frame[0] / 20.0)
		ctx.fillStyle = "#c8a030"
		ctx.font = "bold 7px \"Cinzel\", serif"
		ctx.textAlign = "center"
		ctx.fillText("Wandering Merchant", W / 2.0, 12)
		ctx.globalAlpha = 1
		frame[0] += 1
		JS.requestAnimationFrame(drawScene[0])
	drawScene[0] = _fn22
	drawScene[0].call()

func switchCombatTab(tab = null):
	_activeCombatTab = tab
	for t in JS.iter(["actions", "log", "runinfo"]):
		JS.callm_opt(JS.g(JS.callm_opt(document, "getElementById", ["ctab-" + JS.s(t)]), "classList"), "toggle", ["active", JS.eq(t, tab)])
		JS.callm_opt(JS.g(JS.callm_opt(document, "getElementById", ["ctabp-" + JS.s(t)]), "classList"), "toggle", ["active", JS.eq(t, tab)])
	if tab == "log":
		_logHasNew = false
		_updateLogBadge(false)
		var log_ = document.getElementById("battle-log")
		if JS.t(log_):
			log_.scrollTop = log_.scrollHeight
	if tab == "runinfo":
		renderRunInfo()

func _updateLogBadge(hasNew = null):
	var btn = document.getElementById("ctab-log")
	if not JS.t(btn):
		return
	var badge = btn.querySelector(".ctab-log-badge")
	if (JS.t(hasNew) and not JS.t(badge)):
		var b = document.createElement("span")
		b.className = "ctab-log-badge"
		btn.appendChild(b)
	elif (not JS.t(hasNew) and JS.t(badge)):
		badge.remove()

# (log badge is wired directly into log())
# ── BATTLE INFO POPUP ────────────────────────────────────────────────────────
func showBattleInfo(tab = null):
	var ov = document.getElementById("battle-info-overlay")
	if not JS.t(ov):
		return
	ov.style.display = "flex"
	switchBipTab(JS.or_(tab, "log"), document.getElementById("bip-btn-" + (JS.or_(tab, "log"))))

func closeBattleInfo():
	var ov = document.getElementById("battle-info-overlay")
	if JS.t(ov):
		ov.style.display = "none"

func switchBipTab(tab = null, btnEl = null):
	for b in JS.iter(document.querySelectorAll(".bip-tab")):
		b.classList.remove("active")
	if JS.t(btnEl):
		btnEl.classList.add("active")
	for p in JS.iter(document.querySelectorAll(".bip-panel")):
		p.classList.remove("active")
	var panel = document.getElementById("bip-" + JS.s(tab))
	if JS.t(panel):
		panel.classList.add("active")
	if tab == "log":
		var src = document.getElementById("battle-log")
		var dest = document.getElementById("bip-log")
		if (JS.t(src) and JS.t(dest)):
			dest.innerHTML = src.innerHTML
			dest.scrollTop = dest.scrollHeight
	elif tab == "stats":
		renderRunInfo(document.getElementById("bip-stats"))
	elif tab == "library":
		Library._libRoot = document.getElementById("bip-library")
		var visibleEls = (JS.arr(Library.LIBRARY_ELEMENTS).filter(func(el = null): return (JS.includes(Constants.RELEASED_ELEMENTS, el) or el == "Duo")) if not JS.t(Constants.sandboxMode) else Library.LIBRARY_ELEMENTS)
		if (not JS.t(Library._libActiveEl) or not JS.includes(visibleEls, Library._libActiveEl)):
			Library._libActiveEl = JS.idx(visibleEls, 0)
		Library._libRender()

# ── RUN INFO renderer ────────────────────────────────────────────────────────
func renderRunInfo(target = null):
	var panel = (target if JS.t(target) else document.getElementById("run-info-panel"))
	if not JS.t(panel):
		return
	panel.innerHTML = ""
	# Helper
	var _fn23 = func(title = null, html = null):
		var s = document.createElement("div")
		s.className = "ri-section"
		s.innerHTML = "<div class=\"ri-title\">" + JS.s(title) + "</div>" + JS.s(html)
		panel.appendChild(s)
	var section = _fn23
	var row = func(name_ = null, val = null): return "<div class=\"ri-row\"><span class=\"ri-name\">" + JS.s(name_) + "</span><span class=\"ri-val\">" + JS.s(val) + "</span></div>"
	# ── Stats
	var maxHP = Helpers.maxHPFor("player")
	section.call("Stats", ((((((row.call("Element", JS.s(State.playerEmoji) + " " + JS.s(State.playerElement)) + row.call("HP", JS.s(max(0, State.player.hp)) + " / " + JS.s(maxHP))) + row.call("Attack Power", State.player.attackPower)) + row.call("Effect Power", State.player.effectPower)) + row.call("Defense", State.player.defense)) + row.call("Gold", State.player.gold)) + row.call("Lives", State.player.revives)) + (row.call("Bonus Actions", "+" + JS.s(State.player.bonusActions)) if JS.t(State.player.get("bonusActions")) else ""))
	# ── Passives
	if (JS.t(State.player.get("passives")) and JS.t(len(State.player.passives))):
		var html = [null]
		var allPassives = JS.flat(JS.values(Passives.PASSIVE_CHOICES))
		html[0] = ""
		for id in JS.iter(State.player.passives):
			var p = JS.find(allPassives, func(x = null): return JS.eq(x.id, id))
			if not JS.t(p):
				continue
			html[0] += "<div style=\"padding:.25rem 0; border-bottom:1px solid #111; font-size:.72rem;\">\n        <div style=\"color:#c8a060;font-family:'Cinzel',serif;font-size:.7rem;display:flex;align-items:center;gap:.3rem;\">" + PassiveIcons.passiveIconSVG(p, 14) + " " + JS.s(p.title) + "</div>\n        <div style=\"color:#6a5a40;font-size:.62rem;margin-top:.1rem;line-height:1.4;\">" + JS.s(p.desc) + "</div>\n      </div>"
		section.call("Passives", JS.or_(html[0], "<div style=\"color:#333;font-size:.68rem;\">None yet</div>"))
	else:
		section.call("Passives", "<div style=\"color:#333;font-size:.68rem;\">None yet</div>")
	# ── Spells
	if (JS.t(State.player.get("spellbook")) and JS.t(len(State.player.spellbook))):
		var html = [null]
		html[0] = ""
		for s in JS.iter(State.player.spellbook):
			var rankPct = JS.round((JS.or_(s.get("dmgMult"), 1.0)) * 100)
			var rankStr = ("<span class=\"ri-spell-rank\">+" + JS.s(rankPct - 100) + "% dmg</span>" if rankPct > 100 else "")
			var cdStr = ("CD:" + JS.s(s.baseCooldown) if s.baseCooldown > 0 else "No CD")
			html[0] += "<div style=\"padding:.28rem 0;border-bottom:1px solid #111;font-size:.72rem;display:flex;flex-direction:column;gap:.1rem;\">\n        <div style=\"display:flex;justify-content:space-between;align-items:center;\">\n          <span style=\"color:#c8a060;font-family:'Cinzel',serif;font-size:.7rem;\">" + JS.s(s.emoji) + " " + JS.s(s.name) + " " + rankStr + "</span>\n          <span style=\"color:#4a4030;font-size:.6rem;\">" + cdStr + " · " + (JS.or_(s.get("element"), "Neutral")) + "</span>\n        </div>\n        <div style=\"color:#6a5a40;font-size:.62rem;line-height:1.4;\">" + JS.s(s.desc) + "</div>\n      </div>"
		section.call("Spellbook", html[0])
	else:
		section.call("Spellbook", "<div style=\"color:#333;font-size:.68rem;\">No spells learned yet</div>")
	# ── Items
	if (JS.t(State.player.get("inventory")) and JS.t(len(State.player.inventory))):
		var html = [null]
		html[0] = ""
		for item in JS.iter(State.player.inventory):
			html[0] += JS.s(row.call(JS.s(item.emoji) + " " + JS.s(item.name), item.desc))
		section.call("Inventory", html[0])
	# ── Second elements
	if (JS.t(State.player.get("unlockedElements")) and JS.t(len(State.player.unlockedElements))):
		section.call("Second Elements", JS.join(JS.arr(State.player.unlockedElements).map(func(e = null): return row.call(e, "✦ Unlocked")), ""))
	# ── Battle info
	section.call("Run Progress", row.call("Battle #", State.battleNumber) + row.call("Gym defeated", ("Yes ✦" if JS.t(State.gymDefeated) else "Not yet")))

# ── Stars (shared) ──
func mkStars(n = null, rMin = null, rMax = null, sMin = null, sMax = null, bMin = null, bMax = null, col = null):
	var _fn24 = func(_u = null, i = null):
		return {
			"cx": W * (0.2 + (randf() * 0.6)),
			"cy": H * (0.08 + (randf() * 0.35)),
			"r": rMin + (randf() * (rMax - rMin)),
			"angle": (randf() * PI) * 2,
			"speed": sMin + (randf() * (sMax - sMin)),
			"phase": (randf() * PI) * 2,
			"bright": bMin + (randf() * (bMax - bMin)),
			"size": (2 if randf() < 0.15 else 1),
			"col": JS.or_(col, "#c8c0f0"),
		}
	return JS.arrayFrom({"length": n}, _fn24)

func spawnShoot():
	if (len(shoots) >= 2 or randf() > 0.004):
		return
	shoots.append({
		"x": (randf() * W) * 0.7,
		"y": (randf() * H) * 0.4,
		"vx": 1.2 + (randf() * 1.6),
		"vy": 0.4 + (randf() * 0.8),
		"life": 0,
		"maxLife": 28 + (randf() * 20),
	})

func hillY(x = null):
	return (((H * 0.72) + (sin((x * 0.025) + 0.5) * 8)) + (sin((x * 0.011) + 1.2) * 5)) + (sin((x * 0.05) + 2.0) * 3)

func getZone():
	var el = (State.currentZoneElement if (true and JS.t(State.currentZoneElement)) else State.playerElement)
	return (JS.idx(ZONE, el) if (JS.t(JS.idx(ZONE, el)) and JS.t(el)) else ZONE.Neutral)

func drawScene():
	var z = getZone()
	# Sky gradient
	var sky = ctx.createLinearGradient(0, 0, 0, H)
	sky.addColorStop(0, JS.idx(z.sky, 0))
	sky.addColorStop(0.55, JS.idx(z.sky, 1))
	sky.addColorStop(1, JS.idx(z.sky, 2))
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, H)
	# Nebulae
	for n in JS.iter(z.nebulae):
		var pulse = n.base + (sin((frame * 0.012) + n.x) * 0.015)
		var g = ctx.createRadialGradient(n.x, n.y, 0, n.x, n.y, max(n.rx, n.ry))
		g.addColorStop(0, JS.s(n.r + min(0.12, pulse * 2)) + ")")
		g.addColorStop(0.5, JS.s(n.r + pulse) + ")")
		g.addColorStop(1, JS.s(n.r) + "0)")
		ctx.save()
		ctx.scale(1, n.ry / float(n.rx))
		ctx.fillStyle = g
		ctx.beginPath()
		ctx.arc(n.x, n.y * (n.rx / float(n.ry)), n.rx, 0, PI * 2)
		ctx.fill()
		ctx.restore()
	# Stars
	for s in JS.iter(FAR_STARS):
		s.angle += s.speed
		var sx = s.cx + (cos(s.angle) * s.r)
		var sy = s.cy + ((sin(s.angle) * s.r) * 0.38)
		var tw = s.bright * (0.5 + (sin((frame * 0.04) + s.phase) * 0.3))
		ctx.globalAlpha = max(0, tw)
		ctx.fillStyle = z.starCol
		ctx.fillRect(JS.round(sx), JS.round(sy), 1, 1)
	for s in JS.iter(NEAR_STARS):
		s.angle += s.speed
		var sx = s.cx + (cos(s.angle) * s.r)
		var sy = s.cy + ((sin(s.angle) * s.r) * 0.42)
		var tw = s.bright * (0.6 + (sin((frame * 0.06) + s.phase) * 0.35))
		ctx.globalAlpha = max(0, tw)
		ctx.fillStyle = ("#ffffff" if s.get("size") == 2 else z.starCol)
		ctx.fillRect(JS.round(sx), JS.round(sy), s.size, s.size)
	ctx.globalAlpha = 1
	# Shooting stars
	spawnShoot()
	for i in range(len(shoots) - 1, 0 - 1, -1):
		var s = shoots[i]
		s.x += s.vx
		s.y += s.vy
		s.life += 1
		var t = s.life / float(s.maxLife)
		var a = (t / 0.3 if t < 0.3 else 1 - ((t - 0.3) / 0.7))
		ctx.globalAlpha = a * 0.85
		ctx.fillStyle = "#ffffff"
		ctx.fillRect(JS.round(s.x), JS.round(s.y), 2, 1)
		ctx.globalAlpha = a * 0.4
		ctx.fillStyle = z.starCol
		ctx.fillRect(JS.round(s.x - (s.vx * 3)), JS.round(s.y - (s.vy * 3)), 3, 1)
		ctx.globalAlpha = 1
		if s.life >= s.maxLife:
			JS.splice(shoots, i, 1)
	# Zone extra effects (aurora, embers, fireflies, etc.)
	JS.callm(z, "extra", [ctx, W, H, frame])
	# Terrain silhouette
	ctx.fillStyle = z.hillCol
	ctx.beginPath()
	ctx.moveTo(0, H)
	for x in range(0, floori(W) + 1):
		ctx.lineTo(x, hillY(x))
	ctx.lineTo(W, H)
	ctx.closePath()
	ctx.fill()
	# Horizon glow
	var hgY = hillY(W / 2.0)
	var hg = ctx.createLinearGradient(0, hgY - 6, 0, hgY + 4)
	hg.addColorStop(0, z.hgCol)
	hg.addColorStop(1, "rgba(0,0,0,0)")
	ctx.fillStyle = hg
	ctx.fillRect(0, hgY - 6, W, 10)
	# Ground fill
	ctx.fillStyle = z.gndCol
	ctx.fillRect(0, H * 0.85, W, H)
	frame += 1
	JS.requestAnimationFrame(drawScene)

func ZONE__Fire__extra(ctx = null, W = null, H = null, frame = null):
	# embers
	for i in range(10):
		var ph = JS.mod((frame * 0.008) + (i * 0.45), 1)
		var ex = (JS.mod((i * 173) + 37, W)) + JS.round(sin((frame * 0.04) + i) * 4)
		var ey = JS.round(H * (0.95 - (ph * 0.7)))
		var a = sin(ph * PI)
		if a < 0.05:
			continue
		ctx.fillStyle = "rgba(255," + JS.s(JS.round(80 + (100 * (1 - ph)))) + ",0," + JS.toFixed(a * 0.9, 2) + ")"
		ctx.fillRect(ex, ey, (2 if (JS.mod(i, 3)) == 0 else 1), (2 if (JS.mod(i, 3)) == 0 else 1))

func ZONE__Water__extra(ctx = null, W = null, H = null, frame = null):
	# moon
	var mx = JS.round(W * 0.72)
	var my = JS.round(H * 0.15)
	ctx.fillStyle = "rgba(220,235,255,0.92)"
	ctx.fillRect(mx - 4, my, 8, 8)
	ctx.fillStyle = "rgba(200,220,255,0.5)"
	ctx.fillRect(mx - 6, my + 2, 4, 4)
	ctx.fillRect(mx + 4, my + 2, 4, 4)
	# reflection column
	for r in range(5):
		var ry = JS.round((H * 0.78) + (r * 3))
		var a = 0.2 - (r * 0.03)
		ctx.fillStyle = "rgba(200,220,255," + JS.s(a) + ")"
		ctx.fillRect((mx - 1) + JS.round(sin((frame * 0.05) + r) * 1), ry, 3, 2)

func ZONE__Ice__extra(ctx = null, W = null, H = null, frame = null):
	# aurora bands
	for ai in range(3):
		var ay = JS.round(H * (0.12 + (ai * 0.09)))
		var awave = sin((frame * 0.015) + (ai * 1.4)) * 5
		var ag = ctx.createLinearGradient(0, ay - 3, 0, ay + 5)
		var cols = [
			["rgba(40,210,170,", "rgba(60,170,230,"],
			["rgba(80,190,255,", "rgba(40,230,190,"],
			["rgba(60,150,210,", "rgba(80,210,170,"],
		]
		ag.addColorStop(0, JS.s(JS.idx(cols[ai], 0)) + "0)")
		ag.addColorStop(0.5, JS.s(JS.idx(cols[ai], 1)) + "0.15)")
		ag.addColorStop(1, JS.s(JS.idx(cols[ai], 0)) + "0)")
		ctx.fillStyle = ag
		ctx.fillRect(0, ay + JS.round(awave), W, 7)
	# snowflakes
	for i in range(12):
		var ph = JS.mod((frame * 0.006) + (i * 0.28), 1)
		var sx = (JS.mod((i * 197) + 41, W)) + JS.round(sin((frame * 0.03) + i) * 3)
		var sy = JS.round(H * ph)
		var a = sin(ph * PI) * 0.8
		ctx.fillStyle = "rgba(220,240,255," + JS.toFixed(a, 2) + ")"
		ctx.fillRect(sx, sy, (2 if (JS.mod(i, 5)) == 0 else 1), (2 if (JS.mod(i, 5)) == 0 else 1))

func ZONE__Lightning__extra(ctx = null, W = null, H = null, frame = null):
	# storm clouds
	for ci in range(3):
		var cx = (JS.mod((ci * 211) + 37, W)) * 1.0
		var cy = JS.round(H * (0.06 + (ci * 0.08)))
		ctx.fillStyle = "rgba(18,10,36,0.88)"
		ctx.fillRect(JS.round(cx - 35), cy, 70, 14)
		ctx.fillStyle = "rgba(35,22,65,0.5)"
		ctx.fillRect(JS.round(cx - 35), cy, 70, 4)
	# periodic lightning bolt
	if (JS.mod(frame, 90)) < 8:
		var ax = JS.round(W * (0.3 + ((JS.mod(int(frame / 90.0), 3)) * 0.2)))
		ctx.strokeStyle = "#ffffaa"
		ctx.lineWidth = 1.5
		ctx.beginPath()
		ctx.moveTo(ax, 0)
		for seg in range(5):
			ctx.lineTo(ax + (sin((frame * 3) + (seg * 7)) * 10), ((seg * H) * 0.55) / 5.0)
		ctx.stroke()
		ctx.strokeStyle = "rgba(200,180,255,0.35)"
		ctx.lineWidth = 5
		ctx.stroke()

func ZONE__Earth__extra(ctx = null, W = null, H = null, frame = null):
	# fireflies near ground
	for i in range(5):
		var fx = (JS.mod((i * 197) + 41, W)) + JS.round(sin((frame * 0.04) + (i * 0.7)) * 6)
		var fy = JS.round((H * 0.8) + (sin((frame * 0.03) + (i * 1.1)) * 4))
		var g = 0.3 + (0.5 * sin((frame * 0.08) + (i * 1.3)))
		if g > 0.4:
			ctx.fillStyle = "rgba(200,240,80," + JS.toFixed(g * 0.7, 2) + ")"
			ctx.fillRect(fx, fy, 2, 2)

func ZONE__Nature__extra(ctx = null, W = null, H = null, frame = null):
	# fireflies
	for i in range(8):
		var fx = (JS.mod((i * 211) + 37, W)) + JS.round(sin((frame * 0.03) + (i * 0.6)) * 8)
		var fy = JS.round((H * 0.75) + (sin((frame * 0.025) + (i * 1.2)) * 6))
		var g = 0.4 + (0.55 * sin((frame * 0.09) + (i * 1.3)))
		if g > 0.5:
			ctx.fillStyle = "rgba(180,255,80," + JS.toFixed(g * 0.8, 2) + ")"
			ctx.fillRect(fx, fy, 2, 2)

func ZONE__Plasma__extra(ctx = null, W = null, H = null, frame = null):
	# orbiting motes
	for i in range(5):
		var ang = ((frame * 0.018) * (1 + (i * 0.15))) + (i * 1.26)
		var ox = JS.round((W * 0.5) + ((cos(ang) * W) * 0.28))
		var oy = JS.round((H * 0.4) + ((sin(ang * 0.55) * H) * 0.15))
		var g = 0.4 + (0.4 * sin((frame * 0.1) + i))
		ctx.fillStyle = "rgba(" + JS.s((200 if JS.t(JS.mod(i, 2)) else 140)) + ",30,255," + JS.toFixed(g, 2) + ")"
		ctx.fillRect(ox, oy, (3 if (JS.mod(i, 2)) == 0 else 2), (3 if (JS.mod(i, 2)) == 0 else 2))

func ZONE__Air__extra(ctx = null, W = null, H = null, frame = null):
	# moving cloud wisps
	for ci in range(4):
		var cx = JS.mod((frame * 0.3) + (ci * 65), W)
		var cy = JS.round(H * (0.08 + (ci * 0.07)))
		ctx.fillStyle = "rgba(180,200,230,0.07)"
		ctx.fillRect(JS.round(cx - 25), cy, 50, 8)
	# wind streaks
	for i in range(4):
		var wx = JS.mod((frame * 1.2) + ((i * W) * 0.25), W)
		ctx.fillStyle = "rgba(200,215,240,0.07)"
		ctx.fillRect(JS.round(wx), JS.round(H * (0.3 + (i * 0.05))), 18 + (i * 4), 1)

func ZONE__Neutral__extra():
	pass
