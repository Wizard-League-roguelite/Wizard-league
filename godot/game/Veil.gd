# Veil — generated from js/ui/veil.js by tools/js2gd.js
extends Node


func _boot():
	pass

# ===== veil.js =====
# ── The Veil UI ───────────────────────────────────────────────────────────────
func _veilIsUnlocked():
	return (not (not JS.t(Artifacts.getMeta().get("darkOneDefeated"))))

func openVeilPanel():
	var panel = document.getElementById("lobby-panel")
	var content = document.getElementById("lobby-panel-content")
	if (not JS.t(panel) or not JS.t(content)):
		return
	_renderVeilContent(content)
	panel.style.display = "block"

func _renderVeilContent(content = null):
	var html = [null]
	# ── Locked state — Ruined Portal ──
	if not _veilIsUnlocked():
		var isSandbox = Constants.sandboxMode
		var html_2 = "\n      <div class=\"lobby-panel-title\">Ruined Portal</div>\n      <canvas id=\"ruined-portal-preview\" style=\"display:block;margin:0 auto 14px;image-rendering:pixelated;border-radius:4px;\"></canvas>\n      <div style=\"color:#5a4a6a;font-size:.72rem;margin-bottom:10px;font-style:italic;line-height:1.6;text-align:center;\">\n        An ancient archway, crumbled and still.<br>Whatever power once lived here has long since faded.\n      </div>\n      <div style=\"text-align:center;color:#3a2844;font-size:.65rem;letter-spacing:.1em;text-transform:uppercase;\">\n        — nothing stirs within —\n      </div>\n    "
		if JS.t(isSandbox):
			html_2 += "\n        <div style=\"margin-top:20px;text-align:center;\">\n          <button onclick=\"sandboxUnlockVeil()\"\n            style=\"padding:.4rem 1.2rem;border-radius:4px;font-size:.63rem;cursor:pointer;\n            font-family:'Cinzel',serif;background:#0a0614;border:1px solid #5020a0;\n            color:#9060cc;letter-spacing:.06em;transition:all .15s;\">\n            🔬 Sandbox: Unlock Veil\n          </button>\n        </div>\n      "
		content.innerHTML = html_2
		_drawRuinedPortalPreview(document.getElementById("ruined-portal-preview"), content)
		return
	# ── Unlocked state — full Veil UI ──
	var cfg = Mist.getMistConfig()
	var totalMist = Mist.getTotalMist()
	html[0] = "\n    <div class=\"lobby-panel-title\">The Veil</div>\n    <div style=\"color:#9070cc;font-size:.72rem;margin-bottom:12px;font-style:italic;\">\n      Each burden you accept is another layer of Mist.\n    </div>\n    <div style=\"display:flex;align-items:center;gap:8px;margin-bottom:14px;padding:8px;\n                background:#120020;border:1px solid #4020aa;border-radius:6px;\">\n      <label style=\"display:flex;align-items:center;gap:8px;cursor:pointer;font-size:.8rem;\n                    color:" + ("#c080ff" if JS.t(cfg.get("active")) else "#776699") + ";\">\n        <input type=\"checkbox\" id=\"veil-active-toggle\" " + ("checked" if JS.t(cfg.get("active")) else "") + " style=\"accent-color:#8040cc;width:14px;height:14px;\">\n        <span>" + ("<b style=\"color:#c080ff;\">The Veil Active</b> — <span style=\"color:#e0a0ff;\">🌫 " + JS.s(totalMist) + " Mist</span>" if JS.t(cfg.get("active")) else "Enter the Veil") + "</span>\n      </label>\n    </div>\n  "
	var dimmed = ("" if JS.t(cfg.get("active")) else "opacity:.35;pointer-events:none;")
	for mod in JS.iter(Mist.MIST_MODIFIERS):
		var currentTier = JS.or_(JS.idx(cfg.get("modifiers"), mod.id), 0)
		html[0] += "\n      <div style=\"" + dimmed + "margin-bottom:8px;padding:8px 10px;background:#0e0018;\n                  border:1px solid " + ("#5030aa" if currentTier > 0 else "#241840") + ";border-radius:6px;\">\n        <div style=\"display:flex;justify-content:space-between;align-items:center;margin-bottom:5px;\">\n          <span style=\"font-size:.76rem;color:#c0a0ee;\">" + JS.s(mod.get("emoji")) + " " + JS.s(mod.get("label")) + "</span>\n          <span style=\"font-size:.65rem;color:" + ("#a070ff" if currentTier > 0 else "#554477") + ";\">\n            " + ("Tier " + JS.s(currentTier) + "/" + JS.s(mod.get("tiers")) if currentTier > 0 else "Off") + "\n          </span>\n        </div>\n        <div style=\"font-size:.65rem;color:" + ("#aa88dd" if currentTier > 0 else "#554477") + ";margin-bottom:6px;\">\n          " + JS.s((JS.callm(mod, "desc", [currentTier]) if currentTier > 0 else "Inactive")) + "\n        </div>\n        <div style=\"display:flex;gap:4px;flex-wrap:wrap;\">\n          <button onclick=\"setMistModifier('" + JS.s(mod.id) + "',0)\"\n            style=\"" + _veilBtnStyle(currentTier == 0, "off") + "\">Off</button>"
		for t in range(1, floori(mod.get("tiers")) + 1):
			var cost = JS.reduce(JS.slice(mod.get("mistCost"), 0, t), func(a = null, b = null): return a + b, 0)
			html[0] += "<button onclick=\"setMistModifier('" + JS.s(mod.id) + "'," + JS.s(t) + ")\"\n        style=\"" + _veilBtnStyle(currentTier == t, "tier") + "\">Tier " + JS.s(t) + " <span style=\"color:#9060cc\">(+" + JS.s(cost) + ")</span></button>"
		html[0] += "</div></div>"
	html[0] += "\n    <div style=\"margin-top:10px;padding:10px;background:#1a0030;border:1px solid #5020cc;\n                border-radius:6px;text-align:center;\">\n      <span style=\"font-size:.9rem;color:#c080ff;letter-spacing:.04em;\">\n        🌫 Total Mist: <b>" + JS.s(totalMist) + "</b>\n      </span>\n      " + ("<div style=\"font-size:.62rem;color:#554477;margin-top:3px;\">Activate the Veil to begin</div>" if JS.eq(totalMist, 0) else "") + "\n      " + ("<div style=\"margin-top:8px;\">\n        <button onclick=\"resetVeil()\" style=\"padding:4px 14px;border-radius:4px;font-size:.63rem;\n          cursor:pointer;font-family:'Cinzel',serif;background:#1a0010;border:1px solid #6020aa;\n          color:#886699;transition:all .15s;\">Reset All</button>\n      </div>" if JS.t(cfg.get("active")) else "") + "\n    </div>"
	content.innerHTML = html[0]
	var toggle = document.getElementById("veil-active-toggle")
	if JS.t(toggle):
		var _fn1 = func():
			var meta = Artifacts.getMeta()
			if not JS.t(meta.get("mistConfig")):
				meta.mistConfig = {"active": false, "modifiers": {}}
			meta.get("mistConfig").active = toggle.checked
			Artifacts.saveMeta()
			_renderVeilContent(content)
		toggle.onchange = _fn1

