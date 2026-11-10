# BookEditor — generated from js/ui/bookEditor.js by tools/js2gd.js
extends Node

# ─── DESTINATION PICKER (for reward screens) ─────────────────────────────────
# Called from battleReward.js before adding a spell/passive.
# If only one valid destination exists, calls cb(bookIdx) immediately.
# Otherwise shows a modal listing books with slot counts.
var _bdCallback = null
# ─── BOOK EDITOR (map screen) ────────────────────────────────────────────────
var _beTab = 0
var _beMoveItem = null

func _boot():
	pass

# ===== bookEditor.js =====
# Book destination picker (reward screens) + spellbook management editor (map)
# ─── SHARED UTIL ─────────────────────────────────────────────────────────────
func _bookEmoji(book = null):
	if JS.t(book.get("emoji")):
		return book.get("emoji")
	var m = {
		"Fire": "🔥",
		"Water": "💧",
		"Ice": "❄️",
		"Lightning": "⚡",
		"Earth": "🪨",
		"Nature": "🌿",
		"Plasma": "🔮",
		"Air": "🌀",
	}
	return JS.or_(JS.idx(m, book.get("element")), "📖")

func _isPlasmaPassive(passiveId = null):
	return JS.some(JS.or_(JS.idx(Passives.PASSIVE_CHOICES, "Plasma"), []), func(p = null): return JS.eq(p.id, passiveId))

# Returns the subset of player.spellbooks that can accept the given spell.
func _validDestBooksFor(kind = null, itemDef = null):
	if JS.eq(kind, "passive"):
		return []
	# passives are global, not book-routed
	var isPlasmaAbility = (itemDef.get("isPlasmaAbility") if JS.t(itemDef) else itemDef)
	var _fn1 = func(_p0 = null):
		var b = JS.idx(_p0, "b")
		if JS.t(b.get("isPlasmaBook")):
			return isPlasmaAbility
		return (not JS.t(isPlasmaAbility))
	return JS.arr(JS.map(State.player.get("spellbooks"), func(b = null, idx = null): return {"b": b, "idx": idx})).filter(_fn1)

func _pickBookDest(kind = null, itemDef = null, cb = null):
	if JS.eq(kind, "passive"):
		cb.call(null)
		return
	# passives are global
	var validBooks = _validDestBooksFor(kind, itemDef)
	if len(validBooks) <= 1:
		cb.call((JS.idx(validBooks, 0).get("idx") if len(validBooks) == 1 else State.player.get("activeBookIdx")))
		return
	_bdCallback = cb
	var overlay = document.getElementById("book-dest-overlay")
	if not JS.t(overlay):
		cb.call(State.player.get("activeBookIdx"))
		return
	# Item preview
	var preview = document.getElementById("bd-item-preview")
	if JS.t(preview):
		if JS.eq(kind, "passive"):
			var def = State._lookupPassiveDef((itemDef if (JS.typeof_(itemDef)) == "string" else itemDef.id))
			preview.innerHTML = (JS.s(def.get("emoji")) + " <strong>" + JS.s(def.title) + "</strong>" if JS.t(def) else JS.or_(itemDef.get("id"), itemDef))
		else:
			preview.innerHTML = JS.s(itemDef.get("emoji")) + " <strong>" + JS.s(itemDef.get("name")) + "</strong>"
	# Book buttons
	var list = document.getElementById("bd-book-list")
	list.innerHTML = ""
	for _e2 in JS.iter(validBooks):
		var b = JS.idx(_e2, "b")
		var idx = JS.idx(_e2, "idx")
		var usedSpells = len(JS.arr(b.get("spells")).filter(func(s = null): return not JS.t(s.get("isBuiltin"))))
		var free_ = b.get("spellSlots") - usedSpells
		var full = free_ <= 0
		var hint = ("Full" if full else JS.s(free_) + " slot" + ("s" if free_ != 1 else "") + " free")
		var hcol = ("#8a4a20" if full else "#4aaa6a")
		var btn = document.createElement("button")
		btn.className = "boo-spell-btn"
		btn.innerHTML = "<span>" + JS.s(_bookEmoji(b)) + " " + JS.s(b.get("name")) + "</span><span class=\"boo-remove-hint\" style=\"color:" + hcol + ";\">" + hint + "</span>"
		var _fn3 = func():
			overlay.classList.remove("open")
			var callback = _bdCallback
			_bdCallback = null
			callback.call(idx)
		btn.onclick = _fn3
		list.appendChild(btn)
	overlay.classList.add("open")

