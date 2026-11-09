# Surge — generated from js/logic/surge.js by tools/js2gd.js
extends Node


func _boot():
	pass

# ===== surge.js =====
# ─── LIGHTNING SURGE SYSTEM ──────────────────────────────────────────────────
# Surge is a Lightning status effect. One Surge per target.
# A Surge has a stored damage value and a meter that fills as the target takes damage.
# When the meter hits the threshold, Surge triggers: deals its value, then is consumed.
# Returns the current Surge trigger threshold (base 60, modified by passives/Fulgurite).
func _getSurgeThreshold():
	var threshold = (60 - (JS.or_(State.combat.get("_surgeFulguriteMinus"), 0))) + (JS.or_(State.combat.get("_stormCoreBonus"), 0))
	if Main.hasPassive("lightning_hair_trigger"):
		threshold -= 10
	# Galestrike (Air+Lightning duo): Momentum reduces threshold by floor(momentum/2)
	if Main.hasPassive("duo_galestrike"):
		threshold -= floori((JS.or_(State.status.player.get("momentumStacks"), 0)) / 2.0)
	return max(10, threshold)

# Apply Surge to a target. Creates new Surge or handles stacking per passives.
# targetSide: 'enemy' | 'player'
# value: the damage Surge will deal when it triggers
func _applySurge(targetSide = null, value = null, label = null):
	var tStatus = null
	if targetSide == "enemy":
		var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if (not JS.t(e) or not JS.t(e.get("alive"))):
			return
		tStatus = e.status
	else:
		tStatus = State.status.player
	label = JS.or_(label, "⚡ Surge")
	if JS.t(tStatus.get("surgeActive")):
		# Amplified: adding Surge to already-Surged target adds 25% of new value
		if Main.hasPassive("lightning_amplified"):
			var bonus = JS.round(value * 0.25)
			tStatus.surgeValue = (JS.or_(tStatus.get("surgeValue"), 0)) + bonus
			UI.log_("⚡ Amplified: Surge +" + JS.s(bonus) + " → " + JS.s(tStatus.surgeValue) + " stored", "status")
		else:
			UI.log_("⚡ Surge already active (" + JS.s(tStatus.surgeValue) + " dmg, " + JS.s(JS.round(JS.or_(tStatus.get("surgeMeter"), 0))) + "/" + JS.s(_getSurgeThreshold()) + " charged)", "status")
		return
	tStatus.surgeActive = true
	tStatus.surgeValue = value
	tStatus.surgeMeter = 0
	UI.log_(label + ": " + JS.s(value) + " dmg Surge loaded (triggers at " + JS.s(_getSurgeThreshold()) + " dmg)", "status")

# Add damage to the Surge meter. Called whenever damage is dealt to a target.
# source: 'hit' | 'dot' | 'conductivity' (informational only)
func _addToSurgeMeter(targetSide = null, dmgAmt = null):
	if dmgAmt <= 0:
		return
	var tStatus = null
	if targetSide == "enemy":
		var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if (not JS.t(e) or not JS.t(e.get("alive"))):
			return
		tStatus = e.status
	else:
		tStatus = State.status.player
	if (not JS.t(tStatus) or not JS.t(tStatus.get("surgeActive"))):
		return
	tStatus.surgeMeter = (JS.or_(tStatus.get("surgeMeter"), 0)) + dmgAmt
	# Check if threshold reached
	if tStatus.surgeMeter >= _getSurgeThreshold():
		_triggerSurge(targetSide)

