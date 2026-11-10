# BattleReward — generated from js/logic/battleReward.js by tools/js2gd.js
extends Node

# ===== battleReward.js =====
# ─── BATTLE REWARD + PROGRESSION ─────────────────────────────────────────────
# Spell/passive/upgrade choices offered after battles and gym clears.
# ── Spell tiers ──────────────────────────────────────────────────────────────
# primary   → offered at level 2
# secondary → offered at levels 5, 10, 20, 25, ...
# legendary → offered at levels 15, 30, ... (tertiary)
# Starters are isStarter:true and never appear in pools.
# ── XP / Level up ────────────────────────────────────────────────────────────
# ===============================
# BATTLE REWARD SYSTEM
# ===============================
# How many battles until next spell reward
var SPELL_REWARD_EVERY = 3
var _currentRewardPool = null
var _currentRewardIsGym = false
var _currentRewardTier = "minor"
var _PBL_REWARD_CFG = null
var _pendingLootInProgress = false
var _lootGoldClaimed = false
var _lootItemClaimed = false
var _lootRewardClaimed = false
# ── Dynamic zone reward sequence ──────────────────────────────────────────────
# Generated fresh each zone so every run has a different reward layout.
# _zoneRewardSequence[slot] gives the reward type for that battle slot (1-indexed).
var _zoneRewardSequence = null
var _zoneRivalSlot = -1

func _boot():
	_currentRewardPool = []
	# ── POST-BATTLE LOOT SCREEN ──────────────────────────────────────────────────
	_PBL_REWARD_CFG = {
		"gym": {"emoji": "🏆", "label": "Gym Reward", "color": "#d4a0ff"},
		"rival": {"emoji": "🧢", "label": "Rival Reward", "color": "#9a6aee"},
		"primary_spell": {"emoji": "✦", "label": "Starting Spell", "color": "#c080ff"},
		"spell": {"emoji": "📜", "label": "Spell Reward", "color": "#a080ff"},
		"incantation": {"emoji": "📜", "label": "Incantation", "color": "#e08030"},
		"minor": {"emoji": "💰", "label": "Pick Up", "color": "#c8a060"},
		"major": {"emoji": "⚡", "label": "Power Up", "color": "#e8d060"},
	}

# Pool of stat/run rewards
func buildStatRewardPool():
	var _fn1 = func():
		State.player.attackPower += 5
	var _fn2 = func():
		State.player.effectPower += 5
	var _fn3 = func():
		State.player.defense += 5
	var _fn4 = func():
		State.player.baseMaxHPBonus = (JS.or_(State.player.get("baseMaxHPBonus"), 0)) + 15
		State.player.hp = min(Helpers.maxHPFor("player"), State.player.get("hp") + 15)
	var _fn5 = func():
		State.player.gold += 50
	var _fn6 = func():
		Helpers.applyHeal("player", floori(Helpers.maxHPFor("player") * 0.4), "✦ Reward Heal")
	var pool = [
		{
			"label": "+5 Attack Power",
			"emoji": "⚔",
			"tag": "Stat",
			"desc": "Permanently gain +5 Attack Power.",
			"apply": _fn1,
		},
		{
			"label": "+5 Effect Power",
			"emoji": "✦",
			"tag": "Stat",
			"desc": "Permanently gain +5 Effect Power.",
			"apply": _fn2,
		},
		{"label": "+5 Defense", "emoji": "🛡", "tag": "Stat", "desc": "Permanently gain +5 Defense.", "apply": _fn3},
		{
			"label": "+15 Max HP",
			"emoji": "❤",
			"tag": "Stat",
			"desc": "Permanently increase max HP by 15.",
			"apply": _fn4,
		},
		{"label": "+50 Gold", "emoji": "✦", "tag": "Gold", "desc": "Gain 50 gold for the shop.", "apply": _fn5},
		{"label": "Heal 40%", "emoji": "💚", "tag": "Heal", "desc": "Restore 40% of your max HP.", "apply": _fn6},
	]
	# Run rewards — rarer, appear occasionally
	var roll = randf()
	if roll < 0.18:
		var _fn7 = func():
			State.player.bonusActions = (JS.or_(State.player.get("bonusActions"), 0)) + 1
			UI.log_("⚡ Extra action per turn gained!", "win")
		pool.append({
			"label": "Extra Action",
			"emoji": "⚡",
			"tag": "Run Reward",
			"desc": "Permanently gain +1 action per turn in combat.",
			"apply": _fn7,
		})
	if (roll >= 0.15 and roll < 0.3):
		var _fn8 = func():
			State.player.revives = (JS.or_(State.player.get("revives"), 0)) + 1
			UI.log_("❤ Extra life gained!", "win")
		pool.append({
			"label": "Extra Life",
			"emoji": "❤",
			"tag": "Run Reward",
			"desc": "Gain one extra life — survive a killing blow.",
			"apply": _fn8,
		})
	if (roll >= 0.25 and roll < 0.4):
		var b = State.activeBook()
		var usedSpells = (len(JS.arr(b.get("spells")).filter(func(s = null): return not JS.t(s.get("isBuiltin")))) if JS.t(b) else 0)
		var spellCap = (b.get("spellSlots") if JS.t(b) else 6)
		if usedSpells >= floori(spellCap * 0.75):
			var _fn9 = func():
				var bk = State.activeBook()
				if JS.t(bk):
					bk.spellSlots += 1
					UI.log_("📖 Spell slot added to " + JS.s(bk.get("name")) + "!", "win")
			pool.append({
				"label": "Extra Spell Slot",
				"emoji": "📖",
				"tag": "Run Reward",
				"desc": "Your active spellbook gains +1 spell slot this run.",
				"apply": _fn9,
			})
	if (roll >= 0.3 and roll < 0.45):
		var passiveCap = JS.or_(State.player.get("passiveSlots"), 6)
		if len(JS.or_(State.player.get("passives"), [])) >= floori(passiveCap * 0.75):
			var _fn10 = func():
				State.player.passiveSlots = (JS.or_(State.player.get("passiveSlots"), 6)) + 1
				UI.log_("📿 Passive roster expanded!", "win")
			pool.append({
				"label": "Extra Passive Slot",
				"emoji": "📿",
				"tag": "Run Reward",
				"desc": "Expand your passive roster by +1 slot this run.",
				"apply": _fn10,
			})
	if (roll >= 0.35 and roll < 0.5):
		var _fn11 = func():
			State.player._rerolls = (JS.or_(State.player.get("_rerolls"), 0)) + 1
			UI.log_("🎲 Reroll token gained!", "win")
		pool.append({
			"label": "Reroll Token",
			"emoji": "🎲",
			"tag": "Run Reward",
			"desc": "Gain 1 reroll — re-draw your choices after any future battle.",
			"apply": _fn11,
		})
	return pool

func grantRandomLegendary():
	var elements = [State.playerElement] + JS.arr(JS.or_(State.player.get("unlockedElements"), []))
	# Check all books for already-owned spells
	var _allOwned = []
	for b in JS.iter(JS.or_(State.player.get("spellbooks"), [])):
		for s in JS.iter(b.get("spells")):
			if not JS.t(s.get("isBuiltin")):
				_allOwned.append(s.id)
	var owned = JSSet.new(_allOwned)
	# Build legendary spell pool
	var spellPool = []
	for el in JS.iter(elements):
		for s in JS.iter(JS.values(Spells.SPELL_CATALOGUE)):
			if not JS.eq(s.get("element"), el):
				continue
			if owned.has(s.id):
				continue
			if (JS.or_(s.get("tier"), "secondary")) == "legendary":
				spellPool.append({"type": "spell", "def": s})
	# Build legendary passive pool — deduplicate against global passive list
	var passivePool = []
	var allOwnedPassives = JSSet.new(JS.or_(State.player.get("passives"), []))
	for el in JS.iter(elements):
		for p in JS.iter(JS.or_(JS.idx(Passives.PASSIVE_CHOICES, el), [])):
			if not JS.t(p.get("legendary")):
				continue
			if allOwnedPassives.has(p.id):
				continue
			passivePool.append({"type": "passive", "def": p})
	var combined = JS.arr(spellPool) + JS.arr(passivePool)
	if not JS.t(len(combined)):
		UI.log_("✦ Gym reward: nothing new to grant (all legendaries owned).", "win")
		return
	var pick = JS.idx(combined, floori(randf() * len(combined)))
	if pick.get("type") == "spell":
		var gymRarity = Incantations.rollSpellRarity()
		Spells.addSpellById(pick.get("def").id, false, gymRarity)
		var rarityLabel = (" (" + (JS.charAt(gymRarity, 0).to_upper() + JS.s(JS.slice(gymRarity, 1))) + ")" if gymRarity != "dim" else "")
		UI.log_("✦ Legendary spell unlocked: " + JS.s(pick.get("def").get("emoji")) + " " + JS.s(pick.get("def").get("name")) + rarityLabel + "!", "win")
	else:
		State.addPassiveToBook(pick.get("def").id)
		UI.log_("✦ Legendary passive unlocked: " + JS.s(pick.get("def").get("emoji")) + " " + JS.s(pick.get("def").title) + "!", "win")

