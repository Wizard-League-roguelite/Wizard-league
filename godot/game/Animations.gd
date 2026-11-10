# Animations — generated from js/rendering/animations.js by tools/js2gd.js
extends Node

var ACTIVE_ANIMS = null
# ─── Screen-level flash overlay ───────────────────────────────────────────────
var _flashR = 0
var _flashG = 0
var _flashB = 0
var _flashAlpha = 0
var ANIM_DEFS = null
# ═══ CAMPFIRE SCENE ════════════════════════════════════════════════════════════
# Full animated rest scene: player sitting by crackling campfire, night sky.
var _cfRAF = null
var _cfTick = 0
var _cfHealText = ""
var SPRITE_PLAYER_SITTING = null
var SPRITE_CF_LOGS = null
var SPRITE_CF_FLAME_A = null
var SPRITE_CF_FLAME_B = null
var SPRITE_CF_FLAME_C = null

func _boot():
	# ===== animations.js =====
	# ─── ANIMATIONS — Spell / battle visual effects ───────────────────────────────
	# Non-blocking. Game state updates instantly; animations are purely cosmetic.
	# tickAnims(ctx, W, H) is called from renderBattlefield() each rAF frame.
	ACTIVE_ANIMS = []
	# ─── Per-element / per-type animation definitions ─────────────────────────────
	ANIM_DEFS = {
		"Fire": {"type": "fireball", "dur": 30, "c1": "#FF6622", "c2": "#FF2200", "burst": "#FFCC44", "glow": "#FF5500"},
		"Water": {"type": "water_wave", "dur": 32, "c1": "#44AAFF", "c2": "#0066DD", "burst": "#AADEFF", "glow": "#2288EE"},
		"Ice": {"type": "ice_shards", "dur": 30, "c1": "#CCEFFF", "c2": "#33AACC", "burst": "#FFFFFF", "glow": "#88CCEE"},
		"Lightning": {"type": "lightning", "dur": 18, "c1": "#FFEE22", "c2": "#FFAA00", "burst": "#FFFFFF", "glow": "#FFFF66"},
		"Earth": {"type": "earth_slam", "dur": 36, "c1": "#CC9933", "c2": "#664400", "burst": "#EEDD88", "glow": "#AA7700"},
		"Nature": {"type": "vine_lash", "dur": 32, "c1": "#44EE55", "c2": "#118833", "burst": "#AAFFAA", "glow": "#33BB44"},
		"Plasma": {"type": "plasma_orb", "dur": 30, "c1": "#EE44FF", "c2": "#8800BB", "burst": "#FF88FF", "glow": "#CC00EE"},
		"Air": {"type": "wind_slash", "dur": 24, "c1": "#AAEEFF", "c2": "#55AACC", "burst": "#EEFFFF", "glow": "#77CCEE"},
		"Neutral": {"type": "arc", "dur": 22, "count": 8, "spread": 12, "c1": "#CCCCCC", "c2": "#888888", "burst": "#FFFFFF"},
		"heal": {"type": "rise", "dur": 34, "count": 12, "spread": 16, "c1": "#44DD66", "c2": "#118833", "burst": "#AAFFAA"},
		"block": {"type": "shield", "dur": 26, "c1": "#DDAA22", "c2": "#AA7700", "burst": "#FFEE88"},
		"armor": {"type": "shield", "dur": 22, "c1": "#888888", "c2": "#555555", "burst": "#CCCCCC"},
	}
	# Seated player sprite (back-left view, legs tucked to the right)
	SPRITE_PLAYER_SITTING = [
		"....hhhhh...",
		"...hhhhhhh..",
		"..3hhhhhhh..",
		"...ssssss...",
		"...111111...",
		"..11111111..",
		".1111111111.",
		"111111111111",
		"111222222111",
		"111222222111",
		"111222222bbb",
		".......bbbbb",
	]
	# Campfire structure sprite (12-col, drawn large)
	SPRITE_CF_LOGS = ["..3.....3...", ".333...333..", "3333.3.3333.", "333333333333", "222222222222", "212122212122"]
	SPRITE_CF_FLAME_A = ["....3111....", "...311113...", "..31111113..", ".3111111113.", "..31111113..", "...311113..."]
	SPRITE_CF_FLAME_B = [".....111....", "....11113...", "...3111113..", "..311111113.", "...3111113..", "....31113..."]
	SPRITE_CF_FLAME_C = ["....3113....", "...311113...", "...311113...", "..31111113..", ".311111113..", "..311111...."]

func _triggerFlash(r = null, g = null, b = null, a = null):
	_flashR = r
	_flashG = g
	_flashB = b
	_flashAlpha = max(_flashAlpha, a)

# ─── Bloom / glow: layered semi-transparent circles ───────────────────────────
func _glow(ctx = null, x = null, y = null, r = null, color = null, alpha = null):
	if (alpha <= 0 or r <= 0):
		return
	ctx.save()
	ctx.fillStyle = color
	ctx.globalAlpha = max(0, alpha * 0.1)
	ctx.beginPath()
	ctx.arc(x, y, r * 3.8, 0, PI * 2)
	ctx.fill()
	ctx.globalAlpha = max(0, alpha * 0.2)
	ctx.beginPath()
	ctx.arc(x, y, r * 2.2, 0, PI * 2)
	ctx.fill()
	ctx.globalAlpha = max(0, alpha * 0.55)
	ctx.beginPath()
	ctx.arc(x, y, r, 0, PI * 2)
	ctx.fill()
	ctx.restore()

# ─── Shockwave / expanding ring ───────────────────────────────────────────────
func _ring(ctx = null, x = null, y = null, r = null, color = null, alpha = null, lw = null):
	if (alpha <= 0 or r <= 0):
		return
	ctx.save()
	ctx.globalAlpha = max(0, alpha)
	ctx.strokeStyle = color
	ctx.lineWidth = JS.or_(lw, 2)
	ctx.beginPath()
	ctx.arc(x, y, r, 0, PI * 2)
	ctx.stroke()
	ctx.restore()

# ─── Particle factory (for arc / rise types) ──────────────────────────────────
func _makeParticles(count = null, spread = null):
	var ps = []
	for i in range(ceili(count)):
		ps.append({
			"offset": (i / float(count)) * (-0.2),
			"yOff": (JS.mod((i * 137) + 31, (spread * 2) + 1)) - spread,
			"size": 2 + (JS.mod(i, 3)),
			"alpha": 0.55 + ((JS.mod(i, 4)) * 0.12),
		})
	return ps

# ─── Arc path position helper ─────────────────────────────────────────────────
func _arcPt(from = null, to = null, p = null):
	p = max(0, min(1, p))
	var x = from.get("x") + ((to.get("x") - from.get("x")) * p)
	var y0 = from.get("y") + ((to.get("y") - from.get("y")) * p)
	var arc = -((abs(to.get("x") - from.get("x")) * 0.22) + 10)
	return {"x": x, "y": y0 + (arc * sin(p * PI))}

# ─── Public API ───────────────────────────────────────────────────────────────
func triggerSpellAnim(abilityElement = null, attackerSide = null, targetEnemyIdx = null):
	if JS.hooks.has("triggerSpellAnim"):
		return JS.run_hook("triggerSpellAnim", [abilityElement, attackerSide, targetEnemyIdx])
	var def = JS.or_(JS.idx(ANIM_DEFS, abilityElement), ANIM_DEFS.get("Neutral"))
	var needsParticles = (def.get("type") == "arc" or def.get("type") == "rise")
	ACTIVE_ANIMS.append(JS.merge([def, {
		"particles": (_makeParticles(JS.or_(def.get("count"), 7), JS.or_(def.get("spread"), 8)) if needsParticles else []),
		"attackerSide": attackerSide,
		"targetEnemyIdx": (targetEnemyIdx if targetEnemyIdx != null else JS.or_(State.combat.get("activeEnemyIdx"), 0)),
		"t": 0,
	}]))

func triggerHealAnim():
	if JS.hooks.has("triggerHealAnim"):
		return JS.run_hook("triggerHealAnim", [])
	var def = ANIM_DEFS.get("heal")
	ACTIVE_ANIMS.append(JS.merge([def, {
		"particles": _makeParticles(def.get("count"), def.get("spread")),
		"attackerSide": "player",
		"targetEnemyIdx": -1,
		"t": 0,
	}]))

func triggerBlockAnim(variant = null):
	var def = JS.or_(JS.idx(ANIM_DEFS, variant), ANIM_DEFS.get("block"))
	ACTIVE_ANIMS.append(JS.merge([def, {"particles": [], "attackerSide": "player", "targetEnemyIdx": -1, "t": 0}]))

# ─── Position helpers ─────────────────────────────────────────────────────────
func _spriteCenter(side = null, enemyIdx = null, W = null, H = null):
	if side == "player":
		var p = Sprites.playerSpritePos(W, H)
		return {"x": p.get("x") + (p.get("w") / 2.0), "y": p.get("y") + (p.get("h") / 2.0)}
		return {"x": W * 0.15, "y": H * 0.7}
	var allE = JS.or_(State.combat.get("enemies"), [])
	var ep = Sprites.enemySpritePos(enemyIdx, allE, W, H)
	return {"x": ep.get("x") + (ep.get("w") / 2.0), "y": ep.get("y") + (ep.get("h") / 2.0)}
	return {"x": W * 0.72, "y": H * 0.38}

