# Progression — generated from js/logic/progression.js by tools/js2gd.js
extends Node

var MAP_SPRITE_CAMPFIRE_BASE = null
var MAP_SPRITE_CAMPFIRE_FLAME = null
var MAP_SPRITE_SHOP = null
var MAP_SPRITE_GYM = null
var MAP_ICON_PLAYER = null
var _mapNodes = null
# { x, y, type, enc, color, sprites[] }
var _mapPlayerX = 0
var _mapPlayerY = 0
var _mapOriginX = 0
var _mapOriginY = 0
var _mapAnimTarget = null
# { x, y, enc }
var _mapAnimT = 0
var MAP_ANIM_FRAMES = 72
var _mapRAF = null
var _mapHovered = -1
# index of hovered node
var _mapCanvas = null
var _starCache = null
var _starCacheKey = ""
var _clouds = null
var _lastCloudTick = 0
var _cfSparks = null
var _cfSparkPools = null
var CF_PALS = null

func _boot():
	# ===== mapCanvas.js =====
	# ─── MAP CANVAS — Pixel art path map with animated player movement ────────────
	# ═══ NODE SPRITES (12-col pixel art) ══════════════════════════════════════════
	# Campfire: log base + animated flame (flame rows at top, drawn separately)
	MAP_SPRITE_CAMPFIRE_BASE = [
		"............",
		"............",
		"............",
		"....4444....",
		"...444444...",
		"..33333333..",
		".3333333333.",
		"333...333.33",
		"333...333.33",
		"23....3..32.",
	]
	# Flame rows overlaid on top (animated color per frame)
	MAP_SPRITE_CAMPFIRE_FLAME = ["....3111....", "...311113...", "..31111113..", "..31111113..", "...311113...", "....3113...."]
	# Shop: market stall with awning and counter
	MAP_SPRITE_SHOP = [
		"111111111111",
		"122222222221",
		"111111111111",
		"1...1....1.1",
		"1...1....1.1",
		"1111111111..",
		"2222222222..",
		"1111111111..",
		"1...........",
		"1...........",
	]
	# Gym: greek temple with pillars
	MAP_SPRITE_GYM = [
		"111111111111",
		"111111111111",
		".1111111111.",
		"..11111111..",
		"...111111...",
		"...1.11.1...",
		"...1.11.1...",
		"...1.11.1...",
		"...1.11.1...",
		"1111111111..",
	]
	MAP_ICON_PLAYER = ["....hh..", "...hhhh.", "...ssss.", "...1111.", "..111111", "..111111", "...1111.", "...bb.b."]
	# ═══ STATE ════════════════════════════════════════════════════════════════════
	_mapNodes = []
	# ── Cloud state ───────────────────────────────────────────────────────────
	_clouds = []
	# ── Animated world campfire (drawn directly into scene) ─────────────────────
	# Sparkle particle state
	_cfSparks = []
	# Shared: spark emitter helper (uses a per-key pool)
	_cfSparkPools = {}
	# Zone color palettes for campfire flames [tip, mid-hi, mid, base, hotspot]
	CF_PALS = {
		"Fire": ["#FFFF88", "#FF9900", "#FF5500", "#FF3300", "#FFEE22"],
		"Water": ["#CCFFFF", "#22CCFF", "#0088EE", "#0055BB", "#AAFFFF"],
		"Ice": ["#FFFFFF", "#CCEEFF", "#88CCEE", "#5599CC", "#FFFFFF"],
		"Lightning": ["#FFFFC0", "#FFFF22", "#FFCC00", "#FF9900", "#FFFFFF"],
		"Earth": ["#FFEEBB", "#CC8800", "#AA5500", "#882200", "#EEDD88"],
		"Nature": ["#EEFF99", "#88DD22", "#44AA00", "#226600", "#CCFF44"],
		"Plasma": ["#FFDDFF", "#DD66FF", "#AA22DD", "#6600AA", "#FFAAFF"],
		"Air": ["#FFFFFF", "#CCEEFF", "#99BBDD", "#6688BB", "#EEFFFF"],
	}

# ═══ SETUP ════════════════════════════════════════════════════════════════════
func showMapCanvas(nodes = null):
	_mapNodes = nodes
	_mapAnimTarget = null
	_mapAnimT = 0
	_mapHovered = -1
	_starCache = null
	# invalidate star cache when canvas resizes
	_clouds.clear()
	# reset clouds for new canvas size
	_lastCloudTick = 0
	var canvas = document.getElementById("map-canvas")
	if not JS.t(canvas):
		return
	_mapCanvas = canvas
	# Canvas dimensions already set by _buildAndShowCanvas — just read them
	# Player starts at bottom center
	_mapPlayerX = JS.round(canvas.width * 0.5)
	_mapOriginX = _mapPlayerX
	_mapPlayerY = JS.round(canvas.height * 0.87)
	_mapOriginY = _mapPlayerY
	# Event wiring
	canvas.onclick = _mapClick
	canvas.onmousemove = _mapHover
	var _fn1 = func():
		_mapHovered = -1
	canvas.onmouseleave = _fn1
	_startMapLoop()

func stopMapCanvas():
	if JS.t(_mapRAF):
		JS.cancelAnimationFrame(_mapRAF)
		_mapRAF = null
	if JS.t(_mapCanvas):
		_mapCanvas.onclick = null
		_mapCanvas.onmousemove = null
		_mapCanvas.onmouseleave = null

# ═══ NODE BUILDER (called from showMap in map.js) ════════════════════════════
# Returns a node array ready for showMapCanvas()
func buildMapNodes(encounters = null, specials = null, canvasW = null, canvasH = null):
	var W = canvasW
	var H = canvasH
	var horizY = H * 0.45
	# Ground surface Y at x — follows gentle terrain rolls
	var gY = func(x = null): return (((horizY + ((H - horizY) * 0.22)) + ((sin((x * 0.019) + 1.2) * (H - horizY)) * 0.055)) + ((sin((x * 0.009) + 0.5) * (H - horizY)) * 0.09)) + ((sin((x * 0.047) + 2.1) * (H - horizY)) * 0.028)
	var nodes = []
	# ── Combat nodes: lower foreground ──────────────────────────────────────
	var combatXFracs = ([0.5] if len(encounters) == 1 else [0.22, 0.76])
	var _arr2 = JS.iter(encounters)
	for i in range(len(_arr2)):
		var enc = _arr2[i]
		var nx = JS.round(W * JS.idx(combatXFracs, i))
		var ny = JS.round(gY.call(nx))
		# _isSpecial: campfire or shop replacing this slot
		if JS.t(enc.get("_isSpecial")):
			var spColor = ("#d4822a" if enc.get("_specialType") == "campfire" else "#2aaa7a")
			var spLabel = ("Campfire" if enc.get("_specialType") == "campfire" else "Shop")
			nodes.append({"x": nx, "y": ny, "type": enc._specialType, "enc": enc, "color": spColor, "sprites": [], "label": spLabel})
			continue
		var nextSlot = State.zoneBattleCount + 1
		var slotReward = (enc.get("_rewardType") if JS.t(enc.get("_rewardType")) else BattleReward.getZoneRewardType(nextSlot, State.currentGymIdx))
		var _rewardNodeCfg = JS.orf(JS.idx({
			"primary_spell": {"label": "Starting Spell", "color": "#c080ff", "icon": "✦"},
			"spell": {"label": "Spell Reward", "color": "#a080ff", "icon": "📜"},
			"incantation": {"label": "Incantation", "color": "#e08030", "icon": "📜"},
			"minor": {"label": "Pick Up", "color": "#c8a060", "icon": "💰"},
			"major": {"label": "Power Up", "color": "#e8d060", "icon": "⚡"},
		}, slotReward), func(): return {"label": "Battle", "color": "#888888", "icon": "⚔"})
		nodes.append({
			"x": nx,
			"y": ny,
			"type": ("pack" if JS.t(enc.get("isPack")) else "combat"),
			"enc": enc,
			"sprites": [],
			"color": _rewardNodeCfg.color,
			"label": _rewardNodeCfg.label,
			"rewardIcon": _rewardNodeCfg.icon,
			"rewardType": slotReward,
		})
	# ── Specials ──────────────────────────────────────────────────────────────
	var gymSpecials = JS.arr(specials).filter(func(s = null): return s.get("type") == "gym")
	var midSpecials = JS.arr(specials).filter(func(s = null): return s.get("type") != "gym")
	# Fixed campfire center position — all specials orbit around it
	var cfX = JS.round(W * 0.5)
	var cfY = JS.round(horizY + ((H - horizY) * 0.36))
	for sp in JS.iter(gymSpecials):
		# Gym: top-center foreground — above campfire but on ground level, path arcs right
		var gx = JS.round(W * 0.5)
		var gy = JS.round(horizY + ((H - horizY) * 0.12))
		# near horizon, top of foreground
		nodes.append({
			"x": gx,
			"y": gy,
			"type": "gym",
			"enc": sp.enc,
			"color": "#c8a060",
			"sprites": [],
			"label": "Gym",
			"pathBias": "right",
		})
	for sp in JS.iter(midSpecials):
		if sp.get("type") == "rival":
			# Rival: left side of map, midground level
			nodes.append({
				"x": JS.round(W * 0.25),
				"y": JS.round(horizY + ((H - horizY) * 0.3)),
				"type": "rival",
				"enc": sp.enc,
				"color": "#9a6aee",
				"sprites": [],
				"label": "Rival",
				"pathBias": "left",
			})
	# campfire and shop no longer appear as midSpecials — they come through encounters
	return nodes

func _nodeRadius(node = null):
	# Campfire and distant nodes get a touch-friendly radius
	if (JS.t(node) and node.get("type") == "campfire"):
		return 32
	return 30

func _hitNode(ex = null, ey = null):
	for i in range(len(_mapNodes)):
		var n = _mapNodes[i]
		var r = _nodeRadius(n)
		var dx = ex - n.x
		var dy = ey - n.y
		if ((dx * dx) + (dy * dy)) <= (r * r):
			return i
	return -1

func _drawNode(ctx = null, node = null, hovered = null, tick = null):
	if node.get("type") == "campfire":
		return
	# rendered as world object by _drawWorldCampfire
	var x = JS.idx(node, "x")
	var y = JS.idx(node, "y")
	var type_ = JS.idx(node, "type")
	var sprites = JS.idx(node, "sprites")
	var color = JS.idx(node, "color")
	var pulse = 0.9 + (0.1 * sin(tick * 0.004))
	var r = _nodeRadius(node)
	# Glow ring
	ctx.save()
	ctx.globalAlpha = (0.4 if JS.t(hovered) else 0.18)
	ctx.fillStyle = color
	ctx.beginPath()
	ctx.arc(x, y, (r * (1.15 if JS.t(hovered) else 1)) * pulse, 0, PI * 2)
	ctx.fill()
	ctx.restore()
	# Dark circle background
	ctx.save()
	ctx.globalAlpha = 0.8
	ctx.fillStyle = "#08070a"
	ctx.beginPath()
	ctx.arc(x, y, r - 4, 0, PI * 2)
	ctx.fill()
	ctx.restore()
	# Border ring
	ctx.save()
	ctx.globalAlpha = (0.9 if JS.t(hovered) else 0.5)
	ctx.strokeStyle = color
	ctx.lineWidth = (2 if JS.t(hovered) else 1)
	ctx.beginPath()
	ctx.arc(x, y, r - 3, 0, PI * 2)
	ctx.stroke()
	ctx.restore()
	# Content: reward icon (animated) or special icon
	if (type_ == "combat" or type_ == "pack"):
		# Float animation — different phase per x position so nodes don't sync
		var floatY = sin((tick * 0.003) + (node.x * 0.012)) * 5
		var scalePulse = (1 + (0.08 * sin(tick * 0.005)) if type_ == "major" else 1)
		ctx.save()
		ctx.font = JS.s(JS.round((r - 6) * scalePulse)) + "px serif"
		ctx.textAlign = "center"
		ctx.textBaseline = "middle"
		ctx.globalAlpha = (1.0 if JS.t(hovered) else 0.88)
		ctx.fillText(JS.or_(node.get("rewardIcon"), "⚔"), x, y + floatY)
		ctx.restore()
	else:
		_drawNodeIcon(ctx, x, y, node, hovered, tick)
	# Label below node
	ctx.save()
	ctx.font = "bold " + JS.s((10 if JS.t(hovered) else 8)) + "px monospace"
	ctx.textAlign = "center"
	ctx.fillStyle = ("#ffe8a0" if JS.t(hovered) else color)
	ctx.globalAlpha = (0.95 if JS.t(hovered) else 0.7)
	ctx.fillText(JS.or_(node.get("label"), ""), x, (y + r) + 10)
	ctx.restore()

func _mapHover(e = null):
	if JS.t(_mapAnimTarget):
		return
	var r = _mapCanvas.getBoundingClientRect()
	var scaleX = _mapCanvas.width / float(r.width)
	var scaleY = _mapCanvas.height / float(r.height)
	_mapHovered = _hitNode((e.clientX - r.left) * scaleX, (e.clientY - r.top) * scaleY)
	_mapCanvas.style.cursor = ("pointer" if _mapHovered >= 0 else "default")

func _mapClick(e = null):
	if JS.t(_mapAnimTarget):
		return
	# mid-animation — ignore
	var r = _mapCanvas.getBoundingClientRect()
	var scaleX = _mapCanvas.width / float(r.width)
	var scaleY = _mapCanvas.height / float(r.height)
	var idx = _hitNode((e.clientX - r.left) * scaleX, (e.clientY - r.top) * scaleY)
	if idx < 0:
		return
	_startTravel(JS.idx(_mapNodes, idx))

func _startTravel(node = null):
	_mapAnimTarget = node
	_mapAnimT = 0
	_mapHovered = -1
	_mapCanvas.style.cursor = "default"

# ═══ RENDER LOOP ══════════════════════════════════════════════════════════════
func _startMapLoop():
	var tick = [null]
	if JS.t(_mapRAF):
		JS.cancelAnimationFrame(_mapRAF)
	var _fn3 = func():
		_renderMap()
		if JS.t(_mapAnimTarget):
			_mapAnimT += 1
			var t = _mapAnimT / float(MAP_ANIM_FRAMES)
			var ease_ = ((2 * t) * t if t < 0.5 else 1 - (pow(((-2) * t) + 2, 2) / 2.0))
			_mapPlayerX = JS.round(_mapOriginX + ((_mapAnimTarget.x - _mapOriginX) * ease_))
			_mapPlayerY = JS.round(_mapOriginY + ((_mapAnimTarget.y - _mapOriginY) * ease_))
			if _mapAnimT >= MAP_ANIM_FRAMES:
				_mapPlayerX = _mapAnimTarget.x
				_mapPlayerY = _mapAnimTarget.y
				var target = _mapAnimTarget
				_mapAnimTarget = null
				stopMapCanvas()
				# Dispatch to correct handler
				JS.setTimeout(func(): return _dispatchNode(target), 80)
				return
		_mapRAF = JS.requestAnimationFrame(tick[0])
	tick[0] = _fn3
	_mapRAF = JS.requestAnimationFrame(tick[0])

func _dispatchNode(node = null):
	if node.get("type") == "campfire":
		ShopCampfire.enterCampfire()
		return
	if node.get("type") == "shop":
		ShopCampfire.enterShop()
		return
	if node.get("type") == "rival":
		GymRival.showRivalIntro()
		return
	if node.get("type") == "gym":
		if (JS.t(node.get("enc")) and JS.t(node.enc.get("_forced"))):
			GymRival.showGymIntro(true)
		else:
			GymRival.showGymIntro(false)
		return
	# combat or pack
	BattleLoad.loadBattle(node.enc)

# ═══ DRAWING ══════════════════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════════════════════════
# NIGHT SCENE RENDERING
# ═══════════════════════════════════════════════════════════════════════════
func _renderMap():
	var canvas = _mapCanvas
	if not JS.t(canvas):
		return
	var ctx = canvas.getContext("2d")
	var W = canvas.width
	var H = canvas.height
	var tick = JS.dateNow()
	var horizY = floori(H * 0.45)
	_drawNightSky(ctx, W, H, horizY, tick)
	_drawTerrain(ctx, W, H, horizY, tick)
	# Ground paths from origin to every node (drawn below nodes)
	var isAirZone = State.currentZoneElement == "Air"
	if not isAirZone:
		for node in JS.iter(_mapNodes):
			_drawGroundPath(ctx, _mapOriginX, _mapOriginY, node.x, node.y, node.color, W, H, horizY, node.pathBias)
	else:
		# Air: dotted cloud walkway path to each node (from static origin)
		for node in JS.iter(_mapNodes):
			_drawAirCloudPath(ctx, _mapOriginX, _mapOriginY, node.x, node.y)
	# World campfire — zone-themed, with cloud platform in Air zone
	var _arr4 = JS.iter(_mapNodes)
	for i in range(len(_arr4)):
		var node = _arr4[i]
		if node.get("type") == "campfire":
			if isAirZone:
				# Cloud platform first, then fire on top
				_cloudPlatform(ctx, node.x, node.y + 12, 68, 18, false)
			_drawZoneCampfire(ctx, node.x, node.y, JS.eq(i, _mapHovered), tick)
	# Warm origin glow under player start (non-air) or player cloud (air)
	if isAirZone:
		_cloudPlatform(ctx, _mapOriginX, _mapOriginY - 4, 85, 20, true)
	else:
		var og = ctx.createRadialGradient(_mapOriginX, _mapOriginY, 0, _mapOriginX, _mapOriginY, 18)
		og.addColorStop(0, "rgba(200,160,60,0.28)")
		og.addColorStop(1, "rgba(200,160,60,0)")
		ctx.fillStyle = og
		ctx.fillRect(_mapOriginX - 18, _mapOriginY - 18, 36, 36)
	# Destination nodes (non-campfire)
	var _arr5 = JS.iter(_mapNodes)
	for i in range(len(_arr5)):
		var node = _arr5[i]
		if node.get("type") != "campfire":
			if isAirZone:
				_drawAirCloudNode(ctx, node, JS.eq(i, _mapHovered), tick)
			else:
				_drawNode(ctx, node, JS.eq(i, _mapHovered), tick)
	# Foreground trees frame the scene
	_drawFgTrees(ctx, W, H, horizY)
	# Zone-specific foreground details (critters, particles, ambience)
	_drawZoneDetails(ctx, W, H, horizY, tick)
	# Player sprite
	_drawMapPlayer(ctx, _mapPlayerX, _mapPlayerY, tick)

# ── Night Sky ──────────────────────────────────────────────────────────────
func _drawNightSky(ctx = null, W = null, H = null, horizY = null, tick = null):
	var sky = ctx.createLinearGradient(0, 0, 0, horizY)
	sky.addColorStop(0, "#020110")
	sky.addColorStop(0.45, "#050318")
	sky.addColorStop(1, "#0d0820")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, horizY + 4)
	# Moon — upper right area
	_drawMoon(ctx, JS.round(W * 0.8), JS.round(H * 0.13), tick)
	# Stars
	var stars = _getStarField(W, H, horizY)
	for s in JS.iter(stars):
		var tw = s.bright * (0.4 + (0.6 * sin((tick * s.spd) + s.ph)))
		ctx.globalAlpha = max(0, tw)
		ctx.fillStyle = s.col
		ctx.fillRect(s.x, s.y, s.sz, s.sz)
	ctx.globalAlpha = 1
	_drawNebulae(ctx, W, horizY, tick)
	_drawClouds(ctx, W, H, horizY, tick)

