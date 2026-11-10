# Incantations — generated from js/data/incantations.js by tools/js2gd.js
extends Node

var SPELL_RARITY = null
var SPELL_INCANTATION_CONFIG = null
var _INCANTATION_BASE_VALUES = null
var _STAT_LABELS = null

func _boot():
	# ===== incantations.js =====
	# ─── SPELL INCANTATION SYSTEM ─────────────────────────────────────────────────
	# Incantations upgrade one specific stat on a spell with decaying returns.
	# Formula: bonus = sum of (baseScale × decay^i) for i = 0 to level-2
	# Level 1 = base value (no bonus). Level 2 = +baseScale. Level 3 = +baseScale + baseScale×decay. Etc.
	SPELL_RARITY = {
		"dim": {"label": "Dim", "color": null, "level": 1},
		"kindled": {"label": "Kindled", "color": "#c06010", "level": 2},
		"blazing": {"label": "Blazing", "color": "#bb1200", "level": 3},
		"radiant": {"label": "Radiant", "color": "#d4aa20", "level": 4},
	}
	# Per-spell config — which stat scales, by how much, and with what decay.
	# Only spells with their execute() wired to read incantationLevel should appear here.
	SPELL_INCANTATION_CONFIG = {
		"ignite": {"scaledStat": "burnStacks", "baseScale": 3, "decay": 0.9},
		"ember_storm": {"scaledStat": "hits", "baseScale": 1, "decay": 1.0},
		"flame_wave": {"scaledStat": "burnStacks", "baseScale": 2, "decay": 0.9},
		"firewall": {"scaledStat": "firewallStacks", "baseScale": 1, "decay": 0.9},
		"grease_fire": {"scaledStat": "burnAdded", "baseScale": 2, "decay": 0.9},
		"fire_heal": {"scaledStat": "healPerStack", "baseScale": 0.2, "decay": 0.95},
		"fire_rage": {"scaledStat": "rageTurns", "baseScale": 1, "decay": 1.0},
		"melt_strike": {"scaledStat": "meltPoints", "baseScale": 3, "decay": 0.9},
		"forge_blast": {"scaledStat": "meltPoints", "baseScale": 2, "decay": 0.9},
		"crucible": {"scaledStat": "multiplier", "baseScale": 0.5, "decay": 0.9},
		"scorch_through": {"scaledStat": "meltPoints", "baseScale": 2, "decay": 0.9},
		"slag": {"scaledStat": "meltPoints", "baseScale": 2, "decay": 0.9},
		"heat_surge": {"scaledStat": "meltPoints", "baseScale": 3, "decay": 0.9},
		"smelt": {"scaledStat": "meltPoints", "baseScale": 2, "decay": 0.9},
		"crucible_burst": {"scaledStat": "meltPoints", "baseScale": 5, "decay": 0.9},
		"melt_down": {"scaledStat": "multiplier", "baseScale": 0.2, "decay": 0.9},
		"tidal_surge": {"scaledStat": "healBase", "baseScale": 3, "decay": 0.9},
		"riptide": {"scaledStat": "hits", "baseScale": 1, "decay": 1.0},
		"healing_tide": {"scaledStat": "healAmount", "baseScale": 8, "decay": 0.95},
		"whirlpool": {"scaledStat": "foamPerHit", "baseScale": 1, "decay": 0.9},
		"tidal_shield": {"scaledStat": "armorAmount", "baseScale": 4, "decay": 0.95},
		"cleanse_current": {"scaledStat": "healPerEffect", "baseScale": 4, "decay": 0.9},
		"frost_bolt": {"scaledStat": "frostStacks", "baseScale": 0.4, "decay": 0.9},
		"glacial_spike": {"scaledStat": "baseDamage", "baseScale": 10, "decay": 0.95},
		"snowstorm": {"scaledStat": "frostStacks", "baseScale": 0.4, "decay": 0.9},
		"flash_freeze": {"scaledStat": "frostStacks", "baseScale": 1, "decay": 0.9},
		"shatter": {"scaledStat": "multiplier", "baseScale": 0.5, "decay": 0.9},
		"frozen_ground": {"scaledStat": "duration", "baseScale": 1, "decay": 1.0},
		"cryostasis": {"scaledStat": "healAmount", "baseScale": 6, "decay": 0.95},
		"zap": {"scaledStat": "shockStacks", "baseScale": 0.4, "decay": 0.9},
		"chain_lightning": {"scaledStat": "bounces", "baseScale": 1, "decay": 1.0},
		"overcharge": {"scaledStat": "shockStacks", "baseScale": 1, "decay": 0.9},
		"feedback": {"scaledStat": "shockStacks", "baseScale": 1, "decay": 0.9},
		"short_circuit": {"scaledStat": "shockApplied", "baseScale": 1, "decay": 1.0},
		"bolt": {"scaledStat": "surgeValue", "baseScale": 5, "decay": 0.9},
		"thunder_strike": {"scaledStat": "shockStacks", "baseScale": 0.5, "decay": 0.9},
		"ball_lightning": {"scaledStat": "surgeValue", "baseScale": 4, "decay": 0.9},
		"static_charge": {"scaledStat": "surgeValue", "baseScale": 10, "decay": 0.9},
		"megavolt": {"scaledStat": "baseDamage", "baseScale": 8, "decay": 0.9},
		"supercharge": {"scaledStat": "surgeBonus", "baseScale": 10, "decay": 0.9},
		"residual_current": {"scaledStat": "surgeValue", "baseScale": 10, "decay": 0.9},
		"grounded": {"scaledStat": "surgePerDebuff", "baseScale": 1, "decay": 0.9},
		"seismic_wave": {"scaledStat": "armorStrip", "baseScale": 1, "decay": 1.0},
		"fortify": {"scaledStat": "armorAmount", "baseScale": 3, "decay": 0.95},
		"echo_slam": {"scaledStat": "dmgPerEnemy", "baseScale": 1, "decay": 0.95},
		"earthshaker": {"scaledStat": "multiplier", "baseScale": 0.5, "decay": 0.9},
		"dig": {"scaledStat": "baseAmount", "baseScale": 2, "decay": 0.95},
		"cataclysm": {"scaledStat": "dmgPerStack", "baseScale": 5, "decay": 0.9},
		"vine_strike": {"scaledStat": "hits", "baseScale": 1, "decay": 1.0},
		"damage_seed": {"scaledStat": "dmgPerStack", "baseScale": 5, "decay": 0.9},
		"root_seed": {"scaledStat": "rootPerStack", "baseScale": 1, "decay": 1.0},
		"silence_seed": {"scaledStat": "silenceCount", "baseScale": 1, "decay": 1.0},
		"armor_seed": {"scaledStat": "armorPerStack", "baseScale": 8, "decay": 0.95},
		"deep_soil": {"scaledStat": "bonusStacks", "baseScale": 1, "decay": 1.0},
		"world_tree": {"scaledStat": "stacksPerType", "baseScale": 1, "decay": 1.0},
		"thornwall": {"scaledStat": "rootStacks", "baseScale": 1, "decay": 1.0},
		"natures_call": {"scaledStat": "treantHP", "baseScale": 5, "decay": 0.95},
		"bramble_burst": {"scaledStat": "baseDamage", "baseScale": 8, "decay": 0.9},
		"nourish": {"scaledStat": "healAmount", "baseScale": 3, "decay": 0.95},
		"plasma_lance": {"scaledStat": "dmgPerCharge", "baseScale": 1, "decay": 0.9},
		"obliteration": {"scaledStat": "baseDamage", "baseScale": 1, "decay": 0.9},
		"quintuple_hit": {"scaledStat": "hits", "baseScale": 1, "decay": 1.0},
		"become_wind": {"scaledStat": "momentumGained", "baseScale": 2, "decay": 0.95},
		"tornado": {"scaledStat": "baseDamage", "baseScale": 3, "decay": 0.95},
		"twin_strike": {"scaledStat": "hits", "baseScale": 1, "decay": 1.0},
		"windy_takedown": {"scaledStat": "baseDamage", "baseScale": 5, "decay": 0.95},
		"plasma_arc": {"scaledStat": "meltPoints", "baseScale": 3, "decay": 0.9},
		"superheated": {"scaledStat": "burnMult", "baseScale": 0, "decay": 1.0},
		"thunderroot": {"scaledStat": "surgeValue", "baseScale": 4, "decay": 0.9},
		"static_bloom": {"scaledStat": "shockPerStack", "baseScale": 1, "decay": 1.0},
		"burning_grove": {"scaledStat": "burnAdded", "baseScale": 2, "decay": 0.9},
		"char_bloom": {"scaledStat": "seedBonus", "baseScale": 1, "decay": 1.0},
		"power_strike": {"scaledStat": "baseDamage", "baseScale": 10, "decay": 0.95},
		"double_tap": {"scaledStat": "baseDamage", "baseScale": 5, "decay": 0.95},
		"shield_bash": {"scaledStat": "armorAmount", "baseScale": 3, "decay": 0.95},
		"vampiric_strike": {"scaledStat": "lifeStealPct", "baseScale": 0.08, "decay": 0.9},
		"war_cry": {"scaledStat": "powerBonus", "baseScale": 3, "decay": 0.9},
	}
	# Base values used for upgrade display calculations
	_INCANTATION_BASE_VALUES = {
		"ignite": 15,
		"ember_storm": 3,
		"fire_heal": 1.0,
		"fire_rage": 1,
		"flame_wave": 5,
		"firewall": 3,
		"grease_fire": 4,
		"tidal_surge": 10,
		"riptide": 3,
		"healing_tide": 40,
		"whirlpool": 3,
		"tidal_shield": 20,
		"cleanse_current": 20,
		"frost_bolt": 2.0,
		"glacial_spike": 25,
		"snowstorm": 2.0,
		"flash_freeze": 5,
		"shatter": 4.0,
		"frozen_ground": 3,
		"cryostasis": 30,
		"zap": 2.0,
		"chain_lightning": 4,
		"overcharge": 3,
		"feedback": 2,
		"short_circuit": 1,
		"seismic_wave": 5,
		"fortify": 15,
		"echo_slam": 5,
		"earthshaker": 3.0,
		"dig": 5,
		"cataclysm": 25,
		"vine_strike": 3,
		"thornwall": 2,
		"natures_call": 25,
		"bramble_burst": 15,
		"nourish": 15,
		"silence_seed": 4,
		"armor_seed": 30,
		"deep_soil": 1,
		"plasma_lance": 5,
		"obliteration": 5,
		"quintuple_hit": 5,
		"become_wind": 10,
		"tornado": 10,
		"twin_strike": 2,
		"windy_takedown": 25,
		"plasma_arc": 20,
		"superheated": 2,
		"thunderroot": 25,
		"static_bloom": 1,
		"burning_grove": 10,
		"char_bloom": 1,
		"bolt": 25,
		"thunder_strike": 2,
		"ball_lightning": 20,
		"static_charge": 60,
		"megavolt": 50,
		"supercharge": 80,
		"residual_current": 30,
		"grounded": 5,
		"crucible": 2.0,
		"crucible_burst": 30,
		"melt_down": 1.5,
		"power_strike": 30,
		"double_tap": 15,
		"shield_bash": 15,
		"vampiric_strike": 0.4,
		"war_cry": 10,
	}
	# Stat → short human-readable label (shared by combat button and upgrade popup)
	_STAT_LABELS = {
		"baseDamage": "Damage",
		"burnStacks": "Burn",
		"burnPerHit": "Burn/Hit",
		"burnAdded": "Burn+",
		"firewallStacks": "Firewall",
		"healBase": "Heal",
		"healAmount": "Heal",
		"healPerEffect": "Heal/Effect",
		"healPerStack": "Heal/Stack",
		"foamPerHit": "Foam/Hit",
		"foamApplied": "Foam",
		"armorAmount": "Armor",
		"armorStrip": "Armor Strip",
		"armorGained": "Armor",
		"armorBonus": "Armor",
		"frostStacks": "Frost",
		"frostApplied": "Frost",
		"shockStacks": "Shock",
		"shockApplied": "Shock",
		"shockPerEffect": "Shock/Effect",
		"hits": "Hits",
		"bounces": "Bounces",
		"multiplier": "Mult",
		"duration": "Duration",
		"rootChance": "Root%",
		"rootStacks": "Root",
		"treantHP": "Treant HP",
		"dmgPerStack": "Dmg/Stack",
		"dmgPerEnemy": "Dmg/Enemy",
		"dmgPerFoam": "Dmg/Foam",
		"dmgPerCharge": "Dmg/Charge",
		"silenceCount": "Spells Silenced",
		"armorPerStack": "Armor/Stack",
		"baseAmount": "Amount",
		"momentumGained": "Momentum",
		"powerBonus": "Power",
		"lifeStealPct": "Life Steal",
		"rageTurns": "Rage Turns",
		"immuneTurns": "Immunity",
		"resetBonus": "Overload",
		"surgeValue": "Surge Dmg",
		"surgeBonus": "Surge+",
		"surgePerDebuff": "Surge/Debuff",
		"shockPerStack": "Shock/Stack",
		"seedBonus": "Seed Stacks",
		"burnMult": "Burn×",
		"powPerCharge": "Pow/Charge",
		"pctPerCharge": "Shield%",
		"hitsPerCharge": "Hits/Charge",
		"borrowAmount": "Charge",
		"powerGained": "Power",
		"bonusCharge": "Charge",
		"actionsGained": "Actions",
		"attackCount": "Attacks",
		"reduction": "Timer−",
		"bonusStacks": "Stacks+",
	}

