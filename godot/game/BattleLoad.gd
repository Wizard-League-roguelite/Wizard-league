# BattleLoad — generated from js/logic/battleLoad.js by tools/js2gd.js
extends Node


func _boot():
	pass

# ===== battleLoad.js =====
# ─── BATTLE SETUP — enemy construction, battle initialization, gym entry effects ──
func makeEnemyObj(enc = null):
	var passive = [null]
	var el = Helpers.primaryElement(JS.or_(enc.get("element"), ""))
	if JS.t(enc.get("isTargetDummy")):
		passive[0] = null
	elif JS.t(enc.get("gymPassive")):
		passive[0] = enc.get("gymPassive")
	else:
		var pool = JS.arr(JS.or_(JS.idx(Passives.PASSIVE_CHOICES, el), [])).filter(func(p = null): return not JS.t(p.get("legendary")))
		passive[0] = (JS.idx(pool, floori(randf() * len(pool))).id if JS.t(len(pool)) else null)
	# Per-enemy stat variation: each stat averages battleNumber, ±50% range
	# At B30: avg=30, could be 20 EFX / 40 DEF / 20 POW etc.
	var _statAvg = max(1, State.battleNumber)
	var _vary = func(): return (0 if JS.t(enc.get("isTargetDummy")) else JS.round(_statAvg * (0.5 + randf())))
	var statPow = _vary.call()
	var statEfx = _vary.call()
	var statDef = _vary.call()
	# Zone scale applies to all enemies except dummies and gauntlet bosses (gauntlet has fixed HP)
	var zoneScaled = ({} if (JS.t(enc.get("isTargetDummy")) or JS.t(enc.get("isGauntletBoss"))) else EnemyAbilities.scaleEnemyForZone(enc, State.currentGymIdx))
	var mistHPMult = JS.or_(State.player.get("_mistEnemyHPMult"), 1.0)
	var mistDmgMult = JS.or_(State.player.get("_mistEnemyDmgMult"), 1.0)
	# Per-battle HP ramp: quadratic curve applies to regular enemies AND gym bosses.
	# Gauntlet bosses have fixed HP, target dummies unchanged.
	var _bnRaw = (State.battleNumber - 6 if ((not JS.t(enc.get("isTargetDummy")) and not JS.t(enc.get("isGauntletBoss"))) and State.battleNumber > 6) else 0)
	var _bnFlat = ((State.battleNumber - 3) * 13 if ((not JS.t(enc.get("isTargetDummy")) and not JS.t(enc.get("isGauntletBoss"))) and State.battleNumber > 3) else 0)
	var _bnBase = (1.2 if ((not JS.t(enc.get("isTargetDummy")) and not JS.t(enc.get("isGauntletBoss"))) and State.battleNumber > 3) else 1.0)
	var _bnMult = _bnBase + ((_bnRaw * 0.09) + pow(_bnRaw / 12.0, 2) if _bnRaw > 0 else 0)
	var _lateBoost = (1.3 if ((not JS.t(enc.get("isTargetDummy")) and not JS.t(enc.get("isGauntletBoss"))) and State.battleNumber >= 39) else 1.0)
	var finalMaxHP = JS.round((((((((JS.or_(zoneScaled.get("enemyMaxHP"), enc.get("enemyMaxHP"))) * _bnMult) + _bnFlat) * mistHPMult) * 0.77) * _lateBoost) * (0.5 if JS.eq(State.battleNumber, 1) else 1)) * 1.1)
	var finalDmg = max(1, JS.round(((JS.or_(zoneScaled.get("enemyDmg"), enc.get("enemyDmg"))) * mistDmgMult) * 0.8) - 5)
	# Variable action scaling: after battle 8, each 7-battle threshold grants a 75% roll.
	# Success → +1 bonus action this battle. Failure → +1 incantation level (boosts priority ability's damage scale).
	var bonusActions = 0
	var incantLvl = 0
	if (not JS.t(enc.get("isTargetDummy")) and not JS.t(enc.get("isGym"))):
		for threshold in range(9, floori(State.battleNumber) + 1, 7):
			if randf() < 0.75:
				bonusActions += 1
			else:
				incantLvl += 1
	# Build ability list based on element + zone depth + bonus actions + incantation level
	var _difficulty = (enc.get("difficulty") if JS.t(enc.get("difficulty")) else ("hard" if enc.get("enemyMaxHP") > 120 else ("medium" if enc.get("enemyMaxHP") > 100 else "easy")))
	var abilities = ([] if (JS.t(enc.get("isGym")) or JS.t(enc.get("isTargetDummy"))) else EnemyAbilities.buildEnemyAbilities(el, State.currentGymIdx, _difficulty, bonusActions, incantLvl))
	# Mist: extra passives for non-dummy enemies
	var extraPassives = []
	if (not JS.t(enc.get("isTargetDummy")) and (JS.or_(State.player.get("_mistExtraPassives"), 0)) > 0):
		var pool = JS.arr(JS.or_(JS.idx(Passives.PASSIVE_CHOICES, el), [])).filter(func(p = null): return (not JS.t(p.get("legendary")) and not JS.eq(p.id, passive[0])))
		extraPassives = JS.arr(BattleReward.pickRandom(pool, State.player.get("_mistExtraPassives"))).map(func(p = null): return p.id)
	# Mist: boss legendaries for gym enemies
	if (JS.t(enc.get("isGym")) and (JS.or_(State.player.get("_mistBossLegendaries"), 0)) > 0):
		var legPool = JS.arr(JS.or_(JS.idx(Passives.PASSIVE_CHOICES, el), [])).filter(func(p = null): return JS.t(p.get("legendary")))
		extraPassives = JS.arr(extraPassives) + JS.arr(JS.arr(BattleReward.pickRandom(legPool, State.player.get("_mistBossLegendaries"))).map(func(p = null): return p.id))
	# Give enemies consumable items (gym bosses get both, regular enemies get healing draught)
	var items = ([] if JS.t(enc.get("isTargetDummy")) else (JS.arr(EnemyAbilities.ENEMY_ITEM_CATALOGUE).map(func(it = null): return JS.merge([it])) if JS.t(enc.get("isGym")) else [JS.merge([JS.idx(EnemyAbilities.ENEMY_ITEM_CATALOGUE, 0)])]))
	return JS.merge([enc, {
		"enemyMaxHP": finalMaxHP,
		"enemyDmg": finalDmg,
		"hp": finalMaxHP,
		"alive": true,
		"basicCD": 0,
		"passive": passive[0],
		"extraPassives": extraPassives,
		"statPow": statPow,
		"statEfx": statEfx,
		"statDef": statDef,
		"status": State.freshEnemyStatus(),
		"abilities": abilities,
		"items": items,
		"bonusActions": bonusActions,
		"incantLvl": incantLvl,
		"gymHitCounter": JS.or_(enc.get("gymHitCounter"), 0),
		"gymPhase2": JS.or_(enc.get("gymPhase2"), false),
	}])

