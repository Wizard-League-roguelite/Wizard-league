# State — generated from js/logic/state.js by tools/js2gd.js
extends Node

# ===== state.js =====
# ─── GAME STATE ──────────────────────────────────────────────────────────────
var playerName = ""
var playerElement = ""
var playerEmoji = ""
var playerColor = ""
var currentZoneElement = ""
var player = null
# ── SPELLBOOK HELPERS ─────────────────────────────────────────────────────────
var BOOK_SPELL_SLOTS_BASE = 6
var BOOK_PASSIVE_SLOTS_BASE = 2
var _pendingOverflowPassive = null
# Overflow state (spell only — passives are now global)
var _pendingOverflowSpell = null
var _pendingOverflowBookIdx = 0
var STATUS_DEFAULTS = null
var combat = null
var status = null
var battleNumber = 1
var currentGymIdx = 0
# which gym we're currently working toward (0-7)
var _runDmgDealt = 0
# total damage player dealt this run
var _runDmgTaken = 0
# total damage player took this run
var _runRoomsCompleted = 0
# rooms cleared this run
var _runZoneReached = ""
# last zone element entered
var _runKillsThisRun = 0
# total enemy kills this run (for Searing Verdict)
var zoneBattleCount = 0
# battles fought in current gym's zone (resets after each gym)
var _zoneRivalDefeated = false
# rival fight doesn't count as a zone battle slot
var _zoneGraph = null
# pre-generated zone node graph {nodes, edges}
var _playerNodeId = -1
var _completedNodeIds = null
# set of completed node ids
var _pendingNodeId = -1
# node id being traveled to (set before encounter, cleared after)
var _zoneIntroPlayed = false
# true after zone intro animation has played
var gymSkips = 0
# times player skipped gym this zone (resets per gym)
var gymDefeated = false
var pendingLevelUps = null

func _boot():
	player = {
		"hp": Constants.BASE_MAX_HP,
		"attackPower": 0,
		"effectPower": 0,
		"defense": 0,
		"skillPoints": 0,
		"gold": 0,
		"inventory": [],
		"spellbook": [],
		"passives": [],
		"startPassive": null,
		"unlockedElements": [],
		"baseMaxHPBonus": 0,
		"revives": 0,
		"bonusActions": 0,
		"basicUpgrade": 0,
		"basicDmgMult": 1.0,
		"_hasteStart": false,
		"_blockStart": 0,
		"_extraStartSpell": false,
		"_rhythmStar": -1,
		"_quickHandsStar": -1,
		"_gritHealOnRevive": 0,
		"_healBonus": 0,
		"basicDmgFlat": 0,
		"_bannerStar": -1,
		"spellbooks": [],
		"activeBookIdx": 0,
		"_activeBookAura": null,
		"_chosenStartBookId": null,
	}
	# Full set of status fields — single source of truth
	STATUS_DEFAULTS = {
		"burnStacks": 0,
		"burnSourcePower": Constants.BASE_POWER,
		"stunned": 0,
		"rootStacks": 0,
		"overgrowthStacks": 0,
		"foamStacks": 0,
		"shockStacks": 0,
		"frostStacks": 0,
		"frozen": false,
		"nextTurnActionPenalty": 0,
		"block": 0,
		"stoneStacks": 0,
		"stoneStanceThisTurn": false,
		"firewallStacks": 0,
		"phaseTurns": 0,
		"lightningMult": 2.0,
		"greasefirePending": false,
		"tidalShieldActive": false,
		"deepCurrentActive": false,
		"cryostasisActive": false,
		"frozenGroundTurns": 0,
		"spreadingVinesTurns": 0,
		"debuffImmune": 0,
		"overchargePowerPending": 0,
		"chargeShotCharging": false,
		"rageBoostPow": 0,
		"rageBoostTurns": 0,
		"plasmaCharge": 3,
		"plasmaChargeHalf": 0,
		"plasmaShieldReduction": 0,
		"borrowedCharge": 0,
		"stallCharge": 0,
		"stallActive": false,
		"singularityActive": false,
		"momentumStacks": 0,
		"momentumNoDecayNext": false,
		"windWallActive": false,
		"windWallPending": 0,
		"tornadoAoENext": false,
		"nextTurnBonusActions": 0,
	}
	combat = {
		"enemies": [],
		"targetIdx": 0,
		"activeEnemyIdx": 0,
		"enemy": {},
		"enemyHP": 0,
		"playerTurn": false,
		"over": false,
		"tempDmgBonus": 0,
		"actionsLeft": 0,
		"basicCD": 0,
		"playerAirToggle": false,
		"enemyAirToggle": false,
		"actionQueue": [],
		"summons": [],
		"totalGold": 0,
		"turnInBattle": 0,
		"plasmaSpendAmounts": {},
		"plasmaOvercharged": false,
		"plasmaChargeReserved": 0,
	}
	status = {"player": JS.merge([STATUS_DEFAULTS]), "enemy": JS.merge([STATUS_DEFAULTS])}
	# current node id (-1 = zone start)
	_completedNodeIds = JSSet.new()
	# true when ALL 8 gyms are beaten
	pendingLevelUps = []

