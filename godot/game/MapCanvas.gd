# MapCanvas — generated from js/rendering/mapCanvas.js by tools/js2gd.js
extends Node

var _znMapTimer = null
var _znWizardRaf = null
var _znWizardX = 0
var _znWizardY = 0
# ── Zone special scheduling ────────────────────────────────────────────────
# 2 shops + 2 campfires per zone, in two pairs:
# Mid pair  — slots 7–10, after the rival window
# End pair  — slots 11–13, once the gym is showing (guaranteed if gym is skipped)
var _zoneShopMid = -1
var _zoneCampfireMid = -1
var _zoneShopEnd = -1
var _zoneCampfireEnd = -1
var _MAP_REWARD_CFG = null
# ===== ZONE MAP GRAPH SYSTEM =====
var ZN_TIERS = 15
# total tiers: tier 1 = start (bottom), tier 15 = gym (top)
var ZN_COLS = 4
# max columns (0-3)
var ZN_TIER_H = 130
# px per tier (used for canvas height only)
var ZN_PAD = 40
# bottom padding in stage
var ZN_SKY_FRAC = 0.13

func _boot():
	# ── Encounter cards ────────────────────────────────────────────────────────────
	_MAP_REWARD_CFG = {
		"primary_spell": {
			"iconType": "arcane",
			"label": "Starting Spell",
			"color": "#c080ff",
			"sub": "#7050b0",
			"anim": "mapSpellGlow 2.2s ease-in-out infinite",
		},
		"spell": {
			"iconType": "tome",
			"label": "Spell Reward",
			"color": "#a080ff",
			"sub": "#6040a0",
			"anim": "mapSpellGlow 2.8s ease-in-out infinite",
		},
		"incantation": {
			"iconType": "scroll",
			"label": "Incantation",
			"color": "#e08030",
			"sub": "#905020",
			"anim": "mapScrollFloat 2.6s ease-in-out infinite",
		},
		"minor": {
			"iconType": "gem",
			"label": "Pick Up",
			"color": "#c8a060",
			"sub": "#887040",
			"anim": "mapPickupFloat 2.6s ease-in-out infinite",
		},
		"major": {
			"iconType": "star",
			"label": "Power Up",
			"color": "#e8d060",
			"sub": "#a08040",
			"anim": "mapPowerPulse 2.2s ease-in-out infinite",
		},
	}

# ===== mapCanvas.js =====
# ─── MAP SCREEN — encounter selection, zone specials, canvas node rendering ───
func showMap():
	# If all gyms beaten and gauntlet hasn't loaded yet, redirect into gauntlet
	if (JS.t(State.gymDefeated) and Encounters._gauntletBossIdx < len(Encounters.GAUNTLET_ROSTER)):
		JS.setTimeout(BattleLoad._loadGauntletBoss, 400)
		return
	var _gymDef = Encounters.currentGymDef()
	State._setZoneElement((_gymDef.get("element") if (JS.t(_gymDef) and JS.t(_gymDef.get("element"))) else State.playerElement))
	# ── Sandbox zone switcher ──
	var sandboxBar = document.getElementById("sandbox-zone-bar")
	if JS.t(sandboxBar):
		if JS.t(Constants.sandboxMode):
			sandboxBar.style.display = "flex"
			sandboxBar.innerHTML = "<span style=\"color:#888;font-size:.6rem;align-self:center;margin-right:4px;\">ZONE:</span>"
			var _arr1 = JS.iter(JS.or_(Encounters.GYM_ROSTER, []))
			for i in range(len(_arr1)):
				var gym = _arr1[i]
				var btn = document.createElement("button")
				btn.textContent = JS.s(gym.get("emoji")) + " " + JS.s(gym.get("element"))
				btn.style.cssText = "background:" + (JS.s(gym.get("color")) + "33" if JS.eq(i, State.currentGymIdx) else "#111") + ";border:1px solid " + JS.s((gym.get("color") if JS.eq(i, State.currentGymIdx) else "#333")) + ";color:" + JS.s((gym.get("color") if JS.eq(i, State.currentGymIdx) else "#888")) + ";border-radius:4px;padding:2px 7px;font-size:.58rem;font-family:'Cinzel',serif;cursor:pointer;"
				var _fn2 = func():
					State.currentGymIdx = i
					State.gymDefeated = false
					State.zoneBattleCount = 0
					State._zoneGraph = null
					State._playerNodeId = -1
					State._completedNodeIds = JSSet.new()
					State._pendingNodeId = -1
					State._zoneIntroPlayed = false
					State._setZoneElement(gym.get("element"))
					showMap()
				btn.onclick = _fn2
				sandboxBar.appendChild(btn)
		else:
			sandboxBar.style.display = "none"
	# ── HP bar ──
	var pMax = Helpers.maxHPFor("player")
	var pPct = max(0, (State.player.get("hp") / float(pMax)) * 100)
	document.getElementById("map-player-hp").textContent = "HP " + JS.s(State.player.get("hp")) + "/" + JS.s(pMax)
	var bar = document.getElementById("map-hp-bar")
	bar.style.width = JS.s(pPct) + "%"
	bar.style.background = UI.hpColor(pPct)
	# ── Lives ──
	var livesEl = document.getElementById("map-lives-inline")
	if JS.t(livesEl):
		livesEl.textContent = "❤".repeat(max(0, State.player.get("revives")))
	# ── Gold ──
	var goldEl = document.getElementById("map-gold-inline")
	if JS.t(goldEl):
		goldEl.textContent = "💰 " + JS.s(State.player.get("gold")) + "g"
	# ── Stats strip (ATK / EFX / DEF) ──
	var statsStrip = document.getElementById("map-stats-strip")
	if JS.t(statsStrip):
		var atk = JS.or_(State.player.get("attackPower"), 0)
		var efx = JS.or_(State.player.get("effectPower"), 0)
		var def = JS.or_(State.player.get("defense"), 0)
		var chips = []
		if atk != 0:
			chips.append("<span class=\"map-stat-chip\" style=\"color:#e07050;\">⚔ <b>" + ("+" if atk > 0 else "") + JS.s(atk) + "</b> ATK</span>")
		if efx != 0:
			chips.append("<span class=\"map-stat-chip\" style=\"color:#8080e0;\">✦ <b>" + ("+" if efx > 0 else "") + JS.s(efx) + "</b> EFX</span>")
		if def != 0:
			chips.append("<span class=\"map-stat-chip\" style=\"color:#50a0e0;\">🛡 <b>" + ("+" if def > 0 else "") + JS.s(def) + "</b> DEF</span>")
		statsStrip.innerHTML = (JS.join(chips, "<span style=\"color:#2a2040;font-size:.55rem;\"> · </span>") if JS.t(len(chips)) else "")
		statsStrip.style.display = ("flex" if JS.t(len(chips)) else "none")
	# ── Zone pill ──
	var gym = Encounters.currentGymDef()
	var zonePill = document.getElementById("map-zone-label")
	if JS.t(zonePill):
		if JS.t(State.gymDefeated):
			zonePill.textContent = "✦ Champion"
			zonePill.style.borderColor = "#5a4aaa"
			zonePill.style.color = "#9a7aff"
		elif JS.t(gym):
			zonePill.textContent = "Zone " + JS.s(State.currentGymIdx + 1) + " · " + JS.s(gym.get("element")) + " · Battle " + JS.s(State.zoneBattleCount)
			zonePill.style.borderColor = JS.s(gym.get("color")) + "55"
			zonePill.style.color = gym.get("color")
	# ── Gym warning banner (compressed) ──
	var banner = document.getElementById("gym-warning-banner")
	if (JS.t(gym) and not JS.t(State.gymDefeated)):
		var remaining = Constants.GYM_ZONE_FORCE - State.zoneBattleCount
		if Helpers.gymIsForced():
			banner.innerHTML = "⚠ " + JS.s(gym.get("name")) + " — FORCED FIGHT"
			banner.style.cssText = "display:block;background:#1a0a0a;border-color:#6a1a1a;color:#aa4444;border-radius:6px;padding:.35rem .7rem;font-size:.65rem;text-align:center;width:100%;max-width:640px;"
		elif (Helpers.gymShouldAppear() and remaining <= 3):
			banner.innerHTML = "⚠ " + JS.s(gym.get("name")) + " — " + JS.s(remaining) + " battle" + ("" if remaining == 1 else "s") + " until forced"
			banner.style.cssText = "display:block;background:#1a0a0a;border-color:#6a1a1a;color:#aa4444;border-radius:6px;padding:.35rem .7rem;font-size:.65rem;text-align:center;width:100%;max-width:640px;"
		elif Helpers.gymShouldAppear():
			banner.innerHTML = "🏛 " + JS.s(gym.get("name")) + " is ready"
			banner.style.cssText = "display:block;background:" + JS.s(gym.get("color")) + "11;border-color:" + JS.s(gym.get("color")) + "44;color:" + JS.s(gym.get("color")) + ";border-radius:6px;padding:.35rem .7rem;font-size:.65rem;text-align:center;width:100%;max-width:640px;"
		else:
			banner.style.display = "none"
	elif JS.t(State.gymDefeated):
		banner.innerHTML = "✦ All 8 Gym Leaders defeated."
		banner.style.cssText = "display:block;background:#0a0820;border-color:#4a3a8a;color:#9a7aff;border-radius:6px;padding:.35rem .7rem;font-size:.65rem;text-align:center;width:100%;max-width:640px;"
	else:
		banner.style.display = "none"
	UI.showScreen("map-screen")
	UI.updateStatsUI()
	# ── Advance player after returning from an encounter ──
	if State._pendingNodeId >= 0:
		State._playerNodeId = State._pendingNodeId
		State._completedNodeIds.add(State._pendingNodeId)
		State._pendingNodeId = -1
	# ── Generate zone graph if entering zone for first time ──
	if not JS.t(State._zoneGraph):
		generateZoneGraph()
	# ── Safety: if player is stranded on the gym node (no successors), reset ──
	if (JS.t(State._zoneGraph) and State._playerNodeId >= 0):
		var _curNode = JS.find(State._zoneGraph.get("nodes"), func(n = null): return JS.eq(n.id, State._playerNodeId))
		if (JS.t(_curNode) and _curNode.get("type") == "gym"):
			State._zoneGraph = null
			State._playerNodeId = -1
			State._completedNodeIds = JSSet.new()
			State._pendingNodeId = -1
			State._zoneIntroPlayed = false
			generateZoneGraph()
	# ── Background sky/terrain canvas (no interactive nodes) ──
	_buildAndShowCanvas([], [])
	# ── Zone map overlay — debounced so rapid showMap() calls only fire once ──
	JS.clearTimeout(_znMapTimer)
	var _fn3 = func():
		drawZoneMap()
		if not JS.t(State._zoneIntroPlayed):
			_playZoneIntroAnim()
		else:
			_scrollToPlayer()
	_znMapTimer = JS.setTimeout(_fn3, 0)

