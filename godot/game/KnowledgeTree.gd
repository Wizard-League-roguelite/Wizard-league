# KnowledgeTree — generated from js/data/knowledgeTree.js by tools/js2gd.js
extends Node

# ===== knowledgeTree.js =====
# ─── KNOWLEDGE TREE ───────────────────────────────────────────────────────────
# meta.ktUnlocked        = string[]   — card IDs permanently unlocked
# meta.ktEquipped        = string[]   — card IDs brought this run
# meta.ktLevels          = {id:level} — current level per unlocked card (default 1)
# meta.ktBudgetGeneralLevel   = 0-4  — times General budget has been expanded
# meta.ktBudgetElementalLevel = 0-4  — times Elemental budget has been expanded
var KT_GENERAL_BUDGET_BASE = 8
var KT_ELEMENTAL_BUDGET_BASE = 8
var KT_BUDGET_PER_UPGRADE = 3
var KT_BUDGET_UPGRADE_COSTS = null
var KT_GENERAL_CARDS = null
var KT_ELEMENTAL_CARDS = null

func _boot():
	KT_BUDGET_UPGRADE_COSTS = [10, 18, 30, 50]
	# ── General Cards — 3 rows of 4 ───────────────────────────────────────────────
	# Card shape: { id, name, emoji, phosCost, phorosCost, maxLevel,
	# levelCosts [null, cost→lv2, cost→lv3],
	# levelDescs ['lv1 desc', 'lv2 desc', 'lv3 desc'],
	# apply(level) }
	KT_GENERAL_CARDS = [
		{
			"id": "kt_extra_life",
			"name": "Extra Life",
			"emoji": "❤️",
			"phosCost": 10,
			"phorosCost": 4,
			"maxLevel": 3,
			"levelCosts": [null, 15, 25],
			"levelDescs": ["Start with +1 revive.", "Start with +2 revives.", "Start with +3 revives."],
			"apply": KT_GENERAL_CARDS__kt_extra_life__apply,
		},
		{
			"id": "kt_vitality",
			"name": "Vitality",
			"emoji": "💪",
			"phosCost": 8,
			"phorosCost": 2,
			"maxLevel": 5,
			"levelCosts": [null, 12, 20, 32, 48],
			"levelDescs": ["+10% max HP.", "+20% max HP.", "+30% max HP.", "+40% max HP.", "+50% max HP."],
			"apply": KT_GENERAL_CARDS__kt_vitality__apply,
		},
		{
			"id": "kt_attack",
			"name": "Attack Training",
			"emoji": "⚔️",
			"phosCost": 8,
			"phorosCost": 1,
			"maxLevel": 3,
			"levelCosts": [null, 12, 20],
			"levelDescs": ["+5 Attack Power.", "+10 Attack Power.", "+15 Attack Power."],
			"apply": KT_GENERAL_CARDS__kt_attack__apply,
		},
		{
			"id": "kt_effect",
			"name": "Effect Training",
			"emoji": "✨",
			"phosCost": 8,
			"phorosCost": 1,
			"maxLevel": 3,
			"levelCosts": [null, 12, 20],
			"levelDescs": ["+8 Effect Power.", "+16 Effect Power.", "+24 Effect Power."],
			"apply": KT_GENERAL_CARDS__kt_effect__apply,
		},
		{
			"id": "kt_defense",
			"name": "Defense Training",
			"emoji": "🛡️",
			"phosCost": 8,
			"phorosCost": 1,
			"maxLevel": 3,
			"levelCosts": [null, 12, 20],
			"levelDescs": ["+8 Defense.", "+16 Defense.", "+24 Defense."],
			"apply": KT_GENERAL_CARDS__kt_defense__apply,
		},
		{
			"id": "kt_iron_will",
			"name": "Iron Will",
			"emoji": "🩹",
			"phosCost": 12,
			"phorosCost": 3,
			"maxLevel": 3,
			"levelCosts": [null, 18, 30],
			"levelDescs": ["Revive with 30% HP.", "Revive with 50% HP.", "Revive with 75% HP."],
			"apply": KT_GENERAL_CARDS__kt_iron_will__apply,
		},
		{
			"id": "kt_treasure",
			"name": "Treasure Sense",
			"emoji": "💰",
			"phosCost": 10,
			"phorosCost": 1,
			"maxLevel": 3,
			"levelCosts": [null, 15, 25],
			"levelDescs": ["+10% gold.", "+20% gold.", "+30% gold."],
			"apply": KT_GENERAL_CARDS__kt_treasure__apply,
		},
		{
			"id": "kt_inheritance",
			"name": "Inheritance",
			"emoji": "🏦",
			"phosCost": 8,
			"phorosCost": 1,
			"maxLevel": 3,
			"levelCosts": [null, 12, 20],
			"levelDescs": ["Start with +100g.", "Start with +175g.", "Start with +250g."],
			"apply": KT_GENERAL_CARDS__kt_inheritance__apply,
		},
		{
			"id": "kt_kindled",
			"name": "Kindled Affinity",
			"emoji": "🔸",
			"phosCost": 14,
			"phorosCost": 1,
			"maxLevel": 3,
			"levelCosts": [null, 20, 32],
			"levelDescs": ["+16% Kindled spell chance.", "+24% Kindled spell chance.", "+32% Kindled spell chance."],
			"apply": KT_GENERAL_CARDS__kt_kindled__apply,
		},
		{
			"id": "kt_blazing",
			"name": "Blazing Affinity",
			"emoji": "🔶",
			"phosCost": 22,
			"phorosCost": 2,
			"maxLevel": 3,
			"levelCosts": [null, 30, 48],
			"levelDescs": ["+8% Blazing spell chance.", "+12% Blazing spell chance.", "+16% Blazing spell chance."],
			"apply": KT_GENERAL_CARDS__kt_blazing__apply,
		},
		{
			"id": "kt_radiant",
			"name": "Radiant Affinity",
			"emoji": "🌟",
			"phosCost": 40,
			"phorosCost": 3,
			"maxLevel": 3,
			"levelCosts": [null, 55, 80],
			"levelDescs": ["+4% Radiant spell chance.", "+6% Radiant spell chance.", "+8% Radiant spell chance."],
			"apply": KT_GENERAL_CARDS__kt_radiant__apply,
		},
		{
			"id": "kt_origination",
			"name": "Origination",
			"emoji": "⚗️",
			"phosCost": 20,
			"phorosCost": 2,
			"maxLevel": 5,
			"levelCosts": [null, 25, 35, 50, 70],
			"levelDescs": [
				"2+ elemental curses on enemy: +5 flat damage per hit.",
				"2+ elemental curses on enemy: +10 flat damage per hit.",
				"2+ elemental curses on enemy: +15 flat damage per hit.",
				"2+ elemental curses on enemy: +20 flat damage per hit.",
				"2+ elemental curses on enemy: +25 flat damage per hit.",
			],
			"apply": KT_GENERAL_CARDS__kt_origination__apply,
		},
		{
			"id": "kt_rerolls",
			"name": "Fortune",
			"emoji": "🎲",
			"phosCost": 10,
			"phorosCost": 1,
			"maxLevel": 5,
			"levelCosts": [null, 14, 22, 34, 50],
			"levelDescs": [
				"Start each run with 3 rerolls.",
				"Start each run with 4 rerolls.",
				"Start each run with 5 rerolls.",
				"Start each run with 6 rerolls.",
				"Start each run with 7 rerolls.",
			],
			"apply": KT_GENERAL_CARDS__kt_rerolls__apply,
		},
		{
			"id": "kt_abundance",
			"name": "Abundance",
			"emoji": "◈",
			"phosCost": 12,
			"phorosCost": 2,
			"maxLevel": 5,
			"levelCosts": [null, 16, 26, 40, 58],
			"levelDescs": [
				"+5% Phoros budget (both pools).",
				"+10% Phoros budget (both pools).",
				"+20% Phoros budget (both pools).",
				"+25% Phoros budget (both pools).",
				"+30% Phoros budget (both pools).",
			],
			"apply": KT_GENERAL_CARDS__kt_abundance__apply,
		},
		{
			"id": "kt_recovery",
			"name": "Recovery",
			"emoji": "💊",
			"phosCost": 12,
			"phorosCost": 2,
			"maxLevel": 5,
			"levelCosts": [null, 16, 24, 36, 52],
			"levelDescs": [
				"Heal 5% max HP after each battle.",
				"Heal 10% max HP after each battle.",
				"Heal 15% max HP after each battle.",
				"Heal 20% max HP after each battle.",
				"Heal 25% max HP after each battle.",
			],
			"apply": KT_GENERAL_CARDS__kt_recovery__apply,
		},
		{
			"id": "kt_strength",
			"name": "Strength",
			"emoji": "🗡️",
			"phosCost": 50,
			"phorosCost": 5,
			"maxLevel": 3,
			"levelCosts": [null, 65, 85],
			"levelDescs": [
				"No lives left: +10% dmg, take 25% less.",
				"No lives left: +15% dmg, take 35% less.",
				"No lives left: +20% dmg, take 40% less.",
			],
			"apply": KT_GENERAL_CARDS__kt_strength__apply,
		},
	]
	# ── Elemental Cards — 4 per element, always 1 row ────────────────────────────
	# 4th card per element is a starting spell (maxLevel:1, no upgrades)
	KT_ELEMENTAL_CARDS = {
		"Fire": [
			{
				"id": "kt_fire_burns",
				"name": "Hotter Burns",
				"emoji": "🔥",
				"phosCost": 12,
				"phorosCost": 1,
				"maxLevel": 3,
				"levelCosts": [null, 18, 28],
				"levelDescs": ["+0.2 bonus burn/stack.", "+0.4 bonus burn/stack.", "+0.6 bonus burn/stack."],
				"apply": KT_ELEMENTAL_CARDS__Fire__kt_fire_burns__apply,
			},
			{
				"id": "kt_fire_kindling",
				"name": "Kindling",
				"emoji": "🪵",
				"phosCost": 10,
				"phorosCost": 1,
				"maxLevel": 3,
				"levelCosts": [null, 14, 22],
				"levelDescs": ["Start battles with 2 Burn.", "4 Burn.", "6 Burn."],
				"apply": KT_ELEMENTAL_CARDS__Fire__kt_fire_kindling__apply,
			},
			{
				"id": "kt_fire_dmg",
				"name": "Pyroclasm",
				"emoji": "💥",
				"phosCost": 14,
				"phorosCost": 2,
				"maxLevel": 3,
				"levelCosts": [null, 22, 35],
				"levelDescs": ["+10% Fire spell damage.", "+15% Fire spell damage.", "+20% Fire spell damage."],
				"apply": KT_ELEMENTAL_CARDS__Fire__kt_fire_dmg__apply,
			},
			{
				"id": "kt_fire_starter",
				"name": "Ignite",
				"emoji": "🔥",
				"phosCost": 8,
				"phorosCost": 1,
				"maxLevel": 3,
				"levelCosts": [null, 14, 24],
				"levelDescs": [
					"Add Ignite (Dim) to your starting deck.",
					"Add Ignite (Kindled) to your starting deck.",
					"Add Ignite (Blazing) to your starting deck.",
				],
				"apply": KT_ELEMENTAL_CARDS__Fire__kt_fire_starter__apply,
			},
		],
		"Lightning": [
			{
				"id": "kt_lightning_shock",
				"name": "Conductor",
				"emoji": "⚡",
				"phosCost": 12,
				"phorosCost": 1,
				"maxLevel": 3,
				"levelCosts": [null, 18, 28],
				"levelDescs": ["+0.5 Shock/hit.", "+1 Shock/hit.", "+1.5 Shock/hit."],
				"apply": KT_ELEMENTAL_CARDS__Lightning__kt_lightning_shock__apply,
			},
			{
				"id": "kt_lightning_surge",
				"name": "Surge",
				"emoji": "💥",
				"phosCost": 12,
				"phorosCost": 2,
				"maxLevel": 3,
				"levelCosts": [null, 18, 28],
				"levelDescs": ["Overload floor +15%.", "Overload floor +25%.", "Overload floor +35%."],
				"apply": KT_ELEMENTAL_CARDS__Lightning__kt_lightning_surge__apply,
			},
			{
				"id": "kt_lightning_dmg",
				"name": "Voltage",
				"emoji": "🔌",
				"phosCost": 14,
				"phorosCost": 2,
				"maxLevel": 3,
				"levelCosts": [null, 22, 35],
				"levelDescs": ["+10% Lightning spell damage.", "+15%.", "+20%."],
				"apply": KT_ELEMENTAL_CARDS__Lightning__kt_lightning_dmg__apply,
			},
			{
				"id": "kt_lightning_starter",
				"name": "Zap",
				"emoji": "⚡",
				"phosCost": 8,
				"phorosCost": 1,
				"maxLevel": 3,
				"levelCosts": [null, 14, 24],
				"levelDescs": [
					"Add Zap (Dim) to your starting deck.",
					"Add Zap (Kindled) to your starting deck.",
					"Add Zap (Blazing) to your starting deck.",
				],
				"apply": KT_ELEMENTAL_CARDS__Lightning__kt_lightning_starter__apply,
			},
		],
		"Nature": [
			{
				"id": "kt_nature_root",
				"name": "Deep Roots",
				"emoji": "🌿",
				"phosCost": 12,
				"phorosCost": 1,
				"maxLevel": 3,
				"levelCosts": [null, 18, 28],
				"levelDescs": ["+0.5 Root/proc.", "+1 Root/proc.", "+1.5 Root/proc."],
				"apply": KT_ELEMENTAL_CARDS__Nature__kt_nature_root__apply,
			},
			{
				"id": "kt_nature_treant",
				"name": "Ancient Grove",
				"emoji": "🌳",
				"phosCost": 10,
				"phorosCost": 1,
				"maxLevel": 3,
				"levelCosts": [null, 14, 22],
				"levelDescs": ["Treants start +20 HP.", "+40 HP.", "+60 HP."],
				"apply": KT_ELEMENTAL_CARDS__Nature__kt_nature_treant__apply,
			},
			{
				"id": "kt_nature_dmg",
				"name": "Verdant",
				"emoji": "🌱",
				"phosCost": 14,
				"phorosCost": 2,
				"maxLevel": 3,
				"levelCosts": [null, 22, 35],
				"levelDescs": ["+10% Nature spell damage.", "+15%.", "+20%."],
				"apply": KT_ELEMENTAL_CARDS__Nature__kt_nature_dmg__apply,
			},
			{
				"id": "kt_nature_starter",
				"name": "Vine Strike",
				"emoji": "🌿",
				"phosCost": 8,
				"phorosCost": 1,
				"maxLevel": 3,
				"levelCosts": [null, 14, 24],
				"levelDescs": [
					"Add Vine Strike (Dim) to your starting deck.",
					"Add Vine Strike (Kindled) to your starting deck.",
					"Add Vine Strike (Blazing) to your starting deck.",
				],
				"apply": KT_ELEMENTAL_CARDS__Nature__kt_nature_starter__apply,
			},
		],
		"Air": [
			{
				"id": "kt_air_slipstream",
				"name": "Slipstream",
				"emoji": "💨",
				"phosCost": 15,
				"phorosCost": 4,
				"maxLevel": 3,
				"levelCosts": [null, 22, 35],
				"levelDescs": ["+1 action every 5 turns.", "+1 action every 4 turns.", "+1 action every 3 turns."],
				"apply": KT_ELEMENTAL_CARDS__Air__kt_air_slipstream__apply,
			},
			{
				"id": "kt_air_gust",
				"name": "Gust",
				"emoji": "🌪️",
				"phosCost": 12,
				"phorosCost": 2,
				"maxLevel": 3,
				"levelCosts": [null, 18, 28],
				"levelDescs": ["+1 hit on multi-hit Air spells.", "+2 hits.", "+3 hits."],
				"apply": KT_ELEMENTAL_CARDS__Air__kt_air_gust__apply,
			},
			{
				"id": "kt_air_dmg",
				"name": "Windshear",
				"emoji": "🌬️",
				"phosCost": 14,
				"phorosCost": 2,
				"maxLevel": 3,
				"levelCosts": [null, 22, 35],
				"levelDescs": ["+10% Air spell damage.", "+15%.", "+20%."],
				"apply": KT_ELEMENTAL_CARDS__Air__kt_air_dmg__apply,
			},
			{
				"id": "kt_air_starter",
				"name": "Quintuple Hit",
				"emoji": "💨",
				"phosCost": 8,
				"phorosCost": 1,
				"maxLevel": 3,
				"levelCosts": [null, 14, 24],
				"levelDescs": [
					"Add Quintuple Hit (Dim) to your starting deck.",
					"Add Quintuple Hit (Kindled) to your starting deck.",
					"Add Quintuple Hit (Blazing) to your starting deck.",
				],
				"apply": KT_ELEMENTAL_CARDS__Air__kt_air_starter__apply,
			},
		],
	}

