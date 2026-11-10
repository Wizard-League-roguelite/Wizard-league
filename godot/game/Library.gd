# Library — generated from js/ui/library.js by tools/js2gd.js
extends Node

var LIBRARY_ELEMENTS = null
var _LIB_EL_EMOJI = null
var _libActiveEl = null
var _libRoot = null
var _LIB_SPECIAL_TABS = null
var _LIB_SPECIAL_EMOJI = null

func _boot():
	# ===== library.js =====
	# Spell Library — elemental reference + discovery tracker
	LIBRARY_ELEMENTS = ["Fire", "Water", "Ice", "Lightning", "Earth", "Nature", "Plasma", "Air", "Duo"]
	_LIB_EL_EMOJI = {
		"Fire": "🔥",
		"Water": "💧",
		"Ice": "❄️",
		"Lightning": "⚡",
		"Earth": "🪨",
		"Nature": "🌿",
		"Plasma": "🔮",
		"Air": "🌀",
		"Duo": "✦",
	}
	# null = standalone overlay, else popup panel element
	_LIB_SPECIAL_TABS = ["Mechanics", "Combat"]
	_LIB_SPECIAL_EMOJI = {"Mechanics": "⚙️", "Combat": "⚔️"}

# ─── DISCOVERY TRACKING ────────────────────────────────────────────────────
func markSpellSeen(id = null):
	var meta = Artifacts.getMeta()
	if not JS.t(meta.get("seenSpells")):
		meta.seenSpells = []
	if not JS.includes(meta.get("seenSpells"), id):
		meta.get("seenSpells").append(id)
		Artifacts.saveMeta()

func markPassiveSeen(id = null):
	var meta = Artifacts.getMeta()
	if not JS.t(meta.get("seenPassives")):
		meta.seenPassives = []
	if not JS.includes(meta.get("seenPassives"), id):
		meta.get("seenPassives").append(id)
		Artifacts.saveMeta()

# ─── DATA HELPERS ──────────────────────────────────────────────────────────
func _libSpellsFor(el = null):
	if el == "Duo":
		return JS.arr(JS.values(Spells.SPELL_CATALOGUE)).filter(func(s = null): return s.get("tier") == "merged")
	return JS.arr(JS.values(Spells.SPELL_CATALOGUE)).filter(func(s = null): return JS.eq(s.get("element"), el))

func _libPassivesFor(el = null):
	if el == "Duo":
		return JS.or_(JS.idx(Passives.PASSIVE_CHOICES, "Duo"), [])
	return JS.or_(JS.idx(Passives.PASSIVE_CHOICES, el), [])

func _libCounts(el = null, seenSpells = null, seenPassives = null):
	var total = [null]
	var seen = [null]
	total[0] = 0
	seen[0] = 0
	for s in JS.iter(_libSpellsFor(el)):
		total[0] += 1
		if (JS.t(s.get("isStarter")) or seenSpells.has(s.id)):
			seen[0] += 1
	for p in JS.iter(_libPassivesFor(el)):
		total[0] += 1
		if seenPassives.has(p.id):
			seen[0] += 1
	return {"seen": seen[0], "total": total[0]}

# ─── TOOLTIP ENGINE ────────────────────────────────────────────────────────
func _libTipShow(e = null, html = null):
	var tip = document.getElementById("lib-tooltip")
	if not JS.t(tip):
		return
	tip.innerHTML = html
	tip.style.display = "block"
	_libTipMove(e)

func _libTipMove(e = null):
	var tip = document.getElementById("lib-tooltip")
	if (not JS.t(tip) or tip.style.get("display") == "none"):
		return
	var margin = 12
	var x = e.clientX + margin
	var y = e.clientY + margin
	var tw = JS.or_(tip.get("offsetWidth"), 280)
	var th = JS.or_(tip.get("offsetHeight"), 60)
	if (x + tw) > (window.innerWidth - 4):
		x = (e.clientX - tw) - margin
	if (y + th) > (window.innerHeight - 4):
		y = (e.clientY - th) - margin
	tip.style.left = JS.s(x) + "px"
	tip.style.top = JS.s(y) + "px"

func _libTipHide():
	var tip = document.getElementById("lib-tooltip")
	if JS.t(tip):
		tip.style.display = "none"

# Attach tooltip listeners to an element
func _libTip(el = null, htmlFn = null):
	el.addEventListener("mouseenter", func(e = null): return _libTipShow(e, htmlFn.call()))
	el.addEventListener("mousemove", func(e = null): return _libTipMove(e))
	el.addEventListener("mouseleave", _libTipHide)

# Build formula HTML for a spell
func _libSpellFormulaHtml(spell = null):
	var lines = []
	# Incantation scaling
	var cfg = JS.idx(Incantations.SPELL_INCANTATION_CONFIG, spell.id)
	var base = JS.idx(Incantations._INCANTATION_BASE_VALUES, spell.id)
	if (JS.t(cfg) and base != null):
		var label = JS.or_(JS.idx(Incantations._STAT_LABELS, cfg.get("scaledStat")), cfg.get("scaledStat"))
		var isFloat = (((((cfg.get("scaledStat") == "frostStacks" or cfg.get("scaledStat") == "shockStacks") or cfg.get("scaledStat") == "frostApplied") or cfg.get("scaledStat") == "multiplier") or cfg.get("scaledStat") == "lifeStealPct") or cfg.get("scaledStat") == "rootChance")
		var _fn1 = func(v = null):
			if (cfg.get("scaledStat") == "rootChance" or cfg.get("scaledStat") == "lifeStealPct"):
				return JS.s(JS.round(v * 100)) + "%"
			if cfg.get("scaledStat") == "multiplier":
				return "×" + JS.toFixed(v, 2)
			return (JS.toFixed(v, 1) if isFloat else JS.round(v))
		var fmtVal = _fn1
		var baseDisp = fmtVal.call(base)
		var lv2Disp = fmtVal.call(base + cfg.get("baseScale"))
		var decayNote = (" (×" + JS.s(cfg.get("decay")) + " decay)" if cfg.get("decay") < 1 else "")
		lines.append("<div style=\"color:#a0c0ff;font-size:.62rem;\"><span style=\"color:#6a8aaa;\">Incantation:</span> " + JS.s(label) + " — base " + JS.s(baseDisp) + ", lv2 " + JS.s(lv2Disp) + ", +" + JS.s(cfg.get("baseScale")) + decayNote + "</div>")
	# Tags
	if (JS.t(spell.get("tags")) and JS.t(len(spell.get("tags")))):
		lines.append("<div style=\"color:#888;font-size:.58rem;\">Tags: " + JS.join(spell.get("tags"), ", ") + "</div>")
	# CD
	lines.append("<div style=\"color:#666;font-size:.58rem;\">Cooldown: " + JS.s(spell.get("baseCooldown")) + " turn" + ("s" if not JS.eq(spell.get("baseCooldown"), 1) else "") + "</div>")
	if not JS.t(len(lines)):
		return "<div style=\"color:#666;font-size:.62rem;\">No formula data.</div>"
	return "<div style=\"font-family:'Cinzel',serif;font-size:.65rem;color:#c8a060;margin-bottom:.3rem;display:flex;align-items:center;gap:.3rem;\">" + SpellIcons.spellIconSVG(spell, 18) + " " + JS.s(spell.get("name")) + "</div>" + JS.join(lines, "")

