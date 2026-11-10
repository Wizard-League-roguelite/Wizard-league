# ShopCampfire — generated from js/ui/shopCampfire.js by tools/js2gd.js
extends Node

var _shopStock = null

func _boot():
	pass

# ===== shopCampfire.js =====
# ─── CAMPFIRE + SHOP screens ──────────────────────────────────────────────────
func enterCampfire():
	var pMax = Helpers.maxHPFor("player")
	var descEl = document.getElementById("campfire-desc")
	var cont = document.getElementById("campfire-choices")
	if JS.t(descEl):
		descEl.textContent = "The fire crackles. How do you spend your rest?"
	var _fn1 = func():
		var actual = Helpers.applyHeal("player", floori(pMax * 0.5), null)
		BattleLoad.restoreAllPP()
		UI.log_(("🔥 You rest. +" + JS.s(actual) + " HP, all PP restored." if actual > 0 else "🔥 Already full — PP restored."), "heal")
	var _fn2 = func():
		var actual = Helpers.applyHeal("player", floori(pMax * 0.2), null)
		State.player.attackPower += 8
		UI.updateStatsUI()
		UI.log_("⚔️ Steel sharpened." + (" +" + JS.s(actual) + " HP," if actual > 0 else "") + " +8 ATK.", "item")
	var _fn3 = func():
		var actual = Helpers.applyHeal("player", floori(pMax * 0.2), null)
		State.player.effectPower += 8
		UI.updateStatsUI()
		UI.log_("✦ Mind sharpened." + (" +" + JS.s(actual) + " HP," if actual > 0 else "") + " +8 EFX.", "item")
	var _fn4 = func():
		var actual = Helpers.applyHeal("player", floori(pMax * 0.2), null)
		State.player.defense += 8
		UI.updateStatsUI()
		UI.log_("🛡️ Armor reinforced." + (" +" + JS.s(actual) + " HP," if actual > 0 else "") + " +8 DEF.", "item")
	var _fn5 = func():
		var actual = Helpers.applyHeal("player", floori(pMax * 0.2), null)
		State.player.gold += 80
		UI.log_("🌿 Foraged supplies." + (" +" + JS.s(actual) + " HP," if actual > 0 else "") + " +80 Gold.", "item")
	var _fn6 = func():
		BattleLoad.restoreAllPP()
		State.player._rerolls = (JS.or_(State.player.get("_rerolls"), 0)) + 1
		UI.log_("📖 You study by firelight. All PP restored, +1 Reroll.", "item")
	var CAMPFIRE_OPTS = [
		{
			"emoji": "🔥",
			"label": "Rest & Recover",
			"tag": "Rest",
			"desc": "Heal " + JS.s(floori(pMax * 0.5)) + " HP and fully restore all spell PP.",
			"apply": _fn1,
		},
		{
			"emoji": "⚔️",
			"label": "Sharpen Your Edge",
			"tag": "Forge",
			"desc": "Heal " + JS.s(floori(pMax * 0.2)) + " HP and permanently gain +8 Attack Power.",
			"apply": _fn2,
		},
		{
			"emoji": "✦",
			"label": "Focus Your Craft",
			"tag": "Forge",
			"desc": "Heal " + JS.s(floori(pMax * 0.2)) + " HP and permanently gain +8 Effect Power.",
			"apply": _fn3,
		},
		{
			"emoji": "🛡️",
			"label": "Fortify",
			"tag": "Forge",
			"desc": "Heal " + JS.s(floori(pMax * 0.2)) + " HP and permanently gain +8 Defense.",
			"apply": _fn4,
		},
		{
			"emoji": "🌿",
			"label": "Forage Supplies",
			"tag": "Forage",
			"desc": "Heal " + JS.s(floori(pMax * 0.2)) + " HP and gain 80 gold.",
			"apply": _fn5,
		},
		{
			"emoji": "📖",
			"label": "Study the Arcane",
			"tag": "Study",
			"desc": "Restore all spell PP and gain +1 reroll token.",
			"apply": _fn6,
		},
	]
	# Rest & Recover is always one of the 3 options; pick 2 more from the rest
	var restOpt = JS.idx(CAMPFIRE_OPTS, 0)
	var otherOpts = JS.slice(CAMPFIRE_OPTS, 1)
	var chosen = [restOpt] + JS.arr(BattleReward.pickRandom(otherOpts, 2))
	if JS.t(cont):
		cont.innerHTML = ""
		for opt in JS.iter(chosen):
			var btn = document.createElement("button")
			btn.className = "prog-choice-btn"
			btn.innerHTML = "<div class=\"pc-tag\">" + JS.s(opt.get("tag")) + "</div><div class=\"pc-name\">" + JS.s(opt.get("emoji")) + " " + JS.s(opt.get("label")) + "</div><div class=\"pc-desc\">" + JS.s(opt.get("desc")) + "</div>"
			var _fn7 = func():
				JS.callm(opt, "apply", [])
				if JS.t(descEl):
					descEl.textContent = ""
				cont.innerHTML = ""
				var leaveBtn = document.createElement("button")
				leaveBtn.className = "btn-main"
				leaveBtn.style.width = "220px"
				leaveBtn.textContent = "Continue"
				leaveBtn.onclick = leaveCampfire
				cont.appendChild(leaveBtn)
			btn.onclick = _fn7
			cont.appendChild(btn)
	UI.showScreen("campfire-screen")
	JS.setTimeout(func(): return Animations.startCampfireScene(""), 0)

