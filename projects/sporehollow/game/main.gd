extends Node2D
const Farm = preload("res://game/world.gd")
const FONT = preload("res://assets/fonts/ui_font.tres")
const TILE = Vector2(48, 42)
const GROUPS = ["建設", "指示"]
const TOOLS = {"wall": "壁  10 / 1秒", "wood_wall":"木壁 木10", "stone_wall":"石壁 石10", "soil_tile":"土タイル 土2", "wood_tile":"木タイル 木2", "stone_tile":"石タイル 石2", "door":"ドア 木10", "locked_door":"施錠ドア 木20", "guide":"連れていく", "repair": "修理", "gate": "ドア開閉", "remove": "解体", "kennel": "犬小屋 木20", "coop": "鶏小屋 木30",
	"auto": "おまかせ", "stay": "待機", "wander": "徘徊", "rest": "休む", "collect": "資源・卵・設計図", "dog_food": "犬用餌 HP+10", "hen_food": "鶏用餌 HP+8", "cat_food": "猫用餌 HP+8"}
const GROUP_TOOLS = [["wall", "wood_wall", "stone_wall", "soil_tile", "wood_tile", "stone_tile", "door", "locked_door"], ["guide", "auto", "stay", "wander", "rest"], ["collect"]]
const BoardArt = preload("res://game/board_art.gd")
const UI = preload("res://game/ui_style.gd")
const MARKET_CATEGORIES = {"animals": ["動物", "animals", "牧場の仲間"], "materials": ["資材", "wood", "土・木・石"], "facilities": ["施設", "hammer", "牧場づくり"], "items": ["小物と恵み", "basket", "卵・羽・道具"]}
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
var selection_layer = "structure"
var selection_ids: Dictionary = {}
var menu_open = false
var menu_was_paused = false
var menu: Control
var shop_side = "home"
var shop_category = "animals"
var shop_notice = ""
var shop_level = "categories"
var product_row: Dictionary = {}
var dragging = false
var press_pending = false
var press_position = Vector2.ZERO
const SELECTION_LIMIT = 8
var drag_class = ""
var drag_encounters: Array = []
var context_panel: Panel
var ui_pointer_capture = false
var context_signature = ""
var selected_resources: Array = []
var route_signature = ""
var route_legs: Array = []
var mode_cursor = ""
var queue_settle: Dictionary = {}
var queue_drag_id = -1
var queue_drag_start = Vector2.ZERO
var queue_drop_index = -1
var hover_job = -1
var morning_screen = "morning"
var book_motion = ""
var book_direction = 1
var book_started = -10.0
var book_next_id = -1
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
var actor_tracks: Dictionary = {}
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
	buttons.speed.tooltip_text = "− / ＋：0.5 → 1 → 2倍（休息中は4倍）。Space：停止"
	add_button(controls, "advance", "買い物を終える", Rect2(1074, 754, 190, 36), advance)
	add_button(controls, "retry", "再挑戦", Rect2(556, 514, 168, 38), retry_stage)
	for i in range(GROUPS.size()):
		add_button(controls, "group%d" % i, GROUPS[i], Rect2(16 + i * 122, 754, 116, 36), select_group.bind(i))
	audio = preload("res://game/farm_audio.gd").new()
	add_child(audio)
	queue_controls = Control.new()
	queue_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.add_child(queue_controls)
	add_button(controls, "walk", "牧場主", Rect2(270, 754, 110, 36), choose_walk)
	buttons.walk.tooltip_text = "ホイール：解除 → 建設 → 指示 → 牧場主。Ctrl+ホイール：ズーム"
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
	selected_resources.clear()
	selected.clear()
	selected_structures.clear()
	tool = ""
	selected_animal = -1
	selected_animals.clear()
	refresh()

func select_tool(id: String, execute: bool = true):
	tool = id
	if execute and id in ["auto", "stay", "wander", "rest"]: command_selected(id, Vector2i.ZERO)
	refresh()

func command_selected(id: String, cell: Vector2i):
	world.queue_order(id,selected_animals,cell)
	notice(world.events.back().text)

func cycle_subtool(reverse: bool = false):
	if not world.working(): return
	if group != 0:
		choose_walk()
		return
	var choices = GROUP_TOOLS[0].filter(func(id): return Farm.BUILD[id].get("blueprint", "") in ([""] + world.campaign.unlocked_blueprints))
	var index = choices.find(tool)
	var next = (choices.size() - 1 if reverse else 0) if index < 0 else posmod(index + (-1 if reverse else 1), choices.size())
	select_tool(choices[next], false)

func choose_animal(id: int, toggle: bool = false):
	selected_resources.clear()
	if world.animals.any(func(a): return a.id == id and not a.placed and not world.available(a)): return
	var reserve = world.animals.any(func(a): return a.id == id and not a.placed)
	if toggle and not reserve:
		selected_animals = selected_animals.filter(func(other): return world.animals.any(func(a): return a.id == other and a.placed))
		if id in selected_animals: selected_animals.erase(id)
		else: toggle_selection(selected_animals, id)
	else: selected_animals = [id]
	group = 1
	selected_animal = selected_animals[0] if not selected_animals.is_empty() else -1
	selected = {"kind": "animal", "id": selected_animal} if selected_animal >= 0 else {}
	tool = ""
	if not reserve: react(id, "hello", 1.0)
	refresh()

func collectible(cell: Vector2i) -> bool:
	return world.natural.has(cell) or not world.items_at(cell).is_empty()

func toggle_selection(targets: Array, id):
	if id in targets: targets.erase(id)
	elif targets.size() < SELECTION_LIMIT: targets.append(id)
	else: notice("選択 8/8")

func job_reserved(kind: String, cell: Vector2i) -> bool:
	return world.jobs.any(func(j): return j.kind == kind and j.pos == cell)

func select_resource(cell: Vector2i, toggle: bool = false):
	selected.clear()
	selected_animals.clear()
	selected_structures.clear()
	group = -1
	tool = ""
	if toggle:
		toggle_selection(selected_resources, cell)
	else:
		selected_resources = [cell]
		if world.act("collect", cell): notice("回収を頼んだよ")
		else: notice("予約済み" if job_reserved("collect", cell) else "予定は8件まで")
	refresh()

func collect_selected():
	selected_resources.sort_custom(func(a, b):
		var da = Farm.distance(world.keeper.pos, a)
		var db = Farm.distance(world.keeper.pos, b)
		return da < db if da != db else (a.y * Farm.W + a.x < b.y * Farm.W + b.x))
	var count = 0
	for cell in selected_resources.duplicate():
		if job_reserved("collect", cell):
			selected_resources.erase(cell)
			continue
		if world.act("collect", cell):
			count += 1
			selected_resources.erase(cell)
	notice("%d件予約・%d件未登録" % [count, selected_resources.size()])
	refresh()

func refresh():
	context_panel = null
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
	UI.selected(buttons.walk, selected.get("kind")=="keeper")
	buttons.pause.visible = world.working()
	buttons.speed.visible = world.working()
	buttons.home.visible = world.working()
	buttons.pause.text = "再開" if world.paused else "停止"
	buttons.pause.icon = UI.icon("next" if world.paused else "pause")
	buttons.speed.text = "早送り" if not world.rest_skip.is_empty() else "×%s" % speed
	buttons.speed.disabled = not world.rest_skip.is_empty()
	buttons.advance.visible = (world.phase == "shop" and morning_screen == "morning") or world.phase=="day" or (world.phase=="defend" and world.early_clear)
	buttons.advance.text = "支度を終える" if world.phase == "shop" else rest_button_text()
	buttons.advance.position = Vector2(548,674) if world.phase=="shop" else Vector2(1074,754)
	buttons.advance.tooltip_text = "商人を見送って、牧場の仕事へ" if world.phase == "shop" else ""
	buttons.retry.visible = world.phase == "result"
	buttons.group1.text = "指示"
	for i in range(2):
		buttons["group%d" % i].visible = world.working()
		UI.selected(buttons["group%d" % i], i == group)
	if world.phase == "dawn":
		last_phase = world.phase
		return
	if world.phase == "shop":
		build_shop()
	elif not selected_resources.is_empty():
		pass
	elif selected.get("kind") == "keeper" and world.working():
		add_button(palette, "keeper_rest", "起きる" if world.keeper.resting else "休息", Rect2(16, 704, 125, 36), keeper_action.bind("keeper_rest"))
		buttons.keeper_rest.icon = UI.icon("moon")
		buttons.keeper_rest.disabled = world.keeper.forced_rest or world.keeper.state != "free"
		add_button(palette, "resume_jobs", "作業再開", Rect2(150, 704, 145, 36), keeper_action.bind("resume_jobs"))
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
		var choices=GROUP_TOOLS[1].filter(func(order):return deployed_selection.any(func(a):return order in Farm.SPECIES[a.species].orders))
		for i in range(choices.size()):
			var id=choices[i]
			add_button(palette,id,TOOLS[id],Rect2(16+i*126,704,118,36),select_tool.bind(id))
	elif group == 0 and world.working():
		var choices = GROUP_TOOLS[group].filter(func(id): return id != "kennel" or "kennel" in world.campaign.unlocked_blueprints)
		for i in range(choices.size()):
			var id = choices[i]
			add_button(palette, id, TOOLS[id], Rect2(16 + (i%6)*164, 685+(i/6)*40, 156, 36), select_tool.bind(id))
			buttons[id].tooltip_text = {"wall": "壁：土10、建設1秒", "collect": "雑草：1 Gold / キノコ：終了時HP5回復 / 卵：回収"}.get(id, TOOLS[id])
			if Farm.Shop.FOOD.has(id):
				buttons[id].text += " ×%d" % world.item_count(id)
			if id in ["wall", "wood_wall", "stone_wall", "soil_tile", "wood_tile", "stone_tile", "door", "locked_door", "kennel", "coop"]:
				buttons[id].icon = BoardArt.icon("wood" if id in ["kennel", "coop"] else "soil")
	for id in TOOLS:
		if buttons.has(id): UI.selected(buttons[id], tool == id)
	build_context_actions()
	if debug_view: build_debug_controls()
	last_phase = world.phase

func selected_store() -> Dictionary:
	return world.building_store(selection_layer)

func select_building(cell: Vector2i, layer_name: String, toggle: bool=false):
	if not toggle or selection_layer!=layer_name: selected_structures.clear(); selection_ids.clear()
	selection_layer=layer_name
	selected_resources.clear(); selected_animals.clear()
	if cell in selected_structures: selected_structures.erase(cell); selection_ids.erase(cell)
	else:
		toggle_selection(selected_structures,cell)
		if cell in selected_structures: selection_ids[cell]=[selected_store()[cell].id,selected_store()[cell].kind]
	selected={"kind":layer_name,"pos":selected_structures[0],"target_id":selection_ids[selected_structures[0]][0]} if not selected_structures.is_empty() else {}
	group=0; tool=""; refresh()

func switch_layer():
	if not selected.has("pos"): return
	select_building(selected.pos,"floor" if selection_layer=="structure" else "structure")