# tracks the element of the current zone/encounter for BG rendering
func _setZoneElement(z = null):
	currentZoneElement = z
	if JS.t(z):
		_runZoneReached = z

# kept for meta upgrade compat; not enforced in-run
func makeSpellbook(element = null, name_ = null):
	return {
		"id": JS.s(element) + "_basic",
		"name": JS.or_(name_, JS.s(element) + "'s Tome"),
		"element": element,
		"spells": [],
		"spellSlots": BOOK_SPELL_SLOTS_BASE,
		"effect": null,
		"isPlasmaBook": false,
	}

# Create a run-book instance from a catalogue entry
func makeBookInstance(catalogueId = null):
	var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, catalogueId)
	if not JS.t(cat):
		return null
	var meta = Artifacts.getMeta()
	var upgradeLevel = JS.or_(JS.idx(JS.or_(meta.get("bookUpgradeLevels"), {}), catalogueId), 0)
	var base = makeSpellbook(JS.or_(cat.get("element"), "Neutral"), cat.name)
	BetweenRuns.applyBookUpgrades(base, catalogueId)
	# apply per-book slot upgrades
	base.id = catalogueId
	base.catalogueId = catalogueId
	base.upgradeLevel = upgradeLevel
	base.emoji = JS.or_(cat.get("emoji"), "📖")
	# Apply slot modifiers from catalogue
	if (JS.or_(cat.get("spellSlots"), 0)) != 0:
		base.spellSlots = max(3, base.spellSlots + cat.spellSlots)
	# Wire on-switch-to effect
	var _lvl = upgradeLevel
	var _fn1 = func():
		if JS.t(cat.get("onSwitchTo")):
			JS.callm(cat, "onSwitchTo", [_lvl])
	base.effect = _fn1
	return base

# Apply a catalogue book's aura to player stats (call when switching to or initializing a book)
func _applyBookAuraToPlayer(book = null):
	_removeBookAuraFromPlayer()
	# always clear old aura first
	if (not JS.t(book) or not JS.t(book.get("catalogueId"))):
		return
	var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, book.catalogueId)
	if (not JS.t(cat) or not JS.t(cat.get("aura"))):
		return
	var aura = JS.callm(cat, "aura", [JS.or_(book.get("upgradeLevel"), 0)])
	var atk = JS.or_(aura.get("atk"), 0)
	var def = JS.or_(aura.get("def"), 0)
	var efx = JS.or_(aura.get("efx"), 0)
	if atk != 0:
		player.attackPower += atk
	if def != 0:
		player.defense += def
	if efx != 0:
		player.effectPower += efx
	player._mutualEnemyAura = ({"atk": atk, "def": def, "efx": efx} if JS.t(aura.get("mutualAura")) else null)
	player._activeBookAura = {"atk": atk, "def": def, "efx": efx, "catalogueId": book.catalogueId}

# Remove the currently applied book aura from player stats
func _removeBookAuraFromPlayer():
	if not JS.t(player.get("_activeBookAura")):
		return
	player.attackPower -= JS.or_(player._activeBookAura.get("atk"), 0)
	player.defense -= JS.or_(player._activeBookAura.get("def"), 0)
	player.effectPower -= JS.or_(player._activeBookAura.get("efx"), 0)
	player._mutualEnemyAura = null
	player._activeBookAura = null

