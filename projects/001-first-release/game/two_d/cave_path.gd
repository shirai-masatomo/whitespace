@tool
extends Path2D
## Curve points are the excavation spine, radius is in tiles. Edit the saved Curve2D.

@export_range(2, 35) var radius := 8.0


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint() and curve and curve.point_count > 1:
		draw_polyline(curve.get_baked_points(), Color(0.1, 0.5, 0.8, 0.14), radius * 48)
		draw_polyline(curve.get_baked_points(), Color(0.3, 0.7, 1, 0.8), 3)