# Compute cumulative bonus at a given incantation level.
# level 1 → 0 bonus. level 2 → baseScale. level 3 → baseScale + baseScale*decay. Etc.
func _incantationBonus(level = null, baseScale = null, decay = null):
	if (not JS.t(level) or level <= 1):
		return 0
	var bonus = 0
	for i in range(ceili(level - 1)):
		bonus += baseScale * pow(decay, i)
	return bonus

# Roll for spell rarity when a spell is awarded.
# Radiant checked first, then Blazing, then Kindled, else Dim.
# Chances stored on player by talent apply() functions.
func rollSpellRarity():
	var r = randf()
	# Base chance per tier even without any talent investment
	# Kindled: 8% base → up to 48% at max talent
	# Blazing: 4% base → up to 24% at max talent
	# Radiant: 2% base → up to 12% at max talent
	var radiantChance = (JS.or_(State.player.get("_rarityChanceRadiant"), 0)) + 0.02
	var blazingChance = (JS.or_(State.player.get("_rarityChanceBlazing"), 0)) + 0.04
	var kindledChance = (JS.or_(State.player.get("_rarityChanceKindled"), 0)) + 0.08
	if r < radiantChance:
		return "radiant"
	if r < (radiantChance + blazingChance):
		return "blazing"
	if r < ((radiantChance + blazingChance) + kindledChance):
		return "kindled"
	return "dim"