func ktGetBudget(meta = null, type_ = null):
	var key = ("ktBudgetElementalLevel" if JS.eq(type_, "elemental") else "ktBudgetGeneralLevel")
	var base = (KT_ELEMENTAL_BUDGET_BASE if JS.eq(type_, "elemental") else KT_GENERAL_BUDGET_BASE)
	var lvl = min(JS.or_(JS.idx(meta, key), 0), len(KT_BUDGET_UPGRADE_COSTS))
	var budget = base + (lvl * KT_BUDGET_PER_UPGRADE)
	if JS.includes(JS.or_(meta.get("ktEquipped"), []), "kt_abundance"):
		var cardLvl = JS.or_(JS.idx(JS.or_(meta.get("ktLevels"), {}), "kt_abundance"), 1)
		var pct = JS.idx([0.05, 0.1, 0.2, 0.25, 0.3], cardLvl - 1)
		budget = floori(budget * (1 + pct))
	return budget

func ktPhoresUsed(meta = null, type_ = null):
	var equipped = JS.or_(meta.get("ktEquipped"), [])
	var pool = (JS.flat(JS.values(KT_ELEMENTAL_CARDS)) if JS.eq(type_, "elemental") else KT_GENERAL_CARDS)
	var _fn1 = func(sum = null, id = null):
		var card = JS.find(pool, func(c = null): return JS.eq(c.id, id))
		return sum + (card.get("phorosCost") if JS.t(card) else 0)
	return JS.reduce(equipped, _fn1, 0)