# null | { kind:'spell'|'passive', id, spellObj?, srcBookIdx }
func showBookEditor():
	if (not JS.t(State.player.get("spellbooks")) or not JS.t(len(State.player.get("spellbooks")))):
		return
	_beTab = State.player.get("activeBookIdx")
	_beMoveItem = null
	_beRender()
	document.getElementById("book-editor-overlay").style.display = "flex"

func closeBookEditor():
	document.getElementById("book-editor-overlay").style.display = "none"
	_beMoveItem = null

# ── Render dispatcher ────────────────────────────────────────────────────────
func _beRender():
	_beRenderTabs()
	if JS.t(_beMoveItem):
		_beRenderPickDest()
	else:
		_beRenderBrowse()

func _beRenderTabs():
	var tabs = document.getElementById("be-tabs")
	if not JS.t(tabs):
		return
	tabs.innerHTML = ""
	var _arr4 = JS.iter(State.player.get("spellbooks"))
	for i in range(len(_arr4)):
		var b = _arr4[i]
		var btn = document.createElement("button")
		var active = JS.eq(i, _beTab)
		btn.style.cssText = JS.join([
			"flex:1;min-width:0;padding:.3rem .35rem;font-family:'Cinzel',serif;font-size:.58rem;",
			"letter-spacing:.04em;cursor:pointer;border-radius:4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;",
			"border:1px solid " + ("#c8a060" if active else "#2a2420") + ";",
			"background:" + ("#1a1208" if active else "#0a0906") + ";",
			"color:" + ("#c8a060" if active else "#555") + ";",
		], "")
		btn.textContent = JS.s(_bookEmoji(b)) + " " + JS.s(b.get("name"))
		var _fn5 = func():
			_beTab = i
			_beMoveItem = null
			_beRender()
		btn.onclick = _fn5
		tabs.appendChild(btn)

# ── Browse view ───────────────────────────────────────────────────────────────
func _beRenderBrowse():
	var cont = document.getElementById("be-content")
	if not JS.t(cont):
		return
	cont.innerHTML = ""
	var book = JS.idx(State.player.get("spellbooks"), _beTab)
	if not JS.t(book):
		return
	# Spells
	var nonBuiltin = JS.arr(book.get("spells")).filter(func(s = null): return not JS.t(s.get("isBuiltin")))
	cont.appendChild(_beSectionHdr("✦ Spells — " + JS.s(len(nonBuiltin)) + " / " + JS.s(book.get("spellSlots"))))
	if len(nonBuiltin) == 0:
		cont.appendChild(_beEmpty("No spells yet."))
	else:
		for sp in JS.iter(nonBuiltin):
			var _fn6 = func():
				_beMoveItem = {"kind": "spell", "id": sp.id, "spellObj": sp, "srcBookIdx": _beTab}
				_beRender()
			cont.appendChild(_beItemRow(JS.s(sp.get("emoji")) + " " + JS.s(sp.get("name")), JS.or_(sp.get("desc"), ""), _fn6))
	# Passives — global (not per-book)
	if JS.eq(_beTab, 0):
		var globalPassives = JS.or_(State.player.get("passives"), [])
		var passiveCap = JS.or_(State.player.get("passiveSlots"), 6)
		cont.appendChild(_beSectionHdr("✦ Passives (Global) — " + JS.s(len(globalPassives)) + " / " + JS.s(passiveCap)))
		if len(globalPassives) == 0:
			cont.appendChild(_beEmpty("No passives yet."))
		else:
			for pid in JS.iter(globalPassives):
				var def = State._lookupPassiveDef(pid)
				var row = document.createElement("div")
				row.style.cssText = "display:flex;align-items:center;gap:.4rem;padding:.3rem .45rem;background:#0d0b09;border:1px solid #1a1512;border-radius:4px;margin-bottom:.2rem;"
				var info = document.createElement("div")
				info.style.cssText = "flex:1;min-width:0;"
				var nameEl = document.createElement("div")
				nameEl.style.cssText = "font-size:.7rem;color:#c8a060;font-family:'Cinzel',serif;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"
				nameEl.textContent = (JS.s(def.get("emoji")) + " " + JS.s(def.title) if JS.t(def) else pid)
				var descEl = document.createElement("div")
				descEl.style.cssText = "font-size:.58rem;color:#555;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"
				descEl.textContent = (JS.or_(def.get("desc"), "") if JS.t(def) else "")
				info.appendChild(nameEl)
				info.appendChild(descEl)
				row.appendChild(info)
				cont.appendChild(row)