func initZoneSpecial():
	# Generate the dynamic reward sequence and rival slot for this zone
	BattleReward.initZoneRewardSequence()
	# Mid pair: two consecutive-ish slots in range 7-10
	var midFirst = 7 + floori(JS.random() * 3)
	# 7, 8, or 9
	var midSecond = min((midFirst + 1) + floori(JS.random() * 2), 10)
	# +1 or +2, cap 10
	# End pair: slots 11-12 or 12-13 (always in the gym-open window)
	var endFirst = 11 + floori(JS.random() * 2)
	# 11 or 12
	var endSecond = endFirst + 1
	# always +1
	# Randomly assign shop/campfire within each pair
	if JS.random() < 0.5:
		_zoneCampfireMid = midFirst
		_zoneShopMid = midSecond
	else:
		_zoneShopMid = midFirst
		_zoneCampfireMid = midSecond
	if JS.random() < 0.5:
		_zoneCampfireEnd = endFirst
		_zoneShopEnd = endSecond
	else:
		_zoneShopEnd = endFirst
		_zoneCampfireEnd = endSecond

# Returns 'campfire' | 'shop' | null
func _pickZoneSpecial():
	if JS.eq(State.zoneBattleCount, _zoneCampfireMid):
		_zoneCampfireMid = -1
		if (JS.or_(State.player.get("_mistCampfireReduction"), 0)) >= 1:
			return null
		return "campfire"
	if JS.eq(State.zoneBattleCount, _zoneShopMid):
		_zoneShopMid = -1
		return "shop"
	if JS.eq(State.zoneBattleCount, _zoneCampfireEnd):
		_zoneCampfireEnd = -1
		if (JS.or_(State.player.get("_mistCampfireReduction"), 0)) >= 1:
			return null
		return "campfire"
	if JS.eq(State.zoneBattleCount, _zoneShopEnd):
		_zoneShopEnd = -1
		return "shop"
	return null

func _buildAndShowCanvas(encounters = null, specials = null):
	var _fn4 = func():
		var canvas = document.getElementById("map-canvas")
		if not JS.t(canvas):
			return
		var wrap_ = canvas.parentElement
		# Fill viewport minus a tiny padding
		canvas.width = JS.round(JS.or_(wrap_.get("clientWidth"), window.innerWidth))
		canvas.height = JS.round(JS.or_(wrap_.get("clientHeight"), window.innerHeight))
		if canvas.height < 300:
			canvas.height = JS.round(window.innerHeight)
		var nodes = Progression.buildMapNodes(encounters, specials, canvas.width, canvas.height)
		Progression.showMapCanvas(nodes)
	JS.setTimeout(_fn4, 0)

# ── Node icon styles + per-type animations ─────────────────────────────────────
func _injectNodeIconStyles():
	if JS.t(document.getElementById("node-icon-styles")):
		return
	var s = document.createElement("style")
	s.id = "node-icon-styles"
	s.textContent = "\n    @keyframes niFlicker {\n      0%,100%{transform:scaleX(1) scaleY(1);opacity:1}\n      20%{transform:scaleX(.86) scaleY(1.07);opacity:.82}\n      40%{transform:scaleX(1.08) scaleY(.93);opacity:1}\n      60%{transform:scaleX(.92) scaleY(1.1);opacity:.88}\n      80%{transform:scaleX(1.05) scaleY(.96);opacity:1}\n    }\n    @keyframes niSpin    { from{transform:rotate(0deg)}   to{transform:rotate(360deg)} }\n    @keyframes niSpinCCW { from{transform:rotate(0deg)}   to{transform:rotate(-360deg)} }\n    @keyframes niBob     { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-2px)} }\n    @keyframes niShake   { 0%,100%{transform:rotate(0deg)} 25%{transform:rotate(-6deg)} 75%{transform:rotate(6deg)} }\n    @keyframes niPulse   { 0%,100%{opacity:1;transform:scale(1)} 50%{opacity:.72;transform:scale(.93)} }\n    @keyframes niGlint   { 0%,72%,100%{filter:none} 78%{filter:drop-shadow(0 0 4px #fff) brightness(1.8)} }\n    @keyframes niBounce  { 0%,100%{transform:translateY(0) scaleY(1)} 45%{transform:translateY(-3px) scaleY(1.07)} 65%{transform:translateY(0) scaleY(.94)} }\n    @keyframes niFloat   { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-3px)} }\n    @keyframes niGem     { 0%,100%{filter:none;transform:scale(1)} 50%{filter:drop-shadow(0 0 5px #fff);transform:scale(1.07)} }\n    .ni-sword   { animation: niGlint    3.8s ease-in-out infinite; transform-origin:center; }\n    .ni-tome    { animation: niPulse    2.8s ease-in-out infinite; transform-origin:center; }\n    .ni-scroll  { animation: niFloat    2.2s ease-in-out infinite; }\n    .ni-gem     { animation: niGem      2.2s ease-in-out infinite; transform-origin:center; }\n    .ni-star    { animation: niSpin     5s linear infinite; transform-origin:center; }\n    .ni-arcane  { animation: niSpinCCW  8s linear infinite; transform-origin:center; }\n    .ni-crown   { animation: niBob      2.2s ease-in-out infinite; }\n    .ni-crossed { animation: niShake    2.6s ease-in-out infinite; transform-origin:center; }\n    .ni-flame   { animation: niFlicker  0.9s ease-in-out infinite; transform-origin:center bottom; }\n    .ni-bag     { animation: niBounce   1.9s ease-in-out infinite; }\n  "
	document.head.appendChild(s)

