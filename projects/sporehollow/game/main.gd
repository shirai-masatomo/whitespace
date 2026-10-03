extends Node2D
const Farm = preload("res://game/world.gd")
const FONT = preload("res://assets/fonts/ui_font.tres")
const TILE = Vector2(48, 42)
const GROUPS = ["建設", "動物", "回収"]
const TOOLS = {"wall": "壁  10 / 1秒", "build_gate": "門  30", "repair": "修理", "gate": "門開閉", "remove": "解体", "kennel": "犬小屋 木20", "coop": "鶏小屋 木30",
	"auto": "おまかせ", "stay": "待機", "wander": "徘徊", "rest": "休む", "collect": "資源・卵・設計図", "dog_food": "犬用餌 HP+10", "hen_food": "鶏用餌 HP+8", "cat_food": "猫用餌 HP+8"}
const GROUP_TOOLS = [["wall", "build_gate", "kennel", "coop"], ["auto", "stay", "wander", "rest"], ["collect"]]
const BoardArt = preload("res://game/board_art.gd")
const UI = preload("res://game/ui_style.gd")
const MARKET_CATEGORIES = {"animals": ["動物", "animals", "牧場の仲間"], "materials": ["資材", "wood", "土・木・石"], "facilities": ["小屋と設備", "kennel", "牧場づくり"], "items": ["小物と恵み", "basket", "卵・羽・道具"]}
var world = Farm.new({}, randi_range(1, 2147483646))
var tool = ""
var queue_controls: Control
var queue_signature = ""
var seen_jobs = 0
var departure_started = -10.0
var group = -1
var selected_animal = -1
var selected_animals: Array = []
var selected_structures: Array = []
var menu_open = false
var menu_was_paused = false
var menu: Control
var shop_side = "home"
var shop_category = "animals"
var shop_notice = ""
var shop_level = "categories"
var product_row: Dictionary = {}
var dragging = false
var drag_start = Vector2.ZERO
var selected: Dictionary = {}
var speed = 1.0
var seen_danger = 0
var keeper_ui_signature = ""
var keeper_hint_shown = false
var accumulated = 0.0
var clock = 0.0
var automated = false
var debug_view = false
var art_alpha = 1.0
var view_positions: Dictionary = {}
var buttons: Dictionary = {}
var camera: Camera2D
var hud: Node2D
var controls: Control
var palette: Control
var keys_down: Dictionary = {}
var pointer = Vector2(-100, -100)
var message = ""
var message_until = 6.0
var message_until_tick = 24
var alert_text = ""
var alert_until = 0.0
var alert_until_tick = 0
var alert_kind = ""
var seen_milestones = 0
var seen_combat = 0
var seen_skills = 0
var hit_effects: Array = []
var last_phase = ""
var audio: Node
var seen_actions = 0
var structure_views: Dictionary = {}
var gate_views: Dictionary = {}
var dust: Array = []
var visual_time = 0.0
var night_tint = 0.0
var transition_at = -10.0
var name_edit: LineEdit
var training_id = -1
var shop_page = 0
var rename_open = false
var sky_kind = ""
var overlay: Node2D
var sky_started = -10.0
var victory_started = -10.0
var arrival_started = -10.0
var arrival_bell = false
var morning_keeper = Vector2(5.5, 8)
var morning_dog = Vector2(6.5, 8.5)
var reactions: Dictionary = {}
var noticed: Dictionary = {}

func _ready():
	camera = Camera2D.new()
	camera.position = Vector2(Farm.W, Farm.H) * TILE * 0.5
	add_child(camera)
	var layer = CanvasLayer.new()
	add_child(layer)
	hud = Node2D.new()
	layer.add_child(hud)
	hud.draw.connect(draw_hud)
	controls = Control.new()
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 16
	controls.theme = theme
	layer.add_child(controls)
	palette = Control.new()
	palette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.add_child(palette)
	add_button(controls, "pause", "停止", Rect2(1040, 7, 88, 32), toggle_pause)
	add_button(controls, "speed", "×1", Rect2(1136, 7, 64, 32), toggle_speed)
	add_button(controls, "home", "", Rect2(1208, 7, 62, 32), recenter)
	buttons.home.tooltip_text = "牧場の中央へ"
	add_button(controls, "advance", "買い物を終える", Rect2(1074, 754, 190, 36), advance)
	add_button(controls, "retry", "再挑戦", Rect2(556, 514, 168, 38), retry_stage)
	for i in range(GROUPS.size()):
		add_button(controls, "group%d" % i, GROUPS[i], Rect2(16 + i * 122, 754, 116, 36), select_group.bind(i))
	audio = preload("res://game/farm_audio.gd").new()
	add_child(audio)
	queue_controls = Control.new()
	queue_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.add_child(queue_controls)
	add_button(controls, "walk", "牧場主", Rect2(405, 754, 95, 36), choose_walk)
	setup_menu()
	overlay = Node2D.new()
	layer.add_child(overlay)
	overlay.draw.connect(draw_transition)
	if world.phase == "shop": arrival_started = clock
	refresh()
	controls.visible = not cinematic()
	if "--automated" in OS.get_cmdline_user_args(): automated = true
	if automated: get_window().unfocusable = true
	if "--smoke" in OS.get_cmdline_user_args(): get_tree().create_timer(2).timeout.connect(get_tree().quit)

func add_button(parent: Control, id: String, text_value: String, area: Rect2, callback: Callable):
	var button = Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.position = area.position
	button.size = area.size
	UI.button(button)
	var symbol = {"shop_back": "back", "advance": "next", "retry": "back", "group0": "hammer", "group1": "paw", "group2": "basket", "pause": "pause", "home": "spark", "rename": "paw", "save_name": "check", "repair": "hammer", "remove": "cross", "menu_resume": "next", "menu_retry": "back", "menu_morning": "back"}.get(id, "")
	if symbol != "": button.icon = UI.icon(symbol)
	button.pressed.connect(callback)
	parent.add_child(button)
	buttons[id] = button

func recenter():
	camera.position = Vector2(Farm.W, Farm.H) * TILE * 0.5
	camera.zoom = Vector2.ONE

func notice(text_value: String):
	message = text_value
	message_until = clock + 3.5
	message_until_tick = world.tick + 14

func select_group(index: int):
	group = index
	selected.clear()
	selected_structures.clear()
	tool = ""
	selected_animal = -1
	selected_animals.clear()
	refresh()

func select_tool(id: String, execute: bool = true):
	tool = id
	if execute and id in ["auto", "wander", "rest"]: command_selected(id, Vector2i.ZERO)
	refresh()

func command_selected(id: String, cell: Vector2i):
	var accepted = 0
	for animal_id in selected_animals:
		if world.act(id, cell, animal_id): accepted += 1
	notice("%d匹に「%s」" % [accepted, TOOLS[id]] if accepted else "指示する仲間をクリックしてください")

func cycle_subtool(reverse: bool = false):
	if not world.working() or group != 0: return
	var choices = GROUP_TOOLS[0].filter(func(id): return Farm.BUILD[id].get("blueprint", "") in ([""] + world.campaign.unlocked_blueprints))
	var index = choices.find(tool)
	var next = (choices.size() - 1 if reverse else 0) if index < 0 else posmod(index + (-1 if reverse else 1), choices.size())
	select_tool(choices[next], false)

func choose_animal(id: int, toggle: bool = false):
	if world.jobs.any(func(j): return j.kind == "place_animal" and j.animal_id == id): return
	if world.animals.any(func(a): return a.id == id and not a.placed and not world.available(a)): return
	var reserve = world.animals.any(func(a): return a.id == id and not a.placed)
	if toggle and not reserve:
		selected_animals = selected_animals.filter(func(other): return world.animals.any(func(a): return a.id == other and a.placed))
		if id in selected_animals: selected_animals.erase(id)
		else: selected_animals.append(id)
	else: selected_animals = [id]
	group = 1
	selected_animal = selected_animals[0] if not selected_animals.is_empty() else -1
	selected = {"kind": "animal", "id": selected_animal} if selected_animal >= 0 else {}
	tool = "place_animal" if reserve else ""
	if not reserve: react(id, "hello", 1.0)
	refresh()

func collectible(cell: Vector2i) -> bool:
	return world.natural.has(cell) or not world.items_at(cell).is_empty()

func select_resource(cell: Vector2i):
	if group == 2 and tool == "collect" and selected.get("kind") == "resource" and selected.get("pos") == cell:
		if world.act("collect", cell):
			selected.clear()
			notice("回収を頼んだよ")
		else: notice("停止中は回収できません")
	else:
		group = 2
		tool = "collect"
		selected = {"kind": "resource", "pos": cell}
		notice("もう一度クリックで回収を頼む")
	refresh()

func refresh():
	if last_phase != world.phase:
		transition_at = clock
		if world.phase in ["dawn", "result"]: play_alert("win" if world.result == "win" else "lose")
		if world.phase == "dawn":
			sky_kind = "dawn"
			sky_started = clock
	for child in palette.get_children():
		palette.remove_child(child)
		child.queue_free()
	for id in buttons.keys():
		if id not in ["pause", "speed", "home", "advance", "retry", "group0", "group1", "group2", "menu_resume", "menu_retry", "menu_morning", "walk"]: buttons.erase(id)
	buttons.walk.visible = world.working()
	buttons.pause.visible = world.working()
	buttons.speed.visible = world.working()
	buttons.home.visible = world.working()
	buttons.pause.text = "再開" if world.paused else "停止"
	buttons.pause.icon = UI.icon("next" if world.paused else "pause")
	buttons.speed.text = "×%s" % speed
	buttons.advance.visible = world.phase == "shop" or (world.working() and world.early_clear)
	buttons.advance.text = "買い物を終える" if world.phase == "shop" else "今夜を終える +%dG" % floori(world.remaining_night() / 10.0)
	buttons.advance.tooltip_text = "商人を見送って、牧場の仕事へ" if world.phase == "shop" else ""
	buttons.retry.visible = world.phase == "result"
	buttons.group1.text = "動物"
	for i in range(3):
		buttons["group%d" % i].visible = world.working()
		UI.selected(buttons["group%d" % i], i == group)
	if world.phase == "dawn":
		last_phase = world.phase
		return
	if world.phase == "shop":
		build_shop()
	elif selected.get("kind") == "keeper" and world.working():
		add_button(palette, "keeper_rest", "起きる" if world.keeper.resting else "ひと休み", Rect2(16, 704, 125, 36), keeper_action.bind("keeper_rest"))
		buttons.keeper_rest.icon = UI.icon("moon")
		buttons.keeper_rest.disabled = world.keeper.forced_rest or world.keeper.state != "free"
		add_button(palette, "resume_jobs", "仕事へ戻る", Rect2(150, 704, 145, 36), keeper_action.bind("resume_jobs"))
		buttons.resume_jobs.icon = UI.icon("hammer")
		buttons.resume_jobs.disabled = world.keeper.forced_rest or world.keeper.state != "free"
		for i in range(2):
			var drink = ["coffee", "energy_drink"][i]
			if world.item_count(drink) > 0:
				add_button(palette, drink, ("コーヒー" if i == 0 else "活力ドリンク") + " ×%d" % world.item_count(drink), Rect2(305 + i * 175, 704, 165, 36), keeper_action.bind(drink))
				buttons[drink].icon = UI.icon("cup")
				buttons[drink].disabled = world.keeper.drinks_today >= 2 or world.keeper.state != "free"
	elif group == 1:
		var deployed_selection = world.animals.filter(func(a): return a.id in selected_animals and a.placed)
		if deployed_selection.is_empty():
			var reserves = world.animals.filter(func(a): return world.available(a) and not world.jobs.any(func(j): return j.kind == "place_animal" and j.animal_id == a.id))
			for i in range(reserves.size()):
				var a = reserves[i]
				add_button(palette, "animal%d" % a.id, Farm.animal_name(a), Rect2(16 + i * 158, 698, 150, 42), choose_animal.bind(a.id))
				buttons["animal%d" % a.id].draw.connect(draw_card_icon.bind(buttons["animal%d" % a.id], a.species, Vector2(23, 21), 0.55))
		elif deployed_selection.any(func(a): return Farm.SPECIES[a.species].commands):
			for i in range(GROUP_TOOLS[1].size()):
				var id = GROUP_TOOLS[1][i]
				add_button(palette, id, TOOLS[id], Rect2(16 + i * 126, 704, 118, 36), select_tool.bind(id))
	elif group >= 0 and world.working():
		var choices = GROUP_TOOLS[group].filter(func(id): return id != "kennel" or "kennel" in world.campaign.unlocked_blueprints)
		for i in range(choices.size()):
			var id = choices[i]
			add_button(palette, id, TOOLS[id], Rect2(16 + i * 190, 704, 182, 36), select_tool.bind(id))
			buttons[id].tooltip_text = {"wall": "壁：土10、建設1秒", "build_gate": "門：土30、建設1秒", "kennel": "設計図で解放、木材20。1匹専用、毎秒HP1回復", "collect": "雑草：1 Gold / キノコ：終了時HP5回復 / 卵：回収"}.get(id, TOOLS[id])
			if Farm.Shop.FOOD.has(id):
				buttons[id].text += " ×%d" % world.item_count(id)
			if id in ["wall", "build_gate", "kennel", "coop"]:
				buttons[id].icon = BoardArt.icon("wood" if id in ["kennel", "coop"] else "soil")
				buttons[id].disabled = id == "kennel" and "kennel" not in world.campaign.unlocked_blueprints
				if buttons[id].disabled: buttons[id].text = "犬小屋：設計図が必要"
		if group == 0 and selected.get("kind") == "structure":
			add_button(palette, "repair", "E 修理", Rect2(800, 704, 108, 36), facility_action.bind("repair"))
			add_button(palette, "remove", "Del 解体", Rect2(916, 704, 114, 36), facility_action.bind("remove"))
			if world.structures.get(selected.pos, {}).get("kind") == "gate":
				add_button(palette, "gate", "門を開閉", Rect2(1040, 704, 114, 36), facility_action.bind("gate"))
	for id in TOOLS:
		if buttons.has(id): UI.selected(buttons[id], tool == id)
	last_phase = world.phase

