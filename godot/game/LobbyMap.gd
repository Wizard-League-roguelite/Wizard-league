# LobbyMap — generated from js/rendering/lobbyMap.js by tools/js2gd.js
extends Node

var LOBBY_FOUNTAIN = null
var LOBBY_PLAZA = null
var LOBBY_LOCATIONS = null
# Player walk state
var _lobbyPlayerX = 0.5
var _lobbyPlayerY = 0.65
var _lobbyTargetX = 0.5
var _lobbyTargetY = 0.65
var _lobbyWalking = false
var _lobbyWalkDest = null
# location id to open after arriving
var _lobbyWaypoint = null
var _lobbyWaypointQueue = null
# ordered list of {x,y,finalDest?} to visit
var _lobbyTick = 0
var _lobbyAnimFrame = null
var _lobbyShootingStars = null
# { x, y, vx, vy, life, maxLife, len }
var _lobbyFacingLeft = false
var _lobbyReturnPos = null
# if set, start here instead of plaza (used when returning from tailor)
var _lobbyCinematic = null
# null | 'castle_enter' | 'castle_teeth' | 'castle_fade'
var _lobbyCinematicTick = 0
# Offscreen canvas — paths are expensive to draw every frame; cache them
var _lobbyPathCanvas = null
var _lobbyPathCacheW = 0
var _lobbyPathCacheH = 0
# Offscreen canvas for post-processing (brightness+contrast in one drawImage)
var _lobbySceneCanvas = null
# ── Zone background panels (randomized per session / run) ─────────────────────
var _lobbyBgZones = null
var _lobbyHoveredId = null
var _PNODES = null
var _PEDGES = null

func _boot():
	# ===== lobbyMap.js =====
	# ─── LOBBY MAP — between-runs interactive world ───────────────────────────────
	# Fountain center — visual only, paths radiate from here
	LOBBY_FOUNTAIN = {"x": 0.5, "y": 0.87}
	# Plaza — where the wizard stands when idle/routing through the square (just south of fountain)
	LOBBY_PLAZA = {"x": 0.5, "y": 0.97}
	LOBBY_LOCATIONS = [
		{"id": "castle", "label": "Begin Run", "desc": "Cross the drawbridge — start a new run", "x": 0.5, "y": 0.42},
		{"id": "archive", "label": "History", "desc": "Review past adventures", "x": 0.09, "y": 0.67},
		{"id": "vault", "label": "Artifacts", "desc": "Artifacts earned from Gym Leaders", "x": 0.83, "y": 0.82},
		{"id": "library", "label": "Spell Decks", "desc": "Manage your deck upgrades", "x": 0.23, "y": 0.91},
		{"id": "talents", "label": "Talent Tree", "desc": "Spend Phos on permanent upgrades", "x": 0.74, "y": 0.91},
		{
			"id": "guild",
			"label": "Library",
			"desc": "Browse your discovered spells and passives",
			"x": 0.17,
			"y": 0.82,
		},
		{"id": "tailor", "label": "Customize Wizard", "desc": "Change your wizard's look", "x": 0.91, "y": 0.67},
		{"id": "veil", "label": "The Veil", "desc": "Choose your burdens, layer your Mist", "x": 0.355, "y": 0.748},
	]
	# legacy compat — unused, replaced by queue
	_lobbyWaypointQueue = []
	_lobbyShootingStars = []
	# Node graph for path-following. All coords normalized (0–1).
	_PNODES = {
		"plaza": [0.5, 0.97],
		"ring_bot": [0.5, 0.907],
		"ring_bl": [0.424, 0.874],
		"ring_br": [0.576, 0.874],
		"ring_tl": [0.429, 0.857],
		"ring_tr": [0.571, 0.857],
		"ring_top": [0.5, 0.833],
		"left_mid": [0.323, 0.828],
		"junc_l": [0.236, 0.795],
		"arc_mid": [0.142, 0.737],
		"guild_mid": [0.213, 0.808],
		"right_mid": [0.677, 0.828],
		"junc_r": [0.764, 0.795],
		"vlt_mid": [0.787, 0.808],
		"tlr_mid": [0.858, 0.737],
		"lib_mid": [0.274, 0.926],
		"tal_mid": [0.709, 0.926],
		"bridge": [0.5, 0.76],
		"archive": [0.09, 0.67],
		"guild": [0.17, 0.82],
		"vault": [0.83, 0.82],
		"tailor": [0.91, 0.67],
		"library": [0.23, 0.91],
		"talents": [0.74, 0.91],
		"veil_mid": [0.43, 0.792],
		"veil": [0.355, 0.748],
	}
	_PEDGES = {
		"plaza": ["ring_bot"],
		"ring_bot": ["plaza", "ring_bl", "ring_br"],
		"ring_bl": ["ring_bot", "ring_tl", "lib_mid"],
		"ring_br": ["ring_bot", "ring_tr", "tal_mid"],
		"ring_tl": ["ring_bl", "ring_top", "left_mid"],
		"ring_tr": ["ring_br", "ring_top", "right_mid"],
		"ring_top": ["ring_tl", "ring_tr", "bridge", "veil_mid"],
		"left_mid": ["ring_tl", "junc_l"],
		"junc_l": ["left_mid", "arc_mid", "guild_mid"],
		"arc_mid": ["junc_l", "archive"],
		"guild_mid": ["junc_l", "guild"],
		"right_mid": ["ring_tr", "junc_r"],
		"junc_r": ["right_mid", "vlt_mid", "tlr_mid"],
		"vlt_mid": ["junc_r", "vault"],
		"tlr_mid": ["junc_r", "tailor"],
		"lib_mid": ["ring_bl", "library"],
		"tal_mid": ["ring_br", "talents"],
		"bridge": ["ring_top"],
		"archive": ["arc_mid"],
		"guild": ["guild_mid"],
		"vault": ["vlt_mid"],
		"tailor": ["tlr_mid"],
		"library": ["lib_mid"],
		"talents": ["tal_mid"],
		"veil_mid": ["ring_top", "veil"],
		"veil": ["veil_mid"],
	}

# Mobile Y-coordinate transform — on portrait screens compress sky into top 20%
# and expand the map area to fill the remaining 80%.
# All fractional Y values (0–1) that are multiplied by H should go through this.
func _lobbyMY(y = null, W = null, H = null):
	if W >= H:
		return y
	# landscape / desktop: no transform
	var ho = 0.6
	var hn = 0.3
	# old horizon 60%, new horizon 30% (leaves sky gap above castle)
	if y <= ho:
		return (y / float(ho)) * hn
	return hn + (((y - ho) / float(1.0 - ho)) * (1.0 - hn))

# Returns the pixel Y for the bottom of the drawbridge — capped on mobile so bridge isn't stretched
func _lobbyBridgeBotY(W = null, H = null):
	var baseY = _lobbyMY(0.6, W, H) * H
	if W < H:
		return baseY + ((W * 0.5) * 0.385)
	# proportional to castle scale (30% shorter)
	return H * 0.76

# array of 3 element strings
func _initLobbyBgZones():
	var all = ["Fire", "Water", "Ice", "Lightning", "Earth", "Nature", "Plasma", "Air", "Camp"]
	# Fisher-Yates shuffle for unbiased ordering
	for i in range(len(all) - 1, 0, -1):
		var j = floori(randf() * (i + 1))
		var _t1 = JS.idx(all, j)
		var _t2 = all[i]
		all[i] = _t1
		all[j] = _t2
	_lobbyBgZones = JS.slice(all, 0, 3)
	# Camp must never appear in the middle panel (index 1)
	if JS.idx(_lobbyBgZones, 1) == "Camp":
		var swap = (0 if randf() < 0.5 else 2)
		var _t3 = JS.idx(_lobbyBgZones, swap)
		var _t4 = JS.idx(_lobbyBgZones, 1)
		_lobbyBgZones[1] = _t3
		_lobbyBgZones[swap] = _t4

func _drawLobbyZonePanels(ctx = null, W = null, H = null):
	if not JS.t(_lobbyBgZones):
		return
	var topY = _lobbyMY(0.12, W, H) * H
	var botY = _lobbyMY(0.6, W, H) * H
	var panelH = botY - topY
	var panelW = W / 3.0
	var t = _lobbyTick
	var _arr5 = JS.iter(_lobbyBgZones)
	for i in range(len(_arr5)):
		var el = _arr5[i]
		var px = i * panelW
		ctx.save()
		ctx.beginPath()
		ctx.rect(px, topY, panelW, panelH)
		ctx.clip()
		_drawZonePanel(ctx, px, topY, panelW, panelH, el, t, i)
		# Soft vertical edge blend
		if i > 0:
			var eg = ctx.createLinearGradient(px, 0, px + (panelW * 0.06), 0)
			eg.addColorStop(0, "rgba(7,4,14,0.85)")
			eg.addColorStop(1, "rgba(7,4,14,0)")
			ctx.fillStyle = eg
			ctx.fillRect(px, topY, panelW * 0.06, panelH)
		ctx.restore()
	# Top fade — panels dissolve upward into pure star sky
	var tf = ctx.createLinearGradient(0, topY, 0, topY + (panelH * 0.22))
	tf.addColorStop(0, "rgba(8,5,14,1)")
	tf.addColorStop(1, "rgba(8,5,14,0)")
	ctx.fillStyle = tf
	ctx.fillRect(0, topY, W, panelH * 0.22)

