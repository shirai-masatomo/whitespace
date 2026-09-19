extends Control

const FONT = preload("res://game/ui_font.tres")
const Model = preload("res://game/dive_model.gd")
const INK := Color("071923")
const WHITE := Color("e5f5f4")
const MUTED := Color("9bbcc8")
const CYAN := Color("7de6d4")
const ORANGE := Color("ffb980")

var game: Node3D
var primary: Button
var quit_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	primary = make_button("潜りはじめる  [Enter]")
	primary.pressed.connect(_primary_pressed)
	quit_button = make_button("終了")
	quit_button.pressed.connect(func(): get_tree().quit())
	sync_buttons()


func make_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	var normal := StyleBoxFlat.new()
	normal.bg_color = CYAN
	normal.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = WHITE
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	add_child(button)
	return button


func sync_buttons() -> void:
	var complete: bool = game.model.mode == Model.Mode.COMPLETE
	primary.visible = not game.started or game.paused or complete
	quit_button.visible = primary.visible
	primary.text = (
		"海面からもう一度" if complete else ("続きを潜る  [Enter]" if game.paused else "潜りはじめる  [Enter]")
	)
	queue_redraw()


func _primary_pressed() -> void:
	if game.model.mode == Model.Mode.COMPLETE:
		game.restart()
	else:
		game.begin()


func text_at(point: Vector2, caption: String, font_size: int, color: Color = WHITE) -> void:
	draw_string(FONT, point, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw() -> void:
	if not is_instance_valid(game):
		return
	var scale_factor := size / Vector2(1280, 720)
	draw_set_transform(Vector2.ZERO, 0, scale_factor)
	var model = game.model
	var pressure_ratio: float = model.pressure / game.TUNING.pressure_limit
	var danger: bool = model.pressure >= game.TUNING.warning_pressure
	var returning: bool = model.mode == Model.Mode.RETURNING
	var complete: bool = model.mode == Model.Mode.COMPLETE
	var accent := ORANGE if danger or returning else CYAN
	if danger or returning:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.7, 0.2, 0.05, 0.06 + pressure_ratio * 0.06))
	draw_rect(Rect2(28, 24, 264, 157), Color(0.02, 0.07, 0.1, 0.88))
	text_at(Vector2(48, 52), "DIVE DIVE   /   潜航記録", 16, CYAN)
	text_at(Vector2(48, 115), "%03d" % int(model.depth), 54)
	text_at(Vector2(166, 114), "m / 300 m", 19, MUTED)
	text_at(
		Vector2(48, 153),
		"最深 %03dm   ·   浮上 %d回" % [int(model.best_depth), model.setbacks],
		16,
		MUTED
	)
	draw_rect(Rect2(872, 24, 380, 125), Color(0.02, 0.07, 0.1, 0.88))
	text_at(Vector2(892, 54), "圧力負荷", 19, accent)
	text_at(Vector2(1145, 56), "%03d%%" % int(model.pressure), 23, accent)
	draw_rect(Rect2(892, 72, 338, 8), Color("284451"))
	draw_rect(Rect2(892, 72, 338 * pressure_ratio, 8), accent)
	var pressure_hint := "止まる・浮上する → 圧力が下がる"
	if returning:
		pressure_hint = "強制浮上中  →  %dmで操作復帰" % int(model.return_depth)
	elif danger:
		pressure_hint = "危険！ Eを離して圧力を下げよう"
	text_at(Vector2(892, 114), pressure_hint, 17, accent)
	# A depth ruler makes upward loss legible even in featureless water.
	draw_line(Vector2(1229, 202), Vector2(1229, 574), MUTED, 2)
	for index in range(4):
		var y := 202.0 + index * 124
		draw_line(Vector2(1220, y), Vector2(1238, y), MUTED, 2)
		text_at(Vector2(1152, y + 5), "%dm" % (index * 100), 16, MUTED)
	var marker_y: float = 202.0 + clampf(model.depth / game.TUNING.goal_depth, 0, 1) * 372
	draw_circle(Vector2(1229, marker_y), 6, accent)
	draw_line(Vector2(632, 360), Vector2(648, 360), Color(0.8, 1, 1, 0.6), 1)
	draw_line(Vector2(640, 352), Vector2(640, 368), Color(0.8, 1, 1, 0.6), 1)
	draw_rect(Rect2(28, 648, 1224, 48), Color(0.02, 0.07, 0.1, 0.9))
	text_at(
		Vector2(46, 678),
		"WASD 移動   ·   マウス 視点   ·   E 潜る   ·   Q 浮上   ·   Shift+E 急降下   ·   Esc 一時停止",
		18
	)
	if returning:
		draw_rect(Rect2(360, 514, 560, 90), Color(0.05, 0.13, 0.17, 0.92))
		text_at(Vector2(391, 549), "圧力限界 — 海があなたを押し戻す", 24, ORANGE)
		text_at(Vector2(401, 580), "深度を失っても、挑戦はそのまま続く", 19)
	if not game.started or game.paused or complete:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.015, 0.045, 0.075, 0.82))
		draw_rect(Rect2(302, 134, 676, 457), INK)
		draw_line(Vector2(334, 168), Vector2(408, 168), CYAN, 3)
		text_at(Vector2(334, 203), "DIVE DIVE  /  潜航試験 01", 20, CYAN)
		var heading := "300mの海底へ。"
		if game.paused:
			heading = "一時停止"
		elif complete:
			heading = "海底に到達。"
		text_at(Vector2(334, 270), heading, 42)
		if complete:
			text_at(
				Vector2(334, 321),
				"潜航時間 %d秒   /   強制浮上 %d回" % [int(model.elapsed), model.setbacks],
				22
			)
			text_at(Vector2(334, 365), "急ぐか、待つか。あなたのペースで潜ろう。", 20, MUTED)
		else:
			text_at(Vector2(334, 317), "深く進むほど、圧力負荷がたまる。", 22)
			text_at(Vector2(334, 354), "Eを離して留まると回復。100%で強制浮上。", 20, MUTED)
			text_at(Vector2(334, 391), "目標は300m。急がず、止まりながら潜ろう。", 20, MUTED)
		text_at(Vector2(334, 444), "E：潜る   Q：浮上   WASD：移動   マウス：視点", 18, CYAN)
		primary.position = Vector2(334, 485) * scale_factor
		primary.size = Vector2(360, 58) * scale_factor
		quit_button.position = Vector2(724, 485) * scale_factor
		quit_button.size = Vector2(220, 58) * scale_factor