func facility_action(action: String):
	if not world.working() or group != 0 or selected.get("kind") != "structure": return
	var targets = selected_structures.duplicate() if action == "remove" else [selected.pos]
	var count = 0
	for cell in targets:
		if world.act(action, cell): count += 1
	notice("%dか所の仕事を頼んだよ" % count if count else ("停止中は実行できません" if world.paused else ("予定は8件まで" if world.jobs.size() >= 8 else "今は使えないか、資材が足りません")))
	if action == "remove" and count:
		selected_structures = selected_structures.filter(func(p): return world.live_structure(p))
		selected = {"kind": "structure", "pos": selected_structures[0]} if not selected_structures.is_empty() else {}
	refresh()

func advance():
	if cinematic() or menu_open: return
	if world.paused: return
	if world.phase == "shop":
		world = world.begin_day()
		reset_view()
		group = 1
		departure_started = clock
	elif world.phase == "dawn":
		morning_keeper = Vector2(world.keeper.pos)
		for a in world.animals:
			if a.species == "shiba" and a.placed: morning_dog = Vector2(a.pos)
		world = Farm.new(world.next_campaign(), world.seed_value + 1)
		reset_view()
		arrival_started = clock
	elif world.working(): world.act("end_night")
	refresh()

func reset_view():
	arrival_started = -10.0
	arrival_bell = false
	reactions.clear()
	noticed.clear()
	sky_started = -10.0
	victory_started = -10.0
	shop_page = 0
	rename_open = false
	menu_open = false
	menu.visible = false
	shop_side = "home"
	shop_level = "categories"
	product_row.clear()
	shop_category = "animals"
	shop_notice = ""
	group = -1
	tool = ""
	selected_animal = -1
	selected_animals.clear()
	selected_structures.clear()
	dragging = false
	selected.clear()
	view_positions.clear()
	seen_milestones = 0
	seen_combat = 0
	seen_skills = 0
	hit_effects.clear()
	seen_actions = 0
	seen_jobs = 0
	queue_signature = ""
	structure_views.clear()
	gate_views.clear()
	dust.clear()
	alert_until = 0
	message = ""
	message_until = 0
	message_until_tick = 0
	accumulated = 0
	recenter()

func retry_stage():
	world = Farm.new(world.checkpoint, world.seed_value)
	reset_view()
	refresh()

func toggle_pause():
	world.act("pause")
	accumulated = 0
	refresh()

func choose_walk():
	group = -1
	tool = ""
	selected = {"kind": "keeper"}
	selected_animals.clear()
	refresh()

func keeper_action(kind: String):
	if not world.act(kind): notice("今はできないよ")
	if not world.keeper.resting and speed > 2: speed = 1
	refresh()

func sync_danger():
	if seen_danger == world.danger_serial: return
	seen_danger = world.danger_serial
	if speed > 1:
		speed = 1
		accumulated = 0
		notice("危険が近い！")
		refresh()

func cancel_work(id: int):
	world.act("cancel_job", Vector2i.ZERO, id)
	refresh_jobs()
	refresh()

func refresh_jobs():
	queue_controls.visible = world.working()
	var signature = str(world.jobs) + str(world.keeper.state) + str(world.paused) + str(world.jobs_held) + str(world.keeper.resting)
	if signature == queue_signature: return
	queue_signature = signature
	for child in queue_controls.get_children():
		queue_controls.remove_child(child)
		child.queue_free()
	if world.jobs.is_empty(): return
	var title = Label.new()
	title.position = Vector2(1020, 64)
	title.text = ("ひと休み" if world.keeper.resting else ("預けた仕事" if world.jobs_held else "おしごと")) + "  · %d" % world.jobs.size()
	queue_controls.add_child(title)
	for i in range(world.jobs.size()):
		var j = world.jobs[i]
		var row = Button.new()
		row.position = Vector2(1010, 94 + i * 35)
		row.size = Vector2(214, 31)
		row.focus_mode = Control.FOCUS_NONE
		UI.button(row, Color("c6d1ac") if i == 0 else UI.PAPER)
		var names = {"wall": "壁", "build_gate": "門", "kennel": "犬小屋", "coop": "鶏小屋", "move": "歩く", "collect": "回収", "repair": "修理", "remove": "解体", "gate": "門を開閉", "place_animal": "仲間を連れていく"}
		row.text = names.get(j.kind, "仕事")
		row.icon = UI.icon("basket" if j.kind == "collect" else ("paw" if j.kind == "place_animal" else ("next" if j.kind == "move" else "hammer")))
		row.tooltip_text = "%d番目 · %s" % [i + 1, "保留" if world.jobs_held else {"pending":"これから", "walking":"向かっている", "working":"作業中"}.get(j.state,"仕事")]
		row.tooltip_text += " · 右クリックで取消"
		row.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT: cancel_work(j.id))
		queue_controls.add_child(row)
		var cancel = Button.new()
		cancel.position = Vector2(1228, 94 + i * 35)
		cancel.size = Vector2(30, 31)
		cancel.focus_mode = Control.FOCUS_NONE
		cancel.icon = UI.icon("cross")
		cancel.tooltip_text = "時を進めてから取り消す" if world.paused else "この予定を取り消す"
		cancel.disabled = world.paused
		UI.button(cancel)
		cancel.pressed.connect(cancel_work.bind(j.id))
		queue_controls.add_child(cancel)

func draw_work_plans():
	if not world.working(): return
	for i in range(world.jobs.size()):
		var j = world.jobs[i]
		var q = center(j.pos)
		if Farm.BUILD.has(j.kind) and not j.started:
			draw_rect(Rect2(q - Vector2(19, 14), Vector2(38, 28)), Color(0.79, 0.76, 0.55, 0.35))
			for x in [-18, 18]:
				draw_line(q + Vector2(x, 11), q + Vector2(x, -12), Color("bdac7a"), 3)
		else: draw_line(q + Vector2(-9, 10), q + Vector2(9, 10), Color("cfdfaa"), 3)
		draw_line(q + Vector2(-10, -12), q + Vector2(-10, -27), Color("9b774e"), 3)
		draw_rect(Rect2(q + Vector2(-16, -29), Vector2(16, 12)), Color("d8c692"))
		label_on(self, q + Vector2(-13, -19), str(i + 1), 10, UI.INK)

func toggle_speed():
	var steps = [0.5, 1.0, 2.0, 4.0] if world.keeper.resting else [0.5, 1.0, 2.0]
	speed = steps[posmod(steps.find(speed) + 1, steps.size())]
	refresh()

func change_speed(direction: int):
	var steps = [0.5, 1.0, 2.0, 4.0] if world.keeper.resting else [0.5, 1.0, 2.0]
	speed = steps[clampi(steps.find(speed) + direction, 0, steps.size() - 1)]
	refresh()

func center(p: Vector2) -> Vector2:
	return (p + Vector2.ONE * 0.5) * TILE

func screen_cell(p: Vector2) -> Vector2:
	return get_canvas_transform() * center(p)

func _input(event):
	if cinematic():
		keys_down.clear()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		toggle_menu()
		get_viewport().set_input_as_handled()
		return
	if menu_open: return
	if is_instance_valid(name_edit) and name_edit.has_focus(): return
	if event is InputEventMouseMotion: pointer = event.position
	if event is InputEventMouseButton:
		pointer = event.position
		if dragging and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_unhandled_input(event)
			get_viewport().set_input_as_handled()
			return
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			if event.ctrl_pressed:
				var scale_value = clampf(camera.zoom.x * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), 0.65, 1.8)
				camera.zoom = Vector2.ONE * scale_value
			elif world.working():
				select_group(posmod(group + (1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1), 3))
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if queue_controls.visible and Rect2(1010, 94, 248, world.jobs.size() * 35).has_point(pointer): return
			if selected.get("kind") == "keeper" and world.working() and not pointer_over_ui():
				var destination = Vector2i(get_canvas_transform().affine_inverse() * event.position / TILE)
				if not world.act("move" if event.shift_pressed else "keeper_move", destination): notice("今はそこへ行けないよ")
				refresh()
				get_viewport().set_input_as_handled()
				return
			tool = ""
			selected.clear()
			selected_animal = -1
			selected_animals.clear()
			dragging = false
			refresh()
			get_viewport().set_input_as_handled()
	if event is InputEventKey:
		if event.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D]: keys_down[event.physical_keycode] = event.pressed
		if not event.pressed or event.echo: return
		if event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT] or event.physical_keycode in [KEY_MINUS, KEY_KP_SUBTRACT] or event.unicode == 45:
			if world.working(): change_speed(-1)
			return
		if event.keycode in [KEY_PLUS, KEY_KP_ADD, KEY_EQUAL] or event.physical_keycode in [KEY_KP_ADD, KEY_EQUAL] or event.unicode == 43:
			if world.working(): change_speed(1)
			return
		match event.physical_keycode:
			KEY_SPACE:
				if world.working(): toggle_pause()
			KEY_TAB: cycle_subtool(event.shift_pressed)
			KEY_HOME: recenter()
			KEY_F3: debug_view = not debug_view
			KEY_F8: export_record()
			KEY_E: facility_action("repair")
			KEY_DELETE: facility_action("remove")
			KEY_1, KEY_2, KEY_3:
				if world.working(): select_group(event.physical_keycode - KEY_1)
		if event.physical_keycode in [KEY_SPACE, KEY_TAB, KEY_HOME, KEY_F3, KEY_F8, KEY_ESCAPE, KEY_1, KEY_2, KEY_3, KEY_E, KEY_DELETE]:
			get_viewport().set_input_as_handled()

func pointer_over_ui() -> bool:
	if pointer.y < 49 or pointer.y > 748: return true
	if world.working() and Rect2(1010, 64, 248, 30 + world.jobs.size() * 35).has_point(pointer): return true
	if not selected.is_empty() and Rect2(16, 595, 422, 91).has_point(pointer): return true
	for button in buttons.values():
		if is_instance_valid(button) and button.is_visible_in_tree() and button.get_global_rect().has_point(pointer): return true
	return false

func _unhandled_input(event):
	if menu_open or cinematic(): return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT): return
	if dragging and not event.pressed:
		dragging = false
		var end = get_canvas_transform().affine_inverse() * event.position
		var area = Rect2(drag_start, end - drag_start).abs()
		if group == 0:
			selected_structures = world.structures.keys().filter(func(p): return world.live_structure(p) and area.has_point(center(p)))
			selected = {"kind": "structure", "pos": selected_structures[0]} if not selected_structures.is_empty() else {}
			tool = ""
			refresh()
			return
		selected_animals.clear()
		for a in world.animals:
			if a.placed and area.has_point(actor_pixel("a%d" % a.id, a.pos)): selected_animals.append(a.id)
		group = 1
		selected_animal = selected_animals[0] if not selected_animals.is_empty() else -1
		selected = {"kind": "animal", "id": selected_animal} if selected_animal >= 0 else {}
		tool = "auto"
		refresh()
		return
	if not event.pressed or pointer_over_ui(): return
	var cell = Vector2i(get_canvas_transform().affine_inverse() * event.position / TILE)
	if not world.working(): return
	if event.shift_pressed:
		dragging = true
		drag_start = get_canvas_transform().affine_inverse() * event.position
		return
	if world.keeper.placed and event.position.distance_to(get_canvas_transform() * keeper_pixel()) < 24 * camera.zoom.x:
		choose_walk()
		if not keeper_hint_shown:
			keeper_hint_shown = true
			notice("右クリックで歩く。仕事は預けておけるよ")
		return
	# Context selection takes precedence over the previously armed tool, even while paused.
	if not world.items_at(cell).is_empty():
		select_resource(cell)
		return
	for a in world.animals:
		if a.placed and event.position.distance_to(get_canvas_transform() * actor_pixel("a%d" % a.id, a.pos)) < 25 * camera.zoom.x:
			if Farm.Shop.FOOD.has(tool):
				notice("餌で回復しました" if world.act(tool, a.pos, a.id) else "対象・在庫・HP・停止状態を確認")
				refresh()
			else: choose_animal(a.id, event.ctrl_pressed)
			return
	if world.live_structure(cell):
		if not event.ctrl_pressed or group != 0 or selected.get("kind") != "structure": selected_structures.clear()
		if cell in selected_structures: selected_structures.erase(cell)
		else: selected_structures.append(cell)
		group = 0
		selected = {"kind": "structure", "pos": selected_structures[0]} if not selected_structures.is_empty() else {}
		tool = ""
		refresh()
		return
	if collectible(cell):
		select_resource(cell)
		return
	for e in world.enemies:
		if not e.done and event.position.distance_to(get_canvas_transform() * actor_pixel("e%d" % e.id, e.pos)) < 25 * camera.zoom.x:
			tool = ""
			group = -1
			selected_animals.clear()
			selected_structures.clear()
			selected = {"kind": "enemy", "id": e.id}
			refresh()
			return
	if tool in Farm.ORDERS:
		command_selected(tool, cell)
	elif tool != "":
		if not world.act(tool, cell, selected_animal if tool == "place_animal" else -1):
			notice("時を進めてから行おう" if world.paused else ("予定は8件まで" if world.jobs.size() >= 8 else "ここは使えないか、資材が足りません"))
		elif tool == "place_animal":
			tool = ""
			selected_animal = -1
			selected_animals.clear()
			selected.clear()
	else:
		selected.clear()
	refresh()

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		keys_down.clear()
		dragging = false

