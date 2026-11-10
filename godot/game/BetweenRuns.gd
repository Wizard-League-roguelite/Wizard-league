# BetweenRuns — generated from js/ui/betweenRuns.js by tools/js2gd.js
extends Node

var _lastRunPhos = 0
var BOOK_SLOT_MAX_SPELL = 3
# max extra spell slots purchasable per book
var BOOK_SLOT_MAX_PASSIVE = 2

func _boot():
	pass

# ===== betweenRuns.js =====
# ─── BETWEEN-RUNS LOBBY — last run summary, history, wizard/book/talent tabs ──
func showBetweenRuns():
	LobbyMap.stopLobbyMap()
	UI.showScreen("between-runs-screen")
	var slotData = (Main.getActiveSlotData() if JS.t(Main.getActiveSlotData) else {})
	if JS.t(slotData.get("wizardBuild")):
		Characters._wizBuild = JS.assign(JS.merge([Characters.WIZ_DEFAULTS]), [slotData.get("wizardBuild")])
	JS.setTimeout(LobbyMap.showBetweenRuns_map, 50)

func lobbyStartRun():
	LobbyMap.stopLobbyMap()
	var slotData = Main.getActiveSlotData()
	if JS.t(slotData.get("wizardBuild")):
		Characters._wizBuild = JS.assign(JS.merge([Characters.WIZ_DEFAULTS]), [slotData.get("wizardBuild")])
	Characters.playerCharId = JS.or_(JS.or_(Characters._wizBuild.get("archetype"), slotData.get("savedCharId")), "arcanist")
	var welcomeEl = document.getElementById("welcome-msg")
	if JS.t(welcomeEl):
		welcomeEl.textContent = JS.s(State.playerName) + ", choose your element"
	Main.showElementScreen()

func renderBrunLastRun():
	var el = document.getElementById("brun-last-run")
	if not JS.t(el):
		return
	var meta = Artifacts.getMeta()
	var phosEarned = JS.or_(_lastRunPhos, 0)
	# No run in progress yet — show lobby welcome
	if not JS.t(State.playerElement):
		el.innerHTML = "<div class=\"brun-run-title\" style=\"color:#c8a060;font-size:1rem;\">&#9876; Wizard&#39;s League</div><div style=\"color:#555;font-size:.7rem;margin-top:.3rem;\">Select New Run to begin your journey</div>"
		return
	var zoneStr = (" → " + JS.s(State._runZoneReached) + " Zone" if (JS.t(State._runZoneReached) and not JS.eq(State._runZoneReached, State.playerElement)) else "")
	el.innerHTML = "\n    <div class=\"brun-run-title\">" + JS.s(State.playerEmoji) + " " + JS.s(State.playerElement) + zoneStr + " — Run Ended</div>\n    <div class=\"brun-run-grid\">\n      <div class=\"brun-run-stat\"><div class=\"brun-run-label\">Rooms</div><div class=\"brun-run-val\">" + JS.s(State._runRoomsCompleted) + "</div></div>\n      <div class=\"brun-run-stat\"><div class=\"brun-run-label\">⚔ Dealt</div><div class=\"brun-run-val\" style=\"color:#e84a4a\">" + JS.s(State._runDmgDealt) + "</div></div>\n      <div class=\"brun-run-stat\"><div class=\"brun-run-label\">🛡 Taken</div><div class=\"brun-run-val\" style=\"color:#4a8aaa\">" + JS.s(State._runDmgTaken) + "</div></div>\n      <div class=\"brun-run-stat\"><div class=\"brun-run-label\">Gold</div><div class=\"brun-run-val\" style=\"color:#c8a830\">" + JS.s(State.player.get("gold")) + "g</div></div>\n      <div class=\"brun-run-stat\"><div class=\"brun-run-label\">Phos</div><div class=\"brun-run-val\" style=\"color:#a080ff\">+" + JS.s(phosEarned) + " ✦</div></div>\n    </div>\n    <div style=\"margin-top:.5rem;font-size:.65rem;color:#5a4a80;\">Total Phos: <span style=\"color:#a080ff;font-family:'Cinzel',serif;\">" + JS.s(JS.or_(meta.get("phos"), 0)) + " ✦</span></div>"

# set in showGameOver path
func switchBrunTab(tab = null, btnEl = null):
	for b in JS.iter(document.querySelectorAll(".brun-tab")):
		b.classList.remove("active")
	var btn = (btnEl if JS.t(btnEl) else document.querySelector(".brun-tab[onclick*=\"" + JS.s(tab) + "\"]"))
	if JS.t(btn):
		btn.classList.add("active")
	var content = document.getElementById("brun-tab-content")
	if not JS.t(content):
		return
	var meta = Artifacts.getMeta()
	if tab == "history":
		var history = JS.or_(meta.get("runHistory"), [])
		if not JS.t(len(history)):
			content.innerHTML = "<div class=\"brun-empty\">No runs recorded yet.</div>"
			return
		content.innerHTML = JS.join(JS.arr(history).map(func(r = null): return "\n      <div class=\"brun-hist-row\">\n        <div class=\"brun-hist-el\">" + (JS.or_(r.get("emoji"), "⚔")) + " " + (JS.or_(r.get("element"), "?")) + " <span style=\"color:#4a6a8a;font-size:.6rem;margin-left:.3rem;\">" + ("→ " + JS.s(r.get("zone")) + " Zone" if (JS.t(r.get("zone")) and not JS.eq(r.get("zone"), r.get("element"))) else "") + "</span></div>\n        <div class=\"brun-hist-stats\">\n          <span>" + JS.s(JS.or_(r.get("battles"), 0)) + " battles</span>\n          <span>" + JS.s(JS.or_(JS.or_(r.get("rooms"), r.get("battles")), 0)) + " rooms</span>\n          <span style=\"color:#c8a830\">" + JS.s(JS.or_(r.get("gold"), 0)) + "g</span>\n          <span style=\"color:#a080ff\">" + JS.s(JS.or_(r.get("phos"), 0)) + "✦</span>\n        </div>\n        <div class=\"brun-hist-details\" style=\"display:flex;gap:.8rem;font-size:.6rem;color:#555;margin-top:.2rem;\">\n          <span>⚔ " + JS.s(JS.or_(r.get("dmgDealt"), 0)) + " dealt</span>\n          <span>🛡 " + JS.s(JS.or_(r.get("dmgTaken"), 0)) + " taken</span>\n          <span>📚 " + JS.s(JS.or_(r.get("spells"), 0)) + " spells</span>\n        </div>\n        <div class=\"brun-hist-date\">" + (JS.or_(r.get("date"), "")) + "</div>\n      </div>"), "")
	elif tab == "artifacts":
		Artifacts.markArtifactsSeen()
		renderArtifactVaultTab(content, meta)
	elif tab == "talents":
		renderKnowledgeTreeTab(content, meta)
	elif tab == "books":
		renderBookUpgradesTab(content, meta)