# ── Node icon helper — pixel-art SVG icons on a 16×16 grid ────────────────────
func _nodeIcon(type_ = null, color = null, size = null):
	size = [size]
	size[0] = JS.or_(size[0], 28)
	_injectNodeIconStyles()
	# c = fill color, d = dim fill opacity, b = bright fill opacity, hi = highlight pixel
	var open = func(cls = null): return "<svg viewBox=\"0 0 16 16\" width=\"" + JS.s(size[0]) + "\" height=\"" + JS.s(size[0]) + "\" class=\"" + JS.s(cls) + "\" shape-rendering=\"crispEdges\" style=\"overflow:visible;display:block\" xmlns=\"http://www.w3.org/2000/svg\">"
	var z = "</svg>"
	var c = color
	var f = "fill=\"" + JS.s(c) + "\""
	var fo = func(a = null): return "fill=\"" + JS.s(c) + "\" fill-opacity=\"" + JS.s(a) + "\""
	var hi = func(x = null, y = null, w = null, h = null): return "<rect x=\"" + JS.s(x) + "\" y=\"" + JS.s(y) + "\" width=\"" + JS.s(w) + "\" height=\"" + JS.s(h) + "\" fill=\"#fff\" fill-opacity=\"0.45\"/>"
	match type_:
		"sword":
			return JS.s(open.call("ni-sword")) + ("<rect x=\"7\" y=\"0\" width=\"2\" height=\"9\" " + JS.s(fo.call(0.9)) + "/>") + ("<rect x=\"1\" y=\"4\" width=\"14\" height=\"2\" " + JS.s(fo.call(0.9)) + "/>") + ("<rect x=\"7\" y=\"10\" width=\"2\" height=\"4\" " + JS.s(fo.call(0.55)) + "/>") + ("<rect x=\"5\" y=\"14\" width=\"6\" height=\"2\" " + JS.s(fo.call(0.85)) + "/>") + JS.s(hi.call(7, 0, 1, 4)) + z
		"tome":
			# Blade (2px wide, occupies top 9 rows)
			# Crossguard (full width bar at row 4-5)
			# Handle
			# Pommel
			# Blade edge highlight
			return JS.s(open.call("ni-tome")) + ("<rect x=\"9\" y=\"1\" width=\"6\" height=\"14\" " + JS.s(fo.call(0.18)) + "/>") + ("<rect x=\"1\" y=\"1\" width=\"6\" height=\"14\" " + JS.s(fo.call(0.18)) + "/>") + ("<rect x=\"7\" y=\"1\" width=\"2\" height=\"14\" " + JS.s(fo.call(0.9)) + "/>") + ("<rect x=\"1\" y=\"1\" width=\"6\" height=\"14\" fill=\"none\" stroke=\"" + JS.s(c) + "\" stroke-width=\"1\"/>") + ("<rect x=\"9\" y=\"1\" width=\"6\" height=\"14\" fill=\"none\" stroke=\"" + JS.s(c) + "\" stroke-width=\"1\"/>") + ("<rect x=\"2\" y=\"4\" width=\"4\" height=\"1\" " + JS.s(fo.call(0.8)) + "/>") + ("<rect x=\"2\" y=\"7\" width=\"4\" height=\"1\" " + JS.s(fo.call(0.8)) + "/>") + ("<rect x=\"2\" y=\"10\" width=\"3\" height=\"1\" " + JS.s(fo.call(0.8)) + "/>") + ("<rect x=\"11\" y=\"5\" width=\"1\" height=\"3\" " + JS.s(fo.call(0.8)) + "/>") + ("<rect x=\"10\" y=\"6\" width=\"3\" height=\"1\" " + JS.s(fo.call(0.8)) + "/>") + JS.s(hi.call(1, 1, 1, 1)) + z
		"scroll":
			# Right page fill
			# Left page fill
			# Spine (bright center bar)
			# Page outlines
			# Left page rune lines
			# Right page glyph (cross/star shape)
			return JS.s(open.call("ni-scroll")) + ("<rect x=\"3\" y=\"2\" width=\"10\" height=\"12\" " + JS.s(fo.call(0.22)) + "/>") + ("<rect x=\"3\" y=\"2\" width=\"10\" height=\"12\" fill=\"none\" stroke=\"" + JS.s(c) + "\" stroke-width=\"1\"/>") + ("<rect x=\"1\" y=\"3\" width=\"3\" height=\"10\" " + JS.s(fo.call(0.5)) + "/>") + ("<rect x=\"1\" y=\"2\" width=\"3\" height=\"12\" fill=\"none\" stroke=\"" + JS.s(c) + "\" stroke-width=\"1\"/>") + ("<rect x=\"12\" y=\"3\" width=\"3\" height=\"10\" " + JS.s(fo.call(0.3)) + "/>") + ("<rect x=\"5\" y=\"5\" width=\"6\" height=\"1\" " + JS.s(fo.call(0.85)) + "/>") + ("<rect x=\"5\" y=\"8\" width=\"6\" height=\"1\" " + JS.s(fo.call(0.85)) + "/>") + ("<rect x=\"5\" y=\"11\" width=\"4\" height=\"1\" " + JS.s(fo.call(0.85)) + "/>") + JS.s(hi.call(1, 2, 1, 1)) + z
		"gem":
			# Scroll body
			# Left curl (thick left edge)
			# Right implied edge
			# Rune text lines
			return JS.s(open.call("ni-gem")) + ("<polygon points=\"8,1 15,7 8,15 1,7\" " + JS.s(fo.call(0.28)) + "/>") + ("<polygon points=\"8,1 15,7 8,15 1,7\" fill=\"none\" stroke=\"" + JS.s(c) + "\" stroke-width=\"1\"/>") + ("<rect x=\"1\" y=\"7\" width=\"14\" height=\"1\" " + JS.s(fo.call(0.8)) + "/>") + ("<rect x=\"7\" y=\"2\" width=\"1\" height=\"1\" " + JS.s(fo.call(0.4)) + "/><rect x=\"6\" y=\"3\" width=\"1\" height=\"1\" " + JS.s(fo.call(0.4)) + "/><rect x=\"5\" y=\"4\" width=\"1\" height=\"1\" " + JS.s(fo.call(0.4)) + "/><rect x=\"4\" y=\"5\" width=\"1\" height=\"1\" " + JS.s(fo.call(0.4)) + "/><rect x=\"3\" y=\"6\" width=\"1\" height=\"1\" " + JS.s(fo.call(0.4)) + "/>") + ("<rect x=\"9\" y=\"2\" width=\"1\" height=\"1\" " + JS.s(fo.call(0.4)) + "/><rect x=\"10\" y=\"3\" width=\"1\" height=\"1\" " + JS.s(fo.call(0.4)) + "/><rect x=\"11\" y=\"4\" width=\"1\" height=\"1\" " + JS.s(fo.call(0.4)) + "/><rect x=\"12\" y=\"5\" width=\"1\" height=\"1\" " + JS.s(fo.call(0.4)) + "/><rect x=\"13\" y=\"6\" width=\"1\" height=\"1\" " + JS.s(fo.call(0.4)) + "/>") + JS.s(hi.call(6, 3, 2, 2)) + z
		"star":
			# Diamond body fill + outline
			# Horizontal facet
			# Upper left facet (stepped pixel diagonal)
			# Upper right facet
			# Highlight corner
			return JS.s(open.call("ni-star")) + ("<polygon points=\"8,1 10,6 15,6 11,9 13,15 8,11 3,15 5,9 1,6 6,6\" " + JS.s(fo.call(0.35)) + "/>") + ("<polygon points=\"8,1 10,6 15,6 11,9 13,15 8,11 3,15 5,9 1,6 6,6\" fill=\"none\" stroke=\"" + JS.s(c) + "\" stroke-width=\"1\"/>") + JS.s(hi.call(7, 7, 2, 2)) + z
		"arcane":
			# 5-pointed star
			# Center shine
			return JS.s(open.call("ni-arcane")) + ("<polygon points=\"8,0 9,7 16,8 9,9 8,16 7,9 0,8 7,7\" " + JS.s(fo.call(0.35)) + "/>") + ("<polygon points=\"8,0 9,7 16,8 9,9 8,16 7,9 0,8 7,7\" fill=\"none\" stroke=\"" + JS.s(c) + "\" stroke-width=\"1\"/>") + ("<rect x=\"6\" y=\"6\" width=\"4\" height=\"4\" " + JS.s(fo.call(0.4)) + "/>") + JS.s(hi.call(7, 6, 2, 2)) + z
		"crown":
			# 4-pointed star body
			# Inner square
			return JS.s(open.call("ni-crown")) + ("<rect x=\"1\" y=\"12\" width=\"14\" height=\"3\" " + JS.s(fo.call(0.9)) + "/>") + ("<rect x=\"1\" y=\"10\" width=\"14\" height=\"2\" " + JS.s(fo.call(0.6)) + "/>") + ("<rect x=\"2\" y=\"7\" width=\"3\" height=\"3\" " + JS.s(fo.call(0.9)) + "/>") + ("<rect x=\"6\" y=\"3\" width=\"4\" height=\"7\" " + JS.s(fo.call(0.9)) + "/>") + ("<rect x=\"11\" y=\"7\" width=\"3\" height=\"3\" " + JS.s(fo.call(0.9)) + "/>") + JS.s(hi.call(7, 5, 2, 2)) + JS.s(hi.call(3, 8, 1, 1)) + JS.s(hi.call(12, 8, 1, 1)) + z
		"crossed":
			# Crown base
			# Crown body between spikes
			# Left spike
			# Center spike (tallest)
			# Right spike
			# Jewels
			return JS.s(open.call("ni-crossed")) + ("<polygon points=\"2,2 5,2 14,14 11,14\" " + JS.s(fo.call(0.85)) + "/>") + ("<polygon points=\"14,2 11,2 2,14 5,14\" " + JS.s(fo.call(0.85)) + "/>") + ("<rect x=\"8\" y=\"5\" width=\"5\" height=\"2\" " + JS.s(fo.call(0.9)) + "/>") + ("<rect x=\"3\" y=\"5\" width=\"5\" height=\"2\" " + JS.s(fo.call(0.9)) + "/>") + JS.s(hi.call(2, 2, 1, 2)) + JS.s(hi.call(13, 2, 1, 2)) + z
		"flame":
			# Sword 1: blade NW, handle SE
			# Sword 2: blade NE, handle SW
			# Guard 1 (horizontal, right side near NW blade root)
			# Guard 2 (left side near NE blade root)
			# Blade tip highlights
			return JS.s(open.call("ni-flame")) + ("<polygon points=\"8,1 11,5 13,3 11,8 14,7 11,12 8,15 5,12 2,7 5,8 3,3 5,5\" " + JS.s(fo.call(0.45)) + "/>") + ("<polygon points=\"8,1 11,5 13,3 11,8 14,7 11,12 8,15 5,12 2,7 5,8 3,3 5,5\" fill=\"none\" stroke=\"" + JS.s(c) + "\" stroke-width=\"1\"/>") + ("<polygon points=\"8,5 10,8 9,12 8,14 7,12 6,8\" " + JS.s(fo.call(0.75)) + "/>") + JS.s(hi.call(7, 8, 2, 3)) + ("<rect x=\"3\" y=\"14\" width=\"10\" height=\"2\" " + JS.s(fo.call(0.7)) + "/>") + ("<rect x=\"5\" y=\"13\" width=\"2\" height=\"1\" " + JS.s(fo.call(0.5)) + "/>") + ("<rect x=\"9\" y=\"13\" width=\"2\" height=\"1\" " + JS.s(fo.call(0.5)) + "/>") + z
		"bag":
			# Outer flame body
			# Inner flame (brighter)
			# Core highlight
			# Logs
			return JS.s(open.call("ni-bag")) + ("<rect x=\"3\" y=\"8\" width=\"10\" height=\"7\" " + JS.s(fo.call(0.28)) + "/>") + ("<rect x=\"3\" y=\"8\" width=\"10\" height=\"7\" fill=\"none\" stroke=\"" + JS.s(c) + "\" stroke-width=\"1\"/>") + ("<rect x=\"5\" y=\"6\" width=\"6\" height=\"2\" " + JS.s(fo.call(0.65)) + "/>") + ("<rect x=\"6\" y=\"5\" width=\"4\" height=\"1\" " + JS.s(fo.call(0.5)) + "/>") + ("<rect x=\"7\" y=\"4\" width=\"2\" height=\"1\" " + JS.s(fo.call(0.5)) + "/>") + ("<rect x=\"6\" y=\"10\" width=\"4\" height=\"3\" fill=\"none\" stroke=\"" + JS.s(c) + "\" stroke-width=\"1\"/>") + ("<rect x=\"7\" y=\"11\" width=\"2\" height=\"1\" " + JS.s(fo.call(0.75)) + "/>") + JS.s(hi.call(3, 8, 1, 1)) + z
		_:
			# Bag body
			# Bag neck/tie
			# Knot top (triangle)
			# Coin symbol
			return JS.s(open.call("ni-sword")) + ("<rect x=\"3\" y=\"3\" width=\"10\" height=\"10\" " + JS.s(fo.call(0.4)) + "/>") + ("<rect x=\"3\" y=\"3\" width=\"10\" height=\"10\" fill=\"none\" stroke=\"" + JS.s(c) + "\" stroke-width=\"1\"/>") + z