# ─── FIRE: Glowing fireball with ember trail + explosion ──────────────────────
func _drawFireball(ctx = null, a = null, W = null, H = null):
	var from = _spriteCenter(a.get("attackerSide"), a.get("targetEnemyIdx"), W, H)
	var toSide = ("enemy" if a.get("attackerSide") == "player" else "player")
	var to = _spriteCenter(toSide, a.get("targetEnemyIdx"), W, H)
	var prog = a.get("t") / float(a.get("dur"))
	var HIT = 0.76
	if prog < HIT:
		var p = prog / float(HIT)
		var pos = _arcPt(from, to, p)
		var env = sin(p * PI)
		# Ember trail (faded past positions)
		for i in range(10, 1 - 1, -1):
			var tp = max(0, p - (i * 0.038))
			var tPos = _arcPt(from, to, tp)
			var ta = ((1 - (i / 11.0)) * 0.55) * env
			var sz = max(0.5, (10 - i) * 0.55)
			ctx.save()
			ctx.globalAlpha = ta
			ctx.fillStyle = ("#FFEE44" if i <= 3 else (a.get("c1") if i <= 6 else a.get("c2")))
			ctx.beginPath()
			ctx.arc(tPos.get("x"), tPos.get("y"), sz, 0, PI * 2)
			ctx.fill()
			ctx.restore()
		# Pulsing glow orb
		var pulse = 1 + (0.18 * sin(a.get("t") * 0.55))
		_glow(ctx, pos.get("x"), pos.get("y"), 11 * pulse, a.get("glow"), env * 0.9)
		# Bright core
		ctx.save()
		ctx.globalAlpha = env
		ctx.fillStyle = "#FFEEAA"
		ctx.beginPath()
		ctx.arc(pos.get("x"), pos.get("y"), 4.5, 0, PI * 2)
		ctx.fill()
		ctx.restore()
	if prog >= HIT:
		var bp = (prog - HIT) / float((1 - HIT))
		var bp2 = 1 - bp
		# Screen flash — orange-red
		if bp < 0.18:
			_triggerFlash(255, 110, 20, bp2 * 0.2)
		# Central glow burst
		_glow(ctx, to.get("x"), to.get("y"), 22 * (1 - (bp * 0.35)), a.get("burst"), bp2 * 0.95)
		# Expanding shockwave rings
		_ring(ctx, to.get("x"), to.get("y"), bp * 38, a.get("c1"), bp2 * 0.85, 3.0)
		_ring(ctx, to.get("x"), to.get("y"), bp * 24, a.get("burst"), bp2 * 0.55, 1.5)
		# Ember sparks flying outward with gravity
		for i in range(18):
			var angle = (((i / 18.0) * PI) * 2) + 0.4
			var speed = 22 + ((JS.mod(i, 5)) * 8)
			var grav = (bp * bp) * 14
			var ex = to.get("x") + ((cos(angle) * speed) * bp)
			var ey = (to.get("y") + ((sin(angle) * speed) * bp)) + grav
			var sz = max(1, 3.5 - (bp * 3))
			ctx.save()
			ctx.globalAlpha = bp2 * 0.9
			ctx.fillStyle = ("#FFEE00" if (JS.mod(i, 3)) == 0 else (a.get("c1") if (JS.mod(i, 3)) == 1 else a.get("c2")))
			ctx.fillRect(JS.round(ex) - 1, JS.round(ey) - 1, sz + 1, sz + 1)
			ctx.restore()

# ─── LIGHTNING: Instant branching bolt + electric sparks ──────────────────────
func _drawLightning(ctx = null, a = null, W = null, H = null):
	var from = _spriteCenter(a.get("attackerSide"), a.get("targetEnemyIdx"), W, H)
	var toSide = ("enemy" if a.get("attackerSide") == "player" else "player")
	var to = _spriteCenter(toSide, a.get("targetEnemyIdx"), W, H)
	var prog = a.get("t") / float(a.get("dur"))
	var fade = (1 if prog < 0.2 else max(0, 1 - ((prog - 0.2) / 0.8)))
	# Screen flash on very first frame
	if a.get("t") <= 1:
		_triggerFlash(255, 255, 180, 0.3)
	# Helper: draw a jittered zigzag segment
	var _fn1 = func(x1 = null, y1 = null, x2 = null, y2 = null, segs = null, amp = null, lw = null, col = null, al = null):
		if (al * fade) <= 0:
			return
		ctx.save()
		ctx.globalAlpha = max(0, al * fade)
		ctx.strokeStyle = col
		ctx.lineWidth = lw
		ctx.beginPath()
		ctx.moveTo(x1, y1)
		for i in range(1, floori(segs) + 1):
			var t = i / float(segs)
			var bx = x1 + ((x2 - x1) * t)
			var by = y1 + ((y2 - y1) * t)
			var j = ((JS.mod(((i * 173) + 7) + (a.get("t") * 3), (amp * 2) + 1)) - amp if i < segs else 0)
			ctx.lineTo(JS.round(bx + j), JS.round(by - (j * 0.5)))
		ctx.stroke()
		ctx.restore()
	var zigzag = _fn1
	# Outer glow (wide, faint)
	zigzag.call(from.get("x"), from.get("y"), to.get("x"), to.get("y"), 8, 14, 8, "rgba(255,230,50,0.18)", 1)
	# Mid bolt
	zigzag.call(from.get("x"), from.get("y"), to.get("x"), to.get("y"), 8, 12, 3, a.get("c1"), 0.95)
	# Inner white core
	zigzag.call(from.get("x"), from.get("y"), to.get("x"), to.get("y"), 8, 10, 1.5, "#FFFFFF", 1.0)
	# Branch 1 — splits off at ~35% toward target
	var b1x = from.get("x") + ((to.get("x") - from.get("x")) * 0.35)
	var b1y = from.get("y") + ((to.get("y") - from.get("y")) * 0.35)
	var b1ex = (b1x + ((to.get("y") - from.get("y")) * 0.3)) + 24
	var b1ey = (b1y - ((to.get("x") - from.get("x")) * 0.12)) + 18
	zigzag.call(b1x, b1y, b1ex, b1ey, 4, 8, 1.8, a.get("c1"), 0.65)
	zigzag.call(b1x, b1y, b1ex, b1ey, 4, 6, 0.9, "#FFFFFF", 0.75)
	# Branch 2 — splits off at ~62%
	var b2x = from.get("x") + ((to.get("x") - from.get("x")) * 0.62)
	var b2y = from.get("y") + ((to.get("y") - from.get("y")) * 0.62)
	var b2ex = (b2x - ((to.get("y") - from.get("y")) * 0.22)) - 18
	var b2ey = (b2y + ((to.get("x") - from.get("x")) * 0.08)) + 14
	zigzag.call(b2x, b2y, b2ex, b2ey, 4, 9, 1.4, a.get("c1"), 0.5)
	# Impact glow + radiating sparks
	var impFade = (1 if prog < 0.45 else max(0, 1 - ((prog - 0.45) / 0.55)))
	_glow(ctx, to.get("x"), to.get("y"), 15, a.get("glow"), impFade * 0.9)
	for i in range(10):
		var angle = (((i / 10.0) * PI) * 2) + (a.get("t") * 0.45)
		var dist = (9 + ((JS.mod(i, 3)) * 6)) * (0.8 + (prog * 0.6))
		ctx.save()
		ctx.globalAlpha = max(0, impFade * 0.75)
		ctx.strokeStyle = "#FFFF66"
		ctx.lineWidth = 1
		ctx.beginPath()
		ctx.moveTo(to.get("x"), to.get("y"))
		ctx.lineTo(JS.round(to.get("x") + (cos(angle) * dist)), JS.round(to.get("y") + (sin(angle) * dist)))
		ctx.stroke()
		ctx.restore()