# ── Artifact Vault Tab ────────────────────────────────────────────────────────
func _artifactCardHTML(a = null, meta = null, onEquip = null, onUnequip = null):
	var def = JS.idx(Artifacts.ARTIFACT_CATALOGUE, a.id)
	if not JS.t(def):
		return ""
	var activeId = meta.get("activeArtifactId")
	var isActive = JS.eq(a.id, activeId)
	var star = JS.or_(a.get("star"), 0)
	var sColor = JS.idx(["#888", "#c8a030", "#e8d060", "#00ccff"], min(star, 3))
	var prog = (JS.s(JS.or_(a.get("roomsUsed"), 0)) + "/25 rooms" if star < 3 else "MAX ★★★")
	var pips = JS.join(JS.arrayFrom({"length": 3}, func(_u = null, i = null): return "<span class=\"kt-level-pip" + (" filled" if i < star else "") + "\"></span>"), "")
	var stateClass = ("kt-card-equipped" if isActive else "kt-card-unlocked")
	var equipBtn = ("<button class=\"kt-action-btn kt-btn-equipped\" onclick=\"" + JS.s(onUnequip) + "\">✓ Active</button>" if isActive else "<button class=\"kt-action-btn kt-btn-equip can-afford\" onclick=\"" + JS.s(onEquip) + "\">Bring Along</button>")
	return "<div class=\"kt-card " + stateClass + "\">\n    <div class=\"kt-card-top-row\">\n      <span class=\"kt-card-tag" + (" kt-tag-equipped" if isActive else "") + "\">Artifact</span>\n      <span class=\"kt-card-phoros-tag" + (" kt-phoros-equipped" if isActive else "") + "\" style=\"color:" + JS.s(sColor) + ";font-size:.58rem;\">" + ("★".repeat(star) if star > 0 else "—") + "</span>\n    </div>\n    <div class=\"kt-card-art\">" + JS.s(def.get("emoji")) + "</div>\n    <div class=\"kt-card-name\">" + JS.s(def.get("name")) + ("<div style=\"font-size:.4rem;color:#70a030;letter-spacing:.06em;font-family:Cinzel,serif;margin-top:2px;\">✦ ACTIVE</div>" if isActive else "") + "</div>\n    <div class=\"kt-card-hint\">" + JS.s(JS.idx(def.get("desc"), star)) + "</div>\n    <div class=\"kt-card-footer\">\n      <div class=\"kt-level-section\">\n        <div class=\"kt-level-pips\">" + pips + "</div>\n        <div style=\"font-size:.42rem;color:#5a4a28;margin-top:2px;\">" + prog + "</div>\n      </div>\n      " + equipBtn + "\n    </div>\n  </div>"

func renderArtifactVaultTab(content = null, meta = null, refreshFn = null):
	var refresh = JS.or_(refreshFn, "switchBrunTab('artifacts')")
	if (not JS.t(meta.get("artifacts")) or not JS.t(len(meta.get("artifacts")))):
		content.innerHTML = "<div class=\"brun-empty\">No artifacts yet — defeat a Gym Leader to have a chance at one!</div>"
		return
	var header = "<div style=\"font-size:.6rem;color:#4a3820;text-align:center;margin-bottom:.9rem;line-height:1.5;\">\n    Bring one artifact per run — it earns stars after every 25 rooms.\n  </div>"
	var cards = JS.join(JS.arr(meta.get("artifacts")).map(func(a = null): return _artifactCardHTML(a, meta, "equipArtifact('" + JS.s(a.id) + "');" + refresh, "unequipArtifact();" + refresh)), "")
	content.innerHTML = header + ("<div class=\"kt-card-grid\">" + cards + "</div>")

# ── Between-zone artifact swap (Hades-style) ──────────────────────────────────
func showArtifactSwapOverlay(onContinue = null):
	var meta = Artifacts.getMeta()
	var artifacts = JS.or_(meta.get("artifacts"), [])
	var overlay = document.createElement("div")
	overlay.id = "artifact-swap-overlay"
	overlay.style.cssText = "position:fixed;inset:0;z-index:8500;background:rgba(0,0,0,.88);display:flex;flex-direction:column;align-items:center;justify-content:center;padding:1rem;"
	var panel = document.createElement("div")
	panel.style.cssText = "background:#0d0b07;border:2px solid #3a2810;border-radius:10px;padding:1.2rem 1.4rem;width:100%;max-width:520px;max-height:90vh;overflow-y:auto;"
	var _fn1 = func():
		var m = Artifacts.getMeta()
		var arts = JS.or_(m.get("artifacts"), [])
		var cards = JS.join(JS.arr(arts).map(func(a = null): return _artifactCardHTML(a, m, "_artSwapEquip('" + JS.s(a.id) + "')", "_artSwapEquip('" + JS.s(a.id) + "')")), "")
		var activeId = m.get("activeArtifactId")
		var activeDef = (JS.idx(Artifacts.ARTIFACT_CATALOGUE, activeId) if JS.t(activeId) else activeId)
		var activeLine = ("<div style=\"font-size:.58rem;color:#70a030;margin-top:.3rem;\">Currently carrying: " + JS.s(activeDef.get("emoji")) + " " + JS.s(activeDef.get("name")) + "</div>" if JS.t(activeDef) else "<div style=\"font-size:.58rem;color:#5a4a30;margin-top:.3rem;\">No artifact equipped.</div>")
		panel.innerHTML = "\n      <div style=\"font-family:'Cinzel',serif;font-size:.95rem;color:#c8a060;text-align:center;letter-spacing:.1em;margin-bottom:.3rem;\">Zone Complete</div>\n      <div style=\"font-size:.6rem;color:#6a5040;text-align:center;margin-bottom:.2rem;\">Swap your artifact before the next zone.</div>\n      " + activeLine + "\n      <div style=\"margin:.9rem 0;border-top:1px solid #2a1a0a;\"></div>\n      <div class=\"kt-card-grid\" id=\"art-swap-grid\">" + cards + "</div>\n      <div style=\"margin-top:1.1rem;text-align:center;\">\n        <button onclick=\"_artSwapContinue()\" style=\"background:#0f0d1a;border:2px solid #5a40aa;color:#9a70ee;padding:.55rem 2.5rem;font-family:'Cinzel',serif;font-size:.78rem;letter-spacing:.12em;text-transform:uppercase;border-radius:7px;cursor:pointer;\">Continue →</button>\n      </div>"
	var rebuild = _fn1
	var _fn2 = func(id = null):
		Artifacts.equipArtifact(id)
		rebuild.call()
	window._artSwapEquip = _fn2
	var _fn3 = func():
		overlay.remove()
		JS.del(window, "_artSwapEquip")
		JS.del(window, "_artSwapContinue")
		if JS.t(onContinue):
			onContinue.call()
		else:
			MapCanvas.showMap()
	window._artSwapContinue = _fn3
	rebuild.call()
	overlay.appendChild(panel)
	document.body.appendChild(overlay)

# Called by the post-battle-loot continue button
func pblContinue():
	var meta = Artifacts.getMeta()
	var artifacts = JS.or_(meta.get("artifacts"), [])
	if (JS.t(window.get("_lastBattleWasGym")) and len(artifacts) >= 2):
		window._lastBattleWasGym = false
		showArtifactSwapOverlay()
	else:
		window._lastBattleWasGym = false
		MapCanvas.showMap()

