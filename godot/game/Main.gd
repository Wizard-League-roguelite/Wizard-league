# Main — generated from js/main.js by tools/js2gd.js
extends Node

var ALL_ELEMENTS = null

func _boot():
	# ── ELEMENT SELECT ────────────────────────────────────────────────────────────
	ALL_ELEMENTS = [
		{"el": "Fire", "emoji": "🔥", "color": "#FF4500", "mechanic": "Burn Stacks"},
		{"el": "Water", "emoji": "💧", "color": "#1E90FF", "mechanic": "Heal · Cleanse · Reflect"},
		{"el": "Ice", "emoji": "❄️", "color": "#A0EFFF", "mechanic": "Frost · Freeze · Execute"},
		{"el": "Lightning", "emoji": "⚡", "color": "#FFD700", "mechanic": "Shock · Burst · Overload"},
		{"el": "Earth", "emoji": "🪨", "color": "#8B6914", "mechanic": "Stone · Block · Armor"},
		{"el": "Nature", "emoji": "🌿", "color": "#32CD32", "mechanic": "Root · Summon · Overgrowth"},
		{"el": "Plasma", "emoji": "🔮", "color": "#DA70D6", "mechanic": "Charge · Tank Hits · Unleash"},
		{"el": "Air", "emoji": "🌀", "color": "#B0E0E6", "mechanic": "Speed · Multi-hit"},
	]
	# ── Music bootstrap ───────────────────────────────────────────────────────────
	var _fn9 = func():
		var _started = [null]
		var _firstGesture = [null]
		_started[0] = false
		var _fn8 = func():
			if _started[0]:
				return
			_started[0] = true
			Music._audioStarted = true
			# unlock volumeToggleMute
			# Sync volume level from slider
			var slider = document.getElementById("vol-slider")
			if JS.t(slider):
				Music._volumeLevel = JS.num(slider.value) / 100.0
			# Always start menu music on first gesture — title screen is always first
			Mp3Audio._smartCurrentKey = null
			Mp3Audio.musicPlaySmart("menu")
			for ev in JS.iter(["click", "keydown", "touchstart"]):
				document.removeEventListener(ev, _firstGesture[0], true)
		_firstGesture[0] = _fn8
		for ev in JS.iter(["click", "keydown", "touchstart"]):
			document.addEventListener(ev, _firstGesture[0], true)
	_fn9.call()

# ===== main.js =====
# ─── MAIN / SCREEN NAVIGATION ────────────────────────────────────────────────
# activeSaveSlot and sandboxMode declared in constants.js (runs first, no TDZ)
# ── SAVE SLOTS ────────────────────────────────────────────────────────────────
func _slotKey(slot = null):
	return "elemental_save_v1_slot" + JS.s(slot)

func loadSlot(slot = null):
	var raw = localStorage.getItem(_slotKey(slot))
	if JS.t(raw):
		return JS.jsonParse(raw)
	return null

func saveSlot(slot = null, data = null):
	localStorage.setItem(_slotKey(slot), JS.jsonStringify(data))

func deleteSlot(slot = null):
	localStorage.removeItem(_slotKey(slot))

func getActiveSlotData():
	return JS.or_(loadSlot(Constants.activeSaveSlot), {})

func patchActiveSlot(patch = null):
	var data = getActiveSlotData()
	JS.assign(data, [patch])
	saveSlot(Constants.activeSaveSlot, data)