func _injectMapRewardStyles():
	if JS.t(document.getElementById("map-reward-styles")):
		return
	var s = document.createElement("style")
	s.id = "map-reward-styles"
	s.textContent = "\n    @keyframes mapSpellGlow {\n      0%,100% { filter:drop-shadow(0 0 6px #8060c0);transform:scale(1); }\n      50%     { filter:drop-shadow(0 0 18px #a080ff);transform:scale(1.18); }\n    }\n    @keyframes mapScrollFloat {\n      0%,100% { transform:translateY(0);filter:drop-shadow(0 0 5px #c06010); }\n      50%     { transform:translateY(-7px);filter:drop-shadow(0 0 13px #e08020); }\n    }\n    @keyframes mapPickupFloat {\n      0%,100% { transform:translateY(0);filter:drop-shadow(0 0 4px #c89040); }\n      50%     { transform:translateY(-7px);filter:drop-shadow(0 0 12px #e8b060); }\n    }\n    @keyframes mapPowerPulse {\n      0%,100% { filter:drop-shadow(0 0 8px #c8a020);transform:scale(1); }\n      50%     { filter:drop-shadow(0 0 22px #ffd040);transform:scale(1.20); }\n    }\n  "
	document.head.appendChild(s)

func makeCombatCard(enc = null):
	# Special encounter slots (campfire / shop replacing a battle)
	if JS.t(enc.get("_isSpecial")):
		return makeSpecialCard(enc.get("_specialType"))
	_injectMapRewardStyles()
	var card = document.createElement("div")
	card.className = "encounter-card"
	card.style.cssText = "display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;padding:1.1rem .8rem;gap:.5rem;"
	var nextSlot = State.zoneBattleCount + 1
	var rewardType = BattleReward.getZoneRewardType(nextSlot, State.currentGymIdx)
	var cfg = JS.or_(JS.idx(_MAP_REWARD_CFG, rewardType), _MAP_REWARD_CFG.get("minor"))
	var gold = (enc.get("gold") if JS.t(enc.get("isPack")) else JS.or_(enc.get("gold"), 0))
	card.innerHTML = "\n    <div style=\"line-height:1;animation:" + JS.s(cfg.get("anim")) + ";\">" + _nodeIcon(cfg.get("iconType"), cfg.get("color"), 48) + "</div>\n    <div style=\"font-family:'Cinzel',serif;font-size:.78rem;color:" + JS.s(cfg.get("color")) + ";letter-spacing:.08em;margin-top:.1rem;\">" + JS.s(cfg.get("label")) + "</div>\n    <div style=\"font-size:.58rem;color:#444;margin-top:.1rem;\">⚔ Battle · " + JS.s(gold) + "g</div>\n  "
	card.onclick = func(): return BattleLoad.loadBattle(enc)
	return card

