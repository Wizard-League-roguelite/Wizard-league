# Helpers — generated from js/logic/helpers.js by tools/js2gd.js
extends Node


func _boot():
	pass

# ===== helpers.js =====
# ─── HELPERS ─────────────────────────────────────────────────────────────────
# Pure utility functions and formulas. No DOM access.
func ceilDiv(a = null, b = null):
	return ceili(a / float(b))

func clamp_(n = null, min_ = null, max_ = null):
	return max(min_, min(max_, n))

func primaryElement(label = null):
	if not JS.t(label):
		return ""
	return JS.idx(JS.split(label, JS.re("[\\/ ]", "")), 0).strip_edges()

func elementOfSide(side = null):
	if side == "player":
		return State.playerElement
	var e = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
	return (primaryElement(JS.or_(e.get("element"), "")) if JS.t(e) else "")

func maxHPFor(side = null):
	if side != "player":
		return 999
	# enemies use their own maxHP field
	var base = Constants.BASE_MAX_HP + (JS.or_(State.player.get("baseMaxHPBonus"), 0))
	return (floori(base * 0.5) if State.playerElement == "Water" else base)

func healingMultiplier():
	var mult = (1.5 if Main.hasPassive("water_restoration") else 1.0)
	if State.combat.get("activeZoneElement") == "Plasma":
		mult *= 1.25
	if JS.t(State.player.get("_healBonus")):
		mult += State.player.get("_healBonus")
	return mult

func applyHeal(side = null, amount = null, label = null):
	# Defense scales heal amount: +0.5 HP per Defense point
	var defBonus = (floori(defenseFor("player") * 0.5) if side == "player" else 0)
	var baseMult = (healingMultiplier() if side == "player" else 1.0)
	var actual = JS.round((amount + defBonus) * baseMult)
	if side == "player":
		var mx = maxHPFor("player")
		var before = State.player.get("hp")
		State.player.hp = min(mx, State.player.get("hp") + actual)
		var got = State.player.get("hp") - before
		if (got > 0 and JS.t(label)):
			UI.log_(JS.s(label) + ": +" + JS.s(got) + " HP (" + JS.s(State.player.get("hp")) + "/" + JS.s(mx) + ")", "heal")
		if got > 0:
			Animations.triggerHealAnim()
		return got
	return 0

func _enemyStat(key = null):
	var e = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
	if (JS.t(e) and JS.idx(e, key) != null):
		return JS.idx(e, key)
	# legacy fallback for old saves / dummies
	if (JS.t(e) and e.get("scaledPower") != null):
		return e.get("scaledPower")
	return max(1, State.battleNumber)

func enemyScaledStat():
	return _enemyStat("statPow")