# ─── ICE: Staggered crystal shards + shatter burst ───────────────────────────
func _drawIceShards(ctx = null, a = null, W = null, H = null):
	var from = _spriteCenter(a.get("attackerSide"), a.get("targetEnemyIdx"), W, H)
	var toSide = ("enemy" if a.get("attackerSide") == "player" else "player")
	var to = _spriteCenter(toSide, a.get("targetEnemyIdx"), W, H)
	var prog = a.get("t") / float(a.get("dur"))
	var SHARDS = 5
	var angle = atan2(to.get("y") - from.get("y"), to.get("x") - from.get("x"))
	for si in range(ceili(SHARDS)):
		var delay = si * 0.055
		var sp = max(0, (prog - delay) / float((1 - delay)))
		if sp <= 0:
			continue
		var HIT = 0.78
		var yOff = (JS.mod((si * 137) + 31, 13)) - 6
		var fromOff = {"x": from.get("x"), "y": from.get("y") + yOff}
		var toOff = {"x": to.get("x"), "y": to.get("y") + (yOff * 0.3)}
		if sp < HIT:
			var p = sp / float(HIT)
			var pos = _arcPt(fromOff, toOff, p)
			var env = sin(p * PI)
			# Elongated crystal shard (rotated rect)
			ctx.save()
			ctx.globalAlpha = env * 0.88
			ctx.translate(JS.round(pos.get("x")), JS.round(pos.get("y")))
			ctx.rotate(angle)
			ctx.fillStyle = a.get("c2")
			ctx.fillRect(-6, -2, 12, 4)
			ctx.fillStyle = a.get("c1")
			ctx.fillRect(-6, -2, 10, 2)
			ctx.fillStyle = "#FFFFFF"
			ctx.fillRect(-5, -2, 6, 1)
			# glint
			ctx.restore()
			# Ice-dust trail
			if p > 0.15:
				var tPos = _arcPt(fromOff, toOff, max(0, p - 0.13))
				ctx.save()
				ctx.globalAlpha = (1 - p) * 0.45
				ctx.fillStyle = a.get("burst")
				ctx.fillRect(JS.round(tPos.get("x")) - 1, JS.round(tPos.get("y")) - 1, 3, 2)
				ctx.restore()
		else:
			# Shatter
			var bp = (sp - HIT) / float((1 - HIT))
			var bp2 = 1 - bp
			if bp2 <= 0:
				continue
			for i in range(8):
				var sAngle = (((i / 8.0) * PI) * 2) + (si * 0.9)
				var dist = (10 + (i * 4.5)) * bp
				var grav = (bp * bp) * 8
				ctx.save()
				ctx.globalAlpha = bp2 * 0.85
				ctx.fillStyle = (a.get("c1") if (JS.mod(i, 2)) == 0 else a.get("burst"))
				ctx.fillRect(JS.round(to.get("x") + (cos(sAngle) * dist)) - 1, JS.round((to.get("y") + (sin(sAngle) * dist)) + grav) - 1, 2, 3)
				ctx.restore()
			_ring(ctx, to.get("x"), to.get("y"), (bp * 20) + (si * 2), a.get("c2"), bp2 * 0.55, 1.5)
	# Frost sparkle lingers at impact
	if prog > 0.68:
		var fp = (prog - 0.68) / 0.32
		_glow(ctx, to.get("x"), to.get("y"), 13 * (1 - (fp * 0.4)), a.get("burst"), (1 - fp) * 0.75)

# ─── WATER: Sinusoidal wave stream + bubble splash ────────────────────────────
func _drawWaterWave(ctx = null, a = null, W = null, H = null):
	var from = _spriteCenter(a.get("attackerSide"), a.get("targetEnemyIdx"), W, H)
	var toSide = ("enemy" if a.get("attackerSide") == "player" else "player")
	var to = _spriteCenter(toSide, a.get("targetEnemyIdx"), W, H)
	var prog = a.get("t") / float(a.get("dur"))
	var HIT = 0.74
	# Sinusoidal stream of water drops
	var DROPS = 14
	for i in range(ceili(DROPS)):
		var delay = (i / float(DROPS)) * (-0.22)
		var dp = min(1, max(0, prog + delay))
		if (dp <= 0 or dp >= 1):
			continue
		var wave = sin(((dp * PI) * 3) + (i * 0.9)) * 9
		var base = _arcPt(from, to, dp)
		var env = sin(dp * PI)
		var sz = 2.5 + ((JS.mod(i, 4)) * 0.4)
		ctx.save()
		ctx.globalAlpha = env * (0.5 + ((JS.mod(i, 3)) * 0.14))
		ctx.fillStyle = (a.get("c1") if dp < 0.55 else a.get("c2"))
		ctx.beginPath()
		ctx.arc(base.get("x"), base.get("y") + wave, sz, 0, PI * 2)
		ctx.fill()
		ctx.restore()
	if prog >= HIT:
		var bp = (prog - HIT) / float((1 - HIT))
		var bp2 = 1 - bp
		_glow(ctx, to.get("x"), to.get("y"), 18, a.get("glow"), bp2 * 0.85)
		_ring(ctx, to.get("x"), to.get("y"), bp * 28, a.get("c1"), bp2 * 0.85, 2.5)
		_ring(ctx, to.get("x"), to.get("y"), bp * 16, a.get("burst"), bp2 * 0.5, 1.0)
		# Upward bubbles
		for i in range(9):
			var age = bp - (i * 0.07)
			if age <= 0:
				continue
			var bx = (to.get("x") + (JS.mod((i * 37) + 7, 22))) - 11
			var by = (to.get("y") - (age * 28)) - (i * 2)
			var br = 2 + (JS.mod(i, 3))
			ctx.save()
			ctx.globalAlpha = max(0, 1 - (age * 2.2)) * 0.72
			ctx.strokeStyle = a.get("burst")
			ctx.lineWidth = 1
			ctx.beginPath()
			ctx.arc(bx, by, br, 0, PI * 2)
			ctx.stroke()
			ctx.restore()
		# Upward droplet spray
		for i in range(12):
			var dAngle = ((-PI) * 0.75) + (((i / 12.0) * PI) * 1.5)
			var dist = (14 + (i * 2.5)) * bp
			var grav = (bp * bp) * 15
			ctx.save()
			ctx.globalAlpha = bp2 * 0.8
			ctx.fillStyle = (a.get("c1") if (JS.mod(i, 2)) == 0 else a.get("burst"))
			ctx.fillRect(JS.round(to.get("x") + (cos(dAngle) * dist)) - 1, JS.round((to.get("y") + (sin(dAngle) * dist)) + grav) - 1, 2, 2)
			ctx.restore()

# ─── EARTH: Tumbling rocks with dust + shockwave ──────────────────────────────
func _drawEarthSlam(ctx = null, a = null, W = null, H = null):
	var from = _spriteCenter(a.get("attackerSide"), a.get("targetEnemyIdx"), W, H)
	var toSide = ("enemy" if a.get("attackerSide") == "player" else "player")
	var to = _spriteCenter(toSide, a.get("targetEnemyIdx"), W, H)
	var prog = a.get("t") / float(a.get("dur"))
	var HIT = 0.7
	var ROCKS = 3
	for ri in range(ceili(ROCKS)):
		var delay = ri * 0.075
		var rp = max(0, (prog - delay) / float((1 - delay)))
		if rp <= 0:
			continue
		var yOff = (JS.mod((ri * 97) + 13, 9)) - 4
		var fromOff = {"x": from.get("x"), "y": from.get("y") + yOff}
		var toOff = {"x": to.get("x"), "y": to.get("y")}
		if rp < HIT:
			var p = rp / float(HIT)
			var pos = _arcPt(fromOff, toOff, p)
			var env = sin(p * PI)
			var spin = (p * 5) + (ri * 1.2)
			# Dust cloud trail
			for ti in range(1, 4 + 1):
				var tp = max(0, p - (ti * 0.05))
				var tPos = _arcPt(fromOff, toOff, tp)
				ctx.save()
				ctx.globalAlpha = ((1 - (ti / 5.0)) * 0.28) * env
				ctx.fillStyle = "#AA8844"
				ctx.beginPath()
				ctx.arc(tPos.get("x"), tPos.get("y"), 4 + (ti * 1.5), 0, PI * 2)
				ctx.fill()
				ctx.restore()
			# Rock chunk (rotated rect with highlight)
			var rw = 7 + (ri * 3)
			var rh = 5 + (ri * 2)
			ctx.save()
			ctx.globalAlpha = env * 0.92
			ctx.translate(JS.round(pos.get("x")), JS.round(pos.get("y")))
			ctx.rotate(spin)
			ctx.fillStyle = a.get("c2")
			ctx.fillRect((-rw) / 2.0, (-rh) / 2.0, rw, rh)
			ctx.fillStyle = a.get("c1")
			ctx.fillRect((-rw) / 2.0, (-rh) / 2.0, rw, 2)
			ctx.restore()
		else:
			var bp = (rp - HIT) / float((1 - HIT))
			var bp2 = 1 - bp
			if bp2 <= 0:
				continue
			# Debris scatter with gravity
			for i in range(9):
				var dAngle = (((i / 9.0) * PI) * 2) + (ri * 1.3)
				var dist = (10 + (i * 4.5)) * bp
				var grav = (bp * bp) * 18
				ctx.save()
				ctx.globalAlpha = bp2 * 0.88
				ctx.fillStyle = (a.get("c1") if (JS.mod(i, 2)) == 0 else a.get("c2"))
				ctx.fillRect(JS.round((to.get("x") + (cos(dAngle) * dist)) + (yOff * 0.4)) - 1, JS.round((to.get("y") + (sin(dAngle) * dist)) + grav) - 1, 3, 2)
				ctx.restore()
			# Dust cloud at impact
			_glow(ctx, to.get("x"), to.get("y"), 16 * bp2, "#BB9944", bp2 * 0.55)
			# Shockwave ring on first rock impact only
			if ri == 0:
				_ring(ctx, to.get("x"), to.get("y"), bp * 32, a.get("burst"), bp2 * 0.8, 2.5)
				_ring(ctx, to.get("x"), to.get("y"), bp * 20, a.get("c1"), bp2 * 0.4, 1.2)

