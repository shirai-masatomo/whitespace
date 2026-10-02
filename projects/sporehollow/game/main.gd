extends Node2D
const Farm = preload("res://game/world.gd")
const FONT = preload("res://assets/fonts/ui_font.tres")
const TILE = Vector2(48, 42)
const GROUPS = ["建設", "動物", "回収"]
const TOOLS = {"wall": "壁  10 / 1秒", "build_gate": "門  30", "repair": "修理", "gate": "門開閉", "remove": "解体", "kennel": "犬小屋 木20", "coop": "鶏小屋 木30",
	"auto": "おまかせ", "stay": "待機", "wander": "徘徊", "rest": "休む", "collect": "資源・卵・設計図", "dog_food": "犬用餌 HP+10", "hen_food": "鶏用餌 HP+8", "cat_food": "猫用餌 HP+8"}
const GROUP_TOOLS = [["wall", "build_gate", "kennel", "coop"], ["auto", "stay", "wander", "rest"], ["collect"]]
const BoardArt = preload("res://game/board_art.gd")
var world = Farm.new({}, randi_range(1, 2147483646))
var tool = "place_keeper"
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
var dragging = false
var drag_start = Vector2.ZERO
var selected: Dictionary = {}
var speed = 1.0
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
	add_button(controls, "home", "中央", Rect2(1208, 7, 62, 32), recenter)
	add_button(controls, "advance", "時計開始", Rect2(1074, 754, 190, 36), advance)
	add_button(controls, "retry", "再挑戦", Rect2(556, 514, 168, 38), retry_stage)
	for i in range(GROUPS.size()):
		add_button(controls, "group%d" % i, GROUPS[i], Rect2(16 + i * 122, 754, 116, 36), select_group.bind(i))
	audio = preload("res://game/farm_audio.gd").new()
	add_child(audio)
	setup_menu()
	overlay = Node2D.new()
	layer.add_child(overlay)
	overlay.draw.connect(draw_transition)
	refresh()
	if "--automated" in OS.get_cmdline_user_args(): automated = true
	if automated: get_window().unfocusable = true
	if "--smoke" in OS.get_cmdline_user_args(): get_tree().create_timer(2).timeout.connect(get_tree().quit)

func add_button(parent: Control, id: String, text_value: String, area: Rect2, callback: Callable):
	var button = Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.position = area.position
	button.size = area.size
	var box = StyleBoxFlat.new()
	box.bg_color = Color("263d32")
	box.border_color = Color("728467")
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	button.add_theme_stylebox_override("normal", box)
	var hover = box.duplicate()
	hover.bg_color = Color("476448")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
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
	notice("%d匹へ%sを予約" % [accepted, TOOLS[id]] if accepted else "指示できる動物を選択してください")

func cycle_subtool(reverse: bool = false):
	if world.phase != "defend" or group != 0: return
	var choices = GROUP_TOOLS[0].filter(func(id): return Farm.BUILD[id].get("blueprint", "") in ([""] + world.campaign.unlocked_blueprints))
	var index = choices.find(tool)
	var next = (choices.size() - 1 if reverse else 0) if index < 0 else posmod(index + (-1 if reverse else 1), choices.size())
	select_tool(choices[next], false)

func choose_animal(id: int, toggle: bool = false):
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
	refresh()

func collectible(cell: Vector2i) -> bool:
	return world.natural.has(cell) or not world.items_at(cell).is_empty()

func select_resource(cell: Vector2i):
	if group == 2 and tool == "collect" and selected.get("kind") == "resource" and selected.get("pos") == cell:
		if world.act("collect", cell):
			selected.clear()
			notice("回収しました")
		else: notice("停止中は回収できません")
	else:
		group = 2
		tool = "collect"
		selected = {"kind": "resource", "pos": cell}
		notice("もう一度クリックで回収")
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
		if id not in ["pause", "speed", "home", "advance", "retry", "group0", "group1", "group2", "menu_resume", "menu_retry", "menu_morning"]: buttons.erase(id)
	buttons.pause.visible = world.phase == "defend"
	buttons.speed.visible = world.phase == "defend"
	buttons.home.visible = world.phase == "defend"
	buttons.pause.text = "再開" if world.paused else "停止"
	buttons.speed.text = "×%s" % speed
	buttons.advance.visible = world.phase in ["shop", "dawn"] or (world.phase == "defend" and world.early_clear)
	buttons.advance.text = "商人を見送る" if world.phase == "shop" else ("朝の市へ" if world.phase == "dawn" else "今夜を終える +%dG" % floori(world.remaining_night() / 10.0))
	buttons.retry.visible = world.phase == "result"
	buttons.group1.text = "動物配置" if tool == "place_animal" else "動物"
	for i in range(3):
		buttons["group%d" % i].visible = world.phase == "defend"
		buttons["group%d" % i].modulate = Color("ffe0a0") if i == group else Color.WHITE
	if world.phase in ["prepare", "dawn"]:
		last_phase = world.phase
		return
	if world.phase == "shop":
		build_shop()
	elif group == 1:
		var deployed_selection = world.animals.filter(func(a): return a.id in selected_animals and a.placed)
		if deployed_selection.is_empty():
			var reserves = world.animals.filter(func(a): return world.available(a))
			for i in range(reserves.size()):
				var a = reserves[i]
				add_button(palette, "animal%d" % a.id, Farm.animal_name(a), Rect2(16 + i * 158, 698, 150, 42), choose_animal.bind(a.id))
				buttons["animal%d" % a.id].draw.connect(draw_card_icon.bind(buttons["animal%d" % a.id], a.species, Vector2(23, 21), 0.55))
		elif deployed_selection.any(func(a): return Farm.SPECIES[a.species].commands):
			for i in range(GROUP_TOOLS[1].size()):
				var id = GROUP_TOOLS[1][i]
				add_button(palette, id, TOOLS[id], Rect2(16 + i * 126, 704, 118, 36), select_tool.bind(id))
	elif group >= 0 and world.phase == "defend":
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
		if buttons.has(id): buttons[id].modulate = Color("ffe0a0") if tool == id else Color.WHITE
	last_phase = world.phase