func _initClouds(W = null, H = null, horizY = null):
	if JS.t(len(_clouds)):
		return
	# already initialised
	# Each cloud: x (world), y (fixed), w, h, speed, opacity, shape[]
	var CLOUD_DEFS = [
		{
			"relW": 0.22,
			"relY": 0.08,
			"speed": 0.008,
			"opacity": 0.13,
			"shape": [[0, 2, 8, 3], [2, 1, 12, 4], [5, 0, 10, 5], [10, 1, 8, 4], [16, 2, 6, 3]],
		},
		{
			"relW": 0.15,
			"relY": 0.16,
			"speed": 0.013,
			"opacity": 0.1,
			"shape": [[0, 2, 6, 3], [2, 0, 9, 4], [7, 1, 7, 4], [12, 2, 5, 3]],
		},
		{
			"relW": 0.3,
			"relY": 0.05,
			"speed": 0.006,
			"opacity": 0.09,
			"shape": [[0, 3, 10, 3], [3, 1, 14, 5], [9, 0, 12, 6], [17, 1, 10, 5], [23, 2, 8, 4]],
		},
		{
			"relW": 0.55,
			"relY": 0.12,
			"speed": 0.01,
			"opacity": 0.11,
			"shape": [[0, 2, 7, 3], [2, 1, 10, 4], [7, 0, 8, 5], [12, 2, 7, 3]],
		},
		{
			"relW": 0.75,
			"relY": 0.06,
			"speed": 0.007,
			"opacity": 0.08,
			"shape": [[0, 2, 9, 3], [3, 0, 13, 5], [9, 1, 10, 5], [17, 2, 7, 3]],
		},
	]
	for def in JS.iter(CLOUD_DEFS):
		_clouds.append({
			"x": def.relW * W,
			"y": JS.round(def.relY * horizY),
			"speed": def.speed,
			"opacity": def.opacity,
			"shape": def.shape,
			"wrapW": W,
		})

func _updateClouds(dt = null):
	for c in JS.iter(_clouds):
		c.x += c.speed * dt
		if c.x > (c.wrapW + 200):
			c.x = -200

func _drawClouds(ctx = null, W = null, H = null, horizY = null, tick = null):
	_initClouds(W, H, horizY)
	var dt = (min(tick - _lastCloudTick, 50) if JS.t(_lastCloudTick) else 16)
	_lastCloudTick = tick
	_updateClouds(dt)
	for c in JS.iter(_clouds):
		var ps = 3
		# pixel scale
		ctx.save()
		ctx.globalAlpha = c.opacity
		ctx.fillStyle = "#c8d4f8"
		for _e6 in JS.iter(c.shape):
			var rx = JS.idx(_e6, 0)
			var ry = JS.idx(_e6, 1)
			var rw = JS.idx(_e6, 2)
			var rh = JS.idx(_e6, 3)
			ctx.fillRect(JS.round(c.x + (rx * ps)), JS.round(c.y + (ry * ps)), rw * ps, rh * ps)
		# Slightly brighter top edge highlight
		ctx.globalAlpha = c.opacity * 0.5
		ctx.fillStyle = "#e8eeff"
		for _e7 in JS.iter(c.shape):
			var rx = JS.idx(_e7, 0)
			var ry = JS.idx(_e7, 1)
			var rw = JS.idx(_e7, 2)
			ctx.fillRect(JS.round(c.x + (rx * ps)), JS.round(c.y + (ry * ps)), rw * ps, ps)
		ctx.restore()

func _getStarField(W = null, H = null, horizY = null):
	var key = JS.s(W) + "x" + JS.s(H)
	if (JS.t(_starCache) and _starCacheKey == key):
		return _starCache
	var out = []
	for i in range(90):
		var rx = (JS.mod((i * 137.508) + 23.7, 1000)) / 1000.0
		var ry = (JS.mod((i * 97.31) + 11.1, 1000)) / 1000.0
		var rs = (JS.mod((i * 53.17) + 5.3, 1000)) / 1000.0
		var rp = (JS.mod((i * 211.3) + 7.7, 1000)) / 1000.0
		var rsp = (JS.mod((i * 73.9) + 3.3, 1000)) / 1000.0
		var rc = (JS.mod((i * 43.1) + 9.1, 1000)) / 1000.0
		out.append({
			"x": JS.round(rx * W),
			"y": JS.round((ry * horizY) * 0.95),
			"sz": (2 if rs < 0.07 else 1),
			"bright": 0.35 + (rs * 0.55),
			"ph": (rp * PI) * 2,
			"spd": 0.0007 + (rsp * 0.0018),
			"col": ("#c8d0ff" if rc < 0.25 else ("#ffffff" if rc < 0.55 else "#ffe8cc")),
		})
	_starCache = out
	_starCacheKey = key
	return out

func _drawMoon(ctx = null, mx = null, my = null, tick = null):
	# Outer glow
	var glow = ctx.createRadialGradient(mx, my, 0, mx, my, 44)
	glow.addColorStop(0, "rgba(180,210,255,0.14)")
	glow.addColorStop(0.5, "rgba(140,180,240,0.05)")
	glow.addColorStop(1, "rgba(100,130,200,0)")
	ctx.fillStyle = glow
	ctx.fillRect(mx - 44, my - 44, 88, 88)
	# Inner glow
	var g2 = ctx.createRadialGradient(mx, my, 0, mx, my, 22)
	g2.addColorStop(0, "rgba(220,235,255,0.18)")
	g2.addColorStop(1, "rgba(180,210,255,0)")
	ctx.fillStyle = g2
	ctx.fillRect(mx - 22, my - 22, 44, 44)
	# Pixel moon disc (12 wide, 8 tall, scale 3)
	var moonRows = [
		"....1111....",
		"..11111111..",
		".1112211111.",
		"111221111111",
		"112221111111",
		".1122211111.",
		"..11111111..",
		"....1111....",
	]
	var moonPal = {"1": "#ccd8f0", "2": "#e4eeff"}
	var ps = 3
	var ox = mx - ((12 * ps) / 2.0)
	var oy = my - ((len(moonRows) * ps) / 2.0)
	var _arr8 = JS.iter(moonRows)
	for ry in range(len(_arr8)):
		var row = _arr8[ry]
		var _arr9 = JS.iter(JS.arr(row))
		for rx in range(len(_arr9)):
			var ch = _arr9[rx]
			if not JS.t(JS.idx(moonPal, ch)):
				continue
			ctx.fillStyle = JS.idx(moonPal, ch)
			ctx.fillRect(JS.round(ox + (rx * ps)), JS.round(oy + (ry * ps)), ps, ps)
	# Crescent shadow — dark overlay slightly offset right
	ctx.save()
	ctx.globalAlpha = 0.58
	ctx.fillStyle = "#030112"
	ctx.beginPath()
	ctx.ellipse(mx + 6, my, 11, 14, 0, 0, PI * 2)
	ctx.fill()
	ctx.restore()

func _drawNebulae(ctx = null, W = null, horizY = null, tick = null):
	var patches = [
		{"x": W * 0.15, "y": horizY * 0.22, "rx": W * 0.12, "ry": horizY * 0.09, "col": "rgba(70,30,110,", "b": 0.055},
		{"x": W * 0.55, "y": horizY * 0.35, "rx": W * 0.1, "ry": horizY * 0.07, "col": "rgba(30,50,120,", "b": 0.045},
		{"x": W * 0.38, "y": horizY * 0.12, "rx": W * 0.08, "ry": horizY * 0.06, "col": "rgba(90,25,70,", "b": 0.038},
	]
	for p in JS.iter(patches):
		var alpha = p.b + (0.018 * sin((tick * 0.0009) + p.x))
		var g = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, max(p.rx, p.ry))
		g.addColorStop(0, JS.s(p.col + (alpha * 2)) + ")")
		g.addColorStop(1, JS.s(p.col) + "0)")
		ctx.save()
		ctx.scale(1, p.ry / float(p.rx))
		ctx.fillStyle = g
		ctx.beginPath()
		ctx.arc(p.x, p.y * (p.rx / float(p.ry)), p.rx, 0, PI * 2)
		ctx.fill()
		ctx.restore()

# ── Terrain ────────────────────────────────────────────────────────────────
func _hillY(x = null, horizY = null, H = null):
	var fg = (JS.or_(H, horizY * 1.6)) - horizY
	return ((horizY + ((fg * 0.055) * sin((x * 0.019) + 1.2))) + ((fg * 0.09) * sin((x * 0.009) + 0.5))) + ((fg * 0.028) * sin((x * 0.047) + 2.1))

# Shared: distant jagged mountain range just above horizon
# cols: array of 1-3 fill colors from farthest to nearest layer
func _mountains(ctx = null, W = null, horizY = null, cols = null, seeds = null):
	var layers = len(cols)
	for li in range(ceili(layers)):
		var seed_ = (seeds[li] if JS.t(seeds) else li * 137)
		var depth = (li + 1) / float(layers)
		# 1=nearest layer
		var peakH = horizY * (0.55 + (depth * 0.25))
		# how high peaks reach above horizon
		ctx.fillStyle = cols[li]
		ctx.beginPath()
		ctx.moveTo(0, horizY)
		var px = 0
		while px <= W:
			# jagged peak width varies
			var pw = 28 + (JS.mod((seed_ * 7) + (px * 3), 55))
			var ph = peakH * (0.55 + ((0.45 * (JS.mod((seed_ + px) * 1031, 100))) / 100.0))
			var mx = ((px + (pw * 0.45)) + (JS.mod(seed_ + (px * 2), 12))) - 6
			ctx.lineTo(JS.round(px), horizY)
			ctx.lineTo(JS.round(mx), JS.round(horizY - ph))
			ctx.lineTo(JS.round(px + pw), horizY)
			px += pw
		ctx.lineTo(W, horizY)
		ctx.closePath()
		ctx.fill()

# ═══════════════════════════════════════════════════════════════════════
# ZONE-AWARE TERRAIN SYSTEM
# Each element has a unique landscape: ground color, features, vegetation.
# _drawTerrain dispatches to zone-specific renderer based on playerElement.
# ═══════════════════════════════════════════════════════════════════════
# Shared: draw a filled ground shape from terrainY to H
func _groundShape(ctx = null, W = null, H = null, horizY = null, col1 = null, col2 = null, wave1 = null, wave2 = null, wave3 = null):
	var grd = ctx.createLinearGradient(0, horizY, 0, H)
	grd.addColorStop(0, col1)
	grd.addColorStop(1, col2)
	ctx.fillStyle = grd
	ctx.beginPath()
	ctx.moveTo(0, H)
	for x in range(0, floori(W) + 1):
		var hy = ((_hillY(x, horizY, H) + ((JS.or_(wave1, 0)) * sin((x * 0.02) + 1.1))) + ((JS.or_(wave2, 0)) * sin((x * 0.009) + 0.5))) + ((JS.or_(wave3, 0)) * sin((x * 0.047) + 2.1))
		if x == 0:
			ctx.lineTo(0, JS.round(hy))
		else:
			ctx.lineTo(x, JS.round(hy))
	ctx.lineTo(W, H)
	ctx.closePath()
	ctx.fill()

# Shared silhouette hills (far background)
func _hillSilhouette(ctx = null, W = null, H = null, horizY = null, col = null):
	ctx.fillStyle = col
	ctx.beginPath()
	for x in range(0, floori(W) + 1):
		var hy = _hillY(x, horizY, H)
		if x == 0:
			ctx.moveTo(0, JS.round(hy))
		else:
			ctx.lineTo(x, JS.round(hy))
	ctx.lineTo(W, H)
	ctx.lineTo(0, H)
	ctx.closePath()
	ctx.fill()

# Second hill layer (mid-distance)
func _hill2(ctx = null, W = null, H = null, horizY = null, col = null):
	ctx.fillStyle = col
	ctx.beginPath()
	for x in range(0, floori(W) + 1):
		var hy = ((horizY + ((H - horizY) * 0.08)) + ((sin((x * 0.028) + 2.8) * (H - horizY)) * 0.045)) + ((sin((x * 0.013) + 1.4) * (H - horizY)) * 0.065)
		if x == 0:
			ctx.moveTo(0, JS.round(hy))
		else:
			ctx.lineTo(x, JS.round(hy))
	ctx.lineTo(W, H)
	ctx.lineTo(0, H)
	ctx.closePath()
	ctx.fill()

# ──────────────────────────────────────────────────────────────────────────────
# FIRE ZONE — volcanic rock, lava veins, charred trees
# ──────────────────────────────────────────────────────────────────────────────
func _terrainFire(ctx = null, W = null, H = null, horizY = null, tick = null):
	# Distant volcanic mountains with lava glow at peaks
	_mountains(ctx, W, horizY, ["#0e0200", "#1a0400", "#260602"], [13, 53, 97])
	# Lava glow bleeding from mountain peaks
	for i in range(5):
		var mx = JS.round(((JS.mod((i * 211) + 43, 997)) / 997.0) * W)
		var mg = ctx.createRadialGradient(mx, horizY, 2, mx, horizY, 18 + (i * 4))
		mg.addColorStop(0, "rgba(255,80,0,0.22)")
		mg.addColorStop(1, "rgba(255,40,0,0)")
		ctx.fillStyle = mg
		ctx.beginPath()
		ctx.arc(mx, horizY, 18 + (i * 4), 0, PI * 2)
		ctx.fill()
	_hillSilhouette(ctx, W, H, horizY, "#1a0603")
	_hill2(ctx, W, H, horizY, "#230808")
	_groundShape(ctx, W, H, horizY, "#1c0804", "#0e0402", 0, 0, 0)
	# Lava river — glowing channel across mid-ground
	var lavaY = JS.round(horizY + ((H - horizY) * 0.55))
	var lavaH = JS.round((H - horizY) * 0.06)
	for x in range(ceili(W)):
		var wave = sin((x * 0.04) + (tick * 0.003)) * 3
		var glow = 0.5 + (0.5 * sin((x * 0.08) + (tick * 0.005)))
		ctx.fillStyle = "rgb(" + JS.s(JS.round(200 + (55 * glow))) + "," + JS.s(JS.round(40 + (30 * glow))) + ",0)"
		ctx.fillRect(x, lavaY + JS.round(wave), 1, lavaH)
	# Lava glow
	var lg = ctx.createLinearGradient(0, lavaY - 8, 0, (lavaY + lavaH) + 12)
	lg.addColorStop(0, "rgba(255,80,0,0)")
	lg.addColorStop(0.4, "rgba(255,80,0,0.18)")
	lg.addColorStop(1, "rgba(255,80,0,0)")
	ctx.fillStyle = lg
	ctx.fillRect(0, lavaY - 8, W, lavaH + 20)
	# Cracked rock texture
	for i in range(18):
		var cx2 = JS.mod((i * 173) + 31, W)
		var cy2 = ((lavaY + lavaH) + 4) + (JS.mod((i * 97) + 13, JS.round((H - lavaY) * 0.7)))
		ctx.fillStyle = ("#2a0d04" if (JS.mod(i, 3)) == 0 else "#1a0804")
		ctx.fillRect(cx2, cy2, 4 + (JS.mod(i, 5)), 2)
	# Horizon glow
	var hg = ctx.createLinearGradient(0, horizY - 15, 0, horizY + 10)
	hg.addColorStop(0, "rgba(200,50,0,0.18)")
	hg.addColorStop(1, "rgba(200,50,0,0)")
	ctx.fillStyle = hg
	ctx.fillRect(0, horizY - 15, W, 25)
	# Charred dead trees
	_fireDeadTrees(ctx, W, H, horizY)
	_fireDeadTrees_fg(ctx, W, H, horizY)
	# Ash particles drifting down
	for i in range(12):
		var phase = JS.mod((tick * 0.0003) + (i * 0.21), 1)
		var ax = (JS.mod((i * 197) + 23, W)) + JS.round(sin((tick * 0.0009) + i) * 6)
		var ay = JS.round(phase * H)
		var alpha = sin(phase * PI) * 0.4
		if alpha < 0.05:
			continue
		ctx.fillStyle = "rgba(80,40,20," + JS.toFixed(alpha, 2) + ")"
		ctx.fillRect(ax, ay, (3 if (JS.mod(i, 4)) == 0 else 2), 1)
	# Foreground lava pool with glow
	var poolX = JS.round(W * 0.38)
	var poolY = JS.round(H * 0.88)
	var poolW = JS.round(W * 0.14)
	var poolH = JS.round((H - horizY) * 0.05)
	var px2 = poolX
	while px2 < (poolX + poolW):
		var wave = sin((px2 * 0.07) + (tick * 0.004)) * 2
		var glow = 0.55 + (0.35 * sin((px2 * 0.11) + (tick * 0.006)))
		ctx.fillStyle = "rgb(" + JS.s(JS.round(210 + (45 * glow))) + "," + JS.s(JS.round(30 + (25 * glow))) + ",0)"
		ctx.fillRect(px2, poolY + JS.round(wave), 1, poolH)
		px2 += 1
	var plg = ctx.createRadialGradient(poolX + (poolW / 2.0), poolY, 0, poolX + (poolW / 2.0), poolY, poolW * 0.6)
	plg.addColorStop(0, "rgba(255,80,0,0.22)")
	plg.addColorStop(1, "transparent")
	ctx.fillStyle = plg
	ctx.fillRect(poolX - JS.round(poolW * 0.3), poolY - 8, JS.round(poolW * 1.6), poolH + 16)
	# Smoke columns rising from lava
	for i in range(3):
		var scx = JS.round(W * (0.22 + (i * 0.28)))
		var sPhase = JS.mod((tick * 0.0006) + (i * 0.38), 1)
		var scy = JS.round((H * 0.62) - ((sPhase * H) * 0.18))
		var salpha = sin(sPhase * PI) * 0.18
		ctx.fillStyle = "rgba(60,30,15," + JS.toFixed(salpha, 2) + ")"
		ctx.fillRect(scx - 4, scy, 8 + JS.round(sPhase * 4), 6)

# Generic pine and oak (used by Nature zone and any zone that needs generic trees)
func _drawPine(ctx = null, cx = null, baseY = null, sc = null):
	var s = max(1, JS.round(sc * 2))
	ctx.fillStyle = "#200f06"
	ctx.fillRect(cx - s, baseY - (4 * s), 2 * s, 4 * s)
	ctx.fillStyle = "#0d2a0f"
	ctx.fillRect(cx - (4 * s), baseY - (7 * s), 8 * s, 3 * s)
	ctx.fillStyle = "#122e14"
	ctx.fillRect(cx - (3 * s), baseY - (8 * s), 6 * s, 2 * s)
	ctx.fillStyle = "#0d2a0f"
	ctx.fillRect(cx - (3 * s), baseY - (12 * s), 6 * s, 4 * s)
	ctx.fillStyle = "#122e14"
	ctx.fillRect(cx - (2 * s), baseY - (13 * s), 4 * s, 2 * s)
	ctx.fillStyle = "#112c13"
	ctx.fillRect(cx - (2 * s), baseY - (16 * s), 4 * s, 4 * s)
	ctx.fillRect(cx - s, baseY - (17 * s), 2 * s, 2 * s)
	ctx.fillStyle = "#173a1a"
	ctx.fillRect(cx - s, baseY - (19 * s), 2 * s, 3 * s)
	ctx.fillStyle = "#1d4820"
	ctx.fillRect(cx - (4 * s), baseY - (7 * s), s, 2 * s)
	ctx.fillRect(cx - (3 * s), baseY - (12 * s), s, 2 * s)
	ctx.fillRect(cx - (2 * s), baseY - (16 * s), s, 2 * s)
	ctx.fillRect(cx - s, baseY - (19 * s), s, s)

