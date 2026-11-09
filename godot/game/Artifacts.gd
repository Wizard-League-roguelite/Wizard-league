# Artifacts — generated from js/data/artifacts.js by tools/js2gd.js
extends Node

var ARTIFACT_CATALOGUE = null
var ARTIFACT_ORDER = null
# ── Meta Persistence (slot-aware) ─────────────────────────────────────────────
# activeSaveSlot is declared in main.js (loads after this file).
# All calls to getMeta/saveMeta happen at runtime (not module init), so by the
# time any function runs, activeSaveSlot is already defined.
var META_KEY_BASE = "elemental_meta_v1_slot"

func _boot():
	# ===== artifacts.js =====
	# ─── ARTIFACT SYSTEM ─────────────────────────────────────────────────────────
	# Permanent meta-progression items earned by beating gym leaders.
	# Each artifact has 3 upgrade tiers (★ ★★ ★★★), earned after 25 rooms of use.
	# Only ONE artifact is active per run — equip it in the Vault between runs.
	# ── Catalogue ─────────────────────────────────────────────────────────────────
	# desc[0] = base, desc[1] = ★, desc[2] = ★★, desc[3] = ★★★
	# applyToRun(star) — called once at run start, modifies player state
	# applyToCombat — optional fn called each startRound, returns nothing
	ARTIFACT_CATALOGUE = {
		"iron_will": {
			"id": "iron_will",
			"name": "Iron Will",
			"emoji": "⚔️",
			"flavor": "Tempered through endless battle.",
			"desc": ["+5 ATK at run start.", "+8 ATK at run start.", "+12 ATK at run start.", "+15 ATK at run start."],
			"applyToRun": ARTIFACT_CATALOGUE__iron_will__applyToRun,
		},
		"focus_lens": {
			"id": "focus_lens",
			"name": "Focus Lens",
			"emoji": "🔮",
			"flavor": "Sharpens every enchantment you cast.",
			"desc": [
				"+5 Effect Power at run start.",
				"+8 EFX at run start.",
				"+12 EFX at run start.",
				"+15 EFX at run start.",
			],
			"applyToRun": ARTIFACT_CATALOGUE__focus_lens__applyToRun,
		},
		"hardy_soul": {
			"id": "hardy_soul",
			"name": "Hardy Soul",
			"emoji": "❤️",
			"flavor": "The will to survive outlasts any wound.",
			"desc": ["+20 Max HP per run.", "+35 Max HP per run.", "+55 Max HP per run.", "+80 Max HP per run."],
			"applyToRun": ARTIFACT_CATALOGUE__hardy_soul__applyToRun,
		},
		"battle_rhythm": {
			"id": "battle_rhythm",
			"name": "Battle Rhythm",
			"emoji": "🥁",
			"flavor": "Every third heartbeat — strike.",
			"desc": [
				"+1 action every 3 turns.",
				"+1 action every 2 turns.",
				"+1 action every 2 turns + +2 flat ATK.",
				"+1 extra action every turn.",
			],
			"applyToRun": ARTIFACT_CATALOGUE__battle_rhythm__applyToRun,
		},
		"gold_hoard": {
			"id": "gold_hoard",
			"name": "Gold Hoard",
			"emoji": "💰",
			"flavor": "A mercenary always starts well-stocked.",
			"desc": [
				"Start each run with 50 gold.",
				"Start with 80 gold.",
				"Start with 120 gold.",
				"Start with 200 gold.",
			],
			"applyToRun": ARTIFACT_CATALOGUE__gold_hoard__applyToRun,
		},
		"quick_hands": {
			"id": "quick_hands",
			"name": "Quick Hands",
			"emoji": "🤲",
			"flavor": "The first blow decides everything.",
			"desc": [
				"+1 action in the first battle only.",
				"+1 action for first 3 battles.",
				"+1 action for first 5 battles.",
				"Permanently +1 action every turn.",
			],
			"applyToRun": ARTIFACT_CATALOGUE__quick_hands__applyToRun,
		},
		"survivors_grit": {
			"id": "survivors_grit",
			"name": "Survivor's Grit",
			"emoji": "🛡️",
			"flavor": "Death is just another obstacle.",
			"desc": [
				"+1 extra life per run.",
				"+2 extra lives per run.",
				"+2 lives + heal 50 HP on each revive.",
				"+3 extra lives per run.",
			],
			"applyToRun": ARTIFACT_CATALOGUE__survivors_grit__applyToRun,
		},
		"ember_heart": {
			"id": "ember_heart",
			"name": "Ember Heart",
			"emoji": "🩷",
			"flavor": "Even fire can nourish.",
			"desc": ["All healing +10% this run.", "+20% healing.", "+30% healing.", "+50% healing."],
			"applyToRun": ARTIFACT_CATALOGUE__ember_heart__applyToRun,
		},
		"storm_core": {
			"id": "storm_core",
			"name": "Storm Core",
			"emoji": "🌩️",
			"flavor": "Even a basic strike carries the storm's fury.",
			"desc": ["+3 flat damage on Basic Spell.", "+5 flat damage.", "+8 flat damage.", "+12 flat damage."],
			"applyToRun": ARTIFACT_CATALOGUE__storm_core__applyToRun,
		},
		"iron_skin": {
			"id": "iron_skin",
			"name": "Iron Skin",
			"emoji": "🪨",
			"flavor": "Forged hide takes the edge off everything.",
			"desc": ["+3 Defense at run start.", "+5 Defense.", "+8 Defense.", "+12 Defense."],
			"applyToRun": ARTIFACT_CATALOGUE__iron_skin__applyToRun,
		},
		"warlords_banner": {
			"id": "warlords_banner",
			"name": "Warlord's Banner",
			"emoji": "🚩",
			"flavor": "Victory fuels the next charge.",
			"desc": [
				"Gain 5 gold on every battle win.",
				"Gain 10 gold on every win.",
				"Gain 10 gold + 1 ATK on every win.",
				"Gain 15 gold + 2 ATK on every win.",
			],
			"applyToRun": ARTIFACT_CATALOGUE__warlords_banner__applyToRun,
		},
	}
	# Ordered by gym — gym 1 unlock gives artifact index 0, gym 2 → index 1, etc.
	ARTIFACT_ORDER = [
		"iron_will",
		"focus_lens",
		"hardy_soul",
		"battle_rhythm",
		"gold_hoard",
		"quick_hands",
		"survivors_grit",
		"ember_heart",
		"storm_core",
		"iron_skin",
		"warlords_banner",
	]