func makeGymCard(forced = null):
	var gym = Encounters.currentGymDef()
	if not JS.t(gym):
		return document.createElement("div")
	var card = document.createElement("div")
	card.className = "special-card " + ("card-gym-warn" if JS.t(forced) else "card-gym")
	var bHP = Helpers.gymBossDisplayHP()
	var battlesLeft = Constants.GYM_ZONE_FORCE - State.zoneBattleCount
	var skipNote = (" (+" + JS.s(State.gymSkips * Constants.GYM_SKIP_BONUS) + " skip HP)" if State.gymSkips > 0 else "")
	card.innerHTML = "<div class=\"enc-left\"><div class=\"enc-name\" style=\"color:" + JS.s(("#cc4444" if JS.t(forced) else gym.get("color"))) + "\">🏛 Gym " + JS.s(State.currentGymIdx + 1) + " — " + JS.s(gym.get("name")) + "</div><div class=\"enc-desc\" style=\"color:" + ("#7a2a2a" if JS.t(forced) else "#888") + "\">" + JS.s(gym.get("element")) + " · HP:" + JS.s(bHP) + skipNote + " · Dmg:" + JS.s(Helpers.gymBossDisplayDmg()) + " · " + ("MUST FIGHT NOW" if JS.t(forced) else "zone battle " + JS.s(State.zoneBattleCount) + "/" + JS.s(Constants.GYM_ZONE_FORCE)) + "</div><div style=\"font-size:.57rem;color:#555;margin-top:2px;\">" + JS.s(gym.get("signature")) + "</div></div><div class=\"enc-right\" style=\"color:" + JS.s(("#cc4444" if JS.t(forced) else gym.get("color"))) + ";font-family:'Cinzel',serif;font-size:.62rem;\">" + ("FORCED" if JS.t(forced) else "BOSS") + "</div>"
	card.onclick = func(): return GymRival.showGymIntro(forced)
	return card

func makeSpecialCard(type_ = null):
	var card = document.createElement("div")
	card.className = "special-card"
	if type_ == "campfire":
		card.classList.add("card-campfire")
		card.innerHTML = "<div class=\"enc-left\"><div class=\"enc-name\" style=\"color:#d4822a\">🔥 Campfire</div><div class=\"enc-desc\" style=\"color:#7a5a2a\">Recover 50% HP</div></div><div class=\"enc-right\" style=\"color:#7a5a2a\">REST</div>"
		card.onclick = func(): return ShopCampfire.enterCampfire()
	elif type_ == "rival":
		var rHP = GymRival.rivalHP()
		var rDmg = GymRival.rivalDmg()
		card.style.borderColor = "#3a1a6a"
		card.innerHTML = "<div class=\"enc-left\"><div class=\"enc-name\" style=\"color:#9a6aee\">🧢 Rival " + JS.s(Encounters.RIVAL.get("name")) + "</div><div class=\"enc-desc\" style=\"color:#6a4a90\">" + JS.s(State.playerElement) + " · HP:" + JS.s(rHP) + " · Dmg:" + JS.s(rDmg) + "/turn</div><div style=\"font-size:.57rem;color:#4a3a60;margin-top:2px;\">Reward: ✦ Passive Ability</div></div><div class=\"enc-right\" style=\"color:#9a6aee;font-family:'Cinzel',serif;font-size:.62rem;\">RIVAL</div>"
		card.onclick = func(): return GymRival.showRivalIntro()
	else:
		card.classList.add("card-shop")
		card.innerHTML = "<div class=\"enc-left\"><div class=\"enc-name\" style=\"color:#2aaa7a\">🏪 Shop</div><div class=\"enc-desc\" style=\"color:#2a6a4a\">Spend gold on items</div></div><div class=\"enc-right\" style=\"color:#2a6a4a\">SHOP</div>"
		card.onclick = func(): return ShopCampfire.enterShop()
	return card

# fraction of canvas that is sky — nodes stay below this
# ── Graph generation ──────────────────────────────────────────────────────────
func generateZoneGraph():
	var gym = Encounters.currentGymDef()
	var zoneEl = (gym.get("element") if JS.t(gym) else State.playerElement)
	# Rival tier
	var rivalTier = (min(max(BattleReward._zoneRivalSlot, 4), ZN_TIERS - 2) if (true and BattleReward._zoneRivalSlot > 0) else 7)
	# Per-node independent campfire/shop chances — max 4 of each per zone.
	# Tracked as we place nodes; each battle-eligible node rolls independently.
	var cfCount = 0
	var shCount = 0
	var MAX_CF = 4
	var MAX_SH = 4
	# Skip rolls on tier 1 (start), rival tier, pre-gym, gym
	var noRollTiers = JSSet.new([1, 2, 3, rivalTier, ZN_TIERS - 1, ZN_TIERS])
	# Shop spacing: track placed shops {tier, col} — no shop within 3 tiers on same/adjacent col
	var shopPlacements = []
	# Zone 2+: pre-shuffle all 4 reward types across the starting nodes so each shows a different reward
	var _startRewards = (JS.sort(["spell", "incantation", "minor", "major"], func(): return JS.random() - 0.5) if State.currentGymIdx > 0 else null)
	# Build per-tier column lists (wider branching — 20/35/45 split toward 4 cols)
	var tierColsList = []
	for t in range(1, floori(ZN_TIERS) + 1):
		var cols = null
		# Zone 2+: tier 1 has 4 starting options (player picks their path entry point)
		if t == 1:
			cols = ([1.5] if JS.eq(State.currentGymIdx, 0) else [0, 1, 2, 3])
		elif t == ZN_TIERS:
			cols = [1.5]
		elif t == (ZN_TIERS - 1):
			cols = [0, 2]
		elif t == (rivalTier - 1):
			cols = [1, 2]
		elif t == rivalTier:
			cols = [1, 3]
		elif t <= 2:
			cols = [0, 2]
		elif t <= 4:
			cols = [0, 1, 2]
		else:
			# gym node (centered)
			# pre-gym funnel
			# funnel toward middle before rival
			# rival col1 (middle), battle col3
			# 20% 2-wide, 35% 3-wide, 45% 4-wide
			var r = JS.random()
			if r < 0.2:
				cols = [0, 3]
			elif r < 0.55:
				cols = [0, 1, 3]
			else:
				cols = [0, 1, 2, 3]
		tierColsList.append(cols)
	# Create nodes
	var nodes = []
	var tierNodes = JS.arrayFrom({"length": ZN_TIERS + 1}, func(): return [])
	# 1-indexed
	var nextId = 0
	for t in range(1, floori(ZN_TIERS) + 1):
		var cols = JS.idx(tierColsList, t - 1)
		var ci = 0
		while ci < len(cols):
			var col = cols[ci]
			# Determine node type
			var type_ = "battle"
			if t == ZN_TIERS:
				type_ = "gym"
			elif ((t == rivalTier and ci == 0) and not JS.t(State._zoneRivalDefeated)):
				type_ = "rival"
			elif not noRollTiers.has(t):
				# Independent per-node roll for campfire/shop
				var roll = JS.random()
				if (cfCount < MAX_CF and roll < 0.14):
					if (JS.or_(State.player.get("_mistCampfireReduction"), 0)) < 1:
						type_ = "campfire"
						cfCount += 1
				elif ((shCount < MAX_SH and roll >= 0.14) and roll < 0.27):
					# Spacing check: no shop within 3 tiers on same or adjacent column
					var shopTooClose = JS.some(shopPlacements, func(s = null): return (abs(s.get("col") - col) <= 1 and (t - JS.un(s.get("tier"))) < 4))
					if not shopTooClose:
						type_ = "shop"
						shCount += 1
						shopPlacements.append({"tier": t, "col": col})
			# Reward type and enc for battle nodes
			# Use tier as the slot (mirrors old system: each screen = one slot with two encounters)
			var rewardType = null
			var enc = null
			if type_ == "battle":
				if (t == 1 and JS.t(_startRewards)):
					rewardType = JS.or_(JS.idx(_startRewards, ci), "minor")
				else:
					rewardType = BattleReward.getZoneRewardType(t, State.currentGymIdx, ci)
					if rewardType == "primary_spell":
						rewardType = "spell"
				enc = _pickZoneGraphEnc(zoneEl)
				enc._rewardType = rewardType
			var _t5 = nextId
			nextId += 1
			var node = {"id": _t5, "tier": t, "col": col, "type": type_, "rewardType": rewardType, "enc": enc}
			nodes.append(node)
			tierNodes[t].append(node)
			ci += 1
	# Build edges: closest-col matching + ensure all nodes fully connected
	var edges = []
	var _fn6 = func(a = null, b = null):
		if not JS.some(edges, func(e = null): return (JS.eq(JS.idx(e, 0), a) and JS.eq(JS.idx(e, 1), b))):
			edges.append([a, b])
	var addEdge = _fn6
	for t in range(1, ceili(ZN_TIERS)):
		var froms = JS.sort(JS.arr(tierNodes[t]), func(a = null, b = null): return a.get("col") - b.get("col"))
		var tos = JS.sort(JS.arr(JS.idx(tierNodes, t + 1)), func(a = null, b = null): return a.get("col") - b.get("col"))
		var toHit = JSSet.new()
		# Each from → closest to
		for fn in JS.iter(froms):
			var best = JS.idx(tos, 0)
			for tn in JS.iter(tos):
				if abs(tn.get("col") - fn.get("col")) < abs(best.get("col") - fn.get("col")):
					best = tn
			addEdge.call(fn.id, best.id)
			toHit.add(best.id)
		# Ensure every to node is reachable
		for tn in JS.iter(tos):
			if not toHit.has(tn.id):
				var best = JS.idx(froms, 0)
				for fn in JS.iter(froms):
					if abs(fn.get("col") - tn.get("col")) < abs(best.get("col") - tn.get("col")):
						best = fn
				addEdge.call(best.id, tn.id)
				toHit.add(tn.id)
		# Optional diagonal: only adjacent columns (diff ≤ 1) to avoid wild crossings
		if ((len(froms) > 1 and len(tos) > 1) and JS.random() < 0.35):
			var fi = floori(JS.random() * len(froms))
			var ti = floori(JS.random() * len(tos))
			if abs(JS.idx(froms, fi).get("col") - JS.idx(tos, ti).get("col")) <= 1:
				addEdge.call(JS.idx(froms, fi).id, JS.idx(tos, ti).id)
	State._zoneGraph = {"nodes": nodes, "edges": edges}
	# Zone 2+: player hasn't picked a starting tile yet — hide wizard until they choose
	if State.currentGymIdx > 0:
		_znWizardX = 0
		_znWizardY = 0
	# Zone 1: the tier-1 battle was the starting spell choice — already done before the map.
	# Mark it complete so the player lands on it and picks from tier 2 immediately.
	if JS.eq(State.currentGymIdx, 0):
		var startNode = JS.find(nodes, func(n = null): return JS.eq(n.get("tier"), 1))
		if JS.t(startNode):
			State._playerNodeId = startNode.id
			State._completedNodeIds.add(startNode.id)

