# Characters — generated from js/data/characters.js by tools/js2gd.js
extends Node

# ===== characters.js =====
# ─── CHARACTER SELECT ─────────────────────────────────────────────────────────
# Shown once at the start of a run (after title, before element select).
# Each character shows a random buff from its pool — player picks one.
var playerCharId = ""
# 'battlemage' | 'hexblade' | 'arcanist'
var playerCharBuff = null
var CHARACTER_ROSTER = null
var CHARACTER_BUFFS = null
var _charRolledBuffs = null
var WIZ_ARCHETYPES = null
var WIZ_HAT_COLORS = null
var WIZ_OUTFIT_COLORS = null
var WIZ_BEARD_COLORS = null
var WIZ_BEARD_STYLES = null
var WIZ_STAFF_COLORS = null
var WIZ_STAFF_GLOWS = null
var WIZ_EYE_COLORS = null
var WIZ_DEFAULTS = null
var _wizBuild = null
var _wizBuilderFromLobby = false
var CHAR_PORTRAIT_STYLES = null

func _boot():
	# { id, name, emoji, desc, apply }
	# ─── Character Roster ─────────────────────────────────────────────────────────
	CHARACTER_ROSTER = [
		{
			"id": "battlemage",
			"name": "Battlemage",
			"title": "The Ironweave",
			"desc": "Forged in war. Channels magic through heavy armor and sheer endurance.",
			"flavor": "They say he was hit by lightning seven times. He just got angrier.",
			"color": "#c8802a",
			"hatColor": "#8a4a10",
			"robeColor": "#5a3020",
			"buffPool": ["buff_hp_bonus", "buff_def_bonus", "buff_block_start"],
		},
		{
			"id": "hexblade",
			"name": "Hexblade",
			"title": "The Shadowcast",
			"desc": "A blade-dancer who weaves curses into every strike. Fast, precise, lethal.",
			"flavor": "She does not dodge spells. She redirects them. Into your face.",
			"color": "#9a6aee",
			"hatColor": "#4a2080",
			"robeColor": "#1e0e3a",
			"buffPool": ["buff_atk_bonus", "buff_gold_start", "buff_potion_start"],
		},
		{
			"id": "arcanist",
			"name": "Arcanist",
			"title": "The Scholar",
			"desc": "A pure-theory wizard who has turned study into devastating practice.",
			"flavor": "Every status effect is a theorem. Every battle, a proof.",
			"color": "#4a9aee",
			"hatColor": "#1a3a8a",
			"robeColor": "#0e1e4a",
			"buffPool": ["buff_efx_bonus", "buff_spell_start", "buff_xp_bonus"],
		},
	]
	# ─── Buff Definitions ─────────────────────────────────────────────────────────
	# apply() is called once during beginRun(), after player stats are reset.
	# TODO: fill in more exotic buffs — these are the scaffolded starters.
	CHARACTER_BUFFS = {
		"buff_hp_bonus": {
			"name": "Fortitude",
			"emoji": "🛡️",
			"desc": "Start with +50 max HP.",
			"apply": CHARACTER_BUFFS__buff_hp_bonus__apply,
		},
		"buff_def_bonus": {
			"name": "Iron Skin",
			"emoji": "⚙️",
			"desc": "Start with +5 Defense.",
			"apply": CHARACTER_BUFFS__buff_def_bonus__apply,
		},
		"buff_block_start": {
			"name": "Bulwark",
			"emoji": "🪨",
			"desc": "Enter every battle with 25 pre-stacked Block.",
			"apply": CHARACTER_BUFFS__buff_block_start__apply,
		},
		"buff_atk_bonus": {
			"name": "Keen Edge",
			"emoji": "⚔️",
			"desc": "Start with +5 Attack Power.",
			"apply": CHARACTER_BUFFS__buff_atk_bonus__apply,
		},
		"buff_gold_start": {
			"name": "Profiteer",
			"emoji": "💰",
			"desc": "Start with 60 gold.",
			"apply": CHARACTER_BUFFS__buff_gold_start__apply,
		},
		"buff_potion_start": {
			"name": "Prepared",
			"emoji": "🧪",
			"desc": "Start with 2 Health Potions.",
			"apply": CHARACTER_BUFFS__buff_potion_start__apply,
		},
		"buff_efx_bonus": {
			"name": "Arcanist",
			"emoji": "🔮",
			"desc": "Start with +5 Effect Power.",
			"apply": CHARACTER_BUFFS__buff_efx_bonus__apply,
		},
		"buff_spell_start": {
			"name": "Head Start",
			"emoji": "📚",
			"desc": "Begin the run with an extra spell of your element.",
			"apply": CHARACTER_BUFFS__buff_spell_start__apply,
		},
		"buff_xp_bonus": {
			"name": "Deep Study",
			"emoji": "📖",
			"desc": "Gain +5 Effect Power at run start.",
			"apply": CHARACTER_BUFFS__buff_xp_bonus__apply,
		},
	}
	# ─── Screen rendering ─────────────────────────────────────────────────────────
	_charRolledBuffs = {}
	# charId → rolled buff (fresh each visit)
	# ═══════════════════════════════════════════════════════════════════════════════
	# WIZARD BUILDER
	# ═══════════════════════════════════════════════════════════════════════════════
	# All customization options
	# ═══════════════════════════════════════════════════════════════════════════════
	# WIZARD BUILDER — all customization maps to actual sprite color overrides
	# ═══════════════════════════════════════════════════════════════════════════════
	WIZ_ARCHETYPES = [
		{
			"id": "battlemage",
			"name": "Battlemage",
			"emoji": "⚔",
			"desc": "Armored. Bonus HP and defense.",
			"sprite": "SPRITE_CHAR_WARRIOR",
		},
		{
			"id": "hexblade",
			"name": "Hexblade",
			"emoji": "🗡",
			"desc": "Shadow caster. Bonus gold and curses.",
			"sprite": "SPRITE_CHAR_ROGUE",
		},
		{
			"id": "arcanist",
			"name": "Arcanist",
			"emoji": "⭐",
			"desc": "Scholar. Bonus spell options and effect power.",
			"sprite": "SPRITE_CHAR_MAGE",
		},
	]
	# Hat color — overrides 'h' char (which maps to pal[1] by default, but we override)
	WIZ_HAT_COLORS = [
		{"id": "navy", "name": "Navy", "color": "#102060"},
		{"id": "violet", "name": "Violet", "color": "#3a0e80"},
		{"id": "forest", "name": "Forest", "color": "#0e3a10"},
		{"id": "scarlet", "name": "Scarlet", "color": "#5a0e0e"},
		{"id": "black", "name": "Black", "color": "#111116"},
		{"id": "teal", "name": "Teal", "color": "#0a2e30"},
		{"id": "gold", "name": "Gold", "color": "#3a2800"},
		{"id": "grey", "name": "Grey", "color": "#2a2a32"},
	]
	# Outfit — overrides pal[0] (primary robe), pal[1] auto-darkened for shadow
	WIZ_OUTFIT_COLORS = [
		{"id": "midnight", "name": "Midnight", "p0": "#1a1060", "p1": "#0c0840", "p2": "#2a1a80", "p3": "#8878cc"},
		{"id": "crimson", "name": "Crimson", "p0": "#601010", "p1": "#380808", "p2": "#881818", "p3": "#cc5050"},
		{"id": "forest", "name": "Forest", "p0": "#0e3a10", "p1": "#062008", "p2": "#186018", "p3": "#50aa50"},
		{"id": "gold", "name": "Golden", "p0": "#3a2c08", "p1": "#201808", "p2": "#604818", "p3": "#d0a030"},
		{"id": "ocean", "name": "Ocean", "p0": "#0e1e60", "p1": "#081040", "p2": "#182888", "p3": "#4080d0"},
		{"id": "dusk", "name": "Dusk", "p0": "#2a1040", "p1": "#140820", "p2": "#401860", "p3": "#9050c0"},
		{"id": "iron", "name": "Iron", "p0": "#2a2a30", "p1": "#181818", "p2": "#3a3a44", "p3": "#8888a0"},
		{"id": "ember", "name": "Ember", "p0": "#3a1408", "p1": "#1e0a04", "p2": "#601a08", "p3": "#d04010"},
	]
	# Beard — overrides 'w' char; 'none' removes all 'w' pixels
	WIZ_BEARD_COLORS = [
		{"id": "white", "name": "White", "color": "#e8e0d0"},
		{"id": "grey", "name": "Grey", "color": "#a0989a"},
		{"id": "black", "name": "Black", "color": "#1a1418"},
		{"id": "brown", "name": "Brown", "color": "#6a3810"},
		{"id": "auburn", "name": "Auburn", "color": "#8a2808"},
		{"id": "gold", "name": "Golden", "color": "#c8a030"},
	]
	WIZ_BEARD_STYLES = [{"id": "show", "name": "Beard"}, {"id": "none", "name": "Clean"}]
	# Staff wood — overrides 'f' char
	WIZ_STAFF_COLORS = [
		{"id": "oak", "name": "Oak", "color": "#8a5010"},
		{"id": "dark", "name": "Dark", "color": "#2a1a0a"},
		{"id": "bone", "name": "Bone", "color": "#d8c8a0"},
		{"id": "ebony", "name": "Ebony", "color": "#1a1010"},
		{"id": "birch", "name": "Birch", "color": "#c8b898"},
		{"id": "iron", "name": "Iron", "color": "#404850"},
	]
	# Staff glow — overrides 'g' char (pal[3] by default)
	WIZ_STAFF_GLOWS = [
		{"id": "blue", "name": "Blue", "color": "#60aaff"},
		{"id": "green", "name": "Green", "color": "#50dd70"},
		{"id": "red", "name": "Red", "color": "#ff6040"},
		{"id": "purple", "name": "Purple", "color": "#cc80ff"},
		{"id": "gold", "name": "Gold", "color": "#ffd040"},
		{"id": "white", "name": "White", "color": "#e8f0ff"},
		{"id": "teal", "name": "Teal", "color": "#40ddc0"},
		{"id": "none", "name": "None", "color": null},
	]
	# Eye color — overrides 'e' char
	WIZ_EYE_COLORS = [
		{"id": "red", "name": "Red", "color": "#dd3322"},
		{"id": "blue", "name": "Blue", "color": "#2255cc"},
		{"id": "green", "name": "Green", "color": "#226622"},
		{"id": "amber", "name": "Amber", "color": "#aa6600"},
		{"id": "purple", "name": "Purple", "color": "#7722aa"},
		{"id": "silver", "name": "Silver", "color": "#7788aa"},
		{"id": "void", "name": "Void", "color": "#080808"},
		{"id": "white", "name": "White", "color": "#ddeeff"},
	]
	WIZ_DEFAULTS = {
		"archetype": "battlemage",
		"hatColor": "navy",
		"outfit": "midnight",
		"beardStyle": "show",
		"beardColor": "white",
		"staffColor": "oak",
		"staffGlow": "blue",
		"eyeColor": "red",
	}
	_wizBuild = JS.merge([WIZ_DEFAULTS])
	CHAR_PORTRAIT_STYLES = {
		"battlemage": {
			"bg": "linear-gradient(175deg, #3a1808 0%, #1a0c04 60%, #0e0804 100%)",
			"ground": "linear-gradient(180deg, #2a1408, #1a0a04)",
			"glowRgb": "200,100,40",
		},
		"hexblade": {
			"bg": "linear-gradient(175deg, #1a0830 0%, #100620 60%, #080410 100%)",
			"ground": "linear-gradient(180deg, #1a0830, #0e0520)",
			"glowRgb": "140,80,240",
		},
		"arcanist": {
			"bg": "linear-gradient(175deg, #04102a 0%, #030c1e 60%, #02080e 100%)",
			"ground": "linear-gradient(180deg, #061228, #030c18)",
			"glowRgb": "60,140,255",
		},
	}