# Build formula HTML for a passive
func _libPassiveFormulaHtml(passive = null):
	var detail = passive.detail
	var name_ = "<div style=\"font-family:'Cinzel',serif;font-size:.65rem;color:#c8a060;margin-bottom:.3rem;display:flex;align-items:center;gap:.3rem;\">" + PassiveIcons.passiveIconSVG(passive, 16) + " " + JS.s(passive.title) + "</div>"
	if JS.t(detail):
		return name_ + ("<div style=\"color:#a0c0ff;font-size:.62rem;line-height:1.5;\">" + JS.s(detail) + "</div>")
	return name_ + "<div style=\"color:#555;font-size:.62rem;\">No additional formula data.</div>"

func _libGetTabs():
	return ((_libRoot if JS.t(_libRoot) else document.getElementById("spell-library-overlay"))).querySelector(".lib-tabs")

func _libGetContent():
	return ((_libRoot if JS.t(_libRoot) else document.getElementById("spell-library-overlay"))).querySelector(".lib-content")

# ─── OVERLAY ───────────────────────────────────────────────────────────────
func showLibrary():
	_libRoot = null
	var visibleEls = (JS.arr(LIBRARY_ELEMENTS).filter(func(el = null): return (JS.includes(Constants.RELEASED_ELEMENTS, el) or el == "Duo")) if not JS.t(Constants.sandboxMode) else LIBRARY_ELEMENTS)
	if (not JS.t(_libActiveEl) or not JS.includes(visibleEls, _libActiveEl)):
		_libActiveEl = JS.idx(visibleEls, 0)
	_libRender()
	document.getElementById("spell-library-overlay").style.display = "flex"

func closeLibrary():
	_libTipHide()
	document.getElementById("spell-library-overlay").style.display = "none"

# ─── RENDER ────────────────────────────────────────────────────────────────
func _libRender():
	_libRenderTabs()
	_libRenderContent()

func _libRenderTabs():
	var tabs = _libGetTabs()
	if not JS.t(tabs):
		return
	tabs.innerHTML = ""
	tabs.style.flexDirection = "column"
	tabs.style.gap = ".3rem"
	var meta = Artifacts.getMeta()
	var seenSpells = JSSet.new(JS.or_(meta.get("seenSpells"), []))
	var seenPassives = JSSet.new(JS.or_(meta.get("seenPassives"), []))
	# Row 1: element tabs — non-sandbox only shows released elements + Duo
	var visibleElements = (JS.arr(LIBRARY_ELEMENTS).filter(func(el = null): return (JS.includes(Constants.RELEASED_ELEMENTS, el) or el == "Duo")) if not JS.t(Constants.sandboxMode) else LIBRARY_ELEMENTS)
	var row1 = document.createElement("div")
	row1.style.cssText = "display:flex;gap:.25rem;"
	for el in JS.iter(visibleElements):
		var _d2 = _libCounts(el, seenSpells, seenPassives)
		var seen = JS.idx(_d2, "seen")
		var total = JS.idx(_d2, "total")
		var active = JS.eq(el, _libActiveEl)
		var pct = (seen / float(total) if total > 0 else 0)
		var countCol = ("#4aaa6a" if pct >= 1 else ("#c8a060" if pct > 0 else "#444"))
		var emoji = JS.or_(JS.idx(_LIB_EL_EMOJI, el), "✦")
		var btn = document.createElement("button")
		btn.style.cssText = JS.join([
			"flex:1;min-width:0;padding:.3rem .2rem;border-radius:4px;cursor:pointer;",
			"display:flex;flex-direction:column;align-items:center;gap:.1rem;",
			"border:1px solid " + ("#c8a060" if active else "#2a2420") + ";",
			"background:" + ("#1a1208" if active else "#0a0906") + ";",
		], "")
		btn.innerHTML = "\n      <span style=\"font-size:.85rem;line-height:1;\">" + emoji + "</span>\n      <span style=\"font-size:.45rem;color:" + countCol + ";font-family:'Cinzel',serif;\">" + JS.s(seen) + "/" + JS.s(total) + "</span>"
		btn.title = el
		var _fn3 = func():
			_libActiveEl = el
			_libRender()
		btn.onclick = _fn3
		row1.appendChild(btn)
	tabs.appendChild(row1)
	# Row 2: special guide tabs
	var row2 = document.createElement("div")
	row2.style.cssText = "display:flex;gap:.25rem;"
	for tab in JS.iter(_LIB_SPECIAL_TABS):
		var active = JS.eq(tab, _libActiveEl)
		var emoji = JS.or_(JS.idx(_LIB_SPECIAL_EMOJI, tab), "📖")
		var btn = document.createElement("button")
		btn.style.cssText = JS.join([
			"flex:1;padding:.28rem .4rem;border-radius:4px;cursor:pointer;",
			"display:flex;align-items:center;justify-content:center;gap:.3rem;",
			"border:1px solid " + ("#6a8aaa" if active else "#1e2830") + ";",
			"background:" + ("#091420" if active else "#060c14") + ";",
			"color:#6a9ac0;font-size:.6rem;font-family:'Cinzel',serif;letter-spacing:.04em;",
		], "")
		btn.innerHTML = "<span style=\"font-size:.75rem;\">" + emoji + "</span><span>" + JS.s(tab) + "</span>"
		var _fn4 = func():
			_libActiveEl = tab
			_libRender()
		btn.onclick = _fn4
		row2.appendChild(btn)
	tabs.appendChild(row2)