# Draws a single zone panel with rich atmospheric detail
func _drawZonePanel(ctx = null, px = null, py = null, pw = null, ph = null, el = null, t = null, idx = null):
	var botY = py + ph
	# ── Sky gradient ──────────────────────────────────────────────────────────
	var SKY = {
		"Fire": ["#120100", "#3a0800", "#601400"],
		"Water": ["#00050e", "#011a2e", "#022848"],
		"Ice": ["#010408", "#031424", "#082038"],
		"Lightning": ["#050310", "#0f0a28", "#1c1248"],
		"Earth": ["#080400", "#1c0e00", "#341800"],
		"Nature": ["#010601", "#031803", "#07280a"],
		"Plasma": ["#0a0116", "#1c0430", "#300558"],
		"Air": ["#040608", "#0e1828", "#1a2840"],
	}
	var cols = JS.or_(JS.idx(SKY, el), SKY.get("Earth"))
	var sg = ctx.createLinearGradient(px, py, px, botY)
	sg.addColorStop(0, JS.idx(cols, 0))
	sg.addColorStop(0.5, JS.idx(cols, 1))
	sg.addColorStop(1, JS.idx(cols, 2))
	ctx.fillStyle = sg
	ctx.fillRect(px, py, pw, ph)
	# ── Per-element rendering ──────────────────────────────────────────────────
	match el:
		"Fire":
			# Distant volcano silhouette
			ctx.fillStyle = "#0a0100"
			ctx.beginPath()
			ctx.moveTo(px, botY)
			ctx.lineTo(px + (pw * 0.18), botY - (ph * 0.24))
			ctx.lineTo(px + (pw * 0.3), botY - (ph * 0.38))
			ctx.lineTo(px + (pw * 0.42), botY - (ph * 0.22))
			ctx.lineTo(px + (pw * 0.6), botY - (ph * 0.3))
			ctx.lineTo(px + (pw * 0.72), botY - (ph * 0.18))
			ctx.lineTo(px + pw, botY)
			ctx.closePath()
			ctx.fill()
			# Lava glow at volcano crater
			var vx = px + (pw * 0.3)
			var vy = botY - (ph * 0.38)
			var vg = ctx.createRadialGradient(vx, vy, 0, vx, vy, pw * 0.28)
			vg.addColorStop(0, "rgba(255,80,0,0.55)")
			vg.addColorStop(0.4, "rgba(180,30,0,0.22)")
			vg.addColorStop(1, "transparent")
			ctx.fillStyle = vg
			ctx.fillRect(px, py, pw, ph)
			# Horizon ember glow band
			var hg = ctx.createLinearGradient(px, botY - (ph * 0.18), px, botY)
			hg.addColorStop(0, "transparent")
			hg.addColorStop(1, "rgba(220,50,0,0.35)")
			ctx.fillStyle = hg
			ctx.fillRect(px, botY - (ph * 0.18), pw, ph * 0.18)
			# Rising embers
			for i in range(14):
				var p = JS.mod((t * 0.009) + (i * 0.18), 1)
				var ex = px + (pw * (JS.mod((i * 0.073) + 0.04, 1)))
				var ey = py + (ph * (1 - (p * 0.82)))
				var drift = (sin((t * 0.025) + (i * 1.3)) * pw) * 0.03
				ctx.globalAlpha = (1 - p) * 0.7
				ctx.fillStyle = ("#FF8800" if (JS.mod(i, 3)) == 0 else ("#FF3300" if (JS.mod(i, 3)) == 1 else "#FFCC00"))
				ctx.fillRect(JS.round(ex + drift), JS.round(ey), 2, 2)
			# Charred tree silhouette (near hill)
			ctx.globalAlpha = 1
			ctx.fillStyle = "#050100"
			for i in range(4):
				var tx2 = px + (pw * (0.08 + (i * 0.24)))
				var th = ph * 0.19
				var ty2 = botY - th
				ctx.fillRect(JS.round(tx2 + (pw * 0.025)), JS.round(ty2), JS.round(pw * 0.018), JS.round(th))
				# Bare branches
				ctx.strokeStyle = "#050100"
				ctx.lineWidth = 1
				ctx.beginPath()
				ctx.moveTo(JS.round(tx2 + (pw * 0.034)), JS.round(ty2 + (th * 0.3)))
				ctx.lineTo(JS.round(tx2 + (pw * 0.075)), JS.round(ty2 + (th * 0.18)))
				ctx.stroke()
				ctx.beginPath()
				ctx.moveTo(JS.round(tx2 + (pw * 0.034)), JS.round(ty2 + (th * 0.5)))
				ctx.lineTo(JS.round(tx2 - (pw * 0.022)), JS.round(ty2 + (th * 0.38)))
				ctx.stroke()
			ctx.globalAlpha = 1
		"Water":
			# Deep ocean horizon glow
			var hg = ctx.createLinearGradient(px, botY - (ph * 0.3), px, botY)
			hg.addColorStop(0, "transparent")
			hg.addColorStop(1, "rgba(0,80,180,0.30)")
			ctx.fillStyle = hg
			ctx.fillRect(px, botY - (ph * 0.3), pw, ph * 0.3)
			# Distant rocky island silhouette
			ctx.fillStyle = "#010a14"
			ctx.beginPath()
			ctx.moveTo(px + (pw * 0.12), botY)
			ctx.lineTo(px + (pw * 0.2), botY - (ph * 0.12))
			ctx.lineTo(px + (pw * 0.32), botY - (ph * 0.2))
			ctx.lineTo(px + (pw * 0.44), botY - (ph * 0.13))
			ctx.lineTo(px + (pw * 0.55), botY)
			ctx.closePath()
			ctx.fill()
			# Sea mist layer
			var mg = ctx.createLinearGradient(px, botY - (ph * 0.15), px, botY - (ph * 0.04))
			mg.addColorStop(0, "transparent")
			mg.addColorStop(1, "rgba(30,100,160,0.18)")
			ctx.fillStyle = mg
			ctx.fillRect(px, botY - (ph * 0.15), pw, ph * 0.11)
			# Wave shimmer lines
			for i in range(6):
				var wy = botY - (ph * (0.04 + (i * 0.028)))
				var ox = (sin(((t * 0.018) + (i * 1.8)) + (idx * 0.9)) * pw) * 0.08
				ctx.globalAlpha = 0.18 - (i * 0.022)
				ctx.fillStyle = ("#55aadd" if JS.t(JS.mod(i, 2)) else "#88ccff")
				var ww = pw * (0.35 + (0.2 * sin((t * 0.011) + i)))
				ctx.fillRect(JS.round((px + (pw * 0.12)) + ox), JS.round(wy), JS.round(ww), 1)
			# Bioluminescent sparkle dots
			for i in range(8):
				var bx = px + (pw * (JS.mod((i * 0.13) + 0.05, 1)))
				var bya = botY - (ph * (0.06 + (JS.mod(i * 0.09, 0.14))))
				var ba = 0.3 + (0.5 * sin((t * 0.04) + (i * 2.1)))
				ctx.globalAlpha = max(0, ba)
				ctx.fillStyle = "#44ffcc"
				ctx.fillRect(JS.round(bx), JS.round(bya), 1, 1)
			ctx.globalAlpha = 1
		"Ice":
			# Aurora bands (sweeping color ribbons)
			var auroraColors = ["rgba(0,255,160,", "rgba(0,180,255,", "rgba(100,80,255,"]
			for i in range(3):
				var aPhase = ((t * 0.007) + (i * 1.1)) + (idx * 0.6)
				var ay = py + (ph * ((0.08 + (i * 0.14)) + (sin(aPhase) * 0.04)))
				var ah = ph * (0.06 + (0.04 * sin(aPhase * 0.7)))
				var ag = ctx.createLinearGradient(px, ay, px, ay + ah)
				ag.addColorStop(0, "transparent")
				ag.addColorStop(0.5, JS.s(auroraColors[i] + (0.18 + (0.12 * sin(aPhase * 1.3)))) + ")")
				ag.addColorStop(1, "transparent")
				ctx.fillStyle = ag
				ctx.fillRect(px, ay, pw, ah)
			# Frozen tundra — dark silhouette hills (NOT bright)
			ctx.fillStyle = "#060c10"
			_drawPanelHillShape(ctx, px, py, pw, ph, 0.4 + (idx * 0.8), 0.3)
			ctx.fillStyle = "#030608"
			_drawPanelHillShape(ctx, px, py, pw, ph, 1.1 + (idx * 0.6), 0.17)
			# Icicles hanging from near hill edge
			ctx.fillStyle = "#88ccee"
			var hillEdgeY = py + (ph * (1 - 0.17))
			for i in range(10):
				var ix = px + (pw * (0.05 + (i * 0.095)))
				var ih = ph * (0.025 + ((0.018 * (JS.mod((i * 7) + 3, 5))) / 4.0))
				ctx.globalAlpha = 0.22 + (0.08 * sin((t * 0.02) + i))
				ctx.fillRect(JS.round(ix), JS.round(hillEdgeY - (ph * 0.01)), 1, JS.round(ih))
			# Distant frozen peaks
			ctx.globalAlpha = 1
			ctx.fillStyle = "#080e14"
			ctx.beginPath()
			ctx.moveTo(px, botY)
			ctx.lineTo(px + (pw * 0.1), botY - (ph * 0.28))
			ctx.lineTo(px + (pw * 0.22), botY - (ph * 0.18))
			ctx.lineTo(px + (pw * 0.36), botY - (ph * 0.36))
			ctx.lineTo(px + (pw * 0.48), botY - (ph * 0.24))
			ctx.lineTo(px + (pw * 0.62), botY - (ph * 0.32))
			ctx.lineTo(px + (pw * 0.76), botY - (ph * 0.2))
			ctx.lineTo(px + (pw * 0.88), botY - (ph * 0.28))
			ctx.lineTo(px + pw, botY - (ph * 0.14))
			ctx.lineTo(px + pw, botY)
			ctx.closePath()
			ctx.fill()
			# Snow highlights on peaks
			ctx.fillStyle = "#2a4050"
			ctx.globalAlpha = 0.4
			ctx.beginPath()
			ctx.moveTo(px + (pw * 0.34), botY - (ph * 0.36))
			ctx.lineTo(px + (pw * 0.3), botY - (ph * 0.28))
			ctx.lineTo(px + (pw * 0.42), botY - (ph * 0.26))
			ctx.closePath()
			ctx.fill()
			ctx.globalAlpha = 1
		"Lightning":
			# Rolling storm clouds — soft gradient blobs
			for ci in range(3):
				var cy2 = py + (ph * (0.06 + (ci * 0.13)))
				var cpha = ((t * 0.004) + (ci * 1.4)) + (idx * 0.8)
				var ch = ph * (0.1 + (0.05 * sin(cpha)))
				var cg2 = ctx.createLinearGradient(px, cy2, px, cy2 + ch)
				cg2.addColorStop(0, "rgba(20,12,45,0)")
				cg2.addColorStop(0.45, "rgba(30,18,65," + JS.s(0.45 + (0.15 * sin(cpha * 0.9))) + ")")
				cg2.addColorStop(1, "rgba(20,12,45,0)")
				ctx.fillStyle = cg2
				ctx.fillRect(px, cy2, pw, ch)
			# Distant jagged cliffs
			ctx.fillStyle = "#04020e"
			ctx.beginPath()
			ctx.moveTo(px, botY)
			ctx.lineTo(px + (pw * 0.05), botY - (ph * 0.2))
			ctx.lineTo(px + (pw * 0.14), botY - (ph * 0.28))
			ctx.lineTo(px + (pw * 0.22), botY - (ph * 0.18))
			ctx.lineTo(px + (pw * 0.32), botY - (ph * 0.34))
			ctx.lineTo(px + (pw * 0.4), botY - (ph * 0.24))
			ctx.lineTo(px + (pw * 0.52), botY - (ph * 0.3))
			ctx.lineTo(px + (pw * 0.62), botY - (ph * 0.2))
			ctx.lineTo(px + (pw * 0.72), botY - (ph * 0.26))
			ctx.lineTo(px + (pw * 0.84), botY - (ph * 0.16))
			ctx.lineTo(px + (pw * 0.92), botY - (ph * 0.22))
			ctx.lineTo(px + pw, botY - (ph * 0.12))
			ctx.lineTo(px + pw, botY)
			ctx.closePath()
			ctx.fill()
			# Near rolling hill
			ctx.fillStyle = "#020106"
			_drawPanelHillShape(ctx, px, py, pw, ph, 1.2 + (idx * 0.5), 0.16)
			# Lightning bolt flash
			var lPhase = JS.mod(t + (idx * 37), 130)
			if (lPhase < 4 or (lPhase > 65 and lPhase < 68)):
				var fadeA = (1 - (lPhase * 0.15) if lPhase < 4 else 1 - ((lPhase - 65) * 0.2))
				ctx.globalAlpha = max(0, fadeA) * 0.85
				ctx.strokeStyle = "#dde8ff"
				ctx.lineWidth = 1.5
				var bx2 = px + (pw * 0.55)
				ctx.beginPath()
				ctx.moveTo(bx2, py + (ph * 0.04))
				ctx.lineTo(bx2 - (pw * 0.04), py + (ph * 0.26))
				ctx.lineTo(bx2 + (pw * 0.03), py + (ph * 0.26))
				ctx.lineTo(bx2 - (pw * 0.055), py + (ph * 0.55))
				ctx.stroke()
				# Secondary thin branch
				ctx.lineWidth = 0.8
				ctx.globalAlpha *= 0.5
				ctx.beginPath()
				ctx.moveTo(bx2 + (pw * 0.03), py + (ph * 0.26))
				ctx.lineTo(bx2 + (pw * 0.09), py + (ph * 0.42))
				ctx.stroke()
				# Flash bloom
				ctx.globalAlpha = max(0, fadeA) * 0.3
				var bg2 = ctx.createRadialGradient(bx2, py + (ph * 0.3), 0, bx2, py + (ph * 0.3), pw * 0.3)
				bg2.addColorStop(0, "rgba(160,160,255,1)")
				bg2.addColorStop(1, "transparent")
				ctx.fillStyle = bg2
				ctx.fillRect(px, py, pw, ph)
				ctx.lineWidth = 1
			# Ambient purple glow pulse in sky
			ctx.globalAlpha = 0.05 + (0.04 * sin((t * 0.025) + idx))
			ctx.fillStyle = "#7744ff"
			ctx.fillRect(px, py, pw, ph * 0.5)
			ctx.globalAlpha = 1
		"Earth":
			# Canyon / mesa horizon glow
			var hg = ctx.createLinearGradient(px, botY - (ph * 0.22), px, botY)
			hg.addColorStop(0, "transparent")
			hg.addColorStop(1, "rgba(140,70,10,0.28)")
			ctx.fillStyle = hg
			ctx.fillRect(px, botY - (ph * 0.22), pw, ph * 0.22)
			# Mesa plateau silhouettes (flat-top cliffs)
			ctx.fillStyle = "#100600"
			ctx.beginPath()
			ctx.moveTo(px, botY)
			ctx.lineTo(px, botY - (ph * 0.22))
			ctx.lineTo(px + (pw * 0.14), botY - (ph * 0.22))
			ctx.lineTo(px + (pw * 0.14), botY - (ph * 0.32))
			ctx.lineTo(px + (pw * 0.38), botY - (ph * 0.32))
			ctx.lineTo(px + (pw * 0.38), botY - (ph * 0.2))
			ctx.lineTo(px + (pw * 0.55), botY - (ph * 0.2))
			ctx.lineTo(px + (pw * 0.55), botY - (ph * 0.28))
			ctx.lineTo(px + (pw * 0.8), botY - (ph * 0.28))
			ctx.lineTo(px + (pw * 0.8), botY - (ph * 0.16))
			ctx.lineTo(px + pw, botY - (ph * 0.16))
			ctx.lineTo(px + pw, botY)
			ctx.closePath()
			ctx.fill()
			# Rock strata lines on mesa face
			ctx.strokeStyle = "#1c0c02"
			ctx.lineWidth = 1
			for i in range(3):
				var sy = botY - (ph * (0.07 + (i * 0.055)))
				ctx.globalAlpha = 0.35
				ctx.beginPath()
				ctx.moveTo(px, sy)
				ctx.lineTo(px + (pw * (0.85 + (0.1 * sin(i * 2.1)))), sy)
				ctx.stroke()
			# Distant butte
			ctx.globalAlpha = 1
			ctx.fillStyle = "#0c0400"
			ctx.fillRect(px + (pw * 0.42), botY - (ph * 0.44), pw * 0.12, ph * 0.12)
			# Near dark hill
			ctx.fillStyle = "#080300"
			_drawPanelHillShape(ctx, px, py, pw, ph, 0.8 + (idx * 0.6), 0.14)
			# Dust particle drift
			for i in range(6):
				var dp = JS.mod((t * 0.006) + (i * 0.22), 1)
				var dx2 = px + (pw * (JS.mod(dp + (i * 0.17), 1)))
				var dy2 = botY - (ph * (0.05 + (JS.mod(i * 0.04, 0.12))))
				ctx.globalAlpha = (1 - dp) * 0.18
				ctx.fillStyle = "#aa7733"
				ctx.fillRect(JS.round(dx2), JS.round(dy2), 2, 1)
			ctx.globalAlpha = 1
		"Nature":
			# Misty forest horizon glow
			var hg = ctx.createLinearGradient(px, botY - (ph * 0.25), px, botY)
			hg.addColorStop(0, "transparent")
			hg.addColorStop(1, "rgba(10,80,10,0.25)")
			ctx.fillStyle = hg
			ctx.fillRect(px, botY - (ph * 0.25), pw, ph * 0.25)
			# Distant hill — muted blue-green (atmospheric haze, clearly separate from mid/near)
			ctx.fillStyle = "#0d2214"
			_drawPanelHillShape(ctx, px, py, pw, ph, 0.4 + (idx * 0.8), 0.34)
			# Mist layer over distant hill
			var mg = ctx.createLinearGradient(px, botY - (ph * 0.36), px, botY - (ph * 0.22))
			mg.addColorStop(0, "transparent")
			mg.addColorStop(1, "rgba(8,30,14,0.45)")
			ctx.fillStyle = mg
			ctx.fillRect(px, botY - (ph * 0.36), pw, ph * 0.14)
			# Mid-ground hill — warmer forest green
			ctx.fillStyle = "#0a1a05"
			_drawPanelHillShape(ctx, px, py, pw, ph, 1.0 + (idx * 0.55), 0.22)
			# Pine tree silhouettes — mid distance, medium dark green
			ctx.fillStyle = "#061405"
			ctx.globalAlpha = 0.95
			for i in range(7):
				var tx2 = px + (pw * (0.03 + (i * 0.138)))
				var tw2 = pw * 0.065
				var th2 = ph * 0.2
				var ty2 = (botY - (ph * 0.22)) - (th2 * 0.8)
				ctx.fillRect(JS.round(tx2 + (tw2 * 0.44)), JS.round(ty2 + (th2 * 0.55)), JS.round(tw2 * 0.14), JS.round(th2 * 0.45))
				ctx.beginPath()
				ctx.moveTo(JS.round(tx2 + (tw2 * 0.5)), JS.round(ty2))
				ctx.lineTo(JS.round(tx2), JS.round(ty2 + (th2 * 0.65)))
				ctx.lineTo(JS.round(tx2 + tw2), JS.round(ty2 + (th2 * 0.65)))
				ctx.closePath()
				ctx.fill()
				ctx.beginPath()
				ctx.moveTo(JS.round(tx2 + (tw2 * 0.5)), JS.round(ty2 + (th2 * 0.25)))
				ctx.lineTo(JS.round(tx2 + (tw2 * 0.08)), JS.round(ty2 + (th2 * 0.82)))
				ctx.lineTo(JS.round(tx2 + (tw2 * 0.92)), JS.round(ty2 + (th2 * 0.82)))
				ctx.closePath()
				ctx.fill()
			# Near tree line — largest, blackest, closest
			ctx.fillStyle = "#020a02"
			ctx.globalAlpha = 1
			for i in range(5):
				var tx2 = px + (pw * (0.01 + (i * 0.198)))
				var tw2 = pw * 0.1
				var th2 = ph * 0.28
				var ty2 = botY - (th2 * 0.85)
				ctx.fillRect(JS.round(tx2 + (tw2 * 0.44)), JS.round(ty2 + (th2 * 0.5)), JS.round(tw2 * 0.14), JS.round(th2 * 0.5))
				ctx.beginPath()
				ctx.moveTo(JS.round(tx2 + (tw2 * 0.5)), JS.round(ty2))
				ctx.lineTo(JS.round(tx2), JS.round(ty2 + (th2 * 0.6)))
				ctx.lineTo(JS.round(tx2 + tw2), JS.round(ty2 + (th2 * 0.6)))
				ctx.closePath()
				ctx.fill()
			# Fireflies
			for i in range(10):
				var fa = 0.5 + (0.5 * sin(((t * 0.045) + (i * 1.8)) + (idx * 0.7)))
				if fa < 0.3:
					continue
				var fx = px + (pw * (JS.mod((i * 0.097) + 0.04, 1)))
				var fy2 = botY - (ph * (0.08 + (JS.mod(i * 0.073, 0.25))))
				ctx.globalAlpha = fa * 0.6
				ctx.fillStyle = "#88ff22"
				ctx.fillRect(JS.round(fx), JS.round(fy2), 1, 1)
			ctx.globalAlpha = 1
		"Plasma":
			# Void nebula layers
			var nebColors = [["rgba(140,0,220,", 0.2, 0.3], ["rgba(220,0,120,", 0.5, 0.55], ["rgba(80,0,180,", 0.7, 0.2]]
			var _arr7 = JS.iter(nebColors)
			for ni in range(len(_arr7)):
				var _e6 = _arr7[ni]
				var c = JS.idx(_e6, 0)
				var yf = JS.idx(_e6, 1)
				var hf = JS.idx(_e6, 2)
				var ng = ctx.createRadialGradient(px + (pw * ((0.3 + (ni * 0.2)) + (0.1 * sin((t * 0.005) + ni)))), py + (ph * yf), pw * 0.01, px + (pw * ((0.3 + (ni * 0.2)) + (0.1 * sin((t * 0.005) + ni)))), py + (ph * yf), pw * (0.4 + hf))
				ng.addColorStop(0, JS.s(c + (0.28 + (0.12 * sin((t * 0.011) + (ni * 2))))) + ")")
				ng.addColorStop(1, "transparent")
				ctx.fillStyle = ng
				ctx.fillRect(px, py, pw, ph)
			# Distant void planet / orb
			var orbX = px + (pw * 0.65)
			var orbY = py + (ph * 0.3)
			var orbR = pw * 0.1
			var orbG = ctx.createRadialGradient(orbX - (orbR * 0.3), orbY - (orbR * 0.3), 0, orbX, orbY, orbR)
			orbG.addColorStop(0, "#9933cc")
			orbG.addColorStop(0.6, "#550088")
			orbG.addColorStop(1, "#220044")
			ctx.fillStyle = orbG
			ctx.beginPath()
			ctx.arc(orbX, orbY, orbR, 0, PI * 2)
			ctx.fill()
			# Orb ring
			ctx.strokeStyle = "rgba(200,80,255,0.35)"
			ctx.lineWidth = 1
			ctx.beginPath()
			ctx.ellipse(orbX, orbY, orbR * 1.5, orbR * 0.35, -0.3, 0, PI * 2)
			ctx.stroke()
			# Dark jagged horizon
			ctx.fillStyle = "#060010"
			ctx.beginPath()
			ctx.moveTo(px, botY)
			ctx.lineTo(px + (pw * 0.06), botY - (ph * 0.1))
			ctx.lineTo(px + (pw * 0.18), botY - (ph * 0.18))
			ctx.lineTo(px + (pw * 0.28), botY - (ph * 0.08))
			ctx.lineTo(px + (pw * 0.42), botY - (ph * 0.22))
			ctx.lineTo(px + (pw * 0.56), botY - (ph * 0.14))
			ctx.lineTo(px + (pw * 0.68), botY - (ph * 0.2))
			ctx.lineTo(px + (pw * 0.8), botY - (ph * 0.1))
			ctx.lineTo(px + (pw * 0.92), botY - (ph * 0.16))
			ctx.lineTo(px + pw, botY - (ph * 0.08))
			ctx.lineTo(px + pw, botY)
			ctx.closePath()
			ctx.fill()
			# Floating energy orbs / motes
			for i in range(10):
				var ox = px + (pw * (JS.mod((i * 0.1) + 0.05, 1)))
				var oy = py + (ph * (0.15 + (JS.mod(i * 0.08, 0.65))))
				var oa = 0.35 + (0.45 * sin((t * 0.022) + (i * 1.9)))
				ctx.globalAlpha = max(0, oa)
				ctx.fillStyle = ("#cc44ff" if (JS.mod(i, 3)) == 0 else ("#ff44aa" if (JS.mod(i, 3)) == 1 else "#8844ff"))
				ctx.beginPath()
				ctx.arc(JS.round(ox), JS.round(oy), 1.5, 0, PI * 2)
				ctx.fill()
			ctx.globalAlpha = 1
		"Air":
			# Bright high-altitude sky wash
			var atm = ctx.createLinearGradient(px, py, px, botY)
			atm.addColorStop(0, "rgba(20,30,50,0)")
			atm.addColorStop(0.6, "rgba(30,50,80,0.08)")
			atm.addColorStop(1, "rgba(60,90,130,0.14)")
			ctx.fillStyle = atm
			ctx.fillRect(px, py, pw, ph)
			# Distant mountain peaks (airy blue-grey)
			ctx.fillStyle = "#0c1420"
			ctx.beginPath()
			ctx.moveTo(px, botY)
			ctx.lineTo(px + (pw * 0.08), botY - (ph * 0.3))
			ctx.lineTo(px + (pw * 0.2), botY - (ph * 0.2))
			ctx.lineTo(px + (pw * 0.34), botY - (ph * 0.42))
			ctx.lineTo(px + (pw * 0.46), botY - (ph * 0.28))
			ctx.lineTo(px + (pw * 0.6), botY - (ph * 0.35))
			ctx.lineTo(px + (pw * 0.72), botY - (ph * 0.22))
			ctx.lineTo(px + (pw * 0.86), botY - (ph * 0.3))
			ctx.lineTo(px + pw, botY - (ph * 0.18))
			ctx.lineTo(px + pw, botY)
			ctx.closePath()
			ctx.fill()
			# Snow on peak tops
			ctx.fillStyle = "#1e2e40"
			ctx.globalAlpha = 0.5
			for _e8 in JS.iter([[0.34, 0.42, 0.44, 0.36], [0.6, 0.35, 0.7, 0.27], [0.08, 0.3, 0.14, 0.22]]):
				var x1 = JS.idx(_e8, 0)
				var y1 = JS.idx(_e8, 1)
				var x2 = JS.idx(_e8, 2)
				var y2 = JS.idx(_e8, 3)
				ctx.beginPath()
				ctx.moveTo(px + (pw * x1), botY - (ph * y1))
				ctx.lineTo(px + (pw * (((x1 + x2) / 2.0) - 0.05)), botY - (ph * (y1 * 0.82)))
				ctx.lineTo(px + (pw * x2), botY - (ph * y2))
				ctx.closePath()
				ctx.fill()
			ctx.globalAlpha = 1
			# Near hill
			ctx.fillStyle = "#08101a"
			_drawPanelHillShape(ctx, px, py, pw, ph, 0.7 + (idx * 0.65), 0.16)
			# Drifting cloud wisps
			for i in range(4):
				var cy2 = py + (ph * (0.1 + (i * 0.11)))
				var cx2 = (px + (JS.mod((t * 0.18) + ((i * pw) * 0.32), pw * 1.8))) - (pw * 0.4)
				var cw2 = pw * (0.28 + ((0.14 * (JS.mod((i * 3) + 1, 3))) / 2.0))
				var clg = ctx.createLinearGradient(cx2, cy2, cx2, cy2 + (ph * 0.035))
				clg.addColorStop(0, "rgba(100,140,180,0.09)")
				clg.addColorStop(0.5, "rgba(120,160,200,0.06)")
				clg.addColorStop(1, "transparent")
				ctx.fillStyle = clg
				ctx.fillRect(JS.round(cx2), JS.round(cy2), JS.round(cw2), JS.round(ph * 0.035))
			# Wind particle streaks
			for i in range(6):
				var wp = JS.mod((t * 0.014) + (i * 0.22), 1)
				var wy2 = py + (ph * (0.55 + (JS.mod(i * 0.07, 0.3))))
				var wx2 = (px + ((wp * pw) * 1.3)) - (pw * 0.15)
				ctx.globalAlpha = (1 - wp) * 0.12
				ctx.fillStyle = "#aaccee"
				ctx.fillRect(JS.round(wx2), JS.round(wy2), JS.round(pw * 0.12), 1)
			ctx.globalAlpha = 1
		"Camp":
			# Night sky
			var atm = ctx.createLinearGradient(px, py, px, botY)
			atm.addColorStop(0, "#02040c")
			atm.addColorStop(0.65, "#050810")
			atm.addColorStop(1, "#080e16")
			ctx.fillStyle = atm
			ctx.fillRect(px, py, pw, ph)
			# Stars
			for i in range(22):
				var sx = px + (pw * (JS.mod(((i * 0.053) + 0.02) + (idx * 0.13), 1)))
				var sy = py + (ph * (0.03 + (JS.mod(i * 0.047, 0.42))))
				var sa = 0.25 + (0.55 * sin((t * 0.028) + (i * 2.1)))
				ctx.globalAlpha = max(0, sa) * 0.72
				ctx.fillStyle = "#ccd4f0"
				ctx.fillRect(JS.round(sx), JS.round(sy), 1, 1)
			ctx.globalAlpha = 1
			# Crescent moon (upper right)
			if true:
				var mx = px + (pw * 0.8)
				var my = py + (ph * 0.09)
				var mr = max(4, JS.round(pw * 0.038))
				ctx.globalAlpha = 0.55
				ctx.fillStyle = "#e8e0c0"
				ctx.beginPath()
				ctx.arc(mx, my, mr, 0, PI * 2)
				ctx.fill()
				ctx.globalAlpha = 1
				ctx.fillStyle = "#02030a"
				ctx.beginPath()
				ctx.arc(mx + JS.round(mr * 0.55), my - JS.round(mr * 0.2), JS.round(mr * 0.88), 0, PI * 2)
				ctx.fill()
			# Background distant dark hill
			ctx.fillStyle = "#04090a"
			_drawPanelHillShape(ctx, px, py, pw, ph, 0.8 + (idx * 0.6), 0.4)
			# Hill geometry: rises from left, levels off into a flat plateau where the tent sits
			var hillTopY = botY - (ph * 0.27)
			var fireX = px + (pw * 0.28)
			var flatEnd = px + (pw * 0.76)
			ctx.fillStyle = "#060e06"
			ctx.beginPath()
			ctx.moveTo(px, botY)
			ctx.bezierCurveTo(px + (pw * 0.06), botY, px + (pw * 0.14), hillTopY, fireX, hillTopY)
			ctx.lineTo(flatEnd, hillTopY)
			ctx.bezierCurveTo(flatEnd + (pw * 0.08), hillTopY, px + (pw * 0.94), botY, px + pw, botY)
			ctx.closePath()
			ctx.fill()
			# ── Campfire — actual sprite animation ───────────────────────────────
			var logScale = max(1, JS.round(pw / 140.0))
			var logPal = ["#6a3810", "#3a1808", "#c8a060", "#2a1004"]
			var logW2 = 12 * logScale
			var logH2 = len(Animations.SPRITE_CF_LOGS) * logScale
			var logSX = JS.round(fireX - (logW2 / 2.0))
			var logSY = (hillTopY - logH2) + 2
			Sprites.drawSprite(ctx, Animations.SPRITE_CF_LOGS, logSX, logSY, logScale, logPal)
			var frameIdx = JS.mod(floori(t / 5.0), 3)
			var flameRows = JS.idx([Animations.SPRITE_CF_FLAME_A, Animations.SPRITE_CF_FLAME_B, Animations.SPRITE_CF_FLAME_C], frameIdx)
			var flickPals = [
				["#FF7700", "#FFAA00", "#FF3300", "#FF9900"],
				["#FF5500", "#FF8800", "#FF2200", "#FFCC00"],
				["#FF9900", "#FFCC00", "#FF4400", "#FFAA00"],
			]
			var flameH2 = len(flameRows) * logScale
			var flameSX = logSX
			var flameSY = (logSY - flameH2) + (logScale * 2)
			Sprites.drawSprite(ctx, flameRows, flameSX, flameSY, logScale, JS.idx(flickPals, frameIdx))
			# Fire glow on hill
			var flicker = 0.85 + (0.15 * sin(t * 0.13))
			var fglow = ctx.createRadialGradient(fireX, hillTopY, 0, fireX, hillTopY, (pw * 0.24) * flicker)
			fglow.addColorStop(0, "rgba(255,120,20," + JS.s(0.3 * flicker) + ")")
			fglow.addColorStop(0.4, "rgba(200,70,5," + JS.s(0.1 * flicker) + ")")
			fglow.addColorStop(1, "transparent")
			ctx.fillStyle = fglow
			ctx.fillRect(px, py, pw, ph)
			# Embers
			for i in range(6):
				var p = JS.mod((t * 0.011) + (i * 0.22), 1)
				var ex = fireX + ((sin((t * 0.04) + (i * 1.5)) * pw) * 0.02)
				var ey = flameSY - ((p * ph) * 0.1)
				ctx.globalAlpha = (1 - p) * 0.8
				ctx.fillStyle = ("#ff6600" if JS.t(JS.mod(i, 2)) else "#ffaa00")
				ctx.fillRect(JS.round(ex), JS.round(ey), 1, 1)
			ctx.globalAlpha = 1
			# ── Hooded figure sitting to the right of fire ───────────────────────
			var figX = JS.round(fireX + (logW2 * 0.9))
			var figH3 = logH2 * 1.3
			var figW3 = logW2 * 0.55
			ctx.fillStyle = "#07040a"
			ctx.fillRect(figX, JS.round(hillTopY - figH3), JS.round(figW3), JS.round(figH3))
			ctx.beginPath()
			ctx.arc(figX + JS.round(figW3 / 2.0), JS.round((hillTopY - figH3) - (figW3 * 0.42)), JS.round(figW3 * 0.46), 0, PI * 2)
			ctx.fill()
			ctx.fillStyle = "rgba(255,90,10," + JS.s(0.22 + (0.07 * flicker)) + ")"
			ctx.fillRect(figX, JS.round(hillTopY - figH3), JS.round(figW3 * 0.32), JS.round(figH3))
			# ── Merchant tent on the flat section (matching map.js shop tent) ─────
			var tentCX = px + (pw * 0.6)
			var tentBase = hillTopY
			var tentW3 = pw * 0.28
			var tentH3 = ph * 0.2
			var tentPeak = tentBase - tentH3
			# Main triangle body
			ctx.fillStyle = "#3a2810"
			ctx.beginPath()
			ctx.moveTo(tentCX - (tentW3 / 2.0), tentBase)
			ctx.lineTo(tentCX + (tentW3 / 2.0), tentBase)
			ctx.lineTo(tentCX, tentPeak)
			ctx.closePath()
			ctx.fill()
			# Two darker stripes from peak
			ctx.fillStyle = "#2a1c08"
			ctx.beginPath()
			ctx.moveTo(tentCX, tentPeak)
			ctx.lineTo(tentCX - (tentW3 * 0.18), tentBase)
			ctx.lineTo(tentCX - (tentW3 * 0.15), tentBase)
			ctx.lineTo(tentCX, tentPeak + (tentH3 * 0.08))
			ctx.closePath()
			ctx.fill()
			ctx.beginPath()
			ctx.moveTo(tentCX, tentPeak)
			ctx.lineTo(tentCX + (tentW3 * 0.18), tentBase)
			ctx.lineTo(tentCX + (tentW3 * 0.15), tentBase)
			ctx.lineTo(tentCX, tentPeak + (tentH3 * 0.08))
			ctx.closePath()
			ctx.fill()
			# Outline
			ctx.strokeStyle = "#6a4818"
			ctx.lineWidth = 1
			ctx.beginPath()
			ctx.moveTo(tentCX - (tentW3 / 2.0), tentBase)
			ctx.lineTo(tentCX, tentPeak)
			ctx.lineTo(tentCX + (tentW3 / 2.0), tentBase)
			ctx.stroke()
			# Door
			var doorW = tentW3 * 0.26
			var doorH = tentH3 * 0.42
			ctx.fillStyle = "#0a0618"
			ctx.fillRect(JS.round(tentCX - (doorW / 2.0)), JS.round(tentBase - doorH), JS.round(doorW), JS.round(doorH))
			# Animated flag at peak
			var flagWave = sin(t * 0.06) * (ph * 0.003)
			ctx.fillStyle = "#c8a030"
			ctx.fillRect(JS.round(tentCX - 1), JS.round(tentPeak - (tentH3 * 0.16)), 1, JS.round(tentH3 * 0.16))
			ctx.fillStyle = "#e8c050"
			ctx.beginPath()
			ctx.moveTo(tentCX, tentPeak - (tentH3 * 0.16))
			ctx.lineTo(tentCX + (tentW3 * 0.12), (tentPeak - (tentH3 * 0.1)) + flagWave)
			ctx.lineTo(tentCX, (tentPeak - (tentH3 * 0.04)) + (flagWave * 0.5))
			ctx.closePath()
			ctx.fill()
			# Guy-ropes and stakes
			ctx.strokeStyle = "#3a2808"
			ctx.lineWidth = 1
			ctx.beginPath()
			ctx.moveTo(tentCX, tentPeak)
			ctx.lineTo(tentCX - (tentW3 * 0.72), tentBase)
			ctx.stroke()
			ctx.beginPath()
			ctx.moveTo(tentCX, tentPeak)
			ctx.lineTo(tentCX + (tentW3 * 0.72), tentBase)
			ctx.stroke()
			ctx.fillStyle = "#5a3810"
			ctx.fillRect(JS.round(tentCX - (tentW3 * 0.73)), JS.round(tentBase), 2, JS.round(ph * 0.018))
			ctx.fillRect(JS.round(tentCX + (tentW3 * 0.71)), JS.round(tentBase), 2, JS.round(ph * 0.018))
			# Lantern hanging off left rope with warm glow
			var lnX = tentCX - (tentW3 * 0.38)
			var lnY = tentBase - (tentH3 * 0.22)
			var lnP = 0.5 + (0.3 * ((sin(t * 0.06) * 0.6) + (sin((t * 0.1) + 1.8) * 0.4)))
			var lng2 = ctx.createRadialGradient(lnX, lnY, 0, lnX, lnY, pw * 0.06)
			lng2.addColorStop(0, "rgba(255,185,45," + JS.s(lnP * 0.5) + ")")
			lng2.addColorStop(1, "transparent")
			ctx.fillStyle = lng2
			ctx.fillRect(lnX - (pw * 0.06), lnY - (pw * 0.06), pw * 0.12, pw * 0.12)
			ctx.fillStyle = "#1a1006"
			ctx.strokeStyle = "#443010"
			ctx.lineWidth = 0.8
			ctx.fillRect(JS.round(lnX - (pw * 0.011)), JS.round(lnY - (ph * 0.016)), JS.round(pw * 0.02), JS.round(ph * 0.025))
			ctx.strokeRect(JS.round(lnX - (pw * 0.011)), JS.round(lnY - (ph * 0.016)), JS.round(pw * 0.02), JS.round(ph * 0.025))
			ctx.fillStyle = "rgba(255,195,40," + JS.s(lnP) + ")"
			ctx.fillRect(JS.round(lnX - 1), JS.round(lnY - (ph * 0.005)), 2, 2)
			ctx.globalAlpha = 1

