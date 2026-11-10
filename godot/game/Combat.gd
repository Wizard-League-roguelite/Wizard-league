# Combat — generated from js/logic/combat.js by tools/js2gd.js
extends Node


func _boot():
	pass

# ===== combat.js =====
# ─── COMBAT LOOP ──────────────────────────────────────────────────────────────
# startRound, queue system, endBattle, summon attacks.
# Calls into hit.js for damage resolution.
# ===============================
# QUEUE-BASED SIMULTANEOUS SYSTEM
# ===============================
# Player queues up to N actions, then presses End Turn.
# Enemy simultaneously queues its actions.
# Both sides resolve action-by-action with a short delay between each pair.
# Tick player CDs once per round (called at end of round, not start).
func _tickPlayerCDs():
	if State.combat.basicCD > 0:
		State.combat.basicCD -= 1
	# Tick all books' spells so CDs advance regardless of which book is active
	for book in JS.iter(JS.or_(State.player.get("spellbooks"), [])):
		for s in JS.iter(book.spells):
			if s.currentCD > 0:
				s.currentCD -= 1

# Apply catalogue book effects after a spell action resolves
func _applyBookSpellEffect(action = null):
	if ((not JS.t(action) or not JS.t(action.get("isSpellAction"))) or not JS.t(action.get("bookCatalogueId"))):
		return
	var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, action.bookCatalogueId)
	if not JS.t(cat):
		return
	var book = JS.find(JS.or_(State.player.get("spellbooks"), []), func(b = null): return JS.eq(b.catalogueId, action.bookCatalogueId))
	var lvl = (JS.or_(book.get("upgradeLevel"), 0) if JS.t(book) else 0)
	var spell = action.spellObj
	if JS.t(State.combat.get("over")):
		return
	# onSpellExecute hook
	if (JS.t(cat.get("onSpellExecute")) and JS.t(spell)):
		JS.callm(cat, "onSpellExecute", [spell, lvl])
	if JS.t(State.combat.get("over")):
		return
	# Echo Grimoire: first non-builtin spell each turn gets bonus damage
	var aura = (JS.callm(cat, "aura", [lvl]) if JS.t(cat.get("aura")) else {})
	if (((JS.t(aura.get("echoBonus")) and JS.t(State.combat.get("_echoReady"))) and JS.t(spell)) and not JS.t(spell.get("isBuiltin"))):
		State.combat._echoReady = false
		var echoDmg = JS.round((JS.or_(State.player.get("attackPower"), 0)) * aura.echoBonus)
		if (echoDmg > 0 and not JS.t(State.combat.get("over"))):
			var anyEnemy = (JS.idx(Helpers.aliveEnemies(), 0) if JS.t(Helpers.aliveEnemies) else null)
			if JS.t(anyEnemy):
				State.setActiveEnemy(JS.indexOf(State.combat.enemies, anyEnemy))
				Hit.applyDirectDamage.call("player", "enemy", echoDmg, "🌀 Echo")
				UI.log_("🌀 Echo Grimoire: +" + JS.s(echoDmg) + " echo damage!", "player")