# ── SAVE SELECT SCREEN ────────────────────────────────────────────────────────
func showSaveSelect():
	var container = document.getElementById("save-slots")
	container.innerHTML = ""
	# Slots 0-2: normal save slots
	for i in range(3):
		var data = loadSlot(i)
		var _fn1 = func():
			var raw = localStorage.getItem("elemental_meta_v1_slot" + JS.s(i))
			return (JS.jsonParse(raw) if JS.t(raw) else null)
		var meta = (_fn1).call()
		var card = document.createElement("div")
		var hasData = (not (not (JS.t(data) and JS.t(data.get("playerName")))))
		card.className = "save-slot-card " + ("has-data" if hasData else "empty")
		if hasData:
			var runs = (JS.or_(meta.get("totalRuns"), 0) if JS.t(meta) else 0)
			var best = (JS.or_(meta.get("bestLevel"), 0) if JS.t(meta) else 0)
			var gyms = (JS.or_(meta.get("gymsBeaten"), 0) if JS.t(meta) else 0)
			card.innerHTML = "\n        <div class=\"save-slot-left\">\n          <div class=\"save-slot-name\">" + JS.s(data.playerName) + "</div>\n          <div class=\"save-slot-stats\">Runs: " + JS.s(runs) + " · Best Lv." + JS.s(best) + " · Gyms: " + JS.s(gyms) + "</div>\n        </div>\n        <div style=\"display:flex;align-items:center;gap:.5rem;\">\n          <div class=\"save-slot-right has-data\">SLOT " + JS.s(i + 1) + "</div>\n          <div class=\"save-slot-delete\" onclick=\"event.stopPropagation();confirmDeleteSlot(" + JS.s(i) + ")\" title=\"Delete save\">✕</div>\n        </div>\n        <div style=\"margin-top:.5rem;border-top:1px solid #1a1208;padding-top:.45rem;display:flex;gap:.4rem;\">\n          <button onclick=\"event.stopPropagation();selectSaveSlot(" + JS.s(i) + ")\" style=\"flex:1;background:#0e0c06;border:1px solid #2a1e0e;color:#c8a060;font-family:Cinzel,serif;font-size:.52rem;letter-spacing:.08em;padding:.3rem .4rem;border-radius:4px;cursor:pointer;\">⚔ Play</button>\n          <button onclick=\"event.stopPropagation();selectSaveSlotSandbox(" + JS.s(i) + ")\" style=\"flex:1;background:#0a0614;border:1px solid #3a1a5a;color:#c080ff;font-family:Cinzel,serif;font-size:.52rem;letter-spacing:.08em;padding:.3rem .4rem;border-radius:4px;cursor:pointer;\">🔬 Sandbox</button>\n        </div>"
		else:
			card.innerHTML = "\n        <div class=\"save-slot-left\">\n          <div class=\"save-slot-name\" style=\"color:#3a2a10;\">Empty Slot</div>\n          <div class=\"save-slot-stats\">— no data —</div>\n        </div>\n        <div class=\"save-slot-right\">SLOT " + JS.s(i + 1) + "</div>"
		card.onclick = func(): return selectSaveSlot(i)
		container.appendChild(card)
	# Slot 3: always-unlocked full master save
	var masterCard = document.createElement("div")
	masterCard.className = "save-slot-card has-data"
	masterCard.style.cssText = "border-color:#5a4010;background:linear-gradient(160deg,#14100a,#0c0805);"
	masterCard.innerHTML = "\n    <div class=\"save-slot-left\">\n      <div class=\"save-slot-name\" style=\"color:#e8c060;\">✦ Full Unlock</div>\n      <div class=\"save-slot-stats\" style=\"color:#6a5020;\">All spells · All books · All talents · All artifacts</div>\n    </div>\n    <div style=\"display:flex;align-items:center;gap:.5rem;\">\n      <div class=\"save-slot-right has-data\" style=\"color:#c8a060;border-color:#5a4010;\">MASTER</div>\n    </div>\n    <div style=\"margin-top:.5rem;border-top:1px solid #2a1a08;padding-top:.45rem;display:flex;gap:.4rem;\">\n      <button onclick=\"event.stopPropagation();selectFullUnlockSlot(false)\" style=\"flex:1;background:#1a1005;border:1px solid #5a3a0a;color:#e8c060;font-family:Cinzel,serif;font-size:.52rem;letter-spacing:.08em;padding:.3rem .4rem;border-radius:4px;cursor:pointer;\">⚔ Play</button>\n      <button onclick=\"event.stopPropagation();selectFullUnlockSlot(true)\" style=\"flex:1;background:#0a0614;border:1px solid #3a1a5a;color:#c080ff;font-family:Cinzel,serif;font-size:.52rem;letter-spacing:.08em;padding:.3rem .4rem;border-radius:4px;cursor:pointer;\">🔬 Sandbox</button>\n    </div>"
	masterCard.onclick = func(): return selectFullUnlockSlot(false)
	container.appendChild(masterCard)
	UI.showScreen("save-select-screen")

func confirmDeleteSlot(slot = null):
	if not JS.t(JS.confirm("Delete Save " + JS.s(slot + 1) + "? This cannot be undone.")):
		return
	deleteSlot(slot)
	localStorage.removeItem("elemental_meta_v1_slot" + JS.s(slot))
	if JS.t(window.get("_metaBySlot")):
		JS.del(window.get("_metaBySlot"), slot)
	showSaveSelect()