func _veilBtnStyle(active = null, type_ = null):
	var base = "padding:3px 9px;border-radius:4px;font-size:.63rem;cursor:pointer;\n                font-family:'Cinzel',serif;transition:all .15s;"
	if (JS.t(active) and type_ == "off"):
		return base + "background:#2a0040;border:1px solid #8040cc;color:#c080ff;"
	if JS.t(active):
		return base + "background:#4020aa;border:1px solid #c080ff;color:#fff;"
	return base + "background:#111;border:1px solid #2a1840;color:#554477;"

func setMistModifier(modId = null, tier = null):
	var meta = Artifacts.getMeta()
	if not JS.t(meta.get("mistConfig")):
		meta.mistConfig = {"active": true, "modifiers": {}}
	meta.get("mistConfig").get("modifiers")[modId] = tier
	Artifacts.saveMeta()
	var content = document.getElementById("lobby-panel-content")
	if JS.t(content):
		_renderVeilContent(content)

func resetVeil():
	var meta = Artifacts.getMeta()
	meta.mistConfig = {"active": false, "modifiers": {}}
	Artifacts.saveMeta()
	var content = document.getElementById("lobby-panel-content")
	if JS.t(content):
		_renderVeilContent(content)

# ── Ruined portal close-up preview in the locked panel ────────────────────────
func _drawRuinedPortalPreview(canvas = null, content = null):
	if not JS.t(canvas):
		return
	var panelW = (content.clientWidth if (JS.t(content) and JS.t(content.get("clientWidth"))) else 280)
	var size = min(220, panelW - 32)
	canvas.width = JS.round(size)
	canvas.height = JS.round(size * 1.05)
	canvas.style.width = JS.s(canvas.width) + "px"
	canvas.style.height = JS.s(canvas.height) + "px"
	var ctx = canvas.getContext("2d")
	var W = canvas.width
	var H = canvas.height
	# Dark stone background
	ctx.fillStyle = "#070510"
	ctx.fillRect(0, 0, W, H)
	# Ground line
	var groundY = H * 0.82
	ctx.fillStyle = "#0e0c14"
	ctx.fillRect(0, groundY, W, H - groundY)
	ctx.strokeStyle = "#1a1525"
	ctx.lineWidth = 1
	ctx.beginPath()
	ctx.moveTo(0, groundY)
	ctx.lineTo(W, groundY)
	ctx.stroke()
	LobbyMap._drawRuinedPortal(ctx, W / 2.0, groundY, W * 0.34, false)

