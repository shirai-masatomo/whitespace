extends Node2D
const Assets=preload("res://game/ui_assets.gd")
const Journal=preload("res://game/journal_view.gd")
const ProgressArt=preload("res://game/progression_art.gd")
const ProgressView=preload("res://game/progression_view.gd")
var book_section="animals"
var equipment_open=false
const StoryView = preload("res://game/story_view.gd")
var story_modal=""
var story_page=0
var story_panel: Control
var selected_trees: Array=[]
const Farm = preload("res://game/world.gd")
const MorningSave=preload("res://game/morning_save.gd")
var persistence_enabled=false
var save_path=MorningSave.PATH
var save_status=""
var save_load_blocked=false
const FONT = preload("res://assets/fonts/ui_font.tres")
const TILE = Vector2(48, 42)
const GROUPS = ["建設", "指示"]
const Direction=preload("res://game/direction_art.gd")
const SixMotion=preload("res://game/six_motion.gd")
const HumanVisual=preload("res://game/human_visual.gd")
var six_art={}
var six_revived={}
const TOOLS = {"milk":"搾乳", "charge":"突撃", "place_kokeshi":"こけしを置く", "place_fossil":"化石を置く","wall": "壁  10 / 1秒", "wood_wall":"木壁 木10", "stone_wall":"石壁 石10", "soil_tile":"土タイル 土2", "wood_tile":"木タイル 木2", "stone_tile":"石タイル 石2", "door":"ドア 木10", "locked_door":"施錠ドア 木20", "guide":"連れていく", "equip":"装備", "repair": "修理", "gate": "ドア開閉", "remove": "解体",
	"attack_target":"狙う", "auto": "おまかせ", "stay": "待機", "wander": "徘徊", "rest": "休む", "collect": "資源・卵・設計図", "dog_food": "犬用餌 HP+10", "hen_food": "鶏用餌 HP+8", "cat_food": "猫用餌 HP+8"}
const GROUP_TOOLS = [["wall", "wood_wall", "stone_wall", "soil_tile", "wood_tile", "stone_tile", "door", "locked_door", "place_kokeshi", "place_fossil"], ["guide", "auto", "stay", "wander", "rest", "attack_target", "equip", "milk", "charge"], ["collect"]]
const BoardArt = preload("res://game/board_art.gd")
const BuildingArt = preload("res://game/building_art.gd")
const Art = preload("res://game/adopted_art.gd")
const Delivered = preload("res://game/delivered_art.gd")
var enemy_art: Dictionary = {}
var work_dust_at = -1.0
var actor_art: Dictionary = {}
const UI = preload("res://game/ui_style.gd")
const MarketView = preload("res://game/market_view.gd")
const MARKET_CATEGORIES = {"animals": ["動物", "animals", "動物の取引"], "materials": ["資材", "wood", "土・木・石"], "facilities": ["施設", "hammer", "牧場づくり"], "items": ["小物と恵み", "basket", "卵・羽・道具"]}
var world = Farm.new({}, randi_range(1, 2147483646))
var subtasks = preload("res://game/subtasks.gd").new()
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
var pan_origin = Vector2.ZERO
var shift_latched = false
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
var restart_confirm=false
var book_view
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
var debug_enemy_kind = "kidnapper"
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
	automated=automated or "--automated" in OS.get_cmdline_user_args() or "--smoke" in OS.get_cmdline_user_args()
	persistence_enabled=not automated
	if persistence_enabled:
		var saved=MorningSave.read(save_path)
		if saved.status in ["ok","recovered"]:
			world=MorningSave.restore(saved.record)
			save_status="保存した朝から再開しました" if saved.status=="ok" else "予備の記録から朝を復元しました"
		elif saved.status=="missing":save_morning(world)
		else:
			save_load_blocked=true
			save_status="保存を読めません。記録を保護しています。確認してから再起動してください"
	subtasks.load_settings()
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
	buttons.speed.tooltip_text = "1：0.5倍 / 2：1倍 / 3：2倍 / 4：4倍（休息中）。Space：停止。− / ＋：段階変更"
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
	buttons.walk.tooltip_text = "Tab：建設 → 指示 → 牧場主。Shift：操作選択。ホイール：ズーム"
	setup_menu()
	overlay = Node2D.new()
	layer.add_child(overlay)
	overlay.draw.connect(draw_transition)
	book_view = preload("res://game/book_view.gd").new()
	add_child(book_view)
	book_view.setup(self)
	if world.phase == "shop": arrival_started = clock
	refresh()
	controls.visible = not cinematic() and story_modal==""
	if "--automated" in OS.get_cmdline_user_args(): automated = true
	if automated: get_window().unfocusable = true
	if not automated and not save_load_blocked and not world.story.intro_seen: StoryView.open(self,"intro")
	if "--smoke" in OS.get_cmdline_user_args(): get_tree().create_timer(2).timeout.connect(get_tree().quit)

func add_button(parent: Control, id: String, text_value: String, area: Rect2, callback: Callable):
	var button = Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	if parent == palette and world.phase == "shop": button.focus_mode = Control.FOCUS_ALL
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
	if execute and id=="milk":
		for aid in selected_animals:world.act("milk",Vector2i.ZERO,aid)
	if execute and id=="equip": equipment_open=not equipment_open
	if execute and id in ["auto", "stay", "wander", "rest"]: command_selected(id, Vector2i.ZERO)
	refresh()

func command_selected(id: String, cell: Vector2i):
	world.queue_order(id,selected_animals,cell)
	notice(world.events.back().text)

func subtask_choices() -> Array:
	var available: Array = []
	if group == 0:
		available = GROUP_TOOLS[0].filter(func(id): return (world.item_count(id.trim_prefix("place_"))>0 if id.begins_with("place_") else Farm.BUILD[id].get("blueprint", "") in ([""] + world.campaign.unlocked_blueprints)))
	elif group == 1:
		var animals = world.animals.filter(func(a): return a.id in selected_animals and a.placed and world.available(a))
		available = GROUP_TOOLS[1].filter(func(id): return animals.any(func(a): return id in Farm.SPECIES[a.species].orders or (id=="milk" and a.species=="cow" and a.get("milked_day",-1)!=world.campaign.day) or (id=="equip" and selected_animals.size()==1 and Farm.ProgressData.ITEMS.keys().any(func(item):return Farm.Progression.can_equip(a,item)))))
	elif group == 2:
		available = ["keeper_rest", "resume_jobs", "coffee", "energy_drink", "keeper_book", "inventory"].filter(func(id): return buttons.has(id) and not buttons[id].disabled and buttons[id].is_visible_in_tree())
	return subtasks.choices(group, available) if group >= 0 else []

func cycle_subtool(reverse: bool = false):
	if not world.working() or menu_open: return
	if group == 1 and selected_animals.is_empty():
		var nearby = world.animals.filter(func(a): return a.placed and world.available(a) and not Farm.SPECIES[a.species].orders.is_empty())
		nearby.sort_custom(func(a,b):
			var da = Farm.distance(world.keeper.pos,a.pos)
			var db = Farm.distance(world.keeper.pos,b.pos)
			return da < db if da != db else a.id < b.id)
		if nearby.is_empty(): notice("指示できる動物がいません")
		else: choose_animal(nearby[0].id)
		return
	var choices = subtask_choices()
	if choices.is_empty(): return
	var index = choices.find(subtasks.selected[group] if group == 2 else tool)
	var next = (choices.size()-1 if reverse else 0) if index < 0 else posmod(index+(-1 if reverse else 1),choices.size())
	subtasks.selected[group] = choices[next]
	if group != 2: select_tool(choices[next],false)
	else: refresh()

