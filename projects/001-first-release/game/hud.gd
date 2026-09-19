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
	draw_rect(Rect2(28, 24, 206, 88), Color(0.02, 0.07, 0.1, 0.66))
	text_at(Vector2(44, 48), "DIVE DIVE", 15, CYAN)
	text_at(Vector2(44, 94), "%03d" % int(model.depth), 38)
	text_at(Vector2(130, 93), "m / %d" % int(model.config.goal_depth), 17, MUTED)
	draw_rect(Rect2(998, 24, 254, 88), Color(0.02, 0.07, 0.1, 0.66))
	text_at(Vector2(1014, 50), "酸素", 17, accent)
	text_at(Vector2(1170, 51), "%d%%" % int(ratio * 100), 20, accent)
	draw_rect(Rect2(1014, 62, 222, 5), Color("284451"))
	draw_rect(Rect2(1014, 62, 222 * ratio, 5), accent)
	var hint := "光る藻に触れて、酸素補給"
	if returning:
		hint = "泡に包まれて救助中"
	elif model.at_oxygen() or model.position.y >= -1:
		hint = "ここでは呼吸できます"
	elif ratio < 0.25:
		hint = "酸素が少ない！ 補給を急ごう"
	text_at(Vector2(1014, 94), hint, 15, accent)
	_draw_target(scale_factor)
	var status := "WASD 移動  ·  E 急降下  ·  Space 浮上  ·  F 見渡す  ·  Esc 操作説明"
	if model.position.y > 0.5:
		status = "WASDで桟橋から海へ飛び込もう  ·  マウスで見渡す"
	elif returning:
		status = "緊急浮上中 → %dmから、そのまま再挑戦" % int(maxf(0, -model.return_target.y))
	elif model.velocity.y < -8:
		status = "急降下中  ·  酸素を多く使っています"
	elif model.velocity.y > 1:
		status = "浮上中  ·  Spaceを離すと沈みます"
	elif model.grounded > 0:
		status = "下を向くと、足場の先を見渡せます  ·  E 急降下  ·  Space 浮上"
	draw_rect(Rect2(300, 660, 820, 34), Color(0.02, 0.07, 0.1, 0.65))
	text_at(Vector2(317, 683), status, 17, ORANGE if returning else WHITE)
	if not game.started or game.paused or model.mode == Model.Mode.COMPLETE:
		_draw_overlay(scale_factor)


func _draw_target(scale_factor: Vector2) -> void:
	# Discover the landscape first. Assistance is requested, not always painted on it.
	if game.model.mode != Model.Mode.DIVING or not game.navigation_help:
		return
	var target_index: int = game.next_platform()
	var target: Dictionary = game.model.platforms[target_index]
	draw_rect(Rect2(28, 604, 410, 48), Color(0.02, 0.07, 0.1, 0.65))
	text_at(
		Vector2(42, 625),
		"%s · %dm [Tab 切替 / H 非表示]" % [target.label, int(-target.position.y)],
		14,
		CYAN
	)
	text_at(
		Vector2(42, 644), game.Navigation.bearing(game.model, target_index, game.yaw), 14, MUTED
	)
	for candidate in game.Navigation.candidates(game.model):
		var option: Dictionary = game.model.platforms[candidate]
		var point: Vector3 = option.position + Vector3.UP * 3
		if game.camera.is_position_behind(point):
			continue
		var screen: Vector2 = game.camera.unproject_position(point) / scale_factor
		if not Rect2(240, 120, 760, 470).has_point(screen):
			continue
		var chosen: bool = candidate == target_index
		var color := CYAN if option.oxygen else WHITE
		color.a = 1.0 if chosen else .6
		draw_arc(screen, 9 if chosen else 5, 0, TAU, 32, color, 1.5, true)
		var label := "%dm" % int(-option.position.y)
		if option.oxygen:
			label += " 藻"
		text_at(screen + Vector2(15, 5), label, 14 if chosen else 12, color)


func _draw_overlay(scale_factor: Vector2) -> void:
	var complete: bool = game.model.mode == Model.Mode.COMPLETE
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.015, 0.045, 0.075, 0.82))
	draw_rect(Rect2(272, 110, 736, 497), INK)
	text_at(Vector2(310, 166), "DIVE DIVE  /  海底への足場旅", 20, CYAN)
	var heading := "海を見渡し、%dmへ。" % int(game.model.config.goal_depth)
	if game.paused:
		heading = "一時停止"
	elif complete:
		heading = "裂け目の先へ到達。"
	text_at(Vector2(310, 230), heading, 34)
	if complete:
		text_at(
			Vector2(310, 298),
			"潜航時間 %d秒 / 緊急浮上 %d回" % [int(game.model.elapsed), game.model.setbacks],
			22
		)
		text_at(Vector2(310, 352), "次は別のルートでもう一度。", 22, MUTED)
	else:
		text_at(Vector2(310, 289), "海へ飛び込み、足場をたどって深く潜ろう。", 21)
		text_at(Vector2(310, 330), "光る藻に触れると酸素100%。待たずに進もう。", 21)
		text_at(Vector2(310, 371), "急降下は酸素を多く使う。酸素0で押し戻される。", 20, MUTED)
	text_at(Vector2(310, 439), "WASD 移動 / マウス 視点 / E 急降下 / Space 浮上", 19, CYAN)
	text_at(Vector2(310, 468), "Q 減速 / F 俯瞰 / H 道案内 / Tab 候補 / V 視点 / M 音", 16, MUTED)
	text_at(Vector2(832, 578), "音: OFF" if game.sound.muted else "音: ON", 16, MUTED)
	primary.position = Vector2(310, 489) * scale_factor
	primary.size = Vector2(400, 58) * scale_factor
	quit_button.position = Vector2(742, 489) * scale_factor
	quit_button.size = Vector2(226, 58) * scale_factor