func _libRenderContent():
	var cont = _libGetContent()
	if not JS.t(cont):
		return
	cont.innerHTML = ""
	var el = _libActiveEl
	if not JS.t(el):
		return
	if el == "Mechanics":
		_libRenderMechanics(cont)
		return
	if el == "Combat":
		_libRenderCombat(cont)
		return
	var meta = Artifacts.getMeta()
	var seenSpells = JSSet.new(JS.or_(meta.get("seenSpells"), []))
	var seenPassives = JSSet.new(JS.or_(meta.get("seenPassives"), []))
	var allSpells = _libSpellsFor(el)
	if el == "Duo":
		if len(allSpells) > 0:
			var disc = len(JS.arr(allSpells).filter(func(s = null): return seenSpells.has(s.id)))
			cont.appendChild(_libSectionHdr("Merged Spells", disc, len(allSpells)))
			for s in JS.iter(allSpells):
				cont.appendChild(_libSpellRow(s, seenSpells.has(s.id)))
		var passives = _libPassivesFor(el)
		if len(passives) > 0:
			var disc = len(JS.arr(passives).filter(func(p = null): return seenPassives.has(p.id)))
			cont.appendChild(_libSectionHdr("Duo Passives", disc, len(passives)))
			for p in JS.iter(passives):
				cont.appendChild(_libPassiveRow(p, seenPassives.has(p.id)))
		return
	var tiers = [
		{"key": "primary", "label": "Primary"},
		{"key": "secondary", "label": "Secondary"},
		{"key": "legendary", "label": "Legendary Spells"},
	]
	for _e5 in JS.iter(tiers):
		var key = JS.idx(_e5, "key")
		var label = JS.idx(_e5, "label")
		var spells = JS.arr(allSpells).filter(func(s = null): return (JS.or_(s.get("tier"), "secondary")) == key)
		if not JS.t(len(spells)):
			continue
		var revealedCount = len(JS.arr(spells).filter(func(s = null): return (JS.t(s.get("isStarter")) or seenSpells.has(s.id))))
		cont.appendChild(_libSectionHdr(label, revealedCount, len(spells)))
		for s in JS.iter(spells):
			cont.appendChild(_libSpellRow(s, (s.get("isStarter") if JS.t(s.get("isStarter")) else seenSpells.has(s.id))))
	var allPassives = _libPassivesFor(el)
	var normPassives = JS.arr(allPassives).filter(func(p = null): return not JS.t(p.get("legendary")))
	var legendPassives = JS.arr(allPassives).filter(func(p = null): return JS.t(p.get("legendary")))
	if len(normPassives) > 0:
		var disc = len(JS.arr(normPassives).filter(func(p = null): return seenPassives.has(p.id)))
		cont.appendChild(_libSectionHdr("Passives", disc, len(normPassives)))
		for p in JS.iter(normPassives):
			cont.appendChild(_libPassiveRow(p, seenPassives.has(p.id)))
	if len(legendPassives) > 0:
		var disc = len(JS.arr(legendPassives).filter(func(p = null): return seenPassives.has(p.id)))
		cont.appendChild(_libSectionHdr("Legendary Passives", disc, len(legendPassives)))
		for p in JS.iter(legendPassives):
			cont.appendChild(_libPassiveRow(p, seenPassives.has(p.id)))
	if not JS.t(len(cont.children)):
		var empty = document.createElement("div")
		empty.style.cssText = "color:#444;font-size:.7rem;padding:1.5rem;text-align:center;"
		empty.textContent = "Nothing recorded for this element yet."
		cont.appendChild(empty)

