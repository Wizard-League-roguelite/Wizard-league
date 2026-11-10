# EnemyAbilities — generated from js/logic/enemyAbilities.js by tools/js2gd.js
extends Node

var ENEMY_SPELL_VALUES = null
var ENEMY_ABILITY_CATALOGUE = null
var ENEMY_ABILITY_POOL = null
var ENEMY_SPELL_POOL_BY_ELEMENT = null
var ENEMY_ITEM_CATALOGUE = null
var ENEMY_ABILITY_HINTS = null

func _boot():
	# ===== enemyAbilities.js =====
	# ============================================================
	# ENEMY ABILITY SYSTEM
	# Each ability: { id, name, cd, baseCd, tier, fn(enemyIdx) }
	# tier: 0=basic, 1=secondary, 2=legendary
	# Enemies get abilities based on element + currentGymIdx (zone depth)
	# Spell-based abilities use ENEMY_SPELL_PARAMS at 60% baseDmg scaling.
	# ============================================================
	# ── Spell numeric params — name/emoji/element/tier come from SPELL_CATALOGUE ──
	# Only baseDmg is scaled to 60%; hits, effect stacks, heal, armor are unchanged.
	ENEMY_SPELL_VALUES = {
		"ignite": {"baseDmg": 5, "hits": 1, "effects": [{"type": "burn", "stacks": 15}], "baseCd": 2},
		"ember_storm": {"baseDmg": 5, "hits": 3, "effects": [{"type": "burn", "stacks": 3}], "baseCd": 3},
		"flame_wave": {"baseDmg": 12, "hits": 1, "effects": [{"type": "burn", "stacks": 7}], "baseCd": 3},
		"forge_blast": {"baseDmg": 8, "hits": 1, "effects": [{"type": "burn", "stacks": 8}], "baseCd": 3},
		"tidal_surge": {"baseDmg": 20, "hits": 1, "effects": [], "heal": 10, "baseCd": 2},
		"riptide": {"baseDmg": 8, "hits": 3, "effects": [], "baseCd": 3},
		"whirlpool": {"baseDmg": 18, "hits": 1, "effects": [], "foam": 3, "baseCd": 3},
		"healing_tide": {"baseDmg": 0, "hits": 0, "effects": [], "heal": 40, "baseCd": 4},
		"tsunami": {"baseDmg": 28, "hits": 1, "effects": [], "foam": 5, "baseCd": 5},
		"frost_bolt": {"baseDmg": 12, "hits": 1, "effects": [], "frost": 2, "baseCd": 2},
		"glacial_spike": {"baseDmg": 25, "hits": 1, "effects": [], "frost": 1, "baseCd": 3},
		"snowstorm": {"baseDmg": 8, "hits": 1, "effects": [], "frost": 2, "baseCd": 2},
		"flash_freeze": {"baseDmg": 0, "hits": 0, "effects": [], "frost": 5, "baseCd": 3},
		"ice_age": {"baseDmg": 10, "hits": 1, "effects": [{"type": "stun", "turns": 1}], "frost": 5, "baseCd": 5},
		"zap": {"baseDmg": 25, "hits": 1, "effects": [], "shock": 2, "baseCd": 1},
		"chain_lightning": {"baseDmg": 11, "hits": 4, "effects": [], "shock": 1, "baseCd": 3},
		"thunder_strike": {"baseDmg": 35, "hits": 1, "effects": [], "shock": 2, "baseCd": 3},
		"megavolt": {"baseDmg": 50, "hits": 1, "effects": [], "baseCd": 4},
		"thunderclap": {"baseDmg": 35, "hits": 1, "effects": [{"type": "stun", "turns": 1}], "shock": 3, "baseCd": 5},
		"seismic_wave": {"baseDmg": 20, "hits": 1, "effects": [], "crackArmor": 8, "baseCd": 2},
		"echo_slam": {"baseDmg": 15, "hits": 1, "effects": [], "baseCd": 3},
		"earthshaker": {"baseDmg": 40, "hits": 1, "effects": [], "baseCd": 3},
		"cataclysm": {"baseDmg": 60, "hits": 1, "effects": [{"type": "stun", "turns": 1}], "baseCd": 6},
		"vine_strike": {"baseDmg": 5, "hits": 3, "effects": [], "root": 1, "baseCd": 2},
		"bramble_burst": {"baseDmg": 12, "hits": 1, "effects": [], "root": 3, "baseCd": 3},
		"wild_growth": {"baseDmg": 0, "hits": 0, "effects": [], "heal": 25, "armor": 20, "baseCd": 4},
		"natures_wrath": {"baseDmg": 45, "hits": 1, "effects": [], "root": 3, "baseCd": 5},
		"quintuple_hit": {"baseDmg": 3, "hits": 5, "effects": [], "baseCd": 1},
		"tornado": {"baseDmg": 10, "hits": 1, "effects": [], "baseCd": 3},
		"windy_takedown": {"baseDmg": 25, "hits": 1, "effects": [{"type": "stun", "turns": 1}], "baseCd": 3},
		"slipcut": {"baseDmg": 20, "hits": 1, "effects": [], "baseCd": 2},
		"storm_rush": {"baseDmg": 15, "hits": 4, "effects": [], "baseCd": 5},
	}
	# ── ABILITY CATALOGUE ─────────────────────────────────────────────────────────
	# Each fn receives (enemyIdx) and should call log/performHit/applyDirectDamage etc.
	# Uses combat.enemies[enemyIdx] for the enemy, status.player for player status.
	ENEMY_ABILITY_CATALOGUE = {
		"brace": {
			"id": "brace",
			"name": "Brace",
			"emoji": "🛡️",
			"tier": 0,
			"baseCd": 2,
			"fn": ENEMY_ABILITY_CATALOGUE__brace__fn,
		},
		"fire_ignite": {
			"id": "fire_ignite",
			"name": "Ignite",
			"emoji": "🔥",
			"tier": 0,
			"baseCd": 2,
			"fn": ENEMY_ABILITY_CATALOGUE__fire_ignite__fn,
		},
		"fire_flame_burst": {
			"id": "fire_flame_burst",
			"name": "Flame Burst",
			"emoji": "💥",
			"tier": 0,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__fire_flame_burst__fn,
		},
		"fire_combustion_strike": {
			"id": "fire_combustion_strike",
			"name": "Combustion Strike",
			"emoji": "🔥",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__fire_combustion_strike__fn,
		},
		"fire_wildfire": {
			"id": "fire_wildfire",
			"name": "Wildfire",
			"emoji": "🌋",
			"tier": 1,
			"baseCd": 4,
			"fn": ENEMY_ABILITY_CATALOGUE__fire_wildfire__fn,
		},
		"fire_magma_armor": {
			"id": "fire_magma_armor",
			"name": "Magma Armor",
			"emoji": "🛡️",
			"tier": 1,
			"baseCd": 4,
			"fn": ENEMY_ABILITY_CATALOGUE__fire_magma_armor__fn,
		},
		"fire_inferno": {
			"id": "fire_inferno",
			"name": "Inferno",
			"emoji": "☄️",
			"tier": 2,
			"baseCd": 5,
			"fn": ENEMY_ABILITY_CATALOGUE__fire_inferno__fn,
		},
		"water_foam_burst": {
			"id": "water_foam_burst",
			"name": "Foam Burst",
			"emoji": "🫧",
			"tier": 0,
			"baseCd": 2,
			"fn": ENEMY_ABILITY_CATALOGUE__water_foam_burst__fn,
		},
		"water_tidal_shield": {
			"id": "water_tidal_shield",
			"name": "Tidal Shield",
			"emoji": "💧",
			"tier": 0,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__water_tidal_shield__fn,
		},
		"water_riptide": {
			"id": "water_riptide",
			"name": "Riptide",
			"emoji": "🌊",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__water_riptide__fn,
		},
		"water_healing_surge": {
			"id": "water_healing_surge",
			"name": "Healing Surge",
			"emoji": "💚",
			"tier": 1,
			"baseCd": 4,
			"fn": ENEMY_ABILITY_CATALOGUE__water_healing_surge__fn,
		},
		"water_drown": {
			"id": "water_drown",
			"name": "Drown",
			"emoji": "🌀",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__water_drown__fn,
		},
		"water_tsunami": {
			"id": "water_tsunami",
			"name": "Tsunami",
			"emoji": "🌊",
			"tier": 2,
			"baseCd": 6,
			"fn": ENEMY_ABILITY_CATALOGUE__water_tsunami__fn,
		},
		"ice_frost_bolt": {
			"id": "ice_frost_bolt",
			"name": "Frost Bolt",
			"emoji": "❄️",
			"tier": 0,
			"baseCd": 2,
			"fn": ENEMY_ABILITY_CATALOGUE__ice_frost_bolt__fn,
		},
		"ice_glacial_armor": {
			"id": "ice_glacial_armor",
			"name": "Glacial Armor",
			"emoji": "🧊",
			"tier": 0,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__ice_glacial_armor__fn,
		},
		"ice_flash_freeze": {
			"id": "ice_flash_freeze",
			"name": "Flash Freeze",
			"emoji": "🌨️",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__ice_flash_freeze__fn,
		},
		"ice_shatter_strike": {
			"id": "ice_shatter_strike",
			"name": "Shatter Strike",
			"emoji": "💎",
			"tier": 1,
			"baseCd": 4,
			"fn": ENEMY_ABILITY_CATALOGUE__ice_shatter_strike__fn,
		},
		"ice_cryostasis": {
			"id": "ice_cryostasis",
			"name": "Cryostasis",
			"emoji": "🧊",
			"tier": 2,
			"baseCd": 5,
			"fn": ENEMY_ABILITY_CATALOGUE__ice_cryostasis__fn,
		},
		"lightning_zap": {
			"id": "lightning_zap",
			"name": "Zap",
			"emoji": "⚡",
			"tier": 0,
			"baseCd": 2,
			"fn": ENEMY_ABILITY_CATALOGUE__lightning_zap__fn,
		},
		"lightning_chain": {
			"id": "lightning_chain",
			"name": "Chain Lightning",
			"emoji": "⚡",
			"tier": 0,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__lightning_chain__fn,
		},
		"lightning_overcharge": {
			"id": "lightning_overcharge",
			"name": "Overcharge",
			"emoji": "💥",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__lightning_overcharge__fn,
		},
		"lightning_blitz": {
			"id": "lightning_blitz",
			"name": "Blitz",
			"emoji": "💫",
			"tier": 1,
			"baseCd": 4,
			"fn": ENEMY_ABILITY_CATALOGUE__lightning_blitz__fn,
		},
		"lightning_static_field": {
			"id": "lightning_static_field",
			"name": "Static Field",
			"emoji": "🌩️",
			"tier": 1,
			"baseCd": 4,
			"fn": ENEMY_ABILITY_CATALOGUE__lightning_static_field__fn,
		},
		"lightning_charge_shot": {
			"id": "lightning_charge_shot",
			"name": "Charge Shot",
			"emoji": "⚡",
			"tier": 2,
			"baseCd": 5,
			"fn": ENEMY_ABILITY_CATALOGUE__lightning_charge_shot__fn,
		},
		"earth_fortify": {
			"id": "earth_fortify",
			"name": "Fortify",
			"emoji": "🛡️",
			"tier": 0,
			"baseCd": 2,
			"fn": ENEMY_ABILITY_CATALOGUE__earth_fortify__fn,
		},
		"earth_boulder": {
			"id": "earth_boulder",
			"name": "Boulder Toss",
			"emoji": "🗿",
			"tier": 0,
			"baseCd": 2,
			"fn": ENEMY_ABILITY_CATALOGUE__earth_boulder__fn,
		},
		"earth_seismic": {
			"id": "earth_seismic",
			"name": "Seismic Wave",
			"emoji": "🌍",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__earth_seismic__fn,
		},
		"earth_stone_stance": {
			"id": "earth_stone_stance",
			"name": "Stone Stance",
			"emoji": "🧱",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__earth_stone_stance__fn,
		},
		"earth_petrify": {
			"id": "earth_petrify",
			"name": "Petrify",
			"emoji": "🗿",
			"tier": 1,
			"baseCd": 4,
			"fn": ENEMY_ABILITY_CATALOGUE__earth_petrify__fn,
		},
		"earth_cataclysm": {
			"id": "earth_cataclysm",
			"name": "Cataclysm",
			"emoji": "💥",
			"tier": 2,
			"baseCd": 6,
			"fn": ENEMY_ABILITY_CATALOGUE__earth_cataclysm__fn,
		},
		"nature_entangle": {
			"id": "nature_entangle",
			"name": "Entangle",
			"emoji": "🌿",
			"tier": 0,
			"baseCd": 2,
			"fn": ENEMY_ABILITY_CATALOGUE__nature_entangle__fn,
		},
		"nature_thornwall": {
			"id": "nature_thornwall",
			"name": "Thornwall",
			"emoji": "🌵",
			"tier": 0,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__nature_thornwall__fn,
		},
		"nature_wild_growth": {
			"id": "nature_wild_growth",
			"name": "Wild Growth",
			"emoji": "🌱",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__nature_wild_growth__fn,
		},
		"nature_vine_lash": {
			"id": "nature_vine_lash",
			"name": "Vine Lash",
			"emoji": "🌿",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__nature_vine_lash__fn,
		},
		"nature_spore_cloud": {
			"id": "nature_spore_cloud",
			"name": "Spore Cloud",
			"emoji": "🍄",
			"tier": 1,
			"baseCd": 4,
			"fn": ENEMY_ABILITY_CATALOGUE__nature_spore_cloud__fn,
		},
		"nature_wrath": {
			"id": "nature_wrath",
			"name": "Nature's Wrath",
			"emoji": "🌳",
			"tier": 2,
			"baseCd": 5,
			"fn": ENEMY_ABILITY_CATALOGUE__nature_wrath__fn,
		},
		"plasma_phase_strike": {
			"id": "plasma_phase_strike",
			"name": "Phase Strike",
			"emoji": "🔮",
			"tier": 0,
			"baseCd": 2,
			"fn": ENEMY_ABILITY_CATALOGUE__plasma_phase_strike__fn,
		},
		"plasma_phase_shift": {
			"id": "plasma_phase_shift",
			"name": "Phase Shift",
			"emoji": "✨",
			"tier": 0,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__plasma_phase_shift__fn,
		},
		"plasma_void_pulse": {
			"id": "plasma_void_pulse",
			"name": "Void Pulse",
			"emoji": "🌀",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__plasma_void_pulse__fn,
		},
		"plasma_evasion_boost": {
			"id": "plasma_evasion_boost",
			"name": "Evasion Boost",
			"emoji": "💜",
			"tier": 1,
			"baseCd": 4,
			"fn": ENEMY_ABILITY_CATALOGUE__plasma_evasion_boost__fn,
		},
		"plasma_singularity": {
			"id": "plasma_singularity",
			"name": "Singularity",
			"emoji": "⚫",
			"tier": 2,
			"baseCd": 6,
			"fn": ENEMY_ABILITY_CATALOGUE__plasma_singularity__fn,
		},
		"air_twin_gust": {
			"id": "air_twin_gust",
			"name": "Twin Gust",
			"emoji": "🌀",
			"tier": 0,
			"baseCd": 2,
			"fn": ENEMY_ABILITY_CATALOGUE__air_twin_gust__fn,
		},
		"air_gale_force": {
			"id": "air_gale_force",
			"name": "Gale Force",
			"emoji": "💨",
			"tier": 0,
			"baseCd": 2,
			"fn": ENEMY_ABILITY_CATALOGUE__air_gale_force__fn,
		},
		"air_cyclone": {
			"id": "air_cyclone",
			"name": "Cyclone",
			"emoji": "🌪️",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__air_cyclone__fn,
		},
		"air_wind_shield": {
			"id": "air_wind_shield",
			"name": "Wind Shield",
			"emoji": "🌬️",
			"tier": 1,
			"baseCd": 3,
			"fn": ENEMY_ABILITY_CATALOGUE__air_wind_shield__fn,
		},
		"air_sky_slam": {
			"id": "air_sky_slam",
			"name": "Sky Slam",
			"emoji": "🌩️",
			"tier": 1,
			"baseCd": 4,
			"fn": ENEMY_ABILITY_CATALOGUE__air_sky_slam__fn,
		},
		"air_tempest": {
			"id": "air_tempest",
			"name": "Tempest",
			"emoji": "⛈️",
			"tier": 2,
			"baseCd": 5,
			"fn": ENEMY_ABILITY_CATALOGUE__air_tempest__fn,
		},
	}
	# ── ELEMENT → SPELL POOL MAPPING (uses ENEMY_SPELL_PARAMS ids) ───────────────
	ENEMY_ABILITY_POOL = {
		"Fire": {
			"0": ["fire_ignite", "fire_flame_burst"],
			"1": ["fire_combustion_strike", "fire_wildfire", "fire_magma_armor"],
			"2": ["fire_inferno"],
		},
		"Water": {
			"0": ["water_foam_burst", "water_tidal_shield"],
			"1": ["water_riptide", "water_healing_surge", "water_drown"],
			"2": ["water_tsunami"],
		},
		"Ice": {
			"0": ["ice_frost_bolt", "ice_glacial_armor"],
			"1": ["ice_flash_freeze", "ice_shatter_strike"],
			"2": ["ice_cryostasis"],
		},
		"Lightning": {
			"0": ["lightning_zap", "lightning_chain"],
			"1": ["lightning_overcharge", "lightning_blitz", "lightning_static_field"],
			"2": ["lightning_charge_shot"],
		},
		"Earth": {
			"0": ["earth_fortify", "earth_boulder"],
			"1": ["earth_seismic", "earth_stone_stance", "earth_petrify"],
			"2": ["earth_cataclysm"],
		},
		"Nature": {
			"0": ["nature_entangle", "nature_thornwall"],
			"1": ["nature_wild_growth", "nature_vine_lash", "nature_spore_cloud"],
			"2": ["nature_wrath"],
		},
		"Plasma": {
			"0": ["plasma_phase_strike", "plasma_phase_shift"],
			"1": ["plasma_void_pulse", "plasma_evasion_boost"],
			"2": ["plasma_singularity"],
		},
		"Air": {
			"0": ["air_twin_gust", "air_gale_force"],
			"1": ["air_cyclone", "air_wind_shield", "air_sky_slam"],
			"2": ["air_tempest"],
		},
	}
	ENEMY_SPELL_POOL_BY_ELEMENT = {
		"Fire": {"0": ["ignite", "ember_storm"], "1": ["flame_wave", "forge_blast"], "2": []},
		"Water": {"0": ["tidal_surge", "riptide"], "1": ["whirlpool", "healing_tide"], "2": ["tsunami"]},
		"Ice": {"0": ["frost_bolt", "glacial_spike", "snowstorm"], "1": ["flash_freeze"], "2": ["ice_age"]},
		"Lightning": {"0": ["zap", "chain_lightning"], "1": ["thunder_strike", "megavolt"], "2": ["thunderclap"]},
		"Earth": {"0": ["seismic_wave", "echo_slam"], "1": ["earthshaker"], "2": ["cataclysm"]},
		"Nature": {"0": ["vine_strike", "bramble_burst"], "1": ["wild_growth"], "2": ["natures_wrath"]},
		"Plasma": {"0": [], "1": [], "2": []},
		"Air": {"0": ["quintuple_hit", "tornado"], "1": ["windy_takedown", "slipcut"], "2": ["storm_rush"]},
	}
	# ── ENEMY ITEM CATALOGUE ──────────────────────────────────────────────────────
	ENEMY_ITEM_CATALOGUE = [
		{
			"id": "enemy_healing_draught",
			"name": "Healing Draught",
			"emoji": "🧪",
			"fn": ENEMY_ITEM_CATALOGUE__enemy_healing_draught__fn,
		},
		{
			"id": "enemy_iron_flask",
			"name": "Iron Flask",
			"emoji": "⚗️",
			"fn": ENEMY_ITEM_CATALOGUE__enemy_iron_flask__fn,
		},
	]
	# Hint strings shown under each intent label
	ENEMY_ABILITY_HINTS = {
		"brace": "6+ Block",
		"fire_ignite": "8 dmg · +6 🔥 Burn",
		"fire_flame_burst": "18 dmg · +4 🔥 Burn",
		"fire_combustion_strike": "14+ dmg · +3 🔥 Burn",
		"fire_wildfire": "Doubles Burn stacks",
		"fire_magma_armor": "26+ Block",
		"fire_inferno": "30 dmg · +21 🔥 Burn",
		"water_foam_burst": "10 dmg · +3 🫧 Foam",
		"water_tidal_shield": "26+ Block",
		"water_riptide": "8 dmg ×3 · +1 Foam each",
		"water_healing_surge": "Heals 25+ HP",
		"water_drown": "Stuns if ≥4 Foam · else +2 Foam",
		"water_tsunami": "10 dmg × Foam stacks",
		"ice_frost_bolt": "12 dmg · Stun 1t · +1 ❄️ Frost",
		"ice_glacial_armor": "33+ Block",
		"ice_flash_freeze": "+6 ❄️ Frost",
		"ice_shatter_strike": "Up to 40+ dmg (scales with Frost)",
		"ice_cryostasis": "+46 Block · Heals 30 · self Stun 1t",
		"lightning_zap": "12 dmg",
		"lightning_chain": "6 dmg ×4",
		"lightning_overcharge": "20 dmg · +3 ⚡ Shock",
		"lightning_blitz": "Detonates Shock stacks for big dmg",
		"lightning_static_field": "+Power for 2 turns",
		"lightning_charge_shot": "Charges — massive hit next action",
		"earth_fortify": "26+ Block",
		"earth_boulder": "22 dmg",
		"earth_seismic": "16 dmg · cracks 15 Armor",
		"earth_stone_stance": "39+ Block · +3 Stone stacks",
		"earth_petrify": "18 dmg · Stun 2t",
		"earth_cataclysm": "50+ dmg or Stone ×25",
		"nature_entangle": "10 dmg · +2 🌿 Root",
		"nature_thornwall": "33+ Block · Thorns on hit",
		"nature_wild_growth": "Heals 20+ HP · +20 Block",
		"nature_vine_lash": "8 dmg ×3 · +1 Root each",
		"nature_spore_cloud": "8 dmg · Stun 1t · +3 🌿 Root",
		"nature_wrath": "Root stacks × 20 dmg",
		"plasma_phase_strike": "14 dmg",
		"plasma_phase_shift": "Dodges next hit",
		"plasma_void_pulse": "20 dmg · gains Phase",
		"plasma_evasion_boost": "+15% dodge · gains Phase",
		"plasma_singularity": "35 dmg · Stun 1t · +20% dodge",
		"air_twin_gust": "10 dmg ×2",
		"air_gale_force": "22 dmg",
		"air_cyclone": "10 dmg ×3",
		"air_wind_shield": "+20% dodge · +20 Block",
		"air_sky_slam": "20 dmg · Stun 1t",
		"air_tempest": "10 dmg ×5",
	}