func _process(delta):
	if not menu_open: clock += delta
	if not world.paused: visual_time += delta
	var direction = Vector2(int(keys_down.get(KEY_D, false)) - int(keys_down.get(KEY_A, false)), int(keys_down.get(KEY_S, false)) - int(keys_down.get(KEY_W, false)))
	if not menu_open and not cinematic() and world.phase != "shop": camera.position += direction.normalized() * delta * 420
	var middle = Vector2(Farm.W, Farm.H) * TILE * 0.5
	camera.position = camera.position.clamp(middle - Vector2(500, 360), middle + Vector2(500, 360))
	if not world.paused and not automated and world.working():
		accumulated += minf(delta, 0.1) * speed
		while accumulated >= Farm.DT:
			world.step()
			accumulated -= Farm.DT
			sync_danger()
	if last_phase != world.phase:
		refresh()
	sync_danger()
	if speed > 2 and not world.keeper.resting:
		speed = 1
		refresh()
	var vitals_signature = str(world.keeper.state) + str(world.keeper.resting) + str(world.keeper.forced_rest)
	if selected.get("kind") == "keeper" and vitals_signature != keeper_ui_signature:
		keeper_ui_signature = vitals_signature
		refresh()
	refresh_jobs()
	smooth_actor("keeper", world.keeper.pos, delta)
	if world.phase == "dawn" and clock - transition_at > 4.8 and not menu_open: advance()
	if world.phase == "shop" and clock - arrival_started > 0.8 and not arrival_bell:
		arrival_bell = true
		audio.cue("merchant")
	controls.visible = not cinematic()
	if selected.get("kind") == "enemy" and world.enemies.any(func(e): return e.id == selected.id and (e.hp <= 0 or e.flee or e.done)):
		selected.clear()
		refresh()
	if world.working() and world.early_clear:
		buttons.advance.visible = true
		buttons.advance.text = "今夜を終える +%dG" % floori(world.remaining_night() / 10.0)
	buttons.advance.disabled = cinematic()
	audio.set_night(world.phase == "defend")
	var target_tint = 0.40 * clampf(world.remaining_night() / 25.0, 0, 1) if world.phase == "defend" else (0.30 * (1 - clampf((world.day_seconds - world.tick * Farm.DT) / 15.0, 0, 1)) if world.phase == "day" else 0.0)
	night_tint = move_toward(night_tint, target_tint, delta * 0.4)
	audio.tension(world.working() and world.enemies.any(func(e): return not e.done and not e.flee))
	update_facility_effects(delta)
	for a in world.animals:
		if a.placed:
			smooth_actor("a%d" % a.id, a.pos, delta)
			var nearby = world.enemies.filter(func(e): return not e.flee and not e.done and Farm.distance(a.pos, e.pos) <= a.detection_range)
			if not nearby.is_empty() and not noticed.has(a.id) and a.hp > 0 and a.mode != "rest":
				noticed[a.id] = true
				react(a.id, "alert", 1.2)
	for e in world.enemies: smooth_actor("e%d" % e.id, e.pos, delta)
	while seen_combat < world.combat_log.size():
		var hit = world.combat_log[seen_combat]
		seen_combat += 1
		if hit.source in ["animal", "enemy"]:
			hit_effects.append({"source": ("a" if hit.source == "animal" else "e") + str(hit.id), "target": ("e" if hit.source == "animal" else "a") + str(hit.target), "at": clock})
			play_alert("attack")
		elif hit.source in ["keeper", "keeper_hit"]:
			hit_effects.append({"source": "keeper" if hit.source == "keeper" else "e%d" % hit.id, "target": "e%d" % hit.target if hit.source == "keeper" else "keeper", "at": clock})
			play_alert("attack")
		elif hit.source == "object":
			for cell in world.structures:
				if world.structures[cell].id == hit.target: puff(center(cell), "hit")
			play_alert("object")
	hit_effects = hit_effects.filter(func(hit): return clock - hit.at < 0.3)
	while seen_milestones < world.milestones.size():
		var event = world.milestones[seen_milestones]
		seen_milestones += 1
		var names = {"auto_start": "敵の襲来に備えよ", "invasion": "！ 侵入者接近", "keeper_down": "倒れた！ 仲間に助けてもらおう", "keeper_recovered": "目が覚めた。少し休もう", "restrained": "主人公が拘束された！", "carried": "主人公が連れ去られている！", "rescue": "主人公を救出した！", "animal_danger": "動物のHPが危険！", "blueprint": "犬小屋の作り方を覚えた", "blueprint_dropped": "作り方のメモが落ちた", "early_clear": "今夜の襲撃を退けた", "dawn": "夜明け。生産と成長の時間です"}
		if event.kind == "sleep_warning": notice("もう限界、少し休もう" if event.value >= 100 else ("かなり眠そうだ" if event.value >= 80 else "眠くなってきた"))
		if event.kind == "early_clear":
			victory_started = clock
			for a in world.animals:
				if a.placed and a.hp > 0 and a.mode != "rest": react(a.id, "happy", 1.7)
		if event.kind in ["auto_start", "invasion", "dawn"]:
			play_alert(event.kind)
			continue
		if names.has(event.kind):
			alert_text = names[event.kind]
			alert_kind = event.kind
			alert_until = clock + (4.0 if event.kind in ["carried", "restrained"] else 2.5)
			alert_until_tick = event.tick + (16 if event.kind in ["carried", "restrained"] else 10)
			play_alert("rescue" if event.kind in ["blueprint", "keeper_recovered"] else ("restrained" if event.kind == "keeper_down" else event.kind))
	while seen_skills < world.skill_log.size():
		play_alert("bark" if world.skill_log[seen_skills].skill == "bark" else "collect")
		seen_skills += 1
	queue_redraw()
	hud.queue_redraw()
	overlay.queue_redraw()

func smooth_actor(id: String, p: Vector2i, delta: float):
	view_positions[id] = Vector2(p) if not view_positions.has(id) else view_positions[id].lerp(Vector2(p), minf(delta * 14, 1))

func actor_pixel(id: String, cell: Vector2i) -> Vector2:
	var p = center(view_positions.get(id, Vector2(cell)))
	if id.begins_with("a") and world.structures.get(cell, {}).get("kind") == "kennel": p.y += 13
	# Presentation only: slight side separation plus a short lunge/recoil. No stagger or tick changes.
	if id.begins_with("a"):
		for e in world.enemies:
			if not e.done and Farm.distance(cell, e.pos) <= 1: p.x -= 8
	else:
		for a in world.animals:
			if a.placed and Farm.distance(cell, a.pos) <= 1: p.x += 8
	for hit in hit_effects:
		if id not in [hit.source, hit.target]: continue
		var from = center(view_positions.get(hit.source, Vector2(cell)))
		var to = center(view_positions.get(hit.target, Vector2(cell)))
		var direction = (to - from).normalized()
		if direction == Vector2.ZERO: direction = Vector2.RIGHT
		var pulse = sin(clampf((clock - hit.at) / 0.3, 0, 1) * PI)
		p += direction * pulse * (7 if id == hit.source else 4)
	return p

func alert_visible() -> bool:
	return clock < alert_until and world.tick < alert_until_tick

func play_alert(kind: String):
	audio.cue(kind)

func puff(p: Vector2, kind: String):
	dust.append({"pos": p, "at": visual_time, "kind": kind})
	if dust.size() > 32: dust.pop_front()

func update_facility_effects(delta: float):
	while seen_jobs < world.job_log.size():
		var event = world.job_log[seen_jobs]
		seen_jobs += 1
		if event.event == "unreachable": notice("道がふさがっている。次の仕事へ")
		if event.event == "invalid": notice("この仕事はできなくなったよ")
		if event.event != "completed": continue
		if event.kind in ["repair", "remove", "collect", "gate"]:
			play_alert(event.kind)
			puff(center(Vector2i(event.pos[0], event.pos[1])), event.kind)
		if event.kind == "place_animal": react(event.animal_id, "wag", 1.5)
		refresh()
	for cell in world.structures:
		var b = world.structures[cell]
		var old = structure_views.get(b.id, "")
		if old != "" and old != b.status and b.status in ["ready", "destroyed"]:
			puff(center(cell), "build" if b.status == "ready" else "break")
			play_alert("build" if b.status == "ready" else "object")
		structure_views[b.id] = b.status
		if b.kind == "gate":
			gate_views[b.id] = move_toward(gate_views.get(b.id, 1.0 if b.open else 0.0), 1.0 if b.open else 0.0, delta * 5) if not world.paused else gate_views.get(b.id, 0.0)
	dust = dust.filter(func(f): return visual_time - f.at < 0.55)

func export_record():
	DirAccess.make_dir_recursive_absolute("user://observations")
	FileAccess.open("user://observations/latest.json", FileAccess.WRITE).store_string(JSON.stringify(world.observation(), "  "))
	notice("開発用観察JSONを保存しました")

func label_on(target: CanvasItem, p: Vector2, text_value: String, size: int = 17, color: Color = Color("f3ead1")):
	target.draw_string(FONT, p, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func rect(p: Vector2, size: Vector2, color: String): draw_rect(Rect2(p, size), Color(Color(color), art_alpha))

func draw_structure(p: Vector2, b: Dictionary, preview: bool = false):
	var shade = Color("baad83")
	if preview: shade.a = 0.45
	if b.status in ["destroyed", "interrupted", "removed"]:
		if b.status != "removed":
			rect(p + Vector2(-15, 4), Vector2(13, 8), "82775d")
			rect(p + Vector2(3, 7), Vector2(10, 6), "82775d")
		return
	if b.status == "building":
		draw_rect(Rect2(p - Vector2(18, 13), Vector2(36, 28)), Color(0.9, 0.8, 0.5, 0.25))
		draw_rect(Rect2(p - Vector2(18, 13), Vector2(36, 28)), Color("e5c982"), false, 2)
		draw_line(p - Vector2(14, 10), p + Vector2(14, 10), Color("e5c982"), 2)
		draw_rect(Rect2(p + Vector2(-17, 17), Vector2(34 * (1.0 - float(b.remaining) / b.total_ticks), 3)), Color("b2ebcf"))
		return
	draw_colored_polygon(PackedVector2Array([p + Vector2(-20, 10), p + Vector2(20, 10), p + Vector2(28, 24), p + Vector2(-12, 24)]), Color(0.12, 0.22, 0.13, 0.25))
	if b.kind in ["kennel", "coop"]:
		draw_rect(Rect2(p + Vector2(-19, -7), Vector2(38, 29)), Color("b99160"))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-23, -7), p + Vector2(0, -21), p + Vector2(23, -7)]), Color("96624a"))
		draw_rect(Rect2(p + Vector2(-9, 4), Vector2(18, 18)), Color("39443b"))
		var owner = world.kennel_owner(Vector2i(p / TILE))
		if owner >= 0:
			draw_circle(p + Vector2(14, -1), 4, Color("c1e6a6"))
		if b.kind == "coop":
			draw_line(p + Vector2(-12, 6), p + Vector2(12, 6), Color("f1d79b"), 3)
			draw_circle(p + Vector2(0, -10), 4, Color("fff0c7"))
	elif b.kind == "wall":
		draw_rect(Rect2(p - Vector2(20, 13), Vector2(40, 29)), Color("797257"))
		draw_rect(Rect2(p - Vector2(20, 13), Vector2(40, 6)), shade)
		draw_line(p - Vector2(20, -2), p + Vector2(20, 2), Color("545642"), 2)
	else:
		draw_rect(Rect2(p - Vector2(20, 13), Vector2(6, 30)), shade)
		draw_rect(Rect2(p + Vector2(14, -13), Vector2(6, 30)), shade)
		var hinge = p - Vector2(15, 8)
		var tip = p + Vector2(15, 8).lerp(Vector2(-12, 15), gate_views.get(b.id, 1.0 if b.open else 0.0))
		draw_line(hinge, tip, shade, 5)
		draw_line(hinge + Vector2(0, 9), tip + Vector2(0, 9), Color("897447"), 4)
	if b.hp < b.max_hp:
		var crack = PackedVector2Array([p + Vector2(2, -12), p + Vector2(-5, -3), p + Vector2(2, 3)])
		if b.hp <= b.max_hp * 0.5:
			crack.append(p + Vector2(-8, 15))
			draw_rect(Rect2(p + Vector2(11, 8), Vector2(9, 8)), Color("4c6047"))
		draw_polyline(crack, Color("313d31"), 3)
		draw_rect(Rect2(p + Vector2(-18, 19), Vector2(36.0 * b.hp / b.max_hp, 3)), Color("ebc171"))