func startRound():
	if JS.t(State.combat.get("over")):
		return
	# Reset per-turn flags
	State.combat.meltDoubleTurn = false
	State.combat._seedSurgePending = false
	# Seed Surge expires if unused
	State.combat._surgeTriggeredThisTurn = false
	State.combat._residualCurrentPending = false
	State.combat._residualCurrentValue = 0
	# ── Apply pending 1-turn power bonuses (Overcharge/Feedback) ──
	# Clear last round's bonus first, then promote pending to this-turn bonus.
	State.status.player.nextTurnPowerBonus = 0
	if State.status.player.overchargePowerPending > 0:
		State.status.player.nextTurnPowerBonus = State.status.player.overchargePowerPending
		UI.log_("⚡ +" + JS.s(State.status.player.overchargePowerPending) + " Power this turn (Overcharge/Feedback)", "status")
		State.status.player.overchargePowerPending = 0
	# Note: player.power is NOT mutated — this bonus expires at next round start
	# ── Charge Shot auto-fire ──
	if JS.t(State.status.player.get("chargeShotCharging")):
		State.status.player.chargeShotCharging = false
		var csDmg = (50 + Helpers.attackPowerFor("player", "enemy")) + (JS.or_(State.status.player.get("chargeShotDmgBonus"), 0))
		State.status.player.chargeShotDmgBonus = 0
		for e in JS.iter(Helpers.aliveEnemies()):
			State.setActiveEnemy(JS.indexOf(State.combat.enemies, e))
			Hit.applyDirectDamage.call("player", "enemy", csDmg, "🎯⚡ Charge Shot")
		UI.log_("🎯⚡ Charge Shot FIRES! " + JS.s(csDmg) + " dmg to all", "player")
		if JS.t(State.combat.get("over")):
			return
	# ── Seed System: Verdant Patience check, then tick ──
	Seeds._checkVerdantPatience()
	if not JS.t(State.combat.get("over")):
		Seeds._tickSeeds()
	if JS.t(State.combat.get("over")):
		return
	# ── Surge System: Static Build + Conductivity tick ──
	Surge._tickSurgeBuilds()
	if JS.t(State.combat.get("over")):
		return
	# ── Duo passive ticks (Scorched Earth etc.) ──
	Duos._tickDuoEffects()
	if JS.t(State.combat.get("over")):
		return
	# ── Per-enemy round ticks ──
	var _arr1 = JS.iter(State.combat.enemies)
	for i in range(len(_arr1)):
		var e = _arr1[i]
		if not JS.t(e.get("alive")):
			continue
		State.setActiveEnemy(i)
		if e.basicCD > 0:
			e.basicCD -= 1
		# Tick ability cooldowns
		if JS.t(e.get("abilities")):
			for a in JS.iter(e.abilities):
				if a.cd > 0:
					a.cd -= 1
		# Tick static field
		if e._staticFieldTurns > 0:
			e._staticFieldTurns -= 1
			if (e._staticFieldTurns <= 0 and JS.t(e.get("_staticPowerBonus"))):
				e.statPow = max(0, (JS.or_(e.get("statPow"), 0)) - e._staticPowerBonus)
				e._staticPowerBonus = 0
				UI.log_("🌩️ " + JS.s(e.name) + "'s Static Field fades.", "status")
		# Shock: decay 25% each round
		e.status.shockStacks = floori((JS.or_(e.status.get("shockStacks"), 0)) * 0.75)
		# Foam expires
		if e.status.foamStacks > 0:
			e.status.foamStacks -= 1
		# Gale Bind (Air+Nature duo): temporary root expires before normal decay
		if e.status._galeBind > 0:
			e.status.rootStacks = max(0, e.status.rootStacks - e.status._galeBind)
			e.status._galeBind = 0
		# Root decay
		if e.status.rootStacks > 0:
			e.status.rootStacks -= 1
			Seeds._rootedBloomDecay("enemy")
		# Stone stance reset + decay (25%, skip if Living Mountain enemy)
		e.status.stoneStanceThisTurn = false
		if e.status.stoneStacks > 0:
			var decay = max(1, floori(e.status.stoneStacks * 0.25))
			e.status.stoneStacks = max(0, e.status.stoneStacks - decay)
		# Wildfire: 33% chance to double enemy burn
		if ((Main.hasPassive("fire_wildfire") and e.status.burnStacks > 0) and randf() < 0.33):
			e.status.burnStacks *= 2
			UI.log_("🌪️ Wildfire! " + JS.s(e.name) + " burn ×2 (×" + JS.s(e.status.burnStacks) + ")", "status")
		# Burn tick (1 or 1.5 per stack; Grease Fire doubles once)
		if e.status.burnStacks > 0:
			var grease = State.status.player.greasefirePending
			var mult = (2 if JS.t(grease) else 1)
			if JS.t(grease):
				State.status.player.greasefirePending = false
				UI.log_("🛢️ Grease Fire: burn tick doubled!", "status")
			var bdmg = ceili((e.status.burnStacks * Helpers.burnDmgPerStack("player", Helpers.effectPowerFor("player"))) * mult)
			if bdmg > 0:
				Hit.applyEffectDamage("player", "enemy", bdmg, "🔥 Burn")
			if JS.t(State.combat.get("over")):
				continue
		# Frost tick (1 or 3 per stack; skip while frozen)
		if (e.status.frostStacks > 0 and not JS.t(e.status.get("frozen"))):
			var frostPer = (3 if Main.hasPassive("ice_permafrost_core") else 1)
			var fdmg = floori(e.status.frostStacks) * frostPer
			if fdmg > 0:
				Hit.applyEffectDamage("player", "enemy", fdmg, "❄️ Frost (×" + JS.toFixed(e.status.frostStacks, 1) + ")")
			if JS.t(State.combat.get("over")):
				continue
		# Frost decay: 1 stack per round regardless of frozen state
		if e.status.frostStacks > 0:
			e.status.frostStacks = max(0, e.status.frostStacks - 1)
			if (JS.t(e.status.get("frozen")) and e.status.frostStacks <= 0):
				e.status.frozen = false
				UI.log_("🧊 " + JS.s(e.name) + " thaws out.", "status")
		# Frozen Ground: apply 2 Frost to all enemies for N rounds
		if State.status.player.frozenGroundTurns > 0:
			Helpers.applyFrost("player", "enemy", 2)
	if JS.t(State.combat.get("over")):
		return
	# Frozen Ground countdown
	if State.status.player.frozenGroundTurns > 0:
		State.status.player.frozenGroundTurns -= 1
		if JS.eq(State.status.player.get("frozenGroundTurns"), 0):
			UI.log_("❄️ Frozen Ground fades.", "status")
	# Spreading Vines: 1 root to all enemies + 1 armor for N rounds
	if State.status.player.spreadingVinesTurns > 0:
		for e in JS.iter(Helpers.aliveEnemies()):
			State.setActiveEnemy(JS.indexOf(State.combat.enemies, e))
			Helpers.applyRoot("player", "enemy", 1)
		Helpers.gainBlock("player", 1)
		State.status.player.spreadingVinesTurns -= 1
		if JS.eq(State.status.player.get("spreadingVinesTurns"), 0):
			UI.log_("🌿 Spreading Vines fades.", "status")
	# ── Player per-round ticks ──
	# Shock: decay 25% each round
	State.status.player.shockStacks = floori((JS.or_(State.status.player.get("shockStacks"), 0)) * 0.75)
	if State.status.player.foamStacks > 0:
		State.status.player.foamStacks -= 1
	if State.status.player.rootStacks > 0:
		State.status.player.rootStacks -= 1
		Seeds._rootedBloomDecay("player")
	State.status.player.stoneStanceThisTurn = false
	if (State.status.player.stoneStacks > 0 and not Main.hasPassive("earth_living_mountain")):
		var decay = max(1, floori(State.status.player.stoneStacks * 0.25))
		State.status.player.stoneStacks = max(0, State.status.player.stoneStacks - decay)
	if State.status.player.debuffImmune > 0:
		State.status.player.debuffImmune -= 1
	if State.status.player.rageBoostTurns > 0:
		State.status.player.rageBoostTurns -= 1
		if JS.eq(State.status.player.get("rageBoostTurns"), 0):
			State.status.player.rageBoostPow = 0
	# Fortify: convert pending armor into Stone stacks (1 stack per 5 armor)
	if State.status.player.fortifyPending > 0:
		var armorLeft = min(State.status.player.fortifyPending, JS.or_(State.status.player.get("block"), 0))
		var stacks = max(1, floori(armorLeft / 5.0))
		State.status.player.block = max(0, (JS.or_(State.status.player.get("block"), 0)) - armorLeft)
		State.status.player.fortifyPending = 0
		Helpers.addStoneStacks("player", stacks)
		UI.log_("🏰 Fortify breaks — " + JS.s(armorLeft) + " Armor → " + JS.s(stacks) + " Stone stacks", "status")
	# Player burn tick
	if State.status.player.burnStacks > 0:
		var anyEnemy = JS.find(State.combat.enemies, func(e = null): return JS.t(e.get("alive")))
		if JS.t(anyEnemy):
			State.setActiveEnemy(JS.indexOf(State.combat.enemies, anyEnemy))
		var bdmg = ceili(State.status.player.burnStacks * Helpers.burnDmgPerStack("enemy", JS.or_(State.status.player.get("burnSourcePower"), 0)))
		if bdmg > 0:
			Hit.applyEffectDamage("enemy", "player", bdmg, "🔥 Burn")
			if JS.t(State.combat.get("over")):
				return
	# Player frost tick
	if (State.status.player.frostStacks > 0 and not JS.t(State.status.player.get("frozen"))):
		var frostPer = (3 if Main.enemyHasPassive("ice_permafrost_core") else 1)
		var fdmg = floori(State.status.player.frostStacks) * frostPer
		if fdmg > 0:
			Hit.applyEffectDamage("enemy", "player", fdmg, "❄️ Frost (×" + JS.toFixed(State.status.player.frostStacks, 1) + ")")
			if JS.t(State.combat.get("over")):
				return
	# Frost decay: 1 stack per round regardless of frozen state
	if State.status.player.frostStacks > 0:
		State.status.player.frostStacks = max(0, State.status.player.frostStacks - 1)
		if (JS.t(State.status.player.get("frozen")) and State.status.player.frostStacks <= 0):
			State.status.player.frozen = false
			UI.log_("🧊 You thaw out.", "status")
	# Restore target reference
	if (not JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)) or not JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx).get("alive"))):
		State.combat.targetIdx = Helpers.firstAliveIdx()
	State.setActiveEnemy(State.combat.targetIdx)
	# ── Zone passive tick ──
	applyZoneTick()
	if JS.t(State.combat.get("over")):
		return
	# Summon auto-attacks
	resolveSummonAttacks()
	if JS.t(State.combat.get("over")):
		return
	# Player stunned: skip planning, all enemies act
	if State.status.player.stunned > 0:
		var delay = [null]
		State.status.player.stunned -= 1
		UI.log_(JS.s(State.playerEmoji) + " You are stunned — skip your turn!", "status")
		UI.renderStatusTags()
		UI.setPlayerTurnUI(false)
		_tickPlayerCDs()
		# stun = lost turn, still tick CDs
		delay[0] = 400
		var _arr2 = JS.iter(State.combat.enemies)
		for i in range(len(_arr2)):
			var e = _arr2[i]
			if not JS.t(e.get("alive")):
				continue
			var _fn3 = func():
				if JS.t(State.combat.get("over")):
					return
				State.setActiveEnemy(i)
				executeOneEnemyAction(i)
			JS.setTimeout(_fn3, delay[0])
			delay[0] += 300
		JS.setTimeout(startRound, delay[0] + 200)
		return
	# ── Air: Wind Wall delayed damage fires at round start ──
	if ((State.playerElement == "Air" and (JS.or_(State.status.player.get("windWallPending"), 0)) > 0) and not JS.t(State.combat.get("over"))):
		var wpDmg = State.status.player.windWallPending
		State.status.player.windWallPending = 0
		var anyEnemy = JS.find(State.combat.enemies, func(e = null): return JS.t(e.get("alive")))
		if JS.t(anyEnemy):
			State.setActiveEnemy(JS.indexOf(State.combat.enemies, anyEnemy))
		Hit.applyEffectDamage("enemy", "player", wpDmg, "🌬️ Wind Wall — delayed damage arrives")
		if JS.t(State.combat.get("over")):
			return
		State.setActiveEnemy(State.combat.targetIdx)
	State.combat.turnInBattle += 1
	State.combat.actionQueue = []
	State.combat._aoPriorityShift = 0
	State.combat.actionsLeft = Helpers.actionsPerTurnFor("player") + Artifacts.artifactExtraActions()
	# ── Air: Slipstream talent — bonus action every N turns ──
	if ((State.playerElement == "Air" and JS.t(State.player.get("_slipstreamInterval"))) and (JS.mod(State.combat.turnInBattle, State.player._slipstreamInterval)) == 0):
		State.combat.actionsLeft += 1
		UI.log_("💨 Slipstream: +1 bonus action! (turn " + JS.s(State.combat.turnInBattle) + ")", "status")
	# ── Air: Sleeper Gust bonus actions ──
	if (State.playerElement == "Air" and (JS.or_(State.status.player.get("nextTurnBonusActions"), 0)) > 0):
		var bonus = State.status.player.nextTurnBonusActions
		State.combat.actionsLeft += bonus
		UI.log_("💨 +" + JS.s(bonus) + " bonus action" + ("s" if bonus > 1 else "") + " from Sleeper Gust!", "status")
		State.status.player.nextTurnBonusActions = 0
	# ── Duo: Thermal Draft (Air+Fire) — Momentum from total enemy Burn ──
	if (Main.hasPassive("duo_thermal_draft") and State.playerElement == "Air"):
		var totalBurn = JS.reduce(State.combat.enemies, func(s = null, e = null): return s + (JS.or_(e.status.get("burnStacks"), 0) if JS.t(e.get("alive")) else 0), 0)
		var momGain = JS.round(totalBurn * 0.15)
		if momGain > 0:
			Helpers.addMomentumStacks(momGain)
			UI.log_("🔥💨 Thermal Draft: +" + JS.s(momGain) + " Momentum (" + JS.s(totalBurn) + " Burn).", "status")
	# ── Air: Tailwind Carry bonus action ──
	if (State.playerElement == "Air" and JS.t(State.combat.get("_tailwindBonusNextTurn"))):
		State.combat._tailwindBonusNextTurn = false
		State.combat.actionsLeft += 1
		State.combat._tailwindBonusActionPriority = JS.or_(State.combat.get("_tailwindBonusPriority"), 1)
		var _tcPri = State.combat._tailwindBonusActionPriority
		UI.log_("🌬️ Tailwind Carry: +1 action (first queued spell gets priority " + ("+" if _tcPri > 0 else "") + JS.s(_tcPri) + ").", "status")
	if (JS.or_(State.status.player.get("nextTurnActionPenalty"), 0)) > 0:
		var penalty = State.status.player.nextTurnActionPenalty
		State.combat.actionsLeft = max(0, State.combat.actionsLeft - penalty)
		UI.log_("🧊 Freeze! −" + JS.s(penalty) + " action" + ("s" if penalty > 1 else "") + " this turn.", "status")
		State.status.player.nextTurnActionPenalty = 0
	State.combat.plasmaChargeReserved = 0
	# reset reserved charge each new round
	# ── Plasma: round-start charge management ──
	if State.playerElement == "Plasma":
		# Stall regain
		if JS.t(State.status.player.get("stallActive")):
			State.status.player.stallActive = false
			var regain = JS.or_(State.status.player.get("stallCharge"), 0)
			State.status.player.stallCharge = 0
			State.status.player.plasmaCharge = (JS.or_(State.status.player.get("plasmaCharge"), 0)) + regain
			UI.log_("🫧 Stall ends — regained " + JS.s(regain) + " Charge (" + JS.s(State.status.player.plasmaCharge) + " total)", "status")
		# Borrowed Power penalty
		if State.status.player.borrowedCharge > 0:
			var penalty = State.status.player.borrowedCharge * 50
			State.status.player.borrowedCharge = 0
			Hit.applyEffectDamage("enemy", "player", penalty, "⏳ Borrowed Power debt")
			if JS.t(State.combat.get("over")):
				return
		# Stabilized Core: +3 charge per turn start — only if Plasma book is active
		if Main.hasPassive("plasma_stabilized_core"):
			var _pIdx = State.plasmaBookIdx()
			if (_pIdx >= 0 and State.player.activeBookIdx == _pIdx):
				State.status.player.plasmaCharge = (JS.or_(State.status.player.get("plasmaCharge"), 0)) + 3
				UI.log_("🔋 Stabilized Core: +3 Charge → " + JS.s(State.status.player.plasmaCharge), "status")
		# Overcharge check: >= 20 at turn start
		State.combat.plasmaOvercharged = (JS.or_(State.status.player.get("plasmaCharge"), 0)) >= 20
		if JS.t(State.combat.get("plasmaOvercharged")):
			UI.log_("✦ OVERCHARGE! Plasma abilities 1.5× this turn.", "status")
		# (Plasma Shield reduction persists the whole battle — only reset in loadBattle)
		# Energy Feedback: power bonus from current charge
		if Main.hasPassive("plasma_energy_feedback"):
			# This is applied dynamically in attackPowerFor — just log it
			UI.log_("⚡ Energy Feedback: +" + JS.s(State.status.player.plasmaCharge) + " Power from Charge", "status")
		Spells.updateChargeUI()
	# ── Book onTurnStart hook (e.g. Verdant Codex regen) ──
	var _abTurn = State.activeBook()
	if (JS.t(_abTurn) and JS.t(_abTurn.get("catalogueId"))):
		var _abCat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, _abTurn.catalogueId)
		if (JS.t(_abCat) and JS.t(_abCat.get("onTurnStart"))):
			JS.callm(_abCat, "onTurnStart", [JS.or_(_abTurn.get("upgradeLevel"), 0)])
			if JS.t(State.combat.get("over")):
				return
	State.combat._echoReady = true
	# reset echo for this turn
	# Pre-build enemy queues now so intents are visible during player planning
	var _fn4 = func(e = null, i = null):
		if not JS.t(e.get("alive")):
			return []
		var actions = Helpers.actionsPerTurnFor("enemy") + (JS.or_(e.get("bonusActions"), 0))
		var penalty = JS.or_(e.status.get("nextTurnActionPenalty"), 0)
		if penalty > 0:
			actions = max(0, actions - penalty)
			e.status.nextTurnActionPenalty = 0
			UI.log_("🧊 " + JS.s(e.name) + " frozen! −" + JS.s(penalty) + " action" + ("s" if penalty > 1 else "") + " this turn.", "status")
		return buildEnemyQueueFor(i, actions)
	State.combat.prebuiltEnemyQueues = JS.map(State.combat.enemies, _fn4)
	UI.renderEnemyCards()
	renderQueue()
	updateActionUI()
	UI.setPlayerTurnUI(true)