func _pickZoneGraphEnc(zoneEl = null):
	var _rel = func(e = null): return JS.includes(Constants.RELEASED_ELEMENTS, JS.or_(e.get("campType"), e.get("element")))
	var zoneSingles = JS.arr(Encounters.ENCOUNTER_POOL).filter(func(e = null): return (JS.eq(e.get("campType"), zoneEl) and JS.t(_rel.call(e))))
	var crossSingles = JS.arr(Encounters.ENCOUNTER_POOL).filter(func(e = null): return (not JS.eq(e.get("campType"), zoneEl) and JS.t(_rel.call(e))))
	var zonePacks = JS.arr(Encounters.PACK_POOL).filter(func(p = null): return (JS.eq(p.get("element"), zoneEl) and JS.t(_rel.call(p))))
	var pool = (zoneSingles if JS.t(len(zoneSingles)) else JS.filter(Encounters.ENCOUNTER_POOL, _rel))
	if (JS.t(len(zonePacks)) and JS.random() < 0.2):
		return JS.merge([JS.idx(zonePacks, floori(JS.random() * len(zonePacks)))])
	if (JS.t(len(crossSingles)) and JS.random() < 0.35):
		return JS.merge([JS.idx(crossSingles, floori(JS.random() * len(crossSingles)))])
	return JS.merge([JS.idx(pool, floori(JS.random() * len(pool)))])

# ── Zone map rendering ────────────────────────────────────────────────────────
# Draw a full-height zone background + cobblestone paths onto the scrollable stage canvas.
# nodePositions: {id -> {x,y}} so paths can be drawn in terrain space.
func _drawZoneBgTall(canvas = null, W = null, H = null, nodePositions = null, edges = null):
	var ctx = canvas.getContext("2d")
	if not JS.t(ctx):
		return
	# Sky fraction matches node positioning so gym always lands in terrain
	var horizY = JS.round(H * ZN_SKY_FRAC)
	var tick = JS.mod(JS.dateNow(), 100000)
	# Reset shared canvas state so the tall canvas gets a clean draw
	Progression._clouds.clear()
	Progression._lastCloudTick = 0
	Progression._starCache = null
	# Sky, stars, moon, nebulae, clouds
	Progression._drawNightSky(ctx, W, H, horizY, tick)
	# Zone-specific terrain (mountains, ground, trees, lava/ice/etc.)
	Progression._drawTerrain(ctx, W, H, horizY, tick)
	# Animated details (critters, sparks — static snapshot at tick)
	Progression._drawZoneDetails(ctx, W, H, horizY, tick)
	# Cobblestone paths between nodes — drawn on top of terrain
	if (JS.t(nodePositions) and JS.t(edges)):
		for _e7 in JS.iter(edges):
			var fid = JS.idx(_e7, 0)
			var tid = JS.idx(_e7, 1)
			var f = nodePositions[fid]
			var t = nodePositions[tid]
			if (not JS.t(f) or not JS.t(t)):
				continue
			# Gentle S-curve control point: perpendicular offset at midpoint
			var mx = (f.get("x") + t.get("x")) * 0.5
			var my = (f.get("y") + t.get("y")) * 0.5
			var dx = t.get("x") - f.get("x")
			var dy = t.get("y") - f.get("y")
			var dist = JS.or_(sqrt((dx * dx) + (dy * dy)), 1)
			var perp = min(dist * 0.12, 28)
			# Alternate curve direction using endpoint hash for variety
			var side = (1 if (JS.mod((fid * 7) + (tid * 13), 2)) == 0 else -1)
			var cpx = mx + ((((-dy) / float(dist)) * perp) * side)
			var cpy = my + (((dx / float(dist)) * perp) * side)
			LobbyMap._drawCobblestonePath(ctx, f.get("x"), f.get("y"), cpx, cpy, t.get("x"), t.get("y"), 10)

func _znColToX(col = null, w = null):
	var margin = w * 0.13
	return margin + ((col / float((ZN_COLS - 1))) * (w - (margin * 2)))

func _znTierToY(tier = null, stageH = null):
	# Gym (tier ZN_TIERS) sits just inside the terrain; tier 1 near the bottom.
	# Both snap to the same sky fraction as the background art.
	var topY = JS.round(stageH * ZN_SKY_FRAC) + 30
	# just below sky horizon
	var bottomY = stageH - ZN_PAD
	var frac = (tier - 1) / float((ZN_TIERS - 1))
	# 0 = tier 1, 1 = gym
	return JS.round(bottomY - (frac * (bottomY - topY)))

