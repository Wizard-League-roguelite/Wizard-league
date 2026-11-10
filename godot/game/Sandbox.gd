# Sandbox — generated from js/ui/sandbox.js by tools/js2gd.js
extends Node


func _boot():
	pass

# ===== sandbox.js =====
# ─── SANDBOX MODE — skip battle, enemy picker, spell picker, zone switcher ────
func sandboxSkipBattle():
	if not JS.t(Constants.sandboxMode):
		return
	State.combat.over = true
	Sprites.stopBattleLoop()
	UI.setPlayerTurnUI(false)
	var gold = JS.or_(State.combat.get("totalGold"), 30)
	State.player.gold += gold
	State.battleNumber += 1
	State.zoneBattleCount += 1
	State._runRoomsCompleted = (JS.or_(State._runRoomsCompleted, 0)) + 1
	UI.log_("⚡ Sandbox: battle skipped (treated as win). +" + JS.s(gold) + " gold.", "system")
	Artifacts.applyBannerReward()
	Artifacts.incrementArtifactRooms()
	var _fn1 = func():
		BattleReward.showBattleRewardScreen(false, JS.or_(State.combat.get("_isSpellBattle"), false), false)
	JS.setTimeout(_fn1, 400)

func sandboxOpenEnemyPicker():
	if not JS.t(Constants.sandboxMode):
		return
	var content = document.getElementById("seo-content")
	if not JS.t(content):
		return
	content.innerHTML = ""
	var sectionStyle = "margin-bottom:.8rem;"
	var headStyle = "font-family:\"Cinzel\",serif;font-size:.65rem;color:#666;letter-spacing:.1em;text-transform:uppercase;margin-bottom:.35rem;"
	var gridStyle = "display:flex;flex-wrap:wrap;gap:.3rem;"
	var btnBase = "border-radius:4px;padding:3px 8px;font-size:.6rem;font-family:\"Cinzel\",serif;cursor:pointer;border-width:1px;border-style:solid;"
	# ── Target Dummy ──
	var dummyDiv = document.createElement("div")
	dummyDiv.style.cssText = sectionStyle
	var dummyHead = document.createElement("div")
	dummyHead.style.cssText = headStyle
	dummyHead.textContent = "Training"
	dummyDiv.appendChild(dummyHead)
	var dummyBtn = document.createElement("button")
	dummyBtn.textContent = "🎯 Target Dummy"
	dummyBtn.style.cssText = btnBase + "background:#1a1a0a;border-color:#6a6a22;color:#cccc44;"
	var _fn2 = func():
		sandboxLoadEnemy({
			"name": "Target Dummy",
			"emoji": "🎯",
			"element": "Neutral",
			"enemyMaxHP": 1000,
			"enemyDmg": 0,
			"gold": 0,
			"type": "wizard",
			"isTargetDummy": true,
		})
	dummyBtn.onclick = _fn2
	dummyDiv.appendChild(dummyBtn)
	content.appendChild(dummyDiv)
	# ── Singles ──
	var singlesDiv = document.createElement("div")
	singlesDiv.style.cssText = sectionStyle
	var singlesHead = document.createElement("div")
	singlesHead.style.cssText = headStyle
	singlesHead.textContent = "Singles"
	singlesDiv.appendChild(singlesHead)
	var singlesGrid = document.createElement("div")
	singlesGrid.style.cssText = gridStyle
	for enc in JS.iter(JS.or_(Encounters.ENCOUNTER_POOL, [])):
		var meta = (JS.idx(Encounters.CAMP_META, enc.get("element")) if JS.t(JS.idx(Encounters.CAMP_META, enc.get("element"))) else {"color": "#888", "icon": "✦"})
		var btn = document.createElement("button")
		btn.textContent = JS.s(meta.get("icon")) + " " + JS.s(enc.get("name"))
		btn.style.cssText = btnBase + ("background:" + JS.s(meta.get("color")) + "22;border-color:" + JS.s(meta.get("color")) + "55;color:" + JS.s(meta.get("color")) + ";")
		var _fn3 = func():
			sandboxLoadEnemy(enc)
		btn.onclick = _fn3
		singlesGrid.appendChild(btn)
	singlesDiv.appendChild(singlesGrid)
	content.appendChild(singlesDiv)
	# ── Packs ──
	var packsDiv = document.createElement("div")
	packsDiv.style.cssText = sectionStyle
	var packsHead = document.createElement("div")
	packsHead.style.cssText = headStyle
	packsHead.textContent = "Packs"
	packsDiv.appendChild(packsHead)
	var packsGrid = document.createElement("div")
	packsGrid.style.cssText = gridStyle
	for enc in JS.iter(JS.or_(Encounters.PACK_POOL, [])):
		var meta = (JS.idx(Encounters.CAMP_META, enc.get("element")) if JS.t(JS.idx(Encounters.CAMP_META, enc.get("element"))) else {"color": "#888", "icon": "✦"})
		var btn = document.createElement("button")
		btn.textContent = JS.s(meta.get("icon")) + " " + JS.s(enc.get("packName")) + " (" + JS.s(len(enc.get("members"))) + ")"
		btn.style.cssText = btnBase + ("background:" + JS.s(meta.get("color")) + "22;border-color:" + JS.s(meta.get("color")) + "55;color:" + JS.s(meta.get("color")) + ";")
		var _fn4 = func():
			sandboxLoadEnemy(enc)
		btn.onclick = _fn4
		packsGrid.appendChild(btn)
	packsDiv.appendChild(packsGrid)
	content.appendChild(packsDiv)
	# ── Gym Bosses ──
	var gymsDiv = document.createElement("div")
	gymsDiv.style.cssText = sectionStyle
	var gymsHead = document.createElement("div")
	gymsHead.style.cssText = headStyle
	gymsHead.textContent = "Gym Bosses"
	gymsDiv.appendChild(gymsHead)
	var gymsGrid = document.createElement("div")
	gymsGrid.style.cssText = gridStyle
	for gym in JS.iter(JS.or_(Encounters.GYM_ROSTER, [])):
		var meta = (JS.idx(Encounters.CAMP_META, gym.get("element")) if JS.t(JS.idx(Encounters.CAMP_META, gym.get("element"))) else {"color": "#888", "icon": "✦"})
		var btn = document.createElement("button")
		btn.textContent = JS.s(gym.get("emoji")) + " " + JS.s(gym.get("name"))
		btn.style.cssText = btnBase + ("background:" + JS.s(meta.get("color")) + "22;border-color:" + JS.s(meta.get("color")) + "55;color:" + JS.s(meta.get("color")) + ";")
		var _fn5 = func():
			sandboxLoadEnemy({
				"name": gym.get("name"),
				"emoji": gym.get("emoji"),
				"element": gym.get("element"),
				"color": gym.get("color"),
				"difficulty": "gym",
				"diffClass": "diff-hard",
				"enemyMaxHP": Helpers.gymBossHP(),
				"enemyDmg": gym.get("baseDmg"),
				"gold": gym.get("gold"),
				"type": "wizard",
				"isGym": true,
				"signature": gym.get("signature"),
				"gymPassive": gym.get("passive"),
				"gymPhase2Passive": gym.get("phase2Passive"),
				"gymEntryEffect": gym.get("entryEffect"),
				"gymHitCounter": 0,
				"gymPhase2": false,
				"gymPhase2Dmg": gym.get("phase2Dmg"),
				"gymChargeInterval": gym.get("chargeInterval"),
			})
		btn.onclick = _fn5
		gymsGrid.appendChild(btn)
	gymsDiv.appendChild(gymsGrid)
	content.appendChild(gymsDiv)
	document.getElementById("sandbox-enemy-overlay").style.display = "block"

