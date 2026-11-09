# Talents — generated from js/data/talents.js by tools/js2gd.js
extends Node

var TALENT_TREE = null
# ── Phos earned this run — stored temporarily, credited in saveRunStats ────────
var _runPhosEarned = 0

func _boot():
	# ── Talent node definitions ───────────────────────────────────────────────────
	# maxLevel: how many times purchasable
	# cost(level): phos cost to go from (level-1) → level  (level is 1-based next purchase)
	# apply(level): called at run start for each level purchased
	TALENT_TREE = {
		"universal": {
			"label": "Universal",
			"nodes": [
				{
					"id": "lives",
					"name": "Extra Life",
					"emoji": "❤️",
					"desc": "Start each run with +1 life.",
					"maxLevel": 4,
					"cost": func(lvl = null): return JS.idx([3, 6, 12, 20], lvl - 1),
					"apply": TALENT_TREE__universal__nodes__lives__apply,
				},
				{
					"id": "base_hp",
					"name": "Vitality",
					"emoji": "💪",
					"desc": "+15 max HP per level.",
					"maxLevel": 6,
					"cost": func(lvl = null): return lvl * 2,
					"apply": TALENT_TREE__universal__nodes__base_hp__apply,
				},
				{
					"id": "base_atk",
					"name": "Attack Training",
					"emoji": "⚔️",
					"desc": "+2 Attack Power per level.",
					"maxLevel": 6,
					"cost": func(lvl = null): return lvl * 2,
					"apply": TALENT_TREE__universal__nodes__base_atk__apply,
				},
				{
					"id": "base_efx",
					"name": "Effect Training",
					"emoji": "✨",
					"desc": "+3 Effect Power per level.",
					"maxLevel": 6,
					"cost": func(lvl = null): return lvl * 2,
					"apply": TALENT_TREE__universal__nodes__base_efx__apply,
				},
				{
					"id": "base_def",
					"name": "Defense Training",
					"emoji": "🛡️",
					"desc": "+3 Defense per level.",
					"maxLevel": 6,
					"cost": func(lvl = null): return lvl * 2,
					"apply": TALENT_TREE__universal__nodes__base_def__apply,
				},
				{
					"id": "revive_hp",
					"name": "Iron Will",
					"emoji": "🩹",
					"desc": "Revive with more HP: +25% per level (stacks).",
					"maxLevel": 3,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__universal__nodes__revive_hp__apply,
				},
				{
					"id": "gold_find",
					"name": "Treasure Sense",
					"emoji": "💰",
					"desc": "+10% gold from all sources per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 3,
					"apply": TALENT_TREE__universal__nodes__gold_find__apply,
				},
				{
					"id": "start_gold",
					"name": "Inheritance",
					"emoji": "🏦",
					"desc": "Start each run with +25g per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 3,
					"apply": TALENT_TREE__universal__nodes__start_gold__apply,
				},
				{
					"id": "rarity_kindled",
					"name": "Kindled Affinity",
					"emoji": "🔸",
					"desc": "Spell rewards have a base 8% Kindled chance. Each level adds +8% (up to 48% at Lv 5).",
					"maxLevel": 5,
					"cost": func(lvl = null): return JS.idx([4, 8, 14, 20, 28], lvl - 1),
					"apply": TALENT_TREE__universal__nodes__rarity_kindled__apply,
				},
				{
					"id": "rarity_blazing",
					"name": "Blazing Affinity",
					"emoji": "🔶",
					"desc": "Spell rewards have a base 4% Blazing chance. Each level adds +4% (up to 24% at Lv 5).",
					"maxLevel": 5,
					"cost": func(lvl = null): return JS.idx([8, 14, 22, 32, 45], lvl - 1),
					"apply": TALENT_TREE__universal__nodes__rarity_blazing__apply,
				},
				{
					"id": "rarity_radiant",
					"name": "Radiant Affinity",
					"emoji": "🌟",
					"desc": "Spell rewards have a base 2% Radiant chance. Each level adds +2% (up to 12% at Lv 5).",
					"maxLevel": 5,
					"cost": func(lvl = null): return JS.idx([15, 25, 40, 60, 85], lvl - 1),
					"apply": TALENT_TREE__universal__nodes__rarity_radiant__apply,
				},
			],
		},
		"Fire": {
			"label": "🔥 Fire",
			"nodes": [
				{
					"id": "fire_burn_dmg",
					"name": "Hotter Burns",
					"emoji": "🔥",
					"desc": "+0.1 bonus burn damage per stack per level (max +0.5).",
					"maxLevel": 5,
					"cost": func(lvl = null): return lvl * 3,
					"apply": TALENT_TREE__Fire__nodes__fire_burn_dmg__apply,
				},
				{
					"id": "fire_burn_stacks",
					"name": "Kindling",
					"emoji": "🪵",
					"desc": "Start with +2 burn stacks on enemy per level.",
					"maxLevel": 3,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Fire__nodes__fire_burn_stacks__apply,
				},
				{
					"id": "fire_spell_dmg",
					"name": "Pyroclasm",
					"emoji": "💥",
					"desc": "+5% fire spell damage per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Fire__nodes__fire_spell_dmg__apply,
				},
				{
					"id": "fire_basic",
					"name": "Ember Strike",
					"emoji": "🔥",
					"desc": "Basic Attack becomes Ember Strike (Fire only). Lv1: Dim. Lv2: Kindled. Lv3: Blazing. Lv4: Radiant. Lv5: Radiant II.",
					"maxLevel": 5,
					"cost": func(lvl = null): return JS.idx([6, 10, 18, 30, 45], lvl - 1),
					"apply": TALENT_TREE__Fire__nodes__fire_basic__apply,
				},
			],
		},
		"Water": {
			"label": "💧 Water",
			"nodes": [
				{
					"id": "water_heal",
					"name": "Deep Current",
					"emoji": "💧",
					"desc": "+10% healing per level.",
					"maxLevel": 5,
					"cost": func(lvl = null): return lvl * 3,
					"apply": TALENT_TREE__Water__nodes__water_heal__apply,
				},
				{
					"id": "water_foam",
					"name": "Froth",
					"emoji": "🫧",
					"desc": "Start each battle with 2 Foam on all enemies per level.",
					"maxLevel": 3,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Water__nodes__water_foam__apply,
				},
				{
					"id": "water_spell_dmg",
					"name": "Torrent",
					"emoji": "🌊",
					"desc": "+5% water spell damage per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Water__nodes__water_spell_dmg__apply,
				},
				{
					"id": "water_basic",
					"name": "Tidal Jab",
					"emoji": "💧",
					"desc": "Basic Attack becomes Tidal Jab (Water only). Lv1: Dim. Lv2: Kindled. Lv3: Blazing. Lv4: Radiant. Lv5: Radiant II.",
					"maxLevel": 5,
					"cost": func(lvl = null): return JS.idx([6, 10, 18, 30, 45], lvl - 1),
					"apply": TALENT_TREE__Water__nodes__water_basic__apply,
				},
			],
		},
		"Ice": {
			"label": "❄️ Ice",
			"nodes": [
				{
					"id": "ice_frost_stacks",
					"name": "Deep Freeze",
					"emoji": "❄️",
					"desc": "+0.5 frost stack applied per ability per level (max +1.5).",
					"maxLevel": 3,
					"cost": func(lvl = null): return lvl * 3,
					"apply": TALENT_TREE__Ice__nodes__ice_frost_stacks__apply,
				},
				{
					"id": "ice_execute",
					"name": "Brittle",
					"emoji": "🧊",
					"desc": "+2% execute threshold per level.",
					"maxLevel": 5,
					"cost": func(lvl = null): return lvl * 3,
					"apply": TALENT_TREE__Ice__nodes__ice_execute__apply,
				},
				{
					"id": "ice_spell_dmg",
					"name": "Glacier",
					"emoji": "🏔️",
					"desc": "+5% ice spell damage per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Ice__nodes__ice_spell_dmg__apply,
				},
				{
					"id": "ice_basic",
					"name": "Frost Jab",
					"emoji": "❄️",
					"desc": "Basic Attack becomes Frost Jab (Ice only). Lv1: Dim. Lv2: Kindled. Lv3: Blazing. Lv4: Radiant. Lv5: Radiant II.",
					"maxLevel": 5,
					"cost": func(lvl = null): return JS.idx([6, 10, 18, 30, 45], lvl - 1),
					"apply": TALENT_TREE__Ice__nodes__ice_basic__apply,
				},
			],
		},
		"Lightning": {
			"label": "⚡ Lightning",
			"nodes": [
				{
					"id": "lightning_shock",
					"name": "Conductor",
					"emoji": "⚡",
					"desc": "+0.5 shock stack per hit per level (max +1.5).",
					"maxLevel": 3,
					"cost": func(lvl = null): return lvl * 3,
					"apply": TALENT_TREE__Lightning__nodes__lightning_shock__apply,
				},
				{
					"id": "lightning_overload_floor",
					"name": "Surge",
					"emoji": "💥",
					"desc": "Overload damage floor +10% per level (min 25%).",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Lightning__nodes__lightning_overload_floor__apply,
				},
				{
					"id": "lightning_spell_dmg",
					"name": "Voltage",
					"emoji": "🔌",
					"desc": "+5% lightning spell damage per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Lightning__nodes__lightning_spell_dmg__apply,
				},
				{
					"id": "lightning_basic",
					"name": "Spark Strike",
					"emoji": "⚡",
					"desc": "Basic Attack becomes Spark Strike (Lightning only). Lv1: Dim. Lv2: Kindled. Lv3: Blazing. Lv4: Radiant. Lv5: Radiant II.",
					"maxLevel": 5,
					"cost": func(lvl = null): return JS.idx([6, 10, 18, 30, 45], lvl - 1),
					"apply": TALENT_TREE__Lightning__nodes__lightning_basic__apply,
				},
			],
		},
		"Earth": {
			"label": "🪨 Earth",
			"nodes": [
				{
					"id": "earth_armor",
					"name": "Stoneback",
					"emoji": "🪨",
					"desc": "+5 starting armor per level.",
					"maxLevel": 5,
					"cost": func(lvl = null): return lvl * 3,
					"apply": TALENT_TREE__Earth__nodes__earth_armor__apply,
				},
				{
					"id": "earth_stone",
					"name": "Bedrock",
					"emoji": "⛰️",
					"desc": "+1 starting Stone stack per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Earth__nodes__earth_stone__apply,
				},
				{
					"id": "earth_spell_dmg",
					"name": "Tectonic",
					"emoji": "🌍",
					"desc": "+5% earth spell damage per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Earth__nodes__earth_spell_dmg__apply,
				},
				{
					"id": "earth_basic",
					"name": "Stone Fist",
					"emoji": "🪨",
					"desc": "Basic Attack becomes Stone Fist (Earth only). Lv1: Dim. Lv2: Kindled. Lv3: Blazing. Lv4: Radiant. Lv5: Radiant II.",
					"maxLevel": 5,
					"cost": func(lvl = null): return JS.idx([6, 10, 18, 30, 45], lvl - 1),
					"apply": TALENT_TREE__Earth__nodes__earth_basic__apply,
				},
			],
		},
		"Nature": {
			"label": "🌿 Nature",
			"nodes": [
				{
					"id": "nature_root",
					"name": "Deep Roots",
					"emoji": "🌿",
					"desc": "+0.5 root stack on root proc per level (max +1.5).",
					"maxLevel": 3,
					"cost": func(lvl = null): return lvl * 3,
					"apply": TALENT_TREE__Nature__nodes__nature_root__apply,
				},
				{
					"id": "nature_treant",
					"name": "Ancient Grove",
					"emoji": "🌳",
					"desc": "Treants start with +15 HP per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 3,
					"apply": TALENT_TREE__Nature__nodes__nature_treant__apply,
				},
				{
					"id": "nature_spell_dmg",
					"name": "Verdant",
					"emoji": "🌱",
					"desc": "+5% nature spell damage per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Nature__nodes__nature_spell_dmg__apply,
				},
				{
					"id": "nature_basic",
					"name": "Vine Whip",
					"emoji": "🌿",
					"desc": "Basic Attack becomes Vine Whip (Nature only). Lv1: Dim. Lv2: Kindled. Lv3: Blazing. Lv4: Radiant. Lv5: Radiant II.",
					"maxLevel": 5,
					"cost": func(lvl = null): return JS.idx([6, 10, 18, 30, 45], lvl - 1),
					"apply": TALENT_TREE__Nature__nodes__nature_basic__apply,
				},
			],
		},
		"Plasma": {
			"label": "🔮 Plasma",
			"nodes": [
				{
					"id": "plasma_dodge",
					"name": "Ghost Step",
					"emoji": "👻",
					"desc": "+2% base dodge per level.",
					"maxLevel": 5,
					"cost": func(lvl = null): return lvl * 3,
					"apply": TALENT_TREE__Plasma__nodes__plasma_dodge__apply,
				},
				{
					"id": "plasma_charge",
					"name": "Capacitor",
					"emoji": "🔋",
					"desc": "+1 starting Charge per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Plasma__nodes__plasma_charge__apply,
				},
				{
					"id": "plasma_spell_dmg",
					"name": "Ionize",
					"emoji": "⚛️",
					"desc": "+5% plasma spell damage per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Plasma__nodes__plasma_spell_dmg__apply,
				},
				{
					"id": "plasma_basic",
					"name": "Surge Bolt",
					"emoji": "🔮",
					"desc": "Basic Attack becomes Surge Bolt (Plasma only). Lv1: Dim. Lv2: Kindled. Lv3: Blazing. Lv4: Radiant. Lv5: Radiant II.",
					"maxLevel": 5,
					"cost": func(lvl = null): return JS.idx([6, 10, 18, 30, 45], lvl - 1),
					"apply": TALENT_TREE__Plasma__nodes__plasma_basic__apply,
				},
			],
		},
		"Air": {
			"label": "🌀 Air",
			"nodes": [
				{
					"id": "air_actions",
					"name": "Slipstream",
					"emoji": "💨",
					"desc": "+1 action every 5/4/3 turns (scales with level).",
					"maxLevel": 3,
					"cost": func(lvl = null): return lvl * 5,
					"apply": TALENT_TREE__Air__nodes__air_actions__apply,
				},
				{
					"id": "air_multihit",
					"name": "Gust",
					"emoji": "🌪️",
					"desc": "+1 hit on multi-hit Air spells per level.",
					"maxLevel": 3,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Air__nodes__air_multihit__apply,
				},
				{
					"id": "air_spell_dmg",
					"name": "Windshear",
					"emoji": "🌬️",
					"desc": "+5% air spell damage per level.",
					"maxLevel": 4,
					"cost": func(lvl = null): return lvl * 4,
					"apply": TALENT_TREE__Air__nodes__air_spell_dmg__apply,
				},
				{
					"id": "air_basic",
					"name": "Gust Slash",
					"emoji": "💨",
					"desc": "Basic Attack becomes Gust Slash (Air only). Lv1: Dim. Lv2: Kindled. Lv3: Blazing. Lv4: Radiant. Lv5: Radiant II.",
					"maxLevel": 5,
					"cost": func(lvl = null): return JS.idx([6, 10, 18, 30, 45], lvl - 1),
					"apply": TALENT_TREE__Air__nodes__air_basic__apply,
				},
			],
		},
	}