func toggleRewardLog(btn = null):
	var panel = document.getElementById("br-log-panel")
	if not JS.t(panel):
		return
	var open = panel.style.get("display") != "none"
	if open:
		panel.style.display = "none"
		btn.textContent = "📋 Battle Log ▾"
	else:
		var src = document.getElementById("battle-log")
		panel.innerHTML = (src.innerHTML if JS.t(src) else "<span style=\"color:#333\">No log.</span>")
		panel.style.display = "block"
		panel.scrollTop = panel.scrollHeight
		btn.textContent = "📋 Battle Log ▴"

func _checkPblAllClaimed():
	if ((JS.t(_lootGoldClaimed) and JS.t(_lootItemClaimed)) and JS.t(_lootRewardClaimed)):
		var btn = document.getElementById("pbl-continue-btn")
		if JS.t(btn):
			btn.style.display = "block"

func _makePblClickCard(card = null):
	# Shared "claimed" visual for interactive cards
	card.classList.add("pbl-card-reward")
	return card

func _claimPblCard(card = null, onClaim = null):
	card.style.opacity = "0.55"
	card.style.cursor = "default"
	card.onclick = null
	var arrow = card.querySelector(".pbl-card-arrow")
	if JS.t(arrow):
		arrow.textContent = "✓"
	var sub = card.querySelector(".pbl-card-sub")
	if JS.t(sub):
		sub.textContent = "✓ Collected"
	if JS.t(onClaim):
		onClaim.call()

func showPostBattleLoot(isGym = null, isSpellBattle = null, isRival = null, gold = null, itemId = null):
	window._lastBattleWasGym = (not (not JS.t(isGym)))
	_pendingLootInProgress = true
	_lootGoldClaimed = false
	_lootItemClaimed = (not JS.t(itemId))
	# no item = auto-claimed
	_lootRewardClaimed = false
	var cards = document.getElementById("pbl-cards")
	if not JS.t(cards):
		showBattleRewardScreen(isGym, isSpellBattle, isRival)
		return
	cards.innerHTML = ""
	# Gold card (interactive — click to collect)
	var goldCard = document.createElement("div")
	goldCard.className = "pbl-card pbl-card-gold pbl-card-reward"
	goldCard.innerHTML = "<div class=\"pbl-card-icon\">💰</div><div class=\"pbl-card-body\"><div class=\"pbl-card-label\">+" + JS.s(gold) + " Gold</div><div class=\"pbl-card-sub\">Click to collect</div></div><div class=\"pbl-card-arrow\">›</div>"
	var _fn13 = func():
		var _fn12 = func():
			_lootGoldClaimed = true
			_checkPblAllClaimed()
		return _claimPblCard(goldCard, _fn12)
	goldCard.onclick = _fn13
	cards.appendChild(goldCard)
	# Item card (interactive — click to collect)
	if ((JS.t(itemId) and true) and JS.t(JS.idx(Items.ITEM_CATALOGUE, itemId))):
		var cat = JS.idx(Items.ITEM_CATALOGUE, itemId)
		var itemCard = document.createElement("div")
		itemCard.className = "pbl-card pbl-card-item pbl-card-reward"
		itemCard.innerHTML = "<div class=\"pbl-card-icon\">" + JS.s(cat.get("emoji")) + "</div><div class=\"pbl-card-body\"><div class=\"pbl-card-label\">" + JS.s(cat.get("name")) + "</div><div class=\"pbl-card-sub\">Click to collect</div></div><div class=\"pbl-card-arrow\">›</div>"
		var _fn15 = func():
			var _fn14 = func():
				_lootItemClaimed = true
				_checkPblAllClaimed()
			return _claimPblCard(itemCard, _fn14)
		itemCard.onclick = _fn15
		cards.appendChild(itemCard)
	# Reward card (interactive — click to open choice screen)
	var rewardType = ("gym" if JS.t(isGym) else ("rival" if JS.t(isRival) else (State.combat.get("_chosenRewardType") if JS.t(State.combat.get("_chosenRewardType")) else getZoneRewardType(State.zoneBattleCount, State.currentGymIdx))))
	var cfg = JS.or_(JS.idx(_PBL_REWARD_CFG, rewardType), _PBL_REWARD_CFG.get("minor"))
	var rewardCard = document.createElement("div")
	rewardCard.className = "pbl-card pbl-card-reward"
	rewardCard.id = "pbl-reward-card"
	rewardCard.innerHTML = "<div class=\"pbl-card-icon\" style=\"color:" + JS.s(cfg.get("color")) + "\">" + JS.s(cfg.get("emoji")) + "</div><div class=\"pbl-card-body\"><div class=\"pbl-card-label\" style=\"color:" + JS.s(cfg.get("color")) + "\">" + JS.s(cfg.get("label")) + "</div><div class=\"pbl-card-sub\">Click to choose</div></div><div class=\"pbl-card-arrow\">›</div>"
	var _fn16 = func():
		rewardCard.style.opacity = "0.5"
		rewardCard.style.cursor = "default"
		rewardCard.onclick = null
		var sub = rewardCard.querySelector(".pbl-card-sub")
		if JS.t(sub):
			sub.textContent = "✓ Claimed"
		showBattleRewardScreen(isGym, isSpellBattle, isRival)
	rewardCard.onclick = _fn16
	cards.appendChild(rewardCard)
	# Continue hidden until all cards claimed
	var continueBtn = document.getElementById("pbl-continue-btn")
	if JS.t(continueBtn):
		continueBtn.style.display = "none"
	var logPanel = document.getElementById("pbl-log-panel")
	if JS.t(logPanel):
		logPanel.style.display = "none"
	UI.showScreen("post-battle-loot-screen")

func _afterRewardChosen():
	if JS.t(_pendingLootInProgress):
		_pendingLootInProgress = false
		_lootRewardClaimed = true
		# Mark reward card as claimed visually
		var rc = document.getElementById("pbl-reward-card")
		if JS.t(rc):
			rc.style.opacity = "0.55"
			rc.style.cursor = "default"
			rc.onclick = null
			var s = rc.querySelector(".pbl-card-sub")
			if JS.t(s):
				s.textContent = "✓ Claimed"
			var a = rc.querySelector(".pbl-card-arrow")
			if JS.t(a):
				a.textContent = "✓"
		_checkPblAllClaimed()
		UI.showScreen("post-battle-loot-screen")
	else:
		MapCanvas.showMap()

func togglePblLog(btn = null):
	var panel = document.getElementById("pbl-log-panel")
	if not JS.t(panel):
		return
	var open = panel.style.get("display") != "none"
	if open:
		panel.style.display = "none"
		btn.textContent = "📋 Battle Log ▾"
	else:
		var src = document.getElementById("battle-log")
		panel.innerHTML = (src.innerHTML if JS.t(src) else "<span style=\"color:#333\">No log.</span>")
		panel.style.display = "block"
		panel.scrollTop = panel.scrollHeight
		btn.textContent = "📋 Battle Log ▴"