# Build a live ability object from player SPELL_CATALOGUE + ENEMY_SPELL_VALUES.
# _scaleMult starts at 0.6; incantation boosts it on the priority ability.
func _buildEnemyAbilityFromSpell(id = null):
	var ab = [null]
	var spell = JS.or_(JS.idx(Spells.SPELL_CATALOGUE, id), {})
	var vals = JS.or_(JS.idx(ENEMY_SPELL_VALUES, id), {})
	var _tierMap = {"primary": 0, "secondary": 1, "legendary": 2}
	var params = {
		"name": JS.or_(spell.get("name"), id),
		"emoji": JS.or_(spell.get("emoji"), "⚔"),
		"element": JS.or_(spell.get("element"), "Fire"),
		"tier": JS.nn(JS.idx(_tierMap, spell.get("tier")), 0),
		"baseCd": JS.or_(vals.get("baseCd"), 2),
		"baseDmg": JS.or_(vals.get("baseDmg"), 0),
		"hits": vals.get("hits"),
		"effects": vals.get("effects"),
		"foam": vals.get("foam"),
		"frost": vals.get("frost"),
		"root": vals.get("root"),
		"shock": vals.get("shock"),
		"heal": vals.get("heal"),
		"armor": vals.get("armor"),
		"crackArmor": vals.get("crackArmor"),
	}
	var _fn1 = func():
		var scaled = JS.round((JS.or_(params.get("baseDmg"), 0)) * ab[0].get("_scaleMult"))
		var parts = []
		if scaled > 0:
			parts.append("~" + JS.s(scaled) + " dmg" + (" ×" + JS.s(params.get("hits")) if (JS.or_(params.get("hits"), 1)) > 1 else ""))
		if JS.t(params.get("foam")):
			parts.append("+" + JS.s(params.get("foam")) + " 🫧 Foam")
		if JS.t(params.get("frost")):
			parts.append("+" + JS.s(params.get("frost")) + " ❄️ Frost")
		if JS.t(params.get("root")):
			parts.append("+" + JS.s(params.get("root")) + " 🌿 Root")
		if JS.t(params.get("shock")):
			parts.append("+" + JS.s(params.get("shock")) + " ⚡ Shock")
		if JS.t(params.get("crackArmor")):
			parts.append("cracks " + JS.s(params.get("crackArmor")) + " Armor")
		if JS.t(params.get("heal")):
			parts.append("Heals " + JS.s(params.get("heal")))
		if JS.t(params.get("armor")):
			parts.append("+" + JS.s(params.get("armor")) + " Block")
		for ef in JS.iter(JS.or_(params.get("effects"), [])):
			if ef.get("type") == "burn":
				parts.append("+" + JS.s(ef.get("stacks")) + " 🔥 Burn")
			if ef.get("type") == "stun":
				parts.append("Stun " + JS.s(ef.get("turns")) + "t")
		return JS.join(parts, " · ")
	var _fn2 = func(enemyIdx = null):
		var e = JS.idx(State.combat.get("enemies"), enemyIdx)
		State.setActiveEnemy(enemyIdx)
		UI.log_(JS.s(params.get("emoji")) + " " + JS.s(e.get("name")) + " casts " + JS.s(params.get("name")) + "!", "enemy")
		var baseDmg = JS.round((JS.or_(params.get("baseDmg"), 0)) * ab[0].get("_scaleMult"))
		if (not JS.t(State.combat.get("over")) and (baseDmg > 0 or (JS.t(params.get("effects")) and len(params.get("effects")) > 0))):
			Hit.performHit("enemy", "player", {
				"baseDamage": baseDmg,
				"hits": JS.or_(params.get("hits"), 1),
				"effects": (JS.arr(params.get("effects")) if JS.t(params.get("effects")) else []),
				"abilityElement": params.get("element"),
				"isEnemyAttack": true,
			})
		if (not JS.t(State.combat.get("over")) and JS.t(params.get("foam"))):
			Helpers.applyFoam("enemy", "player", params.get("foam"))
		if (not JS.t(State.combat.get("over")) and JS.t(params.get("frost"))):
			Helpers.applyFrost("enemy", "player", params.get("frost"))
		if (not JS.t(State.combat.get("over")) and JS.t(params.get("root"))):
			Helpers.applyRoot("enemy", "player", params.get("root"))
		if (not JS.t(State.combat.get("over")) and JS.t(params.get("shock"))):
			State.status.get("player").shockStacks = (JS.or_(State.status.get("player").get("shockStacks"), 0)) + JS.un(params.get("shock"))
			UI.log_("⚡ Shock +" + JS.s(params.get("shock")) + " (×" + JS.s(State.status.get("player").get("shockStacks")) + ")", "status")
		if (not JS.t(State.combat.get("over")) and JS.t(params.get("crackArmor"))):
			var crack = min(JS.or_(State.status.get("player").get("block"), 0), params.get("crackArmor"))
			if crack > 0:
				State.status.get("player").block -= crack
				UI.log_("🪨 Armor cracked by " + JS.s(crack) + "!", "status")
		if (not JS.t(State.combat.get("over")) and JS.t(params.get("heal"))):
			var h = JS.round(params.get("heal"))
			e.hp = min(e.get("enemyMaxHP"), e.get("hp") + h)
			UI.log_("💚 " + JS.s(e.get("name")) + " heals " + JS.s(h) + " HP!", "enemy")
			UI.updateHPBars()
		if (not JS.t(State.combat.get("over")) and JS.t(params.get("armor"))):
			e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + JS.round(params.get("armor"))
			UI.log_("🛡️ " + JS.s(e.get("name")) + " gains " + JS.s(JS.round(params.get("armor"))) + " Block!", "enemy")
		if ((((JS.t(params.get("foam")) or JS.t(params.get("frost"))) or JS.t(params.get("root"))) or JS.t(params.get("crackArmor"))) or JS.t(params.get("armor"))):
			UI.renderStatusTags()
	ab[0] = {
		"id": id,
		"name": params.get("name"),
		"emoji": params.get("emoji"),
		"tier": params.get("tier"),
		"baseCd": params.get("baseCd"),
		"cd": 0,
		"_scaleMult": 0.6,
		"hintFn": _fn1,
		"fn": _fn2,
	}
	return ab[0]