func drawZoneMap():
	var overlay = document.getElementById("zone-map-overlay")
	var stage = document.getElementById("zone-map-stage")
	var svg = document.getElementById("zone-map-svg")
	if (((not JS.t(overlay) or not JS.t(stage)) or not JS.t(svg)) or not JS.t(State._zoneGraph)):
		return
	var stageW = JS.or_(overlay.get("clientWidth"), window.innerWidth)
	var stageH = (ZN_TIERS * ZN_TIER_H) + (ZN_PAD * 2)
	stage.style.width = JS.s(stageW) + "px"
	stage.style.height = JS.s(stageH) + "px"
	svg.setAttribute("viewBox", "0 0 " + JS.s(stageW) + " " + JS.s(stageH))
	svg.setAttribute("width", stageW)
	svg.setAttribute("height", stageH)
	# Background art canvas — lives inside the stage so it scrolls with the map
	var bgC = document.getElementById("zone-bg-canvas")
	if not JS.t(bgC):
		bgC = document.createElement("canvas")
		bgC.id = "zone-bg-canvas"
		bgC.style.cssText = "position:absolute;top:0;left:0;pointer-events:none;image-rendering:pixelated;image-rendering:crisp-edges;"
		stage.insertBefore(bgC, stage.firstChild)
	# Pre-calculate node pixel positions (needed for both bg paths and node divs)
	var nodes = JS.idx(State._zoneGraph, "nodes")
	var edges = JS.idx(State._zoneGraph, "edges")
	var nodePositions = {}
	for n in JS.iter(nodes):
		nodePositions[n.id] = {"x": _znColToX(n.get("col"), stageW), "y": _znTierToY(n.get("tier"), stageH)}
	# Background + cobblestone paths (drawn together on one canvas)
	bgC.width = stageW
	bgC.height = stageH
	bgC.style.width = JS.s(stageW) + "px"
	bgC.style.height = JS.s(stageH) + "px"
	_drawZoneBgTall(bgC, stageW, stageH, nodePositions, edges)
	# SVG is no longer used for edges — clear it
	svg.innerHTML = ""
	# Clear old node divs
	for el in JS.iter(stage.querySelectorAll(".zn-node")):
		el.remove()
	var nodeMap = {}
	for n in JS.iter(nodes):
		nodeMap[n.id] = n
	var availIds = _znAvailableIds()
	var gym = Encounters.currentGymDef()
	# Draw nodes (no emoji wizard — wizard lives on its own animated canvas)
	for node in JS.iter(nodes):
		var _d8 = JS.idx(nodePositions, node.id)
		var x = JS.idx(_d8, "x")
		var y = JS.idx(_d8, "y")
		var cfg = _znNodeCfg(node, gym)
		var el = document.createElement("div")
		el.className = "zn-node"
		el.style.left = JS.s(x) + "px"
		el.style.top = JS.s(y) + "px"
		var isCurrent = JS.eq(node.id, State._playerNodeId)
		var isDone = State._completedNodeIds.has(node.id)
		var isAvail = availIds.has(node.id)
		if isCurrent:
			el.classList.add("zn-current")
		if isDone:
			el.classList.add("zn-done")
		if isAvail:
			el.classList.add("zn-available")
		var circle = document.createElement("div")
		circle.className = "zn-circle"
		circle.style.borderColor = cfg.get("color")
		circle.style.setProperty("--zn-glow", JS.s(cfg.get("color")) + "bb")
		circle.innerHTML = _nodeIcon(cfg.get("iconType"), cfg.get("color"))
		if isDone:
			var chk = document.createElement("div")
			chk.className = "zn-done-check"
			chk.textContent = "✓"
			circle.appendChild(chk)
		var lbl = document.createElement("div")
		lbl.className = "zn-label"
		lbl.textContent = cfg.get("label")
		el.appendChild(circle)
		el.appendChild(lbl)
		if isAvail:
			el.onclick = func(): return _startNodeEncounter(node.id)
		stage.appendChild(el)
	# Wizard canvas — animated pixel sprite above current node
	_znStartWizardAnim(stage, stageW, stageH)
	# Zone label at the bottom of the stage
	var zoneLbl = stage.querySelector(".zn-zone-label")
	if not JS.t(zoneLbl):
		zoneLbl = document.createElement("div")
		zoneLbl.className = "zn-zone-label"
		stage.appendChild(zoneLbl)
	var gymDef = Encounters.currentGymDef()
	zoneLbl.textContent = ("Zone " + JS.s(State.currentGymIdx + 1) + " — " + JS.s(gymDef.get("element")) if JS.t(gymDef) else "Zone Start")
	zoneLbl.style.cssText = "position:absolute;bottom:6px;left:50%;transform:translateX(-50%);\n    font-family:'Cinzel',serif;font-size:.62rem;letter-spacing:.13em;text-transform:uppercase;\n    color:" + JS.s((gymDef.get("color") if JS.t(gymDef) else "#c8a060")) + "88;text-shadow:0 1px 6px #000;pointer-events:none;white-space:nowrap;"
	overlay.style.display = "block"
	# Hide old canvas hint text
	var hint = document.getElementById("map-hint")
	if JS.t(hint):
		hint.style.display = "none"

func _znNodeCfg(node = null, gym = null):
	var zoneColor = (gym.get("color") if JS.t(gym) else "#7060b0")
	match node.type:
		"gym":
			return {"iconType": "crown", "label": (gym.get("name") if JS.t(gym) else "Gym Leader"), "color": zoneColor}
		"rival":
			return {"iconType": "crossed", "label": "Rival", "color": "#9a6aee"}
		"campfire":
			return {"iconType": "flame", "label": "Campfire", "color": "#d4822a"}
		"shop":
			return {"iconType": "bag", "label": "Shop", "color": "#2aaa7a"}
		_:
			var rc = JS.idx(_MAP_REWARD_CFG, node.get("rewardType"))
			return {
				"iconType": (rc.get("iconType") if JS.t(rc) else "sword"),
				"label": (rc.get("label") if JS.t(rc) else "Battle"),
				"color": (rc.get("color") if JS.t(rc) else zoneColor),
			}

func _znAvailableIds():
	var s = JSSet.new()
	if not JS.t(State._zoneGraph):
		return s
	if State._playerNodeId == (-1):
		# Zone just started: tier-1 nodes are available
		for n in JS.iter(State._zoneGraph.get("nodes")):
			if JS.eq(n.get("tier"), 1):
				s.add(n.id)
		return s
	for _e9 in JS.iter(State._zoneGraph.get("edges")):
		var fid = JS.idx(_e9, 0)
		var tid = JS.idx(_e9, 1)
		if (JS.eq(fid, State._playerNodeId) and not State._completedNodeIds.has(tid)):
			s.add(tid)
	return s

func _scrollToPlayer():
	var overlay = document.getElementById("zone-map-overlay")
	if (not JS.t(overlay) or not JS.t(State._zoneGraph)):
		return
	var stageH = (ZN_TIERS * ZN_TIER_H) + (ZN_PAD * 2)
	var tier = 1
	if State._playerNodeId >= 0:
		var node = JS.find(State._zoneGraph.get("nodes"), func(n = null): return JS.eq(n.id, State._playerNodeId))
		if JS.t(node):
			tier = node.get("tier")
	var nodeY = _znTierToY(tier, stageH)
	overlay.scrollTop = max(0, nodeY - (overlay.clientHeight * 0.55))

func _playZoneIntroAnim():
	State._zoneIntroPlayed = true
	var overlay = document.getElementById("zone-map-overlay")
	if not JS.t(overlay):
		return
	overlay.scrollTop = 0
	overlay.style.pointerEvents = "none"
	overlay.style.overflowY = "hidden"
	# Banner lives inside the stage so it scrolls with the map
	var stage = document.getElementById("zone-map-stage")
	var gym = Encounters.currentGymDef()
	var stageH = (ZN_TIERS * ZN_TIER_H) + (ZN_PAD * 2)
	var vh = JS.or_(overlay.get("clientHeight"), window.innerHeight)
	var banner = document.createElement("div")
	banner.id = "zn-intro-banner"
	banner.textContent = "Zone " + JS.s(State.currentGymIdx + 1) + (" — " + JS.s(gym.get("element")) if JS.t(gym) else "")
	# Position at the very top of the stage (gym area), centered
	banner.style.cssText = "position:absolute;top:" + JS.s(JS.round(vh * 0.18)) + "px;left:0;right:0;\n    text-align:center;padding:1.2rem 1rem;z-index:20;\n    font-family:'Cinzel',serif;font-size:2rem;letter-spacing:.18em;text-transform:uppercase;\n    color:" + JS.s((gym.get("color") if JS.t(gym) else "#c8a060")) + ";text-shadow:0 0 30px " + JS.s((gym.get("color") if JS.t(gym) else "#c8a060")) + "88;\n    background:linear-gradient(to bottom,#000c,#0000);\n    pointer-events:none;opacity:0;transition:opacity .5s;"
	if JS.t(stage):
		stage.appendChild(banner)
	var _fn10 = func():
		banner.style.opacity = "1"
	JS.requestAnimationFrame(_fn10)
	var playerTier = ((JS.orf(JS.find(State._zoneGraph.get("nodes"), func(n = null): return JS.eq(n.id, State._playerNodeId)), func(): return {"tier": 1})).get("tier") if (State._playerNodeId >= 0 and JS.t(State._zoneGraph)) else 1)
	var playerScroll = max(0, _znTierToY(playerTier, stageH) - (vh * 0.55))
	# Hold briefly, then scroll down and fade banner out as scroll completes
	var _fn12 = func():
		var t0 = [null]
		var step_ = [null]
		t0[0] = null
		var dur = 5000
		var _fn11 = func(ts = null):
			if not JS.t(t0[0]):
				t0[0] = ts
			var p = min((ts - t0[0]) / float(dur), 1)
			overlay.scrollTop = playerScroll * p
			# Fade banner out in the second half of the scroll
			if p > 0.5:
				banner.style.opacity = JS.s(1 - ((p - 0.5) * 2))
			if p < 1:
				JS.requestAnimationFrame(step_[0])
			else:
				banner.remove()
				overlay.style.pointerEvents = ""
				overlay.style.overflowY = "auto"
		step_[0] = _fn11
		JS.requestAnimationFrame(step_[0])
	JS.setTimeout(_fn12, 1400)