func ktGetCardLevel(meta = null, cardId = null):
	return JS.or_(JS.idx(JS.or_(meta.get("ktLevels"), {}), cardId), 1)

# ── Apply equipped cards at run start ────────────────────────────────────────
func applyKnowledgeTreeCards():
	var meta = Artifacts.getMeta()
	var equipped = JS.or_(meta.get("ktEquipped"), [])
	if not JS.t(len(equipped)):
		return
	var allCards = JS.arr(KT_GENERAL_CARDS) + JS.arr(JS.flat(JS.values(KT_ELEMENTAL_CARDS)))
	for id in JS.iter(equipped):
		var card = JS.find(allCards, func(c = null): return JS.eq(c.id, id))
		if (JS.t(card) and JS.t(card.get("apply"))):
			JS.callm(card, "apply", [ktGetCardLevel(meta, id)])

# ── Apply KT starter spells after giveStarterSpell() ─────────────────────────
func ktApplyStarterSpells():
	if (not JS.t(State.player.get("_ktStarterSpells")) or not JS.t(len(State.player.get("_ktStarterSpells")))):
		return
	for entry in JS.iter(State.player.get("_ktStarterSpells")):
		var elemName = (entry if (JS.typeof_(entry)) == "string" else entry.get("element"))
		var rarity = ("dim" if (JS.typeof_(entry)) == "string" else JS.or_(entry.get("rarity"), "dim"))
		var spellId = JS.idx(Spells.STARTER_SPELL, elemName)
		if not JS.t(spellId):
			continue
		var alreadyOwned = JS.some(JS.or_(State.player.get("spellbooks"), []), func(b = null): return JS.some(b.get("spells"), func(s = null): return JS.eq(s.id, spellId)))
		if not alreadyOwned:
			Spells.addSpellById(spellId, true, rarity)