func _draw():
	BoardArt.draw_ground(self, world, TILE, visual_time)
	for p in world.natural:
		BoardArt.draw_resource(self, center(p) + Vector2(sin(visual_time * 1.3 + p.x) * (1.5 if world.natural[p] == "weed" else 0.3), 0), world.natural[p])
	for p in world.structures: draw_structure(center(p), world.structures[p])
	for f in world.foods:
		draw_circle(center(f.pos), 10, Color("d3a762"))
		draw_circle(center(f.pos), 6, Color("70513b"))
	draw_market_world()
	for e in world.enemies:
		if e.done or not world.working(): continue
		var p = actor_pixel("e%d" % e.id, e.pos)
		var walking = Vector2(e.pos).distance_to(view_positions.get("e%d" % e.id, Vector2(e.pos))) > 0.025
		var stride = sin(visual_time * 16 + e.id) * (3 if walking else 0.5)
		draw_line(p + Vector2(-5, 14), p + Vector2(-6 + stride, 25), Color("42424c"), 5)
		draw_line(p + Vector2(5, 14), p + Vector2(6 - stride, 25), Color("42424c"), 5)
		p.y += absf(stride) * -0.4
		rect(p + Vector2(-10, -5), Vector2(21, 23), "87768e" if not e.flee else "98947f")
		draw_circle(p + Vector2(0, -10), 10, Color("d2b396"))
		rect(p + Vector2(-12, -18), Vector2(24, 8), "454453")
		rect(p + Vector2(-9, -11), Vector2(18, 5), "474954")
		rect(p + Vector2(-6, -10), Vector2(3, 2), "fff3ce")
		rect(p + Vector2(4, -10), Vector2(3, 2), "fff3ce")
		if e.hp < e.max_hp:
			draw_rect(Rect2(p + Vector2(-18, -48), Vector2(36, 4)), Color("3e4534"))
			draw_rect(Rect2(p + Vector2(-18, -48), Vector2(36.0 * e.hp / e.max_hp, 4)), Color("e3aa88"))
		if world.tick < e.move_stopped_until:
			label_on(self, p + Vector2(-16, -53), "足止め", 13, Color("ffe5a0"))
		if e.counter_target >= 0 and not e.flee:
			draw_line(p + Vector2(-7, -37), p + Vector2(7, -25), Color("ffda91"), 3)
			draw_line(p + Vector2(7, -37), p + Vector2(-7, -25), Color("ffda91"), 3)
		elif "壊す" in e.state:
			draw_line(p + Vector2(0, -24), p + Vector2(0, -38), Color("dfb981"), 3)
			draw_line(p + Vector2(-7, -37), p + Vector2(7, -37), Color("dfb981"), 5)
		elif not e.flee and e.carry == "":
			draw_circle(p + Vector2(0, -32), 4, Color("8bd2c5"))
			draw_line(p + Vector2(-6, -24), p + Vector2(6, -24), Color("8bd2c5"), 3)
		if debug_view: label_on(self, p + Vector2(20, 0), e.state, 12)
		if e.hp > 0 and not e.flee and world.tick < e.sight_reaction_until: label_on(self, p + Vector2(15, -30), e.sight_reaction, 26, Color("ffe0a0"))
		elif e.hp > 0 and not e.flee and e.state == "迷う": label_on(self, p + Vector2(15, -23), "?", 16, Color("c8cfb4"))
		if selected.get("kind") == "enemy" and selected.id == e.id:
			draw_rect(Rect2(p - Vector2(18, 23), Vector2(36, 49)), Color("e6c998"), false, 2)
	if world.keeper.placed:
		var p = actor_pixel("keeper", world.keeper.pos)
		var walking = Farm.Life.able(world) and (world.manual_goal != null or (not world.jobs_held and not world.jobs.is_empty() and world.jobs[0].state == "walking"))
		if walking: p.y += sin(visual_time * 15) * 2
		p.y += sin(visual_time * 1.7) * 0.8
		if world.keeper.carrier >= 0:
			var carrier_pos = view_positions.get("e%d" % world.keeper.carrier, Vector2(world.keeper.pos))
			p = center(carrier_pos) + Vector2(34, -36)
			draw_line(center(carrier_pos) + Vector2(8, 0), p + Vector2(0, 14), Color("d2b396"), 7)
			draw_line(p + Vector2(-11, 11), p + Vector2(12, 11), Color("e7c794"), 4)
			draw_set_transform(p, -PI * 0.5)
			p = Vector2.ZERO
		elif world.keeper.state == "unconscious" or world.keeper.resting:
			draw_set_transform(p + Vector2(0, 12), -PI * 0.5)
			p = Vector2.ZERO
		draw_circle(p + Vector2(0, -8), 9, Color("f3cda2"))
		rect(p + Vector2(-12, -18), Vector2(24, 6), "f1d690")
		rect(p + Vector2(-8, 1), Vector2(17, 20), "80d4cd")
		rect(p + Vector2(-7, 20), Vector2(5, 6), "30484a")
		rect(p + Vector2(3, 20), Vector2(5, 6), "30484a")
		if not world.jobs_held and Farm.Life.able(world) and not world.jobs.is_empty() and world.jobs[0].state == "working":
			var hand = p + Vector2(12, 5)
			var hammer = hand + Vector2(8, -8 + sin(visual_time * 18) * 6)
			draw_line(hand, hammer, Color("a58051"), 3)
			draw_rect(Rect2(hammer - Vector2(5, 3), Vector2(10, 6)), Color("c9c5a5"))
		if world.keeper.state in ["restrained", "captured"]:
			label_on(self, p + Vector2(14, -18), "!", 18, Color("f69773"))
			draw_line(p + Vector2(-10, 8), p + Vector2(10, 8), Color("513f39"), 3)
		draw_set_transform(Vector2.ZERO)
		var owner_pixel = center(view_positions.get("keeper", Vector2(world.keeper.pos)))
		if world.keeper.carrier < 0:
			if selected.get("kind") == "keeper": draw_rect(Rect2(owner_pixel - Vector2(18, 23), Vector2(36, 48)), Color("ffe2a3"), false, 2)
			if world.keeper.resting or world.keeper.sleepiness >= 60:
				label_on(self, owner_pixel + Vector2(15, -20), "Zzz" if world.keeper.resting else ("Z!" if world.keeper.sleepiness >= 90 else "z"), 18, Color("efb383") if world.keeper.sleepiness >= 80 else Color("dce8c2"))
			if world.keeper.state == "unconscious": label_on(self, owner_pixel + Vector2(12, -18), "!", 22, Color("efa084"))
			if world.tick < world.keeper.hurt_until or selected.get("kind") == "keeper":
				draw_rect(Rect2(owner_pixel + Vector2(-17, -33), Vector2(34, 4)), Color("684b46"))
				draw_rect(Rect2(owner_pixel + Vector2(-17, -33), Vector2(34 * float(world.keeper.hp) / world.keeper.max_hp, 4)), Color("d68b74"))
	for item in world.field_items:
		var q = center(item.pos) + (Vector2(7, 8) if item.kind == "kennel_plan" else Vector2.ZERO)
		if item.kind == "kennel_plan" and world.keeper.placed and item.pos == world.keeper.pos: q = center(item.pos) + Vector2(-25,-22)
		if item.kind == "kennel_plan":
			draw_rect(Rect2(q - Vector2(15, 11), Vector2(30, 24)), Color("75c6d8"))
			draw_line(q + Vector2(-9, 0), q + Vector2(0, -7), Color("ffffff"), 2)
			draw_line(q + Vector2(0, -7), q + Vector2(9, 0), Color("ffffff"), 2)
			draw_rect(Rect2(q + Vector2(-6, 0), Vector2(12, 8)), Color("ffffff"), false, 2)
		elif item.kind == "egg":
			draw_circle(q, 7, Color("fff0c7"))
		elif item.kind == "chick":
			draw_circle(q, 8, Color("efd160"))
			draw_line(q, q + Vector2(10, 2), Color("d78d37"), 3)
		else: draw_line(q + Vector2(-5, 6), q + Vector2(6, -8), Color("eee8cf"), 5)
	for a in world.animals:
		if not a.placed: continue
		var p = actor_pixel("a%d" % a.id, a.pos)
		draw_circle(p + Vector2(0, 13), 18, Color(0.1, 0.2, 0.13, 0.25))
		if a.species == "shiba":
			if world.structures.get(a.pos, {}).get("kind") == "kennel":
				draw_set_transform(p, 0, Vector2.ONE * 0.65)
				draw_dog(Vector2.ZERO, a)
				draw_set_transform(Vector2.ZERO)
			else: draw_dog(p, a)
		elif a.species == "cat": draw_cat(p)
		else: draw_hen(p)
		var in_combat = world.enemies.any(func(e): return not e.done and not e.flee and Farm.distance(a.pos, e.pos) <= 1)
		if a.hp <= a.max_hp * 0.5 or in_combat:
			var danger = a.hp <= a.max_hp * Farm.Rules.LOW_HP_FRACTION
			var color = Color("f38c73") if danger else Color("efcc7f")
			draw_rect(Rect2(p + Vector2(-20, 23), Vector2(40, 5)), Color("3e4534"))
			draw_rect(Rect2(p + Vector2(-20, 23), Vector2(40.0 * a.hp / a.max_hp, 5)), color)
			if danger:
				color.a = 0.65 + 0.25 * sin(clock * 4)
				label_on(self, p + Vector2(-4, -29), "!", 23, color)
		if a.hp <= 0: label_on(self, p + Vector2(-18, -27), "気絶", 16, Color("e2bcb3"))
		elif a.state in ["休む", "自主休養"]: label_on(self, p + Vector2(14, -25), "Zz", 18, Color("c1e3db"))
		if a.rescuing: label_on(self, p + Vector2(-25, -20), "!!", 16, Color("b0f0de"))
		if world.tick - a.last_bark < 4:
			var f = dog_facing(a)
			draw_arc(p + Vector2(25 * f, -8), 9, -0.8 + (PI if f < 0 else 0), 0.8 + (PI if f < 0 else 0), 8, Color("ffe3a0"), 2)
			draw_arc(p + Vector2(25 * f, -8), 15, -0.8 + (PI if f < 0 else 0), 0.8 + (PI if f < 0 else 0), 8, Color("ffe3a0"), 2)
		elif a.state == "様子見": label_on(self, p + Vector2(17, -24), "…", 18, Color("ffe3a0"))
		if not cinematic() and group == 1 and a.id in selected_animals:
			for side in [-1, 1]:
				for vertical in [-1, 1]:
					var corner = p + Vector2(side * 23, vertical * 24)
					draw_line(corner, corner - Vector2(side * 7, 0), Color("ffe2a3"), 3 if a.id == selected_animal else 2)
					draw_line(corner, corner - Vector2(0, vertical * 7), Color("ffe2a3"), 3 if a.id == selected_animal else 2)
		if debug_view: label_on(self, p + Vector2(25, 0), a.state, 12)
	for hit in hit_effects:
		var p = center(view_positions.get(hit.target, Vector2.ZERO))
		var fade = 1.0 - (clock - hit.at) / 0.3
		draw_arc(p, 17, -0.8, 1.1, 8, Color(1, 0.85, 0.45, fade), 3)
	for f in dust:
		var age = (visual_time - f.at) / 0.55
		for i in range(6):
			var q = f.pos + Vector2(cos(i * 2.4) * age * 22, -sin(age * PI) * (8 + i * 2))
			var tint = Color("b8a47b") if f.kind != "collect" else Color("b5cd83")
			tint.a = (1 - age) * 0.7
			draw_rect(Rect2(q, Vector2(3, 3) if f.kind in ["break", "remove"] else Vector2(5, 3)), tint)
	draw_work_plans()
	if cinematic(): return
	var cell = Vector2i(get_canvas_transform().affine_inverse() * pointer / TILE)
	if world.working() and world.inside(cell) and not pointer_over_ui():
		var valid = false
		var show_preview = false
		if tool == "place_animal" and selected_animal >= 0:
			valid = world.valid_animal_site(selected_animal, cell)
			show_preview = true
			var p = center(cell)
			draw_set_transform(p, 0, Vector2.ONE)
			art_alpha = 0.45
			var animal = world.animals.filter(func(a): return a.id == selected_animal)[0]
			if animal.species == "shiba": draw_dog(Vector2.ZERO)
			elif animal.species == "cat": draw_cat(Vector2.ZERO)
			else: draw_hen(Vector2.ZERO)
			art_alpha = 1.0
			draw_set_transform(Vector2.ZERO)
		elif Farm.BUILD.has(tool):
			valid = world.can_build(tool, cell)
			show_preview = true
			draw_rect(Rect2(Vector2(cell) * TILE + Vector2(3, 4), TILE - Vector2(6, 8)), Color(0.8, 0.8, 0.6, 0.3))
		if show_preview:
			draw_rect(Rect2(Vector2(cell) * TILE + Vector2(2, 2), TILE - Vector2(4, 4)), Color("a3e5ba") if valid else Color("ee8a77"), false, 3)
			var mark = center(cell) + Vector2(17, -22)
			if valid:
				draw_polyline(PackedVector2Array([mark + Vector2(-5, 0), mark + Vector2(-1, 4), mark + Vector2(6, -5)]), Color("d7edb7"), 3)
			else:
				draw_line(mark - Vector2(4, 4), mark + Vector2(4, 4), Color("f2ab90"), 3)
				draw_line(mark + Vector2(-4, 4), mark + Vector2(4, -4), Color("f2ab90"), 3)
	if selected.get("kind") in ["structure", "resource"]:
		draw_rect(Rect2(Vector2(selected.pos) * TILE + Vector2(1, 1), TILE - Vector2(2, 2)), Color("ffe2a3"), false, 3)
	if group == 0 and selected.get("kind") == "structure":
		for p in selected_structures:
			if world.live_structure(p): draw_rect(Rect2(Vector2(p) * TILE + Vector2(2, 2), TILE - Vector2(4, 4)), Color("ffe2a3"), false, 2)