func showBattleRewardScreen(isGym = null, isSpellBattle = null, isRival = null):
	# Reset log panel to closed state
	var brLog = document.getElementById("br-log-panel")
	if JS.t(brLog):
		brLog.style.display = "none"
	var brLogBtn = document.querySelector("#battle-reward-screen button[onclick*=\"toggleRewardLog\"]")
	if JS.t(brLogBtn):
		brLogBtn.textContent = "📋 Battle Log ▾"
	_currentRewardIsGym = isGym
	var badge = document.getElementById("br-badge")
	var title = document.getElementById("br-title")
	var sub = document.getElementById("br-sub")
	var rewardType = ("gym" if JS.t(isGym) else ("rival" if JS.t(isRival) else (State.combat.get("_chosenRewardType") if JS.t(State.combat.get("_chosenRewardType")) else getZoneRewardType(State.zoneBattleCount, State.currentGymIdx))))
	if JS.t(badge):
		badge.textContent = ("Gym Clear" if JS.t(isGym) else ("Rival Defeated" if JS.t(isRival) else "Battle " + JS.s(State.battleNumber)))
	if rewardType == "gym":
		_doGymRewardFlow()
		return
	if rewardType == "rival":
		showPassiveChoiceScreen("rival")
		return
	if rewardType == "incantation":
		if JS.t(title):
			title.textContent = "✦ Incantation ✦"
		if JS.t(sub):
			sub.textContent = "Choose a spell to upgrade."
		showIncantationChoiceScreen(State.battleNumber)
		return
	if rewardType == "primary_spell":
		if JS.t(title):
			title.textContent = "✦ Starting Spell ✦"
		if JS.t(sub):
			sub.textContent = "Choose your primary spell."
		showSpellChoiceScreen(State.battleNumber, "primary")
		return
	if (rewardType == "spell" or rewardType == "secondary_spell"):
		if JS.t(title):
			title.textContent = "✦ Card Reward ✦"
		if JS.t(sub):
			sub.textContent = "Choose a card to add to your deck."
		showSpellChoiceScreen(State.battleNumber, "secondary")
		return
	if rewardType == "minor":
		if JS.t(title):
			title.textContent = "✦ Pick Up ✦"
		if JS.t(sub):
			sub.textContent = "Choose a reward."
		_currentRewardTier = "minor"
		_renderUpgradeChoices("minor")
		UI.showScreen("battle-reward-screen")
		return
	if rewardType == "major":
		if JS.t(title):
			title.textContent = "✦ Power Up ✦"
		if JS.t(sub):
			sub.textContent = "Choose your reward."
		_currentRewardTier = "major"
		_renderUpgradeChoices("major")
		UI.showScreen("battle-reward-screen")
		return
	# fallback
	if JS.t(title):
		title.textContent = "✦ Upgrade ✦"
	if JS.t(sub):
		sub.textContent = "Choose a reward."
	_currentRewardTier = "minor"
	_renderUpgradeChoices("minor")
	UI.showScreen("battle-reward-screen")

func initZoneRewardSequence():
	var isZone1 = JS.eq(State.currentGymIdx, 0)
	_zoneRivalSlot = (6 + floori(randf() * 4) if isZone1 else 5 + floori(randf() * 4))
	# Weighted random reward type picker (20% spell, 30% incant, 30% minor, 20% major)
	var _rewardTypes = ["spell", "incantation", "minor", "major"]
	var _rewardWeights = [20, 30, 30, 20]
	var _fn17 = func(exclude = null):
		if exclude == null:
			exclude = null
		var types = JS.arr(_rewardTypes).filter(func(t = null): return not JS.eq(t, exclude))
		var weights = JS.filter(_rewardWeights, func(_u = null, i = null): return not JS.eq(JS.idx(_rewardTypes, i), exclude))
		var total = JS.reduce(weights, func(s = null, w = null): return s + w, 0)
		var r = randf() * total
		for i in range(len(types)):
			r -= weights[i]
			if r <= 0:
				return types[i]
		return JS.idx(types, len(types) - 1)
	var _pickReward = _fn17
	# Generate pairs for slots 2–14 (all regular battle slots before forced gym at 15)
	# Each pair guaranteed different types; same type can recur across screens
	_zoneRewardSequence = [null, ("primary_spell" if isZone1 else "spell")]
	for i in range(13):
		var typeA = _pickReward.call()
		var typeB = _pickReward.call(typeA)
		_zoneRewardSequence.append([typeA, typeB])

# encIdx: 0 = left encounter, 1 = right encounter
func getZoneRewardType(battleSlot = null, gymIdx = null, encIdx = null):
	if encIdx == null:
		encIdx = 0
	if ((JS.t(_zoneRewardSequence) and battleSlot >= 1) and battleSlot < len(_zoneRewardSequence)):
		var entry = JS.idx(_zoneRewardSequence, battleSlot)
		if (entry is Array):
			return JS.or_(JS.or_(JS.idx(entry, encIdx), JS.idx(entry, 0)), "minor")
		return JS.or_(entry, "minor")
	return "minor"

func buildMinorUpgradePool():
	# Pick Ups — items, gold, utility. Small and consumable-feeling. No big stat upgrades.
	var _fn18 = func():
		State.player.gold += 100
		UI.log_("💰 +100 gold!", "win")
	var _fn19 = func():
		BattleLoad.restoreAllPP()
		UI.log_("🔮 All spell PP restored!", "win")
	var _fn20 = func():
		Helpers.applyHeal("player", floori(Helpers.maxHPFor("player") * 0.4), "💚 Potion")
	var _fn21 = func():
		State.player._rerolls = (JS.or_(State.player.get("_rerolls"), 0)) + 3
		UI.log_("🎲 +3 Reroll tokens!", "win")
	var _fn22 = func():
		State.player.attackPower += 6
		UI.updateStatsUI()
	var _fn23 = func():
		State.player.effectPower += 6
		UI.updateStatsUI()
	var _fn24 = func():
		State.player.defense += 6
		UI.updateStatsUI()
	var _fn25 = func():
		State.player.baseMaxHPBonus = (JS.or_(State.player.get("baseMaxHPBonus"), 0)) + 18
		State.player.hp = min(Helpers.maxHPFor("player"), State.player.get("hp") + 18)
	var pool = [
		{
			"label": "Gold Pouch",
			"emoji": "💰",
			"tag": "Pick Up",
			"desc": "Find 100 gold on the ground.",
			"apply": _fn18,
		},
		{
			"label": "Mana Crystal",
			"emoji": "🔮",
			"tag": "Pick Up",
			"desc": "Restore all spell PP to full.",
			"apply": _fn19,
		},
		{
			"label": "Healing Potion",
			"emoji": "💚",
			"tag": "Pick Up",
			"desc": "Drink up — restore 40% of your max HP.",
			"apply": _fn20,
		},
		{
			"label": "Reroll Cache",
			"emoji": "🎲",
			"tag": "Pick Up",
			"desc": "Gain 3 reroll tokens for any future reward screen.",
			"apply": _fn21,
		},
		{
			"label": "Sharpening Stone",
			"emoji": "⚔️",
			"tag": "Pick Up",
			"desc": "Quick maintenance — gain +6 Attack Power.",
			"apply": _fn22,
		},
		{
			"label": "Focus Charm",
			"emoji": "✦",
			"tag": "Pick Up",
			"desc": "Attune your magic — gain +6 Effect Power.",
			"apply": _fn23,
		},
		{
			"label": "Leather Brace",
			"emoji": "🛡️",
			"tag": "Pick Up",
			"desc": "Strap it on — gain +6 Defense.",
			"apply": _fn24,
		},
		{
			"label": "Vitality Tonic",
			"emoji": "❤️",
			"tag": "Pick Up",
			"desc": "A fortifying brew — permanently gain +18 max HP.",
			"apply": _fn25,
		},
	]
	return pool