# ─── Roll a buff for a character ─────────────────────────────────────────────
func rollCharacterBuff(charId = null):
	var ch = JS.find(CHARACTER_ROSTER, func(c = null): return JS.eq(c.id, charId))
	if not JS.t(ch):
		return null
	var pool = JS.arr(ch.get("buffPool")).filter(func(id = null): return JS.t(JS.idx(CHARACTER_BUFFS, id)))
	if not JS.t(len(pool)):
		return null
	var id = JS.idx(pool, floori(randf() * len(pool)))
	var def = JS.idx(CHARACTER_BUFFS, id)
	return JS.merge([{"id": id}, def])

# Apply the chosen character's buff — called once from beginRun()
func applyCharacterBuff():
	if (JS.t(playerCharBuff) and (JS.typeof_(playerCharBuff.get("apply"))) == "function"):
		JS.callm(playerCharBuff, "apply", [])

# true when opened from the lobby tailor, so "continue" returns to lobby
func _applyWizBuild(patch = null):
	JS.assign(_wizBuild, [patch])
	Main.patchActiveSlot({"wizardBuild": _wizBuild})
	_renderWizBuilder()

func getWizColorMap():
	var b = _wizBuild
	var hatClr = JS.or_(JS.find(WIZ_HAT_COLORS, func(c = null): return JS.eq(c.id, b.get("hatColor"))), JS.idx(WIZ_HAT_COLORS, 0))
	var outClr = JS.or_(JS.find(WIZ_OUTFIT_COLORS, func(c = null): return JS.eq(c.id, b.get("outfit"))), JS.idx(WIZ_OUTFIT_COLORS, 0))
	var beardClr = JS.or_(JS.find(WIZ_BEARD_COLORS, func(c = null): return JS.eq(c.id, b.get("beardColor"))), JS.idx(WIZ_BEARD_COLORS, 0))
	var staffClr = JS.or_(JS.find(WIZ_STAFF_COLORS, func(c = null): return JS.eq(c.id, b.get("staffColor"))), JS.idx(WIZ_STAFF_COLORS, 0))
	var glowClr = JS.or_(JS.find(WIZ_STAFF_GLOWS, func(g = null): return JS.eq(g.id, b.get("staffGlow"))), JS.idx(WIZ_STAFF_GLOWS, 0))
	var eyeClr = JS.or_(JS.find(WIZ_EYE_COLORS, func(e = null): return JS.eq(e.id, b.get("eyeColor"))), JS.idx(WIZ_EYE_COLORS, 0))
	var showBeard = b.get("beardStyle") != "none"
	return {
		".": null,
		"1": outClr.get("p0"),
		"2": outClr.get("p1"),
		"3": outClr.get("p2"),
		"4": outClr.get("p3"),
		"h": hatClr.get("color"),
		"s": SpriteData.SKIN_C,
		"e": eyeClr.get("color"),
		"b": SpriteData.BOOT_C,
		"w": (beardClr.get("color") if showBeard else null),
		"f": staffClr.get("color"),
		"g": JS.or_(glowClr.get("color"), outClr.get("p3")),
	}