func _bookSlotPips(current = null, max_ = null):
	var s = ""
	for i in range(ceili(max_)):
		var f = i < current
		s += "<span style=\"display:inline-block;width:7px;height:7px;border-radius:50%;margin-right:2px;background:" + ("#a0c060" if f else "#252520") + ";border:1px solid " + ("#6a8a30" if f else "#3a3030") + ";\"></span>"
	return s

func _bookSlotRow(label = null, current = null, max_ = null, extra = null, maxExtra = null, costFn = null, bookKey = null, type_ = null, phos = null):
	var maxed = extra >= maxExtra
	var cost = (0 if maxed else costFn.call(extra))
	var canAfford = phos >= cost
	return "<div style=\"margin-top:.4rem;\">\n    <div style=\"display:flex;align-items:center;gap:.35rem;margin-bottom:.18rem;\">\n      <span style=\"font-size:.56rem;color:#5a5a6a;text-transform:uppercase;letter-spacing:.07em;\">" + JS.s(label) + ":</span>\n      " + JS.s(_bookSlotPips(current, max_)) + "\n      <span style=\"font-size:.56rem;color:#7a8a5a;\">" + JS.s(current) + "/" + JS.s(max_) + "</span>\n    </div>\n    " + ("<div style=\"font-size:.56rem;color:#4a8a4a;\">✓ Full</div>" if maxed else "<button onclick=\"purchaseBookSlotUpgrade('" + JS.s(bookKey) + "','" + JS.s(type_) + "')\" " + ("" if canAfford else "disabled") + "\n           style=\"width:100%;background:" + ("#0a140a" if canAfford else "#0a0a0a") + ";border:1px solid " + ("#4a6a20" if canAfford else "#1a1a1a") + ";\n           color:" + ("#90b050" if canAfford else "#2a3010") + ";padding:.22rem .4rem;font-family:'Cinzel',serif;font-size:.57rem;\n           letter-spacing:.07em;cursor:" + ("pointer" if canAfford else "not-allowed") + ";border-radius:4px;text-transform:uppercase;\">\n           +1 " + JS.s(label) + " — " + JS.s(cost) + " ✦</button>") + "\n  </div>"

func renderBookUpgradesTab(content = null, meta = null):
	var html = [null]
	var phos = JS.or_(meta.get("phos"), 0)
	var ownedBookIds = JS.or_(meta.get("ownedBookIds"), [])
	var bookUpgradeLevels = JS.or_(meta.get("bookUpgradeLevels"), {})
	var bookSlotUpgrades = JS.or_(meta.get("bookSlotUpgrades"), {})
	var startingBookId = JS.or_(meta.get("startingBookId"), null)
	html[0] = "<div style=\"display:flex;justify-content:space-between;align-items:center;margin-bottom:.8rem;\">\n    <div style=\"font-family:'Cinzel',serif;font-size:.78rem;color:#c8a060;\">🃏 Spell Decks</div>\n    <div style=\"font-size:.72rem;color:#a080ff;\">" + JS.s(phos) + " ✦ Phos</div>\n  </div>"
	# ── Owned catalogue books ─────────────────────────────────────────────────
	if len(ownedBookIds) == 0:
		html[0] += "<div style=\"font-size:.65rem;color:#3a3a4a;font-style:italic;padding:.5rem 0;\">No spell decks discovered yet. Beat bosses during runs to find them!</div>"
	else:
		for bookId in JS.iter(ownedBookIds):
			var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, bookId)
			if not JS.t(cat):
				continue
			var lvl = JS.or_(JS.idx(bookUpgradeLevels, bookId), 0)
			var maxLvl = 4
			var maxedEff = lvl >= maxLvl
			var upgCost = (0 if maxedEff else JS.or_(JS.idx(JS.or_(cat.get("upgradeCosts"), []), lvl), 0))
			var canAffordEff = phos >= upgCost
			var rarityColor = ("#d4a0ff" if cat.get("rarity") == "legendary" else ("#80c8ff" if cat.get("rarity") == "generic" else "#c8a060"))
			var rarityLabel = ("✦ Legendary" if cat.get("rarity") == "legendary" else ("⚡ Generic" if cat.get("rarity") == "generic" else (JS.or_(cat.get("element"), "")) + " Deck"))
			var perBook = JS.or_(JS.idx(bookSlotUpgrades, bookId), {})
			var extraSpell = JS.or_(perBook.get("spellSlots"), 0)
			var baseSpell = State.BOOK_SPELL_SLOTS_BASE + (JS.or_(cat.get("spellSlots"), 0))
			var isActive = JS.eq(bookId, startingBookId)
			var equipBtn = ("<button onclick=\"unequipStartingBook()\" style=\"background:#1a1205;border:1px solid #5a4020;color:#8a6030;font-family:'Cinzel',serif;font-size:.55rem;padding:.25rem .6rem;border-radius:3px;cursor:pointer;\">Unequip</button>" if isActive else "<button onclick=\"equipStartingBook('" + JS.s(bookId) + "')\" style=\"background:#1a1205;border:1px solid #8a6020;color:#c8a060;font-family:'Cinzel',serif;font-size:.55rem;padding:.25rem .6rem;border-radius:3px;cursor:pointer;\">Equip</button>")
			html[0] += "<div style=\"background:" + ("#1a1205" if isActive else "#0f0d0b") + ";border:1px solid " + ("#8a6020" if isActive else "#2a2020") + ";border-radius:6px;padding:.65rem .85rem;margin-bottom:.5rem;\">\n        <div style=\"display:flex;justify-content:space-between;align-items:center;margin-bottom:.15rem;\">\n          <div style=\"font-family:'Cinzel',serif;font-size:.74rem;color:" + rarityColor + ";display:flex;align-items:center;gap:.35rem;\">\n            <span style=\"display:inline-flex;width:22px;height:22px;flex-shrink:0;\">" + JS.s((JS.idx(DeckIcons.DECK_ICONS, bookId) if (true and JS.t(JS.idx(DeckIcons.DECK_ICONS, bookId))) else cat.get("emoji"))) + "</span>\n            " + JS.s(cat.get("name")) + ("<span style=\"color:#c8a060;font-size:.55rem;margin-left:.5rem;\"> ✦ STARTING DECK</span>" if isActive else "") + "\n          </div>\n          <div style=\"display:flex;align-items:center;gap:.4rem;\">\n            <div style=\"font-size:.56rem;color:#5a5a5a;\">" + rarityLabel + " · Lv " + JS.s(lvl) + "/" + JS.s(maxLvl) + "</div>\n            " + equipBtn + "\n          </div>\n        </div>\n        <div style=\"font-size:.6rem;color:#888;margin-bottom:.1rem;\">" + JS.s(cat.get("desc")) + "</div>\n        <div style=\"font-size:.57rem;color:#7a4a30;margin-bottom:.3rem;\">⚠ " + JS.s(cat.get("negative")) + "</div>\n        <div style=\"font-size:.6rem;color:#7a8a5a;padding:.3rem 0;border-top:1px solid #1a1a1a;border-bottom:1px solid #1a1a1a;margin-bottom:.3rem;\">\n          " + JS.s((JS.idx(cat.get("levelDescs"), lvl) if JS.t(cat.get("levelDescs")) else "")) + "\n        </div>\n        " + ("<div style=\"font-size:.6rem;color:#4a8a4a;margin-bottom:.3rem;\">✓ Effect Maxed</div>" if maxedEff else "<button onclick=\"purchaseCatalogueBookUpgrade('" + JS.s(bookId) + "')\" " + ("" if canAffordEff else "disabled") + "\n               style=\"width:100%;background:" + ("#0a1a0a" if canAffordEff else "#0a0a0a") + ";border:1px solid " + ("#5a7a20" if canAffordEff else "#2a2020") + ";\n               color:" + ("#a0c060" if canAffordEff else "#3a4020") + ";padding:.25rem;font-family:'Cinzel',serif;font-size:.6rem;\n               letter-spacing:.08em;cursor:" + ("pointer" if canAffordEff else "not-allowed") + ";border-radius:4px;text-transform:uppercase;margin-bottom:.3rem;\">\n               Upgrade Effect Lv" + JS.s(lvl) + "→" + JS.s(lvl + 1) + " — " + JS.s(upgCost) + " ✦</button>") + "\n        <div style=\"border-top:1px solid #1a1818;padding-top:.3rem;\">\n          " + _bookSlotRow("Spell Slots", baseSpell + extraSpell, baseSpell + BOOK_SLOT_MAX_SPELL, extraSpell, BOOK_SLOT_MAX_SPELL, _spellSlotCost, bookId, "spellSlots", phos) + "\n        </div>\n      </div>"
	# ── Default Deck ──────────────────────────────────────────────────────────
	var isDefaultActive = (not JS.t(startingBookId))
	html[0] += "<div style=\"font-size:.62rem;color:#4a4a60;margin:.5rem 0 .4rem;letter-spacing:.08em;text-transform:uppercase;\">Default Deck</div>"
	var defBook = JS.or_(JS.idx(bookSlotUpgrades, "default"), {})
	var defExtraSpell = JS.or_(defBook.get("spellSlots"), 0)
	html[0] += "<div style=\"background:" + ("#1a1205" if isDefaultActive else "#0f0d0b") + ";border:1px solid " + ("#8a6020" if isDefaultActive else "#2a2020") + ";border-radius:6px;padding:.65rem .85rem;margin-bottom:.5rem;\">\n    <div style=\"display:flex;justify-content:space-between;align-items:center;margin-bottom:.15rem;\">\n      <div style=\"font-family:'Cinzel',serif;font-size:.74rem;color:#a08060;display:flex;align-items:center;gap:.35rem;\">\n        <span style=\"display:inline-flex;width:22px;height:22px;flex-shrink:0;\">" + JS.s((DeckIcons.DECK_ICONS.get("standard") if (true and JS.t(DeckIcons.DECK_ICONS.get("standard"))) else "")) + "</span>\n        Standard" + ("<span style=\"color:#c8a060;font-size:.55rem;margin-left:.5rem;\"> ✦ STARTING DECK</span>" if isDefaultActive else "") + "\n      </div>\n      " + ("" if isDefaultActive else "<button onclick=\"unequipStartingBook()\" style=\"background:#1a1205;border:1px solid #8a6020;color:#c8a060;font-family:'Cinzel',serif;font-size:.55rem;padding:.25rem .6rem;border-radius:3px;cursor:pointer;\">Set Default</button>") + "\n    </div>\n    <div style=\"font-size:.6rem;color:#555;margin-bottom:.35rem;\">Your base deck when no catalogue deck is equipped.</div>\n    " + _bookSlotRow("Spell Slots", State.BOOK_SPELL_SLOTS_BASE + defExtraSpell, State.BOOK_SPELL_SLOTS_BASE + BOOK_SLOT_MAX_SPELL, defExtraSpell, BOOK_SLOT_MAX_SPELL, _spellSlotCost, "default", "spellSlots", phos) + "\n  </div>"
	content.innerHTML = html[0]

