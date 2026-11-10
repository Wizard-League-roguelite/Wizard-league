# Hit — generated from js/logic/hit.js by tools/js2gd.js
extends Node

var applyDirectDamage = null
var applyMelt = null

func _boot():
	applyDirectDamage = applyDirectDamage_2
	# ─── MELT DAMAGE ─────────────────────────────────────────────────────────────
	# Melt is a Fire damage type that hits armor at 3:1 efficiency (ceil(armor/3) points
	# to destroy all armor), then remaining points deal direct HP damage at 1:1.
	# Bypasses shock damage reduction and all shield effects — armor still applies normally.
	applyMelt = applyMelt_2

# ===== hit.js =====
# ─── DAMAGE PIPELINE ─────────────────────────────────────────────────────────
func _elemTalentDmgMult(element = null):
	match element:
		"Fire":
			return JS.or_(State.player.get("_talentFireDmgMult"), 1.0)
		"Water":
			return JS.or_(State.player.get("_talentWaterDmgMult"), 1.0)
		"Ice":
			return JS.or_(State.player.get("_talentIceDmgMult"), 1.0)
		"Lightning":
			return JS.or_(State.player.get("_talentLightDmgMult"), 1.0)
		"Earth":
			return JS.or_(State.player.get("_talentEarthDmgMult"), 1.0)
		"Nature":
			return JS.or_(State.player.get("_talentNatureDmgMult"), 1.0)
		"Plasma":
			return JS.or_(State.player.get("_talentPlasmaDmgMult"), 1.0)
		"Air":
			return JS.or_(State.player.get("_talentAirDmgMult"), 1.0)
		_:
			return 1.0

func makeSpellCtx(attackerSide = null, defenderSide = null, spellIdx = null):
	if spellIdx == null:
		spellIdx = -1
	var temp = {"deltaPower": 0}
	var _fn1 = func(dp = null):
		# Three stat accessors
		# Legacy compat — defaults to attackPower
		temp.deltaPower += dp
	var _fn2 = func(amount = null):
		if attackerSide != "player":
			return
		Helpers.applyHeal("player", amount, "💠 Heal")
	var _fn3 = func(pkg = null):
		var adj = JS.merge([pkg])
		if (attackerSide == "player" and (JS.typeof_(adj.get("baseDamage"))) == "number"):
			var spell = JS.idx(State.player.get("spellbook"), spellIdx)
			var mult = (JS.or_(spell.get("dmgMult"), 1.0) if JS.t(spell) else 1.0)
			var elemMult = _elemTalentDmgMult(JS.or_((adj.get("abilityElement") if JS.t(adj.get("abilityElement")) else (spell.get("element") if JS.t(spell) else "")), ""))
			adj.baseDamage = JS.round((adj.get("baseDamage") * mult) * elemMult)
			if (JS.t(spell) and not JS.t(adj.get("label"))):
				adj.label = (JS.or_(spell.get("emoji"), "")) + " " + JS.s(spell.get("name"))
			# Air multi-hit talent: extra hits on multi-hit Air spells
			if ((adj.get("abilityElement") == "Air" or (JS.t(spell) and spell.get("element") == "Air")) and (JS.or_(adj.get("hits"), 1)) > 1):
				adj.hits = (JS.or_(adj.get("hits"), 1)) + (JS.or_(State.player.get("_talentAirHits"), 0))
		if not JS.t(adj.get("abilityElement")):
			adj.abilityElement = Helpers.elementOfSide(attackerSide)
		performHit(attackerSide, defenderSide, adj)
	return {
		"attackerSide": attackerSide,
		"defenderSide": defenderSide,
		"log": UI.log_,
		"attackPow": func(): return max(0, Helpers.attackPowerFor(attackerSide, defenderSide) + temp.get("deltaPower")),
		"effectPow": func(): return max(0, Helpers.effectPowerFor(attackerSide)),
		"defStat": func(): return max(0, Helpers.defenseFor(attackerSide)),
		"effectivePower": func(): return max(0, Helpers.attackPowerFor(attackerSide, defenderSide) + temp.get("deltaPower")),
		"pushTempPower": _fn1,
		"healSelf": _fn2,
		"hit": _fn3,
	}

