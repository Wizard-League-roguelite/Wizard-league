extends SceneTree
func _init():
	var base = load("res://fonts/Cinzel-Regular.woff2")
	for sz in [16, 72]:
		for sp in [0, 1, 10]:
			var fv = FontVariation.new()
			fv.base_font = base
			fv.spacing_glyph = sp
			print(sz, " sp=", sp, " w=", fv.get_string_size("ABCDE", HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
	var fv2 = FontVariation.new()
	fv2.base_font = base
	fv2.fallbacks = [load("res://fonts/DejaVuSans.ttf"), load("res://fonts/NotoColorEmoji.ttf")]
	fv2.spacing_glyph = 10
	print("fb ", fv2.get_string_size("ABCDE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
	quit()