func selectSaveSlot(slot = null):
	Constants.activeSaveSlot = slot
	if not JS.t(window.get("_metaBySlot")):
		window._metaBySlot = {}
	window.get("_metaBySlot")[slot] = null
	# force reload on next getMeta()
	var data = loadSlot(slot)
	if (JS.t(data) and JS.t(data.get("playerName"))):
		# Existing save — go straight to lobby
		State.playerName = data.playerName
		Constants.sandboxMode = false
		BetweenRuns.showBetweenRuns()
	else:
		# New slot — need name entry
		showHub()

func selectSaveSlotSandbox(slot = null):
	Constants.activeSaveSlot = slot
	if not JS.t(window.get("_metaBySlot")):
		window._metaBySlot = {}
	window.get("_metaBySlot")[slot] = null
	var data = loadSlot(slot)
	if (JS.t(data) and JS.t(data.get("playerName"))):
		State.playerName = data.playerName
		Constants.sandboxMode = true
		BetweenRuns.showBetweenRuns()
	else:
		showHub()

# ── FULL UNLOCK SLOT (always slot index 3) ────────────────────────────────────
# Rebuilds the meta from live catalogue data every time — always fresh.
func selectFullUnlockSlot(sandbox = null):
	var SLOT = 3
	Constants.activeSaveSlot = SLOT
	if not JS.t(window.get("_metaBySlot")):
		window._metaBySlot = {}
	window.get("_metaBySlot")[SLOT] = null
	# clear cache
	# ── All spell IDs ──
	var allSpellIds = JS.keys(Spells.SPELL_CATALOGUE)
	# ── All passive IDs (flatten all PASSIVE_CHOICES arrays) ──
	var allPassiveIds = []
	for arr in JS.iter(JS.values(Passives.PASSIVE_CHOICES)):
		if (arr is Array):
			for p in JS.iter(arr):
				if (JS.t(p) and JS.t(p.get("id"))):
					allPassiveIds.append(p.id)
	# ── All book IDs at upgrade level 4 ──
	var allBookIds = JS.keys(Spellbooks.SPELLBOOK_CATALOGUE)
	var bookUpgradeLevels = {}
	var bookSlotUpgrades = {}
	for id in JS.iter(allBookIds):
		bookUpgradeLevels[id] = 4
	# ── All artifacts at star 3 ──
	var allArtifactIds = Artifacts.ARTIFACT_ORDER
	var artifacts = JS.arr(allArtifactIds).map(func(id = null): return {"id": id, "star": 3, "roomsUsed": 0})
	# ── All talents at max level ──
	var talents = {}
	for tree in JS.iter(JS.values(Talents.TALENT_TREE)):
		if (JS.t(tree) and (tree.nodes is Array)):
			for node in JS.iter(tree.nodes):
				if (JS.t(node) and JS.t(node.get("id"))):
					talents[node.id] = node.maxLevel
	var meta = {
		"totalRuns": 50,
		"bestLevel": 99,
		"gymsBeaten": 20,
		"artifacts": artifacts,
		"activeArtifactId": JS.or_(JS.idx(allArtifactIds, 0), null),
		"unseenArtifacts": [],
		"ownedBookIds": JS.arr(allBookIds),
		"bookUpgradeLevels": bookUpgradeLevels,
		"bookSlotUpgrades": bookSlotUpgrades,
		"unseenBookIds": [],
		"talents": talents,
		"phos": 9999,
		"phosTotal": 99999,
		"runHistory": [],
		"seenThroneRoom": true,
		"seenSpells": allSpellIds,
		"seenPassives": allPassiveIds,
		"darkOneDefeated": true,
	}
	# Write meta and slot data
	localStorage.setItem("elemental_meta_v1_slot" + JS.s(SLOT), JS.jsonStringify(meta))
	saveSlot(SLOT, {"playerName": "Full Unlock"})
	State.playerName = "Full Unlock"
	Constants.sandboxMode = (not (not JS.t(sandbox)))
	BetweenRuns.showBetweenRuns()