func _metaKey():
	return META_KEY_BASE + (JS.or_(Constants.activeSaveSlot, 0))

func _metaCache():
	if not JS.t(window.get("_metaBySlot")):
		window._metaBySlot = {}
	return {"slot": JS.or_(Constants.activeSaveSlot, 0), "cache": window.get("_metaBySlot")}

func getMeta():
	var _d1 = _metaCache()
	var slot = JS.idx(_d1, "slot")
	var cache = JS.idx(_d1, "cache")
	if not JS.t(JS.idx(cache, slot)):
		var raw = localStorage.getItem(_metaKey())
		cache[slot] = (JS.jsonParse(raw) if JS.t(raw) else {
			"artifacts": [],
			"totalRuns": 0,
			"bestLevel": 0,
			"gymsBeaten": 0,
			"runHistory": [],
			"activeArtifactId": null,
			"unseenArtifacts": [],
		})
	return JS.idx(cache, slot)

func saveMeta():
	localStorage.setItem(_metaKey(), JS.jsonStringify(getMeta()))

# Called at run start — apply only the active artifact's bonuses
func applyArtifactBonuses():
	var meta = getMeta()
	var activeId = meta.activeArtifactId
	if not JS.t(activeId):
		return
	var a = JS.find(JS.or_(meta.get("artifacts"), []), func(x = null): return JS.eq(x.id, activeId))
	if not JS.t(a):
		return
	var def = JS.idx(ARTIFACT_CATALOGUE, a.id)
	if JS.t(def):
		JS.callm(def, "applyToRun", [JS.or_(a.get("star"), 0)])