func _drawOak(ctx = null, cx = null, baseY = null, sc = null):
	var s = max(1, JS.round(sc * 2))
	ctx.fillStyle = "#200f06"
	ctx.fillRect(cx - s, baseY - (5 * s), 2 * s, 5 * s)
	ctx.fillStyle = "#160a04"
	ctx.fillRect(cx, baseY - (4 * s), s, 4 * s)
	ctx.fillStyle = "#112e14"
	ctx.fillRect(cx - (4 * s), baseY - (13 * s), 8 * s, 8 * s)
	ctx.fillRect(cx - (3 * s), baseY - (15 * s), 6 * s, 3 * s)
	ctx.fillRect(cx - (5 * s), baseY - (12 * s), 10 * s, 4 * s)
	ctx.fillRect(cx - (4 * s), baseY - (8 * s), 8 * s, 2 * s)
	ctx.fillStyle = "#0a1e0c"
	ctx.fillRect(cx + (2 * s), baseY - (13 * s), 2 * s, 7 * s)
	ctx.fillRect(cx + s, baseY - (15 * s), 3 * s, 3 * s)
	ctx.fillStyle = "#193a1c"
	ctx.fillRect(cx - (4 * s), baseY - (14 * s), 3 * s, 3 * s)
	ctx.fillStyle = "#214a24"
	ctx.fillRect(cx - (3 * s), baseY - (15 * s), 2 * s, 2 * s)
	ctx.fillStyle = "#173818"
	ctx.fillRect(cx - (5 * s), baseY - (11 * s), 2 * s, 2 * s)

func _fireDeadTrees(ctx = null, W = null, H = null, horizY = null):
	for i in range(10):
		var tx = JS.round(((JS.mod((i * 211) + 53, 997)) / 997.0) * W)
		var ty = JS.round(_hillY(tx, horizY, H))
		var h = 10 + (JS.mod(i * 7, 12))
		var s = 1
		ctx.fillStyle = "#100604"
		ctx.fillRect(tx - s, ty - h, s * 2, h)
		if (JS.mod(i, 3)) != 0:
			ctx.fillRect(tx + s, (ty - h) + 3, s * 3, s)
			ctx.fillRect(tx - (s * 3), (ty - h) + 6, s * 3, s)

func _fireDeadTrees_fg(ctx = null, W = null, H = null, horizY = null):
	for _e10 in JS.iter([[W * 0.05, H * 0.89], [W * 0.93, H * 0.89]]):
		var tx = JS.idx(_e10, 0)
		var ty = JS.idx(_e10, 1)
		var s = 2
		var h = 34
		ctx.fillStyle = "#180806"
		ctx.fillRect(tx - s, ty - h, s * 2, h)
		ctx.fillRect(tx + s, (ty - h) + 8, s * 4, s * 2)
		ctx.fillRect(tx - (s * 5), (ty - h) + 14, s * 4, s * 2)
		ctx.fillRect(tx + s, (ty - h) + 20, s * 3, s)
		ctx.fillRect(tx - (s * 4), (ty - h) + 25, s * 3, s)

# ──────────────────────────────────────────────────────────────────────────────
# WATER ZONE — sandy beach, ocean waves, palm trees
# ──────────────────────────────────────────────────────────────────────────────
func _terrainWater(ctx = null, W = null, H = null, horizY = null, tick = null):
	# Distant ocean cliffs and islands on horizon
	_mountains(ctx, W, horizY, ["#081420", "#0c1e2e"], [23, 71])
	# Distant island silhouettes (low, flat-topped)
	for _e11 in JS.iter([[0.2, 0.6], [0.55, 0.35], [0.78, 0.5]]):
		var xf = JS.idx(_e11, 0)
		var wf = JS.idx(_e11, 1)
		var ix = JS.round(W * xf)
		var iw = JS.round((W * wf) * 0.15)
		var ih = JS.round(horizY * 0.25)
		ctx.fillStyle = "#091828"
		ctx.beginPath()
		ctx.ellipse(ix, horizY, iw, ih, 0, PI, PI * 2)
		ctx.fill()
	_hillSilhouette(ctx, W, H, horizY, "#0a1820")
	_hill2(ctx, W, H, horizY, "#0f2030")
	# Sandy beach ground
	var bg = ctx.createLinearGradient(0, horizY, 0, H)
	bg.addColorStop(0, "#1a3040")
	bg.addColorStop(0.35, "#8a7a4a")
	bg.addColorStop(1, "#c8b060")
	ctx.fillStyle = bg
	ctx.beginPath()
	ctx.moveTo(0, H)
	for x in range(0, floori(W) + 1):
		var hy = _hillY(x, horizY, H)
		if x == 0:
			ctx.lineTo(0, JS.round(hy))
		else:
			ctx.lineTo(x, JS.round(hy))
	ctx.lineTo(W, H)
	ctx.closePath()
	ctx.fill()
	# Ocean at bottom — waves
	var oceanTop = JS.round(H * 0.82)
	var og = ctx.createLinearGradient(0, oceanTop, 0, H)
	og.addColorStop(0, "#1a6888")
	og.addColorStop(1, "#0a3a55")
	ctx.fillStyle = og
	ctx.fillRect(0, oceanTop, W, H - oceanTop)
	# Wave lines
	for wi in range(5):
		var wy = oceanTop + (wi * 5)
		var phase = (tick * 0.002) + (wi * 1.2)
		ctx.fillStyle = "rgba(160,220,255," + JS.s(0.12 - (wi * 0.02)) + ")"
		for x in range(ceili(W)):
			var wave = sin((x * 0.03) + phase) * 3
			if abs(wave) > 1.5:
				ctx.fillRect(x, wy + JS.round(wave), 1, 2)
	# Seafoam edge
	var sf = tick * 0.0015
	for x in range(ceili(W)):
		var foam = (sin((x * 0.05) + sf) * 2) + sin((x * 0.13) + (sf * 1.3))
		if foam > 1.8:
			ctx.fillStyle = "rgba(220,240,255,0.4)"
			ctx.fillRect(x, oceanTop + JS.round(foam * 0.5), 1, 2)
	# Horizon glow (teal)
	var hg = ctx.createLinearGradient(0, horizY - 12, 0, horizY + 8)
	hg.addColorStop(0, "rgba(20,120,150,0.2)")
	hg.addColorStop(1, "rgba(20,120,150,0)")
	ctx.fillStyle = hg
	ctx.fillRect(0, horizY - 12, W, 20)
	# Palm trees
	_palmTree(ctx, JS.round(W * 0.08), JS.round(H * 0.78), 1.0)
	_palmTree(ctx, JS.round(W * 0.14), JS.round(H * 0.8), 0.8)
	_palmTree(ctx, JS.round(W * 0.9), JS.round(H * 0.78), 0.9)
	_palmTree(ctx, JS.round(W * 0.84), JS.round(H * 0.8), 0.75)
	for i in range(8):
		var tx = JS.round(((JS.mod((i * 211) + 53, 997)) / 997.0) * W)
		var ty = JS.round(_hillY(tx, horizY, H)) - 4
		_palmTree(ctx, tx, ty, 0.4 + ((JS.mod(i, 3)) * 0.15))
	# Distant ship silhouette
	var shipX = JS.round(W * 0.68)
	var shipY = JS.round(horizY - 6)
	ctx.fillStyle = "#060e18"
	ctx.fillRect(shipX - 12, shipY, 24, 5)
	ctx.fillRect(shipX - 8, shipY - 2, 16, 2)
	ctx.fillRect(shipX - 2, shipY - 14, 2, 12)
	ctx.fillRect(shipX + 1, shipY - 14, 8, 2)
	ctx.fillRect(shipX + 1, shipY - 10, 6, 4)
	# Shore sheen at tide line
	for x in range(ceili(W)):
		var sheen = (sin((x * 0.04) + (tick * 0.0012)) * 0.5) + 0.5
		var sheenY = JS.round((H * 0.82) - (sheen * 3))
		ctx.fillStyle = "rgba(120,200,240," + JS.toFixed(sheen * 0.08, 2) + ")"
		ctx.fillRect(x, sheenY, 1, 2)
	# Reef tint in shallow water
	var reefG = ctx.createLinearGradient(0, JS.round(H * 0.82), 0, JS.round(H * 0.88))
	reefG.addColorStop(0, "rgba(0,120,80,0.10)")
	reefG.addColorStop(1, "rgba(0,80,60,0)")
	ctx.fillStyle = reefG
	ctx.fillRect(0, JS.round(H * 0.82), W, JS.round(H * 0.06))

func _palmTree(ctx = null, cx = null, baseY = null, sc = null):
	var s = max(1, JS.round(sc * 3))
	# Curved trunk (pixel steps)
	ctx.fillStyle = "#7a5c2a"
	for i in range(ceili(12 * s)):
		var lean = JS.round((sin(i * 0.15) * s) * 0.8)
		ctx.fillRect((cx - s) + lean, baseY - i, s * 2, 1)
	# Fronds
	var topX = cx + JS.round((sin((12 * s) * 0.15) * s) * 0.8)
	var topY = baseY - (12 * s)
	var fronds = [[-1, -1], [-3, -2], [-5, -2], [-6, -1], [1, -1], [3, -2], [5, -2], [6, -1], [0, -3], [0, -4]]
	for _e12 in JS.iter(fronds):
		var dx = JS.idx(_e12, 0)
		var dy = JS.idx(_e12, 1)
		ctx.fillStyle = "#2a6a18"
		ctx.fillRect(topX + (dx * s), topY + (dy * s), s * 2, s)
		ctx.fillStyle = "#1a4a10"
		ctx.fillRect(topX + (dx * s), (topY + (dy * s)) + s, s * 2, s)
	# Coconuts
	ctx.fillStyle = "#8a6020"
	ctx.fillRect(topX - s, topY, s * 2, s * 2)

# ──────────────────────────────────────────────────────────────────────────────
# ICE ZONE — snow-covered ground, icicles, frozen trees
# ──────────────────────────────────────────────────────────────────────────────
func _terrainIce(ctx = null, W = null, H = null, horizY = null, tick = null):
	# Distant glacial peaks — sharp, pale
	_mountains(ctx, W, horizY, ["#60a8d0", "#80c0e8", "#a0d4f0"], [17, 61, 103])
	# Snow caps on mountain tips
	for i in range(8):
		var mx = JS.round(((JS.mod((i * 173) + 29, 997)) / 997.0) * W)
		var capH = JS.round(horizY * (0.12 + (0.08 * (JS.mod(i, 3)))))
		ctx.fillStyle = "rgba(240,250,255,0.55)"
		ctx.beginPath()
		ctx.moveTo(mx - 8, (horizY - capH) + 6)
		ctx.lineTo(mx, horizY - capH)
		ctx.lineTo(mx + 8, (horizY - capH) + 6)
		ctx.closePath()
		ctx.fill()
	_hillSilhouette(ctx, W, H, horizY, "#a0c8e8")
	_hill2(ctx, W, H, horizY, "#b8d8f0")
	var ig = ctx.createLinearGradient(0, horizY, 0, H)
	ig.addColorStop(0, "#c8e0f8")
	ig.addColorStop(0.5, "#d8eeff")
	ig.addColorStop(1, "#e8f4ff")
	ctx.fillStyle = ig
	ctx.beginPath()
	ctx.moveTo(0, H)
	for x in range(0, floori(W) + 1):
		var hy = _hillY(x, horizY, H)
		if x == 0:
			ctx.lineTo(0, JS.round(hy))
		else:
			ctx.lineTo(x, JS.round(hy))
	ctx.lineTo(W, H)
	ctx.closePath()
	ctx.fill()
	# Snow sparkle texture
	for i in range(40):
		var sx = JS.mod((i * 173) + 31, W)
		var sy = JS.round(_hillY(sx, horizY, H)) + (JS.mod((i * 97) + 13, JS.round((H - horizY) * 0.9)))
		var bright = 0.3 + (0.4 * sin((tick * 0.004) + (i * 0.8)))
		ctx.fillStyle = "rgba(255,255,255," + JS.toFixed(bright, 2) + ")"
		ctx.fillRect(sx, sy, 2, 2)
	# Frozen pond (teal circle mid-ground)
	var pondX = JS.round(W * 0.5)
	var pondY = JS.round(horizY + ((H - horizY) * 0.6))
	var pondW = JS.round(W * 0.18)
	var pondH = JS.round((H - horizY) * 0.06)
	ctx.fillStyle = "#7ab8d8"
	ctx.fillRect(pondX - pondW, pondY, pondW * 2, pondH)
	ctx.fillStyle = "rgba(200,235,255,0.4)"
	ctx.fillRect((pondX - pondW) + 4, pondY + 2, pondW, pondH * 0.4)
	# Icicles hanging from hill edges
	for i in range(20):
		var ix = JS.round(((JS.mod((i * 197) + 41, 997)) / 997.0) * W)
		var iy = JS.round(_hillY(ix, horizY, H))
		var ih = 4 + (JS.mod(i * 7, 10))
		ctx.fillStyle = "#a0d0f0"
		ctx.fillRect(ix - 1, iy, 2, ih)
		ctx.fillStyle = "#c8e8ff"
		ctx.fillRect(ix, iy, 1, ih - 2)
	# Horizon shimmer
	var hg = ctx.createLinearGradient(0, horizY - 10, 0, horizY + 10)
	hg.addColorStop(0, "rgba(180,220,255,0.3)")
	hg.addColorStop(1, "rgba(180,220,255,0)")
	ctx.fillStyle = hg
	ctx.fillRect(0, horizY - 10, W, 20)
	# Snow-capped pines
	for i in range(12):
		var tx = JS.round(((JS.mod((i * 197) + 41, 997)) / 997.0) * W)
		var ty = JS.round(_hillY(tx, horizY, H))
		_snowPine(ctx, tx, ty, 0.4 + ((JS.mod(i, 3)) * 0.15))
	_snowPine(ctx, JS.round(W * 0.05), JS.round(H * 0.88), 0.9)
	_snowPine(ctx, JS.round(W * 0.93), JS.round(H * 0.88), 0.85)
	_snowPine(ctx, JS.round(W * 0.11), JS.round(H * 0.91), 0.7)
	_snowPine(ctx, JS.round(W * 0.87), JS.round(H * 0.91), 0.7)
	# Aurora bands in sky
	var aurColors = ["rgba(0,220,160,", "rgba(60,120,255,", "rgba(180,80,255,"]
	for i in range(3):
		var aY = JS.round((horizY * (0.12 + (i * 0.16))) + (sin((tick * 0.005) + (i * 1.2)) * 6))
		var aH = JS.round(horizY * 0.07)
		var ag = ctx.createLinearGradient(0, aY, 0, aY + aH)
		ag.addColorStop(0, "transparent")
		ag.addColorStop(0.4, JS.s(aurColors[i] + (0.14 + (0.08 * sin((tick * 0.007) + i)))) + ")")
		ag.addColorStop(1, "transparent")
		ctx.fillStyle = ag
		ctx.fillRect(0, aY, W, aH)
	# Frozen cliff waterfall (right side)
	var fwX = JS.round(W * 0.8)
	var fwTopY = JS.round(horizY + ((H - horizY) * 0.06))
	var fwBotY = JS.round(horizY + ((H - horizY) * 0.44))
	ctx.fillStyle = "#3a4858"
	ctx.fillRect(fwX - 7, fwTopY, 14, fwBotY - fwTopY)
	for i in range(5):
		var iAlpha = 0.55 + (0.25 * sin((tick * 0.004) + i))
		ctx.fillStyle = "rgba(180,230,255," + JS.toFixed(iAlpha, 2) + ")"
		ctx.fillRect((fwX - 4) + (i * 2), fwTopY, 2, fwBotY - fwTopY)
	# Ice crack patterns on ground surface
	for i in range(8):
		var icx = JS.round(((JS.mod((i * 211) + 41, 997)) / 997.0) * W)
		var icy = JS.round(_hillY(icx, horizY, H)) + JS.round(JS.mod((i * 73) + 7, (H - horizY) * 0.4))
		ctx.strokeStyle = "rgba(180,220,255,0.3)"
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.moveTo(icx, icy)
		ctx.lineTo(icx + (12 if JS.t(JS.mod(i, 2)) else -10), (icy + 4) + (JS.mod(i, 4)))
		ctx.stroke()

func _snowPine(ctx = null, cx = null, baseY = null, sc = null):
	var s = max(1, JS.round(sc * 2))
	ctx.fillStyle = "#5a3a18"
	ctx.fillRect(cx - s, baseY - (4 * s), s * 2, s * 4)
	var layers = [[8, 3], [6, 4], [5, 4], [3, 5]]
	var _arr14 = JS.iter(layers)
	for i in range(len(_arr14)):
		var _e13 = _arr14[i]
		var w = JS.idx(_e13, 0)
		var h = JS.idx(_e13, 1)
		var ly = baseY - ((8 + (i * 4.5)) * s)
		ctx.fillStyle = "#1a3a50"
		ctx.fillRect(cx - ((w * s) / 2.0), ly, w * s, h * s)
		# Snow cap
		ctx.fillStyle = "#e8f4ff"
		ctx.fillRect(cx - (((w - 2) * s) / 2.0), ly, (w - 2) * s, s)
		ctx.fillStyle = "#cce4f8"
		ctx.fillRect(cx - ((w * s) / 2.0), ly, s, s)
	# Tip snow
	ctx.fillStyle = "#f0f8ff"
	ctx.fillRect(cx - s, baseY - (26 * s), s * 2, s * 3)

# ──────────────────────────────────────────────────────────────────────────────
# LIGHTNING ZONE — cracked dark earth, purple-yellow, storm arcs
# ──────────────────────────────────────────────────────────────────────────────
func _terrainLightning(ctx = null, W = null, H = null, horizY = null, tick = null):
	# Distant jagged storm mountains
	_mountains(ctx, W, horizY, ["#080615", "#0e0c22", "#150f2e"], [31, 73, 113])
	# Lightning glow on distant peaks
	for i in range(4):
		var mx = JS.round(((JS.mod((i * 257) + 41, 997)) / 997.0) * W)
		var mg = ctx.createRadialGradient(mx, horizY, 1, mx, horizY, 20 + (i * 5))
		mg.addColorStop(0, "rgba(180,150,255,0.18)")
		mg.addColorStop(1, "rgba(100,80,200,0)")
		ctx.fillStyle = mg
		ctx.beginPath()
		ctx.arc(mx, horizY, 20 + (i * 5), 0, PI * 2)
		ctx.fill()
	_hillSilhouette(ctx, W, H, horizY, "#0e0c1a")
	_hill2(ctx, W, H, horizY, "#120f20")
	var lg = ctx.createLinearGradient(0, horizY, 0, H)
	lg.addColorStop(0, "#16122a")
	lg.addColorStop(1, "#0c0a18")
	ctx.fillStyle = lg
	ctx.beginPath()
	ctx.moveTo(0, H)
	for x in range(0, floori(W) + 1):
		var hy = _hillY(x, horizY, H)
		if x == 0:
			ctx.lineTo(0, JS.round(hy))
		else:
			ctx.lineTo(x, JS.round(hy))
	ctx.lineTo(W, H)
	ctx.closePath()
	ctx.fill()
	# Cracked earth texture
	for i in range(25):
		var cx2 = JS.mod((i * 173) + 31, W)
		var cy2 = JS.round(_hillY(cx2, horizY, H)) + (JS.mod((i * 97) + 13, JS.round((H - horizY) * 0.85)))
		var len_ = 8 + (JS.mod(i * 7, 20))
		ctx.strokeStyle = "#1e1830"
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.moveTo(cx2, cy2)
		ctx.lineTo(cx2 + ((len_ if JS.t(JS.mod(i, 2)) else -len_) * 0.6), cy2 + ((JS.mod(i, 3)) * 3))
		ctx.stroke()
	# Lightning arc (periodic)
	var arcPhase = JS.mod(floori(tick / 1800.0), 3)
	if (JS.mod(tick, 1800)) < 200:
		var ax = JS.round(W * JS.idx([0.3, 0.6, 0.75], arcPhase))
		var ay1 = JS.round(horizY * 0.6)
		ctx.strokeStyle = "#ffffaa"
		ctx.lineWidth = 2
		ctx.beginPath()
		ctx.moveTo(ax, ay1)
		for seg in range(6):
			ctx.lineTo(ax + ((randf() - 0.5) * 20), ay1 + (seg * 14))
		ctx.stroke()
		ctx.strokeStyle = "rgba(220,200,255,0.3)"
		ctx.lineWidth = 6
		ctx.stroke()
	# Horizon glow (yellow-purple)
	var hg = ctx.createLinearGradient(0, horizY - 12, 0, horizY + 8)
	hg.addColorStop(0, "rgba(180,150,20,0.18)")
	hg.addColorStop(1, "rgba(80,40,150,0.05)")
	ctx.fillStyle = hg
	ctx.fillRect(0, horizY - 12, W, 20)
	# Bare struck trees
	for i in range(8):
		var tx = JS.round(((JS.mod((i * 197) + 41, 997)) / 997.0) * W)
		var ty = JS.round(_hillY(tx, horizY, H))
		_lightningTree(ctx, tx, ty, 0.5 + ((JS.mod(i, 3)) * 0.2))
	_lightningTree(ctx, JS.round(W * 0.05), JS.round(H * 0.88), 0.9)
	_lightningTree(ctx, JS.round(W * 0.93), JS.round(H * 0.88), 0.85)
	# Rain streaks
	for i in range(30):
		var rx2 = JS.mod((i * 173) + 41, W)
		var rPhase = JS.mod((tick * 0.0014) + (i * 0.17), 1)
		var ry2 = JS.round(((rPhase * H) * 1.2) - (H * 0.1))
		var rAlpha = sin(rPhase * PI) * 0.22
		if rAlpha < 0.03:
			continue
		ctx.fillStyle = "rgba(160,180,220," + JS.toFixed(rAlpha, 2) + ")"
		ctx.fillRect(rx2, ry2, 1, 6 + JS.round(rPhase * 4))
	# Storm cloud mass layered over horizon
	for ci in range(4):
		var cX2 = JS.round(W * (0.12 + (ci * 0.22)))
		var cY2 = JS.round(horizY * (0.55 + (ci * 0.08)))
		var cW2 = JS.round(W * (0.18 + (ci * 0.04)))
		var cg = ctx.createRadialGradient(cX2, cY2, 4, cX2, cY2, JS.round(cW2 * 0.55))
		cg.addColorStop(0, "rgba(18,12,35,0.55)")
		cg.addColorStop(1, "rgba(8,5,18,0)")
		ctx.fillStyle = cg
		ctx.fillRect(cX2 - JS.round(cW2 * 0.6), cY2 - JS.round(horizY * 0.12), JS.round(cW2 * 1.2), JS.round(horizY * 0.24))

