extends RefCounted
# Absolute multiplier from delivered pixels, shared by bodies, bounds and carried layers.
const SCALE=1.3
static func transform(foot: Vector2,scale_value: float=SCALE) -> Transform2D:
	return Transform2D(Vector2(scale_value,0),Vector2(0,scale_value),foot*(1.0-scale_value))
static func rect(native: Rect2,foot: Vector2,scale_value: float=SCALE) -> Rect2:
	return Rect2(foot+(native.position-foot)*scale_value,native.size*scale_value)