func applyOutgoingDamageMods(attackerSide = null, defenderSide = null, baseDamage = null, meta = null):
	var dmg = max(0, JS.round(baseDamage))
	# _noAtk: caller already baked power in (e.g. Plasma spells) — skip adding it again
	if (not JS.t(meta) or not JS.t(meta.get("_noAtk"))):
		var pow_ = Helpers.attackPowerFor(attackerSide, defenderSide)
		var apMult = (meta.get("apMult") if (JS.t(meta) and meta.get("apMult") != null) else 1)
		if dmg > 0:
			dmg += JS.round(pow_ * apMult)
		# Plasma: Effect Power also adds to damage (EFX = ATK for Plasma)
		if (dmg > 0 and Helpers.elementOfSide(attackerSide) == "Plasma"):
			dmg += Helpers.effectPowerFor(attackerSide)
	# Zone environment bonus: enemies whose element matches the active zone deal +20% damage
	if ((attackerSide == "enemy" and JS.t(State.combat.get("activeZoneElement"))) and dmg > 0):
		var e = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
		if (JS.t(e) and Helpers.primaryElement(JS.or_(e.get("element"), "")) == State.combat.get("activeZoneElement")):
			dmg = JS.round(dmg * 1.2)
	# Lightning Overload multiplier
	if Helpers.elementOfSide(attackerSide) == "Lightning":
		var hasOverload = ((attackerSide == "player" and Main.hasPassive("lightning_overload")) or (attackerSide == "enemy" and Main.enemyHasPassive("lightning_overload")))
		if hasOverload:
			var overloadFloor = (max(0.25, JS.or_(State.player.get("_talentOverloadFloor"), 0.25)) if attackerSide == "player" else 0.25)
			var mult = Helpers.clamp_(JS.idx(State.status, attackerSide).get("lightningMult"), overloadFloor, 10)
			dmg = JS.round(dmg * mult)
			if (JS.t(meta) and JS.t(meta.get("consumeLightningAmp"))):
				JS.idx(State.status, attackerSide).lightningMult = max(overloadFloor, JS.idx(State.status, attackerSide).get("lightningMult") - 0.25)
	# Shock: baseline (3 + casterEFX/10)%/stack outgoing damage. Conduction passive adds +2%.
	var sStacks = JS.or_(JS.idx(State.status, attackerSide).get("shockStacks"), 0)
	if (sStacks > 0 and dmg > 0):
		var hasConduction = ((attackerSide == "player" and Main.hasPassive("lightning_conduction")) or (attackerSide == "enemy" and Main.enemyHasPassive("lightning_conduction")))
		var casterEFX = Helpers.effectPowerFor(defenderSide)
		var pctPerStack = ((3 + (casterEFX / 10.0)) / 100.0) + (0.02 if hasConduction else 0)
		var reduction = Helpers.clamp_(sStacks * pctPerStack, 0, 0.75)
		dmg = max(0, JS.round(dmg * (1 - reduction)))
	# Air Backdraft: bonus multiplier when enemy actions resolved before this spell
	if (((attackerSide == "player" and Helpers.elementOfSide("player") == "Air") and Main.hasPassive("air_backdraft")) and dmg > 0):
		var eab = min(2, JS.or_(State.combat.get("currentQueuePosition"), 0))
		if eab > 0:
			dmg = JS.round(dmg * (1 + (eab * 0.15)))
	# log is in resolveFlat context; skip inline log to avoid per-hit spam
	# Air Vortex Strike: +50% when acting consecutively after your own action
	if (((attackerSide == "player" and Helpers.elementOfSide("player") == "Air") and JS.t(State.combat.get("_vortexStrikeActive"))) and dmg > 0):
		dmg = JS.round(dmg * 1.5)
	# Origination (KT): flat bonus when enemy has 2+ elemental curse types active
	if ((attackerSide == "player" and JS.t(State.player.get("_ktOriginationLevel"))) and dmg > 0):
		var es = JS.idx(State.status, defenderSide)
		var elemCurses = len(JS.filter([
			(JS.or_(es.get("burnStacks"), 0)) > 0,
			(JS.or_(es.get("shockStacks"), 0)) > 0,
			((JS.or_(es.get("rootStacks"), 0)) + (JS.or_(es.get("overgrowthStacks"), 0))) > 0,
			(JS.or_(es.get("frostStacks"), 0)) > 0,
			(JS.or_(es.get("foamStacks"), 0)) > 0,
		], JS.t))
		if elemCurses >= 2:
			dmg += JS.or_(JS.idx([5, 10, 15, 20, 25], JS.un(State.player.get("_ktOriginationLevel")) - 1), 5)
	# Strength (KT): last-stand outgoing bonus scaled by level
	if (((attackerSide == "player" and JS.t(State.player.get("_ktStrengthPassive"))) and State.player.get("revives") <= 0) and dmg > 0):
		var _sLvl = JS.or_(State.player.get("_ktStrengthLevel"), 1)
		dmg = JS.round(dmg * JS.un(JS.idx([1.1, 1.15, 1.2], _sLvl - 1)))
	return dmg

func effectBlockedByRoot(defenderSide = null):
	if (JS.or_(JS.idx(State.status, defenderSide).get("rootStacks"), 0)) > 0:
		var hasOvergrowth = ((defenderSide == "player" and Main.hasPassive("nature_overgrowth")) or (defenderSide == "enemy" and Main.enemyHasPassive("nature_overgrowth")))
		if hasOvergrowth:
			JS.idx(State.status, defenderSide).rootStacks -= 1
			JS.idx(State.status, defenderSide).overgrowthStacks = (JS.or_(JS.idx(State.status, defenderSide).get("overgrowthStacks"), 0)) + 1
			UI.log_("🌿 Overgrowth blocks effect! (root ×" + JS.s(JS.idx(State.status, defenderSide).get("rootStacks")) + ", growth ×" + JS.s(JS.idx(State.status, defenderSide).get("overgrowthStacks")) + ")", "status")
		else:
			JS.idx(State.status, defenderSide).rootStacks -= 1
			UI.log_("🌿 Root blocks effect! (×" + JS.s(JS.idx(State.status, defenderSide).get("rootStacks")) + " left)", "status")
		return true
	return false