# ===== talents.js =====
# ─── TALENT TREE ──────────────────────────────────────────────────────────────
# Phos: meta currency earned each run. Spent here for permanent upgrades.
# meta.phos       = total unspent phos
# meta.phosTotal  = lifetime phos earned (for display)
# meta.talents    = { nodeId: currentLevel }
# ── Phos earning formula ──────────────────────────────────────────────────────
# Called at run end in saveRunStats
func calcPhosEarned():
	var phos = 0
	phos += floori(State.battleNumber / 5.0)
	# 1 per 5 battles survived
	phos += (JS.or_(State.currentGymIdx, 0)) * 5
	# 5 per gym beaten this run
	return max(1, JS.round(phos))

# ── Apply all purchased talents to current run ────────────────────────────────
func applyTalentBonuses():
	var meta = Artifacts.getMeta()
	var talents = JS.or_(meta.get("talents"), {})
	# Reset all talent-driven player fields first
	State.player.revives = 0
	State.player._talentReviveBonus = 0
	State.player._goldBonus = JS.or_(State.player.get("_goldBonus"), 0)
	# artifacts may also set this
	State.player._blockStart = JS.or_(State.player.get("_blockStart"), 0)
	# Apply each purchased node (Mist may reduce effective level)
	var mistReduction = JS.or_(State.player.get("_mistTalentReduction"), 0)
	for _e1 in JS.iter(JS.entries(talents)):
		var nodeId = JS.idx(_e1, 0)
		var level = JS.idx(_e1, 1)
		var effectiveLevel = max(0, level - mistReduction)
		if not JS.t(effectiveLevel):
			continue
		var node = _findTalentNode(nodeId)
		if (JS.t(node) and JS.t(node.get("apply"))):
			JS.callm(node, "apply", [effectiveLevel])