func _startNodeEncounter(nodeId = null):
	var node = (JS.find(State._zoneGraph.get("nodes"), func(n = null): return JS.eq(n.id, nodeId)) if JS.t(State._zoneGraph) else State._zoneGraph)
	if not JS.t(node):
		return
	# Disable all node clicks while travelling
	var overlay = document.getElementById("zone-map-overlay")
	if JS.t(overlay):
		overlay.style.pointerEvents = "none"
	var _fn13 = func():
		State._pendingNodeId = nodeId
		if JS.t(overlay):
			overlay.style.pointerEvents = ""
		match node.type:
			"battle":
				BattleLoad.loadBattle(node.get("enc"))
			"campfire":
				ShopCampfire.enterCampfire()
			"shop":
				ShopCampfire.enterShop()
			"rival":
				GymRival.showRivalIntro()
			"gym":
				GymRival.showGymIntro(Helpers.gymIsForced())
	_animTravelToNode(nodeId, _fn13)

func _animTravelToNode(nodeId = null, cb = null):
	var t0 = [null]
	var step_ = [null]
	var overlay = document.getElementById("zone-map-overlay")
	var stage = document.getElementById("zone-map-stage")
	if ((not JS.t(overlay) or not JS.t(stage)) or not JS.t(State._zoneGraph)):
		cb.call()
		return
	# Zone 2+: picking a starting tile — snap wizard to chosen node, no travel animation
	if (State._playerNodeId == (-1) and State.currentGymIdx > 0):
		var tn = JS.find(State._zoneGraph.get("nodes"), func(n = null): return JS.eq(n.id, nodeId))
		if JS.t(tn):
			var sw = JS.or_(overlay.get("clientWidth"), window.innerWidth)
			var sh = (ZN_TIERS * ZN_TIER_H) + (ZN_PAD * 2)
			_znWizardX = _znColToX(tn.get("col"), sw)
			_znWizardY = _znTierToY(tn.get("tier"), sh) - 28
		cb.call()
		return
	var fromNode = (JS.find(State._zoneGraph.get("nodes"), func(n = null): return JS.eq(n.id, State._playerNodeId)) if State._playerNodeId >= 0 else JS.find(State._zoneGraph.get("nodes"), func(n = null): return JS.eq(n.get("tier"), 1)))
	var toNode = JS.find(State._zoneGraph.get("nodes"), func(n = null): return JS.eq(n.id, nodeId))
	if (not JS.t(fromNode) or not JS.t(toNode)):
		cb.call()
		return
	var stageW = JS.or_(overlay.get("clientWidth"), window.innerWidth)
	var stageH = (ZN_TIERS * ZN_TIER_H) + (ZN_PAD * 2)
	var x1 = _znColToX(fromNode.get("col"), stageW)
	var y1 = _znTierToY(fromNode.get("tier"), stageH)
	var x2 = _znColToX(toNode.get("col"), stageW)
	var y2 = _znTierToY(toNode.get("tier"), stageH)
	# Compute the EXACT same bezier control point used when drawing the cobblestone path
	var mx = (x1 + x2) * 0.5
	var my = (y1 + y2) * 0.5
	var dx = x2 - x1
	var dy = y2 - y1
	var dist = JS.or_(sqrt((dx * dx) + (dy * dy)), 1)
	var perp = min(dist * 0.12, 28)
	var side = (1 if (JS.mod((fromNode.id * 7) + (toNode.id * 13), 2)) == 0 else -1)
	var cpx = mx + ((((-dy) / float(dist)) * perp) * side)
	var cpy = my + (((dx / float(dist)) * perp) * side)
	# Quadratic bezier sampler — matches the drawn path exactly
	var _fn14 = func(t = null):
		var mt = 1 - t
		return {
			"x": (((mt * mt) * x1) + (((2 * mt) * t) * cpx)) + ((t * t) * x2),
			"y": (((mt * mt) * y1) + (((2 * mt) * t) * cpy)) + ((t * t) * y2),
		}
	var bezPt = _fn14
	# Scroll destination
	var targetScroll = max(0, y2 - (overlay.clientHeight * 0.55))
	var startScroll = overlay.scrollTop
	var TRAVEL_MS = 700
	t0[0] = null
	var ease_ = func(p = null): return ((2 * p) * p if p < 0.5 else (-1) + ((4 - (2 * p)) * p))
	var _fn15 = func(ts = null):
		if not JS.t(t0[0]):
			t0[0] = ts
		var p = min((ts - t0[0]) / float(TRAVEL_MS), 1)
		var e = ease_.call(p)
		# Follow the bezier curve so wizard stays on the cobblestone path
		var bp = bezPt.call(e)
		_znWizardX = bp.get("x")
		_znWizardY = bp.get("y") - 28
		overlay.scrollTop = startScroll + ((targetScroll - startScroll) * e)
		if p < 1:
			JS.requestAnimationFrame(step_[0])
		else:
			cb.call()
	step_[0] = _fn15
	JS.requestAnimationFrame(step_[0])

# ── Wizard sprite canvas (animated pixel player above current/travelling node) ─
func _znStartWizardAnim(stage = null, W = null, H = null):
	var wc = document.getElementById("zone-wizard-canvas")
	if not JS.t(wc):
		wc = document.createElement("canvas")
		wc.id = "zone-wizard-canvas"
		wc.style.cssText = "position:absolute;top:0;left:0;pointer-events:none;z-index:10;image-rendering:pixelated;image-rendering:crisp-edges;"
		stage.appendChild(wc)
	wc.width = W
	wc.height = H
	wc.style.width = JS.s(W) + "px"
	wc.style.height = JS.s(H) + "px"
	# Snap wizard to current node position
	if (JS.t(State._zoneGraph) and State._playerNodeId >= 0):
		var node = JS.find(State._zoneGraph.get("nodes"), func(n = null): return JS.eq(n.id, State._playerNodeId))
		if JS.t(node):
			_znWizardX = _znColToX(node.get("col"), W)
			_znWizardY = _znTierToY(node.get("tier"), H) - 28
	if JS.t(_znWizardRaf):
		JS.cancelAnimationFrame(_znWizardRaf)
	_znTickWizard()

func _znStopWizardAnim():
	if JS.t(_znWizardRaf):
		JS.cancelAnimationFrame(_znWizardRaf)
		_znWizardRaf = null

func _znTickWizard():
	var wc = document.getElementById("zone-wizard-canvas")
	if not JS.t(wc):
		_znWizardRaf = null
		return
	var W = wc.width
	var H = wc.height
	var ctx = wc.getContext("2d")
	ctx.clearRect(0, 0, W, H)
	if (JS.t(_znWizardX) or JS.t(_znWizardY)):
		Progression._drawMapPlayer(ctx, _znWizardX, _znWizardY, JS.dateNow())
	_znWizardRaf = JS.requestAnimationFrame(_znTickWizard)