func facility_action(action: String):
	if world.phase != "defend" or group != 0 or selected.get("kind") != "structure": return
	var targets = selected_structures.duplicate() if action == "remove" else [selected.pos]
	var count = 0
	var before = world.resource_snapshot()
	for cell in targets:
		if world.act(action, cell): count += 1
	notice(("%d施設を解体 → %s" % [count, resource_text({"soil": world.materials - before.soil, "wood": world.wood - before.wood, "stone": world.stone - before.stone})] if action == "remove" else TOOLS[action] + "しました") if count else ("停止中は実行できません" if world.paused else "占有・耐久・土を確認してください"))
	if action == "remove" and count:
		selected_structures = selected_structures.filter(func(p): return world.live_structure(p))
		selected = {"kind": "structure", "pos": selected_structures[0]} if not selected_structures.is_empty() else {}
	refresh()

func advance():
	if clock - sky_started < 2.0 or menu_open: return
	if world.paused: return
	if world.phase == "shop":
		world = world.begin_night()
		reset_view()
		sky_kind = "night"
		sky_started = clock
	elif world.phase == "dawn":
		world = Farm.new(world.next_campaign(), world.seed_value + 1)
		reset_view()
	elif world.phase == "defend": world.act("end_night")
	refresh()

func reset_view():
	sky_started = -10.0
	victory_started = -10.0
	shop_page = 0
	rename_open = false
	menu_open = false
	menu.visible = false
	shop_side = "home"
	shop_category = "animals"
	shop_notice = ""
	group = -1
	tool = "place_keeper"
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

func toggle_speed():
	speed = {0.5: 1.0, 1.0: 2.0, 2.0: 0.5}[speed]
	refresh()

func change_speed(direction: int):
	var steps = [0.5, 1.0, 2.0]
	speed = steps[clampi(steps.find(speed) + direction, 0, 2)]
	refresh()

func center(p: Vector2) -> Vector2:
	return (p + Vector2.ONE * 0.5) * TILE

func screen_cell(p: Vector2) -> Vector2:
	return get_canvas_transform() * center(p)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		toggle_menu()
		get_viewport().set_input_as_handled()
		return
	if menu_open or clock - sky_started < 2.0: return
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
			elif world.phase == "defend":
				select_group(posmod(group + (1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1), 3))
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			tool = "place_keeper" if world.phase == "prepare" else ""
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
			change_speed(-1)
			return
		if event.keycode in [KEY_PLUS, KEY_KP_ADD, KEY_EQUAL] or event.physical_keycode in [KEY_KP_ADD, KEY_EQUAL] or event.unicode == 43:
			change_speed(1)
			return
		match event.physical_keycode:
			KEY_SPACE: toggle_pause()
			KEY_TAB: cycle_subtool(event.shift_pressed)
			KEY_HOME: recenter()
			KEY_F3: debug_view = not debug_view
			KEY_F8: export_record()
			KEY_E: facility_action("repair")
			KEY_DELETE: facility_action("remove")
			KEY_1, KEY_2, KEY_3:
				if world.phase == "defend": select_group(event.physical_keycode - KEY_1)
		if event.physical_keycode in [KEY_SPACE, KEY_TAB, KEY_HOME, KEY_F3, KEY_F8, KEY_ESCAPE, KEY_1, KEY_2, KEY_3, KEY_E, KEY_DELETE]:
			get_viewport().set_input_as_handled()

func pointer_over_ui() -> bool:
	if world.phase == "prepare": return false
	if pointer.y < 49 or pointer.y > 748: return true
	if not selected.is_empty() and Rect2(16, 610, 422, 76).has_point(pointer): return true
	for button in buttons.values():
		if is_instance_valid(button) and button.is_visible_in_tree() and button.get_global_rect().has_point(pointer): return true
	return false

