extends Control
## Schematic depth, not a route finder or teleport map.
const Journey = preload("res://game/two_d/journey.gd")
const FONT = preload("res://game/ui_font.tres")
const COLORS := [
	Color("287d98"),
	Color("244761"),
	Color("345356"),
	Color("496875"),
	Color("493867"),
	Color("1f3346")
]
var game: Node2D


static func progress(y: float, goal_y: float) -> float:
	return clampf((y - 240.0) / maxf(1, goal_y - 240.0), 0, 1)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(164, 360)


func _process(_delta: float) -> void:
	position = Vector2(get_viewport_rect().size.x - size.x - 18, 18)
	visible = game.started and not game.complete
	queue_redraw()


func caption(
	at: Vector2, words: String, color: Color = Color("c4e3e8"), font_size: int = 15
) -> void:
	draw_string(FONT, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.045, 0.075, 0.9))
	caption(Vector2(12, 25), "深度マップ", Color("e2f6f2"), 17)
	var goal_y: float = game.goal_position().y
	var ratio := progress(game.player.position.y, goal_y)
	caption(Vector2(12, 47), "%dm / %dm" % [game.depth(), int((goal_y - 240) / 12)])
	caption(Vector2(12, 68), "全体の深さ %.0f%%" % (ratio * 100))
	var top := 90.0
	var height := 235.0
	var active := Journey.layer(game.player.position.y) - 1
	for index in range(6):
		var start := progress(Journey.LAYER_STARTS[index], goal_y)
		var end := progress(Journey.LAYER_STARTS[index + 1], goal_y) if index < 5 else 1.0
		var y := top + start * height
		var length := (end - start) * height
		draw_rect(Rect2(19, y, 20, maxf(1, length - 1)), COLORS[index])
		caption(
			Vector2(48, y + length * 0.5 + 5),
			"L%d %s" % [index + 1, Journey.LAYER_NAMES[index]],
			Color("ffffff") if index == active else Color("92afb8"),
			14
		)
	var marker := top + ratio * height
	draw_line(Vector2(13, marker), Vector2(43, marker), Color("ffdc82"), 3)
	draw_colored_polygon(
		PackedVector2Array([Vector2(5, marker - 5), Vector2(13, marker), Vector2(5, marker + 5)]),
		Color("ffdc82")
	)
	caption(Vector2(12, 347), "黄色の線：いまここ", Color("ffdc82"), 13)