func _lightningTree(ctx = null, cx = null, baseY = null, sc = null):
	var s = max(1, JS.round(sc * 2))
	ctx.fillStyle = "#1a1428"
	ctx.fillRect(cx - s, baseY - (14 * s), s * 2, 14 * s)
	# Singed branches
	ctx.fillRect(cx + s, baseY - (12 * s), s * 5, s)
	ctx.fillRect(cx - (s * 5), baseY - (9 * s), s * 4, s)
	ctx.fillRect(cx + s, baseY - (6 * s), s * 4, s)
	# Yellow tip glow
	var glow = 0.4 + (0.4 * sin((JS.dateNow() * 0.008) + cx))
	ctx.fillStyle = "rgba(220,200,40," + JS.toFixed(glow, 2) + ")"
	ctx.fillRect(cx - s, baseY - (14 * s), s * 2, s)

# ──────────────────────────────────────────────────────────────────────────────
# EARTH ZONE — rocky brown terrain, stone formations, cave
# ──────────────────────────────────────────────────────────────────────────────
func _terrainEarth(ctx = null, W = null, H = null, horizY = null, tick = null):
	# Distant mesa plateaus and rock formations
	_mountains(ctx, W, horizY, ["#180e04", "#221408", "#301a0a"], [19, 67, 107])
	# Flat-topped mesa caps (distinctive Earth silhouette)
	var _arr16 = JS.iter([[0.15, 0.12], [0.42, 0.18], [0.68, 0.1], [0.85, 0.14]])
	for i in range(len(_arr16)):
		var _e15 = _arr16[i]
		var xf = JS.idx(_e15, 0)
		var wf = JS.idx(_e15, 1)
		var mx = JS.round(W * xf)
		var mw = JS.round(W * wf)
		var mh = JS.round(horizY * (0.3 + (0.15 * (JS.mod(i, 3)))))
		ctx.fillStyle = ("#1e1208" if (JS.mod(i, 2)) == 0 else "#280f05")
		ctx.fillRect(mx - mw, horizY - mh, mw * 2, mh + 4)
		# Mesa top highlight
		ctx.fillStyle = "#3a1e08"
		ctx.fillRect(mx - mw, horizY - mh, mw * 2, 3)
	_hillSilhouette(ctx, W, H, horizY, "#2a1a08")
	_hill2(ctx, W, H, horizY, "#361f08")
	var eg = ctx.createLinearGradient(0, horizY, 0, H)
	eg.addColorStop(0, "#3d2010")
	eg.addColorStop(0.5, "#5a3018")
	eg.addColorStop(1, "#3a2010")
	ctx.fillStyle = eg
	ctx.beginPath()
	ctx.moveTo(0, H)
	for x in range(0, floori(W) + 1):
		var hy = _hillY(x, horizY, H)
		if x == 0:
			ctx.lineTo(0, JS.round(hy))
		else:
			ctx.lineTo(x, JS.round(hy))
	ctx.lineTo(W, H)
	ctx.closePath()
	ctx.fill()
	# Rock texture rows
	for i in range(20):
		var rx = JS.mod((i * 173) + 31, W)
		var ry = JS.round(_hillY(rx, horizY, H)) + (JS.mod((i * 97) + 13, JS.round((H - horizY) * 0.85)))
		var rw = 8 + ((JS.mod(i, 7)) * 3)
		var rh = 3 + (JS.mod(i, 3))
		ctx.fillStyle = ("#6a4020" if (JS.mod(i, 3)) == 0 else ("#4a2c10" if (JS.mod(i, 3)) == 1 else "#5a3818"))
		ctx.fillRect(rx, ry, rw, rh)
		ctx.fillStyle = "#2a1808"
		ctx.fillRect(rx + rw, ry, 2, rh)
		ctx.fillStyle = "#7a5028"
		ctx.fillRect(rx, ry, rw, 1)
	# Stone formation (right side)
	var stX = JS.round(W * 0.75)
	var stY = JS.round(horizY + ((H - horizY) * 0.35))
	for _e17 in JS.iter([[0, 0, 16, 28], [16, 8, 12, 20], [28, 4, 10, 24]]):
		var dx = JS.idx(_e17, 0)
		var dy = JS.idx(_e17, 1)
		var sw = JS.idx(_e17, 2)
		var sh = JS.idx(_e17, 3)
		ctx.fillStyle = "#5a3818"
		ctx.fillRect(stX + dx, stY + dy, sw, sh)
		ctx.fillStyle = "#7a5030"
		ctx.fillRect(stX + dx, stY + dy, sw, 3)
		ctx.fillStyle = "#3a2010"
		ctx.fillRect(((stX + dx) + sw) - 3, stY + dy, 3, sh)
	# Horizon warm glow
	var hg = ctx.createLinearGradient(0, horizY - 12, 0, horizY + 8)
	hg.addColorStop(0, "rgba(140,80,20,0.22)")
	hg.addColorStop(1, "rgba(140,80,20,0)")
	ctx.fillStyle = hg
	ctx.fillRect(0, horizY - 12, W, 20)
	# Sparse scrubby trees
	for i in range(10):
		var tx = JS.round(((JS.mod((i * 211) + 53, 997)) / 997.0) * W)
		var ty = JS.round(_hillY(tx, horizY, H))
		_scrubTree(ctx, tx, ty, 0.4 + ((JS.mod(i, 3)) * 0.15))
	_scrubTree(ctx, JS.round(W * 0.07), JS.round(H * 0.87), 0.9)
	_scrubTree(ctx, JS.round(W * 0.91), JS.round(H * 0.87), 0.85)
	# Cave entrance in cliff
	var caveX = JS.round(W * 0.1)
	var caveY = JS.round(horizY + ((H - horizY) * 0.28))
	var caveW = JS.round(W * 0.07)
	var caveH = JS.round((H - horizY) * 0.12)
	ctx.fillStyle = "#0e0804"
	ctx.beginPath()
	ctx.ellipse(caveX, caveY, caveW / 2.0, caveH / 2.0, 0, PI, PI * 2)
	ctx.fill()
	ctx.fillRect(caveX - JS.round(caveW / 2.0), caveY, caveW, JS.round(caveH / 2.0))
	var caveGlow = ctx.createRadialGradient(caveX, caveY + (caveH * 0.2), 2, caveX, caveY + (caveH * 0.2), caveW * 0.5)
	caveGlow.addColorStop(0, "rgba(120,60,10,0.15)")
	caveGlow.addColorStop(1, "transparent")
	ctx.fillStyle = caveGlow
	ctx.fillRect(caveX - caveW, caveY - JS.round(caveH * 0.3), caveW * 2, JS.round(caveH * 1.3))
	# Rock arch (right side)
	var archX = JS.round(W * 0.62)
	var archY = JS.round(horizY + ((H - horizY) * 0.22))
	var archW = JS.round(W * 0.09)
	var archH = JS.round((H - horizY) * 0.18)
	ctx.fillStyle = "#4a2c10"
	ctx.fillRect(archX, archY, JS.round(archW * 0.18), archH)
	ctx.fillRect(archX + JS.round(archW * 0.82), archY, JS.round(archW * 0.18), archH)
	ctx.fillRect(archX, archY, archW, JS.round(archH * 0.22))
	ctx.fillStyle = "#3a2008"
	ctx.fillRect(archX + JS.round(archW * 0.18), archY + JS.round(archH * 0.22), JS.round(archW * 0.64), JS.round(archH * 0.08))

func _scrubTree(ctx = null, cx = null, baseY = null, sc = null):
	var s = max(1, JS.round(sc * 2))
	ctx.fillStyle = "#3a2010"
	ctx.fillRect(cx - s, baseY - (10 * s), s * 2, 10 * s)
	ctx.fillStyle = "#4a2c0f"
	ctx.fillRect(cx - (3 * s), baseY - (14 * s), 6 * s, 5 * s)
	ctx.fillRect(cx - (2 * s), baseY - (16 * s), 4 * s, 3 * s)
	ctx.fillStyle = "#5a3818"
	ctx.fillRect(cx - (4 * s), baseY - (13 * s), 2 * s, 2 * s)

# ──────────────────────────────────────────────────────────────────────────────
# NATURE ZONE — lush green, waterfall + river, rich forest
# ──────────────────────────────────────────────────────────────────────────────
func _terrainNature(ctx = null, W = null, H = null, horizY = null, tick = null):
	# ── 1. FARTHEST: distant mountain range ──
	_mountains(ctx, W, horizY, ["#04100a", "#061a0c", "#082212"], [11, 37, 79])
	# ── 2. BACKGROUND river — drawn before hills so hills overlap it ──
	# River originates near the horizon (between distant mountains) and flows forward
	var rivStartX = JS.round(W * 0.48)
	var rivStartY = JS.round(horizY + 4)
	var rivEndX = JS.round(W * 0.62)
	var rivEndY = JS.round(horizY + ((H - horizY) * 0.52))
	var rivSteps = 40
	for rs in range(0, floori(rivSteps) + 1):
		var t = rs / float(rivSteps)
		var rx = JS.round((rivStartX + ((rivEndX - rivStartX) * t)) + (sin(((t * PI) * 3) + (tick * 0.001)) * 5))
		var ry = JS.round(rivStartY + ((rivEndY - rivStartY) * t))
		var rw = JS.round(2 + (t * 14))
		var flow = 0.5 + (0.5 * sin((rx * 0.08) + (tick * 0.003)))
		ctx.fillStyle = "rgb(" + JS.s(JS.round(18 + (8 * flow))) + "," + JS.s(JS.round(80 + (35 * flow))) + "," + JS.s(JS.round(130 + (45 * flow))) + ")"
		ctx.fillRect(rx - rw, ry, rw * 2, 3 + JS.round(t * 2))
	# Waterfall from distant cliff — visible in the gap between far and mid hills
	var wfX = JS.round(W * 0.48)
	var wfTopY = JS.round(horizY + 2)
	var wfBotY = JS.round(horizY + ((H - horizY) * 0.18))
	var wy = wfTopY
	while wy < wfBotY:
		var wobble = JS.round(sin((wy * 0.25) + (tick * 0.008)) * 2)
		var alpha = 0.55 + (0.3 * sin((wy * 0.18) + (tick * 0.012)))
		ctx.fillStyle = "rgba(150,210,245," + JS.toFixed(alpha, 2) + ")"
		ctx.fillRect((wfX + wobble) - 2, wy, 5, 2)
		wy += 2
	# Mist at waterfall base
	var mist = ctx.createRadialGradient(wfX, wfBotY, 2, wfX, wfBotY, 14)
	mist.addColorStop(0, "rgba(160,220,255,0.3)")
	mist.addColorStop(1, "rgba(160,220,255,0)")
	ctx.fillStyle = mist
	ctx.beginPath()
	ctx.ellipse(wfX, wfBotY, 14, 6, 0, 0, PI * 2)
	ctx.fill()
	# ── 3. MID hills — overlap the far river ──
	_hillSilhouette(ctx, W, H, horizY, "#061208")
	_hill2(ctx, W, H, horizY, "#0a1e0c")
	# ── 4. FRONT GROUND ──
	var ng = ctx.createLinearGradient(0, horizY, 0, H)
	ng.addColorStop(0, "#1a4010")
	ng.addColorStop(0.5, "#1e4c12")
	ng.addColorStop(1, "#162e0a")
	ctx.fillStyle = ng
	ctx.beginPath()
	ctx.moveTo(0, H)
	for x in range(0, floori(W) + 1):
		var hy = _hillY(x, horizY, H)
		if x == 0:
			ctx.lineTo(0, JS.round(hy))
		else:
			ctx.lineTo(x, JS.round(hy))
	ctx.lineTo(W, H)
	ctx.closePath()
	ctx.fill()
	# ── 5. Ground detail — grass tufts and moss ──
	for i in range(35):
		var gx = JS.mod((i * 197) + 41, W)
		var gy = JS.round(_hillY(gx, horizY, H)) + (JS.mod((i * 97) + 13, JS.round((H - horizY) * 0.75)))
		ctx.fillStyle = ("#2a5a14" if (JS.mod(i, 3)) == 0 else ("#224a10" if (JS.mod(i, 3)) == 1 else "#1a3c0c"))
		ctx.fillRect(gx, gy, 3, 2)
	# Grass blade clusters on ground surface
	for i in range(20):
		var gx = JS.round(((JS.mod((i * 263) + 17, 997)) / 997.0) * W)
		var gy = JS.round(_hillY(gx, horizY, H))
		ctx.fillStyle = "#2a5a14"
		ctx.fillRect(gx, gy - 5, 1, 5)
		ctx.fillRect(gx + 2, gy - 7, 1, 7)
		ctx.fillRect(gx + 4, gy - 4, 1, 4)
	# ── 6. Horizon glow (green mist) ──
	var hg = ctx.createLinearGradient(0, horizY - 14, 0, horizY + 10)
	hg.addColorStop(0, "rgba(20,90,10,0.22)")
	hg.addColorStop(1, "rgba(20,90,10,0)")
	ctx.fillStyle = hg
	ctx.fillRect(0, horizY - 14, W, 24)
	# ── 7. TREES — mid-ground on hill edges, large foreground ──
	# Mid-ground row along hill line (smaller)
	for i in range(18):
		var tx = JS.round(((JS.mod((i * 197) + 41, 997)) / 997.0) * W)
		var ty = JS.round(_hillY(tx, horizY, H))
		(_drawOak if (JS.mod(i, 3)) == 0 else _drawPine).call(ctx, tx, ty, 0.38 + ((JS.mod(i, 4)) * 0.12))
	# Large foreground trees
	_drawPine(ctx, JS.round(W * 0.04), JS.round(H * 0.87), 1.0)
	_drawOak(ctx, JS.round(W * 0.11), JS.round(H * 0.91), 0.85)
	_drawPine(ctx, JS.round(W * 0.18), JS.round(H * 0.89), 0.78)
	_drawOak(ctx, JS.round(W * 0.78), JS.round(H * 0.9), 0.82)
	_drawPine(ctx, JS.round(W * 0.87), JS.round(H * 0.88), 0.92)
	_drawOak(ctx, JS.round(W * 0.94), JS.round(H * 0.91), 0.77)
	# Ground mist layer between tree rows
	var mistG = ctx.createLinearGradient(0, JS.round(horizY + ((H - horizY) * 0.55)), 0, JS.round(horizY + ((H - horizY) * 0.75)))
	mistG.addColorStop(0, "rgba(160,210,190,0.12)")
	mistG.addColorStop(1, "rgba(120,180,160,0)")
	ctx.fillStyle = mistG
	ctx.fillRect(0, JS.round(horizY + ((H - horizY) * 0.55)), W, JS.round((H - horizY) * 0.2))
	# Fern fronds at foreground tree bases
	for _e18 in JS.iter([[W * 0.05, H * 0.91], [W * 0.15, H * 0.93], [W * 0.82, H * 0.91], [W * 0.92, H * 0.93]]):
		var fx = JS.idx(_e18, 0)
		var fy = JS.idx(_e18, 1)
		ctx.strokeStyle = "#1a4a0a"
		ctx.lineWidth = 2
		for fi in range(5):
			var angle = ((fi / 5.0) * PI) - (PI * 0.1)
			var flen = JS.round(W * 0.04)
			ctx.beginPath()
			ctx.moveTo(JS.round(fx), JS.round(fy))
			ctx.lineTo(JS.round(fx + (cos(angle) * flen)), JS.round(fy - ((sin(angle) * flen) * 0.5)))
			ctx.stroke()
	# Mossy stones scattered on ground
	for _e19 in JS.iter([[W * 0.3, H * 0.88], [W * 0.48, H * 0.9], [W * 0.65, H * 0.87]]):
		var sx2 = JS.idx(_e19, 0)
		var sy2 = JS.idx(_e19, 1)
		ctx.fillStyle = "#2a4018"
		ctx.fillRect(JS.round(sx2) - 5, JS.round(sy2) - 3, 10, 6)
		ctx.fillStyle = "#3a5a22"
		ctx.fillRect(JS.round(sx2) - 5, JS.round(sy2) - 3, 10, 2)