# ─── COMBAT PREVIEW SIMULATION ─────────────────────────────────────────────
# Run spell.execute() in a sandboxed environment, capture damage/effect events,
# then restore all globals.  Safe to call at any game state (map, between runs, etc.)
func _libSimulateSpell(spell = null):
	if (not JS.t(spell) or (JS.typeof_(spell.get("execute"))) != "function"):
		return []
	var events = []
	var simAtk = max(0, State.player.get("attackPower"))
	var simEfx = max(0, State.player.get("effectPower"))
	# Minimal spell context — mirrors makeSpellCtx without touching real game state
	var _fn6 = func():
		pass
	var _fn7 = func():
		pass
	var _fn8 = func(amt = null):
		if amt > 0:
			events.append({"type": "heal", "amount": JS.round(amt)})
	var _fn10 = func(pkg = null):
		var hits = JS.or_(pkg.get("hits"), 1)
		var bd = max(0, JS.or_(pkg.get("baseDamage"), 0))
		var mult = JS.or_(spell.get("dmgMult"), 1.0)
		var perHit = JS.round((bd + simAtk) * mult)
		# Plasma: EFX adds to damage the same way ATK does
		var isPlasma = State.playerElement == "Plasma"
		if isPlasma:
			perHit += simEfx
		# Apply real effect formulas (mirroring performHit)
		var _fn9 = func(ef = null):
			if ef.get("type") == "burn":
				var powerBonus = floori(simEfx * 0.2)
				var actualStacks = (JS.or_(ef.get("stacks"), 0)) + powerBonus
				return JS.merge([ef, {"stacks": actualStacks, "_rawStacks": JS.or_(ef.get("stacks"), 0)}])
			return JS.merge([ef])
		var processedEffects = JS.arr(JS.or_(pkg.get("effects"), [])).map(_fn9)
		events.append({
			"type": "damage",
			"hits": hits,
			"dmgPerHit": perHit,
			"total": perHit * hits,
			"effects": processedEffects,
			"isAOE": (not (not JS.t(pkg.get("isAOE")))),
			"_isPlasma": isPlasma,
		})
	var mockS = {
		"attackerSide": "player",
		"defenderSide": "enemy",
		"attackPow": func(): return simAtk,
		"effectPow": func(): return simEfx,
		"defStat": func(): return 0,
		"effectivePower": func(): return simAtk,
		"pushTempPower": _fn6,
		"log": _fn7,
		"healSelf": _fn8,
		"hit": _fn10,
	}
	var mockEnemyStatus = JS.merge([State.STATUS_DEFAULTS, {"block": 50}])
	var mockPlayerStatus = JS.merge([State.STATUS_DEFAULTS])
	var mockEnemy = {
		"hp": 50,
		"enemyMaxHP": 50,
		"alive": true,
		"status": mockEnemyStatus,
		"statPow": 5,
		"statEfx": 5,
		"statDef": 5,
		"element": "Neutral",
		"name": "Dummy",
		"enemyDmg": 10,
		"items": [],
		"extraPassives": [],
	}
	# Functions to silence (DOM/animation/render side-effects)
	var _noopKeys = [
		"renderStatusTags",
		"renderEnemyCards",
		"renderBattlefield",
		"renderSummonsRow",
		"updateHPBars",
		"updateActionUI",
		"updateStatsUI",
		"triggerSpellAnim",
		"triggerHealAnim",
		"log",
		"checkDeath",
		"checkWin",
		"setActiveEnemy",
		"aliveEnemies",
	]
	# Functions to intercept and capture
	var _captureKeys = ["applyDirectDamage", "applyMelt", "totalEnemyBurnStacks"]
	var _saved = {}
	for k in JS.iter(JS.arr(_noopKeys) + JS.arr(_captureKeys)):
		_saved[k] = JS.idx(window, k)
	# Save the slice of combat/status we will temporarily overwrite
	var _sc = {
		"enemies": State.combat.get("enemies"),
		"enemy": State.combat.get("enemy"),
		"activeEnemyIdx": State.combat.get("activeEnemyIdx"),
		"targetIdx": State.combat.get("targetIdx"),
		"over": State.combat.get("over"),
	}
	var _ssPlayer = State.status.get("player")
	var _ssEnemy = State.status.get("enemy")
	for k in JS.iter(_noopKeys):
		var _fn11 = func():
			pass
		JS.hook(k, _fn11)
	var _fn12 = func(_a = null, _d = null, dmg = null, label = null):
		if dmg > 0:
			events.append({"type": "damage", "hits": 1, "dmgPerHit": dmg, "total": dmg, "effects": [], "label": JS.or_(label, "")})
	JS.hook("applyDirectDamage", _fn12)
	var _fn13 = func(_a = null, _d = null, pts = null):
		if pts <= 0:
			return
		var armor = JS.or_(mockEnemyStatus.get("block"), 0)
		var breakCost = (ceili(armor / 3.0) if armor > 0 else 0)
		var armorDestroyed = 0
		var hpDmg = 0
		if (armor > 0 and pts >= breakCost):
			armorDestroyed = armor
			hpDmg = pts - breakCost
			mockEnemyStatus.block = 0
		elif armor > 0:
			armorDestroyed = pts * 3
			hpDmg = 0
		else:
			hpDmg = pts
		events.append({"type": "melt", "pts": pts, "armorDestroyed": armorDestroyed, "hpDmg": hpDmg})
	JS.hook("applyMelt", _fn13)
	JS.hook("totalEnemyBurnStacks", func(): return 0)
	State.combat.enemies = [mockEnemy]
	State.combat.enemy = mockEnemy
	State.combat.activeEnemyIdx = 0
	State.combat.targetIdx = 0
	State.combat.over = false
	State.status.player = mockPlayerStatus
	State.status.enemy = mockEnemyStatus
	JS.callm(spell, "execute", [mockS])
	# keep whatever was captured
	for k in JS.iter(JS.arr(_noopKeys) + JS.arr(_captureKeys)):
		JS.unhook(k)
	State.combat.enemies = _sc.get("enemies")
	State.combat.enemy = _sc.get("enemy")
	State.combat.activeEnemyIdx = _sc.get("activeEnemyIdx")
	State.combat.targetIdx = _sc.get("targetIdx")
	State.combat.over = _sc.get("over")
	State.status.player = _ssPlayer
	State.status.enemy = _ssEnemy
	return events