# Returns the index of the plasma-only book, or -1 if none exists
func plasmaBookIdx():
	return JS.findIndex(player.spellbooks, func(b = null): return JS.t(b.get("isPlasmaBook")))

# Creates a dedicated Plasma abilities book if one doesn't exist yet
func ensurePlasmaBook():
	if JS.some(player.spellbooks, func(b = null): return JS.t(b.get("isPlasmaBook"))):
		return
	var pb = makeSpellbook("Plasma", "Plasma Abilities")
	pb.id = "plasma_abilities"
	pb.isPlasmaBook = true
	player.spellbooks.append(pb)

func activeBook():
	if not JS.t(len(player.spellbooks)):
		return null
	return JS.or_(JS.idx(player.spellbooks, player.activeBookIdx), JS.idx(player.spellbooks, 0))

# Keep player.spellbook in sync with active book
# Call this whenever activeBookIdx changes or books change
func syncActiveBook():
	var book = activeBook()
	if not JS.t(book):
		return
	player.spellbook = book.spells
	_applyBookAuraToPlayer(book)

# Passives are global — always read from player.passives
func hasPassive__superseded_State(id = null):
	return JS.includes(JS.or_(player.get("passives"), []), id)

func initSpellbooksForRun():
	var book = makeSpellbook(playerElement, "Standard")
	BetweenRuns.applyBookUpgrades(book)
	# Pre-fill the two built-in utility slots
	book.spells.append_array([{"id": "_basic", "emoji": "⚔", "name": "Basic Attack", "baseCooldown": 1, "currentCD": 0, "isBuiltin": true}, {"id": "_armor", "emoji": "🛡", "name": "Armor", "baseCooldown": 0, "currentCD": 0, "isBuiltin": true}])
	player.spellbooks = [book]
	player.activeBookIdx = 0
	player.passiveSlots = 6
	# global cap, expandable via rewards
	# Plasma players always start with a dedicated Plasma Abilities book
	if playerElement == "Plasma":
		ensurePlasmaBook()
	syncActiveBook()

func switchBook(idx = null):
	if (idx < 0 or idx >= len(player.spellbooks)):
		return
	if JS.eq(idx, player.activeBookIdx):
		return
	# Notify current book we're leaving
	var oldBook = activeBook()
	if (JS.t(oldBook) and JS.t(oldBook.get("catalogueId"))):
		var oldCat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, oldBook.catalogueId)
		if (JS.t(oldCat) and JS.t(oldCat.get("onSwitchAway"))):
			JS.callm(oldCat, "onSwitchAway", [JS.or_(oldBook.get("upgradeLevel"), 0)])
	player.activeBookIdx = idx
	syncActiveBook()
	# also applies new book's aura
	var book = activeBook()
	UI.log_("📖 Switched to " + book.name, "player")
	# Trigger book effect if any (includes catalogue onSwitchTo via makeBookInstance)
	if (JS.t(book.get("effect")) and (JS.typeof_(book.get("effect"))) == "function"):
		JS.callm(book, "effect", [])

# Add a spell to the active book (with overflow check)
# Plasma abilities are always routed to the plasma book regardless of bookIdx
func addSpellToBook(spell = null, bookIdx = null):
	# Plasma abilities belong exclusively in the plasma book
	if JS.t(spell.get("isPlasmaAbility")):
		ensurePlasmaBook()
		var pIdx = plasmaBookIdx()
		if pIdx >= 0:
			var pb = JS.idx(player.spellbooks, pIdx)
			if JS.t(JS.find(pb.spells, func(s = null): return JS.eq(s.id, spell.id))):
				return
			# already owned
			if len(pb.spells) >= pb.spellSlots:
				_pendingOverflowSpell = spell
				_pendingOverflowBookIdx = pIdx
				showBookOverflowScreen(spell, pb)
				return
			pb.spells.append(spell)
			if pIdx == player.activeBookIdx:
				syncActiveBook()
		return
	var idx = (bookIdx if bookIdx != null else player.activeBookIdx)
	# Never route non-plasma spells into the plasma book
	var targetIdx = (0 if (JS.t(JS.idx(player.spellbooks, idx)) and JS.t(JS.idx(player.spellbooks, idx).get("isPlasmaBook"))) else idx)
	var book = JS.idx(player.spellbooks, targetIdx)
	if not JS.t(book):
		return
	if JS.t(JS.find(book.spells, func(s = null): return JS.eq(s.id, spell.id))):
		return
	# already owned
	if len(book.spells) >= book.spellSlots:
		# Full — trigger overflow removal UI
		_pendingOverflowSpell = spell
		_pendingOverflowBookIdx = targetIdx
		showBookOverflowScreen(spell, book)
		return
	book.spells.append(spell)
	if JS.eq(targetIdx, player.activeBookIdx):
		syncActiveBook()