func wheel_scroll_ui() -> bool:
	var hovered = get_viewport().gui_get_hovered_control()
	while is_instance_valid(hovered):
		if hovered is ScrollContainer or hovered is TextEdit or hovered is ItemList: return true
		hovered = hovered.get_parent() as Control
	return false

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
			# Commit a real next-morning world even if the app closes during the dawn animation.
			save_morning(Farm.new(world.next_campaign(),world.seed_value+1))
	for child in palette.get_children():
		palette.remove_child(child)
		child.queue_free()
	for id in buttons.keys():
		if id not in ["pause", "speed", "home", "advance", "retry", "group0", "group1", "group2", "menu_resume", "menu_retry", "menu_morning", "walk"]: buttons.erase(id)
	buttons.walk.visible = world.working() and not field_book
	UI.selected(buttons.walk, selected.get("kind")=="keeper")
	buttons.pause.visible = world.working() and not field_book
	buttons.speed.visible = world.working() and not field_book
	buttons.home.visible = world.working() and not field_book
	buttons.pause.text = "再開" if world.paused else "停止"
	buttons.pause.icon = UI.icon("next" if world.paused else "pause")
	buttons.speed.text = "早送り" if not world.rest_skip.is_empty() else "×%s" % speed
	buttons.speed.disabled = not world.rest_skip.is_empty()
	buttons.advance.visible = (world.phase == "shop" and morning_screen == "morning") or world.phase=="day" or (world.phase=="defend" and world.early_clear)
	buttons.advance.text = "支度を終える" if world.phase == "shop" else rest_button_text()
	buttons.advance.position = Vector2(548,570) if world.phase=="shop" else Vector2(1074,754)
	if world.phase=="shop" and Farm.Progression.Encounters.reached(world.campaign):
		buttons.advance.position=Vector2(376,576)
		buttons.advance.text="牧場を続ける"
		buttons.advance.visible=morning_screen=="morning" and not restart_confirm
	buttons.advance.tooltip_text = "商人を見送り、昼の牧場仕事を始めます" if world.phase == "shop" else ""
	buttons.advance.disabled=save_load_blocked
	if world.phase=="shop": MarketView.button_style(buttons.advance,true)
	else: UI.button(buttons.advance)
	buttons.retry.visible = world.phase == "result"
	buttons.group1.text = "指示"
	for i in range(2):
		buttons["group%d" % i].visible = world.working() and not field_book
		UI.selected(buttons["group%d" % i], i == group)
	if world.phase == "dawn":
		last_phase = world.phase
		return
	if world.phase == "shop" or field_book:
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
		add_button(palette,"keeper_book","図鑑",Rect2(660,704,110,36),open_book)
		buttons.keeper_book.icon=UI.icon("book_closed")
		add_button(palette,"inventory","持ち物",Rect2(778,704,120,36),preload("res://game/inventory_view.gd").open.bind(self))
		buttons.inventory.icon=UI.icon("basket")
		for i in range(2):
			var drink = ["coffee", "energy_drink"][i]
			if world.item_count(drink) > 0:
				add_button(palette, drink, ("コーヒー" if i == 0 else "活力ドリンク") + " ×%d" % world.item_count(drink), Rect2(305 + i * 175, 704, 165, 36), keeper_action.bind(drink))
				buttons[drink].icon = UI.icon("cup")
				buttons[drink].disabled = world.keeper.drinks_today >= 2 or world.keeper.state != "free"
	elif group == 1:
		var deployed_selection = world.animals.filter(func(a): return a.id in selected_animals and a.placed)
		var choices = subtask_choices()
		for i in range(choices.size()):
			var id=choices[i]
			add_button(palette,id,TOOLS[id],Rect2(16+i*126,704,118,36),select_tool.bind(id))
			var supported=deployed_selection.filter(func(a):return id in Farm.SPECIES[a.species].orders or (id=="milk" and a.species=="cow" and a.get("milked_day",-1)!=world.campaign.day) or (id=="equip" and Farm.ProgressData.ITEMS.keys().any(func(item):return Farm.Progression.can_equip(a,item)))).size()
			buttons[id].tooltip_text="対応 %d / 選択 %d。クリックで予約（誘導は行き先を指定）"%[supported,selected_animals.size()]
		if equipment_open: ProgressView.equipment_buttons(self)
	elif group == 0 and world.working():
		var choices = subtask_choices()
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
	if group == 2:
		for id in subtask_choices(): UI.selected(buttons[id], subtasks.selected[2] == id)
	if not field_book: build_context_actions()
	if debug_view and not field_book: build_debug_controls()
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
	if selected.get("kind")=="tree": return selected_trees
	if selected.get("kind")=="idol": return [world.Story.at(world)]
	if selected.get("kind") == "job": return [selected.pos]
	if not selected_resources.is_empty(): return selected_resources
	if selected.get("kind") in ["structure","floor"]: return selected_structures
	return []

func context_state() -> String:
	return str(world.trees)+str(world.story.idol)+str(world.story.investigated)+str(world.story.prayed_day)+str(selected_trees)+str(selected_resources) + str(selected) + str(selected_structures) + str(selected_structures.map(func(p): return selected_store().get(p,{}))) + str(world.jobs.map(func(j): return [j.kind, j.pos])) + str(world.materials) + str(world.wood)

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
	elif selected.get("kind")=="tree":
		rows.append(["clear_tree","道具が必要","hammer",func():pass,true,"伐採には道具が必要です（道具は未実装）"])
		if selected_trees.any(func(p):return job_reserved("clear_tree",p)): rows.append(["cancel_near","取消","cross",cancel_selected_work,false,"開拓予定を取り消す"])
	elif selected.get("kind")=="idol":
		for kind in ["inspect_idol","pray_animal","pray_gold","pray_item","repair_idol","recover_idol"]:
			if world.Story.is_prayer(kind) and not world.story.investigated: continue
			if kind=="repair_idol" and world.story.idol.hp>=world.story.idol.max_hp: continue
			if kind=="recover_idol" and world.story.idol.state!="interrupted": continue
			var why=world.Story.reason(world,kind,world.Story.at(world))
			if why=="" and world.jobs.any(func(j):return j.get("world_target")=="father-idol"): why="像の作業は予約済みです"
			rows.append([kind,StoryView.LABELS[kind],"spark",story_action.bind(kind),why!="",why if why!="" else ("牧場主が現地で3秒祈ります。1日1回、翌朝に選んだ種類の贈り物を受け取ります" if world.Story.is_prayer(kind) else "牧場主が現地で行います")])
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
	var row_width=140 if selected.get("kind")=="idol" else 112
	context_panel.size = Vector2(rows.size() * row_width + 12, 68)
	var title = Label.new()
	title.text = "黄金像" if selected.get("kind")=="idol" else ("開拓する木" if selected.get("kind")=="tree" else ("選択 %d/8" % count if count > 1 else ("落とし物" if not selected_resources.is_empty() else ("床" if selection_layer=="floor" else "建物"))))
	title.position = Vector2(9,3)
	title.add_theme_color_override("font_color",UI.INK)
	context_panel.add_child(title)
	for i in range(rows.size()):
		var row = rows[i]
		add_button(context_panel,row[0],row[1],Rect2(6+i*row_width,27,row_width-6,34),row[3])
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
	if selected.get("kind")=="tree":
		selected_trees=selected_trees.filter(func(p):return world.trees.has(p))
		if selected_trees.is_empty(): selected.clear(); refresh()
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
		if not save_morning(world):return
		var next_day = world.begin_day()
		if next_day == null:
			notice(world.story.get("migration_error","今は支度を終えられません"))
			return
		world = next_day
		reset_view()
		group = -1
		departure_started = clock
	elif world.phase == "dawn":
		morning_keeper = Vector2(world.keeper.pos)
		for a in world.animals:
			if a.species == "shiba" and a.placed: morning_dog = Vector2(a.pos)
		world = Farm.new(world.next_campaign(), world.seed_value + 1)
		save_morning(world)
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

func confirm_new_campaign(enabled: bool):
	if world.phase!="shop":return
	restart_confirm=enabled;refresh()

func new_campaign():
	if world.phase!="shop" or not restart_confirm:return
	var fresh=Farm.new({},world.seed_value+1)
	if not save_morning(fresh):return
	world=fresh
	restart_confirm=false;morning_screen="morning";group=-1;speed=1;accumulated=0
	shop_side="home";shop_level="categories";morning_keeper=Vector2(5.5,8);morning_dog=Vector2(6.5,8.5)
	reset_view();arrival_started=clock;refresh()
	if not automated:StoryView.open(self,"intro")

func save_morning(morning) -> bool:
	if not persistence_enabled:return true
	if save_load_blocked:return false
	var saved=MorningSave.write(MorningSave.capture(morning),save_path)
	var ok=saved.status=="ok"
	save_status="朝の支度を保存しました。再起動すると、この朝から再開します" if ok else "朝を保存できませんでした。空き容量などを確認し、支度を終える前に再試行してください"
	return ok

func cancel_selected_work():
	for j in world.jobs.duplicate():
		if (j.kind=="collect" and j.pos in selected_resources) or (selected.get("kind")=="tree" and j.kind=="clear_tree" and j.pos in selected_trees): world.act("cancel_job",Vector2i.ZERO,j.id)
	refresh()

func reset_view():
	field_book=false
	actor_art.clear()
	six_art.clear()
	six_revived.clear()
	subtasks.cancel()
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
	enemy_art.clear()
	work_dust_at = -1.0
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
	selected_trees.clear()
	selected_resources.clear()
	selected_structures.clear()
	group = 2
	tool = ""
	selected = {"kind": "keeper"}
	selected_animals.clear()
	refresh()

func neutral():
	selected_trees.clear()
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
	if kind=="keeper_book": open_book(); return
	if kind=="inventory": preload("res://game/inventory_view.gd").open(self); return
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
		var names = {"milk":"搾乳","place_kokeshi":"こけし","place_fossil":"化石","wall": "壁", "door":"ドア","locked_door":"施錠ドア","wood_wall":"木壁","stone_wall":"石壁","soil_tile":"土タイル","wood_tile":"木タイル","stone_tile":"石タイル", "kennel": "犬小屋", "coop": "鶏小屋", "move": "歩く", "collect": "回収", "repair": "修理", "remove": "解体", "remove_floor":"タイル解体", "repair_floor":"床修理", "gate": "ドアを開閉", "equip":"装備", "animal_order": "仲間へ指示"}
		row.text = "%s%s" % [ "› " if j.state != "pending" else "", ("待機 · " if j.state == "blocked" else "") + names.get(j.kind, StoryView.LABELS.get(j.kind,"仕事"))]
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
	var signature = str(world.keeper.pos)+str(world.manual_goal)+str(world.jobs.map(func(j):return [j.id,j.pos,j.get("targets",[])]))+str(world.structures)+str(world.animals.map(func(a):return a.pos))+str(world.floors)+str(world.trees)+str(world.story.idol)
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
	for i in range(world.jobs.size()):
		var j = world.jobs[i]
		var q = center(j.pos)
		if j.kind=="move":
			draw_line(q+Vector2(0,10),q+Vector2(0,-27),Color("e4cd9b"),3)
			draw_colored_polygon(PackedVector2Array([q+Vector2(1,-27),q+Vector2(23,-20),q+Vector2(1,-13)]),Color("91dabd"))
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

func set_speed(index: int):
	if not world.rest_skip.is_empty(): notice("時間送りを中断してから倍率を変更"); return
	if index==3 and not world.keeper.resting: notice("4倍速は休息中のみ"); return
	speed=[0.5,1.0,2.0,4.0][index]
	refresh()

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
		if j.get("cancel_requested",false):continue
		if j.pos == cell:return j.id
		if j.kind=="animal_order" and j.order=="guide" and j.targets.any(func(t):return t.dest==cell and not t.done):return j.id
	return -1

func job_title(j: Dictionary) -> String:
	if Farm.BUILD.has(j.kind):return Farm.Buildings.NAMES.get(j.kind,"建設")+"を建設"
	return {"move":"移動予定","collect":"回収予定","repair":"修理予定","remove":"解体予定","remove_floor":"床を解体","repair_floor":"床を修理","equip":"装備予定","animal_order":"仲間への指示","gate":"ドア開閉"}.get(j.kind,StoryView.LABELS.get(j.kind,"予定"))