func purchaseCatalogueBookUpgrade(catalogueId = null):
	var cat = JS.idx(Spellbooks.SPELLBOOK_CATALOGUE, catalogueId)
	if not JS.t(cat):
		return
	var meta = Artifacts.getMeta()
	if not JS.t(meta.get("bookUpgradeLevels")):
		meta.bookUpgradeLevels = {}
	var lvl = JS.or_(JS.idx(meta.get("bookUpgradeLevels"), catalogueId), 0)
	if lvl >= 4:
		return
	var cost = JS.or_(JS.idx(JS.or_(cat.get("upgradeCosts"), []), lvl), 0)
	if (JS.or_(meta.get("phos"), 0)) < cost:
		return
	meta.phos -= cost
	meta.get("bookUpgradeLevels")[catalogueId] = lvl + 1
	Artifacts.saveMeta()
	_rerenderBookPanel()

# max extra passive slots purchasable per book
func _spellSlotCost(n = null):
	return (n + 1) * 10

# 10, 20, 30
func _passiveSlotCost(n = null):
	return (n + 1) * 12

# 12, 24
func _rerenderBookPanel():
	var freshMeta = Artifacts.getMeta()
	var c1 = document.getElementById("brun-tab-content")
	if JS.t(c1):
		renderBookUpgradesTab(c1, freshMeta)
	var c2 = document.getElementById("lobby-panel-content")
	if (JS.t(c2) and c2.style.get("display") != "none"):
		renderBookUpgradesTab(c2, freshMeta)

func equipStartingBook(id = null):
	var meta = Artifacts.getMeta()
	meta.startingBookId = id
	Artifacts.saveMeta()
	_rerenderBookPanel()

func unequipStartingBook():
	var meta = Artifacts.getMeta()
	JS.del(meta, "startingBookId")
	Artifacts.saveMeta()
	_rerenderBookPanel()

func purchaseBookSlotUpgrade(bookKey = null, type_ = null):
	var meta = Artifacts.getMeta()
	if not JS.t(meta.get("bookSlotUpgrades")):
		meta.bookSlotUpgrades = {}
	if not JS.t(JS.idx(meta.get("bookSlotUpgrades"), bookKey)):
		meta.get("bookSlotUpgrades")[bookKey] = {}
	var current = JS.or_(JS.idx(JS.idx(meta.get("bookSlotUpgrades"), bookKey), type_), 0)
	var max_ = (BOOK_SLOT_MAX_SPELL if type_ == "spellSlots" else BOOK_SLOT_MAX_PASSIVE)
	if current >= max_:
		return
	var cost = (_spellSlotCost if type_ == "spellSlots" else _passiveSlotCost).call(current)
	if (JS.or_(meta.get("phos"), 0)) < cost:
		return
	meta.phos -= cost
	JS.idx(meta.get("bookSlotUpgrades"), bookKey)[type_] = current + 1
	Artifacts.saveMeta()
	_rerenderBookPanel()

