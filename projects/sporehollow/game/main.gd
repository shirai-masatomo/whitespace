extends Node2D
const Farm = preload("res://game/world.gd")
const FONT = preload("res://assets/fonts/ui_font.tres")
const TILE = Vector2(48, 42)
const GROUPS = ["建設", "動物", "回収"]
const TOOLS = {"wall": "壁  10 / 1秒", "build_gate": "門  30（仮）", "repair": "修理", "gate": "門開閉", "remove": "撤去",
	"auto": "おまかせ", "stay": "待機", "wander": "徘徊", "collect": "草・キノコ・卵", "feed": "餌を置く"}
const GROUP_TOOLS = [["wall", "build_gate"], ["auto", "stay", "wander"], ["collect", "feed"]]
const BoardArt = preload("res://game/board_art.gd")
var world = Farm.new({}, randi_range(1, 2147483646))
var tool = "place_keeper"
var group = -1
var selected_animal = -1
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
var audio: AudioStreamPlayer

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
	audio = AudioStreamPlayer.new()
	add_child(audio)
	refresh()
	if "--automated" in OS.get_cmdline_user_args(): automated = true
	if automated: get_window().unfocusable = true
	if "--smoke" in OS.get_cmdline_user_args(): get_tree().create_timer(2).timeout.connect(get_tree().quit)

func add_button(parent: Control, id: String, text_value: String, area: Rect2, callback: Callable):
	var button = Button.new()
	button.text = text_value
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
	tool = "place_animal" if index == 1 and selected_animal >= 0 and world.animals.any(func(a): return a.id == selected_animal and not a.placed) else ""
	refresh()

func select_tool(id: String):
	tool = id
	if id in ["auto", "wander"] and selected_animal >= 0:
		world.act(id, Vector2i.ZERO, selected_animal)
		notice(TOOLS[id] + "を予約")
	refresh()

func choose_animal(id: int):
	selected_animal = id
	selected = {"kind": "animal", "id": id}
	tool = "place_animal" if world.animals.any(func(a): return a.id == id and not a.placed) else ""
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
			add_button(palette, "animal%d" % a.id, "%s Lv%d%s" % ["柴犬" if a.species == "shiba" else "鶏", a.lv, " 出撃済" if a.placed else " 未配置"], Rect2(16 + i * 196, 704, 188, 36), choose_animal.bind(a.id))
		if world.animals.any(func(a): return a.id == selected_animal and a.placed):
			for i in range(GROUP_TOOLS[1].size()):
				var id = GROUP_TOOLS[1][i]
				add_button(palette, id, TOOLS[id], Rect2(220 + i * 126, 704, 118, 36), select_tool.bind(id))
	elif group >= 0 and world.phase == "defend":
		for i in range(GROUP_TOOLS[group].size()):
			var id = GROUP_TOOLS[group][i]
			add_button(palette, id, TOOLS[id], Rect2(16 + i * 190, 704, 182, 36), select_tool.bind(id))
			buttons[id].tooltip_text = {"wall": "壁：土10、建設1秒", "build_gate": "門：土30（仮）、建設1秒", "collect": "雑草：1 Gold / キノコ：終了時HP5回復 / 卵：回収"}.get(id, TOOLS[id])
			if id in ["wall", "build_gate"]: buttons[id].icon = BoardArt.icon("soil")
		if group == 0 and selected.get("kind") == "structure":
			add_button(palette, "repair", "E 修理", Rect2(414, 704, 116, 36), facility_action.bind("repair"))
			add_button(palette, "remove", "Del 撤去", Rect2(540, 704, 124, 36), facility_action.bind("remove"))
			if world.structures.get(selected.pos, {}).get("kind") == "gate":
				add_button(palette, "gate", "門を開閉", Rect2(674, 704, 124, 36), facility_action.bind("gate"))
	for id in TOOLS:
		if buttons.has(id): buttons[id].modulate = Color("ffe0a0") if tool == id else Color.WHITE
	last_phase = world.phase