func _unhandled_input(event):
	if menu_open or clock - sky_started < 2.0: return
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
	if world.phase == "prepare":
		if world.act("place", cell):
			select_group(1)
			message_until = 0
		else: notice("ここには主人公を配置できません")
		return
	if world.phase != "defend": return
	if event.shift_pressed:
		dragging = true
		drag_start = get_canvas_transform().affine_inverse() * event.position
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
			notice("停止中は動物指示だけ" if world.paused else "対象・土・占有状態を確認してください")
		elif tool == "place_animal":
			choose_animal(selected_animal)
			notice("出撃しました。移動は指示で行います")
	else:
		selected.clear()
	refresh()

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		keys_down.clear()
		dragging = false

func _process(delta):
	clock += delta
	if not world.paused: visual_time += delta
	var direction = Vector2(int(keys_down.get(KEY_D, false)) - int(keys_down.get(KEY_A, false)), int(keys_down.get(KEY_S, false)) - int(keys_down.get(KEY_W, false)))
	if not menu_open and world.phase != "shop": camera.position += direction.normalized() * delta * 420
	var middle = Vector2(Farm.W, Farm.H) * TILE * 0.5
	camera.position = camera.position.clamp(middle - Vector2(500, 360), middle + Vector2(500, 360))
	if not world.paused and not automated and world.phase == "defend":
		accumulated += minf(delta, 0.1) * speed
		while accumulated >= Farm.DT:
			world.step()
			accumulated -= Farm.DT
	if last_phase != world.phase:
		refresh()
	if world.phase == "defend" and world.early_clear:
		buttons.advance.visible = true
		buttons.advance.text = "今夜を終える +%dG" % floori(world.remaining_night() / 10.0)
	buttons.advance.disabled = clock - sky_started < 2.0
	audio.set_night(world.phase in ["prepare", "defend"] and clock - sky_started > 1.0)
	var target_tint = 0.40 * clampf(world.remaining_night() / 25.0, 0, 1) if world.phase == "defend" else (0.4 if world.phase == "prepare" and clock - sky_started > 1.0 else 0.0)
	night_tint = move_toward(night_tint, target_tint, delta * 0.4)
	audio.tension(world.phase == "defend" and world.enemies.any(func(e): return not e.done and not e.flee))
	update_facility_effects(delta)
	for a in world.animals:
		if a.placed: smooth_actor("a%d" % a.id, a.pos, delta)
	for e in world.enemies: smooth_actor("e%d" % e.id, e.pos, delta)
	while seen_combat < world.combat_log.size():
		var hit = world.combat_log[seen_combat]
		seen_combat += 1
		if hit.source in ["animal", "enemy"]:
			hit_effects.append({"source": ("a" if hit.source == "animal" else "e") + str(hit.id), "target": ("e" if hit.source == "animal" else "a") + str(hit.target), "at": clock})
			play_alert("attack")
		elif hit.source == "object":
			for cell in world.structures:
				if world.structures[cell].id == hit.target: puff(center(cell), "hit")
			play_alert("object")
	hit_effects = hit_effects.filter(func(hit): return clock - hit.at < 0.3)
	while seen_milestones < world.milestones.size():
		var event = world.milestones[seen_milestones]
		seen_milestones += 1
		var names = {"auto_start": "敵の襲来に備えよ", "invasion": "！ 侵入者接近", "restrained": "主人公が拘束された！", "carried": "主人公が連れ去られている！", "rescue": "主人公を救出した！", "animal_danger": "動物のHPが危険！", "blueprint": "犬小屋の作り方を覚えた", "blueprint_dropped": "作り方のメモが落ちた", "early_clear": "今夜の襲撃を退けた", "dawn": "夜明け。生産と成長の時間です"}
		if event.kind == "early_clear": victory_started = clock
		if names.has(event.kind):
			alert_text = names[event.kind]
			alert_kind = event.kind
			alert_until = clock + (4.0 if event.kind in ["carried", "restrained"] else 2.5)
			alert_until_tick = event.tick + (16 if event.kind in ["carried", "restrained"] else 10)
			play_alert("rescue" if event.kind == "blueprint" else event.kind)
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
	while seen_actions < world.actions.size():
		var action = world.actions[seen_actions]
		seen_actions += 1
		if not action.accepted: continue
		var kind = action.kind
		if kind in ["repair", "remove", "collect", "gate"]:
			play_alert(kind)
			puff(center(Vector2i(action.pos[0], action.pos[1])), kind)
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
	if world.phase in ["shop", "dawn"] or (world.phase == "prepare" and clock - sky_started < 1.1):
		var q = center(Vector2(1.8, 5))
		if world.phase == "prepare": q.x -= (clock - sky_started) * 240
		draw_rect(Rect2(q - Vector2(34, 18), Vector2(60, 32)), Color("af7b43"))
		draw_rect(Rect2(q - Vector2(38, 35), Vector2(68, 19)), Color("dfbe6c"))
		for dx in [-22, 20]: draw_circle(q + Vector2(dx, 20), 9, Color("45443c"))
		draw_circle(q + Vector2(43, -8), 9, Color("edc492"))
		draw_rect(Rect2(q + Vector2(34, 1), Vector2(18, 26)), Color("bf795e"))
		label_on(self, q + Vector2(-36, -45), "朝の商人", 17)
	for e in world.enemies:
		if e.done or world.phase != "defend": continue
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
		if world.tick < e.sight_reaction_until: label_on(self, p + Vector2(15, -30), e.sight_reaction, 26, Color("ffe0a0"))
		elif e.state == "迷う": label_on(self, p + Vector2(15, -23), "?", 16, Color("c8cfb4"))
		if selected.get("kind") == "enemy" and selected.id == e.id:
			draw_rect(Rect2(p - Vector2(18, 23), Vector2(36, 49)), Color("e6c998"), false, 2)
	if world.keeper.placed:
		var p = center(world.keeper.pos)
		p.y += sin(visual_time * 1.7) * 0.8
		if world.keeper.carrier >= 0:
			var carrier_pos = view_positions.get("e%d" % world.keeper.carrier, Vector2(world.keeper.pos))
			p = center(carrier_pos) + Vector2(34, -36)
			draw_line(center(carrier_pos) + Vector2(8, 0), p + Vector2(0, 14), Color("d2b396"), 7)
			draw_line(p + Vector2(-11, 11), p + Vector2(12, 11), Color("e7c794"), 4)
			draw_set_transform(p, -PI * 0.5)
			p = Vector2.ZERO
		draw_circle(p + Vector2(0, -8), 9, Color("f3cda2"))
		rect(p + Vector2(-12, -18), Vector2(24, 6), "f1d690")
		rect(p + Vector2(-8, 1), Vector2(17, 20), "80d4cd")
		rect(p + Vector2(-7, 20), Vector2(5, 6), "30484a")
		rect(p + Vector2(3, 20), Vector2(5, 6), "30484a")
		if world.keeper.state in ["restrained", "captured"]:
			label_on(self, p + Vector2(14, -18), "!", 18, Color("f69773"))
			draw_line(p + Vector2(-10, 8), p + Vector2(10, 8), Color("513f39"), 3)
		draw_set_transform(Vector2.ZERO)
	for item in world.field_items:
		var q = center(item.pos) + (Vector2(7, 8) if item.kind == "kennel_plan" else Vector2.ZERO)
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
			draw_arc(p + Vector2(25, -8), 9, -0.8, 0.8, 8, Color("ffe3a0"), 2)
			draw_arc(p + Vector2(25, -8), 15, -0.8, 0.8, 8, Color("ffe3a0"), 2)
		elif a.state == "様子見": label_on(self, p + Vector2(17, -24), "…", 18, Color("ffe3a0"))
		if group == 1 and a.id in selected_animals:
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
	var cell = Vector2i(get_canvas_transform().affine_inverse() * pointer / TILE)
	if world.phase in ["prepare", "defend"] and world.inside(cell) and not pointer_over_ui():
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
		elif tool == "place_keeper":
			valid = world.walkable(cell) and not world.live_structure(cell) and not world.occupied(cell) and cell not in world.entries
			show_preview = true
			art_alpha = 0.55
			var p = center(cell)
			rect(p + Vector2(-10, -16), Vector2(21, 7), "f1d690")
			rect(p + Vector2(-7, -9), Vector2(15, 12), "f3cda2")
			rect(p + Vector2(-8, 3), Vector2(17, 20), "80d4cd")
			art_alpha = 1.0
		if show_preview: draw_rect(Rect2(Vector2(cell) * TILE + Vector2(2, 2), TILE - Vector2(4, 4)), Color("a3e5ba") if valid else Color("ee8a77"), false, 3)
	if selected.get("kind") in ["structure", "resource"]:
		draw_rect(Rect2(Vector2(selected.pos) * TILE + Vector2(1, 1), TILE - Vector2(2, 2)), Color("ffe2a3"), false, 3)
	if group == 0 and selected.get("kind") == "structure":
		for p in selected_structures:
			if world.live_structure(p): draw_rect(Rect2(Vector2(p) * TILE + Vector2(2, 2), TILE - Vector2(4, 4)), Color("ffe2a3"), false, 2)