# Build the combat-preview section of the tooltip HTML
func _libCombatPreviewHtml(spell = null):
	var html = [null]
	var simAtk = State.player.get("attackPower")
	var events = _libSimulateSpell(spell)
	var dmgEvents = JS.arr(events).filter(func(e = null): return e.get("type") == "damage")
	var meltEvents = JS.arr(events).filter(func(e = null): return e.get("type") == "melt")
	var healEvents = JS.arr(events).filter(func(e = null): return e.get("type") == "heal")
	var totalDmg = JS.reduce(dmgEvents, func(s = null, e = null): return s + e.get("total"), 0) + JS.reduce(meltEvents, func(s = null, e = null): return s + (JS.or_(e.get("hpDmg"), 0)), 0)
	var effectEmojiMap = {"burn": "🔥", "frost": "❄️", "stun": "💫", "shock": "⚡", "root": "🌿", "foam": "🫧", "block": "🛡️"}
	html[0] = "<div style=\"font-family:'Cinzel',serif;font-size:.65rem;color:#c8a060;margin-bottom:.35rem;padding-bottom:.25rem;border-bottom:1px solid #2a2010;\">\n    ⚔️ " + JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")) + " — Combat Preview\n  </div>"
	html[0] += "<div style=\"font-size:.52rem;color:#6a4a20;margin-bottom:.3rem;\">vs. Dummy Enemy &nbsp;·&nbsp; 50 HP &nbsp;·&nbsp; 50 Armor</div>"
	html[0] += "<div style=\"font-size:.58rem;line-height:1.75;color:#c0a870;\">"
	html[0] += "<div style=\"color:#7080a0;margin-bottom:.2rem;\">🧙 You cast the spell...</div>"
	if ((len(dmgEvents) == 0 and len(meltEvents) == 0) and len(healEvents) == 0):
		html[0] += "<div style=\"color:#6a5a40;font-style:italic;\">No direct damage — buff / effect spell</div>"
	for ev in JS.iter(dmgEvents):
		var simEfx = State.player.get("effectPower")
		# Build breakdown suffix
		var breakdown = null
		if JS.t(ev.get("_isPlasma")):
			var base = max(0, (ev.get("dmgPerHit") - simAtk) - simEfx)
			breakdown = "(" + JS.s(base) + " base + " + JS.s(simAtk) + " ATK + " + JS.s(simEfx) + " EFX)"
		else:
			var base = max(0, ev.get("dmgPerHit") - simAtk)
			breakdown = "(" + JS.s(base) + " base + " + JS.s(simAtk) + " ATK)"
		if JS.t(ev.get("isAOE")):
			html[0] += "<div>💥 AoE hit → <span style=\"color:#ffcc88;font-weight:bold;\">" + JS.s(ev.get("dmgPerHit")) + " dmg</span> <span style=\"color:#443a28;font-size:.5rem;\">each · " + breakdown + "</span></div>"
		elif ev.get("hits") > 1:
			html[0] += "<div>⚔️ " + JS.s(ev.get("hits")) + " hits × <span style=\"color:#ffcc88;\">" + JS.s(ev.get("dmgPerHit")) + "</span> = <span style=\"color:#ffdd99;font-weight:bold;\">" + JS.s(ev.get("total")) + " dmg</span> <span style=\"color:#3e3020;font-size:.5rem;\">" + breakdown + "</span></div>"
		else:
			html[0] += "<div>⚔️ <span style=\"color:#ffdd99;font-weight:bold;\">" + JS.s(ev.get("total")) + " dmg</span> <span style=\"color:#3e3020;font-size:.5rem;\">" + breakdown + "</span></div>"
		# Effects from this hit — multiply per-hit stacks by number of hits
		var efGrp = {}
		for ef in JS.iter(JS.or_(ev.get("effects"), [])):
			efGrp[ef.type] = (JS.or_(JS.idx(efGrp, ef.type), 0)) + (JS.or_(ef.get("stacks"), 1))
		for _e14 in JS.iter(JS.entries(efGrp)):
			var type_ = JS.idx(_e14, 0)
			var perHit = JS.idx(_e14, 1)
			var total = perHit * ev.get("hits")
			var detail = (JS.s(perHit) + " × " + JS.s(ev.get("hits")) + " hits = <span style=\"color:#d4aa60;\">" + JS.s(total) + "</span>" if ev.get("hits") > 1 else "<span style=\"color:#d4aa60;\">" + JS.s(total) + "</span>")
			html[0] += "<div style=\"padding-left:.6rem;color:#a09060;\">" + (JS.or_(JS.idx(effectEmojiMap, type_), "✦")) + " " + detail + " " + JS.s(type_) + "</div>"
	for ev in JS.iter(meltEvents):
		if (ev.get("armorDestroyed") > 0 and ev.get("hpDmg") > 0):
			html[0] += "<div>⚒️ Melt → strips <span style=\"color:#aaddff;\">" + JS.s(ev.get("armorDestroyed")) + " armor</span>, then <span style=\"color:#ffdd99;font-weight:bold;\">" + JS.s(ev.get("hpDmg")) + " HP dmg</span></div>"
		elif ev.get("armorDestroyed") > 0:
			html[0] += "<div>⚒️ Melt → strips <span style=\"color:#aaddff;\">" + JS.s(ev.get("armorDestroyed")) + " armor</span> <span style=\"color:#3e3020;font-size:.5rem;\">(no HP dmg — not enough pts)</span></div>"
		else:
			html[0] += "<div>⚒️ Melt → <span style=\"color:#ffdd99;font-weight:bold;\">" + JS.s(ev.get("hpDmg")) + " HP dmg</span></div>"
	for ev in JS.iter(healEvents):
		html[0] += "<div>💚 Heal self → <span style=\"color:#88ee88;\">+" + JS.s(ev.get("amount")) + " HP</span></div>"
	if (totalDmg > 0 and len(JS.arr(events).filter(func(e = null): return e.get("type") != "heal")) > 1):
		html[0] += "<div style=\"margin-top:.25rem;padding-top:.25rem;border-top:1px solid #2a2010;color:#ffee99;font-weight:bold;\">Total: " + JS.s(totalDmg) + " dmg</div>"
	html[0] += "</div>"
	var simEfxFooter = State.player.get("effectPower")
	html[0] += "<div style=\"font-size:.44rem;color:#3a2818;margin-top:.3rem;padding-top:.25rem;border-top:1px solid #1a1208;\">Simulated · ATK: " + JS.s(simAtk) + " &nbsp;·&nbsp; EFX: " + JS.s(simEfxFooter) + "</div>"
	return html[0]

# ─── ROW BUILDERS ──────────────────────────────────────────────────────────
func _libSectionHdr(label = null, seen = null, total = null):
	var d = document.createElement("div")
	var pct = (seen / float(total) if total > 0 else 0)
	var col = ("#4aaa6a" if pct >= 1 else ("#c8a060" if pct > 0 else "#6a4a20"))
	d.style.cssText = "display:flex;justify-content:space-between;align-items:center;font-size:.56rem;color:#6a4a20;letter-spacing:.08em;text-transform:uppercase;margin:.65rem 0 .2rem;padding-bottom:.2rem;border-bottom:1px solid #1a1512;"
	d.innerHTML = "<span>" + JS.s(label) + "</span><span style=\"color:" + col + ";\">" + JS.s(seen) + " / " + JS.s(total) + "</span>"
	return d

func _libSpellRow(spell = null, revealed = null):
	var row = document.createElement("div")
	row.style.cssText = "display:flex;align-items:flex-start;gap:.45rem;padding:.3rem .42rem;background:#0d0b09;border:1px solid #1a1512;border-radius:3px;margin-bottom:.15rem;cursor:default;"
	if JS.t(revealed):
		row.style.cursor = "help"
		var tierColors = {"primary": "#4a8a4a", "secondary": "#4a6a9a", "legendary": "#9a6a20", "merged": "#00a09a"}
		var tier = JS.or_(spell.get("tier"), "secondary")
		var tierCol = JS.or_(JS.idx(tierColors, tier), "#555")
		var hasFormula = JS.idx(Incantations.SPELL_INCANTATION_CONFIG, spell.id)
		var infoHint = ("<span style=\"font-size:.44rem;color:#4a6a8a;margin-left:.3rem;\" title=\"Hover for formula\">ℹ</span>" if JS.t(hasFormula) else "")
		row.innerHTML = "\n      <span style=\"flex-shrink:0;\">" + SpellIcons.spellIconSVG(spell, 20) + "</span>\n      <div style=\"flex:1;min-width:0;\">\n        <div style=\"display:flex;align-items:center;gap:.3rem;flex-wrap:wrap;margin-bottom:.18rem;\">\n          <span style=\"font-size:.68rem;color:#c8a060;font-family:'Cinzel',serif;\">" + JS.s(spell.get("name")) + infoHint + "</span>\n          <span style=\"font-size:.44rem;color:" + tierCol + ";border:1px solid " + tierCol + ";border-radius:2px;padding:.04rem .22rem;text-transform:uppercase;letter-spacing:.05em;flex-shrink:0;\">" + tier + "</span>\n          <span style=\"font-size:.46rem;color:#444;margin-left:auto;flex-shrink:0;\">CD:" + JS.s(spell.get("baseCooldown")) + "</span>\n        </div>\n        <div style=\"font-size:.6rem;color:#5a5a5a;line-height:1.5;white-space:normal;\">" + (JS.or_(spell.get("desc"), "")) + "</div>\n      </div>"
		var _fn15 = func():
			var preview = _libCombatPreviewHtml(spell)
			var formula = _libSpellFormulaHtml(spell)
			return JS.s(preview) + "<div style=\"border-top:1px solid #2a2010;margin:.45rem 0 .3rem;\"></div>" + formula
		_libTip(row, _fn15)
	else:
		row.style.opacity = "0.4"
		row.innerHTML = "\n      <span style=\"font-size:.9rem;line-height:1.4;flex-shrink:0;filter:blur(3px);\">⬛</span>\n      <div>\n        <div style=\"font-size:.68rem;color:#252525;font-family:'Cinzel',serif;letter-spacing:.06em;\">?????? ??????</div>\n        <div style=\"font-size:.58rem;color:#1e1e1e;margin-top:.15rem;\">Undiscovered</div>\n      </div>"
	return row