func buildMajorUpgradePool():
	# Power Ups — structural upgrades only. Always show 3.
	# Spell Slot and Passive Slot are near-guaranteed anchors (high weight).
	# Extra Action appears ~44% of the time. Extra Life has reduced/capped odds.
	var revives = JS.or_(State.player.get("revives"), 0)
	var lifeWeight = (0 if revives >= 3 else JS.nn(JS.idx([45, 30, 15], revives), 0))
	var bookWeight = (75 if len(JS.or_(State.player.get("spellbooks"), [])) < 3 else 0)
	var _spellSlotBook = State.activeBook()
	var _usedSpells = (len(JS.arr(_spellSlotBook.get("spells")).filter(func(s = null): return not JS.t(s.get("isBuiltin")))) if JS.t(_spellSlotBook) else 0)
	var _spellCap = (_spellSlotBook.get("spellSlots") if JS.t(_spellSlotBook) else 6)
	var _passiveCap = JS.or_(State.player.get("passiveSlots"), 6)
	var _showSpellSlot = _usedSpells >= floori(_spellCap * 0.75)
	var _showPassiveSlot = len(JS.or_(State.player.get("passives"), [])) >= floori(_passiveCap * 0.75)
	var _fn26 = func():
		var b = State.activeBook()
		if JS.t(b):
			b.spellSlots += 1
			UI.log_("📖 Spell slot added!", "win")
	var _fn27 = func():
		State.player.passiveSlots = (JS.or_(State.player.get("passiveSlots"), 6)) + 1
		UI.log_("📿 Passive roster expanded!", "win")
	var _fn28 = func():
		State.player.bonusActions = (JS.or_(State.player.get("bonusActions"), 0)) + 1
		UI.log_("⚡ Extra action per turn!", "win")
	var _fn29 = func():
		State.player.revives = (JS.or_(State.player.get("revives"), 0)) + 1
		UI.log_("❤ Extra life gained!", "win")
	var _fn30 = func():
		_showPickupBookChoice()
	var candidates = JS.arr([
		{
			"w": (90 if _showSpellSlot else 0),
			"label": "Extra Spell Slot",
			"emoji": "📖",
			"tag": "Power Up",
			"desc": "+1 spell slot in your active spellbook.",
			"apply": _fn26,
		},
		{
			"w": (80 if _showPassiveSlot else 0),
			"label": "Extra Passive Slot",
			"emoji": "📿",
			"tag": "Power Up",
			"desc": "+1 passive slot in your global roster.",
			"apply": _fn27,
		},
		{
			"w": max(22, 66 - ((JS.or_(State.player.get("bonusActions"), 0)) * 20)),
			"label": "Extra Action",
			"emoji": "⚡",
			"tag": "Power Up",
			"desc": "Permanently gain +1 action per turn in combat.",
			"apply": _fn28,
		},
		{
			"w": lifeWeight,
			"label": "Extra Life",
			"emoji": "❤️",
			"tag": "Power Up",
			"desc": "Survive one killing blow — revive at 75% HP.",
			"apply": _fn29,
		},
		{
			"w": bookWeight,
			"label": "New Deck",
			"emoji": "🃏",
			"tag": "Power Up",
			"desc": "Add a new deck to your arsenal. Choose from 3 options.",
			"_modal": true,
			"apply": _fn30,
		},
	]).filter(func(c = null): return c.get("w") > 0)
	# Weighted pick without replacement — return exactly 3
	var chosen = []
	var remaining = JS.arr(candidates)
	var target = min(3, len(remaining))
	while (len(chosen) < target and len(remaining) > 0):
		var total = JS.reduce(remaining, func(s = null, c = null): return s + c.get("w"), 0)
		var r = randf() * total
		var i = 0
		while i < len(remaining):
			r -= remaining[i].get("w")
			if r <= 0:
				chosen.append(JS.idx(JS.splice(remaining, i, 1), 0))
				break
			i += 1
	return chosen

func _showPickupBookChoice():
	var choices = _buildBookDiscoveryChoices(3)
	var cont = document.getElementById("br-choices")
	if (not JS.t(cont) or len(choices) == 0):
		_afterRewardChosen()
		return
	var title = document.getElementById("br-title")
	var sub = document.getElementById("br-sub")
	if JS.t(title):
		title.textContent = "🃏 New Deck"
	if JS.t(sub):
		sub.textContent = "Choose a deck to add to your arsenal."
	cont.innerHTML = ""
	var meta = Artifacts.getMeta()
	for id in JS.iter(choices):
		var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, id)
		if not JS.t(cat):
			continue
		var isOwned = JS.includes(JS.or_(meta.get("ownedBookIds"), []), id)
		var lvl = JS.or_(JS.idx(JS.or_(meta.get("bookUpgradeLevels"), {}), id), 0)
		var rarityColor = ("#d4a0ff" if cat.get("rarity") == "legendary" else ("#80c8ff" if cat.get("rarity") == "generic" else "#c8a060"))
		var rarityLabel = ("✦ Legendary" if cat.get("rarity") == "legendary" else ("⚡ Generic" if cat.get("rarity") == "generic" else (JS.or_(cat.get("element"), "Element")) + " Book"))
		var newBadge = ("" if isOwned else "<span style=\"font-size:.55rem;background:#1a2a0a;border:1px solid #5a8a20;color:#90c040;padding:.1rem .4rem;border-radius:3px;margin-left:.4rem;\">NEW</span>")
		var btn = document.createElement("button")
		btn.className = "prog-choice-btn"
		btn.innerHTML = "\n      <div class=\"pc-tag\">" + rarityLabel + "</div>\n      <div class=\"pc-name\" style=\"color:" + rarityColor + ";\">" + JS.s(cat.get("emoji")) + " " + JS.s(cat.get("name")) + newBadge + "</div>\n      <div class=\"pc-desc\">" + JS.s((JS.idx(cat.get("levelDescs"), lvl) if JS.t(cat.get("levelDescs")) else cat.get("desc"))) + "</div>\n      <div class=\"pc-desc\" style=\"color:#7a4a30;margin-top:2px;\">⚠ " + JS.s(cat.get("negative")) + "</div>"
		var _fn31 = func():
			if not isOwned:
				if not JS.t(meta.get("ownedBookIds")):
					meta.ownedBookIds = []
				if not JS.t(meta.get("unseenBookIds")):
					meta.unseenBookIds = []
				meta.get("ownedBookIds").append(id)
				meta.get("unseenBookIds").append(id)
				Artifacts.saveMeta()
			if len(JS.or_(State.player.get("spellbooks"), [])) < 3:
				var instance = State.makeBookInstance(id)
				if JS.t(instance):
					instance.get("spells").append_array([{"id": "_basic", "emoji": "⚔", "name": "Basic Attack", "baseCooldown": 1, "currentCD": 0, "isBuiltin": true}, {"id": "_armor", "emoji": "🛡", "name": "Armor", "baseCooldown": 0, "currentCD": 0, "isBuiltin": true}])
					State.player.get("spellbooks").append(instance)
					UI.log_("📖 " + JS.s(cat.get("emoji")) + " " + JS.s(cat.get("name")) + " added as book " + JS.s(len(State.player.get("spellbooks"))) + "!", "win")
			_afterRewardChosen()
		btn.onclick = _fn31
		cont.appendChild(btn)

func _renderUpgradeChoices(tier = null):
	var cont = document.getElementById("br-choices")
	if not JS.t(cont):
		return
	cont.innerHTML = ""
	var pool = (buildMajorUpgradePool() if tier == "major" else buildMinorUpgradePool())
	# Major pool already returns exactly 3 weighted picks; minor pool needs random sampling
	var chosen = (pool if tier == "major" else pickRandom(pool, min(4, len(pool))))
	for opt in JS.iter(chosen):
		var btn = document.createElement("button")
		btn.className = "prog-choice-btn"
		btn.innerHTML = "<div class=\"pc-tag\">" + JS.s(opt.get("tag")) + "</div><div class=\"pc-name\">" + JS.s(opt.get("emoji")) + " " + JS.s(opt.get("label")) + "</div><div class=\"pc-desc\">" + JS.s(opt.get("desc")) + "</div>"
		var _fn32 = func():
			JS.callm(opt, "apply", [])
			UI.updateStatsUI()
			if not JS.t(opt.get("_modal")):
				_afterRewardChosen()
		btn.onclick = _fn32
		cont.appendChild(btn)
	var rerollBtn = document.getElementById("br-reroll-btn")
	var rerollCount = document.getElementById("br-reroll-count")
	if JS.t(rerollBtn):
		rerollBtn.style.display = ("inline-block" if (JS.or_(State.player.get("_rerolls"), 0)) > 0 else "none")
		if JS.t(rerollCount):
			rerollCount.textContent = JS.or_(State.player.get("_rerolls"), 0)

# Build weighted book discovery pool (all catalogue books minus ones already in run)
func _buildBookDiscoveryChoices(n = null):
	var meta = Artifacts.getMeta()
	var inRunIds = JSSet.new(JS.filter(JS.arr(JS.or_(State.player.get("spellbooks"), [])).map(func(b = null): return b.get("catalogueId")), JS.t))
	var elements = [State.playerElement] + JS.arr(JS.or_(State.player.get("unlockedElements"), []))
	var pool = []
	for id in JS.iter(JS.keys(Spellbooks.SPELLBOOK_CATALOGUE)):
		if inRunIds.has(id):
			continue
		# already in run
		var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, id)
		var weight = JS.or_(JS.idx({"element": 3, "generic": 2, "legendary": 1}, cat.get("rarity")), 2)
		# Boost weight for matching elements
		if (JS.t(cat.get("element")) and JS.includes(elements, cat.get("element"))):
			weight += 2
		for i in range(ceili(weight)):
			pool.append(id)
	# Shuffle and pick n unique
	var seen = JSSet.new()
	var result = []
	var shuffled = JS.sort(pool, func(): return randf() - 0.5)
	for id in JS.iter(shuffled):
		if not seen.has(id):
			seen.add(id)
			result.append(id)
		if len(result) >= n:
			break
	return result