# ──────────────────────────────────────────────────────────────────────────────
# PLASMA ZONE — alien purple/magenta ground, glowing crystal spires
# ──────────────────────────────────────────────────────────────────────────────
func _terrainPlasma(ctx = null, W = null, H = null, horizY = null, tick = null):
	# Distant alien crystal mountains
	_mountains(ctx, W, horizY, ["#0e0218", "#180330", "#220440"], [41, 83, 127])
	# Crystal spire glow at peaks
	for i in range(6):
		var mx = JS.round(((JS.mod((i * 197) + 37, 997)) / 997.0) * W)
		var mg = ctx.createRadialGradient(mx, horizY, 1, mx, horizY, 16 + (i * 3))
		mg.addColorStop(0, "rgba(200,100,255,0.2)")
		mg.addColorStop(1, "rgba(150,50,200,0)")
		ctx.fillStyle = mg
		ctx.beginPath()
		ctx.arc(mx, horizY, 16 + (i * 3), 0, PI * 2)
		ctx.fill()
	_hillSilhouette(ctx, W, H, horizY, "#1a0428")
	_hill2(ctx, W, H, horizY, "#200530")
	var pg = ctx.createLinearGradient(0, horizY, 0, H)
	pg.addColorStop(0, "#1e0430")
	pg.addColorStop(0.5, "#280540")
	pg.addColorStop(1, "#180330")
	ctx.fillStyle = pg
	ctx.beginPath()
	ctx.moveTo(0, H)
	for x in range(0, floori(W) + 1):
		var hy = _hillY(x, horizY, H)
		if x == 0:
			ctx.lineTo(0, JS.round(hy))
		else:
			ctx.lineTo(x, JS.round(hy))
	ctx.lineTo(W, H)
	ctx.closePath()
	ctx.fill()
	# Glowing crystal floor veins
	for i in range(12):
		var vx = JS.mod((i * 211) + 37, W)
		var vy = JS.round(_hillY(vx, horizY, H)) + (JS.mod((i * 113) + 19, JS.round((H - horizY) * 0.8)))
		var glow = 0.3 + (0.4 * sin((tick * 0.006) + (i * 1.1)))
		ctx.fillStyle = "rgba(" + JS.s((200 if JS.t(JS.mod(i, 2)) else 150)) + ",40," + JS.s((255 if JS.t(JS.mod(i, 2)) else 200)) + "," + JS.toFixed(glow, 2) + ")"
		ctx.fillRect(vx, vy, 2 + (JS.mod(i, 4)), 1 + (JS.mod(i, 2)))
	# Crystal spires
	for i in range(10):
		var sx = JS.round(((JS.mod((i * 197) + 41, 997)) / 997.0) * W)
		var sy = JS.round(_hillY(sx, horizY, H))
		_crystalSpire(ctx, sx, sy, 0.3 + ((JS.mod(i, 4)) * 0.15), tick, i)
	_crystalSpire(ctx, JS.round(W * 0.07), JS.round(H * 0.86), 0.9, tick, 0)
	_crystalSpire(ctx, JS.round(W * 0.92), JS.round(H * 0.86), 0.85, tick, 1)
	_crystalSpire(ctx, JS.round(W * 0.13), JS.round(H * 0.9), 0.65, tick, 2)
	_crystalSpire(ctx, JS.round(W * 0.86), JS.round(H * 0.9), 0.65, tick, 3)
	# Horizon glow
	var hg = ctx.createLinearGradient(0, horizY - 12, 0, horizY + 8)
	hg.addColorStop(0, "rgba(180,20,220,0.22)")
	hg.addColorStop(1, "rgba(180,20,220,0)")
	ctx.fillStyle = hg
	ctx.fillRect(0, horizY - 12, W, 20)
	# Void ground rifts
	for i in range(6):
		var rfX = JS.round(((JS.mod((i * 197) + 53, 997)) / 997.0) * W)
		var rfY = JS.round(_hillY(rfX, horizY, H)) + JS.round(JS.mod((i * 89) + 11, (H - horizY) * 0.6))
		var rfGlow = 0.4 + (0.4 * sin((tick * 0.006) + (i * 1.3)))
		ctx.fillStyle = "rgba(200,60,255," + JS.toFixed(rfGlow * 0.35, 2) + ")"
		ctx.fillRect(rfX, rfY, 14 + (i * 3), 2)
		ctx.strokeStyle = "rgba(180,40,255," + JS.toFixed(rfGlow, 2) + ")"
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.moveTo(rfX, rfY)
		ctx.lineTo((rfX + 14) + (i * 3), rfY + 3)
		ctx.stroke()
	# Alien stalks with glowing caps
	var _arr21 = JS.iter([[W * 0.22, H * 0.82], [W * 0.55, H * 0.84], [W * 0.78, H * 0.8]])
	for i in range(len(_arr21)):
		var _e20 = _arr21[i]
		var ax2 = JS.idx(_e20, 0)
		var ay2 = JS.idx(_e20, 1)
		var stGlow = 0.5 + (0.4 * sin((tick * 0.004) + (i * 1.5)))
		ctx.fillStyle = "#2a0840"
		ctx.fillRect(JS.round(ax2) - 2, JS.round(ay2) - 14, 4, 14)
		ctx.fillStyle = "rgba(" + JS.s((200 if JS.t(JS.mod(i, 2)) else 140)) + ",40,255," + JS.toFixed(stGlow, 2) + ")"
		ctx.fillRect(JS.round(ax2) - 7, JS.round(ay2) - 18, 14, 5)
		ctx.fillRect(JS.round(ax2) - 5, JS.round(ay2) - 20, 10, 3)
		ctx.fillRect(JS.round(ax2) - 3, JS.round(ay2) - 21, 6, 2)
		var capG = ctx.createRadialGradient(JS.round(ax2), JS.round(ay2) - 16, 0, JS.round(ax2), JS.round(ay2) - 16, 10)
		capG.addColorStop(0, "rgba(200,100,255," + JS.toFixed(stGlow * 0.4, 2) + ")")
		capG.addColorStop(1, "transparent")
		ctx.fillStyle = capG
		ctx.fillRect(JS.round(ax2) - 12, JS.round(ay2) - 24, 24, 16)

func _crystalSpire(ctx = null, cx = null, baseY = null, sc = null, tick = null, seed_ = null):
	var s = max(1, JS.round(sc * 2))
	var h = 14 * s
	var glow = 0.5 + (0.4 * sin((tick * 0.005) + (seed_ * 0.9)))
	# Main spire
	ctx.fillStyle = "rgba(160,40,220," + JS.toFixed(0.7 + (0.2 * glow), 2) + ")"
	for row in range(ceili(h)):
		var w = max(1, JS.round(((1 - (row / float(h))) * 3) * s))
		ctx.fillRect(cx - w, baseY - row, w * 2, 1)
	# Glow
	ctx.fillStyle = "rgba(220,100,255," + JS.toFixed(glow * 0.5, 2) + ")"
	ctx.fillRect(cx - s, baseY - h, s * 2, h)
	# Side facets
	ctx.fillStyle = "rgba(100,20,180,0.8)"
	for row in range(ceili(h)):
		var w = max(1, JS.round(((1 - (row / float(h))) * 3) * s))
		ctx.fillRect((cx + w) - s, baseY - row, s, 1)

# ──────────────────────────────────────────────────────────────────────────────
# AIR ZONE — misty white/gray, floating rock platforms, wispy trees
# ──────────────────────────────────────────────────────────────────────────────
func _terrainAir(ctx = null, W = null, H = null, horizY = null, tick = null):
	# Night sky — full background
	var sky = ctx.createLinearGradient(0, 0, 0, H)
	sky.addColorStop(0, "#03050d")
	sky.addColorStop(0.5, "#07101e")
	sky.addColorStop(1, "#0d1a2e")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, H)
	# Stars
	var seeds = [
		17,
		31,
		53,
		79,
		101,
		127,
		149,
		163,
		193,
		211,
		233,
		251,
		269,
		281,
		307,
		331,
		353,
		373,
		397,
		419,
		443,
		461,
		487,
		503,
		521,
		541,
		557,
		571,
		587,
		601,
		619,
		641,
	]
	var _arr22 = JS.iter(seeds)
	for i in range(len(_arr22)):
		var s = _arr22[i]
		var sx = JS.mod((s * 37) + (i * 83), W)
		var sy = JS.mod((s * 53) + (i * 61), H * 0.88)
		ctx.fillStyle = "rgba(220,230,255," + JS.toFixed(0.35 + ((JS.mod(i, 5)) * 0.12), 2) + ")"
		ctx.fillRect(sx, sy, (2 if (JS.mod(i, 9)) == 0 else 1), (2 if (JS.mod(i, 9)) == 0 else 1))
	# Moon (top-right)
	var mx = JS.round(W * 0.84)
	var my = JS.round(H * 0.1)
	ctx.fillStyle = "#ddeeff"
	ctx.fillRect(mx - 7, my - 7, 14, 14)
	ctx.fillStyle = "#0a1422"
	ctx.fillRect(mx + 2, my - 6, 6, 12)
	# No platforms here — drawn per-node and at player origin
	# Layered cloud formations drifting across sky
	var cloudLayers = [
		{"yf": 0.18, "count": 3, "alpha": 0.08, "speed": 0.04},
		{"yf": 0.3, "count": 4, "alpha": 0.06, "speed": 0.025},
		{"yf": 0.45, "count": 5, "alpha": 0.05, "speed": 0.015},
	]
	for _e23 in JS.iter(cloudLayers):
		var yf = JS.idx(_e23, "yf")
		var count = JS.idx(_e23, "count")
		var alpha = JS.idx(_e23, "alpha")
		var speed = JS.idx(_e23, "speed")
		for ci in range(ceili(count)):
			var cX2 = (JS.mod((tick * speed) + (ci * ((W / float(count)) + 40)), W + 120)) - 60
			var cY2 = JS.round((H * yf) + (sin((tick * 0.003) + ci) * 5))
			var cW3 = 60 + (ci * 20)
			var clg = ctx.createLinearGradient(cX2, cY2, cX2, cY2 + 18)
			clg.addColorStop(0, "rgba(140,170,220," + JS.s(alpha) + ")")
			clg.addColorStop(0.5, "rgba(160,190,240," + JS.toFixed(alpha * 0.7, 2) + ")")
			clg.addColorStop(1, "transparent")
			ctx.fillStyle = clg
			ctx.fillRect(JS.round(cX2), cY2, cW3, 18)
			ctx.fillRect(JS.round(cX2) + 8, cY2 - 7, cW3 - 16, 10)
	# Shooting star (occasional)
	var sStar = JS.mod(tick * 0.001, 1)
	if sStar > 0.85:
		var ssProg = (sStar - 0.85) / 0.15
		var ssX = JS.round((W * 0.1) + ((ssProg * W) * 0.5))
		var ssY = JS.round((H * 0.06) + ((ssProg * H) * 0.08))
		ctx.fillStyle = "rgba(240,245,255," + JS.toFixed(1 - ssProg, 2) + ")"
		ctx.fillRect(ssX, ssY, 4, 1)
		ctx.fillStyle = "rgba(200,215,255," + JS.toFixed((1 - ssProg) * 0.5, 2) + ")"
		ctx.fillRect(ssX + 4, ssY, 6, 1)

func _cloudPlatform(ctx = null, cx = null, cy = null, w = null, h = null, bright = null):
	# Pixel-art cloud: flat bottom bar + uneven bumps on top
	var base = ("#c0d8f4" if JS.t(bright) else "#5a7898")
	var mid = ("#a8c8e8" if JS.t(bright) else "#4a6880")
	var top = ("#e8f4ff" if JS.t(bright) else "#80a8c8")
	var shad = ("rgba(80,120,180,0.18)" if JS.t(bright) else "rgba(10,25,55,0.40)")
	var l = cx - JS.round(w / 2.0)
	var bodyTop = cy + JS.round(h * 0.45)
	var bodyH = JS.round(h * 0.55)
	# Drop shadow
	ctx.fillStyle = shad
	ctx.fillRect(l + 4, (cy + h) + 3, w - 4, 4)
	# Flat bottom body
	ctx.fillStyle = mid
	ctx.fillRect(l, bodyTop, w, bodyH)
	# Bumps — varied widths and heights for organic look
	var bumpDefs = ([
		{"ox": 0.1, "bw": 0.28, "bh": 0.7},
		{"ox": 0.3, "bw": 0.24, "bh": 0.55},
		{"ox": 0.5, "bw": 0.3, "bh": 0.8},
		{"ox": 0.72, "bw": 0.22, "bh": 0.55},
	] if w > 70 else ([
		{"ox": 0.1, "bw": 0.35, "bh": 0.72},
		{"ox": 0.38, "bw": 0.28, "bh": 0.55},
		{"ox": 0.62, "bw": 0.3, "bh": 0.68},
	] if w > 44 else [{"ox": 0.12, "bw": 0.4, "bh": 0.7}, {"ox": 0.52, "bw": 0.36, "bh": 0.55}]))
	for _e24 in JS.iter(bumpDefs):
		var ox = JS.idx(_e24, "ox")
		var bw = JS.idx(_e24, "bw")
		var bh = JS.idx(_e24, "bh")
		var bx = l + JS.round(ox * w)
		var bwPx = JS.round(bw * w)
		var bhPx = JS.round((bh * h) * 0.6)
		var bTop = bodyTop - bhPx
		ctx.fillStyle = base
		ctx.fillRect(bx, bTop + 2, bwPx, (bhPx + bodyH) - 2)
		# Top highlight pixel row
		ctx.fillStyle = top
		ctx.fillRect(bx + 1, bTop, bwPx - 2, 2)
		# Side pixel caps
		ctx.fillStyle = base
		ctx.fillRect(bx - 1, bTop + 2, 1, bhPx - 2)
		ctx.fillRect(bx + bwPx, bTop + 2, 1, bhPx - 2)
	# Top highlight on body edge
	ctx.fillStyle = top
	ctx.fillRect(l + 1, bodyTop, w - 2, 1)

# ──────────────────────────────────────────────────────────────────────────────
# DISPATCHER
# ──────────────────────────────────────────────────────────────────────────────
func _drawTerrain(ctx = null, W = null, H = null, horizY = null, tick = null):
	var el = (State.currentZoneElement if (true and JS.t(State.currentZoneElement)) else State.playerElement)
	match el:
		"Fire":
			_terrainFire(ctx, W, H, horizY, tick)
		"Water":
			_terrainWater(ctx, W, H, horizY, tick)
		"Ice":
			_terrainIce(ctx, W, H, horizY, tick)
		"Lightning":
			_terrainLightning(ctx, W, H, horizY, tick)
		"Earth":
			_terrainEarth(ctx, W, H, horizY, tick)
		"Nature":
			_terrainNature(ctx, W, H, horizY, tick)
		"Plasma":
			_terrainPlasma(ctx, W, H, horizY, tick)
		"Air":
			_terrainAir(ctx, W, H, horizY, tick)
		_:
			_terrainEarth(ctx, W, H, horizY, tick)

# These are still used by Nature zone directly
func _drawFgTrees(ctx = null, W = null, H = null, horizY = null):
	pass

# ── Ground-Hugging Perspective Dirt Road ─────────────────────────────────────
# Static S-curve pixel path from player origin to a node, themed to current zone.
func _drawGroundPath(ctx = null, ox = null, oy = null, nx = null, ny = null, nodeColor = null, W = null, H = null, horizY = null, pathBias = null):
	var cp1x = [null]
	var cp1y = [null]
	var cp2x = [null]
	var cp2y = [null]
	var dist = sqrt((pow(nx - ox, 2)) + (pow(ny - oy, 2)))
	if dist < 2:
		return
	var STEPS = max(48, JS.round(dist / 2.0))
	# Zone-themed path colors
	var el = (State.currentZoneElement if (true and JS.t(State.currentZoneElement)) else "Earth")
	var pathColors = {
		"Fire": {"main": "#5a2a10", "edge": "#8a3a10"},
		"Water": {"main": "#0a2a4a", "edge": "#1a4a7a"},
		"Ice": {"main": "#c8eeff", "edge": "#a0d8f0"},
		"Lightning": {"main": "#2a2a10", "edge": "#6a6a10"},
		"Earth": {"main": "#4a3010", "edge": "#6a4a18"},
		"Nature": {"main": "#1a3a10", "edge": "#2a5a18"},
		"Plasma": {"main": "#2a0a3a", "edge": "#6a1a8a"},
		"Air": {"main": "#a8c0d8", "edge": "#d0e4f4"},
	}
	var col = JS.or_(JS.idx(pathColors, el), pathColors.get("Earth"))
	# Bezier control points — biased by pathBias
	var dx = nx - ox
	var dy = ny - oy
	var px = (-dy) / float(dist)
	var py = dx / float(dist)
	# perpendicular unit vector
	if pathBias == "straight":
		# Dead straight — no swing
		cp1x[0] = ox + (dx * 0.33)
		cp1y[0] = oy + (dy * 0.33)
		cp2x[0] = ox + (dx * 0.67)
		cp2y[0] = oy + (dy * 0.67)
	elif pathBias == "right":
		# Swing hard right (positive perp) — arcs around campfire on the right side
		var swing = min(dist * 0.22, W * 0.14)
		cp1x[0] = (ox + (dx * 0.25)) + (px * (-swing))
		cp1y[0] = (oy + (dy * 0.25)) + (py * (-swing))
		cp2x[0] = (ox + (dx * 0.75)) + (px * (-swing))
		cp2y[0] = (oy + (dy * 0.75)) + (py * (-swing))
	else:
		# Default S-curve
		var swing = min(dist * 0.28, 60)
		cp1x[0] = (ox + (dx * 0.25)) + (px * swing)
		cp1y[0] = (oy + (dy * 0.25)) + (py * swing)
		cp2x[0] = (ox + (dx * 0.75)) - (px * swing)
		cp2y[0] = (oy + (dy * 0.75)) - (py * swing)
	var _fn25 = func(t = null):
		var u = 1 - t
		return {
			"x": JS.round((((((u * u) * u) * ox) + ((((3 * u) * u) * t) * cp1x[0])) + ((((3 * u) * t) * t) * cp2x[0])) + (((t * t) * t) * nx)),
			"y": JS.round((((((u * u) * u) * oy) + ((((3 * u) * u) * t) * cp1y[0])) + ((((3 * u) * t) * t) * cp2y[0])) + (((t * t) * t) * ny)),
		}
	var bez = _fn25
	var pts = []
	for s in range(0, floori(STEPS) + 1):
		pts.append(bez.call(s / float(STEPS)))
	# Shadow
	for s in range(0, floori(STEPS) + 1):
		var _d26 = pts[s]
		var x = JS.idx(_d26, "x")
		var y = JS.idx(_d26, "y")
		var hw = max(3, JS.round(7 - ((s / float(STEPS)) * 4))) + 2
		ctx.fillStyle = "rgba(0,0,0,0.35)"
		ctx.fillRect(x - hw, y + 2, hw * 2, 3)
	# Edge band
	for s in range(0, floori(STEPS) + 1):
		var _d27 = pts[s]
		var x = JS.idx(_d27, "x")
		var y = JS.idx(_d27, "y")
		var hw = max(3, JS.round(7 - ((s / float(STEPS)) * 4))) + 1
		ctx.fillStyle = col.edge
		ctx.fillRect(x - hw, y - 2, hw * 2, 4)
	# Main fill
	for s in range(0, floori(STEPS) + 1):
		var _d28 = pts[s]
		var x = JS.idx(_d28, "x")
		var y = JS.idx(_d28, "y")
		var hw = max(3, JS.round(7 - ((s / float(STEPS)) * 4)))
		ctx.fillStyle = col.main
		ctx.fillRect(x - hw, y - 1, hw * 2, 3)

# Air zone: sparse stepping-stone cloud path
func _drawAirCloudPath(ctx = null, ox = null, oy = null, nx = null, ny = null):
	var dist = sqrt((pow(nx - ox, 2)) + (pow(ny - oy, 2)))
	if dist < 4:
		return
	# Dotted white path — small pixel dots spaced along line
	var dotSpacing = 10
	var numDots = floori(dist / float(dotSpacing))
	var dx = nx - ox
	var dy = ny - oy
	ctx.save()
	for d in range(1, ceili(numDots)):
		var t = d / float(numDots)
		var px = JS.round(ox + (dx * t))
		var py = JS.round(oy + (dy * t))
		var alpha = 0.15 + (0.2 * sin(t * PI))
		# fade at edges
		ctx.globalAlpha = alpha
		ctx.fillStyle = "#c8dff8"
		ctx.fillRect(px - 1, py - 1, 2, 2)
	ctx.restore()