# ── Destination picker view ───────────────────────────────────────────────────
func _beRenderPickDest():
	var cont = document.getElementById("be-content")
	var item = _beMoveItem
	if (not JS.t(cont) or not JS.t(item)):
		return
	cont.innerHTML = ""
	# Back + moving-item label
	var backRow = document.createElement("div")
	backRow.style.cssText = "display:flex;align-items:center;gap:.5rem;margin-bottom:.7rem;"
	var backBtn = document.createElement("button")
	backBtn.style.cssText = "background:#0a0806;border:1px solid #2a2420;color:#888;padding:.2rem .55rem;font-size:.62rem;cursor:pointer;border-radius:3px;white-space:nowrap;"
	backBtn.textContent = "← Back"
	var _fn7 = func():
		_beMoveItem = null
		_beRender()
	backBtn.onclick = _fn7
	var label = document.createElement("span")
	label.style.cssText = "font-size:.68rem;color:#c8a060;font-family:'Cinzel',serif;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;"
	if JS.eq(item.get("kind"), "spell"):
		label.textContent = "Moving: " + JS.s(item.get("spellObj").get("emoji")) + " " + JS.s(item.get("spellObj").get("name"))
	else:
		var def = State._lookupPassiveDef(item.id)
		label.textContent = "Moving: " + JS.s((JS.s(def.get("emoji")) + " " + JS.s(def.title) if JS.t(def) else item.id))
	backRow.appendChild(backBtn)
	backRow.appendChild(label)
	cont.appendChild(backRow)
	cont.appendChild(_beSectionHdr("Choose destination:"))
	var _fn8 = func(_p0 = null):
		var idx = JS.idx(_p0, "idx")
		return not JS.eq(idx, item.get("srcBookIdx"))
	var dests = JS.arr(_validDestBooksFor(item.get("kind"), (item.get("spellObj") if JS.eq(item.get("kind"), "spell") else item.id))).filter(_fn8)
	if len(dests) == 0:
		cont.appendChild(_beEmpty("No other valid books to move to."))
		return
	for _e9 in JS.iter(dests):
		var b = JS.idx(_e9, "b")
		var idx = JS.idx(_e9, "idx")
		var usedSpells = len(JS.arr(b.get("spells")).filter(func(s = null): return not JS.t(s.get("isBuiltin"))))
		var free_ = b.get("spellSlots") - usedSpells
		var isFull = free_ <= 0
		if not isFull:
			# Simple move button
			var btn = document.createElement("button")
			btn.className = "boo-spell-btn"
			btn.innerHTML = "<span>" + JS.s(_bookEmoji(b)) + " " + JS.s(b.get("name")) + "</span><span class=\"boo-remove-hint\" style=\"color:#4aaa6a;\">Move here (" + JS.s(free_) + " free)</span>"
			btn.onclick = func(): return _beDoMove(idx)
			cont.appendChild(btn)
		else:
			var expanded = [null]
			# Full — show collapsible swap list
			var wrap_ = document.createElement("div")
			wrap_.style.cssText = "display:flex;flex-direction:column;gap:.2rem;"
			var hintId = "be-swap-hint-" + JS.s(idx)
			var bookBtn = document.createElement("button")
			bookBtn.className = "boo-spell-btn"
			bookBtn.innerHTML = "<span>" + JS.s(_bookEmoji(b)) + " " + JS.s(b.get("name")) + "</span><span class=\"boo-remove-hint\" style=\"color:#8a6a20;\" id=\"" + hintId + "\">Full — swap ▾</span>"
			var swapList = document.createElement("div")
			swapList.style.cssText = "display:none;flex-direction:column;gap:.25rem;padding:.25rem 0 0 .7rem;"
			# Swap targets (spells only — passives are global)
			var swapItems = JS.arr(JS.arr(b.get("spells")).filter(func(s = null): return not JS.t(s.get("isBuiltin")))).map(func(sp = null): return {"label": JS.s(sp.get("emoji")) + " " + JS.s(sp.get("name")), "ref": sp})
			for sw in JS.iter(swapItems):
				var swBtn = document.createElement("button")
				swBtn.className = "boo-spell-btn"
				swBtn.style.cssText = "font-size:.66rem;border-color:#1a1a1a;"
				swBtn.innerHTML = "<span>" + JS.s(sw.get("label")) + "</span><span class=\"boo-remove-hint\" style=\"color:#6a8a9a;\">Swap</span>"
				var _fn10 = func():
					_beDoSwap(idx, JS.indexOf(b.get("spells"), sw.get("ref")))
				swBtn.onclick = _fn10
				swapList.appendChild(swBtn)
			expanded[0] = false
			var _fn11 = func():
				expanded[0] = (not (expanded[0]))
				swapList.style.display = ("flex" if expanded[0] else "none")
				var hint = document.getElementById(hintId)
				if JS.t(hint):
					hint.textContent = ("Full — swap ▴" if expanded[0] else "Full — swap ▾")
			bookBtn.onclick = _fn11
			wrap_.appendChild(bookBtn)
			wrap_.appendChild(swapList)
			cont.appendChild(wrap_)

