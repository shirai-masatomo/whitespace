extends Node2D
const Farm = preload("res://game/world.gd")
const FONT = preload("res://assets/fonts/ui_font.tres")
const ORIGIN = Vector2(28, 174)
const TILE = 32.0
const TOOL_INFO = {
	"wall": ["1  壁 / 土20・1秒", "空きマスに壁。犬も敵も通れず、敵は壊せます。"],
	"build_gate": ["2  門 / 土30（仮）", "閉じた門を建築。開閉モードで犬の通り道を作ろう。"],
	"gate": ["3  門を開閉", "門をクリックして開閉。上に誰かいる間は操作できません。"],
	"feed": ["4  餌 / 指示力3", "餌1個を設置。疲れた犬が自分で向かい回復します。"],
	"remove": ["5  撤去 / 一部返却", "壁・門を撤去。耐久に応じ資材の半分以下を回収。"],
	"collect": ["6  卵を回収", "巣をクリックして卵を所持品へ。停止中は回収できません。"],
	"whistle": ["Q  笛で呼ぶ", "地点へ呼び戻す。反撃中の敵から離し、落ち着いてから再追跡。救出中は本能を優先。"],
	"stay": ["W  待機", "地点で待機。隣の敵に吠えますが、追いかけません。"],
	"wander": ["E  徘徊", "地点の周辺を歩き回り、侵入者を見つけます。"],
	"attack_target": ["R  敵を指定", "侵入者をクリック。犬がその相手を追い返しに向かいます。"],
	"repair": ["7  修理 / 土を消費", "施設をクリック。必要な土を消費して修理。不足時は可能な分だけ。停止中は不可。"]}
var world = Farm.new()
var tool = "wall"
var speed = 1
var accumulated = 0.0
var clock = 0.0
var automated = false
var view_positions: Dictionary = {}
var buttons: Dictionary = {}
var message = "牧場内をクリックして牧場主を配置 → 時計開始。柴犬はそばから始まります。"
var last_phase = ""

func _ready():
	var theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 16
	var controls = Control.new()
	controls.theme = theme
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(controls)
	var index = 0
	for id in TOOL_INFO:
		add_button(controls, id, TOOL_INFO[id][0], Rect2(860 + (index % 2) * 200, 304 + (index / 2) * 42, 190, 36), select_tool.bind(id))
		index += 1
	add_button(controls, "auto", "A  おまかせに戻す", Rect2(1060, 514, 190, 36), auto_order)
	add_button(controls, "advance", "位置を選び、時計を開始", Rect2(860, 585, 390, 46), advance)
	add_button(controls, "pause", "停止 / Space", Rect2(860, 640, 188, 38), toggle_pause)
	add_button(controls, "speed", "速度 ×1", Rect2(1062, 640, 188, 38), toggle_speed)
	add_button(controls, "retry", "この日の最初から", Rect2(860, 689, 188, 38), retry_stage)
	add_button(controls, "export", "観察JSON", Rect2(1062, 689, 188, 38), export_record)
	var shop = [["hen", "鶏を迎える  30G"], ["feed_buy", "餌 ×3  8G"], ["shelter", "巣周辺の休憩所 28G"], ["fence", "新設門の補強 24G"], ["sell_egg", "卵 → 9G"], ["cook_egg", "卵 → 餌 ×2"], ["soil", "土50（仮） 15G"]]
	for i in range(shop.size()):
		add_button(controls, shop[i][0], shop[i][1], Rect2(860 + (i % 2) * 200, 380 + (i / 2) * 51, 190, 42), purchase.bind(shop[i][0]))
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
	message = TOOL_INFO[value][1]
	refresh_buttons()

func auto_order():
	world.act("auto")
	message = "おまかせを指示。忠誠度に応じて少し遅れて反応します。"

func advance():
	if world.phase == "prepare":
		if world.act("start"): message = "敵が来るまで建築。襲来中も作れます。壁で犬を閉じ込めないように！"
	elif world.result == "win":
		world = Farm.new(world.next_campaign(), world.seed_value + 1) if world.stage == 1 else Farm.new()
		view_positions.clear()
		accumulated = 0
		message = "牧場の施設・損傷・土を引き継ぎました。牧場主を配置して時計を動かそう。"
	refresh_buttons()

func toggle_pause():
	world.act("pause")
	accumulated = 0
	refresh_buttons()

func toggle_speed():
	speed = 2 if speed == 1 else 1
	refresh_buttons()

func retry_stage():
	world = Farm.new(world.checkpoint, world.seed_value)
	view_positions.clear()
	accumulated = 0
	message = "当日開始時へ戻しました。主人公の位置・建築・指示を変えて試そう。"
	refresh_buttons()