func _input(event):
	if event is InputEventKey and not event.pressed and event.physical_keycode==KEY_SHIFT:shift_latched=false
	if story_modal!="":
		if event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE: StoryView.close(self); get_viewport().set_input_as_handled()
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed: StoryView.close(self); get_viewport().set_input_as_handled()
		# GUI buttons receive the event; every world handler is gated by the modal.
		return
	if event is InputEventMouse: pointer = event.position
	if subtasks.input(self,event):
		press_pending = false
		dragging = false
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(name_edit) and name_edit.has_focus(): return
	if (world.phase == "shop" or field_book) and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if morning_screen == "book": close_morning_screen()
			elif morning_screen == "market": market_back()
		get_viewport().set_input_as_handled()
		return
	if book_motion != "" and event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		close_morning_screen()
		get_viewport().set_input_as_handled()
		return
	if book_motion != "" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and buttons.has("close_market") and buttons.close_market.get_global_rect().has_point(event.position):
		return
	if cinematic() or book_motion != "":
		keys_down.clear()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		if (world.phase == "shop" or field_book) and morning_screen != "morning": close_morning_screen()
		else: toggle_menu()
		get_viewport().set_input_as_handled()
		return
	if menu_open: return
	if field_book: return
	if world.phase == "shop" and event is InputEventKey: return
	if event is InputEventMouseMotion:
		pointer = event.position
		if queue_drag_id >= 0:
			queue_drop_index = clampi(int((pointer.y - 94) / 35), 1 if not world.jobs.is_empty() and world.jobs[0].state not in ["pending","blocked"] else 0, maxi(0,world.jobs.size() - 1))
			get_viewport().set_input_as_handled()
		elif press_pending:
			if pointer.distance_to(press_position) >= 7: dragging = true
			if dragging:
				if group < 0: camera.position = pan_origin - (pointer - press_position) / camera.zoom
				else: update_drag_class()
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
				if dragging and group >= 0 and not pointer_over_ui(): finish_drag()
				elif dragging: pass
				elif not pointer_over_ui(): board_click(event)
				dragging = false
				get_viewport().set_input_as_handled()
				return
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			if world.phase == "shop" or wheel_scroll_ui(): return
			var before = get_canvas_transform().affine_inverse() * pointer
			camera.zoom = Vector2.ONE * clampf(camera.zoom.x * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), 0.65, 1.8)
			camera.force_update_scroll()
			camera.position += before - get_canvas_transform().affine_inverse() * pointer
			clamp_camera()
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
			if dragging or press_pending:
				if group < 0: camera.position = pan_origin
				dragging=false; press_pending=false
			else:
				var id=job_at(Vector2i(get_canvas_transform().affine_inverse()*pointer/TILE))
				if id>=0: world.act("cancel_job",Vector2i.ZERO,id); refresh()
				else: neutral()
			get_viewport().set_input_as_handled()
	if event is InputEventKey:
		if event.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D]: keys_down[event.physical_keycode] = event.pressed
		if event.physical_keycode == KEY_SHIFT:
			if not event.pressed: shift_latched=false
			elif not event.echo and not shift_latched:
				shift_latched=true
				cycle_subtool()
			get_viewport().set_input_as_handled()
			return
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
			KEY_TAB:
				if world.working():
					var next_mode=posmod(group+1,3)
					if next_mode==2: choose_walk()
					else: select_group(next_mode)
			KEY_HOME: recenter()
			KEY_F3: debug_view = not debug_view; world.debug_enabled=debug_view; refresh()
			KEY_F8: export_record()
			KEY_E: facility_action("repair")
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4:
				if world.working(): set_speed([KEY_1,KEY_2,KEY_3,KEY_4].find(event.physical_keycode) if event.physical_keycode in [KEY_1,KEY_2,KEY_3,KEY_4] else [KEY_KP_1,KEY_KP_2,KEY_KP_3,KEY_KP_4].find(event.physical_keycode))
		if event.physical_keycode in [KEY_SPACE, KEY_TAB, KEY_HOME, KEY_F3, KEY_F8, KEY_ESCAPE, KEY_1, KEY_2, KEY_3, KEY_4, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_E]:
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
	for cell in world.trees: result.append({"class":"tree","id":cell,"point":center(cell)})
	for cell in world.structures:
		if world.live_structure(cell) and selection_layer!="floor": result.append({"class":"structure","id":cell,"point":center(cell)})
	for cell in world.floors:
		if world.floors[cell].status=="ready" and (selection_layer=="floor" or not world.live_structure(cell)): result.append({"class":"floor","id":cell,"point":center(cell)})
	result = result.filter(func(c): return (group==0 and c["class"] in ["structure","floor"]) or (group==1 and c["class"]=="animal") or (group==2 and c["class"]=="resource"))
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
	elif drag_class == "tree":
		selected_trees=targets.map(func(c):return c.id)
		if not selected_trees.is_empty(): selected={"kind":"tree","pos":selected_trees[0]}
	elif drag_class == "resource":
		group = 2
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
	if story_modal!="" or field_book: return
	if menu_open or cinematic() or not world.working(): return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or pointer_over_ui(): return
	press_pending = true
	press_position = event.position
	pan_origin = camera.position
	drag_start = get_canvas_transform().affine_inverse() * pointer
	drag_class = ""
	drag_encounters.clear()
	for candidate in selection_candidates():
		if drag_start.distance_to(candidate.point) < 20:
			drag_class = candidate["class"]
			break

func board_click(event):
	var cell = Vector2i(get_canvas_transform().affine_inverse() * event.position / TILE)
	if tool in ["attack_target","charge"]:
		command_selected(tool,cell);refresh();return
	if tool.begins_with("place_"):
		if not world.act(tool,cell):notice("空き場所と持ち物を確認してください")
		refresh();return
	if Farm.BUILD.has(tool):
		if not world.act(tool,cell): notice("予定は8件まで" if world.jobs.size()>=8 else world.Buildings.reason(world,tool,cell))
		refresh(); return
	if world.trees.has(cell) or cell in world.Story.idol_cells(world):
		if not event.ctrl_pressed: selected_trees.clear()
		if world.trees.has(cell): toggle_selection(selected_trees,cell)
		selected={"kind":"tree" if world.trees.has(cell) else "idol","pos":cell}
		selected_resources.clear(); selected_structures.clear(); selected_animals.clear(); tool=""
		refresh(); return
	selected_trees.clear()
	if not event.ctrl_pressed: selected_resources.clear()
	if world.keeper.placed and keeper_hit_rect().has_point(get_canvas_transform().affine_inverse()*event.position):
		choose_walk()
		if not keeper_hint_shown:
			keeper_hint_shown = true
			notice("地面を左クリックで移動を予約")
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
		var hit=enemy_hit_rect(e).has_point(get_canvas_transform().affine_inverse()*event.position)
		if not e.done and hit:
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
		shift_latched = false
		dragging = false
		press_pending = false
		queue_drag_id = -1

func clamp_camera():
	var middle=Vector2(Farm.W,Farm.H)*TILE*0.5
	camera.position=camera.position.clamp(middle-Vector2(500,360),middle+Vector2(500,360))
	camera.force_update_scroll()

func _process(delta):
	if book_motion != "":
		var duration = 0.42 if book_motion.begins_with("turning") else 0.54
		if clock - book_started >= duration:
			if book_motion.begins_with("turning"): training_id = book_next_id
			elif book_motion == "closing":
				field_book = false
				morning_screen = "morning"
				shop_side = "home"
			book_motion = ""
			refresh()
	palette.visible = true
	for child in palette.get_children():
		child.visible = book_motion == "" or child == buttons.get("close_market")

	if not menu_open: clock += delta
	if not field_book and story_modal=="" and not world.paused and not menu_open and world.working(): visual_time += delta * (24.0 if not world.rest_skip.is_empty() else speed)
	var direction = Vector2(int(keys_down.get(KEY_D, false)) - int(keys_down.get(KEY_A, false)), int(keys_down.get(KEY_S, false)) - int(keys_down.get(KEY_W, false)))
	if not field_book and story_modal=="" and not menu_open and not cinematic() and world.phase != "shop": camera.position += direction.normalized() * delta * 420
	clamp_camera()
	if not field_book and story_modal=="" and not world.paused and not automated and world.working():
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
	queue_controls.visible=not field_book and story_modal==""
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
	if not world.working() or group < 0 or pointer_over_ui() or menu_open or field_book or story_modal!="" or cinematic() or queue_drag_id >= 0: mode_cursor = ""
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if mode_cursor == "" else Input.MOUSE_MODE_HIDDEN)
	smooth_actor("keeper", world.keeper.pos, delta)
	if not world.story.idol.is_empty(): smooth_actor("idol",world.Story.at(world),delta)
	if world.phase == "dawn" and clock - transition_at > 4.8 and not menu_open: advance()
	if world.phase == "shop" and clock - arrival_started > 0.8 and not arrival_bell:
		arrival_bell = true
		audio.cue("merchant")
	controls.visible = not cinematic() and story_modal==""
	if selected.get("kind") == "enemy" and world.enemies.any(func(e): return e.id == selected.id and (e.hp <= 0 or e.flee or e.done)):
		selected.clear()
		refresh()
	if world.working():
		buttons.advance.visible = not field_book and (world.phase=="day" or world.early_clear)
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
		elif hit.source in ["object","lock"]:
			for cell in world.structures:
				if world.structures[cell].id == hit.target:
					puff(center(cell), "lock_break" if hit.source=="lock" and world.structures[cell].get("lock_hp",0)<=0 else "hit")
			play_alert("object")
		if hit.source in ["enemy","keeper_hit","object","lock"]: enemy_reaction(hit.id,"attack")
		elif hit.source in ["animal","keeper"]: enemy_reaction(hit.target,"hit")
		if hit.source in ["animal","enemy","keeper","keeper_hit"]:
			var target=hit_effects[-1].target
			puff(center(view_positions.get(target,Vector2.ZERO)),"hurt" if hit.source in ["enemy","keeper_hit"] else "attack_hit")
	hit_effects = hit_effects.filter(func(hit): return clock - hit.at < 0.3)
	while seen_milestones < world.milestones.size():
		var event = world.milestones[seen_milestones]
		seen_milestones += 1
		var names = {"whistle": "", "auto_start": "敵の襲来に備えよ", "invasion": "！ 侵入者接近", "keeper_down": "倒れた！ 仲間に助けてもらおう", "keeper_recovered": "回復した。作業を再開できます", "restrained": "牧場主が拘束された！", "carried": "牧場主が連れ去られている！", "rescue": "牧場主を救出した！", "animal_danger": "動物のHPが危険！", "blueprint": event.get("text","設計図を手に入れた。"), "blueprint_dropped": "作り方のメモが落ちた", "early_clear": "今夜の襲撃を退けた", "dawn": "夜明け"}
		if event.kind == "order_notice": notice(event.text); continue
		if event.kind == "whistle":
			sound_wave(actor_pixel("keeper",world.keeper.pos),int(world.keeper.get("facing",1)))
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
		var skill=world.skill_log[seen_skills]
		ProgressArt.skill(self,skill)
		SixMotion.skill(self,skill)
		if skill.skill=="bark":
			var id=int(skill.actor.trim_prefix("shiba_"))
			for a in world.animals:
				if a.id==id:sound_wave(actor_pixel("a%d"%id,a.pos),int(a.get("facing",1)))
		play_alert("bark" if world.skill_log[seen_skills].skill == "bark" else "collect")
		seen_skills += 1
	update_enemy_art()
	for a in world.animals:
		ProgressArt.update(self,a,false)
		SixMotion.update(self,a,false)
	for e in world.enemies:
		if e.get("revived",false) and not six_revived.has(e.id):six_revived[e.id]=visual_time
	queue_redraw()
	hud.queue_redraw()
	overlay.queue_redraw()

