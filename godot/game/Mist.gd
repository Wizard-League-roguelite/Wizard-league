# Mist — generated from js/data/mist.js by tools/js2gd.js
extends Node

var MIST_MODIFIERS = null

func _boot():
	# ===== mist.js =====
	# ── The Veil — Mist difficulty system ────────────────────────────────────────
	MIST_MODIFIERS = [
		{
			"id": "enemy_damage",
			"label": "Relentless Aggression",
			"emoji": "⚔",
			"desc": func(t = null): return "Enemy damage +" + JS.s(JS.idx([15, 30, 50, 75], t - 1)) + "%",
			"tiers": 4,
			"mistCost": [1, 2, 3, 4],
		},
		{
			"id": "enemy_hp",
			"label": "Fortified Enemies",
			"emoji": "🛡",
			"desc": func(t = null): return "Enemy HP +" + JS.s(JS.idx([15, 30, 50, 75], t - 1)) + "%",
			"tiers": 4,
			"mistCost": [1, 2, 3, 4],
		},
		{
			"id": "enemy_passives",
			"label": "Hardened Foes",
			"emoji": "💀",
			"desc": func(t = null): return "Enemies gain +" + JS.s(t) + " extra passive" + ("s" if t > 1 else ""),
			"tiers": 2,
			"mistCost": [2, 3],
		},
		{
			"id": "shop_prices",
			"label": "Premium Market",
			"emoji": "💰",
			"desc": func(t = null): return "Shop prices +" + JS.s(JS.idx([30, 60], t - 1)) + "%",
			"tiers": 2,
			"mistCost": [1, 2],
		},
		{
			"id": "pp_reduction",
			"label": "Mana Drought",
			"emoji": "🫧",
			"desc": func(t = null): return "All PP reduced by " + JS.s(JS.idx([20, 40], t - 1)) + "%",
			"tiers": 2,
			"mistCost": [2, 3],
		},
		{
			"id": "campfire_reduction",
			"label": "Scarce Respite",
			"emoji": "🔥",
			"desc": func(t = null): return ("One fewer campfire per zone" if JS.eq(t, 1) else "No campfires per zone"),
			"tiers": 2,
			"mistCost": [3, 5],
		},
		{
			"id": "talent_reduction",
			"label": "Diminished Legacy",
			"emoji": "📿",
			"desc": func(t = null): return "Talent node levels reduced by " + JS.s(t) + " during runs",
			"tiers": 2,
			"mistCost": [2, 4],
		},
		{
			"id": "boss_legendaries",
			"label": "Awakened Bosses",
			"emoji": "👁",
			"desc": func(t = null): return "Gym bosses gain +" + JS.s(t) + " legendary passive" + ("s" if t > 1 else ""),
			"tiers": 2,
			"mistCost": [3, 4],
		},
		{
			"id": "hidden_intentions",
			"label": "Veiled Intentions",
			"emoji": "🎭",
			"desc": func(t = null): return JS.s(JS.idx([25, 50, 75, 100], t - 1)) + "% chance each enemy action is hidden",
			"tiers": 4,
			"mistCost": [1, 2, 3, 4],
		},
		{
			"id": "blind_damage",
			"label": "Fog of War",
			"emoji": "🌫",
			"desc": func(): return "Damage previews are hidden — you cannot see estimated damage values",
			"tiers": 1,
			"mistCost": [2],
		},
	]

func getMistConfig():
	var meta = Artifacts.getMeta()
	if not JS.t(meta.get("mistConfig")):
		meta.mistConfig = {"active": false, "modifiers": {}}
	return meta.get("mistConfig")

func getTotalMist():
	var total = [null]
	var cfg = getMistConfig()
	if not JS.t(cfg.get("active")):
		return 0
	total[0] = 1
	for mod in JS.iter(MIST_MODIFIERS):
		var tier = JS.or_(JS.idx(cfg.get("modifiers"), mod.id), 0)
		if tier > 0:
			total[0] += JS.reduce(JS.slice(mod.get("mistCost"), 0, tier), func(a = null, b = null): return a + b, 0)
	return total[0]

func getMistTier(modId = null):
	var cfg = getMistConfig()
	if not JS.t(cfg.get("active")):
		return 0
	return JS.or_(JS.idx(cfg.get("modifiers"), modId), 0)

func applyMistModifiers():
	State.player._mistEnemyDmgMult = 1.0
	State.player._mistEnemyHPMult = 1.0
	State.player._mistExtraPassives = 0
	State.player._mistShopPriceMult = 1.0
	State.player._mistPPMult = 1.0
	State.player._mistCampfireReduction = 0
	State.player._mistTalentReduction = 0
	State.player._mistBossLegendaries = 0
	var cfg = getMistConfig()
	if not JS.t(cfg.get("active")):
		return
	var dmg = getMistTier("enemy_damage")
	if dmg > 0:
		State.player._mistEnemyDmgMult = JS.idx([1.15, 1.3, 1.5, 1.75], dmg - 1)
	var hp = getMistTier("enemy_hp")
	if hp > 0:
		State.player._mistEnemyHPMult = JS.idx([1.15, 1.3, 1.5, 1.75], hp - 1)
	var pass_ = getMistTier("enemy_passives")
	if pass_ > 0:
		State.player._mistExtraPassives = pass_
	var shop = getMistTier("shop_prices")
	if shop > 0:
		State.player._mistShopPriceMult = JS.idx([1.3, 1.6], shop - 1)
	var pp = getMistTier("pp_reduction")
	if pp > 0:
		State.player._mistPPMult = JS.idx([0.8, 0.6], pp - 1)
	var camp = getMistTier("campfire_reduction")
	if camp > 0:
		State.player._mistCampfireReduction = camp
	var talent = getMistTier("talent_reduction")
	if talent > 0:
		State.player._mistTalentReduction = talent
	var boss = getMistTier("boss_legendaries")
	if boss > 0:
		State.player._mistBossLegendaries = boss
	# hidden_intentions is read live via getMistTier() in _intentHidden() — no player prop needed
	State.player._mistBlindDamage = getMistTier("blind_damage") > 0