# ── Air: extra priority added to each queued action ─────────────────────────
func _airQueuePriorityBonus():
	if State.playerElement != "Air":
		return 0
	var bonus = 0
	# Prevailing Wind: permanent +1 or -1 for all actions
	if Main.hasPassive("air_prevailing_wind"):
		bonus += JS.or_(State.player.get("_prevailingWindPriority"), 0)
	# Tailwind Carry: first queued action next turn gets the pre-loaded priority
	if State.combat.get("_tailwindBonusActionPriority") != null:
		bonus += State.combat._tailwindBonusActionPriority
		State.combat._tailwindBonusActionPriority = null
	# Windfall Seed (Air+Nature duo): +1 priority while any Momentum Seed is germinating
	if JS.some(JS.or_(State.status.player.get("seeds"), []), func(s = null): return s.get("type") == "momentum"):
		bonus += 1
	return bonus

# ===============================
# QUEUE-BASED SIMULTANEOUS SYSTEM
# ===============================
func queueAction(label = null, fn = null, opts = null):
	if (not JS.t(State.combat.get("playerTurn")) or JS.t(State.combat.get("over"))):
		return
	var isFree = (opts.get("isFree") if JS.t(opts) else opts)
	if not JS.t(isFree):
		var nonFreeCount = len(JS.arr(JS.or_(State.combat.get("actionQueue"), [])).filter(func(a = null): return not JS.t(a.get("isFree"))))
		if nonFreeCount >= State.combat.actionsLeft:
			return
	# Immediate effect at queue time (e.g. Storm Rush +3 actions)
	if (JS.t(opts) and JS.t(opts.get("onQueue"))):
		JS.callm(opts, "onQueue", [])
	var snapTarget = State.combat.targetIdx
	State.combat.actionQueue.append({
		"label": label,
		"fn": fn,
		"targetIdx": snapTarget,
		"isPlasma": false,
		"isFree": (not (not JS.t(isFree))),
		"stormRushAction": (not (not (JS.t(opts) and JS.t(opts.get("stormRushAction"))))),
		"stormRushDependent": (not (not (JS.t(opts) and JS.t(opts.get("stormRushDependent"))))),
		"undoOnQueue": JS.or_((opts.get("undoOnQueue") if JS.t(opts) else opts), null),
		"isSpellAction": (not (not (JS.t(opts) and JS.t(opts.get("isSpellAction"))))),
		"bookCatalogueId": JS.or_((opts.get("bookCatalogueId") if JS.t(opts) else opts), null),
		"spellObj": JS.or_((opts.get("spellObj") if JS.t(opts) else opts), null),
		"hintFn": JS.or_((opts.get("hintFn") if JS.t(opts) else opts), null),
		"priority": ((JS.or_((opts.get("priority") if JS.t(opts) else opts), 0)) + (JS.or_(State.combat.get("_aoPriorityShift"), 0))) + _airQueuePriorityBonus(),
	})
	renderQueue()
	updateActionUI()
	UI.renderSpellButtons()

# Plasma abilities: bypass action cap, only gate by charge reserved
func queuePlasmaAction(label = null, fn = null, chargeToReserve = null, spellId = null):
	if (not JS.t(State.combat.get("playerTurn")) or JS.t(State.combat.get("over"))):
		return
	var avail = (JS.or_(State.status.player.get("plasmaCharge"), 0)) - (JS.or_(State.combat.get("plasmaChargeReserved"), 0))
	if (chargeToReserve > 0 and avail < chargeToReserve):
		return
	var snapTarget = State.combat.targetIdx
	State.combat.plasmaChargeReserved = (JS.or_(State.combat.get("plasmaChargeReserved"), 0)) + (JS.or_(chargeToReserve, 0))
	State.combat.actionQueue.append({
		"label": label,
		"fn": fn,
		"targetIdx": snapTarget,
		"isPlasma": true,
		"chargeReserved": JS.or_(chargeToReserve, 0),
		"spellId": JS.or_(spellId, null),
	})
	renderQueue()
	updateActionUI()
	UI.renderSpellButtons()

func removeFromQueue(idx = null):
	if (not JS.t(State.combat.get("playerTurn")) or JS.t(State.combat.get("over"))):
		return
	var a = JS.idx(State.combat.actionQueue, idx)
	if (JS.t(a) and JS.t(a.get("undoCD"))):
		JS.callm(a, "undoCD", [])
	if (JS.t(a) and JS.t(a.get("undoOnQueue"))):
		JS.callm(a, "undoOnQueue", [])
	# Refund reserved Plasma charge
	if ((JS.t(a) and JS.t(a.get("isPlasma"))) and a.chargeReserved > 0):
		State.combat.plasmaChargeReserved = max(0, (JS.or_(State.combat.get("plasmaChargeReserved"), 0)) - a.chargeReserved)
		Spells.updateChargeUI()
	JS.splice(State.combat.actionQueue, idx, 1)
	# Storm Rush removed — cascade-remove any spells that were only queueable due to its CD preview
	if (JS.t(a) and JS.t(a.get("stormRushAction"))):
		for i in range(len(State.combat.actionQueue) - 1, 0 - 1, -1):
			if JS.t(State.combat.actionQueue[i].get("stormRushDependent")):
				JS.splice(State.combat.actionQueue, i, 1)
	renderQueue()
	updateActionUI()
	UI.renderSpellButtons()