func showCharacterScreen():
	var slotData = Main.getActiveSlotData()
	if JS.t(slotData.get("wizardBuild")):
		_wizBuild = JS.assign(JS.merge([WIZ_DEFAULTS]), [slotData.get("wizardBuild")])
	elif JS.t(slotData.get("savedCharId")):
		_wizBuild = JS.merge([WIZ_DEFAULTS, {"archetype": slotData.get("savedCharId")}])
	playerCharId = _wizBuild.get("archetype")
	_charRolledBuffs = {}
	for ch in JS.iter(CHARACTER_ROSTER):
		_charRolledBuffs[ch.id] = rollCharacterBuff(ch.id)
	_renderWizBuilder()
	UI.showScreen("character-screen")
	# Update button label depending on context
	var continueBtn = document.getElementById("char-continue-btn")
	if JS.t(continueBtn):
		continueBtn.textContent = ("Save ✓" if JS.t(_wizBuilderFromLobby) else "Continue →")

func _renderWizBuilder():
	_renderWizSection("archetype", "Wizard Type", _buildArchetypeOpts())
	_renderWizBoon()
	_renderWizSection("hat", "Hat Color", _buildColorOpts(WIZ_HAT_COLORS, "hatColor", func(c = null): return "background:" + JS.s(c.get("color")) + ";"))
	_renderWizSection("outfit", "Outfit Color", _buildColorOpts(WIZ_OUTFIT_COLORS, "outfit", func(c = null): return "background:linear-gradient(135deg," + JS.s(c.get("p0")) + "," + JS.s(c.get("p1")) + ");"))
	_renderWizSection("beard", "Beard", _buildBeardOpts())
	_renderWizSection("staff", "Staff Wood", _buildColorOpts(WIZ_STAFF_COLORS, "staffColor", func(c = null): return "background:" + JS.s(c.get("color")) + ";"))
	_renderWizSection("staffglow", "Orb Glow", _buildColorOpts(WIZ_STAFF_GLOWS, "staffGlow", func(c = null): return ("background:radial-gradient(circle," + JS.s(c.get("color")) + "," + JS.s(c.get("color")) + "66);" if JS.t(c.get("color")) else "background:#0a0806;"), true))
	_renderWizSection("eyes", "Eye Color", _buildColorOpts(WIZ_EYE_COLORS, "eyeColor", func(c = null): return "background:" + JS.s(c.get("color")) + ";"))
	_renderWizPreview()