# ─── NATURE: Growing vine tendrils + thorn burst ─────────────────────────────
func _drawVineLash(ctx = null, a = null, W = null, H = null):
	var from = _spriteCenter(a.get("attackerSide"), a.get("targetEnemyIdx"), W, H)
	var toSide = ("enemy" if a.get("attackerSide") == "player" else "player")
	var to = _spriteCenter(toSide, a.get("targetEnemyIdx"), W, H)
	var prog = a.get("t") / float(a.get("dur"))
	var HIT = 0.7
	# Vine grows from attacker toward target
	if prog < (HIT + 0.1):
		var drawFrac = min(1, prog / float(HIT))
		var SEGS = 18
		# Shadow vine (dark, offset)
		ctx.save()
		ctx.strokeStyle = a.get("c2")
		ctx.lineWidth = 3
		ctx.globalAlpha = 0.75
		ctx.beginPath()
		var i = 0
		while i <= JS.round(SEGS * drawFrac):
			var p = i / float(SEGS)
			var pt = _arcPt(from, to, p)
			var wig = (sin(((p * PI) * 3.5) + (a.get("t") * 0.18)) * 6) * sin(p * PI)
			if i == 0:
				ctx.moveTo(pt.get("x"), pt.get("y") + wig)
			else:
				ctx.lineTo(pt.get("x"), pt.get("y") + wig)
			i += 1
		ctx.stroke()
		# Highlight vine (brighter, thinner)
		ctx.strokeStyle = a.get("c1")
		ctx.lineWidth = 1.5
		ctx.globalAlpha = 0.6
		ctx.stroke()
		ctx.restore()
		# Leaf clusters along vine
		for i_2 in range(7):
			var lp = (i_2 / 7.0) * drawFrac
			if lp <= 0:
				continue
			var lPos = _arcPt(from, to, lp)
			var wig = (sin(((lp * PI) * 3.5) + (a.get("t") * 0.18)) * 6) * sin(lp * PI)
			ctx.save()
			ctx.globalAlpha = 0.78
			ctx.fillStyle = (a.get("c1") if (JS.mod(i_2, 2)) == 0 else a.get("c2"))
			ctx.fillRect(JS.round(lPos.get("x")) - 2, JS.round(lPos.get("y") + wig) - 2, 5, 3)
			ctx.restore()
	# Impact: thorn burst + leaf scatter
	if prog > HIT:
		var bp = (prog - HIT) / float((1 - HIT))
		var bp2 = 1 - bp
		_glow(ctx, to.get("x"), to.get("y"), 15, a.get("glow"), bp2 * 0.85)
		# Thorn spikes radiating outward
		for i in range(12):
			var sAngle = (((i / 12.0) * PI) * 2) + 0.4
			var len_ = (15 + ((JS.mod(i, 3)) * 7)) * bp
			ctx.save()
			ctx.globalAlpha = bp2 * 0.88
			ctx.strokeStyle = (a.get("c1") if (JS.mod(i, 2)) == 0 else a.get("c2"))
			ctx.lineWidth = max(0.5, 2.2 - (bp * 1.5))
			ctx.beginPath()
			ctx.moveTo(to.get("x"), to.get("y"))
			ctx.lineTo(JS.round(to.get("x") + (cos(sAngle) * len_)), JS.round(to.get("y") + (sin(sAngle) * len_)))
			ctx.stroke()
			ctx.restore()
		# Leaf scatter with gravity
		for i in range(10):
			var lAngle = (((i / 10.0) * PI) * 2) + 1.1
			var dist = (14 + (i * 4)) * bp
			var grav = (bp * bp) * 10
			ctx.save()
			ctx.globalAlpha = bp2 * 0.82
			ctx.fillStyle = (a.get("c1") if (JS.mod(i, 2)) == 0 else a.get("c2"))
			ctx.fillRect(JS.round(to.get("x") + (cos(lAngle) * dist)) - 1, JS.round((to.get("y") + (sin(lAngle) * dist)) + grav) - 1, 4, 3)
			ctx.restore()

# ─── PLASMA: Pulsing orb with orbiting satellites + ring explosion ─────────────
func _drawPlasmaOrb(ctx = null, a = null, W = null, H = null):
	var from = _spriteCenter(a.get("attackerSide"), a.get("targetEnemyIdx"), W, H)
	var toSide = ("enemy" if a.get("attackerSide") == "player" else "player")
	var to = _spriteCenter(toSide, a.get("targetEnemyIdx"), W, H)
	var prog = a.get("t") / float(a.get("dur"))
	var HIT = 0.74
	if prog < HIT:
		var p = prog / float(HIT)
		var pos = _arcPt(from, to, p)
		var env = sin(p * PI)
		var pulse = 1 + (0.22 * sin(a.get("t") * 0.55))
		# Energy trail
		for i in range(6, 1 - 1, -1):
			var tp = max(0, p - (i * 0.038))
			var tPos = _arcPt(from, to, tp)
			ctx.save()
			ctx.globalAlpha = ((1 - (i / 7.0)) * 0.42) * env
			ctx.fillStyle = a.get("c2")
			ctx.beginPath()
			ctx.arc(tPos.get("x"), tPos.get("y"), 4 - (i * 0.45), 0, PI * 2)
			ctx.fill()
			ctx.restore()
		# Pulsing glow
		_glow(ctx, pos.get("x"), pos.get("y"), 13 * pulse, a.get("glow"), env * 0.92)
		# Core orb
		ctx.save()
		ctx.globalAlpha = env
		ctx.fillStyle = a.get("burst")
		ctx.beginPath()
		ctx.arc(pos.get("x"), pos.get("y"), 6, 0, PI * 2)
		ctx.fill()
		ctx.fillStyle = "#FFFFFF"
		ctx.beginPath()
		ctx.arc(pos.get("x") - 2, pos.get("y") - 2, 2, 0, PI * 2)
		ctx.fill()
		# specular
		ctx.restore()
		# 3 orbiting satellite sparks
		for i in range(3):
			var oAngle = (a.get("t") * 0.28) + (((i / 3.0) * PI) * 2)
			var oR = 14 * pulse
			var sx = pos.get("x") + (cos(oAngle) * oR)
			var sy = pos.get("y") + ((sin(oAngle) * oR) * 0.55)
			ctx.save()
			ctx.globalAlpha = env * 0.78
			ctx.fillStyle = (a.get("c1") if (JS.mod(i, 2)) == 0 else a.get("c2"))
			ctx.beginPath()
			ctx.arc(sx, sy, 2.8, 0, PI * 2)
			ctx.fill()
			ctx.restore()
	if prog >= HIT:
		var bp = (prog - HIT) / float((1 - HIT))
		var bp2 = 1 - bp
		# Screen flash — purple
		if bp < 0.18:
			_triggerFlash(200, 40, 255, bp2 * 0.18)
		_glow(ctx, to.get("x"), to.get("y"), 24 * (1 - (bp * 0.35)), a.get("burst"), bp2 * 0.95)
		# Three expanding rings
		_ring(ctx, to.get("x"), to.get("y"), bp * 40, a.get("c1"), bp2 * 0.85, 3.0)
		_ring(ctx, to.get("x"), to.get("y"), bp * 26, a.get("burst"), bp2 * 0.62, 2.0)
		_ring(ctx, to.get("x"), to.get("y"), bp * 14, "#FFFFFF", bp2 * 0.32, 1.0)
		# Energy sparks scatter
		for i in range(16):
			var sAngle = (((i / 16.0) * PI) * 2) + 0.6
			var dist = (20 + (i * 4)) * bp
			var sz = 2 + (JS.mod(i, 2))
			ctx.save()
			ctx.globalAlpha = bp2 * 0.88
			ctx.fillStyle = (a.get("c1") if (JS.mod(i, 2)) == 0 else a.get("c2"))
			ctx.fillRect(JS.round(to.get("x") + (cos(sAngle) * dist)) - 1, JS.round(to.get("y") + (sin(sAngle) * dist)) - 1, sz, sz)
			ctx.restore()