# ── Veil unlock cinematic — plays when returning to lobby after Dark One defeat ──
func playVeilUnlockAnimation(onDone = null):
	var animTick = [null]
	var dismissed = [null]
	var animFrame = [null]
	var draw = [null]
	var overlay = document.getElementById("veil-unlock-overlay")
	if not JS.t(overlay):
		if JS.t(onDone):
			onDone.call()
		return
	animTick[0] = 0
	dismissed[0] = false
	animFrame[0] = null
	var canvas = document.getElementById("veil-unlock-canvas")
	var titleEl = document.getElementById("veil-unlock-title")
	var subEl = document.getElementById("veil-unlock-sub")
	if JS.t(titleEl):
		titleEl.textContent = "✦ VEIL UNLOCKED ✦"
		titleEl.style.opacity = "0"
	if JS.t(subEl):
		subEl.textContent = "Pass through to escape the mist"
		subEl.style.opacity = "0"
	var size = min(window.innerWidth * 0.65, 260)
	canvas.width = JS.round(size)
	canvas.height = JS.round(size * 1.1)
	canvas.style.width = JS.s(canvas.width) + "px"
	canvas.style.height = JS.s(canvas.height) + "px"
	overlay.style.display = "flex"
	var ctx = canvas.getContext("2d")
	var W = canvas.width
	var H = canvas.height
	var _fn2 = func():
		if dismissed[0]:
			return
		dismissed[0] = true
		if JS.t(animFrame[0]):
			JS.cancelAnimationFrame(animFrame[0])
			animFrame[0] = null
		overlay.style.display = "none"
		if JS.t(titleEl):
			titleEl.style.opacity = "0"
		if JS.t(subEl):
			subEl.style.opacity = "0"
		if JS.t(onDone):
			onDone.call()
	var dismiss = _fn2
	var _fn3 = func():
		if animTick[0] >= 100:
			dismiss.call()
	overlay.onclick = _fn3
	var _fn4 = func():
		animFrame[0] = JS.requestAnimationFrame(draw[0])
		animTick[0] += 1
		var t = animTick[0]
		if t >= 400:
			dismiss.call()
			return
		# Power phase: dead (0) → fully glowing (1) over frames 40–150
		var pp = max(0, min(1, (t - 40) / 110.0))
		# Background fade-in from black
		var bgA = min(1, t / 15.0)
		ctx.fillStyle = "rgba(1,0,8," + JS.s(bgA) + ")"
		ctx.fillRect(0, 0, W, H)
		_drawVeilAnimPortal(ctx, W / 2.0, H * 0.62, W * 0.3, pp, t)
		if JS.t(titleEl):
			titleEl.style.opacity = JS.s(max(0, min(1, (t - 165) / 25.0)))
		if JS.t(subEl):
			subEl.style.opacity = JS.s(max(0, min(1, (t - 200) / 25.0)))
	draw[0] = _fn4
	draw[0].call()