func _renderWizSection(id = null, label = null, html = null):
	var el = document.getElementById("wiz-section-" + JS.s(id))
	if not JS.t(el):
		return
	el.innerHTML = "<div class=\"wiz-section\"><div class=\"wiz-section-label\">" + JS.s(label) + "</div><div class=\"wiz-opts\">" + JS.s(html) + "</div></div>"

func _wizOpt(selected = null, onclick = null, swatchStyle = null, label = null, extra = null):
	return "<div class=\"wiz-opt" + (" selected" if JS.t(selected) else "") + "\" onclick=\"" + JS.s(onclick) + "\">\n    <div class=\"wiz-opt-swatch\" style=\"" + JS.s(swatchStyle) + "\">" + (JS.or_(extra, "")) + "</div>\n    <div class=\"wiz-opt-label\">" + JS.s(label) + "</div>\n  </div>"

func _buildColorOpts(list = null, key = null, styleFn = null, noneOpt = null):
	var _fn1 = func(c = null):
		var selected = JS.eq(JS.idx(_wizBuild, key), c.id)
		var noneX = ("<div style=\"position:absolute;inset:0;display:flex;align-items:center;justify-content:center;color:#3a2a10;font-size:11px;\">✕</div>" if c.get("id") == "none" else "")
		return _wizOpt(selected, "_applyWizBuild({" + JS.s(key) + ":'" + JS.s(c.id) + "'})", styleFn.call(c), c.get("name"), noneX)
	return JS.join(JS.arr(list).map(_fn1), "")