# How many abilities an enemy gets, by zone depth (0-indexed gym)
func abilityCountForZone(gymIdx = null, difficulty = null, bonusActions = null):
	return min(max(2, (1 + (JS.or_(bonusActions, 0))) + floori(gymIdx / 2.0)), 8)

# Max tier unlocked per zone depth
func maxAbilityTierForZone(gymIdx = null):
	if gymIdx <= 1:
		return 0
	# zones 1-2: primary only
	if gymIdx <= 3:
		return 1
	# zones 3-4: up to secondary
	return 2

# Build ability list for an enemy based on element + zone depth
# incantLvl: number of failed bonus-action rolls — boosts the priority ability's _scaleMult
func buildEnemyAbilities(element = null, gymIdx = null, difficulty = null, bonusActions = null, incantLvl = null):
	var pool = JS.idx(ENEMY_SPELL_POOL_BY_ELEMENT, element)
	if not JS.t(pool):
		return []
	var maxTier = maxAbilityTierForZone(gymIdx)
	var count = abilityCountForZone(gymIdx, JS.or_(difficulty, "easy"), JS.or_(bonusActions, 0))
	# Collect eligible spell ids by tier
	var candidates = []
	for t in range(0, floori(maxTier) + 1):
		for id in JS.iter(JS.or_(JS.idx(pool, t), [])):
			candidates.append({"id": id, "tier": t})
	# Pick `count` spells, biased toward higher tiers in later zones
	var chosen = []
	var shuffled = JS.sort(JS.arr(candidates), func(): return randf() - 0.5)
	# Always include at least one tier-0 to anchor
	var tier0 = JS.arr(shuffled).filter(func(c = null): return JS.eq(c.get("tier"), 0))
	if JS.t(len(tier0)):
		chosen.append(JS.idx(tier0, floori(randf() * len(tier0))))
	# Fill remainder preferring higher tiers
	var remaining = JS.arr(shuffled).filter(func(c = null): return not JS.t(JS.find(chosen, func(x = null): return JS.eq(x.id, c.id))))
	JS.sort(remaining, func(a = null, b = null): return JS.un(b.get("tier")) - JS.un(a.get("tier")))
	while (len(chosen) < count and JS.t(len(remaining))):
		chosen.append(remaining.pop_front())
	# Build live ability objects from SPELL_CATALOGUE + ENEMY_SPELL_VALUES
	var built = JS.arr(chosen).map(func(c = null): return _buildEnemyAbilityFromSpell(c.id))
	# Apply incantation boost to the highest-tier ability
	if ((JS.or_(incantLvl, 0)) > 0 and len(built) > 0):
		var priority = JS.reduce(built, func(best = null, ab = null): return (ab if JS.un(ab.get("tier")) > JS.un(best.get("tier")) else best), JS.idx(built, 0))
		priority._scaleMult = min(1.0, 0.6 + ((JS.or_(incantLvl, 0)) * 0.12))
	# Every enemy always gets Brace — universal armor ability
	built.push_front(JS.merge([JS.idx(ENEMY_ABILITY_CATALOGUE, "brace"), {"cd": 0}]))
	return built