# Called when a gym is beaten — 65% chance to discover a new random artifact.
# Returns the new artifact object if one was discovered, or null.
func onGymDefeated(gymIdx = null):
	var meta = getMeta()
	var prevGymsBeaten = JS.or_(meta.get("gymsBeaten"), 0)
	meta.gymsBeaten = max(prevGymsBeaten, gymIdx + 1)
	# First time beating this gym — bonus 10 phos
	if (gymIdx + 1) > prevGymsBeaten:
		meta.phos = (JS.or_(meta.get("phos"), 0)) + 10
		meta.phosTotal = (JS.or_(meta.get("phosTotal"), 0)) + 10
		UI.log_("✦ First gym clear! +10 Phos", "win")
	if not JS.t(meta.get("artifacts")):
		meta.artifacts = []
	if not JS.t(meta.get("unseenArtifacts")):
		meta.unseenArtifacts = []
	# Find all artifact IDs not yet discovered
	var discovered = JSSet.new(JS.arr(meta.artifacts).map(func(a = null): return a.id))
	var undiscovered = JS.arr(ARTIFACT_ORDER).filter(func(id = null): return not discovered.has(id))
	if (not JS.t(len(undiscovered)) or randf() > 0.65):
		saveMeta()
		return null
	# no discovery this time
	# Pick a random undiscovered artifact
	var chosenId = JS.idx(undiscovered, floori(randf() * len(undiscovered)))
	var target = {"id": chosenId, "star": 0, "roomsUsed": 0}
	meta.artifacts.append(target)
	meta.unseenArtifacts.append(chosenId)
	saveMeta()
	window._lastArtifactUnlock = target
	return target

# Equip an artifact as the single active one
func equipArtifact(id = null):
	var meta = getMeta()
	meta.activeArtifactId = id
	saveMeta()

# Unequip the active artifact
func unequipArtifact():
	var meta = getMeta()
	meta.activeArtifactId = null
	saveMeta()

# Returns true if there are newly discovered artifacts the player hasn't seen
func hasUnseenArtifact():
	var meta = getMeta()
	return len(JS.or_(meta.get("unseenArtifacts"), [])) > 0

# Called when the player opens the vault — clears unseen notification
func markArtifactsSeen():
	var meta = getMeta()
	meta.unseenArtifacts = []
	saveMeta()

# Called when the player opens the library — clears unseen book notification
func markBooksSeen():
	var meta = getMeta()
	meta.unseenBookIds = []
	saveMeta()

# Called after each non-gym room is cleared — progress the ACTIVE artifact only
func incrementArtifactRooms():
	var meta = getMeta()
	var activeId = meta.activeArtifactId
	if not JS.t(activeId):
		return null
	var a = JS.find(JS.or_(meta.get("artifacts"), []), func(x = null): return JS.eq(x.id, activeId))
	if (not JS.t(a) or a.star >= 3):
		return null
	a.roomsUsed = (JS.or_(a.get("roomsUsed"), 0)) + 1
	if a.roomsUsed >= 25:
		a.star += 1
		a.roomsUsed = 0
		saveMeta()
		return a
	saveMeta()
	return null

# Called after each battle win — awards 10 phos per room cleared past the previous record.
# Updates meta.bestLevel immediately so each new room in a run earns separately.
func checkBattleRecord():
	if JS.t(Constants.sandboxMode):
		return
	var meta = getMeta()
	var prev = JS.or_(meta.get("bestLevel"), 0)
	if State.battleNumber > prev:
		meta.bestLevel = State.battleNumber
		meta.phos = (JS.or_(meta.get("phos"), 0)) + 3
		meta.phosTotal = (JS.or_(meta.get("phosTotal"), 0)) + 3
		saveMeta()
		UI.log_("✦ Room " + JS.s(State.battleNumber) + " record! +3 Phos", "win")

# Called on run end — save stats
func saveRunStats():
	var meta = getMeta()
	var phosEarned = Talents.calcPhosEarned()
	meta.phos = (JS.or_(meta.get("phos"), 0)) + phosEarned
	meta.phosTotal = (JS.or_(meta.get("phosTotal"), 0)) + phosEarned
	meta.totalRuns = (JS.or_(meta.get("totalRuns"), 0)) + 1
	meta.bestLevel = max(JS.or_(meta.get("bestLevel"), 0), State.battleNumber)
	if not JS.t(meta.get("runHistory")):
		meta.runHistory = []
	meta.runHistory.push_front({
		"element": JS.or_(State.playerElement, "?"),
		"emoji": JS.or_(State.playerEmoji, "⚔"),
		"battles": State.battleNumber,
		"gold": State.player.gold,
		"spells": len(State.player.spellbook),
		"phos": phosEarned,
		"date": JS.toLocaleDateString(JS.newDate()),
		"dmgDealt": State._runDmgDealt,
		"dmgTaken": State._runDmgTaken,
		"rooms": State._runRoomsCompleted,
		"zone": JS.or_(JS.or_(State._runZoneReached, State.playerElement), "?"),
	})
	if len(meta.runHistory) > 15:
		meta.runHistory.pop_back()
	saveMeta()
	return phosEarned