# Show pick-1-of-3 book discovery screen after a boss
func showBookDiscoveryScreen():
	var meta = Artifacts.getMeta()
	var cont = document.getElementById("bd-choices")
	var badge = document.getElementById("bd-badge")
	var sub = document.getElementById("bd-sub")
	if not JS.t(cont):
		_continueGymFlow()
		return
	var choices = _buildBookDiscoveryChoices(3)
	if len(choices) == 0:
		_continueGymFlow()
		return
	if JS.t(badge):
		badge.textContent = "Boss Clear"
	if JS.t(sub):
		sub.textContent = "A spellbook has revealed itself. Choose one to take with you this run."
	cont.innerHTML = ""
	for id in JS.iter(choices):
		var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, id)
		if not JS.t(cat):
			continue
		var isOwned = JS.includes(JS.or_(meta.get("ownedBookIds"), []), id)
		var lvl = JS.or_(JS.idx(JS.or_(meta.get("bookUpgradeLevels"), {}), id), 0)
		var rarityColor = ("#d4a0ff" if cat.get("rarity") == "legendary" else ("#80c8ff" if cat.get("rarity") == "generic" else "#c8a060"))
		var rarityLabel = ("✦ Legendary" if cat.get("rarity") == "legendary" else ("⚡ Generic" if cat.get("rarity") == "generic" else (JS.or_(cat.get("element"), "Element")) + " Book"))
		var newBadge = ("" if isOwned else "<span style=\"font-size:.55rem;background:#1a2a0a;border:1px solid #5a8a20;color:#90c040;padding:.1rem .4rem;border-radius:3px;margin-left:.4rem;\">NEW</span>")
		var btn = document.createElement("button")
		btn.className = "prog-choice-btn"
		btn.innerHTML = "<div class=\"pc-tag\">" + rarityLabel + "</div>\n      <div class=\"pc-name\" style=\"color:" + rarityColor + ";\">" + JS.s(cat.get("emoji")) + " " + JS.s(cat.get("name")) + newBadge + "</div>\n      <div class=\"pc-desc\">" + JS.s((JS.idx(cat.get("levelDescs"), lvl) if JS.t(cat.get("levelDescs")) else cat.get("desc"))) + "</div>\n      <div style=\"font-size:.58rem;color:#6a4a3a;margin-top:.2rem;\">⚠ " + JS.s(cat.get("negative")) + "</div>"
		var _fn33 = func():
			# Add to permanent collection if not already owned
			if not isOwned:
				if not JS.t(meta.get("ownedBookIds")):
					meta.ownedBookIds = []
				meta.get("ownedBookIds").append(id)
				if not JS.t(meta.get("unseenBookIds")):
					meta.unseenBookIds = []
				meta.get("unseenBookIds").append(id)
				Artifacts.saveMeta()
				UI.log_("✦ New spellbook discovered: " + JS.s(cat.get("emoji")) + " " + JS.s(cat.get("name")) + "!", "win")
			else:
				UI.log_("📖 Picked up " + JS.s(cat.get("emoji")) + " " + JS.s(cat.get("name")) + " for this run.", "win")
			# Add to current run (up to 3 books per run)
			if len(JS.or_(State.player.get("spellbooks"), [])) < 3:
				var instance = State.makeBookInstance(id)
				if JS.t(instance):
					instance.get("spells").append_array([{"id": "_basic", "emoji": "⚔", "name": "Basic Attack", "baseCooldown": 1, "currentCD": 0, "isBuiltin": true}, {"id": "_armor", "emoji": "🛡", "name": "Armor", "baseCooldown": 0, "currentCD": 0, "isBuiltin": true}])
					State.player.get("spellbooks").append(instance)
					UI.log_("📖 " + JS.s(cat.get("name")) + " added to your spellbooks (book " + JS.s(len(State.player.get("spellbooks"))) + ").", "item")
			_continueGymFlow()
		btn.onclick = _fn33
		cont.appendChild(btn)
	UI.showScreen("bookdiscovery-screen")

# Continue the gym flow after book discovery
func _continueGymFlow():
	var hasAnyUnlocked = (len(State.player.get("unlockedElements")) > 0 if JS.t(State.player.get("unlockedElements")) else State.player.get("unlockedElements"))
	var allElements = JS.keys(Spells.STARTER_SPELL)
	var locked = JS.arr(allElements).filter(func(e = null): return (not JS.eq(e, State.playerElement) and not JS.includes(State.player.get("unlockedElements"), e)))
	if (not JS.t(hasAnyUnlocked) or len(locked) > 0):
		showElementUnlockScreen("gym")
	else:
		grantRandomLegendary()
		_afterRewardChosen()

func _doGymRewardFlow():
	# Always show book discovery first, then continue to element unlock / legendary
	showBookDiscoveryScreen()

func _renderStatRewardChoices():
	_renderUpgradeChoices(JS.or_(_currentRewardTier, "minor"))

func rerollBattleReward():
	if (JS.or_(State.player.get("_rerolls"), 0)) <= 0:
		return
	State.player._rerolls -= 1
	_renderStatRewardChoices()

# ── SPELL CHOICE (now standalone, called from reward flow) ──
func processNextLevelUp():
	if len(State.pendingLevelUps) == 0:
		_afterRewardChosen()
		return
	var ev = State.pendingLevelUps.pop_front()
	if ev.get("type") == "gym_legendary":
		grantRandomLegendary()
		_afterRewardChosen()
	elif ev.get("type") == "spellchoice":
		showSpellChoiceScreen(ev.get("level"), JS.or_(ev.get("tier"), "secondary"), JS.or_(ev.get("forElement"), null))
	elif ev.get("type") == "passivechoice":
		showPassiveChoiceScreen(ev.get("level"), JS.or_(ev.get("forElement"), null))
	else:
		_afterRewardChosen()

func showLevelUp():
	_afterRewardChosen()

func closeLevelUp():
	_afterRewardChosen()

# ── SKILL POINT ──
# showSkillPointScreen removed — replaced by battle reward system
func buildSkillPointPool():
	var _fn34 = func():
		State.player.baseMaxHPBonus = (JS.or_(State.player.get("baseMaxHPBonus"), 0)) + 10
		State.player.hp = min(Helpers.maxHPFor("player"), State.player.get("hp") + 10)
	var _fn35 = func():
		Helpers.applyHeal("player", 50, "✦ Skill Point Heal")
	var _fn36 = func():
		State.player.attackPower += 3
	var _fn37 = func():
		State.player.effectPower += 3
	var _fn38 = func():
		State.player.defense += 3
	var opts = [
		{"label": "+10 Max HP", "desc": "Permanently increase your max HP by 10.", "apply": _fn34},
		{"label": "+50 HP Heal", "desc": "Immediately restore 50 HP.", "apply": _fn35},
		{"label": "+3 Attack Power", "desc": "Permanently gain +3 Attack Power — scales hit damage.", "apply": _fn36},
		{
			"label": "+3 Effect Power",
			"desc": "Permanently gain +3 Effect Power — scales status potency.",
			"apply": _fn37,
		},
		{
			"label": "+3 Defense",
			"desc": "Permanently gain +3 Defense — scales armor, healing, and dodge.",
			"apply": _fn38,
		},
	]
	# Add one entry per owned spell for upgrading (skip builtins)
	var _arr39 = JS.iter(State.player.get("spellbook"))
	for idx in range(len(_arr39)):
		var s = _arr39[idx]
		if JS.t(s.get("isBuiltin")):
			continue
		var rank = JS.round(((JS.or_(s.get("dmgMult"), 1.0)) - 1.0) / 0.1)
		var _fn40 = func():
			JS.idx(State.player.get("spellbook"), idx).dmgMult = JS.round(((JS.or_(s.get("dmgMult"), 1.0)) + 0.1) * 100) / 100.0
		opts.append({
			"label": "Upgrade: " + JS.s(s.get("emoji")) + " " + JS.s(s.get("name")) + " (rank " + JS.s(rank) + ")",
			"desc": "+10% damage multiplier. Current: " + JS.s(JS.round((JS.or_(s.get("dmgMult"), 1.0)) * 100)) + "%",
			"apply": _fn40,
		})
	# Basic spell upgrade
	var brank = JS.or_(State.player.get("basicUpgrade"), 0)
	var _fn41 = func():
		State.player.basicDmgMult = JS.round(((JS.or_(State.player.get("basicDmgMult"), 1.0)) + 0.1) * 100) / 100.0
	opts.append({
		"label": "Upgrade: ⚔ Basic Spell (rank " + JS.s(brank) + ")",
		"desc": "+10% damage multiplier to Basic Spell.",
		"apply": _fn41,
	})
	return opts