# Trigger a Surge on the target — deal damage, apply passives, consume Surge.
func _triggerSurge(targetSide = null):
	var tStatus = null
	var targetName = null
	var targetObj = null
	if targetSide == "enemy":
		targetObj = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if (not JS.t(targetObj) or not JS.t(targetObj.get("alive"))):
			return
		tStatus = targetObj.status
		targetName = targetObj.name
	else:
		tStatus = State.status.player
		targetName = "you"
	if (not JS.t(tStatus) or not JS.t(tStatus.get("surgeActive"))):
		return
	var surgeValue = JS.or_(tStatus.get("surgeValue"), 0)
	UI.log_("⚡ SURGE TRIGGERS on " + JS.s(targetName) + "! (" + JS.s(surgeValue) + " dmg)", "player")
	# Consume Surge before dealing damage (prevents re-entry)
	tStatus.surgeActive = false
	tStatus.surgeValue = 0
	tStatus.surgeMeter = 0
	# Live Wire: trigger hits all alive enemies, not just the active target
	var hasLiveWire = Main.hasPassive("lightning_live_wire")
	if (hasLiveWire and targetSide == "enemy"):
		var alive = Helpers.aliveEnemies()
		for e in JS.iter(alive):
			State.setActiveEnemy(JS.indexOf(State.combat.enemies, e))
			Hit.applyDirectDamage.call("player", "enemy", surgeValue, "⚡ Surge (Live Wire)")
			if JS.t(State.combat.get("over")):
				continue
		# Restore active enemy
		if not JS.t(State.combat.get("over")):
			State.setActiveEnemy(State.combat.targetIdx)
	else:
		Hit.applyDirectDamage.call("player", targetSide, surgeValue, "⚡ Surge")
	if JS.t(State.combat.get("over")):
		return
	# Galestrike (Air+Lightning duo): triggering Surge costs 5 Momentum
	if (Main.hasPassive("duo_galestrike") and State.playerElement == "Air"):
		var lost = min(5, floori(JS.or_(State.status.player.get("momentumStacks"), 0)))
		if lost > 0:
			State.status.player.momentumStacks = max(0, (JS.or_(State.status.player.get("momentumStacks"), 0)) - lost)
			UI.log_("⚡💨 Galestrike: Surge triggered — −" + JS.s(lost) + " Momentum (×" + JS.toFixed(State.status.player.momentumStacks, 1) + ")", "status")
	# Mark that Surge triggered this turn (for Residual Current)
	State.combat._surgeTriggeredThisTurn = true
	# Overcharged passive: +3 Shock to target on trigger
	if (Main.hasPassive("lightning_overcharged") and targetSide == "enemy"):
		var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if (JS.t(e) and JS.t(e.get("alive"))):
			e.status.shockStacks = (JS.or_(e.status.get("shockStacks"), 0)) + 3
			UI.log_("⚡ Overcharged! +3 Shock (×" + JS.toFixed(e.status.shockStacks, 1) + ")", "status")
	# Cascade: all player CDs −1
	if Main.hasPassive("lightning_cascade"):
		for book in JS.iter(JS.or_(State.player.get("spellbooks"), [])):
			for s in JS.iter(book.spells):
				if (JS.or_(s.get("currentCD"), 0)) > 0:
					s.currentCD -= 1
		if State.combat.basicCD > 0:
			State.combat.basicCD -= 1
		UI.log_("⚡ Cascade! All cooldowns −1", "status")
	# Storm Core: threshold permanently +15 this battle per trigger
	if Main.hasPassive("lightning_storm_core"):
		State.combat._stormCoreBonus = (JS.or_(State.combat.get("_stormCoreBonus"), 0)) + 15
		UI.log_("⚡ Storm Core: threshold now " + JS.s(_getSurgeThreshold()) + " (+15)", "status")
	# Chain Surge: auto-reapply Surge with the same value
	if (Main.hasPassive("lightning_chain_surge") and targetSide == "enemy"):
		var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if (JS.t(e) and JS.t(e.get("alive"))):
			e.status.surgeActive = true
			e.status.surgeValue = surgeValue
			e.status.surgeMeter = 0
			UI.log_("⚡ Chain Surge: Surge " + JS.s(surgeValue) + " re-applied!", "status")
	# ── Duo: Flashfire (Lightning+Fire) — Burn = 25% of surge damage ──
	if (Main.hasPassive("duo_flashfire") and targetSide == "enemy"):
		var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if (JS.t(e) and JS.t(e.get("alive"))):
			var burnAmt = max(1, floori(surgeValue * 0.25))
			e.status.burnStacks = (JS.or_(e.status.get("burnStacks"), 0)) + burnAmt
			UI.log_("⚡🔥 Flashfire! +" + JS.s(burnAmt) + " Burn from Surge", "status")
	# ── Duo: Stormseed (Lightning+Nature) — all Seed timers −1 ──
	if Main.hasPassive("duo_stormseed"):
		var allEnemies = ([JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)] if targetSide == "enemy" else [])
		for e in JS.iter(allEnemies):
			if (not JS.t(e) or not JS.t(e.get("alive"))):
				continue
			for seed_ in JS.iter(JS.or_(e.status.get("seeds"), [])):
				seed_.timer = max(0, seed_.timer - 1)
			UI.log_("⚡🌱 Stormseed! All Seed timers −1", "status")
		# Also tick player seeds if any
		if targetSide == "player":
			for seed_ in JS.iter(JS.or_(State.status.player.get("seeds"), [])):
				seed_.timer = max(0, seed_.timer - 1)
			UI.log_("⚡🌱 Stormseed! All Seed timers −1", "status")
	# Residual Current pending: apply stored surge value to target
	if (JS.t(State.combat.get("_residualCurrentPending")) and targetSide == "enemy"):
		State.combat._residualCurrentPending = false
		var rcVal = JS.or_(State.combat.get("_residualCurrentValue"), 30)
		var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
		if (JS.t(e) and JS.t(e.get("alive"))):
			e.status.surgeActive = true
			e.status.surgeValue = rcVal
			e.status.surgeMeter = 0
			UI.log_("⚡ Residual Current: Surge " + JS.s(rcVal) + " applied!", "status")
	UI.renderStatusTags()