func _drawVeilAnimPortal(ctx = null, bx = null, by = null, bs = null, pp = null, t = null):
	var aw = bs * 1.4
	var ah = bs * 1.5
	var ax = bx - (aw / 2.0)
	var pulse = 0.5 + (0.5 * sin(t * 0.08))
	# Backdrop glow grows with power
	if pp > 0:
		var gA = pp * (0.25 + (pulse * 0.1))
		var glow = ctx.createRadialGradient(bx, by - (ah * 0.5), 0, bx, by - (ah * 0.5), aw * 1.0)
		glow.addColorStop(0, "rgba(120,40,220," + JS.s(gA) + ")")
		glow.addColorStop(1, "rgba(0,0,0,0)")
		ctx.fillStyle = glow
		ctx.fillRect(ax - (aw * 0.5), by - (ah * 1.2), aw * 2, ah * 1.8)
	# Stone colour: weathered grey → dark purple
	var sR = JS.round(42 + ((26 - 42) * pp))
	var sG = JS.round(37 + ((16 - 37) * pp))
	var sB = JS.round(53 + ((32 - 53) * pp))
	var stoneCol = "rgb(" + JS.s(sR) + "," + JS.s(sG) + "," + JS.s(sB) + ")"
	var strokeCol = ("rgba(58,32,96," + JS.s(pp * 0.8) + ")" if pp > 0.3 else "#403040")
	var pilW = aw * 0.18
	var pilH = ah * 0.85
	# Pillars
	ctx.fillStyle = stoneCol
	ctx.strokeStyle = strokeCol
	ctx.lineWidth = 1
	ctx.fillRect(ax, by - pilH, pilW, pilH)
	ctx.strokeRect(ax, by - pilH, pilW, pilH)
	ctx.fillRect((ax + aw) - pilW, by - pilH, pilW, pilH)
	ctx.strokeRect((ax + aw) - pilW, by - pilH, pilW, pilH)
	# Cracks fade out as portal powers up
	if pp < 0.9:
		var crA = (1 - (pp / 0.9)) * 0.55
		ctx.strokeStyle = "rgba(0,0,0," + JS.s(crA) + ")"
		ctx.lineWidth = 0.7
		ctx.beginPath()
		ctx.moveTo(ax + (pilW * 0.3), by - (pilH * 0.2))
		ctx.lineTo(ax + (pilW * 0.6), by - (pilH * 0.4))
		ctx.lineTo(ax + (pilW * 0.4), by - (pilH * 0.6))
		ctx.stroke()
		ctx.beginPath()
		ctx.moveTo((ax + aw) - (pilW * 0.4), by - (pilH * 0.35))
		ctx.lineTo((ax + aw) - (pilW * 0.7), by - (pilH * 0.55))
		ctx.stroke()
	# Arch top
	ctx.beginPath()
	ctx.arc(bx, (by - pilH) + (aw * 0.01), (aw * 0.5) - (pilW * 0.5), PI, 0)
	ctx.fillStyle = stoneCol
	ctx.fill()
	ctx.strokeStyle = strokeCol
	ctx.lineWidth = 1.2
	ctx.stroke()
	# Arch interior
	var innerR = aw * 0.36
	var innerGrad = ctx.createRadialGradient(bx, (by - pilH) + 2, 0, bx, by - pilH, innerR)
	if pp > 0:
		innerGrad.addColorStop(0, "rgba(90,20,180," + JS.s((0.5 + (pp * 0.3)) + ((pulse * 0.15) * pp)) + ")")
		innerGrad.addColorStop(0.6, "rgba(40,8,100," + JS.s(0.6 * pp) + ")")
		innerGrad.addColorStop(1, "rgba(0,0,0,0.5)")
	else:
		innerGrad.addColorStop(0, "rgba(8,4,12,0.9)")
		innerGrad.addColorStop(1, "rgba(0,0,0,0.6)")
	ctx.beginPath()
	ctx.arc(bx, (by - pilH) + (aw * 0.01), innerR, PI, 0)
	ctx.fillStyle = innerGrad
	ctx.fill()
	# Mist wisps appear after portal powers up
	if pp > 0.35:
		var mA = (pp - 0.35) / 0.65
		for i in range(3):
			var wx = bx + ((sin((t * 0.05) + (i * 2.1)) * aw) * 0.18)
			var wy = ((by - (pilH * 0.3)) - ((i * ah) * 0.13)) + ((cos((t * 0.04) + i) * ah) * 0.06)
			var wr = bs * (0.12 + (0.05 * sin((t * 0.05) + i)))
			var mg = ctx.createRadialGradient(wx, wy, 0, wx, wy, wr)
			mg.addColorStop(0, "rgba(160,80,255," + JS.s(mA * (0.25 + (pulse * 0.15))) + ")")
			mg.addColorStop(1, "rgba(0,0,0,0)")
			ctx.fillStyle = mg
			ctx.fillRect(wx - wr, wy - wr, wr * 2, wr * 2)
	# Keystone gem
	var gemY = (by - pilH) - (aw * 0.12)
	ctx.beginPath()
	ctx.arc(bx, gemY, bs * 0.09, 0, PI * 2)
	if pp > 0:
		ctx.fillStyle = "rgba(180,80,255," + JS.s((0.35 + (pp * 0.55)) + ((pulse * 0.1) * pp)) + ")"
		ctx.fill()
		ctx.strokeStyle = ("#e0a0ff" if pp > 0.5 else "#7040b0")
		ctx.lineWidth = 0.8
		ctx.stroke()
	else:
		ctx.fillStyle = "rgba(42,34,48,0.8)"
		ctx.fill()
		ctx.strokeStyle = "#302838"
		ctx.lineWidth = 0.8
		ctx.stroke()
	# Converging energy particles during power-up
	if (pp > 0 and pp < 1):
		var numP = 10
		for i in range(ceili(numP)):
			var angle = (((i / float(numP)) * PI) * 2) + (t * 0.04)
			var dist = ((1 - pp) * aw) * 1.3
			var px = bx + (cos(angle) * dist)
			var py = (by - (pilH * 0.5)) + ((sin(angle) * dist) * 0.5)
			ctx.fillStyle = "rgba(180,80,255," + JS.s(pp * 0.7) + ")"
			ctx.beginPath()
			ctx.arc(px, py, 1.5, 0, PI * 2)
			ctx.fill()