func facility_action(action: String):
	if world.phase != "defend" or group != 0 or selected.get("kind") != "structure": return
	var ok = world.act(action, selected.pos)
	notice(TOOLS[action] + "しました" if ok else ("停止中は動物指示だけ" if world.paused else "耐久・土・施設の状態を確認してください"))
	if action == "remove" and ok: selected.clear()
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
	selected.clear()
	view_positions.clear()
	seen_milestones = 0
	seen_combat = 0
	seen_skills = 0
	hit_effects.clear()
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
			refresh()
			get_viewport().set_input_as_handled()
	if event is InputEventKey:
		if event.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D]: keys_down[event.physical_keycode] = event.pressed
		if not event.pressed or event.echo: return
		match event.physical_keycode:
			KEY_SPACE: toggle_pause()
			KEY_TAB: toggle_speed()
			KEY_HOME: recenter()
			KEY_F3: debug_view = not debug_view
			KEY_F8: export_record()
			KEY_ESCAPE:
				group = -1
				tool = "place_keeper" if world.phase == "prepare" else ""
				selected.clear()
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
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT): return
	if pointer_over_ui(): return
	var cell = Vector2i(get_canvas_transform().affine_inverse() * event.position / TILE)
	if world.phase == "prepare":
		if world.act("place", cell):
			selected_animal = world.animals[0].id
			select_group(1)
			notice("未配置の動物を選んで出撃。出撃は任意です")
		else: notice("ここには主人公を配置できません")
		return
	if world.phase != "defend": return
	if group == 0 and world.live_structure(cell):
		selected = {"kind": "structure", "pos": cell}
		refresh()
		return
	if tool != "":
		if tool == "attack_target":
			for e in world.enemies:
				if not e.done and not e.flee and event.position.distance_to(screen_cell(view_positions.get("e%d" % e.id, Vector2(e.pos)))) < 23:
					cell = e.pos
					break
		if not world.act(tool, cell, selected_animal if tool in Farm.ORDERS or tool == "place_animal" else -1):
			notice("停止中は動物指示だけ" if world.paused else "対象・土・占有状態を確認してください")
		elif tool == "place_animal":
			tool = ""
			notice("出撃しました。移動は指示で行います")
			refresh()
		elif tool in Farm.ORDERS: notice("指示を予約しました")
		elif tool == "repair": notice("修理しました")
	else:
		selected.clear()
		for a in world.animals:
			if a.placed and event.position.distance_to(screen_cell(view_positions.get("a%d" % a.id, Vector2(a.pos)))) < 23:
				select_group(1)
				choose_animal(a.id)
				return
		for e in world.enemies:
			if not e.done and event.position.distance_to(screen_cell(view_positions.get("e%d" % e.id, Vector2(e.pos)))) < 23:
				selected = {"kind": "enemy", "id": e.id}
				return
		if world.structures.has(cell): selected = {"kind": "structure", "pos": cell}

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT: keys_down.clear()

func _process(delta):
	clock += delta
	var direction = Vector2(int(keys_down.get(KEY_D, false)) - int(keys_down.get(KEY_A, false)), int(keys_down.get(KEY_S, false)) - int(keys_down.get(KEY_W, false)))
	camera.position += direction.normalized() * delta * 420
	var middle = Vector2(Farm.W, Farm.H) * TILE * 0.5
	camera.position = camera.position.clamp(middle - Vector2(500, 360), middle + Vector2(500, 360))
	if not world.paused and not automated and world.phase == "defend":
		accumulated += minf(delta, 0.1) * speed
		while accumulated >= Farm.DT:
			world.step()
			accumulated -= Farm.DT
	if last_phase != world.phase: refresh()
	for a in world.animals:
		if a.placed: smooth_actor("a%d" % a.id, a.pos, delta)
	for e in world.enemies: smooth_actor("e%d" % e.id, e.pos, delta)
	while seen_combat < world.combat_log.size():
		var hit = world.combat_log[seen_combat]
		seen_combat += 1
		if hit.source in ["animal", "enemy"]:
			hit_effects.append({"source": ("a" if hit.source == "animal" else "e") + str(hit.id), "target": ("e" if hit.source == "animal" else "a") + str(hit.target), "at": clock})
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
	# Short original two-note signal; Dummy audio is used by automated visual runs.
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples = PackedByteArray()
	samples.resize(6615 * 2)
	var frequency = 440.0 if kind in ["carried", "restrained", "animal_danger"] else 660.0
	for i in range(6615):
		var t = float(i) / 22050.0
		var envelope = minf(t * 70, 1) * maxf(0, 1 - t / 0.3)
		var value = int(sin(t * TAU * frequency * (1.25 if t > 0.14 else 1.0)) * 2800 * envelope)
		if kind == "bark":
			var pulse = fmod(t, 0.15) / 0.15
			value = int((sin(t * TAU * (180 - pulse * 90)) + 0.3 * sin(t * TAU * 971)) * 2300 * sin(pulse * PI) * envelope)
		samples.encode_s16(i * 2, value)
	stream.data = samples
	audio.stream = stream
	audio.play()

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
	if b.kind == "wall":
		draw_rect(Rect2(p - Vector2(20, 13), Vector2(40, 29)), Color("797257"))
		draw_rect(Rect2(p - Vector2(20, 13), Vector2(40, 6)), shade)
		draw_line(p - Vector2(20, -2), p + Vector2(20, 2), Color("545642"), 2)
	else:
		draw_rect(Rect2(p - Vector2(20, 13), Vector2(6, 30)), shade)
		draw_rect(Rect2(p + Vector2(14, -13), Vector2(6, 30)), shade)
		draw_line(p - Vector2(15, 8), p + (Vector2(-12, 15) if b.open else Vector2(15, 8)), shade, 5)
	if b.hp < b.max_hp:
		var crack = PackedVector2Array([p + Vector2(2, -12), p + Vector2(-5, -3), p + Vector2(2, 3)])
		if b.hp <= b.max_hp * 0.5:
			crack.append(p + Vector2(-8, 15))
			draw_rect(Rect2(p + Vector2(11, 8), Vector2(9, 8)), Color("4c6047"))
		draw_polyline(crack, Color("313d31"), 3)
		draw_rect(Rect2(p + Vector2(-18, 19), Vector2(36.0 * b.hp / b.max_hp, 3)), Color("ebc171"))