func restoreAllPP():
	for book in JS.iter(JS.or_(State.player.get("spellbooks"), [])):
		for s in JS.iter(book.get("spells")):
			if s.get("maxPP") != null:
				s.currentPP = s.get("maxPP")

func loadBattle(enc = null):
	UI.resetDeckHandTracking()
	State.combat.over = false
	State.combat.tempDmgBonus = 0
	State.combat.playerTurn = false
	State.combat._gen = 0
	State.combat.basicCD = 0
	State.combat.actionQueue = []
	State.combat.summons = []
	State.combat.totalGold = 0
	State.combat.hitFlashes = []
	State.combat.turnInBattle = 0
	State.combat._chosenRewardType = JS.or_(enc.get("_rewardType"), null)
	State.combat.activeZoneElement = (null if JS.eq(State.battleNumber, 1) else ((JS.or_(Encounters.currentGymDef(), {})).get("element") if (Encounters.inGymZone() and not JS.t(enc.get("isGym"))) else null))
	State.combat._echoReady = false
	# will be set true in startRound
	State.combat._swiftbladeSwitch = 0
	# reset per-battle swiftblade switch counter
	State.combat.nextMeltDouble = false
	# Temper: next melt hit doubled
	State.combat.meltDoubleTurn = false
	# Molten Surge: all melt this turn doubled
	State.combat._seedSurgePending = false
	# Seed Surge: next Seed costs no CD
	State.combat._seedSurgeBonus = 2
	# Seed Surge: bonus stacks (incantation-scaled)
	# Surge system
	State.combat._surgeThreshold = 60
	# base threshold (unused directly — _getSurgeThreshold() computes it)
	State.combat._surgeFulguriteMinus = 0
	# cumulative threshold reduction from Fulgurite casts
	State.combat._stormCoreBonus = 0
	# cumulative threshold increase from Storm Core triggers
	State.combat._surgeTriggeredThisTurn = false
	State.combat._residualCurrentPending = false
	# Air system resets
	State.combat._momentumSeedProgress = 0
	State.combat._aoPriorityShift = 0
	State.combat._afterburnActive = false
	State.combat._tailwindAllFirst = false
	State.combat._tailwindBonusNextTurn = false
	State.combat._tailwindBonusPriority = null
	State.combat._vortexStrikeActive = false
	# Zone background = the map zone you are fighting in, never the enemy element
	var _gymDef = Encounters.currentGymDef()
	State._setZoneElement((_gymDef.get("element") if (JS.t(_gymDef) and JS.t(_gymDef.get("element"))) else State.playerElement))
	Helpers.resetStatusForBattle()
	# Initialize all books' spells (CDs reset, PP calculated) so non-active books are ready too
	for book in JS.iter(JS.or_(State.player.get("spellbooks"), [])):
		for s in JS.iter(book.get("spells")):
			s.currentCD = 0
			if JS.has(s, "_battlePriority"):
				s._battlePriority = 0
				s.priority = 0
			var rawPP = ceili(32 / float(max(1, JS.or_(s.get("baseCooldown"), 0))))
			var maxPP = max(1, floori(rawPP * (JS.or_(State.player.get("_mistPPMult"), 1.0))))
			s.maxPP = maxPP
			# Carry PP over between battles — only reset if uninitialized or above new max
			if (s.get("currentPP") == null or s.get("currentPP") > maxPP):
				s.currentPP = maxPP
	# Apply per-battle character buff effects
	if State.player.get("_blockStart") > 0:
		State.status.get("player").block = (JS.or_(State.status.get("player").get("block"), 0)) + State.player.get("_blockStart")
	if (JS.or_(State.player.get("_talentStoneStart"), 0)) > 0:
		State.status.get("player").stoneStacks = (JS.or_(State.status.get("player").get("stoneStacks"), 0)) + State.player.get("_talentStoneStart")
	# Plasma: start each battle with 3 charge (+ Reserve Cell bonus)
	if State.playerElement == "Plasma":
		var startCharge = (3 + (10 if Main.hasPassive("plasma_reserve_cell") else 0)) + (JS.or_(State.player.get("_talentChargeStart"), 0))
		State.status.get("player").plasmaCharge = startCharge
		State.status.get("player").plasmaChargeHalf = 0
		State.combat.plasmaChargeReserved = 0
		State.combat.plasmaOvercharged = false
		State.combat.plasmaSpendAmounts = {}
		# reset per-spell steppers each battle
		State.combat.plasmaCurrentSpend = 1
		Spells.updateChargeUI()
	if JS.t(enc.get("isPack")):
		var memberCount = len(enc.get("members"))
		# Pack members deal much less individually — total pack dps should ~= solo enemy
		# 2-pack: 60% HP / 37% dmg.  3-pack: 50% HP / 27% dmg.  4+: 40% HP / 20% dmg
		var hpScale = (0.6 if memberCount <= 2 else (0.5 if memberCount == 3 else 0.4))
		var dmgScale = (0.37 if memberCount <= 2 else (0.27 if memberCount == 3 else 0.2))
		var _fn1 = func(m = null):
			return makeEnemyObj(JS.merge([m, {
				"enemyMaxHP": JS.round(m.get("enemyMaxHP") * hpScale),
				"enemyDmg": JS.round(m.get("enemyDmg") * dmgScale),
				"gold": floori(enc.get("gold") / float(len(enc.get("members")))),
				"isGym": false,
			}]))
		State.combat.enemies = JS.arr(enc.get("members")).map(_fn1)
		State.combat.totalGold = enc.get("gold")
		State.combat._isSpellBattle = JS.or_(enc.get("_isSpellBattle"), false)
		State.combat._isRival = JS.or_(enc.get("isRival"), false)
		State.combat._isGauntletBoss = JS.or_(enc.get("isGauntletBoss"), false)
	else:
		State.combat.enemies = [makeEnemyObj(enc)]
		State.combat.totalGold = enc.get("gold")
		State.combat._isSpellBattle = JS.or_(enc.get("_isSpellBattle"), false)
		State.combat._isRival = JS.or_(enc.get("isRival"), false)
		State.combat._isGauntletBoss = JS.or_(enc.get("isGauntletBoss"), false)
	State.combat.targetIdx = 0
	State.setActiveEnemy(0)
	# Apply talent-granted battle-start stacks to enemies
	if (JS.or_(State.player.get("_talentBurnStart"), 0)) > 0:
		for e in JS.iter(State.combat.get("enemies")):
			if JS.t(e.get("alive")):
				e.get("status").burnStacks = (JS.or_(e.get("status").get("burnStacks"), 0)) + State.player.get("_talentBurnStart")
	if (JS.or_(State.player.get("_talentFoamStart"), 0)) > 0:
		for e in JS.iter(State.combat.get("enemies")):
			if JS.t(e.get("alive")):
				e.get("status").foamStacks = (JS.or_(e.get("status").get("foamStacks"), 0)) + State.player.get("_talentFoamStart")
	var label = ("⚔ Gym " + JS.s(State.currentGymIdx + 1) + " — " + JS.s(enc.get("name")) + " ⚔" if JS.t(enc.get("isGym")) else ("⚔ Pack Encounter ⚔" if JS.t(enc.get("isPack")) else "⚔ Battle " + JS.s(State.battleNumber) + " ⚔"))
	document.getElementById("combat-round-label").textContent = label
	# player-hud-name is set by updateHPBars; set element badge
	var badge = document.getElementById("combat-element-badge")
	var gym = Encounters.currentGymDef()
	var zoneEl = (gym.get("element") if JS.t(gym) else State.playerElement)
	var zoneMeta = (JS.idx(Encounters.CAMP_META, zoneEl) if JS.t(JS.idx(Encounters.CAMP_META, zoneEl)) else {"icon": State.playerEmoji, "color": State.playerColor})
	badge.textContent = JS.s(zoneMeta.get("icon")) + " " + JS.s(zoneEl) + " Zone"
	badge.style.color = zoneMeta.get("color")
	badge.style.borderColor = JS.s(zoneMeta.get("color")) + "44"
	document.getElementById("battle-log").innerHTML = ""
	MapLogic.switchCombatTab("actions")
	UI.showScreen("combat-screen")
	# Apply deck layout immediately so spellbook UI never flashes
	var _cs = document.getElementById("combat-screen")
	if JS.t(_cs):
		_cs.classList.add("deck-mode-active")
	# Show sandbox buttons
	var isSandbox = Constants.sandboxMode
	var skipBtn = document.getElementById("sandbox-skip-btn")
	if JS.t(skipBtn):
		skipBtn.style.display = ("block" if JS.t(isSandbox) else "none")
	var enemyBtn = document.getElementById("sandbox-enemy-btn")
	if JS.t(enemyBtn):
		enemyBtn.style.display = ("block" if JS.t(isSandbox) else "none")
	var spellBtn = document.getElementById("sandbox-spell-btn")
	if JS.t(spellBtn):
		spellBtn.style.display = ("block" if JS.t(isSandbox) else "none")
	var bookBtn = document.getElementById("sandbox-book-btn")
	if JS.t(bookBtn):
		bookBtn.style.display = ("block" if JS.t(isSandbox) else "none")
	# Sandbox zone switcher for combat
	var combatZoneBar = document.getElementById("sandbox-zone-combat-bar")
	if JS.t(combatZoneBar):
		if JS.t(Constants.sandboxMode):
			combatZoneBar.style.display = "flex"
			combatZoneBar.innerHTML = "<span style=\"color:#888;font-size:.6rem;align-self:center;margin-right:4px;\">ZONE:</span>"
			for gym_2 in JS.iter(JS.or_(Encounters.GYM_ROSTER, [])):
				var btn = document.createElement("button")
				btn.textContent = JS.s(gym_2.get("emoji")) + " " + JS.s(gym_2.get("element"))
				var isActive = JS.eq(State.combat.get("activeZoneElement"), gym_2.get("element"))
				btn.style.cssText = "background:" + (JS.s(gym_2.get("color")) + "33" if isActive else "#111") + ";border:1px solid " + JS.s((gym_2.get("color") if isActive else "#333")) + ";color:" + JS.s((gym_2.get("color") if isActive else "#888")) + ";border-radius:4px;padding:2px 7px;font-size:.58rem;font-family:'Cinzel',serif;cursor:pointer;"
				btn.onclick = func(): return Sandbox.sandboxSetCombatZone(gym_2.get("element"))
				combatZoneBar.appendChild(btn)
		else:
			combatZoneBar.style.display = "none"
	# Init canvas AFTER screen is visible so clientWidth is correct
	var _fn2 = func():
		Sprites.initBattleCanvas()
		Sprites.startBattleLoop()
		UI.renderEnemyCards()
		UI.updateHPBars()
		UI.updateStatsUI()
		UI.renderSpellButtons()
		Combat.renderCombatInventory()
		UI.renderStatusTags()
		Combat.updateActionUI()
	JS.setTimeout(_fn2, 0)
	if JS.t(enc.get("isGym")):
		UI.log_("🏛 Gym " + JS.s(State.currentGymIdx + 1) + " — " + JS.s(enc.get("name")) + " steps forward!", "system")
		if JS.t(enc.get("signature")):
			UI.log_(enc.get("signature"), "system")
		UI.log_("✦ You enter fully healed. (" + JS.s(Helpers.maxHPFor("player")) + "/" + JS.s(Helpers.maxHPFor("player")) + ")", "heal")
	elif JS.t(enc.get("isPack")):
		UI.log_("⚔ " + JS.s(enc.get("packName")) + " attacks! (" + JS.s(len(enc.get("members"))) + " enemies)", "system")
	else:
		UI.log_(JS.s(enc.get("name")) + " appears!", "system")
	if JS.t(State.combat.get("activeZoneElement")):
		var zd = JS.idx(Encounters.ZONE_EFFECTS, State.combat.get("activeZoneElement"))
		if JS.t(zd):
			UI.log_("🌍 Zone Effect active: " + JS.s(zd.get("desc")), "system")
	UI.log_("Select your target. All enemies act each round.", "system")
	if (JS.t(enc.get("isGym")) and JS.t(enc.get("gymEntryEffect"))):
		JS.setTimeout(func(): return applyGymEntryEffect(enc.get("gymEntryEffect"), enc), 600)
	JS.setTimeout(Combat.startRound, (1100 if (JS.t(enc.get("isGym")) and JS.t(enc.get("gymEntryEffect"))) else 400))