func sandboxLoadEnemy(enc = null):
	document.getElementById("sandbox-enemy-overlay").style.display = "none"
	var savedZone = JS.or_(State.combat.get("activeZoneElement"), State.currentZoneElement)
	BattleLoad.loadBattle(enc)
	if JS.t(savedZone):
		sandboxSetCombatZone(savedZone)

func sandboxOpenSpellPicker():
	if not JS.t(Constants.sandboxMode):
		return
	var content = document.getElementById("sso-content")
	if not JS.t(content):
		return
	content.innerHTML = ""
	var headStyle = "font-family:\"Cinzel\",serif;font-size:.62rem;color:#4aaa6a;letter-spacing:.1em;text-transform:uppercase;margin:.7rem 0 .3rem;"
	var gridStyle = "display:flex;flex-wrap:wrap;gap:.3rem;margin-bottom:.4rem;"
	var btnBase = "border-radius:4px;padding:4px 9px;font-size:.6rem;font-family:\"Cinzel\",serif;cursor:pointer;border-width:1px;border-style:solid;"
	# Group all spells for player's element by tier
	var tiers = ["primary", "secondary", "legendary"]
	var tierLabels = {"primary": "Primary", "secondary": "Secondary", "legendary": "Legendary"}
	# Current spellbook IDs for quick lookup
	var book = State.activeBook()
	var ownedIds = JSSet.new(JS.arr((book.get("spells") if JS.t(book) else State.player.get("spellbook"))).map(func(s = null): return s.id))
	for tier in JS.iter(tiers):
		var spells = JS.arr(JS.values(Spells.SPELL_CATALOGUE)).filter(func(sp = null): return (JS.eq(sp.get("element"), State.playerElement) and JS.eq(sp.get("tier"), tier)))
		if not JS.t(len(spells)):
			continue
		var head = document.createElement("div")
		head.style.cssText = headStyle
		head.textContent = JS.idx(tierLabels, tier)
		content.appendChild(head)
		var grid = document.createElement("div")
		grid.style.cssText = gridStyle
		for spell in JS.iter(spells):
			var owned = ownedIds.has(spell.id)
			var btn = document.createElement("button")
			btn.title = JS.or_(spell.get("desc"), "")
			if owned:
				btn.style.cssText = btnBase + "background:#0a2a0a;border-color:#4aaa6a;color:#4aaa6a;"
				btn.innerHTML = JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")) + " <span style=\"font-size:.5rem;opacity:.7;\">✓ Remove</span>"
			else:
				btn.style.cssText = btnBase + "background:#0d0b09;border-color:#2a5a3a;color:#7ac09a;"
				btn.innerHTML = JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")) + " <span style=\"font-size:.5rem;opacity:.55;\">+ Add</span>"
			var _fn6 = func():
				sandboxToggleSpell(spell.id)
				sandboxOpenSpellPicker()
			btn.onclick = _fn6
			grid.appendChild(btn)
		content.appendChild(grid)
	# Also show non-element spells (Neutral)
	var neutralSpells = JS.arr(JS.values(Spells.SPELL_CATALOGUE)).filter(func(sp = null): return sp.get("element") == "Neutral")
	if JS.t(len(neutralSpells)):
		var head = document.createElement("div")
		head.style.cssText = headStyle
		head.textContent = "Neutral"
		content.appendChild(head)
		var grid = document.createElement("div")
		grid.style.cssText = gridStyle
		for spell in JS.iter(neutralSpells):
			var owned = ownedIds.has(spell.id)
			var btn = document.createElement("button")
			btn.title = JS.or_(spell.get("desc"), "")
			if owned:
				btn.style.cssText = btnBase + "background:#0a2a0a;border-color:#4aaa6a;color:#4aaa6a;"
				btn.innerHTML = JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")) + " <span style=\"font-size:.5rem;opacity:.7;\">✓ Remove</span>"
			else:
				btn.style.cssText = btnBase + "background:#0d0b09;border-color:#555;color:#aaa;"
				btn.innerHTML = JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")) + " <span style=\"font-size:.5rem;opacity:.55;\">+ Add</span>"
			var _fn7 = func():
				sandboxToggleSpell(spell.id)
				sandboxOpenSpellPicker()
			btn.onclick = _fn7
			grid.appendChild(btn)
		content.appendChild(grid)
	document.getElementById("sandbox-spell-overlay").style.display = "block"