func record_actor_tracks():
	record_actor("keeper",world.keeper.pos)
	if not world.story.idol.is_empty(): record_actor("idol",world.Story.at(world))
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
			if e.id==int(id.substr(1)): rate=world.Story.TOW_SPEED if world.story.idol.get("carrier",-1)==e.id and world.story.idol.state=="transporting" else (1.0 if e.carry=="keeper" else e.move_speed); break
	elif id=="keeper" and world.keeper.carrier>=0: rate=1.0
	elif id=="idol": rate=world.Story.TOW_SPEED
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
	var action={"hit":"attack_hit","build":"build_complete","collect":"item_collect","repair":"wood_chips","remove":"soil_dust","break":"stone_powder","gate":"wood_chips"}.get(kind,kind)
	if not Delivered.CLIPS.has("fx/"+action):return
	dust.append({"pos": p, "at": visual_time, "kind": action})
	if dust.size() > 32: dust.pop_front()

func sound_wave(p: Vector2, facing: int):
	puff(p+Vector2(facing*10,-8),"sound_wave_left" if facing<0 else "sound_wave")

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
		elif event.kind in Farm.BUILD:
			puff(center(Vector2i(event.pos[0],event.pos[1])),"build")
		if event.kind == "guide": react(event.animal_id, "wag", 1.5)
		refresh()
	for cell in world.structures:
		var b = world.structures[cell]
		var old = structure_views.get(b.id, "")
		if old != "" and old != b.status and b.status in ["ready", "destroyed"]:
			if b.status=="destroyed":puff(center(cell),"break")
			play_alert("build" if b.status == "ready" else "object")
		structure_views[b.id] = b.status
		if b.kind in Farm.Buildings.DOORS:
			gate_views[b.id] = move_toward(gate_views.get(b.id, 1.0 if b.open else 0.0), 1.0 if b.open else 0.0, delta * 5) if not world.paused else gate_views.get(b.id, 0.0)
	if not world.paused and not world.jobs_held and not world.jobs.is_empty() and world.jobs[0].state=="working" and visual_time-work_dust_at>=0.5:
		var job=world.jobs[0]
		if job.kind in Farm.BUILD or job.kind in ["repair","repair_floor","remove","remove_floor"]:
			puff(center(job.pos),{"wood":"wood_chips","stone":"stone_powder"}.get(job.get("resource","soil"),"soil_dust"))
			work_dust_at=visual_time
	dust = dust.filter(func(f): return visual_time - f.at < Delivered.duration("fx/"+f.kind))

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
	if b.kind not in Farm.Buildings.WALLS: draw_colored_polygon(PackedVector2Array([p + Vector2(-20, 10), p + Vector2(20, 10), p + Vector2(28, 24), p + Vector2(-12, 24)]), Color(0.12, 0.22, 0.13, 0.25))
	if b.kind in Farm.Buildings.WALLS:
		BuildingArt.wall(self,p,b,preview)

	else:
		for part in ["frame_rear","leaf","frame_front"]: BuildingArt.door_layer(self,p,b,part)

	if b.hp < b.max_hp and b.kind not in Farm.Buildings.WALLS:
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
		BuildingArt.floor_tile(self,cell)
	BuildingArt.boundaries(self)
	for cell in world.indoor:
		draw_rect(Rect2(Vector2(cell)*TILE,TILE),Color(0.22,0.35,0.45,0.22 if debug_view else 0.08))
	for p in world.natural:
		BoardArt.draw_resource(self, center(p) + Vector2(sin(visual_time * 1.3 + p.x) * (1.5 if world.natural[p] == "weed" else 0.3), 0), world.natural[p])
	for f in world.foods:
		draw_circle(center(f.pos), 10, Color("d3a762"))
		draw_circle(center(f.pos), 6, Color("70513b"))
	draw_market_world()
	for item in world.field_items:
		var q = center(item.pos) + (Vector2(7, 8) if item.kind.ends_with("_plan") else Vector2.ZERO)
		if item.kind.ends_with("_plan") and world.keeper.placed and item.pos == world.keeper.pos: q = center(item.pos) + Vector2(-25,-22)
		if item.kind.ends_with("_plan") or item.kind=="skill_scroll":
			draw_texture(Art.SCROLL,(q-Vector2(12,10)).round())
		elif item.kind in ["kokeshi","fossil"]:
			Direction.draw(self,"kokeshi.idle" if item.kind=="kokeshi" else "new.fossil",q+Vector2(0,14))
		elif item.kind == "egg":
			draw_circle(q, 7, Color("fff0c7"))
		elif item.kind == "chick":
			draw_circle(q, 8, Color("efd160"))
			draw_line(q, q + Vector2(10, 2), Color("d78d37"), 3)
		else: draw_line(q + Vector2(-5, 6), q + Vector2(6, -8), Color("eee8cf"), 5)
	for a in world.animals+world.enemies:
		if a.get("species")=="doberman" and a.has("visual_death_tick") and (world.tick-a.visual_death_tick)*world.DT<ProgressArt.duration("doberman","death"):
			Delivered.draw_clip(self,ProgressArt.clip("doberman","death",a.get("facing",1)),center(a.pos)+Vector2(0,14),(world.tick-a.visual_death_tick)*world.DT)
	for e in world.enemies:
		if six_revived.has(e.id) and visual_time-six_revived[e.id]<SixMotion.duration("dancer","revival_light"):
			SixMotion.paint(self,"dancer","revival_light",1,actor_pixel("e"+str(e.id),e.pos)+Vector2(0,14),visual_time-six_revived[e.id])
	# Brief visual ending only; no corpse collision or revived simulation actor.
	for enemy_side in [false,true]:
		for actor in (world.enemies if enemy_side else world.animals):
			var who=actor.get("archetype",actor.get("species","")) if enemy_side else actor.species
			if who not in Direction.ACTORS or actor.hp>0 or (not actor.get("done",false) if enemy_side else actor.placed):continue
			if enemy_side and actor.get("dead",false):continue
			var pose=six_art.get(SixMotion.key(actor,enemy_side),{})
			if not pose.has("death_at") or visual_time-pose.death_at>=SixMotion.duration(who,pose.action):continue
			var foot=center(pose.death_pos)+Vector2(0,14);var scale_value=HumanVisual.SCALE if who in ["maid","dancer","thief"] else 1.0
			draw_set_transform(foot*(1.0-scale_value),0,Vector2.ONE*scale_value)
			SixMotion.paint(self,who,pose.action,pose.facing,foot,visual_time-pose.death_at)
			draw_set_transform(Vector2.ZERO)
	for victim in [world.keeper]+world.animals:
		if victim.hp>0 and world.tick<victim.get("poison_until",0):Direction.draw(self,"new.poison_cloud",center(victim.pos)+Vector2(0,10),0.5)
	for thrower in world.enemies:
		if thrower.get("archetype")=="thief" and world.tick<thrower.get("poison_visual_until",0):
			var flight=clampf((world.tick-thrower.poison_fired)/2.0,0,1)
			Direction.draw(self,"new.poison_projectile" if flight<1 else "new.poison_splash",center(thrower.pos).lerp(center(thrower.poison_target),flight))
	for actor in scene_actors():
		match actor.kind:
			"tree": StoryView.tree(self,actor.data,actor.get("deep",false))
			"idol": StoryView.idol(self)
			"door_part": BuildingArt.door_layer(self,center(actor.data),world.structures[actor.data],actor.part)
			"building": draw_structure(center(actor.data),world.structures[actor.data])
			"animal": draw_animal_actor(actor.data)
			"enemy": draw_enemy_actor(actor.data)
			"keeper": draw_keeper_actor()
	for f in dust:
		Delivered.draw_clip(self,"fx/"+f.kind,f.pos,visual_time-f.at)
	draw_work_plans()
	for cell in selected_trees:
		if selected.get("kind")=="tree": draw_rect(Rect2(center(cell)-Vector2(21,21),Vector2(42,42)),Color("ffe2a3"),false,2)
	if debug_view: StoryView.debug(self)
	for cell in selected_resources: draw_rect(Rect2(center(cell)-Vector2(20,20),Vector2(40,40)),Color("ffe2a3"),false,2)
	if dragging and group>=0:
		label_on(self,get_canvas_transform().affine_inverse()*pointer+Vector2(10,-10),{"animal":"仲間","resource":"回収物","tree":"開拓","structure":"建物","floor":"床"}.get(drag_class,""),16,UI.PAPER)
	if cinematic(): return
	draw_pointer_preview()

