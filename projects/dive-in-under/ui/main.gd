extends Control
const Combat = preload("res://core/combat.gd")
const Catalog = preload("res://core/catalog.gd")
const Cavern = preload("res://ui/cavern.gd")
var data: Dictionary
var screen: Control
var state: Dictionary = {}
var enemy_choice: OptionButton
var level_input: SpinBox
var seed_input: SpinBox
var hero_label: Label
var enemy_label: Label
var result_label: Label
var log_view: RichTextLabel
var timer: Timer
var start_button: Button
var auto_button: Button
var launch_button: Button
var back_button: Button
var ids: Array = []
var smoke_dir := ""

func _ready() -> void:
	get_window().min_size = Vector2i(1280,720)
	data = Catalog.load_data()
	if data.is_empty():
		get_tree().quit(1)
		return
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Yu Gothic UI", "Meiryo", "Noto Sans CJK JP"])
	var style := Theme.new()
	style.default_font = font
	style.default_font_size = 18
	style.set_color("font_color", "Label", Color("e2ddcc"))
	style.set_color("default_color", "RichTextLabel", Color("d5dfda"))
	for type in ["Button", "OptionButton"]:
		style.set_stylebox("normal",type,box(Color("112c32"),Color("7c704e")))
		style.set_stylebox("hover",type,box(Color("1c454c"),Color("bba574")))
		style.set_stylebox("pressed",type,box(Color("0a2026"),Color("e6cc86")))
		style.set_stylebox("focus",type,box(Color(0,0,0,0),Color("5fd6da"),2))
		style.set_color("font_color",type,Color("e9e2cc"))
		style.set_font_size("font_size",type,18)
	theme = style
	var bg := Control.new()
	bg.set_script(Cavern)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(next_round)
	add_child(timer)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--smoke-dir="):
			smoke_dir = argument.trim_prefix("--smoke-dir=")
	show_title()
	if not smoke_dir.is_empty():
		smoke.call_deferred()