func _findTalentNode(id = null):
	for section in JS.iter(JS.values(TALENT_TREE)):
		var found = JS.find(section.nodes, func(n = null): return JS.eq(n.id, id))
		if JS.t(found):
			return found
	return null

# ── Purchase a talent node ────────────────────────────────────────────────────
func purchaseTalent(nodeId = null):
	var meta = Artifacts.getMeta()
	if not JS.t(meta.get("talents")):
		meta.talents = {}
	var node = _findTalentNode(nodeId)
	if not JS.t(node):
		return false
	var current = JS.or_(JS.idx(meta.talents, nodeId), 0)
	if current >= node.maxLevel:
		return false
	var nextLvl = current + 1
	var cost = JS.callm(node, "cost", [nextLvl])
	if (JS.or_(meta.get("phos"), 0)) < cost:
		return false
	meta.phos -= cost
	meta.talents[nodeId] = nextLvl
	Artifacts.saveMeta()
	return true

func TALENT_TREE__universal__nodes__lives__apply(lvl = null):
	# ── UNIVERSAL ──────────────────────────────────────────────────────────────
	State.player.revives += lvl

func TALENT_TREE__universal__nodes__base_hp__apply(lvl = null):
	State.player.baseMaxHPBonus = (JS.or_(State.player.get("baseMaxHPBonus"), 0)) + (lvl * 15)