# legacy alias
# ── Three player stat accessors ───────────────────────────────────────────────
# Attack Power: scales raw hit damage
func attackPowerFor(side = null, targetSide = null):
	var pow_ = (State.player.get("attackPower") if side == "player" else _enemyStat("statPow"))
	var s = (State.status.get("player") if side == "player" else (JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx")) if JS.t(JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))) else {"status": {}}).get("status"))
	# Stone: +3 AP/stack (doubled by Stone Stance)
	var sm = (2 if JS.t(s.get("stoneStanceThisTurn")) else 1)
	pow_ += (floori(JS.or_(s.get("stoneStacks"), 0)) * 3) * sm
	# Frost on self: -1 AP/stack
	pow_ -= floori(JS.or_(s.get("frostStacks"), 0))
	# Root bonus vs rooted targets — scales with attacker's EFX (+1 per 10 EFX)
	if JS.t(targetSide):
		var ts = (State.status.get("player") if targetSide == "player" else (JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx")) if JS.t(JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))) else {"status": {}}).get("status"))
		var totalRoots = (JS.or_(ts.get("rootStacks"), 0)) + (JS.or_(ts.get("overgrowthStacks"), 0))
		if totalRoots > 0:
			var efxBonus = floori(effectPowerFor(side) / 10.0)
			var baseBonus = Constants.ROOT_POWER_PER_STACK + efxBonus
			var bonus = (baseBonus * 2 if Main.hasPassive("nature_thorned_strikes") else baseBonus)
			pow_ += bonus * totalRoots
	# Blazing Heat (Fire): +totalEnemyBurn/2 AP
	if (side == "player" and Main.hasPassive("fire_blazing_heat")):
		pow_ += floori(totalEnemyBurnStacks() / 2.0)
	# Fire Rage temp power
	if s.get("rageBoostTurns") > 0:
		pow_ += s.get("rageBoostPow")
	# Overcharge/Feedback 1-turn bonus
	pow_ += JS.or_(s.get("nextTurnPowerBonus"), 0)
	# War Cry / battle-scoped bonuses
	pow_ += JS.or_(s.get("battlePowerBonus"), 0)
	# Plasma Energy Feedback: +1 AP per current Charge
	if (side == "player" and Main.hasPassive("plasma_energy_feedback")):
		pow_ += JS.or_(State.status.get("player").get("plasmaCharge"), 0)
	# Air Momentum: +0.8 AP per Momentum stack
	if (side == "player" and State.playerElement == "Air"):
		pow_ += floori((JS.or_(State.status.get("player").get("momentumStacks"), 0)) * 0.8)
	# Enemy AP reduced by player's Defense
	if side == "enemy":
		pow_ -= defenseFor("player")
	# Mutual book aura (Soul Codex etc.) — enemy shares ATK aura
	if side == "enemy":
		pow_ += (JS.or_(State.player.get("_mutualEnemyAura").get("atk"), 0) if JS.t(State.player.get("_mutualEnemyAura")) else 0)
	return max(0, pow_)

# Effect Power: scales status potency (burn stacks, frost, root, shock)
func effectPowerFor(side = null):
	var pow_ = (State.player.get("effectPower") if side == "player" else _enemyStat("statEfx"))
	var s = (State.status.get("player") if side == "player" else (JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx")) if JS.t(JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))) else {"status": {}}).get("status"))
	# Frost on self: -1 EP/stack
	pow_ -= floori(JS.or_(s.get("frostStacks"), 0))
	# Battle-scoped EFX bonus (from EFX Crystal consumable)
	if side == "player":
		pow_ += JS.or_(s.get("battleEfxBonus"), 0)
	# Enemy EFX reduced by player's Defense
	if side == "enemy":
		pow_ -= defenseFor("player")
	# Mutual book aura — enemy shares EFX aura
	if side == "enemy":
		pow_ += (JS.or_(State.player.get("_mutualEnemyAura").get("efx"), 0) if JS.t(State.player.get("_mutualEnemyAura")) else 0)
	return max(0, pow_)

# Defense: scales armor gained, heal amounts, reduces enemy AP and EFX.
# Foam reduces Defense — negative Defense means enemies deal bonus damage per hit.
func defenseFor(side = null):
	var def = (State.player.get("defense") if side == "player" else _enemyStat("statDef"))
	var s = (State.status.get("player") if side == "player" else (JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx")) if JS.t(JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))) else {"status": {}}).get("status"))
	# Frost weakens defense too
	def -= floori((JS.or_(s.get("frostStacks"), 0)) * 0.5)
	# Foam: reduces Defense (can go negative — negative def means bonus enemy ATK/EFX)
	def -= floori((JS.or_(s.get("foamStacks"), 0)) * 1.5)
	# Battle-scoped DEF bonus (from Defense Crystal consumable)
	if side == "player":
		def += JS.or_(s.get("battleDefBonus"), 0)
	# Mutual book aura — enemy shares DEF aura
	if side == "enemy":
		def += (JS.or_(State.player.get("_mutualEnemyAura").get("def"), 0) if JS.t(State.player.get("_mutualEnemyAura")) else 0)
	return def

# Legacy: enemies use scaledPower as a single composite stat
func enemyPower():
	return enemyScaledStat()

func burnDmgPerStack(side = null, sourceEFX = null):
	var legendary = ((side == "player" and Main.hasPassive("fire_roaring_heat")) or (side == "enemy" and Main.enemyHasPassive("fire_roaring_heat")))
	# _talentBurnDmg: flat bonus burn damage/stack when enemy is burning (player applied it)
	var talentBonus = (JS.or_(State.player.get("_talentBurnDmg"), 0) if side == "enemy" else 0)
	var base = (1.5 if legendary else 1.0)
	return (base + ((JS.or_(sourceEFX, 0)) / 100.0)) + talentBonus

func totalEnemyBurnStacks():
	if JS.hooks.has("totalEnemyBurnStacks"):
		return JS.run_hook("totalEnemyBurnStacks", [])
	return JS.reduce(State.combat.get("enemies"), func(s = null, e = null): return s + (JS.or_(e.get("status").get("burnStacks"), 0) if JS.t(e.get("alive")) else 0), 0)

# ── Effective armor (block + Stone bonuses – Foam – Frost) ───────────────────
func effectiveArmor(side = null):
	var s = JS.idx(State.status, side)
	var armor = JS.or_(s.get("block"), 0)
	var sm = (2 if JS.t(s.get("stoneStanceThisTurn")) else 1)
	armor += (floori(JS.or_(s.get("stoneStacks"), 0)) * 2) * sm
	# Stone: +2 block/stack
	armor -= floori(JS.or_(s.get("frostStacks"), 0))
	# Frost: -1 armor/stack
	return armor

# ── Power computation ────────────────────────────────────────────────────────
func powerFor(side = null, targetSide = null):
	var pow_ = (State.player.get("attackPower") if side == "player" else enemyPower())
	var s = JS.idx(State.status, side)
	# Stone: +3 power/stack (doubled by Stone Stance)
	var sm = (2 if JS.t(s.get("stoneStanceThisTurn")) else 1)
	pow_ += (floori(JS.or_(s.get("stoneStacks"), 0)) * 3) * sm
	# Frost on self: -1 power/stack
	pow_ -= floori(JS.or_(s.get("frostStacks"), 0))
	# Root bonus vs rooted targets (Thorned Strikes or base)
	if JS.t(targetSide):
		var ts = JS.idx(State.status, targetSide)
		var totalRoots = (JS.or_(ts.get("rootStacks"), 0)) + (JS.or_(ts.get("overgrowthStacks"), 0))
		if totalRoots > 0:
			var efxBonus = floori(effectPowerFor(side) / 10.0)
			var baseBonus = Constants.ROOT_POWER_PER_STACK + efxBonus
			var bonus = (baseBonus * 2 if Main.hasPassive("nature_thorned_strikes") else baseBonus)
			pow_ += bonus * totalRoots
	# Blazing Heat (Fire passive): +total enemy burn / 2
	if (side == "player" and Main.hasPassive("fire_blazing_heat")):
		pow_ += floori(totalEnemyBurnStacks() / 2.0)
	# Fire Rage temp power (2-turn window)
	if s.get("rageBoostTurns") > 0:
		pow_ += s.get("rageBoostPow")
	# Overcharge/Feedback: 1-turn bonus (set at round start, cleared next round start)
	pow_ += JS.or_(s.get("nextTurnPowerBonus"), 0)
	# War Cry etc: battle-scoped bonus (resets at resetStatusForBattle)
	pow_ += JS.or_(s.get("battlePowerBonus"), 0)
	return max(0, pow_)

# ── Armor reduction (Hard Shell / earth_hard_shell) ──────────────────────────
func armorReductionFor(side = null):
	var el = elementOfSide(side)
	# Hard Shell (Earth passive): flat 10 reduction
	if (el == "Earth" and ((side == "player" and Main.hasPassive("earth_hard_shell")) or (side == "enemy" and Main.enemyHasPassive("earth_hard_shell")))):
		return 10
	return 0

# ── Fissure check (Earth pierce) ─────────────────────────────────────────────
func isEarthFissure(attackerSide = null, pkg = null):
	return (pkg.get("abilityElement") == "Earth" and ((attackerSide == "player" and Main.hasPassive("earth_fissure")) or (attackerSide == "enemy" and Main.enemyHasPassive("earth_fissure"))))

# ── Dodge / Phase ─────────────────────────────────────────────────────────────
func dodgeChanceFor(side = null):
	if JS.idx(State.status, side).get("phaseTurns") > 0:
		return 1
	# Air: Momentum grants +2% dodge per stack (cap 80%)
	if (side == "player" and State.playerElement == "Air"):
		return min(0.8, floori(JS.or_(State.status.get("player").get("momentumStacks"), 0)) * 0.02)
	# Plasma Ghost Step talent: flat base dodge chance
	if side == "player":
		return min(0.5, JS.or_(State.player.get("_talentDodgeBonus"), 0))
	return 0

# ── Cooldowns ─────────────────────────────────────────────────────────────────
func adjustedCooldownFor(side = null, baseCd = null):
	var cd = baseCd
	if elementOfSide(side) == "Ice":
		cd = max(0, cd - 1)
	# Ice baseline -1 CD
	return max(0, cd)

func enemyCooldownPenaltyFor(enemyIdx = null):
	if not Main.hasPassive("ice_cold_swell"):
		return 0
	var e = JS.idx(State.combat.get("enemies"), enemyIdx)
	return (1 if ((JS.t(e) and JS.t(e.get("status"))) and (JS.or_(e.get("status").get("frostStacks"), 0)) > 0) else 0)

# legacy compat
func enemyCooldownPenalty():
	return (1 if Main.hasPassive("ice_cold_swell") else 0)

# ── Actions per turn ─────────────────────────────────────────────────────────
func actionsPerTurnFor(side = null):
	var actions = Constants.BASE_ACTIONS_PER_TURN
	# Shop-purchased bonus actions (player only, cooldown-limited)
	if side == "player":
		actions += JS.or_(State.player.get("bonusActions"), 0)
	# Rapid Tempo passive: alternate +1 action every other turn
	if elementOfSide(side) == "Air":
		var hasRapidTempo = ((side == "player" and Main.hasPassive("air_rapid_tempo")) or (side == "enemy" and Main.enemyHasPassive("air_rapid_tempo")))
		if hasRapidTempo:
			if side == "player":
				State.combat.playerAirToggle = (not JS.t(State.combat.get("playerAirToggle")))
				if JS.t(State.combat.get("playerAirToggle")):
					actions += 1
			else:
				State.combat.enemyAirToggle = (not JS.t(State.combat.get("enemyAirToggle")))
				if JS.t(State.combat.get("enemyAirToggle")):
					actions += 1
	return actions

# ── Misc ──────────────────────────────────────────────────────────────────────
func aliveEnemies():
	if JS.hooks.has("aliveEnemies"):
		return JS.run_hook("aliveEnemies", [])
	return JS.arr(State.combat.get("enemies")).filter(func(e = null): return JS.t(e.get("alive")))

func firstAliveIdx():
	var i = JS.findIndex(State.combat.get("enemies"), func(e = null): return JS.t(e.get("alive")))
	return (i if i >= 0 else 0)

func gymBossHP():
	var g = Encounters.currentGymDef()
	return (g.get("baseHP") + (State.gymSkips * Constants.GYM_SKIP_BONUS) if JS.t(g) else 300)

# Actual in-battle HP (mirrors makeEnemyObj scaling: zone mult + bn ramp + 0.77 global)
func gymBossDisplayHP():
	var g = Encounters.currentGymDef()
	if not JS.t(g):
		return 300
	var rawHP = g.get("baseHP") + (State.gymSkips * Constants.GYM_SKIP_BONUS)
	var zoneHP = JS.round(rawHP * (1 + (State.currentGymIdx * 0.336)))
	var _bnRaw = (State.battleNumber - 6 if State.battleNumber > 6 else 0)
	var _bnFlat = ((State.battleNumber - 3) * 13 if State.battleNumber > 3 else 0)
	var _bnBase = (1.2 if State.battleNumber > 3 else 1.0)
	var _bnMult = _bnBase + ((_bnRaw * 0.09) + pow(_bnRaw / 12.0, 2) if _bnRaw > 0 else 0)
	return JS.round(((zoneHP * _bnMult) + _bnFlat) * 0.77)

# Actual in-battle phase-1 dmg (zone scaled + 0.80 mult - 5 flat)
func gymBossDisplayDmg():
	var g = Encounters.currentGymDef()
	if not JS.t(g):
		return 30
	return max(1, JS.round(JS.round(g.get("baseDmg") * (1 + (State.currentGymIdx * 0.22))) * 0.8) - 5)

# Gym card shows up as an option once the zone has run 7 battles
func gymShouldAppear():
	if JS.t(State.gymDefeated):
		return false
	if not JS.t(Encounters.currentGymDef()):
		return false
	return State.zoneBattleCount >= Constants.GYM_ZONE_OPEN

# Gym is forced at 12 zone battles — no more choice
func gymIsForced():
	return State.zoneBattleCount >= Constants.GYM_ZONE_FORCE

func advanceToNextGym():
	State.currentGymIdx += 1
	State.zoneBattleCount = 0
	State.gymSkips = 0
	State._zoneRivalDefeated = false
	State._zoneGraph = null
	State._playerNodeId = -1
	State._completedNodeIds = JSSet.new()
	State._pendingNodeId = -1
	State._zoneIntroPlayed = false
	if State.currentGymIdx >= len(Encounters.GYM_ROSTER):
		State.gymDefeated = true
	# Each zone block is 15 battles wide (B1-15, B16-30, B31-45…).
	# Jump battleNumber to the new zone's start so fighting the gym early
	# (B12) still lands at the same next-zone start (B16) as fighting it late (B15).
	State.battleNumber = (State.currentGymIdx * 15) + 1
	MapCanvas.initZoneSpecial()

# ── Status application helpers ────────────────────────────────────────────────
func applyBurn(defenderSide = null, stacks = null, sourcePow = null):
	var s = JS.idx(State.status, defenderSide)
	s.burnStacks = (JS.or_(s.get("burnStacks"), 0)) + stacks
	if sourcePow != null:
		s.burnSourcePower = sourcePow
	UI.log_("🔥 Burn +" + JS.s(stacks) + " (×" + JS.s(s.get("burnStacks")) + ")", "status")

func applyFoam(attackerSide = null, defenderSide = null, stacks = null):
	var efx = effectPowerFor(attackerSide)
	var scaledStacks = stacks * (1 + (efx / 50.0))
	var s = JS.idx(State.status, defenderSide)
	s.foamStacks = (JS.or_(s.get("foamStacks"), 0)) + scaledStacks
	UI.log_("🫧 Foam +" + JS.toFixed(scaledStacks, 1) + " (×" + JS.toFixed(s.get("foamStacks"), 1) + ")", "status")
	Hit._plasmaChargeOnDebuff(defenderSide)

func applyFrost(attackerSide = null, defenderSide = null, stacks = null):
	if (attackerSide == "player" and Main.hasPassive("ice_stay_frosty")):
		stacks += 1
	if attackerSide == "player":
		stacks += JS.or_(State.player.get("_talentFrostBonus"), 0)
	var efx = effectPowerFor(attackerSide)
	var scaledStacks = stacks * (1 + (efx / 50.0))
	var s = JS.idx(State.status, defenderSide)
	s.frostStacks = (JS.or_(s.get("frostStacks"), 0)) + scaledStacks
	UI.log_("❄️ Frost +" + JS.toFixed(scaledStacks, 1) + " (×" + JS.toFixed(s.get("frostStacks"), 1) + ")", "status")
	if (s.get("frostStacks") >= 10 and not JS.t(s.get("frozen"))):
		s.frozen = true
		s.nextTurnActionPenalty = (JS.or_(s.get("nextTurnActionPenalty"), 0)) + 1
		UI.log_("🧊 FROZEN! −1 action next turn. Next Ice hit deals 1.5× and consumes 10 stacks.", "status")

func applyRoot(attackerSide = null, defenderSide = null, stacks = null):
	var total = stacks
	if (attackerSide == "player" and Main.hasPassive("nature_stay_rooted")):
		total += 1
	if attackerSide == "player":
		total += JS.or_(State.player.get("_talentRootBonus"), 0)
	JS.idx(State.status, defenderSide).rootStacks = (JS.or_(JS.idx(State.status, defenderSide).get("rootStacks"), 0)) + total
	UI.log_("🌿 Root +" + JS.s(total) + " (×" + JS.s(JS.idx(State.status, defenderSide).get("rootStacks")) + ")", "status")
	Hit._plasmaChargeOnDebuff(defenderSide)
	# Deep Roots: every 3rd Root applied to an enemy reduces Seed timers by 1
	if (attackerSide == "player" and defenderSide == "enemy"):
		Seeds._deepRootsCheck()

func addStoneStacks(side = null, stacks = null):
	var efx = effectPowerFor(side)
	var scaled = stacks * (1 + (efx / 50.0))
	JS.idx(State.status, side).stoneStacks = (JS.or_(JS.idx(State.status, side).get("stoneStacks"), 0)) + scaled
	UI.log_("🪨 Stone +" + JS.toFixed(scaled, 1) + " (×" + JS.toFixed(JS.idx(State.status, side).get("stoneStacks"), 1) + ")", "status")

func addMomentumStacks(stacks = null):
	var efx = effectPowerFor("player")
	var scaled = stacks * (1 + (efx / 50.0))
	State.status.get("player").momentumStacks = (JS.or_(State.status.get("player").get("momentumStacks"), 0)) + scaled
	UI.log_("💨 Momentum +" + JS.toFixed(scaled, 1) + " (×" + JS.toFixed(State.status.get("player").get("momentumStacks"), 1) + ")", "status")
	# Gale Root (Air+Nature duo): each raw stack has 20% chance to apply 1 Root to active enemy
	if ((Main.hasPassive("duo_gale_root") and State.playerElement == "Air") and not JS.t(State.combat.get("over"))):
		var e = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
		if (JS.t(e) and JS.t(e.get("alive"))):
			var rootApplied = 0
			for i in range(ceili(stacks)):
				if JS.random() < 0.2:
					rootApplied += 1
			if rootApplied > 0:
				applyRoot("player", "enemy", rootApplied)
	# Rushing Growth (Air+Nature duo): every 10 raw stacks gained reduces a random Seed timer by 1
	if (Main.hasPassive("duo_rushing_growth") and State.playerElement == "Air"):
		State.combat._momentumSeedProgress = (JS.or_(State.combat.get("_momentumSeedProgress"), 0)) + stacks
		while JS.un(State.combat.get("_momentumSeedProgress")) >= 10:
			State.combat._momentumSeedProgress -= 10
			# Collect all active seeds across all alive enemies and the player
			var allSeeds = []
			for e in JS.iter(State.combat.get("enemies")):
				if JS.t(e.get("alive")):
					for s in JS.iter(JS.or_(e.get("status").get("seeds"), [])):
						allSeeds.append(s)
			for s in JS.iter(JS.or_(State.status.get("player").get("seeds"), [])):
				allSeeds.append(s)
			if len(allSeeds) > 0:
				var pick = JS.idx(allSeeds, floori(JS.random() * len(allSeeds)))
				pick.timer = max(1, pick.get("timer") - 1)
				UI.log_("🌱💨 Rushing Growth: Seed timer −1 (" + JS.s(pick.get("timer")) + " remaining).", "status")

func gainBlock(side = null, amount = null):
	if amount <= 0:
		return
	# Defense scales armor gained: +2 per Defense point. Foam-reduced Defense gives less armor.
	var defBonus = (floori(defenseFor("player") * 2) if side == "player" else 0)
	var total = max(0, amount + defBonus)
	JS.idx(State.status, side).block = (JS.or_(JS.idx(State.status, side).get("block"), 0)) + total
	if defBonus > 0:
		UI.log_("🛡️ +" + JS.s(total) + " Armor (" + JS.s(amount) + " base + " + JS.s(defBonus) + " from Defense)", "status")
	if side == "player":
		Animations.triggerBlockAnim("armor")
	# Bedrock: gain 1 stone per armor gain
	if (side == "player" and Main.hasPassive("earth_bedrock")):
		addStoneStacks("player", 1)
	# Bramble Guard: apply 1 root to all enemies on armor gain
	if (side == "player" and Main.hasPassive("nature_bramble_guard")):
		for e in JS.iter(aliveEnemies()):
			var idx = JS.indexOf(State.combat.get("enemies"), e)
			State.setActiveEnemy(idx)
			applyRoot("player", "enemy", 1)
		if JS.t(JS.idx(State.combat.get("enemies"), State.combat.get("targetIdx"))):
			State.setActiveEnemy(State.combat.get("targetIdx"))

func applySelfDamage(amount = null, label = null):
	if Main.hasPassive("lightning_superconductor"):
		var tripled = amount * 3
		UI.log_("🔋 Superconductor redirects " + JS.s(label) + " — " + JS.s(tripled) + " dmg to enemy!", "status")
		Hit.applyDirectDamage("player", "enemy", tripled, "🔋 " + JS.s(label))
	else:
		State.player.hp = max(0, State.player.get("hp") - amount)
		UI.log_(JS.s(label) + ": " + JS.s(amount) + " self damage. (" + JS.s(State.player.get("hp")) + "/" + JS.s(maxHPFor("player")) + ")", "player")
		UI.updateHPBars()
		if (State.player.get("hp") <= 0 and not JS.t(State.combat.get("over"))):
			Combat.endBattle(false)

func applyFlowToWaterPkg(pkg = null):
	if ((not Main.hasPassive("water_flow") or pkg.get("abilityElement") != "Water") or not (pkg.get("baseDamage") > 0)):
		return pkg
	return JS.merge([pkg, {"baseDamage": ceili((JS.or_(pkg.get("baseDamage"), 0)) / 2.0), "hits": (JS.or_(pkg.get("hits"), 1)) * 2}])

# Count removable debuffs on player (for Cleanse Current / Static Cleanse)
func countPlayerDebuffs():
	var p = State.status.get("player")
	var n = 0
	if p.get("burnStacks") > 0:
		n += 1
	if p.get("frostStacks") > 0:
		n += 1
	if p.get("stunned") > 0:
		n += 1
	if p.get("rootStacks") > 0:
		n += 1
	if p.get("shockStacks") > 0:
		n += 1
	if p.get("foamStacks") > 0:
		n += 1
	return n

func clearPlayerDebuffs():
	var p = State.status.get("player")
	p.burnStacks = 0
	p.frostStacks = 0
	p.frozen = false
	p.stunned = 0
	p.rootStacks = 0
	p.shockStacks = 0
	p.foamStacks = 0

# Count removable buffs on player (block, stone — for Static Cleanse)
func countPlayerBuffs():
	var p = State.status.get("player")
	var n = 0
	if p.get("block") > 0:
		n += 1
	if p.get("stoneStacks") > 0:
		n += 1
	if p.get("firewallStacks") > 0:
		n += 1
	return n

func clearPlayerBuffs():
	var p = State.status.get("player")
	p.block = 0
	p.stoneStacks = 0
	p.firewallStacks = 0

# Reset status at battle start
func resetStatusForBattle():
	# Spread fresh defaults, preserving nothing from last battle
	JS.assign(State.status.get("player"), [{
		"burnStacks": 0,
		"burnSourcePower": Constants.BASE_POWER,
		"stunned": 0,
		"rootStacks": 0,
		"overgrowthStacks": 0,
		"foamStacks": 0,
		"shockStacks": 0,
		"frostStacks": 0,
		"frozen": false,
		"frozenIceHitPending": false,
		"block": 0,
		"stoneStacks": 0,
		"stoneStanceThisTurn": false,
		"firewallStacks": 0,
		"phaseTurns": 0,
		"lightningMult": 2.0,
		"greasefirePending": false,
		"tidalShieldActive": false,
		"deepCurrentActive": false,
		"cryostasisActive": false,
		"frozenGroundTurns": 0,
		"spreadingVinesTurns": 0,
		"debuffImmune": 0,
		"overchargePowerPending": 0,
		"chargeShotCharging": false,
		"rageBoostPow": 0,
		"rageBoostTurns": 0,
		"nextTurnPowerBonus": 0,
		"battlePowerBonus": 0,
		"battleEfxBonus": 0,
		"battleDefBonus": 0,
		"fortifyPending": 0,
		"plasmaCharge": 3,
		"plasmaChargeHalf": 0,
		"plasmaShieldReduction": 0,
		"borrowedCharge": 0,
		"stallCharge": 0,
		"stallActive": false,
		"singularityActive": false,
		"momentumStacks": 0,
		"momentumNoDecayNext": false,
		"windWallActive": false,
		"windWallPending": 0,
		"tornadoAoENext": false,
		"nextTurnBonusActions": 0,
		"seeds": [],
		"_silencedBookIdx": -1,
		"_silenceTurns": 0,
		"surgeActive": false,
		"surgeValue": 0,
		"surgeMeter": 0,
	}])
	# Plasma
	# Air / Momentum
	# Seeds
	# Surge
	if Main.hasPassive("lightning_overload"):
		State.status.get("player").lightningMult = 2.0

# Compat alias — old combat.js code used burnValueFor(power).
# New design: burn is 1 dmg/stack flat (or 1.5 with Roaring Heat).
# This shim lets any leftover calls degrade gracefully.
func burnValueFor():
	return 1

func hasPassive__superseded_Helpers(id = null):
	return JS.includes(JS.or_(State.player.get("passives"), []), id)

func enemyHasPassive__superseded_Helpers(id = null):
	var e = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
	if not JS.t(e):
		return false
	return (JS.eq(e.get("passive"), id) or JS.includes(JS.or_(e.get("extraPassives"), []), id))

func pickRandom__superseded_Helpers(arr = null, n = null):
	var copy = JS.arr(arr)
	var result = []
	while (len(result) < n and len(copy) > 0):
		var i = floori(JS.random() * len(copy))
		result.append(JS.idx(JS.splice(copy, i, 1), 0))
	return result

func armorBlockAmount():
	# Armor button: base 10 + Defense
	return 10 + defenseFor("player")

# ── Enemy elemental effects per basic attack ──────────────────────────────────
# Returns effects[] to pass into performHit for enemy basic attacks.
# Burn/Stun live in effects[]. Frost/Root/Shock/Foam are handled in applyEnemyElementalProc.
func enemyElementalEffects(element = null):
	match element:
		"Fire":
			return [{"type": "burn", "stacks": 3}]
		"Water":
			return []
		"Ice":
			# Foam applied via proc
			return []
		"Lightning":
			# Frost applied via proc
			return []
		"Earth":
			# Shock applied via Lightning pipeline in hit.js
			return []
		"Nature":
			# Stone/armor handled in proc
			return []
		"Plasma":
			# Root proc handled in hit.js elementOfSide check
			return []
		"Air":
			# Dodge via passive
			return []
		_:
			# No status effect — just hits
			return []

# Secondary elemental procs that need applyFrost / direct status manipulation
func applyEnemyElementalProc(element = null, enemyIdx = null):
	if JS.t(State.combat.get("over")):
		return
	match element:
		"Ice":
			applyFrost("enemy", "player", 2)
			UI.renderStatusTags()
		"Water":
			# Baseline foam: 1 stack per hit regardless of passive
			applyFoam("enemy", "player", 1)
			UI.renderStatusTags()
		"Earth":
			# Reduce player block by 5 (armor crack)
			if State.status.get("player").get("block") > 0:
				var crack = min(5, State.status.get("player").get("block"))
				State.status.get("player").block -= crack
				UI.log_("🪨 Earth crack — your Armor reduced by " + JS.s(crack), "status")
				UI.renderStatusTags()
		"Lightning":
			pass
		_:
			pass