# Air zone: draw a node as a cloud platform with label + enemy sprites on top
func _drawAirCloudNode(ctx = null, node = null, hovered = null, tick = null):
	var x = JS.idx(node, "x")
	var y = JS.idx(node, "y")
	var type_ = JS.idx(node, "type")
	var sprites = JS.idx(node, "sprites")
	var color = JS.idx(node, "color")
	var label = JS.idx(node, "label")
	# Cloud is smaller and positioned so sprites sit on top
	var padW = (80 if JS.t(hovered) else 72)
	var padH = 18
	var cloudY = y + 10
	# cloud sits below node center
	# Hover glow (subtle, behind cloud)
	if JS.t(hovered):
		ctx.save()
		ctx.globalAlpha = 0.18
		ctx.fillStyle = JS.or_(color, "#90c0f0")
		ctx.fillRect((x - (padW / 2.0)) - 6, cloudY - 14, padW + 12, padH + 22)
		ctx.restore()
	# Cloud pad
	_cloudPlatform(ctx, x, cloudY, padW, padH, false)
	# Sprites standing on top of cloud
	if (((type_ == "combat" or type_ == "pack") and JS.t(sprites)) and JS.t(len(sprites))):
		_drawNodeSprites(ctx, x, cloudY - 10, sprites, hovered)
	else:
		_drawNodeIcon(ctx, x, cloudY - 10, node, hovered, tick)
	# Label below cloud
	ctx.save()
	ctx.font = "bold " + JS.s((10 if JS.t(hovered) else 8)) + "px monospace"
	ctx.textAlign = "center"
	ctx.fillStyle = ("#ffe8a0" if JS.t(hovered) else "#90b8d8")
	ctx.globalAlpha = (0.95 if JS.t(hovered) else 0.65)
	ctx.fillText(JS.or_(label, ""), x, (cloudY + padH) + 10)
	ctx.restore()

# ═══ ZONE AMBIENT DETAILS ══════════════════════════════════════════════════════
# Small animated critters, particles, and decorations that bring each zone to life.
func _drawZoneDetails(ctx = null, W = null, H = null, horizY = null, tick = null):
	var el = (State.currentZoneElement if (true and JS.t(State.currentZoneElement)) else State.playerElement)
	var fg = H - horizY
	match el:
		"Fire":
			_zoneDetailFire(ctx, W, H, horizY, fg, tick)
		"Water":
			_zoneDetailWater(ctx, W, H, horizY, fg, tick)
		"Ice":
			_zoneDetailIce(ctx, W, H, horizY, fg, tick)
		"Lightning":
			_zoneDetailLightning(ctx, W, H, horizY, fg, tick)
		"Earth":
			_zoneDetailEarth(ctx, W, H, horizY, fg, tick)
		"Nature":
			_zoneDetailNature(ctx, W, H, horizY, fg, tick)
		"Plasma":
			_zoneDetailPlasma(ctx, W, H, horizY, fg, tick)
		"Air":
			_zoneDetailAir(ctx, W, H, horizY, fg, tick)

func _zoneDetailFire(ctx = null, W = null, H = null, horizY = null, fg = null, tick = null):
	# Floating embers
	for i in range(14):
		var phase = JS.mod((tick * 0.0007) + (i * 0.52), 1)
		var ex = (JS.mod((i * 211) + 37, W)) + JS.round(sin((tick * 0.001) + i) * 8)
		var ey = JS.round(H - ((phase * fg) * 0.85))
		var alpha = sin(phase * PI)
		if alpha < 0.05:
			continue
		ctx.fillStyle = "rgba(255," + JS.s(JS.round(80 + (120 * (1 - phase)))) + ",0," + JS.toFixed(alpha * 0.9, 2) + ")"
		ctx.fillRect(ex, ey, (3 if (JS.mod(i, 3)) == 0 else 2), (3 if (JS.mod(i, 3)) == 0 else 2))
	# Fire skull rocks (decorative)
	for _e29 in JS.iter([[W * 0.18, H * 0.8], [W * 0.72, H * 0.82]]):
		var sx = JS.idx(_e29, 0)
		var sy = JS.idx(_e29, 1)
		ctx.fillStyle = "#1a0804"
		ctx.fillRect(JS.round(sx) - 5, JS.round(sy) - 4, 10, 8)
		ctx.fillStyle = "#cc3300"
		ctx.fillRect(JS.round(sx) - 2, JS.round(sy) - 2, 2, 2)
		ctx.fillRect(JS.round(sx) + 1, JS.round(sy) - 2, 2, 2)
	# Smoke wisps from lava river
	for i in range(5):
		var sx = JS.round(W * (0.2 + (i * 0.15)))
		var sy = JS.round(H * 0.59)
		var phase = JS.mod((tick * 0.0005) + (i * 0.4), 1)
		var alpha = sin(phase * PI) * 0.25
		var drift = JS.round(sin((tick * 0.001) + i) * 4)
		ctx.fillStyle = "rgba(80,30,10," + JS.toFixed(alpha, 2) + ")"
		ctx.fillRect(sx + drift, sy - JS.round(phase * 28), 4, 6)
	# Volcanic rocks scattered in foreground
	for _e30 in JS.iter([[W * 0.38, H * 0.87], [W * 0.58, H * 0.91], [W * 0.25, H * 0.84]]):
		var rx = JS.idx(_e30, 0)
		var ry = JS.idx(_e30, 1)
		ctx.fillStyle = "#1c0806"
		ctx.fillRect(JS.round(rx) - 6, JS.round(ry) - 3, 12, 6)
		ctx.fillStyle = "#2a0c08"
		ctx.fillRect(JS.round(rx) - 6, JS.round(ry) - 3, 12, 2)
		ctx.fillStyle = "#cc3300"
		ctx.fillRect(JS.round(rx) - 2, JS.round(ry), 4, 1)
	# Lava geyser (periodic eruption)
	var geyserX = JS.round(W * 0.58)
	var geyserPhase = JS.mod(tick * 0.0005, 1)
	if geyserPhase < 0.15:
		var eruptA = sin((geyserPhase / 0.15) * PI)
		var gH = JS.round((H * 0.08) * eruptA)
		var gBase = JS.round(H * 0.65)
		ctx.fillStyle = "rgba(255,80,0," + JS.toFixed(0.6 * eruptA, 2) + ")"
		ctx.fillRect(geyserX - 3, gBase - gH, 6, gH)
		ctx.fillRect(geyserX - 5, gBase - gH, 10, 3)
		var gg = ctx.createRadialGradient(geyserX, gBase - gH, 0, geyserX, gBase - gH, 14)
		gg.addColorStop(0, "rgba(255,120,0," + JS.toFixed(0.4 * eruptA, 2) + ")")
		gg.addColorStop(1, "transparent")
		ctx.fillStyle = gg
		ctx.fillRect(geyserX - 16, (gBase - gH) - 16, 32, 32)

func _zoneDetailWater(ctx = null, W = null, H = null, horizY = null, fg = null, tick = null):
	# Seagulls (simple pixel Vs)
	var gullSeeds = [0.25, 0.52, 0.71, 0.38]
	var _arr31 = JS.iter(gullSeeds)
	for i in range(len(_arr31)):
		var seed_ = _arr31[i]
		var gx = JS.round((W * seed_) + (sin((tick * 0.0004) + i) * 12))
		var gy = JS.round((horizY * (0.3 + (seed_ * 0.25))) + (sin((tick * 0.0008) + (i * 1.3)) * 6))
		ctx.fillStyle = "rgba(200,215,235,0.8)"
		ctx.fillRect(gx - 3, gy, 2, 1)
		ctx.fillRect(gx - 1, gy - 1, 2, 1)
		ctx.fillRect(gx + 1, gy, 2, 1)
	# Starfish on beach
	for _e32 in JS.iter([[W * 0.35, H * 0.8], [W * 0.55, H * 0.81], [W * 0.68, H * 0.79]]):
		var sx = JS.idx(_e32, 0)
		var sy = JS.idx(_e32, 1)
		ctx.fillStyle = "#cc7730"
		ctx.fillRect(JS.round(sx) - 1, JS.round(sy) - 3, 2, 6)
		ctx.fillRect(JS.round(sx) - 3, JS.round(sy) - 1, 6, 2)
	# Crab near shore
	var crabX = JS.round((W * 0.44) + (sin(tick * 0.0006) * 10))
	var crabY = JS.round(H * 0.84)
	ctx.fillStyle = "#cc3311"
	ctx.fillRect(crabX - 3, crabY - 2, 6, 4)
	ctx.fillRect(crabX - 5, crabY - 1, 2, 2)
	ctx.fillRect(crabX + 3, crabY - 1, 2, 2)
	ctx.fillStyle = "#000"
	ctx.fillRect(crabX - 2, crabY - 2, 1, 1)
	ctx.fillRect(crabX + 1, crabY - 2, 1, 1)
	# Bubbles rising from ocean
	for i in range(6):
		var bx = JS.round(W * (0.05 + (i * 0.16)))
		var phase = JS.mod((tick * 0.0006) + (i * 0.35), 1)
		var by = JS.round(H * (0.88 - (phase * 0.12)))
		ctx.fillStyle = "rgba(160,210,240," + JS.toFixed(0.5 - (phase * 0.4), 2) + ")"
		ctx.fillRect(bx, by, 2, 2)
	# Treasure chest half-buried in sand
	ctx.fillStyle = "#8a5a20"
	ctx.fillRect(JS.round(W * 0.62), JS.round(H * 0.82), 10, 7)
	ctx.fillStyle = "#c8901c"
	ctx.fillRect(JS.round(W * 0.62), JS.round(H * 0.82), 10, 3)
	ctx.fillStyle = "#f0c040"
	ctx.fillRect(JS.round(W * 0.66), JS.round(H * 0.84), 3, 2)
	# Jellyfish in ocean
	for i in range(3):
		var jx = JS.round((W * (0.15 + (i * 0.28))) + (sin((tick * 0.0005) + (i * 1.2)) * 8))
		var jy = JS.round(H * (0.87 + (sin((((tick * 0.0004) + (i * 0.5)) * PI) * 2) * 0.02)))
		var jAlpha = 0.35 + (0.2 * sin((tick * 0.003) + i))
		ctx.fillStyle = "rgba(180,120,255," + JS.toFixed(jAlpha, 2) + ")"
		ctx.beginPath()
		ctx.ellipse(jx, jy, 6, 4, 0, PI, PI * 2)
		ctx.fill()
		for t2 in range(4):
			ctx.fillStyle = "rgba(200,140,255," + JS.toFixed(jAlpha * 0.6, 2) + ")"
			ctx.fillRect((jx - 4) + (t2 * 3), jy, 1, 4 + JS.round(sin((tick * 0.002) + t2) * 2))

func _zoneDetailIce(ctx = null, W = null, H = null, horizY = null, fg = null, tick = null):
	# Snowflakes drifting
	for i in range(18):
		var phase = JS.mod((tick * 0.0004) + (i * 0.31), 1)
		var sx = (JS.mod((i * 211) + 37, W)) + JS.round(sin((tick * 0.0008) + i) * 6)
		var sy = JS.round(H * phase)
		var alpha = 0.5 + (0.4 * sin(phase * PI))
		ctx.fillStyle = "rgba(220,240,255," + JS.toFixed(alpha, 2) + ")"
		var size = (3 if (JS.mod(i, 4)) == 0 else 2)
		ctx.fillRect(sx, sy, size, size)
		# Crosshair flake arms
		if (JS.mod(i, 5)) == 0:
			ctx.fillRect(sx - 1, sy + 1, size + 2, 1)
			ctx.fillRect(sx + 1, sy - 1, 1, size + 2)
	# Polar bear (simple pixel blob)
	var bearX = JS.round((W * 0.62) + (sin(tick * 0.0002) * 5))
	var bearY = JS.round(H * 0.75)
	ctx.fillStyle = "#d8eeff"
	ctx.fillRect(bearX, bearY - 4, 12, 8)
	# body
	ctx.fillRect(bearX + 10, bearY - 7, 6, 6)
	# head
	ctx.fillStyle = "#000"
	ctx.fillRect(bearX + 13, bearY - 6, 1, 1)
	# eye
	ctx.fillStyle = "#c0d8f0"
	ctx.fillRect(bearX, bearY + 4, 3, 3)
	ctx.fillRect(bearX + 4, bearY + 4, 3, 3)
	# front legs
	ctx.fillRect(bearX + 7, bearY + 4, 3, 3)
	ctx.fillRect(bearX + 10, bearY + 4, 3, 3)
	# rear legs
	# Penguin
	var penX = JS.round(W * 0.32)
	var penY = JS.round(H * 0.77)
	ctx.fillStyle = "#111"
	ctx.fillRect(penX - 2, penY - 6, 6, 10)
	ctx.fillStyle = "#eee"
	ctx.fillRect(penX - 1, penY - 4, 4, 6)
	ctx.fillStyle = "#f80"
	ctx.fillRect(penX, penY + 4, 2, 2)
	ctx.fillStyle = "#111"
	ctx.fillRect(penX - 1, penY - 5, 2, 2)
	# Frozen treasure under ice
	ctx.fillStyle = "rgba(120,190,230,0.5)"
	ctx.fillRect(JS.round(W * 0.48), JS.round(H * 0.83), 14, 6)
	ctx.fillStyle = "rgba(240,200,40,0.5)"
	ctx.fillRect(JS.round(W * 0.5), JS.round(H * 0.84), 6, 4)
	# Wind-driven snow drift streaks
	for i in range(8):
		var dPhase = JS.mod((tick * 0.0005) + (i * 0.145), 1)
		var dx2 = JS.round((dPhase * (W + 60)) - 30)
		var dy2 = JS.round((H * (0.65 + (JS.mod(i * 0.04, 0.2)))) + (sin((dPhase * PI) * 4) * 4))
		var dAlpha = sin(dPhase * PI) * 0.2
		ctx.fillStyle = "rgba(220,240,255," + JS.toFixed(dAlpha, 2) + ")"
		ctx.fillRect(dx2, dy2, 8 + (i * 2), 1)
	# Ice crystal clusters
	for _e33 in JS.iter([[W * 0.2, H * 0.84], [W * 0.68, H * 0.82]]):
		var icx2 = JS.idx(_e33, 0)
		var icy2 = JS.idx(_e33, 1)
		for c in range(5):
			var cH2 = 4 + (c * 3)
			var cX3 = (JS.round(icx2) - 6) + (c * 3)
			ctx.fillStyle = "rgba(160,220,255," + JS.toFixed(0.5 + (c * 0.08), 2) + ")"
			for row in range(ceili(cH2)):
				var cw = max(1, JS.round((1 - (row / float(cH2))) * 2))
				ctx.fillRect(cX3 - cw, JS.round(icy2) - row, cw * 2, 1)

func _zoneDetailLightning(ctx = null, W = null, H = null, horizY = null, fg = null, tick = null):
	# Small spark particles
	for i in range(10):
		var phase = JS.mod((tick * 0.0009) + (i * 0.27), 1)
		var sx = (JS.mod((i * 197) + 41, W)) + JS.round(sin((tick * 0.001) + i) * 5)
		var sy = JS.round(H * (0.55 + (phase * 0.38)))
		var alpha = sin(phase * PI)
		if alpha < 0.1:
			continue
		ctx.fillStyle = "rgba(" + JS.s(200 + JS.round(55 * alpha)) + "," + JS.s(160 + JS.round(80 * alpha)) + ",40," + JS.toFixed(alpha, 2) + ")"
		ctx.fillRect(sx, sy, 2, 2)
	# Broken stone pillar (left)
	var px = JS.round(W * 0.2)
	var py = JS.round(H * 0.64)
	ctx.fillStyle = "#1c1830"
	ctx.fillRect(px - 5, py, 10, H - py)
	ctx.fillStyle = "#2a2448"
	ctx.fillRect(px - 5, py, 10, 3)
	ctx.fillStyle = "#1c1830"
	ctx.fillRect(px - 6, py - 4, 12, 5)
	# broken top
	ctx.fillStyle = "#2a2448"
	ctx.fillRect(px - 6, py - 4, 12, 2)
	# Second pillar (right, taller)
	var px2 = JS.round(W * 0.78)
	var py2 = JS.round(H * 0.58)
	ctx.fillStyle = "#1c1830"
	ctx.fillRect(px2 - 4, py2, 8, H - py2)
	ctx.fillStyle = "#2a2448"
	ctx.fillRect(px2 - 4, py2, 8, 3)
	ctx.fillRect(px2 - 5, py2 - 6, 10, 7)
	ctx.fillStyle = "#2a2448"
	ctx.fillRect(px2 - 5, py2 - 6, 10, 2)
	# Glowing storm orb (ambient)
	var orbX = JS.round(W * 0.5)
	var orbY = JS.round((horizY * 0.4) + (sin(tick * 0.001) * 8))
	var orbGlow = 0.3 + (0.2 * sin(tick * 0.003))
	ctx.fillStyle = "rgba(200,180,255," + JS.toFixed(orbGlow, 2) + ")"
	ctx.fillRect(orbX - 3, orbY - 3, 6, 6)
	ctx.fillStyle = "rgba(255,240,100," + JS.toFixed(orbGlow * 0.6, 2) + ")"
	ctx.fillRect(orbX - 1, orbY - 1, 2, 2)
	# Lightning-struck tree stump
	var stX = JS.round(W * 0.41)
	var stY = JS.round(H * 0.8)
	ctx.fillStyle = "#100c20"
	ctx.fillRect(stX - 4, stY - 8, 8, 12)
	ctx.fillStyle = "#1a1630"
	ctx.fillRect(stX - 4, stY - 8, 8, 2)
	if (JS.mod(tick, 900)) < 100:
		ctx.fillStyle = "rgba(220,200,60,0.7)"
		ctx.fillRect(stX - 1, stY - 9, 2, 2)
	# Rain streaks over battlefield
	for i in range(20):
		var rPhase2 = JS.mod((tick * 0.0012) + (i * 0.13), 1)
		var rx3 = JS.mod((i * 211) + 57, W)
		var ry3 = JS.round(((rPhase2 * H) * 1.1) - (H * 0.05))
		var rA = sin(rPhase2 * PI) * 0.18
		if rA < 0.02:
			continue
		ctx.fillStyle = "rgba(140,160,220," + JS.toFixed(rA, 2) + ")"
		ctx.fillRect(rx3, ry3, 1, 5)
	# Ground electric tendril (low arc on floor)
	var arcTick2 = JS.mod(tick * 0.0015, 1)
	if arcTick2 < 0.08:
		var baseY3 = JS.round(H * 0.76)
		var arcFade = 1 - (arcTick2 / 0.08)
		ctx.strokeStyle = "rgba(220,200,60," + JS.toFixed(0.5 * arcFade, 2) + ")"
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.moveTo(JS.round(W * 0.38), baseY3)
		for s in range(5):
			ctx.lineTo(JS.round((W * 0.38) + (s * 10)), baseY3 - JS.round(JS.mod((s * 97) + 13, 5)))
		ctx.stroke()