func performHit(attackerSide = null, defenderSide = null, pkg = null):
	var hits = JS.or_(pkg.get("hits"), 1)
	for i in range(ceili(hits)):
		if JS.t(State.combat.get("over")):
			return
		# ── Spell animation (cosmetic, non-blocking) ──
		if ((((not JS.t(pkg.get("_isEcho")) and not JS.t(pkg.get("_isReflect"))) and not JS.t(pkg.get("_isDblStrike"))) and not JS.t(pkg.get("_isElemProc"))) and i == 0):
			Animations.triggerSpellAnim((pkg.get("abilityElement") if JS.t(pkg.get("abilityElement")) else (State.playerElement if attackerSide == "player" else "Neutral")), attackerSide, State.combat.get("activeEnemyIdx"))
		# ── Static Shock: passive effect TBD ──
		# ── Dodge / Phase ──
		var fissure = Helpers.isEarthFissure(attackerSide, pkg)
		if not fissure:
			if JS.idx(State.status, defenderSide).get("phaseTurns") > 0:
				JS.idx(State.status, defenderSide).phaseTurns -= 1
				UI.log_("🔮 " + JS.s(("You" if defenderSide == "player" else State.combat.get("enemy").get("name"))) + " phase — attack misses!", "status")
				UI.renderStatusTags()
				continue
			var dodgeChance = Helpers.dodgeChanceFor(defenderSide)
			if (dodgeChance > 0 and randf() < dodgeChance):
				UI.log_("💨 " + JS.s(("You" if defenderSide == "player" else State.combat.get("enemy").get("name"))) + " dodge!", "status")
				# Air: Momentum decay on dodge
				if (defenderSide == "player" and State.playerElement == "Air"):
					if JS.t(State.status.get("player").get("momentumNoDecayNext")):
						State.status.get("player").momentumNoDecayNext = false
						UI.log_("🌬️ Become Wind — no Momentum decay this dodge!", "status")
					else:
						var decayPct = (0.1 if Main.hasPassive("air_slipstream") else 0.25)
						var cur = JS.or_(State.status.get("player").get("momentumStacks"), 0)
						var lost = max(0, floori(cur * decayPct))
						if lost > 0:
							State.status.get("player").momentumStacks = cur - lost
							UI.log_("💨 Dodge! Momentum −" + JS.s(lost) + " (×" + JS.toFixed(State.status.get("player").get("momentumStacks"), 1) + ")", "status")
					UI.renderStatusTags()
				continue
		# ── Base damage ──
		var dmg = applyOutgoingDamageMods(attackerSide, defenderSide, pkg.get("baseDamage"), {"consumeLightningAmp": true, "_noAtk": (not (not JS.t(pkg.get("_noAtk")))), "apMult": pkg.get("apMult")})
		# Hard Shell (Earth defender): flat damage reduction per hit
		if not fissure:
			var armor = Helpers.armorReductionFor(defenderSide)
			if armor > 0:
				dmg = max(0, dmg - armor)
		# Defense: flat damage reduction per hit (both sides)
		if dmg > 0:
			var def = max(0, Helpers.defenseFor(defenderSide))
			if def > 0:
				dmg = max(0, dmg - def)
		# ── Frozen 1.5× damage on Ice hits — consumes 10 stacks and breaks freeze ──
		var defIsFrozen = JS.idx(State.status, defenderSide).get("frozen")
		if (JS.t(defIsFrozen) and pkg.get("abilityElement") == "Ice"):
			dmg = JS.round(dmg * 1.5)
			JS.idx(State.status, defenderSide).frostStacks = max(0, (JS.or_(JS.idx(State.status, defenderSide).get("frostStacks"), 0)) - 10)
			JS.idx(State.status, defenderSide).frozen = false
			UI.log_("🧊 Frozen! 1.5× damage, 10 Frost consumed (" + JS.s(JS.idx(State.status, defenderSide).get("frostStacks")) + " remaining)", "status")
		# ── Block absorption (fissure bypasses) ──
		if not fissure:
			var effBlock = Helpers.effectiveArmor(defenderSide)
			# includes Stone/Frost/Foam modifiers
			if (effBlock < 0 and dmg > 0):
				# Negative armor (foam stripped past zero): bonus damage to attacker
				dmg -= effBlock
				# effBlock is negative, so subtracting adds to dmg
				UI.log_("🫧 Exposed! +" + JS.s(-effBlock) + " bonus dmg (armor broken by foam)", "status")
			elif (effBlock > 0 and dmg > 0):
				var absorbed = min(effBlock, dmg)
				dmg = max(0, dmg - absorbed)
				# Only consume real block (Stone/Frost don't deplete)
				var blockConsumed = min(JS.or_(JS.idx(State.status, defenderSide).get("block"), 0), absorbed)
				var blockBefore = JS.or_(JS.idx(State.status, defenderSide).get("block"), 0)
				# Track armor peak for Meltdown legendary
				if (defenderSide == "enemy" and blockBefore > 0):
					JS.idx(State.status, defenderSide)._armorPeak = max(JS.or_(JS.idx(State.status, defenderSide).get("_armorPeak"), 0), blockBefore)
				JS.idx(State.status, defenderSide).block = max(0, blockBefore - blockConsumed)
				if absorbed > 0:
					UI.log_("🛡️ Armor absorbs " + JS.s(absorbed) + ". (" + JS.s(JS.idx(State.status, defenderSide).get("block")) + " block left)", "status")
				# Earthen Bulwark: +2 Stone when block reaches 0
				if (((defenderSide == "player" and blockBefore > 0) and JS.eq(State.status.get("player").get("block"), 0)) and Main.hasPassive("earth_earthen_bulwark")):
					Helpers.addStoneStacks("player", 2)
					UI.log_("🪨 Earthen Bulwark! +2 Stone", "status")
				# Meltdown legendary: when enemy armor fully breaks via any hit
				if ((((attackerSide == "player" and defenderSide == "enemy") and blockBefore > 0) and JS.eq(JS.idx(State.status, defenderSide).get("block"), 0)) and Main.hasPassive("fire_meltdown")):
					var peak = JS.or_(JS.idx(State.status, defenderSide).get("_armorPeak"), blockBefore)
					var _mdownDmg = JS.round(peak)
					UI.log_("🌋 Meltdown! +" + JS.s(_mdownDmg) + " from peak armor " + JS.s(peak) + "!", "status")
					JS.idx(State.status, defenderSide)._armorPeak = 0
					applyDirectDamage.call("player", "enemy", _mdownDmg, "🌋 Meltdown")
					if JS.t(State.combat.get("over")):
						return
				# Tidal Shield reactive: Foam attacker + heal per block consumed
				if (((defenderSide == "player" and JS.t(State.status.get("player").get("tidalShieldActive"))) and blockConsumed > 0) and attackerSide == "enemy"):
					Helpers.applyHeal("player", blockConsumed, "🌊 Tidal Shield")
					var eIdx = State.combat.get("activeEnemyIdx")
					if (JS.t(JS.idx(State.combat.get("enemies"), eIdx)) and JS.t(JS.idx(State.combat.get("enemies"), eIdx).get("alive"))):
						Helpers.applyFoam("player", "enemy", 1)
						UI.log_("🌊 Tidal Shield: +1 Foam on attacker", "status")
					State.status.get("player").tidalShieldActive = false
				# Cryostasis reactive: 3 Frost to attacker when armor is hit
				if (((defenderSide == "player" and JS.t(State.status.get("player").get("cryostasisActive"))) and blockConsumed > 0) and attackerSide == "enemy"):
					Helpers.applyFrost("player", "enemy", 3)
					State.status.get("player").cryostasisActive = false
					UI.log_("🧊 Cryostasis: 3 Frost to attacker!", "status")
		# ── Firewall: defender absorbs with fire shield stacks ──
		if ((defenderSide == "player" and (JS.or_(State.status.get("player").get("firewallStacks"), 0)) > 0) and dmg > 0):
			var absorbed = min(State.status.get("player").get("firewallStacks") * 5, dmg)
			var stacksUsed = ceili(absorbed / 5.0)
			State.status.get("player").firewallStacks = max(0, State.status.get("player").get("firewallStacks") - stacksUsed)
			dmg -= absorbed
			dmg = max(0, dmg)
			# Apply burn to attacker
			if attackerSide == "enemy":
				JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx")).get("status").burnStacks = (JS.or_(JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx")).get("status").get("burnStacks"), 0)) + (stacksUsed * 2)
				UI.log_("🔥 Firewall! −" + JS.s(stacksUsed) + " stacks, " + JS.s(stacksUsed * 2) + " Burn to attacker", "status")
		# ── Wind Wall: delay incoming damage ──
		if (((defenderSide == "player" and JS.t(State.status.get("player").get("windWallActive"))) and dmg > 0) and not JS.t(pkg.get("_isWindWall"))):
			State.status.get("player").windWallActive = false
			State.status.get("player").windWallPending = (JS.or_(State.status.get("player").get("windWallPending"), 0)) + dmg
			UI.log_("🌬️ Wind Wall! " + JS.s(dmg) + " damage delayed to next turn.", "status")
			UI.renderStatusTags()
			dmg = 0
		var _atkEnemy = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
		applyDirectDamage.call(attackerSide, defenderSide, dmg, (pkg.get("label") if JS.t(pkg.get("label")) else ((JS.or_(JS.g(_atkEnemy, "emoji"), "")) + " " + (JS.or_(JS.g(_atkEnemy, "name"), "Enemy")) if JS.t(pkg.get("isEnemyAttack")) else "Hit")))
		# ── Air: Momentum gain per damage instance ──
		if (((attackerSide == "player" and State.playerElement == "Air") and dmg > 0) and not JS.t(pkg.get("_isTornadoSelf"))):
			if randf() < (pkg.get("momentumChance") if pkg.get("momentumChance") != null else 0.5):
				var momGain = 1
				if (Main.hasPassive("air_gale_force") and randf() < 0.5):
					momGain += 1
				Helpers.addMomentumStacks(momGain)
		# Record for Plasma echo
		if ((dmg > 0 and not JS.t(pkg.get("_isEcho"))) and not JS.t(pkg.get("noRecord"))):
			JS.idx(State.status, attackerSide).lastDamagePkg = {
				"baseDamage": JS.or_(pkg.get("baseDamage"), 0),
				"meta": {"isBasic": (not (not JS.t(pkg.get("isBasic")))), "abilityElement": pkg.get("abilityElement")},
			}
		if JS.t(State.combat.get("over")):
			return
		# ── Embrittlement: Frozen targets take +3 per damage instance ──
		if (JS.t(defIsFrozen) and dmg > 0):
			var hasEmbrit = ((attackerSide == "player" and Main.hasPassive("ice_embrittlement")) or (attackerSide == "enemy" and Main.enemyHasPassive("ice_embrittlement")))
			if hasEmbrit:
				applyDirectDamage.call(attackerSide, defenderSide, 3, "🧊 Embrittlement")
				if JS.t(State.combat.get("over")):
					return
		# ── Ebb: reflect damage ──
		if (((defenderSide == "player" and Main.hasPassive("water_ebb")) and dmg > 0) and not JS.t(pkg.get("_isReflect"))):
			var pow_ = Helpers.defenseFor("player")
			var reflectPct = (20 + floori(pow_ / 10.0)) / 100.0
			var reflectDmg = max(1, JS.round(dmg * reflectPct))
			UI.log_("🌊 Ebb reflects " + JS.s(reflectDmg) + "!", "status")
			performHit("player", "enemy", {"baseDamage": reflectDmg, "effects": [], "abilityElement": "Water", "_isReflect": true, "noRecord": true})
			if JS.t(State.combat.get("over")):
				return
		if (((defenderSide == "enemy" and Main.enemyHasPassive("water_ebb")) and dmg > 0) and not JS.t(pkg.get("_isReflect"))):
			var pow_ = Helpers.defenseFor("enemy")
			var reflectPct = (20 + floori(pow_ / 10.0)) / 100.0
			var reflectDmg = max(1, JS.round(dmg * reflectPct))
			UI.log_("🌊 Enemy Ebb reflects " + JS.s(reflectDmg) + "!", "status")
			performHit("enemy", "player", {"baseDamage": reflectDmg, "effects": [], "abilityElement": "Water", "_isReflect": true, "noRecord": true})
			if JS.t(State.combat.get("over")):
				return
		# ── Lightning Double Strike ──
		if (pkg.get("abilityElement") == "Lightning" and not JS.t(pkg.get("_isDblStrike"))):
			var hasDouble = ((attackerSide == "player" and Main.hasPassive("lightning_double")) or (attackerSide == "enemy" and Main.enemyHasPassive("lightning_double")))
			if hasDouble:
				var pow_ = Helpers.effectPowerFor(attackerSide)
				# Velocity Arc (Air+Lightning duo): +1% double strike chance per Momentum stack
				var momBonus = ((JS.or_(State.status.get("player").get("momentumStacks"), 0)) * 0.01 if (attackerSide == "player" and Main.hasPassive("duo_velocity_arc")) else 0)
				var chance = Helpers.clamp_(((30 + floori(pow_ / 2.0)) / 100.0) + momBonus, 0, 10)
				var roll = randf()
				var extraHits = (2 if (chance > 1.0 and roll < (chance - 1.0)) else (1 if roll < min(chance, 1.0) else 0))
				for h in range(ceili(extraHits)):
					UI.log_("💥 " + ("Double" if h == 0 else "Triple") + " Strike!", "status")
					if (attackerSide == "player" and Main.hasPassive("duo_velocity_arc")):
						Helpers.addMomentumStacks(2)
					performHit(attackerSide, defenderSide, JS.merge([pkg, {"baseDamage": JS.round((JS.or_(pkg.get("baseDamage"), 0)) * 0.7), "_isDblStrike": true, "noRecord": true}]))
					if JS.t(State.combat.get("over")):
						return
		# ── Apply spell effects: burn / stun (each blockable by Root) ──
		for eff in JS.iter(JS.or_(pkg.get("effects"), [])):
			if JS.t(State.combat.get("over")):
				continue
			# Debuff immune (Brave Burn)
			if JS.idx(State.status, defenderSide).get("debuffImmune") > 0:
				continue
			if effectBlockedByRoot(defenderSide):
				continue
			if eff.get("type") == "burn":
				var pow_ = Helpers.effectPowerFor(attackerSide)
				var powerBonus = floori(pow_ * 0.2)
				var stacks = (JS.or_(eff.get("stacks"), 0)) + powerBonus
				if ((attackerSide == "player" and Main.hasPassive("fire_pyromaniac")) or (attackerSide == "enemy" and Main.enemyHasPassive("fire_pyromaniac"))):
					stacks += 3
				JS.idx(State.status, defenderSide).burnStacks += stacks
				JS.idx(State.status, defenderSide).burnSourcePower = pow_
				UI.log_("🔥 Burn +" + JS.s(stacks) + " (×" + JS.s(JS.idx(State.status, defenderSide).get("burnStacks")) + ")", "status")
				_plasmaChargeOnDebuff(defenderSide)
				var pre = JS.idx(State.status, defenderSide).get("burnStacks") - stacks
				if pre > 0:
					var hasCombustion = ((attackerSide == "player" and Main.hasPassive("fire_combustion")) or (attackerSide == "enemy" and Main.enemyHasPassive("fire_combustion")))
					if hasCombustion:
						var growth = 1 + floori(pre / 5.0)
						JS.idx(State.status, defenderSide).burnStacks += growth
						UI.log_("💥 Combustion: +" + JS.s(growth) + " extra burn (×" + JS.s(JS.idx(State.status, defenderSide).get("burnStacks")) + ")", "status")
			elif eff.get("type") == "stun":
				JS.idx(State.status, defenderSide).stunned = max(JS.idx(State.status, defenderSide).get("stunned"), JS.or_(eff.get("turns"), 1))
				UI.log_("❄️ Stun " + JS.s(JS.or_(eff.get("turns"), 1)) + "t", "status")
				_plasmaChargeOnDebuff(defenderSide)
		# ── Sea Foam passive: every Water hit applies 1 Foam ──
		if (pkg.get("abilityElement") == "Water" and not JS.t(pkg.get("_isReflect"))):
			var hasFoam = ((attackerSide == "player" and Main.hasPassive("water_sea_foam")) or (attackerSide == "enemy" and Main.enemyHasPassive("water_sea_foam")))
			if hasFoam:
				Helpers.applyFoam(attackerSide, defenderSide, 1)
				_plasmaChargeOnDebuff(defenderSide)
		# ── Nature Root proc on all Nature hits ──
		if (Helpers.elementOfSide(attackerSide) == "Nature" and not JS.t(pkg.get("_isReflect"))):
			if randf() < Constants.ROOT_PROC_CHANCE:
				Helpers.applyRoot(attackerSide, defenderSide, 1)
		# ── Thorned Strikes: bonus damage per Root/Overgrowth stack ──
		var hasThorns = ((attackerSide == "player" and Main.hasPassive("nature_thorned_strikes")) or (attackerSide == "enemy" and Main.enemyHasPassive("nature_thorned_strikes")))
		if hasThorns:
			var totalRoots = (JS.or_(JS.idx(State.status, defenderSide).get("rootStacks"), 0)) + (JS.or_(JS.idx(State.status, defenderSide).get("overgrowthStacks"), 0))
			if totalRoots > 0:
				applyDirectDamage.call(attackerSide, defenderSide, totalRoots * 5, "🌵 Thorned Strikes (×" + JS.s(totalRoots) + ")")
				if JS.t(State.combat.get("over")):
					return
		# ── Ice Blast (execute): kills enemies below HP threshold ──
		if ((defenderSide == "enemy" and attackerSide == "player") and Main.hasPassive("ice_blast")):
			var e = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
			if (JS.t(e) and JS.t(e.get("alive"))):
				var threshold = Helpers.clamp_((20 + floori(Helpers.effectPowerFor("player") / 4.0)) + (JS.or_(State.player.get("_talentIceExecute"), 0)), 0, 60)
				var pct = (e.get("hp") / float(e.get("enemyMaxHP"))) * 100
				if pct <= threshold:
					UI.log_("❄️ Ice Blast executes " + JS.s(e.get("name")) + " at " + JS.s(JS.round(pct)) + "% HP!", "player")
					e.hp = 0
					e.alive = false
					if len(Helpers.aliveEnemies()) == 0:
						Combat.endBattle(true)
						return
					State.combat.targetIdx = Helpers.firstAliveIdx()
					State.setActiveEnemy(State.combat.get("targetIdx"))
		# ── Eye of the Storm: repeat strike chance per Momentum stack ──
		if ((((attackerSide == "player" and State.playerElement == "Air") and dmg > 0) and Main.hasPassive("air_eye_of_the_storm")) and not JS.t(pkg.get("_isTornadoSelf"))):
			var repeatChance = min(0.95, floori(JS.or_(State.status.get("player").get("momentumStacks"), 0)) * 0.03)
			var depth = JS.or_(pkg.get("_eotDepth"), 0)
			if ((depth < 1 and repeatChance > 0) and randf() < repeatChance):
				UI.log_("👁️ Eye of the Storm repeats! (" + JS.s(JS.round(repeatChance * 100)) + "% chance)", "status")
				performHit(attackerSide, defenderSide, JS.merge([pkg, {"_eotDepth": depth + 1, "noRecord": true}]))
				if JS.t(State.combat.get("over")):
					return
	UI.updateHPBars()
	UI.renderStatusTags()