func scene_actors() -> Array:
	var actors=[]
	var inv=get_canvas_transform().affine_inverse()
	var top=inv*Vector2.ZERO;var bottom=inv*Vector2(1280,800)
	for y in range(floori(top.y/TILE.y)-2,ceili(bottom.y/TILE.y)+3):
		for x in range(floori(top.x/TILE.x)-2,ceili(bottom.x/TILE.x)+3):
			var p=Vector2i(x,y)
			if p not in world.trees and preload("res://game/forest_pattern.gd").outer_tree(p,world.seed_value,world.W,world.H):
				actors.append({"y":StoryView.tree_foot(self,p).y,"x":p.x,"kind":"tree","data":p,"deep":true})
	for p in world.trees: actors.append({"y":StoryView.tree_foot(self,p).y,"x":p.x,"kind":"tree","data":p})
	if not world.story.idol.is_empty(): actors.append({"y":actor_pixel("idol",world.Story.at(world)).y+TILE.y+14,"x":world.Story.at(world).x,"kind":"idol"})
	for cell in world.structures:
		var b=world.structures[cell]
		if b.kind in Farm.Buildings.DOORS and b.status=="ready":
			for part in [["frame_rear",-16],["leaf",0],["frame_front",16]]:
				actors.append({"y":center(cell).y+part[1]+14,"x":cell.x,"kind":"door_part","data":cell,"part":part[0]})
		else: actors.append({"y":center(cell).y+14,"x":cell.x,"kind":"building","data":cell})
	for a in world.animals:
		if a.placed: actors.append({"y":actor_pixel("a%d"%a.id,a.pos).y+14,"x":a.pos.x,"kind":"animal","data":a})
	for e in world.enemies:
		if not e.done: actors.append({"y":actor_pixel("e%d"%e.id,e.pos).y+14,"x":e.pos.x,"kind":"enemy","data":e})
	if world.keeper.placed and world.keeper.carrier<0: actors.append({"y":keeper_pixel().y+14,"x":world.keeper.pos.x,"kind":"keeper"})
	actors.sort_custom(func(a,b): return a.y<b.y if a.y!=b.y else (a.x<b.x if a.x!=b.x else a.kind<b.kind))
	return actors

func draw_pointer_preview():
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
				elif animal.species=="hen":draw_hen(Vector2.ZERO)
				elif animal.species in Direction.ACTORS:Direction.draw(self,Direction.actor_key(animal),Vector2(0,14),0.45)
				else:Delivered.draw_clip(self,ProgressArt.clip(animal.species,"idle",animal.get("facing",1)),Vector2(0,14),0)
				art_alpha = 1.0
				draw_set_transform(Vector2.ZERO)
		elif tool.begins_with("place_"):
			valid=world.Content.can_place(world,cell);show_preview=true
			Direction.draw(self,"kokeshi.idle" if tool=="place_kokeshi" else "new.fossil",center(cell)+Vector2(0,14),0.5)
		elif tool=="charge" and selected_animal>=0:
			valid=world.walkable(cell);show_preview=true
			var origin=world.Orders.animal(world,selected_animal).pos
			var path=world.Content.line(origin,cell)
			for point in path:draw_circle(center(point),2,UI.DANGER)
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

func draw_down_stars(p: Vector2):
	for i in range(3):
		var v=p+Vector2(-12+i*12,-22+sin(visual_time*1.4+i)*2)
		draw_line(v-Vector2(3,0),v+Vector2(3,0),Color("eed49b"),2)
		draw_line(v-Vector2(0,3),v+Vector2(0,3),Color("eed49b"),2)

func draw_hud():
	if world.working() and hover_job>=0 and not pointer_over_ui():
		for i in range(world.jobs.size()):
			var j=world.jobs[i]
			if j.id!=hover_job:continue
			var p=(pointer+Vector2(18,20)).clamp(Vector2(12,54),Vector2(985,668))
			hud.draw_style_box(MarketView.panel(UI.PAPER,UI.WOOD),Rect2(p,Vector2(274,68)))
			label_on(hud,p+Vector2(12,25),"%d · %s"%[i+1,job_title(j)],17,UI.INK)
			label_on(hud,p+Vector2(12,51),"右クリック：取消"+("（着工分は一部返却）" if j.started else ""),13,UI.INK)
	if hover_job >= 0:
		for i in range(world.jobs.size()):
			if world.jobs[i].id == hover_job: hud.draw_rect(Rect2(1007,91+i*35,253,34),Color("ffe2a3"),false,2)
	hud.draw_rect(Rect2(0, 49, 1280, 703), Color(0.04, 0.07, 0.22, night_tint))
	if cinematic(): return
	if world.phase == "shop" or field_book:
		draw_shop()
		return
	if world.working() and not world.player_events.is_empty():
		var paragraphs=[];var height=16.0
		for row in world.player_events:
			var paragraph=TextParagraph.new();paragraph.add_string(row.text,FONT,13);paragraph.width=308
			paragraph.break_flags=TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE
			paragraphs.append(paragraph);height+=paragraph.get_size().y+6
		var y=723-height
		hud.draw_style_box(MarketView.panel(Color(0.12,0.19,0.15,0.72)),Rect2(932,y,332,height))
		y+=8
		for paragraph in paragraphs:
			paragraph.draw(hud.get_canvas_item(),Vector2(944,y),UI.PAPER);y+=paragraph.get_size().y+6
	if world.phase == "dawn":
		hud.draw_style_box(UI.surface(UI.PAPER), Rect2(330, 72, 620, 106))
		label_on(hud, Vector2(365, 118), "夜明け", 30, Color("485e48"))
		label_on(hud, Vector2(368, 153), "よく守ったね", 18, Color("526444"))
		var gifts=world.story.miracles.filter(func(m):return m.day==world.campaign.day+1)
		if not gifts.is_empty():label_on(hud,Vector2(380,325),"願いの贈り物："+gifts[-1].get("text","金貨 +60G"),21,UI.PAPER)
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

	if dragging and group>=0:
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
		for enemy in world.enemies:
			if not enemy.done and world.tick-enemy.born<16: draw_edge(enemy.pos,"人影 !",Color("f5d483"))
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
			label_on(hud, Vector2(92, 634), e.get("name","侵入者"), 20)
			label_on(hud, Vector2(286, 634), "Lv%d" % e.lv, 15)
			hud.draw_rect(Rect2(92, 646, 150, 9), Color("293d35"))
			hud.draw_rect(Rect2(92, 646, 150.0 * e.hp / e.max_hp, 9), Color("d2aa80"))
			draw_gauge(hud,e,Vector2(92,655))
			var status = "倒した" if e.get("dead",false) else "退散" if e.flee else (e.search_state if debug_view else "HP %d / %d" % [e.hp, e.max_hp])
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
		label_on(hud, Vector2(398, 271), "守りきった！" if world.result == "win" else {"idol_destroyed":"黄金像が壊された","idol_stolen":"黄金像が持ち去られた"}.get(world.story.defeat_reason,"牧場主が連れ去られた"), 27)
		label_on(hud, Vector2(398, 311), "評価 %d   EXP +%d   GOLD +%d" % [world.score.rating, world.score.xp, world.score.gold], 18)
	if world.working() and world.early_clear:
		label_on(hud, Vector2(935, 735), "夜明けまで自由に", 16)
	if debug_view:
		label_on(hud,Vector2(278,153),"世界 %s / 祈り%d / 放送%d"%[str(world.story.hidden),world.story.prayers.size(),world.story.news.size()],12)
		label_on(hud, Vector2(15, 125), "DEBUG ON: seed %d / tick %d  F3:OFF" % [world.seed_value, world.tick], 14)

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

func actor_pose(id: String, resting: bool, sleeping: bool, walking: bool, who: String) -> Dictionary:
	var state = actor_art.get(id,{"resting":false,"since":visual_time,"action":"idle","at":visual_time})
	if resting != state.resting:
		state.resting = resting
		state.since = visual_time
	var age = visual_time-state.since
	var action = "walk" if walking else "idle"
	if resting: action = "settle" if age<0.36 else ("sleep" if sleeping and who=="keeper" else "rest")
	elif state.action in ["settle","rest","sleep","wake"] and age<0.36: action="wake"
	if who in ["hen","cat"]:
		if walking: action="walk"
		elif fmod(visual_time+float(id.hash()%17),8)<0.52: action="peck" if who=="hen" else "stretch"
		else: action="idle"
	if action != state.action: state.action=action; state.at=visual_time
	actor_art[id]=state
	return {"action":action,"elapsed":visual_time-state.at}

func draw_animal_sprite(p: Vector2, animal: Dictionary, who: String):
	var id = "a%d" % animal.get("id",-1)
	var walking = not animal.is_empty() and Vector2(animal.pos).distance_to(view_positions.get(id,Vector2(animal.pos)))>0.025
	var resting = animal.get("state","") in ["休む","自主休養"] or animal.get("hp",1)<=0
	var pose = actor_pose(id,resting,resting,walking,who) if not animal.is_empty() else {"action":"idle","elapsed":0.0}
	Art.sprite(self,who,pose.action,int(animal.get("facing",1)),p+Vector2(0,14),pose.elapsed,art_alpha)

func draw_dog(p: Vector2, animal: Dictionary = {}):
	draw_animal_sprite(p,animal,"shiba")