func _zoneDetailEarth(ctx = null, W = null, H = null, horizY = null, fg = null, tick = null):
	# Glowing mushrooms
	var mushPos = [[W * 0.22, H * 0.82], [W * 0.46, H * 0.85], [W * 0.68, H * 0.8], [W * 0.32, H * 0.79]]
	var _arr35 = JS.iter(mushPos)
	for i in range(len(_arr35)):
		var _e34 = _arr35[i]
		var mx = JS.idx(_e34, 0)
		var my = JS.idx(_e34, 1)
		var glow = 0.4 + (0.3 * sin((tick * 0.004) + (i * 1.1)))
		ctx.fillStyle = "#3a2010"
		ctx.fillRect(JS.round(mx) - 1, JS.round(my) - 4, 2, 5)
		ctx.fillStyle = "rgba(" + JS.s((80 if JS.t(JS.mod(i, 2)) else 160)) + "," + JS.s((200 if JS.t(JS.mod(i, 2)) else 80)) + "," + JS.s((60 if JS.t(JS.mod(i, 2)) else 200)) + "," + JS.toFixed(0.7 + (0.2 * glow), 2) + ")"
		ctx.fillRect(JS.round(mx) - 4, JS.round(my) - 7, 8, 4)
		ctx.fillRect(JS.round(mx) - 3, JS.round(my) - 8, 6, 2)
		ctx.fillStyle = "rgba(255,255,255," + JS.toFixed(glow * 0.4, 2) + ")"
		ctx.fillRect(JS.round(mx) - 2, JS.round(my) - 8, 2, 2)
	# Butterfly
	var bfx = JS.round((W * 0.5) + (sin(tick * 0.001) * 20))
	var bfy = JS.round((H * 0.72) + (sin(tick * 0.0015) * 8))
	var bfFlap = sin(tick * 0.012) > 0
	ctx.fillStyle = "rgba(200,140,40,0.8)"
	if bfFlap:
		ctx.fillRect(bfx - 5, bfy - 2, 4, 4)
		ctx.fillRect(bfx + 1, bfy - 2, 4, 4)
	else:
		ctx.fillRect(bfx - 4, bfy - 1, 3, 3)
		ctx.fillRect(bfx + 1, bfy - 1, 3, 3)
	ctx.fillStyle = "#1a0a04"
	ctx.fillRect(bfx - 1, bfy - 3, 2, 6)
	# Ancient ruins wall segment
	var rwX = JS.round(W * 0.15)
	var rwY = JS.round(H * 0.75)
	for b in range(3):
		ctx.fillStyle = ("#5a3818" if (JS.mod(b, 2)) == 0 else "#4a2c10")
		ctx.fillRect(rwX, rwY + (b * 5), 24, 4)
		ctx.fillStyle = "#3a2008"
		ctx.fillRect(rwX, (rwY + (b * 5)) + 3, 24, 1)
		ctx.fillStyle = "#6a4828"
		ctx.fillRect(rwX, rwY + (b * 5), 24, 1)
	# Earthworm
	var ewX = JS.round(W * 0.6)
	var ewY = JS.round(H * 0.88)
	ctx.fillStyle = "#8a5030"
	for s in range(4):
		var sx = ewX + (s * 4)
		var sy = ewY + JS.round(sin((tick * 0.003) + s) * 2)
		ctx.fillRect(sx, sy, 4, 3)
	# Scorpion
	var scX = JS.round((W * 0.74) + (sin(tick * 0.0004) * 8))
	var scY = JS.round(H * 0.84)
	ctx.fillStyle = "#5a3010"
	ctx.fillRect(scX - 4, scY - 3, 8, 5)
	ctx.fillRect(scX - 6, scY - 2, 3, 2)
	ctx.fillRect(scX + 3, scY - 2, 3, 2)
	ctx.fillStyle = "#7a4018"
	ctx.fillRect(scX + 4, scY - 3, 2, 2)
	ctx.fillRect(scX + 6, scY - 5, 2, 2)
	ctx.fillRect(scX + 7, scY - 7, 2, 2)
	ctx.fillStyle = "#cc8830"
	ctx.fillRect(scX + 8, scY - 8, 2, 2)
	# Tumbleweed rolling across
	var twPhase = JS.mod(tick * 0.0004, 1)
	var twX = JS.round((twPhase * (W + 30)) - 15)
	var twY = JS.round((H * 0.8) + (sin((twPhase * PI) * 8) * 3))
	ctx.strokeStyle = "rgba(120,80,30,0.5)"
	ctx.lineWidth = 1
	ctx.beginPath()
	ctx.arc(twX, twY, 6, 0, PI * 2)
	ctx.stroke()
	ctx.beginPath()
	ctx.moveTo(twX - 5, twY - 3)
	ctx.lineTo(twX + 5, twY + 3)
	ctx.stroke()
	ctx.beginPath()
	ctx.moveTo(twX + 5, twY - 3)
	ctx.lineTo(twX - 5, twY + 3)
	ctx.stroke()

func _zoneDetailNature(ctx = null, W = null, H = null, horizY = null, fg = null, tick = null):
	# Fireflies
	for i in range(8):
		var fx = (JS.mod((i * 211) + 37, W)) + JS.round(sin((tick * 0.001) + (i * 0.7)) * 12)
		var fy = JS.round((H * (0.55 + (sin((tick * 0.0008) + (i * 1.1)) * 0.08))) + (fg * (0.1 + (i * 0.05))))
		var glow = 0.4 + (0.55 * sin((tick * 0.007) + (i * 1.3)))
		if glow > 0.5:
			ctx.fillStyle = "rgba(180,255,80," + JS.toFixed(glow * 0.8, 2) + ")"
			ctx.fillRect(fx, fy, 2, 2)
	# Deer (left side)
	var deerX = JS.round((W * 0.14) + (sin(tick * 0.0003) * 6))
	var deerY = JS.round(H * 0.75)
	ctx.fillStyle = "#8a5020"
	ctx.fillRect(deerX, deerY - 10, 12, 8)
	# body
	ctx.fillRect(deerX + 10, deerY - 14, 5, 6)
	# neck+head
	ctx.fillStyle = "#000"
	ctx.fillRect(deerX + 13, deerY - 13, 1, 1)
	# eye
	ctx.fillStyle = "#8a5020"
	ctx.fillRect(deerX + 1, deerY - 2, 2, 6)
	ctx.fillRect(deerX + 4, deerY - 2, 2, 6)
	# front legs
	ctx.fillRect(deerX + 7, deerY - 2, 2, 6)
	ctx.fillRect(deerX + 10, deerY - 2, 2, 6)
	# back legs
	# Antlers
	ctx.fillStyle = "#7a4818"
	ctx.fillRect(deerX + 11, deerY - 18, 1, 5)
	ctx.fillRect(deerX + 9, deerY - 17, 2, 1)
	ctx.fillRect(deerX + 12, deerY - 16, 2, 1)
	# Fish jumping in river
	var fishPhase = JS.mod(tick * 0.002, PI * 2)
	if sin(fishPhase) > 0:
		var fx2 = JS.round(W * 0.47)
		var fy2 = JS.round((H * 0.6) - (sin(fishPhase) * 14))
		ctx.fillStyle = "#2a7aaa"
		ctx.fillRect(fx2, fy2, 8, 4)
		ctx.fillRect(fx2 - 3, fy2 + 1, 3, 3)
		# tail
		ctx.fillStyle = "rgba(200,240,255,0.4)"
		ctx.fillRect(fx2, fy2 - 1, 8, 2)
	# shimmer
	# Flower patch
	var _arr37 = JS.iter([[W * 0.3, H * 0.84], [W * 0.34, H * 0.86], [W * 0.28, H * 0.85]])
	for i in range(len(_arr37)):
		var _e36 = _arr37[i]
		var flx = JS.idx(_e36, 0)
		var fly = JS.idx(_e36, 1)
		ctx.fillStyle = JS.idx(["#ff6688", "#ffcc00", "#aa66ff"], i)
		ctx.fillRect(JS.round(flx) - 2, JS.round(fly) - 4, 4, 4)
		ctx.fillStyle = "#ffff00"
		ctx.fillRect(JS.round(flx) - 1, JS.round(fly) - 3, 2, 2)
		ctx.fillStyle = "#2a6a10"
		ctx.fillRect(JS.round(flx), JS.round(fly), 2, 5)
	# Waterfall mist cloud at base
	var wfMistX = JS.round(W * 0.22)
	var wfMistY = JS.round(H * 0.6)
	var mAlpha = 0.12 + (0.06 * sin(tick * 0.004))
	ctx.fillStyle = "rgba(200,235,255," + JS.toFixed(mAlpha, 2) + ")"
	ctx.beginPath()
	ctx.ellipse(wfMistX, wfMistY, 16, 6, 0, 0, PI * 2)
	ctx.fill()
	# Frog on mossy stone
	var frogX = JS.round((W * 0.52) + (sin(tick * 0.0005) * 4))
	var frogY = JS.round(H * 0.82)
	ctx.fillStyle = "#3a8a20"
	ctx.fillRect(frogX - 4, frogY - 4, 8, 5)
	ctx.fillRect(frogX - 5, frogY - 5, 10, 2)
	ctx.fillStyle = "#88dd44"
	ctx.fillRect(frogX - 4, frogY - 6, 3, 3)
	ctx.fillRect(frogX + 1, frogY - 6, 3, 3)
	ctx.fillStyle = "#000"
	ctx.fillRect(frogX - 3, frogY - 5, 1, 1)
	ctx.fillRect(frogX + 2, frogY - 5, 1, 1)
	ctx.fillStyle = "#2a7018"
	ctx.fillRect(frogX - 6, frogY, 3, 2)
	ctx.fillRect(frogX + 3, frogY, 3, 2)
	# Butterfly near flower patch
	var bfPhase2 = JS.mod(tick * 0.0008, PI * 2)
	var bfx2 = JS.round((W * 0.33) + (cos(bfPhase2) * 12))
	var bfy2 = JS.round((H * 0.8) + (sin(bfPhase2 * 0.5) * 6))
	ctx.fillStyle = "rgba(255,100,200,0.85)"
	if sin(tick * 0.015) > 0:
		ctx.fillRect(bfx2 - 5, bfy2 - 2, 4, 4)
		ctx.fillRect(bfx2 + 1, bfy2 - 2, 4, 4)
	else:
		ctx.fillRect(bfx2 - 3, bfy2 - 1, 3, 3)
		ctx.fillRect(bfx2, bfy2 - 1, 3, 3)
	ctx.fillStyle = "#1a0a04"
	ctx.fillRect(bfx2 - 1, bfy2 - 3, 2, 6)

func _zoneDetailPlasma(ctx = null, W = null, H = null, horizY = null, fg = null, tick = null):
	# Orbiting energy motes
	for i in range(6):
		var angle = ((tick * 0.001) * (1 + (i * 0.2))) + (i * 1.05)
		var orbitX = JS.round((W * 0.5) + (cos(angle) * (W * 0.3)))
		var orbitY = JS.round((H * 0.65) + ((sin(angle * 0.6) * fg) * 0.15))
		var glow = 0.4 + (0.4 * sin((tick * 0.007) + i))
		ctx.fillStyle = "rgba(" + JS.s((200 if JS.t(JS.mod(i, 2)) else 140)) + ",40,255," + JS.toFixed(glow, 2) + ")"
		ctx.fillRect(orbitX, orbitY, 3, 3)
		# Trail
		for t2 in range(1, 4):
			var ta = angle - (t2 * 0.12)
			var tx2 = JS.round((W * 0.5) + (cos(ta) * (W * 0.3)))
			var ty2 = JS.round((H * 0.65) + ((sin(ta * 0.6) * fg) * 0.15))
			ctx.fillStyle = "rgba(" + JS.s((180 if JS.t(JS.mod(i, 2)) else 120)) + ",20,220," + JS.toFixed(glow * (1 - (t2 / 4.0)), 2) + ")"
			ctx.fillRect(tx2, ty2, 2, 2)
	# Phase rifts (shimmering portals)
	var _arr39 = JS.iter([[W * 0.18, H * 0.72], [W * 0.78, H * 0.7]])
	for i in range(len(_arr39)):
		var _e38 = _arr39[i]
		var rx = JS.idx(_e38, 0)
		var ry = JS.idx(_e38, 1)
		var glow = 0.3 + (0.3 * sin((tick * 0.003) + (i * 1.6)))
		ctx.strokeStyle = "rgba(200,80,255," + JS.toFixed(glow, 2) + ")"
		ctx.lineWidth = 2
		ctx.beginPath()
		ctx.ellipse(JS.round(rx), JS.round(ry), 8, 14, 0.2, 0, PI * 2)
		ctx.stroke()
		ctx.fillStyle = "rgba(160,20,220," + JS.toFixed(glow * 0.3, 2) + ")"
		ctx.beginPath()
		ctx.ellipse(JS.round(rx), JS.round(ry), 6, 11, 0.2, 0, PI * 2)
		ctx.fill()
	# Floating glyphs
	for i in range(4):
		var gx = JS.round((W * (0.22 + (i * 0.2))) + (sin((tick * 0.001) + i) * 5))
		var gy = JS.round((H * 0.75) + (cos((tick * 0.0008) + (i * 1.2)) * 8))
		var gAlpha = 0.3 + (0.3 * sin((tick * 0.005) + (i * 0.9)))
		ctx.fillStyle = "rgba(220,180,255," + JS.toFixed(gAlpha, 2) + ")"
		ctx.font = "8px monospace"
		ctx.textAlign = "center"
		ctx.fillText(["✦", "◈", "⬡", "◉"][i], gx, gy)
	ctx.textAlign = "left"
	# Void tentacles rising from ground
	var _arr41 = JS.iter([[W * 0.3, H * 0.88], [W * 0.62, H * 0.86]])
	for ti in range(len(_arr41)):
		var _e40 = _arr41[ti]
		var tx3 = JS.idx(_e40, 0)
		var ty3 = JS.idx(_e40, 1)
		for s in range(8):
			var sY = JS.round(ty3 - (s * 5))
			var sX = JS.round(tx3 + (sin(((tick * 0.003) + (s * 0.7)) + (ti * 2.1)) * (s * 2)))
			var tAlpha = (1 - (s / 8.0)) * (0.4 + (0.3 * sin((tick * 0.005) + ti)))
			ctx.fillStyle = "rgba(140,20,220," + JS.toFixed(tAlpha, 2) + ")"
			ctx.fillRect(sX, sY, max(1, 3 - JS.round(s / 4.0)), 5)
	# Crystal growth from floor
	var _arr43 = JS.iter([[W * 0.44, H * 0.9], [W * 0.56, H * 0.88]])
	for ci in range(len(_arr43)):
		var _e42 = _arr43[ci]
		var cx3 = JS.idx(_e42, 0)
		var cy3 = JS.idx(_e42, 1)
		for c in range(4):
			var cH3 = 6 + (c * 4)
			var cX4 = (JS.round(cx3) - 4) + (c * 3)
			var cGlow2 = 0.5 + (0.4 * sin(((tick * 0.006) + c) + (ci * 1.8)))
			ctx.fillStyle = "rgba(" + JS.s((180 if JS.t(JS.mod(ci, 2)) else 140)) + ",60,255," + JS.toFixed(cGlow2, 2) + ")"
			for row in range(ceili(cH3)):
				var cw2 = max(1, JS.round((1 - (row / float(cH3))) * 2))
				ctx.fillRect(cX4, JS.round(cy3) - row, cw2 * 2, 1)

func _zoneDetailAir(ctx = null, W = null, H = null, horizY = null, fg = null, tick = null):
	# Birds high in the sky
	var flockY = JS.round(horizY * 0.28)
	var _arr45 = JS.iter([[0, 0], [22, -4], [44, -2], [66, -5], [88, -1], [-22, -3]])
	for i in range(len(_arr45)):
		var _e44 = _arr45[i]
		var bx = JS.idx(_e44, 0)
		var by = JS.idx(_e44, 1)
		var bxr = JS.round(JS.mod(((W * 0.35) + bx) + (tick * 0.018), W))
		var flap = sin((tick * 0.012) + (i * 0.8)) > 0
		ctx.fillStyle = "rgba(80,120,180,0.6)"
		if flap:
			ctx.fillRect(bxr - 4, flockY + by, 3, 1)
			ctx.fillRect(bxr + 1, (flockY + by) - 1, 3, 1)
		else:
			ctx.fillRect(bxr - 4, (flockY + by) - 1, 3, 1)
			ctx.fillRect(bxr + 1, (flockY + by) - 1, 3, 1)
	# Wisps of cloud drifting off the sides
	for i in range(5):
		var phase = JS.mod((tick * 0.0003) + (i * 0.22), 1)
		var wy = JS.round(horizY + (fg * (0.05 + (JS.mod(i * 0.13, 0.3)))))
		var wx = JS.round((phase * (W + 80)) - 40)
		var ww = 40 + (JS.mod(i * 23, 50))
		var alpha = (0.15 + (0.1 * sin(phase * PI))) * (1 - (abs(0.5 - phase) * 1.5))
		if alpha < 0.02:
			continue
		ctx.fillStyle = "rgba(220,235,255," + JS.toFixed(alpha, 2) + ")"
		ctx.fillRect(wx, wy, ww, 8)
		ctx.fillRect(wx + 6, wy - 4, ww - 12, 5)
	# Sun rays from top-right corner
	ctx.save()
	for r in range(5):
		var rayAlpha = 0.04 + (r * 0.01)
		ctx.fillStyle = "rgba(255,245,200," + JS.s(rayAlpha) + ")"
		var rx = W - (r * 18)
		ctx.beginPath()
		# thin triangle ray
		ctx.moveTo(rx, 0)
		ctx.lineTo(rx - 60, H * 0.6)
		ctx.lineTo(rx - 50, H * 0.6)
		ctx.closePath()
		ctx.fill()
	ctx.restore()
	# Eagle/hawk soaring alone below the flock
	var hawkAngle = tick * 0.0006
	var hawkX = JS.round((W * 0.5) + ((cos(hawkAngle) * W) * 0.3))
	var hawkY = JS.round((H * 0.38) + ((sin(hawkAngle * 0.4) * H) * 0.06))
	ctx.fillStyle = "rgba(100,120,160,0.55)"
	ctx.fillRect(hawkX - 7, hawkY, 6, 2)
	ctx.fillRect(hawkX + 1, hawkY - 1, 6, 2)
	ctx.fillRect(hawkX - 1, hawkY - 2, 2, 3)
	# Shooting star (periodic)
	var ssPhase2 = JS.mod(tick * 0.0007, 1)
	if ssPhase2 > 0.88:
		var ssProg2 = (ssPhase2 - 0.88) / 0.12
		var ssX2 = JS.round((W * 0.15) + ((ssProg2 * W) * 0.45))
		var ssY2 = JS.round((H * 0.05) + ((ssProg2 * H) * 0.1))
		ctx.fillStyle = "rgba(240,245,255," + JS.toFixed(1 - ssProg2, 2) + ")"
		ctx.fillRect(ssX2, ssY2, 4, 1)
		ctx.fillStyle = "rgba(200,215,255," + JS.toFixed((1 - ssProg2) * 0.5, 2) + ")"
		ctx.fillRect(ssX2 + 4, ssY2, 7, 1)

