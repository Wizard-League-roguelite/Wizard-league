# Spellbooks — generated from js/data/spellbooks.js by tools/js2gd.js
extends Node

var SPELLBOOK_CATALOGUE = null
var BOOK_CATALOGUE_IDS = null
var BOOK_RARITY_WEIGHTS = null

func _boot():
	SPELLBOOK_CATALOGUE = {
		"fire_tome": {
			"id": "fire_tome",
			"name": "Emberheart Tome",
			"emoji": "🔥",
			"rarity": "element",
			"element": "Fire",
			"desc": "Each spell cast applies bonus Burn stacks to enemies.",
			"negative": "You lose 2 HP per spell cast (cannot kill you).",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [15, 25, 40, 60],
			"levelDescs": [
				"+1 Burn stack per spell. −2 HP per cast.",
				"+2 Burn stacks per spell. −2 HP per cast.",
				"+3 Burn stacks per spell. −2 HP per cast.",
				"+3 Burn. +5 Effect Power aura. −2 HP per cast.",
				"+4 Burn. +10 Effect Power aura. −2 HP per cast.",
			],
			"aura": SPELLBOOK_CATALOGUE__fire_tome__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__fire_tome__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__fire_tome__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__fire_tome__onSwitchAway,
		},
		"tide_codex": {
			"id": "tide_codex",
			"name": "Tidal Codex",
			"emoji": "🌊",
			"rarity": "element",
			"element": "Water",
			"desc": "Each spell restores HP. Switching to this book costs HP.",
			"negative": "Lose 5 HP when switching to this book in combat.",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [15, 25, 40, 60],
			"levelDescs": [
				"Restore 3 HP per spell. −5 HP on switch-to.",
				"Restore 4 HP per spell. −5 HP on switch-to.",
				"Restore 6 HP per spell. −5 HP on switch-to.",
				"Restore 6 HP. +5 DEF aura. −5 HP on switch-to.",
				"Restore 8 HP. +8 DEF aura. −5 HP on switch-to.",
			],
			"aura": SPELLBOOK_CATALOGUE__tide_codex__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__tide_codex__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__tide_codex__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__tide_codex__onSwitchAway,
		},
		"frost_grimoire": {
			"id": "frost_grimoire",
			"name": "Glacial Grimoire",
			"emoji": "❄️",
			"rarity": "element",
			"element": "Ice",
			"desc": "Each spell applies Frost stacks to the enemy.",
			"negative": "−5 Defense while this book is active.",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [15, 25, 40, 60],
			"levelDescs": [
				"+1 Frost per spell. −5 DEF aura.",
				"+1 Frost per spell. −5 DEF aura.",
				"+2 Frost per spell. −5 DEF aura.",
				"+2 Frost. +6 ATK aura. −5 DEF.",
				"+3 Frost. +10 ATK aura. −5 DEF.",
			],
			"aura": SPELLBOOK_CATALOGUE__frost_grimoire__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__frost_grimoire__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__frost_grimoire__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__frost_grimoire__onSwitchAway,
		},
		"storm_codex": {
			"id": "storm_codex",
			"name": "Storm Codex",
			"emoji": "⚡",
			"rarity": "element",
			"element": "Lightning",
			"desc": "Each spell applies Shock stacks to the enemy.",
			"negative": "−5 Attack Power while this book is active.",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [15, 25, 40, 60],
			"levelDescs": [
				"+1 Shock per spell. −5 ATK aura.",
				"+2 Shock per spell. −5 ATK aura.",
				"+2 Shock per spell. −5 ATK aura.",
				"+3 Shock. +5 EFX aura. −5 ATK.",
				"+4 Shock. +8 EFX aura. −5 ATK.",
			],
			"aura": SPELLBOOK_CATALOGUE__storm_codex__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__storm_codex__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__storm_codex__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__storm_codex__onSwitchAway,
		},
		"earth_ledger": {
			"id": "earth_ledger",
			"name": "Earthen Ledger",
			"emoji": "🪨",
			"rarity": "element",
			"element": "Earth",
			"desc": "Defense aura for both sides. Each spell cast grants Block.",
			"negative": "Aura buffs enemies too. Spells deal less damage (−8 ATK).",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [15, 25, 40, 60],
			"levelDescs": [
				"+3 DEF aura (both sides). +1 Block per spell. −8 ATK.",
				"+4 DEF aura (both sides). +2 Block per spell. −8 ATK.",
				"+6 DEF aura (both sides). +3 Block per spell. −8 ATK.",
				"+8 DEF aura (both sides). +4 Block per spell. −8 ATK.",
				"+10 DEF aura (both sides). +5 Block per spell. −8 ATK.",
			],
			"aura": SPELLBOOK_CATALOGUE__earth_ledger__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__earth_ledger__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__earth_ledger__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__earth_ledger__onSwitchAway,
		},
		"verdant_codex": {
			"id": "verdant_codex",
			"name": "Verdant Codex",
			"emoji": "🌿",
			"rarity": "element",
			"element": "Nature",
			"desc": "Regenerate HP at the start of each turn.",
			"negative": "−5 Attack Power while this book is active.",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [15, 25, 40, 60],
			"levelDescs": [
				"Regen 4 HP per turn. −5 ATK aura.",
				"Regen 7 HP per turn. −5 ATK aura.",
				"Regen 10 HP per turn. −5 ATK aura.",
				"Regen 14 HP per turn. +5 EFX aura. −5 ATK.",
				"Regen 20 HP per turn. +8 EFX aura. −5 ATK.",
			],
			"aura": SPELLBOOK_CATALOGUE__verdant_codex__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__verdant_codex__onSpellExecute,
			"onTurnStart": SPELLBOOK_CATALOGUE__verdant_codex__onTurnStart,
			"onSwitchTo": SPELLBOOK_CATALOGUE__verdant_codex__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__verdant_codex__onSwitchAway,
		},
		"gale_sketchbook": {
			"id": "gale_sketchbook",
			"name": "Gale Sketchbook",
			"emoji": "💨",
			"rarity": "element",
			"element": "Air",
			"desc": "Each spell has a chance to grant a bonus action next turn.",
			"negative": "−5 Defense while this book is active.",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [15, 25, 40, 60],
			"levelDescs": [
				"20% chance: +1 action next turn. −5 DEF aura.",
				"25% chance: +1 action next turn. −5 DEF aura.",
				"30% chance: +1 action next turn. −5 DEF aura.",
				"35% chance. +4 ATK aura. −5 DEF.",
				"40% chance. +8 ATK aura. −5 DEF.",
			],
			"aura": SPELLBOOK_CATALOGUE__gale_sketchbook__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__gale_sketchbook__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__gale_sketchbook__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__gale_sketchbook__onSwitchAway,
		},
		"plasma_atlas": {
			"id": "plasma_atlas",
			"name": "Plasma Atlas",
			"emoji": "🔮",
			"rarity": "element",
			"element": "Plasma",
			"desc": "Each spell generates Plasma Charge.",
			"negative": "Max Plasma Charge −3 (17 cap) until level 4.",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [15, 25, 40, 60],
			"levelDescs": [
				"+1 Charge per spell. Max charge 17.",
				"+1 Charge per spell. Max charge 17.",
				"+2 Charge per spell. Max charge 17.",
				"+2 Charge per spell. Max charge 17.",
				"+3 Charge per spell. Max charge restored to 20.",
			],
			"aura": SPELLBOOK_CATALOGUE__plasma_atlas__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__plasma_atlas__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__plasma_atlas__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__plasma_atlas__onSwitchAway,
		},
		"codex_of_power": {
			"id": "codex_of_power",
			"name": "Codex of Power",
			"emoji": "⚔️",
			"rarity": "generic",
			"element": null,
			"desc": "Massive Attack Power aura for raw damage output.",
			"negative": "One fewer spell slot in this book (5 total).",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": -1,
			"passiveSlots": 0,
			"upgradeCosts": [20, 35, 55, 80],
			"levelDescs": [
				"+10 ATK aura. 5 spell slots.",
				"+13 ATK aura. 5 spell slots.",
				"+16 ATK aura. 5 spell slots.",
				"+20 ATK aura. 5 spell slots.",
				"+26 ATK aura. 5 spell slots.",
			],
			"aura": SPELLBOOK_CATALOGUE__codex_of_power__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__codex_of_power__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__codex_of_power__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__codex_of_power__onSwitchAway,
		},
		"guardians_ward": {
			"id": "guardians_ward",
			"name": "Guardian's Ward",
			"emoji": "🛡",
			"rarity": "generic",
			"element": null,
			"desc": "Free to switch to. Gain Block on switch. Strong Defense aura.",
			"negative": "Spells deal less damage (−8 effective ATK).",
			"freeSwitch": true,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [20, 35, 55, 80],
			"levelDescs": [
				"Free switch. Gain 5 Block on switch-to. +10 DEF aura. −8 ATK.",
				"Free switch. Gain 8 Block on switch-to. +14 DEF aura. −8 ATK.",
				"Free switch. Gain 10 Block on switch-to. +18 DEF aura. −8 ATK.",
				"Free switch. Gain 12 Block on switch-to. +22 DEF aura. −8 ATK.",
				"Free switch. Gain 15 Block on switch-to. +28 DEF aura. −8 ATK.",
			],
			"aura": SPELLBOOK_CATALOGUE__guardians_ward__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__guardians_ward__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__guardians_ward__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__guardians_ward__onSwitchAway,
		},
		"swiftblade_ms": {
			"id": "swiftblade_ms",
			"name": "Swiftblade Manuscript",
			"emoji": "🌪",
			"rarity": "generic",
			"element": null,
			"desc": "Free to switch to. Gain bonus actions on switching here.",
			"negative": "−5 Defense while this book is active.",
			"freeSwitch": true,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [20, 35, 55, 80],
			"levelDescs": [
				"Free switch. First switch per battle: +1 action. +8 ATK aura. −5 DEF.",
				"Free switch. First switch: +1 action. +11 ATK aura. −5 DEF.",
				"Free switch. First 2 switches: +1 action each. +14 ATK aura. −5 DEF.",
				"Free switch. First 2 switches: +1 action each. +18 ATK aura. −5 DEF.",
				"Free switch. Every switch: +1 action. +22 ATK aura. −5 DEF.",
			],
			"aura": SPELLBOOK_CATALOGUE__swiftblade_ms__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__swiftblade_ms__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__swiftblade_ms__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__swiftblade_ms__onSwitchAway,
		},
		"scholars_folio": {
			"id": "scholars_folio",
			"name": "Scholar's Folio",
			"emoji": "📚",
			"rarity": "generic",
			"element": null,
			"desc": "Switching to this book reduces all spell cooldowns.",
			"negative": "−8 effective ATK from aura.",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [20, 35, 55, 80],
			"levelDescs": [
				"Switch-to: −1 to all CDs. +5 EFX aura. −8 ATK.",
				"Switch-to: −1 to all CDs. +8 EFX aura. −8 ATK.",
				"Switch-to: −2 to all CDs. +8 EFX aura. −8 ATK.",
				"Switch-to: −2 to all CDs. +12 EFX aura. −8 ATK.",
				"Switch-to: −3 to all CDs. +15 EFX aura. −8 ATK.",
			],
			"aura": SPELLBOOK_CATALOGUE__scholars_folio__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__scholars_folio__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__scholars_folio__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__scholars_folio__onSwitchAway,
		},
		"hunters_notes": {
			"id": "hunters_notes",
			"name": "Hunter's Notes",
			"emoji": "🗡",
			"rarity": "generic",
			"element": null,
			"desc": "Heal after each spell cast. Strong ATK aura.",
			"negative": "−5 Defense while this book is active.",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [20, 35, 55, 80],
			"levelDescs": [
				"+2 HP per spell cast. +6 ATK aura. −5 DEF.",
				"+3 HP per cast. +8 ATK aura. −5 DEF.",
				"+4 HP per cast. +10 ATK aura. −5 DEF.",
				"+5 HP per cast. +11 ATK aura. −5 DEF.",
				"+7 HP per cast. +14 ATK aura. −5 DEF.",
			],
			"aura": SPELLBOOK_CATALOGUE__hunters_notes__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__hunters_notes__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__hunters_notes__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__hunters_notes__onSwitchAway,
		},
		"tome_of_time": {
			"id": "tome_of_time",
			"name": "Tome of Time",
			"emoji": "⏳",
			"rarity": "legendary",
			"element": null,
			"desc": "Every few turns, all spells in this book have their CD reduced by 1.",
			"negative": "Switching AWAY from this book costs +1 extra action.",
			"freeSwitch": false,
			"stickySwitch": true,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [40, 70, 110, 160],
			"levelDescs": [
				"−1 CD every 3 turns. Sticky: switch-away costs +1 action.",
				"−1 CD every 3 turns. +4 ATK aura. Sticky.",
				"−1 CD every 2 turns. +6 ATK aura. Sticky.",
				"−1 CD every 2 turns. +10 ATK aura. Sticky.",
				"−1 CD every turn. +13 ATK aura. Sticky.",
			],
			"aura": SPELLBOOK_CATALOGUE__tome_of_time__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__tome_of_time__onSpellExecute,
			"onTurnStart": SPELLBOOK_CATALOGUE__tome_of_time__onTurnStart,
			"onSwitchTo": SPELLBOOK_CATALOGUE__tome_of_time__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__tome_of_time__onSwitchAway,
		},
		"echo_grimoire": {
			"id": "echo_grimoire",
			"name": "Echo Grimoire",
			"emoji": "🌀",
			"rarity": "legendary",
			"element": null,
			"desc": "Your first non-builtin spell each turn deals a bonus echo hit.",
			"negative": "Only 5 spell slots and 1 passive slot.",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": -1,
			"passiveSlots": -1,
			"upgradeCosts": [40, 70, 110, 160],
			"levelDescs": [
				"First spell/turn: +40% ATK echo hit. 5 slots, 1 passive.",
				"First spell/turn: +48% ATK echo hit. 5 slots, 1 passive.",
				"First spell/turn: +56% ATK echo hit. 5 slots, 1 passive.",
				"First spell/turn: +64% ATK echo hit. 5 slots, 1 passive.",
				"First spell/turn: +80% ATK echo hit. 5 slots, 1 passive.",
			],
			"aura": SPELLBOOK_CATALOGUE__echo_grimoire__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__echo_grimoire__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__echo_grimoire__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__echo_grimoire__onSwitchAway,
		},
		"soul_codex": {
			"id": "soul_codex",
			"name": "Soul Codex",
			"emoji": "👁",
			"rarity": "legendary",
			"element": null,
			"desc": "Massive ATK aura for both sides. Spells cost HP.",
			"negative": "ATK aura buffs enemies too. Each non-builtin spell costs HP.",
			"freeSwitch": false,
			"stickySwitch": false,
			"spellSlots": 0,
			"passiveSlots": 0,
			"upgradeCosts": [40, 70, 110, 160],
			"levelDescs": [
				"Each spell: −5 HP, +16 ATK aura (both sides).",
				"Each spell: −5 HP, +20 ATK aura (both sides).",
				"Each spell: −4 HP, +24 ATK aura (both sides).",
				"Each spell: −4 HP, +28 ATK aura (both sides).",
				"Each spell: −3 HP, +32 ATK aura (both sides).",
			],
			"aura": SPELLBOOK_CATALOGUE__soul_codex__aura,
			"onSpellExecute": SPELLBOOK_CATALOGUE__soul_codex__onSpellExecute,
			"onSwitchTo": SPELLBOOK_CATALOGUE__soul_codex__onSwitchTo,
			"onSwitchAway": SPELLBOOK_CATALOGUE__soul_codex__onSwitchAway,
		},
	}
	# Ordered list of all catalogue IDs (for iteration)
	BOOK_CATALOGUE_IDS = JS.keys(SPELLBOOK_CATALOGUE)
	# Rarity weights for discovery pool
	BOOK_RARITY_WEIGHTS = {"element": 3, "generic": 2, "legendary": 1}