# Shared hill shape helper (no fill setup — caller sets fillStyle)
func _drawPanelHillShape(ctx = null, px = null, py = null, pw = null, ph = null, phase = null, heightFrac = null):
	var hy = py + (ph * (1 - heightFrac))
	ctx.beginPath()
	for x in range(0, floori(pw) + 1):
		var nx = x / float(pw)
		var y = ((hy + ((sin(((nx * PI) * 2.6) + phase) * ph) * 0.07)) + ((sin(((nx * PI) * 5.8) + (phase * 0.55)) * ph) * 0.035)) + ((sin(((nx * PI) * 11.2) + (phase * 1.1)) * ph) * 0.015)
		if x == 0:
			ctx.moveTo(px + x, JS.round(y))
		else:
			ctx.lineTo(px + x, JS.round(y))
	ctx.lineTo(px + pw, py + ph)
	ctx.lineTo(px, py + ph)
	ctx.closePath()
	ctx.fill()

func showBetweenRuns_map():
	var canvas = document.getElementById("lobby-map-canvas")
	if not JS.t(canvas):
		return
	var wrap_ = canvas.parentElement
	var dpr = JS.or_(window.devicePixelRatio, 1)
	var cssW = JS.round(JS.or_(wrap_.get("clientWidth"), window.innerWidth))
	var cssH = JS.round(JS.or_(wrap_.get("clientHeight"), window.innerHeight))
	canvas.width = JS.round(cssW * dpr)
	canvas.height = JS.round(cssH * dpr)
	canvas.style.width = JS.s(cssW) + "px"
	canvas.style.height = JS.s(cssH) + "px"
	# Start player at return position (e.g. tailor) or default plaza
	var _startX = (_lobbyReturnPos.x if JS.t(_lobbyReturnPos) else LOBBY_PLAZA.x)
	var _startY = (_lobbyReturnPos.y if JS.t(_lobbyReturnPos) else LOBBY_PLAZA.y)
	_lobbyReturnPos = null
	_lobbyPlayerX = _startX
	_lobbyPlayerY = _startY
	_lobbyTargetX = _startX
	_lobbyTargetY = _startY
	_lobbyWalking = false
	_lobbyWalkDest = null
	_lobbyWaypointQueue = []
	_lobbyShootingStars = []
	_lobbyCinematic = null
	_lobbyCinematicTick = 0
	_initLobbyBgZones()
	# re-randomize zone backgrounds each visit
	# Click handler
	canvas.onclick = _lobbyClick
	canvas.onmousemove = _lobbyHover
	canvas.style.cursor = "default"
	if JS.t(_lobbyAnimFrame):
		JS.cancelAnimationFrame(_lobbyAnimFrame)
	_lobbyLoop()
	if JS.t(window.get("_pendingVeilUnlock")):
		window._pendingVeilUnlock = false
		var _fn9 = func():
			Veil.playVeilUnlockAnimation()
		JS.setTimeout(_fn9, 800)

func _lobbyLoop():
	_lobbyTick += 1
	_lobbyCinematicStep()
	_lobbyMovePlayer()
	_lobbyDraw()
	_lobbyAnimFrame = JS.requestAnimationFrame(_lobbyLoop)

func _lobbyCinematicStep():
	if not JS.t(_lobbyCinematic):
		return
	_lobbyCinematicTick += 1
	if _lobbyCinematic == "castle_enter":
		# Transition once wizard has stopped walking (reached gate)
		if not JS.t(_lobbyWalking):
			_lobbyCinematic = "castle_teeth"
			_lobbyCinematicTick = 0
	elif _lobbyCinematic == "castle_teeth":
		if _lobbyCinematicTick > 110:
			_lobbyCinematic = "castle_fade"
			_lobbyCinematicTick = 0
	elif _lobbyCinematic == "castle_fade":
		if _lobbyCinematicTick > 80:
			_lobbyCinematic = null
			_lobbyCinematicTick = 0
			BetweenRuns.lobbyStartRun()

func _lobbyMovePlayer():
	if not JS.t(_lobbyWalking):
		return
	var _mc = document.getElementById("lobby-map-canvas")
	var _dpr = JS.or_(window.devicePixelRatio, 1)
	var W = (JS.or_(JS.g(_mc, "width"), 400)) / float(_dpr)
	var H = (JS.or_(JS.g(_mc, "height"), 600)) / float(_dpr)
	var px = _lobbyPlayerX * W
	var py = _lobbyPlayerY * H
	var tx = _lobbyTargetX * W
	var ty = _lobbyTargetY * H
	var dx = tx - px
	var dy = ty - py
	var dist = sqrt((dx * dx) + (dy * dy))
	var speed = (1.6 if _lobbyCinematic == "castle_enter" else 3.2)
	if dist < (speed + 1):
		_lobbyPlayerX = _lobbyTargetX
		_lobbyPlayerY = _lobbyTargetY
		_lobbyWalking = false
		if len(_lobbyWaypointQueue) > 0:
			var next = _lobbyWaypointQueue.pop_front()
			_lobbyTargetX = next.x
			_lobbyTargetY = next.y
			_lobbyWalking = true
			if JS.t(next.get("finalDest")):
				_lobbyWalkDest = next.finalDest
		elif JS.t(_lobbyWalkDest):
			var dest = _lobbyWalkDest
			_lobbyWalkDest = null
			JS.setTimeout(func(): return _openLobbyLocation(dest), 80)
	else:
		_lobbyFacingLeft = dx < 0
		_lobbyPlayerX += ((dx / float(dist)) * speed) / float(W)
		_lobbyPlayerY += ((dy / float(dist)) * speed) / float(H)

func _lobbyDraw():
	var canvas = document.getElementById("lobby-map-canvas")
	if not JS.t(canvas):
		return
	var ctx = canvas.getContext("2d")
	var dpr = JS.or_(window.devicePixelRatio, 1)
	ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
	var W = JS.round(canvas.width / float(dpr))
	var H = JS.round(canvas.height / float(dpr))
	_drawLobbyMap(ctx, W, H)

func _drawShootingStars(ctx = null, W = null, H = null):
	# Spawn a new shooting star occasionally
	if (randf() < 0.012 and len(_lobbyShootingStars) < 5):
		var angle = (PI / 6.0) + (randf() * (PI / 6.0))
		# 30–60° downward diagonal
		var spd = W * (0.006 + (randf() * 0.008))
		_lobbyShootingStars.append({
			"x": randf() * W,
			"y": (randf() * H) * 0.3,
			"vx": cos(angle) * spd,
			"vy": sin(angle) * spd,
			"life": 0,
			"maxLife": 35 + floori(randf() * 30),
			"len": W * (0.06 + (randf() * 0.08)),
		})
	ctx.save()
	var _fn10 = func(s = null):
		s.x += s.vx
		s.y += s.vy
		s.life += 1
		var progress = s.life / float(s.maxLife)
		# Fade in then fade out
		var alpha = (progress / 0.2 if progress < 0.2 else 1 - ((progress - 0.2) / 0.8))
		# Tail — gradient from bright head to transparent tail
		var tailX = s.x - (s.vx * (s.len / float(JS.hypot([s.vx, s.vy]))))
		var tailY = s.y - (s.vy * (s.len / float(JS.hypot([s.vx, s.vy]))))
		var grad = ctx.createLinearGradient(tailX, tailY, s.x, s.y)
		grad.addColorStop(0, "transparent")
		grad.addColorStop(0.6, "rgba(200,200,255," + JS.s(alpha * 0.3) + ")")
		grad.addColorStop(1, "rgba(255,255,255," + JS.s(alpha) + ")")
		ctx.beginPath()
		ctx.moveTo(tailX, tailY)
		ctx.lineTo(s.x, s.y)
		ctx.strokeStyle = grad
		ctx.lineWidth = 1.5
		ctx.stroke()
		# Bright head dot
		ctx.fillStyle = "rgba(255,255,255," + JS.s(alpha) + ")"
		ctx.beginPath()
		ctx.arc(s.x, s.y, 1.5, 0, PI * 2)
		ctx.fill()
		return (s.life < s.maxLife and s.y < (H * 0.42))
	_lobbyShootingStars = JS.arr(_lobbyShootingStars).filter(_fn10)
	ctx.restore()

func _drawLobbyMap(ctx = null, W = null, H = null):
	# Render scene into offscreen canvas so we can apply brightness+contrast
	# in a single drawImage — avoids the per-draw-call cost of ctx.filter.
	if ((not JS.t(_lobbySceneCanvas) or not JS.eq(_lobbySceneCanvas.width, W)) or not JS.eq(_lobbySceneCanvas.height, H)):
		_lobbySceneCanvas = document.createElement("canvas")
		_lobbySceneCanvas.width = W
		_lobbySceneCanvas.height = H
	var sc = _lobbySceneCanvas.getContext("2d")
	# Base sky fill
	sc.fillStyle = "#08050e"
	sc.fillRect(0, 0, W, H)
	# Zone backgrounds in the distance
	_drawLobbyZonePanels(sc, W, H)
	# Ground (horizon) — dark grassy green
	var _hz = _lobbyMY(0.6, W, H) * H
	var gnd = sc.createLinearGradient(0, _hz, 0, H)
	gnd.addColorStop(0, "#0e1e08")
	gnd.addColorStop(0.4, "#0c1a07")
	gnd.addColorStop(1, "#081205")
	sc.fillStyle = gnd
	sc.fillRect(0, _hz, W, H)
	# Thin horizon glow
	var _hzT = _lobbyMY(0.57, W, H) * H
	var _hzB = _lobbyMY(0.63, W, H) * H
	var hglow = sc.createLinearGradient(0, _hzT, 0, _hzB)
	hglow.addColorStop(0, "transparent")
	hglow.addColorStop(0.5, "rgba(30,60,12,0.28)")
	hglow.addColorStop(1, "transparent")
	sc.fillStyle = hglow
	sc.fillRect(0, _hzT, W, _hzB - _hzT)
	# Winding dirt paths + foreground detail
	_drawLobbyPaths(sc, W, H)
	_drawLobbyForeground(sc, W, H)
	# Shooting stars
	_drawShootingStars(sc, W, H)
	# Stars — varied sizes, flicker at different rates
	sc.save()
	for i in range(80):
		var sx = JS.mod((i * 137) + 17, W)
		var sy = JS.mod((i * 97) + 31, _lobbyMY(0.55, W, H) * H)
		var flicker = 0.25 + (0.65 * abs(sin((_lobbyTick * (0.012 + ((JS.mod(i, 7)) * 0.004))) + (i * 1.3))))
		sc.globalAlpha = flicker
		if (JS.mod(i, 9)) == 0:
			var sz = 1.5 + ((JS.mod(i, 3)) * 0.5)
			sc.fillStyle = "#ffffff"
			sc.fillRect(sx - sz, sy, (sz * 2) + 1, 1)
			sc.fillRect(sx, sy - sz, 1, (sz * 2) + 1)
		else:
			var sz = (2 if (JS.mod(i, 5)) == 0 else 1)
			sc.fillStyle = ("#d0c8ff" if (JS.mod(i, 4)) == 0 else "#fffbe0")
			sc.fillRect(sx, sy, sz, sz)
	sc.restore()
	# Moon
	if true:
		var mx = JS.round(W * 0.8)
		var my = JS.round(H * 0.07)
		var mr = max(8, JS.round(W * 0.022))
		sc.save()
		var halo = sc.createRadialGradient(mx, my, mr * 0.6, mx, my, mr * 3.0)
		halo.addColorStop(0, "rgba(220,200,140,0.14)")
		halo.addColorStop(1, "transparent")
		sc.fillStyle = halo
		sc.beginPath()
		sc.arc(mx, my, mr * 3.0, 0, PI * 2)
		sc.fill()
		sc.globalAlpha = 0.82
		sc.fillStyle = "#e8e0c0"
		sc.beginPath()
		sc.arc(mx, my, mr, 0, PI * 2)
		sc.fill()
		sc.globalAlpha = 1
		sc.fillStyle = "#08051a"
		sc.beginPath()
		sc.arc(mx + JS.round(mr * 0.55), my - JS.round(mr * 0.15), JS.round(mr * 0.86), 0, PI * 2)
		sc.fill()
		sc.restore()
	_drawLobbycastle(sc, W, H)
	_drawLobbyFountain(sc, W, H)
	for loc in JS.iter(LOBBY_LOCATIONS):
		if loc.get("id") == "castle":
			continue
		_drawLobbyBuilding(sc, loc, W, H)
	_drawLobbyPlayer(sc, W, H)
	# Foreground brightness gradient — ground and buildings brighter than sky
	var fgLift = sc.createLinearGradient(0, H * 0.35, 0, H)
	fgLift.addColorStop(0, "rgba(255,255,255,0)")
	fgLift.addColorStop(1, "rgba(255,255,255,0.18)")
	sc.fillStyle = fgLift
	sc.fillRect(0, H * 0.35, W, H * 0.65)
	# Copy to main canvas — one filtered drawImage, negligible cost
	ctx.save()
	if ((_lobbyCinematic == "castle_teeth" and _lobbyCinematicTick >= 97) and _lobbyCinematicTick < 110):
		var intensity = (1 - ((_lobbyCinematicTick - 97) / 13.0)) * 3
		ctx.translate(((randf() - 0.5) * intensity) * 2, (randf() - 0.5) * intensity)
	ctx.filter = "brightness(1.10) contrast(1.06)"
	ctx.drawImage(_lobbySceneCanvas, 0, 0)
	ctx.filter = "none"
	ctx.restore()
	# end shake transform
	# ── DEV: refresh-background button (top-right corner) ────────────────────
	if true:
		var bw = max(60, W * 0.09)
		var bh = max(18, H * 0.032)
		var bx = (W - bw) - 6
		var by = 6
		var hov = _lobbyHoveredId == "__refreshBg__"
		ctx.save()
		ctx.fillStyle = ("#1a1a2a" if hov else "#0e0e18")
		ctx.strokeStyle = ("#8866cc" if hov else "#443366")
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.roundRect(bx, by, bw, bh, 3)
		ctx.fill()
		ctx.stroke()
		ctx.font = JS.s(max(9, JS.round(bh * 0.52))) + "px monospace"
		ctx.textAlign = "center"
		ctx.textBaseline = "middle"
		ctx.fillStyle = ("#bb99ff" if hov else "#665588")
		ctx.fillText("⟳ bg", bx + (bw / 2.0), by + (bh / 2.0))
		ctx.restore()
	# Fade to black overlay (no shake)
	if _lobbyCinematic == "castle_fade":
		var fadeAlpha = min(1, _lobbyCinematicTick / 60.0)
		ctx.fillStyle = "rgba(0,0,0," + JS.s(fadeAlpha) + ")"
		ctx.fillRect(0, 0, W, H)