# Add a passive to the global passive pool (book-independent)
func addPassiveToBook(passiveId = null):
	if JS.includes(JS.or_(player.get("passives"), []), passiveId):
		return
	var cap = JS.or_(player.get("passiveSlots"), 6)
	if len(player.passives) >= cap:
		_pendingOverflowPassive = passiveId
		showPassiveOverflowScreen(passiveId)
		return
	player.passives.append(passiveId)
	Library.markPassiveSeen(passiveId)
	if passiveId == "air_tailwind":
		player.attackPower += 15

func showPassiveOverflowScreen(passiveId = null):
	var overlay = document.getElementById("passive-overflow-overlay")
	if not JS.t(overlay):
		return
	var def = _lookupPassiveDef(passiveId)
	document.getElementById("poo-new-passive").textContent = (def.emoji + " " + def.title if JS.t(def) else passiveId)
	document.getElementById("poo-new-desc").textContent = (JS.or_(def.get("desc"), "") if JS.t(def) else "")
	var list = document.getElementById("poo-passive-list")
	list.innerHTML = ""
	var _arr2 = JS.iter(JS.or_(player.get("passives"), []))
	for i in range(len(_arr2)):
		var pid = _arr2[i]
		var pdef = _lookupPassiveDef(pid)
		var btn = document.createElement("button")
		btn.className = "boo-spell-btn"
		btn.innerHTML = "<span>" + JS.s((pdef.emoji + " " + pdef.title if JS.t(pdef) else pid)) + "</span><span class=\"boo-remove-hint\">Replace</span>"
		btn.onclick = func(): return resolvePassiveOverflow(i)
		list.appendChild(btn)
	var declineBtn = document.createElement("button")
	declineBtn.className = "boo-spell-btn"
	declineBtn.style.cssText = "margin-top:.5rem;border-color:#1a1a25;color:#666;"
	declineBtn.innerHTML = "<span>↩ Decline new passive</span>"
	declineBtn.onclick = func(): return declinePassiveOverflow()
	list.appendChild(declineBtn)
	overlay.classList.add("open")

func resolvePassiveOverflow(removeIdx = null):
	if not JS.t(_pendingOverflowPassive):
		return
	var removed = JS.idx(JS.splice(player.passives, removeIdx, 1), 0)
	player.passives.append(_pendingOverflowPassive)
	Library.markPassiveSeen(_pendingOverflowPassive)
	_pendingOverflowPassive = null
	var overlay = document.getElementById("passive-overflow-overlay")
	if JS.t(overlay):
		overlay.classList.remove("open")
	BattleReward.processNextLevelUp()

func declinePassiveOverflow():
	_pendingOverflowPassive = null
	var overlay = document.getElementById("passive-overflow-overlay")
	if JS.t(overlay):
		overlay.classList.remove("open")
	BattleReward.processNextLevelUp()

