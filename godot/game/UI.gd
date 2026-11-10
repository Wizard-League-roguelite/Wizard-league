# UI — generated from js/rendering/ui.js by tools/js2gd.js
extends Node

# ===============================
# SPELL BUTTONS & TURN UI
# ===============================
var _drawAnimPending = false
var _prevHandSpellIds = null
var _deckModeLayoutActive = false
var _showingItemHand = false
var _ELEM_CARD_COLORS = null
# ── DECK MODE: ARENA OVERLAY RENDERERS ────────────────────────────────────────
# Left panel: always 3 deck slots shown as mini cards
var DECK_SLOT_COUNT = 3

func _boot():
	_prevHandSpellIds = JSSet.new()
	# ── DECK MODE: CARD HAND RENDERER ─────────────────────────────────────────────
	_ELEM_CARD_COLORS = {
		"Fire": "#cc4400",
		"Water": "#1878dd",
		"Ice": "#80d8ee",
		"Lightning": "#ccaa00",
		"Earth": "#7a5810",
		"Nature": "#28a028",
		"Plasma": "#b050c0",
		"Air": "#90c8cc",
		"Neutral": "#666",
	}

# ===== ui.js =====
# ─── UI / RENDERING ───────────────────────────────────────────────────────────
# All DOM render functions. No game logic here.
# renderEnemyCards, renderSpellButtons, updateHPBars, log, showScreen, etc.
func updateStatsUI():
	if JS.hooks.has("updateStatsUI"):
		return JS.run_hook("updateStatsUI", [])
	# Build lives string: filled hearts for remaining, empty for lost
	var maxDisplay = max(State.player.get("revives"), 3)
	var heartsStr = "❤".repeat(State.player.get("revives")) + "🖤".repeat(max(0, maxDisplay - State.player.get("revives")))
	# During combat show effective (status-modified) stats; outside show base
	var inCombat = JS.andf(((true and not JS.t(State.combat.get("over"))) and true), func(): return State.status.get("player"))
	var dispAtk = (Helpers.attackPowerFor("player") if JS.t(inCombat) else State.player.get("attackPower"))
	var dispEfx = (Helpers.effectPowerFor("player") if JS.t(inCombat) else State.player.get("effectPower"))
	var dispDef = (Helpers.defenseFor("player") if JS.t(inCombat) else State.player.get("defense"))
	for prefix in JS.iter(["map", "combat"]):
		var ap = document.getElementById(JS.s(prefix) + "-atk")
		if JS.t(ap):
			ap.textContent = dispAtk
		var ep = document.getElementById(JS.s(prefix) + "-ep")
		if JS.t(ep):
			ep.textContent = dispEfx
		var df = document.getElementById(JS.s(prefix) + "-def")
		if JS.t(df):
			df.textContent = dispDef
		var g = document.getElementById(JS.s(prefix) + "-gold")
		if JS.t(g):
			g.textContent = State.player.get("gold")
		var lh = document.getElementById(JS.s(prefix) + "-lives")
		if JS.t(lh):
			lh.textContent = heartsStr
	var mi = document.getElementById("map-items")
	if JS.t(mi):
		mi.textContent = len(State.player.get("inventory"))
	# Deck mode stats panel
	var dsp = document.getElementById("deck-stats-panel")
	if JS.t(dsp):
		dsp.style.display = "flex"
		var _e = func(id = null): return document.getElementById(id)
		var a = _e.call("dsp-atk")
		if JS.t(a):
			a.textContent = dispAtk
		var e = _e.call("dsp-efx")
		if JS.t(e):
			e.textContent = dispEfx
		var d = _e.call("dsp-def")
		if JS.t(d):
			d.textContent = dispDef
		var g = _e.call("dsp-gold")
		if JS.t(g):
			g.textContent = JS.s(State.player.get("gold")) + "g"
		var l = _e.call("dsp-lives")
		if JS.t(l):
			l.textContent = heartsStr
		# Position above the deck slots — bottom edge at ~50% of arena height
		var _arena2 = document.getElementById("battle-canvas")
		var _arenaEl = (_arena2.get("parentElement") if JS.t(_arena2) else _arena2)
		var arenaH = (_arenaEl.offsetHeight if JS.t(_arenaEl) else 0)
		dsp.style.bottom = JS.s(JS.round(arenaH * 0.5) + 30) + "px"
		dsp.style.top = ""
		# Position passives above HUD
		var hud2 = document.getElementById("arena-player-hud")
		var passives = document.getElementById("arena-passives")
		if (JS.t(hud2) and JS.t(passives)):
			passives.style.bottom = JS.s((JS.or_(hud2.get("offsetHeight"), 44)) + 11) + "px"
	elif JS.t(dsp):
		dsp.style.display = "none"

func _repositionDeckSwitcher():
	var hud = document.getElementById("arena-player-hud")
	var passives = document.getElementById("arena-passives")
	var deckSw = document.getElementById("arena-deck-switcher")
	if (not JS.t(hud) or not JS.t(deckSw)):
		return
	var hudH = JS.or_(hud.get("offsetHeight"), 44)
	var passBottom = hudH + 11
	var passH = (JS.or_(passives.get("offsetHeight"), 0) if JS.t(passives) else 0)
	deckSw.style.bottom = JS.s(passBottom + (passH + 8 if passH > 0 else 0)) + "px"

# ===============================
# UI HELPERS
# ===============================
func renderEnemyCards():
	if JS.hooks.has("renderEnemyCards"):
		return JS.run_hook("renderEnemyCards", [])
	var hud = document.getElementById("arena-enemy-hud")
	if not JS.t(hud):
		return
	hud.innerHTML = ""
	var count = len(JS.or_(State.combat.get("enemies"), []))
	var scl = (1.0 if count <= 1 else (0.95 if count == 2 else (0.85 if count == 3 else (0.74 if count == 4 else 0.64))))
	var pad = ("4px 7px 3px" if count <= 2 else ("3px 5px 2px" if count <= 3 else "2px 4px 2px"))
	var fs = func(b = null): return JS.toFixed(b * scl, 2) + "rem"
	hud.style.setProperty("--cfs", JS.toFixed(scl, 3))
	# For deck mode: get canvas dimensions to position cards under sprites
	var _canvas = document.getElementById("battle-canvas")
	var _canvasW = (_canvas.offsetWidth if JS.t(_canvas) else 0)
	var _canvasH = (_canvas.offsetHeight if JS.t(_canvas) else 0)
	var _isDeck = true
	var _arr1 = JS.iter(JS.or_(State.combat.get("enemies"), []))
	for i in range(len(_arr1)):
		var e = _arr1[i]
		var pct = max(0, (e.get("hp") / float(e.get("enemyMaxHP"))) * 100)
		var card = document.createElement("div")
		card.className = "arena-enemy-card" + (" targeted" if JS.eq(i, State.combat.get("targetIdx")) else "") + ("" if JS.t(e.get("alive")) else " dead")
		card.dataset.idx = i
		card.style.padding = pad
		# In deck mode, position each card below its sprite
		if (_isDeck and _canvasW > 0):
			var ep = Sprites.enemySpritePos(i, State.combat.get("enemies"), _canvasW, _canvasH)
			card.style.left = JS.s(JS.add(ep.get("x"), ep.get("w") / 2.0)) + "px"
			card.style.top = JS.s(JS.add(JS.add(ep.get("y"), ep.get("h")), 6)) + "px"
			card.style.minWidth = "110px"
		if JS.t(e.get("alive")):
			var _fn2 = func():
				State.combat.targetIdx = i
				State.setActiveEnemy(i)
				renderEnemyCards()
				Combat.updateActionUI()
			card.onclick = _fn2
		# Build passive list: primary + extra passives
		var el = Helpers.primaryElement(JS.or_(e.get("element"), ""))
		var passivePool = JS.or_(JS.idx(Passives.PASSIVE_CHOICES, el), [])
		var allPassiveIds = JS.filter([e.get("passive")] + JS.arr(JS.or_(e.get("extraPassives"), [])), JS.t)
		var passiveObjs = JS.arr(allPassiveIds).map(func(id = null): return JS.orf(JS.find(passivePool, func(p = null): return JS.eq(p.id, id)), func(): return {"id": id, "title": id, "desc": ""}))
		# Build all queued intents as inline badges
		var intentBadges = ""
		if ((JS.t(e.get("alive")) and JS.t(e.get("intentQueue"))) and len(e.get("intentQueue")) > 0):
			var _fn3 = func(intent = null, ii = null):
				if JS.t(intent.get("hidden")):
					return "<span style=\"font-size:" + JS.s(fs.call(0.46)) + ";color:#554466;font-family:'Cinzel',serif;\n            background:#110022;border:1px solid #2a1040;border-radius:3px;padding:1px 4px;\n            " + ("font-weight:bold;" if JS.eq(ii, 0) else "opacity:.6;") + "\">???</span>"
				var isCurrent = JS.eq(ii, 0)
				var isCharge = JS.includes(intent.get("label"), "⚡")
				var color = ("#ffcc44" if isCharge else ("#e0c0ff" if isCurrent else "#886aa0"))
				var bg = ("#2a1800" if isCharge else ("#1a0030" if isCurrent else "#0e0018"))
				var border = ("#aa7700" if isCharge else ("#7040cc" if isCurrent else "#221040"))
				var hintBody = ((JS.callm(intent, "hintFn", []) if JS.t(intent.get("hintFn")) else intent.get("hint")) if (not JS.t(State.player.get("_mistBlindDamage")) and (JS.t(intent.get("hintFn")) or JS.t(intent.get("hint")))) else "")
				var hintTip = (JS.s(intent.get("label")) + "\n" + JS.s(hintBody) if JS.t(hintBody) else intent.get("label"))
				return "<span style=\"font-size:" + JS.s(fs.call(0.46)) + ";color:" + color + ";font-family:'Cinzel',serif;\n          background:" + bg + ";border:1px solid " + border + ";border-radius:3px;padding:1px 4px;white-space:nowrap;\n          " + ("font-weight:bold;" if isCurrent else "opacity:.65;") + "\"\n          title=\"" + JS.s(hintTip) + "\">" + ("▶ " if isCurrent else "") + JS.s(intent.get("label")) + "</span>"
			intentBadges = JS.join(JS.map(e.get("intentQueue"), _fn3), "")
		# Passives + items as emoji-only with tooltip
		var passiveBadges = JS.join(JS.arr(passiveObjs).map(func(p = null): return "<span style=\"cursor:help;opacity:.7;display:inline-flex;align-items:center;\" title=\"" + JS.s(JS.or_(p.get("title"), p.get("id"))) + ": " + JS.replace(((JS.or_(p.get("desc"), "")) + " " + (JS.or_(p.get("detail"), ""))).strip_edges(), JS.re("\"", "g"), "'") + "\">" + PassiveIcons.passiveIconSVG(p, 14) + "</span>"), "")
		var itemBadges = JS.join(JS.arr(JS.or_(e.get("items"), [])).map(func(it = null): return "<span style=\"cursor:help;opacity:.7;font-size:" + JS.s(fs.call(0.5)) + ";\" title=\"" + JS.s(it.get("name")) + "\">" + JS.s(it.get("emoji")) + "</span>"), "")
		var badges = passiveBadges + itemBadges
		card.innerHTML = "\n      <div style=\"display:flex;align-items:center;gap:3px;justify-content:space-between;\">\n        <div class=\"arena-hud-name\" style=\"display:flex;align-items:center;gap:3px;min-width:0;overflow:hidden;white-space:nowrap;\">" + Encounters.elemHatSVG(JS.or_(e.get("element"), "Neutral"), 11) + " <span style=\"overflow:hidden;text-overflow:ellipsis;\">" + JS.s(e.get("name")) + "</span></div>\n        " + ("<div style=\"display:flex;gap:2px;flex-shrink:0;\">" + badges + "</div>" if JS.t(badges) else "") + "\n      </div>\n      <div style=\"margin-top:2px;\">\n        <div class=\"arena-hud-hp-wrap\" style=\"width:100%;margin-bottom:2px;\"><div class=\"arena-hud-hp-fill\" style=\"width:" + JS.s(pct) + "%;background:" + hpColor(pct) + "\"></div></div>\n        <div class=\"arena-hud-hp-text\" style=\"white-space:nowrap;\">" + JS.s(e.get("hp")) + "/" + JS.s(e.get("enemyMaxHP")) + "</div>\n      </div>\n      <div class=\"arena-hud-status\" id=\"estatus-" + JS.s(i) + "\" style=\"margin-top:2px;\"></div>\n    "
		hud.appendChild(card)
	# Status tags per enemy
	var _mistHPPct = JS.round(((JS.or_(State.player.get("_mistEnemyHPMult"), 1)) - 1) * 100)
	var _arr4 = JS.iter(JS.or_(State.combat.get("enemies"), []))
	for i in range(len(_arr4)):
		var e = _arr4[i]
		var row = document.getElementById("estatus-" + JS.s(i))
		if not JS.t(row):
			continue
		var s = e.get("status")
		if s.get("burnStacks") > 0:
			var v = JS.round(s.get("burnStacks"))
			row.appendChild(tag("🔥" + JS.s(v), "tag-burn", "Burn ×" + JS.s(v) + " — deals " + JS.s(v) + " dmg/turn"))
		if s.get("stunned") > 0:
			row.appendChild(tag("❄" + JS.s(s.get("stunned")) + "t", "tag-stun", "Stunned — skips " + JS.s(s.get("stunned")) + " turn(s)"))
		if s.get("rootStacks") > 0:
			var v = JS.round(s.get("rootStacks"))
			row.appendChild(tag("🌿" + JS.s(v), "tag-root", "Root ×" + JS.s(v) + " — takes +" + JS.s(v * Constants.ROOT_POWER_PER_STACK) + " bonus damage"))
		if s.get("overgrowthStacks") > 0:
			var v = JS.round(s.get("overgrowthStacks"))
			row.appendChild(tag("🌿G" + JS.s(v), "tag-root", "Overgrowth ×" + JS.s(v) + " — +" + JS.s(v * Constants.ROOT_POWER_PER_STACK) + " bonus damage"))
		if s.get("foamStacks") > 0:
			var v = floori(s.get("foamStacks"))
			row.appendChild(tag("🫧" + JS.s(v), "tag-block", "Foam ×" + JS.s(v) + " — -" + JS.s(floori(v * 1.5)) + " Defense (less Armor gained; at negative Defense, enemy hits deal bonus damage)"))
		if s.get("shockStacks") > 0:
			var v = JS.round(s.get("shockStacks"))
			row.appendChild(tag("⚡" + JS.s(v), "tag-stun", "Shock ×" + JS.s(v) + " — reduces outgoing damage by " + JS.s(v * 5) + "%"))
		if s.get("block") > 0:
			var v = JS.round(s.get("block"))
			row.appendChild(tag("🛡" + JS.s(v), "tag-block", "Armor " + JS.s(v) + " — absorbs " + JS.s(v) + " damage"))
		if s.get("phaseTurns") > 0:
			row.appendChild(tag("🔮", "tag-phase", "Phase — immune to damage for " + JS.s(s.get("phaseTurns")) + " turn(s)"))
		if s.get("frostStacks") > 0:
			var v = JS.round(s.get("frostStacks"))
			row.appendChild(tag("❄️" + JS.s(v), "tag-stun", "Frost ×" + JS.s(v) + " — -" + JS.s(v) + " ATK/Armor"))
		if s.get("stoneStacks") > 0:
			var v = floori(s.get("stoneStacks"))
			row.appendChild(tag("🪨" + JS.s(v), "tag-block", "Stone ×" + JS.s(v) + " — +" + JS.s(v * 3) + " ATK, +" + JS.s(v * 2) + " Armor"))
		# Mist HP bonus: undispellable indicator
		if _mistHPPct > 0:
			var t = tag("🌫+" + JS.s(_mistHPPct) + "%HP", "tag-block", "Mist — The Veil grants this enemy +" + JS.s(_mistHPPct) + "% max HP (cannot be removed)")
			t.style.opacity = ".7"
			row.appendChild(t)
	renderEnemyIntentOverlay()
	Sprites.renderBattlefield()