# Compute the scaled value for a spell's incantated stat given its current incantation level.
func incantatedValue(spellObj = null, baseValue = null):
	var cfg = JS.idx(SPELL_INCANTATION_CONFIG, spellObj.id)
	if not JS.t(cfg):
		return baseValue
	return baseValue + _incantationBonus(JS.or_(spellObj.get("incantationLevel"), 1), cfg.get("baseScale"), cfg.get("decay"))

# Returns "Label: value" string showing the CURRENT incantated stat for display in spell buttons.
func incantationStatDisplay(spellObj = null):
	var cfg = JS.idx(SPELL_INCANTATION_CONFIG, spellObj.id)
	if not JS.t(cfg):
		return null
	var base = JS.idx(_INCANTATION_BASE_VALUES, spellObj.id)
	if base == null:
		return null
	var curLevel = JS.or_(spellObj.get("incantationLevel"), 1)
	var val = base + _incantationBonus(curLevel, cfg.get("baseScale"), cfg.get("decay"))
	var fmt = null
	if (cfg.get("scaledStat") == "rootChance" or cfg.get("scaledStat") == "lifeStealPct"):
		fmt = JS.s(JS.round(val * 100)) + "%"
	elif cfg.get("scaledStat") == "multiplier":
		fmt = "×" + JS.toFixed(val, 2)
	elif ((cfg.get("scaledStat") == "frostStacks" or cfg.get("scaledStat") == "shockStacks") or cfg.get("scaledStat") == "frostApplied"):
		fmt = JS.toFixed(val, 1)
	elif ((JS.typeof_(base)) == "number" and not JS.isInteger(base)):
		fmt = JS.toFixed(val, 1)
	else:
		fmt = JS.s(JS.round(val))
	return JS.s(JS.or_(JS.idx(_STAT_LABELS, cfg.get("scaledStat")), cfg.get("scaledStat"))) + ": " + fmt