# ─── AIR: Wind slash streaks + swirl burst ────────────────────────────────────
func _drawWindSlash(ctx = null, a = null, W = null, H = null):
	var from = _spriteCenter(a.get("attackerSide"), a.get("targetEnemyIdx"), W, H)
	var toSide = ("enemy" if a.get("attackerSide") == "player" else "player")
	var to = _spriteCenter(toSide, a.get("targetEnemyIdx"), W, H)
	var prog = a.get("t") / float(a.get("dur"))
	var HIT = 0.66
	var travelAngle = atan2(to.get("y") - from.get("y"), to.get("x") - from.get("x"))
	var perpAngle = travelAngle + (PI / 2.0)
	var SLASHES = 5
	for si in range(ceili(SLASHES)):
		var delay = si * 0.055
		var sp = max(0, min(1, (prog - delay) / float((1 - delay))))
		if sp <= 0:
			continue
		if sp < HIT:
			var p = sp / float(HIT)
			var pos = _arcPt(from, to, p)
			var env = sin(p * PI)
			var slashOff = (si - 2) * 7
			# vertical spread
			var slashLen = 12 + (si * 2.5)
			# Slash line (oriented along travel direction)
			var sx1 = (pos.get("x") + (cos(perpAngle) * slashOff)) - ((cos(travelAngle) * slashLen) * 0.5)
			var sy1 = (pos.get("y") + (sin(perpAngle) * slashOff)) - ((sin(travelAngle) * slashLen) * 0.5)
			var sx2 = (pos.get("x") + (cos(perpAngle) * slashOff)) + ((cos(travelAngle) * slashLen) * 0.5)
			var sy2 = (pos.get("y") + (sin(perpAngle) * slashOff)) + ((sin(travelAngle) * slashLen) * 0.5)
			ctx.save()
			ctx.globalAlpha = env * (0.55 + (si * 0.07))
			ctx.strokeStyle = (a.get("c1") if (JS.mod(si, 2)) == 0 else a.get("burst"))
			ctx.lineWidth = max(0.8, 2.2 - (si * 0.2))
			ctx.beginPath()
			ctx.moveTo(sx1, sy1)
			ctx.lineTo(sx2, sy2)
			ctx.stroke()
			ctx.restore()
			# Afterimage trail (faint copy slightly behind)
			if p > 0.18:
				var tPos = _arcPt(from, to, p - 0.12)
				var atx1 = (tPos.get("x") + (cos(perpAngle) * slashOff)) - ((cos(travelAngle) * slashLen) * 0.4)
				var aty1 = (tPos.get("y") + (sin(perpAngle) * slashOff)) - ((sin(travelAngle) * slashLen) * 0.4)
				var atx2 = (tPos.get("x") + (cos(perpAngle) * slashOff)) + ((cos(travelAngle) * slashLen) * 0.4)
				var aty2 = (tPos.get("y") + (sin(perpAngle) * slashOff)) + ((sin(travelAngle) * slashLen) * 0.4)
				ctx.save()
				ctx.globalAlpha = env * 0.22
				ctx.strokeStyle = a.get("c1")
				ctx.lineWidth = 1
				ctx.beginPath()
				ctx.moveTo(atx1, aty1)
				ctx.lineTo(atx2, aty2)
				ctx.stroke()
				ctx.restore()
	# Impact: expanding spiral wind burst
	if prog >= HIT:
		var bp = (prog - HIT) / float((1 - HIT))
		var bp2 = 1 - bp
		_glow(ctx, to.get("x"), to.get("y"), 15, a.get("glow"), bp2 * 0.82)
		_ring(ctx, to.get("x"), to.get("y"), bp * 30, a.get("c1"), bp2 * 0.85, 2.0)
		_ring(ctx, to.get("x"), to.get("y"), bp * 18, a.get("burst"), bp2 * 0.5, 1.0)
		# Spiral wind streaks
		for i in range(14):
			var sAngle = (((i / 14.0) * PI) * 2) + ((bp * PI) * 2.5)
			var r1 = (6 + (i * 0.8)) * bp
			var r2 = r1 + 10
			ctx.save()
			ctx.globalAlpha = bp2 * 0.65
			ctx.strokeStyle = (a.get("c1") if (JS.mod(i, 2)) == 0 else a.get("burst"))
			ctx.lineWidth = 1
			ctx.beginPath()
			ctx.moveTo(to.get("x") + (cos(sAngle) * r1), to.get("y") + ((sin(sAngle) * r1) * 0.55))
			ctx.lineTo(to.get("x") + (cos(sAngle + 0.55) * r2), to.get("y") + ((sin(sAngle + 0.55) * r2) * 0.55))
			ctx.stroke()
			ctx.restore()

# ─── ARC (Neutral) — particles fly arc path + glow impact ────────────────────
func _drawArc(ctx = null, a = null, W = null, H = null):
	var from = _spriteCenter(a.get("attackerSide"), a.get("targetEnemyIdx"), W, H)
	var toSide = ("enemy" if a.get("attackerSide") == "player" else "player")
	var to = _spriteCenter(toSide, a.get("targetEnemyIdx"), W, H)
	var prog = a.get("t") / float(a.get("dur"))
	for p in JS.iter(a.get("particles")):
		var pt = min(1, max(0, prog + p.get("offset")))
		if (pt <= 0 or pt >= 1):
			continue
		var pos = _arcPt(from, to, pt)
		var env = sin(pt * PI)
		ctx.save()
		ctx.globalAlpha = env * p.get("alpha")
		ctx.fillStyle = (a.get("c1") if pt < 0.55 else a.get("c2"))
		var sz = max(1, JS.round(p.size * (1 - (pt * 0.35))))
		ctx.fillRect(JS.round(pos.get("x")) - (sz >> 1), JS.round(pos.get("y")) - (sz >> 1), sz, sz)
		ctx.restore()
	if prog > 0.7:
		var bp = (prog - 0.7) / 0.3
		_glow(ctx, to.get("x"), to.get("y"), 12, a.get("burst"), (1 - bp) * 0.75)
		_ring(ctx, to.get("x"), to.get("y"), bp * 18, a.get("c1"), (1 - bp) * 0.7, 1.5)

# ─── RISE (Heal) — particles float upward with glow ──────────────────────────
func _drawRise(ctx = null, a = null, W = null, H = null):
	var center = _spriteCenter("player", 0, W, H)
	var prog = a.get("t") / float(a.get("dur"))
	# Screen flash — soft green
	if JS.eq(a.get("t"), 1):
		_triggerFlash(50, 220, 80, 0.15)
	# Rising particles
	var _arr2 = JS.iter(a.get("particles"))
	for i in range(len(_arr2)):
		var p = _arr2[i]
		var delay = (i / float(len(a.get("particles")))) * 0.28
		var pt = max(0, (prog - delay) / float((1 - delay)))
		if (pt <= 0 or pt >= 1):
			continue
		var x = center.get("x") + p.get("yOff")
		var y = (center.get("y") - (pt * 38)) - 4
		ctx.save()
		ctx.globalAlpha = sin(pt * PI) * p.get("alpha")
		ctx.fillStyle = (a.get("c1") if pt < 0.5 else a.get("c2"))
		ctx.fillRect(JS.round(x), JS.round(y), p.size, p.size)
		ctx.restore()
	# Central glow
	if prog < 0.55:
		_glow(ctx, center.get("x"), center.get("y"), 16, a.get("burst"), (1 - (prog / 0.55)) * 0.55)

# ─── SHIELD (Block / Armor) — pulsing glow border with corner sparks ──────────
func _drawShield(ctx = null, a = null, W = null, H = null):
	var pp = Sprites.playerSpritePos(W, H)
	var prog = a.get("t") / float(a.get("dur"))
	var grow = min(1, prog * 3.5)
	var fade = (prog / 0.3 if prog < 0.3 else 1 - ((prog - 0.3) / 0.7))
	var pad = 6 * grow
	# Glow fill
	ctx.save()
	ctx.globalAlpha = fade * 0.45
	ctx.fillStyle = a.get("burst")
	ctx.fillRect(pp.get("x") - pad, pp.get("y") - pad, pp.get("w") + (pad * 2), pp.get("h") + (pad * 2))
	# Bright border
	ctx.globalAlpha = fade * 0.9
	ctx.strokeStyle = a.get("c1")
	ctx.lineWidth = max(1, JS.round(2.5 * grow))
	ctx.strokeRect(pp.get("x") - pad, pp.get("y") - pad, pp.get("w") + (pad * 2), pp.get("h") + (pad * 2))
	ctx.restore()
	# Corner spark dots
	var corners = [
		[pp.get("x") - pad, pp.get("y") - pad],
		[(pp.get("x") + pp.get("w")) + pad, pp.get("y") - pad],
		[pp.get("x") - pad, (pp.get("y") + pp.get("h")) + pad],
		[(pp.get("x") + pp.get("w")) + pad, (pp.get("y") + pp.get("h")) + pad],
	]
	for _e3 in JS.iter(corners):
		var cx = JS.idx(_e3, 0)
		var cy = JS.idx(_e3, 1)
		ctx.save()
		ctx.globalAlpha = fade * (0.6 + (0.4 * sin(a.get("t") * 0.4)))
		ctx.fillStyle = a.get("burst")
		ctx.fillRect(JS.round(cx) - 2, JS.round(cy) - 2, 4, 4)
		ctx.restore()

# ─── Main tick — called every rAF frame from renderBattlefield ────────────────
func tickAnims(ctx = null, W = null, H = null):
	for i in range(len(ACTIVE_ANIMS) - 1, 0 - 1, -1):
		var a = ACTIVE_ANIMS[i]
		match a.type:
			"fireball":
				_drawFireball(ctx, a, W, H)
			"lightning":
				_drawLightning(ctx, a, W, H)
			"ice_shards":
				_drawIceShards(ctx, a, W, H)
			"water_wave":
				_drawWaterWave(ctx, a, W, H)
			"earth_slam":
				_drawEarthSlam(ctx, a, W, H)
			"vine_lash":
				_drawVineLash(ctx, a, W, H)
			"plasma_orb":
				_drawPlasmaOrb(ctx, a, W, H)
			"wind_slash":
				_drawWindSlash(ctx, a, W, H)
			"arc":
				_drawArc(ctx, a, W, H)
			"rise":
				_drawRise(ctx, a, W, H)
			"shield":
				_drawShield(ctx, a, W, H)
		a.t += 1
		if a.get("t") >= a.get("dur"):
			JS.splice(ACTIVE_ANIMS, i, 1)
	# Screen flash overlay — drawn after all anims, decays per frame
	if _flashAlpha > 0.006:
		ctx.save()
		ctx.globalAlpha = _flashAlpha
		ctx.fillStyle = "rgb(" + JS.s(_flashR) + "," + JS.s(_flashG) + "," + JS.s(_flashB) + ")"
		ctx.fillRect(0, 0, W, H)
		ctx.restore()
		_flashAlpha *= 0.72
		# quick decay
		if _flashAlpha < 0.006:
			_flashAlpha = 0

# ── Zone-themed campfire environments ─────────────────────────────────────────
func _cfStars(ctx = null, W = null, H = null, groundY = null, t = null):
	for i in range(55):
		var sx = JS.mod((i * 137) + 17, W)
		var sy = JS.mod((i * 97) + 31, floori(groundY * 0.85))
		var blink = sin((t * 0.025) + (i * 0.7)) > 0.55
		ctx.globalAlpha = (0.7 if blink else 0.2)
		ctx.fillStyle = "#ffffff"
		ctx.fillRect(sx, sy, 1, 1)
	ctx.globalAlpha = 1