func renderEnemyIntentOverlay():
	var overlay = document.getElementById("enemy-intent-overlay")
	if not JS.t(overlay):
		return
	overlay.innerHTML = ""

func renderSummonsRow():
	if JS.hooks.has("renderSummonsRow"):
		return JS.run_hook("renderSummonsRow", [])
	var col = document.getElementById("arena-summons")
	if not JS.t(col):
		return
	col.innerHTML = ""
	if (not JS.t(State.combat.get("summons")) or len(State.combat.get("summons")) == 0):
		Sprites.renderBattlefield()
		return
	for s in JS.iter(State.combat.get("summons")):
		if s.get("hp") <= 0:
			continue
		var card = document.createElement("div")
		card.className = "arena-summon-card"
		var pct = JS.round((s.get("hp") / float(s.get("maxHP"))) * 100)
		card.textContent = JS.s(s.get("emoji")) + " " + JS.s(s.get("name")) + " " + JS.s(s.get("hp")) + "/" + JS.s(s.get("maxHP"))
		col.appendChild(card)
	Sprites.renderBattlefield()

func updateHPBars():
	if JS.hooks.has("updateHPBars"):
		return JS.run_hook("updateHPBars", [])
	var pMax = Helpers.maxHPFor("player")
	var pPct = max(0, (State.player.get("hp") / float(pMax)) * 100)
	# Player HUD
	var fill = document.getElementById("player-hud-hp-fill")
	if JS.t(fill):
		fill.style.width = JS.s(pPct) + "%"
		fill.style.background = hpColor(pPct)
	var txt = document.getElementById("player-hp-text")
	if JS.t(txt):
		txt.textContent = JS.s(max(0, State.player.get("hp"))) + " / " + JS.s(pMax)
	var nm = document.getElementById("player-hud-name")
	if JS.t(nm):
		nm.textContent = State.playerName
	# Mist badge
	var mb = document.getElementById("mist-badge")
	if JS.t(mb):
		var mist = Mist.getTotalMist()
		if mist > 0:
			mb.textContent = "🌫 " + JS.s(mist) + " Mist"
			mb.style.display = ""
		else:
			mb.style.display = "none"
	renderEnemyCards()
	# also redraws canvas
	renderSummonsRow()

func renderStatusTags():
	if JS.hooks.has("renderStatusTags"):
		return JS.run_hook("renderStatusTags", [])
	var pr = document.getElementById("player-status-row")
	if JS.t(pr):
		pr.innerHTML = ""
		var s = State.status.get("player")
		if s.get("burnStacks") > 0:
			var v = JS.round(s.get("burnStacks"))
			pr.appendChild(tag("🔥" + JS.s(v), "tag-burn", "Burn ×" + JS.s(v) + " — deals " + JS.s(v) + " dmg/turn (1 per stack)"))
		if s.get("stunned") > 0:
			pr.appendChild(tag("❄" + JS.s(s.get("stunned")) + "t", "tag-stun", "Stunned — skip " + JS.s(s.get("stunned")) + " turn(s)"))
		if s.get("rootStacks") > 0:
			var v = JS.round(s.get("rootStacks"))
			pr.appendChild(tag("🌿" + JS.s(v), "tag-root", "Root ×" + JS.s(v) + " — you take +" + JS.s(v * Constants.ROOT_POWER_PER_STACK) + " bonus damage from attacks"))
		if s.get("overgrowthStacks") > 0:
			var v = JS.round(s.get("overgrowthStacks"))
			pr.appendChild(tag("🌿G" + JS.s(v), "tag-root", "Overgrowth ×" + JS.s(v) + " — enhanced root, +" + JS.s(v * Constants.ROOT_POWER_PER_STACK) + " bonus damage"))
		if s.get("foamStacks") > 0:
			var v = floori(s.get("foamStacks"))
			pr.appendChild(tag("🫧" + JS.s(v), "tag-block", "Foam ×" + JS.s(v) + " — -" + JS.s(floori(v * 1.5)) + " Defense (less Armor gained; at negative Defense, enemy hits deal bonus damage)"))
		if s.get("shockStacks") > 0:
			var v = JS.round(s.get("shockStacks"))
			pr.appendChild(tag("⚡" + JS.s(v), "tag-stun", "Shock ×" + JS.s(v) + " — reduces your outgoing damage by " + JS.s(v * 5) + "%"))
		if s.get("block") > 0:
			var v = JS.round(s.get("block"))
			pr.appendChild(tag("🛡" + JS.s(v), "tag-block", "Armor " + JS.s(v) + " — absorbs " + JS.s(v) + " incoming damage"))
		if s.get("phaseTurns") > 0:
			pr.appendChild(tag("🔮", "tag-phase", "Phase — immune to damage for " + JS.s(s.get("phaseTurns")) + " turn(s)"))
		if s.get("frostStacks") > 0:
			var v = JS.round(s.get("frostStacks"))
			pr.appendChild(tag("❄️" + JS.s(v), "tag-stun", "Frost ×" + JS.s(v) + " — -" + JS.s(v) + " ATK/EFX/Armor; at 10 stacks: Frozen (stunned)"))
		if s.get("stoneStacks") > 0:
			var v = floori(s.get("stoneStacks"))
			pr.appendChild(tag("🪨" + JS.s(v), "tag-block", "Stone ×" + JS.s(v) + " — +" + JS.s(v * 3) + " ATK, +" + JS.s(v * 2) + " Armor; decays 25%/turn"))
		# Plasma
		if JS.eq(State.playerElement, "Plasma"):
			if JS.t(s.get("stallActive")):
				pr.appendChild(tag("🫧 Stall", "tag-phase", "Stall — enemy action delayed, charge refunded next turn"))
			if s.get("borrowedCharge") > 0:
				pr.appendChild(tag("⏳" + JS.s(s.get("borrowedCharge")) + "debt", "tag-burn", "Borrowed Charge — " + JS.s(s.get("borrowedCharge")) + " charge debt to repay"))
			if s.get("plasmaShieldReduction") > 0:
				pr.appendChild(tag("🛡" + JS.s(s.get("plasmaShieldReduction")) + "%", "tag-block", "Plasma Shield — " + JS.s(s.get("plasmaShieldReduction")) + "% incoming damage reduced"))
			if JS.t(State.combat.get("plasmaOvercharged")):
				pr.appendChild(tag("✦ OC", "tag-phase", "Overcharged — next plasma cast has bonus power"))
		# Air: Momentum
		if JS.eq(State.playerElement, "Air"):
			if (JS.or_(s.get("momentumStacks"), 0)) > 0:
				pr.appendChild(tag("💨" + JS.s(floori(s.get("momentumStacks"))) + "M", "tag-phase", "Momentum ×" + JS.s(floori(s.get("momentumStacks"))) + " — +" + JS.s(floori(s.get("momentumStacks"))) + " ATK, +" + JS.s(floori(s.get("momentumStacks")) * 2) + "% dodge; decays each turn"))
			if JS.t(s.get("windWallActive")):
				pr.appendChild(tag("🛡️WW", "tag-block", "Wind Wall — blocks next instance of damage"))
			if JS.t(s.get("tornadoAoENext")):
				pr.appendChild(tag("🌪️AoE", "tag-phase", "Tornado AoE — next attack hits all enemies"))
	renderEnemyCards()

func tag(text = null, cls = null, tooltip = null):
	var t = document.createElement("span")
	t.className = "status-tag " + JS.s(cls)
	t.textContent = text
	if JS.t(tooltip):
		t.title = tooltip
		t.style.cursor = "help"
	return t

func hpColor(pct = null):
	return ("#3a8a3a" if pct > 50 else ("#8a7a1a" if pct > 25 else "#8a2a2a"))

func log_(msg = null, type_ = null):
	if JS.hooks.has("log"):
		return JS.run_hook("log", [msg, type_])
	if type_ == null:
		type_ = ""
	var el = document.getElementById("battle-log")
	if not JS.t(el):
		return
	var line = document.createElement("div")
	line.className = "log-line " + JS.s(type_)
	line.textContent = msg
	el.appendChild(line)
	# Only auto-scroll if log tab is active
	if JS.eq(MapLogic._activeCombatTab, "log"):
		el.scrollTop = el.scrollHeight
	# Badge the log tab when not visible
	if not JS.eq(MapLogic._activeCombatTab, "log"):
		MapLogic._logHasNew = true
		MapLogic._updateLogBadge(true)

func showScreen(id = null):
	# Stop lobby map when navigating away from between-runs
	if not JS.eq(id, "between-runs-screen"):
		LobbyMap.stopLobbyMap()
	# Stop zone wizard animation when leaving map
	if not JS.eq(id, "map-screen"):
		MapCanvas._znStopWizardAnim()
	# Stop any running game over / victory animation
	var goCanvas = document.getElementById("gameover-canvas")
	if (JS.t(goCanvas) and JS.t(goCanvas.get("_goStop"))):
		JS.callm(goCanvas, "_goStop", [])
	var vcCanvas = document.getElementById("victory-canvas")
	if (JS.t(vcCanvas) and JS.t(vcCanvas.get("_vcStop"))):
		JS.callm(vcCanvas, "_vcStop", [])
	for s in JS.iter(document.querySelectorAll(".screen")):
		s.classList.remove("active")
	document.getElementById(id).classList.add("active")
	# Music transitions — zone-aware
	Music._tryResumeAudio.call()
	var _zone = (State.currentZoneElement if (true and JS.t(State.currentZoneElement)) else State.playerElement)
	var _menuScreens = [
		"title-screen",
		"save-select-screen",
		"hub-screen",
		"element-screen",
		"passive-screen",
		"between-runs-screen",
		"character-screen",
	]
	if JS.eq(id, "combat-screen"):
		Mp3Audio.musicPlaySmart(("battle_" + JS.s(_zone) if JS.t(_zone) else "battle_Fire"))
	elif JS.includes(["map-screen", "campfire-screen", "shop-screen", "gym-screen", "rival-screen"], id):
		Mp3Audio.musicPlaySmart("map")
	elif JS.includes(_menuScreens, id):
		Mp3Audio.musicPlaySmart("menu")
	elif JS.eq(id, "run-victory-screen"):
		Mp3Audio.musicPlaySmart("menu")
	elif JS.eq(id, "between-runs-screen"):
		Mp3Audio.musicStopAll()

func restartToSelect():
	JS.assign(State.player, [{
		"hp": Constants.BASE_MAX_HP,
		"attackPower": 0,
		"effectPower": 0,
		"defense": 0,
		"skillPoints": 0,
		"gold": 0,
		"inventory": [],
		"spellbook": [],
		"passives": [],
		"startPassive": null,
		"unlockedElements": [],
		"baseMaxHPBonus": 0,
		"spellbooks": [],
		"activeBookIdx": 0,
		"revives": 0,
		"bonusActions": 0,
		"basicUpgrade": 0,
		"basicDmgMult": 1.0,
		"_hasteStart": false,
		"_blockStart": 0,
		"_extraStartSpell": false,
		"_rerolls": 0,
	}])
	JS.assign(State.combat, [{
		"enemies": [],
		"targetIdx": 0,
		"activeEnemyIdx": 0,
		"enemy": {},
		"enemyHP": 0,
		"playerTurn": false,
		"over": false,
		"tempDmgBonus": 0,
		"actionsLeft": 0,
		"basicCD": 0,
		"playerAirToggle": false,
		"enemyAirToggle": false,
		"actionQueue": [],
		"summons": [],
		"totalGold": 0,
	}])
	State.battleNumber = 1
	State.currentGymIdx = 0
	State.zoneBattleCount = 0
	State.gymSkips = 0
	State.gymDefeated = false
	State.pendingLevelUps = []
	State._zoneGraph = null
	State._playerNodeId = -1
	State._completedNodeIds = JSSet.new()
	State._pendingNodeId = -1
	State._zoneIntroPlayed = false
	State._runDmgDealt = 0
	State._runDmgTaken = 0
	State._runRoomsCompleted = 0
	State._runZoneReached = ""
	State._runKillsThisRun = 0
	Constants.sandboxMode = false
	Encounters.GYM_ROSTER.clear()
	Main.showHub()

func backToElementSelectFromPassive__superseded_UI():
	window.pendingStartPassive = null
	Main.showElementScreen()

func promptAbandon():
	document.getElementById("confirm-modal").classList.add("open")

func closeModal():
	document.getElementById("confirm-modal").classList.remove("open")

func confirmAbandon():
	closeModal()
	BetweenRuns._lastRunPhos = Artifacts.saveRunStats()
	Analytics.sendRunAnalytics("abandoned")
	BetweenRuns.showBetweenRuns()

func setPlayerTurnUI(isPlayerTurn = null):
	State.combat.playerTurn = isPlayerTurn
	var endBtn = document.getElementById("end-turn-btn")
	var invBtn = document.getElementById("inv-toggle-btn")
	if JS.t(endBtn):
		endBtn.disabled = (not JS.t(isPlayerTurn))
	if JS.t(invBtn):
		invBtn.disabled = (not JS.t(isPlayerTurn))
	if JS.t(isPlayerTurn):
		_drawAnimPending = true
	renderSpellButtons()
	Combat.renderQueue()
	Combat.updateActionUI()

func basicSpellDamagePreview():
	var dmg = JS.round(((Constants.BASE_DMG + State.combat.get("tempDmgBonus")) + (JS.or_(State.player.get("basicDmgFlat"), 0))) * (JS.or_(State.player.get("basicDmgMult"), 1.0)))
	return JS.s(dmg) + "+P"

