extends Control

const DepthMap = preload("res://game/two_d/depth_map.gd")
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
	var depth_map := DepthMap.new()
	depth_map.game = game
	add_child(depth_map)


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
	text(
		Vector2(163, 46),
		"海の記憶 %d / %d" % [game.collected.size(), game.markers("relic").size()],
		17,
		CYAN
	)
	text(Vector2(34, 75), "酸素", 16)
	draw_rect(Rect2(84, 62, 200, 14), Color("243a4b"))
	var color := CYAN if game.oxygen > 25 else Color("ff986f")
	draw_rect(Rect2(84, 62, maxf(0, game.oxygen) * 2, 14), color)
	text(Vector2(34, 100), "岩 %d   ｜   海底の先へ潜ろう" % game.stones, 15)
	draw_rect(Rect2(0, screen.y - 43, screen.x, 43), Color(0.01, 0.04, 0.08, 0.9))
	text(
		Vector2(22, screen.y - 15),
		"左クリック 移動   A D / ← → 移動   Space 浮上   E 急降下   Shift＋左 掘る   右 岩を置く   Esc 停止   M 音",
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
		text(center + Vector2(-255, -31), "行きたい場所をクリックして、深い海へ。", 24)
		text(center + Vector2(-255, 8), "光る藻で酸素回復。酸素切れは最後の藻へ戻ります。", 18)
		text(center + Vector2(-255, 40), "Shift＋左クリックで掘る。右上のマップで現在の深さを確認。", 16)
		text(center + Vector2(-193, 176), "海から、神話と星の底へ / セーブなし", 16, Color("94b7be"))
	elif game.paused or game.complete:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(0.01, 0.03, 0.08, 0.78))
		var center := screen * 0.5
		text(center + Vector2(-240, -70), "最深部に、光があった。" if game.complete else "一時停止", 40)
		text(
			center + Vector2(-240, -17),
			"海の記憶：%d / %d" % [game.collected.size(), game.markers("relic").size()],
			21,
			CYAN
		)
		text(
			center + Vector2(-190, 57), "R：最初から  /  Esc：再開" if not game.complete else "R：もう一度潜る", 20
		)

		if game.complete:
			text(
				center + Vector2(-240, 20),
				(
					"潜水 %d分%02d秒  /  救助 %d回"
					% [int(game.play_seconds / 60), int(game.play_seconds) % 60, game.rescue_count]
				),
				18
			)
			text(center + Vector2(-240, 111), "DIVE DIVE — 最後まで潜ってくれて、ありがとう。", 17, CYAN)
