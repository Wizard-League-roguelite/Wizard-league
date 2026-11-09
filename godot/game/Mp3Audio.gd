# Mp3Audio — generated from js/audio/mp3audio.js by tools/js2gd.js
extends Node

var _MP3_KEYS = null
var _MP3_PATHS = null
# ── State ─────────────────────────────────────────────────────────────────────
var _mp3El = null
var _mp3Key = null
var _mp3Paused = null
var _mp3FadeRAF = null
var _MP3_FADE_MS = 450
var _MP3_MAX_VOL = 0.82
# ── Core router ───────────────────────────────────────────────────────────────
var _smartCurrentKey = null
# ── Start audio on first user interaction of any kind ──────────────────────────
# Browsers block autoplay until a gesture; scroll/move/key all count.
var _unlocked = false
var _events = null

func _boot():
	# ===== mp3audio.js =====
	# ─── MP3 AUDIO SYSTEM ────────────────────────────────────────────────────────
	# Loads MP3s from ./audio/ folder (relative to game.html)
	# Synth keys fall through to music.js musicPlay()
	# 
	# Public API:
	# musicPlaySmart(key)  — routes to MP3 or synth
	# musicStopAll()       — stops both systems
	_MP3_KEYS = JSSet.new([
		"menu",
		"map",
		"battle_Fire",
		"battle_Lightning",
		"battle_Plasma",
		"battle_Air",
		"battle_Nature",
		"battle_Ice",
		"battle_Water",
	])
	_MP3_PATHS = {
		"menu": "audio/menu.mp3",
		"map": "audio/map.mp3",
		"battle_Fire": "audio/fire.mp3",
		"battle_Lightning": "audio/lightning.mp3",
		"battle_Plasma": "audio/Wizard League Plasma Theme .mp3",
		"battle_Air": "audio/Wizard League Air Theme .mp3",
		"battle_Nature": "audio/Wizard League Nature Theme .mp3",
		"battle_Ice": "audio/Wizard League Ice Theme .mp3",
		"battle_Water": "audio/Wizard League Water Theme.mp3",
	}
	_mp3Paused = {}
	# ── Override _tryResumeAudio stub (music.js loads first, can't reference _mp3El yet) ──
	var _fn7 = func():
		if (not JS.t(_mp3El) or not JS.t(_smartCurrentKey)):
			return
		if JS.t(_mp3El.get("paused")):
			_mp3Play(_smartCurrentKey)
	Music._tryResumeAudio = _fn7
	_events = ["click", "keydown", "pointerdown", "touchstart", "scroll", "mousemove"]
	for ev in JS.iter(_events):
		document.addEventListener(ev, _onInteraction, {"capture": true, "passive": true})

func _getAudioEl():
	if not JS.t(_mp3El):
		_mp3El = JSAudio.new()
		_mp3El.loop = true
		_mp3El.volume = 0
		_mp3El.muted = false
	return _mp3El

# ── Fade helpers ──────────────────────────────────────────────────────────────
func _mp3FadeIn(el = null, onDone = null):
	var tick = [null]
	if JS.t(_mp3FadeRAF):
		JS.cancelAnimationFrame(_mp3FadeRAF)
	var start = JS.now()
	var from = el.volume
	var _fn1 = func(now = null):
		var t = min((now - start) / float(_MP3_FADE_MS), 1)
		var _targetVol = (Music._volumeLevel if JS.t(Music._musicEnabled) else 0)
		el.volume = max(0, min(1, from + ((_targetVol - from) * t)))
		if t < 1:
			_mp3FadeRAF = JS.requestAnimationFrame(tick[0])
		else:
			el.volume = (Music._volumeLevel if JS.t(Music._musicEnabled) else 0)
			_mp3FadeRAF = null
			if JS.t(onDone):
				onDone.call()
	tick[0] = _fn1
	_mp3FadeRAF = JS.requestAnimationFrame(tick[0])

func _mp3FadeOut(el = null, onDone = null):
	var tick = [null]
	if JS.t(_mp3FadeRAF):
		JS.cancelAnimationFrame(_mp3FadeRAF)
	var start = JS.now()
	var from = el.volume
	var _fn2 = func(now = null):
		var t = min((now - start) / float(_MP3_FADE_MS), 1)
		el.volume = max(0, min(1, from * (1 - t)))
		if t < 1:
			_mp3FadeRAF = JS.requestAnimationFrame(tick[0])
		else:
			el.volume = 0
			_mp3FadeRAF = null
			if JS.t(onDone):
				onDone.call()
	tick[0] = _fn2
	_mp3FadeRAF = JS.requestAnimationFrame(tick[0])

# ── Play an MP3 key (resume if previously paused) ─────────────────────────────
func _mp3Play(key = null):
	var el = _getAudioEl()
	el.muted = false
	if not JS.eq(_mp3Key, key):
		el.src = JS.idx(_MP3_PATHS, key)
		el.currentTime = JS.or_(JS.idx(_mp3Paused, key), 0)
		_mp3Key = key
	else:
		el.currentTime = JS.or_(JS.idx(_mp3Paused, key), el.get("currentTime"))
	el.volume = 0
	var _fn3 = func(err = null):
		JS.console_warn(["[mp3audio] play() blocked:", err.message, "— path:", JS.idx(_MP3_PATHS, key)])
	el.play().catch(_fn3)
	_mp3FadeIn(el)

# ── Pause an MP3 (saves position) ─────────────────────────────────────────────
func _mp3Pause(key = null):
	if not JS.t(_mp3El):
		return
	_mp3Paused[key] = _mp3El.currentTime
	var _fn4 = func():
		_mp3El.pause()
	_mp3FadeOut(_mp3El, _fn4)

func musicPlaySmart(key = null):
	if JS.eq(_smartCurrentKey, key):
		return
	var prevKey = _smartCurrentKey
	_smartCurrentKey = key
	var nextIsMP3 = _MP3_KEYS.has(key)
	var prevIsMP3 = (_MP3_KEYS.has(prevKey) if JS.t(prevKey) else prevKey)
	var prevIsSynth = ((not JS.t(prevIsMP3)) if JS.t(prevKey) else prevKey)
	# MP3 → MP3
	if (JS.t(prevIsMP3) and nextIsMP3):
		var _fn5 = func():
			_mp3Paused[prevKey] = 0
			_mp3Play(key)
		_mp3FadeOut(_getAudioEl(), _fn5)
		return
	# Synth → MP3
	if (JS.t(prevIsSynth) and nextIsMP3):
		Music.musicStop()
		JS.setTimeout(func(): return _mp3Play(key), _MP3_FADE_MS + 80)
		return
	# MP3 → Synth
	if (JS.t(prevIsMP3) and not nextIsMP3):
		_mp3Pause(prevKey)
		JS.setTimeout(func(): return Music.musicPlay(key), _MP3_FADE_MS + 80)
		return
	# Synth → Synth
	if not nextIsMP3:
		Music.musicPlay(key)
		return
	# Cold start
	if nextIsMP3:
		_mp3Play(key)
	else:
		Music.musicPlay(key)

func musicStopAll():
	Music.musicStop()
	if JS.t(_mp3El):
		var _fn6 = func():
			_mp3El.pause()
		_mp3FadeOut(_mp3El, _fn6)
	_smartCurrentKey = null

func _onInteraction():
	if JS.t(_unlocked):
		return
	_unlocked = true
	Music._tryResumeAudio.call()
	for ev in JS.iter(_events):
		document.removeEventListener(ev, _onInteraction, true)