# ── Unlock a card (Phos) ─────────────────────────────────────────────────────
func ktUnlockCard(cardId = null):
	var meta = Artifacts.getMeta()
	var allCards = JS.arr(KT_GENERAL_CARDS) + JS.arr(JS.flat(JS.values(KT_ELEMENTAL_CARDS)))
	var card = JS.find(allCards, func(c = null): return JS.eq(c.id, cardId))
	if not JS.t(card):
		return false
	if not JS.t(meta.get("ktUnlocked")):
		meta.ktUnlocked = []
	if JS.includes(meta.get("ktUnlocked"), cardId):
		return false
	if (JS.or_(meta.get("phos"), 0)) < card.get("phosCost"):
		return false
	meta.phos -= card.get("phosCost")
	meta.get("ktUnlocked").append(cardId)
	if not JS.t(meta.get("ktLevels")):
		meta.ktLevels = {}
	meta.get("ktLevels")[cardId] = 1
	Artifacts.saveMeta()
	return true

# ── Level up a card (Phos) ───────────────────────────────────────────────────
func ktUpgradeCard(cardId = null):
	var meta = Artifacts.getMeta()
	var allCards = JS.arr(KT_GENERAL_CARDS) + JS.arr(JS.flat(JS.values(KT_ELEMENTAL_CARDS)))
	var card = JS.find(allCards, func(c = null): return JS.eq(c.id, cardId))
	if not JS.t(card):
		return false
	if (not JS.t(meta.get("ktUnlocked")) or not JS.includes(meta.get("ktUnlocked"), cardId)):
		return false
	if not JS.t(meta.get("ktLevels")):
		meta.ktLevels = {}
	var currentLevel = JS.or_(JS.idx(meta.get("ktLevels"), cardId), 1)
	if currentLevel >= card.get("maxLevel"):
		return false
	var nextLevel = currentLevel + 1
	var cost = JS.idx(card.get("levelCosts"), nextLevel - 1)
	if (not JS.t(cost) or (JS.or_(meta.get("phos"), 0)) < cost):
		return false
	meta.phos -= cost
	meta.get("ktLevels")[cardId] = nextLevel
	Artifacts.saveMeta()
	return true