func sandboxToggleSpell(spellId = null):
	if not JS.t(Constants.sandboxMode):
		return
	var spell = JS.idx(Spells.SPELL_CATALOGUE, spellId)
	if not JS.t(spell):
		return
	var book = State.activeBook()
	var spells = (book.get("spells") if JS.t(book) else State.player.get("spellbook"))
	var idx = JS.findIndex(spells, func(s = null): return JS.eq(s.id, spellId))
	if idx >= 0:
		# Remove it
		JS.splice(spells, idx, 1)
		if (JS.t(book) and State.player.get("activeBookIdx") == JS.indexOf(JS.or_(State.player.get("spellbooks"), []), book)):
			State.syncActiveBook()
		UI.log_("📖 Sandbox: removed " + JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")) + ".", "system")
	else:
		# Force-add (bypass slot limit in sandbox)
		var entry = JS.merge([spell, {"currentCD": 0, "dmgMult": 1.0, "rarity": "dim", "incantationLevel": 1}])
		spells.append(entry)
		if (JS.t(book) and State.player.get("activeBookIdx") == JS.indexOf(JS.or_(State.player.get("spellbooks"), []), book)):
			State.syncActiveBook()
		UI.log_("📖 Sandbox: added " + JS.s(spell.get("emoji")) + " " + JS.s(spell.get("name")) + ".", "system")
	UI.renderSpellButtons()

func sandboxOpenBookPicker():
	if not JS.t(Constants.sandboxMode):
		return
	var content = document.getElementById("sbo-content")
	if not JS.t(content):
		return
	content.innerHTML = ""
	var headStyle = "font-family:\"Cinzel\",serif;font-size:.62rem;color:#aa6aff;letter-spacing:.1em;text-transform:uppercase;margin:.7rem 0 .3rem;"
	var gridStyle = "display:flex;flex-wrap:wrap;gap:.3rem;margin-bottom:.4rem;"
	var btnBase = "border-radius:4px;padding:4px 9px;font-size:.6rem;font-family:\"Cinzel\",serif;cursor:pointer;border-width:1px;border-style:solid;text-align:left;"
	var currentIds = JSSet.new(JS.filter(JS.arr(JS.or_(State.player.get("spellbooks"), [])).map(func(b = null): return b.get("catalogueId")), JS.t))
	var rarityOrder = ["element", "generic", "legendary"]
	var rarityLabels = {"element": "Element Books", "generic": "Generic Books", "legendary": "Legendary Books"}
	var rarityColors = {"element": "#c8a060", "generic": "#80c8ff", "legendary": "#d4a0ff"}
	# Note: only 1 book active at start of sandbox
	var noteEl = document.createElement("div")
	noteEl.style.cssText = "font-size:.58rem;color:#555;margin-bottom:.6rem;"
	noteEl.textContent = "Active books in your run are highlighted. Max 3 books per run."
	content.appendChild(noteEl)
	for rarity in JS.iter(rarityOrder):
		var books = JS.arr(JS.values(Spellbooks.SPELLBOOK_CATALOGUE)).filter(func(b = null): return JS.eq(b.get("rarity"), rarity))
		if not JS.t(len(books)):
			continue
		var head = document.createElement("div")
		head.style.cssText = headStyle
		head.textContent = JS.idx(rarityLabels, rarity)
		content.appendChild(head)
		var grid = document.createElement("div")
		grid.style.cssText = gridStyle
		var col = JS.idx(rarityColors, rarity)
		for cat in JS.iter(books):
			var active = currentIds.has(cat.id)
			var btn = document.createElement("button")
			if active:
				btn.style.cssText = btnBase + ("background:#1a0a2a;border-color:" + JS.s(col) + ";color:" + JS.s(col) + ";")
				btn.innerHTML = JS.s(cat.get("emoji")) + " " + JS.s(cat.get("name")) + " <span style=\"font-size:.5rem;opacity:.7;\">✓ Remove</span>"
			else:
				btn.style.cssText = btnBase + ("background:#0d0b09;border-color:" + JS.s(col) + "55;color:" + JS.s(col) + "88;")
				btn.innerHTML = JS.s(cat.get("emoji")) + " " + JS.s(cat.get("name")) + " <span style=\"font-size:.5rem;opacity:.55;\">+ Add</span>"
			var _fn8 = func():
				sandboxToggleBook(cat.id)
				sandboxOpenBookPicker()
			btn.onclick = _fn8
			grid.appendChild(btn)
		content.appendChild(grid)
	document.getElementById("sandbox-book-overlay").style.display = "block"

func sandboxToggleBook(catalogueId = null):
	if not JS.t(Constants.sandboxMode):
		return
	var books = JS.or_(State.player.get("spellbooks"), [])
	var idx = JS.findIndex(books, func(b = null): return JS.eq(b.get("catalogueId"), catalogueId))
	if idx >= 0:
		# Remove — must keep at least 1 book
		if len(books) <= 1:
			UI.log_("📚 Sandbox: must keep at least one book.", "system")
			return
		# If removing the active book, switch to another first
		if idx == State.player.get("activeBookIdx"):
			State.player.activeBookIdx = (1 if idx == 0 else 0)
			State.syncActiveBook()
		elif idx < State.player.get("activeBookIdx"):
			State.player.activeBookIdx -= 1
		JS.splice(books, idx, 1)
		var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, catalogueId)
		UI.log_("📚 Sandbox: removed " + JS.s((JS.s(cat.get("emoji")) + " " + JS.s(cat.get("name")) if JS.t(cat) else catalogueId)) + ".", "system")
	else:
		# Add (cap at 3 in sandbox too)
		if len(books) >= 3:
			UI.log_("📚 Sandbox: max 3 books per run.", "system")
			return
		var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, catalogueId)
		if not JS.t(cat):
			return
		var newBook = State.makeBookInstance(catalogueId)
		if not JS.t(newBook):
			return
		# Copy builtins from first book so new book has Basic Attack + Armor
		var builtins = JS.arr((JS.idx(books, 0).get("spells") if JS.t(JS.idx(books, 0)) else [])).filter(func(s = null): return JS.t(s.get("isBuiltin")))
		newBook.spells = JS.arr(builtins)
		books.append(newBook)
		UI.log_("📚 Sandbox: added " + JS.s(cat.get("emoji")) + " " + JS.s(cat.get("name")) + ".", "system")
	UI.renderSpellButtons()