# Draws a brick/stone block pattern clipped to a rectangle.
# blockH controls row height; seed gives variation between surfaces.
func _drawStoneBlocks(ctx = null, rx = null, ry = null, rw = null, rh = null, blockH = null, seed_ = null):
	ctx.save()
	ctx.beginPath()
	ctx.rect(rx, ry, rw, rh)
	ctx.clip()
	var mortar = 1
	var rows = ceili(rh / float(blockH + mortar)) + 1
	for row in range(0, floori(rows) + 1):
		var rowY = ry + (row * (blockH + mortar))
		var offset = (0 if (JS.mod(row, 2)) == 0 else blockH * 0.55)
		var sx = rx - offset
		var col = 0
		while sx < (rx + rw):
			var bw = blockH * (1.5 + ((JS.mod(((seed_ * 7) + (row * 13)) + (col * 5), 9)) * 0.1))
			if (sx + bw) > rx:
				var bx = max(sx, rx)
				var clw = min((sx + bw) - mortar, rx + rw) - bx
				if clw > 0:
					var v = 18 + (JS.mod((seed_ + (row * 7)) + (col * 3), 10))
					ctx.fillStyle = "rgb(" + JS.s(v) + "," + JS.s(v) + "," + JS.s(JS.round(v * 1.06)) + ")"
					ctx.fillRect(bx, rowY, clw, blockH)
			sx += bw + mortar
			col += 1
	ctx.restore()

func _drawLobbycastle(ctx = null, W = null, H = null):
	var cx = W * 0.5
	var baseY = _lobbyMY(0.6, W, H) * H
	# horizon line where castle meets ground
	var s = W * (0.5 if W < H else 0.38)
	# zoom castle on portrait mobile
	var t = _lobbyTick
	ctx.save()
	# ── Ominous castle glow backdrop ──────────────────────────────────────────
	var backGlow = ctx.createRadialGradient(cx, baseY - (s * 0.5), s * 0.1, cx, baseY - (s * 0.4), s * 1.1)
	backGlow.addColorStop(0, "rgba(80,20,160,0.22)")
	backGlow.addColorStop(0.5, "rgba(40,10,80,0.12)")
	backGlow.addColorStop(1, "transparent")
	ctx.fillStyle = backGlow
	ctx.fillRect(cx - s, baseY - (s * 1.2), s * 2, s * 1.4)
	# ── Outer curtain walls (wide low flanking walls) ─────────────────────────
	var cwW = s * 0.12
	var cwH = s * 0.22
	for side in JS.iter([-1, 1]):
		var cwX = (cx + ((side * s) * 0.54)) - (cwW if side > 0 else 0)
		var cwY = baseY - cwH
		ctx.fillStyle = "#131315"
		ctx.strokeStyle = "#252530"
		ctx.lineWidth = 1
		ctx.fillRect(cwX, cwY, cwW, cwH)
		_drawStoneBlocks(ctx, cwX, cwY, cwW, cwH, s * 0.026, side * 17)
		ctx.strokeRect(cwX, cwY, cwW, cwH)
		# Curtain wall merlons
		var cmW = cwW / 5.0
		var cmH = s * 0.03
		for i in range(4):
			ctx.fillStyle = "#181818"
			ctx.strokeStyle = "#252530"
			ctx.fillRect(cwX + (i * (cwW / 4.0)), cwY - cmH, cmW, cmH)
			ctx.strokeRect(cwX + (i * (cwW / 4.0)), cwY - cmH, cmW, cmH)
	# ── Main keep (central body) ──────────────────────────────────────────────
	var keepW = s * 0.52
	var keepH = s * 0.48
	var keepX = cx - (keepW / 2.0)
	var keepY = baseY - keepH
	ctx.fillStyle = "#131315"
	ctx.strokeStyle = "#2a2535"
	ctx.lineWidth = 1.5
	ctx.fillRect(keepX, keepY, keepW, keepH)
	_drawStoneBlocks(ctx, keepX, keepY, keepW, keepH, s * 0.03, 42)
	ctx.strokeRect(keepX, keepY, keepW, keepH)
	# Keep battlements
	var mW = keepW / 10.0
	var mH = s * 0.04
	for i in range(9):
		if (JS.mod(i, 2)) == 0:
			ctx.fillStyle = "#1a1a1c"
			ctx.strokeStyle = "#2a2535"
			ctx.fillRect(keepX + (i * (keepW / 9.0)), keepY - mH, mW, mH)
			ctx.strokeRect(keepX + (i * (keepW / 9.0)), keepY - mH, mW, mH)
	# Keep windows — glowing amber
	var winW = keepW * 0.1
	var winH = keepH * 0.14
	var winPulse = 0.5 + (0.25 * ((sin(t * 0.01) * 0.65) + (sin(((t * 0.01) * 1.618) + 1.2) * 0.35)))
	for xFrac in JS.iter([0.28, 0.5, 0.72]):
		var wx = (keepX + (keepW * xFrac)) - (winW / 2.0)
		var wy = keepY + (keepH * 0.28)
		# Arch window
		ctx.fillStyle = "rgba(255,180,60," + JS.s(winPulse * 0.7) + ")"
		ctx.beginPath()
		ctx.moveTo(wx, wy + winH)
		ctx.lineTo(wx, wy + (winW / 2.0))
		ctx.arc(wx + (winW / 2.0), wy + (winW / 2.0), winW / 2.0, PI, 0)
		ctx.lineTo(wx + winW, wy + winH)
		ctx.fill()
		# Window glow
		var wg = ctx.createRadialGradient(wx + (winW / 2.0), wy + (winH / 2.0), 0, wx + (winW / 2.0), wy + (winH / 2.0), winW * 1.5)
		wg.addColorStop(0, "rgba(255,160,40," + JS.s(winPulse * 0.3) + ")")
		wg.addColorStop(1, "transparent")
		ctx.fillStyle = wg
		ctx.fillRect(wx - winW, wy - winW, winW * 3, winH * 2)
	# ── Inner connecting walls (keep sides → tower inner face, curtain height) ─
	# Fills any visual seam between the keep edge and the tower at ground level
	for side in JS.iter([-1, 1]):
		var connX = (keepX - (s * 0.16) if side < 0 else keepX + keepW)
		var connY = baseY - cwH
		ctx.fillStyle = "#131315"
		ctx.strokeStyle = "#252530"
		ctx.lineWidth = 1
		ctx.fillRect(connX, connY, s * 0.16, cwH)
		_drawStoneBlocks(ctx, connX, connY, s * 0.16, cwH, s * 0.028, (side * 11) + 3)
		ctx.strokeRect(connX, connY, s * 0.16, cwH)
	# ── Side towers (tall, dramatic) ──────────────────────────────────────────
	var twW = s * 0.16
	var twH = s * 0.68
	for side in JS.iter([-1, 1]):
		var tx = (cx + (side * ((keepW * 0.5) + twW))) - (twW if side > 0 else 0)
		var ty = baseY - twH
		ctx.fillStyle = "#111113"
		ctx.strokeStyle = "#282535"
		ctx.lineWidth = 1.5
		ctx.fillRect(tx, ty, twW, twH)
		_drawStoneBlocks(ctx, tx, ty, twW, twH, s * 0.026, (side * 23) + 7)
		ctx.strokeRect(tx, ty, twW, twH)
		# Tower merlons
		for i in range(4):
			if (JS.mod(i, 2)) == 0:
				ctx.fillStyle = "#181818"
				ctx.strokeStyle = "#282535"
				ctx.fillRect(tx + (i * (twW / 4.0)), ty - mH, (twW / 4.0) - 1, mH)
				ctx.strokeRect(tx + (i * (twW / 4.0)), ty - mH, (twW / 4.0) - 1, mH)
		# Tower windows — flicker independently
		var twPulse = 0.4 + (0.3 * ((sin((t * 0.008) + (side * 2.1)) * 0.55) + (sin((((t * 0.008) * 1.618) + (side * 1.3)) + 3.7) * 0.45)))
		ctx.fillStyle = "rgba(255,200,80," + JS.s(twPulse) + ")"
		var twx = tx + (twW * 0.25)
		var twy = ty + (twH * 0.3)
		var twWin = twW * 0.5
		var twWinH = twH * 0.12
		ctx.beginPath()
		ctx.moveTo(twx, twy + twWinH)
		ctx.lineTo(twx, twy + (twWin / 2.0))
		ctx.arc(twx + (twWin / 2.0), twy + (twWin / 2.0), twWin / 2.0, PI, 0)
		ctx.lineTo(twx + twWin, twy + twWinH)
		ctx.fill()
	# ── "Begin Run" button in top keep section (fits between towers) ─────────
	if true:
		var hovered = _lobbyHoveredId == "castle"
		var btnMaxW = s * 0.26
		# fits within the ~s*0.232 gap between towers (scaled up)
		var btnH = JS.round(max(16, s * 0.085))
		var btnY = JS.round(keepY + (keepH * 0.06))
		var bcx = JS.round(cx)
		ctx.save()
		ctx.textAlign = "center"
		ctx.textBaseline = "middle"
		# Shrink font until text fits
		var fs = JS.round(btnH * 0.55)
		ctx.font = JS.s(fs) + "px 'Cinzel', serif"
		while (ctx.measureText("⚔ Begin Run").width > (btnMaxW * 0.86) and fs > 5):
			fs -= 1
			ctx.font = JS.s(fs) + "px 'Cinzel', serif"
		var txtW = ctx.measureText("⚔ Begin Run").width
		var btnW = JS.round(txtW + (btnH * 0.9))
		var bx = JS.round(bcx - (btnW / 2.0))
		var br = JS.round(btnH * 0.28)
		# Dark background
		ctx.fillStyle = ("#1e1608" if hovered else "#0a0806")
		ctx.strokeStyle = ("#c8a060" if hovered else "#4a3010")
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.moveTo(bx + br, btnY)
		ctx.lineTo((bx + btnW) - br, btnY)
		ctx.arcTo(bx + btnW, btnY, bx + btnW, btnY + br, br)
		ctx.lineTo(bx + btnW, (btnY + btnH) - br)
		ctx.arcTo(bx + btnW, btnY + btnH, (bx + btnW) - br, btnY + btnH, br)
		ctx.lineTo(bx + br, btnY + btnH)
		ctx.arcTo(bx, btnY + btnH, bx, (btnY + btnH) - br, br)
		ctx.lineTo(bx, btnY + br)
		ctx.arcTo(bx, btnY, bx + br, btnY, br)
		ctx.closePath()
		ctx.fill()
		ctx.stroke()
		# Label
		ctx.fillStyle = ("#ffd080" if hovered else "#c8a060")
		if hovered:
			ctx.shadowColor = "#ffd080"
			ctx.shadowBlur = 6
		ctx.fillText("⚔ Begin Run", bcx, btnY + JS.round(btnH / 2.0))
		ctx.restore()
	# ── Gate dimensions (shared by arch + bridge) ────────────────────────────
	var gateW = keepW * 0.32
	var gateH = keepH * 0.45
	var gateX = cx - (gateW / 2.0)
	var gateY = baseY - gateH
	# ── Long drawbridge (raises during castle-enter cinematic) ───────────────
	var bridgeW = gateW
	# exact match so bridge fills arch when raised
	var bridgeTopY = baseY
	var bridgeBotY = _lobbyBridgeBotY(W, H)
	var bridgeLen = bridgeBotY - bridgeTopY
	var parapetW = bridgeW * 0.08
	# Compute raise progress (0 = flat, 1 = fully raised against gate)
	var raiseP = 0
	if (_lobbyCinematic == "castle_teeth" or _lobbyCinematic == "castle_fade"):
		var bt = (110 if _lobbyCinematic == "castle_fade" else _lobbyCinematicTick)
		var raw = max(0, min(1, (bt - 6) / 92.0))
		raiseP = raw * raw
	var tiltScale = max(0, 1 - raiseP)
	# Bridge body — foreshortens from pivot as it raises
	ctx.save()
	ctx.translate(cx, bridgeTopY)
	ctx.scale(1, tiltScale)
	# Flip vertically so the arch crown is at the BOTTOM (far from gate)
	# and the flat edge is at the TOP (touching the gate at baseY).
	ctx.translate(0, bridgeLen)
	ctx.scale(1, -1)
	var bridgeGrad = ctx.createLinearGradient((-bridgeW) / 2.0, 0, bridgeW / 2.0, 0)
	bridgeGrad.addColorStop(0, "#1e1408")
	bridgeGrad.addColorStop(0.5, "#2e2010")
	bridgeGrad.addColorStop(1, "#1e1408")
	# Arch crown at local y=0 (which after the flip appears at the bottom).
	var archCenterY = bridgeW / 2.0
	ctx.beginPath()
	ctx.moveTo((-bridgeW) / 2.0, bridgeLen)
	ctx.lineTo((-bridgeW) / 2.0, archCenterY)
	ctx.arc(0, archCenterY, bridgeW / 2.0, PI, 0)
	# arch crown at y=0
	ctx.lineTo(bridgeW / 2.0, bridgeLen)
	ctx.closePath()
	ctx.fillStyle = bridgeGrad
	ctx.fill()
	# Clip bricks/parapets to arch shape
	ctx.save()
	ctx.beginPath()
	ctx.moveTo((-bridgeW) / 2.0, bridgeLen)
	ctx.lineTo((-bridgeW) / 2.0, archCenterY)
	ctx.arc(0, archCenterY, bridgeW / 2.0, PI, 0)
	ctx.lineTo(bridgeW / 2.0, bridgeLen)
	ctx.closePath()
	ctx.clip()
	ctx.strokeStyle = "#0e0a04"
	ctx.lineWidth = 1
	var rowCount = 8
	for i in range(1, ceili(rowCount)):
		var rowY = bridgeLen * (i / float(rowCount))
		ctx.beginPath()
		ctx.moveTo((-bridgeW) / 2.0, rowY)
		ctx.lineTo(bridgeW / 2.0, rowY)
		ctx.stroke()
	for row in range(ceili(rowCount)):
		var rowY = bridgeLen * (row / float(rowCount))
		var off = (0 if (JS.mod(row, 2)) == 0 else bridgeW / 6.0)
		for col in range(4):
			var colX = (((-bridgeW) / 2.0) + off) + (col * (bridgeW / 3.0))
			if (colX > ((-bridgeW) / 2.0) and colX < (bridgeW / 2.0)):
				ctx.beginPath()
				ctx.moveTo(colX, rowY)
				ctx.lineTo(colX, rowY + (bridgeLen / float(rowCount)))
				ctx.stroke()
	for px in JS.iter([((-bridgeW) / 2.0) - (parapetW * 0.5), (bridgeW / 2.0) - (parapetW * 0.5)]):
		ctx.fillStyle = "#2a1c0c"
		ctx.strokeStyle = "#1a1008"
		ctx.lineWidth = 1
		ctx.fillRect(px, 0, parapetW, bridgeLen)
		ctx.strokeRect(px, 0, parapetW, bridgeLen)
		for i in range(5):
			ctx.fillStyle = "#3a2810"
			ctx.fillRect(px, bridgeLen * (i / 5.0), parapetW, bridgeLen / 10.0)
	ctx.restore()
	# end clip
	ctx.restore()
	# end bridge transform
	# ── Gate arch — drawn after bridge so black opening stays on top ──────────
	ctx.fillStyle = "#000000"
	ctx.beginPath()
	ctx.moveTo(gateX, baseY)
	ctx.lineTo(gateX, gateY + (gateW / 2.0))
	ctx.arc(cx, gateY + (gateW / 2.0), gateW / 2.0, PI, 0)
	ctx.lineTo(gateX + gateW, baseY)
	ctx.fill()
	# Chains — connect at arch springing points (base of the bottom semicircle)
	var springY = baseY + ((bridgeLen - (bridgeW / 2.0)) * tiltScale)
	ctx.strokeStyle = "#7a6030"
	ctx.lineWidth = 2
	for side in JS.iter([-1, 1]):
		ctx.beginPath()
		ctx.moveTo(cx + ((side * bridgeW) / 2.0), springY)
		ctx.lineTo(cx + ((side * gateW) * 0.35), gateY + (gateW * 0.1))
		ctx.stroke()
	# Gate sealed: once bridge closes flush against the gate, cover the opening with stone
	if raiseP > 0.6:
		var sealP = min(1, (raiseP - 0.6) / 0.4)
		ctx.save()
		ctx.globalAlpha = sealP
		var sealGrad = ctx.createLinearGradient(gateX, 0, gateX + gateW, 0)
		sealGrad.addColorStop(0, "#1a1008")
		sealGrad.addColorStop(0.35, "#2a1c10")
		sealGrad.addColorStop(0.65, "#2a1c10")
		sealGrad.addColorStop(1, "#1a1008")
		ctx.fillStyle = sealGrad
		ctx.beginPath()
		ctx.moveTo(gateX, baseY)
		ctx.lineTo(gateX, gateY + (gateW / 2.0))
		ctx.arc(cx, gateY + (gateW / 2.0), gateW / 2.0, PI, 0)
		ctx.lineTo(gateX + gateW, baseY)
		ctx.fill()
		# Horizontal plank lines across the sealed gate
		ctx.strokeStyle = "rgba(10,6,2," + JS.s(sealP * 0.8) + ")"
		ctx.lineWidth = 1
		for i in range(1, 6):
			var py = gateY + ((baseY - gateY) * (i / 6.0))
			ctx.beginPath()
			ctx.moveTo(gateX + 1, py)
			ctx.lineTo((gateX + gateW) - 1, py)
			ctx.stroke()
		ctx.restore()
	ctx.restore()

func _drawLobbyFountain(ctx = null, W = null, H = null):
	var cx = LOBBY_FOUNTAIN.x * W
	var cy = _lobbyMY(LOBBY_FOUNTAIN.y, W, H) * H
	var r = max(22, W * 0.055)
	var t = _lobbyTick
	ctx.save()
	# Outer stone basin rim
	var rimGrad = ctx.createRadialGradient(cx, cy, r * 0.6, cx, cy, r)
	rimGrad.addColorStop(0, "#2a1e40")
	rimGrad.addColorStop(1, "#110c1e")
	ctx.fillStyle = rimGrad
	ctx.beginPath()
	ctx.ellipse(cx, cy, r, r * 0.42, 0, 0, PI * 2)
	ctx.fill()
	ctx.strokeStyle = "#6a4aaa"
	ctx.lineWidth = 2
	ctx.stroke()
	# Water surface inside basin
	var waterGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, r * 0.75)
	waterGrad.addColorStop(0, "#1a4060")
	waterGrad.addColorStop(1, "#0a1828")
	ctx.fillStyle = waterGrad
	ctx.beginPath()
	ctx.ellipse(cx, cy, r * 0.76, r * 0.3, 0, 0, PI * 2)
	ctx.fill()
	# Animated ripples on water surface
	for i in range(3):
		var phase = JS.mod((t * 0.025) + (i * 0.333), 1)
		var rr = (r * 0.12) + ((r * 0.58) * phase)
		ctx.globalAlpha = (1 - phase) * 0.5
		ctx.strokeStyle = "#60a8e0"
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.ellipse(cx, cy, rr, rr * 0.38, 0, 0, PI * 2)
		ctx.stroke()
	ctx.globalAlpha = 1
	# Central stone pillar
	ctx.fillStyle = "#1e1630"
	ctx.strokeStyle = "#5a3a8a"
	ctx.lineWidth = 1
	ctx.beginPath()
	ctx.ellipse(cx, cy - (r * 0.05), r * 0.12, r * 0.06, 0, 0, PI * 2)
	ctx.fill()
	ctx.stroke()
	# Animated water jet — height pulses
	var jetH = r * (0.55 + (0.12 * sin(t * 0.07)))
	var jetGrad = ctx.createLinearGradient(cx, cy - jetH, cx, cy)
	jetGrad.addColorStop(0, "#b8e8ff")
	jetGrad.addColorStop(0.5, "#60b8f0")
	jetGrad.addColorStop(1, "#2060a0")
	ctx.fillStyle = jetGrad
	ctx.beginPath()
	ctx.ellipse(cx, cy - (jetH * 0.5), r * 0.055, jetH * 0.5, 0, 0, PI * 2)
	ctx.fill()
	# Droplets arcing outward from jet tip
	for i in range(7):
		var angle = ((i / 7.0) * PI) * 2
		var phase = JS.mod((t * 0.04) + (i * 0.143), 1)
		var spread = (r * 0.62) * phase
		var dropX = cx + (cos(angle) * spread)
		var dropY = ((cy - jetH) - ((r * 0.35) * sin(phase * PI))) + (jetH * phase)
		ctx.globalAlpha = (1 - phase) * 0.75
		ctx.fillStyle = "#a0d8ff"
		ctx.beginPath()
		ctx.arc(dropX, dropY, max(1, r * 0.025), 0, PI * 2)
		ctx.fill()
	ctx.globalAlpha = 1
	# Magic glow halo around fountain
	var haloPhase = 0.3 + (0.15 * sin(t * 0.04))
	var halo = ctx.createRadialGradient(cx, cy, r * 0.5, cx, cy, r * 1.4)
	halo.addColorStop(0, "rgba(100,60,200," + JS.s(haloPhase) + ")")
	halo.addColorStop(1, "transparent")
	ctx.fillStyle = halo
	ctx.beginPath()
	ctx.ellipse(cx, cy, r * 1.4, r * 0.6, 0, 0, PI * 2)
	ctx.fill()
	# Label
	ctx.font = JS.s(JS.round(W * 0.014)) + "px 'Cinzel', serif"
	ctx.textAlign = "center"
	ctx.textBaseline = "alphabetic"
	ctx.fillStyle = "#7060a0"
	ctx.globalAlpha = 0.65
	ctx.fillText("✦ Town Square ✦", cx, (cy + (r * 0.5)) + (W * 0.022))
	ctx.globalAlpha = 1
	ctx.restore()