# Called each round in startRound. Handles:
# - Static Build: if Surge active and didn't trigger, +20 to its value
# - Conductivity: each Shock stack on enemy = 2 toward meter
func _tickSurgeBuilds():
	var hasStaticBuild = Main.hasPassive("lightning_static_build")
	var hasConductivity = Main.hasPassive("lightning_conductivity")
	var hasMoltenCurrent = Main.hasPassive("duo_molten_current")
	var hasChargedRoots = Main.hasPassive("duo_charged_roots")
	var _arr1 = JS.iter(State.combat.enemies)
	for i in range(len(_arr1)):
		var e = _arr1[i]
		if not JS.t(e.get("alive")):
			continue
		State.setActiveEnemy(i)
		# Molten Current (Lightning+Fire): Burn stacks count 1 each toward Surge meter
		if (hasMoltenCurrent and JS.t(e.status.get("surgeActive"))):
			var burnContrib = JS.or_(e.status.get("burnStacks"), 0)
			if burnContrib > 0:
				UI.log_("🌊🔥 Molten Current: +" + JS.s(burnContrib) + " Surge meter from " + JS.s(burnContrib) + " Burn", "status")
				_addToSurgeMeter("enemy", burnContrib)
				if JS.t(State.combat.get("over")):
					continue
		# Charged Roots (Lightning+Nature): Root stacks count 3 each toward Surge meter
		if ((not JS.t(State.combat.get("over")) and hasChargedRoots) and JS.t(e.status.get("surgeActive"))):
			var rootContrib = (JS.or_(e.status.get("rootStacks"), 0)) * 3
			if rootContrib > 0:
				UI.log_("⚡🌿 Charged Roots: +" + JS.s(rootContrib) + " Surge meter from " + JS.s(e.status.rootStacks) + " Root", "status")
				_addToSurgeMeter("enemy", rootContrib)
				if JS.t(State.combat.get("over")):
					continue
		if not JS.t(e.status.get("surgeActive")):
			continue
		# may have triggered above
		# Conductivity: Shock stacks count as 2 dmg each toward meter
		if hasConductivity:
			var shockContrib = (JS.or_(e.status.get("shockStacks"), 0)) * 2
			if shockContrib > 0:
				UI.log_("⚡ Conductivity: +" + JS.s(shockContrib) + " Surge meter from " + JS.s(JS.round(e.status.shockStacks)) + " Shock", "status")
				_addToSurgeMeter("enemy", shockContrib)
				if JS.t(State.combat.get("over")):
					continue
		# Static Build: +20 surge value per turn it didn't trigger
		if ((not JS.t(State.combat.get("over")) and JS.t(e.status.get("surgeActive"))) and hasStaticBuild):
			e.status.surgeValue = (JS.or_(e.status.get("surgeValue"), 0)) + 20
			UI.log_("⚡ Static Build: Surge value → " + JS.s(e.status.surgeValue), "status")
	# Restore active enemy
	if not JS.t(State.combat.get("over")):
		State.setActiveEnemy(State.combat.targetIdx)
