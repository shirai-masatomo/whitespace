extends Control
const Combat = preload("res://core/combat.gd")
const Catalog = preload("res://core/catalog.gd")
const Cavern = preload("res://ui/cavern.gd")
const VisualAssets = preload("res://ui/visual_assets.gd")
const PanelFrame = preload("res://ui/panel_frame.gd")
var background: Control
const BattleStage = preload("res://ui/battle_stage.gd")
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
var stage: Control
var hero_hp: ProgressBar
var hero_sp: ProgressBar
var enemy_hp: ProgressBar
var ids: Array = []
var smoke_dir := ""
var smoke_run_id := ""
var smoke_fault := ""
var smoke_report: Dictionary = {}
var round_button: Button
var speed_button: Button
var tool_started := false
var title_visible := false

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
		style.set_stylebox("normal",type,box(Color("cdb784"),Color("927044"),2))
		style.set_stylebox("hover",type,box(Color("ead29b"),Color("e0af53"),2))
		style.set_stylebox("pressed",type,box(Color("ad976b"),Color("e6cc86"),2))
		style.set_stylebox("focus",type,box(Color(0,0,0,0),Color("5fd6da"),2))
		style.set_color("font_color",type,Color("231f1b"))
		style.set_color("font_hover_color",type,Color("231f1b"))
		style.set_color("font_pressed_color",type,Color("231f1b"))
		style.set_color("font_focus_color",type,Color("231f1b"))
		style.set_font_size("font_size",type,18)
	theme = style
	var bg := Control.new()
	background = bg
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
		if argument.begins_with("--smoke-run-id="): smoke_run_id=argument.trim_prefix("--smoke-run-id=")
		if argument.begins_with("--smoke-fault="): smoke_fault=argument.trim_prefix("--smoke-fault=")
	initialize_game()
	show_title()
	if not smoke_dir.is_empty():
		smoke.call_deferred()

func initialize_game() -> void:
	pass