func renderQueue():
	var slots = document.getElementById("queue-slots")
	var endBtn = document.getElementById("end-turn-btn")
	if not JS.t(slots):
		return
	# ── Render played cards in #played-card-row ──────────────────────────────
	if true:
		var playedRow = document.getElementById("played-card-row")
		slots.innerHTML = ""
		if JS.t(playedRow):
			var _dragSrcQIdx = [null]
			playedRow.innerHTML = ""
			# ── Build interleaved preview (same logic as commitEndTurn) ────────────
			var _fn10 = func():
				var pq = State.combat.actionQueue
				var eq = State.combat.prebuiltEnemyQueues
				if (not JS.t(eq) or (len(pq) == 0 and not JS.some(eq, func(q = null): return (JS.t(q) and JS.t(len(q)))))):
					return JS.map(pq, func(a = null, qi = null): return {"isPlayer": true, "action": a, "qIdx": qi, "eab": 0})
				var participants = []
				if len(pq) > 0:
					participants.append({"id": "player", "queue": pq})
				var _arr5 = JS.iter(State.combat.enemies)
				for i in range(len(_arr5)):
					var e = _arr5[i]
					if not JS.t(e.get("alive")):
						continue
					var q = JS.or_(JS.idx(eq, i), [])
					if len(q) > 0:
						participants.append({"id": "enemy_" + JS.s(i), "idx": i, "queue": q})
				var _fn6 = func(a = null, b = null):
					if len(b.queue) != len(a.queue):
						return len(b.queue) - len(a.queue)
					if a.get("id") == "player":
						return -1
					if b.get("id") == "player":
						return 1
					return 0
				JS.sort(participants, _fn6)
				var flat = []
				var maxLen = JS.arrMax(JS.arr(JS.arr(participants).map(func(p = null): return len(p.queue))) + [0])
				for slot in range(ceili(maxLen)):
					for p in JS.iter(participants):
						if slot < len(p.queue):
							flat.append({"isPlayer": p.get("id") == "player", "p": p, "action": p.queue[slot], "qIdx": slot, "eab": 0})
				var _arr7 = JS.iter(flat)
				for i in range(len(_arr7)):
					var e = _arr7[i]
					e._nat = i
				var _fn8 = func(a = null, b = null):
					var pa = JS.or_((a.action.get("priority") if JS.t(a.get("action")) else a.get("action")), 0)
					var pb = JS.or_((b.action.get("priority") if JS.t(b.get("action")) else b.get("action")), 0)
					if pb != pa:
						return pb - pa
					return a._nat - b._nat
				JS.sort(flat, _fn8)
				var _arr9 = JS.iter(flat)
				for i in range(len(_arr9)):
					var entry = _arr9[i]
					if JS.t(entry.get("isPlayer")):
						entry.eab = len(JS.arr(JS.slice(flat, 0, i)).filter(func(e = null): return not JS.t(e.get("isPlayer"))))
				return flat
			var _previewFlat = (_fn10).call()
			_dragSrcQIdx[0] = null
			for entry in JS.iter(_previewFlat):
				var isPlayer = JS.idx(entry, "isPlayer")
				var action = JS.idx(entry, "action")
				var qIdx = JS.idx(entry, "qIdx")
				var eab = JS.idx(entry, "eab")
				var pc = document.createElement("div")
				if JS.t(isPlayer):
					pc.className = "played-card"
					pc.draggable = true
					var _pcIcon = (SpellIcons.spellIconSVG(action.spellObj, 22) if (JS.t(action.get("spellObj")) and true) else "<span>" + (JS.or_(JS.idx(JS.split(JS.or_(action.get("label"), ""), " "), 0), "✦")) + "</span>")
					var _pcPri = JS.or_(action.get("priority"), 0)
					var _priBadge = ("<div class=\"pc-priority\" style=\"font-size:.65rem;color:" + ("#7af" if _pcPri > 0 else "#f97") + ";line-height:1;\">" + ("↑" if _pcPri > 0 else "↓") + JS.s(abs(_pcPri)) + "</div>" if _pcPri != 0 else "")
					var _eabBadge = ("<div style=\"font-size:.52rem;color:#f97;line-height:1;margin-top:1px;\" title=\"Enemy acts " + JS.s(eab) + "x before this spell\">⚔" + JS.s(eab) + "</div>" if eab > 0 else "")
					pc.innerHTML = "<div class=\"pc-emoji\">" + _pcIcon + "</div><div class=\"pc-name\">" + JS.replace(JS.or_(action.get("label"), ""), JS.re("^[^\\s]+\\s*", ""), "") + "</div>" + _priBadge + _eabBadge
					pc.title = "Drag to reorder · Click to unqueue"
					pc.onclick = func(): return removeFromQueue(qIdx)
					var _fn11 = func(e = null):
						_dragSrcQIdx[0] = qIdx
						pc.style.opacity = "0.5"
						e.dataTransfer.effectAllowed = "move"
					pc.addEventListener("dragstart", _fn11)
					var _fn12 = func():
						pc.style.opacity = ""
					pc.addEventListener("dragend", _fn12)
					var _fn13 = func(e = null):
						e.preventDefault()
						pc.classList.add("drag-over")
						e.dataTransfer.dropEffect = "move"
					pc.addEventListener("dragover", _fn13)
					pc.addEventListener("dragleave", func(): return pc.classList.remove("drag-over"))
					var _fn14 = func(e = null):
						e.preventDefault()
						pc.classList.remove("drag-over")
						if (_dragSrcQIdx[0] == null or JS.eq(_dragSrcQIdx[0], qIdx)):
							return
						var moved = JS.idx(JS.splice(State.combat.actionQueue, _dragSrcQIdx[0], 1), 0)
						JS.splice(State.combat.actionQueue, qIdx, 0, [moved])
						_dragSrcQIdx[0] = null
						renderQueue()
						UI.renderSpellButtons()
					pc.addEventListener("drop", _fn14)
				else:
					# Enemy action card
					var _eEnemy = JS.idx(State.combat.enemies, entry.p.idx)
					var _eName = (_eEnemy.name if JS.t(_eEnemy) else "Enemy")
					var _pcPri = JS.or_(action.get("priority"), 0)
					var _priBadge = ("<div class=\"pc-priority\" style=\"font-size:.65rem;color:" + ("#f97" if _pcPri > 0 else "#7af") + ";line-height:1;\">" + ("↑" if _pcPri > 0 else "↓") + JS.s(abs(_pcPri)) + "</div>" if _pcPri != 0 else "")
					var _ie = action._intentEntry
					var _hint = ((JS.callm(_ie, "hintFn", []) if JS.t(_ie.get("hintFn")) else JS.or_(_ie.get("hint"), "")) if JS.t(_ie) else "")
					var _eElem = (JS.or_(_eEnemy.get("element"), "Neutral") if JS.t(_eEnemy) else "Neutral")
					var _eRawId = JS.or_((_ie.get("id") if JS.t(_ie) else _ie), "")
					var _eStrippedId = JS.replace(_eRawId, JS.re("^(fire|water|ice|lightning|earth|nature|plasma|air)_", ""), "")
					var _eIconId = (_eRawId if (true and JS.t(JS.idx(SpellIcons.SPELL_ICON_DATA, _eRawId))) else (_eStrippedId if (true and JS.t(JS.idx(SpellIcons.SPELL_ICON_DATA, _eStrippedId))) else null))
					var _eIcon = (SpellIcons.spellIconSVG({"id": _eIconId, "element": _eElem}, 22) if (JS.t(_eIconId) and true) else "<span>" + (JS.or_(JS.idx(JS.split(JS.or_(action.get("label"), ""), " "), 0), "⚔")) + "</span>")
					pc.className = "played-card enemy-queued-card"
					pc.style.cssText = "background:#1a0a0a;border-color:#5a1a1a;cursor:default;opacity:.85;"
					pc.innerHTML = "<div class=\"pc-emoji\">" + _eIcon + "</div><div class=\"pc-name\" style=\"color:#d08080;\">" + (JS.or_(action.get("label"), "Attack")) + "</div>" + _priBadge
					pc.title = JS.s(_eName) + ": " + (JS.or_(action.get("label"), "Attack")) + ("\n" + JS.s(_hint) if JS.t(_hint) else "")
				playedRow.appendChild(pc)
			# Drop zone on card-hand-area to drag a played card back to hand (unqueue)
			var handArea = document.getElementById("card-hand-area")
			if JS.t(handArea):
				var _fn15 = func(e = null):
					e.preventDefault()
					e.dataTransfer.dropEffect = "move"
				handArea.ondragover = _fn15
				var _fn16 = func(e = null):
					e.preventDefault()
					if _dragSrcQIdx[0] != null:
						removeFromQueue(_dragSrcQIdx[0])
						_dragSrcQIdx[0] = null
				handArea.ondrop = _fn16
		UI.renderEnemyCards()
		# Sync the arena end-turn panel (deck mode)
		UI._renderArenaEndTurn(((not JS.t(State.combat.get("over"))) if JS.t(State.combat.get("playerTurn")) else State.combat.get("playerTurn")))
		# Keep the hidden #end-turn-btn in sync (other code reads its state)
		if JS.t(endBtn):
			var hasActions = (len(State.combat.actionQueue) > 0 if JS.t(State.combat.get("actionQueue")) else State.combat.get("actionQueue"))
			endBtn.disabled = JS.or_((not JS.t(State.combat.get("playerTurn"))), State.combat.get("over"))
			endBtn.className = ("end-turn-btn ready" if JS.t(hasActions) else "end-turn-btn")
		return
	# ── Spellbook mode: classic queue list ──────────────────────────────────
	slots.innerHTML = ""
	if (not JS.t(State.combat.get("actionQueue")) or len(State.combat.actionQueue) == 0):
		slots.innerHTML = "<span class=\"queue-empty\">No actions queued — select actions below</span>"
	else:
		var _arr17 = JS.iter(State.combat.actionQueue)
		for i in range(len(_arr17)):
			var a = _arr17[i]
			var s = document.createElement("div")
			s.className = "queue-slot"
			var tname = (" → " + JS.s(JS.idx(State.combat.enemies, a.targetIdx).name) if JS.t(JS.idx(State.combat.enemies, a.targetIdx)) else "")
			var dmgHint = (JS.callm(a, "hintFn", []) if JS.t(a.get("hintFn")) else "")
			s.innerHTML = JS.s(a.label) + tname + ("<div style=\"font-size:.48rem;color:#8aaa88;opacity:.85;margin-top:1px;\">" + JS.s(dmgHint) + "</div>" if JS.t(dmgHint) else "") + " <span class=\"qs-x\">✕</span>"
			s.onclick = func(): return removeFromQueue(i)
			slots.appendChild(s)
	UI.renderEnemyCards()
	if JS.t(endBtn):
		var hasActions = (len(State.combat.actionQueue) > 0 if JS.t(State.combat.get("actionQueue")) else State.combat.get("actionQueue"))
		endBtn.disabled = JS.or_((not JS.t(State.combat.get("playerTurn"))), State.combat.get("over"))
		endBtn.className = ("end-turn-btn ready" if JS.t(hasActions) else "end-turn-btn")
		var totalQ = len(State.combat.actionQueue)
		endBtn.textContent = ("⚔ End Turn — Resolve " + JS.s(totalQ) + " Action" + ("s" if totalQ > 1 else "") if JS.t(hasActions) else "⚔ End Turn")

func updateActionUI():
	var el = document.getElementById("turn-indicator")
	var slotsTxt = document.getElementById("queue-slots-left")
	if not JS.t(el):
		return
	if JS.t(State.combat.get("playerTurn")):
		var queued = len(JS.arr(JS.or_(State.combat.get("actionQueue"), [])).filter(func(a = null): return (not JS.t(a.get("isFree")) and not JS.t(a.get("isPlasma")))))
		var total = JS.or_(State.combat.get("actionsLeft"), 0)
		var alive = Helpers.aliveEnemies()
		var tgt = JS.idx(State.combat.enemies, State.combat.targetIdx)
		el.textContent = "Planning — Target: " + JS.s((tgt.name if JS.t(tgt) else "?")) + " (" + JS.s(len(alive)) + " alive)"
		if JS.t(slotsTxt):
			slotsTxt.textContent = "(" + JS.s(queued) + "/" + JS.s(total) + " queued)"
	else:
		el.textContent = "Resolving..."
		if JS.t(slotsTxt):
			slotsTxt.textContent = ""