# Star display helpers
func starStr(star = null):
	if JS.eq(star, 0):
		return ""
	return " " + "★".repeat(star)

func starColor(star = null):
	return JS.idx(["#888", "#c8a030", "#e8d060", "#00ccff"], min(star, 3))

# ── Combat hooks (called from startRound / endBattle) ─────────────────────────
# Returns extra actions from the active artifact for player this turn
func artifactExtraActions():
	var meta = getMeta()
	var activeId = meta.activeArtifactId
	if not JS.t(activeId):
		return 0
	var a = JS.find(JS.or_(meta.get("artifacts"), []), func(x = null): return JS.eq(x.id, activeId))
	if not JS.t(a):
		return 0
	var star = JS.or_(a.get("star"), 0)
	var extra = 0
	if activeId == "battle_rhythm":
		var interval = (1 if star >= 3 else (2 if star >= 1 else 3))
		var t = JS.or_(State.combat.get("turnInBattle"), 0)
		if (t > 0 and (JS.mod(t, interval)) == 0):
			extra += 1
	if activeId == "quick_hands":
		if star >= 3:
			extra += 1
		else:
			var battleLimit = JS.idx([1, 3, 5], min(star, 2))
			if State.battleNumber <= battleLimit:
				extra += 1
	return extra

# Called from endBattle(won=true) — warlord's banner (only if active)
func applyBannerReward():
	var meta = getMeta()
	if meta.get("activeArtifactId") != "warlords_banner":
		return
	var a = JS.find(JS.or_(meta.get("artifacts"), []), func(x = null): return x.get("id") == "warlords_banner")
	if not JS.t(a):
		return
	var star = JS.or_(a.get("star"), 0)
	var gold = JS.idx([5, 10, 10, 15], star)
	State.player.gold += gold
	UI.log_("🚩 Warlord's Banner: +" + JS.s(gold) + " gold!", "item")
	if star >= 2:
		var atkBonus = (2 if star >= 3 else 1)
		State.player.attackPower += atkBonus
		UI.log_("🚩 Banner: +" + JS.s(atkBonus) + " ATK!", "item")
		UI.updateStatsUI()

func ARTIFACT_CATALOGUE__iron_will__applyToRun(star = null):
	State.player.attackPower += JS.idx([5, 8, 12, 15], star)

func ARTIFACT_CATALOGUE__focus_lens__applyToRun(star = null):
	State.player.effectPower += JS.idx([5, 8, 12, 15], star)

func ARTIFACT_CATALOGUE__hardy_soul__applyToRun(star = null):
	State.player.baseMaxHPBonus = (JS.or_(State.player.get("baseMaxHPBonus"), 0)) + JS.idx([20, 35, 55, 80], star)

func ARTIFACT_CATALOGUE__battle_rhythm__applyToRun(star = null):
	State.player._rhythmStar = star

func ARTIFACT_CATALOGUE__gold_hoard__applyToRun(star = null):
	# handled in startRound
	State.player.gold += JS.idx([50, 80, 120, 200], star)

func ARTIFACT_CATALOGUE__quick_hands__applyToRun(star = null):
	State.player._quickHandsStar = star

func ARTIFACT_CATALOGUE__survivors_grit__applyToRun(star = null):
	# handled in startRound
	State.player.revives = (JS.or_(State.player.get("revives"), 3)) + JS.idx([1, 2, 2, 3], star)
	if star >= 2:
		State.player._gritHealOnRevive = 50

func ARTIFACT_CATALOGUE__ember_heart__applyToRun(star = null):
	State.player._healBonus = (JS.or_(State.player.get("_healBonus"), 0)) + JS.idx([0.1, 0.2, 0.3, 0.5], star)

func ARTIFACT_CATALOGUE__storm_core__applyToRun(star = null):
	State.player.basicDmgFlat = (JS.or_(State.player.get("basicDmgFlat"), 0)) + JS.idx([3, 5, 8, 12], star)

func ARTIFACT_CATALOGUE__iron_skin__applyToRun(star = null):
	State.player.defense = (JS.or_(State.player.get("defense"), 0)) + JS.idx([3, 5, 8, 12], star)

func ARTIFACT_CATALOGUE__warlords_banner__applyToRun(star = null):
	State.player._bannerStar = star