func draw_hen(p: Vector2, animal: Dictionary = {}):
	draw_animal_sprite(p,animal,"hen")

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
	stamp.text+="  素材 "+str(metadata.get("asset_delivery_commit","未記録")).left(8)
	stamp.position=Vector2(480,532)
	stamp.add_theme_font_size_override("font_size",14)
	menu.add_child(stamp)
	var guide = Label.new()
	guide.text = "ホイール：ズーム　Tab：建設 / 指示 / 牧場主\nShift：操作選択　未選択でドラッグ：マップ移動　操作ボタンをドラッグ：並べ替え\n左クリック：選択・行動　右クリック：予定取消 / 他は解除 / 市場で戻る\n1：0.5倍　2：1倍　3：2倍　4：4倍（休息中）\nSpace：停止 / 再開　−：遅く　＋ / ＝ / テンキー＋：速く\n通常 0.5 / 1 / 2倍　休息中 4倍　危険時 1倍\n夜まで / 朝まで休む：別の時間送り（中断して倍率を変更）"
	guide.position=Vector2(288,580)
	guide.add_theme_font_size_override("font_size",16)
	menu.add_child(guide)
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
		shift_latched = false
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
	if shop_side == "home":
		close_morning_screen()
		return
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
	var before_gold = world.campaign.gold
	var ok = world.buy(id) if shop_side == "buy" else world.sell(id, animal_id)
	var change = world.campaign.gold - before_gold
	shop_notice = ("%sを%sしました　%s%dG（%dG → %dG）" % [MarketView.product_name({"id":id}), "購入" if shop_side=="buy" else "売却", "−" if change<0 else "＋", absi(change),before_gold,world.campaign.gold]) if ok else "取引できませんでした。所持数と在庫を確認してください。"
	if ok: play_alert("collect")
	if ok: save_morning(world)
	refresh()
func shop_rows(category: String = "") -> Array:
	if category=="": category=shop_category
	var rows = []
	var table = Farm.Shop.table()
	if shop_side == "buy":
		for row in world.shop_stock:
			if table[row.product].Category == category: rows.append({"id": row.product, "count": row.remaining, "animal_id": -1})
	elif category == "animals":
		for a in world.campaign.animals:
			if not table[a.species].Enabled: continue
			rows.append({"id": a.species, "count": 1, "animal_id": a.id, "lv": a.lv})
	else:
		for p in table.values():
			if p.Category != category or not p.Enabled: continue
			var count = world.resource_amount(p.ProductID) / p.Amount if category == "materials" else world.item_count(p.ProductID)
			if count > 0 or (category == "materials" and world.resource_amount(p.ProductID) > 0): rows.append({"id": p.ProductID, "count": count, "animal_id": -1})
	return rows

func open_market():
	morning_screen = "market"
	shop_side = "home"
	shop_level = "categories"
	refresh()

var field_book = false

func open_book():
	field_book = world.working()
	book_section="animals"
	morning_screen = "book"
	shop_side = "animals"
	training_id = -1
	book_started = clock
	book_motion = "opening"
	refresh()

func close_morning_screen():
	if morning_screen == "book":
		if book_motion == "closing": return
		book_motion = "closing"
		book_started = clock
	else:
		morning_screen = "morning"
		shop_side = "home"
	refresh()

func turn_book(direction: int):
	if book_motion != "": return
	var owned=book_records()
	if training_id<0:
		var count=maxi(1,ceili(owned.size()/8.0))
		if count<2:return
		book_next_id=-1-posmod(-training_id-1+direction,count)
	else:
		if owned.size()<2:return
		var ids=owned.map(func(a):return a.id)
		book_next_id=ids[posmod(ids.find(training_id)+direction,ids.size())]
	book_direction=direction
	book_started=clock
	book_motion="turning_next" if direction>0 else "turning_previous"
	rename_open=false
	refresh()

func build_shop():
	if morning_screen != "book":
		MarketView.build(self)
		if morning_screen=="morning":
			StoryView.morning_buttons(self)
			if save_status!="":
				var status_label=Label.new();status_label.name="MorningSaveStatus"
				status_label.position=Vector2(330,751);status_label.size=Vector2(660,44)
				status_label.text=save_status;status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				status_label.add_theme_font_size_override("font_size",16);status_label.add_theme_color_override("font_color",UI.PAPER)
				status_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;palette.add_child(status_label)
		return
	add_button(palette, "close_market", "閉じる" if field_book else "メニューへ", Rect2(1040, 116, 124, 44), close_morning_screen)
	buttons.close_market.icon = UI.icon("cross")
	add_button(palette,"book_animals","動物",Rect2(300,116,170,44),switch_book_section.bind("animals"))
	add_button(palette,"book_enemies","敵",Rect2(482,116,100,44),switch_book_section.bind("enemies"))
	UI.selected(buttons.book_animals,book_section=="animals"); UI.selected(buttons.book_enemies,book_section=="enemies")
	Journal.build(self)
	add_button(palette, "book_prev", "←", Rect2(266,676,80,36), turn_book.bind(-1))
	add_button(palette, "book_next", "→", Rect2(930,676,80,36), turn_book.bind(1))
	buttons.book_prev.disabled = book_records().size() <= (8 if training_id<0 else 1)
	buttons.book_next.disabled = buttons.book_prev.disabled

func product_title(row: Dictionary) -> String:
	if row.get("animal_id", -1) >= 0:
		for a in world.campaign.animals:
			if a.id == row.animal_id: return Farm.animal_name(a) + " Lv%d" % a.lv
	return Farm.Shop.table()[row.id].Name

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
	if morning_screen == "book":
		hud.draw_rect(Rect2(0, 0, 1280, 800), Color(0.13, 0.18, 0.17, 0.65))
		draw_book()
	else:
		MarketView.draw(self)

func train(id: int):
	shop_notice = "ひとつ成長した！" if world.train_animal(id) else "経験を積んでからまた来よう"
	save_morning(world)
	refresh()

func edit_name(id: int):
	training_id = id
	rename_open = false
	refresh()

func save_name():
	if is_instance_valid(name_edit): world.rename_animal(training_id, name_edit.text)
	save_morning(world)
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
	add_button(palette, "train_%d" % training_id, "育てる  %d EXP" % world.level_cost(training_id), Rect2(712,570,180,40), train.bind(training_id))
	buttons["train_%d" % training_id].icon = UI.icon("spark")
	for a in owned:
		if a.id == training_id:
			buttons["train_%d" % training_id].disabled = a.lv >= 5 or world.campaign.exp_pool < world.level_cost(training_id)
			if a.lv >= 5: buttons["train_%d" % training_id].text = "最大Lv"
	add_button(palette, "rename", "名前を変える", Rect2(900,570,136,40), open_name)
	if rename_open:
		name_edit = LineEdit.new()
		name_edit.position = Vector2(712,620)
		name_edit.size = Vector2(174,40)
		name_edit.max_length = 12
		name_edit.call_deferred("grab_focus")
		name_edit.add_theme_stylebox_override("normal", UI.surface(UI.PAPER))
		name_edit.add_theme_color_override("font_color", UI.INK)
		for a in owned:
			if a.id == training_id: name_edit.text = a.name
		palette.add_child(name_edit)
		add_button(palette, "save_name", "この名前にする", Rect2(896,620,140,40), save_name)

func animal_hp(a: Dictionary) -> int:
	return Farm.AnimalData.stats(a.species,a.lv).hp + (4 if "hardy" in a.get("bonus_skills",[]) else 0)

func draw_book():
	book_view.draw(hud)

func draw_book_content(canvas: CanvasItem, animal_id: int):
	Journal.draw(self,canvas,animal_id)

func book_detail(id: int):
	if book_motion!="":return
	rename_open=false
	book_next_id=id
	book_started=clock
	book_motion="turning_next" if id>=0 else "turning_previous"
	refresh()

func restart_morning():
	var morning=Farm.new(world.morning_checkpoint, world.seed_value)
	if not save_morning(morning):return
	world=morning
	reset_view()
	arrival_started = clock
	training_id = -1
	rename_open = false
	refresh()

func draw_card_icon(c: CanvasItem, kind: String, p: Vector2, scale_value: float):
	if Assets.texture(kind)!=null: Assets.portrait(c,kind,Rect2(p-Vector2(24,28)*scale_value,Vector2(48,56)*scale_value)); return
	if kind in ["doberman","bullfrog","hedgehog","collar","berry"]:
		if kind in Farm.SPECIES: ProgressView.placeholder(self,c,kind,p,scale_value); return
		c.draw_texture_rect(UI.icon("paw" if kind=="collar" else "basket"),Rect2(p-Vector2(18,18)*scale_value,Vector2(36,36)*scale_value),false); return
	if Delivered.RESOURCES.has(kind) or kind=="sell":
		# Delivered tiers have their own pixel density, not the old diagram scale.
		var size=96.0 if scale_value>=2 else (48.0 if scale_value>=1 else 24.0)
		Delivered.resource(c,"gold" if kind=="sell" else kind,p,size)
		return
	c.draw_set_transform(p, 0, Vector2.ONE * scale_value)
	if kind=="shiba":
		UI.shiba(c,Vector2(0,20),1)
	elif kind == "cat":
		Art.sprite(c,"cat","idle",1,Vector2(0,20))
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
		Art.sprite(c,"hen","idle",1,Vector2(0,16))
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
	elif kind in ["egg", "feather"]:
		if kind == "egg": c.draw_circle(Vector2.ZERO, 14, Color("f6e6b6"))
		else: c.draw_line(Vector2(-10,12), Vector2(12,-20), Color("f2dfbc"), 9)
	else: BoardArt.draw_resource(c, Vector2.ZERO, kind)
	c.draw_set_transform(Vector2.ZERO)