# Player hits End Turn — build all enemy queues then resolve
func queueSwitchBook(bookIdx = null):
	if (not JS.t(State.combat.get("playerTurn")) or JS.t(State.combat.get("over"))):
		return
	var book = JS.idx(State.player.spellbooks, bookIdx)
	if (not JS.t(book) or JS.eq(bookIdx, State.player.activeBookIdx)):
		return
	# Check freeSwitch on target book
	var targetCat = (JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, book.catalogueId) if (JS.t(book.get("catalogueId")) and true) else null)
	var isFreeSwitch = (not (not (JS.t(targetCat) and JS.t(targetCat.get("freeSwitch")))))
	# Check stickySwitch on current book (costs extra action to leave)
	var curBook = State.activeBook()
	var curCat = (JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, curBook.catalogueId) if ((JS.t(curBook) and JS.t(curBook.get("catalogueId"))) and true) else null)
	var isSticky = (not (not (JS.t(curCat) and JS.t(curCat.get("stickySwitch")))))
	var nonFreeCount = len(JS.arr(JS.or_(State.combat.get("actionQueue"), [])).filter(func(a = null): return not JS.t(a.get("isFree"))))
	if not isFreeSwitch:
		var needed = (2 if isSticky else 1)
		if (nonFreeCount + needed) > (JS.or_(State.combat.get("actionsLeft"), 0)):
			return
	var prevIdx = State.player.activeBookIdx
	# Immediately switch the display so the player can see the target book's spells
	State.switchBook(bookIdx)
	UI.renderSpellButtons()
	updateActionUI()
	var _fn18 = func():
		if not JS.eq(State.player.activeBookIdx, bookIdx):
			State.switchBook(bookIdx)
		UI.renderSpellButtons()
		updateActionUI()
	var _fn19 = func():
		State.switchBook(prevIdx)
		UI.renderSpellButtons()
		updateActionUI()
	queueAction("📖 " + book.name, _fn18, {"isFree": isFreeSwitch, "undoOnQueue": _fn19})
	# Sticky: consume an extra action slot when leaving the Tome of Time
	if (isSticky and not isFreeSwitch):
		var _fn20 = func():
			UI.log_("⏳ Tome of Time: extra action spent leaving the book.", "status")
		queueAction("⏳ Time Toll", _fn20, {})

func commitEndTurn():
	if (not JS.t(State.combat.get("playerTurn")) or JS.t(State.combat.get("over"))):
		return
	UI.setPlayerTurnUI(false)
	# Split player queue: non-Plasma first, Plasma last
	var allPlayerActions = JS.arr(State.combat.actionQueue)
	State.combat.actionQueue = []
	renderQueue()
	var normalPlayerActions = JS.arr(allPlayerActions).filter(func(a = null): return not JS.t(a.get("isPlasma")))
	var plasmaPlayerActions = JS.arr(allPlayerActions).filter(func(a = null): return JS.t(a.get("isPlasma")))
	State.combat._playerActionsTotal = len(normalPlayerActions)
	State.combat._playerActionIdx = 0
	State.combat._queueAbsPrioritySum = 0
	State.combat._turnTotalAbsPrioritySum = JS.reduce(normalPlayerActions, func(s = null, a = null): return s + abs(JS.or_(a.get("priority"), 0)), 0)
	# Use pre-built enemy queues (built at round start so intents were visible during planning)
	var allEnemyQueues = (State.combat.get("prebuiltEnemyQueues") if JS.t(State.combat.get("prebuiltEnemyQueues")) else JS.map(State.combat.enemies, func(e = null, i = null): return (buildEnemyQueueFor(i, Helpers.actionsPerTurnFor("enemy") + (JS.or_(e.get("bonusActions"), 0))) if JS.t(e.get("alive")) else [])))
	State.combat.prebuiltEnemyQueues = null
	# Show enemy intents before resolution
	UI.renderEnemyCards()
	# Priority sort among non-Plasma participants
	var participants = []
	if len(normalPlayerActions) > 0:
		participants.append({"id": "player", "queue": normalPlayerActions, "hp": State.player.hp, "power": State.player.attackPower})
	var _arr21 = JS.iter(State.combat.enemies)
	for i in range(len(_arr21)):
		var e = _arr21[i]
		if not JS.t(e.get("alive")):
			continue
		participants.append({
			"id": "enemy_" + JS.s(i),
			"idx": i,
			"queue": JS.or_(JS.idx(allEnemyQueues, i), []),
			"hp": e.hp,
			"power": JS.or_(e.get("statPow"), 0),
		})
	var _fn22 = func(a = null, b = null):
		if len(b.queue) != len(a.queue):
			return len(b.queue) - len(a.queue)
		# Equal queue length: player always goes first
		if a.get("id") == "player":
			return -1
		if b.get("id") == "player":
			return 1
		return 0
	JS.sort(participants, _fn22)
	# Log initiative order
	var _fn23 = func(p = null):
		var name_ = (State.playerName if p.get("id") == "player" else JS.idx(State.combat.enemies, p.idx).name)
		return ("🟢" if p.get("id") == "player" else "🔴") + JS.s(name_) + "(" + JS.s(len(p.queue)) + ")"
	var names = JS.arr(participants).map(_fn23)
	if len(plasmaPlayerActions) > 0:
		names.append("🔮Plasma(" + JS.s(len(plasmaPlayerActions)) + ")")
	UI.log_("Initiative: " + JS.join(names, " → "), "system")
	# Weave non-Plasma into flat interleaved list
	var flatActions = []
	var maxLen = JS.arrMax(JS.arr(JS.arr(participants).map(func(p = null): return len(p.queue))) + [0])
	for slot in range(ceili(maxLen)):
		for p in JS.iter(participants):
			if slot < len(p.queue):
				flatActions.append({"p": p, "action": p.queue[slot]})
	# Priority sort: stable sort by priority descending, preserving round-robin tiebreak
	var _arr24 = JS.iter(flatActions)
	for i in range(len(_arr24)):
		var entry = _arr24[i]
		entry._nat = i
	var _fn25 = func(a = null, b = null):
		var pa = JS.or_((a.action.get("priority") if JS.t(a.get("action")) else a.get("action")), 0)
		var pb = JS.or_((b.action.get("priority") if JS.t(b.get("action")) else b.get("action")), 0)
		if pb != pa:
			return pb - pa
		return a._nat - b._nat
	JS.sort(flatActions, _fn25)
	# Compute EAB (enemy actions before) for each player action
	var _arr26 = JS.iter(flatActions)
	for i in range(len(_arr26)):
		var entry = _arr26[i]
		if entry.p.get("id") == "player":
			entry.enemyActionsBefore = len(JS.arr(JS.slice(flatActions, 0, i)).filter(func(e = null): return e.p.get("id") != "player"))
	# Tailwind Carry: track if all player actions resolved first (EAB=0)
	State.combat._tailwindAllFirst = JS.some(flatActions, func(e = null): return e.p.get("id") == "player")
	for e in JS.iter(flatActions):
		if (e.p.get("id") == "player" and (JS.or_(e.get("enemyActionsBefore"), 0)) > 0):
			State.combat._tailwindAllFirst = false
	# Plasma actions go at the very end
	for a in JS.iter(plasmaPlayerActions):
		flatActions.append({"p": {"id": "player"}, "action": a, "isPlasmaFinal": true})
	# Afterburn: burn ticks before actions resolve
	if JS.t(State.combat.get("_afterburnActive")):
		_tickAfterburn("before")
	State.combat._gen = (JS.or_(State.combat.get("_gen"), 0)) + 1
	resolveFlat(flatActions, 0, State.combat._gen)

func _tickAfterburn(phase = null):
	var _arr27 = JS.iter(State.combat.enemies)
	for i in range(len(_arr27)):
		var e = _arr27[i]
		if (not JS.t(e.get("alive")) or not (e.status.burnStacks > 0)):
			continue
		State.setActiveEnemy(i)
		var bdmg = ceili(e.status.burnStacks * Helpers.burnDmgPerStack("player", Helpers.effectPowerFor("player")))
		if bdmg > 0:
			Hit.applyEffectDamage("player", "enemy", bdmg, "🔥💨 Afterburn (" + JS.s(phase) + ")")
	if not JS.t(State.combat.get("over")):
		State.setActiveEnemy(State.combat.targetIdx)