func facility_action(action: String):
	if not world.working() or selected.get("kind") not in ["structure","floor"]: return
	prune_selection()
	var count=0
	var targets=selected_structures.duplicate()
	var kind=action+"_floor" if selection_layer=="floor" and action in ["remove","repair"] else action
	for cell in targets:
		if action=="repair" and world.repair_quote(cell,selection_layer).hp<=0: continue
		if world.act(kind,cell): count+=1
	notice("%d件予約・%d件未登録" % [count,targets.size()-count])
	refresh()

func context_targets() -> Array:
	if selected.get("kind") == "job": return [selected.pos]
	if not selected_resources.is_empty(): return selected_resources
	if selected.get("kind") in ["structure","floor"]: return selected_structures
	return []

func context_state() -> String:
	return str(selected_resources) + str(selected) + str(selected_structures) + str(selected_structures.map(func(p): return selected_store().get(p,{}))) + str(world.jobs.map(func(j): return [j.kind, j.pos])) + str(world.materials) + str(world.wood)

func build_context_actions():
	context_signature = context_state()
	if not world.working() or context_targets().is_empty(): return
	context_panel = Panel.new()
	context_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	context_panel.add_theme_stylebox_override("panel", UI.surface(UI.PAPER))
	palette.add_child(context_panel)
	var rows = []
	if selected.get("kind") == "job":
		rows.append(["cancel_near", "取消", "cross", cancel_work.bind(selected.id), false, "この予定だけを取り消す"])
	elif not selected_resources.is_empty():
		var pending = selected_resources.any(func(p): return not job_reserved("collect", p))
		rows.append(["collect_selection", "回収する" if pending else "予約済み", "basket", collect_selected, not pending, "牧場主が現地で回収する"])
		if selected_resources.any(func(p):return job_reserved("collect",p)):
			rows.append(["cancel_near","取消","cross",cancel_selected_work,false,"選んだ回収予定を取り消す"])
	else:
		var damaged = selected_structures.filter(func(p): return selected_store().get(p,{}).get("status")=="ready" and selected_store()[p].status == "ready" and (selected_store()[p].hp < selected_store()[p].max_hp or selected_store()[p].get("lock_hp",0)<selected_store()[p].get("max_lock_hp",0)))
		if not damaged.is_empty():
			var can_repair = damaged.any(func(p): return not job_reserved("repair_floor" if selection_layer=="floor" else "repair", p) and world.repair_quote(p,selection_layer).hp > 0)
			var costs = {"soil":0,"wood":0,"stone":0}
			for p in damaged: costs[selected_store()[p].get("resource","soil")] += world.repair_quote(p,selection_layer).cost
			rows.append(["repair", "修理", "hammer", facility_action.bind("repair"), not can_repair, "E · " + resource_text(costs)])
		var returns = {"soil":0,"wood":0,"stone":0}
		for p in selected_structures: returns[selected_store()[p].get("resource","soil")] += world.dismantle_quote(p,selection_layer)
		rows.append(["remove", "タイルを解体" if selection_layer=="floor" else "解体", "cross", facility_action.bind("remove"), (selection_layer=="floor" and selected_structures.all(func(p):return world.live_structure(p))) or selected_structures.all(func(p):return job_reserved("remove_floor" if selection_layer=="floor" else "remove",p)), "先に上の建物を解体してください" if selection_layer=="floor" and selected_structures.any(func(p):return world.live_structure(p)) else "返却 " + resource_text(returns)])
		if selected_structures.size() == 1 and selected_store()[selected_structures[0]].kind in Farm.Buildings.DOORS:
			rows.append(["gate", "開閉", "next", facility_action.bind("gate"), job_reserved("gate",selected_structures[0]), "牧場主が現地で開閉する"])
		if selected_structures.size()==1 and world.live_structure(selected.pos) and world.floors.get(selected.pos,{}).get("status")=="ready":
			rows.append(["switch_layer","床を見る" if selection_layer=="structure" else "建物を見る","next",switch_layer,false,"同じマスの別の層を選択"])
	var count = context_targets().size()
	context_panel.size = Vector2(rows.size() * 112 + 12, 68)
	var title = Label.new()
	title.text = "選択 %d/8" % count if count > 1 else ("落とし物" if not selected_resources.is_empty() else ("床" if selection_layer=="floor" else "建物"))
	title.position = Vector2(9,3)
	title.add_theme_color_override("font_color",UI.INK)
	context_panel.add_child(title)
	for i in range(rows.size()):
		var row = rows[i]
		add_button(context_panel,row[0],row[1],Rect2(6+i*112,27,106,34),row[3])
		buttons[row[0]].icon = UI.icon(row[2])
		buttons[row[0]].disabled = row[4]
		buttons[row[0]].tooltip_text = row[5]
	position_context_actions()

func position_context_actions():
	if not is_instance_valid(context_panel) or context_targets().is_empty(): return
	var anchor = screen_cell(context_targets()[0])
	var size_value = context_panel.size
	var p = anchor + Vector2(28,-size_value.y-15)
	if p.x + size_value.x > 1268: p.x = anchor.x-size_value.x-28
	p = p.clamp(Vector2(12,55),Vector2(1268-size_value.x,690-size_value.y))
	var queue_area = Rect2(1006,60,256,34+world.jobs.size()*35)
	if not world.jobs.is_empty() and Rect2(p,size_value).intersects(queue_area): p.x = minf(p.x,queue_area.position.x-size_value.x-8)
	context_panel.position = p

func prune_selection():
	if selected.get("kind")=="job" and not world.jobs.any(func(j):return j.id==selected.id):
		selected.clear()
		refresh()
	var resources = selected_resources.filter(func(p):return collectible(p))
	var structures = selected_structures.filter(func(p):return selected_store().get(p,{}).get("status") in ["ready","building"] and selection_ids.get(p)==[selected_store()[p].id,selected_store()[p].kind])
	var changed = resources != selected_resources or structures != selected_structures
	selected_resources = resources
	selected_structures = structures
	if selected.get("kind") in ["structure","floor"]:
		selected = {"kind":selection_layer,"pos":structures[0],"target_id":selection_ids[structures[0]][0]} if not structures.is_empty() else {}
	if changed: refresh()

func advance():
	if cinematic() or menu_open: return
	if world.phase == "shop":
		world = world.begin_day()
		reset_view()
		group = -1
		departure_started = clock
	elif world.phase == "dawn":
		morning_keeper = Vector2(world.keeper.pos)
		for a in world.animals:
			if a.species == "shiba" and a.placed: morning_dog = Vector2(a.pos)
		world = Farm.new(world.next_campaign(), world.seed_value + 1)
		reset_view()
		arrival_started = clock
	elif world.working():
		if not world.rest_skip.is_empty():
			world.act("cancel_rest_until")
			speed=1
			accumulated=0
		elif not world.act("rest_until_night" if world.phase=="day" else "end_night"):
			notice(world.Life.rest_until_reason(world,"night" if world.phase=="day" else "dawn"))
	refresh()

func cancel_selected_work():
	for j in world.jobs.duplicate():
		if j.kind=="collect" and j.pos in selected_resources: world.act("cancel_job",Vector2i.ZERO,j.id)
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
	morning_screen = "morning"
	book_motion = ""
	selected_resources.clear()
	press_pending = false
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
	actor_tracks.clear()
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
	selected_resources.clear()
	selected_structures.clear()
	group = 2
	tool = ""
	selected = {"kind": "keeper"}
	selected_animals.clear()
	refresh()

func neutral():
	group = -1
	tool = ""
	selected.clear()
	selected_animals.clear()
	selected_structures.clear()
	selected_resources.clear()
	selected_animal = -1
	press_pending = false
	dragging = false
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
	var signature = str(world.jobs) + str(world.keeper.state) + str(world.paused) + world.job_hold_reason + str(world.manual_goal) + str(world.keeper.resting)
	if signature == queue_signature or queue_drag_id >= 0: return
	queue_signature = signature
	for child in queue_controls.get_children():
		queue_controls.remove_child(child)
		child.queue_free()
	if world.jobs.is_empty(): return
	var title = Label.new()
	title.position = Vector2(1020, 64)
	title.text = "予定 %d" % world.jobs.size()
	if world.Jobs.status(world)!="": title.text += " · " + world.Jobs.status(world)
	title.size.x = 238
	title.clip_text = true
	title.tooltip_text = title.text
	title.add_theme_font_size_override("font_size",14)
	queue_controls.add_child(title)
	for i in range(world.jobs.size()):
		var j = world.jobs[i]
		var row = Button.new()
		row.position = Vector2(1010, queue_settle.get(j.id,94 + i * 35))
		row.size = Vector2(214, 31)
		row.focus_mode = Control.FOCUS_NONE
		UI.button(row, Color("c6d1ac") if i == 0 else UI.PAPER)
		var names = {"wall": "壁", "door":"ドア","locked_door":"施錠ドア","wood_wall":"木壁","stone_wall":"石壁","soil_tile":"土タイル","wood_tile":"木タイル","stone_tile":"石タイル", "kennel": "犬小屋", "coop": "鶏小屋", "move": "歩く", "collect": "回収", "repair": "修理", "remove": "解体", "remove_floor":"タイル解体", "repair_floor":"床修理", "gate": "ドアを開閉", "animal_order": "仲間へ指示"}
		row.text = "%s%s" % [ "› " if j.state != "pending" else "", ("待機 · " if j.state == "blocked" else "") + names.get(j.kind, "仕事")]
		row.draw.connect(draw_queue_badge.bind(row,i+1))
		row.set_meta("job_id",j.id)
		row.set_meta("row_index",i)
		row.tooltip_text = "%d番目 · %s" % [i + 1, "保留" if world.jobs_held else {"pending":"これから", "walking":"向かっている", "working":"作業中", "blocked":j.get("block_reason","通行待ち")+"・順番変更/取消可"}.get(j.state,"仕事")]
		row.tooltip_text += " · ×で取消"
		row.gui_input.connect(queue_input.bind(j.id))
		row.mouse_entered.connect(func(): hover_job = j.id)
		row.mouse_exited.connect(func(): hover_job = -1)
		queue_controls.add_child(row)
		var cancel = Button.new()
		cancel.position = Vector2(1228, 94 + i * 35)
		cancel.size = Vector2(30, 31)
		cancel.focus_mode = Control.FOCUS_NONE
		cancel.icon = UI.icon("cross")
		cancel.tooltip_text = "この予定を取り消す"
		UI.button(cancel)
		cancel.pressed.connect(cancel_work.bind(j.id))
		queue_controls.add_child(cancel)
	queue_settle.clear()
	if world.jobs_held and not world.keeper.resting and world.keeper.state=="free":
		var resume=Button.new()
		resume.position=Vector2(1010,98+world.jobs.size()*35)
		resume.size=Vector2(248,28)
		resume.text="▶ 作業再開"
		resume.focus_mode=Control.FOCUS_NONE
		UI.button(resume,Color("c6d1ac"))
		resume.pressed.connect(keeper_action.bind("resume_jobs"))
		queue_controls.add_child(resume)