# Called each round start to tick enemy ability cooldowns
func tickEnemyAbilityCDs():
	for e in JS.iter(State.combat.get("enemies")):
		if (not JS.t(e.get("alive")) or not JS.t(e.get("abilities"))):
			continue
		for a in JS.iter(e.get("abilities")):
			if a.get("cd") > 0:
				a.cd -= 1
		# Tick static field duration
		if JS.un(e.get("_staticFieldTurns")) > 0:
			e._staticFieldTurns -= 1
			if (JS.un(e.get("_staticFieldTurns")) <= 0 and JS.t(e.get("_staticPowerBonus"))):
				e.statPow = max(0, (JS.or_(e.get("statPow"), 0)) - JS.un(e.get("_staticPowerBonus")))
				e._staticPowerBonus = 0
				UI.log_("🌩️ " + JS.s(e.get("name")) + "'s Static Field fades.", "status")

# Pick an ability for this enemy to use (returns ability obj or null)
func pickEnemyAbility(e = null, gymIdx = null):
	if (not JS.t(e.get("abilities")) or len(e.get("abilities")) == 0):
		return null
	var ready = JS.arr(e.get("abilities")).filter(func(a = null): return a.get("cd") <= 0)
	if not JS.t(len(ready)):
		return null
	var hpPct = e.get("hp") / float(e.get("enemyMaxHP"))
	var hasNoBlock = (JS.or_(e.get("status").get("block"), 0)) == 0
	# Brace: use proactively when undefended
	var brace = JS.find(ready, func(a = null): return a.get("id") == "brace")
	if JS.t(brace):
		var braceChance = (0.65 if (hpPct < 0.5 and hasNoBlock) else (0.35 if hasNoBlock else 0.15))
		if randf() < braceChance:
			return brace
	# Below 40% HP: strongly prefer any defensive / healing ability
	if hpPct < 0.4:
		var defensive = JS.find(ready, func(a = null): return (a.get("id") == "brace" or (JS.t(JS.idx(ENEMY_SPELL_VALUES, a.id)) and ((JS.or_(JS.idx(ENEMY_SPELL_VALUES, a.id).get("heal"), 0)) > 0 or (JS.or_(JS.idx(ENEMY_SPELL_VALUES, a.id).get("armor"), 0)) > 0))))
		if (JS.t(defensive) and randf() < 0.65):
			return defensive
	# Use high-tier abilities when available
	if (JS.t(JS.find(ready, func(a = null): return JS.un(a.get("tier")) >= 1)) and randf() < 0.55):
		var powerful = JS.arr(ready).filter(func(a = null): return JS.un(a.get("tier")) >= 1)
		return JS.idx(powerful, floori(randf() * len(powerful)))
	# Random ability with 50% overall chance
	if randf() < 0.5:
		return JS.idx(ready, floori(randf() * len(ready)))
	return null

