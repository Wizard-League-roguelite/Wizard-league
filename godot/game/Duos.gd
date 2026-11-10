# Duos — generated from js/data/duos.js by tools/js2gd.js
extends Node

var DUO_CATALOGUE = null

func _boot():
	# ===== duos.js =====
	# ─── DUO / MERGED SPELL SYSTEM ───────────────────────────────────────────────
	# Duo content unlocks when the player has committed to two elements.
	# Unlock gate: at least 1 primary + 1 secondary spell in EACH of the two elements,
	# counted across all spellbooks.
	DUO_CATALOGUE = [
		{
			"elements": ["Lightning", "Fire"],
			"spells": ["plasma_arc", "superheated"],
			"passives": ["duo_flashfire", "duo_molten_current"],
		},
		{
			"elements": ["Lightning", "Nature"],
			"spells": ["thunderroot", "static_bloom"],
			"passives": ["duo_stormseed", "duo_charged_roots"],
		},
		{
			"elements": ["Fire", "Nature"],
			"spells": ["burning_grove", "char_bloom"],
			"passives": ["duo_wildfire_seeds", "duo_scorched_earth"],
		},
		{
			"elements": ["Air", "Nature"],
			"spells": ["windfall_seed", "gale_bind"],
			"passives": ["duo_gale_root", "duo_rushing_growth"],
		},
		{
			"elements": ["Air", "Lightning"],
			"spells": ["storm_window", "arc_load"],
			"passives": ["duo_velocity_arc", "duo_galestrike"],
		},
		{
			"elements": ["Air", "Fire"],
			"spells": ["ember_flurry", "afterburn"],
			"passives": ["duo_thermal_draft", "duo_bellows"],
		},
	]

# Returns true if the player has unlocked the duo for the given element pair.
# Cross-book: any spell in any book counts toward qualification.
func _duoUnlocked(elementA = null, elementB = null):
	var available = [State.playerElement] + JS.arr(JS.or_(State.player.get("unlockedElements"), []))
	if (not JS.includes(available, elementA) or not JS.includes(available, elementB)):
		return false
	var _fn1 = func(element = null):
		var hasPrimary = [null]
		var hasSecondary = [null]
		hasPrimary[0] = false
		hasSecondary[0] = false
		for book in JS.iter(JS.or_(State.player.get("spellbooks"), [])):
			for s in JS.iter(book.get("spells")):
				var def = JS.idx(Spells.SPELL_CATALOGUE, s.id)
				if (not JS.t(def) or not JS.eq(def.get("element"), element)):
					continue
				if def.get("tier") == "primary":
					hasPrimary[0] = true
				if def.get("tier") == "secondary":
					hasSecondary[0] = true
		return (hasPrimary[0] and hasSecondary[0])
	var _qualified = _fn1
	return JS.andf(_qualified.call(elementA), func(): return _qualified.call(elementB))

# Returns all unlocked duo spells the player doesn't already own.
func _eligibleDuoSpells():
	var owned = JSSet.new()
	for b in JS.iter(JS.or_(State.player.get("spellbooks"), [])):
		for s in JS.iter(b.get("spells")):
			if not JS.t(s.get("isBuiltin")):
				owned.add(s.id)
	var eligible = []
	for duo in JS.iter(DUO_CATALOGUE):
		if not JS.t(_duoUnlocked(JS.idx(duo.get("elements"), 0), JS.idx(duo.get("elements"), 1))):
			continue
		for id in JS.iter(duo.get("spells")):
			if (not owned.has(id) and JS.t(JS.idx(Spells.SPELL_CATALOGUE, id))):
				eligible.append(JS.idx(Spells.SPELL_CATALOGUE, id))
	return eligible

# Returns all unlocked duo passives the player doesn't already own.
func _eligibleDuoPassives():
	var owned = JSSet.new(JS.or_(State.player.get("passives"), []))
	var eligible = []
	for duo in JS.iter(DUO_CATALOGUE):
		if not JS.t(_duoUnlocked(JS.idx(duo.get("elements"), 0), JS.idx(duo.get("elements"), 1))):
			continue
		for pid in JS.iter(duo.get("passives")):
			if not owned.has(pid):
				var def = State._lookupPassiveDef(pid)
				if JS.t(def):
					eligible.append(JS.merge([def, {"element": JS.join(duo.get("elements"), "/")}]))
	return eligible

# ─── DUO PASSIVE ROUND TICKS ─────────────────────────────────────────────────
# Called each round from startRound (after seed tick, before enemy queue).
func _tickDuoEffects():
	var hasScorchedEarth = Main.hasPassive("duo_scorched_earth")
	if not hasScorchedEarth:
		return
	var _arr2 = JS.iter(State.combat.get("enemies"))
	for i in range(len(_arr2)):
		var e = _arr2[i]
		if not JS.t(e.get("alive")):
			continue
		State.setActiveEnemy(i)
		# Scorched Earth: every 5 Burn stacks on enemy reduce all Seed timers by 1
		var burnStacks = JS.or_(e.get("status").get("burnStacks"), 0)
		if burnStacks >= 5:
			var reductions = floori(burnStacks / 5.0)
			var seeds = JS.or_(e.get("status").get("seeds"), [])
			if len(seeds) > 0:
				for seed_ in JS.iter(seeds):
					seed_.timer = max(0, seed_.get("timer") - reductions)
				UI.log_("🔥🌍 Scorched Earth: " + JS.s(reductions) + " Seed timer reduction(s) from " + JS.s(burnStacks) + " Burn", "status")
				# Immediately bloom any seeds that hit 0
				var toBloom = JS.arr(seeds).filter(func(seed_ = null): return seed_.get("timer") <= 0)
				for seed_ in JS.iter(toBloom):
					Seeds._bloomSeed("enemy", seed_, i)
				e.get("status").seeds = JS.arr(e.get("status").get("seeds")).filter(func(seed_ = null): return seed_.get("timer") > 0)
				if JS.t(State.combat.get("over")):
					continue
	if not JS.t(State.combat.get("over")):
		State.setActiveEnemy(State.combat.get("targetIdx"))