func draw_work_plans():
	if not world.working(): return
	var signature = str(world.keeper.pos)+str(world.manual_goal)+str(world.jobs.map(func(j):return [j.id,j.pos,j.get("targets",[])]))+str(world.structures)+str(world.animals.map(func(a):return a.pos))+str(world.floors)
	if signature != route_signature:
		route_signature=signature
		route_legs=world.Jobs.preview(world)
	var show_route=selected.get("kind")=="keeper" or queue_drag_id>=0 or hover_job>=0
	if show_route:
		var segments={}
		for leg in route_legs:
			var held=world.jobs_held and leg.number>0
			for i in range(1,leg.path.size()):
				var a=leg.path[i-1];var b=leg.path[i]
				var key=str(a if str(a)<str(b) else b)+str(b if str(a)<str(b) else a)
				var count=int(segments.get(key,0))
				segments[key]=count+1
				if count>=2:continue
				var pa=center(a);var pb=center(b)
				var direction=(pb-pa).normalized()
				var offset=Vector2(-direction.y,direction.x)*3 if count>0 else Vector2.ZERO
				pa+=offset;pb+=offset
				var color=Color(0.85,0.30,0.27,0.30 if held else 0.58)
				if count>0 or held:draw_dashed_line(pa,pb,color,1.5,5)
				else:draw_line(pa,pb,color,1.5)
				if i%3==0:
					var side=Vector2(-direction.y,direction.x)
					var q=pa.lerp(pb,0.6)
					draw_polyline(PackedVector2Array([q-direction*5+side*3,q,q-direction*5-side*3]),color,1.5)
			if leg.get("blocked",false):
				var q=center(leg.path[-1])
				draw_line(q-Vector2(5,5),q+Vector2(5,5),UI.DANGER,3)
				draw_line(q+Vector2(-5,5),q+Vector2(5,-5),UI.DANGER,3)
	if world.manual_goal != null:
		var flag = center(world.manual_goal)
		draw_line(flag + Vector2(0, 10), flag + Vector2(0, -27), Color("e4cd9b"), 3)
		draw_colored_polygon(PackedVector2Array([flag+Vector2(1,-27), flag+Vector2(23,-20), flag+Vector2(1,-13)]), Color("91dabd"))
	for i in range(world.jobs.size()):
		var j = world.jobs[i]
		var q = center(j.pos)
		if j.id == hover_job: draw_rect(Rect2(q - Vector2(22,22),Vector2(44,44)), Color("ffe2a3"), false, 2)
		if j.kind=="animal_order" and j.order=="guide":
			for t in j.targets:
				if not t.done:
					var marker=center(t.dest)
					draw_line(marker-Vector2(12,0),marker+Vector2(12,0),Color("dcd5a5"),2)
					label_on(self,marker+Vector2(-5,-8),str(i+1),14,UI.PAPER)
		if Farm.BUILD.has(j.kind) and not j.started:
			draw_rect(Rect2(q - Vector2(19, 14), Vector2(38, 28)), Color(0.79, 0.76, 0.55, 0.35))
			for x in [-18, 18]:
				draw_line(q + Vector2(x, 11), q + Vector2(x, -12), Color("bdac7a"), 3)
		else: draw_line(q + Vector2(-9, 10), q + Vector2(9, 10), Color("cfdfaa"), 3)
		draw_line(q + Vector2(-10, -12), q + Vector2(-10, -27), Color("9b774e"), 3)
		draw_rect(Rect2(q + Vector2(-18, -33), Vector2(22, 18)), Color("d8c692"))
		label_on(self, q + Vector2(-13, -19), str(i + 1), 15, UI.INK)

func draw_animal_silhouette(p: Vector2, species: String, alpha: float, size_value: float = 1.0):
	draw_set_transform(p, 0, Vector2.ONE * size_value)
	art_alpha = alpha
	if species == "shiba": draw_dog(Vector2.ZERO)
	elif species == "cat": draw_cat(Vector2.ZERO)
	else: draw_hen(Vector2.ZERO)
	art_alpha = 1.0
	draw_set_transform(Vector2.ZERO)

func toggle_speed():
	var steps = [0.5, 1.0, 2.0, 4.0] if world.keeper.resting else [0.5, 1.0, 2.0]
	speed = steps[posmod(steps.find(speed) + 1, steps.size())]
	refresh()

func change_speed(direction: int):
	if not world.rest_skip.is_empty(): return
	var steps = [0.5, 1.0, 2.0, 4.0] if world.keeper.resting else [0.5, 1.0, 2.0]
	speed = steps[clampi(steps.find(speed) + direction, 0, steps.size() - 1)]
	refresh()

func center(p: Vector2) -> Vector2:
	return (p + Vector2.ONE * 0.5) * TILE

func screen_cell(p: Vector2) -> Vector2:
	return get_canvas_transform() * center(p)

func queue_input(event, id: int):
	if not event is InputEventMouseButton: return
	if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not world.jobs.is_empty() and world.jobs[0].id == id and world.jobs[0].state not in ["pending","blocked"]:
			notice("今の仕事は先頭。中断するなら×")
			return
		queue_drag_id = id
		queue_drag_start = pointer
	get_viewport().set_input_as_handled()

func job_at(cell: Vector2i) -> int:
	for j in world.jobs:
		if (j.pos) == cell and not j.started and not j.get("resume", false): return j.id
	return -1

func _input(event):
	if is_instance_valid(name_edit) and name_edit.has_focus(): return
	if cinematic() or book_motion != "":
		keys_down.clear()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		if world.phase == "shop" and morning_screen != "morning": close_morning_screen()
		else: toggle_menu()
		get_viewport().set_input_as_handled()
		return
	if menu_open: return
	if event is InputEventMouseMotion:
		pointer = event.position
		if queue_drag_id >= 0:
			queue_drop_index = clampi(int((pointer.y - 94) / 35), 1 if not world.jobs.is_empty() and world.jobs[0].state not in ["pending","blocked"] else 0, maxi(0,world.jobs.size() - 1))
			get_viewport().set_input_as_handled()
		elif press_pending:
			if pointer.distance_to(press_position) >= 7: dragging = true
			if dragging: update_drag_class()
		elif world.working() and not pointer_over_ui(): hover_job = job_at(Vector2i(get_canvas_transform().affine_inverse() * pointer / TILE))
	if event is InputEventMouseButton:
		pointer = event.position
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and pointer_over_ui():
			ui_pointer_capture = true
			press_pending = false
			dragging = false
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and ui_pointer_capture and queue_drag_id < 0:
			ui_pointer_capture = false
			press_pending = false
			dragging = false
			return
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			ui_pointer_capture = false
			if queue_drag_id >= 0:
				if pointer.distance_to(queue_drag_start) >= 7:
					for row in queue_controls.get_children():
						if row.has_meta("job_id"): queue_settle[row.get_meta("job_id")]=row.position.y
					if Rect2(990,84,278,world.jobs.size()*35+20).has_point(pointer):
						if world.Jobs.reorder(world, queue_drag_id, queue_drop_index): queue_settle[queue_drag_id]=82+queue_drop_index*35
				queue_drag_id = -1
				queue_drop_index = -1
				queue_signature = ""
				refresh_jobs()
				get_viewport().set_input_as_handled()
				return
			if press_pending:
				press_pending = false
				if dragging and not pointer_over_ui(): finish_drag()
				elif not pointer_over_ui(): board_click(event)
				dragging = false
				get_viewport().set_input_as_handled()
				return
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			if world.phase == "shop" or pointer_over_ui(): return
			if event.ctrl_pressed:
				camera.zoom = Vector2.ONE * clampf(camera.zoom.x * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), 0.65, 1.8)
			elif world.working():
				var next_mode = posmod(group + 1 + (1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1),4)-1
				if next_mode == 2: choose_walk()
				elif next_mode == -1: neutral()
				else: select_group(next_mode)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if queue_drag_id >= 0:
				queue_drag_id = -1
				queue_drop_index = -1
				queue_signature = ""
				ui_pointer_capture = false
				get_viewport().set_input_as_handled()
				return
			if pointer_over_ui() or world.phase == "shop": return
			neutral()
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
			KEY_F3: debug_view = not debug_view; world.debug_enabled=debug_view; refresh()
			KEY_F8: export_record()
			KEY_E: facility_action("repair")
			KEY_1, KEY_2:
				if world.working(): select_group(event.physical_keycode - KEY_1)
		if event.physical_keycode in [KEY_SPACE, KEY_TAB, KEY_HOME, KEY_F3, KEY_F8, KEY_ESCAPE, KEY_1, KEY_2, KEY_3, KEY_E]:
			get_viewport().set_input_as_handled()

func pointer_over_ui() -> bool:
	if is_instance_valid(context_panel) and context_panel.is_visible_in_tree() and context_panel.get_global_rect().has_point(pointer): return true
	if pointer.y < 49 or pointer.y > 748: return true
	if world.working() and Rect2(1010, 64, 248, 66 + world.jobs.size() * 35).has_point(pointer): return true
	if not selected.is_empty() and (keeper_card_rect() if selected.get("kind")=="keeper" else Rect2(16,595,422,91)).has_point(pointer): return true
	for button in buttons.values():
		if is_instance_valid(button) and button.is_visible_in_tree() and button.get_global_rect().has_point(pointer): return true
	return false

func selection_candidates() -> Array:
	var result = []
	for a in world.animals:
		if a.placed: result.append({"class": "animal", "id": a.id, "point": actor_pixel("a%d" % a.id, a.pos)})
	var cells = world.natural.keys()
	for item in world.field_items:
		if item.pos not in cells: cells.append(item.pos)
	for cell in cells: result.append({"class": "resource", "id": cell, "point": center(cell)})
	for cell in world.structures:
		if world.live_structure(cell) and selection_layer!="floor": result.append({"class":"structure","id":cell,"point":center(cell)})
	for cell in world.floors:
		if world.floors[cell].status=="ready" and (selection_layer=="floor" or not world.live_structure(cell)): result.append({"class":"floor","id":cell,"point":center(cell)})
	result.sort_custom(func(a,b):
		var da = drag_start.distance_squared_to(a.point)
		var db = drag_start.distance_squared_to(b.point)
		return da < db if da != db else str(a["class"]) + str(a.id) < str(b["class"]) + str(b.id))
	return result

func update_drag_class():
	var end = get_canvas_transform().affine_inverse() * pointer
	var area = Rect2(drag_start, end - drag_start).abs().grow(1)
	for candidate in selection_candidates():
		if not area.has_point(candidate.point): continue
		if drag_class == "": drag_class = candidate["class"]
		if candidate["class"] == drag_class:
			var key = [candidate["class"], candidate.id]
			if key not in drag_encounters: drag_encounters.append(key)