# ── Equip / unequip a card (uses type-specific Phoros budget) ────────────────
func ktEquipCard(cardId = null):
	var meta = Artifacts.getMeta()
	if (not JS.t(meta.get("ktUnlocked")) or not JS.includes(meta.get("ktUnlocked"), cardId)):
		return false
	if not JS.t(meta.get("ktEquipped")):
		meta.ktEquipped = []
	if JS.includes(meta.get("ktEquipped"), cardId):
		meta.ktEquipped = JS.arr(meta.get("ktEquipped")).filter(func(id = null): return not JS.eq(id, cardId))
		Artifacts.saveMeta()
		return true
	var isGeneral = JS.some(KT_GENERAL_CARDS, func(c = null): return JS.eq(c.id, cardId))
	var type_ = ("general" if isGeneral else "elemental")
	var pool = (KT_GENERAL_CARDS if isGeneral else JS.flat(JS.values(KT_ELEMENTAL_CARDS)))
	var card = JS.find(pool, func(c = null): return JS.eq(c.id, cardId))
	if not JS.t(card):
		return false
	if (ktPhoresUsed(meta, type_) + card.get("phorosCost")) > ktGetBudget(meta, type_):
		return false
	meta.get("ktEquipped").append(cardId)
	Artifacts.saveMeta()
	return true