# ─── GUIDE TABS ────────────────────────────────────────────────────────────
func _guideSection(cont = null, title = null, emoji = null):
	var hdr = document.createElement("div")
	hdr.style.cssText = "display:flex;align-items:center;gap:.4rem;font-size:.6rem;color:#6a4a20;letter-spacing:.08em;text-transform:uppercase;margin:.75rem 0 .3rem;padding-bottom:.2rem;border-bottom:1px solid #1a1512;font-family:'Cinzel',serif;"
	hdr.innerHTML = "<span>" + JS.s(emoji) + "</span><span>" + JS.s(title) + "</span>"
	cont.appendChild(hdr)

func _guideEntry(cont = null, label = null, body = null, labelColor = null):
	var d = document.createElement("div")
	d.style.cssText = "display:flex;flex-direction:column;gap:.15rem;padding:.28rem .42rem;background:#0d0b09;border:1px solid #1a1512;border-radius:3px;margin-bottom:.15rem;"
	var col = JS.or_(labelColor, "#c8a060")
	d.innerHTML = ("<div style=\"font-size:.63rem;color:" + col + ";font-family:'Cinzel',serif;\">" + JS.s(label) + "</div>") + ("<div style=\"font-size:.6rem;color:#5a5a5a;line-height:1.6;\">" + JS.s(body) + "</div>")
	cont.appendChild(d)

