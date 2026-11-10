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

var _http: HTTPRequest = null
var _want_play := false
static var _remote_cache := {}    # src -> AudioStreamMP3 fetched over HTTP (web build)

var src:
	get: return _src
	set(v):
		_src = JS.s(v)
		_want_play = false
		if _http != null:
			_http.cancel_request()
			_http.queue_free()
			_http = null
		_player.stop()
		_paused = true
		_pending_pos = 0.0
		var path := "res://" + _src
		var stream = load(path) if ResourceLoader.exists(path) else _remote_cache.get(_src)
		if stream == null and OS.has_feature("web"):
			# the web export keeps music out of the .pck (fast first load) and streams it
			# from the audio/ folder that sits next to index.html
			_player.stream = null
			_fetch_remote(_src)
			return
		if stream == null:
			push_warning("JSAudio: missing audio file %s" % path)
		elif stream is AudioStreamMP3:
			stream.loop = _loop
		_player.stream = stream

func _fetch_remote(s: String) -> void:
	var base := str(JavaScriptBridge.eval("new URL('.', window.location.href).href", true))
	var parts := PackedStringArray()
	for seg in s.split("/"): parts.append(seg.uri_encode())
	_http = HTTPRequest.new()
	document.add_child(_http)
	var h := _http
	h.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
		if h != _http: return        # src changed while downloading
		_http = null
		h.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200 or body.size() < 128:
			push_warning("JSAudio: could not fetch %s (result %d, http %d)" % [s, result, code])
			return
		var st := AudioStreamMP3.new()
		st.data = body
		st.loop = _loop
		_remote_cache[s] = st
		_player.stream = st
		if _want_play:
			_want_play = false
			_player.play(_pending_pos))
	if h.request(base + "/".join(parts)) != OK:
		push_warning("JSAudio: could not request %s" % s)
		_http = null
		h.queue_free()

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
	get: return _paused or not (_player.playing or _want_play)

var duration: float:
	get: return _player.stream.get_length() if _player.stream != null else 0.0

func play() -> JSAudio:
	if _player.stream != null:
		_player.play(_pending_pos)
		_paused = false
	elif _http != null:
		_want_play = true          # starts as soon as the download finishes
		_paused = false
	return self

func pause() -> void:
	if _player.playing:
		_pending_pos = _player.get_playback_position()
		_player.stop()
	_want_play = false
	_paused = true

# `el.play().catch(...)` / `.then(...)`: playback never rejects here
func catch(_fn = null) -> JSAudio:
	return self

func then(fn = null, _rej = null) -> JSAudio:
	JS.invoke(fn, [])
	return self

func addEventListener(_t = null, _f = null, _o = null) -> void:
	pass