# ── Cobblestone paths — tree layout ───────────────────────────────────────
func _drawLobbyPaths(ctx = null, W = null, H = null):
	# Cache paths on an offscreen canvas — expensive cobblestone drawing only runs on size change
	if ((not JS.t(_lobbyPathCanvas) or not JS.eq(_lobbyPathCacheW, W)) or not JS.eq(_lobbyPathCacheH, H)):
		_lobbyPathCanvas = document.createElement("canvas")
		_lobbyPathCanvas.width = W
		_lobbyPathCanvas.height = H
		_lobbyPathCacheW = W
		_lobbyPathCacheH = H
		_drawLobbyPathsActual(_lobbyPathCanvas.getContext("2d"), W, H)
	ctx.drawImage(_lobbyPathCanvas, 0, 0)

func _drawLobbyPathsActual(ctx = null, W = null, H = null):
	var my = func(y = null): return _lobbyMY(y, W, H) * H
	# shorthand: fractional Y → pixel Y
	var fcx = LOBBY_FOUNTAIN.x * W
	var fcy = my.call(LOBBY_FOUNTAIN.y)
	var pathW = max(5, W * 0.012)
	var branchW = pathW * 0.75
	# side branches slightly thinner
	var plazaRX = max(30, W * 0.076)
	var plazaRY = plazaRX * 0.36
	# Helper: point on the plaza ellipse edge toward a given world point
	var _fn11 = func(lx = null, ly = null):
		var a = atan2(ly - fcy, lx - fcx)
		return [fcx + (cos(a) * plazaRX), fcy + (sin(a) * plazaRY)]
	var edgePt = _fn11
	# Helper: point on a quadratic bezier at parameter t
	var _fn12 = func(x0 = null, y0 = null, cpx = null, cpy = null, x1 = null, y1 = null, t = null):
		var mt = 1 - t
		return [
			(((mt * mt) * x0) + (((2 * mt) * t) * cpx)) + ((t * t) * x1),
			(((mt * mt) * y0) + (((2 * mt) * t) * cpy)) + ((t * t) * y1),
		]
	var bezPt = _fn12
	# ── LEFT TRUNK: fountain → archive (farthest left) ──────────────────────
	var archLoc = JS.find(LOBBY_LOCATIONS, func(l = null): return l.get("id") == "archive")
	var guildLoc = JS.find(LOBBY_LOCATIONS, func(l = null): return l.get("id") == "guild")
	var _d13 = edgePt.call(archLoc.x * W, my.call(archLoc.y))
	var ls0x = JS.idx(_d13, 0)
	var ls0y = JS.idx(_d13, 1)
	var ls_cpx = 0.14 * W
	var ls_cpy = my.call(0.79)
	# trunk control point
	var ls_ex = archLoc.x * W
	var ls_ey = my.call(archLoc.y)
	_drawCobblestonePath(ctx, ls0x, ls0y, ls_cpx, ls_cpy, ls_ex, ls_ey, pathW)
	# Branch off trunk at t≈0.40 → guild
	var _d14 = bezPt.call(ls0x, ls0y, ls_cpx, ls_cpy, ls_ex, ls_ey, 0.4)
	var ljx = JS.idx(_d14, 0)
	var ljy = JS.idx(_d14, 1)
	var gl_ex = guildLoc.x * W
	var gl_ey = my.call(guildLoc.y)
	_drawCobblestonePath(ctx, ljx, ljy, ((ljx + gl_ex) * 0.5) + (W * 0.02), (ljy + gl_ey) * 0.5, gl_ex, gl_ey, branchW)
	# ── RIGHT TRUNK: fountain → vault (farthest right) ──────────────────────
	var vaultLoc = JS.find(LOBBY_LOCATIONS, func(l = null): return l.get("id") == "vault")
	var tailorLoc = JS.find(LOBBY_LOCATIONS, func(l = null): return l.get("id") == "tailor")
	var _d15 = edgePt.call(vaultLoc.x * W, my.call(vaultLoc.y))
	var rs0x = JS.idx(_d15, 0)
	var rs0y = JS.idx(_d15, 1)
	var rs_cpx = 0.86 * W
	var rs_cpy = my.call(0.79)
	var rs_ex = vaultLoc.x * W
	var rs_ey = my.call(vaultLoc.y)
	_drawCobblestonePath(ctx, rs0x, rs0y, rs_cpx, rs_cpy, rs_ex, rs_ey, pathW)
	# Branch off trunk at t≈0.40 → tailor
	var _d16 = bezPt.call(rs0x, rs0y, rs_cpx, rs_cpy, rs_ex, rs_ey, 0.4)
	var rjx = JS.idx(_d16, 0)
	var rjy = JS.idx(_d16, 1)
	var tl_ex = tailorLoc.x * W
	var tl_ey = my.call(tailorLoc.y)
	_drawCobblestonePath(ctx, rjx, rjy, ((rjx + tl_ex) * 0.5) - (W * 0.02), (rjy + tl_ey) * 0.5, tl_ex, tl_ey, branchW)
	# ── BOTTOM PATHS: direct from plaza edge ────────────────────────────────
	var _arr17 = JS.iter(["library", "talents"])
	for i in range(len(_arr17)):
		var id = _arr17[i]
		var loc = JS.find(LOBBY_LOCATIONS, func(l = null): return JS.eq(l.id, id))
		var _d18 = edgePt.call(loc.x * W, my.call(loc.y))
		var sx = JS.idx(_d18, 0)
		var sy = JS.idx(_d18, 1)
		var cpx = (0.22 * W if JS.eq(i, 0) else 0.76 * W)
		_drawCobblestonePath(ctx, sx, sy, cpx, my.call(0.96), loc.x * W, my.call(loc.y), pathW)
	# ── BRIDGE PATH: plaza top edge → drawbridge bottom ─────────────────────
	var castleLoc = JS.find(LOBBY_LOCATIONS, func(l = null): return l.get("id") == "castle")
	var _d19 = edgePt.call(castleLoc.x * W, my.call(castleLoc.y))
	var bp0x = JS.idx(_d19, 0)
	var bp0y = JS.idx(_d19, 1)
	var bridgeBotX = 0.5 * W
	var bridgeBotY = _lobbyBridgeBotY(W, H)
	_drawCobblestonePath(ctx, bp0x, bp0y, 0.5 * W, (bp0y + bridgeBotY) * 0.5, bridgeBotX, bridgeBotY, pathW)
	# ── VEIL PATH: branch left from bridge path toward grass beside bridge ───
	var veilLoc = JS.find(LOBBY_LOCATIONS, func(l = null): return l.get("id") == "veil")
	# Branch starts partway along bridge path (t≈0.55, near the lower portion)
	var bpCPy = (bp0y + bridgeBotY) * 0.5
	var _d20 = bezPt.call(bp0x, bp0y, 0.5 * W, bpCPy, bridgeBotX, bridgeBotY, 0.55)
	var vjx = JS.idx(_d20, 0)
	var vjy = JS.idx(_d20, 1)
	var vl_ex = veilLoc.x * W
	var vl_ey = my.call(veilLoc.y)
	_drawCobblestonePath(ctx, vjx, vjy, (vjx + vl_ex) * 0.5, ((vjy + vl_ey) * 0.5) - (H * 0.01), vl_ex, vl_ey, branchW)
	# Thin perspective elliptical ring (drawn last to cap all path starts cleanly)
	_drawCobblestoneRing(ctx, fcx, fcy, plazaRX, plazaRY, pathW)

# Seeded PRNG — stable rock shapes that don't shimmer each frame
func _cobblePrng(seed_ = null):
	var s = [null]
	s[0] = int(seed_)
	var _fn21 = func():
		s[0] = int(JS.imul(s[0], 1664525) + 1013904223)
		return (JS.ushr(s[0], 0)) / 4294967295.0
	return _fn21

# Draws an irregular polygon cobblestone centred at (cx,cy) with avg radius r
func _drawCobbleStone(ctx = null, cx = null, cy = null, r = null, seed_ = null):
	var rng = _cobblePrng(seed_)
	var nV = 6 + (1 if rng.call() > 0.5 else 0)
	# 6 or 7 sides
	var base = rng.call() * PI
	# random starting angle
	var v = 24 + JS.round(rng.call() * 14)
	ctx.fillStyle = "rgb(" + JS.s(v) + "," + JS.s(v - 1) + "," + JS.s(v - 2) + ")"
	ctx.strokeStyle = "#09080a"
	ctx.lineWidth = 0.9
	ctx.beginPath()
	for i in range(ceili(nV)):
		var a = base + (((i / float(nV)) * PI) * 2)
		var ir = r * (0.62 + (rng.call() * 0.52))
		# irregular radius per vertex
		var vx = cx + (cos(a) * ir)
		var vy = cy + ((sin(a) * ir) * 0.72)
		# slight y-squish (perspective)
		if i == 0:
			ctx.moveTo(vx, vy)
		else:
			ctx.lineTo(vx, vy)
	ctx.closePath()
	ctx.fill()
	ctx.stroke()
	# Subtle lighter highlight near top-left of each stone
	ctx.fillStyle = "rgba(255,255,255," + JS.s(0.04 + (rng.call() * 0.04)) + ")"
	ctx.beginPath()
	ctx.ellipse(cx - (r * 0.18), cy - (r * 0.22), r * 0.3, r * 0.2, -0.5, 0, PI * 2)
	ctx.fill()

# Draws cobblestone path along a quadratic bezier
func _drawCobblestonePath(ctx = null, x0 = null, y0 = null, cpx = null, cpy = null, x1 = null, y1 = null, pathW = null):
	# Mortar base
	ctx.strokeStyle = "#0c0b09"
	ctx.lineWidth = pathW + 3
	ctx.lineCap = "round"
	ctx.beginPath()
	ctx.moveTo(x0, y0)
	ctx.quadraticCurveTo(cpx, cpy, x1, y1)
	ctx.stroke()
	ctx.strokeStyle = "#161412"
	ctx.lineWidth = pathW
	ctx.beginPath()
	ctx.moveTo(x0, y0)
	ctx.quadraticCurveTo(cpx, cpy, x1, y1)
	ctx.stroke()
	var roughLen = JS.hypot([x1 - x0, y1 - y0]) * 1.22
	var stoneR = max(2.5, pathW * 0.34)
	var spacing = stoneR * 1.55
	var nStones = max(6, ceili(roughLen / float(spacing)))
	# Seed from endpoints so same path = same pattern
	var baseSeed = JS.round((((x0 * 11) + (y0 * 17)) + (x1 * 7)) + (y1 * 5))
	for s in range(ceili(nStones)):
		var rng = _cobblePrng(baseSeed + (s * 97))
		# Slightly jittered t position
		var t2 = max(0.01, min(0.99, ((s + 0.5) + ((rng.call() - 0.5) * 0.5)) / float(nStones)))
		var mt = 1 - t2
		var px = (((mt * mt) * x0) + (((2 * mt) * t2) * cpx)) + ((t2 * t2) * x1)
		var py = (((mt * mt) * y0) + (((2 * mt) * t2) * cpy)) + ((t2 * t2) * y1)
		# Normal direction for lateral scatter
		var dtx = ((2 * (1 - t2)) * (cpx - x0)) + ((2 * t2) * (x1 - cpx))
		var dty = ((2 * (1 - t2)) * (cpy - y0)) + ((2 * t2) * (y1 - cpy))
		var tLen = JS.or_(sqrt((dtx * dtx) + (dty * dty)), 1)
		var nx = -(dty / float(tLen))
		var ny = dtx / float(tLen)
		# Three lanes across full path width
		var lanes = [-0.4, 0, 0.4]
		var _arr22 = JS.iter(lanes)
		for li in range(len(_arr22)):
			var lane = _arr22[li]
			var lRng = _cobblePrng((baseSeed + (s * 97)) + (li * 1009))
			var across = (lane * pathW) + (((lRng.call() - 0.5) * pathW) * 0.18)
			var sr = stoneR * (0.78 + (lRng.call() * 0.44))
			_drawCobbleStone(ctx, px + (nx * across), py + (ny * across), sr, ((baseSeed + (s * 131)) + (li * 53)) + 77)

# Thin elliptical cobblestone ring — perspective trick makes it look flat on the ground
func _drawCobblestoneRing(ctx = null, cx = null, cy = null, rX = null, rY = null, pathW = null):
	# Ring thickness: narrow so it reads as a single row of cobbles
	var ringW = max(5, pathW * 1.1)
	var sw = max(2, pathW * 0.41)
	# half-size stones along ring
	var innerRX = rX - (ringW * 0.5)
	var innerRY = rY - ((ringW * 0.5) * (rY / float(rX)))
	var outerRX = rX + (ringW * 0.5)
	var outerRY = rY + ((ringW * 0.5) * (rY / float(rX)))
	# Mortar base — two ellipse strokes (outer shadow, inner mortar)
	ctx.strokeStyle = "#0e0c0a"
	ctx.lineWidth = ringW + 3
	ctx.lineCap = "butt"
	ctx.beginPath()
	ctx.ellipse(JS.round(cx), JS.round(cy), rX, rY, 0, 0, PI * 2)
	ctx.stroke()
	ctx.strokeStyle = "#1c1a15"
	ctx.lineWidth = ringW
	ctx.beginPath()
	ctx.ellipse(JS.round(cx), JS.round(cy), rX, rY, 0, 0, PI * 2)
	ctx.stroke()
	# Polygon cobblestones along the ellipse — perspective-scaled
	var circumference = PI * ((3 * (rX + rY)) - sqrt(((3 * rX) + rY) * (rX + (3 * rY))))
	var stoneR = max(2, sw * 0.85)
	var nStones = max(24, ceili(circumference / float(stoneR * 1.55)))
	for s in range(ceili(nStones)):
		var angle = ((s / float(nStones)) * PI) * 2
		var px = cx + (cos(angle) * rX)
		var py = cy + (sin(angle) * rY)
		# Perspective scale: top (angle≈-π/2) = small/far, bottom (angle≈π/2) = large/near
		var pScale = 0.62 + (0.38 * ((sin(angle) + 1) * 0.5))
		_drawCobbleStone(ctx, px, py, stoneR * pScale, (s * 113) + 41)

# ── Foreground environmental detail ───────────────────────────────────────
func _drawLobbyForeground(ctx = null, W = null, H = null):
	var t = _lobbyTick
	var my = func(y = null): return _lobbyMY(y, W, H) * H
	# fractional Y → pixel Y
	# ── River (horizontal across foreground, bridge passes over it) ────────
	var spts = [
		[(-0.02) * W, my.call(0.634)],
		[0.13 * W, my.call(0.622)],
		[0.28 * W, my.call(0.638)],
		[0.5 * W, my.call(0.628)],
		[0.72 * W, my.call(0.638)],
		[0.87 * W, my.call(0.622)],
		[1.02 * W, my.call(0.634)],
	]
	# Draw river: dark shadow, water body, shimmer, bank edges
	var _fn23 = func(col = null, lw = null, off = null):
		ctx.strokeStyle = col
		ctx.lineWidth = lw
		ctx.lineCap = "round"
		ctx.beginPath()
		ctx.moveTo(JS.idx(JS.idx(spts, 0), 0) + off, JS.idx(JS.idx(spts, 0), 1))
		for i in range(1, len(spts)):
			var mp = [
				((JS.idx(JS.idx(spts, i - 1), 0) + JS.idx(spts[i], 0)) / 2.0) + off,
				(JS.idx(JS.idx(spts, i - 1), 1) + JS.idx(spts[i], 1)) / 2.0,
			]
			ctx.quadraticCurveTo(JS.idx(mp, 0), JS.idx(mp, 1), JS.idx(spts[i], 0) + off, JS.idx(spts[i], 1))
		ctx.stroke()
	var drawStream = _fn23
	drawStream.call("#050a12", 44, 0)
	# bank/shadow
	drawStream.call("#081426", 32, 0)
	# deep water
	drawStream.call("#0e1e3a", 20, 0)
	# mid water
	drawStream.call("#142846", 10, 0)
	# surface
	# Animated shimmer highlights
	ctx.globalAlpha = 0.32 + (0.16 * sin(t * 0.04))
	drawStream.call("#206078", 5, -2)
	ctx.globalAlpha = 0.2 + (0.12 * sin((t * 0.06) + 1.2))
	drawStream.call("#4080a0", 3, 3)
	ctx.globalAlpha = 1
	# ── Grass tufts (deterministic scatter across ground) ─────────────────
	var tufts = [
		[0.06, 0.68],
		[0.1, 0.69],
		[0.18, 0.68],
		[0.24, 0.74],
		[0.32, 0.67],
		[0.36, 0.79],
		[0.44, 0.67],
		[0.48, 0.75],
		[0.52, 0.68],
		[0.56, 0.84],
		[0.62, 0.68],
		[0.68, 0.78],
		[0.72, 0.67],
		[0.76, 0.72],
		[0.8, 0.88],
		[0.85, 0.67],
		[0.9, 0.74],
		[0.94, 0.67],
		[0.11, 0.86],
		[0.89, 0.82],
	]
	var _arr25 = JS.iter(tufts)
	for i in range(len(_arr25)):
		var _e24 = _arr25[i]
		var fx = JS.idx(_e24, 0)
		var fy = JS.idx(_e24, 1)
		var gx = fx * W
		var gy = my.call(fy)
		var gs = max(4, W * 0.006)
		var sway = (sin((t * 0.022) + (i * 1.4)) * gs) * 0.35
		ctx.strokeStyle = ("#2a4410" if (JS.mod(i, 3)) == 0 else ("#1e3808" if (JS.mod(i, 3)) == 1 else "#163010"))
		ctx.lineWidth = 1
		for b in range(3):
			var bx = gx + (((b - 1) * gs) * 0.5)
			ctx.beginPath()
			ctx.moveTo(JS.round(bx), JS.round(gy))
			ctx.lineTo(JS.round((bx + sway) + (((b - 1) * gs) * 0.25)), JS.round(gy - (gs * (0.7 + (b * 0.25)))))
			ctx.stroke()
	# ── Small rocks scattered here and there ──────────────────────────────
	var rocks = [[0.09, 0.67], [0.38, 0.74], [0.62, 0.81], [0.88, 0.7], [0.23, 0.88]]
	var _arr27 = JS.iter(rocks)
	for i in range(len(_arr27)):
		var _e26 = _arr27[i]
		var fx = JS.idx(_e26, 0)
		var fy = JS.idx(_e26, 1)
		var rx = fx * W
		var ry = my.call(fy)
		var rs = max(2, W * 0.005)
		ctx.fillStyle = "#14120e"
		ctx.beginPath()
		ctx.ellipse(JS.round(rx), JS.round(ry), JS.round(rs * (1.4 + (i * 0.1))), JS.round(rs * 0.7), 0.2 + (i * 0.3), 0, PI * 2)
		ctx.fill()
		ctx.fillStyle = "#1c1a16"
		ctx.beginPath()
		ctx.ellipse(JS.round(rx - (rs * 0.2)), JS.round(ry - (rs * 0.15)), JS.round(rs * 0.6), JS.round(rs * 0.35), 0.2 + (i * 0.3), 0, PI * 2)
		ctx.fill()
	# ── Edge trees (silhouettes at left and right margins) ────────────────
	var edgeTrees = [
		{"x": 0.02, "y": 0.68, "s": 0.8},
		{"x": 0.04, "y": 0.73, "s": 0.65},
		{"x": 0.96, "y": 0.67, "s": 0.75},
		{"x": 0.98, "y": 0.72, "s": 0.6},
		{"x": 0.01, "y": 0.78, "s": 0.55},
		{"x": 0.99, "y": 0.79, "s": 0.5},
	]
	for tr in JS.iter(edgeTrees):
		var txp = tr.x * W
		var typ = my.call(tr.y)
		var trs = tr.s * max(16, W * 0.022)
		ctx.fillStyle = "#1a0e06"
		ctx.fillRect(JS.round(txp - (trs * 0.16)), JS.round(typ - (trs * 1.2)), JS.round(trs * 0.32), JS.round(trs * 1.2))
		ctx.fillStyle = "#061208"
		ctx.beginPath()
		ctx.arc(JS.round(txp), JS.round(typ - (trs * 1.4)), JS.round(trs * 0.75), 0, PI * 2)
		ctx.fill()
		ctx.beginPath()
		ctx.arc(JS.round(txp - (trs * 0.35)), JS.round(typ - (trs * 1.2)), JS.round(trs * 0.55), 0, PI * 2)
		ctx.fill()
		ctx.beginPath()
		ctx.arc(JS.round(txp + (trs * 0.35)), JS.round(typ - (trs * 1.1)), JS.round(trs * 0.5), 0, PI * 2)
		ctx.fill()
	# ── Small wildflowers along river banks ────────────────────────────────
	var flowers = [[0.08, 0.65], [0.2, 0.66], [0.42, 0.64], [0.62, 0.65], [0.78, 0.66], [0.92, 0.65]]
	var _arr29 = JS.iter(flowers)
	for i in range(len(_arr29)):
		var _e28 = _arr29[i]
		var fx = JS.idx(_e28, 0)
		var fy = JS.idx(_e28, 1)
		var flx = fx * W
		var fly = my.call(fy)
		var flr = max(1, W * 0.004)
		var fc = JS.idx(["#3a1a30", "#1a1a40", "#2a1a10", "#1a2a10"], i)
		ctx.fillStyle = fc
		ctx.beginPath()
		ctx.arc(JS.round(flx), JS.round(fly), JS.round(flr), 0, PI * 2)
		ctx.fill()
		# Stem
		ctx.strokeStyle = "#0e1808"
		ctx.lineWidth = 0.8
		ctx.beginPath()
		ctx.moveTo(JS.round(flx), JS.round(fly))
		ctx.lineTo(JS.round(flx), JS.round(fly + (flr * 2.5)))
		ctx.stroke()