func finish_drag():
	update_drag_class()
	var area = Rect2(drag_start, get_canvas_transform().affine_inverse() * pointer - drag_start).abs().grow(1)
	var targets = selection_candidates().filter(func(c): return c["class"] == drag_class and area.has_point(c.point))
	targets.sort_custom(func(a,b):return drag_encounters.find([a["class"],a.id]) < drag_encounters.find([b["class"],b.id]))
	targets = targets.slice(0,SELECTION_LIMIT)
	selected.clear()
	selected_animals.clear()
	selected_resources.clear()
	selected_structures.clear()
	tool = ""
	if drag_class == "animal":
		group = 1
		selected_animals = targets.map(func(c): return c.id)
		selected_animal = selected_animals[0] if not selected_animals.is_empty() else -1
		if selected_animal >= 0: selected = {"kind": "animal", "id": selected_animal}
	elif drag_class == "resource":
		group = -1
		selected_resources = targets.map(func(c): return c.id)
	elif drag_class in ["structure","floor"]:
		selection_layer=drag_class
		group = 0
		selected_structures = targets.map(func(c): return c.id)
		selection_ids.clear()
		for p in selected_structures: selection_ids[p]=[selected_store()[p].id,selected_store()[p].kind]
		if not selected_structures.is_empty(): selected = {"kind":selection_layer,"pos":selected_structures[0],"target_id":selection_ids[selected_structures[0]][0]}
	refresh()

func _unhandled_input(event):
	if menu_open or cinematic() or not world.working(): return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or pointer_over_ui(): return
	if Farm.BUILD.has(tool):
		board_click(event)
		get_viewport().set_input_as_handled()
		return
	press_pending = true
	press_position = event.position
	drag_start = get_canvas_transform().affine_inverse() * pointer
	drag_class = ""
	drag_encounters.clear()
	for candidate in selection_candidates():
		if drag_start.distance_to(candidate.point) < 20:
			drag_class = candidate["class"]
			break

func board_click(event):
	var cell = Vector2i(get_canvas_transform().affine_inverse() * event.position / TILE)
	if Farm.BUILD.has(tool):
		if not world.act(tool,cell): notice("予定は8件まで" if world.jobs.size()>=8 else world.Buildings.reason(world,tool,cell))
		refresh(); return
	if not event.ctrl_pressed: selected_resources.clear()
	if world.keeper.placed and keeper_hit_rect().has_point(get_canvas_transform().affine_inverse()*event.position):
		choose_walk()
		if not keeper_hint_shown:
			keeper_hint_shown = true
			notice("地面を左クリックで移動")
		return
	var planned = job_at(cell)
	if planned >= 0:
		selected = {"kind":"job","id":planned,"pos":cell}
		selected_animals.clear()
		selected_structures.clear()
		tool = ""
		refresh()
		return
	# Context selection takes precedence over the previously armed tool, even while paused.
	if not world.items_at(cell).is_empty():
		select_resource(cell, event.ctrl_pressed)
		return
	for a in world.animals:
		if a.placed and animal_hit_rect(a).has_point(get_canvas_transform().affine_inverse()*event.position):
			if Farm.Shop.FOOD.has(tool):
				notice("餌で回復しました" if world.act(tool, a.pos, a.id) else "対象・在庫・HP・停止状態を確認")
				refresh()
			else: choose_animal(a.id, event.ctrl_pressed)
			return
	if Farm.BUILD.has(tool) and (world.live_structure(cell) or world.floors.has(cell)):
		if not world.act(tool,cell): notice(world.Buildings.reason(world,tool,cell))
		refresh(); return
	if world.live_structure(cell) or (world.floors.get(cell,{}).get("status")=="ready" and selected.get("kind")!="keeper" and tool!="guide"):
		var layer_name="floor" if world.floors.get(cell,{}).get("status")=="ready" and (selection_layer=="floor" or not world.live_structure(cell)) else "structure"
		select_building(cell,layer_name,event.ctrl_pressed)
		return
	if collectible(cell):
		select_resource(cell, event.ctrl_pressed)
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
	if selected.get("kind") == "keeper":
		if not world.act("keeper_move",cell): notice("移動できません")
	elif tool in Farm.ORDERS:
		command_selected(tool, cell)
	elif tool != "":
		if not world.act(tool, cell, -1):
			notice("予定は8件まで" if world.jobs.size() >= 8 else "ここは使えないか、資材が足りません")

	else:
		selected.clear()
	refresh()

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		keys_down.clear()
		dragging = false
		press_pending = false
		queue_drag_id = -1

func _process(delta):
	if book_motion != "":
		var duration = 0.3 if book_motion == "turn" else 0.4
		if clock - book_started >= duration:
			if book_motion == "turn": training_id = book_next_id
			elif book_motion == "close":
				morning_screen = "morning"
				shop_side = "home"
			book_motion = ""
			refresh()
	palette.visible = book_motion == ""

	if not menu_open: clock += delta
	if not world.paused and not menu_open and world.working(): visual_time += delta * (24.0 if not world.rest_skip.is_empty() else speed)
	var direction = Vector2(int(keys_down.get(KEY_D, false)) - int(keys_down.get(KEY_A, false)), int(keys_down.get(KEY_S, false)) - int(keys_down.get(KEY_W, false)))
	if not menu_open and not cinematic() and world.phase != "shop": camera.position += direction.normalized() * delta * 420
	var middle = Vector2(Farm.W, Farm.H) * TILE * 0.5
	camera.position = camera.position.clamp(middle - Vector2(500, 360), middle + Vector2(500, 360))
	if not world.paused and not automated and world.working():
		accumulated += minf(delta, 0.1) * (24.0 if not world.rest_skip.is_empty() else speed)
		while accumulated >= Farm.DT:
			var was_sending = not world.rest_skip.is_empty()
			world.step()
			record_actor_tracks()
			accumulated -= Farm.DT
			sync_danger()
			if was_sending and world.rest_skip.is_empty():
				speed=1
				accumulated=0
				refresh()
				break
	if last_phase != world.phase:
		refresh()
	sync_danger()
	if speed > 2 and not world.keeper.resting:
		speed = 1
		refresh()
	var vitals_signature = str(world.rest_skip) + str(world.keeper.state) + str(world.keeper.resting) + str(world.keeper.forced_rest)
	if selected.get("kind") == "keeper" and vitals_signature != keeper_ui_signature:
		keeper_ui_signature = vitals_signature
		refresh()
	prune_selection()
	if not ui_pointer_capture and not context_targets().is_empty() and context_signature != context_state(): refresh()
	position_context_actions()
	refresh_jobs()
	for row in queue_controls.get_children():
		var id=int(row.get_meta("job_id",-2))
		var lifting=queue_drag_id>=0 and pointer.distance_to(queue_drag_start)>=7
		row.modulate.a=0.15 if id==queue_drag_id and lifting else 1.0
		if row.has_meta("row_index"):
			var index=int(row.get_meta("row_index"))
			var target_y=94+index*35
			if lifting and id!=queue_drag_id and index>=queue_drop_index:target_y+=8
			row.position.y=move_toward(row.position.y,target_y,delta*1100)
	mode_cursor = "hammer" if group == 0 else ("whistle" if group == 1 else "move")
	if not world.working() or group < 0 or pointer_over_ui() or menu_open or cinematic() or queue_drag_id >= 0: mode_cursor = ""
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if mode_cursor == "" else Input.MOUSE_MODE_HIDDEN)
	smooth_actor("keeper", world.keeper.pos, delta)
	if world.phase == "dawn" and clock - transition_at > 4.8 and not menu_open: advance()
	if world.phase == "shop" and clock - arrival_started > 0.8 and not arrival_bell:
		arrival_bell = true
		audio.cue("merchant")
	controls.visible = not cinematic()
	if selected.get("kind") == "enemy" and world.enemies.any(func(e): return e.id == selected.id and (e.hp <= 0 or e.flee or e.done)):
		selected.clear()
		refresh()
	if world.working():
		buttons.advance.visible = world.phase=="day" or world.early_clear
		buttons.advance.text = rest_button_text()
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
		var names = {"whistle": "", "auto_start": "敵の襲来に備えよ", "invasion": "！ 侵入者接近", "keeper_down": "倒れた！ 仲間に助けてもらおう", "keeper_recovered": "目が覚めた。少し休もう", "restrained": "牧場主が拘束された！", "carried": "牧場主が連れ去られている！", "rescue": "牧場主を救出した！", "animal_danger": "動物のHPが危険！", "blueprint": event.get("text","設計図を手に入れた。"), "blueprint_dropped": "作り方のメモが落ちた", "early_clear": "今夜の襲撃を退けた", "dawn": "夜明け"}
		if event.kind == "order_notice": notice(event.text); continue
		if event.kind == "whistle":
			audio.cue("whistle"); continue
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

func record_actor_tracks():
	record_actor("keeper",world.keeper.pos)
	for a in world.animals:
		if a.placed: record_actor("a%d" % a.id,a.pos)
	for e in world.enemies: record_actor("e%d" % e.id,e.pos)

func record_actor(id: String, cell: Vector2i):
	if not actor_tracks.has(id): actor_tracks[id]=[]
	var track=actor_tracks[id]
	var previous=track[-1] if not track.is_empty() else view_positions.get(id,Vector2(cell))
	if previous!=Vector2(cell): track.append(Vector2(cell))

func smooth_actor(id: String, p: Vector2i, delta: float):
	if not view_positions.has(id): view_positions[id]=Vector2(p)
	record_actor(id,p)
	if world.paused or menu_open: return
	var rate=2.5*Farm.Life.factor(world)
	if id.begins_with("a"):
		var a=world.Orders.animal(world,int(id.substr(1)))
		rate=a.get("move_speed",2.0)*(1.5 if a.get("rescuing",false) else 1.0)
	elif id.begins_with("e"):
		for e in world.enemies:
			if e.id==int(id.substr(1)): rate=1.0 if e.carry=="keeper" else e.move_speed; break
	elif id=="keeper" and world.keeper.carrier>=0: rate=1.0
	var budget=delta*rate*(24.0 if not world.rest_skip.is_empty() else speed)
	var track=actor_tracks[id]
	while not track.is_empty() and budget>0:
		var current: Vector2=view_positions[id]
		var target: Vector2=track[0]
		var remaining=current.distance_to(target)
		# Non-cardinal discontinuities are explicit fixture/phase placement, not walking.
		if absf(current.x-target.x)>0.001 and absf(current.y-target.y)>0.001:
			view_positions[id]=target; track.pop_front(); continue
		var distance=minf(budget,remaining)
		view_positions[id]=current.move_toward(target,distance)
		budget-=distance
		if distance>=remaining: track.pop_front()

func actor_pixel(id: String, cell: Vector2i) -> Vector2:
	var p = center(view_positions.get(id, Vector2(cell)))
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
		if event.kind == "guide": react(event.animal_id, "wag", 1.5)
		refresh()
	for cell in world.structures:
		var b = world.structures[cell]
		var old = structure_views.get(b.id, "")
		if old != "" and old != b.status and b.status in ["ready", "destroyed"]:
			puff(center(cell), "build" if b.status == "ready" else "break")
			play_alert("build" if b.status == "ready" else "object")
		structure_views[b.id] = b.status
		if b.kind in Farm.Buildings.DOORS:
			gate_views[b.id] = move_toward(gate_views.get(b.id, 1.0 if b.open else 0.0), 1.0 if b.open else 0.0, delta * 5) if not world.paused else gate_views.get(b.id, 0.0)
	dust = dust.filter(func(f): return visual_time - f.at < 0.55)

