# Hand-optimised: sprites are cached as textures instead of being drawn pixel by pixel each frame.
func drawSprite(ctx = null, rows = null, x = null, y = null, scale_ = null, pal = null, cols = null, flipH = null):
	cols = JS.or_(cols, 12)
	var key = hash(pal)
	var colors = _sprite_pal_cache.get(key)
	if colors == null:
		colors = {}
		for ch in ["1", "2", "3", "4", "h", "s", "e", "b", "w", "f", "g"]:
			var c = charToColor(ch, pal)
			if JS.t(c): colors[ch] = c
		if _sprite_pal_cache.size() > 200: _sprite_pal_cache.clear()
		_sprite_pal_cache[key] = colors
	ctx.drawPixelRows(rows, x, y, scale_, colors, cols, JS.t(flipH))