func _buildArchetypeOpts():
	var _fn2 = func(a = null):
		var selected = JS.eq(_wizBuild.get("archetype"), a.id)
		var ps = JS.or_(JS.idx(CHAR_PORTRAIT_STYLES, a.id), CHAR_PORTRAIT_STYLES.get("battlemage"))
		var swatch = "background:" + JS.s(ps.get("bg")) + ";display:flex;align-items:center;justify-content:center;font-size:15px;"
		return _wizOpt(selected, "_applyWizBuild({archetype:'" + JS.s(a.id) + "'})", swatch, a.get("name"), a.get("emoji"))
	return JS.join(JS.arr(WIZ_ARCHETYPES).map(_fn2), "")

func _buildBeardOpts():
	var _fn3 = func(s = null):
		var selected = JS.eq(_wizBuild.get("beardStyle"), s.id)
		var swatchStyle = ("background:#0a0806;" if s.get("id") == "none" else "background:#e8e0d0;")
		var extra = ("<div style=\"position:absolute;inset:0;display:flex;align-items:center;justify-content:center;color:#3a2a10;font-size:11px;\">✕</div>" if s.get("id") == "none" else "<div style=\"position:absolute;bottom:3px;left:50%;transform:translateX(-50%);width:14px;height:10px;background:#e8e0d0;border-radius:3px 3px 5px 5px;\"></div>")
		return _wizOpt(selected, "_applyWizBuild({beardStyle:'" + JS.s(s.id) + "'})", swatchStyle, s.get("name"), extra)
	var styleOpts = JS.join(JS.arr(WIZ_BEARD_STYLES).map(_fn3), "")
	var divider = "<div style=\"width:100%;height:1px;background:#1a1208;margin:4px 0;\"></div>"
	var _fn4 = func(c = null):
		var selected = JS.eq(_wizBuild.get("beardColor"), c.id)
		return _wizOpt(selected, "_applyWizBuild({beardColor:'" + JS.s(c.id) + "'})", "background:" + JS.s(c.get("color")) + ";", c.get("name"))
	var colorOpts = JS.join(JS.arr(WIZ_BEARD_COLORS).map(_fn4), "")
	return styleOpts + divider + colorOpts