func TALENT_TREE__universal__nodes__base_atk__apply(lvl = null):
	State.player.attackPower += lvl * 2

func TALENT_TREE__universal__nodes__base_efx__apply(lvl = null):
	State.player.effectPower += lvl * 3

func TALENT_TREE__universal__nodes__base_def__apply(lvl = null):
	State.player.defense += lvl * 3

func TALENT_TREE__universal__nodes__revive_hp__apply(lvl = null):
	# stored on player for combat.js to read
	State.player._talentReviveBonus = (JS.or_(State.player.get("_talentReviveBonus"), 0)) + (lvl * 0.25)

func TALENT_TREE__universal__nodes__gold_find__apply(lvl = null):
	State.player._goldBonus = (JS.or_(State.player.get("_goldBonus"), 0)) + (lvl * 0.1)

func TALENT_TREE__universal__nodes__start_gold__apply(lvl = null):
	State.player.gold += lvl * 25

func TALENT_TREE__universal__nodes__rarity_kindled__apply(lvl = null):
	# ── Spell Rarity ───────────────────────────────────────────────────────
	# Each level adds a flat % chance for spells awarded during a run to
	# arrive at a higher rarity (= higher starting incantation level).
	# Radiant is checked first; Blazing second; Kindled last; else Dim.
	State.player._rarityChanceKindled = (JS.or_(State.player.get("_rarityChanceKindled"), 0)) + (lvl * 0.08)

