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
	var ratio: float = model.oxygen / game.TUNING.oxygen_capacity
	var returning: bool = model.mode == Model.Mode.RETURNING
	var accent := ORANGE if ratio < 0.25 or returning else CYAN
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
	text_at(
		Vector2(892, 54),
		(
			"酸素 / 補給中"
			if model.at_oxygen()
			else "酸素 / 残り約%d秒" % int(ceil(model.oxygen / game.TUNING.oxygen_consumption))
		),
		19,
		accent
	)
	text_at(Vector2(1145, 56), "%03d%%" % int(ratio * 100), 23, accent)
	draw_rect(Rect2(892, 72, 338, 8), Color("284451"))
	draw_rect(Rect2(892, 72, 338 * ratio, 8), accent)
	var hint := "緑の泡に入って酸素を補給"
	if returning:
		hint = "緊急浮上 → %dmから再挑戦" % int(-model.return_target.y)
	elif model.at_oxygen():
		hint = "酸素を補給中 · ここが再挑戦地点"
	elif ratio < 0.25:
		hint = "酸素が少ない！ 緑の泡を目指そう"
	text_at(Vector2(892, 114), hint, 16, accent)
	var status := "足場を離れると、自然に沈みます" if model.grounded >= 0 else "沈降中 · Qで減速 / Eで速く潜る"
	if returning:
		status = "緊急浮上中 · 操作は到着後に戻ります"
	text_at(Vector2(30, 213), status, 17)
	text_at(
		Vector2(30, 239),
		(
			"カメラ：%s [Vで切替]"
			% (
				"俯瞰 [Fを離すと戻る]"
				if Input.is_action_pressed("survey")
				else ("三人称" if game.third_person else "一人称")
			)
		),
		16,
		MUTED
	)
	_draw_target(scale_factor)
	draw_rect(Rect2(28, 648, 1224, 48), Color(0.02, 0.07, 0.1, 0.9))
	text_at(Vector2(46, 678), "WASD 移動 · E 急降下 / Q 減速 · F長押し 見渡す · Tab 目標 · V 視点 · Esc 停止", 18)
	if returning:
		draw_rect(Rect2(348, 510, 584, 95), Color(0.03, 0.12, 0.18, 0.92))
		text_at(Vector2(380, 547), "%s — 泡になって緊急浮上" % model.rescue_reason, 23, ORANGE)
		text_at(Vector2(380, 582), "深度を失っても、挑戦はそのまま続く", 19)
	if not game.started or game.paused or model.mode == Model.Mode.COMPLETE:
		_draw_overlay(scale_factor)


func _draw_target(scale_factor: Vector2) -> void:
	if game.model.mode != Model.Mode.DIVING:
		return
	var target_index: int = game.next_platform()
	var target: Dictionary = game.model.platforms[target_index]
	var choices: Array[int] = game.Navigation.candidates(game.model)
	draw_rect(Rect2(28, 504, 540, 124), Color(0.02, 0.07, 0.1, 0.88))
	text_at(
		Vector2(42, 531),
		"目標候補 [Tab]   ·   %s" % game.Navigation.bearing(game.model, target_index, game.yaw),
		17
	)
	for row in range(choices.size()):
		var candidate: Dictionary = game.model.platforms[choices[row]]
		var selected: bool = choices[row] == target_index
		var caption := (
			"%s %s / %dm  %s"
			% [
				"▶" if selected else "·",
				candidate.label,
				int(-candidate.position.y),
				"補給" if candidate.oxygen else "足場"
			]
		)
		text_at(Vector2(42, 558 + row * 26), caption, 16, CYAN if selected else MUTED)
	var point: Vector3 = target.position + Vector3.UP * 2
	if game.camera.is_position_behind(point):
		return
	var screen: Vector2 = game.camera.unproject_position(point) / scale_factor
	if Rect2(300, 170, 780, 330).has_point(screen):
		draw_arc(screen, 12, 0, TAU, 32, CYAN, 2, true)
		draw_circle(screen, 2, WHITE)
		draw_rect(Rect2(screen + Vector2(18, -17), Vector2(82, 26)), INK)
		text_at(screen + Vector2(24, 2), "%dm ↓" % int(-target.position.y), 16, CYAN)


func _draw_overlay(scale_factor: Vector2) -> void:
	var complete: bool = game.model.mode == Model.Mode.COMPLETE
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.015, 0.045, 0.075, 0.82))
	draw_rect(Rect2(272, 110, 736, 497), INK)
	text_at(Vector2(310, 166), "DIVE DIVE  /  海底への足場旅", 20, CYAN)
	var heading := "足場をたどって、300mへ。"
	if game.paused:
		heading = "一時停止"
	elif complete:
		heading = "海底の灯に到達。"
	text_at(Vector2(310, 230), heading, 34)
	if complete:
		text_at(
			Vector2(310, 298),
			"潜航時間 %d秒 / 緊急浮上 %d回" % [int(game.model.elapsed), game.model.setbacks],
			22
		)
		text_at(Vector2(310, 352), "次は別のルートでもう一度。", 22, MUTED)
	else:
		text_at(Vector2(310, 289), "足場を離れると沈む。着地すると止まる。", 21)
		text_at(Vector2(310, 330), "酸素は減り続ける。緑の泡で補給しよう。", 21)
		text_at(Vector2(310, 371), "酸素が切れると浮上して、深度を失います。", 20, MUTED)
	text_at(Vector2(310, 439), "WASD 移動 / マウス 視点 / E 急降下 / Q 減速", 19, CYAN)
	primary.position = Vector2(310, 489) * scale_factor
	primary.size = Vector2(400, 58) * scale_factor
	quit_button.position = Vector2(742, 489) * scale_factor
	quit_button.size = Vector2(226, 58) * scale_factor