# Pick an item for the enemy to use (returns item or null)
func pickEnemyItem(e = null):
	if (not JS.t(e.get("items")) or len(e.get("items")) == 0):
		return null
	var hpPct = e.get("hp") / float(e.get("enemyMaxHP"))
	var heal = JS.find(e.get("items"), func(it = null): return it.get("id") == "enemy_healing_draught")
	if ((JS.t(heal) and hpPct < 0.4) and randf() < 0.75):
		return heal
	var flask = JS.find(e.get("items"), func(it = null): return it.get("id") == "enemy_iron_flask")
	if ((JS.t(flask) and (JS.or_(e.get("status").get("block"), 0)) == 0) and randf() < 0.59):
		return flask
	return null

# Scale enemy base stats by zone depth (applied in makeEnemyObj)
func scaleEnemyForZone(enc = null, gymIdx = null):
	# HP and damage scale per zone — roughly +25% HP and +20% dmg per zone
	var hpMult = 1 + (gymIdx * 0.336)
	var dmgMult = 1 + (gymIdx * 0.22)
	return {"enemyMaxHP": JS.round(enc.get("enemyMaxHP") * hpMult), "enemyDmg": JS.round(enc.get("enemyDmg") * dmgMult)}

func ENEMY_ABILITY_CATALOGUE__brace__fn(i = null):
	# ═══ UNIVERSAL ═══
	var e = JS.idx(State.combat.get("enemies"), i)
	var armor = JS.round((5 + floori((JS.or_(e.get("statDef"), 0)) / 5.0)) * 1.625)
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + armor
	UI.log_("🛡️ " + JS.s(e.get("name")) + " braces! (+" + JS.s(armor) + " Block)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__fire_ignite__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🔥 " + JS.s(e.get("name")) + " ignites you! (+6 Burn)", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 8, "effects": [{"type": "burn", "stacks": 6}], "abilityElement": "Fire", "isEnemyAttack": true})