func applyEffectDamage(attackerSide = null, defenderSide = null, dmg = null, label = null):
	# Effect damage (burn, frost ticks, zone pressure, etc.)
	# Armor reduces it; block does NOT. Does NOT count toward Surge meter.
	if dmg <= 0:
		return
	var armor = Helpers.armorReductionFor(defenderSide)
	if armor > 0:
		var reduced = max(0, dmg - armor)
		if reduced < dmg:
			UI.log_("🛡️ Armor absorbs " + JS.s(dmg - reduced) + " from " + JS.s(label), "status")
		dmg = reduced
		if dmg <= 0:
			return
	applyDirectDamage.call(attackerSide, defenderSide, dmg, label, {"noSurge": true})

# Grant Charge when a debuff is applied to the player (Plasma only, 1 per application instance)
# Only triggers when the Plasma abilities book is the currently active book
func _plasmaChargeOnDebuff(defenderSide = null):
	if State.playerElement != "Plasma":
		return
	if defenderSide != "player":
		return
	# Charge only accumulates when the plasma book is active
	var _pIdx = State.plasmaBookIdx()
	if (_pIdx < 0 or State.player.get("activeBookIdx") != _pIdx):
		return
	var hasStabilized = Main.hasPassive("plasma_stabilized_core")
	if hasStabilized:
		# Stabilized: 1 charge per debuff (was 0.5)
		State.status.get("player").plasmaCharge = (JS.or_(State.status.get("player").get("plasmaCharge"), 0)) + 1
		UI.log_("🔋 Charge +1 from debuff (Stabilized) → " + JS.s(State.status.get("player").get("plasmaCharge")), "status")
		Spells.updateChargeUI()
	else:
		# Base: 2 charge per debuff (was 1)
		State.status.get("player").plasmaCharge = (JS.or_(State.status.get("player").get("plasmaCharge"), 0)) + 2
		UI.log_("⚡ Charge +2 from debuff → " + JS.s(State.status.get("player").get("plasmaCharge")), "status")
		Spells.updateChargeUI()