# ===== spellbooks.js =====
# ─── SPELLBOOK CATALOGUE ──────────────────────────────────────────────────────
# Persistent spellbooks discovered and upgraded in the Library between runs.
# Each book can be taken into a run and switched between in combat.
# Helper: safe heal (can't overheal beyond max)
func _bookHeal(amt = null, label = null):
	Helpers.applyHeal("player", amt, label)

func SPELLBOOK_CATALOGUE__fire_tome__aura(lvl = null):
	# ── ELEMENT BOOKS ──────────────────────────────────────────────────────────
	return {"atk": 0, "def": 0, "efx": JS.or_(JS.idx([0, 0, 0, 5, 10], lvl), 0)}

func SPELLBOOK_CATALOGUE__fire_tome__onSpellExecute(spell = null, lvl = null):
	if JS.t(spell.get("isBuiltin")):
		return
	var burns = JS.or_(JS.idx([1, 2, 3, 3, 4], lvl), 1)
	Helpers.applyBurn("enemy", burns, Helpers.effectPowerFor("player"))
	if State.player.hp > 2:
		State.player.hp -= 2
		UI.updateStatsUI()

func SPELLBOOK_CATALOGUE__fire_tome__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__fire_tome__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__tide_codex__aura(lvl = null):
	return {"atk": 0, "def": JS.or_(JS.idx([0, 0, 0, 5, 8], lvl), 0), "efx": 0}