# Apply per-book slot upgrades at run start (called in initSpellbooksForRun and makeBookInstance)
func applyBookUpgrades(book = null, catalogueId = null):
	var meta = Artifacts.getMeta()
	var slotUpgs = JS.or_(meta.get("bookSlotUpgrades"), {})
	var key = JS.or_(catalogueId, "default")
	var perBook = JS.or_(JS.idx(slotUpgs, key), {})
	book.spellSlots = State.BOOK_SPELL_SLOTS_BASE + (JS.or_(perBook.get("spellSlots"), 0))
	book.passiveSlots = State.BOOK_PASSIVE_SLOTS_BASE + (JS.or_(perBook.get("passiveSlots"), 0))

func renderTalentTab(content = null, meta = null):
	var html = [null]
	var phos = JS.or_(meta.get("phos"), 0)
	var talents = JS.or_(meta.get("talents"), {})
	html[0] = "<div class=\"talent-phos-bar\">\n    <span>✦ Phos Available</span>\n    <span class=\"talent-phos-val\" id=\"talent-phos-display\">" + JS.s(phos) + "</span>\n  </div>"
	# Section picker buttons — non-sandbox hides unreleased element sections
	var allSections = JS.keys(Talents.TALENT_TREE)
	var sections = (allSections if JS.t(Constants.sandboxMode) else JS.arr(allSections).filter(func(k = null): return (k == "universal" or JS.includes(Constants.RELEASED_ELEMENTS, k))))
	html[0] += "<div class=\"talent-section-tabs\" id=\"talent-section-tabs\">"
	var _arr4 = JS.iter(sections)
	for i in range(len(_arr4)):
		var key = _arr4[i]
		html[0] += "<button class=\"talent-sec-btn" + (" active" if JS.eq(i, 0) else "") + "\" onclick=\"switchTalentSection('" + JS.s(key) + "',this)\">" + JS.s(JS.idx(Talents.TALENT_TREE, key).get("label")) + "</button>"
	html[0] += "</div>"
	html[0] += "<div id=\"talent-nodes-area\"></div>"
	content.innerHTML = html[0]
	renderTalentSection(JS.idx(sections, 0), meta)

func switchTalentSection(key = null, btnEl = null):
	for b in JS.iter(document.querySelectorAll(".talent-sec-btn")):
		b.classList.remove("active")
	if JS.t(btnEl):
		btnEl.classList.add("active")
	renderTalentSection(key, Artifacts.getMeta())

func renderTalentSection(key = null, meta = null):
	var area = document.getElementById("talent-nodes-area")
	if not JS.t(area):
		return
	var section = JS.idx(Talents.TALENT_TREE, key)
	if not JS.t(section):
		return
	var talents = JS.or_(meta.get("talents"), {})
	var phos = JS.or_(meta.get("phos"), 0)
	var _fn5 = func(node = null):
		var current = JS.or_(JS.idx(talents, node.id), 0)
		var maxed = current >= node.get("maxLevel")
		var nextLvl = current + 1
		var cost = (0 if maxed else JS.callm(node, "cost", [nextLvl]))
		var canAfford = phos >= cost
		var barPct = (current / float(node.get("maxLevel"))) * 100
		return "<div class=\"talent-node " + ("maxed" if maxed else "") + " " + ("affordable" if (not maxed and canAfford) else "") + "\">\n      <div class=\"talent-node-top\">\n        <span class=\"talent-node-emoji\">" + JS.s(node.get("emoji")) + "</span>\n        <span class=\"talent-node-name\">" + JS.s(node.get("name")) + "</span>\n        <span class=\"talent-node-level\">" + JS.s(current) + "/" + JS.s(node.get("maxLevel")) + "</span>\n      </div>\n      <div class=\"talent-node-desc\">" + JS.s(node.get("desc")) + "</div>\n      <div class=\"talent-node-bar\"><div class=\"talent-node-fill\" style=\"width:" + JS.s(barPct) + "%\"></div></div>\n      " + ("<div class=\"talent-node-maxed\">MAX</div>" if maxed else "<button class=\"talent-buy-btn " + ("can-afford" if canAfford else "") + "\"\n             onclick=\"buyTalent('" + JS.s(node.id) + "')\"\n             " + ("" if canAfford else "disabled") + ">\n             Upgrade · " + JS.s(cost) + "✦\n           </button>") + "\n    </div>"
	area.innerHTML = JS.join(JS.arr(section.get("nodes")).map(_fn5), "")

func buyTalent(nodeId = null):
	var ok = Talents.purchaseTalent(nodeId)
	if not ok:
		return
	var meta = Artifacts.getMeta()
	# refresh phos display
	var phosEl = document.getElementById("talent-phos-display")
	if JS.t(phosEl):
		phosEl.textContent = JS.or_(meta.get("phos"), 0)
	# find which section this node is in and re-render
	for key in JS.iter(JS.keys(Talents.TALENT_TREE)):
		if JS.t(JS.find(Talents.TALENT_TREE[key].get("nodes"), func(n = null): return JS.eq(n.id, nodeId))):
			renderTalentSection(key, meta)
			renderBrunLastRun()
			# update phos total display
			break

# ── Knowledge Tree ────────────────────────────────────────────────────────────
func _ktBudgetRowHTML(type_ = null, meta = null):
	var isEl = type_ == "elemental"
	var label = ("Elemental" if isEl else "General")
	var pool = (JS.flat(JS.values(KnowledgeTree.KT_ELEMENTAL_CARDS)) if isEl else KnowledgeTree.KT_GENERAL_CARDS)
	var budget = KnowledgeTree.ktGetBudget(meta, type_)
	var used = KnowledgeTree.ktPhoresUsed(meta, type_)
	var lvlKey = ("ktBudgetElementalLevel" if isEl else "ktBudgetGeneralLevel")
	var lvl = JS.or_(JS.idx(meta, lvlKey), 0)
	var maxLvl = len(KnowledgeTree.KT_BUDGET_UPGRADE_COSTS)
	var cost = (JS.idx(KnowledgeTree.KT_BUDGET_UPGRADE_COSTS, lvl) if lvl < maxLvl else 0)
	var phos = JS.or_(meta.get("phos"), 0)
	var unlockedIds = JS.or_(meta.get("ktUnlocked"), [])
	var unlockedInPool = len(JS.arr(pool).filter(func(c = null): return JS.includes(unlockedIds, c.id)))
	var reqMet = unlockedInPool >= 4
	var canUp = ((lvl < maxLvl and reqMet) and phos >= cost)
	var budgetFull = used >= budget
	var btnHTML = ("<span class=\"kt-budget-max\">Maxed</span>" if lvl >= maxLvl else "<button class=\"kt-budget-btn " + ("can-afford" if canUp else "") + "\"\n         onclick=\"ktUpgradeAndRefresh('" + JS.s(type_) + "')\" " + ("" if canUp else "disabled") + "\n         title=\"" + ("Unlock 4 " + label + " cards first" if not reqMet else "") + "\">\n         " + ("🔒 " if not reqMet else "") + "+" + JS.s(KnowledgeTree.KT_BUDGET_PER_UPGRADE) + " — " + JS.s(cost) + "✦\n       </button>")
	return "\n    <span class=\"kt-phoros-icon\">◈</span>\n    <span class=\"kt-phoros-label\">" + label + "</span>\n    <span class=\"kt-budget-used " + ("kt-budget-full" if budgetFull else "") + "\" id=\"kt-budget-" + JS.s(type_) + "\">" + JS.s(used) + " / " + JS.s(budget) + "</span>\n    " + btnHTML

