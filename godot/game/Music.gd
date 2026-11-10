# Music — generated from js/audio/music.js by tools/js2gd.js
extends Node

# ===== music.js (stubs — synth engine removed) =====
var _musicEnabled = true
var _volumeLevel = 0.5
var _mutedByBtn = false
var _audioStarted = false
var _tryResumeAudio = null

func _boot():
	# true after first gesture fires
	_tryResumeAudio = _tryResumeAudio_2
	# Restore saved volume on page load
	var _fn2 = func():
		var saved = JS.jsonParse(localStorage.getItem("wl_vol"))
		if JS.t(saved):
			_volumeLevel = JS.nn(saved.get("level"), 0.5)
			_mutedByBtn = JS.nn(saved.get("muted"), false)
			_musicEnabled = (not JS.t(_mutedByBtn) and _volumeLevel > 0)
			var slider = document.getElementById("vol-slider")
			if JS.t(slider):
				slider.value = JS.round(_volumeLevel * 100)
			_updateVolIcon()
	_fn2.call()

func musicPlay(key = null):
	pass

func musicStop():
	pass

# Get the live MP3 element safely (declared later in mp3audio.js)
func _getVol():
	return (Mp3Audio._mp3El if (true and JS.t(Mp3Audio._mp3El)) else null)

func _saveVolPrefs():
	localStorage.setItem("wl_vol", JS.jsonStringify({"level": _volumeLevel, "muted": _mutedByBtn}))

func volumeSet(val = null):
	var v = max(0, min(100, JS.num(val))) / 100.0
	_volumeLevel = v
	_mutedByBtn = v == 0
	_musicEnabled = v > 0
	var el = _getVol()
	if JS.t(el):
		el.volume = v
	_updateVolIcon()
	_saveVolPrefs()

func volumeToggleMute():
	# If audio hasn't started yet, let _firstGesture handle it — don't mute
	if not JS.t(_audioStarted):
		return
	if (JS.t(_mutedByBtn) or not JS.t(_musicEnabled)):
		# Unmute
		_mutedByBtn = false
		_musicEnabled = true
		var v = max(0.1, _volumeLevel)
		_volumeLevel = v
		var el = _getVol()
		if JS.t(el):
			el.volume = v
			if JS.t(el.get("paused")):
				var _fn1 = func():
					pass
				el.play().catch(_fn1)
		var slider = document.getElementById("vol-slider")
		if JS.t(slider):
			slider.value = JS.round(v * 100)
	else:
		# Mute
		_mutedByBtn = true
		_musicEnabled = false
		var el = _getVol()
		if JS.t(el):
			el.volume = 0
	_updateVolIcon()
	_saveVolPrefs()

func _updateVolIcon():
	var icon = document.getElementById("vol-icon")
	if not JS.t(icon):
		return
	var muted = JS.or_(JS.or_(_mutedByBtn, (not JS.t(_musicEnabled))), JS.eq(_volumeLevel, 0))
	icon.textContent = ("🔇" if JS.t(muted) else ("🔉" if _volumeLevel < 0.4 else "🔊"))

func musicToggle():
	volumeToggleMute()
	return _musicEnabled

func _tryResumeAudio_2():
	pass