func panel(area: Rect2): hud.draw_rect(area, Color(0.09, 0.16, 0.12, 0.94))

func draw_hud():
	hud.draw_rect(Rect2(0, 49, 1280, 703), Color(0.04, 0.07, 0.22, night_tint))
	if night_tint > 0.05:
		for entry in world.entries:
			var q = screen_cell(entry) + Vector2(0, -45)
			hud.draw_circle(q, 28, Color(1, 0.77, 0.3, night_tint * 0.22))
			hud.draw_rect(Rect2(q - Vector2(4, 6), Vector2(8, 12)), Color("efd99b"))
	if world.phase == "shop":
		draw_shop()
		return
	if world.phase == "dawn":
		hud.draw_rect(Rect2(355, 184, 570, 386), Color("e1d6af"))
		label_on(hud, Vector2(558, 249), "夜明け", 38, Color("485e48"))
		label_on(hud, Vector2(578, 289), "防衛成功", 23, Color("526444"))
		label_on(hud, Vector2(441, 351), "+%d EXP" % world.score.xp, 30, Color("456358"))
		draw_card_icon(hud, "coins", Vector2(695, 340), 1.0)
		label_on(hud, Vector2(730, 351), "+%d" % (world.score.gold + world.early_finish_bonus), 30, Color("85652f"))
		var x = 442
		for row in [["egg", world.dawn_summary.eggs], ["hen", world.dawn_summary.chicks], ["feather", world.dawn_summary.feathers]]:
			if row[1] <= 0: continue
			draw_card_icon(hud, row[0], Vector2(x, 410), 0.8)
			label_on(hud, Vector2(x + 28, 420), "+%d" % row[1], 24, Color("51604a"))
			x += 135
		if world.dawn_summary.hens > 0: label_on(hud, Vector2(421, 463), "鶏へ成長  %d" % world.dawn_summary.hens, 19, Color("51604a"))
		if not world.dawn_summary.unconscious.is_empty(): label_on(hud, Vector2(421, 492), "明日は休養  %d匹" % world.dawn_summary.unconscious.size(), 19, Color("85634f"))
		if world.dawn_summary.pending_blueprints > 0: label_on(hud, Vector2(421, 522), "作り方のメモは牧場に残っています", 17, Color("85634f"))
		return

	if dragging:
		var start = get_canvas_transform() * drag_start
		var area = Rect2(start, pointer - start).abs()
		hud.draw_rect(area, Color(0.65, 0.9, 0.76, 0.15))
		hud.draw_rect(area, Color("b6ebc5"), false, 2)
	if world.phase == "prepare":
		panel(Rect2(428, 26, 424, 71))
		label_on(hud, Vector2(464, 55), "今夜はどこで過ごす？", 24)
		label_on(hud, Vector2(515, 81), "好きな場所をクリック", 17)
		return
	panel(Rect2(0, 0, 1280, 49))
	label_on(hud, Vector2(18, 31), "%d日目 夜" % world.campaign.day, 20)
	for i in range(4):
		var kind = ["soil", "wood", "stone", "gold"][i]
		BoardArt.draw_resource(hud, Vector2(162 + i * 115, 24), kind)
		label_on(hud, Vector2(181 + i * 115, 31), str(world.campaign.gold if kind == "gold" else world.resource_amount(kind)), 20)
	if Rect2(142, 0, 480, 49).has_point(pointer):
		panel(Rect2(145, 50, 390, 30))
		label_on(hud, Vector2(154, 71), "土 / 木材 / 石 / Gold  ·  キノコ %d" % world.campaign.mushrooms, 14)
	label_on(hud, Vector2(796, 31), "残 %02d:%02d %s" % [int(world.remaining_night()) / 60, int(world.remaining_night()) % 60, "PAUSE" if world.paused else ""], 20)
	panel(Rect2(0, 748, 1280, 52))
	if world.phase == "prepare":
		label_on(hud, Vector2(650, 778), "動物の出撃は時計開始後・任意" if world.keeper.placed else "主人公を一度だけ配置", 15)
	elif world.phase == "defend":
		label_on(hud, Vector2(530, 779), ("動物配置：再配置不可" if tool == "place_animal" else (TOOLS.get(tool, "対象を選択") if tool != "" else "選択なし")) + "   WASD:移動 / Ctrl+ホイール:拡縮 / Space:停止", 14)
	if clock < message_until and world.tick < message_until_tick and world.phase != "result":
		panel(Rect2(16, 60, minf(800, message.length() * 16 + 28), 35))
		label_on(hud, Vector2(28, 84), message, 16)
	if alert_visible() and alert_kind != "early_clear":
		var urgent = alert_kind in ["restrained", "carried", "animal_danger"]
		var top = 330 if alert_kind == "auto_start" else 62
		hud.draw_rect(Rect2(410, top, 460, 48), Color("814a3d") if urgent else Color("685d37"))
		label_on(hud, Vector2(434, top + 32), alert_text, 23)
	if world.keeper.state in ["restrained", "captured"]:
		draw_edge(world.keeper.pos, "主人公 !", Color("ffa58a"))
	for a in world.animals:
		if a.placed and a.hp <= a.max_hp * Farm.Rules.LOW_HP_FRACTION: draw_edge(a.pos, Farm.animal_name(a) + " !", Color("ff997f"))
	if alert_kind == "invasion" and alert_visible():
		for entry in world.entries: draw_edge(entry, "侵入 !", Color("f5d483"))
	var details = ""
	if selected.get("kind") == "resource":
		details = "もう一度クリックで回収" if collectible(selected.pos) else "回収済み"
		if world.items_at(selected.pos).any(func(item): return item.kind == "kennel_plan"): details = "犬小屋の設計図\nもう一度クリックで回収・建築解放"
	elif selected.get("kind") == "animal":
		for a in world.animals:
			if a.id == selected.id: details = "%s Lv%d   HP %d/%d\n現在：%s" % [Farm.animal_name(a), a.lv, a.hp, a.max_hp, (TOOLS.get(a.mode, a.mode) if a.mode != "auto" else "おまかせ") if a.placed else "未配置"]
		if selected_animals.size() > 1: details = "%d匹を選択\n%s → クリックで一括指示" % [selected_animals.size(), TOOLS.get(tool, "指示ボタンを選択")]
	elif selected.get("kind") == "enemy":
		for e in world.enemies:
			if e.id == selected.id: details = "誘拐者 Lv%d   HP %d/%d\n視界 %d / %s" % [e.lv, e.hp, e.max_hp, e.sight_range, "主人公を発見" if e.can_see_keeper else e.search_state]
	elif selected.get("kind") == "structure" and world.structures.has(selected.pos):
		var b = world.structures[selected.pos]
		var quote = world.repair_quote(selected.pos)
		details = "%s Lv1   耐久 %d/%d\n[E] 修理 / [Del] 解体 → %s" % [{"wall": "壁", "gate": "門", "kennel": "犬小屋", "coop": "鶏小屋"}.get(b.kind, b.kind), b.hp, b.max_hp, resource_text({b.get("resource", "soil"): world.dismantle_quote(selected.pos)})]
		if selected_structures.size() > 1:
			var refund = {"soil": 0, "wood": 0, "stone": 0}
			for cell in selected_structures: refund[world.structures[cell].get("resource", "soil")] += world.dismantle_quote(cell)
			details = "%d施設を選択\n[Del] 一括解体 → %s" % [selected_structures.size(), resource_text(refund)]
	if details != "":
		panel(Rect2(16, 610, 422, 76))
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
	if world.phase == "defend" and world.early_clear:
		label_on(hud, Vector2(796, 735), "夜明けまで牧場の仕事を続けられます", 16)
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
	var stride = sin(visual_time * 16) * (3 if walking else 0)
	if resting:
		rect(p + Vector2(-16, 4), Vector2(34, 12), "bd713c")
		rect(p + Vector2(7, 1), Vector2(16, 13), "d9924f")
		rect(p + Vector2(14, 9), Vector2(12, 6), "f4deb0")
		rect(p + Vector2(18, 6), Vector2(5, 2), "293d37")
		return
	p.y -= absf(stride) * 0.5 + sin(visual_time * 2) * 0.5
	rect(p + Vector2(-14, -7), Vector2(26, 19), "bd713c")
	rect(p + Vector2(2, -13), Vector2(19, 18), "d9924f")
	rect(p + Vector2(3, -20), Vector2(5, 9), "9c5630")
	rect(p + Vector2(16, -20), Vector2(5, 9), "9c5630")
	rect(p + Vector2(9, -2), Vector2(14, 8), "f4deb0")
	rect(p + Vector2(18, -6), Vector2(3, 3), "293d37")
	rect(p + Vector2(-12 + stride, 10), Vector2(6, 7), "e5b27c")
	rect(p + Vector2(6 - stride, 10), Vector2(6, 7), "e5b27c")
	draw_arc(p + Vector2(-15, -8), 8, 0.1, 5.4, 9, Color(Color("f2d3a4"), art_alpha), 5)