# ── Notification badge check ───────────────────────────────────────────────
func _lobbyBuildingHasNotif(id = null):
	var meta = Artifacts.getMeta()
	var phos = JS.or_(meta.get("phos"), 0)
	if id == "vault":
		return len(JS.or_(meta.get("unseenArtifacts"), [])) > 0
	if id == "library":
		if len(JS.or_(meta.get("unseenBookIds"), [])) > 0:
			return true
		var bul = JS.or_(meta.get("bookUpgradeLevels"), {})
		var bsl = JS.or_(meta.get("bookSlotUpgrades"), {})
		for bid in JS.iter(JS.or_(meta.get("ownedBookIds"), [])):
			var cat = Spellbooks.SPELLBOOK_CATALOGUE[bid]
			if not JS.t(cat):
				continue
			var lvl = JS.or_(JS.idx(bul, bid), 0)
			if (lvl < 4 and phos >= (JS.or_(JS.idx(JS.or_(cat.get("upgradeCosts"), []), lvl), 0))):
				return true
			var ps = JS.or_(JS.idx(bsl, bid), {})
			if ((JS.or_(ps.get("spellSlots"), 0)) < 3 and phos >= (((JS.or_(ps.get("spellSlots"), 0)) + 1) * 10)):
				return true
		var def = JS.or_(JS.idx(bsl, "default"), {})
		if ((JS.or_(def.get("spellSlots"), 0)) < 3 and phos >= (((JS.or_(def.get("spellSlots"), 0)) + 1) * 10)):
			return true
		return false
	if id == "talents":
		var talents = JS.or_(meta.get("talents"), {})
		for key in JS.iter(JS.keys(JS.or_(Talents.TALENT_TREE, {}))):
			for node in JS.iter(Talents.TALENT_TREE[key].nodes):
				var lvl = JS.or_(JS.idx(talents, node.id), 0)
				if (lvl < node.maxLevel and phos >= JS.callm(node, "cost", [lvl + 1])):
					return true
		return false
	return false

# ── Building dispatcher ────────────────────────────────────────────────────
func _drawLobbyBuilding(ctx = null, loc = null, W = null, H = null):
	var hovered = JS.eq(_lobbyHoveredId, loc.id)
	var bx = JS.round(loc.x * W)
	var by = JS.round(_lobbyMY(loc.y, W, H) * H)
	var bs = max(14, JS.round(min(W * (0.05 if W < H else 0.034), H * 0.06)))
	var t = _lobbyTick
	ctx.save()
	match loc.id:
		"archive":
			_drawBuildingArchive(ctx, bx, by, bs, hovered, t)
		"vault":
			_drawBuildingVault(ctx, bx, by, bs, hovered, t)
		"library":
			_drawBuildingLibrary(ctx, bx, by, bs, hovered, t)
		"talents":
			_drawBuildingTalentTree(ctx, bx, by, bs, hovered, t)
		"guild":
			_drawBuildingGuild(ctx, bx, by, bs, hovered, t)
		"tailor":
			_drawBuildingTailor(ctx, bx, by, bs, hovered, t)
		"veil":
			_drawBuildingVeil(ctx, bx, by, bs, hovered, t)
	# Label below
	var fs = max(8, JS.round(W * 0.011))
	ctx.font = JS.s(fs) + "px 'Cinzel', serif"
	ctx.textAlign = "center"
	ctx.textBaseline = "top"
	var _veilLocked = (loc.get("id") == "veil" and not (true and Veil._veilIsUnlocked()))
	ctx.fillStyle = (("#9a8a90" if hovered else "#4a3a45") if _veilLocked else ("#c8a060" if hovered else "#6a5030"))
	ctx.fillText(("Ruined Portal" if _veilLocked else loc.label), bx, by + max(4, bs * 0.15))
	ctx.restore()
	# Notification dot — drawn after restore so it's always on top
	if _lobbyBuildingHasNotif(loc.id):
		var dotR = max(3, JS.round(bs * 0.22))
		var dotX = bx + JS.round(bs * 0.85)
		var dotY = by - JS.round(bs * 1.15)
		var pulse = 0.65 + (0.35 * sin(t * 0.09))
		var isArtifact = loc.get("id") == "vault"
		ctx.save()
		# Glow ring
		ctx.globalAlpha = pulse * 0.4
		ctx.fillStyle = ("#a080ff" if isArtifact else "#c8a060")
		ctx.beginPath()
		ctx.arc(dotX, dotY, dotR + 2, 0, PI * 2)
		ctx.fill()
		# Solid dot
		ctx.globalAlpha = 0.95
		ctx.fillStyle = ("#9060ee" if isArtifact else "#c8a030")
		ctx.beginPath()
		ctx.arc(dotX, dotY, dotR, 0, PI * 2)
		ctx.fill()
		# White highlight
		ctx.globalAlpha = 0.7
		ctx.fillStyle = "#ffffff"
		ctx.beginPath()
		ctx.arc(dotX - (dotR * 0.3), dotY - (dotR * 0.3), dotR * 0.35, 0, PI * 2)
		ctx.fill()
		ctx.restore()

# ── Archive — squat stone records hall ────────────────────────────────────
func _drawBuildingArchive(ctx = null, bx = null, by = null, bs = null, hov = null, t = null):
	var bw = bs * 2.0
	var bh = bs * 1.25
	# Wall body
	ctx.fillStyle = ("#1e1e22" if JS.t(hov) else "#171719")
	ctx.fillRect(JS.round(bx - (bw / 2.0)), JS.round(by - bh), JS.round(bw), JS.round(bh))
	_drawStoneBlocks(ctx, bx - (bw / 2.0), by - bh, bw, bh, max(4, bs * 0.2), 7)
	# Stepped gable roof
	ctx.fillStyle = "#10100f"
	ctx.beginPath()
	ctx.moveTo((bx - (bw / 2.0)) - (bs * 0.1), by - bh)
	ctx.lineTo(bx, (by - bh) - (bs * 0.52))
	ctx.lineTo((bx + (bw / 2.0)) + (bs * 0.1), by - bh)
	ctx.closePath()
	ctx.fill()
	ctx.strokeStyle = "#252523"
	ctx.lineWidth = 1
	ctx.beginPath()
	ctx.moveTo((bx - (bw / 2.0)) - (bs * 0.1), by - bh)
	ctx.lineTo((bx + (bw / 2.0)) + (bs * 0.1), by - bh)
	ctx.stroke()
	# Arched door
	var dw = bs * 0.52
	var dh = bh * 0.52
	ctx.fillStyle = "#09070e"
	ctx.fillRect(JS.round(bx - (dw / 2.0)), JS.round(by - dh), JS.round(dw), JS.round(dh))
	ctx.beginPath()
	ctx.arc(JS.round(bx), JS.round(by - dh), JS.round(dw / 2.0), PI, 0)
	ctx.fill()
	ctx.strokeStyle = "#2a2010"
	ctx.lineWidth = 1
	ctx.beginPath()
	ctx.moveTo(bx - (dw / 2.0), by - dh)
	ctx.lineTo(bx - (dw / 2.0), by)
	ctx.stroke()
	ctx.beginPath()
	ctx.moveTo(bx + (dw / 2.0), by - dh)
	ctx.lineTo(bx + (dw / 2.0), by)
	ctx.stroke()
	ctx.beginPath()
	ctx.arc(bx, by - dh, dw / 2.0, PI, 0)
	ctx.stroke()
	# Slit windows (warm dim glow behind)
	for ox in JS.iter([(-bw) * 0.34, bw * 0.26]):
		var wx = bx + ox
		var wy = by - (bh * 0.72)
		var ww2 = bs * 0.11
		var wh2 = bh * 0.26
		ctx.fillStyle = "rgba(100,70,25,0.12)"
		ctx.fillRect(JS.round(wx - (ww2 * 0.5)), JS.round(wy - 2), JS.round(ww2 + 4), JS.round(wh2 + 4))
		ctx.fillStyle = "#07060c"
		ctx.fillRect(JS.round(wx - (ww2 * 0.5)), JS.round(wy), JS.round(ww2), JS.round(wh2))
		ctx.strokeStyle = "#2a1e0e"
		ctx.lineWidth = 0.8
		ctx.strokeRect(JS.round(wx - (ww2 * 0.5)), JS.round(wy), JS.round(ww2), JS.round(wh2))
	# Carved scroll motif above door (3 horizontal score lines)
	ctx.strokeStyle = "#2e1e0a"
	ctx.lineWidth = 0.8
	for i in range(3):
		ctx.beginPath()
		ctx.moveTo(bx - (bs * 0.14), ((by - dh) - (bs * 0.18)) - ((i * bs) * 0.09))
		ctx.lineTo(bx + (bs * 0.14), ((by - dh) - (bs * 0.18)) - ((i * bs) * 0.09))
		ctx.stroke()
	if JS.t(hov):
		ctx.strokeStyle = "#c8a060"
		ctx.lineWidth = 1.5
		ctx.strokeRect(JS.round(bx - (bw / 2.0)), JS.round(by - bh), JS.round(bw), JS.round(bh))

# ── Vault — heavily fortified treasury ────────────────────────────────────
func _drawBuildingVault(ctx = null, bx = null, by = null, bs = null, hov = null, t = null):
	var bw = bs * 1.8
	var bh = bs * 1.1
	# Battered walls (slightly wider at base)
	ctx.fillStyle = ("#1a1a1c" if JS.t(hov) else "#141416")
	ctx.beginPath()
	ctx.moveTo((bx - (bw / 2.0)) - (bs * 0.1), by)
	ctx.lineTo(bx - (bw / 2.0), by - bh)
	ctx.lineTo(bx + (bw / 2.0), by - bh)
	ctx.lineTo((bx + (bw / 2.0)) + (bs * 0.1), by)
	ctx.closePath()
	ctx.fill()
	_drawStoneBlocks(ctx, (bx - (bw / 2.0)) - (bs * 0.1), by - bh, bw + (bs * 0.2), bh, max(4, bs * 0.22), 13)
	# Flat crenellated top (merlons)
	var btX = (bx - (bw / 2.0)) - (bs * 0.1)
	var btW = bw + (bs * 0.2)
	var mW = max(4, bs * 0.18)
	var mH = max(3, bs * 0.18)
	var mGap = max(3, bs * 0.14)
	var mx2 = btX
	while (mx2 + mW) <= (btX + btW):
		ctx.fillStyle = ("#1a1a1c" if JS.t(hov) else "#141416")
		ctx.fillRect(JS.round(mx2), JS.round((by - bh) - mH), JS.round(mW), JS.round(mH))
		_drawStoneBlocks(ctx, mx2, (by - bh) - mH, mW, mH, max(3, bs * 0.18), 13 + JS.round(mx2))
		mx2 += mW + mGap
	# Heavy banded door
	var dw = bs * 0.58
	var dh = bh * 0.68
	ctx.fillStyle = "#1e1006"
	# old dark wood
	ctx.fillRect(JS.round(bx - (dw / 2.0)), JS.round(by - dh), JS.round(dw), JS.round(dh))
	# Iron bands
	for i in range(4):
		ctx.fillStyle = "#252525"
		ctx.fillRect(JS.round(bx - (dw / 2.0)), JS.round((by - dh) + ((i * dh) / 4.0)), JS.round(dw), JS.round(max(2, bs * 0.05)))
	# Rivets on bands
	ctx.fillStyle = "#353535"
	for i in range(4):
		for j in range(2):
			ctx.beginPath()
			ctx.arc(JS.round(((bx - (dw / 2.0)) + (bs * 0.09)) + (j * (dw - (bs * 0.18)))), JS.round(((by - dh) + ((i * dh) / 4.0)) + max(1, bs * 0.025)), max(1, bs * 0.04), 0, PI * 2)
			ctx.fill()
	# Door frame
	ctx.strokeStyle = "#3a2010"
	ctx.lineWidth = 1
	ctx.strokeRect(JS.round(bx - (dw / 2.0)), JS.round(by - dh), JS.round(dw), JS.round(dh))
	# Keyhole
	ctx.fillStyle = "#0c0a08"
	ctx.beginPath()
	ctx.arc(JS.round(bx), JS.round(by - (dh * 0.38)), max(2, bs * 0.05), 0, PI * 2)
	ctx.fill()
	ctx.fillRect(JS.round(bx - (bs * 0.03)), JS.round(by - (dh * 0.38)), JS.round(bs * 0.06), JS.round(bs * 0.1))
	# Crest above door
	ctx.strokeStyle = "#382808"
	ctx.lineWidth = 1
	ctx.beginPath()
	ctx.arc(JS.round(bx), JS.round((by - dh) - (bs * 0.14)), JS.round(max(4, bs * 0.12)), 0, PI * 2)
	ctx.stroke()
	ctx.strokeStyle = "#2a2008"
	ctx.lineWidth = 0.8
	ctx.beginPath()
	ctx.moveTo(bx, (by - dh) - (bs * 0.26))
	ctx.lineTo(bx, (by - dh) - (bs * 0.02))
	ctx.stroke()
	ctx.beginPath()
	ctx.moveTo(bx - (bs * 0.12), (by - dh) - (bs * 0.14))
	ctx.lineTo(bx + (bs * 0.12), (by - dh) - (bs * 0.14))
	ctx.stroke()
	if JS.t(hov):
		ctx.strokeStyle = "#c8a060"
		ctx.lineWidth = 1.5
		ctx.beginPath()
		ctx.moveTo((bx - (bw / 2.0)) - (bs * 0.1), by)
		ctx.lineTo(bx - (bw / 2.0), by - bh)
		ctx.lineTo(bx + (bw / 2.0), by - bh)
		ctx.lineTo((bx + (bw / 2.0)) + (bs * 0.1), by)
		ctx.stroke()

# ── Library — tall narrow spellbook shop ──────────────────────────────────
func _drawBuildingLibrary(ctx = null, bx = null, by = null, bs = null, hov = null, t = null):
	var bw = bs * 1.45
	var bh = bs * 1.55
	# Wall (dark wood/plaster)
	ctx.fillStyle = ("#1e1408" if JS.t(hov) else "#16100a")
	ctx.fillRect(JS.round(bx - (bw / 2.0)), JS.round(by - bh), JS.round(bw), JS.round(bh))
	# Wood plank lines
	ctx.strokeStyle = "#100c06"
	ctx.lineWidth = 0.8
	var plankH = max(4, bs * 0.18)
	var i = 0
	while i < ceili(bh / float(plankH)):
		var ly = (by - bh) + (i * plankH)
		ctx.beginPath()
		ctx.moveTo(bx - (bw / 2.0), ly)
		ctx.lineTo(bx + (bw / 2.0), ly)
		ctx.stroke()
		i += 1
	# Steeply pitched roof
	ctx.fillStyle = "#0e0c08"
	ctx.beginPath()
	ctx.moveTo((bx - (bw / 2.0)) - (bs * 0.08), by - bh)
	ctx.lineTo(bx, (by - bh) - (bs * 0.82))
	ctx.lineTo((bx + (bw / 2.0)) + (bs * 0.08), by - bh)
	ctx.closePath()
	ctx.fill()
	ctx.strokeStyle = "#1c1810"
	ctx.lineWidth = 0.8
	ctx.beginPath()
	ctx.moveTo((bx - (bw / 2.0)) - (bs * 0.08), by - bh)
	ctx.lineTo((bx + (bw / 2.0)) + (bs * 0.08), by - bh)
	ctx.stroke()
	# Large glowing window (warm amber inside)
	var ww = bw * 0.6
	var wh = bh * 0.34
	var wx = bx - (ww / 2.0)
	var wy = by - (bh * 0.72)
	# Glow behind
	var wglo = ctx.createRadialGradient(bx, wy + (wh / 2.0), 0, bx, wy + (wh / 2.0), ww * 0.9)
	wglo.addColorStop(0, "rgba(190,120,35,0.28)")
	wglo.addColorStop(1, "transparent")
	ctx.fillStyle = wglo
	ctx.fillRect(bx - ww, wy - wh, ww * 2, wh * 3)
	ctx.fillStyle = "#100e08"
	ctx.fillRect(JS.round(wx), JS.round(wy), JS.round(ww), JS.round(wh))
	ctx.fillStyle = "rgba(170,100,28,0.20)"
	ctx.fillRect(JS.round(wx), JS.round(wy), JS.round(ww), JS.round(wh))
	# Window frame cross
	ctx.strokeStyle = "#1e1608"
	ctx.lineWidth = 1
	ctx.strokeRect(JS.round(wx), JS.round(wy), JS.round(ww), JS.round(wh))
	ctx.beginPath()
	ctx.moveTo(bx, wy)
	ctx.lineTo(bx, wy + wh)
	ctx.stroke()
	ctx.beginPath()
	ctx.moveTo(wx, wy + (wh / 2.0))
	ctx.lineTo(wx + ww, wy + (wh / 2.0))
	ctx.stroke()
	# Book silhouettes in window
	var bkColors = ["#0e1830", "#12082a", "#1a0a20", "#080e18"]
	for i_2 in range(3):
		ctx.fillStyle = bkColors[i_2]
		ctx.fillRect(JS.round((bx - (ww * 0.38)) + ((i_2 * ww) * 0.26)), JS.round(wy + (wh * 0.22)), JS.round(ww * 0.18), JS.round(wh * 0.58))
	# Door
	var ddw = bw * 0.36
	var ddh = bh * 0.28
	ctx.fillStyle = "#0c0808"
	ctx.fillRect(JS.round(bx - (ddw / 2.0)), JS.round(by - ddh), JS.round(ddw), JS.round(ddh))
	ctx.strokeStyle = "#221608"
	ctx.lineWidth = 0.8
	ctx.strokeRect(JS.round(bx - (ddw / 2.0)), JS.round(by - ddh), JS.round(ddw), JS.round(ddh))
	# Peaked awning over door
	ctx.fillStyle = "#18120a"
	ctx.beginPath()
	ctx.moveTo((bx - (ddw / 2.0)) - (bs * 0.06), by - ddh)
	ctx.lineTo(bx, (by - ddh) - (bs * 0.16))
	ctx.lineTo((bx + (ddw / 2.0)) + (bs * 0.06), by - ddh)
	ctx.closePath()
	ctx.fill()
	# Hanging book sign
	ctx.strokeStyle = "#2a1808"
	ctx.lineWidth = 0.8
	ctx.beginPath()
	ctx.moveTo(bx + (bw * 0.3), by - (bh * 0.45))
	ctx.lineTo(bx + (bw * 0.3), by - (bh * 0.3))
	ctx.stroke()
	ctx.fillStyle = "#161008"
	ctx.fillRect(JS.round(bx + (bw * 0.22)), JS.round((by - (bh * 0.3)) - (bs * 0.12)), JS.round((bs * 0.16) * 1.2), JS.round(bs * 0.12))
	ctx.strokeStyle = "#3a2010"
	ctx.lineWidth = 0.6
	ctx.strokeRect(JS.round(bx + (bw * 0.22)), JS.round((by - (bh * 0.3)) - (bs * 0.12)), JS.round((bs * 0.16) * 1.2), JS.round(bs * 0.12))
	if JS.t(hov):
		ctx.strokeStyle = "#c8a060"
		ctx.lineWidth = 1.5
		ctx.strokeRect(JS.round(bx - (bw / 2.0)), JS.round(by - bh), JS.round(bw), JS.round(bh))

