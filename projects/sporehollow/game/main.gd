extends Node2D
const Farm = preload("res://game/world.gd")
const FONT = preload("res://assets/fonts/ui_font.tres")
const TILE = Vector2(48, 42)
const GROUPS = ["建設", "動物", "回収"]
const TOOLS = {"wall": "壁  10 / 1秒", "build_gate": "門  30（仮）", "repair": "修理", "gate": "門開閉", "remove": "解体", "kennel": "犬小屋 30（仮）",
	"auto": "おまかせ", "stay": "待機", "wander": "徘徊", "rest": "休む", "collect": "草・キノコ・卵", "feed": "餌を置く"}
const GROUP_TOOLS = [["wall", "build_gate", "kennel"], ["auto", "stay", "wander", "rest"], ["collect", "feed"]]
const BoardArt = preload("res://game/board_art.gd")
var world = Farm.new({}, randi_range(1, 2147483646))
var tool = "place_keeper"
var group = -1
var selected_animal = -1
var selected_animals: Array = []
var selected_structures: Array = []
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
var message = "牧場主を配置してください"
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
	tool = "place_animal" if index == 1 and selected_animal >= 0 and world.animals.any(func(a): return a.id == selected_animal and not a.placed) else ""
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
	if world.phase != "defend" or group not in [0, 1]: return
	if group == 1 and not world.animals.any(func(a): return a.placed and a.id in selected_animals): return
	var choices = GROUP_TOOLS[group]
	var index = choices.find(tool)
	var next = (choices.size() - 1 if reverse else 0) if index < 0 else posmod(index + (-1 if reverse else 1), choices.size())
	select_tool(choices[next], false)

func choose_animal(id: int, toggle: bool = false):
	var reserve = world.animals.any(func(a): return a.id == id and not a.placed)
	if toggle and not reserve:
		selected_animals = selected_animals.filter(func(other): return world.animals.any(func(a): return a.id == other and a.placed))
		if id in selected_animals: selected_animals.erase(id)
		else: selected_animals.append(id)
	else: selected_animals = [id]
	group = 1
	selected_animal = selected_animals[0] if not selected_animals.is_empty() else -1
	selected = {"kind": "animal", "id": selected_animal} if selected_animal >= 0 else {}
	tool = "place_animal" if reserve else (tool if tool in GROUP_TOOLS[1] else "auto")
	refresh()

func collectible(cell: Vector2i) -> bool:
	return world.natural.has(cell) or (world.has_nest() and cell == world.nest and world.eggs > 0)

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
	for child in palette.get_children():
		palette.remove_child(child)
		child.queue_free()
	for id in buttons.keys():
		if id not in ["pause", "speed", "home", "advance", "retry", "group0", "group1", "group2"]: buttons.erase(id)
	buttons.pause.visible = world.phase == "defend"
	buttons.speed.visible = world.phase == "defend"
	buttons.home.visible = world.phase != "prepare"
	buttons.pause.text = "再開" if world.paused else "停止"
	buttons.speed.text = "×%s" % speed
	buttons.advance.visible = world.result == "win"
	buttons.advance.text = "Stage 2へ" if world.stage == 1 else "新しい牧場"
	buttons.retry.visible = world.phase == "result"
	buttons.group1.text = "動物配置" if tool == "place_animal" else "動物"
	for i in range(3):
		buttons["group%d" % i].visible = world.phase == "defend"
		buttons["group%d" % i].modulate = Color("ffe0a0") if i == group else Color.WHITE
	if world.phase == "prepare":
		last_phase = world.phase
		return
	if world.result == "win":
		var shop = [["hen", "鶏 30G"], ["soil", "土50 15G（仮）"], ["feed", "餌3 8G"], ["shelter", "休憩所 28G"], ["fence", "門補強 24G"], ["sell_egg", "卵を売る"], ["cook_egg", "卵を餌へ"]]
		for i in range(shop.size()):
			add_button(palette, "buy_" + shop[i][0], shop[i][1], Rect2(398 + (i % 3) * 164, 352 + (i / 3) * 46, 154, 38), purchase.bind(shop[i][0]))
	elif group == 1:
		for i in range(world.animals.size()):
			var a = world.animals[i]
			add_button(palette, "animal%d" % a.id, "%s Lv%d%s" % ["柴犬" if a.species == "shiba" else "鶏", a.lv, " 出撃済" if a.placed else " 未配置"], Rect2(16 + i * 146, 704, 138, 36), choose_animal.bind(a.id))
		if world.animals.any(func(a): return a.id == selected_animal and a.placed):
			for i in range(GROUP_TOOLS[1].size()):
				var id = GROUP_TOOLS[1][i]
				add_button(palette, id, TOOLS[id], Rect2(22 + world.animals.size() * 146 + i * 126, 704, 118, 36), select_tool.bind(id))
	elif group >= 0 and world.phase == "defend":
		for i in range(GROUP_TOOLS[group].size()):
			var id = GROUP_TOOLS[group][i]
			add_button(palette, id, TOOLS[id], Rect2(16 + i * 190, 704, 182, 36), select_tool.bind(id))
			buttons[id].tooltip_text = {"wall": "壁：土10、建設1秒", "build_gate": "門：土30（仮）、建設1秒", "kennel": "犬小屋：土30・2秒（仮）。1匹専用、毎秒HP1回復", "collect": "雑草：1 Gold / キノコ：終了時HP5回復 / 卵：回収"}.get(id, TOOLS[id])
			if id in ["wall", "build_gate", "kennel"]: buttons[id].icon = BoardArt.icon("soil")
		if group == 0 and selected.get("kind") == "structure":
			add_button(palette, "repair", "E 修理", Rect2(596, 704, 116, 36), facility_action.bind("repair"))
			add_button(palette, "remove", "Del 解体", Rect2(722, 704, 124, 36), facility_action.bind("remove"))
			if world.structures.get(selected.pos, {}).get("kind") == "gate":
				add_button(palette, "gate", "門を開閉", Rect2(856, 704, 124, 36), facility_action.bind("gate"))
	for id in TOOLS:
		if buttons.has(id): buttons[id].modulate = Color("ffe0a0") if tool == id else Color.WHITE
	last_phase = world.phase

