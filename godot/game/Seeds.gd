# Seeds — generated from js/logic/seeds.js by tools/js2gd.js
extends Node


func _boot():
	pass

# ===== seeds.js =====
# ─── SEED SYSTEM — Nature element ────────────────────────────────────────────
# Seeds are planted on a target (enemies) or the player (Healing Seed) with a
# 5-turn germination timer. Planting the same type again adds stacks — all
# bloom simultaneously on the original timer (timer does NOT reset on stack).
# Eternal Garden: each individual stack has its own independent timer.
# ─── PLANT ───────────────────────────────────────────────────────────────────
# Returns true if Seed Surge was consumed (spell should reset its own CD).
func _plantSeed(targetSide = null, type_ = null, stacks = null, timer = null, opts = null):
	stacks = JS.or_(stacks, 1)
	timer = JS.or_(timer, 4)
	var incantLevel = JS.or_((opts.get("incantLevel") if JS.t(opts) else opts), 1)
	# Patient Bloom: +1 timer
	if Main.hasPassive("nature_patient_bloom"):
		timer += 1
	# Seed Surge: free stacks (incantation-scaled), next seed costs no CD
	var surge = (not (not JS.t(State.combat.get("_seedSurgePending"))))
	if surge:
		stacks += JS.or_(State.combat.get("_seedSurgeBonus"), 2)
		State.combat._seedSurgePending = false
		State.combat._seedSurgeBonus = 2
	var tgt = (State.status.get("player") if JS.eq(targetSide, "player") else (JS.or_(JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx")), {})).get("status"))
	if not JS.t(tgt):
		return surge
	if not JS.t(tgt.get("seeds")):
		tgt.seeds = []
	var eternal = Main.hasPassive("nature_eternal_garden")
	if JS.eq(type_, "silence"):
		# Silence never merges — each cast is its own independent seed
		for i in range(ceili(stacks)):
			tgt.get("seeds").append({"type": "silence", "stacks": 1, "timer": timer, "incantLevel": incantLevel})
		UI.log_("🤫 Silence Seed planted! (" + JS.s(stacks) + " seed" + ("s" if stacks > 1 else "") + ", blooms in " + JS.s(timer) + ")", "status")
		return surge
	if eternal:
		# Eternal Garden: every stack is an independent entry with its own timer
		for i in range(ceili(stacks)):
			tgt.get("seeds").append({"type": type_, "stacks": 1, "timer": timer, "incantLevel": incantLevel})
		UI.log_("🌱 " + JS.s(_seedLabel(type_)) + " Seed planted! (×" + JS.s(stacks) + " independent, timer " + JS.s(timer) + ")", "status")
	else:
		# Normal: merge stacks onto existing seed of same type (timer unchanged)
		var existing = JS.find(tgt.get("seeds"), func(s = null): return JS.eq(s.type, type_))
		if JS.t(existing):
			existing.stacks += stacks
			UI.log_("🌱 " + JS.s(_seedLabel(type_)) + " Seed stacked! (×" + JS.s(existing.get("stacks")) + ", blooms in " + JS.s(existing.get("timer")) + ")", "status")
		else:
			tgt.get("seeds").append({"type": type_, "stacks": stacks, "timer": timer, "incantLevel": incantLevel})
			UI.log_("🌱 " + JS.s(_seedLabel(type_)) + " Seed planted! (×" + JS.s(stacks) + ", blooms in " + JS.s(timer) + ")", "status")
	return surge

func _seedLabel(type_ = null):
	return JS.or_(JS.idx({"damage": "Damage", "root": "Root", "silence": "Silence", "armor": "Armor", "momentum": "Momentum"}, type_), type_)

# ─── BLOOM ───────────────────────────────────────────────────────────────────
func _bloomSeed(targetSide = null, seed_ = null, enemyIdx = null, opts = null):
	if (not JS.t(seed_) or seed_.get("stacks") <= 0):
		return
	var prevActive = State.combat.get("activeEnemyIdx")
	if (JS.eq(targetSide, "enemy") and enemyIdx != null):
		State.setActiveEnemy(enemyIdx)
	var powerMult = (opts.get("powerMult") if (JS.t(opts) and opts.get("powerMult") != null) else 1)
	var efx = Helpers.effectPowerFor("player")
	var def = Helpers.defenseFor("player")
	var il = JS.or_(seed_.get("incantLevel"), 1)
	var label = "🌸 " + JS.s(_seedLabel(seed_.type)) + " Seed (×" + JS.s(seed_.get("stacks")) + ")"
	var patientMult = (1.3 if Main.hasPassive("nature_patient_bloom") else 1)
	match seed_.type:
		"damage":
			var perStack = floori(((30 + Incantations._incantationBonus(il, 5, 0.9)) + (efx * 0.5)) * patientMult)
			var _bEnemy = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
			var _hpBefore = (_bEnemy.get("hp") if JS.t(_bEnemy) else 0)
			Hit.performHit("player", "enemy", {
				"baseDamage": floori((perStack * seed_.get("stacks")) * powerMult),
				"effects": [],
				"abilityElement": "Nature",
				"label": label,
				"_noAtk": true,
				"noRecord": true,
			})
			# Wildfire Seeds (Fire+Nature): apply Burn equal to damage dealt
			if ((not JS.t(State.combat.get("over")) and Main.hasPassive("duo_wildfire_seeds")) and JS.eq(targetSide, "enemy")):
				var _bEnemyNow = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
				if (JS.t(_bEnemyNow) and JS.t(_bEnemyNow.get("alive"))):
					var actualDmg = max(0, _hpBefore - _bEnemyNow.get("hp"))
					if actualDmg > 0:
						_bEnemyNow.get("status").burnStacks = (JS.or_(_bEnemyNow.get("status").get("burnStacks"), 0)) + actualDmg
						UI.log_("🔥🌱 Wildfire Seeds: +" + JS.s(actualDmg) + " Burn from bloom!", "status")
		"root":
			var perStack = floori((3 + floori(Incantations._incantationBonus(il, 1, 1.0))) * patientMult)
			var totalRoot = floori((perStack * seed_.get("stacks")) * powerMult)
			Helpers.applyRoot("player", "enemy", totalRoot)
			UI.log_(label + " — " + JS.s(totalRoot) + " Root!", "player")
		"silence":
			# Silences N random player spells, prioritizing the active book
			var baseCount = 4 + floori(Incantations._incantationBonus(il, 1, 1.0))
			var count = max(1, floori(baseCount * powerMult))
			var books = JS.or_(State.player.get("spellbooks"), [])
			var activeIdx = JS.or_(State.player.get("activeBookIdx"), 0)
			var activeSpells = JS.or_((JS.or_(JS.idx(books, activeIdx), {})).get("spells"), [])
			var otherSpells = []
			var _arr1 = JS.iter(books)
			for i in range(len(_arr1)):
				var b = _arr1[i]
				if i != activeIdx:
					for sp in JS.iter(JS.or_(b.get("spells"), [])):
						otherSpells.append(sp)
			var shuffActive = JS.sort(JS.arr(activeSpells), func(): return JS.random() - 0.5)
			var shuffOther = JS.sort(JS.arr(otherSpells), func(): return JS.random() - 0.5)
			var targets = []
			while (len(targets) < count and len(shuffActive) > 0):
				targets.append(shuffActive.pop_front())
			while (len(targets) < count and len(shuffOther) > 0):
				targets.append(shuffOther.pop_front())
			for sp in JS.iter(targets):
				sp.currentCD = max(JS.or_(sp.get("currentCD"), 0), 2)
			var names = JS.join(JS.arr(targets).map(func(sp = null): return JS.or_(sp.get("name"), sp.get("id"))), ", ")
			UI.log_("🤫 " + label + " — " + JS.s(count) + " spell" + ("s" if count != 1 else "") + " silenced: " + (JS.or_(names, "none")) + "!", "player")
			# Patient Bloom: spill 2 extra silences into inactive books
			if (patientMult > 1 and len(shuffOther) > 0):
				var extra = JS.slice(shuffOther, 0, 2)
				for sp in JS.iter(extra):
					sp.currentCD = max(JS.or_(sp.get("currentCD"), 0), 2)
				UI.log_("🌾🤫 Patient Bloom spill: " + JS.join(JS.arr(extra).map(func(sp = null): return JS.or_(sp.get("name"), sp.get("id"))), ", ") + " also silenced!", "status")
		"armor":
			var perStack = floori((30 + Incantations._incantationBonus(il, 8, 0.95)) * patientMult)
			var totalArmor = floori((perStack * seed_.get("stacks")) * powerMult)
			Helpers.gainBlock("player", totalArmor)
			UI.log_(label + " — +" + JS.s(totalArmor) + " Armor!", "player")
		"momentum":
			var momGain = JS.round((10 * seed_.get("stacks")) * powerMult)
			Helpers.addMomentumStacks(momGain)
			UI.log_(label + " — +" + JS.s(momGain) + " Momentum!", "player")
	if JS.t(State.combat.get("over")):
		if JS.eq(targetSide, "enemy"):
			State.setActiveEnemy(prevActive)
		return
	# ── Thorn Bloom: +2 Root if target is Rooted ──
	if (JS.eq(targetSide, "enemy") and Main.hasPassive("nature_thorn_bloom")):
		var e = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
		if ((JS.t(e) and JS.t(e.get("alive"))) and (JS.or_(e.get("status").get("rootStacks"), 0)) > 0):
			Helpers.applyRoot("player", "enemy", 2)
			UI.log_("🌹 Thorn Bloom: +2 Root on bloom!", "status")
	# ── Rooted Bloom: Root = stacks that bloomed ──
	if (JS.eq(targetSide, "enemy") and Main.hasPassive("nature_rooted_bloom")):
		var e = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
		if (JS.t(e) and JS.t(e.get("alive"))):
			Helpers.applyRoot("player", "enemy", seed_.get("stacks"))
			UI.log_("🌺 Rooted Bloom: +" + JS.s(seed_.get("stacks")) + " Root from bloom!", "status")
	if JS.t(State.combat.get("over")):
		if JS.eq(targetSide, "enemy"):
			State.setActiveEnemy(prevActive)
		return
	# ── Perennial: replant with 1 stack at timer 3 ──
	if Main.hasPassive("nature_perennial"):
		_plantSeed(targetSide, seed_.type, 1, 3, {"incantLevel": il})
		UI.log_("🌸 Perennial: " + JS.s(_seedLabel(seed_.type)) + " Seed replanted (timer 3).", "status")
	if JS.eq(targetSide, "enemy"):
		State.setActiveEnemy(prevActive)

# ─── VERDANT PATIENCE ────────────────────────────────────────────────────────
# Called at round start before tick. If any Seed timer ≤ 2 (3+ turns active),
# gain 15 armor and reduce all Seed timers by 1.
func _checkVerdantPatience():
	var anyOld = [null]
	if not Main.hasPassive("nature_verdant_patience"):
		return
	anyOld[0] = false
	for e in JS.iter(State.combat.get("enemies")):
		if (not JS.t(e.get("alive")) or not JS.t(e.get("status").get("seeds"))):
			continue
		for s in JS.iter(e.get("status").get("seeds")):
			if s.get("timer") <= 3:
				anyOld[0] = true
	if JS.t(State.status.get("player").get("seeds")):
		for s in JS.iter(State.status.get("player").get("seeds")):
			if s.get("timer") <= 3:
				anyOld[0] = true
	if not (anyOld[0]):
		return
	Helpers.gainBlock("player", 15)
	UI.log_("🌿 Verdant Patience! +15 Armor, all Seed timers −1.", "status")
	# Reduce timers (min 1 — the tick will bring 1→0 for blooms this round)
	for e in JS.iter(State.combat.get("enemies")):
		if (not JS.t(e.get("alive")) or not JS.t(e.get("status").get("seeds"))):
			continue
		for s in JS.iter(e.get("status").get("seeds")):
			s.timer = max(1, s.get("timer") - 1)
	if JS.t(State.status.get("player").get("seeds")):
		for s in JS.iter(State.status.get("player").get("seeds")):
			s.timer = max(1, s.get("timer") - 1)

# ─── TICK ────────────────────────────────────────────────────────────────────
# Called each round after _checkVerdantPatience. Decrements timers and blooms.
func _tickSeeds():
	# Enemy seeds
	var _arr2 = JS.iter(State.combat.get("enemies"))
	for i in range(len(_arr2)):
		var e = _arr2[i]
		if ((not JS.t(e.get("alive")) or not JS.t(e.get("status").get("seeds"))) or not JS.t(len(e.get("status").get("seeds")))):
			continue
		for s in JS.iter(e.get("status").get("seeds")):
			s.timer -= 1
		var toBloom = JS.arr(e.get("status").get("seeds")).filter(func(s = null): return s.get("timer") <= 0)
		e.get("status").seeds = JS.arr(e.get("status").get("seeds")).filter(func(s = null): return s.get("timer") > 0)
		for seed_ in JS.iter(toBloom):
			if not JS.t(State.combat.get("over")):
				_bloomSeed("enemy", seed_, i)
	# Player seeds
	if (JS.t(State.status.get("player").get("seeds")) and JS.t(len(State.status.get("player").get("seeds")))):
		for s in JS.iter(State.status.get("player").get("seeds")):
			s.timer -= 1
		var toBloom = JS.arr(State.status.get("player").get("seeds")).filter(func(s = null): return s.get("timer") <= 0)
		State.status.get("player").seeds = JS.arr(State.status.get("player").get("seeds")).filter(func(s = null): return s.get("timer") > 0)
		for seed_ in JS.iter(toBloom):
			if not JS.t(State.combat.get("over")):
				_bloomSeed("player", seed_)
	# Decay enemy silence counter
	for e in JS.iter(State.combat.get("enemies")):
		if (JS.or_(e.get("_silenced"), 0)) > 0:
			e._silenced -= 1

# ─── ACCELERATE ──────────────────────────────────────────────────────────────
# Reduce ALL active Seed timers by `amount`. If any reach 0, bloom immediately.
func _accelerateSeeds(amount = null):
	amount = [amount]
	amount[0] = JS.or_(amount[0], 1)
	var prevActive = State.combat.get("activeEnemyIdx")
	var _arr3 = JS.iter(State.combat.get("enemies"))
	for i in range(len(_arr3)):
		var e = _arr3[i]
		if ((not JS.t(e.get("alive")) or not JS.t(e.get("status").get("seeds"))) or not JS.t(len(e.get("status").get("seeds")))):
			continue
		for s in JS.iter(e.get("status").get("seeds")):
			s.timer = max(0, s.get("timer") - amount[0])
		var toBloom = JS.arr(e.get("status").get("seeds")).filter(func(s = null): return s.get("timer") <= 0)
		e.get("status").seeds = JS.arr(e.get("status").get("seeds")).filter(func(s = null): return s.get("timer") > 0)
		for seed_ in JS.iter(toBloom):
			if not JS.t(State.combat.get("over")):
				_bloomSeed("enemy", seed_, i)
	if (JS.t(State.status.get("player").get("seeds")) and JS.t(len(State.status.get("player").get("seeds")))):
		for s in JS.iter(State.status.get("player").get("seeds")):
			s.timer = max(0, s.get("timer") - amount[0])
		var toBloom = JS.arr(State.status.get("player").get("seeds")).filter(func(s = null): return s.get("timer") <= 0)
		State.status.get("player").seeds = JS.arr(State.status.get("player").get("seeds")).filter(func(s = null): return s.get("timer") > 0)
		for seed_ in JS.iter(toBloom):
			if not JS.t(State.combat.get("over")):
				_bloomSeed("player", seed_)
	State.setActiveEnemy(prevActive)

# ─── DEEP ROOTS ──────────────────────────────────────────────────────────────
# Called from applyRoot when attacker is player and target is enemy.
# Every 3rd Root applied to a target reduces its Seed timers by 1.
func _deepRootsCheck():
	if not Main.hasPassive("nature_deep_roots"):
		return
	var e = JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx"))
	if (not JS.t(e) or not JS.t(e.get("alive"))):
		return
	e._deepRootsCounter = (JS.or_(e.get("_deepRootsCounter"), 0)) + 1
	if (((JS.mod(e.get("_deepRootsCounter"), 3)) == 0 and JS.t(e.get("status").get("seeds"))) and JS.t(len(e.get("status").get("seeds")))):
		for s in JS.iter(e.get("status").get("seeds")):
			s.timer = max(1, s.get("timer") - 1)
		UI.log_("🌿 Deep Roots: Seed timers −1!", "status")

# ─── ROOTED BLOOM DECAY ──────────────────────────────────────────────────────
# Called when Root decays on a target. Reduces the nearest Seed timer by 1.
func _rootedBloomDecay(targetSide = null):
	if not Main.hasPassive("nature_rooted_bloom"):
		return
	var seeds = (State.status.get("player").get("seeds") if JS.eq(targetSide, "player") else JS.andf((JS.or_(JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx")), {})).get("status"), func(): return JS.idx(State.combat.get("enemies"), State.combat.get("activeEnemyIdx")).get("status").get("seeds")))
	if (not JS.t(seeds) or not JS.t(len(seeds))):
		return
	# "nearest" = lowest timer (closest to blooming)
	var nearest = JS.reduce(seeds, func(min_ = null, s = null): return (s if s.get("timer") < min_.get("timer") else min_), JS.idx(seeds, 0))
	if JS.t(nearest):
		nearest.timer = max(1, nearest.get("timer") - 1)
		UI.log_("🌺 Rooted Bloom: Root decay shortens nearest Seed timer (" + JS.s(nearest.get("timer")) + " left)!", "status")

# ─── SEED STATUS SUMMARY ─────────────────────────────────────────────────────
# Returns a display string for seed state on a target (for UI/logs).
func _seedStatusSummary(seeds = null):
	if (not JS.t(seeds) or not JS.t(len(seeds))):
		return ""
	var groups = {}
	for s in JS.iter(seeds):
		var k = s.type
		if not JS.t(JS.idx(groups, k)):
			groups[k] = {"stacks": 0, "minTimer": s.get("timer")}
		JS.idx(groups, k).stacks += s.get("stacks")
		JS.idx(groups, k).minTimer = min(JS.idx(groups, k).get("minTimer"), s.get("timer"))
	var _fn4 = func(_p0 = null):
		var t = JS.idx(_p0, 0)
		var g = JS.idx(_p0, 1)
		return JS.s(_seedLabel(t)) + "×" + JS.s(g.get("stacks")) + "(" + JS.s(g.get("minTimer")) + "t)"
	return JS.join(JS.arr(JS.entries(groups)).map(_fn4), " ")