func _drawWorldCampfire(ctx = null, cx = null, cy = null, hovered = null, tick = null):
	var ps = 3
	# pixel scale
	# Update/spawn sparks
	if len(_cfSparks) < 18:
		for i in range(3):
			_cfSparks.append({
				"x": cx + ((randf() - 0.5) * 8),
				"y": cy - (ps * 4),
				"vx": (randf() - 0.5) * 0.6,
				"vy": -(0.5 + (randf() * 1.0)),
				"life": 1.0,
				"col": ("#FF8800" if randf() > 0.5 else "#FFCC00"),
			})
	for i in range(len(_cfSparks) - 1, 0 - 1, -1):
		var sp = _cfSparks[i]
		sp.x += sp.vx
		sp.y += sp.vy
		sp.vy *= 0.97
		sp.life -= 0.025
		if sp.life <= 0:
			JS.splice(_cfSparks, i, 1)
			continue
		ctx.save()
		ctx.globalAlpha = sp.life * 0.8
		ctx.fillStyle = sp.col
		ctx.fillRect(JS.round(sp.x), JS.round(sp.y), ps - 1, ps - 1)
		ctx.restore()
	# Warm glow underneath
	var glowR = (60 if JS.t(hovered) else 50) + (8 * sin(tick * 0.006))
	ctx.save()
	ctx.globalAlpha = (0.25 if JS.t(hovered) else 0.16)
	var grd = ctx.createRadialGradient(cx, cy, 0, cx, cy, glowR)
	grd.addColorStop(0, "#FF9900")
	grd.addColorStop(0.4, "#FF550044")
	grd.addColorStop(1, "transparent")
	ctx.fillStyle = grd
	ctx.fillRect(cx - glowR, cy - glowR, glowR * 2, glowR * 2)
	ctx.restore()
	# Logs (two crossed pixel logs)
	var logC = ["#3d1f08", "#5a2d0c", "#7a3d10"]
	# Left log
	for i in range(4):
		ctx.fillStyle = JS.idx(logC, min(i, 2))
		ctx.fillRect((cx - (6 * ps)) + i, (cy - ps) + (i * 0), ps * 4, ps)
	# Right log
	for i in range(4):
		ctx.fillStyle = JS.idx(logC, min(i, 2))
		ctx.fillRect((cx + ps) - i, cy - ps, ps * 4, ps)
	# Ember glow on logs
	ctx.save()
	ctx.globalAlpha = 0.6 + (0.3 * sin(tick * 0.011))
	ctx.fillStyle = "#FF4400"
	ctx.fillRect(cx - ps, cy - ps, ps * 2, ps)
	ctx.restore()
	# Animated flame — 3 frames cycling
	var frame = JS.mod(floori(tick / 80.0), 3)
	var FLAMES = [
		[
			[0, (-8) * ps, 2 * ps, 3 * ps, "#FFEE22"],
			[-ps, (-7) * ps, 4 * ps, 3 * ps, "#FF9900"],
			[(-2) * ps, (-5) * ps, 6 * ps, 3 * ps, "#FF5500"],
			[(-3) * ps, (-3) * ps, 8 * ps, 2 * ps, "#FF3300"],
			[-ps, (-9) * ps, 2 * ps, 2 * ps, "#FFFF88"],
		],
		[
			[-ps, (-9) * ps, 2 * ps, 3 * ps, "#FFFF44"],
			[(-2) * ps, (-7) * ps, 5 * ps, 3 * ps, "#FFAA00"],
			[(-3) * ps, (-5) * ps, 7 * ps, 3 * ps, "#FF6600"],
			[(-3) * ps, (-3) * ps, 7 * ps, 2 * ps, "#FF3300"],
			[0, (-10) * ps, ps, 2 * ps, "#FFFFAA"],
		],
		[
			[0, (-7) * ps, 3 * ps, 3 * ps, "#FFEE00"],
			[(-2) * ps, (-6) * ps, 6 * ps, 3 * ps, "#FF8800"],
			[(-3) * ps, (-4) * ps, 8 * ps, 3 * ps, "#FF4400"],
			[(-2) * ps, (-3) * ps, 6 * ps, 2 * ps, "#FF2200"],
			[-ps, (-8) * ps, 3 * ps, 2 * ps, "#FFFFCC"],
		],
	]
	# frame 0
	# frame 1
	# frame 2
	for _e46 in JS.iter(JS.idx(FLAMES, frame)):
		var dx = JS.idx(_e46, 0)
		var dy = JS.idx(_e46, 1)
		var fw = JS.idx(_e46, 2)
		var fh = JS.idx(_e46, 3)
		var col = JS.idx(_e46, 4)
		ctx.fillStyle = col
		ctx.fillRect(cx + dx, cy + dy, fw, fh)
	# Smoke wisps (rise, fade, drift)
	var smokeT = JS.mod(tick * 0.0008, 1)
	for i in range(3):
		var ot = JS.mod(smokeT + (i * 0.33), 1)
		var sx = cx + (sin(((ot * PI) * 3) + i) * 6)
		var sy = (cy - (12 * ps)) - (ot * 28)
		ctx.save()
		ctx.globalAlpha = (1 - ot) * 0.12
		ctx.fillStyle = "#9988bb"
		ctx.fillRect(JS.round(sx - 3), JS.round(sy - 3), 6, 6)
		ctx.restore()
	# Label
	ctx.save()
	ctx.font = "bold " + JS.s((11 if JS.t(hovered) else 9)) + "px monospace"
	ctx.textAlign = "center"
	ctx.fillStyle = "#ffbb55"
	ctx.globalAlpha = (0.95 if JS.t(hovered) else 0.7)
	ctx.fillText("REST", cx, (cy + (ps * 3)) + 8)
	ctx.restore()

# Zone-themed campfire dispatcher
func _drawZoneCampfire(ctx = null, cx = null, cy = null, hovered = null, tick = null):
	var el = JS.or_(State.currentZoneElement, "Fire")
	match el:
		"Fire":
			_cfFire(ctx, cx, cy, hovered, tick)
		"Water":
			_cfWater(ctx, cx, cy, hovered, tick)
		"Ice":
			_cfIce(ctx, cx, cy, hovered, tick)
		"Lightning":
			_cfLightning(ctx, cx, cy, hovered, tick)
		"Earth":
			_cfEarth(ctx, cx, cy, hovered, tick)
		"Nature":
			_cfNature(ctx, cx, cy, hovered, tick)
		"Plasma":
			_cfPlasma(ctx, cx, cy, hovered, tick)
		"Air":
			_cfAir(ctx, cx, cy, hovered, tick)
		_:
			_drawWorldCampfire(ctx, cx, cy, hovered, tick)

# Shared: draw animated glow + label
func _cfGlow(ctx = null, cx = null, cy = null, col = null, hovered = null, tick = null, radius = null):
	var r = (JS.or_(radius, 44)) + (6 * sin(tick * 0.007))
	ctx.save()
	ctx.globalAlpha = (0.22 if JS.t(hovered) else 0.13)
	var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, r)
	g.addColorStop(0, col)
	g.addColorStop(1, "transparent")
	ctx.fillStyle = g
	ctx.fillRect(cx - r, cy - r, r * 2, r * 2)
	ctx.restore()

func _cfLabel(ctx = null, cx = null, cy = null, text = null, col = null, hovered = null):
	ctx.save()
	ctx.font = "bold " + JS.s((11 if JS.t(hovered) else 9)) + "px monospace"
	ctx.textAlign = "center"
	ctx.fillStyle = JS.or_(col, "#ffbb55")
	ctx.globalAlpha = (0.95 if JS.t(hovered) else 0.7)
	ctx.fillText(text, cx, cy + 28)
	ctx.restore()

# Shared: pixel logs
func _cfLogs(ctx = null, cx = null, cy = null, col1 = null, col2 = null):
	var ps = 3
	ctx.fillStyle = col1
	ctx.fillRect(cx - (5 * ps), cy - ps, ps * 4, ps)
	ctx.fillStyle = col2
	ctx.fillRect(cx + ps, cy - ps, ps * 4, ps)

func _cfSparks2(ctx = null, cx = null, cy = null, tick = null, cols = null, key = null):
	if not JS.t(JS.idx(_cfSparkPools, key)):
		_cfSparkPools[key] = []
	var pool = JS.idx(_cfSparkPools, key)
	if len(pool) < 14:
		for i in range(2):
			pool.append({
				"x": cx + ((randf() - 0.5) * 7),
				"y": cy - 9,
				"vx": (randf() - 0.5) * 0.7,
				"vy": -(0.6 + (randf() * 1.1)),
				"life": 1,
				"col": JS.idx(cols, floori(randf() * len(cols))),
			})
	for i in range(len(pool) - 1, 0 - 1, -1):
		var s = pool[i]
		s.x += s.vx
		s.y += s.vy
		s.vy *= 0.97
		s.life -= 0.028
		if s.life <= 0:
			JS.splice(pool, i, 1)
			continue
		ctx.save()
		ctx.globalAlpha = s.life * 0.85
		ctx.fillStyle = s.col
		ctx.fillRect(JS.round(s.x), JS.round(s.y), 2, 2)
		ctx.restore()

# Shared: animated flame column
func _cfFlame(ctx = null, cx = null, cy = null, tick = null, palFn = null):
	# Same pixel template as _drawWorldCampfire FLAMES (ps=3), recolored by palFn
	var ps = 3
	var frame = JS.mod(floori(tick / 80.0), 3)
	var TEMPLATES = [
		[[0, -8, 2, 3, 0], [-1, -7, 4, 3, 1], [-2, -5, 6, 3, 2], [-3, -3, 8, 2, 3], [-1, -9, 2, 2, 4]],
		[[-1, -9, 2, 3, 4], [-2, -7, 5, 3, 1], [-3, -5, 7, 3, 2], [-3, -3, 7, 2, 3], [0, -10, 1, 2, 4]],
		[[0, -7, 3, 3, 0], [-2, -6, 6, 3, 1], [-3, -4, 8, 3, 2], [-2, -3, 6, 2, 3], [-1, -8, 3, 2, 4]],
	]
	# frame 0
	# frame 1
	# frame 2
	for _e47 in JS.iter(JS.idx(TEMPLATES, frame)):
		var dx = JS.idx(_e47, 0)
		var dy = JS.idx(_e47, 1)
		var fw = JS.idx(_e47, 2)
		var fh = JS.idx(_e47, 3)
		var ci = JS.idx(_e47, 4)
		ctx.fillStyle = palFn.call(ci)
		ctx.fillRect(cx + (dx * ps), cy + (dy * ps), fw * ps, fh * ps)

func _cfZonePal(zone = null):
	var p = JS.or_(JS.idx(CF_PALS, zone), CF_PALS.get("Fire"))
	return func(i = null): return JS.or_(JS.idx(p, i), JS.idx(p, 0))

# Shared zone campfire renderer — same animation, zone-tinted colors
func _cfDrawZone(ctx = null, cx = null, cy = null, hovered = null, tick = null, zone = null):
	var pal = JS.or_(JS.idx(CF_PALS, zone), CF_PALS.get("Fire"))
	var glowC = JS.idx(pal, 2)
	var ps = 3
	# Glow
	_cfGlow(ctx, cx, cy, glowC, hovered, tick, 44)
	# Logs (Air: wind swirl instead)
	if zone == "Air":
		var wt = JS.mod(tick * 0.003, 1)
		for i in range(3):
			var ox = sin(((wt * PI) * 2) + (i * 2.1)) * 8
			ctx.save()
			ctx.globalAlpha = 0.3 - (i * 0.07)
			ctx.fillStyle = JS.idx(pal, 1)
			ctx.fillRect(JS.round((cx - 12) + ox), (cy - 3) + (i * 2), 24, 1)
			ctx.restore()
	else:
		var log1 = ("#0a1a2a" if zone == "Ice" else ("#0a2030" if zone == "Water" else ("#1a1a00" if zone == "Lightning" else ("#1a0a2a" if zone == "Plasma" else "#3d1f08"))))
		var log2 = ("#1a3a4a" if zone == "Ice" else ("#1a4050" if zone == "Water" else ("#333300" if zone == "Lightning" else ("#2a1a3a" if zone == "Plasma" else "#5a2d0c"))))
		_cfLogs(ctx, cx, cy, log1, log2)
	# Sparks
	_cfSparks2(ctx, cx, cy, tick, [JS.idx(pal, 0), JS.idx(pal, 1), JS.idx(pal, 4)], zone)
	# Flame using shared template
	_cfFlame(ctx, cx, cy, tick, _cfZonePal(zone))
	# Label
	_cfLabel(ctx, cx, cy + 6, "REST", JS.idx(pal, 1), hovered)

func _cfFire(ctx = null, cx = null, cy = null, hovered = null, tick = null):
	_cfDrawZone(ctx, cx, cy, hovered, tick, "Fire")

func _cfWater(ctx = null, cx = null, cy = null, hovered = null, tick = null):
	_cfDrawZone(ctx, cx, cy, hovered, tick, "Water")

func _cfIce(ctx = null, cx = null, cy = null, hovered = null, tick = null):
	_cfDrawZone(ctx, cx, cy, hovered, tick, "Ice")

func _cfLightning(ctx = null, cx = null, cy = null, hovered = null, tick = null):
	_cfDrawZone(ctx, cx, cy, hovered, tick, "Lightning")

func _cfEarth(ctx = null, cx = null, cy = null, hovered = null, tick = null):
	_cfDrawZone(ctx, cx, cy, hovered, tick, "Earth")

func _cfNature(ctx = null, cx = null, cy = null, hovered = null, tick = null):
	_cfDrawZone(ctx, cx, cy, hovered, tick, "Nature")

func _cfPlasma(ctx = null, cx = null, cy = null, hovered = null, tick = null):
	_cfDrawZone(ctx, cx, cy, hovered, tick, "Plasma")

func _cfAir(ctx = null, cx = null, cy = null, hovered = null, tick = null):
	_cfDrawZone(ctx, cx, cy, hovered, tick, "Air")

func _drawNodeSprites(ctx = null, cx = null, cy = null, sprites = null, hovered = null, node = null):
	if (not JS.t(sprites) or len(sprites) == 0):
		return
	# Map nodes always draw as wizard hats — small, clear icons
	var scale_ = 3
	var hatCols = 12
	var hatW = hatCols * scale_
	var isPack = (node.get("type") == "pack" if JS.t(node) else node)
	var count = (3 if JS.t(isPack) else 1)
	# Pick element from node or first sprite
	var elem = (JS.or_(JS.or_(node.enc.get("element"), JS.g(JS.idx(JS.g(JS.g(node, "enc"), "members"), 0), "element")), "Fire") if (JS.t(node) and JS.t(node.get("enc"))) else "Fire")
	var hatRows = Sprites.getElemHatSprite(elem)
	var hatH = len(hatRows) * scale_
	var pal = (JS.g(JS.idx(sprites, 0), "pal") if JS.t(JS.g(JS.idx(sprites, 0), "pal")) else Sprites.getElemPal(elem))
	if count == 1:
		var sx = JS.round(cx - (hatW / 2.0))
		var sy = JS.round(cy - (hatH / 2.0))
		ctx.save()
		ctx.globalAlpha = (1.0 if JS.t(hovered) else 0.88)
		Sprites.drawSprite(ctx, hatRows, sx, sy, scale_, pal, hatCols)
		ctx.restore()
	else:
		# Pack: 3 hats — left smaller, center largest, right smaller
		var sizes = [2.4, 3, 2.4]
		var xOffs = [(-hatW) * 0.8, 0, hatW * 0.8]
		var yOffs = [4, 0, 4]
		var alphas = ([0.9, 1.0, 0.9] if JS.t(hovered) else [0.7, 0.88, 0.7])
		for i in range(3):
			var s = sizes[i]
			var hw = JS.round(hatCols * s)
			var hh = JS.round(len(hatRows) * s)
			var sx = JS.round((cx + xOffs[i]) - (hw / 2.0))
			var sy = JS.round((cy + yOffs[i]) - (hh / 2.0))
			ctx.save()
			ctx.globalAlpha = alphas[i]
			Sprites.drawSprite(ctx, hatRows, sx, sy, s, pal, hatCols)
			ctx.restore()

func _drawNodeIcon(ctx = null, cx = null, cy = null, node = null, hovered = null, tick = null):
	var type_ = JS.idx(node, "type")
	var color = JS.idx(node, "color")
	var scale_ = 2
	var cols = 24
	var baseRows = null
	var pal = null
	if type_ == "campfire":
		# Warm fire palette: 1=log-dark 2=log-mid 3=ember 4=core-flame
		baseRows = MAP_SPRITE_CAMPFIRE_BASE
		pal = ["#5a3010", "#8a5020", "#FF8822", "#FFDD00", "#FF4400"]
		var spriteW = cols * scale_
		var spriteH = len(baseRows) * scale_
		var sx = JS.round(cx - (spriteW / 2.0))
		var sy = JS.round(cy - (spriteH / 2.0))
		# Warm glow behind fire
		var glowR = 18 + (3 * sin(tick * 0.07))
		ctx.save()
		ctx.globalAlpha = (0.22 if JS.t(hovered) else 0.12)
		var grd = ctx.createRadialGradient(cx, sy - 4, 0, cx, sy - 4, glowR)
		grd.addColorStop(0, "#FF8822")
		grd.addColorStop(1, "transparent")
		ctx.fillStyle = grd
		ctx.fillRect(cx - glowR, (sy - glowR) - 4, glowR * 2, glowR * 2)
		ctx.restore()
		# Draw log base
		ctx.save()
		ctx.globalAlpha = (1 if JS.t(hovered) else 0.88)
		Sprites.drawSprite(ctx, baseRows, sx, sy, scale_, pal)
		ctx.restore()
		# Animated flame — shift palette based on tick
		var flameShift = JS.mod(floori(tick / 4.0), 3)
		var flamePals = [
			["#FF6600", "#FF9900", "#FFCC00", "#FF3300", "#FF0000"],
			["#FF4400", "#FF8800", "#FFAA00", "#FF2200", "#EE0000"],
			["#FF7700", "#FFAA00", "#FFDD00", "#FF4400", "#FF1100"],
		]
		var flameP = JS.idx(flamePals, flameShift)
		# Flame sits above the base — offset upward
		var flameOffY = (sy - (len(MAP_SPRITE_CAMPFIRE_FLAME) * scale_)) + (scale_ * 2)
		ctx.save()
		ctx.globalAlpha = (1 if JS.t(hovered) else 0.9)
		Sprites.drawSprite(ctx, MAP_SPRITE_CAMPFIRE_FLAME, sx, flameOffY, scale_, flameP)
		ctx.restore()
	elif type_ == "shop":
		# Shop: 1=canvas/fabric 2=counter-wood 3=highlight 4=shadow
		baseRows = MAP_SPRITE_SHOP
		pal = ["#2aaa7a", "#1a6a4a", "#55ddaa", "#0a3a2a"]
		var spriteW = cols * scale_
		var spriteH = len(baseRows) * scale_
		var sx = JS.round(cx - (spriteW / 2.0))
		var sy = JS.round(cy - (spriteH / 2.0))
		ctx.save()
		ctx.globalAlpha = (1 if JS.t(hovered) else 0.85)
		Sprites.drawSprite(ctx, baseRows, sx, sy, scale_, pal)
		ctx.restore()
		# Hanging sign twinkle
		if sin(tick * 0.05) > 0.7:
			ctx.save()
			ctx.globalAlpha = 0.6
			ctx.fillStyle = "#FFEE44"
			ctx.fillRect(cx - 2, (cy - (spriteH / 2.0)) - 5, 2, 2)
			ctx.restore()
	elif type_ == "gym":
		# Gym: 1=stone 2=column-shadow 3=gold-trim
		baseRows = MAP_SPRITE_GYM
		pal = [color, "#6a5020", "#FFD700", "#3a2808"]
		var spriteW = cols * scale_
		var spriteH = len(baseRows) * scale_
		var sx = JS.round(cx - (spriteW / 2.0))
		var sy = JS.round(cy - (spriteH / 2.0))
		ctx.save()
		ctx.globalAlpha = (1 if JS.t(hovered) else 0.85)
		Sprites.drawSprite(ctx, baseRows, sx, sy, scale_, pal)
		ctx.restore()
		# Pulsing gold banner at top
		var pulse = 0.5 + (0.5 * sin(tick * 0.05))
		ctx.save()
		ctx.globalAlpha = 0.3 + (0.2 * pulse)
		ctx.fillStyle = "#FFD700"
		ctx.fillRect(sx, sy - 3, spriteW, 2)
		ctx.restore()

# ─── Animated player on map ───────────────────────────────────────────────────
func _drawMapPlayer(ctx = null, px = null, py = null, tick = null):
	var scale_ = 2
	var rows = Sprites.getPlayerCharSprite()
	var pal = Sprites.getElemPal(State.playerElement)
	var spriteW = 24 * scale_
	var spriteH = len(rows) * scale_
	# Bob up/down while moving
	var bobY = (JS.round(sin(tick * 0.09) * 2) if JS.t(_mapAnimTarget) else 0)
	# Shadow
	ctx.save()
	ctx.globalAlpha = 0.25
	ctx.fillStyle = "#000"
	ctx.beginPath()
	ctx.ellipse(px, (py + (spriteH / 2.0)) + 2, spriteW * 0.3, 3, 0, 0, PI * 2)
	ctx.fill()
	ctx.restore()
	# Sprite
	ctx.save()
	ctx.globalAlpha = 1.0
	Sprites.drawSprite(ctx, rows, JS.round(px - (spriteW / 2.0)), JS.round((py - (spriteH / 2.0)) + bobY), scale_, pal, 24)
	ctx.restore()
	# "YOU" label
	ctx.save()
	ctx.font = "bold 8px monospace"
	ctx.textAlign = "center"
	ctx.fillStyle = "#c8a060"
	ctx.globalAlpha = 0.8
	ctx.fillText("YOU", px, ((py - (spriteH / 2.0)) - 4) + bobY)
	ctx.restore()
