extends RefCounted
var opened=false
var bench=Vector2i.ZERO
var labels=[]
var elapsed=0.0
func show(g,p):opened=true;bench=p;g.refresh()
func close(g):opened=false;g.refresh()
func build(g):
	labels=[]
	if not opened or g.field_shop or g.field_book or not g.world.working():return
	var b=g.world.structures.get(bench,{})
	if b.get("status")!="ready" or not g.world.Craft.Data.BENCHES.has(b.get("kind","")):opened=false;return
	var area=Rect2(16,110,520,440);var panel=g.ColonyPanels.panel(g,area)
	g.ColonyPanels.label(panel,g.world.Craft.Data.BENCHES[b.kind]+(" · 栽培指示" if b.kind=="mushroom_bed" else " · 製作指示"),Vector2(12,10),19)
	var close_button=Button.new();close_button.text="閉じる";close_button.position=Vector2(422,8);close_button.size=Vector2(84,30);g.UI.button(close_button);panel.add_child(close_button);close_button.pressed.connect(close.bind(g))
	var recipes=g.world.Craft.Data.RECIPES.keys().filter(func(id):return g.world.Craft.Data.RECIPES[id].bench==b.kind)
	var recipe=OptionButton.new();recipe.name="Recipe";recipe.position=Vector2(12,51);recipe.size=Vector2(230,32);panel.add_child(recipe);g.UI.button(recipe)
	for id in recipes:recipe.add_item(g.world.Craft.Data.RECIPES[id].get("name",g.world.Craft.Catalog.title(id)))
	var mode=OptionButton.new();mode.position=Vector2(250,51);mode.size=Vector2(145,32);mode.add_item("収穫数を指定" if b.kind=="mushroom_bed" else "指定数を製作");mode.add_item("在庫数を維持");panel.add_child(mode);g.UI.button(mode)
	var count=SpinBox.new();count.position=Vector2(404,51);count.size=Vector2(100,32);count.min_value=1;count.max_value=100;count.value=1;panel.add_child(count)
	var detail=Label.new();detail.position=Vector2(12,91);detail.size=Vector2(490,38);detail.add_theme_font_size_override("font_size",13);detail.add_theme_color_override("font_color",g.UI.INK);panel.add_child(detail)
	var describe=func():
		var data=g.world.Craft.Data.RECIPES[recipes[recipe.selected]];var parts=[]
		for kind in data.ingredients:parts.append("%s ×%d"%[g.world.Craft.Catalog.title(kind),data.ingredients[kind]])
		detail.text=" + ".join(parts)+" → %d個 · %s秒\n備蓄から自動搬入 · 完成品の回収は別途指定"%[data.count,str(data.seconds)]
		if data.has("grow_seconds"):detail.text="キノコ1を植菌 → 48時間生育 → 3個収穫\n植菌・収穫 各4秒 · 採集担当 · 自動収集ONで備蓄へ"
	describe.call();recipe.item_selected.connect(func(_i):describe.call())
	var add=Button.new();add.text="栽培指示を追加" if b.kind=="mushroom_bed" else "製作指示を追加";add.position=Vector2(12,136);add.size=Vector2(220,34);panel.add_child(add);g.UI.button(add)
	add.pressed.connect(func():
		if not g.world.Craft.enqueue(g.world,bench,recipes[recipe.selected],"count" if mode.selected==0 else "stock",int(count.value)):g.notice("指示を追加できません（上限100件・栽培床は1件ずつ）")
		g.refresh())
	var scroll=ScrollContainer.new();scroll.position=Vector2(12,182);scroll.size=Vector2(492,244);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_ALWAYS;panel.add_child(scroll)
	var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
	for j in g.world.jobs:
		if j.kind!="craft" or j.bench_id!=b.id:continue
		var row=HBoxContainer.new();list.add_child(row);var text=Label.new();text.custom_minimum_size=Vector2(370,66);text.add_theme_font_size_override("font_size",13);text.add_theme_color_override("font_color",g.UI.INK);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;row.add_child(text);labels.append([text,j]);text.text=g.world.Craft.summary(g.world,j)
		var cancel=Button.new();cancel.text="取消";row.add_child(cancel);g.UI.button(cancel);cancel.pressed.connect(func():g.world.Jobs.cancel(g.world,j.id);g.refresh())
	if labels.is_empty():g.ColonyPanels.label(list,"製作指示はありません",Vector2.ZERO,14)
func step(g,delta):
	if not opened:return
	elapsed+=delta
	if elapsed<0.25:return
	elapsed=0
	for pair in labels:
		if is_instance_valid(pair[0]):pair[0].text=g.world.Craft.summary(g.world,pair[1]) if pair[1] in g.world.jobs else "完了"