func _renderWizBoon():
	var secEl = document.getElementById("wiz-section-archetype")
	if not JS.t(secEl):
		return
	var old = secEl.querySelector(".wiz-boon-row")
	if JS.t(old):
		old.remove()
	var arch = JS.find(WIZ_ARCHETYPES, func(a = null): return JS.eq(a.id, _wizBuild.get("archetype")))
	var buff = JS.idx(_charRolledBuffs, _wizBuild.get("archetype"))
	if not JS.t(arch):
		return
	var row = document.createElement("div")
	row.className = "wiz-boon-row"
	row.style.cssText = "margin-top:.45rem;padding:.35rem .5rem;background:#0e0c06;border:1px solid #1e1808;border-radius:5px;font-size:.56rem;line-height:1.5;"
	row.innerHTML = ("<div style=\"color:#7a5828;font-size:.47rem;font-family:Cinzel,serif;letter-spacing:.1em;text-transform:uppercase;margin-bottom:.15rem;\">" + JS.s(arch.get("desc")) + "</div>") + ("<div style=\"color:#5a4020;font-size:.46rem;font-family:Cinzel,serif;letter-spacing:.08em;text-transform:uppercase;margin-bottom:.1rem;\">Starting Boon (re-rolled each run)</div><div style=\"color:#c8a060;\">" + JS.s(buff.get("emoji")) + " " + JS.s(buff.get("name")) + " — <span style=\"color:#7a6040;\">" + JS.s(buff.get("desc")) + "</span></div>" if JS.t(buff) else "")
	secEl.appendChild(row)

# ── Draw wizard preview on canvas using the real sprite system ────────────────
func _renderWizPreview():
	var canvas = document.getElementById("wiz-preview-canvas")
	if not JS.t(canvas):
		return
	var ctx = canvas.getContext("2d")
	var W = canvas.width
	var H = canvas.height
	var b = _wizBuild
	var arch = JS.or_(JS.find(WIZ_ARCHETYPES, func(a = null): return JS.eq(a.id, b.get("archetype"))), JS.idx(WIZ_ARCHETYPES, 0))
	var hatClr = JS.or_(JS.find(WIZ_HAT_COLORS, func(c = null): return JS.eq(c.id, b.get("hatColor"))), JS.idx(WIZ_HAT_COLORS, 0))
	var outClr = JS.or_(JS.find(WIZ_OUTFIT_COLORS, func(c = null): return JS.eq(c.id, b.get("outfit"))), JS.idx(WIZ_OUTFIT_COLORS, 0))
	var beardClr = JS.or_(JS.find(WIZ_BEARD_COLORS, func(c = null): return JS.eq(c.id, b.get("beardColor"))), JS.idx(WIZ_BEARD_COLORS, 0))
	var staffClr = JS.or_(JS.find(WIZ_STAFF_COLORS, func(c = null): return JS.eq(c.id, b.get("staffColor"))), JS.idx(WIZ_STAFF_COLORS, 0))
	var glowClr = JS.or_(JS.find(WIZ_STAFF_GLOWS, func(g = null): return JS.eq(g.id, b.get("staffGlow"))), JS.idx(WIZ_STAFF_GLOWS, 0))
	var eyeClr = JS.or_(JS.find(WIZ_EYE_COLORS, func(e = null): return JS.eq(e.id, b.get("eyeColor"))), JS.idx(WIZ_EYE_COLORS, 0))
	var ps = JS.or_(JS.idx(CHAR_PORTRAIT_STYLES, b.get("archetype")), CHAR_PORTRAIT_STYLES.get("battlemage"))
	# Background
	var grad = ctx.createLinearGradient(0, 0, 0, H)
	var bgParts = JS.orf(JS.match_(ps.get("bg"), JS.re("#[0-9a-fA-F]{6}", "g")), func(): return ["#080604", "#0a0806"])
	grad.addColorStop(0, JS.idx(bgParts, 0))
	grad.addColorStop(1, JS.idx(bgParts, len(bgParts) - 1))
	ctx.fillStyle = grad
	ctx.fillRect(0, 0, W, H)
	# Ground strip
	ctx.fillStyle = "#0e0a06"
	ctx.fillRect(0, H - 28, W, 28)
	ctx.fillStyle = "rgba(255,255,255,0.04)"
	ctx.fillRect(0, H - 28, W, 1)
	# Get sprite rows based on archetype
	var rows = JS.or_(JS.idx({
		"battlemage": SpriteData.SPRITE_CHAR_WARRIOR,
		"hexblade": SpriteData.SPRITE_CHAR_ROGUE,
		"arcanist": SpriteData.SPRITE_CHAR_MAGE,
	}, b.get("archetype")), SpriteData.SPRITE_CHAR_WARRIOR)
	if not JS.t(rows):
		return
	# Build full custom color map — overrides charToColor for every character
	var showBeard = b.get("beardStyle") != "none"
	var customColorMap = {
		".": null,
		"1": outClr.get("p0"),
		"2": outClr.get("p1"),
		"3": outClr.get("p2"),
		"4": outClr.get("p3"),
		"h": hatClr.get("color"),
		"s": SpriteData.SKIN_C,
		"e": eyeClr.get("color"),
		"b": SpriteData.BOOT_C,
		"w": (beardClr.get("color") if showBeard else null),
		"f": staffClr.get("color"),
		"g": glowClr.get("color"),
	}
	# null = transparent (no beard)
	# Draw sprite using custom color map
	var scale_ = 4
	var cols = 24
	var sprW = cols * scale_
	var sprH = len(rows) * scale_
	var sx = JS.round((W - sprW) / 2.0)
	var sy = (H - 28) - sprH
	for row in range(len(rows)):
		for col in range(ceili(cols)):
			var c = JS.or_(JS.idx(JS.or_(JS.idx(rows, row), ""), col), ".")
			var color = JS.idx(customColorMap, c)
			if not JS.t(color):
				continue
			ctx.fillStyle = color
			ctx.fillRect(sx + (col * scale_), sy + (row * scale_), scale_, scale_)
	# Name label
	var nameEl = document.getElementById("wiz-prev-name")
	if JS.t(nameEl):
		nameEl.textContent = arch.get("name")