func resolveFlat(flatActions = null, idx = null, chainGen = null):
	# Stale chain guard: abort if a newer chain has started (e.g. post-revive)
	if not JS.eq(State.combat._gen, chainGen):
		return
	if idx >= len(flatActions):
		# Afterburn: burn ticks after all actions resolve
		if (not JS.t(State.combat.get("over")) and JS.t(State.combat.get("_afterburnActive"))):
			_tickAfterburn("after")
			State.combat._afterburnActive = false
		# Tailwind Carry: all player actions went first → bonus action next turn
		if (((not JS.t(State.combat.get("over")) and Main.hasPassive("air_tailwind_carry")) and State.playerElement == "Air") and JS.t(State.combat.get("_tailwindAllFirst"))):
			var _tcChoice = JS.or_(State.player.get("_tailwindCarryChoice"), "fast")
			State.combat._tailwindBonusPriority = (-1 if _tcChoice == "slow" else 1)
			State.combat._tailwindBonusNextTurn = true
			UI.log_("🌬️ Tailwind Carry! Bonus action next turn (priority " + ("+" if State.combat._tailwindBonusPriority > 0 else "") + JS.s(State.combat._tailwindBonusPriority) + ").", "status")
		# All actions done — now check deferred death
		if (State.player.hp <= 0 and not JS.t(State.combat.get("over"))):
			endBattle(false)
			return
		if JS.t(State.combat.get("over")):
			return
		_tickPlayerCDs()
		# round fully resolved — tick CDs now
		if (not JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx)) or not JS.t(JS.idx(State.combat.enemies, State.combat.targetIdx).get("alive"))):
			State.combat.targetIdx = Helpers.firstAliveIdx()
		State.setActiveEnemy(State.combat.targetIdx)
		JS.setTimeout(startRound, 650)
		return
	var _d28 = JS.idx(flatActions, idx)
	var p = JS.idx(_d28, "p")
	var action = JS.idx(_d28, "action")
	var isPlasmaFinal = JS.idx(_d28, "isPlasmaFinal")
	var _fn29 = func():
		if not JS.t(State.combat.get("over")):
			JS.setTimeout(func(): return resolveFlat(flatActions, idx + 1, chainGen), 320)
	var next = _fn29
	if p.get("id") == "player":
		var snapTgt = (action.targetIdx if action.get("targetIdx") != null else State.combat.targetIdx)
		State.combat.targetIdx = snapTgt
		State.setActiveEnemy(snapTgt)
		State.combat._playerActionIdx = (JS.or_(State.combat.get("_playerActionIdx"), 0)) + 1
		State.combat.currentQueuePosition = (JS.idx(flatActions, idx).enemyActionsBefore if JS.idx(flatActions, idx).get("enemyActionsBefore") != null else 0)
		# Vortex Strike: consecutive player actions, first in each run
		var _prevWasPlayer = (idx > 0 and JS.idx(flatActions, idx - 1).p.get("id") == "player")
		if not _prevWasPlayer:
			State.combat._vortexUsedThisSequence = false
		State.combat._vortexStrikeActive = (((Main.hasPassive("air_vortex_strike") and State.playerElement == "Air") and _prevWasPlayer) and not JS.t(State.combat.get("_vortexUsedThisSequence")))
		if JS.t(State.combat.get("_vortexStrikeActive")):
			State.combat._vortexUsedThisSequence = true
			UI.log_("🌀 Vortex Strike! +50% damage.", "status")
		JS.callm(action, "fn", [])
		State.combat.currentQueuePosition = 0
		State.combat._vortexStrikeActive = false
		State.combat._queueAbsPrioritySum = (JS.or_(State.combat.get("_queueAbsPrioritySum"), 0)) + abs(JS.or_(action.get("priority"), 0))
		# Headwind: bonus hit when acting first (EAB=0)
		if ((((not JS.t(State.combat.get("over")) and State.playerElement == "Air") and Main.hasPassive("air_headwind")) and (JS.or_(JS.idx(flatActions, idx).get("enemyActionsBefore"), 0)) == 0) and not JS.t(isPlasmaFinal)):
			var _hwDmg = JS.round(10 + (Helpers.attackPowerFor("player", "enemy") * 0.5))
			Hit.applyDirectDamage.call("player", "enemy", _hwDmg, "💨 Headwind")
		# Turbulence: momentum from enemy actions before
		if (((not JS.t(State.combat.get("over")) and State.playerElement == "Air") and Main.hasPassive("air_turbulence")) and not JS.t(isPlasmaFinal)):
			var _turbGain = min(2, JS.or_(JS.idx(flatActions, idx).get("enemyActionsBefore"), 0)) * 2
			if _turbGain > 0:
				Helpers.addMomentumStacks(_turbGain)
		if (not JS.t(State.combat.get("over")) and JS.t(action.get("isSpellAction"))):
			_applyBookSpellEffect(action)
		UI.updateHPBars()
		UI.renderStatusTags()
		if ((not JS.t(isPlasmaFinal) and State.player.hp <= 0) and not JS.t(State.combat.get("over"))):
			UI.log_("💀 You dropped to 0 HP — Plasma heals may save you!", "status")
		next.call()
	else:
		var eIdx = p.idx
		if (not JS.t(JS.idx(State.combat.enemies, eIdx)) or not JS.t(JS.idx(State.combat.enemies, eIdx).get("alive"))):
			next.call()
			return
		State.setActiveEnemy(eIdx)
		# Remove the fired intent from the queue so remaining ones stay visible
		var enemy = JS.idx(State.combat.enemies, eIdx)
		if (JS.t(enemy.get("intentQueue")) and len(enemy.intentQueue) > 0):
			enemy.intentQueue.pop_front()
		if enemy.status.stunned > 0:
			enemy.status.stunned -= 1
			UI.log_(enemy.emoji + " " + enemy.name + " is stunned!", "status")
			UI.renderStatusTags()
		else:
			JS.callm(action, "fn", [])
			UI.updateHPBars()
			UI.renderStatusTags()
		UI.renderEnemyCards()
		next.call()

# Returns true if this intent should be hidden by the Hidden Intentions mist modifier
func _intentHidden():
	var tier = Mist.getMistTier("hidden_intentions")
	if not JS.t(tier):
		return false
	var chance = JS.idx([0.25, 0.5, 0.75, 1.0], tier - 1)
	return randf() < chance