# ── HUB SCREEN ───────────────────────────────────────────────────────────────
func showHub():
	var slotData = getActiveSlotData()
	var meta = Artifacts.getMeta()
	var hasSave = (not (not JS.t(slotData.get("playerName"))))
	document.getElementById("hub-slot-label").textContent = "Save File " + JS.s(Constants.activeSaveSlot + 1)
	document.getElementById("hub-title").textContent = ("Welcome back, " + JS.s(slotData.playerName) if hasSave else "New Adventure")
	# Show name input only for new saves
	var nameInput = document.getElementById("hub-name-input")
	var nameError = document.getElementById("hub-error")
	nameInput.value = JS.or_(slotData.get("playerName"), "")
	nameInput.style.display = ("none" if hasSave else "")
	nameError.style.display = ("none" if hasSave else "")
	# Stats
	var statsRow = document.getElementById("hub-stats-row")
	if meta.totalRuns > 0:
		statsRow.innerHTML = "Runs: <span>" + JS.s(meta.totalRuns) + "</span> &nbsp;·&nbsp; Best Level: <span>" + JS.s(JS.or_(meta.get("bestLevel"), 0)) + "</span> &nbsp;·&nbsp; Gyms: <span>" + JS.s(JS.or_(meta.get("gymsBeaten"), 0)) + "</span>"
	else:
		statsRow.innerHTML = ("<span style=\"color:#3a2a10;\">No runs yet — go fight!</span>" if hasSave else "<span style=\"color:#3a2a10;\">No runs yet</span>")
	UI.showScreen("hub-screen")

func _hubGetName():
	var val = document.getElementById("hub-name-input").value.strip_edges()
	document.getElementById("hub-error").textContent = ""
	if not JS.t(val):
		document.getElementById("hub-error").textContent = "Please enter a name."
		return null
	# Save name to slot
	patchActiveSlot({"playerName": val})
	State.playerName = val
	return val

func hubPlay():
	# Only called for new saves needing name entry
	if not JS.t(_hubGetName()):
		return
	Constants.sandboxMode = false
	var meta = Artifacts.getMeta()
	var isFirstRun = (not JS.t(meta.get("totalRuns")) or JS.eq(meta.get("totalRuns"), 0))
	if isFirstRun:
		for s in JS.iter(document.querySelectorAll(".screen")):
			s.classList.remove("active")
		Mp3Audio.musicStopAll()
		Cutscene.playCutscene(func(): return BetweenRuns.showBetweenRuns())
	else:
		BetweenRuns.showBetweenRuns()

func showElementScreen():
	var pool = JS.arr(ALL_ELEMENTS)
	# Sandbox: all elements. Non-sandbox: 2 random from released elements.
	var picked = (pool if JS.t(Constants.sandboxMode) else BattleReward.pickRandom(JS.arr(pool).filter(func(e = null): return JS.includes(Constants.RELEASED_ELEMENTS, e.el)), 2))
	var grid = document.getElementById("element-grid")
	grid.innerHTML = ""
	State.playerElement = ""
	State.playerEmoji = ""
	State.playerColor = ""
	document.getElementById("start-battle-btn").style.display = "none"
	document.getElementById("selected-label").textContent = ""
	for def in JS.iter(picked):
		var card = document.createElement("div")
		card.className = "element-card"
		card.id = "card-" + JS.s(def.el)
		card.innerHTML = "\n      <div class=\"crack crack-1\"></div><div class=\"crack crack-2\"></div><div class=\"crack crack-3\"></div>\n      <span class=\"emoji\">" + JS.s(def.emoji) + "</span>\n      <span class=\"name\" style=\"color:" + JS.s(def.color) + "\">" + JS.s(def.el) + "</span>\n      <span class=\"mechanic\">" + JS.s(def.mechanic) + "</span>\n    "
		card.onclick = func(): return selectElement(def.el, def.emoji, def.color)
		grid.appendChild(card)
	UI.showScreen("element-screen")

func selectElement(el = null, emoji = null, color = null):
	State.playerElement = el
	State.playerEmoji = emoji
	State.playerColor = color
	for c in JS.iter(document.querySelectorAll(".element-card")):
		c.classList.remove("selected")
	var card = document.getElementById("card-" + JS.s(el))
	if JS.t(card):
		card.classList.add("selected")
	document.getElementById("selected-label").textContent = "Selected: " + JS.s(emoji) + " " + JS.s(el)
	document.getElementById("start-battle-btn").style.display = "block"

