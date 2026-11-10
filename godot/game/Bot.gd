# Bot — generated from godot/dev/bot.js by tools/js2gd.js
extends Node

var _botLog = null
var _botDone = false
var _botBattles = 0
var _botMax = 3
var _botIdx = 0
var _botSig = ""
var _botTried = 0
var _botLastScreen = ""
var _botStarted = false
var _botSteps = 0
var _BOT_AVOID = null

func _boot():
	# dev/bot.js — deterministic autoplayer. The same file runs in the browser game and (converted)
	# in the Godot port, so a seeded run can be compared line by line between the two.
	_botLog = []
	_BOT_AVOID = [
		"Quit",
		"Abandon",
		"Files",
		"Back",
		"Library",
		"Log",
		"Stats",
		"Decks",
		"Reroll",
		"Sandbox",
		"Rarity",
		"Skip",
		"Map",
	]

func _botVisible(el = null):
	return ((not (not JS.t(el)) and el.offsetWidth > 0) and not JS.t(el.get("disabled")))

func _botRecord(s = null):
	_botLog.append(s)

func botStart(seed_ = null, maxBattles = null):
	JS.seedRandom(seed_)
	_botMax = JS.or_(maxBattles, 3)
	_botLog = []
	_botDone = false
	_botBattles = 0
	_botStarted = false
	_botLastScreen = ""
	_botSteps = 0
	JS.setTimeout(_botStep, 300)

func _botStep():
	if JS.t(_botDone):
		return
	_botSteps += 1
	if _botSteps > 6000:
		_botRecord("TIMEOUT")
		_botDone = true
		return
	_botAct()
	if not JS.t(_botDone):
		JS.setTimeout(_botStep, 300)

func _botAvoided(el = null):
	var t = JS.or_(el.get("textContent"), "")
	if len(t) > 60:
		return false
	return JS.some(_BOT_AVOID, func(a = null): return JS.includes(t, a))

func _botAct():
	var scr = document.querySelector(".screen.active")
	var id = (scr.id if JS.t(scr) else "none")
	if not JS.eq(id, _botLastScreen):
		if _botLastScreen == "combat-screen":
			_botBattles += 1
			var lines = JS.arr(JS.arr(document.querySelectorAll("#battle-log .log-line"))).map(func(l = null): return l.textContent)
			_botRecord("LOG " + JS.join(lines, " | "))
			_botRecord("STATE hp=" + JS.s(State.player.get("hp")) + " gold=" + JS.s(State.player.get("gold")) + " battle=" + JS.s(State.battleNumber) + " spells=" + JS.join(JS.arr(State.player.get("spellbook")).map(func(s = null): return s.id), ","))
			if _botBattles >= _botMax:
				_botDone = true
				return
		_botRecord("SCREEN " + JS.s(id))
		_botLastScreen = id
		_botIdx = 0
		_botSig = ""
		_botTried = 0
	var cut = document.getElementById("cutscene-screen")
	if (JS.t(cut) and cut.offsetWidth > 0):
		cut.click()
		return
	if id == "between-runs-screen":
		if JS.t(_botStarted):
			_botRecord("RUN OVER")
			_botDone = true
			return
		_botStarted = true
		Main.showElementScreen()
		return
	var scope = scr
	var ovs = [
		"passive-overflow-overlay",
		"book-overflow-overlay",
		"book-dest-overlay",
		"confirm-modal",
		"passive-modal",
	]
	for o in JS.iter(ovs):
		var ov = document.getElementById(o)
		if (JS.t(ov) and ov.classList.contains("open")):
			scope = ov
	if not JS.t(scope):
		return
	if (id == "combat-screen" and JS.eq(scope, scr)):
		if (JS.t(State.combat.get("over")) or not JS.t(State.combat.get("playerTurn"))):
			return
		var cards = JS.filter(JS.arr(document.querySelectorAll("#card-hand .spell-card")), _botVisible)
		if ((JS.or_(State.combat.get("actionsLeft"), 0)) > 0 and _botTried < len(cards)):
			var before = len(State.combat.get("actionQueue"))
			JS.idx(cards, _botTried).click()
			if len(State.combat.get("actionQueue")) > before:
				_botRecord("PLAY " + JS.s(_botTried))
				_botTried = 0
			else:
				_botTried += 1
			return
		_botTried = 0
		_botRecord("END hp=" + JS.s(State.player.get("hp")) + " enemy=" + JS.join(JS.arr(State.combat.get("enemies")).map(func(e = null): return e.get("hp")), "/"))
		Combat.commitEndTurn()
		return
	var cands = JS.arr(JS.arr(scope.querySelectorAll("*"))).filter(func(el = null): return ((not (not JS.t(el.get("onclick"))) and _botVisible(el)) and not _botAvoided(el)))
	if not JS.t(len(cands)):
		return
	# walk through the clickable elements in turn until the screen changes
	var el = JS.idx(cands, JS.mod(_botIdx, len(cands)))
	_botRecord("CLICK " + JS.s(id) + " #" + JS.s(JS.mod(_botIdx, len(cands))) + "/" + JS.s(len(cands)) + " " + (JS.or_(JS.or_(el.get("className"), el.get("id")), "")))
	_botIdx += 1
	el.click()