# ── INCANTATION CHOICE ──
func showIncantationChoiceScreen(level = null):
	var badge = document.getElementById("inc-level-badge")
	if JS.t(badge):
		badge.textContent = ("Battle " + JS.s(level) if (JS.typeof_(level)) == "number" else JS.s(level))
	var cont = document.getElementById("inc-choices")
	if not JS.t(cont):
		_afterRewardChosen()
		return
	cont.innerHTML = ""
	# Collect all owned non-builtin spells that have an incantation config
	var upgradeable = []
	for book in JS.iter(JS.or_(State.player.get("spellbooks"), [])):
		for s in JS.iter(book.get("spells")):
			if JS.t(s.get("isBuiltin")):
				continue
			if JS.t(JS.idx(Incantations.SPELL_INCANTATION_CONFIG, s.id)):
				upgradeable.append(s)
	if len(upgradeable) == 0:
		# No spells to upgrade yet — fall back to minor reward
		_currentRewardTier = "minor"
		_renderUpgradeChoices("minor")
		UI.showScreen("battle-reward-screen")
		return
	var _statLabels = Incantations._STAT_LABELS
	var picks = pickRandom(upgradeable, min(3, len(upgradeable)))
	for spell in JS.iter(picks):
		var display = Incantations.incantationUpgradeDisplay(spell)
		var rarityInfo = JS.or_(JS.idx(Incantations.SPELL_RARITY, JS.or_(spell.get("rarity"), "dim")), Incantations.SPELL_RARITY.get("dim"))
		var rarityColor = JS.or_(rarityInfo.get("color"), "#8a6a30")
		var nextLevel = (JS.or_(spell.get("incantationLevel"), 1)) + 1
		var statLabel = (JS.or_(JS.idx(_statLabels, display.get("stat")), display.get("stat")) if JS.t(display) else "")
		var upgradeStr = (JS.s(statLabel) + ": " + JS.s(display.get("prev")) + " → " + JS.s(display.get("next")) if JS.t(display) else "Level " + JS.s(JS.or_(spell.get("incantationLevel"), 1)) + " → " + JS.s(nextLevel))
		var btn = document.createElement("button")
		btn.className = "prog-choice-btn spell-btn-el"
		btn.style.borderColor = rarityColor
		var _incIconHTML = SpellIcons.spellIconSVG(spell, 48)
		btn.innerHTML = ("<div class=\"pc-tag\" style=\"color:" + rarityColor + ";\">" + JS.s(rarityInfo.get("label")) + " · Level " + JS.s(JS.or_(spell.get("incantationLevel"), 1)) + " → " + JS.s(nextLevel) + "</div>") + ("<div style=\"display:flex;align-items:center;justify-content:center;padding:6px 0 4px;\">" + _incIconHTML + "</div>") + ("<div class=\"pc-name\">" + JS.s(spell.get("name")) + "</div>") + ("<div class=\"pc-desc\">" + (JS.or_(spell.get("desc"), "")) + "</div>") + ("<div class=\"pc-desc\" style=\"color:#c8e0ff;margin-top:2px;\">" + upgradeStr + "</div>")
		var _fn42 = func():
			spell.incantationLevel = (JS.or_(spell.get("incantationLevel"), 1)) + 1
			UI.log_("✦ Incantation: " + JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")) + " upgraded to level " + JS.s(spell.get("incantationLevel")) + "!", "win")
			_afterRewardChosen()
		btn.onclick = _fn42
		cont.appendChild(btn)
	_appendStatPad(cont, 3 - len(picks), _afterRewardChosen)
	UI.showScreen("incantation-screen")

# ── SPELL CHOICE ──
func showSpellChoiceScreen(level = null, tier = null, forElement = null):
	if tier == null:
		tier = "secondary"
	if forElement == null:
		forElement = null
	var duoSpell = [null]
	var tierLabel = ("Primary Spell" if tier == "primary" else ("✦ Legendary Spell" if tier == "legendary" else "Spell"))
	document.getElementById("sc-level-badge").textContent = ("Battle " + JS.s(level) if (JS.typeof_(level)) == "number" else JS.s(level))
	document.querySelector("#spellchoice-screen .prog-title").textContent = ("✦ Legendary Card ✦" if tier == "legendary" else "✦ New Card ✦")
	document.querySelector("#spellchoice-screen .prog-sub").textContent = ("Choose a primary card to start your journey." if tier == "primary" else ("Choose a legendary card." if tier == "legendary" else "Choose a card to add to your deck."))
	var cont = document.getElementById("sc-choices")
	cont.innerHTML = ""
	var pool = buildSpellChoicePool(tier, forElement)
	if len(pool) == 0:
		processNextLevelUp()
		return
	var chosen = pickRandom(pool, min(3, len(pool)))
	# Mark offered spells as seen in the library
	for s in JS.iter(chosen):
		Library.markSpellSeen(s.id)
	# ── Duo spell: bonus 4th option (10% per eligible spell, pick one winner) ──
	duoSpell[0] = null
	if tier == "secondary":
		var eligible = JS.arr(Duos._eligibleDuoSpells()).filter(func(s = null): return not JS.t(JS.find(chosen, func(c = null): return JS.eq(c.id, s.id))))
		var winners = JS.arr(eligible).filter(func(): return randf() < 0.1)
		if len(winners) > 0:
			duoSpell[0] = JS.idx(winners, floori(randf() * len(winners)))
			Library.markSpellSeen(duoSpell[0].id)
	# Inject shared rarity animation keyframes once
	if not JS.t(document.getElementById("inc-preview-styles")):
		var s = document.createElement("style")
		s.id = "inc-preview-styles"
		s.textContent = "\n      @keyframes incStarPulse {\n        0%,100% { opacity:1; filter:brightness(1) drop-shadow(0 0 2px currentColor); transform:scale(1); }\n        50%      { opacity:.5; filter:brightness(2.5) drop-shadow(0 0 6px currentColor); transform:scale(1.4); }\n      }\n      @keyframes incShimmer {\n        0%   { left:-80%; }\n        100% { left:160%; }\n      }\n      @keyframes incFireGlow {\n        0%,100% { opacity:.7; transform:scaleY(1);   filter:blur(2px); }\n        33%     { opacity:1;   transform:scaleY(1.15); filter:blur(1px); }\n        66%     { opacity:.6;  transform:scaleY(.9);   filter:blur(3px); }\n      }\n      @keyframes incBorderPulse {\n        0%,100% { opacity:1; }\n        50%     { opacity:.6; }\n      }\n    "
		document.head.appendChild(s)
	# Rarity card config — mirrors the preview panel exactly
	var _RARITY_CARD_CONFIG = {
		"dim": {
			"label": "DIM",
			"stars": 1,
			"textColor": "#887766",
			"tagColor": "#887766",
			"cardBg": "rgba(0,0,0,.98)",
			"borderGrad": "linear-gradient(to right, #1a1a1a 50%, #2a1a08 100%)",
		},
		"kindled": {
			"label": "KINDLED",
			"stars": 2,
			"textColor": "#c06010",
			"tagColor": "#c06010",
			"cardBg": "rgba(0,0,0,.98)",
			"borderGrad": "linear-gradient(to right, #1a1a1a 50%, #c06010 100%)",
		},
		"blazing": {
			"label": "BLAZING",
			"stars": 3,
			"textColor": "#bb1200",
			"tagColor": "#bb1200",
			"cardBg": "rgba(0,0,0,.98)",
			"borderGrad": "linear-gradient(to right, #1a1a1a 50%, #bb1200 100%)",
		},
		"radiant": {
			"label": "RADIANT",
			"stars": 4,
			"textColor": "#7a5208",
			"tagColor": "#8a6a10",
			"cardBg": "linear-gradient(to right, rgba(0,0,0,.98) 50%, #f0e8c0 100%)",
			"borderGrad": "linear-gradient(to right, #1a1a1a 50%, #d4aa20 100%)",
			"leftTextColor": "#ffffff",
		},
		"merged": {
			"label": "MERGED",
			"stars": 5,
			"textColor": "#ffffff",
			"tagColor": "#00d4c8",
			"cardBg": "linear-gradient(to right, rgba(0,0,0,.98) 50%, rgba(0,80,75,1) 100%)",
			"borderGrad": "linear-gradient(to right, #1a1a1a 50%, #00d4c8 100%)",
			"leftTextColor": "#ffffff",
		},
	}
	for opt in JS.iter(chosen):
		var isAOE = (JS.includes(opt.get("desc").to_lower(), "all") if JS.t(opt.get("desc")) else opt.get("desc"))
		var el = JS.or_(opt.get("element"), "Neutral")
		var rarity = Incantations.rollSpellRarity()
		var cfg = JS.or_(JS.idx(_RARITY_CARD_CONFIG, rarity), _RARITY_CARD_CONFIG.get("dim"))
		var btn = document.createElement("button")
		btn.className = "prog-choice-btn " + ("neutral-btn" if el == "Neutral" else "spell-btn-el")
		var _fn44 = func():
			var _fn43 = func(bIdx = null):
				Spells.addSpellById(opt.id, false, rarity, bIdx)
				processNextLevelUp()
			var doAdd = _fn43
			BookEditor._pickBookDest("spell", opt, doAdd)
		btn.onclick = _fn44
		if true:
			# Kindled / Blazing / Radiant — gradient border wrapper + matching card bg
			var isFire = (rarity == "kindled" or rarity == "blazing")
			var isGradient = JS.includes(cfg.get("cardBg"), "gradient")
			var fireColor = ("rgba(255,120,0,.10)" if rarity == "kindled" else "rgba(255,30,0,.22)")
			var fire = ("<div style=\"position:absolute;bottom:0;right:0;width:55%;height:100%;pointer-events:none;z-index:2;\n             background:linear-gradient(to left," + fireColor + ",transparent);\n             animation:incFireGlow 1.6s ease-in-out infinite;\"></div>" if isFire else "")
			var shimmer = ("<div style=\"position:absolute;top:0;left:-80%;width:45%;height:100%;pointer-events:none;z-index:2;\n             background:linear-gradient(to right,transparent,rgba(255,255,255,.09),transparent);\n             animation:incShimmer 3.5s linear infinite;\"></div>" if isGradient else "")
			var nameColor = JS.or_(cfg.get("leftTextColor"), cfg.get("textColor"))
			var descColor = ("rgba(255,255,255,.75)" if JS.t(cfg.get("leftTextColor")) else "rgba(220,200,180,.75)")
			var wrapperAnim = ("animation:incBorderPulse 1.8s ease-in-out infinite;" if isFire else "")
			btn.style.cssText = "padding:0;display:flex;flex-direction:row;flex-wrap:nowrap;align-items:stretch;overflow:hidden;gap:0;border:none;border-radius:5px;width:100%;position:relative;"
			btn.innerHTML = "\n        " + fire + shimmer + "\n        <div style=\"flex:1;min-width:0;padding:.55rem .65rem;text-align:left;position:relative;z-index:3;\">\n          <div class=\"pc-tag\">" + tierLabel + " · " + el + (" · AOE" if JS.t(isAOE) else "") + "</div>\n          <div class=\"pc-name\" style=\"color:" + JS.s(nameColor) + ";\">" + JS.s(opt.get("emoji")) + " " + JS.s(opt.get("name")) + "</div>\n          <div class=\"pc-desc\" style=\"white-space:normal;color:" + descColor + ";\">" + JS.s(opt.get("desc")) + " · CD:" + JS.s(opt.get("baseCooldown")) + "</div>\n        </div>\n        <div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;min-width:72px;width:72px;padding:4px 6px;flex-shrink:0;align-self:stretch;gap:2px;position:relative;z-index:3;\">\n          <div style=\"display:flex;gap:1px;\">" + JS.join(JS.arrayFrom({"length": cfg.get("stars")}, func(_u = null, i = null): return "<span style=\"font-size:.45rem;color:" + JS.s(cfg.get("tagColor")) + ";display:inline-block;animation:incStarPulse " + JS.s(5.5 + (i * 0.7)) + "s ease-in-out " + JS.s(i * 1.0) + "s infinite;\">✦</span>"), "") + "</div>\n          <div style=\"font-size:.62rem;color:" + JS.s(cfg.get("textColor")) + ";font-family:'Cinzel',serif;font-weight:700;letter-spacing:.06em;text-transform:uppercase;line-height:1.1;text-align:center;\">" + JS.s(cfg.get("label")) + "</div>\n        </div>"
			# Wrapper provides the gradient border (padding trick)
			var wrapper = document.createElement("div")
			wrapper.style.cssText = "padding:3px;background:" + JS.s(cfg.get("borderGrad")) + ";border-radius:7px;" + wrapperAnim
			btn.style.background = cfg.get("cardBg")
			wrapper.appendChild(btn)
			cont.appendChild(wrapper)
	# ── Render duo spell as bonus 4th option (always 'merged' rarity) ──
	if JS.t(duoSpell[0]):
		var cfg = JS.idx(_RARITY_CARD_CONFIG, "merged")
		var el = JS.or_(duoSpell[0].get("element"), "Duo")
		var shimmer = "<div style=\"position:absolute;top:0;left:-80%;width:45%;height:100%;pointer-events:none;z-index:2;\n        background:linear-gradient(to right,transparent,rgba(255,255,255,.09),transparent);\n        animation:incShimmer 3.5s linear infinite;\"></div>"
		var wrapper = document.createElement("div")
		wrapper.style.cssText = "padding:3px;background:" + JS.s(cfg.get("borderGrad")) + ";border-radius:7px;"
		var btn = document.createElement("button")
		btn.className = "prog-choice-btn spell-btn-el"
		btn.style.cssText = "padding:0;display:flex;flex-direction:row;flex-wrap:nowrap;align-items:stretch;overflow:hidden;gap:0;border:none;border-radius:5px;width:100%;position:relative;"
		btn.style.background = cfg.get("cardBg")
		var _fn46 = func():
			var _fn45 = func(bIdx = null):
				Spells.addSpellById(duoSpell[0].id, false, "merged", bIdx)
				processNextLevelUp()
			var doAdd = _fn45
			BookEditor._pickBookDest("spell", duoSpell[0], doAdd)
		btn.onclick = _fn46
		btn.innerHTML = shimmer + "\n      <div style=\"flex:1;min-width:0;padding:.55rem .65rem;text-align:left;position:relative;z-index:3;\">\n        <div class=\"pc-tag\" style=\"color:" + JS.s(cfg.get("tagColor")) + ";\">Merged · " + el + "</div>\n        <div class=\"pc-name\" style=\"color:" + JS.s(cfg.get("leftTextColor")) + ";\">" + JS.s(duoSpell[0].get("emoji")) + " " + JS.s(duoSpell[0].get("name")) + "</div>\n        <div class=\"pc-desc\" style=\"white-space:normal;color:rgba(255,255,255,.75);\">" + JS.s(duoSpell[0].get("desc")) + " · CD:" + JS.s(duoSpell[0].get("baseCooldown")) + "</div>\n      </div>\n      <div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;min-width:72px;width:72px;padding:4px 6px;flex-shrink:0;align-self:stretch;gap:2px;position:relative;z-index:3;\">\n        <div style=\"display:flex;gap:1px;\">" + JS.join(JS.arrayFrom({"length": 5}, func(_u = null, i = null): return "<span style=\"font-size:.45rem;color:" + JS.s(cfg.get("tagColor")) + ";display:inline-block;animation:incStarPulse " + JS.s(5.5 + (i * 0.7)) + "s ease-in-out " + JS.s(i * 1.0) + "s infinite;\">✦</span>"), "") + "</div>\n        <div style=\"font-size:.62rem;color:" + JS.s(cfg.get("textColor")) + ";font-family:'Cinzel',serif;font-weight:700;letter-spacing:.06em;text-transform:uppercase;line-height:1.1;text-align:center;\">" + JS.s(cfg.get("label")) + "</div>\n      </div>"
		wrapper.appendChild(btn)
		cont.appendChild(wrapper)
	var totalShown = len(chosen) + (1 if JS.t(duoSpell[0]) else 0)
	_appendStatPad(cont, 3 - totalShown, processNextLevelUp)
	UI.showScreen("spellchoice-screen")

func buildSpellChoicePool(tier = null, forElement = null):
	if tier == null:
		tier = "secondary"
	if forElement == null:
		forElement = null
	# Check all books for already-owned spells
	var _allOwned = []
	for b in JS.iter(JS.or_(State.player.get("spellbooks"), [])):
		for s in JS.iter(b.get("spells")):
			if not JS.t(s.get("isBuiltin")):
				_allOwned.append(s.id)
	var owned = JSSet.new(_allOwned)
	var elements = ([forElement] if JS.t(forElement) else [State.playerElement] + JS.arr(State.player.get("unlockedElements")))
	var pool = []
	# Build owned tag set for prerequisite checking
	var ownedTagSet = JSSet.new()
	for s in JS.iter(State.player.get("spellbook")):
		var def = JS.idx(Spells.SPELL_CATALOGUE, s.id)
		if (JS.t(def) and JS.t(def.get("tags"))):
			for t in JS.iter(def.get("tags")):
				ownedTagSet.add(t)
	for el in JS.iter(elements):
		for s in JS.iter(JS.values(Spells.SPELL_CATALOGUE)):
			if not JS.eq(s.get("element"), el):
				continue
			if owned.has(s.id):
				continue
			if JS.t(s.get("isStarter")):
				continue
			if (JS.or_(s.get("tier"), "secondary")) != tier:
				continue
			if (JS.t(s.get("requiresTag")) and not ownedTagSet.has(s.get("requiresTag"))):
				continue
			pool.append(s)
	if tier == "secondary":
		for id in JS.iter(Spells.NEUTRAL_SPELL_IDS):
			if not owned.has(id):
				pool.append(JS.idx(Spells.SPELL_CATALOGUE, id))
	return pool

# ── ELEMENT UNLOCK (level 15) ──
func showElementUnlockScreen(level = null):
	document.getElementById("eu-level-badge").textContent = "Level " + JS.s(level) + " — Choose Second Element"
	var c = document.getElementById("eu-element-choices")
	c.innerHTML = ""
	var allElements = JS.arr(JS.keys(Spells.STARTER_SPELL)).filter(func(e = null): return not JS.eq(e, State.playerElement))
	var chosen = pickRandom(allElements, 3)
	for el in JS.iter(chosen):
		var starterSpell = JS.idx(Spells.SPELL_CATALOGUE, JS.idx(Spells.STARTER_SPELL, el))
		var elInfo = {
			"Fire": "🔥",
			"Water": "💧",
			"Ice": "❄️",
			"Lightning": "⚡",
			"Earth": "🪨",
			"Nature": "🌿",
			"Plasma": "🔮",
			"Air": "🌀",
		}
		var btn = document.createElement("button")
		btn.className = "prog-choice-btn spell-btn-el"
		btn.innerHTML = "<div class=\"pc-tag\">Second Element</div>\n      <div class=\"pc-name\">" + (JS.or_(JS.idx(elInfo, el), "✦")) + " " + JS.s(el) + "</div>\n      <div class=\"pc-desc\">Unlocks " + JS.s(el) + " spells and passives. Starter: " + (JS.s(starterSpell.get("emoji")) + " " + JS.s(starterSpell.get("name")) if JS.t(starterSpell) else "—") + "</div>"
		var _fn47 = func():
			State.player.get("unlockedElements").append(el)
			# Plasma always gets its own dedicated spellbook
			if el == "Plasma":
				State.ensurePlasmaBook()
			Spells.addSpellById(JS.idx(Spells.STARTER_SPELL, el))
			# Queue: passive choice for new element, spell choice in new element, then legendary
			State.pendingLevelUps = [
				{"type": "passivechoice", "level": "gym", "forElement": el},
				{"type": "spellchoice", "level": "gym", "tier": "secondary", "forElement": el},
				{"type": "gym_legendary"},
			]
			processNextLevelUp()
		btn.onclick = _fn47
		c.appendChild(btn)
	UI.showScreen("elementunlock-screen")

# ── PASSIVE CHOICE ──
func _applyPickupChoice(passiveId = null, value = null):
	if passiveId == "air_prevailing_wind":
		State.player._prevailingWindPriority = (1 if value == "fast" else -1)
	elif passiveId == "air_tailwind_carry":
		State.player._tailwindCarryChoice = value
	elif passiveId == "duo_bellows":
		State.player._bellowsChoice = value

func showPassiveChoiceScreen(level = null, forElement = null):
	if forElement == null:
		forElement = null
	var badgeText = ("Rival Defeated" if level == "rival" else ("Gym Clear — New Passive" if level == "gym" else "Level " + JS.s(level) + " — New Passive"))
	document.getElementById("pc-level-badge").textContent = badgeText
	var c = document.getElementById("pc-choices")
	c.innerHTML = ""
	var pool = buildPassiveChoicePool(forElement)
	if len(pool) == 0:
		processNextLevelUp()
		return
	var chosen = pickRandom(pool, min(3, len(pool)))
	# Mark offered passives as seen in the library
	for p in JS.iter(chosen):
		Library.markPassiveSeen(p.id)
	for p in JS.iter(chosen):
		var btn = document.createElement("button")
		btn.className = "prog-choice-btn passive-btn"
		var infoIcon = ("<span class=\"pc-info-icon\" title=\"" + JS.s(p.detail) + "\" onclick=\"event.stopPropagation()\">ℹ</span>" if JS.t(p.get("detail")) else "")
		btn.innerHTML = "<div class=\"pc-tag\">" + (JS.or_(p.get("element"), "")) + " Passive</div><div class=\"pc-name\" style=\"display:flex;align-items:center;gap:.35rem;\">" + PassiveIcons.passiveIconSVG(p, 20) + " " + JS.s(p.title) + infoIcon + "</div><div class=\"pc-desc\">" + JS.s(p.get("desc")) + "</div>"
		var _fn50 = func():
			var _fn48 = func():
				State.addPassiveToBook(p.id)
				processNextLevelUp()
			var doAdd = _fn48
			var doContinue = doAdd
			if JS.t(p.get("pickupChoice")):
				c.innerHTML = "<div class=\"pc-tag\" style=\"margin-bottom:1rem;\">Choose for: " + (JS.or_(p.get("emoji"), "")) + " " + JS.s(p.title) + "</div>"
				for opt in JS.iter(p.get("pickupChoice")):
					var cb = document.createElement("button")
					cb.className = "prog-choice-btn"
					cb.innerHTML = "<div class=\"pc-name\">" + JS.s(opt.get("label")) + "</div>"
					var _fn49 = func():
						_applyPickupChoice(p.id, opt.value)
						doContinue.call()
					cb.onclick = _fn49
					c.appendChild(cb)
			else:
				doContinue.call()
		btn.onclick = _fn50
		c.appendChild(btn)
	_appendStatPad(c, 3 - len(chosen), processNextLevelUp)
	UI.showScreen("passivechoice-screen")

func buildPassiveChoicePool(forElement = null):
	if forElement == null:
		forElement = null
	var elements = ([forElement] if JS.t(forElement) else [State.playerElement] + JS.arr(State.player.get("unlockedElements")))
	var allOwnedPassives = JSSet.new(JS.or_(State.player.get("passives"), []))
	var pool = []
	for el in JS.iter(elements):
		for p in JS.iter(JS.or_(JS.idx(Passives.PASSIVE_CHOICES, el), [])):
			if JS.t(p.get("legendary")):
				continue
			# legendaries not offered through normal passive picks
			if not allOwnedPassives.has(p.id):
				pool.append(JS.merge([p, {"element": el}]))
	# Add eligible duo passives — compete equally with normal passives (not on element-specific screens)
	if not JS.t(forElement):
		for p in JS.iter(Duos._eligibleDuoPassives()):
			pool.append(p)
	return pool

# Pad a choice container to 3 options with generic stat boosts
func _appendStatPad(cont = null, needed = null, doneFn = null):
	if needed <= 0:
		return
	var _fn51 = func():
		State.player.attackPower += 5
		UI.updateStatsUI()
	var _fn52 = func():
		State.player.effectPower += 5
		UI.updateStatsUI()
	var _fn53 = func():
		State.player.defense += 5
		UI.updateStatsUI()
	var _fn54 = func():
		State.player.baseMaxHPBonus = (JS.or_(State.player.get("baseMaxHPBonus"), 0)) + 15
		State.player.hp = min(Helpers.maxHPFor("player"), State.player.get("hp") + 15)
	var pool = [
		{"emoji": "⚔️", "label": "Attack Training", "desc": "Gain +5 Attack Power.", "apply": _fn51},
		{"emoji": "✦", "label": "Effect Training", "desc": "Gain +5 Effect Power.", "apply": _fn52},
		{"emoji": "🛡️", "label": "Defense Training", "desc": "Gain +5 Defense.", "apply": _fn53},
		{"emoji": "❤️", "label": "Vitality Surge", "desc": "Permanently gain +15 max HP.", "apply": _fn54},
	]
	for opt in JS.iter(pickRandom(pool, min(needed, len(pool)))):
		var btn = document.createElement("button")
		btn.className = "prog-choice-btn"
		btn.innerHTML = "<div class=\"pc-tag\">Bonus</div><div class=\"pc-name\">" + JS.s(opt.get("emoji")) + " " + JS.s(opt.get("label")) + "</div><div class=\"pc-desc\">" + JS.s(opt.get("desc")) + "</div>"
		var _fn55 = func():
			JS.callm(opt, "apply", [])
			doneFn.call()
		btn.onclick = _fn55
		cont.appendChild(btn)

# Utility: pick n random distinct items
func pickRandom(arr = null, n = null):
	var copy = JS.arr(arr)
	var result = []
	while (len(result) < n and len(copy) > 0):
		var i = floori(randf() * len(copy))
		result.append(JS.idx(JS.splice(copy, i, 1), 0))
	return result