func ENEMY_ABILITY_CATALOGUE__fire_flame_burst__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("💥 " + JS.s(e.get("name")) + " erupts in flames!", "enemy")
	Hit.performHit("enemy", "player", {
		"baseDamage": 18,
		"effects": [{"type": "burn", "stacks": 4}],
		"abilityElement": "Fire",
		"isEnemyAttack": true,
	})

func ENEMY_ABILITY_CATALOGUE__fire_combustion_strike__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	var extra = (floori(State.status.get("player").get("burnStacks") * 1.5) if (JS.or_(State.status.get("player").get("burnStacks"), 0)) > 0 else 0)
	UI.log_("🔥 " + JS.s(e.get("name")) + " Combustion Strike! " + ("(+" + JS.s(extra) + " burn dmg)" if extra > 0 else ""), "enemy")
	Hit.performHit("enemy", "player", {
		"baseDamage": 14 + extra,
		"effects": [{"type": "burn", "stacks": 3}],
		"abilityElement": "Fire",
		"isEnemyAttack": true,
	})

func ENEMY_ABILITY_CATALOGUE__fire_wildfire__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	var stacks = JS.or_(State.status.get("player").get("burnStacks"), 0)
	if stacks > 0:
		State.status.get("player").burnStacks = min(stacks * 2, 60)
		UI.log_("🌋 " + JS.s(e.get("name")) + " Wildfire! Burn doubled (×" + JS.s(State.status.get("player").get("burnStacks")) + ")", "enemy")
	else:
		State.status.get("player").burnStacks = 8
		UI.log_("🌋 " + JS.s(e.get("name")) + " Wildfire! Sets you ablaze (×8 Burn)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__fire_magma_armor__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	var armor = JS.round((20 + floori((JS.or_(e.get("statDef"), 0)) / 5.0)) * 1.625)
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + armor
	UI.log_("🛡️ " + JS.s(e.get("name")) + " hardens with Magma Armor! (+" + JS.s(armor) + " Block)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__fire_inferno__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("☄️ " + JS.s(e.get("name")) + " unleashes INFERNO!", "enemy")
	Hit.performHit("enemy", "player", {
		"baseDamage": 30,
		"effects": [{"type": "burn", "stacks": 12}],
		"abilityElement": "Fire",
		"isEnemyAttack": true,
	})
	State.status.get("player").burnStacks = min((JS.or_(State.status.get("player").get("burnStacks"), 0)) + 9, 80)
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__water_foam_burst__fn(i = null):
	# ═══ WATER ═══
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🫧 " + JS.s(e.get("name")) + " Foam Burst! (+3 Foam on you)", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 10, "effects": [], "abilityElement": "Water", "isEnemyAttack": true})
	Helpers.applyFoam("enemy", "player", 3)
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__water_tidal_shield__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	var armor = JS.round((20 + floori((JS.or_(e.get("statDef"), 0)) / 4.0)) * 1.625)
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + armor
	UI.log_("💧 " + JS.s(e.get("name")) + " raises a Tidal Shield! (+" + JS.s(armor) + " Block)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__water_riptide__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🌊 " + JS.s(e.get("name")) + " Riptide! Multiple hits + Foam", "enemy")
	for h in range(3):
		if JS.t(State.combat.get("over")):
			return
		Hit.performHit("enemy", "player", {"baseDamage": 8, "effects": [], "abilityElement": "Water", "isEnemyAttack": true, "hits": 1})
		Helpers.applyFoam("enemy", "player", 1)
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__water_healing_surge__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	var heal = 25 + floori((JS.or_(e.get("statEfx"), 0)) / 3.0)
	var prev = e.get("hp")
	e.hp = min(e.get("enemyMaxHP"), e.get("hp") + heal)
	UI.log_("💚 " + JS.s(e.get("name")) + " Healing Surge! (+" + JS.s(e.get("hp") - prev) + " HP → " + JS.s(e.get("hp")) + "/" + JS.s(e.get("enemyMaxHP")) + ")", "enemy")
	UI.updateHPBars()

func ENEMY_ABILITY_CATALOGUE__water_drown__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	var foam = JS.or_(State.status.get("player").get("foamStacks"), 0)
	if foam >= 4:
		State.status.get("player").foamStacks = 0
		State.status.get("player").stunned = (JS.or_(State.status.get("player").get("stunned"), 0)) + 1
		UI.log_("🌀 " + JS.s(e.get("name")) + " DROWNS you! (" + JS.s(foam) + " Foam consumed — Stunned 1t)", "enemy")
	else:
		Helpers.applyFoam("enemy", "player", 2)
		Hit.performHit("enemy", "player", {"baseDamage": 12, "effects": [], "abilityElement": "Water", "isEnemyAttack": true})
		UI.log_("🌀 " + JS.s(e.get("name")) + " Drown — not enough Foam yet (+2 Foam)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__water_tsunami__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	var foam = JS.or_(State.status.get("player").get("foamStacks"), 0)
	UI.log_("🌊 " + JS.s(e.get("name")) + " calls a TSUNAMI! (" + JS.s(foam) + " Foam stacks)", "enemy")
	var hits = max(1, foam)
	for h in range(ceili(hits)):
		if JS.t(State.combat.get("over")):
			return
		Hit.performHit("enemy", "player", {"baseDamage": 10, "effects": [], "abilityElement": "Water", "isEnemyAttack": true})
	State.status.get("player").foamStacks = 0
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__ice_frost_bolt__fn(i = null):
	# ═══ ICE ═══
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("❄️ " + JS.s(e.get("name")) + " Frost Bolt!", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 12, "effects": [{"type": "stun", "turns": 1}], "abilityElement": "Ice", "isEnemyAttack": true})
	if not JS.t(State.combat.get("over")):
		Helpers.applyFrost("enemy", "player", 1)

func ENEMY_ABILITY_CATALOGUE__ice_glacial_armor__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	var armor = JS.round((25 + floori((JS.or_(e.get("statDef"), 0)) / 4.0)) * 1.625)
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + armor
	UI.log_("🧊 " + JS.s(e.get("name")) + " encases itself in Glacial Armor! (+" + JS.s(armor) + " Block)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__ice_flash_freeze__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🌨️ " + JS.s(e.get("name")) + " Flash Freeze!", "enemy")
	Helpers.applyFrost("enemy", "player", 6)
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__ice_shatter_strike__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	var frost = JS.or_(State.status.get("player").get("frostStacks"), 0)
	var dmg = (40 + ((JS.or_(e.get("statPow"), 0)) * 2) if frost >= 10 else frost * 4)
	UI.log_("💎 " + JS.s(e.get("name")) + " Shatter! " + ("FROZEN — massive hit" if frost >= 10 else "(" + JS.s(frost) + " Frost × 4)"), "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": max(8, dmg), "effects": [], "abilityElement": "Ice", "isEnemyAttack": true})
	if (not JS.t(State.combat.get("over")) and frost < 10):
		Helpers.applyFrost("enemy", "player", 1)
	if frost >= 10:
		State.status.get("player").frostStacks = 0
		State.status.get("player").frozen = 0
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__ice_cryostasis__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	var armor = JS.round(35 * 1.625)
	var heal = 30
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + armor
	e.hp = min(e.get("enemyMaxHP"), e.get("hp") + heal)
	e.get("status").stunned = max(JS.or_(e.get("status").get("stunned"), 0), 1)
	# stuns SELF for 1t (charges up)
	UI.log_("🧊 " + JS.s(e.get("name")) + " enters Cryostasis! (+" + JS.s(armor) + " Armor, +" + JS.s(heal) + " HP, charges 1t)", "enemy")
	UI.updateHPBars()
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__lightning_zap__fn(i = null):
	# ═══ LIGHTNING ═══
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("⚡ " + JS.s(e.get("name")) + " Zap!", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 12, "effects": [], "abilityElement": "Lightning", "isEnemyAttack": true})