func facility_action(action: String):
	if world.phase != "defend" or group != 0 or selected.get("kind") != "structure": return
	var targets = selected_structures.duplicate() if action == "remove" else [selected.pos]
	var count = 0
	var before = world.materials
	for cell in targets:
		if world.act(action, cell): count += 1
	notice(("%d施設を解体 → 土%d" % [count, world.materials - before] if action == "remove" else TOOLS[action] + "しました") if count else ("停止中は実行できません" if world.paused else "占有・耐久・土を確認してください"))
	if action == "remove" and count:
		selected_structures = selected_structures.filter(func(p): return world.live_structure(p))
		selected = {"kind": "structure", "pos": selected_structures[0]} if not selected_structures.is_empty() else {}
	refresh()

func advance():
	if world.result == "win":
		world = Farm.new(world.next_campaign(), world.seed_value + 1) if world.stage == 1 else Farm.new({}, randi_range(1, 2147483646))
		reset_view()
	refresh()

func reset_view():
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
	accumulated = 0
	recenter()

func retry_stage():
	world = Farm.new(world.checkpoint, world.seed_value)
	reset_view()
	refresh()

func purchase(id: String):
	notice("購入しました" if world.buy(id) else "購入できません")
	refresh()

func toggle_pause():
	world.act("pause")
	accumulated = 0
	refresh()

func toggle_speed():
	speed = {0.5: 1.0, 1.0: 2.0, 2.0: 0.5}[speed]
	refresh()

func center(p: Vector2) -> Vector2:
	return (p + Vector2.ONE * 0.5) * TILE

func screen_cell(p: Vector2) -> Vector2:
	return get_canvas_transform() * center(p)

func _input(event):
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
			group = -1
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
		match event.physical_keycode:
			KEY_SPACE: toggle_pause()
			KEY_TAB: cycle_subtool(event.shift_pressed)
			KEY_HOME: recenter()
			KEY_F3: debug_view = not debug_view
			KEY_F8: export_record()
			KEY_ESCAPE:
				group = -1
				tool = "place_keeper" if world.phase == "prepare" else ""
				selected.clear()
				selected_animals.clear()
				selected_animal = -1
				dragging = false
				refresh()
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
		if is_instance_valid(button) and button.visible and button.get_global_rect().has_point(pointer): return true
	return false