# Legacy shim — old calls to goToElementSelect still work
func goToElementSelect():
	hubPlay()

# ── PASSIVE SELECT (run start) ────────────────────────────────────────────────
func showPassiveScreen(element = null):
	var title = document.getElementById("passive-screen-title")
	var sub = document.getElementById("passive-screen-subtitle")
	var list = document.getElementById("passive-choices-screen")
	var startBtn = document.getElementById("passive-start-btn")
	var pool = JS.arr(JS.or_(JS.idx(Passives.PASSIVE_CHOICES, element), [])).filter(func(p = null): return not JS.t(p.get("legendary")))
	var choices = (pool if JS.t(Constants.sandboxMode) else BattleReward.pickRandom(pool, min(3, len(pool))))
	window.pendingStartPassive = null
	startBtn.disabled = true
	var _fn2 = func():
		if not JS.t(window.get("pendingStartPassive")):
			return
		confirmStartPassive(window.get("pendingStartPassive"))
	startBtn.onclick = _fn2
	title.textContent = "Choose a " + JS.s(element) + " Passive"
	sub.textContent = "Pick one to start your run. You can earn others later."
	list.innerHTML = ""
	if not JS.t(len(choices)):
		var msg = document.createElement("div")
		msg.style.cssText = "opacity:.7;font-size:.9rem;"
		msg.textContent = "No passives available."
		list.appendChild(msg)
	for ch in JS.iter(choices):
		var btn = document.createElement("button")
		btn.className = "choice-btn"
		btn.type = "button"
		btn.dataset.passiveId = ch.id
		var infoIcon = ("<span class=\"pc-info-icon\" title=\"" + JS.s(ch.detail) + "\" onclick=\"event.stopPropagation()\">ℹ</span>" if JS.t(ch.get("detail")) else "")
		btn.innerHTML = "<div class=\"choice-title\">" + JS.s(ch.emoji) + " " + JS.s(ch.title) + infoIcon + "</div><div class=\"choice-desc\">" + JS.s(ch.desc) + "</div>"
		var _fn3 = func():
			window.pendingStartPassive = ch.id
			for b in JS.iter(list.querySelectorAll("button.choice-btn")):
				b.style.borderColor = "#2b2b36"
				b.style.transform = ""
			btn.style.borderColor = "#ffffff66"
			btn.style.transform = "translateY(-1px)"
			startBtn.disabled = false
		btn.addEventListener("click", _fn3)
		list.appendChild(btn)
	UI.showScreen("passive-screen")

func hasPassive(id = null):
	return JS.includes(JS.or_(State.player.get("passives"), []), id)

func enemyHasPassive(id = null):
	var e = JS.idx(State.combat.enemies, State.combat.activeEnemyIdx)
	if not JS.t(e):
		return false
	return (JS.eq(e.passive, id) or JS.includes(JS.or_(e.get("extraPassives"), []), id))