func _draw():
	BoardArt.draw_ground(self, world, TILE)
	for p in world.natural:
		BoardArt.draw_resource(self, center(p), world.natural[p])
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
			draw_arc(p, 28, 0, TAU, 24, Color("f5d575"), 3)
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
			draw_arc(p, 25, 0, TAU, 24, Color("f69773"), 3)
			draw_line(p + Vector2(-10, 8), p + Vector2(10, 8), Color("513f39"), 3)
		draw_set_transform(Vector2.ZERO)
	for a in world.animals:
		if not a.placed: continue
		var p = actor_pixel("a%d" % a.id, a.pos)
		draw_circle(p + Vector2(0, 13), 18, Color(0.1, 0.2, 0.13, 0.25))
		if a.species == "shiba": draw_dog(p)
		else: draw_hen(p)
		var in_combat = world.enemies.any(func(e): return not e.done and not e.flee and Farm.distance(a.pos, e.pos) <= 1)
		if a.hp <= a.max_hp * 0.5 or in_combat:
			var danger = a.hp <= a.max_hp * Farm.Rules.LOW_HP_FRACTION
			var color = Color("f38c73") if danger else Color("efcc7f")
			draw_rect(Rect2(p + Vector2(-20, 23), Vector2(40, 5)), Color("3e4534"))
			draw_rect(Rect2(p + Vector2(-20, 23), Vector2(40.0 * a.hp / a.max_hp, 5)), color)
			if danger:
				color.a = 0.65 + 0.25 * sin(clock * 4)
				draw_arc(p, 28, 0, TAU, 28, color, 3)
				label_on(self, p + Vector2(-4, -29), "!", 23, color)
		if a.rescuing: draw_arc(p, 25, -PI, 0, 16, Color("b0f0de"), 3)
		if world.tick - a.last_bark < 4:
			var ripple = float(world.tick - a.last_bark) / 4.0
			for ring in range(3):
				draw_arc(p, 28 + ring * 17 + ripple * 35, -PI, PI, 40, Color(1, 0.89, 0.55, 0.7 - ring * 0.16), 2)
			label_on(self, p + Vector2(-13, -35), "ワン！", 16, Color("ffe3a0"))
		if a.state == "吠える":
			draw_arc(p + Vector2(25, -8), 9, -0.8, 0.8, 8, Color("ffe3a0"), 2)
			draw_arc(p + Vector2(25, -8), 15, -0.8, 0.8, 8, Color("ffe3a0"), 2)
		elif a.state == "様子見": label_on(self, p + Vector2(17, -24), "…", 18, Color("ffe3a0"))
		if selected.get("kind") == "animal" and selected.get("id") == a.id:
			draw_arc(p, 23, 0, TAU, 24, Color("ffe2a3"), 2)
			if a.mode in ["stay", "wander"]: draw_arc(center(a.order), 36 if a.mode == "stay" else 120, 0, TAU, 40, Color(1, 0.9, 0.5, 0.35), 2)
		if debug_view: label_on(self, p + Vector2(25, 0), a.state, 12)
	for hit in hit_effects:
		var p = center(view_positions.get(hit.target, Vector2.ZERO))
		var fade = 1.0 - (clock - hit.at) / 0.3
		draw_arc(p, 17, -0.8, 1.1, 8, Color(1, 0.85, 0.45, fade), 3)
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
	if selected.get("kind") == "structure":
		draw_rect(Rect2(Vector2(selected.pos) * TILE + Vector2(1, 1), TILE - Vector2(2, 2)), Color("ffe2a3"), false, 3)