func SPELLBOOK_CATALOGUE__tide_codex__onSpellExecute(spell = null, lvl = null):
	if JS.t(spell.get("isBuiltin")):
		return
	var heal = JS.or_(JS.idx([3, 4, 6, 6, 8], lvl), 3)
	_bookHeal(heal, "📘 Tidal Codex")

func SPELLBOOK_CATALOGUE__tide_codex__onSwitchTo(lvl = null):
	if ((true and JS.t(State.combat.get("playerTurn"))) and not JS.t(State.combat.get("over"))):
		if State.player.hp > 6:
			State.player.hp -= 5
			UI.updateStatsUI()
		UI.log_("📘 Tidal Codex: −5 HP on switch.", "status")

func SPELLBOOK_CATALOGUE__tide_codex__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__frost_grimoire__aura(lvl = null):
	return {"atk": JS.or_(JS.idx([0, 0, 0, 6, 10], lvl), 0), "def": -5, "efx": 0}

func SPELLBOOK_CATALOGUE__frost_grimoire__onSpellExecute(spell = null, lvl = null):
	if JS.t(spell.get("isBuiltin")):
		return
	var frost = JS.or_(JS.idx([1, 1, 2, 2, 3], lvl), 1)
	State.status.enemy.frostStacks = (JS.or_(State.status.enemy.get("frostStacks"), 0)) + frost