# ── Move / swap executors ─────────────────────────────────────────────────────
func _beDoMove(destBookIdx = null):
	var item = _beMoveItem
	if (not JS.t(item) or not JS.eq(item.get("kind"), "spell")):
		return
	var src = JS.idx(State.player.get("spellbooks"), item.get("srcBookIdx"))
	var dest = JS.idx(State.player.get("spellbooks"), destBookIdx)
	if (not JS.t(src) or not JS.t(dest)):
		return
	src.spells = JS.arr(src.get("spells")).filter(func(s = null): return not JS.eq(s, item.get("spellObj")))
	dest.get("spells").append(item.get("spellObj"))
	if (JS.eq(item.get("srcBookIdx"), State.player.get("activeBookIdx")) or JS.eq(destBookIdx, State.player.get("activeBookIdx"))):
		State.syncActiveBook()
	_beMoveItem = null
	_beTab = destBookIdx
	_beRender()

func _beDoSwap(destBookIdx = null, destItemIdx = null):
	var item = _beMoveItem
	if (not JS.t(item) or not JS.eq(item.get("kind"), "spell")):
		return
	var src = JS.idx(State.player.get("spellbooks"), item.get("srcBookIdx"))
	var dest = JS.idx(State.player.get("spellbooks"), destBookIdx)
	if (not JS.t(src) or not JS.t(dest)):
		return
	var movingSpell = item.get("spellObj")
	var swapSpell = JS.idx(dest.get("spells"), destItemIdx)
	if not JS.t(swapSpell):
		return
	src.spells = JS.arr(src.get("spells")).filter(func(s = null): return not JS.eq(s, movingSpell))
	dest.spells = JS.arr(dest.get("spells")).filter(func(s = null): return not JS.eq(s, swapSpell))
	dest.get("spells").append(movingSpell)
	src.get("spells").append(swapSpell)
	if (JS.eq(item.get("srcBookIdx"), State.player.get("activeBookIdx")) or JS.eq(destBookIdx, State.player.get("activeBookIdx"))):
		State.syncActiveBook()
	_beMoveItem = null
	_beTab = destBookIdx
	_beRender()

# ── DOM helpers ───────────────────────────────────────────────────────────────
func _beSectionHdr(text = null):
	var d = document.createElement("div")
	d.style.cssText = "font-size:.58rem;color:#6a4a20;letter-spacing:.08em;text-transform:uppercase;margin:.6rem 0 .25rem;"
	d.textContent = text
	return d

func _beEmpty(text = null):
	var d = document.createElement("div")
	d.style.cssText = "font-size:.68rem;color:#3a3a3a;padding:.2rem 0 .4rem;"
	d.textContent = text
	return d

func _beItemRow(name_ = null, desc = null, onMove = null):
	var row = document.createElement("div")
	row.style.cssText = "display:flex;align-items:center;gap:.4rem;padding:.3rem .45rem;background:#0d0b09;border:1px solid #1a1512;border-radius:4px;margin-bottom:.2rem;"
	var info = document.createElement("div")
	info.style.cssText = "flex:1;min-width:0;"
	var nameEl = document.createElement("div")
	nameEl.style.cssText = "font-size:.7rem;color:#c8a060;font-family:'Cinzel',serif;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"
	nameEl.textContent = name_
	var descEl = document.createElement("div")
	descEl.style.cssText = "font-size:.58rem;color:#555;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"
	descEl.textContent = desc
	info.appendChild(nameEl)
	info.appendChild(descEl)
	var btn = document.createElement("button")
	btn.style.cssText = "flex:0 0 auto;background:#0a0806;border:1px solid #2a2010;color:#8a6a40;padding:.18rem .5rem;font-size:.58rem;cursor:pointer;border-radius:3px;white-space:nowrap;"
	btn.textContent = "Move →"
	btn.onclick = onMove
	row.appendChild(info)
	row.appendChild(btn)
	return row