func TALENT_TREE__universal__nodes__rarity_blazing__apply(lvl = null):
	State.player._rarityChanceBlazing = (JS.or_(State.player.get("_rarityChanceBlazing"), 0)) + (lvl * 0.04)

func TALENT_TREE__universal__nodes__rarity_radiant__apply(lvl = null):
	State.player._rarityChanceRadiant = (JS.or_(State.player.get("_rarityChanceRadiant"), 0)) + (lvl * 0.02)

func TALENT_TREE__Fire__nodes__fire_burn_dmg__apply(lvl = null):
	# ── ELEMENTAL TREES (stubs — you fill these in) ────────────────────────────
	State.player._talentBurnDmg = lvl * 0.1

func TALENT_TREE__Fire__nodes__fire_burn_stacks__apply(lvl = null):
	State.player._talentBurnStart = (JS.or_(State.player.get("_talentBurnStart"), 0)) + (lvl * 2)

func TALENT_TREE__Fire__nodes__fire_spell_dmg__apply(lvl = null):
	State.player._talentFireDmgMult = (JS.or_(State.player.get("_talentFireDmgMult"), 1.0)) + (lvl * 0.05)

func TALENT_TREE__Fire__nodes__fire_basic__apply(lvl = null):
	if State.playerElement == "Fire":
		State.player._elementalBasicFire = lvl