func renderKnowledgeTreeTab(content = null, meta = null):
	var phos = JS.or_(meta.get("phos"), 0)
	content.innerHTML = "\n    <div class=\"kt-header\">\n      <div class=\"kt-phos-row\">\n        <span class=\"kt-phos-icon\">✦</span>\n        <span class=\"kt-phos-label\">Phos</span>\n        <span class=\"kt-phos-val\" id=\"kt-phos-display\">" + JS.s(phos) + "</span>\n      </div>\n      <div class=\"kt-budget-row\" id=\"kt-budget-row-general\">" + _ktBudgetRowHTML("general", meta) + "</div>\n      <div class=\"kt-budget-row\" id=\"kt-budget-row-elemental\">" + _ktBudgetRowHTML("elemental", meta) + "</div>\n    </div>\n    <div class=\"kt-subtabs\">\n      <button class=\"kt-subtab active\" id=\"kt-btn-general\" onclick=\"switchKtSubTab('general',this)\">General</button>\n      <button class=\"kt-subtab\" id=\"kt-btn-elemental\" onclick=\"switchKtSubTab('elemental',this)\">Elemental</button>\n    </div>\n    <div id=\"kt-area\"></div>"
	renderKtGeneral(document.getElementById("kt-area"), Artifacts.getMeta())

func switchKtSubTab(tab = null, btnEl = null):
	for b in JS.iter(document.querySelectorAll(".kt-subtab")):
		b.classList.remove("active")
	if JS.t(btnEl):
		btnEl.classList.add("active")
	var area = document.getElementById("kt-area")
	if not JS.t(area):
		return
	var meta = Artifacts.getMeta()
	if tab == "general":
		renderKtGeneral(area, meta)
	else:
		renderKtElemental(area, meta)

func _ktCardHTML(card = null, meta = null, tagLabel = null, rowLocked = null, rowComplete = null):
	var unlockedIds = JS.or_(meta.get("ktUnlocked"), [])
	var equippedIds = JS.or_(meta.get("ktEquipped"), [])
	var unlocked = JS.includes(unlockedIds, card.id)
	var equipped = JS.includes(equippedIds, card.id)
	var phos = JS.or_(meta.get("phos"), 0)
	var isGeneral = JS.some(KnowledgeTree.KT_GENERAL_CARDS, func(c = null): return JS.eq(c.id, card.id))
	var poolType = ("general" if isGeneral else "elemental")
	var budget = KnowledgeTree.ktGetBudget(meta, poolType)
	var used = KnowledgeTree.ktPhoresUsed(meta, poolType)
	var level = (KnowledgeTree.ktGetCardLevel(meta, card.id) if unlocked else 1)
	var maxLevel = JS.or_(card.get("maxLevel"), 1)
	var desc = JS.or_(JS.idx(JS.or_(card.get("levelDescs"), []), level - 1), "")
	var lockedDesc = JS.or_(JS.idx(JS.or_(card.get("levelDescs"), []), 0), "")
	var canAffordUnlock = phos >= card.get("phosCost")
	var wouldFit = (used + card.get("phorosCost")) <= budget
	var _fn6 = func():
		if ((not unlocked or maxLevel <= 1) or not JS.t(rowComplete)):
			return ""
		var pips = JS.join(JS.arrayFrom({"length": maxLevel}, func(_u = null, i = null): return "<span class=\"kt-level-pip" + (" filled" if i < level else "") + "\"></span>"), "")
		if level >= maxLevel:
			return "<div class=\"kt-level-section\"><div class=\"kt-level-pips\">" + pips + "</div><div class=\"kt-level-maxed\">Mastered</div></div>"
		var nextCost = JS.idx(card.get("levelCosts"), level)
		var canLvl = (phos >= nextCost if JS.t(nextCost) else nextCost)
		return "<div class=\"kt-level-section\">\n      <div class=\"kt-level-pips\">" + pips + "</div>\n      <button class=\"kt-levelup-btn" + (" can-afford" if JS.t(canLvl) else "") + "\"\n        onclick=\"ktLevelAndRefresh('" + JS.s(card.id) + "')\" " + ("" if JS.t(canLvl) else "disabled") + ">\n        Level Up — " + JS.s(nextCost) + "✦\n      </button>\n    </div>"
	var _levelSection = _fn6
	if not unlocked:
		if JS.t(rowLocked):
			return "<div class=\"kt-card kt-card-row-locked\">\n        <div class=\"kt-card-top-row\">\n          <span class=\"kt-card-tag\">" + (JS.or_(tagLabel, "")) + "</span>\n          <span class=\"kt-card-phoros-tag\">🔒</span>\n        </div>\n        <div class=\"kt-card-art\">" + JS.s(card.get("emoji")) + "</div>\n        <div class=\"kt-card-name\">" + JS.s(card.get("name")) + "</div>\n        <div class=\"kt-card-hint\">" + lockedDesc + "</div>\n        <div class=\"kt-card-footer\">\n          <div class=\"kt-cost-line kt-cost-row-locked\">Complete the row above first</div>\n        </div>\n      </div>"
		return "<div class=\"kt-card kt-card-locked\">\n      <div class=\"kt-card-top-row\">\n        <span class=\"kt-card-tag\">" + (JS.or_(tagLabel, "")) + "</span>\n      </div>\n      <div class=\"kt-card-art\">" + JS.s(card.get("emoji")) + "</div>\n      <div class=\"kt-card-name\">" + JS.s(card.get("name")) + "</div>\n      <div class=\"kt-card-hint\">" + lockedDesc + "</div>\n      <div class=\"kt-card-footer\">\n        <div class=\"kt-cost-line kt-cost-phos\">✦ " + JS.s(card.get("phosCost")) + " to unlock</div>\n        <button class=\"kt-action-btn kt-btn-unlock " + ("can-afford" if canAffordUnlock else "") + "\"\n          onclick=\"ktBuyAndRefresh('" + JS.s(card.id) + "')\" " + ("" if canAffordUnlock else "disabled") + ">\n          Unlock\n        </button>\n      </div>\n    </div>"
	if equipped:
		return "<div class=\"kt-card kt-card-equipped\">\n      <div class=\"kt-card-top-row\">\n        <span class=\"kt-card-tag kt-tag-equipped\">" + (JS.or_(tagLabel, "")) + "</span>\n        <span class=\"kt-card-phoros-tag kt-phoros-equipped\">◈ " + JS.s(card.get("phorosCost")) + "</span>\n      </div>\n      <div class=\"kt-card-art\">" + JS.s(card.get("emoji")) + "</div>\n      <div class=\"kt-card-name\">" + JS.s(card.get("name")) + "</div>\n      <div class=\"kt-card-hint\">" + desc + "</div>\n      <div class=\"kt-card-footer\">\n        " + JS.s(_levelSection.call()) + "\n        <button class=\"kt-action-btn kt-btn-equipped\" onclick=\"ktToggleAndRefresh('" + JS.s(card.id) + "')\">✓ Packed</button>\n      </div>\n    </div>"
	return "<div class=\"kt-card kt-card-unlocked\">\n    <div class=\"kt-card-top-row\">\n      <span class=\"kt-card-tag\">" + (JS.or_(tagLabel, "")) + "</span>\n      <span class=\"kt-card-phoros-tag\">◈ " + JS.s(card.get("phorosCost")) + "</span>\n    </div>\n    <div class=\"kt-card-art\">" + JS.s(card.get("emoji")) + "</div>\n    <div class=\"kt-card-name\">" + JS.s(card.get("name")) + "</div>\n    <div class=\"kt-card-hint\">" + desc + "</div>\n    <div class=\"kt-card-footer\">\n      " + JS.s(_levelSection.call()) + "\n      <button class=\"kt-action-btn " + ("kt-btn-equip can-afford" if wouldFit else "kt-btn-equip") + "\"\n        onclick=\"ktToggleAndRefresh('" + JS.s(card.id) + "')\" " + ("" if wouldFit else "disabled") + ">\n        " + ("Bring Along" if wouldFit else "No Room") + "\n      </button>\n    </div>\n  </div>"

