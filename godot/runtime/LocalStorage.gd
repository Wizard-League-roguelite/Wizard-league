# localStorage — persistent key/value store (saved to user://localstorage.json).
extends Node

const PATH := "user://localstorage.json"
var _data: Dictionary = {}
var _loaded := false
var memory_only := false       # tests: never touch the disk

func _load() -> void:
	if _loaded: return
	_loaded = true
	if memory_only or not FileAccess.file_exists(PATH): return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null: return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary: _data = parsed

func _save() -> void:
	if memory_only: return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null: f.store_string(JSON.stringify(_data))

func getItem(key):
	_load()
	return _data.get(JS.s(key))

func setItem(key, value) -> void:
	_load()
	_data[JS.s(key)] = JS.s(value)
	_save()

func removeItem(key) -> void:
	_load()
	if _data.erase(JS.s(key)): _save()

func clear() -> void:
	_data.clear()
	_save()
