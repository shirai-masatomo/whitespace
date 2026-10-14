extends RefCounted
## Read-only inspection uses the existing modal boundary, never creates a job.
static func open(g):
	g.story_modal="inventory"
	var panel=Panel.new();g.story_panel=panel
	panel.size=Vector2(1280,800);panel.mouse_filter=Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel",g.MarketView.panel(Color(0.13,0.20,0.16,0.94)))
	g.controls.get_parent().add_child(panel);panel.theme=g.controls.theme
	var title=Label.new();title.text="物資の所在";title.position=Vector2(240,125);title.add_theme_font_size_override("font_size",30);panel.add_child(title)
	var scroll=ScrollContainer.new();scroll.position=Vector2(240,185);scroll.size=Vector2(800,430);panel.add_child(scroll)
	var list=VBoxContainer.new();list.custom_minimum_size.x=775;list.add_theme_constant_override("separation",12);scroll.add_child(list)
	var counts=g.world.Stock.totals(g.world)
	var ids=counts.keys();ids.sort()
	for id in ids:
		if counts[id]<=0:continue
		var product=g.world.Shop.table().get(id,{"Name":id,"Rarity":0})
		var catalog=preload("res://game/item_catalog.gd")
		var row=HBoxContainer.new();row.custom_minimum_size.y=112;row.add_theme_constant_override("separation",18);list.add_child(row)
		var pic=TextureRect.new();pic.texture=g.MarketView.texture_for(id) if g.MarketView.texture_for(id)!=null else g.UI.icon(catalog.item(id).icon);pic.custom_minimum_size=Vector2(54,54);pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(pic)
		var body=Label.new();body.custom_minimum_size.x=610
		var data=preload("res://game/item_catalog.gd").item(id)
		var name=data.name
		var purpose=g.MarketView.description(id)
		if id in ["fiber","wood_crate","wood_shelf","fiber_clothes"]:
			purpose={"fiber":"裁縫台で衣服に加工する素材。","wood_crate":"アーキテクトの設置から配置。収納効果はまだありません。","wood_shelf":"アーキテクトの設置から配置。収納効果はまだありません。","fiber_clothes":"人間の衣服。防御・耐久の効果はありません。"}[id]
		if g.world.Needs.Data.FOOD.has(id):
			var food=g.world.Needs.Data.FOOD[id];purpose="満腹度 +%d"%food.satiety+(" · "+food.effect+" %d秒"%food.duration if food.has("effect") else "")

		if id in ["soil","wood","stone"]:purpose="建設・改築に使う素材"
		if id in g.world.Work.Policy.HUMAN_FOOD:purpose+=" · 備蓄に回収後、空腹時に食べます。"
		var q=g.world.Stock.summary(g.world,id)
		body.text=name+"  所持 %d"%q.owned+"  利用可能 %d"%q.available+"\n備蓄 %d / 携行 %d / 現場 %d / 備蓄外 %d\n予約 %d（内数） / 装備 %d"%[q.stored,q.carried,q.site,q.outside,q.reserved,q.equipped]+(" / 盗難 %d"%q.stolen if q.stolen>0 else "")+"\n"+purpose.replace("\n"," ")
		body.add_theme_font_size_override("font_size",15);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		row.add_child(body)
		var tier=g.world.ProgressData.rarity(product.Rarity)
		var emblem=TextureRect.new();emblem.texture=g.Direction.ASSETS["ui.rarity_"+g.world.ProgressData.RARITY_NAMES[tier].to_lower()].texture;emblem.custom_minimum_size=Vector2(40,40);emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;emblem.tooltip_text=g.world.ProgressData.RARITY_NAMES[tier];row.add_child(emblem)
		var equipment=g.world.ProgressData.ITEMS.get(id,{})
		row.tooltip_text=catalog.CATEGORIES[data.category][0]+" / "+catalog.CATEGORIES[data.category][1][data.subcategory]+"\n"+purpose+("\n装備対象："+" / ".join(equipment.get("equip_targets",[]).map(func(tag):return {"dog":"犬","animal":"動物"}.get(tag,tag))) if not equipment.is_empty() else ("\n建設モードで設置" if id in ["kokeshi","fossil"] else ""))
	g.add_button(panel,"inventory_close","閉じる",Rect2(870,640,160,44),g.StoryView.close.bind(g))