func leaveCampfire():
	Animations.stopCampfireScene()
	State.zoneBattleCount += 1
	MapCanvas.showMap()

func _generateShopStock():
	var m = JS.or_(State.player.get("_mistShopPriceMult"), 1.0)
	var c = func(n = null): return ceili(n * m)
	# ── Category pools ──────────────────────────────────────────────────────
	var _fn8 = func():
		Spells.addItem("health_potion")
	var _fn9 = func():
		Spells.addItem("mana_crystal")
	var _fn10 = func():
		Spells.addItem("dmg_booster")
	var _fn11 = func():
		Spells.addItem("efx_crystal")
	var _fn12 = func():
		Spells.addItem("def_crystal")
	var _fn13 = func():
		Spells.addItem("basic_dispel")
	var _fn14 = func():
		Spells.addItem("strong_dispel")
	var itemPool = [
		{
			"id": "s_hp",
			"label": "Health Potion",
			"emoji": "💚",
			"tag": "Consumable",
			"desc": "Restore 40% HP during battle.",
			"cost": c.call(50),
			"buy": _fn8,
		},
		{
			"id": "s_pp",
			"label": "Mana Crystal",
			"emoji": "🔮",
			"tag": "Consumable",
			"desc": "Restore all spell PP during battle.",
			"cost": c.call(50),
			"buy": _fn9,
		},
		{
			"id": "s_dmg",
			"label": "Damage Crystal",
			"emoji": "💎",
			"tag": "Consumable",
			"desc": "+20 damage this battle.",
			"cost": c.call(50),
			"buy": _fn10,
		},
		{
			"id": "s_efx",
			"label": "EFX Crystal",
			"emoji": "✦",
			"tag": "Consumable",
			"desc": "+20 Effect Power this battle.",
			"cost": c.call(50),
			"buy": _fn11,
		},
		{
			"id": "s_defc",
			"label": "Defense Crystal",
			"emoji": "🛡️",
			"tag": "Consumable",
			"desc": "+20 Defense this battle.",
			"cost": c.call(50),
			"buy": _fn12,
		},
		{
			"id": "s_disp1",
			"label": "Basic Dispel",
			"emoji": "🧹",
			"tag": "Consumable",
			"desc": "Halve debuff stacks; duration effects -1.",
			"cost": c.call(50),
			"buy": _fn13,
		},
		{
			"id": "s_disp2",
			"label": "Strong Dispel",
			"emoji": "✨",
			"tag": "Consumable",
			"desc": "Clear all negative status effects.",
			"cost": c.call(100),
			"buy": _fn14,
		},
	]
	var _fn15 = func():
		State.player.attackPower += 5
		UI.updateStatsUI()
		UI.log_("⚔️ +5 Attack Power!", "item")
	var _fn16 = func():
		State.player.effectPower += 5
		UI.updateStatsUI()
		UI.log_("✦ +5 Effect Power!", "item")
	var _fn17 = func():
		State.player.defense += 5
		UI.updateStatsUI()
		UI.log_("🛡️ +5 Defense!", "item")
	var _fn18 = func():
		State.player.baseMaxHPBonus = (JS.or_(State.player.get("baseMaxHPBonus"), 0)) + 25
		State.player.hp = min(Helpers.maxHPFor("player"), State.player.get("hp") + 25)
		UI.updateStatsUI()
		UI.log_("❤️ +25 Max HP!", "item")
	var statPool = [
		{
			"id": "s_atk",
			"label": "+5 Attack Power",
			"emoji": "⚔️",
			"tag": "Stat",
			"desc": "Permanently gain +5 Attack Power.",
			"cost": c.call(100),
			"buy": _fn15,
		},
		{
			"id": "s_efxs",
			"label": "+5 Effect Power",
			"emoji": "✦",
			"tag": "Stat",
			"desc": "Permanently gain +5 Effect Power.",
			"cost": c.call(100),
			"buy": _fn16,
		},
		{
			"id": "s_def",
			"label": "+5 Defense",
			"emoji": "🛡️",
			"tag": "Stat",
			"desc": "Permanently gain +5 Defense.",
			"cost": c.call(100),
			"buy": _fn17,
		},
		{
			"id": "s_hp2",
			"label": "+25 Max HP",
			"emoji": "❤️",
			"tag": "Stat",
			"desc": "Permanently gain +25 Max HP.",
			"cost": c.call(100),
			"buy": _fn18,
		},
	]
	var _fn19 = func():
		_closeShopForReward()
		BattleReward.showSpellChoiceScreen("Shop", "secondary")
	var _fn20 = func():
		_closeShopForReward()
		BattleReward.showIncantationChoiceScreen("Shop")
	var rewardPool = [
		{
			"id": "s_spell",
			"label": "Spell Reward",
			"emoji": "📜",
			"tag": "Reward",
			"desc": "Choose a new spell to add to your spellbook.",
			"cost": c.call(150),
			"_modal": true,
			"buy": _fn19,
		},
		{
			"id": "s_incant",
			"label": "Incantation",
			"emoji": "✦",
			"tag": "Reward",
			"desc": "Choose a spell to upgrade.",
			"cost": c.call(150),
			"_modal": true,
			"buy": _fn20,
		},
	]
	var _fn21 = func():
		State.player.bonusActions = (JS.or_(State.player.get("bonusActions"), 0)) + 1
		UI.log_("⚡ Extra action per turn!", "item")
	var _fn22 = func():
		State.player.revives = (JS.or_(State.player.get("revives"), 0)) + 1
		UI.log_("❤ Extra life gained!", "item")
	var _fn23 = func():
		_closeShopForReward()
		BattleReward.showPassiveChoiceScreen("Shop")
	var powerPool = [
		{
			"id": "s_action",
			"label": "Extra Action",
			"emoji": "⚡",
			"tag": "Power",
			"desc": "Permanently gain +1 action per turn.",
			"cost": c.call(250),
			"buy": _fn21,
		},
		{
			"id": "s_life",
			"label": "Extra Life",
			"emoji": "❤️",
			"tag": "Power",
			"desc": "Survive one killing blow — revive at 75% HP.",
			"cost": c.call(200),
			"buy": _fn22,
		},
		{
			"id": "s_rival",
			"label": "Rival's Secret",
			"emoji": "⚔️",
			"tag": "Power",
			"desc": "Study your rival's techniques — choose from 3 passives.",
			"cost": c.call(400),
			"_modal": true,
			"buy": _fn23,
		},
	]
	# ── Pick one per slot ───────────────────────────────────────────────────
	var item1 = JS.idx(BattleReward.pickRandom(itemPool, 1), 0)
	var stat1 = JS.idx(BattleReward.pickRandom(statPool, 1), 0)
	# 50/50: another item (different from item1) or another stat (different from stat1)
	var mix = (JS.idx(BattleReward.pickRandom(JS.arr(itemPool).filter(func(i = null): return not JS.eq(i.id, item1.id)), 1), 0) if randf() < 0.5 else JS.idx(BattleReward.pickRandom(JS.arr(statPool).filter(func(s = null): return not JS.eq(s.id, stat1.id)), 1), 0))
	var reward = JS.idx(BattleReward.pickRandom(rewardPool, 1), 0)
	var power = JS.idx(BattleReward.pickRandom(powerPool, 1), 0)
	return JS.arr(JS.sort(JS.filter([item1, stat1, mix, reward, power], JS.t), func(a = null, b = null): return a.get("cost") - b.get("cost"))).map(func(item = null): return JS.merge([item, {"bought": false}]))