func box(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_content_margin_all(14)
	s.set_corner_radius_all(0)
	s.shadow_color = Color("090d10")
	s.shadow_size = 3
	s.shadow_offset = Vector2(2,2)
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

func column(parent: Node, min_width: float = 0, parchment: bool = false, scenery: bool = false) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.x = min_width
	panel.add_theme_stylebox_override("panel",box(Color("d8c092") if parchment else Color(0.025,0.07,0.085,0.24 if scenery else 0.90),Color("b18a4d"),3))
	if parchment:
		var paper_theme := Theme.new()
		paper_theme.set_color("font_color","Label",Color("292922"))
		panel.theme = paper_theme
	parent.add_child(panel)
	var ornament := Control.new()
	ornament.set_script(PanelFrame)
	panel.add_child(ornament)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation",8)
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
	title_visible=true
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
	root.add_child(text_label("0.1.0 foundation  ·  Godot 4.7.2  ·  主人公の数値とドット表現は試作用",15))
	launch_button.grab_focus()

func show_battle() -> void:
	title_visible=false
	timer.stop()
	var root := root_layout()
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 52
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
	var controls := column(row,210)
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
	start_button = button("自動戦闘を開始",begin_battle)
	controls.add_child(start_button)
	auto_button = button("一時停止",toggle_auto)
	controls.add_child(auto_button)
	round_button=button("1ラウンド進行",func(): timer.stop(); next_round(); auto_button.text = "自動再生")
	controls.add_child(round_button)
	speed_button=button("速度：1倍",func(): timer.wait_time=0.25 if timer.wait_time==0.5 else 0.5; speed_button.text="速度：2倍" if timer.wait_time==0.25 else "速度：1倍")
	controls.add_child(speed_button)
	var center := column(row,550)
	enemy_label = text_label("",18)
	center.add_child(enemy_label)
	enemy_hp = health_bar(Color("b4523b"))
	center.add_child(enemy_hp)
	stage = Control.new()
	stage.set_script(BattleStage)
	stage.clip_contents = true
	center.add_child(stage)
	result_label = text_label("",17)
	result_label.add_theme_color_override("font_color",Color("c9b77d"))
	center.add_child(result_label)
	log_view = RichTextLabel.new()
	log_view.custom_minimum_size.y = 100
	log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.scroll_following = true
	log_view.add_theme_stylebox_override("normal",box(Color("081215"),Color("987b49")))
	log_view.add_theme_font_size_override("normal_font_size",17)
	center.add_child(log_view)
	var status := column(row,210,true)
	status.add_child(text_label("主人公 / 単独",22))
	hero_label = text_label("",18)
	status.add_child(hero_label)
	status.add_child(text_label("HP（現在 / 最大は上記）",16))
	hero_hp = health_bar(Color("a84936"))
	status.add_child(hero_hp)
	status.add_child(text_label("SP",16))
	hero_sp = health_bar(Color("327e9b"))
	status.add_child(hero_sp)
	status.add_child(HSeparator.new())
	status.add_child(text_label("完全自動 / 通常攻撃\n命中 95%\n会心 5% / 1.5倍\n上限 50ラウンド",16))
	root.add_child(text_label("独立した単発戦闘です。敵スキル・装備・成長・戦利品の所持管理は未実装。",16))
	reset_battle()
	start_button.grab_focus()

func health_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 12
	bar.show_percentage = false
	var background := box(Color("1c292a"),Color("544b33"))
	var fill := box(color,color)
	background.set_content_margin_all(0)
	fill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("background",background)
	bar.add_theme_stylebox_override("fill",fill)
	return bar

func reset_battle() -> void:
	tool_started=false
	state = Combat.start(data.hero_fixture, Combat.enemy(data,ids[enemy_choice.selected],int(level_input.value)),data.rules,int(seed_input.value))
	refresh()
	auto_button.text = "自動再生"
	auto_button.disabled=true
	round_button.disabled=true

func begin_battle() -> void:
	timer.stop()
	reset_battle()
	tool_started=true
	auto_button.disabled=false
	round_button.disabled=false
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
	if not tool_started: return
	state = Combat.advance(state)
	if state.outcome != "ongoing":
		timer.stop()
		auto_button.text = "戦闘終了"
		auto_button.disabled=true
		round_button.disabled=true
		start_button.text="同じ条件で再戦"
	refresh()

func refresh() -> void:
	var h: Dictionary = state.hero
	var e: Dictionary = state.enemy
	hero_label.text = "Lv. %d\nHP  %d / %d\nSP  %d / %d\nATK  %d\nDEF  %d\nSPD  %d\n試験用の仮能力" % [h.level,h.hp,h.max_hp,h.sp,h.max_sp,h.atk,h.def,h.spd]
	enemy_label.text = "%s  Lv.%d   HP %d / %d\nATK %d / DEF %d / SPD %d / SP %d" % [e.name,e.level,e.hp,e.max_hp,e.atk,e.def,e.spd,e.sp]
	hero_hp.max_value = h.max_hp
	hero_hp.value = h.hp
	hero_sp.max_value = maxi(1,h.max_sp)
	hero_sp.value = h.sp
	enemy_hp.max_value = e.max_hp
	enemy_hp.value = e.hp
	stage.set_encounter(e.id,10 if e.id=="B10" else 4)
	background.set_depth(10 if e.id=="B10" else 4)
	stage.hero_alive = h.hp > 0
	stage.enemy_alive = e.hp > 0
	stage.queue_redraw()
	var names := {"hero":"主人公","enemy":str(e.name)}
	var outcomes := {"ongoing":"戦闘中", "victory":"勝利", "defeat":"主人公死亡", "draw":"50ラウンドで打切り"}
	result_label.text = "ROUND %02d   /   %s   /   seed %d" % [state.round,outcomes[state.outcome],state.seed]
	result_label.add_theme_font_size_override("font_size",24 if state.outcome!="ongoing" else 17)
	log_view.clear()
	for entry in state.log:
		if entry.type == "round":
			log_view.append_text("\n第%dラウンド  %s → %s\n" % [entry.round,names[entry.order[0]],names[entry.order[1]]])
		else:
			var detail := "%d ダメージ%s" % [entry.damage,"（会心）" if entry.critical else ""] if entry.hit else "ミス"
			log_view.append_text("%s → %s  %s%s\n" % [names[entry.actor],names[entry.target],detail," / HP0" if entry.death else ""])
	if state.outcome == "victory":
		log_view.append_text("\n報酬試算  EXP %d / Gold %d（保存はしません）\n" % [state.reward.exp,state.reward.gold])

func collect_visual_audits(node: Node) -> Array:
	var result: Array = []
	if node.has_method("visual_audit"): result.append(node.visual_audit())
	for child in node.get_children(): result.append_array(collect_visual_audits(child))
	return result

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(smoke_dir.path_join(filename))
	if error != OK:
		push_error("Screenshot failed: " + str(error))
		get_tree().quit(1)
	var audit := FileAccess.open(smoke_dir.path_join(filename.trim_suffix(".png")+"-visual.json"),FileAccess.WRITE)
	audit.store_string(JSON.stringify({"run_id":smoke_run_id,"screenshot":filename,"stages":collect_visual_audits(screen)},"\t"))
	audit.close()

func click_control(control: Button) -> void:
	# Route through this app's viewport hit-testing; never inject OS input.
	await get_tree().process_frame
	await get_tree().process_frame
	var point := control.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
		await get_tree().process_frame

func smoke(quit_on_finish: bool = true) -> void:
	# Application-level regression hook. It is not a claim of manual OS input.
	var rendered := DisplayServer.get_name() != "headless"
	if smoke_fault=="omit-result": get_tree().quit(); return
	if not smoke_check(smoke_run_id!="","missing run ID"): return
	if rendered:
		await get_tree().create_timer(0.4).timeout
		await capture("01-title.png")
	await click_control(launch_button)
	await get_tree().process_frame
	if not is_instance_valid(start_button):
		push_error("Title button input failed")
		get_tree().quit(1)
		return
	if smoke_fault=="start": start_button.pressed.disconnect(begin_battle)
	await click_control(start_button)
	if not smoke_check(tool_started and not timer.is_stopped(),"Start must start playback"): return
	await click_control(auto_button)
	if not smoke_check(timer.is_stopped(),"Pause must stop timer"): return
	await click_control(auto_button)
	if not smoke_check(not timer.is_stopped(),"Resume must start timer"): return
	await click_control(speed_button)
	if not smoke_check(timer.wait_time==0.25 and speed_button.text=="速度：2倍","Speed state"): return
	timer.stop()
	next_round()
	await click_control(start_button)
	if not smoke_check(state.round==0 and not timer.is_stopped(),"Restart resets round and playback"): return
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
	if smoke_fault=="back": back_button.pressed.disconnect(show_title)
	await click_control(back_button)
	await get_tree().process_frame
	if not smoke_check(title_visible and is_instance_valid(launch_button) and launch_button.is_inside_tree(),"Back must return to title"): return
	smoke_report={"run_id":smoke_run_id,"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),
		"rendered":rendered,"manual_input":false,"viewport_mouse_input":true,"ui_core_equal":true,"outcome":state.outcome,"rounds":state.round,
		"tool_start_pause_resume_restart_back":true}
	if quit_on_finish: write_smoke_result(); get_tree().quit()

func smoke_check(ok: bool, message: String) -> bool:
	if not ok: push_error("SMOKE_CHECK_FAILED: "+message); get_tree().quit(1)
	return ok

func write_smoke_result() -> void:
	var file := FileAccess.open(smoke_dir.path_join("ui-smoke.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(smoke_report,"\t")); file.close()
	print("UI_SMOKE_OK run_id=",smoke_run_id)