# Show book selection screen at run start (if player owns catalogue books)
func showRunBookSelectionScreen(onDone = null):
	var meta = Artifacts.getMeta()
	# In sandbox, offer all catalogue books; otherwise only owned ones
	var ownedBookIds = (JS.keys(Spellbooks.SPELLBOOK_CATALOGUE) if (JS.t(Constants.sandboxMode) and true) else JS.or_(meta.get("ownedBookIds"), []))
	# Deck is chosen in the lobby — auto-select or fall back to default, never show this screen
	if not JS.t(Constants.sandboxMode):
		if JS.t(meta.get("startingBookId")):
			var sid = meta.startingBookId
			if (JS.includes(ownedBookIds, sid) and JS.t(JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, sid))):
				onDone.call(sid)
				return
		onDone.call(null)
		return
	# Non-legendary owned books — randomly sample up to 3
	var _fn4 = func(id = null):
		var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, id)
		return (cat.get("rarity") != "legendary" if JS.t(cat) else cat)
	var regularIds = JS.arr(ownedBookIds).filter(_fn4)
	for i in range(len(regularIds) - 1, 0, -1):
		var j = floori(randf() * (i + 1))
		var _t5 = JS.idx(regularIds, j)
		var _t6 = regularIds[i]
		regularIds[i] = _t5
		regularIds[j] = _t6
	var offeredIds = JS.slice(regularIds, 0, 3)
	if (len(offeredIds) == 0 or false):
		onDone.call(null)
		return
	var cont = document.getElementById("bs-choices")
	if not JS.t(cont):
		onDone.call(null)
		return
	cont.innerHTML = ""
	var bsBadge = document.getElementById("bs-badge")
	var bsTitle = document.getElementById("bs-title")
	var bsSub = document.getElementById("bs-sub")
	if JS.t(bsBadge):
		bsBadge.textContent = "Starting Deck"
	if JS.t(bsTitle):
		bsTitle.textContent = "✦ Choose Your Deck ✦"
	if JS.t(bsSub):
		bsSub.textContent = "Pick the deck you'll begin this run with."
	# Option: use default element tome (no catalogue book)
	var defBtn = document.createElement("button")
	defBtn.className = "prog-choice-btn"
	defBtn.innerHTML = "<div class=\"pc-tag\">Default</div>\n       <div class=\"pc-name\">🃏 " + JS.s(State.playerElement) + " Starter Deck</div>\n       <div class=\"pc-desc\">Your standard deck — no special effects, but no drawbacks either.</div>"
	defBtn.onclick = func(): return onDone.call(null)
	cont.appendChild(defBtn)
	# Offered catalogue books (up to 3, non-legendary)
	var bookUpgradeLevels = JS.or_(meta.get("bookUpgradeLevels"), {})
	for id in JS.iter(offeredIds):
		var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, id)
		if not JS.t(cat):
			continue
		var lvl = JS.or_(JS.idx(bookUpgradeLevels, id), 0)
		var rarityColor = ("#80c8ff" if cat.get("rarity") == "generic" else "#c8a060")
		var rarityLabel = ("⚡ Generic Deck" if cat.get("rarity") == "generic" else (JS.or_(cat.get("element"), "")) + " Deck")
		var btn = document.createElement("button")
		btn.className = "prog-choice-btn"
		btn.innerHTML = "<div class=\"pc-tag\">" + rarityLabel + " · Lv " + JS.s(lvl) + "</div>\n      <div class=\"pc-name\" style=\"color:" + rarityColor + ";\">" + JS.s(cat.emoji) + " " + JS.s(cat.name) + "</div>\n      <div class=\"pc-desc\">" + JS.s((JS.idx(cat.levelDescs, lvl) if JS.t(cat.get("levelDescs")) else cat.desc)) + "</div>\n      <div style=\"font-size:.58rem;color:#6a4a3a;margin-top:.2rem;\">⚠ " + JS.s(cat.negative) + "</div>"
		btn.onclick = func(): return onDone.call(id)
		cont.appendChild(btn)
	UI.showScreen("bookselect-screen")

# ── RUN INIT ──────────────────────────────────────────────────────────────────
func beginRun():
	JS.assign(State.player, [{
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
		"spellbooks": [],
		"activeBookIdx": 0,
		"revives": 0,
		"bonusActions": 0,
		"basicUpgrade": 0,
		"basicDmgMult": 1.0,
		"_hasteStart": false,
		"_blockStart": 0,
		"_extraStartSpell": false,
		"_rerolls": 0,
		"_rhythmStar": -1,
		"_quickHandsStar": -1,
		"_gritHealOnRevive": 0,
		"_healBonus": 0,
		"basicDmgFlat": 0,
		"_bannerStar": -1,
		"_talentReviveBonus": 0,
		"_goldBonus": 0,
		"_talentBurnDmg": 0,
		"_talentBurnStart": 0,
		"_talentFireDmgMult": 1.0,
		"_talentFoamStart": 0,
		"_talentWaterDmgMult": 1.0,
		"_talentFrostBonus": 0,
		"_talentIceExecute": 0,
		"_talentIceDmgMult": 1.0,
		"_talentShockBonus": 0,
		"_talentOverloadFloor": 0.25,
		"_talentLightDmgMult": 1.0,
		"_talentStoneStart": 0,
		"_talentEarthDmgMult": 1.0,
		"_talentRootBonus": 0,
		"_talentTreantHP": 0,
		"_talentNatureDmgMult": 1.0,
		"_talentDodgeBonus": 0,
		"_talentChargeStart": 0,
		"_talentPlasmaDmgMult": 1.0,
		"_talentAirHits": 0,
		"_talentAirDmgMult": 1.0,
	}])
	JS.assign(State.combat, [{
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
	}])
	Helpers.resetStatusForBattle()
	State.battleNumber = 1
	State.currentGymIdx = 0
	State.zoneBattleCount = 0
	State.gymSkips = 0
	State.gymDefeated = false
	State.pendingLevelUps = []
	State._zoneRivalDefeated = false
	State._zoneGraph = null
	State._playerNodeId = -1
	State._completedNodeIds = JSSet.new()
	State._pendingNodeId = -1
	State._zoneIntroPlayed = false
	State._runDmgDealt = 0
	State._runDmgTaken = 0
	State._runRoomsCompleted = 0
	State._runZoneReached = ""
	State._runKillsThisRun = 0
	Encounters.initGymRoster()
	MapCanvas.initZoneSpecial()
	Characters.applyCharacterBuff()
	Artifacts.applyArtifactBonuses()
	Mist.applyMistModifiers()
	# mist before talents so _mistTalentReduction is set
	Talents.applyTalentBonuses()
	# legacy talent tree (honours existing saves)
	KnowledgeTree.applyKnowledgeTreeCards()
	# equipped KT cards for this run
	State.initSpellbooksForRun()
	# create starting spellbook before spells/passives are added
	Spells.giveStarterSpell()
	KnowledgeTree.ktApplyStarterSpells()
	document.getElementById("welcome-msg").textContent = JS.s(State.playerName) + ", choose your element"
	if (JS.t(JS.idx(Passives.PASSIVE_CHOICES, State.playerElement)) and JS.t(len(JS.arr(JS.idx(Passives.PASSIVE_CHOICES, State.playerElement)).filter(func(p = null): return not JS.t(p.get("legendary")))))):
		showPassiveScreen(State.playerElement)
		return
	_offerRunBookThenBattle()