func doBasicAttack(ctx = null):
	var _elemBasicFlag = {
		"Fire": "_elementalBasicFire",
		"Water": "_elementalBasicWater",
		"Ice": "_elementalBasicIce",
		"Earth": "_elementalBasicEarth",
		"Nature": "_elementalBasicNature",
		"Lightning": "_elementalBasicLightning",
		"Plasma": "_elementalBasicPlasma",
		"Air": "_elementalBasicAir",
	}
	var basicLevel = JS.or_(JS.idx(State.player, JS.or_(JS.idx(_elemBasicFlag, State.playerElement), "")), 0)
	# 0=off, 1-5=tier
	var hasElemBasicActive = basicLevel > 0
	# Damage scales with level: +10 base, +3 per level above 1
	var elemDmgBonus = (10 + Incantations._incantationBonus(basicLevel, 3, 0.95) if hasElemBasicActive else 0)
	var dmg = JS.round((((Constants.BASE_DMG + (JS.or_(State.combat.get("tempDmgBonus"), 0))) + (JS.or_(State.player.get("basicDmgFlat"), 0))) + elemDmgBonus) * (JS.or_(State.player.get("basicDmgMult"), 1.0)))
	# Burn stacks for Fire scale with level
	var burnStacks = (JS.round(2 + Incantations._incantationBonus(basicLevel, 1, 0.9)) if hasElemBasicActive else 0)
	var elemEffects = ([{"type": "burn", "stacks": burnStacks}] if (hasElemBasicActive and JS.eq(State.playerElement, "Fire")) else [])
	var _basicNames = {
		"Fire": "Ember Strike",
		"Water": "Tidal Jab",
		"Ice": "Frost Jab",
		"Earth": "Stone Fist",
		"Nature": "Vine Whip",
		"Lightning": "Spark Strike",
		"Plasma": "Surge Bolt",
		"Air": "Gust Slash",
	}
	var _basicIcons = {
		"Fire": "🔥",
		"Water": "💧",
		"Ice": "❄️",
		"Earth": "🪨",
		"Nature": "🌿",
		"Lightning": "⚡",
		"Plasma": "🔮",
		"Air": "💨",
	}
	var _basicLabel = ((JS.or_(JS.idx(_basicIcons, State.playerElement), "⚔")) + " " + (JS.or_(JS.idx(_basicNames, State.playerElement), "Basic Attack")) if hasElemBasicActive else "⚔ Basic Attack")
	JS.callm(ctx, "hit", [{
		"baseDamage": dmg,
		"effects": elemEffects,
		"isBasic": true,
		"abilityElement": State.playerElement,
		"label": _basicLabel,
	}])
	if (JS.t(State.combat.get("over")) or not hasElemBasicActive):
		return
	# Post-hit elemental procs — all scale with basicLevel via _incantationBonus
	var _ib = func(base = null, scale_ = null, decay = null): return base + Incantations._incantationBonus(basicLevel, scale_, decay)
	if JS.eq(State.playerElement, "Water"):
		Helpers.applyFoam("player", "enemy", JS.round(_ib.call(1, 0.5, 0.9)))
	if JS.eq(State.playerElement, "Ice"):
		Helpers.applyFrost("player", "enemy", _ib.call(1, 0.5, 0.9))
	if JS.eq(State.playerElement, "Earth"):
		Helpers.addStoneStacks("player", JS.round(_ib.call(1, 0.5, 0.9)))
	if JS.eq(State.playerElement, "Nature"):
		Helpers.applyRoot("player", "enemy", JS.round(_ib.call(1, 0.5, 0.9)))
	if JS.eq(State.playerElement, "Lightning"):
		var extraShock = JS.round(_ib.call(1, 0.5, 0.9) * (1 + (Helpers.effectPowerFor("player") / 50.0)))
		State.status.get("enemy").shockStacks = (JS.or_(State.status.get("enemy").get("shockStacks"), 0)) + extraShock
		log_("⚡ Spark Strike: +" + JS.s(extraShock) + " extra Shock (×" + JS.s(State.status.get("enemy").get("shockStacks")) + ")", "status")
	if JS.eq(State.playerElement, "Plasma"):
		var charge = JS.round(_ib.call(2, 1, 1.0))
		State.status.get("player").plasmaCharge = min((JS.or_(State.status.get("player").get("plasmaCharge"), 0)) + charge, 20)
		Spells.updateChargeUI()
		log_("🔮 Surge Bolt: +" + JS.s(charge) + " Charge (" + JS.s(State.status.get("player").get("plasmaCharge")) + " total)", "player")
	if JS.eq(State.playerElement, "Air"):
		Helpers.addMomentumStacks(JS.round(_ib.call(1, 1, 1.0)))

# ── Spell damage preview for tooltips ────────────────────────────────────────
func _spellDmgPreview(spell = null):
	if (not JS.t(spell) or not JS.t(spell.get("execute"))):
		return ""
	var src = JS.s(spell.get("execute"))
	var atk = null
	var efx = null
	var def = null
	atk = Helpers.attackPowerFor("player")
	efx = Helpers.effectPowerFor("player")
	def = Helpers.defenseFor("player")
	var mult = JS.or_(spell.get("dmgMult"), 1.0)
	# Special cases: spells whose damage doesn't follow simple baseDamage+ATK
	match spell.id:
		"zap":
			var b = 25 + floori(atk / 10.0)
			return "~" + JS.s(JS.round((b + atk) * mult)) + " dmg"
		"echo_slam":
			var n = JS.or_(len(Helpers.aliveEnemies()), 1)
			return "~" + JS.s(JS.round(((5 * n) + atk) * mult)) + " dmg to all (" + JS.s(n) + " × 5 base)"
		"earthshaker":
			return "~" + JS.s(atk * 3) + " dmg (ATK × 3)"
		"tidal_surge":
			return "~" + JS.s(JS.round((20 + atk) * mult)) + " dmg · heals ~" + JS.s(10 + ceili(def / 2.0)) + " HP"
		"vampiric_strike":
			var d = JS.round((30 + atk) * mult)
			return "~" + JS.s(d) + " dmg · heals ~" + JS.s(JS.round(d * 0.4)) + " HP"
		"tidal_shield":
			return "+" + JS.s(20 + floori(def / 2.0)) + " armor"
		"seismic_wave":
			return "~" + JS.s(JS.round((20 + atk) * mult)) + " dmg · -5 enemy armor, +5 armor"
		"shatter":
			var e2 = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
			if (JS.t(e2) and JS.t(e2.get("status").get("frozen"))):
				return "~" + JS.s(JS.round(((40 + floori(atk / 5.0)) + atk) * mult)) + " dmg (Frozen target)"
			var fr = (JS.or_(e2.get("status").get("frostStacks"), 0) if JS.t(e2) else 0)
			return (JS.s(fr) + " Frost × 4 = " + JS.s(fr * 4) + " dmg, clears Frost" if fr > 0 else "vs Frozen: ~40+ATK | vs Frosted: Frost×4")
		"blitz":
			var e2 = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
			var sh = (JS.or_(e2.get("status").get("shockStacks"), 0) if JS.t(e2) else 0)
			var hpow = max(1, floori(atk / 2.0))
			return (JS.s(sh) + " Shock × " + JS.s(hpow) + " = " + JS.s(sh * hpow) + " dmg" if sh > 0 else "Shock stacks × ATK÷2 dmg")
		"cataclysm":
			var st = JS.or_(State.status.get("player").get("stoneStacks"), 0)
			return (JS.s(st) + " Stone × 25 = " + JS.s(st * 25) + " dmg to all" if st > 0 else "X Stone × 25 dmg to all")
		"break_momentum":
			var m = floori(JS.or_(State.status.get("player").get("momentumStacks"), 0))
			return (JS.s(m) + " Momentum × 5 = " + JS.s(m * 5) + " dmg" if m > 0 else "X Momentum × 5 dmg")
		"natures_wrath":
			return "X Root stacks × 20 dmg to all (consumes root)"
		"tsunami":
			return "X Foam stacks × 10 dmg per enemy (consumes foam)"
		"extinguish":
			return "Triggers burn tick + (removed stacks × 2) bonus dmg"
		"fire_heal":
			return "Heals (all burn stacks on field) HP"
		"fire_rage":
			return "+(total burn ÷ 2) ATK for 2 turns"
		"cleanse_current":
			return "Heals (debuffs removed × 20) HP"
		"plasma_lance":
			var ch = JS.or_(State.status.get("player").get("plasmaCharge"), 0)
			return JS.s(ch) + "⚡ → ~" + JS.s(((ch * 5) + atk) + efx) + " dmg (spend×5 + ATK+EFX)"
		"obliteration":
			var ch = JS.or_(State.status.get("player").get("plasmaCharge"), 0)
			return JS.s(ch) + "⚡ → " + JS.s(ch * 2) + " hits × " + JS.s((5 + atk) + efx) + " dmg"
		"energy_infusion":
			return "spend ⚡ → +⚡ Power this battle"
		"plasma_shield":
			return "spend ⚡ → +⚡% damage reduction (max 75%)"
		"self_sacrifice":
			var ch = JS.or_(State.status.get("player").get("plasmaCharge"), 0)
			return JS.s(ch) + "⚡ → " + JS.s(ch * 2) + " hits of 5 self-dmg (each hit generates charge)"
		"borrowed_power":
			return "+10 Charge now — 500 dmg next turn if unpaid"
		"plasma_stall":
			return "Stores " + JS.s(JS.or_(State.status.get("player").get("plasmaCharge"), 0)) + " Charge, immune this turn, regain next"
		"singularity":
			return "Next Plasma ability has doubled effects"
		"chain_lightning":
			return "4 hits × ~" + JS.s(JS.round((5 + atk) * mult)) + " dmg (random enemies)"
		"natures_call":
			return ("Summon Treant (50 HP, 15 dmg, 100% root)" if Main.hasPassive("nature_verdant_legion") else "Summon Treant (25 HP, 5 dmg, 50% root)")
		"living_forest":
			var ts = JS.arr(State.combat.get("summons")).filter(func(t = null): return t.get("hp") > 0)
			return (JS.s(len(ts)) + " Treants × 2 strikes of " + JS.s(JS.idx(ts, 0).get("dmg")) + " dmg" if JS.t(len(ts)) else "Commands all Treants to strike twice")
		"storm_rush":
			return "+3 actions this turn · +5 Momentum · all CDs -1"
		"overcharge":
			return "+3 Shock on target · +30 Power next turn"
		"feedback":
			return "+2 Shock on target · 5 self-dmg · +15 Power next turn"
	# Generic: parse s.hit({baseDamage:X, hits:Y, isAOE:true})
	var hasHit = JS.test(JS.re("\\bs\\.hit\\s*\\(", ""), src)
	var dmgMatch = JS.match_(src, JS.re("baseDamage\\s*:\\s*(\\d+)", ""))
	var hitMatch = JS.match_(src, JS.re("\\bhits\\s*:\\s*(\\d+)", ""))
	var isAOE = (JS.test(JS.re("isAOE\\s*:\\s*true", ""), src) or (JS.includes(src, "aliveEnemies()") and hasHit))
	var noAtk = JS.test(JS.re("_noAtk\\s*:\\s*true", ""), src)
	var parts = []
	if (hasHit and JS.t(dmgMatch)):
		var base = JS.parseInt(JS.idx(dmgMatch, 1))
		var hits = (JS.parseInt(JS.idx(hitMatch, 1)) if JS.t(hitMatch) else 1)
		var perHit = (JS.round(base * mult) if noAtk else JS.round((base + atk) * mult))
		var total = perHit * hits
		parts.append((JS.s(hits) + "× " + JS.s(perHit) + " dmg" if hits > 1 else "~" + JS.s(total) + " dmg"))
		if isAOE:
			parts.append("all")
	# Effect parsing — literal stacks first, then presence-only
	var _burnLit = JS.orf(JS.match_(src, JS.re("type\\s*:\\s*['\"]burn['\"]\\s*[,}][^}]*?stacks\\s*:\\s*(\\d+)", "s")), func(): return JS.match_(src, JS.re("stacks\\s*:\\s*(\\d+)[^}]*type\\s*:\\s*['\"]burn['\"]", "s")))
	var _burnVar = (not JS.t(_burnLit) and (JS.test(JS.re("type\\s*:\\s*['\"]burn['\"]", ""), src) or JS.test(JS.re("applyBurn\\s*\\(", ""), src)))
	if JS.t(_burnLit):
		parts.append("+" + JS.s(JS.idx(_burnLit, 1)) + " Burn🔥")
	elif _burnVar:
		parts.append("Burn🔥")
	var _frostLit = JS.match_(src, JS.re("applyFrost\\s*\\([^,]+,[^,]+,\\s*(\\d+)", ""))
	if JS.t(_frostLit):
		parts.append("+" + JS.s(JS.idx(_frostLit, 1)) + " Frost❄")
	elif JS.test(JS.re("applyFrost\\s*\\(", ""), src):
		parts.append("Frost❄")
	var _rootLit = JS.match_(src, JS.re("applyRoot\\s*\\([^,]+,[^,]+,\\s*(\\d+)", ""))
	if JS.t(_rootLit):
		parts.append("+" + JS.s(JS.idx(_rootLit, 1)) + " Root🌿")
	elif JS.test(JS.re("applyRoot\\s*\\(", ""), src):
		parts.append("Root🌿")
	var _shockLit = JS.match_(src, JS.re("applyShock\\s*\\([^,]+,[^,]+,\\s*(\\d+)", ""))
	if JS.t(_shockLit):
		parts.append("+" + JS.s(JS.idx(_shockLit, 1)) + " Shock⚡")
	elif JS.test(JS.re("applyShock\\s*\\(", ""), src):
		parts.append("Shock⚡")
	var _foamLit = JS.match_(src, JS.re("applyFoam\\s*\\([^,]+,[^,]+,\\s*(\\d+)", ""))
	if JS.t(_foamLit):
		parts.append("+" + JS.s(JS.idx(_foamLit, 1)) + " Foam🫧")
	elif JS.test(JS.re("applyFoam\\s*\\(", ""), src):
		parts.append("Foam🫧")
	var healMatch = JS.match_(src, JS.re("healSelf\\s*\\(\\s*(\\d+)", ""))
	if JS.t(healMatch):
		parts.append("heals " + JS.s(JS.idx(healMatch, 1)) + " HP")
	# Block — require literal integer with closing paren to avoid matching expressions
	var blockMatch = JS.match_(src, JS.re("gainBlock\\s*\\(\\s*['\"]player['\"]\\s*,\\s*(\\d+)\\s*\\)", ""))
	if JS.t(blockMatch):
		parts.append("+" + JS.s(JS.parseInt(JS.idx(blockMatch, 1))) + " Block")
	return JS.join(parts, " · ")

# Reset on new battle so first draw animates all cards
func resetDeckHandTracking():
	_prevHandSpellIds = JSSet.new()
	_showingItemHand = false