func panel(area: Rect2): hud.draw_rect(area, Color(0.09, 0.16, 0.12, 0.94))

func draw_hud():
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
	BoardArt.draw_resource(hud, Vector2(352, 24), "mushroom")
	label_on(hud, Vector2(372, 31), str(world.campaign.mushrooms), 20)
	if Rect2(142, 0, 272, 49).has_point(pointer):
		panel(Rect2(145, 50, 390, 30))
		label_on(hud, Vector2(154, 71), "土：建築・修理 / Gold：購入 / キノコ：終了時回復", 14)
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
	if selected.get("kind") == "animal":
		for a in world.animals:
			if a.id == selected.id: details = "%s Lv%d   HP %d/%d   忠誠 %d\n指示：%s / %s" % ["柴犬" if a.species == "shiba" else "鶏", a.lv, a.hp, a.max_hp, a.loyalty, TOOLS.get(a.mode, a.mode), a.state if a.placed else "未配置"]
	elif selected.get("kind") == "enemy":
		for e in world.enemies:
			if e.id == selected.id: details = "誘拐者 Lv%d   HP %d/%d\n目的：%s" % [e.lv, e.hp, e.max_hp, e.state]
	elif selected.get("kind") == "structure" and world.structures.has(selected.pos):
		var b = world.structures[selected.pos]
		var quote = world.repair_quote(selected.pos)
		details = "%s Lv1   耐久 %d/%d\nE 修理 +%d（土%d） / Del 撤去" % ["壁" if b.kind == "wall" else "門", b.hp, b.max_hp, quote.hp, quote.cost]
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
		label_on(hud, p + Vector2(10, 22), "%s %d/%d → 修理 +%d" % ["壁" if b.kind == "wall" else "門", b.hp, b.max_hp, quote.hp], 16)
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

func draw_dog(p: Vector2):
	# Original small pixel silhouette: curled tail, cream muzzle and pointed ears.
	rect(p + Vector2(-14, -7), Vector2(26, 19), "bd713c")
	rect(p + Vector2(2, -13), Vector2(19, 18), "d9924f")
	rect(p + Vector2(3, -20), Vector2(5, 9), "9c5630")
	rect(p + Vector2(16, -20), Vector2(5, 9), "9c5630")
	rect(p + Vector2(9, -2), Vector2(14, 8), "f4deb0")
	rect(p + Vector2(18, -6), Vector2(3, 3), "293d37")
	rect(p + Vector2(-12, 10), Vector2(6, 7), "e5b27c")
	rect(p + Vector2(6, 10), Vector2(6, 7), "e5b27c")
	draw_arc(p + Vector2(-15, -8), 8, 0.1, 5.4, 9, Color(Color("f2d3a4"), art_alpha), 5)

func draw_hen(p: Vector2):
	draw_circle(p, 12, Color(Color("f4ebcf"), art_alpha))
	rect(p + Vector2(3, -13), Vector2(12, 14), "fff4d8")
	rect(p + Vector2(5, -18), Vector2(8, 5), "c45d4d")
	rect(p + Vector2(15, -7), Vector2(5, 4), "edb65a")
	rect(p + Vector2(11, -10), Vector2(2, 2), "243d36")
	rect(p + Vector2(-6, 11), Vector2(3, 6), "d69a4e")
	rect(p + Vector2(4, 11), Vector2(3, 6), "d69a4e")
