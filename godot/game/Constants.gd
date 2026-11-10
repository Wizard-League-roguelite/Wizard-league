# Constants — generated from js/data/constants.js by tools/js2gd.js
extends Node

# ===== constants.js =====
# ─── GAME CONSTANTS ───────────────────────────────────────────────────────
# Tweak these to balance the game without touching logic files.
# ===============================
# CORE CONSTANTS
# ===============================
var BASE_MAX_HP = 200
var BASE_DMG = 25
# basic spell base damage (pre-mods)
var BASE_POWER = 0
var BATTLE_HEAL = 0
# removed — now a KT card (kt_recovery)
var CAMPFIRE_HEAL = 0.5
var CAMPFIRE_CHANCE = 0.25
var SHOP_CHANCE = 0.15
var ITEM_DROP_CHANCE = 0.3
var GYM_ZONE_OPEN = 14
# gym appears after this many zone battles
var GYM_ZONE_FORCE = 14
# gym is forced at this count (same → always forced, no skip window)
var GYM_SKIP_BONUS = 20
# +20 HP per skip
var XP_PER_LEVEL = 100
# ACTION SYSTEM
var BASE_ACTIONS_PER_TURN = 2
# ROOT (global passive)
var ROOT_PROC_CHANCE = 0.5
# 50% chance per hit
var ROOT_POWER_PER_STACK = 5
# +5 power per root stack vs rooted foes
# ── Save slot — declared here (before artifacts.js) so no TDZ ──
var activeSaveSlot = 0
var sandboxMode = false
var RELEASED_ELEMENTS = null

func _boot():
	# ── Released elements — only these are available in non-sandbox mode ──
	# Add new elements here when they are fully fleshed out.
	RELEASED_ELEMENTS = ["Fire", "Lightning", "Nature", "Air"]
