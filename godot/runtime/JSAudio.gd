# JSAudio — HTMLAudioElement look-alike backed by an AudioStreamPlayer.
class_name JSAudio
extends RefCounted

var _player: AudioStreamPlayer
var _src := ""
var _volume := 1.0
var _loop := false
var _pending_pos := 0.0
var _paused := true
var muted := false:
	set(v):
		muted = JS.t(v)
		_apply_volume()
var preload_ := "auto"

func _init(src_ = null) -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	document.add_child(_player)
	if src_ != null: src = src_

var src:
	get: return _src
	set(v):
		_src = JS.s(v)
		var path := "res://" + _src
		var stream = load(path) if ResourceLoader.exists(path) else null
		if stream == null:
			push_warning("JSAudio: missing audio file %s" % path)
		elif stream is AudioStreamMP3:
			stream.loop = _loop
		_player.stop()
		_player.stream = stream
		_paused = true
		_pending_pos = 0.0

var loop:
	get: return _loop
	set(v):
		_loop = JS.t(v)
		if _player.stream is AudioStreamMP3: _player.stream.loop = _loop

var volume:
	get: return _volume
	set(v):
		_volume = clampf(float(JS.num(v)), 0.0, 1.0)
		_apply_volume()

func _apply_volume() -> void:
	var v := 0.0 if muted else _volume
	_player.volume_db = -80.0 if v <= 0.0005 else linear_to_db(v)

var currentTime:
	get: return _player.get_playback_position() if _player.playing else _pending_pos
	set(v):
		_pending_pos = maxf(0.0, float(JS.num(v)))
		if _player.playing: _player.seek(_pending_pos)

var paused: bool:
	get: return _paused or not _player.playing

var duration: float:
	get: return _player.stream.get_length() if _player.stream != null else 0.0

func play() -> JSAudio:
	if _player.stream != null:
		_player.play(_pending_pos)
		_paused = false
	return self

func pause() -> void:
	if _player.playing:
		_pending_pos = _player.get_playback_position()
		_player.stop()
	_paused = true

# `el.play().catch(...)` / `.then(...)`: playback never rejects here
func catch(_fn = null) -> JSAudio:
	return self

func then(fn = null, _rej = null) -> JSAudio:
	JS.invoke(fn, [])
	return self

func addEventListener(_t = null, _f = null, _o = null) -> void:
	pass
