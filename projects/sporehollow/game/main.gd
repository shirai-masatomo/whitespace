extends Node2D
const Farm = preload("res://game/world.gd")
const FONT = preload("res://assets/fonts/ui_font.tres")
const ORIGIN = Vector2(28, 174)
const TILE = 32.0
var world = Farm.new()
var tool = "whistle"
var paused = false
var speed = 1
var accumulated = 0.0
var clock = 0.0
var automated = false
var view_positions: Dictionary = {}
var buttons: Dictionary = {}
var message = "最初の仲間は柴犬 Lv1。柵の内側をクリックして見張り位置を決めよう。"
var last_phase = ""

func _ready():
	var theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 17
	var controls = Control.new()
	controls.theme = theme
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(controls)
	for data in [["whistle", "1  ホイッスル  /  指示力 2", 342], ["feed", "2  餌を置く  /  指示力 3", 387], ["gate", "3  門の開閉  /  指示力 1", 432]]:
		add_button(controls, data[0], data[1], Rect2(860, data[2], 390, 39), select_tool.bind(data[0]))
	add_button(controls, "advance", "朝をはじめる", Rect2(860, 585, 390, 46), advance)
	add_button(controls, "pause", "一時停止", Rect2(860, 640, 188, 38), toggle_pause)
	add_button(controls, "speed", "速度 ×1", Rect2(1062, 640, 188, 38), toggle_speed)
	add_button(controls, "retry", "この日の最初から", Rect2(860, 689, 188, 38), retry_stage)
	add_button(controls, "export", "観察JSON", Rect2(1062, 689, 188, 38), export_record)
	var shop = [["hen", "鶏を迎える  30G"], ["feed_buy", "餌 ×3  8G"], ["shelter", "休憩小屋  28G"], ["fence", "補強門  24G"], ["sell_egg", "卵 → 9G"], ["cook_egg", "卵 → 餌 ×2"]]
	for i in range(shop.size()):
		add_button(controls, shop[i][0], shop[i][1], Rect2(860 + (i % 2) * 201, 380 + (i / 2) * 51, 189, 42), purchase.bind(shop[i][0]))
	refresh_buttons()
	if "--automated" in OS.get_cmdline_user_args():
		automated = true
		get_window().unfocusable = true
	if "--smoke" in OS.get_cmdline_user_args():
		get_tree().create_timer(2.0).timeout.connect(get_tree().quit)

func add_button(parent: Control, id: String, text_value: String, rect: Rect2, callback: Callable):
	var b = Button.new()
	b.text = text_value
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color("304a43")
	normal.border_color = Color("607764")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(7)
	b.add_theme_stylebox_override("normal", normal)
	var hover = normal.duplicate()
	hover.bg_color = Color("496652")
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.pressed.connect(callback)
	parent.add_child(b)
	buttons[id] = b

func select_tool(value: String):
	tool = value
	message = {"whistle": "左クリック：柴犬に見張り場所を知らせる。近くの敵への反応は犬に任せよう。", "feed": "左クリック：餌を置く。疲れた柴犬は餌へ向かうため、置くタイミングに注意。", "gate": "金色の門をクリック：開閉する。閉めると柴犬も通れず、泥棒は門を壊します。"}[value]
	refresh_buttons()

func advance():
	if world.phase == "prepare":
		world.act("start")
		message = "門は上下の2か所。侵入を見つけたら笛で知らせよう。"
	elif world.result == "win" and world.stage == 1:
		world = Farm.new(world.next_campaign(), world.seed_value + 1)
		view_positions.clear()
		paused = false
		message = "2日目。鶏は落ち着くと卵を産みます。巣へ来る泥棒にも注意。"
	elif world.result == "win" and world.stage == 2:
		world = Farm.new()
		view_positions.clear()
		message = "別の育て方・買い方を試そう。最初は柴犬1匹です。"
	refresh_buttons()

func toggle_pause():
	paused = not paused
	refresh_buttons()

func toggle_speed():
	speed = 2 if speed == 1 else 1
	refresh_buttons()

func retry_stage():
	world = Farm.new(world.checkpoint, world.seed_value)
	view_positions.clear()
	paused = false
	accumulated = 0
	message = "この日の開始状態へ戻しました。配置や介入を変えて試せます。"
	refresh_buttons()

