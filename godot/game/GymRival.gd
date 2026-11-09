# GymRival — generated from js/ui/gymRival.js by tools/js2gd.js
extends Node


func _boot():
	pass

# ===== gymRival.js =====
# ─── GYM + RIVAL intro screens and battle entry ───────────────────────────────
func rivalHP():
	return JS.callm(Encounters.RIVAL, "baseHP", [State.currentGymIdx])

func rivalDmg():
	return JS.callm(Encounters.RIVAL, "baseDmg", [State.currentGymIdx])

func showRivalIntro():
	var hp = rivalHP()
	var dmg = rivalDmg()
	var dialogue = JS.idx(Encounters.RIVAL.dialogue, min(State.currentGymIdx, len(Encounters.RIVAL.dialogue) - 1))
	document.getElementById("rival-title").textContent = Encounters.RIVAL.emoji + " Rival " + Encounters.RIVAL.name
	document.getElementById("rival-dialogue").textContent = "\"" + JS.s(dialogue) + "\""
	document.getElementById("rival-hp-display").textContent = hp
	document.getElementById("rival-dmg-display").textContent = dmg
	document.getElementById("rival-element-display").textContent = State.playerElement
	UI.showScreen("rival-screen")

func startRivalBattle():
	var hp = rivalHP()
	var dmg = rivalDmg()
	var rivEnc = {
		"name": Encounters.RIVAL.name,
		"emoji": Encounters.RIVAL.emoji,
		"element": State.playerElement,
		"color": "#9a6aee",
		"difficulty": "rival",
		"diffClass": "diff-hard",
		"enemyMaxHP": hp,
		"enemyDmg": dmg,
		"gold": JS.round(30 + (State.currentGymIdx * 15)),
		"type": "wizard",
		"isRival": true,
	}
	BattleLoad.loadBattle(rivEnc)

func showGymIntro(forced = null):
	var gym = Encounters.currentGymDef()
	if not JS.t(gym):
		return
	var bHP = Helpers.gymBossDisplayHP()
	document.getElementById("gym-title").textContent = "🏛 Gym " + JS.s(State.currentGymIdx + 1) + " — " + JS.s(gym.name)
	document.getElementById("gym-boss-hp-display").textContent = bHP
	document.getElementById("gym-boss-dmg-display").textContent = JS.s(Helpers.gymBossDisplayDmg()) + " → " + JS.s(gym.phase2Dmg) + " (phase 2)"
	document.getElementById("gym-subtitle").textContent = gym.signature
	if JS.t(forced):
		document.getElementById("gym-warn-txt").textContent = ("Skipped " + JS.s(State.gymSkips) + "× — +" + JS.s(State.gymSkips * Constants.GYM_SKIP_BONUS) + " HP on boss." if State.gymSkips > 0 else "Zone battle " + JS.s(State.zoneBattleCount) + " — no more delays.")
		document.getElementById("gym-skip-btn").style.display = "none"
		document.getElementById("gym-challenge-btn").className = "btn-gym-forced"
		document.getElementById("gym-challenge-btn").textContent = "No Choice — Fight Now"
	else:
		var battlesLeft = Constants.GYM_ZONE_FORCE - State.zoneBattleCount
		document.getElementById("gym-warn-txt").textContent = ("Skipped " + JS.s(State.gymSkips) + "× — boss has +" + JS.s(State.gymSkips * Constants.GYM_SKIP_BONUS) + " HP." if State.gymSkips > 0 else "")
		document.getElementById("gym-skip-btn").style.display = "block"
		document.getElementById("gym-challenge-btn").className = "btn-gym"
		document.getElementById("gym-challenge-btn").textContent = "Challenge " + JS.s(gym.name)
		document.getElementById("gym-subtitle").textContent += "  (" + JS.s(battlesLeft) + " battle" + ("" if battlesLeft == 1 else "s") + " until forced)"
	UI.showScreen("gym-screen")

func startGymBattle():
	var gym = Encounters.currentGymDef()
	if not JS.t(gym):
		return
	BattleLoad.loadBattle({
		"name": gym.name,
		"emoji": gym.emoji,
		"element": gym.element,
		"color": gym.color,
		"difficulty": "gym",
		"diffClass": "diff-hard",
		"enemyMaxHP": Helpers.gymBossHP(),
		"enemyDmg": gym.baseDmg,
		"gold": gym.gold,
		"type": "wizard",
		"isGym": true,
		"signature": gym.signature,
		"gymPassive": gym.passive,
		"gymPhase2Passive": gym.phase2Passive,
		"gymEntryEffect": gym.entryEffect,
		"gymHitCounter": 0,
		"gymPhase2": false,
		"gymPhase2Dmg": gym.phase2Dmg,
		"gymChargeInterval": gym.chargeInterval,
	})

func skipGym():
	State.gymSkips += 1
	State._pendingNodeId = -1
	MapCanvas.showMap()