func TALENT_TREE__Water__nodes__water_heal__apply(lvl = null):
	State.player._healBonus = (JS.or_(State.player.get("_healBonus"), 0)) + (lvl * 0.1)

func TALENT_TREE__Water__nodes__water_foam__apply(lvl = null):
	State.player._talentFoamStart = (JS.or_(State.player.get("_talentFoamStart"), 0)) + (lvl * 2)

func TALENT_TREE__Water__nodes__water_spell_dmg__apply(lvl = null):
	State.player._talentWaterDmgMult = (JS.or_(State.player.get("_talentWaterDmgMult"), 1.0)) + (lvl * 0.05)

func TALENT_TREE__Water__nodes__water_basic__apply(lvl = null):
	if State.playerElement == "Water":
		State.player._elementalBasicWater = lvl

func TALENT_TREE__Ice__nodes__ice_frost_stacks__apply(lvl = null):
	State.player._talentFrostBonus = lvl * 0.5

func TALENT_TREE__Ice__nodes__ice_execute__apply(lvl = null):
	State.player._talentIceExecute = (JS.or_(State.player.get("_talentIceExecute"), 0)) + (lvl * 2)

func TALENT_TREE__Ice__nodes__ice_spell_dmg__apply(lvl = null):
	State.player._talentIceDmgMult = (JS.or_(State.player.get("_talentIceDmgMult"), 1.0)) + (lvl * 0.05)

func TALENT_TREE__Ice__nodes__ice_basic__apply(lvl = null):
	if State.playerElement == "Ice":
		State.player._elementalBasicIce = lvl

func TALENT_TREE__Lightning__nodes__lightning_shock__apply(lvl = null):
	State.player._talentShockBonus = lvl * 0.5