# ── Talent Tree — magical glowing tree ────────────────────────────────────
func _drawBuildingTalentTree(ctx = null, bx = null, by = null, bs = null, hov = null, t = null):
	var trW = max(4, bs * 0.28)
	var trH = bs * 0.65
	var canopyY = (by - trH) - (bs * 0.42)
	var canopyR = bs * 0.88
	# Root spread
	ctx.fillStyle = "#1a0e06"
	ctx.beginPath()
	ctx.ellipse(JS.round(bx), JS.round(by), JS.round(trW * 1.9), JS.round(trW * 0.38), 0, 0, PI * 2)
	ctx.fill()
	# Trunk
	ctx.fillStyle = "#1e1008"
	ctx.fillRect(JS.round(bx - (trW / 2.0)), JS.round(by - trH), JS.round(trW), JS.round(trH))
	# Trunk grain
	ctx.strokeStyle = "#160c06"
	ctx.lineWidth = 0.8
	ctx.beginPath()
	ctx.moveTo(bx - (trW * 0.18), by - trH)
	ctx.lineTo(bx - (trW * 0.18), by)
	ctx.stroke()
	ctx.beginPath()
	ctx.moveTo(bx + (trW * 0.12), by - (trH * 0.65))
	ctx.lineTo(bx + (trW * 0.12), by)
	ctx.stroke()
	# Branch left
	ctx.strokeStyle = "#201008"
	ctx.lineWidth = max(1.5, trW * 0.5)
	ctx.beginPath()
	ctx.moveTo(bx - (trW * 0.2), by - (trH * 0.55))
	ctx.lineTo(bx - (bs * 0.45), by - (trH * 0.85))
	ctx.stroke()
	ctx.beginPath()
	ctx.moveTo(bx + (trW * 0.2), by - (trH * 0.6))
	ctx.lineTo(bx + (bs * 0.42), by - (trH * 0.8))
	ctx.stroke()
	# Canopy — layered lobes
	ctx.fillStyle = "#050f04"
	ctx.beginPath()
	ctx.arc(JS.round(bx - (bs * 0.2)), JS.round(canopyY + (bs * 0.18)), JS.round(canopyR * 0.72), 0, PI * 2)
	ctx.fill()
	ctx.beginPath()
	ctx.arc(JS.round(bx + (bs * 0.24)), JS.round(canopyY + (bs * 0.22)), JS.round(canopyR * 0.68), 0, PI * 2)
	ctx.fill()
	ctx.beginPath()
	ctx.arc(JS.round(bx), JS.round(canopyY - (bs * 0.06)), JS.round(canopyR * 0.82), 0, PI * 2)
	ctx.fill()
	# Inner lighter canopy
	ctx.fillStyle = "#071508"
	ctx.beginPath()
	ctx.arc(JS.round(bx), JS.round(canopyY), JS.round(canopyR * 0.58), 0, PI * 2)
	ctx.fill()
	# Magical glowing orbs in branches
	var orbPos = [
		[bx - (bs * 0.32), canopyY - (bs * 0.08)],
		[bx + (bs * 0.36), canopyY + (bs * 0.04)],
		[bx - (bs * 0.1), canopyY - (bs * 0.48)],
		[bx + (bs * 0.14), canopyY - (bs * 0.36)],
		[bx - (bs * 0.44), canopyY + (bs * 0.15)],
		[bx + (bs * 0.46), canopyY + (bs * 0.18)],
	]
	var _arr31 = JS.iter(orbPos)
	for i in range(len(_arr31)):
		var _e30 = _arr31[i]
		var ox = JS.idx(_e30, 0)
		var oy = JS.idx(_e30, 1)
		var pulse = 0.55 + (0.45 * sin((t * 0.038) + (i * 1.13)))
		var orbR = max(2, bs * 0.065)
		var og = ctx.createRadialGradient(ox, oy, 0, ox, oy, orbR * 2.8)
		og.addColorStop(0, "rgba(170,220,25," + JS.s(pulse * 0.55) + ")")
		og.addColorStop(1, "transparent")
		ctx.fillStyle = og
		ctx.beginPath()
		ctx.arc(ox, oy, orbR * 2.8, 0, PI * 2)
		ctx.fill()
		ctx.fillStyle = "rgba(195,240,45," + JS.s(pulse * 0.95) + ")"
		ctx.beginPath()
		ctx.arc(JS.round(ox), JS.round(oy), JS.round(orbR), 0, PI * 2)
		ctx.fill()
	if JS.t(hov):
		var hg = ctx.createRadialGradient(bx, canopyY, 0, bx, canopyY, canopyR * 1.7)
		hg.addColorStop(0, "rgba(140,215,28,0.13)")
		hg.addColorStop(1, "transparent")
		ctx.fillStyle = hg
		ctx.beginPath()
		ctx.arc(bx, canopyY, canopyR * 1.7, 0, PI * 2)
		ctx.fill()

# ── Wizard Guild — classical library / academy ────────────────────────────
func _drawBuildingGuild(ctx = null, bx = null, by = null, bs = null, hov = null, t = null):
	var bw = bs * 2.15
	var bh = bs * 1.75
	var bx2 = JS.round(bx - (bw / 2.0))
	var by2 = JS.round(by - bh)
	# Main body
	ctx.fillStyle = ("#1c1820" if JS.t(hov) else "#161418")
	ctx.fillRect(bx2, by2, JS.round(bw), JS.round(bh))
	_drawStoneBlocks(ctx, bx2, by2, bw, bh, max(4, bs * 0.19), 3)
	# Stepped pediment top
	ctx.fillStyle = "#121014"
	ctx.beginPath()
	ctx.moveTo(bx2 - (bs * 0.06), by2)
	ctx.lineTo(bx, by2 - (bs * 0.56))
	ctx.lineTo((bx2 + bw) + (bs * 0.06), by2)
	ctx.closePath()
	ctx.fill()
	ctx.strokeStyle = "#222030"
	ctx.lineWidth = 1
	ctx.beginPath()
	ctx.moveTo(bx2 - (bs * 0.06), by2)
	ctx.lineTo(bx, by2 - (bs * 0.56))
	ctx.lineTo((bx2 + bw) + (bs * 0.06), by2)
	ctx.stroke()
	# Columns (left and right of doorway)
	for cx2 in JS.iter([bx - (bw * 0.28), bx + (bw * 0.28)]):
		ctx.fillStyle = "#1a1822"
		ctx.fillRect(JS.round(cx2 - (bs * 0.09)), JS.round(by2), JS.round(bs * 0.17), JS.round(bh))
		# Capital top and base
		ctx.fillStyle = "#22202c"
		ctx.fillRect(JS.round(cx2 - (bs * 0.13)), JS.round(by2), JS.round(bs * 0.24), JS.round(bs * 0.1))
		ctx.fillRect(JS.round(cx2 - (bs * 0.13)), JS.round(by - (bs * 0.06)), JS.round(bs * 0.24), JS.round(bs * 0.08))
	# Arched doorway
	var dw2 = bw * 0.38
	var dh2 = bh * 0.52
	ctx.fillStyle = "#0a0810"
	ctx.fillRect(JS.round(bx - (dw2 / 2.0)), JS.round(by - dh2), JS.round(dw2), JS.round(dh2))
	ctx.beginPath()
	ctx.arc(JS.round(bx), JS.round(by - dh2), JS.round(dw2 / 2.0), PI, 0)
	ctx.fill()
	ctx.strokeStyle = "#2e2040"
	ctx.lineWidth = 1
	ctx.beginPath()
	ctx.moveTo(bx - (dw2 / 2.0), by - dh2)
	ctx.lineTo(bx - (dw2 / 2.0), by)
	ctx.stroke()
	ctx.beginPath()
	ctx.moveTo(bx + (dw2 / 2.0), by - dh2)
	ctx.lineTo(bx + (dw2 / 2.0), by)
	ctx.stroke()
	ctx.beginPath()
	ctx.arc(bx, by - dh2, dw2 / 2.0, PI, 0)
	ctx.stroke()
	# Upper windows (arched, warm glow)
	var winP = 0.07 + (0.04 * sin(t * 0.03))
	for ox in JS.iter([(-bw) * 0.3, bw * 0.3]):
		var wwx = JS.round((bx + ox) - (bs * 0.11))
		var wwy = JS.round(by2 + (bh * 0.18))
		var wwW = JS.round(bs * 0.2)
		var wwH = JS.round(bs * 0.32)
		ctx.fillStyle = "rgba(150,90,35," + JS.s(winP * 2.5) + ")"
		ctx.fillRect(wwx - 2, wwy - 2, wwW + 4, wwH + 4)
		ctx.fillStyle = "#0c0a10"
		ctx.fillRect(wwx, wwy, wwW, wwH)
		ctx.fillStyle = "rgba(130,80,28," + JS.s(winP * 3.5) + ")"
		ctx.fillRect(wwx, wwy, wwW, wwH)
		# Arched top
		ctx.fillStyle = "#0c0a10"
		ctx.beginPath()
		ctx.arc(wwx + (wwW / 2.0), wwy, wwW / 2.0, PI, 0)
		ctx.fill()
		ctx.fillStyle = "rgba(130,80,28," + JS.s(winP * 3.5) + ")"
		ctx.beginPath()
		ctx.arc(wwx + (wwW / 2.0), wwy, wwW / 2.0, PI, 0)
		ctx.fill()
		ctx.strokeStyle = "#281838"
		ctx.lineWidth = 0.8
		ctx.strokeRect(wwx, wwy, wwW, wwH)
	# Magic orb floating at pediment peak
	var orbP = 0.4 + (0.3 * sin(t * 0.038))
	var og = ctx.createRadialGradient(bx, by2 - (bs * 0.56), 0, bx, by2 - (bs * 0.56), bs * 0.24)
	og.addColorStop(0, "rgba(130,75,200," + JS.s(orbP * 0.65) + ")")
	og.addColorStop(1, "transparent")
	ctx.fillStyle = og
	ctx.beginPath()
	ctx.arc(JS.round(bx), JS.round(by2 - (bs * 0.56)), bs * 0.24, 0, PI * 2)
	ctx.fill()
	ctx.fillStyle = "rgba(175,115,240," + JS.s(orbP * 0.95) + ")"
	ctx.beginPath()
	ctx.arc(JS.round(bx), JS.round(by2 - (bs * 0.56)), max(2, bs * 0.06), 0, PI * 2)
	ctx.fill()
	if JS.t(hov):
		ctx.strokeStyle = "#c8a060"
		ctx.lineWidth = 1.5
		ctx.strokeRect(bx2, by2, JS.round(bw), JS.round(bh))

# ── Tailor — cozy shop with awning and display window ─────────────────────
func _drawBuildingTailor(ctx = null, bx = null, by = null, bs = null, hov = null, t = null):
	var bw = bs * 1.65
	var bh = bs * 1.35
	# Wall
	ctx.fillStyle = ("#1e1508" if JS.t(hov) else "#181008")
	ctx.fillRect(JS.round(bx - (bw / 2.0)), JS.round(by - bh), JS.round(bw), JS.round(bh))
	ctx.strokeStyle = "#120e06"
	ctx.lineWidth = 0.8
	var plH = max(4, bs * 0.22)
	var i = 0
	while i < ceili(bh / float(plH)):
		var ly = (by - bh) + (i * plH)
		ctx.beginPath()
		ctx.moveTo(bx - (bw / 2.0), ly)
		ctx.lineTo(bx + (bw / 2.0), ly)
		ctx.stroke()
		i += 1
	# Gabled roof
	ctx.fillStyle = "#0e0c08"
	ctx.beginPath()
	ctx.moveTo((bx - (bw / 2.0)) - (bs * 0.08), by - bh)
	ctx.lineTo(bx, (by - bh) - (bs * 0.48))
	ctx.lineTo((bx + (bw / 2.0)) + (bs * 0.08), by - bh)
	ctx.closePath()
	ctx.fill()
	ctx.strokeStyle = "#201a10"
	ctx.lineWidth = 0.8
	ctx.beginPath()
	ctx.moveTo(bx - (bw / 2.0), by - bh)
	ctx.lineTo(bx + (bw / 2.0), by - bh)
	ctx.stroke()
	# Display window (right side, large with robe form)
	var wwx = JS.round(bx + (bw * 0.04))
	var wwy = JS.round(by - (bh * 0.74))
	var wwW = JS.round(bw * 0.42)
	var wwH = JS.round(bh * 0.4)
	var wGl = ctx.createRadialGradient(wwx + (wwW / 2.0), wwy + (wwH / 2.0), 0, wwx + (wwW / 2.0), wwy + (wwH / 2.0), wwW * 0.8)
	wGl.addColorStop(0, "rgba(170,95,28,0.28)")
	wGl.addColorStop(1, "transparent")
	ctx.fillStyle = wGl
	ctx.fillRect(wwx - wwW, wwy - wwH, wwW * 3, wwH * 3)
	ctx.fillStyle = "#100e08"
	ctx.fillRect(wwx, wwy, wwW, wwH)
	ctx.fillStyle = "rgba(150,85,22,0.18)"
	ctx.fillRect(wwx, wwy, wwW, wwH)
	# Robed dress-form silhouette
	ctx.fillStyle = "#0a0408"
	ctx.beginPath()
	ctx.arc(JS.round(wwx + (wwW * 0.5)), JS.round(wwy + (wwH * 0.22)), JS.round(wwW * 0.1), 0, PI * 2)
	ctx.fill()
	ctx.beginPath()
	ctx.moveTo(wwx + (wwW * 0.38), wwy + (wwH * 0.3))
	ctx.bezierCurveTo(wwx + (wwW * 0.28), wwy + (wwH * 0.55), wwx + (wwW * 0.22), wwy + (wwH * 0.8), wwx + (wwW * 0.26), wwy + (wwH * 0.96))
	ctx.lineTo(wwx + (wwW * 0.74), wwy + (wwH * 0.96))
	ctx.bezierCurveTo(wwx + (wwW * 0.78), wwy + (wwH * 0.8), wwx + (wwW * 0.72), wwy + (wwH * 0.55), wwx + (wwW * 0.62), wwy + (wwH * 0.3))
	ctx.closePath()
	ctx.fill()
	# Window frame
	ctx.strokeStyle = "#1e1408"
	ctx.lineWidth = 1
	ctx.strokeRect(wwx, wwy, wwW, wwH)
	ctx.beginPath()
	ctx.moveTo(wwx + (wwW / 2.0), wwy)
	ctx.lineTo(wwx + (wwW / 2.0), wwy + wwH)
	ctx.stroke()
	# Door (left side)
	var ddx = JS.round(bx - (bw * 0.25))
	var ddW = JS.round(bw * 0.3)
	var ddH = JS.round(bh * 0.36)
	ctx.fillStyle = "#1c0e06"
	ctx.fillRect(JS.round(ddx - (ddW / 2.0)), JS.round(by - ddH), ddW, ddH)
	ctx.strokeStyle = "#2a1808"
	ctx.lineWidth = 0.8
	ctx.strokeRect(JS.round(ddx - (ddW / 2.0)), JS.round(by - ddH), ddW, ddH)
	# Striped awning over door
	var awX = (ddx - (ddW / 2.0)) - (bs * 0.06)
	var awW2 = ddW + (bs * 0.12)
	var awY = (by - ddH) - (bs * 0.02)
	var awH2 = max(6, bs * 0.15)
	ctx.fillStyle = "#200a0a"
	ctx.beginPath()
	ctx.moveTo(awX, awY)
	ctx.lineTo(awX + awW2, awY)
	ctx.lineTo((awX + awW2) + (bs * 0.06), awY + awH2)
	ctx.lineTo(awX - (bs * 0.06), awY + awH2)
	ctx.closePath()
	ctx.fill()
	# Awning stripes
	var numS = 4
	var sw2 = awW2 / float(numS * 2)
	for i_2 in range(ceili(numS)):
		ctx.fillStyle = "#2e1010"
		var sx2 = awX + ((i_2 * sw2) * 2)
		ctx.beginPath()
		ctx.moveTo(sx2, awY)
		ctx.lineTo(sx2 + sw2, awY)
		ctx.lineTo((sx2 + sw2) + (bs * 0.04), awY + awH2)
		ctx.lineTo(sx2 + (bs * 0.04), awY + awH2)
		ctx.closePath()
		ctx.fill()
	# Scalloped awning edge
	var numSc = max(3, floori((awW2 / float(bs)) * 0.16) + 1)
	for i_2 in range(ceili(numSc)):
		ctx.fillStyle = "#200a0a"
		ctx.beginPath()
		ctx.arc(JS.round((awX - (bs * 0.06)) + ((i_2 * (awW2 + (bs * 0.12))) / float(numSc - 1))), JS.round(awY + awH2), JS.round(max(3, bs * 0.08)), 0, PI)
		ctx.fill()
	# Hanging scissors sign
	ctx.strokeStyle = "#281808"
	ctx.lineWidth = 0.8
	ctx.beginPath()
	ctx.moveTo(bx + (bw * 0.3), by - (bh * 0.58))
	ctx.lineTo(bx + (bw * 0.3), by - (bh * 0.42))
	ctx.stroke()
	ctx.fillStyle = "#1a1008"
	ctx.strokeStyle = "#362210"
	ctx.lineWidth = 0.7
	var sgx = JS.round(bx + (bw * 0.22))
	var sgy = JS.round((by - (bh * 0.42)) - (bs * 0.13))
	var sgW = JS.round(bs * 0.19)
	var sgH = JS.round(bs * 0.13)
	ctx.fillRect(sgx, sgy, sgW, sgH)
	ctx.strokeRect(sgx, sgy, sgW, sgH)
	if JS.t(hov):
		ctx.strokeStyle = "#c8a060"
		ctx.lineWidth = 1.5
		ctx.strokeRect(JS.round(bx - (bw / 2.0)), JS.round(by - bh), JS.round(bw), JS.round(bh))

# ── Ruined Portal — locked Veil, crumbled and dark ────────────────────────
func _drawRuinedPortal(ctx = null, bx = null, by = null, bs = null, hov = null):
	var aw = bs * 1.4
	var ah = bs * 1.5
	var ax = bx - (aw / 2.0)
	var ay = by - ah
	# Subtle dark backdrop (no glow)
	var fade = ctx.createRadialGradient(bx, by - (ah * 0.5), 0, bx, by - (ah * 0.5), aw * 0.7)
	fade.addColorStop(0, "rgba(20,15,25,0.15)")
	fade.addColorStop(1, "rgba(0,0,0,0)")
	ctx.fillStyle = fade
	ctx.fillRect(ax - (aw * 0.3), ay - (ah * 0.1), aw * 1.6, ah * 1.2)
	# Weathered stone pillars
	ctx.fillStyle = "#2a2530"
	ctx.strokeStyle = "#3a3040"
	ctx.lineWidth = 1
	var pilW = aw * 0.18
	var pilH = ah * 0.85
	ctx.fillRect(ax, by - pilH, pilW, pilH)
	ctx.strokeRect(ax, by - pilH, pilW, pilH)
	ctx.fillRect((ax + aw) - pilW, by - pilH, pilW, pilH)
	ctx.strokeRect((ax + aw) - pilW, by - pilH, pilW, pilH)
	# Cracks
	ctx.strokeStyle = "rgba(0,0,0,0.5)"
	ctx.lineWidth = 0.7
	ctx.beginPath()
	ctx.moveTo(ax + (pilW * 0.35), by - (pilH * 0.25))
	ctx.lineTo(ax + (pilW * 0.65), by - (pilH * 0.45))
	ctx.lineTo(ax + (pilW * 0.45), by - (pilH * 0.6))
	ctx.stroke()
	ctx.beginPath()
	ctx.moveTo((ax + aw) - (pilW * 0.55), by - (pilH * 0.35))
	ctx.lineTo((ax + aw) - (pilW * 0.75), by - (pilH * 0.55))
	ctx.stroke()
	# Broken arch top
	ctx.beginPath()
	ctx.arc(bx, (by - pilH) + (aw * 0.01), (aw * 0.5) - (pilW * 0.5), PI, 0)
	ctx.fillStyle = "#2a2530"
	ctx.fill()
	ctx.strokeStyle = "#3a3040"
	ctx.lineWidth = 1.2
	ctx.stroke()
	# Dark empty void interior
	var innerR = aw * 0.36
	var innerGrad = ctx.createRadialGradient(bx, (by - pilH) + 2, 0, bx, by - pilH, innerR)
	innerGrad.addColorStop(0, "rgba(10,5,15,0.9)")
	innerGrad.addColorStop(0.7, "rgba(5,3,8,0.7)")
	innerGrad.addColorStop(1, "rgba(0,0,0,0.4)")
	ctx.beginPath()
	ctx.arc(bx, (by - pilH) + (aw * 0.01), innerR, PI, 0)
	ctx.fillStyle = innerGrad
	ctx.fill()
	# Dead keystone gem
	var gemY = (by - pilH) - (aw * 0.12)
	ctx.beginPath()
	ctx.arc(bx, gemY, bs * 0.07, 0, PI * 2)
	ctx.fillStyle = "rgba(45,38,50,0.7)"
	ctx.fill()
	ctx.strokeStyle = "#302838"
	ctx.lineWidth = 0.8
	ctx.stroke()
	# Rubble at base
	ctx.fillStyle = "#2a2535"
	for i in range(3):
		ctx.fillRect(ax + (pilW * (0.2 + (i * 0.35))), by - 1, bs * 0.08, bs * 0.04)
	ctx.fillStyle = "#252030"
	for i in range(2):
		ctx.fillRect(((ax + aw) - pilW) + (pilW * (0.2 + (i * 0.5))), by - 1, bs * 0.06, bs * 0.03)
	# Hover outline
	if JS.t(hov):
		ctx.strokeStyle = "#666070"
		ctx.lineWidth = 1.5
		ctx.strokeRect(ax - 2, ay - 2, aw + 4, ah + 4)