func _cfMoon(ctx = null, W = null, H = null, t = null, col = null, x = null, y = null):
	ctx.save()
	ctx.globalAlpha = 0.55
	ctx.fillStyle = JS.or_(col, "#e8e0c0")
	ctx.beginPath()
	ctx.arc(JS.round(W * (JS.or_(x, 0.82))), JS.round(H * (JS.or_(y, 0.13))), 9, 0, PI * 2)
	ctx.fill()
	ctx.globalAlpha = 1
	ctx.fillStyle = "#02020a"
	ctx.beginPath()
	ctx.arc(JS.round(W * (JS.or_(x, 0.82))) + 5, JS.round(H * (JS.or_(y, 0.13))) - 2, 8, 0, PI * 2)
	ctx.fill()
	ctx.restore()

func _cfDrawEnvironment(ctx = null, W = null, H = null, groundY = null, t = null, zone = null):
	match zone:
		"Fire":
			_cfEnvFire(ctx, W, H, groundY, t)
		"Water":
			_cfEnvWater(ctx, W, H, groundY, t)
		"Ice":
			_cfEnvIce(ctx, W, H, groundY, t)
		"Lightning":
			_cfEnvLightning(ctx, W, H, groundY, t)
		"Earth":
			_cfEnvEarth(ctx, W, H, groundY, t)
		"Nature":
			_cfEnvNature(ctx, W, H, groundY, t)
		"Plasma":
			_cfEnvPlasma(ctx, W, H, groundY, t)
		"Air":
			_cfEnvAir(ctx, W, H, groundY, t)
		_:
			_cfEnvFire(ctx, W, H, groundY, t)

# FIRE: dark ember sky, glowing horizon, cracked lava ground
func _cfEnvFire(ctx = null, W = null, H = null, gY = null, t = null):
	var sky = ctx.createLinearGradient(0, 0, 0, gY)
	sky.addColorStop(0, "#0a0200")
	sky.addColorStop(0.6, "#1a0600")
	sky.addColorStop(1, "#2a0c00")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, gY)
	# Ember horizon glow
	ctx.save()
	ctx.globalAlpha = 0.18 + (0.06 * sin(t * 0.04))
	var hg = ctx.createLinearGradient(0, gY - 20, 0, gY)
	hg.addColorStop(0, "transparent")
	hg.addColorStop(1, "#FF4400")
	ctx.fillStyle = hg
	ctx.fillRect(0, gY - 20, W, 20)
	ctx.restore()
	# Stars (sparse, reddish)
	for i in range(30):
		var sx = JS.mod((i * 137) + 17, W)
		var sy = JS.mod((i * 97) + 31, floori(gY * 0.7))
		ctx.globalAlpha = 0.25
		ctx.fillStyle = "#ff9944"
		ctx.fillRect(sx, sy, 1, 1)
	ctx.globalAlpha = 1
	# Ground — cracked dark lava
	var gg = ctx.createLinearGradient(0, gY, 0, H)
	gg.addColorStop(0, "#2a1000")
	gg.addColorStop(1, "#0a0400")
	ctx.fillStyle = gg
	ctx.fillRect(0, gY, W, H)
	ctx.fillStyle = "#3a1400"
	ctx.fillRect(0, gY, W, 2)
	# Lava crack lines
	ctx.save()
	ctx.globalAlpha = 0.5 + (0.2 * sin(t * 0.06))
	ctx.fillStyle = "#FF4400"
	for i in range(5):
		var cx = JS.mod(((i * W) / 4.0) + (W * 0.1), W)
		ctx.fillRect(JS.round(cx), gY + 2, 1, (H - gY) - 2)
	ctx.restore()
	# Small fire hazard spots on ground
	for i in range(3):
		var gfx = JS.round(((i * 0.28) + 0.12) * W)
		ctx.save()
		ctx.globalAlpha = (0.3 + (0.15 * sin((t * 0.08) + i))) * 0.7
		ctx.fillStyle = "#FF8800"
		ctx.fillRect(gfx - 3, gY + 4, 6, 3)
		ctx.restore()

# WATER: deep ocean night, moonlit water reflection, sandy shore
func _cfEnvWater(ctx = null, W = null, H = null, gY = null, t = null):
	var sky = ctx.createLinearGradient(0, 0, 0, gY)
	sky.addColorStop(0, "#01050f")
	sky.addColorStop(0.6, "#050e1a")
	sky.addColorStop(1, "#0a1828")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, gY)
	_cfStars(ctx, W, H, gY, t)
	_cfMoon(ctx, W, H, t, "#c0d8f0", 0.8, 0.12)
	# Ground — wet sand / shore
	var gg = ctx.createLinearGradient(0, gY, 0, H)
	gg.addColorStop(0, "#1a2a1a")
	gg.addColorStop(0.4, "#0e1a10")
	gg.addColorStop(1, "#060e0a")
	ctx.fillStyle = gg
	ctx.fillRect(0, gY, W, H)
	ctx.fillStyle = "#1e3020"
	ctx.fillRect(0, gY, W, 2)
	# Water shimmer at horizon
	ctx.save()
	for i in range(6):
		var wx = JS.round(JS.mod(((i * W) / 5.0) + (sin((t * 0.03) + i) * 8), W))
		ctx.globalAlpha = 0.12 + (0.08 * sin((t * 0.05) + (i * 1.3)))
		ctx.fillStyle = "#4488cc"
		ctx.fillRect(wx, gY - 2, JS.round(W * 0.08), 1)
	ctx.restore()
	# Moon reflection ripple on ground
	ctx.save()
	for i in range(4):
		var rx = JS.round((W * 0.8) + (sin((t * 0.04) + i) * 6))
		ctx.globalAlpha = (0.06 - (i * 0.012)) * abs(sin(t * 0.03))
		ctx.fillStyle = "#aaccee"
		ctx.fillRect(rx - (i * 4), (gY + 4) + (i * 3), 8 + (i * 8), 1)
	ctx.restore()

# ICE: pale blue arctic night, aurora, snow ground
func _cfEnvIce(ctx = null, W = null, H = null, gY = null, t = null):
	var sky = ctx.createLinearGradient(0, 0, 0, gY)
	sky.addColorStop(0, "#010814")
	sky.addColorStop(0.6, "#05101e")
	sky.addColorStop(1, "#0a1828")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, gY)
	# Aurora bands
	ctx.save()
	var _arr5 = JS.iter([[0.2, 0.3, "#004422"], [0.45, 0.25, "#003344"], [0.7, 0.35, "#002233"]])
	for i in range(len(_arr5)):
		var _e4 = _arr5[i]
		var fx = JS.idx(_e4, 0)
		var fy = JS.idx(_e4, 1)
		var col = JS.idx(_e4, 2)
		ctx.globalAlpha = 0.1 + (0.05 * sin((t * 0.02) + i))
		ctx.fillStyle = col
		ctx.fillRect(0, JS.round(gY * fy), W, JS.round(gY * 0.12))
	ctx.restore()
	_cfStars(ctx, W, H, gY, t)
	_cfMoon(ctx, W, H, t, "#ddeeff", 0.78, 0.11)
	# Ground — snow
	var gg = ctx.createLinearGradient(0, gY, 0, H)
	gg.addColorStop(0, "#c8ddf0")
	gg.addColorStop(0.3, "#8aaac8")
	gg.addColorStop(1, "#405870")
	ctx.fillStyle = gg
	ctx.fillRect(0, gY, W, H)
	ctx.fillStyle = "#e8f4ff"
	ctx.fillRect(0, gY, W, 3)
	# Snow sparkles on ground
	ctx.save()
	for i in range(12):
		var sx = JS.mod((i * 71) + 13, W)
		ctx.globalAlpha = 0.4 + (0.3 * sin((t * 0.04) + i))
		ctx.fillStyle = "#ffffff"
		ctx.fillRect(sx, (gY + 2) + ((JS.mod(i, 4)) * 3), 1, 1)
	ctx.restore()
	# Snow drift mounds
	ctx.fillStyle = "#d0e8ff"
	for i in range(4):
		var mx = JS.round(JS.mod(((i * W) / 3.0) + (W * 0.05), W - 20))
		ctx.fillRect(mx, gY - 2, JS.round(W * 0.08), 4)