# ── Expand a budget pool (Phos) ──────────────────────────────────────────────
func ktUpgradeBudget(type_ = null):
	var meta = Artifacts.getMeta()
	var key = ("ktBudgetElementalLevel" if JS.eq(type_, "elemental") else "ktBudgetGeneralLevel")
	var lvl = JS.or_(JS.idx(meta, key), 0)
	if lvl >= len(KT_BUDGET_UPGRADE_COSTS):
		return false
	var cost = JS.idx(KT_BUDGET_UPGRADE_COSTS, lvl)
	if (JS.or_(meta.get("phos"), 0)) < cost:
		return false
	meta.phos -= cost
	meta[key] = lvl + 1
	Artifacts.saveMeta()
	return true

func KT_GENERAL_CARDS__kt_extra_life__apply(lvl = null):
	# ── Row 1 ──────────────────────────────────────────────────────────────────
	State.player.revives = (JS.or_(State.player.get("revives"), 0)) + lvl

func KT_GENERAL_CARDS__kt_vitality__apply(lvl = null):
	var pct = JS.idx([0.1, 0.2, 0.3, 0.4, 0.5], lvl - 1)
	var base = Constants.BASE_MAX_HP + (JS.or_(State.player.get("baseMaxHPBonus"), 0))
	State.player.baseMaxHPBonus = (JS.or_(State.player.get("baseMaxHPBonus"), 0)) + floori(base * pct)