func draw_hen(p: Vector2):
	draw_circle(p, 12, Color(Color("f4ebcf"), art_alpha))
	rect(p + Vector2(3, -13), Vector2(12, 14), "fff4d8")
	rect(p + Vector2(5, -18), Vector2(8, 5), "c45d4d")
	rect(p + Vector2(15, -7), Vector2(5, 4), "edb65a")
	rect(p + Vector2(11, -10), Vector2(2, 2), "243d36")
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
	title.text = "PAUSE"
	title.position = Vector2(570, 250)
	title.add_theme_font_size_override("font_size", 28)
	menu.add_child(title)
	add_button(menu, "menu_resume", "続ける", Rect2(480, 320, 320, 50), toggle_menu)
	add_button(menu, "menu_retry", "今夜をやり直す", Rect2(480, 390, 320, 50), restart_menu)
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
	shop_notice = ""
	refresh()

func trade(id: String, animal_id: int = -1):
	var ok = world.buy(id) if shop_side == "buy" else world.sell(id, animal_id)
	shop_notice = ("購入しました" if shop_side == "buy" else "売却しました") if ok else "Gold・在庫を確認（最後の動物は売却不可）"
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
		var titles = ["買う", "売る", "動物"]
		var subtitles = ["商人の品を見よう", "牧場の恵みを届けよう", "仲間の様子を見よう"]
		var ids = ["buy", "sell", "animals"]
		for i in range(3):
			add_card("shop_" + ids[i], titles[i] + "
" + subtitles[i], ids[i], Rect2(295 + i * 292, 250, 270, 280), shop_choose.bind(ids[i], "animals"), [Color("b87b54"), Color("ad9047"), Color("70957d")][i])
		return
	add_button(palette, "shop_back", "← 広場へ", Rect2(290, 155, 160, 40), shop_choose.bind("home", "animals"))
	if shop_side == "animals":
		build_training()
		return
	var i = 0
	for category in Farm.Shop.CATEGORIES:
		add_button(palette, "category_" + category, Farm.Shop.CATEGORIES[category], Rect2(465 + i * 170, 155, 157, 40), shop_choose.bind(shop_side, category))
		buttons["category_" + category].modulate = Color("ffdca6") if category == shop_category else Color.WHITE
		i += 1
	var rows = shop_rows()
	for index in range(shop_page * 6, mini(rows.size(), shop_page * 6 + 6)):
		var row = rows[index]
		var p = Farm.Shop.table()[row.id]
		var price = p.BuyPrice if shop_side == "buy" else p.SellPrice
		var title = p.Name
		if row.animal_id >= 0:
			for a in world.campaign.animals:
				if a.id == row.animal_id: title = Farm.animal_name(a) + " Lv%d" % a.lv
		var desc = {"hen": "朝に卵を産む", "cat": "気ままな仲間", "soil": "壁を築く", "wood": "小屋づくりに", "stone": "重くて丈夫", "egg": "牧場の新鮮な卵", "feather": "軽くて柔らかい", "mushroom": "休養のお供"}.get(row.id, "牧場の道具")
		var n = index % 6
		add_card("trade_" + row.id + "_" + str(row.animal_id), "%s
%d G  ·  残%d
%s" % [title, price, row.count, desc], row.id, Rect2(290 + n % 3 * 292, 220 + n / 3 * 218, 272, 198), trade.bind(row.id, row.animal_id), Color("8b805d") if shop_category == "materials" else Color("8a9c79"))
		buttons["trade_" + row.id + "_" + str(row.animal_id)].disabled = row.count <= 0 or (shop_side == "buy" and world.campaign.gold < price)
	if rows.size() > 6:
		add_button(palette, "shop_page", "次の品へ →", Rect2(935, 675, 215, 38), next_shop_page.bind(ceili(rows.size() / 6.0)))

func next_shop_page(count: int):
	shop_page = (shop_page + 1) % count
	refresh()

func add_card(id: String, title: String, icon: String, area: Rect2, callback: Callable, color: Color):
	add_button(palette, id, "


" + title, area, callback)
	var button = buttons[id]
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("fff3dc"))
	var box = StyleBoxFlat.new()
	box.bg_color = color.darkened(0.22)
	box.border_color = color.lightened(0.25)
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", box)
	var hover = box.duplicate()
	hover.bg_color = color
	button.add_theme_stylebox_override("hover", hover)
	button.draw.connect(draw_card_icon.bind(button, icon, Vector2(area.size.x / 2, 48 if area.size.y < 220 else 76), 1.6))

func draw_shop():
	hud.draw_rect(Rect2(265, 40, 915, 694), Color(0.18, 0.23, 0.19, 0.92))
	hud.draw_rect(Rect2(265, 40, 915, 8), Color("d9ba78"))
	label_on(hud, Vector2(295, 96), "%d日目  朝の市" % world.campaign.day, 32)
	label_on(hud, Vector2(785, 94), "%d G    %d EXP" % [world.campaign.gold, world.campaign.exp_pool], 22, Color("f8d885"))
	if shop_side == "home":
		label_on(hud, Vector2(317, 181), "今日は何から始めよう？", 24)
		panel(Rect2(48, 350, 197, 66))
		label_on(hud, Vector2(65, 380), "いい朝だね。", 19)
		label_on(hud, Vector2(65, 404), "ゆっくり見ていって。", 16)
	elif shop_side in ["buy", "sell"] and shop_rows().is_empty():
		label_on(hud, Vector2(470, 363), "今は並んでいないようだ", 23)
	label_on(hud, Vector2(295, 708), shop_notice, 18)
	if shop_side == "animals" and training_id >= 0: draw_animal_detail()

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
	for i in range(shop_page * 4, mini(owned.size(), shop_page * 4 + 4)):
		var a = owned[i]
		add_button(palette, "name_%d" % a.id, "%s
Lv%d  HP%d/%d" % [Farm.animal_name(a), a.lv, a.get("hp", animal_hp(a)), animal_hp(a)], Rect2(290, 216 + (i % 4) * 104, 242, 92), edit_name.bind(a.id))
		buttons["name_%d" % a.id].draw.connect(draw_card_icon.bind(buttons["name_%d" % a.id], a.species, Vector2(28, 42), 0.8))
		buttons["name_%d" % a.id].modulate = Color("ffe1a3") if a.id == training_id else Color.WHITE
	if owned.size() > 4: add_button(palette, "animal_page", "次の仲間 →", Rect2(290, 646, 242, 36), next_shop_page.bind(ceili(owned.size() / 4.0)))
	if training_id < 0: return
	add_button(palette, "train_%d" % training_id, "Lvアップ  %d EXP" % world.level_cost(training_id), Rect2(610, 606, 302, 44), train.bind(training_id))
	for a in owned:
		if a.id == training_id: buttons["train_%d" % training_id].disabled = a.lv >= 5 or world.campaign.exp_pool < world.level_cost(training_id)
	add_button(palette, "rename", "名前を変える", Rect2(942, 606, 192, 44), open_name)
	if rename_open:
		name_edit = LineEdit.new()
		name_edit.position = Vector2(600, 547)
		name_edit.size = Vector2(320, 44)
		name_edit.max_length = 12
		for a in owned:
			if a.id == training_id: name_edit.text = a.name
		palette.add_child(name_edit)
		add_button(palette, "save_name", "決める", Rect2(945, 547, 150, 44), save_name)

func animal_hp(a: Dictionary) -> int:
	return Farm.SPECIES[a.species].hp + (a.lv - 1) * 4

func draw_animal_detail():
	for a in world.campaign.animals:
		if a.id != training_id: continue
		draw_card_icon(hud, a.species, Vector2(625, 250), 1.8)
		label_on(hud, Vector2(703, 245), "%s  Lv%d" % [Farm.animal_name(a), a.lv], 26)
		label_on(hud, Vector2(703, 278), "HP %d / %d" % [a.get("hp", animal_hp(a)), animal_hp(a)], 20)
		label_on(hud, Vector2(595, 325), "忠誠 %d%s" % [a.get("loyalty", 0), "  ·  親密度 %d" % a.affinity if a.affinity != null else ""], 19)
		var y = 375
		for id in Farm.SPECIES[a.species].skills:
			var skill = Farm.AnimalData.SKILLS[id]
			var ready = a.lv >= skill.unlock_level
			label_on(hud, Vector2(595, y), "%s %s  Lv%d%s" % ["✓" if ready else "鍵", skill.name, skill.unlock_level, " / CT%d秒" % skill.cooldown if skill.has("cooldown") else " / 常時"], 20, Color("f7dda0") if ready else Color("a8b7ac"))
			label_on(hud, Vector2(615, y + 26), skill.effect, 17, Color("bdcbb9"))
			y += 70
		if a.species == "shiba": label_on(hud, Vector2(595, y), "Lv3 / Lv5   これからの成長", 18, Color("a8b7ac"))

func restart_morning():
	world = Farm.new(world.morning_checkpoint, world.seed_value)
	reset_view()
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
	elif kind == "hen":
		c.draw_circle(Vector2(-3, 4), 17, Color("f5e8bd"))
		c.draw_rect(Rect2(5, -20, 17, 23), Color("fff0ce"))
		c.draw_rect(Rect2(6, -26, 13, 7), Color("bd5e48"))
		c.draw_circle(Vector2(17, -11), 2, Color("293a34"))
		c.draw_colored_polygon(PackedVector2Array([Vector2(22,-7), Vector2(30,-4), Vector2(22,0)]), Color("e3ac54"))
	elif kind == "animals":
		c.draw_circle(Vector2(0, 6), 15, Color("f2d6a0"))
		for q in [Vector2(-17,-13), Vector2(-5,-23), Vector2(10,-23), Vector2(22,-10)]: c.draw_circle(q, 7, Color("f2d6a0"))
	elif kind == "buy":
		c.draw_line(Vector2(-30,-25), Vector2(-22,-25), Color("f9deb0"), 4)
		c.draw_line(Vector2(-22,-25), Vector2(-13,15), Color("f9deb0"), 4)
		c.draw_rect(Rect2(-17,-18,43,26), Color("e5bd76"), false, 4)
		for x in [-10,21]: c.draw_circle(Vector2(x,24), 5, Color("f9deb0"))
	elif kind == "sell" or kind == "gold":
		for q in [Vector2(-12,6), Vector2(12,6), Vector2(0,-10)]: BoardArt.draw_resource(c, q, "gold")
	elif kind in ["egg", "feather"]:
		if kind == "egg": c.draw_circle(Vector2.ZERO, 14, Color("f6e6b6"))
		else: c.draw_line(Vector2(-10,12), Vector2(12,-20), Color("f2dfbc"), 9)
	else: BoardArt.draw_resource(c, Vector2.ZERO, kind)
	c.draw_set_transform(Vector2.ZERO)
func draw_cat(p: Vector2):
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
		label_on(overlay, Vector2(490, 170), "牧場に朝が来た" if dawn else "夜のとばりが降りる", 34, Color(1, 0.95, 0.83, alpha))
	elif world.phase == "defend" and clock - victory_started < 1.9:
		var alpha = minf(1, (1.9 - (clock - victory_started)) * 3)
		overlay.draw_rect(Rect2(332, 268, 616, 114), Color(0.21, 0.34, 0.28, alpha * 0.94))
		label_on(overlay, Vector2(406, 338), "今夜の襲撃を退けた", 36, Color(1, 0.88, 0.55, alpha))
