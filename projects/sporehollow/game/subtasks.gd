extends RefCounted
# UI order and selected operation are independent of the world's job queue.
var order = {0: [], 1: [], 2: []}
var selected = {0: "", 1: "", 2: ""}
var pressed = ""
var origin = Vector2.ZERO
var dragging = false
var mode = -1
var insertion = -1
var slots: Array = []
var area = Rect2()
var label = ""

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://ui-settings.cfg") != OK: return
	for key in order:
		var saved = config.get_value("subtasks", str(key), [])
		if saved is Array:
			for id in saved:
				if id is String and id not in order[key]: order[key].append(id)

func choices(key: int, available: Array) -> Array:
	for id in available:
		if id not in order[key]: order[key].append(id)
	return order[key].filter(func(id): return id in available)

func save_settings():
	var config = ConfigFile.new()
	for key in order: config.set_value("subtasks", str(key), order[key])
	config.save("user://ui-settings.cfg")

func cancel():
	pressed = ""
	dragging = false
	slots.clear()
	insertion = -1

func input(game, event) -> bool:
	if pressed != "" and ((event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT)):
		cancel()
		game.refresh()
		return true
	if game.menu_open or game.field_book or game.story_modal!="" or not game.world.working(): return false
	if pressed != "" and event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]: return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for id in game.subtask_choices():
				if not game.buttons.has(id): continue
				var button = game.buttons[id]
				if button.disabled or not button.is_visible_in_tree() or not button.get_global_rect().has_point(event.position): continue
				pressed = id
				label = button.text
				origin = event.position
				mode = game.group
				slots.clear()
				for other in game.subtask_choices():
					if game.buttons.has(other): slots.append({"id":other, "rect":game.buttons[other].get_global_rect()})
				area = slots[0].rect
				for slot in slots: area = area.merge(slot.rect)
				return true
		elif pressed != "":
			var id = pressed
			var execute = not dragging and game.buttons.has(id) and game.buttons[id].get_global_rect().has_point(event.position)
			if dragging and game.group == mode and area.grow(12).has_point(event.position) and insertion >= 0:
				var visible_ids = slots.map(func(slot): return slot.id)
				visible_ids.erase(id)
				visible_ids.insert(mini(insertion,visible_ids.size()),id)
				# Replace only visible slots; temporarily unavailable species commands retain their positions.
				var n = 0
				for i in range(order[mode].size()):
					if order[mode][i] in visible_ids:
						order[mode][i] = visible_ids[n]
						n += 1
				save_settings()
			cancel()
			if execute:
				selected[game.group] = id
				if game.group == 2: game.keeper_action(id)
				else: game.select_tool(id)
			else: game.refresh()
			return true
	if event is InputEventMouseMotion and pressed != "":
		if mode != game.group: cancel(); return true
		if event.position.distance_to(origin) >= 7: dragging = true
		if dragging:
			var best = INF
			for i in range(slots.size()):
				var distance = slots[i].rect.get_center().distance_squared_to(event.position)
				if distance < best: best = distance; insertion = i
		return true
	return false

func draw(game):
	if not dragging: return
	for slot in slots:
		if not game.buttons.has(slot.id): continue
		var button = game.buttons[slot.id]
		button.modulate.a = 0.18 if slot.id == pressed else 1.0
		var offset = Vector2.ZERO
		if insertion >= 0 and slot.id != pressed and slots.find(slot) >= insertion: offset.x = 5
		button.position = slot.rect.position + offset
	if insertion >= 0 and area.grow(12).has_point(game.pointer):
		var rect = slots[insertion].rect
		game.overlay.draw_line(rect.position-Vector2(4,2),rect.position+Vector2(-4,rect.size.y+2),Color("ba704e"),4)
	var held=slots.filter(func(slot):return slot.id==pressed)
	if held.is_empty(): return
	var floating = Rect2(game.pointer-Vector2(40,22),held[0].rect.size*1.04)
	game.overlay.draw_style_box(game.UI.surface(Color(0.12,0.10,0.07,0.28)),Rect2(floating.position+Vector2(4,7),floating.size))
	game.overlay.draw_style_box(game.UI.surface(Color("f1e2ba")),floating)
	game.label_on(game.overlay,floating.position+Vector2(10,26),label,16,game.UI.INK)