func SPELLBOOK_CATALOGUE__frost_grimoire__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__frost_grimoire__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__storm_codex__aura(lvl = null):
	return {"atk": -5, "def": 0, "efx": JS.or_(JS.idx([0, 0, 0, 5, 8], lvl), 0)}

func SPELLBOOK_CATALOGUE__storm_codex__onSpellExecute(spell = null, lvl = null):
	if JS.t(spell.get("isBuiltin")):
		return
	var shock = JS.or_(JS.idx([1, 2, 2, 3, 4], lvl), 1)
	State.status.enemy.shockStacks = (JS.or_(State.status.enemy.get("shockStacks"), 0)) + shock

func SPELLBOOK_CATALOGUE__storm_codex__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__storm_codex__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__earth_ledger__aura(lvl = null):
	return {"atk": -8, "def": JS.or_(JS.idx([3, 4, 6, 8, 10], lvl), 3), "efx": 0, "mutualAura": true}

func SPELLBOOK_CATALOGUE__earth_ledger__onSpellExecute(spell = null, lvl = null):
	if JS.t(spell.get("isBuiltin")):
		return
	var block = JS.or_(JS.idx([1, 2, 3, 4, 5], lvl), 1)
	State.status.player.block = (JS.or_(State.status.player.get("block"), 0)) + block

