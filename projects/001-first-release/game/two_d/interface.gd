extends Control

const FONT = preload("res://game/ui_font.tres")
const WHITE := Color("e2f6f2")
const CYAN := Color("85ecd4")
var game: Node2D
var start_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_button = Button.new()
	start_button.text = "海へ潜る  [Enter]"
	start_button.add_theme_font_override("font", FONT)
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.pressed.connect(game.begin)
	add_child(start_button)


func _process(_delta: float) -> void:
	start_button.visible = not game.started
	start_button.position = get_viewport_rect().size * 0.5 + Vector2(-140, 80)
	start_button.size = Vector2(280, 50)
	queue_redraw()


func text(at: Vector2, caption: String, size: int = 18, color: Color = WHITE) -> void:
	draw_string(FONT, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw() -> void:
	var screen := get_viewport_rect().size
	draw_rect(Rect2(18, 18, 290, 98), Color(0.015, 0.06, 0.11, 0.9))
	text(Vector2(34, 48), "%03d m" % game.depth(), 26)
	text(Vector2(163, 46), "海の記憶 %d / 3" % game.collected.size(), 17, CYAN)
	text(Vector2(34, 75), "酸素", 16)
	draw_rect(Rect2(84, 62, 200, 14), Color("243a4b"))
	var color := CYAN if game.oxygen > 25 else Color("ff986f")
	draw_rect(Rect2(84, 62, maxf(0, game.oxygen) * 2, 14), color)
	text(Vector2(34, 100), "岩 %d   ｜   海底の先へ潜ろう" % game.stones, 15)
	draw_rect(Rect2(0, screen.y - 43, screen.x, 43), Color(0.01, 0.04, 0.08, 0.9))
	text(
		Vector2(22, screen.y - 15),
		"A D / ← → 移動   Space 浮上   E 急降下   左クリック 掘る   右クリック 岩を置く   Esc 一時停止   M 音",
		16
	)
	if game.message_time > 0 and game.started:
		draw_rect(Rect2(330, 24, 680, 39), Color(0.02, 0.08, 0.13, 0.88))
		text(Vector2(346, 51), game.message, 17, CYAN)
	if not game.started:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(0.015, 0.05, 0.10, 0.73))
		var center := screen * 0.5
		text(center + Vector2(-258, -135), "DIVE DIVE", 70)
		text(center + Vector2(-105, -91), "DEEP OCEAN", 20, CYAN)
		text(center + Vector2(-255, -31), "横へ泳ぎ、岩を掘り、もっと深い海へ。", 24)
		text(center + Vector2(-255, 8), "光る藻で酸素回復。酸素切れは最後の藻へ戻ります。", 18)
		text(center + Vector2(-255, 40), "深海の光に触れたら到達。金色の遺物は寄り道のお楽しみ。", 16)
		text(center + Vector2(-193, 176), "現実海層 → 生物層 / セーブなし", 16, Color("94b7be"))
	elif game.paused or game.complete:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(0.01, 0.03, 0.08, 0.78))
		var center := screen * 0.5
		text(center + Vector2(-190, -35), "深海の光へ到達！" if game.complete else "一時停止", 40)
		text(center + Vector2(-190, 12), "見つけた海の記憶：%d / 3" % game.collected.size(), 21, CYAN)
		text(
			center + Vector2(-190, 57), "R：最初から  /  Esc：再開" if not game.complete else "R：もう一度潜る", 20
		)