func panel(area: Rect2): hud.draw_style_box(UI.surface(Color("485d46")), area)

func draw_hud():
	hud.draw_rect(Rect2(0, 49, 1280, 703), Color(0.04, 0.07, 0.22, night_tint))
	if night_tint > 0.05:
		for entry in world.entries:
			var q = screen_cell(entry) + Vector2(0, -45)
			hud.draw_circle(q, 28, Color(1, 0.77, 0.3, night_tint * 0.22))
			hud.draw_rect(Rect2(q - Vector2(4, 6), Vector2(8, 12)), Color("efd99b"))
	if cinematic(): return
	if world.phase == "shop":
		draw_shop()
		return
	if world.phase == "dawn":
		hud.draw_style_box(UI.surface(UI.PAPER), Rect2(330, 72, 620, 106))
		label_on(hud, Vector2(365, 118), "夜明け", 30, Color("485e48"))
		label_on(hud, Vector2(368, 153), "よく守ったね", 18, Color("526444"))
		hud.draw_texture(UI.icon("spark"), Vector2(533, 119))
		label_on(hud, Vector2(560, 138), "+%d EXP" % world.score.xp, 27, Color("456358"))
		draw_card_icon(hud, "gold", Vector2(786, 127), 0.9)
		label_on(hud, Vector2(819, 138), "+%d" % (world.score.gold + world.early_finish_bonus), 27, Color("85652f"))
		var x = 460
		for row in [["egg", world.dawn_summary.eggs], ["hen", world.dawn_summary.chicks], ["feather", world.dawn_summary.feathers]]:
			if row[1] <= 0: continue
			draw_card_icon(hud, row[0], Vector2(x, 211), 0.8)
			label_on(hud, Vector2(x + 28, 221), "+%d" % row[1], 24)
			x += 135
		if world.dawn_summary.hens > 0: label_on(hud, Vector2(421, 266), "鶏へ成長  %d" % world.dawn_summary.hens, 19)
		if not world.dawn_summary.unconscious.is_empty(): label_on(hud, Vector2(421, 292), "明日は休養  %d匹" % world.dawn_summary.unconscious.size(), 19)
		return

	if dragging:
		var start = get_canvas_transform() * drag_start
		var area = Rect2(start, pointer - start).abs()
		hud.draw_rect(area, Color(0.65, 0.9, 0.76, 0.15))
		hud.draw_rect(area, Color("b6ebc5"), false, 2)
	panel(Rect2(0, 0, 1280, 49))
	label_on(hud, Vector2(18, 31), "%d日目 %s" % [world.campaign.day, "昼" if world.phase == "day" else "夜"], 20)
	for i in range(4):
		var kind = ["soil", "wood", "stone", "gold"][i]
		BoardArt.draw_resource(hud, Vector2(162 + i * 115, 24), kind)
		label_on(hud, Vector2(181 + i * 115, 31), str(world.campaign.gold if kind == "gold" else world.resource_amount(kind)), 20)
	if Rect2(142, 0, 480, 49).has_point(pointer):
		panel(Rect2(145, 50, 390, 30))
		label_on(hud, Vector2(154, 71), "土 / 木材 / 石 / Gold  ·  キノコ %d" % world.campaign.mushrooms, 14)
	var remaining = maxf(0, world.day_seconds - world.tick * Farm.DT) if world.phase == "day" else world.remaining_night()
	label_on(hud, Vector2(720, 31), "%s %02d:%02d" % ["日暮れまで" if world.phase == "day" else "夜明けまで", int(remaining) / 60, int(remaining) % 60], 18)
	panel(Rect2(0, 748, 505, 52))
	if clock < message_until and world.tick < message_until_tick and world.phase != "result":
		panel(Rect2(16, 60, minf(800, message.length() * 16 + 28), 35))
		label_on(hud, Vector2(28, 84), message, 16)
	if alert_visible() and alert_kind != "early_clear":
		var urgent = alert_kind in ["restrained", "carried", "animal_danger"]
		var top = 330 if alert_kind == "auto_start" else 62
		hud.draw_style_box(UI.surface(UI.DANGER if urgent else UI.MOSS), Rect2(440, top, 400, 42))
		label_on(hud, Vector2(455, top + 29), alert_text, 20)
	if world.keeper.state in ["restrained", "captured"]:
		draw_edge(world.keeper.pos, "主人公 !", Color("ffa58a"))
	for a in world.animals:
		if a.placed and a.hp <= a.max_hp * Farm.Rules.LOW_HP_FRACTION: draw_edge(a.pos, Farm.animal_name(a) + " !", Color("ff997f"))
	if alert_kind == "invasion" and alert_visible():
		for entry in world.entries: draw_edge(entry, "侵入 !", Color("f5d483"))
	var details = ""
	if selected.get("kind") == "resource":
		details = "もう一度クリックで回収を頼む" if collectible(selected.pos) else "回収済み"
		if world.items_at(selected.pos).any(func(item): return item.kind == "kennel_plan"): details = "犬小屋の設計図\nもう一度クリックで回収・建築解放"
	elif selected.get("kind") == "keeper":
		draw_keeper_card()
	elif selected.get("kind") == "animal":
		draw_companion_card()
	elif selected.get("kind") == "enemy":
		for e in world.enemies:
			if e.id != selected.id: continue
			hud.draw_style_box(companion_box(), Rect2(16, 609, 344, 80))
			hud.draw_circle(Vector2(53, 642), 13, Color("d2b396"))
			hud.draw_rect(Rect2(37, 625, 32, 8), Color("454453"))
			hud.draw_rect(Rect2(40, 639, 27, 6), Color("454453"))
			label_on(hud, Vector2(92, 634), "誘拐者", 20)
			label_on(hud, Vector2(286, 634), "Lv%d" % e.lv, 15)
			hud.draw_rect(Rect2(92, 646, 150, 9), Color("293d35"))
			hud.draw_rect(Rect2(92, 646, 150.0 * e.hp / e.max_hp, 9), Color("d2aa80"))
			var status = "撃退済み" if e.hp <= 0 or e.flee or e.done else ("主人公を発見" if e.can_see_keeper else e.search_state)
			label_on(hud, Vector2(92, 677), "%d/%d  視界%d" % [e.hp, e.max_hp, e.sight_range] if Rect2(16, 609, 344, 80).has_point(pointer) else status, 15)
	elif selected.get("kind") == "structure" and world.structures.has(selected.pos):
		var b = world.structures[selected.pos]
		var quote = world.repair_quote(selected.pos)
		details = "%s Lv1   耐久 %d/%d\n[E] 修理 / [Del] 解体 → %s" % [{"wall": "壁", "gate": "門", "kennel": "犬小屋", "coop": "鶏小屋"}.get(b.kind, b.kind), b.hp, b.max_hp, resource_text({b.get("resource", "soil"): world.dismantle_quote(selected.pos)})]
		if selected_structures.size() > 1:
			var refund = {"soil": 0, "wood": 0, "stone": 0}
			for cell in selected_structures: refund[world.structures[cell].get("resource", "soil")] += world.dismantle_quote(cell)
			details = "まとめて %dか所\n[Del] 解体 → %s" % [selected_structures.size(), resource_text(refund)]
	if details != "":
		panel(Rect2(16, 595, 422, 91))
		var lines = details.split("\n")
		for i in range(lines.size()): label_on(hud, Vector2(30, 638 + i * 25), lines[i], 16)
	var cell = Vector2i(get_canvas_transform().affine_inverse() * pointer / TILE)
	if tool == "collect" and world.natural.has(cell) and not pointer_over_ui():
		var p = pointer.clamp(Vector2(8, 120), Vector2(950, 628)) + Vector2(15, -45)
		panel(Rect2(p, Vector2(270, 34)))
		label_on(hud, p + Vector2(10, 24), {"weed": "雑草：回収で +1 Gold", "mushroom": "キノコ：終了時に HP +5", "stump": "切り株：回収で 木材 +20"}[world.natural[cell]], 16)
	if tool == "repair" and world.structures.has(cell) and not pointer_over_ui():
		var b = world.structures[cell]
		var quote = world.repair_quote(cell)
		var p = pointer.clamp(Vector2(8, 120), Vector2(950, 628)) + Vector2(15, -55)
		panel(Rect2(p, Vector2(266, 56)))
		label_on(hud, p + Vector2(10, 22), "%s %d/%d → 修理 +%d" % [{"wall": "壁", "gate": "門", "kennel": "犬小屋", "coop": "鶏小屋"}.get(b.kind, b.kind), b.hp, b.max_hp, quote.hp], 16)
		label_on(hud, p + Vector2(10, 45), "%s%s" % [resource_text({b.get("resource", "soil"): quote.cost}), " / 停止中は不可" if world.paused else ""], 16)
	if world.phase == "result":
		panel(Rect2(362, 225, 554, 340))
		label_on(hud, Vector2(398, 271), "守りきった！" if world.result == "win" else "主人公が連れ去られた", 27)
		label_on(hud, Vector2(398, 311), "評価 %d   EXP +%d   GOLD +%d" % [world.score.rating, world.score.xp, world.score.gold], 18)
	if world.working() and world.early_clear:
		label_on(hud, Vector2(935, 735), "夜明けまで自由に", 16)
	if debug_view: label_on(hud, Vector2(15, 125), "DEBUG: seed %d / tick %d  F8:観察JSON" % [world.seed_value, world.tick], 14)

func draw_edge(cell: Vector2i, title: String, color: Color):
	var p = screen_cell(cell)
	var visible = Rect2(24, 115, 1232, 568)
	if visible.has_point(p): return
	var edge = p.clamp(visible.position, visible.end)
	var direction = (p - Vector2(640, 400)).normalized()
	var normal = Vector2(-direction.y, direction.x)
	hud.draw_colored_polygon(PackedVector2Array([edge + direction * 10, edge - direction * 9 + normal * 7, edge - direction * 9 - normal * 7]), color)
	# Small animal/keeper head silhouette alongside the arrow.
	hud.draw_circle(edge + Vector2(-10, 17), 5, color)
	label_on(hud, (edge + Vector2(0, 32)).clamp(Vector2(24, 120), Vector2(1140, 700)), title, 16, color)