func _ktRowLocked(cards = null, idx = null, unlockedIds = null):
	var row = floori(idx / 4.0)
	if row == 0:
		return false
	var prevStart = (row - 1) * 4
	var prevEnd = row * 4
	var i = prevStart
	while (i < prevEnd and i < len(cards)):
		if not JS.includes(unlockedIds, cards[i].id):
			return true
		i += 1
	return false

func renderKtGeneral(area = null, meta = null):
	var unlockedIds = JS.or_(meta.get("ktUnlocked"), [])
	var _fn7 = func(c = null, i = null):
		var rowStart = floori(i / 4.0) * 4
		var rowComplete = JS.every(JS.slice(KnowledgeTree.KT_GENERAL_CARDS, rowStart, rowStart + 4), func(rc = null): return JS.includes(unlockedIds, rc.id))
		return _ktCardHTML(c, meta, "General", _ktRowLocked(KnowledgeTree.KT_GENERAL_CARDS, i, unlockedIds), rowComplete)
	var html = "<div class=\"kt-card-grid\">" + JS.join(JS.map(KnowledgeTree.KT_GENERAL_CARDS, _fn7), "") + "</div>"
	area.innerHTML = html

func renderKtElemental(area = null, meta = null):
	var elements = (JS.keys(KnowledgeTree.KT_ELEMENTAL_CARDS) if (true and JS.t(Constants.sandboxMode)) else JS.arr(JS.keys(KnowledgeTree.KT_ELEMENTAL_CARDS)).filter(func(el = null): return JS.includes(Constants.RELEASED_ELEMENTS, el)))
	var elementLabels = {"Fire": "🔥 Fire", "Lightning": "⚡ Lightning", "Nature": "🌿 Nature", "Air": "🌀 Air"}
	var elementTags = {"Fire": "Fire", "Lightning": "Lightning", "Nature": "Nature", "Air": "Air"}
	var html = ""
	for el in JS.iter(elements):
		var cards = JS.or_(JS.idx(KnowledgeTree.KT_ELEMENTAL_CARDS, el), [])
		html += "<div class=\"kt-element-section\">\n      <div class=\"kt-element-label\">" + JS.s(JS.or_(JS.idx(elementLabels, el), el)) + "</div>\n      <div class=\"kt-card-grid\">" + JS.join(JS.arr(cards).map(func(c = null): return _ktCardHTML(c, meta, JS.or_(JS.idx(elementTags, el), el), false, JS.every(cards, func(rc = null): return JS.includes(JS.or_(meta.get("ktUnlocked"), []), rc.id)))), "") + "</div>\n    </div>"
	area.innerHTML = html

func _ktRefresh():
	var meta = Artifacts.getMeta()
	var phosEl = document.getElementById("kt-phos-display")
	if JS.t(phosEl):
		phosEl.textContent = JS.or_(meta.get("phos"), 0)
	# rebuild both budget rows (updates button lock state, values, affordability)
	var rowG = document.getElementById("kt-budget-row-general")
	if JS.t(rowG):
		rowG.innerHTML = _ktBudgetRowHTML("general", meta)
	var rowE = document.getElementById("kt-budget-row-elemental")
	if JS.t(rowE):
		rowE.innerHTML = _ktBudgetRowHTML("elemental", meta)
	# re-render active sub-tab
	var area = document.getElementById("kt-area")
	if not JS.t(area):
		return
	var activeBtn = document.querySelector(".kt-subtab.active")
	var tab = ("elemental" if (JS.t(activeBtn) and activeBtn.get("id") == "kt-btn-elemental") else "general")
	if tab == "general":
		renderKtGeneral(area, meta)
	else:
		renderKtElemental(area, meta)
	renderBrunLastRun()

func ktBuyAndRefresh(cardId = null):
	KnowledgeTree.ktUnlockCard(cardId)
	_ktRefresh()

func ktToggleAndRefresh(cardId = null):
	KnowledgeTree.ktEquipCard(cardId)
	_ktRefresh()

func ktLevelAndRefresh(cardId = null):
	KnowledgeTree.ktUpgradeCard(cardId)
	_ktRefresh()

func ktUpgradeAndRefresh(type_ = null):
	KnowledgeTree.ktUpgradeBudget(type_)
	var content = JS.orf(document.getElementById("lobby-panel-content"), func(): return document.getElementById("brun-tab-content"))
	if JS.t(content):
		renderKnowledgeTreeTab(content, Artifacts.getMeta())