func _libRenderMechanics(cont = null):
	_guideSection(cont, "Core Stats", "📊")
	_guideEntry(cont, "ATK — Attack Power", "Your base damage output. Spells multiply ATK by their own scaling factor. Higher ATK = bigger hits. Talents, passives, and items can raise it.")
	_guideEntry(cont, "EFX — Elemental Force", "Amplifies all elemental effects you apply: burn damage per stack, frost stacks applied, root stacks, stone stacks, and momentum all scale with EFX. Formula: effect × (1 + EFX/50). Also boosts root bonus damage by +1 per 10 EFX.")
	_guideEntry(cont, "Defense", "Scales how much <b>Armor</b> you gain (+2 per Defense point) and scales healing received. Also directly reduces enemy ATK and EFX, weakening their attacks. <b>Foam reduces Defense</b> — at negative Defense, enemies deal bonus damage per hit.")
	_guideEntry(cont, "Armor", "Consumable damage shield. Absorbs incoming hits before HP, then depletes. Gained from the Armor action and spells. The amount gained scales with your Defense stat.")
	_guideEntry(cont, "Block", "Flat damage reduction per hit — reusable, never depleted. Does <b>not</b> apply to effect/DoT damage. Currently granted by the Earth Hard Shell passive (10 flat reduction per hit).")
	_guideSection(cont, "Status Effects", "💥")
	_guideEntry(cont, "🔥 Burn", "Stacks accumulate on a target. Each turn, deals <b>stacks × damage-per-stack</b> to HP, bypassing armor.<br>" + "Damage per stack = <span style=\"color:#a0c0ff;\">1.0 + yourEFX/100 + talentBonus</span> (or 1.5 with Roaring Heat) — uses your <b>current EFX</b> each tick, so EFX buffs gained mid-battle increase burn damage immediately.<br>" + "Burn does <b>not decay</b> — stacks persist until the enemy dies or is cleansed.", "#c86030")
	_guideEntry(cont, "❄️ Frost", "Each stack reduces enemy ATK and EFX by 1, and reduces armor absorption by 1 per hit. Stacks scale with your EFX when applied: <span style=\"color:#a0c0ff;\">stacks × (1 + EFX/50)</span>.<br>" + "Decays 1 stack per turn. At 10 stacks → triggers <b>Freeze</b>: enemy skips a turn. An Ice hit on a frozen target deals 1.5× damage and consumes 10 stacks. Freeze also wears off naturally as frost decays to 0.", "#60a0cc")
	_guideEntry(cont, "⚡ Shock", "Reduces the shocked target's outgoing damage by <b>5% per stack</b> (max 75%). Applied by Lightning spells and abilities. Passives like Conduction add +1 shock per hit.", "#c0c020")
	_guideEntry(cont, "⚡ Surge (Lightning)", "A charged detonation. Loading spells fill the Surge meter; when it reaches the <b>threshold (default 60)</b>, Surge explodes for its stored damage.<br>" + "Only one Surge active per target at a time. Hair Trigger lowers threshold to 50. Static Build adds +20 stored damage per turn it doesn't trigger.", "#c0c020")
	_guideEntry(cont, "🌿 Root", "Each root stack adds <b>+5 bonus damage taken</b> per incoming attack (+1 per 10 EFX of the attacker).<br>" + "Rooted targets cannot dodge. Thorned Strikes passive doubles this bonus. Root stacks accumulate — they don't decay on their own.<br>" + "<b>Root also blocks incoming effects</b> (Burn, Stun, etc.) applied to the rooted target, consuming 1 stack per effect blocked. With Overgrowth passive, blocked stacks convert to Overgrowth instead of being lost.", "#3a8a3a")
	_guideEntry(cont, "🌿 Overgrowth", "Permanent root — same <b>+5 bonus damage taken per stack</b> as regular Root, but these stacks never decay and are never consumed.<br>" + "Applied by the Overgrowth passive, which converts Root stacks into Overgrowth stacks whenever Root would block an effect.", "#50a050")
	_guideEntry(cont, "🪨 Stone", "Grants <b>+3 ATK and +2 Armor per stack</b>. Both bonuses are doubled during Stone Stance. Stacks scale with EFX when applied: <span style=\"color:#a0c0ff;\">stacks × (1 + EFX/50)</span>. Decay slowly each turn.", "#8a8a6a")
	_guideEntry(cont, "🫧 Foam", "Reduces <b>Defense by 1.5 per stack</b>. Since Defense scales Armor gains and attenuates enemy stats, heavy Foam prevents effective blocking. At negative Defense, each enemy hit deals bonus damage equal to the deficit. Stacks scale with applier's EFX.", "#4080a0")
	_guideEntry(cont, "💨 Momentum", "Each stack grants <b>+0.8 ATK</b> and <b>+2% dodge chance</b> (cap 80%). Stacks scale with EFX: <span style=\"color:#a0c0ff;\">stacks × (1 + EFX/50)</span>. Gained on every hit landed.<br>" + "On dodge: lose <b>25% of stacks</b> (10% with Slipstream passive). Become Wind ability prevents this decay for one dodge.", "#80a0c0")
	_guideSection(cont, "Dodge & Phase", "💨")
	_guideEntry(cont, "Dodge", "Some elements and passives grant a chance to fully evade incoming hits. A dodged attack deals no damage and applies no effects.<br>" + "<b>Air:</b> +2% dodge per Momentum stack (cap 80%). Each dodge costs 25% of Momentum (10% with Slipstream).<br>" + "<b>Plasma:</b> Ghost Step talent grants a flat dodge chance (up to 50%).<br>" + "Dodge does not protect against DoT/effect damage (burn ticks, frost ticks, etc.).")
	_guideEntry(cont, "Phase", "Full phase grants <b>100% dodge</b> for N turns. Every incoming hit is evaded — no damage, no effects. Phase is consumed one turn at a time.")
	_guideSection(cont, "Nature Seeds", "🌱")
	_guideEntry(cont, "Seeds — Germination System", "Seeds are planted mid-combat and bloom after a 5-turn timer. Planting the same type again adds stacks — all bloom on the original timer (timer does not reset).<br>" + "<b>Damage Seed:</b> deals 30 + EFX/2 direct damage per stack when it blooms.<br>" + "<b>Root Seed:</b> applies 3 root stacks per stack when it blooms.<br>" + "<b>Healing Seed:</b> planted on <i>yourself</i> — blooms to restore <b>50 + DEF HP per stack</b> (scales with incantation level).<br>" + "<b>Silence Seed:</b> planted on the enemy — blooms to <b>silence</b> them, disabling their active spellbook for 1 turn (scales with incantation level). Each cast is independent and does not merge.<br>" + "The Perennial passive replants any bloomed seed at a 4-turn timer. Deep Roots passive reduces seed timers by 1 every 3rd root applied.", "#50a050")
	_guideEntry(cont, "🤫 Silence", "A silenced enemy cannot use abilities for the duration. Basic attacks still fire. Silence is applied by Silence Seed on bloom and decays 1 turn per round.", "#a050a0")
	_guideSection(cont, "Fire Melt", "🔩")
	_guideEntry(cont, "Melt — Armor Destruction", "Each melt point strips <b>3 Armor</b> from the target. To fully break all Armor costs <b>ceil(Armor ÷ 3)</b> melt points — any melt left over converts to <b>direct HP damage at 1:1</b>. If you can't break all the Armor in one hit, no HP damage is dealt — only Armor is chipped.<br>" + "<b>Forge Master:</b> +30% melt points. <b>Deep Heat:</b> +EFX/5 bonus melt points; also converts 50% of stripped Armor into bonus melt. <b>Meltdown</b> legendary: when Armor fully breaks, gain bonus melt equal to its peak value.", "#c06030")
	_guideSection(cont, "Incantations", "✦")
	_guideEntry(cont, "Spell Upgrades", "Incantations upgrade individual spells. Each level boosts one stat (e.g. burn stacks, damage, root chance) by a base amount that decays slightly with each additional level.<br>" + "Formula: <span style=\"color:#a0c0ff;\">+baseScale × decay^(level−2)</span> per upgrade beyond lv1. Hover any spell in the element tabs to see its scaling.")