func box(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_content_margin_all(14)
	s.set_corner_radius_all(3)
	return s

func text_label(value: String, font_size: int = 18) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	return label

func button(value: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size.y = 52
	b.pressed.connect(callback)
	return b

func column(parent: Node, min_width: float = 0) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.x = min_width
	panel.add_theme_stylebox_override("panel",box(Color(0.025,0.07,0.085,0.95),Color("6b644d")))
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation",10)
	panel.add_child(v)
	return v

func root_layout() -> VBoxContainer:
	if is_instance_valid(screen):
		remove_child(screen)
		screen.queue_free()
	var margin := MarginContainer.new()
	screen = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,32)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation",18)
	margin.add_child(root)
	return root

func show_title() -> void:
	timer.stop()
	var root := root_layout()
	root.add_child(text_label("D I V E   I N   U N D E R",48))
	root.add_child(text_label("深く、まだ見ぬ地下へ。",22))
	var gap := Control.new()
	gap.custom_minimum_size.y = 65
	root.add_child(gap)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",100)
	root.add_child(row)
	var left := column(row,400)
	left.add_child(text_label("工程1  /  戦闘基盤",26))
	left.add_child(text_label("主人公ひとり。地下へ向かう、その前に。"))
	launch_button = button("戦闘を確認する  →",show_battle)
	left.add_child(launch_button)
	left.add_child(button("終了",func(): get_tree().quit()))
	var right := column(row,400)
	right.add_child(text_label("今回、確認できること",24))
	right.add_child(text_label("01   素早さ順の自動戦闘\n\n02   同じシードで同じ戦闘\n\n03   敵のLvと基本能力"))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	root.add_child(text_label("開発用の基盤ビルド。探索・初回死亡・町・倉庫・保存は今後の実装です。",17))
	root.add_child(text_label("0.1.0 foundation  ·  Godot 4.7.2  ·  主人公の数値と背景は試作用",15))
	launch_button.grab_focus()

func show_battle() -> void:
	timer.stop()
	var root := root_layout()
	var header := HBoxContainer.new()
	root.add_child(header)
	var heading := text_label("Dive In Under   /   戦闘確認",30)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	back_button = button("タイトルへ",show_title)
	header.add_child(back_button)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation",16)
	root.add_child(row)
	var controls := column(row,270)
	controls.size_flags_horizontal = Control.SIZE_FILL
	controls.add_child(text_label("検証条件",24))
	enemy_choice = OptionButton.new()
	ids = data.enemies.keys()
	ids.sort()
	for id in ids:
		enemy_choice.add_item(id + "  " + data.enemies[id].name)
	enemy_choice.select(ids.find("E04"))
	controls.add_child(enemy_choice)
	controls.add_child(text_label("敵レベル"))
	level_input = SpinBox.new()
	level_input.min_value = 1
	level_input.max_value = 7
	level_input.value = 4
	controls.add_child(level_input)
	controls.add_child(text_label("戦闘シード"))
	seed_input = SpinBox.new()
	seed_input.min_value = 0
	seed_input.max_value = 2147383647
	seed_input.value = 10000
	controls.add_child(seed_input)
	start_button = button("この条件で自動戦闘",begin_battle)
	controls.add_child(start_button)
	auto_button = button("一時停止",toggle_auto)
	controls.add_child(auto_button)
	controls.add_child(button("1ラウンド進める",func(): timer.stop(); next_round(); auto_button.text = "自動再生"))
	var center := column(row,460)
	enemy_label = text_label("",22)
	center.add_child(enemy_label)
	result_label = text_label("",20)
	result_label.add_theme_color_override("font_color",Color("c9b77d"))
	center.add_child(result_label)
	center.add_child(HSeparator.new())
	log_view = RichTextLabel.new()
	log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.scroll_following = true
	log_view.add_theme_font_size_override("normal_font_size",17)
	center.add_child(log_view)
	var status := column(row,240)
	status.add_child(text_label("主人公 / 単独",24))
	hero_label = text_label("",20)
	status.add_child(hero_label)
	status.add_child(HSeparator.new())
	status.add_child(text_label("通常攻撃のみ\n\n命中 95%\n会心 5% / 1.5倍\n\n上限 50ラウンド",17))
	root.add_child(text_label("独立した単発戦闘です。敵スキル・装備・成長・戦利品の所持管理は未実装。",16))
	reset_battle()
	start_button.grab_focus()

func reset_battle() -> void:
	state = Combat.start(data.hero_fixture, Combat.enemy(data,ids[enemy_choice.selected],int(level_input.value)),data.rules,int(seed_input.value))
	refresh()
	auto_button.text = "自動再生"

func begin_battle() -> void:
	timer.stop()
	reset_battle()
	timer.start()
	auto_button.text = "一時停止"

func toggle_auto() -> void:
	if state.outcome != "ongoing":
		return
	if timer.is_stopped():
		timer.start()
		auto_button.text = "一時停止"
	else:
		timer.stop()
		auto_button.text = "自動再生"

func next_round() -> void:
	state = Combat.advance(state)
	if state.outcome != "ongoing":
		timer.stop()
		auto_button.text = "戦闘終了"
	refresh()

func refresh() -> void:
	var h: Dictionary = state.hero
	var e: Dictionary = state.enemy
	hero_label.text = "Lv. %d\n\nHP  %d / %d\nSP  %d / %d\n\n攻撃    %d\n防御    %d\n素早さ  %d\n\n試験用の仮能力" % [h.level,h.hp,h.max_hp,h.sp,h.max_sp,h.atk,h.def,h.spd]
	enemy_label.text = "%s  Lv.%d\nHP %d / %d   攻撃 %d / 防御 %d / 速さ %d" % [e.name,e.level,e.hp,e.max_hp,e.atk,e.def,e.spd]
	var names := {"hero":"主人公","enemy":str(e.name)}
	var outcomes := {"ongoing":"戦闘中", "victory":"勝利", "defeat":"主人公死亡", "draw":"50ラウンドで打切り"}
	result_label.text = "ROUND %02d   /   %s   /   seed %d" % [state.round,outcomes[state.outcome],state.seed]
	log_view.clear()
	for entry in state.log:
		if entry.type == "round":
			log_view.append_text("\n第%dラウンド  %s → %s\n" % [entry.round,names[entry.order[0]],names[entry.order[1]]])
		else:
			var detail := "%d ダメージ%s" % [entry.damage,"（会心）" if entry.critical else ""] if entry.hit else "ミス"
			log_view.append_text("%s → %s  %s%s\n" % [names[entry.actor],names[entry.target],detail," / HP0" if entry.death else ""])
	if state.outcome == "victory":
		log_view.append_text("\n報酬試算  EXP %d / Gold %d（保存はしません）\n" % [state.reward.exp,state.reward.gold])

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(smoke_dir.path_join(filename))
	if error != OK:
		push_error("Screenshot failed: " + str(error))
		get_tree().quit(1)

func smoke() -> void:
	# Application-level regression hook. It is not a claim of manual OS input.
	var rendered := DisplayServer.get_name() != "headless"
	if rendered:
		await capture("01-title.png")
	launch_button.pressed.emit()
	await get_tree().process_frame
	start_button.pressed.emit()
	timer.stop()
	next_round()
	if rendered:
		await capture("02-battle.png")
	while state.outcome == "ongoing":
		next_round()
	var expected := Combat.simulate(data.hero_fixture, Combat.enemy(data,"E04",4),data.rules,10000)
	if state != expected:
		push_error("UI/core parity failure")
		get_tree().quit(1)
		return
	if rendered:
		await capture("03-battle-result.png")
	var file := FileAccess.open(smoke_dir.path_join("ui-smoke.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),
		"rendered":rendered,"manual_input":false,"ui_core_equal":true,"outcome":state.outcome,"rounds":state.round},"\t"))
	file.close()
	back_button.pressed.emit()
	await get_tree().process_frame
	print("UI_SMOKE_OK rendered=",rendered," manual_input=false")
	get_tree().quit()