func _showAirPriorityPopup(choices = null, onChoose = null):
	var overlay = [null]
	overlay[0] = document.getElementById("air-priority-popup")
	if JS.t(overlay[0]):
		overlay[0].remove()
	overlay[0] = document.createElement("div")
	overlay[0].id = "air-priority-popup"
	overlay[0].style.cssText = "position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.6);z-index:1000;display:flex;align-items:center;justify-content:center;"
	var box = document.createElement("div")
	box.style.cssText = "background:#1a1a2e;border:1px solid #4a4a6a;border-radius:8px;padding:18px 22px;display:flex;flex-direction:column;gap:10px;min-width:180px;"
	var title = document.createElement("div")
	title.textContent = "Choose priority shift"
	title.style.cssText = "color:#aaa;font-size:.85rem;text-align:center;margin-bottom:2px;"
	box.appendChild(title)
	for ch in JS.iter(choices):
		var btn = document.createElement("button")
		btn.textContent = ch.get("label")
		btn.style.cssText = "padding:9px;background:#2a2a3e;border:1px solid #5a5a8a;color:#fff;border-radius:5px;cursor:pointer;font-size:1rem;"
		var _fn5 = func():
			btn.style.borderColor = "#9a9acf"
		btn.onmouseenter = _fn5
		var _fn6 = func():
			btn.style.borderColor = "#5a5a8a"
		btn.onmouseleave = _fn6
		var _fn7 = func():
			overlay[0].remove()
			onChoose.call(ch.value)
		btn.onclick = _fn7
		box.appendChild(btn)
	var cancel = document.createElement("button")
	cancel.textContent = "Cancel"
	cancel.style.cssText = "padding:5px;background:transparent;border:1px solid #444;color:#666;border-radius:4px;cursor:pointer;font-size:.8rem;"
	cancel.onclick = func(): return overlay[0].remove()
	box.appendChild(cancel)
	overlay[0].appendChild(box)
	document.body.appendChild(overlay[0])