func export_record():
	DirAccess.make_dir_recursive_absolute("user://observations")
	FileAccess.open("user://observations/latest.json", FileAccess.WRITE).store_string(JSON.stringify(world.observation(), "  "))
	notice("開発用観察JSONを保存しました")

func label_on(target: CanvasItem, p: Vector2, text_value: String, size: int = 17, color: Color = Color("f3ead1")):
	for i in range(text_value.split("\n").size()):
		target.draw_string(FONT, p+Vector2(0,i*22), text_value.split("\n")[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func rect(p: Vector2, size: Vector2, color: String): draw_rect(Rect2(p, size), Color(Color(color), art_alpha))

func draw_structure(p: Vector2, b: Dictionary, preview: bool = false):
	var shade = Color("baad83")
	if b.kind=="wood_wall": shade=Color("bc9367")
	if b.kind=="stone_wall": shade=Color("9ba4a3")
	if preview: shade.a = 0.45
	if b.kind in ["kennel","coop"] or b.status=="disabled": return
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
	elif b.kind in Farm.Buildings.WALLS:
		if not preview:
			var cell=Vector2i(p/TILE)
			for n in world.neighbors(cell):
				if not Farm.Buildings.enclosure(world.structures.get(n,{})): continue
				var offset=Vector2(n-cell)*TILE*0.5
				draw_line(p+Vector2(0,3),p+offset+Vector2(0,3),Color("797257"),24)
				draw_line(p-Vector2(0,10),p+offset-Vector2(0,10),shade,6)
		draw_rect(Rect2(p - Vector2(20, 13), Vector2(40, 29)), Color("797257"))
		draw_rect(Rect2(p - Vector2(20, 13), Vector2(40, 6)), shade)
		draw_line(p - Vector2(20, -2), p + Vector2(20, 2), Color("545642"), 2)
	else:
		draw_rect(Rect2(p - Vector2(24, 13), Vector2(6, 30)), shade)
		draw_rect(Rect2(p + Vector2(18, -13), Vector2(6, 30)), shade)
		var hinge = p - Vector2(15, 8)
		var tip = p + Vector2(15, 8).lerp(Vector2(-12, 15), gate_views.get(b.id, 1.0 if b.open else 0.0))
		draw_line(hinge, tip, shade, 5)
		draw_line(hinge + Vector2(0, 9), tip + Vector2(0, 9), Color("897447"), 4)
	if b.kind=="locked_door":
		draw_rect(Rect2(p+Vector2(-4,-6),Vector2(9,11)),Color("dfbf62") if b.get("lock_hp",0)>0 else Color("665e58"))
		if b.get("lock_hp",0)<=0: label_on(self,p+Vector2(-4,1),"×",12)
	if b.hp < b.max_hp:
		var crack = PackedVector2Array([p + Vector2(2, -12), p + Vector2(-5, -3), p + Vector2(2, 3)])
		if b.hp <= b.max_hp * 0.5:
			crack.append(p + Vector2(-8, 15))
			draw_rect(Rect2(p + Vector2(11, 8), Vector2(9, 8)), Color("4c6047"))
		draw_polyline(crack, Color("313d31"), 3)
		draw_rect(Rect2(p + Vector2(-18, 19), Vector2(36.0 * b.hp / b.max_hp, 3)), Color("ebc171"))

func _draw():
	BoardArt.draw_ground(self, world, TILE, visual_time)
	for cell in world.floors:
		var floor_data=world.floors[cell]
		if floor_data.status!="ready": continue
		var tint={"soil_tile":Color("ad946b"),"wood_tile":Color("bc9367"),"stone_tile":Color("929b95")}.get(floor_data.kind,Color("ad946b"))
		draw_rect(Rect2(Vector2(cell)*TILE,TILE),tint)
		for offset in [12,25,38]: draw_line(Vector2(cell)*TILE+Vector2(offset,2),Vector2(cell)*TILE+Vector2(offset,40),Color(tint.darkened(0.12)),1)
	for cell in world.indoor:
		draw_rect(Rect2(Vector2(cell)*TILE,TILE),Color(0.22,0.35,0.45,0.22 if debug_view else 0.08))
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
		elif Farm.Life.presentation(world) in ["unconscious","sleeping"]:
			draw_set_transform(p + Vector2(0, 12), -PI * 0.5)
			p = Vector2.ZERO
		elif Farm.Life.presentation(world) == "settling":
			p.y += 7
		elif Farm.Life.presentation(world) in ["tired","exhausted"]:
			draw_set_transform(p+Vector2(0,4),0.16)
			p = Vector2.ZERO
		# Static v1 at its delivered foot anchor. Walking/sleep poses remain provisional.
		UI.keeper(self,(p+Vector2(0,14)).round(),world.keeper.get("facing",1))
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
			if selected.get("kind") == "keeper": draw_rect(keeper_hit_rect(), Color("ffe2a3"), false, 2)
			if Farm.Life.presentation(world) in ["settling", "sleeping"]:
				label_on(self, owner_pixel + Vector2(15, -20), "…" if Farm.Life.presentation(world)=="settling" else "Zzz", 18, Color("dce8c2"))
			elif Farm.Life.presentation(world) in ["drowsy", "tired", "exhausted"]:
				var severe = world.keeper.sleepiness > 80
				var tired = Color("edba89") if severe else Color("e3d3a8")
				var badge = owner_pixel + Vector2(18,-34)
				draw_rect(Rect2(badge,Vector2(27 if severe else 18,20)),Color("4d5550"))
				draw_circle(badge+Vector2(9,9),6,tired)
				draw_circle(badge+Vector2(12,7),5,Color("4d5550"))
				if severe:
					draw_line(badge+Vector2(21,5),badge+Vector2(21,14),tired,2)
					draw_polyline(PackedVector2Array([badge+Vector2(18,11),badge+Vector2(21,14),badge+Vector2(24,11)]),tired,2)
				if severe:
					for i in range(2):
						var drift = fmod(visual_time * 5 + i * 8,16)
						draw_rect(Rect2(owner_pixel+Vector2(-17-i*4,drift-4),Vector2(3,4)),Color(0.24,0.25,0.29,0.38*(1-drift/20)))
				elif fmod(visual_time,9) < 1.2:
					draw_arc(owner_pixel+Vector2(1,-3),3,0,TAU,8,tired,1.5)
			if world.tick < world.keeper.get("whistle_until",-1): label_on(self,owner_pixel+Vector2(16,-22),"♪",20,Color("f1d99d"))
			if world.keeper.state == "unconscious": label_on(self, owner_pixel + Vector2(12, -18), "!", 22, Color("efa084"))
			if world.tick < world.keeper.hurt_until or selected.get("kind") == "keeper":
				draw_rect(Rect2(owner_pixel + Vector2(-17, -37), Vector2(34, 4)), Color("684b46"))
				draw_rect(Rect2(owner_pixel + Vector2(-17, -37), Vector2(34 * float(world.keeper.hp) / world.keeper.max_hp, 4)), Color("d68b74"))
	for item in world.field_items:
		var q = center(item.pos) + (Vector2(7, 8) if item.kind.ends_with("_plan") else Vector2.ZERO)
		if item.kind.ends_with("_plan") and world.keeper.placed and item.pos == world.keeper.pos: q = center(item.pos) + Vector2(-25,-22)
		if item.kind.ends_with("_plan"):
			draw_rect(Rect2(q-Vector2(11,9),Vector2(22,20)),Color("eddbad"))
			for side in [-1,1]:
				draw_rect(Rect2(q+Vector2(side*12-3,-12),Vector2(6,26)),Color("bb9762"))
			for y in [-4,1,6]: draw_line(q+Vector2(-6,y),q+Vector2(6,y),Color("8c795e"),1)
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
		if a.species == "shiba": draw_dog(p, a)
		elif a.species == "cat": draw_cat(p,a)
		else: draw_hen(p,a)
		var in_combat = world.enemies.any(func(e): return not e.done and not e.flee and Farm.distance(a.pos, e.pos) <= 1)
		if a.hp <= a.max_hp * 0.5 or in_combat:
			var danger = a.hp <= a.max_hp * Farm.Rules.LOW_HP_FRACTION
			var color = Color("f38c73") if danger else Color("efcc7f")
			draw_rect(Rect2(p + Vector2(-20, 23), Vector2(40, 5)), Color("3e4534"))
			draw_rect(Rect2(p + Vector2(-20, 23), Vector2(40.0 * a.hp / a.max_hp, 5)), color)
			if danger:
				color.a = 0.65 + 0.25 * sin(clock * 4)
				label_on(self, p + Vector2(-4, -29), "!", 23, color)
		if a.hp <= 0: label_on(self, p + Vector2(-18, -27), a.state, 16, Color("e2bcb3"))
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
					var bounds=animal_hit_rect(a)
					var corner = bounds.get_center() + bounds.size*Vector2(side,vertical)*0.5
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
	for cell in selected_resources: draw_rect(Rect2(center(cell)-Vector2(20,20),Vector2(40,40)),Color("ffe2a3"),false,2)
	if dragging:
		label_on(self,get_canvas_transform().affine_inverse()*pointer+Vector2(10,-10),{"animal":"仲間","resource":"回収物","structure":"建物","floor":"床"}.get(drag_class,""),16,UI.PAPER)
	if cinematic(): return
	var cell = Vector2i(get_canvas_transform().affine_inverse() * pointer / TILE)
	if world.working() and world.inside(cell) and not pointer_over_ui():
		var valid = false
		var show_preview = false
		if tool == "guide" and selected_animal >= 0:
			valid = world.animal_walkable(world.Orders.animal(world,selected_animal),cell)
			show_preview = true
			# A resident at the cursor already shows the species; do not overprint a second body.
			if guide_ghost_visible(cell):
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
	if group == 0 and selected.get("kind") in ["structure","floor"]:
		for p in selected_structures:
			if world.live_structure(p): draw_rect(Rect2(Vector2(p) * TILE + Vector2(2, 2), TILE - Vector2(4, 4)), Color("ffe2a3"), false, 2)

func guide_ghost_visible(cell: Vector2i) -> bool:
	return not world.animals.any(func(a): return a.pos == cell)

func panel(area: Rect2): hud.draw_style_box(UI.surface(Color("485d46")), area)

func draw_hud():
	if hover_job >= 0:
		for i in range(world.jobs.size()):
			if world.jobs[i].id == hover_job: hud.draw_rect(Rect2(1007,91+i*35,253,34),Color("ffe2a3"),false,2)
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
		label_on(hud, Vector2(181 + i * 115, 31), ("∞" if kind!="gold" and world.debug_enabled and world.debug_infinite else str(world.campaign.gold if kind == "gold" else world.resource_amount(kind))), 20)
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
		hud.draw_style_box(UI.surface(UI.DANGER if urgent else UI.MOSS), Rect2(380, top, 520, 42+22*(alert_text.count("\n"))))
		label_on(hud, Vector2(395, top + 29), alert_text, 20)
	if world.keeper.state in ["restrained", "captured"]:
		draw_edge(world.keeper.pos, "牧場主 !", Color("ffa58a"))
	for a in world.animals:
		if a.placed and a.hp <= a.max_hp * Farm.Rules.LOW_HP_FRACTION: draw_edge(a.pos, Farm.animal_name(a) + " !", Color("ff997f"))
	if alert_kind == "invasion" and alert_visible():
		for entry in world.entries: draw_edge(entry, "侵入 !", Color("f5d483"))
	var details = ""
	if selected.get("kind") == "resource":
		details = "回収予定" if collectible(selected.pos) else "回収済み"
		for item in world.items_at(selected.pos):
			if item.kind.ends_with("_plan"): details = Farm.Buildings.NAMES.get(item.kind.trim_suffix("_plan"),"建築")+"の設計図\n回収して習得を記録"
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
			var status = "撃退済み" if e.hp <= 0 or e.flee or e.done else ("牧場主を発見" if e.can_see_keeper else e.search_state)
			label_on(hud, Vector2(92, 677), "%d/%d  視界%d" % [e.hp, e.max_hp, e.sight_range] if Rect2(16, 609, 344, 80).has_point(pointer) else status, 15)
	elif selected.get("kind") in ["structure","floor"] and selected_store().has(selected.pos):
		var b = selected_store()[selected.pos]
		var quote = world.repair_quote(selected.pos,selection_layer)
		details = "%s Lv1   耐久 %d/%d\n解体返却 %s" % [Farm.Buildings.NAMES.get(b.kind,"建物"), b.hp, b.max_hp, resource_text({b.get("resource", "soil"): world.dismantle_quote(selected.pos,selection_layer)})]
		if selected_structures.size() > 1:
			var refund = {"soil": 0, "wood": 0, "stone": 0}
			for cell in selected_structures: refund[selected_store()[cell].get("resource", "soil")] += world.dismantle_quote(cell,selection_layer)
			details = "まとめて %dか所\n解体返却 %s" % [selected_structures.size(), resource_text(refund)]
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
		label_on(hud, p + Vector2(10, 22), "%s %d/%d → 修理 +%d" % [{"wall":"土壁","wood_wall":"木壁","stone_wall":"石壁","door":"ドア","locked_door":"ロック付きドア","kennel":"犬小屋","coop":"鶏小屋"}.get(b.kind,"施設"), b.hp, b.max_hp, quote.hp], 16)
		label_on(hud, p + Vector2(10, 45), "%s%s" % [resource_text({b.get("resource", "soil"): quote.cost}), ""], 16)
	if world.phase == "result":
		panel(Rect2(362, 225, 554, 340))
		label_on(hud, Vector2(398, 271), "守りきった！" if world.result == "win" else "牧場主が連れ去られた", 27)
		label_on(hud, Vector2(398, 311), "評価 %d   EXP +%d   GOLD +%d" % [world.score.rating, world.score.xp, world.score.gold], 18)
	if world.working() and world.early_clear:
		label_on(hud, Vector2(935, 735), "夜明けまで自由に", 16)
	if debug_view: label_on(hud, Vector2(15, 125), "DEBUG ON: seed %d / tick %d  F3:OFF" % [world.seed_value, world.tick], 14)

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
	var resting=animal.get("state","") in ["休む","自主休養"]
	var walking=not animal.is_empty() and Vector2(animal.pos).distance_to(view_positions.get("a%d" % animal.id,Vector2(animal.pos)))>0.025
	var reaction=reactions.get(animal.get("id",-1),{})
	var mood=reaction.get("kind","") if clock<reaction.get("until",-1) else ""
	p.y-=absf(sin(visual_time*(13 if walking else 2)))*(2.0 if walking else 0.5)
	if mood=="happy":p.y-=absf(sin(visual_time*9))*5
	if mood=="wag":p.x+=sin(visual_time*12)*1.5
	var alert=not animal.is_empty() and world.enemies.any(func(e):return not e.done and not e.flee and Farm.distance(animal.pos,e.pos)<=animal.get("detection_range",4))
	var pose=1 if mood=="hello" else (0 if dog_facing(animal)<0 else 2)
	UI.shiba(self,(p+Vector2(0,14)).round(),pose,art_alpha)

func draw_hen(p: Vector2, animal: Dictionary = {}):
	if not animal.is_empty():
		draw_set_transform(p,0,Vector2(animal.get("facing",1),1))
		p=Vector2.ZERO
	var peck = maxf(0, sin(visual_time * 2.8 + p.x)) * 5
	draw_circle(p, 12, Color(Color("f4ebcf"), art_alpha))
	var head = p + Vector2(peck * 0.5, peck)
	rect(head + Vector2(3, -13), Vector2(12, 14), "fff4d8")
	rect(head + Vector2(5, -18), Vector2(8, 5), "c45d4d")
	rect(head + Vector2(15, -7), Vector2(5, 4), "edb65a")
	rect(head + Vector2(11, -10), Vector2(2, 2), "243d36")
	rect(p + Vector2(-6, 11), Vector2(3, 6), "d69a4e")
	rect(p + Vector2(4, 11), Vector2(3, 6), "d69a4e")
	if not animal.is_empty(): draw_set_transform(Vector2.ZERO)

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
	title.text = "休息"
	title.position = Vector2(570, 250)
	title.add_theme_font_size_override("font_size", 28)
	menu.add_child(title)
	add_button(menu, "menu_resume", "続ける", Rect2(480, 320, 320, 50), toggle_menu)
	add_button(menu, "menu_retry", "昼からやり直す", Rect2(480, 390, 320, 50), restart_menu)
	add_button(menu, "menu_morning", "今朝からやり直す", Rect2(480, 460, 320, 50), restart_morning)
	var stamp=Label.new()
	var metadata=JSON.parse_string(FileAccess.get_file_as_string("res://game/build_stamp.json")) if FileAccess.file_exists("res://game/build_stamp.json") else {}
	stamp.text="ビルド "+str(metadata.get("commit","未記録"))+(" + 未コミット変更" if metadata.get("dirty",true) else "")
	stamp.position=Vector2(480,532)
	stamp.add_theme_font_size_override("font_size",14)
	menu.add_child(stamp)
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
		press_pending = false
		queue_drag_id = -1
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

func open_market():
	morning_screen = "market"
	shop_side = "home"
	shop_level = "categories"
	refresh()

func open_book():
	morning_screen = "book"
	shop_side = "animals"
	training_id = world.campaign.animals[0].id
	book_started = clock
	book_motion = "open"
	refresh()

func close_morning_screen():
	if morning_screen == "book":
		book_motion = "close"
		book_started = clock
	else:
		morning_screen = "morning"
		shop_side = "home"
	refresh()

func turn_book(direction: int):
	if book_motion != "": return
	var owned = world.campaign.animals
	var index = 0
	for i in range(owned.size()):
		if owned[i].id == training_id: index = i
	book_direction = direction
	book_next_id = owned[posmod(index + direction, owned.size())].id
	book_started = clock
	book_motion = "turn"
	rename_open = false
	refresh()

func build_shop():
	if morning_screen == "morning":
		add_button(palette,"open_market","朝の市",Rect2(377,497,220,46),open_market)
		buttons.open_market.icon=UI.icon("basket")
		add_button(palette,"open_book","図鑑を開く",Rect2(725,497,220,46),open_book)
		buttons.open_book.icon=UI.icon("book")
		return
	add_button(palette, "close_market", "閉じる", Rect2(1048, 122, 116, 38), close_morning_screen)
	buttons.close_market.icon = UI.icon("cross")
	if morning_screen == "book":
		build_training()
		add_button(palette, "book_prev", "←", Rect2(215, 690, 80, 36), turn_book.bind(-1))
		add_button(palette, "book_next", "→", Rect2(1000, 690, 80, 36), turn_book.bind(1))
		buttons.book_prev.disabled = world.campaign.animals.size() < 2
		buttons.book_next.disabled = world.campaign.animals.size() < 2
		return
	if shop_side == "home":
		for i in range(2):
			var id = ["buy", "sell"][i]
			add_card("shop_" + id, ["買う\n今日の品", "売る\n牧場の恵み", "動物\n大切な仲間"][i], id, Rect2(392 + i * 345, 273, 304, 215), shop_choose.bind(id, "animals"), [Color("d8b784"), Color("dcc783"), Color("bbcca3")][i])
		return
	for side in ["buy","sell"]:
		add_button(palette,"market_"+side,"買う" if side=="buy" else "売る",Rect2(640 if side=="buy" else 809,211,156,37),shop_choose.bind(side,"animals"))
		buttons["market_"+side].icon=UI.icon("basket" if side=="buy" else "coin")
		UI.selected(buttons["market_"+side],shop_side==side)
	var back_label = "戻る"
	if shop_side == "animals" and training_id >= 0: back_label = "仲間たちへ"
	elif shop_level == "detail": back_label = "商品一覧へ"
	elif shop_level == "list": back_label = "品の種類へ"
	add_button(palette, "shop_back", back_label, Rect2(135, 654, 172, 38), market_back)
	if shop_side == "animals":
		build_training()
		return
	if shop_level == "categories":
		var i = 0
		for category in MARKET_CATEGORIES:
			var row = MARKET_CATEGORIES[category]
			add_card("category_" + category, row[0] + "\n" + row[2], row[1], Rect2(410 + (i % 2) * 354, 284 + (i / 2) * 180, 332, 163), choose_category.bind(category), Color("cfbd96") if i % 2 == 0 else Color("bdc69d"))
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
	for index in range(shop_page * 4, mini(rows.size(), shop_page * 4 + 4)):
		var row = rows[index]
		var p = Farm.Shop.table()[row.id]
		var price = p.BuyPrice if shop_side == "buy" else p.SellPrice
		var n = index % 4
		var price_tag = "%d G" % price if row.count > 0 else "売り切れ"
		add_card("trade_" + row.id + "_" + str(row.animal_id), product_title(row) + "\n" + price_tag, row.id, Rect2(410 + (728 - mini(4,rows.size()-shop_page*4)*180)*0.5 + n * 180, 306, 169, 294), inspect_product.bind(row), Color("eee3c9") if row.count > 0 else Color("b9b99e"))
		buttons["trade_" + row.id + "_" + str(row.animal_id)].tooltip_text = product_description(row.id)
	if rows.size() > 4: add_button(palette, "shop_page", "次の品へ →", Rect2(935, 640, 215, 38), next_shop_page.bind(ceili(rows.size() / 4.0)))

func product_title(row: Dictionary) -> String:
	if row.get("animal_id", -1) >= 0:
		for a in world.campaign.animals:
			if a.id == row.animal_id: return Farm.animal_name(a) + " Lv%d" % a.lv
	return Farm.Shop.table()[row.id].Name

func product_description(id: String) -> String:
	if id == "coffee": return "眠気を少し和らげる。飲み物は1日2杯まで"
	if id == "energy_drink": return "眠気をぐっと和らげる。休息も忘れずに"
	return {"hen": "朝に卵を産む、のんびりした仲間。", "cat": "牧場を気ままに歩く、小さな仲間。", "soil": "壁や床を築くための、よく締まる土。", "wood": "小屋づくりに使う、丈夫な木材。", "stone": "重くて丈夫な石。", "egg": "牧場で産まれた新鮮な卵。", "feather": "鶏が落とした、軽く柔らかな羽。", "mushroom": "夜明けの休養に。傷ついた仲間を癒す。", "whistle":"6マス先へ呼びかけ、仲間を一緒に誘導する。", "kennel_plan": "犬が落ち着いて休める、小屋の作り方。"}.get(id, "牧場で使う品物。")
func next_shop_page(count: int):
	shop_page = (shop_page + 1) % count
	refresh()

func add_card(id: String, title: String, icon: String, area: Rect2, callback: Callable, color: Color):
	add_button(palette, id, "", area, callback)
	var button = buttons[id]
	UI.button(button, color)
	button.draw.connect(draw_market_card.bind(button, icon, title))

func draw_market_card(button: Button, icon: String, title: String):
	var p = Vector2(button.size.x / 2, 55 if button.size.y < 220 else 106)
	draw_card_icon(button, icon, p, (2.3 if icon in ["soil", "wood", "stone"] else 1.3) if button.size.y < 220 else 2.1)
	var lines = title.split("\n")
	for i in range(lines.size()):
		var size_value = 22 if i == 0 else 16
		var width = FONT.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size_value).x
		label_on(button, Vector2((button.size.x - width) / 2, button.size.y - 49 + i * 26), lines[i], size_value, UI.INK)

func draw_shop():
	if morning_screen == "morning":
		hud.draw_style_box(UI.surface(Color("d6c6a1")),Rect2(330,128,656,437))
		hud.draw_texture_rect(UI.STALL,Rect2(346,154,282,317),false)
		hud.draw_texture_rect(UI.icon("book_closed"),Rect2(778,265,120,132),false)
		label_on(hud,Vector2(716,204),"牧場の仲間",22,UI.INK)
		label_on(hud,Vector2(379,153),"%d日目の朝" % world.campaign.day,19,UI.INK)
		return
	hud.draw_rect(Rect2(0, 0, 1280, 800), Color(0.13, 0.18, 0.17, 0.65))
	if morning_screen == "book":
		draw_book()
		return
	hud.draw_style_box(UI.surface(Color("29392f")),Rect2(119,108,1065,608))
	hud.draw_style_box(UI.surface(Color("a58c65")),Rect2(107,96,1065,608))
	hud.draw_style_box(UI.surface(Color("efe4ca")),Rect2(117,106,1045,583))
	# Quiet A-style information layout with C-style stall/merchant warmth.
	for i in range(17):
		var x=120+i*61
		var color=Color("cdb584") if i%2==0 else Color("809880")
		hud.draw_rect(Rect2(x,105,61,17),color)
	hud.draw_line(Vector2(143,195),Vector2(1138,195),Color("c5b084"),2)
	label_on(hud,Vector2(146,174),"朝の市",36,UI.INK)
	draw_card_icon(hud,"gold",Vector2(918,159),0.65)
	label_on(hud,Vector2(952,170),"%d G" % world.campaign.gold,25,UI.INK)
	if shop_side != "home":
		label_on(hud,Vector2(355,263),("買う" if shop_side=="buy" else "売る")+"  /  "+(MARKET_CATEGORIES[shop_category][0] if shop_level!="categories" else "今日の品"),20,UI.INK)
	hud.draw_texture_rect(UI.STALL,Rect2(124,237,272,345),false)
	var greeting=shop_notice if shop_notice!="" else "いらっしゃい"
	label_on(hud,Vector2(160,614),greeting,16,UI.INK)
	hud.draw_rect(Rect2(335,611,802,12),Color("a98d61"))
	if shop_side == "home":
		for i in range(4):draw_card_icon(hud,["hen","cat","wood","soil"][i],Vector2(470+i*166,555),1.25)
	if shop_side in ["buy", "sell"] and shop_level == "list" and shop_rows().is_empty():
		hud.draw_style_box(UI.surface(UI.PAPER), Rect2(485, 288, 430, 118))
		draw_card_icon(hud, "basket", Vector2(544, 342), 1.1)
		label_on(hud, Vector2(597, 344), "今日は空っぽだね。", 22, UI.INK)
		label_on(hud, Vector2(597, 377), "ほかの品も見ていこう。", 16, UI.INK)
	if shop_side in ["buy", "sell"] and shop_level == "detail": draw_product_detail()
	if shop_side == "animals" and training_id >= 0: draw_animal_detail()

func draw_market_merchant(p: Vector2):
	hud.draw_rect(Rect2(p+Vector2(-44,4),Vector2(88,75)),Color("69816b"))
	hud.draw_rect(Rect2(p+Vector2(-18,9),Vector2(35,65)),Color("dbc592"))
	hud.draw_circle(p+Vector2(0,-27),35,Color("e1b68e"))
	hud.draw_style_box(UI.surface(Color("c7a66f")),Rect2(p+Vector2(-33,-88),Vector2(66,42)))
	hud.draw_style_box(UI.surface(Color("d8bc86")),Rect2(p+Vector2(-55,-54),Vector2(110,14)))
	for x in [-13,13]:hud.draw_circle(p+Vector2(x,-25),3,UI.INK)
	hud.draw_arc(p+Vector2(0,-20),15,0.35,PI-0.35,10,UI.WOOD,2)
	hud.draw_rect(Rect2(p+Vector2(-65,80),Vector2(130,15)),UI.WOOD)
	draw_card_icon(hud,"wood",p+Vector2(-43,98),0.8)


func draw_product_detail():
	var p = Farm.Shop.table()[product_row.id]
	var rows = shop_rows().filter(func(row): return row.id == product_row.id and row.animal_id == product_row.animal_id)
	var count = rows[0].count if not rows.is_empty() else 0
	var price = p.BuyPrice if shop_side == "buy" else p.SellPrice
	hud.draw_style_box(UI.surface(UI.PAPER), Rect2(407, 281, 724, 320))
	hud.draw_style_box(UI.surface(Color("c2cda4")), Rect2(421, 305, 175, 266))
	draw_card_icon(hud, p.ProductID, Vector2(508, 398), 2.3)
	label_on(hud, Vector2(622, 329), product_title(product_row), 30, UI.INK)
	label_on(hud, Vector2(622, 366), product_description(p.ProductID), 17, UI.INK)
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
	add_button(palette, "train_%d" % training_id, "育てる  %d EXP" % world.level_cost(training_id), Rect2(659, 608, 216, 46), train.bind(training_id))
	buttons["train_%d" % training_id].icon = UI.icon("spark")
	for a in owned:
		if a.id == training_id:
			buttons["train_%d" % training_id].disabled = a.lv >= 5 or world.campaign.exp_pool < world.level_cost(training_id)
			if a.lv >= 5: buttons["train_%d" % training_id].text = "最大Lv"
	add_button(palette, "rename", "名前を変える", Rect2(886, 608, 178, 46), open_name)
	if rename_open:
		name_edit = LineEdit.new()
		name_edit.position = Vector2(659, 550)
		name_edit.size = Vector2(215, 42)
		name_edit.max_length = 12
		name_edit.call_deferred("grab_focus")
		name_edit.add_theme_stylebox_override("normal", UI.surface(UI.PAPER))
		name_edit.add_theme_color_override("font_color", UI.INK)
		for a in owned:
			if a.id == training_id: name_edit.text = a.name
		palette.add_child(name_edit)
		add_button(palette, "save_name", "この名前にする", Rect2(886, 550, 178, 42), save_name)

func animal_hp(a: Dictionary) -> int:
	return Farm.SPECIES[a.species].hp + (a.lv - 1) * 4

func draw_book():
	hud.draw_texture_rect(UI.BOOK,Rect2(153,115,972,623),false)
	label_on(hud,Vector2(250,221),"動物図鑑",24,UI.INK)
	draw_animal_detail()
	var index=0
	for i in range(world.campaign.animals.size()):
		if world.campaign.animals[i].id==training_id:index=i
	label_on(hud,Vector2(610,676),"%d / %d" % [index+1,world.campaign.animals.size()],14,UI.INK)

func draw_animal_detail():
	for a in world.campaign.animals:
		if a.id != training_id: continue

		hud.draw_style_box(UI.surface(Color("c4cea7")), Rect2(262, 256, 299, 270))
		draw_card_icon(hud, a.species, Vector2(416, 354), 2.5)
		var hp = a.get("hp", animal_hp(a))
		var hp_max = animal_hp(a)
		label_on(hud, Vector2(310, 466), "休養中" if a.get("unavailable_through_day", 0) >= world.campaign.day else ("元気いっぱい" if hp == hp_max else "休養が必要"), 19, UI.INK)
		hud.draw_style_box(UI.surface(UI.MOSS, UI.MOSS), Rect2(332, 489, 158, 10))
		hud.draw_rect(Rect2(334, 491, 154.0 * hp / hp_max, 6), Color("b5d28a"))
		label_on(hud, Vector2(265, 562), Farm.animal_name(a), 26, UI.INK)
		label_on(hud, Vector2(265, 596), "%s · Lv%d" % [Farm.SPECIES[a.species].title, a.lv], 18, UI.INK)
		label_on(hud, Vector2(665, 275), "この子のこと", 26, UI.INK)
		label_on(hud, Vector2(960, 284), "%d EXP" % world.campaign.exp_pool, 18, UI.INK)
		hud.draw_texture(UI.icon("heart"), Vector2(666, 308))
		label_on(hud, Vector2(691, 322), "%d / %d" % [hp, hp_max], 17, UI.INK)
		label_on(hud, Vector2(819, 322), "忠誠 %d%s" % [a.get("loyalty", 0), "  親密 %d" % a.affinity if a.affinity != null else ""], 15, UI.INK)
		var y = 367
		for id in Farm.SPECIES[a.species].skills:
			var skill = Farm.AnimalData.SKILLS[id]
			var ready = a.lv >= skill.unlock_level
			hud.draw_style_box(UI.surface(Color("d1d8b2") if ready else Color("d3cbb4")), Rect2(659, y - 18, 405, 74))
			hud.draw_texture(UI.icon("spark" if ready else "pause"), Vector2(671, y - 1))
			label_on(hud, Vector2(695, y + 10), skill.name, 21, UI.INK)
			var summary = {"bark": "敵検知時。周囲4マスの敵の移動を1秒停止。", "rescue": "牧場主の気絶・連れ去り時、救出を優先。", "lay": "朝になると卵を産む。", "feather": "時々、きれいな羽を落とす。", "charm": "動物と仲良くなる素質。", "meow": "鳴き声で、敵の勢いを弱める。"}.get(id, skill.effect)
			label_on(hud, Vector2(669, y + 38), summary if ready else "Lv%dで解放" % skill.unlock_level, 13, UI.INK)
			label_on(hud,Vector2(817,y+10),("発動" if skill.type=="active" else "パッシブ")+" / Lv%d" % skill.unlock_level+(" / CT %d秒" % skill.cooldown if skill.has("cooldown") else ""),12,UI.INK)
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
	if kind=="shiba":
		UI.shiba(c,Vector2(0,20),1)
	elif kind == "cat":
		var fur = Color("d49a5c") if kind == "shiba" else Color("aeb9c4")
		c.draw_rect(Rect2(-20, -5, 31, 21), fur)
		c.draw_rect(Rect2(1, -19, 24, 24), fur.lightened(0.16))
		c.draw_colored_polygon(PackedVector2Array([Vector2(1, -15), Vector2(3, -29), Vector2(12, -18)]), fur)
		c.draw_colored_polygon(PackedVector2Array([Vector2(17, -18), Vector2(23, -28), Vector2(25, -13)]), fur)
		c.draw_rect(Rect2(13, -7, 15, 10), Color("f8e5bd"))
		c.draw_circle(Vector2(18, -12), 2, Color("273a35"))
		c.draw_line(Vector2(-19, 3), Vector2(-28, -7), fur, 5)
		c.draw_rect(Rect2(-13,7,22,8),Color("f0dfbd"))
		for x in [-16,4]: c.draw_rect(Rect2(x,13,7,10),fur.darkened(0.1))
		c.draw_rect(Rect2(25,-5,4,4),UI.INK)
		c.draw_line(Vector2(17,0),Vector2(22,2),UI.WOOD,1)
		if kind=="cat":
			c.draw_line(Vector2(7,-3),Vector2(-1,-5),UI.INK,1)
			c.draw_line(Vector2(22,-1),Vector2(30,2),UI.INK,1)
			c.draw_rect(Rect2(6,-24,4,8),Color("d9b7a4"))
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
		c.draw_arc(Vector2(-5,3),10,0.1,PI,10,Color("d3bd8b"),2)
		c.draw_colored_polygon(PackedVector2Array([Vector2(-18,0),Vector2(-30,-12),Vector2(-26,9)]),Color("fff0ce"))
		for x in [-9,6]:
			c.draw_line(Vector2(x,18),Vector2(x,25),Color("bb904f"),2)
			c.draw_line(Vector2(x-4,25),Vector2(x+3,25),Color("bb904f"),2)
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
func draw_cat(p: Vector2, animal: Dictionary = {}):
	if not animal.is_empty():
		draw_set_transform(p,0,Vector2(animal.get("facing",1),1))
		p=Vector2.ZERO
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
	if not animal.is_empty(): draw_set_transform(Vector2.ZERO)

func draw_queue_badge(row: Button, number: int):
	row.draw_style_box(UI.surface(UI.PAPER),Rect2(5,3,27,25))
	label_on(row,Vector2(12,22),str(number),17,UI.INK)

func draw_queue_drag():
	if queue_drag_id < 0 or pointer.distance_to(queue_drag_start)<7: return
	var index=-1
	for i in range(world.jobs.size()):
		if world.jobs[i].id==queue_drag_id:index=i
	if index<0:return
	var y=94+queue_drop_index*35+(35 if queue_drop_index>index else 0)
	overlay.draw_line(Vector2(1004,y),Vector2(1258,y),UI.INK,8)
	overlay.draw_line(Vector2(1004,y),Vector2(1258,y),UI.GOLD,4)
	overlay.draw_colored_polygon(PackedVector2Array([Vector2(995,y-6),Vector2(1005,y),Vector2(995,y+6)]),UI.GOLD)
	overlay.draw_style_box(UI.surface(UI.PAPER,UI.INK),Rect2(946,y-12,43,23))
	label_on(overlay,Vector2(951,y+5),"ここ",13,UI.INK)
	overlay.draw_style_box(UI.surface(UI.PAPER.darkened(0.15)),Rect2(1010,94+index*35,214,31))
	var p=(pointer+Vector2(-260,14)).clamp(Vector2(5,50),Vector2(1030,660))
	overlay.draw_style_box(UI.surface(Color(0.13,0.17,0.12,0.55)),Rect2(p+Vector2(6,9),Vector2(242,43)))
	overlay.draw_style_box(UI.surface(UI.PAPER,UI.GOLD),Rect2(p,Vector2(242,43)))
	var names={"wall":"壁","door":"ドア","locked_door":"施錠ドア","collect":"回収","animal_order":"仲間へ指示","repair":"修理","remove":"解体","gate":"ドアを開閉"}
	label_on(overlay,p+Vector2(12,29),"%d   %s" % [index+1,names.get(world.jobs[index].kind,"仕事")],19,UI.INK)

func draw_transition():
	draw_queue_drag()
	if mode_cursor != "":
		overlay.draw_texture(UI.cursor(mode_cursor),pointer-Vector2(2,2))
	if book_motion != "":
		var duration = 0.3 if book_motion == "turn" else 0.4
		var t = clampf((clock - book_started) / duration, 0, 1)
		if book_motion == "turn":
			var edge=638+book_direction*425*cos(PI*t)
			var lift=sin(PI*t)*38
			var sheet=PackedVector2Array([Vector2(638,182),Vector2(edge,182-lift),Vector2(edge,674-lift*0.3),Vector2(638,674)])
			overlay.draw_colored_polygon(PackedVector2Array([Vector2(638,187),Vector2(edge+12,195),Vector2(edge+12,685),Vector2(638,679)]),Color(0.22,0.18,0.12,0.18*sin(PI*t)))
			overlay.draw_polygon(sheet,PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2(0.5,0.12),Vector2(0.94,0.12),Vector2(0.94,0.84),Vector2(0.5,0.84)]),UI.BOOK)
			overlay.draw_polyline(PackedVector2Array([sheet[1],sheet[2],sheet[3]]),Color("bba77e"),2)
		else:
			var openness=t if book_motion=="open" else 1-t
			var x=200+430*openness
			var alpha=1-smoothstep(0.55,1.0,openness)
			overlay.draw_colored_polygon(PackedVector2Array([Vector2(638,170),Vector2(x,174+10*openness),Vector2(x,685-10*openness),Vector2(638,691)]),Color(0.46,0.40,0.28,alpha))
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
		var caption = "気絶" if a.hp <= 0 else ("助けに行く！" if a.rescuing else ("休息" if resting else ("そばにいるよ" if a.mode == "stay" else "気ままに")))
		label_on(hud, Vector2(92, 678), "%d / %d" % [a.hp, a.max_hp] if Rect2(16, 609, 344, 80).has_point(pointer) else caption, 14, Color("b9c9b5"))
		if selected_animals.size() > 1: label_on(hud, Vector2(301, 677), "×%d" % selected_animals.size(), 16)

