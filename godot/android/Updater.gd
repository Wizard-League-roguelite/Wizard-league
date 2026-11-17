# Updater — Android build only. Once per launch, asks GitHub for the newest release and, if it is
# newer than this install, offers to update. Releases come from .github/workflows/godot-android.yml:
# each is tagged android-<build> and carries one APK. "Update" opens the APK link in the browser;
# Android then downloads it and shows its own install screen.
extends Node

const LATEST := "https://api.github.com/repos/Wizard-League-roguelite/Wizard-league/releases/latest"

var _http: HTTPRequest

func _ready() -> void:
	if installed_build() <= 0: return       # local exports are not on the release track
	_http = HTTPRequest.new()
	_http.timeout = 15.0
	add_child(_http)
	_http.request_completed.connect(_on_latest)
	_http.request(LATEST, PackedStringArray(["Accept: application/vnd.github+json", "User-Agent: WizardLeague-Android"]))

# build number stamped into Version.gd by tools/build_android.sh
func installed_build() -> int:
	var v = Version.GAME_VERSION
	return int(v.get("build", 0)) if v is Dictionary and v.get("build") != null else 0

# "android-42" -> 42; anything else -> -1
static func parse_build(tag: String) -> int:
	if not tag.begins_with("android-"): return -1
	var n := tag.substr(8)
	return n.to_int() if n.is_valid_int() else -1

func _on_latest(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200: return
	var json = JSON.parse_string(body.get_string_from_utf8())
	if not (json is Dictionary): return
	if parse_build(str(json.get("tag_name", ""))) <= installed_build(): return
	for a in json.get("assets", []):
		if a is Dictionary and str(a.get("name", "")).ends_with(".apk"):
			_prompt(str(json.get("name", "")), str(a.get("browser_download_url", "")))
			return

# same look as the game's own confirm dialog (JS.confirmDialog)
func _prompt(release_name: String, apk_url: String) -> void:
	var overlay: DomNode = document.createElement("div")
	overlay.style.cssText = "position:fixed;inset:0;background:rgba(0,0,0,.72);z-index:9600;display:flex;align-items:center;justify-content:center;"
	var box: DomNode = document.createElement("div")
	box.style.cssText = "background:#0d0b09;border:1px solid #3a2a10;border-radius:8px;padding:1.2rem 1.4rem;max-width:360px;text-align:center;box-shadow:0 8px 40px rgba(0,0,0,.8);"
	var title: DomNode = document.createElement("div")
	title.style.cssText = "font-family:'Cinzel',serif;font-size:.85rem;color:#e0b060;margin-bottom:.5rem;letter-spacing:.06em;"
	title.textContent = "Update available"
	var sub: DomNode = document.createElement("div")
	sub.style.cssText = "font-family:'Cinzel',serif;font-size:.62rem;color:#c8a060;margin-bottom:.5rem;"
	sub.textContent = release_name
	var text: DomNode = document.createElement("div")
	text.style.cssText = "font-family:'Cinzel',serif;font-size:.58rem;color:#a08050;margin-bottom:1rem;line-height:1.6;"
	text.textContent = "It downloads in your browser. Open the file when it finishes to install. Your saves are kept."
	var row: DomNode = document.createElement("div")
	row.style.cssText = "display:flex;gap:.6rem;justify-content:center;"
	var yes: DomNode = document.createElement("button")
	yes.style.cssText = "background:#0e1408;border:1px solid #4a6a1a;color:#a0d060;font-family:'Cinzel',serif;font-size:.7rem;padding:.4rem 1rem;border-radius:4px;cursor:pointer;"
	yes.textContent = "Update"
	var no: DomNode = document.createElement("button")
	no.style.cssText = "background:#0f0d0b;border:1px solid #3a3020;color:#8a6a30;font-family:'Cinzel',serif;font-size:.7rem;padding:.4rem 1rem;border-radius:4px;cursor:pointer;"
	no.textContent = "Later"
	yes.onclick = func():
		overlay.remove()
		OS.shell_open(apk_url)
	no.onclick = func(): overlay.remove()
	row.appendChild(yes); row.appendChild(no)
	box.appendChild(title); box.appendChild(sub); box.appendChild(text); box.appendChild(row)
	overlay.appendChild(box)
	document.body.appendChild(overlay)