func draw_dog(p: Vector2, animal: Dictionary = {}):
	# Original small pixel silhouette: curled tail, cream muzzle and pointed ears.
	var resting = animal.get("state", "") in ["休む", "自主休養"]
	var walking = not animal.is_empty() and Vector2(animal.pos).distance_to(view_positions.get("a%d" % animal.id, Vector2(animal.pos))) > 0.025
	var reaction = reactions.get(animal.get("id", -1), {})
	var mood = reaction.get("kind", "" ) if clock < reaction.get("until", -1) else ""
	var stride = sin(visual_time * 16) * (3 if walking else 0)
	var facing = dog_facing(animal)
	if mood == "happy": p.y -= absf(sin((clock - reaction.at) * 9)) * 7
	var sitting = animal.get("mode", "") == "stay" and not walking
	if resting:
		rect(p + Vector2(-16, 4), Vector2(34, 12), "bd713c")
		rect(p + Vector2(7, 1), Vector2(16, 13), "d9924f")
		rect(p + Vector2(14, 9), Vector2(12, 6), "f4deb0")
		rect(p + Vector2(18, 6), Vector2(5, 2), "293d37")
		return
	p.y -= absf(stride) * 0.5 + sin(visual_time * 2) * 0.5
	rect(p + Vector2(-10 if sitting else -14, -7), Vector2(19 if sitting else 26, 24 if sitting else 19), "bd713c")
	dog_part(p, Vector2(2, -13), Vector2(19, 18), "d9924f", facing)
	dog_part(p, Vector2(3, -20), Vector2(5, 9), "9c5630", facing)
	dog_part(p, Vector2(16, -20), Vector2(5, 9), "9c5630", facing)
	dog_part(p, Vector2(9, -2), Vector2(14, 8), "f4deb0", facing)
	dog_part(p, Vector2(18, -6), Vector2(3, 3), "293d37", facing)
	rect(p + Vector2(-12 + stride, 14 if sitting else 10), Vector2(10 if sitting else 6, 3 if sitting else 7), "e5b27c")
	rect(p + Vector2(6 - stride, 10), Vector2(6, 7), "e5b27c")
	var wag = sin(visual_time * (16 if mood in ["wag", "happy", "hello"] else 2)) * (5 if mood != "" else 0.7)
	draw_arc(p + Vector2(-15 * facing, -8 + wag), 8, 0.1, 5.4, 9, Color(Color("f2d3a4"), art_alpha), 5)
	if mood == "hello":
		dog_part(p, Vector2(4, -6), Vector2(3, 3), "293d37", facing)
		dog_part(p, Vector2(10, 4), Vector2(4, 4), "d8887a", facing)
	elif mood == "alert":
		draw_line(p + Vector2(3, -24), p + Vector2(0, -30), Color("ffe0a5"), 2)
		draw_line(p + Vector2(13, -25), p + Vector2(15, -32), Color("ffe0a5"), 2)

func draw_hen(p: Vector2):
	var peck = maxf(0, sin(visual_time * 2.8 + p.x)) * 5
	draw_circle(p, 12, Color(Color("f4ebcf"), art_alpha))
	var head = p + Vector2(peck * 0.5, peck)
	rect(head + Vector2(3, -13), Vector2(12, 14), "fff4d8")
	rect(head + Vector2(5, -18), Vector2(8, 5), "c45d4d")
	rect(head + Vector2(15, -7), Vector2(5, 4), "edb65a")
	rect(head + Vector2(11, -10), Vector2(2, 2), "243d36")
	rect(p + Vector2(-6, 11), Vector2(3, 6), "d69a4e")
	rect(p + Vector2(4, 11), Vector2(3, 6), "d69a4e")

func resource_text(values: Dictionary) -> String:
	var parts: Array[String] = []
	for kind in values:
		if values[kind] != 0: parts.append("%s%d" % [{"soil": "土", "wood": "木", "stone": "石"}.get(kind, kind), values[kind]])
	return "0" if parts.is_empty() else " / ".join(parts)

func setup_menu():
	menu = Control.new()
	menu.size = Vector2(1280, 800)
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	controls.add_child(menu)
	var shade = ColorRect.new()
	shade.size = Vector2(1280, 800)
	shade.color = Color(0.03, 0.08, 0.06, 0.88)
	menu.add_child(shade)
	var title = Label.new()
	title.text = "ひと休み"
	title.position = Vector2(570, 250)
	title.add_theme_font_size_override("font_size", 28)
	menu.add_child(title)
	add_button(menu, "menu_resume", "続ける", Rect2(480, 320, 320, 50), toggle_menu)
	add_button(menu, "menu_retry", "昼からやり直す", Rect2(480, 390, 320, 50), restart_menu)
	add_button(menu, "menu_morning", "今朝からやり直す", Rect2(480, 460, 320, 50), restart_morning)
	menu.visible = false

func toggle_menu():
	if menu_open:
		world.paused = menu_was_paused
		menu_open = false
	else:
		menu_was_paused = world.paused
		world.paused = true
		menu_open = true
		keys_down.clear()
		dragging = false
	menu.visible = menu_open
	menu.move_to_front()
	refresh()

func restart_menu():
	retry_stage()

func shop_choose(side: String, category: String):
	shop_side = side
	shop_page = 0
	shop_category = category
	shop_level = "categories"
	product_row.clear()
	training_id = -1
	shop_notice = ""
	refresh()

func choose_category(category: String):
	shop_category = category
	shop_level = "list"
	shop_page = 0
	product_row.clear()
	shop_notice = ""
	refresh()

func inspect_product(row: Dictionary):
	product_row = row.duplicate()
	shop_level = "detail"
	shop_notice = ""
	refresh()

func market_back():
	shop_notice = ""
	if shop_side == "animals" and training_id >= 0:
		training_id = -1
		rename_open = false
	elif shop_level == "detail":
		shop_level = "list"
		product_row.clear()
	elif shop_level == "list":
		shop_level = "categories"
	else:
		shop_side = "home"
	refresh()

func trade(id: String, animal_id: int = -1):
	var ok = world.buy(id) if shop_side == "buy" else world.sell(id, animal_id)
	shop_notice = ("ありがとう。\n大事にしてね。" if shop_side == "buy" else "ありがとう、助かるよ。") if ok else "今は取引できないね。"
	if ok: play_alert("collect")
	refresh()
func shop_rows() -> Array:
	var rows = []
	var table = Farm.Shop.table()
	if shop_side == "buy":
		for row in world.shop_stock:
			if table[row.product].Category == shop_category: rows.append({"id": row.product, "count": row.remaining, "animal_id": -1})
	elif shop_category == "animals":
		for a in world.campaign.animals:
			if not table[a.species].Enabled: continue
			rows.append({"id": a.species, "count": 1, "animal_id": a.id, "lv": a.lv})
	else:
		for p in table.values():
			if p.Category != shop_category or not p.Enabled: continue
			var count = world.resource_amount(p.ProductID) / p.Amount if shop_category == "materials" else world.item_count(p.ProductID)
			if count > 0: rows.append({"id": p.ProductID, "count": count, "animal_id": -1})
	return rows

func build_shop():
	if shop_side == "home":
		for i in range(3):
			var id = ["buy", "sell", "animals"][i]
			add_card("shop_" + id, ["買う\n今日の品", "売る\n牧場の恵み", "動物\n大切な仲間"][i], id, Rect2(300 + i * 285, 263, 260, 246), shop_choose.bind(id, "animals"), [Color("d8b784"), Color("dcc783"), Color("bbcca3")][i])
		return
	var back_label = "戻る"
	if shop_side == "animals" and training_id >= 0: back_label = "仲間たちへ"
	elif shop_level == "detail": back_label = "商品一覧へ"
	elif shop_level == "list": back_label = "品の種類へ"
	add_button(palette, "shop_back", back_label, Rect2(288, 167, 174, 40), market_back)
	if shop_side == "animals":
		build_training()
		return
	if shop_level == "categories":
		var i = 0
		for category in MARKET_CATEGORIES:
			var row = MARKET_CATEGORIES[category]
			add_card("category_" + category, row[0] + "\n" + row[2], row[1], Rect2(360 + (i % 2) * 355, 230 + (i / 2) * 190, 327, 169), choose_category.bind(category), Color("cfbd96") if i % 2 == 0 else Color("bdc69d"))
			i += 1
		return
	if shop_level == "detail":
		var p = Farm.Shop.table()[product_row.id]
		var rows = shop_rows().filter(func(row): return row.id == product_row.id and row.animal_id == product_row.animal_id)
		var count = rows[0].count if not rows.is_empty() else 0
		var price = p.BuyPrice if shop_side == "buy" else p.SellPrice
		var can_trade = count > 0 and (world.campaign.gold >= price if shop_side == "buy" else (product_row.animal_id < 0 or world.campaign.animals.size() > 1))
		add_button(palette, "confirm_trade", ("迎える" if p.Category == "animals" else "買う") if shop_side == "buy" else "売る", Rect2(865, 492, 224, 54), trade.bind(p.ProductID, product_row.animal_id))
		buttons.confirm_trade.icon = UI.icon("coin")
		buttons.confirm_trade.disabled = not can_trade
		buttons.confirm_trade.tooltip_text = "売り切れ" if count <= 0 else ("手持ちが足りない" if shop_side == "buy" and world.campaign.gold < price else ("最後の仲間は手放せません" if not can_trade else ""))
		return
	var rows = shop_rows()
	for index in range(shop_page * 6, mini(rows.size(), shop_page * 6 + 6)):
		var row = rows[index]
		var p = Farm.Shop.table()[row.id]
		var price = p.BuyPrice if shop_side == "buy" else p.SellPrice
		var n = index % 6
		var price_tag = "%d G" % price if row.count > 0 else "売り切れ"
		add_card("trade_" + row.id + "_" + str(row.animal_id), product_title(row) + "\n" + price_tag, row.id, Rect2(300 + (n % 3) * 285, 237 + (n / 3) * 194, 260, 176), inspect_product.bind(row), Color("d4c29b") if row.count > 0 else Color("b9b99e"))
		buttons["trade_" + row.id + "_" + str(row.animal_id)].tooltip_text = product_description(row.id)
	if rows.size() > 6: add_button(palette, "shop_page", "次の品へ →", Rect2(935, 640, 215, 38), next_shop_page.bind(ceili(rows.size() / 6.0)))

func product_title(row: Dictionary) -> String:
	if row.get("animal_id", -1) >= 0:
		for a in world.campaign.animals:
			if a.id == row.animal_id: return Farm.animal_name(a) + " Lv%d" % a.lv
	return Farm.Shop.table()[row.id].Name

func product_description(id: String) -> String:
	if id == "coffee": return "眠気を少し和らげる。飲み物は1日2杯まで"
	if id == "energy_drink": return "眠気をぐっと和らげる。休息も忘れずに"
	return {"hen": "朝に卵を産む、のんびりした仲間。", "cat": "牧場を気ままに歩く、小さな仲間。", "soil": "壁や門を築くための、よく締まる土。", "wood": "小屋づくりに使う、丈夫な木材。", "stone": "重くて丈夫な石。", "egg": "牧場で産まれた新鮮な卵。", "feather": "鶏が落とした、軽く柔らかな羽。", "mushroom": "夜明けの休養に。傷ついた仲間を癒す。", "kennel_plan": "犬が落ち着いて休める、小屋の作り方。"}.get(id, "牧場で使う品物。")
func next_shop_page(count: int):
	shop_page = (shop_page + 1) % count
	refresh()

func add_card(id: String, title: String, icon: String, area: Rect2, callback: Callable, color: Color):
	add_button(palette, id, "", area, callback)
	var button = buttons[id]
	UI.button(button, color)
	button.draw.connect(draw_market_card.bind(button, icon, title))

func draw_market_card(button: Button, icon: String, title: String):
	var p = Vector2(button.size.x / 2, 55 if button.size.y < 220 else 75)
	draw_card_icon(button, icon, p, (2.3 if icon in ["soil", "wood", "stone"] else 1.3) if button.size.y < 220 else 1.6)
	var lines = title.split("\n")
	for i in range(lines.size()):
		var size_value = 22 if i == 0 else 16
		var width = FONT.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size_value).x
		label_on(button, Vector2((button.size.x - width) / 2, button.size.y - 49 + i * 26), lines[i], size_value, UI.INK)