func _unhandled_input(event):
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
			choose_animal(world.animals[0].id)
			notice("未配置の動物を選んで出撃。出撃は任意です")
		else: notice("ここには主人公を配置できません")
		return
	if world.phase != "defend": return
	if event.shift_pressed:
		dragging = true
		drag_start = get_canvas_transform().affine_inverse() * event.position
		return
	# Context selection takes precedence over the previously armed tool, even while paused.
	for a in world.animals:
		if a.placed and event.position.distance_to(get_canvas_transform() * actor_pixel("a%d" % a.id, a.pos)) < 25 * camera.zoom.x:
			choose_animal(a.id, event.ctrl_pressed)
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
	camera.position += direction.normalized() * delta * 420
	var middle = Vector2(Farm.W, Farm.H) * TILE * 0.5
	camera.position = camera.position.clamp(middle - Vector2(500, 360), middle + Vector2(500, 360))
	if not world.paused and not automated and world.phase == "defend":
		accumulated += minf(delta, 0.1) * speed
		while accumulated >= Farm.DT:
			world.step()
			accumulated -= Farm.DT
	if last_phase != world.phase:
		if world.phase == "result": play_alert(world.result)
		refresh()
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
		var names = {"auto_start": "敵の襲来に備えよ", "invasion": "！ 侵入者接近", "restrained": "主人公が拘束された！", "carried": "主人公が連れ去られている！", "rescue": "主人公を救出した！", "animal_danger": "動物のHPが危険！"}
		if names.has(event.kind):
			alert_text = names[event.kind]
			alert_kind = event.kind
			alert_until = clock + (4.0 if event.kind in ["carried", "restrained"] else 2.5)
			alert_until_tick = event.tick + (16 if event.kind in ["carried", "restrained"] else 10)
			play_alert(event.kind)
	while seen_skills < world.skill_log.size():
		seen_skills += 1
		play_alert("bark")
	queue_redraw()
	hud.queue_redraw()

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
	if b.kind == "kennel":
		draw_rect(Rect2(p + Vector2(-19, -7), Vector2(38, 29)), Color("b99160"))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-23, -7), p + Vector2(0, -21), p + Vector2(23, -7)]), Color("96624a"))
		draw_rect(Rect2(p + Vector2(-9, 4), Vector2(18, 18)), Color("39443b"))
		var owner = world.kennel_owner(Vector2i(p / TILE))
		if owner >= 0:
			draw_circle(p + Vector2(14, -1), 4, Color("c1e6a6"))
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
	if world.has_nest():
		draw_circle(center(world.nest), 18, Color("99794b"))
		for i in range(mini(world.eggs, 8)): draw_circle(center(world.nest) + Vector2(i % 4 * 7 - 10, i / 4 * 7), 4, Color("fff1ca"))
	for f in world.foods:
		draw_circle(center(f.pos), 10, Color("d3a762"))
		draw_circle(center(f.pos), 6, Color("70513b"))
	for e in world.enemies:
		if e.done: continue
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
		if e.state == "迷う": label_on(self, p + Vector2(15, -23), "?", 18, Color("f5cd89"))
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
		if a.state in ["休む", "自主休養"]: label_on(self, p + Vector2(14, -25), "Zz", 18, Color("c1e3db"))
		if a.rescuing: label_on(self, p + Vector2(-25, -20), "!!", 16, Color("b0f0de"))
		if world.tick - a.last_bark < 4:
			draw_arc(p + Vector2(25, -8), 9, -0.8, 0.8, 8, Color("ffe3a0"), 2)
			draw_arc(p + Vector2(25, -8), 15, -0.8, 0.8, 8, Color("ffe3a0"), 2)
		elif a.state == "様子見": label_on(self, p + Vector2(17, -24), "…", 18, Color("ffe3a0"))
		if group == 1 and a.id in selected_animals:
			draw_line(p + Vector2(-11, 21), p + Vector2(11, 21), Color("ffe2a3"), 3)
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
	if world.inside(cell) and not pointer_over_ui():
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
	if dragging:
		var start = get_canvas_transform() * drag_start
		var area = Rect2(start, pointer - start).abs()
		hud.draw_rect(area, Color(0.65, 0.9, 0.76, 0.15))
		hud.draw_rect(area, Color("b6ebc5"), false, 2)
	if world.phase == "prepare":
		panel(Rect2(428, 26, 424, 71))
		label_on(hud, Vector2(464, 55), "主人公を配置してください", 24)
		label_on(hud, Vector2(515, 81), "クリックで配置・開始", 17)
		return
	panel(Rect2(0, 0, 1280, 49))
	label_on(hud, Vector2(18, 31), "STAGE %d" % world.stage, 20)
	BoardArt.draw_resource(hud, Vector2(162, 24), "soil")
	label_on(hud, Vector2(181, 31), str(world.materials), 20)
	BoardArt.draw_resource(hud, Vector2(262, 24), "gold")
	label_on(hud, Vector2(281, 31), str(world.campaign.gold), 20)
	label_on(hud, Vector2(342, 31), "木材 —", 17, Color("acb99a"))
	if Rect2(142, 0, 272, 49).has_point(pointer):
		panel(Rect2(145, 50, 390, 30))
		label_on(hud, Vector2(154, 71), "土：建築・修理 / 木材：未使用 / キノコ %d" % world.campaign.mushrooms, 14)
	label_on(hud, Vector2(796, 31), "%02d:%02d   %s" % [int(world.tick * Farm.DT) / 60, int(world.tick * Farm.DT) % 60, "PAUSE" if world.paused else ""], 20)
	panel(Rect2(0, 748, 1280, 52))
	if world.phase == "prepare":
		label_on(hud, Vector2(650, 778), "動物の出撃は時計開始後・任意" if world.keeper.placed else "主人公を一度だけ配置", 15)
	elif world.phase == "defend":
		label_on(hud, Vector2(530, 779), ("動物配置：再配置不可" if tool == "place_animal" else (TOOLS.get(tool, "対象を選択") if tool != "" else "選択なし")) + "   WASD:移動 / Ctrl+ホイール:拡縮 / Space:停止", 14)
	if clock < message_until and world.tick < message_until_tick and world.phase != "result":
		panel(Rect2(16, 60, minf(800, message.length() * 16 + 28), 35))
		label_on(hud, Vector2(28, 84), message, 16)
	if alert_visible():
		var urgent = alert_kind in ["restrained", "carried", "animal_danger"]
		var top = 330 if alert_kind == "auto_start" else 62
		hud.draw_rect(Rect2(410, top, 460, 48), Color("814a3d") if urgent else Color("685d37"))
		label_on(hud, Vector2(434, top + 32), alert_text, 23)
	if world.keeper.state in ["restrained", "captured"]:
		draw_edge(world.keeper.pos, "主人公 !", Color("ffa58a"))
	for a in world.animals:
		if a.placed and a.hp <= a.max_hp * Farm.Rules.LOW_HP_FRACTION: draw_edge(a.pos, "柴犬 !" if a.species == "shiba" else "鶏 !", Color("ff997f"))
	if alert_kind == "invasion" and alert_visible():
		for entry in world.entries: draw_edge(entry, "侵入 !", Color("f5d483"))
	var details = ""
	if selected.get("kind") == "resource":
		details = "もう一度クリックで回収" if collectible(selected.pos) else "回収済み"
	elif selected.get("kind") == "animal":
		for a in world.animals:
			if a.id == selected.id: details = "%s Lv%d   HP %d/%d\n現在：%s" % ["柴犬" if a.species == "shiba" else "鶏", a.lv, a.hp, a.max_hp, (TOOLS.get(a.mode, a.mode) if a.mode != "auto" else "おまかせ") if a.placed else "未配置"]
		if selected_animals.size() > 1: details = "%d匹を選択\n%s → クリックで一括指示" % [selected_animals.size(), TOOLS.get(tool, "Tabで操作選択")]
	elif selected.get("kind") == "enemy":
		for e in world.enemies:
			if e.id == selected.id: details = "誘拐者 Lv%d   HP %d/%d\n目的：%s" % [e.lv, e.hp, e.max_hp, e.state]
	elif selected.get("kind") == "structure" and world.structures.has(selected.pos):
		var b = world.structures[selected.pos]
		var quote = world.repair_quote(selected.pos)
		details = "%s Lv1   耐久 %d/%d\n[E] 修理 / [Del] 解体 → 土%d" % [{"wall": "壁", "gate": "門", "kennel": "犬小屋"}.get(b.kind, b.kind), b.hp, b.max_hp, world.dismantle_quote(selected.pos)]
		if selected_structures.size() > 1:
			var refund = 0
			for cell in selected_structures: refund += world.dismantle_quote(cell)
			details = "%d施設を選択\n[Del] 一括解体 → 土%d" % [selected_structures.size(), refund]
	if details != "":
		panel(Rect2(16, 610, 422, 76))
		var lines = details.split("\n")
		for i in range(lines.size()): label_on(hud, Vector2(30, 638 + i * 25), lines[i], 16)
	var cell = Vector2i(get_canvas_transform().affine_inverse() * pointer / TILE)
	if tool == "collect" and world.natural.has(cell) and not pointer_over_ui():
		var p = pointer.clamp(Vector2(8, 120), Vector2(950, 628)) + Vector2(15, -45)
		panel(Rect2(p, Vector2(270, 34)))
		label_on(hud, p + Vector2(10, 24), "雑草：回収で +1 Gold" if world.natural[cell] == "weed" else "キノコ：終了時に HP +5", 16)
	if tool == "repair" and world.structures.has(cell) and not pointer_over_ui():
		var b = world.structures[cell]
		var quote = world.repair_quote(cell)
		var p = pointer.clamp(Vector2(8, 120), Vector2(950, 628)) + Vector2(15, -55)
		panel(Rect2(p, Vector2(266, 56)))
		label_on(hud, p + Vector2(10, 22), "%s %d/%d → 修理 +%d" % [{"wall": "壁", "gate": "門", "kennel": "犬小屋"}.get(b.kind, b.kind), b.hp, b.max_hp, quote.hp], 16)
		label_on(hud, p + Vector2(10, 45), "土 %d%s" % [quote.cost, " / 停止中は不可" if world.paused else ""], 16)
	if world.phase == "result":
		panel(Rect2(362, 225, 554, 340))
		label_on(hud, Vector2(398, 271), "守りきった！" if world.result == "win" else "主人公が連れ去られた", 27)
		label_on(hud, Vector2(398, 311), "評価 %d   EXP +%d   GOLD +%d" % [world.score.rating, world.score.xp, world.score.gold], 18)
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