func _plasmaBackfeed(attackerSide = null, triggeringDmg = null):
	if not Main.hasPassive("plasma_backfeed_reactor"):
		return
	var pow_ = Helpers.attackPowerFor("player", "enemy")
	var reflectDmg = max(1, JS.round((triggeringDmg * 0.2) + (pow_ / 5.0)))
	# Reflect back at the active enemy
	var e = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
	if (JS.t(e) and JS.t(e.get("alive"))):
		e.hp = max(0, e.get("hp") - reflectDmg)
		UI.log_("♻️ Backfeed Reactor: " + JS.s(reflectDmg) + " reflected to " + JS.s(e.get("name")) + "!", "status")
		if e.get("hp") <= 0:
			e.alive = false
			UI.log_("💀 " + JS.s(e.get("name")) + " defeated!", "win")
			UI.renderEnemyCards()
			if len(Helpers.aliveEnemies()) == 0:
				Combat.endBattle(true)

func applyDirectDamage_2(attackerSide = null, defenderSide = null, dmg = null, label = null, opts = null):
	if dmg <= 0:
		if JS.t(label):
			UI.log_(JS.s(label) + ": 0 dmg.", "status")
		return
	if defenderSide == "enemy":
		var e = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
		if (not JS.t(e) or not JS.t(e.get("alive"))):
			return
		e.hp = max(0, e.get("hp") - dmg)
		if attackerSide == "player":
			State._runDmgDealt += dmg
		UI.log_(JS.s(label) + " deals " + JS.s(dmg) + " to " + JS.s(e.get("name")) + ". (" + JS.s(e.get("hp")) + "/" + JS.s(e.get("enemyMaxHP")) + ")", ("player" if attackerSide == "player" else "enemy"))
		Sprites.triggerHitFlash("enemy", State.combat.get("activeEnemyIdx"))
		# Surge meter: direct player damage feeds the meter (effect/DOT damage skipped via opts.noSurge)
		if (attackerSide == "player" and not (JS.t(opts) and JS.t(opts.get("noSurge")))):
			Surge._addToSurgeMeter("enemy", dmg)
			if JS.t(State.combat.get("over")):
				return
		# Surge may have triggered and ended battle
		if e.get("hp") <= 0:
			e.alive = false
			State._runKillsThisRun += 1
			UI.log_("💀 " + JS.s(e.get("name")) + " defeated!", "win")
			UI.renderEnemyCards()
			if len(Helpers.aliveEnemies()) == 0:
				Combat.endBattle(true)
				return
			State.combat.targetIdx = Helpers.firstAliveIdx()
			State.setActiveEnemy(State.combat.get("targetIdx"))
	else:
		# ── Plasma: Stall immunity ──
		if (State.playerElement == "Plasma" and JS.t(State.status.get("player").get("stallActive"))):
			UI.log_("🫧 Stall! " + JS.s(label) + " blocked.", "status")
			return
		# ── Plasma: Shield reduction ──
		if ((State.playerElement == "Plasma" and State.status.get("player").get("plasmaShieldReduction") > 0) and dmg > 0):
			var reduced = max(0, JS.round(dmg * (1 - (State.status.get("player").get("plasmaShieldReduction") / 100.0))))
			if reduced < dmg:
				UI.log_("🛡️ Plasma Shield absorbs " + JS.s(dmg - reduced) + " (" + JS.s(State.status.get("player").get("plasmaShieldReduction")) + "% reduction)", "status")
			dmg = reduced
			if dmg <= 0:
				UI.updateHPBars()
				return
		# Strength (KT): last-stand incoming reduction scaled by level
		if ((JS.t(State.player.get("_ktStrengthPassive")) and State.player.get("revives") <= 0) and dmg > 0):
			var _sLvl = JS.or_(State.player.get("_ktStrengthLevel"), 1)
			dmg = JS.round(dmg * JS.un(JS.idx([0.75, 0.65, 0.6], _sLvl - 1)))
		# For Plasma: allow HP to go negative so heals must actually cover the full deficit
		if State.playerElement == "Plasma":
			State.player.hp = State.player.get("hp") - dmg
			# no floor — can go negative
			State._runDmgTaken += dmg
		else:
			State.player.hp = max(0, State.player.get("hp") - dmg)
			State._runDmgTaken += dmg
		UI.log_(JS.s(label) + " deals " + JS.s(dmg) + " to you. (" + JS.s(max(0, State.player.get("hp"))) + "/" + JS.s(Helpers.maxHPFor("player")) + ")", "enemy")
		Sprites.triggerHitFlash("player")
		# ── Plasma: Charge gain on damage received ──
		if ((((State.playerElement == "Plasma" and dmg > 0) and not JS.includes(label, "Recoil")) and not JS.includes(label, "Self Sacrifice")) and not JS.includes(label, "Charge Heal")):
			var hasStabilized = Main.hasPassive("plasma_stabilized_core")
			if hasStabilized:
				# Stabilized: 1 charge per hit (was 0.5)
				State.status.get("player").plasmaCharge = (JS.or_(State.status.get("player").get("plasmaCharge"), 0)) + 1
				UI.log_("🔋 Charge +1 (Stabilized) → " + JS.s(State.status.get("player").get("plasmaCharge")), "status")
				_plasmaBackfeed(attackerSide, dmg)
			else:
				# Base: 2 charge per hit (was 1)
				State.status.get("player").plasmaCharge = (JS.or_(State.status.get("player").get("plasmaCharge"), 0)) + 2
				UI.log_("⚡ Charge +2 → " + JS.s(State.status.get("player").get("plasmaCharge")), "status")
				_plasmaBackfeed(attackerSide, dmg)
			Spells.updateChargeUI()
		# ── Deferred death: don't end battle mid-turn for Plasma (resolveFlat checks after all actions) ──
		# For non-Plasma, still end immediately (no heal-back mechanic)
		if (State.player.get("hp") <= 0 and not JS.t(State.combat.get("over"))):
			if State.playerElement == "Plasma":
				pass
			else:
				# deferred to resolveFlat end
				Combat.endBattle(false)
	UI.updateHPBars()