# ── The Veil — misty archway with purple glow ─────────────────────────────
func _drawBuildingVeil(ctx = null, bx = null, by = null, bs = null, hov = null, t = null):
	if not Veil._veilIsUnlocked():
		_drawRuinedPortal(ctx, bx, by, bs, hov)
		return
	var aw = bs * 1.4
	var ah = bs * 1.5
	var ax = bx - (aw / 2.0)
	var ay = by - ah
	var pulse = 0.5 + (0.5 * sin(t * 0.04))
	var mistCfg = Mist.getMistConfig()
	var active = mistCfg.active
	# Archway glow backdrop
	var glow = ctx.createRadialGradient(bx, by - (ah * 0.5), 0, bx, by - (ah * 0.5), aw * 0.8)
	glow.addColorStop(0, "rgba(" + ("120,40,220" if JS.t(active) else "60,20,110") + "," + JS.s(0.22 + (pulse * 0.12)) + ")")
	glow.addColorStop(1, "rgba(0,0,0,0)")
	ctx.fillStyle = glow
	ctx.fillRect(ax - (aw * 0.3), ay - (ah * 0.1), aw * 1.6, ah * 1.2)
	# Stone pillars
	ctx.fillStyle = "#1a1020"
	ctx.strokeStyle = "#2d1a40"
	ctx.lineWidth = 1
	var pilW = aw * 0.18
	var pilH = ah * 0.85
	ctx.fillRect(ax, by - pilH, pilW, pilH)
	ctx.strokeRect(ax, by - pilH, pilW, pilH)
	ctx.fillRect((ax + aw) - pilW, by - pilH, pilW, pilH)
	ctx.strokeRect((ax + aw) - pilW, by - pilH, pilW, pilH)
	# Arch top
	ctx.beginPath()
	ctx.arc(bx, (by - pilH) + (aw * 0.01), (aw * 0.5) - (pilW * 0.5), PI, 0)
	ctx.fillStyle = "#1a1020"
	ctx.fill()
	ctx.strokeStyle = "#3a2060"
	ctx.lineWidth = 1.2
	ctx.stroke()
	# Arch interior — misty void
	var innerR = aw * 0.36
	var innerGrad = ctx.createRadialGradient(bx, (by - pilH) + 2, 0, bx, by - pilH, innerR)
	innerGrad.addColorStop(0, "rgba(" + ("90,20,180" if JS.t(active) else "40,10,80") + "," + JS.s(0.7 + (pulse * 0.2)) + ")")
	innerGrad.addColorStop(0.6, "rgba(" + ("50,10,120" if JS.t(active) else "20,5,50") + ",0.8)")
	innerGrad.addColorStop(1, "rgba(0,0,0,0.4)")
	ctx.beginPath()
	ctx.arc(bx, (by - pilH) + (aw * 0.01), innerR, PI, 0)
	ctx.fillStyle = innerGrad
	ctx.fill()
	# Mist wisps inside arch
	for i in range(3):
		var wx = bx + ((sin((t * 0.03) + (i * 2.1)) * aw) * 0.18)
		var wy = ((by - (pilH * 0.3)) - ((i * ah) * 0.13)) + ((cos((t * 0.025) + i) * ah) * 0.06)
		var wr = bs * (0.1 + (0.05 * sin((t * 0.05) + i)))
		var mg = ctx.createRadialGradient(wx, wy, 0, wx, wy, wr)
		mg.addColorStop(0, "rgba(" + ("160,80,255" if JS.t(active) else "100,40,180") + "," + JS.s(0.25 + (pulse * 0.15)) + ")")
		mg.addColorStop(1, "rgba(0,0,0,0)")
		ctx.fillStyle = mg
		ctx.fillRect(wx - wr, wy - wr, wr * 2, wr * 2)
	# Keystone gem at arch top
	var gemY = (by - pilH) - (aw * 0.12)
	ctx.beginPath()
	ctx.arc(bx, gemY, bs * 0.07, 0, PI * 2)
	ctx.fillStyle = ("rgba(180,80,255," + JS.s(0.7 + (pulse * 0.3)) + ")" if JS.t(active) else "rgba(80,30,120,0.6)")
	ctx.fill()
	ctx.strokeStyle = ("#e0a0ff" if JS.t(active) else "#6030a0")
	ctx.lineWidth = 0.8
	ctx.stroke()
	# Active mist indicator dot
	if JS.t(active):
		var mist = Mist.getTotalMist()
		ctx.fillStyle = "rgba(200,120,255," + JS.s(0.6 + (pulse * 0.4)) + ")"
		ctx.font = "bold " + JS.s(JS.round(bs * 0.22)) + "px Cinzel,serif"
		ctx.textAlign = "center"
		ctx.fillText("🌫" + JS.s(mist), bx, (by - ah) - (bs * 0.12))
		ctx.textAlign = "left"
	# Hover outline
	if JS.t(hov):
		ctx.strokeStyle = ("#c080ff" if JS.t(active) else "#6030a0")
		ctx.lineWidth = 1.5
		ctx.strokeRect(ax - 2, ay - 2, aw + 4, ah + 4)

func _drawLobbyPlayer(ctx = null, W = null, H = null):
	# Hide wizard entirely during teeth and fade phases
	if (_lobbyCinematic == "castle_teeth" or _lobbyCinematic == "castle_fade"):
		return
	var x = JS.round(_lobbyPlayerX * W)
	var y = JS.round(_lobbyMY(_lobbyPlayerY, W, H) * H)
	var scale_ = max(1, min(2, floori(W / 400.0)))
	# During castle_enter: shrink and fade as wizard walks into the gate
	var wizAlpha = 1
	if _lobbyCinematic == "castle_enter":
		var enterProgress = max(0, min(1, (0.6 - _lobbyPlayerY) / 0.12))
		scale_ = max(0.2, scale_ * (1 - (enterProgress * 0.75)))
		wizAlpha = max(0, 1 - (enterProgress * 0.95))
	if wizAlpha <= 0.02:
		return
	# Bob when walking
	var bobY = (JS.round(sin(_lobbyTick * 0.25) * 2) if JS.t(_lobbyWalking) else 0)
	# Get player sprite rows based on wizard archetype
	var _archId = (Characters._wizBuild.archetype if (true and JS.t(Characters._wizBuild)) else "arcanist")
	var rows = Sprites.getPlayerCharSprite(_archId)
	var sprW = 24 * scale_
	var sprH = len(rows) * scale_
	var sx = x - (sprW / 2.0)
	var sy = (y - sprH) + bobY
	# Horizontal flip for facing left
	ctx.save()
	ctx.globalAlpha = wizAlpha
	if JS.t(_lobbyFacingLeft):
		ctx.translate(x * 2, 0)
		ctx.scale(-1, 1)
	# Draw sprite with full custom color map matching wizard build
	var colorMap = _lobbyBuildColorMap()
	if JS.t(colorMap):
		for row in range(len(rows)):
			for col in range(24):
				var c = JS.or_(JS.idx(JS.or_(JS.idx(rows, row), ""), col), ".")
				var color = JS.idx(colorMap, c)
				if not JS.t(color):
					continue
				ctx.fillStyle = color
				ctx.fillRect(floori(sx + (col * scale_)), floori(sy + (row * scale_)), scale_, scale_)
	else:
		var pal = _lobbyGetPlayerPal()
		Sprites.drawSprite(ctx, rows, sx, sy, scale_, pal, 24)
	# Name label
	ctx.restore()
	ctx.save()
	ctx.font = "bold " + JS.s(JS.round(W * 0.018)) + "px 'Cinzel', serif"
	ctx.textAlign = "center"
	ctx.fillStyle = "#c8a060"
	ctx.globalAlpha = 0.85
	ctx.fillText(JS.or_(State.playerName, "Wizard"), x, sy - 4)
	ctx.restore()

func _lobbyGetPlayerPal():
	var b = Characters._wizBuild
	if not JS.t(b):
		return ["#aa6622", "#cc8833", "#eebb55", "#ffdd88"]
	var outfit = JS.find(Characters.WIZ_OUTFIT_COLORS, func(o = null): return JS.eq(o.id, b.outfit))
	if JS.t(outfit):
		return [outfit.p0, outfit.p1, outfit.p2, outfit.p3]
	return ["#aa6622", "#cc8833", "#eebb55", "#ffdd88"]

func _lobbyBuildColorMap():
	var b = Characters._wizBuild
	if not JS.t(b):
		return null
	var hatClr = JS.find(Characters.WIZ_HAT_COLORS, func(c = null): return JS.eq(c.id, b.hatColor))
	var outClr = JS.find(Characters.WIZ_OUTFIT_COLORS, func(c = null): return JS.eq(c.id, b.outfit))
	var beardClr = JS.find(Characters.WIZ_BEARD_COLORS, func(c = null): return JS.eq(c.id, b.beardColor))
	var staffClr = JS.find(Characters.WIZ_STAFF_COLORS, func(c = null): return JS.eq(c.id, b.staffColor))
	var glowClr = JS.find(Characters.WIZ_STAFF_GLOWS, func(g = null): return JS.eq(g.id, b.staffGlow))
	var eyeClr = JS.find(Characters.WIZ_EYE_COLORS, func(e = null): return JS.eq(e.id, b.eyeColor))
	var showBeard = b.get("beardStyle") != "none"
	return {
		".": null,
		"1": (outClr.p0 if JS.t(outClr) else "#aa6622"),
		"2": (outClr.p1 if JS.t(outClr) else "#cc8833"),
		"3": (outClr.p2 if JS.t(outClr) else "#eebb55"),
		"4": (outClr.p3 if JS.t(outClr) else "#ffdd88"),
		"h": (hatClr.color if JS.t(hatClr) else "#2244aa"),
		"s": SpriteData.SKIN_C,
		"e": (eyeClr.color if JS.t(eyeClr) else "#ff2222"),
		"b": SpriteData.BOOT_C,
		"w": (beardClr.color if (showBeard and JS.t(beardClr)) else null),
		"f": (staffClr.color if JS.t(staffClr) else "#8b5a2b"),
		"g": (glowClr.color if JS.t(glowClr) else null),
	}

func _lobbyHover(e = null):
	var hit = [null]
	var canvas = document.getElementById("lobby-map-canvas")
	if not JS.t(canvas):
		return
	var r = canvas.getBoundingClientRect()
	var mx = (e.clientX - r.left) * (canvas.width / float(r.width))
	var my = (e.clientY - r.top) * (canvas.height / float(r.height))
	var W = canvas.width
	var H = canvas.height
	hit[0] = null
	for loc in JS.iter(LOBBY_LOCATIONS):
		var lx = loc.x * W
		var ly = _lobbyMY(loc.y, W, H) * H
		var dist = sqrt((pow(mx - lx, 2)) + (pow(my - ly, 2)))
		var radius = (W * 0.14 if loc.get("id") == "castle" else max(28, W * 0.065))
		if dist < radius:
			hit[0] = loc.id
	# Refresh-bg button hit
	var W2 = canvas.width
	var H2 = canvas.height
	var rbw = max(60, W2 * 0.09)
	var rbh = max(18, H2 * 0.032)
	var rbx = (W2 - rbw) - 6
	var rby = 6
	if (((mx >= rbx and mx <= (rbx + rbw)) and my >= rby) and my <= (rby + rbh)):
		hit[0] = "__refreshBg__"
	_lobbyHoveredId = hit[0]
	canvas.style.cursor = ("pointer" if JS.t(hit[0]) else "default")

func _nearestPathNode(x = null, y = null):
	var best = "plaza"
	var bestDist = INF
	for _e32 in JS.iter(JS.entries(_PNODES)):
		var id = JS.idx(_e32, 0)
		var _d33 = JS.idx(_e32, 1)
		var nx = JS.idx(_d33, 0)
		var ny = JS.idx(_d33, 1)
		var d = (pow(x - nx, 2)) + (pow(y - ny, 2))
		if d < bestDist:
			bestDist = d
			best = id
	return best

func _bfsLobbyPath(from = null, to = null):
	if JS.eq(from, to):
		return [from]
	var visited = JSSet.new([from])
	var queue = [[from, [from]]]
	while len(queue) > 0:
		var _d34 = queue.pop_front()
		var node = JS.idx(_d34, 0)
		var path = JS.idx(_d34, 1)
		for nb in JS.iter(JS.or_(JS.idx(_PEDGES, node), [])):
			if not visited.has(nb):
				visited.add(nb)
				var p = JS.arr(path) + [nb]
				if JS.eq(nb, to):
					return p
				queue.append([nb, p])
	return [from, to]

func _buildLobbyRoute(destId = null, destX = null, destY = null):
	var destNode = ("bridge" if destId == "castle" else destId)
	var startNode = _nearestPathNode(_lobbyPlayerX, _lobbyPlayerY)
	var nodePath = _bfsLobbyPath(startNode, destNode)
	var _fn36 = func(id = null, i = null, arr = null):
		var _d35 = JS.idx(_PNODES, id)
		var nx = JS.idx(_d35, 0)
		var ny = JS.idx(_d35, 1)
		return ({"x": nx, "y": ny, "finalDest": destId} if i == (len(arr) - 1) else {"x": nx, "y": ny})
	return JS.map(JS.slice(nodePath, 1), _fn36)

func _lobbyClick(e = null):
	var hit = [null]
	var canvas = document.getElementById("lobby-map-canvas")
	if not JS.t(canvas):
		return
	var r = canvas.getBoundingClientRect()
	var mx = (e.clientX - r.left) * (canvas.width / float(r.width))
	var my = (e.clientY - r.top) * (canvas.height / float(r.height))
	var W = canvas.width
	var H = canvas.height
	# Refresh-bg button
	var rbw = max(60, W * 0.09)
	var rbh = max(18, H * 0.032)
	var rbx = (W - rbw) - 6
	var rby = 6
	if (((mx >= rbx and mx <= (rbx + rbw)) and my >= rby) and my <= (rby + rbh)):
		_initLobbyBgZones()
		return
	hit[0] = null
	for loc in JS.iter(LOBBY_LOCATIONS):
		var lx = loc.x * W
		var ly = _lobbyMY(loc.y, W, H) * H
		var dist = sqrt((pow(mx - lx, 2)) + (pow(my - ly, 2)))
		var radius = (W * 0.14 if loc.get("id") == "castle" else max(28, W * 0.065))
		if dist < radius:
			hit[0] = loc
	if not JS.t(hit[0]):
		return
	var destX = hit[0].x
	var destY = (0.68 if hit[0].get("id") == "castle" else hit[0].y)
	var route = _buildLobbyRoute(hit[0].id, destX, destY)
	var first = route.pop_front()
	_lobbyTargetX = first.x
	_lobbyTargetY = first.y
	_lobbyWaypointQueue = route
	_lobbyWalking = true
	_lobbyWalkDest = JS.or_(first.get("finalDest"), null)
	_lobbyWaypoint = null

func _openLobbyLocation(id = null):
	if id == "castle":
		# Start castle-enter cinematic — wizard walks slowly into the gate, then it snaps shut
		_lobbyCinematic = "castle_enter"
		_lobbyCinematicTick = 0
		_lobbyTargetX = 0.5
		_lobbyTargetY = 0.56
		# deep inside the gate arch
		_lobbyWalking = true
		_lobbyWalkDest = null
		# cinematic handles transition, not _openLobbyLocation
		var canvas = document.getElementById("lobby-map-canvas")
		if JS.t(canvas):
			canvas.onclick = null
		# disable clicks during cinematic
		return
	if id == "tailor":
		var tailorLoc = JS.find(LOBBY_LOCATIONS, func(l = null): return l.get("id") == "tailor")
		if JS.t(tailorLoc):
			_lobbyReturnPos = {"x": tailorLoc.x, "y": tailorLoc.y}
		stopLobbyMap()
		Characters._wizBuilderFromLobby = true
		Characters.showCharacterScreen()
		return
	var panel = document.getElementById("lobby-panel")
	var content = document.getElementById("lobby-panel-content")
	if (not JS.t(panel) or not JS.t(content)):
		return
	var meta = Artifacts.getMeta()
	var loc = JS.find(LOBBY_LOCATIONS, func(l = null): return JS.eq(l.id, id))
	var title = (loc.label if JS.t(loc) else "")
	var phosLabel = "<div class=\"lobby-phos-bar\">✦ " + JS.s(JS.or_(meta.get("phos"), 0)) + " Phos available</div>"
	if id == "archive":
		var history = JS.or_(meta.get("runHistory"), [])
		var html = "<div class=\"lobby-panel-title\">" + JS.s(title) + "</div>"
		if not JS.t(len(history)):
			html += "<div class=\"brun-empty\">No runs recorded yet.</div>"
		else:
			html += JS.join(JS.arr(history).map(func(r = null): return "\n        <div class=\"brun-hist-row\">\n          <div class=\"brun-hist-el\">" + (JS.or_(r.get("emoji"), "⚔")) + " " + (JS.or_(r.get("element"), "?")) + " <span style=\"color:#4a6a8a;font-size:.6rem;margin-left:.3rem;\">" + ("→ " + JS.s(r.zone) + " Zone" if (JS.t(r.get("zone")) and not JS.eq(r.zone, r.element)) else "") + "</span></div>\n          <div class=\"brun-hist-stats\">\n            <span>" + JS.s(JS.or_(r.get("battles"), 0)) + " battles</span>\n            <span style=\"color:#c8a830\">" + JS.s(JS.or_(r.get("gold"), 0)) + "g</span>\n            <span style=\"color:#a080ff\">" + JS.s(JS.or_(r.get("phos"), 0)) + "✦</span>\n          </div>\n          <div style=\"display:flex;gap:.8rem;font-size:.6rem;color:#555;margin-top:.2rem;\">\n            <span>⚔ " + JS.s(JS.or_(r.get("dmgDealt"), 0)) + " dealt</span><span>🛡 " + JS.s(JS.or_(r.get("dmgTaken"), 0)) + " taken</span>\n          </div>\n          <div class=\"brun-hist-date\">" + (JS.or_(r.get("date"), "")) + "</div>\n        </div>"), "")
		content.innerHTML = html
		panel.style.display = "block"
	elif id == "vault":
		Artifacts.markArtifactsSeen()
		BetweenRuns.renderArtifactVaultTab(content, meta, "_openLobbyLocation('vault')")
		content.insertAdjacentHTML("afterbegin", "<div class=\"lobby-panel-title\">" + JS.s(title) + "</div>")
		panel.style.display = "block"
	elif id == "library":
		Artifacts.markBooksSeen()
		content.innerHTML = "<div class=\"lobby-panel-title\">" + JS.s(title) + "</div>"
		BetweenRuns.renderBookUpgradesTab(content, meta)
		panel.style.display = "block"
	elif id == "talents":
		content.innerHTML = "<div class=\"lobby-panel-title\">" + JS.s(title) + "</div>"
		BetweenRuns.renderKnowledgeTreeTab(content, meta)
		panel.style.display = "block"
	elif id == "guild":
		closeLobbyPanel()
		Library.showLibrary()
	elif id == "veil":
		Veil._renderVeilContent(content)
		panel.style.display = "block"

func closeLobbyPanel():
	var panel = document.getElementById("lobby-panel")
	if JS.t(panel):
		panel.style.display = "none"
	# Resume map loop
	if not JS.t(_lobbyAnimFrame):
		_lobbyLoop()

func stopLobbyMap():
	if JS.t(_lobbyAnimFrame):
		JS.cancelAnimationFrame(_lobbyAnimFrame)
		_lobbyAnimFrame = null
	var canvas = document.getElementById("lobby-map-canvas")
	if JS.t(canvas):
		canvas.onclick = null
		canvas.onmousemove = null