func ENEMY_ABILITY_CATALOGUE__lightning_chain__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("⚡ " + JS.s(e.get("name")) + " Chain Lightning! (×4 hits)", "enemy")
	for h in range(4):
		if JS.t(State.combat.get("over")):
			return
		Hit.performHit("enemy", "player", {"baseDamage": 6, "effects": [], "abilityElement": "Lightning", "isEnemyAttack": true})

func ENEMY_ABILITY_CATALOGUE__lightning_overcharge__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	var shock = JS.or_(State.status.get("player").get("shockStacks"), 0)
	State.status.get("player").shockStacks = (JS.or_(State.status.get("player").get("shockStacks"), 0)) + 3
	UI.log_("💥 " + JS.s(e.get("name")) + " Overcharge! +3 Shock (×" + JS.s(State.status.get("player").get("shockStacks")) + ")", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 20, "effects": [], "abilityElement": "Lightning", "isEnemyAttack": true})

func ENEMY_ABILITY_CATALOGUE__lightning_blitz__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	var shock = JS.or_(State.status.get("player").get("shockStacks"), 0)
	if shock > 0:
		var dmg = shock * max(1, floori((JS.or_(e.get("statPow"), 0)) / 2.0))
		UI.log_("💫 " + JS.s(e.get("name")) + " BLITZ! Detonates " + JS.s(shock) + " Shock stacks (" + JS.s(dmg) + " dmg)", "enemy")
		Hit.applyDirectDamage("enemy", "player", dmg, "💫 Blitz")
		State.status.get("player").shockStacks = 0
	else:
		Hit.performHit("enemy", "player", {"baseDamage": 18, "effects": [], "abilityElement": "Lightning", "isEnemyAttack": true})
		UI.log_("💫 " + JS.s(e.get("name")) + " Blitz — no stacks, raw hit", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__lightning_static_field__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	# Self-buff: enemy deals 15% more dmg for 2 turns via temp power
	e._staticFieldTurns = 2
	var bonus = floori((JS.or_(e.get("statPow"), 0)) * 0.3)
	e._staticPowerBonus = bonus
	e.statPow = (JS.or_(e.get("statPow"), 0)) + bonus
	UI.log_("🌩️ " + JS.s(e.get("name")) + " Static Field! (+" + JS.s(bonus) + " Power for 2t)", "enemy")

func ENEMY_ABILITY_CATALOGUE__lightning_charge_shot__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("⚡ " + JS.s(e.get("name")) + " winds up a CHARGE SHOT — next turn massive lightning!", "enemy")
	e._chargeShot = true
	# resolved next action
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + 13
	# defensive while charging
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__earth_fortify__fn(i = null):
	# ═══ EARTH ═══
	var e = JS.idx(State.combat.get("enemies"), i)
	var armor = JS.round((20 + floori((JS.or_(e.get("statDef"), 0)) / 4.0)) * 1.625)
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + armor
	UI.log_("🛡️ " + JS.s(e.get("name")) + " Fortifies! (+" + JS.s(armor) + " Block)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__earth_boulder__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🗿 " + JS.s(e.get("name")) + " Boulder Toss!", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 22, "effects": [], "abilityElement": "Earth", "isEnemyAttack": true})

func ENEMY_ABILITY_CATALOGUE__earth_seismic__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🌍 " + JS.s(e.get("name")) + " Seismic Wave! Cracks your armor", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 16, "effects": [], "abilityElement": "Earth", "isEnemyAttack": true})
	var crack = min(JS.or_(State.status.get("player").get("block"), 0), 15)
	if crack > 0:
		State.status.get("player").block -= crack
		UI.log_("🪨 Armor cracked by " + JS.s(crack) + "!", "status")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__earth_stone_stance__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	var armor = JS.round((30 + floori((JS.or_(e.get("statDef"), 0)) / 3.0)) * 1.625)
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + armor
	# Gain stone stacks
	e.get("status").stoneStacks = (JS.or_(e.get("status").get("stoneStacks"), 0)) + 3
	UI.log_("🧱 " + JS.s(e.get("name")) + " Stone Stance! (+" + JS.s(armor) + " Block, +3 Stone stacks)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__earth_petrify__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🗿 " + JS.s(e.get("name")) + " Petrify!", "enemy")
	Hit.performHit("enemy", "player", {
		"baseDamage": 18,
		"effects": [{"type": "stun", "turns": 2}],
		"abilityElement": "Earth",
		"isEnemyAttack": true,
	})