# LIGHTNING: storm sky, lightning flashes, scorched stone ground
func _cfEnvLightning(ctx = null, W = null, H = null, gY = null, t = null):
	var sky = ctx.createLinearGradient(0, 0, 0, gY)
	sky.addColorStop(0, "#04060a")
	sky.addColorStop(0.6, "#0a0e14")
	sky.addColorStop(1, "#14141a")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, gY)
	# Storm cloud banks
	ctx.save()
	for _e6 in JS.iter([[0.15, 0.18, 80], [0.5, 0.12, 100], [0.75, 0.2, 70]]):
		var fx = JS.idx(_e6, 0)
		var fy = JS.idx(_e6, 1)
		var cw = JS.idx(_e6, 2)
		ctx.globalAlpha = 0.35
		ctx.fillStyle = "#1a1e28"
		ctx.fillRect(JS.round((fx * W) - (cw / 2.0)), JS.round(fy * gY), cw, 18)
	ctx.restore()
	# Lightning flash across sky
	if ((JS.mod(floori(t / 90.0), 5)) == 0 and (JS.mod(t, 90)) < 8):
		ctx.save()
		ctx.globalAlpha = 0.12
		ctx.fillStyle = "#eeeeff"
		ctx.fillRect(0, 0, W, gY)
		ctx.restore()
	_cfStars(ctx, W, H, gY, t)
	# Ground — dark scorched stone
	var gg = ctx.createLinearGradient(0, gY, 0, H)
	gg.addColorStop(0, "#12121a")
	gg.addColorStop(1, "#06060e")
	ctx.fillStyle = gg
	ctx.fillRect(0, gY, W, H)
	ctx.fillStyle = "#1e1e2a"
	ctx.fillRect(0, gY, W, 2)
	# Stone tile lines
	ctx.save()
	ctx.globalAlpha = 0.2
	ctx.fillStyle = "#0a0a14"
	for i in range(6):
		ctx.fillRect(JS.round((i * W) / 5.0), gY, 1, H - gY)
	ctx.restore()
	# Static crackle on ground
	for i in range(4):
		var sx = JS.round(JS.mod(((i * W) * 0.22) + (W * 0.08), W))
		ctx.save()
		ctx.globalAlpha = 0.12 + (0.08 * sin((t * 0.15) + (i * 2.1)))
		ctx.fillStyle = "#8888ff"
		ctx.fillRect(sx, gY + 2, 1, 6)
		ctx.restore()

# EARTH: warm dusk sky, distant mountains, dirt ground
func _cfEnvEarth(ctx = null, W = null, H = null, gY = null, t = null):
	var sky = ctx.createLinearGradient(0, 0, 0, gY)
	sky.addColorStop(0, "#0a0810")
	sky.addColorStop(0.5, "#1a1010")
	sky.addColorStop(1, "#2a1a08")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, gY)
	# Distant mountain silhouettes
	ctx.save()
	ctx.fillStyle = "#1a1008"
	ctx.globalAlpha = 0.8
	for _e7 in JS.iter([[0.1, 0.55, 0.12], [0.25, 0.5, 0.09], [0.45, 0.48, 0.14], [0.6, 0.52, 0.1], [0.8, 0.46, 0.13]]):
		var fx = JS.idx(_e7, 0)
		var fy = JS.idx(_e7, 1)
		var fw = JS.idx(_e7, 2)
		var mx = JS.round(fx * W)
		var my = JS.round(fy * gY)
		var mw = JS.round(fw * W)
		var mh = gY - my
		var px = mx - (mw / 2.0)
		while px < (mx + (mw / 2.0)):
			var h2 = mh * max(0, 1 - pow((px - mx) / float((mw / 2.0)), 2))
			ctx.fillRect(JS.round(px), JS.round((my + mh) - h2), 1, JS.round(h2))
			px += 1
	ctx.restore()
	_cfStars(ctx, W, H, gY, t)
	_cfMoon(ctx, W, H, t, "#e0c890", 0.83, 0.14)
	# Ground — rich soil
	var gg = ctx.createLinearGradient(0, gY, 0, H)
	gg.addColorStop(0, "#2a1a08")
	gg.addColorStop(1, "#0e0a04")
	ctx.fillStyle = gg
	ctx.fillRect(0, gY, W, H)
	ctx.fillStyle = "#3a2010"
	ctx.fillRect(0, gY, W, 2)
	# Dirt texture pebbles
	ctx.save()
	ctx.globalAlpha = 0.3
	for i in range(8):
		var px = JS.mod((i * 67) + 23, W)
		ctx.fillStyle = "#4a2a12"
		ctx.fillRect(px, (gY + 3) + ((JS.mod(i, 3)) * 4), 2, 1)
	ctx.restore()

# NATURE: lush forest night, fireflies, mossy ground
func _cfEnvNature(ctx = null, W = null, H = null, gY = null, t = null):
	var sky = ctx.createLinearGradient(0, 0, 0, gY)
	sky.addColorStop(0, "#010a04")
	sky.addColorStop(0.6, "#040e06")
	sky.addColorStop(1, "#0a1a08")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, gY)
	# Tree silhouettes L and R
	ctx.save()
	ctx.fillStyle = "#040e04"
	ctx.globalAlpha = 0.9
	for _e8 in JS.iter([
		[0.04, 0.42, 16, gY * 0.55],
		[0.1, 0.38, 12, gY * 0.6],
		[0.86, 0.4, 15, gY * 0.58],
		[0.93, 0.45, 11, gY * 0.52],
	]):
		var fx = JS.idx(_e8, 0)
		var _u = JS.idx(_e8, 1)
		var tw = JS.idx(_e8, 2)
		var th = JS.idx(_e8, 3)
		ctx.fillRect(JS.round(fx * W) - JS.round(tw / 2.0), gY - JS.round(th), tw, JS.round(th))
	ctx.restore()
	_cfStars(ctx, W, H, gY, t)
	_cfMoon(ctx, W, H, t, "#d0eec0", 0.8, 0.12)
	# Ground — moss
	var gg = ctx.createLinearGradient(0, gY, 0, H)
	gg.addColorStop(0, "#0e2008")
	gg.addColorStop(1, "#040c04")
	ctx.fillStyle = gg
	ctx.fillRect(0, gY, W, H)
	ctx.fillStyle = "#1a3a10"
	ctx.fillRect(0, gY, W, 2)
	# Fireflies
	for i in range(8):
		var age = JS.mod((t * 0.4) + (i * 14), 70)
		var alpha = (age / 10.0 if age < 10 else max(0, 1 - ((age - 10) / 60.0)))
		var fx = JS.round((W * 0.1) + (JS.mod((i * 59) + (age * 0.5), W * 0.8)))
		var fy = JS.round(((gY * 0.5) + (JS.mod(i * 37, JS.round(gY * 0.4)))) - (age * 0.3))
		ctx.save()
		ctx.globalAlpha = alpha * 0.8
		ctx.fillStyle = "#aaff44"
		ctx.fillRect(fx, fy, 2, 2)
		ctx.restore()

# PLASMA: void night, dimensional rifts, arcane ground
func _cfEnvPlasma(ctx = null, W = null, H = null, gY = null, t = null):
	var sky = ctx.createLinearGradient(0, 0, 0, gY)
	sky.addColorStop(0, "#05020e")
	sky.addColorStop(0.6, "#0a0518")
	sky.addColorStop(1, "#150a22")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, gY)
	# Plasma rift wisps in sky
	ctx.save()
	for i in range(3):
		var rx = JS.round(JS.mod((((i * W) * 0.3) + (W * 0.1)) + (sin((t * 0.02) + i) * 12), W))
		var ry = JS.round(gY * (0.2 + (i * 0.12)))
		ctx.globalAlpha = 0.08 + (0.05 * sin((t * 0.03) + (i * 1.4)))
		ctx.fillStyle = ["#8844ff", "#ff44cc", "#44aaff"][i]
		ctx.fillRect(rx - 25, ry, 50, 3)
	ctx.restore()
	_cfStars(ctx, W, H, gY, t)
	_cfMoon(ctx, W, H, t, "#cc88ff", 0.81, 0.12)
	# Ground — dark arcane stone
	var gg = ctx.createLinearGradient(0, gY, 0, H)
	gg.addColorStop(0, "#1a0a28")
	gg.addColorStop(1, "#080412")
	ctx.fillStyle = gg
	ctx.fillRect(0, gY, W, H)
	ctx.fillStyle = "#2a1040"
	ctx.fillRect(0, gY, W, 2)
	# Glowing rune cracks on ground
	for i in range(5):
		var rx = JS.mod(((i * W) * 0.18) + (W * 0.06), W)
		ctx.save()
		ctx.globalAlpha = 0.15 + (0.1 * sin((t * 0.05) + (i * 1.7)))
		ctx.fillStyle = "#aa44ff"
		ctx.fillRect(JS.round(rx), gY + 3, 2, (H - gY) - 3)
		ctx.restore()