func renderSpellButtons():
	var grid = document.getElementById("spell-grid")
	if not JS.t(grid):
		return
	var isMyTurn = ((not JS.t(State.combat.get("over"))) if JS.t(State.combat.get("playerTurn")) else State.combat.get("playerTurn"))
	var nonFreeQueued = len(JS.arr(JS.or_(State.combat.get("actionQueue"), [])).filter(func(a = null): return (not JS.t(a.get("isFree")) and not JS.t(a.get("isPlasma")))))
	var queueFull = nonFreeQueued >= (JS.or_(State.combat.get("actionsLeft"), 0))
	# Storm Rush preview: if it's queued, show all spell CDs as 1 lower
	var stormRushQueued = JS.some(JS.or_(State.combat.get("actionQueue"), []), func(a = null): return JS.t(a.get("stormRushAction")))
	var cdPreviewReduce = (1 if stormRushQueued else 0)
	# ── Populate book tab bar ────────────────────────────────────────────────
	var bookTabBar = document.getElementById("sb-book-tabs")
	if JS.t(bookTabBar):
		bookTabBar.innerHTML = ""
		if (JS.t(State.player.get("spellbooks")) and len(State.player.get("spellbooks")) > 1):
			var _arr8 = JS.iter(State.player.get("spellbooks"))
			for i in range(len(_arr8)):
				var book = _arr8[i]
				var btn = document.createElement("button")
				btn.className = "sb-book-tab" + (" active" if JS.eq(i, State.player.get("activeBookIdx")) else "")
				btn.textContent = book.get("name")
				btn.disabled = ((JS.eq(i, State.player.get("activeBookIdx")) or not JS.t(isMyTurn)) or queueFull)
				btn.onclick = func(): return Combat.queueSwitchBook(i)
				# Tooltip: show book description if it's a catalogue book
				if JS.t(book.get("catalogueId")):
					var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, book.get("catalogueId"))
					if JS.t(cat):
						var lvl = JS.or_(book.get("upgradeLevel"), 0)
						var lvlDesc = JS.or_(JS.idx(JS.or_(cat.get("levelDescs"), []), lvl), "")
						var lines = [JS.s(cat.get("name")) + (" ✦" if cat.get("rarity") == "legendary" else ""), cat.get("desc")]
						if JS.t(lvlDesc):
							lines.append("Level " + JS.s(lvl + 1) + ": " + lvlDesc)
						if JS.t(cat.get("negative")):
							lines.append("Downside: " + JS.s(cat.get("negative")))
						btn.title = JS.join(lines, "\n")
				bookTabBar.appendChild(btn)
		elif (JS.t(State.player.get("spellbooks")) and len(State.player.get("spellbooks")) == 1):
			var lbl = document.createElement("span")
			lbl.style.cssText = "font-family:Cinzel,serif;font-size:.6rem;color:#6a4a20;letter-spacing:.06em;cursor:help;"
			lbl.textContent = JS.idx(State.player.get("spellbooks"), 0).get("name")
			var _b0 = JS.idx(State.player.get("spellbooks"), 0)
			if JS.t(_b0.get("catalogueId")):
				var _cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, _b0.get("catalogueId"))
				if JS.t(_cat):
					var _lvl = JS.or_(_b0.get("upgradeLevel"), 0)
					var _lvlDesc = JS.or_(JS.idx(JS.or_(_cat.get("levelDescs"), []), _lvl), "")
					var _lines = [_cat.get("name"), _cat.get("desc")]
					if JS.t(_lvlDesc):
						_lines.append("Level " + JS.s(_lvl + 1) + ": " + _lvlDesc)
					if JS.t(_cat.get("negative")):
						_lines.append("Downside: " + JS.s(_cat.get("negative")))
					lbl.title = JS.join(_lines, "\n")
			bookTabBar.appendChild(lbl)
	# ── Populate passives row ────────────────────────────────────────────────
	var passivesRow = document.getElementById("sb-passives-row")
	if JS.t(passivesRow):
		passivesRow.innerHTML = ""
		var passiveIds = JS.or_(State.player.get("passives"), [])
		if len(passiveIds) == 0:
			var empty = document.createElement("span")
			empty.className = "sb-passive-empty"
			empty.textContent = "No passives yet"
			passivesRow.appendChild(empty)
		else:
			for pid in JS.iter(passiveIds):
				var pdef = [null]
				# Find passive def
				pdef[0] = null
				for arr in JS.iter(JS.values(JS.or_(Passives.PASSIVE_CHOICES, {}))):
					var found = JS.find(JS.or_(arr, []), func(p = null): return JS.eq(p.id, pid))
					if JS.t(found):
						pdef[0] = found
				var pip = document.createElement("div")
				pip.className = "sb-passive-pip"
				pip.innerHTML = (PassiveIcons.passiveIconSVG(pdef[0], 14) if JS.t(pdef[0]) else "<svg viewBox=\"0 0 16 16\" width=\"14\" height=\"14\" xmlns=\"http://www.w3.org/2000/svg\"><circle cx=\"8\" cy=\"8\" r=\"4\" fill=\"#a09080\" opacity=\".6\"/></svg>")
				pip.setAttribute("data-tip", (JS.or_(JS.or_(pdef[0].get("title"), pdef[0].get("name")), pid) if JS.t(pdef[0]) else pid))
				if JS.t(pdef[0]):
					var _tipLines = [JS.or_(JS.or_(pdef[0].get("title"), pdef[0].get("name")), pid), JS.or_(pdef[0].get("desc"), "")]
					if JS.t(pdef[0].get("detail")):
						_tipLines.append_array(["─────", pdef[0].detail])
					pip.title = JS.join(_tipLines, "\n")
				else:
					pip.title = pid
				passivesRow.appendChild(pip)
	# ── Update end-turn btn ──────────────────────────────────────────────────
	var endBtn = document.getElementById("end-turn-btn")
	if JS.t(endBtn):
		var hasActions = len(JS.or_(State.combat.get("actionQueue"), [])) > 0
		endBtn.disabled = JS.or_(JS.or_((not JS.t(State.combat.get("playerTurn"))), State.combat.get("over")), (not hasActions))
		endBtn.className = "sb-endturn-btn" + (" ready" if hasActions else "")
		endBtn.textContent = ("⚔ End Turn (" + JS.s(len(State.combat.get("actionQueue"))) + ")" if hasActions else "⚔ End Turn")
	# ── Update item button ────────────────────────────────────────────────────
	var itemBtn = document.getElementById("sb-item-btn")
	var invCount = document.getElementById("inv-count-label")
	if JS.t(itemBtn):
		var count = len(JS.or_(State.player.get("inventory"), []))
		itemBtn.disabled = (not JS.t(isMyTurn) or count == 0)
		if JS.t(invCount):
			invCount.textContent = count
	# ── Card hand UI ─────────────────────────────────────────────────────────────
	var _combatScreen = document.getElementById("combat-screen")
	grid.style.display = "none"
	var _invPanel = document.getElementById("inv-panel")
	if JS.t(_invPanel):
		_invPanel.style.display = "none"
	var _itemBtnEl = document.getElementById("sb-item-btn")
	if JS.t(_itemBtnEl):
		_itemBtnEl.style.display = "none"
	var _sbTopbar = document.querySelector(".sb-topbar")
	if JS.t(_sbTopbar):
		_sbTopbar.style.display = "none"
	var _sbPassives = document.getElementById("sb-passives-row")
	if JS.t(_sbPassives):
		_sbPassives.style.display = "none"
	if JS.t(_combatScreen):
		_combatScreen.classList.add("deck-mode-active")
	if not JS.t(_deckModeLayoutActive):
		_deckModeLayoutActive = true
		var _fn9 = func():
			Sprites.initBattleCanvas()
		JS.setTimeout(_fn9, 50)
	_renderCardHand(isMyTurn, queueFull, cdPreviewReduce)
	_renderArenaDecks(isMyTurn, queueFull)
	_renderArenaEndTurn(isMyTurn)
	_renderArenaPassives()
	_repositionDeckSwitcher()
	return
	# ── PLASMA: full custom grid (shown whenever the plasma abilities book is active) ─────────────────────────────────────────────
	if (JS.t(State.activeBook()) and JS.t(State.activeBook().get("isPlasmaBook"))):
		grid.style.gridTemplateColumns = "repeat(3,1fr)"
		grid.innerHTML = ""
		var availCharge = max(0, (JS.or_(State.status.get("player").get("plasmaCharge"), 0)) - (JS.or_(State.combat.get("plasmaChargeReserved"), 0)))
		if not JS.t(State.combat.get("plasmaSpendAmounts")):
			State.combat.plasmaSpendAmounts = {}
		for spell in JS.iter(State.player.get("spellbook")):
			if not JS.t(spell.get("isPlasmaAbility")):
				continue
			var onCD = (JS.or_(spell.get("currentCD"), 0)) > 0
			var isVar = JS.eq(spell.get("chargeCost"), "variable")
			var fixedCost = (spell.get("chargeCost") if (JS.typeof_(spell.get("chargeCost"))) == "number" else 0)
			if JS.idx(State.combat.get("plasmaSpendAmounts"), spell.id) == null:
				State.combat.get("plasmaSpendAmounts")[spell.id] = (min(6, availCharge) if isVar else fixedCost)
			var curSpend = (min(max(1, JS.idx(State.combat.get("plasmaSpendAmounts"), spell.id)), availCharge) if isVar else fixedCost)
			var canAfford = availCharge >= curSpend
			var alreadyQueued = JS.some(JS.or_(State.combat.get("actionQueue"), []), func(a = null): return JS.eq(a.get("spellId"), spell.id))
			var cell = document.createElement("button")
			cell.className = "sb-spell-cell" + (" on-cd" if onCD else "")
			cell.disabled = (((not JS.t(isMyTurn) or onCD) or not canAfford) or alreadyQueued)
			var costLabel = (JS.s(curSpend) + "⚡" if isVar else (JS.s(fixedCost) + "⚡" if fixedCost > 0 else "Free"))
			var overStr = ("✦" if JS.t(State.combat.get("plasmaOvercharged")) else "")
			cell.innerHTML = "<div class=\"sb-spell-icon\">" + SpellIcons.spellIconSVG(spell, 22) + "</div>" + "<div class=\"sb-spell-name\">" + JS.s(spell.get("name")) + (" " + overStr if JS.t(overStr) else "") + "</div>" + "<div class=\"sb-spell-cd " + ("on-cd" if onCD else "ready") + "\">" + ("CD:" + JS.s(spell.get("currentCD")) if onCD else costLabel) + "</div>" + ("<div class=\"sb-spell-queued-badge\">✓</div>" if alreadyQueued else "")
			if true:
				var chargeCostStr = ("Cost: variable ⚡ (adjust with +/-)" if isVar else ("Cost: " + JS.s(fixedCost) + " ⚡" if fixedCost > 0 else "Cost: Free"))
				var cdInfo = ("CD: " + JS.s(spell.get("baseCooldown")) + " turn" + ("s" if not JS.eq(spell.get("baseCooldown"), 1) else "") if (JS.or_(spell.get("baseCooldown"), 0)) > 0 else "")
				var dmgPrev = _spellDmgPreview(spell)
				var atkLine = "ATK: " + JS.s(Helpers.attackPowerFor("player")) + "  EFX: " + JS.s(Helpers.effectPowerFor("player")) + "  Charge: " + JS.s(JS.or_(State.status.get("player").get("plasmaCharge"), 0)) + "⚡"
				var parts = JS.filter([
					JS.s(spell.get("name")) + " [Plasma]",
					JS.or_(spell.get("desc"), ""),
					dmgPrev,
					chargeCostStr,
					cdInfo,
					atkLine,
				], JS.t)
				cell.title = JS.join(parts, "\n")
			if isVar:
				cell.style.cursor = "default"
				cell.onclick = null
				# Stepper overlay — small +/- inside cell
				var stepper = document.createElement("div")
				stepper.style.cssText = "display:flex;gap:2px;justify-content:center;margin-top:2px;"
				var minus = document.createElement("button")
				minus.textContent = "-"
				minus.style.cssText = "background:#1a0e05;border:1px solid #3a1a0a;color:#c8a060;width:18px;height:16px;font-size:.6rem;cursor:pointer;border-radius:2px;padding:0;"
				var _fn10 = func(e = null):
					e.stopPropagation()
					State.combat.get("plasmaSpendAmounts")[spell.id] = max(1, (JS.or_(JS.idx(State.combat.get("plasmaSpendAmounts"), spell.id), 1)) - 1)
					renderSpellButtons()
				minus.onclick = _fn10
				var plus = document.createElement("button")
				plus.textContent = "+"
				plus.style.cssText = "background:#1a0e05;border:1px solid #3a1a0a;color:#c8a060;width:18px;height:16px;font-size:.6rem;cursor:pointer;border-radius:2px;padding:0;"
				var _fn11 = func(e = null):
					e.stopPropagation()
					State.combat.get("plasmaSpendAmounts")[spell.id] = min(availCharge, (JS.or_(JS.idx(State.combat.get("plasmaSpendAmounts"), spell.id), 1)) + 1)
					renderSpellButtons()
				plus.onclick = _fn11
				var castBtn = document.createElement("button")
				castBtn.textContent = "Cast"
				castBtn.style.cssText = "background:#2a1a3a;border:1px solid #6a2a8a;color:#da70d6;font-size:.54rem;padding:0 4px;border-radius:2px;cursor:pointer;font-family:Cinzel,serif;"
				castBtn.disabled = (((not JS.t(isMyTurn) or onCD) or not canAfford) or alreadyQueued)
				var _fn13 = func(e = null):
					e.stopPropagation()
					if (((not JS.t(isMyTurn) or onCD) or not canAfford) or alreadyQueued):
						return
					var snapSpend = JS.or_(JS.idx(State.combat.get("plasmaSpendAmounts"), spell.id), 1)
					State.combat.plasmaChargeReserved = (JS.or_(State.combat.get("plasmaChargeReserved"), 0)) + snapSpend
					var snapTgt = State.combat.get("targetIdx")
					var snapIdx = JS.indexOf(State.player.get("spellbook"), spell)
					var _fn12 = func():
						State.setActiveEnemy(snapTgt)
						State.combat.plasmaCurrentSpend = snapSpend
						# wire UI spend → _plasmaSpend()
						var ctx = Hit.makeSpellCtx("player", "enemy", snapIdx)
						ctx.plasmaChargeSpent = snapSpend
						JS.callm(spell, "execute", [ctx])
						updateHPBars()
						renderStatusTags()
						updateStatsUI()
					State.combat.get("actionQueue").append({
						"label": JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")) + "(" + JS.s(snapSpend) + "⚡)",
						"fn": _fn12,
						"targetIdx": snapTgt,
						"isPlasma": true,
						"spellId": spell.id,
					})
					Combat.renderQueue()
					Combat.updateActionUI()
					renderSpellButtons()
				castBtn.onclick = _fn13
				stepper.appendChild(minus)
				stepper.appendChild(castBtn)
				stepper.appendChild(plus)
				cell.appendChild(stepper)
			else:
				var _fn15 = func():
					if (((not JS.t(isMyTurn) or onCD) or not canAfford) or alreadyQueued):
						return
					var snapTgt = State.combat.get("targetIdx")
					var snapIdx = JS.indexOf(State.player.get("spellbook"), spell)
					State.combat.plasmaChargeReserved = (JS.or_(State.combat.get("plasmaChargeReserved"), 0)) + curSpend
					var _fn14 = func():
						State.setActiveEnemy(snapTgt)
						var ctx = Hit.makeSpellCtx("player", "enemy", snapIdx)
						ctx.plasmaChargeSpent = curSpend
						JS.callm(spell, "execute", [ctx])
						updateHPBars()
						renderStatusTags()
						updateStatsUI()
					State.combat.get("actionQueue").append({
						"label": JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")),
						"fn": _fn14,
						"targetIdx": snapTgt,
						"isPlasma": true,
						"spellId": spell.id,
					})
					Combat.renderQueue()
					Combat.updateActionUI()
					renderSpellButtons()
				cell.onclick = _fn15
			grid.appendChild(cell)
		return
	# ── Non-Plasma: Build 3-col grid ─────────────────────────────────────────
	grid.innerHTML = ""
	# Spell cells (player.spellbook includes _basic and _armor builtins)
	for spell in JS.iter(State.player.get("spellbook")):
		# ── Built-in: Basic Attack ───────────────────────────────────────────
		if spell.get("id") == "_basic":
			var _elemBasicNames = {
				"Fire": "Ember Strike",
				"Water": "Tidal Jab",
				"Ice": "Frost Jab",
				"Earth": "Stone Fist",
				"Nature": "Vine Whip",
				"Lightning": "Spark Strike",
				"Plasma": "Surge Bolt",
				"Air": "Gust Slash",
			}
			var _elemBasicIcons = {
				"Fire": "🔥",
				"Water": "💧",
				"Ice": "❄️",
				"Earth": "🪨",
				"Nature": "🌿",
				"Lightning": "⚡",
				"Plasma": "🔮",
				"Air": "💨",
			}
			var _elemBasicFlags = {
				"Fire": "_elementalBasicFire",
				"Water": "_elementalBasicWater",
				"Ice": "_elementalBasicIce",
				"Earth": "_elementalBasicEarth",
				"Nature": "_elementalBasicNature",
				"Lightning": "_elementalBasicLightning",
				"Plasma": "_elementalBasicPlasma",
				"Air": "_elementalBasicAir",
			}
			var basicLevel = JS.or_(JS.idx(State.player, JS.or_(JS.idx(_elemBasicFlags, State.playerElement), "")), 0)
			var hasElemBasic = basicLevel > 0
			var basicName = (JS.or_(JS.idx(_elemBasicNames, State.playerElement), "Basic Attack") if hasElemBasic else "Basic Attack")
			var basicIcon = (JS.or_(JS.idx(_elemBasicIcons, State.playerElement), "⚔") if hasElemBasic else "⚔")
			var basicOnCD = State.combat.get("basicCD") > 0
			var basicQueued = JS.some(JS.or_(State.combat.get("actionQueue"), []), func(a = null): return a.get("label") == (basicIcon + " " + basicName))
			var basicOutOfPP = (spell.get("currentPP") != null and spell.get("currentPP") <= 0)
			# Rarity for basic: level maps to rarity tiers
			var _basicRarityMap = [null, "dim", "kindled", "blazing", "radiant", "radiant"]
			var _basicRarityKey = JS.or_(JS.idx(_basicRarityMap, basicLevel), null)
			var _basicRarityInfo = (JS.idx(Incantations.SPELL_RARITY, _basicRarityKey) if (hasElemBasic and true) else null)
			var _basicRarityColor = (_basicRarityInfo.get("color") if JS.t(_basicRarityInfo) else null)
			var cell = document.createElement("button")
			cell.className = "sb-spell-cell" + (" on-cd" if basicOnCD else "") + (" no-pp" if basicOutOfPP else "")
			if JS.t(_basicRarityColor):
				cell.style.borderColor = JS.s(_basicRarityColor) + "99"
			cell.disabled = ((((not JS.t(isMyTurn) or queueFull) or basicOnCD) or basicQueued) or basicOutOfPP)
			var _elemDmgBonus = (10 + Incantations._incantationBonus(basicLevel, 3, 0.95) if hasElemBasic else 0)
			var basicDmgEst = max(1, JS.round(((((Constants.BASE_DMG + (JS.or_(State.combat.get("tempDmgBonus"), 0))) + (JS.or_(State.player.get("basicDmgFlat"), 0))) + _elemDmgBonus) * (JS.or_(State.player.get("basicDmgMult"), 1.0))) + Helpers.attackPowerFor("player")))
			var _basicRarityBadge = ("<div style=\"font-size:.5rem;color:" + JS.s(_basicRarityColor) + ";letter-spacing:.04em;\">✦" + JS.s(_basicRarityInfo.get("label")) + (" II" if basicLevel >= 5 else "") + "</div>" if JS.t(_basicRarityColor) else "")
			# Build elemental effect description line for the button
			var _elemEffectDescs = {
				"Fire": func(lvl = null): return "🔥 +" + JS.s(JS.round(2 + Incantations._incantationBonus(lvl, 1, 0.9))) + " Burn",
				"Water": func(lvl = null): return "🫧 +" + JS.s(JS.round(1 + Incantations._incantationBonus(lvl, 0.5, 0.9))) + " Foam",
				"Ice": func(lvl = null): return "❄️ +" + JS.toFixed(1 + Incantations._incantationBonus(lvl, 0.5, 0.9), 1) + " Frost",
				"Earth": func(lvl = null): return "🪨 +" + JS.s(JS.round(1 + Incantations._incantationBonus(lvl, 0.5, 0.9))) + " Stone",
				"Nature": func(lvl = null): return "🌿 +" + JS.s(JS.round(1 + Incantations._incantationBonus(lvl, 0.5, 0.9))) + " Root",
				"Lightning": func(lvl = null): return "⚡ +" + JS.s(JS.round(1 + Incantations._incantationBonus(lvl, 0.5, 0.9))) + " Shock",
				"Plasma": func(lvl = null): return "🔮 +" + JS.s(JS.round(2 + Incantations._incantationBonus(lvl, 1, 1.0))) + " Charge",
				"Air": func(lvl = null): return "💨 +" + JS.s(JS.round(1 + Incantations._incantationBonus(lvl, 1, 1.0))) + " Momentum",
			}
			var _elemEffectFn = (JS.idx(_elemEffectDescs, State.playerElement) if JS.t(hasElemBasic) else hasElemBasic)
			var _elemEffectLine = ("<div style=\"font-size:.48rem;color:#a0c8a0;letter-spacing:.03em;margin-top:1px;\">" + JS.s(_elemEffectFn.call(basicLevel)) + "</div>" if JS.t(_elemEffectFn) else "")
			var basicPPLabel = ("<div class=\"sb-spell-pp\">" + JS.s(JS.or_(spell.get("currentPP"), 0)) + "/" + JS.s(spell.get("maxPP")) + " PP</div>" if spell.get("maxPP") != null else "")
			cell.innerHTML = ("<div class=\"sb-spell-icon\">" + basicIcon + "</div>") + ("<div class=\"sb-spell-name\">" + basicName + "</div>") + "<div class=\"sb-spell-cd " + ("on-cd" if basicOnCD else "ready") + "\">" + ("No PP" if basicOutOfPP else ("CD:" + JS.s(State.combat.get("basicCD")) if basicOnCD else "~" + JS.s(basicDmgEst) + " dmg")) + "</div>" + _basicRarityBadge + _elemEffectLine + basicPPLabel + ("<div class=\"sb-spell-queued-badge\">✓</div>" if basicQueued else "")
			var _elemEffectTooltip = ("\n" + JS.s(_elemEffectFn.call(basicLevel)) + " on hit" if JS.t(_elemEffectFn) else "")
			cell.title = basicName + " [" + JS.s(State.playerElement) + "]" + (" · " + JS.s(_basicRarityInfo.get("label")) + (" II" if basicLevel >= 5 else "") if JS.t(_basicRarityInfo) else "") + "\nDeals ~" + JS.s(basicDmgEst) + " dmg (ATK: " + JS.s(Helpers.attackPowerFor("player")) + ")" + _elemEffectTooltip + "\nCooldown: 1 turn"
			var basicSpellRef = spell
			var _fn18 = func():
				if ((((not JS.t(isMyTurn) or queueFull) or basicOnCD) or basicQueued) or basicOutOfPP):
					return
				var snapTgt = State.combat.get("targetIdx")
				var snapCD = JS.or_(Helpers.adjustedCooldownFor("player", 1), 1)
				var _bSnapTgt = snapTgt
				var _bHasElem = hasElemBasic
				var _fn16 = func():
					State.combat.basicCD = snapCD
					if (JS.or_(basicSpellRef.get("currentPP"), 0)) > 0:
						basicSpellRef.currentPP -= 1
					State.setActiveEnemy(_bSnapTgt)
					var ctx = Hit.makeSpellCtx("player", "enemy", -1)
					doBasicAttack(ctx)
					updateHPBars()
					renderStatusTags()
					updateStatsUI()
				var _fn17 = func():
					if JS.t(State.player.get("_mistBlindDamage")):
						return ""
					var tgt = JS.idx(State.combat.get("enemies"), _bSnapTgt)
					if (not JS.t(tgt) or not JS.t(tgt.get("alive"))):
						return ""
					var prevActive = State.combat.get("activeEnemyIdx")
					State.combat.activeEnemyIdx = _bSnapTgt
					var ap = Helpers.attackPowerFor("player", "enemy")
					State.combat.activeEnemyIdx = prevActive
					var base = (JS.or_(State.player.get("basicDmgFlat"), 0)) + (10 if _bHasElem else 0)
					var dmg = max(0, base + ap)
					var block = JS.or_(tgt.get("status").get("block"), 0)
					var after = max(0, dmg - block)
					return ("~" + JS.s(after) + " dmg (" + JS.s(dmg) + "−" + JS.s(block) + " blk)" if (block > 0 and after != dmg) else "~" + JS.s(after) + " dmg")
				Combat.queueAction(basicIcon + " " + basicName, _fn16, {"hintFn": _fn17})
				renderSpellButtons()
			cell.onclick = _fn18
			grid.appendChild(cell)
			continue
		# ── Built-in: Armor ──────────────────────────────────────────────────
		if spell.get("id") == "_armor":
			var armAmt = Helpers.armorBlockAmount()
			var armorQueued = JS.some(JS.or_(State.combat.get("actionQueue"), []), func(a = null): return a.get("label") == "🛡 Armor")
			var armorOutOfPP = (spell.get("currentPP") != null and spell.get("currentPP") <= 0)
			var cell = document.createElement("button")
			cell.className = "sb-spell-cell elemental" + (" no-pp" if armorOutOfPP else "")
			cell.disabled = (((not JS.t(isMyTurn) or armorQueued) or queueFull) or armorOutOfPP)
			var armorPPLabel = ("<div class=\"sb-spell-pp\">" + JS.s(JS.or_(spell.get("currentPP"), 0)) + "/" + JS.s(spell.get("maxPP")) + " PP</div>" if spell.get("maxPP") != null else "")
			cell.innerHTML = "<div class=\"sb-spell-icon\">🛡</div>" + "<div class=\"sb-spell-name\">Armor</div>" + "<div class=\"sb-spell-cd ready\">" + ("No PP" if armorOutOfPP else "+" + JS.s(armAmt) + " Block") + "</div>" + armorPPLabel + ("<div class=\"sb-spell-queued-badge\">✓</div>" if armorQueued else "")
			cell.title = "Armor\n+" + JS.s(armAmt) + " Block (10 base + DEF÷5, DEF: " + JS.s(Helpers.defenseFor("player")) + ")\nBlock absorbs damage before HP\nNo cooldown"
			var armorSpellRef = spell
			var _fn20 = func():
				if (((not JS.t(isMyTurn) or armorQueued) or queueFull) or armorOutOfPP):
					return
				var _fn19 = func():
					if (JS.or_(armorSpellRef.get("currentPP"), 0)) > 0:
						armorSpellRef.currentPP -= 1
					State.status.get("player").block = (JS.or_(State.status.get("player").get("block"), 0)) + armAmt
					log_("🛡 You brace — +" + JS.s(armAmt) + " Block (" + JS.s(State.status.get("player").get("block")) + " total).", "player")
					renderStatusTags()
				Combat.queueAction("🛡 Armor", _fn19, {})
				renderSpellButtons()
			cell.onclick = _fn20
			grid.appendChild(cell)
			continue
		var rawCD = JS.or_(spell.get("currentCD"), 0)
		var effectiveCD = max(0, rawCD - cdPreviewReduce)
		var onCD = (not JS.t(spell.get("multiUse")) and effectiveCD > 0)
		var outOfPP = (spell.get("currentPP") != null and spell.get("currentPP") <= 0)
		var isFree = (not (not JS.t(spell.get("isFreeAction"))))
		var alreadyQueued = (not JS.t(spell.get("multiUse")) and JS.some(JS.or_(State.combat.get("actionQueue"), []), func(a = null): return (JS.t(a.get("label")) and JS.includes(a.get("label"), spell.get("name")))))
		var cell = document.createElement("button")
		cell.className = "sb-spell-cell elemental" + (" on-cd" if onCD else "") + (" no-pp" if outOfPP else "") + (" free-action" if isFree else "")
		# Rarity: tint border color
		if (JS.t(spell.get("rarity")) and spell.get("rarity") != "dim"):
			var rc = JS.idx(Incantations.SPELL_RARITY, spell.get("rarity"))
			if (JS.t(rc) and JS.t(rc.get("color"))):
				cell.style.borderColor = rc.get("color")
		var isChargeShot = spell.get("id") == "charge_shot"
		var slotsAvail = State.combat.get("actionsLeft") - nonFreeQueued
		var canQueue = (((not onCD and not outOfPP) and (JS.eq(spell.get("baseCooldown"), 0) or not alreadyQueued)) if isFree else JS.andf(((not queueFull and not onCD) and not outOfPP), func(): return JS.or_(spell.get("multiUse"), (not alreadyQueued))))
		cell.disabled = ((not JS.t(isMyTurn) or not JS.t(canQueue)) or (isChargeShot and slotsAvail < 2))
		var rankPct = JS.round((JS.or_(spell.get("dmgMult"), 1.0)) * 100)
		var rankStr = (" [" + JS.s(rankPct) + "%]" if rankPct > 100 else "")
		var cdLabel = ("No PP" if outOfPP else ("Free" if JS.t(spell.get("multiUse")) else ("CD:" + JS.s(effectiveCD) if onCD else "CD:" + JS.s(spell.get("baseCooldown")))))
		var freeLabel = (" ✦Free" if isFree else "")
		var ppLabel = ("<div class=\"sb-spell-pp\">" + JS.s(JS.or_(spell.get("currentPP"), 0)) + "/" + JS.s(spell.get("maxPP")) + " PP</div>" if spell.get("maxPP") != null else "")
		var incLevel = JS.or_(spell.get("incantationLevel"), 1)
		var rarityInfo = (JS.idx(Incantations.SPELL_RARITY, spell.get("rarity")) if (true and JS.t(spell.get("rarity"))) else null)
		var rarityColor = (rarityInfo.get("color") if (JS.t(rarityInfo) and JS.t(rarityInfo.get("color"))) else null)
		var incLabel = ("<div style=\"font-size:.52rem;color:" + JS.s(rarityColor) + ";letter-spacing:.04em;\">✦" + JS.s(rarityInfo.get("label")) + "</div>" if ((JS.t(rarityInfo) and JS.t(spell.get("rarity"))) and spell.get("rarity") != "dim") else "")
		var _incStat = Incantations.incantationStatDisplay(spell)
		var incStatLabel = ("<div style=\"font-size:.5rem;color:#88aacc;letter-spacing:.03em;\">" + JS.s(_incStat) + "</div>" if JS.t(_incStat) else "")
		cell.innerHTML = "<div class=\"sb-spell-icon\">" + SpellIcons.spellIconSVG(spell, 22) + "</div>" + "<div class=\"sb-spell-name\">" + JS.s(spell.get("name")) + rankStr + freeLabel + "</div>" + "<div class=\"sb-spell-cd " + ("on-cd" if (onCD or outOfPP) else "ready") + "\">" + cdLabel + "</div>" + incLabel + incStatLabel + ppLabel + ("<div class=\"sb-spell-queued-badge\">✓</div>" if alreadyQueued else "")
		if true:
			var cdInfo = ("CD: " + JS.s(spell.get("baseCooldown")) + " turn" + ("s" if not JS.eq(spell.get("baseCooldown"), 1) else "") if spell.get("baseCooldown") > 0 else "No cooldown")
			var ppInfo = ("PP: " + JS.s(JS.or_(spell.get("currentPP"), 0)) + "/" + JS.s(spell.get("maxPP")) if spell.get("maxPP") != null else "")
			var elemInfo = ("[" + JS.s(spell.get("element")) + "]" if JS.t(spell.get("element")) else "")
			var rankInfo = ("Rank: +" + JS.s(rankPct - 100) + "% damage" if rankPct > 100 else "")
			var dmgPrev = _spellDmgPreview(spell)
			var atkLine = "ATK: " + JS.s(Helpers.attackPowerFor("player")) + "  EFX: " + JS.s(Helpers.effectPowerFor("player")) + "  DEF: " + JS.s(Helpers.defenseFor("player"))
			var _iRar = (JS.idx(Incantations.SPELL_RARITY, spell.get("rarity")) if (true and JS.t(spell.get("rarity"))) else null)
			var incInfo = JS.s((_iRar.get("label") if JS.t(_iRar) else "Dim")) + " · Incantation Level " + JS.s(JS.or_(spell.get("incantationLevel"), 1))
			var parts = JS.filter([
				JS.s(spell.get("name")) + " " + elemInfo,
				JS.or_(spell.get("desc"), ""),
				dmgPrev,
				cdInfo,
				ppInfo,
				rankInfo,
				incInfo,
				atkLine,
			], JS.t)
			cell.title = JS.join(parts, "\n")
		var _fn26 = func():
			var _doQueueSpell = [null]
			var _fn24 = func(extraPriority = null):
				# General instant-use spells: execute immediately, apply CD, don't queue
				# Air: spells with pickPriority show a choice popup before queuing/using
				# Instant-use: don't queue, just set the shift and consume PP
				# Normal queued spell — set shift then queue
				# Pressure Launch: show +1/-1 choice when 10+ Momentum (runs popup then re-calls with chosen value)
				if (((extraPriority == null and Main.hasPassive("air_pressure_launch")) and JS.eq(State.playerElement, "Air")) and (JS.or_(State.status.get("player").get("momentumStacks"), 0)) >= 10):
					var _fn21 = func(chosen = null):
						_doQueueSpell[0].call(chosen)
					_showAirPriorityPopup([{"label": "+1 (fast)", "value": 1}, {"label": "−1 (slow)", "value": -1}], _fn21)
					return
				var snapTgt = State.combat.get("targetIdx")
				var spellRef = spell
				var spellIdx = JS.indexOf(State.player.get("spellbook"), spell)
				var snapCD = (JS.or_(Helpers.adjustedCooldownFor("player", spell.get("baseCooldown")), 1) if not JS.t(spell.get("multiUse")) else 0)
				var isStormRushDependent = ((stormRushQueued and rawCD > 0) and effectiveCD == 0)
				var _sSnapTgt = snapTgt
				var _sSpellRef = spellRef
				var _fn22 = func():
					if JS.t(State.player.get("_mistBlindDamage")):
						return ""
					var preview = _spellDmgPreview(_sSpellRef)
					if not JS.t(preview):
						return ""
					var tgt = JS.idx(State.combat.get("enemies"), _sSnapTgt)
					var block = (JS.or_(tgt.get("status").get("block"), 0) if JS.t(tgt) else 0)
					return (preview + " (−" + JS.s(block) + " blk)" if block > 0 else preview)
				var opts = {
					"isFree": isFree,
					"stormRushDependent": isStormRushDependent,
					"isSpellAction": true,
					"bookCatalogueId": (State.activeBook().get("catalogueId") if (JS.t(State.activeBook()) and JS.t(State.activeBook().get("catalogueId"))) else null),
					"spellObj": spell,
					"priority": (JS.or_(spell.get("priority"), 0)) + (JS.or_(extraPriority, 0)),
					"hintFn": _fn22,
				}
				if JS.t(spell.get("onQueue")):
					opts.onQueue = func(): return JS.callm(spell, "onQueue", [])
				if JS.t(spell.get("undoOnQueue")):
					opts.undoOnQueue = func(): return JS.callm(spell, "undoOnQueue", [])
				if spell.get("id") == "storm_rush":
					opts.stormRushAction = true
				var _fn23 = func():
					if not JS.t(spellRef.get("multiUse")):
						spellRef.currentCD = snapCD
					if (JS.or_(spellRef.get("currentPP"), 0)) > 0:
						spellRef.currentPP -= 1
					State.setActiveEnemy(snapTgt)
					var ctx = Hit.makeSpellCtx("player", "enemy", spellIdx)
					JS.callm(spellRef, "execute", [ctx])
					# Deep Current: fire Water spell a second time
					if ((not JS.t(State.combat.get("over")) and spellRef.get("element") == "Water") and JS.t(State.status.get("player").get("deepCurrentActive"))):
						State.status.get("player").deepCurrentActive = false
						log_("💠 Deep Current: " + JS.s(spellRef.get("name")) + " fires again!", "player")
						State.setActiveEnemy(snapTgt)
						var ctx2 = Hit.makeSpellCtx("player", "enemy", spellIdx)
						JS.callm(spellRef, "execute", [ctx2])
					updateHPBars()
					renderStatusTags()
					updateStatsUI()
				Combat.queueAction(JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")), _fn23, opts)
				renderSpellButtons()
			_doQueueSpell[0] = _fn24
			if (not JS.t(isMyTurn) or not JS.t(canQueue)):
				return
			if (JS.t(spell.get("instantUse")) and not JS.t(spell.get("pickPriority"))):
				var _iuIdx = JS.indexOf(State.player.get("spellbook"), spell)
				spell.currentCD = JS.or_(Helpers.adjustedCooldownFor("player", spell.get("baseCooldown")), spell.get("baseCooldown"))
				JS.callm(spell, "execute", [Hit.makeSpellCtx("player", "enemy", _iuIdx)])
				renderSpellButtons()
				Combat.updateActionUI()
				return
			if JS.t(spell.get("pickPriority")):
				var _fn25 = func(chosen = null):
					if JS.t(spell.get("instantUse")):
						State.combat._aoPriorityShift = chosen
						if (JS.or_(spell.get("currentPP"), 0)) > 0:
							spell.currentPP -= 1
						log_(JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")) + "! Subsequent spells: " + ("+" if chosen > 0 else "") + JS.s(chosen) + " priority.", "player")
						renderSpellButtons()
						Combat.updateActionUI()
						return
					State.combat._aoPriorityShift = chosen
					_doQueueSpell[0].call()
				_showAirPriorityPopup(spell.get("pickPriority"), _fn25)
				return
			_doQueueSpell[0].call()
		cell.onclick = _fn26
		grid.appendChild(cell)

func _makeSpellCard(spell = null, clickFn = null, isQueued = null, isOnCD = null, hintText = null):
	var card = document.createElement("div")
	card.className = "spell-card" + (" card-queued" if JS.t(isQueued) else "")
	var elemColor = JS.or_(JS.idx(_ELEM_CARD_COLORS, spell.get("element")), _ELEM_CARD_COLORS.get("Neutral"))
	card.style.borderColor = JS.s(elemColor) + "99"
	var rarityInfo = (JS.idx(Incantations.SPELL_RARITY, spell.get("rarity")) if (true and JS.t(spell.get("rarity"))) else null)
	var rarityColor = (rarityInfo.get("color") if (JS.t(rarityInfo) and JS.t(rarityInfo.get("color"))) else null)
	if JS.t(rarityColor):
		card.style.borderColor = rarityColor
	if JS.t(spell.get("id")):
		card.dataset.spellId = spell.id
	card.title = JS.s(spell.get("name")) + (" — " + JS.s(spell.get("desc")) if JS.t(spell.get("desc")) else "")
	var _iconHTML = SpellIcons.spellIconSVG(spell, 50)
	var _cdStr = ("CD:" + JS.s(spell.get("baseCooldown")) if spell.get("baseCooldown") > 1 else ("✦" if JS.eq(spell.get("baseCooldown"), 0) else ""))
	var _ppStr = (JS.s(JS.or_(spell.get("currentPP"), 0)) + "/" + JS.s(spell.get("maxPP")) if spell.get("maxPP") != null else "")
	card.innerHTML = "<div class=\"card-top-row\">" + ("<div class=\"card-cd\">" + _cdStr + "</div>") + ("<div class=\"card-type\">" + (JS.or_(spell.get("element"), "")) + "</div>") + ("<div class=\"card-pp\">" + _ppStr + "</div>") + "</div>" + ("<div class=\"card-art\">" + _iconHTML + "</div>") + ("<div class=\"card-name\">" + JS.s(spell.get("name")) + "</div>") + ("<div class=\"card-hint\">" + JS.replace(JS.or_(hintText, ""), JS.re(" · ", "g"), "<br>") + "</div>")
	if (not JS.t(isQueued) and JS.t(clickFn)):
		var _holdTimer = [null]
		card.onclick = clickFn
		# Hold-to-info tooltip
		_holdTimer[0] = null
		var _fn28 = func(e = null):
			var _fn27 = func():
				_showSpellTooltip(spell, hintText, card)
			_holdTimer[0] = JS.setTimeout(_fn27, 420)
		card.addEventListener("pointerdown", _fn28)
		var _fn29 = func():
			JS.clearTimeout(_holdTimer[0])
			_hideSpellTooltip()
		card.addEventListener("pointerup", _fn29)
		var _fn30 = func():
			JS.clearTimeout(_holdTimer[0])
			_hideSpellTooltip()
		card.addEventListener("pointerleave", _fn30)
	return card

func _showSpellTooltip(spell = null, hintText = null, cardEl = null):
	var tip = document.getElementById("spell-tooltip")
	if not JS.t(tip):
		return
	var rarityInfo = (JS.idx(Incantations.SPELL_RARITY, spell.get("rarity")) if (true and JS.t(spell.get("rarity"))) else null)
	var rarityColor = (rarityInfo.get("color") if JS.t(rarityInfo) else "#8a6a30")
	var rarityLabel = (rarityInfo.get("label") if JS.t(rarityInfo) else "")
	var elemColor = JS.or_(JS.idx(_ELEM_CARD_COLORS, spell.get("element")), "#a09080")
	var iconHTML = SpellIcons.spellIconSVG(spell, 52)
	var cdText = ("<span class=\"stt-stat\">CD <b>" + JS.s(spell.get("baseCooldown")) + "</b></span>" if spell.get("baseCooldown") > 1 else ("<span class=\"stt-stat\" style=\"color:#c8a060;\">✦ Free</span>" if JS.eq(spell.get("baseCooldown"), 0) else ""))
	var ppText = ("<span class=\"stt-stat\">PP <b>" + JS.s(JS.or_(spell.get("currentPP"), 0)) + "/" + JS.s(spell.get("maxPP")) + "</b></span>" if spell.get("maxPP") != null else "")
	var dmgText = ("<span class=\"stt-stat\">" + JS.s(hintText) + "</span>" if (JS.t(hintText) and not JS.eq(hintText, "No PP")) else "")
	tip.innerHTML = ("<div class=\"stt-header\" style=\"border-color:" + JS.s(rarityColor) + "33;\">") + ("<div class=\"stt-icon\">" + iconHTML + "</div>") + "<div class=\"stt-title-block\">" + ("<div class=\"stt-name\" style=\"color:#f0f0f8;\">" + JS.s(spell.get("name")) + "</div>") + "<div class=\"stt-badges\">" + ("<span class=\"stt-elem\" style=\"color:" + elemColor + ";\">" + (JS.or_(spell.get("element"), "")) + "</span>") + ("<span class=\"stt-rarity\" style=\"color:" + JS.s(rarityColor) + ";\">" + JS.s(rarityLabel) + "</span>" if JS.t(rarityLabel) else "") + "</div>" + "</div>" + "</div>" + ("<div class=\"stt-desc\">" + JS.s(spell.get("desc")) + "</div>" if JS.t(spell.get("desc")) else "") + ("<div class=\"stt-stats\">" + cdText + ppText + dmgText + "</div>")
	# Position above the card
	var rect = cardEl.getBoundingClientRect()
	tip.style.display = "block"
	var tipW = 220
	var left = (JS.un(rect.get("left")) + (rect.width / 2.0)) - (tipW / 2.0)
	left = max(8, min(left, (window.innerWidth - tipW) - 8))
	tip.style.left = JS.s(left) + "px"
	tip.style.top = JS.s(max(8, (JS.un(rect.get("top")) - tip.offsetHeight) - 10)) + "px"

func _hideSpellTooltip():
	var tip = document.getElementById("spell-tooltip")
	if JS.t(tip):
		tip.style.display = "none"

func _renderCardHand(isMyTurn = null, queueFull = null, cdPreviewReduce = null):
	var deckCount = [null]
	var _newCardDelay = [null]
	var cardArea = document.getElementById("card-hand-area")
	var handEl = document.getElementById("card-hand")
	var itemHandEl = document.getElementById("item-hand")
	var deckCounter = document.getElementById("deck-counter")
	var playedRow = document.getElementById("played-card-row")
	if not JS.t(handEl):
		return
	if JS.t(cardArea):
		cardArea.style.display = ""
	if JS.t(playedRow):
		playedRow.style.display = ""
	handEl.innerHTML = ""
	if JS.t(itemHandEl):
		itemHandEl.innerHTML = ""
		itemHandEl.style.display = "none"
	deckCount[0] = 0
	var stormRushQueued = JS.some(JS.or_(State.combat.get("actionQueue"), []), func(a = null): return JS.t(a.get("stormRushAction")))
	var nonFreeQueued = len(JS.arr(JS.or_(State.combat.get("actionQueue"), [])).filter(func(a = null): return (not JS.t(a.get("isFree")) and not JS.t(a.get("isPlasma")))))
	# ── Item hand mode: show items as cards instead of spells ────────────────
	if JS.t(_showingItemHand):
		var items = JS.or_(State.player.get("inventory"), [])
		if len(items) == 0:
			var empty = document.createElement("div")
			empty.style.cssText = "font-size:.72rem;color:#444;padding:1.5rem;font-family:'Cinzel',serif;"
			empty.textContent = "No items."
			handEl.appendChild(empty)
		else:
			var _arr31 = JS.iter(items)
			for idx in range(len(_arr31)):
				var item = _arr31[idx]
				var fakeSpell = {
					"id": "_item_" + JS.s(idx),
					"emoji": item.get("emoji"),
					"name": item.get("name"),
					"element": "Neutral",
					"baseCooldown": 1,
					"desc": JS.or_(item.get("desc"), ""),
				}
				var _fn32 = func():
					if not JS.t(isMyTurn):
						return
					Combat.useItemInCombat(idx)
				var card = _makeSpellCard(fakeSpell, _fn32, false, false, (JS.slice(item.get("desc"), 0, 22) if JS.t(item.get("desc")) else "Use"))
				handEl.appendChild(card)
		# Apply fan layout to item cards
		var _itemFanCards = JS.arr(handEl.querySelectorAll(".spell-card"))
		var _arr33 = JS.iter(_itemFanCards)
		for i in range(len(_arr33)):
			var card = _arr33[i]
			var relI = ((i - ((len(_itemFanCards) - 1) / 2.0)) / float(max(len(_itemFanCards) - 1, 1)) if len(_itemFanCards) > 1 else 0)
			card.style.transformOrigin = "50% 120%"
			card.style.position = "relative"
			card.style.zIndex = JS.s(len(_itemFanCards) - JS.round(abs(relI) * (len(_itemFanCards) - 1)))
			card.style.transform = "rotate(" + JS.toFixed(relI * (14 if len(_itemFanCards) > 1 else 0), 1) + "deg) translateY(" + JS.toFixed(abs(relI) * 20, 0) + "px)"
		if JS.t(deckCounter):
			deckCounter.textContent = ""
		return
	for spell in JS.iter(State.player.get("spellbook")):
		# ── Built-in: Basic Attack ────────────────────────────────────────────
		if spell.get("id") == "_basic":
			var _elemBasicNames = {
				"Fire": "Ember Strike",
				"Water": "Tidal Jab",
				"Ice": "Frost Jab",
				"Earth": "Stone Fist",
				"Nature": "Vine Whip",
				"Lightning": "Spark Strike",
				"Plasma": "Surge Bolt",
				"Air": "Gust Slash",
			}
			var _elemBasicIcons = {
				"Fire": "🔥",
				"Water": "💧",
				"Ice": "❄️",
				"Earth": "🪨",
				"Nature": "🌿",
				"Lightning": "⚡",
				"Plasma": "🔮",
				"Air": "💨",
			}
			var basicLevel = JS.or_(JS.idx(State.player, "_elementalBasic" + JS.s(State.playerElement)), 0)
			var hasElemBasic = basicLevel > 0
			var basicName = (JS.or_(JS.idx(_elemBasicNames, State.playerElement), "Basic Attack") if hasElemBasic else "Basic Attack")
			var basicIcon = (JS.or_(JS.idx(_elemBasicIcons, State.playerElement), "⚔") if hasElemBasic else "⚔")
			var basicOnCD = State.combat.get("basicCD") > 0
			var basicQueued = JS.some(JS.or_(State.combat.get("actionQueue"), []), func(a = null): return a.get("label") == (basicIcon + " " + basicName))
			if (basicOnCD or basicQueued):
				deckCount[0] += 1
				continue
			var basicOutOfPP = (spell.get("currentPP") != null and spell.get("currentPP") <= 0)
			var basicDmgEst = max(1, JS.round(((((Constants.BASE_DMG + (JS.or_(State.combat.get("tempDmgBonus"), 0))) + (JS.or_(State.player.get("basicDmgFlat"), 0))) + (10 if hasElemBasic else 0)) * (JS.or_(State.player.get("basicDmgMult"), 1.0))) + Helpers.attackPowerFor("player")))
			var _basicIconIds = {
				"Fire": "ignite",
				"Water": "tidal_surge",
				"Ice": "frost_bolt",
				"Lightning": "zap",
				"Earth": "seismic_wave",
				"Nature": "vine_strike",
				"Plasma": "plasma_lance",
				"Air": "twin_strike",
			}
			var _fakeSpell = {
				"id": JS.or_(JS.idx(_basicIconIds, State.playerElement), "power_strike"),
				"emoji": basicIcon,
				"name": basicName,
				"element": State.playerElement,
				"baseCooldown": JS.or_(Helpers.adjustedCooldownFor("player", 1), 1),
				"currentPP": spell.get("currentPP"),
				"maxPP": spell.get("maxPP"),
			}
			var _fn35 = func():
				if ((((not JS.t(isMyTurn) or JS.t(queueFull)) or basicOnCD) or basicQueued) or basicOutOfPP):
					return
				var snapTgt = State.combat.get("targetIdx")
				var snapCD = JS.or_(Helpers.adjustedCooldownFor("player", 1), 1)
				var _fn34 = func():
					State.combat.basicCD = snapCD
					if (JS.or_(spell.get("currentPP"), 0)) > 0:
						spell.currentPP -= 1
					State.setActiveEnemy(snapTgt)
					var ctx = Hit.makeSpellCtx("player", "enemy", -1)
					doBasicAttack(ctx)
					updateHPBars()
					renderStatusTags()
					updateStatsUI()
				Combat.queueAction(basicIcon + " " + basicName, _fn34, {"spellObj": _fakeSpell})
				renderSpellButtons()
			var card = _makeSpellCard(_fakeSpell, _fn35, false, false, ("No PP" if basicOutOfPP else "~" + JS.s(basicDmgEst) + " dmg"))
			handEl.appendChild(card)
			continue
		# ── Built-in: Armor ───────────────────────────────────────────────────
		if spell.get("id") == "_armor":
			var armAmt = Helpers.armorBlockAmount()
			var armorQueued = JS.some(JS.or_(State.combat.get("actionQueue"), []), func(a = null): return a.get("label") == "🛡 Armor")
			if armorQueued:
				deckCount[0] += 1
				continue
			var armorOutOfPP = (spell.get("currentPP") != null and spell.get("currentPP") <= 0)
			var _fakeArmor = {
				"id": "_armor",
				"emoji": "🛡",
				"name": "Armor",
				"element": "Neutral",
				"baseCooldown": 0,
				"currentPP": spell.get("currentPP"),
				"maxPP": spell.get("maxPP"),
			}
			var _fn37 = func():
				if ((not JS.t(isMyTurn) or JS.t(queueFull)) or armorOutOfPP):
					return
				var _fn36 = func():
					if (JS.or_(spell.get("currentPP"), 0)) > 0:
						spell.currentPP -= 1
					State.status.get("player").block = (JS.or_(State.status.get("player").get("block"), 0)) + armAmt
					log_("🛡 You brace — +" + JS.s(armAmt) + " Block (" + JS.s(State.status.get("player").get("block")) + " total).", "player")
					renderStatusTags()
				Combat.queueAction("🛡 Armor", _fn36, {"spellObj": _fakeArmor})
				renderSpellButtons()
			var card = _makeSpellCard(_fakeArmor, _fn37, false, false, ("No PP" if armorOutOfPP else "+" + JS.s(armAmt) + " Block"))
			handEl.appendChild(card)
			continue
		# ── Regular spell ─────────────────────────────────────────────────────
		var rawCD = JS.or_(spell.get("currentCD"), 0)
		var effectiveCD = max(0, rawCD - cdPreviewReduce)
		var onCD = (not JS.t(spell.get("multiUse")) and effectiveCD > 0)
		if onCD:
			deckCount[0] += 1
			continue
		var outOfPP = (spell.get("currentPP") != null and spell.get("currentPP") <= 0)
		var isFree = (not (not JS.t(spell.get("isFreeAction"))))
		var isZeroCD = JS.eq(spell.get("baseCooldown"), 0)
		var alreadyQueued = ((not JS.t(spell.get("multiUse")) and not isZeroCD) and JS.some(JS.or_(State.combat.get("actionQueue"), []), func(a = null): return (JS.t(a.get("label")) and JS.includes(a.get("label"), spell.get("name")))))
		# Queued non-multiUse cards disappear from hand (they show in played-card-row)
		if alreadyQueued:
			deckCount[0] += 1
			continue
		var canQueue = ((not outOfPP) if isFree else (not JS.t(queueFull) and not outOfPP))
		var dmgPrev = _spellDmgPreview(spell)
		var hintText = ("No PP" if outOfPP else JS.or_(dmgPrev, ""))
		var _fn42 = func():
			var snapTgt = [null]
			var spellRef = [null]
			var spellIdx = [null]
			var snapCD = [null]
			var isStormRushDependent = [null]
			var _doCardQueueSpell = [null]
			var _fn39 = func(extraPri = null):
				# CD:0 spells never go on cooldown — they redraw immediately
				# Air: pickPriority spells or Pressure Launch show choice popup
				var opts = {
					"isFree": isFree,
					"stormRushDependent": isStormRushDependent[0],
					"isSpellAction": true,
					"bookCatalogueId": (State.activeBook().get("catalogueId") if (JS.t(State.activeBook()) and JS.t(State.activeBook().get("catalogueId"))) else null),
					"spellObj": spell,
					"priority": (JS.or_(spell.get("priority"), 0)) + (JS.or_(extraPri, 0)),
				}
				if JS.t(spell.get("onQueue")):
					opts.onQueue = func(): return JS.callm(spell, "onQueue", [])
				if JS.t(spell.get("undoOnQueue")):
					opts.undoOnQueue = func(): return JS.callm(spell, "undoOnQueue", [])
				if spell.get("id") == "storm_rush":
					opts.stormRushAction = true
				var _fn38 = func():
					if not JS.t(spellRef[0].get("multiUse")):
						spellRef[0].currentCD = snapCD[0]
					if (JS.or_(spellRef[0].get("currentPP"), 0)) > 0:
						spellRef[0].currentPP -= 1
					State.setActiveEnemy(snapTgt[0])
					var ctx = Hit.makeSpellCtx("player", "enemy", spellIdx[0])
					JS.callm(spellRef[0], "execute", [ctx])
					if ((not JS.t(State.combat.get("over")) and spellRef[0].get("element") == "Water") and JS.t(State.status.get("player").get("deepCurrentActive"))):
						State.status.get("player").deepCurrentActive = false
						log_("💠 Deep Current: " + JS.s(spellRef[0].get("name")) + " fires again!", "player")
						State.setActiveEnemy(snapTgt[0])
						var ctx2 = Hit.makeSpellCtx("player", "enemy", spellIdx[0])
						JS.callm(spellRef[0], "execute", [ctx2])
					updateHPBars()
					renderStatusTags()
					updateStatsUI()
				Combat.queueAction(JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")), _fn38, opts)
				renderSpellButtons()
			_doCardQueueSpell[0] = _fn39
			if (not JS.t(isMyTurn) or not canQueue):
				return
			snapTgt[0] = State.combat.get("targetIdx")
			spellRef[0] = spell
			spellIdx[0] = JS.indexOf(State.player.get("spellbook"), spell)
			snapCD[0] = (0 if (JS.t(spell.get("multiUse")) or isZeroCD) else JS.or_(Helpers.adjustedCooldownFor("player", spell.get("baseCooldown")), 1))
			isStormRushDependent[0] = ((stormRushQueued and rawCD > 0) and effectiveCD == 0)
			if (JS.t(spell.get("instantUse")) and not JS.t(spell.get("pickPriority"))):
				var _iuIdx = JS.indexOf(State.player.get("spellbook"), spell)
				spell.currentCD = JS.or_(Helpers.adjustedCooldownFor("player", spell.get("baseCooldown")), spell.get("baseCooldown"))
				JS.callm(spell, "execute", [Hit.makeSpellCtx("player", "enemy", _iuIdx)])
				renderSpellButtons()
				Combat.updateActionUI()
				return
			if JS.t(spell.get("pickPriority")):
				var _fn40 = func(chosen = null):
					if JS.t(spell.get("instantUse")):
						State.combat._aoPriorityShift = chosen
						if (JS.or_(spell.get("currentPP"), 0)) > 0:
							spell.currentPP -= 1
						log_(JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")) + "! Subsequent spells: " + ("+" if chosen > 0 else "") + JS.s(chosen) + " priority.", "player")
						renderSpellButtons()
						Combat.updateActionUI()
						return
					_doCardQueueSpell[0].call(chosen)
				_showAirPriorityPopup(spell.get("pickPriority"), _fn40)
				return
			if ((Main.hasPassive("air_pressure_launch") and JS.eq(State.playerElement, "Air")) and (JS.or_(State.status.get("player").get("momentumStacks"), 0)) >= 10):
				var _fn41 = func(chosen = null):
					_doCardQueueSpell[0].call(chosen)
				_showAirPriorityPopup([{"label": "+1 (fast)", "value": 1}, {"label": "−1 (slow)", "value": -1}], _fn41)
				return
			_doCardQueueSpell[0].call(0)
		var card = _makeSpellCard(spell, _fn42, false, false, hintText)
		# end _doCardQueueSpell
		handEl.appendChild(card)
	# ── Item cards ───────────────────────────────────────────────────────────
	if JS.t(itemHandEl):
		var _arr43 = JS.iter(JS.or_(State.player.get("inventory"), []))
		for idx in range(len(_arr43)):
			var item = _arr43[idx]
			var _hTimer = [null]
			var ic = document.createElement("div")
			ic.className = "item-card"
			ic.innerHTML = ("<div class=\"ic-emoji\">" + JS.s(item.get("emoji")) + "</div>") + ("<div class=\"ic-name\">" + JS.s(item.get("name")) + "</div>") + "<div class=\"ic-cost\">USE (1 action)</div>"
			ic.title = JS.or_(item.get("desc"), item.get("name"))
			var _fn44 = func():
				Combat.useItemInCombat(idx)
			ic.onclick = _fn44
			# Hold-to-zoom
			_hTimer[0] = null
			var _fn45 = func():
				_hTimer[0] = JS.setTimeout(func(): return ic.classList.add("card-zoomed"), 420)
			ic.addEventListener("pointerdown", _fn45)
			var _fn46 = func():
				JS.clearTimeout(_hTimer[0])
				ic.classList.remove("card-zoomed")
			ic.addEventListener("pointerup", _fn46)
			var _fn47 = func():
				JS.clearTimeout(_hTimer[0])
				ic.classList.remove("card-zoomed")
			ic.addEventListener("pointerleave", _fn47)
			itemHandEl.appendChild(ic)
	# ── Card fan + draw animation ─────────────────────────────────────────────
	var _fanCards = JS.arr(handEl.querySelectorAll(".spell-card"))
	var _fanN = len(_fanCards)
	var _doDrawAnim = _drawAnimPending
	if JS.t(_doDrawAnim):
		_drawAnimPending = false
	var _newHandIds = JSSet.new()
	_newCardDelay[0] = 0
	var _arr48 = JS.iter(_fanCards)
	for i in range(len(_arr48)):
		var card = _arr48[i]
		var relI = ((i - ((_fanN - 1) / 2.0)) / float(max(_fanN - 1, 1)) if _fanN > 1 else 0)
		var angle = relI * (14 if _fanN > 1 else 0)
		var yDrop = abs(relI) * 20
		card.style.transformOrigin = "50% 120%"
		card.style.position = "relative"
		card.style.zIndex = JS.s(_fanN - JS.round(abs(relI) * (_fanN - 1)))
		card.style.transform = "rotate(" + JS.toFixed(angle, 1) + "deg) translateY(" + JS.toFixed(yDrop, 0) + "px)"
		var sid = JS.or_(card.dataset.get("spellId"), "")
		if JS.t(sid):
			_newHandIds.add(sid)
		# Only animate cards that weren't in hand last render (newly drawn)
		if (JS.t(_doDrawAnim) and not _prevHandSpellIds.has(sid)):
			var delay = _newCardDelay[0] * 75
			_newCardDelay[0] += 1
			card.style.animation = "cardFlyIn 0.42s cubic-bezier(0.22, 0.68, 0, 1.2) " + JS.s(delay) + "ms both"
	_prevHandSpellIds = _newHandIds
	# ── Deck counter ─────────────────────────────────────────────────────────
	if JS.t(deckCounter):
		deckCounter.textContent = ("📚 " + JS.s(deckCount[0]) + " on cooldown" if deckCount[0] > 0 else "")
	# ── Drag-to-scroll hand ───────────────────────────────────────────────────
	var _handRow = document.getElementById("card-hand-row")
	if JS.t(_handRow):
		var _isDragging = [null]
		var _didDrag = [null]
		var _capturedId = [null]
		var _dragStartX = [null]
		var _dragStartTx = [null]
		if JS.t(_handRow.get("_dragCleanup")):
			JS.callm(_handRow, "_dragCleanup", [])
		var _getMax = func(): return max(0, handEl.offsetWidth - _handRow.clientWidth)
		var _fn49 = func(x = null):
			var clamped = max(0, min(_getMax.call(), x))
			handEl.style.transform = ("translateX(" + JS.s(clamped) + "px)" if JS.t(clamped) else "")
			_handRow._txOffset = clamped
		var _applyTx = _fn49
		# Re-clamp saved offset after re-render (hand may have shrunk)
		if JS.t(_handRow.get("_txOffset")):
			_applyTx.call(_handRow.get("_txOffset"))
		_isDragging[0] = false
		_didDrag[0] = false
		_capturedId[0] = null
		_dragStartX[0] = 0
		_dragStartTx[0] = 0
		var _fn50 = func(e = null):
			_isDragging[0] = true
			_didDrag[0] = false
			_capturedId[0] = e.pointerId
			_dragStartX[0] = e.clientX
			_dragStartTx[0] = JS.or_(_handRow.get("_txOffset"), 0)
		var _onPDown = _fn50
		var _fn51 = func(e = null):
			if (not (_isDragging[0]) or not JS.eq(e.pointerId, _capturedId[0])):
				return
			var dx = e.clientX - _dragStartX[0]
			if (not (_didDrag[0]) and abs(dx) > 7):
				_didDrag[0] = true
				_handRow.setPointerCapture(e.pointerId)
				_handRow.classList.add("hand-dragging")
			# drag RIGHT reveals left cards (hand overflows left; translateX moves hand right)
			if _didDrag[0]:
				e.preventDefault()
				_applyTx.call(_dragStartTx[0] + dx)
		var _onPMove = _fn51
		var _fn53 = func():
			_isDragging[0] = false
			_handRow.classList.remove("hand-dragging")
			var _fn52 = func():
				_didDrag[0] = false
			JS.setTimeout(_fn52, 0)
		var _onPUp = _fn53
		var _fn54 = func(e = null):
			if _didDrag[0]:
				e.stopPropagation()
				e.preventDefault()
		var _onClickCapture = _fn54
		_handRow.addEventListener("pointerdown", _onPDown)
		_handRow.addEventListener("pointermove", _onPMove)
		_handRow.addEventListener("pointerup", _onPUp)
		_handRow.addEventListener("click", _onClickCapture, true)
		var _fn55 = func():
			_handRow.removeEventListener("pointerdown", _onPDown)
			_handRow.removeEventListener("pointermove", _onPMove)
			_handRow.removeEventListener("pointerup", _onPUp)
			_handRow.removeEventListener("click", _onClickCapture, true)
		_handRow._dragCleanup = _fn55

func _renderArenaDecks(isMyTurn = null, queueFull = null):
	var el = document.getElementById("arena-deck-switcher")
	if not JS.t(el):
		return
	el.style.display = "flex"
	el.innerHTML = ""
	for i in range(ceili(DECK_SLOT_COUNT)):
		var book = (JS.idx(State.player.get("spellbooks"), i) if JS.t(State.player.get("spellbooks")) else State.player.get("spellbooks"))
		var isActive = (i == State.player.get("activeBookIdx") if JS.t(book) else book)
		var slot = document.createElement("button")
		if not JS.t(book):
			slot.className = "arena-deck-slot empty"
			slot.disabled = true
			slot.innerHTML = "<div class=\"ads-art\"><svg viewBox=\"0 0 24 24\" width=\"36\" height=\"36\" xmlns=\"http://www.w3.org/2000/svg\"><rect x=\"4\" y=\"4\" width=\"16\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"#2a2018\" stroke-width=\"1.5\" stroke-dasharray=\"3 2\"/></svg></div>" + "<div class=\"ads-name\">Empty</div>"
		else:
			var _desc = (JS.or_((JS.or_(JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, book.get("catalogueId")), {})).get("desc"), "") if (JS.t(book.get("catalogueId")) and true) else "")
			slot.className = "arena-deck-slot" + (" active" if JS.t(isActive) else "")
			slot.disabled = JS.or_(JS.or_(isActive, (not JS.t(isMyTurn))), queueFull)
			slot.title = JS.s(book.get("name")) + ("\n" + _desc if JS.t(_desc) else "")
			var iconId = JS.or_(book.get("catalogueId"), "standard")
			var catEntry = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, iconId)
			var accentColor = (JS.or_(JS.idx({
				"Fire": "#e05830",
				"Water": "#3090d0",
				"Ice": "#70c8e0",
				"Lightning": "#e8d040",
				"Earth": "#907040",
				"Nature": "#50a830",
				"Plasma": "#c040d0",
				"Air": "#90b8cc",
			}, catEntry.get("element")), "#c8a060") if (JS.t(catEntry) and JS.t(catEntry.get("element"))) else "#c8a060")
			var svgArt = (JS.idx(DeckIcons.DECK_ICONS, iconId) if (true and JS.t(JS.idx(DeckIcons.DECK_ICONS, iconId))) else "<svg viewBox=\"0 0 24 24\" width=\"36\" height=\"36\" xmlns=\"http://www.w3.org/2000/svg\"><text x=\"12\" y=\"17\" text-anchor=\"middle\" font-size=\"14\">" + (JS.or_(book.get("emoji"), "📖")) + "</text></svg>")
			var shortName = JS.join(JS.slice(JS.split(book.get("name"), " "), 0, 2), " ")
			slot.innerHTML = ("<div class=\"ads-art\" style=\"--accent:" + accentColor + "\">" + JS.s(svgArt) + "</div>") + ("<div class=\"ads-name\" style=\"color:" + accentColor + "\">" + shortName + "</div>")
			var _fn56 = func():
				Combat.queueSwitchBook(i)
			slot.onclick = _fn56
		el.appendChild(slot)

# Bottom-right: end turn button + actions remaining
func _renderArenaEndTurn(isMyTurn = null):
	var panel = document.getElementById("arena-endturn-panel")
	var btn = document.getElementById("arena-end-turn-btn")
	var label = document.getElementById("arena-actions-left-label")
	if not JS.t(panel):
		return
	panel.style.display = "flex"
	var hasActions = len(JS.or_(State.combat.get("actionQueue"), [])) > 0
	var queued = len(JS.arr(JS.or_(State.combat.get("actionQueue"), [])).filter(func(a = null): return not JS.t(a.get("isFree"))))
	var total = JS.or_(State.combat.get("actionsLeft"), 0)
	if JS.t(btn):
		btn.disabled = JS.or_(JS.or_((not JS.t(State.combat.get("playerTurn"))), State.combat.get("over")), (not hasActions))
		btn.className = "arena-endturn-btn" + (" ready" if hasActions else "")
		btn.textContent = ("⚔ End Turn (" + JS.s(len(State.combat.get("actionQueue"))) + ")" if hasActions else "⚔ End Turn")
	if JS.t(label):
		label.textContent = JS.s(queued) + " / " + JS.s(total) + " actions"
	# Items / Deck toggle button
	var itemToggleBtn = document.getElementById("arena-item-toggle-btn")
	if not JS.t(itemToggleBtn):
		itemToggleBtn = document.createElement("button")
		itemToggleBtn.id = "arena-item-toggle-btn"
		itemToggleBtn.className = "arena-item-toggle-btn"
		panel.appendChild(itemToggleBtn)
	var itemCount = len(JS.or_(State.player.get("inventory"), []))
	itemToggleBtn.textContent = ("← Deck" if JS.t(_showingItemHand) else "Items (" + JS.s(itemCount) + ")")
	itemToggleBtn.style.display = ("" if (itemCount > 0 or JS.t(_showingItemHand)) else "none")
	var _fn57 = func():
		_showingItemHand = (not JS.t(_showingItemHand))
		renderSpellButtons()
	itemToggleBtn.onclick = _fn57
	# Mirror actions count into the deck stats panel
	var dspActions = document.getElementById("dsp-actions")
	if JS.t(dspActions):
		dspActions.textContent = JS.s(queued) + " / " + JS.s(total)
		dspActions.style.color = ("#f0c060" if (queued >= total and total > 0) else "#8a6a40")

# Below player HUD: passive pips
func _renderArenaPassives():
	var el = document.getElementById("arena-passives")
	if not JS.t(el):
		return
	var passiveIds = JS.or_(State.player.get("passives"), [])
	if len(passiveIds) == 0:
		el.style.display = "none"
		return
	el.style.display = "flex"
	el.style.cursor = "pointer"
	el.onclick = _showPassivePanel
	el.innerHTML = "<span class=\"arena-passives-label\">Passives ▶</span>"

func _showPassivePanel():
	var overlay = document.getElementById("passive-panel-overlay")
	var list = document.getElementById("passive-panel-list")
	var empty = document.getElementById("passive-panel-empty")
	if (not JS.t(overlay) or not JS.t(list)):
		return
	list.innerHTML = ""
	var passiveIds = JS.or_(State.player.get("passives"), [])
	var passiveCap = JS.or_(State.player.get("passiveSlots"), 6)
	var countEl = document.getElementById("passive-panel-count")
	if JS.t(countEl):
		countEl.textContent = JS.s(len(passiveIds)) + " / " + JS.s(passiveCap)
	if len(passiveIds) == 0:
		if JS.t(empty):
			empty.style.display = "block"
		list.style.display = "none"
	else:
		if JS.t(empty):
			empty.style.display = "none"
		list.style.display = "flex"
		for pid in JS.iter(passiveIds):
			var pdef = [null]
			pdef[0] = null
			for arr in JS.iter(JS.values(JS.or_(Passives.PASSIVE_CHOICES, {}))):
				var found = JS.find(JS.or_(arr, []), func(p = null): return JS.eq(p.id, pid))
				if JS.t(found):
					pdef[0] = found
			var card = document.createElement("div")
			card.style.cssText = "background:#120f0b;border:1px solid #2a2010;border-radius:6px;padding:.65rem .8rem;"
			var nameRow = document.createElement("div")
			nameRow.style.cssText = "display:flex;align-items:center;gap:.45rem;margin-bottom:.3rem;"
			var iconWrap = document.createElement("span")
			iconWrap.innerHTML = (PassiveIcons.passiveIconSVG(pdef[0], 20) if JS.t(pdef[0]) else "")
			var nameEl = document.createElement("span")
			nameEl.style.cssText = "font-family:'Cinzel',serif;font-size:.82rem;color:#c8a060;"
			nameEl.textContent = (JS.or_(JS.or_(pdef[0].get("title"), pdef[0].get("name")), pid) if JS.t(pdef[0]) else pid)
			nameRow.appendChild(iconWrap)
			nameRow.appendChild(nameEl)
			if (JS.t(pdef[0]) and JS.t(pdef[0].get("legendary"))):
				var badge = document.createElement("span")
				badge.style.cssText = "font-size:.55rem;color:#e8a020;border:1px solid #8a5010;border-radius:3px;padding:.1rem .3rem;margin-left:auto;letter-spacing:.05em;"
				badge.textContent = "LEGENDARY"
				nameRow.appendChild(badge)
			card.appendChild(nameRow)
			if (JS.t(pdef[0]) and JS.t(pdef[0].get("desc"))):
				var descEl = document.createElement("div")
				descEl.style.cssText = "font-size:.7rem;color:#a09080;line-height:1.4;"
				descEl.textContent = pdef[0].get("desc")
				card.appendChild(descEl)
			if (JS.t(pdef[0]) and JS.t(pdef[0].get("detail"))):
				var detEl = document.createElement("div")
				detEl.style.cssText = "font-size:.63rem;color:#5a6a5a;margin-top:.3rem;line-height:1.35;border-top:1px solid #1a1a12;padding-top:.3rem;"
				detEl.textContent = pdef[0].detail
				card.appendChild(detEl)
			list.appendChild(card)
	overlay.style.display = "flex"

func _closePassivePanel():
	var overlay = document.getElementById("passive-panel-overlay")
	if JS.t(overlay):
		overlay.style.display = "none"