func draw_shop():
	# The canopy, shelves and small paper tickets sit over the actual ranch.
	for i in range(15):
		hud.draw_rect(Rect2(265 + i * 61, 42, 61, 83), Color("d4b782") if i % 2 == 0 else Color("729187"))
		hud.draw_circle(Vector2(295 + i * 61, 125), 30, Color("d4b782") if i % 2 == 0 else Color("729187"))
	hud.draw_rect(Rect2(265, 40, 915, 8), Color("d9ba78"))
	hud.draw_style_box(UI.surface(UI.MOSS), Rect2(280, 60, 875, 57))
	label_on(hud, Vector2(295, 101), "朝の市", 32)
	draw_card_icon(hud, "gold", Vector2(833, 88), 0.65)
	label_on(hud, Vector2(865, 99), str(world.campaign.gold), 23)
	draw_card_icon(hud, "spark", Vector2(972, 88), 0.6)
	label_on(hud, Vector2(990, 99), "%d EXP" % world.campaign.exp_pool, 20)
	var heading = ""
	if shop_side == "animals": heading = "仲間たち" + ("  /  いつもの様子" if training_id >= 0 else "")
	elif shop_side != "home":
		heading = "買う" if shop_side == "buy" else "売る"
		if shop_level != "categories": heading += "  /  " + MARKET_CATEGORIES[shop_category][0]
		if shop_level == "detail": heading += "  /  " + product_title(product_row)
	if heading != "":
		hud.draw_style_box(UI.surface(UI.PAPER), Rect2(486, 167, 650, 40))
		label_on(hud, Vector2(503, 194), heading, 18, UI.INK)
	var shelf_y = [519] if shop_side == "home" else ([407, 600] if shop_level == "categories" and shop_side != "animals" else ([418, 611] if shop_rows().size() > 3 else ([418] if not shop_rows().is_empty() else [])))
	if shop_level != "detail" and shop_side != "animals":
		for y in shelf_y:
			hud.draw_style_box(UI.surface(Color("ab8655")), Rect2(285, y, 877, 14))
			for x in [307, 1126]: hud.draw_rect(Rect2(x, y + 14, 8, 22), UI.WOOD)
	var greeting = "いい朝だね。\n今日はいい品があるよ。" if shop_side == "home" else "ゆっくり見ていって。"
	if shop_notice != "": greeting = shop_notice
	hud.draw_style_box(UI.surface(UI.PAPER), Rect2(42, 353, 208, 90))
	hud.draw_colored_polygon(PackedVector2Array([Vector2(170, 353), Vector2(194, 334), Vector2(192, 353)]), UI.PAPER)
	var words = greeting.split("\n")
	for i in range(words.size()): label_on(hud, Vector2(55, 385 + i * 25), words[i], 16, UI.INK)
	if shop_side in ["buy", "sell"] and shop_level == "list" and shop_rows().is_empty():
		hud.draw_style_box(UI.surface(UI.PAPER), Rect2(485, 288, 430, 118))
		draw_card_icon(hud, "basket", Vector2(544, 342), 1.1)
		label_on(hud, Vector2(597, 344), "今日は空っぽだね。", 22, UI.INK)
		label_on(hud, Vector2(597, 377), "ほかの品も見ていこう。", 16, UI.INK)
	if shop_side in ["buy", "sell"] and shop_level == "detail": draw_product_detail()
	if shop_side == "animals" and training_id >= 0: draw_animal_detail()

func draw_product_detail():
	var p = Farm.Shop.table()[product_row.id]
	var rows = shop_rows().filter(func(row): return row.id == product_row.id and row.animal_id == product_row.animal_id)
	var count = rows[0].count if not rows.is_empty() else 0
	var price = p.BuyPrice if shop_side == "buy" else p.SellPrice
	hud.draw_style_box(UI.surface(UI.PAPER), Rect2(355, 237, 777, 340))
	hud.draw_style_box(UI.surface(Color("c2cda4")), Rect2(380, 267, 205, 231))
	draw_card_icon(hud, p.ProductID, Vector2(478, 360), 2.7)
	label_on(hud, Vector2(622, 294), product_title(product_row), 30, UI.INK)
	label_on(hud, Vector2(622, 339), product_description(p.ProductID), 17, UI.INK)
	draw_card_icon(hud, "gold", Vector2(642, 395), 0.8)
	label_on(hud, Vector2(677, 405), "%d G" % price, 29, UI.INK)
	label_on(hud, Vector2(622, 452), "売り切れ" if count <= 0 else ("残り %d" % count if shop_side == "buy" else "手持ち %d" % count), 17, UI.INK)
	var hint = ""
	if shop_side == "buy" and count > 0 and world.campaign.gold < price: hint = "手持ちが足りないね。"
	elif shop_side == "sell" and product_row.animal_id >= 0 and world.campaign.animals.size() <= 1: hint = "最後の仲間は手放せない。"
	elif shop_notice != "": hint = "受け取りました" if shop_side == "buy" else "渡しました"
	label_on(hud, Vector2(622, 527), hint, 17, UI.INK)
func train(id: int):
	shop_notice = "ひとつ成長した！" if world.train_animal(id) else "経験を積んでからまた来よう"
	refresh()

func edit_name(id: int):
	training_id = id
	rename_open = false
	refresh()

func save_name():
	if is_instance_valid(name_edit): world.rename_animal(training_id, name_edit.text)
	rename_open = false
	refresh()

func open_name():
	rename_open = true
	refresh()

func build_training():
	var owned = world.campaign.animals
	if training_id < 0:
		for i in range(shop_page * 4, mini(owned.size(), shop_page * 4 + 4)):
			var a = owned[i]
			var n = i % 4
			add_card("name_%d" % a.id, "%s\nLv%d" % [Farm.animal_name(a), a.lv], a.species, Rect2(355 + (n % 2) * 370, 235 + (n / 2) * 191, 340, 170), edit_name.bind(a.id), Color("c4cea7"))
		if owned.size() > 4: add_button(palette, "animal_page", "次の仲間 →", Rect2(925, 639, 170, 38), next_shop_page.bind(ceili(owned.size() / 4.0)))
		return
	add_button(palette, "train_%d" % training_id, "育てる  %d EXP" % world.level_cost(training_id), Rect2(611, 608, 286, 46), train.bind(training_id))
	buttons["train_%d" % training_id].icon = UI.icon("spark")
	for a in owned:
		if a.id == training_id:
			buttons["train_%d" % training_id].disabled = a.lv >= 5 or world.campaign.exp_pool < world.level_cost(training_id)
			if a.lv >= 5: buttons["train_%d" % training_id].text = "立派に育ったね"
	add_button(palette, "rename", "名前を変える", Rect2(924, 608, 192, 46), open_name)
	if rename_open:
		name_edit = LineEdit.new()
		name_edit.position = Vector2(610, 550)
		name_edit.size = Vector2(285, 42)
		name_edit.max_length = 12
		name_edit.add_theme_stylebox_override("normal", UI.surface(UI.PAPER))
		name_edit.add_theme_color_override("font_color", UI.INK)
		for a in owned:
			if a.id == training_id: name_edit.text = a.name
		palette.add_child(name_edit)
		add_button(palette, "save_name", "この名前にする", Rect2(924, 550, 192, 42), save_name)

func animal_hp(a: Dictionary) -> int:
	return Farm.SPECIES[a.species].hp + (a.lv - 1) * 4

func draw_animal_detail():
	for a in world.campaign.animals:
		if a.id != training_id: continue
		hud.draw_style_box(UI.surface(UI.PAPER), Rect2(355, 235, 783, 437))
		hud.draw_style_box(UI.surface(Color("c4cea7")), Rect2(375, 259, 210, 258))
		draw_card_icon(hud, a.species, Vector2(475, 340), 2.5)
		var hp = a.get("hp", animal_hp(a))
		var hp_max = animal_hp(a)
		label_on(hud, Vector2(404, 458), "休養中" if a.get("unavailable_through_day", 0) >= world.campaign.day else ("元気いっぱい" if hp == hp_max else "少しひと休み"), 19, UI.INK)
		hud.draw_style_box(UI.surface(UI.MOSS, UI.MOSS), Rect2(400, 479, 158, 10))
		hud.draw_rect(Rect2(402, 481, 154.0 * hp / hp_max, 6), Color("b5d28a"))
		label_on(hud, Vector2(609, 287), Farm.animal_name(a), 32, UI.INK)
		label_on(hud, Vector2(1003, 284), "Lv%d" % a.lv, 18, UI.INK)
		hud.draw_texture(UI.icon("heart"), Vector2(610, 308))
		label_on(hud, Vector2(635, 322), "%d / %d" % [hp, hp_max], 17, UI.INK)
		label_on(hud, Vector2(819, 322), "忠誠 %d%s" % [a.get("loyalty", 0), "  親密 %d" % a.affinity if a.affinity != null else ""], 15, UI.INK)
		var y = 367
		for id in Farm.SPECIES[a.species].skills:
			var skill = Farm.AnimalData.SKILLS[id]
			var ready = a.lv >= skill.unlock_level
			hud.draw_style_box(UI.surface(Color("d1d8b2") if ready else Color("d3cbb4")), Rect2(607, y - 18, 510, 74))
			hud.draw_texture(UI.icon("spark" if ready else "pause"), Vector2(622, y - 1))
			label_on(hud, Vector2(649, y + 10), skill.name, 21, UI.INK)
			var summary = {"bark": "ひと吠えで、近くの敵の足を止める。", "rescue": "連れ去られた主人公を急いで助けに行く。", "lay": "朝になると卵を産む。", "feather": "時々、きれいな羽を落とす。", "charm": "動物と仲良くなる素質。", "meow": "鳴き声で、敵の勢いを弱める。"}.get(id, skill.effect)
			label_on(hud, Vector2(624, y + 38), summary if ready else "Lv%dになったら覚える" % skill.unlock_level, 16, UI.INK)
			if skill.has("cooldown") and ready: label_on(hud, Vector2(997, y + 10), "%d秒ごと" % skill.cooldown, 14, UI.INK)
			y += 88
func restart_morning():
	world = Farm.new(world.morning_checkpoint, world.seed_value)
	reset_view()
	arrival_started = clock
	training_id = -1
	rename_open = false
	refresh()

func draw_card_icon(c: CanvasItem, kind: String, p: Vector2, scale_value: float):
	c.draw_set_transform(p, 0, Vector2.ONE * scale_value)
	if kind in ["shiba", "cat"]:
		var fur = Color("d49a5c") if kind == "shiba" else Color("aeb9c4")
		c.draw_rect(Rect2(-20, -5, 31, 21), fur)
		c.draw_rect(Rect2(1, -19, 24, 24), fur.lightened(0.16))
		c.draw_colored_polygon(PackedVector2Array([Vector2(1, -15), Vector2(3, -29), Vector2(12, -18)]), fur)
		c.draw_colored_polygon(PackedVector2Array([Vector2(17, -18), Vector2(23, -28), Vector2(25, -13)]), fur)
		c.draw_rect(Rect2(13, -7, 15, 10), Color("f8e5bd"))
		c.draw_circle(Vector2(18, -12), 2, Color("273a35"))
		c.draw_line(Vector2(-19, 3), Vector2(-28, -7), fur, 5)
	elif kind in ["coffee", "energy_drink"]:
		if kind == "coffee":
			c.draw_arc(Vector2(18, 3), 9, -PI/2, PI/2, 10, UI.WOOD, 5)
			c.draw_rect(Rect2(-18, -12, 34, 33), UI.PAPER)
			c.draw_rect(Rect2(-15, -10, 28, 5), Color("674736"))
			c.draw_line(Vector2(-26, 25), Vector2(26, 25), UI.WOOD, 4)
		else:
			c.draw_rect(Rect2(-10, -22, 20, 7), UI.WOOD)
			c.draw_rect(Rect2(-15, -14, 30, 39), Color("93ab73"))
			c.draw_rect(Rect2(-12, -2, 24, 17), UI.PAPER)
			c.draw_texture_rect(UI.icon("spark"), Rect2(-7, 0, 14, 14), false)
	elif kind == "hen":
		c.draw_circle(Vector2(-3, 4), 17, Color("f5e8bd"))
		c.draw_rect(Rect2(5, -20, 17, 23), Color("fff0ce"))
		c.draw_rect(Rect2(6, -26, 13, 7), Color("bd5e48"))
		c.draw_circle(Vector2(17, -11), 2, Color("293a34"))
		c.draw_colored_polygon(PackedVector2Array([Vector2(22,-7), Vector2(30,-4), Vector2(22,0)]), Color("e3ac54"))
	elif kind == "animals":
		c.draw_circle(Vector2(0, 6), 15, UI.MOSS)
		for q in [Vector2(-17,-13), Vector2(-5,-23), Vector2(10,-23), Vector2(22,-10)]: c.draw_circle(q, 7, UI.MOSS)
	elif kind == "kennel":
		c.draw_rect(Rect2(-22, -4, 44, 29), Color("bb8d56"))
		c.draw_colored_polygon(PackedVector2Array([Vector2(-28,-4), Vector2(0,-28), Vector2(28,-4)]), Color("81563b"))
		c.draw_rect(Rect2(-8, 6, 16, 19), UI.INK)
	elif kind == "basket":
		c.draw_arc(Vector2(0, -5), 19, PI, TAU, 12, UI.WOOD, 4)
		c.draw_rect(Rect2(-24, -5, 48, 28), Color("bc955c"))
		for x in [-16, 0, 16]: c.draw_line(Vector2(x, -5), Vector2(x, 23), UI.WOOD, 3)
		c.draw_line(Vector2(-24, 8), Vector2(24, 8), UI.WOOD, 3)
	elif kind == "buy":
		c.draw_line(Vector2(-30,-25), Vector2(-22,-25), UI.WOOD, 4)
		c.draw_line(Vector2(-22,-25), Vector2(-13,15), UI.WOOD, 4)
		c.draw_rect(Rect2(-17,-18,43,26), UI.WOOD, false, 4)
		for x in [-10,21]: c.draw_circle(Vector2(x,24), 5, UI.WOOD)
	elif kind == "spark":
		c.draw_colored_polygon(PackedVector2Array([Vector2(0,-18), Vector2(6,-5), Vector2(18,0), Vector2(6,6), Vector2(0,18), Vector2(-6,6), Vector2(-18,0), Vector2(-6,-5)]), UI.GOLD)
	elif kind == "sell" or kind == "gold":
		for q in [Vector2(-12,6), Vector2(12,6), Vector2(0,-10)]: BoardArt.draw_resource(c, q, "gold")
	elif kind in ["egg", "feather"]:
		if kind == "egg": c.draw_circle(Vector2.ZERO, 14, Color("f6e6b6"))
		else: c.draw_line(Vector2(-10,12), Vector2(12,-20), Color("f2dfbc"), 9)
	else: BoardArt.draw_resource(c, Vector2.ZERO, kind)
	c.draw_set_transform(Vector2.ZERO)