func KT_GENERAL_CARDS__kt_attack__apply(lvl = null):
	State.player.attackPower += lvl * 5

func KT_GENERAL_CARDS__kt_effect__apply(lvl = null):
	State.player.effectPower += lvl * 8

func KT_GENERAL_CARDS__kt_defense__apply(lvl = null):
	# ── Row 2 ──────────────────────────────────────────────────────────────────
	State.player.defense += lvl * 8

func KT_GENERAL_CARDS__kt_iron_will__apply(lvl = null):
	State.player._talentReviveBonus = (JS.or_(State.player.get("_talentReviveBonus"), 0)) + JS.un(JS.idx([0.3, 0.5, 0.75], lvl - 1))

func KT_GENERAL_CARDS__kt_treasure__apply(lvl = null):
	State.player._goldBonus = (JS.or_(State.player.get("_goldBonus"), 0)) + (lvl * 0.1)

func KT_GENERAL_CARDS__kt_inheritance__apply(lvl = null):
	State.player.gold += JS.idx([100, 175, 250], lvl - 1)

func KT_GENERAL_CARDS__kt_kindled__apply(lvl = null):
	# ── Row 3 ──────────────────────────────────────────────────────────────────
	State.player._rarityChanceKindled = ((JS.or_(State.player.get("_rarityChanceKindled"), 0)) + (lvl * 0.08)) + 0.08

func KT_GENERAL_CARDS__kt_blazing__apply(lvl = null):
	State.player._rarityChanceBlazing = ((JS.or_(State.player.get("_rarityChanceBlazing"), 0)) + (lvl * 0.04)) + 0.04

func KT_GENERAL_CARDS__kt_radiant__apply(lvl = null):
	State.player._rarityChanceRadiant = ((JS.or_(State.player.get("_rarityChanceRadiant"), 0)) + (lvl * 0.02)) + 0.02

func KT_GENERAL_CARDS__kt_origination__apply(lvl = null):
	State.player._ktOriginationLevel = lvl

func KT_GENERAL_CARDS__kt_rerolls__apply(lvl = null):
	State.player._rerolls = (JS.or_(State.player.get("_rerolls"), 0)) + (lvl + 2)

func KT_GENERAL_CARDS__kt_abundance__apply(lvl = null):
	pass

func KT_GENERAL_CARDS__kt_recovery__apply(lvl = null):
	# budget boost is applied via ktGetBudget
	State.player._ktRecoveryPct = lvl * 0.05

func KT_GENERAL_CARDS__kt_strength__apply(lvl = null):
	State.player._ktStrengthPassive = true
	State.player._ktStrengthLevel = lvl

func KT_ELEMENTAL_CARDS__Fire__kt_fire_burns__apply(lvl = null):
	State.player._talentBurnDmg = (JS.or_(State.player.get("_talentBurnDmg"), 0)) + (lvl * 0.2)