func _loadGauntletBoss():
	if Encounters._gauntletBossIdx >= len(Encounters.GAUNTLET_ROSTER):
		return
	var enc = JS.idx(Encounters.GAUNTLET_ROSTER, Encounters._gauntletBossIdx)
	if enc.get("name") == "The Dark One":
		DarkOneIntro.playDarkOneIntro(func(): return loadBattle(JS.merge([enc, {"_rewardType": "gym"}])))
	else:
		loadBattle(JS.merge([enc, {"_rewardType": "gym"}]))

func applyGymEntryEffect(effect = null, enc = null):
	if JS.t(State.combat.get("over")):
		return
	var gym = JS.idx(State.combat.get("enemies"), 0)
	if not JS.t(gym):
		return
	match effect:
		"frozen_ground":
			State.status.get("player").frostStacks = (JS.or_(State.status.get("player").get("frostStacks"), 0)) + 6
			UI.log_("❄️ " + JS.s(enc.get("name")) + " casts Frozen Ground! You are afflicted with 6 Frost!", "enemy")
			UI.renderStatusTags()
		"chain_shock":
			State.status.get("player").shockStacks = (JS.or_(State.status.get("player").get("shockStacks"), 0)) + 3
			UI.log_("⚡ " + JS.s(enc.get("name")) + " opens with Chain Shock! +3 Shock!", "enemy")
		"fortify":
			gym.get("status").block = (JS.or_(gym.get("status").get("block"), 0)) + 30
			gym.get("status").stoneStacks = (JS.or_(gym.get("status").get("stoneStacks"), 0)) + 3
			UI.log_("🪨 " + JS.s(enc.get("name")) + " FORTIFIES! +30 Block, +3 Stone stacks!", "enemy")
			UI.renderEnemyCards()
		"summon_treant":
			State.combat.get("summons").append({
				"name": "Gym Treant",
				"emoji": "🌳",
				"hp": 100,
				"maxHP": 100,
				"dmg": 35 + floori(State.player.get("attackPower") / 2.0),
				"cd": 0,
				"id": JS.dateNow(),
				"rootChance": 0.75,
			})
			UI.log_("🌿 " + JS.s(enc.get("name")) + " summons a mighty Treant!", "enemy")
			UI.renderSummonsRow()