# Helper: show run-start book selection, then launch first battle
func _offerRunBookThenBattle():
	var _fn7 = func(chosenId = null):
		if JS.t(chosenId):
			var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, chosenId)
			if JS.t(cat):
				var newBook = State.makeBookInstance(chosenId)
				if JS.t(newBook):
					# Transfer spells/passives from default book
					var oldBook = JS.idx(State.player.spellbooks, 0)
					if JS.t(oldBook):
						newBook.spells = JS.arr(oldBook.spells)
						newBook.passives = JS.arr(oldBook.passives)
					State.player.spellbooks[0] = newBook
					State.player.activeBookIdx = 0
					State.syncActiveBook()
					UI.log_("📖 Starting with " + JS.s(cat.emoji) + " " + JS.s(cat.name) + ".", "item")
		# First time entering the castle — play throne room intro
		var meta = Artifacts.getMeta()
		if not JS.t(meta.get("seenThroneRoom")):
			meta.seenThroneRoom = true
			Artifacts.saveMeta()
			for s in JS.iter(document.querySelectorAll(".screen")):
				s.classList.remove("active")
			Mp3Audio.musicStopAll()
			CastleCutscene.playThroneRoomCutscene(func(): return BattleLoad.loadBattle(JS.idx(Encounters.ENCOUNTER_POOL, 0)))
		else:
			BattleLoad.loadBattle(JS.idx(Encounters.ENCOUNTER_POOL, 0))
	showRunBookSelectionScreen(_fn7)

func confirmStartPassive(passiveId = null):
	State.player.startPassive = passiveId
	# Put start passive into active book
	if (JS.t(State.player.get("spellbooks")) and JS.t(len(State.player.spellbooks))):
		State.addPassiveToBook(passiveId)
	else:
		State.player.passives = [passiveId]
	if JS.t(State.player.get("_extraStartSpell")):
		var owned = JSSet.new(JS.arr(State.player.spellbook).map(func(s = null): return s.id))
		var candidates = JS.arr(JS.values(Spells.SPELL_CATALOGUE)).filter(func(s = null): return ((JS.eq(s.element, State.playerElement) and not owned.has(s.id)) and not JS.t(s.get("legendary"))))
		if JS.t(len(candidates)):
			var pick = JS.idx(candidates, floori(randf() * len(candidates)))
			Spells.addSpellById(pick.id)
			UI.log_("📚 Head Start: bonus spell — " + JS.s(pick.emoji) + " " + JS.s(pick.name) + "!", "item")
	_offerRunBookThenBattle()

func backToElementSelectFromPassive():
	window.pendingStartPassive = null
	showElementScreen()