func sandboxSetCombatZone(element = null):
	if not JS.t(Constants.sandboxMode):
		return
	State.combat.activeZoneElement = element
	State._setZoneElement(element)
	Mp3Audio.musicPlaySmart("battle_" + JS.s(element))
	UI.log_("⚡ Sandbox: zone changed to " + JS.s(element) + ".", "system")
	# Update the element badge top-left
	var badge = document.getElementById("combat-element-badge")
	if JS.t(badge):
		var meta = JS.orf(JS.idx(Encounters.CAMP_META, element), func(): return {"icon": "✦", "color": "#aaa"})
		badge.textContent = JS.s(meta.get("icon")) + " " + JS.s(element) + " Zone"
		badge.style.color = meta.get("color")
		badge.style.borderColor = JS.s(meta.get("color")) + "44"
	# Refresh the zone bar to highlight the new active zone
	var combatZoneBar = document.getElementById("sandbox-zone-combat-bar")
	if JS.t(combatZoneBar):
		for btn in JS.iter(combatZoneBar.querySelectorAll("button")):
			var gym = JS.find(JS.or_(Encounters.GYM_ROSTER, []), func(g = null): return JS.includes(btn.textContent, g.get("element")))
			if not JS.t(gym):
				continue
			var isActive = JS.eq(element, gym.get("element"))
			btn.style.background = (JS.s(gym.get("color")) + "33" if isActive else "#111")
			btn.style.borderColor = (gym.get("color") if isActive else "#333")
			btn.style.color = (gym.get("color") if isActive else "#888")

func sandboxUnlockVeil():
	if not JS.t(Constants.sandboxMode):
		return
	var meta = Artifacts.getMeta()
	if JS.t(meta.get("darkOneDefeated")):
		return
	meta.darkOneDefeated = true
	Artifacts.saveMeta()
	LobbyMap.closeLobbyPanel()
	Veil.playVeilUnlockAnimation()
