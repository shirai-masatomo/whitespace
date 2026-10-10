extends RefCounted
# Approved geometry. Live-world migration waits for extraction/save decisions.
const WIDTH=50
const HEIGHT=34
const BOUNDS=Rect2i(0,0,WIDTH,HEIGHT)
const IDOL_SIZE=Vector2i(2,2)
const IDOL_ANCHOR=Vector2i(24,16)

static func idol_cells() -> Array:
	return [IDOL_ANCHOR,IDOL_ANCHOR+Vector2i.RIGHT,IDOL_ANCHOR+Vector2i.DOWN,IDOL_ANCHOR+Vector2i.ONE]