# ── Incantation Rarity Preview Overlay ────────────────────────────────────────
func showIncantationPreview():
	var html = [null]
	var existing = document.getElementById("inc-preview-overlay")
	if JS.t(existing):
		existing.remove()
		return
	var overlay = document.createElement("div")
	overlay.id = "inc-preview-overlay"
	overlay.style.cssText = "position:fixed;inset:0;z-index:9000;background:rgba(0,0,0,.78);display:flex;align-items:center;justify-content:center;cursor:pointer;padding:1rem;"
	var _fn8 = func(e = null):
		if JS.eq(e.target, overlay):
			overlay.remove()
	overlay.onclick = _fn8
	var panel = document.createElement("div")
	panel.style.cssText = "background:#0e0a04;border:2px solid #3a2410;border-radius:8px;padding:1.2rem 1.4rem;width:100%;max-width:460px;cursor:default;"
	panel.onclick = func(e = null): return e.stopPropagation()
	var tiers = [
		{
			"label": "Dim",
			"stars": 1,
			"bg": "rgba(0,0,0,.98)",
			"border": "#2a1a08",
			"tagColor": "#887766",
			"nameColor": "#e8e8e8",
			"subColor": "rgba(220,220,220,.7)",
		},
		{
			"label": "Kindled",
			"stars": 2,
			"bg": "rgba(0,0,0,.98)",
			"border": "#c06010",
			"tagColor": "#c06010",
			"nameColor": "#ffffff",
			"subColor": "rgba(255,255,255,.75)",
		},
		{
			"label": "Blazing",
			"stars": 3,
			"bg": "rgba(0,0,0,.98)",
			"border": "#bb1200",
			"tagColor": "#bb1200",
			"nameColor": "#ffffff",
			"subColor": "rgba(255,255,255,.75)",
		},
		{
			"label": "Radiant",
			"stars": 4,
			"bg": "linear-gradient(to right, rgba(0,0,0,.98) 50%, #f0e8c0 100%)",
			"border": "#d4aa20",
			"tagColor": "#8a6a10",
			"nameColor": "#7a5208",
			"subColor": "#9a7820",
			"leftNameColor": "#ffffff",
			"leftSubColor": "rgba(255,255,255,.75)",
		},
		{
			"label": "Merged",
			"stars": 5,
			"bg": "linear-gradient(to right, rgba(0,0,0,.98) 50%, rgba(0,80,75,1) 100%)",
			"border": "#00d4c8",
			"tagColor": "#00d4c8",
			"nameColor": "#ffffff",
			"subColor": "rgba(255,255,255,.75)",
			"note": "(Coming Soon)",
		},
	]
	# Inject animation keyframes once
	if not JS.t(document.getElementById("inc-preview-styles")):
		var s = document.createElement("style")
		s.id = "inc-preview-styles"
		s.textContent = "\n      @keyframes incStarPulse {\n        0%,100% { opacity:1; filter:brightness(1) drop-shadow(0 0 2px currentColor); transform:scale(1); }\n        50%      { opacity:.5; filter:brightness(2.5) drop-shadow(0 0 6px currentColor); transform:scale(1.4); }\n      }\n      @keyframes incShimmer {\n        0%   { left:-80%; }\n        100% { left:160%; }\n      }\n      @keyframes incFireGlow {\n        0%,100% { opacity:.7; transform:scaleY(1);   filter:blur(2px); }\n        33%     { opacity:1;   transform:scaleY(1.15); filter:blur(1px); }\n        66%     { opacity:.6;  transform:scaleY(.9);   filter:blur(3px); }\n      }\n      @keyframes incBorderPulse {\n        0%,100% { opacity:1; }\n        50%     { opacity:.6; }\n      }\n    "
		document.head.appendChild(s)
	var _fn9 = func(t = null):
		var isGradient = JS.includes(t.get("bg"), "gradient")
		var isFire = (t.get("label") == "Kindled" or t.get("label") == "Blazing")
		var borderGrad = "linear-gradient(to right, #1a1a1a 50%, " + JS.s(t.get("border")) + " 100%)"
		# Staggered sparkling stars
		var starSpans = JS.join(JS.map(JS.arr("✦".repeat(t.get("stars"))), func(s = null, i = null): return "<span style=\"display:inline-block;animation:incStarPulse " + JS.s(5.5 + (i * 0.7)) + "s ease-in-out " + JS.s(i * 1.0) + "s infinite;\">" + JS.s(s) + "</span>"), "")
		# Shimmer overlay for gradient cards
		var shimmer = ("<div style=\"position:absolute;top:0;left:-80%;width:45%;height:100%;pointer-events:none;z-index:2;\n           background:linear-gradient(to right,transparent,rgba(255,255,255,.09),transparent);\n           animation:incShimmer 3.5s linear infinite;\"></div>" if isGradient else "")
		# Fire flicker overlay for Kindled / Blazing
		var fireColor = ("rgba(255,120,0,.10)" if t.get("label") == "Kindled" else "rgba(255,30,0,.22)")
		var fire = ("<div style=\"position:absolute;bottom:0;right:0;width:55%;height:100%;pointer-events:none;z-index:2;\n           background:linear-gradient(to left," + fireColor + ",transparent);\n           animation:incFireGlow 1.6s ease-in-out infinite;\"></div>" if isFire else "")
		# Border pulse for fire cards
		var wrapperAnim = ("animation:incBorderPulse 1.8s ease-in-out infinite;" if isFire else "")
		return "<div style=\"padding:3px;background:" + borderGrad + ";border-radius:7px;margin-bottom:.5rem;" + wrapperAnim + "\">\n      <div style=\"display:flex;align-items:stretch;border-radius:5px;overflow:hidden;background:" + JS.s(t.get("bg")) + ";position:relative;\">\n        " + shimmer + fire + "\n        <div style=\"flex:1;padding:.4rem .55rem;position:relative;z-index:3;\">\n          <div style=\"font-size:.72rem;font-family:'Cinzel',serif;color:" + JS.s(JS.or_(t.get("leftNameColor"), t.get("nameColor"))) + ";margin-bottom:.2rem;\">🔮 Example Spell" + (" <span style=\"font-size:.45rem;opacity:.65;\">" + JS.s(t.get("note")) + "</span>" if JS.t(t.get("note")) else "") + "</div>\n          <div style=\"font-size:.48rem;color:" + JS.s(JS.or_(t.get("leftSubColor"), t.get("subColor"))) + ";\">" + ("Two spells fused into one." if JS.t(t.get("note")) else "Deals damage and applies a status effect.") + "</div>\n        </div>\n        <div style=\"display:flex;flex-direction:column;align-items:center;justify-content:center;min-width:58px;padding:3px 8px;gap:1px;position:relative;z-index:3;\">\n          <div style=\"font-size:.45rem;font-family:'Cinzel',serif;color:" + JS.s(t.get("tagColor")) + ";letter-spacing:.1em;\">" + starSpans + "</div>\n          <div style=\"font-size:.72rem;font-family:'Cinzel',serif;color:" + JS.s(t.get("nameColor")) + ";font-weight:700;letter-spacing:.08em;text-transform:uppercase;line-height:1.1;\">" + JS.s(t.get("label")) + "</div>\n        </div>\n      </div>\n    </div>"
	var cardHTML = _fn9
	html[0] = "<div style=\"font-family:'Cinzel',serif;font-size:.9rem;letter-spacing:.1em;color:#c8a060;text-align:center;margin-bottom:.8rem;border-bottom:1px solid #2a1a08;padding-bottom:.6rem;\">\n    📜 Spell Rarity Tiers\n  </div>"
	for t in JS.iter(tiers):
		html[0] += JS.s(cardHTML.call(t))
	html[0] += "<div style=\"font-size:.48rem;color:#554433;text-align:center;margin-top:.4rem;font-family:'Cinzel',serif;letter-spacing:.06em;\">Click outside to close</div>"
	panel.innerHTML = html[0]
	overlay.appendChild(panel)
	document.body.appendChild(overlay)