func purchase(id: String):
	message = "購入しました。次の日へ持ち越します。" if world.buy("feed" if id == "feed_buy" else id) else "Gold・卵が足りないか、すでに所有しています。"
	refresh_buttons()

func export_record():
	DirAccess.make_dir_recursive_absolute("user://observations")
	var file = FileAccess.open("user://observations/latest.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(world.observation(), "  "))
		message = "観察JSONを user://observations/latest.json に保存しました。"

func refresh_buttons():
	var shop = world.result == "win"
	for id in ["hen", "feed_buy", "shelter", "fence", "sell_egg", "cook_egg", "soil"]: buttons[id].visible = shop
	for id in TOOL_INFO:
		buttons[id].visible = world.phase != "result"
		buttons[id].modulate = Color("ffe2a0") if tool == id else Color.WHITE
		buttons[id].disabled = world.phase != "defend"
	buttons.auto.visible = world.phase != "result"
	buttons.auto.disabled = world.phase != "defend"
	buttons.advance.disabled = world.phase == "defend" or world.result == "loss" or (world.phase == "prepare" and not world.keeper.placed)
	buttons.advance.text = "時計を開始 / 建築準備へ" if world.phase == "prepare" else ("Stage 2 へ進む" if shop and world.stage == 1 else ("別の牧場づくりを試す" if shop else "防衛中"))
	buttons.pause.disabled = world.phase != "defend"
	buttons.pause.text = "再開 / Space" if world.paused else "停止 / Space"
	buttons.speed.text = "速度 ×%d" % speed
	last_phase = world.phase

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var modes = TOOL_INFO.keys()
			var index = modes.find(tool)
			select_tool(modes[posmod(index + (1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1), modes.size())])
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			tool = ""
			message = "選択を解除しました。ホイールでモードを選べます。"
			refresh_buttons()
			get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var keys = {KEY_1: "wall", KEY_2: "build_gate", KEY_3: "gate", KEY_4: "feed", KEY_5: "remove", KEY_6: "collect", KEY_7: "repair", KEY_Q: "whistle", KEY_W: "stay", KEY_E: "wander", KEY_R: "attack_target"}
		if keys.has(event.physical_keycode): select_tool(keys[event.physical_keycode])
		if event.physical_keycode == KEY_SPACE: toggle_pause()
		if event.physical_keycode == KEY_A: auto_order()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Rect2(ORIGIN, Vector2(Farm.W, Farm.H) * TILE).has_point(event.position):
			var p = Vector2i((event.position - ORIGIN) / TILE)
			if tool == "attack_target":
				# Hit-test the displayed actor, then issue a stable model ID via its current cell.
				for e in world.enemies:
					if not e.done and not e.flee and event.position.distance_to(center(view_positions.get("e%d" % e.id, Vector2(e.pos)))) <= 20:
						p = e.pos
						break
			if not world.act("place" if world.phase == "prepare" else tool, p):
				message = "停止中は動物指示だけ。資材・対象・占有中のマスも確認してください。"
			refresh_buttons()

func _process(delta):
	clock += delta
	if not world.paused and not automated and world.phase == "defend":
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

func _draw():
	rect(Vector2.ZERO, Vector2(1280, 800), "192e2b")
	label_at(Vector2(30, 35), "WHITESPACE  /  SMALL FARM STORIES", 13, Color("9bb9a1"))
	label_at(Vector2(28, 77), "ホイッスル牧場", 32)
	label_at(Vector2(315, 76), "築く。まかせる。連れ去りから救う。", 17, Color("b7ccb4"))
	label_at(Vector2(861, 45), "DAY %02d  /  土 %d" % [world.stage, world.materials], 22)
	label_at(Vector2(861, 77), "Gold %d   餌 %d   卵 %d + 巣%d" % [world.campaign.gold, world.campaign.feed, world.campaign.eggs, world.eggs], 18, Color("f1cd85"))
	rect(Vector2(28, 98), Vector2(800, 55), "263f37")
	var status = "位置を選ぶ → 時計開始"
	if world.phase == "defend":
		status = "停止中：動物への指示だけ可能" if world.paused else ("建築準備" if world.spawned == 0 else "防衛中")
		if world.keeper.carrier >= 0: status = "連れ去り中！ 犬で救出しよう"
	elif world.phase == "result": status = "守りきった！" if world.result == "win" else ("牧場主が連れ去られた" if world.keeper.state == "abducted" else "防衛時間切れ")
	label_at(Vector2(43, 132), status, 20)
	var upcoming = world.next_attack_seconds()
	label_at(Vector2(490, 132), "次の襲来 %.0f秒 / 経過 %.0f秒" % [upcoming, world.tick * Farm.DT] if upcoming >= 0 else "全員を追い返そう / %.0f秒" % (world.tick * Farm.DT), 16)
	var exits = world.entries.map(func(entry): return world.exit_for(entry))
	for y in range(Farm.H):
		for x in range(Farm.W):
			var q = Vector2i(x, y)
			var p = ORIGIN + Vector2(q) * TILE
			var border = not world.inside(q)
			rect(p, Vector2(TILE, TILE), "345447" if border else ("608252" if (x + y) % 2 == 0 else "658757"))
			if not border and (x * 7 + y * 3) % 5 == 0:
				rect(p + Vector2(7, 19), Vector2(2, 6), "92a86a")
			if q in world.entries or q in exits:
				rect(p, Vector2(TILE, TILE), "b19867")
	for entry in world.entries: label_at(center(entry) + Vector2(-22, -22), "入口", 14)
	for p in world.structures:
		var b = world.structures[p]
		var c = center(p)
		if b.status in ["destroyed", "interrupted", "removed"]:
			if b.status != "removed":
				rect(c + Vector2(-10, 5), Vector2(9, 7), "817057")
				rect(c + Vector2(3, 7), Vector2(7, 5), "817057")
			continue
		if b.status == "building":
			draw_rect(Rect2(c - Vector2(14, 14), Vector2(28, 28)), Color("f6cf83"), false, 2)
			draw_line(c - Vector2(10, 10), c + Vector2(10, 10), Color("f6cf83"), 2)
			label_at(c + Vector2(-18, -19), "建設中", 12)
			rect(c + Vector2(-14, 16), Vector2(28.0 * (1.0 - float(b.remaining) / b.total_ticks), 4), "a8eee0")
			continue
		if b.kind == "wall":
			rect(c - Vector2(14, 13), Vector2(28, 27), "71674c")
			rect(c - Vector2(14, 13), Vector2(28, 5), "b2a481")
			draw_line(c - Vector2(13, 0), c + Vector2(13, 0), Color("4d523f"), 2)
		else:
			rect(c - Vector2(14, 13), Vector2(5, 28), "d1ad65")
			rect(c + Vector2(9, -13), Vector2(5, 28), "d1ad65")
			draw_line(c - Vector2(10, 10), c + Vector2(10, -10) if b.open else c + Vector2(10, 10), Color("ffdc83"), 5)
			label_at(c + Vector2(-7, 7), "開" if b.open else "閉", 12)
		rect(c + Vector2(-14, 16), Vector2(28, 3), "343e34")
		rect(c + Vector2(-14, 16), Vector2(28.0 * b.hp / b.max_hp, 3), "edc874")
	if world.campaign.animals.size() > 1:
		var n = center(world.nest)
		draw_circle(n, 20, Color("947448"))
		for i in range(mini(world.eggs, 8)): draw_circle(n + Vector2((i % 4) * 7 - 10, (i / 4) * 7 - 3), 4, Color("fff0c9"))
		label_at(n + Vector2(-23, 35), "卵の巣", 14)
		if world.campaign.shelter: draw_arc(n, 50, 0, TAU, 32, Color("bbaa74"), 2)
	for f in world.foods:
		var p = center(f.pos)
		draw_circle(p, 13, Color("e7b968"))
		draw_circle(p, 9, Color("75503c"))
	for e in world.enemies:
		if e.done: continue
		var p = center(view_positions.get("e%d" % e.id, Vector2(e.pos)))
		rect(p + Vector2(-10, -6), Vector2(21, 22), "817393" if not e.flee else "929388")
		draw_circle(p + Vector2(0, -10), 10, Color("d2b396"))
		rect(p + Vector2(-12, -18), Vector2(24, 8), "454453")
		rect(p + Vector2(-9, -11), Vector2(18, 5), "474954")
		rect(p + Vector2(-6, -10), Vector2(3, 2), "fff3ce")
		rect(p + Vector2(4, -10), Vector2(3, 2), "fff3ce")
		label_at(p + Vector2(-24, -44 if e.carry == "keeper" else -28), e.state, 13)
		rect(p + Vector2(-15, 21), Vector2(30, 4), "433a44")
		rect(p + Vector2(-15, 21), Vector2(30.0 * e.hp / e.max_hp, 4), "e8b98f")
	var owner = center(world.keeper.pos)
	if world.keeper.carrier >= 0: owner += Vector2(17, 5)
	draw_circle(owner + Vector2(0, -8), 9, Color("f3cda2"))
	rect(owner + Vector2(-12, -18), Vector2(24, 6), "f1d690")
	rect(owner + Vector2(-8, 1), Vector2(17, 20), "80d4cd")
	rect(owner + Vector2(-7, 20), Vector2(5, 6), "30484a")
	rect(owner + Vector2(3, 20), Vector2(5, 6), "30484a")
	label_at(owner + Vector2(-24, 43), "牧場主", 14, Color("aaffed"))
	if world.keeper.carrier >= 0: draw_arc(owner, 21, 0, TAU, 20, Color("fa996b"), 3)
	for a in world.animals:
		var p = center(view_positions.get("a%d" % a.id, Vector2(a.pos)))
		draw_circle(p + Vector2(0, 13), 16, Color(0.1, 0.2, 0.13, 0.25))
		if a.species == "shiba": draw_dog(p)
		else: draw_hen(p)
		label_at(p + Vector2(-25, -29), "%s Lv%d" % ["柴犬" if a.species == "shiba" else "鶏", a.lv], 14)
		if a.species == "shiba":
			rect(p + Vector2(-17, 22), Vector2(34, 4), "35523f")
			rect(p + Vector2(-17, 22), Vector2(34.0 * a.hp / a.max_hp, 4), "efd187")
			if not a.pending.is_empty(): draw_arc(center(a.pending.pos) if a.pending.kind != "auto" else p, 17, 0, TAU, 24, Color("fff0bd"), 2)
	# A placement preview makes construction legible without mutating the model.
	var mouse = get_global_mouse_position()
	var cell = Vector2i((mouse - ORIGIN) / TILE)
	if world.structures.has(cell):
		var hovered = world.structures[cell]
		label_at(Vector2(40, 733), "%s  耐久 %d/%d" % ["壁" if hovered.kind == "wall" else "門", hovered.hp, hovered.max_hp], 13)
	if world.inside(cell) and Rect2(ORIGIN, Vector2(Farm.W, Farm.H) * TILE).has_point(mouse):
		var tint = Color(1, 0.95, 0.7, 0.6)
		if Farm.BUILD.has(tool) and world.phase == "defend": tint = Color("a9ecd1") if world.can_build(tool, cell) else Color("e88c78")
		draw_rect(Rect2(ORIGIN + Vector2(cell) * TILE, Vector2.ONE * TILE), tint, false, 2)
	label_at(Vector2(40, 750), message.left(65), 15, Color("decba8"))
	label_at(Vector2(40, 780), "ホイール：モード選択   左：実行   右：解除   Space：停止   現在：" + (TOOL_INFO[tool][0] if TOOL_INFO.has(tool) else "選択なし"), 14, Color("9db69b"))
	draw_sidebar()

func draw_sidebar():
	rect(Vector2(847, 98), Vector2(417, 661), "223b35")
	var dog = world.animals[0]
	if world.result == "":
		label_at(Vector2(868, 133), "柴犬 Lv%d / %s" % [dog.lv, dog.state], 22)
		label_at(Vector2(868, 168), "HP %d/%d   元気 %d%%   忠誠 %d" % [dog.hp, dog.max_hp, dog.stamina, dog.loyalty], 18)
		label_at(Vector2(868, 202), "反撃されたら笛で退避 → 敵を再指定。", 16)
		label_at(Vector2(868, 229), "連れ去り中は救出本能：犬の速度1.5倍。", 16)
		label_at(Vector2(868, 261), "停止 = 動物指示だけ / 再開 = 建築・実行", 16, Color("f3d08c"))
		label_at(Vector2(868, 290), "壁HP8 / 門HP%d   入り口には建築不可" % (6 + world.campaign.fence * 4), 14)
		if not world.events.is_empty(): label_at(Vector2(868, 572), world.events.back().text.left(29), 13, Color("d2c9a7"))
	else:
		label_at(Vector2(868, 143), "防衛成功 / 購入と育成" if world.result == "win" else "防衛失敗 / もう一度", 24)
		label_at(Vector2(868, 186), "評価 %d点   EXP +%d   Gold +%d" % [world.score.rating, world.score.xp, world.score.gold], 18)
		label_at(Vector2(868, 225), "追返 %d / 拘束 %d / 救出 %d" % [world.metrics.repelled, world.metrics.captures, world.metrics.rescues], 18)
		label_at(Vector2(868, 262), "建築 %d / 破壊 %d / 残HP %d%%" % [world.metrics.built, world.metrics.destroyed, world.score.condition], 18)
		label_at(Vector2(868, 308), "柴犬 Lv%d   EXP %d / %d" % [dog.lv, dog.xp, dog.lv * 20], 20, Color("f5d395"))
		label_at(Vector2(868, 349), "配置・損傷・土も持越し。土購入か育成か。", 15)
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