func ENEMY_ABILITY_CATALOGUE__earth_cataclysm__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	var stone = JS.or_(e.get("status").get("stoneStacks"), 0)
	var dmg = (stone * 25 if stone > 0 else 50 + ((JS.or_(e.get("statPow"), 0)) * 2))
	UI.log_("💥 " + JS.s(e.get("name")) + " CATACLYSM! " + ("(" + JS.s(stone) + " Stone×25)" if stone > 0 else "Raw devastation"), "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": dmg, "effects": [], "abilityElement": "Earth", "isEnemyAttack": true})
	e.get("status").stoneStacks = 0
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__nature_entangle__fn(i = null):
	# ═══ NATURE ═══
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🌿 " + JS.s(e.get("name")) + " Entangle!", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 10, "effects": [], "abilityElement": "Nature", "isEnemyAttack": true})
	State.status.get("player").rootStacks = (JS.or_(State.status.get("player").get("rootStacks"), 0)) + 2
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__nature_thornwall__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	var armor = JS.round((25 + floori((JS.or_(e.get("statDef"), 0)) / 4.0)) * 1.625)
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + armor
	e.get("status").thornArmor = true
	# flag: thorns on hit
	UI.log_("🌵 " + JS.s(e.get("name")) + " Thornwall! (+" + JS.s(armor) + " Block + Thorns)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__nature_wild_growth__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	var heal = 20 + floori((JS.or_(e.get("statEfx"), 0)) / 3.0)
	e.hp = min(e.get("enemyMaxHP"), e.get("hp") + heal)
	var armor = JS.round(15 * 2.1125)
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + armor
	UI.log_("🌱 " + JS.s(e.get("name")) + " Wild Growth! (+" + JS.s(heal) + " HP, +" + JS.s(armor) + " Block)", "enemy")
	UI.updateHPBars()
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__nature_vine_lash__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🌿 " + JS.s(e.get("name")) + " Vine Lash! (×3 hits + Root)", "enemy")
	for h in range(3):
		if JS.t(State.combat.get("over")):
			return
		Hit.performHit("enemy", "player", {"baseDamage": 8, "effects": [], "abilityElement": "Nature", "isEnemyAttack": true})
		if not JS.t(State.combat.get("over")):
			State.status.get("player").rootStacks = (JS.or_(State.status.get("player").get("rootStacks"), 0)) + 1
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__nature_spore_cloud__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🍄 " + JS.s(e.get("name")) + " Spore Cloud! Weakens and roots you", "enemy")
	State.status.get("player").rootStacks = (JS.or_(State.status.get("player").get("rootStacks"), 0)) + 3
	# Temp power debuff on player tracked via foamStacks as proxy (visual only)
	Hit.performHit("enemy", "player", {
		"baseDamage": 8,
		"effects": [{"type": "stun", "turns": 1}],
		"abilityElement": "Nature",
		"isEnemyAttack": true,
	})
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__nature_wrath__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	var root = JS.or_(State.status.get("player").get("rootStacks"), 0)
	var dmg = max(20, root * 20)
	UI.log_("🌳 " + JS.s(e.get("name")) + " NATURE'S WRATH! (" + JS.s(root) + " Root × 20 = " + JS.s(dmg) + " dmg)", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": dmg, "effects": [], "abilityElement": "Nature", "isEnemyAttack": true})
	State.status.get("player").rootStacks = 0
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__plasma_phase_strike__fn(i = null):
	# ═══ PLASMA ═══
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🔮 " + JS.s(e.get("name")) + " Phase Strike!", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 14, "effects": [], "abilityElement": "Plasma", "isEnemyAttack": true})

func ENEMY_ABILITY_CATALOGUE__plasma_phase_shift__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	e.get("status").phaseTurns = 1
	UI.log_("✨ " + JS.s(e.get("name")) + " phases out! (dodges next hit)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__plasma_void_pulse__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🌀 " + JS.s(e.get("name")) + " Void Pulse!", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 20, "effects": [], "abilityElement": "Plasma", "isEnemyAttack": true})
	# Phase self after attacking
	e.get("status").phaseTurns = 1
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__plasma_evasion_boost__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	e.get("status").battleDodgeBonus = (JS.or_(e.get("status").get("battleDodgeBonus"), 0)) + 0.15
	e.get("status").phaseTurns = 1
	UI.log_("💜 " + JS.s(e.get("name")) + " Evasion Boost! (+15% dodge + Phase)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__plasma_singularity__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("⚫ " + JS.s(e.get("name")) + " opens a SINGULARITY!", "enemy")
	Hit.performHit("enemy", "player", {
		"baseDamage": 35,
		"effects": [{"type": "stun", "turns": 1}],
		"abilityElement": "Plasma",
		"isEnemyAttack": true,
	})
	e.get("status").phaseTurns = 1
	e.get("status").battleDodgeBonus = (JS.or_(e.get("status").get("battleDodgeBonus"), 0)) + 0.2
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__air_twin_gust__fn(i = null):
	# ═══ AIR ═══
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🌀 " + JS.s(e.get("name")) + " Twin Gust! (×2)", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 10, "effects": [], "abilityElement": "Air", "isEnemyAttack": true, "hits": 2})

func ENEMY_ABILITY_CATALOGUE__air_gale_force__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("💨 " + JS.s(e.get("name")) + " Gale Force!", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 22, "effects": [], "abilityElement": "Air", "isEnemyAttack": true})

func ENEMY_ABILITY_CATALOGUE__air_cyclone__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🌪️ " + JS.s(e.get("name")) + " Cyclone! (×3 hits)", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 10, "effects": [], "abilityElement": "Air", "isEnemyAttack": true, "hits": 3})

func ENEMY_ABILITY_CATALOGUE__air_wind_shield__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	e.get("status").battleDodgeBonus = (JS.or_(e.get("status").get("battleDodgeBonus"), 0)) + 0.2
	var armor = JS.round(15 * 2.1125)
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + armor
	UI.log_("🌬️ " + JS.s(e.get("name")) + " Wind Shield! (+20% dodge, +" + JS.s(armor) + " Block)", "enemy")
	UI.renderStatusTags()

func ENEMY_ABILITY_CATALOGUE__air_sky_slam__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("🌩️ " + JS.s(e.get("name")) + " Sky Slam!", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 20, "effects": [{"type": "stun", "turns": 1}], "abilityElement": "Air", "isEnemyAttack": true})

func ENEMY_ABILITY_CATALOGUE__air_tempest__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	State.setActiveEnemy(i)
	UI.log_("⛈️ " + JS.s(e.get("name")) + " TEMPEST! (×5 rapid hits)", "enemy")
	Hit.performHit("enemy", "player", {"baseDamage": 10, "effects": [], "abilityElement": "Air", "isEnemyAttack": true, "hits": 5})
	e.get("status").battleDodgeBonus = (JS.or_(e.get("status").get("battleDodgeBonus"), 0)) + 0.1
	UI.renderStatusTags()

func ENEMY_ITEM_CATALOGUE__enemy_healing_draught__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	var heal = JS.round(e.get("enemyMaxHP") * 0.2)
	e.hp = min(e.get("enemyMaxHP"), e.get("hp") + heal)
	UI.log_("🧪 " + JS.s(e.get("name")) + " drinks a Healing Draught! (+" + JS.s(heal) + " HP)", "enemy")
	UI.updateHPBars()

func ENEMY_ITEM_CATALOGUE__enemy_iron_flask__fn(i = null):
	var e = JS.idx(State.combat.get("enemies"), i)
	var armor = JS.round(15 * 2.1125)
	e.get("status").block = (JS.or_(e.get("status").get("block"), 0)) + armor
	UI.log_("⚗️ " + JS.s(e.get("name")) + " uses an Iron Flask! (+" + JS.s(armor) + " Block)", "enemy")
	UI.renderStatusTags()