func KT_ELEMENTAL_CARDS__Fire__kt_fire_kindling__apply(lvl = null):
	State.player._talentBurnStart = (JS.or_(State.player.get("_talentBurnStart"), 0)) + (lvl * 2)

func KT_ELEMENTAL_CARDS__Fire__kt_fire_dmg__apply(lvl = null):
	State.player._talentFireDmgMult = ((JS.or_(State.player.get("_talentFireDmgMult"), 1.0)) + (lvl * 0.05)) + 0.05

func KT_ELEMENTAL_CARDS__Fire__kt_fire_starter__apply(lvl = null):
	if not JS.t(State.player.get("_ktStarterSpells")):
		State.player._ktStarterSpells = []
	State.player.get("_ktStarterSpells").append({"element": "Fire", "rarity": JS.idx(["dim", "kindled", "blazing"], lvl - 1)})

func KT_ELEMENTAL_CARDS__Lightning__kt_lightning_shock__apply(lvl = null):
	State.player._talentShockBonus = (JS.or_(State.player.get("_talentShockBonus"), 0)) + (lvl * 0.5)

func KT_ELEMENTAL_CARDS__Lightning__kt_lightning_surge__apply(lvl = null):
	State.player._talentOverloadFloor = ((JS.or_(State.player.get("_talentOverloadFloor"), 0.25)) + (lvl * 0.1)) + 0.05

func KT_ELEMENTAL_CARDS__Lightning__kt_lightning_dmg__apply(lvl = null):
	State.player._talentLightDmgMult = ((JS.or_(State.player.get("_talentLightDmgMult"), 1.0)) + (lvl * 0.05)) + 0.05

func KT_ELEMENTAL_CARDS__Lightning__kt_lightning_starter__apply(lvl = null):
	if not JS.t(State.player.get("_ktStarterSpells")):
		State.player._ktStarterSpells = []
	State.player.get("_ktStarterSpells").append({"element": "Lightning", "rarity": JS.idx(["dim", "kindled", "blazing"], lvl - 1)})

func KT_ELEMENTAL_CARDS__Nature__kt_nature_root__apply(lvl = null):
	State.player._talentRootBonus = (JS.or_(State.player.get("_talentRootBonus"), 0)) + (lvl * 0.5)

func KT_ELEMENTAL_CARDS__Nature__kt_nature_treant__apply(lvl = null):
	State.player._talentTreantHP = (JS.or_(State.player.get("_talentTreantHP"), 0)) + (lvl * 20)

func KT_ELEMENTAL_CARDS__Nature__kt_nature_dmg__apply(lvl = null):
	State.player._talentNatureDmgMult = ((JS.or_(State.player.get("_talentNatureDmgMult"), 1.0)) + (lvl * 0.05)) + 0.05

func KT_ELEMENTAL_CARDS__Nature__kt_nature_starter__apply(lvl = null):
	if not JS.t(State.player.get("_ktStarterSpells")):
		State.player._ktStarterSpells = []
	State.player.get("_ktStarterSpells").append({"element": "Nature", "rarity": JS.idx(["dim", "kindled", "blazing"], lvl - 1)})

func KT_ELEMENTAL_CARDS__Air__kt_air_slipstream__apply(lvl = null):
	State.player._slipstreamInterval = JS.idx([5, 4, 3], lvl - 1)

func KT_ELEMENTAL_CARDS__Air__kt_air_gust__apply(lvl = null):
	State.player._talentAirHits = (JS.or_(State.player.get("_talentAirHits"), 0)) + lvl

func KT_ELEMENTAL_CARDS__Air__kt_air_dmg__apply(lvl = null):
	State.player._talentAirDmgMult = ((JS.or_(State.player.get("_talentAirDmgMult"), 1.0)) + (lvl * 0.05)) + 0.05

func KT_ELEMENTAL_CARDS__Air__kt_air_starter__apply(lvl = null):
	if not JS.t(State.player.get("_ktStarterSpells")):
		State.player._ktStarterSpells = []
	State.player.get("_ktStarterSpells").append({"element": "Air", "rarity": JS.idx(["dim", "kindled", "blazing"], lvl - 1)})