func companion_box() -> StyleBox:
	return UI.surface(UI.MOSS)

func dog_part(p: Vector2, offset: Vector2, size_value: Vector2, tint: String, facing: float):
	rect(p + Vector2(facing * (offset.x + size_value.x / 2) - size_value.x / 2, offset.y), size_value, tint)

func dog_facing(a: Dictionary) -> float:
	return float(a.get("facing",1))

func keeper_card_rect() -> Rect2:
	var owner_screen=get_canvas_transform()*keeper_pixel()
	return Rect2(16,485 if Rect2(8,575,450,125).has_point(owner_screen) else 595,422,91)

func draw_keeper_card():
	var k = world.keeper
	hud.draw_set_transform(keeper_card_rect().position-Vector2(16,595))
	hud.draw_style_box(UI.surface(UI.PAPER), Rect2(16, 595, 422, 91))
	UI.keeper(hud,Vector2(48,653))
	label_on(hud, Vector2(78, 615), "牧場主", 17, UI.INK)
	for i in range(2):
		var y = 626 + i * 18
		hud.draw_texture_rect(UI.icon("heart" if i == 0 else "moon"), Rect2(78, y, 14, 14), false)
		hud.draw_rect(Rect2(100, y + 3, 170, 8), Color("b9b69c"))
		var ratio = float(k.hp) / k.max_hp if i == 0 else k.sleepiness / 100.0
		hud.draw_rect(Rect2(100, y + 3, 170 * ratio, 8), Color("bf7661") if i == 0 else Color("8087a7"))
		label_on(hud, Vector2(279, y + 12), "%d/%d" % [k.hp, k.max_hp] if i == 0 else "%d%%" % k.sleepiness, 13, UI.INK)
	var activity = "連れ去り" if k.carrier >= 0 else ("気絶" if k.state == "unconscious" else ("限界休息" if k.forced_rest else (("寝入り待ち" if Farm.Life.presentation(world)=="settling" else "睡眠") if k.resting else ("散歩中" if world.manual_goal != null else ("再開待ち" if world.jobs_held else ("仕事中" if not world.jobs.is_empty() else "のんびり"))))))
	label_on(hud, Vector2(30, 676), activity, 15, UI.INK)
	if not world.jobs.is_empty():
		var names = {"wall": "壁", "door":"ドア","locked_door":"施錠ドア","wood_wall":"木壁","stone_wall":"石壁","soil_tile":"土タイル","wood_tile":"木タイル","stone_tile":"石タイル", "collect": "回収", "move": "歩く", "animal_order": "仲間へ指示", "repair": "修理", "remove": "解体", "remove_floor":"タイル解体", "repair_floor":"床修理", "gate": "ドア", "kennel": "犬小屋", "coop": "鶏小屋"}
		var next = names.get(world.jobs[0].kind, "仕事")
		if world.jobs.size() > 1: next += " → " + names.get(world.jobs[1].kind, "仕事")
		label_on(hud, Vector2(166, 676), next, 14, UI.INK)
	hud.draw_set_transform(Vector2.ZERO)