func _updateCharBtn():
	var btn = document.getElementById("char-continue-btn")
	if JS.t(btn):
		btn.disabled = false

func confirmCharacterSelect():
	# Sync archetype + full build from wizard builder
	playerCharId = _wizBuild.get("archetype")
	playerCharBuff = JS.or_(JS.idx(_charRolledBuffs, playerCharId), null)
	Main.patchActiveSlot({"savedCharId": playerCharId, "wizardBuild": _wizBuild})
	if JS.t(_wizBuilderFromLobby):
		_wizBuilderFromLobby = false
		BetweenRuns.showBetweenRuns()
		return
	document.getElementById("welcome-msg").textContent = JS.s(State.playerName) + ", choose your element"
	Main.showElementScreen()

func CHARACTER_BUFFS__buff_hp_bonus__apply():
	# ── Warrior buffs ──────────────────────────────────────────────────────────
	State.player.baseMaxHPBonus = (JS.or_(State.player.get("baseMaxHPBonus"), 0)) + 50
	State.player.hp = min(Helpers.maxHPFor("player"), State.player.get("hp") + 50)

func CHARACTER_BUFFS__buff_def_bonus__apply():
	State.player.defense += 5

func CHARACTER_BUFFS__buff_block_start__apply():
	# Applied in loadBattle via player._blockStart flag
	State.player._blockStart = (JS.or_(State.player.get("_blockStart"), 0)) + 25

func CHARACTER_BUFFS__buff_atk_bonus__apply():
	# ── Rogue buffs ────────────────────────────────────────────────────────────
	State.player.attackPower += 5

func CHARACTER_BUFFS__buff_gold_start__apply():
	State.player.gold += 60

func CHARACTER_BUFFS__buff_potion_start__apply():
	Spells.addItem("health_potion")
	Spells.addItem("health_potion")

func CHARACTER_BUFFS__buff_efx_bonus__apply():
	# ── Mage buffs ─────────────────────────────────────────────────────────────
	State.player.effectPower += 5

func CHARACTER_BUFFS__buff_spell_start__apply():
	# Applied after element is selected — flag checked in beginRun
	State.player._extraStartSpell = true

func CHARACTER_BUFFS__buff_xp_bonus__apply():
	State.player.effectPower = (JS.or_(State.player.get("effectPower"), 0)) + 5