func SPELLBOOK_CATALOGUE__earth_ledger__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__earth_ledger__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__verdant_codex__aura(lvl = null):
	return {"atk": -5, "def": 0, "efx": JS.or_(JS.idx([0, 0, 0, 5, 8], lvl), 0)}

func SPELLBOOK_CATALOGUE__verdant_codex__onSpellExecute(spell = null, lvl = null):
	pass

func SPELLBOOK_CATALOGUE__verdant_codex__onTurnStart(lvl = null):
	var regen = JS.or_(JS.idx([4, 7, 10, 14, 20], lvl), 4)
	_bookHeal(regen, "📔 Verdant Regen")

func SPELLBOOK_CATALOGUE__verdant_codex__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__verdant_codex__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__gale_sketchbook__aura(lvl = null):
	return {"atk": JS.or_(JS.idx([0, 0, 0, 4, 8], lvl), 0), "def": -5, "efx": 0}

func SPELLBOOK_CATALOGUE__gale_sketchbook__onSpellExecute(spell = null, lvl = null):
	if JS.t(spell.get("isBuiltin")):
		return
	var chance = JS.or_(JS.idx([0.2, 0.25, 0.3, 0.35, 0.4], lvl), 0.2)
	if randf() < chance:
		State.status.player.nextTurnBonusActions = (JS.or_(State.status.player.get("nextTurnBonusActions"), 0)) + 1
		UI.log_("📑 Gale Sketchbook: +1 action next turn!", "status")