# AIR: open night sky, player sits on cloud, stars close
func _cfEnvAir(ctx = null, W = null, H = null, gY = null, t = null):
	# Full night sky — no ground, we're on a cloud
	var sky = ctx.createLinearGradient(0, 0, 0, H)
	sky.addColorStop(0, "#03050d")
	sky.addColorStop(0.6, "#07101e")
	sky.addColorStop(1, "#0d1a2e")
	ctx.fillStyle = sky
	ctx.fillRect(0, 0, W, H)
	# Many stars (closer, brighter)
	for i in range(80):
		var sx = JS.mod((i * 131) + 19, W)
		var sy = JS.mod((i * 89) + 41, H * 0.9)
		var blink = sin((t * 0.022) + (i * 0.6)) > 0.45
		ctx.globalAlpha = (0.85 if blink else 0.3)
		ctx.fillStyle = ("#aaccff" if (JS.mod(i, 7)) == 0 else "#ffffff")
		ctx.fillRect(sx, sy, (2 if (JS.mod(i, 11)) == 0 else 1), (2 if (JS.mod(i, 11)) == 0 else 1))
	ctx.globalAlpha = 1
	# Moon — large, bright
	ctx.save()
	ctx.globalAlpha = 0.7
	ctx.fillStyle = "#e8f4ff"
	ctx.fillRect(JS.round(W * 0.79) - 8, JS.round(H * 0.1) - 8, 16, 16)
	ctx.globalAlpha = 1
	ctx.fillStyle = "#03050d"
	ctx.fillRect(JS.round(W * 0.79) + 2, JS.round(H * 0.1) - 7, 7, 14)
	ctx.restore()
	# Distant clouds in background
	ctx.save()
	for _e9 in JS.iter([[0.15, 0.65, 55, 8], [0.6, 0.55, 70, 10], [0.85, 0.72, 45, 7]]):
		var fx = JS.idx(_e9, 0)
		var fy = JS.idx(_e9, 1)
		var cw = JS.idx(_e9, 2)
		var ch = JS.idx(_e9, 3)
		ctx.globalAlpha = 0.12
		ctx.fillStyle = "#4a6a8a"
		ctx.fillRect(JS.round((fx * W) - (cw / 2.0)), JS.round(fy * H), cw, ch)
	ctx.restore()
	# "Ground" is a large cloud platform — drawn at gY level
	# Cloud platform (the one player sits on)
	var cw = JS.round(W * 0.7)
	var ch = 20
	var cx = JS.round(W * 0.5)
	var cy = gY + 2
	ctx.save()
	ctx.globalAlpha = 0.9
	ctx.fillStyle = "#5a7898"
	ctx.fillRect(cx - (cw / 2.0), cy + JS.round(ch * 0.45), cw, JS.round(ch * 0.55))
	var bumps = [
		{"ox": 0.05, "bw": 0.2, "bh": 0.65},
		{"ox": 0.22, "bw": 0.18, "bh": 0.5},
		{"ox": 0.38, "bw": 0.22, "bh": 0.75},
		{"ox": 0.58, "bw": 0.2, "bh": 0.52},
		{"ox": 0.76, "bw": 0.18, "bh": 0.62},
	]
	for _e10 in JS.iter(bumps):
		var ox = JS.idx(_e10, "ox")
		var bw = JS.idx(_e10, "bw")
		var bh = JS.idx(_e10, "bh")
		var bx = (cx - (cw / 2.0)) + JS.round(ox * cw)
		var bwPx = JS.round(bw * cw)
		var bhPx = JS.round((bh * ch) * 0.65)
		var bTop = (cy + JS.round(ch * 0.45)) - bhPx
		ctx.fillStyle = "#6a8aae"
		ctx.fillRect(bx, bTop + 2, bwPx, (bhPx + JS.round(ch * 0.55)) - 2)
		ctx.fillStyle = "#9abcd0"
		ctx.fillRect(bx + 1, bTop, bwPx - 2, 2)
	ctx.fillStyle = "#9abcd0"
	ctx.fillRect((cx - (cw / 2.0)) + 1, cy + JS.round(ch * 0.45), cw - 2, 1)
	ctx.restore()

func startCampfireScene(healText = null):
	var tick = [null]
	_cfHealText = JS.or_(healText, "")
	_cfTick = 0
	var canvas = document.getElementById("campfire-canvas")
	if not JS.t(canvas):
		return
	var W = (canvas.parentElement.clientWidth if JS.t(canvas.get("parentElement")) else 400)
	canvas.width = min(W, 520)
	canvas.height = JS.round(canvas.width * 0.48)
	if JS.t(_cfRAF):
		JS.cancelAnimationFrame(_cfRAF)
	var _fn11 = func():
		_renderCampfireScene(canvas)
		_cfTick += 1
		_cfRAF = JS.requestAnimationFrame(tick[0])
	tick[0] = _fn11
	_cfRAF = JS.requestAnimationFrame(tick[0])

func stopCampfireScene():
	if JS.t(_cfRAF):
		JS.cancelAnimationFrame(_cfRAF)
		_cfRAF = null

func _renderCampfireScene(canvas = null):
	var ctx = canvas.getContext("2d")
	var W = canvas.width
	var H = canvas.height
	var t = _cfTick
	# ── Zone-themed environment ─────────────────────────────────────────────
	var _cfZone = JS.or_(State.currentZoneElement, "Fire")
	var groundY = floori(H * 0.68)
	_cfDrawEnvironment(ctx, W, H, groundY, t, _cfZone)
	# ── Fire warm glow on ground ──────────────────────────────────────────────
	var fireX = JS.round(W * 0.5)
	var fireY = groundY - 4
	var flicker = 0.85 + (0.15 * sin(t * 0.13))
	var glowR = JS.round(W * 0.28) * flicker
	ctx.save()
	var glow = ctx.createRadialGradient(fireX, fireY, 0, fireX, fireY, glowR)
	glow.addColorStop(0, "rgba(255,120,20," + JS.s(0.18 * flicker) + ")")
	glow.addColorStop(0.4, "rgba(200,80,10," + JS.s(0.1 * flicker) + ")")
	glow.addColorStop(1, "rgba(0,0,0,0)")
	ctx.fillStyle = glow
	ctx.fillRect(0, groundY - glowR, W, glowR * 2)
	ctx.restore()
	# ── Campfire logs ─────────────────────────────────────────────────────────
	var logScale = JS.round(max(2, W / 160.0))
	var logPal = ["#6a3810", "#3a1808", "#c8a060", "#2a1004"]
	var logW = 12 * logScale
	var logH = len(SPRITE_CF_LOGS) * logScale
	var logSX = JS.round(fireX - (logW / 2.0))
	var logSY = (groundY - logH) + 2
	Sprites.drawSprite(ctx, SPRITE_CF_LOGS, logSX, logSY, logScale, logPal)
	# ── Animated flame ────────────────────────────────────────────────────────
	var frameIdx = JS.mod(floori(t / 5.0), 3)
	var flameRows = JS.idx([SPRITE_CF_FLAME_A, SPRITE_CF_FLAME_B, SPRITE_CF_FLAME_C], frameIdx)
	var flickPals = [
		["#FF7700", "#FFAA00", "#FF3300", "#FF9900"],
		["#FF5500", "#FF8800", "#FF2200", "#FFCC00"],
		["#FF9900", "#FFCC00", "#FF4400", "#FFAA00"],
	]
	var flamePal = JS.idx(flickPals, frameIdx)
	var flameScale = logScale
	var flameW = 12 * flameScale
	var flameH = len(flameRows) * flameScale
	var flameSX = JS.round(fireX - (flameW / 2.0))
	var flameSY = (logSY - flameH) + (flameScale * 2)
	Sprites.drawSprite(ctx, flameRows, flameSX, flameSY, flameScale, flamePal)
	# ── Smoke particles ───────────────────────────────────────────────────────
	for i in range(8):
		var age = JS.mod((t * 0.7) + (i * 11), 60)
		var alpha = max(0, 0.25 - (age / 100.0))
		if alpha <= 0:
			continue
		var px = fireX + (sin((age * 0.18) + i) * 7)
		var py = flameSY - (age * 1.1)
		var r = 1 + (age * 0.12)
		ctx.save()
		ctx.globalAlpha = alpha
		ctx.fillStyle = "#888888"
		ctx.beginPath()
		ctx.arc(px, py, r, 0, PI * 2)
		ctx.fill()
		ctx.restore()
	# ── Player sitting left of fire ───────────────────────────────────────────
	var pScale = JS.round(max(2, W / 180.0))
	var pRows = Sprites.getPlayerCharSprite()
	# Use sitting sprite
	var sitRows = SPRITE_PLAYER_SITTING
	var sitPal = Sprites.getElemPal(State.playerElement)
	# Add hair color — override 'h' in palette via custom charToColor
	var sitW = 12 * pScale
	var sitH = len(sitRows) * pScale
	var sitX = JS.round((fireX - (logW * 1.55)) - (sitW * 0.5))
	var sitY = (groundY - sitH) + pScale
	# Gentle warm tint from fire on player
	ctx.save()
	ctx.globalAlpha = 0.12 + (0.05 * sin(t * 0.1))
	ctx.fillStyle = "#FF8822"
	ctx.fillRect(sitX, sitY, sitW, sitH)
	ctx.restore()
	Sprites.drawSprite(ctx, sitRows, sitX, sitY, pScale, sitPal)
	# ── Heal text ─────────────────────────────────────────────────────────────
	if JS.t(_cfHealText):
		var fadeIn = min(1, t / 35.0)
		ctx.save()
		ctx.globalAlpha = fadeIn * (0.75 + (0.25 * sin(t * 0.04)))
		ctx.font = "bold " + JS.s(JS.round(W * 0.03)) + "px 'Cinzel', serif"
		ctx.textAlign = "center"
		ctx.fillStyle = "#55ee88"
		ctx.fillText(_cfHealText, W / 2.0, JS.round(H * 0.92))
		ctx.restore()
	# ── Firefly sparks floating up ────────────────────────────────────────────
	for i in range(5):
		var age = JS.mod((t * 0.5) + (i * 17), 80)
		var alpha = (age / 10.0 if age < 10 else max(0, 1 - ((age - 10) / 70.0)))
		if alpha <= 0:
			continue
		var spark_x = (logSX + 8) + (JS.mod((i * 37) + floori(age), logW - 8))
		var spark_y = logSY - (age * 0.7)
		ctx.save()
		ctx.globalAlpha = alpha * 0.85
		ctx.fillStyle = ("#FFCC44" if age < 30 else "#FF6600")
		ctx.fillRect(JS.round(spark_x), JS.round(spark_y), 2, 2)
		ctx.restore()