func showBookOverflowScreen(newSpell = null, book = null):
	var overlay = document.getElementById("book-overflow-overlay")
	if not JS.t(overlay):
		return
	document.getElementById("boo-book-name").textContent = book.name
	document.getElementById("boo-new-spell").textContent = newSpell.emoji + " " + newSpell.name
	document.getElementById("boo-new-desc").textContent = newSpell.desc
	var list = document.getElementById("boo-spell-list")
	list.innerHTML = ""
	# Remove-from-current-book options
	var _arr3 = JS.iter(book.spells)
	for i in range(len(_arr3)):
		var sp = _arr3[i]
		var btn = document.createElement("button")
		btn.className = "boo-spell-btn"
		btn.innerHTML = "<span>" + sp.emoji + " " + sp.name + "</span><span class=\"boo-remove-hint\">Remove</span>"
		btn.onclick = func(): return resolveBookOverflow(i)
		list.appendChild(btn)
	# Send-to-another-book options (only books that aren't full and accept this spell type)
	# Plasma abilities can only live in the plasma book; non-plasma spells cannot enter the plasma book
	var isPlasmAbil = (not (not (JS.t(_pendingOverflowSpell) and JS.t(_pendingOverflowSpell.get("isPlasmaAbility")))))
	var _fn4 = func(_p0 = null):
		var b = JS.idx(_p0, "b")
		var bi = JS.idx(_p0, "bi")
		if JS.eq(bi, _pendingOverflowBookIdx):
			return false
		if isPlasmAbil:
			return false
		# plasma abilities can't move to another book
		if JS.t(b.get("isPlasmaBook")):
			return false
		# non-plasma spells can't enter plasma book
		return true
	var otherBooks = JS.arr(JS.map(player.spellbooks, func(b = null, bi = null): return {"b": b, "bi": bi})).filter(_fn4)
	if len(otherBooks) > 0:
		var sep = document.createElement("div")
		sep.style.cssText = "font-size:.6rem;color:#4a6a9a;letter-spacing:.08em;text-transform:uppercase;margin-top:.5rem;margin-bottom:.2rem;"
		sep.textContent = "— or move to another book —"
		list.appendChild(sep)
		for _e5 in JS.iter(otherBooks):
			var ob = JS.idx(_e5, "b")
			var bi = JS.idx(_e5, "bi")
			var btn = document.createElement("button")
			btn.className = "boo-spell-btn"
			btn.style.borderColor = "#1a2a4a"
			btn.innerHTML = "<span>📖 " + ob.name + "</span><span class=\"boo-remove-hint\" style=\"color:#4a6a9a\">Move</span>"
			var _fn6 = func():
				var spell = _pendingOverflowSpell
				_pendingOverflowSpell = null
				_pendingOverflowBookIdx = 0
				overlay.classList.remove("open")
				addSpellToBook(spell, bi)
			btn.onclick = _fn6
			# may open overflow for target book
			list.appendChild(btn)
	# Discard option
	var discardBtn = document.createElement("button")
	discardBtn.className = "boo-spell-btn"
	discardBtn.style.cssText = "margin-top:.5rem;border-color:#1a1a25;color:#666;"
	discardBtn.innerHTML = "<span>↩ Discard new spell</span>"
	discardBtn.onclick = func(): return discardOverflowSpell()
	list.appendChild(discardBtn)
	overlay.classList.add("open")

func resolveBookOverflow(removeIdx = null):
	var book = JS.idx(player.spellbooks, _pendingOverflowBookIdx)
	if (not JS.t(book) or not JS.t(_pendingOverflowSpell)):
		return
	JS.splice(book.spells, removeIdx, 1)
	book.spells.append(_pendingOverflowSpell)
	if JS.eq(_pendingOverflowBookIdx, player.activeBookIdx):
		syncActiveBook()
	_pendingOverflowSpell = null
	_pendingOverflowBookIdx = 0
	var overlay = document.getElementById("book-overflow-overlay")
	if JS.t(overlay):
		overlay.classList.remove("open")
	BattleReward.processNextLevelUp()

func discardOverflowSpell():
	_pendingOverflowSpell = null
	_pendingOverflowBookIdx = 0
	var overlay = document.getElementById("book-overflow-overlay")
	if JS.t(overlay):
		overlay.classList.remove("open")
	BattleReward.processNextLevelUp()

# ── Passive lookup util ───────────────────────────────────────────────────────
func _lookupPassiveDef(passiveId = null):
	var def = [null]
	def[0] = null
	for arr in JS.iter(JS.values(JS.or_(Passives.PASSIVE_CHOICES, {}))):
		var found = JS.find(JS.or_(arr, []), func(p = null): return JS.eq(p.id, passiveId))
		if JS.t(found):
			def[0] = found
	return def[0]

func freshEnemyStatus():
	return JS.merge([STATUS_DEFAULTS, {"seeds": [], "surgeActive": false, "surgeValue": 0, "surgeMeter": 0}])

func setActiveEnemy(idx = null):
	if not JS.t(JS.idx(combat.enemies, idx)):
		return
	combat.activeEnemyIdx = idx
	combat.enemy = JS.idx(combat.enemies, idx)
	status.enemy = JS.idx(combat.enemies, idx).status
