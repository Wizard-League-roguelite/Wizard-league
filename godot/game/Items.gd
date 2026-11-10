# Items — generated from js/data/items.js by tools/js2gd.js
extends Node

var ITEM_CATALOGUE = null
var ITEM_DROP_POOL = null

func _boot():
	# ===== items.js =====
	# ─── ITEM DATA ─────────────────────────────────────────────────────────────
	# ITEM_CATALOGUE, shop pool, drop pool.
	ITEM_CATALOGUE = {
		"health_potion": {
			"id": "health_potion",
			"name": "Health Potion",
			"emoji": "💚",
			"desc": "Restore 40% HP",
			"type": "consumable",
			"use": ITEM_CATALOGUE__health_potion__use,
		},
		"mana_crystal": {
			"id": "mana_crystal",
			"name": "Mana Crystal",
			"emoji": "🔮",
			"desc": "Restore all spell PP",
			"type": "consumable",
			"use": ITEM_CATALOGUE__mana_crystal__use,
		},
		"dmg_booster": {
			"id": "dmg_booster",
			"name": "Damage Crystal",
			"emoji": "💎",
			"desc": "+16 dmg this battle",
			"type": "consumable",
			"use": ITEM_CATALOGUE__dmg_booster__use,
		},
		"efx_crystal": {
			"id": "efx_crystal",
			"name": "EFX Crystal",
			"emoji": "✦",
			"desc": "+20 Effect Power this battle",
			"type": "consumable",
			"use": ITEM_CATALOGUE__efx_crystal__use,
		},
		"def_crystal": {
			"id": "def_crystal",
			"name": "Defense Crystal",
			"emoji": "🛡️",
			"desc": "+20 Defense this battle",
			"type": "consumable",
			"use": ITEM_CATALOGUE__def_crystal__use,
		},
		"basic_dispel": {
			"id": "basic_dispel",
			"name": "Basic Dispel",
			"emoji": "🧹",
			"desc": "Halve debuff stacks; duration effects -1",
			"type": "consumable",
			"use": ITEM_CATALOGUE__basic_dispel__use,
		},
		"strong_dispel": {
			"id": "strong_dispel",
			"name": "Strong Dispel",
			"emoji": "✨",
			"desc": "Clear all negative status effects",
			"type": "consumable",
			"use": ITEM_CATALOGUE__strong_dispel__use,
		},
	}
	ITEM_DROP_POOL = ["health_potion", "dmg_booster"]

func ITEM_CATALOGUE__health_potion__use():
	Helpers.applyHeal("player", floori(Helpers.maxHPFor("player") * 0.4), "💚 Health Potion")
	return null

func ITEM_CATALOGUE__mana_crystal__use():
	BattleLoad.restoreAllPP()
	return "🔮 All spell PP restored!"

func ITEM_CATALOGUE__dmg_booster__use():
	State.combat.tempDmgBonus = (JS.or_(State.combat.get("tempDmgBonus"), 0)) + 16
	return "💎 Damage Crystal shatters — +16 damage this battle!"

func ITEM_CATALOGUE__efx_crystal__use():
	State.status.get("player").battleEfxBonus = (JS.or_(State.status.get("player").get("battleEfxBonus"), 0)) + 20
	return "✦ EFX Crystal — +20 Effect Power this battle!"

func ITEM_CATALOGUE__def_crystal__use():
	State.status.get("player").battleDefBonus = (JS.or_(State.status.get("player").get("battleDefBonus"), 0)) + 20
	return "🛡️ Defense Crystal — +20 Defense this battle!"

func ITEM_CATALOGUE__basic_dispel__use():
	var s = State.status.get("player")
	for key in JS.iter(["burnStacks", "foamStacks", "shockStacks", "frostStacks", "rootStacks", "overgrowthStacks"]):
		if JS.t(JS.idx(s, key)):
			s[key] = floori(s[key] / 2.0)
	for key in JS.iter(["stunned", "frozenGroundTurns", "spreadingVinesTurns"]):
		if JS.t(JS.idx(s, key)):
			s[key] = max(0, s[key] - 1)
	if JS.t(s.get("frozen")):
		s.frozen = false
	UI.renderStatusTags()
	return "🧹 Debuffs reduced!"

func ITEM_CATALOGUE__strong_dispel__use():
	var s = State.status.get("player")
	for key in JS.iter([
		"burnStacks",
		"foamStacks",
		"shockStacks",
		"frostStacks",
		"rootStacks",
		"overgrowthStacks",
		"stunned",
		"frozenGroundTurns",
		"spreadingVinesTurns",
	]):
		s[key] = 0
	s.frozen = false
	UI.renderStatusTags()
	return "✨ All debuffs cleared!"
