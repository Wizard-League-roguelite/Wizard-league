# Analytics — generated from js/analytics.js by tools/js2gd.js
extends Node

# ===== analytics.js =====
# Sends anonymised run data to Supabase after every run ends.
# Outcome values: 'win' | 'loss' | 'abandoned'
# Fails silently — analytics must never crash the game.
var _ANALYTICS_URL = "https://wflupykrwlegzekxorzo.supabase.co/rest/v1/run_analytics"
var _ANALYTICS_KEY = "sb_publishable_hRMWH3gdJYE82tDKzWaWyw_2Yli8vN9"

func _boot():
	pass

func sendRunAnalytics(outcome = null):
	# Skip dev/testing contexts
	var isLocalhost = JS.isLocalBuild()
	var isFullUnlock = State.playerName == "Full Unlock"
	if ((JS.t(isLocalhost) or JS.t(Constants.sandboxMode)) or isFullUnlock):
		return
	# Collect spell IDs from every spellbook, skip internal built-ins (_basic_attack etc.)
	var spells = JS.arr(JS.flat(JS.map(JS.or_(State.player.get("spellbooks"), []), func(b = null): return JS.arr(JS.or_(b.get("spells"), [])).map(func(s = null): return s.id)))).filter(func(id = null): return (JS.t(id) and not id.begins_with("_")))
	var meta = Artifacts.getMeta()
	var payload = {
		"element": JS.or_(State.playerElement, null),
		"archetype": JS.or_(Characters.playerCharId, null),
		"outcome": outcome,
		"battles": JS.or_(State.battleNumber, 0),
		"rooms": JS.or_(State._runRoomsCompleted, 0),
		"zone": JS.or_(JS.or_(State._runZoneReached, State.playerElement), null),
		"dmg_dealt": JS.or_(State._runDmgDealt, 0),
		"dmg_taken": JS.or_(State._runDmgTaken, 0),
		"gold": JS.or_(State.player.get("gold"), 0),
		"spells": spells,
		"artifact": JS.or_(meta.get("activeArtifactId"), null),
	}
	JS.fetch(_ANALYTICS_URL, {
		"method": "POST",
		"headers": {
			"Content-Type": "application/json",
			"apikey": _ANALYTICS_KEY,
			"Authorization": "Bearer " + _ANALYTICS_KEY,
			"Prefer": "return=minimal",
		},
		"body": JS.jsonStringify(payload),
	})