func purchase(id: String):
	var item = "feed" if id == "feed_buy" else id
	message = "購入・交換しました。次の日へ持ち越します。" if world.buy(item) else "Gold・卵が足りないか、すでに所有しています。"
	refresh_buttons()

func export_record():
	DirAccess.make_dir_recursive_absolute("user://observations")
	var file = FileAccess.open("user://observations/latest.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(world.observation(), "  "))
		message = "観察JSONを保存： %s" % ProjectSettings.globalize_path("user://observations/latest.json")

func refresh_buttons():
	var shop = world.result == "win"
	for id in ["hen", "feed_buy", "shelter", "fence", "sell_egg", "cook_egg"]:
		buttons[id].visible = shop
	for id in ["whistle", "feed", "gate"]:
		buttons[id].visible = not shop
		buttons[id].modulate = Color("ffe2a0") if tool == id else Color.WHITE
		buttons[id].disabled = world.phase != "defend"
	buttons.advance.disabled = world.result == "loss"
	buttons.advance.text = "朝をはじめる" if world.phase == "prepare" else ("Stage 2 へ進む" if shop and world.stage == 1 else ("試作完了 / 別の育て方へ" if shop else "防衛中"))
	if world.phase == "defend": buttons.advance.disabled = true
	buttons.pause.disabled = world.phase != "defend"
	buttons.pause.text = "再開" if paused else "一時停止"
	buttons.speed.text = "速度 ×%d" % speed
	last_phase = world.phase

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: select_tool("whistle")
			KEY_2: select_tool("feed")
			KEY_3: select_tool("gate")
			KEY_SPACE: toggle_pause()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p = Vector2i((event.position - ORIGIN) / TILE)
		if Rect2(ORIGIN, Vector2(Farm.W, Farm.H) * TILE).has_point(event.position):
			var accepted = world.act("place" if world.phase == "prepare" else tool, p)
			if not accepted:
				message = "その操作は使えません。指示力・餌・門の状態を確認してください。"

func _process(delta):
	clock += delta
	if not paused and not automated:
		accumulated += minf(delta, 0.1) * speed
		while accumulated >= Farm.DT:
			world.step()
			accumulated -= Farm.DT
	if last_phase != world.phase: refresh_buttons()
	for a in world.animals:
		var key = "a%d" % a.id
		view_positions[key] = Vector2(a.pos) if not view_positions.has(key) else view_positions[key].lerp(Vector2(a.pos), minf(delta * 14, 1))
	for e in world.enemies:
		var key = "e%d" % e.id
		view_positions[key] = Vector2(e.pos) if not view_positions.has(key) else view_positions[key].lerp(Vector2(e.pos), minf(delta * 14, 1))
	queue_redraw()

func label_at(p: Vector2, text_value: String, size: int = 18, color: Color = Color("f3ead1")):
	draw_string(FONT, p, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func rect(p: Vector2, size: Vector2, color: String):
	draw_rect(Rect2(p, size), Color(color))

func center(p: Vector2) -> Vector2:
	return ORIGIN + (p + Vector2.ONE * 0.5) * TILE

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
	draw_arc(p + Vector2(-15, -8), 8, 0.1, 5.4, 9, Color("f2d3a4"), 5)

func draw_hen(p: Vector2):
	draw_circle(p, 12, Color("f4ebcf"))
	rect(p + Vector2(3, -13), Vector2(12, 14), "fff4d8")
	rect(p + Vector2(5, -18), Vector2(8, 5), "c45d4d")
	rect(p + Vector2(15, -7), Vector2(5, 4), "edb65a")
	rect(p + Vector2(11, -10), Vector2(2, 2), "243d36")
	rect(p + Vector2(-6, 11), Vector2(3, 6), "d69a4e")
	rect(p + Vector2(4, 11), Vector2(3, 6), "d69a4e")

func _draw():
	rect(Vector2.ZERO, Vector2(1280, 800), "192e2b")
	label_at(Vector2(30, 35), "WHITESPACE  /  SMALL FARM STORIES", 13, Color("9bb9a1"))
	label_at(Vector2(28, 77), "ホイッスル牧場", 32)
	label_at(Vector2(315, 76), "育てる。まかせる。ちょっと手を貸す。", 17, Color("b7ccb4"))
	label_at(Vector2(861, 45), "DAY %02d   /   柴犬と、ちいさな牧場" % world.stage, 18)
	label_at(Vector2(861, 77), "Gold %d    餌 %d    卵 %d" % [world.campaign.gold, world.campaign.feed, world.eggs if world.phase == "defend" else world.campaign.eggs], 20, Color("f1cd85"))
	rect(Vector2(28, 98), Vector2(800, 55), "263f37")
	var phase_name = {"prepare": "準備：柴犬を配置", "defend": "防衛中" if not paused else "一時停止", "result": "守りきった！" if world.result == "win" else "今日はうまくいかなかった"}[world.phase]
	label_at(Vector2(43, 133), "%s     持出 %d / 2     追返 %d" % [phase_name, world.metrics.stolen, world.metrics.repelled], 20)
	label_at(Vector2(674, 133), "%3.0f 秒" % (world.tick * Farm.DT), 19)
	for y in range(Farm.H):
		for x in range(Farm.W):
			var q = Vector2i(x, y)
			var p = ORIGIN + Vector2(q) * TILE
			var border = not world.inside(q)
			var col = "345447" if border else ("668956" if x > 12 else "52744a")
			if (y == 5 or y == 12) and not border: col = "b19867"
			rect(p, Vector2(TILE, TILE), col)
			if not border and y not in [5, 12] and (x * 7 + y * 3) % 5 == 0:
				rect(p + Vector2(7, 19), Vector2(2, 6), "92a86a")
				rect(p + Vector2(12, 21), Vector2(2, 4), "809e63")
			if world.is_fence(q):
				rect(p + Vector2(10, 0), Vector2(12, TILE), "66513c")
				rect(p + Vector2(7, 5), Vector2(18, 5), "c4a378")
				rect(p + Vector2(7, 23), Vector2(18, 4), "c4a378")
	for g in range(2):
		var p = center(Farm.GATES[g])
		if world.gate_hp[g] <= 0:
			draw_line(p - Vector2(10, 9), p + Vector2(13, 10), Color("806145"), 6)
		else:
			draw_line(p + Vector2(-12, -14), p + Vector2(12, -14) if world.gate_open[g] else p + Vector2(-12, 14), Color("f5cf80"), 7)
		label_at(p + Vector2(-20, -23), "破損" if world.gate_hp[g] <= 0 else ("開" if world.gate_open[g] else "閉"), 14, Color("fff0ba"))
	var s = center(world.store)
	rect(s + Vector2(-26, -24), Vector2(53, 46), "765d43")
	rect(s + Vector2(-31, -30), Vector2(64, 12), "c47b52")
	for i in range(world.supplies):
		draw_circle(s + Vector2(-17 + i * 11, 6), 6, Color("e7c987"))
	label_at(s + Vector2(-27, -38), "飼料庫", 15)
	var n = center(world.nest)
	draw_ellipse_patch(n, Color("947448"))
	for i in range(mini(world.eggs, 8)):
		draw_circle(n + Vector2((i % 4) * 7 - 10, (i / 4) * 7 - 3), 4, Color("fff0c9"))
	label_at(n + Vector2(-24, 33), "卵の巣", 14)
	if world.campaign.shelter:
		var hut = center(Vector2(17, 3))
		rect(hut - Vector2(22, 12), Vector2(44, 30), "9c7857")
		draw_colored_polygon(PackedVector2Array([hut + Vector2(-29, -12), hut + Vector2(0, -31), hut + Vector2(29, -12)]), Color("d08c64"))
		label_at(hut + Vector2(-25, 39), "休憩小屋", 14)
	for f in world.foods:
		var p = center(f.pos)
		draw_circle(p, 13, Color("e7b968"))
		draw_circle(p, 9, Color("75503c"))
		label_at(p + Vector2(-8, 27), "餌", 14)
	for e in world.enemies:
		if e.done: continue
		var p = center(view_positions.get("e%d" % e.id, Vector2(e.pos)))
		rect(p + Vector2(-10, -6), Vector2(21, 22), "817393" if not e.flee else "929388")
		draw_circle(p + Vector2(0, -10), 10, Color("d2b396"))
		rect(p + Vector2(-12, -18), Vector2(24, 8), "454453")
		rect(p + Vector2(-9, -11), Vector2(18, 5), "474954")
		rect(p + Vector2(-6, -10), Vector2(3, 2), "fff3ce")
		rect(p + Vector2(4, -10), Vector2(3, 2), "fff3ce")
		if e.carry != "": draw_circle(p + Vector2(14, 7), 8, Color("e5ce8d"))
		label_at(p + Vector2(-18, -27), "退散！" if e.flee else ("斥候" if e.role == "scout" else "泥棒"), 13)
	for a in world.animals:
		var p = center(view_positions.get("a%d" % a.id, Vector2(a.pos)))
		if world.phase == "prepare" and a.species == "shiba":
			draw_arc(p, 3 * TILE, 0, TAU, 40, Color(1, 0.9, 0.65, 0.45), 2)
		draw_circle(p + Vector2(0, 13), 16, Color(0.1, 0.2, 0.13, 0.25))
		if a.species == "shiba": draw_dog(p)
		else: draw_hen(p)
		label_at(p + Vector2(-25, -29), "%s Lv%d" % ["柴犬" if a.species == "shiba" else "鶏", a.lv], 14)
		if a.species == "shiba":
			rect(p + Vector2(-17, 22), Vector2(34, 4), "35523f")
			rect(p + Vector2(-17, 22), Vector2(a.stamina * 0.34, 4), "efd187")
			if a.order_until > world.tick:
				draw_arc(center(a.order), 17 + sin(clock * 5) * 2, 0, TAU, 24, Color("fff0bd"), 2)
	label_at(Vector2(40, 750), message.left(70), 15, Color("decba8"))
	label_at(Vector2(40, 780), "左クリックで介入 / 1 笛  2 餌  3 門 / Space 一時停止     ※ プレイヤーの直接攻撃はありません", 14, Color("9db69b"))
	draw_sidebar()

func draw_ellipse_patch(p: Vector2, color: Color):
	draw_set_transform(p, 0, Vector2(1.7, 0.7))
	draw_circle(Vector2.ZERO, 17, color)
	draw_set_transform(Vector2.ZERO)

func draw_sidebar():
	rect(Vector2(847, 98), Vector2(417, 661), "223b35")
	label_at(Vector2(868, 134), "THE CARETAKER'S NOTE", 13, Color("a6be9f"))
	var dog = world.animals[0]
	if world.result == "":
		label_at(Vector2(868, 177), "柴犬 Lv%d  /  %s" % [dog.lv, dog.state], 22)
		label_at(Vector2(868, 212), "元気 %d%%   /   指示力 %d / 10" % [dog.stamina, world.command_power], 19)
		rect(Vector2(868, 229), Vector2(364, 7), "142c27")
		rect(Vector2(868, 229), Vector2(world.command_power * 36.4, 7), "d9ca8a")
		label_at(Vector2(868, 272), "笛は場所を伝える。戦いは犬にまかせる。", 16)
		label_at(Vector2(868, 300), "疲れたら餌へ。門を閉めると犬も通れない。", 16)
		label_at(Vector2(868, 328), "畜産物・飼料を2個持ち出されると失敗。", 15, Color("c4bc9c"))
	else:
		label_at(Vector2(868, 178), "防衛成功 / 購入と育成" if world.result == "win" else "防衛失敗 / もう一度", 24)
		label_at(Vector2(868, 214), "評価 %d 点   EXP +%d   Gold +%d" % [world.score.rating, world.score.xp, world.score.gold], 18)
		label_at(Vector2(868, 248), "追返 %d / 持出 %d / 門被害 %d" % [world.metrics.repelled, world.metrics.stolen, world.metrics.gate_damage], 17)
		label_at(Vector2(868, 280), "元気 %d%%  /  指示力使用 %.0f" % [world.score.condition, world.metrics.commands], 17)
		var owned = world.campaign.animals[0]
		label_at(Vector2(868, 314), "柴犬 Lv%d   EXP %d / %d" % [owned.lv, owned.xp, owned.lv * 20], 20, Color("f5d395"))
		label_at(Vector2(868, 350), "鶏は生産と逃避、犬は追跡。役割が違います。", 15)
	if world.result == "win":
		label_at(Vector2(868, 560), "所有 %d匹 / 小屋 %s / 門補強 %d" % [world.campaign.animals.size(), "有" if world.campaign.shelter else "無", world.campaign.fence], 17)
	else:
		var recent = world.events.slice(-3)
		for i in range(recent.size()):
			label_at(Vector2(868, 511 + i * 24), recent[i].text.left(24), 14, Color("d2c9a7"))