func TALENT_TREE__Lightning__nodes__lightning_overload_floor__apply(lvl = null):
	State.player._talentOverloadFloor = (JS.or_(State.player.get("_talentOverloadFloor"), 0.25)) + (lvl * 0.1)

func TALENT_TREE__Lightning__nodes__lightning_spell_dmg__apply(lvl = null):
	State.player._talentLightDmgMult = (JS.or_(State.player.get("_talentLightDmgMult"), 1.0)) + (lvl * 0.05)

func TALENT_TREE__Lightning__nodes__lightning_basic__apply(lvl = null):
	if State.playerElement == "Lightning":
		State.player._elementalBasicLightning = lvl

func TALENT_TREE__Earth__nodes__earth_armor__apply(lvl = null):
	State.player._blockStart = (JS.or_(State.player.get("_blockStart"), 0)) + (lvl * 5)

func TALENT_TREE__Earth__nodes__earth_stone__apply(lvl = null):
	State.player._talentStoneStart = (JS.or_(State.player.get("_talentStoneStart"), 0)) + lvl

func TALENT_TREE__Earth__nodes__earth_spell_dmg__apply(lvl = null):
	State.player._talentEarthDmgMult = (JS.or_(State.player.get("_talentEarthDmgMult"), 1.0)) + (lvl * 0.05)

func TALENT_TREE__Earth__nodes__earth_basic__apply(lvl = null):
	if State.playerElement == "Earth":
		State.player._elementalBasicEarth = lvl

func TALENT_TREE__Nature__nodes__nature_root__apply(lvl = null):
	State.player._talentRootBonus = lvl * 0.5

func TALENT_TREE__Nature__nodes__nature_treant__apply(lvl = null):
	State.player._talentTreantHP = (JS.or_(State.player.get("_talentTreantHP"), 0)) + (lvl * 15)

func TALENT_TREE__Nature__nodes__nature_spell_dmg__apply(lvl = null):
	State.player._talentNatureDmgMult = (JS.or_(State.player.get("_talentNatureDmgMult"), 1.0)) + (lvl * 0.05)

func TALENT_TREE__Nature__nodes__nature_basic__apply(lvl = null):
	if State.playerElement == "Nature":
		State.player._elementalBasicNature = lvl

func TALENT_TREE__Plasma__nodes__plasma_dodge__apply(lvl = null):
	State.player._talentDodgeBonus = (JS.or_(State.player.get("_talentDodgeBonus"), 0)) + (lvl * 0.02)

func TALENT_TREE__Plasma__nodes__plasma_charge__apply(lvl = null):
	State.player._talentChargeStart = (JS.or_(State.player.get("_talentChargeStart"), 0)) + lvl

func TALENT_TREE__Plasma__nodes__plasma_spell_dmg__apply(lvl = null):
	State.player._talentPlasmaDmgMult = (JS.or_(State.player.get("_talentPlasmaDmgMult"), 1.0)) + (lvl * 0.05)

func TALENT_TREE__Plasma__nodes__plasma_basic__apply(lvl = null):
	if State.playerElement == "Plasma":
		State.player._elementalBasicPlasma = lvl

func TALENT_TREE__Air__nodes__air_actions__apply(lvl = null):
	State.player._slipstreamInterval = JS.idx([5, 4, 3], lvl - 1)

func TALENT_TREE__Air__nodes__air_multihit__apply(lvl = null):
	State.player._talentAirHits = (JS.or_(State.player.get("_talentAirHits"), 0)) + lvl

func TALENT_TREE__Air__nodes__air_spell_dmg__apply(lvl = null):
	State.player._talentAirDmgMult = (JS.or_(State.player.get("_talentAirDmgMult"), 1.0)) + (lvl * 0.05)

func TALENT_TREE__Air__nodes__air_basic__apply(lvl = null):
	if State.playerElement == "Air":
		State.player._elementalBasicAir = lvl