func SPELLBOOK_CATALOGUE__gale_sketchbook__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__gale_sketchbook__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__plasma_atlas__aura(lvl = null):
	return {"atk": 0, "def": 0, "efx": 0}

func SPELLBOOK_CATALOGUE__plasma_atlas__onSpellExecute(spell = null, lvl = null):
	if JS.t(spell.get("isBuiltin")):
		return
	var charge = JS.or_(JS.idx([1, 1, 2, 2, 3], lvl), 1)
	var cap = (20 if lvl >= 4 else 17)
	if JS.t(State.status.get("player")):
		State.status.player.plasmaCharge = min((JS.or_(State.status.player.get("plasmaCharge"), 0)) + charge, cap)
		Spells.updateChargeUI()

func SPELLBOOK_CATALOGUE__plasma_atlas__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__plasma_atlas__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__codex_of_power__aura(lvl = null):
	# ── GENERIC BOOKS ──────────────────────────────────────────────────────────
	return {"atk": JS.or_(JS.idx([10, 13, 16, 20, 26], lvl), 10), "def": 0, "efx": 0}

func SPELLBOOK_CATALOGUE__codex_of_power__onSpellExecute(spell = null, lvl = null):
	pass

func SPELLBOOK_CATALOGUE__codex_of_power__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__codex_of_power__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__guardians_ward__aura(lvl = null):
	return {"atk": -8, "def": JS.or_(JS.idx([10, 14, 18, 22, 28], lvl), 10), "efx": 0}

func SPELLBOOK_CATALOGUE__guardians_ward__onSpellExecute(spell = null, lvl = null):
	pass

func SPELLBOOK_CATALOGUE__guardians_ward__onSwitchTo(lvl = null):
	if (false or not JS.t(State.combat.get("playerTurn"))):
		return
	var block = JS.or_(JS.idx([5, 8, 10, 12, 15], lvl), 5)
	State.status.player.block = (JS.or_(State.status.player.get("block"), 0)) + block
	UI.log_("🛡 Guardian's Ward: +" + JS.s(block) + " Block!", "heal")

func SPELLBOOK_CATALOGUE__guardians_ward__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__swiftblade_ms__aura(lvl = null):
	return {"atk": JS.or_(JS.idx([8, 11, 14, 18, 22], lvl), 8), "def": -5, "efx": 0}

func SPELLBOOK_CATALOGUE__swiftblade_ms__onSpellExecute(spell = null, lvl = null):
	pass

func SPELLBOOK_CATALOGUE__swiftblade_ms__onSwitchTo(lvl = null):
	if (false or not JS.t(State.combat.get("playerTurn"))):
		return
	var maxFree = JS.or_(JS.idx([1, 1, 2, 2, 999], lvl), 1)
	var sw = JS.or_(State.combat.get("_swiftbladeSwitch"), 0)
	if sw < maxFree:
		State.combat.actionsLeft = (JS.or_(State.combat.get("actionsLeft"), 0)) + 1
		Combat.updateActionUI()
		UI.log_("🌪 Swiftblade Manuscript: +1 action!", "status")
	State.combat._swiftbladeSwitch = sw + 1