func draw_cat(p: Vector2, animal: Dictionary = {}):
	draw_animal_sprite(p,animal,"cat")

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
	subtasks.draw(self)
	if mode_cursor != "":
		overlay.draw_texture(UI.cursor(mode_cursor),pointer-Vector2(2,2))
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
	# The adopted cart contains its merchant. No second figure or old cargo overlay.
	SixMotion.paint(self,"merchant","cart_move" if rolling else "cart_idle",-1 if world.phase=="day" else 1,q+Vector2(20,30),clock)

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
		caption += " · " + Farm.ProgressData.ITEMS.get(a.get("equipment",{}).get("item_id",""),{}).get("name","装備なし")
		label_on(hud, Vector2(92, 678), "%d / %d" % [a.hp, a.max_hp] if Rect2(16, 609, 344, 80).has_point(pointer) else caption, 14, Color("b9c9b5"))
		draw_gauge(hud,a,Vector2(92,655))
		if selected_animals.size() > 1: label_on(hud, Vector2(301, 677), "×%d" % selected_animals.size(), 16)

func companion_box() -> StyleBox:
	return UI.surface(UI.MOSS)

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
	hud.draw_texture(Direction.ASSETS["ui.stamina_lightning"].texture,Vector2(151,596))
	label_on(hud,Vector2(180,615),"スタミナ %d/%d"%[k.stamina,k.max_stamina],13,UI.INK)
	for i in range(2):
		var y = 626 + i * 18
		hud.draw_texture_rect(UI.icon("heart" if i == 0 else "moon"), Rect2(78, y, 14, 14), false)
		hud.draw_rect(Rect2(100, y + 3, 170, 8), Color("b9b69c"))
		var ratio = float(k.hp) / k.max_hp if i == 0 else k.sleepiness / 100.0
		hud.draw_rect(Rect2(100, y + 3, 170 * ratio, 8), Color("bf7661") if i == 0 else Color("8087a7"))
		label_on(hud, Vector2(279, y + 12), "%d/%d" % [k.hp, k.max_hp] if i == 0 else "%d%%" % k.sleepiness, 13, UI.INK)
	var activity = "連れ去り" if k.carrier >= 0 else ("気絶" if k.state == "unconscious" else ("限界休息" if k.forced_rest else (("寝入り待ち" if Farm.Life.presentation(world)=="settling" else "睡眠") if k.resting else ("散歩中" if world.manual_goal != null else ("再開待ち" if world.jobs_held else ("仕事中" if not world.jobs.is_empty() else "のんびり"))))))
	if k.state=="hidden_rest":activity="隠れて療養中"
	label_on(hud, Vector2(30, 676), activity, 15, UI.INK)
	if not world.jobs.is_empty():
		var names = {"milk":"搾乳","place_kokeshi":"こけし","place_fossil":"化石","wall": "壁", "door":"ドア","locked_door":"施錠ドア","wood_wall":"木壁","stone_wall":"石壁","soil_tile":"土タイル","wood_tile":"木タイル","stone_tile":"石タイル", "collect": "回収", "move": "歩く", "equip":"装備", "animal_order": "仲間へ指示", "repair": "修理", "remove": "解体", "remove_floor":"タイル解体", "repair_floor":"床修理", "gate": "ドア", "kennel": "犬小屋", "coop": "鶏小屋"}
		var next = names.get(world.jobs[0].kind, "仕事")
		if world.jobs.size() > 1: next += " → " + names.get(world.jobs[1].kind, "仕事")
		label_on(hud, Vector2(166, 676), next, 14, UI.INK)
	hud.draw_set_transform(Vector2.ZERO)

func keeper_pixel() -> Vector2:
	if world.keeper.carrier >= 0:
		return carried_keeper_rect().get_center()
	return actor_pixel("keeper", world.keeper.pos)

func carried_keeper_rect() -> Rect2:
	var facing=enemy_art.get(world.keeper.carrier,{}).get("facing",1)
	var foot=center(view_positions.get("e%d"%world.keeper.carrier,Vector2(world.keeper.pos)))+Vector2(0,14)
	var support=foot-Vector2(16,44)+Vector2(20 if facing<0 else 12,16)
	return HumanVisual.rect(Rect2(support+Vector2(-22 if facing<0 else -26,-26),Vector2(48,32)),foot)

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
	var kinds=Farm.ProgressData.ENEMY_ROWS.keys()+["doberman"]
	for i in range(kinds.size()):
		var kind=kinds[i]
		var title="敵ドーベルマン" if kind=="doberman" else Farm.ProgressData.enemy(kind).name
		add_button(palette,"debug_enemy_"+kind,title,Rect2(16+(i%2)*148,305+(i/2)*37,140,32),select_debug_enemy.bind(kind))
		UI.selected(buttons["debug_enemy_"+kind],debug_enemy_kind==kind)
	add_button(palette,"debug_spawn_enemy","入口に出現（1体）",Rect2(16,305+ceili(kinds.size()/2.0)*37,288,34),debug_action.bind("spawn_enemy"))
	for i in range(3):
		var id=["maid","cow","bull"][i]
		add_button(palette,"debug_"+id,Farm.SPECIES[id].title+"＋",Rect2(16+i*98,345+ceili(kinds.size()/2.0)*37,94,32),debug_action.bind(id))
	buttons.debug_spawn_enemy.disabled=not world.working()
	buttons.debug_spawn_enemy.tooltip_text="昼・夜にLv1を1体。停止中は出現だけ。入口の空きマスを使用します。"

func select_debug_enemy(kind: String):
	debug_enemy_kind=kind
	refresh()

func debug_action(action: String):
	world.debug_action(action,{"enemy_kind":debug_enemy_kind} if action=="spawn_enemy" else selected)
	refresh()

func keeper_hit_rect() -> Rect2:
	if world.keeper.carrier>=0:return carried_keeper_rect().grow(3)
	var p=keeper_pixel()
	if Farm.Life.presentation(world) in ["unconscious","carried"]: return Rect2(p+Vector2(-25,-12),Vector2(50,34))
	var pose=actor_art.get("keeper",{}).duplicate()
	if world.keeper.state=="hidden_rest":pose.action="rest"
	if pose.get("action", "idle") != "idle":
		var foot=p+Vector2(0,14)
		var rect=Art.bounds("keeper",pose.action,int(world.keeper.get("facing",1)),foot,visual_time-pose.get("at",visual_time))
		return Rect2(foot+(rect.position-foot)*1.15,rect.size*1.15).grow(3)
	return Rect2(p+Vector2(-19,-39),Vector2(38,56))

func animal_hit_rect(a: Dictionary) -> Rect2:
	if a.species in Direction.ACTORS:return Direction.bounds(self,a)
	if a.species in ProgressArt.SPECIES:return ProgressArt.bounds(self,a)
	var p=actor_pixel("a%d" % a.id,a.pos)
	var pose=actor_art.get("a%d"%a.id,{})
	if a.species in ["hen","cat"] or pose.get("action","idle")!="idle":
		return Art.bounds(a.species,pose.get("action","idle"),int(a.get("facing",1)),p+Vector2(0,14),visual_time-pose.get("at",visual_time)).grow(3)
	return Rect2(p+Vector2(-17,-18),Vector2(34,37))

func enemy_hit_rect(e: Dictionary) -> Rect2:
	if e.get("archetype","") in Direction.ACTORS:return Direction.bounds(self,e,true)
	if e.get("archetype","") in ProgressArt.SPECIES:return ProgressArt.bounds(self,e,true)
	var pose=enemy_art.get(e.id,{"action":"idle","facing":1,"at":visual_time})
	var key="enemy/"+pose.action+("_left" if pose.facing<0 else "_right")
	var clip=Delivered.CLIPS[key];var frame=clip.frames[Delivered.frame_index(key,visual_time-pose.at)]
	var used=Rect2(frame.rear.get_image().get_used_rect()).merge(Rect2(frame.front.get_image().get_used_rect())) if frame is Dictionary else Rect2(frame.get_image().get_used_rect())
	var foot=actor_pixel("e%d"%e.id,e.pos)+Vector2(0,14)
	return HumanVisual.rect(Rect2(foot-clip.anchor+used.position,used.size),foot).grow(3)

func enemy_reaction(id: int, action: String):
	if not enemy_art.has(id):enemy_art[id]={"action":"idle","facing":1,"at":visual_time}
	enemy_art[id].reaction=action
	enemy_art[id].reaction_at=visual_time
	if enemy_art[id].action==action:enemy_art[id].at=visual_time

func update_enemy_art():
	for e in world.enemies:
		if e.get("archetype","") in Direction.ACTORS:
			SixMotion.update(self,e,true)
			continue
		if e.get("archetype","kidnapper") in ProgressArt.SPECIES:
			ProgressArt.update(self,e,true)
			continue
		var previous=enemy_art.get(e.id,{"action":"idle","facing":1,"at":visual_time,"cell":e.pos,"sight":0,"searching":false})
		var dx=e.pos.x-previous.get("cell",e.pos).x
		if dx!=0:previous.facing=1 if dx>0 else -1
		elif e.can_see_keeper and world.keeper.carrier!=e.id and not e.flee and world.keeper.pos.x!=e.pos.x:previous.facing=1 if world.keeper.pos.x>e.pos.x else -1
		previous.cell=e.pos
		var walking=Vector2(e.pos).distance_to(view_positions.get("e%d"%e.id,Vector2(e.pos)))>0.025
		previous.walking=walking
		var searching=not walking and e.carry=="" and not e.flee and not e.can_see_keeper
		if e.sight_reaction_until>previous.get("sight",0) and e.sight_reaction=="!" and not previous.has("reaction"):
			previous.reaction="discovery";previous.reaction_at=visual_time
		elif searching and not previous.get("searching",false) and not previous.has("reaction"):
			previous.reaction="search";previous.reaction_at=visual_time
		previous.sight=e.sight_reaction_until
		previous.searching=searching
		var action="walk" if walking else "idle"
		if previous.has("reaction"):
			if visual_time-previous.reaction_at<Delivered.duration("enemy/"+previous.reaction+"_right"):action=previous.reaction
			else:previous.erase("reaction")
		if e.flee:action="retreat" if walking else "idle"
		if e.carry=="keeper":action="carry_walk" if walking else "carry_idle"
		if action!=previous.action:
			previous.action=action
			previous.at=previous.reaction_at if action==previous.get("reaction","") else visual_time
		enemy_art[e.id]=previous