func keeper_pixel() -> Vector2:
	if world.keeper.carrier >= 0:
		return center(view_positions.get("e%d" % world.keeper.carrier, Vector2(world.keeper.pos))) + Vector2(34,-36)
	return actor_pixel("keeper", world.keeper.pos)

func rest_button_text() -> String:
	if not world.rest_skip.is_empty(): return "時間送りを中断"
	if world.phase=="day": return "夜まで休む"
	return "朝まで休む +%dG" % floori(world.remaining_night()/10.0)

func build_debug_controls():
	var entries=[["infinite","素材∞"],["whistle","ホイッスル"],["shiba","柴犬＋"],["hen","鶏＋"],["cat","猫＋"],["hurt","HP−10"],["heal","HP＋10"],["lock","ロック−4"]]
	for i in range(entries.size()):
		var row=entries[i]
		add_button(palette,"debug_"+row[0],("素材∞ ON" if world.debug_infinite else "素材∞ OFF") if row[0]=="infinite" else row[1],Rect2(16+(i%2)*124,145+(i/2)*37,118,32),debug_action.bind(row[0]))

	buttons.debug_lock.disabled=selected.get("kind")!="structure" or world.structures.get(selected.get("pos"),{}).get("kind")!="locked_door" or world.structures.get(selected.get("pos"),{}).get("status")!="ready"

func debug_action(action: String):
	world.debug_action(action,selected)
	refresh()

func keeper_hit_rect() -> Rect2:
	var p=keeper_pixel()
	if Farm.Life.presentation(world) in ["sleeping","unconscious","carried"]: return Rect2(p+Vector2(-32,-12),Vector2(58,34))
	return Rect2(p+Vector2(-17,-32),Vector2(34,49))

func animal_hit_rect(a: Dictionary) -> Rect2:
	var p=actor_pixel("a%d" % a.id,a.pos)
	return Rect2(p+Vector2(-17,-18),Vector2(34,37)) if a.species=="shiba" else Rect2(p-Vector2(25,25),Vector2(50,50))