func applyMelt_2(attackerSide = null, targetSide = null, meltPoints = null, label = null):
	if meltPoints <= 0:
		return
	label = JS.or_(label, "🔥 Melt")
	# ── Temper: consume multiplier on next melt hit ──
	if (attackerSide == "player" and JS.t(State.combat.get("nextMeltDouble"))):
		meltPoints = JS.round(meltPoints * 2)
		State.combat.nextMeltDouble = false
		UI.log_("⚔️ Temper: Melt ×2! (" + JS.s(meltPoints) + " pts)", "status")
	# ── Molten Surge: all melt this turn multiplied ──
	if (attackerSide == "player" and JS.t(State.combat.get("meltDoubleTurn"))):
		meltPoints = JS.round(meltPoints * 2)
		UI.log_("🌋 Molten Surge: Melt ×2! (" + JS.s(meltPoints) + " pts)", "status")
	# ── Forge Master: +30% melt points ──
	if (attackerSide == "player" and Main.hasPassive("fire_forge_master")):
		meltPoints = JS.round(meltPoints * 1.3)
	# ── Deep Heat: +EFX/5 bonus melt points ──
	if (attackerSide == "player" and Main.hasPassive("fire_deep_heat")):
		var deepBonus = floori(Helpers.effectPowerFor("player") / 5.0)
		if deepBonus > 0:
			meltPoints += deepBonus
	# Get target object + status
	var targetStatus = null
	var targetObj = null
	if targetSide == "enemy":
		targetObj = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
		if (not JS.t(targetObj) or not JS.t(targetObj.get("alive"))):
			return
		targetStatus = targetObj.get("status")
	else:
		targetStatus = State.status.get("player")
	var currentArmor = JS.or_(targetStatus.get("block"), 0)
	# ── Update armor peak for Meltdown ──
	if currentArmor > 0:
		targetStatus._armorPeak = max(JS.or_(targetStatus.get("_armorPeak"), 0), currentArmor)
	var remaining = meltPoints
	var armorDestroyed = 0
	if currentArmor > 0:
		var breakCost = ceili(currentArmor / 3.0)
		if remaining >= breakCost:
			# Full armor break: costs ceil(armor/3) melt points
			armorDestroyed = currentArmor
			remaining -= breakCost
			targetStatus.block = 0
			UI.log_("⚒️ " + label + ": " + JS.s(armorDestroyed) + " armor melted! (" + JS.s(breakCost) + " pts used, " + JS.s(remaining) + " pts remain)", "status")
			# ── Meltdown legendary ──
			var hasMeltdown = ((attackerSide == "player" and Main.hasPassive("fire_meltdown")) or (attackerSide == "enemy" and Main.enemyHasPassive("fire_meltdown")))
			if hasMeltdown:
				var peak = JS.or_(targetStatus.get("_armorPeak"), armorDestroyed)
				var meltdownBonus = JS.round(peak)
				UI.log_("🌋 Meltdown! +" + JS.s(meltdownBonus) + " bonus Melt (peak armor: " + JS.s(peak) + ")", "status")
				remaining += meltdownBonus
			targetStatus._armorPeak = 0
			# ── Slag Trail: armor destroyed → burn stacks on target ──
			if (((attackerSide == "player" and Main.hasPassive("fire_slag_trail")) and armorDestroyed > 0) and JS.t(targetObj)):
				targetStatus.burnStacks = (JS.or_(targetStatus.get("burnStacks"), 0)) + armorDestroyed
				UI.log_("🔥 Slag Trail: +" + JS.s(armorDestroyed) + " Burn from melted armor!", "status")
			# ── Deep Heat: 50% of armor stripped as bonus melt ──
			if ((attackerSide == "player" and Main.hasPassive("fire_deep_heat")) and armorDestroyed > 0):
				var dhBonus = floori(armorDestroyed * 0.5)
				if dhBonus > 0:
					remaining += dhBonus
					UI.log_("🔥 Deep Heat: +" + JS.s(dhBonus) + " bonus Melt from stripped armor!", "status")
		else:
			# Partial: each melt point chips 3 armor points
			var armorChipped = remaining * 3
			targetStatus.block = max(0, currentArmor - armorChipped)
			UI.log_("⚒️ " + label + ": chips " + JS.s(armorChipped) + " armor. (" + JS.s(targetStatus.get("block")) + " remain)", "status")
			remaining = 0
	# ── HP damage portion ──
	if remaining > 0:
		# Iron Burn: +1 bonus melt per 3 enemy burn stacks
		if ((attackerSide == "player" and Main.hasPassive("fire_iron_burn")) and targetSide == "enemy"):
			var ibBonus = floori((JS.or_(targetStatus.get("burnStacks"), 0)) / 3.0)
			if ibBonus > 0:
				remaining += ibBonus
				UI.log_("🔥 Iron Burn: +" + JS.s(ibBonus) + " from " + JS.s(targetStatus.get("burnStacks")) + " burn stacks", "status")
		# Armor Eater: +2 HP damage per armor point consumed by this melt
		if ((attackerSide == "player" and Main.hasPassive("fire_armor_eater")) and armorDestroyed > 0):
			var aeBonus = armorDestroyed * 2
			remaining += aeBonus
			UI.log_("⚔️ Armor Eater: +" + JS.s(aeBonus) + " from " + JS.s(armorDestroyed) + " armor consumed!", "status")
		# Bellows (Air+Fire duo): Melt HP multiplied by queue position
		if (attackerSide == "player" and Main.hasPassive("duo_bellows")):
			var eab = JS.or_(State.combat.get("currentQueuePosition"), 0)
			var _bChoice = JS.or_(State.player.get("_bellowsChoice"), "fast")
			var _bMult = ((1.5 if eab == 0 else 1) if _bChoice == "fast" else 1 + (eab * 0.25))
			if _bMult > 1:
				remaining = JS.round(remaining * _bMult)
				UI.log_("💨🔩 Bellows: ×" + JS.toFixed(_bMult, 2) + " Melt HP (" + _bChoice + ", EAB=" + JS.s(eab) + ")", "status")
		applyDirectDamage.call(attackerSide, targetSide, JS.round(remaining * 1.5), label)
		if JS.t(State.combat.get("over")):
			return
		# Eternal Flame: melt HP damage applies Burn (50% of HP damage dealt)
		if ((((attackerSide == "player" and Main.hasPassive("fire_eternal_flame")) and targetSide == "enemy") and JS.t(targetObj)) and JS.t(targetObj.get("alive"))):
			var flameBurn = floori(remaining * 0.5)
			if flameBurn > 0:
				targetStatus.burnStacks = (JS.or_(targetStatus.get("burnStacks"), 0)) + flameBurn
				UI.log_("🔥 Eternal Flame: +" + JS.s(flameBurn) + " Burn from Melt!", "status")
	UI.updateHPBars()
	UI.renderStatusTags()