func _closeShopForReward():
	_shopStock = null
	var canvas = document.getElementById("shop-canvas")
	if (JS.t(canvas) and JS.t(canvas.get("_stop"))):
		JS.callm(canvas, "_stop", [])

func enterShop():
	if not JS.t(_shopStock):
		_shopStock = _generateShopStock()
	_renderShop()

func _renderShop():
	document.getElementById("shop-gold-display").textContent = State.player.get("gold")
	var c = document.getElementById("shop-items")
	c.innerHTML = ""
	for item in JS.iter(JS.or_(_shopStock, [])):
		var affordable = State.player.get("gold") >= item.get("cost")
		var canBuy = (not JS.t(item.get("bought")) and affordable)
		var row = document.createElement("div")
		row.className = "shop-item-row" + (" cant-afford" if JS.t(item.get("bought")) else ("" if canBuy else " cant-afford"))
		var statusLabel = ("<span style=\"font-size:.55rem;color:#555;margin-left:.4rem;\">SOLD</span>" if JS.t(item.get("bought")) else "")
		row.innerHTML = "<div><div class=\"shop-item-name\">" + JS.s(item.get("emoji")) + " " + JS.s(item.get("label")) + statusLabel + "</div><div class=\"shop-item-desc\">[" + JS.s(item.get("tag")) + "] " + JS.s(item.get("desc")) + "</div></div><div class=\"shop-item-cost\">" + JS.s(item.get("cost")) + "g</div>"
		if canBuy:
			var _fn24 = func():
				State.player.gold -= item.get("cost")
				item.bought = true
				JS.callm(item, "buy", [])
				if not JS.t(item.get("_modal")):
					_renderShop()
			row.onclick = _fn24
		c.appendChild(row)
	UI.updateStatsUI()
	UI.showScreen("shop-screen")
	MapLogic.startShopCanvas()

func leaveShop():
	_shopStock = null
	var canvas = document.getElementById("shop-canvas")
	if (JS.t(canvas) and JS.t(canvas.get("_stop"))):
		JS.callm(canvas, "_stop", [])
	State.zoneBattleCount += 1
	MapCanvas.showMap()