func draw_cat(p: Vector2):
	var stretch = maxf(0, sin(visual_time * 0.5 + p.x)) * 5
	draw_line(p + Vector2(-14 - stretch, 9), p + Vector2(9 + stretch, 9), Color("8f969d"), 6)
	rect(p + Vector2(-13, -4), Vector2(27, 15), "8f969d")
	rect(p + Vector2(3, -15), Vector2(17, 17), "b4bbc0")
	rect(p + Vector2(3, -21), Vector2(5, 9), "8f969d")
	rect(p + Vector2(16, -21), Vector2(4, 9), "8f969d")
	rect(p + Vector2(7, -9), Vector2(3, 3), "dadf81")
	rect(p + Vector2(16, -9), Vector2(3, 3), "dadf81")
	draw_line(p + Vector2(-12, 1), p + Vector2(-23, -15), Color("8f969d"), 5)
	for x in [-9, 7]: rect(p + Vector2(x, 8), Vector2(4, 8), "c0c5c4")

func draw_transition():
	var elapsed = clock - sky_started
	if elapsed >= 0 and elapsed < 2.0:
		var t = elapsed / 2.0
		var alpha = minf(1, minf(t * 10, (1 - t) * 10))
		var dawn = sky_kind == "dawn"
		var night_amount = 1 - t if dawn else t
		var sky = Color("bd7959").lerp(Color("152c51"), smoothstep(0.15, 0.8, night_amount))
		overlay.draw_rect(Rect2(0, 0, 1280, 800), Color(sky, alpha * 0.94))
		for i in range(8):
			overlay.draw_rect(Rect2(0, 470 + i * 42, 1280, 43), Color(sky.darkened(i * 0.07), alpha * 0.75))
		var sun_y = 310 + night_amount * 580
		overlay.draw_circle(Vector2(445, sun_y), 100, Color(1, 0.82, 0.43, alpha * (1 - smoothstep(0.25, 0.6, night_amount))))
		var moon = Vector2(780, 760 - night_amount * 530)
		var moon_alpha = alpha * smoothstep(0.2, 0.5, night_amount)
		overlay.draw_circle(moon, 90, Color(0.91, 0.95, 0.86, moon_alpha))
		overlay.draw_circle(moon + Vector2(39, -27), 78, Color(sky, moon_alpha))
		for star in [Vector2(300, 240), Vector2(515, 327), Vector2(988, 271), Vector2(920, 440)]:
			overlay.draw_rect(Rect2(star, Vector2(4, 4)), Color(0.9, 0.91, 0.73, moon_alpha * 0.6))

	elif world.working() and clock - victory_started < 1.9:
		var alpha = minf(1, (1.9 - (clock - victory_started)) * 3)
		overlay.draw_rect(Rect2(332, 268, 616, 114), Color(0.21, 0.34, 0.28, alpha * 0.94))
		label_on(overlay, Vector2(406, 338), "今夜の襲撃を退けた", 36, Color(1, 0.88, 0.55, alpha))

func cinematic() -> bool:
	return (world.phase == "shop" and clock - arrival_started < 2.6) or (sky_kind == "dawn" and clock >= sky_started and clock < sky_started + 2.0)

func react(id: int, kind: String, duration: float):
	reactions[id] = {"kind": kind, "at": clock, "until": clock + duration}

func draw_market_world():
	if world.phase == "shop":
		var settle = smoothstep(0, 1, clampf((clock - arrival_started) / 2.6, 0, 1))
		var owner = center(morning_keeper.lerp(Vector2(6, 13), settle))
		owner.y += sin(visual_time * 2) * 1.4
		draw_circle(owner + Vector2(0, 17), 15, Color(0.15, 0.23, 0.15, 0.2))
		rect(owner + Vector2(-8, -4), Vector2(17, 22), "80b6a5")
		draw_circle(owner + Vector2(0, -10), 9, Color("efcba4"))
		rect(owner + Vector2(-13, -22), Vector2(26, 8), "e4c074")
		var pups = world.campaign.animals.filter(func(a): return a.species == "shiba")
		if not pups.is_empty():
			var pup = center(morning_dog.lerp(Vector2(7, 13.5), settle)) + Vector2(0, sin(visual_time * 3) * 1.5)
			var tired = pups[0].get("hp", 40) <= 0 or pups[0].get("unavailable_through_day", 0) >= world.campaign.day
			draw_dog(pup, {"state": "休む", "mode": "rest", "pos": Vector2.ZERO, "id": -1} if tired else {})
			if not tired: draw_arc(pup + Vector2(-15, -8 + sin(visual_time * 8) * 3), 8, 0.1, 5.4, 9, Color("f2d3a4"), 4)
	if world.phase != "shop" and not (world.phase == "day" and clock - departure_started < 1.0): return
	var t = clampf((clock - arrival_started - 0.5) / 1.8, 0, 1)
	var q = center(Vector2(1.8, 5)) + Vector2(-240 * (1 - smoothstep(0, 1, t)), 0)
	if world.phase == "day": q = center(Vector2(1.8, 5)) - Vector2((clock - departure_started) * 280, 0)
	var rolling = world.phase == "day" or t < 1
	q.y += sin(visual_time * 18) * (1.3 if rolling else 0.25)
	draw_rect(Rect2(q + Vector2(-36, 14), Vector2(100, 22)), Color(0.13, 0.20, 0.13, 0.3))
	for dx in [-22, 20]:
		var wheel = q + Vector2(dx, 20)
		draw_circle(wheel, 10, Color("4c4438"))
		draw_arc(wheel, 7, 0, TAU, 12, Color("b69565"), 2)
		for i in range(3):
			var angle = i * TAU / 3 + (visual_time * 6 if rolling else 0)
			draw_line(wheel, wheel + Vector2.from_angle(angle) * 8, Color("b69565"), 2)
	draw_rect(Rect2(q - Vector2(34, 18), Vector2(60, 32)), Color("af7b43"))
	for i in range(5): draw_line(q + Vector2(-33 + i * 12, -15), q + Vector2(-33 + i * 12, 13), Color("795432"), 2)
	draw_rect(Rect2(q - Vector2(38, 44), Vector2(68, 15)), Color("dfbe6c"))
	for x in [-32, 30]: draw_line(q + Vector2(x, -34), q + Vector2(x, 6), Color("815d40"), 3)
	BoardArt.draw_resource(self, q + Vector2(-18, -12), "wood")
	BoardArt.draw_resource(self, q + Vector2(11, -12), "stone")
	draw_circle(q + Vector2(43, -8), 9, Color("edc492"))
	rect(q + Vector2(33, -19), Vector2(23, 6), "bb7852")
	rect(q + Vector2(34, 1), Vector2(18, 26), "bf795e")
	if not rolling:
		# Crates, coin purse and poultry basket stay beside the actual cart.
		for dx in [-25, 17]:
			draw_rect(Rect2(q + Vector2(dx - 17, 49), Vector2(31, 27)), Color("b88954"))
			draw_line(q + Vector2(dx - 15, 52), q + Vector2(dx + 11, 72), Color("765537"), 3)
		BoardArt.draw_resource(self, q + Vector2(-25, 46), "gold")
		draw_hen(q + Vector2(21, 47))
		for dx in [7, 16, 25, 34]: draw_line(q + Vector2(dx, 30), q + Vector2(dx, 65), Color("ac8757"), 2)

func draw_companion_card():
	for a in world.animals:
		if a.id != selected.id: continue
		hud.draw_style_box(companion_box(), Rect2(16, 609, 344, 80))
		draw_card_icon(hud, a.species, Vector2(54, 650), 0.85)
		label_on(hud, Vector2(90, 634), Farm.animal_name(a), 20)
		label_on(hud, Vector2(287, 633), "Lv%d" % a.lv, 15, Color("a8b9a3"))
		hud.draw_rect(Rect2(91, 646, 150, 9), Color("293d35"))
		hud.draw_rect(Rect2(91, 646, 150.0 * a.hp / a.max_hp, 9), Color("90c19b") if a.hp > a.max_hp * 0.3 else Color("df947a"))
		var resting = a.mode == "rest" or a.state == "自主休養"
		var state = "Zz" if resting or a.hp <= 0 else ("!" if a.rescuing else ("…" if a.mode == "stay" else "♪"))
		label_on(hud, Vector2(260, 660), state, 25, Color("edd49f"))
		var caption = "気絶" if a.hp <= 0 else ("助けに行く！" if a.rescuing else ("ひと休み" if resting else ("そばにいるよ" if a.mode == "stay" else "気ままに")))
		label_on(hud, Vector2(92, 678), "%d / %d" % [a.hp, a.max_hp] if Rect2(16, 609, 344, 80).has_point(pointer) else caption, 14, Color("b9c9b5"))
		if selected_animals.size() > 1: label_on(hud, Vector2(301, 677), "×%d" % selected_animals.size(), 16)

func companion_box() -> StyleBoxFlat:
	return UI.surface(UI.MOSS)

func dog_part(p: Vector2, offset: Vector2, size_value: Vector2, tint: String, facing: float):
	rect(p + Vector2(facing * (offset.x + size_value.x / 2) - size_value.x / 2, offset.y), size_value, tint)

func dog_facing(a: Dictionary) -> float:
	if a.is_empty() or a.get("mode", "") == "rest": return 1.0
	var enemies = world.enemies.filter(func(e): return not e.done and not e.flee and Farm.distance(e.pos, a.pos) <= a.detection_range)
	if not enemies.is_empty(): return -1.0 if enemies[0].pos.x < a.pos.x else 1.0
	var previous = view_positions.get("a%d" % a.id, Vector2(a.pos))
	return -1.0 if a.pos.x < previous.x - 0.02 else 1.0

func draw_keeper_card():
	var k = world.keeper
	hud.draw_style_box(UI.surface(UI.PAPER), Rect2(16, 595, 422, 91))
	hud.draw_circle(Vector2(48, 629), 12, Color("e9bd8b"))
	hud.draw_rect(Rect2(32, 616, 32, 6), UI.GOLD)
	label_on(hud, Vector2(78, 615), "牧場主", 17, UI.INK)
	for i in range(2):
		var y = 626 + i * 18
		hud.draw_texture_rect(UI.icon("heart" if i == 0 else "moon"), Rect2(78, y, 14, 14), false)
		hud.draw_rect(Rect2(100, y + 3, 170, 8), Color("b9b69c"))
		var ratio = float(k.hp) / k.max_hp if i == 0 else k.sleepiness / 100.0
		hud.draw_rect(Rect2(100, y + 3, 170 * ratio, 8), Color("bf7661") if i == 0 else Color("8087a7"))
		label_on(hud, Vector2(279, y + 12), "%d/%d" % [k.hp, k.max_hp] if i == 0 else "%d%%" % k.sleepiness, 13, UI.INK)
	var activity = "連れ去り" if k.carrier >= 0 else ("気絶" if k.state == "unconscious" else ("ぐっすり" if k.forced_rest else ("ひと休み" if k.resting else ("散歩中" if world.manual_goal != null else ("仕事は保留" if world.jobs_held else ("仕事中" if not world.jobs.is_empty() else "のんびり"))))))
	label_on(hud, Vector2(30, 676), activity, 15, UI.INK)
	if not world.jobs.is_empty():
		var names = {"wall": "壁", "build_gate": "門", "collect": "回収", "move": "歩く", "place_animal": "仲間", "repair": "修理", "remove": "解体", "gate": "門", "kennel": "犬小屋", "coop": "鶏小屋"}
		var next = names.get(world.jobs[0].kind, "仕事")
		if world.jobs.size() > 1: next += " → " + names.get(world.jobs[1].kind, "仕事")
		label_on(hud, Vector2(166, 676), next, 14, UI.INK)

func keeper_pixel() -> Vector2:
	if world.keeper.carrier >= 0:
		return center(view_positions.get("e%d" % world.keeper.carrier, Vector2(world.keeper.pos))) + Vector2(34,-36)
	return actor_pixel("keeper", world.keeper.pos)