# Returns { stat, prev, next } display strings for the upgrade popup.
func incantationUpgradeDisplay(spellObj = null):
	var cfg = JS.idx(SPELL_INCANTATION_CONFIG, spellObj.id)
	if not JS.t(cfg):
		return null
	var curLevel = JS.or_(spellObj.get("incantationLevel"), 1)
	var base = JS.idx(_INCANTATION_BASE_VALUES, spellObj.id)
	if base == null:
		return null
	var prevBonus = _incantationBonus(curLevel, cfg.get("baseScale"), cfg.get("decay"))
	var nextBonus = _incantationBonus(curLevel + 1, cfg.get("baseScale"), cfg.get("decay"))
	var prevVal = base + prevBonus
	var nextVal = base + nextBonus
	var _fn1 = func(v = null):
		if (cfg.get("scaledStat") == "rootChance" or cfg.get("scaledStat") == "lifeStealPct"):
			return JS.s(JS.round(v * 100)) + "%"
		if cfg.get("scaledStat") == "multiplier":
			return "×" + JS.toFixed(v, 2)
		if (cfg.get("scaledStat") == "frostStacks" or cfg.get("scaledStat") == "shockStacks"):
			return JS.toFixed(v, 1)
		if ((JS.typeof_(base)) == "number" and not JS.isInteger(base)):
			return JS.toFixed(v, 1)
		if JS.eq(cfg.get("decay"), 1.0):
			return JS.s(JS.round(v))
		return JS.s(JS.round(v))
	var fmt = _fn1
	return {"stat": cfg.get("scaledStat"), "prev": fmt.call(prevVal), "next": fmt.call(nextVal)}