func _libRenderCombat(cont = null):
	_guideSection(cont, "Run Structure", "🗺️")
	_guideEntry(cont, "Zones & Gyms", "A run progresses through zones, each ending with a <b>Gym Boss</b>. Within each zone you fight a series of regular battles before reaching the gym.<br>" + "Enemies get progressively harder each zone: HP scales by ×1.28 per gym, damage by ×1.22, and elemental power by +4.4 per gym.")
	_guideEntry(cont, "Starting a Run", "At the start of each run you pick your <b>element</b>. Your first reward after battle 1 is always a <b>primary spell</b> — your starting move. You begin with only that one spell.", "#c8a060")
	_guideEntry(cont, "Choosing a Path", "After each battle you see two encounter options. Each has a visible <b>reward type</b> attached. Pick the path whose reward you want more.", "#c8a060")
	_guideSection(cont, "Rewards", "✦")
	_guideEntry(cont, "Reward Types", "<b style=\"color:#a080ff;\">Spell</b> — choose 1 of 3 spells to add to your spellbook.<br>" + "<b style=\"color:#a080ff;\">Primary Spell</b> — battle 1 of each run, picks a primary-tier spell.<br>" + "<b style=\"color:#c8a060;\">Incantation</b> — upgrade one spell you already own to the next level.<br>" + "<b style=\"color:#888;\">Minor</b> — small stat boost (gold, HP heal, ATK, etc.).<br>" + "<b style=\"color:#c8a060;\">Major</b> — significant boost (large heal, passive stat, etc.).<br>" + "Reward chances per non-gym battle: 20% Spell · 30% Incantation · 30% Minor · 20% Major.")
	_guideEntry(cont, "Passive Rewards", "Passives are not earned from regular battles — they come from <b>Gym clears</b> and <b>Rival defeats</b>. You choose from 3 options. Legendary passives can appear with lower probability.")
	_guideEntry(cont, "Gym Clear Rewards", "Defeating the Gym Boss gives you: a <b>full HP heal</b>, a passive reward, and bonus gold. The gym's element determines what the boss does in combat.", "#c8a060")
	_guideSection(cont, "Combat Turn Order", "⚔️")
	_guideEntry(cont, "Player Turn", "You have a set number of actions per turn (usually 1–2 depending on spells). Play spells from your spellbook in any order. Cooldowns track how many turns until a spell is usable again. When you end your turn, enemy turn begins.")
	_guideEntry(cont, "Enemy Turn", "The enemy acts: attacks, applies zone effects, uses abilities. Basic attacks hit for scaled damage. Some enemies have multiple hits or special abilities that trigger passively.<br>" + "Zone effects apply extra status on every enemy attack (e.g. Fire zones apply +2 Burn to the player per hit).")
	_guideEntry(cont, "End of Turn", "After each side's actions: burn ticks deal damage, frost decays, stone decays, surge meters may trigger. Effects that say \"per turn\" resolve here.")
	_guideSection(cont, "HP & Healing", "❤️")
	_guideEntry(cont, "HP Persists Between Battles", "You do <b>not</b> fully heal between regular fights. Manage your HP carefully. Some minor rewards offer small heals, and some spells/passives provide lifesteal or shields.", "#cc4444")
	_guideEntry(cont, "Gym Clear: Full Heal", "Clearing the Gym Boss <b>fully restores your HP</b>. Plan your pathing to reach the gym before you run out.", "#4aaa6a")
	_guideSection(cont, "Zone Effects", "🌍")
	var _zoneHazardLines = [
		["#c86030", "🔥 Fire", "+2 Burn applied to player per hit (scales with battle number).", "Fire"],
		["#c0c020", "⚡ Lightning", "+1 Shock applied to player per hit.", "Lightning"],
		["#3a8a3a", "🌿 Nature", "50% chance to apply Root to player per hit.", "Nature"],
		["#60a0cc", "❄️ Ice", "+2 Frost applied to player per hit.", "Ice"],
		["#4080a0", "💧 Water", "applies Foam to player.", "Water"],
		["#8B6914", "🪨 Earth", "attacker gains +1 Stone per hit.", "Earth"],
		["#DA70D6", "🔮 Plasma", "+25% healing for this zone.", "Plasma"],
		["#B0E0E6", "🌀 Air", "20% chance to stun player for 1 turn per hit.", "Air"],
	]
	var _fn16 = func(_p0 = null):
		var el = JS.idx(_p0, 3)
		return JS.includes(Constants.RELEASED_ELEMENTS, el)
	var _visibleHazards = (_zoneHazardLines if JS.t(Constants.sandboxMode) else JS.arr(_zoneHazardLines).filter(_fn16))
	var _fn17 = func(_p0 = null):
		var color = JS.idx(_p0, 0)
		var name_ = JS.idx(_p0, 1)
		var desc = JS.idx(_p0, 2)
		return "<span style=\"color:" + JS.s(color) + ";\">" + JS.s(name_) + "</span> — " + JS.s(desc)
	_guideEntry(cont, "Per-Element Zone Hazards", "The active zone element adds a passive effect on every enemy basic attack:<br>" + JS.join(JS.arr(_visibleHazards).map(_fn17), "<br>") + "<br>Playing the matching element doesn't remove these — they always apply.")
	_guideSection(cont, "Talent Levels", "⭐")
	_guideEntry(cont, "Novice → Master", "Talent level is set before a run and determines your starting power. Higher talent levels unlock stronger versions of incantation scaling, passive bonuses, and spell base values.<br>" + "Talents are bought with <b>Phos</b>, earned by surviving battles and clearing gyms across all your runs. You keep Phos permanently between runs.", "#c8a060")
	_guideSection(cont, "Spellbooks", "📚")
	_guideEntry(cont, "Multiple Books", "Your spells are organized into spellbooks. In combat you play from the active book. You can edit books from the map before a run starts — assign spells to whichever book fits your strategy.")

func _libPassiveRow(passive = null, revealed = null):
	var row = document.createElement("div")
	row.style.cssText = "display:flex;align-items:flex-start;gap:.45rem;padding:.3rem .42rem;background:#0d0b09;border:1px solid #1a1512;border-radius:3px;margin-bottom:.15rem;cursor:default;"
	if JS.t(revealed):
		var legBadge = ("<span style=\"font-size:.44rem;color:#c8a060;border:1px solid #c8a060;border-radius:2px;padding:.04rem .22rem;text-transform:uppercase;letter-spacing:.05em;flex-shrink:0;\">Legendary</span>" if JS.t(passive.get("legendary")) else "")
		var infoHint = ("<span style=\"font-size:.44rem;color:#4a6a8a;margin-left:.3rem;\">ℹ</span>" if JS.t(passive.get("detail")) else "")
		row.innerHTML = "\n      <span style=\"flex-shrink:0;display:flex;align-items:center;\">" + PassiveIcons.passiveIconSVG(passive, 20) + "</span>\n      <div style=\"flex:1;min-width:0;\">\n        <div style=\"display:flex;align-items:center;gap:.3rem;flex-wrap:wrap;margin-bottom:.18rem;\">\n          <span style=\"font-size:.68rem;color:#f0f0f8;font-family:'Cinzel',serif;\">" + JS.s(passive.title) + infoHint + "</span>\n          " + legBadge + "\n        </div>\n        <div style=\"font-size:.6rem;color:#5a5a5a;line-height:1.5;white-space:normal;\">" + (JS.or_(passive.get("desc"), "")) + "</div>\n      </div>"
		_libTip(row, func(): return _libPassiveFormulaHtml(passive))
	else:
		row.style.opacity = "0.4"
		row.innerHTML = "\n      <span style=\"font-size:.9rem;line-height:1.4;flex-shrink:0;filter:blur(3px);\">⬛</span>\n      <div>\n        <div style=\"font-size:.68rem;color:#252525;font-family:'Cinzel',serif;letter-spacing:.06em;\">?????? ??????</div>\n        <div style=\"font-size:.58rem;color:#1e1e1e;margin-top:.15rem;\">Undiscovered</div>\n      </div>"
	return row