func _liveAttackHint(idx = null, baseDmg = null, el = null):
	if JS.t(State.player.get("_mistBlindDamage")):
		return ""
	var e = JS.idx(State.combat.enemies, idx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return ""
	var es = JS.or_(e.get("status"), {})
	var ps = JS.or_(State.status.get("player"), {})
	# Read AP with this enemy as active so attackPowerFor uses its status
	var prevIdx = State.combat.activeEnemyIdx
	State.combat.activeEnemyIdx = idx
	var ap = Helpers.attackPowerFor("enemy", "player")
	State.combat.activeEnemyIdx = prevIdx
	var dmg = max(0, JS.round(baseDmg + ap))
	# Zone bonus
	if ((JS.t(State.combat.get("activeZoneElement")) and dmg > 0) and Helpers.primaryElement(JS.or_(e.get("element"), "")) == State.combat.activeZoneElement):
		dmg = JS.round(dmg * 1.2)
	# Enemy shock reduces their outgoing damage
	var shockStacks = JS.or_(es.get("shockStacks"), 0)
	if (shockStacks > 0 and dmg > 0):
		var reduction = min(0.75, shockStacks * 0.03)
		dmg = max(0, JS.round(dmg * (1 - reduction)))
	# Player block absorbs
	var block = JS.or_(ps.get("block"), 0)
	var afterBlock = max(0, dmg - block)
	var procs = {
		"Fire": "· +3 🔥 Burn",
		"Ice": "· +2 ❄️ Frost",
		"Water": "· +1 🫧 Foam",
		"Earth": "· cracks Armor",
		"Lightning": "· +⚡ Shock",
		"Nature": "· +1 🌿 Root",
	}
	var hint = "~" + JS.s(afterBlock) + " dmg"
	if (block > 0 and afterBlock != dmg):
		hint += " (" + JS.s(dmg) + "−" + JS.s(block) + " blk)"
	if shockStacks > 0:
		hint += " [⚡×" + JS.s(shockStacks) + " reduces]"
	if JS.t(JS.idx(procs, el)):
		hint += " " + JS.s(JS.idx(procs, el))
	return hint.strip_edges()

func buildEnemyQueueFor(idx = null, count = null):
	var e = JS.idx(State.combat.enemies, idx)
	var q = []
	# Clear previous intent
	e.intentQueue = []
	# Target dummy: never attacks, just stands still
	if JS.t(e.get("isTargetDummy")):
		for j in range(ceili(count)):
			var _fn30 = func():
				UI.log_("🎯 " + e.name + " stands still.", "enemy")
			q.append({"label": "Stand Still", "intentIdx": j, "fn": _fn30})
			e.intentQueue.append({"label": "Stand Still", "hidden": false})
		return q
	var cdPenalty = Helpers.enemyCooldownPenaltyFor(idx)
	var cd = e.basicCD
	for j in range(ceili(count)):
		if cd <= 0:
			var snapIdx = idx
			# Try to use an item first (one-time consumable, fires on conditions)
			var item = EnemyAbilities.pickEnemyItem(e)
			if JS.t(item):
				e.items = JS.arr(e.items).filter(func(it = null): return not JS.eq(it.id, item.id))
				var snapItem = item
				var snapHint = ("Heals 20% max HP" if snapItem.get("id") == "enemy_healing_draught" else "+15 Block")
				var intentEntry = {"label": snapItem.emoji + " " + snapItem.name, "hidden": false, "hint": snapHint}
				e.intentQueue.append(intentEntry)
				var _fn31 = func():
					if (JS.t(State.combat.get("over")) or not JS.t(JS.idx(State.combat.enemies, snapIdx).get("alive"))):
						return
					JS.callm(snapItem, "fn", [snapIdx])
					UI.updateHPBars()
					UI.renderStatusTags()
					UI.updateStatsUI()
				q.append({
					"label": snapItem.emoji + " " + snapItem.name,
					"intentIdx": len(e.intentQueue) - 1,
					"_intentEntry": intentEntry,
					"fn": _fn31,
				})
				cd = cdPenalty
				continue
			var isGymEnemy = (not (not JS.t(JS.idx(State.combat.enemies, idx).get("isGym"))))
			if isGymEnemy:
				var gymE = JS.idx(State.combat.enemies, idx)
				if (not JS.t(gymE.get("gymPhase2")) and gymE.hp <= (gymE.enemyMaxHP * 0.5)):
					gymE.gymPhase2 = true
					gymE.enemyDmg = gymE.gymPhase2Dmg
					var intentEntry = {"label": "💢 Enrage", "hidden": false}
					e.intentQueue.append(intentEntry)
					var _fn32 = func():
						UI.log_("💢 " + gymE.name + " ENRAGES! Damage surges!", "enemy")
						gymE.hp = min(gymE.enemyMaxHP, (JS.or_(gymE.get("hp"), 0)) + 40)
						UI.renderEnemyCards()
					q.append({"label": "💢 Enrage", "intentIdx": len(e.intentQueue) - 1, "fn": _fn32})
					cd = 1 + cdPenalty
					continue
				gymE.gymHitCounter = (JS.or_(gymE.get("gymHitCounter"), 0)) + 1
				var isCharge = ((JS.mod(gymE.gymHitCounter, gymE.gymChargeInterval)) == 0 if JS.t(gymE.get("gymChargeInterval")) else gymE.get("gymChargeInterval"))
				var chargeLabel = ("⚡ Charge" if JS.t(isCharge) else "⚔ Attack")
				var _gymEl = Helpers.primaryElement(JS.or_(gymE.get("element"), ""))
				var _gymDmg = (JS.round(gymE.enemyDmg * 2.5) if JS.t(isCharge) else gymE.enemyDmg)
				var _snapGymDmg = _gymDmg
				var _snapGymEl = _gymEl
				var intentEntry = {
					"label": chargeLabel,
					"hidden": _intentHidden(),
					"hintFn": func(): return _liveAttackHint(snapIdx, _snapGymDmg, _snapGymEl),
				}
				e.intentQueue.append(intentEntry)
				var _fn33 = func():
					State.setActiveEnemy(snapIdx)
					var gem = JS.idx(State.combat.enemies, snapIdx)
					var dmg = (JS.round(gem.enemyDmg * 2.5) if JS.t(isCharge) else gem.enemyDmg)
					if JS.t(isCharge):
						UI.log_("💥 " + gem.name + " winds up a CHARGE ATTACK!", "enemy")
					var gemEl = Helpers.primaryElement(JS.or_(gem.get("element"), ""))
					Hit.performHit("enemy", "player", {
						"baseDamage": dmg,
						"effects": Helpers.enemyElementalEffects(gemEl),
						"isBasic": true,
						"isEnemyAttack": true,
						"abilityElement": gemEl,
					})
					if not JS.t(State.combat.get("over")):
						Helpers.applyEnemyElementalProc(gemEl, snapIdx)
				q.append({"label": chargeLabel, "intentIdx": len(e.intentQueue) - 1, "_intentEntry": intentEntry, "fn": _fn33})
			else:
				# Try to use an ability this action (blocked if silenced)
				var ability = (null if e._silenced > 0 else EnemyAbilities.pickEnemyAbility(e, State.currentGymIdx))
				if JS.t(ability):
					ability.cd = ability.baseCd
					var snapAbility = ability
					var abilLabel = snapAbility.emoji + " " + snapAbility.name
					var intentEntry = {
						"label": abilLabel,
						"hidden": _intentHidden(),
						"id": snapAbility.id,
						"hintFn": (func(): return JS.callm(snapAbility, "hintFn", []) if JS.t(snapAbility.get("hintFn")) else null),
						"hint": (null if JS.t(snapAbility.get("hintFn")) else JS.or_(JS.idx(EnemyAbilities.ENEMY_ABILITY_HINTS, snapAbility.id), "")),
					}
					e.intentQueue.append(intentEntry)
					var _fn34 = func():
						if JS.t(State.combat.get("over")):
							return
						if not JS.t(JS.idx(State.combat.enemies, snapIdx).get("alive")):
							return
						State.setActiveEnemy(snapIdx)
						JS.callm(snapAbility, "fn", [snapIdx])
						UI.updateHPBars()
						UI.renderStatusTags()
						UI.updateStatsUI()
					q.append({"label": abilLabel, "intentIdx": len(e.intentQueue) - 1, "_intentEntry": intentEntry, "fn": _fn34})
				else:
					# Basic attack — 1-turn CD so it can't fire twice in one turn
					var _el2 = Helpers.primaryElement(JS.or_(e.get("element"), ""))
					var _snapDmg2 = e.enemyDmg
					var _snapEl2 = _el2
					var intentEntry = {
						"label": "⚔ Attack",
						"hidden": _intentHidden(),
						"hintFn": func(): return _liveAttackHint(snapIdx, _snapDmg2, _snapEl2),
					}
					e.intentQueue.append(intentEntry)
					var _fn35 = func():
						State.setActiveEnemy(snapIdx)
						var e2 = JS.idx(State.combat.enemies, snapIdx)
						var el = Helpers.primaryElement(JS.or_(e2.get("element"), ""))
						Hit.performHit("enemy", "player", {
							"baseDamage": e2.enemyDmg,
							"effects": Helpers.enemyElementalEffects(el),
							"isBasic": true,
							"isEnemyAttack": true,
							"abilityElement": el,
						})
						if not JS.t(State.combat.get("over")):
							Helpers.applyEnemyElementalProc(el, snapIdx)
						if (JS.t(State.combat.get("activeZoneElement")) and not JS.t(State.combat.get("over"))):
							var zfx = JS.idx(Encounters.ZONE_EFFECTS, State.combat.activeZoneElement)
							if JS.t(zfx):
								JS.callm(zfx, "apply", ["player", snapIdx])
							UI.updateHPBars()
							UI.renderStatusTags()
					q.append({"label": "⚔ Attack", "intentIdx": len(e.intentQueue) - 1, "_intentEntry": intentEntry, "fn": _fn35})
					cd = 1 + cdPenalty
					# basic attack puts itself on CD — second slot uses ability or waits
					continue
			cd = cdPenalty
		else:
			# Basic attack on cooldown — try to use an ability instead of waiting
			var snapIdx = idx
			var ability2 = (null if e._silenced > 0 else EnemyAbilities.pickEnemyAbility(e, State.currentGymIdx))
			if JS.t(ability2):
				ability2.cd = ability2.baseCd
				var snapAbility2 = ability2
				var abilLabel2 = snapAbility2.emoji + " " + snapAbility2.name
				var intentEntry2 = {
					"label": abilLabel2,
					"hidden": _intentHidden(),
					"id": snapAbility2.id,
					"hintFn": (func(): return JS.callm(snapAbility2, "hintFn", []) if JS.t(snapAbility2.get("hintFn")) else null),
					"hint": (null if JS.t(snapAbility2.get("hintFn")) else JS.or_(JS.idx(EnemyAbilities.ENEMY_ABILITY_HINTS, snapAbility2.id), "")),
				}
				e.intentQueue.append(intentEntry2)
				var _fn36 = func():
					if JS.t(State.combat.get("over")):
						return
					if not JS.t(JS.idx(State.combat.enemies, snapIdx).get("alive")):
						return
					State.setActiveEnemy(snapIdx)
					JS.callm(snapAbility2, "fn", [snapIdx])
					UI.updateHPBars()
					UI.renderStatusTags()
					UI.updateStatsUI()
				q.append({"label": abilLabel2, "intentIdx": len(e.intentQueue) - 1, "_intentEntry": intentEntry2, "fn": _fn36})
			# else: no action available — slot consumed silently (no "Wait" shown)
			cd -= 1
	e.basicCD = max(0, cd)
	return q

func executeOneEnemyAction(idx = null):
	if JS.t(State.combat.get("over")):
		return
	var e = JS.idx(State.combat.enemies, idx)
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	State.setActiveEnemy(idx)
	if e.status.stunned > 0:
		e.status.stunned -= 1
		UI.log_(JS.s(e.emoji) + " " + JS.s(e.name) + " is stunned!", "status")
		UI.renderStatusTags()
		return
	if e.basicCD <= 0:
		e.basicCD = 1 + Helpers.enemyCooldownPenalty()
		var el = Helpers.primaryElement(JS.or_(e.get("element"), ""))
		Hit.performHit("enemy", "player", {
			"baseDamage": e.enemyDmg,
			"effects": Helpers.enemyElementalEffects(el),
			"isBasic": true,
			"isEnemyAttack": true,
			"abilityElement": el,
		})
		if not JS.t(State.combat.get("over")):
			Helpers.applyEnemyElementalProc(el, JS.indexOf(State.combat.enemies, e))

func resolveSummonAttacks():
	if (not JS.t(State.combat.get("summons")) or len(State.combat.summons) == 0):
		return
	var alive = Helpers.aliveEnemies()
	if len(alive) == 0:
		return
	for s in JS.iter(State.combat.summons):
		if s.hp <= 0:
			continue
		if s.cd > 0:
			s.cd -= 1
			continue
		var target = JS.idx(alive, floori(randf() * len(alive)))
		var tIdx = JS.indexOf(State.combat.enemies, target)
		State.setActiveEnemy(tIdx)
		UI.log_("🌳 " + JS.s(s.name) + " strikes " + JS.s(target.name) + "!", "player")
		Hit.performHit("player", "enemy", {"baseDamage": s.dmg, "effects": [], "isBasic": false, "abilityElement": "Nature", "isSummon": true})
		if (not JS.t(State.combat.get("over")) and randf() < (JS.or_(s.get("rootChance"), 0.5))):
			Helpers.applyRoot("player", "enemy", 1)
	# Remove dead summons
	State.combat.summons = JS.arr(State.combat.summons).filter(func(s = null): return s.hp > 0)
	UI.renderSummonsRow()

func toggleInventory():
	if (not JS.t(State.combat.get("playerTurn")) or JS.t(State.combat.get("over"))):
		return
	document.getElementById("inv-panel").classList.toggle("open")

func useItemInCombat(idx = null):
	if (not JS.t(State.combat.get("playerTurn")) or JS.t(State.combat.get("over"))):
		return
	var item = JS.idx(State.player.inventory, idx)
	if not JS.t(item):
		return
	if len(JS.or_(State.combat.get("actionQueue"), [])) >= State.combat.actionsLeft:
		return
	document.getElementById("inv-panel").classList.remove("open")
	# snapshot item, remove from inv immediately to prevent double-queue
	var snapItem = JS.merge([item])
	Spells.removeItemAt(idx)
	renderCombatInventory()
	var _fn37 = func():
		var result = JS.callm(snapItem, "use", [])
		if JS.t(result):
			UI.log_(JS.s(snapItem.emoji) + " " + JS.s(result), "item")
		UI.updateHPBars()
		UI.updateStatsUI()
	queueAction(JS.s(snapItem.emoji) + " " + JS.s(snapItem.name), _fn37)

func renderCombatInventory():
	var panel = document.getElementById("inv-panel")
	var count = len(State.player.inventory)
	document.getElementById("inv-count-label").textContent = JS.s(count) + " item" + ("" if count == 1 else "s")
	panel.innerHTML = ""
	if count == 0:
		panel.innerHTML = "<div class=\"inv-empty\">No items</div>"
	else:
		var _arr38 = JS.iter(State.player.inventory)
		for idx in range(len(_arr38)):
			var item = _arr38[idx]
			var b = document.createElement("button")
			b.className = "inv-item-btn"
			b.innerHTML = "<span>" + JS.s(item.emoji) + " " + JS.s(item.name) + " <span style=\"color:#666;font-size:.63rem;\">— " + JS.s(item.desc) + "</span></span><span style=\"color:#555;font-size:.63rem;\">USE (1)</span>"
			b.onclick = func(): return useItemInCombat(idx)
			panel.appendChild(b)

func endBattle(won = null):
	if JS.t(State.combat.get("over")):
		return
	State.combat.over = true
	UI.setPlayerTurnUI(false)
	Sprites.stopBattleLoop()
	State.combat.summons = []
	if JS.t(won):
		var _lootItemId = [null]
		var isGym = JS.some(State.combat.enemies, func(e = null): return JS.t(e.get("isGym")))
		UI.log_("⚔ Victory!", "win")
		if JS.t(State.player.get("_ktRecoveryPct")):
			Helpers.applyHeal("player", floori(Helpers.maxHPFor("player") * State.player._ktRecoveryPct), "💊 Recovery")
		var goldBase = JS.or_(State.combat.get("totalGold"), 0)
		var gold = JS.round(goldBase * (1 + (JS.or_(State.player.get("_goldBonus"), 0))))
		State.player.gold += gold
		if gold > 0:
			UI.log_("✦ Gained " + JS.s(gold) + " gold" + (" (" + JS.s(JS.round(State.player._goldBonus * 100)) + "% bonus)" if State.player._goldBonus > 0 else "") + ".", "item")
		_lootItemId[0] = null
		if randf() < Constants.ITEM_DROP_CHANCE:
			_lootItemId[0] = JS.idx(Items.ITEM_DROP_POOL, floori(randf() * len(Items.ITEM_DROP_POOL)))
			Spells.addItem(_lootItemId[0])
			UI.log_("✦ Item dropped: " + JS.s(JS.idx(Items.ITEM_CATALOGUE, _lootItemId[0]).emoji) + " " + JS.s(JS.idx(Items.ITEM_CATALOGUE, _lootItemId[0]).name) + "!", "item")
		UI.updateHPBars()
		UI.updateStatsUI()
		var isRival = (not (not JS.t(State.combat.get("_isRival"))))
		if isGym:
			# Full heal + PP restore on gym clear
			State.player.hp = Helpers.maxHPFor("player")
			BattleLoad.restoreAllPP()
			UI.updateHPBars()
			UI.updateStatsUI()
			UI.log_("✦ Gym cleared — full HP and PP restored!", "win")
			var beatenGym = Encounters.currentGymDef()
			var gymIdx = State.currentGymIdx
			if JS.t(beatenGym):
				UI.log_("🏆 Gym " + JS.s(JS.add(State.currentGymIdx, 1)) + " — " + beatenGym.name + " defeated!", "win")
			# Artifact discovery (65% chance)
			var newArt = Artifacts.onGymDefeated(gymIdx)
			if JS.t(newArt):
				var def = JS.idx(Artifacts.ARTIFACT_CATALOGUE, newArt.id)
				if JS.t(def):
					UI.log_("🏺 Artifact Discovered: " + def.emoji + " " + def.name + " — check the Vault!", "item")
			var _beatenGymIdx = State.currentGymIdx
			# capture before advancing
			# Gauntlet boss victory — not a zone gym
			if JS.t(State.combat.get("_isGauntletBoss")):
				Encounters._gauntletBossIdx += 1
				State.battleNumber += 1
				if Encounters._gauntletBossIdx >= len(Encounters.GAUNTLET_ROSTER):
					# All 3 gauntlet bosses defeated — run victory
					JS.setTimeout(MapLogic.showRunVictory, 1200)
				else:
					# Next gauntlet boss
					JS.setTimeout(BattleLoad._loadGauntletBoss, 1400)
				return
			Helpers.advanceToNextGym()
			# resets zoneBattleCount and gymSkips
			# After the final zone gym — arm the gauntlet sequence.
			# showMap() will detect gymDefeated and redirect into the gauntlet after rewards.
			# Non-sandbox: 3 released-element gyms (indices 0-2) → Dark One (GAUNTLET_ROSTER index 2).
			# Sandbox: 8 gyms (indices 0-7) → full gauntlet from Skar (index 0).
			var lastGymIdx = len(Encounters.GYM_ROSTER) - 1
			if _beatenGymIdx == lastGymIdx:
				Encounters._gauntletBossIdx = (0 if JS.t(Constants.sandboxMode) else 2)
				# sandbox: full gauntlet; non-sandbox: Dark One only
				State.battleNumber += 1
		elif isRival:
			# Fall through to showPostBattleLoot — showMap() will load gauntlet after rewards
			UI.log_("⚔ Rival " + Encounters.RIVAL.name + " defeated! Passive reward incoming...", "win")
			State._zoneRivalDefeated = true
			State.battleNumber += 1
			State._runRoomsCompleted += 1
			State.zoneBattleCount += 1
			# rival counts as a zone room
			Artifacts.checkBattleRecord()
		else:
			State.battleNumber += 1
			State._runRoomsCompleted += 1
			State.zoneBattleCount += 1
			# track progress through this gym's zone
			Artifacts.checkBattleRecord()
		# Warlord's Banner reward on every win
		Artifacts.applyBannerReward()
		# Increment active artifact room counter for non-gym battles
		if not isGym:
			var artUpgrade = Artifacts.incrementArtifactRooms()
			if JS.t(artUpgrade):
				var def = JS.idx(Artifacts.ARTIFACT_CATALOGUE, artUpgrade.id)
				if JS.t(def):
					UI.log_("🏺 " + JS.s(def.emoji) + " " + JS.s(def.name) + " " + "★".repeat(artUpgrade.star) + " — Artifact leveled up!", "item")
		var _fn39 = func():
			BattleReward.showPostBattleLoot(isGym, JS.or_(State.combat.get("_isSpellBattle"), false), isRival, gold, _lootItemId[0])
		JS.setTimeout(_fn39, 900)
	else:
		if State.player.revives > 0:
			State.player.revives -= 1
			var revivePct = min(1.0, 0.75 + (JS.or_(State.player.get("_talentReviveBonus"), 0)))
			var reviveHP = floori(Helpers.maxHPFor("player") * revivePct)
			State.player.hp = reviveHP + (JS.or_(State.player.get("_gritHealOnRevive"), 0))
			State.player.hp = min(State.player.hp, Helpers.maxHPFor("player"))
			# Clear all negative debuffs on revive
			State.status.player.burnStacks = 0
			State.status.player.foamStacks = 0
			State.status.player.frostStacks = 0
			State.status.player.frozen = false
			State.status.player.shockStacks = 0
			State.status.player.rootStacks = 0
			State.status.player.stunned = 0
			State.status.player.frozenGroundTurns = 0
			State.combat.over = false
			UI.log_("💀 Fatal blow! ❤️ Life lost — reviving to " + JS.s(State.player.hp) + " HP. (" + JS.s(State.player.revives) + " lives left)", "win")
			UI.updateHPBars()
			UI.updateStatsUI()
			JS.setTimeout(startRound, 1400)
		else:
			UI.log_("💀 All lives lost. Your run ends here.", "lose")
			JS.setTimeout(MapLogic.showGameOver, 1200)

# ── ZONE TICK ─────────────────────────────────────────────────────────────────
# Called once per round at startRound. Applies small passive zone pressure.
func applyZoneTick():
	if (not JS.t(State.combat.get("activeZoneElement")) or JS.t(State.combat.get("over"))):
		return
	var el = State.combat.activeZoneElement
	match el:
		"Fire":
			# +2 burn on player from the scorched environment
			State.status.player.burnStacks = (JS.or_(State.status.player.get("burnStacks"), 0)) + 2
			State.status.player.burnSourcePower = max(JS.or_(State.status.player.get("burnSourcePower"), 0), floori(State.battleNumber * 1.5))
			UI.log_("🔥 Zone: searing heat applies +2 Burn.", "status")
		"Ice":
			# +2 frost on player from the frozen air
			Helpers.applyFrost("enemy", "player", 2)
			UI.log_("❄️ Zone: biting cold applies +2 Frost.", "status")
		"Lightning":
			# +1 shock on player from static in the air
			State.status.player.shockStacks = (JS.or_(State.status.player.get("shockStacks"), 0)) + 1
			UI.log_("⚡ Zone: static charge applies +1 Shock.", "status")
		"Earth":
			# All alive enemies gain +1 stone stack — they're on home turf
			for e in JS.iter(Helpers.aliveEnemies()):
				e.status.stoneStacks = (JS.or_(e.status.get("stoneStacks"), 0)) + 1
			UI.log_("🪨 Zone: earthen power grants enemies +1 Stone.", "status")
		"Nature":
			# 40% chance to root player — vines creep in
			if randf() < 0.4:
				Helpers.applyRoot("enemy", "player", 1)
				UI.log_("🌿 Zone: creeping vines apply 1 Root.", "status")
		"Water":
			# +1 foam on player — drenched environment blunts defences
			Helpers.applyFoam("enemy", "player", 1)
			UI.log_("🫧 Zone: sea spray applies +1 Foam (reduces your Block).", "status")
		"Plasma":
			# All alive enemies gain +3% dodge this round from phasing reality
			for e in JS.iter(Helpers.aliveEnemies()):
				e.status.battleDodgeBonus = min(0.3, (JS.or_(e.status.get("battleDodgeBonus"), 0)) + 0.03)
			UI.log_("🔮 Zone: reality flickers — enemies +3% dodge.", "status")
		"Air":
			# 25% chance to stun player 1t from battering winds
			if randf() < 0.25:
				State.status.player.stunned = max(JS.or_(State.status.player.get("stunned"), 0), 1)
				UI.log_("🌀 Zone: battering winds stun you for 1 turn!", "status")
	UI.renderStatusTags()
	UI.renderEnemyCards()