func draw_enemy_actor(e: Dictionary):
	if e.done or not world.working(): return
	if e.get("dead",false):
		var foot=center(e.pos)+Vector2(0,14)
		var who=e.get("archetype","kidnapper");var facing=e.get("facing",1)
		var elapsed=(world.tick-e.corpse_started_tick)*world.DT
		var scale_value=1.0 if who=="doberman" else HumanVisual.SCALE
		if who in ["maid","dancer","thief","doberman"]:
			draw_set_transform(foot*(1-scale_value),0,Vector2.ONE*scale_value)
			if who=="doberman":Delivered.draw_clip(self,ProgressArt.clip(who,"death",facing),foot,elapsed)
			else:SixMotion.paint(self,who,"death" if who=="maid" else "downed",facing,foot,elapsed)
		else:
			draw_set_transform(foot,PI/2,Vector2.ONE*scale_value)
			if who=="kidnapper":Delivered.draw_clip(self,"enemy/hit_left" if facing<0 else "enemy/hit_right",Vector2.ZERO,99)
			else:Delivered.draw_clip(self,ProgressArt.clip(who,"hurt",facing),Vector2.ZERO,99)
		draw_set_transform(Vector2.ZERO)
		return
	var p = actor_pixel("e%d" % e.id, e.pos)
	draw_ready(e,p)
	var pose=enemy_art.get(e.id,{"action":"idle","facing":1,"at":visual_time})
	var foot=p+Vector2(0,14)
	ProgressArt.tongue_layer(self,e,false)
	var human_scale=HumanVisual.SCALE if e.get("type_tag","Human")=="Human" else 1.0
	draw_set_transform(foot*(1.0-human_scale),0,Vector2.ONE*human_scale)
	if e.get("archetype","kidnapper")!="kidnapper":
		if e.archetype in Direction.ACTORS:SixMotion.draw(self,self,e,foot,true)
		else:ProgressArt.draw(self,self,e,foot,true)

	elif e.carry=="keeper":
		Delivered.carry(self,"carry_walk" if pose.get("walking",false) else "carry_idle",pose.facing,foot,visual_time-pose.at,human_scale)
	else:
		Delivered.draw_clip(self,"enemy/"+pose.action+("_left" if pose.facing<0 else "_right"),foot,visual_time-pose.at)
	draw_set_transform(Vector2.ZERO)
	ProgressArt.tongue_layer(self,e,true)
	if e.hp<=0: draw_down_stars(p)
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
	elif not e.flee and e.carry == "" and e.get("archetype","kidnapper")=="kidnapper":
		draw_circle(p + Vector2(0, -32), 4, Color("8bd2c5"))
		draw_line(p + Vector2(-6, -24), p + Vector2(6, -24), Color("8bd2c5"), 3)
	if debug_view: label_on(self, p + Vector2(20, 0), e.state, 12)
	if e.hp > 0 and not e.flee and world.tick < e.sight_reaction_until: label_on(self, p + Vector2(15, -30), e.sight_reaction, 26, Color("ffe0a0"))
	elif e.hp > 0 and not e.flee and e.state == "迷う": label_on(self, p + Vector2(15, -23), "?", 16, Color("c8cfb4"))
	if selected.get("kind") == "enemy" and selected.id == e.id:
		draw_rect(enemy_hit_rect(e), Color("e6c998"), false, 2)


func draw_keeper_actor():
	var p = actor_pixel("keeper", world.keeper.pos)
	var walking = Farm.Life.able(world) and Vector2(world.keeper.pos).distance_to(view_positions.get("keeper",Vector2(world.keeper.pos)))>0.025
	if world.keeper.carrier>=0:return # Composited once between the carrier rear/front layers.
	if Farm.Life.presentation(world) == "unconscious":
		draw_set_transform(p + Vector2(0, 12), -PI * 0.5)
		p = Vector2.ZERO
	elif Farm.Life.presentation(world) in ["tired","exhausted"]:
		draw_set_transform(p+Vector2(0,4),0.16)
		p = Vector2.ZERO
	var pose = actor_pose("keeper",world.keeper.resting,Farm.Life.presentation(world)=="sleeping",walking,"keeper")
	if world.keeper.state=="hidden_rest": pose.action="rest"
	Art.sprite(self,"keeper",pose.action,int(world.keeper.get("facing",1)),p+Vector2(0,14),pose.elapsed,1.0,1.15)

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
		if world.keeper.state == "unconscious": draw_down_stars(owner_pixel)
		elif world.keeper.state=="hidden_rest":
			draw_rect(Rect2(owner_pixel+Vector2(-24,6),Vector2(48,13)),Color(0.24,0.35,0.25,0.65))
			label_on(self,owner_pixel+Vector2(-35,-22),"隠れて療養",12,Color("d9dfc3"))
		if world.tick < world.keeper.hurt_until or selected.get("kind") == "keeper":
			draw_rect(Rect2(owner_pixel + Vector2(-17, -37), Vector2(34, 4)), Color("684b46"))
			draw_rect(Rect2(owner_pixel + Vector2(-17, -37), Vector2(34 * float(world.keeper.hp) / world.keeper.max_hp, 4)), Color("d68b74"))


func draw_animal_actor(a: Dictionary):
	if not a.placed: return
	var p = actor_pixel("a%d" % a.id, a.pos)
	draw_ready(a,p)
	draw_circle(p + Vector2(0, 13), 18, Color(0.1, 0.2, 0.13, 0.25))
	if a.species == "shiba": draw_dog(p, a)
	elif a.species == "cat": draw_cat(p,a)
	elif a.species=="hen": draw_hen(p,a)
	elif a.species in Direction.ACTORS:
		var foot=p+Vector2(0,14)
		var scale_value=HumanVisual.SCALE if a.get("category")=="human" else 1.0
		draw_set_transform(foot*(1.0-scale_value),0,Vector2.ONE*scale_value)
		Direction.actor(self,self,a,foot)
		draw_set_transform(Vector2.ZERO)
	else: ProgressArt.draw(self,self,a,p+Vector2(0,14))
	if a.get("abductor",-1)>=0: label_on(self,p+Vector2(-20,30),"連れ去り中",12,UI.DANGER)
	if world.tick<a.get("spines_until",0): label_on(self,p+Vector2(15,-15),"棘",14,UI.GOLD)
	var in_combat = world.enemies.any(func(e): return not e.done and not e.flee and Farm.distance(a.pos, e.pos) <= 1)
	if a.hp <= a.max_hp * 0.5 or in_combat:
		var danger = a.hp <= a.max_hp * Farm.Rules.LOW_HP_FRACTION
		var color = Color("f38c73") if danger else Color("efcc7f")
		draw_rect(Rect2(p + Vector2(-20, 23), Vector2(40, 5)), Color("3e4534"))
		draw_rect(Rect2(p + Vector2(-20, 23), Vector2(40.0 * a.hp / a.max_hp, 5)), color)
		if danger:
			color.a = 0.65 + 0.25 * sin(clock * 4)
			label_on(self, p + Vector2(-4, -29), "!", 23, color)
	if a.hp <= 0: draw_down_stars(p)
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


func wall_links(cell: Vector2i) -> Dictionary:
	var result={}
	for d in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
		result[d]=Farm.Buildings.enclosure(world.structures.get(cell+d,{}))
	return result


func story_action(kind: String):
	var count=0
	for p in context_targets().duplicate():
		if world.act(kind,p): count+=1
	notice("%d件予約"%count if count>0 else world.events.back().text)
	refresh()

func book_records() -> Array:
	if book_section=="enemies":return ProgressView.ENEMY_ORDER.map(func(id):return {"id":ProgressView.ENEMY_ORDER.find(id)})
	if not field_book:return world.campaign.animals
	return world.campaign.animals.map(func(owned):
		var row=owned.duplicate(true)
		var live=world.Orders.animal(world,owned.id)
		for key in ["hp","equipment","ultimate_gauge","ultimate_gauge_max","unavailable_through_day"]:
			if live.has(key):row[key]=live[key]
		return row)

func switch_book_section(section: String):
	if book_motion!="" or rename_open: return
	book_section=section
	training_id=-1
	book_next_id=training_id; refresh()

func reserve_equipment(animal_id: int,item_id: String):
	notice("装備を予約しました" if Farm.Progression.equip_job(world,animal_id,item_id) else "今は装備を予約できません")
	equipment_open=false; refresh()

func draw_ready(a: Dictionary,p: Vector2):
	if a.get("hp",0)<=0 or not Farm.Combat.ready(a):return
	var q=p+Vector2(23,-32)
	draw_texture(Direction.ASSETS["ui.ready_stars"].texture,q-Vector2(12,12))

func draw_gauge(c: CanvasItem,a: Dictionary,p: Vector2):
	label_on(c,p+Vector2(0,12),"READY" if Farm.Combat.ready(a) else "技",12,UI.PAPER)
	c.draw_texture_rect(Direction.ASSETS["ui.ultimate_frame"].texture,Rect2(p-Vector2(18,0),Vector2(22,22)),false)
	c.draw_rect(Rect2(p+Vector2(50,7),Vector2(110,5)),Color("293d35"))
	c.draw_rect(Rect2(p+Vector2(50,7),Vector2(110*a.get("ultimate_gauge",0.0)/a.get("ultimate_gauge_max",100.0),5)),UI.GOLD)
	label_on(c,p+Vector2(169,12),"%d/%d"%[a.get("ultimate_gauge",0),a.get("ultimate_gauge_max",100)],11,UI.PAPER)