func SPELLBOOK_CATALOGUE__swiftblade_ms__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__scholars_folio__aura(lvl = null):
	return {"atk": -8, "def": 0, "efx": JS.or_(JS.idx([5, 8, 8, 12, 15], lvl), 5)}

func SPELLBOOK_CATALOGUE__scholars_folio__onSpellExecute(spell = null, lvl = null):
	pass

func SPELLBOOK_CATALOGUE__scholars_folio__onSwitchTo(lvl = null):
	var reduce = JS.or_(JS.idx([1, 1, 2, 2, 3], lvl), 1)
	var book = State.activeBook()
	if not JS.t(book):
		return
	for s in JS.iter(book.spells):
		if (JS.or_(s.get("currentCD"), 0)) > 0:
			s.currentCD = max(0, (JS.or_(s.get("currentCD"), 0)) - reduce)
	UI.log_("📚 Scholar's Folio: spell CDs −" + JS.s(reduce) + "!", "status")

func SPELLBOOK_CATALOGUE__scholars_folio__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__hunters_notes__aura(lvl = null):
	return {"atk": JS.or_(JS.idx([6, 8, 10, 11, 14], lvl), 6), "def": -5, "efx": 0}

func SPELLBOOK_CATALOGUE__hunters_notes__onSpellExecute(spell = null, lvl = null):
	if JS.t(spell.get("isBuiltin")):
		return
	var heal = JS.or_(JS.idx([2, 3, 4, 5, 7], lvl), 2)
	_bookHeal(heal, "🗡 Hunter's Notes")

func SPELLBOOK_CATALOGUE__hunters_notes__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__hunters_notes__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__tome_of_time__aura(lvl = null):
	# ── LEGENDARY BOOKS ────────────────────────────────────────────────────────
	return {"atk": JS.or_(JS.idx([0, 4, 6, 10, 13], lvl), 0), "def": 0, "efx": 0}

func SPELLBOOK_CATALOGUE__tome_of_time__onSpellExecute(spell = null, lvl = null):
	pass

func SPELLBOOK_CATALOGUE__tome_of_time__onTurnStart(lvl = null):
	var interval = JS.or_(JS.idx([3, 3, 2, 2, 1], lvl), 3)
	if (State.combat.turnInBattle > 0 and (JS.mod(State.combat.turnInBattle, interval)) == 0):
		var book = State.activeBook()
		if JS.t(book):
			for s in JS.iter(book.spells):
				if (JS.or_(s.get("currentCD"), 0)) > 0:
					s.currentCD = max(0, s.currentCD - 1)
		UI.log_("⏳ Tome of Time: all spell CDs −1", "status")

func SPELLBOOK_CATALOGUE__tome_of_time__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__tome_of_time__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__echo_grimoire__aura(lvl = null):
	return {"atk": 0, "def": 0, "efx": 0, "echoBonus": JS.or_(JS.idx([0.4, 0.48, 0.56, 0.64, 0.8], lvl), 0.4)}

func SPELLBOOK_CATALOGUE__echo_grimoire__onSpellExecute(spell = null, lvl = null):
	pass

func SPELLBOOK_CATALOGUE__echo_grimoire__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__echo_grimoire__onSwitchAway(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__soul_codex__aura(lvl = null):
	# Echo logic applied in _applyBookSpellEffect via aura.echoBonus
	return {"atk": JS.or_(JS.idx([16, 20, 24, 28, 32], lvl), 16), "def": 0, "efx": 0, "mutualAura": true}

func SPELLBOOK_CATALOGUE__soul_codex__onSpellExecute(spell = null, lvl = null):
	if JS.t(spell.get("isBuiltin")):
		return
	var cost = JS.or_(JS.idx([5, 5, 4, 4, 3], lvl), 5)
	if State.player.hp > (cost + 1):
		State.player.hp -= cost
		UI.updateStatsUI()

func SPELLBOOK_CATALOGUE__soul_codex__onSwitchTo(lvl = null):
	pass

func SPELLBOOK_CATALOGUE__soul_codex__onSwitchAway(lvl = null):
	pass
